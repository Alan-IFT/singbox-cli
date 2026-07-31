#!/usr/bin/env bash
# ambient-reset.sh — Ambient-stream SessionStart reset hook for Claude Code (Unix)
#
# Invoked by .claude/settings.json hooks.SessionStart at the start of every new
# session. Deletes the ambient flag `.harness/ambient.flag` (under the nearest .git/
# ancestor of cwd) so ambient-stream mode is SESSION-SCOPED: a fresh session never
# inherits a stale ambient state. To (re-)enter ambient mode, invoke /harness-stream
# with no pool-id again. Always exits 0 (fail-open) — a reset hook must never wedge
# session startup. See skills/harness-stream/SKILL.md "Ambient mode".

set -uo pipefail

# Drain stdin (the SessionStart payload JSON) — not needed; just don't block.
cat - >/dev/null 2>&1 || true

# Walk up to nearest .git/ ancestor of cwd (same robust pattern as guard-rm;
# NOT a fixed depth from $0 — insight 2026-06-04).
dir="$PWD"
repo_root=""
while [[ -n "$dir" ]]; do
    if [[ -d "$dir/.git" ]]; then repo_root="$dir"; break; fi
    parent=$(dirname "$dir")
    if [[ "$parent" == "$dir" ]]; then break; fi
    dir="$parent"
done
[[ -z "$repo_root" ]] && exit 0  # no project root -> nothing to reset.

# Remove the ambient flag if present (idempotent). Never fail.
rm -f "$repo_root/.harness/ambient.flag" 2>/dev/null || true
exit 0
