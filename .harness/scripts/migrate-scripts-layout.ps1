# migrate-scripts-layout.ps1 — One-shot upgrade: scripts/ -> .harness/scripts/ (T-007)
#
# For an already-initialized Harness project that placed its harness-owned scripts
# under scripts/ (the pre-T-007 layout). Moves the known harness-owned scripts to
# .harness/scripts/ and rewires the two hook command strings in .claude/settings.json.
#
# Idempotent: safe to run repeatedly. A second run is a clean no-op (exit 0).
# Only the KNOWN harness-owned set is touched — your own scripts/<custom> files
# are never moved.
#
# Usage:
#   pwsh -File .harness/scripts/migrate-scripts-layout.ps1            # migrate
#   pwsh -File .harness/scripts/migrate-scripts-layout.ps1 -DryRun    # print plan, change nothing
#   pwsh -File .harness/scripts/migrate-scripts-layout.ps1 -Force     # overwrite existing targets
#
# Exit codes:
#   0  migrated, or already migrated / nothing to do
#   1  user error (not a Harness project — no .claude/settings.json)
#   4  end-state assertion failure (T-020): a wired hook command references (or, in
#      dry-run, would reference) a missing script, or a move did not land.
#      Remediation: run /harness-upgrade to re-land current scripts + rewire hooks.

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Get-ResilientCmd <tool> <isWindows> — return the T-12 RESILIENT hook command string,
# JSON-escaped (inner " as \"). Convenience hooks (harness-sync) fail-OPEN + anchored to
# $CLAUDE_PROJECT_DIR; guard-rm (safety) fail-CLOSED (no exit-0 fallback). The space-
# preceded bare `.harness/scripts/<tool>.<ext>` token survives so the unchanged left-
# bounded congruence regex still parses + existence-checks it (OQ-3a).
function Get-ResilientCmd($tool, $forWin) {
    if ($forWin) {
        if ($tool -eq "guard-rm") {
            return ('pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/{0}.ps1\"' -f $tool)
        } else {
            return ('pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/{0}.ps1 -PathType Leaf) {{ & pwsh -NoProfile -File .harness/scripts/{0}.ps1 }}; exit 0\"' -f $tool)
        }
    } else {
        if ($tool -eq "guard-rm") {
            return ('sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/{0}.sh''' -f $tool)
        } else {
            return ('sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/{0}.sh ] && exec bash .harness/scripts/{0}.sh || exit 0''' -f $tool)
        }
    }
}

# Run from the project root (the directory that contains .claude/ and scripts/).
$root = (Get-Location).Path
$settings = Join-Path $root ".claude/settings.json"
$srcDir = Join-Path $root "scripts"
$dstDir = Join-Path $root ".harness/scripts"

if (-not (Test-Path $settings)) {
    [Console]::Error.WriteLine("migrate-scripts-layout: no .claude/settings.json found at $settings.")
    [Console]::Error.WriteLine("  Run this from the root of an initialized Harness project.")
    exit 1
}

# The known harness-owned movable set (filename-preserved). NOT a blanket scripts/*.
# verification_history.log is intentionally excluded — it regenerates at the new path.
$known = @(
    "verify_all.ps1", "verify_all.sh",
    "harness-sync.ps1", "harness-sync.sh",
    "guard-rm.ps1", "guard-rm.sh",
    "install-hooks.ps1", "install-hooks.sh",
    "archive-task.ps1", "archive-task.sh",
    "baseline.json"
)

$inGit = (Test-Path (Join-Path $root ".git"))
$plan = @()
$plannedMoves = @()
$moveFailed = $false

foreach ($name in $known) {
    $src = Join-Path $srcDir $name
    $dst = Join-Path $dstDir $name

    if (-not (Test-Path $src)) {
        # Source absent: either already migrated (dst present) or not part of this project.
        continue
    }
    if ((Test-Path $dst) -and -not $Force) {
        $plan += "SKIP  scripts/$name (already present at .harness/scripts/$name; use -Force to overwrite)"
        continue
    }
    $plan += "MOVE  scripts/$name -> .harness/scripts/$name"
    $plannedMoves += $name
    if (-not $DryRun) {
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        $tracked = $false
        if ($inGit) {
            git ls-files --error-unmatch "scripts/$name" *> $null
            $tracked = ($LASTEXITCODE -eq 0)
        }
        if ($tracked) {
            if ($Force -and (Test-Path $dst)) { Remove-Item $dst -Force }
            git mv -f "scripts/$name" ".harness/scripts/$name" | Out-Null
        } else {
            Move-Item -Path $src -Destination $dst -Force
        }
        # Move verification (T-020 / FR-P2): a failed git mv / Move-Item must not pass
        # silently. A failed move leaves the source in place, so the presence-gated
        # settings rewire below simply stays OFF for that variant — no new dangle is
        # ever created by a failed move; the run is marked incongruent and exits 4.
        if (-not (Test-Path $dst)) {
            $plan += "MOVE-FAILED  scripts/$name (move did not land — see git output above)"
            $moveFailed = $true
        }
    }
}

# Settings rewire — surgical case-sensitive substring replace on the RAW text.
# Never re-serialize: that would reorder keys and strip the _comment / _doc_sync_hook
# documentation keys. We replace ALL occurrences of the harness command path
# prefixes, which covers the Stop command, the PreToolUse command, the
# permissions.allow entry, AND the _doc_sync_hook doc string.
# T-020 (RC-1 fix): each of the four {harness-sync,guard-rm} x {ps1,sh} variants is
# rewired ONLY when its target is (projected) present at .harness/scripts/ — a rewire
# can no longer point a hook at a file that never landed. The unconditional double-
# prefix collapse stays last, so the transform remains a fixed point.
# Known cosmetic nuance (gate F-4): when only ONE shell variant's target is present,
# doc strings that mention both variants end half-migrated (the absent variant keeps
# the old path). Idempotent and harmless — the congruence scan below only checks
# "command" lines, never doc keys.
$raw = Get-Content $settings -Raw
$new = $raw
foreach ($toolExt in @("harness-sync.ps1", "harness-sync.sh", "guard-rm.ps1", "guard-rm.sh")) {
    $targetPresent = (Test-Path (Join-Path $dstDir $toolExt)) -or
                     ($DryRun -and ($plannedMoves -ccontains $toolExt))
    if ($targetPresent) {
        $new = $new.Replace("scripts/$toolExt", ".harness/scripts/$toolExt")
    }
}
# Collapse any double prefix produced when an already-migrated `.harness/scripts/...`
# substring matched the `scripts/...` replace target. This makes the transform a
# true fixed point: running it on already-migrated text yields the same text.
$new = $new.Replace(".harness/.harness/scripts/", ".harness/scripts/")

# Brittle -> resilient rewrite (T-12 / A8, design §4.3). The prefix rewire above only
# adds `.harness/`; it does NOT make the hook fail-open/closed + $CLAUDE_PROJECT_DIR-
# anchored. For each {tool}x{ext}, if the `.harness/`-prefixed brittle command VALUE is
# present verbatim AND its target is (projected) present, swap the WHOLE value for the
# OS-picked resilient string. Ordinal .Replace (R1). Double-quote-bounded needle ->
# idempotent (a second run sees the resilient value, not the bare brittle "command", so
# no .bak churn — B10) and gated on target-present so a brittle command pointing at a
# missing script is left for the terminal scan to flag. R4: only harness tool names.
foreach ($s32Tool in @("harness-sync", "guard-rm", "ambient-prompt", "ambient-reset")) {
    foreach ($s32Ext in @("ps1", "sh")) {
        $s32Target = "$s32Tool.$s32Ext"
        $s32Present = (Test-Path (Join-Path $dstDir $s32Target)) -or
                      ($DryRun -and ($plannedMoves -ccontains $s32Target))
        if (-not $s32Present) { continue }
        if ($s32Ext -eq "ps1") {
            $s32Brittle = "pwsh -NoProfile -File .harness/scripts/$s32Target"
            $s32Win = $true
        } else {
            $s32Brittle = "bash .harness/scripts/$s32Target"
            $s32Win = $false
        }
        $s32Needle = '"' + $s32Brittle + '"'
        if ($new.Contains($s32Needle)) {
            $s32Cmd = Get-ResilientCmd $s32Tool $s32Win
            $new = $new.Replace($s32Needle, ('"' + $s32Cmd + '"'))
        }
    }
}

# Only an actual content change counts as needing a settings write (idempotent:
# already-migrated text is a fixed point -> $new -ceq $raw -> no .bak, no write).
$needsSettings = ($new -cne $raw)

if ($needsSettings) {
    $plan += "EDIT  .claude/settings.json (rewire harness-sync + guard-rm hook paths)"
    if (-not $DryRun) {
        $stamp = (Get-Date).ToString("yyyyMMddTHHmmss")
        $bak = "$settings.bak-$stamp"
        Copy-Item -Path $settings -Destination $bak -Force
        [System.IO.File]::WriteAllText($settings, $new)
        Write-Host "Backed up settings.json -> $bak" -ForegroundColor DarkGray
    }
}

# --- Terminal hook<->script congruence scan (T-020 / FR-P1) -----------------------
# Asserts the END STATE: every script path referenced by a `"command"` line in the
# FINAL settings text resolves to a file that exists (apply mode: the text is RE-READ
# from disk after the moves + write, so a settings write that never landed — read-only
# file, disk full — is caught too; disk is ground truth) or is projected to exist
# (dry-run scans the in-memory projection: a planned MOVE counts). Any miss prints an
# explicit CONGRUENCE-FAIL line and the run exits 4 — silent danglement is never a
# reachable end state.
# Known asymmetry (B9): the dry-run projection is ADDITIVE-only — a hook wired to a
# legacy scripts/<name> that exists NOW but is planned to MOVE still passes the disk
# test in dry-run, yet apply exits 4 after the move; apply is authoritative.
# The path regex is LEFT-BOUNDED (quote / space / `=` / line start) so a custom hook
# whose dirname merely ENDS in `scripts/` (e.g. build-scripts/deploy.sh) can never
# match (gate C1). Anything the regex cannot parse is ignored — fail-open diagnosis
# (R4): the scan only flags PARSED tokens whose target file is missing.
# Line-scoping to "command" lines is deliberate: permissions.allow entries and the
# _doc_sync_hook / _ambient_hook doc strings mention BOTH shell variants and must not
# force both to exist (only the wired variant is load-bearing). Case-sensitive regex,
# no IgnoreCase (insight 2026-05-19 family); .Split("`n") not -split (insight 2026-06-08).
$congLines = @()
$phOpen = "{" + "{"   # assembled at runtime: this shipped helper must not carry a literal token
$pathRx = [regex]::new('(^|["'' =])((\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh))')
$scanText = if ($DryRun) { $new } else { Get-Content $settings -Raw }
foreach ($scanLine in $scanText.Split("`n")) {
    if (-not $scanLine.Contains('"command"')) { continue }
    $trimmed = $scanLine.Trim()
    if ($scanLine.Contains($phOpen)) {
        $congLines += "CONGRUENCE-FAIL  $trimmed -> unresolved placeholder token"
    }
    $seenPaths = @()
    foreach ($m in $pathRx.Matches($scanLine)) {
        $refPath = $m.Groups[2].Value
        if ($seenPaths -ccontains $refPath) { continue }
        $seenPaths += $refPath
        $present = Test-Path (Join-Path $root $refPath)
        if (-not $present -and $DryRun -and $refPath.StartsWith(".harness/scripts/")) {
            $refName = $refPath.Substring(".harness/scripts/".Length)
            if ($plannedMoves -ccontains $refName) { $present = $true }
        }
        if (-not $present) {
            $congLines += "CONGRUENCE-FAIL  $trimmed -> missing $refPath"
        }
    }
}

function Write-Congruence {
    if ($script:congLines.Count -eq 0) { return }
    $script:congLines | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host "  hint: run /harness-upgrade to re-land current scripts and rewire hook paths" -ForegroundColor Yellow
}

$finalExit = 0
if ($moveFailed -or ($congLines.Count -gt 0)) { $finalExit = 4 }

# Report
if ($plan.Count -eq 0) {
    if ($finalExit -eq 0) {
        Write-Host "Already migrated / nothing to do." -ForegroundColor Green
        exit 0
    }
    Write-Host "=== migrate-scripts-layout ===" -ForegroundColor Cyan
    Write-Congruence
    exit $finalExit
}

if ($DryRun) {
    Write-Host "=== migrate-scripts-layout (dry run) ===" -ForegroundColor Cyan
    $plan | ForEach-Object { Write-Host "  $_" }
    Write-Congruence
    Write-Host "(dry run — no changes written)" -ForegroundColor Yellow
    exit $finalExit
}

Write-Host "=== migrate-scripts-layout ===" -ForegroundColor Cyan
$plan | ForEach-Object { Write-Host "  $_" }
Write-Congruence
if ($finalExit -eq 0) {
    Write-Host "Done." -ForegroundColor Green
}
exit $finalExit
