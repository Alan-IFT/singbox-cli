#!/usr/bin/env bash
# guard-rm.sh — Destructive-command PreToolUse guard for Claude Code (Unix)
#
# Invoked by .claude/settings.json hooks.PreToolUse before every Bash tool call.
# Reads the tool input as JSON on stdin; exits 0 to allow the command, non-zero
# (exit 2) to BLOCK with a stderr message Claude Code shows in the transcript.
#
# Blocks when ANY destructive verb (rm / rmdir / unlink / Remove-Item / del /
# erase / Clear-RecycleBin / shred / srm / find -delete) targets a path that
# resolves OUTSIDE the nearest .git/ ancestor of cwd.
#
# Override: prepend `HARNESS_ALLOW_OUTSIDE_RM=1 ` to the bash invocation for a
# single call.
#
# See `.harness/rules/75-safety-hook.md` for full contract and disable path.

# NOTE: do NOT use `declare -a` under `set -u` — empty-array reads crash.
# Use bare `name=()` instead (insight 2026-05-16 declare-a-under-set-u).
set -uo pipefail

# 1. Read tool input JSON from stdin.
payload=$(cat - 2>/dev/null || true)
if [[ -z "$payload" ]]; then exit 0; fi

# Extract .tool_input.command. Use python only if it actually works (Windows can
# have a Microsoft-Store stub that fakes `command -v` success but exits non-zero
# on real invocation; we test with a tiny script before trusting it).
cmd=""
have_python=0
if command -v python3 >/dev/null 2>&1; then
    if echo '' | python3 -c 'pass' >/dev/null 2>&1; then have_python=1; fi
fi
if (( have_python == 1 )); then
    cmd=$(python3 -c '
import sys, json
try:
    data = json.loads(sys.stdin.read())
    print(data.get("tool_input", {}).get("command", ""), end="")
except Exception:
    pass
' <<<"$payload" 2>/dev/null || true)
fi
if [[ -z "$cmd" ]]; then
    # Heuristic fallback for the one-level Claude Code shape: greedy-match
    # everything between `"command":"` and the closing `"}` (handles nested
    # \" by being lazy about the right anchor — the closing `"}` is what
    # actually terminates the field in Claude Code's emitted JSON).
    cmd=$(printf '%s' "$payload" \
        | tr -d '\n' \
        | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"[[:space:]]*}.*/\1/p' \
        | head -1)
    # Unescape JSON \" -> " and \\ -> \. Order matters: do \" first so a literal
    # \\ stays \\ and then becomes \.
    cmd="${cmd//\\\"/\"}"
    cmd="${cmd//\\\\/\\}"
fi
[[ -z "$cmd" ]] && exit 0

# 2. Override env var: bail out cheaply.
if [[ "${HARNESS_ALLOW_OUTSIDE_RM:-}" == "1" ]]; then
    echo "harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command." >&2
    exit 0
fi

# 3. Walk up to nearest .git/ ancestor of cwd.
dir="$PWD"
repo_root=""
while [[ -n "$dir" ]]; do
    if [[ -d "$dir/.git" ]]; then repo_root="$dir"; break; fi
    parent=$(dirname "$dir")
    if [[ "$parent" == "$dir" ]]; then break; fi
    dir="$parent"
done
if [[ -z "$repo_root" ]]; then
    echo "harness-kit guard-rm: WARN no .git/ ancestor — guard inactive." >&2
    exit 0
fi

# 4. Truncate command (boundary B11).
cmd="${cmd:0:8192}"

# Verb sets (case-sensitive for bash verbs; Remove-Item etc. case-insensitive).
destructive_verbs_ci="rm rmdir unlink Remove-Item del erase Clear-RecycleBin shred srm"
find_predicates="-name -type -regex -iname -perm -mtime -size -path -ipath -newer"

# 5. Whitespace-aware quote tokenizer.
# Writes tokens into the global array _TOKENS.
# Returns 0 on success, 1 on parse failure (unbalanced quotes).
_TOKENS=()
tokenize() {
    local s="$1"
    _TOKENS=()
    local cur=""
    local in_single=0 in_double=0 has_content=0
    local i=0 ch=""
    local len=${#s}
    while (( i < len )); do
        ch="${s:$i:1}"
        if (( in_single == 0 && in_double == 0 )) && [[ "$ch" == " " || "$ch" == $'\t' ]]; then
            if (( has_content == 1 )); then
                _TOKENS+=("$cur"); cur=""; has_content=0
            fi
            ((i++)); continue
        fi
        if (( in_double == 0 )) && [[ "$ch" == "'" ]]; then
            in_single=$(( 1 - in_single )); has_content=1; ((i++)); continue
        fi
        if (( in_single == 0 )) && [[ "$ch" == '"' ]]; then
            in_double=$(( 1 - in_double )); has_content=1; ((i++)); continue
        fi
        cur="${cur}${ch}"; has_content=1
        ((i++))
    done
    if (( in_single == 1 || in_double == 1 )); then return 1; fi
    if (( has_content == 1 )); then _TOKENS+=("$cur"); fi
    return 0
}

# 6. Split top-level pipes into segments (not inside quotes).
# Writes into the global array _SEGS.
_SEGS=()
split_pipes() {
    local s="$1"
    _SEGS=()
    local cur=""
    local in_single=0 in_double=0
    local i=0 ch=""
    local len=${#s}
    while (( i < len )); do
        ch="${s:$i:1}"
        if (( in_double == 0 )) && [[ "$ch" == "'" ]]; then in_single=$(( 1 - in_single )); fi
        if (( in_single == 0 )) && [[ "$ch" == '"' ]]; then in_double=$(( 1 - in_double )); fi
        if [[ "$ch" == "|" ]] && (( in_single == 0 && in_double == 0 )); then
            local trimmed="${cur#"${cur%%[![:space:]]*}"}"
            trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
            _SEGS+=("$trimmed")
            cur=""
            ((i++)); continue
        fi
        cur="${cur}${ch}"
        ((i++))
    done
    local trimmed="${cur#"${cur%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    _SEGS+=("$trimmed")
}

# 7. Path normalize (leaf-only; no realpath / symlink chase).
resolve_leaf() {
    local p="$1" cwd="$2"
    # Strip surrounding quotes if any.
    if [[ "$p" == \"*\" ]]; then p="${p:1:${#p}-2}"; fi
    if [[ "$p" == \'*\' ]]; then p="${p:1:${#p}-2}"; fi
    # Expand ~.
    if [[ "$p" == "~" ]]; then p="${HOME:-/}"
    elif [[ "$p" == "~/"* ]]; then p="${HOME:-/}/${p#~/}"; fi
    local abs="$p"
    # Determine absolute: unix /…, Windows-style /…, or drive-letter X:…
    case "$abs" in
        /*|\\*) ;;
        [A-Za-z]:*) ;;
        *) abs="$cwd/$abs" ;;
    esac
    # Collapse .. and . segments.
    local IFS='/'
    # shellcheck disable=SC2206
    local parts=($abs)
    local stack=()
    local first=1
    local part
    for part in "${parts[@]+"${parts[@]}"}"; do
        if (( first == 1 )); then
            stack+=("$part"); first=0; continue
        fi
        if [[ -z "$part" || "$part" == "." ]]; then continue; fi
        if [[ "$part" == ".." ]]; then
            if (( ${#stack[@]} > 1 )); then unset 'stack[${#stack[@]}-1]'; fi
            continue
        fi
        stack+=("$part")
    done
    local result
    result=$(IFS='/'; printf '%s' "${stack[*]+"${stack[*]}"}")
    [[ -z "$result" ]] && result="/"
    printf '%s' "$result"
}

is_descendant() {
    local child="$1" parent="$2"
    # Strip trailing slashes.
    child="${child%/}"; child="${child%\\}"
    parent="${parent%/}"; parent="${parent%\\}"
    [[ "$child" == "$parent" ]] && return 0
    [[ "$child" == "$parent/"* ]] && return 0
    return 1
}

# 8. Classify a segment. Writes offending paths to $segment_offending (global) and
#    sets parse_failed=1 on tokenizer / nested-pwsh parse failure.
parse_failed=0
segment_offending=()

classify_segment() {
    local segment="$1" depth="$2"
    if (( depth > 2 )); then parse_failed=1; return; fi
    if ! tokenize "$segment"; then parse_failed=1; return; fi
    # Snapshot tokens to a local array immediately — recursive calls re-fill _TOKENS.
    local tokens=("${_TOKENS[@]+"${_TOKENS[@]}"}")
    if (( ${#tokens[@]} == 0 )); then return; fi

    local idx=0
    # Strip leading sudo + optional -E/-H/-u <user>.
    if [[ "${tokens[0]}" == "sudo" ]]; then
        idx=1
        while (( idx < ${#tokens[@]} )); do
            local t="${tokens[$idx]}"
            if [[ "$t" == "-E" || "$t" == "-H" ]]; then ((idx++)); continue; fi
            if [[ "$t" == "-u" ]] && (( idx + 1 < ${#tokens[@]} )); then idx=$((idx + 2)); continue; fi
            break
        done
    fi
    (( idx >= ${#tokens[@]} )) && return
    local verb="${tokens[$idx]}"
    local after_verb=$((idx + 1))

    # Nested pwsh / powershell.
    local verb_lc; verb_lc=$(printf '%s' "$verb" | tr '[:upper:]' '[:lower:]')
    if [[ "$verb_lc" == "pwsh" || "$verb_lc" == "powershell" ]]; then
        local j=$after_verb
        while (( j < ${#tokens[@]} )); do
            local t="${tokens[$j]}"
            local t_lc; t_lc=$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')
            if [[ "$t_lc" == "-c" || "$t_lc" == "-command" || "$t_lc" == "-commandwithargs" || "$t" == "/c" ]]; then
                if (( j + 1 >= ${#tokens[@]} )); then parse_failed=1; return; fi
                classify_segment "${tokens[$((j+1))]}" $((depth + 1))
                return
            fi
            ((j++))
        done
        return
    fi

    # find with -delete.
    if [[ "$verb" == "find" ]]; then
        local has_delete=0
        local t
        for t in "${tokens[@]+"${tokens[@]}"}"; do
            if [[ "$t" == "-delete" ]]; then has_delete=1; break; fi
        done
        (( has_delete == 0 )) && return
        local j=$after_verb
        while (( j < ${#tokens[@]} )); do
            t="${tokens[$j]}"
            if [[ "$t" == -* ]]; then break; fi
            local abs; abs=$(resolve_leaf "$t" "$PWD")
            if ! is_descendant "$abs" "$repo_root"; then
                segment_offending+=("$abs")
            fi
            ((j++))
        done
        return
    fi

    # Other destructive verbs (case-insensitive match).
    local is_destructive=0
    local v
    for v in $destructive_verbs_ci; do
        if [[ "$verb_lc" == "$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')" ]]; then
            is_destructive=1; break
        fi
    done
    (( is_destructive == 0 )) && return

    # Walk remaining tokens; skip flags. Find-predicate-style next-arg skip
    # applies ONLY when verb is 'find' (handled in its own branch above).
    # Applying it generically allowed `rm -path /etc`, `rm -name /etc/passwd`
    # to bypass. See 06_TEST_REPORT.md D-1 / D-2.
    local skip_next=0 after_dd=0
    local j=$after_verb
    while (( j < ${#tokens[@]} )); do
        local t="${tokens[$j]}"
        if (( skip_next == 1 )); then skip_next=0; ((j++)); continue; fi
        if (( after_dd == 0 )); then
            if [[ "$t" == "--" ]]; then after_dd=1; ((j++)); continue; fi
            if [[ "$t" == -* && "${#t}" -gt 1 ]]; then
                # NOTE: find-predicate skip intentionally disabled here.
                # No destructive verb other than `find` takes -name/-path/etc.,
                # so any such flag is either user error or adversarial — treat
                # subsequent tokens as paths.
                ((j++)); continue
            fi
        fi
        local abs; abs=$(resolve_leaf "$t" "$PWD")
        if ! is_descendant "$abs" "$repo_root"; then
            segment_offending+=("$abs")
        fi
        ((j++))
    done
}

# 9. Walk pipe segments.
all_offending=()
split_pipes "$cmd"
# Snapshot _SEGS — tokenize/classify_segment will clobber globals.
segments=("${_SEGS[@]+"${_SEGS[@]}"}")
for seg in "${segments[@]+"${segments[@]}"}"; do
    [[ -z "$seg" ]] && continue
    segment_offending=()
    classify_segment "$seg" 0
    if (( parse_failed == 1 )); then break; fi
    for off in "${segment_offending[@]+"${segment_offending[@]}"}"; do
        all_offending+=("$off")
    done
done

if (( parse_failed == 1 )); then
    echo "harness-kit guard-rm: BLOCKED — could not parse nested pwsh command safely; override with HARNESS_ALLOW_OUTSIDE_RM=1 if intended." >&2
    exit 2
fi

(( ${#all_offending[@]} == 0 )) && exit 0

# 10. Emit BLOCK message.
trunc_cmd="${cmd:0:300}"
{
    printf 'harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.\n'
    printf '  Command: %s\n' "$trunc_cmd"
    printf '  Offending path(s):\n'
    for p in "${all_offending[@]}"; do
        printf '    - %s (outside %s)\n' "$p" "$repo_root"
    done
    printf '  Override (only if you really mean this): re-issue the command with the env var\n'
    printf '    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.\n'
    printf '  See .harness/rules/75-safety-hook.md to fully disable.\n'
} >&2
exit 2
