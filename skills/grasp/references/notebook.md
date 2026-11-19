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

**Markdown** (default): the layout lives in the repository's root `docs/` folder, so the pages
travel with the code, show up in code review, and open as an Obsidian vault (`docs/` is the
vault root) as well as on GitHub and in a static doc site:

```
docs/
  README.md                      the docs router; one row per page below
  how-it-works/
    README.md                    the parent: what each page is, in reading order
    app-map.md
    decisions.md
    glossary.md
    features/
      README.md                  the Features table
      KEY-short-name.md          one page per issue
      assets/                    images for the issue pages, KEY-what.png
```

The folder is the one confirmed with the user at setup and saved in `.grasp.md`; never write
somewhere else without asking. If `docs/` already has its own layout or router, fit into it and
say where. **The router:** a project's `docs/README.md` is how people and agents find a page.
When it exists, add one row per new page (a question in the left column, the link in the
right). When it does not, create it on the first write with the pages above, after asking.

**Markdown that renders everywhere.** Obsidian, GitHub and static sites (VitePress, MkDocs)
share only plain Markdown, so the pages use only that:

- Standard relative links with the `.md` extension, `[App map](../app-map.md)`. Never
  `[[wikilinks]]`, `![[embeds]]`, block refs, `==highlight==` or `%%comments%%`.
- Diagrams as ```mermaid fences. Quote labels that hold `( ) : / [ ]`. Validate each one (a
  Mermaid validator tool if connected, otherwise the project's doc build) before saying done.
- Images in an `assets/` folder beside the page, linked `![what it shows](assets/KEY-what.png)`.
  Never hotlink an image from a tracker, Notion or a signed URL: those links expire.
- Notes as GitHub alerts (`> [!NOTE]`, `TIP`, `IMPORTANT`, `WARNING`, `CAUTION`); Obsidian shows
  them as callouts.
- Folded answers as `<details><summary>Model answer</summary>`, with a blank line after
  `</summary>` and before `</details>` so the Markdown inside renders.
- Status as a word (`Status: built`), not a colour. No front matter unless the doc site needs
  it. Lowercase file names joined with `-`.
- If the repository ships a doc site build, run it after writing: it catches broken links.

**Notion** (`--notebook notion`, needs a Notion tool): the same layout as pages. Create the
parent and children on first run and save their IDs in `.grasp.md`. Edit with targeted updates
(`update_content` or equivalent); never replace a whole page. Folded answers use Notion's
`<toggle>`. Mermaid goes in a ```mermaid code block, which Notion renders.

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
idea wrong, otherwise go without. Save it to the page's `assets/` folder (Markdown) before
linking it. Never decorative images.

## App map

`/grasp map`, or the first run in a repository that has none. One subagent (Sonnet) reads only:
the README, the manifests (`package.json`, `pyproject.toml`, `go.mod`, docker and CI files),
the entry points and the top two directory levels, plus any existing architecture doc. It does
not read every file. It writes the page in the shape of
[templates/app-map.md](../templates/app-map.md): what the app is for, a container diagram, a
codemap (names, not links), one traced request, invariants and boundaries, and the glossary.

Keep it current cheaply: step 7 patches only the rows the issue touched (a new module, service,
data store, endpoint family or path step). Refresh in full with `/grasp map` when it feels
stale, about monthly. The app map lives in the notebook (in `docs/` for Markdown) only: never paste it into `CLAUDE.md` or
`AGENTS.md`, because a long generated context file loaded into every session costs tokens and
has been measured to lower agent success.

## Token budget

- **One subagent per page write**: Sonnet for a new page or the app map, Haiku for a patch. The
  main thread keeps only the page path or link. For a small change whose context the main thread already
  holds (a diff of a few files), write the page inline: a subagent would cost more to brief.
- **Narrow input**: the issue note, the picked approach, `git diff --stat` and the diff of
  changed source files (not lock files, not generated files), the pull request body, the verify
  results, and the app map's diagram source. Never the repository, never a fresh research pass.
- **Patch, never regenerate**: targeted edits only. Incremental updates cost a small fraction of
  a rebuild and keep more detail.
- **Skip** the after half for a diff under about 20 changed lines that adds no behaviour; add one
  line to the Features table instead.
- **Load references per step**: read a reference file only when its step starts.
- **Check once**: after writing, read the page once (fetch it for Notion) and confirm the title,
  status line, diagram, folded answers, any image and the Features row are there.

## Explain-back

At close-out ask the first explain-back question, before the user opens the answer. Their reply
goes on the page under the question, in their words. Also log one conceptual question the user
asked during the run, if any, under "Questions asked": those are the moments learning happened.
Never block the run waiting for an answer.
