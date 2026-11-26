# Understanding first: what the evidence says about pages, walks and stale docs

Date: 2026-11-26 · Feeds: [the design](../superpowers/specs/2026-11-26-understanding-first-design.md)

Question: when an agent writes most of the code, what makes the person who owns the work
understand it well enough to answer for it? Collected from the web on 2026-11-26. "Opened" means
the page was read; "unverified" means it only surfaced in search results.

## The problem has names, and reading alone does not fix it

| Finding | Source |
| --- | --- |
| Cognitive debt: a team stalls when nobody can explain the design. One person must understand each change before it ships, and the why must be written down. | Opened: [Storey](https://margaretstorey.com/blog/2026/02/09/cognitive-debt/) |
| Technical debt lives in code, cognitive debt in people, intent debt in missing rationale. | Opened: [arXiv 2603.22106](https://arxiv.org/abs/2603.22106) |
| Comprehension debt: tests, specs and review do not close the gap. | Opened: [Osmani](https://oreillyradar.substack.com/p/comprehension-debt-the-hidden-cost) |
| Trial, 52 engineers: 50% on a comprehension quiz with AI, 67% by hand, debugging the largest gap. Those who asked for explanations scored 65% or more, pure delegators under 40%. Sidebar chat, not agents; immediate quiz. | Opened: [Anthropic](https://www.anthropic.com/research/AI-assistance-coding-skills) |
| 16 developers were 19% slower with AI and believed they were 20% faster. Self-judged understanding is unreliable. | Opened: [METR](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/) |
| Five months of hands-off building ended in unmaintainable code; the team went back to reading code and reviewing design first. | Opened: [HumanLayer](https://www.humanlayer.dev/blog/humanlayer-resources) |
| Fully automated explanations may suppress the understanding they describe. The author calls this unvalidated. | Opened: [Cognitive Tours](https://arxiv.org/pdf/2611.08456) |

## Habits worth copying

| Habit | Source |
| --- | --- |
| Linear walkthrough: the agent pulls every snippet with a command instead of retyping it. | Opened: [Willison](https://simonwillison.net/guides/agentic-engineering-patterns/linear-walkthroughs/) |
| Demo documents record the command and its real output, and can be re-run. | Opened: [showboat](https://github.com/simonw/showboat) |
| Fixed order of waypoints: user need, decision, code, tests, open questions. Ask "what was decided, in your words, and what else did you consider" before drafting. | Opened: [Cognitive Tours](https://arxiv.org/pdf/2611.08456) |
| Optional 10 to 15 minute exercise after significant work: predict, trace the path, debug this, teach it back. Stops offering after one decline. | Opened: [learning-opportunities](https://github.com/DrCatHicks/learning-opportunities) |
| A walkthrough per pull request: changed files, effort, merge risk, linked-issue assessment, a sequence diagram only when interactions changed. | Opened: [CodeRabbit](https://docs.coderabbit.ai/pr-reviews/walkthroughs) |
| "If you cannot explain your changes without AI, do not contribute." | Opened: [Ghostty](https://github.com/ghostty-org/ghostty/blob/main/AI_POLICY.md), [Home Assistant](https://contributors.home-assistant.io/start/ai-policy/) |
| A staleness audit flags pages that no longer match the linked files. Maintenance killed an earlier tour tool. | Opened: [Cognitive Tours](https://arxiv.org/pdf/2611.08456) |

## Page format

| Rule | Source |
| --- | --- |
| Conclusion first, and the main point first in every paragraph. | Opened: [NN/g inverted pyramid](https://www.nngroup.com/articles/inverted-pyramid/) |
| Two levels of disclosure at most; label each fold with what is inside. | Opened: [NN/g progressive disclosure](https://www.nngroup.com/articles/progressive-disclosure/) |
| A change page is explanation: why, context, alternatives. Link out to steps and reference. | Opened: [Diátaxis](https://diataxis.fr/explanation/) |
| Context and container views are enough for most teams; a dynamic view is scoped to one feature. | Opened: [C4](https://c4model.com/diagrams/dynamic) |
| Say what and why, including decisions not visible in code; list non-goals and alternatives. | Opened: [Google CL descriptions](https://google.github.io/eng-practices/review/developer/cl-descriptions.html) |
| Decision records hold context, decision, consequences including the negative ones, and the options considered. | Opened: [Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions), [MADR](https://adr.github.io/madr/) |
| Define key terms before the walkthrough; put a diagram's words beside it; no decorative content. | Opened, secondary: [Mayer's principles](https://www.devlinpeck.com/content/mayers-principles-of-multimedia-learning) |
| Guidance that helps a novice is redundant or harmful for an expert, so scaffolding must be skippable. | Opened: [expertise reversal](https://en.wikipedia.org/wiki/Expertise_reversal_effect) |
| Short-answer questions with feedback beat rereading and summarising. | Opened: [testing effect](https://en.wikipedia.org/wiki/Testing_effect) |

## What renders where

- Obsidian does not render Markdown inside an HTML element, so a `<details>` block cannot hold a
  code fence or a diagram. Opened: [Obsidian HTML](https://obsidian.md/help/html).
- `> [!note]-` folds in Obsidian and stays open in VitePress (read from the VitePress source, not
  rendered). `::: details` folds in VitePress only. The portable deep level is a linked page.
- Obsidian 1.15 (2026-11-02) is reported to render diagrams with its own engine instead of
  Mermaid. Opened by the researcher, not re-checked: [changelog](https://obsidian.md/changelog/2026-11-02-desktop-v1.15.0/).
  Any new diagram type needs a render test in both tools first.
- VitePress has no built-in Mermaid. Opened: [issue 5222](https://github.com/vuejs/vitepress/issues/5222).

## Checking lesson links

- YouTube oEmbed returns 200 with a title for a real video and 400 for a bogus one, no key needed
  (fetched).
- noembed returns 200 with an `error` field for a bogus id: check the body, not the status.
- LinkedIn Learning: a course address is public. A bogus video slug redirects to the course page
  with 200, so the final address must be compared with the requested one (tested with curl).
- Sources that answered 200 and are dependable for patterns: refactoring.guru, martinfowler.com,
  web.dev, MDN, the Azure Architecture Center patterns, the AWS Builders' Library.

## Traps

- Long generated Markdown nobody reads: "I'd rather review code than all these markdown files"
  ([Böckeler](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)).
- Wikis built from the code index record what, never why.
- A fluent summary can describe the wrong behaviour.
- Multiple-choice gates with unlimited retries pass without understanding (our reading).

## Thin evidence

- No study was found on formats for an owner or project manager reading an AI-built change. The
  owner block rests on release-note convention.
- No evidence was found that quiz gates improve understanding.
- Effect sizes for the multimedia principles were not verified; the primary paper did not load.
