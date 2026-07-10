# Backlog: Multi-Application Tracking & Scraped-Job Handling

Analysis of how the framework currently handles multiple in-flight applications and jobs that
come in through `/scrape`/`/rank`, written after tracing every command that reads or writes
`job_search_tracker.csv`, `job_scraper/seen_jobs.json`, and `documents/applications/`.

**Scope:** personal fork only (per owner decision, 2026-07-10). These are not written to clear
`CONTRIBUTING.md`'s upstream bar — they're shaped for this fork's own workflow.

## The core finding

Three files each hold a partial, uncoordinated picture of "what have I done with this job":

| File | Written by | Read by | Knows about |
|---|---|---|---|
| `job_scraper/seen_jobs.json` | `/scrape`, `/rank` | `/scrape` (dedup), `/rank` | new / skipped / evaluated / ranked / expired — **no "applied" state** |
| `job_search_tracker.csv` | `/outcome` only | `/rank` (exclusion), `/outcome`, `/interview` | applied / interview / offer / hired / rejected / etc. — **only exists once `/outcome` runs, which is a manual step users can forget or delay** |
| `documents/applications/<company>_<role>/` | `/outcome` only | `/setup` Path A, `/interview` | the archived posting/CV/cover-letter/outcome — **same manual-trigger gap** |

`/apply` — the command that actually drafts a CV and cover letter — writes to **none** of these.
It hands off to `/outcome` with a "Submitted? Run `/outcome <company>`" suggestion, and everything
downstream (`/interview`, `/setup`'s calibration, a hypothetical dashboard) is blind until that
manual step happens. `/interview` and `/outcome` both explicitly handle the "this isn't tracked
yet" case as a fallback — evidence that this gap is already felt, not hypothetical.

## Items

| # | Title | Status |
|---|---|---|
| [001](001-track-applications-at-draft-time.md) | ~~Auto-create a tracker row + archive stub the moment `/apply` starts drafting~~ | ~~Decided: implement~~ Implemented (2026-07-10) |
| [002](002-status-dashboard-command.md) | ~~New `/status` command — one view across all applications~~ | ~~Decided: implement (depends on 001, softly on 004)~~ Implemented (2026-07-10) |
| [003](003-cv-filename-collision-fix.md) | ~~Fix: CV filename drops the role, second application to the same company silently overwrites the first~~ | ~~Decided: implement~~ Implemented (2026-07-10) |
| [004](004-unify-scraper-tracker-state.md) | ~~Cross-link `seen_jobs.json` entries to tracker rows; add an `applied` status to the scraper's own enum~~ | ~~Proposed, not yet decided~~ Implemented (2026-07-10) |

Recommended order: **003 → 001 → 004 → 002.** 003 is an isolated bug fix. 001 is the behavioral
change everything else leans on. 004 makes 002's dashboard able to show ranked-but-undecided jobs
next to real applications instead of only real applications. 002 is the payoff.
