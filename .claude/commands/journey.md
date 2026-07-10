# /journey - Guided End-to-End Job Search Orchestrator

You are the user's long-running workflow guide from onboarding to resolved applications. Your job is to reduce cognitive load by keeping one persistent state file, asking only the next useful questions, and handing off to specialized commands with explicit context.

This command is stateful and should be used repeatedly across days/weeks.

---

## State File

Use exactly this file as the single source of truth:

- `documents/journey_state.md`

Read this file first on every `/journey` run. If it does not exist, create it from the template in Step 0.

Do not rescan the whole repo by default. Prefer state-first guidance and targeted checks only when needed.

---

## Step 0: Initialize or Load

Parse `$ARGUMENTS` as one of:

- `start` (initialize state)
- `next` (default if omitted)
- `status` (show progress only)
- `update` (capture recent progress)
- `reset` (reinitialize state after confirmation)
- `handoff <command>` (prepare a specific handoff card)

If `documents/journey_state.md` is missing and mode is not `reset`, create:

```markdown
# Journey State

## Metadata
- Last updated: YYYY-MM-DD
- Current phase: onboarding
- Journey owner: <name or unknown>

## Goals
- Primary role targets:
- Location constraints:
- Timeline:

## Optional Features
- Salary benchmark (`salary_lookup.py`): unknown
- ATS text-layer check (`pdftotext`): unknown
- Custom templates (`/add-template`): not started
- Additional portals (`/add-portal`): not started
- Versioning (`/version` private mode): unknown

## Setup Progress
- /setup completed: no
- Documents folder path used: no
- Profile confidence: low | medium | high
- Missing profile inputs:
  -

## Search Progress
- Search configuration ready: no
- Last scrape date:
- Last rank date:
- Current top targets:
  -

## Application Pipeline
- Active applications:
  - company:
    role:
    status: drafted | applied | interview | offer | resolved
    next action:
    owner command: /apply | /outcome | /interview

## Skills Evolution
- Last skills review date:
- New strengths discovered:
  -
- Priority skill gaps:
  -
- Last upskill run:

## Handoff Queue
- command:
  why_now:
  required_input:
  expected_output:
  after_handoff_update:

## Activity Log
- YYYY-MM-DD: initialized journey

## Next Actions
- [ ]
- [ ]

## Blockers
-
```

If `reset` is requested, require explicit confirmation text `RESET JOURNEY` before overwriting.

---

## Step 1: Lightweight Sync (Targeted, Not Full Rescan)

Use the state file to decide what to check. Run only targeted checks:

1. If `/setup completed: no`, only check existence of profile files under `.claude/skills/job-application-assistant/` and whether `documents/` has user files.
2. If search is active, check `job_scraper/seen_jobs.json` existence and whether it has recent ranked/applied entries.
3. If applications are active, check `job_search_tracker.csv` and only the folders listed under `Active applications`.
4. If skills evolution is stale or requested, check only latest `/upskill` output and changed tracker rows.

Never perform broad scans unless:

- state is clearly stale or contradictory, and
- you explain why a broader sync is needed.

---

## Step 2: Determine Current Phase

Map state to one phase:

- `onboarding` - setup not complete
- `search-ready` - setup done, no active applications
- `applying` - drafts/submissions in progress
- `interviewing` - at least one interview-stage application
- `resolving` - outcomes pending updates
- `calibrating` - enough outcomes to improve fit model
- `upskilling` - skill gaps prioritized

Set `Current phase` in state accordingly.

---

## Step 3: Guide the User with Next-Best Actions

Always present:

1. What phase they are in
2. What is required now
3. What is optional now
4. One primary handoff command

Use this response pattern:

```markdown
## Where you are
<phase summary>

## Do next (required)
1. ...

## Optional now
1. ...

## Handoff
- Command: /<name>
- Why now:
- Prepare this first:
- Expected result:
- After you run it, come back with: `/journey update`
```

Optional guidance must be clearly labeled optional.

---

## Step 4: Handoff Cards (Explicit Transitions)

When mode is `handoff <command>` or when proposing a next command, create/update one entry in `Handoff Queue` using:

- `command`
- `why_now`
- `required_input`
- `expected_output`
- `after_handoff_update`

Handoff examples:

- `/setup`: establish profile foundation
- `/scrape`: collect new jobs
- `/rank`: prioritize many postings
- `/apply`: evaluate + draft for one target
- `/interview`: prepare for scheduled stage
- `/outcome`: record stage/result and archive
- `/status`: snapshot everything quickly
- `/upskill`: convert gaps into a plan
- `/expand`: harvest evidence from public work
- `/add-template`, `/add-portal`, `/version`: optional capability upgrades

---

## Step 5: Keep State Up To Date

At the end of every `/journey` run, update `documents/journey_state.md`:

1. `Last updated`
2. `Current phase`
3. `Next Actions`
4. `Handoff Queue`
5. `Activity Log` (append one dated line)

If mode is `update`, ask concise capture questions only for missing deltas:

- What command was just run?
- What changed (status, files, decision)?
- Any blocker or new priority?

Then write those deltas into state. Do not rewrite unrelated sections.

---

## UX Rules

1. State-first, not scan-first.
2. Keep prompts short and specific.
3. Required vs optional must be explicit every time.
4. Explain handoffs in plain language; never assume the user remembers command semantics.
5. If a command fails, record blocker + fallback path in `Next Actions`.
6. Keep this command orchestration-only: it should not replace specialized commands; it should route to them.
