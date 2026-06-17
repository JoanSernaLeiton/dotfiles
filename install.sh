#!/usr/bin/env bash

set -e

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

DOTFILES="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# ── OS Detection ─────────────────────────────────────────────────────
OS="$(uname)"

# ── Helpers ──────────────────────────────────────────────────────────
ensure_brew() {
    if command -v brew &>/dev/null; then
        return
    fi
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$OS" == "Linux" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
}

brew_install() {
    local pkg
    for pkg in "$@"; do
        if brew list "$pkg" &>/dev/null; then
            info "$pkg already installed"
        else
            info "Installing $pkg..."
            brew install "$pkg"
        fi
    done
}

brew_install_cask() {
    local pkg
    for pkg in "$@"; do
        if brew list --cask "$pkg" &>/dev/null; then
            info "$pkg (cask) already installed"
        else
            info "Installing $pkg (cask)..."
            brew install --cask "$pkg"
        fi
    done
}

backup_if_exists() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        local name
        name="$(basename "$target")"
        warn "Backing up $target → $BACKUP_DIR/$name"
        mv "$target" "$BACKUP_DIR/$name"
    fi
}

symlink() {
    local src="$1" dst="$2"
    backup_if_exists "$dst"
    ln -sf "$src" "$dst"
    success "Linked $src → $dst"
}

# ── Modules ──────────────────────────────────────────────────────────

MODULES=(tmux nvim zsh kitty python node core fonts)

install_tmux() {
    info "── tmux ──"
    ensure_brew
    brew_install tmux
    if [[ "$OS" == "Darwin" ]]; then
        brew_install reattach-to-user-namespace
    fi
    symlink "$DOTFILES/tmux.conf" "$HOME/.tmux.conf"
    # Install TPM
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        info "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    else
        info "TPM already installed"
    fi
    success "tmux done"
}

install_nvim() {
    info "── nvim ──"
    ensure_brew
    brew_install neovim code-minimap tree-sitter-cli

    mkdir -p "$HOME/.config/nvim"
    mkdir -p "$HOME/.local/share/nvim"/{backup,swap,undo}

    # Remove old symlinks/dirs before creating new ones
    rm -f "$HOME/.config/nvim/init.lua"
    rm -rf "$HOME/.config/nvim/lua"
    rm -rf "$HOME/.config/nvim/after"

    symlink "$DOTFILES/nvim/init.lua" "$HOME/.config/nvim/init.lua"
    symlink "$DOTFILES/nvim/lua" "$HOME/.config/nvim/lua"
    symlink "$DOTFILES/nvim/after" "$HOME/.config/nvim/after"

    chmod 755 "$HOME/.config/nvim"
    chmod 644 "$HOME/.config/nvim/init.lua"
    success "nvim done"
}

install_zsh() {
    info "── zsh ──"
    ensure_brew

    if [[ "$OS" == "Linux" ]]; then
        if ! command -v zsh &>/dev/null; then
            info "Installing zsh (apt)..."
            sudo apt install -y zsh curl build-essential
        fi
        if [[ "$(basename "$SHELL")" != "zsh" ]]; then
            sudo chsh -s "$(which zsh)"
        fi
    fi

    brew_install powerlevel10k zsh-syntax-highlighting zsh-autosuggestions

    symlink "$DOTFILES/zshrc" "$HOME/.zshrc"
    symlink "$DOTFILES/.p10k.zsh" "$HOME/.p10k.zsh"
    success "zsh done"
}

install_kitty() {
    info "── kitty ──"
    mkdir -p "$HOME/.config/kitty"
    symlink "$DOTFILES/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    symlink "$DOTFILES/theme.conf" "$HOME/.config/kitty/theme.conf"
    success "kitty done"
}

install_python() {
    info "── python ──"
    ensure_brew
    brew_install python
    info "Upgrading pip..."
    python3 -m pip install --upgrade pip 2>/dev/null || true
    info "Installing Python packages..."
    pip3 install --user pipenv pynvim 2>/dev/null || python3 -m pip install --user pipenv pynvim
    success "python done"
}

install_node() {
    info "── node ──"
    if command -v fnm &>/dev/null; then
        info "fnm already installed"
    else
        info "Installing fnm..."
        curl -fsSL https://fnm.vercel.app/install | bash
    fi
    success "node done"
}

install_core() {
    info "── core ──"
    ensure_brew
    brew_install ripgrep fd fzf bat go gcc cmake bazel ag shfmt lazydocker
    # Run fzf install for keybindings/completion (idempotent)
    if [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
        info "Setting up fzf keybindings..."
        "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish 2>/dev/null || true
    fi
    success "core done"
}

install_fonts() {
    info "── fonts ──"
    if [[ "$OS" != "Darwin" ]]; then
        warn "Font cask installation is macOS only, skipping"
        return
    fi
    ensure_brew
    brew_install_cask font-fira-code \
                      font-jetbrains-mono \
                      font-meslo-lg-nerd-font \
                      font-iosevka
    success "fonts done"
}

# ── Module Runner ────────────────────────────────────────────────────

run_module() {
    local mod="$1"
    case "$mod" in
        tmux)   install_tmux   ;;
        nvim)   install_nvim   ;;
        zsh)    install_zsh    ;;
        kitty)  install_kitty  ;;
        python) install_python ;;
        node)   install_node   ;;
        core)   install_core   ;;
        fonts)  install_fonts  ;;
        *)
            error "Unknown module: $mod"
            echo "Run './install.sh --list' to see available modules."
            return 1
            ;;
    esac
}

list_modules() {
    echo "Available modules:"
    echo ""
    echo "  tmux    - tmux + TPM + config"
    echo "  nvim    - Neovim + config symlinks"
    echo "  zsh     - Zsh plugins + zshrc + p10k"
    echo "  kitty   - Kitty terminal config"
    echo "  python  - Python + pip + pipenv + pynvim"
    echo "  node    - fnm (Node version manager)"
    echo "  core    - ripgrep, fzf, bat, go, gcc, cmake, bazel, ag, shfmt, lazydocker"
    echo "  fonts   - Nerd Fonts (macOS only)"
    echo ""
    echo "Usage:"
    echo "  ./install.sh              # Install everything"
    echo "  ./install.sh tmux nvim    # Install specific modules"
    echo "  ./install.sh --list       # Show this help"
}

# ── Main ─────────────────────────────────────────────────────────────

main() {
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Dotfiles Installer             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""

    if [[ $# -eq 0 ]]; then
        info "Installing all modules..."
        echo ""
        for mod in "${MODULES[@]}"; do
            run_module "$mod"
            echo ""
        done
    elif [[ "$1" == "--list" || "$1" == "-l" ]]; then
        list_modules
        exit 0
    else
        for mod in "$@"; do
            run_module "$mod"
            echo ""
        done
    fi

    success "All done!"
}

main "$@"
