# ambient-prompt.ps1 — Ambient-stream UserPromptSubmit heartbeat hook for Claude Code (Windows)
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
#
# IMPORTANT: the .claude/settings.json command MUST pass -NoProfile, or the user's
# $PROFILE runs per turn (~3.7s p50 vs ~10ms body). See insight-index 2026-05-17.

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

# 1. Drain stdin (the UserPromptSubmit JSON) — we don't need it; just don't block.
try { [void][Console]::In.ReadToEnd() } catch { }

# 2. Walk up to nearest .git/ ancestor of cwd (same robust pattern as guard-rm;
#    NOT $PSScriptRoot arithmetic, which is depth-sensitive — insight 2026-06-04).
$dir = (Get-Location).Path
$repoRoot = $null
while ($dir) {
    if (Test-Path (Join-Path $dir '.git')) { $repoRoot = $dir; break }
    $parent = Split-Path $dir -Parent
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}
if (-not $repoRoot) { exit 0 }  # no project root -> no-op, never block.

# 3. Flag gate. Absent -> no-op.
$flag = Join-Path $repoRoot '.harness/ambient.flag'
if (-not (Test-Path -LiteralPath $flag)) { exit 0 }

# 4. Flag present -> emit the ambient instruction block as added turn context.
$msg = @'
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
'@
# Emit as raw UTF-8 bytes so non-ASCII punctuation in the block is never re-encoded
# through the host ANSI codepage (pwsh inherits GB2312/GBK on zh-CN Windows, which a
# UTF-8 consumer then reads as mojibake). insight-index 2026-06-12. The try/catch keeps
# the hook fail-open: it must always exit 0 and never wedge the user's chat.
try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg + "`n")
    $out = [Console]::OpenStandardOutput()
    $out.Write($bytes, 0, $bytes.Length)
    $out.Flush()
} catch { }
exit 0
