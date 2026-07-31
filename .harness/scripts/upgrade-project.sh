#!/usr/bin/env bash
# upgrade-project.sh — Deterministic mechanical layer for /harness-upgrade (T-012).
# Mirror of upgrade-project.ps1. See that file for the full doc + stdout contract.
#
# Brings an already-initialized but STALE harness project up to the current plugin
# layout: relocate scripts to .harness/scripts/, content-refresh the depth-sensitive
# scripts from the current template (so their two-up repo-root derivation is correct —
# relocation alone is NOT enough; insight L31 / DO-1), re-install the pre-commit hook,
# rewire .claude/settings.json hook paths (raw-text, never re-serialized), and
# regenerate verify_all from the current type template while preserving the user's
# B.* customizations.
#
# Run from the PROJECT ROOT. cwd-derived (depth-independent).
#
# Usage:
#   bash upgrade-project.sh --template-root <abs> --type generic --stack "Rust CLI"
#   bash upgrade-project.sh --template-root <abs> --type fullstack --dry-run
#
# Exit codes: 0 success; 1 precondition error; 2 verify_all refresh-blocked (no --force);
#             3 hook conflict (non-stock pre-commit);
#             4 post-run hook<->script congruence failure (T-020): a wired hook command
#               references (apply) or would reference (dry-run) a missing script, or
#               carries an unresolved placeholder token. Exit 4 overrides 2/3 — the
#               co-occurring CONFLICT records are still all on stdout.

set -uo pipefail

DRY_RUN=false
FORCE=false
TYPE=""
STACK=""
PROJECT_NAME=""
TEMPLATE_ROOT=""
TODAY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)        DRY_RUN=true; shift ;;
        --force)          FORCE=true; shift ;;
        --type)           TYPE="${2:-}"; shift 2 ;;
        --stack)          STACK="${2:-}"; shift 2 ;;
        --project-name)   PROJECT_NAME="${2:-}"; shift 2 ;;
        --template-root)  TEMPLATE_ROOT="${2:-}"; shift 2 ;;
        --today)          TODAY="${2:-}"; shift 2 ;;
        *) echo "upgrade-project: unknown argument: $1" >&2; exit 1 ;;
    esac
done

root="$(pwd)"

# --- preconditions --------------------------------------------------------------
if [[ -z "$TEMPLATE_ROOT" ]]; then
    echo "upgrade-project: --template-root is required (the resolved plugin template cache root)." >&2
    exit 1
fi
template_common_scripts="$TEMPLATE_ROOT/skills/harness-init/templates/common/.harness/scripts"
template_type_scripts="$TEMPLATE_ROOT/skills/harness-init/templates/$TYPE/.harness/scripts"
if [[ ! -d "$template_common_scripts" ]]; then
    echo "upgrade-project: template common scripts not found at $template_common_scripts." >&2
    exit 1
fi
if [[ -z "$TYPE" ]]; then
    echo "upgrade-project: --type is required (fullstack|backend|generic)." >&2
    exit 1
fi
case "$TYPE" in
    fullstack|backend|generic) : ;;
    *) echo "upgrade-project: bad --type '$TYPE' (fullstack|backend|generic)." >&2; exit 1 ;;
esac
if [[ ! -d "$template_type_scripts" ]]; then
    echo "upgrade-project: template type scripts not found at $template_type_scripts." >&2
    exit 1
fi

has_settings=false;  [[ -f "$root/.claude/settings.json" ]] && has_settings=true
has_harness=false;   [[ -d "$root/.harness" ]] && has_harness=true
has_old_sync=false;  { [[ -f "$root/scripts/harness-sync.ps1" ]] || [[ -f "$root/scripts/harness-sync.sh" ]]; } && has_old_sync=true
if [[ "$has_settings" == false && "$has_harness" == false && "$has_old_sync" == false ]]; then
    echo "upgrade-project: this does not look like a harness project (no .claude/settings.json, no .harness/, no scripts/harness-sync.*). Use /harness-adopt for a no-harness project." >&2
    exit 1
fi

[[ -z "$PROJECT_NAME" ]] && PROJECT_NAME="$(basename "$root")"
[[ -z "$TODAY" ]] && TODAY="$(date +%Y-%m-%d)"
stamp="$(date +%Y%m%dT%H%M%S)"

n_moved=0; n_rewritten=0; n_rewired=0; n_added=0; n_conflicts=0
exit_code=0

emit() { printf '%s\n' "$1"; }
verb_prefix() { if [[ "$DRY_RUN" == true ]]; then echo "PLAN"; else echo "RESULT"; fi; }

# resilient_cmd <tool> <is_windows> — print the T-12 RESILIENT hook command string,
# JSON-escaped (inner " as \") so it can be dropped straight into a JSON "command"
# value byte-identical to settings.json.tmpl after substitution.
#   convenience hooks (harness-sync / ambient-prompt / ambient-reset): fail-OPEN —
#     anchor to $CLAUDE_PROJECT_DIR, exit 0 silently if the script is absent/unreachable.
#   guard-rm (safety): fail-CLOSED — anchor but NO `|| exit 0` / no `exit 0` fallback,
#     so a missing/unreachable guard yields a non-zero exit (the Bash call is blocked).
# The space-preceded bare `.harness/scripts/<tool>.<ext>` token is preserved so the
# unchanged left-bounded congruence ERE still parses + existence-checks it (OQ-3a).
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

# str_replace_all <haystack> <needle> <replacement> — literal replace-all that is
# IMMUNE to bash 5.2's `&`-means-matched-text rule in ${var//pat/repl} (the resilient
# command contains a literal `&`, which ${//} would otherwise expand to the match).
# Splits on the needle and concatenates verbatim — neither needle nor replacement is
# treated as a pattern. Mirrors PS String.Replace (which is already literal).
str_replace_all() {
    local rest="$1" needle="$2" repl="$3" out=""
    while [[ "$rest" == *"$needle"* ]]; do
        out="$out${rest%%"$needle"*}$repl"
        rest="${rest#*"$needle"}"
    done
    printf '%s' "$out$rest"
}

emit "TYPE|$TYPE"

# --- S1 relocation --------------------------------------------------------------
# INVARIANT: refresh_set (S2 below) == (known minus verify_all.{ps1,sh}, baseline.json)
# plus the ambient hook pair (ambient-prompt/-reset never lived at top-level scripts/ —
# they shipped post-relocation in T-011, so they are NOT in `known`).
# These two literal arrays are hand-maintained — if you edit one, update the other.
known=(
    verify_all.ps1 verify_all.sh
    harness-sync.ps1 harness-sync.sh
    guard-rm.ps1 guard-rm.sh
    install-hooks.ps1 install-hooks.sh
    archive-task.ps1 archive-task.sh
    migrate-scripts-layout.ps1 migrate-scripts-layout.sh
    baseline.json
)
src_dir="$root/scripts"
dst_dir="$root/.harness/scripts"
in_git=false
[[ -d "$root/.git" ]] && in_git=true
planned_moves=""

for name in "${known[@]}"; do
    src_file="$src_dir/$name"
    dst_file="$dst_dir/$name"
    [[ -f "$src_file" ]] || continue
    if [[ -e "$dst_file" && "$FORCE" == false ]]; then
        emit "$(verb_prefix)|SKIP|scripts/$name (already at .harness/scripts/$name; --force to overwrite)"
        continue
    fi
    emit "$(verb_prefix)|MOVE|scripts/$name -> .harness/scripts/$name"
    planned_moves="$planned_moves $name"
    n_moved=$((n_moved + 1))
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$dst_dir"
        tracked=false
        if [[ "$in_git" == true ]] && git ls-files --error-unmatch "scripts/$name" &>/dev/null; then
            tracked=true
        fi
        if [[ "$tracked" == true ]]; then
            [[ "$FORCE" == true && -e "$dst_file" ]] && rm -f "$dst_file"
            git mv -f "scripts/$name" ".harness/scripts/$name" >/dev/null
        else
            mv -f "$src_file" "$dst_file"
        fi
    fi
done

# --- S2 content-refresh of depth-sensitive scripts (the L31 / DO-1 fix) ---------
# INVARIANT: refresh_set == (known (S1 above) minus verify_all.{ps1,sh}, baseline.json)
# plus the ambient hook pair (ambient-prompt/-reset are hook targets — repair, FR-R1,
# must be able to re-land them; they are not in `known` because they never lived at
# top-level scripts/). Hand-maintained literal arrays — edit one, update the other.
refresh_set=(
    harness-sync.ps1 harness-sync.sh
    install-hooks.ps1 install-hooks.sh
    archive-task.ps1 archive-task.sh
    guard-rm.ps1 guard-rm.sh
    migrate-scripts-layout.ps1 migrate-scripts-layout.sh
    ambient-prompt.ps1 ambient-prompt.sh
    ambient-reset.ps1 ambient-reset.sh
)
for name in "${refresh_set[@]}"; do
    tmpl_file="$template_common_scripts/$name"
    dst_file="$dst_dir/$name"
    if [[ ! -f "$tmpl_file" ]]; then
        # T-020 (RC-4 fix): never skip this case silently. If the project still has a
        # copy, that copy is retained (NOOP); if neither side has the file, emit an
        # explicit GAP so a hook wired to it is diagnosable (the terminal congruence
        # scan then fails the run with exit 4 if the file is actually wired).
        if [[ -f "$dst_file" ]]; then
            emit "$(verb_prefix)|NOOP|.harness/scripts/$name (template lacks it; existing copy retained)"
        else
            emit "GAP|template-missing|absent|.harness/scripts/$name"
        fi
        continue
    fi
    if [[ -f "$dst_file" ]] && cmp -s "$tmpl_file" "$dst_file"; then
        emit "$(verb_prefix)|NOOP|.harness/scripts/$name (already current)"
        continue
    fi
    is_new=false
    [[ -f "$dst_file" ]] || is_new=true
    emit "$(verb_prefix)|REFRESH|.harness/scripts/$name (from current template)"
    if [[ "$is_new" == true ]]; then n_added=$((n_added + 1)); else n_rewritten=$((n_rewritten + 1)); fi
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$dst_dir"
        # cp verify (T-020 / RC-4): under `set -uo` (no -e) a failed cp would pass
        # silently and S3 could rewire toward a file that never landed.
        if ! cp "$tmpl_file" "$dst_file" 2>/dev/null || ! cmp -s "$tmpl_file" "$dst_file"; then
            emit "CONFLICT|refresh|.harness/scripts/$name copy failed (template -> project copy did not land)"
            n_conflicts=$((n_conflicts + 1))
        fi
    fi
done

# --- S3 settings rewire (verbatim raw-text replace; NEVER re-serialize — DO-3) ---
# target_present <name>: is .harness/scripts/<name> on disk (apply mode: S1 moves +
# S2 refresh already ran, disk is ground truth) or projected to land there (dry-run:
# a planned S1 MOVE counts, and so does the template carrying a refresh-set member —
# S2 would land it on apply)? Gates both the placeholder repair and the per-variant
# prefix rewires below (T-020 / FR-P3).
target_present() {
    local tp_name="$1" tp_m
    [[ -f "$dst_dir/$tp_name" ]] && return 0
    [[ "$DRY_RUN" == true ]] || return 1
    case " $planned_moves " in *" $tp_name "*) return 0 ;; esac
    if [[ -f "$template_common_scripts/$tp_name" ]]; then
        for tp_m in "${refresh_set[@]}"; do
            [[ "$tp_m" == "$tp_name" ]] && return 0
        done
    fi
    return 1
}

settings="$root/.claude/settings.json"
settings_new=""
if [[ ! -f "$settings" ]]; then
    emit "RESULT|SKIP|.claude/settings.json absent — settings rewire skipped (non-Claude-Code project)"
else
    settings_raw="$(cat "$settings")"
    settings_new="$settings_raw"

    # S3.0 — literal-placeholder repair (T-020 gate C3 / B7, design §6.2.5).
    # A wired, UNSUBSTITUTED placeholder token (RC-3 improvisation damage) can never
    # run on any OS, so it is never a deliberate user choice (OQ-5 untriggered): it is
    # rewritten to the OS-picked init command — gated on the target script being
    # (projected) present, so a MALFORMED token never becomes a DANGLING path (the
    # terminal scan flags an un-repairable token instead -> exit 4). Tokens are
    # assembled from pieces so this shipped helper never contains a literal
    # double-brace token (insight 2026-06-08; test-init's blanket placeholder scan).
    # Replacement values contain no token opener, so a second run is a no-op (B10).
    # T-12: the emitted command is the RESILIENT form (resilient_cmd) — fail-open +
    # $CLAUDE_PROJECT_DIR-anchored for the convenience hooks, fail-CLOSED for guard-rm
    # — so a placeholder-repaired hook is born resilient, not brittle. The value lands
    # inside a JSON string, so resilient_cmd returns the JSON-escaped bytes (inner " as
    # \") — byte-identical to what settings.json.tmpl carries after substitution.
    ph_o="{{"; ph_c="}}"
    is_windows=false
    case "${OSTYPE:-}" in msys*|cygwin*|win32) is_windows=true ;; esac
    ph_names=(SYNC_COMMAND GUARD_COMMAND AMBIENT_PROMPT_COMMAND AMBIENT_RESET_COMMAND)
    ph_tools=(harness-sync guard-rm ambient-prompt ambient-reset)
    for ph_i in "${!ph_names[@]}"; do
        ph_tok="${ph_o}${ph_names[$ph_i]}${ph_c}"
        if [[ "$is_windows" == true ]]; then
            ph_target="${ph_tools[$ph_i]}.ps1"
        else
            ph_target="${ph_tools[$ph_i]}.sh"
        fi
        ph_cmd="$(resilient_cmd "${ph_tools[$ph_i]}" "$is_windows")"
        if printf '%s' "$settings_new" | grep -qF -- "$ph_tok" && target_present "$ph_target"; then
            settings_new="$(str_replace_all "$settings_new" "$ph_tok" "$ph_cmd")"
            emit "$(verb_prefix)|REWIRE-PLACEHOLDER|.claude/settings.json (${ph_names[$ph_i]} -> $ph_cmd)"
        fi
    done

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
    for tool_ext in harness-sync.ps1 harness-sync.sh guard-rm.ps1 guard-rm.sh; do
        if target_present "$tool_ext"; then
            tool_base="${tool_ext%.*}"
            tool_suffix="${tool_ext##*.}"
            settings_new="$(printf '%s\n' "$settings_new" \
                | sed -e "s|scripts/$tool_base\.$tool_suffix|.harness/scripts/$tool_base.$tool_suffix|g")"
        fi
    done
    settings_new="$(printf '%s\n' "$settings_new" | sed -e 's|\.harness/\.harness/scripts/|.harness/scripts/|g')"

    # S3.2 — brittle -> resilient rewrite (T-12 / A8, design §4.3). S3.1 above only adds
    # the `.harness/` prefix; it does NOT convert a brittle command
    # (`bash .harness/scripts/harness-sync.sh` / `pwsh -NoProfile -File .harness/...`)
    # into the resilient (fail-open/closed + $CLAUDE_PROJECT_DIR-anchored) form. This
    # step does. For each of the four {tool}x{ext} brittle forms, if the `.harness/`-
    # prefixed brittle command value is present verbatim AND its target is (projected)
    # present, swap the WHOLE brittle command VALUE for the OS-picked resilient string.
    # Pure ordinal bash substring replace (no sed) so the resilient value's `&`/`|`/`;`
    # metachars are inert. Gated on target_present so a brittle command pointing at a
    # missing script is left for the terminal scan to flag (never rewritten into a
    # resilient-but-dangling form). The needle is double-quote-bounded ("<brittle>") so
    # it matches ONLY a bare brittle "command" value, never the same bare token embedded
    # INSIDE an already-resilient value (there it sits in single quotes / Set-Location
    # body, not "..."), which makes the rewrite idempotent without a whole-file sentinel
    # (second run = NOOP, no .bak churn — B10) and robust to mixed states. Raw-text,
    # never re-serialize (DO-3); $schema untouched. R4: only the four harness tool names
    # are eligible — a user's custom hook is never a rewrite candidate.
    s32_tools=(harness-sync guard-rm ambient-prompt ambient-reset)
    for s32_tool in "${s32_tools[@]}"; do
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
                emit "$(verb_prefix)|REWIRE-RESILIENT|.claude/settings.json ($s32_tool.$s32_ext -> resilient form)"
            fi
        done
    done

    if [[ "$settings_new" != "$settings_raw" ]]; then
        emit "$(verb_prefix)|REWIRE|.claude/settings.json (hook command paths)"
        n_rewired=$((n_rewired + 1))
        if [[ "$DRY_RUN" == false ]]; then
            bak="$settings.bak-$stamp"
            cp "$settings" "$bak"
            emit "BAK|$bak"
            printf '%s\n' "$settings_new" > "$settings"
        fi
    else
        emit "RESULT|NOOP|.claude/settings.json already rewired"
    fi
fi

# --- S4 hook (re)install --------------------------------------------------------
read -r -d '' current_hook_body <<'EOF'
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
EOF
# install-hooks.sh writes the body via a heredoc, so the on-disk stock hook ends with a
# trailing newline. Match that exactly when (re)writing.
current_hook_file_content="$current_hook_body"$'\n'

normalize_hook() {
    # Collapse old one-up path prefix to two-up, drop CR, strip leading/trailing blank
    # lines, so the stock-vs-custom test ignores path-depth + CRLF.
    printf '%s' "$1" \
        | sed -e 's|scripts/harness-sync\.|.harness/scripts/harness-sync.|g' \
              -e 's|\.harness/\.harness/scripts/harness-sync\.|.harness/scripts/harness-sync.|g' \
              -e 's|\r$||' \
        | sed -e '/./,$!d' | tac | sed -e '/./,$!d' | tac
}

hook_path="$root/.git/hooks/pre-commit"
norm_current="$(normalize_hook "$current_hook_body")"
if [[ ! -d "$root/.git" ]]; then
    emit "RESULT|SKIP|.git absent — pre-commit hook not installed"
elif [[ ! -f "$hook_path" ]]; then
    emit "$(verb_prefix)|HOOK-INSTALL|.git/hooks/pre-commit (was absent)"
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$root/.git/hooks"
        printf '%s' "$current_hook_file_content" > "$hook_path"
        chmod +x "$hook_path"
    fi
else
    existing="$(cat "$hook_path")"
    if [[ "$(normalize_hook "$existing")" == "$norm_current" ]]; then
        if cmp -s "$hook_path" <(printf '%s' "$current_hook_file_content"); then
            emit "RESULT|NOOP|.git/hooks/pre-commit already current"
        else
            emit "$(verb_prefix)|HOOK-INSTALL|.git/hooks/pre-commit (was stock pre-T-007; refreshed to new path)"
            if [[ "$DRY_RUN" == false ]]; then
                bak="$hook_path.bak-$stamp"
                cp "$hook_path" "$bak"
                emit "BAK|$bak"
                printf '%s' "$current_hook_file_content" > "$hook_path"
                chmod +x "$hook_path"
            fi
        fi
    else
        emit "CONFLICT|hook|.git/hooks/pre-commit is non-stock (hand-customized) — NOT overwritten; merge the drift check in manually"
        n_conflicts=$((n_conflicts + 1))
        exit_code=3
    fi
fi

# --- S5 verify_all regenerate (splice / regen / halt) ---------------------------
begin_marker="# >>> HARNESS:B-CUSTOM:BEGIN"
end_marker="# >>> HARNESS:B-CUSTOM:END"

substitute_placeholders() {
    # $1 = file path; prints substituted content. Only the 3 whitelisted placeholders.
    # The placeholder tokens are assembled from pieces (o + NAME + c) rather than written
    # as double-brace literals, so this helper file does NOT itself contain an
    # unsubstituted placeholder token — keeps test-init's "no unresolved placeholders"
    # cleanliness check happy when the helper is copied into a generated project. Still the
    # same 3 D.2-whitelisted names; no new placeholder introduced.
    local stack_val="$STACK"
    [[ -z "$stack_val" ]] && stack_val="$TYPE"
    local o="{{" c="}}"
    sed -e "s|${o}PROJECT_NAME${c}|$PROJECT_NAME|g" \
        -e "s|${o}STACK${c}|$stack_val|g" \
        -e "s|${o}TODAY${c}|$TODAY|g" \
        "$1"
}

# Returns 0 (true) if exactly one BEGIN, one END, BEGIN strictly before END.
markers_clean() {
    local file_content="$1"
    local nb ne
    # -F (fixed string, never combined with -i) — markers contain ( ) > < which are
    # regex-significant; L27 only bans the -F -i combination, -F alone is safe.
    nb=$(printf '%s\n' "$file_content" | grep -cF -- "$begin_marker" || true)
    ne=$(printf '%s\n' "$file_content" | grep -cF -- "$end_marker" || true)
    [[ "$nb" -eq 1 && "$ne" -eq 1 ]] || return 1
    local bl el
    bl=$(printf '%s\n' "$file_content" | grep -nF -- "$begin_marker" | head -1 | cut -d: -f1)
    el=$(printf '%s\n' "$file_content" | grep -nF -- "$end_marker" | head -1 | cut -d: -f1)
    [[ "$bl" -lt "$el" ]] || return 1
    return 0
}

# Prints the inner block (lines strictly between BEGIN and END).
marker_inner_block() {
    printf '%s\n' "$1" | awk -v b="$begin_marker" -v e="$end_marker" '
        index($0,b)==1 {inb=1; next}
        index($0,e)==1 {inb=0}
        inb==1 {print}
    '
}

# Returns 0 (true) if the inner block is stub-only (no real B.* command).
block_is_stub() {
    local block="$1" line t
    while IFS= read -r line; do
        t="$(printf '%s' "$line" | sed -e 's|^[[:space:]]*||' -e 's|[[:space:]]*$||')"
        [[ -z "$t" ]] && continue
        case "$t" in
            \#*) continue ;;
            *SKIP*) continue ;;
            Step\ *|step\ *) continue ;;
            '{'|'}') continue ;;
            return\ *) continue ;;
            *) return 1 ;;
        esac
    done <<< "$block"
    return 0
}

# Returns 0 (true) if an OLD non-marker verify_all carries custom B.* checks.
old_b_customized() {
    local file_content="$1" line t
    while IFS= read -r line; do
        t="$(printf '%s' "$line" | sed -e 's|^[[:space:]]*||' -e 's|[[:space:]]*$||')"
        # bash step "B.x" ... with a non-SKIP status
        if [[ "$t" == step\ \"B.* ]] && [[ "$t" != *'"SKIP"'* ]]; then return 0; fi
        case "$t" in
            \#*) continue ;;
            *cargo*|*pytest*|*"npm "*|*"pnpm "*|*"yarn "*|*"go build"*|*"go test"*|*dotnet*|*gradle*|*mvn*|*ruff*|*mypy*|*eslint*|*tsc*) return 0 ;;
        esac
    done <<< "$file_content"
    return 1
}

for shell in ps1 sh; do
    proj_file="$dst_dir/verify_all.$shell"
    tmpl_file="$template_type_scripts/verify_all.$shell.tmpl"
    if [[ ! -f "$tmpl_file" ]]; then
        emit "RESULT|SKIP|verify_all.$shell (no type template)"
        continue
    fi
    fresh="$(substitute_placeholders "$tmpl_file")"

    verb="VERIFY-REGEN"
    final_text="$fresh"
    if [[ -f "$proj_file" ]]; then
        old_raw="$(cat "$proj_file")"
        if markers_clean "$old_raw"; then
            old_block="$(marker_inner_block "$old_raw")"
            if block_is_stub "$old_block"; then
                verb="VERIFY-REGEN"
            else
                # SPLICE old block into fresh
                if markers_clean "$fresh"; then
                    final_text="$(printf '%s\n' "$fresh" | awk -v b="$begin_marker" -v e="$end_marker" -v blk="$old_block" '
                        index($0,b)==1 { print; print blk; skip=1; next }
                        index($0,e)==1 { skip=0 }
                        skip==1 { next }
                        { print }
                    ')"
                    verb="VERIFY-SPLICE"
                else
                    verb="VERIFY-REGEN"
                fi
            fi
        else
            if old_b_customized "$old_raw" && [[ "$FORCE" == false ]]; then
                emit "VERIFY-HALT|$shell"
                emit "CONFLICT|verify_all|verify_all.$shell has no HARNESS:B-CUSTOM markers but appears to carry custom B.* checks — left untouched (nothing lost). Re-run with --force to overwrite; a timestamped .bak will be written first, preserving your old checks."
                n_conflicts=$((n_conflicts + 1))
                exit_code=2
                continue
            fi
            verb="VERIFY-REGEN"
        fi
    fi

    # Idempotence: byte-identical -> NOOP.
    if [[ -f "$proj_file" ]] && [[ "$(cat "$proj_file")" == "$final_text" ]]; then
        emit "RESULT|NOOP|verify_all.$shell already current"
        continue
    fi

    is_new=false
    [[ -f "$proj_file" ]] || is_new=true
    emit "$(verb_prefix)|$verb|verify_all.$shell"
    if [[ "$is_new" == true ]]; then n_added=$((n_added + 1)); else n_rewritten=$((n_rewritten + 1)); fi
    if [[ "$DRY_RUN" == false ]]; then
        if [[ -f "$proj_file" ]]; then
            bak="$proj_file.bak-$stamp"
            cp "$proj_file" "$bak"
            emit "BAK|$bak"
        fi
        printf '%s\n' "$final_text" > "$proj_file"
    fi
done

# --- S6 terminal hook<->script congruence scan (T-020 / FR-P1, runs last) --------
# Asserts the END STATE: every script path referenced by a `"command"` line in the
# final settings text resolves to a file that exists (apply mode: disk is ground
# truth — the scan runs after every writer) or is projected to exist (dry-run:
# planned S1 MOVEs and template-carried refresh-set members count). Each miss emits
# a CONFLICT|congruence record and the run exits 4. The scan is the LAST writer of
# exit_code, so 4 deliberately wins over 2/3 — an incongruent end state is the most
# actionable failure; the co-occurring CONFLICT/VERIFY-HALT records stay on stdout.
# The path ERE is LEFT-BOUNDED (quote / space / `=` / line start) so a custom hook
# whose dirname merely ENDS in `scripts/` (e.g. build-scripts/deploy.sh) can never
# match (gate C1). Anything the ERE cannot parse is ignored — fail-open diagnosis
# (R4): the scan only flags PARSED tokens whose target file is missing.
# Line-scoping to "command" lines is deliberate: permissions.allow entries and the
# _doc_sync_hook / _ambient_hook doc strings mention BOTH shell variants and must not
# force both to exist (only the wired variant is load-bearing).
# Known asymmetry (B9): the dry-run projection is ADDITIVE-only — a hook wired to a
# legacy scripts/<name> that exists NOW but is planned to MOVE still passes the disk
# test in dry-run, yet apply exits 4 after the move; apply is authoritative.
if [[ -f "$settings" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        scan_text="$settings_new"
    else
        scan_text="$(cat "$settings")"
    fi
    cong_found=false
    while IFS= read -r cmd_line; do
        case "$cmd_line" in *'"command"'*) : ;; *) continue ;; esac
        trimmed="$(printf '%s' "$cmd_line" | sed -e 's|^[[:space:]]*||' -e 's|[[:space:]]*$||')"
        if [[ "$cmd_line" == *"$ph_o"* ]]; then
            emit "CONFLICT|congruence|$trimmed -> unresolved placeholder token"
            n_conflicts=$((n_conflicts + 1))
            cong_found=true
        fi
        while IFS= read -r ref_path; do
            [[ -z "$ref_path" ]] && continue
            present=false
            [[ -f "$root/$ref_path" ]] && present=true
            if [[ "$present" == false && "$DRY_RUN" == true ]]; then
                case "$ref_path" in
                    .harness/scripts/*)
                        ref_name="${ref_path#.harness/scripts/}"
                        target_present "$ref_name" && present=true
                        ;;
                esac
            fi
            if [[ "$present" == false ]]; then
                emit "CONFLICT|congruence|$trimmed -> missing $ref_path"
                n_conflicts=$((n_conflicts + 1))
                cong_found=true
            fi
        done < <(printf '%s\n' "$cmd_line" \
            | grep -oE "(^|[\"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)" \
            | sed -E "s|^[\"' =]||" \
            | sort -u)
    done <<< "$scan_text"
    [[ "$cong_found" == true ]] && exit_code=4
fi

emit "SUMMARY|added=$n_added moved=$n_moved rewritten=$n_rewritten rewired=$n_rewired conflicts=$n_conflicts"
exit "$exit_code"
