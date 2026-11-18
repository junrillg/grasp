# App map template

One page for the whole app, under about 1,000 words. Shape follows the ARCHITECTURE.md
convention: a map of the country, not an atlas of each state. Names, not links, so it does not
rot when files move. Patch the rows an issue touches; refresh in full about monthly.

---

**Last full refresh:** {date} · **Patched by:** {latest issue keys}

## What it is for

{2-3 lines: who uses it and the main thing they do}

## The pieces

```mermaid
flowchart LR
  user([{user role}]) --> fe[{frontend}]
  fe --> api[{backend / API}]
  api --> db[({data store})]
  api --> ext[{external service}]
```

{C4 container level only: apps, services, data stores, external systems. At most about 10 boxes.}

## One request, end to end

```mermaid
sequenceDiagram
  {the most important user action traced through every piece, 5-10 steps}
```

## Codemap

| Area | Where | What lives there |
| ---- | ----- | ---------------- |
| {area} | `{top-level dir or module name}` | {one line} |

## Rules that must hold (invariants and boundaries)

- {e.g. "only the exams module writes exam tables"; "the frontend never calls the database"}

## Glossary

| Word | Means |
| ---- | ----- |
| {domain word} | {plain meaning} |

## Features built

See the Features table. Each row links to its issue page.
