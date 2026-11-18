# Packaging and workflow notes for a portable, cheap-in-tokens skill

Researched 2026-11-18. Claims marked (3rd-party) come from secondary sources, not vendor docs.

## 1. Claude Code plugin + marketplace (one repo, one skill)

- A marketplace is a repo with `.claude-plugin/marketplace.json`. Required top-level: `name`, `owner{name}`, `plugins[]`. Entry requires `name` + `source`. Source `"./"` (or `"."`) means the marketplace root, so one repo can be marketplace and plugin. Names: letters/digits/`.`/`_`/`-`; avoid `claude-`/`anthropic-` prefixes (reserved). Source: https://code.claude.com/docs/en/plugins/marketplace-reference.md
- `plugin.json` lives at `.claude-plugin/plugin.json`; only `name` is required (kebab-case). `version`, `description`, `author{name}`, `homepage`, `repository`, `license`, `keywords` are optional. Default skill location is `skills/<name>/SKILL.md` at the plugin root, never inside `.claude-plugin/`. Skills are invoked as `/plugin-name:skill-name`. Source: https://code.claude.com/docs/en/plugins-reference
- Keep entry name = manifest name. Set `version` in plugin.json only (not both). With `version` set, users get updates only when it changes; omit it to track commits. Source: https://code.claude.com/docs/en/plugins/host-marketplace.md
- Validate: `claude plugin validate .`
- Private GitHub repo: Claude Code runs plain `git` non-interactively using the user's existing credentials. No token field exists. `owner/repo` tries SSH first (`ssh -T git@github.com`), then HTTPS. HTTPS needs a credential already stored in a git credential helper (GitHub CLI login plus its git setup step does this). Background auto-update is off by default; `GITHUB_TOKEN` alone does not authenticate it, only via a credential helper. `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` skips the SSH probe. Source: host-marketplace.md, "Grant access to a private marketplace".
- Plain alternative (no plugin): copy or symlink `skills/<name>` to `~/.claude/skills/<name>` (personal) or `.claude/skills/<name>` (project). Source: https://code.claude.com/docs/en/skills
- Claude Code extras beyond the open standard (keep out of the portable core; they hard-fail when packaged for claude.ai/API): `disable-model-invocation`, `context: fork`, `agent`, `model`, `argument-hint`, `when_to_use`, `paths`.

## 2. Agent Skills open standard

Source: https://agentskills.io/specification
- Required: `name` (1-64 chars, lowercase a-z 0-9 and hyphens, no leading/trailing/double hyphen, must equal the folder name), `description` (1-1024 chars, what + when).
- Optional: `license`, `compatibility` (<=500), `metadata` (string map), `allowed-tools` (space-separated, experimental).
- Layout: `SKILL.md`, optional `scripts/`, `references/`, `assets/`. Metadata ~100 tokens at startup, body < 5000 tokens recommended, SKILL.md < 500 lines, references one level deep. Validate with `skills-ref validate ./skill`.
- Anthropic additionally bans `anthropic`/`claude` in `name` and XML tags in name/description.

Where each tool looks:

| Tool | Paths | Source |
|---|---|---|
| Claude Code | `~/.claude/skills`, `.claude/skills`, plugin `skills/` | code.claude.com/docs/en/skills |
| Codex CLI | `.agents/skills` (cwd up to repo root), `~/.agents/skills`, `/etc/codex/skills`; follows symlinks; `~/.codex/skills` legacy (3rd-party); optional `agents/openai.yaml` | https://learn.chatgpt.com/docs/build-skills |
| Cursor | `.agents/skills`, `.cursor/skills`, `~/.agents/skills`, `~/.cursor/skills`, plus compat reads of `.claude/skills`, `~/.claude/skills`, `.codex/skills` | https://cursor.com/docs/context/skills |
| Gemini CLI | `~/.gemini/skills` or `~/.agents/skills`; `.gemini/skills` or `.agents/skills`; `gemini skills install <git-url>` | https://geminicli.com/docs/cli/skills/ |

Conclusion: `.agents/skills` is the common denominator (Codex, Cursor, Gemini); Claude Code needs `.claude/skills` or the plugin (Cursor also reads `.claude/skills`). Ship one `skills/<name>/` folder and symlink it into both.

## 3. Superpowers design (local v7.0.2, `~/.claude/plugins/cache/claude-plugins-official/superpowers/7.0.2`)

- **Hard gate** (brainstorming): "Nothing gets built until your human partner approves the design doc... Building includes writing product code, scaffolding, installing dependencies... Reading and exploring are fine." Next step: "invoke superpowers:writing-plans and no other skill."
- **Order**: lay out approaches and have the human pick one; write the design doc; get approval; invoke writing-plans.
- **One question at a time**: "Ask one at a time." Ask only when "the answer would change what gets built and neither the request nor the project answers it." Get them describing first (open questions), then offer named choices.
- **2-3 approaches**: "Sketch the two or three that remain concretely... with what each trades off. Recommend one and say why."
- **Look before you ask**: read context first; "Never ask what the project or their context already answers."
- **Size the work**: small change gets a short design doc; project gets the full doc plus a fresh-subagent "builder check".
- **Verification** (iron law): "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE". Gate: identify command, run full, read output, verify, only then claim. "Agent reports success" is not evidence: check the VCS diff.
- **TDD** (iron law): "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"; code before the test is deleted.
- **Plans**: bite-sized steps, no placeholders ("TBD", "handle edge cases" banned), self-review, header names the next skill (subagent-driven-development or executing-plans) and the spec path.
- **Subagent models**: "Use the least powerful model that can handle each role"; mechanical tasks get a cheap model; "Always specify the model explicitly when dispatching a subagent" (an omitted model inherits the expensive session model).
- **Keeping it short**: process skills run 65-340 lines (using-superpowers 65, verification 120, writing-plans 204, brainstorming 316). Side material moves out (brainstorming ships `visual-companion.md`, `builder-check-prompt.md`, `scripts/`). Rationalization tables ("Thought | Reality") enforce gates in few lines.
- **Chaining**: each skill names the next one: brainstorming -> writing-plans -> subagent-driven-development -> requesting-code-review -> verification-before-completion -> finishing-a-development-branch. `using-superpowers` carries `<SUBAGENT-STOP>` so dispatched subagents skip the meta-skill.
- Its plugin manifest is minimal: name, description, version, author, homepage, repository, license, keywords.

## 4. Tracker-agnostic intake

Adapter pattern: SKILL.md states the contract; each tracker is a short reference file mapping the contract to a tool. The agent picks the adapter by input shape (URL host or key regex).
- Jira: Atlassian remote MCP, `claude mcp add --transport http atlassian https://mcp.atlassian.com/v2/mcp`; the `/v1/sse` endpoint is unsupported after 2026-06-30 (3rd-party, repo atlassian/atlassian-mcp-server). Tools: `getJiraIssue`, `searchJiraIssuesUsingJql`, `addCommentToJiraIssue`, `transitionJiraIssue`. Cloud only.
- Linear: `https://mcp.linear.app/mcp` (also `/mcp/readonly`); tools `get_issue`, `list_comments`, `save_comment` (3rd-party list).
- GitHub: `gh issue view N --json title,body,comments,labels`, or GitHub MCP `issue_read` (methods get, get_comments, get_labels).
- Plain text: the pasted text is the body.

Minimal contract (normalise to this, then forget the tracker):

```
fetch(ref) -> { id, url, title, body, comments[{author,text}], attachments[{name,url}], acceptance[] }
comment(ref, text)   # optional; only after the user approves the exact text
```

`acceptance[]` is extracted from the body (checklist, Given/When/Then, "Acceptance criteria" heading); if empty, ask one question to derive it. Fetch attachments only when the body references them. If the MCP or CLI is missing, ask the user to paste the card; never guess.

## 5. Token-efficiency rules

Sources: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices, https://code.claude.com/docs/en/skills
- Descriptions sit in context every turn: one trigger sentence (listing truncates at 1,536 chars including `when_to_use`). Bodies load on invocation, then persist; after compaction only the first 5,000 tokens per skill are re-attached (25,000 combined).
- SKILL.md < 500 lines; split to `references/` one level deep, with a contents list if a reference exceeds 100 lines. Load a reference only when its branch is taken.
- "Default assumption: Claude is already very smart." Cut what it knows. One default path plus one escape hatch; no option menus.
- Scripts run without entering context (only output counts): use them for deterministic steps and validators; make validators verbose.
- Descriptions in third person, what + when. Test on Haiku, Sonnet and Opus; Haiku needs more explicit steps.
- Delegate heavy reads to subagents with an explicit cheap model; return summaries, not file dumps. Do not re-read what is in context; keep one status file and point to it.
- Write 3 evaluations first; write the minimum text that fixes observed gaps.

## Recommended repo layout

```
<repo>/
  .claude-plugin/
    plugin.json          # name, description, author, license, repository (no version: track commits)
    marketplace.json     # name, owner, plugins:[{name, source:"./", description}]
  skills/<skill-name>/
    SKILL.md             # <200 lines: hard gates, steps, links
    references/
      intake.md          # contract + adapter table
      jira.md  github.md  linear.md  plain.md
      templates.md       # output shapes
    scripts/             # validators, deterministic helpers
  README.md              # install section below
  LICENSE
```

Frontmatter `name` equals `<skill-name>`; marketplace entry name equals plugin.json `name`. Use only the six standard frontmatter fields in the core file.

## Install section text (for README)

> ### Install
> **Claude Code (plugin).** In a session: `/plugin marketplace add OWNER/REPO`, then `/plugin install SKILL@MARKETPLACE`. A private repo uses your own git credentials: load an SSH key in `ssh-agent`, or store an HTTPS credential with the GitHub CLI (login, then its git-credential setup). Pull changes with `/plugin marketplace update` (auto-update is off by default).
>
> **Any agent (plain copy).** Clone, then link the skill folder where your tool reads skills:
>
> ```
> git clone git@github.com:OWNER/REPO.git ~/src/SKILL
> ln -s ~/src/SKILL/skills/SKILL ~/.agents/skills/SKILL    # Codex, Cursor, Gemini CLI
> ln -s ~/src/SKILL/skills/SKILL ~/.claude/skills/SKILL    # Claude Code without the plugin
> ```
>
> Per project, use `.agents/skills/` or `.claude/skills/` inside the repo. Restart the agent (Gemini CLI: `/skills reload`).
>
> **Tracker access.** Jira: add the Atlassian remote MCP. Linear: add `https://mcp.linear.app/mcp`. GitHub: install `gh` and sign in. No tracker: paste the issue text.
