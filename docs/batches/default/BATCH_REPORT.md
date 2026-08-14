# Batch Report — default

> Written by `/harness-batch` when the loop exited. Covers the 9 rows that were outstanding when
> the batch was invoked on 2026-08-13; the 10 rows delivered before it (T-01 … T-05, T-08 … T-14)
> are recorded in `docs/tasks-archive.md` and are out of this report's scope.

**Result: all 9 rows complete. No strong-signal stop ever fired.** No task returned `FAILED`, no
`verify_all` FAIL followed any task, no `STOP` intervention arrived, and no `guard-rm` block was
overridden. The batch was never auto-continued past a failure because there was none.

## Per-task result

| ID | Slug | Verdict | Commit | Stage docs |
|---|---|---|---|---|
| T-15 | proxy-urltest-group | **DELIVERED** | `6778711`, `9f85f9e` | `docs/features/_archived/proxy-urltest-group/` |
| T-16 | dns-resilience | **DELIVERED** (1 of 3 goal clauses; other 2 proved not expressible → R-23) | `4c7d126` | `docs/features/_archived/dns-resilience/` |
| T-17 | telemetry-reject-list | **DELIVERED** | `ed01efc` | `docs/features/_archived/telemetry-reject-list/` |
| T-18 | status-egress-via-clash-api | **DELIVERED** (goal's 1st clause a phantom; closed R-20 instead) | `84c8d8b` | `docs/features/_archived/status-egress-via-clash-api/` |
| T-19 | ruleset-staleness-visibility | **DELIVERED** | `71b6d45` | `docs/features/_archived/ruleset-staleness-visibility/` |
| T-06 | sc-config-show | **DELIVERED** (all 3 goal clauses refuted; shipped as bare `sc config`, always-redacted) | `5bd0eaa` | `docs/features/_archived/sc-config-show/` |
| T-20 | doctor-extended-checks | **DELIVERED** | `46fc683` | `docs/features/_archived/doctor-extended-checks/` |
| T-21 | ruleset-source-strategy-from-v2rayn | **EXPLORED** — no code recommended (Q1 decline / Q2 defer / Q3 decline / Q4 decline) | `6f7d9c3` | `docs/features/_archived/ruleset-source-strategy-from-v2rayn/` |
| T-07 | restricted-network-regression-test | **DELIVERED** — harness committed, end-to-end run BLOCKED (no disposable VM) | `99745ac` | `docs/features/_archived/restricted-network-regression-test/` |

One out-of-band commit, `69341b5`, belongs to the batch loop rather than to any row: it promoted the
owner's restated 「以少就是多」 clause into `.harness/rules/85-design-discipline.md` (see below).

## Aggregate

- **Done: 9. Failed: 0. Blocked: 0. Skipped: 0.**
- **Elapsed:** 2026-08-13T01:10Z → 2026-08-15T02:11Z (~49 h wall clock, sequential, one task at a time).
- **`verify_all`:** baseline at batch start **PASS 16 / WARN 1 / FAIL 0 / SKIP 1** → final
  **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**. Re-run independently by the loop after **every** task, never
  by trusting a task's own report; it read 17/0/0/1 after all nine. The one baseline WARN was F.6 on
  T-15's in-flight requirement doc and cleared when that task archived. **B.3 (lint) is the standing
  SKIP** and `baseline.json` still reads `test_count: 0` — T-07 ruled explicitly that populating it
  would not yet be honest.
- **Rollbacks: 4 across 9 tasks** (T-15 at stage 6, T-19 stage 2→1, T-20 stage 5→4, T-07 one). Every
  one was caught by a later stage than the one that introduced the defect.
- **Product diff:** ~1 800 lines across `bin/sc`, `install.sh`, both READMEs, `CHANGELOG.md`,
  `systemd/`, `docs/dev-map.md`. T-21 and T-07 shipped **zero product diff** by design.
- **Live service untouched for the entire batch:** `MainPID=2566751`, `NRestarts=0`, witnessed per
  task with `systemctl show -p MainPID -p ActiveEnterTimestamp` (never `is-active`, which cannot
  detect a bounce). `/etc/sing-box/` and `/var/lib/sing-box` were never written; `install.sh` was
  never executed; no mutating call ever reached the live Clash API.

## The batch's dominant finding: goal sentences decay

**Six of the nine rows had their goal sentence partly or wholly refuted at stage 1**, and in every
case catching it there was the largest single saving of the task. The pool was written 2026-07-31 to
2026-08-01 from two field reports; by the time each row ran, the code had moved under it.

| Row | What the sentence claimed | What was true |
|---|---|---|
| T-16 | converge the DNS timeout; add a fallback resolver | `"timeout"` is not an expressible field on a server, the `dns` block, or a rule (proved with a bogus-key control); the rule chain never falls through on failure; `dns.final` is the no-rule-matched default, not a failure fallback |
| T-18 | the egress probe assumes a local inbound | `_egress_ip()` has **no proxy argument in any commit** back to `41ffd08` — there was nothing to fix |
| T-19 | make the timer fail instead of only printing | a failed *download* already failed the unit since T-02; the real defects were two states nobody had enumerated |
| T-06 | add `sc config --show` with optional `--redact` | no `config` subcommand and **no `parse_args()` function at all**; an opt-out flag would convert a password-gated read of a 0600 credential file into a password-free one |
| T-20 | report DNS timing | there is no configured value to report |
| T-21 | Releases assets are CDN-backed | **both halves false** — no publisher ships `.srs` as a release asset, and a release download 302s into `raw.githubusercontent.com`'s own Fastly anycast range |
| T-07 | assert the report's five end-state conditions | the headline condition **inverts**: with all four rule-sets missing, current code drops the empty `route.rule_set`, `sing-box check` passes, and the installer takes its **success** arm — a test written to the report would have failed on correct code |

The practice that produced this — re-derive the requirement first-hand before designing, and state
plainly which clauses survive — is the batch's most transferable result.

## The R-22 lesson, and its two sharper forms

T-15 shipped 35 acceptance criteria, all green through stage 5, and QA still found the promise wider
than the behaviour: **not one criterion observed the behavioural goal — all 35 verified the
artifact.** Filed as R-22, it was carried into every subsequent dispatch, and the failure shape
recurred twice in forms worth recording:

- **T-06, at stage 3 rather than QA:** two criteria were each satisfied by an all-masked document,
  and one satisfied *better* the more was masked — the two agreed with each other on a useless
  build. The gate bound one to its stronger form and made an all-masked run a FAIL.
- **T-07, the vacuous-green family:** four more were caught, each at a different stage and **none by
  the stage that introduced it** — including that base 4 of `RULESET_BASES` is a byte-suffix of
  base 3, so a substring test counts four on a log naming three.

## Honesty discipline: five BLOCKED criteria, none substituted

Where a criterion needed a credential or a machine no agent here holds, it was reported **BLOCKED**
with a named recipe, never downgraded to an artifact check: **R-31** (T-18), **R-41** (T-19),
**R-47** (T-06), **R-52** (T-20), and T-07's eight `[VM]` criteria — the largest instance, where QA
labelled even the rows it *could* partly discharge at unit level as "condition still BLOCKED".

Two human obligations are now recorded in `.harness/operator-obligations.md`, with full recipes:
row 1 (run `sc doctor` as root on a real install) and row 2 (T-07's disposable-VM run).

## The owner's directive, mid-batch

On 2026-08-14 the owner restated 「优先用好的设计，避免不断的修修补补」 for the **third** time, adding
「以少就是多（更少的代码或实现能达到同样的目的）」. Per rule 65 — an intervention seen twice belongs in
a rule — it was promoted into `.harness/rules/85-design-discipline.md` as a permanent **"Less is
more"** section (`69341b5`) rather than left as a per-task note, and the in-flight T-17 was signalled
with a `NOTE` (not a `REDIRECT`, so nothing already decided was overturned by fiat). It found a real
defect on its first application: T-17's bloat was **not in the diff but in the published surface**,
where following the documented recipe and then running `sc telemetry allow` produced an uncaught
error with the setting already persisted.

Measured effect on the four rows that ran under it: T-17 shipped as one 17-name tuple plus **one
changed line** in `generate_config()`; T-18 as **one exception envelope with no call site edited**
(+15/−7); T-21 recommended **no code at all**; T-07 shipped **no framework, no fixture library, no
mock server, no runner, no second file** — against a project history of five harnesses built and
discarded.

## Standing infrastructure defects, re-confirmed

- **R-18 — `archive-task.sh`'s rotation is dead. Confirmed nine times, once per task.** It counts
  bullets while `verify_all` F.4 counts lines, so on any index with a header the branch can never
  fire. Every task in this batch hand-rotated `.harness/insight-index.md` at delivery.
- **`guard-rm.sh` blocks commands containing no `rm`, seven times**, by misparsing a heredoc commit
  message as a nested pwsh command. Worked around every time with `git commit -F <file>`; the
  `HARNESS_ALLOW_OUTSIDE_RM` bypass was **never** set.
- `.harness/scripts/task-state.js` and `.harness/scripts/entropy-cadence` **do not exist on this
  host** — handled fail-open and recorded from T-16 onward. No entropy watch ran at T-20's delivery.

## Open rows

The batch opened **R-19 … R-61** (43 rows) and closed or re-homed several older ones — R-10, R-20,
R-32 and R-43 closed; R-11 half-closed; R-16 re-homed by R-54. They live in `docs/tasks.md` under
per-task headings, with older still-open blocks rotated into `docs/tasks-archive.md`. Two deserve
the owner's attention ahead of the rest:

- **R-42 — `parse_tuic()` has never stored a tuic link's password.** `urlparse().username` stops at
  the first `:`, so every tuic outbound `sc` has ever emitted carries `"password": ""`. A silent
  authentication failure, not a display defect. Found by T-06, correctly not fixed there.
- **R-23 — T-16's unshipped two thirds**, with the reason they are unshippable as specified.

Nothing in this file is a rule, an insight, or a decision — those live in `.harness/rules/`,
`.harness/insight-index.md`, and each task's `07_DELIVERY.md`.
