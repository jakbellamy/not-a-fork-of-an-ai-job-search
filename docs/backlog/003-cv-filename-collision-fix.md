# 003 — Fix: CV filename drops the role, second application at the same company silently overwrites the first

**Status:** ~~Decided: implement~~ Implemented (owner call executed, 2026-07-10)

## Problem

`/apply` writes the cover letter to a filename that includes the role, but the CV to a filename
that doesn't:

- `.claude/commands/apply.md:80` — `### CV (`cv/main_<company>.tex`)`
- `.claude/commands/apply.md:87` — `### Cover Letter (`cover_letters/cover_<company>_<role>.tex`)`

Same asymmetry in `.claude/skills/job-application-assistant/SKILL.md:30` and
`.claude/skills/job-application-assistant/05-cv-templates.md:9`.

**Concrete failure case:** apply to "Data Scientist" and "ML Engineer" at the same company in two
separate `/apply` runs. Both write `cover_letters/cover_acme_data-scientist.tex` and
`cover_letters/cover_acme_ml-engineer.tex` (fine, distinct files) but both CVs write to the same
`cv/main_acme.tex` (not fine — the second `/apply` run silently overwrites the first CV with no
warning, no diff shown, no confirmation asked). The Edit/Write step in Step 2 just writes the file;
nothing in the verification checklist checks "did this file already exist for a different role."

This is a genuine work-loss bug, not just an inconsistency — if the first CV was already submitted,
the only surviving copy is whatever `/outcome` archived to
`documents/applications/acme_data-scientist/cv_draft.tex` (assuming `/outcome` was already run for
it), otherwise it's gone.

## Decision

Rename the CV output to `cv/main_<company>_<role>.tex`, matching the cover letter and the
`documents/applications/<company>_<role>/` archive folder convention already used everywhere else.
Existing `main_<company>.tex` files from past applications are left alone — this only changes the
pattern for new `/apply` runs going forward, per the owner's explicit choice (not a bulk rename of
history).

## Implementation checklist

Every touch point found via repo-wide grep for `main_<company>` / `main_*.tex` (excluding the
nested `ai-job-search/` clone, which is out of scope — see the conversation this backlog originated
from):

- `.claude/commands/apply.md`
  - Line 80 header and the file path itself
  - Line 130 `<CV_DRAFT file="cv/main_<COMPANY>.tex">`
  - Line 151 the reviewer's structured-edit JSON schema (`"file": "cv/main_<COMPANY>.tex" | ...`)
  - Line 199 compile command `cd cv && lualatex ... main_<company>.tex`
  - Line 212 `**CV (`cv/main_<company>.pdf`):**`
  - Line 244 `pdftotext -layout main_<company>.pdf main_<company>.txt`
  - Line 293 "Files Created" list
- `.claude/skills/job-application-assistant/SKILL.md` line 30
- `.claude/skills/job-application-assistant/05-cv-templates.md` lines 9, 16, 19, 153, 182
- `.claude/commands/outcome.md` line 61 — the fallback glob `cv/main_<company>.tex` used when the
  tracker row's `cv_file` column is empty; needs to become `cv/main_<company>_<role>.tex`, and since
  the tracker row now always has `cv_file` populated once
  [001](001-track-applications-at-draft-time.md) lands, this fallback becomes a true fallback
  (manual applications) rather than the common path
- `.claude/commands/interview.md` line 28 — same fallback-glob update
- `.claude/commands/typeset.md` lines 41, 43 — `--all` suffix behavior
  (`cv/main_<company>_<template>.tex`) needs to compose correctly with the role now also being in
  the filename: `cv/main_<company>_<role>_<template>.tex`
- `.claude/commands/add-template.md` line 138 — the "Output file: unchanged" note documents the old
  pattern
- `CLAUDE.md` line 88 — workflow description
- `SETUP.md` lines 231, 237 — compile command examples
- `.gitignore` line 50 (`cv/main_*.tex`) and `tools/security_guards.py` lines 47-48 — these use a
  wildcard glob, so they keep working unchanged; confirm during implementation rather than assuming
- `.claude/commands/version.md` line 45 (`!cv/main_*.tex` in the private-mode gitignore override) —
  same wildcard, should be unaffected

Not in scope: `.github/workflows/ci.yml` and `cv/main_example.tex` itself — those exercise the
stock template, which is unaffected by this per-application naming change.

## Verification

After implementing, the concrete repro case above (two `/apply` runs, same company, different
roles) should produce two distinct CV files, neither overwriting the other. Add this as a manual
test step until/unless this repo's CI grows a way to exercise `/apply` end-to-end.
