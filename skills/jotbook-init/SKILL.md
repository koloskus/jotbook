---
name: jotbook-init
description: Initialize a jotbook in the current project — writes a starter `.claude/jotbook.local.md` settings file, scaffolds the directory structure, and optionally amends `.gitignore`.
---

# Initialize a jotbook

You're setting up a new jotbook in this project. The procedure writes a starter settings file, offers to handle `.gitignore`, and tells the user about the restart caveat for hook-affecting fields.

## Starter settings

Write the following YAML frontmatter at the top of `.claude/jotbook.local.md`, followed by a short commented body that the user can replace with their own house-style guidance:

```markdown
---
jots_dir:           docs/jotbook/_jots/
entries_dir:        docs/jotbook/
pencils_dir:        docs/jotbook/_pencils/
output_format:      markdown            # markdown | obsidian | html
template_path:                          # required only when output_format is html, or when penciling with --html
backlog_threshold:  8                   # session-start jot nudge fires at this count
pencils_threshold:  3                   # session-start pencil nudge fires at this count
---

<!--
House style (optional). Whatever you write below the closing --- above
is treated by jotbook-ink and jotbook-pencil as authoritative guidance
on voice, tone, terminology, and formatting conventions.

Example:

  Field-manual voice — restrained, precise, deadpan. No exclamation points.
  Cross-link liberally; prefer wikilinks over relative paths.
  Code excerpts capped at ~20 lines; longer extracts go in a sibling block.
-->
```

Leave the `template_path` field empty by default. The user fills it in only when they want HTML output.

## Procedure

1. **Check existing settings.** If `.claude/jotbook.local.md` already exists, ask the user before overwriting:

   > "A `.claude/jotbook.local.md` already exists. Overwrite with fresh defaults (your existing settings will be lost), or leave it alone?"

   Default to leaving it alone. If they pick leave-alone, skip to step 4 (gitignore check is still worth doing in case they need it).

2. **Create `.claude/`** if it doesn't already exist.

3. **Write the starter settings file** at `.claude/jotbook.local.md` using the template above.

4. **Scaffold the jotbook directory structure.** Create the three default directories so that later auto-staging or manual `/jot` invocations don't have to surface a surprise mkdir prompt days later:

   ```bash
   mkdir -p docs/jotbook/_jots docs/jotbook/_pencils docs/jotbook
   ```

   Use the resolved values from the settings file you just wrote (in case the user customizes paths before re-running, though by default they'll be the three above). Skip this step if the user chose "leave alone" in step 1 — their existing settings might point elsewhere and we shouldn't scaffold defaults that don't match.

5. **Handle the gitignore** — only if this is a git repo. The settings file should be project-local and not committed.

   Before any gitignore work, run a **quiet** git-repo probe that doesn't emit scary stderr when the directory isn't a repo:

   ```bash
   git rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo yes || echo no
   ```

   Then branch:

   - **Probe returns `no` (not a git repo)** → skip the entire gitignore step. In one short line, tell the user something like: *"This isn't a git repo, so no `.gitignore` step. If you later put this directory under git, add `.claude/*.local.md` to your `.gitignore` so settings don't get committed."* Move on to step 5.

   - **Probe returns `yes` (is a git repo)** → check `.gitignore` existence with `[ -f .gitignore ]` (do NOT `cat` it blindly — `cat` on a missing file produces noisy stderr). Then:
     - **`.gitignore` exists** → read it and check whether the settings file is already covered (look for `.claude/*.local.md`, `.claude/*`, or an explicit `.claude/jotbook.local.md` line). If not covered, ask once: *"Add `.claude/*.local.md` to your `.gitignore`?"* and append if they confirm.
     - **`.gitignore` does not exist** → ask: *"Create a `.gitignore` with `.claude/*.local.md`?"* and create if they confirm.

   If the user declines either prompt, mention in one line that the settings file should not be committed and move on.

6. **Mention the restart caveat.** Hook-affecting fields (`backlog_threshold`, `pencils_threshold`) take effect on the next Claude Code restart. Other fields (`jots_dir`, `entries_dir`, `pencils_dir`, `output_format`, `template_path`) are picked up immediately.

7. **Report next steps** in two or three lines:
   - Confirm what was written and which directories were scaffolded.
   - Point at `/jot` for staging an explainer after a relevant turn.
   - Point at `/jotbook-ink` for the curation flow once the backlog has grown.
   - Mention that inking builds a navigable `index.md` landing page in `entries_dir` and a back-to-index link on each entry, and that `/jotbook-link` (or `/jot link`) re-links related entries across the collection.
   - Mention `.claude/jotbook.local.md` is the place to edit defaults.
   - If they want HTML output later: `/jotbook-template` runs a guided design workflow and, on their sign-off, wires `template_path` for them.

## Hard rules

- **Never overwrite an existing settings file** without explicit confirmation.
- **Never amend `.gitignore`** without explicit confirmation.
- **Probe quietly.** Never `cat` `.gitignore` or run git commands without first checking that the file/repo exists. Both can produce big red stderr output that looks like a real error to a user who isn't paying close attention. Use `[ -f .gitignore ]` for file existence and `git rev-parse --is-inside-work-tree >/dev/null 2>&1` for repo existence. Combine multiple discovery probes into a single bash call only if every command in the chain is silent on its failure path.
- **Don't proceed if writing the settings file fails** — surface the error path and stop, so the user can fix permissions or path issues.
- **Don't auto-chain** into other flows after init. The user should explicitly choose `/jot` or `/jotbook-ink` after setup completes.
