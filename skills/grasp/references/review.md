# Review and resolve: pull requests

Detail for the `review` and `resolve` subcommands in [SKILL.md](../SKILL.md). Both end the
same way as a build: the issue page says what the code does now, so the team understands the
change without reading the diff.

Use the host command from `.grasp.md` (`gh`, `glab`, or a project wrapper) for every call. When
the project has its own review or comment-resolution skill, prefer it and run only the page step
below.

## `review PR`

Read only on the host unless the user asks to post.

1. **Fetch.** The pull request's title, body, head commit, base branch, checks, changed files and
   diff, plus existing reviews and threads. Find the issue key in the title or branch name and
   read the issue (step 1 of SKILL.md). No key: say "issue not read" and go on without it.
2. **Context.** Read the project's written standard (`CLAUDE.md`, `AGENTS.md`,
   `CONTRIBUTING.md`, its `docs/`), the issue page and the app map if they exist. Read the full
   file at the head commit for every hunk a finding will touch (`git show SHA:path`). Never check
   out, stash or reset: the user may have work in progress.
3. **Review**, in parallel read-only subagents, one per lens:
   - correctness: logic, unhandled failures, races, edge cases, callers of changed code;
   - standard: each finding names the rule and the file it comes from;
   - issue: each acceptance criterion met, partly met, missing, or changed without being asked;
   - contract, when an API call or response shape changes: compare both sides.
   Do not run tests or builds: the pull request's checks are the evidence.
4. **Verify every finding yourself.** Open the line at the head commit. Drop what is wrong, what
   a tool already enforces, what repeats an existing comment, and taste without a rule behind
   it. A rule that is not written in the repository is at most a question.
5. **Report.** Counts and checks first, then each finding with file, line, severity
   (`must-fix`, `should-fix`, `nit`, `question`), the comment as it would be posted, and its
   rule. Then what was not checked.
6. **Page.** See "The issue page" below.
7. **Post, only when asked.** Show every comment word for word and the review type; post once
   after a yes. Follow the project's voice rules. Never approve or merge on the user's behalf
   without being told to.

On a pull request already reviewed by this account, run a second round instead: for each earlier
finding, check the author's reply and the fix commits, and report fixed, not fixed, or answered.

## `resolve PR`

The pull request is the user's own (or they asked to work it).

1. **Fetch every unresolved thread verbatim** in the main thread; never ask a subagent to
   summarise review comments. Also read review bodies and conversation comments. Stop if the
   pull request is not open. Ask before resolving threads on someone else's pull request.
2. **Check out the head** in a clean clone (stop and ask if it has changes), and confirm `HEAD`
   equals the pull request's head commit.
3. **Sort** into one table: finding, who raised it, threads, `path:line`, kind (change request,
   question, nit, already addressed, noise). Merge repeats.
4. **Was it decided on purpose?** Search the project's docs, the issue page and its decisions
   log for what the finding names. A recorded decision is strong evidence.
5. **Verify** each finding with a read-only subagent (add an adversary for bot findings and for
   anything that changes behaviour). Read the deciding line yourself before acting on a verdict.
6. **Decide and show the table:** right with one obvious fix (implement), right with a design
   choice (ask), outside this pull request (reply), overstated (cheap safe part plus evidence),
   wrong (reply only), product question (ask the user).
7. **Fix**, scoped to what each thread is about. A bug fix comes with a test that fails without
   it. Run the project's checks one at a time. Never weaken a check to pass it.
8. **Commit** one new commit on the same branch in the project's format. Never amend,
   force-push, rebase or squash.
9. **Page and record.** See "The issue page" below, then update the task's run record
   ([records.md](records.md)): what the review caught goes in its Problems line, what this run
   fixed in Changed.
10. **Replies.** Draft one per thread; show the diff summary, check results and every reply word
    for word, and ask once. Then push, reply, and resolve only the threads that are the author's
    to close. Fetch again to confirm each reply and thread state, and report the checks.

## The issue page

Both subcommands leave the issue page (see [notebook.md](notebook.md)) matching the code:

- **No page yet, issue adds behaviour:** create it with the status line and the after half from
  [templates/issue-page.md](../templates/issue-page.md), written from the issue, the pull
  request body and the diff. Leave out the before half and "your guess vs what happened": the
  author's predictions are not known. The list of issues is generated by `grasp-tools sync` only:
  run the writing `sync` once the page is written, built as "`/grasp sync`" in
  [upkeep.md](upkeep.md) builds it (not with `--notebook off`, and not for a Notion notebook),
  and never add a row to it by hand.
- **Page with no `Standard: 2`:** it is not patched in its old layout. It is rewritten to standard 2
  by "Existing pages" and "What a rewrite keeps from the old page" in [notebook.md](notebook.md).
  Never convert untouched pages.
- **Standard 2 page exists:** update only the sections the pull request (`review`) or the fixes
  (`resolve`) change: "In two sentences", the owner block, How it works (diagram and steps), the
  code sub-page (walkthrough, files touched), the "Why it was built this way" and "Proof it works"
  folds, and the `Checked against:` line once a fix commit moved the pull request's last code
  commit, re-pinned by "A snapshot and a living page" in [notebook.md](notebook.md). Add a changed
  decision to the decisions log.
- **Findings:** `review` puts each verified finding that is still open in the alert under the
  title, a visible `> [!WARNING]`, one line each, never folded. `resolve` adds each finding it
  fixed to the "Planned and built" fold's list as one item (what the reviewer caught and how it
  was fixed) and removes its warning line; a warning goes only when this run fixed it.
- **Bug:** a short page ("Short pages" in [notebook.md](notebook.md)), and its run record
  ([records.md](records.md)).
- **Checks:** run the three checks in "Standard 2" ([notebook.md](notebook.md)) on every page
  written or patched: `grasp-tools lint-page` on the page and its code sub-page, `snippet-check`
  on the sub-page, `coverage` on both. Fix each line they print before showing the page.
- Describe only what the code does at the head commit; mark what the issue asks for but the diff
  does not build as "not built yet".
- Where the page change is committed:
  - docs in a separate repository (`docs repo` in `.grasp.md`, such as a workspace wrapper):
    commit and push it there, never in the product pull request;
  - docs in the same repository, `resolve`: a second commit on the same branch, shown in the
    diff summary before the push;
  - docs in the same repository, `review`: the branch is the author's, so do not push to it.
    Write the page locally, show it, and offer it as a suggested change or a follow-up commit
    after a yes.

One subagent writes the page (Sonnet new, Haiku update) when the diff is large; inline when
small. Then check it once, as notebook.md says.
