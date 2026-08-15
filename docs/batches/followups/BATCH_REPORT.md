# Batch Report — followups

> Written by `/harness-batch` when the loop exited. Covers the 7 rows derived from the ~40 open
> findings the `default` pool's nine deliveries left behind.

**Result: all 7 rows complete. No strong-signal stop ever fired.** No task returned `FAILED`, no
`verify_all` FAIL followed any task, no `STOP` intervention arrived, and the `HARNESS_ALLOW_OUTSIDE_RM`
bypass was never set despite `guard-rm.sh` blocking twelve commands containing no `rm`.

## Per-task result

| ID | Slug | Verdict | Commit | Rows closed |
|---|---|---|---|---|
| T-22 | share-url-userinfo-contract | **DELIVERED** | `cf164f9` | R-42 |
| T-23 | state-file-io-contract | **DELIVERED** | `2de1339` | R-17, R-25, R-27, R-29, R-62 |
| T-24 | override-error-envelope | **DELIVERED** | `6c034d6` | R-15, R-16, R-26, R-54 |
| T-25 | output-layer-contract | **DELIVERED** | `6d16caf` | R-19, R-33, R-34, R-38, R-40 |
| T-26 | doctor-rows-establish-their-fact | **DELIVERED** | `d849234` | R-24, R-48, R-49, R-50 |
| T-27 | harness-self-maintenance | **DELIVERED** | `55f39f0` | R-18, R-36, R-37 |
| T-28 | committed-test-suite | **DELIVERED** | `2ea5e16` | R-4, R-6, R-9, R-56, R-58, R-59, R-71, R-80 |

## Aggregate

- **Done: 7. Failed: 0. Blocked: 0. Skipped: 0.**
- **`verify_all`: PASS 17 / WARN 0 / FAIL 0 / SKIP 1 → PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0.**
  The two new steps are the pool's own product: **B.4** (`bin/sc` contract assertions) and **B.5**
  (restricted-network self-check). **B.3 (lint) remains the standing SKIP.** Re-measured
  independently by the loop after every task, never taken from a task's own report.
- **Rollbacks: 7 across 7 tasks** — and the striking fact is **how few were code**. T-22's two and
  T-23's two were criteria that could not detect what they claimed; **all three of T-24's were
  prose**, with `bin/sc` byte-identical from round 1 onward; T-25's one was a record defect; T-26's
  MAJOR was a published exit transition the build cannot produce; T-27's was a durability ruling
  written without opening the file `/harness-upgrade` actually copies.
- **Product diff: ~370 lines net across `bin/sc`** plus one new 449-line test artifact. Every row
  came in at or under the size its predecessor set.
- **Live service untouched for the entire pool:** `MainPID=2566751`, `NRestarts=0`,
  `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`, re-checked independently by the loop.
  `/etc/sing-box/` and `/var/lib/sing-box` never written; `is-active` never used as a witness.

## What "less is more" actually produced

The owner restated the directive on 2026-08-14 with the added clause 「以少就是多」, and it was
promoted into `.harness/rules/85-design-discipline.md` before this pool was authored. **The pool
itself is the first product of the rule**: rather than filing ~40 tasks for ~40 open rows, the rows
were grouped by cause into 7. Measured outcomes:

- **T-25** shipped a whole output-layer contract with **no new function at all** — top-level
  `def`/`class` count unchanged at 113.
- **T-27** shipped **8 executable added lines**, and *deleted* a per-kind routing table it had
  designed once it proved unnecessary.
- **T-26** was **net-negative** on one of its four rows: the fix for R-49 *removes* a second liveness
  opinion.
- **T-28**, the largest over-build risk in either pool, shipped **one file** — no framework, no
  fixture library, no runner, no directory, no dependency — against a project history of five
  harnesses built and discarded.
- **The gates enforced it rather than reciting it.** T-24's gate found the *rejected smaller* design
  covered a case the architect had conceded, and that the larger design's justifying band was
  **empty** when measured (deepcopy 498, `json.dumps` 996, `json.loads` 9997). T-25's gate re-priced
  the rejected route and found no smaller construct exists on the 3.6 floor. T-26's gate found the
  design's stated rejection *mechanism* wrong while upholding the ruling.

## The finding that matters most: fixes that made claims smaller

Three closures did **not** strengthen a check — they narrowed a promise, and a future reader must not
mistake them for stronger guarantees:

- **R-48** closed with the DNS probe **byte-for-byte unchanged**. A read-only probe established that
  no cache-free lookup exists through the Clash route and that `/dns/query` carries no cache-hit
  indicator — so the stronger claim was **never available to make**. Three sentences moved; the
  shipped guarantee is **weaker** than the old wording implied, and now true.
- **R-19's stated cause was wrong**: in English *every* `t()` lookup is a designed miss and the key
  **is** the rendering, so no `en` table and no change to `t()` were needed.
- **R-29's own prescribed fix was insufficient**: `except (OSError, ValueError, TypeError)` misses the
  `AttributeError` two of its four named readers actually raise, so the **is-a-dict check, not the
  catch tuple**, closes the class. Its `"telemetry"` example does not raise at all — it returns
  `auto` by a legal substring test, a silently wrong answer worse than the traceback filed against it.

## Safety: one near-miss, caught

**T-25's QA wrote a loader that re-exec'd the installed `/usr/local/bin/sc` under password-less
sudo** — the exact hazard `.harness/insight-index.md` line 2 warns about. It was caught **before any
write**, the run was declared void, all five cases were re-taken on the mandated recipe reproducing
byte-for-byte, and the reviewer ruled it write-free on evidence independent of the harness's own
witness. Filed as **R-78**; the live-service witness confirms no mutation occurred.

**T-28 then made that hazard permanent-or-eliminated, and got it right at the third attempt.** Its
suite means `bin/sc` is imported on every future `verify_all` run, forever. The safety spine was
strengthened at three stages, **none of them the stage that introduced the weakness**: the gate
refuted an inherited `docs/dev-map.md` claim that the shim "fails closed if `geteuid` moves" (it
copies the real `os.__dict__`, so `os.execvp` stays live); the reviewer caught that the first fix was
**a name prefix standing in for a capability**; and QA's control settled it by measurement — under
the prefix-only filter a `bin/sc` whose elevate guard called `os.popen` **actually started a shell**
while the suite reported `14 defined, 14 run, 14 passed, exit 0`.

## Two long-standing rows closed

- **R-18**, confirmed **fifteen times** — once per delivery — was closed by T-27 and **proved rather
  than argued**: its own archive run printed `Rotating 4 old insight(s)` and left the index at exactly
  30 lines, the first of seventeen deliveries needing no hand rotation. T-28 confirmed it a second
  time independently (`Rotating 3`).
- **R-9**, deferred **five times** on legitimate grounds each time, was closed by T-28 — with
  `baseline.json` finally honest **because a program reads it** (`test_count` 0 → 14 as a floor,
  proved wet: a 13-assertion suite is green on its own while B.4 FAILs `floor is 14`).

## Still owed to the owner

- **Install the new `bin/sc` and run `sc reload`** (standing **R-30**). Everything this pool and the
  previous one shipped reaches the live host no other way.
- **Operator obligations id 1–5** in `.harness/operator-obligations.md`, each with a full recipe.
  Notably **id 3**: a real `sing-box check` *accepts* an empty tuic password, so no config-level test
  can substitute for a live handshake — and existing tuic/trojan/hy2 nodes must be repaired **by hand**
  (`sc rm` + `sc add`), because `sc reload` cannot: the share URL is never persisted.
- **R-87** — whether to adopt the upstream `archive-task.sh` refresh. It fixes four things this copy
  still gets wrong but **does not** fix R-18, and cannot be taken selectively.
- Open rows now run to **R-96**, in `docs/tasks.md` and `docs/tasks-archive.md`.
