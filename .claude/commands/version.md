# /version - Plain-Language Version Control (Git, Fully Agent-Managed)

You are the version-control layer for a user who **does not know git and should never need to**. Every git mechanic — commits, branches, checkouts, restores — is executed by you and described in plain language. The user thinks in terms of "save my progress", "start a version for the Acme job", "go back to yesterday's cover letter"; you translate.

`$ARGUMENTS` contains a subcommand or a natural-language request. Map natural language onto the closest subcommand — the user will rarely type the exact forms below.

---

## Subcommands

| User intent | Subcommand | Git underneath |
|---|---|---|
| "Where am I? What's unsaved?" | *(none)* / `status` | `git status`, `git branch --show-current`, `git log` |
| "Save my progress" | `save [note]` | `git add <relevant> && git commit` |
| "Start a version for the Acme job" | `new <company> [role]` | `git checkout -b application/<company>-<role>` |
| "Switch to the Acme application" / "back to main" | `switch <name>` | auto-save, then `git checkout` |
| "What versions/saves do I have?" | `history [file]` | `git log --oneline --follow` |
| "Bring back yesterday's version of my CV draft" | `restore <description>` | `git checkout <commit> -- <path>` |
| "Fold the Acme work back into main" | `merge <name>` | `git merge` from master |

---

## Step 0: Private-Mode Check (runs before any subcommand)

The public framework gitignores all personal data (`documents/**` contents, `cv/main_*.tex`, `cover_letters/cover_*.tex`, `job_search_tracker.csv`, PDFs). Version control of application work is impossible until this instance is switched to **private mode**.

Check: `git check-ignore -q documents/applications/x 2>/dev/null; echo $?` (0 = still ignored → private mode is OFF).

If OFF, explain and ask once:

> This copy of the framework currently keeps your personal documents **out** of version control (that's the right default for the public template, since it protects against accidentally publishing personal data). To version your drafts and applications, I need to switch this copy to **private mode**.
>
> ⚠️ After this switch, your CVs, cover letters, and application history are stored in the git history. That is exactly what you want for a private repo — but this repo must **never** be pushed anywhere public afterwards. If it lives on GitHub, the repository must be Private.

On consent, append to `.gitignore`:

```gitignore
# ── PRIVATE INSTANCE (added by /version) ─────────────────────────
# This copy versions personal data. NEVER push it to a public remote.
!documents/cv/**
!documents/linkedin/**
!documents/diplomas/**
!documents/references/**
!documents/applications/**
!cv/main_*.tex
!cover_letters/cover_*.tex
!cover_letters/Cover_*.tex
!job_search_tracker.csv
!upskill/*.md
!documents/**/*.pdf
!cv/main_*.pdf
!cover_letters/*.pdf
```

Then commit the `.gitignore` change itself, and verify a remote check: if `git remote -v` shows a public-looking remote (the upstream framework repo), warn the user to change it to their own private repo before any push, and never push without being asked.

If the user declines private mode, say that `/version` can't operate and stop.

---

## Behavior per Subcommand

### `status` (default)

Report in plain language, no git jargon: which application (branch) is active — `master` is called "main workspace", `application/acme-ml-engineer` is called "the Acme — ML Engineer application"; what has changed since the last save (name the documents, not the paths: "your Acme cover letter draft has unsaved changes"); the last few saves with dates.

### `save [note]`

1. `git status --porcelain` to see what changed. If nothing: say so, done.
2. Stage the changed files relevant to the job-search workflow (drafts, reviews, tex/pdf outputs, tracker, profile skill files, posting archives). List anything unexpected (code changes, config) and ask before including it.
3. Commit with a descriptive message: `save(<context>): <note or auto-summary>` — e.g. `save(acme): critique round 2 applied to cover letter`. Auto-summarize from the diff if the user gave no note.
4. Confirm in plain language: "Saved. You can always come back to this state."

### `new <company> [role]`

1. If there are unsaved changes, `save` them first (tell the user).
2. Branch name: `application/<company>-<role>`, lowercase, hyphens. Create with `git checkout -b` **from master** (ask if they'd rather branch from the current application).
3. Explain the model once, simply: "You now have a separate version of everything for the Acme application. Changes here won't affect your main workspace or other applications until we fold them back in."

### `switch <name>`

1. Auto-`save` any pending changes on the current branch first — **never** switch with a dirty tree.
2. Fuzzy-match the name against existing `application/*` branches and `master`. Ambiguous → list matches and ask.
3. `git checkout`, then a one-line orientation: which application is now active and its last save.

### `history [file]`

Show saves as a plain-language table: date, context, what changed (from the commit message). With a file/document argument, use `--follow` on the resolved path. Offer: "Say `restore` with a date or description to bring any of these back."

### `restore <description>`

1. Find the target commit from the description (`git log --grep`, dates, or show recent history and ask).
2. **Always show what will happen before doing it**: which document(s), restored to which date's state, and that the current state gets saved first so nothing is lost.
3. Auto-`save` current state, then restore **paths** (`git checkout <commit> -- <path>`), commit as `restore(<context>): <doc> back to <date>`.
4. Never use `git reset --hard`, never delete history, never force-push. Restores are always *forward* commits that bring old content back — the timeline is append-only.

### `merge <name>`

1. From master (switch there first, auto-saving), `git merge application/<name>`.
2. On conflicts: resolve document conflicts by asking the user which version of the conflicted text to keep (show both in plain language, not conflict markers).
3. Suggest keeping the application branch until the application is resolved (`/outcome`), then offer to clean it up.

---

## Integration Points (for other commands)

`/critique`, `/typeset`, and `/apply --self-draft` suggest `/version save` at their natural checkpoints. When executing those suggestions, use the contexts: `critique round applied`, `typeset output`, `application submitted`. A sensible rhythm the agent should encourage unprompted: one save per critique round, one per typeset, one on submission.

---

## Hard Safety Rules

1. **Never push** unless the user explicitly asks, and never to a remote that isn't confirmed private.
2. **Never destructive**: no `reset --hard`, no branch deletion without confirmation, no history rewriting. Restore = new commit.
3. **Never switch branches over unsaved changes** — auto-save first, every time.
4. **Plain language always**: the words "commit", "branch", "checkout", "HEAD", "merge conflict" don't appear in user-facing output unless the user uses them first. Say "save", "version for the Acme job", "switch to", "both versions changed the same paragraph — which do you want?".
5. **Commits attribute normally** — end commit messages with the standard Claude Code co-author line.
