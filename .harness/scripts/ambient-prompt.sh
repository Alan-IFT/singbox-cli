#!/usr/bin/env bash
# ambient-prompt.sh — Ambient-stream UserPromptSubmit heartbeat hook for Claude Code (Unix)
#
# Invoked by .claude/settings.json hooks.UserPromptSubmit on EVERY user turn.
# Reads the UserPromptSubmit payload JSON from stdin (and ignores it — the user's
# prompt is already in the turn). Its ONLY decision is: does the ambient flag file
# `.harness/ambient.flag` exist under the nearest .git/ ancestor of cwd?
#
#   - Flag ABSENT  -> print nothing, exit 0 (no-op; normal chat).
#   - Flag PRESENT -> print the ambient ingest+drain instruction block to stdout,
#                     exit 0. Claude Code injects a UserPromptSubmit hook's stdout
#                     into the turn as ADDED CONTEXT — that is how the agent is told
#                     to fold the message into the default pool and drain it.
#
# The hook NEVER blocks a turn — it always exits 0 (fail-open). A context-injection
# hook must never wedge the user's chat. It does NOT do the work itself; Claude is
# the worker. See skills/harness-stream/SKILL.md "Ambient mode" + .harness/rules/.

# NOTE: do NOT use `declare -a` under `set -u` — empty-array reads crash.
# Use bare `name=()` instead (insight 2026-05-16). This script uses no arrays.
set -uo pipefail

# 1. Drain stdin (the UserPromptSubmit JSON) — we don't need it; just don't block.
cat - >/dev/null 2>&1 || true

# 2. Walk up to nearest .git/ ancestor of cwd (same robust pattern as guard-rm;
#    NOT a fixed depth from $0, which is depth-sensitive — insight 2026-06-04).
dir="$PWD"
repo_root=""
while [[ -n "$dir" ]]; do
    if [[ -d "$dir/.git" ]]; then repo_root="$dir"; break; fi
    parent=$(dirname "$dir")
    if [[ "$parent" == "$dir" ]]; then break; fi
    dir="$parent"
done
[[ -z "$repo_root" ]] && exit 0  # no project root -> no-op, never block.

# 3. Flag gate. Absent -> no-op.
flag="$repo_root/.harness/ambient.flag"
[[ -f "$flag" ]] || exit 0

# 4. Flag present -> emit the ambient instruction block as added turn context.
cat <<'EOF'
[harness-kit ambient mode — ACTIVE]
.harness/ambient.flag is present, so this is an ambient-stream turn. Act per
skills/harness-stream/SKILL.md "Ambient mode" using the default pool
docs/batches/default/BATCH_PLAN.md (create it from docs/batches/_template/BATCH_PLAN.md
with an EMPTY task table if it is absent):
  1. If THIS user message reads as a requirement (not a question/aside), normalize it
     into the default pool: ONE `pending` row, or — when it bundles several independently
     verifiable deliverables — N rows per skills/harness-stream/SKILL.md "Ingest triage"
     (shared slug prefix, real `Depends on` only, union ≡ the message; Mode per row,
     default full). De-duplicate against existing slugs/goals first. If it is ambiguous,
     do not guess and do not block: record a needs-human clarification note to
     STREAM_REPORT.md "Needs your input" and keep draining. A plain question/aside creates NO row.
  2. Then drain ready tasks in topological order through pm-orchestrator, one at a time
     (serial — never parallel), best-effort, honoring the existing hard-safety stops
     (verify_all FAIL, intervention STOP, guard-rm block), until the pool is empty.
  3. Then stop and wait for the next message.
To leave ambient mode, start a new session (ambient is session-scoped — a SessionStart
hook auto-clears the flag) or delete .harness/ambient.flag. No "off" keyword needed.
EOF
exit 0
