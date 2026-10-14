#!/usr/bin/env bash
# One-shot setup for a fresh Mac:
#
#   curl -fsSL https://raw.githubusercontent.com/JoanSernaLeiton/dotfiles/main/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/JoanSernaLeiton/dotfiles/main/bootstrap.sh | bash -s -- --extras
#
# Installs Xcode Command Line Tools, clones this repo over HTTPS (no SSH key
# needed yet) and hands off to install.sh with any arguments given.

set -euo pipefail

REPO_URL="https://github.com/JoanSernaLeiton/dotfiles.git"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
BRANCH="${DOTFILES_BRANCH:-main}"

info() { echo -e "\033[0;34m[INFO]\033[0m $*"; }

if [[ "$(uname)" == "Darwin" ]] && ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools (accept the dialog)..."
    xcode-select --install || true
    until xcode-select -p &>/dev/null; do sleep 5; done
fi

if [[ -d "$DOTFILES/.git" ]]; then
    info "Updating $DOTFILES..."
    git -C "$DOTFILES" pull --ff-only || info "Could not fast-forward, using local copy"
else
    info "Cloning dotfiles into $DOTFILES..."
    git clone --branch "$BRANCH" "$REPO_URL" "$DOTFILES"
fi

exec "$DOTFILES/install.sh" "$@"
