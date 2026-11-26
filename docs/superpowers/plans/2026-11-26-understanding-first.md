# Understanding First Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** grasp 0.5.0 writes one issue page to a single standard with a code sub-page, proves every changed file and every code block, and adds `explain`, `walk`, `sync` and `repair`.

**Architecture:** Everything a script can decide lives in `skills/grasp/bin/grasp-tools` (bash and awk, tested in `tests/grasp-tools.sh`): pulling code, coverage, link checks, lint, page states, generated lists, keeping a walk. Everything that needs judgement lives in Markdown references the agent reads, pinned by string assertions in `tests/skill-docs.sh`. Pages carry their own state in two fixed lines so the helper can read it without a database.

**Tech Stack:** bash 3.2 compatible, awk, git, curl (stubbed by `tests/fixtures/fake-curl`), Markdown, Mermaid.

**Spec:** [docs/superpowers/specs/2026-11-26-understanding-first-design.md](../specs/2026-11-26-understanding-first-design.md). Covers build steps 1 to 5 of the spec. Step 6 (adoption in a project) is a later plan.

## Global Constraints

- Work on branch `feat/understanding-first`. Commit locally. Never push, never merge to `main`: that is the owner's call.
- Commit subjects follow the repository: `feat:`, `fix:`, `docs:`, `test:`, lowercase, no scope, no body, no `Co-Authored-By` or any tool attribution.
- No new runtime dependency. `grasp-tools` stays bash with `set -u`, `LC_ALL=C`, and must run on macOS bash 3.2 (no associative arrays, no `mapfile`).
- Tests never touch the network: curl goes through `GRASP_CURL="$FIX/fake-curl"`.
- Pages render in Obsidian and VitePress: no Markdown, code fence or Mermaid inside `<details>`; no wikilinks; no fold inside a fold.
- The visible word limit of an issue page stays 400. The target written in instructions is 300.
- A page with no walk is never a lint failure.
- No secrets, tokens, env values or raw command output on any page or fixture.
- Never name a real project, card or person in this repository. Fixtures use `SHOP-12` and a shop.
- `help` lists every subcommand, and `argument-hint`, the help block and the usage lines agree (`tests/skill-docs.sh` enforces it).
- Suites: `tests/grasp-tools.sh` (now `139 passed, 0 failed`) and `tests/skill-docs.sh` (now `15 passed, 0 failed`). Both must end with `0 failed` after every task.

## Fixed formats (every task uses these exactly)

Issue page, first two lines after the title, each its own paragraph:

```
Status: built · Standard: 2 · Feature: [Checkout](checkout.md) · Walk: not walked · [issue](URL) · [pull request](URL)

Checked against: `web@1a2b3c4..5d6e7f8`, `api@9a8b7c6..0f1e2d3` on 2026-11-26
```

- `Standard: 2 short` marks the short form. `Feature: none` when there is no feature page.
- `Walk:` is `not walked`, `partly walked N of M`, or `walked YYYY-MM-DD, N of M right`.
- `REPO@BASE..HEAD`: `REPO` is the basename of the repository folder, `BASE` and `HEAD` are commits.
- `sync` owns one optional line directly under `Checked against:`, in the same paragraph: `Changed since by: [SHOP-14](SHOP-14-y.md), [SHOP-15](SHOP-15-z.md)`. No writer and no person edits it.

Issue page headings, in order: `## In two sentences`, `## For the owner`, `## Where it fits`, `## Ideas this leans on`, `## How it works`, `## More detail`. The owner block is five list lines starting `- **Asked:**`, `- **Users can now:**`, `- **Risk:**`, `- **Not done:**`, `- **Needs a decision:**`. Under `## More detail` are five `<details>` blocks whose `<summary>` starts with `Why it was built this way`, `Planned and built`, `Proof it works`, `Open and not verified`, `Your walk`.

Ideas, under `## Ideas this leans on`. The first is always the design idea (an architecture pattern or system design concept); the rest start `- **Idea · `:

```html
- **Design · Resumable upload:** a big file goes up in pieces, so one failure resends a piece.
<details><summary>Resumable upload: how it works here, and where to learn it</summary>
<p>Three to five lines tied to this code.</p>
<p>Watch: <a href="https://www.youtube.com/watch?v=ID&t=95s">TITLE</a> · CHANNEL · 12 min · content checked · checked 2026-11-26</p>
<p>Read: <a href="URL">TITLE</a> · SITE · checked 2026-11-26</p>
</details>
```

- A video is one YouTube video (`youtube.com/watch?v=` or `youtu.be/`) or one LinkedIn Learning video (`linkedin.com/learning/COURSE/VIDEO`, two path parts). A course address (`linkedin.com/learning/COURSE`) is not a video; it may follow on a `Course:` line.
- The confirmation words are exactly `content checked` or `title match only`.
- With no video that passes: `<p>No checked video yet</p>`. With lessons switched off (`--lessons none`): `<p>Lessons turned off</p>`.

Code sub-page: same basename plus `-code.md`. Third line `Code for [SHOP-12: name](SHOP-12-name.md) · Standard: 2`. Headings `## Every changed file` and `## Code walkthrough`.

Markers:

```
<!-- grasp:snippet repo=web file="src/cart/total.ts" lines=10-24 rev=5d6e7f8 -->
<!-- grasp:walk:start -->  ...  <!-- grasp:walk:end -->
<!-- grasp:issues:start -->  ...  <!-- grasp:issues:end -->
```

Constant in `grasp-tools`: `PAGE_STANDARD=2`.

## Review Focus

1. **A page a person edited, or an old page with no `Standard:` or `Checked against:` line.** `sync` must report it `below-standard` with the missing field named, never crash or skip it. Test in Task 9.
2. **A recorded commit that is not in the local clone** (a squash merge dropped it, or it was never fetched). `snippet-check` and `sync` must say `unreachable` and must not call the code drifted. Tests in Tasks 1 and 9.
3. **File paths with spaces.** `snippet`, `snippet-check` and `coverage` must handle `src/my file.ts`. Tests in Tasks 1 and 2.
4. **A rewritten page that lost its walk markers.** `keep-walk` must refuse and leave the new file untouched, so answers are never dropped silently. Test in Task 8.
5. **The tracker or the pull request host cannot be read.** `sync` with no `--keys` or `--heads` must still report the other states and say which check was skipped. Test in Task 9.

## File Structure

| File | Responsibility |
| --- | --- |
| `skills/grasp/bin/grasp-tools` | New commands `snippet`, `snippet-check`, `coverage`, `keep-walk`, `sync`; changed `check-link`, `lint-page`, `block_text`, `usage` |
| `skills/grasp/templates/issue-page.md` | Rewritten to standard 2 |
| `skills/grasp/templates/issue-code-page.md` | New: the code sub-page |
| `skills/grasp/templates/feature-page.md` | `## Changes` becomes the generated `## Issues` block |
| `skills/grasp/templates/grasp-config.md` | New `## Reader` and `## Features` sections, `sync scope`, `other records` |
| `skills/grasp/references/notebook.md` | Page shapes, the writer's inputs, snapshot rule, ideas and lessons |
| `skills/grasp/references/walk.md` | New: the walk |
| `skills/grasp/references/upkeep.md` | New: `sync` and `repair` |
| `skills/grasp/references/explain.md` | New: `explain` |
| `skills/grasp/references/{build,verify,understand,setup,overview,records}.md` | Small edits named in the tasks |
| `skills/grasp/SKILL.md` | Arguments, help, workflow steps 6 and 7, four new subcommand sections |
| `tests/grasp-tools.sh`, `tests/skill-docs.sh`, `tests/fixtures/**` | Tests and fixtures |
| `skills/grasp/VERSION`, `.claude-plugin/plugin.json`, `README.md`, `AGENTS.md`, `.grasp.md` | 0.5.0 |

---

### Task 1: `snippet` and `snippet-check`

**Files:**
- Modify: `skills/grasp/bin/grasp-tools` (new `cmd_snippet`, `cmd_snippet_check`, two lines in `usage()`, two in the dispatch `case`)
- Test: `tests/grasp-tools.sh`

**Interfaces:**
- Produces: `grasp-tools snippet [--repo DIR] [--rev REV] FILE START END`. Prints the marker line, a fence whose language is the file extension, the lines `START..END` of `FILE` at `REV` (default `HEAD`, resolved to a 7 character commit), and, when `origin` is a GitHub or GitLab address, one link line `[FILE lines A-B at REV](https://HOST/ORG/REPO/blob/FULLSHA/FILE#LA-LB)`. Exit 1 with a message on a missing file, an unknown rev or a range past the end; exit 2 on bad use.
- Produces: `grasp-tools snippet-check [--repo DIR]... PAGE`. For every marker it compares the fence under it with `git show REV:FILE`. Findings in lint format: `PAGE:LINE: snippet-drift FILE A-B`, `PAGE:LINE: snippet-unreachable REPO@REV`, `PAGE:LINE: snippet-unknown-repo REPO`, and, on a page whose name ends in `-code.md`, `PAGE:LINE: snippet-unmarked` for a non-Mermaid fence with no marker above it. `REPO` is matched to the basename of each `--repo` (default `.`). Exit 1 when anything is reported.

- [ ] **Step 1: Commit what is already written, on a new branch**

```bash
git switch -c feat/understanding-first
git add docs/research docs/superpowers/specs docs/superpowers/plans docs/how-it-works/runs
git commit -m "docs: design and plan for the page standard, walk, sync and repair"
```

- [ ] **Step 2: Write the failing tests**

```bash
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
```

- [ ] **Step 3: Run them and see them fail**

Run: `tests/grasp-tools.sh snippet`
Expected: every `test_snippet_*` prints `FAIL`, the summary ends `6 failed`.

- [ ] **Step 4: Implement `cmd_snippet` and `cmd_snippet_check`**

Read file content with `git -C REPO show "REV:FILE"`, never from the working tree. Compare fence bodies byte for byte after stripping one trailing newline. Add both to `usage()` and to the dispatch `case`.

- [ ] **Step 5: Run the whole suite**

Run: `tests/grasp-tools.sh`
Expected: `145 passed, 0 failed`. `test_help_lists_all_commands` has a fixed command list: add `snippet` and `snippet-check` to it.

- [ ] **Step 6: Commit**

```bash
git add skills/grasp/bin/grasp-tools tests/grasp-tools.sh
git commit -m "feat: pull code onto a page by command and check it still matches"
```

---

### Task 2: `coverage`

**Files:**
- Modify: `skills/grasp/bin/grasp-tools` (new `cmd_coverage`, `usage()`, dispatch)
- Test: `tests/grasp-tools.sh`

**Interfaces:**
- Consumes: the `Checked against:` line format from "Fixed formats".
- Produces: `grasp-tools coverage [--repo DIR]... [--base REF] [--head REF] PAGE...`. The changed files are `git diff --name-only --no-renames BASE HEAD` in each repo. With no `--base`, the range of each repo is read from the `Checked against:` line of the first `PAGE`. A file counts as named when any `PAGE` holds it in backticks or `<code>`, as `path`, as `REPO/path`, or under a named `folder/**`. Output: `MISSING REPO/path` per unnamed file, `STALE path` for a path in the first column of a table on a page that is neither changed nor present in any repo, then `N of M changed files named`. Exit 0 all named, 1 on any MISSING or STALE, 2 on bad use, a git error, or no range to read.

This is a port of `scripts/coverage` in the explain-build skill (`~/.claude/skills/explain-build/scripts/coverage`, Python). Read it first; keep its behaviour for one repo and one page. grasp keeps its own copy from here on: do not call that script, and do not name that skill in a comment (Task 7b tests for it).

- [ ] **Step 1: Write the failing tests**

```bash
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
```

- [ ] **Step 2: Run them and see them fail**

Run: `tests/grasp-tools.sh coverage`
Expected: `4 failed`.

- [ ] **Step 3: Implement `cmd_coverage`**

Use `git diff -z` and read names with `while IFS= read -r -d ''` so spaces survive. STALE only considers strings that look like a path with a folder and an extension, as the Python does.

- [ ] **Step 4: Run the whole suite**

Run: `tests/grasp-tools.sh`
Expected: `149 passed, 0 failed` (add `coverage` to the fixed command list).

- [ ] **Step 5: Commit**

```bash
git add skills/grasp/bin/grasp-tools tests/grasp-tools.sh
git commit -m "feat: prove every changed file is named on a page"
```

---

### Task 3: `check-link` accepts a LinkedIn Learning address only when it is the final one

**Files:**
- Modify: `skills/grasp/bin/grasp-tools:683-710`
- Modify: `tests/fixtures/fake-curl` (new cases `li-same`, `li-video-bounced`, `li-query`)
- Test: `tests/grasp-tools.sh` (`test_linkedin_redirect_prints_final_url_and_title` changes)

**Interfaces:**
- Produces: for a LinkedIn Learning address, `fail redirected FINAL` (exit 1) when the final address differs from the requested one. Both are compared after dropping `?query`, `#fragment` and a trailing `/`. Everything else in `check-link` is unchanged.

- [ ] **Step 1: Add the fake-curl cases**

`li-same`: the `li-redirect` body with final `https://www.linkedin.com/learning/oauth-2-0-essentials`. `li-video-bounced`: same body and same final address (the caller asks for a video under that course). `li-query`: same body, final `https://www.linkedin.com/learning/oauth-2-0-essentials?u=0`.

- [ ] **Step 2: Write the failing tests**

```bash
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
```

Change the existing `test_linkedin_redirect_prints_final_url_and_title`: rename it `test_linkedin_renamed_course_fails_redirected`, expect exit 1 and `fail redirected https://www.linkedin.com/learning/oauth-2-0-essentials`, and keep its two log assertions (`-L`, not `/dev/null`).

- [ ] **Step 3: Run, see 4 fail, implement, run the whole suite**

Run: `tests/grasp-tools.sh linkedin` then `tests/grasp-tools.sh`
Expected after the change: `152 passed, 0 failed`.

- [ ] **Step 4: Commit**

```bash
git add skills/grasp/bin/grasp-tools tests/grasp-tools.sh tests/fixtures/fake-curl
git commit -m "fix: a LinkedIn Learning link that redirects is not a checked link"
```

---

### Task 4: Standard 2 templates and lint

**Files:**
- Rewrite: `skills/grasp/templates/issue-page.md`
- Create: `skills/grasp/templates/issue-code-page.md`
- Modify: `skills/grasp/bin/grasp-tools:826-1040` (`cmd_lint_page`)
- Modify: `tests/fixtures/pages/example-issue-page.md` (to standard 2); create `example-issue-page-code.md`, `short-issue-page.md`, `bad-no-owner-block.md`, `bad-asked-too-long.md`, `bad-link-undated.md`, `bad-no-code-page.md`, `bad-no-design-idea.md`, `bad-no-video.md`, `bad-code-page-sections-code.md`; delete `bad-no-answer.md`
- Test: `tests/grasp-tools.sh`

**Interfaces:**
- Consumes: "Fixed formats".
- Produces: lint rules that apply only when the status line holds `Standard: 2`:

| Finding | When |
| --- | --- |
| `no-owner-block` | `## For the owner` is missing, or one of its five labelled lines is. Reported at line 1. |
| `asked-too-long N words, limit 30` | The `- **Asked:**` line has more than 30 words after the label. |
| `link-undated` | A line holds a `youtube.com`, `youtu.be` or `linkedin.com/learning` address and no `checked 20NN-NN-NN`. |
| `no-design-idea` | A page that is not `short` has no line starting `- **Design · ` under `## Ideas this leans on`. Reported at that heading, or at line 1 when the heading is missing. |
| `no-video` | A `<details>` block under `## Ideas this leans on` holds no video address as "Fixed formats" defines one, and neither `No checked video yet` nor `Lessons turned off`. Reported at the `<details>` line. |
| `no-code-page` | A standard 2 page that is not `short` has no sibling `BASENAME-code.md`. Reported at line 1, after the awk pass, where `dead-link` is. |
| `no-file-list`, `no-walkthrough` | A file ending `-code.md` with a `Code for [` line lacks `## Every changed file` or `## Code walkthrough`. |

- `## Ideas this leans on` satisfies the existing `no-concepts` rule, as `## Concepts` does. A `short` page needs no ideas section.
- A code sub-page has no word limit.
- The `no-answer` rule, its fixture and its two tests are removed.
- A page with no `Standard:` field is linted exactly as today, minus `no-answer`.

- [ ] **Step 1: Write the templates**

`issue-page.md` keeps its agent-instruction header above `---` (rewrite it for the sections below) and follows "Fixed formats". Content rules to state in the header: target 300 visible words; `## How it works` is one diagram then 4 to 7 numbered steps; each idea is one visible line then a `<details>` with 3 to 5 lines and its links as `<a href>` with `· title · author · checked YYYY-MM-DD`; the Proof fold is an HTML `<table>` with columns acceptance point, command or check, result line; the walk fold sits between the walk markers and starts as `<details><summary>Your walk: not done yet. Run /grasp walk {KEY}</summary></details>`; while `Status: planned` or `building` a visible `## Steps` list and a `## Predict` question sit above `## More detail`, and both move into the "Planned and built" fold at `built`; the page links its sub-page in one line under "How it works"; a blocker is a `> [!WARNING]` alert under the title, never folded.

`issue-code-page.md`: `## Every changed file` is a table per layer with columns `File` and `What it does in this change`; `## Code walkthrough` has one `### N. Title` per "How it works" step, each followed by `grasp-tools snippet` output and one or two sentences.

- [ ] **Step 2: Write the fixtures**

`example-issue-page.md` and `example-issue-page-code.md` are a complete `SHOP-12` pair that passes lint (under 400 visible words, all five owner lines, exactly one idea, a `- **Design · ` idea whose fold has one `<p>Watch: ...</p>` line with a YouTube video and one `<p>Read: ...</p>` line, both dated, a flowchart of at most 10 boxes). `short-issue-page.md` is a `Standard: 2 short` page with sections 1, 2 and 5 and a file list, no sub-page. Each `bad-*` fixture is the example with exactly one defect. The example page uses `Feature: none`, has no relative link except the one to `example-issue-page-code.md`, no image, and no Markdown table: Task 9 copies it into a temp folder and it must still lint clean there.

- [ ] **Step 3: Write the failing tests**

```bash
test_lint_standard2_pair_and_short_page_pass() {
  assert_eq "" "$(lint example-issue-page.md example-issue-page-code.md short-issue-page.md)" "the three good pages are clean"
}
test_lint_flags_no_owner_block()   { _lint_expect no-owner-block "bad-no-owner-block.md:1: no-owner-block"; }
test_lint_flags_asked_too_long()   { _lint_expect asked-too-long "bad-asked-too-long.md:9: asked-too-long 31 words, limit 30"; }
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
test_lint_flags_code_page_sections() {
  local out; out=$(lint bad-code-page-sections-code.md)
  assert_contains "$out" "no-file-list" "file list required"; assert_contains "$out" "no-walkthrough" "walkthrough required"
}
test_lint_code_page_has_no_word_limit() {
  local t; t=$(new_tmp)
  { printf '# SHOP-12: x, code\n\nCode for [SHOP-12: x](SHOP-12-x.md) · Standard: 2\n\n## Every changed file\n\n## Code walkthrough\n\n'; words 900; } > "$t/SHOP-12-x-code.md"
  assert_eq "" "$("$TOOLS" lint-page "$t/SHOP-12-x-code.md")" "900 words on a code page is fine"
}
test_lint_old_page_without_standard_is_unchanged() {
  local t; t=$(new_tmp); kind_page issue 300 > "$t/old.md"
  assert_eq "" "$("$TOOLS" lint-page "$t/old.md")" "an old page with no owner block and no answer still lints clean"
}
```

Set the line number in `test_lint_flags_asked_too_long` to where the fixture's Asked line really is.

- [ ] **Step 4: Run, see them fail, implement in the awk program, delete the `no-answer` rule and its tests**

Run: `tests/grasp-tools.sh lint`
Expected before: the 11 new tests fail. Line 707 and 728 of the test file already use `example-issue-page.md`; keep them passing with the new fixture.

- [ ] **Step 5: Run both suites**

Run: `tests/grasp-tools.sh && tests/skill-docs.sh`
Expected: `161 passed, 0 failed` and `15 passed, 0 failed`.

- [ ] **Step 6: Commit**

```bash
git add skills/grasp/bin/grasp-tools skills/grasp/templates tests
git commit -m "feat: issue pages follow standard 2 with an owner block and a code sub-page"
```

---

### Task 5: The writer's rules

**Files:**
- Modify: `skills/grasp/references/notebook.md` (Layout 8-63, Page shapes 114-151, Toggles 170-190, Explain-back 349-371)
- Modify: `skills/grasp/references/build.md`, `verify.md`, `understand.md`
- Modify: `skills/grasp/SKILL.md` (workflow steps 3, 6, 7 at lines 240, 265, 277; the `page` section 313-333)
- Test: `tests/skill-docs.sh`

**Interfaces:**
- Consumes: `snippet`, `snippet-check`, `coverage`, the lint rules of Task 4.
- Produces: the one set of page-writing rules every later task points at. `notebook.md` gains sections named exactly `## Standard 2`, `## What the writer reads`, `## A snapshot and a living page`, `## Short pages`.

Content the references must state (copy the meaning from the spec sections "The page standard", "A snapshot and a living page", "The writer"):

- The writer reads the repository, the card and its comments, the working note if any, the pull request, the diff, the feature page and the app map. Every path uses this: `/grasp ISSUE`, `page`, `explain`, `repair`.
- Code goes on the sub-page only through `grasp-tools snippet`. Before a page is called written: `lint-page` on both files, `snippet-check` on the sub-page, `coverage` on both. All three must print nothing or the count line only.
- Pinning: `HEAD` of `Checked against` is the merge commit once merged, the pull request head before that; one range per repository touched.
- Proof rows come only from a run made in this session or from the pull request's checks; otherwise the result cell reads `not run here`.
- Small changes (a diff under about 20 lines that adds no behaviour) and bugs get a short page. The old rules "skip the after half" and "bugs get a row, not a page" are removed.
- Explain-back is removed from the page and from workflow step 6. Step 6 ends with one line: `Walk ready: /grasp walk KEY`. It never starts a walk and never waits. Predict stays in step 3.
- The `page` section no longer says it writes "not asked (no person in the run)".
- The before half is unchanged in purpose: at the pick, the attended flow writes sections 1 to 4 as planned, with Steps and Predict, and `--plan` stops there. The illustration rule is unchanged.
- Notion: the same sections, the code sub-page as a child page, and `walk` works. Lint, coverage and `snippet-check` run on Markdown files only.

- [ ] **Step 1: Write the failing assertions in `tests/skill-docs.sh`**

```bash
test_writer_rules_are_stated_once() {
  local nb="$SKILL/references/notebook.md"
  for h in "## Standard 2" "## What the writer reads" "## A snapshot and a living page" "## Short pages"; do
    grep -qxF "$h" "$nb" || _fail "notebook.md lacks: $h"
  done
  for s in "grasp-tools snippet" "snippet-check" "grasp-tools coverage" "not run here" "reads the repository"; do
    grep -qF "$s" "$nb" || _fail "notebook.md does not mention: $s"
  done
  ! grep -rqF "not asked (no person in the run)" "$SKILL" || _fail "the explain-back fallback is still written somewhere"
  ! grep -qF "## Explain it back" "$SKILL/templates/issue-page.md" || _fail "the template still has Explain it back"
  grep -qF "Walk ready: /grasp walk" "$SKILL/SKILL.md" || _fail "step 6 does not end with the walk line"
}
```

Use the variable the file already uses for the skill folder if it is not `$SKILL`.

- [ ] **Step 2: Run and see it fail**

Run: `tests/skill-docs.sh`
Expected: `15 passed, 1 failed`.

- [ ] **Step 3: Edit the references and SKILL.md**

- [ ] **Step 4: Run both suites**

Run: `tests/grasp-tools.sh && tests/skill-docs.sh`
Expected: `161 passed, 0 failed` and `16 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add skills/grasp tests/skill-docs.sh
git commit -m "docs: one set of page rules, written from the repository and checked by command"
```

---

### Task 6: Reader profile, lessons and settings

**Files:**
- Modify: `skills/grasp/templates/grasp-config.md` (new `## Reader`, `## Features`; two keys under `## Notebook`)
- Modify: `skills/grasp/references/notebook.md` (Concepts 240-258, Learning links 259-281)
- Modify: `skills/grasp/references/setup.md`
- Test: `tests/skill-docs.sh`

**Interfaces:**
- Produces, in `.grasp.md`:

```markdown
## Notebook
- sync scope: {project | mine}
- other records: {folders whose files are linked from an issue page when they mention its key, or none}

## Reader
- knows well: {comma list}
- new to: {comma list}

| gap | found on | date |
| --- | -------- | ---- |

## Features
| feature | page | covers |
| ------- | ---- | ------ |
```

Content to state:

- The design idea comes first on every page that is not short: the architecture pattern or system design concept the change rests on, taken from the code and the decisions. Name it with the term a person can search for (resumable upload, idempotent write, optimistic locking, a queue between two services, the server as the source of truth). It is listed even when `knows well` holds it, with a fold of two lines, because the owner has to be able to name it. It is always the first idea, and the heading of the walkthrough step where it shows says so.
- Choosing the other ideas: teach an idea when it is under `new to`, in the gap table, or absent from `knows well`. At most 3 ideas on an issue page with the design idea counted, at most 8 on an `explain` page.
- Every idea gets one specific video and one page to read, in the format of "Fixed formats".
  - The video: search the idea plus the project's stack. A YouTube video, or, when `linkedin learning: yes`, one video inside a LinkedIn Learning course: open the course page, find the video whose title names the idea, and use that video's own address. Never the course address, a channel, a playlist or a search page as the video.
  - Prefer a video that explains before it codes, and for the design idea one that draws the system. Add `&t=NNs` only when the start of the relevant part was read from the video's chapters or transcript.
  - `content checked` only when the chapters, the transcript or the course's table of contents were read and name the idea; otherwise `title match only`. Never claim to have watched it.
  - Run `grasp-tools check-link` on every video. `fail redirected FINAL` on a LinkedIn Learning video means the video is gone: pick another, do not fall back to the course.
  - No video passes: write `No checked video yet`. Never leave the line out.
- The page to read: official documentation first; then this fixed list: refactoring.guru, martinfowler.com, web.dev, developer.mozilla.org, learn.microsoft.com/azure/architecture/patterns, aws.amazon.com/builders-library. For the design idea try the last three and martinfowler.com first. The page must have been opened.
- Each link line holds title, author or site, and `checked YYYY-MM-DD`.
- `setup` asks two questions for Reader (what you know well, what is new to you) and one for `sync scope`, default `project`. It fills `## Features` from the feature pages it finds or writes; a project whose level 2 pages live elsewhere lists them here by hand.

- [ ] **Step 1: Write the failing assertions**

```bash
test_reader_and_features_settings() {
  local cfg="$SKILL/templates/grasp-config.md" nb="$SKILL/references/notebook.md"
  for s in "## Reader" "- knows well:" "- new to:" "| gap | found on | date |" "## Features" "| feature | page | covers |" "- sync scope:" "- other records:"; do
    grep -qF -- "$s" "$cfg" || _fail "config template lacks: $s"
  done
  for s in "title match only" "content checked" "fail redirected" "refactoring.guru" "aws.amazon.com/builders-library" "checked YYYY-MM-DD" \
           "design idea" "one specific video" "No checked video yet" "Never the course address" "system design"; do
    grep -qF "$s" "$nb" || _fail "notebook.md lacks: $s"
  done
  grep -qF "## Reader" "$SKILL/references/setup.md" || _fail "setup.md does not ask for the reader profile"
}
```

- [ ] **Step 2: Run, see it fail, edit the three files, run both suites**

Expected after: `161 passed, 0 failed` and `17 passed, 0 failed`.

- [ ] **Step 3: Commit**

```bash
git add skills/grasp tests/skill-docs.sh
git commit -m "feat: a reader profile decides what a page teaches, and lessons are checked harder"
```

---

### Task 7: One writer

**Files:**
- Modify: `skills/grasp/bin/grasp-tools:153-169` (`block_text`)
- Modify: `skills/grasp/references/setup.md` (the connect step 147-178 and the update section)
- Test: `tests/grasp-tools.sh`, `tests/skill-docs.sh`

**Interfaces:**
- Produces: the block for steps `work`, `verify`, `review`, `resolve` gains this line before "Skip this if grasp is not installed.": `The issue's learning page is written by grasp alone: do not write or patch it by this skill's own rules.`

Content added to `setup.md`: when connecting or updating, read each connected skill and its `references/` for page-writing rules of its own (a learning page, feature page or learning note it tells the agent to write). Show the person the file and lines found, and offer to replace them with one line that points to the grasp block. Edit only after a yes; without one, leave the file and say that two writers remain.

- [ ] **Step 1: Write the failing tests**

In `tests/grasp-tools.sh`:

```bash
test_block_says_grasp_alone_writes_the_page() {
  local s
  for s in work verify review resolve; do
    assert_contains "$(gt block "$s")" "written by grasp alone" "$s block"
  done
  [[ "$(gt block record)" != *"written by grasp alone"* ]] || _fail "the record block is unchanged"
}
```

In `tests/skill-docs.sh`:

```bash
test_setup_looks_for_a_second_writer() {
  grep -qF "page-writing rules of its own" "$SKILL/references/setup.md" || _fail "setup does not look for a second writer"
}
```

If `block` takes its step differently, follow `usage()`.

- [ ] **Step 2: Run, see 2 fail, implement, run both suites**

Expected after: `162 passed, 0 failed` and `18 passed, 0 failed`.

- [ ] **Step 3: Commit**

```bash
git add skills/grasp tests
git commit -m "feat: connected skills leave the learning page to grasp"
```

---

### Task 7b: `explain`, grasp's own full copy

`/grasp explain` must do everything the separate explain-build skill does, from files inside `skills/grasp` only. It is not a pointer. Read `~/.claude/skills/explain-build/SKILL.md` and its `references/pages.md` and `references/grasp.md` once, as the source to carry over; after this task nothing in grasp may refer to that skill.

**Files:**
- Create: `skills/grasp/references/explain.md`
- Modify: `skills/grasp/templates/issue-page.md` and `issue-code-page.md` (the parts only `explain` writes, marked as such in the header)
- Modify: `skills/grasp/SKILL.md` (frontmatter `argument-hint` and `description`, Arguments table, help block, new `explain` section)
- Test: `tests/skill-docs.sh`

**Interfaces:**
- Consumes: `notebook.md` (Task 5), `grasp-tools coverage`, `snippet`, `snippet-check`, `lint-page`, `check-link`, `change-map`, `record-index`.
- Produces: `/grasp explain [SOURCE] [--repo PATH]... [--docs DIR] [--name SLUG] [--lessons all|free|none] [--no-image]` and `/grasp explain check PAGE [--repo PATH] [--base REF]`.
- `argument-hint` gains ` | explain [SOURCE] [--repo PATH] [--docs DIR] [--name SLUG] [--lessons all|free|none] [--no-image] | explain check PAGE [--repo PATH] [--base REF]` before ` | record`.

What `explain.md` must hold, each carried over from explain-build:

| Part | Rule |
| --- | --- |
| When | Work with no tracker issue, or wider than one issue: a setup, a pipeline, a migration, a whole session. Exactly one issue whose page says it all: say so and offer `/grasp page ISSUE`. |
| `SOURCE` | Nothing: the work done in this session. A number or address: a pull request. A name: a branch. `BASE..HEAD`: a commit range. Several pieces of work in the session and none named: ask which. |
| `--repo` | Repeatable. Default: the repositories this session changed, else the current one. The docs may live in another repository than the code. |
| `--docs` | Default: `markdown folder` in `.grasp.md`, else `docs/how-it-works/`. No `.grasp.md` and no `docs/` folder: ask. |
| `--name` | Default: named after the work, matching the numbering and title style already in the folder. Pages are `NAME.md` and `NAME-code.md`. |
| `--lessons` | `all` (default; `free` when `.grasp.md` says `linkedin learning: no`), `free` drops LinkedIn Learning, `none` drops the lessons. |
| `--no-image` | Default off; on when `.grasp.md` says `illustrations: no`. |
| Gather | From the session first: what was asked, each decision and what was rejected, commands and their result lines, every problem and its fix, what is left. Then git per repository: changed files (committed, uncommitted, untracked) and each diff. Then what git does not see: settings, installed tools, permissions, steps a person must do. Read each small file again, never describe one from memory. Older work or a summarised session: use run records, the pull request and the diff, and mark what is reconstructed. Read-only subagents only above about 40 files. |
| Outline first | Print the two sentences, the change map with its arrows, the ideas (at most 8 on an `explain` page), the pictures and the file count per part. Go on unless the person objects or the source is ambiguous. |
| The page | Standard 2. Title `# NAME` with no key. Asked is the request, or the pull request title. Three more folds under `## More detail`, written only by `explain`: `Set it up` (the exact commands and one that shows it worked), `When something goes wrong` (what you see, what to do, with the real messages), `How we built it, step by step`. |
| The sub-page | As any code sub-page, plus two sections written only by `explain`: `## Things people look up` (routes, tables and columns, setting and environment variable names, packages with version and why, error codes) and `## Not in git` (settings in a web console, tools installed on a machine, permissions, and whether each is done). A folder of generated or repeated files may be one entry, `` `path/to/folder/**` ``. |
| Existing pages | Pages on this work already exist: patch them, never write a second set. |
| Prove | The three page checks, every lesson link through `check-link`, every diagram rendered or at least linted, the illustration opened and looked at, each number and claim checked against its source once. |
| Connect | Add rows to the docs router and the folder's index. Update the run record of the task that built the thing (a run that explains older work gets its own). Link issue, feature and architecture pages instead of repeating them. Stage only your own files. |
| Report | Where the pages are, coverage `N of N`, what is not finished, which checks did not run, then the walk line. |
| `check` | Run Prove on `PAGE`, report, write nothing. `--base` defaults to the integration branch. |
| Never | Change code (report a bug found while explaining). Put a secret, token, personal data, client text or raw log on a page. Name a project, client or issue in a web search or an image prompt. Commit or push without the project's standing rule or a yes. |

- [ ] **Step 1: Write the failing assertions in `tests/skill-docs.sh`**

```bash
test_explain_is_a_full_copy() {
  local e="$SKILL/references/explain.md"
  [[ -f "$e" ]] || _fail "references/explain.md missing"
  for s in "this session" "BASE..HEAD" "--repo" "--docs" "--name" "--lessons" "--no-image" "check PAGE" \
           "reconstructed" "what git does not see" "Set it up" "When something goes wrong" \
           "How we built it, step by step" "## Things people look up" "## Not in git" "docs router" \
           "change-map" "grasp-tools coverage" "never write a second set"; do
    grep -qF -- "$s" "$e" || _fail "explain.md lacks: $s"
  done
  grep -qF "/grasp explain check" "$SKILL/SKILL.md" || _fail "no usage line for explain check"
  ! grep -rqiF "explain-build" "$SKILL" || _fail "grasp must not depend on or mention the explain-build skill"
}
```

- [ ] **Step 2: Run and see it fail**

Run: `tests/skill-docs.sh`
Expected: `18 passed, 1 failed`.

- [ ] **Step 3: Write `explain.md`, extend the two templates, edit SKILL.md**

Every new flag goes in `argument-hint`, the Arguments table and the help block with its type, default and one line; add two `explain` examples and the two `explain` questions to IT WILL ASK YOU.

- [ ] **Step 4: Run both suites**

Run: `tests/grasp-tools.sh && tests/skill-docs.sh`
Expected: `162 passed, 0 failed` and `19 passed, 0 failed`. The existing hint-versus-help assertions must pass with every `explain` flag.

- [ ] **Step 5: Commit**

```bash
git add skills/grasp tests/skill-docs.sh
git commit -m "feat: explain finished work from inside grasp, every file, setting and lesson"
```

---

### Task 8: `walk`

**Files:**
- Modify: `skills/grasp/bin/grasp-tools` (new `cmd_keep_walk`, `usage()`, dispatch)
- Create: `skills/grasp/references/walk.md`
- Modify: `skills/grasp/SKILL.md` (hint ` | walk ISSUE|FEATURE`, Arguments, help, new `walk` section), `skills/grasp/templates/feature-page.md` (a walk block and `Walk:` on its "Verified at" line)
- Test: `tests/grasp-tools.sh`, `tests/skill-docs.sh`

**Interfaces:**
- Produces: `grasp-tools keep-walk OLD NEW`. Copies everything between the walk markers of `OLD`, markers included, over the same span in `NEW`, and copies the `Walk: ...` field of `OLD`'s status line into `NEW`'s. Prints `kept` or `no walk to keep`. Exit 0 in both cases. Exit 1, with `NEW` left byte for byte the same, when `OLD` has a walk block and `NEW` has no markers. Exit 2 on bad use or a missing file.
- Produces: the walk fold format, HTML only:

```html
<!-- grasp:walk:start -->
<details><summary>Your walk: 2026-11-27, 5 of 6 right, 1 gap</summary>
<p><b>1. Predict.</b> QUESTION</p>
<p><b>You:</b> THEIR WORDS</p>
<p><b>Right.</b> or <b>Gap:</b> TWO TO FOUR LINES</p>
<p><b>Model answer:</b> ANSWER</p>
</details>
<!-- grasp:walk:end -->
```

Content of `walk.md` (from the spec section "The walk"): needs a standard 2 page that `sync` does not call stale, else say so and offer `repair`; 5 to 7 questions, one at a time, in "How it works" order; before each, show the real lines with `grasp-tools snippet`; kinds are predict, trace, what breaks, why this and not the other; one question is always about the design idea (name the pattern and say what it buys here); after each answer say right or name the gap in two to four lines; `skip` moves on; stopping early saves; at the end write the fold, set `Walk:`, add a row to the `## Reader` gap table per gap, and add one checked lesson per gap under "Ideas this leans on"; an issue walk uses the pinned lines and says when the page lists "Changed since by"; a feature walk uses the code today, follows one request across the feature's issues, and writes its fold on the feature page; never score; never block; never rewrite the person's words except to escape HTML.

- [ ] **Step 1: Write the failing tests**

```bash
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
```

In `tests/skill-docs.sh`:

```bash
test_walk_is_documented() {
  local w="$SKILL/references/walk.md"
  [[ -f "$w" ]] || _fail "references/walk.md missing"
  for s in "one at a time" "grasp:walk:start" "## Reader" "never block" "Changed since by"; do
    grep -qiF "$s" "$w" || _fail "walk.md lacks: $s"
  done
  grep -qF "/grasp walk" "$SKILL/SKILL.md" || _fail "no usage line for walk"
}
```

- [ ] **Step 2: Run, see 4 fail, implement `cmd_keep_walk` (write to a temp file, then `write_if_changed`), write `walk.md`, edit SKILL.md and the feature template**

- [ ] **Step 3: Run both suites**

Expected: `165 passed, 0 failed` (add `keep-walk` to the fixed command list) and `20 passed, 0 failed`.

- [ ] **Step 4: Commit**

```bash
git add skills/grasp tests
git commit -m "feat: a guided walk records the owner's own answers on the page"
```

---

### Task 9: `grasp-tools sync`

**Files:**
- Modify: `skills/grasp/bin/grasp-tools` (new `cmd_sync` and helpers, `usage()`, dispatch)
- Test: `tests/grasp-tools.sh`

**Interfaces:**
- Consumes: `cmd_lint_page`, `cmd_snippet_check`, `cmd_coverage`, `cmd_check_link`, `PAGE_STANDARD`.
- Produces: `grasp-tools sync [--docs DIR] [--repo DIR]... [--keys FILE] [--heads FILE] [--links] [--only KEY] [--no-write]`.
  - `--docs` defaults to `docs/how-it-works`. Pages are every `.md` under it, not in `runs/`, that is an issue page (a `Status:` line as lint detects it), a code sub-page, or a feature page (lint's `isfeature`, or listed as a `Feature:` target).
  - `KEY` is the title text before the first `:`; for a title with no `:` it is the file's basename.
  - `--keys FILE`: one key per line (the agent reads the tracker). `--heads FILE`: `KEY<TAB>REPO<TAB>SHA` per line, the pull request's current head or merge commit.
  - Stdout, one row per issue page and feature page, then one per missing key: `KEY<TAB>STATES<TAB>PATH<TAB>DETAIL`. `STATES` is a comma list in this order: `missing`, `stale`, `below-standard`, `bad-link`, `changed-since`, `not-walked`; or `ok` alone.
  - Stderr notes when a check could not run: `note: missing not checked (no --keys)`, `note: issue pages not checked for stale (no --heads)`, `note: links not checked (no --links)`.
  - Exit 0 whatever the states; 2 on bad use.
  - Unless `--no-write`: it rewrites the block between the issues markers in `DOCS/features/README.md` (table `| Issue | Feature | Design idea | State | Walk | Checked |`, sorted by feature then checked date, `No feature page` for `Feature: none`) and in every feature page (table `| Issue | Design idea | State | Walk | Checked |`, oldest first). `Design idea` is the text between `- **Design · ` and `:**` on the issue page, empty when there is none. When any idea fold holds `No checked video yet`, DETAIL gains `N ideas without a video`. A file with no markers gets `## Issues` and the block appended once. It also sets, replaces or removes the `Changed since by:` line of each issue page. `--only` implies `--no-write`.

State rules:

| State | Rule | DETAIL |
| --- | --- | --- |
| `missing` | key in `--keys` with no issue page | empty |
| `stale` (issue) | a `--heads` row for this key and repo whose SHA is not the page's `HEAD` (compare by prefix) | `REPO moved to SHA` |
| `stale` (feature) | a backticked path on the page changed in `git log SHA..HEAD` of a `--repo`, `SHA` from its "Verified at" line | first changed path |
| `below-standard` | no `Standard:` field or a number under `PAGE_STANDARD`; no `Checked against:` line; any `lint-page` finding on the page or its sub-page; `snippet-drift` or `snippet-unmarked`; `coverage` MISSING or STALE | the first reason, for example `no Standard field`, `lint: no-owner-block`, `coverage: MISSING web/a.ts` |
| `bad-link` | with `--links`, a lesson link fails `check-link` | the address |
| `changed-since` | another issue page with a later checked date names, in the first column of its file list, a file this page's sub-page also names | the later keys, comma separated |
| `not-walked` | `Walk:` does not start with `walked` | empty |

`snippet-unreachable` and `snippet-unknown-repo` do not make a page `below-standard`; they are appended to DETAIL as `unreachable REPO@REV`.

<!-- ponytail: changed-since compares page dates and file names, not git ancestry. Move to merge order per repo if two cards built on the same day mislabel each other. -->

- [ ] **Step 1: Write a fixture builder and the failing tests**

```bash
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
  local d p t out; read -r d p <<<"$(sync_fix)"; t=$(new_tmp)
  printf 'SHOP-12\nSHOP-13\n' > "$t/keys"; printf 'SHOP-12\tweb\tfffffff\n' > "$t/heads"
  out=$(gt sync --docs "$d" --repo "$p" --keys "$t/keys" --heads "$t/heads" --no-write 2>/dev/null)
  assert_eq "missing" "$(row SHOP-13 "$out" | cut -f2)" "a key with no page"
  assert_contains "$(row SHOP-12 "$out" | cut -f2)" "stale" "the pull request moved"
  assert_contains "$(row SHOP-12 "$out" | cut -f4)" "web moved to fffffff" "detail"
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
```

Add one more, `test_sync_changed_since_names_the_later_issue`: copy the pair to `SHOP-14-y.md` and `SHOP-14-y-code.md` with the title changed and the date `2026-11-25`; assert the SHOP-12 row holds `changed-since` with DETAIL containing `SHOP-14`, and the SHOP-14 row does not hold `changed-since`; then run without `--no-write` and assert `SHOP-12-x.md` holds the line `Changed since by: [SHOP-14](SHOP-14-y.md)` exactly once after a second run, and `SHOP-14-y.md` holds no such line. And `test_sync_lists_design_idea_and_counts_missing_videos`: after a writing run the block in `features/README.md` holds the example's design idea name in the `Design idea` column; then replace the example's `Watch:` line with `<p>No checked video yet</p>` and assert the SHOP-12 DETAIL contains `1 ideas without a video` while its states do not gain `below-standard`. And `test_sync_bad_link_only_with_links`: with `GRASP_CURL="$FIX/fake-curl" FAKE_CURL_CASE=yt-400` and `--links`, the row holds `bad-link`; without `--links` it does not.

- [ ] **Step 2: Run and see them fail**

Run: `tests/grasp-tools.sh sync`
Expected: `11 failed`.

- [ ] **Step 3: Implement `cmd_sync`**

Call the other commands as functions and capture their output; do not re-implement their rules. Build each generated block in a temp file and use `write_if_changed`.

- [ ] **Step 4: Run the whole suite**

Run: `tests/grasp-tools.sh`
Expected: `176 passed, 0 failed` (add `sync` to the fixed command list).

- [ ] **Step 5: Commit**

```bash
git add skills/grasp/bin/grasp-tools tests/grasp-tools.sh
git commit -m "feat: sync reports missing, stale and below-standard pages and lists issues per feature"
```

---

### Task 10: `sync` and `repair` for the agent

**Files:**
- Create: `skills/grasp/references/upkeep.md`
- Modify: `skills/grasp/SKILL.md` (hint ` | sync [FEATURE] | repair ISSUE|FEATURE|--all [--only page|code|links] [--dry-run] [--force] ["REASON"]`, Arguments, help including IT WILL ASK YOU, two sections)
- Modify: `skills/grasp/templates/feature-page.md` (`## Changes` becomes `## Issues` holding the two issues markers), `skills/grasp/references/overview.md` (feature pages list issues through the generated block; `map` never edits inside the walk or issues markers), `skills/grasp/references/records.md` (a run record for issue work links the issue page in its Changed line and does not repeat it)
- Test: `tests/skill-docs.sh`

**Interfaces:**
- Consumes: `grasp-tools sync`, `keep-walk`, the three page checks, `notebook.md`.
- Produces: `/grasp sync [FEATURE]` and `/grasp repair ...` as the spec's "Sync and repair" section defines them.

Content of `upkeep.md`:

- **sync.** Read `sync scope` in `.grasp.md`. `project`: list every issue of the tracker project that has a pull request; `mine`: only those assigned to the account `setup` tested. Write the keys to a temp file, and for each key with a page the pull request's head or merge commit to a heads file. When the tracker or the host cannot be read, run without that file and repeat the helper's note to the person. Run `grasp-tools sync` with every project of `## Projects` as `--repo`, and `--links` when the person asked for links. Print the rows as a table grouped by feature, worst first, then one line of counts. Never edit prose.
- **repair one issue.** Accept a key, a tracker address, or the path of either file. Run `grasp-tools sync --only KEY` and print each finding as one line. `--dry-run` stops there. With nothing found and no reason and no `--force`: print `nothing to repair` and stop. Otherwise write the page again by `notebook.md`, in a subagent, from the card, the pull request and the code at the pinned commit; a quoted reason is a finding to check against the code first, and the result says where the code agrees and where it does not. Write to a new file, run `grasp-tools keep-walk OLD NEW`, and stop without replacing the old file if it exits 1. An old explain-back answer becomes the first entry of the walk fold. Link every file under `other records` that mentions the key, in the "Open and not verified" fold. `--only page`, `--only code`, `--only links`: touch that part only; `--only links` rechecks each link and replaces failed ones in place. Finish with the three checks and report `repaired` or `needs a person: REASON`. A missing page is written the same way.
- **repair a feature or `--all`.** Run `sync`, show how many pages would be rewritten, and ask. With no argument, ask which feature. One page per subagent, one at a time when the project's checks are heavy.
- **Notion.** `sync` and `repair` work on Markdown notebooks only; on Notion say so and stop.

- [ ] **Step 1: Write the failing assertions**

```bash
test_upkeep_is_documented() {
  local u="$SKILL/references/upkeep.md"
  [[ -f "$u" ]] || _fail "references/upkeep.md missing"
  for s in "grasp-tools sync --only" "keep-walk" "nothing to repair" "--dry-run" "--only links" "needs a person" "sync scope" "other records" "Markdown notebooks only"; do
    grep -qF -- "$s" "$u" || _fail "upkeep.md lacks: $s"
  done
  grep -qF "/grasp sync" "$SKILL/SKILL.md"   || _fail "no usage line for sync"
  grep -qF "/grasp repair" "$SKILL/SKILL.md" || _fail "no usage line for repair"
  grep -qF "grasp:issues:start" "$SKILL/templates/feature-page.md" || _fail "feature template has no issues block"
  ! grep -qxF "## Changes" "$SKILL/templates/feature-page.md" || _fail "feature template still has a hand-kept Changes table"
}
```

- [ ] **Step 2: Run, see it fail, write the files, run both suites**

Expected after: `176 passed, 0 failed` and `21 passed, 0 failed`. The hint, help and usage-line assertions must pass with all four new subcommands and every new flag.

- [ ] **Step 3: Commit**

```bash
git add skills/grasp tests/skill-docs.sh
git commit -m "feat: repair one issue's documents, a feature or everything, from what sync found"
```

---

### Task 11: Version 0.5.0 and the README

**Files:**
- Modify: `skills/grasp/VERSION`, `.claude-plugin/plugin.json`, `README.md:25,231` and its feature list and command table, `AGENTS.md:1`, `.grasp.md:51`
- Modify: `tests/grasp-tools.sh` (the `0.4.0` strings at lines 44, 71, 92, 94, 169, 736, 753, 844, 924, 931, 938, 967, 1344, 1353, 1370; the line numbers have moved, find them with grep)
- Modify: `docs/research/README.md` (the two rows added on 2026-11-26: replace "Design agreed 2026-11-26, not built yet:" with what grasp now does)
- Create: `docs/how-it-works/runs/YYYY-MM-DD-understanding-first-build.md`

- [ ] **Step 1: Bump the version everywhere**

Run: `grep -rn "0\.4\.0" --include='*' . | grep -v '^./docs/' | grep -v '^./.git/'`
Expected after editing: no line left except deliberate "old version" fixtures in tests that test upgrading from an older block. Read each test before changing its string.

- [ ] **Step 2: Refresh this repository's own block**

Run: `skills/grasp/bin/grasp-tools refresh`
Expected: `AGENTS.md` line 1 reads `v=0.5.0`.

- [ ] **Step 3: Update the README**

Add `explain`, `walk`, `sync`, `repair` where the other subcommands are listed, and one short paragraph on the page standard. Do not add a changelog file.

- [ ] **Step 4: Run every suite**

Run: `tests/grasp-tools.sh && tests/skill-docs.sh`
Expected: `176 passed, 0 failed` and `21 passed, 0 failed`.

Run: `tests/obsidian-render.sh tests/fixtures/pages`
Expected: exit 0 with every diagram drawn, or exit 2 (skipped: the Obsidian command line is not set up). Report which. Exit 1 is a failure to fix.

- [ ] **Step 5: Write the run record and rebuild its index**

Five lines as `AGENTS.md` prescribes, with the two summary lines above as **Checked**. Then `skills/grasp/bin/grasp-tools record-index docs/how-it-works/runs`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: grasp 0.5.0"
```

---

### Task 12: Check `explain` against explain-build, part by part

The separate explain-build skill is not changed by this plan. This task only proves grasp's copy lost nothing.

**Files:**
- Modify: `docs/how-it-works/runs/` record of Task 11 (one line under Problems for anything found)

- [ ] **Step 1: Compare the two skills section by section**

Read `~/.claude/skills/explain-build/SKILL.md`, `references/pages.md` and `references/grasp.md` beside `skills/grasp/references/explain.md`, `notebook.md` and the two issue templates. For every argument, flag, workflow step, page section, picture rule, lesson rule and "it will ask you" line of explain-build, name the line in grasp that carries it. Print the result as a two-column table.
Expected: no row with an empty right column. A row that is empty on purpose (the `-files` name became `-code`, explain-back became the walk line) says why.

- [ ] **Step 2: Fix every real gap in `explain.md`, add its string to `test_explain_is_a_full_copy`, run `tests/skill-docs.sh`**

Expected: `21 passed, 0 failed`.

- [ ] **Step 3: Commit, only if something changed**

```bash
git add skills/grasp tests/skill-docs.sh
git commit -m "fix: explain carries the last parts of the old explain flow"
```

---

### Task 13: Trial on one real card

This task needs the owner. Do not start it without them.

- [ ] **Step 1: Ask the owner which project and which card.** Stop until answered.
- [ ] **Step 2: In that project, add `## Reader` and `## Features` to `.grasp.md` from the owner's answers.** Change nothing else there.
- [ ] **Step 3: Run `/grasp repair KEY --dry-run`, then `/grasp repair KEY`.** Expected: the three checks print nothing but the coverage count; the visible part is under 400 words; the Asked line is the card's own words.
- [ ] **Step 4: Open both files in Obsidian with the owner.** Check every diagram draws, folds open, code has colours on the sub-page.
- [ ] **Step 5: The owner runs `/grasp walk KEY`.** Expected: answers are on the page in their words, and one gap row is in `## Reader` for each gap.
- [ ] **Step 6: Run `/grasp repair KEY --only code`, then `/grasp repair KEY --force`.** Expected: `git diff --stat` shows only the sub-page after the first; the walk fold is byte for byte the same after the second (`git diff` shows no line inside the walk markers).
- [ ] **Step 7: Run `/grasp sync`.** Expected: one row per page, the trial card `ok`, the others `below-standard`.
- [ ] **Step 7a: Run `/grasp explain` on a branch or range the owner picks, into a scratch `--docs` folder, and `/explain-build` on the same range into another.** Expected: `grasp-tools coverage` prints `N of N` on grasp's pair, and every file, setting, route and "not in git" item on explain-build's two pages is also on grasp's two. List anything missing; it goes back to Task 12 step 2.
- [ ] **Step 7b: Ask the owner what happens to explain-build: keep it as it is, or turn it into a pointer to `/grasp explain`.** Do neither without an answer. A pointer is a separate small change in `~/Projects/personal/skills`.
- [ ] **Step 8: Commit nothing in that project.** Show the owner `git status` there and let them keep or discard the files.
- [ ] **Step 9: Write what was learned** into the run record of Task 11 (Problems and Next lines), and list every rule the trial showed to be wrong as an item for the adoption plan.
