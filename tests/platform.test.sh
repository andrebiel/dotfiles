#!/usr/bin/env bash
set -euo pipefail
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
for platform in macos linux; do
  home="$root/$platform"
  mkdir -p "$home"
  mkdir -p "$home/.local/bin"
  case "$platform" in macos) old_package=herdr;; linux) old_package=herdr-linux;; esac
  ln -s "$DOTFILES_DIR/$old_package/.local/bin/herdr-fresh-worktree" "$home/.local/bin/herdr-fresh-worktree"
  HOME="$home" "$DOTFILES_DIR/bootstrap" link --platform "$platform" >/dev/null
  [[ ! -L "$home/.local/bin/herdr-fresh-worktree" ]] || { echo "not ok - $platform retired worktree helper remains" >&2; exit 1; }
  [[ "$(realpath "$home/.zshrc")" == "$DOTFILES_DIR/zsh/.zshrc" ]]
  [[ "$(realpath "$home/.config/nvim/init.lua")" == "$DOTFILES_DIR/nvim/.config/nvim/init.lua" ]]
  [[ -L "$home/.ssh/config" ]]
  [[ -L "$home/.config/herdr/config.toml" ]] || { echo "not ok - $platform Herdr config missing" >&2; exit 1; }
  for helper in herdr-fuzzy-open; do
    [[ -x "$home/.local/bin/$helper" ]] || { echo "not ok - $platform $helper missing" >&2; exit 1; }
  done
  grep -Fqx 'directory = "~/dev/worktrees"' "$home/.config/herdr/config.toml" || { echo "not ok - $platform worktree directory is not portable" >&2; exit 1; }
  for shell_mode in -ic -lic; do
    env -u ZDOTDIR HOME="$home" XDG_CONFIG_HOME="$home/.config" \
      XDG_CACHE_HOME="$home/.cache" zsh "$shell_mode" \
      '[[ ${aliases[vim]} == nvim && -o aliases ]]'
  done
  if [[ "$platform" == macos ]]; then
    [[ -L "$home/Library/LaunchAgents/dev.andrebiel.ai-usage.plist" ]]
    [[ -L "$home/.config/herdr/config.toml" ]]
  else
    [[ ! -e "$home/Library" ]]
    ! grep -q 'ai-usage' "$home/.config/herdr/config.toml"
  fi
  # A rerun must preserve already-correct symlinks.
  HOME="$home" "$DOTFILES_DIR/bootstrap" --platform "$platform" link >/dev/null
  printf 'ok - %s links and repeated setup\n' "$platform"
done
for args in '--platform invalid link' '--platform' 'link --reload' 'migrate --without-secrets' 'link doctor'; do
  if "$DOTFILES_DIR/bootstrap" $args >/dev/null 2>&1; then
    echo "not ok - invalid arguments accepted: $args" >&2; exit 1
  fi
done
printf 'ok - invalid options fail before installation\n'
case "$(uname -s)" in Darwin) other=linux;; Linux) other=macos;; esac
if "$DOTFILES_DIR/bootstrap" install --platform "$other" >/dev/null 2>&1; then
  echo 'not ok - installation allowed on the wrong OS' >&2; exit 1
fi
printf 'ok - wrong-OS installation rejected\n'
env -u CLAUDE_CONFIG_DIR -u CODEX_HOME -u CURSOR_CONFIG_DIR HOME="$root/linux" "$DOTFILES_DIR/bootstrap" integrations --platform linux >/dev/null
jq -e '.statusLine.type == "command"' "$root/linux/.claude/settings.json" >/dev/null
before="$(cksum "$root/linux/.claude/settings.json")"
env -u CLAUDE_CONFIG_DIR -u CODEX_HOME -u CURSOR_CONFIG_DIR HOME="$root/linux" "$DOTFILES_DIR/bootstrap" integrations --platform linux >/dev/null
[[ "$before" == "$(cksum "$root/linux/.claude/settings.json")" ]]
printf 'ok - Linux integrations preserve settings on repeat\n'
python3 - "$DOTFILES_DIR/bootstrap" "$other" <<'PY'
import os, pty, select, subprocess, sys, time
master, slave = pty.openpty()
env = dict(os.environ)
env.pop('DOTFILES_PLATFORM', None)
process = subprocess.Popen([sys.argv[1], 'install'], stdin=slave, stdout=slave, stderr=slave, env=env)
os.close(slave)
output = b''
try:
    deadline = time.monotonic() + 10
    while b'Set up this machine as MacBook (macos) or Linux?' not in output:
        if time.monotonic() > deadline:
            raise AssertionError('interactive platform prompt did not appear')
        if select.select([master], [], [], 0.1)[0]:
            output += os.read(master, 4096)
    os.write(master, (sys.argv[2] + '\n').encode())
    assert process.wait(timeout=10) != 0, 'wrong-platform choice accepted'
finally:
    if process.poll() is None:
        process.kill()
        process.wait()
    os.close(master)
print('ok - interactive setup offers MacBook/Linux and rejects wrong host')
PY
