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
  Architecture                   one page: the design, why, what breaks first, lessons
  Features                       a table: issue, what, status, pull request, page
    Feature name                 a page for each larger core feature: how it works today
    KEY: short name              one page per issue, before half + after half
  Run records                    a table: every agent task, newest first
    YYYY-MM-DD: short name       one small page per task
  Decisions                      one line per decision, newest first
  Glossary                       one line per domain word
```

Three kinds of page, three questions: the app map, architecture page and feature pages answer "how does it work?",
an issue page answers "what did this change do and why?", a run record answers "what did the
agent do?". Read in that order, widest first.

**Markdown** (default): the layout lives in the repository's root `docs/` folder, so the pages
travel with the code, show up in code review, and open as an Obsidian vault (`docs/` is the
vault root) as well as on GitHub and in a static doc site:

```
docs/
  README.md                      the docs router: rows for the app map (or workspace map),
                                 the architecture page, the Features table and Run records, never one per issue
  how-it-works/
    README.md                    the parent: what each page is, in reading order
    app-map.md
    architecture.md              not in a small app
    workspace-map.md             only at the top of a workspace
    decisions.md                 created with the first decision and linked from this README
                                 (a workspace sub-project has no README: link it from its
                                 app map's "Features built" section);
                                 one line each: `- YYYY-MM-DD: {picked} over {rejected},
                                 because {why}. [page](features/KEY-short-name.md)`
    glossary.md                  only once the app map's Glossary outgrows the page
    features/
      README.md                  the Features table
      feature-name.md            a page for each larger core feature
      KEY-short-name.md          one page per issue (a text issue has no key: short-name.md)
      KEY-short-name-code.md     its code sub-page (not on a short page)
      assets/                    images for the pages, KEY-what.png
    runs/
      README.md                  the table of run records, built by grasp-tools record-index
      YYYY-MM-DD-short-name.md   one page per agent task
```

The folder is the one confirmed with the user at setup and saved in `.grasp.md`; never write
somewhere else without asking. If `docs/` already has its own layout or router, fit into it and
say where. **The router:** a project's `docs/README.md` is how people and agents find a page.
When it exists, it gets one row for each entry page (the app map or workspace map, the architecture page,
the Features table, Run records; a question in the left column, the link in the right), never one per issue
or feature page. When it does not, create it on the first write with the pages above, after asking.

**Markdown that renders everywhere.** Obsidian, GitHub and static sites (VitePress, MkDocs)
share only plain Markdown, so the pages use only that:

- **One paragraph, one line.** Never wrap prose or a list item at a fixed width: Obsidian shows
  every newline inside a paragraph as a line break, so wrapped text reads as ragged short lines.
  (These skill files are wrapped; pages are not.)
- Standard relative links with the `.md` extension, `[App map](../app-map.md)`. Never
  `[[wikilinks]]`, `![[embeds]]`, block refs, `==highlight==` or `%%comments%%`.
- Diagrams as ```mermaid fences. In a flowchart, quote every node and edge label that holds
  `( ) : / [ ]` (`A["GET /orders"]`, `-->|"step 7: record"|`); sequence diagram messages take no
  quotes. Validate each one (a Mermaid validator tool if connected and short in its answer,
  otherwise the project's doc build; read the verdict only) before saying done. With neither, `lint-page` still checks the diagram type and its
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
  folder) on each page you touched, never on untouched pages, and never on `AGENTS.md`,
  `CLAUDE.md`, `.grasp.md` or a `SKILL.md`: those are instructions, not pages. Fix every line it prints: a toggle
  that won't render, a link to a file that isn't there (`dead-link`), a diagram type outside the
  tested ones (`mermaid-type`), an unclosed quote in a diagram (`mermaid-quote`), prose wrapped
  by hand (`hard-wrap`), a page git would silently skip (`git-ignored`), more visible words than the page's kind allows (`too-long`: fold or cut), a diagram with more than 20 boxes (`too-many-boxes`: split it), an issue page, app map, architecture or feature page without its Concepts section (`no-concepts`; on an issue page that is `## Ideas this leans on`), an architecture page with no lesson (`no-lessons`). A Standard 2 issue page is also checked for a missing owner block (`no-owner-block`), an Asked line over 30 words (`asked-too-long`), a video link with no check date (`link-undated`), no design idea (`no-design-idea`), an idea with no video and no "No checked video yet" (`no-video`) and no code sub-page (`no-code-page`); a code sub-page for a missing file list (`no-file-list`) or walkthrough (`no-walkthrough`). It prints nothing when the page is clean.

**Notion** (`--notebook notion`, needs a Notion tool): the same layout as pages. Create the
parent and children on first run and save their IDs in `.grasp.md`. Edit with targeted updates
(`update_content` or equivalent); never replace a whole page. Folded answers use Notion's
`<toggle>`. Mermaid goes in a ```mermaid code block, which Notion renders. Use the same layout
and section names as the Markdown page, with the code sub-page as a child page; Notion toggles
may hold Mermaid and code, and `walk` works. Upload screenshots with the Notion file tool.
`lint-page`, `coverage` and `snippet-check` run on Markdown files only. Run records stay in the
repository as Markdown even with a Notion notebook: the instruction block, the index and
`record-check` all work on files.

**Off**: no learning page; still ask the prediction question in chat. The run
record is still written: it is the logbook, not a lesson.

`review` and `resolve` also write to the issue page; see [review.md](review.md).

One issue, one page. A later issue on the same feature gets its own page and patches the feature
page, never the earlier issue's page ("A snapshot and a living page"). A bug or a small change
gets a short page ("Short pages"). Whatever a task is and however small, it also gets its run
record ([records.md](records.md)).

## Page shapes

- Issue page: [templates/issue-page.md](../templates/issue-page.md), and its code sub-page
  [templates/issue-code-page.md](../templates/issue-code-page.md). One layout for both halves:
  the before half writes the first sections, the after half patches them and fills the folds.
  Target 300 visible words, `lint-page` reports `too-long` past 400. The rules are in "Standard 2".
- App map: [templates/app-map.md](../templates/app-map.md). Under about 1,000 words.
- Architecture page: [templates/architecture.md](../templates/architecture.md). How the app is
  designed and the system design ideas to learn from it. About 600 words.
- Feature page: [templates/feature-page.md](../templates/feature-page.md). How one core feature
  works today; patched when an issue changes it.
- Workspace map: [templates/workspace-map.md](../templates/workspace-map.md). Only at the top of
  a workspace.
- Run record: [templates/run-record.md](../templates/run-record.md). Five fixed lines per task,
  150 visible words at most.

The page is read by scanning, not top to bottom. If its pictures and captions alone don't tell
the story, it has failed.

Rules for every page:

- **Picture first, caption above it, detail folded under it.** Each section is one caption line,
  one picture (diagram or screenshot) and its toggles. Section names and order are the page's
  template. Drop a section that has nothing true to say, except Concepts (on an issue page,
  the owner block and the ideas), and except on a short page, which has no ideas section.
- **Long text is always folded.** Anything that needs more than two lines to explain (a concept,
  a reason, a history) gets one visible line that states the point and a toggle that holds the
  rest. A page never makes the reader scroll past a paragraph to reach the next picture.
- **Visible, never folded:** the status line, "In one line" (an issue page: "In two sentences"), the steps and their ticks while the
  status is `planned` or `building`, one line per concept, every caption and picture, any blocker or risk (`> [!WARNING]`), the owner block of
  an issue page.
- Mermaid by default: it costs only its text and can be patched. The issue's box is highlighted
  in the "Where it fits" diagram (`style X fill:#fde68a`) and reuses the app map's node names.
- Plain words. Every claim about what was built links to the pull request or a file; every
  "works" points to the evidence from verify.
- Mark built, not built and blocked honestly.
- No secrets, personal data or text copied from client documents.

## Standard 2

Every path that writes an issue page uses the same rules and templates: `/grasp ISSUE`, `page`,
`explain` and `repair`. The page is [templates/issue-page.md](../templates/issue-page.md) and,
unless it is a short page, [templates/issue-code-page.md](../templates/issue-code-page.md). Follow
them; this section holds only what a template cannot show.

- Two levels only: visible, then a fold or the code sub-page. No fold inside a fold.
- Quoted words count toward the visible limit.
- **Asked** is the card's ask in its own words, 30 words at most; a close paraphrase where the
  project's rules forbid quoting. A line with nothing true to say reads "none". Before and after
  screenshots sit in the owner block when a user can see the change.
- **Ideas:** the first is always the design idea, the architecture pattern or system design
  concept the change rests on, named so the owner can say it to someone else. Each idea is one
  visible line and a fold of 3 to 5 lines tied to this code, one video to watch and one page to
  read. Keep a link only if `grasp-tools check-link` prints `ok`; never a link that was not checked.
- **Code reaches a page only through `grasp-tools snippet FILE START END`.** Paste its output on the
  code sub-page as it is. Never type a code block or edit one.
- **Proof rows** come only from a run made in this session or from the pull request's checks.
  Anything else reads `not run here` in the result cell.
- A blocker is a visible alert at the top and is never folded. Diagram types stay as lint allows.
- **Questions asked:** a conceptual question the person asked during the understand step is logged
  as the last paragraph inside the "Why it was built this way" fold, as HTML:
  `<p><b>Questions asked:</b> ...</p>`. Leave the line out when they asked none.
- The before half is unchanged in purpose. At the pick, the attended flow writes sections 1 to 4 as
  planned, with Steps and Predict, and `--plan` stops there. Steps stay visible and are ticked
  while the status is `building`; once built they move into the "Planned and built" fold. The
  illustration rule ("Illustrations") is unchanged.
- Predict stays in the attended flow. There is no explain-back on the page or in the workflow: the
  walk replaces it. A page with no walk is not a lint failure, and the walk fold changes only when
  a walk runs. After the after half, the report ends with `Walk ready: /grasp walk KEY`; the run
  never starts a walk and never waits for one.

Before a page is called written, run these, and all three must print nothing or the count line only:

```
grasp-tools lint-page PAGE PAGE-code.md
grasp-tools snippet-check --repo DIR PAGE-code.md
grasp-tools coverage --repo DIR PAGE PAGE-code.md
```

`--repo DIR` is repeated for each repository the change touches. `coverage` without `--base`
reads each range from the page's `Checked against:` line. A short page has no code file: pass the
page alone.

## What the writer reads

The writer reads the repository, not only the diff:

- the card and its comments, and the working note if one exists
- the pull request: its body, its checks and its head or merge commit
- the diff of each repository touched, and the files around the changed lines
- the feature page, if there is one, and the app map

Do not guess a fact that one of these answers. Read each decisive file once, at the commit the page
is pinned to.

## A snapshot and a living page

- An issue page is a snapshot of one change, pinned to a commit per repository in its `Checked
  against:` line, as `REPO@BASE..HEAD` with `REPO` the repository folder's name. One range for each
  repository the change touches. `BASE` is the merge base with the integration branch. `HEAD` is the
  merge commit when the page is written after the pull request merged. Otherwise it is the pull
  request's last commit that changes anything outside the notebook folder (the last code commit).
- A later commit that only touches the notebook, the page itself included, does not move the pin.
- Its code blocks never move to a later commit.
- A feature page describes how the feature works today, so it is patched when a later issue changes
  it.
- A later issue that edits the same files does not make an issue page stale. `sync` adds a generated
  `Changed since by:` line under `Checked against:`; no writer and no person edits it.
- An issue page is stale only when code in its own pull request changed after the pin. `sync`
  decides that by comparing file contents between the pinned commit and the pull request's current
  head or merge commit, never by comparing commit ids, so neither the page's own commit nor a merge
  by itself makes a page stale.
- `repair` re-pins a page to the current commit by the same rule when it rewrites the page.

## Short pages

A bug, or a change under about 20 changed lines that adds no behaviour, gets a short page of its
own.

- The status line says `Standard: 2 short`.
- It holds "In two sentences", "For the owner", "How it works", the Proof fold and an
  `## Every changed file` list on the page itself. It has no ideas section, no "Where it fits" and no
  code sub-page.
- The three checks above still run, on the page alone.
- The Features table still gets its row, and the run record is never skipped for a task that
  changed files.

## Change map and depth

Any page about a change (an issue page's after half, an `explain` page) shows the **change map**:
the whole code base as boxes coloured by what the change did. Green is new, amber is changed, grey
is untouched, with file counts. On an issue page it is the picture under `## Where it fits`, with
this issue's parts highlighted. `grasp-tools change-map --repo DIR --base REF` prints it from git
(boxes are folders, cut further while there are more than 18); rename the boxes to the app map's
names, keep the folder in the label, and add the arrows by hand from the code. Keep its legend line
under it.

An issue page has two levels, and each works alone:

| Level | Holds |
| ----- | ----- |
| Visible | `## In two sentences`, the owner block, the change map, the ideas, the diagram and its steps. Target 300 words, lint limit 400 |
| One step down | Either a fold on the page, or the code sub-page. Never a fold inside a fold |

Short facts fold on the page: why it was built this way, planned and built, proof, what is open.
The file list and the code walkthrough go to the code sub-page. Fold detail, never cut it. A
reader who opens every fold and the sub-page has the whole change.

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
- **Never fold a blocker or risk.**

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
A repository with no remote has no permalink: name the path and lines in `<code>` with the short
commit (`cart.js#L10-L14 at ed2a932`) and no link.
Quote flowchart labels that hold `( ) : / [ ]`, and validate each diagram as "Markdown that
renders everywhere" says.

The before half's "How it works" shows the expected flow; the after half replaces it with what
was built. What differs from the plan goes in "Planned and built": the caption counts the steps
built as planned, and the table has one row per step that changed or was not done (planned, built
instead, why). A step that was not done is also the run record's Next line. Never leave an
unticked step unexplained.

## Screenshots

Only for changes someone can see. After-only by default, the cheapest path:

1. Start the app with the run command in `.grasp.md` (`## App`). No run command yet, or `run:`
   says "UI, no start command known": ask once and save it; with no answer, or no person in the
   run, write "Not captured" and go on. `run:` says "no UI": there is nothing to capture.
2. Capture: `npx playwright screenshot --viewport-size=1280,800 URL assets/KEY-after.png`, from
   the page's folder. Playwright missing: offer to skip; never install it without a yes.
3. Read the PNG once to confirm it shows the right screen. Retake once if not, otherwise skip.
4. Caption it `After, at <short sha>, YYYY-MM-DD`.

"Before" comes from an image attached to the issue when there is one (download it into
`assets/KEY-before.png`; never hotlink); otherwise write "Not captured". No visible change: write
"No visible change" as the caption and drop the table. A screen behind a login: ask once how to
sign in for the test (never store credentials in `.grasp.md` or the page); otherwise skip and say
so. Screenshots are dated snapshots: never refresh old ones automatically.

## Concepts

Every issue page, app map, architecture page and feature page has a "Concepts" section: the ideas a reader must know
to follow the page. Up to 3 on an issue page (concepts the change actually relies on, named in the
plan or the diff), up to 5 on an app map or an architecture page, one or two on a
feature page. When an issue adds or moves a piece, changes who calls whom, or picks between two
designs, one of its concepts is the system design idea behind that choice, linked to the
architecture page when it is named there.

- **One visible line per concept**: its name in bold, what it is in one plain sentence, and where
  this code uses it. That line alone must be enough to keep reading.
- **One toggle per concept** for everything longer: 3 to 8 lines that explain the idea through
  this code (not a textbook definition), then its links. The toggle title states the concept's
  point as a conclusion.
- **Nothing new** is a valid answer for a small change: write "Nothing new" and name the one idea
  already on the app map that it uses, with a link. The section stays.
- On the issue page it is written in the before half, so the plan can be judged; the after half
  corrects it if the build leaned on something else.

### Learning links

On every page but the architecture page, each concept's toggle holds at most 3 links, in this order: the official docs, one free video,
and one LinkedIn Learning course only when `.grasp.md` says `linkedin learning: yes`. A page holds
at most 6 links in all; an architecture page at most 15 (5 ideas: docs in the toggle, a video and
a course in its "Lessons" table).

- Search with the concept name only, never project, client or issue text.
- Keep a link only if `grasp-tools check-link URL` prints `ok`. Use the title and channel it
  prints for YouTube, and the final URL and course title it prints for LinkedIn Learning (an
  address that redirects prints `fail redirected FINAL`: drop it); never
  invent a title. A video title that does not name the concept is the wrong video: drop it. A
  course is wider than a video: its title must name the concept or the field it belongs to (a
  course on HTTP for the concept "status codes"). For a docs
  page it prints the final URL only: use the page's own heading as you read it when you opened
  the page, and keep no docs link you did not open.
- After each link say who made it, where it lives and whether it's free or paid, and end the
  toggle with the check date (`Links checked YYYY-MM-DD`).
- Links are checked when a page is written or patched, never on a schedule.
- Prefer the lesson a beginner can follow: the idea named in the title, explained before code, and
  not tied to a language the project does not use.
- No link found that passes: keep the concept and its explanation, and write "No checked link
  yet" in the toggle. Never a link that was not checked.

## Existing pages

A page written before this layout is converted only when a run patches it anyway: rewrite its
toggles into the one-block HTML form (content unchanged) and run `lint-page`. No one-off
migration of untouched pages.

## Illustrations

`.grasp.md` decides (`illustrations: yes` or `no`, asked once at setup; a file without the line
means ask once, then save it).

- **yes**: the app map, the architecture page, the workspace map and each issue page open with one
  generated picture that shows the idea as an everyday scene, directly under "What it is for", "In one line" or, on an issue page, "In two sentences".
  Feature pages and run records never get one.
- **no**: diagrams only.
- **An issue page's after half that changed more than about three parts** also gets the change map
  as a picture (`KEY-change-map.png`): a cutaway building, one room per part named as on the
  change map, walls in its colours (pale green new, amber changed, grey untouched), a
  three-swatch legend, outside systems in the basement or outside the walls. It sits directly
  above the change map, under `## Where it fits`: the picture is read in seconds, the diagram gives the counts.
- Generate it with whatever image tool is available. With the Codex CLI, the form that worked in
  grasp's own trial, run from the `assets/` folder: `codex exec --skip-git-repo-check -s
  workspace-write -C "$PWD" --enable image_generation "PROMPT" < /dev/null`, where the prompt
  names the file to save and says "short labels, spelled exactly, no other text" and "this
  image is one step of another agent's task, and that agent writes the task's run record: write
  none yourself and change no other file" (a second agent started in the project reads the
  block in `AGENTS.md` and would otherwise leave a record of its own; delete one if it appears).
  The `< /dev/null` matters: without it the command waits on stdin forever. It can take several
  minutes: give the command a timeout of at least five. Read the PNG before
  linking it, regenerate once if the text is garbled or the idea
  wrong, otherwise go without. Save it to the page's `assets/` folder (`KEY-idea.png`,
  `app-map.png`, `architecture.png`, `workspace-map.png`); the alt text says what the picture shows.
- **No image tool**: write the page with its diagrams, and say once in the report that the
  illustration was skipped and why. Never a placeholder, never a hotlinked or stock image.
- A picture explains; it never decorates. Short labels only, no paragraphs inside an image, and
  nothing in it that the page does not say.

## App map

[overview.md](overview.md) holds the app map, the architecture page, the feature pages and the workspace map: what they
contain, how to explore the code for them, and how to keep them current. In short: built at
setup or with `/grasp map`, patched in step 7 only where an issue changed a core feature, a
connection, a piece, a step of the main request path, a rule or a glossary word, and never pasted
into `CLAUDE.md` or `AGENTS.md`.

## Token budget

- **One subagent per page write**: Sonnet for a new page or the app map, Haiku for a patch (the
  first overview is the one exception: the subagent that explored a project writes its app map
  and feature pages, since it already holds the traces). The
  main thread keeps only the page path or link. For a small change whose context the main thread already
  holds (a diff of a few files), write the page inline: a subagent would cost more to brief. This
  line decides wherever a step says "with one subagent". Whoever writes the page also searches
  for and checks its learning links; the illustration is made by the main thread after the page
  is written and linted.
- **Narrow input**: what "What the writer reads" lists, with the diff of changed source files
  only (not lock files, not generated files), the verify results and the app map's diagram source.
  No fresh research pass.
- **Patch, never regenerate**: targeted edits only. Incremental updates cost a small fraction of
  a rebuild and keep more detail.
- **Small changes** get a short page ("Short pages"), never no page. The run record is never
  skipped for a task that changed files.
- **Load references per step**: read a reference file only when its step starts.
- **Check once**: after writing, run the three checks in "Standard 2", then read the page once (fetch it for Notion) and
  confirm the title, status line, diagrams, toggles, any screenshot and the Features row are there.
