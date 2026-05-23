---
name: jotbook-review
description: Review the staged jot backlog and decide what to keep, drop, merge, tweak, pencil, or ink into a full entry. Use periodically when the backlog has accumulated. Surfaces overlap between jots, proposes consolidations before they're inked, and flags jots that already have a pencil in progress. Invoked by `/jotbook-review` (or `/jot review`), or as the first phase of `/jotbook-ink` (the no-args curation flow).
---

# Review the jot backlog

The user is reviewing the jot list to decide which subjects still feel worth inking into a long-form entry — or worth penciling first as a provisional draft before committing. Your job is to **surface and recommend**, not to delete or merge unilaterally. Every destructive action needs explicit confirmation.

## Resolve configuration

Read `.claude/jotbook.local.md` if present. From its frontmatter, extract:

| field | default | meaning |
|---|---|---|
| `jots_dir` | `docs/jotbook/_jots/` | where staged jots live |
| `pencils_dir` | `docs/jotbook/_pencils/` | where pencils live — checked to flag jots that already have one |

If `jots_dir` doesn't exist or contains no jots, report that in one line and stop.

## Procedure

### 1. Inventory

List every `*.md` file under `jots_dir` (excluding any `README.md`). For each, read the file and extract:

- Slug (filename without `YYYY-MM-DD-` prefix and `.md` suffix)
- `staged:` date
- Age in days (today − staged date)
- Description line
- Files line (if present)
- **Pencil status**: check whether `<pencils_dir>/<slug>.md` or `<pencils_dir>/<slug>.html` exists. If so, note "has pencil from `<drafted-date>`" (and "revised `<date>`" if the pencil's frontmatter has a `revised:` field).

Sort by age, oldest first.

### 2. Detect overlap

Group jots that look topically related. Signals:

- Overlapping file references on the `Files:` line
- Shared keywords or domain terms in descriptions
- Same subsystem or topic cluster

Note these as **suggested merges**, not forced ones.

### 3. Present

Output a compact, scannable summary. Don't over-format — the user will be making decisions from this view. Suggested shape:

```
Jots (N total):

  ▸ 2026-05-12  cache-eviction-policy      (10d)  [has pencil from 2026-05-18]
    How the LRU cache evicts on hot keys.
    Files: src/cache/lru.ts, src/cache/metrics.ts

  ▸ 2026-05-15  feature-flag-rollout       (7d)
    How the gradual rollout schedule advances cohorts.

  ▸ 2026-05-15  feature-flag-telemetry     (7d)
    How flag-evaluation events flow to analytics.

Suggested consolidations:
  • feature-flag-rollout + feature-flag-telemetry → both touch the flag
    subsystem and could share an entry; consider merging into
    "feature-flag-system".

Recommendations:
  • cache-eviction-policy: pencil already exists — consider running
    `/jot review pencils` to evaluate it instead of re-deciding from
    the jot alone.
  • feature-flag-system (merged): plausible candidate for pencil if
    you want to see the long-form before committing.
  • drop none unless the user has lost interest in any.
```

When a jot has a pencil, prefer recommending the user review the pencil (which has more material to judge from) rather than re-deciding from the jot alone.

Lead with the inventory; put your recommendations at the end. Keep the whole thing scannable — short lines, no walls of prose.

### 4. Solicit decisions

Ask the user, in plain language, what to do. Don't present a numbered menu — let them respond in free form. Mention all six available actions in the prompt so the user knows the surface. Example:

> Decisions? You can say things like "drop the feature-flag pair", "merge X and Y into Z", "tweak cache-eviction to focus on hot keys", "ink cache-eviction-policy", "pencil feature-flag-system" (draft first, decide later), or "keep everything for now".

### 5. Apply

For each decided action:

- **Keep** — no-op.
- **Drop <slug>** — delete the jot file. If more than one is being dropped, list what you're about to delete first and confirm.
- **Merge <slug-a> + <slug-b> → <new-slug>** — create a new jot file combining the descriptions (still one or two lines total); union the `Files:` lines; delete the merged-in originals. Date the merged jot today.
- **Tweak <slug> — <new framing>** — the inferred subject was close but the framing needs a nudge. Edit the jot's description line in place to reflect the user's directive. Optionally update the `Files:` line if the new framing implicates different sources. This stays lightweight — apply the change in one pass, do not enter a back-and-forth discussion. If the directive is genuinely ambiguous, ask exactly one clarifying question, then apply and move on.
- **Ink <slug>** — leave the jot file in place. If you are running as part of the bare `/jotbook-ink` flow, hand off to `jotbook-ink` on that slug. If you are running as a standalone `/jot review`, tell the user the next step is `/jot ink <slug>` and stop — do not invoke `jotbook-ink` yourself in that mode.
- **Pencil <slug>** (optionally with `--html`) — leave the jot file in place. If you are running as part of the bare `/jotbook-ink` flow, hand off to `jotbook-pencil` on that slug, forwarding the `--html` flag if the user specified it. If you are running as a standalone `/jot review`, tell the user the next step is `/jot pencil <slug>` (or `/jot pencil <slug> --html`) and stop — do not invoke `jotbook-pencil` yourself in that mode.

After applying, give a one-line summary: `Dropped N, merged M into K, tweaked T, kept P, ready to ink: <list>, ready to pencil: <list>`. Omit the trailing fields when their lists are empty.

## What NOT to do

- Don't expand jot files into paragraphs during review — they stay lightweight until inked or penciled.
- Don't auto-drop "old" jots just because they're old. Age is information, not a verdict.
- Don't propose creating a new jot that wasn't already staged. Use `jotbook-stage` for that.
- Don't read every referenced source file during review — the jot text is enough to make keep/drop decisions. Save deep reading for `jotbook-ink` or `jotbook-pencil`.
- Don't invoke `jotbook-pencil` (or `jotbook-ink`) without explicit user marking — same rule as ink.
- Don't quietly re-decide for a jot that already has a pencil. Point the user at `/jot review pencils` so they can judge from the long form.
