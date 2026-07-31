# guard-rm.ps1 — Destructive-command PreToolUse guard for Claude Code (Windows)
#
# Invoked by .claude/settings.json hooks.PreToolUse before every Bash tool call.
# Reads the tool input as JSON on stdin; exits 0 to allow the command, non-zero
# (exit 2) to BLOCK with a stderr message Claude Code shows in the transcript.
#
# Blocks when ANY destructive verb (rm / rmdir / unlink / Remove-Item / del /
# erase / Clear-RecycleBin / shred / srm / find -delete) targets a path that
# resolves OUTSIDE the nearest .git/ ancestor of cwd.
#
# Override: prepend `HARNESS_ALLOW_OUTSIDE_RM=1 ` to the bash invocation, or set
# `$env:HARNESS_ALLOW_OUTSIDE_RM=1` in PowerShell, for a single call.
#
# See `.harness/rules/75-safety-hook.md` for full contract and disable path.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# 1. Read tool input JSON from stdin
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try {
    $payload = $raw | ConvertFrom-Json
} catch {
    # Unparseable payload — nothing to guard.
    exit 0
}
$cmd = $payload.tool_input.command
if (-not $cmd) { exit 0 }

# 2. Override env var: bail out cheaply.
if ($env:HARNESS_ALLOW_OUTSIDE_RM -eq '1') {
    [Console]::Error.WriteLine('harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.')
    exit 0
}

# 3. Walk up to nearest .git/ ancestor of cwd.
$dir = (Get-Location).Path
$repoRoot = $null
while ($dir) {
    if (Test-Path (Join-Path $dir '.git')) { $repoRoot = $dir; break }
    $parent = Split-Path $dir -Parent
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}
if (-not $repoRoot) {
    [Console]::Error.WriteLine('harness-kit guard-rm: WARN no .git/ ancestor — guard inactive.')
    exit 0
}

# 4. Truncate (boundary B11).
if ($cmd.Length -gt 8192) { $cmd = $cmd.Substring(0, 8192) }

# Destructive verb set.
$destructiveVerbs = @(
    'rm', 'rmdir', 'unlink', 'Remove-Item', 'del', 'erase',
    'Clear-RecycleBin', 'shred', 'srm'
)
# Find-predicate flags whose following arg is non-path.
$findPredicates = @('-name', '-type', '-regex', '-iname', '-perm', '-mtime', '-size', '-path', '-ipath', '-newer')

# 5. Whitespace-aware quote tokenizer. Returns $null on parse failure.
function Get-Tokens([string]$s) {
    $tokens = [System.Collections.Generic.List[string]]::new()
    $cur = New-Object System.Text.StringBuilder
    $inSingle = $false
    $inDouble = $false
    $hasContent = $false
    for ($i = 0; $i -lt $s.Length; $i++) {
        $ch = $s[$i]
        if (-not $inSingle -and -not $inDouble -and ($ch -eq ' ' -or $ch -eq "`t")) {
            if ($hasContent) {
                $tokens.Add($cur.ToString())
                [void]$cur.Clear()
                $hasContent = $false
            }
            continue
        }
        if (-not $inDouble -and $ch -eq "'") {
            $inSingle = -not $inSingle
            $hasContent = $true
            continue
        }
        if (-not $inSingle -and $ch -eq '"') {
            $inDouble = -not $inDouble
            $hasContent = $true
            continue
        }
        [void]$cur.Append($ch)
        $hasContent = $true
    }
    if ($inSingle -or $inDouble) { return $null }
    if ($hasContent) { $tokens.Add($cur.ToString()) }
    # Return as string array (not List) to prevent caller's array-coercion bugs.
    return ,$tokens.ToArray()
}

# 6. Split top-level pipes (not inside quotes).
function Split-Pipes([string]$s) {
    $segments = [System.Collections.Generic.List[string]]::new()
    $cur = New-Object System.Text.StringBuilder
    $inSingle = $false; $inDouble = $false
    for ($i = 0; $i -lt $s.Length; $i++) {
        $ch = $s[$i]
        if (-not $inDouble -and $ch -eq "'") { $inSingle = -not $inSingle }
        elseif (-not $inSingle -and $ch -eq '"') { $inDouble = -not $inDouble }
        if ($ch -eq '|' -and -not $inSingle -and -not $inDouble) {
            $segments.Add($cur.ToString().Trim())
            [void]$cur.Clear()
            continue
        }
        [void]$cur.Append($ch)
    }
    $segments.Add($cur.ToString().Trim())
    return ,$segments.ToArray()
}

# 7. Path normalize (leaf-only; no realpath / symlink chase).
function Resolve-AbsoluteLeaf([string]$p, [string]$cwd) {
    $abs = $p
    # Strip surrounding quotes if any left over (defense-in-depth).
    if ($abs.StartsWith('"') -and $abs.EndsWith('"')) { $abs = $abs.Substring(1, $abs.Length - 2) }
    if ($abs.StartsWith("'") -and $abs.EndsWith("'")) { $abs = $abs.Substring(1, $abs.Length - 2) }
    # Expand ~ (home dir). Note: $home is a built-in pwsh auto-variable; use a different name.
    if ($abs -eq '~' -or $abs.StartsWith('~/') -or $abs.StartsWith('~\')) {
        $homePath = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
        if ($abs -eq '~') { $abs = $homePath } else { $abs = Join-Path $homePath $abs.Substring(2) }
    }
    $isAbs = $false
    if ($abs.Length -ge 1 -and ($abs[0] -eq '/' -or $abs[0] -eq '\')) { $isAbs = $true }
    if ($abs.Length -ge 2 -and $abs[1] -eq ':') { $isAbs = $true }  # Windows drive
    if (-not $isAbs) { $abs = Join-Path $cwd $abs }
    # Normalize: collapse .. and . segments without touching the filesystem.
    $sep = [IO.Path]::DirectorySeparatorChar
    $sepStr = "$sep"
    $normalized = $abs -replace '/', $sepStr
    $parts = $normalized.Split($sep)
    $stack = [System.Collections.Generic.List[string]]::new()
    for ($si = 0; $si -lt $parts.Length; $si++) {
        $part = $parts[$si]
        if ($part -eq '' -or $part -eq '.') {
            if ($stack.Count -eq 0 -and $part -eq '') { $stack.Add('') }
            continue
        }
        if ($part -eq '..') {
            if ($stack.Count -gt 1) { $stack.RemoveAt($stack.Count - 1) }
            continue
        }
        $stack.Add($part)
    }
    $arr = $stack.ToArray()
    $result = [string]::Join($sepStr, $arr)
    if ($result -eq '') { $result = $sepStr }
    return $result
}

function Test-IsDescendant([string]$child, [string]$parent) {
    $c = $child.TrimEnd('\','/')
    $p = $parent.TrimEnd('\','/')
    if ([string]::Equals($c, $p, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    $sep = [IO.Path]::DirectorySeparatorChar
    return $c.StartsWith($p + $sep, [StringComparison]::OrdinalIgnoreCase) -or `
           $c.StartsWith($p + '/', [StringComparison]::OrdinalIgnoreCase) -or `
           $c.StartsWith($p + '\', [StringComparison]::OrdinalIgnoreCase)
}

# 8. Classify a single segment and collect offending paths.
function Get-OffendingFromSegment {
    param([string]$segment, [int]$depth)
    $offending = @()
    if ($depth -gt 2) {
        return ,@('__PARSE_FAIL__')
    }
    $tokens = Get-Tokens $segment
    if ($null -eq $tokens) {
        return ,@('__PARSE_FAIL__')
    }
    if ($tokens.Count -eq 0) { return $offending }

    # Strip leading sudo (and optional -E / -H / -u <user>).
    $idx = 0
    if ($tokens[$idx] -eq 'sudo') {
        $idx++
        while ($idx -lt $tokens.Count) {
            $t = $tokens[$idx]
            if ($t -eq '-E' -or $t -eq '-H') { $idx++; continue }
            if ($t -eq '-u' -and $idx + 1 -lt $tokens.Count) { $idx += 2; continue }
            break
        }
    }
    if ($idx -ge $tokens.Count) { return $offending }
    $verb = $tokens[$idx]
    $afterVerb = $idx + 1

    # Nested pwsh / powershell.
    if ($verb -ieq 'pwsh' -or $verb -ieq 'powershell') {
        # Find -c / -Command and re-tokenize the next arg.
        for ($j = $afterVerb; $j -lt $tokens.Count; $j++) {
            $t = $tokens[$j]
            if ($t -ieq '-c' -or $t -ieq '-Command' -or $t -ieq '-CommandWithArgs' -or $t -eq '/c') {
                if ($j + 1 -ge $tokens.Count) { return ,@('__PARSE_FAIL__') }
                $nested = $tokens[$j + 1]
                $sub = Get-OffendingFromSegment -segment $nested -depth ($depth + 1)
                foreach ($x in $sub) { $offending += $x }
                return $offending
            }
        }
        return $offending  # pwsh without -c is harmless
    }

    # find with -delete is destructive; otherwise non-destructive.
    if ($verb -eq 'find') {
        $hasDelete = $false
        foreach ($t in $tokens) { if ($t -eq '-delete') { $hasDelete = $true; break } }
        if (-not $hasDelete) { return $offending }
        # Path args are positional before the first predicate flag.
        for ($j = $afterVerb; $j -lt $tokens.Count; $j++) {
            $t = $tokens[$j]
            if ($t.StartsWith('-')) { break }  # first predicate stops path-arg list
            $abs = Resolve-AbsoluteLeaf -p $t -cwd (Get-Location).Path
            if (-not (Test-IsDescendant -child $abs -parent $repoRoot)) {
                $offending += $abs
            }
        }
        return $offending
    }

    # Other destructive verbs.
    $isDestructive = $false
    foreach ($v in $destructiveVerbs) {
        if ($verb -ieq $v) { $isDestructive = $true; break }
    }
    if (-not $isDestructive) { return $offending }

    # Walk remaining tokens; skip flags. Find-predicate-style next-arg skip
    # applies ONLY when $verb is 'find' (the only verb that actually accepts
    # those predicates). Applying it generically allowed `rm -path /etc`,
    # `rm -name /etc/passwd`, `Remove-Item -Path C:\Windows` (PowerShell's
    # case-insensitive -contains matched -Path against -path) to bypass.
    # See 06_TEST_REPORT.md D-1 / D-2.
    $skipNext = $false
    $afterDoubleDash = $false
    for ($j = $afterVerb; $j -lt $tokens.Count; $j++) {
        $t = $tokens[$j]
        if ($skipNext) { $skipNext = $false; continue }
        if (-not $afterDoubleDash) {
            if ($t -eq '--') { $afterDoubleDash = $true; continue }
            if ($t.StartsWith('-') -and $t.Length -gt 1) {
                # NOTE: find-predicate skip intentionally disabled here.
                # `find` is handled in its own branch above (line ~214); no
                # other destructive verb takes `-name`/`-path`/etc., so any
                # such flag on `rm`/`Remove-Item` is either user error or
                # adversarial — block by treating subsequent tokens as paths.
                continue
            }
        }
        # Treat as path token.
        $abs = Resolve-AbsoluteLeaf -p $t -cwd (Get-Location).Path
        if (-not (Test-IsDescendant -child $abs -parent $repoRoot)) {
            $offending += $abs
        }
    }
    return $offending
}

# 9. Walk pipe segments.
$allOffending = @()
$parseFailed = $false
foreach ($seg in (Split-Pipes $cmd)) {
    if (-not $seg) { continue }
    $found = Get-OffendingFromSegment -segment $seg -depth 0
    foreach ($x in $found) {
        if ($x -eq '__PARSE_FAIL__') { $parseFailed = $true; continue }
        $allOffending += $x
    }
}

if ($parseFailed) {
    [Console]::Error.WriteLine('harness-kit guard-rm: BLOCKED — could not parse nested pwsh command safely; override with HARNESS_ALLOW_OUTSIDE_RM=1 if intended.')
    exit 2
}

if ($allOffending.Count -eq 0) { exit 0 }

# 10. Emit BLOCK message.
$truncCmd = if ($cmd.Length -gt 300) { $cmd.Substring(0, 300) } else { $cmd }
[Console]::Error.WriteLine('harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.')
[Console]::Error.WriteLine("  Command: $truncCmd")
[Console]::Error.WriteLine('  Offending path(s):')
foreach ($p in $allOffending) {
    [Console]::Error.WriteLine("    - $p (outside $repoRoot)")
}
[Console]::Error.WriteLine('  Override (only if you really mean this): re-issue the command with the env var')
[Console]::Error.WriteLine('    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.')
[Console]::Error.WriteLine('  See .harness/rules/75-safety-hook.md to fully disable.')
exit 2
