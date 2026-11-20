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
- tested: {YYYY-MM-DD ok | YYYY-MM-DD failed (title | body | comments | attachments | write)}

## Notebook

- target: {markdown | notion | off}
- markdown folder: {docs/how-it-works, confirmed with the user on the first run}
- docs router: {docs/README.md, or none}
- docs repo: {same | path of a separate docs repository, e.g. a workspace wrapper}
- notion parent: {page id, only for target notion}
- notion features: {page id, only for target notion}
- notion app map: {page id, only for target notion}

## Code

- integration branch: {develop | main}
- branch pattern: {TYPE/KEY-short-name}
- pull request host command: {e.g. "gh", or a project wrapper}

## Checks (run one at a time, in this order)

- {lint command}
- {test command}
- {build command}

## Voice

- {e.g. "first person, no AI attribution", or "see CLAUDE.md"}

## App

- run: {command that starts the app, e.g. npm run dev, or "no UI"}
- url: {e.g. http://localhost:3000}

## Learning

- linkedin learning: {yes | no}

## Connected skills

<!-- Written by `grasp-tools connect`; refreshed by /grasp update. Edit with connect/disconnect. -->

| skill | step | grasp version |
| ----- | ---- | ------------- |
| {.claude/skills/work-issue} | {work | verify | review | resolve} | {0.2.0} |
