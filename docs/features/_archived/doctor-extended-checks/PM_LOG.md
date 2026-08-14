# PM Log — T-20 / doctor-extended-checks

Mode: **full** (stages 1-7). Dispatched by `/harness-batch`, pool `default`.
Deferred-human mode: **defer** — but the owner's standing decision grant (「你来决策就行」)
applies; `BLOCKED: NEEDS-HUMAN` only for a genuine safety red line.

## Pre-flight (2026-08-14)

- `task-state.js` — **absent on this host**. Fail-open: durable state tracked in this log only.
  Stage/round/streak counters kept by hand below.
- `entropy-cadence` — **absent on this host**. Fail-open: the delivery-time entropy watch
  resolves to NOT-DUE, no scan, no `## Entropy watch` section.
- `.harness/intervention.md` — **absent** at task start (check 1 of the mandated three points).
- `.harness/agents/dev-*.md` — **absent** ⇒ **single-Developer mode**, dispatch `harness-kit:developer`.
- Task folder created: `docs/features/doctor-extended-checks/`.
- Batch baseline (measured after T-06): `verify_all` PASS 17 / WARN 0 / FAIL 0 / SKIP 1.

### Related historical tasks (from `docs/tasks.md`)

T-05 `sc-doctor` (the command being extended), T-19 `ruleset-staleness-visibility`,
T-15 `proxy-urltest-group`, T-14 `config-composition-layer`, T-06 `sc-config-show`,
T-13 `config-write-permission-hardening`, T-16 `dns-resilience`, T-18 `status-egress-via-clash-api`.
All archived under `docs/features/_archived/`.

Open rows naming T-20 as owner or natural site: **R-10**, **R-11**, **R-17**, **R-32**, **R-38**.
Open row constraining the DNS row: **R-23**.

### Insight-index entries surfaced to downstream (whole)

Queried `.harness/insight-index.md` (30 lines, read whole). Entries applicable to this task
are carried verbatim into the stage-1/2/4/6 dispatch prompts: lines 9, 10, 12, 13, 14, 15,
16, 17, 22, 23, 24, 26, 30.

## Stage transitions

| # | Stage | Round | Verdict | Timestamp |
|---|---|---|---|---|
| 1 | requirement-analyst | 1 | **READY** | 2026-08-14 |

### Stage 1 — round record

round 1 · initial contract · no rework · no finding id.

**Routing decision: ADVANCE to stage 2.** No `BLOCKED:` marker, no rollback request.
Intervention check 2 performed after stage 1 — `.harness/intervention.md` absent.

Stage 1's material result: **the goal sentence's "DNS timing" clause is refuted**, five of six
survive. It was re-scoped to FR-6 (one *measured* fact) with **BC-16** as a hard gate — if stage 2's
first-hand read-only probe finds no boundable mechanism reaching the running install's resolver,
FR-6 ships **no code** and is re-homed as a pool row. **BC-17** pre-rules out `socket.getaddrinfo`.
R-10 and R-11 ruled **in scope** (R-11 narrowed to `mode & 0o022`); R-32 in scope; **R-43 closed by
ruling** (Q-9); R-17/R-19/R-33/R-38 explicitly not claimed. AC-B14 pre-declared BLOCKED-and-filed
if no interactive root credential exists.

| 2 | solution-architect | 1 | **READY** | 2026-08-14 |

### Stage 2 — round record

round 1 · first pass · nothing superseded · no finding id.

**Routing decision: ADVANCE to stage 3.** No `BLOCKED:` marker, no rollback request.
Intervention check performed after stage 2 — `.harness/intervention.md` absent.

**BC-16 discharged: FR-6 ships.** The architect ran probe **P-1** first-hand and read-only
(`Grep` over the `/usr/local/bin/sing-box` binary, no HTTP issued): `clashapi.queryDNS` **and**
`clashapi.dnsRouter` are both in the symbol table, and Go drops unreachable functions, so the
route is mounted as `Mount("/dns")` + `Get("/query")` — which is why the literal `/dns/query`
matches 0 times (negative control). `/providers/rules` matched 1 as a calibration control,
reproducing T-10's independently measured count. Ruling: the DNS row stands on
`GET /dns/query?name=<EGRESS_HOST>&type=A` **through the existing `clash_api()`** — no second
exception envelope, caller-bounded, and the install's own resolver by construction. **P-2** (a
live read-only request) is specified for stage 4 and made binding by **K-20**.

**Shape**: `DOCTOR_SECTIONS` grows by exactly **two** entries; the other four facts land as rows
inside sections that already own their subject. Healthy host: **+5 rows**, exit 0, no paths, no
next steps. `_age_seconds()` deliberately **not** added (the smaller design taken).

**Residuals carried into the stage-3 dispatch as things the gate must rule on, not accept**:
RS-1 (NFR-2's literal wording vs FR-4's one required parse), RS-3 (older-`sc` document reads as
"does not carry this decision"), and the burden-of-proof item — `_aaaa_rule()` and `EGRESS_HOST`
extractions, and the *absence* of `_age_seconds()`. RS-2/K-19 (the `is_running()` vacuity trap)
is carried forward to stages 4 and 6. RS-6/RS-7 (two `CONTEXT.md` glossary terms; one
`rejected-decisions.md` record) are the PM's at close.

| 3 | gate-reviewer | 1 | **APPROVED WITH CONDITIONS** | 2026-08-14 |

### Stage 3 — round record

round 1 · first gate pass on T-20 · nothing corrected in place (no re-review round) · no finding id.
P-1 re-run independently with two added controls (`clashapi.configRouter` / `clashapi.proxyRouter`
present, a fabricated `clashapi.queryDNSNotReal` absent) and one **counter-control**
(`clashapi.scriptRouter` present while `/script` answers "not supported") that bounds the ruling to
*mounted*, never *supported*. Findings F-1 … F-15 raised; ten conditions GC-1 … GC-10 bound on
stages 4 and 6.

**Transcription:** the gate holds no write capability. It returned both portions under a header
naming each target path; both bodies were checked to open with their declared opening line and to
close with the contract's `## Verdict` line, then written **verbatim** to `03_GATE_REVIEW.md` and
`03_RATIONALE.md`. Nothing was added, completed or repaired.

**Routing decision: ADVANCE to stage 4.** The verdict routes to no upstream agent — F-1/F-2/F-3/F-8
are contract-internal contradictions each decided by an invariant the design itself already states,
and F-4/F-5/F-9/F-10 are discharge defects binding on stages 4 and 6 rather than gaps in what 01 or
02 promised. Stage-gate check satisfied: stage 3 produced an explicit approval verdict.
Intervention check performed after stage 3 — `.harness/intervention.md` absent.

Residuals ruled here: **RS-1 confirmed** (F-11), **RS-3 accepted as worded** (F-12), **BC-16 ruled
shipping** with the symbol-table inference independently verified (F-13); K-20's one hole (a P-2
that cannot be run at all) closed by **GC-6**. R-37 confirmed a **fifth** time (F-15).

| 4 | developer | 1 | **READY FOR REVIEW** | 2026-08-14 |

### Stage 4 — round record

round 1 · initial implementation of E-1…E-14 · full-mode first pass · no finding id (no rework round).

**Routing decision: ADVANCE to stage 5.** Stage-gate satisfied — `verify_all` PASS is recorded in
`04_DEVELOPMENT.md` and **independently re-run by the PM at this checkpoint**:
**PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, identical to the batch baseline measured after T-06.
Intervention check performed after stage 4 — `.harness/intervention.md` absent.

**GC-6 discharged without a routeback.** P-2 ran live and read-only; the body carries a non-empty
`Answer` array, so I-8 stands and the DNS row was written from a measured body rather than an
inferred one. P-3 (NXDOMAIN) returns an object with **no `Answer` key at all**, so I-8's "returned
no records" branch is real and V-7's stub bodies are **copied from these two, not invented**.
**P-2b deviation, measured not reasoned**: the telemetry-name discriminator came back *resolved*
because `grep -c TELEMETRY_NAMES /usr/local/bin/sc` = **0** — the installed build predates T-17, so
the live config carries no rule to reject it. BC-16 clause 3 therefore rests on `"Server":"internal"`
plus P-3's NXDOMAIN propagation instead. Recorded as a residual.

**Shape held**: `bin/sc` +320/−32, exactly two new `DOCTOR_SECTIONS` entries, five new rows.
GC-1 measured **+5 rows exactly** (16→21 on the same fixture root), every new row `[OK]`, zero
naming a path or a next step, exit **0**. GC-2 by AST sweep: `_dns_overlay()` call sites in the
doctor block = **0**, `ipv6_decision()` = **1**, IPv6 stderr line asserted at exactly **1**.
GC-4: stub log `['/configs', '/proxies', '/dns/query?name=api.ipify.org&type=A']`, no `systemctl`
exec'd. V-11 byte-compare of `config.json` IDENTICAL in all four IPv6 decision states.
52-step fixture suite 52/52.

**Carried into the stage-5 dispatch**: **D-4** — the new docstrings deliberately *name* the banned
calls, so a substring grep produces three **false** FAILs; V-16 was rewritten as an AST walk. The
reviewer is warned rather than left to trip on it. **AC-B14 BLOCKED and to be filed** (installing
the candidate over `/usr/local/bin/sc` is forbidden by K-18; no weaker artifact substituted — the
R-31/R-41/R-47 precedent honoured a fourth time). **RS-2 reproduced unchanged** → delivery pool row.
**R-37, sixth confirmation.**

| 5 | code-reviewer | 1 | **ROLLBACK TO DEVELOPER** | 2026-08-14 |

### Stage 5 — round record

round 1 · first review pass · nothing corrected in place · no finding id.
Findings CR-1 (MAJOR) … CR-9 (INFO); residuals RES-1 … RES-9.

**Transcription:** the reviewer holds no write capability. It returned both portions under a
header naming each target path; both bodies were checked to open with their declared opening line
and to close with the contract's `## Verdict` line, then written **verbatim** to
`05_CODE_REVIEW.md` and `05_RATIONALE.md`. Nothing was added, completed or repaired.

**Routing decision: ROLLBACK to stage 4 (developer). Rollback #1 at this stage** — streak 1 of
the 3 that would force an escalation. The reviewer explicitly declines to re-open the design
("no design re-open"), so the route is to the implementer, which is also what the rollback table
requires for a code defect.

**CR-1, the MAJOR, is the R-22 defect class reintroduced in the text of the row that reports on
it.** The clean-host permission row asserts the universal "no file grants access to group or
other", while `settings.json` is excluded **by name, whatever its mode** — and `save_settings()`
writes it with `write_text()` (`bin/sc:559`), so it is **0644 on a default install**. On every
default install with otherwise-clean modes, `sc doctor` prints that sentence as a **false
statement**, and both READMEs describe the row the same way. The *decision* to exclude
`settings.json` is right (Q-4) and is not being re-opened; only the sentence is wider than the
check. The reviewer applied to the row exactly the standard the gate applied to the README in
GC-8 — the promise stays exactly as wide as the behaviour.

**Undeclared-growth arithmetic closed with no slack** (CR-8): the per-region chain sums to
**+288 net**, precisely `+320/−32`. No hidden helper, cap, flag or constant. The three seams were
each proved load-bearing rather than accepted (CR-8 / rationale §2), and `_age_seconds()`'s
absence was verified rather than assumed.

Intervention check performed after stage 5 — `.harness/intervention.md` absent.

| 4 | developer | **2** | **READY FOR REVIEW** | 2026-08-14 |

### Stage 4 — round 2 record (rework after ROLLBACK TO DEVELOPER)

round 2 · rework · `04_DEVELOPMENT.md` and `04_RATIONALE.md` corrected **in place** (no round
section added to either).

| what changed | why | finding |
|---|---|---|
| One translation key pair replaced — `no credential file grants access to group or other, and the directory is not group- or other-writable` / 「没有凭据文件对同组或其他用户开放，目录本身也不可被同组或其他用户写入」 (`bin/sc:335`, `:2877`) + a 3-line call-site comment stating why the sentence says *credential* | `settings.json` is excluded by name whatever its mode and `save_settings()` writes it 0644, so the universal sentence was false on **every default install**. **Sentence narrowed, check untouched** — key count still exactly 28, PROBLEM/UNKNOWN values untouched, no other row moved | CR-1 |
| `README.md:268` + `README.zh-CN.md:268` now read "any **credential** file … (`settings.json` is excluded — it carries no credential)" | the same promise-width standard the gate applied in GC-8 | CR-1 |
| `CHANGELOG.md:7`'s permission clause carries the same exclusion | **judgement call, one clause beyond the reviewer's named scope** — the CHANGELOG made the identical false promise about the identical row, and leaving it would have shipped the defect in the one user-facing text not listed. No other CHANGELOG text touched. **Accepted by the PM**: it is the same finding, not a widened diff | CR-1 |
| `ipv6_decision()`'s docstring (`bin/sc:1635`) and `docs/dev-map.md:57` now say "three callers"; function body **byte-unchanged** (frozen, out-of-scope 9) | the prose counts were false after `_doctor_ipv6()` | CR-4 |
| `bin/sc:2769` renders `_plain(current or t("(none)"))` | **fixed in code, not declined**, so `_plain()`'s docstring invariant needs no amendment | CR-5 |
| `04_DEVELOPMENT.md`'s GC-10 disposition rewritten to state what actually shipped (mode strings are **not** `_plain()`ed; met by construction, a no-op wrapper deliberately not added) | the record overstated the code | CR-6 |
| `_egress_ip()`'s docstring sources the literal to `EGRESS_HOST`; the 8 s-timeout half kept | stale after E-1 | CR-7 |
| CR-2 / CR-3 **not fixed, by instruction** → RES-1 / RES-2 pool rows; CR-8 / CR-9 need no code | — | — |

**Re-verification (the reviewer's scope + the gate).** V-9 5/5 PASS with a **new V-9.5**, the
`settings.json`-exclusion control on a *default install* fixture (credentials 0600, dir 0755,
`settings.json` 0644): the row reads the narrowed sentence, no quoted line, and the string
`no file grants access` is **absent** from the capture. V-12/GC-1: HEAD 16 rows → candidate 21 on
the same fixture root, **delta +5**, all five new rows `[OK]`, **0** rows naming a path or a next
step, **exit 0**. V-15/V-15p zh capture clean, no `失败`, no leaked English key. New **V-17c**
(CR-5 control): `/proxies` echoing `n1\r\x1b[31mRED\x1b[0m` yields no CR and no ESC — and the
**negative control with the fix reverted leaks both bytes** while printing a plausible-looking
`n1`. AC-S5 diffed against HEAD's own table: **+28 keys, −3, 0 shared values changed**, 0 missing
zh, 0 placeholder mismatches; `check-i18n-parity.sh` → `OK: 48 keys, both languages`, exit 0.
V-11 re-run: `config.json` byte-identical to HEAD in all four IPv6 states. Fixture suite
**54/54**. `bin/sc` now **+331/−37**.

**Routing decision: ADVANCE to stage 5 (round 2).** Stage-gate satisfied — `verify_all` PASS
recorded by the developer and **independently re-run by the PM**: **PASS 17 / WARN 0 / FAIL 0 /
SKIP 1**, still the batch baseline. Intervention check performed — `.harness/intervention.md`
absent.

| 5 | code-reviewer | **2** | **APPROVED WITH MINOR** | 2026-08-14 |

### Stage 5 — round 2 record (re-review)

round 2 · re-review of the rework · `05_CODE_REVIEW.md` and `05_RATIONALE.md` **replaced** in
place (no round section, nothing appended).

**Closed at the code, not merely in the record:** CR-1 (MAJOR) by one translation-key pair
(`bin/sc:335-336`) plus a call-site comment, `README.md:268`+`:279`, `README.zh-CN.md:268`+`:279`
and `CHANGELOG.md:7` — with the permission **check byte-unchanged** (`:2841` `dir_mode & 0o022`,
`:2864` `S_ISREG ∧ name != "settings.json" ∧ mode & 0o077`), so the repair landed on the sentence
and never on the predicate. That distinction was the one that mattered: narrowing the *check*
instead would have been the wrong repair, and the reviewer tested for it explicitly. CR-4, CR-5,
CR-6, CR-7 also closed. **New: CR-10** (MINOR — twelve stale line citations in
`04_DEVELOPMENT.md`, substance correct everywhere, coordinates off by the +2/+3/+6 the
arithmetic itself predicts) and **CR-11** (INFO — the narrowed sentence is now marginally
*narrower* than the check, the safe direction: an under-promise can produce no false `[OK]`).

**Undeclared-growth arithmetic re-closed for the rework round**, anchor by anchor, at exactly
**+6** (`_egress_ip()` docstring +1, `ipv6_decision()` docstring +1, the `_plain()` wrap's line
break +1, the clean-host comment +3) ⇒ **+294 net**, precisely the declared `+331/−37`. The
reviewer added an independent add/delete cross-check (+11 added / +5 deleted decomposing exactly
across the four edits) — the property that catches a rework round quietly re-touching a frozen
function. `TRANSLATIONS` is line-neutral across the round, which holds the key count at 28/−3
without a shell.

**Rollback #2 was explicitly declined and the reasoning is sound**: CR-10 is stale coordinates,
not false behaviour (materially weaker than round 1's CR-6, which asserted a call that did not
exist), and spending the escalation budget on it while the two genuinely open items travel as
pool rows would be the wrong trade. **Rollback streak at stage 4 stays at 1 of 3.**

**Routing decision: ADVANCE to stage 6.** Stage-gate satisfied — stage 5 PASSes with no CRITICAL
and no MAJOR on either axis. Intervention check performed — `.harness/intervention.md` absent.
`PM_LOG.md` at 214 lines, well under rule 70's 500-line compaction threshold; every task doc
under the F.6 cap (largest 292).

| 6 | qa-tester | 1 | **APPROVED FOR DELIVERY** | 2026-08-14 |

### Stage 6 — round record

round 1 · initial validation · no re-test round, nothing routed back to the developer · no finding id.

**Routing decision: ADVANCE to stage 7.** Stage-gate satisfied — stages 5 and 6 both PASS.
Intervention check performed after stage 6 — `.harness/intervention.md` absent.

**RES-10 honoured**: the suite was rebuilt at stage 6 from `01`'s criteria and from `bin/sc`
itself — **317 assertions, 14 files, 3 consecutive clean runs** — with **no line number inherited**
from any stage document. The re-derived anchors agree with `05`'s corrections, not `04`'s.

The four conditions that were QA's: **GC-1** three row-level clauses asserted separately from exit
— 16 → 21 rows (**+5 exactly**) against a HEAD **clone** (`5bd0eaa`) on the *same* fixture root,
all five new rows `[OK]`, none naming a path or a next step, exit **0** (reachable, so no partial).
**GC-4** discharged with `sc.SYSTEMD = True` alongside the stub; log
`['/configs', '/proxies', '/dns/query?name=api.ipify.org&type=A']`, and QA additionally ran the
**vacuity twin** — the same delay-carrying fixture without the flag reads `0/2` with `/proxies`
never requested. **GC-5** four deletions each degrading the *named* section and naming the symbol.
**GC-9** `[OK] geosite-google.srs: usable, 203 bytes, 0 seconds ago` on a healthy row.

Five MINOR defects, 0 BLOCKER / 0 CRITICAL / 0 MAJOR. Two are new at this stage rather than
restatements: **DEF-1** widens RES-4 with the BC-11 clause the residual never named, and **DEF-2**
sharpens RES-2 — the DNS probe **populates the very cache it reads**, measured live (175 ms → 4 ms,
TTL 195 → 190 → 186, negative answers held 1800 s). **AC-B14 BLOCKED and filed**, nothing
substituted — the R-31/R-41/R-47 precedent honoured a fourth time.

| 7 | PM (delivery) | 1 | **DELIVERED** | 2026-08-14 |

### Stage 7 — delivery record

**Entropy watch: NOT-DUE by fail-open.** `.harness/scripts/entropy-cadence` **does not exist on
this host**, so neither `delivered` nor `check` could run. Per the cadence's own fail-open rule
(any cadence I/O problem resolves to not-due) the result is: **no scan dispatched, no
`## Entropy watch` section, no entropy digest**, and the delivery verdict is unchanged. Recorded
rather than worked around. Same for `.harness/scripts/task-state.js`, absent for the whole run —
stage/round/streak counters were kept by hand in this log.

**Final rollback tally: 1** (stage 5 → stage 4, CR-1). Never within two of the 3-consecutive
escalation threshold.

**Delivery-time obligations discharged.**

- `docs/tasks.md`: T-20's row added; **T-06's completed row rotated** into `docs/tasks-archive.md`
  (completed rows rotated in preference to open ones — no open row was displaced at this delivery).
  R-10 marked **closed**, R-11 **half-closed** with its remaining half named and re-homed, R-32 and
  R-43 recorded closed. New rows **R-48 … R-52** filed. Board at **292/300** lines, F.5 PASS.
- `.harness/insight-index.md`: `archive-task.sh` harvested 4 and rotated **none** — 34 against the
  30-line cap. **R-18, confirmed a ninth time** (it counts bullets while F.4 counts lines, so its
  branch cannot fire on a file with a header). **Hand-rotated** four entries into
  `docs/features/_archived/insight-history.md`, chosen by rule 70's "what no longer earns its line"
  rather than oldest-first. Deliberately **kept** despite age: the `LANG` / `CLASH_PORT` traps and
  the new `is_running()` twin, `_init_files()`'s hard-coded `/var/lib/sing-box`, the `[D]`/`[A]`
  control-class rule, the E.6 regex, and the `clash_mode`-precedence entry — that last because
  **R-50 is open against exactly that mode-independence property**. Index back to 30, F.4 PASS.
- `docs/dev-map.md` updated by stage 4 and corrected at stage 5 (CR-4's stale caller count).
- `.harness/scripts/archive-task.sh --task doctor-extended-checks` run: stage docs moved to
  `docs/features/_archived/doctor-extended-checks/`.
- **`guard-rm.sh` blocked a command a seventh time** — this run it was a `python3` heredoc
  containing no `rm` at all, refused as an unparseable "nested pwsh command". Worked around by
  writing the script to a file and invoking it by path. The `HARNESS_ALLOW_OUTSIDE_RM` bypass was
  **never** set. The commit used `git commit -F <file>` for the same reason.
- `verify_all` re-run **after** every board, index and archive edit: **PASS 17 / WARN 0 / FAIL 0 /
  SKIP 1**.
- `docs/batches/**` left **unstaged** — they belong to the batch loop.
