# Trackers: one contract, many sources

Detail for step 1 of [SKILL.md](../SKILL.md) and every tracker write.

## The contract

Whatever the source, intake produces the same note in the run's scratch folder:

```
key:        PROJ-123 | owner/repo#42 | LIN-7 | text
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
| `LIN-7`, `linear.app/...` | the Linear MCP tools (`get_issue`, `list_comments`) |
| `group/proj#9`, `gitlab.com/...` | `glab issue view 9 -R group/proj --comments` |
| a `.md` or `.txt` path | read the file |
| quoted text | the text is the body; `key: text` |

`ABC-123` is ambiguous between Jira and Linear: `.grasp.md` settles it; if it is not set, ask.

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
