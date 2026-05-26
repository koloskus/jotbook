---
name: jotbook-pencil-review
description: Review the pencil backlog and decide which provisional drafts to ink, drop, revise, edit, or keep.
---

# Review the pencil backlog

The user is reviewing the pencils (provisional long-form drafts) to decide which are worth promoting to inked entries, which need a revise pass, and which should be dropped. Your job is to **surface and recommend** — never delete, promote, or regenerate unilaterally. Every action needs explicit confirmation.

## Resolve configuration

Read `.claude/jotbook.local.md` if present. From its frontmatter, extract:

| field | default | meaning |
|---|---|---|
| `pencils_dir` | `docs/jotbook/_pencils/` | where pencils live |
| `jots_dir` | `docs/jotbook/_jots/` | needed to verify source-jot existence |

If `pencils_dir` doesn't exist or contains no pencils, report that in one line and stop.

## Procedure

### 1. Inventory

List every `*.md` and `*.html` file under `pencils_dir` (excluding any `README.md`). For each:

- Read the metadata block — YAML frontmatter for `.md` pencils, the top HTML comment for `.html` pencils. Extract:
  - `status` (should be `pencil` — flag anything else as suspicious)
  - `drafted:` date
  - `revised:` date (if present)
  - `from_jots:` list
- Compute age as today − (most recent of `revised`, `drafted`).
- Check that each entry in `from_jots:` still resolves to a real file in `jots_dir`. Note any missing source jots — the pencil can still be promoted, but its source-jot cleanup will be partial.
- Record the format (`md` or `html`).

Sort by age, oldest first.

### 2. Present

Output a compact, scannable summary. Don't over-format — the user is making decisions from this view.

Suggested shape:

```
Pencils (N total):

  ▸ 2026-05-12  cache-eviction-policy        (10d)  md
    From jots: 2026-05-02-cache-eviction-policy

  ▸ 2026-05-15  feature-flag-system          (7d)   html
    From jots: 2026-05-04-flag-rollout, 2026-05-05-flag-telemetry
    Revised:   2026-05-18

  ▸ 2026-05-18  webhook-retry-semantics      (4d)   md
    From jots: 2026-05-10-webhook-retry-semantics  [MISSING]

Recommendations:
  • cache-eviction-policy: ready to ink — concrete, sources still present,
    no revise history.
  • feature-flag-system: ink or keep — recent revise suggests it's settled.
  • webhook-retry-semantics: source jot is gone; still promotable but
    flag this to the user before inking.
```

Lead with the inventory; put your recommendations at the end. Keep the whole thing scannable — short lines, no walls of prose.

### 3. Solicit decisions

Ask the user in plain language. Don't present a numbered menu — let them respond free-form. Mention all five available actions so the surface is visible:

> Decisions? You can say things like "ink cache-eviction-policy", "drop feature-flag-system", "revise feature-flag-system — focus on rollout only", "edit webhook-retry-semantics" (no regen, just give me the path), or "keep everything for now".

### 4. Apply

For each decided action:

- **Ink `<slug>`** — hand off to `jotbook-ink` with the slug. The ink skill detects the pencil's existence and runs its **Promotion path** (skipping gather/plan/render, swapping pencil frontmatter for entry-appropriate frontmatter per `output_format`, writing to `entries_dir`, updating cross-links into related entries, deleting the pencil + source jot(s)). Confirm with the user before running if you noticed missing source jots in the inventory.

- **Drop `<slug>`** — delete the pencil file. Before deleting, ask one question:

  > "Drop pencil `<slug>`. Source jot(s) (`<list>`) can stay (default) so you can redraft later, or be deleted alongside the pencil. Which?"

  Default to keeping source jots. If the user explicitly says delete-all, also remove the source jots.

- **Revise `<slug>` — `<notes>`** — invoke `jotbook-pencil` with the slug and pass the user's notes to its revise sub-procedure. The pencil skill applies the notes to the existing pencil in place and bumps `revised:` to today. If the user said `revise` without notes, ask once for the notes before proceeding.

- **Edit `<slug>`** — no-op. Surface the file path so the user can hand-edit it. Mention they can re-run `/jot review pencils` once they're done.

- **Keep** — no-op for now.

After applying, give a one-line summary:

```
Inked N, dropped M, revised R, edited E, kept K. Source jots deleted: <list>.
```

Omit the "Source jots deleted" tail if no source jots were deleted.

## What NOT to do

- Don't promote, drop, or regenerate without explicit confirmation.
- Don't read source files referenced by `sources:` during review — the pencil body is enough to evaluate. Save deep reading for the user (or for ink time).
- Don't propose drafting new pencils — that's `/jot pencil <slug>`. This skill only acts on existing pencils.
- Don't proceed if `pencils_dir` is empty — report and stop.
- Don't silently invoke `jotbook-ink` or `jotbook-pencil` for an action the user hasn't explicitly marked.
