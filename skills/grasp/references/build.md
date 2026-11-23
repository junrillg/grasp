# Build: branch, test first, checks, pull request

Detail for step 4 of [SKILL.md](../SKILL.md). Runs only after the user picked an approach. The
project's own rules (its `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`) win over this page.

## 1. Branch

- Integration branch, branch name pattern and remote come from `.grasp.md`. Default name:
  `TYPE/KEY-short-name`, with `feat` for new behaviour and `fix` for a bug; text issues use a
  slug.
- Fetch first, branch from the fresh integration branch. With no remote, skip the fetch and
  branch from the local integration branch.
- The working tree has tracked changes: show them; the user chooses commit, stash or discard.
- The issue already has a branch: an open pull request on it means add commits on top; a merged
  one means ask before resetting (show the commits first); anything unclear means ask.
- Confirm `git branch --show-current` before the first edit. Never edit on the integration branch.
- Re-read each decisive file on the new branch. A change written against a stale read is a
  second bug.

## 2. Implement

- **Test first.** Write the test that fails for the issue's reason. Run it and watch it fail.
  Then change the code. A bug fix without a test that fails without it is not done.
- **Smallest correct change** at the place every caller passes through. Search the callers of a
  function before changing it.
- **Never weaken a gate** to get green: no disabled lint rule, skipped test, loosened type check,
  lowered coverage floor.
- **Comments: default to none.** One line of why when the code cannot say it.
- Leave unrelated problems for their own issue; list them in the report.
- **Keep the page live.** At the first edit, set the issue page's status line to
  `Status: building`. Each time a step of its "Steps" list is finished (what the step names is
  true: a "failing test" step when the test exists and fails for the right reason, a code step
  when its test passes; two steps proven by one test are ticked together), tick
  that box (`- [x]`) before starting the next one: one small edit, no subagent, no lint run. A
  step that turned out different keeps its box and gains "(changed: why)". This is how someone
  with the page open in Obsidian follows the build. With `--notebook off` there is no page: say
  each finished step in one line in the conversation instead.

## 3. Checks

Run the check commands from `.grasp.md`, one at a time, and keep each result line. Typical
sets when `.grasp.md` has none: `npm run lint && npm test && npm run build`; `ruff check . &&
pytest`; `go vet ./... && go test ./...`; `make check`. Anything a person sees: also run the app
and look.

A check already failing on the integration branch: prove it by running it without your change,
tell the user, and do not fold an unrelated repair into this issue.

## 4. Commit and pull request

- Stage files by path. Never `git add -A`. The run record and the pages for this task go in the
  same pull request as the code, in a commit of their own when they are written after the first
  push (docs in a separate repository: committed there, see [review.md](review.md)).
- One Conventional Commit subject line unless the project says otherwise.
- Show the pull request title and body, ask, then push and open it against the integration
  branch. The body opens with the issue in one or two sentences and its link, then the changes as
  short bullets, then how it was checked with real commands and results.
- Read back the pull request's base branch and its checks. A red check is this run's to fix.
  Never merge: that is the reviewer's call.
