# dotfiles

One-command setup for macOS and Linux: zsh + p10k, tmux, kitty, Neovim, git, and every CLI tool / app I use daily.
The installer detects the OS and installs each thing the native way:

| OS | System packages | CLI tools | GUI apps | Fonts |
|---|---|---|---|---|
| macOS | Xcode CLT | Homebrew (`Brewfile`) | Homebrew casks | Homebrew casks |
| Ubuntu / Debian | `apt` | Homebrew on Linux | Flatpak (`linux/flatpaks.txt`) | Nerd Fonts → `~/.local/share/fonts` |
| Fedora | `dnf` | Homebrew on Linux | Flatpak | Nerd Fonts |
| Arch | `pacman` | Homebrew on Linux | Flatpak | Nerd Fonts |
| WSL (Ubuntu) | `apt` | Homebrew on Linux | — (use Windows apps) | — |

Native Windows isn't supported; run `wsl --install` and use the WSL row.

## Fresh machine — one command

```sh
curl -fsSL https://raw.githubusercontent.com/JoanSernaLeiton/dotfiles/main/bootstrap.sh | bash
```

With the optional apps (Slack, Zoom, AnyDesk, Chrome Dev, Firefox), as casks on macOS or Flatpaks on Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/JoanSernaLeiton/dotfiles/main/bootstrap.sh | bash -s -- --extras
```

`bootstrap.sh` makes sure git exists (Xcode CLT on macOS, the native package manager on Linux), clones this repo to `~/dotfiles` over HTTPS and runs `install.sh`. It asks for your `sudo` password once.

## Already cloned

```sh
./install.sh              # everything
./install.sh --extras     # everything + extras
./install.sh nvim tmux    # specific modules
./install.sh --list       # list modules
```

Modules: `system brew apps zsh git tmux kitty nvim node python claude macos`.
`system` installs build tools, zsh, Docker, kitty, clipboard tools and Flatpak on Linux; `apps` (Linux only) installs the Flatpaks, Nerd Fonts, gcloud and the AWS session-manager-plugin; `macos` only runs on macOS. Every module is idempotent; existing files are moved to `~/.dotfiles_backup/<timestamp>/` before being replaced by symlinks.

## Layout

| Path | What |
|---|---|
| `Brewfile` / `Brewfile.extras` | Homebrew formulas (all OSes), casks and fonts (macOS) |
| `linux/` | Flatpak app lists (`flatpaks.txt`, `flatpaks.extras.txt`) |
| `bin/` | Cross-platform helpers linked into `~/.local/bin` (`clipcopy`, `clippaste`) |
| `zsh/` | `zshrc`, `p10k.zsh`, `zshrc.local.example` |
| `git/gitconfig` | Shared git config |
| `tmux/tmux.conf` | tmux (prefix `C-a`, TPM plugins) |
| `kitty/` | kitty config + theme |
| `nvim/` | Neovim (lazy.nvim, plugin versions pinned in `lazy-lock.json`) |
| `macos.sh` | macOS defaults (key repeat, Finder, Dock, screenshots) |

## Private / machine-specific config

Never commit these; they are created on install and sourced automatically:

- `~/.zshrc.local` — work hosts, tunnels, env vars
- `~/.gitconfig.local` — git email, signing key, `includeIf` rules

## After installing

- `gh auth login`, then add your SSH key and switch the remote: `git remote set-url origin git@github.com:JoanSernaLeiton/dotfiles.git`
- Open tmux and press `prefix + I` if any plugin is missing
- Open Neovim once so Mason installs the language servers
- Linux: log out and back in so the `docker` group and zsh login shell take effect
- Linux: Cursor, Claude desktop and AWS VPN Client have no Flatpak; install them manually if needed
