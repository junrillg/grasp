# Issue page template

One page per issue, one layout for both halves. Title: `KEY: short name` (for a text issue, a
short name). Step 3 writes the before half: the sections marked (before). Step 6 writes the
after half: it patches the same sections and adds the ones marked (after). Rules for every
part are in [notebook.md](../references/notebook.md). Fill every `{...}`. Delete a section that
has nothing true to say instead of padding it.

**Visible:** pictures, one-line captions, the status line, the steps, one line per concept,
blockers, the explain-back question.
**Folded:** everything else, in a toggle directly under the picture it explains. A toggle is a
single HTML block: no blank lines inside, HTML only (`p`, `ul`, `ol`, `li`, `a`, `code`, `pre`,
`b`, `br`). Each toggle title states a conclusion, never "Details". Run
`grasp-tools lint-page PAGE` after every write.

---

# {KEY}: {short name}

Status: {planned | building | built | verified | blocked} · [issue]({issue url}; for a text issue write "text issue" with no link) · [pull request]({pr url, or "not yet"})

> [!WARNING]
> {Blocked: what blocks it and who can unblock it, in one line. Only while blocked; never folded.}

**In one line:** {what someone can do now (after) or will be able to do (before), in plain words}

## Steps

{Caption: the plan in 3 to 6 steps. Each box is ticked the moment the build finishes that step, so this list is the live progress.} (before, ticked during the build)

- [ ] {step 1, something a person could check, e.g. "A test that fails for the expired token"}
- [ ] {step 2}
- [ ] {step 3}

## Where it fits

{Caption: where this issue sits in the app, one line.} (before)

```mermaid
flowchart LR
  A["{previous step}"] --> B["{this issue}"] --> C["{next step}"]
  style B fill:#fde68a,stroke:#b45309,stroke-width:3px
```

<details><summary>{Why this matters, as a conclusion, e.g. "Users lose their work after an hour, so we refresh early"}</summary>
<p>{the reason, in the asker's words where possible}</p>
<p><b>Not doing:</b> {what this issue deliberately leaves out}</p>
</details>

## Concepts

{Caption: the ideas this change leans on, one line. Up to 3. With none: "Nothing new: {the one idea already on the app map}". A change to a piece, to who calls whom, or between designs names the system design idea behind it.} (before; links checked again after)

- **{Concept name}:** {what it is in one plain sentence, and where this change uses it}

<details><summary>{Concept name}: {its point as a conclusion, e.g. "A queue lets the request return before the work is done"}</summary>
<p>{the longer explanation, 3 to 8 lines, plain words, tied to this code and not a textbook definition}</p>
<ul><li><a href="{official docs url}">{page title}</a>, official docs, free</li><li><a href="{video url}">{title from check-link}</a>, {channel from check-link}, YouTube, free</li><li><a href="{final url from check-link}">{course title from check-link}</a>, LinkedIn Learning, paid</li></ul>
<p>Links checked {YYYY-MM-DD}.</p>
</details>

## Before and after

{Caption: what changed on screen, one line, or "No visible change" and drop the table. A change that shows only in another project: drop the table and the "After, at" line, and make the caption "{what will show} in {project}. Not captured."} (after; the table is for UI changes only, the "Check it yourself" toggle below stays for every change: it holds the evidence)

| Before | After |
| ------ | ----- |
| {![before](assets/{KEY}-before.png) from an issue attachment, or "Not captured"} | ![after](assets/{KEY}-after.png) |

After, at `{short sha}`, {YYYY-MM-DD}.

<details><summary>Check it yourself in {n} steps</summary>
<ol><li>{one command or one click}</li><li>{what you should see}</li></ol>
<p><b>Verified:</b> {checks run with their result lines, the control result, behaviour seen} on <code>{commit}</code></p>
</details>

## How it works

{Caption: the one idea behind the change, one line. Before: "Expected flow".} (before, replaced after)

```mermaid
sequenceDiagram
  autonumber
  participant U as {actor}
  participant S as {service}
  U->>S: {step 1}
  S-->>U: {step 2}
```

<details><summary>Code walkthrough: {n} steps, numbered like the diagram</summary>
<p><b>1.</b> {what this step does} (<a href="{commit-SHA permalink to the lines}">{path}#L{a}-L{b}</a>)</p>
<pre><code>{3 to 8 lines of the real code, no highlighting}</code></pre>
<p><b>2.</b> {next step} (<a href="{permalink}">{path}#L{a}-L{b}</a>)</p>
<pre><code>{excerpt}</code></pre>
</details>
<details><summary>{n} files touched, {m} of them tests</summary>
<ul><li><code>{path}</code>: {what it does, one line}</li></ul>
</details>

## Decision

{Caption: the decision in one line, "{picked} over {rejected}".} (before)

```mermaid
flowchart LR
  Q{"{the question}"} -->|picked| P["{picked approach}"]
  Q -.->|rejected| R["{rejected approach}"]
  style P fill:#bbf7d0,stroke:#15803d
  style R fill:#e5e7eb,stroke:#6b7280,stroke-dasharray: 4 4
```

<details><summary>Why {picked} wins, and what it costs</summary>
<p>{the reason}. <b>Costs:</b> {the trade-off}. <b>Biggest risk:</b> {one line}.</p>
</details>

## Planned and built

{Caption: "{n} of {m} steps built as planned", then the one thing that changed, if any.} (after)

| Planned | Built instead | Why |
| ------- | ------------- | --- |
| {a step that changed, or was not done} | {what was built, or "not done"} | {one line} |

{One row per step that changed or was not done, never the steps built as planned: their ticks say it. Everything as planned: keep the caption, drop the table.}

## Blocker

> [!WARNING]
> {A blocker met during the build, and how it was resolved or worked around. One alert per blocker. Never folded.} (after)

## Predict

{Visible while planned or building. Once built, move it into the "Your guess" toggle below.} (before)

- {The one question that was asked, e.g. "Which parts will change?" or "What is most likely to break?"} → {user's guess, or "skipped"}

<details><summary>Your guess vs what happened: {one-line verdict}</summary>
<p>{the predictions, then one or two lines comparing them with the diff} (after)</p>
</details>

## Explain it back

1. {a "why", "what breaks if" or "trace this request" question} (after)
   - Your answer: {their words; `skipped`; or `not asked (no person in the run)`}

<details><summary>Model answer</summary>
<p>{2 to 4 lines}</p>
</details>

**Questions asked:** {one conceptual question the user asked during the run, if any}
