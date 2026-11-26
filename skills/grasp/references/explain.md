# Explain: finished work with no issue, or wider than one

Detail for `/grasp explain` in [SKILL.md](../SKILL.md). The work is done. Make sure a person can
explain it without reading the code. The result is two pages in the standard 2 layout:

- `NAME.md`, the page: what, how and why, with pictures and the ideas it leans on.
- `NAME-code.md`, its code sub-page: every changed file, what people look up, what is not in git.

It needs nothing outside grasp's own folder. The page rules, the three checks, pinning, the ideas
and the pictures are in [notebook.md](notebook.md); this file holds only what `explain` does
differently or adds.

## When to use it

- **Use it** for work with no tracker issue, or wider than one issue: a setup, a pipeline, a
  migration, a whole session.
- **Exactly one issue, and its page already says it all:** say so, offer `/grasp page ISSUE`, and
  write nothing.
- **Where it sits:** `/grasp ISSUE` while building one issue, `/grasp explain` when the work is
  wider, `/grasp map` when the shape of the app changed.

## Arguments

| Argument | Type | Default | Meaning |
| -------- | ---- | ------- | ------- |
| `SOURCE` | nothing, a pull request number or URL, a branch name, or `BASE..HEAD` | the work done in this session | What to explain. Several pieces of work in the session and none named: ask which |
| `--repo` | path, repeatable | the repositories this session changed, else the current one | Where the code is. The docs may live in another repository than the code |
| `--docs` | folder | `markdown folder` in `.grasp.md`, else `docs/how-it-works/` at the root of the folder the session was started in (the workspace root when the session changed several repositories) | Where the pages go. No `.grasp.md` and no `docs/` folder there: ask |
| `--name` | slug | named after the work, in the numbering and title style of the pages already in the folder | File name of the page. The sub-page is `NAME-code.md` |
| `--lessons` | `all`, `free`, `none` | `all`; `free` when `.grasp.md` says `linkedin learning: no` | `all` allows a LinkedIn Learning video when `.grasp.md` says `linkedin learning: yes` or has no such line (or there is no `.grasp.md`). `free` drops LinkedIn Learning videos and `Course:` lines. `none` writes `<p>Lessons turned off</p>` in each idea's fold |
| `--no-image` | flag | off; on when `.grasp.md` says `illustrations: no` | Diagrams only: no illustration and no cutaway picture |
| `check PAGE` | subcommand | none | Run "Prove" on an existing page and write nothing. `PAGE` is the main page, `NAME.md`; the sub-page is `NAME-code.md`, derived from it. Given a `-code.md` file, `check` uses its main page |
| `--base` | ref, with `check` | the page's own ranges, else the integration branch | What the work is compared with. See "`check PAGE`" |

## Rules

- **Only what happened.** Every "done" points at a file, a commit or a command that ran. Say plainly
  what is not finished, not proven or not live. Mark what was reconstructed from records, a pull
  request or a diff, with the word `reconstructed` on the line or row it applies to.
- **Cover everything, then make it easy.** The sub-page is complete and the page is short. Fold
  detail, never cut it.
- **Never put on a page** a secret, token, personal data, client text or a raw log. Names of
  settings and variables only, never values.
- **Never name a project, client or issue** in a web search or an image prompt.
- **No lesson without a live check**, and never claim you watched one ([notebook.md](notebook.md),
  "One specific video and one page to read").
- **Never change code.** A bug found while explaining is reported, not fixed.
- **Never commit or push** without the project's standing rule or a yes. Stage only your own files.
- A project's own docs rules (file names, links, folding) win over this file.

## Workflow

### 1. Find the ground

Read `.grasp.md` (walk up from the current folder; `--config PATH` for the helper), the docs
router, and the project's writing rules. The docs may be another repository than the code: note
both. Settings used:

| `.grasp.md` line | Used for |
| ---------------- | -------- |
| `markdown folder` | Where the pages go. `--docs` wins |
| `docs router`, `docs repo` | Where to add rows, and which repository the docs belong to |
| `run records` | The folder for the run record |
| `linkedin learning` | `no` means `--lessons free` |
| `illustrations` | `no` means `--no-image` |
| `integration branch` | The base when no other is named |
| `Voice` | How the pages read |
| `## Reader` | Which ideas to teach |

`target: notion` or `off` is about issue pages: `explain` pages still go to Markdown, unless the
person names another place. No `.grasp.md`: use the defaults, offer `/grasp setup` once in the
report and never run it (this overrides the first-run rule in SKILL.md). The helper is
`bin/grasp-tools` in grasp's folder, run from the folder that holds `.grasp.md`.

### 2. Gather the facts

- **The session first:** what was asked, each decision and what was rejected, commands and their
  result lines, every problem and its fix, what is left.
- **Git, per repository:** the changed files, committed, uncommitted and untracked, and the diff
  of each. `SOURCE` decides the range: a pull request (its body, checks and head or merge commit),
  a branch against the merge base with the integration branch, `BASE..HEAD` as given, or this
  session's commits and working tree. `REPO` in `REPO@BASE..HEAD` is the repository folder's
  name ([notebook.md](notebook.md), "A snapshot and a living page"). When the work was committed
  straight onto the integration branch, `BASE` is the commit that branch was at before the work's
  first commit; when the session and the log do not tell, ask.
- **Then, what git does not see:** settings in a web console, installed tools, permissions, steps a
  person must do.
- Read each small file again; never describe a file from memory.
- **Older work or a summarised session:** use the run records, the pull request and the diff, and
  mark what is reconstructed.
- Read-only subagents only above about 40 files. The main thread reads the decisive lines itself.

### 3. Show the outline

Print: the two sentences, the change map with its arrows, the ideas (design idea first), the pictures, and the count of files per part. Go on unless the person objects or the source
is ambiguous. The change map is `grasp-tools change-map --repo DIR... --base REF`, with the
arrows added and the boxes renamed as "Change map and depth" in [notebook.md](notebook.md) says;
the illustration uses the same part names as its labels.

### 4. Write the pages

Pages on this work already exist (search the folder for the same title, branch, pull request or
files): patch them, never write a second set. Re-pin `Checked against:` by the same rule, and
leave the walk fold alone.

The page follows [templates/issue-page.md](../templates/issue-page.md) and "Standard 2" in
[notebook.md](notebook.md), with these differences:

| Part | On an `explain` page |
| ---- | -------------------- |
| Title | The work's name in the folder's title style, with no key |
| `{KEY}` | Everywhere a template shows `{KEY}` (the titles, the `Code for [...]` link, the link to the sub-page, the walk fold's `/grasp walk` line) use `NAME` |
| Status line | `Status: built` (`verified` only when a Proof row quotes a run made now). Replace `[issue]` with `no issue`, and `[pull request]` with `no pull request` when there is none. `Feature:` links the feature page, or `none` |
| Asked | The request, or the pull request's title, 30 words at most |
| Not done | Says who can finish it. Say here, plainly, when the work is not merged or not live |
| Where it fits | The change map. More than about three parts: also the cutaway picture `NAME-change-map.png` ("Illustrations" in [notebook.md](notebook.md)) |
| Ideas | The design idea first, then at most 7 more, 8 in all. `--lessons` applies to every fold |
| Illustration | Under `## In two sentences`, unless `--no-image`: `assets/NAME-idea.png` |
| Length | Never a short page. Every fold and the sub-page are complete |

Three more folds under `## More detail`, written only by `explain`, before the walk fold. HTML
only, one level, a title that states a conclusion, a table as an HTML `<table>`:

| Fold | Holds |
| ---- | ----- |
| `Set it up` | The exact commands in order, then one command that shows it worked. A variable's name, never its value |
| `When something goes wrong` | A table: what you see, what to do. The real message, seen in this session or read in the code, never one made up |
| `How we built it, step by step` | A numbered list, one to three sentences each: what was done, what went wrong there and how it was fixed |

"Why it was built this way" holds the choices as an HTML table: choice, rejected, why, cost.

The sub-page follows [templates/issue-code-page.md](../templates/issue-code-page.md), with these
differences:

- **`## Every changed file`:** a `###` heading per repository. Under it, per part, one bold line
  (the part as named on the change map, its file count, what it is for and why), then the table.
  Paths relative to the repository, exactly as git prints them. A folder of generated or repeated
  files is one row, `` `path/to/folder/**` ``. End with a count line: the parts add up to the
  total.
- **`## Code walkthrough`:** as on any code sub-page. Work not committed yet is the exception, see
  "Work that is not committed yet" below.
- **`## Things people look up`**, visible tables: routes, tables and columns, setting and
  environment variable names, packages with version and why, error codes. A first-column entry
  shaped like a file path must be a real file, or `coverage` reports it `STALE`.
- **`## Not in git`**, a visible table: settings in a web console, tools installed on a machine,
  permissions, and whether each is done.

#### Work that is not committed yet

A page is pinned to commits, and code reaches a page only through `grasp-tools snippet`, which
reads commits. For a repository with uncommitted or untracked work:

- `Checked against:` uses the fixed word `uncommitted` as that repository's head, for example
  `` `web@1a2b3c4..uncommitted` ``. `BASE` is still the merge base with the integration branch.
- Every changed file still gets its row under `## Every changed file`.
- The walkthrough is still written, one `### N. Title` per step. Each step names the file and the
  line range in prose (`` `src/cart/total.ts` lines 10-24, not committed yet ``), with one or two
  sentences and no fence.
- Put one line under the status lines: `Not pinned yet: this work was not committed when the page was written.`
- `coverage` takes `--base` for it (step 5).
- The report tells the person to finish the page with `/grasp repair NAME --only code` after the
  commit: it pins the page and pulls the real lines.
- `explain` never commits the code itself to get around this.

Who writes the pages (inline or one subagent) follows the token budget in
[notebook.md](notebook.md). The pages go to the `--docs` folder, with images in `assets/` beside
them, named `NAME-what.png`.

### 5. Prove it

Run, and fix everything they print:

```
grasp-tools lint-page NAME.md NAME-code.md
grasp-tools snippet-check --repo DIR [--repo DIR2] NAME-code.md
grasp-tools coverage --repo DIR [--repo DIR2] [--base REF] NAME.md NAME-code.md
```

Give the main page first: `coverage` reads the ranges from the first page given, and the
sub-page has no `Checked against:` line.

- Everything committed: leave `--base` out. Each range is read from `Checked against:`.
- Uncommitted or untracked files in the work (a head of `uncommitted`): pass `--base REF`, one ref
  that exists in every repository (usually the integration branch), and no `--head`. It counts
  those files too. With `--head`, only commits count.
- Repositories that need different bases and have uncommitted work: one `--base` cannot serve
  them. Say so, ask the person to commit, and run `coverage` once with no `--base` after that: the
  `Checked against:` line carries one range per repository. Report coverage as not run until then.
- Every `MISSING` or `STALE` line is something to fix. `MISSING REPO/path` names the repository.
- Every lesson link through `grasp-tools check-link URL`, as in "One specific video and one page
  to read". A link that fails is dropped.
- Every diagram rendered, or at least linted, and the illustration opened and looked at. Say in
  the report which of these did not run.
- Each number and claim on the pages checked against its source once.
- The project's doc build, when it has one. Separate a failure that was already there from a new
  one.

### 6. Connect it

- Add rows to the docs router (a question in the left column, the link in the right) and to the
  folder's index, with the page's name and one line.
- Link the issue, feature and architecture pages instead of repeating them. An issue page exists:
  link it and leave its "How it works" there. A feature page or the app map became wrong: patch the
  changed rows only ([overview.md](overview.md)), or say that `/grasp map` is due. A decisions
  file exists: one line for a new decision.
- Update the run record of the task that built the thing: Changed, Checked and Problems, and a
  link to the page ([records.md](records.md)). A run that explains older work gets its own, even
  though its only writes are notebook pages. Then `grasp-tools record-index`, after reading its
  diff: stage only your own rows.
- Stage only your own files. Commit and push as the Rules say.

### 7. Report

- Where the pages are.
- Coverage: the one line `N of M changed files named` from the single run over every repository.
- What is not finished, and who can finish it.
- Which checks did not run, and any bug found.
- With no `.grasp.md`: that `/grasp setup` is available.
- Work not committed yet: the finishing line from "Work that is not committed yet".
- Last line: `Walk ready: /grasp walk NAME`. Never start a walk and never wait for one.

## `check PAGE`

Run step 5 on `PAGE` and report. Write nothing: no page, router row, run record or image.
`PAGE` is the main page, `NAME.md`; the sub-page is the same name plus `-code.md`. Given a
`-code.md` file, use its main page. `--repo` is repeated for each repository. When the page has a
`Checked against:` line, run `coverage` with no `--base`: each repository's range is read from the
page. Unless a head reads `uncommitted`: then `--base`, default the integration branch. Only when
the page has no `Checked against:` line does `--base` apply, defaulting to the integration branch.
An explicit `--base` always wins.
