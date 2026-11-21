# Run records, and an overview for day one

Searched 2026-11-21. Two questions: how do you make every agent task leave a record a person will
read, and what should a first-day overview of an unfamiliar repository hold, including a folder
of several projects. Items marked "not verified" were not confirmed against a primary source.

## The gap this closes

An audit of grasp 0.2.0 against the goal "know what the agent did, and understand the app":

| Goal | 0.2.0 | Now |
| ---- | ----- | --- |
| Every run is recorded | Only runs through `/grasp` or a connected skill. Bugs got no page, small diffs skipped the after half, one page per issue meant later runs overwrote earlier ones. | A run record per task, written by any agent, listed in one table. |
| Setup updates AGENTS.md or CLAUDE.md | Never touched them. | A 16-line marked block, added and kept current by `grasp-tools`. |
| Setup explains the app | No map step in setup; the map had no feature list and no feature connections. | Setup writes the app map with core features and how they connect, plus a page per core feature. |
| A top folder with sub-projects | Not handled. | `grasp-tools projects` finds them; each gets its app map; a workspace map shows how they fit. |
| Issues met along the way | Blockers on the issue page only. | A Problems line on every record, shown in the table. |

## 1. An instruction file is advice

- Anthropic's memory docs describe `CLAUDE.md` as context, not enforced configuration, and point
  to hooks for anything that must run at a fixed point ([memory](https://code.claude.com/docs/en/memory)).
- Direct commands are followed more often than conditional ones: on Claude Code, 78.0% against
  64.2% (Opus) and 71.6% against 35.6% (Sonnet) ([Tsuchida et al., Nov 2026](https://arxiv.org/html/2611.04367)).
  The rules tested were code-style rules; no study isolates end-of-task rules.
- Placement and file length showed no detectable effect across 1,650 sessions, but compliance
  fell as a session went on ([McMillan, May 2026](https://arxiv.org/abs/2605.10039)). Long runs
  are exactly where an end-of-task rule gets dropped.
- LLM-generated context files lowered agent success and added cost (already in
  [comprehension-before-and-app-map.md](comprehension-before-and-app-map.md)). So the block is
  short, written by hand, and holds no app knowledge.

**What grasp does:** the block opens with a direct command ("Before your final message on any
task that changed files..."), gives five fixed lines, and is 16 lines long. Because advice is
not enough, an optional Stop hook does the reminding.

## 2. The hook is the part that can't be forgotten

Read from the hooks references on 2026-11-21:

- **Claude Code.** A `Stop` hook in `.claude/settings.json` or `.claude/settings.local.json` runs
  when Claude finishes responding. Exit code 2 "prevents Claude from stopping, continues the
  conversation", with stderr as the reason. Its stdin JSON carries `stop_hook_active`, "`true`
  when Claude Code is already continuing as a result of a stop hook"; checking it is the documented
  loop guard, and Claude Code also caps consecutive continuations at 8
  ([hooks](https://code.claude.com/docs/en/hooks)). `SessionEnd` can't block, so it can't make an
  agent write anything.
- **Codex.** The same shape in `.codex/hooks.json`; Stop stdin has `stop_hook_active`; "You can
  also use exit code `2` and write the continuation reason to `stderr`". Hooks load "only from
  trusted project layers" and each must be reviewed and trusted through `/hooks`
  ([hooks](https://learn.chatgpt.com/docs/hooks)).
- A hook with no "did anything change" test demands a note after every question. So
  `grasp-tools record-check` only fires when files changed outside the notebook and no record
  was added.

**Ceilings.** The hook proves a record exists, not that it is true. A dirty tree the session
didn't touch trips it once. The Claude Code hook was run live (it fired and the record was
written). The Codex hook was not: Codex asks the user to approve a hook through `/hooks`, and
this test did not bypass that.

## 3. One block for every agent

- Claude Code reads `AGENTS.md` by itself from v2.1.277, but "only when you have no `CLAUDE.md`
  in your working directory or above it". Otherwise the documented way is "an `@AGENTS.md` import
  in a `CLAUDE.md` next to it" ([memory](https://code.claude.com/docs/en/memory)).
- Codex looks for `AGENTS.override.md`, then `AGENTS.md`, then names listed in
  `project_doc_fallback_filenames`; "filenames not on this list are ignored"
  ([AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)). That Codex
  ignores `CLAUDE.md` by default is inferred from those two sentences, not stated.

**What grasp does:** the block goes in `AGENTS.md`; a `CLAUDE.md` that exists gets the one import
line, after asking. Never the block in both.

**Checked live, 2026-11-21** (Claude Code 2.1.330, Codex CLI 0.169.0), by asking a fresh
session what it had loaded and by giving it a small task with no mention of records:

| Setup | Result |
| ----- | ------ |
| Codex, block in `AGENTS.md` | Wrote the record, in the exact shape |
| Claude Code, trusted repository, `AGENTS.md` only | Block loaded |
| Claude Code, trusted repository, `CLAUDE.md` with the import block | Block loaded through the import |
| Claude Code, Stop hook only, no block | Hook fired; the session went back and wrote the record |
| Claude Code, a folder never trusted | No project instructions loaded at all, so no record |

The last row explains three scratch-folder runs that wrote no record: the cause was folder
trust, not the block or the import. A personal `~/.claude/CLAUDE.md` does not stop Claude Code
from reading a project's `AGENTS.md`.

## 4. What a record a person will read looks like

- Per-task records work. Per-turn is noise; per-session mixes unrelated tasks. Cline's memory bank
  rewrites state each session and keeps no history; Aider's chat history is a transcript nobody
  reads ([Cline](https://docs.cline.bot/prompting/cline-memory-bank)). The Progress Log pattern
  keeps done, tried-and-failed (which it calls the most useful part), decisions and remaining,
  and names staleness as its failure ([pattern](https://aipatternbook.com/progress-log)).
- Agent-written descriptions run long ([arXiv 2509.14745](https://arxiv.org/pdf/2509.14745)) and
  sometimes misstate the change: of 23,247 agent pull requests, 1.7% had high message-code
  inconsistency, and 45.4% of those claimed changes that were never made
  ([Gong et al., MSR '26](https://arxiv.org/html/2601.04886v2)).
- One shared log file conflicts on every merge; towncrier's fix is one fragment per change
  ([towncrier](https://towncrier.readthedocs.io/en/stable/index.html)).
- Logs leak credentials when they hold command output
  ([GitGuardian](https://blog.gitguardian.com/ai-coding-agents-credential-security/)).

**What grasp does:** one file per task; five fixed one-sentence lines (asked, changed, checked,
problems, next); "Checked" names the command and its result line or says "not checked"; no raw
output; the table of all runs is built by a command, so it can't drift and a conflict in it is
settled by building it again.

## 5. What a first-day overview needs

- C4: "the system context and container diagrams are sufficient for most software development
  teams" ([c4model.com](https://c4model.com/diagrams)). arc42's newcomer-facing sections are
  goals, context, building blocks, runtime view and glossary ([arc42](https://arc42.org/overview)).
- CodeWiki (ACL 2026) starts from entry points, builds a feature-oriented module tree and
  synthesises overviews bottom-up ([paper](https://arxiv.org/pdf/2510.24428)). Its scores are
  LLM-judged.
- The 0.2.0 app map had purpose, containers, a traced request, a codemap, rules and a glossary.
  What was missing is the part a newcomer asks for first: what can it do, and how do those things
  connect.
- Size: "any diagram with 20+ elements (perhaps fewer) starts to get complicated quickly"
  ([Simon Brown](https://dev.to/simonbrown/diagramming-distributed-architectures-with-the-c4-model-51cm));
  node-link graphs degrade well before 50 nodes ([Yoghourdjian et al.](https://arxiv.org/abs/2008.07944)).
  "At most 9 features per table" is a working limit, not a sourced one.
- Grounding: a no-retrieval baseline was wrong in 14 of 30 repository answers in one study
  ([arXiv 2512.12117](https://arxiv.org/html/2512.12117)); Anthropic's guidance is to retract a
  claim that has no supporting quote
  ([guardrails](https://docs.claude.com/en/docs/test-and-evaluate/strengthen-guardrails/reduce-hallucinations)).

**What grasp does:** the app map gains "Core features" and "How the features connect"; each core
feature gets a short page so the map stays one page; diagrams hold about 10 boxes, never over 20;
every row names the file it was read from, guesses are marked "(inferred)", and open questions
go under "Not sure yet".

## 6. A folder of several projects

- Structurizr's enterprise pattern keeps each system's docs beside its code and derives the
  landscape from them ([Structurizr](https://docs.structurizr.com/workspaces/enterprise)).
  Backstage models Domain, System, Component ([Backstage](https://backstage.io/docs/features/software-catalog/system-model/)).
- Connections can be found from files, strongest first: workspace or path dependencies,
  docker-compose links and env values that are sibling URLs, an API description with a client
  elsewhere, a shared queue or topic name, infrastructure code. Env var names alone are a guess.
  Static recovery tools miss things too; the best of 13 compared scored F1 0.86 (not verified
  beyond the research summary).

**What grasp does:** `grasp-tools projects` lists nested repositories and manifest-holding
folders, with each repository's origin so two checkouts of one repository are seen as one; each
sub-project gets its own app map; a workspace map shows what passes between them, with a "Sure?"
column. Tried read-only on a real workspace of two 3,000-file repositories: the pages were
grounded and the connection table named files on both sides. The team picks one vault at the top or docs in each repository. The
detection list (manifest names, folders skipped) is from experience, not from a fetched source.

## 7. Diagram types

Only `flowchart` (with `subgraph`) and `sequenceDiagram` are used. Both were render-tested in
this repository on 2026-11-20 ([visual-pages.md](visual-pages.md)). `C4Context`, `architecture`,
`block`, `mindmap` and `journey` are left out: Mermaid documents missing features or open layout
bugs for the first three, and the last two can't draw labelled cross-links.

Rendered in Obsidian 1.15.1 on 2026-11-21 (Live Preview): all 20 diagrams from the pages grasp
wrote for itself and for the trial workspace, plus a run record, a feature page, the table of
runs, the warning alerts and a toggle with quoted code. Everything rendered. Three things only
the real app showed:

- A `flowchart LR` with three `subgraph`s and ten labelled edges was shrunk to the page width
  until its text was unreadable. The same diagram as `flowchart TB` kept its text full size. So:
  `LR` only for a short chain, `TB` otherwise.
- An HTML comment is hidden in Reading view but shown as grey text in Live Preview. The note in
  the table of runs is now a plain sentence.
- Lines in `<pre><code>` don't wrap; anything past about 70 characters is cut off.
- Obsidian shows every newline inside a paragraph as a line break, so prose wrapped at a fixed
  width read as ragged short lines. Pages are now written one paragraph per line, and `lint-page`
  reports `hard-wrap`.

One illustration was generated for grasp's own app map (Codex CLI image generation, a synthetic
three-panel scene with no project detail in the prompt), read before it was linked, and it shows
in Obsidian.

Obsidian's changelog reports that 1.15 replaced the bundled Mermaid with its own renderer
([changelog](https://obsidian.md/changelog/2026-11-02-desktop-v1.15.0/)); these results are on
that renderer, and a broken diagram does show its `pele-error` box.

Reading view is checked by a script, `tests/obsidian-render.sh`. It copies pages into the render
vault, opens each one through Obsidian's command line, switches to Reading view, scrolls through
it and counts drawn diagrams, parse errors and broken images. A page with a broken diagram runs
first as the control. On 2026-11-21: 24 pages (grasp's own and the ones written for a real
workspace), 34 diagrams, all drawn. It opens pages in the background, so it does not take the
keyboard.

## Not found

- No study of how well an end-of-task rule or a Stop-hook reminder holds up in practice.
- No human-subjects study of how readable agent-written run summaries are.
- No comparison of feature maps against C4 for newcomers.
