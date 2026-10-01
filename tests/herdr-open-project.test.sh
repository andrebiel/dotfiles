#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

test_root="$(mktemp -d "${TMPDIR:-/tmp}/herdr-open-project.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

repo_dir="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
helper="$repo_dir/herdr/.local/bin/herdr-open-project"
fake_bin="$test_root/bin"
open_capture="$test_root/open.args"
project="$test_root/project with spaces"
mkdir -p "$fake_bin" "$project/src/deep" "$test_root/plain dir"
project="$(cd "$project" && pwd -P)"
plain_dir="$(cd "$test_root/plain dir" && pwd -P)"
git -C "$project" init -q

cat >"$fake_bin/open" <<'OPEN'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\0' "$@" >"$HERDR_TEST_OPEN_CAPTURE"
OPEN
chmod +x "$fake_bin/open"

run_helper() {
  rm -f "$open_capture"
  HERDR_OPEN_BIN="$fake_bin/open" HERDR_TEST_OPEN_CAPTURE="$open_capture" \
    HERDR_ACTIVE_PANE_CWD="$1" "$helper"
}

run_helper "$project/src/deep"
printf '%s\0' "$project" >"$test_root/expected"
cmp "$test_root/expected" "$open_capture" || fail 'a nested pane did not open its Git project root'
printf 'ok - a pane inside a repository opens the project root\n'

run_helper "$plain_dir"
printf '%s\0' "$plain_dir" >"$test_root/expected"
cmp "$test_root/expected" "$open_capture" || fail 'a pane outside Git did not open its own directory'
printf 'ok - a pane outside Git opens its own directory\n'

if run_helper "$test_root/missing" 2>/dev/null; then
  fail 'a missing pane directory was opened'
fi
[[ ! -e "$open_capture" ]] || fail 'a missing pane directory reached the opener'
printf 'ok - a missing pane directory fails without opening anything\n'

# Both Stow packages must provide the same helper.
cmp "$helper" "$repo_dir/herdr-linux/.local/bin/herdr-open-project" || fail 'platform helpers differ'
