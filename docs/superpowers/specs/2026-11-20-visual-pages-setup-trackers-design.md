# Visual pages, skill setup and tracker coverage

Date: 2026-11-20 · Status: design, awaiting approval

## Intent

A developer who lets an AI agent build an issue must still understand, at a glance, what was
planned, what was built, the decisions, how it fits the architecture and what blocked it. Today
grasp's pages are text-led, grasp cannot attach itself to a project's own workflow skills, and
its tracker support misses ClickUp and is never proven against a real tracker. This design fixes
all three.

The owner does not have time to read long pages. Pictures carry the page; text sits beside each
picture and the detail is folded away, there when needed for reference.

## Goals

1. **Visual-first pages.** Every visible block is a picture (diagram, screenshot) with one or two
   lines of caption. All other detail sits in a toggle directly under the picture it explains.
   Pages render correctly in Obsidian (core, no plugins) and on GitHub.
2. **Code walkthrough, screenshots, decisions, blockers, learning links** on every page that
   has them, each grounded in the research below.
3. **`/grasp setup`** finds this project's own skills that overlap grasp (work an issue, verify,
   review, resolve), lets the user multi-select which to connect, adds a marked block that makes
   each one call grasp for the learning page only, and records the mapping.
4. **`/grasp update`** pulls the latest grasp and refreshes the block in every connected skill.
5. **Tracker setup and test.** Setup detects, asks, remembers and live-tests the project's
   tracker. Supported: Jira, GitHub Issues, ClickUp, Linear, GitLab, "other" (any connected tool
   or CLI), plain text.

## Non-goals

- grasp does not take over a connected skill's job. The connected skill keeps doing its own work.
- No global (user-level) skill scanning. Project scope only: `.claude/skills/`, `.agents/skills/`.
- No automatic refresh of old screenshots. A screenshot is a dated snapshot of one change.
- No scheduled link crawl. Links are checked when a page is written or patched.
- No LinkedIn Learning API use (needs an organisation licence and admin keys).

## Anti-goals (a failure even if it works)

- A page that needs reading top to bottom to understand. If the pictures and captions alone do
  not tell the story, the page failed.
- A toggle that shows unfolded in Obsidian, or a hidden model answer that is visible.
- grasp editing a user's skill outside its own marked block, or posting to a tracker in a test
  without a yes.
- A learning link that is dead, guessed or off-topic.
- Claiming a tracker works when it was not read live in this project.

## Constraints

- Plain Markdown that renders in Obsidian and GitHub (Obsidian is the primary reader; see the owner's rules: standard relative
  links, no wikilinks, attachments in `./assets` beside the doc).
- Agent Skills format: `SKILL.md` stays a short router; detail in one-level `references/`.
- Every subcommand appears in the `help` block; documented flags must exist in the body.
- Works for both installs: symlink via `install.sh` and the Claude Code plugin.
- Token-cheap: one subagent per page write, diff in, patch out (existing budget rules hold).
- Never handle or print tracker tokens.

## Research behind the page design

From `docs/research/learning-pages.md` and the 2026-11-20 visual-docs research (to be committed
as `docs/research/visual-pages.md`):

| Page rule | Source |
|---|---|
| Verdict visible, bulk folded | CodeRabbit walkthroughs fold by default |
| Diagram type follows the change: sequence (API / multi-service), ER (schema), flowchart (logic), none (trivial) | Greptile review docs |
| Caption directly above each picture; headings that state conclusions | Mayer spatial contiguity; NN/g layer-cake scanning |
| Diagram steps numbered (`autonumber`), walkthrough uses the same numbers | Mayer signalling; VS Code CodeTour step format |
| Before / After screenshot table; "No visible change" otherwise | Common PR-template convention |
| Short code excerpt + commit-SHA permalink (GitHub never expands permalinks in `.md`) | GitHub docs |
| Toggle titles state the conclusion; one level of folding; blockers and risks never folded | NN/g accordions and progressive disclosure |
| No decorative images; drop a section with nothing true to say | Mayer coherence |
| At most 3 learning links, live-checked, paywalls labelled | Tested 2026-11-20 (YouTube oEmbed, LinkedIn Learning pages) |

## Approaches considered

- **A. Instructions only.** Smallest change. The exact steps (block replace, version stamp,
  toggle form) depend on the agent getting them right every time; slips are silent.
- **B. Instructions plus one dependency-free helper script. Picked.** Exact, testable steps move
  into a shell script that ships inside the skill; the agent keeps the judgement calls. Only way
  to back the confidence bar for the mechanical parts.
- **C. Separate skills.** More install surface, more for `update` to track, dilutes the one-command
  experience. Dropped.

## Design

### 1. The page

Visible, top to bottom (about 150 words of text plus pictures):

```
Status: built · issue · PR
> [!WARNING] blocker, one line            (only when blocked; never folded)
In one line: what someone can do now

caption ── [ Where it fits: flowchart, this issue highlighted ]
           ▸ Why, and what we're not doing
caption ── [ Before | After: screenshot table ]   (UI changes only)
           ▸ How to check it yourself
caption ── [ How it works: diagram, type per change, numbered ]
           ▸ Code walkthrough: ① ② ③ excerpts + permalinks
           ▸ All files touched
caption ── [ Decision: small picked-vs-rejected diagram ]
           ▸ Why, and what it costs
▸ Plan vs actual   ▸ Blockers met   ▸ Evidence   ▸ Learn more (≤ 3 links)
Explain it back: question   ▸ Model answer
```

The before half (step 3) uses the same layout: expected flow instead of screenshots, the plan's
decision diagram, predictions visible while `planned` or `building`, folded once `built`.

**Toggle form (Obsidian-safe).** Every toggle is one HTML block: `<details><summary>…</summary>`
with **no blank lines** inside and **HTML-only** content (`<p>`, `<br>`, `<a>`, `<code>`,
`<pre>`, `<ul>`). No Markdown, Mermaid or code fences inside a toggle. Code in a toggle goes in
`<pre>` (no highlighting). Diagrams always stay visible, outside toggles. This form is gated by
the Obsidian render test (section 5) before the template changes; the current template's note
claiming Markdown inside `<details>` works in Obsidian is removed.

**Screenshots.** After-only by default, captured with Playwright's CLI
(`npx playwright screenshot --viewport-size=1280,800 URL file`) against the app started with the
`.grasp.md` run command. "Before" reuses an issue attachment image when one exists. Saved to
`assets/KEY-after.png` beside the page, captioned with commit SHA and date. The main thread reads
the image once to confirm it shows the right screen. No UI change: "No visible change", no
capture. A login-protected screen: ask once for test credentials handling (never store them in
`.grasp.md`); otherwise skip and say so. Playwright missing: offer to skip; never install without
a yes.

**Learning links** (in "Learn more"): concepts the change actually relies on, named in the plan
or diff. Order: official docs, one free video, one LinkedIn Learning course (only when
`.grasp.md` says `linkedin learning: yes`). Kept only if `grasp-tools check-link` passes at write
time; the stored title and channel come from the check, never invented; paywall label and
"checked YYYY-MM-DD" after each. Search queries hold only the concept name, never project or
issue text.

### 2. `grasp-tools` helper

`skills/grasp/bin/grasp-tools`, POSIX-leaning bash, needs only `bash`, `sed`, `awk`, `curl`.
Called by path relative to the skill directory. Subcommands:

| Command | Does |
|---|---|
| `connect SKILL_DIR STEP` | Append or replace the block between `<!-- grasp:start v=X step=S -->` and `<!-- grasp:end -->` at the end of `SKILL_DIR/SKILL.md`; record the row in `.grasp.md`. Never touches text outside the markers. |
| `disconnect SKILL_DIR` | Remove the block and the row. |
| `status` | List connected skills: path, step, block version vs current, missing/renamed. Exit non-zero if any stale or missing. |
| `refresh [SKILL_DIR]` | Re-write stale blocks to the current version (all when no arg). |
| `check-link URL` | YouTube: oEmbed must return 200; print title and channel. LinkedIn Learning: GET with redirects must end 200 on a `/learning/` URL; print the final URL. Other: 200. Anything else exits non-zero. |
| `lint-page FILE` | Fail on: blank line inside `<details>`, Markdown/fence/Mermaid inside `<details>`, nested `<details>`, `[[wikilinks]]`, `> [!X]-` foldable callouts, `==highlight==`, absolute or remote image links, a blocker/warning inside a toggle. |
| `version` | Print the grasp version from `skills/grasp/VERSION` (kept in step with `plugin.json`; a test checks they match). |

**Staleness** follows the block, not the release: the start marker carries `b=N`, a block-format
number bumped only when the block text changes. A grasp release that leaves the block alone
creates no diffs in connected skills. `v=` records which release wrote it, for information.
`install.sh --copy` also writes `skills/grasp/.source` (the repo path) so `update` can re-copy.

`STEP` is one of `work`, `verify`, `review`, `resolve`. Tests: `tests/grasp-tools.sh`, a plain
bash runner over fixture skills and pages (no bats). `check-link` tests run against a local stub
by default and live only with `--live`.

### 3. The connection block and `/grasp page`

A new subcommand, `/grasp page ISSUE|PR [--step work|verify|review|resolve]`, writes or patches
the issue's learning page from the current state (issue, branch diff, PR, any verify results in
the conversation) and does nothing else: no code, no commits, no tracker writes. It is what the
block calls. Block text (stamped with version and step):

```
<!-- grasp:start b=1 v=0.2.0 step=review -->
## Learning page (grasp)
When this skill has finished its own work, run `/grasp page <issue or PR> --step review`
so the issue's learning page shows what was done. Skip if grasp is not installed.
<!-- grasp:end -->
```

One call per block. `/grasp page` decides the half from state: no branch diff and no PR yet
means the before half; otherwise the after half (writing the before half first if the page has
none). Step mapping: `work` → before or after half by that rule; `verify` → after
half; `review` and `resolve` → patch the sections the PR or fixes touched (existing rules in
`references/review.md`).

### 4. `/grasp setup` and `/grasp update`

`setup` replaces today's implicit first-run setup and still runs automatically when `.grasp.md`
is missing. Re-running it edits the existing file. Steps, one question at a time:

1. **Tracker.** Detect from git remote, connected tools (Atlassian, ClickUp, Linear, GitHub,
   GitLab), CLIs (`gh`, `acli`, `glab`, `az`) and keys in recent branch names. Confirm or pick.
2. **Tracker test.** Ask for one real issue; read title, body, comments and one attachment;
   show the result for confirmation. Check write permission without posting; offer a real test
   comment only on a yes. Save tracker, reader, project, `tested: YYYY-MM-DD ok|failed (part)`.
3. **Checks and app.** Lint, test, build commands; app run command and URL for screenshots.
4. **Docs location.** As today: confirm `docs/how-it-works/` or the existing router's folder.
5. **Learning links.** Ask whether the team has LinkedIn Learning.
6. **Skills.** Scan `.claude/skills/*/SKILL.md` and `.agents/skills/*/SKILL.md` (excluding grasp
   itself); read name, description and headings; propose a step for each that overlaps; present
   a multi-select (AskUserQuestion, `multiSelect: true`). Show the block diff for the picked ones,
   then `grasp-tools connect` each on yes.

`.grasp.md` gains:

```
## Connected skills
| skill | step | grasp version |
| .claude/skills/work-issue | work | 0.2.0 |

## App
- run: {npm run dev}
- url: {http://localhost:3000}

## Learning
- linkedin learning: {yes | no}
```

and the tracker section gains `tested:`.

`update`: detect the install. Symlink: `git -C <repo> pull --ff-only`, report the new version.
Plugin: tell the user to run `/plugin marketplace update grasp` (the agent cannot run it) and
continue once they confirm. Copy install: re-run `install.sh --copy`. Then `grasp-tools status`;
for stale blocks show the diff and `refresh` on yes; for a missing or renamed skill ask to
re-point or disconnect.

On any later run, a tracker read that fails says which part failed and offers to re-run only
the tracker test.

**Existing pages.** Any write that patches an old page also converts its toggles to the
Obsidian-safe form (mechanical; content unchanged). `lint-page` runs on every page written or
patched, never on untouched pages. No one-off migration.

**Old `.grasp.md` files.** A section missing from a 0.1.0 file (`tested:`, `App`, `Learning`,
`Connected skills`) is asked for the first time a run needs it, then saved. Setup is not forced.

**Notion.** `--notebook notion` gets the same layout: Notion toggle blocks (which hold Mermaid
and code natively), screenshots uploaded with the Notion file tool. `lint-page` is Markdown only.

### 5. Obsidian render test (gate before the template changes)

Write `tests/render/obsidian-check.md` with every construct the new page uses: each toggle form
(including the forbidden Markdown-inside form, labelled), `<pre>` code in a toggle, Mermaid
flowchart and sequence with `autonumber`, the five alerts, a screenshot table with a relative
image, a `diff` fence, a relative `.md` link. Claude opens it in the Obsidian app (reading view and live preview) with the computer-use tool,
and on GitHub via a pushed branch or `gh api /markdown`; if computer-use is unavailable the owner
opens it and reports. Screenshot both, keep only constructs that render correctly in both. `lint-page` forbids the
rest. Results recorded in `docs/research/visual-pages.md`.

**If HTML toggles do not fold in Obsidian (owner's decision: Obsidian wins).** Switch every
toggle to Obsidian's foldable callout, `> [!info]- <conclusion>`, which folds in Obsidian and
holds Markdown, Mermaid and code natively. GitHub then shows those as open quote blocks with a
`[!info]-` marker; that is accepted. `lint-page` flips accordingly: it requires the callout form
and forbids `<details>`, except the explain-back model answer, which must stay hidden in both and
uses whichever form the test proved folds in Obsidian.

### 6. Trackers

`references/trackers.md` gains:

- **ClickUp:** forms `86abc123` (task id), custom ids like `DEV-42`, `app.clickup.com/t/...`.
  Reader: the ClickUp MCP tools; otherwise paste. A custom id is ambiguous with Jira/Linear keys:
  `.grasp.md` decides; unset means ask.
- **Azure DevOps** (`az boards work-item show --id N`) as a named "other".
- **Other:** any connected MCP tool or CLI that can return title, body, comments and
  attachments; setup records the exact reader. Fallback: pasted text.

Every reader must produce the existing intake contract. Confidence comes from the live setup
test in each project; trackers not tested live are reported as "not tested in this project".

## Decided by the owner

- Connected skills keep their own job and call grasp only for the learning page.
- Tracker is chosen, remembered and live-tested during setup.
- Screenshots: grasp runs the app; after-only, most token-efficient path.
- Visible = pictures plus short captions; everything else in toggles under its picture,
  including the code walkthrough.
- Must render in Obsidian.
- Approach B.
- If the Obsidian render test fails for HTML toggles, Obsidian wins: foldable callouts, GitHub
  shows them open.

## Calls made by Claude (check these)

- Marked block at the end of the skill file, with version and step in the start marker.
- Mapping lives in `.grasp.md` (committed, shared by the team).
- New `/grasp page` subcommand as the connection point.
- Toggles HTML-only with `<pre>` code (no highlighting inside folds), pending the render test.
- Write permission is checked without posting; a real test comment only on yes.
- Plain bash test runner, no bats.
- Version bump to 0.2.0.

## Left to the builder

Exact wording of help text and references, fixture contents, the precise skill-overlap heuristic
(name, description, headings), and how `lint-page` detects Markdown inside an HTML block.
