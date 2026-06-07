---
name: jotbook-link
description: Cross-link sweep over the inked jotbook. Walks the entries in entries_dir, surfaces pairs of topically related entries that aren't yet linked, and — on your confirmation — adds small format-appropriate links between them. Use it to connect older entries to ones inked after them. User-triggered only; never auto-invoke.
---

# Cross-link the jotbook

Inking links forward at write time (`jotbook-ink` step 6 connects a new entry to obviously-related existing ones), but it can't see the future: an entry inked last week never gains a link to one inked today. This skill is the deliberate, re-runnable pass that fixes that — it re-examines the whole inked collection and proposes the cross-links that are missing, so the jotbook stays connected as it grows.

It only ever **adds links** between entries that already exist. It never invents entries, never rewrites prose, and never edits a previously-inked entry without your confirmation.

**User-triggered only.** Run it on an explicit `/jotbook-link` (or `/jot link`); never auto-invoke it.

## Resolve configuration

Read `.claude/jotbook.local.md` if present. From the frontmatter, extract:

| field | default | meaning |
|---|---|---|
| `jots_dir` | `docs/jotbook/_jots/` | where staged jots live (optional secondary candidates) |
| `entries_dir` | `docs/jotbook/` | where inked entries live — the sweep's primary scope |
| `output_format` | `markdown` | one of `markdown`, `obsidian`, `html` — determines link syntax |

The **body** of the settings file (after the closing `---`) is house-style guidance — if it says anything about cross-linking (e.g. "prefer wikilinks over relative paths", "cross-link liberally"), honor it.

If the plugin hasn't been initialized (no `.claude/jotbook.local.md`), proceed with defaults and mention once that `/jot init` writes a settings file.

## Inputs

- An optional focus slug from the invocation (`/jotbook-link <slug>` scopes the sweep to one entry's connections; with no argument, the sweep covers the whole collection).
- The inked entries under `entries_dir`.
- The user, who confirms before any entry is edited.

## Procedure

### 1. Inventory the entries

Glob `entries_dir` for entry files (`*.md` for `markdown`/`obsidian`, `*.html` for `html`). **Exclude** the index file (`index.md`/`index.html`) and anything under the `_jots`/`_pencils`/`_assets`/`_templates` subdirectories.

If a focus slug was given, confirm it resolves to a real entry; if it doesn't, list what's there and ask — don't guess. If the collection has fewer than two entries, there's nothing to link — say so and stop.

### 2. Find missing-link candidates

For each entry (or, in focus mode, between the focus entry and every other), read enough to judge relatedness, then look for pairs that are topically related but **not yet linked in either direction**. Signals of relatedness:

- **Shared tags** (Obsidian `tags:` frontmatter, or HTML tag chips).
- **Shared referenced files** (the `*Sources:*` footer / `sources:` frontmatter — two entries documenting the same code are usually worth connecting).
- **Title / subject overlap** — same component, feature, or concept.
- **Body mentions** — one entry names a concept that another entry is *about* (a strong candidate for an inline link at the mention).

Skip pairs that are already linked (in either direction). Rank candidates by strength of relationship; cap the surfaced set at a manageable number (≈8) so the user isn't flooded — say if you truncated.

(Optional, lower priority: a jot in `jots_dir` whose subject clearly matches an existing entry can be surfaced too, but jots are lightweight pointers — prefer linking entries to entries.)

### 3. Present candidates and confirm

List the proposed links concisely — for each: the two entries, why they're related, and where the link would go (e.g. "inline at the `eviction` mention in the body" vs. "a See-also line at the foot"). Let the user pick which to apply (all / a subset / none). Default to proposing **bidirectional** links where both sides genuinely benefit, but a one-directional link is fine when only one side has a natural anchor.

**Do not edit anything before the user confirms.**

### 4. Apply the chosen links

For each approved link, make the smallest edit that reads naturally, in the format's idiom:

- **Markdown**: relative link `[Title](slug.md)` — inline at a mention, or under a trailing `## See also` / `*Related:*` line.
- **Obsidian**: `[[slug|Title]]` wikilink (or `[[slug]]` when the title equals the slug).
- **HTML**: an `<a href="slug.html">Title</a>` anchor, placed in the body or a related/see-also block consistent with the template's conventions.

Prefer an inline link at an existing mention over a tacked-on list when the prose already references the other entry. Don't duplicate a link that's already present.

### 5. Report

Tell the user which entries you edited and the links added. Note that **the index does not need rebuilding** — adding cross-links changes neither entry titles nor the set of entries, so `index.<ext>` (owned by `jotbook-ink`) is unaffected. Only mention re-running `/jotbook-ink` if a title actually changed (it won't from this skill).

## Hard rules

- **User-triggered only; never auto-invoke.** This skill edits previously-inked entries — it runs only on an explicit `/jotbook-link` (or `/jot link`).
- **Confirm before every edit.** Never modify a previously-inked entry without the user's explicit go-ahead (mirrors `jotbook-ink`'s rule for editing existing entries).
- **Only add links — never rewrite content.** No restructuring, no re-toning, no deletions. The edit is a link and the minimal surrounding text to make it read.
- **Never invent entries or slugs.** Link only between entries that exist on disk.
- **Don't duplicate existing links.** Skip any pair already connected in either direction.
- **Match the configured format's link syntax** — relative `.md` links, `[[wikilinks]]`, or `<a>` anchors per `output_format`, honoring any house-style preference.
