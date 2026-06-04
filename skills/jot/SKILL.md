---
name: jot
description: Toolkit dispatcher for `/jot` — routes user slash invocations to the appropriate jotbook skill (stage, review, ink, pencil, init). **User-triggered only; never auto-invoke.** Auto-staging is handled by `jotbook-stage`, not this skill.
---

# /jot

Toolkit dispatcher for granular jotbook actions. This skill runs **only** in response to an explicit `/jot ...` slash command from the user. Never auto-invoke it. (Auto-staging after substantive explainers is the `jotbook-stage` skill's job, not this one.)

Parse the user's invocation text immediately after `/jot`. Treat the first whitespace-separated token as the subcommand and the remainder as its arguments. Route as follows:

- **`review`** → look at the next token:
  - If empty or `jots`, invoke the `jotbook-review` skill.
  - If `pencils`, invoke the `jotbook-pencil-review` skill.
  - Anything else: ask the user to clarify (`jots` or `pencils`).
- **`ink`** → invoke the `jotbook-ink` skill. Pass the rest of the arguments as the jot slug (or comma-separated slugs).
- **`pencil`** → invoke the `jotbook-pencil` skill. Pass the rest of the arguments as the jot slug or subject (single, or comma-separated slugs). The argument need not match an existing jot — `jotbook-pencil` will stage one first when given a fresh subject. Recognize an optional `--html` flag anywhere in the remaining arguments and forward it. If `pencil` is invoked with no argument at all, do NOT default — instead, tell the user the two valid forms (`/jot pencil <slug>` to draft, `/jot review pencils` to review the pencil backlog) and stop.
- **`init`** → invoke the `jotbook-init` skill. The skill writes the starter settings file and handles the `.gitignore` prompt.
- **`template`** → invoke the `jotbook-template` skill. Forward any remaining text as the optional pre-run direction steer (e.g. an existing doc look to harmonize with, or a request for a distinct identity); the skill treats it as a hint, never a gate, and runs the same way with no argument.
- **`stage`** → invoke the `jotbook-stage` skill. Pass the rest of the arguments as the subject phrase.
- **anything else (or empty)** → invoke the `jotbook-stage` skill. Treat the full invocation text as the subject phrase (if empty, the skill infers from recent conversation).

Reserved subcommand words: `review`, `ink`, `pencil`, `init`, `stage`, `template`. If the user wants to stage a jot whose subject starts with one of these words, they should use the explicit `/jot stage <subject>` form.

## Settings

Before invoking any skill, attempt to read `.claude/jotbook.local.md` in the project root. Parse its YAML frontmatter for these fields, using the defaults shown when a field (or the whole file) is missing:

```
jots_dir:           docs/jotbook/_jots/
entries_dir:        docs/jotbook/
pencils_dir:        docs/jotbook/_pencils/
output_format:      markdown            # markdown | obsidian | html
template_path:      (none)
backlog_threshold:  8                   # session-start jot nudge fires at this count
pencils_threshold:  3                   # session-start pencil nudge fires at this count
```

The body of the settings file (if present) is optional house-style guidance the `jotbook-ink` and `jotbook-pencil` skills should respect.

If the settings file does not exist and the user is invoking anything other than `init`, proceed with defaults and mention once — at the end of your reply — that `/jot init` (or `/jotbook-init`) will write a settings file they can edit.

## Hard rules

- **User-triggered only.** Never auto-invoke this skill. For auto-staging behavior, see `jotbook-stage`.
- Do not silently invent slugs or jots that don't exist on disk.
- Do not lecture the user about the workflow at the top of every reply.
