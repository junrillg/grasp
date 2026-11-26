# 2026-11-26: understanding-first design

Status: done · Claude Code · branch `main`

- **Asked:** Work out how grasp should change so a card's owner understands what an agent built, with research into how others do it.
- **Changed:** Nothing behaves differently yet: a research note, an approved design and a 14-task build plan were written for page standard 2, `walk`, `sync`, `repair` and `explain`.
- **Checked:** not checked: documents only, no tests run.
- **Problems:** One research claim about Obsidian's diagram engine was not re-checked, and nothing is committed yet.
- **Next:** See [the build record](2026-11-26-understanding-first-build.md).

```mermaid
flowchart LR
  A["Audit of 25 real pages"] --> C["Design, approved"]
  B["Research note"] --> C
  C --> D["Build plan, 14 tasks"]
  D --> E["Owner picks how to run it"]
```
