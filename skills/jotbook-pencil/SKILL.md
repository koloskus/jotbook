---
name: jotbook-pencil
description: Render one or more jots — or a fresh subject, which is staged as a jot first — into a provisional long-form draft (a "pencil") for later evaluation. Source jots are preserved and no cross-links are written — promotion happens later via `/jotbook-pencil-review`.
---

# Pencil a jot into a provisional draft

You're producing the long-form version of a jot (or merged jots) for later evaluation. A pencil is a draft: it lives in `pencils_dir`, the source jot(s) stay in `jots_dir`, and no cross-links into existing entries are written. Promotion to a finished entry happens later, via `/jot review pencils`.

## Resolve configuration

Read `.claude/jotbook.local.md` if present. From the frontmatter, extract:

| field | default | meaning |
|---|---|---|
| `jots_dir` | `docs/jotbook/_jots/` | where staged jots live |
| `pencils_dir` | `docs/jotbook/_pencils/` | where pencils are written |
| `output_format` | `markdown` | global output mode — informs cross-link style but does NOT change a pencil's format unless `--html` is passed |
| `template_path` | (none) | path to an HTML template — required when `--html` is passed |

The **body** of the settings file (everything after the closing `---`) is optional house-style guidance — voice, tone, conventions, terminology. If present, treat it as authoritative for stylistic decisions.

If `pencils_dir` does not exist, create it — but first briefly note to the user what you're doing and why, e.g. *"Creating `<pencils_dir>` to hold pencil drafts (first time penciling in this project, or the directory was renamed in settings)."* This avoids a context-free mkdir prompt.

## Inputs

- One or more jot slugs from the user's invocation (single slug, or comma-separated to consolidate into one pencil). The argument can also be a **fresh subject** that has no jot yet — see step 2 for how that's handled.
- Optional `--html` flag (anywhere in the arguments).
- Files referenced on each jot's `Files:` line.
- The conversation, if the original explainer is still in context.
- The user, for any gaps that the files and conversation can't fill.

## Procedure

### 1. Parse args

- Detect the `--html` flag in the arguments and remove it from the slug list.
- Parse the remaining slug(s) (single, or comma-separated).
- If `--html` was set, verify `template_path` is set in settings and points to a real file. If not, stop and tell the user:

> "I can't pencil this in HTML — `template_path` isn't set (or points to a missing file). Either run `/jotbook-template` (or `/jot template`) to set up the template first, or re-run as `/jot pencil <slug>` (without `--html`) for a Markdown pencil."

This is a lighter-weight version of the same gate the ink skill enforces — a missing template is recoverable here because Markdown is always available as a fallback.

### 2. Resolve inputs

- Locate the jot file(s) under `jots_dir`. For each argument that **matches** an existing jot, use it directly.
- When an argument **doesn't** match any existing jot, decide which case you're in:
  - **Near-miss of an existing jot** (looks like a typo or partial of something already in the backlog) — don't guess. Surface the close match and ask: *"Did you mean `<existing-slug>`, or stage `<arg>` as a new jot?"*
  - **A genuinely new subject, with material to work from** (the topic was just discussed in conversation, or the user clearly intends a fresh entry) — **stage the jot first, then pencil it.** Invoke the staging behavior from `jotbook-stage` (infer the one-line description and `Files:` line from the most recent explainer, or from the subject phrase the user gave), write the pointer file under `jots_dir`, narrate it in one line (`Jotted: <slug>`), then continue this procedure with that freshly-staged jot as the source. Don't pause for confirmation — staging is cheap and the pencil is the thing the user asked for.
  - **A new subject with nothing to draft from** (no conversation context, no files, the topic isn't something you can reconstruct) — stop and ask the user for the material rather than inventing it. A pencil built on a hallucinated premise is worse than no pencil.
- Read each jot's description and `Files:` line.
- Determine the pencil slug:
  - Single jot: same slug as the jot (without the `YYYY-MM-DD-` date prefix).
  - Multiple jots: ask the user for the consolidated slug, defaulting to the first jot's slug.

Check whether `<pencils_dir>/<slug>.md` or `<pencils_dir>/<slug>.html` already exists. If so, ask the user:

> "A pencil for `<slug>` already exists (drafted `<date>`). Overwrite, abort, or revise (apply notes to the existing pencil)?"

If they pick **revise**, jump to the **Revise sub-procedure** at the end of this skill. If **overwrite**, continue normally. If **abort**, stop.

### 3. Gather material

- Read every file listed under `Files:` (across all source jots).
- If the original explainer is in conversation context, anchor on it for the user's voice and framing.
- If gaps remain (motivation, history, design rationale that isn't in code), ask the user a small, targeted set of questions before writing. Don't ship a draft with placeholder framing — even a draft.

### 4. Plan the structure

Before writing, decide and briefly share with the user:

- **Title** — short, descriptive.
- **Standfirst / lede** — one or two sentences setting the scene.
- **Sections** — most pencils land at 3–6. Don't pad.
- **Sub-sections** — when a section has more than ~3 distinct beats.
- **Diagrams** — only when the concept has structure prose alone obscures. For HTML pencils use inline SVG; for Markdown skip diagrams or use a fenced ASCII sketch if it genuinely helps.
- **Callouts** — note / warning blocks for asides and gotchas. Use sparingly.
- **Tables** — for keymaps, parameter lists, mode references.
- **Code blocks** — keep extracts short (≤ ~20 lines).

Tell the user the planned section list before writing the file, so they can redirect early if the shape is off.

**Cross-links into other entries in `entries_dir` are NOT written for pencils.** That side-effect fires at ink time, not now. If a related entry is worth mentioning, do it inline in prose without making a clickable link.

### 5. Render

Determine the output path:

```
<pencils_dir>/<slug>.<ext>
```

Where `<ext>` is `md` (default — even when `output_format: obsidian` or `output_format: html`) or `html` (only when `--html` was passed). The slug has no date prefix.

#### Markdown pencil (default)

Write a Markdown file with pencil frontmatter:

```markdown
---
status: pencil
drafted: YYYY-MM-DD
from_jots:
  - YYYY-MM-DD-source-jot-slug
sources:
  - path/to/file_one.ext
  - path/to/file_two.ext
---

# <Title>

<one or two sentence standfirst>

## <Section 1>

...
```

- `drafted:` is today's date (use `currentDate` from context if available; otherwise the system date).
- `from_jots:` lists each source jot's full filename (with `YYYY-MM-DD-` prefix), one per line.
- `sources:` lists the deduplicated union of every source jot's `Files:` line.

No trailing `*Sources:*` line in the body — that's an ink-time concern. The frontmatter carries the provenance here.

#### HTML pencil (`--html` only)

Read the template at `template_path` and replace any `{{PLACEHOLDER}}` tokens using the planned title, standfirst, sections, etc. Match the template's conventions (numbering schemes, masthead fields, colophon) — do not invent your own. **Never paste CSS inline** if the template links a stylesheet.

Pencil metadata travels in an HTML comment at the very top of the file, so it doesn't render in browsers but survives round-trips:

```html
<!--
status: pencil
drafted: YYYY-MM-DD
from_jots:
  - YYYY-MM-DD-source-jot-slug
sources:
  - path/to/file_one.ext
-->
<!DOCTYPE html>
...
```

### 6. Skip cross-link updates

Do NOT edit any file in `entries_dir`. Cross-link creation is an ink-time side-effect — pencils never write to other entries.

### 7. Skip source-jot deletion

Do NOT delete any file in `jots_dir`. Source jots are preserved until the pencil resolves (via promotion to ink, or explicit drop in `/jot review pencils`).

### 8. Report

Tell the user, in one short paragraph:

- The new pencil's path.
- That the source jot(s) are still in `jots_dir`.
- The next step: `/jot review pencils` when they're ready to evaluate it.

Example:

> Penciled `cache-eviction-policy.md` at `docs/jotbook/_pencils/`. Source jot stayed in place. Run `/jot review pencils` to ink, revise, or drop it.

## Revise sub-procedure

When the user picks **revise** (either because a pencil already exists and they want to apply notes, or because the pencil-review flow handed off here), the procedure is:

1. Read the existing pencil at `<pencils_dir>/<slug>.<ext>`.
2. Apply the user's notes — adjust framing, restructure sections, swap focus, tighten or expand sections, etc.
3. Preserve the original `drafted:` date. Set or update `revised: YYYY-MM-DD` to today.
4. Write the file back at the same path with the same extension. Don't change the format mid-revision; if the user wants a format change, that's a fresh `/jot pencil <slug>` with the opposite flag and an overwrite.

The revise sub-procedure does NOT re-read source files unless the user's notes specifically point to them. Trust the existing pencil as the starting point.

## Hard rules

- **No cross-link side effects.** Don't edit any file in `entries_dir` from this skill.
- **Don't delete source jots.** They stay until the pencil resolves.
- **Default to Markdown.** HTML pencils require explicit `--html`. Do not infer from `output_format`.
- **Don't invent facts.** Ask the user or omit. A pencil is a draft, but it's still a draft of a real entry — don't pad with plausible-sounding fabrications.
- **No marketing language, no AI-isms** ("Let's dive in!", "It's important to note that…"). Match the user's existing voice. If the house-style body specifies tone, follow it.
- **No "Generated by Claude" footers** unless the template already includes one.
- **No emojis** unless house-style explicitly allows them.
- **One pencil per invocation** unless the user explicitly asks for a multi-pencil set.
