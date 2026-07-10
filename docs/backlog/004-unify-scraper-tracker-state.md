# 004 — Cross-link `seen_jobs.json` and the tracker; add an `applied` status to the scraper's own enum

**Status:** ~~Proposed, not yet decided by owner~~ Implemented (owner call executed, 2026-07-10) — companion to [001](001-track-applications-at-draft-time.md) and [002](002-status-dashboard-command.md).

## Problem

Even after [001](001-track-applications-at-draft-time.md) makes `/apply` create a tracker row at
draft time, `job_scraper/seen_jobs.json` — the file `/scrape` and `/rank` actually read and write —
never learns that a job was acted on. Its status enum (from `.claude/skills/job-scraper/SKILL.md`'s
Step 4 schema, extended by `/rank`'s Step 4) is `new` / `skipped` / `evaluated` / `ranked` /
`expired`. There is no `applied` value. A job that gets drafted and submitted stays frozen at
whatever status `/rank` last set it to (`ranked`), forever, as far as `seen_jobs.json` is concerned.

Two consequences:

1. **Dedup still works, but by accident of a different mechanism.** `/scrape` Step 2 skips a URL
   if it's already a key in `seen_jobs.json` regardless of status — so a job won't resurface just
   because its status is stale. The correctness isn't at risk; the *legibility* is. Anyone (or any
   future command) reading `seen_jobs.json` directly sees "ranked" for a job that was actually
   pursued to completion, which is misleading.
2. **The two files key jobs differently**, which matters if anything ever needs to join them (as
   [002](002-status-dashboard-command.md)'s dashboard would, to show ranked-but-undecided jobs next
   to real applications in one list). `seen_jobs.json` keys on `<url_or_company_title_key>`
   (`job-scraper/SKILL.md` Step 4). The tracker matches on `company`+`role`, case-insensitive,
   fuzzy (`outcome.md` Step 1.2: "match rows case-insensitively on company, then role"). These are
   not the same key. A company name or role title that's phrased slightly differently between the
   scrape result and what the user later types into `/outcome` (or that `/apply` extracts from the
   posting) won't join cleanly.

## Proposed design

1. Add `applied` to the status enum documented in `job-scraper/SKILL.md`'s `seen_jobs.json` schema
   section and `documents/README.md` wherever the schema is described.
2. When [001](001-track-applications-at-draft-time.md)'s tracker-row write happens in `/apply`, if
   the job's URL matches a key in `seen_jobs.json`, also flip that entry's status to `applied` in
   the same step. If `/apply` was invoked directly (pasted text, no scrape origin), there's no
   `seen_jobs.json` entry to update — that's fine, this is best-effort enrichment, not a new
   requirement on `/apply`.
3. Store the `seen_jobs.json` key on the tracker row itself (a new `source_key` column, or reuse
   the existing `source` column if it already holds the URL `seen_jobs.json` keys on — check
   whether these are actually the same string before adding a redundant column). This gives
   anything joining the two files an exact key instead of fuzzy company/role matching.

## Why this is flagged, not decided

This changes the tracker CSV's schema (a new column) and the scraper's state schema (a new enum
value) — both are data-format changes to files that may already have rows/entries in them from
before this backlog existed. That's a low-stakes migration for a single personal user, but it's
still a "does the value justify touching the schema" call, not a pure bug fix like
[003](003-cv-filename-collision-fix.md). Worth confirming:

- Is the `source_key`/exact-join improvement actually needed, or is fuzzy company+role matching
  good enough in practice for one person's job search (a handful to a few dozen applications,
  not thousands)? The complexity here scales with how often company/role names actually drift
  between a scrape result and later manual references to it — worth checking a few real
  `seen_jobs.json` entries against tracker rows before building this, rather than assuming drift
  is common.
- Does [002](002-status-dashboard-command.md)'s "needs a decision" section (ranked-but-undecided
  jobs) matter enough to justify this, or is it fine for `/status` to only show real applications
  and leave "what's ranked but I haven't acted on" to `/rank`'s own output (which already presents
  that list once, right after ranking)?

## Implementation checklist (if approved)

- `.claude/skills/job-scraper/SKILL.md` — Step 4 schema section, add `applied` to the status enum
  documentation.
- `.claude/commands/rank.md` — Step 4 already documents `ranked`/`expired` as additive fields; note
  that `applied` is set by `/apply`, not by `/rank`, to avoid two commands racing to own the same
  field (same ownership principle `/outcome`'s Step 5 already applies to calibration: "don't write
  what another command owns").
- `.claude/commands/apply.md` — Step 1 (alongside the 001 tracker-row write), add the
  `seen_jobs.json` status flip, keyed by URL match.
- `job_search_tracker.csv` header (documented in `.claude/commands/outcome.md` Step 1) — add
  `source_key` column if the existing `source` column isn't already the same string
  `seen_jobs.json` uses as its key.
- `documents/README.md` — update the `seen_jobs.json` schema documentation block to include
  `applied`.

## Open questions for implementation

- Confirm whether `seen_jobs.json`'s key and the tracker's `source` column already store the same
  URL string before adding a new column — they may already join cleanly on `source` alone.
- If a job was ranked under one seen_jobs.json key but the user pastes a *different* URL (e.g. a
  redirect, or a re-posted listing) into `/apply`, the status flip simply won't find a match — that
  should fail silently (no error, no blocking), consistent with this being best-effort enrichment.
