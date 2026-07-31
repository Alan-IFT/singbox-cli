# Delivery Summary — T-11 `install-version-query-abort`

- **Task**: `install-version-query-abort` — fix `install.sh`'s sing-box version query, where a
  command-substitution assignment aborted the script before its own error handler could run, letting
  the installer exit having stated no outcome at all.
- **Mode**: full (stages 1 → 7)
- **Decision mode**: deferred-human (`defer, do not ask`), standing owner authority (「你来决策就行」).
  No `BLOCKED: NEEDS-HUMAN` was raised; no safety red line was engaged.

## Stages traversed

| Stage | Agent | Verdict | Doc |
|---|---|---|---|
| 1 | requirement-analyst | `READY FOR DESIGN` | `01_REQUIREMENT_ANALYSIS.md` (549L) |
| — | **PM pre-flight** | E-0 **7/7 MATCH**, stop rule not triggered | recorded in `PM_LOG.md` |
| 2 | solution-architect | `READY FOR GATE REVIEW` | `02_SOLUTION_DESIGN.md` (500L) |
| 3 | gate-reviewer | `APPROVED FOR DEVELOPMENT` (C-1…C-17) | `03_GATE_REVIEW.md` |
| 4 | developer | `READY FOR REVIEW` | `04_DEVELOPMENT.md` (496L) |
| — | **PM probe** | sha dispute settled: HEAD is `9184171` | recorded in `PM_LOG.md` |
| 5 | code-reviewer | `APPROVED` (0 CRITICAL, 0 MAJOR, 5 MINOR) | `05_CODE_REVIEW.md` |
| 6 | qa-tester | `PASS` (0 BLOCKER/CRITICAL/MAJOR, 3 MINOR) | `06_TEST_REPORT.md` (499L) |
| 7 | PM | delivered | this document |

All on 2026-08-01.

## Rollbacks: 0

No stage was routed back. Three upstream defects were found and each was discharged by a **ruling or
a re-homed row** rather than a round trip, because none reached the product code: the gate's F-1
substitution miscount (ruling C-9), the design's defective E-10 fixture (corrected out of band by the
developer *before* editing, per C-8), and the design's "+11 line shift" (actually +14).

Three **capability gaps** surfaced and were absorbed by the PM rather than by the pipeline:
stage 2 and stage 3 have no shell tool (so AC-1's experiment was re-homed to a PM pre-flight, and
the sha dispute to a PM probe), and stages 3 and 5 have no write tool (so both documents were
returned in-message and persisted verbatim by the PM).

## What shipped

`install.sh:373-395` — the bare assignment becomes an `if`-guarded one (an exempt context under
`set -e`, proven by E4/E9), with `SB_VER=""` pre-assigned for `set -u`, and `head -1` replaced by an
addressed `sed`:

```bash
    SB_VER=""
    if ! SB_VER=$(curl "${CURL_OPTS_QUIET[@]}" "https://api.github.com/repos/${SB_REPO}/releases/latest" \
        | grep '"tag_name"' \
        | sed -n '1s/.*"v\([^"]*\)".*/\1/p'); then
        SB_VER=""
    fi
```

The existing validation at `:391-395` is now the **only** judge of whether the version is usable; the
pipeline's status never decides. All five failure modes — transport failure, non-2xx (the routine
403 rate limit), 2xx with no `tag_name`, empty version, non-semver version — converge on the
localized `download_failed` / `check_network` pair and `exit 1`.

**Reporting route — decided, not defaulted.** The failure keeps an **explicit early exit** and does
**not** route through `install_report()`. Routing it there would have printed six statements that are
false or useless at step 2 (`fail_config` when config generation never ran; `fail_rulesets`;
`sc update-rules` / `sc reload`, installed at `:398`; `systemctl status`, at `:428`; a log path whose
directory does not exist yet). The gate verified all six against the source. `CONTEXT.md`'s
definition of **stated outcome** is satisfied by the two `t` calls plus the derived exit status —
T-01's guarantee is that the installer states its outcome, not that it does so through one particular
function. Consequence: **AC-11 holds with no exception at all** — the phase machinery,
`install_report()` and the closing `install_report || exit 1` are byte-identical to HEAD, verified by
range diff at stage 6.

Also shipped: `.harness/scripts/check-i18n-parity.sh` (new) wired as `verify_all` **B.2**, turning a
permanently-`SKIP` step into a real gate. This closes a hazard deferred four tasks running
(`install.sh`'s `t()` declares `local fmt` with no default, so a key in one language table only
aborts the whole installer under `set -u`, and the zh branch is reachable only by answering `2`).

## Final verify_all result: **PASS**

```
PASS: 16   WARN: 1   FAIL: 0   SKIP: 1
```

**0 FAIL — the gate is met.** `verify_all` exits 1 whenever warns > 0; that is not failure.
Delta against a **clone** of pristine HEAD (never a `git worktree` — insight L26): 18/18 steps
compared, **exactly two changes**, both predicted in advance:

- `B.2 install.sh bilingual key parity` — `SKIP` → **PASS** (this task made it real)
- `F.6 Active task docs <=500 lines each` — `PASS` → **WARN**

The F.6 WARN's sole offender is stage 1's own 549-line `01_REQUIREMENT_ANALYSIS.md`. It is known,
attributable, and **self-clearing by construction**: `verify_all.sh:223-231` skips any path
containing `/_archived/`, and `archive-task.sh` moves this folder there. Compaction was deliberately
declined at three levels (PM-1, gate A-6): rewriting a 549-line document that is the binding contract
for 15 acceptance criteria risks silently dropping binding content for cosmetic gain.

**Post-archive confirmation (added after `archive-task.sh` ran):** the prediction held. With the task
folder moved under `docs/features/_archived/`, F.6 returned to PASS and the run is now
**PASS: 17 / WARN: 0 / FAIL: 0 / SKIP: 1, exit 0**. The only remaining SKIP is B.3 (lint).
The insight harvested as **one physical line** with its `· evidence:` tag intact (insight L21's
truncation trap did not fire); `.harness/insight-index.md` went 28 → 29 lines, under the F.4 cap of
30, and no rotation to `insight-history.md` was needed.

## Baseline changes

`.harness/scripts/baseline.json` still reads `test_count: 0` and was **not** modified — it sits
outside the gate's permitted diff and is filed as R-4. This task is nonetheless the first to leave a
**committed** automated check behind (`verify_all` B.2); every prior task built a throwaway harness
and discarded it.

## Files changed

7 tracked files, **+85 / −9**, plus 2 untracked additions:

```
 .harness/rules/50-singbox-cli.md |  6 ++++--
 .harness/scripts/verify_all.sh   |  8 +++++++-
 CHANGELOG.md                     |  2 ++
 CONTEXT.md                       | 14 ++++++++++++++
 docs/dev-map.md                  |  9 ++++++++-
 docs/tasks.md                    | 33 ++++++++++++++++++++++++++++++++-
 install.sh                       | 22 ++++++++++++++++++----
?? .harness/scripts/check-i18n-parity.sh
?? docs/features/install-version-query-abort/
```

**Product code is `install.sh` alone: +18 / −4.** Two of the eleven permitted items
(`.harness/rejected-decisions.md`, `.harness/insight-index.md`) are delivery-owned.

**Not committed, not pushed** — the owner handles delivery, as instructed.

## Verification highlights

- **QA rebuilt the harness from the acceptance criteria** rather than re-running the developer's
  (stage 5 [VERIF-1]), so the two witnesses are independent rather than duplicated. **102 assertions,
  0 failures** across 5 failure modes × 2 languages; 145 runs, zero flakes.
- **Non-vacuity was proven, not assumed.** The success-path test was made to fail on demand: dropping
  the `1` address from the `sed` flips three of three assertions. Negative controls reproduce the
  original mute abort on the HEAD fragment (`exit=1`, empty stdout) for modes 1-3.
- **Bilingual parity tested in both languages**, per insight L10 — zh literals `下载失败` /
  `请检查网络后重试` asserted, and zh stdout proven different from en stdout for all six modes.
- **`install.sh` was never executed by any stage.** Only a guarded ≤20-line extracted fragment ran,
  inside a `mktemp -d`, with a stubbed `curl` (198 stub calls, **0 real network requests**) and 18
  poison-pill executables leading `PATH` (`POISON` lines logged: **0**).
- **Live service provably untouched at four independent checkpoints** — task start, development
  start, development end, QA end — all reading `MainPID=2500438`,
  `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST`. Per insight L22, `systemctl is-active` was not
  used: it prints `active` on both sides of a restart and would have passed *during* the incident it
  was written to catch.

## Outstanding risks

1. **[VAC-1 / QA-2] The new B.2 gate has two blind spots — confirmed with tool evidence, and it is
   now permanent.** Mutating `install.sh:143`'s `LANG_CHOICE` dispatch on a temp copy makes
   `check-i18n-parity.sh` render the **en** table twice, agree on every comparison, print
   `OK: 41 keys, both languages` — a literally false statement — and **exit 0**, with zh unreachable.
   It also cannot see a key missing from *both* tables, though that aborts the installer under
   `set -u`. The product is clean today (41 keys, both tables, verified independently by reading
   them); the *gate* is not. Filed as **R-7**.
2. **T-01's guarantee is still not global** (D-7). At least six bare commands in `install.sh`
   (`python3` heredoc, `tar`, `install -m`, `chmod`, `visudo`) still abort with no stated outcome.
   This task closed the version-query hole only, and `CHANGELOG.md` says so explicitly rather than
   claiming the broader property. Filed as R-3.
3. **The `22502f9` sha label is wrong in every stage document.** HEAD is `9184171`; `22502f9` is 13
   commits behind (the pre-harness-bootstrap commit). All line anchors were verified **correct for
   `9184171`** and resolve to nothing coherent at `22502f9` — so the documents were written against
   the right file and mislabelled the commit. The clone baseline was taken from the real HEAD and is
   valid. Correcting the label in a 549-line document was judged not worth the content risk;
   **this paragraph is the correction of record.**
4. **Restricted-network end-to-end verification remains unreproduced** here (no such VM) — a standing
   gap carried since T-01, not introduced by this task.

## Next steps for user

- Review and commit. Suggested scope: the 7 modified files plus
  `.harness/scripts/check-i18n-parity.sh`; the task folder is archived by tooling.
- **R-7** (the B.2 blind spot) is the highest-leverage follow-up: a one-line guard asserting that at
  least one key renders differently between the two languages closes leg (a).
- `.harness/rejected-decisions.md` entries owed at commit time (C-16): D-5 (GitHub API
  authentication — declined), `installer-early-exit-download-helper` (declined, R-5), and a closing
  line on `installer-version-query-silent-abort` naming T-11 as its resolution.

## Insight

- 2026-08-01 · `check-i18n-parity.sh` (now `verify_all` B.2) renders both languages *through* `install.sh`'s own `LANG_CHOICE` dispatch, so breaking that dispatch makes it render the **en** table twice, agree on every comparison, print `OK: 41 keys, both languages` and exit 0 while the zh path is entirely unreachable — a committed gate that passes by rendering the same table twice · evidence: install-version-query-abort
