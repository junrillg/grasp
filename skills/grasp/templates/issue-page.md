# Issue page template

One page per issue. Title: `KEY: short name` (for text issues, a short name). The before half is
written at step 3, the after half at step 6. Fill every `{...}`; delete a line that has nothing
true to say rather than padding it.

---

Status: {planned | building | built | verified | blocked} · [issue]({url}) · [pull request]({pr url or "not yet"})

## Before

**In one line:** {what someone will be able to do after this, in plain words}

**Why:** {the reason, in the asker's words where possible} · **Not doing:** {what this issue
deliberately leaves out}

**Where it fits**

```mermaid
flowchart LR
  A[{previous step}] --> B[{this issue}] --> C[{next step}]
  style B fill:#fde68a,stroke:#b45309
```

{reuse node names from the app map; at most about 8 boxes; name the issues before and after}

**The plan:** {picked approach in 1-2 lines} · **Rejected:** {other option} because {reason}

**Will touch:** {3 or so areas or files, one line each}

**Biggest risk:** {one line}

**Predict** (answer before the build, then compare below)

- Which parts will change? → {user's guess, or "skipped"}
- What is most likely to break? → {user's guess, or "skipped"}

## After

**Your guess vs what happened:** {one or two lines comparing the predictions with the diff}

**What was built:** {2-3 lines: what someone can do now, and the one idea behind it}

**Plan vs actual:** {"as planned", or what changed and why}

**How it works**

```mermaid
sequenceDiagram
  {the main path through the change, 4-8 steps}
```

**Where it lives** (at most 6)

- `{path}`: {what it does, one line}

**Key decision:** {decision} over {alternative} because {reason} (also a line on the Decisions page)

**Issues met**

- {what broke, what surprised, what a reviewer caught, what is not built yet}

**How to check it works:** {one command or one click path} · Verified: {checks with result
lines, control result, behaviour seen} on `{commit}`

**Questions asked:** {one conceptual question the user asked during the run, if any}

**Explain it back**

1. {a "why", "what breaks if" or "trace this request" question}
   - Your answer: {filled after they reply}

<details>
<summary>Model answer</summary>

{2-4 lines}

</details>

2. {optional second question}

<details>
<summary>Model answer</summary>

{2-4 lines}

</details>

---

Keep the blank lines inside `<details>`: without them Obsidian and GitHub show the answer's
Markdown as raw text. In a Notion notebook use a toggle block instead.
