---
name: jotbook-stage
description: Stage a recently-discussed concept as a lightweight jot. Use immediately after explaining something the user might want to revisit later. Writes a small pointer file under the configured jots directory — does not write the full entry. Invoked by `/jot [subject]` or by the plugin's auto-stage hook.
---

# Stage a jot

You just gave (or were asked about) an explainer the user wants to revisit later. Write a **lightweight** pointer file (a "jot") so the topic can be picked up during a future review pass. Do not write the full entry — that's `jotbook-bind`'s job.

## Resolve the jots directory and mode

Read `.claude/jotbook.local.md` if present. From its frontmatter, extract:

- `jots_dir` — default `docs/jotbook/_candidates/` if missing
- `auto_stage_mode` — default `prompt` if missing

If the jots directory does not exist, create it.

The `auto_stage_mode` value changes how interactive you should be (see **Auto mode** below).

## What to write

A single Markdown file at:

```
<jots_dir>/YYYY-MM-DD-short-kebab-slug.md
```

- `YYYY-MM-DD` = today's date (use the `currentDate` from context if available, otherwise the system date).
- `short-kebab-slug` = 2–5 words capturing the concept, lowercased, hyphenated.

File contents:

```markdown
---
staged: YYYY-MM-DD
---
One-line description of what was explained — past tense, plain prose.

Files: path/to/file_one.ext, path/to/file_two.ext
```

The `Files:` line is **optional**. Include it only when the explainer leaned heavily on specific source files (e.g., "how does this manager work" → yes; "what does eventual consistency mean in general" → no).

## Hard limits

- **One line of description.** Not two. Not a paragraph. If you feel the urge to write more, you're trying to do `jotbook-bind`'s job — stop.
- **No background, no rationale, no code excerpts.** A jot is a *pointer*. The full explanation lives in chat history or will be reconstructed at bind time.
- **No headings beyond the frontmatter.**

The point of a tiny jot is that some won't survive review, and you should be able to drop one without regret.

## Procedure

1. Identify the subject:
   - If the user passed an argument, use that as the subject phrase.
   - Otherwise, infer from the most recent explainer in the conversation. If there isn't a clear recent explainer, ask the user what they want jotted rather than guessing. (In auto mode, see below — skip silently instead of asking.)
2. Derive the slug (kebab-case, ≤ 5 words).
3. Check the jots directory for an existing jot with a similar slug or covering the same concept. If one exists, ask the user whether to **append** to it (add a line to the description), **supersede** it (replace with today's framing), or **create a new** one alongside. (In auto mode, see below — default to creating a new one silently.)
4. Write the file using the absolute path.
5. Report back in one sentence: the slug, and a one-line confirmation. Do not lecture about the workflow.

## Auto mode

When `auto_stage_mode: auto` is set in the settings file, you are running unattended via the Stop hook and the goal is to capture without slowing the user down. In this mode:

- **Step 1**: If you can't infer a clear subject, abort silently (no jot, no message). Don't ask.
- **Step 3**: If a similar jot exists, default to creating a **new sibling** entry. Don't prompt. The user will sort it out at review time.
- **Step 5**: Compress the confirmation to a single line: `(jotted: <slug>)`. Nothing else.

In `prompt` mode the user has opted in to being asked, so the original procedure applies. In `off` mode this skill should not be invoked by a hook at all — it can still be invoked explicitly via `/jot`, in which case behave as `prompt`.

## What NOT to do

- Don't propose to bind the jot into a full entry immediately. That's a separate explicit step.
- Don't add tags, status fields, priority, or other metadata beyond `staged:`.
- Don't ask the user to "review" the staged jot — it's already supposed to be lightweight enough that review is unnecessary.
- Don't stage trivial Q&A ("what's the syntax for X"). If you wouldn't expect future-you to benefit from a long-form entry on it, don't stage it.
