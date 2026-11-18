# Verify: fresh evidence, then the gate

Detail for step 5 of [SKILL.md](../SKILL.md) and the `verify` subcommand. Verification proves
the change works, or says plainly that it does not. It never repairs anything during `verify`.

## Which code

| Situation | Verify | Record |
| --------- | ------ | ------ |
| Just built in this run | the branch tip | `git rev-parse HEAD` |
| Open pull request | its head commit, detached | the head SHA from the pull request |
| Merged pull request | the integration branch tip, after confirming it holds the merge commit (`git merge-base --is-ancestor`) | both SHAs |

The working tree must be clean before a checkout; if not, stop and ask, or use a separate
`git worktree add --detach`. Note the branch you were on and switch back at the end. Reinstall
dependencies when the lock file differs.

## Evidence

Run, one at a time, keeping the exit code and the result line:

1. The project's checks from `.grasp.md`.
2. **The control**: the new test must fail on the code before the change
   (`git stash` the source change, or check out the parent commit in a worktree, run the one test,
   restore). When the control cannot run cleanly, skip it and say so. Do not improvise one.
3. **The behaviour**: follow the issue's own steps against a local run. Screenshot or capture
   output for each passing step and look at it. If the behaviour cannot run locally, say so and
   rest on the tests and CI.
4. **CI** on the pull request, for the commit you verified.
5. **Acceptance**: one row per acceptance criterion (or per expected behaviour in the issue):
   met, not met, or not checked, with the evidence for each.

## The gate

Claim done only when all of these hold. Otherwise report what is short.

1. The issue's expected behaviour is understood and each criterion has a row.
2. Every check run exited 0, with the result lines shown.
3. The control failed on the old code, or the user accepted going without it.
4. The behaviour was seen correct, or the user accepted that it cannot be exercised locally.
5. CI passed for the commit verified (or there is no CI, said plainly).

Words like "should work", "looks fine", "probably" mean the gate has not passed. Give a
confidence percentage with what would raise it; it goes to the user, never onto a tracker.

Whatever went wrong on the way (a failed check, a wrong first approach, a surprise in the code)
goes into the "after" page under "Issues met". That is where the team learns the most.
