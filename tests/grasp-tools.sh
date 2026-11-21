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
  assert_eq "0.3.0" "$(gt version)" "version prints 0.3.0"
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
  for c in connect disconnect block status refresh record-index record-check projects check-link lint-page version; do
    assert_contains "$out" "$c" "help lists $c"
  done
}

# ---- connect / disconnect / status / refresh ----

# expected_block STEP [EOL] -> the exact block grasp writes
expected_block() {
  local step=$1 eol=${2:-$'\n'}
  printf '%s%s' \
    "<!-- grasp:start b=1 v=0.3.0 step=$step -->" "$eol" \
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
  assert_contains "$(cat "$p/.grasp.md")" "| .claude/skills/plain | work | 0.3.0 |" "row recorded"
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
  assert_eq 1 "$(grep -c 'grasp:start b=1 v=0.3.0 step=verify' "$p/.claude/skills/plain/SKILL.md")" "block now verify"
  assert_eq 1 "$(grep -c '^| .claude/skills/plain |' "$p/.grasp.md")" "still one row"
  assert_contains "$(cat "$p/.grasp.md")" "| .claude/skills/plain | verify | 0.3.0 |" "row updated"
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
    printf '\n## Connected skills\n\n| skill | step | grasp version |\n| ----- | ---- | ------------- |\n| .claude/skills/plain | work | 0.3.0 |\n'
  } > "$want"
  assert_file_eq "$want" "$p/.grasp.md" "section created at end of old .grasp.md"
  gt --config "$p/.grasp.md" connect .claude/skills/crlf verify >/dev/null
  assert_eq ".claude/skills/crlf" "$(tail -n 1 "$p/.grasp.md" | awk -F' [|] ' '{print $1}' | sed 's/^| //')" "second row appended last"
}

test_connect_twice_into_new_grasp_md() {
  local p want
  p=$(new_project)
  rm "$p/.grasp.md"
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  gt --config "$p/.grasp.md" connect .claude/skills/crlf review >/dev/null
  want=$(mktemp)
  printf '## Connected skills\n\n| skill | step | grasp version |\n| ----- | ---- | ------------- |\n| .claude/skills/plain | work | 0.3.0 |\n| .claude/skills/crlf | review | 0.3.0 |\n' > "$want"
  assert_file_eq "$want" "$p/.grasp.md" ".grasp.md created with both rows under the header"
  assert_eq 2 "$(gt --config "$p/.grasp.md" status | grep -c $'\tok$')" "status lists both"
}

test_connect_into_empty_template_table() {
  local p
  p=$(new_project)
  sed -n '/^## Connected skills/,$p' "$ROOT/skills/grasp/templates/grasp-config.md" > "$p/.grasp.md"
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  gt --config "$p/.grasp.md" connect .claude/skills/crlf review >/dev/null
  assert_eq "$(printf '| .claude/skills/plain | work | 0.3.0 |\n| .claude/skills/crlf | review | 0.3.0 |')" "$(tail -n 2 "$p/.grasp.md")" "rows appended under the template's empty table"
  assert_exit 0 "status ok, no placeholder row" -- "$TOOLS" --config "$p/.grasp.md" status
}

test_connect_ignores_marker_in_code_fence() {
  local p want
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/quotes-marker work >/dev/null
  want=$(mktemp)
  { cat "$FIX/skills/quotes-marker/SKILL.md"; printf '\n'; expected_block work; } > "$want"
  assert_file_eq "$want" "$p/.claude/skills/quotes-marker/SKILL.md" "fenced example kept, block appended"
  gt --config "$p/.grasp.md" connect .claude/skills/quotes-marker verify >/dev/null
  assert_contains "$(cat "$p/.claude/skills/quotes-marker/SKILL.md")" "Step 2: keep this line." "replace keeps user text"
  gt --config "$p/.grasp.md" disconnect .claude/skills/quotes-marker >/dev/null
  assert_file_eq "$FIX/skills/quotes-marker/SKILL.md" "$p/.claude/skills/quotes-marker/SKILL.md" "disconnect restores original"
}

test_missing_end_marker_is_refused() {
  local p f before out rc=0
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  f="$p/.claude/skills/plain/SKILL.md"
  sed -i.bak '/grasp:end/d' "$f"; rm -f "$f.bak"
  printf '\n## My own section\nDo not delete me.\n' >> "$f"
  before=$(mktemp); cp "$f" "$before"
  out=$(gt --config "$p/.grasp.md" status) || rc=$?
  assert_eq 1 "$rc" "status exits 1"
  assert_eq $'.claude/skills/plain\twork\tbroken' "$out" "status reports broken"
  assert_exit 1 "disconnect refuses a block with no end marker" -- "$TOOLS" --config "$p/.grasp.md" disconnect .claude/skills/plain
  assert_exit 1 "connect refuses a block with no end marker" -- "$TOOLS" --config "$p/.grasp.md" connect .claude/skills/plain work
  assert_exit 1 "refresh reports the broken block" -- "$TOOLS" --config "$p/.grasp.md" refresh
  assert_file_eq "$before" "$f" "user text untouched"
}

test_connect_section_without_table() {
  local p want
  p=$(new_project)
  printf '# grasp settings\n\n## Connected skills\n\nNone yet.\n\n## Voice\n\n- plain\n' > "$p/.grasp.md"
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  want=$(mktemp)
  printf '# grasp settings\n\n## Connected skills\n\n| skill | step | grasp version |\n| ----- | ---- | ------------- |\n| .claude/skills/plain | work | 0.3.0 |\n\nNone yet.\n\n## Voice\n\n- plain\n' > "$want"
  assert_file_eq "$want" "$p/.grasp.md" "table added under the heading"
  printf '# grasp settings\n\n## Connected skills\n' > "$p/.grasp.md"
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  assert_eq $'.claude/skills/plain\twork\tok' "$(gt --config "$p/.grasp.md" status)" "heading alone at end of file gets a table"
}

test_paths_are_normalised() {
  local p
  p=$(new_project)
  gt --config "$p/.grasp.md" connect ./.claude/skills/plain work >/dev/null
  gt --config "$p/.grasp.md" connect "$p/.claude/skills/crlf/" verify >/dev/null
  assert_eq "$(printf '.claude/skills/plain\twork\tok\n.claude/skills/crlf\tverify\tok')" "$(gt --config "$p/.grasp.md" status)" "./ and absolute paths recorded relative"
  gt --config "$p/.grasp.md" disconnect .claude/skills/plain >/dev/null
  gt --config "$p/.grasp.md" disconnect "$p/.claude/skills/crlf" >/dev/null
  assert_eq "" "$(gt --config "$p/.grasp.md" status)" "both rows gone"
  assert_file_eq "$FIX/skills/plain/SKILL.md" "$p/.claude/skills/plain/SKILL.md" "block removed"
}

test_disconnect_unknown_skill_fails() {
  local p
  p=$(new_project)
  assert_exit 1 "disconnect of a skill that is not connected fails" -- "$TOOLS" --config "$p/.grasp.md" disconnect .claude/skills/plain
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

# ---- check-link ----

cl() { GRASP_CURL="$FIX/fake-curl" FAKE_CURL_CASE=$1 "$TOOLS" check-link "$2"; }

test_youtube_ok_prints_title_channel() {
  local log out
  log=$(mktemp)
  out=$(FAKE_CURL_LOG=$log cl yt-ok "https://www.youtube.com/watch?v=abcdefghijk")
  assert_eq $'ok\tOAuth 2.0 explained\tTech Channel' "$out" "title and channel printed"
  assert_contains "$(cat "$log")" "https://www.youtube.com/oembed?url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3Dabcdefghijk&format=json" "oEmbed URL encoded"
  assert_contains "$(cat "$log")" "grasp-link-check" "generic user agent"
  assert_contains "$(cat "$log")" "10" "max time passed"
}

test_youtube_title_with_escapes() {
  local out
  out=$(cl yt-escapes "https://youtu.be/abcdefghijk")
  assert_eq $'ok\tHe said "hi" \xc3\xa9 a/b \\ ok\tCaf\xc3\xa9 \xf0\x9f\x98\x80 TV' "$out" "escapes decoded to UTF-8"
}

test_youtube_400_fails() {
  local out rc=0
  out=$(cl yt-400 "https://www.youtube.com/watch?v=aaaaaaaaaaa") || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_eq "fail 400" "$out" "status reported"
}

test_linkedin_redirect_prints_final_url() {
  local log out
  log=$(mktemp)
  out=$(FAKE_CURL_LOG=$log cl li-redirect "https://www.linkedin.com/learning/oauth-2-0-essentials-2")
  assert_eq $'ok\thttps://www.linkedin.com/learning/oauth-2-0-essentials' "$out" "final URL printed"
  assert_contains "$(cat "$log")" "-L" "follows redirects"
}

test_linkedin_404_fails() {
  local out rc=0
  out=$(cl li-404 "https://www.linkedin.com/learning/no-such-course") || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_eq "fail 404" "$out" "status reported"
}

test_linkedin_leaves_learning_fails_not_learning() {
  local out rc=0
  out=$(cl li-leaves "https://www.linkedin.com/learning/gone") || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_eq "fail not-learning" "$out" "redirect off /learning/ fails"
}

test_other_200_ok() {
  assert_eq $'ok\thttps://developer.mozilla.org/en-US/docs/Web/HTTP' "$(cl other-200 "https://developer.mozilla.org/en-US/docs/Web/HTTP")" "other URL ok"
}

test_timeout_fails() {
  local out rc=0
  out=$(cl timeout "https://www.youtube.com/watch?v=abcdefghijk") || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_eq "fail timeout" "$out" "timeout reported"
}

test_check_link_needs_url() {
  assert_exit 2 "no URL exits 2" -- "$TOOLS" check-link
}

if [[ $LIVE == 1 ]]; then
  test_live_youtube_invalid_id_fails() {
    assert_exit 1 "invalid YouTube id fails live" -- "$TOOLS" check-link "https://www.youtube.com/watch?v=aaaaaaaaaaa"
  }
  test_live_youtube_real_video_ok() {
    local out
    out=$("$TOOLS" check-link "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    assert_contains "$out" $'ok\t' "real video passes live"
  }
fi

# ---- lint-page ----

# lint FILE_IN_PAGES -> output; sets LINT_RC
lint() { (cd "$FIX/pages" && "$TOOLS" lint-page "$@"); }

test_lint_good_page_passes() {
  local out rc=0
  out=$(lint good.md) || rc=$?
  assert_eq 0 "$rc" "good page exits 0"
  assert_eq "" "$out" "good page prints nothing"
}

_lint_expect() { # RULE EXPECTED_OUTPUT
  local out rc=0
  out=$(lint "bad-$1.md") || rc=$?
  assert_eq 1 "$rc" "$1 exits 1"
  assert_eq "$2" "$out" "$1 reported"
}

test_lint_flags_details_blank_line() { _lint_expect details-blank-line "bad-details-blank-line.md:5: details-blank-line"; }
test_lint_flags_details_markdown()   { _lint_expect details-markdown "bad-details-markdown.md:5: details-markdown"; }
test_lint_flags_details_nested()     { _lint_expect details-nested "bad-details-nested.md:4: details-nested"; }
test_lint_flags_wikilink()           { _lint_expect wikilink "bad-wikilink.md:3: wikilink"; }
test_lint_flags_foldable_callout()   { _lint_expect foldable-callout "bad-foldable-callout.md:3: foldable-callout"; }
test_lint_flags_highlight()          { _lint_expect highlight "bad-highlight.md:3: highlight"; }
test_lint_flags_warning_in_toggle()  { _lint_expect warning-in-toggle "bad-warning-in-toggle.md:4: warning-in-toggle"; }

test_lint_allows_relative_assets_image() {
  _lint_expect remote-image "$(printf 'bad-remote-image.md:3: remote-image\nbad-remote-image.md:4: remote-image')"
}

test_lint_flags_details_open() {
  _lint_expect details-open "bad-details-open.md:3: details-open"
}

test_lint_flags_dead_links() {
  _lint_expect dead-link "$(printf 'bad-dead-link.md:3: dead-link ../app-map.md\nbad-dead-link.md:5: dead-link assets/missing.png\nbad-dead-link.md:8: dead-link nope.md')"
}

test_lint_flags_mermaid_type() {
  _lint_expect mermaid-type "bad-mermaid-type.md:5: mermaid-type"
}

test_lint_flags_mermaid_quote() {
  _lint_expect mermaid-quote "bad-mermaid-quote.md:5: mermaid-quote"
}

test_lint_flags_git_ignored_page() {
  local p out rc=0
  p=$(new_repo)
  printf 'shop-web/\n' > "$p/.gitignore"
  mkdir -p "$p/docs/how-it-works/shop-web"
  printf '# map\n' > "$p/docs/how-it-works/shop-web/app-map.md"
  printf '# map\n' > "$p/docs/how-it-works/app-map.md"
  out=$(cd "$p" && "$TOOLS" lint-page docs/how-it-works/app-map.md docs/how-it-works/shop-web/app-map.md) || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_eq "docs/how-it-works/shop-web/app-map.md:1: git-ignored" "$out" "a page git would skip is reported"
}

test_lint_inline_pre_does_not_switch_rules_off() {
  _lint_expect after-inline-pre "bad-after-inline-pre.md:5: wikilink"
}

test_lint_accepts_link_titles_queries_and_diagram_comments() {
  local out rc=0
  out=$(lint links-ok.md) || rc=$?
  assert_eq "" "$out" "titles, a query string, an indented diagram and a leading comment are fine"
}

test_lint_flags_hard_wrapped_prose() {
  _lint_expect hard-wrap "$(printf 'bad-hard-wrap.md:4: hard-wrap\nbad-hard-wrap.md:8: hard-wrap')"
}

test_lint_ignores_code_in_pre() {
  local out rc=0
  out=$(lint pre-code.md) || rc=$?
  assert_eq "" "$out" "code quoted in <pre> trips no rule"
  assert_eq 0 "$rc" "exit 0"
}

test_lint_ignores_fenced_code() {
  local out rc=0
  out=$(lint fenced.md) || rc=$?
  assert_eq 0 "$rc" "fenced code ignored"
  assert_eq "" "$out" "no output for fenced code"
}

test_lint_several_files() {
  local out rc=0
  out=$(lint good.md bad-wikilink.md bad-highlight.md) || rc=$?
  assert_eq 1 "$rc" "any violation exits 1"
  assert_eq "$(printf 'bad-wikilink.md:3: wikilink\nbad-highlight.md:3: highlight')" "$out" "violations from every file"
}

test_lint_missing_file_exits_2() {
  assert_exit 2 "missing file exits 2" -- "$TOOLS" lint-page "$FIX/pages/nope.md"
}

# ---- page template ----

TEMPLATE="$ROOT/skills/grasp/templates/issue-page.md"

test_example_page_lints_clean() {
  assert_exit 0 "example page lints clean" -- "$TOOLS" lint-page "$FIX/pages/example-issue-page.md"
}

test_template_has_sections() {
  local body sec
  body=$(cat "$TEMPLATE")
  for sec in "Where it fits" "Before and after" "How it works" "Decision" "Blocker" "Explain it back" "Learn more"; do
    assert_contains "$body" "## $sec" "template has section $sec"
  done
}

test_template_lints_clean() {
  local out
  # the instruction header above "---" is wrapped prose for the agent; the page part is checked
  # for wraps and links in test_new_templates_lint_clean
  out=$("$TOOLS" lint-page "$TEMPLATE" | grep -v ': hard-wrap$') || true
  assert_eq "" "$out" "template lints clean (no blank line or Markdown inside toggles)"
}

test_example_has_sections() {
  local body sec
  body=$(cat "$FIX/pages/example-issue-page.md")
  for sec in "Where it fits" "Before and after" "How it works" "Decision" "Explain it back" "Learn more"; do
    assert_contains "$body" "## $sec" "example has section $sec"
  done
}

# ---- run records: the block in AGENTS.md / CLAUDE.md ----

RECORD_MARKER='<!-- grasp:start b=1 v=0.3.0 step=record dir=docs/how-it-works/runs -->'

test_connect_record_appends_block_to_agents_md() {
  local p out body
  p=$(new_project)
  printf '# Project rules\n\nUse tabs.\n' > "$p/AGENTS.md"
  out=$(gt --config "$p/.grasp.md" connect AGENTS.md record)
  assert_eq "connected AGENTS.md record" "$out" "connect prints confirmation"
  body=$(cat "$p/AGENTS.md")
  assert_eq "$(printf '# Project rules\n\nUse tabs.\n\n%s' "$RECORD_MARKER")" "$(head -n 5 "$p/AGENTS.md")" "user text kept, block after one blank line"
  assert_eq "<!-- grasp:end -->" "$(tail -n 1 "$p/AGENTS.md")" "block closed"
  assert_contains "$body" "## Run records (grasp)" "block heading"
  assert_contains "$body" 'docs/how-it-works/runs/YYYY-MM-DD-short-name.md' "block names the record path"
  assert_contains "$body" 'part of the task, also when you were told to change only' "block says the record is never an extra file"
  for f in '**Asked:**' '**Changed:**' '**Checked:**' '**Problems:**' '**Next:**'; do
    assert_contains "$body" "$f" "block lists field $f"
  done
  assert_contains "$(cat "$p/.grasp.md")" "| AGENTS.md | record | 0.3.0 |" "row recorded"
  assert_eq $'AGENTS.md\trecord\tok' "$(gt --config "$p/.grasp.md" status)" "status ok"
}

test_record_block_is_short() {
  local p n
  p=$(new_project)
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  n=$(wc -l < "$p/AGENTS.md" | tr -d ' ')
  [[ $n -le 20 ]] || _fail "the block loads into every session, so it stays under 20 lines (got $n)"
}

test_connect_record_creates_missing_file() {
  local p
  p=$(new_project)
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  assert_eq "$RECORD_MARKER" "$(head -n 1 "$p/AGENTS.md")" "new file starts with the block"
}

test_connect_record_twice_is_idempotent() {
  local p a
  p=$(new_project)
  printf '# Rules\n' > "$p/CLAUDE.md"
  gt --config "$p/.grasp.md" connect CLAUDE.md record >/dev/null
  a=$(mktemp); cp "$p/CLAUDE.md" "$a"
  gt --config "$p/.grasp.md" connect ./CLAUDE.md record >/dev/null
  assert_file_eq "$a" "$p/CLAUDE.md" "file unchanged on second connect"
  assert_eq 1 "$(grep -c '^| CLAUDE.md |' "$p/.grasp.md")" "one row"
}

test_disconnect_record_restores_file() {
  local p orig
  p=$(new_project)
  printf '# Project rules\n\nUse tabs.\n' > "$p/AGENTS.md"
  orig=$(mktemp); cp "$p/AGENTS.md" "$orig"
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  gt --config "$p/.grasp.md" disconnect AGENTS.md >/dev/null
  assert_file_eq "$orig" "$p/AGENTS.md" "original restored"
  assert_eq "" "$(gt --config "$p/.grasp.md" status)" "row gone"
}

test_record_folder_comes_from_config_and_goes_stale() {
  local p
  p=$(new_project)
  printf '\n## Notebook\n\n- run records: ../docs/how-it-works/runs\n' >> "$p/.grasp.md"
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  assert_eq '<!-- grasp:start b=1 v=0.3.0 step=record dir=../docs/how-it-works/runs -->' "$(head -n 1 "$p/AGENTS.md")" "marker holds the configured folder"
  assert_contains "$(cat "$p/AGENTS.md")" '`../docs/how-it-works/runs/YYYY-MM-DD-short-name.md`' "block path uses it"
  sed -i.bak 's|^- run records: .*|- run records: notes/runs|' "$p/.grasp.md"
  assert_eq $'AGENTS.md\trecord\tstale' "$(gt --config "$p/.grasp.md" status)" "a moved folder makes the block stale"
  gt --config "$p/.grasp.md" refresh >/dev/null
  assert_eq $'AGENTS.md\trecord\tok' "$(gt --config "$p/.grasp.md" status)" "refresh rewrites it"
  assert_contains "$(cat "$p/AGENTS.md")" 'dir=notes/runs -->' "marker updated"
}

test_record_block_for_a_shared_folder_names_the_project() {
  local p
  p=$(new_tmp); mkdir -p "$p/shop-api"
  printf -- '- run records: ../docs/how-it-works/runs\n' > "$p/shop-api/.grasp.md"
  gt --config "$p/shop-api/.grasp.md" connect AGENTS.md record >/dev/null
  assert_contains "$(cat "$p/shop-api/AGENTS.md")" 'start the short name with `shop-api-`' "a sub-repository's block says to prefix the project"
  p=$(new_project); gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  [[ "$(cat "$p/AGENTS.md")" != *"shared by several projects"* ]] || _fail "a single project's block has no prefix rule"
}

test_block_prints_what_connect_would_write() {
  local p
  p=$(new_project)
  gt --config "$p/.grasp.md" block record > "$p/shown.txt"
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  assert_file_eq "$p/shown.txt" "$p/AGENTS.md" "block record prints exactly what connect writes"
  assert_eq "$(expected_block verify)" "$(gt --config "$p/.grasp.md" block verify)" "block STEP prints a skill block"
  assert_exit 2 "block needs a valid step" -- "$TOOLS" block deploy
}

test_unusable_tmpdir_never_empties_a_file() {
  local p before cfg
  p=$(new_project)
  printf '# My rules\n\nKeep this.\n' > "$p/AGENTS.md"
  assert_exit 1 "connect fails without a temp folder" -- env TMPDIR=/nonexistent/grasp "$TOOLS" --config "$p/.grasp.md" connect AGENTS.md record
  assert_eq "$(printf '# My rules\n\nKeep this.')" "$(cat "$p/AGENTS.md")" "file untouched by the failed connect"
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  before=$(mktemp); cfg=$(mktemp); cp "$p/AGENTS.md" "$before"; cp "$p/.grasp.md" "$cfg"
  assert_exit 1 "disconnect fails without a temp folder" -- env TMPDIR=/nonexistent/grasp "$TOOLS" --config "$p/.grasp.md" disconnect AGENTS.md
  assert_file_eq "$before" "$p/AGENTS.md" "AGENTS.md untouched by the failed disconnect"
  assert_file_eq "$cfg" "$p/.grasp.md" ".grasp.md untouched by the failed disconnect"
}

test_read_only_file_is_reported() {
  local p
  [[ $(id -u) != 0 ]] || return 0   # root writes through a read-only bit: nothing to test
  p=$(new_project)
  printf '# Rules\n' > "$p/AGENTS.md"; chmod 444 "$p/AGENTS.md"
  assert_exit 1 "connect says it could not write" -- "$TOOLS" --config "$p/.grasp.md" connect AGENTS.md record
  assert_eq "" "$(gt --config "$p/.grasp.md" status)" "nothing recorded as connected"
  chmod 644 "$p/AGENTS.md"
}

test_non_utf8_byte_does_not_duplicate_the_block() {
  local p
  p=$(new_project)
  printf '# Rules\n\nDon\x92t push.\n' > "$p/AGENTS.md"
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  assert_eq 1 "$(LC_ALL=C grep -c 'grasp:start' "$p/AGENTS.md")" "still one block"
  assert_eq $'AGENTS.md\trecord\tok' "$(gt --config "$p/.grasp.md" status)" "status finds it"
  gt --config "$p/.grasp.md" disconnect AGENTS.md >/dev/null
  assert_eq "$(printf '# Rules\n\nDon\x92t push.')" "$(cat "$p/AGENTS.md")" "bytes restored"
}

test_unclosed_fence_above_the_block_is_refused() {
  local p before
  p=$(new_project)
  printf '# Rules\n' > "$p/AGENTS.md"
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  { printf '# Rules\n\n```\nan example that was never closed\n\n'; sed '1,2d' "$p/AGENTS.md"; } > "$p/new" && mv "$p/new" "$p/AGENTS.md"
  before=$(mktemp); cp "$p/AGENTS.md" "$before"
  assert_exit 1 "connect refuses to append a second block" -- "$TOOLS" --config "$p/.grasp.md" connect AGENTS.md record
  assert_file_eq "$before" "$p/AGENTS.md" "file untouched"
}

test_run_records_value_is_trimmed() {
  local p
  p=$(new_project)
  printf -- '\n- run records: notes/runs/  \n' >> "$p/.grasp.md"
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  assert_eq '<!-- grasp:start b=1 v=0.3.0 step=record dir=notes/runs -->' "$(head -n 1 "$p/AGENTS.md")" "trailing slash and spaces dropped"
}

test_connect_import_makes_claude_md_load_agents_md() {
  local p want
  p=$(new_project)
  assert_eq "connected CLAUDE.md import" "$(gt --config "$p/.grasp.md" connect CLAUDE.md import)" "connect prints confirmation"
  want=$(mktemp); printf '<!-- grasp:start b=1 v=0.3.0 step=import -->\n@AGENTS.md\n<!-- grasp:end -->\n' > "$want"
  assert_file_eq "$want" "$p/CLAUDE.md" "a missing CLAUDE.md is created with only the import"
  gt --config "$p/.grasp.md" connect CLAUDE.md import >/dev/null
  assert_file_eq "$want" "$p/CLAUDE.md" "second connect changes nothing"
  assert_eq $'CLAUDE.md\timport\tok' "$(gt --config "$p/.grasp.md" status)" "status lists it"
  printf '# My rules\n\nUse tabs.\n' > "$p/CLAUDE.md"
  gt --config "$p/.grasp.md" connect CLAUDE.md import >/dev/null
  assert_eq "$(printf '# My rules\n\nUse tabs.\n\n<!-- grasp:start b=1 v=0.3.0 step=import -->\n@AGENTS.md\n<!-- grasp:end -->')" "$(cat "$p/CLAUDE.md")" "an existing CLAUDE.md keeps its text"
  gt --config "$p/.grasp.md" disconnect CLAUDE.md >/dev/null
  assert_eq "$(printf '# My rules\n\nUse tabs.')" "$(cat "$p/CLAUDE.md")" "disconnect restores it"
}

test_block_with_old_text_is_stale() {
  local p
  p=$(new_project)
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  sed -i.bak 's/one short plain sentence each/one sentence each/' "$p/AGENTS.md"
  sed -i.bak 's/grasp:start b=1 v=0.3.0 step=work/grasp:start b=1 v=0.2.0 step=work/' "$p/.claude/skills/plain/SKILL.md"
  assert_eq "$(printf 'AGENTS.md\trecord\tstale\n.claude/skills/plain\twork\tok')" "$(gt --config "$p/.grasp.md" status)" "changed wording is stale; an older version number alone is not"
  gt --config "$p/.grasp.md" refresh >/dev/null
  assert_contains "$(cat "$p/AGENTS.md")" "one short plain sentence each" "refresh restores the current text"
}

test_record_and_skill_rows_live_together() {
  local p
  p=$(new_project)
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  assert_eq "$(printf '.claude/skills/plain\twork\tok\nAGENTS.md\trecord\tok')" "$(gt --config "$p/.grasp.md" status)" "both kinds listed"
  assert_contains "$(cat "$p/.claude/skills/plain/SKILL.md")" "step=work -->" "skill block keeps its own text"
}

test_record_broken_marker_is_refused() {
  local p before
  p=$(new_project)
  printf '# Rules\n\n<!-- grasp:start b=1 v=0.3.0 step=record dir=x -->\nmine\n' > "$p/AGENTS.md"
  before=$(mktemp); cp "$p/AGENTS.md" "$before"
  assert_exit 1 "connect refuses a start marker with no end" -- "$TOOLS" --config "$p/.grasp.md" connect AGENTS.md record
  assert_file_eq "$before" "$p/AGENTS.md" "user text untouched"
}

test_refresh_unknown_target_fails() {
  local p
  p=$(new_project)
  assert_exit 1 "refresh of a path that is not connected fails" -- "$TOOLS" --config "$p/.grasp.md" refresh AGENTS.md
}

# ---- run records: the index ----

# runs_copy -> tmp dir holding a copy of the run record fixtures
runs_copy() { local d; d=$(new_tmp); cp "$FIX/runs/"*.md "$d/"; printf '%s' "$d"; }

test_record_index_builds_table() {
  local d out want
  d=$(runs_copy)
  out=$(gt record-index "$d")
  assert_eq "indexed 3 $d/README.md" "$out" "prints the count and the file"
  want=$(mktemp)
  cat > "$want" <<'EOF'
# Run records

What agents did here, newest first. One row per task; open it for the detail.

This table is built by `grasp-tools record-index`. Don't edit it by hand: run that again, also to settle a merge conflict here.

| Date | Task | Status | What changed | Problems |
| ---- | ---- | ------ | ------------ | -------- |
| 2026-11-21 | [Login redirect fix](2026-11-21-login-redirect-fix.md) | partial | Login returns users to the page they came from; the mobile app isn't fixed yet. | The test database isn't reachable, so nothing ran \| the mobile app still lands on a blank page. |
| 2026-11-20 | [CSV export on the report page](2026-11-20-csv-export.md) | done | Anyone on the report page can download the rows they see as a CSV file. | Dates export in UTC, not the user's time zone. |
| 2026-11-19 | [2026-11-19-notes](2026-11-19-notes.md) | ? | ? | ? |
EOF
  assert_file_eq "$want" "$d/README.md" "index content"
}

test_record_index_escapes_title_and_file_name() {
  local d
  d=$(new_tmp)
  printf '# 2026-01-02: Fix [tags] parsing\n\nStatus: done\n\n- **Changed:** Tags parse.\n- **Problems:** none\n' > "$d/2026-01-02-fix (tags).md"
  gt record-index "$d" >/dev/null
  assert_contains "$(cat "$d/README.md")" '| 2026-01-02 | [Fix \[tags\] parsing](2026-01-02-fix%20%28tags%29.md) | done |' "brackets and parentheses can't break the link"
}

test_record_index_is_idempotent_and_lints() {
  local d a
  d=$(runs_copy)
  gt record-index "$d" >/dev/null
  a=$(mktemp); cp "$d/README.md" "$a"
  gt record-index "$d" >/dev/null
  assert_file_eq "$a" "$d/README.md" "second run changes nothing"
  assert_exit 0 "index and records lint clean" -- "$TOOLS" lint-page "$d/README.md" "$d/2026-11-20-csv-export.md" "$d/2026-11-21-login-redirect-fix.md"
}

test_record_index_empty_folder() {
  local d
  d=$(new_tmp)
  assert_eq "indexed 0 $d/README.md" "$(gt record-index "$d")" "empty folder still gets an index"
  assert_contains "$(cat "$d/README.md")" "| Date | Task |" "table header written"
}

test_record_index_uses_config_folder() {
  local p
  p=$(new_project)
  mkdir -p "$p/notes/runs"; cp "$FIX/runs/2026-11-20-csv-export.md" "$p/notes/runs/"
  printf '\n- run records: notes/runs\n' >> "$p/.grasp.md"
  gt --config "$p/.grasp.md" record-index >/dev/null
  assert_contains "$(cat "$p/notes/runs/README.md")" "CSV export on the report page" "index written in the configured folder"
}

test_record_index_missing_folder_exits_1() {
  assert_exit 1 "missing folder exits 1" -- "$TOOLS" record-index "$(new_tmp)/nope"
}

# ---- run records: the check ----

g() { git -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false "$@"; }

# new_repo: a git repo on main with one commit, a .grasp.md and a notebook folder; prints its path
new_repo() {
  local p
  p=$(new_tmp); p=$(cd -P "$p" && pwd)
  g -C "$p" init -q -b main
  mkdir -p "$p/src" "$p/docs/how-it-works/runs"
  printf '## Code\n\n- integration branch: main\n' > "$p/.grasp.md"
  printf 'one\n' > "$p/src/app.txt"
  printf '# Run records\n' > "$p/docs/how-it-works/runs/README.md"
  g -C "$p" add -A; g -C "$p" commit -qm init
  printf '%s' "$p"
}

rc_of() { local rc=0; "$@" >/dev/null 2>&1 || rc=$?; printf '%s' "$rc"; }

test_record_check_clean_tree_ok() {
  local p
  p=$(new_repo)
  assert_eq "ok nothing-changed (uncommitted only: no base to compare commits with)" "$(gt --config "$p/.grasp.md" record-check)" "clean tree, and it says what it could not see"
}

test_record_check_dirty_without_record_fails() {
  local p out rc=0
  p=$(new_repo)
  printf 'two\n' >> "$p/src/app.txt"; printf 'new\n' > "$p/src/new.txt"
  out=$(gt --config "$p/.grasp.md" record-check) || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_eq "missing 2 changed files, no run record in docs/how-it-works/runs" "$out" "says what is missing"
}

test_record_check_dirty_with_record_ok() {
  local p
  p=$(new_repo)
  printf 'two\n' >> "$p/src/app.txt"
  printf '# 2026-11-21: x\n' > "$p/docs/how-it-works/runs/2026-11-21-x.md"
  assert_eq "ok recorded" "$(gt --config "$p/.grasp.md" record-check)" "a new record satisfies the check"
}

test_record_check_index_alone_is_not_a_record() {
  local p
  p=$(new_repo)
  printf 'two\n' >> "$p/src/app.txt"
  printf 'more\n' >> "$p/docs/how-it-works/runs/README.md"
  assert_eq 1 "$(rc_of "$TOOLS" --config "$p/.grasp.md" record-check)" "README.md does not count"
}

test_record_check_notebook_only_changes_ok() {
  local p
  p=$(new_repo)
  printf '# map\n' > "$p/docs/how-it-works/app-map.md"
  assert_contains "$(gt --config "$p/.grasp.md" record-check)" "ok nothing-changed" "pages alone need no record"
}

test_record_check_branch_commits() {
  local p
  p=$(new_repo)
  g -C "$p" checkout -qb feat/x
  printf 'two\n' >> "$p/src/app.txt"; g -C "$p" commit -qam work
  assert_eq 1 "$(rc_of "$TOOLS" --config "$p/.grasp.md" record-check)" "committed branch work with no record fails"
  printf '# 2026-11-21: x\n' > "$p/docs/how-it-works/runs/2026-11-21-x.md"
  g -C "$p" add -A; g -C "$p" commit -qm record
  assert_eq "ok recorded" "$(gt --config "$p/.grasp.md" record-check)" "a record committed on the branch passes"
  assert_eq "ok nothing-changed" "$(gt --config "$p/.grasp.md" record-check --base HEAD~1)" "--base narrows the range to one commit"
}

test_record_check_deleted_record_is_not_a_record() {
  local p
  p=$(new_repo)
  printf '# 2026-11-01: old\n' > "$p/docs/how-it-works/runs/2026-11-01-old.md"
  g -C "$p" add -A; g -C "$p" commit -qm old
  printf 'two\n' >> "$p/src/app.txt"; rm "$p/docs/how-it-works/runs/2026-11-01-old.md"
  assert_eq 1 "$(rc_of "$TOOLS" --config "$p/.grasp.md" record-check)" "deleting an old record does not record this work"
}

test_record_check_staged_files_before_the_first_commit() {
  local p
  p=$(new_tmp); p=$(cd -P "$p" && pwd)
  g -C "$p" init -q -b main
  printf -- '- integration branch: main\n' > "$p/.grasp.md"; printf 'one\n' > "$p/app.txt"
  g -C "$p" add -A
  assert_eq 1 "$(rc_of "$TOOLS" --config "$p/.grasp.md" record-check)" "staged work in a repository with no commits is seen"
}

test_record_check_unknown_base_exits_2() {
  local p
  p=$(new_repo)
  assert_exit 2 "an unknown --base is an error, not a pass" -- "$TOOLS" --config "$p/.grasp.md" record-check --base nosuchref
}

test_record_check_hook_never_blocks_on_bad_arguments() {
  local p rc=0
  p=$(new_repo); printf 'two\n' >> "$p/src/app.txt"
  printf '{}' | gt --config "$p/.grasp.md" record-check --hook --bogus >/dev/null 2>&1 || rc=$?
  assert_eq 0 "$rc" "a bad flag in hook mode lets the stop through"
  rc=0; printf '{}' | gt --config "$p/.grasp.md" record-check --base nosuchref --hook >/dev/null 2>&1 || rc=$?
  assert_eq 0 "$rc" "an unknown base in hook mode lets the stop through"
}

test_record_check_hook_reminds_once_per_state() {
  local p t in rc
  p=$(new_repo); t=$(new_tmp); in='{"session_id":"abc-123","stop_hook_active":false}'
  printf 'two\n' >> "$p/src/app.txt"
  rc=0; printf '%s' "$in" | TMPDIR=$t "$TOOLS" --config "$p/.grasp.md" record-check --hook >/dev/null 2>&1 || rc=$?
  assert_eq 2 "$rc" "first stop in a changed tree: reminded"
  rc=0; printf '%s' "$in" | TMPDIR=$t "$TOOLS" --config "$p/.grasp.md" record-check --hook >/dev/null 2>&1 || rc=$?
  assert_eq 0 "$rc" "next turn, nothing new changed: no second reminder"
  printf 'three\n' >> "$p/src/app.txt"
  rc=0; printf '%s' "$in" | TMPDIR=$t "$TOOLS" --config "$p/.grasp.md" record-check --hook >/dev/null 2>&1 || rc=$?
  assert_eq 2 "$rc" "the files changed again: reminded again"
  rc=0; printf '{"session_id":"other","stop_hook_active":false}' | TMPDIR=$t "$TOOLS" --config "$p/.grasp.md" record-check --hook >/dev/null 2>&1 || rc=$?
  assert_eq 2 "$rc" "another session gets its own reminder"
}

test_record_check_not_a_git_repo_ok() {
  local p
  p=$(new_project)
  assert_eq "ok not-a-git-repo" "$(gt --config "$p/.grasp.md" record-check)" "no git, nothing to check"
}

test_record_check_hook_blocks_with_exit_2() {
  local p err rc=0
  p=$(new_repo)
  printf 'two\n' >> "$p/src/app.txt"
  err=$(printf '{"hook_event_name":"Stop","stop_hook_active":false}' | gt --config "$p/.grasp.md" record-check --hook 2>&1 >/dev/null) || rc=$?
  assert_eq 2 "$rc" "exit 2 blocks the stop"
  assert_contains "$err" "run record" "reason on stderr"
  assert_contains "$err" "docs/how-it-works/runs" "reason names the folder"
}

test_record_check_hook_never_loops() {
  local p rc=0
  p=$(new_repo)
  printf 'two\n' >> "$p/src/app.txt"
  printf '{"hook_event_name":"Stop", "stop_hook_active": true}' | gt --config "$p/.grasp.md" record-check --hook >/dev/null 2>&1 || rc=$?
  assert_eq 0 "$rc" "stop_hook_active lets the stop through"
}

test_record_check_hook_silent_when_ok() {
  local p out rc=0
  p=$(new_repo)
  out=$(printf '{"stop_hook_active":false}' | gt --config "$p/.grasp.md" record-check --hook 2>&1) || rc=$?
  assert_eq 0 "$rc" "exit 0"
  assert_eq "" "$out" "prints nothing"
}

test_record_check_hook_fails_open_without_config() {
  local p rc=0
  p=$(new_tmp)
  printf '{}' | gt --config "$p/.grasp.md" record-check --hook >/dev/null 2>&1 || rc=$?
  assert_eq 0 "$rc" "no .grasp.md: never block"
}

test_record_check_records_in_another_repo() {
  local top p d
  top=$(new_tmp); top=$(cd -P "$top" && pwd)
  p="$top/app"; d="$top/docs/how-it-works/runs"
  mkdir -p "$p/src" "$d"
  g -C "$top" init -q -b main
  printf 'app/\n' > "$top/.gitignore"; printf '# Run records\n' > "$d/README.md"
  g -C "$top" add -A; g -C "$top" commit -qm docs
  g -C "$p" init -q -b main
  printf -- '- integration branch: main\n- run records: ../docs/how-it-works/runs\n' > "$p/.grasp.md"
  printf 'one\n' > "$p/src/app.txt"; g -C "$p" add -A; g -C "$p" commit -qm init
  printf 'two\n' >> "$p/src/app.txt"
  assert_eq 1 "$(rc_of "$TOOLS" --config "$p/.grasp.md" record-check)" "work in the sub-repo, no record in the wrapper"
  printf '# 2026-11-21: x\n' > "$d/2026-11-21-x.md"
  assert_eq "ok recorded" "$(gt --config "$p/.grasp.md" record-check)" "a new record in the wrapper's docs passes"
}

# ---- projects ----

test_projects_lists_sub_projects() {
  local t
  t=$(new_tmp)
  mkdir -p "$t/backend/.git" "$t/frontend/packages/ui" "$t/packages/api" "$t/node_modules/x" "$t/docs" "$t/infra" "$t/.cache/y"
  printf '{}' > "$t/package.json"
  printf 'module x\n' > "$t/backend/go.mod"
  printf 'gitdir: ../.git/modules/frontend\n' > "$t/frontend/.git"
  printf '{}' > "$t/frontend/package.json"
  printf '{}' > "$t/frontend/packages/ui/package.json"
  printf '{}' > "$t/packages/api/package.json"
  printf '{}' > "$t/node_modules/x/package.json"
  printf '{}' > "$t/.cache/y/package.json"
  printf 'FROM scratch\n' > "$t/infra/Dockerfile"
  printf '# docs\n' > "$t/docs/README.md"
  assert_eq "$(printf 'backend\trepo\t.git,go.mod\nfrontend\trepo\t.git,package.json\ninfra\tpackage\tDockerfile\npackages/api\tpackage\tpackage.json')" "$(gt projects "$t")" "repos and packages, nothing inside a nested repo or node_modules"
}

test_projects_ignores_cdpath() {
  local t
  t=$(new_tmp); mkdir -p "$t/top/api" "$t/other/top/web"
  printf '{}' > "$t/top/api/package.json"; printf '{}' > "$t/other/top/web/package.json"
  assert_eq $'api\tpackage\tpackage.json' "$(cd "$t" && CDPATH="$t/other" "$TOOLS" projects top)" "an exported CDPATH changes nothing"
}

test_projects_shows_the_remote_of_a_repository() {
  local t
  t=$(new_tmp)
  for r in api api-second-checkout web; do g -C "$t" init -q -b main "$r"; done
  g -C "$t/api" remote add origin git@example.com:acme/api.git
  g -C "$t/api-second-checkout" remote add origin git@example.com:acme/api.git
  assert_eq "$(printf 'api\trepo\t.git\tgit@example.com:acme/api.git\napi-second-checkout\trepo\t.git\tgit@example.com:acme/api.git\nweb\trepo\t.git')" "$(gt projects "$t")" "two checkouts of one repository show the same remote"
}

test_projects_none_prints_nothing() {
  local t out rc=0
  t=$(new_tmp); printf '{}' > "$t/package.json"; mkdir -p "$t/src"
  out=$(gt projects "$t") || rc=$?
  assert_eq 0 "$rc" "exit 0"
  assert_eq "" "$out" "a single project lists nothing"
}

test_projects_missing_dir_exits_2() {
  assert_exit 2 "missing dir exits 2" -- "$TOOLS" projects "$(new_tmp)/nope"
}

# ---- run record and overview templates ----

# page_of TEMPLATE -> the page itself: everything after the template's "---" line
page_of() { awk 'f { print } /^---$/ { f = 1 }' "$ROOT/skills/grasp/templates/$1.md"; }

test_new_templates_lint_clean() {
  local d t out rc
  for t in run-record app-map feature-page workspace-map issue-page; do
    rc=0
    out=$("$TOOLS" lint-page "$ROOT/skills/grasp/templates/$t.md" | grep -v -e ': dead-link ' -e ': hard-wrap$') || true
    assert_eq "" "$out" "$t template: toggles and diagrams lint clean"
  done
  # the page parts, laid out as a notebook, have no dead links either
  d=$(new_tmp); mkdir -p "$d/features" "$d/runs"
  page_of app-map > "$d/app-map.md"; page_of workspace-map > "$d/workspace-map.md"
  page_of feature-page > "$d/features/some-feature.md"; page_of run-record > "$d/runs/2026-01-02-x.md"
  page_of issue-page > "$d/features/KEY-1-some-issue.md"
  printf '# Features\n' > "$d/features/README.md"; printf '# Run records\n' > "$d/runs/README.md"
  out=$("$TOOLS" lint-page "$d/app-map.md" "$d/workspace-map.md" "$d/features/some-feature.md" "$d/features/KEY-1-some-issue.md" "$d/runs/2026-01-02-x.md") || rc=$?
  assert_eq "" "$out" "template pages in a notebook layout lint clean, links included"
}

test_run_record_template_matches_the_index() {
  local d
  d=$(new_tmp)
  # the template's own page starts after the "---" line
  awk 'f { print } /^---$/ { f = 1 }' "$ROOT/skills/grasp/templates/run-record.md" > "$d/2026-01-02-x.md"
  gt record-index "$d" >/dev/null
  assert_contains "$(cat "$d/README.md")" "{short name}](2026-01-02-x.md) | {done | {what behaves differently now" "the index reads the template's title, status and Changed line"
}

test_app_map_template_has_overview_sections() {
  local body sec
  body=$(cat "$ROOT/skills/grasp/templates/app-map.md")
  for sec in "What it is for" "Core features" "How the features connect" "The pieces" "One request, end to end" "Codemap" "What it keeps" "Not sure yet"; do
    assert_contains "$body" "## $sec" "app map has section $sec"
  done
}

# ---- install.sh ----

test_install_copy_writes_source() {
  local p
  p=$(new_tmp)
  "$ROOT/install.sh" --project "$p" --copy >/dev/null
  assert_eq "$ROOT" "$(cat "$p/.claude/skills/grasp/.source" 2>/dev/null)" ".source holds the repo path (.claude)"
  assert_eq "$ROOT" "$(cat "$p/.agents/skills/grasp/.source" 2>/dev/null)" ".source holds the repo path (.agents)"
  assert_eq "0.3.0" "$("$p/.claude/skills/grasp/bin/grasp-tools" version)" "copied grasp-tools runs"
}

test_install_copy_twice_recopies() {
  local p
  p=$(new_tmp)
  "$ROOT/install.sh" --project "$p" --copy >/dev/null
  printf '0.0.1\n' > "$p/.claude/skills/grasp/VERSION"
  "$ROOT/install.sh" --project "$p" --copy >/dev/null 2>&1
  assert_eq "0.3.0" "$(cat "$p/.claude/skills/grasp/VERSION")" "second --copy replaces grasp's own copy"
  assert_eq "$ROOT" "$(cat "$p/.claude/skills/grasp/.source")" ".source still written"
}

test_install_keeps_foreign_folder() {
  local p
  p=$(new_tmp)
  mkdir -p "$p/.claude/skills/grasp"; printf 'mine\n' > "$p/.claude/skills/grasp/SKILL.md"
  "$ROOT/install.sh" --project "$p" --copy >/dev/null 2>&1
  assert_eq "mine" "$(cat "$p/.claude/skills/grasp/SKILL.md")" "a folder grasp did not copy is left alone"
}

test_install_link_writes_no_source() {
  local p
  p=$(new_tmp)
  "$ROOT/install.sh" --project "$p" >/dev/null
  [[ ! -e "$ROOT/skills/grasp/.source" ]] || _fail "link install leaves no .source in the repo"
  assert_eq "0.3.0" "$("$p/.claude/skills/grasp/bin/grasp-tools" version)" "grasp-tools runs through the symlink"
}

test_uninstall_removes_only_own_installs() {
  local p
  p=$(new_tmp)
  "$ROOT/install.sh" --project "$p" --copy >/dev/null
  rm -rf "$p/.claude/skills/grasp"
  mkdir -p "$p/.claude/skills/grasp"; printf 'mine\n' > "$p/.claude/skills/grasp/SKILL.md"
  "$ROOT/install.sh" --project "$p" --uninstall >/dev/null 2>&1
  assert_eq "mine" "$(cat "$p/.claude/skills/grasp/SKILL.md" 2>/dev/null)" "uninstall leaves a folder grasp did not install"
  [[ ! -e "$p/.agents/skills/grasp" ]] || _fail "uninstall removes grasp's own copy"
  "$ROOT/install.sh" --project "$p" >/dev/null 2>&1
  "$ROOT/install.sh" --project "$p" --uninstall >/dev/null 2>&1
  [[ ! -L "$p/.agents/skills/grasp" ]] || _fail "uninstall removes grasp's symlink"
  [[ -d "$ROOT/skills/grasp" ]] || _fail "uninstall leaves the symlink target in the repo"
}

run_tests "${1:-.}"
