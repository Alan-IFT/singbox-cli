# AI-GUIDE — singbox-cli project index

> Tool-agnostic entry. Any AI tool (Claude Code, GitHub Copilot, Cursor, …) reads this **before starting a task**.

## Project

Type: **generic** · Stack: **Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management** · Initialized: 2026-07-31

This project uses the **Harness 7-agent pipeline**: PM Orchestrator → Requirement Analyst → Solution Architect → Gate Reviewer → Developer → Code Reviewer → QA Tester.

## Source of truth (in this repo, version-controlled)

- `.harness/rules/*.md` — rule fragments
- the 7 framework agents (+ supervisor) are **plugin-provided** by harness-kit (dispatched as `harness-kit:<name>`)
- `.harness/agents/*.md` — only project-specific partition `dev-*` agents (if any)
- `.harness/skills/*/SKILL.md` — standard procedures (build / test / verify)

**Do not directly edit** `.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md` — they are tool-specific stubs or generated bindings.

## Rule fragments (read by "when to read")

- **`.harness/rules/00-core.md`** (**always**): 7-stage pipeline, hard rules, default output formats
- **`.harness/rules/05-insight-index.md`** (**at the start of design/implementation tasks**): how cross-task hard-won truths are captured; check `.harness/insight-index.md` before deciding anything non-trivial
- **`.harness/rules/25-decision-policy.md`** (**load when you would ask the user / call `AskUserQuestion`**): the decision & escalation policy — Mode 1 (human decides, **the default for new projects**) vs Mode 2 (preset-rubric autonomy) vs Mode 3 (your custom rubric) + the always-escalate red lines. Switch modes with `/harness-decision-mode`.
- **`.harness/rules/50-singbox-cli.md`** (**when touching code**): project-type overlay, partitioning, stack conventions <!-- ai-native-init: when /harness-init Q6 = Yes, the skill's step 5b.8 Edits this line to point at `50-<project-slug>.md` instead -->
- **`.harness/rules/60-tool-handoff.md`** (**when switching Claude Code ↔ Copilot**): state lives in files, not chat memory
- **`.harness/rules/65-intervention.md`** (**when running, observing, or redirecting any `/harness*` task**): `.harness/intervention.md` is a single-shot signal file (STOP / REDIRECT / SKIP / NOTE) that PM consumes at every stage boundary
- **`.harness/rules/70-doc-size.md`** (**when adding or reviewing long-lived docs, or when `verify_all` flags an `F.*` WARN**): soft caps on AI-GUIDE / rules / agents / insight-index / tasks.md / per-task docs; "reference don't paste" + PM_LOG compaction + always-archive discipline
- **`.harness/rules/75-safety-hook.md`** (**when running, observing, or disabling the destructive-command guardrail**): `PreToolUse` hook on Bash tool calls; blocks destructive commands targeting paths outside the `.git/` ancestor of cwd; override `HARNESS_ALLOW_OUTSIDE_RM=1`.
- **`.harness/rules/80-delivery-policy.md`** (**at delivery time, or before any `git commit` / `git push`**): the owner durably authorized automatic commit + push directly to `main` on `origin` (a public repo) — do not re-confirm per task; includes the preconditions that block a commit and the operations that are never automatic (force-push, history rewrite, tags/releases).
- **`.harness/rules/85-design-discipline.md`** (**at stage 2 design and stage 3 gate review, and before splitting one requirement into several tasks**): the owner's 「优先用好的设计，避免不断的修修补补」 directive — find the abstraction behind a symptom list instead of implementing the list; two tests for a patch-then-patch seam; plus the counter-rule that this is not a license to over-build or widen scope.
- **`.harness/rules/_ai-native-prompt.md`** (**reference only — only read if customizing the AI-native init/adopt drafting prompt**): canonical prompt the `/harness-init` step 5b and `/harness-adopt` step 4b hand to the orchestrator model when drafting a tailored `50-<project-slug>.md`. Not a runtime rule; the leading `_` marks it as documentation.

If you add a new fragment, append a line above with its filename, a 1-line description, and the trigger condition.

**Memory layer**:
- **`.harness/insight-index.md`** — ≤30 evidence-backed lines of project-specific facts. Read at task start; append at task end (only with evidence).
- **`.harness/decision-rubric.md`** — the principles the AI decides by under Mode 2 (Preset) / Mode 3 (Custom); read at every escalate-or-decide point (see `.harness/rules/25-decision-policy.md`). Edit to widen / narrow autonomy.

## Skills (standard procedures, invoked per task type)

- **`.harness/skills/build/`**: compile / package commands
- **`.harness/skills/test/`**: test runner
- **`.harness/skills/verify/`**: total verification gate (`.harness/scripts/verify_all`)

## Agents

The 7 framework agents are provided by the harness-kit plugin — dispatch as `harness-kit:<name>`; only partition `dev-*` agents live in `.harness/agents/`. Read a contract on demand when assuming or dispatching to a role.

- `harness-kit:pm-orchestrator` — takes new tasks, routes
- `harness-kit:requirement-analyst` — writes `01_REQUIREMENT_ANALYSIS.md`
- `harness-kit:solution-architect` — writes `02_SOLUTION_DESIGN.md`
- `harness-kit:gate-reviewer` — writes `03_GATE_REVIEW.md`
- `harness-kit:developer` (or project-local partitions: `dev-frontend` / `dev-backend` / `dev-db` / `dev-api` / `dev-services`) — writes `04_DEVELOPMENT.md`
- `harness-kit:code-reviewer` — writes `05_CODE_REVIEW.md`
- `harness-kit:qa-tester` — writes `06_TEST_REPORT.md`

**Claude Code sub-agent dispatch — already implemented.** PM Orchestrator uses Claude Code's `Task` tool to spawn each downstream role in its own context (`harness-kit:<name>`); see the `harness-kit:pm-orchestrator` contract for the exact dispatch contract. Non-Claude tools (Copilot/Cursor) are not currently first-class for the framework agents (they're plugin-provided).

## AI tool flow modes

Three flows are supported, picked by the tool the user is in:

- **Claude Code automatic sub-agent dispatch** (default for Claude Code): PM Orchestrator hands off through stages 1 → 7 via the `Task` tool; no user intervention required between stages.
- **Non-Claude tools (Copilot / Cursor)**: the framework agents are **plugin-provided** (dispatched by Claude Code as `harness-kit:<name>`); non-Claude framework-agent support is **not currently first-class**. Project-local partition `dev-*` agents in `.harness/agents/` remain readable by any tool.

## Project documents

- `docs/workflow.md` — full 7-stage pipeline definition
- `docs/tasks.md` — current task board
- `docs/dev-map.md` — project navigation
- `docs/features/<task-slug>/` — per-task stage documents
- `docs/spec/` — project specs
- `evals/golden-tasks.md` — regression task set

## Workflow entry — pick the right mode

| Mode | Use when (English triggers) | Use when (中文触发) | Skill |
|---|---|---|---|
| Full 7-stage pipeline | "Add X" / "Fix bug Y" / "Refactor Z" — real shipping work | "加一个 ..." / "修个 bug" / "重构 ..." | `/harness` |
| Plan only (stages 1-3) | "Vet this design" / "evaluate the approach" / "先别动手" | "评审一下..." / "先别动手" / "设计上行不行" | `/harness-plan` |
| Explore / feasibility | "Can we do X?" / "Is library Y feasible?" — research | "能不能..." / "可行吗" / "调研一下" | `/harness-explore` |
| Goal loop (Dev + QA) | "Keep improving until X" / "iterate to N% coverage" | "持续优化到..." / "循环改进直到..." | `/harness-goal` |
| Trivial | Typo, comment, single-line dependency bump | typo / 注释 / 改个变量名 | Direct edit + `.harness/scripts/verify_all` |
| Mid-task redirect | "stop the pipeline" / "tell dev to skip X" / "leave a note for QA" | "停一下" / "让 dev 别动 X" / "顺便告诉 QA…" | `/harness-intervene` |

Declare-done gate: `.harness/scripts/verify_all` PASS + (if 7-stage or goal) QA's `06_TEST_REPORT.md` has an `## Adversarial tests` section.

When a task is complete, run `.harness/scripts/archive-task --task <task-slug>` to harvest its insights (from the `## Insight` section of `07_DELIVERY.md`) into `.harness/insight-index.md` and move the stage docs to `docs/features/_archived/`.

## Editing rules

- To change a rule: edit the relevant `.harness/rules/*.md` fragment. If you add a new fragment, append an index line above.
- To change an agent: edit `.harness/agents/<name>.md`. Then run `.harness/scripts/harness-sync` so the change reaches `.claude/agents/` (Claude Code requires that path).
- To change a skill: edit `.harness/skills/<name>/SKILL.md`. Same sync applies.

No automatic regeneration of this file or of `CLAUDE.md` / `.github/copilot-instructions.md` — they reference `.harness/`; updates flow by reference, not by re-composition.
