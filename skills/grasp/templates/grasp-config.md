# grasp settings

<!-- Saved as .grasp.md at the repository root by /grasp setup (it runs by itself on the first
     /grasp run). Commit it.
     No secrets here: tokens stay in the tracker tool or the OS keychain. -->

## Tracker

- type: {jira | github | clickup | linear | gitlab | azure-devops | other | none}
- reader: {e.g. "Atlassian MCP", "gh", "ClickUp MCP", "az boards", "bin/tracker" (a project wrapper)}
- project or repo: {e.g. PROJ, owner/repo, ClickUp space or list}
- keys: {only when a key like DEV-42 could be two trackers: which one it means}
- comments: {ask | never}
- tested: {YYYY-MM-DD ok | YYYY-MM-DD failed (title | body | comments | attachments | write) | not tested (why)}

## Notebook

- target: {markdown | notion | off}
- markdown folder: {docs/how-it-works, confirmed with the user on the first run}
- run records: {docs/how-it-works/runs; read by grasp-tools, relative to this file}
- stop hook: {the settings file holding the Stop hook, e.g. .claude/settings.local.json; or none}
- docs router: {docs/README.md, or none}
- obsidian: {yes | no; yes means setup wrote .obsidian/app.json in the docs root}
- docs repo: {same | path of a separate docs repository, e.g. a workspace wrapper | none (the folder is not a git repository)}
- notion parent: {page id, only for target notion}
- notion features: {page id, only for target notion}
- notion app map: {page id, only for target notion}

## Code

- integration branch: {develop | main}
- branch pattern: {TYPE/KEY-short-name; a text issue has no key: TYPE/short-name}
- pull request host command: {e.g. "gh", or a project wrapper}

## Checks (run one at a time, in this order)

- {lint command}
- {test command}
- {build command}

## Voice

- {e.g. "first person, no AI attribution", or "see CLAUDE.md"}

## App

- run: {command that starts the app, e.g. npm run dev; "no UI"; or "UI, no start command known"}
- url: {e.g. http://localhost:3000}

## Learning

- linkedin learning: {yes | no}
- illustrations: {yes | no}

## Projects

<!-- Only at the top of a workspace (a folder holding several projects). One row per sub-project
     covered: its path, repo or package, where its pages go, and the commit its app map was
     verified at. Delete this section in a single project. -->

| project | kind | notebook folder | mapped at |
| ------- | ---- | --------------- | --------- |

## Connected skills

<!-- Rows are written by `grasp-tools connect` (one per target: path, step, grasp version) and
     refreshed by /grasp update. A row with step `record` is an agent instructions file
     (AGENTS.md or CLAUDE.md) holding the run-record block, not a skill. Start with no rows;
     change them only with connect/disconnect. -->

| skill | step | grasp version |
| ----- | ---- | ------------- |
