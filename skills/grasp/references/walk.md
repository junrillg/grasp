# walk: a short guided session on one page

`/grasp walk ISSUE|FEATURE|NAME`. A person started it, and they are there. Reading a page does not
build understanding; answering questions about how the code works does. So a walk shows real
code, asks one question at a time, says right or names the gap, and writes the person's own
answers on the page. It is for the page's owner. It never changes code, commits or tracker cards.

Rules that hold for the whole walk:

- **Never score.** No grade, no praise, no comparison, no "passed". `N of M right` on the page is
  a record of where the gaps are, nothing more.
- **Never block.** A walk gates nothing: not a merge, not a card, not the next run. The person can
  `skip` any question and stop at any point.
- **Never rewrite the person's words.** The only change is HTML escaping (`&` `<` `>`, and a line
  break as `<br>`). No fixing, shortening or translating. An answer that holds a token, a key or
  personal data is the one exception: leave that part out, write `[removed]`, and say so.
- **One question at a time.** Never show the next question, or any model answer, before the
  person has answered.
- **Only real lines.** Code reaches the conversation only through `grasp-tools snippet`. Never type
  a code block from memory. Check every model answer against the lines it is about.

## 1. Find the page and check it first

1. Find it in the docs folder (`.grasp.md`, else `docs/how-it-works/`): an issue page
   `KEY-*.md`, a feature page `features/NAME.md`, or the page `NAME.md` that `explain` wrote.
   More than one match: ask which. None: say so, point at `/grasp ISSUE` or `/grasp explain`,
   and stop. A walk never writes a page that does not exist. A page that lives in Notion is read
   and edited with the Notion tool; the fold is the same.
2. The page must be at standard 2: its status line holds `Standard: 2` (or `Standard: 2 short`).
   Then run `grasp-tools sync --only KEY` (`NAME` for a feature or explain page) and read its row.
   `stale` or `below-standard` in the states: say so in one line and offer `/grasp repair KEY`
   first. Walk only after a yes, and only after the repair. With no `sync` in this install, check
   the status line by hand and say the page's age was not checked.
3. A page that shows `Not pinned yet:` (its `Checked against:` head reads `uncommitted` and its
   walkthrough has no code) cannot be walked. Say so, and point at `/grasp repair NAME --only code`
   after the commit. Stop.
4. Read the `Walk:` field of the status line (on a feature page, the `Verified at` line).
   - `not walked`: go on.
   - `walked DATE, ...` or `partly walked ...`: ask once, "This page was walked on DATE. Walk
     again? The earlier answers are replaced." On no, stop.
5. Read the page's `## How it works`, its `## Ideas this leans on` (`## Concepts` on a feature
   page), and the code sub-page `KEY-NAME-code.md` when there is one. Read `## Reader` in
   `.grasp.md`, so a question is not pitched at what the person knows well.

## 2. Choose 5 to 7 questions

Take them in the order of "How it works", so the walk follows the request through the code. Use
these kinds, and mix them:

| Kind | Asks |
| ---- | ---- |
| Predict | What does the next step do with this input? |
| Trace | Where does this value come from, and where does it go? |
| What breaks | What happens if this call fails, or this value is missing? |
| Why this | Why this way, and not the other option? |

One question is always about the design idea: name the pattern (the page's first idea) and ask
what it buys here, in this code. Do not ask for a definition. Ask about this code.

Read the page and its code for the answers before you start. Write each model answer now, in one
to three lines, and check it against the real lines.

**An issue page** is walked on the pinned code. Take the lines from the `grasp:snippet` markers
on the code sub-page (repo, file, lines and rev are in the marker). A short page has no code
sub-page: take the changed files in `## Every changed file` at the `HEAD` of its
`Checked against:` line. When the page holds a `Changed since by:` line, say in one line, before
the first question, which later issues touched this code, and that the lines shown are as this
change left them.

**A feature page** is walked on the code today: the paths in its code walkthrough, at the
current `HEAD` of each repository. Ask about what the feature's issues share (the listed issues
sit between `grasp:issues:start` and `grasp:issues:end`), and follow one request across them,
issue by issue, from where it enters to where it ends.

## 3. Ask, one at a time

For each question:

1. Show the real lines.
   `grasp-tools snippet [--repo DIR] [--rev REV] FILE START END` (`REPO` in `Checked against:` is a
   folder name; find the folder with `grasp-tools projects`, else ask once). For a predict
   question show the lines up to the step, never the line that answers it. Show at most about 15
   lines.
2. Ask the question in one or two sentences, numbered `1 of 6`. Name the file and lines. Say that
   `skip` moves on and `stop` ends the walk.
3. Wait. Do not hint and do not fill in for the person.
4. Answer in plain words, in this form:
   - **Right:** `Right.` and, only when it helps, one line on why.
   - **Gap:** name what was right first, then the gap, in two to four lines tied to the shown
     lines (file and line numbers). "I don't know" is a gap with nothing right to name. Never
     write "wrong" or "incorrect". Never show the model answer as a lecture; the gap lines are
     the model answer, shortened.
   - **skip:** say `Skipped.` and ask the next question. A skipped question is not a gap.
5. A question from the person mid-walk gets a short answer, then the same question again.

`stop`, or any clear sign the person is done, ends the walk and goes to step 4 with what was
answered. Stopping early is fine and is saved. With nothing answered, write nothing and say so.

## 4. Write it down

Do all of this after the last answer, in one pass, with the person's exact words.

1. **The fold.** Replace what is between `<!-- grasp:walk:start -->` and `<!-- grasp:walk:end -->`
   with the fold below, markers kept. HTML only: no Markdown, no code fence, no fold inside it.
   Give lines as `<code>file lines 10-24</code>`, not as a code block. The date is today's.

   ```html
   <!-- grasp:walk:start -->
   <details><summary>Your walk: 2026-11-27, 5 of 6 right, 1 gap</summary>
   <p><b>1. Predict.</b> QUESTION (<code>src/cart/total.ts lines 10-24</code>)</p>
   <p><b>You:</b> THEIR WORDS</p>
   <p><b>Right.</b> or <b>Gap:</b> TWO TO FOUR LINES</p>
   <p><b>Model answer:</b> ANSWER</p>
   </details>
   <!-- grasp:walk:end -->
   ```

   Kinds are written `Predict`, `Trace`, `What breaks`, `Why this`. A skipped question has
   `<p><b>Skipped.</b></p>` in place of the You and Right lines. `N of M right` counts answered
   questions only. A walk stopped early reads `Your walk: 2026-11-27, stopped after 3 of 6, 2 right,
   1 gap`.

2. **The status line.** Set `Walk:` to `walked YYYY-MM-DD, N of M right`, or
   `partly walked N of M` when the walk stopped early (N answered, M planned). A feature walk sets
   it on the feature page only; the pages of its issues are not touched.
3. **The reader profile.** For each gap, add one row to the gap table under `## Reader` in
   `.grasp.md`: the idea as a person could search for it, the page's key (`SHOP-12`), the date.
   Skip a row already there for the same idea and key. No `.grasp.md`: skip and say so. No
   `## Reader` section: add it from [grasp-config.md](../templates/grasp-config.md), both lists
   empty.
4. **A lesson for each gap.** Add one idea under `## Ideas this leans on`, written as
   `- **Idea · NAME:**` in the fixed ideas format of
   [issue-page.md](../templates/issue-page.md), with one specific video and one page to read, chosen
   and checked by "One specific video and one page to read" in
   [notebook.md](notebook.md) (`grasp-tools check-link` on every video). When the page already
   has an idea for that gap, add nothing and say which one it is. Walk ideas may take a page past
   its usual limit of 3 ideas; say so in the report. On a feature page the lesson goes under
   `## Concepts`, in that page's own format, with the same checked video and page.
5. **Check.** Run `grasp-tools lint-page PAGE` on the page. Fix what the walk added (a link with
   no check date, a visible line that is too long: shorten your own new line, never the person's
   words). Report anything else it prints.

Leave the files uncommitted unless the project's rules say a run commits its pages.

## A rewritten page keeps its walk

Any run that rewrites a page (`page`, `explain`, `repair`) first copies the old file aside, then
writes the new one, then runs `grasp-tools keep-walk OLD NEW`. It copies the walk fold and the
`Walk:` field of the old page into the new one and prints `kept`, or `no walk to keep`. Exit 1
means the new page has no walk markers; add them from the template and run it again. Never
finish a rewrite that lost a walk.

## Report

At most 8 lines: how many answered, how many right, the gaps by name (one short phrase each),
the lessons added, which files changed, and anything that did not run.
