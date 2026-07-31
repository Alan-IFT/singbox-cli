# Batch Plan — <batch-id>

> Created: YYYY-MM-DD
> Default mode: full
> Stop policy: strong-signal-only

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|
| T-01 | <kebab-case-slug> | <one-sentence goal that becomes pm-orchestrator's task description> | full | — | pending |
| T-02 | <kebab-case-slug> | <one-sentence goal> | full | — | pending |
| T-03 | <kebab-case-slug> | <one-sentence goal> | full | T-01 | pending |

## Notes (optional)

- Use this section for any human context the AI needs but that doesn't fit in the per-task goal cell (e.g. "T-03 must wait for T-01 because both touch the same `apps/web/middleware.ts` file").
- Order in the table is the **preferred** execution order; the skill honors `Depends on` to compute the actual topological order.

## Column reference

- **ID** — batch-local identifier (`T-NN`). Does NOT collide with repo-wide `docs/tasks.md` IDs.
- **Slug** — kebab-case; becomes `docs/features/<slug>/`. Must be unique within the batch.
- **Goal** — one sentence; becomes pm-orchestrator's task-description input.
- **Mode** — `full` (default 7-stage) | `plan` (stages 1-3 only) | `goal` (Dev + QA loop).
- **Depends on** — comma-separated `T-NN` IDs in the same batch, or `—` for none.
- **Status** — `pending` (initial) | `in-progress` | `done` | `failed` | `blocked` | `needs-human` (deferred — `/harness-stream` set it aside pending the human input recorded in `STREAM_REPORT.md` "Needs your input"; re-runs on resume once you answer) | `skipped`. The skill writes; the user reads.
- **What makes a good row** — each row should be a tracer-bullet vertical slice (a thin end-to-end change, independently verifiable, NOT a horizontal layer) sized to the smart zone (~120k-token reasoning window). See `harness-plan` → "Task-decomposition discipline".

## How to invoke

1. Copy this whole `docs/batches/_template/` folder to `docs/batches/<your-batch-id>/`.
2. Replace `<batch-id>` and the example task rows.
3. Run `/harness-kit:harness-batch <your-batch-id>`.

See `docs/batches/README.md` for the lifecycle and `skills/harness-batch/SKILL.md` for the full procedure.
