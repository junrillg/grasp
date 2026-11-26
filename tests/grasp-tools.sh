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

test_version_prints_the_version_file() {
  assert_eq "$(cat "$ROOT/skills/grasp/VERSION")" "$(gt version)" "version prints the VERSION file"
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
  for c in connect disconnect block status refresh record-index record-check projects check-link lint-page change-map snippet snippet-check coverage keep-walk sync version; do
    assert_contains "$out" "$c" "help lists $c"
  done
}

# ---- connect / disconnect / status / refresh ----

# expected_block STEP [EOL] -> the exact block grasp writes
expected_block() {
  local step=$1 eol=${2:-$'\n'}
  printf '%s%s' \
    "<!-- grasp:start b=1 v=0.5.0 step=$step -->" "$eol" \
    "## Learning page (grasp)" "$eol" \
    "When this skill has finished its own work, run grasp's \`page\` subcommand for the same issue or" "$eol" \
    "pull request with \`--step $step\` (\`/grasp page <issue or PR> --step $step\`, or \`/grasp:grasp page ...\`" "$eol" \
    "when grasp is installed as a plugin), so the issue's learning page shows what was done." "$eol" \
    "The issue's learning page is written by grasp alone: do not write or patch it by this skill's own rules." "$eol" \
    "Skip this if grasp is not installed." "$eol" \
    "<!-- grasp:end -->" "$eol"
}

test_block_says_grasp_alone_writes_the_page() {
  local s
  for s in work verify review resolve; do
    assert_contains "$(gt block "$s")" "written by grasp alone" "$s block"
  done
  [[ "$(gt block record)" != *"written by grasp alone"* ]] || _fail "the record block is unchanged"
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
  assert_contains "$(cat "$p/.grasp.md")" "| .claude/skills/plain | work | 0.5.0 |" "row recorded"
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
  assert_eq 1 "$(grep -c 'grasp:start b=1 v=0.5.0 step=verify' "$p/.claude/skills/plain/SKILL.md")" "block now verify"
  assert_eq 1 "$(grep -c '^| .claude/skills/plain |' "$p/.grasp.md")" "still one row"
  assert_contains "$(cat "$p/.grasp.md")" "| .claude/skills/plain | verify | 0.5.0 |" "row updated"
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
    printf '\n## Connected skills\n\n| skill | step | grasp version |\n| ----- | ---- | ------------- |\n| .claude/skills/plain | work | 0.5.0 |\n'
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
  printf '## Connected skills\n\n| skill | step | grasp version |\n| ----- | ---- | ------------- |\n| .claude/skills/plain | work | 0.5.0 |\n| .claude/skills/crlf | review | 0.5.0 |\n' > "$want"
  assert_file_eq "$want" "$p/.grasp.md" ".grasp.md created with both rows under the header"
  assert_eq 2 "$(gt --config "$p/.grasp.md" status | grep -c $'\tok$')" "status lists both"
}

test_connect_into_empty_template_table() {
  local p
  p=$(new_project)
  sed -n '/^## Connected skills/,$p' "$ROOT/skills/grasp/templates/grasp-config.md" > "$p/.grasp.md"
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  gt --config "$p/.grasp.md" connect .claude/skills/crlf review >/dev/null
  assert_eq "$(printf '| .claude/skills/plain | work | 0.5.0 |\n| .claude/skills/crlf | review | 0.5.0 |')" "$(tail -n 2 "$p/.grasp.md")" "rows appended under the template's empty table"
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
  printf '# grasp settings\n\n## Connected skills\n\n| skill | step | grasp version |\n| ----- | ---- | ------------- |\n| .claude/skills/plain | work | 0.5.0 |\n\nNone yet.\n\n## Voice\n\n- plain\n' > "$want"
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

test_linkedin_renamed_course_fails_redirected() {
  local log out rc=0
  log=$(mktemp)
  out=$(FAKE_CURL_LOG=$log cl li-redirect "https://www.linkedin.com/learning/oauth-2-0-essentials-2") || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_eq "fail redirected https://www.linkedin.com/learning/oauth-2-0-essentials" "$out" "a renamed course is not verified"
  assert_contains "$(cat "$log")" "-L" "follows redirects"
  [[ "$(cat "$log")" != *"/dev/null"* ]] || _fail "the page is read for its title, not thrown away"
}

test_linkedin_same_address_is_ok() {
  assert_eq $'ok\thttps://www.linkedin.com/learning/oauth-2-0-essentials\tOAuth 2.0 Essentials' \
    "$(cl li-same "https://www.linkedin.com/learning/oauth-2-0-essentials")" "final equals requested"
}

test_linkedin_query_and_slash_are_ignored() {
  assert_contains "$(cl li-query "https://www.linkedin.com/learning/oauth-2-0-essentials/?trk=x")" $'ok\t' "query and slash do not count"
}

test_linkedin_bounced_video_fails_redirected() {
  local out rc=0
  out=$(cl li-video-bounced "https://www.linkedin.com/learning/oauth-2-0-essentials/no-such-video") || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_eq "fail redirected https://www.linkedin.com/learning/oauth-2-0-essentials" "$out" "a video that bounces to its course is not verified"
}

test_linkedin_title_entities_decoded() {
  assert_eq $'ok\thttps://www.linkedin.com/learning/devs-guide\tDev\'s Guide to "OAuth" & OpenID' "$(cl li-entities "https://www.linkedin.com/learning/devs-guide")" "&#39; &quot; &amp; decoded"
}

test_linkedin_without_title_fails_no_title() {
  local out rc=0
  out=$(cl li-no-title "https://www.linkedin.com/learning/oauth-2-0-essentials") || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_eq "fail no-title" "$out" "a course page with no readable title is not verified"
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
  local log
  log=$(mktemp)
  assert_eq $'ok\thttps://developer.mozilla.org/en-US/docs/Web/HTTP' "$(FAKE_CURL_LOG=$log cl other-200 "https://developer.mozilla.org/en-US/docs/Web/HTTP")" "other URL ok"
  assert_contains "$(cat "$log")" "/dev/null" "any other page is not downloaded into memory"
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

# ---- lint-page: page kinds, length, boxes, concepts ----

test_lint_flags_too_long()       { _lint_expect too-long "bad-too-long.md:1: too-long 151 words, limit 150"; }
test_lint_flags_too_many_boxes() { _lint_expect too-many-boxes "bad-too-many-boxes.md:5: too-many-boxes 21 boxes, limit 20"; }
test_lint_flags_no_concepts()    { _lint_expect no-concepts "bad-no-concepts.md:1: no-concepts"; }
test_lint_flags_no_lessons() {
  local d f
  d=$(new_tmp); f="$d/architecture.md"
  arch() { printf '# Shop: architecture\n\n## Concepts\n\n%s\n' "$1" > "$f"; }
  arch 'no lesson here'
  assert_eq "$f:1: no-lessons" "$("$TOOLS" lint-page "$f")" "an architecture page must hold a lesson"
  arch '[docs](https://example.com/guide)'
  assert_eq "$f:1: no-lessons" "$("$TOOLS" lint-page "$f")" "official docs alone are not a lesson"
  arch '## Lessons'
  assert_eq "$f:1: no-lessons" "$("$TOOLS" lint-page "$f")" "an empty Lessons section is not a lesson"
  printf '# Shop: architecture\n\n## Concepts\n\n[v](https://www.youtube.com/watch?v=abcdefghijk)\n' > "$f"
  assert_eq "$f:1: no-lessons" "$("$TOOLS" lint-page "$f")" "the lesson must be under ## Lessons"
  local ok
  for ok in '[v](https://www.youtube.com/watch?v=abcdefghijk)' '[c](https://www.linkedin.com/learning/x)' 'No checked lesson yet'; do
    arch "$(printf '## Lessons\n\n%s' "$ok")"
    assert_eq "" "$("$TOOLS" lint-page "$f")" "passes with: $ok"
  done
  arch "$(printf '## Lessons\n\n## Not sure yet\n\n[v](https://youtu.be/abcdefghijk)')"
  assert_eq "$f:1: no-lessons" "$("$TOOLS" lint-page "$f")" "a link after the section ends does not count"
}
test_lint_instruction_file_is_not_a_run_record() {
  # AGENTS.md holds the block, which spells out "- **Asked:**": it must not be measured as a record
  local t i; t=$(new_tmp)
  { printf '# Project rules\n\n'; for i in $(seq 1 200); do printf 'word '; done; printf '\n\n'; "$TOOLS" block record; } > "$t/AGENTS.md"
  assert_eq "" "$("$TOOLS" lint-page "$t/AGENTS.md" | grep -e too-long -e no-concepts)" "an instruction file is never too-long"
}

test_lint_flags_backticks_inside_a_toggle() {
  # Obsidian shows backticks inside an HTML block as typed, so code in a toggle must be <code>
  local t; t=$(new_tmp)
  printf '# Note\n\n<details><summary>Why</summary>\n<p>Run `npm test` first.</p>\n</details>\n' > "$t/bad.md"
  printf '# Note\n\n<details><summary>Why</summary>\n<p>Run <code>npm test</code> first.</p>\n<pre><code>echo `date`</code></pre>\n</details>\n\nRun `npm test`.\n' > "$t/good.md"
  assert_eq "$t/bad.md:4: details-markdown" "$("$TOOLS" lint-page "$t/bad.md")" "backticks in a toggle are Markdown"
  printf '# Note\n\n<details><summary>Why `npm test` runs first</summary>\n<p>It is fast.</p>\n</details>\n' > "$t/summary.md"
  assert_eq "$t/summary.md:3: details-markdown" "$("$TOOLS" lint-page "$t/summary.md")" "backticks in a toggle title are Markdown too"
  assert_eq "" "$("$TOOLS" lint-page "$t/good.md")" "code tags, backticks inside pre, and backticks outside a toggle are fine"
}

test_lint_standard2_pair_and_short_page_pass() {
  assert_eq "" "$(lint example-issue-page.md example-issue-page-code.md short-issue-page.md)" "the three good pages are clean"
}
test_lint_flags_no_owner_block()   { _lint_expect no-owner-block "bad-no-owner-block.md:1: no-owner-block"; }
test_lint_flags_asked_too_long()   { _lint_expect asked-too-long "bad-asked-too-long.md:13: asked-too-long 31 words, limit 30"; }
test_lint_flags_link_undated()     { assert_contains "$(lint bad-link-undated.md)" ": link-undated" "a lesson link with no checked date"; }
test_lint_flags_no_code_page()     { _lint_expect no-code-page "bad-no-code-page.md:1: no-code-page"; }
test_lint_flags_no_design_idea()   { assert_contains "$(lint bad-no-design-idea.md)" ": no-design-idea" "every full page names its design idea"; }
test_lint_flags_idea_without_video() { assert_contains "$(lint bad-no-video.md)" ": no-video" "an idea with only a page to read"; }
test_lint_video_rule_accepts_and_rejects() {
  local t ok bad; t=$(new_tmp)
  ok='<p>Watch: <a href="https://www.linkedin.com/learning/system-design-basics/resumable-uploads">T</a> · A · content checked · checked 2026-11-26</p>'
  sed "s|<p>Watch:.*</p>|$ok|" "$FIX/pages/example-issue-page.md" > "$t/example-issue-page.md"
  cp "$FIX/pages/example-issue-page-code.md" "$t/"
  assert_eq "" "$("$TOOLS" lint-page "$t/example-issue-page.md")" "one LinkedIn Learning video inside a course counts"
  bad='<p>Course: <a href="https://www.linkedin.com/learning/system-design-basics">T</a> · A · checked 2026-11-26</p>'
  sed "s|<p>Watch:.*</p>|$bad|" "$FIX/pages/example-issue-page.md" > "$t/example-issue-page.md"
  assert_contains "$("$TOOLS" lint-page "$t/example-issue-page.md")" ": no-video" "a whole course is not a video"
  sed "s|<p>Watch:.*</p>|<p>No checked video yet</p>|" "$FIX/pages/example-issue-page.md" > "$t/example-issue-page.md"
  assert_eq "" "$("$TOOLS" lint-page "$t/example-issue-page.md")" "saying there is none yet is allowed"
}
test_lint_no_checked_page_is_not_a_video_fallback() {
  local t; t=$(new_tmp); cp "$FIX/pages/example-issue-page-code.md" "$t/"
  sed "s|<p>Read:.*</p>|<p>No checked page yet</p>|" "$FIX/pages/example-issue-page.md" > "$t/example-issue-page.md"
  assert_eq "" "$("$TOOLS" lint-page "$t/example-issue-page.md")" "no page to read, with a video, is clean"
  sed -e "s|<p>Read:.*</p>|<p>No checked page yet</p>|" -e "/<p>Watch:/d" "$FIX/pages/example-issue-page.md" > "$t/example-issue-page.md"
  assert_contains "$("$TOOLS" lint-page "$t/example-issue-page.md")" ": no-video" "the page fallback is not a video fallback"
}
test_lint_flags_code_page_sections() {
  local out; out=$(lint bad-code-page-sections-code.md)
  assert_contains "$out" "no-file-list" "file list required"; assert_contains "$out" "no-walkthrough" "walkthrough required"
}
test_lint_code_page_has_no_word_limit() {
  local t; t=$(new_tmp); : > "$t/SHOP-12-x.md"
  { printf '# SHOP-12: x, code\n\nCode for [SHOP-12: x](SHOP-12-x.md) · Standard: 2\n\n## Every changed file\n\n## Code walkthrough\n\n'; words 900; } > "$t/SHOP-12-x-code.md"
  assert_eq "" "$("$TOOLS" lint-page "$t/SHOP-12-x-code.md")" "900 words on a code page is fine"
}
test_lint_old_page_without_standard_is_unchanged() {
  local t; t=$(new_tmp); kind_page issue 300 > "$t/old.md"
  assert_eq "" "$("$TOOLS" lint-page "$t/old.md")" "an old page with no owner block and no answer still lints clean"
}

test_lint_counts_only_what_a_reader_sees() {
  local out rc=0
  # the same run record as bad-too-long.md less one word: exactly 150
  out=$(lint words-not-counted.md) || rc=$?
  assert_eq "" "$out" "folded text, code fences, <pre>, comments and link targets are not counted"
  assert_eq 0 "$rc" "exit 0"
}

words() { local i; for ((i = 1; i <= $1; i++)); do printf 'w%d ' "$i"; done; }   # N words on one line

# kind_page KIND N -> a page of that kind: its own few words, then N more
kind_page() {
  case $1 in
    run)       printf '# 2026-01-02: x\n\n- **Asked:** x\n\n' ;;                                    # 4 words
    issue)     printf '# K-1: x\n\nStatus: built\n\n## Concepts\n\n' ;;                              # 5
    feature)   printf '# Cart\n\npart of the [app map](app-map.md)\n\n## Concepts\n\n' ;;            # 7
    app)       printf '# Shop: app map\n\n## Concepts\n\n' ;;                                        # 4
    workspace) printf '# Shop: how the projects fit\n\n' ;;                                          # 5
    arch)      printf '# Shop: architecture\n\n## Concepts\n\n## Lessons\n\nNo checked lesson yet\n\n' ;;   # 8
    none)      printf '# Features\n\nStatus: done\n\n' ;;
  esac
  words "$2"; printf '\n'
}

test_lint_word_limit_follows_the_page_kind() {
  local d kind own limit f
  d=$(new_tmp); : > "$d/app-map.md"
  while read -r kind own limit; do
    f="$d/$kind.md"
    kind_page "$kind" $((limit - own)) > "$f"
    assert_eq "" "$("$TOOLS" lint-page "$f")" "$kind: $limit words pass"
    kind_page "$kind" $((limit - own + 1)) > "$f"
    assert_eq "$f:1: too-long $((limit + 1)) words, limit $limit" "$("$TOOLS" lint-page "$f")" "$kind: one word more is too long"
  done <<'EOF'
run 4 150
issue 5 400
feature 7 350
app 4 1100
workspace 5 1100
arch 8 900
EOF
}

test_lint_page_of_no_kind_is_never_too_long_or_without_concepts() {
  local d out rc=0
  d=$(new_tmp)
  kind_page none 3000 > "$d/README.md"
  out=$("$TOOLS" lint-page "$d/README.md") || rc=$?
  assert_eq "" "$out" "an index or a README has no word limit and needs no Concepts"
  assert_eq 0 "$rc" "exit 0"
}

test_lint_no_concepts_only_on_issue_app_and_feature_pages() {
  local d kind f
  d=$(new_tmp); : > "$d/app-map.md"
  for kind in issue feature app arch; do
    f="$d/$kind.md"
    kind_page "$kind" 10 | grep -v '^## Concepts$' > "$f"
    assert_eq "$f:1: no-concepts" "$("$TOOLS" lint-page "$f")" "$kind page without Concepts"
    kind_page "$kind" 10 | sed 's/^## Concepts$/## Concepts and more/' > "$f"
    assert_eq "$f:1: no-concepts" "$("$TOOLS" lint-page "$f")" "$kind page: the heading is exactly ## Concepts"
  done
  # first match wins: a run record that also has an issue status line is a run record
  f="$d/run.md"; printf '# 2026-01-02: x\n\nStatus: blocked\n\n- **Asked:** x\n' > "$f"
  assert_eq "" "$("$TOOLS" lint-page "$f")" "a run record needs no Concepts"
  kind_page workspace 10 > "$f"
  assert_eq "" "$("$TOOLS" lint-page "$f")" "a workspace map needs no Concepts"
}

# seq_page N -> a page with one sequenceDiagram of N participants
seq_page() {
  local i
  printf '# Flow\n\n```mermaid\nsequenceDiagram\n  autonumber\n  actor P1 as Person\n'
  for ((i = 2; i <= $1; i++)); do printf '  participant P%d as Part %d\n' "$i" "$i"; done
  printf '  P1->>P2: hello\n```\n'
}

test_lint_counts_sequence_participants() {
  local d
  d=$(new_tmp)
  seq_page 20 > "$d/p.md"
  assert_eq "" "$("$TOOLS" lint-page "$d/p.md")" "20 participants are fine"
  seq_page 21 > "$d/p.md"
  assert_eq "$d/p.md:3: too-many-boxes 21 boxes, limit 20" "$("$TOOLS" lint-page "$d/p.md")" "21 participants are reported on the opening fence"
}

test_lint_accepts_a_task_list_on_an_issue_page() {
  local d out rc=0
  d=$(new_tmp); : > "$d/app-map.md"
  printf '# K-1: x\n\nStatus: building\n\n## Steps\n\n- [x] A test that fails for the expired token\n- [ ] The cache refreshes early\n- [ ] The [app map](app-map.md) names the cache\n\n## Concepts\n\n- **Token:** a pass.\n' > "$d/K-1-x.md"
  out=$("$TOOLS" lint-page "$d/K-1-x.md") || rc=$?
  assert_eq "" "$out" "ticked and open boxes are fine"
  assert_eq 0 "$rc" "exit 0"
}

# ---- change-map ----

# cm_repo: a repo whose main has app/{a,b,c,d}, lib/x and a root file; on branch work it adds
# app/new (committed), changes app/a (uncommitted) and adds lib/x/u and README (untracked)
cm_repo() {
  local p f
  p=$(new_tmp); p=$(cd -P "$p" && pwd)/shop; mkdir -p "$p"
  g -C "$p" init -q -b main
  mkdir -p "$p/app/a" "$p/app/b" "$p/app/c" "$p/app/d" "$p/lib/x"
  for f in app/a/1 app/b/1 app/c/1 app/d/1 lib/x/1 top; do printf '1\n' > "$p/$f"; done
  g -C "$p" add -A; g -C "$p" commit -qm init; g -C "$p" switch -qc work
  mkdir -p "$p/app/new"; printf 'n\n' > "$p/app/new/f"; printf 'n\n' > "$p/app/new/g"
  g -C "$p" add -A; g -C "$p" commit -qm new
  printf '2\n' >> "$p/app/a/1"; printf 'u\n' > "$p/lib/x/u"; printf 'r\n' > "$p/README"
  printf '%s' "$p"
}

test_change_map_boxes_classes_and_counts() {
  local p out
  p=$(cm_repo)
  out=$(gt change-map --repo "$p" --base main)
  assert_contains "$out" $'```mermaid\nflowchart TB\n  subgraph r1["shop"]' "a fenced flowchart with one subgraph named after the folder"
  assert_contains "$out" $'    r1p1["app/new \xc2\xb7 2 files, 2 new"]' "the biggest part comes first, files counted"
  assert_contains "$out" '["app/a · 1 file"]' "one file is 1 file"
  assert_contains "$out" '["lib/x · 1 file, 1 new"]' "an added file in an old folder"
  assert_contains "$out" '    r1u["3 other folders unchanged"]' "app/b, app/c, app/d are untouched siblings"
  assert_contains "$out" '  class r1p1 new' "a folder that is all new is new"
  assert_contains "$out" "  class $(printf '%s\n' "$out" | sed -n 's/^ *\(r1p[0-9]*\)\["lib\/x .*/\1/p') changed" "an old folder with an added file is changed"
  assert_contains "$out" '  class r1u same' "the untouched box is grey"
  assert_contains "$out" '  classDef changed fill:#fde68a,stroke:#b45309' "classes are defined"
  assert_eq 'Green: new. Amber: changed. Grey: untouched. Arrows: add them by hand from the architecture.' "$(printf '%s\n' "$out" | tail -n 1)" "the legend follows the fence"
}

test_change_map_head_sees_commits_only() {
  local p out
  p=$(cm_repo)
  out=$(gt change-map --repo "$p" --base main --head HEAD)
  assert_contains "$out" '["app/new · 2 files, 2 new"]' "committed work is shown"
  [[ "$out" != *lib/x* && "$out" != *"(root)"* && "$out" != *app/a* ]] || _fail "untracked and uncommitted files are left out"
  assert_contains "$out" '["4 other folders unchanged"]' "siblings are read from REF"
  assert_exit 1 "a missing head exits 1" -- "$TOOLS" change-map --repo "$p" --base main --head nope
}

test_change_map_lints_clean_in_a_page() {
  local p d
  p=$(cm_repo); d=$(new_tmp)
  { printf '# What changed\n\n'; gt change-map --repo "$p" --base main; } > "$d/page.md"
  assert_eq "" "$("$TOOLS" lint-page "$d/page.md")" "the block passes lint-page"
}

test_change_map_reduces_depth_past_18_boxes() {
  local p i out
  p=$(new_tmp); p=$(cd -P "$p" && pwd)
  g -C "$p" init -q -b main; printf '1\n' > "$p/top"; g -C "$p" add -A; g -C "$p" commit -qm init
  for i in $(seq 1 20); do mkdir -p "$p/src/m$i"; printf 'x\n' > "$p/src/m$i/f"; done
  out=$(gt change-map --repo "$p" --base main)
  assert_contains "$out" '  %% depth reduced to 1 to stay under 18 boxes' "20 parts drop to depth 1"
  assert_contains "$out" '["src · 20 files, 20 new"]' "and fold into one box"
}

test_change_map_no_changes_and_errors() {
  local p
  p=$(new_tmp); p=$(cd -P "$p" && pwd)
  g -C "$p" init -q -b main; printf '1\n' > "$p/top"; g -C "$p" add -A; g -C "$p" commit -qm init
  assert_eq "no changes against main" "$(gt change-map --repo "$p")" "a clean branch says so"
  assert_exit 0 "and exits 0" -- "$TOOLS" change-map --repo "$p"
  assert_exit 1 "a missing base exits 1" -- "$TOOLS" change-map --repo "$p" --base nope
  assert_exit 1 "a folder that is not a repository exits 1" -- "$TOOLS" change-map --repo "$(new_tmp)"
}

# ---- snippet ----

sn_repo() {   # a repo named "web" with one file of 30 numbered lines and one with a space
  local p; p="$(new_tmp)/web"; mkdir -p "$p/src"
  g -C "$p" init -q -b main
  for i in $(seq 1 30); do echo "line $i"; done > "$p/src/total.ts"
  cp "$p/src/total.ts" "$p/src/my file.ts"
  g -C "$p" add -A; g -C "$p" commit -qm one; echo "$p"
}

test_snippet_prints_marker_fence_and_lines() {
  local p out rev; p=$(sn_repo); rev=$(g -C "$p" rev-parse --short=7 HEAD)
  out=$(gt snippet --repo "$p" src/total.ts 3 5)
  assert_contains "$out" "<!-- grasp:snippet repo=web file=\"src/total.ts\" lines=3-5 rev=$rev -->" "marker"
  assert_contains "$out" $'```ts\nline 3\nline 4\nline 5\n```' "fence holds exactly lines 3 to 5"
  [[ "$out" != *"]("* ]] || _fail "no link line without a remote"
}
test_snippet_handles_a_path_with_a_space() {
  local p; p=$(sn_repo)
  assert_contains "$(gt snippet --repo "$p" "src/my file.ts" 1 1)" 'file="src/my file.ts"' "path kept whole"
}
test_snippet_links_a_github_remote() {
  local p; p=$(sn_repo); g -C "$p" remote add origin git@github.com:acme/web.git
  assert_contains "$(gt snippet --repo "$p" src/total.ts 3 5)" "https://github.com/acme/web/blob/$(g -C "$p" rev-parse HEAD)/src/total.ts#L3-L5" "permalink"
}
test_snippet_rejects_bad_input() {
  local p; p=$(sn_repo)
  assert_exit 1 "range past the end" -- "$TOOLS" snippet --repo "$p" src/total.ts 29 40
  assert_exit 1 "missing file"      -- "$TOOLS" snippet --repo "$p" src/none.ts 1 2
  assert_exit 1 "unknown rev"       -- "$TOOLS" snippet --repo "$p" --rev nope src/total.ts 1 2
  assert_exit 2 "bad use"           -- "$TOOLS" snippet --repo "$p" src/total.ts 5
}
test_snippet_check_passes_then_reports_drift() {
  local p page; p=$(sn_repo); page="$(new_tmp)/SHOP-12-x-code.md"
  gt snippet --repo "$p" src/total.ts 3 5 > "$page"
  assert_eq "" "$(gt snippet-check --repo "$p" "$page")" "a pulled block is clean"
  sed -i.bak 's/^line 4$/line four/' "$page"
  assert_contains "$(gt snippet-check --repo "$p" "$page")" "snippet-drift src/total.ts 3-5" "an edited block is drift"
  assert_exit 1 "drift exits 1" -- "$TOOLS" snippet-check --repo "$p" "$page"
}
test_snippet_check_unreachable_unknown_and_unmarked() {
  local p page; p=$(sn_repo); page="$(new_tmp)/SHOP-12-x-code.md"
  gt snippet --repo "$p" src/total.ts 3 5 | sed 's/rev=[0-9a-f]*/rev=0000000/' > "$page"
  assert_contains "$(gt snippet-check --repo "$p" "$page")" "snippet-unreachable web@0000000" "missing commit is not drift"
  [[ "$(gt snippet-check --repo "$p" "$page")" != *snippet-drift* ]] || _fail "unreachable must not also say drift"
  assert_contains "$(gt snippet-check --repo "$(new_tmp)" "$page")" "snippet-unknown-repo web" "repo not given"
  printf '```ts\nretyped\n```\n\n```mermaid\nflowchart LR\n```\n' > "$page"
  assert_eq "$page:1: snippet-unmarked" "$(gt snippet-check --repo "$p" "$page")" "a retyped fence is flagged, a diagram is not"
}

# ---- coverage ----

cov_repo() {   # repo "web": main has a.ts; HEAD changes a.ts, adds "b c.ts" and deep/d.ts
  local p; p="$(new_tmp)/web"; mkdir -p "$p/deep"; g -C "$p" init -q -b main
  echo 1 > "$p/a.ts"; g -C "$p" add -A; g -C "$p" commit -qm base
  echo 2 > "$p/a.ts"; echo 1 > "$p/b c.ts"; echo 1 > "$p/deep/d.ts"
  g -C "$p" add -A; g -C "$p" commit -qm change; echo "$p"
}
test_coverage_all_named_across_two_pages() {
  local p t; p=$(cov_repo); t=$(new_tmp)
  printf '`a.ts` and <code>b c.ts</code>\n' > "$t/p.md"; printf '`deep/**`\n' > "$t/p-code.md"
  assert_eq "3 of 3 changed files named" "$(gt coverage --repo "$p" --base HEAD~1 --head HEAD "$t/p.md" "$t/p-code.md")" "page and sub-page are read together"
}
test_coverage_reports_missing_with_repo_prefix() {
  local p t out rc=0; p=$(cov_repo); t=$(new_tmp); printf '`a.ts`\n' > "$t/p.md"
  out=$(gt coverage --repo "$p" --base HEAD~1 --head HEAD "$t/p.md") || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_contains "$out" "MISSING web/b c.ts" "a path with a space is reported whole"
  assert_contains "$out" "MISSING web/deep/d.ts" "second missing file"
  assert_contains "$out" "1 of 3 changed files named" "count"
}
test_coverage_reads_the_range_from_the_page() {
  local p t b h; p=$(cov_repo); t=$(new_tmp)
  b=$(g -C "$p" rev-parse --short=7 HEAD~1); h=$(g -C "$p" rev-parse --short=7 HEAD)
  printf 'Checked against: `web@%s..%s` on 2026-11-26\n\n`web/a.ts` `web/b c.ts` `web/deep/d.ts`\n' "$b" "$h" > "$t/p.md"
  assert_eq "3 of 3 changed files named" "$(gt coverage --repo "$p" "$t/p.md")" "REPO/path form and page range"
}
test_coverage_stale_and_usage() {
  local p t; p=$(cov_repo); t=$(new_tmp)
  printf '`a.ts` `b c.ts` `deep/**`\n\n| File | Does |\n| --- | --- |\n| `src/gone.ts` | x |\n' > "$t/p.md"
  assert_contains "$(gt coverage --repo "$p" --base HEAD~1 --head HEAD "$t/p.md")" "STALE src/gone.ts" "a named file that does not exist"
  printf 'no range here\n' > "$t/q.md"
  assert_exit 2 "no range anywhere" -- "$TOOLS" coverage --repo "$p" "$t/q.md"
}

test_coverage_without_head_sees_the_working_tree() {
  local p t out rc=0; p=$(cov_repo); t=$(new_tmp); printf '`x.ts`\n' > "$t/p.md"
  echo 3 > "$p/a.ts"; echo 1 > "$p/new file.ts"
  out=$(gt coverage --repo "$p" --base HEAD "$t/p.md") || rc=$?
  assert_eq 1 "$rc" "uncommitted work is checked, exit 1"
  assert_contains "$out" "MISSING web/a.ts" "an edited file"
  assert_contains "$out" "MISSING web/new file.ts" "an untracked file"
  rc=0; out=$(gt coverage --repo "$p" --base HEAD --head HEAD "$t/p.md") || rc=$?
  assert_eq "0 of 0 changed files named" "$out" "with --head only commits count"
  assert_eq 0 "$rc" "and exits 0"
}

test_coverage_page_with_no_code_spans_names_nothing() {
  local p t out rc=0; p=$(cov_repo); t=$(new_tmp); printf 'only prose, no code spans\n' > "$t/p.md"
  out=$(gt coverage --repo "$p" --base HEAD~1 --head HEAD "$t/p.md") || rc=$?
  assert_eq 1 "$rc" "exit 1"
  assert_contains "$out" "MISSING web/a.ts" "first file"
  assert_contains "$out" "MISSING web/b c.ts" "second file"
  assert_contains "$out" "MISSING web/deep/d.ts" "third file"
  assert_contains "$out" "0 of 3 changed files named" "count"
}

# ---- page template ----

TEMPLATE="$ROOT/skills/grasp/templates/issue-page.md"

test_example_page_lints_clean() {
  assert_exit 0 "example page lints clean" -- "$TOOLS" lint-page "$FIX/pages/example-issue-page.md"
}

test_template_has_sections() {
  local body sec
  body=$(cat "$TEMPLATE")
  for sec in "In two sentences" "For the owner" "Where it fits" "Ideas this leans on" "How it works" "Steps" "Predict" "More detail"; do
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
  for sec in "In two sentences" "For the owner" "Where it fits" "Ideas this leans on" "How it works" "More detail"; do
    assert_contains "$body" "## $sec" "example has section $sec"
  done
}

# ---- run records: the block in AGENTS.md / CLAUDE.md ----

RECORD_MARKER='<!-- grasp:start b=1 v=0.5.0 step=record dir=docs/how-it-works/runs -->'

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
  assert_contains "$(cat "$p/.grasp.md")" "| AGENTS.md | record | 0.5.0 |" "row recorded"
  assert_eq $'AGENTS.md\trecord\tok' "$(gt --config "$p/.grasp.md" status)" "status ok"
}

test_record_block_asks_for_a_small_flowchart() {
  local p want
  p=$(new_project)
  want=$(mktemp)
  cat > "$want" <<'EOF'
- **Next:** what a person should do or decide next, or "nothing".
Under them, when the change has a shape (steps, or parts that connect), add one small Mermaid
`flowchart` of it: at most 10 boxes, every label in double quotes.
Write only what happened: never claim a change or a check you did not make. No secrets, tokens,
env values or raw command output. Skip it for questions and for runs that changed no files.
With the grasp skill installed, `/grasp record` writes it and rebuilds the index.
<!-- grasp:end -->
EOF
  gt --config "$p/.grasp.md" block record | tail -n 7 > "$p/tail.txt"
  assert_file_eq "$want" "$p/tail.txt" "the end of the record block"
}

test_record_block_from_0_3_0_is_stale() {
  local p
  p=$(new_project)
  cat > "$p/AGENTS.md" <<'EOF'
<!-- grasp:start b=1 v=0.3.0 step=record dir=docs/how-it-works/runs -->
## Run records (grasp)
Before your final message on any task that changed files in this project, write one run record:
`docs/how-it-works/runs/YYYY-MM-DD-short-name.md`. It is part of the task, also when you were told to change only
certain files. One file per task; the same task continued updates its file.
Start it with `# YYYY-MM-DD: short name` and `Status: done` (or `partial`, `blocked`, `failed`), then
exactly these five lines, one short plain sentence each:
- **Asked:** the request.
- **Changed:** what behaves differently now.
- **Checked:** the command you ran and its result line, or "not checked".
- **Problems:** what failed, was worked around or is uncertain, or "none".
- **Next:** what a person should do or decide next, or "nothing".
Write only what happened: never claim a change or a check you did not make. No secrets, tokens,
env values or raw command output. Skip it for questions and for runs that changed no files.
With the grasp skill installed, `/grasp record` writes it, adds a diagram and rebuilds the index.
<!-- grasp:end -->
EOF
  printf '\n## Connected skills\n\n| skill | step | grasp version |\n| ----- | ---- | ------------- |\n| AGENTS.md | record | 0.3.0 |\n' >> "$p/.grasp.md"
  assert_eq $'AGENTS.md\trecord\tstale' "$(gt --config "$p/.grasp.md" status)" "the block an 0.3.0 install wrote is stale, with the same b= number"
  assert_eq "refreshed AGENTS.md record" "$(gt --config "$p/.grasp.md" refresh)" "refresh rewrites it"
  assert_contains "$(cat "$p/AGENTS.md")" "at most 10 boxes" "the new wording is in"
  assert_eq $'AGENTS.md\trecord\tok' "$(gt --config "$p/.grasp.md" status)" "ok after refresh"
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
  assert_eq '<!-- grasp:start b=1 v=0.5.0 step=record dir=../docs/how-it-works/runs -->' "$(head -n 1 "$p/AGENTS.md")" "marker holds the configured folder"
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
  assert_eq '<!-- grasp:start b=1 v=0.5.0 step=record dir=notes/runs -->' "$(head -n 1 "$p/AGENTS.md")" "trailing slash and spaces dropped"
}

test_connect_import_makes_claude_md_load_agents_md() {
  local p want
  p=$(new_project)
  assert_eq "connected CLAUDE.md import" "$(gt --config "$p/.grasp.md" connect CLAUDE.md import)" "connect prints confirmation"
  want=$(mktemp); printf '<!-- grasp:start b=1 v=0.5.0 step=import -->\n@AGENTS.md\n<!-- grasp:end -->\n' > "$want"
  assert_file_eq "$want" "$p/CLAUDE.md" "a missing CLAUDE.md is created with only the import"
  gt --config "$p/.grasp.md" connect CLAUDE.md import >/dev/null
  assert_file_eq "$want" "$p/CLAUDE.md" "second connect changes nothing"
  assert_eq $'CLAUDE.md\timport\tok' "$(gt --config "$p/.grasp.md" status)" "status lists it"
  printf '# My rules\n\nUse tabs.\n' > "$p/CLAUDE.md"
  gt --config "$p/.grasp.md" connect CLAUDE.md import >/dev/null
  assert_eq "$(printf '# My rules\n\nUse tabs.\n\n<!-- grasp:start b=1 v=0.5.0 step=import -->\n@AGENTS.md\n<!-- grasp:end -->')" "$(cat "$p/CLAUDE.md")" "an existing CLAUDE.md keeps its text"
  gt --config "$p/.grasp.md" disconnect CLAUDE.md >/dev/null
  assert_eq "$(printf '# My rules\n\nUse tabs.')" "$(cat "$p/CLAUDE.md")" "disconnect restores it"
}

test_block_with_old_text_is_stale() {
  local p
  p=$(new_project)
  gt --config "$p/.grasp.md" connect AGENTS.md record >/dev/null
  gt --config "$p/.grasp.md" connect .claude/skills/plain work >/dev/null
  sed -i.bak 's/one short plain sentence each/one sentence each/' "$p/AGENTS.md"
  sed -i.bak 's/grasp:start b=1 v=0.5.0 step=work/grasp:start b=1 v=0.2.0 step=work/' "$p/.claude/skills/plain/SKILL.md"
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
  printf '# Rules\n\n<!-- grasp:start b=1 v=0.5.0 step=record dir=x -->\nmine\n' > "$p/AGENTS.md"
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

test_record_check_hook_reads_the_codex_stop_payload() {
  # the fields Codex documents for a Stop hook; the config is found from a sub-folder the way the
  # documented Codex command does it, with git rev-parse --show-toplevel
  local p t rc=0 err
  p=$(new_repo); t=$(new_tmp); mkdir -p "$p/src/deep"
  printf 'two\n' >> "$p/src/app.txt"
  err=$(cd "$p/src/deep" && printf '{"session_id":"019a-cx","transcript_path":"/x/rollout.jsonl","cwd":"%s","hook_event_name":"Stop","model":"gpt-5","turn_id":"t1","stop_hook_active":false,"last_assistant_message":"Done."}' "$p/src/deep" |
        TMPDIR=$t "$TOOLS" --config "$(git rev-parse --show-toplevel)/.grasp.md" record-check --hook 2>&1 >/dev/null) || rc=$?
  assert_eq 2 "$rc" "exit 2 with the Codex payload"
  assert_contains "$err" "no run record in docs/how-it-works/runs" "reason on stderr, the continuation Codex shows the model"
  rc=0
  (cd "$p/src/deep" && printf '{"session_id":"019a-cx","hook_event_name":"Stop","turn_id":"t2","stop_hook_active":true,"last_assistant_message":"Done."}' |
        TMPDIR=$t "$TOOLS" --config "$(git rev-parse --show-toplevel)/.grasp.md" record-check --hook >/dev/null 2>&1) || rc=$?
  assert_eq 0 "$rc" "the turn Codex already continued is let through"
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

test_projects_finds_a_repository_deeper_than_three_folders() {
  local t
  t=$(new_tmp)
  mkdir -p "$t/a/b/c/d/deep/.git" "$t/a/b/c/d/pkg"
  printf '{}' > "$t/a/b/c/d/pkg/package.json"
  assert_eq "$(printf 'a/b/c/d/deep\trepo\t.git')" "$(gt projects "$t")" "a repository five folders down is listed; a package that deep is not"
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
  for t in run-record app-map architecture feature-page workspace-map issue-page issue-code-page; do
    rc=0
    # the notes above "---" count as words of the page here, so its length is checked below
    out=$("$TOOLS" lint-page "$ROOT/skills/grasp/templates/$t.md" | grep -v -e ': dead-link ' -e ': hard-wrap$' -e ': too-long ') || true
    assert_eq "" "$out" "$t template: toggles and diagrams lint clean"
  done
  # the page parts, laid out as a notebook, have no dead links either, are within their kind's
  # word limit and have their Concepts section
  d=$(new_tmp); mkdir -p "$d/features" "$d/runs"
  page_of app-map > "$d/app-map.md"; page_of workspace-map > "$d/workspace-map.md"
  page_of feature-page > "$d/features/some-feature.md"; page_of run-record > "$d/runs/2026-01-02-x.md"
  page_of issue-page > "$d/features/KEY-1-some-issue.md"; page_of architecture > "$d/architecture.md"
  printf '# Features\n' > "$d/features/README.md"; printf '# Run records\n' > "$d/runs/README.md"
  out=$("$TOOLS" lint-page "$d/app-map.md" "$d/architecture.md" "$d/workspace-map.md" "$d/features/some-feature.md" "$d/features/KEY-1-some-issue.md" "$d/runs/2026-01-02-x.md") || rc=$?
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

test_install_project_without_dir_prints_usage() {
  local out rc=0
  out=$("$ROOT/install.sh" --project 2>&1) || rc=$?
  assert_eq 2 "$rc" "--project with no DIR exits 2"
  assert_contains "$out" "Usage:" "--project with no DIR prints usage"
}

test_install_copy_writes_source() {
  local p
  p=$(new_tmp)
  "$ROOT/install.sh" --project "$p" --copy >/dev/null
  assert_eq "$ROOT" "$(cat "$p/.claude/skills/grasp/.source" 2>/dev/null)" ".source holds the repo path (.claude)"
  assert_eq "$ROOT" "$(cat "$p/.agents/skills/grasp/.source" 2>/dev/null)" ".source holds the repo path (.agents)"
  assert_eq "0.5.0" "$("$p/.claude/skills/grasp/bin/grasp-tools" version)" "copied grasp-tools runs"
}

test_install_copy_twice_recopies() {
  local p
  p=$(new_tmp)
  "$ROOT/install.sh" --project "$p" --copy >/dev/null
  printf '0.0.1\n' > "$p/.claude/skills/grasp/VERSION"
  "$ROOT/install.sh" --project "$p" --copy >/dev/null 2>&1
  assert_eq "0.5.0" "$(cat "$p/.claude/skills/grasp/VERSION")" "second --copy replaces grasp's own copy"
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
  assert_eq "0.5.0" "$("$p/.claude/skills/grasp/bin/grasp-tools" version)" "grasp-tools runs through the symlink"
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

# ---- keep-walk ----

walk_page() {   # walk_page FILE WALKFIELD BODY
  printf '# SHOP-12: x\n\nStatus: built · Standard: 2 · Feature: none · Walk: %s · [issue](u)\n\ntext\n\n<!-- grasp:walk:start -->\n%s\n<!-- grasp:walk:end -->\n\ntail\n' "$2" "$3" > "$1"
}
test_keep_walk_copies_block_and_field() {
  local t; t=$(new_tmp)
  walk_page "$t/old.md" "walked 2026-11-27, 5 of 6 right" "<details><summary>Your walk</summary><p>You: my words</p></details>"
  walk_page "$t/new.md" "not walked" "<details><summary>Your walk: not done yet</summary></details>"
  assert_eq "kept" "$(gt keep-walk "$t/old.md" "$t/new.md")" "says kept"
  assert_contains "$(cat "$t/new.md")" "<p>You: my words</p>" "answers carried over"
  assert_contains "$(cat "$t/new.md")" "Walk: walked 2026-11-27, 5 of 6 right ·" "field carried over"
  assert_contains "$(cat "$t/new.md")" $'\ntail' "the rest of the new page is kept"
}
test_keep_walk_refuses_when_new_has_no_markers() {
  local t before; t=$(new_tmp)
  walk_page "$t/old.md" "walked 2026-11-27, 1 of 1 right" "<details><summary>Your walk</summary><p>You: a</p></details>"
  printf '# SHOP-12: x\n\nStatus: built · Standard: 2 · Walk: not walked\n' > "$t/new.md"; before=$(cat "$t/new.md")
  assert_exit 1 "refuses" -- "$TOOLS" keep-walk "$t/old.md" "$t/new.md"
  assert_eq "$before" "$(cat "$t/new.md")" "the new page is untouched"
}
test_keep_walk_with_nothing_to_keep() {
  local t; t=$(new_tmp); printf '# old\n' > "$t/old.md"
  walk_page "$t/new.md" "not walked" "<details><summary>Your walk: not done yet</summary></details>"
  assert_eq "no walk to keep" "$(gt keep-walk "$t/old.md" "$t/new.md")" "an old page with no walk is fine"
}

test_keep_walk_refuses_when_new_has_no_walk_field() {
  local t before; t=$(new_tmp)
  walk_page "$t/old.md" "walked 2026-11-27, 1 of 1 right" "<details><summary>Your walk</summary><p>You: a</p></details>"
  printf '# SHOP-12: x\n\nStatus: built · Standard: 2\n\n<!-- grasp:walk:start -->\n<details>e</details>\n<!-- grasp:walk:end -->\n' > "$t/new.md"; before=$(cat "$t/new.md")
  assert_exit 1 "refuses" -- "$TOOLS" keep-walk "$t/old.md" "$t/new.md"
  assert_eq "$before" "$(cat "$t/new.md")" "the new page is untouched"
}
test_keep_walk_carries_hostile_answer_bytes() {
  local t line; t=$(new_tmp)
  line='<p><b>You:</b> &amp; \ | / \1 \n s/x/y/g & $(touch "'$t'/PWNED") %s %d `a` `b`</p>'
  walk_page "$t/old.md" "walked 2026-11-27, 1 of 1 right" "$line"
  walk_page "$t/new.md" "not walked" "<details>empty</details>"
  assert_eq "kept" "$(gt keep-walk "$t/old.md" "$t/new.md")" "says kept"
  grep -qxF -- "$line" "$t/new.md" || _fail "the answer line arrives byte for byte"
  [[ ! -e "$t/PWNED" ]] || _fail "nothing in the answer was run"
}
test_keep_walk_refuses_an_unclosed_block_in_old() {
  local t before; t=$(new_tmp)
  printf '# SHOP-12: x\n\nStatus: built · Walk: walked 2026-11-27, 1 of 1 right\n\n<!-- grasp:walk:start -->\nmy words\n' > "$t/old.md"
  walk_page "$t/new.md" "not walked" "<details>empty</details>"; before=$(cat "$t/new.md")
  assert_exit 1 "refuses" -- "$TOOLS" keep-walk "$t/old.md" "$t/new.md"
  assert_eq "$before" "$(cat "$t/new.md")" "the new page is untouched"
}
# ---- sync ----

sync_fix() {   # docs with a clean standard 2 pair for SHOP-12 on repo "web"; echoes "DOCS WEB"
  local t d p b h; t=$(new_tmp); d="$t/docs/how-it-works"; p=$(cov_repo); mkdir -p "$d/features"
  b=$(g -C "$p" rev-parse --short=7 HEAD~1); h=$(g -C "$p" rev-parse --short=7 HEAD)
  sed -e "s/^Checked against:.*/Checked against: \`web@$b..$h\` on 2026-11-20/" -e 's/example-issue-page-code\.md/SHOP-12-x-code.md/g' \
    "$FIX/pages/example-issue-page.md" > "$d/features/SHOP-12-x.md"
  { printf '# SHOP-12: x, code\n\nCode for [SHOP-12: x](SHOP-12-x.md) · Standard: 2\n\n## Every changed file\n\n| File | What it does in this change |\n| --- | --- |\n| `a.ts` | x |\n| `b c.ts` | x |\n| `deep/d.ts` | x |\n\n## Code walkthrough\n\n'
    gt snippet --repo "$p" --rev "$h" a.ts 1 1; } > "$d/features/SHOP-12-x-code.md"
  echo "$d $p"
}
row() { awk -F'\t' -v k="$1" '$1 == k' <<<"$2"; }

test_sync_clean_page_is_not_walked_only() {
  local d p out; read -r d p <<<"$(sync_fix)"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_eq "not-walked" "$(row SHOP-12 "$out" | cut -f2)" "a clean, unwalked page"
}
test_sync_old_page_is_below_standard_with_reason() {
  local d p out; read -r d p <<<"$(sync_fix)"
  kind_page issue 20 | sed 's/^# K-1: x/# SHOP-9: old/' > "$d/features/SHOP-9-old.md"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-9 "$out")" "below-standard" "old page reported"
  assert_contains "$(row SHOP-9 "$out")" "no Standard field" "the reason is named"
}
test_sync_reports_missing_and_stale_from_files() {
  local d p t out cur; read -r d p <<<"$(sync_fix)"; t=$(new_tmp)
  echo 3 > "$p/a.ts"; g -C "$p" commit -qam "code after the pin"; cur=$(g -C "$p" rev-parse --short=7 HEAD)
  printf 'SHOP-12\nSHOP-13\n' > "$t/keys"; printf 'SHOP-12\tweb\t%s\n' "$cur" > "$t/heads"
  out=$(gt sync --docs "$d" --repo "$p" --keys "$t/keys" --heads "$t/heads" --no-write 2>/dev/null)
  assert_eq "missing" "$(row SHOP-13 "$out" | cut -f2)" "a key with no page"
  assert_contains "$(row SHOP-12 "$out" | cut -f2)" "stale" "code changed after the pin"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "web: a.ts changed after the pin" "detail"
}
test_sync_page_only_commit_is_not_stale() {   # the notebook lives inside the code repository
  local p d b h t out cur; p=$(cov_repo); d="$p/docs/how-it-works"; mkdir -p "$d/features"; t=$(new_tmp)
  b=$(g -C "$p" rev-parse --short=7 HEAD~1); h=$(g -C "$p" rev-parse --short=7 HEAD)
  sed -e "s/^Checked against:.*/Checked against: \`web@$b..$h\` on 2026-11-20/" -e 's/example-issue-page-code\.md/SHOP-12-x-code.md/g' \
    "$FIX/pages/example-issue-page.md" > "$d/features/SHOP-12-x.md"
  printf '# SHOP-12: x, code\n\nCode for [SHOP-12: x](SHOP-12-x.md) · Standard: 2\n\n## Every changed file\n\n| File | What it does in this change |\n| --- | --- |\n| `a.ts` | x |\n| `b c.ts` | x |\n| `deep/d.ts` | x |\n\n## Code walkthrough\n\n' > "$d/features/SHOP-12-x-code.md"
  g -C "$p" add -A; g -C "$p" commit -qm "docs: the page"; cur=$(g -C "$p" rev-parse --short=7 HEAD)
  printf 'SHOP-12\tweb\t%s\n' "$cur" > "$t/heads"
  out=$(gt sync --docs "$d" --repo "$p" --heads "$t/heads" --no-write 2>/dev/null)
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *stale* ]] || _fail "the page's own commit must not make it stale"
}
test_sync_unreachable_head_is_not_stale() {
  local d p t out; read -r d p <<<"$(sync_fix)"; t=$(new_tmp)
  printf 'SHOP-12\tweb\tfffffff\n' > "$t/heads"
  out=$(gt sync --docs "$d" --repo "$p" --heads "$t/heads" --no-write 2>/dev/null)
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *stale* ]] || _fail "a head that is not in the clone proves nothing"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "unreachable web@fffffff" "but it is said"
}
test_sync_says_what_it_could_not_check() {
  local d p err; read -r d p <<<"$(sync_fix)"
  err=$(gt sync --docs "$d" --repo "$p" --no-write 2>&1 >/dev/null)
  assert_contains "$err" "note: missing not checked (no --keys)" "keys note"
  assert_contains "$err" "note: issue pages not checked for stale (no --heads)" "heads note"
  assert_exit 0 "still exits 0" -- "$TOOLS" sync --docs "$d" --repo "$p" --no-write
}
test_sync_unreachable_commit_is_not_below_standard() {
  local d p out; read -r d p <<<"$(sync_fix)"
  sed -i.bak 's/rev=[0-9a-f]*/rev=0000000/' "$d/features/SHOP-12-x-code.md"; rm "$d/features/SHOP-12-x-code.md.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *below-standard* ]] || _fail "an unfetched commit must not fail the page"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "unreachable web@0000000" "but it is said"
}
test_sync_drift_and_uncovered_file_are_below_standard() {
  local d p out; read -r d p <<<"$(sync_fix)"
  sed -i.bak 's/| `deep\/d.ts` | x |//' "$d/features/SHOP-12-x-code.md"; rm "$d/features/SHOP-12-x-code.md.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "coverage: MISSING web/deep/d.ts" "an unnamed file"
}
test_sync_uncommitted_page_is_not_pinned() {
  local d p out; read -r d p <<<"$(sync_fix)"
  sed -i.bak 's/\(Checked against: `web@[0-9a-f]*\.\.\)[0-9a-f]*/\1uncommitted/' "$d/features/SHOP-12-x.md"; rm "$d/features/SHOP-12-x.md.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f2)" "below-standard" "an unpinned page is below standard"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "not pinned to a commit" "and says why"
  assert_exit 0 "and sync does not fail" -- "$TOOLS" sync --docs "$d" --repo "$p" --no-write
}
test_sync_missing_sub_page_is_below_standard() {
  local d p out; read -r d p <<<"$(sync_fix)"
  mv "$d/features/SHOP-12-x-code.md" "$d/features/other-code.md"
  sed -i.bak 's/SHOP-12-x-code\.md/other-code.md/g' "$d/features/SHOP-12-x.md"; rm "$d/features/SHOP-12-x.md.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "no code sub-page" "a sub-page under another name does not count"
}
test_sync_writes_generated_lists_and_keeps_other_text() {
  local d p; read -r d p <<<"$(sync_fix)"
  printf '# Features\n\nhand written\n' > "$d/features/README.md"
  gt sync --docs "$d" --repo "$p" >/dev/null 2>&1
  assert_contains "$(cat "$d/features/README.md")" "hand written" "existing text kept"
  assert_contains "$(cat "$d/features/README.md")" "<!-- grasp:issues:start -->" "block added"
  assert_contains "$(cat "$d/features/README.md")" "| [SHOP-12" "the issue is listed"
  gt sync --docs "$d" --repo "$p" >/dev/null 2>&1
  assert_eq 1 "$(grep -c 'grasp:issues:start' "$d/features/README.md")" "running twice adds one block"
}
test_sync_only_limits_rows_and_writes_nothing() {
  local d p out; read -r d p <<<"$(sync_fix)"
  out=$(gt sync --docs "$d" --repo "$p" --only SHOP-12 2>/dev/null)
  assert_eq 1 "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" "one row"
  [[ ! -f "$d/features/README.md" ]] || _fail "--only must not write lists"
}
test_sync_changed_since_names_the_later_issue() {
  local d p f out; read -r d p <<<"$(sync_fix)"; f="$d/features"
  sed -e 's/^# SHOP-12: .*/# SHOP-14: y/' -e 's/ on 2026-11-20$/ on 2026-11-25/' -e 's/SHOP-12-x-code\.md/SHOP-14-y-code.md/g' \
    "$f/SHOP-12-x.md" > "$f/SHOP-14-y.md"
  sed -e 's/SHOP-12: x/SHOP-14: y/g' -e 's/SHOP-12-x\.md/SHOP-14-y.md/g' "$f/SHOP-12-x-code.md" > "$f/SHOP-14-y-code.md"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f2)" "changed-since" "the older page is changed since"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "SHOP-14" "by the later issue"
  [[ "$(row SHOP-14 "$out" | cut -f2)" != *changed-since* ]] || _fail "the later page is not changed since"
  gt sync --docs "$d" --repo "$p" >/dev/null 2>&1; gt sync --docs "$d" --repo "$p" >/dev/null 2>&1
  assert_eq 1 "$(grep -cxF 'Changed since by: [SHOP-14](SHOP-14-y.md)' "$f/SHOP-12-x.md")" "the line is written once"
  assert_eq 0 "$(grep -c '^Changed since by:' "$f/SHOP-14-y.md")" "the later page gets no line"
  sed 's/^Checked against: .*/&, `api@1111111..2222222`/' "$f/SHOP-12-x.md" > "$f/long.md"
  [[ "$(gt lint-page "$f/long.md")" != *hard-wrap* ]] || _fail "the line under a long Checked against line is not a wrap"
}
test_sync_lists_design_idea_and_counts_missing_videos() {
  local d p out; read -r d p <<<"$(sync_fix)"
  gt sync --docs "$d" --repo "$p" >/dev/null 2>&1
  assert_contains "$(sed -n '/grasp:issues:start/,/grasp:issues:end/p' "$d/features/README.md")" "| Resumable upload |" "the design idea is listed"
  sed -i.bak 's#^<p>Watch:.*#<p>No checked video yet</p>#' "$d/features/SHOP-12-x.md"; rm "$d/features/SHOP-12-x.md.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "1 ideas without a video" "an idea with no video is counted"
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *below-standard* ]] || _fail "a missing video is not below standard"
}
test_sync_counts_ideas_without_a_page() {
  local d p out; read -r d p <<<"$(sync_fix)"
  sed -i.bak 's#^<p>Read:.*#<p>No checked page yet</p>#' "$d/features/SHOP-12-x.md"; rm "$d/features/SHOP-12-x.md.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "1 ideas without a page" "an idea with no page to read is counted"
  [[ "$(row SHOP-12 "$out" | cut -f4)" != *"without a video"* ]] || _fail "a missing page is not a missing video"
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *below-standard* ]] || _fail "a missing page is not below standard"
}
test_sync_bad_link_only_with_links() {
  local d p out; read -r d p <<<"$(sync_fix)"
  out=$(GRASP_CURL="$FIX/fake-curl" FAKE_CURL_CASE=yt-400 gt sync --docs "$d" --repo "$p" --links --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f2)" "bad-link" "a failing lesson link"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "https://www.youtube.com/watch?v=aBcDeFgHiJk&t=95s" "the address"
  out=$(GRASP_CURL="$FIX/fake-curl" FAKE_CURL_CASE=yt-400 gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *bad-link* ]] || _fail "links are checked only with --links"
}

test_lint_generated_issue_list_is_not_counted() {
  local d f i; d=$(new_tmp); : > "$d/app-map.md"; : > "$d/SHOP-12-x.md"; f="$d/cart.md"   # 350 words with "## Issues"
  { kind_page feature 342; printf '\n## Issues\n\n<!-- grasp:issues:start -->\n| Issue | Design idea | State | Walk | Checked |\n| --- | --- | --- | --- | --- |\n'
    for i in $(seq 1 40); do printf '| [SHOP-12: a long issue title here](SHOP-12-x.md) | Resumable upload | not-walked | not walked | 2026-11-20 |\n'; done
    printf '<!-- grasp:issues:end -->\n'; } > "$f"
  assert_eq "" "$(gt lint-page "$f")" "a generated list does not count toward the word limit"
  sed -i.bak 's#(SHOP-12-x.md) | Resumable#(SHOP-99-gone.md) | Resumable#' "$f"; rm "$f.bak"
  assert_contains "$(gt lint-page "$f")" "dead-link SHOP-99-gone.md" "a dead link in the list is still reported"
}
test_sync_absent_repo_skips_stale_keeps_missing() {
  local d p out; read -r d p <<<"$(sync_fix)"
  sed -i.bak 's#^Checked against: \(.*\) on#Checked against: \1, `api@1111111..2222222` on#' "$d/features/SHOP-12-x.md"; rm "$d/features/SHOP-12-x.md.bak"
  printf '| `api/src/gone.ts` | x |\n' >> "$d/features/SHOP-12-x-code.md"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *below-standard* ]] || _fail "a path of the absent repository is not STALE"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "coverage partly checked: api not given" "said"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "api not given" "a repository not given is named as such"
  [[ "$(row SHOP-12 "$out" | cut -f4)" != *"unreachable api@"* ]] || _fail "a repository not given is not called unreachable"
  sed -i.bak 's/| `deep\/d.ts` | x |//' "$d/features/SHOP-12-x-code.md"; rm "$d/features/SHOP-12-x-code.md.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "coverage: MISSING web/deep/d.ts" "MISSING still counts for the given repository"
}
test_sync_no_repo_of_the_page_given() {
  local d p o out; read -r d p <<<"$(sync_fix)"; o="$(new_tmp)/shop"; mkdir -p "$o"; g -C "$o" init -q
  out=$(gt sync --docs "$d" --repo "$o" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "coverage partly checked: web not given" "said with no repository of the page given"
  [[ "$(row SHOP-12 "$out" | cut -f4)" != *"unreachable web@"* ]] || _fail "not called unreachable"
}
test_sync_changed_since_line_never_makes_a_page_too_long() {
  local d p f n; read -r d p <<<"$(sync_fix)"; f="$d/features"
  sed -e 's/^# SHOP-12: .*/# SHOP-14: y/' -e 's/ on 2026-11-20$/ on 2026-11-25/' -e 's/SHOP-12-x-code\.md/SHOP-14-y-code.md/g' \
    "$f/SHOP-12-x.md" > "$f/SHOP-14-y.md"
  sed -e 's/SHOP-12: x/SHOP-14: y/g' -e 's/SHOP-12-x\.md/SHOP-14-y.md/g' "$f/SHOP-12-x-code.md" > "$f/SHOP-14-y-code.md"
  cp "$f/SHOP-12-x.md" "$f/probe.md"; { printf '\n'; words 1000; printf '\n'; } >> "$f/probe.md"
  n=$(gt lint-page "$f/probe.md" | sed -n 's/.*too-long \([0-9]*\) words.*/\1/p'); rm "$f/probe.md"
  { printf '\n'; words $((400 - (n - 1000))); printf '\n'; } >> "$f/SHOP-12-x.md"
  [[ "$(row SHOP-12 "$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)" | cut -f2)" != *below-standard* ]] || _fail "the page starts at its limit, clean"
  gt sync --docs "$d" --repo "$p" >/dev/null 2>&1
  grep -q '^Changed since by:' "$f/SHOP-12-x.md" || _fail "the line was written"
  [[ "$(row SHOP-12 "$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)" | cut -f2)" != *below-standard* ]] || _fail "the line sync wrote does not make the page too long"
}
test_sync_coverage_that_cannot_run_is_not_clean() {
  local d p out; read -r d p <<<"$(sync_fix)"
  g -C "$p" tag v1 HEAD~1; g -C "$p" tag v2 HEAD
  sed -i.bak 's/^Checked against: .* on/Checked against: `web@v1..v2` on/' "$d/features/SHOP-12-x.md"; rm "$d/features/SHOP-12-x.md.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f2)" "below-standard" "a range coverage cannot read is not proven"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "coverage could not run: " "and says so"
}
test_sync_refuses_a_walk_inside_the_issues_block() {
  local d p f err; read -r d p <<<"$(sync_fix)"; f="$d/features/cart.md"; : > "$d/app-map.md"
  printf '# Cart

part of the [app map](../app-map.md)

## Concepts

x

<!-- grasp:issues:start -->
old
<!-- grasp:walk:start -->
<details><summary>Your walk</summary><p>You: mine</p></details>
<!-- grasp:walk:end -->
<!-- grasp:issues:end -->
' > "$f"
  cp "$f" "$f.want"
  err=$(gt sync --docs "$d" --repo "$p" 2>&1 >/dev/null)
  assert_file_eq "$f.want" "$f" "the page is left byte for byte"
  assert_contains "$err" "$f" "a note names the file"
}
test_sync_ignores_issues_markers_in_a_fence() {
  local d p f; read -r d p <<<"$(sync_fix)"; f="$d/features/README.md"
  printf '# Features

```
<!-- grasp:issues:start -->
example
<!-- grasp:issues:end -->
```
' > "$f"
  gt sync --docs "$d" --repo "$p" >/dev/null 2>&1; gt sync --docs "$d" --repo "$p" >/dev/null 2>&1
  assert_eq "example" "$(sed -n 5p "$f")" "the fenced example is kept"
  assert_eq 2 "$(grep -c 'grasp:issues:start' "$f")" "the real block is appended once"
  assert_contains "$(cat "$f")" "| [SHOP-12" "the real block holds the issue"
}
test_sync_snippet_drift_is_below_standard() {
  local d p out c; read -r d p <<<"$(sync_fix)"; c="$d/features/SHOP-12-x-code.md"
  sed -i.bak '/^```ts$/{n;s/.*/9/;}' "$c"; rm "$c.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f2)" "below-standard" "an edited fence"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "snippet-drift a.ts 1-1" "named"
}

# ---- fix wave: reports that can be wrong ----

test_lint_before_half_page_needs_no_code_page() {
  local t; t=$(new_tmp)
  sed -e 's/^Status: built/Status: planned/' -e '/^\[The code, file by file\]/d' -e '/^Checked against:/d' \
    "$FIX/pages/example-issue-page.md" > "$t/SHOP-12-x.md"
  assert_eq "" "$("$TOOLS" lint-page "$t/SHOP-12-x.md")" "a planned page has no code page yet"
  sed 's/^Status: planned/Status: building/' "$t/SHOP-12-x.md" > "$t/SHOP-13-x.md"
  assert_eq "" "$("$TOOLS" lint-page "$t/SHOP-13-x.md")" "nor a page being built"
  sed 's/^Status: planned/Status: built/' "$t/SHOP-12-x.md" > "$t/SHOP-14-x.md"
  assert_contains "$("$TOOLS" lint-page "$t/SHOP-14-x.md")" ": no-code-page" "a built page still needs it"
}
test_sync_before_half_page_is_not_built_yet() {
  local d p t out; read -r d p <<<"$(sync_fix)"; t=$(new_tmp)
  rm "$d/features/SHOP-12-x-code.md"
  sed -e 's/^Status: built/Status: building/' -e '/^\[The code, file by file\]/d' -e '/^Checked against:/d' \
    "$d/features/SHOP-12-x.md" > "$t/p" && cat "$t/p" > "$d/features/SHOP-12-x.md"
  echo 3 > "$p/a.ts"; g -C "$p" commit -qam later; printf 'SHOP-12\tweb\t%s\n' "$(g -C "$p" rev-parse --short=7 HEAD)" > "$t/heads"
  out=$(gt sync --docs "$d" --repo "$p" --heads "$t/heads" --no-write 2>/dev/null)
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *below-standard* ]] || _fail "a page before its build is not below standard: $(row SHOP-12 "$out")"
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *stale* ]] || _fail "nor stale"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "not built yet" "and says why"
}

# merge_pr P: on a branch from P's HEAD, one Markdown-only commit; on main, someone else's z.ts;
# then a true merge of the branch into main. Prints the merge commit.
merge_pr() {
  local p=$1
  g -C "$p" switch -qc pr; echo n > "$p/notes.md"; g -C "$p" add -A; g -C "$p" commit -qm notes
  g -C "$p" switch -q main; echo z > "$p/z.ts"; g -C "$p" add -A; g -C "$p" commit -qm other
  g -C "$p" merge -q --no-ff -m merge pr; g -C "$p" rev-parse --short=7 HEAD
}
test_sync_merge_commit_reads_the_pull_request_side() {
  local d p t out; read -r d p <<<"$(sync_fix)"; t=$(new_tmp)
  printf 'SHOP-12\tweb\t%s\n' "$(merge_pr "$p")" > "$t/heads"
  out=$(gt sync --docs "$d" --repo "$p" --heads "$t/heads" --no-write 2>/dev/null)
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *stale* ]] || _fail "a change on the base branch brought in by the merge is not this page's: $(row SHOP-12 "$out")"
}
test_sync_markdown_outside_the_notebook_is_not_stale() {
  local d p t out; read -r d p <<<"$(sync_fix)"; t=$(new_tmp)
  mkdir -p "$p/docs"; echo r > "$p/docs/README.md"; echo a > "$p/AGENTS.md"; echo c > "$p/.grasp.md"
  g -C "$p" add -A; g -C "$p" commit -qm "docs: router"
  printf 'SHOP-12\tweb\t%s\n' "$(g -C "$p" rev-parse --short=7 HEAD)" > "$t/heads"
  out=$(gt sync --docs "$d" --repo "$p" --heads "$t/heads" --no-write 2>/dev/null)
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *stale* ]] || _fail "the router, AGENTS.md and .grasp.md do not make a page stale"
  mkdir -p "$p/src"; echo x > "$p/src/x.ts"; g -C "$p" add -A; g -C "$p" commit -qm code
  printf 'SHOP-12\tweb\t%s\n' "$(g -C "$p" rev-parse --short=7 HEAD)" > "$t/heads"
  out=$(gt sync --docs "$d" --repo "$p" --heads "$t/heads" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "web: src/x.ts changed after the pin" "code outside the range still does"
}
test_sync_empty_range_proves_nothing() {
  local d p h out; read -r d p <<<"$(sync_fix)"; h=$(g -C "$p" rev-parse --short=7 HEAD)
  sed -i.bak "s/^Checked against: .* on/Checked against: \`web@$h..$h\` on/" "$d/features/SHOP-12-x.md"; rm "$d/features/SHOP-12-x.md.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f2)" "below-standard" "0 of 0 proves nothing on a full page"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "coverage: nothing changed in the range" "and says so"
}
test_sync_checked_against_with_no_range() {
  local d p out; read -r d p <<<"$(sync_fix)"
  sed -i.bak 's/^Checked against: `\([^`]*\)`/Checked against: \1/' "$d/features/SHOP-12-x.md"; rm "$d/features/SHOP-12-x.md.bak"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f2)" "below-standard" "a range sync cannot read"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "no range on the Checked against line" "is named"
}
test_repo_name_is_the_main_checkout_in_a_worktree() {
  local p w t b h; p=$(cov_repo); w="$(new_tmp)/wt-web"; t=$(new_tmp)
  g -C "$p" worktree add -q -b wt "$w" 2>/dev/null
  b=$(g -C "$p" rev-parse --short=7 HEAD~1); h=$(g -C "$p" rev-parse --short=7 HEAD)
  assert_contains "$(gt snippet --repo "$w" a.ts 1 1)" "repo=web " "snippet names the main checkout's folder"
  gt snippet --repo "$w" a.ts 1 1 > "$t/x-code.md"
  assert_eq "" "$(gt snippet-check --repo "$p" "$t/x-code.md")" "and the main checkout reads it back"
  printf 'Checked against: `web@%s..%s` on 2026-11-26\n\n`a.ts` `b c.ts` `deep/d.ts`\n' "$b" "$h" > "$t/p.md"
  assert_eq "3 of 3 changed files named" "$(gt coverage --repo "$w" "$t/p.md")" "coverage in the worktree reads web's range"
  assert_contains "$(gt change-map --repo "$w" --base HEAD~1)" 'subgraph r1["web"]' "change-map names it the same way"
}
test_coverage_counts_a_shared_path_per_repository() {
  local t r out rc=0; t=$(new_tmp)
  for r in web api; do
    mkdir -p "$t/$r"; g -C "$t/$r" init -q -b main; echo 1 > "$t/$r/package.json"; g -C "$t/$r" add -A; g -C "$t/$r" commit -qm base
    echo 2 > "$t/$r/package.json"; g -C "$t/$r" commit -qam change
  done
  printf '`package.json`\n' > "$t/p.md"
  out=$(gt coverage --repo "$t/web" --repo "$t/api" --base HEAD~1 --head HEAD "$t/p.md") || rc=$?
  assert_eq 1 "$rc" "a bare path changed in two repositories names neither"
  assert_contains "$out" "MISSING web/package.json" "web's"
  assert_contains "$out" "MISSING api/package.json" "api's"
  printf '`web/package.json` `api/package.json`\n' > "$t/p.md"
  assert_eq "2 of 2 changed files named" "$(gt coverage --repo "$t/web" --repo "$t/api" --base HEAD~1 --head HEAD "$t/p.md")" "REPO/path names each"
}
test_sync_changed_since_follows_commit_order() {
  local d p f c1 c2 out; read -r d p <<<"$(sync_fix)"; f="$d/features"
  c1=$(g -C "$p" rev-parse --short=7 HEAD); echo 9 > "$p/a.ts"
  GIT_COMMITTER_DATE="2030-01-01T00:00:00" g -C "$p" commit -qam later; c2=$(g -C "$p" rev-parse --short=7 HEAD)
  sed -e 's/^# SHOP-12: .*/# SHOP-14: y/' -e "s/^Checked against: .*/Checked against: \`web@$c1..$c2\` on 2026-11-20/" \
    -e 's/SHOP-12-x-code\.md/SHOP-14-y-code.md/g' "$f/SHOP-12-x.md" > "$f/SHOP-14-y.md"
  sed -e 's/SHOP-12: x/SHOP-14: y/g' -e 's/SHOP-12-x\.md/SHOP-14-y.md/g' "$f/SHOP-12-x-code.md" > "$f/SHOP-14-y-code.md"
  sed -i.bak 's/ on 2026-11-20$/ on 2026-11-25/' "$f/SHOP-12-x.md"; rm "$f/SHOP-12-x.md.bak"   # re-dated by a repair
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "SHOP-14" "the page pinned to the older commit is changed since"
  [[ "$(row SHOP-14 "$out" | cut -f2)" != *changed-since* ]] || _fail "the newer commit's page is not changed since by the older"
}
test_sync_keys_match_title_or_file_name() {
  local d p t out; read -r d p <<<"$(sync_fix)"; t=$(new_tmp)
  assert_eq 1 "$(gt sync --docs "$d" --repo "$p" --only shop-12 2>/dev/null | wc -l | tr -d ' ')" "case does not matter"
  assert_contains "$(gt sync --docs "$d" --repo "$p" --only SHOP-12-x 2>/dev/null)" "SHOP-12" "the file name works"
  sed 's/^# SHOP-12: .*/# Checkout: how the setup works/' "$d/features/SHOP-12-x.md" > "$d/checkout-setup.md"
  assert_contains "$(gt sync --docs "$d" --repo "$p" --only checkout-setup 2>/dev/null)" $'Checkout\t' "an explain page by its file name, printed by its title key"
  sed 's/^# SHOP-12: .*/# #42: a thing/' "$d/features/SHOP-12-x.md" > "$d/42-a-thing.md"
  printf 'owner/shop#42\n#42\nSHOP-1\n' > "$t/keys"
  out=$(gt sync --docs "$d" --repo "$p" --keys "$t/keys" --no-write 2>/dev/null)
  [[ "$out" != *$'owner/shop#42\tmissing'* && "$out" != *$'#42\tmissing'* ]] || _fail "#42 and owner/shop#42 find the page: $out"
  assert_contains "$out" $'SHOP-1\tmissing' "SHOP-1 is not SHOP-12"
}
test_sync_reports_an_old_explain_pair() {
  local d p out; read -r d p <<<"$(sync_fix)"
  printf '# Checkout setup\n\n> [!NOTE]\n> Status: built\n' > "$d/checkout.md"; printf '# Checkout setup: files\n' > "$d/checkout-files.md"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  assert_contains "$(row checkout "$out" | cut -f2)" "below-standard" "an old explain page is reported"
  assert_contains "$(row checkout "$out" | cut -f4)" "old explain page (checkout-files.md)" "and named"
  [[ -z "$(row checkout-files "$out")" ]] || _fail "its file list gets no row of its own"
}
test_sync_link_timeout_is_not_a_bad_link() {
  local d p out; read -r d p <<<"$(sync_fix)"
  out=$(GRASP_CURL="$FIX/fake-curl" FAKE_CURL_CASE=timeout gt sync --docs "$d" --repo "$p" --links --no-write 2>/dev/null)
  [[ "$(row SHOP-12 "$out" | cut -f2)" != *bad-link* ]] || _fail "a timeout proves nothing about the link"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "link not checked: timeout https://www.youtube.com/watch?v=aBcDeFgHiJk&t=95s" "said"
}
test_sync_never_reads_a_run_record_as_an_issue_page() {
  local d p out; read -r d p <<<"$(sync_fix)"
  mkdir -p "$d/old" "$d/features/runs"
  printf '# 2026-11-20: shop fix\n\nStatus: blocked\n\n- **Asked:** fix it.\n' > "$d/old/2026-11-20-shop-fix.md"
  printf '# SHOP-77: x\n\nStatus: built\n' > "$d/features/runs/SHOP-77-x.md"
  out=$(gt sync --docs "$d" --repo "$p" --no-write 2>/dev/null)
  [[ "$out" != *2026-11-20* ]] || _fail "a blocked run record is not an issue page: $out"
  [[ "$out" != *SHOP-77* ]] || _fail "a runs folder anywhere is left out"
}
test_lint_video_forms() {
  local t; t=$(new_tmp); cp "$FIX/pages/example-issue-page-code.md" "$t/"
  sed 's|https://www.youtube.com/watch?v=aBcDeFgHiJk&t=95s|https://www.linkedin.com/learning/paths/become-a-dev|' \
    "$FIX/pages/example-issue-page.md" > "$t/example-issue-page.md"
  assert_contains "$("$TOOLS" lint-page "$t/example-issue-page.md")" ": no-video" "a learning path is not a video"
  for u in https://www.youtube.com/live/aBcDeFgHiJk https://www.youtube.com/shorts/aBcDeFgHiJk; do
    sed "s|https://www.youtube.com/watch?v=aBcDeFgHiJk&t=95s|$u|" "$FIX/pages/example-issue-page.md" > "$t/example-issue-page.md"
    assert_eq "" "$("$TOOLS" lint-page "$t/example-issue-page.md")" "$u is a video"
  done
}
test_keep_walk_notes_an_old_explain_back_answer() {
  local t err; t=$(new_tmp)
  printf '# SHOP-12: x\n\nStatus: built\n\n## Explain it back\n\n1. Why pieces?\n   - Your answer: so one failure resends one piece\n' > "$t/old.md"
  walk_page "$t/new.md" "not walked" "<details>empty</details>"
  err=$(gt keep-walk "$t/old.md" "$t/new.md" 2>&1 >/dev/null)
  assert_contains "$err" "note: $t/old.md has an explain-back answer; carry it into the walk fold" "noted with no walk to keep"
  assert_exit 0 "exit unchanged" -- "$TOOLS" keep-walk "$t/old.md" "$t/new.md"
  { cat "$t/old.md"; printf '\n<!-- grasp:walk:start -->\n<p>w</p>\n<!-- grasp:walk:end -->\n'; } > "$t/old2.md"
  sed -i.bak 's/^Status: built$/Status: built · Walk: walked 2026-11-27, 1 of 1 right/' "$t/old2.md"
  err=$(gt keep-walk "$t/old2.md" "$t/new.md" 2>&1 >/dev/null)
  assert_contains "$err" "has an explain-back answer" "noted when a walk is kept too"
  for a in pending skipped '`skipped`' 'not asked (no person in the run)' ''; do
    printf '# SHOP-12: x\n\n## Explain it back\n\n1. Why?\n   - Your answer: %s\n' "$a" > "$t/old.md"
    [[ -z "$(gt keep-walk "$t/old.md" "$t/new.md" 2>&1 >/dev/null)" ]] || _fail "no note for: '$a'"
  done
}

test_sync_on_a_mixed_notebook_exits_0_and_settles() {
  local d p f sum1 sum2 sum0; read -r d p <<<"$(sync_fix)"; f="$d/features"; : > "$d/app-map.md"
  sed -e 's/^# SHOP-12: .*/# SHOP-14: y/' -e 's/^Status: built/Status: planned/' -e '/^Checked against:/d' -e '/^\[The code, file by file\]/d' \
    "$f/SHOP-12-x.md" > "$f/SHOP-14-y.md"
  printf '# Checkout setup\n\n> [!NOTE]\n> Status: built\n' > "$d/checkout.md"; printf '# files\n' > "$d/checkout-files.md"
  mkdir -p "$d/old"; printf '# 2026-11-20: x\n\nStatus: blocked\n\n- **Asked:** x\n' > "$d/old/2026-11-20-x.md"
  sed 's/^# SHOP-12: .*/# #42: a thing/' "$f/SHOP-12-x.md" > "$d/42-a-thing.md"
  printf '# Cart\n\nVerified at `0000000`, 2026-11-20 · Walk: not walked · part of the [app map](../app-map.md)\n\n## Concepts\n\nx\n' > "$f/cart.md"
  sum0=$(cd "$d" && find . -type f | LC_ALL=C sort | xargs cksum)
  assert_exit 0 "--no-write exits 0" -- "$TOOLS" sync --docs "$d" --repo "$p" --no-write
  assert_exit 0 "--only exits 0" -- "$TOOLS" sync --docs "$d" --repo "$p" --only checkout
  assert_eq "$sum0" "$(cd "$d" && find . -type f | LC_ALL=C sort | xargs cksum)" "--no-write and --only write nothing"
  assert_exit 0 "a writing run exits 0" -- "$TOOLS" sync --docs "$d" --repo "$p"
  sum1=$(cd "$d" && find . -type f | LC_ALL=C sort | xargs cksum)
  gt sync --docs "$d" --repo "$p" >/dev/null 2>&1
  sum2=$(cd "$d" && find . -type f | LC_ALL=C sort | xargs cksum)
  assert_eq "$sum1" "$sum2" "a second run changes nothing"
}

run_tests "${1:-.}"
