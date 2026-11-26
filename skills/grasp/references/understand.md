# Understand: restate, ask, choose, write it down

Detail for steps 2 and 3 of [SKILL.md](../SKILL.md). The aim: before any code, the user and the
agent agree on what is being built and why, and the user could explain the plan to a teammate.

Why: delegating the thinking is what loses understanding; asking the developer to say what they
want, and to predict what will change, keeps it. Sources: `docs/research/` in the grasp repository.

## Look before you ask

Read the app map page, the architecture page and the feature page for the feature the issue
touches (if they exist),
the code the issue touches, and the project's own docs
for that area. Keep reading until you can say how the relevant part works today and what the
change would touch. Use one or two read-only subagents for a wide search; give each the issue
text, the area, and a fixed report shape (files with line numbers, how it works today, open
questions). Never ask what the code or the issue already answers.

## First message: about 200 words

1. **Restate** the ask in your own words: what it adds or fixes, for whom, and why, as far as the
   issue says.
2. **What you found** that bears on it: how it works today, what the change touches, and anything
   that changes what gets built or how: a constraint, a conflict between sources, a cheaper path
   (code or tables that already exist).
3. **One question**, if the issue does not say why: open, in the user's words, with nothing to
   pick from. If the why is known, ask the one open point that would change the build most.
4. End with one line inviting corrections.

Ask one question per message. Ask only when the answer would change what gets built; otherwise
state your call as a proposal they can correct. Plain words, no process jargon.
A conceptual question the person asks during this step is logged on the page under "Questions
asked" in the "Why it was built this way" fold ("Standard 2" in [notebook.md](notebook.md)).

## Approaches: a message of its own

Two or three real options grounded in the code. For each: what it is in one line, what it costs,
what it trades off. Say which you recommend and why. If only one way makes sense, say so and why
the others do not fit. Wait for the pick. Record it, with the rejected options, for the page.

Skip approaches when the ask is small and fully specified, or for a bug whose fix is not a real
choice: give the root cause (file, line, a short quote) and the reproduction instead, ideally a
test that fails for the issue's reason.

Scale the ceremony to the work: a one-file fix gets three lines of plan; a new module gets the
full before page. Spec-first tools show long specs for small tasks are not read.

## The before half

Written by one subagent (Sonnet) from the restatement, the picked approach and rejected ones, and
what "What the writer reads" in [notebook.md](notebook.md) lists. Shape is in
[templates/issue-page.md](../templates/issue-page.md): at the pick, sections 1 to 4 as planned,
with Steps and Predict, a target of 300 visible words with the rest folded. Run
`grasp-tools lint-page` on it, as [notebook.md](notebook.md) says.

Two sections of the before half carry the understanding:

- **Steps**: the picked approach as 3 to 6 unticked boxes (`- [ ]`), each something a person could
  check. The build ticks them one by one ([build.md](build.md)), so the page shows progress while
  the agent works.
- **Ideas**: up to 3 ideas the change leans on, the first the design idea, each one visible line
  and one toggle that holds the longer explanation and the checked links ("Standard 2" and
  "Concepts" in [notebook.md](notebook.md)). Name them before the build: a reader who does not know the idea cannot judge the plan.

The before half is also the spec: the build works from it, and the "after" half is compared
against it in "Planned and built". If the plan changes during the build, change the step's text in
place and add "(changed: why)" to it rather than rewriting the page.

## The prediction question

After the page is written, ask the user one short question from its "Predict" section, for
example "Which files do you think will change?" or "What is most likely to break?". Their guess
goes on the page. Never wait for it: carry on with the build. Pretesting helps memory for the
material that is tested; it is cheap, but keep it to one question and let them skip it.
