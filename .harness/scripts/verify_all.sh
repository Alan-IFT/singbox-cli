#!/usr/bin/env bash
# verify_all.sh — Generic project total verification
# Generated for singbox-cli (Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management) on 2026-07-31
# Mirror of verify_all.ps1. See that file for full doc.

set -uo pipefail

errors=0
warns=0
skips=0
declare -a report

step() {
    local id="$1" name="$2" status="$3" detail="${4:-}"
    case "$status" in
        PASS) echo "[$id] $name ... PASS" ;;
        WARN) echo "[$id] $name ... WARN"; ((warns++)) ;;
        SKIP) echo "[$id] $name ... SKIP"; ((skips++)) ;;
        FAIL) echo "[$id] $name ... FAIL"; [[ -n "$detail" ]] && echo "      $detail"; ((errors++)) ;;
    esac
    report+=("$id|$name|$status")
}

echo "=== verify_all (generic) ==="
echo "Project: singbox-cli"
echo "Stack:   Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management"
echo ""

# --- A. Hygiene (universal) ---
if [[ ! -d .git ]]; then
    step "A.1" "No hardcoded secrets" "SKIP"
else
    if git grep -E "(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*[\"'][^\"']{8,}[\"']" \
        -- ':!*.md' ':!.harness/scripts/verify_all*' ':!.harness/*' &>/dev/null; then
        step "A.1" "No hardcoded secrets" "FAIL" "Possible secret detected"
    else
        step "A.1" "No hardcoded secrets" "PASS"
    fi
fi

if [[ ! -d .git ]]; then
    step "A.2" "No .env files committed" "SKIP"
else
    env_committed=$(git ls-files '*.env' '.env*' 2>/dev/null | grep -vE 'example|sample' || true)
    [[ -z "$env_committed" ]] && step "A.2" "No .env files committed" "PASS" || step "A.2" "No .env files committed" "FAIL" "$env_committed"
fi

# >>> HARNESS:B-CUSTOM:BEGIN (your build/test/lint checks live here; preserved across /harness-upgrade) <<<
# --- B. Build / test / lint (CUSTOMIZE FOR Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management) ---
# TODO: Replace each SKIP with your actual command for Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management.
# Examples at the bottom of this file.
# B.1 — no compile step (bin/sc is run directly, shell scripts are interpreted).
# Substitute a syntax gate: a parse error in either artifact bricks the installed CLI.
b1_syntax=""
if command -v python3 >/dev/null 2>&1; then
    if ! python3 -m py_compile bin/sc 2>/dev/null; then
        b1_syntax="bin/sc fails python3 -m py_compile"
    fi
    rm -rf bin/__pycache__ 2>/dev/null || true
else
    b1_syntax="python3 not found"
fi
for sh_file in install.sh uninstall.sh; do
    [[ -f "$sh_file" ]] || continue
    bash -n "$sh_file" 2>/dev/null || b1_syntax="$b1_syntax; $sh_file fails bash -n"
done
[[ -z "$b1_syntax" ]] && step "B.1" "Syntax (bin/sc, install.sh, uninstall.sh)" "PASS" \
    || step "B.1" "Syntax (bin/sc, install.sh, uninstall.sh)" "FAIL" "$b1_syntax"

step "B.2" "Tests pass" "SKIP"
step "B.3" "Lint" "SKIP"
# >>> HARNESS:B-CUSTOM:END <<<

# --- E. Project structure (Harness required) ---
e1_missing=""
for f in AI-GUIDE.md CLAUDE.md .github/copilot-instructions.md; do
    [[ -f "$f" ]] || e1_missing="$e1_missing $f"
done
[[ -z "$e1_missing" ]] && step "E.1" "Bootstrap files present" "PASS" || step "E.1" "Bootstrap files present" "FAIL" "missing:$e1_missing"

[[ -f docs/workflow.md ]] && step "E.2" "workflow.md present" "PASS" || step "E.2" "workflow.md present" "FAIL"

# E.3 — agents layout (v0.30+): the 7 framework agents are PLUGIN-provided
# (harness-kit:<name>) and are NOT project files; .harness/agents/ holds only
# partition dev-* agents. Absence of the dir is healthy (single-developer project).
# Legacy framework copies WARN (not FAIL): /harness-upgrade v1 does not delete agent
# files, so an upgraded-but-unmigrated project must not end red with no in-flow fix.
e3_legacy=""
if [[ -d .harness/agents ]]; then
    while IFS= read -r agent_file; do
        agent_name=$(basename "$agent_file")
        case "$agent_name" in
            dev-*.md) : ;;
            *) e3_legacy="$e3_legacy $agent_name" ;;
        esac
    done < <(find .harness/agents -maxdepth 1 -name '*.md' -type f)
fi
if [[ -z "$e3_legacy" ]]; then
    step "E.3" "Agents layout v0.30+ (.harness/agents/ = partition dev-* only)" "PASS"
else
    step "E.3" "Agents layout v0.30+ (.harness/agents/ = partition dev-* only)" "WARN"
    echo "      framework agents are plugin-provided since v0.30 — remove local copies:$e3_legacy"
fi

if [[ -f .harness/scripts/harness-sync.sh ]] && bash .harness/scripts/harness-sync.sh --check &>/dev/null; then
    step "E.4" "Binding in sync (.harness/ -> .claude/)" "PASS"
else
    step "E.4" "Binding in sync (.harness/ -> .claude/)" "FAIL" "Run .harness/scripts/harness-sync.sh"
fi

# E.4b — hook<->script congruence (T-020): every script path referenced by a
# "command" line in .claude/settings.json must exist; an unresolved placeholder
# token in a command is also a FAIL. The path ERE is LEFT-BOUNDED (quote/space/=/
# line start) so a custom hook whose dirname merely ENDS in scripts/ (e.g.
# build-scripts/deploy.sh) can never match. Doc keys / permissions are NOT scanned
# (only the wired variant of a script pair is load-bearing).
if [[ ! -f .claude/settings.json ]]; then
    step "E.4b" "Hook commands resolve to existing scripts" "SKIP"
else
    e4b_bad=""
    e4b_tok="{{"   # assembled at runtime: generated file carries no literal token
    if grep '"command"' .claude/settings.json | grep -qF -- "$e4b_tok"; then
        e4b_bad="$e4b_bad\nunresolved placeholder token in a hook command"
    fi
    while IFS= read -r e4b_path; do
        [[ -z "$e4b_path" ]] && continue
        [[ -f "$e4b_path" ]] || e4b_bad="$e4b_bad\nhook command references missing script: $e4b_path"
    done < <(grep '"command"' .claude/settings.json \
        | grep -oE "(^|[\"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)" \
        | sed -E "s|^[\"' =]||" \
        | sort -u)
    if [[ -z "$e4b_bad" ]]; then
        step "E.4b" "Hook commands resolve to existing scripts" "PASS"
    else
        step "E.4b" "Hook commands resolve to existing scripts" "FAIL" "$(echo -e $e4b_bad) — fix: run /harness-upgrade"
    fi
fi

# E.5 — AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa)
if [[ ! -f AI-GUIDE.md || ! -d .harness/rules ]]; then
    step "E.5" "AI-GUIDE.md indexes every .harness/rules/*.md" "SKIP"
else
    e5_problems=""
    while IFS= read -r r; do
        name=$(basename "$r")
        if ! grep -qF ".harness/rules/$name" AI-GUIDE.md; then
            e5_problems="$e5_problems\nNot indexed: $name"
        fi
    done < <(find .harness/rules -maxdepth 1 -name '*.md' -type f)
    while IFS= read -r ref; do
        if [[ ! -f ".harness/rules/$ref" ]]; then
            e5_problems="$e5_problems\nReferences non-existent: .harness/rules/$ref"
        fi
    done < <(grep -oE '\.harness/rules/[0-9A-Za-z_\-]+\.md' AI-GUIDE.md | sed 's|\.harness/rules/||' | sort -u)
    if [[ -z "$e5_problems" ]]; then
        step "E.5" "AI-GUIDE.md indexes every .harness/rules/*.md" "PASS"
    else
        step "E.5" "AI-GUIDE.md indexes every .harness/rules/*.md" "FAIL" "$(echo -e $e5_problems)"
    fi
fi

# E.6 — Adversarial tests section required in every 06_TEST_REPORT.md
if [[ ! -d docs/features ]]; then
    step "E.6" "Adversarial tests section in completed task reports" "SKIP"
else
    bad_reports=""
    while IFS= read -r r; do
        if ! grep -qE '^##\s+Adversarial\s+tests' "$r"; then
            bad_reports="$bad_reports\n$r"
        fi
    done < <(find docs/features -name '06_TEST_REPORT.md' -type f 2>/dev/null)
    if [[ -z "$bad_reports" ]]; then
        step "E.6" "Adversarial tests section in completed task reports" "PASS"
    else
        step "E.6" "Adversarial tests section in completed task reports" "FAIL" "Missing section:$(echo -e $bad_reports)"
    fi
fi

# --- F. Document size caps (v0.14+, WARN-only; see .harness/rules/70-doc-size.md) ---

# F.1 — AI-GUIDE.md <=200 lines
if [[ -f AI-GUIDE.md ]]; then
    n=$(wc -l < AI-GUIDE.md)
    if (( n > 200 )); then step "F.1" "AI-GUIDE.md <=200 lines" "WARN" "$n lines (cap 200)"; else step "F.1" "AI-GUIDE.md <=200 lines" "PASS"; fi
else
    step "F.1" "AI-GUIDE.md <=200 lines" "SKIP"
fi

# F.2 — Rule fragments <=200 lines each
f2_over=""
if [[ -d .harness/rules ]]; then
    while IFS= read -r f; do
        n=$(wc -l < "$f"); (( n > 200 )) && f2_over="$f2_over $f:${n}L"
    done < <(find .harness/rules -maxdepth 1 -name '*.md' -type f)
fi
[[ -n "$f2_over" ]] && step "F.2" "Rule fragments <=200 lines each" "WARN" "over cap:$f2_over" || step "F.2" "Rule fragments <=200 lines each" "PASS"

# F.3 — Agent definitions <=300 lines each
f3_over=""
if [[ -d .harness/agents ]]; then
    while IFS= read -r f; do
        n=$(wc -l < "$f"); (( n > 300 )) && f3_over="$f3_over $f:${n}L"
    done < <(find .harness/agents -maxdepth 1 -name '*.md' -type f)
fi
[[ -n "$f3_over" ]] && step "F.3" "Agent definitions <=300 lines each" "WARN" "over cap:$f3_over" || step "F.3" "Agent definitions <=300 lines each" "PASS"

# F.4 — insight-index <=30 lines
if [[ -f .harness/insight-index.md ]]; then
    n=$(wc -l < .harness/insight-index.md)
    if (( n > 30 )); then step "F.4" "insight-index.md <=30 lines" "WARN" "$n lines — run .harness/scripts/archive-task to rotate"; else step "F.4" "insight-index.md <=30 lines" "PASS"; fi
else
    step "F.4" "insight-index.md <=30 lines" "SKIP"
fi

# F.5 — docs/tasks.md <=300 lines
if [[ -f docs/tasks.md ]]; then
    n=$(wc -l < docs/tasks.md)
    if (( n > 300 )); then step "F.5" "docs/tasks.md <=300 lines" "WARN" "$n lines — rotate Completed rows to docs/tasks-archive.md"; else step "F.5" "docs/tasks.md <=300 lines" "PASS"; fi
else
    step "F.5" "docs/tasks.md <=300 lines" "SKIP"
fi

# F.6 — Active task docs <=500 lines each (excludes _archived/)
f6_over=""
if [[ -d docs/features ]]; then
    while IFS= read -r f; do
        case "$f" in *"/_archived/"*) continue ;; esac
        n=$(wc -l < "$f"); (( n > 500 )) && f6_over="$f6_over $f:${n}L"
    done < <(find docs/features -type f \( -name 'PM_LOG.md' -o -name '0[1-7]_*.md' \) 2>/dev/null)
fi
[[ -n "$f6_over" ]] && step "F.6" "Active task docs <=500 lines each" "WARN" "over cap:$f6_over (see rule 70: compact PM_LOG or reference don't paste)" || step "F.6" "Active task docs <=500 lines each" "PASS"

# Summary
echo ""
echo "=== Summary ==="
pass_count=$(printf '%s\n' "${report[@]}" | grep -c PASS || true)
echo "  PASS: $pass_count"
echo "  WARN: $warns"
echo "  FAIL: $errors"
echo "  SKIP: $skips"

(( errors > 0 )) && exit 2
(( warns > 0 )) && exit 1
exit 0

# --- CUSTOMIZE: B.* examples for common stacks ---
# Rust:        cargo build  /  cargo test  /  cargo clippy
# Python:      python -m pytest  /  ruff check .  /  mypy .
# Go:          go build ./...  /  go test ./...  /  golangci-lint run
# .NET / C#:   dotnet build  /  dotnet test
# Java:        ./gradlew build  /  ./gradlew test
# Mobile:      xcodebuild test  /  ./gradlew connectedAndroidTest
