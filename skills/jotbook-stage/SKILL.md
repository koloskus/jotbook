---
name: jotbook-stage
description: Stage a recently-discussed concept as a lightweight jot. **Auto-invoke at the end of any turn where you've delivered a substantive multi-paragraph explanation of a domain concept (system, mechanism, code) that the user might want to revisit later — don't ask first, just stage it and report.** Writes a small pointer file under the configured jots directory; does not write the full entry. Also invocable explicitly via `/jotbook-stage [subject]` or `/jot [subject]`.
---

# Stage a jot

You just gave (or were asked about) an explainer the user wants to revisit later. Write a **lightweight** pointer file (a "jot") so the topic can be picked up during a future review pass. Do not write the full entry — that's `jotbook-ink`'s job.

## When to auto-invoke

Auto-invoke this skill at the end of any turn that delivered a substantive multi-paragraph explanation of a domain concept — a system, mechanism, piece of code, or design rationale that the user might plausibly want to revisit as a long-form note later. Don't ask first. Just stage and report.

Do NOT auto-invoke for:
- Short answers, status updates, error messages
- Code edits with minimal narration
- Routine tool use or clarifications
- Output from any jotbook skill (curation summaries, "the jot backlog is empty", `(jotted: X)`, etc.)
- Trivial Q&A ("what's the syntax for X")
- Anything you wouldn't expect future-you to benefit from a long-form entry on

When in doubt, skip — the user can always invoke `/jot [subject]` explicitly.

## Resolve the jots directory

Read `.claude/jotbook.local.md` if present. From its frontmatter, extract:

- `jots_dir` — default `docs/jotbook/_jots/` if missing

If the jots directory does not exist, create it. **Before running `mkdir`, briefly note to the user what you're doing and why** — something like *"Creating `<jots_dir>` to hold staged jots (first time staging in this project, or the directory was renamed in settings)."* This avoids a context-free permission prompt that could confuse a user who set up jotbook days earlier and forgot.

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

- **One line of description.** Not two. Not a paragraph. If you feel the urge to write more, you're trying to do `jotbook-ink`'s or `jotbook-pencil`'s job — stop.
- **No background, no rationale, no code excerpts.** A jot is a *pointer*. The full explanation lives in chat history or will be reconstructed at ink (or pencil) time.
- **No headings beyond the frontmatter.**

The point of a tiny jot is that some won't survive review, and you should be able to drop one without regret.

## Procedure

1. Identify the subject:
   - If the user passed an argument, use that as the subject phrase.
   - Otherwise (auto-invocation or no-arg `/jot`), infer from the most recent explainer in the conversation. If there isn't a clear recent explainer, ask the user what they want jotted rather than guessing.
2. Derive the slug (kebab-case, ≤ 5 words).
3. Check the jots directory for an existing jot with a similar slug or covering the same concept. If one exists, ask the user whether to **append** to it (add a line to the description), **supersede** it (replace with today's framing), or **create a new** one alongside.
4. Write the file using the absolute path.
5. Report back in one short line: the slug and a brief confirmation. Don't lecture about the workflow. For auto-invocations, keep it especially terse — something like `Jotted: <slug>` is plenty.

## What NOT to do

- Don't propose to ink or pencil the jot into a full entry immediately. That's a separate explicit step.
- Don't add tags, status fields, priority, or other metadata beyond `staged:`.
- Don't ask the user to "review" the staged jot — it's already supposed to be lightweight enough that review is unnecessary.
- Don't stage trivial Q&A ("what's the syntax for X"). If you wouldn't expect future-you to benefit from a long-form entry on it, don't stage it.
