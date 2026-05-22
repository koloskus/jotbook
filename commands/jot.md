---
description: Toolkit for individual jots — stage (default), review, bind, or init.
argument-hint: "[subject] | review | bind <slug> | init"
---

# /jot

Toolkit dispatcher for granular jotbook actions. Read `$1` and route:

- **`review`** → invoke the `jotbook-review` skill. No further arguments.
- **`bind`** → invoke the `jotbook-bind` skill. Pass the rest of the arguments as the jot slug (or comma-separated slugs).
- **`init`** → run the **Init** flow below.
- **`stage`** → invoke the `jotbook-stage` skill. Pass the rest of the arguments as the subject phrase.
- **anything else (or empty)** → invoke the `jotbook-stage` skill. Treat `$ARGUMENTS` as the subject phrase (if empty, the skill infers from recent conversation).

Reserved subcommand words: `review`, `bind`, `init`, `stage`. If the user wants to stage a jot whose subject starts with one of these words, they should use the explicit `/jot stage <subject>` form.

## Settings

Before invoking any skill, attempt to read `.claude/jotbook.local.md` in the project root. Parse its YAML frontmatter for these fields, using the defaults shown when a field (or the whole file) is missing:

```
jots_dir: docs/jotbook/_candidates/
entries_dir:    docs/jotbook/
output_format:  markdown               # markdown | obsidian | html
template_path:  (none)
auto_stage_mode: prompt                # off | prompt | auto
backlog_threshold: 8                   # session-start nudge fires at this count
```

The body of the settings file (if present) is optional house-style guidance the `jotbook-bind` skill should respect.

If the settings file does not exist and the user is invoking anything other than `init`, proceed with defaults and mention once — at the end of your reply — that `/jot init` will write a settings file they can edit.

## Init

When `$1` is `init`:

1. Check whether `.claude/jotbook.local.md` already exists. If it does, ask the user before overwriting.
2. Create `.claude/` if it doesn't exist.
3. Write a starter settings file with the default values shown in the **Settings** section above. Include a brief commented body explaining each field.
4. Handle the gitignore:
   - If `.gitignore` exists at the project root, check whether the settings file is already covered (look for `.claude/*.local.md`, `.claude/*`, or an explicit `.claude/jotbook.local.md` line). If not covered, ask the user once: *"Add `.claude/*.local.md` to your .gitignore?"* and append if they confirm.
   - If `.gitignore` does not exist, ask: *"Create a .gitignore with `.claude/*.local.md`?"* and create if they confirm.
   - If they decline either prompt, mention in one line that the settings file should not be committed and move on.
5. Mention that hook changes (auto-stage mode, threshold) take effect on next Claude Code restart.

## Hard rules

- Do not silently invent slugs or jots that don't exist on disk.
- Do not lecture the user about the workflow at the top of every reply.
