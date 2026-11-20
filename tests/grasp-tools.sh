#!/usr/bin/env bash
# Tests for skills/grasp/bin/grasp-tools. Usage: tests/grasp-tools.sh [--live] [FILTER_REGEX]
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TOOLS="$ROOT/skills/grasp/bin/grasp-tools"
FIX="$ROOT/tests/fixtures"
LIVE=0
if [[ "${1:-}" == "--live" ]]; then LIVE=1; shift; fi
# shellcheck source=tests/lib.sh
source "$ROOT/tests/lib.sh"

gt() { "$TOOLS" "$@"; }

# ---- version and dispatch ----

test_version_prints_0_2_0() {
  assert_eq "0.2.0" "$(gt version)" "version prints 0.2.0"
}

test_version_matches_plugin_json() {
  local pj
  pj=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$ROOT/.claude-plugin/plugin.json")
  assert_eq "$pj" "$(gt version)" "VERSION matches plugin.json"
}

test_unknown_command_exits_2() {
  assert_exit 2 "unknown command exits 2" -- "$TOOLS" no-such-command
}

test_help_lists_all_commands() {
  local out c
  out=$(gt -h 2>&1)
  for c in connect disconnect status refresh check-link lint-page version; do
    assert_contains "$out" "$c" "help lists $c"
  done
}

run_tests "${1:-.}"
