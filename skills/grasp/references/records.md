# Run records

Detail for `record`, step 7, and setup's "Run records" step in [SKILL.md](../SKILL.md). Goal: after
any agent task, a person who was not watching can say in under a minute what was asked, what
changed, whether it was checked, what went wrong and what is left.

An issue page teaches one change in depth. A run record is the logbook line for one task, and it
exists for every task that changed files: a bug fix, a three-line change, a task that never went
near `/grasp`, a run that failed halfway. The table of all records is the answer to "what has the
agent been doing here?".

## Where they live

```
<notebook folder>/runs/
  README.md                      the table of every run, newest first (built, never hand-edited)
  YYYY-MM-DD-short-name.md       one file per task
```

The folder is `run records:` in `.grasp.md` (default `docs/how-it-works/runs`). One file per task
and no shared log file: two branches that each append to one file always conflict, two branches
that each add a file never do. `README.md` is rebuilt by `grasp-tools record-index`, so a merge
conflict in it is settled by running that again.

In a workspace where several projects share one folder, start the short name with the project:
`2026-11-21-backend-csv-export.md`, titled `# 2026-11-21: backend: CSV export`.

## When to write one

- **Write** when the task changed files in the repository: code, config, tests, docs outside the
  notebook, the agent instruction files.
- **Write** when the task failed or was abandoned after changing or trying something. `Status:
  failed` or `blocked` with the problem is the record a person most needs.
- **Update, don't add** when the same task continues (same branch, same issue, or the user says
  "continue"): patch the lines that changed and the status. One task, one record.
- **Skip** a question, a read-only look, and a run whose only writes were notebook pages, except
  the grasp subcommands listed under "`/grasp record`" below, which always leave one.

`grasp-tools record-check` applies the same rule mechanically: it exits 1 when the uncommitted
tree or this branch's commits changed files outside the notebook folder and no record was added
or changed. It compares commits against where the branch left the integration branch, else the
upstream; with neither it checks uncommitted changes only, and says so.

## The shape

[templates/run-record.md](../templates/run-record.md). A title, a status line, then five fixed
lines of one short plain sentence each (about 20 words: the table of runs prints Changed and
Problems in full, and a long sentence makes a tall, unread row):

| Line | Holds | Never |
| ---- | ----- | ----- |
| **Asked** | The request, in the asker's words | Your reading of what they "really" meant |
| **Changed** | What behaves differently now | A list of files; a change that was planned but not made |
| **Checked** | The command that ran in this run and its result line ("exit 0, no output" for a command that prints nothing), or "not checked" and why | A check that exists but did not run; "should work" |
| **Problems** | What failed, was worked around, skipped or is uncertain, or "none" | Silence about a failed attempt because a later one worked |
| **Next** | The one thing a person should do or decide, or "nothing" | A wish list |

A record for issue work links the issue page in its Changed line (one standard link, `[KEY](path)`)
and does not repeat what the page says. The block that `setup` adds to `AGENTS.md` keeps its five
fixed lines as they are.

Status is one word: `done` (asked and checked), `partial` (some of it, or done but not checked),
`blocked` (cannot go on without a person or access), `failed` (nothing usable changed).

After the five lines, only when it helps:

- **One diagram** when the change has a shape (two or more parts that now talk differently): a
  small `flowchart` with the changed box highlighted, reusing the app map's names. No diagram for
  copy, config or a one-line fix. When the task has an issue page, link the page and leave the
  picture there.
- **One `> [!WARNING]` alert** only for a problem that is still open or blocks someone, one line,
  never folded. A problem that was met and fixed, and needs more than its Problems line, goes in
  one toggle ("3 problems met, all fixed"), one list item each: what happened and what was done.
- **Files touched**, folded in one toggle.

Rules that keep a record true and short:

- Write only what happened in this run. Agent summaries are known to claim changes that were never
  made; every "Changed" and "Checked" must be something you can point to in the diff or the output.
- About 120 words outside the toggles, never more than 150: `lint-page` reports `too-long`. Plain
  words. No narration of how you worked. What needs more room goes in a toggle.
- No secrets, tokens, env values, personal data, client text or raw command output. Quote one
  result line, not a log.
- The same Markdown rules as every page ([notebook.md](notebook.md)): standard links, one-block
  HTML toggles, alerts for problems.

## `/grasp record`

Writes or updates the record for the task in this conversation. No code changes, no commits, no
tracker writes.

1. Find the folder (`run records:` in `.grasp.md`). Create it on the first record.
2. Gather from this conversation and the repository, nothing wider: the request, `git status
   --short`, `git diff --stat` against where the branch left the integration branch, the commits
   made in this run, each check that ran with its result line, every error, failed attempt,
   workaround and skipped step, and what is left.
3. Find an existing record for the same task (its status line names this branch or issue). Patch
   it if there is one; otherwise create `YYYY-MM-DD-short-name.md` with today's date. An argument
   in quotes is the short name; without one, name it after what changed.
4. Write it in the template's shape. Link the pull request and the issue page when they exist.
5. Run `grasp-tools lint-page FILE`, then `grasp-tools record-index`.
6. If the task added or changed a core feature, an edge between features, a piece, a step of the
   main request path, a rule or a glossary word, patch those rows of the app map and the feature
   page; a changed layer, call direction, design choice, failure path or limit patches the
   architecture page ("Keeping it current" in [overview.md](overview.md)).
7. Report the record's path in one line. Leave it uncommitted unless the task itself commits: it
   belongs in the same commit or pull request as the work it describes.

Every grasp subcommand that does work ends with this, because its outcome is what people ask
about later: the full workflow at step 7, `verify` (Changed: "nothing; the fix for KEY was
verified", or what failed), `review` (the findings count, and whether anything was posted),
`resolve` after its commit, `setup` and `map` for what they wrote, `explain` (also for older work
whose only writes are notebook pages), `walk` (Changed: the answers
recorded and the gaps found; Checked: the lint result of the page), `repair` (one record for the whole run, written by the
main thread and listing every page it rewrote or could not; subagents write none), and `sync` when it changed a file. Only `page` and `record`
themselves don't: `page` is called by a skill that is still working.

## The block in AGENTS.md and CLAUDE.md

Most agent work never goes through `/grasp`. `setup` therefore adds a short marked block to the
project's agent instructions file, so every agent session is told to leave a record. The block
holds the folder, the title and status form, the five lines and the ask for one small Mermaid
diagram when the change has a shape, so an agent with no grasp installed can still write a record
the index reads, picture included.

- **Which file.** `AGENTS.md` is the one file Codex, Cursor, Gemini CLI and Claude Code can all
  read. Claude Code reads `AGENTS.md` by itself only when the project has no `CLAUDE.md`; when
  there is a `CLAUDE.md`, it must hold the line `@AGENTS.md`. So: put the block in `AGENTS.md`
  (creating it when missing), and when a `CLAUDE.md` exists without that import line, offer
  `grasp-tools connect CLAUDE.md import`, which adds the line in its own marked block. With no
  `CLAUDE.md`, add one only when someone on the team runs a Claude Code older than 2.1.277,
  which can't read `AGENTS.md` by itself. A project that wants no `AGENTS.md` gets the block in
  `CLAUDE.md` instead. Never the block in both: the same text loaded twice is wasted context.
- **Checked live** (Claude Code 2.1.330, Codex CLI 0.169, November 2026): Codex wrote the record
  from the block alone; Claude Code loaded the block from `AGENTS.md` alone and through the
  import; the Stop hook sent Claude Code back to write the record. The Stop hook in Codex was
  checked on 2026-11-23 (Codex CLI 0.171), in a project with no block, after the owner approved
  it through `/hooks`: Codex was sent back with "no run record in ..." and wrote the record. One thing to know: Claude
  Code loads no project instructions in a folder the user has not trusted yet, so the block
  starts working once the project has been opened and trusted.
- **How.** `grasp-tools connect AGENTS.md record`. It appends the block, or replaces grasp's own
  block in place, and lists the file in `.grasp.md` under "Connected skills" with step `record`.
  Nothing outside the block changes. `grasp-tools disconnect AGENTS.md` removes it.
- **Kept current.** `grasp-tools status` reports the block `stale` after a grasp release that
  changes it, or when `run records:` in `.grasp.md` moved; `grasp-tools refresh` rewrites it.
- **Kept short.** The block is loaded into every session. It is 16 lines (17 in a sub-repository
  that shares a workspace's folder) and holds no app
  knowledge; the app map stays in the notebook.

One repository, one block. In a workspace each sub-repository gets the block in its own
`AGENTS.md`, because an agent started inside it reads only that.

**What `record-check` can and cannot see.** It compares the files git says changed with the
records git says were added. With one notebook at the top of a workspace, a sub-repository's
records live outside that repository: the check prints `ok records-outside-git` and proves
nothing about them. In a folder that is no repository it prints `ok not-a-git-repo`. Read both as
"not checked here", never as "a record exists": look in the runs folder itself.

## The Stop hook (optional)

An instruction file is advice: agents follow most rules, not all, and less reliably late in a long
session. A Stop hook is the part that cannot be forgotten: when the agent tries to finish with
changed files and no record, it is sent back once with the reason.

`grasp-tools record-check --hook` is built for it. It reads the hook's JSON on stdin, lets the
stop through when `stop_hook_active` is true (so it can never loop), when `.grasp.md` is missing,
and on any error, a bad argument included; otherwise it exits 2 with the reason on stderr. It
reminds once per state, not once per turn: after a reminder it stays quiet in that session until
the changed files change again, so a session that only answers questions in a tree someone else
left dirty hears it one time. It proves a record exists, not that the record is true.

Offer it at setup, off by default. On a yes, merge one entry into the settings file, keeping every
key already there, where `HELPER` is the absolute path of this skill's `bin/grasp-tools`:

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "timeout": 30,
          "command": "t=\"HELPER\"; [ -x \"$t\" ] || exit 0; \"$t\" --config \"${CLAUDE_PROJECT_DIR}/.grasp.md\" record-check --hook" } ] }
    ]
  }
}
```

- **Claude Code.** grasp installed inside the project (`.claude/skills/grasp`): write
  `${CLAUDE_PROJECT_DIR}/.claude/skills/grasp/bin/grasp-tools` as `HELPER` in
  `.claude/settings.json`, which the team shares. Installed anywhere else (home folder, plugin):
  the path is this machine's, so it goes in `.claude/settings.local.json`.
- **Codex.** The same entry in `.codex/hooks.json`, with
  `"$(git rev-parse --show-toplevel)/.grasp.md"` as the config path. Codex runs project hooks
  only in a trusted project and after the user approves the hook through `/hooks`; say so.
- Save `stop hook: FILE` in `.grasp.md`. `/grasp update` checks that `HELPER` in that file still
  exists (a plugin update moves it) and rewrites the path when it does not.
- The guard `[ -x "$t" ] || exit 0` means a teammate without grasp is never blocked.

Two ceilings, by design. A dirty tree the session did not touch also trips the reminder, once;
the message says so, and the agent answers that it changed nothing and stops again. And where
several repositories share one run records folder, any new record in that folder satisfies the
check, whichever project it is about.

## In CI (optional)

The same check fits a pull request job: `grasp-tools record-check --base origin/<integration
branch>` exits 1 when the branch changed files and added no record. Offer it only when asked.
