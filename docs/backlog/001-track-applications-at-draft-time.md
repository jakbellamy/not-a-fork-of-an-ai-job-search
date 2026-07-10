# 001 — Auto-create a tracker row + archive stub at draft time

**Status:** ~~Decided: implement~~ Implemented (owner call executed, 2026-07-10)

## Problem

`/apply` is the command that actually produces a CV and cover letter, but it never writes to
`job_search_tracker.csv` or `documents/applications/`. Confirmed by grep across `.claude/commands/`
and `.claude/skills/`: only `outcome.md`, `rank.md`, `interview.md`, `version.md`, and
`upskill/SKILL.md` reference either file. `apply.md` does not.

Instead, `/apply` Step 6 ends with a suggestion:

> "Submitted? `/outcome <company>` logs it in the tracker and starts the per-application record."

This makes "did I apply?" a manually-reported fact with no default. Concretely:

1. **Drafts are invisible to the rest of the system.** If a user drafts CVs for 4 jobs in one
   session and hasn't decided which to submit yet, there is no record anywhere that those 4 drafts
   exist — not in the tracker, not in an archive folder. `cv/main_<company>.tex` files just
   accumulate in the working tree with no linkage back to the posting or the fit evaluation that
   was shown for them.
2. **`/interview` and `/outcome` both hit a dead end if invoked before the tracker row exists.**
   From `interview.md:15`: *"None → this application isn't tracked; suggest `/outcome <company>`
   to register it first."* From `outcome.md:29`: *"None → the application was made outside the
   workflow; collect company, role, date applied, channel, and posting URL from the user and add a
   tracker row."* Both treat "no tracker row" as the common case for anything drafted through
   `/apply`, not the edge case the wording implies.
3. **Redundant data entry.** `/apply` Step 0 already extracts company, role, location, and posting
   language/URL. `/outcome`'s no-match fallback re-asks the user for company, role, date applied,
   channel, and source — all of which existed in the `/apply` session, just not persisted anywhere
   `/outcome` can read.
4. **Nothing distinguishes "drafted, undecided" from "actually submitted."** A future dashboard
   (see [002](002-status-dashboard-command.md)) has no state to render for jobs sitting in this
   limbo.

## Decision

The moment `/apply` Step 1 gets a "yes, draft it" answer (i.e., right before Step 2 starts
writing files), it should:

1. Create/update a row in `job_search_tracker.csv` with `status = drafted`, populated from data
   already in context: `date` (today), `company`, `role`, `source` (the posting URL, or `pasted`
   if the user pasted text), `cv_file`/`cover_letter_file` (the paths Step 2 is about to write).
   `sector`, `role_type`, `channel`, `contact_person`, `fit_rating` filled in where derivable
   (`fit_rating` from the Step 1 evaluation verdict), left blank otherwise.
2. Create `documents/applications/<company>_<role>/job_posting.md` with the posting text captured
   in Step 0 — this is the one artifact that's often impossible to recover later (postings expire
   fast), so capturing it at draft time instead of at `/outcome` time closes a real data-loss risk,
   not just a convenience gap.
3. Leave `outcome.md` **uncreated** at this stage — `in_progress` isn't a meaningful outcome yet,
   and `/outcome`'s job is still to create that file once there's something to report (an
   application submitted, a response, etc.). Don't pre-empt `/outcome`'s ownership of that file.

`/outcome` then needs a third branch alongside its existing "matched row" / "no match" cases in
Step 1.2: **matched row with `status = drafted`** → this is the expected path now, not the
exception. Treat it the same as a matched row (update status, don't re-ask for company/role/date),
but since `date` there is "drafted", ask specifically for the actual submission date if the user is
recording a submission.

## Why not the alternatives

- **Keep current behavior (only track at `/outcome`)** — rejected by the owner. Keeps drafting
  "free" but leaves the three problems above unaddressed, and every downstream command's
  "not tracked yet" fallback stays the common path instead of the edge case.
- **New checkpoint after PDFs compile, asking "add to tracker?"** — rejected by the owner in favor
  of the fully automatic version. Would avoid tracking drafts the user immediately discards, at the
  cost of one more prompt per application and reintroducing the "forgot to say yes" failure mode
  this item exists to close.

## Implementation checklist

- `.claude/commands/apply.md`
  - Step 1: after "yes, continue" is confirmed, before Step 2 begins, add the tracker-row +
    archive-stub write described above.
  - Step 2: note that the archive's `job_posting.md` already has the posting text; no need to
    refetch it.
  - Step 6 "Next Steps": change "Submitted? `/outcome <company>` logs it in the tracker" to
    "Submitted? `/outcome <company>` updates its status" (the row already exists).
- `.claude/commands/outcome.md`
  - Step 1.2: add the "matched row with `status = drafted`" branch described above.
  - Step 1.4: the archive folder may already exist (with `job_posting.md` only) — check for that
    instead of assuming folder-exists implies outcome.md exists too.
  - Step 3.2 (`job_posting.md`): update "if it already exists, leave it" — this will now be the
    normal case, not the exception.
- `.claude/commands/interview.md`
  - Step 15: the "None → not tracked, suggest `/outcome`" fallback becomes rarer but should stay
    as a safety net for applications made outside `/apply` (pasted-in-chat evaluations, manual
    applications never run through the tool).
- `.claude/skills/job-application-assistant/SKILL.md` — Step 2 mentions creating the CV; add a
  one-line note that the tracker row is created before this step, per `apply.md`.
- `documents/README.md` — the `applications/<company>_<role>/` section currently describes
  `job_posting.md` as written by `/outcome`; update to say `/apply` writes it at draft time and
  `/outcome` only fills gaps if a draft-stage application is missing it (manual applications).
- `docs/user-guide.md` — the "How `/apply` works" and "A typical week" sections should mention
  that drafting now creates a tracker entry, not just the PDFs.

## Open questions for implementation (not product decisions, just details to nail down)

- Tracker CSV has no natural primary key beyond `company`+`role` matched case-insensitively
  (`outcome.md` Step 1.2). If a user runs `/apply` twice for the same company+role (e.g., redrafting
  after rejection elsewhere, or a genuine duplicate), should the second `/apply` update the existing
  `drafted` row or ask? Recommend: ask, same as `/outcome`'s existing "several matches → list and
  ask" behavior.
- `fit_rating` — Step 1's evaluation produces a qualitative verdict (strong/moderate/weak fit) and
  optionally a salary benchmark, not a single number. Recommend storing the verdict word directly
  in `fit_rating` (matches the header's plain intent) rather than inventing a numeric score to fit
  a column that has never needed one before now.
