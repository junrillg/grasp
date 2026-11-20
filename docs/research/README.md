# Why grasp works the way it does

Research done in November 2026. Each design choice below links to the notes behind it.

| Finding | What grasp does about it | Notes |
| ------- | ------------------------ | ----- |
| Handing the thinking to the AI is what loses understanding. In Anthropic's January 2026 trial, developers who delegated scored 17% lower on a quiz with no real speed gain; those who asked conceptual questions or asked for code plus explanation kept their understanding. | Step 2 makes the developer state the why and pick the approach. Questions the user asks are logged on the page. | [learning-pages.md](learning-pages.md), [comprehension-before-and-app-map.md](comprehension-before-and-app-map.md) |
| Missing intent turns into cognitive debt ("intent debt"). Spec-first tools write intent down before code, but long specs for small tasks go unread. | The before half is a short spec (150-250 words) that scales with the work, and the build is compared against it. | [comprehension-before-and-app-map.md](comprehension-before-and-app-map.md) |
| Answering a question beats rereading (retrieval practice); guessing before learning helps memory for what was guessed (pretesting). | One prediction question before the build, one explain-back after, model answers folded away. Never blocking. | [learning-pages.md](learning-pages.md) |
| A diagram plus a few words beats words alone. | Mermaid first on every page; one image only for a new domain idea. | [learning-pages.md](learning-pages.md) |
| Docs survive only when a step the team always takes updates them. Hosted auto wikis drift (one measured 29-33 commits behind). | Pages are written inside the run that builds the change, from its diff. | [learning-pages.md](learning-pages.md), [comprehension-before-and-app-map.md](comprehension-before-and-app-map.md) |
| ARCHITECTURE.md-style maps (codemap, invariants, boundaries, names not links) age well. Long generated context files loaded into every session lowered agent success and added about 20% cost. | One app map page, patched per issue, kept in the notebook and out of CLAUDE.md / AGENTS.md. | [comprehension-before-and-app-map.md](comprehension-before-and-app-map.md) |
| Incremental patching costs a small fraction of regeneration and keeps more detail. | Diff in, patch out; one subagent per page, Sonnet to write, Haiku to patch. | [comprehension-before-and-app-map.md](comprehension-before-and-app-map.md) |
| Superpowers-style gates (one question at a time, 2-3 approaches, approval before code, evidence before "done") keep agents honest. | Same gates, in steps 2, 4 and 5. | [packaging-and-workflow.md](packaging-and-workflow.md) |
| Skills load cheaply when SKILL.md is short and detail sits in one-level references; the open Agent Skills format works across Claude Code, Codex, Cursor and Gemini. | SKILL.md is the router; each step reads only its own reference. Frontmatter is standard-only. | [packaging-and-workflow.md](packaging-and-workflow.md) |
| Trackers differ, but every issue reduces to title, body, comments, attachments and acceptance criteria. | One intake contract, a reader per tracker, plain text as the fallback. | [packaging-and-workflow.md](packaging-and-workflow.md) |
| Pages are skimmed, not read: people scan headings and pictures, folded content often goes unopened, and a diagram beside a caption beats separated text. Markdown inside HTML doesn't render in Obsidian. | Pictures with one-line captions stay visible; detail sits in single-block HTML toggles (tested in Obsidian and on GitHub) whose titles state the conclusion; blockers are never folded. | [visual-pages.md](visual-pages.md) |

Open gaps: no study yet covers professionals learning from agent-built code over months, and
nothing ranks C4 against request traces against glossaries for learning. Treat the prediction
question as a cheap bet, not a proven one.
