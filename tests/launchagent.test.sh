#!/usr/bin/env bash
set -euo pipefail
export DOTFILES_PLATFORM=macos

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-launchagent-test.XXXXXX")"
trap 'rm -rf "$root"' EXIT

fail_test() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

bin="$root/bin"
mkdir -p "$bin"
for command_name in bun codexbar; do
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$bin/$command_name"
  chmod +x "$bin/$command_name"
done

cat >"$bin/launchctl" <<'LAUNCHCTL'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$LAUNCHCTL_LOG"
case "${1:-}" in
  print)
    case "$LAUNCHCTL_MODE" in
      current|explicit|changed|same-path-no-state|fail-kickstart) printf 'path = %s\n' "$CURRENT_AGENT" ;;
      stale|fail-replacement) printf 'path = %s\n' "$OLD_AGENT" ;;
      unloaded) exit 3 ;;
    esac
    ;;
  bootout) ;;
  bootstrap)
    if [[ "$LAUNCHCTL_MODE" == fail-replacement && "${3:-}" == "$CURRENT_AGENT" ]]; then
      exit 23
    fi
    ;;
  kickstart)
    if [[ "$LAUNCHCTL_MODE" == fail-kickstart ]]; then
      kickstart_count=0
      [[ ! -f "$KICKSTART_COUNT_FILE" ]] || kickstart_count="$(<"$KICKSTART_COUNT_FILE")"
      printf '%s\n' "$((kickstart_count + 1))" >"$KICKSTART_COUNT_FILE"
      [[ "$kickstart_count" -gt 0 ]] || exit 29
    fi
    ;;
  *) exit 8 ;;
esac
LAUNCHCTL
chmod +x "$bin/launchctl"

run_case() {
  local case_name="$1" mode="$2" reload="${3:-}" home log output current old state_dir
  home="$root/$case_name/home"
  log="$root/$case_name/launchctl.log"
  output="$root/$case_name/output.log"
  current="$home/Library/LaunchAgents/dev.andrebiel.ai-usage.plist"
  old="$root/$case_name/old-agent.plist"
  state_dir="$home/Library/Caches/ai-usage"
  mkdir -p "$(dirname "$current")" "$state_dir"
  printf '%s\n' '<plist><dict><key>Label</key><string>dev.andrebiel.ai-usage</string></dict></plist>' >"$current"
  printf '%s\n' '<plist><dict><key>Label</key><string>dev.andrebiel.ai-usage</string><key>Old</key><true/></dict></plist>' >"$old"
  case "$mode" in
    current|explicit)
      cksum <"$current" >"$state_dir/launchagent.cksum"
      cp "$current" "$state_dir/launchagent.plist"
      ;;
    changed|fail-replacement|fail-kickstart)
      cksum <"$old" >"$state_dir/launchagent.cksum"
      cp "$old" "$state_dir/launchagent.plist"
      ;;
  esac
  : >"$log"
  set +e
  PATH="$bin:$PATH" HOME="$home" LAUNCHCTL_LOG="$log" LAUNCHCTL_MODE="$mode" \
    KICKSTART_COUNT_FILE="$root/$case_name/kickstart.count" \
    CURRENT_AGENT="$current" OLD_AGENT="$old" "$DOTFILES_DIR/bootstrap" usage $reload >"$output" 2>&1
  CASE_STATUS=$?
  set -e
  CASE_LOG="$log"
  CASE_OUTPUT="$output"
  CASE_CURRENT="$current"
  CASE_OLD="$old"
  CASE_STATE_DIR="$state_dir"
}

run_case current current
[[ "$CASE_STATUS" -eq 0 ]] || fail_test "current agent check failed"
[[ "$(grep -Ec '^(bootout|bootstrap|kickstart) ' "$CASE_LOG" || true)" -eq 0 ]] ||
  fail_test "detectably current agent was restarted"
printf 'ok - detectably current agent is left running\n'

run_case first unloaded
[[ "$CASE_STATUS" -eq 0 ]] || fail_test "first load failed"
grep -Fqx "bootstrap gui/$(id -u) $CASE_CURRENT" "$CASE_LOG" || fail_test "first load did not bootstrap"
grep -Fqx "kickstart -k gui/$(id -u)/dev.andrebiel.ai-usage" "$CASE_LOG" || fail_test "first load did not kickstart"
[[ -f "$CASE_STATE_DIR/launchagent.cksum" && -f "$CASE_STATE_DIR/launchagent.plist" ]] ||
  fail_test "first load did not record restorable state"
printf 'ok - first load starts the agent and records state\n'

run_case explicit explicit --reload
[[ "$CASE_STATUS" -eq 0 ]] || fail_test "explicit reload failed"
grep -Fqx "bootout gui/$(id -u)/dev.andrebiel.ai-usage" "$CASE_LOG" || fail_test "explicit reload did not boot out"
grep -Fqx "bootstrap gui/$(id -u) $CASE_CURRENT" "$CASE_LOG" || fail_test "explicit reload did not bootstrap"
printf 'ok - explicit reload replaces a current agent\n'

run_case changed changed
[[ "$CASE_STATUS" -eq 0 ]] || fail_test "changed agent reload failed"
grep -Fqx "bootout gui/$(id -u)/dev.andrebiel.ai-usage" "$CASE_LOG" || fail_test "changed agent was not booted out"
grep -Fqx "bootstrap gui/$(id -u) $CASE_CURRENT" "$CASE_LOG" || fail_test "changed agent was not bootstrapped"
printf 'ok - changed configuration is reloaded\n'

run_case no-snapshot same-path-no-state
[[ "$CASE_STATUS" -ne 0 ]] || fail_test "same-path agent without trusted state was reloaded"
[[ "$(grep -Ec '^(bootout|bootstrap|kickstart) ' "$CASE_LOG" || true)" -eq 0 ]] ||
  fail_test "same-path agent without trusted state was mutated"
grep -Fq 'no trusted prior configuration snapshot' "$CASE_OUTPUT" ||
  fail_test "same-path no-state failure did not explain the missing trusted snapshot"
[[ ! -e "$CASE_STATE_DIR/launchagent.cksum" && ! -e "$CASE_STATE_DIR/launchagent.plist" ]] ||
  fail_test "same-path no-state failure copied the current plist into trusted state"
printf 'ok - same-path agent without trusted state is left untouched\n'

run_case stale stale
[[ "$CASE_STATUS" -eq 0 ]] || fail_test "stale-path agent reload failed"
grep -Fqx "bootout gui/$(id -u)/dev.andrebiel.ai-usage" "$CASE_LOG" || fail_test "stale-path agent was not booted out"
grep -Fqx "bootstrap gui/$(id -u) $CASE_CURRENT" "$CASE_LOG" || fail_test "stale-path agent replacement was not bootstrapped"
printf 'ok - agent loaded from a stale path is replaced\n'

run_case failure fail-replacement
[[ "$CASE_STATUS" -eq 23 ]] || fail_test "replacement failure status was $CASE_STATUS instead of 23"
[[ "$(grep -c '^bootstrap ' "$CASE_LOG" || true)" -eq 2 ]] || fail_test "prior agent restore was not attempted"
last_bootstrap="$(grep '^bootstrap ' "$CASE_LOG" | command tail -n 1)"
[[ "$last_bootstrap" != *" $CASE_CURRENT" ]] || fail_test "restore retried only the failed replacement"
printf 'ok - failed replacement attempts prior-agent restore and preserves status\n'

run_case kickstart-failure fail-kickstart
[[ "$CASE_STATUS" -eq 29 ]] || fail_test "kickstart failure status was $CASE_STATUS instead of 29"
recovery_calls=()
while IFS= read -r recovery_call; do
  recovery_calls[${#recovery_calls[@]}]="$recovery_call"
done < <(grep -E '^(bootout|bootstrap|kickstart) ' "$CASE_LOG")
[[ "${#recovery_calls[@]}" -eq 6 ]] || fail_test "kickstart recovery made ${#recovery_calls[@]} calls instead of 6"
[[ "${recovery_calls[0]}" == "bootout gui/$(id -u)/dev.andrebiel.ai-usage" ]] || fail_test "kickstart recovery call 1 was not initial bootout"
[[ "${recovery_calls[1]}" == "bootstrap gui/$(id -u) $CASE_CURRENT" ]] || fail_test "kickstart recovery call 2 was not replacement bootstrap"
[[ "${recovery_calls[2]}" == "kickstart -k gui/$(id -u)/dev.andrebiel.ai-usage" ]] || fail_test "kickstart recovery call 3 was not replacement kickstart"
[[ "${recovery_calls[3]}" == "bootout gui/$(id -u)/dev.andrebiel.ai-usage" ]] || fail_test "kickstart recovery call 4 did not remove replacement"
[[ "${recovery_calls[4]}" == bootstrap\ gui/"$(id -u)"\ * && "${recovery_calls[4]}" != *" $CASE_CURRENT" ]] ||
  fail_test "kickstart recovery call 5 did not bootstrap the saved prior plist"
[[ "${recovery_calls[5]}" == "kickstart -k gui/$(id -u)/dev.andrebiel.ai-usage" ]] || fail_test "kickstart recovery call 6 did not restart prior agent"
printf 'ok - kickstart failure removes replacement, restores prior agent, and preserves status\n'
printf 'All LaunchAgent tests passed.\n'
