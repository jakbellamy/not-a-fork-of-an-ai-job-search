# Write It Yourself: The Self-Draft Workflow

A guide for using this assistant when **you** write your CV and cover letters and the AI acts as your editor, formatter, and archivist. No LaTeX knowledge needed, no git knowledge needed — you write in Word, Google Docs, or plain text, and talk to Claude in plain English.

## The idea

The classic `/apply` workflow has the AI write your documents and you review them. This workflow flips it:

1. **You draft** — in whatever tool you like
2. **The AI critiques** — numbered suggestions, and *nothing changes unless you accept it*
3. **You decide** — "apply 2 and 5", "skip the rest", or push back and discuss
4. **The AI typesets** — your words, rendered as a polished professional PDF
5. **Everything is versioned** — every round is saved; you can always go back

## Getting your draft in

Any of these work — just tell Claude which job it's for:

- **Word / Google Docs:** export or save as `.docx` and drop the file into the project (or @-mention it). Claude converts it without changing your wording.
- **Paste into chat:** paste the text and say "this is my cover letter draft for the Acme job".
- **Plain text/Markdown file:** point Claude at it.

Claude stores your draft in that job's folder under `documents/applications/<company>_<role>/drafts/`. That file is the master copy — the PDF is always generated from it, so they never drift apart.

## The commands

You don't need exact syntax — describing what you want in plain English triggers the right one. But for reference:

| Say / type | What happens |
|---|---|
| `/critique my draft for the Acme job` | Claude reviews your draft against the job posting, your real profile, and resume best practices. You get numbered suggestions with reasons. You pick which to apply. |
| `/typeset the Acme cover letter` | Your draft becomes a professionally formatted PDF. Content is untouched — if it doesn't fit the page, Claude asks before cutting anything. |
| `/typeset --all` | Renders your draft in every registered style so you can compare looks. |
| `/apply <job url> --self-draft` | The full pipeline: fit evaluation for the posting, critique of your draft, your approval of changes, PDF, and quality checks. |
| `/version save` | Saves a checkpoint of everything. |
| `/version new acme` | Starts a separate version of your documents just for the Acme application. |
| `/version history` | Shows your saved checkpoints. |
| "bring back Tuesday's version of my CV" | Claude restores it — nothing is ever lost. |

## What a critique looks like

Suggestions come numbered, each with the exact text it refers to, the proposed change, and why:

> **3. [keywords]** The posting asks for "stakeholder management" three times; your project paragraph describes it but never uses the term.
> **Where:** "coordinated with the clinical team and external vendors…"
> **Suggestion:** "managed stakeholders across the clinical team and external vendors…"
> **Why:** ATS keyword match — you genuinely do this; the posting's literal term scores better.

You reply: *"apply 1, 3, 4 — skip 2, that's not my voice"*. Claude applies exactly those, records your decisions, and never re-raises what you rejected.

Two promises the critique always keeps:

- **It never invents.** If a job asks for a skill you don't have, the suggestion is how to frame honest adjacent experience — never to claim the skill.
- **It keeps your voice.** Rewording suggestions reuse your vocabulary and rhythm, not generic AI phrasing.

## Versions, in plain English

Behind the scenes this uses git, but you never see git. The mental model:

- **Save** = a snapshot of everything, with a date and note. Take one after each critique round and each PDF.
- **A version for a job** = your own separate track of documents for one application (like "Save As", but for the whole workspace). Edits there don't affect your main documents until you fold them back in.
- **Restore** = bring any earlier snapshot back. Restoring never deletes anything — the current state is saved first.

The first time you use `/version`, Claude will ask to switch your copy to **private mode** so personal documents can be versioned. Say yes — just never publish this folder publicly afterwards (if it goes on GitHub, the repository must be set to Private).

## A typical application, end to end

1. Find a job → tell Claude the URL → it evaluates the fit honestly first
2. `/version new acme` — a fresh track for this application
3. Write your cover letter in Google Docs → export → "here's my draft"
4. `/critique` → accept/reject suggestions → repeat until you're happy
5. `/typeset` → professional PDF, quality-checked (page count, layout, ATS readability)
6. Submit it yourself on the company site
7. `/outcome acme` — logs the submission; later, log interviews or the result
8. Interview scheduled? `/interview acme` builds a prep pack

Over time the system learns from your outcomes which roles you interview well for, and its critiques get sharper.
