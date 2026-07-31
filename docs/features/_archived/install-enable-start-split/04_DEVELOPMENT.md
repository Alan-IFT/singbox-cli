# 04 — Development Record — install-enable-start-split (T-01)

- **Task ID**: T-01 · **Mode**: full · **Date**: 2026-07-31 — **rev. 3 (rewritten in place per gate C-8; rev.-1 content deleted, not appended to)**
- **Upstream**: `01_REQUIREMENT_ANALYSIS.md` rev. 2 (`READY`), `02_SOLUTION_DESIGN.md` **rev. 3** (`READY`),
  `03_GATE_REVIEW.md` **rev. 3** (`APPROVED WITH CONDITIONS` = PASS; C-1, C-5, C-6, C-7, C-8, C-9 in force;
  C-2/C-3/C-4 retired)
- **Dispatch context**: deferred-human mode (defer, do not ask); do not commit, do not push
- **Verdict**: `READY FOR REVIEW`

> **This document supersedes its rev.-1 self entirely.** The rev.-1 claims — `INSTALL_OK`,
> "no user-facing string was added", "exit 0 on both paths" — are all **false of the shipped code** and
> have been removed rather than annotated.

---

## Summary

`install.sh` now **reports its true outcome**. Three pessimistic phase variables (`PHASE_RULESETS`,
`PHASE_CONFIG`, `PHASE_SERVICE`) are written by the step that owns each phase and read by one new function
`install_report()`, which prints the closing block **and** returns the process exit status — so the banner
and the exit code can no longer disagree. Steps 6-7 append both streams to `/var/log/sing-box/install.log`
behind a one-time writability probe, with the displayed path (`INSTALL_LOG`) and the redirection target
(`LOG_SINK`) kept as **two separate variables** so no message can name `/dev/null`. `INSTALL_OK` is retired;
the `cleanup` EXIT trap is made empty-array-safe so it cannot override the derived status on bash 4.2.
All nine regions of `02` rev. 3 §4.A-§4.I were implemented **verbatim**; no design decision was made and
there is **no drift**.

---

## Files changed

- `/home/alan/Programs/singbox-cli/install.sh` — nine regions, everything else byte-identical.
  386 lines at HEAD → **497** lines.
  - **§4.A** `install.sh:18-30` — `INSTALL_LOG` / `LOG_SINK` + the three `PHASE_*` constants, appended
    after `SB_REPO=` with the design's comment block.
  - **§4.B** `install.sh:301-305` — `cleanup()` guards both the array expansion
    (`${CLEANUP_DIRS[@]+"…"}`) and the `rm -rf`; `trap cleanup EXIT` untouched.
  - **§4.C** `install.sh:132` / `:167` — `step6_warn` rewritten (now takes one `%s`);
    `install.sh:154-164` (zh) and `:200-210` (en) — 11 new keys each, same names, same order.
  - **§4.D** `install.sh:219-268` — new `install_report()`, immediately after `t()`'s closing `}`.
  - **§4.E** `install.sh:443-452` — the `# ---- install log ----` block and the `umask 027` probe,
    inserted after the blank line following `visudo -c -f …`, with one new blank line before step 6.
  - **§4.F** `install.sh:454-463` — step 6 records `PHASE_RULESETS` and picks
    `step6_warn` / `step6_nolog` via `elif`.
  - **§4.G** `install.sh:465-492` — step 7: registration unchanged in shape, all redirections moved to
    `$LOG_SINK`, `PHASE_CONFIG` / `PHASE_SERVICE` recorded, `systemctl start sing-box` and
    `rc-service … start` now in `if` condition position.
  - **§4.H** `install.sh:494-497` — `install_report || exit 1` / `exit 0`; the 13 banner lines **moved**
    (not retyped) into §4.D.
- `/home/alan/Programs/singbox-cli/CHANGELOG.md:8` — the single existing bullet **amended in place**
  (§4.I verbatim). No second bullet, no heading, no version bump; the file still has exactly 2 bullets
  under `## [Unreleased] → ### 修复`.

**Not changed** (verified empty `git diff`): `bin/sc` (all three timeouts `:583`/`:742`/`:812` untouched),
`uninstall.sh`, `systemd/*`, `README*.md`, `.harness/**` (incl. `verify_all.sh` and
`85-design-discipline.md`), `docs/dev-map.md`, `docs/batches/default/BATCH_PLAN.md`.

**Uncommitted, outside the diff**: `test/step7/run.sh` — the QA harness, gitignored via `.gitignore:19`
(`git check-ignore -v` confirms). `docs/tasks.md`'s one-line change is the **PM's** stage-0 board row,
present before this agent started; I did not touch that file.

---

## Mechanical verification of the three highest-risk details

Measured with commands, not eyeballed.

| Check | Command | Result |
|---|---|---|
| **Key parity 40/40** | key names extracted per `case` block from `install.sh` and compared | zh **40**, en **40**, **identical names in identical order**, no duplicates, all 11 new keys in both |
| **Format arity** | `%` count per new key | `fail_status`, `fail_log`, `fail_nolog`, `step6_warn`, `step6_nolog` = **exactly one `%s`** in both branches, each called with **1** argument; the other 6 new keys = **zero `%`**, called with 0 |
| **The variable split** | `grep -c '>>"$LOG_SINK" 2>&1'` | **8** — all eight §4.F/§4.G redirections; no half-rename |
| | `grep -c '^INSTALL_LOG='` | **1** — never reassigned |
| | `$INSTALL_LOG` as a redirection target | **only** at `install.sh:450` (inside the probe) |
| | `t` calls naming the log (`install.sh:263,265,460,462`) | all four pass `"$INSTALL_LOG"`; `LOG_SINK` is **never** an argument to `t` |
| **Probe polarity** | `install.sh:450` | copied as printed: no `!`, `2>/dev/null` on the **subshell**, no `else`, no assignment inside the subshell |
| **`INSTALL_OK` retired** | `grep -c INSTALL_OK install.sh` | **0** (comment + both assignments gone) |
| **Success output unchanged** | dedented `install.sh:224-225,227-237` vs `HEAD:install.sh:374-386` | `diff` **empty** — the 13 banner lines and all three 55-char `═` separators are byte-identical, moved not retyped |
| **Trap cannot eat the status** | §4.B extracted and run standalone under `set -euo pipefail` with `exit 7` | empty array → **rc 7**; non-empty array → **rc 7** *and* the directory is still removed |

---

## verify_all result

| | PASS | WARN | FAIL | SKIP | exit |
|---|---|---|---|---|---|
| **Baseline** (before any edit) | 16 | **0** | **0** | 2 | **0** |
| **After changes** | 16 | **0** | **0** | 2 | **0** |
| **Delta** | 0 | 0 | 0 | 0 | 0 |

Verbatim: `PASS: 16 / WARN: 0 / FAIL: 0 / SKIP: 2`, exit **0**, both before and after. The rev.-1 F.6
doc-size WARN is gone and **no new WARN was introduced** (`[F.6] Active task docs <=500 lines each … PASS`;
this document and all six stage docs are under the 500-line cap — C-9).
`[B.2] Tests pass` / `[B.3] Lint` remain **SKIP**: the harness is uncommitted by construction, so wiring
B.2 is T-07's (design D-6, C-5 forbids touching `verify_all.sh`).

Direct commands (AC-1 + `50-singbox-cli.md`'s minimum manual verification):
`bash -n install.sh` → **PASS**, `bash -n uninstall.sh` → **PASS**, `python3 -m py_compile bin/sc` → **PASS**.

### `git diff --stat`

```
 CHANGELOG.md  |   1 +
 docs/tasks.md |   2 +-
 install.sh    | 157 +++++++++++++++++++++++++++++++++++++++++++++++++---------
 3 files changed, 136 insertions(+), 24 deletions(-)
```

`install.sh` + `CHANGELOG.md` are mine; `docs/tasks.md` is the PM's pre-existing row. `git diff` against
`bin/sc`, `uninstall.sh`, `systemd/`, `.harness/`, `README*.md`, `docs/dev-map.md` and `docs/batches/` is
**empty** in every case (AC-10). `git status --short` lists no `test/` entry.

---

## QA harness (optional; built for confidence — stage 6 owns QA)

`/home/alan/Programs/singbox-cli/test/step7/run.sh`, rewritten for `02` rev. 3 §10.2/§10.2.1/§10.2.3.
**C-6 honored**: `T_DIR` is passed in the scenario env, the stub is pure-builtin (`${0##*/}`, no
`basename`), the awk extraction uses `[+]`, and matching is whole-line `grep -nxF`/`-qxF`.
**G-8 honored**: `LOG_PATH` is always a path under `$T`, never `/dev/null`.

**Result: `PASS: 334 / FAIL: 0`.** Every scenario runs twice per language (`en` and `zh`) — AC-16 — and
every run is checked for `unbound variable` on stderr. Coverage: S1, S2 (+S2b = `sc` deleted → 127), S4,
S5, S6 (+S6b = strict `PATH="$STUB"`, `systemctl` stub deleted), S7, S9, S10, S11 (S1/S2/S10 twins under a
`chmod 500` dir), S13 (idempotency, one run marker per run), S14 (static 40/40 parity), plus the
§10.2.3 **HEAD baseline** for AC-5. Load-bearing observations:

- **AC-5**: S1's stdout is **byte-identical** to the HEAD baseline in *both* languages — the banner move
  changed nothing a user sees. Baseline `HEAD` = `6282cea`; both §10.2.3 tripwires fired correctly.
- **AC-14**: exit **1** on S2/S2b/S5/S7/S10, exit **0** on S1/S4/S6/S9. `PHASES` (a genuine `set -u` probe,
  no `:-` defaults) matched the design's table on every scenario.
- **Q2/AC-18**: `update-rules`' **stdout** cause *and* stderr aggregate both reach the log, and neither
  reaches the terminal — the stderr-only reading really would have lost the cause.
- **S11/G-1**: the degraded run's stdout contains **no `/dev/null` token**, the probe is silent
  (no `Permission denied`), the log file is never created, and the stdout delta versus the writable twin is
  exactly as the gate derived: **0** lines for S1, **1** (`fail_log`→`fail_nolog`) for S2, **2**
  (+`step6_warn`→`step6_nolog`) for S10 — with identical `PHASES` and identical exit status (**B-17**).

Three harness bugs were found and fixed; **none was a production defect** — verified individually:
a sloppy `t .*\$LOG_SINK` regex that matched `start sing-box…`; the driver's `declare -f | tail` (an
*external* command, which the strict-PATH scenario correctly starved — replaced with pure-builtin
`${_body#*$'\n'}`); and an S11 assertion that expected the twin's removed line to carry the *degraded*
path when the two runs necessarily use different `LOG_PATH`s.

**AC-9 is NOT executed and is not executable here** (no systemd-capable, network-restricted host, no root):
it is **deferred to T-07** per C-7. Design §10.3's four coverage limits must be restated verbatim in
`06_TEST_REPORT.md`.

---

## Design drift

**None.** No `DESIGN DRIFT` to flag: all nine regions are character-identical to `02` rev. 3 §4, including
comments. C-5's prohibitions were actively honored — no `INSTALL_LOG` reassignment, no `LOG_SAVED` flag,
no predicate function, no re-probe, no `/dev/null` in any user-facing string, no `local fmt=""`, no
liveness probe, no persisted state, no `tee`/`date`/new external command, `t step7` unmoved and unreworded,
no timeout touched, no second CHANGELOG bullet, and no success test outside `install_report()`.

Rule compliance: 11 new user-facing strings ship in **both** languages (`50-singbox-cli.md`'s hard
requirement, verified 40/40 mechanically and exercised in both languages by every scenario); `install.sh`
remains a **single self-contained file** with no new dependency, external command or network call; step 6-7
write only the append-only log and touch neither `nodes.json` nor `settings.json`, so installer idempotency
holds (S13 proves it at region granularity).

---

## Open issues for review

1. **The gate's premise about `HEAD` is wrong, harmlessly.** `03` rev. 3 §2.3 states "the working tree is
   clean at HEAD, so HEAD already carries the rev-1 step-7 block". It does **not**: `HEAD` (`6282cea`) is
   the *pre-rev-1* installer (386 lines) and both the rev-1 step-7 block and the rev-1 CHANGELOG bullet
   were **uncommitted working-tree edits**. Consequences, all benign: `git diff install.sh` shows rev-1 +
   rev-3 together (157 lines), `CHANGELOG.md` shows `1 +` and not `1 +/1 -`, and the §10.2.3 baseline is
   built from the **original** installer — a *stronger* AC-5 check than comparing against rev. 1. No
   tripwire misfired. QA and the reviewer should read the diff with this in mind.
2. **R1 stands** (`PHASE_SERVICE=started` is a launch-command result, not liveness; `Type=simple`), and
   **R5's TOCTOU residual** stands (a disk that fills *after* the probe leaves the run saying "written
   to <path>"). Both are accepted design positions, not implementation gaps.
3. **`systemd/sing-box-rules-update.service:7`** still has the stale `ExecStart=/usr/local/bin/proxy`
   (203/EXEC) — pre-existing, out of scope per §12(8), recommended as backlog row `T-08`.
4. **B.2/B.3 remain SKIP.** The harness is proven (334 assertions, no root, no network, no new
   dependency) but stays uncommitted per AC-10; promotion is T-07's, and it is now cheap.

---

## Dev-map updates

**None.** No module was added, moved or removed — the change is internal to one existing Bash script, and
the only new file is the gitignored QA harness. `docs/dev-map.md` is byte-identical to HEAD, as `02` §2
requires.

---

## Insight to surface

- `install.sh` is **executable in isolation from any section marker to EOF** with zero new dependencies and
  no root — `sed -n '/^t() {$/,/^}$/p'` for the message table, `sed -n '/^install_report() {$/,/^}$/p'` for
  the report, `awk '/^# -+ <marker> -+$/{f=1} f'` for the tail, one absolute-path rewrite and four
  symlinks to a single pure-builtin `${0##*/}`-dispatch stub — so this repo can have a real `verify_all`
  B.2 command whenever T-07 wants one · evidence: `test/step7/run.sh` (uncommitted), 334/334 assertions
  green against `install.sh:443-497`, both languages, including a byte-identity diff versus `HEAD:install.sh`

---

## Verdict

**READY FOR REVIEW**
