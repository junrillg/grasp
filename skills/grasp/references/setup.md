# Setup and update

Detail for `setup`, `update` and the first run in a repository in [SKILL.md](../SKILL.md).

The helper `grasp-tools` sits in the skill's own folder: `<skill dir>/bin/grasp-tools`, where
`<skill dir>` is the folder holding this skill's `SKILL.md` (Claude Code shows it as the skill's
base directory). Run it from the repository root, where `.grasp.md` lives. `grasp-tools -h`
lists its commands.

## `/grasp setup`

Runs by itself the first time grasp is used in a repository without `.grasp.md`. Running it
again edits the existing file: show the current value for each step and keep it unless the user
changes it. One question at a time, in plain words. Write `.grasp.md` from
[templates/grasp-config.md](../templates/grasp-config.md) at the end and tell the user to commit
it.

### 1. Tracker

Detect before asking: the git remote host, connected tools (Atlassian, ClickUp, Linear, GitHub,
GitLab, Azure DevOps), CLIs on the path (`gh`, `acli`, `glab`, `az`), and keys in recent branch
names (`git branch -a --sort=-committerdate | head -30`). Propose the best match with the reader
you would use ([trackers.md](trackers.md)) and ask the user to confirm or pick another, including
"other" (any tool or CLI they name) and "none, I paste issues".

### 2. Tracker test (live)

Ask for one real issue key or URL. Read it with the chosen reader and show the user what came
back, in a few lines: title, the first lines of the body, the comment count with the newest
comment's author, and one attachment opened (or "no attachments"). Ask whether that matches
what they see in the tracker.

- Check write permission without writing: the tool's permission or project-role call when it
  has one, otherwise say "write access not checked". Offer a real test comment only as a
  separate question, show its exact text, and post only on a yes.
- Save `type`, `reader`, `project or repo` and `tested: YYYY-MM-DD ok`, or
  `tested: YYYY-MM-DD failed (title | body | comments | attachments | write)` naming the part that
  failed. A failed test is saved too, and said plainly; never report a tracker as working when
  this read did not succeed.
- Never ask for, handle or print a token. A reader that needs signing in: say how to sign in and
  re-run only this step.

### 3. Checks and app

Detect lint, test and build commands from `package.json` scripts, `pyproject.toml`, `Makefile`
or CI files, and confirm them. Ask for the command that starts the app and the URL it serves
(for screenshots, [notebook.md](notebook.md)); "no UI" is a valid answer.

### 4. Docs location

Always confirm, even when detected: propose `docs/how-it-works/` at the repository root (or the
folder an existing `docs/` router already uses for this kind of page), show the files the first
page will create, and wait for a yes or another path.

### 5. Learning links

Ask whether the team has LinkedIn Learning. Save `linkedin learning: yes` or `no`. With `no`,
"Learn more" lists only free material.

### 6. Connect this project's skills

Find skills in this project that do grasp's kinds of work, so they can call grasp for the
learning page while keeping their own job.

1. Scan `.claude/skills/*/SKILL.md` and `.agents/skills/*/SKILL.md`. Skip grasp itself and any
   symlink into a global skills folder: project scope only.
2. For each, read the frontmatter `name` and `description` and the headings. Propose a step when
   it overlaps:

   | The skill | Step |
   | --------- | ---- |
   | works or implements an issue, ticket, story or task | `work` |
   | verifies, tests or QAs a fix | `verify` |
   | reviews a pull or merge request | `review` |
   | resolves or addresses review comments | `resolve` |

   No overlap: leave it out. Already connected (listed by `grasp-tools status`): show it as
   connected and leave it out of the question.
3. Ask with AskUserQuestion, `multiSelect: true`: one option per proposed skill, the skill name
   as the label, and "step, and why" as the description (`work: it implements Jira tickets
   end to end`). At most 4 options per question; put the rest in a follow-up question. None
   picked is fine.
4. Show the block that will be added to the end of each picked skill's `SKILL.md` (the exact
   text `connect` writes, between `<!-- grasp:start ... -->` and `<!-- grasp:end -->`), and say
   nothing else in their file changes. On a yes, for each:
   `grasp-tools connect .claude/skills/NAME STEP`. It records the skill in `.grasp.md` under
   "Connected skills".
5. To undo one later: `grasp-tools disconnect .claude/skills/NAME`.

The block makes the connected skill run `/grasp page <issue or PR> --step STEP` when it has
finished its own work. grasp never edits a skill outside its block.

## `/grasp update`

Brings grasp up to date, then refreshes the block in every connected skill.

1. **Find the install.** Resolve `<skill dir>` through symlinks.
   - It resolves into a git repository (a link install from `install.sh`): run
     `git -C <repo> pull --ff-only` and report the old and new `grasp-tools version`. A pull
     that is not a fast-forward: stop and show the git message.
   - It sits under Claude Code's plugin folder (`~/.claude/plugins/`): ask the user to run
     `/plugin marketplace update grasp` (an agent can't run it) and continue when they confirm.
   - It holds a `.source` file (a copy install): run `<path in .source>/install.sh --copy`, with
     `--project <repo root>` when the copy is inside this repository, after a `git -C <path>
     pull --ff-only` there.
2. **Check the connected skills:** `grasp-tools status`. Each line is
   `SKILL_DIR<TAB>STEP<TAB>STATE`.
   - `ok`: nothing to do. A grasp release that doesn't change the block text leaves every
     connected skill untouched.
   - `stale` or `no-block`: show the block that will be written and run `grasp-tools refresh`
     on a yes (or `refresh SKILL_DIR` for just one).
   - `missing`: the skill was moved or deleted. Ask whether to point grasp at its new folder
     (`disconnect` the old path, `connect` the new) or to disconnect it.
3. Report the version, what was refreshed, and anything left as it was.

## Old `.grasp.md` files

A file written by grasp 0.1.0 has no `tested:` line, no `## App`, no `## Learning` and no
`## Connected skills`. Never force a full setup for that. Ask for a missing part the first time a
run needs it (the app command when a screenshot is due, LinkedIn Learning when writing "Learn
more"), save it, and carry on. `grasp-tools connect` adds the Connected skills section itself.

## Later runs

When a tracker read fails, say which part failed (title, body, comments or attachments) and
offer to re-run only step 2. Never re-run the whole setup for it.
