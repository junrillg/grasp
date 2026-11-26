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
| `--docs` | folder | `markdown folder` in `.grasp.md`, else `docs/how-it-works/` | Where the pages go. No `.grasp.md` and no `docs/` folder: ask |
| `--name` | slug | named after the work, in the numbering and title style of the pages already in the folder | File name of the page. The sub-page is `NAME-code.md` |
| `--lessons` | `all`, `free`, `none` | `all`; `free` when `.grasp.md` says `linkedin learning: no` | `free` drops LinkedIn Learning videos and `Course:` lines. `none` writes `<p>Lessons turned off</p>` in each idea's fold |
| `--no-image` | flag | off; on when `.grasp.md` says `illustrations: no` | Diagrams only: no illustration and no cutaway picture |
| `check PAGE` | subcommand | none | Run "Prove" on an existing page and write nothing |
| `--base` | ref, with `check` | the integration branch | What the work is compared with. For a page whose work has merged into it, pass the `BASE` of the page's `Checked against:` line |

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
| `integration branch` | The base for coverage and for `check` |
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
  name ([notebook.md](notebook.md), "A snapshot and a living page").
- **Then, what git does not see:** settings in a web console, installed tools, permissions, steps a
  person must do.
- Read each small file again; never describe a file from memory.
- **Older work or a summarised session:** use the run records, the pull request and the diff, and
  mark what is reconstructed.
- Read-only subagents only above about 40 files. The main thread reads the decisive lines itself.

### 3. Show the outline

Print: the two sentences, the change map with its arrows, the ideas (design idea first, at most
8), the pictures, and the count of files per part. Go on unless the person objects or the source
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
| Status line | `Status: built` (`verified` only when a Proof row quotes a run made now). Replace `[issue]` with `no issue`, and `[pull request]` with `no pull request` when there is none. `Feature:` links the feature page, or `none` |
| Asked | The request, or the pull request's title, 30 words at most |
| Not done | Says who can finish it. Say here, plainly, when the work is not merged or not live |
| Where it fits | The change map. More than about three parts: also the cutaway picture `NAME-change-map.png` ("Illustrations" in [notebook.md](notebook.md)) |
| Ideas | The design idea first, then at most 7 more. `--lessons` applies to every fold |
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
- **`## Code walkthrough`:** as on any code sub-page. A file not committed yet cannot be quoted
  (`grasp-tools snippet` reads commits): write its row and a line saying it is not committed,
  and patch the walkthrough after the commit.
- **`## Things people look up`**, visible tables: routes, tables and columns, setting and
  environment variable names, packages with version and why, error codes. A first-column entry
  shaped like a file path must be a real file, or `coverage` reports it `STALE`.
- **`## Not in git`**, a visible table: settings in a web console, tools installed on a machine,
  permissions, and whether each is done.

Who writes the pages (inline or one subagent) follows the token budget in
[notebook.md](notebook.md). The pages go to the `--docs` folder, with images in `assets/` beside
them, named `NAME-what.png`.

### 5. Prove it

Run, and fix everything they print:

```
grasp-tools lint-page PAGE PAGE-code.md
grasp-tools snippet-check --repo DIR PAGE-code.md
grasp-tools coverage --repo DIR --repo DIR2 [--base REF] PAGE PAGE-code.md
```

- Everything committed: leave `--base` out. Each range is read from `Checked against:`.
- Uncommitted or untracked files in the work: pass `--base REF`, one ref that exists in every
  repository (usually the integration branch). It counts those files too. With `--head`, only
  commits count.
- Repositories that need different bases and have uncommitted work: run `coverage` once per
  repository. A `STALE` line for a path of the other repository is then expected; every `MISSING`
  line is not.
- Every lesson link through `grasp-tools check-link URL`, as in "One specific video and one page
  to read". A link that fails is dropped.
- Every diagram rendered, or at least linted, and the illustration opened and looked at. Say in
  the report which of these did not run.
- Each number and claim on the pages checked against its source once.

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
- Stage only your own files. Commit and push only under the project's standing rule or after a yes.

### 7. Report

- Where the pages are.
- Coverage, `N of N changed files named`.
- What is not finished, and who can finish it.
- Which checks did not run, and any bug found.
- With no `.grasp.md`: that `/grasp setup` is available.
- Last line: `Walk ready: /grasp walk NAME`. Never start a walk and never wait for one.

## `check PAGE`

Run step 5 on `PAGE` and report. Write nothing: no page, router row, run record or image.
`--repo` is repeated for each repository. `--base` is passed to `coverage` as in step 5, so
uncommitted files count too.
