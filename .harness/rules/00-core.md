# singbox-cli — Project Rules

> Project type: **generic** · Stack: **Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management** · Initialized: 2026-07-31
>
> This is a project rule fragment — a **source-of-truth** file you edit directly.
> `AI-GUIDE.md` indexes it by reference; AI tools lazy-load it on demand. No sync step
> is needed for rule edits (since v0.10 rules are referenced, not composed into `CLAUDE.md`).

## 输出语言（按消费者分流）

本项目的 AI 产出**按主要消费者**分两种语言：面向人的用**中文**，面向下游 agent / LLM 的用**英文**（LLM 读英文同样顺畅，且与英文的框架内部保持一致、体积更小）。

**用中文（消费者是人）：**

- 跟用户的所有对话回复。
- 错误消息、状态 / 进度报告、给用户的解释。
- 给用户的交付总结（"交付了什么"的叙述性说明）。
- 面向人的文档：`README.md` / `README.zh-CN.md` 以及 `docs/` 下供人阅读的指南。

**用英文（消费者是下游 agent / LLM）：**

- `docs/features/<task>/` 下每份阶段文档：`01_REQUIREMENT_ANALYSIS.md` … `07_DELIVERY.md`，以及 `PM_LOG.md`。
- `docs/tasks.md`、`docs/dev-map.md`、`.harness/insight-index.md` 这些台账的追加内容。
- AI 编辑的 `.harness/agents/*.md`、`.harness/rules/*.md`、`AI-GUIDE.md`、`CLAUDE.md`。
- 代码注释、commit message。

被人和 agent 同时读的产物（阶段文档、台账、注释、commit），按"更严格的消费者"打破平局 —— 即下游 agent，因此用英文；人审阅英文同样没问题。

**不要在同一份产物里混用语言。** 即使用户用其他语言发消息，对话回复仍用中文（内部理解用户意图，输出按上面的分流规则）。

要修改语言策略，编辑 `.harness/rules/00-core.md` 的"输出语言"章节 —— 按引用生效，不需要 sync 步骤。

## How this project is developed

This repo uses the **Harness 7-agent pipeline**. Read `docs/workflow.md` before starting work.

- New feature or bug? → ask the PM Orchestrator to take it.
- Never skip the pipeline for non-trivial changes (>10 lines or any logic).
- Trivial changes (typo, comment, single-line fix) can skip agents but **must still pass `verify_all`**.

## Hard rules (red lines)

1. **No silent design drift.** If implementation must deviate from approved design, flag it in `04_DEVELOPMENT.md` as `DESIGN DRIFT`.
2. **Downstream cannot edit upstream documents.** If you see a defect upstream, propose a rollback via PM.
3. **Tests only go up.** Never delete tests to make `verify_all` pass. Obsolete tests need PM approval to remove.
4. **No secrets in code.** Use `.env` / environment variables; verify_all scans for hardcoded keys.
5. **No production-destructive actions** (drop table, force push to main, delete branches) without explicit user confirmation.
6. **Run verify_all before declaring done.** "It compiles" is not done.
7. **Edit `.harness/`, not `.claude/agents/`, `.claude/skills/`, or `CLAUDE.md`.** `.claude/agents/` and `.claude/skills/` are synced from `.harness/` — a Stop hook auto-runs `.harness/scripts/harness-sync` each session, so manual sync is rarely needed; `verify_all` catches drift if the hook didn't run. `CLAUDE.md` is a static stub written once at init. `.claude/settings.json` is live config you may hand-edit.
8. **Prefer asking the AI to edit `.harness/` rather than editing it yourself.** Examples:
   - "Add a rule: never use `MessageBox.Show`." → AI picks the right `.harness/rules/NN-*.md` (or creates a new one), edits it, the Stop hook syncs.
   - "Add a Developer partition for `apps/mobile/`." → AI creates `.harness/agents/dev-mobile.md` with correct owned-paths.
   - "Add a rule that new modules need an ADR." → AI edits the right `.harness/rules/NN-*.md`.
   This is the AI-driven path: human asks, AI edits, hooks sync. Editing files by hand is fine when convenient, but not required.

## Style / convention

- Code style is enforced by lint config in the repo (`eslint`, `ruff`, `gofmt`, etc.). Do not bypass.
- Commit messages: imperative mood, ≤72 char first line, body explains the why.
- File names: existing project convention overrides any default — match what's already there.

## What lives where

| Need | Look at |
|---|---|
| Project structure / where things go | `docs/dev-map.md` |
| What's currently being worked on | `docs/tasks.md` |
| Per-task documents | `docs/features/<task-slug>/` |
| Project SPECs / requirements | `docs/spec/` |
| The 7-agent pipeline definition | `docs/workflow.md` |
| Framework agent contracts | harness-kit plugin (`harness-kit:<name>`) |
| Partition `dev-*` agent definitions (SOT) | `.harness/agents/` |
| Project rule fragments (SOURCE OF TRUTH) | `.harness/rules/` |
| Build/test/verify procedures (SOURCE OF TRUTH) | `.harness/skills/` |
| Claude Code agent/skill binding (synced; do not hand-edit) | `.claude/agents/` + `.claude/skills/` |
| Claude Code bootstrap stub + live config | `CLAUDE.md` + `.claude/settings.json` |
| Tool binding sync (partition `dev-*` agents + `.harness/skills/` → `.claude/`) | `.harness/scripts/harness-sync.{ps1,sh}` |
| Total verification | `.harness/scripts/verify_all.{ps1,sh}` |
| Test count baseline | `.harness/scripts/baseline.json` |
| Regression task set | `evals/golden-tasks.md` |

## When in doubt

- Read `docs/dev-map.md` first — it tells you which files own which feature.
- Check `docs/tasks.md` for related historical work before starting new work.
- If a rule conflicts with the situation, **stop and ask the user**, don't improvise.
