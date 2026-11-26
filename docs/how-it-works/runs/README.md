# Run records

What agents did here, newest first. One row per task; open it for the detail.

This table is built by `grasp-tools record-index`. Don't edit it by hand: run that again, also to settle a merge conflict here.

| Date | Task | Status | What changed | Problems |
| ---- | ---- | ------ | ------------ | -------- |
| 2026-11-26 | [understanding-first design](2026-11-26-understanding-first-design.md) | partial | Nothing behaves differently yet: a research note, an approved design and a 13-task build plan were written for page standard 2, `walk`, `sync`, `repair` and `explain`. | One research claim about Obsidian's diagram engine was not re-checked, and nothing is committed yet. |
| 2026-11-26 | [change map and three zoom levels](2026-11-26-change-map-and-zoom-levels.md) | done | `grasp-tools change-map` draws the code base coloured new, changed or untouched from git, and an issue page's after half now opens with it, a part-by-part table and one folded toggle per part. | The map counts folders, not jobs: a person still renames the boxes and draws the arrows. |
| 2026-11-24 | [Architecture page and system design lessons](2026-11-24-architecture-page-and-lessons.md) | done | `map` and setup now also write an architecture page: the design by name, why and at what cost, what fails, what gives first, and checked lessons; grasp has its own. | The render check failed on five pages whose files did not change, and its rerun failed its own control; the page was not tried on another app. |
| 2026-11-23 | [Goal review: live steps, concepts, length limits, one-line install](2026-11-23-goal-review-steps-concepts-limits.md) | done | Pages show steps ticked during the build, concepts with long text folded, planned against built; the linter fails long pages; explain-back waits for an answer; one-line install; MIT license. | The skill's description was invalid YAML, so the skills CLI skipped grasp; two live runs found 38 unclear instructions. All fixed. |
| 2026-11-21 | [Uninstall removes only grasp's own installs](2026-11-21-uninstall-own-installs-only.md) | done | `--uninstall` now leaves a `grasp` folder it did not install and says it skipped it; before, any folder holding a `SKILL.md` was deleted. | none |
| 2026-11-21 | [Run records, app overview at setup, workspaces](2026-11-21-run-records-overview-workspaces.md) | done | `setup` now adds a run-record block to `AGENTS.md`, writes an app map with feature pages, and covers each sub-project of a workspace. | A review found the helper could empty `AGENTS.md`, a trial found pages git ignored, and Obsidian shrank one wide diagram to unreadable; all three fixed. |
