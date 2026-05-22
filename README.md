# jotbook

A Claude Code plugin to help easily create a curated knowledge base from ad-hoc explanations.

If you are a vibe coder, your agent is almost certainly implementing stuff you don't fully understand. If you are a *responsible* vibe coder, you are asking your agent to explain what it just implemented in detail so you can learn about it. Jotbook is for the responsible vibe coder. 

When Claude gives you a substantive explainer of something — a system, a concept, a piece of code — you often want to revisit it later as a polished long-form note, but you don't want to interrupt the current work to decide if it's worth saving, let alone write it. This plugin gives you a three-stage workflow: **jot** down a quick note to revisit an explainer cheaply in the moment, **review** the backlog periodically for still-relevant explainers, **ink** the survivors into finished entries in your jotbook.

## How it works

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

You can drive each stage by hand with `/jot`, or just run `/jotbook` for a guided session that walks review → ink in one pass.

---

By default, the plugin will just nudge Claude to ask if you'd like to save an explainer as a candidate for future codification. But the the real magic happens when you auto-detect candidate entries and save them to the backlog silently for you to review later (`auto_stage_mode`). 

Review your backlog later, cut what's not relevant, and ink new entries. Inking also updates existing inked entries with new links (if relevant) for all you Obsidian node heads.

Format your jotbook as linked markdown (default), Obsidian vault, or HTML files for added pizzazz.

## Install

Once published to a marketplace:

```
/plugin install jotbook@<marketplace-name>
```

Or install manually by cloning into your Claude Code plugins directory.

## Quickstart

In any project:

```
/jot init
```

This writes a starter `.claude/jotbook.local.md` settings file (and offers to add it to your `.gitignore`). Edit the defaults if you want; otherwise everything works out of the box.

Then, during normal use:

| When | Do |
|---|---|
| Claude just gave you an explainer you'll want to revisit | `/jot` (or let the auto-stage hook nudge you) |
| Your jot backlog has gotten chunky | `/jotbook` |
| You want to ink one specific jot right now | `/jot ink <slug>` |
| You want to draft a long-form preview before deciding | `/jot pencil <slug>` |

## Commands

The plugin uses a dual-command shape: `/jotbook` for the *artifact* (the whole curation flow), `/jot` for the *verb* (atomic actions on individual jots).

| Command | Purpose |
|---|---|
| `/jotbook` | **Guided curation flow.** Reviews the backlog, lets you drop/merge/tweak/ink/pencil jots, then inks anything you marked as ready. The primary entry point. |
| `/jot [subject]` | Stage a jot. With no argument, infers from recent conversation; with an argument, uses it as the subject phrase. Also invoked by the auto-stage hook. |
| `/jot review` | Inventory the jot backlog and apply structural decisions only — no ink step. |
| `/jot review pencils` | Inventory the pencil backlog and decide what to ink, drop, revise, edit, or keep. |
| `/jot ink <slug>[,<slug>]` | Ink a jot (or several) into a finished entry. Comma-separated slugs consolidate into one entry. If a pencil already exists for the slug, you'll be offered to promote it instead of regenerating. |
| `/jot pencil <slug>[,<slug>] [--html]` | Pencil a jot (or several) into a provisional long-form draft for later evaluation. Default format is Markdown; `--html` opts into the HTML template (requires `template_path`). Source jot(s) are preserved. |
| `/jot init` | Write the starter settings file (and optionally amend your `.gitignore`). |

Reserved words after `/jot` (`review`, `ink`, `pencil`, `init`, `stage`) are interpreted as subcommands. If you want to jot a subject that starts with one of those words, use `/jot stage <subject>`.

## Pencil drafts

Sometimes you can't tell if a jot is worth inking until you read the long-form version. **Pencil** is an optional intermediate step: produce the full elaboration first, then evaluate it like you would a jot.

Pencils live in their own backlog (`pencils_dir`, default `docs/jotbook/_pencils/`). The source jot stays in place until the pencil resolves one way or the other.

### Creating a pencil

```
/jot pencil <slug>            # from a jot in your backlog
/jot pencil <slug-a>,<slug-b> # consolidate multiple jots into one pencil
/jot pencil <slug> --html     # opt into the HTML template (requires template_path)
```

You can also create a pencil from inside the `/jotbook` flow: `pencil <slug>` is a valid decision alongside `ink`, `drop`, `merge`, `tweak`, and `keep`.

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
| `jots_dir` | `docs/jotbook/_candidates/` | Where staged jots are written. |
| `entries_dir` | `docs/jotbook/` | Where inked entries are written. |
| `pencils_dir` | `docs/jotbook/_pencils/` | Where pencil drafts are written. |
| `output_format` | `markdown` | One of `markdown`, `obsidian`, `html`. See **Output modes** below. Pencils default to Markdown regardless; opt into the template with `--html`. |
| `template_path` | (none) | Path to an HTML template, used only when `output_format: html` or when a pencil is drafted with `--html`. |
| `auto_stage_mode` | `prompt` | One of `off`, `prompt`, `auto`. See **Auto-stage hook** below. |
| `backlog_threshold` | `8` | Session-start jot nudge fires when the jot count reaches this number. |
| `pencils_threshold` | `3` | Session-start pencil nudge fires when the pencil count reaches this number. Smaller default since pencils are heavier per item. |

The **body** of the settings file (after the closing `---`) is treated by `jotbook-ink` and `jotbook-pencil` as house-style guidance — voice, tone, terminology, formatting conventions. Use it for things that should shape the writeup but don't fit in a single config field.

Example:

```yaml
---
jots_dir: docs/jotbook/_candidates/
entries_dir: docs/jotbook/
pencils_dir: docs/jotbook/_pencils/
output_format: obsidian
auto_stage_mode: prompt
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

## Auto-stage hook

The plugin includes a Stop hook that fires when Claude finishes responding and can nudge you about an explainer worth jotting.

| `auto_stage_mode` | Behavior |
|---|---|
| `off` | Hook is a no-op. Stage manually with `/jot`. |
| `prompt` (default) | Hook evaluates the last turn; if it looks like a substantive explainer, asks you in one line whether to jot it. You decide. |
| `auto` | Hook evaluates the last turn; if substantive, silently jots it with an inferred slug. Reports a single `(jotted: <slug>)` line. Skips silently if the subject is ambiguous. |

The hook is intentionally conservative — false positives are annoying. When in doubt it does nothing.

## Backlog reminder

A SessionStart hook counts files in `jots_dir` and `pencils_dir` and surfaces a one-line nudge when either reaches its threshold (`backlog_threshold` for jots, `pencils_threshold` for pencils). The nudge points you at `/jotbook` for jots and `/jot review pencils` for pencils. The hook is a no-op when neither threshold is met.

## Restart caveat

Hooks are loaded when Claude Code starts. Editing `auto_stage_mode`, `backlog_threshold`, or `pencils_threshold` in the settings file won't take effect until you exit and restart Claude Code. The skills and commands themselves pick up settings changes immediately.

## Configuration cheatsheet

| To… | Set… |
|---|---|
| Disable the staging nudge entirely | `auto_stage_mode: off` |
| Have Claude jot explainers silently | `auto_stage_mode: auto` |
| Ink into an Obsidian vault | `output_format: obsidian` + `entries_dir: <vault-folder>` |
| Use a custom HTML template | `output_format: html` + `template_path: <path>` |
| Draft a specific pencil with the HTML template | `/jot pencil <slug> --html` (requires `template_path`) |
| Change where jots live | `jots_dir: <path>` |
| Change where pencils live | `pencils_dir: <path>` |
| Move the jot backlog nudge threshold | `backlog_threshold: <n>` |
| Move the pencil backlog nudge threshold | `pencils_threshold: <n>` |

## License

MIT — see [LICENSE](LICENSE).
