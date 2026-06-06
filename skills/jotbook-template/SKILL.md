---
name: jotbook-template
description: Design a templated-HTML output for this jotbook — a full judge-panel workflow or a streamlined quick path, recommended from the project's visual richness — that produces a stylesheet, tokenized template, preview, and token-conventions doc, verifies them mechanically, and wires output_format/template_path on your sign-off. User-triggered only; never auto-invoke.
---

# Design a jotbook HTML template

The `html` output mode needs a real template before it works. The two gates differ, and this skill is the deliberate, named artifact both point at:

- `jotbook-ink` hard-stops when `output_format: html` is set but `template_path` is empty or points at a missing file.
- `jotbook-pencil` hard-stops when `--html` is passed but `template_path` is empty or missing — independent of `output_format`.

This skill produces a stylesheet, a tokenized template, a populated preview, and token-conventions documentation tailored to *this* project, verifies them mechanically, and — only after you sign off — wires the settings so the HTML path is armed.

It offers **two design paths**, recommended from the project's visual richness (step 1) but always the user's choice:

- **Full panel** — the judge-panel workflow below. Worth it when the project has a real visual language and tone to harmonize with, so distinct directions can actually separate.
- **Quick path** — a single opinionated design pass (or a baseline preset). Right for greenfield/utilitarian projects, or when the user just wants a clean, blog-like template without the exercise.

**The fork lives only in the design phase.** Both paths build the same fixed sample, write the same four artifacts, run the same mechanical verification, and hit the same sign-off gate. Quick is not lower-rigor output — it just skips exploring a design space that may have no room to be explored.

**User-triggered only.** This skill mutates config and (on the full path) runs a heavy multi-agent design panel; never auto-invoke it. It runs only in response to an explicit `/jotbook-template` (or `/jot template`) invocation.

The full panel's shape is the whole point, so when you take it, preserve its intent, not just its steps:

- **A fixed sample entry, held constant across all concepts**, so designs are compared on craft, not copy.
- **Distinct, hard-committed directions** beat one hedged attempt.
- **An adversarial multi-lens judge panel** catches failure modes a single reviewer averages away.
- **Synthesis grafts strengths** from across the panel rather than shipping one concept whole.
- **Post-hoc mechanical verification** turns a subjective design into something pass/fail before it touches config.

## Resolve configuration

Read `.claude/jotbook.local.md` if present. From the frontmatter, extract:

| field | default | meaning |
|---|---|---|
| `jots_dir` | `docs/jotbook/_jots/` | where staged jots live (mined for the fixed sample) |
| `pencils_dir` | `docs/jotbook/_pencils/` | where pencils live (also mined for the fixed sample) |
| `entries_dir` | `docs/jotbook/` | where inked entries are written; the assets/templates dirs and the template's relative CSS link are derived from this |
| `output_format` | `markdown` | the field this skill flips to `html` on sign-off |
| `template_path` | (none) | the field this skill points at the new template on sign-off |

The **body** of the settings file (everything after the closing `---`) is optional house-style guidance — voice, tone, conventions, terminology. If present, treat it as authoritative for stylistic decisions, and feed it verbatim into the design context so every concept matches the project's voice.

Derive these from `entries_dir`/`pencils_dir` (do not hardcode):
- **assets dirs** — `<entries_dir>/_assets/` AND `<pencils_dir>/_assets/` (where `jotbook.css` is written — see below for why both).
- **templates dir** — `<entries_dir>/_templates/` (where `jotbook.html` and `jotbook-preview.html` are written).
- **the template's CSS link** — a RELATIVE href that must resolve from where each rendered file actually lives. This is the subtle part, and there are TWO consumers at DIFFERENT depths:
  - `jotbook-ink` writes the finished entry into `entries_dir` (e.g. `docs/jotbook/<slug>.html`);
  - `jotbook-pencil --html` renders the SAME template into `pencils_dir` (e.g. `docs/jotbook/_pencils/<slug>.html`) — one directory deeper by default.

  A single relative href cannot resolve from both depths, and a sheet written only under `<entries_dir>/_assets/` leaves every HTML pencil unstyled (`_assets/jotbook.css` from `_pencils/<slug>.html` points at the nonexistent `_pencils/_assets/jotbook.css`). The fix keeps the link uniform — always `_assets/jotbook.css`, resolved from the rendered file's OWN location, NOT from the template file's deeper `_templates/` location — and writes a copy of the (identical) sheet into each consumer's `_assets/` dir so that href resolves from both. Worked example: entry at `docs/jotbook/<slug>.html` ⇒ `docs/jotbook/_assets/jotbook.css`; pencil at `docs/jotbook/_pencils/<slug>.html` ⇒ `docs/jotbook/_pencils/_assets/jotbook.css`; both reachable via the same `_assets/jotbook.css` href. (The field-manual doc system fell into exactly this trap — its CSS link did not resolve from the jotbook dir.)
- **`template_path` value to write on sign-off** — a project-relative path (matching how `jotbook-init` writes it and how `jotbook-ink`/`jotbook-pencil` consume it), e.g. `docs/jotbook/_templates/jotbook.html`.

## Inputs

- The current project, for visual-context discovery (existing CSS/templates, brand sources, the house-style body).
- The jot/pencil backlog, for reconstructing the fixed sample from real content.
- Optional pre-run steer from the user (an existing doc look to harmonize with, a request for a distinct identity, or "let the panel explore"). This is a steer, never a gate.
- Optional path intent — a `--quick` or `--full` flag, or plain-language intent in the steer ("just something simple/blog-like" → quick; "make it expressive / give me options" → full). When present, intent overrides the richness recommendation in either direction.
- The user, for the one mandatory sign-off before any config change.

## Procedure

### 1. Discover the project's visual language

Before generating anything, run a fixed discovery sweep and assemble a CONTEXT block passed to every agent. The skill must NOT bake in any one project's palette/fonts — discover them.

1. **Existing stylesheets/templates.** Glob the repo for `*.css`, `*.html` templates, and design-token files (`tokens.json`, `theme.*`, `tailwind.config.*`, `:root{}` blocks, SCSS `$vars`). If a doc/site system already exists, read it for palette, type stack, spacing rhythm, and motifs — but treat it as a **harmony reference and sibling document class, never a thing to clone.** Record any masthead/numbering conventions that do NOT transfer (e.g. a "System No."/"Issue" masthead the jotbook has no equivalent for), and whether its relative CSS link would resolve from `entries_dir`.
2. **Brand/identity sources.** Read `README.md`, `CLAUDE.md`, `package.json` (name/description), logo/favicon assets, and any `BRAND*`/`STYLE*`/`DESIGN*` docs. Extract the project domain, tone words, and any existing color/font vocabulary.
3. **House style.** The body of `.claude/jotbook.local.md` is authoritative for voice/tone/terminology — feed it verbatim to the agents.
4. **Synthesize a HARMONIZE-OR-DIVERGE brief.** A small extracted palette (hex list), a type stack (noting whether the faces are Google-Fonts-available or already self-hosted), spacing/rhythm notes, and motif candidates. The rule for agents: the result must feel like it belongs to THIS project and never a generic framework/AI default, but the jotbook is a more personal, intimate document class than any public docs it sits beside.
5. **Greenfield fallback.** If no visual context exists at all, fall back to a neutral-but-opinionated editorial baseline — a restrained warm-paper-or-cool-slate palette chosen from the project domain, a tasteful Google-Fonts serif+mono pairing — and instruct agents to establish identity from the project's DOMAIN rather than inventing arbitrary branding. Record that no house palette was found so the synthesis doc can flag the chosen palette as net-new.
6. **Read the richness signal (for the path recommendation).** Discovery already surfaces everything this needs — don't run a second pass; just read what 1–5 found. The full panel only produces meaningful signal when there's enough divergence space for distinct directions to separate; on a bare project the four archetypes collapse toward the same baseline and the panel mostly burns effort to rediscover it. Count these "leans-full" signals:
   - a design-token file or theme config is present (`tokens.json`, `tailwind.config.*`, a real `:root{}` palette, SCSS `$vars`);
   - ≥2 distinct stylesheets, or a sibling doc/site system to harmonize-or-diverge against (the field-manual case);
   - a tone/voice/lore source exists — `BRAND*`/`STYLE*`/worldbuilding/design docs, or a populated house-style body in `.claude/jotbook.local.md`;
   - the project domain is expressive (game, creative tool, narrative product) rather than utilitarian (infra, library, CLI);
   - ≥1 content-rich real jot/pencil exists to reconstruct the fixed sample from.

   Form a recommendation, not a verdict: **greenfield fallback fired (no visual context at all) → recommend quick; ≥3 leans-full signals → recommend full; otherwise → no strong lean, surface what was found and let the user pick.** Record the lean and the one-line evidence for step 3. This is only a recommendation — explicit path intent (step 3) overrides it in either direction.

### 2. Build the fixed sample entry (the experiment's control)

Produce ONE content-complete sample, frozen as a string, passed identically to every design agent, into the judge context, and into the synthesis preview. Do not let agents invent different content.

**Prefer reconstruct-from-real-jot.** Scan `jots_dir`/`pencils_dir` for the richest existing jot or pencil — one whose `Files:` reference real code and whose description has structural beats (problem → mechanism → params → gotcha). Reconstruct a full entry from it: read the referenced files for a genuine short code block, real parameter names for the table, and a real sibling entry slug for the cross-link. This makes the preview immediately legible to the user as THEIR content.

**Fallback generic-but-full (non-code, greenfield, or thin backlog).** If no jot is rich enough, the jotbook is empty, the project is non-code, or jots reference no readable files, synthesize a domain-flavored but self-contained sample from the discovered project domain. The sample generator must NEVER require reading real files when none exist. For a non-code domain, adapt the domain-specific elements:
- the **code block** becomes a representative monospace block appropriate to the domain — a config snippet, a shell command, or a short quoted excerpt;
- the **parameter table** becomes any small 3-row table (key/value or term/definition);
- the **cross-link** target is explicitly an intentional placeholder slug (`<another-slug>.html`) — state in a comment that this href is intentionally dangling in the sample/preview and is fine, since no sibling entry exists yet.

Either way the sample MUST stress every supported element so concepts compare fairly and nothing renders untested: title; a 1-2 sentence standfirst/lede; created date (`YYYY-MM-DD`); 3-6 topic tags (chips); slug; a STATUS rendered in the INKED state (with an HTML comment describing how the PENCIL state differs); 3-6 body sections, at least one with an h3 sub-section; a NOTE callout and a WARN callout; one short code/monospace block (≤ ~20 lines, terminal/source styled); a small table (header + ~3 rows); one inline SVG diagram + a `<p class="caption">`; an inline `<code>` span; an inline cross-link to another entry (`<slug>.html`); and a trailing Sources footer.

### 3. Choose the path (quick vs full), and optionally take a steer

Resolve which design path to run BEFORE generating anything. Order of precedence: **explicit intent → richness recommendation → default toward quick.**

1. **Explicit intent wins.** If the invocation carried a `--quick` or `--full` flag, or plain-language intent ("just something simple/blog-like" → quick; "make it expressive / give me options" → full), honor it and skip the question. Intent overrides the step-1 recommendation in either direction (e.g. a rich game repo whose owner just wants a plain blog look → quick).
2. **Otherwise, recommend from the richness signal and ask once.** Surface the step-1 lean with its one-line evidence and let the user pick — e.g. "I found a design-token file and a tone doc, so the **full panel** will pay off here (≈9 design/judge passes). Or I can run the **quick path** — one clean pass, same verification and sign-off. Which would you like?" When there's no strong lean, present both evenly. Keep it to one lightweight question; don't lecture.
3. **When unanswered, fall back to the recommendation, else quick.** Explicit intent is already resolved in step 3.1, so it never reaches here. If the user declines to choose or doesn't respond: when the step-1 richness signal recommended **full** (≥3 leans-full signals), honor that; otherwise default to **quick** — the cheap, safe option, since upgrading is a trivial re-run (the artifacts are inert and just get overwritten) whereas a needless panel is the expensive spend.

If the chosen path is **full**, you MAY also take a direction steer here ("share an existing doc look / give the jotbook a distinct identity / let the panel explore freely"); if declined, let the panel explore the full default direction set. The quick path takes the same steer as a single hint. Never block on any of this.

### 4. Run the chosen design path

Two paths produce the synthesis output that step 5 writes. Both consume the same CONTEXT (step 1) and the same fixed SAMPLE (step 2), and both hand off to the identical steps 5–8. Run the one chosen in step 3.

#### 4-QUICK. Quick path — one opinionated pass

Skip the panel entirely. Produce the four artifacts in a single design pass tailored to the discovered (or baseline) palette/type/motifs:

- **Pick the look.** Use the discovered visual language if step 1 found one; otherwise fall back to the SAME neutral-but-opinionated editorial baseline defined in step 1.5 (Greenfield fallback) — a restrained warm-paper-or-cool-slate palette chosen from the project domain, a tasteful Google-Fonts serif+mono pairing. State which you used. A clean, legible, blog-like dev notebook is the target — distinctive enough to not read as a generic AI default, but no in-world theming, marginalia, or console atmosphere.
- **Generate once.** Either inline, or as a single subagent if a Task/subagent tool exists — render the fixed SAMPLE in the INKED state and produce the same synthesis output shape as the full path: `css`, `templateHtml`, `previewHtml`, `tokenConventions` (the `SYNTH_SCHEMA` in the appendix). The CSS must carry the full structural class set and the `.leaf.inked` / `.leaf.pencil` pure-class-swap treatment exactly as the full path requires — the quick path simplifies the *exploration*, not the *output contract*.
- **No directions, no judges, no synthesis-from-panel.** There is nothing to tally; go straight to step 5.

Then continue to step 5 (write), 6 (verify), 7 (sign-off), 8 (wire) unchanged. State in the final report that the quick path was taken and which look was used.

#### 4-FULL. Full panel — Design → Judge → Synthesize

The workflow is **Design → Judge → Synthesize**, described below as a procedure you execute in this conversation. There are two execution modes; pick based on a concrete capability check.

**Detect the execution mode first.** If a Task/subagent dispatch tool is available, take the parallel path. If it is not, take the sequential fallback. Either way you run the *same* three phases against the *same* fixed SAMPLE and CONTEXT — only the dispatch differs.

The schemas and exact prompts for each phase are spelled out in the **Workflow script (reference appendix)** at the end of this skill; read it to build the prompts. (It is illustrative pseudocode for a workflow harness — NOT a file this skill executes. If you happen to be running inside a real workflow-orchestration harness that provides `parallel()`/`agent()`/`phase()` primitives, it is also runnable as-is as an accelerator.)

**PARALLEL PATH — dispatch subagents (when a Task/subagent tool exists).**

- **Design — 4 parallel subagents.** Each gets the CONTEXT block, the fixed SAMPLE, ONE direction brief, and the design output shape (`conceptName`, `designRationale`, `selfContainedHtml`). Each commits HARD to its DISTINCT direction. The default archetype set, tailored to the discovered palette/type/motifs:
  1. **Engineer's bound notebook** — faint graph/grid substrate, a stitched/taped binding margin, monospace-forward metadata, restrained serif body. Tactile, calm, technical. (Most domain-neutral; safe default.)
  2. **Archive/catalog card** — accession-card styling, prominent date and tag chips, ruled card lines, crisp filing hierarchy, a quiet catalog-code motif. Orderly, indexed, clinical.
  3. **In-world/domain-voiced journal** — the literary option, voiced from the project's domain (naturalist's field journal for a game, lab logbook for a science tool, ops runbook for infra, studio sketchbook for a creative app). Characterful display face, marginalia energy, captions as dry observations. If the domain is unknown, fall back to a generic "working lab notebook" voice rather than inventing lore.
  4. **Console/log terminal** — darker console-styled header, a timestamped log line, signal/mono headers, atmospheric — body stays HIGHLY readable. The most distinct-from-paper option.

  Each renders the SAME fixed sample in the INKED state as one self-contained HTML document (inline CSS), with an HTML comment near the status element describing how PENCIL differs. Fold the discovered palette/type/motifs into the chosen archetype so all four feel like the same project seen four ways. Collect each returned HTML.
- **Judge — 4 parallel subagents.** Each gets the CONTEXT, all four concepts, and ONE lens; scores ALL concepts 1-10, names a per-lens winner, lists grafts from the non-winners. Framing is explicitly adversarial (a quality gate, not encouragement). The lenses:
  1. **Genre fitness for a personal dev notebook** — surfaces metadata cleanly; distinguishes pencil vs inked; scales short→long; handles every content type; reads calmly.
  2. **Typographic & visual craft** — typography, hierarchy, spacing, rhythm, color discipline, distinctiveness. Penalize generic/AI-default looks.
  3. **Project coherence** — belongs to THIS project's discovered visual language WITHOUT cloning a sibling document class; tasteful, never costume. When no house style exists, judges domain-appropriateness and internal consistency instead.
  4. **Technical soundness & tokenisability** — valid semantic HTML; accessible contrast; responsive at 1280px and mobile; `prefers-color-scheme` handling; clean CSS with `:root` tokens and reusable classes; obvious `{{TOKEN}}` seams; variable section/callout/table counts handled; renders without JS.

  Tally scores across the panel; the cross-panel leader seeds synthesis.
- **Synthesize — 1 subagent (or do it inline).** Bases the final on the panel leader, grafting the specific strengths judges flagged. Emits exactly the four artifacts in step 5.

**SEQUENTIAL FALLBACK — single-conversation emulation (when no subagent tool exists).** This is the path most invocations take. Preserve the structure; manage context aggressively:

- **Design.** Draft the directions one at a time against the fixed sample. After each, **write its HTML to a scratch file** under `<templates dir>/_concepts/<key>.html` rather than holding all four inline in the conversation. Cap each concept at a reasonable byte budget (a focused page, not a sprawl). If context is tight, you MAY drop from 4 directions to 3 — keep `bound-notebook`, `catalog`, and `console`; drop `domain-journal` first.
- **Judge.** Run an honest, adversarial scoring pass across the four lenses, **reading the concept files one at a time** rather than all at once. Score each concept 1-10 per lens, tally, name lens winners and grafts.
- **Synthesize.** Read the leading concept file (plus the specific grafted bits from the others) and produce the four artifacts.

State which path was taken in the final report.

### 5. Write the artifacts (inert until config points at them)

Write the synthesis output to disk, all paths derived from settings:

1. **External stylesheet** → `<entries_dir>/_assets/jotbook.css` — `:root` color/type tokens; structural classes for header/masthead, section + h3 sub-section, `.note`/`.warn` callouts, terminal-styled `pre/code` + inline `<code>`, tables, `.caption`, cross-link anchors, tag chips, the pencil-vs-inked status treatment, sources footer; a `prefers-color-scheme` dark variant; a responsive breakpoint; robust fallback font stacks. The pencil-vs-inked treatment MUST be a pure class swap on an outer wrapper (e.g. `.leaf.inked` vs `.leaf.pencil`) with ALL pencil behaviour (graphite ink, a pencil-glyph stamp, a faint DRAFT watermark) defined under the `.pencil` selector. **Then write a byte-identical copy to `<pencils_dir>/_assets/jotbook.css`** (skip if `pencils_dir` resolves to the same directory as `entries_dir`) so the template's `_assets/jotbook.css` href resolves from HTML pencils too — splice the same bytes, don't re-emit the sheet.
2. **Tokenized template** → `<entries_dir>/_templates/jotbook.html` — LINKS the external sheet via the derived relative `<link rel="stylesheet" href="_assets/jotbook.css">`, uses `{{TOKENS}}` for all variable content, ZERO inline CSS, with guiding HTML comments (repeatable section pattern, delete-if-unused callout/table/diagram blocks, exactly how pencil-vs-inked status is set via the outer class + label tokens).
3. **Self-contained preview** → `<entries_dir>/_templates/jotbook-preview.html` — **build it by construction, not by retyping CSS.** Take the populated sample HTML (the synthesis preview body, or the template with the fixed sample substituted and the `<link>` removed), then Read `jotbook.css` and splice its exact bytes into a single `<style>` block in the `<head>`. This guarantees the preview's inline styles are byte-identical to the sheet rather than depending on a model reproducing a long stylesheet twice.
4. **Token-conventions markdown** — keep it for the sign-off step (append to the house-style body on approval). May also be written beside the template for reference.

These artifacts are inert: nothing reads them until `template_path` points at the template, so writing-then-holding is safe.

### 6. Verify mechanically (before the sign-off gate)

Run these checks and report each result. They turn a subjective design into something pass/fail.

1. **Byte-identical preview vs CSS.** Extract the inline `<style>` block from the preview and assert it is byte-for-byte identical to `jotbook.css`. Because step 5 built the preview by splicing the css bytes, this passes by construction. If a divergence is ever detected, **regenerate the preview from the css file** (re-splice) rather than re-prompting synthesis — never ask the model to retype the sheet.
2. **Zero inline styles in the TEMPLATE, and the sheet resolves from BOTH consumers.** Assert the template contains NO `<style>` block and no `style="..."` attributes (the SVG diagram is the one allowed exception if it needs geometry attrs, but presentational CSS lives in the sheet), AND that it links the external sheet with the derived relative href. Then assert `<entries_dir>/_assets/jotbook.css` exists, and — unless `pencils_dir` is the same directory — that `<pencils_dir>/_assets/jotbook.css` also exists and is byte-identical, so the template's `_assets/jotbook.css` href resolves from an inked entry in `entries_dir` AND from an HTML pencil in `pencils_dir`. A missing pencil-dir copy means every HTML pencil renders unstyled.
3. **Token presence & pattern repeatability.** Assert a healthy count of well-named `{{TOKENS}}` covering title/standfirst/date/tags/slug/status/sections/sources, and that the section, callout, table, and figure patterns are repeatable (delete-if-unused comment examples present) so variable counts work.
4. **Tag balance / well-formedness.** Sanity-check that open/close tag counts balance and the doc parses without error.
5. **Headless render (best-effort, NOT a gate).** Probe for a renderer fast and without hanging. Probe each candidate SEPARATELY and stop at the first hit — `command -v` with multiple names exits non-zero unless *all* resolve, so it can't be used to detect "any one present." Try, each with a short timeout: `command -v google-chrome || command -v chromium || command -v chromium-browser || command -v chrome` (Linux/PATH), the macOS path `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`, then `command -v wkhtmltoimage`. If one is found, render the preview to PNG with `--headless=new --no-sandbox --virtual-time-budget=4000` (let any fade-in settle), a tall `--window-size`, then crop, under an overall render timeout (~20s). If nothing is found, or the render fails/times out, immediately skip and tell the user to open the self-contained preview HTML in their own browser. The render is purely confirmatory and never on the critical path.
6. **Pencil-state render proof.** Produce the pencil variant by flipping the single outer class (`leaf inked` → `leaf pencil`) plus the coordinated status-label tokens, and confirm the CSS already defines all `.pencil` behaviour so pencil is a pure class swap, not a separate template. Render it too if a browser is available.

### 7. Sign-off gate (the one hard stop)

Present the preview to the user — the screenshot if rendered, the path to the self-contained preview HTML, the pencil-state proof, and the verification results — then HOLD. Do NOT touch `.claude/jotbook.local.md` until the user explicitly approves.

When you ask for approval, also surface the scope choice, because `template_path` and `output_format` arm different things: **setting `template_path` alone** makes the template available to `/jot pencil <slug> --html` (the pencil gate is independent of `output_format`); **also setting `output_format: html`** additionally makes every plain `/jotbook-ink` render through the template. Offer both — e.g. "Make HTML the default for all inked entries (`output_format: html`), or just enable the template for `--html` pencils and keep `output_format` as `<current>`?" Default to the narrower option (template only) if the user doesn't care, since it's non-destructive to their current ink format.

### 8. Wire config (only after approval)

On approval, in `.claude/jotbook.local.md`:
- set `template_path` to the project-relative template path (e.g. `docs/jotbook/_templates/jotbook.html`) — always;
- set `output_format: html` **only if the user chose to make HTML the default for all inked entries** (the scope choice above); if they opted for template-only, leave `output_format` untouched so their existing markdown/obsidian inks are unaffected and only `--html` pencils render through the template;
- **append** the token-conventions to the house-style body as LIVE markdown — under a clear heading like `## HTML template tokens`, placed BELOW any existing house-style content and OUTSIDE (after) the starter HTML comment block that `jotbook-init` writes (the `<!-- ... -->` block whose first line reads `House style (optional).`, closed by `-->`). Do NOT write the conventions inside that comment (where ink/pencil would treat them as inert and never see them), and do NOT delete or overwrite existing body prose. If only the starter comment exists, add the live section after its closing `-->`.

This is what arms the HTML path in `jotbook-ink`/`jotbook-pencil`. Until it's done, those flows correctly hard-stop (ink on `output_format: html` + empty `template_path`; pencil on `--html` + empty `template_path`). Report the wired settings; if `output_format` was set to `html`, remind the user that `/jotbook-ink` now renders through the template; if they kept the narrower scope, remind them that `/jot pencil <slug> --html` renders through the template while plain `/jotbook-ink` still uses their existing `output_format`.

## Hard rules

- **Never flip settings without explicit sign-off.** Writing the artifacts to disk is safe (they're inert); changing `output_format`/`template_path` is the one action that arms the HTML gate for every future ink and pencil. Mirror `jotbook-init`'s "don't auto-chain" discipline.
- **User-triggered only; never auto-invoke.** This skill mutates config and (on the full path) runs a heavy panel — it runs only on an explicit `/jotbook-template` (or `/jot template`).
- **The quick/full fork is the design phase only.** Both paths build the same fixed sample, emit the same four artifacts under the same output contract (including the `.leaf.inked`/`.leaf.pencil` class swap), run the same step-6 verification, and hit the same step-7 sign-off gate. Quick simplifies exploration, never output rigor or safety.
- **Recommend the path from richness; never force it.** Default toward quick when intent is absent and there's no strong lean — upgrading quick→full is a cheap re-run, while a needless panel is the expensive spend. Explicit user intent always wins.
- **The template links an external sheet — never inline CSS.** The produced template is judged against `jotbook-ink`'s rule: "Don't paste CSS inline in HTML output when the template already links a stylesheet." The only presentational exception is geometry attributes on the SVG diagram.
- **Hold the fixed sample constant across all concepts.** Same text, same structure, in every design agent, the judge context, and the preview. Designs are compared on craft, not copy.
- **Discover the project's visual language; don't bake one in.** No hardcoded palette/fonts/domain. Harmonize with existing brand/docs where they exist, but never clone a sibling document class, and never resolve to a generic framework/AI default.
- **Derive all paths from settings.** assets dirs, templates dir, and the template's relative CSS link all come from `entries_dir`/`pencils_dir` — never hardcode `docs/jotbook/...`. The CSS href resolves from each RENDERED FILE's own location (an inked entry in `entries_dir`, an HTML pencil in `pencils_dir`), not the template file's `_templates/` location — which is why the sheet is written into both consumers' `_assets/` dirs.
- **Don't invent facts in the sample.** When reconstructing from a real jot, read the referenced files for genuine code/params/cross-links. Don't fabricate parameter names or sibling slugs. When no real files exist, use the domain-appropriate fallback and an explicitly-dangling placeholder cross-link.
- **The preview must tell the truth.** Build it by splicing the css bytes so its inline `<style>` is byte-identical to the external CSS, or it doesn't represent production fidelity.
- **A missing browser never blocks sign-off.** The screenshot is a nicety; the self-contained preview is the fallback deliverable.
- **Append, don't replace, the house style.** The token-conventions are appended as live markdown below existing body content, outside the starter comment, preserving any existing guidance.

## Workflow script (reference appendix)

The following JS is the Design → Judge → Synthesize workflow expressed for a workflow-orchestration harness. **It is illustrative — a non-normative reference for the phase prompts and output schemas, NOT a file this skill executes.** A bare in-session skill has no `parallel()`/`agent()`/`phase()` runtime; follow the procedure in step 4 instead, using this as the source of the exact prompts and schemas. (If you ARE running inside a harness that provides these primitives, the script is runnable as-is: the caller assembles `globalThis.JOTBOOK_CONTEXT` from discovery (step 1) and `globalThis.JOTBOOK_SAMPLE` from the fixed sample (step 2); it is project-agnostic and bakes in no palette, fonts, or domain.)

```js
export const meta = {
  name: 'jotbook-template-design',
  description: 'Design a new HTML template + stylesheet for a jotbook by judging distinct concepts against a fixed sample, then synthesizing the winner with grafts. Project-agnostic: the caller passes in a discovered CONTEXT block and a fixed SAMPLE.',
  phases: [
    { title: 'Design', detail: '4 distinct template concepts render the same fixed sample entry' },
    { title: 'Judge', detail: 'panel scores all concepts across 4 lenses' },
    { title: 'Synthesize', detail: 'merge winner + best grafts into final css/template/preview/token-doc' },
  ],
}

// INPUTS provided by the caller (NOT hardcoded): globalThis.JOTBOOK_CONTEXT
// (discovery block) and globalThis.JOTBOOK_SAMPLE (the fixed, content-complete
// sample, frozen as a string). Optional globalThis.JOTBOOK_DIRECTIONS overrides
// the default archetype set. The SAMPLE is held constant across every concept.

const CONTEXT = globalThis.JOTBOOK_CONTEXT
const SAMPLE = globalThis.JOTBOOK_SAMPLE

if (!CONTEXT || !SAMPLE) {
  throw new Error('jotbook-template-design: JOTBOOK_CONTEXT and JOTBOOK_SAMPLE must be provided by the calling skill (discovery + fixed sample).')
}

const DEFAULT_DIRECTIONS = [
  { key: 'bound-notebook', brief: "DIRECTION — Engineer's bound notebook. A faint graph/grid-paper substrate, a stitched or taped binding margin down one side, monospace-forward metadata (a date stamp, tag labels set like margin annotations), a restrained serif body that reads as if written into a real ruled notebook. Tactile, calm, technical. The most domain-neutral, safe-default direction. Pencil-vs-inked could differ by graphite-grey vs ink-blue rendering." },
  { key: 'catalog-archive', brief: 'DIRECTION — Library/archive catalog card. The entry reads like a card pulled from a drawer: accession/catalog styling, prominent date and tag chips, ruled card lines, crisp archival typographic hierarchy, a quiet filing-code motif. Orderly, indexed, pleasingly clinical. Pencil-vs-inked could differ by a "PROVISIONAL" rubber-stamp vs a clean filed card.' },
  { key: 'domain-journal', brief: "DIRECTION — In-world / domain-voiced journal. The literary option, voiced from THIS project's domain as given in the context: a naturalist's field journal for a game world, a lab logbook for a science tool, an ops runbook for infra, a studio sketchbook for a creative app. A characterful display face, marginalia energy, captions written as dry observations. If the project domain is unknown, fall back to a generic 'working lab notebook' voice rather than inventing lore. Restrained, never costume." },
  { key: 'console-log', brief: 'DIRECTION — Console / log terminal. A darker console-styled header with a timestamped log line and a signal/mono motif, monospace headers, atmospheric. The body must remain HIGHLY readable (do not sacrifice legibility for theme). The most distinct-from-paper option; ties to any event-stream / CLI / telemetry flavour in the project. Pencil-vs-inked could differ by a "DRAFT / UNFILED" header state.' },
]

const ANGLES = (globalThis.JOTBOOK_DIRECTIONS && globalThis.JOTBOOK_DIRECTIONS.length)
  ? globalThis.JOTBOOK_DIRECTIONS
  : DEFAULT_DIRECTIONS

const DESIGN_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['conceptName', 'designRationale', 'selfContainedHtml'],
  properties: {
    conceptName: { type: 'string', description: 'Short evocative name for this concept' },
    designRationale: { type: 'string', description: '2-4 sentences: the core design idea and how it serves a personal, re-readable dev notebook' },
    selfContainedHtml: { type: 'string', description: 'Complete self-contained HTML5 document, all CSS inline in one <style> block, rendering the fixed sample entry in the INKED state, with an HTML comment near the status element describing how PENCIL differs' },
  },
}

const JUDGE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['lens', 'scores', 'winner', 'graftSuggestions'],
  properties: {
    lens: { type: 'string' },
    scores: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['conceptName', 'score', 'notes'],
        properties: {
          conceptName: { type: 'string' },
          score: { type: 'number', description: 'integer 1-10 on this lens' },
          notes: { type: 'string', description: 'concise, specific rationale' },
        },
      },
    },
    winner: { type: 'string', description: 'conceptName that best serves this lens' },
    graftSuggestions: { type: 'string', description: 'specific elements from non-winning concepts worth grafting into the final synthesis' },
  },
}

const SYNTH_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['chosenDirection', 'css', 'templateHtml', 'previewHtml', 'tokenConventions'],
  properties: {
    chosenDirection: { type: 'string', description: 'Which concept won, why, and what specifically was grafted from the others' },
    css: { type: 'string', description: 'Final external stylesheet (jotbook.css) — :root tokens, header/masthead, section + h3 sub-section, .note/.warn callouts, terminal pre/code + inline <code>, tables, .caption, cross-link anchors, tag chips, the pencil-vs-inked status treatment, sources footer, prefers-color-scheme dark variant, responsive breakpoint, robust fallback font stacks' },
    templateHtml: { type: 'string', description: 'Final tokenized template (jotbook.html): links the external sheet via a RELATIVE <link rel="stylesheet" href="_assets/jotbook.css">, uses {{TOKENS}} for all variable content, ZERO inline CSS, with guiding HTML comments (repeatable section pattern, delete-if-unused callout/table/diagram blocks, exactly how pencil-vs-inked status is set via the outer class + label tokens)' },
    previewHtml: { type: 'string', description: 'Self-contained preview (jotbook-preview.html): inline <style> BYTE-IDENTICAL to css, populated with the fixed sample entry in the INKED state, openable directly. NOTE: the calling skill rebuilds this by splicing the css bytes, so exact reproduction here is a best-effort starting point, not the source of truth.' },
    tokenConventions: { type: 'string', description: 'Markdown documenting every {{TOKEN}} and exactly how jotbook-ink/pencil fills each (including the pencil-vs-inked status value), suitable to append to the house-style body of .claude/jotbook.local.md' },
  },
}

// --- Design ----------------------------------------------------------------
phase('Design')
const concepts = (await parallel(ANGLES.map(a => () =>
  agent(
    CONTEXT +
    '\n\n=== YOUR ASSIGNED DESIGN DIRECTION ===\n' + a.brief +
    '\n\n=== TASK ===\nProduce ONE complete self-contained HTML document for your direction, all CSS inline in one <style> block, rendering the fixed sample entry above EXACTLY (same text, same structure — do not invent different content), in the INKED state. Exercise every content type the sample calls for (sections, the h3 sub-section, note + warn callouts, the code block, the table, the inline SVG + caption, the inline cross-link, the Sources footer) and surface all metadata (title, standfirst, date, tags, slug, status). In an HTML comment near the status element, describe how the PENCIL/draft state would differ visually. Fold the discovered project palette/type/motifs into your direction so it feels like THIS project, never a generic framework/AI default. Commit HARD to your direction — distinctive and production-grade beats a hedged blend. Return the full document in selfContainedHtml.',
    { label: 'design:' + a.key, phase: 'Design', schema: DESIGN_SCHEMA }
  )
))).filter(Boolean)

log(concepts.length + ' concepts rendered: ' + concepts.map(c => c.conceptName).join(', '))

// --- Judge -----------------------------------------------------------------
phase('Judge')
const conceptsBlock = concepts.map((c, i) =>
  '### Concept ' + (i + 1) + ': ' + c.conceptName + '\nRationale: ' + c.designRationale + '\n\nHTML:\n<<<HTML\n' + c.selfContainedHtml + '\nHTML'
).join('\n\n---\n\n')

const LENSES = [
  { key: 'genre-fit', name: 'Genre fitness for a personal dev notebook', brief: 'Does it serve working lab notes meant to be re-read weeks later? Surfaces metadata (date, tags, slug, sources) cleanly; clearly distinguishes pencil vs inked; scales gracefully from a short jot to a long entry; handles every content type without strain; reads calmly, not like marketing.' },
  { key: 'craft', name: 'Typographic & visual craft', brief: 'Quality of typography, hierarchy, spacing, rhythm, colour discipline, distinctiveness. Penalize generic framework/AI-default looks, weak hierarchy, cramped or noisy layouts, theme-over-legibility.' },
  { key: 'project-coherence', name: 'Project coherence', brief: "Does it feel like it belongs to THIS project's visual language as described in the context (harmonizing with any existing brand/docs) WITHOUT cloning a sibling document class? Tasteful and restrained, never kitsch or costume; clearly a distinct-but-related personal document class. If no house style exists, judge domain-appropriateness and internal consistency instead." },
  { key: 'technical', name: 'Technical soundness & tokenisability', brief: 'Valid semantic HTML; accessible contrast; responsive at 1280px and on mobile; prefers-color-scheme handling; clean, well-organized CSS with :root tokens and reusable structural classes; obvious where {{TOKENS}} would go; variable section/callout/table count handled cleanly; renders without JS; robust font fallback stacks so it holds offline.' },
]

const judgments = (await parallel(LENSES.map(l => () =>
  agent(
    'You are judging jotbook HTML template concepts on ONE lens. Be specific and critical — this is an adversarial quality gate, not encouragement.\n\nLENS: ' + l.name + '\n' + l.brief +
    '\n\nScore EVERY concept 1-10 on this lens with concise specific notes, name the single best concept for this lens, and call out specific elements from the non-winners worth grafting into a final synthesis.\n\n' + CONTEXT + '\n\n=== CONCEPTS TO JUDGE ===\n' + conceptsBlock,
    { label: 'judge:' + l.key, phase: 'Judge', schema: JUDGE_SCHEMA }
  )
))).filter(Boolean)

const tally = {}
for (const j of judgments) for (const s of j.scores) tally[s.conceptName] = (tally[s.conceptName] || 0) + s.score
log('Lens winners: ' + judgments.map(j => j.lens.split(' ')[0] + '->' + j.winner).join(' | '))
log('Score totals: ' + Object.entries(tally).map(e => e[0] + '=' + e[1]).join(', '))

// --- Synthesize ------------------------------------------------------------
phase('Synthesize')
const judgeBlock = judgments.map(j =>
  '## Lens: ' + j.lens + '\nWinner: ' + j.winner + '\nScores: ' + j.scores.map(s => s.conceptName + '=' + s.score + ' (' + s.notes + ')').join('; ') + '\nGraft: ' + j.graftSuggestions
).join('\n\n')

const final = await agent(
  'You are producing the FINAL jotbook template, synthesizing from a judged design panel.\n\n' + CONTEXT +
  '\n\n=== ALL CONCEPTS ===\n' + conceptsBlock +
  '\n\n=== JUDGE PANEL ===\n' + judgeBlock +
  '\n\n=== SYNTHESIS TASK ===\nBase the final on the concept that scored best across the panel, grafting the specific strengths judges flagged from the others. Produce four artifacts:\n' +
  '(1) css — a clean, well-organized external stylesheet (jotbook.css). Use :root colour/type tokens (with robust fallback font stacks) and clear structural classes for: header/masthead, section + sub-section (h3), .note and .warn callouts, pre/code (terminal-styled) and inline <code>, tables, .caption for diagrams, inline cross-link anchors, tag chips, the pencil-vs-inked status treatment, and the sources footer. Include a prefers-color-scheme dark variant and a responsive breakpoint. Comment the sheet lightly. The pencil-vs-inked treatment MUST be a pure class swap on an outer wrapper (e.g. .leaf.inked vs .leaf.pencil), so flipping ONE class plus a few coordinated label tokens produces the pencil state — define ALL pencil behaviour (graphite ink, a pencil-glyph stamp, a faint DRAFT watermark, etc.) under the .pencil selector.\n' +
  '(2) templateHtml — the skeleton (jotbook.html). It MUST link the external sheet via a RELATIVE <link rel="stylesheet" href="_assets/jotbook.css"> (do NOT inline CSS here). Use {{TOKENS}} for every variable piece (title, standfirst, date, tags, slug, status, sections, sources). Include guiding HTML comments showing the repeatable section pattern, how to add/remove callouts/tables/SVG diagrams (delete-if-unused), and exactly how the PENCIL vs INKED status is set (the outer class + the coordinated label tokens).\n' +
  '(3) previewHtml — a fully self-contained document whose inline <style> is BYTE-IDENTICAL to the css artifact, populated with the fixed sample entry (INKED state), so the user can open it and see production fidelity. (The calling skill will rebuild this by splicing the css bytes; emit your best-effort copy regardless.)\n' +
  '(4) tokenConventions — markdown listing every {{TOKEN}} and precisely how jotbook-ink/pencil should fill it (including the pencil-vs-inked status value and the outer-class swap), ready to APPEND to the house-style body of .claude/jotbook.local.md.\n' +
  'Make the final cohesive and production-grade — not a mechanical merge.',
  { label: 'synthesize', phase: 'Synthesize', schema: SYNTH_SCHEMA }
)

return {
  chosenDirection: final.chosenDirection,
  css: final.css,
  templateHtml: final.templateHtml,
  previewHtml: final.previewHtml,
  tokenConventions: final.tokenConventions,
  conceptNames: concepts.map(c => c.conceptName),
  tally,
}
```
