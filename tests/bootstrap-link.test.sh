#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-link-test.XXXXXX")"
trap 'rm -rf "$temporary_root"' EXIT

fail_test() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

make_fake_stow() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat >"$bin_dir/stow" <<'STOW'
#!/usr/bin/env bash
set -euo pipefail
for argument in "$@"; do
  [[ "$argument" == --simulate ]] && exit 0
done
ln -s "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
ln -s "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
exit 42
STOW
  chmod +x "$bin_dir/stow"
}

assert_file_content() {
  local expected="$1" file="$2"
  [[ -f "$file" && ! -L "$file" ]] || fail_test "$file was not restored as a regular file"
  [[ "$(<"$file")" == "$expected" ]] || fail_test "$file content changed"
}

test_partial_stow_rollback() {
  local case_root="$temporary_root/partial" home="$temporary_root/partial/home"
  local bin_dir="$temporary_root/partial/bin" output status cache_file
  mkdir -p "$home" "$case_root"
  make_fake_stow "$bin_dir"
  printf '%s\n' original-zshrc >"$home/.zshrc"
  printf '%s\n' unrelated >"$home/keep-me"
  ln -s "$DOTFILES_DIR/zsh/.zshenv" "$home/.zshenv"
  cache_file="$home/.cache/p10k-dump-$(id -un).zsh"
  mkdir -p "$(dirname "$cache_file")"
  printf '%s\n' retired-cache >"$cache_file"

  set +e
  output="$(HOME="$home" PATH="$bin_dir:$PATH" DOTFILES_DIR="$DOTFILES_DIR" \
    DOTFILES_BACKUP_TIMESTAMP=partial-failure "$DOTFILES_DIR/bootstrap" link 2>&1)"
  status=$?
  set -e

  [[ "$status" -eq 42 ]] || fail_test "partial Stow status was $status, expected 42; output: $output"
  [[ "$output" != *"unbound variable"* ]] || fail_test "rollback emitted an unbound-variable error"
  assert_file_content original-zshrc "$home/.zshrc"
  [[ ! -e "$home/.zprofile" && ! -L "$home/.zprofile" ]] ||
    fail_test "newly created managed link was not removed"
  [[ "$(realpath "$home/.zshenv")" == "$DOTFILES_DIR/zsh/.zshenv" ]] ||
    fail_test "pre-existing managed link was changed"
  assert_file_content unrelated "$home/keep-me"
  assert_file_content retired-cache "$cache_file"
  printf 'ok - partial Stow failure rolls back exactly and preserves status\n'
}

test_invalid_backup_id() {
  local case_root="$temporary_root/traversal" home="$temporary_root/traversal/home"
  local bin_dir="$temporary_root/traversal/bin" output status
  mkdir -p "$home" "$case_root"
  make_fake_stow "$bin_dir"
  printf '%s\n' original-zshrc >"$home/.zshrc"

  set +e
  output="$(HOME="$home" PATH="$bin_dir:$PATH" DOTFILES_DIR="$DOTFILES_DIR" \
    DOTFILES_BACKUP_TIMESTAMP='../escape' "$DOTFILES_DIR/bootstrap" link 2>&1)"
  status=$?
  set -e

  [[ "$status" -ne 0 ]] || fail_test "traversal backup ID was accepted"
  assert_file_content original-zshrc "$home/.zshrc"
  [[ ! -e "$case_root/escape" && ! -L "$case_root/escape" ]] ||
    fail_test "traversal backup path was created"
  [[ "$output" == *"backup"* ]] || fail_test "invalid backup ID error was unclear: $output"
  printf 'ok - traversal backup ID is rejected without data loss\n'
}

test_backup_collision() {
  local home="$temporary_root/collision/home" bin_dir="$temporary_root/collision/bin"
  local output status
  mkdir -p "$home/.dotfiles-backup/collision-id"
  make_fake_stow "$bin_dir"
  printf '%s\n' original-zshrc >"$home/.zshrc"
  printf '%s\n' sentinel >"$home/.dotfiles-backup/collision-id/sentinel"

  set +e
  output="$(HOME="$home" PATH="$bin_dir:$PATH" DOTFILES_DIR="$DOTFILES_DIR" \
    DOTFILES_BACKUP_TIMESTAMP=collision-id "$DOTFILES_DIR/bootstrap" link 2>&1)"
  status=$?
  set -e

  [[ "$status" -ne 0 ]] || fail_test "existing backup root was reused"
  assert_file_content original-zshrc "$home/.zshrc"
  assert_file_content sentinel "$home/.dotfiles-backup/collision-id/sentinel"
  [[ "$output" == *"already exists"* ]] || fail_test "collision error was unclear: $output"
  printf 'ok - backup collision fails before moving data\n'
}

test_symlink_backup_parent() {
  local home="$temporary_root/symlink-parent/home"
  local bin_dir="$temporary_root/symlink-parent/bin" outside="$temporary_root/symlink-parent/outside"
  local output status
  mkdir -p "$home" "$outside"
  make_fake_stow "$bin_dir"
  printf '%s\n' original-zshrc >"$home/.zshrc"
  printf '%s\n' outside-sentinel >"$outside/sentinel"
  ln -s "$outside" "$home/.dotfiles-backup"

  set +e
  output="$(HOME="$home" PATH="$bin_dir:$PATH" DOTFILES_DIR="$DOTFILES_DIR" \
    DOTFILES_BACKUP_TIMESTAMP=symlink-parent "$DOTFILES_DIR/bootstrap" link 2>&1)"
  status=$?
  set -e

  [[ "$status" -ne 0 ]] || fail_test "symlink backup parent was accepted"
  assert_file_content original-zshrc "$home/.zshrc"
  [[ -L "$home/.dotfiles-backup" && "$(readlink "$home/.dotfiles-backup")" == "$outside" ]] ||
    fail_test "symlink backup parent was changed"
  assert_file_content outside-sentinel "$outside/sentinel"
  [[ -z "$(find "$outside" -mindepth 1 ! -name sentinel -print -quit)" ]] ||
    fail_test "data was written outside through the symlink backup parent"
  [[ "$output" == *"backup"* ]] || fail_test "unsafe backup parent error was unclear: $output"
  printf 'ok - symlink backup parent is rejected before moving data\n'
}

test_partial_stow_rollback
test_invalid_backup_id
test_backup_collision
test_symlink_backup_parent
printf 'All bootstrap link tests passed.\n'
