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

MODULES=(system brew apps zsh git tmux kitty nvim node python claude macos)

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
        debian) pkg_install build-essential procps curl file git zsh unzip fontconfig sshpass jq libnotify-bin ;;
        fedora) pkg_install gcc gcc-c++ make procps-ng curl file git zsh unzip fontconfig sshpass jq libnotify ;;
        arch)   pkg_install base-devel procps-ng curl file git zsh unzip fontconfig sshpass jq libnotify ;;
    esac

    if [[ "$IS_WSL" == true ]]; then
        info "WSL: skipping Docker engine (use Docker Desktop's WSL integration) and desktop packages"
        success "system done"
        return
    fi

    # Docker engine (the Linux counterpart of OrbStack)
    case "$DISTRO" in
        debian) pkg_install docker.io docker-compose-v2 ;;
        fedora) pkg_install moby-engine docker-compose ;;
        arch)   pkg_install docker docker-compose ;;
    esac
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable --now docker || warn "Could not start docker service"
    fi
    if ! id -nG "$USER" | grep -qw docker; then
        sudo usermod -aG docker "$USER" && info "Added $USER to the docker group (log out/in to apply)"
    fi

    # Desktop: terminal, clipboard, Flatpak
    pkg_install kitty xclip wl-clipboard flatpak
    success "system done"
}

install_brew() {
    info "── brew ──"
    if [[ "$OS" == linux && "$(uname -m)" != x86_64 ]]; then
        warn "Homebrew on Linux $(uname -m) has few prebuilt bottles; some formulas will compile from source (slow)"
    fi
    ensure_brew
    brew update
    # Brewfile wraps casks / mac-only formulas in `if OS.mac?`, so it works on both
    brew bundle --file="$DOTFILES/Brewfile" || warn "Some Brewfile entries failed (see above)"
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

    install_linux_fonts
    install_gcloud
    install_session_manager_plugin

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
    for font in FiraCode JetBrainsMono Meslo; do
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
    success "tmux done"
}

install_kitty() {
    info "── kitty ──"
    symlink "$DOTFILES/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    symlink "$DOTFILES/kitty/theme.conf" "$HOME/.config/kitty/theme.conf"
    success "kitty done"
}

install_nvim() {
    info "── nvim ──"
    mkdir -p "$HOME/.local/share/nvim"/{backup,swap,undo}
    symlink "$DOTFILES/nvim/init.lua" "$HOME/.config/nvim/init.lua"
    symlink "$DOTFILES/nvim/lua" "$HOME/.config/nvim/lua"
    symlink "$DOTFILES/nvim/after" "$HOME/.config/nvim/after"
    symlink "$DOTFILES/nvim/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
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

install_claude() {
    info "── claude ──"
    if command -v claude &>/dev/null || [[ -x "$HOME/.local/bin/claude" ]]; then
        info "Claude Code already installed"
    else
        curl -fsSL https://claude.ai/install.sh | bash
    fi
    configure_claude_settings
    success "claude done"
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
        | reduce ("PreToolUse", "UserPromptSubmit", "PostToolUse", "Notification", "Stop", "SessionEnd") as $ev (.;
            .hooks[$ev] = ([(.hooks[$ev] // [])[] | select(ours | not)]
                           + [{hooks: [{type: "command", command: $cmd, timeout: 10}]}]))
        # Agent teams: one tmux pane per teammate when running inside tmux
        | .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
        | .teammateMode = "auto"
    ' "$settings" > "$tmp" && mv "$tmp" "$settings"
    success "Claude Code hooks → tmux (~/.claude/settings.json)"
}

install_macos() {
    info "── macos ──"
    if [[ "$OS" != macos ]]; then
        info "Not macOS, skipping system defaults"
        return
    fi
    "$DOTFILES/macos.sh"
    success "macos done"
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

  system  - macOS: Xcode CLT | Linux: build tools, zsh, Docker, kitty, clipboard, Flatpak (native pkg manager)
  brew    - Homebrew (macOS & Linux) + Brewfile (CLI tools; casks/fonts on macOS)
  apps    - Linux only: Flatpak apps, Nerd Fonts, gcloud, AWS session-manager-plugin
  zsh     - zshrc + p10k + ~/.zshrc.local + bin/ helpers
  git     - gitconfig + ~/.gitconfig.local (email)
  tmux    - tmux.conf + TPM + plugins
  kitty   - kitty config + theme
  nvim    - Neovim config + plugins (lazy-lock.json)
  node    - Node LTS via fnm
  python  - pipenv via uv
  claude  - Claude Code CLI + tmux hooks (state icons, notifications, agent-team panes)
  macos   - macOS system defaults (macos.sh; skipped elsewhere)

Usage:
  ./install.sh                  # Install everything
  ./install.sh --extras         # Everything + extras (Slack, Zoom, AnyDesk, Chrome Dev, Firefox)
  ./install.sh tmux nvim        # Specific modules only
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
            *)                   selected+=("$arg") ;;
        esac
    done
    if [[ ${#selected[@]} -eq 0 ]]; then
        selected=("${MODULES[@]}")
    fi

    detect_os

    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Dotfiles Installer             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    info "Detected: $OS${DISTRO:+ ($DISTRO)}$([[ $IS_WSL == true ]] && echo ' on WSL')"
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
