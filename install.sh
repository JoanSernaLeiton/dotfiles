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

# ── Helpers ──────────────────────────────────────────────────────────
load_brew_env() {
    local b
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
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
        read -r -p "$question " answer </dev/tty || true
    fi
    echo "$answer"
}

# ── Modules ──────────────────────────────────────────────────────────

MODULES=(brew zsh git tmux kitty nvim node python claude macos)

install_brew() {
    info "── brew ──"
    ensure_brew
    brew update
    brew bundle --file="$DOTFILES/Brewfile" || warn "Some Brewfile entries failed (see above)"
    if [[ "$EXTRAS" == true ]]; then
        brew bundle --file="$DOTFILES/Brewfile.extras" || warn "Some Brewfile.extras entries failed (see above)"
    fi
    success "brew done"
}

install_zsh() {
    info "── zsh ──"
    symlink "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
    symlink "$DOTFILES/zsh/p10k.zsh" "$HOME/.p10k.zsh"
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
        cp "$DOTFILES/zsh/zshrc.local.example" "$HOME/.zshrc.local"
        success "Created ~/.zshrc.local (private, untracked)"
    fi
    if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
        info "Changing login shell to zsh..."
        chsh -s "$(command -v zsh)" || warn "chsh failed; run: chsh -s $(command -v zsh)"
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
    success "claude done"
}

install_macos() {
    info "── macos ──"
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
Available modules (run in this order by default):

  brew    - Homebrew + everything in Brewfile (CLI tools, apps, fonts)
  zsh     - zshrc + p10k + ~/.zshrc.local
  git     - gitconfig + ~/.gitconfig.local (email)
  tmux    - tmux.conf + TPM + plugins
  kitty   - kitty config + theme
  nvim    - Neovim config + plugins (lazy-lock.json)
  node    - Node LTS via fnm
  python  - pipenv via uv
  claude  - Claude Code CLI
  macos   - macOS system defaults (macos.sh)

Usage:
  ./install.sh                  # Install everything
  ./install.sh --extras         # Everything + Brewfile.extras (Slack, Zoom, AnyDesk, ...)
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

    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Dotfiles Installer             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$(uname)" != "Darwin" ]]; then
        warn "Only macOS is fully supported; casks and macos defaults will be skipped or fail"
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
