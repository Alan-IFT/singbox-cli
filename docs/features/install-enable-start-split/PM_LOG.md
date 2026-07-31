# PM Log — install-enable-start-split (T-01)

- **Mode**: full (stages 1 → 7) · **Started**: 2026-07-31 · **Dispatch**: deferred-human (defer, do not ask)
- **Developer mode**: single — no `.harness/agents/dev-*.md` partitions exist
- **Compacted 2026-07-31** per rule 70 (was 554 lines, breaching the 500-line cap and causing the sole
  `verify_all` F.6 WARN — QA finding D-1). Stages 1-3 rev-1 are summarized; all routing decisions,
  reversals and their reasons are preserved. Full detail lives in the stage documents themselves.

## Goal

Originally: split `enable` from `start` in `install.sh` step 7 so autostart registration is unconditional
and no optional-step failure aborts the installer. **Scope expanded mid-pipeline** (see Intervention) to:
**"install.sh reports its true outcome"** — registration + real error causes captured to a log + an honest
closing banner + non-zero exit on failure, as one coherent design.

## Pre-flight

`.harness/intervention.md` absent at every checkpoint (checked before stage 1 and after every stage).
`.harness/insight-index.md` empty — nothing to surface downstream. `docs/tasks.md` had no prior tasks.
`docs/dev-map.md` is a template. No partition agents → `harness-kit:developer`.

---

## Stage ledger

| # | Stage | Agent | Decision |
|---|---|---|---|
| 1 | Requirement | requirement-analyst | ADVANCE — `READY` |
| 2 | Design | solution-architect | ADVANCE — `READY` |
| 3 | Gate | gate-reviewer | ADVANCE — `APPROVED WITH CONDITIONS`, no blocking defects |
| 4 | Development | harness-kit:developer | ADVANCE — `verify_all FAIL: 0` |
| 5 | Code review | code-reviewer | ADVANCE — `APPROVED`, 0 critical/major |
| — | **INTERVENTION** | coordinator | **Scope expanded; rollback to stage 1** |
| 1b | Requirement (rev. 2) | requirement-analyst | ADVANCE — `READY` |
| 2b | Design (rev. 2) | solution-architect | ADVANCE — `READY` |
| 3b | Gate (rev. 2) | gate-reviewer | **ROLLBACK → stage 2** on finding G-1 |
| 2c | Design (rev. 3, G-1 fix) | solution-architect | ADVANCE — `READY` |
| 3c | Gate (rev. 3) | gate-reviewer | ADVANCE — explicit PASS, no FAIL **and no WARN** in any dimension |
| 4b | Development (rev. 3) | harness-kit:developer | ADVANCE — `PASS: 16 / WARN: 0 / FAIL: 0` |
| 5b | Code review (rev. 3) | code-reviewer | *(blocked once — see below)* → ADVANCE, `APPROVED` |
| 6 | QA | qa-tester | ADVANCE — `APPROVED FOR DELIVERY`, 0 code defects |
| 7 | Delivery | (PM) | in progress |

---

## Rev-1 pipeline (stages 1-5) — condensed

Analyst produced 11 behaviors, 14 boundary conditions, 12 acceptance criteria against the owner's supplied
`INSTALL_OK` shape (treated as a given). Two deferred questions were resolved by PM: **Q1** (CHANGELOG) →
add one line, routine hygiene; **Q2** (stderr suppression on `sc reload`) → follow the owner's shape
verbatim, with the resulting silent-failure window recorded as a *delivery-sequencing* matter owned by the
stream, not a requirement question. **That call was later overturned by the owner — see Intervention.**

Architect kept the owner's shape, added the `set -e`/`set -u`/subshell proof and a stub-PATH harness spec.
Gate approved with conditions C-1…C-7 and found F-1…F-7. PM **declined a rollback on F-3** (the requirement's
"exit status unchanged" was factually wrong — the failure path had silently regressed 1 → 0): the gate graded
it WARN not FAIL, the normative requirement was unambiguous, and overriding a cleared WARN with PM's own
judgment would breach hard rule 1. It was carried forward as a mandatory reporting duty instead.

Developer implemented verbatim; code review returned `APPROVED` and surfaced **STD-3** — `t()` declares
`local fmt` with no default, so a key present in only one language branch **aborts the installer** under
`set -u`, and the zh branch is only reached via the prompt at `install.sh:195-199`, so an English-only run
would never see it. This reclassified bilingual parity from a style rule to a crash risk and later became
first-class scope.

Both the gate-reviewer and code-reviewer have read-only tool sets and could not write their own documents;
PM persisted each verbatim with only a provenance note added.

---

## Intervention consumed at 2026-07-31 (coordinator message)

Arrived as a coordinator message, not `.harness/intervention.md`; handled under the same protocol as a
`REDIRECT`. The stage-6 dispatch was interrupted before running, so nothing was discarded.

**Directive**: owner's standing rule 优先用好的设计，避免不断的修修补补 — prefer a coherent design over
successive patches. This **invalidated the T-01/T-04 split**. The decisive point, and it was correct: the
tree was *incoherent on its own* — step 7 computed `INSTALL_OK` while the banner still printed
`✅ 安装完成` unconditionally, so **the installer still lied on the failure path**, the very defect reported.
This vindicated the concern the analyst raised as §8 Q2 and PM had recorded as an accepted window; the owner
ruled it unacceptable.

**New scope**: unconditional registration + status model; stop swallowing errors (log to
`/var/log/sing-box/install.log`); honest banner driven by collected status; non-zero exit on failure;
i18n mandatory. Out of scope unchanged: `bin/sc` degradation, ruleset download logic, all timeouts,
steps 4/5.

**Routing decision — PM routed to stage 1 first, then 2, though the coordinator said stage 2.** `01` did
not merely omit the new scope, it **forbade** it (§4.1 banner out of scope; B-11/AC-12 made "exit 0 on both
paths" normative). Designing against that would have drawn a correct requirement-gap bounce from the gate
and cost a full extra cycle — exactly the churn the directive targets. Fixing the requirement first cost one
stage and kept the chain coherent. Per hard rule 2, the analyst (the author) made the edit.

---

## Rev-2/3 pipeline

**1b — requirement rev. 2.** B-10/B-11 and AC-11/AC-12 explicitly **superseded**; new B-12…B-19,
AC-13…AC-20 mapped 1:1 onto the coordinator's provable (a)-(f) list. Prior findings folded in rather than
deferred: F-3 → B-11 (deliberate non-zero exit), F-4 → B-12, F-5 → B-18, STD-3 → B-10 + AC-16/AC-17,
SPEC-1 → B-16.

**The analyst caught a defect in the directive's literal wording.** The instruction was "stderr → log". But
`sc update-rules` prints the cause on **stdout** (`bin/sc:817`); stderr carries only the count
(`bin/sc:821`). A literal implementation would have logged "4 ruleset(s) failed to update" and **lost
`urlopen error timed out` — reproducing the reported defect inside the mechanism built to fix it.** B-12 was
written as an outcome ("the cause reaches the log"). PM endorsed honoring intent over literal wording.
Also verified: `/var/log/sing-box` already exists by step 6 (`install.sh:287`), and `uninstall.sh:137`
already removes it — no new mkdir, no residue.

**2b — design rev. 2.** One status model: `PHASE_RULESETS` / `PHASE_CONFIG` / `PHASE_SERVICE`, pessimistic
defaults, each written only by its owning step, read only by one `install_report()` that prints the banner
**and** returns the exit status. Architect decisions taken under its own authority, each flagged for gate
scrutiny rather than rubber-stamping:

- **`INSTALL_OK` retired** — the name asserts "the install is OK" while the value only ever encoded config
  generation (a failed `systemctl start` still left it `1`). Overrides the owner's literal shape, which the
  dispatch expressly permitted if defended.
- **Gate C-5's "do not hoist" and D-5's redirection asymmetry consciously reversed** — C-5 was scoped to
  rev-1 where *nothing read* the variable.
- No `tee` (pipefail would let a logging fault fail the install); `>>` + a one-time writability probe;
  `umask 027` → 0640. F-5/B-18 closed via `${CLEANUP_DIRS[@]+"${CLEANUP_DIRS[@]}"}`.
- **Q5 decided (b)** — no `verify_all.sh` edit: AC-10 confines the diff, and filling B.2 with a single
  parity assertion would make the gate claim more than it verifies.

**3b — gate rev. 2: ROLLBACK to stage 2 on G-1.** The gate confirmed all five load-bearing decisions and
explicitly retired its own two stale conditions. But **G-1**: `INSTALL_LOG` served two jobs — redirection
target *and* the string shown to the user — so on the degraded path the installer printed 「详细原因见
/dev/null」. The gate offered a cheaper path (document it via C-2/C-3).

**PM routed back instead.** Rationale: the owner had just rejected delivering a tree that prints a success
banner while knowing better; accepting a documented "prints `/dev/null`" behavior ships a smaller instance
of the same dishonesty, with a note explaining it — the pattern being rejected. Routed to the **architect**
(not the analyst) because the flaw is mechanical — one variable doing two jobs — and B-15's intent already
covered the requirement side. Recorded as the **2nd consecutive** return to stage 2; a third would trigger
the hard stop in rule 3.

**2c — design rev. 3.** `INSTALL_LOG` (what the user is *told*, assigned once, never reassigned) split from
`LOG_SINK` (where bytes *go*; pessimistic `/dev/null`, promoted only on proof). `[ "$LOG_SINK" =
"$INSTALL_LOG" ]` then reads exactly as "were this run's diagnostics saved". Architect **declined** a third
`LOG_SAVED` flag and a predicate function — applying the counter-rule against over-building to its own fix.
Cost: 2 keys (40/40), one `elif`, one `if/else`. Doc trimmed 524 → 481 lines, clearing the long-standing
F.6 WARN.

**3c — gate rev. 3: PASS.** G-1 closed. The gate enumerated all eight probe × phase combinations — every one
truthful, `/dev/null` never reaches stdout. Decisive: **rev. 2 violated AC-13 literally**; rev. 3 satisfies
it on every path. Also verified the equality test is *exact* not heuristic, the probe polarity flip is safe,
the EXIT trap cannot fire inside the probe subshell, and **all eight redirections use `$LOG_SINK`** with no
half-rename. The gate retired **C-2, C-3, C-4** as discharged rather than letting them bind by inertia;
**C-1 (amended to 40/40), C-5, C-6, C-7, C-8, C-9** remain. No FAIL and no WARN in any dimension.

Its own summary of the trade: *"The fix is smaller than the finding … PM's decision to route rather than
accept C-2/C-3 bought a real mechanism for roughly the cost of the paperwork it replaced."*

**4b — development rev. 3.** Verbatim, no drift. `install.sh` 386 → 497. Verified **mechanically, not by
eye**: 8/8 `$LOG_SINK` redirections, `^INSTALL_LOG=` exactly 1, `INSTALL_OK` count 0, keys 40/40, success
banner dedent-diffs empty vs `HEAD` (moved, not retyped), trap fix exercised standalone with `exit 7`.

*Correction to the record*: `HEAD` was **pre-rev-1** (386-line `install.sh`) — rev-1 was an uncommitted
working-tree edit all along. So the delivery diff is rev-1 + rev-3 combined, which is correct per gate §7,
and the AC-5 baseline is built from the *original* installer, making that check stronger.

**5b — blocked, then APPROVED.** Four consecutive `Agent` dispatches failed on a platform classifier outage
(`claude-sonnet-5[1m] temporarily unavailable`). PM declared a hard stop (external dependency blocked) and
**refused to review the code itself** (hard rule 1), skip to stage 7, or write a delivery doc. On the
coordinator's confirmation that the classifier was recovering, the dispatch succeeded on retry.

Reviewer returned **`APPROVED`** (0 critical, 0 major, 1 minor, 5 nit), **independently agreeing with all
three PM judgment calls** and confirming the third at source (`bin/sc:817` `print` → stdout vs `:821`
`sys.exit` → stderr). Required design-discipline finding: the +111 lines are **requirement-carried, no
speculative generality** — ~22 lines are the bilingual table alone. Its one MINOR (**M-1**) is a
reporting-scope item routed to QA: AC-5's byte-identity holds for *stdout under a silent stub*, but `HEAD`
ran `systemctl enable --now` unredirected, so real-host `Created symlink …` stderr now goes to the log
instead of the terminal — deliberate and approved, but structurally unobservable by the harness.

**6 — QA: `APPROVED FOR DELIVERY`, 0 defects in `install.sh`.** Everything below was executed, not reasoned:
`bash -n` clean; developer harness re-run, audited and hardened (334 PASS); a **QA-authored** adversarial
suite written from `01`'s ACs rather than from the developer's test code (341 PASS); and a **mutation run —
17 mutants, 17 killed, 0 survived**, which is what proves neither suite is vacuous. Every scenario in both
languages, including one that **executes the real language prompt** with 8 stdin cases instead of presetting
`LANG_CHOICE`. Mutation M13 (deleting the zh-only `fail_config`) confirmed the STD-3 abort is real and that
an English-only run cannot detect it. QA honored C-7 (AC-9 **UNVERIFIED**, deferred to T-07; four coverage
limits restated verbatim) and acted on M-1 by scoping the AC-5 claim.

QA also found **D-1 [MAJOR], a process defect outside the code**: this `PM_LOG.md` had grown to 554 lines,
breaching C-9's 500-line cap and becoming the sole `verify_all` WARN (`PASS: 15 / WARN: 1 / FAIL: 0`,
exit 1). **PM owns PM_LOG compaction and never delegates it** — resolved by this compaction. `FAIL` was 0
throughout, so the delivery gate was never at risk.

---

## Items carried to delivery

- **T-09** (owner-confirmed, separate pipeline): `systemd/sing-box-rules-update.service:7` has
  `ExecStart=/usr/local/bin/proxy`, a binary that does not exist — the weekly auto-update has never run on
  any install. systemd-only; `bin/sc:898` writes the correct path for OpenRC. **T-01 does not create it but
  widens its blast radius**: the timer is now enabled unconditionally, including on failed installs where
  `HEAD` aborted first. One line in `07_DELIVERY.md`.
- **Owner decision open (gate H-1 / design D-9)**: on the degraded-log path the installer names the real
  path and *denies* that diagnostics were saved (truthful) rather than claiming they were (shorter).
  Reversal is cheap and local.
- **T-07**: promote the QA suites into `verify_all` B.2 with the assertion floor set to **675**;
  `.harness/baseline.json` deliberately left untouched here (tracked file; editing it would breach AC-10).
- **T-05**: `PHASE_SERVICE=started` is a launch-command result, not a liveness fact (`Type=simple`).
