# grasp settings

<!-- Saved as .grasp.md at the repository root by the first /grasp run. Commit it.
     No secrets here: tokens stay in the tracker tool or the OS keychain. -->

## Tracker

- type: {jira | github | linear | gitlab | none}
- reader: {e.g. "Atlassian MCP", "gh", "bin/tracker" (a project wrapper), "Linear MCP"}
- project or repo: {e.g. PROJ, owner/repo}
- comments: {ask | never}

## Notebook

- target: {notion | markdown | off}
- notion parent: {page id, filled on first run}
- notion features: {page id}
- notion app map: {page id}
- markdown folder: docs/grasp

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
