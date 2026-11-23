<!-- grasp:start b=1 v=0.4.0 step=record dir=docs/how-it-works/runs -->
## Run records (grasp)
Before your final message on any task that changed files in this repository, write one run record:
`docs/how-it-works/runs/YYYY-MM-DD-short-name.md`. It is part of the task, also when you were told to change only
certain files. One file per task; the same task continued updates its file.
Start it with `# YYYY-MM-DD: short name` and `Status: done` (or `partial`, `blocked`, `failed`), then
exactly these five lines, one short plain sentence each:
- **Asked:** the request.
- **Changed:** what behaves differently now.
- **Checked:** the command you ran and its result line, or "not checked".
- **Problems:** what failed, was worked around or is uncertain, or "none".
- **Next:** what a person should do or decide next, or "nothing".
Under them, when the change has a shape (steps, or parts that connect), add one small Mermaid
`flowchart` of it: at most 10 boxes, every label in double quotes.
Write only what happened: never claim a change or a check you did not make. No secrets, tokens,
env values or raw command output. Skip it for questions and for runs that changed no files.
With the grasp skill installed, `/grasp record` writes it and rebuilds the index.
<!-- grasp:end -->
