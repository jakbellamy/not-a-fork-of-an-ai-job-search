# /typeset - Render a Text Draft as a Professional PDF

You are converting the candidate's own text draft (Markdown, plain text, or Word) into a professionally typeset LaTeX PDF. This is a **formatting operation, not a writing operation**: the content of the output must match the draft word for word. If something about the content should change, that's `/critique`'s job, not yours.

`$ARGUMENTS` may contain: a draft file path or @-mention, a company/role name, `--template <name>`, `--all`, or nothing.

Follow these steps **in order**.

---

## Step 0: Get the Draft and Determine Type

1. **Locate the draft.** In priority order:
   - A file path/@-mention in `$ARGUMENTS` (`.md`, `.txt`, `.docx` — convert `.docx` as described in `/critique` Step 0)
   - A company/role in `$ARGUMENTS` → look for `documents/applications/<company>_<role>/drafts/cv.md` and/or `cover_letter.md`; if both exist, ask which (or both)
   - Pasted text in the conversation → save it into the application folder's `drafts/` first (create the folder per `/critique` Step 1)
   - Nothing → ask
2. **Document type:** CV or cover letter — infer, ask if ambiguous. This decides template, engine, and page limit.
3. **Company/role:** needed for output filenames. If the draft is general (no target job), use a slug the user confirms (e.g. `general`).

---

## Step 1: Choose the Template

1. Read the guidance file for the document type: `.claude/skills/job-application-assistant/05-cv-templates.md` (CV) or `06-cover-letter-templates.md` (cover letter).
2. Resolve the template:
   - `--template <name>` → use `templates/<type>/<name>/` (read its `TEMPLATE.md` manifest for engine, fonts, page limit, style rules, pitfalls). If it doesn't exist, run `/add-template --list` logic and show what is available.
   - `--all` → repeat Steps 2–4 for **every** registered template of this type *plus* the stock template, producing one PDF per style so the user can compare side by side.
   - Neither → use the `ACTIVE-TEMPLATE` managed block if present, else the stock template (moderncv/banking for CVs, `cover.cls` for cover letters).

---

## Step 2: Map Content into the Template

Fill the template skeleton with the draft's content:

- **Verbatim content.** Headings, bullets, sentences, dates — exactly as the author wrote them. Fix nothing silently: no rewording, no reordering of bullets within a section, no "improvements". Only mechanical LaTeX escaping (`&`, `%`, `#`, `_`, `$`) and structural mapping (a Markdown heading becomes the template's section command, a bullet list becomes the template's bullet environment).
- **Contact details** come from the draft if present, otherwise from `01-candidate-profile.md` (tell the user which fields were pulled from the profile).
- **Missing template sections:** if the template expects a section the draft doesn't have (or vice versa), ask rather than invent or drop content.
- Write the output to the standard locations `/apply`, `/outcome`, and `/interview` already expect:
   - CV → `cv/main_<company>_<role>.tex`
  - Cover letter → `cover_letters/cover_<company>_<role>.tex`
   - With `--all`, suffix the template name: `cv/main_<company>_<role>_<template>.tex`

---

## Step 3: Compile and Inspect (MANDATORY)

Follow `/apply` Step 5 exactly (5a compile → 5b inspect → 5c iterate → 5d ATS check for CVs → 5e clean up), with the engine from the template manifest (stock: **lualatex** for CVs, **xelatex** for cover letters). Same checklists: CV exactly 2 pages, no orphaned entry titles; cover letter exactly 1 page, signature intact, bullet fonts matching.

**One difference — the overflow rule.** `/apply` cuts content itself using relevance-weighted cutting. `/typeset` must not: the author owns the content. If the draft doesn't fit the page limit:

1. Report the overflow concretely ("the CV runs 2 pages plus 6 lines; the cover letter spills 4 lines onto page 2").
2. Offer ranked cut candidates using the relevance-weighted logic from `05-cv-templates.md` — as **suggestions with rationale**, exactly like `/critique` suggestions.
3. Apply only the cuts the user accepts, **in the Markdown draft first**, then re-map and re-compile. Draft and PDF must never diverge.
4. Layout-only rescues that don't touch content (`\needspace`, `\enlargethispage`) may be applied freely.

---

## Step 4: Deliver

1. **Copy the final `.tex` and `.pdf` into the application folder** (`documents/applications/<company>_<role>/`) alongside `drafts/` — the per-job workspace holds everything: source draft, reviews, and rendered output. (On submission, `/outcome` archives whatever was actually sent; existing archive files are never overwritten.)
2. Report:
   - Files written (standard paths + application-folder copies)
   - Layout verification results (page count, inspection checklist)
   - ATS verification results (CV only): parseability + keyword coverage table if a posting is on file
   - Any content pulled from the profile rather than the draft
3. Suggest **`/version save`** to checkpoint the rendered state.
4. If the user wants a different look: `/typeset --template <name>`, `/typeset --all` to compare, or `/add-template` to register a new style (including building a template from a sample resume design they like).

---

## Design Principles

- **Formatting, never authorship.** The PDF says what the draft says. Content problems route to `/critique`; overflow cuts require the author's sign-off and land in the draft first.
- **The Markdown draft is the single source of truth.** `.tex` and `.pdf` are build artifacts, regenerated at will; nothing is hand-edited into them that isn't in the draft.
- **Reuses the existing pipeline.** Compilation, inspection, ATS checks, and template registration all follow `/apply` and `/add-template` — one set of rules, no drift.
- **Style is swappable.** Same content, any registered template, one command.
