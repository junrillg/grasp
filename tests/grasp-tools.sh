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

# ---- connect / disconnect / status / refresh ----

# expected_block STEP [EOL] -> the exact block grasp writes
expected_block() {
  local step=$1 eol=${2:-$'\n'}
  printf '%s%s' \
    "<!-- grasp:start b=1 v=0.2.0 step=$step -->" "$eol" \
    "## Learning page (grasp)" "$eol" \
    "When this skill has finished its own work, run grasp's \`page\` subcommand for the same issue or" "$eol" \
    "pull request with \`--step $step\` (\`/grasp page <issue or PR> --step $step\`, or \`/grasp:grasp page ...\`" "$eol" \
    "when grasp is installed as a plugin), so the issue's learning page shows what was done." "$eol" \
    "Skip this if grasp is not installed." "$eol" \
    "<!-- grasp:end -->" "$eol"
}

# new_project: tmp dir with .claude/skills/<fixtures> and an old .grasp.md; prints its path
new_project() {
  local p
  p=$(new_tmp)
  mkdir -p "$p/.claude/skills"
  cp -R "$FIX/skills/." "$p/.claude/skills/"
  cp "$FIX/grasp-md/old.md" "$p/.grasp.md"
  printf '%s' "$p"
}

test_connect_appends_block_and_row() {
  local p out want
  p=$(new_project)
  out=$(gt --config "$p/.grasp.md" connect .claude/skills/plain work)
  assert_eq "connected .claude/skills/plain work" "$out" "connect prints confirmation"
  want=$(mktemp)
  { cat "$FIX/skills/plain/SKILL.md"; printf '\n'; expected_block work; } > "$want"
  assert_file_eq "$want" "$p/.claude/skills/plain/SKILL.md" "block appended after one blank line"
  assert_contains "$(cat "$p/.grasp.md")" "| .claude/skills/plain | work | 0.2.0 |" "row recorded"
}

test_connect_twice_is_idempotent() {
  local p a b
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  a=$(mktemp); b=$(mktemp)
  cp "$p/.claude/skills/plain/SKILL.md" "$a"; cp "$p/.grasp.md" "$b"
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  assert_file_eq "$a" "$p/.claude/skills/plain/SKILL.md" "skill file unchanged on second connect"
  assert_file_eq "$b" "$p/.grasp.md" ".grasp.md unchanged on second connect"
  assert_eq 1 "$(grep -c 'grasp:start' "$p/.claude/skills/plain/SKILL.md")" "exactly one block"
}

test_connect_replaces_block_when_step_changes() {
  local p
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  gt --config "$p/.grasp.md" connect .claude/skills/plain verify >/dev/null
  assert_eq 1 "$(grep -c 'grasp:start' "$p/.claude/skills/plain/SKILL.md")" "still one block"
  assert_eq 1 "$(grep -c 'grasp:start b=1 v=0.2.0 step=verify' "$p/.claude/skills/plain/SKILL.md")" "block now verify"
  assert_eq 1 "$(grep -c '^| .claude/skills/plain |' "$p/.grasp.md")" "still one row"
  assert_contains "$(cat "$p/.grasp.md")" "| .claude/skills/plain | verify | 0.2.0 |" "row updated"
}

test_connect_preserves_crlf_and_text_above() {
  local p want
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/crlf verify >/dev/null
  want=$(mktemp)
  { cat "$FIX/skills/crlf/SKILL.md"; printf '\r\n'; expected_block verify $'\r\n'; } > "$want"
  assert_file_eq "$want" "$p/.claude/skills/crlf/SKILL.md" "CRLF kept, block written with CRLF"
}

test_connect_no_trailing_newline() {
  local p want
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/no-newline review >/dev/null
  want=$(mktemp)
  { cat "$FIX/skills/no-newline/SKILL.md"; printf '\n\n'; expected_block review; } > "$want"
  assert_file_eq "$want" "$p/.claude/skills/no-newline/SKILL.md" "newline added, then blank line and block"
}

test_connect_path_with_spaces() {
  local p
  p=$(new_project)
  assert_exit 0 "connect a path with spaces" -- "$TOOLS" --config "$p/.grasp.md" connect ".claude/skills/my skill" resolve
  assert_eq 1 "$(grep -c 'step=resolve' "$p/.claude/skills/my skill/SKILL.md")" "block written"
  assert_contains "$(gt --config "$p/.grasp.md" status)" $'.claude/skills/my skill\tresolve\tok' "status handles spaces"
  gt --config "$p/.grasp.md" disconnect ".claude/skills/my skill" >/dev/null
  assert_file_eq "$FIX/skills/my skill/SKILL.md" "$p/.claude/skills/my skill/SKILL.md" "disconnect handles spaces"
}

test_connect_bad_step_exits_2() {
  local p
  p=$(new_project)
  assert_exit 2 "bad step exits 2" -- "$TOOLS" --config "$p/.grasp.md" connect .claude/skills/plain deploy
  assert_file_eq "$FIX/skills/plain/SKILL.md" "$p/.claude/skills/plain/SKILL.md" "file untouched on bad step"
}

test_connect_missing_skill_exits_1() {
  local p
  p=$(new_project)
  assert_exit 1 "missing SKILL.md exits 1" -- "$TOOLS" --config "$p/.grasp.md" connect .claude/skills/nope work
}

test_connect_creates_section_in_old_grasp_md() {
  local p want
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  want=$(mktemp)
  { cat "$FIX/grasp-md/old.md"
    printf '\n## Connected skills\n\n| skill | step | grasp version |\n| ----- | ---- | ------------- |\n| .claude/skills/plain | work | 0.2.0 |\n'
  } > "$want"
  assert_file_eq "$want" "$p/.grasp.md" "section created at end of old .grasp.md"
  gt --config "$p/.grasp.md" connect .claude/skills/crlf verify >/dev/null
  assert_eq ".claude/skills/crlf" "$(tail -n 1 "$p/.grasp.md" | awk -F' [|] ' '{print $1}' | sed 's/^| //')" "second row appended last"
}

test_disconnect_restores_original() {
  local p
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  gt --config "$p/.grasp.md" connect .claude/skills/crlf verify >/dev/null
  assert_eq "disconnected .claude/skills/plain" "$(gt --config "$p/.grasp.md" disconnect .claude/skills/plain)" "disconnect prints confirmation"
  gt --config "$p/.grasp.md" disconnect .claude/skills/crlf >/dev/null
  assert_file_eq "$FIX/skills/plain/SKILL.md" "$p/.claude/skills/plain/SKILL.md" "plain restored"
  assert_file_eq "$FIX/skills/crlf/SKILL.md" "$p/.claude/skills/crlf/SKILL.md" "crlf restored"
  assert_eq 0 "$(grep -c '^| .claude/skills/' "$p/.grasp.md")" "rows removed"
}

test_status_reports_ok_stale_missing_noblock() {
  local p out rc=0
  p=$(new_project)
  for s in plain crlf no-newline; do gt --config "$p/.grasp.md" connect ".claude/skills/$s" work >/dev/null; done
  gt --config "$p/.grasp.md" connect ".claude/skills/my skill" resolve >/dev/null
  sed -i.bak 's/grasp:start b=1/grasp:start b=0/' "$p/.claude/skills/crlf/SKILL.md"
  rm -rf "$p/.claude/skills/no-newline"
  cp "$FIX/skills/my skill/SKILL.md" "$p/.claude/skills/my skill/SKILL.md"
  out=$(gt --config "$p/.grasp.md" status) || rc=$?
  assert_eq 1 "$rc" "status exits 1 when any skill is not ok"
  assert_eq "$(printf '.claude/skills/plain\twork\tok\n.claude/skills/crlf\twork\tstale\n.claude/skills/no-newline\twork\tmissing\n.claude/skills/my skill\tresolve\tno-block')" "$out" "status lines"
}

test_status_all_ok_exits_0() {
  local p
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  assert_exit 0 "status exits 0 when all ok" -- "$TOOLS" --config "$p/.grasp.md" status
}

test_refresh_rewrites_only_stale() {
  local p ok_before want
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  gt --config "$p/.grasp.md" connect .claude/skills/crlf verify >/dev/null
  gt --config "$p/.grasp.md" connect ".claude/skills/my skill" resolve >/dev/null
  ok_before=$(mktemp); cp "$p/.claude/skills/plain/SKILL.md" "$ok_before"
  touch -t 202001010000 "$p/.claude/skills/plain/SKILL.md"
  sed -i.bak 's/grasp:start b=1/grasp:start b=0/' "$p/.claude/skills/crlf/SKILL.md"
  cp "$FIX/skills/my skill/SKILL.md" "$p/.claude/skills/my skill/SKILL.md"
  gt --config "$p/.grasp.md" refresh >/dev/null
  assert_file_eq "$ok_before" "$p/.claude/skills/plain/SKILL.md" "ok block untouched"
  assert_eq "202001010000" "$(date -r "$p/.claude/skills/plain/SKILL.md" +%Y%m%d%H%M)" "ok file not rewritten"
  want=$(mktemp)
  { cat "$FIX/skills/crlf/SKILL.md"; printf '\r\n'; expected_block verify $'\r\n'; } > "$want"
  assert_file_eq "$want" "$p/.claude/skills/crlf/SKILL.md" "stale block rewritten in place"
  assert_exit 0 "all ok after refresh" -- "$TOOLS" --config "$p/.grasp.md" status
}

test_refresh_one_skill() {
  local p
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  gt --config "$p/.grasp.md" connect .claude/skills/crlf verify >/dev/null
  sed -i.bak 's/grasp:start b=1/grasp:start b=0/' "$p/.claude/skills/plain/SKILL.md" "$p/.claude/skills/crlf/SKILL.md"
  gt --config "$p/.grasp.md" refresh .claude/skills/plain >/dev/null
  assert_eq 1 "$(grep -c 'b=1' "$p/.claude/skills/plain/SKILL.md")" "named skill refreshed"
  assert_eq 1 "$(grep -c 'b=0' "$p/.claude/skills/crlf/SKILL.md")" "other skill left alone"
}

run_tests "${1:-.}"
