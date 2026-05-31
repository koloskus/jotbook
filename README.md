# jotbook

A Claude Code plugin to help easily curate a knowledge base from ad-hoc explanations.

If you are a vibe coder, your agent is almost certainly implementing stuff you don't fully understand. If you are a *responsible* vibe coder, you are asking your agent to explain what it just implemented in detail so you can learn about it. Jotbook is for the responsible vibe coder. 

When Claude gives you a substantive explainer of something — a system, a concept, a piece of code — you often want to revisit it later as a polished long-form note, but you don't want to interrupt the current work to decide if it's worth saving, let alone write it. This plugin gives you a three-stage workflow: **jot** down a quick note to revisit an explainer cheaply in the moment, **review** the backlog periodically for still-relevant explainers, **ink** the survivors into finished entries in your jotbook.

What makes it powerful is Claude knows to jot when it has explained something to you, so as you build stuff you can rest assured there's a record of what to return to learn from later.

## How it works

*Want to get a quick sense of how it works? run `/jotbook-pencil how-jotbook-works`*

```
  ┌──────────┐     ┌──────────┐     ┌──────────┐
  │   jot    │ ──▶ │  review  │ ──▶ │   ink    │
  └──────────┘     └──────────┘     └──────────┘
   lightweight      consolidate /     inked entry
   pointer file     drop / tweak      in the jotbook
```

- **Jot** is cheap: a one-line pointer file with today's date and (optionally) the files the explainer referenced. Use it freely — most won't survive.
- **Review** is curation: list the backlog, propose merges, drop the dead weight, tweak framings, mark the survivors.
- **Ink** is the actual writeup: read the referenced files, reconstruct the explanation, produce a finished entry. Markdown by default; Obsidian or HTML on request.

You can drive each stage by hand with `/jot`, or just run `/jotbook-ink` for a guided session that walks review → ink in one pass.

---

By default, when Claude gives you a substantive explainer it'll proactively stage it as a candidate for future codification — briefly noting what it jotted and writing the small pointer file under your jots directory. You review the backlog later and decide which candidates are worth elaborating into full entries.

Review your backlog later, cut what's not relevant, and ink new entries. Inking also updates existing inked entries with new links (if relevant) for all you Obsidian node heads.

Format your jotbook as linked markdown (default), Obsidian vault, or HTML files for added pizzazz.

## Install

Jotbook isn't yet published to a public Claude Code marketplace. This section will be updated when it is.

In the meantime, you can install jotbook by hosting it through your own **local plugin marketplace** — a directory on your machine with a `.claude-plugin/marketplace.json` file that points at your cloned jotbook directory. Once registered with `/plugin marketplace add <path>`, jotbook installs into any project via `/plugin install jotbook@<your-marketplace-name>`. See Anthropic's [plugin marketplaces docs](https://code.claude.com/docs/en/plugin-marketplaces) for the full setup walkthrough.

## Quickstart

In any project, run either:

```
/jotbook-ink
# or, equivalently when nothing is set up yet:
/jot init
```

The first run detects that the plugin hasn't been initialized in this project yet and writes a starter `.claude/jotbook.local.md` settings file (offering to add it to your `.gitignore` along the way). Edit the defaults if you want; otherwise everything works out of the box. Once initialized, `/jotbook-ink` becomes the guided curation flow.

Then, during normal use:

| When | Do |
|---|---|
| Claude just gave you an explainer you'll want to revisit | `/jot` (or let Claude stage it on its own — it'll usually offer after a real explainer) |
| Your jot backlog has gotten chunky | `/jotbook-ink` |
| You want to ink one specific jot right now | `/jot ink <slug>` |
| You want to draft a long-form preview before deciding | `/jot pencil <slug>` |

## Commands

Most operations have **two equivalent invocation forms**: the direct skill alias (`/jotbook-<skill>`) or via the `/jot` toolkit (`/jot <subcommand>`). Both route to the same skills; pick whichever your fingers prefer. See the namespace note below the table for why the rest of the skills use the `jotbook-` prefix.

| Command | Purpose |
|---|---|
| `/jotbook-ink [<slug>[,<slug>]]` | **Primary entry point.** With no args, runs the guided curation session (review backlog → mark decisions → apply ink/pencil to the chosen ones). With one or more slugs, inks those specific jots into finished entries (equivalent to `/jot ink <slug>`). Routes to `jotbook-init` if the plugin hasn't been initialized in this project yet. If a pencil already exists for the slug, you'll be offered to promote it instead of regenerating. |
| `/jot [subject]` | Stage a jot. With no argument, infers from recent conversation; with an argument, uses it as the subject phrase. Claude also invokes this automatically after substantive explainers, via the skill's auto-trigger description. (Equivalent: `/jotbook-stage`.) |
| `/jot review` | Inventory the jot backlog, then apply your decisions in place — drop / merge / tweak structurally, or dispatch directly into ink / pencil for marked slugs. No follow-up slash command needed. (Equivalent: `/jotbook-review`.) |
| `/jot review pencils` | Inventory the pencil backlog and decide what to ink, drop, revise, edit, or keep. (Equivalent: `/jotbook-pencil-review`.) |
| `/jot pencil <slug>[,<slug>] [--html]` | Pencil a jot (or several) into a provisional long-form draft for later evaluation. Default format is Markdown; `--html` opts into the HTML template (requires `template_path`). Source jot(s) are preserved. (Equivalent: `/jotbook-pencil <slug>`.) |
| `/jot init` | Write the starter settings file (and optionally amend your `.gitignore`). (Equivalent: `/jotbook-init`.) |

Reserved words after `/jot` (`review`, `ink`, `pencil`, `init`, `stage`) are interpreted as subcommands. If you want to jot a subject that starts with one of those words, use `/jot stage <subject>`.

> **Note on Claude Code's plugin namespace:** Claude Code skills surface as **bare** slash commands using their literal `name:` field — a skill named `foo` becomes `/foo`, not `/jotbook:foo`. That collides with built-in skills like `/init` and `/review` and with skills from other plugins. To dodge collisions, every jotbook skill except `jot` is manually prefixed: `jotbook-init`, `jotbook-ink`, `jotbook-pencil`, etc. `jot` itself is unique enough that we leave it bare so the toolkit dispatcher (`/jot <subcommand>`) reads naturally. Typing `/jotbook` triggers autocomplete listing every `jotbook-*` skill; `/jot` is its own thing alongside.

## Pencil drafts

Sometimes you can't tell if a jot is worth inking until you read the long-form version. **Pencil** is an optional intermediate step: produce the full elaboration first, then evaluate it like you would a jot.

Pencils live in their own backlog (`pencils_dir`, default `docs/jotbook/_pencils/`). The source jot stays in place until the pencil resolves one way or the other.

### Creating a pencil

```
/jot pencil <slug>            # from a jot in your backlog
/jot pencil <slug-a>,<slug-b> # consolidate multiple jots into one pencil
/jot pencil <slug> --html     # opt into the HTML template (requires template_path)
```

You can also create a pencil from inside the `/jotbook-ink` flow: `pencil <slug>` is a valid decision alongside `ink`, `drop`, `merge`, `tweak`, and `keep`.

### Reviewing pencils

```
/jot review pencils
```

Five decisions per pencil:

- **Ink** — promote to a finished entry. Cross-links into existing entries fire here. Pencil + source jot(s) are deleted on success.
- **Drop** — delete the pencil. Asks once whether to also delete the source jot(s); defaults to keeping them so you can redraft later.
- **Revise** — regenerate with your feedback notes. Bumps the `revised:` date.
- **Edit** — surfaces the file path; you'll hand-edit and re-run review later.
- **Keep** — no-op for now.

### Format

Pencils render as Markdown by default regardless of `output_format`, since most iteration is text. Pass `--html` when you want to see an SVG diagram or interactive sketch before deciding whether the entry is worth keeping.

Format conversion at ink time is **asymmetric** — going up in fidelity is automatic, going down is opt-in:

- **Markdown pencil → any `output_format`** — converts to match. A Markdown pencil promoted into an HTML jotbook is rendered through your template; the inked entry is the finalized form of the draft.
- **HTML pencil → Markdown/Obsidian `output_format`** — kept as `.html` by default. Choosing HTML at draft time was deliberate (you wanted the SVG, the interactive sketch, the richer layout), so the inked entry stays HTML even though your global format is Markdown. The promotion prompt offers an explicit downcast if you actually do want it flattened to Markdown — it's lossy (diagrams become alt text, complex layouts flatten), so it stays opt-in.
- **HTML pencil → HTML `output_format`** — promotes directly. Any ink-time template finalization (e.g., masthead "draft" → "published") applies.

## Settings

Settings live at `.claude/jotbook.local.md` in each project. YAML frontmatter for config, an optional markdown body for house-style guidance.

| Field | Default | Meaning |
|---|---|---|
| `jots_dir` | `docs/jotbook/_jots/` | Where staged jots are written. |
| `entries_dir` | `docs/jotbook/` | Where inked entries are written. |
| `pencils_dir` | `docs/jotbook/_pencils/` | Where pencil drafts are written. |
| `output_format` | `markdown` | One of `markdown`, `obsidian`, `html`. See **Output modes** below. Pencils default to Markdown regardless; opt into the template with `--html`. |
| `template_path` | (none) | Path to an HTML template, used only when `output_format: html` or when a pencil is drafted with `--html`. |
| `backlog_threshold` | `8` | Session-start jot nudge fires when the jot count reaches this number. |
| `pencils_threshold` | `3` | Session-start pencil nudge fires when the pencil count reaches this number. Smaller default since pencils are heavier per item. |

The **body** of the settings file (after the closing `---`) is treated by `jotbook-ink` and `jotbook-pencil` as house-style guidance — voice, tone, terminology, formatting conventions. Use it for things that should shape the writeup but don't fit in a single config field.

Example:

```yaml
---
jots_dir: docs/jotbook/_jots/
entries_dir: docs/jotbook/
pencils_dir: docs/jotbook/_pencils/
output_format: obsidian
backlog_threshold: 12
pencils_threshold: 3
---

# House style

Field-manual voice — restrained, precise, deadpan. No exclamation points.
Cross-link liberally; prefer wikilinks over relative paths.
Code excerpts capped at ~20 lines; longer extracts go in a sibling code block.
```

## Output modes

### `markdown` (default)

Plain GitHub-flavored Markdown. Sections, callouts (`> [!NOTE]`), tables, code blocks, relative `.md` links for cross-references. A trailing `*Sources:*` line lists the jot's referenced files.

### `obsidian`

Markdown tuned for an Obsidian vault. Same body structure as `markdown`, but with:

- YAML frontmatter: `tags`, `aliases`, `created`, `sources`.
- `[[wikilinks]]` for cross-links between entries instead of relative paths.
- Optional inline `#topic/subtopic` tags where they read naturally.

Point `entries_dir` at a folder inside your vault and entries appear there directly.

### `html`

Template-driven HTML for users who want a styled long-form output (zines, field manuals, internal wikis, etc.). Requires `template_path` to point at a real HTML file containing `{{PLACEHOLDER}}` tokens for the title, standfirst, sections, etc. `jotbook-ink` will refuse to invent a template — building one is a separate, deliberate design task.

If you'd like to build an HTML template for this mode, start a fresh conversation and ask Claude to help design one; then point `template_path` at it.

### Notion

Notion doesn't support file-based writes, so there's no `notion` output mode. The default `markdown` output is Notion-import-friendly, though — drag a finished entry into a Notion page and the structure comes through cleanly. A real Notion integration would need API access, likely as a separate plugin.

## Auto-staging

There's no separate "auto-stage hook" in the plugin — staging is driven by the `jotbook-stage` skill's description, which tells Claude to invoke the skill at the end of any turn where the last response was a substantive multi-paragraph explainer worth revisiting. Claude does the judgment call in-band: after a real explainer it'll briefly narrate ("Jotted as `cache-eviction-policy`") and you'll see the file land under `jots_dir`. After a short answer, status update, or jotbook-skill output, it won't trigger.

If Claude misses something you wanted staged, run `/jot [subject]` explicitly. If Claude stages something you didn't want, `/jot review` (or `/jotbook-review`) lets you drop it in seconds.

**For lower friction:** consider adding `Write(docs/jotbook/_jots/**)` to your project's `.claude/settings.json` `permissions.allow` list, so the staging skill's file write doesn't prompt you each time. The plugin doesn't ship this allow rule (permissions are a per-user decision), but it's a one-line addition.

## Backlog reminder

A SessionStart hook counts files in `jots_dir` and `pencils_dir` and surfaces a one-line nudge when either reaches its threshold (`backlog_threshold` for jots, `pencils_threshold` for pencils). The nudge points you at `/jotbook-ink` for jots and `/jot review pencils` for pencils. The hook is a no-op when neither threshold is met.

## Restart caveat

The SessionStart hook is loaded when Claude Code starts. Editing `backlog_threshold` or `pencils_threshold` in the settings file won't take effect until you exit and restart Claude Code. The skills and commands themselves pick up settings changes immediately.

## Configuration cheatsheet

| To… | Set… |
|---|---|
| Skip the staging prompt entirely | Allow `Write(docs/jotbook/_jots/**)` in project `.claude/settings.json` |
| Tell Claude to stop auto-staging | Add to project `CLAUDE.md`: "Do not invoke jotbook-stage automatically." |
| Ink into an Obsidian vault | `output_format: obsidian` + `entries_dir: <vault-folder>` |
| Use a custom HTML template | `output_format: html` + `template_path: <path>` |
| Draft a specific pencil with the HTML template | `/jot pencil <slug> --html` (requires `template_path`) |
| Change where jots live | `jots_dir: <path>` |
| Change where pencils live | `pencils_dir: <path>` |
| Move the jot backlog nudge threshold | `backlog_threshold: <n>` |
| Move the pencil backlog nudge threshold | `pencils_threshold: <n>` |

## License

MIT — see [LICENSE](LICENSE).
