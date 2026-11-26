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
  for s in setup update page record map --step; do assert_contains "$h" "$s" "help block mentions $s"; done
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
  for s in "## Connected skills" "## App" "## Learning" "tested:" "## Projects" "- run records:" "- stop hook:"; do assert_contains "$c" "$s" "config template has $s"; done
}

test_review_converts_old_pages() {
  local r
  r=$(cat "$ROOT/skills/grasp/references/review.md")
  assert_contains "$r" "lint-page" "review.md runs lint-page"
}

test_description_is_a_quoted_yaml_string() {
  # an unquoted description holding ": " is invalid YAML: strict loaders (npx skills) skip the skill
  local d
  d=$(sed -n 's/^description: //p' "$SKILL")
  [[ "$d" == \"*\" ]] || _fail "description is wrapped in double quotes"
  d=${d#\"}; d=${d%\"}
  [[ "$d" != *\"* && "$d" != *\\* ]] || _fail "description holds no inner double quote or backslash"
}

test_description_within_1024_chars() {
  local d
  d=$(sed -n 's/^description: //p' "$SKILL")
  [[ ${#d} -le 1024 ]] || _fail "description is ${#d} characters; the Agent Skills limit is 1024"
}

test_update_checks_copy_install_first() {
  # a copy inside a project sits in the project's git repo, so .source must be checked before git
  local u src git
  u=$(awk '/^## `\/grasp update`/ { f = 1 } /^## Old/ { f = 0 } f' "$ROOT/skills/grasp/references/setup.md")
  src=$(printf '%s\n' "$u" | grep -n '\.source' | head -n 1 | cut -d: -f1)
  git=$(printf '%s\n' "$u" | grep -n 'pull --ff-only' | head -n 1 | cut -d: -f1)
  [[ -n "$src" && -n "$git" && $src -lt $git ]] || _fail "update checks .source before any git pull (src=$src git=$git)"
  assert_contains "$u" "symlink" "link install is identified by a symlink"
}

test_setup_records_runs_and_writes_overview() {
  local u s
  u=$(cat "$ROOT/skills/grasp/references/setup.md")
  for s in "### 0. Scope" "grasp-tools projects" "### 6. Run records" "grasp-tools connect AGENTS.md record" \
           "@AGENTS.md" "### 8. Overview" "workspace map" '/grasp record "grasp set up"'; do
    assert_contains "$u" "$s" "setup.md covers: $s"
  done
}

test_settings_come_only_from_grasp_md() {
  # grasp's block in AGENTS.md is an instruction, never a stand-in for .grasp.md (it would skip setup)
  local body
  body=$(cat "$SKILL")
  [[ "$body" != *'section in `CLAUDE.md`'* ]] || _fail "SKILL.md no longer treats a section in CLAUDE.md/AGENTS.md as settings"
  assert_contains "$body" 'never stands in for' "SKILL.md says the block is not the settings"
}

test_links_inside_the_skill_resolve() {
  # a copy or plugin install ships only skills/grasp, so every relative link must stay inside it
  local f dir link n=0
  while IFS=$'\t' read -r f link; do
    n=$((n + 1))
    dir=$(dirname "$f")
    [[ -f "$dir/$link" ]] || _fail "$(basename "$f") links a missing file: $link"
    case "$(cd "$dir/$(dirname "$link")" 2>/dev/null && pwd)" in
      "$ROOT/skills/grasp"*) ;;
      *) _fail "$(basename "$f") links outside the skill folder: $link" ;;
    esac
  done < <(grep -oE '\]\((\.\./)*(references|templates)/[a-z-]+\.md\)|\]\([a-z-]+\.md\)' -H \
             "$ROOT"/skills/grasp/SKILL.md "$ROOT"/skills/grasp/references/*.md "$ROOT"/skills/grasp/templates/*.md |
           grep -v '{' | sed -E 's/:\]\(/\t/; s/\)$//')
  [[ $n -gt 20 ]] || _fail "found links to check (got $n)"
  if grep -n '\](\.\./\.\./' "$ROOT"/skills/grasp/references/*.md "$ROOT"/skills/grasp/templates/*.md >/dev/null; then
    _fail "no link climbs out of skills/grasp"
  fi
}

test_overview_teaches_architecture_and_system_design() {
  local tpl o n s
  tpl=$(cat "$ROOT/skills/grasp/templates/architecture.md" 2>/dev/null)
  o=$(cat "$ROOT/skills/grasp/references/overview.md"); n=$(cat "$ROOT/skills/grasp/references/notebook.md")
  for s in ": architecture" "## The shape" "## Why it is built this way" "## When something fails" "## How it grows" \
           "## Design system" "## Concepts" "## Lessons" "assets/architecture.png" '```mermaid' "YouTube" "LinkedIn Learning"; do
    assert_contains "$tpl" "$s" "architecture template has: $s"
  done
  assert_contains "$o" "templates/architecture.md" "overview.md links the template"
  assert_contains "$n" "architecture.md" "notebook.md lists the page"
  assert_contains "$(cat "$ROOT/skills/grasp/references/setup.md")" "architecture page" "setup writes it"
  assert_contains "$(help_block)" "architecture" "help names it"
}

test_run_record_fields_agree_everywhere() {
  local f blk p rec tpl
  p=$(new_tmp); "$ROOT/skills/grasp/bin/grasp-tools" --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  blk=$(cat "$p/AGENTS.md")
  rec=$(cat "$ROOT/skills/grasp/references/records.md"); tpl=$(cat "$ROOT/skills/grasp/templates/run-record.md")
  for f in Asked Changed Checked Problems Next; do
    assert_contains "$rec" "**$f**" "records.md explains $f"
    assert_contains "$tpl" "- **$f:**" "template has the $f line"
    assert_contains "$blk" "- **$f:**" "the AGENTS.md block has the $f line"
  done
  for f in done partial blocked failed; do assert_contains "$rec" "\`$f\`" "records.md defines status $f"; done
}

test_writer_rules_are_stated_once() {
  local sd="$ROOT/skills/grasp" nb="$ROOT/skills/grasp/references/notebook.md" h s
  for h in "## Standard 2" "## What the writer reads" "## A snapshot and a living page" "## Short pages"; do
    grep -qxF "$h" "$nb" || _fail "notebook.md lacks: $h"
  done
  for s in "grasp-tools snippet" "snippet-check" "grasp-tools coverage" "not run here" "reads the repository"; do
    grep -qF "$s" "$nb" || _fail "notebook.md does not mention: $s"
  done
  ! grep -rqF "not asked (no person in the run)" "$sd" || _fail "the explain-back fallback is still written somewhere"
  ! grep -qF "## Explain it back" "$sd/templates/issue-page.md" || _fail "the template still has Explain it back"
  grep -qF "Walk ready: /grasp walk" "$SKILL" || _fail "step 6 does not end with the walk line"
}

test_reader_and_features_settings() {
  local cfg="$ROOT/skills/grasp/templates/grasp-config.md" nb="$ROOT/skills/grasp/references/notebook.md" s
  for s in "## Reader" "- knows well:" "- new to:" "| gap | found on | date |" "## Features" "| feature | page | covers |" "- sync scope:" "- other records:"; do
    grep -qF -- "$s" "$cfg" || _fail "config template lacks: $s"
  done
  for s in "title match only" "content checked" "fail redirected" "refactoring.guru" "aws.amazon.com/builders-library" "checked YYYY-MM-DD" \
           "design idea" "one specific video" "No checked video yet" "Never the course address" "system design"; do
    grep -qF "$s" "$nb" || _fail "notebook.md lacks: $s"
  done
  grep -qF "## Reader" "$ROOT/skills/grasp/references/setup.md" || _fail "setup.md does not ask for the reader profile"
}

test_setup_looks_for_a_second_writer() {
  grep -qF "page-writing rules of its own" "$ROOT/skills/grasp/references/setup.md" || _fail "setup does not look for a second writer"
}

test_explain_is_a_full_copy() {
  local e="$ROOT/skills/grasp/references/explain.md" s
  [[ -f "$e" ]] || _fail "references/explain.md missing"
  for s in "this session" "BASE..HEAD" "--repo" "--docs" "--name" "--lessons" "--no-image" "check PAGE" \
           "reconstructed" "what git does not see" "Set it up" "When something goes wrong" \
           "How we built it, step by step" "## Things people look up" "## Not in git" "docs router" \
           "change-map" "grasp-tools coverage" "never write a second set" "uncommitted" "Not pinned yet"; do
    grep -qF -- "$s" "$e" || _fail "explain.md lacks: $s"
  done
  grep -qF "/grasp explain check" "$SKILL" || _fail "no usage line for explain check"
  ! grep -rqiF "explain-build" "$ROOT/skills/grasp" || _fail "grasp must not depend on or mention the explain-build skill"
}

test_walk_is_documented() {
  local w="$ROOT/skills/grasp/references/walk.md" s
  [[ -f "$w" ]] || _fail "references/walk.md missing"
  for s in "one at a time" "grasp:walk:start" "## Reader" "never block" "Changed since by"; do
    grep -qiF "$s" "$w" || _fail "walk.md lacks: $s"
  done
  grep -qF "/grasp walk" "$SKILL" || _fail "no usage line for walk"
}

run_tests "${1:-.}"
