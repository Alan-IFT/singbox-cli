# verify_all.ps1 — Generic project total verification
# Generated for singbox-cli (Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management) on 2026-07-31
#
# This is a minimal generic skeleton — it ships with stack-agnostic checks only
# (A.* hygiene + E.* Harness structure). **You should add B.* build / test / lint
# checks for Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management on the first real task.** See the bottom of this file
# for examples.
#
# Usage:
#   .\scripts\verify_all.ps1
#
# Exit codes:
#   0   all checks PASS
#   1   one or more checks WARN
#   2   one or more checks FAIL

[CmdletBinding()]
param([switch]$Quick)

$ErrorActionPreference = "Stop"
$root = (Get-Location).Path
$report = @()
$errors = 0
$warns = 0
$skips = 0

function Step($id, $name, [scriptblock]$action) {
    Write-Host "[$id] $name ..." -NoNewline
    try {
        $result = & $action
        if ($result -eq "SKIP") {
            Write-Host " SKIP" -ForegroundColor DarkGray
            $script:skips++
            $script:report += [pscustomobject]@{ id = $id; name = $name; status = "SKIP" }
        } elseif ($result -eq $false) {
            Write-Host " WARN" -ForegroundColor Yellow
            $script:warns++
            $script:report += [pscustomobject]@{ id = $id; name = $name; status = "WARN" }
        } else {
            Write-Host " PASS" -ForegroundColor Green
            $script:report += [pscustomobject]@{ id = $id; name = $name; status = "PASS" }
        }
    } catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "       $_" -ForegroundColor DarkRed
        $script:errors++
        $script:report += [pscustomobject]@{ id = $id; name = $name; status = "FAIL"; error = "$_" }
    }
}

Write-Host "=== verify_all (generic) ===" -ForegroundColor Cyan
Write-Host "Project: singbox-cli"
Write-Host "Stack:   Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management"
Write-Host ""

# --- A. Hygiene (universal) ---
Step "A.1" "No hardcoded secrets" {
    if (-not (Test-Path ".git")) { return "SKIP" }
    $patterns = @("(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*['""][^'""]{8,}['""]")
    $hits = git grep -E $patterns -- ':!*.md' ':!.harness/scripts/verify_all*' ':!.harness/*' 2>$null
    if ($hits) { throw "Possible secret in:`n$hits" }
}

Step "A.2" "No .env files committed" {
    if (-not (Test-Path ".git")) { return "SKIP" }
    $envFiles = git ls-files -- ':!*.env.example' ':!*.env.sample' '*.env' '.env*' 2>$null | Where-Object { $_ -notmatch 'example|sample' }
    if ($envFiles) { throw "Committed env files:`n$envFiles" }
}

# >>> HARNESS:B-CUSTOM:BEGIN (your build/test/lint checks live here; preserved across /harness-upgrade) <<<
# --- B. Build / test (CUSTOMIZE FOR Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management) ---
# Every id below carries the identical check name to its verify_all.sh counterpart, and
# every SKIP states its reason on the run's output. The reason lands BEFORE the status
# word because Step writes "[id] name ..." -NoNewline and only then invokes this block.
Step "B.1" "Syntax (bin/sc, install.sh, uninstall.sh)" {
    Write-Host " (not run here: the gate is python3 -m py_compile plus bash -n)" -NoNewline
    return "SKIP"
}

Step "B.2" "install.sh bilingual key parity" {
    Write-Host " (not run here: the check is a Bash script over install.sh)" -NoNewline
    return "SKIP"
}

Step "B.3" "Lint" {
    Write-Host " (no lint config is committed)" -NoNewline
    return "SKIP"
}

Step "B.4" "bin/sc contract assertions" {
    Write-Host " (Linux-only by subject: POSIX file modes and os.geteuid)" -NoNewline
    return "SKIP"
}

Step "B.5" "restricted-network self-check" {
    Write-Host " (a Bash scenario script)" -NoNewline
    return "SKIP"
}
# >>> HARNESS:B-CUSTOM:END <<<

# --- E. Project structure (Harness required) ---
Step "E.1" "AI-GUIDE.md, CLAUDE.md, copilot-instructions.md present" {
    foreach ($f in @("AI-GUIDE.md", "CLAUDE.md", ".github/copilot-instructions.md")) {
        if (-not (Test-Path $f)) { throw "Missing $f" }
    }
}

Step "E.2" "workflow.md present" {
    if (-not (Test-Path "docs/workflow.md")) { throw "docs/workflow.md missing" }
}

# E.3 — agents layout (v0.30+): the 7 framework agents are PLUGIN-provided
# (harness-kit:<name>) and are NOT project files; .harness/agents/ holds only
# partition dev-* agents. Absence of the dir is healthy (single-developer project).
# Legacy framework copies WARN (not FAIL): /harness-upgrade v1 does not delete agent
# files, so an upgraded-but-unmigrated project must not end red with no in-flow fix.
Step "E.3" "Agents layout v0.30+ (.harness/agents/ = partition dev-* only)" {
    if (-not (Test-Path ".harness/agents")) { return }
    $legacy = @()
    Get-ChildItem -Path ".harness/agents" -Filter "*.md" -File | ForEach-Object {
        if ($_.Name -cnotlike "dev-*.md") { $legacy += $_.Name }
    }
    if ($legacy.Count -gt 0) {
        Write-Host "" -NoNewline; Write-Host " (framework agents are plugin-provided since v0.30 — remove local copies: $($legacy -join ', '))" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "E.4" "Binding in sync (.harness/ -> .claude/)" {
    if (-not (Test-Path ".harness/scripts/harness-sync.ps1")) { throw ".harness/scripts/harness-sync.ps1 missing" }
    & ".harness/scripts/harness-sync.ps1" -Check
    if ($LASTEXITCODE -ne 0) { throw "Binding drift -- run .harness/scripts/harness-sync.ps1 to fix" }
}

# E.4b — hook<->script congruence (T-020): every script path referenced by a
# "command" line in .claude/settings.json must exist; an unresolved placeholder
# token in a command is also a FAIL. The path regex is LEFT-BOUNDED (quote/space/=/
# line start) so a custom hook whose dirname merely ENDS in scripts/ (e.g.
# build-scripts/deploy.sh) can never match. Doc keys / permissions are NOT scanned
# (only the wired variant of a script pair is load-bearing). Case-sensitive regex.
Step "E.4b" "Hook commands resolve to existing scripts" {
    if (-not (Test-Path ".claude/settings.json")) { return "SKIP" }
    $tok = "{" + "{"   # assembled at runtime: generated file carries no literal token
    $rx = [regex]::new('(^|["'' =])((\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh))')
    $bad = @()
    $raw = Get-Content ".claude/settings.json" -Raw
    foreach ($line in $raw.Split("`n")) {
        if (-not $line.Contains('"command"')) { continue }
        if ($line.Contains($tok)) { $bad += "unresolved placeholder token in a hook command" }
        foreach ($m in $rx.Matches($line)) {
            $p = $m.Groups[2].Value
            if (-not (Test-Path $p)) { $bad += "hook command references missing script: $p" }
        }
    }
    if ($bad.Count -gt 0) { throw "$($bad -join "`n") — fix: run /harness-upgrade" }
}

Step "E.5" "AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa)" {
    if (-not (Test-Path "AI-GUIDE.md")) { return "SKIP" }
    if (-not (Test-Path ".harness/rules")) { return "SKIP" }
    $guide = Get-Content "AI-GUIDE.md" -Raw
    $missingFromGuide = @()
    Get-ChildItem -Path ".harness/rules" -Filter "*.md" -File | ForEach-Object {
        if ($guide -notmatch [regex]::Escape(".harness/rules/$($_.Name)")) {
            $missingFromGuide += $_.Name
        }
    }
    $referencedRules = [regex]::Matches($guide, '\.harness/rules/([0-9A-Za-z_\-]+\.md)') |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $missingFromDisk = @()
    foreach ($ref in $referencedRules) {
        if (-not (Test-Path ".harness/rules/$ref")) { $missingFromDisk += $ref }
    }
    $problems = @()
    if ($missingFromGuide.Count -gt 0) { $problems += "Rules NOT indexed: $($missingFromGuide -join ', ')" }
    if ($missingFromDisk.Count -gt 0) { $problems += "References non-existent: $($missingFromDisk -join ', ')" }
    if ($problems.Count -gt 0) { throw ($problems -join " | ") }
}

Step "E.6" "Adversarial tests section present in completed task reports" {
    if (-not (Test-Path "docs/features")) { return "SKIP" }
    $reports = Get-ChildItem -Path "docs/features" -Recurse -Filter "06_TEST_REPORT.md" -ErrorAction SilentlyContinue
    if ($reports.Count -eq 0) { return "SKIP" }
    $bad = @()
    foreach ($r in $reports) {
        $c = Get-Content $r.FullName -Raw
        if ($c -notmatch '##\s+Adversarial\s+tests') { $bad += $r.FullName.Substring($root.Length + 1) }
    }
    if ($bad.Count -gt 0) { throw "Test reports missing '## Adversarial tests' section:`n$($bad -join "`n")" }
}

# --- F. Document size caps (v0.14+, WARN-only; see .harness/rules/70-doc-size.md) ---
Step "F.1" "AI-GUIDE.md <=200 lines" {
    if (-not (Test-Path "AI-GUIDE.md")) { return "SKIP" }
    $n = (Get-Content "AI-GUIDE.md" | Measure-Object -Line).Lines
    if ($n -gt 200) {
        Write-Host "" -NoNewline; Write-Host " ($n lines, cap 200)" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "F.2" "Rule fragments <=200 lines each" {
    if (-not (Test-Path ".harness/rules")) { return "SKIP" }
    $over = @()
    Get-ChildItem -Path ".harness/rules" -Filter "*.md" -File | ForEach-Object {
        $n = (Get-Content $_.FullName | Measure-Object -Line).Lines
        if ($n -gt 200) { $over += "$($_.Name):${n}L" }
    }
    if ($over.Count -gt 0) {
        Write-Host "" -NoNewline; Write-Host " (over cap: $($over -join ', '))" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "F.3" "Agent definitions <=300 lines each" {
    if (-not (Test-Path ".harness/agents")) { return "SKIP" }
    $over = @()
    Get-ChildItem -Path ".harness/agents" -Filter "*.md" -File | ForEach-Object {
        $n = (Get-Content $_.FullName | Measure-Object -Line).Lines
        if ($n -gt 300) { $over += "$($_.Name):${n}L" }
    }
    if ($over.Count -gt 0) {
        Write-Host "" -NoNewline; Write-Host " (over cap: $($over -join ', '))" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "F.4" "insight-index.md <=30 lines" {
    if (-not (Test-Path ".harness/insight-index.md")) { return "SKIP" }
    $n = (Get-Content ".harness/insight-index.md" | Measure-Object -Line).Lines
    if ($n -gt 30) {
        Write-Host "" -NoNewline; Write-Host " ($n lines — run .harness/scripts/archive-task to rotate)" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "F.5" "docs/tasks.md <=300 lines" {
    if (-not (Test-Path "docs/tasks.md")) { return "SKIP" }
    $n = (Get-Content "docs/tasks.md" | Measure-Object -Line).Lines
    if ($n -gt 300) {
        Write-Host "" -NoNewline; Write-Host " ($n lines — rotate Completed rows to docs/tasks-archive.md)" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "F.6" "Active task docs <=500 lines each" {
    if (-not (Test-Path "docs/features")) { return "SKIP" }
    $over = @()
    Get-ChildItem -Path "docs/features" -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/]_archived[\\/]' -and ($_.Name -eq 'PM_LOG.md' -or $_.Name -match '^0[1-7]_.+\.md$') } |
        ForEach-Object {
            $n = (Get-Content $_.FullName | Measure-Object -Line).Lines
            if ($n -gt 500) { $over += "$($_.FullName.Substring($root.Length + 1)):${n}L" }
        }
    if ($over.Count -gt 0) {
        Write-Host "" -NoNewline; Write-Host " (over cap: $($over -join ', ') — see rule 70)" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

# --- Summary ---
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$pass = ($report | Where-Object status -eq "PASS").Count
Write-Host "  PASS: $pass" -ForegroundColor Green
Write-Host "  WARN: $warns" -ForegroundColor Yellow
Write-Host "  FAIL: $errors" -ForegroundColor Red
Write-Host "  SKIP: $skips" -ForegroundColor DarkGray

if ($errors -gt 0) { exit 2 }
if ($warns -gt 0) { exit 1 }
exit 0

# --- CUSTOMIZE: B.* examples for common stacks ---
# Rust:        & cargo build  /  & cargo test  /  & cargo clippy
# Python:      & python -m pytest  /  & ruff check .  /  & mypy .
# Go:          & go build ./...  /  & go test ./...  /  & golangci-lint run
# .NET / C#:   & dotnet build  /  & dotnet test
# Java:        & ./gradlew build  /  & ./gradlew test
# Mobile (iOS, Android): & xcodebuild test / & ./gradlew connectedAndroidTest
