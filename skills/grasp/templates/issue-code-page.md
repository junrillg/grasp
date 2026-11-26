# Issue code page template

The code behind one issue page, for the reader who wants it. The file is the issue page's name
plus `-code.md`, in the same folder. The issue page links it in one line under "How it works". It
has no word limit. Run `grasp-tools lint-page PAGE` after every write.

- `## Every changed file` is one table per layer (web, api and so on) with the columns `File` and
  `What it does in this change`. Every changed file is in one table.
- `## Code walkthrough` has one `### N. Title` per step of "How it works", in the same order. Under
  each: the output of `grasp-tools snippet` (a marker line, a code fence and a permalink), then one
  or two sentences on what the code does and why.

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
