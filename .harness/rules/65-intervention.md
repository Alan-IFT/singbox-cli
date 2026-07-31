# 65 — Mid-task intervention protocol

## What this is

`.harness/intervention.md` is a **single-shot signal file** the human (or another tool) can drop to redirect, pause, or annotate an in-flight 7-stage task. The PM Orchestrator reads it at each stage boundary, logs the consumption into `PM_LOG.md`, then **deletes the file** — presence = "unread", absence = "no pending intervention".

Think of it as a tool-agnostic soft Ctrl-C for long autonomous runs: write a file, the next stage transition picks it up. No process kill, no chat-window race. Works the same across Claude Code, Copilot, Cursor, or human-to-PM handoff.

## File location

Always at repo root: `.harness/intervention.md`. Never inside `docs/features/<task>/` — task-scoping is automatic because the PM only reads it during an active task.

## Read points (PM Orchestrator)

1. Right after `docs/features/<task>/PM_LOG.md` is created (before stage 1).
2. After **every** stage completion, before deciding the next route.
3. At the start of each iteration in `goal` mode.

## File schema (freeform-with-hints)

Body is freeform markdown — PM uses normal LLM understanding. Optional first-line hint disambiguates:

```markdown
# Intervention

STOP — <reason for user-visible halt>
```

```markdown
# Intervention

REDIRECT 04 — Skip the websocket layer, ship REST first; we'll do WS in a follow-up.
```

```markdown
# Intervention

NOTE — DB is being rotated this afternoon; gate any migrations behind --dry-run.
```

Recognized keywords (case-sensitive, must follow the `# Intervention` header):

| Keyword | PM action |
|---|---|
| `STOP` | Halt pipeline, log to PM_LOG, surface to user. Do not auto-resume. |
| `REDIRECT <stage>` | Override stage `<stage>`'s brief; if already past, route back. Log rationale. |
| `SKIP <stage>` | Skip the named stage with given rationale. Allowed only for stages 5 and 6. Skipping 3 (gate) is forbidden. |
| `NOTE` | Acknowledge in PM_LOG, attach to next dispatch prompt, continue. |
| (no keyword) | `NOTE` if benign, `STOP` if ambiguous/consequential. Surface to user when in doubt. |

Stage numbers reference `pm-orchestrator.md` (`01` = requirement analysis … `07` = delivery).

## PM consumption protocol

1. Copy full content into the active task's `PM_LOG.md` under `## Intervention consumed at <ISO timestamp>`.
2. Take the implied action.
3. Delete `.harness/intervention.md` (purpose fulfilled; staleness would cause re-application).
4. Continue routing as adjusted, or halt if STOP.

If no task is active, PM leaves the file alone — it's addressed to whoever runs the next task.

## Who writes intervention.md

- The human, by hand or via `/harness-intervene` (writes a template skeleton).
- Another AI tool session redirecting an in-flight pipeline.
- **Never an agent inside the pipeline.** Agents use stage docs + BLOCKED markers; intervention.md is the human-or-out-of-band side channel.

## What NOT to put here

- Permanent rules → new `.harness/rules/*.md` fragment.
- Cross-task insight → `## Insight` in `07_DELIVERY.md`.
- Bug reports → `docs/tasks.md`.

Intervention is **transient task-scoped redirection only**. If the same intervention shows up twice, it's a candidate for a permanent rule.

## Gitignore

Add `.harness/intervention.md` to `.gitignore` — it's ephemeral and should not be committed. If a tracked copy exists, verify_all warns.
