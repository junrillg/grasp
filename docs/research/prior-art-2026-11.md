# Prior art check, 2026-11-23: what others do that grasp did not

A second pass over the field, reporting only what the earlier notes had not covered. "Opened" means the source page was read; "search only" means it was seen through a search summary and is unverified.

## What changed in grasp because of it

| Finding | Source | Read how | What grasp does now |
| ------- | ------ | -------- | ------------------- |
| Spec tools show planned against built as a delta (added, modified, removed), and a post-build check lists what the plan asked for that was not done. | [OpenSpec](https://github.com/Fission-AI/OpenSpec/blob/main/docs/getting-started.md), [Spec Kit converge](https://github.github.io/spec-kit/reference/agentic-sdd.html) | search only | The issue page has a "Planned and built" table: one row per step that changed or was not done. A step not done becomes the run record's Next line. |
| Plan files carry to-dos that tick as the agent works. | [Cursor agent best practices](https://cursor.com/blog/agent-best-practices) | search only | The before half lists 3 to 6 steps; the build sets the page to `building` and ticks each step as it finishes. |
| One command installs a skill into many agents from one copy: `npx skills add`, with `--skill`, `-g`, `-a`. | [vercel-labs/skills commands](https://github.com/vercel-labs/skills/blob/main/docs/commands.md) | opened, and run locally | README gives the one-line install. The run found grasp's frontmatter was not valid YAML (an unquoted description holding `: `), so the CLI skipped the skill; the description is now quoted and a test pins it. |
| LinkedIn Learning serves the course title in the page's `<title>`, so a course can be named without guessing. | checked live with `curl` on 2026-11-23 | run | `check-link` prints the course title for LinkedIn Learning and fails without one. |
| Obsidian 1.15 draws Mermaid with zoom and pan when a diagram is scaled down, and the "Show Mermaid diagrams" setting is gone. | [Obsidian 1.15 changelog](https://obsidian.md/changelog/2026-11-02-desktop-v1.15.0/) | opened | Nothing changed: top-to-bottom diagrams still read without zooming. The "allow Mermaid banner" doubt in [visual-pages.md](visual-pages.md) is settled. |

## Looked at, not adopted

| Finding | Source | Read how | Why not, for now |
| ------- | ------ | -------- | ---------------- |
| Learners who had to explain generated code back before using it failed a later no-AI task far less often (39% against 77%, 78 novices). | [arXiv 2602.20206](https://arxiv.org/abs/2602.20206) | opened | grasp already asks one explain-back question and never blocks on it. Making it a gate is the owner's call. |
| A steering file lists the pages a generated wiki must have, capped at 30. | [DeepWiki docs](https://docs.devin.ai/work-with-devin/deepwiki) | opened | grasp caps the app map at 9 features and writes pages only for features worth tracing. |
| A map generated from one question, in execution order, each node linked to its code. | [Windsurf Codemaps](https://docs.devin.ai/desktop/codemaps) | opened | A possible `/grasp map "question"`. Not built. |
| A bug spec is written as current, expected and unchanged behaviour. | [Kiro specs](https://kiro.dev/docs/specs/best-practices/) | search only | Bugs get a root cause and a failing test instead of a page. |
| `gh skill install` installs skills into 48 hosts. | [GitHub CLI manual](https://cli.github.com/manual/gh_skill_install) | search only | Not tested here, so not in the README. |
| Copilot, OpenCode, Windsurf and Goose also read `.agents/skills` or `.claude/skills`. | vendor docs | search only | Not tested here, so the README names only the agents the skills CLI itself reported: Claude Code, Codex, Cursor, Gemini CLI. |
| Obsidian Canvas and Bases. | [Obsidian help](https://help.obsidian.md/plugins/canvas) | search only | Obsidian only; they show nothing on GitHub. |

No tool was found that writes one overview across several repositories; the workspace map has no counterpart in what was read.
