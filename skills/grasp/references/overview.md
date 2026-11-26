# Overview: app map, architecture page, feature pages, workspace map

Detail for `map`, setup's "Overview" step and the app map patch in step 7 of
[SKILL.md](../SKILL.md). Goal: someone who has never opened this repository can say what the app
is for, name its core features, explain how one of them works and how they connect, name the
architecture and say why it is built that way, after fifteen minutes with these pages.

## The pages

| Page | Answers | Template | Written |
| ---- | ------- | -------- | ------- |
| App map, `app-map.md` | What is this app, what can it do, how do the parts connect? | [app-map.md](../templates/app-map.md) | once per app, at setup or `/grasp map` |
| Architecture page, `architecture.md` | What is the design called, why is it built this way, what breaks first, and where do I learn those ideas? | [architecture.md](../templates/architecture.md) | with the app map, once the app is not small (see "Scale with the app") |
| Feature page, `features/<feature-name>.md` | How does this one feature work today? | [feature-page.md](../templates/feature-page.md) | with the app map, for each core feature that earns one (see "Scale with the app") |
| Workspace map, `workspace-map.md` | How do these projects fit together? | [workspace-map.md](../templates/workspace-map.md) | only at the top of a workspace |

Layered on purpose: the app map stays one scannable page because the detail of each feature lives
one click away. Never grow the app map to explain a feature; write or patch its feature page.

**Scale with the app.** A page nobody needs is noise, and noise is what makes docs unread:

- **A small project gets the app map alone.** Small means under about 15 source files, counted
  per project: files of code only, not tests, manifests, lock files, styles, config or docs. No feature pages, whatever the features look like, and no
  architecture page: the caption of "The pieces" names the architecture style instead, and one of
  the map's concepts is the system design idea behind it, with its lessons in the toggle. This rule wins over the next.
- In a larger project, a feature whose whole path is one or two short files gets **no feature
  page**: its row in "Core features" and the app map's pictures already say it. Write a feature
  page only when there is a path worth tracing: three or more files or steps between where it
  starts and where it ends.
- **A small workspace gets the workspace map alone.** When all its projects together are under
  about 15 source files, add a "Core features" table to the workspace map (feature, project,
  where it starts) and a "Concepts" section, and write no app maps and no architecture page (the caption of "How they connect" names the style,
  and one concept is the system design idea behind it). The workspace map then stands
  in for the app map everywhere this skill says "the app map": it is what a run reads before
  restating an issue, what step 7 patches, what setup shows the concepts for, and the way into
  each project. `mapped at` in the Projects table still holds each project's commit. This rule
  wins over every line that says "write the app map".
- **Never draw the same arrows twice.** In a workspace, the workspace map owns the pictures that
  cross projects ("How they connect", "One journey"). A sub-project's app map then draws only its
  own inside: its "One request" stops at its own edge (the last arrow is the call that leaves
  the project, named, with no arrows drawn inside the other project), and "The pieces" is dropped
  when the project is a single piece (one process or one bundle with no store, queue or outside
  service of its own). A feature that crosses two projects is split at the edge: each
  project's page traces its own half and links the other half, and neither redraws the other's
  arrows.
- `features/README.md` (a "Core features" table and an empty `## Issues` block, as "Exploring the
  code" step 7 gives it) is created with the first feature page or issue page, not before, by whichever step writes that page first (setup step
  8, a run's step 3, `page`, `review`, or `verify` when the issue has no page yet). The same step adds the "See the Features table" line to
  the app map's "Features built" section; until then that section holds only its run records
  line, and the app map is itself the list. This small edit is allowed whatever the issue
  changed: it is not one of the patches "Keeping it current" limits.

The overview lives in the notebook only. Never paste it into `CLAUDE.md` or `AGENTS.md`: a long
generated context file loaded into every session costs tokens and has been measured to lower
agent success. The agent instruction files get the short run-record block and nothing else.

## The architecture page

It teaches two things at once: how this app is designed, and the system design ideas it uses, so
the reader can recognise them in the next app. Shape: [architecture.md](../templates/architecture.md).

- **Name the style, then show it.** "In one line" gives the architecture its usual name and what
  that means here. The code is the evidence for the shape; a name no file states is marked
  "(inferred)".
- **Its pictures are not the app map's.** The app map owns "The pieces" and "One request". This
  page draws which part may call which ("The shape") and what happens on a failure ("When
  something fails").
- **Every choice has a cost.** A row in "Why it is built this way" with nothing under "What it
  costs" is praise, not design: find the cost or drop the row.
- **Limits are read, not guessed.** "How it grows" names only a limit a file shows (one process, a
  table with no index, a ceiling in a comment). The next step is the textbook answer and is never
  a recommendation to do it now.
- **Concepts are system design ideas** (layering, idempotency, caching, queues, consistency,
  failing open or closed), at most 5, each already used in a section above. Each toggle has an
  everyday picture, where this code does it, and when not to use it.
- **Lessons are visible, not folded.** The "Lessons" table has one row per concept, easiest
  first: a free YouTube video and, with `linkedin learning: yes`, a LinkedIn Learning course, each
  checked as "Concepts on the other pages" in [notebook.md](notebook.md) says. `lint-page` reports
  `no-lessons`.
- **Design system**, only for an app with a UI: where the tokens and shared components live and
  what is enforced. This is a different thing from system design; say which one you mean.
- **In a workspace** the top folder gets one `architecture.md` for the whole system (its "app map"
  link is the workspace map). A sub-project gets its own only when it is not small and has an
  inside worth naming: more than one piece, or layers the code enforces.
- **When it is written:** with the app map, from the same traces plus the files that show
  failure handling and limits. `/grasp map` writes it when the app map is there and it is not.

## Rules for every overview page

- **Only what a file shows.** Every feature row, connection and rule names the file it was read
  from. A claim with no file behind it is dropped. A claim counts as read when you read the lines
  that show it; a search hit whose matching lines you read is enough, the whole file is not
  needed. Something guessed from a name or a convention alone is marked "(inferred)". Open
  questions go under "Not sure yet".
- **Small pictures.** About 10 boxes per diagram, never more than 20 (`lint-page` reports
  `too-many-boxes`). Past that, split by area and give each area its own picture. A picture
  nobody can take in at a glance teaches nothing.
- **Concepts, short on the page, long in the toggle.** The app map names at most 5 ideas a
  newcomer must know to follow this app, the architecture page at most 5 system design ideas, a
  feature page one or two (or a link to the app map's).
  Each is one visible line and one toggle with the longer explanation and its checked links, as
  "Concepts on the other pages" in [notebook.md](notebook.md) describes. Pick them from what the code actually does
  (the traces), never from a list of its libraries. Every one of these pages keeps the section:
  `lint-page` reports `no-concepts`.
- **Top to bottom unless it is a short chain.** Obsidian shrinks a diagram to the width of the
  page, so a wide one ends up with text too small to read. Use `flowchart LR` only for a chain of
  up to about 5 boxes in a row with no `subgraph`. Anything with a `subgraph`, or more boxes, is
  `flowchart TB`: it grows downward and keeps its text full size. Edge labels: 4 words at most.
- **Two diagram types only:** `flowchart` (with `subgraph` for areas) and `sequenceDiagram`. They
  are the ones tested in Obsidian and on GitHub. No `C4Context`, `architecture`, `block`,
  `mindmap` or `journey`: they render differently or not at all across the two.
- **The users' words.** Name a feature the way the README, the menus and the screens name it,
  never after a folder. When no menu or screen label can be found, use the route or command
  name and say so under "Not sure yet".
- **Names, not links to code.** A file name survives a move; a line link does not. When two
  files share a name, give the shortest path that tells them apart (`views/v3/job.py`). (An issue page
  is different: it is a snapshot of one change, so it links the exact lines at that commit.)
- **Stamped.** Each page says the commit it was verified at (`git rev-parse --short HEAD` when
  it was mapped) and that day's date.
- **Rules are only what the code enforces.** "Rules that must hold" lists what a check, a
  constraint, a test or a comment in the code states. An observation ("today only X writes this
  table") is not a rule; leave it out or put it under "Not sure yet" as a question.
- **Word limits count what a reader sees:** prose, captions, table cells. Not diagram source, not
  folded text. `lint-page` reports `too-long` past 1,100 words on an app map or a workspace map,
  900 on an architecture page and 350 on a feature page: fold or cut, never raise the limit.
- **Walkthroughs stay short.** At most 7 steps, each up to 8 lines of real code, never a whole
  file. A quoted line longer than about 70 characters is cut off on screen: end it with `...`
  where it is cut. Nothing else about the code is changed. A short function is quoted whole. One step may cover several arrows ("Arrows 2 to 4")
  when one function does them all.
- **Not git-ignored.** Before the first write, test the path of a page you are about to write,
  from the repository that will hold it: `git -C <that repository> check-ignore -v
  docs/how-it-works/app-map.md`, and in a workspace one path per sub-project folder
  (`docs/how-it-works/shop-web/app-map.md`). Test a file path, not the folder: a folder that does
  not exist yet prints nothing even when it would be ignored. Any output means git will silently
  skip the pages: stop, show the user the rule that matched, and fix it together (anchor the
  rule, `/shop-web/` instead of `shop-web/`, or pick another folder). `lint-page` reports the
  same thing as `git-ignored` on any page it is given. A folder that is not inside any git
  repository (a plain top folder) cannot ignore anything: skip the test there and say the pages
  are not under version control.
- **One illustration per map, when the project wants them.** Diagrams carry the structure. With
  `illustrations: yes` in `.grasp.md` and an image tool available, the app map and the workspace
  map each open with one picture of the app as an everyday scene (who uses it, what goes in, what
  comes out), and the architecture page with one of its shape as an everyday scene (the parts, and
  who may hand work to whom), as "Illustrations" in [notebook.md](notebook.md) describes: saved to
  `assets/app-map.png`, `assets/workspace-map.png` or `assets/architecture.png`, read before it is linked, regenerated once
  if its text is garbled, dropped otherwise. Never one per feature page.
- Everything in "Markdown that renders everywhere" and "Toggles" in [notebook.md](notebook.md)
  applies. Run `grasp-tools lint-page` on every page written.

## Exploring the code

Cheap and grounded: find the features from the code's own indexes, read only the files on one
path per feature. One subagent (Sonnet) per app; the main thread keeps only the page paths and
the feature list.

1. **Orient.** The README, the manifests (`package.json`, `pyproject.toml`, `go.mod`, docker and
   CI files), the entry points and the top two directory levels, plus any architecture doc that
   already exists. Never every file.
2. **List what the app can do** from its indexes, by search, not by reading:
   - routes and page files, and the navigation or menu component (web and mobile);
   - command registrations (a CLI) and public exports or an OpenAPI file (a library or API);
   - scheduled jobs, queue consumers and webhooks;
   - data model entities (schema, migrations, models), which also fill the app map's "What it
     keeps";
   - names of end-to-end and feature tests, which often read as a feature list.
3. **Group into at most 9 core features**, named in the users' words. A core feature is something
   a user or another system would miss if it vanished. Smaller ones share one "Also" row.
4. **Trace one path per core feature**: from where it starts (the route, the command, the job)
   to where it ends (the data written, the reply sent), reading only the files on that path.
5. **Find the connections** between features from what the traces share: the same table or
   entity, one feature calling another's function or endpoint, an event one sends and another
   handles. Label each edge with the thing that passes. Note on the way, for the
   architecture page: which part calls which, what happens on a failure, and any stated limit.
6. **Check before writing.** Every file named exists (`ls` it). Every edge has a file. Whatever
   is left unconfirmed moves to "Not sure yet".
7. **Write** the app map, the architecture page ("The architecture page"), then a feature page for each core feature that earns one ("Scale with
   the app"), from the traces already made. No second research pass. With the first feature page,
   create `features/README.md`: a "Core features" table (feature, page), then `## Issues` with
   an empty generated block, the two lines `<!-- grasp:issues:start -->` and
   `<!-- grasp:issues:end -->`. The list of issues there and on feature pages is generated by
   `grasp-tools sync` only: no instruction adds or edits a row by hand. The
   notebook's own `README.md` is one short paragraph on what the folder is (one line in the
   file, never wrapped by hand), then the pages in reading
   order as a numbered list. The pages link the run records: when that folder has no
   `README.md` yet (a `/grasp map` before any record), build it with `grasp-tools record-index`.
8. **Diagrams.** Validate each one with a Mermaid validator tool if one is connected and
   answers with a short verdict, or with the project's doc build; the main thread does this, since
   subagents often have no such tool. Read only the verdict: a validator that returns a rendered
   image or pages of output is not worth its tokens, so skip it. With none, `grasp-tools
   lint-page` still checks the diagram type, its quotes and its box count; say in the report
   that the diagrams were not rendered.

Ask the user one thing before writing when the code can't say it: who uses the app and what for,
if the README is silent. Show the feature list and let them fix names or drop rows; it is their
vocabulary.

## Keeping it current

- Step 7 of an issue run, and `/grasp record`, patch only what the change touched: a core feature
  row, an edge in "How the features connect", a piece, a step of the main request path, a rule,
  a glossary word. A new core feature gets its feature page; a changed one gets its picture
  patched. It has no hand-kept list of changes: its `## Issues` block is generated by `/grasp sync`
  ([upkeep.md](upkeep.md)). `map` never edits between `<!-- grasp:issues:start -->` and
  `<!-- grasp:issues:end -->`, and never between `<!-- grasp:walk:start -->` and
  `<!-- grasp:walk:end -->`. A feature page that already exists and is rewritten keeps its
  walk and the rest: see "What a rewrite keeps from the old page" in [notebook.md](notebook.md)
  "Standard 2".
- The architecture page is patched only when an issue changes a layer, a call direction, a design
  choice, a failure path or a limit; its lessons are rechecked then, never on a schedule.
- `/grasp map` refreshes in full: explore again, patch what differs, restamp (at the top of a
  workspace it does this only for sub-projects that are new or stale: "Workspaces" below). Do it when the map
  feels wrong, about monthly, and after a big refactor.
- To see what moved since a page was verified: `git diff --name-only <its sha>..HEAD`, compared
  with the files the page names.
- "Verified at" and `mapped at` name the commit the code was read at. A later commit that only
  adds grasp's own files (`.grasp.md`, the instruction file, the pages) does not make a map
  stale: a map is stale only when that diff lists a source file.

## Workspaces: a top folder with several projects

A workspace is a top folder holding several projects: separate git repositories side by side or
nested (`frontend/`, `backend/`, `infra/`), git submodules, or apps and packages in one monorepo.

**Detect.** `grasp-tools projects` (from the top folder) lists each sub-project as
`PATH<TAB>repo|package<TAB>markers`, plus a repository's origin remote when it has one: `repo`
has its own `.git`, `package` has its own manifest inside the top repository. Nothing inside a
nested repository is listed; that repository gets its own setup. It finds a repository up to
eight folders deep and a package up to three, and never looks inside `node_modules`, `vendor`,
`dist`, `build`, `target`, `venv` or hidden folders: say so to the user with the list, and ask
whether any project is missing, so one outside those limits is added by hand rather than missed.
Check the list against workspace
manifests (`workspaces` in `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `nx.json`,
`[workspace]` in `Cargo.toml`, `go.work`, `.gitmodules`) and drop what isn't a project in its
own right:

- two folders with the same origin remote are one project checked out twice: cover the main one;
- the documentation site that will hold these pages (a `docs` folder with its own manifest);
- an examples folder, a shared config package, a Dockerfile-only folder that belongs to its
  neighbour.

A sub-repository that itself holds several apps (run `grasp-tools projects` inside it to see):
ask which app its map should cover, map that one, and name the others in one "Not covered yet"
line on the app map.

**Ask**, with the list shown: which sub-projects to cover (all by default), and where their pages
go:

| Choice | Pages for a sub-project go to | Pick when |
| ------ | ----------------------------- | --------- |
| One vault at the top | `<top>/docs/how-it-works/<project>/` | The top folder is itself a repository whose `docs/` the team already opens (one Obsidian vault for everything) |
| Each repository its own | `<project>/docs/how-it-works/` | Sub-repositories are worked on and reviewed separately, and their docs should travel with their code |

A `package` always uses the top repository's notebook: `<top>/docs/how-it-works/<package>/`.

`<project>` in these paths is the sub-project's own folder name (`reporter` for
`tools/internal/reports/daily/reporter`); when two sub-projects share a name, join the path with
`-` (`tools-reporter`). Links between pages are relative paths worked out from the two real
locations, never copied from an example: a project five folders down is not one `../` away.

With one vault at the top, an agent started inside a sub-repository writes its run record
outside that repository, into the wrapper's folder. An agent sandbox that only lets writes into
the working folder will stop it or ask each time. Say so when the user picks this layout: start
agents at the top folder, or let the wrapper's docs folder be written in the agent's settings.

With one vault at the top, a wrapper that git-ignores its sub-repositories by name (`shop-web/`)
also ignores `docs/how-it-works/shop-web/`: the "Not git-ignored" check above is not optional
here.

**Write, in this order:**

0. **Check the page paths are not git-ignored** ("Not git-ignored" above), one path per
   sub-project folder, before exploring anything. A wrapper that ignores its sub-repositories by
   name fails this every time; settle it with the user first, so no exploring is wasted.
1. **Each sub-project**, in two passes. Explore: one subagent per sub-project, in parallel,
   read-only, each handing back the proposed feature list, the concepts, and what the project
   exposes and consumes (below). Confirm the lists with the user (setup step 8.2). Write: resume
   the same subagent, or start one per sub-project with its hand-back, to write that project's
   app map and feature pages and hand back the page paths. What a project exposes and consumes: endpoints served and called, packages published and
   imported, queues and topics, data stores, env values that point at a sibling.
2. **The workspace map** at the top, written by one subagent given those hand-backs (or inline
   when they are short), without re-reading code, and the top `architecture.md` with it. Draw a
   connection only when a file shows it, strongest evidence first:
   - a workspace or path dependency in a manifest;
   - `docker-compose` service links, or an env value that is a URL to a sibling service;
   - an API description (OpenAPI, proto, GraphQL schema) in one project and a client for it in
     another, or the same route on both sides: a client call in one project and the matching
     server route in the other;
   - the same queue, topic or table name on both sides;
   - infrastructure code that wires two of them together.
   An env var name alone (`API_URL`) is "inferred". Expect to miss some: say so under "Not sure
   yet" instead of drawing a guess.
3. **The Projects table.** Fill `mapped at` in the top `.grasp.md` with each sub-project's commit.

**Settings in a workspace** (written during setup steps 1 to 7, before the pages):

- The top `.grasp.md` holds what is shared: the tracker, the notebook folder, `run records:` and
  the `## Projects` table (path, kind, notebook folder, the commit mapped at). Where the top
  folder has no code of its own, Checks and App say "see each project".
- Each sub-repository gets its own complete `.grasp.md`: a run started inside it reads that one
  file and never the top one, so the shared answers (tracker, learning, illustrations, obsidian)
  are repeated in it, and only what differs is asked (its checks, app, branch and tracker
  project). It also gets its own run-record block in its own `AGENTS.md`
  ([records.md](records.md)). Run the helper for it with `--config <project>/.grasp.md`.
- With one vault at the top, a sub-repository's `.grasp.md` points there:
  `markdown folder: ../docs/how-it-works/<project>`, `run records: ../docs/how-it-works/runs`,
  `docs router: ../docs/README.md`, `docs repo: ..`. Its block then tells agents to start a
  record's short name with the project.
- The feature list is made per sub-project, each confirmed with the user.
- The top notebook's `README.md` lists the workspace map first, then the architecture page, then
  each project's app map, then the run records. A sub-project's folder needs no README of its own: its app map is the way in.
  The docs router gets two rows: the workspace map and the run records.
- Setup's own run record is one record, at the top, for the whole setup.

A top folder that is not a git repository can still hold the workspace map and a `.grasp.md`;
say plainly that those pages are not under version control, and suggest the one place they would
be (a wrapper repository, or the main sub-repository's docs).

Later, `/grasp map` at the top refreshes the workspace map and any sub-project that is new (no
"mapped at" yet) or stale since "mapped at" (a source file changed, as "Keeping it current" defines it; a commit of
grasp's own files alone is not stale); `/grasp map` inside a sub-project refreshes only that project.
