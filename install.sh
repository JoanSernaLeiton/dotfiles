#!/usr/bin/env bash

set -euo pipefail

# ── Colors & Logging ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
EXTRAS=false
LITE=false

# ── OS Detection ─────────────────────────────────────────────────────
# OS:     macos | linux
# DISTRO: debian | fedora | arch (Linux only, from /etc/os-release ID / ID_LIKE)
# IS_WSL: true when running inside Windows Subsystem for Linux (no GUI apps)
OS=""
DISTRO=""
IS_WSL=false

detect_os() {
    case "$(uname -s)" in
        Darwin) OS=macos ;;
        Linux)
            OS=linux
            grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=true
            local id="" id_like=""
            if [[ -r /etc/os-release ]]; then
                id="$(. /etc/os-release && echo "${ID:-}")"
                id_like="$(. /etc/os-release && echo "${ID_LIKE:-}")"
            fi
            case " $id $id_like " in
                *" debian "*|*" ubuntu "*)        DISTRO=debian ;;
                *" fedora "*|*" rhel "*)          DISTRO=fedora ;;
                *" arch "*)                       DISTRO=arch ;;
                *)
                    error "Unsupported Linux distribution: ${id:-unknown} (supported: Debian/Ubuntu, Fedora, Arch)"
                    exit 1
                    ;;
            esac
            ;;
        MINGW*|MSYS*|CYGWIN*)
            error "Native Windows isn't supported. Install WSL (wsl --install) and run this inside Ubuntu."
            exit 1
            ;;
        *)
            error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac
}

has_gui() { [[ "$OS" == macos ]] || { [[ "$IS_WSL" == false ]] && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}${XDG_CURRENT_DESKTOP:-}" ]]; }; }

# ── Helpers ──────────────────────────────────────────────────────────
load_brew_env() {
    local b
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
        if [[ -x "$b" ]]; then
            eval "$("$b" shellenv)"
            return 0
        fi
    done
    return 1
}

ensure_brew() {
    if command -v brew &>/dev/null || load_brew_env; then
        return
    fi
    info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew_env
    success "Homebrew installed"
}

# Native package manager, one package at a time so a missing name doesn't
# abort the whole batch (package names differ slightly between releases).
pkg_install() {
    local pkg
    for pkg in "$@"; do
        case "$DISTRO" in
            debian) sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$pkg" >/dev/null ;;
            fedora) sudo dnf install -y -q "$pkg" ;;
            arch)   sudo pacman -S --needed --noconfirm "$pkg" ;;
        esac || warn "Could not install package: $pkg"
    done
}

pkg_refresh() {
    case "$DISTRO" in
        debian) sudo apt-get update -qq ;;
        fedora) sudo dnf makecache -q ;;
        arch)   sudo pacman -Sy --noconfirm ;;
    esac
}

backup_if_exists() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        warn "Backing up $target → $BACKUP_DIR/$(basename "$target")"
        mv "$target" "$BACKUP_DIR/$(basename "$target")"
    fi
}

symlink() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    backup_if_exists "$dst"
    ln -sfn "$src" "$dst"
    success "Linked $dst → $src"
}

# Ask on the terminal even when this script is piped from curl.
prompt() {
    local question="$1" answer=""
    if [[ -r /dev/tty ]]; then
        { read -r -p "$question " answer </dev/tty; } 2>/dev/null || true
    fi
    echo "$answer"
}

# Read a package list file, skipping comments and blank lines.
read_list() { grep -vE '^\s*(#|$)' "$1"; }

# ── Modules ──────────────────────────────────────────────────────────

MODULES=(system brew apps zsh git tmux kitty node nvim python memory claude opencode macos)
LITE_MODULES=(system brew apps zsh git tmux kitty node nvim memory claude opencode macos)

LITE_NERD_FONTS=(FiraCode)
FULL_NERD_FONTS=(FiraCode JetBrainsMono Meslo)

DOCKER_DAEMON_CONFIGURATION_PATH=/etc/docker/daemon.json
DOCKER_LOG_ROTATION_SETTINGS='{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"3"}}'
ZRAM_GENERATOR_CONFIGURATION_PATH=/etc/systemd/zram-generator.conf
ZRAM_GENERATOR_SETTINGS=$'[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd'
CHROME_DEV_DEBIAN_PACKAGE_URL="https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"
CHROME_DEV_FEDORA_PACKAGE_URL="https://dl.google.com/linux/direct/google-chrome-unstable_current_x86_64.rpm"
CHROME_DEV_EXECUTABLE=/opt/google/chrome-unstable/chrome
TMUX_THUMBS_PLUGIN_DIRECTORY="$HOME/.tmux/plugins/tmux-thumbs"
XFCE_TERMINAL_SHORTCUT_PROPERTY="/commands/custom/<Primary><Alt>t"
BREWFILE_THIRD_PARTY_TAPS=(anomalyco/tap)
MACOS_BREWFILE_THIRD_PARTY_TAPS=(hudochenkov/sshpass)

install_system() {
    info "── system ──"
    if [[ "$OS" == macos ]]; then
        if ! xcode-select -p &>/dev/null; then
            info "Installing Xcode Command Line Tools (accept the dialog)..."
            xcode-select --install || true
            until xcode-select -p &>/dev/null; do sleep 5; done
        fi
        success "system done"
        return
    fi

    pkg_refresh
    # Build tools + what Homebrew on Linux needs, zsh, fonts tooling
    case "$DISTRO" in
        debian) pkg_install build-essential procps curl file git zsh unzip fontconfig sshpass jq libnotify-bin lsof pkg-config postgresql-client ;;
        fedora) pkg_install gcc gcc-c++ make procps-ng curl file git zsh unzip fontconfig sshpass jq libnotify lsof pkgconf-pkg-config postgresql ;;
        arch)   pkg_install base-devel procps-ng curl file git zsh unzip fontconfig sshpass jq libnotify lsof pkgconf postgresql ;;
    esac
    install_rust_toolchain

    if [[ "$IS_WSL" == true ]]; then
        info "WSL: skipping Docker engine (use Docker Desktop's WSL integration) and desktop packages"
        success "system done"
        return
    fi

    # Docker engine (the Linux counterpart of OrbStack)
    case "$DISTRO" in
        debian) pkg_install docker.io docker-compose-v2 docker-buildx ;;
        fedora) pkg_install moby-engine docker-compose docker-buildx ;;
        arch)   pkg_install docker docker-compose docker-buildx ;;
    esac
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable --now docker || warn "Could not start docker service"
    fi
    if ! id -nG "$USER" | grep -qw docker; then
        sudo usermod -aG docker "$USER" && info "Added $USER to the docker group (log out/in to apply)"
    fi
    configure_docker_log_rotation
    install_tauri_build_dependencies

    # Desktop: terminal, clipboard, Flatpak
    if [[ "$LITE" == true ]]; then
        pkg_install kitty xclip
        enable_compressed_memory_swap
        power_off_discrete_nvidia_gpu
    else
        pkg_install kitty xclip wl-clipboard flatpak
    fi
    success "system done"
}

install_rust_toolchain() {
    pkg_install rustup
    if ! command -v rustup &>/dev/null && command -v rustup-init &>/dev/null; then
        rustup-init -y --no-modify-path --profile minimal --default-toolchain none
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    if ! command -v rustup &>/dev/null; then
        warn "rustup not found; install Rust from https://rustup.rs"
        return
    fi
    rustup toolchain install stable --profile minimal --component clippy --component rustfmt
    rustup default stable
    success "Rust $(rustc --version | cut -d' ' -f2) with clippy and rustfmt"
}

install_tauri_build_dependencies() {
    case "$DISTRO" in
        debian) pkg_install libwebkit2gtk-4.1-dev libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev ;;
        fedora) pkg_install webkit2gtk4.1-devel openssl-devel libappindicator-gtk3-devel librsvg2-devel libxdo-devel ;;
        arch)   pkg_install webkit2gtk-4.1 openssl appmenu-gtk-module libappindicator-gtk3 librsvg xdotool ;;
    esac
}

configure_docker_log_rotation() {
    if sudo test -s "$DOCKER_DAEMON_CONFIGURATION_PATH"; then
        info "Keeping the existing $DOCKER_DAEMON_CONFIGURATION_PATH (no log rotation added)"
        return
    fi
    sudo mkdir -p "$(dirname "$DOCKER_DAEMON_CONFIGURATION_PATH")"
    echo "$DOCKER_LOG_ROTATION_SETTINGS" | sudo tee "$DOCKER_DAEMON_CONFIGURATION_PATH" >/dev/null
    if command -v systemctl &>/dev/null; then
        sudo systemctl restart docker || warn "Could not restart docker; log rotation applies after a reboot"
    fi
    success "Docker logs capped at 3 files of 10 MB per container"
}

enable_compressed_memory_swap() {
    case "$DISTRO" in
        debian)      pkg_install systemd-zram-generator ;;
        fedora|arch) pkg_install zram-generator ;;
    esac
    if [[ -f "$ZRAM_GENERATOR_CONFIGURATION_PATH" ]]; then
        info "Keeping the existing $ZRAM_GENERATOR_CONFIGURATION_PATH"
        return
    fi
    echo "$ZRAM_GENERATOR_SETTINGS" | sudo tee "$ZRAM_GENERATOR_CONFIGURATION_PATH" >/dev/null
    sudo systemctl daemon-reload && sudo systemctl start systemd-zram-setup@zram0.service \
        || warn "zram swap starts after the next reboot"
    success "zram swap: half the RAM, zstd"
}

power_off_discrete_nvidia_gpu() {
    if ! command -v prime-select &>/dev/null; then
        info "No prime-select (NVIDIA driver not installed); nothing to switch off"
        return
    fi
    if [[ "$(prime-select query 2>/dev/null)" == intel ]]; then
        info "NVIDIA GPU already off (prime-select intel)"
        return
    fi
    if sudo prime-select intel; then
        success "NVIDIA GPU off (prime-select intel); reboot to apply"
    else
        warn "prime-select intel failed; the NVIDIA GPU stays on"
    fi
}

trust_brewfile_third_party_taps() {
    if ! brew trust --help &>/dev/null; then
        return
    fi
    local taps_to_trust=("${BREWFILE_THIRD_PARTY_TAPS[@]}")
    if [[ "$OS" == macos ]]; then
        taps_to_trust+=("${MACOS_BREWFILE_THIRD_PARTY_TAPS[@]}")
    fi
    local tap_name
    for tap_name in "${taps_to_trust[@]}"; do
        brew trust --tap "$tap_name" >/dev/null || warn "Could not trust the $tap_name tap; brew will skip its formulas"
    done
}

install_brew() {
    info "── brew ──"
    if [[ "$OS" == linux && "$(uname -m)" != x86_64 ]]; then
        warn "Homebrew on Linux $(uname -m) has few prebuilt bottles; some formulas will compile from source (slow)"
    fi
    ensure_brew
    brew update
    trust_brewfile_third_party_taps
    # Brewfile wraps casks / mac-only formulas in `if OS.mac?`, so it works on both
    brew bundle --file="$DOTFILES/Brewfile" || warn "Some Brewfile entries failed (see above)"
    if [[ "$LITE" == false ]]; then
        brew bundle --file="$DOTFILES/Brewfile.full" || warn "Some Brewfile.full entries failed (see above)"
    fi
    if [[ "$EXTRAS" == true && "$OS" == macos ]]; then
        brew bundle --file="$DOTFILES/Brewfile.extras" || warn "Some Brewfile.extras entries failed (see above)"
    fi
    success "brew done"
}

# GUI apps / fonts / cloud tools on Linux (on macOS these are casks in the Brewfile)
install_apps() {
    info "── apps ──"
    if [[ "$OS" == macos ]]; then
        info "macOS apps come from the Brewfile casks"
        success "apps done"
        return
    fi

    if [[ "$LITE" == true ]]; then
        install_linux_fonts "${LITE_NERD_FONTS[@]}"
    else
        install_linux_fonts "${FULL_NERD_FONTS[@]}"
        install_gcloud
        install_session_manager_plugin
    fi
    if [[ "$IS_WSL" == false ]]; then
        install_chrome_dev
    fi

    if [[ "$LITE" == true ]]; then
        success "apps done (lite: no Flatpaks, gcloud or session-manager-plugin)"
        return
    fi
    if ! has_gui; then
        info "No desktop session detected (or WSL); skipping Flatpak apps"
        success "apps done"
        return
    fi
    if ! command -v flatpak &>/dev/null; then
        warn "flatpak not installed; run './install.sh system' first"
        return
    fi
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    local lists=("$DOTFILES/linux/flatpaks.txt")
    [[ "$EXTRAS" == true ]] && lists+=("$DOTFILES/linux/flatpaks.extras.txt")
    local app
    for app in $(cat "${lists[@]}" | grep -vE '^\s*(#|$)'); do
        flatpak install --user -y --noninteractive flathub "$app" || warn "Could not install $app"
    done
    success "apps done"
}

install_linux_fonts() {
    local dir="$HOME/.local/share/fonts/NerdFonts" font
    mkdir -p "$dir"
    for font in "$@"; do
        if ls "$dir" 2>/dev/null | grep -q "^$font"; then
            continue
        fi
        info "Installing $font Nerd Font..."
        local tmp
        tmp="$(mktemp -d)"
        if curl -fsSL -o "$tmp/$font.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip"; then
            unzip -qo "$tmp/$font.zip" -d "$tmp/$font"
            # Files are named <Font>NerdFont-*.ttf, which the check above relies on
            find "$tmp/$font" -name '*.ttf' -exec cp {} "$dir/" \;
        else
            warn "Could not download $font Nerd Font"
        fi
        rm -rf "$tmp"
    done
    command -v fc-cache &>/dev/null && fc-cache -f "$dir" >/dev/null
}

install_chrome_dev() {
    if [[ -x "$CHROME_DEV_EXECUTABLE" ]]; then
        return
    fi
    if [[ "$(uname -m)" != x86_64 ]]; then
        warn "Chrome Dev has no Linux $(uname -m) build; the Playwright MCP (--browser chrome-dev) won't start"
        return
    fi
    info "Installing Chrome Dev (the browser the Playwright MCP uses)..."
    local download_directory
    download_directory="$(mktemp -d)"
    chmod 755 "$download_directory"
    case "$DISTRO" in
        debian)
            curl -fsSL -o "$download_directory/google-chrome-unstable.deb" "$CHROME_DEV_DEBIAN_PACKAGE_URL" \
                && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$download_directory/google-chrome-unstable.deb" >/dev/null \
                || warn "Chrome Dev install failed"
            ;;
        fedora)
            sudo dnf install -y -q "$CHROME_DEV_FEDORA_PACKAGE_URL" || warn "Chrome Dev install failed"
            ;;
        arch)
            warn "Chrome Dev: install google-chrome-dev from the AUR"
            ;;
    esac
    rm -rf "$download_directory"
}

install_gcloud() {
    if command -v gcloud &>/dev/null || [[ -d "$HOME/google-cloud-sdk" ]]; then
        return
    fi
    info "Installing Google Cloud SDK into ~/google-cloud-sdk..."
    curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME" >/dev/null \
        || warn "gcloud install failed"
}

install_session_manager_plugin() {
    command -v session-manager-plugin &>/dev/null && return
    local base="https://s3.amazonaws.com/session-manager-downloads/plugin/latest" arch tmp
    arch="$(uname -m)"
    tmp="$(mktemp -d)"
    case "$DISTRO" in
        debian)
            [[ "$arch" == x86_64 ]] && arch=ubuntu_64bit || arch=ubuntu_arm64
            curl -fsSL -o "$tmp/smp.deb" "$base/$arch/session-manager-plugin.deb" \
                && sudo dpkg -i "$tmp/smp.deb" >/dev/null || warn "session-manager-plugin install failed"
            ;;
        fedora)
            [[ "$arch" == x86_64 ]] && arch=linux_64bit || arch=linux_arm64
            sudo dnf install -y -q "$base/$arch/session-manager-plugin.rpm" || warn "session-manager-plugin install failed"
            ;;
        arch)
            warn "session-manager-plugin: install from the AUR (aws-session-manager-plugin)"
            ;;
    esac
    rm -rf "$tmp"
}

install_zsh() {
    info "── zsh ──"
    symlink "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
    symlink "$DOTFILES/zsh/p10k.zsh" "$HOME/.p10k.zsh"
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
        cp "$DOTFILES/zsh/zshrc.local.example" "$HOME/.zshrc.local"
        success "Created ~/.zshrc.local (private, untracked)"
    fi
    local f
    for f in "$DOTFILES"/bin/*; do
        symlink "$f" "$HOME/.local/bin/$(basename "$f")"
    done
    if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
        # Prefer the system zsh: it's the one listed in /etc/shells
        local zsh_path
        zsh_path="$(command -v /bin/zsh /usr/bin/zsh zsh 2>/dev/null | head -1)"
        info "Changing login shell to $zsh_path..."
        sudo chsh -s "$zsh_path" "$USER" || warn "chsh failed; run: chsh -s $zsh_path"
    fi
    success "zsh done"
}

install_git() {
    info "── git ──"
    symlink "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
    symlink "$DOTFILES/git/ignore" "$HOME/.config/git/ignore"
    if [[ ! -f "$HOME/.gitconfig.local" ]]; then
        local email
        email="$(prompt "Git email for this machine (blank to skip):")"
        if [[ -n "$email" ]]; then
            printf '[user]\n\temail = %s\n' "$email" > "$HOME/.gitconfig.local"
            success "Created ~/.gitconfig.local"
        else
            warn "No git email set; add it to ~/.gitconfig.local"
        fi
    fi
    success "git done"
}

install_tmux() {
    info "── tmux ──"
    symlink "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
    if ! infocmp tmux-256color &>/dev/null; then
        warn "tmux-256color terminfo missing; colors may be off (set default-terminal to xterm-256color)"
    fi
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        info "Installing TPM..."
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
    info "Installing tmux plugins..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null || warn "TPM plugin install failed; press prefix+I inside tmux"
    install_tmux_thumbs_binary
    success "tmux done"
}

install_tmux_thumbs_binary() {
    if [[ "$OS" != linux || "$(uname -m)" != x86_64 || ! -f "$TMUX_THUMBS_PLUGIN_DIRECTORY/Cargo.toml" ]]; then
        return
    fi
    local release_directory="$TMUX_THUMBS_PLUGIN_DIRECTORY/target/release" plugin_version
    plugin_version="$(awk -F'"' '/^version *=/ { print $2; exit }' "$TMUX_THUMBS_PLUGIN_DIRECTORY/Cargo.toml")"
    if [[ -x "$release_directory/thumbs" && "$("$release_directory/thumbs" --version 2>/dev/null)" == "thumbs $plugin_version" ]]; then
        return
    fi
    info "Downloading tmux-thumbs $plugin_version (instead of compiling it on first use)..."
    mkdir -p "$release_directory"
    curl -fsSL "https://github.com/fcsonline/tmux-thumbs/releases/download/$plugin_version/tmux-thumbs_${plugin_version}_x86_64-unknown-linux-musl.tar.gz" \
        | tar -xz -C "$release_directory" \
        || warn "Could not download tmux-thumbs; prefix+t builds it with cargo instead"
}

install_kitty() {
    info "── kitty ──"
    symlink "$DOTFILES/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    symlink "$DOTFILES/kitty/theme.conf" "$HOME/.config/kitty/theme.conf"
    bind_xfce_terminal_shortcut_to_kitty
    success "kitty done"
}

bind_xfce_terminal_shortcut_to_kitty() {
    if [[ "$OS" != linux ]] || ! command -v xfconf-query &>/dev/null || ! command -v kitty &>/dev/null; then
        return
    fi
    if xfconf-query -c xfce4-keyboard-shortcuts -p "$XFCE_TERMINAL_SHORTCUT_PROPERTY" -n -t string -s kitty 2>/dev/null; then
        success "Ctrl+Alt+T opens kitty"
    else
        info "To open kitty with Ctrl+Alt+T, run this inside the Xfce session: xfconf-query -c xfce4-keyboard-shortcuts -p '$XFCE_TERMINAL_SHORTCUT_PROPERTY' -n -t string -s kitty"
    fi
}

install_nvim() {
    info "── nvim ──"
    mkdir -p "$HOME/.local/share/nvim"/{backup,swap,undo}
    symlink "$DOTFILES/nvim/init.lua" "$HOME/.config/nvim/init.lua"
    symlink "$DOTFILES/nvim/lua" "$HOME/.config/nvim/lua"
    symlink "$DOTFILES/nvim/after" "$HOME/.config/nvim/after"
    symlink "$DOTFILES/nvim/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
    if command -v fnm &>/dev/null; then
        eval "$(fnm env --shell bash)"
    fi
    if command -v nvim &>/dev/null; then
        info "Installing Neovim plugins at locked versions..."
        nvim --headless "+Lazy! restore" +qa || warn "Lazy restore failed; open nvim and run :Lazy restore"
    else
        warn "nvim not found; run './install.sh brew' first"
    fi
    success "nvim done"
}

install_node() {
    info "── node ──"
    if ! command -v fnm &>/dev/null; then
        warn "fnm not found; run './install.sh brew' first"
        return
    fi
    eval "$(fnm env --shell bash)"
    fnm install --lts
    fnm default lts-latest
    success "node done ($(fnm exec --using=default node --version))"
}

install_python() {
    info "── python ──"
    if ! command -v uv &>/dev/null; then
        warn "uv not found; run './install.sh brew' first"
        return
    fi
    uv tool install pipenv || uv tool upgrade pipenv
    success "python done"
}

# Shared memory MCP server on 127.0.0.1:8765, used by Claude Code and OpenCode.
# Runs offline, so the embedding model is downloaded here first.
MEMORY_VERSION="12.1.0"
MEMORY_MODEL="paraphrase-multilingual-MiniLM-L12-v2"

install_memory() {
    info "── memory ──"
    if ! command -v uv &>/dev/null; then
        warn "uv not found; run './install.sh brew' first"
        return
    fi
    if uv tool list 2>/dev/null | grep -q '^mcp-memory-service '; then
        info "mcp-memory-service already installed"
    else
        # Homebrew's Python: uv's own builds can't load SQLite extensions, which sqlite-vec needs
        local py
        brew list --versions python@3.12 &>/dev/null || brew install python@3.12 || true
        py="$(brew --prefix python@3.12 2>/dev/null)/bin/python3.12"
        [[ -x "$py" ]] || { warn "python@3.12 not found; run './install.sh brew' first"; return; }
        uv tool install --python "$py" --with onnxruntime "mcp-memory-service[sqlite-ml]==$MEMORY_VERSION"
    fi

    local model_dir="$HOME/.cache/mcp_memory/onnx_models/$MEMORY_MODEL"
    if [[ ! -f "$model_dir/tokenizer.json" ]]; then
        info "Downloading embedding model $MEMORY_MODEL..."
        # Plain HTTP: the hf-xet transport can stall on this 470 MB file
        HF_HUB_DISABLE_XET=1 "$(uv tool dir)/mcp-memory-service/bin/python" - "$model_dir" "$MEMORY_MODEL" <<'PY'
import sys
from huggingface_hub import snapshot_download
snapshot_download(repo_id=f"onnx-community/{sys.argv[2]}-ONNX", local_dir=sys.argv[1],
                  allow_patterns=["model.onnx", "onnx/model.onnx", "tokenizer.json", "tokenizer_config.json",
                                  "config.json", "special_tokens_map.json"])
PY
    fi

    mkdir -p "$HOME/.mcp-memory/logs"
    if [[ "$OS" == macos ]]; then
        local label=com.joan.mcp-memory plist="$HOME/Library/LaunchAgents/com.joan.mcp-memory.plist" tmp
        tmp="$(mktemp)"
        sed "s#__HOME__#$HOME#g" "$DOTFILES/memory/$label.plist" > "$tmp"
        mkdir -p "$(dirname "$plist")"
        if ! cmp -s "$tmp" "$plist"; then
            mv "$tmp" "$plist"
            launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
        else
            rm -f "$tmp"
        fi
        launchctl print "gui/$(id -u)/$label" &>/dev/null || launchctl bootstrap "gui/$(id -u)" "$plist"
    elif command -v systemctl &>/dev/null && systemctl --user show-environment &>/dev/null; then
        symlink "$DOTFILES/memory/mcp-memory.service" "$HOME/.config/systemd/user/mcp-memory.service"
        systemctl --user daemon-reload
        systemctl --user enable --now mcp-memory.service
    else
        warn "No systemd user session; start it yourself: memory server --streamable-http --sse-host 127.0.0.1 --sse-port 8765"
    fi

    local i
    for i in {1..30}; do
        memory_healthy && { success "memory done (http://127.0.0.1:8765/mcp)"; return; }
        sleep 2
    done
    warn "Memory server not healthy on :8765; logs in ~/.mcp-memory/logs"
}

# The server answers HTTP even when its database failed to open, so ask it over MCP
memory_healthy() {
    local url=http://127.0.0.1:8765/mcp sid
    local h=(-H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream')
    sid="$(curl -s -D - -o /dev/null --max-time 10 "${h[@]}" "$url" \
        -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"dotfiles","version":"1"}}}' \
        | tr -d '\r' | awk -F': ' 'tolower($1)=="mcp-session-id"{print $2}')"
    # Stateless servers send no session id; only pass it when there is one
    [[ -n "$sid" ]] && h+=(-H "mcp-session-id: $sid")
    curl -s -o /dev/null --max-time 10 "${h[@]}" "$url" -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'
    curl -s --max-time 60 "${h[@]}" "$url" \
        -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"memory_health","arguments":{}}}' \
        | grep -q 'database validation successful'
}

install_claude() {
    info "── claude ──"
    if command -v claude &>/dev/null || [[ -x "$HOME/.local/bin/claude" ]]; then
        info "Claude Code already installed"
    else
        curl -fsSL https://claude.ai/install.sh | bash
    fi
    local f
    for f in CLAUDE.md RTK.md VOICE.md; do
        symlink "$DOTFILES/claude/$f" "$HOME/.claude/$f"
    done
    configure_claude_settings
    configure_claude_mcp
    configure_claude_rtk
    success "claude done"
}

# User-scope MCP servers from claude/mcp.json (same ones OpenCode gets in opencode/opencode.json)
configure_claude_mcp() {
    # Fresh install: claude lands in ~/.local/bin, which may not be on PATH yet
    local claude name
    claude="$(command -v claude || echo "$HOME/.local/bin/claude")"
    if [[ ! -x "$claude" ]] || ! command -v jq &>/dev/null; then
        warn "claude or jq not found; skipping MCP servers"
        return
    fi
    for name in $(jq -r 'keys[]' "$DOTFILES/claude/mcp.json"); do
        # Replace instead of skip, so changes in mcp.json reach machines that already have it
        "$claude" mcp remove -s user "$name" &>/dev/null || true
        "$claude" mcp add-json -s user "$name" "$(jq -c --arg n "$name" '.[$n]' "$DOTFILES/claude/mcp.json")" >/dev/null \
            && success "Claude MCP: $name" || warn "Could not add Claude MCP $name"
    done
}

# RTK: PreToolUse hook that rewrites shell commands to save tokens, plus ~/.claude/RTK.md
configure_claude_rtk() {
    if ! command -v rtk &>/dev/null; then
        warn "rtk not found; run './install.sh brew' first"
        return
    fi
    (cd "$HOME" && rtk init -g --auto-patch) && success "Claude Code hook → rtk"
}

# Merge the tmux integration into ~/.claude/settings.json without touching the rest of
# the file (it holds machine/work-specific settings, so it isn't tracked here).
configure_claude_settings() {
    if ! command -v jq &>/dev/null; then
        warn "jq not found; run './install.sh brew' first to wire Claude Code into tmux"
        return
    fi
    local settings="$HOME/.claude/settings.json" tmp
    mkdir -p "$HOME/.claude"
    [[ -s "$settings" ]] || echo '{}' > "$settings"
    tmp="$(mktemp)"
    jq --arg cmd '$HOME/.local/bin/claude-tmux hook' '
        # Drop our previous entries so re-running is idempotent, then add them back
        def ours: .hooks | any(.command == $cmd);
        .hooks |= (. // {})
        | reduce ("SessionStart", "PreToolUse", "UserPromptSubmit", "PostToolUse", "Notification", "Stop", "SessionEnd") as $ev (.;
            .hooks[$ev] = ([(.hooks[$ev] // [])[] | select(ours | not)]
                           + [{hooks: [{type: "command", command: $cmd, timeout: 10}]}]))
        # Agent teams: one tmux pane per teammate when running inside tmux
        | .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
        | .teammateMode = "auto"
        # Status line: model · context % · cost (also mirrored to the tmux pane border). Kept if you have your own.
        | .statusLine //= {type: "command", command: "$HOME/.local/bin/claude-tmux statusline"}
    ' "$settings" > "$tmp" && mv "$tmp" "$settings"
    success "Claude Code hooks → tmux (~/.claude/settings.json)"
}

install_opencode() {
    info "── opencode ──"
    if command -v opencode &>/dev/null || [[ -x "$HOME/.opencode/bin/opencode" ]]; then
        info "OpenCode already installed"
    else
        curl -fsSL https://opencode.ai/install | bash
    fi
    # Same pane states, notifications and `prefix a` as Claude: the plugin feeds claude-tmux
    symlink "$DOTFILES/bin/claude-tmux" "$HOME/.local/bin/claude-tmux"
    # Config, global rules and plugins. service.json and cli.json stay local (service password)
    local f
    for f in opencode.json AGENTS.md plugins/rtk.ts plugins/tmux.ts; do
        symlink "$DOTFILES/opencode/$f" "$HOME/.config/opencode/$f"
    done
    success "opencode done"
}

install_macos() {
    info "── macos ──"
    if [[ "$OS" != macos ]]; then
        info "Not macOS, skipping system defaults"
        return
    fi
    "$DOTFILES/macos.sh"
    install_maintenance_agent mac-maintenance
    install_maintenance_agent brew-daily-upgrade
    success "macos done"
}

install_maintenance_agent() {
    local agent_name="$1"
    local label="com.joan.$agent_name"
    local plist="$HOME/Library/LaunchAgents/$label.plist" rendered_plist
    symlink "$DOTFILES/bin/$agent_name" "$HOME/.local/bin/$agent_name"
    rendered_plist="$(mktemp)"
    sed "s#__HOME__#$HOME#g" "$DOTFILES/maintenance/$label.plist" > "$rendered_plist"
    mkdir -p "$(dirname "$plist")"
    if ! cmp -s "$rendered_plist" "$plist"; then
        mv "$rendered_plist" "$plist"
        launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
    else
        rm -f "$rendered_plist"
    fi
    launchctl print "gui/$(id -u)/$label" &>/dev/null || launchctl bootstrap "gui/$(id -u)" "$plist"
}

# ── Module Runner ────────────────────────────────────────────────────

run_module() {
    local mod="$1"
    if [[ " ${MODULES[*]} " != *" $mod "* ]]; then
        error "Unknown module: $mod"
        echo "Run './install.sh --list' to see available modules."
        return 1
    fi
    "install_$mod"
}

list_modules() {
    cat <<EOF
Available modules (run in this order by default). The OS is detected
automatically: macOS, Debian/Ubuntu, Fedora, Arch, or WSL.

  system  - macOS: Xcode CLT | Linux: build tools, zsh, psql, Rust (rustup) + Tauri libraries,
            Docker (buildx, log rotation), kitty, clipboard, Flatpak (native pkg manager)
  brew    - Homebrew (macOS & Linux) + Brewfile and Brewfile.full (CLI tools; casks/fonts on macOS)
  apps    - Linux only: Nerd Fonts, Chrome Dev (Playwright MCP), Flatpak apps, gcloud, AWS session-manager-plugin
  zsh     - zshrc + p10k + ~/.zshrc.local + bin/ helpers
  git     - gitconfig + global gitignore + ~/.gitconfig.local (email)
  tmux    - tmux.conf + TPM + plugins
  kitty   - kitty config + theme
  node    - Node LTS via fnm
  nvim    - Neovim config + plugins (lazy-lock.json)
  python  - pipenv via uv
  memory  - Shared memory MCP server (mcp-memory-service on :8765, launchd/systemd) for Claude and OpenCode
  claude  - Claude Code CLI + tmux hooks, status line, agent-team panes, MCPs (memory, playwright), rtk hook
  opencode - OpenCode CLI + config (model, MCPs, AGENTS.md) + rtk and tmux plugins
  macos   - macOS system defaults (macos.sh) + launch agents: weekly mac-maintenance, brew-daily-upgrade at 07:00 and 21:00 (skipped elsewhere)

--lite, for old or low-RAM machines. Runs every module except python, and:
  brew    - only Brewfile (skips Brewfile.full: Go, Bazel, Deno, cloud CLIs, image tools, Mac apps)
  apps    - only the FiraCode Nerd Font and Chrome Dev (no Flatpaks, gcloud or session-manager-plugin)
  system  - no Flatpak or wl-clipboard; adds zram swap (half the RAM, zstd) and turns the NVIDIA GPU off
            when prime-select exists

Usage:
  ./install.sh                  # Install everything
  ./install.sh --lite           # Lightweight profile
  ./install.sh --extras         # Everything + extras (Slack, Zoom, AnyDesk, Firefox)
  ./install.sh tmux nvim        # Specific modules only (add --lite to use the lite variants)
  ./install.sh --list           # Show this help
EOF
}

# ── Main ─────────────────────────────────────────────────────────────

main() {
    local selected=()
    local arg
    for arg in "$@"; do
        case "$arg" in
            -l|--list|-h|--help) list_modules; exit 0 ;;
            -e|--extras)         EXTRAS=true ;;
            --lite)              LITE=true ;;
            *)                   selected+=("$arg") ;;
        esac
    done
    if [[ ${#selected[@]} -eq 0 && "$LITE" == true ]]; then
        selected=("${LITE_MODULES[@]}")
    elif [[ ${#selected[@]} -eq 0 ]]; then
        selected=("${MODULES[@]}")
    fi

    detect_os

    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Dotfiles Installer             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    info "Detected: $OS${DISTRO:+ ($DISTRO)}$([[ $IS_WSL == true ]] && echo ' on WSL')"
    if [[ "$LITE" == true ]]; then
        info "Profile: lite"
    fi
    echo ""

    # Ask for the sudo password once up front and keep it alive while we run
    if [[ "$OS" == linux ]] || [[ " ${selected[*]} " == *" brew "* ]]; then
        if sudo -v; then
            while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
        fi
    fi

    load_brew_env || true

    local failed=()
    local mod
    for mod in "${selected[@]}"; do
        # Keep going if one module fails so a single broken step doesn't block the rest.
        # Not run as `if ! (...)`: errexit is ignored inside a condition.
        local rc=0
        set +e
        ( set -e; run_module "$mod" )
        rc=$?
        set -e
        if [[ $rc -ne 0 ]]; then
            error "Module '$mod' failed"
            failed+=("$mod")
        fi
        load_brew_env || true
        echo ""
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        error "Finished with failures in: ${failed[*]}"
        exit 1
    fi

    success "All done! Open a new terminal (or run: exec zsh)."
    if git -C "$DOTFILES" remote get-url origin 2>/dev/null | grep -q '^https://'; then
        info "Once your SSH key is on GitHub: git -C $DOTFILES remote set-url origin git@github.com:JoanSernaLeiton/dotfiles.git"
    fi
}

main "$@"
