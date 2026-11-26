# Issue code page template

The code behind one issue page, for the reader who wants it. The file is the issue page's name
plus `-code.md`, in the same folder. The issue page links it in one line under "How it works". It
has no word limit. Run `grasp-tools lint-page PAGE` after every write.

- `## Every changed file` is one table per layer (web, api and so on) with the columns `File` and
  `What it does in this change`. Every changed file is in one table.
- `## Code walkthrough` has one `### N. Title` per step of "How it works", in the same order. Under
  each: the output of `grasp-tools snippet` (a marker line, a code fence and a permalink), then one
  or two sentences on what the code does and why.
- **`explain` only:** `/grasp explain` adds `## Things people look up` and `## Not in git` after
  the walkthrough, and groups each layer's table by part
  ([explain.md](../references/explain.md)). Delete both sections on every other page.
- The heading of the step where the design idea shows ends with the idea's name in parentheses,
  for example `### 4. Send in chunks (Resumable upload)`.

---

# {KEY}: {short name}, code

Code for [{KEY}: {short name}]({KEY}-{slug}.md) · Standard: 2

## Every changed file

### {layer}

| File | What it does in this change |
| ---- | --------------------------- |
| `{path}` | {one line} |

## Code walkthrough

### 1. {title of step 1, as in "How it works"}

{the output of `grasp-tools snippet` for the key lines of this step}

{One or two sentences: what this code does and why.}

### 2. {title of step 2}

{snippet output}

{One or two sentences.}

## Things people look up

{Visible tables, one per kind that applies: routes, tables and columns, setting and environment variable names (never values), packages with version and why, error codes.}

| Name | What it is | Where it is used |
| ---- | ---------- | ---------------- |
| `{name}` | {one line} | {part or file} |

## Not in git

{What the change needs that no commit holds.}

| What | Where | Done |
| ---- | ----- | ---- |
| {a setting in a web console, a tool installed on a machine, a permission} | {where it lives} | {yes, no or not checked} |
