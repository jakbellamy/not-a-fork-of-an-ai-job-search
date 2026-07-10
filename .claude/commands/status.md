# /status - Unified Application Dashboard

You are providing a read-only overview of application progress across the workspace.

This command summarizes state. It does not write or modify any files.

Follow these steps in order.

---

## Step 0: Parse Input

`$ARGUMENTS` may contain:

- Nothing -> show a grouped dashboard across all applications
- A company name (optionally with role), e.g. `/status acme` or `/status acme ml engineer` -> show one application's full picture
- `--stale <N>` -> show applications with no update in N days (default 14 if N is missing)

---

## Step 1: Load Data Sources

Read these sources if present:

1. `job_search_tracker.csv`
2. `documents/applications/*/outcome.md`
3. `documents/applications/*/interview_prep_*.md`
4. Optional enrichment: `job_scraper/seen_jobs.json`

If `job_search_tracker.csv` does not exist, report that no tracked applications exist yet and suggest `/apply` to create drafted rows or `/outcome` for manual applications.

---

## Step 2: Normalize Statuses

Normalize tracker statuses into dashboard stages:

- `drafted` -> Drafted, not yet submitted
- `applied` -> Submitted, awaiting response
- `interview`, `offer` -> Interview stage
- `hired`, `rejected`, `no response`, `no_response`, `withdrawn`, `offer declined`, `offer_declined`, `interview_only` -> Resolved
- Unknown values -> Submitted, awaiting response (flag as `unmapped`)

For each row, derive:

- Last activity date from the tracker `date` column, and if present, latest date found in that application's `outcome.md` notes/checklist
- Days since last activity
- Archive presence (`job_posting.md`, `cv_draft.tex`, `cover_letter.tex`, `outcome.md`)
- Scraper link status using exact key join first:
   - match `tracker.source_key` to a `seen_jobs.json` key when available
   - else match `tracker.source` to a `seen_jobs.json` key
   - else fall back to fuzzy company+role comparison only for display hints

---

## Step 3: Render the Requested View

### A) Default view (no specific company)

Output sections in this order:

1. `Needs a decision` (optional)
   - Include only if `job_scraper/seen_jobs.json` is available and has entries with `status: ranked` that are not represented by a tracker exact key join (`source_key`/`source`) or company+role fallback.
2. `Drafted, not yet submitted`
3. `Submitted, awaiting response`
4. `Interview stage`
5. `Resolved`

Use compact markdown tables. For actionable rows, include a short action hint:

- Drafted: suggest `/outcome <company>` after submission
- Stale submitted/interview rows: suggest follow-up and `/outcome <company>` update
- Interview stage rows with upcoming prep need: suggest `/interview <company>`

### B) Company view (`/status <company> [role]`)

Show:

1. Matched tracker row(s)
2. Archive folder path and which artifacts exist
3. `outcome.md` status summary (or `not recorded`)
4. List of `interview_prep_*.md` files if any
5. Suggested next command based on current status

If several rows match, list choices and ask which one to inspect.

### C) Stale view (`/status --stale <N>`)

Show rows where `days since last activity >= N`, grouped by current stage. If none, say so clearly.

---

## Step 4: Important Rules

1. Read-only: never call edit/write tools from this command.
2. Do not infer outcomes that are not recorded. Missing data stays explicit.
3. If optional sources are missing (`seen_jobs.json`, `outcome.md`), degrade gracefully and continue.
4. Keep statuses human-readable while preserving original tracker value when it is ambiguous.
