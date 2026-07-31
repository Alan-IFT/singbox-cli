# language-policy.ps1 — Deterministic mechanical layer for /harness-language (T-014).
#
# Sets / switches / refreshes a generated project's output-language policy by surgically
# rewriting only the three policy-bearing surfaces to the TARGET language's current
# canonical text:
#   1. .harness/rules/00-core.md       — the policy SECTION (heading-anchored slice)
#   2. CLAUDE.md                        — the single top policy LINE
#   3. .github/copilot-instructions.md — the single top policy LINE
#
# The canonical en/zh text is EXTRACTED at runtime from the resolved plugin template
# using the SAME heading/line anchors — it is never embedded as a string literal here
# (single source of truth = the templates; keeps this file free of any policy prose,
# which also keeps it clear of the I.6 retired-phrase guard). The en source is the
# `common/` 00-core + CLAUDE templates (read inline); the zh source is the single-source
# snippet `i18n/zh/_policy/output-language.zh.md.tmpl` (carries BOTH the section + line).
#
# This is the deterministic transform. The /harness-language SKILL owns all judgment
# (cache + version discovery, current-language detect + AskUserQuestion confirm, the
# absent-section conflict mediation, plan/confirm, final reporting). The helper does ZERO
# cache discovery — the SKILL passes the resolved template root via -TemplateRoot.
#
# Run from the PROJECT ROOT. cwd-derived (depth-independent).
#
# Usage:
#   pwsh -File language-policy.ps1 -TemplateRoot <abs> -Lang en
#   pwsh -File language-policy.ps1 -TemplateRoot <abs> -Lang zh -DryRun
#   pwsh -File language-policy.ps1 -TemplateRoot <abs> -Lang en -Force   # insert absent section
#
# Machine-readable stdout (one record per line, pipe-delimited):
#   LANG|<en|zh>
#   DETECT|<en|zh|ambiguous>|<00-core|CLAUDE|copilot|none>
#   PLAN|<verb>|<file>|<detail>        (dry-run)
#   RESULT|<verb>|<file>|<detail>      (applied)
#   BAK|<path>
#   SKIP|<file>|<reason>
#   CONFLICT|section|<file>|<detail>
#   SUMMARY|rewritten=<n> noop=<n> skipped=<n> baks=<n> conflicts=<n>
# <verb> in: REWRITE-SECTION REWRITE-LINE INSERT-SECTION NOOP SKIP
#
# Exit codes:
#   0  success (applied / nothing-to-do / dry-run printed)
#   1  precondition / arg error (bad -Lang, missing -TemplateRoot, no policy surface)
#   2  section-conflict (00-core.md has neither canonical heading) and not -Force

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [ValidateSet("en", "zh")]
    [string]$Lang,
    [string]$TemplateRoot
)

$ErrorActionPreference = "Stop"

$root = (Get-Location).Path

# --- preconditions ---------------------------------------------------------------
if (-not $TemplateRoot) {
    [Console]::Error.WriteLine("language-policy: -TemplateRoot is required (the resolved plugin template cache root).")
    exit 1
}
if (-not $Lang) {
    [Console]::Error.WriteLine("language-policy: -Lang is required ('en' or 'zh').")
    exit 1
}

# Canonical heading anchors (both languages — the project may currently be either).
$enHeading = "## Output language (project-wide)"
$zhHeading = "## 输出语言（按消费者分流）"

# en: read the section + line inline from common/ (en path byte-unchanged).
# zh: read BOTH from the single-source snippet (section first, line after the sentinel) —
#     the i18n/zh SPECIAL files no longer exist (T-016).
if ($Lang -eq "en") {
    $tmplCore   = Join-Path $TemplateRoot "skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl"
    $tmplClaude = Join-Path $TemplateRoot "skills/harness-init/templates/common/CLAUDE.md.tmpl"
    $targetHeading = $enHeading
} else {
    $tmplCore   = Join-Path $TemplateRoot "skills/harness-init/templates/i18n/zh/_policy/output-language.zh.md.tmpl"
    $tmplClaude = $tmplCore   # single source carries BOTH the section and the line
    $targetHeading = $zhHeading
}

if (-not (Test-Path $tmplCore)) {
    [Console]::Error.WriteLine("language-policy: template 00-core.md.tmpl not found at $tmplCore.")
    exit 1
}
if (-not (Test-Path $tmplClaude)) {
    [Console]::Error.WriteLine("language-policy: template CLAUDE.md.tmpl not found at $tmplClaude.")
    exit 1
}

# Project surfaces.
$projCore    = Join-Path $root ".harness/rules/00-core.md"
$projClaude  = Join-Path $root "CLAUDE.md"
$projCopilot = Join-Path $root ".github/copilot-instructions.md"

if ((-not (Test-Path $projCore)) -and (-not (Test-Path $projClaude))) {
    [Console]::Error.WriteLine("language-policy: neither .harness/rules/00-core.md nor CLAUDE.md exists — nothing to operate on.")
    exit 1
}

$stamp = (Get-Date).ToString("yyyyMMddTHHmmss")
$nRewritten = 0; $nNoop = 0; $nSkipped = 0; $nBaks = 0; $nConflicts = 0
$exitCode = 0

function Emit($line) { Write-Output $line }
function Get-VerbPrefix { if ($DryRun) { "PLAN" } else { "RESULT" } }

# Read a UTF-8 file into an array of LF-delimited lines with any trailing CR stripped.
# Mirrors the bash awk line model: a single trailing newline does NOT produce a final
# empty record. Returns @() for an empty file.
function Read-Lines($path) {
    $raw = [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false))
    if ($raw -eq "") { return @() }
    # .NET String.Split (NOT the `-split` operator: `-split "`n", -1` misparses the -1
    # max-count and collapses to one element). String.Split yields a trailing empty
    # element when the file ends with LF — drop exactly one to mirror the bash awk line
    # model (a single trailing newline produces no final empty record).
    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $raw.Split("`n")) {
        if ($p.EndsWith("`r")) { $parts.Add($p.Substring(0, $p.Length - 1)) }
        else { $parts.Add($p) }
    }
    if ($parts.Count -gt 0 -and $parts[$parts.Count - 1] -eq "") {
        $parts.RemoveAt($parts.Count - 1)
    }
    return , @($parts.ToArray())
}

# Join lines with LF and append a single trailing LF (byte-identical to bash awk output),
# then write as UTF-8 without BOM.
function Write-LinesUtf8($path, $lines) {
    $text = ($lines -join "`n") + "`n"
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}

# Extract the canonical SECTION block [heading, next "## ") as a line array (byte-exact:
# includes the trailing blank line). Returns @() if heading absent.
function Get-SectionLines($lines, $heading) {
    $out = @()
    $found = $false
    foreach ($line in $lines) {
        $cmp = $line -replace '[ \t\r]+$', ''
        if (-not $found) {
            if ($cmp -ceq $heading) { $found = $true; $out += $line }
            continue
        }
        if ($line -cmatch '^## ') { break }
        $out += $line
    }
    if (-not $found) { return @() }
    return , @($out)
}

# Extract the canonical policy LINE (first line matching the anchor). $null if none.
function Get-PolicyLine($lines) {
    foreach ($line in $lines) {
        if ($line -cmatch '^Output language:' -or $line -cmatch '^输出语言：') { return $line }
    }
    return $null
}

Emit ("LANG|{0}" -f $Lang)

# --- DETECT the project current language from 00-core -> CLAUDE -> copilot --------
$detected = "ambiguous"
$detectSource = "none"
if (Test-Path $projCore) {
    $coreRaw = [System.IO.File]::ReadAllText($projCore, [System.Text.UTF8Encoding]::new($false))
    if ($coreRaw.Contains("输出语言（按消费者分流）")) { $detected = "zh"; $detectSource = "00-core" }
    elseif ($coreRaw.Contains("Output language (project-wide)")) { $detected = "en"; $detectSource = "00-core" }
}
if ($detected -eq "ambiguous" -and (Test-Path $projClaude)) {
    foreach ($line in (Read-Lines $projClaude)) {
        if ($line -cmatch '^输出语言：') { $detected = "zh"; $detectSource = "CLAUDE"; break }
        if ($line -cmatch '^Output language:') { $detected = "en"; $detectSource = "CLAUDE"; break }
    }
}
if ($detected -eq "ambiguous" -and (Test-Path $projCopilot)) {
    foreach ($line in (Read-Lines $projCopilot)) {
        if ($line -cmatch '^输出语言：') { $detected = "zh"; $detectSource = "copilot"; break }
        if ($line -cmatch '^Output language:') { $detected = "en"; $detectSource = "copilot"; break }
    }
}
Emit ("DETECT|{0}|{1}" -f $detected, $detectSource)

# Canonical TARGET block + line, extracted from the resolved template.
$tmplCoreLines = Read-Lines $tmplCore
$targetSection = Get-SectionLines $tmplCoreLines $targetHeading
if ($targetSection.Count -eq 0) {
    [Console]::Error.WriteLine("language-policy: could not extract the '$Lang' policy section from $tmplCore.")
    exit 1
}
$targetLine = Get-PolicyLine (Read-Lines $tmplClaude)
if ($null -eq $targetLine) {
    [Console]::Error.WriteLine("language-policy: could not extract the '$Lang' policy line from $tmplClaude.")
    exit 1
}

# --- write the rebuilt line array IFF it differs; .bak first; NOOP on identity ----
function Write-OrNoop($path, $newLines, $label, $verb) {
    $newText = ($newLines -join "`n") + "`n"
    if (Test-Path $path) {
        $cur = [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false))
        if ($cur -ceq $newText) {
            Emit ("{0}|NOOP|{1}|already current" -f (Get-VerbPrefix), $label)
            $script:nNoop++
            return
        }
    }
    Emit ("{0}|{1}|{2}|to {3}" -f (Get-VerbPrefix), $verb, $label, $Lang)
    $script:nRewritten++
    if (-not $DryRun) {
        if (Test-Path $path) {
            $bak = "$path.bak-$stamp"
            Copy-Item -Path $path -Destination $bak -Force
            Emit ("BAK|{0}" -f $bak)
            $script:nBaks++
        }
        [System.IO.File]::WriteAllText($path, $newText, [System.Text.UTF8Encoding]::new($false))
    }
}

# --- 00-core.md: REWRITE-SECTION / INSERT-SECTION / CONFLICT ---------------------
if (Test-Path $projCore) {
    $coreLines = Read-Lines $projCore
    $hasHeading = $false
    foreach ($line in $coreLines) {
        $cmp = $line -replace '[ \t\r]+$', ''
        if ($cmp -ceq $enHeading -or $cmp -ceq $zhHeading) { $hasHeading = $true; break }
    }

    if ($hasHeading) {
        $rebuilt = @()
        $state = 0   # 0=before, 1=inside old section, 2=after
        foreach ($line in $coreLines) {
            $cmp = $line -replace '[ \t\r]+$', ''
            if ($state -eq 0 -and ($cmp -ceq $enHeading -or $cmp -ceq $zhHeading)) {
                $rebuilt += $targetSection
                $state = 1
                continue
            }
            if ($state -eq 1) {
                if ($line -cmatch '^## ') { $state = 2; $rebuilt += $line; continue }
                continue
            }
            $rebuilt += $line
        }
        Write-OrNoop $projCore $rebuilt ".harness/rules/00-core.md" "REWRITE-SECTION"
    } else {
        if (-not $Force) {
            Emit "CONFLICT|section|.harness/rules/00-core.md|no recognizable policy heading"
            $nConflicts++
            $exitCode = 2
        } else {
            $rebuilt = @()
            $inserted = $false
            foreach ($line in $coreLines) {
                if (-not $inserted -and $line -cmatch '^## ') {
                    $rebuilt += $targetSection
                    $inserted = $true
                }
                $rebuilt += $line
            }
            if (-not $inserted) { $rebuilt += $targetSection }
            Write-OrNoop $projCore $rebuilt ".harness/rules/00-core.md" "INSERT-SECTION"
        }
    }
} else {
    Emit ("{0}|SKIP|.harness/rules/00-core.md|absent" -f (Get-VerbPrefix))
    $nSkipped++
}

# --- CLAUDE.md + copilot: REWRITE-LINE (or SKIP) ---------------------------------
function Rewrite-LineFile($path, $label) {
    if (-not (Test-Path $path)) {
        Emit ("{0}|SKIP|{1}|absent" -f (Get-VerbPrefix), $label)
        $script:nSkipped++
        return
    }
    $lines = Read-Lines $path
    $hasLine = $false
    foreach ($line in $lines) {
        if ($line -cmatch '^Output language:' -or $line -cmatch '^输出语言：') { $hasLine = $true; break }
    }
    if (-not $hasLine) {
        Emit ("{0}|SKIP|{1}|policy line not found" -f (Get-VerbPrefix), $label)
        $script:nSkipped++
        return
    }
    $rebuilt = @()
    $done = $false
    foreach ($line in $lines) {
        if (-not $done -and ($line -cmatch '^Output language:' -or $line -cmatch '^输出语言：')) {
            $rebuilt += $targetLine
            $done = $true
            continue
        }
        $rebuilt += $line
    }
    Write-OrNoop $path $rebuilt $label "REWRITE-LINE"
}

Rewrite-LineFile $projClaude "CLAUDE.md"
Rewrite-LineFile $projCopilot ".github/copilot-instructions.md"

Emit ("SUMMARY|rewritten={0} noop={1} skipped={2} baks={3} conflicts={4}" -f $nRewritten, $nNoop, $nSkipped, $nBaks, $nConflicts)
exit $exitCode
