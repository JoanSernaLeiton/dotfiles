#!/usr/bin/env bash
# One-shot setup for a fresh machine (macOS, Debian/Ubuntu, Fedora, Arch, WSL):
#
#   curl -fsSL https://raw.githubusercontent.com/JoanSernaLeiton/dotfiles/main/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/JoanSernaLeiton/dotfiles/main/bootstrap.sh | bash -s -- --extras
#
# Makes sure git is available (Xcode CLT on macOS, the native package manager
# on Linux), clones this repo over HTTPS (no SSH key needed yet) and hands off
# to install.sh, which detects the OS and installs everything the native way.

set -euo pipefail

REPO_URL="https://github.com/JoanSernaLeiton/dotfiles.git"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
BRANCH="${DOTFILES_BRANCH:-main}"

info() { echo -e "\033[0;34m[INFO]\033[0m $*"; }

case "$(uname -s)" in
    Darwin)
        if ! xcode-select -p &>/dev/null; then
            info "Installing Xcode Command Line Tools (accept the dialog)..."
            xcode-select --install || true
            until xcode-select -p &>/dev/null; do sleep 5; done
        fi
        ;;
    Linux)
        if ! command -v git &>/dev/null; then
            info "Installing git..."
            if command -v apt-get &>/dev/null; then sudo apt-get update -qq && sudo apt-get install -y -qq git
            elif command -v dnf &>/dev/null; then sudo dnf install -y -q git
            elif command -v pacman &>/dev/null; then sudo pacman -Sy --needed --noconfirm git
            else echo "Install git first, then re-run." >&2; exit 1
            fi
        fi
        ;;
    *)
        echo "Unsupported OS: $(uname -s). On Windows, use WSL (wsl --install)." >&2
        exit 1
        ;;
esac

if [[ -d "$DOTFILES/.git" ]]; then
    info "Updating $DOTFILES..."
    git -C "$DOTFILES" pull --ff-only || info "Could not fast-forward, using local copy"
else
    info "Cloning dotfiles into $DOTFILES..."
    git clone --branch "$BRANCH" "$REPO_URL" "$DOTFILES"
fi

exec "$DOTFILES/install.sh" "$@"
