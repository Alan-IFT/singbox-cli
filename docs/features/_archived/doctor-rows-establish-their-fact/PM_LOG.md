# PM Log — T-26 / doctor-rows-establish-their-fact

Mode: **full** (7 stages). Pool: `followups` (`docs/batches/followups/BATCH_PLAN.md`).
Decision authority: standing authority granted by owner; `BLOCKED: NEEDS-HUMAN` reserved for a
genuine safety red line. Deferred-human mode: batch dispatch.

## 2026-08-15 — task start

- Task folder created: `docs/features/doctor-rows-establish-their-fact/`.
- **Intervention check #1** (before stage 1 dispatch): `.harness/intervention.md` **absent** — no
  pending intervention.
- **Durable task state**: `.harness/scripts/task-state.js` **does not exist on this host**
  (`node:internal/modules/cjs/loader` throw). Per dispatch instruction: **fail open and record**.
  Stage/rollback counters are tracked in this log by hand instead.
- **Entropy cadence**: `.harness/scripts/entropy-cadence` **does not exist on this host**. Per the
  cadence's own fail-open rule, this resolves to **NOT-DUE** — no entropy scan, no
  `## Entropy watch` section at delivery. Recorded here.
- **Developer mode**: `.harness/agents/` does not exist ⇒ **single-Developer mode**; stage 4 goes to
  the plugin agent `harness-kit:developer`.
- **Batch plan Notes read** (T-26 paragraph): the three rows share one cause — *the verdict is
  derived from a proxy for the fact rather than from the fact*. R-50 needs a **requirement ruling**
  (FR-4 and I-6 both specify a membership test), not just a code edit. R-24 rides along only if it
  costs one line.
- Baseline to beat: `bash .harness/scripts/verify_all.sh` = **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**.

### Insight index entries surfaced to downstream (whole entries)

Queried `.harness/insight-index.md` (29 lines, at the ≤30 cap — hand-rotation obligation R-18
applies at delivery). Applicable entries, carried verbatim into the stage-1/2/4/6 dispatches:

- line 17 — `is_running()` returning `False` from its final line (this is R-49's mechanism, plus the
  fixture requirement `sc.SYSTEMD = True` alongside the `subprocess.run` stub).
- line 24 — a `sc doctor` probe that raises loses its **whole section** (`_doctor_clash()` returns
  four rows as one list).
- line 9 — `_init_files()` hard-codes `/var/lib/sing-box`.
- line 10 — `main()` reassigns `LANG`, so setting only `sc.LANG` renders English.
- line 13 — `main()` reassigns `CLASH_PORT` after import.
- line 21 — `LC_ALL=C PYTHONCOERCECLOCALE=0` does not give a non-UTF-8 Python (PEP 540).
- line 29 — `docs/dev-map.md`'s mandated loader recipe needs `encoding="utf-8"` added.

## Stage transitions

| # | Stage | Agent | Round | Verdict | Decision |
|---|---|---|---|---|---|
| 1 | Requirement analysis | `harness-kit:requirement-analyst` | 1 | **READY** | Advance to stage 2 |

### Stage 1 — accepted (2026-08-15)

Contract `01_REQUIREMENT_ANALYSIS.md` (219 lines) + `01_RATIONALE.md` (180 lines). FR-1…FR-13,
BC-1…BC-14, AC-1…AC-17, 4 NFRs, OQ-1…OQ-11 all resolved (no open questions carried forward).

- **Intervention check #2**: `.harness/intervention.md` absent.
- **The R-50 requirement ruling (OQ-1) is POSITION** — T-20's FR-4 and I-6 are amended: the AAAA row
  reports `[OK]` only when the authored rule is the **first** `dns.rules` entry. Three first-hand
  grounds: `README.md:126` already publishes the *position* as the product promise; `CONFIG_BASE`'s
  `dns.rules` opens with two `clash_mode` rules that each match every query in their mode, so a later
  rule is dead in `global`/`direct`; and narrowing cannot resolve this row because the outcome
  **class** carries the verdict.
- **Four dispatch claims corrected by first-hand reading** (recorded because they change what stage 2
  must respect):
  1. The amendment target is **T-20**, not T-16 (OQ-6). T-16's FR-4 governs `sc ipv6` and its I-6
     `_dns_overlay()` *authors* index 0 — so the amendment contradicts nothing in T-16.
  2. The read-only ruling (OQ-2) is **already published** at `README.md:272`, not new. The probe
     satisfies the invariant; the binding addition is that the side effect bounds what the row may
     *claim*.
  3. **R-48 is wider than filed** (OQ-9): the same call serves all three DNS-row branches from the
     same cache, and a negative answer is held far longer — so `returned no records` can restate an
     already-repaired failure. One clause covers all three.
  4. **R-49's real shape is a duplicated judgment, not a missing guard**: `_doctor_clash()` decides
     "is the process alive?" twice and the weaker answer overrides the stronger. The fix **removes a
     second opinion**. R-49 fails loud (false PROBLEM); R-48/R-50 fail silent.
- **R-24 rides along at one line** (OQ-5, drop rule BC-11): `cmd_telemetry` already ships the exact
  translated sentence for the identical state; the fix is a key swap at one print site.
- **R-22 standard met**: AC-1/2/3/5/9/10/12 each state HEAD's behaviour and HEAD fails each;
  AC-4/6/7/8/11/13/14 are declared **control / not discriminating** and AC-15 **fidelity, not
  discriminating by construction** — declared up front rather than discovered at stage 6.
- **Honest limit carried to stage 2**: stage 1 held no execution tool. OQ-8 lists what is inherited
  (R-48's ms/TTL figures; R-50's index-3 runtime measurement) and shows neither is load-bearing;
  **BC-10 routes the measurement obligation to stage 2** (T-20 BC-16 precedent) and AC-1/5/9/10 to
  stage 6.
- **R-37 confirmed a fifteenth time** (OQ-11: rule 70 still defines no stage-doc boundary rule).
  T-27 owns it; file at delivery, do not fix here.

### Stage 2 — accepted (2026-08-15)

Contract `02_SOLUTION_DESIGN.md` (292 lines) + `02_RATIONALE.md` (203 lines). Verdict **READY**.
Single-Developer mode confirmed, so no partition-assignment section was required.

- **Intervention check #3**: `.harness/intervention.md` absent.
- Design shape: **one expression, one condition, five sentences — no shared construct** (FR-3/AC-16
  held). E1 AAAA: `_dns_overlay()` takes `suppress`, becoming the one home of rule **and** emitted
  position; the probe tests `rules[:len(prepend)] == prepend`. E2 node delays: **one changed line**,
  `if port is None and not is_running():` — it *deletes* a second opinion rather than adding a check,
  and `sc ls` (which passes no port) keeps BC-7's guarantee. E3 DNS: **sentences only**, probe
  byte-for-byte unchanged. E4/E5: R-24 key swap plus deletion of the orphaned key — net zero.
- **BC-10 discharged and the ruling recorded**: no read-only, no-new-constant cache-free lookup
  exists through the Clash route. `clashapi.cacheRouter`'s handler is a **mutating** fake-IP flush;
  `disable_cache` is **configuration** vocabulary only; `no_cache`/`bypass_cache`/`fresh=` = 0. A
  second independent leg: the DNS-JSON body carries no cache-hit indicator, so even a bypass
  parameter would leave the row *inferring* it was honoured — one proxy swapped for another.
  **FR-9 does not fire; FR-8 ships the narrowed claim.** Carried as **RS-2** with its honest limit:
  stage 2 held no execution tool, so this is a read-only literal search over the installed binary
  (T-20's BC-16 technique, with its calibration and negative controls reproduced). **The gate must
  test this discharge**, not accept it.
- **BC-11: R-24 rides along** — the reused `cmd_telemetry` sentence is true for the IPv6 case word
  for word, and the swap orphans a key that gets deleted.
- **Rule 85 discharge present per row** (`## Smaller alternative rejected`), each naming what the
  extra code buys: bare `[:1]` slice → silent false PROBLEM on 100% of installs under a directive
  rename; deleting the guard → `sc ls` pays a request and a wait; `[OK]`-only wording → BC-12/AC-10.
- **Projected size ≈ +50/−40 on `bin/sc`** (net ≈ +10; ~15 executable lines). Exceeds stage 1's
  `+40/−20` bar, and the document discharges the burden explicitly. **Gate must test that argument.**
- **BC-9 does not fire** (the establish branch means no row becomes UNKNOWN; init-less hosts go
  `1 → 0`, not `1 → 2`), so the exit-`2` README row needs no change.
- **RS-1 warns** AC-7's fixture must have the stub API *not* answering, or it tests an incoherent
  state (an answering API on a host whose init reports "stopped" describes a live process).
- **RS-7 is a PM obligation at delivery**: file two declines in `.harness/rejected-decisions.md`
  (`position-test-by-a-bare-head-slice`, `doctor-cache-free-dns-lookup`) — the T-18/T-19 precedent,
  since `.harness/**` is outside the task's permitted diff.
- Files referenced by the ledger verified to exist: `CONTEXT.md`, `.harness/rejected-decisions.md`,
  both READMEs (457 lines each, line-for-line mirrors), `CHANGELOG.md`.

### Stage 3 — accepted (2026-08-15) · verdict **APPROVED WITH CONDITIONS**

- **Intervention check #4**: `.harness/intervention.md` absent.
- **Transcription**: `gate-reviewer` holds no write capability and returned both portions in its
  final message under a header naming each target path. Pre-write checks all passed — the contract
  body begins with its declared opening line (`> Contract portion.`), ends with its `## Verdict`
  line, both header-named paths carried a portion, and no partial return was reported. Written
  **verbatim** to `03_GATE_REVIEW.md` (59 lines) and `03_RATIONALE.md` (282 lines); nothing added,
  no heading, no summary, no round record. Round 1, so no round record accompanied it.
- **Gate audit**: 5 PASS / 3 WARN (design completeness, boundary handling, test feasibility) / 0 FAIL.
  Findings F-1…F-10 (3 MEDIUM, 7 LOW), all dischargeable downstream — no finding required the
  analyst or the architect to hold the pen again, so no rollback. **Rollback streak at stage 3: 0.**
- **The gate did its two hardest duties properly**:
  - **It tested the rule-85 answer and found the design's mechanism wrong** (F-4): a bare
    `rules[:1] == [_aaaa_rule(suppress)]` never "compares one element against two" — with payload
    `[aaaa, new]` it *passes while silently under-checking*, and only `[new, aaaa]` gives a false
    PROBLEM. **It ruled the rejection survives anyway** and recorded that it considered moving the
    ruling to the bare slice and what stopped it (FR-5/AC-3 are contract; and the six lines are the
    *smaller* design once concept count is priced — after E1 `_dns_overlay(suppress)` and
    `_aaaa_rule(suppress)` are one concept instead of two). It also corrected the design's citation:
    `_aaaa_rule()`'s docstring warns against a positional index **into the overlay**, not a
    positional test **of the document** — adjacent evidence, not the same evidence.
  - **It re-ran the BC-10 probe itself** and reproduced every count (`cacheRouter` 1, `disable_cache`
    4, `/proxies` 3, `/dns/query` 0, bypass vocabulary 0), stated the literal search's honest
    resolution limit, and ruled it **does not matter** because of the discharge's second leg.
    **BC-10 is discharged at stage 2 and does not survive to stage 6; RS-2 upheld** (BC-I).
  - Size: it **accepted the discharge and rejected the ruler swap** — "a design does not get to
    redefine the bar a contract states; it gets to discharge the burden the bar imposes." Recorded
    as F-9 and capped by **BC-G** at `+55/−45` so the argument cannot widen during implementation.
- **The one fact neither upstream document named** (F-3): `_telemetry_overlay()` is a **second
  `sc`-authored writer of `dns.rules` today** — so BC-5's multi-writer world is present tense, not
  future. The position claim survives (its `$before` anchor resolves by search, so it lands at
  index ≥ 1) but by an argument no document made, on a config state a large fraction of hosts are in.
  **BC-C** makes stage 4/6 observe it rather than assert it.
- **Ten binding conditions BC-A…BC-J** carried into the dispatches of the stages that own them:
  stage 4 owns BC-C/BC-D/BC-E/BC-F; stage 5 owns BC-D/BC-G/BC-H; stage 6 owns BC-A/BC-B/BC-C/BC-E/
  BC-F/BC-I; **PM owns BC-J** (file F-7's `docs/dev-map.md:136` recipe defect against R-77's owner
  rather than fixing it here) and the PM half of BC-I.
- Gate confirmed **PQ-3**: a raising position test costs **one row**, not a section —
  `_doctor_ipv6()` is its own single-row section, so the indexed `_doctor_clash()` blast-radius
  entry does not apply. And **PQ-1**: E1 is read-only and removes a second opinion rather than
  adding one.
- Ledger-name check clean: every downstream stage-doc filename the design names is exact.

**Stage gate before stage 4 satisfied**: stage 3 produced an explicit approval verdict. Advancing to
stage 4 in **single-Developer mode**.

### Stage 4 — accepted (2026-08-15) · verdict **READY FOR REVIEW**

Contract `04_DEVELOPMENT.md` (117 lines) + `04_RATIONALE.md` (188 lines).

- **Intervention check #5**: `.harness/intervention.md` absent.
- **All ten edits E1…E10 landed** in the design's migration order (E1's signature change and its
  single call site in one edit).
- **`verify_all` PASSED** — `bash .harness/scripts/verify_all.sh` from `/home/alan/Programs/singbox-cli`,
  **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, measured both before any edit and after all edits.
  Baseline preserved. **Stage gate before stage 5 satisfied.**
- **Diff verified by PM** (`git diff --numstat`): `bin/sc` **+55/−44** — inside BC-G's `+55/−45` bar,
  but at its ceiling, so stage 5 must run BC-G as written. Also `README.md` 4/4,
  `README.zh-CN.md` 4/4, `docs/dev-map.md` 4/4, `CONTEXT.md` +9, `CHANGELOG.md` +2. No file outside
  the declared ledger. `docs/batches/**` modifications are the batch runner's own and stay unstaged.
  Top-level `def`/`class` **113 → 113** (AC-16 held); `TRANSLATIONS["zh"]` **183 → 182** (zero added,
  exactly one deleted — K-2 held).
- **BC-C discharged by assertion, not assumption**, and it sharpened the gate's F-3: `telemetry:
  block` is the **absent-key default**, so the second `sc`-authored `dns.rules` writer is present on
  an **ordinary** host, and its `$before` anchor lands it at index **2** (behind the `hosts_dns`
  rule), not index 1 as PQ-2 estimated. `rules[0] == _aaaa_rule(suppress)` is True and V-1's
  byte-identity holds for that composition. This is the item the gate said it would most regret
  waving through — it is now observed.
- **BC-D discharged**: `grep membership bin/sc` returns nothing; the `_aaaa_rule()` body and returned
  dict untouched; the `_doctor_ipv6()` prohibition sentence removed in the same edit per PQ-1.
- **BC-E, BC-F discharged** (command line quoted; `OVERRIDE_PATH` clause verified in both rendered
  language halves).
- **D-1, one design drift, declared**: `ipv6_decision()`'s docstring caller list was corrected (E1
  makes "`_dns_overlay()` is a caller" false). 4 docstring lines, no behaviour. Flagged to stage 5.
- **Safety near-miss recorded rather than hidden** — the right call, and the reason this pool's R-78
  discipline works: one intermediate case ran `sc ls` through `main()`, reaching `_init_files()`.
  **Nothing was written** (`mkdir(..., exist_ok=True)`; `/var/lib/sing-box` mtime unchanged at
  Jul 30; no new entry), and the case was rebuilt to call `cmd_ls()` directly. No live-service
  action, no write under `/etc/sing-box`, no install over `/usr/local/bin/sc`, no request of any
  kind to the live Clash API. Carry to delivery as a pool row candidate.
- **R-37 confirmed a seventeenth time** — the contract portion has no section shape that can hold a
  measurement transcript, so smoke evidence lives in `04_RATIONALE.md`. T-27 owns it.

### Stage 5 — round 1 (2026-08-15) · verdict **APPROVED WITH COMMENTS**

- **Intervention check #6**: `.harness/intervention.md` absent.
- **Transcription**: `code-reviewer` holds no write capability. Pre-write checks passed (contract
  body opens with `> Contract portion.`, ends with its `## Verdict` line, both header-named paths
  present, no partial return). Written verbatim to `05_CODE_REVIEW.md` and `05_RATIONALE.md`.
- **Spec/design-fidelity: zero findings.** E1…E10 shipped as declared; I-1…I-10 match; K-1…K-10 all
  held; the frozen set moved nowhere under BC-D's narrowing. Standards-conformance: 3 findings,
  worst **MINOR**.
- **BC-G, BC-H, BC-D all discharged by stage 5.** BC-H confirmed the shared cache clause
  byte-identical across both English keys and both `zh` values, and all five placeholder sets
  set-equal. BC-D confirmed `grep membership bin/sc` empty and `_aaaa_rule()`'s body untouched.
- The reviewer **declared its own tool limit before any verdict rested on it** — no execution tool,
  so BC-G's numstat was *quoted, not re-measured*, with **RES-1** routing the machine measurement
  forward. It re-ran AC-16's count first-hand (113). **PM has now re-measured both**: numstat below,
  `grep -cE "^(def |class )" bin/sc` = **113**. RES-1 discharged at PM level.
- Three requirement readings **adjudicated rather than passed silently**: R-a (FR-6's letter vs the
  shipped PROBLEM-with-three-causes row — ratified in advance by gate BC-A), R-b (AC-8's grep is a
  proxy; its intent is "no *second* liveness source", and the one `is_running` in the diff is the
  single changed guard line), R-c (NFR-2 vs FR-6 — the `/proxies` request on an init-less host is
  in-bounds, routed to stage 6 as RES-4 to be measured rather than argued).
- **D-1 ruled in-bounds**, on BC-D's own principle: leaving the docstring would ship the map and the
  code in disagreement — the defect this task exists to remove.
- The reviewer judged the developer's fixture near-miss disclosure **adequate and better than the
  norm**, while catching that the *remediation sentence* claimed a boundary the code does not draw.

### Stage 4 — round 2 (2026-08-15) · PM-routed rework · verdict **READY FOR REVIEW**

**PM routing decision and why.** Stage 5's verdict did not block, but **CR-1 was a false sentence in
`bin/sc`** — `stored_delays()`'s guard paragraph still claimed "every future caller inherits it"
after E2 made that untrue, while `docs/dev-map.md:65` stated it correctly **in the same delivery**.
Shipping it would have made this delivery self-refuting: the entire task is about rows claiming what
they did not establish. Routed under "reviewer finds code defect → developer".

**PM verified the constraint before routing rather than handing over a wish.** `git diff -U8` showed
the offending sentence is **pre-existing context**, not a line round 1 added — so a naive in-place
edit was `+1/−1` and would have taken `bin/sc` to `+56/−45`, **exceeding BC-G**. The dispatch named
that tension, left the resolution to the developer's standing authority, and pointed at rule 85's
"prefer deleting to adding" without prescribing an answer.

**Outcome — the developer took the smaller route.** It corrected the pre-existing line **and**
collapsed its own round-1 three-line paragraph to two, because the narrowing was being said twice.
Net: the docstring is **one line shorter than round 1**, and `bin/sc` landed at **`+55/−45`** —
inside BC-G, which fires on "exceeds". **PM re-measured: `55 45 bin/sc`.** No overrun to declare.
CR-2 corrected in place in `04_DEVELOPMENT.md`; **CR-3 deliberately untouched** (NIT, explicitly
"flagged, not required", not in E9's declared rows) and carried as a residual.

- **Round records** (written here, per contract — no stage document carries a `## Round N` section):
  - `round 2 · corrected stored_delays()'s guard-paragraph claim at bin/sc:2222 from "every future
    caller inherits it" to "every caller naming no port inherits it", and absorbed the +1 removal by
    tightening the added named-port paragraph from three lines to two · the sentence was false after
    E2 and disagreed with docs/dev-map.md:65 in the same delivery — the task's own BC-D principle
    unapplied at the one site E2 falsified; landed inside BC-G at +55/−45 with zero margin rather
    than declaring an overrun · CR-1`
  - `round 2 · corrected 04_DEVELOPMENT.md's fixture-remediation sentence to state that sc ipv6 takes
    main()'s initialising arm and the final fixture still drives _init_files() and bin/sc:543 · the
    boundary claim was wrong (main()'s read-only arm is ("doctor","config")); disclosure and
    nil-effect evidence kept and extended, fixture unchanged · CR-2`
- **`verify_all` re-run and still PASSING**: PASS 17 / WARN 0 / FAIL 0 / SKIP 1.
- **No stage-5 re-review round dispatched.** The delta is two docstring lines and one stage-doc
  sentence, with **zero behavioural change** — stage 5's spec/design-fidelity axis had no findings
  and cannot be disturbed by it. Recorded here rather than silently: the developer flagged that
  AC-8's *mechanical* grep now returns four diff lines instead of two (the changed guard plus the
  changed docstring line, which names `is_running()` in prose exactly as HEAD's line did). Stage 5's
  ruling **R-b** already governs this — AC-8's intent is call sites, not tokens — and stage 6 is
  dispatched to verify AC-8 **by call site**.
- **Rollback streak: stage 4 round 2 of 2, stage 3 streak 0, stage 5 streak 0.** No escalation
  trigger approached (3 consecutive at one stage).

**Stage gate before stage 6 satisfied**: stage 4 shows `verify_all` PASSED and stage 5 approved.

### Stage 6 — round 1 (2026-08-15) · verdict **CHANGES REQUIRED (1 defect)**

Contract `06_TEST_REPORT.md` (306 lines, unnumbered `## Adversarial tests` heading present at line 77
— declare-done gate satisfied) + `06_RATIONALE.md` (365 lines).

- **Intervention check #7**: `.harness/intervention.md` absent.
- **16 of 17 ACs pass. All 7 discriminating criteria discriminated** — candidate ≠ HEAD on every
  one; **none reported `NOT-DISCRIMINATING`**. 114 fixture runs (57 candidate/HEAD pairs) + 50
  stability repeats, **0 flakes, 0 bytes of stderr**. Pristine HEAD **clone** at `6d16caf` (not a
  worktree). Nothing BLOCKED, so **no operator obligation opened** — ids 1-5 unchanged.
- **All six binding conditions I routed to QA discharged**, including the two the gate added
  because the AC set never covered them:
  - **BC-A** (gate F-1) rendered rather than argued: candidate `[PROBLEM] node delays: a stored
    delay was read for 0/2 nodes — … or the list could not be read` vs HEAD `[PROBLEM] … 0/2 nodes
    carry a stored delay …` **with a request log holding no `/proxies`** — HEAD's count had no
    request behind it. This is the R-48-class defect the gate found *inside* R-49's own row.
  - **BC-B** (gate F-2): candidate requests `/proxies` and reads `2/2` where HEAD requests nothing
    and prints `0/2`.
  - **BC-C** (gate F-3, the item the gate said it would most regret waving through): the
    developer's two claims **reproduced independently** — `telemetry: block` is the absent-key
    default (identical normalised digest) and the telemetry rule lands at index **2**; V-1
    byte-identity holds across four compositions.
- **AC-3 is the sharpest pair in the run**: renaming the directive in the **emitter only** gives
  candidate `[UNKNOWN] IPv6 (AAAA): this check could not run: '$prepend'` while HEAD reports
  `[OK]` **with the rule sitting at index 8 of 9**. That is I-3's design intent observed, and it
  is the concrete vindication of the gate's rule-85 ruling against the bare-slice alternative.
- **All five stage-5 residuals discharged**: RES-1 measured (`bin/sc 55 45`; stage 5 had quoted
  `55 44` from before round 2 — still inside BC-G, at the ceiling on both halves); RES-2 rendered;
  **RES-3 re-asserted first-hand rather than inherited** — `sc ipv6` *does* reach `_init_files()`
  (proof: `clash_api_port` appears in `settings.json`), and `/var/lib/sing-box` mtime + entry list
  are unchanged across all 8 such runs; RES-4 counted per host class; **RES-8/AC-8 verified by call
  site, not grep** — `is_running()` 6 → 6 sites in the identical six functions, `subprocess.run`
  28 → 28.
- `baseline.json` untouched (`test_count` stays 0 — **T-28 owns the suite**); no check lowered or
  modified; no production code touched by QA.
- **Pool candidate recorded by QA, not a defect**: with an emptied `$prepend` payload the new probe
  would read `[OK]` silently — the coupling's one silent failure mode, against the rename's loud
  one. Carry to delivery.

#### DEF-1 — [MAJOR] AC-15 fails, and PM routing

`CHANGELOG.md:26` publishes an exit transition **the build never produces**: "没有 init 系统、Clash
API 正常应答的机器 … 退出码从 `1` 变成 `0`". On a host with neither systemd nor OpenRC,
`_doctor_service()` returns two `[UNKNOWN]` rows unconditionally (`bin/sc:2741`), and with
`DOCTOR_EXIT = {OK:0, UNKNOWN:2, PROBLEM:1}` / `worst = max(...)` such a host **cannot exit 0**.
Measured on a wholly healthy init-less fixture: **HEAD `EXIT = 1`, candidate `EXIT = 2`**. The other
half of the same sentence (`0` → `1` for a rule-not-first host) is **true** — measured HEAD 0 /
candidate 1. `README*.md:279/280` need nothing; I-9 and BC-9 stand as shipped.

**The mechanism is subtler than an error and is why it survived three prior stages**: the design's
premise "no host gains an UNKNOWN it did not have" is **true**, and it is why it concluded BC-9 does
not fire. But the exit still moves `1 → 2` by **unmasking** — a `[PROBLEM]` row was hiding the two
pre-existing `[UNKNOWN]` service rows in the exit status, and removing the PROBLEM exposes them.
Sound reasoning, true premise, wrong conclusion. It is the task's own defect class — a sentence
claiming what was not established — surviving into the task's own changelog.

**PM routed DEF-1 to two owners in parallel, per the no-downstream-edits rule**, because QA
identified the origin as well as the symptom:
- **Developer (round 3)** — `CHANGELOG.md`, the shipped published sentence. `README*` explicitly
  out of scope; `bin/sc` must stay at `+55/−45`.
- **Solution architect** — `02_SOLUTION_DESIGN.md`'s backwards-compat clause (c), which states the
  same false transition and is where the developer got it. QA's own note was "don't transcribe it
  again"; leaving the design uncorrected would have re-seeded the error in the next task that reads
  it. Scoped to the one clause; verdict stays `READY`.

Different files, no conflict, so both ran concurrently.

### Stage 2 — round 2 (2026-08-15) · single-clause correction · verdict stays **READY**

- **Round record**: `round 2 · corrected 02_SOLUTION_DESIGN.md's backwards-compatibility clause (c)
  in place: the init-less-host exit transition now reads 1 → 2 (measured), and names the unmasking
  mechanism (_doctor_service()'s two unconditional UNKNOWN rows, previously masked in the exit
  status by the node-delay PROBLEM under worst = max over OK < UNKNOWN < PROBLEM) · stage-6
  measurement disproved the clause's 1 → 0 conclusion while its premise ("no host gains an UNKNOWN
  it did not have") held; I-9, BC-9 and README*.md:279-280 stand as shipped and are now stated as
  standing for the right reason · QA DEF-1`
- Corrected in place, no `## Round N` section added, `## Verdict` unchanged. `02_RATIONALE.md` was
  checked by grep (`exit` / `退出码` / `UNKNOWN` / `init-less` / `BC-9`) and **never states the exit
  transition**, so it needed no correction and was not touched. No other file or section modified.
- **The architect tightened QA's own line citations** rather than transcribing them: the guard plus
  the two returned UNKNOWN rows are `bin/sc:2739-2742` (QA cited `:2741-2744`), `worst = max(worst,
  cls)` is at `:3027`, the ordering comment at `:2476`, `DOCTOR_EXIT` at `:2480`. Same mechanism,
  exact spans. Recorded because it is the second time this round a stage checked a cited number
  instead of inheriting it.

### Stage 4 — round 3 (2026-08-15) · DEF-1 · verdict **READY FOR REVIEW**

- **Round record**: `round 3 · CHANGELOG.md:26 — the exit-transition clause for the
  init-less/answering-API host class corrected from "退出码从 1 变成 0" to "退出码从 1 变成 2", with
  the one-clause mechanism (the two 服务/开机自启 rows are already [未知]; once no [异常] remains the
  exit reports 未知); the true 0 → 1 half kept verbatim; 04_DEVELOPMENT.md's E8 row and Open-issues
  section updated in place and one insight added · why: the published sentence claimed an exit
  transition the build cannot produce — DOCTOR_EXIT maps UNKNOWN→2 while the severity ordering is
  OK<UNKNOWN<PROBLEM under worst = max(...), so an init-less host cannot exit 0 on this build or on
  HEAD · finding: QA DEF-1 [MAJOR], AC-15`
- `bin/sc` **untouched, still `55 45`**; every other numstat identical to round 2; `CHANGELOG.md`
  stays `2 0` because the repair lands inside a line this task added. Verified by PM.
- The developer **verified the mechanism first-hand rather than inheriting QA's citation**, and
  declined one thing on the record: it left the clause's lead 「退出码的影响只有一个方向」 untouched,
  ruling that repairing the false transition was in scope but re-phrasing pre-existing looseness in
  a published entry was not. Routed to QA to rule on.

### Stage 6 — round 2 (2026-08-15) · verdict **APPROVED FOR DELIVERY**

- **Intervention check #8**: `.harness/intervention.md` absent.
- **Round record**: `round 2 · AC-15 re-verified green and DEF-1 closed by my own re-measurement;
  the two-UNKNOWN-row span corrected to bin/sc:2741-2742 (guard :2739, cause :2740) in my report and
  rationale; verdict CHANGES REQUIRED (1 defect) → APPROVED FOR DELIVERY · because the CHANGELOG
  repair's every clause now matches measured behaviour on both host classes and nothing regressed ·
  finding id DEF-1`
- QA **established `bin/sc` byte-identical** to the build the 114 first-pass runs were taken on
  (`md5 10536f7ff4912c6dd7de97930dad582b`, numstat `55 45`) *before* re-measuring — so the repair
  could only have made a sentence false, and that is what it tested. 8 fresh runs:
  `healthy-clean-initless` HEAD `1` / candidate `2`; `healthy-clean-override` HEAD `0` / candidate
  `1`. **Both halves of the repaired sentence hold.** The mechanism aside holds **on both builds**,
  which is what makes 「新旧版本都一样」 a measurement rather than a claim. Six further runs
  reproduced their first-pass rows, request logs and exits exactly.
- **The line-span disagreement resolved against QA's own round-1 citation**: guard `:2739`, cause
  `:2740`, the two `[UNKNOWN]` row tuples `:2741-2742`; `:2743-2744` are the has-init branch. So the
  developer's `:2740-2742` and the architect's `:2739-2742` were each true of what they claimed to
  span and **QA's round-1 `:2741-2744` was the wrong one**. Corrected in QA's own two documents; the
  two upstream docs needed no change. Three agents checked a cited span rather than inheriting it,
  and the one that had been wrong said so.
- **QA ruled on the developer's declined item and accepted it, with reasons rather than deference**:
  the repair moved the lead from false-under-both-readings to true-under-one — the published pair is
  now `1 → 2` and `0 → 1`, **both upward numerically**, so "only one direction" is literally true of
  the exit values. Filed instead as a **pool candidate** (state the fact, not the direction:
  「没有哪台机器的退出码会变小」).
- `verify_all` re-run **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**; `## Adversarial tests` heading intact;
  `baseline.json` untouched (`test_count` stays 0 — T-28 owns the suite); **no operator obligation
  opened**, ids 1-5 stand.

**Stage gate before stage 7 satisfied**: stage 5 `APPROVED WITH COMMENTS`, stage 6 `APPROVED FOR
DELIVERY`. **Rollback streak: stage 4 reached round 3, stage 2 round 2, stage 6 round 2 — no stage
reached three *consecutive* rollbacks, so no escalation trigger fired.**

## Delivery (2026-08-15)

- **Entropy watch**: `.harness/scripts/entropy-cadence` **does not exist on this host**. Per the
  cadence's own fail-open rule this resolves to **NOT-DUE** — no supervisor scan dispatched, no
  `## Entropy watch` section in `07_DELIVERY.md`, no cadence reset. Recorded, not skipped silently.
- `.harness/scripts/task-state.js` absent throughout; stage/rollback counters were kept by hand in
  this log, as recorded at task start.

### Delivery-time obligations discharged (2026-08-15)

- **`docs/tasks.md` rotation.** The board was at its **300-line F.5 cap** before this delivery, so
  rotation was mandatory rather than tidy. Rotated *completed* work first, per instruction, then two
  blocks whose rows are now mostly closed — never displacing an open row that had nowhere to go:
  1. **T-25's completed row** → `docs/tasks-archive.md`.
  2. **T-20's whole block (R-48 … R-52)** → archive, with **R-48/R-49/R-50 marked CLOSED by T-26**
     and **R-51/R-52 recorded as still open**, plus a pointer bullet added to the board's existing
     "Rotated-but-open blocks" section so neither open row becomes invisible.
  3. **T-16's whole block (R-23 … R-27)** → archive: **four of its five rows are now closed**
     (R-24 by T-26, R-25/R-27 by T-23, R-26 by T-24) and the one survivor, **R-23**, is a capability
     gap the pool plan already records as deliberately not built.
  Each closure was checked against shipped work before the row was called closed. Board now **295
  lines**, under the cap with headroom for T-27.
- **New rows filed: R-80 … R-85** (six). R-80 is the one a future reader most needs: the new
  position test has a **silent** failure mode (an emptied `$prepend` payload makes the slice compare
  `[] == []`) where the old membership test had none — latent, not live, and priced against the loud
  `[UNKNOWN]` the design bought.
- **`.harness/rejected-decisions.md`** — RS-7 discharged: both declines filed
  (`doctor-position-test-by-a-bare-head-slice`, `doctor-cache-free-dns-lookup`), each carrying the
  gate's correction of record so a re-proposal meets the corrected mechanism rather than the
  design's wrong one.
- **`archive-task.sh`** run: 4 insights harvested, stage docs moved. **R-18 confirmed for the
  fifteenth time** — its rotation branch counts bullets against 30 while `verify_all` F.4 counts
  lines, so it can never fire; the index went to **33 lines** and the PM hand-rotated the **3 oldest
  entries** into `docs/features/_archived/insight-history.md`, bringing it to exactly **30**. **T-27
  owns the one-line fix; it was deliberately not made here.**
  - **Worth flagging to whoever dispatches next**: two of the three rotated entries are the
    *safety-critical* ones — `_init_files()` hard-coding `/var/lib/sing-box`, and `main()`
    reassigning `LANG` after import. They are preserved in `insight-history.md`, and the substance
    of the first is now **also** carried on the live board as **R-84**, so it stays in front of a
    future fixture author rather than only in history. Oldest-first rotation is the honest policy,
    but it evicts by age rather than by value, which is itself an argument for T-27's fix.
- **Entropy watch**: not run — `.harness/scripts/entropy-cadence` does not exist on this host, which
  the cadence's own fail-open rule resolves to NOT-DUE. No `## Entropy watch` section written.
- **Final gate**: `bash .harness/scripts/verify_all.sh` from the repository root —
  **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, run by the PM after every delivery-time edit including the
  board rotation and the index rotation.
- **Commit**: message written to a file and applied with `git commit -F` — `guard-rm.sh` has now
  blocked commands containing no `rm` **eleven** times by misparsing a heredoc as nested pwsh (it
  blocked this very log append), and the `HARNESS_ALLOW_OUTSIDE_RM` bypass was **not** set.
  `docs/batches/**` left unstaged per the pool's delivery policy.
