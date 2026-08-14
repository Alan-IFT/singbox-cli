# PM_LOG — T-07 `restricted-network-regression-test`

Mode: **full** (7 stages). Dispatched by `/harness-batch` on pool `default`; **final row of the batch**.
Decision mode: owner's standing authority — resolve judgment calls downstream and record them.
`BLOCKED: NEEDS-HUMAN` only for a genuine safety red line.

## Task-start checks

| check | result |
|---|---|
| `.harness/intervention.md` | **absent** — no pending intervention (checked before stage 1 dispatch) |
| `.harness/agents/dev-*.md` | directory **does not exist** ⇒ **single-Developer mode**, dispatch `harness-kit:developer` |
| `.harness/scripts/task-state.js` | **does not exist on this host** — durable state unavailable, **fail-open**; round counting is carried in this log instead |
| `.harness/scripts/entropy-cadence` | **does not exist on this host** — cadence unavailable, **fail-open** ⇒ resolves to NOT-DUE, no entropy sweep, no `## Entropy watch` section |
| `verify_all` baseline (PM-measured, pre-stage-1) | `bash .harness/scripts/verify_all.sh` → **PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — matches the batch baseline |
| working tree | clean except `docs/batches/**` (batch loop's, to be left unstaged) |

## Insight-index entries surfaced to downstream dispatches

Queried at task start; six entries apply and are carried verbatim into the stage-1/2/4/6 prompts
(the `set -euo pipefail` assignment-abort trap, the `git worktree` non-baseline trap, `main()`'s
`LANG` reassignment vacuity trap, the `失败：` load-bearing grep, the `CLASH_PORT` twin of the LANG
trap, and E.6's unnumbered `## Adversarial tests` heading).

## Stage transitions

### Stage 1 — requirement-analyst — round 1 — verdict `READY` — ADVANCE

Contract `01_REQUIREMENT_ANALYSIS.md` (217 lines) + rationale `01_RATIONALE.md` (256 lines), both
under the F.6 500-line cap. No rollback requested. Intervention file re-checked after the stage:
**absent**.

**The goal sentence was refuted on all four clauses** — the sixth consecutive batch row where that
held, and again the largest saving:

1. **The five end-state conditions are superseded and one is now inverted.** T-01's AC-9 ("prints
   the failure banner, exits non-zero") is **false against current code**: T-02's degradation makes
   config generation succeed with all four rule-sets missing, so the service starts and the run ends
   in the **success** banner at exit `0`. A test written to AC-9 would fail on correct code. Current
   characterisation re-derived first-hand as **six** conditions E1…E6, each attributed to the task
   that set it.
2. **Blocking `github.com` / `raw.githubusercontent.com` cannot reproduce the scenario** — four
   shipped sources across three failure domains; two jsDelivr edges and `ghfast.top` keep answering.
   The blackout must be *derived* from the shipped list (FR-3).
3. **"the full one-liner install" is impossible under its own premise** — the one-liner fetches
   `install.sh` from the blocked host. The artifact drives the local-checkout branch; the coverage
   limit is stated (Q-4).
4. **Container is out; VM only** — E1/E5 need systemd as PID 1 plus `/dev/net/tun`.

**Rulings taken under the owner's standing grant** (no BLOCKED, none deferred): T-02's 846-assertion
harness and T-08's two "inherited defects" reference files that **were never committed and do not
exist** (`.gitignore:19` ignores `test/` wholesale) — both converted into binding requirements
(FR-3/BC-2/BC-13, and FR-10/AC-5/AC-12) rather than carried as unfixable TODOs. `CURL_OPTS_*`
dev-map row **discharged here** (FR-15). `baseline.json` **stays at `test_count: 0`** — nothing in
the repo reads it and no assertion can run here (Q-9). **R-9 not merged** (out-of-scope 1/2).
T-11's R-1…R-8 read, **not covered**, stay open (Q-12). Of T-02's four unverified items **only
BC-32 closes** (Q-13).

The host/VM split is **structural, not discovered at stage 6**: every AC is tagged `[HOST]` or
`[VM]`; eight are VM-only and **AC-19 makes reporting them `BLOCKED` mandatory, with artifact
inspection explicitly forbidden as a substitute** — the R-31/R-41/R-47/R-52 discipline, a fifth
time. FR-14's unprivileged non-mutating self-check is the one place code was deliberately bought,
so that some of the artifact executes before a VM exists.

R-37 recorded a **third** time (rule 70 still defines no `## Stage-doc boundary rule`).

### Stage 2 — solution-architect — round 1 — verdict `READY` — ADVANCE

Contract `02_SOLUTION_DESIGN.md` (196 lines) + rationale `02_RATIONALE.md` (157 lines). No rollback.
Intervention re-checked: **absent**. Single-Developer mode confirmed, so no partition section was
requested and none was written.

Design: **one new file**, `.harness/scripts/restricted-network-regression.sh` (≤250 lines including
its Chinese operator-guide header), beside `check-i18n-parity.sh` — the existing precedent for a
git-tracked, unignored, Linux-only, no-`.ps1` project check, so `.gitignore` is untouched and
dev-map's "no test directory" sentence stays true. Blackout **derived textually** from `bin/sc`'s
`RULESET_BASES` (never importing `bin/sc`), injected via `/etc/hosts` and lifted by byte-restore.
Ledger C-1…C-5; product files byte-frozen. Rule 85's `## Smaller alternative rejected` was routed to
the rationale portion (RS-1, R-37 a **fourth** time).

### Stage 3 — gate-reviewer — round 1 — verdict `APPROVED WITH CONDITIONS` (GC-1 … GC-11) — ADVANCE

Round record returned by the reviewer, transcribed here per the stage-3 rule:
`round 1 · initial gate review, no prior round · verdict APPROVED WITH CONDITIONS with 11 gate
conditions · findings F-1…F-11, no rollback · no finding id superseded`.

**Transcription check before writing** (nothing would have been written on any failure): contract
body begins with the gate-reviewer contract's declared opening line — verified verbatim against
`~/.claude/plugins/marketplaces/harness-kit-marketplace/agents/gate-reviewer.md:19` — and ends with
its `## Verdict` line; both header-named paths carried a portion; no partial return reported.
`03_GATE_REVIEW.md` and `03_RATIONALE.md` written **verbatim**, nothing added or repaired.

The gate did the two jobs it was dispatched for:

- **It re-derived stage 1's headline refutation first-hand** (A-1, rationale §1) through all five
  links — `PHASE_RULESETS=failed` → `sc reload` → `generate_config` deleting the empty
  `route.rule_set` and filtering **both** rule arrays → service already up → `install_report`'s
  success arm → exit 0. **Confirmed**: E1 is the correct assertion and T-01's AC-9's last two
  clauses are refuted. Q-3 and Q-4 also independently confirmed.
- **It caught the vacuous green at the gate rather than at QA** — the T-06 precedent. **F-1: E1's
  `pair=` is a restatement, not a control**, and E1's assertion is satisfied *identically by a
  completely unrestricted healthy install*. GC-1 replaces it with the step-6 rule-set-failure
  warning read from the same capture, which separates a **degraded** success from a healthy one.
  It also found E1 and E5 **agree rather than constrain** (F-5, via `PHASE_SERVICE=started` plus
  `Restart=on-failure`) → GC-4; and that the self-check's **positive** arm is not a guard at all
  (F-6) → GC-5.

Three further defects that would each have failed the test on correct code: **F-3** — `[6/7]` as a
`grep` pattern is a bracket expression matching any line containing `6`, `/` or `7` → GC-2 forces
fixed-string matching; **F-2** — `dns_refs≥0` is true of every possible document → GC-3; **F-7** —
nothing pinned when `$WORK` is created → GC-6.

**F-4 is mine (GC-8), and it is a live delivery hazard.** PM re-measured: `.harness/insight-index.md`
is **exactly 30** `wc -l` lines against F.4's 30 cap, and `docs/tasks.md` **exactly 300** against
F.5's 300 — both at the limit. The gate established what F.4 actually counts (`wc -l` over the
whole file, header included — `verify_all.sh:214-219`) and why `archive-task.sh`'s rotation cannot
protect it (it counts **bullets**; 30 bullets = 38 file lines — **R-18, a ninth confirmation**).
So one harvested insight or one board row at delivery turns `WARN 0` into `WARN 1`. Delivery must
rotate first, then harvest, then measure.

**AC-18 witness recorded at task start**: `MainPID=2566751`,
`ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` (`systemctl show`, never `is-active`).

Stage gate for stage 4 satisfied: stage 3 produced an explicit approval verdict.

### Stage 4 — developer (single-Developer mode) — round 1 — verdict `READY FOR REVIEW` — ADVANCE

Round record returned by the developer: `round 1 · C-1…C-5 implemented, verify_all unchanged at
17/0/0/1 · initial development pass · n/a (no prior finding)`. No rollback requested. Intervention
re-checked: **absent**.

Shipped `.harness/scripts/restricted-network-regression.sh` (new, `0755`) plus the two `docs/dev-map.md`
rows, the `rejected-decisions.md` record and the `CONTEXT.md` glossary entry. All eight discharged
gate conditions (GC-1…GC-7, GC-9) are cited line-by-line in `04_DEVELOPMENT.md`'s
`## Condition disposition`.

**PM-measured independently after stage 4** (not taken on the developer's report):
`bash .harness/scripts/verify_all.sh` → **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, unchanged from the
pre-stage-1 baseline. `git status` shows the diff confined to the ledger (`.harness/scripts/…sh` added,
`docs/dev-map.md`, `CONTEXT.md`, `.harness/rejected-decisions.md` modified; `docs/batches/**` is the
batch loop's and stays unstaged). Mode is `-rwxr-xr-x`. Live-service witness **identical** to task
start — `MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`; `is-active` never
invoked. Stage gate for stage 5 satisfied.

**Five design drifts reported, all recorded rather than worked around.** The load-bearing one is
**D-3**, and it is the most valuable thing this stage produced: **base 4 of `RULESET_BASES` is a byte
*suffix* of base 3**, so V-14's "a `failed:` line naming all four derived bases", implemented as the
obvious substring test, reports **4-of-4 on a log carrying 3** — a vacuous green of exactly the class
the gate was hunting, surviving into the stage the gate could not reach. E3 now matches at the entry
boundary; negative control measured 4 vs 3.

**D-2 is the open question this stage hands to stage 5**: the artifact is **317 lines against the
250-line cap** (the gate's own estimate was 240-265), with a measured comment-and-blank-stripped
floor of 259. GC-9 permits an overrun **recorded**, and nothing was dropped to make the number —
but rule 85 puts the burden of proof on the larger artifact, so the *judgment* on whether those
lines are earned is stage 5's, not stage 4's self-assessment. Routed explicitly.

### Stage 5 — code-reviewer — round 1 — verdict `ROLLBACK TO stage 4` — **ROLLBACK #1 (5 → 4)**

Round record returned by the reviewer: `round 1 · initial code review of C-1…C-4 · 1 MAJOR (CR-1,
BC-9's second clause unimplemented for E3/E4), 6 MINOR, 5 NIT · rule-85 overrun judged earned, no
refactor demanded · verdict ROLLBACK TO stage 4 for CR-1 only`.

**Transcription check before writing**: contract body begins with the code-reviewer contract's
declared opening line (verified against
`~/.claude/plugins/marketplaces/harness-kit-marketplace/agents/code-reviewer.md:19`) and ends with
its `## Verdict` line; both header-named paths carried a portion; no partial return. Written
**verbatim** to `05_CODE_REVIEW.md` and `05_RATIONALE.md`.

**CR-1 (MAJOR) — the fourth vacuous green, and the reason this rollback is correct.** BC-9's second
clause is implemented for E6 and forgotten for E3 and E4. On a VM where the recovery arm **runs and
every source is still unreachable** (`nrf=4, nok=0` — an entirely plausible disposable-lab state),
E4 prints `PASS` with `pair=rec_defs=0;rec_dns_refs=0` — a counter-observation whose two values are
**the same two numbers as the `obs=` it is supposed to falsify**. That is gate finding F-1's defect
verbatim, relocated to a different condition, and it is precisely the failure class this whole task
exists to prevent. Not CRITICAL only because E6 is BLOCKED in that same run, so the run still exits
non-zero. Reviewer's named fix is two tokens per guard and drops no element.

Routing per the rollback table: *reviewer finds code defect → developer*. Re-dispatched to the same
stage-4 agent (context intact) rather than a fresh one.

**Rule 85 was adjudicated, not deferred** (CR-2, MINOR): the reviewer spent the burden of proof
region by region and judged the **317-line overrun earned** — recoverable surplus is ~15-20 lines,
not ~50, and the binding floor (231 code + the 28-line I-15 guide GC-9 forbids trimming) is 259
*before a single comment*, i.e. **the 250 cap was unreachable by construction**. The fault is the
cap's provenance: the gate itself wrote F-11 saying the cap had no margin and K-10's "≤235 target"
was not credible — and then approved K-10 unchanged. No refactor demanded, and the counter-rule was
honoured (no future edit could be named that a smaller shape would prevent). → RES-5 to delivery.

The reviewer also independently re-verified **D-3** against the real emission sites (`bin/sc:3274`
builds `<base> -> <cause>`, `:3284` joins with `"; "`) and confirmed the boundary matcher both fixes
the 4-of-4-on-3 false pass **and** stays reachable on correct code. All five stage-4 drifts
adjudicated: **all accepted as shipped**, none the source of CR-1.

R-37 recorded a **sixth** time (RES-6).

### Stage 4 — developer — round 2 (rework) — verdict `READY FOR REVIEW` — return to stage 5

Round record returned by the developer, transcribed here:
`round 2 · widened BC-9 to E3/E4 via a single 'rblock' reason (:291-294, both reasons preserved);
added E5's no-agreement BLOCKED arm behind an 'agree' flag because the named [ $p5 = $prev5 ] fix is
provably a no-op; 'die' now emits the six-line report; declared D-6/D-7/D-8; corrected five
'## Condition disposition' citations and re-verified the rest · vacuous-green at E3/E4 was the
rollback cause, E5 was the last agreeing-rather-than-constraining pair, 'die' contradicted I-5, and
four cells cited lines that did not contain their construct · CR-1 (MAJOR, mandatory), CR-5, CR-3,
CR-4 (ruled), CR-6, CR-8, CR-11`.

**CR-1 fixed and proven non-vacuous in both directions.** One BC-9 reason computed once after the
recovery arm, gating E3, E4 **and** E6. Exercised over five synthetic recovery states: `nok=0,nrf=4`
and `nok=0,nrf=0` now print three BLOCKED lines where round 1 printed `E3 PASS` / `E4 PASS` with the
self-identical `pair=`; `nok=4` and `nok=2` still reach PASS, so **nothing was taken from a correct
run** — the failure direction a rushed fix would have introduced. The developer kept *two* reason
tokens rather than the reviewer's one, because E3/E4 carry no `nok` in `obs=` and an operator could
otherwise not distinguish "`sc` was never installed" from "`sc` ran and the network was still down".

**The most valuable thing this round produced is a refutation of the reviewer's own named fix**
(CR-5, → drift **D-6**): `[ "$p5" = "$prev5" ]` is **always true at both loop exits** — the loop
body's tail statement is `prev5="$p5"`, so the exhausted exit has just created the identity and the
break exit required it. Instrumented and measured (`p5=111 prev5=111 equal=yes` in the crash-loop
case). Shipped the working equivalent instead (an `agree` flag set at the break), checked over seven
read-sequences, and **deliberately kept a dead service reporting FAIL rather than BLOCKED** — a
product failure must not be laundered into a harness excuse. This is the stage-4-refutes-a-gate-answer
pattern that T-19 established, now applied to a code-review answer.

CR-3 taken; **CR-4 ruled and declined with a reason** (past gate 4 the missing-observation values can
only mean the *product* produced no unit, no log or an unparsable document — BLOCKED would hide three
real failures behind harness vocabulary); CR-8/CR-11 declared as drift (D-7, D-8); CR-2 respected, no
refactor attempted.

**PM-measured after round 2**: `verify_all` **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**. Diff still
confined to the ledger. Artifact now **330 lines** (+13: +4 CR-1, +9 CR-5). Live-service witness
**unchanged** (`MainPID=2566751`, same `ActiveEnterTimestamp`); `/etc/hosts` sha256 unchanged.
Intervention re-checked: **absent**.

### Stage 5 — code-reviewer — round 2 — re-review dispatched (RES-1)

RES-1 makes re-review of CR-1's fix mandatory before any `[VM]` run. Re-dispatched to the same
stage-5 agent (context intact); its round-2 body **replaces** the content at `05_CODE_REVIEW.md` /
`05_RATIONALE.md`, never appends.

**Round-2 verdict: `APPROVED WITH RESIDUALS`** (0 CRITICAL, 0 MAJOR; 3 MINOR, 5 NIT, none blocking).
Round record returned by the reviewer, abridged to its load-bearing clauses: `round 2 · re-reviewed
the 330-line artifact against round-1 findings CR-1…CR-12 and re-verified every GC discharge at its
shifted line · verdict moved from ROLLBACK TO stage 4 to APPROVED WITH RESIDUALS · CR-1 (the rollback
cause) verified closed in both directions at :293-294, including the partial-recovery path
(bin/sc:3295-3303 regenerates on any gain, so nok≥1 is the correct threshold); CR-3 closed at :68 on
all four die paths with GC-6 intact; CR-6 closed, twelve citations spot-checked; CR-8/CR-11 closed by
D-7/D-8; CR-4's ruling accepted; CR-5 WITHDRAWN — the developer's refutation is correct · three new
findings, none blocking: CR-13 MINOR, CR-14 NIT, CR-15 NIT · CR-2's rule-85 judgment re-stated
against 330 lines with the floor at 267: still earned, no refactor demanded · RES-1 closed; RES-2…RES-6
travel on`. Transcription preconditions re-checked (declared opening line, `## Verdict` ending, both
portions present); written verbatim, replacing round 1.

**The reviewer withdrew its own named fix, on the developer's measurement.** CR-5's
`[ "$p5" = "$prev5" ]` is a tautology at both loop exits because the loop body's tail is
`prev5="$p5"` — so the round-1 named fix would have changed no verdict on any input. The reviewer
says so plainly ("I described it as *well-defined on both loop exits*, which was true and was the
wrong property to check"), verified the shipped `agree`-flag mechanism in **both** failure directions
(a correct quiet install still PASSes at `settled_at=2s`; a dead service still reports FAIL, not
BLOCKED), and re-classified it as design fidelity row **D-6, accepted**. A downstream stage refuting
an upstream stage's named fix with a measurement is the outcome this pipeline is built for.

**CR-13 (MINOR, new) is the inverse hazard of CR-1 and is worth carrying**: `rblock` is tested
*before* E3/E4's own verdict, so on a no-egress VM a genuine product failure — including the `E3 FAIL`
that BC-10 mandates in so many words — reports **BLOCKED**, a harness excuse for a product fault.
Never a false green (`finish` exits non-zero on any non-PASS), so non-blocking; travels to stage 6 as
RES-4(b) to be read against the first real `[VM]` transcript.

Stage gate for stage 6 satisfied: stage 5 approved, stage 4's `verify_all` PASSes at the baseline.


### Stage 6 — qa-tester — round 1 — verdict `APPROVED FOR DELIVERY` — ADVANCE

Round record returned by QA: `round 1 · wrote 06_TEST_REPORT.md + 06_RATIONALE.md, appended
operator-obligation id 2 · discharged RES-2, RES-3, GC-5, GC-11 and reported AC-6…13 + AC-20/VM as
BLOCKED per AC-19/Q-15 · findings RES-2, RES-3, RES-4, GC-5, GC-11`. No rollback. Intervention
re-checked: **absent**.

**63 host observations — 12 PASS / 0 FAIL / 9 BLOCKED / 0 N/A.** E.6's unnumbered
`## Adversarial tests` heading is present at `06_TEST_REPORT.md:44` (the indexed trap avoided).

**The BLOCKED discipline held, at its largest instance yet.** Eight `[VM]` criteria reported BLOCKED
with reasons and a named recipe, **nothing substituted** — and where QA *could* discharge part of a
condition at unit level (AC-8/9/11), it labelled the row *"partly discharged at unit level, condition
still BLOCKED"* rather than letting a unit result stand in for a run. That is AC-19 honoured to the
letter and the R-31/R-41/R-47/R-52 precedent held a fifth time. It also wrote the recipe where a
standing human step belongs: `.harness/operator-obligations.md` **row 2** (R-1…R-6 plus the three
RES-4 readings). That file carries no C-row in the ledger; **accepted as a deliberate deviation** —
T-20 established the register at R-52 and a task-folder doc would have been archived away from the
human who must act on it. Recorded here rather than silently.

**QA reproduced the trap before trusting the tool.** It first confirmed gate finding **F-6** is
unrepaired as designed (`--self-check` prints `SELF-CHECK OK: 3 shipped base(s), all covered` and
exits 0 on a three-base source), so exit 0 was never accepted as evidence; it then discharged
**GC-5/RES-3** by comparing the four printed URLs against `bin/sc:113-118` with an **independent**
parser (`ast.literal_eval`, sharing no code with the artifact's `sed`+`grep`) — byte-identical, with
one-byte-edit and dropped-line negative controls. **GC-11** honoured exactly: AC-16 baselined against
a `git clone` (`.git` confirmed a *directory*), and all three `verify_all` `find` roots proved to
return `0 hits` for it **before** the counts were read.

**The tenth vacuous green was found** (D6-1, MINOR): `uncoverable()` accepts a **userinfo** authority,
so it reports "covered" for a base whose sunk name `u@cdn.example` is not the name any fetcher
resolves (`cdn.example`). Three further NITs (D6-2/D6-3 `--source`-only derivation defects; D6-4 —
the comment asserting the file has no CJK is the file's only CJK, falsifying I-15 and a line of
`05_CODE_REVIEW.md`). **0 BLOCKER / 0 CRITICAL / 0 MAJOR, and nothing fails an acceptance criterion.**

**D6-4 was deliberately not routed back to stage 4.** It is a NIT whose fix is a comment reword; a
fourth stage-4 round plus mandatory re-review to correct a comment is exactly the churn rule 85's
counter-rule forbids. Filed as **R-58** instead, with the falsified sentences named so no future
reader inherits them silently. Decided under the owner's standing grant.

Live-service witness identical at all 12 sample points; `/etc/hosts`, `nsswitch.conf`, `resolv.conf`
unchanged; `test/head-baseline` cleaned up (`test/` itself pre-existed).

### Stage 7 — delivery (PM)

**Entropy watch: SKIPPED, fail-open.** `.harness/scripts/entropy-cadence` **does not exist on this
host**, so `delivered` / `check` / `swept` could not run. Per the cadence's fail-open rule any I/O
problem resolves to **NOT-DUE** ⇒ no supervisor scan, no `## Entropy watch` section in
`07_DELIVERY.md`, delivery verdict unchanged. `.harness/scripts/task-state.js` likewise absent all
task (counters carried in this log instead). Both recorded, neither blocking.

**GC-8 discharged in the required order** — this was a live hazard, not a formality. AC-2 was measured
**before** any harvest or board edit (`PASS 17 / WARN 0 / FAIL 0 / SKIP 1`). Both caps then sat
*exactly* at their limit: `.harness/insight-index.md` **30/30**, `docs/tasks.md` **300/300**. So:

1. **Rotated three insight lines by hand** into `docs/features/_archived/insight-history.md` with a
   per-line "why rotated" (rule 70's *what no longer earns its line*, not oldest-first): the urltest
   demotion line (T-15 shipped; residual lives as R-21/R-49), the fixture-`CLASH_PORT` line (a
   narrower restatement of the `main()`-reassigns-`CLASH_PORT` line, which stays), and the
   `/dns/query` cache-warming line (carried in full by R-48). **R-18 confirmed a ninth time** —
   `archive-task.sh:85-95` counts *bullets* where F.4 counts *lines*, so its rotation branch cannot
   fire on any index carrying a header.
2. **Rotated `docs/tasks.md`** — completed rows first, per policy: T-21's completed row moved to
   `docs/tasks-archive.md`; that alone did not free the space T-07's row plus six open rows needed,
   so **T-13's R-9 … R-14 open block** followed it, with a pointer left in the "Rotated-but-open
   blocks" section stating plainly that **R-9 is live and T-07 did not claim it** (T-07 makes it
   *cheaper*, not done).
3. **Then harvested**: `archive-task.sh --task restricted-network-regression-test` took the 2
   insights and moved all 14 stage docs to `docs/features/_archived/`.
4. **Re-measured**: `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, with headroom restored — insight-index
   **29/30**, tasks.md **278/300**.

**Six open rows filed (R-56 … R-61)**, none dropped: R-56 = D6-1, R-57 = D6-2/D6-3, R-58 = D6-4,
R-59 = CR-13 (needs a *requirement* ruling, since it is a real K-11-vs-BC-10 collision, not just a
code edit), R-60 = the operator obligation, R-61 = the line-cap provenance plus CR-7/CR-14/CR-15 and
QA's fourth owed reading. Board pointers updated to record what T-07 **closed**: the `CURL_OPTS_*`
dev-map seam row (T-08 block) and T-02's BC-32 (by construction, in fact only on a `[VM]` run);
and what it **read and deliberately declined**: T-11's R-1…R-8, R-9, `baseline.json`/R-4.

**Rollback ledger: 1 total** (stage 5 → 4, CR-1). No stage was rolled back twice, so the
three-consecutive-rollback escalation never came near firing. No `BLOCKED: NEEDS-HUMAN` was raised:
the one candidate — "this cannot be executed end to end here" — is explicitly *not* a blocking
reason (Q-15/RS-5); it was delivered as eight BLOCKED criteria plus a named recipe.

**Final PM-measured state**: `verify_all` **PASS 17 / WARN 0 / FAIL 0 / SKIP 1** (fifth checkpoint);
diff 5 files **+355/−0**; product files byte-frozen; live service untouched
(`MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`).
`docs/batches/**` left unstaged — the batch loop's.
