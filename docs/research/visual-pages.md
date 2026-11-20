# Visual-first issue pages: what the evidence and the tools say

## Render test results

Decision: TOGGLE_FORM=html

Tested 2026-11-20 with [`tests/render/obsidian-check.md`](../../tests/render/obsidian-check.md). GitHub was checked
through `gh api markdown` (GitHub's own renderer). Obsidian was checked by the owner in the app, with
`tests/render` opened as a temporary vault, in both Reading view and Live Preview.

| Construct | GitHub | Obsidian reading | Obsidian live preview |
| --------- | ------ | ---------------- | --------------------- |
| (a) `<details>` as one block, no blank lines, HTML-only content incl. `<pre>` | folds | folds | folds |
| (b) `<details>` with blank lines and Markdown inside (forbidden) | folds | not checked; Obsidian's help says it breaks | not checked |
| (c) `> [!info]-` foldable callout with Mermaid and code | open quote with a literal `[!info]-` | folds, diagram renders | folds, diagram renders |
| (d) Mermaid flowchart with a `style` highlight | `mermaid` block emitted (rendered client-side) | renders | renders |
| (e) Mermaid `sequenceDiagram` with `autonumber` | `mermaid` block emitted | renders | renders |
| (f) The five alerts | styled alerts | styled callouts | styled callouts |
| (g) `\| Before \| After \|` table with a relative `assets/` image | image shows | image shows | image shows |
| (h) `diff` fence | coloured | coloured | coloured |
| (i) Relative `.md` link | works | fails only because the target sat outside the temporary vault | same |

What this decides:

- Toggles use the single-block HTML form from (a). It folds everywhere the pages are read, so the
  Obsidian-wins fallback (foldable callouts) isn't needed.
- (c) folds only in Obsidian and shows open on GitHub, so `lint-page` keeps flagging `> [!x]-`.
- (b) stays forbidden: it relies on Markdown inside HTML, which Obsidian documents as unsupported.
- Diagrams, alerts, screenshot tables and diff fences stay outside toggles and render in both.

Researched 2026-11-20. This builds on `docs/research/learning-pages.md`, which already covers the case for one page per issue, explain-back, Mermaid by default, CodeRabbit's walkthrough table and Mayer's multimedia effect. This report adds only what's new. **[verified]** means I tested it myself. **[unverified]** means I couldn't confirm it.

## The finding that changes the template right now

GitHub renders the template's folded model answer (`<details>`, a blank line after `</summary>`, Markdown inside) correctly. I confirmed that through GitHub's own Markdown renderer [verified]. **Obsidian doesn't.** Its help page says "Obsidian does not render Markdown syntax inside HTML elements" and "Blank lines will break the HTML block" ([Obsidian Help](https://obsidian.md/help/Editing+and+formatting/HTML+content)). Obsidian staff say the same on its forum ([forum 10468](https://forum.obsidian.md/t/details-summary-collapsible-headings-summary-under-click-to-reveal-text-details-on-multiple-lines/10468), [forum 40569](https://forum.obsidian.md/t/markdown-inside-raw-html-not-rendered-correctly/40569), [feature request 23764](https://forum.obsidian.md/t/parse-markdown-inside-details-summary-tags/23764)). So in Obsidian the "hidden" model answer most likely shows up as ordinary visible text under an empty toggle, which gives the explain-back answer away. The render test below confirms the single-block HTML form folds in Obsidian. The note at the bottom of `templates/issue-page.md` says the opposite, so it's wrong for Obsidian.

The portable alternatives are below. Each has a cost.

- Obsidian's foldable callout `> [!NOTE]-` is **not portable**. GitHub renders it as a plain blockquote that starts with the literal text `[!NOTE]-` [verified]. GitHub alerts can't fold and can't take custom titles.
- `<details>` written with **no blank lines and HTML-only content** (`<code>`, `<br>`, `<a>`) folds on GitHub and, per the forum, also in Obsidian. The cost is no Markdown, no Mermaid and no code fences inside the fold.
- Accept that Obsidian degrades to "expanded" for long prose folds, where showing the text does no harm. Use the HTML-only single-block form only where hiding matters: the explain-back answers.

## 1. How AI change explainers lay out a change

- **CodeRabbit** posts a walkthrough on every PR. The sections, in order: changed-files summary, sequence diagrams, estimated review effort, merge risk, related issues, linked-issue assessment and related PRs. The summary sits above the file table. **The whole walkthrough is wrapped in a collapsed `<details>` by default.** Sequence diagrams and the file table are on by default ([CodeRabbit walkthroughs](https://docs.coderabbit.ai/pr-reviews/walkthroughs), [config reference](https://docs.coderabbit.ai/reference/configuration)). The pattern is a one-line verdict visible, the bulk folded, and the diagram inside.
- **Greptile** picks the diagram *type* from the kind of change. It uses a sequence diagram for API and multi-service flows, an ER diagram for schema changes, a class diagram for class hierarchies, a flowchart for business logic, and **no diagram for trivial changes** ([Greptile, Anatomy of a Review](https://www.greptile.com/docs/code-review/first-pr-review)). grasp can take this mapping directly.
- **GitHub Copilot PR summaries** write a prose overview plus bullets with the files touched. They come from the diff only and **don't update when the PR changes** ([GitHub Docs](https://docs.github.com/en/copilot/github-copilot-enterprise/copilot-pull-request-summaries), [responsible use](https://docs.github.com/en/copilot/responsible-use/pull-request-summaries)). That staleness is the gap grasp's patch-on-review rule already covers.
- **Swimm** couples docs to code snippets and checks them in CI ("Auto-sync"). Its "playlists" are ordered sequences of docs, videos, images and links stored as Markdown in the repo ([Swimm blog](https://swimm.io/blog/get-started-with-swimm-most-frequently-asked), [Swimm](https://swimm.io/blog/sync-dont-sink-why-we-built-swimm-for-dev-teams); vendor sources, 2022-2023). A "learn more" list in a fixed order fits the external-learning section.
- **VS Code CodeTour** stores a tour as JSON steps of `file` + `line` + Markdown `description` ([microsoft/codetour](https://github.com/microsoft/codetour)). That's the shape of a numbered code walkthrough. A static page can do the same with a numbered list in which each item has a permalink and a short excerpt.
- **Before/after screenshots:** the common convention is a `| Before | After |` table under a "Screenshots" heading, one row per screen or state. Changes with nothing visual write "No visible change". Long galleries go in `<details>` ([humanmade PR](https://github.com/humanmade/hm-facet-blocks/pull/4), [beutl PR](https://github.com/b-editor/beutl/pull/3791), [losos PR](https://github.com/dasmatus/losos/pull/69)). These are community conventions, not a GitHub standard.
- **Engagement data:** I found no published click or read data for walkthroughs, folded sections or diagrams in any of these tools [gap]. The only outcome data is still Copilot-for-PRs' 19.3 fewer review hours, which is already cited in learning-pages.md.

## 2. Progressive disclosure: what gets missed

- NN/g says accordions "diminish content visibility" and that "valuable content hidden under an accordion may be missed altogether", especially when the heading isn't descriptive. They suit independent sections the reader rarely needs, and hurt when readers need most of the content or **critical information is hidden** ([NN/g Accordions on Desktop](https://www.nngroup.com/articles/accordions-on-desktop/)). Nielsen's older rule is to show what's frequently needed up front and avoid more than two levels of disclosure ([NN/g Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/), seen only via secondary quotes). Desktop users opened hidden navigation 27% of the time against 48% for visible navigation ([NN/g hamburger study](https://www.nngroup.com/articles/hamburger-menus/), seen via secondary sources) [unverified on nngroup.com]. That's the closest number to "how often collapsed content is opened".
- People scan in an F-pattern, and the **layer-cake pattern** (reading descriptive headings, skipping body text) is "by far the most effective" way to scan ([NN/g F-pattern 2017](https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content/), [Text Scanning Patterns](https://www.nngroup.com/articles/text-scanning-patterns-eyetracking/)). The inverted pyramid puts the conclusion first ([NN/g](https://www.nngroup.com/articles/inverted-pyramid/)).
- Diátaxis keeps explanation (why), how-to and reference apart ([diataxis.fr](https://diataxis.fr/start-here/)). On an issue page, the visible layer is the explanation. Reference material (file lists, full diffs) is what goes in folds.
- **What this means for the design:** fold *supporting* prose, never the verdict, a blocker or a risk. Every `<summary>` should state its conclusion ("Why we chose a queue over a cron job"), not a label like "Details". Use one level of folding only.

## 3. Code walkthroughs in static Markdown

- GitHub expands a line permalink into an embedded snippet **only in issue and PR comments, never in Markdown files**, and only in the same repository ([GitHub Docs](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-a-permanent-link-to-a-code-snippet)). So the page has to carry a short excerpt itself, plus a permalink pinned to a full commit SHA with `#L10-L24`.
- A ```` ```diff ```` fence is highlighted on GitHub [verified] and by Shiki in VitePress. Obsidian's highlighting of it is [unverified].
- A workable pattern is a numbered walkthrough of 3-5 steps. Each step has a one-line "what happens here", a 5-15 line excerpt (a `diff` fence for changes), and a permalink. Mermaid sequence step numbers can match the walkthrough numbers (`autonumber`) to create the signalling link between picture and code.

## 4. Screenshots

- Playwright's `toHaveScreenshot()` stores baselines in the repo and writes a diff PNG on mismatch ([Playwright docs](https://playwright.dev/docs/test-snapshots)). Percy and Chromatic diff in a hosted dashboard and post a PR status check, not images in the page ([comparison, secondary](https://bug0.com/knowledge-base/visual-regression-testing-tools)).
- For grasp, the cheapest path is a plain Playwright `page.screenshot()` of the affected route at a fixed viewport, run before the build (on the base branch) and after. The two images go in `assets/KEY-before.png` and `KEY-after.png`, and are named after the view, theme and width the way the orbit convention does ([orbit PR](https://github.com/constellation-works/orbit/pull/6170)).
- **Staleness:** caption each image with the commit SHA and date it was taken. Treat it as a snapshot of that change, never as current UI. I found no tool that automatically refreshes doc screenshots in plain Markdown [gap].
- Annotation: I found no standard. Use an arrow or box drawn in the screenshot step, or a numbered caption list under the image [unverified as a convention].

## 5. External learning links

**YouTube** [verified 2026-11-20]: `GET https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=<ID>&format=json` needs no key. It returned 200 with `title` and `author_name` for a real video and 400 for an invented ID. Secondary sources report 401/403 for private or embed-disabled videos and 404 for removed ones ([youtube-video-exists](https://github.com/matthiasschwarz/youtube-video-exists), [JesusFilm issue](https://github.com/JesusFilm/core/issues/10273)). oEmbed can't tell unlisted from public and gives no duration or upload date. Getting those needs the Data API, which needs a key.

**LinkedIn Learning** [verified 2026-11-20]: course pages at `linkedin.com/learning/<slug>-<id>` load without a login. They show the outline and preview, but the full videos need a subscription ([summary of public catalogue](https://apify.com/johnvc/linkedin-learning-api/examples/linkedin-learning-courses-no-login), secondary). A real course URL returned 200 **after redirecting to a newer course version with a different ID**. An invented one returned 404. The official API needs an organisation's site licence or partner status, plus admin access to create keys in Learning Admin Settings ([Microsoft Learn: request access](https://learn.microsoft.com/en-us/linkedin/learning/getting-started/request-access)). That isn't something grasp can assume. LinkedIn is known to answer automated clients with non-standard codes such as 999 [unverified for /learning].

**The rule to adopt:**

1. Use at most 3 links, and only for concepts the change actually relies on (named in the plan or the diff). Order: official docs first, then one free video, then one LinkedIn Learning course, the last only when the team's `.grasp.md` says it has access.
2. A link is kept only if a live check passes **at write time**. For YouTube, oEmbed must return 200, and the returned `title` must name the concept. Write the returned title and channel into the page and never invent them. For LinkedIn Learning, an HTTP GET with redirects must end at 200 on a `/learning/` URL. Save the **final** URL, not the requested one. For docs, a 200 response whose page title names the concept.
3. Any other code (400, 401, 403, 404, 429, 999) or a timeout means **drop the link**. Never "fix" it with a guessed URL.
4. Label paywalls inline ("LinkedIn Learning, subscription"), and add "checked YYYY-MM-DD" after each link.
5. Re-check links only when a page is patched. Don't run a scheduled crawl.
6. Search queries must contain only the concept name. Never put the project, client or issue text in them.

## 6. Mayer's principles that change the layout

These are Mayer's own medians from his lab. Independent meta-analyses find about half that size: coherence d = 0.86, signalling 0.70, spatial contiguity 0.82, segmenting 0.67 ([Mayer 2021 via UNH](https://www.unh.edu/teaching-learning-resource-hub/sites/default/files/media/2023-06/itow-research-based-principles-for-designing-multimedia-instruction-mayer.pdf), [Mayer and Fiorella 2014](https://www.cambridge.org/core/books/abs/cambridge-handbook-of-multimedia-learning/principles-for-reducing-extraneous-processing-in-multimedia-learning-coherence-signaling-redundancy-spatial-contiguity-and-temporal-contiguity-principles/CD5B7AE1279A9AB81F8EEBB53DBEC86E)). What each one changes:

- **Coherence:** no decorative images or stock illustrations. Leave out a section rather than pad it. Irrelevant extras hurt learning, d of about -0.33 (secondary, [ResearchGate chapter](https://www.researchgate.net/publication/262915119_Principles_for_reducing_extraneous_processing_in_multimedia_learning_Coherence_signaling_redundancy_spatial_contiguity_and_temporal_contiguity_principles)).
- **Signalling:** highlight the issue's node in each diagram (already in the template), use numbered steps shared between the diagram and the walkthrough, and write headings that state conclusions.
- **Spatial contiguity:** put the one-line caption directly above each diagram or screenshot, not in a later paragraph. Labels go in the diagram nodes, not in a legend.
- **Segmenting:** use short sections the reader moves through at their own pace. Folds and numbered walkthrough steps do this.

## Recommended page layout

**Visible (one screen, about 150 words of text plus visuals):**

1. Status line: status word, issue link, PR link.
2. **In one line** (the verdict) and, when blocked, a `> [!WARNING]` alert with the blocker. A blocker is never folded.
3. **Where it fits:** a Mermaid flowchart with the issue's node highlighted.
4. **Before / After:** a screenshot table for UI changes. For non-UI changes, a "before/after behaviour" pair of one line each.
5. **How it works:** one Mermaid diagram, its type picked the Greptile way, with `autonumber`.
6. **Code walkthrough:** 3-5 numbered steps matching the diagram numbers. Each has a short excerpt and a SHA permalink.
7. **Decision** in one line, and **risk or issues met** in one line each.
8. **Explain it back:** the question visible, the model answer in an HTML-only single-block `<details>`.

**Folded (each `<details>` with a summary that states its conclusion):**

9. Why, and what's left out (prose).
10. Plan vs actual, and the rejected approach with its reasoning.
11. Files touched (the full table).
12. Verification evidence (commands and output lines).
13. **Learn the concepts:** up to 3 verified links with title, channel or provider, paywall label and check date. This also works visible as a short list. It's folded only when the page runs long.

Predictions in the before half stay visible while the issue is `planned` or `building`, and fold once `built`.

## Rendering compatibility

| Construct | GitHub | Obsidian (core, no plugins) | VitePress (default) |
|---|---|---|---|
| ```` ```mermaid ```` | Yes ([docs](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams)) | Yes, built in. A newer "allow Mermaid" banner is [unverified] | **No**, needs `vitepress-plugin-mermaid` ([plugin](https://github.com/emersonbottero/vitepress-plugin-mermaid)) |
| GitHub alerts `> [!NOTE]` (5 types) | Yes, top level only, not inside lists or HTML | Yes, as callouts | Yes, built in ([VitePress](https://vitepress.dev/guide/markdown)) |
| Foldable callout `> [!NOTE]-` / custom title | **No**, shows literal text [verified] | Yes | Title yes, fold [unverified] |
| `<details>` + blank lines + Markdown inside | Yes [verified] | **No**, content shows unfolded (per docs) | Yes (CommonMark HTML block) [untested] |
| `<details>` single block, HTML-only content | Yes | Yes (per forum) [untested] | Yes [untested] |
| `::: details` container | No, shows as text | No | Yes |
| ```` ```diff ```` highlighting | Yes [verified] | [unverified] | Yes (Shiki) |
| Relative image `![](assets/x.png)` | Yes | Yes | Yes |
| Line permalink expanding to a snippet | Comments only, not .md files | No | No |
| YouTube embed `![](youtube url)` | No (broken image) | Yes | No |
| `[[wikilinks]]`, `==highlight==` | No | Yes | No |

## Open gaps

- No engagement data on folded walkthroughs, diagrams or screenshots in PR tools. No study of developers opening `<details>`.
- Obsidian behaviour (the `<details>` forms, `diff` highlighting, Mermaid banner) comes from docs and forum posts. Render a test page in the Obsidian app before changing the template.
- How VitePress handles the foldable-callout marker, and raw `<details>`, was not tested in a build.
- LinkedIn Learning's response codes to automated clients at volume (999 or rate limits) are unknown. So is whether redirected "newer version" courses still cover the same content.
- No standard for screenshot annotation, and no tool that refreshes doc screenshots in plain Markdown.
- Loom-style recorded walkthroughs: I found no 2024-2026 data. Google, Meta and Stripe launch-review formats were not researched beyond learning-pages.md.
- Graphite and Ellipsis: I found no documentation of diagrams in their summaries.
