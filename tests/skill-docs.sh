#!/usr/bin/env bash
# Checks that SKILL.md's help block, argument-hint and references agree. Usage: tests/skill-docs.sh
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/skills/grasp/SKILL.md"
# shellcheck source=tests/lib.sh
source "$ROOT/tests/lib.sh"

# the fenced help block under "## Help"
help_block() { awk '/^## Help/ { h = 1 } h && /^```/ { n++; next } h && n == 1 { print } n == 2 { exit }' "$SKILL"; }
arg_hint() { sed -n 's/^argument-hint: "\(.*\)"$/\1/p' "$SKILL"; }
flags_of() { grep -o -- '--[a-z][a-z-]*' | grep -vx -- '--help' | sort -u; }
# first word of each |-separated segment that is a lowercase subcommand
subs_of_hint() { arg_hint | awk -F' [|] ' '{ for (i = 1; i <= NF; i++) { split($i, w, " "); print w[1] } }' | grep -E '^[a-z]+$' | sort -u; }

test_help_lists_subcommands() {
  local h s
  h=$(help_block)
  for s in setup update page --step; do assert_contains "$h" "$s" "help block mentions $s"; done
}

test_argument_hint_matches_help() {
  local h hint f s
  h=$(help_block); hint=$(arg_hint)
  [[ -n "$hint" ]] || _fail "argument-hint found"
  for f in $(printf '%s' "$hint" | flags_of); do assert_contains "$h" "$f" "help documents hint flag $f"; done
  for f in $(printf '%s' "$h" | flags_of); do assert_contains "$hint" "$f" "argument-hint lists help flag $f"; done
  for s in $(subs_of_hint); do assert_contains "$h" "/grasp $s" "help has usage line for $s"; done
  for s in $(printf '%s\n' "$h" | sed -n 's|^  /grasp \([a-z][a-z]*\).*|\1|p' | sort -u); do
    assert_contains "$hint" "$s" "argument-hint lists subcommand $s"
  done
}

test_references_exist() {
  local p n=0
  while read -r p; do
    n=$((n + 1))
    [[ -f "$ROOT/skills/grasp/$p" ]] || _fail "linked file exists: $p"
  done < <(grep -oE '(references|templates)/[a-z-]+\.md' "$SKILL" | sort -u)
  [[ $n -gt 0 ]] || _fail "SKILL.md links some references"
}

test_setup_reference_linked() {
  assert_contains "$(cat "$SKILL")" "references/setup.md" "SKILL.md links setup.md"
}

test_trackers_cover_clickup() {
  local t
  t=$(cat "$ROOT/skills/grasp/references/trackers.md")
  assert_contains "$t" "ClickUp" "ClickUp named"
  assert_contains "$t" "app.clickup.com/t/" "ClickUp URL form"
  assert_contains "$t" "Azure DevOps" "Azure DevOps named"
  assert_contains "$t" "DEV-42" "custom-id ambiguity covered"
}

test_config_template_sections() {
  local c s
  c=$(cat "$ROOT/skills/grasp/templates/grasp-config.md")
  for s in "## Connected skills" "## App" "## Learning" "tested:"; do assert_contains "$c" "$s" "config template has $s"; done
}

test_review_converts_old_pages() {
  local r
  r=$(cat "$ROOT/skills/grasp/references/review.md")
  assert_contains "$r" "lint-page" "review.md runs lint-page"
}

run_tests "${1:-.}"
