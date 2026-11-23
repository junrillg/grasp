# App overview

Verified at `d6454c6` with uncommitted changes, 2026-11-21 · part of the [app map](../app-map.md)

**In one line:** grasp reads the code and writes an app map, a page per core feature and, for several projects, a workspace map.

## Where it fits

Setup writes it once; issue runs read it first and patch it after.

```mermaid
flowchart LR
  S["Set up and update"] -->|"step 8, the first map"| B["App overview"]
  R["Run records"] -->|"record patches changed rows"| B
  B -->|"read before restating"| W["Work an issue"]
  W -->|"step 7, a patch"| B
  style B fill:#fde68a,stroke:#b45309,stroke-width:3px
```

## How it works

Find the features from the code's own indexes, trace one path each, and write only what a file shows.

```mermaid
sequenceDiagram
  autonumber
  participant D as Developer
  participant A as Coding agent
  participant G as grasp-tools
  participant C as Project code
  participant N as Notebook
  A->>G: projects, to see if this is a workspace
  A->>C: list what the app can do, trace one path per feature
  A->>D: show the feature list, wait for fixes
  A->>N: write the app map, then a page per feature, lint each
```

<details><summary>Code walkthrough: 4 steps, numbered like the diagram</summary>
<p><b>1.</b> Any output means a workspace, and each sub-project gets its own map (<code>skills/grasp/bin/grasp-tools</code>, <code>cmd_projects</code>)</p>
<pre><code># cmd_projects [DIR]: sub-projects under DIR, up to three folders d...
# .git (repo) or its own manifest (package). Nothing inside a neste...
# gets its own setup. DIR itself is never listed.</code></pre>
<p><b>2.</b> The agent searches indexes and reads only one path per feature (<code>skills/grasp/references/overview.md</code>, "Exploring the code")</p>
<pre><code>Cheap and grounded: find the features from the code's own indexes,...
path per feature. One subagent (Sonnet) per app; the main thread ke...
the feature list.</code></pre>
<p><b>3.</b> The feature names are the user's to fix (<code>skills/grasp/references/overview.md</code>, "Exploring the code")</p>
<pre><code>Ask the user one thing before writing when the code can't say it: w...
if the README is silent. Show the feature list and let them fix nam...
vocabulary.</code></pre>
<p><b>4.</b> Pages are written from the traces, listed in the router and linted (<code>skills/grasp/references/setup.md</code>, "8. Overview")</p>
<pre><code>3. Write the app map, the feature pages that earn one and, in a wor...
   Create the notebook's `README.md` (the pages in reading order: t...
   that table exists, Run records) and add the same rows to the doc...
   README and the router follow "Settings in a workspace" in overvi...
   are reached from the app map, not from the router. Run `grasp-to...</code></pre>
</details>

## Concepts

Explained on the app map: [Concepts](../app-map.md#concepts). Diagrams as text (Mermaid) and the agent instructions file apply here.

## Connects to

| Feature or piece | How | Seen in |
| ---------------- | --- | ------- |
| Set up and update | Step 8 writes the first overview; `map` refreshes it | `skills/grasp/references/setup.md` |
| Work an issue | Step 2 reads the pages; step 7 patches them | `skills/grasp/references/understand.md` |
| Run records | `record` patches the rows a task changed | `skills/grasp/references/records.md` |

## Rules that must hold

- Every row, connection and rule names the file it was read from (`skills/grasp/references/overview.md`).
- About 10 boxes per diagram, never more than 20 (`skills/grasp/references/overview.md`).
- The overview is never pasted into `AGENTS.md` or `CLAUDE.md` (`skills/grasp/references/overview.md`).

## Changes

| When | What changed | Page |
| ---- | ------------ | ---- |
| 2026-11-23 | `lint-page` now counts diagram boxes and visible words, and the app map and feature pages name their concepts | [Goal review](../runs/2026-11-23-goal-review-steps-concepts-limits.md) |
