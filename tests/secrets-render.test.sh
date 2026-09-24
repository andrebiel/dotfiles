#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-secrets-render-test.XXXXXX")"
trap 'rm -rf "$root"' EXIT
real_zsh="$(command -v zsh)"

fail_test() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

home="$root/home"
bin="$root/bin"
values="$root/values"
marker="$root/marker"
mkdir -p "$home" "$bin" "$values"

{
  printf '%s' "quote'\""
  printf '%s' ' dollar $HOME $(touch '
  printf '%s' "$marker"
  printf '%s' ') `touch '
  printf '%s' "$marker"
  printf '%s' '` slash\ space '
} >"$values/AI_COMMIT_HOOK_API_KEY"
printf 'first line\nsecond line\n' >"$values/STORYBLOK_MCP_TOKEN"
printf '%s' '  leading and trailing  ' >"$values/TODOIST_MCP_TOKEN"
printf '%s' '\backslash\path\' >"$values/NOTION_PRIVATE_TOKEN"
printf '%s' 'plain-value' >"$values/GOOGLE_CLOUD_CLIENT_KEY"

cat >"$bin/op" <<'OP'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-} ${2:-}" in
  'item get') exit 0 ;;
  'read '*)
    reference="$2"
    label="${reference##*/}"
    [[ -f "$OP_VALUES/$label" ]] || exit 3
    output=''
    shift 2
    while (($#)); do
      if [[ "$1" == --out-file ]]; then
        output="$2"
        shift 2
      else
        shift
      fi
    done
    [[ -n "$output" ]] || exit 5
    command cp "$OP_VALUES/$label" "$output"
    ;;
  *) exit 4 ;;
esac
OP
chmod +x "$bin/op"

cat >"$bin/zsh" <<ZSH
#!/usr/bin/env bash
set -euo pipefail
if [[ "\${FAIL_ZSH_VALIDATION:-0}" == 1 && "\${1:-}" == -n ]]; then
  exit 9
fi
exec "$real_zsh" "\$@"
ZSH
chmod +x "$bin/zsh"

render_output="$root/render-output"
PATH="$bin:$PATH" HOME="$home" OP_VALUES="$values" \
  "$DOTFILES_DIR/bootstrap" secrets >"$render_output" 2>&1
secret_file="$home/.config/zsh/secrets.zsh"
[[ -f "$secret_file" ]] || fail_test "rendered secret file is missing"
[[ "$(<"$render_output")" != *plain-value* && "$(<"$render_output")" != *"quote'\""* ]] ||
  fail_test "bootstrap printed secret content"
if [[ "$(uname -s)" == Darwin ]]; then
  rendered_mode="$(stat -f '%Lp' "$secret_file")"
else
  rendered_mode="$(stat -c '%a' "$secret_file")"
fi
[[ "$rendered_mode" == 600 ]] || fail_test "rendered secret mode is not 600"
"$real_zsh" -n "$secret_file" || fail_test "rendered file is not valid Zsh"

for name in AI_COMMIT_HOOK_API_KEY STORYBLOK_MCP_TOKEN TODOIST_MCP_TOKEN NOTION_PRIVATE_TOKEN GOOGLE_CLOUD_CLIENT_KEY; do
  actual="$root/actual-$name"
  NAME="$name" SECRET_FILE="$secret_file" "$real_zsh" -fc '
    source "$SECRET_FILE"
    print -rn -- "${(P)NAME}"
  ' >"$actual"
  cmp -s "$values/$name" "$actual" || fail_test "$name did not round-trip exactly"
done
[[ ! -e "$marker" ]] || fail_test "vault content executed while sourcing rendered secrets"
printf 'ok - arbitrary secret data renders as inert, exact Zsh literals\n'

printf '%s\n' 'existing target' >"$secret_file"
set +e
PATH="$bin:$PATH" HOME="$home" OP_VALUES="$values" FAIL_ZSH_VALIDATION=1 \
  "$DOTFILES_DIR/bootstrap" secrets >/dev/null 2>&1
status=$?
set -e
[[ "$status" -ne 0 ]] || fail_test "syntax-validation failure unexpectedly succeeded"
[[ "$(<"$secret_file")" == 'existing target' ]] || fail_test "syntax failure replaced the existing target"
if compgen -G "$home/.config/zsh/.secrets.zsh.*" >/dev/null ||
   compgen -G "$home/.config/zsh/.secret-value.*" >/dev/null; then
  fail_test "plaintext temporary files remained after failure"
fi
printf 'ok - syntax failure preserves target and cleans plaintext temporaries\n'

assert_no_plaintext_remnants() {
  local target_dir="$1"
  if compgen -G "$target_dir/.secrets.zsh.*" >/dev/null ||
     compgen -G "$target_dir/.secret-value.*" >/dev/null; then
    fail_test "plaintext temporary files remained after unsafe-target failure"
  fi
}

rm -f -- "$secret_file"
mkdir "$secret_file"
set +e
PATH="$bin:$PATH" HOME="$home" OP_VALUES="$values" \
  "$DOTFILES_DIR/bootstrap" secrets >/dev/null 2>&1
status=$?
set -e
[[ "$status" -ne 0 ]] || fail_test "directory secret target was accepted"
[[ -d "$secret_file" && ! -L "$secret_file" ]] || fail_test "directory secret target was changed"
[[ -z "$(find "$secret_file" -mindepth 1 -print -quit)" ]] ||
  fail_test "plaintext was moved inside the directory secret target"
assert_no_plaintext_remnants "$home/.config/zsh"
printf 'ok - directory secret target is rejected without plaintext remnants\n'

rmdir "$secret_file"
outside="$root/outside-secret-target"
mkdir "$outside"
ln -s "$outside" "$secret_file"
set +e
PATH="$bin:$PATH" HOME="$home" OP_VALUES="$values" \
  "$DOTFILES_DIR/bootstrap" secrets >/dev/null 2>&1
status=$?
set -e
[[ "$status" -ne 0 ]] || fail_test "symlink secret target was accepted"
[[ -L "$secret_file" && "$(readlink "$secret_file")" == "$outside" ]] ||
  fail_test "symlink secret target was changed"
[[ -z "$(find "$outside" -mindepth 1 -print -quit)" ]] ||
  fail_test "plaintext was moved through the symlink secret target"
assert_no_plaintext_remnants "$home/.config/zsh"
printf 'ok - symlink secret target is rejected without plaintext remnants\n'

printf 'All secret rendering tests passed.\n'
