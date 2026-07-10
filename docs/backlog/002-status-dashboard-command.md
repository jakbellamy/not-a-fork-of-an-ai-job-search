# 002 — `/status`: one view across all applications

**Status:** ~~Decided: implement~~ Implemented (owner call executed, 2026-07-10). Depends on [001](001-track-applications-at-draft-time.md); works better with [004](004-unify-scraper-tracker-state.md) but doesn't strictly require it.

## Problem

Today there is no single place to see "where do things stand across everything I'm working on."
The closest thing is `/outcome` invoked with no argument, which:

- only lists rows whose status is **not** final (`outcome.md` Step 1.3) — resolved applications
  drop out of view entirely, so there's no "how did my last 10 applications go" retrospective
  without opening the CSV by hand
- only shows what's already in `job_search_tracker.csv` — which, before
  [001](001-track-applications-at-draft-time.md), means drafted-but-undecided applications aren't
  in it at all, and even after 001, ranked-but-not-yet-drafted candidates from `/rank` still aren't
- is a side effect of a command whose primary purpose is *recording an update*, not *reviewing
  state* — a user who just wants to look, not update anything, still walks into "what happened?"

With multiple applications genuinely in flight (the whole point of the tracker + archive + `/version`
branch-per-application model), "what needs my attention right now" is a real recurring question
this framework has no direct answer for.

## Decision

Add `/status` as a new, read-only command.

```
/status                 # everything, grouped by stage
/status <company>       # one application's full picture (tracker row + archive + interview prep files)
/status --stale <N>     # applications with no update in N days (default 14) — the "needs a nudge" view
```

### Default view

Group by stage, most-actionable first:

```
## Application Status — YYYY-MM-DD

### Needs a decision (3)
Ranked, not yet applied to. From /rank.
| Score | Verdict | Title | Company | Deadline |

### Drafted, not yet submitted (2)
| Company | Role | Drafted | CV | Cover Letter |

### Submitted, awaiting response (5)
| Company | Role | Applied | Days since | Status |

### Interview stage (2)
| Company | Role | Stage | Next step |

### Resolved (12)
| Company | Role | Outcome | Date |
```

- "Needs a decision" only populates if [004](004-unify-scraper-tracker-state.md) is implemented
  (it reads `seen_jobs.json` entries with `status: ranked` that have no matching tracker row).
  Without 004, this section is simply omitted — degrade gracefully rather than block on it.
- "Days since" surfaces the same staleness signal `/outcome` Step 2 already asks about
  (`no_response` classification) — `/status` computes it, it doesn't ask the user to self-report.
- Every row that's actionable should say what the action is: "3 days until deadline", "no response
  in 21 days — consider `/outcome` to mark no_response", "interview scheduled — run `/interview`".

### `/status <company>`

Pull together everything already scattered per application: the tracker row, the archive folder's
`outcome.md` notes, and (if present) `interview_prep_*.md` files. This is a read-only aggregation —
no new data written anywhere.

## Why not the alternatives

- **No new command, rely on `/outcome`'s partial list** — rejected by the owner; doesn't cover
  resolved applications or pre-tracker-row candidates, and overloads a write-oriented command with
  a read-oriented job.

## Implementation checklist

- New `.claude/commands/status.md` — read-only, no `Edit`/`Write` tool needed in its `allowed-tools`
  if commands declare that (check `job-application-assistant/SKILL.md`'s `allowed-tools:` pattern
  for the convention used elsewhere in this repo).
- Reads: `job_search_tracker.csv`, `documents/applications/*/outcome.md`,
  `documents/applications/*/interview_prep_*.md`, and — once 004 lands —
  `job_scraper/seen_jobs.json` entries with `status: ranked`.
- `README.md` "Other commands" list and `docs/user-guide.md`'s command reference table both need
  the new entry.
- No change to any file-writing command — `/status` must stay strictly read-only, otherwise it
  becomes another place state can drift from the others.

## Open questions for implementation

- Staleness default of 14 days is a guess calibrated to nothing — worth revisiting once there's
  real data on this fork's own response times (which, fittingly, `/setup`'s calibration from
  `outcome.md` records could eventually inform).
- Should `/status` read `job_search_tracker.csv` directly or should there be a light shared
  "load tracker + parse rows" helper reused by `/outcome`, `/rank`, `/interview`, and `/status`?
  All four currently duplicate their own "read the CSV, match rows" logic in prose form (they're
  markdown-driven agent instructions, not code, so "duplicate" means "repeat the same instruction,"
  not a real DRY violation — but if the CSV's column set ever changes, four files need updating in
  lockstep). Not blocking for a first version; flag if it becomes an actual maintenance pain.
