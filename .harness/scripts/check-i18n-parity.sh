#!/usr/bin/env bash
# check-i18n-parity.sh — bilingual key + printf-specifier parity for install.sh's t()
#
# T-11 (02_SOLUTION_DESIGN.md §5). `install.sh:t()` declares `local fmt` with NO
# default, so a key present in only one language table makes `printf` dereference
# an unset variable under `set -u` and abort the WHOLE installer — and the zh
# table is reachable only by answering `2` at the language prompt, so an
# English-only run can never detect the break (.harness/insight-index.md:10).
#
# The parser's only job is to enumerate CANDIDATE key names. The judgment is
# behavioural: the extracted t() is sourced under `set -u` and every key is
# rendered in BOTH languages, which reproduces the production failure mode
# itself rather than a proxy for it.
#
#   usage:  check-i18n-parity.sh [FILE]     (default: <script dir>/../../install.sh)
#   exit 0  parity holds        prints "OK: N keys, both languages"
#   exit 1  parity broken       one line per offending key on stdout
#   exit 2  cannot decide       t() not found / no keys parsed / a fmt= line not parsed
#
# `exit 2` is a hard failure for the caller, never a pass: a file this check
# cannot read must not be reported green.
#
# SAFETY: this script never sources or executes FILE. It extracts the t()
# function body only, writes solely inside its own mktemp -d, runs no installer
# command, and needs neither root nor network.

# Deliberately NOT `set -e`: a key missing from one table must make one render
# subshell fail while the outer loop keeps going, so every offender is reported.
set -u

SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)
FILE="${1:-$SELF_DIR/../../install.sh}"

die2() { printf 'CANNOT DECIDE: %s\n' "$1"; exit 2; }

[ -f "$FILE" ] || die2 "no such file: $FILE"

TMP=$(mktemp -d) || die2 "mktemp -d failed"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FRAG="$TMP/t.frag"
KEYS="$TMP/keys"

# --- 1. extract t() by function-boundary anchors -----------------------------
# Both anchors sit at column 0 and nothing inside the body starts at column 0
# (the case blocks close with an indented `esac`), so the range is exact.
sed -n '/^t() {/,/^}/p' "$FILE" > "$FRAG"

[ -s "$FRAG" ] || die2 "t() not found in $FILE"
head -1 "$FRAG" | grep -q '^t() {' || die2 "extraction does not start at 't() {'"
tail -1 "$FRAG" | grep -q '^}' || die2 "extraction does not end at a column-0 '}'"

# The fragment must be a bare function definition: sourcing it may define a
# function and must execute nothing. A command substitution has no business
# being here; refuse rather than source something unexpected.
if grep -q '\$(' "$FRAG" || grep -q '`' "$FRAG"; then
    die2 "extracted t() contains a command substitution — refusing to source it"
fi

# --- 2. enumerate candidate keys (union; never attributed to a block) --------
n_fmt=$(grep -c 'fmt=' "$FRAG")
n_case=$(grep -cE '^[[:space:]]*[A-Za-z0-9_]+\)[[:space:]]*fmt=' "$FRAG")

[ "$n_fmt" -gt 0 ] || die2 "no 'fmt=' line in the extracted t()"
if [ "$n_fmt" -ne "$n_case" ]; then
    die2 "$((n_fmt - n_case)) 'fmt=' line(s) did not parse as a key (parsed $n_case of $n_fmt) — the parser has drifted"
fi

sed -nE 's/^[[:space:]]*([A-Za-z0-9_]+)\)[[:space:]]*fmt=.*/\1/p' "$FRAG" | sort -u > "$KEYS"
n_keys=$(grep -c . "$KEYS")
[ "$n_keys" -gt 0 ] || die2 "no key parsed from the extracted t()"

# --- 3. render behaviourally, one bash child per language -------------------
cat > "$TMP/render.sh" <<'RENDER'
frag="$1"; keysfile="$2"; lang="$3"
. "$frag" || exit 90
LANG_CHOICE="$lang"
while IFS= read -r k; do
    [ -n "$k" ] || continue
    # A key missing from THIS table leaves `fmt` unset; `printf` then dereferences
    # it under `set -u` and the subshell dies — the production failure mode.
    out=$( t "$k" 2>&1 ); st=$?
    spec=${out//%%/}          # a literal %% is not a conversion specifier
    spec=${spec//[!%]/}
    printf '%s\t%s\t%s\t%s\n' "$k" "$st" "${#out}" "${#spec}"
done < "$keysfile"
RENDER

for lang in en zh; do
    bash -u "$TMP/render.sh" "$FRAG" "$KEYS" "$lang" > "$TMP/out.$lang" 2> "$TMP/err.$lang"
    got=$(grep -c . "$TMP/out.$lang")
    if [ "$got" -ne "$n_keys" ]; then
        die2 "$lang render produced $got of $n_keys records (see stderr: $(head -1 "$TMP/err.$lang"))"
    fi
done

# --- 3b. self-check: the two renders MUST differ (R-7) ----------------------
# Without this, the checker has a false-green blind spot. If the LANG_CHOICE
# dispatch in the target file breaks, BOTH children render the SAME (English)
# table, step 4 compares en against en, agrees with itself, and prints
# "OK: N keys, both languages" while zh is unreachable — a green light from the
# very gate that exists to catch unreachable-language bugs. Two full renders of
# dozens of keys cannot be byte-identical unless the dispatch never switched.
if cmp -s "$TMP/out.en" "$TMP/out.zh"; then
    die2 "en and zh renders are byte-identical — the language dispatch in $FILE never switched, so this check cannot see zh at all (it would otherwise pass vacuously)"
fi

# --- 4. compare -------------------------------------------------------------
bad=0
while IFS=$'\t' read -r k_en st_en len_en spec_en <&3 && IFS=$'\t' read -r k_zh st_zh len_zh spec_zh <&4; do
    [ "$k_en" = "$k_zh" ] || die2 "render records out of order ($k_en vs $k_zh)"
    miss=""
    if [ "$st_en" -ne 0 ] || [ "$len_en" -eq 0 ]; then miss="en"; fi
    if [ "$st_zh" -ne 0 ] || [ "$len_zh" -eq 0 ]; then miss="${miss:+$miss and }zh"; fi
    if [ -n "$miss" ]; then
        printf '%s: missing in %s (renders in %s only)\n' "$k_en" "$miss" \
            "$([ "$miss" = "en" ] && echo zh || { [ "$miss" = "zh" ] && echo en || echo neither; })"
        bad=$((bad + 1))
        continue
    fi
    if [ "$spec_en" -ne "$spec_zh" ]; then
        printf '%s: specifier count differs (en=%s zh=%s)\n' "$k_en" "$spec_en" "$spec_zh"
        bad=$((bad + 1))
    fi
done 3< "$TMP/out.en" 4< "$TMP/out.zh"

if [ "$bad" -gt 0 ]; then
    printf 'FAIL: %s of %s keys break bilingual parity in %s\n' "$bad" "$n_keys" "$FILE"
    exit 1
fi

printf 'OK: %s keys, both languages\n' "$n_keys"
exit 0
