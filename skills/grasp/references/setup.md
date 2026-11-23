# Setup and update

Detail for `setup`, `update` and the first run in a repository in [SKILL.md](../SKILL.md).

The helper `grasp-tools` sits in the skill's own folder: `<skill dir>/bin/grasp-tools`, where
`<skill dir>` is the folder holding this skill's `SKILL.md` (Claude Code shows it as the skill's
base directory). Run it from the repository root, where `.grasp.md` lives. `grasp-tools -h`
lists its commands.

## `/grasp setup`

Runs by itself the first time grasp is used in a repository without `.grasp.md`. Running it
again edits the existing file: show the current value for each step and keep it unless the user
changes it. One question at a time, in plain words.

Setup does three things a team needs before the first task: it makes the settings file
(steps 1 to 5), it makes every later agent run leave a record (step 6), and it writes the
overview of the app so there is something to read on day one (step 8).

| Step | Asks | Writes |
| ---- | ---- | ------ |
| 0 Scope | which sub-projects, where their pages go (workspaces only) | nothing yet |
| 1-5 Settings | tracker, one real issue, checks, app, docs folder, LinkedIn Learning | `.grasp.md` |
| 6 Run records | which instructions file, Stop hook yes/no | the block in `AGENTS.md` or `CLAUDE.md`, the `runs/` folder |
| 7 Connect skills | which of the project's skills | the block in each picked skill |
| 8 Overview | to confirm the feature list | the app map, feature pages, the workspace map |

### 0. Scope

Run `grasp-tools projects` from the folder setup was started in. No output: this is one project;
go to step 1. Any output: this is a workspace. Follow "Workspaces" in [overview.md](overview.md):
show the list, ask which sub-projects to cover and where their pages go, then run steps 1 to 7
for the top folder first and for each sub-repository after it, asking a sub-repository only what
differs from the top (its tracker project, its checks, its branch). Step 8 covers them all.

Every folder an agent may be started in gets its own `.grasp.md` and its own run-record block:
the top folder and each sub-repository ("one repository, one block" means never two blocks in
one repository, not one block for the whole workspace). A top folder that is not a git
repository has no branch, no pull request command and no `.gitattributes`: write `none` for
those settings and skip the `.gitattributes` line.

### 1. Tracker

Detect before asking: the git remote host, connected tools (Atlassian, ClickUp, Linear, GitHub,
GitLab, Azure DevOps), CLIs on the path (`gh`, `acli`, `glab`, `az`), and keys in recent branch
names (`git branch -a --sort=-committerdate | head -30`). Propose the best match with the reader
you would use ([trackers.md](trackers.md)) and ask the user to confirm or pick another, including
"other" (any tool or CLI they name) and "none, I paste issues".

### 2. Tracker test (live)

No tracker ("none, I paste issues"): skip this step and save `tested: not tested (no tracker)`.

Ask for one real issue key or URL. Read it with the chosen reader and show the user what came
back, in a few lines: title, the first lines of the body, the comment count with the newest
comment's author, and one attachment opened (or "no attachments"). Ask whether that matches
what they see in the tracker.

- Check write permission without writing: the tool's permission or project-role call when it
  has one, otherwise say "write access not checked". Offer a real test comment only as a
  separate question, show its exact text, and post only on a yes.
- Save `type`, `reader`, `project or repo` and `tested: YYYY-MM-DD ok`, or
  `tested: YYYY-MM-DD failed (title | body | comments | attachments | write)` naming the part that
  failed, or `tested: not tested (why)` when the user gives no issue to read. A failed test is saved too, and said plainly; never report a tracker as working when
  this read did not succeed.
- Never ask for, handle or print a token. A reader that needs signing in: say how to sign in and
  re-run only this step.

### 3. Checks, app and code

Detect lint, test and build commands from `package.json` scripts, `pyproject.toml`, `Makefile`
or CI files, and confirm them. Ask for the command that starts the app and the URL it serves
(for screenshots, [notebook.md](notebook.md)); "no UI" is a valid answer.

Detect the rest of `## Code` and `## Voice` and confirm it in the same message, never as four
questions: the integration branch (the remote's default branch; with no remote, the current
branch), the branch pattern (from recent branch names), the pull request command (`gh`, `glab`,
a project wrapper, or "none"), and the project's rules on voice and attribution (from the
project's own `AGENTS.md` or `CLAUDE.md`, not a personal one; "none written" is fine). With no
tracker, `comments:` is `never`.

### 4. Docs location

Always confirm, even when detected: propose `docs/how-it-works/` at the repository root (or the
folder an existing `docs/` router already uses for this kind of page), show the files setup will
create there (in a workspace, the folder per sub-project), and wait for a yes or another path.
Then make sure git will keep the pages, as "Not git-ignored" in [overview.md](overview.md) says:
test the path of a page about to be written, one per sub-project folder.

Then ask: "Do you read these pages in Obsidian?" Save `obsidian: yes` or `no`. On yes, the vault
is the docs root (the `docs/` folder that holds the notebook folder; the notebook folder itself
when there is no `docs/` above it). When that folder has no `.obsidian/` yet, create two files and
nothing else:

- `.obsidian/app.json`: `{"useMarkdownLinks": true, "newLinkFormat": "relative", "attachmentFolderPath": "./assets"}`.
  It makes links created by hand in Obsidian standard Markdown links, which is what `lint-page`,
  GitHub and doc sites need.
- `.obsidian/.gitignore`: one line, `workspace*.json` (Obsidian rewrites those on every click).

A folder that already has `.obsidian/` is somebody's vault: change nothing in it; when its
`app.json` lacks `"useMarkdownLinks": true`, say so and let the user switch it on (Settings,
Files and links, "Use [[Wikilinks]]" off). Tell the user to open that folder as a vault; never
rename a vault from inside Obsidian, since that renames the folder on disk.

### 5. Learning links and illustrations

Ask whether the team has LinkedIn Learning. Save `linkedin learning: yes` or `no`. With `no`,
"Concepts" lists only free material.

Then ask once whether pages should open with a generated illustration (one image generation per
page: the app map, the workspace map and each issue page). Save `illustrations: yes` or `no`.
Say which image tool was found; with none, say so, save the answer anyway and write diagrams only
until one is available ("Illustrations" in [notebook.md](notebook.md)).

Now write `.grasp.md` from [templates/grasp-config.md](../templates/grasp-config.md), with
`run records:` set to `<docs folder>/runs`. The steps below read it.

### 6. Run records

Follow "The block in AGENTS.md and CLAUDE.md" in [records.md](records.md). This is what makes
every agent task leave a record, including the ones that never go through `/grasp`.

1. Look at what the project has: `AGENTS.md`, `CLAUDE.md`, both or neither, and whether
   `CLAUDE.md` holds the line `@AGENTS.md`.
2. Propose the file (`AGENTS.md`, created when missing; `CLAUDE.md` only when the user wants no
   `AGENTS.md`), show the exact block that will be written (`grasp-tools block record` prints
   it), and say nothing else in the file changes. On a yes: `grasp-tools connect AGENTS.md record`.
3. A `CLAUDE.md` that exists without the import: Claude Code then does not read `AGENTS.md`, so
   offer `grasp-tools connect CLAUDE.md import` (it adds the one line `@AGENTS.md` in a marked
   block; `grasp-tools block import` prints it). Run it only on a yes. No `CLAUDE.md`: nothing
   to add, unless the user says someone runs a Claude Code older than 2.1.277.
4. Create the run records folder and its index: `grasp-tools record-index` (after `mkdir -p` of
   the folder). Offer one line for `.gitattributes`, `<run records folder>/README.md merge=union`,
   so two branches that both rebuild the index merge without a conflict. The line goes in the
   repository that holds the folder, once.
5. Ask whether to add the Stop hook ("The Stop hook" in [records.md](records.md)): off by
   default; explain in one line that the instruction file is advice and the hook is the reminder
   that can't be forgotten. On a yes, merge the entry and save `stop hook: FILE` in `.grasp.md`.

To undo: `grasp-tools disconnect AGENTS.md`, and `grasp-tools disconnect CLAUDE.md` for the
import.

### 7. Connect this project's skills

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
   text `connect` writes, printed by `grasp-tools block STEP`), and say
   nothing else in their file changes. On a yes, for each:
   `grasp-tools connect .claude/skills/NAME STEP`. It records the skill in `.grasp.md` under
   "Connected skills".
5. To undo one later: `grasp-tools disconnect .claude/skills/NAME`.

The block makes the connected skill run `/grasp page <issue or PR> --step STEP` when it has
finished its own work. grasp never edits a skill outside its block.

### 8. Overview

Follow [overview.md](overview.md). Skip only when the app map already exists and the user does
not want it refreshed. When setup started by itself in front of another run (the first
`/grasp ISSUE` in a repository), ask first: write the overview now, or later with `/grasp map`?
The issue the user came for should not wait on it unless they choose so.

1. Explore as "Exploring the code" describes, one subagent per app (per sub-project in a
   workspace, in parallel).
2. Show the user the feature list (at most 9 core features, in their words) and let them rename
   or drop rows. Say which features will get a page of their own ("Scale with the app" in
   overview.md decides; a small project gets none) and ask whether to write those now
   (recommended) or only the app map. Show the concepts picked for the app map (at most 5) in
   the same message, so a wrong or missing one is caught before pages are written.
3. Write the app map, the feature pages that earn one and, in a workspace, the workspace map
   (a small workspace gets the workspace map alone: "Scale with the app" in overview.md).
   Create the notebook's `README.md` (the pages in reading order: the app map, Features once
   that table exists, Run records) and add the same rows to the docs router. In a workspace the
   README and the router follow "Settings in a workspace" in overview.md instead. Feature pages
   are reached from the app map, not from the router. Run `grasp-tools lint-page` on each page.

### Finish

- Write setup's own run record with `/grasp record "grasp set up"` ([records.md](records.md)): it
  is the first row of the table and proves the folder, the index and the block work. One record,
  also in a workspace.
- Tell the user what to open first (the app map, or the workspace map) and list what was
  written. `.grasp.md`, the instruction file and the new pages are new, uncommitted files in each
  repository: offer one commit per repository (`chore: set up grasp`), files staged by path, and
  make it only on a yes. Left uncommitted, they show up as untracked files in the next issue's
  branch: a later run commits them in a commit of their own, never inside the issue's commit.

## `/grasp update`

Brings grasp up to date, then refreshes the block in every connected skill.

1. **Find the install**, checking in this order (a copy inside a project sits in the project's
   own git repository, so never start with "is it in a git repository"):
   - `<skill dir>` holds a `.source` file (a copy install from `install.sh --copy`): run
     `git -C <path in .source> pull --ff-only`, then `<path in .source>/install.sh --copy`, with
     `--project <repo root>` when the copy is inside this repository. It replaces grasp's own
     earlier copy.
   - `<skill dir>` is a symlink whose target is `skills/grasp` inside a checkout that also holds
     `install.sh` (a link install): run `git -C <that checkout> pull --ff-only` and report the old
     and new `grasp-tools version`. A pull that isn't a fast-forward: stop and show git's message.
   - It sits under Claude Code's plugin folder (`~/.claude/plugins/`): ask the user to run
     `/plugin marketplace update grasp` (an agent can't run it) and continue when they confirm.
   - `<skill dir>` is a real folder with no `.source`, or a link into `.agents/skills/`, and
     `grasp` is named in `~/.agents/.skill-lock.json` or in the project's `skills-lock.json`
     (installed with `npx skills add`): run `npx skills update grasp`, with `-g` for the global
     install.
   - None of these: say how grasp seems to be installed and ask; never pull a repository you
     didn't identify as grasp's.
2. **Check what is connected:** `grasp-tools status`. Each line is
   `TARGET<TAB>STEP<TAB>STATE`: a skill folder, or an instructions file (`AGENTS.md`, `CLAUDE.md`)
   with step `record`.
   - `ok`: nothing to do. A grasp release that doesn't change the block text leaves every
     connected skill untouched.
   - `stale` or `no-block`: show the block that will be written and run `grasp-tools refresh`
     on a yes (or `refresh TARGET` for just one). The run-record block is also `stale` when
     `run records:` in `.grasp.md` moved.
   - `missing`: the skill was moved or deleted. Ask whether to point grasp at its new folder
     (`disconnect` the old path, `connect` the new) or to disconnect it.
   - `broken`: the skill has a `grasp:start` line with no `grasp:end` after it, usually from a
     hand edit. grasp-tools refuses to touch it, so nothing below the marker can be lost. Show
     the user the lines and ask them to restore or delete the marker, then re-run `status`.
3. **Check the Stop hook**, when `.grasp.md` has a `stop hook:` line: the helper path inside that
   file must still exist (a plugin update moves it). Rewrite the path to this skill's current
   `bin/grasp-tools` when it does not, and say so.
4. **Rebuild the run records index:** `grasp-tools record-index`, when the folder exists.
5. Report the version, what was refreshed, and anything left as it was.

## Old `.grasp.md` files

A file written by grasp 0.1.0 has no `tested:` line, no `## App`, no `## Learning` and no
`## Connected skills`. Never force a full setup for that. Ask for a missing part the first time a
run needs it (the app command when a screenshot is due, LinkedIn Learning when writing
"Concepts", `illustrations:` when a page that may open with a picture is written), save it, and
carry on. `grasp-tools connect` adds the Connected skills section itself.

A file written before 0.3.0 has no `run records:` line, no run-record block in the instruction
files and usually no app map. Runs still work: records go to the default
`docs/how-it-works/runs`. The first run in such a project says once, in one line, that
`/grasp setup` will add the run-record block and the overview (steps 6 and 8), and carries on.

## Later runs

When a tracker read fails, say which part failed (title, body, comments or attachments) and
offer to re-run only step 2. Never re-run the whole setup for it.
