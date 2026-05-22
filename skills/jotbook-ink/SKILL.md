---
name: jotbook-ink
description: Ink one or more reviewed jots into a finished long-form entry in the jotbook. Reads the referenced source files, optionally consolidates multiple jots, and writes the entry under the configured entries directory. If a pencil already exists for the slug, offers to promote it (skipping gather/plan/render) instead of regenerating from scratch. Removes consumed jots (and the promoted pencil, if any) on success. Invoked by `/jot ink <slug>[,<slug>]`, by the final phase of the bare `/jotbook` flow, or by the pencil-review `ink` decision.
---

# Ink a jot into the jotbook

You're turning a jot (or a small set of related jots) into a long-form entry. The jot file is a *pointer*; the actual content needs to be reconstructed from the referenced files, conversation history, and — if context is thin — direct questions to the user. The output is an inked entry in the jotbook.

If a **pencil** (provisional draft) already exists for the requested slug, you can promote it instead of regenerating — see the **Pencil promotion** branch in step 2.

## Resolve configuration

Read `.claude/jotbook.local.md` if present. From the frontmatter, extract:

| field | default | meaning |
|---|---|---|
| `jots_dir` | `docs/jotbook/_candidates/` | where staged jots live |
| `pencils_dir` | `docs/jotbook/_pencils/` | where pencils live (checked for promotion) |
| `entries_dir` | `docs/jotbook/` | where inked entries are written |
| `output_format` | `markdown` | one of `markdown`, `obsidian`, `html` |
| `template_path` | (none) | path to an HTML template used when `output_format: html` |

The **body** of the settings file (everything after the closing `---`) is optional house-style guidance — voice, tone, conventions, terminology. If present, treat it as authoritative for stylistic decisions.

If `output_format: html` is set but `template_path` is empty or points to a missing file, stop. Do **not** invent a template inside this flow. Instead, surface the situation clearly to the user — something along the lines of:

> "I can't ink this entry — `output_format` is `html` but `template_path` isn't set (or points to a missing file). Two ways forward: (1) switch `output_format` to `markdown` in your settings and re-run, or (2) start a separate conversation to design the HTML template — Claude can help you build one, but it's a substantial design task that shouldn't happen inside the `/jot ink` flow. Once the template exists, point `template_path` at it and re-run."

Then stop. The point is to make the template a deliberate, named artifact rather than something improvised mid-ink.

(One exception: if a pencil already exists in HTML format for the requested slug and the user opts to promote it, the template gate doesn't apply — the template work happened at pencil time. The pencil's HTML is the source of truth.)

## Inputs

- One or more jot slugs from the user's invocation (single slug, or comma-separated for a merged entry).
- Files referenced on each jot's `Files:` line.
- The conversation, if the original explainer is still in context.
- The user, for any gaps that the files and conversation can't fill.
- Optionally: an existing pencil at `<pencils_dir>/<slug>.<ext>`.

## Procedure

### 1. Resolve inputs

- Parse the slug(s) from the invocation argument.
- For each slug, check whether a pencil exists at `<pencils_dir>/<slug>.md` or `<pencils_dir>/<slug>.html`.
- Locate the jot file(s) under `jots_dir`. If a slug matches neither a jot nor a pencil, list what's there and ask the user to clarify — do not guess.
- Read each existing jot's description and `Files:` line.

### 2. Choose path: promotion vs. fresh render

If a pencil exists for any of the requested slugs, surface this and ask:

> "A pencil for `<slug>` exists (drafted `<date>`). Promote it (skip regen — just transform frontmatter, cross-link, and clean up) or regenerate from scratch?"

For multi-slug invocations where some have pencils and some don't, ask per-slug or ask once how to handle the batch.

- **Promote** → follow the **Promotion path** below (steps 3a → 5 → 6). Skip the **Fresh render path**.
- **Regenerate fresh** → follow the **Fresh render path** below (steps 3b → 4 → 5 → 6). At cleanup time, ask once whether to delete the now-stale pencil (default: delete).

If no pencil exists, follow the **Fresh render path** with no branching.

### 3a. Promotion path — read the pencil

(Skip this step if you're on the Fresh render path.)

- Read the pencil at `<pencils_dir>/<slug>.<ext>`.
- Extract the body (everything after the YAML frontmatter for `.md` pencils, or below the leading HTML comment block for `.html` pencils).
- Note the pencil's format — `md` or `html`.
- Use **Format precedence** (below) to determine the output extension and any transformation needed.
- Transform frontmatter as follows, writing to `<entries_dir>/<slug>.<ext>`:
  - **Markdown entry** (`output_format: markdown`): no frontmatter; write the body, then append the trailing `*Sources:*` line listing the pencil's `sources:` field (or omit if empty).
  - **Obsidian entry** (`output_format: obsidian`): write Obsidian frontmatter — `tags` (3–6 short topic tags inferred from content), `aliases` (only if natural alternates), `created` (today's date in `YYYY-MM-DD`), `sources` (carried over from the pencil's `sources:` field). Drop the trailing `*Sources:*` line — that info lives in the frontmatter for Obsidian.
  - **HTML entry** (`output_format: html`, pencil was Markdown): render through the template at `template_path` using the pencil body as source material. Follow the HTML output conventions described in **Fresh render: HTML output**. This is the Markdown→HTML uplift — automatic, no question asked.
  - **HTML pencil → HTML entry** (`output_format: html`): keep the HTML body as-is. Apply any template tokens that should change at ink time (issue numbering finalization, masthead "draft" → "published" if present, etc.).
  - **HTML pencil → Markdown/Obsidian global format**: ask the user once before promoting:

    > "The pencil is HTML but your `output_format` is `<format>`. Keep the entry as `.html` (default — preserves the SVG/layout work that made you choose HTML at draft time) or downcast to Markdown (lossy: diagrams become alt text, complex layouts flatten)?"

    Default to **keep as HTML** if the user doesn't pick. If they pick downcast: extract the readable content from the HTML body, convert to Markdown (preserve semantic structure where possible — headings, lists, code blocks, links; flatten interactive/visual elements to descriptive text or alt text), and write to `<entries_dir>/<slug>.md` with frontmatter appropriate for the global format (Obsidian's frontmatter for `obsidian`, none for plain `markdown`). Mention the downcast in your final report so the user knows what happened.

Then jump to step 5 (Update related entries) and step 6 (Clean up).

### 3b. Fresh render path — gather material

(Skip this step if you're on the Promotion path.)

- Read every file listed under `Files:`.
- If the original explainer is in conversation context, anchor on it for the user's voice/framing.
- If gaps remain (motivation, history, design rationale that isn't in code), ask the user a small, targeted set of questions before writing. Don't ship an entry with placeholder framing.

### 4. Fresh render path — plan and render

(Skip this step if you're on the Promotion path.)

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

Then write to `<entries_dir>/<slug>.<ext>` where `<ext>` is `md` (for `markdown` or `obsidian`) or `html` (for `html`).

#### Fresh render: Markdown output (default)

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

#### Fresh render: Obsidian output

Same body structure as Markdown, with these differences tuned for an Obsidian vault:

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

#### Fresh render: HTML output

When `output_format: html` and `template_path` is set:

1. Read the template at `template_path`.
2. Replace any `{{PLACEHOLDER}}` tokens it contains using the planned title, standfirst, sections, etc. Match the template's conventions (numbering schemes, masthead fields, colophon) — do not invent your own.
3. **Never paste CSS inline** if the template links a stylesheet. Use the existing `<link>` reference.
4. Honor any conventions documented in the house-style body of the settings file (e.g., issue numbering, system numbering, phase tags).

### 5. Update related entries

(Both paths execute this step.)

If this entry deserves to be linked **from** an existing entry, add a link from the appropriate place in that entry. Confirm with the user before editing a previously-inked entry.

### 6. Clean up

(Both paths execute this step.)

- Delete the consumed jot file(s) from `jots_dir`. If multiple were consolidated, delete all of them.
- If you took the **Promotion path**: also delete the pencil file from `pencils_dir`.
- If you took the **Fresh render path** AND a pencil existed for the slug (which the user opted not to promote): ask once whether to delete the now-stale pencil. Default to delete.
- Show the user the path of the new entry and any entries you edited for cross-links.

## Format precedence (promotion only)

Format conversion at promotion is **asymmetric**: going up in fidelity (Markdown → HTML) is automatic; going down (HTML → Markdown) is opt-in. The principle is that picking HTML at draft time was a deliberate signal that the entry wanted the richer format — don't silently throw that away.

| pencil format | `output_format` | entry written as | how |
|---|---|---|---|
| `.md` | `markdown` | `.md` (plain) | direct write |
| `.md` | `obsidian` | `.md` (with Obsidian frontmatter) | direct write |
| `.md` | `html` | `.html` (via template) | render pencil body through `template_path` — automatic, no prompt |
| `.html` | `markdown` | `.html` (default) or `.md` (if user opts to downcast) | **ask once during promotion** |
| `.html` | `obsidian` | `.html` (default) or `.md` (if user opts to downcast) | **ask once during promotion** |
| `.html` | `html` | `.html` | direct write; finalize any ink-time template tokens |

When asking about HTML→Markdown downcast, default to **keep as HTML** and warn the user that downcast is lossy (diagrams flatten to alt text, complex layouts collapse to prose).

The fresh render path always uses `output_format` — this table only applies when promoting a pencil.

## Hard rules

- **Don't invent facts.** If you don't know something (a number, a rationale, a constraint), ask the user or omit it. Faking authority erodes trust in the whole jotbook.
- **No marketing language, no AI-isms** ("Let's dive in!", "It's important to note that…"). Match the user's existing voice. If the house-style body specifies tone, follow it.
- **No "Generated by Claude" footers** unless the template already includes one.
- **No emojis** in entry content unless the house-style explicitly allows them.
- **Don't proliferate output files.** One entry per ink, unless the user explicitly asks for a multi-entry set.
- **Don't paste CSS inline** in HTML output when the template already links a stylesheet.
- **Don't promote a pencil without confirmation.** If a pencil exists, ask before taking the promotion path.
- **Don't delete a pencil silently on the fresh path.** When the user chose to regenerate, confirm once before removing the stale pencil.
