# Notebook: pages, app map, token budget

Detail for steps 3, 6, 7 and `map` in [SKILL.md](../SKILL.md). Goal: someone on the team can
read one page in under five minutes and explain what was built, how, and why, without opening
the code.

## Layout

One space per project, set in `.grasp.md`:

```
<Project>: how it works          parent page
  App map                        one page: the whole app (templates/app-map.md)
  Features                       a table: issue, what, status, pull request, page
    KEY: short name              one page per issue, before half + after half
  Decisions                      one line per decision, newest first
  Glossary                       one line per domain word
```

**Notion** (default when a Notion tool is connected): create the parent and children on first
run and save their IDs in `.grasp.md`. Edit with targeted updates (`update_content` or
equivalent); never replace a whole page. Collapsed answers use Notion's `<toggle>`. Mermaid goes
in a ```mermaid code block, which Notion renders.

**Markdown** (`--notebook markdown`, or no Notion tool): the same layout under `docs/grasp/` in
the repository: `README.md` (the parent), `app-map.md`, `features.md` (the table),
`issues/KEY-short-name.md`, `decisions.md`, `glossary.md`. Collapsed answers use
`<details><summary>`.

**Off**: write nothing; still ask the prediction and explain-back questions in chat.

One issue, one page. A later issue on the same feature patches that page and adds its link;
never a second page. Bugs get no page of their own: add one line under "Issues met" on the page
of the feature they touched, or skip when there is none.

## Page shapes

- Issue page: [templates/issue-page.md](../templates/issue-page.md). Before half 150 to 250
  words, after half 250 to 400 words.
- App map: [templates/app-map.md](../templates/app-map.md). Under about 1,000 words.

Rules for every page:

- Diagram first, words second. Mermaid by default: it costs only its text and can be patched.
  The issue's box is highlighted in the "where it fits" diagram (`style X fill:#fde68a`), and
  reuses the node names of the app map so the two pages read as one picture.
- Plain words. No component or code-level diagrams: link to the code instead.
- Every claim about what was built links to the pull request or a file; every "works" points to
  the evidence from verify.
- Mark built, not built and blocked honestly.
- No secrets, personal data or text copied from client documents.

## Illustrations

One image only when the issue brings a new domain idea that a flowchart cannot show (about one
issue in five). Generate it with whatever image tool is available (for example `codex exec` with
image generation), read the PNG before uploading, regenerate once if the text is garbled or the
idea wrong, otherwise go without. Never decorative images.

## App map

`/grasp map`, or the first run in a repository that has none. One subagent (Sonnet) reads only:
the README, the manifests (`package.json`, `pyproject.toml`, `go.mod`, docker and CI files),
the entry points and the top two directory levels, plus any existing architecture doc. It does
not read every file. It writes the page in the shape of
[templates/app-map.md](../templates/app-map.md): what the app is for, a container diagram, a
codemap (names, not links), one traced request, invariants and boundaries, and the glossary.

Keep it current cheaply: step 7 patches only the rows the issue touched (a new module, service,
data store, endpoint family or path step). Refresh in full with `/grasp map` when it feels
stale, about monthly. The app map lives in the notebook only: never paste it into `CLAUDE.md` or
`AGENTS.md`, because a long generated context file loaded into every session costs tokens and
has been measured to lower agent success.

## Token budget

- **One subagent per page write**: Sonnet for a new page or the app map, Haiku for a patch. The
  main thread keeps only the page link. For a small change whose context the main thread already
  holds (a diff of a few files), write the page inline: a subagent would cost more to brief.
- **Narrow input**: the issue note, the picked approach, `git diff --stat` and the diff of
  changed source files (not lock files, not generated files), the pull request body, the verify
  results, and the app map's diagram source. Never the repository, never a fresh research pass.
- **Patch, never regenerate**: targeted edits only. Incremental updates cost a small fraction of
  a rebuild and keep more detail.
- **Skip** the after half for a diff under about 20 changed lines that adds no behaviour; add one
  line to the Features table instead.
- **Load references per step**: read a reference file only when its step starts.
- **Fetch once to check**: after writing, fetch the page once and confirm the title, status line,
  diagram, toggles and the Features row are there.

## Explain-back

At close-out ask the first explain-back question, before the user opens the answer. Their reply
goes on the page under the question, in their words. Also log one conceptual question the user
asked during the run, if any, under "Questions asked": those are the moments learning happened.
Never block the run waiting for an answer.
