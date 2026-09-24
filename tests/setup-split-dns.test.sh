#!/usr/bin/env bash
# Argument handling of setup-split-dns. Every case below exits before any
# privileged action, so this is safe to run anywhere, including CI.
set -euo pipefail
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
script="$DOTFILES_DIR/scripts/setup-split-dns"

expect_failure() {
  local label="$1" pattern="$2"; shift 2
  local output status=0
  output="$("$script" "$@" 2>&1)" || status=$?
  [[ "$status" -ne 0 ]] || { echo "not ok - $label was accepted" >&2; exit 1; }
  grep -Eq "$pattern" <<<"$output" || { echo "not ok - $label: unexpected message: $output" >&2; exit 1; }
  printf 'ok - %s rejected\n' "$label"
}

# Capture first: grep -q closing the pipe early would surface as SIGPIPE under pipefail.
help_output="$("$script" --help)"
grep -q '^Usage: .* --profile NAME DOMAIN NAMESERVER' <<<"$help_output" || { echo 'not ok - --help' >&2; exit 1; }
printf 'ok - --help prints usage\n'
if grep -Eq '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b|nameserver [0-9]|\.(xx|local|lan|internal)\b' "$script"; then
  echo 'not ok - setup-split-dns hardcodes an address' >&2; exit 1
fi
printf 'ok - no hardcoded domain or nameserver\n'

expect_failure 'missing arguments' '^Usage:'
expect_failure 'missing nameserver' '^Usage:' --profile vpn corp.example
expect_failure 'unknown option' '^Usage:' --bogus corp.example 192.0.2.53

if [[ "$(uname -s)" == Darwin ]]; then
  expect_failure 'missing --profile' 'Tunnelblick profile name' corp.example 192.0.2.53
  expect_failure 'profile with a path' 'Tunnelblick profile name' --profile ../x corp.example 192.0.2.53
  expect_failure 'single-label domain' 'domain with at least two labels' --profile vpn corp 192.0.2.53
  expect_failure 'uppercase domain' 'domain with at least two labels' --profile vpn Corp.Example 192.0.2.53
  expect_failure 'out-of-range IPv4 nameserver' 'Invalid IPv4 nameserver' --profile vpn corp.example 192.0.2.999
  expect_failure 'non-address nameserver' 'IPv4 or IPv6 nameserver' --profile vpn corp.example ns1.corp.example
  # Valid arguments stop at the VPN state or the missing Tunnelblick profile, before any privileged step.
  expect_failure 'nonexistent Tunnelblick profile' 'quit Tunnelblick before setup|Install the Tunnelblick profile' \
    --profile "dotfiles-test-$$" corp.example 192.0.2.53 2001:db8::53
else
  expect_failure 'non-macOS host' 'Requires macOS' --profile vpn corp.example 192.0.2.53
fi
