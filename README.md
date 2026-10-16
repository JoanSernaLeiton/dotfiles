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
| `bin/` | Helpers linked into `~/.local/bin` (`clipcopy`, `clippaste`, `claude-tmux`) |
| `zsh/` | `zshrc`, `p10k.zsh`, `zshrc.local.example` |
| `git/gitconfig`, `git/ignore` | Shared git config and global ignores (`.DS_Store`, Claude worktrees and local settings) |
| `tmux/tmux.conf` | tmux (prefix `C-a`, TPM plugins) |
| `kitty/` | kitty config + theme |
| `nvim/` | Neovim (lazy.nvim, plugin versions pinned in `lazy-lock.json`) |
| `memory/` | launchd plist and systemd unit for the shared memory MCP server |
| `claude/mcp.json` | MCP servers for Claude Code (added at user scope by `./install.sh claude`) |
| `opencode/` | OpenCode config linked into `~/.config/opencode`: `opencode.json` (model, MCPs), `AGENTS.md` (global rules), `plugins/` (`rtk.ts`, `tmux.ts`) |
| `macos.sh` | macOS defaults (key repeat, Finder, Dock, screenshots) |

## Claude Code + tmux

`./install.sh claude` merges hooks into `~/.claude/settings.json` (the rest of that file is left alone) so every Claude session reports its state to tmux through `bin/claude-tmux`:

- The window list shows each Claude pane's state: `●` needs you (permission or question), `✓` finished, `…` working. `✓` clears when you look at the pane.
- When Claude needs you or finishes in a pane you're **not** looking at, you get a desktop notification (macOS: terminal-notifier, falling back to osascript; Linux: notify-send):
  - title — what happened and where: `🔐 dotfiles needs permission`, `❓ … has a question`, `💬 … is waiting for you`, `✅ … is done`
  - subtitle — branch and tmux location: `main · window 2 (dotfiles)` (numbered sessions are hidden)
  - body — what it wants (`Run: git push origin main`, `Edit: install.sh`) or its last message
- macOS: the osascript fallback shows up as "Script Editor" and isn't clickable. Allow notifications for terminal-notifier in System Settings → Notifications and clicking brings your terminal (Terminal, iTerm2, kitty, Ghostty, detected automatically) forward on that pane.
- If it's still waiting after 5 minutes you get a `⏰ … still needs you` reminder (`CLAUDE_REMIND_AFTER` seconds, `0` disables).
- The status bar counts Claude panes across **all** sessions (`●2 ✓1`), shows `🔕` while do-not-disturb is on, and each pane border shows what Claude is waiting on (`→ Run: git push`) plus its context use.
- The Claude status line (bottom of Claude itself) shows `model · ctx% · $cost`; it's only set if you don't already have one.
- Agent teams are enabled with `teammateMode: auto`: inside tmux each teammate gets its own labelled pane. `prefix T` moves the teammates to their own window so the lead keeps the full screen.
- MCP servers `memory` (`http://127.0.0.1:8765/mcp`) and `playwright`, user scope, from `claude/mcp.json`. OpenCode gets the same two from `opencode/opencode.json`. The memory server comes from `./install.sh memory`.
- RTK: `rtk init -g` adds the `rtk hook claude` PreToolUse hook (shell commands go through `rtk` to save tokens) and `~/.claude/RTK.md`. OpenCode uses `opencode/plugins/rtk.ts` for the same thing.
- tmux-resurrect + tmux-continuum save the layout every 10 minutes and restore it when tmux starts; panes that were running Claude come back with `claude --resume` on the same conversation.

| Key | Action |
|---|---|
| `tp` / `prefix f` | Pick a project (open sessions, zoxide, git repos under `CLAUDE_TMUX_PROJECT_ROOTS`, default `~/code ~/projects ~/dotfiles`) → session with a `claude` and an `nvim` window |
| `ct [dir] [args]` | New tmux window named after the project, running `claude` (new session if outside tmux) |
| `ct -w name` / `prefix W` | Same, in a git worktree (`.claude/worktrees/name`, branch `worktree-name`) |
| `prefix a` | Jump to the pane that needs you (then finished ones) |
| `prefix A` | Dashboard: every Claude pane, needs-you first, with a live preview |
| `prefix C` | New Claude window in the current directory |
| `prefix E` | Send the last `CLAUDE_SEND_LINES` (60) lines of this pane into the nearest Claude prompt (same window, then session, then anywhere) without submitting |
| `prefix ?` | Scratch popup (persistent `scratch` session); `prefix ?` again closes it |
| `prefix T` | Move agent-team teammates to their own window |
| `prefix N` | Toggle do-not-disturb (no desktop notifications) |
| `prefix M-t` / `prefix M-v` | Tiled / lead + stack layout for agent teams |
| `prefix Space` | Command palette (has all of the above, plus sync panes and the full key list) |

`prefix f`, `prefix E` and `prefix ?` replace tmux's find-window, spread-layout and list-keys (the key list is in the palette). Hooks only apply to Claude sessions started after `./install.sh claude`.

### Memory server

`./install.sh memory` installs `mcp-memory-service` with `uv tool` (on Homebrew's `python@3.12`: uv's own Pythons can't load the sqlite-vec extension), downloads the multilingual embedding model once, and keeps the server running on `127.0.0.1:8765` with launchd (`memory/com.joan.mcp-memory.plist`) or a systemd user unit (`memory/mcp-memory.service`). It runs offline after that. Data (`sqlite_vec.db`) lives in `~/Library/Application Support/mcp-memory` on macOS and isn't tracked: back it up yourself. Logs: `~/.mcp-memory/logs`.

### OpenCode

`./install.sh opencode` links `opencode/plugins/tmux.ts` into `~/.config/opencode/plugins`. It turns OpenCode events into the same hook calls, so OpenCode panes get the same icons, notifications, reminders, `prefix a`, dashboard and pane border (with cost instead of context %).

OpenCode runs plugins in a shared background service, not in your pane. So the plugin looks for the pane running `opencode` in that project folder. Two OpenCode panes in the same folder are ambiguous and get skipped; start one of them with `opencode --standalone` and that one tracks its own pane. Restart OpenCode after installing (`opencode service restart` if the background service is already up). `OPENCODE_TMUX_LOG=/tmp/oc-tmux.log` logs what the plugin sends.

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
