# Visual pages, skill setup and tracker coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make grasp's learning pages visual-first and Obsidian-safe, let `/grasp setup` connect a project's own workflow skills and live-test its tracker, add `/grasp update` and `/grasp page`, and add ClickUp.

**Architecture:** The skill stays Markdown instructions (SKILL.md router + references + templates). Exact, mechanical steps move into one dependency-free bash helper, `skills/grasp/bin/grasp-tools`, with its own plain-bash test runner. An Obsidian render test runs first and fixes the toggle form every later task uses.

**Tech Stack:** bash, sed, awk, curl; Markdown (Obsidian core + GitHub); Mermaid; Playwright CLI (optional, at run time only).

**Spec:** `docs/superpowers/specs/2026-11-20-visual-pages-setup-trackers-design.md`

## Global Constraints

- Branch first: `git switch -c feat/visual-pages-setup` (never commit on `main`).
- Commit messages: Conventional Commits, **no `Co-Authored-By` line, no AI attribution** (owner's global rule overrides the harness).
- `grasp-tools` needs only `bash`, `sed`, `awk`, `curl`. No `jq`, no `bats`, no Node.
- Version: `0.2.0` in both `skills/grasp/VERSION` and `.claude-plugin/plugin.json`.
- Block format number: `1`. Markers exactly `<!-- grasp:start b=1 v=0.2.0 step=STEP -->` and `<!-- grasp:end -->`.
- `STEP` ∈ `work`, `verify`, `review`, `resolve`.
- Pages: standard relative `.md` links, no `[[wikilinks]]`, images in `./assets` beside the page, Mermaid fences outside toggles only.
- Every toggle title states a conclusion; one level of folding; blockers (`> [!WARNING]`) never folded.
- Learning links: at most 3, live-checked, paywall labelled, `checked YYYY-MM-DD`; search queries hold only the concept name.
- Never handle or print tracker tokens. Tracker writes during setup only after a yes.
- `help` block in SKILL.md lists every subcommand and flag the body implements, and nothing else.
- One heavy process at a time (owner rule).

## Review Focus

1. A SKILL.md with CRLF line endings or no trailing newline: `connect` must append one clean block and keep the user's line endings and bytes above the marker unchanged.
2. `connect` run twice, or `refresh` on a current block: exactly one block remains and the file is byte-identical on the second run.
3. A skill path containing spaces (`.claude/skills/my skill`): every subcommand handles it.
4. A YouTube title with escaped quotes or `\u` escapes in the oEmbed JSON: `check-link` prints the decoded title, not a truncated one.
5. A page that shows `<details>` or `[[x]]` inside a fenced code block (documenting syntax): `lint-page` ignores fenced code.

---

### Task 1: Obsidian render gate

Decides the toggle form (`html` or `callout`) used by Tasks 3 and 6. Nothing else depends on Obsidian behaviour.

**Files:**
- Create: `tests/render/obsidian-check.md`
- Create: `docs/research/visual-pages.md` (from a scratch research note, plus a "Render test results" section)
- Modify: `docs/research/README.md` (one row linking `visual-pages.md`)

**Interfaces:**
- Produces: the decision `TOGGLE_FORM=html|callout`, written as the first line of the "Render test results" section: `Decision: TOGGLE_FORM=<value>`.

- [ ] **Step 1: Branch.** `git switch -c feat/visual-pages-setup`.
- [ ] **Step 2: Write `tests/render/obsidian-check.md`** with one labelled section each for: (a) `<details>` single block, no blank lines, HTML-only content incl. `<pre>` code; (b) `<details>` with blank lines and Markdown inside (labelled FORBIDDEN, expected to fail in Obsidian); (c) `> [!info]- Title` foldable callout containing a Mermaid fence and a code fence; (d) Mermaid flowchart with a `style` highlight; (e) Mermaid `sequenceDiagram` with `autonumber`; (f) the five GitHub alerts; (g) `| Before | After |` table with `![after](assets/obsidian-check.png)` (add a small PNG at `tests/render/assets/obsidian-check.png`); (h) a `diff` fence; (i) a relative `.md` link to `../../README.md`.
- [ ] **Step 3: GitHub render.** Run `gh api markdown -f mode=gfm -F text=@tests/render/obsidian-check.md > "$SCRATCH/gh.html"` and record, per section, whether it folds/renders. (Mermaid is rendered client-side on GitHub; for (d)(e) check the `mermaid` code block is emitted.)
- [ ] **Step 4: Obsidian render.** Register `tests/render` as a temporary vault or open the file in Obsidian.app via the computer-use tool; screenshot reading view and live preview; record per section. If computer-use is unavailable, ask the owner to open it and report sections (a), (b), (c).
- [ ] **Step 5: Decide.** `TOGGLE_FORM=html` if (a) folds in Obsidian reading view and live preview and on GitHub; otherwise `TOGGLE_FORM=callout` (owner's decision: Obsidian wins). Write `docs/research/visual-pages.md` with the research and the results table (construct × GitHub × Obsidian reading × Obsidian live preview), decision line first. Remove the temporary vault registration if one was added.
- [ ] **Step 6: Commit.** `git add tests/render docs/research docs/superpowers && git commit -m "docs: design, plan, visual page research and Obsidian render test"`

### Task 2: grasp-tools skeleton, version and test runner

**Files:**
- Create: `skills/grasp/VERSION` (contents `0.2.0`)
- Create: `skills/grasp/bin/grasp-tools` (executable)
- Create: `tests/grasp-tools.sh` (executable), `tests/lib.sh`
- Modify: `.claude-plugin/plugin.json` (`"version": "0.2.0"`)

**Interfaces:**
- Produces: `grasp-tools <command> [args]`; unknown command → usage on stderr, exit 2. `grasp-tools version` prints `0.2.0`. Script resolves its own dir (`GRASP_HOME`, the skill dir) by following symlinks. Constants `BLOCK_FORMAT=1`, `TOGGLE_FORM=<Task 1 decision>`.
- Produces for tests: `tests/lib.sh` with `assert_eq EXPECTED ACTUAL MSG`, `assert_exit CODE MSG -- CMD...`, `assert_file_eq PATH_A PATH_B MSG`, `new_tmp` (prints a fresh dir under `$TMPDIR`), and a summary that exits non-zero on any failure. `tests/grasp-tools.sh` sources it and runs every `test_*` function.

- [ ] **Step 1: Write failing tests** `test_version_prints_0_2_0` (`assert_eq 0.2.0 "$(grasp-tools version)"`), `test_version_matches_plugin_json` (version equals the `"version"` value in `.claude-plugin/plugin.json`), `test_unknown_command_exits_2`, `test_help_lists_all_commands` (`grasp-tools -h` output contains each of `connect disconnect status refresh check-link lint-page version`).
- [ ] **Step 2: Run** `tests/grasp-tools.sh` → FAIL (script missing).
- [ ] **Step 3: Implement** the dispatcher, `version`, `-h|--help|help`, VERSION file, plugin.json bump. Stub the other commands to exit 3 "not implemented".
- [ ] **Step 4: Run** `tests/grasp-tools.sh` → PASS.
- [ ] **Step 5: Commit** `feat: grasp-tools helper skeleton and 0.2.0 version`.

### Task 3: `lint-page`

**Files:**
- Modify: `skills/grasp/bin/grasp-tools`
- Create: `tests/fixtures/pages/good.md`, `tests/fixtures/pages/bad-*.md` (one per rule)
- Test: `tests/grasp-tools.sh`

**Interfaces:**
- Produces: `grasp-tools lint-page FILE...` → one line per violation `FILE:LINE: RULE`, exit 1 if any, 0 if none. RULE names: `details-blank-line`, `details-markdown`, `details-nested`, `wikilink`, `foldable-callout`, `highlight`, `remote-image`, `warning-in-toggle`, plus when `TOGGLE_FORM=callout`: `details-not-allowed` (any `<details>` except one whose summary is exactly `Model answer`).
- Under `TOGGLE_FORM=callout`, `foldable-callout` is not a rule (it is the required form) and `warning-in-toggle` covers `> [!WARNING]` nested in a `> [!info]-` callout.

- [ ] **Step 1: Write failing tests**: `test_lint_good_page_passes` (exit 0, no output); one `test_lint_flags_<rule>` per rule asserting exit 1 and the exact `bad-<rule>.md:<line>: <rule>` line; `test_lint_ignores_fenced_code` (fixture with `<details>` and `[[x]]` inside a ``` fence → exit 0); `test_lint_allows_relative_assets_image` (`![x](assets/KEY-after.png)` passes; `![x](https://…)` and `![x](/abs.png)` flag `remote-image`).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** in awk: track fenced-code state (``` and ~~~), skip lines inside fences; track `<details>` open/close depth; inside a toggle flag blank lines, lines starting with Markdown markers (`#`, `- `, `* `, `1. `, ```` ``` ````, `|`, `> `, `![`), and `[text](link)` syntax.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat: lint-page checks pages render in Obsidian and GitHub`.

### Task 4: `connect`, `disconnect`, `status`, `refresh`

**Files:**
- Modify: `skills/grasp/bin/grasp-tools`
- Create: `tests/fixtures/skills/` (`plain/SKILL.md`, `crlf/SKILL.md` with CRLF, `no-newline/SKILL.md`, `my skill/SKILL.md`), `tests/fixtures/grasp-md/old.md` (a 0.1.0 `.grasp.md` with no Connected skills section)
- Test: `tests/grasp-tools.sh`

**Interfaces:**
- Consumes: `BLOCK_FORMAT`, `version` from Task 2.
- Produces:
  - Global option `--config PATH` (default `./.grasp.md`); skill dirs are given relative to the config file's directory.
  - `connect SKILL_DIR STEP` → appends/replaces the block, upserts the row, prints `connected SKILL_DIR STEP`. Bad STEP → exit 2. Missing `SKILL_DIR/SKILL.md` → exit 1.
  - `disconnect SKILL_DIR` → removes block (and the one blank line before it that connect added) and row.
  - `status` → one line per row, tab-separated `SKILL_DIR STEP STATE`, STATE ∈ `ok`, `stale` (marker `b` < BLOCK_FORMAT), `no-block`, `missing` (no SKILL.md); exit 1 if any not `ok`.
  - `refresh [SKILL_DIR]` → re-writes `stale` and `no-block` blocks; leaves `ok` untouched byte-for-byte.
- Block text (exact copy; `STEP` substituted):

```
<!-- grasp:start b=1 v=0.2.0 step=STEP -->
## Learning page (grasp)
When this skill has finished its own work, run grasp's `page` subcommand for the same issue or
pull request with `--step STEP` (`/grasp page <issue or PR> --step STEP`, or `/grasp:grasp page ...`
when grasp is installed as a plugin), so the issue's learning page shows what was done.
Skip this if grasp is not installed.
<!-- grasp:end -->
```

- `.grasp.md` section (created at end of file when absent):

```
## Connected skills

| skill | step | grasp version |
| ----- | ---- | ------------- |
| .claude/skills/work-issue | work | 0.2.0 |
```

- [ ] **Step 1: Write failing tests**: `test_connect_appends_block_and_row`; `test_connect_twice_is_idempotent` (second run leaves both files byte-identical); `test_connect_preserves_crlf_and_text_above` (bytes before the marker unchanged; block lines use CRLF); `test_connect_no_trailing_newline` (one newline inserted before the block, nothing else changed); `test_connect_path_with_spaces`; `test_connect_bad_step_exits_2`; `test_connect_creates_section_in_old_grasp_md`; `test_disconnect_restores_original` (connect then disconnect → original bytes); `test_status_reports_ok_stale_missing_noblock` (craft a `b=0` block for stale, delete a dir for missing, strip a block for no-block; exit 1); `test_refresh_rewrites_only_stale`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** Detect CRLF from the file's first line ending and write the block with the same ending. Replace by deleting from the start marker line through the end marker line. Row upsert keyed on the skill column. Write via temp file + `mv`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat: connect project skills to grasp with a marked block`.

### Task 5: `check-link`

**Files:**
- Modify: `skills/grasp/bin/grasp-tools`
- Create: `tests/fixtures/fake-curl` (executable; reads `FAKE_CURL_CASE` and prints canned status/body/final URL)
- Test: `tests/grasp-tools.sh`

**Interfaces:**
- Produces: `check-link URL` → on pass, exit 0 and one tab-separated line: YouTube `ok TITLE CHANNEL`; LinkedIn Learning `ok FINAL_URL`; other `ok URL`. On fail, exit 1 and `fail CODE` (CODE = HTTP status, or `timeout`, or `not-learning` when a LinkedIn redirect leaves `/learning/`).
- Uses `${GRASP_CURL:-curl}`, `--max-time 10`, a generic User-Agent `grasp-link-check`. YouTube: `https://www.youtube.com/oembed?url=<encoded URL>&format=json`. LinkedIn: `-L -o /dev/null -w '%{http_code} %{url_effective}'`.
- `check-link --live` is not a flag; live tests run when `tests/grasp-tools.sh --live` is passed.

- [ ] **Step 1: Write failing tests** (all with `GRASP_CURL=tests/fixtures/fake-curl`): `test_youtube_ok_prints_title_channel`; `test_youtube_title_with_escapes` (body title `He said \"hi\" é` → prints `He said "hi" é`); `test_youtube_400_fails`; `test_linkedin_redirect_prints_final_url`; `test_linkedin_404_fails`; `test_linkedin_leaves_learning_fails_not_learning`; `test_other_200_ok`; `test_timeout_fails`. Live-only: `test_live_youtube_invalid_id_fails` (`watch?v=aaaaaaaaaaa` → exit 1).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** JSON field extraction in awk handling `\"`, `\\`, `\/` and `\uXXXX` (print as UTF-8).
- [ ] **Step 4: Run** `tests/grasp-tools.sh` → PASS; then `tests/grasp-tools.sh --live` → PASS.
- [ ] **Step 5: Commit** `feat: check-link verifies YouTube and LinkedIn Learning links live`.

### Task 6: Visual page template and notebook rules

**Files:**
- Modify: `skills/grasp/templates/issue-page.md` (rewrite to the spec's section 1 layout, both halves, toggles in `TOGGLE_FORM`; remove the old "Markdown inside details works in Obsidian" note)
- Modify: `skills/grasp/references/notebook.md` (page shapes, toggle form, diagram-type rule, screenshots, learning links, existing-page conversion, Notion layout, run `grasp-tools lint-page` after every write)
- Create: `tests/fixtures/pages/example-issue-page.md` (a filled example of the template)
- Test: `tests/grasp-tools.sh`

**Interfaces:**
- Consumes: `lint-page` (Task 3), `check-link` (Task 5), `TOGGLE_FORM` (Task 1).
- Produces: section names later tasks and references cite: "Where it fits", "Before and after", "How it works", "Decision", "Blocker", "Explain it back", "Learn more".

- [ ] **Step 1: Write failing test** `test_example_page_lints_clean` (`grasp-tools lint-page tests/fixtures/pages/example-issue-page.md` exit 0) and `test_template_has_sections` (template contains each section name above and no blank line inside any toggle).
- [ ] **Step 2: Run** → FAIL (fixture missing / old template).
- [ ] **Step 3: Write** the template and example. Diagram rule (copy into notebook.md): sequence for API or multi-service flows, `erDiagram` for schema changes, `classDiagram` for class hierarchies, flowchart for logic, none for trivial changes; `autonumber` on sequence diagrams and walkthrough steps numbered to match. Screenshots: `npx playwright screenshot --viewport-size=1280,800 URL assets/KEY-after.png`, caption `After, at <short sha>, YYYY-MM-DD`; "before" from an issue attachment when present; skip with "No visible change" when nothing is on screen; never install Playwright without a yes; login-protected screen → ask once, never store credentials. Learning links: rule from spec section 1 with `grasp-tools check-link`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat: visual-first issue page with Obsidian-safe toggles`.

### Task 7: `setup`, `update`, `page` subcommands and trackers

**Files:**
- Create: `skills/grasp/references/setup.md` (setup steps 1–6, update flow, lazy fill of missing `.grasp.md` sections)
- Modify: `skills/grasp/SKILL.md` (argument table, `help` block, Setup section → points to setup.md and runs automatically when `.grasp.md` is missing, new `setup`, `update`, `page` sections, References list; `argument-hint` adds `setup | update | page ISSUE|PR [--step work|verify|review|resolve]`)
- Modify: `skills/grasp/templates/grasp-config.md` (add `tested:`, `## App`, `## Learning`, `## Connected skills`)
- Modify: `skills/grasp/references/trackers.md` (ClickUp forms and reader, Azure DevOps, "other", ambiguity rule incl. `DEV-42`, live setup test, failed-read message offering only the tracker re-test)
- Modify: `skills/grasp/references/review.md` (patching an old page converts toggles; run `lint-page`)
- Modify: `install.sh` (`--copy` writes `DEST/.source` containing the repo path)
- Test: `tests/grasp-tools.sh`, `tests/skill-docs.sh` (create)

**Interfaces:**
- Consumes: `connect`, `status`, `refresh` (Task 4); template section names (Task 6).
- `page` decides the half: no branch diff against the integration branch and no PR → before half; otherwise after half (writing the before half first when absent). `--step` defaults to `work`. No code, commits or tracker writes.
- `update`: symlink install (`GRASP_HOME` resolves through a symlink into a git repo) → `git -C <repo> pull --ff-only`; plugin install → ask the user to run `/plugin marketplace update grasp`, continue on confirm; copy install → `install.sh --copy` from the path in `.source`. Then `grasp-tools status`; diff + `refresh` on yes; missing skill → ask re-point or disconnect.
- Setup step 6 uses AskUserQuestion with `multiSelect: true`, one option per overlapping skill (label = skill name, description = proposed step and why), max 4 per question, extra skills in a follow-up question.

- [ ] **Step 1: Write failing tests** in `tests/skill-docs.sh`: `test_help_lists_subcommands` (help block in SKILL.md contains `setup`, `update`, `page`, `--step`); `test_argument_hint_matches_help` (every `--flag` and subcommand in `argument-hint` appears in the help block and vice versa); `test_references_exist` (every `references/*.md` and `templates/*.md` linked from SKILL.md exists); `test_trackers_cover_clickup` (trackers.md contains `app.clickup.com/t/` and `ClickUp`); `test_config_template_sections` (grasp-config.md contains `## Connected skills`, `## App`, `## Learning`, `tested:`). In `tests/grasp-tools.sh`: `test_install_copy_writes_source` (`install.sh --project "$tmp" --copy` → `$tmp/.claude/skills/grasp/.source` holds the repo path).
- [ ] **Step 2: Run** both → FAIL.
- [ ] **Step 3: Write** the docs and the `install.sh` change.
- [ ] **Step 4: Run** both → PASS.
- [ ] **Step 5: Commit** `feat: setup connects project skills and tests the tracker; add update and page`.

### Task 8: README and end-to-end check

**Files:**
- Modify: `README.md` (what's new: visual pages, `setup`, `update`, `page`, ClickUp; how `update` works per install; how to run tests)
- Modify: `docs/research/README.md` (findings rows for visual-pages decisions)

- [ ] **Step 1: End-to-end in a scratch repo:** create a temp git repo with `.claude/skills/work-issue/SKILL.md` and `.claude/skills/review-pr/SKILL.md`; run `grasp-tools --config .grasp.md connect .claude/skills/work-issue work` and `... review-pr review`; `status` → both `ok`; hand-edit one marker to `b=0`; `status` exits 1 with `stale`; `refresh`; `status` exits 0.
- [ ] **Step 2: Lint all pages:** `skills/grasp/bin/grasp-tools lint-page tests/fixtures/pages/example-issue-page.md tests/render/obsidian-check.md` — the render file is expected to fail only on its FORBIDDEN section; confirm that is the only violation.
- [ ] **Step 3: Run** `tests/grasp-tools.sh && tests/skill-docs.sh` → all PASS; quote the summary lines.
- [ ] **Step 4: Update README** and research index.
- [ ] **Step 5: Commit** `docs: README for visual pages, setup, update and ClickUp`. Ask before pushing (check `gh auth status` shows `junrillg` active first).
