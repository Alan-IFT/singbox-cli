# Batch Report — closeout

> Written by `/harness-batch` when the loop exited. Four rows, derived from R-62 … R-96 by triaging
> on cause **before** filing. This pool closes a three-pool programme: `default` (9 rows),
> `followups` (7), `closeout` (4) — **20 tasks**.

**Result: all 4 rows complete. No strong-signal stop ever fired** in this pool or in either of the
previous two.

## Per-task result

| ID | Slug | Verdict | Commit | Rows closed |
|---|---|---|---|---|
| T-29 | state-file-contract-completion | **DELIVERED** | `fc634e3` | R-65, R-66, R-76 |
| T-30 | validate-before-baseline | **DELIVERED** | `2a6b6e8` | R-70, R-73 |
| T-31 | suite-guarantee-boundaries | **DELIVERED** | `179db66`, `103e58f` | R-93, R-95, R-96, R-102(a), R-104 |
| T-32 | record-accuracy-sweep | **DELIVERED** | `9fd835c` | 7 of 11 prose rows (3 were already discharged) |

## Aggregate

- **Done: 4. Failed: 0. Blocked: 0. Skipped: 0.**
- **`verify_all`: PASS 19 → PASS 20 / WARN 0 / FAIL 0 / SKIP 1, exit 0.** The added step is **B.6**
  ("assertion floor never below its last committed value"), this pool's own product. `test_count`
  rose 14 → 17 → 18 as contracts were pinned. **B.3 (lint) remains the standing SKIP.**
- **Rollbacks: 6 across 4 tasks**, and the pattern from the previous pools held — most were criteria
  or record defects rather than code. Two are worth naming: T-30's stage 5 found
  `tempfile.mkstemp()` **outside** the guarded region, so BC-11 was violated **by that task's own
  fix**, and it routed to the *architect* rather than the developer because the code was faithful and
  the missing statement was one the developer had been forbidden to invent. T-32's second rollback
  was the **PM's own, over an already-APPROVED verdict**, because the round had shipped a false
  enumeration *inside* `.harness/rejected-decisions.md` — the record declining a mechanism for
  catching false enumerations.

## The two findings that matter most

**1. A silent, severe defect was closed by reordering three calls.** T-24 had discovered, while
refuting its own brief, that `sing-box check` runs **after** `_write_private()` and **after** the
drift digest is baselined — so the loudness everyone relied on protects the *running service*, not
the *stored configuration*. T-30 established the consequence first-hand and it is not cosmetic: the
rejected document stays at `/etc/sing-box/config.json`, the unit reads it at every start under
`Restart=on-failure`, and the weekly timer restarts **without regenerating** — **an unattended
outage up to a week after the error**. Because the harm is in the write rather than the record, the
fix is an ordering: **+21 net executable lines**, no validation pipeline.

**2. The committed suite could not have stopped what it claimed to stop.** T-28's reviewer had
already caught one version of this — *a name prefix standing in for a capability*. T-31 measured the
delivered version before designing anything and found the gap **larger than filed**:
`subprocess.call/Popen/run` **and** `ctypes.CDLL(None).system` each started a process and left a
marker **while the suite ran on into its assertion phase**. Then QA found the task's own defect one
level down (CRITICAL): `os._execvpe` / `os._spawnvef` are process-start names present in `dir(os)`
**today** that match no prefix, and a subject calling `os._execvpe` **replaced the loading
interpreter with `touch`** — exit 0, no summary. The `subprocess` half is now refused in **three
lines**; the enumeration half closed **as prose, with no name added to the tuple**.

## What "less is more" produced in this pool

- **T-29** closed R-65 — the only data-loss row — at **zero code**, by ruling: an unusable
  `settings.json` blocks every run that *writes* and blocks no run that only *reports*.
- **T-31** closed **R-95 and R-96 with a written boundary at zero code**, on the reasoning that a
  limit which is real, understood and written where a reader meets it beats machinery that pretends
  to cover it. Its executable diff was **31 lines against a cap of 40**, with `bin/sc` byte-identical.
- **T-32 added no mechanism at all**, arguing it against T-27's and T-31's precedents at three
  separate stages. Eleven sentences were corrected; no linter, no doc-lint step, no template.
- **Two whole categories were declined before any work started** — `archive-task.sh`'s three internal
  defects (blocked on the owner's R-87 decision about a 425-line upstream rewrite of the very
  function they live in) and R-86. Declining them *is* the rule being applied.

## Where the record corrected itself

This pool kept finding that **filed rows were wrong about their own repairs**, which is the strongest
argument for re-verifying rather than inheriting:

- **R-76** named one site; the family was **six**.
- **R-93**'s gap was `subprocess` and `ctypes`, not a missing name.
- **R-83**'s "four directives" is **three**. **R-85**'s filed replacement wording is false, because
  `DOCTOR_EXIT` maps OK/UNKNOWN/PROBLEM to 0/2/1 — **a label set, not a scale**, so a host can move
  2 → 1 *downward*. **R-94**'s population was five clauses, not three.
- **R-77, R-78, R-84** were already discharged by T-28 and were edited nowhere.

## The honest negative result

T-32's QA reported **AC-19 itself NOT-DISCRIMINATING**. A mutant inverting the shipped AAAA advice —
false of the code at all three sites — produces a **byte-identical** verdict from B.4, `py_compile`,
the AST identity and a full `verify_all`. Nothing mechanical could see it; three independent
first-hand re-derivations could. That is the boundary of what a committed suite buys, measured rather
than assumed, and it is why **R-74 was ruled open** rather than closed: it has no closure predicate,
and closing it would trade eleven corrected instances for a claim about future sentences.

## The invariant that broke, and why that is good news

`MainPID=2566751` was asserted in **all 20 dispatches** of this programme. It went false during
T-32. The cause, verified independently by the batch loop and read-only:
`sing-box-rules-update.timer` fired at **00:44:43** (`Result=success`, `ExecMainStatus=0`), and the
service re-entered at **00:44:47** — `NRestarts=0`, no reboot, `/etc/sing-box` mtime unmoved. Nothing
in any pipeline touched the host.

**This is the first observed run of the weekly timer T-09 repaired.** T-09's QA had recorded that the
unit had *never* run on this host — timer disabled, no stamp, empty journal — which made its "~100%
of hosts are in `failed`" premise false. The invariant was guaranteed to break at a cadence this
project ships, and its breaking is evidence the fix works.

## Still owed to the owner

- **Install the new `bin/sc` and run `sc reload`** (standing **R-30**). Twenty tasks reach the live
  host no other way — and the timer above ran the *installed* build, not the delivered one.
- **Operator obligations id 1–6** in `.harness/operator-obligations.md`, each with a full recipe.
  **id 3 is the sharpest**: a real `sing-box check` *accepts* an empty tuic password, so no
  config-level test can substitute for a live handshake, and existing tuic/trojan/hy2 nodes must be
  repaired **by hand** (`sc rm` + `sc add`) — `sc reload` cannot, because the share URL is never
  persisted.
- **R-87** — whether to adopt harness-kit 0.47.0's `archive-task.sh` refresh. It fixes four things
  this copy still gets wrong, **does not** fix R-18 (closed locally by T-27, confirmed working six
  times since), and cannot be taken selectively. **R-89, R-90 and R-92 are deliberately parked behind
  this decision.**
- Open rows now run to **R-117**, in `docs/tasks.md` and `docs/tasks-archive.md`.
