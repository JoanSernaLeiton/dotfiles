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
brew "bat"
brew "fd"
brew "ripgrep"
brew "the_silver_searcher"
brew "wget"
brew "yq"
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
brew "deno"
brew "go"
brew "python@3.14"
brew "uv"
brew "pipx"
brew "gcc"
brew "cmake"
brew "bazel"

# ── Git hosting / cloud / infra ──────────────────────────────────────
brew "gh"
brew "glab"
brew "awscli"
brew "kubernetes-cli"
brew "libpq"
brew "anomalyco/tap/opencode"

# ── Misc utilities ───────────────────────────────────────────────────
brew "ghostscript"
brew "graphicsmagick"
brew "poppler"
brew "wakeonlan"

if OS.mac?
  tap "hudochenkov/sshpass"
  brew "hudochenkov/sshpass/sshpass"
  brew "reattach-to-user-namespace"
  brew "duti"

  # ── Apps ─────────────────────────────────────────────────────────────
  cask "kitty"
  cask "orbstack"
  cask "cursor"
  cask "webstorm"
  cask "dbeaver-community"
  cask "postman"
  cask "claude"
  cask "bitwarden"
  cask "rectangle"
  cask "obsidian"
  cask "google-chrome"
  cask "gcloud-cli"
  cask "session-manager-plugin"
  cask "aws-vpn-client"

  # ── Fonts ────────────────────────────────────────────────────────────
  cask "font-fira-code"
  cask "font-fira-code-nerd-font"
  cask "font-jetbrains-mono"
  cask "font-meslo-lg-nerd-font"
  cask "font-iosevka"
end
