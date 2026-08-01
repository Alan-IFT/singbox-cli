# Delivery Summary — `sc doctor` (T-05)

- **Task:** `sc-doctor` — add a read-only `sc doctor` that prints, in one screen and in causal order,
  the seven facts a broken singbox-cli install is diagnosed from.
- **Mode:** `full` (stages 1-7).
- **Decision mode:** deferred-human (`defer, do not ask`) under the owner's standing authority
  (「你来决策就行」). No `BLOCKED: NEEDS-HUMAN` was raised — no safety red line was reached.

## Stages traversed

| Stage | Agent | Outcome |
|---|---|---|
| 1 | requirement-analyst | `READY FOR DESIGN` — 31 FR / 26 AC / 18 BC / 7 NFR / 10 resolved ambiguities |
| 2 | solution-architect | `READY FOR GATE REVIEW` — D-1..D-9, edit list E-1..E-18 |
| 3 | gate-reviewer | `APPROVED FOR DEVELOPMENT WITH CONDITIONS: C-1..C-8` (14 findings; 3 MAJOR, all instruction/test-method, none design-substance) |
| 4 | developer | `READY FOR REVIEW` — `verify_all` no FAIL, live service untouched |
| 5 | code-reviewer | `APPROVED WITH FOLLOW-UPS` — **zero BLOCKER, zero MAJOR** |
| 4b | developer (bounded fix-up) | M-2 + M-3 + M-1 discharged |
| 5b | code-reviewer (delta) | `DELTA APPROVED — prior verdict stands` (aggregate NIT) |
| 6 | qa-tester | `PASS WITH DEFECTS: DEF-1, DEF-2` — 688 assertions, all 26 ACs PASS |
| 4c | developer (bounded fix-up) | DEF-1 fixed — whole-CSI stripping in `_plain()` |
| 6b | qa-tester (targeted re-verify) | `PASS WITH DEFECTS: DEF-2` — **721 PASS / 0 FAIL** |
| 7 | PM | this document |

## Rollbacks: 2 — both to the developer, neither reaching the design

- **4b** (from stage 5): M-2 dangling header, M-3 record arithmetic, M-1 evidence gap.
- **4c** (from stage 6): DEF-1 ANSI CSI litter.

**No rollback reached stages 1-3.** Three design drifts found at stage 4 and three more at stage 5 were
each **audited and ruled on** rather than bounced upstream — the gate and the code reviewer both
confirmed the developer's minimal resolutions were proportionate, and one alleged drift (an `02_`
line-count anchor) proved not to be a drift at all. The 3-consecutive-rollback stop was never
approached.

## Final `verify_all` result: **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**

**Measured after archive. FAIL is 0 — the owner's gate — and WARN is 0 as well, matching a pristine
`HEAD` clone exactly (17 / 0 / 0 / 1). Zero delta.**

Getting there took two rulings rather than one, and both are worth recording:

1. **F.6 (active task docs ≤500 lines) ran WARN throughout the task**, naming this task's own
   `02_SOLUTION_DESIGN.md` (857) and later `04_DEVELOPMENT.md` (508). That was a **predicted,
   PM-accepted delta**, ruled at the gate (C-8): compacting a design doc mid-flight would have broken
   the section anchors that C-1..C-8, the E-1..E-18 edit list and T-1..T-10 all cite, and rule 70
   forbids mechanical truncation. `verify_all.sh:229-237` excludes `_archived/`, so it cleared on
   archive exactly as predicted.
2. **F.4 then fired, and this was NOT predicted.** `archive-task.sh` harvested the 3 insights below but
   did **not** auto-rotate the overflow, leaving `.harness/insight-index.md` at **32 lines against its
   30-line cap** — so the archive step traded one WARN for another instead of clearing to green. Rule
   70 §Caps says this file's overflow is `archive-task`'s job; it did not do it. The PM rotated two
   entries by hand into `docs/features/_archived/insight-history.md`, choosing them on rule 70's
   principle that *"cuts are made by removing what doesn't earn its line"* rather than by mechanical
   oldest-first: one is now enforced by a committed gate (T-11's `verify_all` B.2), the other is now a
   standing convention in `docs/dev-map.md`. The index sits at exactly 30.

**Follow-up filed by this observation:** `archive-task.sh`'s insight rotation is either missing or
silently failing. Every future task that harvests at the cap will hit the same WARN, and the next PM
will have to hand-rotate again. This is the second archive-script defect the project has found
(`insight-index.md:21` records the first: it harvests only the FIRST physical line of a `## Insight`
bullet). Natural owner: the next task touching `.harness/scripts/`.

## Baseline changes

- **Test count:** no committed suite existed and none is claimed. `.harness/scripts/baseline.json` still
  reads `test_count: 0` — deliberately not raised, following T-10's precedent, because asserting
  coverage the repo cannot re-run would be false. **However** — unlike the six tasks before it, this
  task's QA harness was **not discarded**: 13 files with a `run_all.sh`, 721 assertions, runnable
  verbatim, left in the task folder. That is the raw material R-4 has been waiting for.
- **Non-vacuity proven**, not assumed: key assertions were made to fail on demand (a `TUN_IFACE`
  perturbation flips the AC-16 comparison red; the AC-16 oracle was quoted from `02_` §3.6 rather than
  from the developer's code, so it cannot agree with the implementation by construction).

## Files changed

**Product — exactly the five permitted files (AC-26):**

```
 5 files changed, 573 insertions(+), 43 deletions(-)
 bin/sc            491 +  /  37 -
 README.md          31 +
 README.zh-CN.md    31 +
 CHANGELOG.md        2 +
 docs/dev-map.md    18 +  /   6 -
```

`install.sh`, `uninstall.sh` and `systemd/` are **byte-identical to HEAD** (`git diff --quiet` → 0,
re-confirmed at stage 6b).

**Pipeline artefacts, outside the product diff and declared here so the commit holds no surprise:**
`docs/features/sc-doctor/` (stage docs + `PM_LOG.md` + `qa-harness/`), `docs/tasks.md`, and two records
appended to `.harness/rejected-decisions.md` (`doctor-exit-status-always-zero`,
`shared-singbox-check-wrapper`). **Nothing was committed or pushed** — the owner owns delivery.

## What was actually built

`sc doctor` prints seven sections in a **causal** order that is pinned in one place
(`DOCTOR_SECTIONS`) and is the sole reader of that order: binary → rule-sets → config → service →
TUN → Clash API → egress IP. The owner's failure chain now reads off the screen top-to-bottom:
four `absent` rule-set rows, then a quoted `sing-box check` FATAL naming the missing rule-set, then
not-running + not-enabled-at-boot. Ordering the rule-sets **above** the config check reverses the
owner's listing order deliberately — the listing was a content list, and rule-set state is causally
upstream of the check that fails because of it.

Decisions worth surfacing:

- **Read-only was made process-wide, not `doctor`-local.** `main()` used to call `_init_files()` and
  `_resolve_clash_port()` *before* dispatch, so `sc doctor` on a wrecked host would have **created the
  very directory whose emptiness is the diagnosis** and persisted an invented Clash port. The init
  block now sits below `parse_args()` behind an `if/else`, and the default arm is today's behaviour
  verbatim — so a forgotten opt-out can only ever produce "a new read-only command wrote files", never
  "an existing command lost its initialisation".
- **Exit codes: 0 all OK, 1 any PROBLEM, 2 no PROBLEM but any UNKNOWN.** Two-value 0/non-zero was
  rejected because it must fold UNKNOWN into one side and *both* foldings lie on real hosts (no init
  system; no persisted port).
- **Reuse held.** Rule-set health comes through `ruleset_states()` — and `ruleset_report()` is *defined
  as* `_status_view(ruleset_states())`, so `doctor` and config generation stand on the same call. Size
  comes from the byte counter inside the one existing reader; `st_size` appears nowhere on the graph.
  `sc status` is byte-identical in both languages.

## Outstanding risks and open rows

1. **DEF-2 (MINOR, shipping open).** A **hung** (not refused) Clash port makes a read-phase
   `socket.timeout` escape `clash_api()` to the driver backstop, so S6 prints one
   `[UNKNOWN] Clash API: this check could not run: timed out` instead of the designed port row plus a
   PROBLEM row — the reader loses the port number on a firewalled host. Predicted by the gate as F-12
   and ruled "acceptable, not a bug to chase" **before** code was written; the report stays complete
   (FR-9 holds) and refused ports behave exactly as designed. Natural owner: the next task touching
   `clash_api()`'s exception surface.
2. **AC-5's live half and AC-6 on the *installed* command are NOT discharged.** This host's NOPASSWD
   sudo is scoped to `/usr/local/bin/sc`, which is an **older build with no `doctor`**, and general
   `sudo` needs a password — so the live-tree run never reached `sing-box check` on the real config
   (EACCES at S3) and `config.json`/`nodes.json` sha256 could not be computed. The read-only guarantee
   is proven structurally (a full call-graph enumeration at stage 5) and behaviourally on fixtures, but
   **one run of the installed binary as root remains owed.** Do it after installing this build.
3. **T-12 (out of scope, verified harmless here).** The installed `/usr/local/bin/sc` has diverged from
   the repo (`query_type: [28, 64, 65]` vs `[64, 65]`). Measured, not assumed: `query_type` lives in
   `generate_config()`'s DNS block, which `doctor` never calls, and sing-box 1.13.15 accepts both
   shapes identically (`rc=0`, empty output). **No doctor probe is affected.**
4. **The F.6 doc-size WARN** clears on archive (see above).
5. **`baseline.json` still reads `test_count: 0`** (pool row R-4) — but a real, re-runnable harness now
   exists for the first time. Promoting `docs/features/sc-doctor/qa-harness/` into a committed suite
   wired to `verify_all` B.3 is the cheapest way to finally close R-4; deliberately **not** done here,
   because it is outside this task's five-file scope.
6. **`_init_files()` hard-codes `/var/lib/sing-box`** (`bin/sc:309`) unlike every other path, so a
   redirected-paths harness driving a **non-doctor** command still touches the real `/var/lib`. Not
   triggered by `doctor` (which never calls it), but it is a live trap for the next task's harness.

## A note on the live service

The owner restarted `sing-box` by hand from another terminal mid-task (`pts/4`,
`PWD=/home/alan/Programs/NFBY_CMS`, `sc status` / `update-rules` / `reload` / `sed -i` at 10:06), so the
witness moved from `MainPID=2500438` / `Fri 2026-07-31 17:04:23 CST` to `MainPID=2887037` /
`Sat 2026-08-01 10:06:40 CST`. **`NRestarts=0`, and no pipeline stage caused it.** Every stage read the
witness with `systemctl show -p MainPID -p ActiveEnterTimestamp` — never `is-active`, which prints
`active` on both sides of a restart and would have passed during the very incident that rule exists to
catch — and every reading within every stage was identical before and after. Every harness and every
throwaway script asserted the auto-elevate neutralisation *before* executing the module, closing the
T-02 gap where the guard bound the QA harness but not a scratch file.

## Next steps for the user

1. Review the uncommitted diff and commit/push at your discretion — nothing was committed.
2. Install this build, then run `sc doctor` once as root to discharge risk 2 above.
3. Consider promoting `qa-harness/` to a committed suite (risk 5) — it would close R-4 and turn
   `verify_all` B.3 from a permanent SKIP into a real gate.

## Insight

- 2026-08-01 · sing-box colours its `check` output unconditionally, even with `stdout=PIPE`, so stripping the lone `0x1B` byte leaves the literal residue `[31mFATAL[0m` on screen — only removing the COMPLETE CSI sequence yields a pasteable line, and a fake-checker fixture cannot reveal this · evidence: sc-doctor
- 2026-08-01 · `verify_all` E.6 matches the heading regex `^##\s+Adversarial\s+tests`, so a *numbered* heading such as `## 3. Adversarial tests` makes E.6 FAIL rather than SKIP — a self-inflicted red that costs a debug cycle in every task whose QA numbers its sections · evidence: sc-doctor
- 2026-08-01 · `_init_files()` hard-codes `/var/lib/sing-box` (`bin/sc:309`) while every other path is a module-level constant a harness can repoint, so a redirected-paths harness driving any non-doctor command still writes to the real `/var/lib` · evidence: sc-doctor
