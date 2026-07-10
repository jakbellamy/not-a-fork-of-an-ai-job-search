# User Guide

A plain-English walkthrough of everything you can do once setup is finished. If you haven't installed anything yet, start with the [README](../README.md) quick start or the full [SETUP.md](../SETUP.md) instead — this guide assumes `/setup` has already run at least once.

## The core loop

```
/setup  →  /scrape  →  /rank  →  /apply  →  /interview  →  /outcome
   ^                                                          |
   └──────────────────── calibration ────────────────────────┘
```

1. **`/setup`** builds your profile once, from your documents, a single CV, or an interview.
2. **`/scrape`** searches job portals and hands you new matches.
3. **`/rank`** (optional, useful when a scrape returns a lot of jobs) batch-scores everything and gives you a shortlist.
4. **`/apply <url>`** drafts a tailored CV and cover letter for one posting.
5. **`/interview`** preps you once an interview is scheduled.
6. **`/outcome`** records what happened — and feeds that signal back into `/setup`'s scoring the next time you calibrate.

Everything below expands on one of these steps, plus the commands that sit around the edges.

## Command reference

| Command | What it does |
|---|---|
| `/setup` | Builds or updates your profile. Three entry paths: read `documents/` folder, import a single CV, or answer an interview. Re-run anytime; it merges, never silently overwrites. See [documents/README.md](../documents/README.md) for what to put in the documents folder. |
| `/setup --section search` | Re-run just the job-search configuration (target roles, skills, locations, portals) without redoing your whole profile. |
| `/scrape` | Searches configured job portals for matches, deduplicates against past runs and your tracker, and presents results with a quick fit rating. |
| `/rank` | Batch-scores all newly scraped postings against the full fit framework (parallel agents fetch and score each one). Returns a ranked shortlist with strengths, gaps, and urgency flags. Best after a scrape returns 8+ jobs. |
| `/apply <url or text>` | The full application pipeline: evaluate fit → draft CV + cover letter → reviewer agent critiques → revise → compile to PDF → ATS check → present. See [How /apply works](#how-apply-works) below. |
| `/critique` | For a draft **you wrote yourself**. Reviews it against the job posting, your real profile, and ATS realities. Nothing changes unless you accept a suggestion. See [Writing it yourself](#writing-it-yourself). |
| `/typeset` | Renders your own text draft (Markdown, plain text, or Word) as a professional PDF using any registered template. `--all` renders it in every registered style for comparison. |
| `/version` | Plain-language git: "save my progress", "start a version for the Acme job", "bring back Tuesday's cover letter". No git knowledge needed. First use switches the repo to private mode. |
| `/interview` | Builds a stage-specific prep pack for a scheduled interview: the exact posting and documents the interviewer read, prior-round feedback, likely questions mapped to your STAR examples, and an optional mock interview. |
| `/outcome` | Records what happened to an application (interview stages, offer, rejection, silence). Archives the submitted CV/cover letter/posting into `documents/applications/<company>_<role>/` and updates the tracker. |
| `/expand` | Scans public sources already linked in your profile (GitHub, portfolio, Kaggle, Google Scholar) and named courses/certifications, and proposes competencies to add — each tagged with its source. Good right after `/setup`. |
| `/upskill` | Compares your profile against tracked postings (or one posting via `/upskill <url>`) and produces a prioritized skill-gap heatmap with study resources and time estimates. |
| `/add-template` | Registers your own LaTeX CV or cover letter template in place of the stock ones. Captures compile engine, fonts, style rules, and page limit; test-compiles before activating. |
| `/add-portal` | Generates a job-portal search skill for a board in your market. Investigates the portal, scaffolds a CLI skill matching the shipped ones, test-runs a live query before registering. |
| `/reset` | Wipes profile data and/or the documents folder. Shows exactly what will be deleted; requires typing `RESET` to confirm. |

## How `/apply` works

1. **Parse** the job posting (URL or pasted text).
2. **Evaluate fit** against your profile — skills, experience, culture, location, career alignment. You see this assessment before anything is drafted.
3. **Draft** a tailored CV and cover letter in LaTeX.
4. **Spawn a reviewer agent** with fresh context that researches the company and critiques the drafts.
5. **Revise** based on that feedback.
6. **Compile and inspect** both PDFs — `lualatex` for the CV, `xelatex` for the cover letter. Claude reads the rendered pages and iterates until the CV is exactly 2 pages with no orphaned entries, and the cover letter is exactly 1 page with a visible signature and consistent fonts.
7. **ATS-check the CV** — extract the PDF's text layer and verify it the way an applicant-tracking system would: contact details present as literal text, no garbled glyphs, sane reading order, honest keyword coverage against the posting (gaps stay visible, never stuffed).
8. **Present** the final output with a verification checklist.

All claims are checked against your actual profile — nothing fabricated.

## Writing it yourself

Prefer to write your own CV and cover letter and have Claude edit, format, and archive them instead of drafting from scratch? That's the self-draft workflow: `/critique` → you accept/reject suggestions → `/typeset` → PDF. Full walkthrough in [docs/self-draft-workflow.md](self-draft-workflow.md).

## Getting the most out of it

**Profile depth is the single biggest lever on output quality.** A thin profile produces generic applications; a detailed one lets the system genuinely tailor results.

- **Describe what you actually did**, not just job titles: specific projects, tools, responsibilities, measurable achievements.
- **Put skills in context.** "Built ML pipelines for customer churn prediction in Python using scikit-learn" gives the system far more to work with than "Python, machine learning."
- **This applies to every `/setup` path** — documents folder, single CV, or interview. Richer input produces sharper output either way.

**Two ways to job search, both supported:**

- **Explicit targeting** — you know the roles/sectors you want; the system refines and prioritizes.
- **Latent opportunity discovery** — by analyzing your full history (not just titles, but the actual work), the system can surface roles you haven't considered: transferable skills mapping to unexpected industries, patterns in what energized you, emerging roles combining your domain with new technology.

To get discovery mode working well, spend time during `/setup` describing not just your experience but what energized you, what drained you, and what you'd want more of. That context directly shapes fit evaluation and what `/scrape` surfaces.

## A typical week

1. `/scrape` on Monday — new postings land, sorted by fit.
2. 8+ new matches? `/rank` first, to avoid eyeballing a long table.
3. Pick the strongest 2-3, `/apply <url>` each.
4. Submit the ones you're happy with.
5. `/outcome` as responses come in — interview requests, rejections, silence, all logged.
6. Interview scheduled → `/interview` the day before.
7. Enough outcomes recorded → re-run `/setup` to let real signal calibrate the fit framework.

## Troubleshooting

Installation and compile issues (Bun, LaTeX, `pdftotext`, stale permissions) are covered in [SETUP.md → Troubleshooting](../SETUP.md#troubleshooting). This guide only covers workflow questions:

- **`/scrape` returns nothing new** — everything found already exists in `job_scraper/seen_jobs.json` or `job_search_tracker.csv`. Try `/setup --section search` to broaden your queries.
- **`/apply` fit evaluation looks off** — the fit framework calibrates from `outcome.md` records. If you haven't logged any outcomes yet, it's working from your stated preferences alone; log a few outcomes and re-run `/setup` to sharpen it.
- **Want a second opinion on a draft without a full rewrite** — use `/critique` instead of `/apply`.
