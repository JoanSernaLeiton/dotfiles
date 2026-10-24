# Daily-driver packages. Installed by `./install.sh brew` (or the full install).
# Optional apps live in Brewfile.extras (`./install.sh --extras`).
#
# Used on macOS and on Linux (Homebrew on Linux for CLI tools). Anything that
# only exists on macOS (casks, fonts, mac-only formulas) is inside `if OS.mac?`;
# Linux gets those via its native package manager / Flatpak (see linux/).

tap "anomalyco/tap"

# ── Shell & terminal ─────────────────────────────────────────────────
brew "git"
brew "tmux"
brew "powerlevel10k"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "fzf"
brew "zoxide"                 # frecent dirs: `z`, and the tmux project picker (prefix f)
brew "bat"
brew "fd"
brew "ripgrep"
brew "wget"
brew "jq"
brew "rtk"

# ── Editor (Neovim + what the config shells out to) ──────────────────
brew "neovim"
brew "tree-sitter-cli"
brew "code-minimap"
brew "lazygit"
brew "lazydocker"
brew "stylua"
brew "prettier"
brew "ruff"
brew "shfmt"

# ── Languages & toolchains ───────────────────────────────────────────
brew "fnm"
brew "pnpm"
brew "python@3.12"   # mcp-memory-service (needs SQLite extension loading, which uv's own Pythons lack)
brew "uv"

# ── Git hosting / cloud / infra ──────────────────────────────────────
brew "gh"
brew "flyctl"
brew "opentofu"
brew "anomalyco/tap/opencode"

if OS.mac?
  tap "hudochenkov/sshpass"
  brew "hudochenkov/sshpass/sshpass"
  brew "reattach-to-user-namespace"
  brew "duti"
  brew "terminal-notifier"   # clickable Claude Code notifications (bin/claude-tmux)
  brew "rust"
  brew "libpq"

  # ── Apps ─────────────────────────────────────────────────────────────
  cask "kitty"
  cask "orbstack"
  cask "google-chrome@dev"

  # ── Fonts ────────────────────────────────────────────────────────────
  cask "font-fira-code-nerd-font"
end
