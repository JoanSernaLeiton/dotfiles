# dotfiles

macOS setup: zsh + p10k, tmux, kitty, Neovim, git, and every CLI tool / app I use daily.

## Fresh machine — one command

```sh
curl -fsSL https://raw.githubusercontent.com/JoanSernaLeiton/dotfiles/main/bootstrap.sh | bash
```

With the optional apps (Slack, Zoom, AnyDesk, Chrome Dev, Firefox):

```sh
curl -fsSL https://raw.githubusercontent.com/JoanSernaLeiton/dotfiles/main/bootstrap.sh | bash -s -- --extras
```

`bootstrap.sh` installs the Xcode Command Line Tools, clones this repo to `~/dotfiles` over HTTPS and runs `install.sh`.

## Already cloned

```sh
./install.sh              # everything
./install.sh --extras     # everything + Brewfile.extras
./install.sh nvim tmux    # specific modules
./install.sh --list       # list modules
```

Modules: `brew zsh git tmux kitty nvim node python claude macos`. Every module is idempotent; existing files are moved to `~/.dotfiles_backup/<timestamp>/` before being replaced by symlinks.

## Layout

| Path | What |
|---|---|
| `Brewfile` / `Brewfile.extras` | Homebrew formulas, casks and fonts |
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
