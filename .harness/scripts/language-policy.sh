#!/usr/bin/env bash
# language-policy.sh — Deterministic mechanical layer for /harness-language (T-014).
# Mirror of language-policy.ps1. See that file for the full doc + stdout contract.
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
# Run from the PROJECT ROOT. cwd-derived (depth-independent).
#
# Usage:
#   bash language-policy.sh --template-root <abs> --lang en
#   bash language-policy.sh --template-root <abs> --lang zh --dry-run
#   bash language-policy.sh --template-root <abs> --lang en --force   # insert absent section
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
# Exit codes: 0 success / nothing-to-do / dry-run printed;
#             1 precondition / arg error (bad --lang, missing --template-root, no surface);
#             2 section-conflict (00-core.md has neither canonical heading) and no --force.

set -uo pipefail

DRY_RUN=false
FORCE=false
LANG_ARG=""
TEMPLATE_ROOT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)        DRY_RUN=true; shift ;;
        --force)          FORCE=true; shift ;;
        --lang)           LANG_ARG="${2:-}"; shift 2 ;;
        --template-root)  TEMPLATE_ROOT="${2:-}"; shift 2 ;;
        *) echo "language-policy: unknown argument: $1" >&2; exit 1 ;;
    esac
done

root="$(pwd)"

# --- preconditions --------------------------------------------------------------
if [[ -z "$TEMPLATE_ROOT" ]]; then
    echo "language-policy: --template-root is required (the resolved plugin template cache root)." >&2
    exit 1
fi
case "$LANG_ARG" in
    en|zh) : ;;
    *) echo "language-policy: --lang must be 'en' or 'zh' (got '${LANG_ARG}')." >&2; exit 1 ;;
esac

# Canonical heading anchors (both languages — the project may currently be either).
en_heading="## Output language (project-wide)"
zh_heading="## 输出语言（按消费者分流）"

# Template source files for the TARGET language.
# en: read the section + line inline from common/ (en path byte-unchanged).
# zh: read BOTH from the single-source snippet (the section first, the line after the
#     sentinel) — the i18n/zh SPECIAL files no longer exist (T-016).
if [[ "$LANG_ARG" == "en" ]]; then
    tmpl_core="$TEMPLATE_ROOT/skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl"
    tmpl_claude="$TEMPLATE_ROOT/skills/harness-init/templates/common/CLAUDE.md.tmpl"
    target_heading="$en_heading"
else
    tmpl_core="$TEMPLATE_ROOT/skills/harness-init/templates/i18n/zh/_policy/output-language.zh.md.tmpl"
    tmpl_claude="$tmpl_core"   # single source carries BOTH the section and the line
    target_heading="$zh_heading"
fi

if [[ ! -f "$tmpl_core" ]]; then
    echo "language-policy: template 00-core.md.tmpl not found at $tmpl_core." >&2
    exit 1
fi
if [[ ! -f "$tmpl_claude" ]]; then
    echo "language-policy: template CLAUDE.md.tmpl not found at $tmpl_claude." >&2
    exit 1
fi

# Project surfaces.
proj_core="$root/.harness/rules/00-core.md"
proj_claude="$root/CLAUDE.md"
proj_copilot="$root/.github/copilot-instructions.md"

if [[ ! -f "$proj_core" && ! -f "$proj_claude" ]]; then
    echo "language-policy: neither .harness/rules/00-core.md nor CLAUDE.md exists — nothing to operate on." >&2
    exit 1
fi

stamp="$(date +%Y%m%dT%H%M%S)"
n_rewritten=0; n_noop=0; n_skipped=0; n_baks=0; n_conflicts=0
exit_code=0

# Temp files for the extracted canonical block / line (byte-exact, no $() stripping).
work_section="$(mktemp -t language-policy-section-XXXXXX)"
work_line="$(mktemp -t language-policy-line-XXXXXX)"
cleanup() { rm -f "$work_section" "$work_line"; }
trap cleanup EXIT

emit() { printf '%s\n' "$1"; }
verb_prefix() { if [[ "$DRY_RUN" == true ]]; then echo "PLAN"; else echo "RESULT"; fi; }

emit "LANG|$LANG_ARG"

# --- extract the canonical SECTION block [heading, next "## ") to $2 (a file) -----
# Byte-exact: every line in [START, END) including the trailing blank line, each with
# its own newline. $1 = source file, $2 = heading literal, $3 = out file.
extract_section_to() {
    local file="$1" heading="$2" out="$3"
    awk -v h="$heading" '
        BEGIN { found=0 }
        {
            line=$0
            cmp=line; sub(/[ \t\r]+$/, "", cmp)
            if (found==0 && cmp==h) { found=1; print line; next }
            if (found==1) {
                if (line ~ /^## /) { exit }
                print line
            }
        }
    ' "$file" > "$out"
}

# --- extract the canonical policy LINE (first line matching the anchor) to $2 -----
extract_line_to() {
    local file="$1" out="$2"
    awk '
        /^Output language:/ { print; exit }
        /^输出语言：/        { print; exit }
    ' "$file" > "$out"
}

# --- DETECT the project current language from 00-core -> CLAUDE -> copilot --------
detect_lang() {
    local detected="ambiguous" source="none"
    if [[ -f "$proj_core" ]]; then
        if grep -q "输出语言（按消费者分流）" "$proj_core" 2>/dev/null; then
            detected="zh"; source="00-core"
        elif grep -q "Output language (project-wide)" "$proj_core" 2>/dev/null; then
            detected="en"; source="00-core"
        fi
    fi
    if [[ "$detected" == "ambiguous" && -f "$proj_claude" ]]; then
        if grep -q "^输出语言：" "$proj_claude" 2>/dev/null; then
            detected="zh"; source="CLAUDE"
        elif grep -q "^Output language:" "$proj_claude" 2>/dev/null; then
            detected="en"; source="CLAUDE"
        fi
    fi
    if [[ "$detected" == "ambiguous" && -f "$proj_copilot" ]]; then
        if grep -q "^输出语言：" "$proj_copilot" 2>/dev/null; then
            detected="zh"; source="copilot"
        elif grep -q "^Output language:" "$proj_copilot" 2>/dev/null; then
            detected="en"; source="copilot"
        fi
    fi
    emit "DETECT|$detected|$source"
}
detect_lang

# Canonical TARGET block + line, extracted from the resolved template (byte-exact files).
extract_section_to "$tmpl_core" "$target_heading" "$work_section"
if [[ ! -s "$work_section" ]]; then
    echo "language-policy: could not extract the '$LANG_ARG' policy section from $tmpl_core." >&2
    exit 1
fi
extract_line_to "$tmpl_claude" "$work_line"
if [[ ! -s "$work_line" ]]; then
    echo "language-policy: could not extract the '$LANG_ARG' policy line from $tmpl_claude." >&2
    exit 1
fi

# --- write a candidate file (already produced in $tmp) IFF it differs -------------
# $1 = target path, $2 = candidate file, $3 = label, $4 = verb
write_or_noop() {
    local path="$1" cand="$2" label="$3" verb="$4"
    if [[ -f "$path" ]] && cmp -s "$path" "$cand"; then
        emit "$(verb_prefix)|NOOP|$label|already current"
        n_noop=$((n_noop + 1))
        return 0
    fi
    emit "$(verb_prefix)|$verb|$label|to $LANG_ARG"
    n_rewritten=$((n_rewritten + 1))
    if [[ "$DRY_RUN" == false ]]; then
        if [[ -f "$path" ]]; then
            local bak="$path.bak-$stamp"
            cp "$path" "$bak"
            emit "BAK|$bak"
            n_baks=$((n_baks + 1))
        fi
        cp "$cand" "$path"
    fi
}

# --- 00-core.md: REWRITE-SECTION / INSERT-SECTION / CONFLICT ---------------------
if [[ -f "$proj_core" ]]; then
    # Does the file currently carry EITHER canonical heading?
    has_heading=false
    if grep -q "Output language (project-wide)" "$proj_core" 2>/dev/null \
       || grep -q "输出语言（按消费者分流）" "$proj_core" 2>/dev/null; then
        has_heading=true
    fi

    cand_core="$(mktemp -t language-policy-core-XXXXXX)"
    if [[ "$has_heading" == true ]]; then
        # Rebuild: lines before the existing heading, then the byte-exact template
        # section, then lines from the next "## " onward. The replacement is injected
        # verbatim from $work_section (getline preserves the trailing blank line).
        awk -v en="$en_heading" -v zh="$zh_heading" -v repl="$work_section" '
            BEGIN { state=0 }   # 0=before, 1=inside old section, 2=after
            {
                line=$0
                cmp=line; sub(/[ \t\r]+$/, "", cmp)
                if (state==0 && (cmp==en || cmp==zh)) {
                    while ((getline rl < repl) > 0) print rl
                    close(repl)
                    state=1
                    next
                }
                if (state==1) {
                    if (line ~ /^## /) { state=2; print line; next }
                    next
                }
                print line
            }
        ' "$proj_core" > "$cand_core"
        write_or_noop "$proj_core" "$cand_core" ".harness/rules/00-core.md" "REWRITE-SECTION"
    else
        if [[ "$FORCE" == false ]]; then
            emit "CONFLICT|section|.harness/rules/00-core.md|no recognizable policy heading"
            n_conflicts=$((n_conflicts + 1))
            exit_code=2
        else
            # INSERT-SECTION: before the first "## " heading, or at EOF if none.
            awk -v repl="$work_section" '
                BEGIN { inserted=0 }
                {
                    if (inserted==0 && $0 ~ /^## /) {
                        while ((getline rl < repl) > 0) print rl
                        close(repl)
                        inserted=1
                    }
                    print
                }
                END {
                    if (inserted==0) { while ((getline rl < repl) > 0) print rl; close(repl) }
                }
            ' "$proj_core" > "$cand_core"
            write_or_noop "$proj_core" "$cand_core" ".harness/rules/00-core.md" "INSERT-SECTION"
        fi
    fi
    rm -f "$cand_core"
else
    emit "$(verb_prefix)|SKIP|.harness/rules/00-core.md|absent"
    n_skipped=$((n_skipped + 1))
fi

# --- CLAUDE.md + copilot: REWRITE-LINE (or SKIP) ---------------------------------
target_line="$(cat "$work_line")"
rewrite_line_file() {
    local path="$1" label="$2"
    if [[ ! -f "$path" ]]; then
        emit "$(verb_prefix)|SKIP|$label|absent"
        n_skipped=$((n_skipped + 1))
        return 0
    fi
    if ! grep -q -e '^Output language:' -e '^输出语言：' "$path" 2>/dev/null; then
        emit "$(verb_prefix)|SKIP|$label|policy line not found"
        n_skipped=$((n_skipped + 1))
        return 0
    fi
    local cand
    cand="$(mktemp -t language-policy-line-cand-XXXXXX)"
    awk -v repl="$target_line" '
        BEGIN { done=0 }
        {
            if (done==0 && ($0 ~ /^Output language:/ || $0 ~ /^输出语言：/)) {
                print repl; done=1; next
            }
            print
        }
    ' "$path" > "$cand"
    write_or_noop "$path" "$cand" "$label" "REWRITE-LINE"
    rm -f "$cand"
}

rewrite_line_file "$proj_claude" "CLAUDE.md"
rewrite_line_file "$proj_copilot" ".github/copilot-instructions.md"

emit "SUMMARY|rewritten=$n_rewritten noop=$n_noop skipped=$n_skipped baks=$n_baks conflicts=$n_conflicts"
exit "$exit_code"
