#!/usr/bin/env bash
# macOS system defaults. Safe to re-run. Run via `./install.sh macos`.

set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
    echo "macos.sh: not macOS, skipping"
    exit 0
fi

# ── Keyboard ─────────────────────────────────────────────────────────
# Fast key repeat, and repeat instead of the accent popup (needed for hjkl in vim)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# ── Finder ───────────────────────────────────────────────────────────
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"   # list view
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search current folder
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Dock ─────────────────────────────────────────────────────────────
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false

# ── Screenshots ──────────────────────────────────────────────────────
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# ── Misc ─────────────────────────────────────────────────────────────
# Save new documents to disk, not iCloud
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

for app in Finder Dock SystemUIServer; do
    killall "$app" &>/dev/null || true
done

echo "macOS defaults applied (some need a logout to take effect)"
