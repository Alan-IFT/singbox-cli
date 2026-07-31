# Delivery Summary — T-10 `ruleset-update-no-needless-restart`

- **Task**: T-10 · `ruleset-update-no-needless-restart` — stop `sc update-rules` restarting
  sing-box when no rule-set's bytes actually changed on disk.
- **Mode**: full (stages 1 → 7)
- **Decision mode**: deferred-human, `defer, do not ask` — standing authority granted by the
  owner. Every judgment call was resolved against `.harness/decision-rubric.md` and recorded.
  **No `BLOCKED: NEEDS-HUMAN` was raised**; no safety red line was reached.

## The defect, and why it mattered now

`bin/sc:1141-1143` (pre-change) ended `cmd_update_rules` with:

```python
if not applied and is_running():
    print("\n" + t("→ Restarting sing-box ..."))
    restart_service()
```

`applied` was True only when a rule-set became newly *usable*. A routine refresh that
re-downloaded four byte-identical files therefore took the `not applied` branch and restarted
the proxy for nothing — dropping every live connection, including the SSH session of anyone
administering the box remotely. T-09 (0bb2373) had just repaired the weekly timer's `ExecStart`,
so a unit that had **never run** was about to start firing every Monday 00:00–01:00.

Stage 1 found the blast radius is wider than the brief stated: OpenRC hosts run the same command
from `/etc/periodic/<period>/singbox-update-rules` (`bin/sc:1217` pre-change), so this was never
systemd-only.

## Stages traversed

| # | Stage | Agent | Verdict | Date |
|---|---|---|---|---|
| 1 | Requirement analysis | requirement-analyst | `READY` — 16 behaviours, 20 BCs, 25 ACs, 5 NFRs, 9 decisions | 2026-07-31 |
| 2 | Solution design | solution-architect | `READY` — D-1 (hot-apply vs restart) closed on evidence | 2026-07-31 |
| 3 | Gate review | gate-reviewer | `APPROVED FOR DEVELOPMENT` — 0 BLOCKER / 3 MAJOR / 5 MEDIUM / 6 LOW, conditions C-1…C-11 binding | 2026-07-31 |
| 3b | Design doc fix (C-1) | solution-architect | Compacted 559 → 495 lines + 2 accuracy corrections | 2026-07-31 |
| 4 | Development | developer | `READY FOR REVIEW` — `verify_all` 16/0/0/2, delta 0 | 2026-07-31 |
| 5 | Code review | code-reviewer | `APPROVED` — 0 CRITICAL / 0 MAJOR / 5 MINOR / 2 NIT, **no code change requested** | 2026-07-31 |
| 5b | Doc fix (M-1, N-1, M-3) | developer | Citations corrected, residual completed; `04` 437 → 497 lines | 2026-08-01 |
| 6 | QA | qa-tester | `PASS WITH NOTES` — 522 assertions, 0 failures, **0 product defects** | 2026-08-01 |
| 7 | Delivery | PM | this document | 2026-08-01 |

## Rollbacks: 0

No stage was rolled back for a defect. Two document-only corrections were routed to their
owning agents and are **not** rollbacks — neither changed a decision, a behaviour or a line of
shipped code:

- **3b** — the gate found `02_SOLUTION_DESIGN.md` at 559 lines against `verify_all` F.6's 500-line
  cap. Because *any* WARN makes `verify_all` exit 1, leaving it would have failed the developer's
  declare-done gate through no fault of theirs. Routed to the architect (rule 70 makes doc size
  the author's responsibility) and handled **before** stage 4 rather than the permitted "before
  stage 6", so the developer would not be implementing from a document being edited underneath
  them.
- **5b** — the reviewer found three stale post-change line citations in `04_DEVELOPMENT.md` and
  one overreaching claim. Routed to the developer as a document fix.

## What was decided, and how

### D-1 — hot-apply vs restart: **restart, only on real content change**

This was the task's central open question. `.harness/rules/50-singbox-cli.md` records "prefer
hot-apply" as a project convention and both READMEs advertise it, so the brief required the
answer be *established*, not assumed. It was closed on evidence, by static probe of the installed
`/usr/local/bin/sing-box` (a Go binary retains string literals and pclntab source paths through
`-s -w`), reproduced independently at stage 3:

- **Clash API cannot apply a local `.srs`.** `/providers/rules` is present (1 match) but
  **neither `ruleCount` nor `vehicleType`** appears anywhere in the binary (0 matches each) — a
  Clash-Meta rule-provider response cannot be serialised without those field names, so the route
  is a compatibility stub. T-02's E-7 is now confirmed by evidence rather than inherited.
- **SIGHUP reload exists but is not usable here.** `systemd/sing-box.service:10` has
  `ExecReload=/bin/kill -HUP $MAINPID`, but it recreates the whole box instance, and the OpenRC
  service (`install.sh:412-431`) defines no `reload()` at all — so it fails B-12's
  "no systemd-only mechanism" rule.
- **sing-box *does* watch local rule-sets** (`route/rule/rule_set_local.go`, `sagernet/fswatch`,
  literals `watch rule-set file` / `reload rule-set `) — but we cannot rely on it: our own
  `generate_config()` emits `"log": {"level": "warn"}` (`bin/sc:746`), so no Info-level success
  line is ever written on this project's hosts; a journal oracle has no OpenRC counterpart and
  `sc` contains no log-reading code; and whether fswatch survives `tmp.replace(target)` (inode vs
  dirent) is undetermined for *our* write pattern. Declining to claim a reload works was the
  point — a wrong "reload works" claim is worse than an honest restart.

Recorded as a **deferred decline**, not a rejection, in `.harness/rejected-decisions.md`
(`trust-singbox-fswatch-ruleset-reload`) with an unblock path requiring a disposable host.

**Accuracy correction made mid-pipeline:** stage 2 originally argued "sing-box logs nothing on a
successful rule-set reload, so there is no evidence channel at all". Stage 3 re-ran the probes,
confirmed every one, and found `updated rule-set ` and `rule-set updated` *do* exist in the
binary — so the honest statement is that a success literal exists but cannot be attributed to
the local-file path from strings alone. The conclusion survived on the three stronger grounds
above; the overclaim was corrected in the design, in the decline record, and forbidden from
reappearing downstream (condition C-9, verified clean by grep at stage 5).

### D-2 — `gained` and `changed` are two facts from **one** on-disk query

T-02 already owned "is this rule-set usable?" (`srs_reject_reason` → `ruleset_status` →
`ruleset_report` → `usable_tags`). Content-changed is a different question, and rule 85 warns
equally against bolting on a parallel notion and against over-abstracting. The resolution:
`ruleset_state(path) -> (status, digest)` reads the file **once** and returns both facts;
`ruleset_report()` keeps its exact T-02 contract as a status-only view, so `generate_config()`
and `usable_tags()` were not touched. A separate `ruleset_digest()` would have re-implemented the
symlink / non-regular-file / EPERM branch a second time — the same seam that made T-02's
`path.exists()` insufficient.

This yields the invariant **`gained ⊆ changed`**, which makes "exactly one apply per run"
*structural* rather than disciplinary: `restart_service()` now has exactly one call site outside
`reload_or_restart()`, under `if changed and CFG_PATH.exists()`. The gate attacked the invariant
with six boundary cases (externally-fixed permissions, a completed partial write, a replaced
bad-magic body, a 0-byte file, a directory/fifo, mid-run constant change) and it held —
conditional on the digest contract, which became condition C-5 and was then verified in the
**body** of the code at stage 5 and by 62 fixture assertions at stage 6.

### The `is-active` finding — the most consequential thing this task learned

The mandatory safety constraint required `systemctl is-active sing-box` to read the same before
and after any test run. The gate reviewer ruled that check **cannot detect what it exists to
detect**: `is-active` prints `active` on both sides of a restart, so the criterion written
*because* T-02 bounced the owner's live sing-box **would have passed during the T-02 incident**.
Replaced by process identity (condition C-2), and both the developer and QA reported it:

```
BEFORE 2026-08-01T00:11:39+08:00        AFTER 2026-08-01T00:27:48+08:00
is-active: active                       is-active: active
MainPID=2500438                         MainPID=2500438
ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST   (identical)
```

Identical PID *and* identical activation timestamp across the entire verification stage — the
live service was provably never restarted. `/etc/sing-box` listings identical,
`find /etc/sing-box -newermt <stage-start>` empty, PATH-shim marker absent on all 10 runs, euid
1000 throughout, `/usr/local/bin/sc` never executed.

The scratch-script clause (the actual T-02 gap) was made mechanical rather than honour-system:
all module loading goes through one `qalib.load_sc()` that hard-fails if `bin/sc`'s auto-elevate
block stops matching, and `run.sh` greps the directory for `import qalib` before running anything
and refuses at euid 0. QA also reported a live hazard still on disk: the shared session scratchpad
root contains `main_sc.py:54`, an un-neutralised copy of the auto-elevate block left by an earlier
task. It was neither run nor used as a pattern.

## Final verify_all result: **PASS**

```
PASS: 16   WARN: 0   FAIL: 0   SKIP: 2
```

Re-run independently at delivery. QA rebuilt a pristine `HEAD` (`10fa8e8`) clone rather than
trusting the developer's numbers: **per-check diff IDENTICAL, delta 0**. The two SKIPs (B.2
tests, B.3 lint) are the project's standing state, not introduced here. F.6 PASS — every active
task doc is under the 500-line cap.

## Baseline changes

**None.** `.harness/scripts/baseline.json` and `verify_all.sh` are untouched, and B.2 stays SKIP.
No test tree was committed — decision D-8, upheld explicitly by the gate reviewer, which ruled
that wiring a committed suite requires a runner command, a rule-50 `Test:` line, a `tests/`
layout and a `baseline.json` `test_count`, all of which belong to T-07; a suite nobody runs is
worse than none, because the next task believes it is covered. In exchange, condition C-11
required the QA harness to be pasted **complete and runnable verbatim** — it is, at
`docs/features/ruleset-update-no-needless-restart/QA_HARNESS_T10.md` (2257 lines; F.6 matches only
`0[1-7]_*.md` and `PM_LOG.md`, so no gate is bypassed and nothing is elided). T-07 inherits it.

## Evidence that the defect is actually gone

QA's **negative control** — the same fixture, both sides:

```
HEAD 10fa8e8, identical no-op fixture : ['is_running', 'restart_service']
working tree, identical fixture       : []
```

Plus four injected mutants, all killed: restoring the unconditional tail; comparing size instead
of content (killed **only** by AC-5's equal-size-different-content case); "tidying" the explicit
`None` arms into `!=`; dropping the `usable in after` filter. In a 10-way concurrent race, HEAD
applies 10 times and the change applies 1.

**522 assertions, 0 failures**, across 8 scripts QA wrote itself from `01` §6/§7. The four red
assertions seen during the stage were all in QA's own test code and are documented as such.

## Files changed

**Product diff — 3 files, +147 / −31:**

```
 bin/sc          | 169 ++++++++++++++++++++++++++++++++++++++++++++++----------
 CHANGELOG.md    |   3 +-
 docs/dev-map.md |   6 +-
```

- `bin/sc` +141/−28 — `import hashlib` (`:5`, the only import added, stdlib); three new
  `TRANSLATIONS["zh"]` keys (`:143-145`); `ruleset_state()` (`:516-558`), `ruleset_status()`
  (`:561-573`), `ruleset_states()` (`:575-588`), `_status_view()` (`:591-596`),
  `ruleset_report()` (`:599-605`, contract unchanged), `changed_usable_tags()` (`:608-636`);
  rewritten apply tail (`:1222-1257`) with R6's in-code comment naming the T-10 defect
  immediately above the single `restart_service()` call site. The download loop, the mirror /
  validation logic, every timeout constant, `install.sh`, `systemd/*` and both READMEs are
  untouched.
- `CHANGELOG.md` — `:15`'s false claim that the command "在 sing-box 正在运行时会重启 sing-box
  （连接会中断几秒）" corrected, plus one new `修复` bullet. Shipping the fix while leaving that
  sentence in place would have published a statement the code no longer makes true.
- `docs/dev-map.md` — the rule-set rows updated so the next task calls `ruleset_state()` /
  `changed_usable_tags()` instead of building a second content comparator.

**Harness / context artifacts also dirty** (not product code, all written by pipeline stages):
`CONTEXT.md` (glossary, written at stage 1, mandated by `01` §3),
`.harness/rejected-decisions.md` (two decline records), `docs/tasks.md`,
`docs/batches/default/BATCH_PLAN.md`, and this task folder.

**Nothing was committed or pushed.** The owner owns delivery, as instructed. `HEAD` is still
`10fa8e8`.

## Outstanding risks and honest gaps

**Recorded residuals** (all in `04` §"Residuals", none blocking):

1. **F-11 / BC-9 ordering delta.** Today's `sys.exit` at `:1140` runs *before* the unconditional
   restart, so a run with any failed rule-set never restarted. The apply block now precedes the
   exit (required by B-14/BC-9 to preserve T-02's recovery). So "2 changed + 2 failed" now
   restarts where today it does not — requirement-sanctioned, strictly narrower than today's
   behaviour on successful runs, and QA measured it from both sides.
2. **Restart *during* a loss.** The `usable in after` filter prevents a restart *caused by* a
   lost rule-set, not a restart *while* one is missing: if A is lost externally while B changes,
   the run restarts into a config that still references A. Today's code restarts unconditionally
   in the same situation, so this is not a regression except in case (1). The cheap future shape
   (skip the apply when the usable set *shrank*) needs no new data — both snapshots already carry
   it. Deliberately not widened; no AC asks for it.
3. **Widened `generate_config()` failure surface, both halves.** A file readable at byte 0 but
   faulting at byte 500 000 was `usable` before and is `unreadable` now — QA measured it: **KEPT
   by HEAD, DROPPED by the change**. Arguably more truthful, but it is a behaviour change on a
   T-02-owned path. The size half: `ruleset_state()` streams to EOF with no ceiling, so a
   pathologically large regular `.srs` costs a full sha256 on every `sc use / add / rm / reload`.
   Real rule-sets total ~480 KB, and `if not path.is_file()` (`:544`) already excludes
   fifos/devices, so this is a robustness edge, not a happy-path regression. Not capped — a cap
   would introduce a "too big to judge" verdict no AC or design section defines.
4. **NFR-3's literal wording is not met on the recovery path.** A `gained` run opens each file
   **three** times (QA measured `{'geoip-cn.srs': 3, …}`), not "at most twice"; the third pass is
   `generate_config()`'s own `ruleset_report()`, inherited from T-02. `cmd_update_rules` still
   takes exactly two snapshots. NFR-3's real intent (no network, no new timeout, bounded chunks,
   O(1) memory) is met.
5. **`restart_service()` uses `check=False`**, so the outcome line's "restarted" means *issued*,
   not *succeeded* (pre-existing, unchanged).
6. **`bin/sc:1258`** has one blank line before `def cmd_update_interval` where the file's
   convention is two (PEP 8 E302). Verified **pre-existing** at `HEAD:bin/sc:1145`, not introduced
   by this hunk. B.3 lint is SKIP so no gate catches it.
7. **`ruleset_status()` is caller-less**, kept on merit (one-line delegation to a function every
   in-tree caller exercises, named in `dev-map.md`, plausibly called by T-05). If T-05 lands
   without it, delete it then — two lines.

**Could not be verified, and is not implied to have been** (QA stated each explicitly): a real
OpenRC host; a real Python 3.6 interpreter; the weekly timer firing end to end; a genuine
hardware IO fault (mid-read `OSError` is injected at the file-object boundary); `install.sh` end
to end; and whether sing-box's fswatch survives `tmp.replace()` — that last one is the NFR-1 red
line and was deliberately not attempted on the owner's live host. AC-19 (non-disruptive fallback)
is **not-applicable by design**, with its reason recorded, not untested.

## Next steps for the owner

1. Review the product diff (`bin/sc`, `CHANGELOG.md`, `docs/dev-map.md`) and commit — the
   pipeline deliberately did not.
2. Note the harness/context files in the same working tree (`CONTEXT.md`,
   `.harness/rejected-decisions.md`, `docs/tasks.md`, `docs/batches/default/BATCH_PLAN.md`); they
   were written by pipeline stages, not by hand.
3. Consider deleting `main_sc.py` from the shared session scratchpad root — it is an
   un-neutralised copy of `bin/sc`'s auto-elevate block and is the T-02 failure mode still
   physically present on disk.
4. Follow-up rows worth filing: the "skip the apply when the usable set shrank" refinement (2);
   the unbounded-size read (3); wiring `verify_all` B.2 so a committed suite can exist (T-07,
   which should inherit `QA_HARNESS_T10.md`); and the fswatch question, which needs a disposable
   host and would remove the restart entirely.

## Insight

- 2026-08-01 · `systemctl is-active` prints `active` on both sides of a restart, so a before/after `is-active` reading cannot detect a service bounce at all — the witness that does is `systemctl show -p MainPID -p ActiveEnterTimestamp`, and the `is-active` check written after T-02's live-restart incident would have passed during that very incident · evidence: ruleset-update-no-needless-restart
- 2026-08-01 · sing-box's Clash API cannot apply a local `.srs`: the installed binary contains the `/providers/rules` route string but neither `ruleCount` nor `vehicleType`, so the route is a compatibility stub and no rule-set hot-apply path exists through it · evidence: ruleset-update-no-needless-restart
- 2026-08-01 · sing-box does watch local rule-set files (`sagernet/fswatch`, literals `watch rule-set file` / `reload rule-set `), but `generate_config()` emits `"log": {"level": "warn"}`, so any Info-level success line is never written on this project's hosts — the watcher cannot be trusted because there is no channel to observe it working · evidence: ruleset-update-no-needless-restart
