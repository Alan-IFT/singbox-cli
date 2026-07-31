#!/usr/bin/env bash
# migrate-scripts-layout.sh — One-shot upgrade: scripts/ -> .harness/scripts/ (T-007)
# Mirror of migrate-scripts-layout.ps1. See that file for full doc.
#
# For an already-initialized Harness project that placed its harness-owned scripts
# under scripts/. Moves the known harness-owned scripts to .harness/scripts/ and
# rewires the two hook command strings in .claude/settings.json.
#
# Idempotent: a second run is a clean no-op (exit 0). Only the KNOWN harness-owned
# set is touched; your own scripts/<custom> files are never moved.
#
# Usage:
#   bash .harness/scripts/migrate-scripts-layout.sh             # migrate
#   bash .harness/scripts/migrate-scripts-layout.sh --dry-run   # print plan, change nothing
#   bash .harness/scripts/migrate-scripts-layout.sh --force     # overwrite existing targets
#
# Exit codes:
#   0  migrated, or already migrated / nothing to do
#   1  user error (no .claude/settings.json)
#   4  end-state assertion failure (T-020): a wired hook command references (or, in
#      dry-run, would reference) a missing script, or a move did not land.
#      Remediation: run /harness-upgrade to re-land current scripts + rewire hooks.

set -uo pipefail

DRY_RUN=false
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force)   FORCE=true ;;
        *) echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

# Run from the project root (the directory that contains .claude/ and scripts/).
root="$(pwd)"
settings="$root/.claude/settings.json"
src_dir="$root/scripts"
dst_dir="$root/.harness/scripts"

if [[ ! -f "$settings" ]]; then
    echo "migrate-scripts-layout: no .claude/settings.json found at $settings." >&2
    echo "  Run this from the root of an initialized Harness project." >&2
    exit 1
fi

# Known harness-owned movable set (filename-preserved). NOT a blanket scripts/*.
# verification_history.log is intentionally excluded — it regenerates at the new path.
known=(
    verify_all.ps1 verify_all.sh
    harness-sync.ps1 harness-sync.sh
    guard-rm.ps1 guard-rm.sh
    install-hooks.ps1 install-hooks.sh
    archive-task.ps1 archive-task.sh
    baseline.json
)

in_git=false
[[ -d "$root/.git" ]] && in_git=true

plan=()
planned_moves=""
move_failed=false

for name in "${known[@]}"; do
    src="$src_dir/$name"
    dst="$dst_dir/$name"
    [[ -f "$src" ]] || continue
    if [[ -e "$dst" && "$FORCE" == false ]]; then
        plan+=("SKIP  scripts/$name (already present at .harness/scripts/$name; use --force to overwrite)")
        continue
    fi
    plan+=("MOVE  scripts/$name -> .harness/scripts/$name")
    planned_moves="$planned_moves $name"
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$dst_dir"
        tracked=false
        if [[ "$in_git" == true ]] && git ls-files --error-unmatch "scripts/$name" &>/dev/null; then
            tracked=true
        fi
        if [[ "$tracked" == true ]]; then
            [[ "$FORCE" == true && -e "$dst" ]] && rm -f "$dst"
            git mv -f "scripts/$name" ".harness/scripts/$name" >/dev/null
        else
            mv -f "$src" "$dst"
        fi
        # Move verification (T-020 / FR-P2): under `set -uo` (no -e) a failed git mv /
        # mv would otherwise pass silently. A failed move leaves the source in place,
        # so the presence-gated settings rewire below simply stays OFF for that
        # variant — no new dangle is ever created by a failed move; the run is marked
        # incongruent and exits 4.
        if [[ ! -f "$dst" ]]; then
            plan+=("MOVE-FAILED  scripts/$name (move did not land — see git output above)")
            move_failed=true
        fi
    fi
done

# target_present <name>: is .harness/scripts/<name> on disk (apply mode: moves above
# already ran, disk is ground truth) or projected to land there (dry-run: a planned
# MOVE counts)? Gates the per-variant settings rewire below (T-020 / FR-P2).
target_present() {
    local tp_name="$1"
    [[ -f "$dst_dir/$tp_name" ]] && return 0
    if [[ "$DRY_RUN" == true ]]; then
        case " $planned_moves " in *" $tp_name "*) return 0 ;; esac
    fi
    return 1
}

# resilient_cmd <tool> <is_windows> — print the T-12 RESILIENT hook command string,
# JSON-escaped (inner " as \"). Convenience hooks (harness-sync) fail-OPEN + anchored to
# $CLAUDE_PROJECT_DIR; guard-rm (safety) fail-CLOSED (no exit-0 fallback). The space-
# preceded bare `.harness/scripts/<tool>.<ext>` token survives so the unchanged left-
# bounded congruence ERE still parses + existence-checks it (OQ-3a).
resilient_cmd() {
    local rc_tool="$1" rc_win="$2"
    if [[ "$rc_win" == true ]]; then
        if [[ "$rc_tool" == "guard-rm" ]]; then
            printf '%s' "pwsh -NoProfile -Command \\\"Set-Location -LiteralPath \$env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/$rc_tool.ps1\\\""
        else
            printf '%s' "pwsh -NoProfile -Command \\\"Set-Location -LiteralPath \$env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/$rc_tool.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/$rc_tool.ps1 }; exit 0\\\""
        fi
    else
        if [[ "$rc_tool" == "guard-rm" ]]; then
            printf '%s' "sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && bash .harness/scripts/$rc_tool.sh'"
        else
            printf '%s' "sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && [ -f .harness/scripts/$rc_tool.sh ] && exec bash .harness/scripts/$rc_tool.sh || exit 0'"
        fi
    fi
}

# str_replace_all <haystack> <needle> <replacement> — literal replace-all immune to
# bash 5.2's `&`-means-matched-text rule in ${var//pat/repl} (the resilient command
# carries a literal `&`). Splits on the needle and concatenates verbatim. Mirrors PS
# String.Replace (already literal).
str_replace_all() {
    local rest="$1" needle="$2" repl="$3" out=""
    while [[ "$rest" == *"$needle"* ]]; do
        out="$out${rest%%"$needle"*}$repl"
        rest="${rest#*"$needle"}"
    done
    printf '%s' "$out$rest"
}

# Settings rewire — surgical substring replace on the RAW text (never re-serialize:
# that would reorder keys and strip _comment / _doc_sync_hook doc keys). Replaces
# ALL occurrences of the harness command path prefixes (Stop command, PreToolUse
# command, permissions.allow entry, _doc_sync_hook doc string).
# T-020 (RC-1 fix): each of the four {harness-sync,guard-rm} x {ps1,sh} variants is
# rewired ONLY when its target is (projected) present at .harness/scripts/ — a rewire
# can no longer point a hook at a file that never landed. The unconditional double-
# prefix collapse stays last, so the transform remains a fixed point: already-migrated
# text maps to itself and a second run is a true no-op (no .bak, no write).
# Known cosmetic nuance (gate F-4): when only ONE shell variant's target is present,
# doc strings that mention both variants end half-migrated (the absent variant keeps
# the old path). Idempotent and harmless — the congruence scan below only checks
# "command" lines, never doc keys.
settings_new="$(cat "$settings")"
for tool_ext in harness-sync.ps1 harness-sync.sh guard-rm.ps1 guard-rm.sh; do
    if target_present "$tool_ext"; then
        tool_base="${tool_ext%.*}"
        tool_suffix="${tool_ext##*.}"
        settings_new="$(printf '%s\n' "$settings_new" \
            | sed -e "s|scripts/$tool_base\.$tool_suffix|.harness/scripts/$tool_base.$tool_suffix|g")"
    fi
done
settings_new="$(printf '%s\n' "$settings_new" | sed -e 's|\.harness/\.harness/scripts/|.harness/scripts/|g')"

# Brittle -> resilient rewrite (T-12 / A8, design §4.3). The prefix rewire above only
# adds `.harness/`; it does NOT make the hook fail-open/closed + $CLAUDE_PROJECT_DIR-
# anchored. For each {tool}x{ext}, if the `.harness/`-prefixed brittle command VALUE is
# present verbatim AND its target is (projected) present, swap the WHOLE value for the
# OS-picked resilient string. Pure ordinal bash substring replace (no sed) so the
# resilient `&`/`|`/`;` are inert. Double-quote-bounded needle -> idempotent (a second
# run sees the resilient value, not the bare brittle "command", so no .bak churn — B10)
# and gated on target_present so a brittle command pointing at a missing script is left
# for the terminal scan to flag. R4: only the harness tool names are eligible.
for s32_tool in harness-sync guard-rm ambient-prompt ambient-reset; do
    for s32_ext in ps1 sh; do
        s32_target="$s32_tool.$s32_ext"
        target_present "$s32_target" || continue
        if [[ "$s32_ext" == "ps1" ]]; then
            s32_brittle="pwsh -NoProfile -File .harness/scripts/$s32_target"
            s32_win=true
        else
            s32_brittle="bash .harness/scripts/$s32_target"
            s32_win=false
        fi
        s32_needle="\"$s32_brittle\""
        if [[ "$settings_new" == *"$s32_needle"* ]]; then
            s32_cmd="$(resilient_cmd "$s32_tool" "$s32_win")"
            settings_new="$(str_replace_all "$settings_new" "$s32_needle" "\"$s32_cmd\"")"
        fi
    done
done

needs_settings=false
if [[ "$settings_new" != "$(cat "$settings")" ]]; then
    needs_settings=true
fi

if [[ "$needs_settings" == true ]]; then
    plan+=("EDIT  .claude/settings.json (rewire harness-sync + guard-rm hook paths)")
    if [[ "$DRY_RUN" == false ]]; then
        stamp="$(date +%Y%m%dT%H%M%S)"
        bak="$settings.bak-$stamp"
        cp "$settings" "$bak"
        printf '%s\n' "$settings_new" > "$settings"
        echo "Backed up settings.json -> $bak"
    fi
fi

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
# The path ERE is LEFT-BOUNDED (quote / space / `=` / line start) so a custom hook
# whose dirname merely ENDS in `scripts/` (e.g. build-scripts/deploy.sh) can never
# match (gate C1). Anything the ERE cannot parse is ignored — fail-open diagnosis
# (R4): the scan only flags PARSED tokens whose target file is missing.
# Line-scoping to "command" lines is deliberate: permissions.allow entries and the
# _doc_sync_hook / _ambient_hook doc strings mention BOTH shell variants and must not
# force both to exist (only the wired variant is load-bearing).
cong_lines=()
ph_open="{{"   # assembled at runtime: this shipped helper must not carry a literal token
if [[ "$DRY_RUN" == true ]]; then
    scan_text="$settings_new"
else
    scan_text="$(cat "$settings")"
fi
while IFS= read -r cmd_line; do
    case "$cmd_line" in *'"command"'*) : ;; *) continue ;; esac
    trimmed="$(printf '%s' "$cmd_line" | sed -e 's|^[[:space:]]*||' -e 's|[[:space:]]*$||')"
    if [[ "$cmd_line" == *"$ph_open"* ]]; then
        cong_lines+=("CONGRUENCE-FAIL  $trimmed -> unresolved placeholder token")
    fi
    while IFS= read -r ref_path; do
        [[ -z "$ref_path" ]] && continue
        present=false
        [[ -f "$root/$ref_path" ]] && present=true
        if [[ "$present" == false && "$DRY_RUN" == true ]]; then
            case "$ref_path" in
                .harness/scripts/*)
                    ref_name="${ref_path#.harness/scripts/}"
                    case " $planned_moves " in *" $ref_name "*) present=true ;; esac
                    ;;
            esac
        fi
        [[ "$present" == false ]] && cong_lines+=("CONGRUENCE-FAIL  $trimmed -> missing $ref_path")
    done < <(printf '%s\n' "$cmd_line" \
        | grep -oE "(^|[\"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)" \
        | sed -E "s|^[\"' =]||" \
        | sort -u)
done <<< "$scan_text"

print_congruence() {
    (( ${#cong_lines[@]} == 0 )) && return 0
    local cl
    for cl in "${cong_lines[@]}"; do echo "  $cl"; done
    echo "  hint: run /harness-upgrade to re-land current scripts and rewire hook paths"
}

final_exit=0
if [[ "$move_failed" == true ]] || (( ${#cong_lines[@]} > 0 )); then
    final_exit=4
fi

if (( ${#plan[@]} == 0 )); then
    if (( final_exit == 0 )); then
        echo "Already migrated / nothing to do."
        exit 0
    fi
    echo "=== migrate-scripts-layout ==="
    print_congruence
    exit "$final_exit"
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "=== migrate-scripts-layout (dry run) ==="
    for p in "${plan[@]}"; do echo "  $p"; done
    print_congruence
    echo "(dry run — no changes written)"
    exit "$final_exit"
fi

echo "=== migrate-scripts-layout ==="
for p in "${plan[@]}"; do echo "  $p"; done
print_congruence
if (( final_exit == 0 )); then
    echo "Done."
fi
exit "$final_exit"
