#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

assert_argument() {
  local expected="$1" capture="$2"
  grep -Fqx -- "$expected" "$capture" || fail "expected argument: $expected"
}

test_root="$(mktemp -d "${TMPDIR:-/tmp}/herdr-fuzzy-open.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

search_root="$test_root/project with spaces"
fake_bin="$test_root/bin"
rg_capture="$test_root/rg.args"
fzf_capture="$test_root/fzf.args"
fzf_input="$test_root/fzf.input"
open_capture="$test_root/open.args"
editor_capture="$test_root/editor.args"
herdr_capture="$test_root/herdr.args"
selection="$test_root/selection"
helper="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/herdr/.local/bin/herdr-fuzzy-open"
mkdir -p "$search_root/docs" "$search_root/notes" "$fake_bin"
search_root="$(cd "$search_root" && pwd -P)"
printf '<h1>Hello</h1>\n' >"$search_root/docs/page.html"
: >"$search_root/notes/read me.txt"
printf '# Markdown\n' >"$search_root/notes/readme.md"
printf '{"enabled":true}\n' >"$search_root/config.json"
printf 'plain text without an extension\n' >"$search_root/README"
printf 'text with a newline in the filename\n' >"$search_root/notes/line"$'\n'"break.md"
printf '\211PNG\r\n\032\n\000\000\000\rIHDR\000' >"$search_root/image.png"
printf 'docs/page.html\0notes/read me.txt\0notes/readme.md\0config.json\0README\0notes/line\nbreak.md\0image.png\0' >"$selection"

cat >"$fake_bin/rg" <<'RG'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >"$HERDR_TEST_RG_CAPTURE"
cat "$HERDR_TEST_SELECTION"
RG

cat >"$fake_bin/fzf" <<'FZF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >"$HERDR_TEST_FZF_CAPTURE"
cat >"$HERDR_TEST_FZF_INPUT"
[[ "${HERDR_TEST_CANCEL:-0}" == 0 ]] || exit 130
printf '%s\0' "${HERDR_TEST_KEY:-}"
cat "$HERDR_TEST_SELECTION"
FZF

cat >"$fake_bin/open" <<'OPEN'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\0' "$@" >>"$HERDR_TEST_OPEN_CAPTURE"
OPEN
cat >"$fake_bin/nvim" <<'EDITOR'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\0' "$@" >"$HERDR_TEST_EDITOR_CAPTURE"
EDITOR
cat >"$fake_bin/herdr" <<'HERDR'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >>"$HERDR_TEST_HERDR_CAPTURE"
case "$1 $2" in
  'tab create') printf '%s\n' '{"result":{"tab":{"tab_id":"test:t2"},"root_pane":{"pane_id":"test:p2"}}}' ;;
  'pane run') [[ "$3" == test:p2 ]]; zsh -fc "$4" ;;
  'tab focus') [[ "$3" == test:t2 ]] ;;
  *) exit 1 ;;
esac
HERDR
chmod +x "$fake_bin/rg" "$fake_bin/fzf" "$fake_bin/open" "$fake_bin/nvim" "$fake_bin/herdr"

run_helper() {
  PATH="$fake_bin:$PATH" \
  HERDR_ENV=1 \
  HERDR_WORKSPACE_ID="${HERDR_TEST_WORKSPACE_ID-test-workspace}" \
  HERDR_ACTIVE_WORKSPACE_ID="${HERDR_TEST_ACTIVE_WORKSPACE_ID-}" \
  HERDR_BIN_PATH="$fake_bin/herdr" \
  HERDR_ACTIVE_PANE_CWD="$search_root" \
  HERDR_RG_BIN="$fake_bin/rg" \
  HERDR_FZF_BIN="$fake_bin/fzf" \
  HERDR_OPEN_BIN="$fake_bin/open" \
  HERDR_EDITOR_BIN="$fake_bin/nvim" \
  HERDR_TEST_SELECTION="$selection" \
  HERDR_TEST_EDITOR_CAPTURE="$editor_capture" \
  HERDR_TEST_HERDR_CAPTURE="$herdr_capture" \
  HERDR_TEST_KEY="${2:-}" \
  HERDR_TEST_RG_CAPTURE="$rg_capture" \
  HERDR_TEST_FZF_CAPTURE="$fzf_capture" \
  HERDR_TEST_FZF_INPUT="$fzf_input" \
  HERDR_TEST_OPEN_CAPTURE="$open_capture" \
  HERDR_TEST_CANCEL="${1:-0}" \
    "$helper"
}

run_helper

assert_argument --files "$rg_capture"
assert_argument --hidden "$rg_capture"
assert_argument --null "$rg_capture"
assert_argument --read0 "$fzf_capture"
assert_argument --print0 "$fzf_capture"
assert_argument --multi "$fzf_capture"
assert_argument --expect=ctrl-o "$fzf_capture"
assert_argument --disabled "$fzf_capture"
assert_argument --bind=j:down,k:up "$fzf_capture"
assert_argument '--bind=/:enable-search+unbind(j,k,/)+change-prompt(Search> )' "$fzf_capture"
assert_argument '--bind=ctrl-g:disable-search+rebind(j,k,/)+change-prompt(Normal> )' "$fzf_capture"

expected_input="$test_root/expected.input"
cp "$selection" "$expected_input"
cmp "$expected_input" "$fzf_input" || fail "fzf did not receive ripgrep's file list"

printf '%s\0' "$search_root/docs/page.html" "$search_root/notes/read me.txt" \
  "$search_root/notes/readme.md" "$search_root/config.json" "$search_root/README" \
  "$search_root/notes/line"$'\n'"break.md" "$search_root/image.png" >"$test_root/open.expected"
cmp "$test_root/open.expected" "$open_capture" || fail 'Enter did not use the system opener for all files'
[[ ! -e "$editor_capture" && ! -e "$herdr_capture" ]] || fail 'Enter unexpectedly started an editor tab'
printf 'ok - Enter uses the system application for text and binary files\n'

rm "$open_capture"
run_helper 0 ctrl-o
printf '%s\0' -- >"$test_root/editor.expected"
cat "$test_root/open.expected" >>"$test_root/editor.expected"
cmp "$test_root/editor.expected" "$editor_capture" || fail 'Ctrl-O did not pass the selected paths to Neovim'
[[ ! -e "$open_capture" ]] || fail 'Ctrl-O used the system opener'
assert_argument --workspace "$herdr_capture"
assert_argument test-workspace "$herdr_capture"
assert_argument "$search_root" "$herdr_capture"
assert_argument --no-focus "$herdr_capture"
[[ "$(grep -cx create "$herdr_capture")" == 1 ]] || fail 'expected one editor tab'
assert_argument focus "$herdr_capture"
printf 'ok - Ctrl-O opens one editor tab in the caller workspace and passes filenames safely to Zsh\n'

rm "$editor_capture" "$herdr_capture"
run_helper 1

[[ ! -e "$open_capture" ]] || fail "cancelled selection unexpectedly called open"
[[ ! -e "$editor_capture" ]] || fail "cancelled selection unexpectedly called Neovim"
[[ ! -e "$herdr_capture" ]] || fail 'cancelled selection created a tab'
printf 'ok - cancelling the picker closes it without opening a file\n'

quoted_name='notes/it'"'"'s $(echo literal).md'
: >"$search_root/$quoted_name"
printf '%s\0' "$quoted_name" >"$selection"
run_helper 0 ctrl-o
printf '%s\0' -- "$search_root/$quoted_name" >"$test_root/quoted.expected"
cmp "$test_root/quoted.expected" "$editor_capture" || fail 'shell metacharacters were interpreted'
printf 'ok - quotes and command substitution characters in filenames stay literal\n'

: >"$herdr_capture"
HERDR_TEST_WORKSPACE_ID='' HERDR_TEST_ACTIVE_WORKSPACE_ID=popup-workspace run_helper 0 ctrl-o
assert_argument popup-workspace "$herdr_capture"
printf 'ok - popup context works without a normal pane workspace ID\n'

: >"$herdr_capture"
HERDR_TEST_WORKSPACE_ID=stale-workspace HERDR_TEST_ACTIVE_WORKSPACE_ID=popup-workspace run_helper 0 ctrl-o
assert_argument popup-workspace "$herdr_capture"
! grep -Fqx stale-workspace "$herdr_capture" || fail 'popup used an inherited workspace instead of its caller'
printf 'ok - popup workspace takes precedence over inherited pane context\n'

# Both Stow packages must provide the same routing behavior.
repo_dir="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cmp "$helper" "$repo_dir/herdr-linux/.local/bin/herdr-fuzzy-open" || fail 'platform helpers differ'
