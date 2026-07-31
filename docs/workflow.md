# Workflow: The 7-Agent Pipeline

The standard development workflow on this repo. Every non-trivial change flows through these stages.

## Stages

```
1. requirement-analyst   →  01_REQUIREMENT_ANALYSIS.md
2. solution-architect    →  02_SOLUTION_DESIGN.md
3. gate-reviewer         →  03_GATE_REVIEW.md
4. developer             →  04_DEVELOPMENT.md  (+ code changes)
5. code-reviewer         →  05_CODE_REVIEW.md
6. qa-tester             →  06_TEST_REPORT.md  (+ test code)
7. pm-orchestrator       →  07_DELIVERY.md
```

All per-task documents live under `docs/features/<task-slug>/`.

## Roles in one line each

| Agent | One-line job |
|---|---|
| **PM Orchestrator** | Routes tasks through the pipeline. Never gives professional opinions. |
| **Requirement Analyst** | Vague request → structured, testable requirement. Lists ambiguities for the user. |
| **Solution Architect** | Requirement → technical design grounded in actual code (reuse audit mandatory). |
| **Gate Reviewer** | Last check before development. 8-dimension audit. Verifies referenced code exists. |
| **Developer** | Only agent that writes production code. Runs verify_all before declaring done. |
| **Code Reviewer** | Audits code against requirement + design, not just style. 6 dimensions, severity-rated. |
| **QA Tester** | Validates against user-observable behavior. Owns the automated test suite. |

## Rollback routing

When a stage finds an upstream defect, **the finder does not fix it**. PM routes back:

| Found by | Defect in | Route back to |
|---|---|---|
| Gate Reviewer | Requirement | requirement-analyst |
| Gate Reviewer | Design | solution-architect |
| Code Reviewer | Code | developer |
| Code Reviewer | Design (drift) | solution-architect |
| QA Tester | Code bug | developer |
| QA Tester | Untested or missing requirement | requirement-analyst |

**Three consecutive rollbacks at the same stage** → PM stops and asks the user.

## How a task starts

User describes a task to Claude Code:

```
Take this task: Add CSV export to the orders page.
```

PM Orchestrator:
1. Creates `docs/features/orders-csv-export/`.
2. Writes `INPUT.md` capturing the user's request.
3. Reads `docs/tasks.md` for related historical tasks.
4. Dispatches stage 1 via the Task tool.

Each stage produces a document. PM reads it, decides (advance / rollback / stop), writes its decision to `PM_LOG.md`, dispatches the next stage.

## Stage gates

- **Before stage 4 (development)**: gate review must be `APPROVED` (or `APPROVED WITH CONDITIONS` with conditions logged).
- **Before stage 5 (code review)**: development doc must show `verify_all PASS`.
- **Before stage 7 (delivery)**: code review and test report both `APPROVED`.

## Lightweight variants

Not every task needs the full pipeline.

| Task type | Recommended flow |
|---|---|
| Major feature / cross-cutting change | Full 7 stages |
| Medium feature, single module | Skip Gate (3) if requirement + design are tight |
| Bug fix | Root cause → developer → reviewer → tester |
| Trivial (typo, ≤10 lines) | Direct edit + verify_all |

**PM Orchestrator decides** based on user-described scope. When in doubt, prefer the full flow.

## When the pipeline stops

PM stops and asks the user when:

- Same stage rolled back 3 times.
- Conflicting requirements that the analyst cannot reconcile.
- External capability missing (e.g. an MCP server needed).
- Production-destructive action requested.

## The evolution principle

If AI keeps making the same mistake, the fix is **not** "try again". The fix is one of:

| If the mistake is… | Add / change… |
|---|---|
| A coding rule violated | A line in CLAUDE.md + a check in verify_all |
| A step forgotten | A `.claude/skills/<name>/SKILL.md` for it |
| A role overstepping or under-doing | Edit the agent definition |
| Missing external capability | An MCP server registration |
| A whole stage of the pipeline missing | Add a new agent + workflow edit |

Document changes in `CHANGELOG.md`.
