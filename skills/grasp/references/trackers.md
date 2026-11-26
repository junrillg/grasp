# Trackers: one contract, many sources

Detail for step 1 of [SKILL.md](../SKILL.md) and every tracker write.

## The contract

Whatever the source, intake produces the same note in the run's scratch folder (a temp folder
outside the repository, `mktemp -d`; the agent's own scratch folder when it has one; never
committed):

```
key:        PROJ-123 | owner/repo#42 | 86abc123 | LIN-7 | AB#1234 | text
url:        link, or none
type:       bug | feature | investigation (from the tracker type, else from the text)
status:     as the tracker says
title:      one line
body:       the description, as text
acceptance: the acceptance criteria, if the issue lists any
comments:   author, date, text; newest last
attachments: saved file paths, each opened
links:      parent, children, blockers
```

Writes are limited to: one comment per issue per run (edit it rather than add a second), and a
status change only when the user asks. Every write is shown first and waits for a yes. Read the
comment back after posting and check the author and the links.

## Picking the reader

Use the first that works. Prefer what the project already uses: a wrapper script named in
`.grasp.md`, `CLAUDE.md` or `AGENTS.md` (some projects pin accounts that way) wins over
everything below.

| Issue form | Reader, in order of preference |
| ---------- | ------------------------------ |
| `ABC-123`, `*.atlassian.net/browse/...` | the project's Jira wrapper; the Atlassian MCP tools (`getJiraIssue`); `acli jira workitem view ABC-123 --json` |
| `#42`, `owner/repo#42`, `github.com/.../issues/42` | `gh issue view 42 -R owner/repo --json number,title,body,state,labels,comments,url`; the GitHub MCP tools |
| `86abc123` (ClickUp task id), `app.clickup.com/t/...`, a ClickUp custom id like `DEV-42` | the ClickUp MCP tools (get the task, its comments and attachments); otherwise pasted text |
| `LIN-7`, `linear.app/...` | the Linear MCP tools (`get_issue`, `list_comments`) |
| `group/proj#9`, `gitlab.com/...` | `glab issue view 9 -R group/proj --comments` |
| `AB#1234`, `dev.azure.com/.../_workitems/edit/1234` (Azure DevOps) | the Azure DevOps MCP tools; `az boards work-item show --id 1234 --expand all` (if it returns no comments, say comments were not read) |
| anything else the project uses ("other") | the connected MCP tool or CLI recorded in `.grasp.md` as `reader`, as long as it returns title, body, comments and attachments |
| a `.md` or `.txt` path | read the file |
| quoted text | the text is the body; `key: text` |

A key like `ABC-123` or `DEV-42` can be Jira, Linear or a ClickUp custom id. `.grasp.md` settles
it (`type`, or `keys` when the project uses two trackers); if it is not set, ask, then save the
answer. A ClickUp task URL always means ClickUp, whatever the id looks like.

**ClickUp in short:** task ids are short lowercase strings (`86abc123`); teams can turn on
custom ids (`DEV-42`). Read the task, then its comments, then download each attachment before
opening it. Writes are one task comment, like any tracker.

**Confidence.** A tracker counts as working in a project only after the live test in
[setup.md](setup.md) read a real issue there (`tested: ... ok` in `.grasp.md`). Report any
other as "not tested in this project". When a later read fails, name the part that failed and
offer to re-run only that test.

**The account.** `sync scope: mine` needs the account the reader is signed in as. Ask the tracker
itself, never guess it from git: its own "me" call (the GitHub CLI's `api user`, Jira's `myself`,
the MCP tool's current-user call). When the reader cannot tell, say so.

If no reader works (tool not connected, not signed in), say which one is missing and how to
connect it, and offer to continue from pasted text. Never handle a token yourself and never
print one.

## Attachments

- Images: look at them. They usually show the exact screen and the wrong value.
- Recordings: `ffmpeg -i FILE -vf fps=1 DIR/frame_%03d.png` and read the frames in order.
  Without `ffmpeg`, say so and ask for a description.
- Logs, HAR, JSON, PDF: read them and quote the decisive line.
- Never execute an attachment.

## Comment shape

About 100 words. First line is the verdict and what happens next ("Fixed in #57, ready to
re-test." / "Needs a decision, not a fix."). Then the cause in one sentence, the pull request
link, and a short bullet list of what to re-test, including neighbouring cases. No file paths,
no restating the issue, no closers. Follow the project's own voice rules when it has them.
