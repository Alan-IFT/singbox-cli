# ambient-reset.ps1 — Ambient-stream SessionStart reset hook for Claude Code (Windows)
#
# Invoked by .claude/settings.json hooks.SessionStart at the start of every new
# session. Deletes the ambient flag `.harness/ambient.flag` (under the nearest .git/
# ancestor of cwd) so ambient-stream mode is SESSION-SCOPED: a fresh session never
# inherits a stale ambient state. To (re-)enter ambient mode, invoke /harness-stream
# with no pool-id again. Always exits 0 (fail-open) — a reset hook must never wedge
# session startup. See skills/harness-stream/SKILL.md "Ambient mode".
#
# IMPORTANT: the .claude/settings.json command MUST pass -NoProfile, or the user's
# $PROFILE runs per session start (~3.7s p50 vs ~10ms body). See insight-index 2026-05-17.

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

# Drain stdin (the SessionStart payload JSON) — not needed; just don't block.
try { [void][Console]::In.ReadToEnd() } catch { }

# Walk up to nearest .git/ ancestor of cwd (same robust pattern as guard-rm;
# NOT $PSScriptRoot arithmetic — insight 2026-06-04).
$dir = (Get-Location).Path
$repoRoot = $null
while ($dir) {
    if (Test-Path (Join-Path $dir '.git')) { $repoRoot = $dir; break }
    $parent = Split-Path $dir -Parent
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}
if (-not $repoRoot) { exit 0 }  # no project root -> nothing to reset.

# Remove the ambient flag if present (idempotent). Never fail.
$flag = Join-Path $repoRoot '.harness/ambient.flag'
Remove-Item -LiteralPath $flag -Force -ErrorAction SilentlyContinue
exit 0
