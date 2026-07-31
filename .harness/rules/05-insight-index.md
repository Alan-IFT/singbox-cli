# 05 — Cross-task insight index

## What this is

`.harness/insight-index.md` is a **≤30-line append-only file** that captures truths the project has learned the hard way — facts that would otherwise be re-discovered every time a new task starts.

Examples of good insights:
- "The legacy `users.created_at` column is `DATETIME` not `TIMESTAMPTZ` — naive UTC conversion silently shifts dates by 8h in CI."
- "Build under WSL fails with `ENOSPC` if more than 4 watchers open; we use `chokidar.useFsEvents: false` in dev."
- "Vendor SDK v2.7.1 returns `null` instead of throwing for invalid keys — wrap every call in an explicit null check."

These aren't rules (no "thou shalt"). They aren't bug reports either (which sit in tasks). They're the hard-won project-specific facts that should never be forgotten and never be re-derived.

## When to read this

**At the start of any task that involves design or implementation decisions.** Skim it before reading other rule fragments — if an entry applies, you save yourself a wrong assumption.

Skip for: pure typo fixes, comment cleanup, dependency version bumps with no other change.

## When to write to this

After completing a task, if the work uncovered a non-obvious truth that the next person (or AI) would hit too, append one line:

```markdown
- YYYY-MM-DD · <one-sentence fact> · evidence: <task-slug or commit-sha>
```

**Rules for writing**:
- Maximum 30 lines total. If you must add one and the file is full, **archive the oldest line** (move it to `docs/features/_archived/insight-history.md`) before appending.
- One line, one fact. If you need a paragraph, the entry is too vague.
- Always include evidence (a task slug or commit SHA) so future readers can trace the truth.
- **Adversarial test**: before writing, ask "would someone reasonable, reading the codebase fresh, derive this in under 10 minutes?" If yes, don't write it — it's not insight, it's just documentation.

## When NOT to write

- Bug reports (those go in tasks)
- Rules / conventions (those go in `00-core.md` or new rule fragments)
- "Best practice" assertions (the codebase or `.harness/rules/` are the place)
- Task summaries (those live in `docs/features/<task-slug>/`)

Insight is **discovered fact that beat someone's prior**, not "we decided X" and not "X is documented".

## Archival

The PM Orchestrator runs `.harness/scripts/archive-task` at the end of every task, which:
1. If the task's final 07_DELIVERY.md contained an `## Insight` section, appends its lines to `.harness/insight-index.md`.
2. Moves the task's 7 stage documents to `docs/features/_archived/<task-slug>/summary.md` (compressed to one file) + keeps the raw 7 files alongside.
3. If `.harness/insight-index.md` exceeds 30 lines, rotates the oldest to `docs/features/_archived/insight-history.md`.

The archive script never deletes — it only moves and compresses. Original task documents are always recoverable from `_archived/`.
