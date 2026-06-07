---
name: jotbook-ink
description: Primary jotbook entry point. With no arguments, runs the guided curation session over the jot backlog. With one or more jot slugs, inks those jots into finished long-form entries (promotes any existing pencil instead of regenerating).
---

# Ink the jotbook

This is the primary jotbook entry point. It has two shapes, both gated on initialization:

- **`/jotbook-ink` (no arguments)** — guided curation session. Review the backlog, mark decisions, then ink or pencil the chosen ones.
- **`/jotbook-ink <slug>[,<slug>]`** — ink one or more specific reviewed jots into finished long-form entries (the targeted form).

If the plugin hasn't been initialized in this project (no `.claude/jotbook.local.md`), either shape routes to `jotbook-init` first. After init completes, the user re-invokes whichever flow they actually wanted.

## Entry-point dispatch

Read the invocation arguments and route as follows. Do this **before** reading the rest of the skill:

1. **Plugin not yet initialized** (no `.claude/jotbook.local.md` in the project) → invoke the `jotbook-init` skill. After init completes, stop. Do not auto-chain into curation or the per-slug procedure — let the user re-invoke once they're set up.

2. **No slug arguments** → the curation session. Hand off to `jotbook-review`, which owns the full decision loop: it inventories jots, takes the user's free-form decisions (drop / merge / tweak / ink / pencil / keep, the latter two accepting their respective slugs and any `--html` flag), applies structural changes in place, and dispatches into this skill's per-slug procedure (for `ink`) or `jotbook-pencil` (for `pencil`) directly. Do not duplicate that orchestration here — let the review skill drive end-to-end.

   When the per-slug procedure is re-entered from review and detects an existing pencil, let it handle the promote-vs-regenerate question.

   If the jot backlog is empty when review starts, it reports and stops on its own — no further action needed here.

3. **One or more slugs supplied** → the targeted form. Continue with the per-slug procedure below (Resolve configuration → Inputs → Procedure).

### Dispatch hard rules

- Do not silently invent slugs or jots that don't exist on disk.
- Do not invoke `jotbook-pencil` or the per-slug procedure without the user explicitly marking a jot as ready.
- Do not enter the pencil-review flow from here — that stays at `/jotbook-pencil-review`.
- If routing to `jotbook-init`, defer entirely to it. Don't continue on a fresh just-initialized jotbook (there are no jots yet anyway).

---

The remaining sections apply only to the **targeted-ink path** (one or more slugs supplied). You're turning a specific jot (or a small set of related jots) into a long-form entry. The jot file is a *pointer*; the actual content needs to be reconstructed from the referenced files, conversation history, and — if context is thin — direct questions to the user. The output is an inked entry in the jotbook.

If a **pencil** (provisional draft) already exists for the requested slug, you can promote it instead of regenerating — see the **Pencil promotion** branch in step 2 of Procedure.

## Resolve configuration

Read `.claude/jotbook.local.md` if present. From the frontmatter, extract:

| field | default | meaning |
|---|---|---|
| `jots_dir` | `docs/jotbook/_jots/` | where staged jots live |
| `pencils_dir` | `docs/jotbook/_pencils/` | where pencils live (checked for promotion) |
| `entries_dir` | `docs/jotbook/` | where inked entries are written |
| `output_format` | `markdown` | one of `markdown`, `obsidian`, `html` |
| `template_path` | (none) | path to an HTML template used when `output_format: html` |

The **body** of the settings file (everything after the closing `---`) is optional house-style guidance — voice, tone, conventions, terminology. If present, treat it as authoritative for stylistic decisions.

If `output_format: html` is set but `template_path` is empty or points to a missing file, stop. Do **not** invent a template inside this flow. Instead, surface the situation clearly to the user — something along the lines of:

> "I can't ink this entry — `output_format` is `html` but `template_path` isn't set (or points to a missing file). Two ways forward: (1) switch `output_format` to `markdown` in your settings and re-run, or (2) run `/jotbook-template` (or `/jot template`) to design the HTML template — a guided design workflow that builds the template, verifies it, and (on your sign-off) wires `template_path` for you. Once the template exists, re-run."

Then stop — the template is a deliberate, named artifact, and `/jotbook-template` is where it gets built.

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

- **Promote** → follow the **Promotion path** below (steps 3a → 5 → 8). Skip the **Fresh render path**.
- **Regenerate fresh** → follow the **Fresh render path** below (steps 3b → 4 → 5 → 8). At cleanup time, ask once whether to delete the now-stale pencil (default: delete).

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

Then continue with step 5 (add navigation) through step 8 (regenerate the index).

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
4. **Strip the template's guiding HTML comments** from the finished entry. The `<!-- ... -->` notes (section pattern, delete-if-unused hints, token explanations) are authoring scaffolding — a published entry should not carry them. Remove every guiding comment after filling the tokens.
5. Honor any conventions documented in the house-style body of the settings file (e.g., issue numbering, system numbering, phase tags).

### 5. Add back-nav and a Contents TOC to the entry

(Both paths execute this step, on the entry just written to `entries_dir`.)

Every inked entry gets a link back to the jotbook index, so the collection is navigable from any entry. Longer entries also get a Contents list of their own sections.

- **Back-to-index link** — add a small link to the index at the top of the entry body, just above the `# Title`. If the file opens with YAML frontmatter, the link goes **below the closing `---`**, never above it — frontmatter must stay at line 1 or the parser (Obsidian especially) won't recognize it.
  - **Markdown**: prepend `[← Index](index.md)` as the first line (plain Markdown has no frontmatter), above the `# Title`.
  - **Obsidian**: place `[[index|← Index]]` immediately **below the frontmatter block**, above the `# Title` — not as line 1.
  - **HTML**: fill the template's `{{NAV}}` token with `<a href="index.html">← Index</a>`. The index lives in `entries_dir` alongside entries, so the relative href resolves. (HTML pencils are not indexed — `jotbook-pencil` leaves `{{NAV}}` empty.)
- **Contents TOC (only when it earns its place)** — if the entry has **3 or more top-level sections** (the section list you planned in step 4), add a Contents list just below the standfirst; otherwise omit it entirely — a short or two-section entry doesn't need the boilerplate.
  - **Markdown**: a `**Contents**` line followed by `- [Section title](#section-anchor)` items. GitHub derives the anchor from the `##` heading text (lowercased, spaces → hyphens, punctuation dropped) — match that.
  - **Obsidian**: `- [[#Section title]]` within-note heading links.
  - **HTML**: fill the `{{TOC}}` token with the anchor list and give each rendered `<section>` (or its `<h2>`) the matching `id` so the links resolve. Below the threshold, leave `{{TOC}}` empty.

When **promoting an already-rendered HTML pencil** (step 3a), the template tokens are already substituted, so there are no `{{NAV}}`/`{{TOC}}` placeholders to fill — insert the back-to-index anchor (and, if ≥3 sections, the Contents list + section `id`s) directly into the masthead/body instead.

### 6. Update related entries

(Both paths execute this step.)

If this entry is topically related to an existing entry, cross-link them: add a link from the appropriate place in the related entry to this one (and, where it reads naturally, from this one back). Confirm with the user before editing a previously-inked entry.

This is the at-ink-time pass over obviously-related entries. To re-examine the whole collection for missing links later — including linking older entries to entries inked after them — run `/jotbook-link` (or `/jot link`), the dedicated cross-link sweep.

### 7. Clean up

(Both paths execute this step.)

- Delete the consumed jot file(s) from `jots_dir`. If multiple were consolidated, delete all of them.
- If you took the **Promotion path**: also delete the pencil file from `pencils_dir`.
- If you took the **Fresh render path** AND a pencil existed for the slug (which the user opted not to promote): ask once whether to delete the now-stale pencil. Default to delete.
- Show the user the path of the new entry and any entries you edited for cross-links.

### 8. Regenerate the jotbook index

(Both paths execute this step.)

The index is the jotbook's landing page and table of contents. Rebuild it from scratch on every ink so it never drifts from what's on disk — do **not** append incrementally.

1. Glob `entries_dir` for entry files (`*.md` for `markdown`/`obsidian`, `*.html` for `html`). **Exclude** the index file itself (`index.md`/`index.html`) and anything under the `_jots`/`_pencils`/`_assets`/`_templates` subdirectories.
2. For each entry, read its title and date:
   - **Markdown**: title = first `# ` heading; date = file mtime (plain Markdown carries no date field).
   - **Obsidian**: title = first `# ` heading; date = `created:` frontmatter; tags = `tags:` frontmatter.
   - **HTML**: title = `<title>` or masthead `<h1>`; date = the rendered date if the template surfaces one.
3. Write `<entries_dir>/index.<ext>`, listing entries **reverse-chronological** (newest first):
   - **markdown** `index.md`: a `# Jotbook` heading and a `- [Title](slug.md)` list.
   - **obsidian** `index.md`: a `# Jotbook` MOC using `- [[slug|Title]]` wikilinks; group entries under `## <tag>` headings when the tags form natural clusters, otherwise a flat list.
   - **html** `index.html`: a document that LINKS `_assets/jotbook.css` (the index sits in `entries_dir` alongside entries, so the href resolves), with the masthead and a styled `<ul>` of entries. Use the index/landing classes the template's stylesheet defines — never inline CSS.
4. Report the index path alongside the new entry.

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
- **Regenerate the index after every ink.** Rebuild `index.<ext>` from the entries on disk (step 8) so the landing page never drifts. Exclude the index file and the `_jots`/`_pencils`/`_assets`/`_templates` subdirs from the listing.
- **A back-to-index link belongs on entries, not pencils.** The index lives in `entries_dir`; an HTML pencil sits one directory deeper and isn't indexed, so its `{{NAV}}` stays empty — never emit a depth-unsafe back-link from a pencil.
- **The Contents TOC is conditional.** Add it only when the entry has ≥3 top-level sections; never clutter a short entry with one.
