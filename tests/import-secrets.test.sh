#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-import-secrets-test.XXXXXX")"
trap 'rm -rf "$root"' EXIT

fail_test() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

bin="$root/bin"
stored="$root/stored"
marker="$root/marker"
mkdir -p "$bin" "$stored"

cat >"$bin/op" <<'OP'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-} ${2:-}" == 'item get' ]]; then
  if [[ " $* " == *' --format json '* ]]; then
    printf '%s\n' '{"id":"fake-item","fields":[]}'
  fi
  exit 0
fi
exit 7
OP
chmod +x "$bin/op"

cat >"$bin/jq" <<'JQ'
#!/usr/bin/env bash
set -euo pipefail
label=''
while (($#)); do
  if [[ "$1" == --arg && "${2:-}" == label ]]; then
    label="$3"
    shift 3
  else
    shift
  fi
done
# Drain the producer before returning fixture data so the fake op cannot receive
# SIGPIPE under the importer's pipefail setting.
command cat >/dev/null
if [[ -n "$label" ]]; then
  command cat "$STORED_VALUES/$label"
else
  printf '%s\n' fake-item
fi
JQ
chmod +x "$bin/jq"

source_file="$root/accepted.zshrc"
printf '%s%s%s%s%s' 'single literal $HOME $(touch ' "$marker" ') `touch ' "$marker" '`' \
  >"$stored/AI_COMMIT_HOOK_API_KEY"
printf '%s' 'quote" and slash\ and spaces' >"$stored/STORYBLOK_MCP_TOKEN"
printf '%s' 'plain-token_123-./:@%+=,' >"$stored/TODOIST_MCP_TOKEN"
printf '%s' '  surrounded whitespace  ' >"$stored/NOTION_PRIVATE_TOKEN"
printf '%s' 'another literal' >"$stored/GOOGLE_CLOUD_CLIENT_KEY"
printf "export AI_COMMIT_HOOK_API_KEY='single literal \$HOME \$(touch %s) \`touch %s\`'\n" \
  "$marker" "$marker" >"$source_file"
cat >>"$source_file" <<'EOF_SOURCE'
export STORYBLOK_MCP_TOKEN="quote\" and slash\\ and spaces"
export TODOIST_MCP_TOKEN=plain-token_123-./:@%+=,
export NOTION_PRIVATE_TOKEN='  surrounded whitespace  '
export GOOGLE_CLOUD_CLIENT_KEY="another literal"
EOF_SOURCE
printf 'touch %q\n' "$marker" >>"$source_file"

PATH="$bin:$PATH" STORED_VALUES="$stored" "$DOTFILES_DIR/scripts/import-secrets" "$source_file" >/dev/null
[[ ! -e "$marker" ]] || fail_test "import executed source content"
printf 'ok - accepted literal assignments decode exactly without sourcing Zsh\n'

base="$root/base.zshrc"
cat >"$base" <<'BASE'
export AI_COMMIT_HOOK_API_KEY='safe'
export STORYBLOK_MCP_TOKEN='safe'
export TODOIST_MCP_TOKEN='safe'
export NOTION_PRIVATE_TOKEN='safe'
export GOOGLE_CLOUD_CLIENT_KEY='safe'
BASE

assert_rejected() {
  local name="$1" replacement="$2" candidate="$root/rejected-$1.zshrc" output status
  cp "$base" "$candidate"
  {
    printf '%s\n' "$replacement"
    command tail -n +2 "$base"
  } >"$candidate.tmp"
  mv "$candidate.tmp" "$candidate"
  set +e
  output="$(PATH="$bin:$PATH" STORED_VALUES="$stored" \
    "$DOTFILES_DIR/scripts/import-secrets" "$candidate" 2>&1)"
  status=$?
  set -e
  [[ "$status" -ne 0 ]] || fail_test "$name syntax was accepted"
  [[ "$output" == *"AI_COMMIT_HOOK_API_KEY"* ]] || fail_test "$name rejection was unclear: $output"
}

assert_rejected expansion 'export AI_COMMIT_HOOK_API_KEY="$HOME"'
assert_rejected command-substitution 'export AI_COMMIT_HOOK_API_KEY="$(touch /tmp/nope)"'
assert_rejected backticks 'export AI_COMMIT_HOOK_API_KEY="`touch /tmp/nope`"'
assert_rejected unsupported-escape 'export AI_COMMIT_HOOK_API_KEY="bad\nvalue"'
assert_rejected unescaped-double-quote 'export AI_COMMIT_HOOK_API_KEY="first"second"'
assert_rejected trailing-syntax "export AI_COMMIT_HOOK_API_KEY='safe'; touch /tmp/nope"

ambiguous="$root/ambiguous.zshrc"
cp "$base" "$ambiguous"
printf '%s\n' "export AI_COMMIT_HOOK_API_KEY='second'" >>"$ambiguous"
set +e
output="$(PATH="$bin:$PATH" STORED_VALUES="$stored" \
  "$DOTFILES_DIR/scripts/import-secrets" "$ambiguous" 2>&1)"
status=$?
set -e
[[ "$status" -ne 0 && "$output" == *AI_COMMIT_HOOK_API_KEY* ]] ||
  fail_test "duplicate assignments were not rejected as ambiguous"

multiline="$root/multiline.zshrc"
{
  printf '%s\n' "export AI_COMMIT_HOOK_API_KEY='first"
  printf '%s\n' "second'"
  command tail -n +2 "$base"
} >"$multiline"
set +e
PATH="$bin:$PATH" STORED_VALUES="$stored" "$DOTFILES_DIR/scripts/import-secrets" "$multiline" >/dev/null 2>&1
status=$?
set -e
[[ "$status" -ne 0 ]] || fail_test "multiline assignment was accepted"
printf 'ok - expansions, commands, multiline and ambiguous syntax are rejected\n'
printf 'All import-secrets tests passed.\n'
