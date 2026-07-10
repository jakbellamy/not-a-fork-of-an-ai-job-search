# Journey State

## Metadata
- Last updated: 2026-07-10
- Current phase: onboarding
- Journey owner: unknown

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
- Documents folder path used: no (folders currently empty)
- Profile confidence: low
- Missing profile inputs:
  - No CV/LinkedIn/diploma/reference files in documents/ yet
  - Basic profile not confirmed yet

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
- command: /setup
  why_now: Profile foundation is required before high-quality matching and drafting.
  required_input: Default chosen for autonomous flow: Path B single CV import (paste or attach one CV). Alternatives: Path C interview mode, or populate documents/ then Path A.
  expected_output: Populated profile and evaluation files.
  after_handoff_update: Mark setup completed and raise profile confidence.

## Activity Log
- 2026-07-10: initialized journey state file
- 2026-07-10: journey sync run; documents/cv, linkedin, diplomas, references, applications are empty except .gitkeep
- 2026-07-10: autonomous default selected for next handoff -> /setup Path B (single CV import)

## Next Actions
- [ ] Run /setup using Path B (single CV import) or Path C (interview mode)
- [ ] Optional: populate documents/ and then rerun /setup Path A
- [ ] Return to /journey update after setup

## Blockers
-
