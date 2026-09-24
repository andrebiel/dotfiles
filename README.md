# dotfiles

Portable macOS and Linux configuration for Zsh, Oh My Posh, Ghostty, Herdr, Neovim, and
SSH. GNU Stow creates file-level symlinks while 1Password supplies machine-local
shell secrets.

## First setup

Clone this repository to `~/dotfiles`, then run:

```sh
./bootstrap
```

Interactive `all`, `install`, and `migrate` ask **MacBook (macos) or Linux**, with
this machine's detected OS as the default. Press Enter to accept it. Unattended
runs detect the OS automatically. Explicit selection works in either position:

```sh
./bootstrap all --platform macos
./bootstrap --platform linux all
```

Installation rejects a platform that does not match the running machine. It
cannot install onto your Mac from a Linux server.

The MacBook profile installs Homebrew when missing, the Brewfile packages,
Node LTS and pnpm, and the full desktop configuration including Ghostty, Herdr,
CodexBar and the AI usage LaunchAgent.

The Linux profile supports **Ubuntu/Debian on x86_64 or arm64**. It installs Zsh,
its plugins, Stow, Neovim 0.12, Oh My Posh, Node LTS/npm/pnpm, Bun, ripgrep, fzf, Lazygit,
GitHub CLI, Granted, Tree-sitter CLI, Herdr, and 1Password CLI. It links the shared
Zsh, Neovim, prompt and SSH configuration, the Linux Herdr configuration and
file-picker helper, installs Claude Code through its official native installer,
and configures the Claude status line. Claude Code updates itself; signing in
remains a per-machine step.
It uses apt (sudo for non-root users) and official upstream downloads. Ghostty,
CodexBar and launchd are excluded from this Linux server profile; their macOS
paths and jobs are not linked. Herdr is installed or updated from the official
checksum-verified release, and its agent integrations are updated. Other Linux
distributions report an unsupported
package manager instead of attempting Homebrew/cask installation.

### 1Password: desktop or terminal sign-in

The credential provider is **1Password**, not OneLogin. Both profiles support:

- **Desktop integration:** install/open/unlock 1Password, then enable
  **Settings → Developer → Connect with 1Password CLI**. The MacBook profile
  installs the desktop app; on Linux install it separately if you want this method.
- **Terminal sign-in:** on a server without the desktop app, run
  `./bootstrap auth` in your own terminal. It adds an account if necessary,
  signs in, and renders secrets within that same session. Enter credentials
  only into the CLI prompts, never into this repository or chat.

The vault must contain `Private/Dotfiles` with the fields listed in
`secrets/secrets.zsh.tpl`. `auth` does not invent or create missing secret values.
Use `migrate` below if an old `.zshrc` contains the existing values.

You can finish the public configuration before signing in:

```sh
./bootstrap all --without-secrets
./bootstrap auth
./bootstrap doctor
```

`--without-secrets` explicitly skips secret rendering and verification; it does
not delete an existing secret file. `doctor --without-secrets` checks the installed
public configuration only. Plain `doctor` requires the local secrets file and
nonempty managed values. To refresh from an already authenticated shell, run
`./bootstrap secrets`.

Launch Zsh with `exec zsh -l` after setup. The bootstrap does not change your
account's login shell. On this Linux host, set it persistently with
`chsh -s /usr/bin/zsh` in your terminal (requires your account password), then
reconnect. The `vim` → `nvim` alias is loaded by interactive Zsh;
after updating dotfiles, restart Zsh with the same command. Check it with
`whence -v vim`. Configure a Nerd Font in your terminal for prompt icons;
on a server this font belongs on your terminal's client machine.
Provision `~/.ssh/id_ed25519` separately or update the SSH identities. The tracked
`~/.ssh/config` only includes other files: put your `Host` blocks with addresses,
users and remote commands in `~/.ssh/config.d/` (created by `./bootstrap link`),
which is never tracked. GitHub CLI also needs your own `gh auth login -h github.com`
before authenticated operations.

In interactive Zsh, `claude` starts with `--dangerously-skip-permissions`, and
`codex` starts with `--dangerously-bypass-approvals-and-sandbox`. These aliases
disable permission prompts; Codex also runs without its sandbox. Use
`command claude` or `command codex` to bypass the alias for one invocation.
Herdr explicitly starts Zsh login shells on both platforms, even when its
persistent server inherited `SHELL=/bin/bash`. Interactive Zsh also exports its
own executable as `SHELL` for child tools. After updating, reload Herdr's config
and run `exec zsh -l` once in any already-open Bash pane.

## Existing-machine migration

Run the migration command. It installs dependencies, imports the active values
from the old Zsh file, renders the local secret file, links managed
configuration, updates integrations, registers the AI usage LaunchAgent, and
runs `doctor`:

```sh
./bootstrap migrate
```

The import command sends a JSON item directly to 1Password over standard input.
It does not put values in command arguments, logs, Git, or temporary files.
It creates `Private/Dotfiles`. If a previous migration already created that
item, it verifies every stored value against the source and resumes only when
they match; mismatches are never overwritten automatically.

The importer reads data from the old file; it never sources or evaluates it.
Each managed name must appear exactly once as `export NAME=VALUE` on one line.
`VALUE` may be a single-quoted literal without embedded single quotes, a
double-quoted literal using only `\"` and `\\` escapes and no `$` or backticks,
or an unquoted token made from letters, digits, `_./:@%+=,-`. Empty values,
expansions, command substitutions, multiline values, comments, trailing shell
syntax, and ambiguous duplicate assignments are rejected. Rewrite an
unsupported legacy assignment into one of these literal forms before migration.

Secret rendering reads each reference in `secrets/secrets.zsh.tpl` as data and
asks Zsh to encode the result as an inert literal assignment. The generated file
is syntax-checked with Bash and Zsh before an atomic replacement, and plaintext
temporary files are removed on errors and signals. Both shells use
`~/.config/zsh/environment.sh` to load the same local `~/.config/zsh/secrets.zsh`;
the `.zsh` suffix does not imply a second Bash copy. Zsh loads it from `.zshenv`,
including for non-interactive SSH commands. `./bootstrap link` prepends a small
hook to the existing `.bashrc` and first active Bash login file (`.bash_profile`,
`.bash_login`, or `.profile`), preserving their contents. These hooks are added
after the managed-link transaction commits and are not rolled back with links.
The `.bashrc` hook runs before any interactive-only early return.

The shared loader exports `BASH_ENV` so subsequent non-interactive Bash scripts
also load it. A standalone `bash -c` started with a completely empty environment
outside SSH cannot discover this file automatically; give that invocation
`BASH_ENV="$HOME/.config/zsh/environment.sh"` or use `bash -lc`.
See the [Bash startup rules](https://www.gnu.org/s/bash/manual/html_node/Bash-Startup-Files.html).
Programs started from these shells inherit the exported credentials.
Treat shell descendants, diagnostics, process
inspection, and environment dumps accordingly; refresh or remove the file when
that exposure is not acceptable.

`./bootstrap link` refuses to replace an old `.zshrc` while managed plaintext
secret assignments are still present. `./bootstrap migrate` holds that file in
a mode-`700` temporary directory while changing links. It restores the original
file and managed-file conflicts if a later migration step fails, and deletes the
protected original only after the final checks pass.

## Transaction and backup boundaries

There is no global transaction around `all` or `migrate`. The recoverable
boundary covers only files and links in the managed-path list while Stow is
running. A failed link transaction removes links it created and moves backed-up
conflicts into place again. In `migrate`, that managed-file recovery remains
active through the final checks so the original `.zshrc` can also be restored.

Package installation, Node/corepack changes, creation or verification of the
1Password item, the rendered `secrets.zsh`, Claude/Herdr integration writes, and
launchd registration are external side effects and are **not** rolled back as a
unit. A failure can therefore leave those successful earlier changes in place.
Package rollback is intentionally not attempted. Integration and launchd
changes run after the managed-link commit where practical.

Before replacing a regular managed file, `link` moves it to a unique directory
under `~/.dotfiles-backup/`. Already-correct links and paths that did not exist
have no backup entry. Backups are retained after success for manual recovery:

```sh
# List backup runs, then inspect one without following or modifying it.
find "$HOME/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d -print
backup="$HOME/.dotfiles-backup/20260101-120000-12345-6789"
find "$backup" -mindepth 1 -print

# Restore one file after checking that the current target is the managed link.
relative=.zshrc
readlink "$HOME/$relative"
unlink "$HOME/$relative"
mkdir -p "$(dirname "$HOME/$relative")"
mv "$backup/$relative" "$HOME/$relative"
```

Restore only entries you have inspected; do not overwrite an unexpected current
target. Once a backup run is no longer needed, prune that specific, fully
qualified directory with `rm -rf -- "$backup"`. There is no automatic retention
policy or bulk restore command.

## Commands

- `./bootstrap install` installs the selected platform dependencies, Neovim,
  nvm, the latest Node LTS (including npm), and pnpm.
- `./bootstrap all` performs the complete first-setup sequence described above;
  only its managed-file/link operation has rollback protection.
- `./bootstrap migrate` performs the complete existing-machine sequence and
  protects the old `.zshrc` and recoverable managed files, not external writes.
- `./bootstrap secrets` refreshes `~/.config/zsh/secrets.zsh` from 1Password.
- `./bootstrap integrations` safely merges supported external-tool settings,
  including the Claude Code status line and Herdr integrations for Claude Code,
  Codex, Cursor Agent CLI, and Hermes Agent, plus the official Herdr skill for
  Codex and Claude Code.
- `./bootstrap usage` ensures the five-minute local AI usage refresh job is
  loaded without restarting a detectably current job. Add `--reload` to force a
  replacement.
- `./bootstrap link` backs up non-secret conflicts and refreshes Stow links.
- `./bootstrap doctor` validates syntax, links, and effective app configuration.
  Its launchd check proves registration only, not that every refresh is healthy.
- `./scripts/check` runs non-destructive static checks.

pnpm is intentionally pinned by `PNPM_VERSION` near the top of `bootstrap`.
Update that constant explicitly after checking the new release's Node engine
requirement against the latest Node LTS installed by `nvm install --lts`; do not
replace the pin with a moving tag such as `latest`.

## Split DNS for a VPN domain alongside Tailscale (macOS, optional)

Some company VPNs need their own nameservers for the company domain while
Tailscale keeps MagicDNS for everything else. The repository stores no
domain, nameserver, VPN profile or credential; pass your own values. Install
the VPN profile in Tunnelblick separately, disconnect it, quit Tunnelblick,
and run as your normal user:

```sh
./scripts/setup-split-dns --profile company_vpn corp.example 192.0.2.53 192.0.2.54
```

`--profile` is the Tunnelblick profile name, followed by the domain and one or
more nameserver addresses. This writes `/etc/resolver/<domain>` with
administrator authentication so only that domain and its subdomains use the
given nameservers. The script also sets the selected Tunnelblick profile to
**Do not set nameserver** and leaves IPv6 enabled. Tailscale keeps its existing
DNS settings and MagicDNS. Reopen Tunnelblick and connect after setup. This
command is opt-in and is not run by `bootstrap`.

Repeat on each Mac after cloning/updating dotfiles. Use fully qualified names
such as `host.corp.example`; this setup does not add a global search suffix for
short names, so update saved RDP or SMB connections to the full name. The
nameservers are only reachable through the VPN or company LAN; this DNS rule
does not establish that connection.

Setup saves the installed resolver, the previous resolver if any, and the two
modified preferences under `~/.dotfiles-backup/split-dns.<domain>.XXXXXX/`. To
revert, disconnect and quit Tunnelblick and run the exact `undo` path printed
by setup, as your normal user. Repeated setup with the same values is a no-op
when the file and preferences already match.

With both VPNs connected, verify using the macOS system resolver (plain `dig`
does not exercise macOS domain-specific resolver selection):

```sh
dscacheutil -q host -a name host.corp.example
dscacheutil -q host -a name example.com
dscacheutil -q host -a name YOUR-DEVICE.YOUR-TAILNET.ts.net
curl -I --max-time 10 https://example.com
```

Also verify reconnection in both VPN start orders. The DNS settings are
documented in [Tunnelblick preferences](https://tunnelblick.net/cPreferences.html)
and macOS `man 5 resolver`.

## Terminal and editor theme

Ghostty is fully opaque, uses the native macOS title bar, and uses its bundled
Catppuccin Mocha theme. Oh My Posh uses matching local configurations: Zsh has
a green `LOCAL user@machine` or peach `SSH user@machine` indicator, the full
directory path (`~` for home), and Git status with command input below it. The
shared context also appears in Claude Code, which
adds its active model and session cost. Agents without a native Oh My Posh
status-line integration do not show guessed values. Neovim 0.12 uses its
bundled Catppuccin colorscheme in dark mode (Mocha), and Herdr uses its matching
built-in `catppuccin` theme with a 32-column sidebar and workspace/branch rows.
Herdr cycles directly between spaces with Control+Option+J/K on macOS.
Neovim uses Space as both leader keys and installs the stable `mini.pick`
release with Neovim's built-in package manager. Ripgrep supplies fast,
`.gitignore`-aware file and text search.

Neovim also provides Tree-sitter highlighting, completion, diagnostics, and
LSP features. Mason installs the configured language servers automatically:

- JavaScript, TypeScript, and Bun projects: vtsls and ESLint.
- Svelte components: Svelte Language Server.
- Python: BasedPyright and Ruff.
- Lua and shell scripts.
- HTML, CSS, JSON, YAML, TOML, and Markdown.

Bun uses the TypeScript language service. Add `@types/bun` to each Bun project
with `bun add -d @types/bun` so the editor knows about Bun's global APIs.

Useful normal-mode mappings:

- `<Space>ff` fuzzy-finds files.
- `<Space>fg` searches project text as you type.
- `<Space>fb` switches buffers; `<Space>fh` searches help.
- `<Space>fr` resumes the last picker; `<Space>w` saves.
- `<Space>yyy` copies the current line to the system clipboard, or the selection
  in visual mode.
- `gd`/`gD` jumps to a definition/declaration.
- `<Space>la` applies a code action; `<Space>lr` renames a symbol.
- `<Space>ld` shows diagnostics; `<Space>lf` formats via the active LSP.
- `<Space>lh` toggles inlay hints.
- `<C-h/j/k/l>` moves between windows.

Inside a picker, use `<C-n>`/`<C-p>` to move, `<CR>` to open, `<Tab>` to
preview, and `<Esc>` to close. The picker is downloaded automatically on the
first normal Neovim launch; update managed plugins with
`:lua vim.pack.update()` and then update parsers with `:TSUpdate`.

Completion appears while typing. Use `<C-n>`/`<C-p>` to select a suggestion,
`<C-y>` to accept it, `<C-Space>` to open completion manually, and `<C-k>` for
signature help. Run `:Mason` to inspect installed tools and `:LspInfo` to
inspect the servers attached to the current buffer.

Parser installation requires the Tree-sitter CLI, a C compiler, `curl`, and
`tar`. To repair a missing CLI on an existing Linux setup, run
`bash scripts/install-tree-sitter` from this repository; on macOS run
`brew install tree-sitter-cli`. Restart Neovim and let the initial parser
installation finish. Use `:checkhealth nvim-treesitter` to check dependencies.

The managed configuration files are linked to `~/.config/nvim/init.lua`,
`~/.config/herdr/config.toml`, `~/.config/oh-my-posh/`, and
`~/Library/Application Support/com.mitchellh.ghostty/config`.

## Herdr agent skill

`./bootstrap integrations` installs the [official Herdr skill](https://herdr.dev/docs/agent-skill/)
for Codex CLI and Claude Code on macOS and Linux. This also runs during
`./bootstrap all` and `./bootstrap migrate`.

The instructions come from `herdr --skill`, matching the installed Herdr release.
Codex reads `~/.agents/skills/herdr/SKILL.md`; Claude Code uses a symlink at
`~/.claude/skills/herdr` (or `$CLAUDE_CONFIG_DIR/skills/herdr` when configured).
No MCP server or separate npm package is needed.

Inside a Herdr terminal, invoke `$herdr` in Codex or `/herdr` in Claude Code,
for example: `List the panes in my current Herdr workspace.` Newly installed
skills should appear on the next turn; restart the CLI if the skill is missing.
The skill requires `HERDR_ENV=1`, so start the agent inside Herdr.

After updating Herdr, rerun `./bootstrap integrations` to refresh the skill.
Unchanged files stay untouched; replaced instructions are backed up next to
`SKILL.md`. Conflicting installations are reported rather than overwritten.
`./scripts/install-herdr-skill --check` verifies the shared skill and Claude link
without changing them; both platform doctors include this check.

## Herdr Lazygit

Press `Ctrl+Space`, release, then `Alt+G` (`Option+G` on macOS) to open Lazygit
in the active pane's directory. The popup uses 90% of the terminal width and
height. Press `q` to close it. Lazygit is installed by both platform profiles.

## Herdr worktrees

Press `Ctrl+Space`, then `w` to open the searchable Goto picker (`goto`).
The `workspace_picker` binding is disabled because it enters Navigate mode.
Press `Ctrl+Space`, then `t` to open Herdr's built-in New worktree dialog.
Existing local branches are
checked out directly; new branches start from the current `HEAD`. No automatic
fetch or copying of local environment files is performed.

Herdr stores checkouts in `~/dev/worktrees/<repo>/<branch-slug>` on the machine
hosting the repository. On SSH hosts, `~` is the remote user's home directory.
Both macOS and Linux profiles configure this location. Existing worktrees
elsewhere remain where they are and can still be opened through Herdr.
Use `Ctrl+Space`, then `c` for another tab in the current workspace and directory.
Press `Ctrl+Space`, release, then `Shift+E` to open and focus a new Neovim tab
in the current workspace, starting in the active pane's directory. From Neovim,
use `Space`, then `ff` to find a file. Plain prefix `e` still edits scrollback.

Press `Ctrl+Space`, then `d` to close a workspace without removing its checkout.
Press `Ctrl+Space`, then `Shift+D` on a worktree workspace to run Herdr's
confirmed worktree removal. This closes the workspace and removes the checkout
directory while keeping its Git branch. Dirty or untracked files require an
additional forced-removal confirmation.

Press `Ctrl+Space`, then `f` to fuzzy-find files below the active pane's current
directory in a Herdr popup. The picker includes hidden files, respects ignore
files such as `.gitignore`, and starts in a Vim-style navigation mode. Use
`j`/`k` to move, `/` to enter fuzzy-search mode, and `Ctrl+G` to return to
navigation. Press `Tab` to select multiple files. `Enter` opens the selection
with the system application (`open` on macOS, `xdg-open` on Linux; a desktop
session is needed there). `Ctrl+O` closes the picker and opens Neovim in a new,
focused Herdr tab in the same workspace and directory. Multiple selected files
become buffers in that one editor. `Esc` cancels the picker.
Set `HERDR_EDITOR_BIN` to override the editor executable and `HERDR_OPEN_BIN`
to override the system opener.

## AI usage

Press `Ctrl+Space`, then `u` in Herdr to open the full terminal dashboard. It
shows estimated API-equivalent cost and tokens for today, 7 days, and 30 days,
provider/model breakdowns, current Codex/Claude/Cursor limits, and Cursor's
accepted-versus-suggested lines. Press `r` to refresh limits and `q` or `Esc` to
close the popup.

The dashboard uses the CodexBar CLI only; it does not install or run the macOS
menu bar app. Codex and Claude costs come from local native session logs. Cursor
locally exposes accepted and suggested line counts rather than defensible token
costs, so Cursor is excluded from the dollar estimate. The displayed dollars
are an API-price estimate, not subscription billing.

`dev.andrebiel.ai-usage` refreshes the local history cache every five minutes.
Online quota checks happen when the popup opens or when `r` is pressed. Cached
data lives under `~/Library/Caches/ai-usage/`; prompts and responses are never
copied into that cache.

SSH keys, `known_hosts`, per-machine SSH hosts in `~/.ssh/config.d/`,
Conductor-generated configuration, VPN domains and nameservers, OAuth files,
histories, backups, and rendered secrets are intentionally not tracked.
