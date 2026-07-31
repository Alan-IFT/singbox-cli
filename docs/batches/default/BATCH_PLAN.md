# Batch Plan — default

> Created: 2026-07-31
> Default mode: full
> Stop policy: strong-signal-only

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|

## Notes (optional)

- This is the **default pool** for ambient mode (`/harness-stream` with no pool-id). Rows are
  normally appended by the stream from chat requirements; you may also hand-write rows here at
  any time — hand-written rows are honored verbatim as one task and are never re-split.

## Column reference

- **ID** — pool-local identifier (`T-NN`). Does NOT collide with repo-wide `docs/tasks.md` IDs.
- **Slug** — kebab-case; becomes `docs/features/<slug>/`. Must be unique within the pool.
- **Goal** — one sentence; becomes pm-orchestrator's task-description input.
- **Mode** — `full` (default 7-stage) | `plan` (stages 1-3 only) | `goal` (Dev + QA loop).
- **Depends on** — comma-separated `T-NN` IDs in the same pool, or `—` for none.
- **Status** — `pending` | `in-progress` | `done` | `failed` | `blocked` | `needs-human` | `skipped`.
  The skill writes; the user reads.
