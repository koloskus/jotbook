---
description: Guided jotbook curation flow — review the staged backlog, then ink the survivors. The primary entry point.
---

# /jotbook

Guided curation flow. Bundles **review** and **ink** into a single pass for clearing the backlog.

If args are passed to `/jotbook`, ignore them and gently point the user at `/jot` for granular actions (e.g., "for individual actions, use `/jot`, `/jot review`, `/jot ink <slug>`"). Then proceed with the flow below.

## Settings

Before doing anything else, attempt to read `.claude/jotbook.local.md` in the project root. Parse its YAML frontmatter for these fields, using the defaults shown when a field (or the whole file) is missing:

```
jots_dir: docs/jotbook/_candidates/
entries_dir:    docs/jotbook/
output_format:  markdown               # markdown | obsidian | html
template_path:  (none)
auto_stage_mode: prompt                # off | prompt | auto
backlog_threshold: 8                   # session-start nudge fires at this count
```

The body of the settings file (if present) is optional house-style guidance the `jotbook-ink` skill should respect.

If the settings file does not exist, proceed with defaults and mention once — at the end of your reply — that `/jot init` will write a settings file they can edit.

## Procedure

1. Invoke the `jotbook-review` skill to inventory jots and surface suggested merges/drops.
2. Let the user respond with their decisions (drop / merge / tweak / ink / keep).
3. Apply the structural decisions (drops, merges, tweaks) via `jotbook-review`.
4. For each jot the user marked as ready to **ink**, invoke the `jotbook-ink` skill on that slug. If they marked several, ask whether to do them one-by-one with checkpoints, or batch through them.
5. End with a one-line summary of what was dropped, merged, tweaked, and inked.

If the backlog is empty, say so in one line and stop — do not proceed to the ink step.

## Hard rules

- Do not silently invent slugs or jots that don't exist on disk.
- Do not call `jotbook-ink` without the user explicitly marking a jot as ready.
- Do not lecture the user about the workflow at the top of every reply. The flow is plumbing — get on with the work.
