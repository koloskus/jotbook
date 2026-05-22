# jotbook

A Claude Code plugin for turning ad-hoc explainers into a curated knowledge base.

When Claude gives you a substantive explanation of something — a system, a concept, a piece of code — you often want to revisit it later as a polished long-form note, but you don't want to interrupt the current work to write it. This plugin gives you a three-stage workflow: **jot** a note down cheaply in the moment to revisit this subject, **review** the backlog periodically, **ink** the survivors into finished entries in your jotbook.

By default the plugin will just nudge Claude to ask you if you'd like to save an explainer as a candidate for potential future codification. But the the real magic happens when you auto-detect candidate entries and save them to the backlog automatically for you to review later (`auto_stage_mode`).

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

## Commands

The plugin uses a dual-command shape: `/jotbook` for the *artifact* (the whole curation flow), `/jot` for the *verb* (atomic actions on individual jots).

| Command | Purpose |
|---|---|
| `/jotbook` | **Guided curation flow.** Reviews the backlog, lets you drop/merge/tweak/ink jots, then inks anything you marked as ready. The primary entry point. |
| `/jot [subject]` | Stage a jot. With no argument, infers from recent conversation; with an argument, uses it as the subject phrase. Also invoked by the auto-stage hook. |
| `/jot review` | Inventory the backlog and apply structural decisions only — no ink step. |
| `/jot ink <slug>[,<slug>]` | Ink a jot (or several) into a finished entry. Comma-separated slugs consolidate into one entry. |
| `/jot init` | Write the starter settings file (and optionally amend your `.gitignore`). |

Reserved words after `/jot` (`review`, `ink`, `init`, `stage`) are interpreted as subcommands. If you want to jot a subject that starts with one of those words, use `/jot stage <subject>`.

## Settings

Settings live at `.claude/jotbook.local.md` in each project. YAML frontmatter for config, an optional markdown body for house-style guidance.

| Field | Default | Meaning |
|---|---|---|
| `jots_dir` | `docs/jotbook/_candidates/` | Where staged jots are written. |
| `entries_dir` | `docs/jotbook/` | Where inked entries are written. |
| `output_format` | `markdown` | One of `markdown`, `obsidian`, `html`. See **Output modes** below. |
| `template_path` | (none) | Path to an HTML template, used only when `output_format: html`. |
| `auto_stage_mode` | `prompt` | One of `off`, `prompt`, `auto`. See **Auto-stage hook** below. |
| `backlog_threshold` | `8` | Session-start backlog nudge fires when the jot count reaches this number. |

The **body** of the settings file (after the closing `---`) is treated by `jotbook-ink` as house-style guidance — voice, tone, terminology, formatting conventions. Use it for things that should shape the writeup but don't fit in a single config field.

Example:

```yaml
---
jots_dir: docs/jotbook/_candidates/
entries_dir: docs/jotbook/
output_format: obsidian
auto_stage_mode: prompt
backlog_threshold: 12
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

A SessionStart hook counts the jots in `jots_dir` and surfaces a one-line nudge when the count reaches `backlog_threshold`. The nudge points you at `/jotbook` (the guided flow). The hook is a no-op when the directory doesn't exist or the threshold isn't met.

## Restart caveat

Hooks are loaded when Claude Code starts. Editing `auto_stage_mode` or `backlog_threshold` in the settings file won't take effect until you exit and restart Claude Code. The skills and commands themselves pick up settings changes immediately.

## Configuration cheatsheet

| To… | Set… |
|---|---|
| Disable the staging nudge entirely | `auto_stage_mode: off` |
| Have Claude jot explainers silently | `auto_stage_mode: auto` |
| Ink into an Obsidian vault | `output_format: obsidian` + `entries_dir: <vault-folder>` |
| Use a custom HTML template | `output_format: html` + `template_path: <path>` |
| Change where jots live | `jots_dir: <path>` |
| Move the backlog nudge threshold | `backlog_threshold: <n>` |

## License

MIT — see [LICENSE](LICENSE).
