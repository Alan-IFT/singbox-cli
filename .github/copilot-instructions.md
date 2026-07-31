---
applyTo: "**"
---
# singbox-cli — bootstrap rules

输出语言：面向人的产出（对话、报告、README/人读文档）用**中文**，面向 agent/LLM 的产出（阶段文档、台账、规则、注释、commit）用**英文**。完整分流见 `.harness/rules/00-core.md`。

The full project ruleset lives in `AI-GUIDE.md` (root) and `.harness/rules/*.md`. **Before starting any task, read `AI-GUIDE.md` once and then selectively load only the rule fragments whose "when to read" trigger applies** — do not load all of them.

Red lines (never violate):
- Do not hand-edit `.claude/` — it is agent runtime config: `settings.json` is the live startup config (propose changes; the user applies them), `agents/`+`skills/` are sync-generated from `.harness/` (edit the source there).
- Do not edit `CLAUDE.md` or this file — static stubs, written once at init.
- Do not declare a task done until `.harness/scripts/verify_all` PASSes
- The framework agents (PM Orchestrator → … → QA) are plugin-provided to Claude Code (`harness-kit:<name>`) and are **not** available locally to Copilot — the multi-stage pipeline is a Claude Code feature. This project gives Copilot the rules (`.harness/rules/`), skills, and any project-specific partition `dev-*` agent (`.harness/agents/dev-*.md`) it can read; do not try to play a framework role from a local file (there isn't one)

This file is **static** — written once at init and intentionally minimal so it never inflates the persistent context budget. Everything else is in `AI-GUIDE.md` or `.harness/`.
