---
name: jotbook-ink
description: Ink one or more reviewed jots into a finished long-form entry in the jotbook. Reads the referenced source files, optionally consolidates multiple jots, and writes the entry under the configured entries directory. Removes consumed jots on success. Invoked by `/jot ink <slug>[,<slug>]` or as the final phase of the bare `/jotbook` flow.
---

# Ink a jot into the jotbook

You're turning a jot (or a small set of related jots) into a long-form entry. The jot file is a *pointer*; the actual content needs to be reconstructed from the referenced files, conversation history, and — if context is thin — direct questions to the user. The output is an inked entry in the jotbook.

## Resolve configuration

Read `.claude/jotbook.local.md` if present. From the frontmatter, extract:

| field | default | meaning |
|---|---|---|
| `jots_dir` | `docs/jotbook/_candidates/` | where staged jots live |
| `entries_dir` | `docs/jotbook/` | where inked entries are written |
| `output_format` | `markdown` | one of `markdown`, `obsidian`, `html` |
| `template_path` | (none) | path to an HTML template used when `output_format: html` |

The **body** of the settings file (everything after the closing `---`) is optional house-style guidance — voice, tone, conventions, terminology. If present, treat it as authoritative for stylistic decisions.

If `output_format: html` is set but `template_path` is empty or points to a missing file, stop. Do **not** invent a template inside this flow. Instead, surface the situation clearly to the user — something along the lines of:

> "I can't ink this entry — `output_format` is `html` but `template_path` isn't set (or points to a missing file). Two ways forward: (1) switch `output_format` to `markdown` in your settings and re-run, or (2) start a separate conversation to design the HTML template — Claude can help you build one, but it's a substantial design task that shouldn't happen inside the `/jot ink` flow. Once the template exists, point `template_path` at it and re-run."

Then stop. The point is to make the template a deliberate, named artifact rather than something improvised mid-ink.

## Inputs

- One or more jot slugs from the user's invocation (single slug, or comma-separated for a merged entry).
- Files referenced on each jot's `Files:` line.
- The conversation, if the original explainer is still in context.
- The user, for any gaps that the files and conversation can't fill.

## Procedure

### 1. Resolve inputs

- Parse the slug(s) from the invocation argument.
- Locate the jot file(s) under `jots_dir`. If a slug doesn't match, list what's there and ask the user to clarify — do not guess.
- Read each jot's description and `Files:` line.

### 2. Gather material

- Read every file listed under `Files:`.
- If the original explainer is in conversation context, anchor on it for the user's voice/framing.
- If gaps remain (motivation, history, design rationale that isn't in code), ask the user a small, targeted set of questions before writing. Don't ship an entry with placeholder framing.

### 3. Plan the structure

Before writing, decide and briefly share with the user:

- **Title** — short, descriptive.
- **Standfirst / lede** — one or two sentences setting the scene.
- **Sections** — most entries land at 3–6. Don't pad.
- **Sub-sections** — when a section has more than ~3 distinct beats.
- **Diagrams** — only when the concept has structure prose alone obscures (data flow, layout, state machine). For HTML output use inline SVG; for Markdown skip diagrams or use a fenced ASCII sketch if it genuinely helps.
- **Callouts** — note / warning blocks for asides and gotchas. Use sparingly.
- **Tables** — for keymaps, parameter lists, mode references.
- **Code blocks** — keep extracts short (≤ ~20 lines).
- **Cross-links** — link to other entries in `entries_dir` when topically related.

Tell the user the planned section list before writing the file, so they can redirect early if the shape is off.

### 4. Render

Determine the output path:

```
<entries_dir>/<slug>.<ext>
```

Where `<ext>` is `md` (for `markdown` or `obsidian`) or `html` (for `html`). The slug is the final concept slug (kebab-case, no date prefix).

#### Markdown output (default)

Write a plain Markdown file:

```markdown
# <Title>

<one or two sentence standfirst>

## <Section 1>

...

## <Section 2>

...

> **Note:** Use GitHub-flavored note/warning callouts where helpful.

---

*Sources: `path/to/file_one.ext`, `path/to/file_two.ext`*
```

End with a small *Sources:* line listing the jot's `Files:` for traceability. No frontmatter unless the user's house-style notes specify one.

#### Obsidian output

Same body structure as the Markdown output, with these differences tuned for an Obsidian vault:

- **Frontmatter** at the top with `tags` (3–6 short topic tags inferred from content), `aliases` (only if the title has natural alternate phrasings), `created` (today's date in `YYYY-MM-DD`), and `sources` (the jot's `Files:` list, one per line).
- **Cross-links** to other entries in `entries_dir` use `[[wikilink]]` syntax — the link target is the entry slug without the `.md` extension. Use standard markdown links only for external URLs.
- **Inline tags** like `#topic/subtopic` are fine where they read naturally — don't force them.
- **Drop the trailing `*Sources:*` line** — that information lives in the frontmatter for Obsidian.

Example frontmatter:

```yaml
---
tags: [jotbook, cache]
aliases: [LRU eviction, cache policy]
created: 2026-05-22
sources:
  - src/cache/lru.ts
  - src/cache/metrics.ts
---
```

#### HTML output

If `output_format: html` and `template_path` is set:

1. Read the template at `template_path`.
2. Replace any `{{PLACEHOLDER}}` tokens it contains using the planned title, standfirst, sections, etc. Match the template's conventions (numbering schemes, masthead fields, colophon) — do not invent your own.
3. **Never paste CSS inline** if the template links a stylesheet. Use the existing `<link>` reference.
4. Honor any conventions documented in the house-style body of the settings file (e.g., issue numbering, system numbering, phase tags).

### 5. Update related entries

If this entry deserves to be linked **from** an existing entry, add a link from the appropriate place in that entry. Confirm with the user before editing a previously-inked entry.

### 6. Clean up

- Delete the consumed jot file(s) from `jots_dir`. If multiple were consolidated, delete all of them.
- Show the user the path of the new entry and any entries you edited for cross-links.

## Hard rules

- **Don't invent facts.** If you don't know something (a number, a rationale, a constraint), ask the user or omit it. Faking authority erodes trust in the whole jotbook.
- **No marketing language, no AI-isms** ("Let's dive in!", "It's important to note that…"). Match the user's existing voice. If the house-style body specifies tone, follow it.
- **No "Generated by Claude" footers** unless the template already includes one.
- **No emojis** in entry content unless the house-style explicitly allows them.
- **Don't proliferate output files.** One entry per ink, unless the user explicitly asks for a multi-entry set.
- **Don't paste CSS inline** in HTML output when the template already links a stylesheet.
