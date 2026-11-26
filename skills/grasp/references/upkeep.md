# sync and repair

Keep the pages current. `sync` reports what is wrong with every page. `repair` fixes it: one
issue's documents, one feature, or everything.

`grasp-tools sync` decides everything a script can decide: which page is missing, stale, below
standard, has a dead lesson link, was changed since, or was not walked. You supply what only an
agent can: the tracker's list of issues and each pull request's current commit. You also do the
repair, which is writing.

**Markdown notebooks only.** When `.grasp.md` says `target: notion`, say that `sync` and `repair`
work on Markdown notebooks only and stop. With no `.grasp.md`, run `setup` first
([setup.md](setup.md)).

Settings read from `.grasp.md`, once, at the start of either command:

- `markdown folder`: the notebook folder, passed as `--docs`. In a workspace, each project's
  `notebook folder` from `## Projects`: a workspace with one notebook folder per project runs the
  helper once per folder, and prints one table.
- `## Projects`: every row is a `--repo`. In a single project there is no such section: pass the
  repository root.
- `sync scope`: `project` or `mine`. Missing means `project`.
- `other records`: folders whose files mention issue keys. `none` or missing means no such links.
- `## Tracker`, and `pull request host command` under `## Code`: how to read the tracker and
  the pull requests ([trackers.md](trackers.md)).

## `/grasp sync [FEATURE]`

Reports. Writes only what the helper generates. Never edits prose.

1. **The keys.** Read the tracker. `project`: every issue of the tracker project that has a pull
   request, whoever built it. `mine`: only those assigned to the account the reader is signed in
   as, asked of the tracker itself ("The account" in [trackers.md](trackers.md)). When that
   cannot be told, use `project` and say so in one note. Write one key per line to a temporary
   file (`mktemp`), in the tracker's own form; the helper finds a page by its title key or file
   name, in any case, and reads `owner/repo#42` as `42`.
2. **The heads.** For each key that has a page (a file `KEY-*.md` in the notebook folder), find its
   pull request in each repository (the branch name or title holds the key; with several in one
   repository, the most recently updated). Write `KEY<TAB>REPO<TAB>SHA` per line to a second
   temporary file. `REPO` is the repository's folder name (the main checkout's, when in a worktree). `SHA` is the merge commit once the pull
   request is merged, otherwise its head. Do not compare commits yourself: the helper decides
   stale from file contents, by the pinning rule in [notebook.md](notebook.md) "A snapshot and a
   living page".
3. **A tracker or host you cannot read.** Run without that file (`--keys` for the tracker,
   `--heads` for the host). The helper prints a note for each check it could not run; repeat those
   notes to the person, so a missing check is never read as a pass.
4. **Run it.**

   ```
   grasp-tools sync --docs DIR --repo DIR [--repo DIR]... [--keys FILE] [--heads FILE] [--links]
   ```

   Pass `--links` only when the person asked for the links to be checked: it opens every lesson
   link. Output is one tab-separated row per issue page and feature page, then one per missing
   key: `KEY`, `STATES`, `PATH`, `DETAIL`. It exits 0 whatever the states. A note on stderr that
   names a file it refused to write into is repeated to the person.
5. **Print.** A table grouped by feature. The helper's rows carry no feature: read the `Feature:`
   field of each issue page, the file in the `PATH` column, to group them. A feature page is the
   head of its group; issue pages whose `Feature:` is `none`, and pages written by `explain`, go
   under "No feature page". Worst first inside each group, in the order of the states below. Columns: key, states, what is
   wrong. With `FEATURE` named, print only that group; the helper still refreshes the generated
   lists everywhere. End with one line of counts, for example `31 pages: 2 missing, 3 stale,
   1 below standard, 5 not walked, 22 ok`. A page with two states counts in both.
6. **Files.** The helper rewrote the issues lists (between `<!-- grasp:issues:start -->` and
   `<!-- grasp:issues:end -->`) in `features/README.md` and each feature page, and the
   `Changed since by:` line of issue pages. Say how many files changed. Leave them uncommitted
   unless the project's rules say a run commits its pages. When it changed a file, write the run
   record ([records.md](records.md)).

States, in the order the helper prints them:

| State | Meaning | What to do |
| ----- | ------- | ---------- |
| `missing` | The tracker has a card with a pull request and there is no page | `repair KEY` writes it |
| `stale` | Issue page: code in its own pull request changed after the pin. Feature page: a file it names changed after its `Verified at` commit | `repair` |
| `below-standard` | Old or no Standard, an old `explain` pair, no code sub-page, not pinned or no range, nothing changed in the range, or a lint, snippet or coverage finding | `repair`, see the table below |
| `bad-link` | A lesson link fails `check-link` (only with `--links`) | `repair KEY --only links` |
| `changed-since` | Later issues edited its files. Information, not a fault | nothing |
| `not-walked` | Nobody has walked the page. Information, not a fault | `/grasp walk` |
| `ok` | None of the above | nothing |

## What a finding means for a repair

`DETAIL` holds the findings, separated by `; `. These are the only strings to expect:

| DETAIL | Fixed by |
| ------ | -------- |
| `no Standard field`, `Standard N, current 2`, `old explain page (NAME-files.md)` | rewriting the page ("Existing pages" in [notebook.md](notebook.md)) |
| `no range on the Checked against line`, `coverage: nothing changed in the range` | rewriting the page, pinned again by "A snapshot and a living page" |
| `no code sub-page` | writing the sub-page, and the link to it from the page |
| `lint: RULE` | rewriting the file the rule is about. Run `grasp-tools lint-page` on the page and its sub-page to see which |
| `coverage: MISSING REPO/path` | rewriting the code sub-page so the file is in its list (a short page: the page) |
| `snippet-drift FILE A-B` | `--only code`: the block was edited by hand, so it is pulled again with `grasp-tools snippet` |
| `not pinned to a commit` | `--only code`, after the work is committed ("A page about uncommitted work" below) |
| `REPO: PATH changed after the pin` | rewriting the page, and pinning it again |
| `bad-link` with an address, `N ideas without a video`, `N ideas without a page` | `--only links` |
| `not built yet` | not a fault: the page is `planned` or `building`. Its build finishes it |
| `link not checked: timeout ADDRESS` | not a fault: the link did not answer in time. Run with `--links` again later |
| `REPO not given`, `coverage partly checked: REPO not given` | not the page's fault. Needs a person: pass that repository as `--repo`, or add it to `## Projects` |
| `unreachable REPO@SHA` | not the page's fault. Needs a person: that commit is not in the clone. Fetch it, after a yes |
| `coverage could not run: REASON`, `lint could not run: REASON` | not the page's fault. Needs a person: fix the cause named in REASON. Do not rewrite |

A row can show a finding that is a note while its state is `ok` (a repository not given, an
unreachable commit, ideas without a video or a page, not built yet, a link that timed out). Print it. It is repaired only when the table says a
repair fixes it.

## `/grasp repair`

Fixes what `sync` found, by writing the page again. It never changes code, never commits, never
pushes and never writes to the tracker. The new pages are left uncommitted unless the project's
rules say otherwise.

Flags: `--only page|code|links` limits the repair to one part. `--dry-run` prints the findings and
stops; it never writes anything, for one issue or a batch: no page, no generated list, no run
record. `--force` rewrites a page that is already clean. A quoted reason after the target is a
finding supplied by the person.

The target decides which part below applies:

- A key, a tracker address, or the path of either of the card's files: one issue.
- The name of a page that has no issue key (an `explain` page, `NAME.md`): one `explain` page.
- A feature name from `## Features`, or a file in `features/`: one feature.
- `--all`: every page.
- None of these, or two matches: ask which, one question, and stop until answered. With no
  target, ask which feature; never start on everything without being told.

### One issue

1. **Findings.** Build the keys file (the one key) and the heads file (its pull requests), as
   sync's steps 1 to 3 do. Run:

   ```
   grasp-tools sync --only KEY --docs DIR --repo DIR [--repo DIR]... --keys FILE [--heads FILE] [--links]
   ```

   For one issue or one name, `sync --only` is always run with `--links` (it checks one page's
   links, which is cheap), except with `--only page` or `--only code`.
   `grasp-tools sync --only` writes nothing. Print each finding as one line: the state, then the
   `DETAIL` item. Print a quoted reason as a finding too.
2. **`--dry-run` stops here.** Nothing is written, no subagent starts. With no findings it prints
   `nothing to repair`.
3. **Nothing found.** When no finding can be repaired (the state is `ok`, or only `changed-since`
   and `not-walked`), there is no reason and no `--force`: print `nothing to repair` and stop.
   Print the notes the table says repair cannot fix.
4. **Write.** One subagent writes the pages by [notebook.md](notebook.md) "Standard 2" and its
   templates. An old page is never written over: steps 1 and 2 of "What a rewrite keeps from the
   old page" in "Standard 2" come first, so the subagent reads the old page, then writes
   `PAGE.new`. Its `Status:` is `verified` only when a Proof row was run in this session or read
   from the pull request's checks; otherwise `built`. Without `--only`, `repair` always writes the
   whole page again, from the card, the
   pull request and the code at the pinned commit (an old page may have no working note). It never
   patches a sentence of the old text grasp wrote. The exception is what that subsection carries
   over (the walk, an old explain-back answer, the prediction guess, "Questions asked",
   screenshots and the illustration), because they are the person's words or cannot be made again.
   It reads what "What the writer reads" lists. It pins by "A snapshot and a living page" (the
   merge commit once merged, otherwise the last code commit of the pull request). It writes every
   code block through `grasp-tools snippet`. A quoted reason is one more finding, checked against
   the code first. The report says, for the reason, where the code agrees (and what changed on the
   page) and where it does not (and that the page already matched the code there). A missing page
   is written the same way. A card with no pull request cannot be written: report `needs a person:
   no pull request`. The subagent writes no run record and does not touch the run records index.
5. **Keep what the old page holds.** Steps 3 to 5 of that subsection, in order: `keep-walk`
   (skipped only when the target file does not exist), the "Earlier explain-back" entry, and only
   then the old file replaced.
6. **Other records.** For each folder in `other records`, link every file that mentions the key
   (`grep -rlwF KEY FOLDER`, so `SHOP-1` does not find `SHOP-12`) in the "Open and not verified" fold, as a link of the fold's own HTML
   form. None, or `none`: skip.
7. **Parts.** `--only page` rewrites the issue page and leaves its sub-page alone. `--only code`
   rewrites the code sub-page, and re-pins the page only when its prose cannot be wrong: when the
   head is `uncommitted` ("A page about uncommitted work" below), or when every file of the page's
   range is the same at the old pin and the new one (`git diff --quiet OLD NEW -- FILES`, with
   FILES from `git diff --name-only BASE OLD`). Then it rewrites the `Checked against:` line by the
   pinning rule in [notebook.md](notebook.md) "A snapshot and a living page" and changes nothing
   else on the issue page. Otherwise it changes nothing and reports `needs a person: the code
   changed after the pin, run /grasp repair KEY`. `--only links` rewrites no prose: it rechecks
   every lesson link with `grasp-tools check-link`, replaces a failed one in place with a link
   chosen by "One specific video and one page to read" in [notebook.md](notebook.md), and fills an
   idea whose fold says `No checked video yet` or
   `No checked page yet` by the same rules. The other documents of the card are not touched.
8. **Check.** Run the three checks of "Standard 2" on the real files, then `grasp-tools sync --only
   KEY` again with the same files. Report one line: `KEY repaired`, or `KEY needs a person: REASON`
   when a check still prints something or the row still shows `missing`, `stale`, `below-standard`
   or `bad-link`. Writing the generated lists and the run record is not done here: see "Closing
   a run".

### Closing a run

The main thread, not a subagent, does this once per `repair` run, after every page has reported:
run `grasp-tools sync` as `sync` does (it writes), so the generated lists show the new states, then
write one run record for the run that lists every page, repaired or needing a person, and rebuild
the index ([records.md](records.md)). Subagents never write a record.

### A page about uncommitted work

An `explain` page can be pinned to the word `uncommitted` and show a `Not pinned yet:` line. `sync`
reports it `below-standard`, `not pinned to a commit`. `repair NAME --only code` finishes it:

1. For each repository with an `uncommitted` head, check that every file in the page's
   `## Every changed file` list is committed (`git status --porcelain` shows none of them).
2. If any is not, say which, change nothing, and report `needs a person: the work is not committed
   yet`.
3. Otherwise rewrite the `Checked against:` line by the pinning rule, remove the `Not pinned yet:`
   line, and replace each prose step of the walkthrough that names lines "not committed yet" with
   the output of `grasp-tools snippet --repo DIR --rev SHA FILE START END`.
4. Run the three checks, using the page's new ranges.

### One `explain` page

`repair NAME` has no card. Rebuild the page by [explain.md](explain.md) from the page's own
`Checked against:` ranges (each `REPO@BASE..HEAD` is a `BASE..HEAD` source in that repository),
keeping its name and folder. Steps 1 to 3, 5, 7 and 8 above apply as written, with `NAME` in place
of `KEY`, and so does step 4's order: the old page is read first and the new one written to
`PAGE.new`. A quoted reason is a finding, as for an issue.

### A feature, or `--all`

1. Run `grasp-tools sync --no-write` as above, on the whole notebook, with `--links` only when the
   person asked for links. For `FEATURE`, keep that feature's rows. Nothing is written before the
   yes: the only writing `sync` of a repair run is the one in "Closing a run", after the repairs.
2. Count: pages to rewrite (`missing`, `stale`, `below-standard`), pages that only need their links
   (`bad-link`, counted only when links were checked; otherwise say `links not checked` and
   promise no link repairs), and pages that need a person (the table above). With `--force`, every page
   counts as one to rewrite. Show the three numbers and ask once whether to go. Without a yes,
   write nothing. With `--dry-run`, show the numbers and the findings and stop. A quoted reason
   belongs to one issue or one `explain` page, so it is not accepted here.
3. One page per subagent, each following "One issue" steps 4 to 8, or "One `explain` page", and
   none writing a record. Run them
   one at a time when the project's checks are heavy; otherwise a few at once. A feature page is
   rewritten by [overview.md](overview.md) from the code as it is today, by the same "What a
   rewrite keeps from the old page".
   `--only code` leaves a feature page alone, because it has no sub-page.
4. Print one line per page as it finishes, then the counts: how many repaired, how many need a
   person, and what each needs. Then "Closing a run".

## Never

- Edit prose in `sync`.
- Write between `<!-- grasp:walk:start -->` and `<!-- grasp:walk:end -->` in a page, except the
  one "Earlier explain-back" entry ([notebook.md](notebook.md) "Standard 2"). Never between
  `<!-- grasp:issues:start -->` and `<!-- grasp:issues:end -->`.
- Rewrite a clean page with no reason and no `--force`.
- Replace an old page before `keep-walk` has exited 0.
- Type or edit a code block by hand.
- Compare commits to decide stale, or call a page stale because a later issue edited its files.
- Report `repaired` for a page whose checks still print something.
