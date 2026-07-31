# 70 — Document size policy

## What this is

Soft caps on the size of long-lived and per-task documents, so AI tools don't burn
context budget reading bloated files. **WARN-level**, surfaced by `verify_all`'s
`F.*` group.

The rule has two halves: **size caps** (the numeric budget) and **process
discipline** (how to live under the cap without losing information).

## When to read this

- Before adding a new rule fragment or agent definition.
- Before pasting evidence into a stage doc (`01_*.md`…`07_*.md`) or `PM_LOG.md`.
- When `verify_all` flags an `F.*` WARN.

## Caps

| Document | Cap | Why this number | If exceeded |
|---|---|---|---|
| `AI-GUIDE.md` | 200 lines | Always-on entry; reread every task. | Trim to index-only; move prose to `docs/concepts.md` or similar |
| `CLAUDE.md` | 50 lines | Static bootstrap stub; not a content destination. | Move content into `.harness/rules/*.md` |
| `.harness/rules/*.md` (each) | 200 lines | Loaded selectively; should fit comfortably with 2–3 siblings. | Split into `70a-…` / `70b-…` with distinct triggers |
| `.harness/agents/*.md` (each) | 300 lines | Loaded when the agent is dispatched. | Refactor responsibilities, or move stable doc to `docs/` |
| `.harness/insight-index.md` | 30 lines | Loaded at every task start by PM. | `.harness/scripts/archive-task` auto-rotates oldest to `docs/features/_archived/insight-history.md` |
| `docs/tasks.md` | 300 lines | Loaded at every task start by PM. | Move oldest Completed rows to `docs/tasks-archive.md` (manual today; tooling later) |
| Per-task `PM_LOG.md` | 500 lines | PM rereads for resume; downstream agents read for context. | "Compaction" pattern below |
| Per-task stage doc (`0[1-7]_*.md`) | 500 lines each | Read by the next stage's agent. | "Reference, don't paste" pattern below |

## Process discipline

### Rule 1 — Reference, don't paste

Stage-doc authors (Architect, Developer, QA especially) MUST cite code by
`path/to/file.ts:42-58` instead of pasting the lines verbatim.

Two reasons:
- A citation refers to the **current** code; a paste decays as the codebase evolves.
- A 16-line snippet pasted costs 16+ lines of doc; the same citation costs one.

When raw evidence is genuinely necessary (an extracted error message, a config
fragment that doesn't live in repo) keep it to **≤5 lines**.

### Rule 2 — PM_LOG.md compaction at the cap

If an active task's `PM_LOG.md` is approaching 500 lines (mostly a `goal`-mode
risk), PM compacts:

1. Identify "stably past" stages (current stage = N; stages 1..N-2 are stably past).
2. Prepend `## Compacted stages 1..N-2 (YYYY-MM-DD)` with **one-line summaries** of each.
3. Delete the verbose entries for those stages from the body.
4. Keep the last 2 stages' entries full and chronological.

Compaction is PM-owned. Never delegate to a downstream agent (they're reading
the file). Do not compact mid-stage — only at stage boundaries.

### Rule 3 — `docs/tasks.md` rotation

When the Completed table exceeds ~30 rows, move the oldest 50% to
`docs/tasks-archive.md`. Keep the active table small so PM's task-start read is
cheap. (Manual today; a `scripts/compact-tasks` may land in a later release.)

### Rule 4 — Always archive completed tasks

The single biggest size guardrail: run `.harness/scripts/archive-task --task <slug>` on
every completed `full` / `goal` task. It:

- Harvests `## Insight` lines from `07_DELIVERY.md` into `.harness/insight-index.md` (auto-rotates overflow).
- Moves stage docs + `PM_LOG.md` to `docs/features/_archived/<slug>/`.

Skipping `archive-task` is the **#1 cause of long-term bloat** — insight-index
fills up manually, stage docs pile under `docs/features/`, and verify_all's size
checks start firing a month later.

PM is responsible for triggering archive at end of full/goal mode
(see `pm-orchestrator.md` step 10).

## Adversarial check

Before adding a new section to ANY of the docs above, ask:

> Would a future AI tool, loading this file fresh, need this content to make
> a decision in the next 10 minutes?

- **Yes** → write it.
- **Nice to have** → write it under `docs/concepts.md` or `docs/_archived/`, not in the index.
- **One-time observation about a task** → write it in a stage doc that gets archived.

The cap is a budget. Cuts are made by removing what doesn't earn its line, not
by mechanical truncation.
