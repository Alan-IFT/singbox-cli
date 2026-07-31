# upgrade-project.ps1 — Deterministic mechanical layer for /harness-upgrade (T-012).
#
# Brings an already-initialized but STALE harness project up to the current plugin
# layout: relocate scripts to .harness/scripts/, content-refresh the depth-sensitive
# scripts from the current template (so their two-up repo-root derivation is correct —
# relocation alone is NOT enough; see insight L31 / DO-1), re-install the pre-commit
# hook, rewire .claude/settings.json hook paths (raw-text, never re-serialized), and
# regenerate verify_all from the current type template while preserving the user's
# B.* customizations.
#
# This is the deterministic transform. The /harness-upgrade SKILL owns all judgment
# (cache + version discovery, project-type detection via AskUserQuestion, plan/confirm,
# the verify_all-HALT confirm, final reporting). The helper does ZERO cache discovery —
# the SKILL passes the resolved template root via -TemplateRoot.
#
# Run from the PROJECT ROOT (the directory that contains .git/, .claude/, scripts/ or
# .harness/scripts/). cwd-derived, so it works whether bootstrapped under scripts/
# (pre-relocation) or .harness/scripts/ (post-relocation).
#
# Usage:
#   pwsh -File upgrade-project.ps1 -TemplateRoot <abs> -Type generic -Stack "Rust CLI"
#   pwsh -File upgrade-project.ps1 -TemplateRoot <abs> -Type fullstack -DryRun
#
# Machine-readable stdout (one record per line, pipe-delimited, stable verb prefix so
# the AI layer can grep without locale/format issues):
#   PLAN|<verb>|<detail>          (dry-run plan lines)
#   RESULT|<verb>|<detail>        (applied actions)
#   GAP|<id>|<present|absent>|<detail>
#   TYPE|<type>
#   BAK|<path>
#   CONFLICT|<kind>|<detail>
#   SUMMARY|added=<n> moved=<n> rewritten=<n> rewired=<n> conflicts=<n>
# <verb> in: MOVE REFRESH REWIRE REWIRE-PLACEHOLDER HOOK-INSTALL HOOK-SKIP
#            VERIFY-REGEN VERIFY-SPLICE VERIFY-HALT SKIP NOOP
#
# Exit codes:
#   0  success (applied / nothing-to-do / dry-run printed)
#   1  user/precondition error (not a harness project; missing -TemplateRoot; bad -Type)
#   2  refresh-blocked: verify_all B.* could not be cleanly delimited AND not --force
#   3  hook conflict surfaced (non-stock pre-commit); other steps still completed
#   4  post-run hook<->script congruence failure (T-020): a wired hook command
#      references (apply) or would reference (dry-run) a missing script, or carries
#      an unresolved placeholder token. Exit 4 overrides 2/3 — the co-occurring
#      CONFLICT records are still all on stdout.

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [ValidateSet("fullstack", "backend", "generic")]
    [string]$Type,
    [string]$Stack,
    [string]$ProjectName,
    [string]$TemplateRoot,
    [string]$Today
)

$ErrorActionPreference = "Stop"

$root = (Get-Location).Path

# --- preconditions ---------------------------------------------------------------
if (-not $TemplateRoot) {
    [Console]::Error.WriteLine("upgrade-project: -TemplateRoot is required (the resolved plugin template cache root).")
    exit 1
}
$templateCommonScripts = Join-Path $TemplateRoot "skills/harness-init/templates/common/.harness/scripts"
$templateTypeScripts   = Join-Path $TemplateRoot ("skills/harness-init/templates/{0}/.harness/scripts" -f $Type)
if (-not (Test-Path $templateCommonScripts)) {
    [Console]::Error.WriteLine("upgrade-project: template common scripts not found at $templateCommonScripts.")
    exit 1
}
if (-not $Type) {
    [Console]::Error.WriteLine("upgrade-project: -Type is required (fullstack|backend|generic).")
    exit 1
}
if (-not (Test-Path $templateTypeScripts)) {
    [Console]::Error.WriteLine("upgrade-project: template type scripts not found at $templateTypeScripts.")
    exit 1
}

# Must look like SOME harness project: .claude/settings.json OR .harness/ OR scripts/harness-sync.*
$hasSettings   = Test-Path (Join-Path $root ".claude/settings.json")
$hasHarnessDir = Test-Path (Join-Path $root ".harness")
$hasOldSync    = (Test-Path (Join-Path $root "scripts/harness-sync.ps1")) -or (Test-Path (Join-Path $root "scripts/harness-sync.sh"))
if (-not ($hasSettings -or $hasHarnessDir -or $hasOldSync)) {
    [Console]::Error.WriteLine("upgrade-project: this does not look like a harness project (no .claude/settings.json, no .harness/, no scripts/harness-sync.*). Use /harness-adopt for a no-harness project.")
    exit 1
}

if (-not $ProjectName) { $ProjectName = Split-Path $root -Leaf }
if (-not $Today)       { $Today = (Get-Date).ToString("yyyy-MM-dd") }

$stamp = (Get-Date).ToString("yyyyMMddTHHmmss")

# counters
$nMoved = 0; $nRewritten = 0; $nRewired = 0; $nAdded = 0; $nConflicts = 0
$exitCode = 0

function Emit($line) { Write-Output $line }

# Get-ResilientCmd <tool> <isWindows> — return the T-12 RESILIENT hook command string,
# JSON-escaped (inner " as \") so it drops straight into a JSON "command" value
# byte-identical to settings.json.tmpl after substitution.
#   convenience hooks (harness-sync / ambient-prompt / ambient-reset): fail-OPEN —
#     anchor to $CLAUDE_PROJECT_DIR, exit 0 silently if the script is absent/unreachable.
#   guard-rm (safety): fail-CLOSED — anchor but NO exit-0 fallback, so a missing /
#     unreachable guard yields a non-zero exit (the Bash call is blocked).
# The space-preceded bare `.harness/scripts/<tool>.<ext>` token is preserved so the
# unchanged left-bounded congruence regex still parses + existence-checks it (OQ-3a).
# Case-sensitive literals; .Split not -split elsewhere (insight 2026-06-08 family).
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

Emit ("TYPE|{0}" -f $Type)

# --- S1 relocation (verbatim known-set + git-mv-preserving + SKIP-unless-Force) ---
# Inlined from migrate-scripts-layout.ps1 so the upgrade is a single self-contained
# helper. The known set is filename-preserved (NOT a blanket scripts/*).
# INVARIANT: $refreshSet (S2 below) == ($known minus verify_all.{ps1,sh}, baseline.json)
# plus the ambient hook pair (ambient-prompt/-reset never lived at top-level scripts/ —
# they shipped post-relocation in T-011, so they are NOT in $known).
# These two literal arrays are hand-maintained — if you edit one, update the other.
$known = @(
    "verify_all.ps1", "verify_all.sh",
    "harness-sync.ps1", "harness-sync.sh",
    "guard-rm.ps1", "guard-rm.sh",
    "install-hooks.ps1", "install-hooks.sh",
    "archive-task.ps1", "archive-task.sh",
    "migrate-scripts-layout.ps1", "migrate-scripts-layout.sh",
    "baseline.json"
)
$srcDir = Join-Path $root "scripts"
$dstDir = Join-Path $root ".harness/scripts"
$inGit  = Test-Path (Join-Path $root ".git")
$plannedMoves = @()

foreach ($name in $known) {
    $src = Join-Path $srcDir $name
    $dst = Join-Path $dstDir $name
    if (-not (Test-Path $src)) { continue }
    if ((Test-Path $dst) -and -not $Force) {
        Emit ("{0}|SKIP|scripts/{1} (already at .harness/scripts/{1}; -Force to overwrite)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $name)
        continue
    }
    Emit ("{0}|MOVE|scripts/{1} -> .harness/scripts/{1}" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $name)
    $plannedMoves += $name
    $nMoved++
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
    }
}

# --- S2 content-refresh of depth-sensitive scripts (the L31 / DO-1 fix) -----------
# UNCONDITIONALLY byte-overwrite the refresh set from the current template (which is
# already two-up). Relocation alone preserves OLD one-up root derivation — this is
# what actually fixes the root-resolution hazard. verify_all is NOT in this set (it
# is regenerated from the type .tmpl in S5); baseline.json is data (relocate-only).
# INVARIANT: $refreshSet == ($known (S1 above) minus verify_all.{ps1,sh}, baseline.json)
# plus the ambient hook pair (ambient-prompt/-reset are hook targets — repair, FR-R1,
# must be able to re-land them; they are not in $known because they never lived at
# top-level scripts/). Hand-maintained literal arrays — edit one, update the other.
$refreshSet = @(
    "harness-sync.ps1", "harness-sync.sh",
    "install-hooks.ps1", "install-hooks.sh",
    "archive-task.ps1", "archive-task.sh",
    "guard-rm.ps1", "guard-rm.sh",
    "migrate-scripts-layout.ps1", "migrate-scripts-layout.sh",
    "ambient-prompt.ps1", "ambient-prompt.sh",
    "ambient-reset.ps1", "ambient-reset.sh"
)
foreach ($name in $refreshSet) {
    $tmpl = Join-Path $templateCommonScripts $name
    $dst = Join-Path $dstDir $name
    if (-not (Test-Path $tmpl)) {
        # T-020 (RC-4 fix): never skip this case silently. If the project still has a
        # copy, that copy is retained (NOOP); if neither side has the file, emit an
        # explicit GAP so a hook wired to it is diagnosable (the terminal congruence
        # scan then fails the run with exit 4 if the file is actually wired).
        if (Test-Path $dst) {
            Emit ("{0}|NOOP|.harness/scripts/{1} (template lacks it; existing copy retained)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $name)
        } else {
            Emit ("GAP|template-missing|absent|.harness/scripts/{0}" -f $name)
        }
        continue
    }
    $identical = $false
    if (Test-Path $dst) {
        $identical = ((Get-FileHash $tmpl -Algorithm SHA256).Hash -eq (Get-FileHash $dst -Algorithm SHA256).Hash)
    }
    if ($identical) {
        Emit ("{0}|NOOP|.harness/scripts/{1} (already current)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $name)
        continue
    }
    $isNew = -not (Test-Path $dst)
    Emit ("{0}|REFRESH|.harness/scripts/{1} (from current template)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $name)
    if ($isNew) { $nAdded++ } else { $nRewritten++ }
    if (-not $DryRun) {
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        Copy-Item -Path $tmpl -Destination $dst -Force -ErrorAction SilentlyContinue
        # Copy verify (T-020 / RC-4): a failed copy must not pass silently — S3 could
        # otherwise rewire toward a file that never landed.
        $landed = (Test-Path $dst) -and
                  ((Get-FileHash $tmpl -Algorithm SHA256).Hash -eq (Get-FileHash $dst -Algorithm SHA256).Hash)
        if (-not $landed) {
            Emit ("CONFLICT|refresh|.harness/scripts/{0} copy failed (template -> project copy did not land)" -f $name)
            $nConflicts++
        }
    }
}

# --- S3 settings rewire (verbatim raw-text replace; NEVER re-serialize — DO-3) -----
# Test-TargetPresent <name>: is .harness/scripts/<name> on disk (apply mode: S1 moves
# + S2 refresh already ran, disk is ground truth) or projected to land there (dry-run:
# a planned S1 MOVE counts, and so does the template carrying a refresh-set member —
# S2 would land it on apply)? Gates both the placeholder repair and the per-variant
# prefix rewires below (T-020 / FR-P3).
function Test-TargetPresent($name) {
    if (Test-Path (Join-Path $dstDir $name)) { return $true }
    if (-not $DryRun) { return $false }
    if ($plannedMoves -ccontains $name) { return $true }
    if (($refreshSet -ccontains $name) -and (Test-Path (Join-Path $templateCommonScripts $name))) { return $true }
    return $false
}

$settings = Join-Path $root ".claude/settings.json"
$new = $null
# Token opener/closer assembled from pieces so this shipped helper never contains a
# literal double-brace token (insight 2026-06-08; test-init's blanket placeholder scan).
$phOpen = "{" + "{"
$phClose = "}" + "}"
if (-not (Test-Path $settings)) {
    Emit "RESULT|SKIP|.claude/settings.json absent — settings rewire skipped (non-Claude-Code project)"
} else {
    $raw = Get-Content $settings -Raw
    $new = $raw

    # S3.0 — literal-placeholder repair (T-020 gate C3 / B7, design §6.2.5).
    # A wired, UNSUBSTITUTED placeholder token (RC-3 improvisation damage) can never
    # run on any OS, so it is never a deliberate user choice (OQ-5 untriggered): it is
    # rewritten to the OS-picked init command — gated on the target script being
    # (projected) present, so a MALFORMED token never becomes a DANGLING path (the
    # terminal scan flags an un-repairable token instead -> exit 4). String ops are
    # ordinal + case-sensitive (.Contains/.Replace — R1 discipline). Replacement
    # values contain no token opener, so a second run is a no-op (B10).
    $phPairs = @(
        @{ Name = "SYNC_COMMAND";           Tool = "harness-sync" },
        @{ Name = "GUARD_COMMAND";          Tool = "guard-rm" },
        @{ Name = "AMBIENT_PROMPT_COMMAND"; Tool = "ambient-prompt" },
        @{ Name = "AMBIENT_RESET_COMMAND";  Tool = "ambient-reset" }
    )
    foreach ($ph in $phPairs) {
        $tok = $phOpen + $ph.Name + $phClose
        if ($IsWindows) {
            $gateTarget = "$($ph.Tool).ps1"
        } else {
            $gateTarget = "$($ph.Tool).sh"
        }
        # T-12: emit the RESILIENT (fail-open/closed + $CLAUDE_PROJECT_DIR-anchored) form
        # so a placeholder-repaired hook is born resilient, not brittle. JSON-escaped
        # bytes — byte-identical to settings.json.tmpl after substitution.
        $cmd = Get-ResilientCmd $ph.Tool $IsWindows
        if ($new.Contains($tok) -and (Test-TargetPresent $gateTarget)) {
            $new = $new.Replace($tok, $cmd)
            Emit ("{0}|REWIRE-PLACEHOLDER|.claude/settings.json ({1} -> {2})" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $ph.Name, $cmd)
        }
    }

    # S3.1 — per-variant presence-gated prefix rewire (T-020 / RC-4 fix). In the
    # normal flow S2 just landed every variant, so the gate is transparently true and
    # behavior on healthy projects is byte-identical to before. The unconditional
    # double-prefix collapse stays last (fixed point — B10).
    # Known cosmetic nuance (gate F-4): when only ONE shell variant's target is
    # present, doc strings mentioning both variants end half-migrated. Idempotent and
    # harmless — the terminal scan only checks "command" lines, never doc keys.
    # T-12 ordering: S3.1 runs BEFORE S3.2 so a pre-T-007 bare `scripts/<tool>` brittle
    # command is first normalized to `.harness/scripts/<tool>` and then S3.2 can match +
    # resilient-ify it (the resilient swap only knows the `.harness/`-prefixed brittle).
    foreach ($toolExt in @("harness-sync.ps1", "harness-sync.sh", "guard-rm.ps1", "guard-rm.sh")) {
        if (Test-TargetPresent $toolExt) {
            $new = $new.Replace("scripts/$toolExt", ".harness/scripts/$toolExt")
        }
    }
    # Collapse the double prefix produced when an already-migrated `.harness/scripts/...`
    # substring matched the `scripts/...` target -> true fixed point (idempotent).
    $new = $new.Replace(".harness/.harness/scripts/", ".harness/scripts/")

    # S3.2 — brittle -> resilient rewrite (T-12 / A8, design §4.3). S3.1 above only adds
    # the `.harness/` prefix; it does NOT convert a brittle command into the resilient
    # (fail-open/closed + $CLAUDE_PROJECT_DIR-anchored) form. This step does. For each of
    # the four {tool}x{ext} brittle forms, if the `.harness/`-prefixed brittle command
    # value is present verbatim AND its target is (projected) present, swap the WHOLE
    # brittle command VALUE for the OS-picked resilient string. Ordinal .Replace (R1).
    # Gated on Test-TargetPresent so a brittle command pointing at a missing script is
    # left for the terminal scan to flag (never rewritten into a resilient-but-dangling
    # form). The needle is double-quote-bounded ("<brittle>") so it matches ONLY a bare
    # brittle "command" value, never the same bare token embedded INSIDE an already-
    # resilient value — idempotent without a whole-file sentinel (second run = NOOP, no
    # .bak churn — B10), robust to mixed states. Raw-text, never re-serialize (DO-3);
    # $schema untouched. R4: only the four harness tool names are eligible.
    foreach ($s32Tool in @("harness-sync", "guard-rm", "ambient-prompt", "ambient-reset")) {
        foreach ($s32Ext in @("ps1", "sh")) {
            $s32Target = "$s32Tool.$s32Ext"
            if (-not (Test-TargetPresent $s32Target)) { continue }
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
                Emit ("{0}|REWIRE-RESILIENT|.claude/settings.json ({1}.{2} -> resilient form)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $s32Tool, $s32Ext)
            }
        }
    }

    if ($new -cne $raw) {
        Emit ("{0}|REWIRE|.claude/settings.json (hook command paths)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })))
        $nRewired++
        if (-not $DryRun) {
            $bak = "$settings.bak-$stamp"
            Copy-Item -Path $settings -Destination $bak -Force
            Emit ("BAK|{0}" -f $bak)
            [System.IO.File]::WriteAllText($settings, $new)
        }
    } else {
        Emit "RESULT|NOOP|.claude/settings.json already rewired"
    }
}

# --- S4 hook (re)install --------------------------------------------------------
# Stock-hook detection: compare the existing pre-commit body against the CURRENT
# stock body. The pre-T-007 stock hook differs only in the script path prefix
# (scripts/harness-sync. vs .harness/scripts/harness-sync.), so NORMALIZE that prefix
# in both bodies before comparing (F-4) — one normalized comparison covers both
# stock variants without keeping two full literal copies.
$currentHookBody = @'
#!/bin/sh
# harness-kit pre-commit hook.
# Blocks the commit if .harness/ has drifted from CLAUDE.md or .github/copilot-instructions.md.
# Tool-agnostic: catches edits from Claude Code, Copilot, Cursor, or hand-typed.
set -e
_drift=0
if command -v pwsh >/dev/null 2>&1 && [ -f .harness/scripts/harness-sync.ps1 ]; then
    pwsh -File .harness/scripts/harness-sync.ps1 -Check >/dev/null 2>&1 || _drift=1
elif command -v bash >/dev/null 2>&1 && [ -f .harness/scripts/harness-sync.sh ]; then
    bash .harness/scripts/harness-sync.sh --check >/dev/null 2>&1 || _drift=1
else
    echo "harness-kit pre-commit: neither pwsh nor bash found; skipping drift check." >&2
    exit 0
fi
if [ "$_drift" = "1" ]; then
    echo "" >&2
    echo "harness-kit: drift between .harness/ and .claude/." >&2
    echo "  .claude/agents/ and/or .claude/skills/ are stale relative to .harness/." >&2
    echo "" >&2
    echo "  Fix: pwsh -File .harness/scripts/harness-sync.ps1   (Windows)" >&2
    echo "       bash .harness/scripts/harness-sync.sh          (macOS / Linux)" >&2
    echo "  Then: git add .claude/ && git commit ..." >&2
    echo "" >&2
    echo "  Note: edits to .harness/rules/ do NOT need sync (referenced by AI-GUIDE.md, not composed)." >&2
    echo "  Bypass once (NOT recommended): git commit --no-verify" >&2
    exit 1
fi
'@

function Normalize-HookBody($s) {
    if ($null -eq $s) { return "" }
    # Collapse the old one-up path prefix to the new two-up prefix, then normalize
    # line endings, so the stock-vs-custom test ignores both path-depth and CRLF/LF.
    $n = $s.Replace("scripts/harness-sync.", ".harness/scripts/harness-sync.")
    $n = $n.Replace(".harness/.harness/scripts/harness-sync.", ".harness/scripts/harness-sync.")
    $n = $n.Replace("`r`n", "`n").Trim()
    return $n
}

$hookPath = Join-Path $root ".git/hooks/pre-commit"
$normCurrent = Normalize-HookBody $currentHookBody
if (-not (Test-Path (Join-Path $root ".git"))) {
    Emit "RESULT|SKIP|.git absent — pre-commit hook not installed"
} elseif (-not (Test-Path $hookPath)) {
    Emit ("{0}|HOOK-INSTALL|.git/hooks/pre-commit (was absent)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })))
    if (-not $DryRun) {
        $hooksDir = Join-Path $root ".git/hooks"
        if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null }
        # Trailing "`n": match the byte-for-byte output of install-hooks.sh / upgrade-project.sh
        # (both write the hook WITH a single trailing newline). Without it the two shells would
        # produce 1-byte-different hooks → a spurious cross-shell re-install + .bak (NFR-1 parity).
        [System.IO.File]::WriteAllText($hookPath, $currentHookBody + "`n")
        if ($IsLinux -or $IsMacOS) { & chmod +x $hookPath }
    }
} else {
    $existing = Get-Content $hookPath -Raw
    if ((Normalize-HookBody $existing) -eq $normCurrent) {
        $alreadyCurrent = (($existing.Replace("`r`n", "`n").Trim()) -eq ($currentHookBody.Replace("`r`n", "`n").Trim()))
        if ($alreadyCurrent) {
            Emit "RESULT|NOOP|.git/hooks/pre-commit already current"
        } else {
            Emit ("{0}|HOOK-INSTALL|.git/hooks/pre-commit (was stock pre-T-007; refreshed to new path)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })))
            if (-not $DryRun) {
                $bak = "$hookPath.bak-$stamp"
                Copy-Item -Path $hookPath -Destination $bak -Force
                Emit ("BAK|{0}" -f $bak)
                # Trailing "`n": match install-hooks.sh / upgrade-project.sh byte-for-byte (NFR-1).
                [System.IO.File]::WriteAllText($hookPath, $currentHookBody + "`n")
                if ($IsLinux -or $IsMacOS) { & chmod +x $hookPath }
            }
        }
    } else {
        Emit "CONFLICT|hook|.git/hooks/pre-commit is non-stock (hand-customized) — NOT overwritten; merge the drift check in manually"
        $nConflicts++
        $exitCode = 3
    }
}

# --- S5 verify_all regenerate (splice / regen / halt) ---------------------------
$beginMarker = "# >>> HARNESS:B-CUSTOM:BEGIN"
$endMarker   = "# >>> HARNESS:B-CUSTOM:END"

function Get-MarkerBlock($lines) {
    # Returns @{ ok=$bool; startIdx; endIdx; block } where ok = exactly one BEGIN, one
    # END, BEGIN strictly before END. block = the lines BETWEEN the markers (exclusive).
    $begins = @(); $ends = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].StartsWith($beginMarker)) { $begins += $i }
        elseif ($lines[$i].StartsWith($endMarker)) { $ends += $i }
    }
    if ($begins.Count -ne 1 -or $ends.Count -ne 1 -or $begins[0] -ge $ends[0]) {
        return @{ ok = $false }
    }
    $inner = @()
    for ($i = $begins[0] + 1; $i -lt $ends[0]; $i++) { $inner += $lines[$i] }
    return @{ ok = $true; startIdx = $begins[0]; endIdx = $ends[0]; block = $inner }
}

function Test-IsStubBlock($blockLines) {
    # Stub = every B.* check body is a bare SKIP/TODO (no real build/test/lint command).
    # Heuristic: no non-comment line that is NOT a SKIP step and NOT structural.
    foreach ($line in $blockLines) {
        $t = $line.Trim()
        if ($t -eq "") { continue }
        if ($t.StartsWith("#")) { continue }
        # bash stub:   step "B.1" "Build" "SKIP"
        # ps stub:     Step "B.x" "..." {  /  return "SKIP"  /  }  /  # TODO comments
        if ($t -match 'SKIP') { continue }
        if ($t -match '^Step\b' -or $t -match '^step\b') { continue }
        if ($t -eq '{' -or $t -eq '}') { continue }
        if ($t.StartsWith('return ')) { continue }
        # Any other live content => customized.
        return $false
    }
    return $true
}

function Test-OldBCustomized($lines) {
    # For an OLD verify_all that predates the HARNESS:B-CUSTOM markers: decide whether
    # the B.* region carries custom checks. Heuristic — any line that declares a B.*
    # step (bash `step "B.x" ... "PASS|FAIL|WARN"` with a non-SKIP status, or a real
    # build/test command token) is treated as customized. A region of only SKIP stubs
    # is NOT customized (safe to regenerate).
    foreach ($line in $lines) {
        $t = $line.Trim()
        # bash step with a non-SKIP terminal status on a B.* id
        if ($t -match '^step\s+"B\.' -and $t -notmatch '"SKIP"') { return $true }
        # explicit real commands commonly written into a customized B.* block
        if ($t -match '\b(cargo|pytest|npm|pnpm|yarn|go build|go test|dotnet|gradle|mvn|ruff|mypy|eslint|tsc)\b' -and $t -notmatch '^#') { return $true }
    }
    return $false
}

function Substitute-Placeholders($text) {
    # The placeholder tokens are assembled from pieces (o + NAME + c) rather than written
    # as double-brace literals, so this helper file does NOT itself contain an
    # unsubstituted placeholder token — keeps test-init's "no unresolved placeholders"
    # cleanliness check happy when the helper is copied into a generated project. These
    # are still the only 3 substituted names (the D.2-whitelisted set); no new placeholder.
    $o = "{{"; $c = "}}"
    $out = $text.Replace($o + "PROJECT_NAME" + $c, $ProjectName)
    $out = $out.Replace($o + "STACK" + $c, $(if ($Stack) { $Stack } else { $Type }))
    $out = $out.Replace($o + "TODAY" + $c, $Today)
    return $out
}

foreach ($shell in @("ps1", "sh")) {
    $proj = Join-Path $dstDir ("verify_all.{0}" -f $shell)
    $tmpl = Join-Path $templateTypeScripts ("verify_all.{0}.tmpl" -f $shell)
    if (-not (Test-Path $tmpl)) {
        Emit ("RESULT|SKIP|verify_all.{0} (no type template)" -f $shell)
        continue
    }
    $fresh = Substitute-Placeholders (Get-Content $tmpl -Raw)
    $freshLines = $fresh -split "`r?`n"

    # Determine the splice/regen/halt decision from the OLD project file.
    $verb = "VERIFY-REGEN"
    $finalText = $fresh
    if (Test-Path $proj) {
        $oldRaw = Get-Content $proj -Raw
        $oldLines = $oldRaw -split "`r?`n"
        $oldMarkers = Get-MarkerBlock $oldLines
        if ($oldMarkers.ok) {
            $customized = -not (Test-IsStubBlock $oldMarkers.block)
            if ($customized) {
                # SPLICE: replace the fresh file's BEGIN..END region with the OLD block verbatim.
                $freshMarkers = Get-MarkerBlock $freshLines
                if ($freshMarkers.ok) {
                    $spliced = @()
                    $spliced += $freshLines[0..$freshMarkers.startIdx]      # up to & incl. fresh BEGIN
                    $spliced += $oldMarkers.block                            # old inner block verbatim
                    $spliced += $freshLines[$freshMarkers.endIdx..($freshLines.Count - 1)]  # fresh END onward
                    $finalText = ($spliced -join "`n")
                    $verb = "VERIFY-SPLICE"
                } else {
                    # Fresh template lost its markers (should not happen) — regen.
                    $verb = "VERIFY-REGEN"
                }
            } else {
                $verb = "VERIFY-REGEN"   # clean delimiter + stub-only -> take fresh
            }
        } else {
            # No clean delimiter in the OLD file (predates markers).
            $oldCustomized = Test-OldBCustomized $oldLines
            if ($oldCustomized -and -not $Force) {
                Emit ("VERIFY-HALT|{0}" -f $shell)
                Emit ("CONFLICT|verify_all|verify_all.{0} has no HARNESS:B-CUSTOM markers but appears to carry custom B.* checks — left untouched (nothing lost). Re-run with -Force to overwrite; a timestamped .bak will be written first, preserving your old checks." -f $shell)
                $nConflicts++
                $exitCode = 2
                continue
            }
            $verb = "VERIFY-REGEN"
        }
    }

    # Idempotence: byte-identical to existing -> NOOP, no .bak, no write.
    if ((Test-Path $proj) -and ((Get-Content $proj -Raw) -ceq $finalText)) {
        Emit ("RESULT|NOOP|verify_all.{0} already current" -f $shell)
        continue
    }

    $isNew = -not (Test-Path $proj)
    Emit ("{0}|{1}|verify_all.{2}" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $verb, $shell)
    if ($isNew) { $nAdded++ } else { $nRewritten++ }
    if (-not $DryRun) {
        if (Test-Path $proj) {
            $bak = "$proj.bak-$stamp"
            Copy-Item -Path $proj -Destination $bak -Force
            Emit ("BAK|{0}" -f $bak)
        }
        [System.IO.File]::WriteAllText($proj, $finalText)
    }
}

# --- S6 terminal hook<->script congruence scan (T-020 / FR-P1, runs last) --------
# Asserts the END STATE: every script path referenced by a `"command"` line in the
# final settings text resolves to a file that exists (apply mode: disk is ground
# truth — the scan runs after every writer) or is projected to exist (dry-run:
# planned S1 MOVEs and template-carried refresh-set members count). Each miss emits
# a CONFLICT|congruence record and the run exits 4. The scan is the LAST writer of
# $exitCode, so 4 deliberately wins over 2/3 — an incongruent end state is the most
# actionable failure; the co-occurring CONFLICT/VERIFY-HALT records stay on stdout.
# The path regex is LEFT-BOUNDED (quote / space / `=` / line start) so a custom hook
# whose dirname merely ENDS in `scripts/` (e.g. build-scripts/deploy.sh) can never
# match (gate C1). Anything the regex cannot parse is ignored — fail-open diagnosis
# (R4): the scan only flags PARSED tokens whose target file is missing.
# Line-scoping to "command" lines is deliberate: permissions.allow entries and the
# _doc_sync_hook / _ambient_hook doc strings mention BOTH shell variants and must not
# force both to exist (only the wired variant is load-bearing). Case-sensitive regex,
# no IgnoreCase (insight 2026-05-19 family); .Split("`n") not -split (insight 2026-06-08).
# Known asymmetry (B9): the dry-run projection is ADDITIVE-only — a hook wired to a
# legacy scripts/<name> that exists NOW but is planned to MOVE still passes the disk
# test in dry-run, yet apply exits 4 after the move; apply is authoritative.
if (Test-Path $settings) {
    $scanText = if ($DryRun) { $new } else { Get-Content $settings -Raw }
    $congFound = $false
    $pathRx = [regex]::new('(^|["'' =])((\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh))')
    foreach ($scanLine in $scanText.Split("`n")) {
        if (-not $scanLine.Contains('"command"')) { continue }
        $trimmed = $scanLine.Trim()
        if ($scanLine.Contains($phOpen)) {
            Emit ("CONFLICT|congruence|{0} -> unresolved placeholder token" -f $trimmed)
            $nConflicts++
            $congFound = $true
        }
        $seenPaths = @()
        foreach ($m in $pathRx.Matches($scanLine)) {
            $refPath = $m.Groups[2].Value
            if ($seenPaths -ccontains $refPath) { continue }
            $seenPaths += $refPath
            $present = Test-Path (Join-Path $root $refPath)
            if (-not $present -and $DryRun -and $refPath.StartsWith(".harness/scripts/")) {
                $refName = $refPath.Substring(".harness/scripts/".Length)
                if (Test-TargetPresent $refName) { $present = $true }
            }
            if (-not $present) {
                Emit ("CONFLICT|congruence|{0} -> missing {1}" -f $trimmed, $refPath)
                $nConflicts++
                $congFound = $true
            }
        }
    }
    if ($congFound) { $exitCode = 4 }
}

Emit ("SUMMARY|added={0} moved={1} rewritten={2} rewired={3} conflicts={4}" -f $nAdded, $nMoved, $nRewritten, $nRewired, $nConflicts)
exit $exitCode
