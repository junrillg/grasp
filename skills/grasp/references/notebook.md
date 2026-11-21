# Notebook: pages, layout, token budget

Detail for steps 3, 6, 7 and `page` in [SKILL.md](../SKILL.md). Goal: someone on the team can
read one page in under five minutes and explain what was built, how, and why, without opening
the code. The overview pages (app map, feature pages, workspace map) are in
[overview.md](overview.md); run records are in [records.md](records.md).

## Layout

One space per project, set in `.grasp.md`:

```
<Project>: how it works          parent page
  App map                        one page: the whole app, its core features, how they connect
  Features                       a table: issue, what, status, pull request, page
    Feature name                 a page for each larger core feature: how it works today
    KEY: short name              one page per issue, before half + after half
  Run records                    a table: every agent task, newest first
    YYYY-MM-DD: short name       one small page per task
  Decisions                      one line per decision, newest first
  Glossary                       one line per domain word
```

Three kinds of page, three questions: the app map and feature pages answer "how does it work?",
an issue page answers "what did this change do and why?", a run record answers "what did the
agent do?". Read in that order, widest first.

**Markdown** (default): the layout lives in the repository's root `docs/` folder, so the pages
travel with the code, show up in code review, and open as an Obsidian vault (`docs/` is the
vault root) as well as on GitHub and in a static doc site:

```
docs/
  README.md                      the docs router; one row per page below
  how-it-works/
    README.md                    the parent: what each page is, in reading order
    app-map.md
    workspace-map.md             only at the top of a workspace
    decisions.md
    glossary.md
    features/
      README.md                  the Features table
      feature-name.md            a page for each larger core feature
      KEY-short-name.md          one page per issue
      assets/                    images for the pages, KEY-what.png
    runs/
      README.md                  the table of run records, built by grasp-tools record-index
      YYYY-MM-DD-short-name.md   one page per agent task
```

The folder is the one confirmed with the user at setup and saved in `.grasp.md`; never write
somewhere else without asking. If `docs/` already has its own layout or router, fit into it and
say where. **The router:** a project's `docs/README.md` is how people and agents find a page.
When it exists, add one row per new page (a question in the left column, the link in the
right). When it does not, create it on the first write with the pages above, after asking.

**Markdown that renders everywhere.** Obsidian, GitHub and static sites (VitePress, MkDocs)
share only plain Markdown, so the pages use only that:

- **One paragraph, one line.** Never wrap prose or a list item at a fixed width: Obsidian shows
  every newline inside a paragraph as a line break, so wrapped text reads as ragged short lines.
  (These skill files are wrapped; pages are not.)
- Standard relative links with the `.md` extension, `[App map](../app-map.md)`. Never
  `[[wikilinks]]`, `![[embeds]]`, block refs, `==highlight==` or `%%comments%%`.
- Diagrams as ```mermaid fences. In a flowchart, quote every node and edge label that holds
  `( ) : / [ ]` (`A["GET /orders"]`, `-->|"step 7: record"|`); sequence diagram messages take no
  quotes. Validate each one (a Mermaid validator tool if connected, otherwise the project's doc
  build) before saying done. With neither, `lint-page` still checks the diagram type and its
  quotes: say in the report that the diagrams were not rendered.
- Images in an `assets/` folder beside the page, linked `![what it shows](assets/KEY-what.png)`.
  Never hotlink an image from a tracker, Notion or a signed URL: those links expire.
- Notes as GitHub alerts (`> [!NOTE]`, `TIP`, `IMPORTANT`, `WARNING`, `CAUTION`); Obsidian shows
  them as callouts. Never Obsidian's foldable callouts (`> [!info]-`): GitHub shows them open
  with a stray `[!info]-`.
- Toggles as one HTML block (see "Toggles" below).
- Status as a word (`Status: built`), not a colour. No front matter unless the doc site needs
  it. Lowercase file names joined with `-`.
- If the repository ships a doc site build, run it after writing: it catches broken links.
- After every write or patch, run `grasp-tools lint-page PAGE` (the helper in the skill's `bin/`
  folder) on each page you touched, never on untouched pages. Fix every line it prints: a toggle
  that won't render, a link to a file that isn't there (`dead-link`), a diagram type outside the
  tested ones (`mermaid-type`), an unclosed quote in a diagram (`mermaid-quote`), prose wrapped
  by hand (`hard-wrap`), or a page git would silently skip (`git-ignored`). It prints nothing when the page is clean.

**Notion** (`--notebook notion`, needs a Notion tool): the same layout as pages. Create the
parent and children on first run and save their IDs in `.grasp.md`. Edit with targeted updates
(`update_content` or equivalent); never replace a whole page. Folded answers use Notion's
`<toggle>`. Mermaid goes in a ```mermaid code block, which Notion renders. Use the same layout
and section names as the Markdown page; Notion toggles may hold Mermaid and code. Upload
screenshots with the Notion file tool. `lint-page` is for Markdown only. Run records stay in the
repository as Markdown even with a Notion notebook: the instruction block, the index and
`record-check` all work on files.

**Off**: no learning page; still ask the prediction and explain-back questions in chat. The run
record is still written: it is the logbook, not a lesson.

`review` and `resolve` also write to the issue page; see [review.md](review.md).

One issue, one page. A later issue on the same feature patches that page and adds its link;
never a second page. Bugs get no page of their own: add one line in the "Plan vs actual" toggle
on the page of the feature they touched, or skip when there is none. Whatever a task is and
however small, it still gets its run record ([records.md](records.md)): that is where a bug fix
or a three-line change is written down.

## Page shapes

- Issue page: [templates/issue-page.md](../templates/issue-page.md). One layout for both halves:
  the before half fills the sections marked (before), the after half patches them and adds the
  rest. About 150 words of visible text per half; the rest is folded.
- App map: [templates/app-map.md](../templates/app-map.md). Under about 1,000 words.
- Feature page: [templates/feature-page.md](../templates/feature-page.md). How one core feature
  works today; patched when an issue changes it.
- Workspace map: [templates/workspace-map.md](../templates/workspace-map.md). Only at the top of
  a workspace.
- Run record: [templates/run-record.md](../templates/run-record.md). Five fixed lines per task.

The page is read by scanning, not top to bottom. If its pictures and captions alone don't tell
the story, it has failed.

Rules for every page:

- **Picture first, caption above it, detail folded under it.** Each section is one caption line,
  one picture (diagram or screenshot) and its toggles. Section names, in order: Where it fits,
  Before and after, How it works, Decision, Blocker, Predict, Learn more, Explain it back. Drop
  a section that has nothing true to say.
- **Visible, never folded:** the status line, "In one line", every caption and picture, any
  blocker or risk (`> [!WARNING]`), the explain-back question.
- Mermaid by default: it costs only its text and can be patched. The issue's box is highlighted
  in the "Where it fits" diagram (`style X fill:#fde68a`) and reuses the app map's node names.
- Plain words. Every claim about what was built links to the pull request or a file; every
  "works" points to the evidence from verify.
- Mark built, not built and blocked honestly.
- No secrets, personal data or text copied from client documents.

## Toggles

Tested in Obsidian (Reading view and Live Preview) and on GitHub (the notes are
`docs/research/visual-pages.md` in the grasp repository). A toggle is **one HTML block**:

```html
<details><summary>Refreshing early avoids a failed request</summary>
<p>A retry still fails the first request after expiry.</p>
<pre><code>if (expiresAt - now &lt; FIVE_MINUTES) await refresh();</code></pre>
</details>
```

- **No blank lines** between `<details>` and `</details>`: a blank line ends the HTML block.
- **HTML only inside:** `p`, `ul`, `ol`, `li`, `a`, `code`, `pre`, `b`, `br`. No Markdown, no
  code fences, no Mermaid: Obsidian doesn't render Markdown inside HTML. Code goes in
  `<pre><code>` with `<` written as `&lt;` (no highlighting). Diagrams stay outside, visible.
- **The title states a conclusion** ("Why a queue beats a cron job here"), never "Details" or
  "More". The reader decides from the title alone whether to open it.
- **One level only:** never a toggle inside a toggle.
- **Never fold a blocker or risk.** The one exception to "conclusion titles" is the explain-back
  answer, titled `Model answer` so it doesn't give the answer away.

## Diagram type follows the change

| The change is mostly | Diagram in "How it works" |
| -------------------- | ------------------------- |
| An API call or a flow across services | `sequenceDiagram` with `autonumber` |
| A schema or data model change | `erDiagram` with only the tables touched |
| A class hierarchy | `classDiagram` with only the classes touched |
| Logic or a decision inside one place | `flowchart` |
| Trivial (copy, config, a one-line fix) | none: drop the picture, keep the caption |

A flowchart is `LR` only when it is a short chain (up to about 5 boxes in a row, no `subgraph`);
otherwise `TB`. Obsidian fits a diagram to the page width, so a wide one renders with text too
small to read, while a tall one stays full size.

The code walkthrough numbers its steps to match the diagram's numbers, so step 3 in the toggle is
arrow 3 in the picture. Lines in `<pre><code>` don't wrap: keep each under about 70 characters.
Each step: one line on what it does, a commit-SHA permalink to the lines
(`https://github.com/OWNER/REPO/blob/SHA/path#L10-L14`; GitHub never expands these inside `.md`
files, so add the excerpt), and 3 to 8 lines of the real code in `<pre><code>`. At most 5 steps.
Quote flowchart labels that hold `( ) : / [ ]`, and validate each diagram as "Markdown that
renders everywhere" says.

The before half's "How it works" shows the expected flow; the after half replaces it with what
was built and moves the expected flow into "Plan vs actual" only when they differ.

## Screenshots

Only for changes someone can see. After-only by default, the cheapest path:

1. Start the app with the run command in `.grasp.md` (`## App`). No run command yet: ask once and
   save it.
2. Capture: `npx playwright screenshot --viewport-size=1280,800 URL assets/KEY-after.png`, from
   the page's folder. Playwright missing: offer to skip; never install it without a yes.
3. Read the PNG once to confirm it shows the right screen. Retake once if not, otherwise skip.
4. Caption it `After, at <short sha>, YYYY-MM-DD`.

"Before" comes from an image attached to the issue when there is one (download it into
`assets/KEY-before.png`; never hotlink); otherwise write "Not captured". No visible change: write
"No visible change" as the caption and drop the table. A screen behind a login: ask once how to
sign in for the test (never store credentials in `.grasp.md` or the page); otherwise skip and say
so. Screenshots are dated snapshots: never refresh old ones automatically.

## Learning links

"Learn more" holds at most 3 links, on concepts the change actually relies on (named in the plan
or the diff). In this order: the official docs, one free video, and one LinkedIn Learning course
only when `.grasp.md` says `linkedin learning: yes`.

- Search with the concept name only, never project, client or issue text.
- Keep a link only if `grasp-tools check-link URL` prints `ok`. Use the title and channel it
  prints for YouTube and the final URL it prints for LinkedIn Learning; never invent a title.
- After each link say who made it, where it lives and whether it's free or paid, and put the
  check date in the toggle title (`checked YYYY-MM-DD`).
- Links are checked when a page is written or patched, never on a schedule.

## Existing pages

A page written before this layout is converted only when a run patches it anyway: rewrite its
toggles into the one-block HTML form (content unchanged) and run `lint-page`. No one-off
migration of untouched pages.

## Illustrations

One image only when the issue brings a new domain idea that a flowchart cannot show (about one
issue in five). Generate it with whatever image tool is available (for example `codex exec` with
image generation), read the PNG before uploading, regenerate once if the text is garbled or the
idea wrong, otherwise go without. Save it to the page's `assets/` folder (Markdown) before
linking it. Never decorative images.

## App map

[overview.md](overview.md) holds the app map, the feature pages and the workspace map: what they
contain, how to explore the code for them, and how to keep them current. In short: built at
setup or with `/grasp map`, patched in step 7 only where an issue changed a core feature, a
connection, a piece, a step of the main request path, a rule or a glossary word, and never pasted
into `CLAUDE.md` or `AGENTS.md`.

## Token budget

- **One subagent per page write**: Sonnet for a new page or the app map, Haiku for a patch. The
  main thread keeps only the page path or link. For a small change whose context the main thread already
  holds (a diff of a few files), write the page inline: a subagent would cost more to brief.
- **Narrow input**: the issue note, the picked approach, `git diff --stat` and the diff of
  changed source files (not lock files, not generated files), the pull request body, the verify
  results, and the app map's diagram source. Never the repository, never a fresh research pass.
- **Patch, never regenerate**: targeted edits only. Incremental updates cost a small fraction of
  a rebuild and keep more detail.
- **Skip** the after half for a diff under about 20 changed lines that adds no behaviour; add one
  line to the Features table instead. The run record is never skipped for a task that changed
  files.
- **Load references per step**: read a reference file only when its step starts.
- **Check once**: after writing, run `lint-page`, then read the page once (fetch it for Notion) and
  confirm the title, status line, diagrams, toggles, any screenshot and the Features row are there.

## Explain-back

At close-out ask the first explain-back question, before the user opens the answer. Their reply
goes on the page under the question, in their words. Also log one conceptual question the user
asked during the run, if any, under "Questions asked": those are the moments learning happened.
Never block the run waiting for an answer.
