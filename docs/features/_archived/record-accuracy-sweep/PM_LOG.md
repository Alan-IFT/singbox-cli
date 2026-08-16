# PM Log — T-32 `record-accuracy-sweep`

Mode: **full** (7 stages). Invoked by `/harness-batch`, pool `closeout`, **final row of the pool
and of the three-pool programme (20 tasks)**.

Goal: correct the eleven filed sentences that claim something the code does not do; add nothing else.

## Task-start checks

- `node .harness/scripts/task-state.js show record-accuracy-sweep` → **MODULE_NOT_FOUND, exit 1**.
  Handled fail-open, as every task since T-16 has (**R-88**: `task-state.js` and `entropy-cadence`
  do not exist on this host). No durable counter is available; rollback streaks are tracked in this
  log instead.
- `.harness/intervention.md` — **absent** at task start (checked before stage-1 dispatch).
- `.harness/agents/dev-*.md` — **directory does not exist** ⇒ **single-Developer mode**
  (`harness-kit:developer`), not partitioned.
- `docs/tasks.md` — **299 lines against F.5's 300 cap**. Rotation of *completed* rows into
  `docs/tasks-archive.md` is required before the T-32 row is added.
- `.harness/insight-index.md` — 30 lines (at rule-70's cap).

## Insight-index entries surfaced to downstream stages

Queried for the task's salient terms (loader recipe, `_init_files`, dev-map, os-shim, prose claim,
locale, README). Four entries apply and were passed **whole** into the stage-1 dispatch:

- `2026-08-16 · main()'s read-only enumeration at bin/sc:3769 gates _init_files() and
  _resolve_clash_port() only …` — directly load-bearing for **R-84**.
- `2026-08-16 · A sys.modules os-shim cannot deny a capability by attribute at all …` (T-31) —
  load-bearing for **R-77/R-78/R-84**, the loader recipe's safety property.
- `2026-08-16 · Every module imported before a sys.modules["os"] shim keeps the real os …` (T-31) —
  same.
- `2026-08-16 · CPython's backslashreplace has three spellings and only one of them is legal JSON …`
  (T-29) — the precedent for "a shipped sentence false of the code", cited as the standard.

## Stage transitions

| # | Stage | Agent | Verdict | Note |
|---|---|---|---|---|
| 1 | requirement | `harness-kit:requirement-analyst` | **READY** | round 1, no rework. Attrition **3/11**: R-77, R-78, R-84 already discharged. |
| 2 | design | `harness-kit:solution-architect` | **READY** | round 1, no rework. Seam found and built; ≤20 lines vs NFR-2's 30. Flagged RS-1 + RS-3 as upstream defects. |
| 3 | gate | `harness-kit:gate-reviewer` | **BLOCKED ON REQUIREMENT** | round 1. F-1 BLOCKER on AC-3 (safety). → **rollback #1 to stage 1.** |
| 1′ | requirement (rework) | `harness-kit:requirement-analyst` | **READY** | round 2. AC-3 + AC-9 amended in place; nothing else touched. |
| 3′ | gate (re-review) | `harness-kit:gate-reviewer` | **APPROVED WITH CONDITIONS** | round 2. F-1, F-2 closed at stage 1; F-9 closed by measurement; F-13 opened (NOTE); G-16 added. **Stage gate satisfied → stage 4.** |
| 4 | development | `harness-kit:developer` | **READY FOR REVIEW** | round 1, no rework. 26 changed lines vs NFR-2's 30; zero executable lines (identical ASTs). `verify_all` PASS. |
| 5 | code review | `harness-kit:code-reviewer` | **APPROVED** | round 1. 0 CRITICAL / 0 MAJOR / 2 MINOR (CR-1, CR-2) / 2 NIT. → **PM overrides to rollback #2 on CR-1.** |
| 4′ | development (rework) | `harness-kit:developer` | **READY FOR REVIEW** | round 2. CR-1, CR-2, CR-3 fixed + one self-found sibling. `bin/sc` byte-identical. 26/30 lines unchanged. |
| 5′ | code review (re-review) | `harness-kit:code-reviewer` | **APPROVED** | round 2. CR-1/CR-2/CR-3 **CLOSED**; CR-5, CR-6 opened, both **PM-owned at delivery**. 0 CRITICAL / 0 MAJOR. |

### Stage 1 → PM decisions

**Two facts in my own stage-1 dispatch were stale; the analyst caught both and I re-measured them
myself rather than take either on report.**

- `baseline.json:4` reads **`test_count: 19`**, not the 18 my dispatch carried (T-31 raised it in the
  same commit as its 19th assertion). **The analyst is right and my dispatch was wrong.** Q-7 binds
  downstream to 19; a criterion written against 18 would pass a lowered floor. Corrected in every
  dispatch from stage 2 on.
- `wc -l docs/tasks.md` = **299** (the analyst read 300). Immaterial — F.5's cap is 300 and the
  rotation obligation fires before anything is added either way.
- `.harness/rules/80-delivery-policy.md` is **89 lines** against F.2's 200 cap, so R-91's repair has
  ample headroom; no fragment split is needed.

**Ruling on Q-8 (R-98 and R-106(a)-(b)) — scope NOT widened, rows NOT orphaned.**

The board names **T-32** as owner of R-98 and R-106(a)-(c), they are the same class as the eleven,
and T-32 is the programme's final task — so declining them without a re-home would strand them. I
rule:

1. **They stay out of T-32's scope.** The operator's list is explicitly enumerated *and* carries a
   deliberate exclusion list (R-86, R-89, R-90, R-92) that does not mention them — that is a curated
   list, not an oversight I should silently correct. `.harness/rules/85-design-discipline.md`'s
   counter-rule is directly on point: *"consolidation re-homes scope between tasks, it never invents
   new scope."*
2. **The risk asymmetry decides the margin.** This is the batch's last row and a `verify_all` FAIL
   stops the batch. R-98's population is **six** sites (not the two filed) and R-106 adds four more;
   taking eleven extra prose edits — four of them in both READMEs — roughly doubles the change
   surface for rows that have a perfectly good re-home.
3. **They are re-homed at delivery with a live owner and with the analyst's corrected pricing**, so
   the next task inherits a better-characterised row than the one T-32 found. Recording that R-98(a)
   is six sites rather than two is a **task-board correction**, which is exactly this task's own
   thesis and is PM work at delivery — not a scope widening.

**Ruling on FR-10 / Q-5 (R-74): accepted as the analyst ruled it** — R-74 does **not** close here; it
stays open as a standing practice with no code owner, amended in place to record that T-32 swept its
eleven filed instances and that instance discharge is not row closure. I am not second-guessing the
substance (that is stage 1's to own); I record only that the brief demanded a *stated* ruling and one
was stated, with reasoning, as a numbered requirement rather than an aside.

**Ruling on FR-11 / Q-6 (no anti-drift mechanism): accepted.** The analyst argued it against both
precedents the brief named, on the merits and not by deference — nine of the eleven are semantic
assertions no committed check can decide, and the two that *are* counts already have a mechanism
(B.4 prints `N defined`, which AC-14 uses). The decline is recorded once in
`.harness/rejected-decisions.md` per rule 25.

### Stage 2 → PM decisions

Stage 2 returned **READY** (round 1, no rework) and reported **two upstream defects in
`01_REQUIREMENT_ANALYSIS.md` that it mitigated in the design rather than blocking on**:

- **RS-1** — AC-13's literal predicate ("`Path`-valued constants referenced only inside function
  bodies") yields **eight**, not nine: `docs/dev-map.md:33` omits `LIB_DIR` (the filed defect) *and*
  asserts of all its constants a property `CFG_DIR` does not have (`CFG_DIR` is read at module level
  six times, `bin/sc:24-27,32,38`). A count-only repair would ship a corrected sentence that is
  still false — the R-22 inversion landing on the requirement itself.
- **RS-3** — **a safety defect in AC-3's stated fallback.** AC-3 offers "run that historical copy on
  a scratch tree"; a pre-T-25 `bin/sc` still carries the import-time `os.execvp("sudo", …)` into the
  **installed** `/usr/local/bin/sc` — the exact R-78 near-miss that voided a T-25 round. The design
  forbids the run (V-3) and settles both sites by source order instead.

**Routing decision: advance to stage 3, do NOT roll back to stage 1 yet.** Reasons: (a) the gate is
the designed independent judge of requirement + design holistically, and a speculative rollback
spends a stage on a call the gate is about to make anyway; (b) the architect neutralised both in the
design (I-5, V-3) rather than carrying them forward silently — which is the disclosure behaviour
this project rewards. **I am tasking the gate explicitly with ruling on RS-1 and RS-3**, including
whether AC-3 must be amended by stage 1 *before* development starts. If the gate says yes, this
rolls back to the requirement-analyst; that is the first rollback and the streak counter starts at 1.

**Partition mode confirmed by stage 2**: single-Developer (`harness-kit:developer`); no
`.harness/agents/dev-*.md` exists.

### Stage 3 round record + PM decisions

Round record returned by the gate: `round 1 · first gate pass over 01/02 · eleven rows re-verified
against the tree with Read/Grep only, no Bash · verdict BLOCKED ON REQUIREMENT on finding F-1
(AC-3's fallback); F-2 optional in the same round; 02 needs no re-emission.`

The gate also noted that my dispatch named `APPROVED FOR DEVELOPMENT` (plan-mode vocabulary) while
every other signal stated the full pipeline. **My wording, its catch** — mode was never ambiguous and
it correctly used full-mode vocabulary rather than stopping on `BLOCKED ON MODE UNCLEAR`.

Both portions transcribed verbatim to `03_GATE_REVIEW.md` and `03_RATIONALE.md`. Pre-write checks
passed: the contract body opens with its declared line and closes with `## Verdict`; both
header-named paths carried a portion; no partial return reported. The gate's `# HEADER` transcription
instruction was **not** written to either file (it is addressed to me, not content).

**The gate overturned stage 2 on RS-3 and I am routing on its ruling, not stage 2's.** Stage 2 judged
a design-level prohibition (V-3/K-12) sufficient; the gate ruled the *criterion text itself* must be
amended, because `01`'s AC-3 affirmatively authorises an act that `01`'s own NFR-4 and BC-8 forbid —
a self-contradicting document whose safe reading requires the reader to already know
`bin/sc:125-126`. The precedent it cites is this project's own **R-110(a)**, filed today against the
requirement-analyst for exactly the pattern of scoping a false requirement sentence by gate condition
and never amending the text. On the batch's last row, against a live service, I agree without
reservation. **Rollback #1 → stage 1. Consecutive-rollback streak at stage 1: 1 of 3.**

**F-9 dissolves on measurement — the gate said so itself and was right to flag it.** The gate counted
`.harness/insight-index.md` at 31 *rendered* lines and predicted F.4 would WARN; I ran the real gate:

```
[F.4] insight-index.md <=30 lines ... PASS      wc -l = 30
[F.5] docs/tasks.md <=300 lines ... PASS        wc -l = 299
PASS: 20  WARN: 0  FAIL: 0  SKIP: 1   (exit 0)
```

**Task-start baseline is therefore `PASS 20 / WARN 0 / FAIL 0 / SKIP 1, exit 0`** — B.3 is the single
SKIP, and B.4/B.5/B.6 all PASS. This is measured by the PM on this tree, discharging G-11's
measure-don't-inherit requirement at the PM level; stage 4 still owes its own post-change run. The
design's V-17 expectation was right after all, and the gate applied Q-7's own principle to itself.

**Not routed back, settled by gate ruling** (recorded so QA does not re-open them): F-6 → **G-7**,
F-7 → **G-9**, F-11 → **G-12**, RS-1/F-8 → **G-8**/**G-10**. **F-10 and G-15 travel to me at
delivery as filed-row candidates**, not repairs.

### Stage 1′ (round 2) round records

- `round 2 · AC-3's execution fallback removed and replaced with a read-only + BLOCKED-and-file
  disposition · the fallback authorised an act with no containment — sc re-execs
  sudo /usr/local/bin/sc with the caller's argv at import to a hard-coded absolute path, so neither
  the historical copy nor the scratch tree is what runs, and 01 contradicted its own NFR-4 and
  BC-8 · F-1 (G-1)`
- `round 2 · AC-9 changed from stated ⊆ derivable to set equality, with the derivation's population
  bound to every doctor row the T-26 changelog entry names as changed · a lead stating a strict
  subset previously passed the criterion written to catch exactly that defect; FR-7 already demanded
  "the transitions the build can produce", so this aligns the AC with its FR rather than adding a
  demand · F-2 (G-2), population note from G-3`
- `round 2 · out-of-scope item 4 re-worded from "pending the PM's ruling" to "by the PM's ruling on
  Q-8: the scope is not widened" · the ruling landed; Q-8 itself untouched · no finding (permitted
  latitude)`
- `round 2 · 01_RATIONALE.md: added the argument for AC-9's two-directional comparison (§4), added
  §11 giving the first-hand evidence and the three reasons AC-3 had to be amended in text rather
  than scoped by condition, corrected §10's docs/tasks.md line count 300 → the measured 299 and
  recorded the PM's task-start verify_all baseline incl. F.4 PASS · non-binding reasoning belongs
  there, and §10 carried a figure the PM has since measured · F-1, F-2, F-9-adjacent fact`

**PM spot-check of the amendment** (I do not take a rework on report): AC-3 now reads *"No stage of
this task executes an `sc` — historical, current or installed — as a program … the act is refused
under NFR-4. Where source order cannot settle a site, that site's outcome is **BLOCKED and a row is
filed** per BC-8; nothing is substituted for it."* That is G-1's property, in text, in the document
QA reads. AC-5, AC-7, AC-13, AC-17 and FR-10 confirmed byte-identical to round 1 — the gate's rulings
were not re-opened.

**One consequence the analyst surfaced and I am carrying forward rather than burying**: AC-3 now
terminates at BC-8 where source order cannot settle a site, so **coverage of at most one FR-4 site
may end BLOCKED rather than verified.** FR-4's claim is prospective, so a BLOCKED site can only
weaken a claim the delivery may narrow — it never forces a stronger one. That is the correct
direction and is exactly the trade the R-31/R-41/R-47 precedent has taken ten times: report BLOCKED,
file the row, substitute nothing.

Re-dispatching stage 3 for re-review (round 2). Per the gate's own verdict, `02_SOLUTION_DESIGN.md`
is **not** re-emitted and the architect is not in this round.

### Stage 3′ (round 2) round record + PM decisions

`round 2 · re-review of the amended 01 only; 02 not re-emitted, architect not in this round · AC-3
verified to carry no execution clause and to terminate at BLOCKED-and-file per BC-8, AC-9 verified to
invert the comparison to set equality with its population bound to CHANGELOG.md:29's three rows, and
the five units reported unchanged verified against every quotation and characterisation in my round-1
record with no drift found · F-1 CLOSED, F-2 CLOSED, F-9 CLOSED by the PM's measurement, F-13 opened
(NOTE) on V-8's now-superseded one-directional observable, G-16 added to govern a FR-4 site that ends
BLOCKED · verdict APPROVED WITH CONDITIONS · F-1, F-2, F-9, F-13, G-16`

Both portions **replaced** (not appended) at `03_GATE_REVIEW.md` and `03_RATIONALE.md`. Pre-write
checks passed on both. The `# HEADER` transcription instruction was again not written to either file.

**Stage gate before stage 4 is satisfied.** `APPROVED WITH CONDITIONS` is stage 3's approval verdict;
G-1 is discharged and G-2…G-16 bind stage 4 and stage 6. Advancing to development.

**Two things the gate did that are worth recording as process, not just outcome.** It reported that
it could not byte-diff `01` between rounds (no `Bash`) and stated plainly what its re-read *does* and
*does not* establish — "your spot-check corroborates; I record it as corroboration, not as my
measurement" — which is the T-30 stage-5 standard applied to itself. And it closed **its own** F-9
against the PM's measurement, recording "V-17's expectation was right and my prediction of a WARN was
wrong". On a task about sentences that claim more than the evidence supports, a gate that marks its
own wrong prediction as wrong is the behaviour the task is about.

**G-16 is a genuinely new condition and I am carrying it into the stage-4 dispatch verbatim**, because
it closes a hole the *fix* opened: AC-3 quantifies over "each site the clause names", so a clause
naming zero sites satisfies it vacuously, and the new BLOCKED terminal mildly incentivises deleting an
unsettleable site rather than reporting it. G-16 requires both FR-4 sites to stay named and a BLOCKED
site to be filed with the `git show` that would settle it. The gate also ruled the BLOCKED terminal
**acceptable on those terms**, on four grounds — the strongest being that a BLOCKED site can only
weaken a claim, never manufacture one, so it is the one failure direction this task is structurally
safe against.

### Stage 4 → PM verification (stage gate before stage 5)

The gate before code review requires `verify_all` PASSED in the development doc. **I re-ran it myself
rather than read it out of `04_DEVELOPMENT.md`:**

```
PASS: 20  WARN: 0  FAIL: 0  SKIP: 1   exit 0
[F.2] PASS  [F.4] PASS  [F.5] PASS  [F.6] PASS
```

**Identical to the task-start baseline in every step.** `docs/tasks.md` **299 → 293** (rotation
performed, five pointer lines left behind, nothing closed by moving); `.harness/insight-index.md`
still 30; rule 80 89 → 93 and rule 50 141 → 140, both far under F.2's 200. `git diff --stat`:
**115 insertions / 39 deletions across 10 files**, of which `docs/batches/closeout/*` are PM-owned
and were already modified before this stage — **they stay unstaged at commit** per the batch policy.

**Stage gate satisfied → stage 5.**

Notable in the developer's round-1 report, carried forward for stage 5 and 6 to test rather than
accept: zero executable lines proved by **AST comparison** (15550 nodes, 113 top-level defs, same
order; exactly three string constants differ) rather than by eyeballing a diff; **both false filed
repairs refuted rather than shipped** (R-83's "four" → three, R-85's filed replacement wording
rejected and the transition set stated as an equality over all three probes); **neither FR-4 site
ended BLOCKED**, so G-16's terminal did not fire; and AC-14 was discharged **by reading rather than a
second import**, keeping NFR-4 strict.

**R-86 fired a sixteenth time** on the developer (heredoc containing no `rm`); bypass never set,
worked around with scratch-file scripts. `.harness/scripts/doc-query.js` absent (R-88 class), handled
fail-open. **G-14 and G-15 travel to me at delivery unrepaired**, as the gate directed.

### Stage 5 round record + PM decisions

`round 1 · stage 5 code review of T-32 record-accuracy-sweep, first pass · re-derived R-83's directive
set, R-85's transition set, R-94's Path enumeration, R-91's five tokens and R-63's consumer count
first-hand from the delivered tree rather than from 04_DEVELOPMENT.md · verdict APPROVED, 0 CRITICAL,
0 MAJOR, 2 MINOR (CR-1, CR-2), 2 NIT (CR-3, CR-4) · no finding id routed back as blocking`

Both portions transcribed verbatim; pre-write checks passed on both; the `# HEADER` block was again
not written to either file.

**I am overriding the reviewer's non-blocking disposition and routing CR-1 and CR-2 back to the
developer. Rollback #2 — stage 4, streak 1 of 3.** The reviewer APPROVED and rated both MINOR, and it
was right on severity: neither reaches a user, neither is false about code behaviour, and the tree is
compliant in both cases. My reason for spending the round anyway is narrower than severity:

- **CR-1 ships.** `.harness/rejected-decisions.md` is a **permanently committed project record**, not
  a stage document, and the delivered decline entry contains an enumeration that "does not partition
  any one population" — one clause untrue under *either* reading. A task named `record-accuracy-sweep`,
  whose thesis is that a sentence must be true of what it describes, cannot ship a false enumeration
  **inside the very record that declines a mechanism for catching false enumerations.** That is
  self-refuting, and a future sweep would re-discover it as a defect — the exact waste R-106(c) was
  written to prevent. This is R-74's own defect class, committed in the act of recording R-74.
- **CR-2 would corrupt the next stage.** `04_DEVELOPMENT.md:274` claims "no delivered document outside
  `baseline.json` now states the number", which is false of the tree (`docs/tasks.md:230-231` and
  T-32's own board row both state 19, both correctly and both authorised by E-10). Because V-12's
  stated observable repeats it, **a literal-minded QA would report AC-14 FAIL against a compliant
  tree.** I could paper over this in the stage-6 dispatch, but the honest fix is to correct the
  sentence rather than to route around it — and routing around it is precisely what this task exists
  to stop.

The round is cheap and low-risk: prose only, no code, no `verify_all` surface, two sentences plus one
drift row. **CR-4 I take as a filed-row candidate at delivery** (the reviewer offered it as one) — it
is T-31's record of what T-31 observed, outside R-94's declared population, and correcting another
task's past-tense observation is scope this task does not own.

### Stage 4′ (round 2) round records

1. `round 2 · .harness/rejected-decisions.md:783-794 — the decline's Why enumeration now partitions
   ONE named population and says which: counting rows, eleven = nine semantic claims + R-94 (the one
   row about a copied count) + R-74 itself. Within R-94 it switches population explicitly ("counting
   its clauses"): the total stood in three documents outside baseline.json, two deleted and the third
   corrected to 19 and still standing. Substance unchanged; bullet 14 → 19 lines · CR-1`
2. `round 2 · .harness/rejected-decisions.md:780-782 — taken under standing decision authority beyond
   the three fixes: the Decision bullet read "T-32 corrected eleven filed sentences", the same
   false-enumeration class as CR-1 two lines below it. Now "swept eleven filed rows … seven sentences
   corrected, three rows found already discharged and edited nowhere, R-74 amended in place" ·
   CR-1 (same defect class, same record)`
3. `round 2 · 04_DEVELOPMENT.md Open issue 4 — over-claim replaced by what is true of the tree; I-6's
   and V-12's absolute phrasing named as false of a compliant tree, with AC-14 to be read against the
   tree. 02's I-6 vs E-10 tension recorded as upstream, not repaired · CR-2`
4. `round 2 · 04_DEVELOPMENT.md ## Design drift — new row D-6 for I-10's three-bullet shape vs the
   delivered four; bullet kept because it discharges G-12 · CR-3`
5. `round 2 · 04_DEVELOPMENT.md verify_all section + new Open issue 7 — a new measurement, not a
   rework: the live sing-box instance is no longer the one round 1 witnessed · no finding id`

**I accept round-record item 2**, the fix the developer took beyond its brief. It is the same defect
in the same record two lines from the one I routed back, and leaving it would have re-created CR-1
immediately. Correctly disclosed as a scope call with an offer to revert, which is the right way to
take one.

### The live service restarted, and a figure this programme carried in every dispatch is now false

The developer surfaced this rather than quietly re-witnessing, and **I re-measured it myself**:

```
MainPID=1776263        (dispatch figure: 2566751)
ActiveEnterTimestamp=Mon 2026-08-17 00:44:47 CST   (dispatch figure: Tue 2026-08-11 12:13:57 CST)
ExecMainStartTimestamp=Mon 2026-08-17 00:44:47 CST
NRestarts=0   Result=success
/etc/sing-box      mtime 2026-08-11 12:13:57  (UNCHANGED)
/var/lib/sing-box  mtime 2026-07-30 12:59:24  (UNCHANGED)
uptime -s          2026-07-30 23:38:28        (no reboot)
```

**This pipeline did not do it, and the evidence is positive rather than merely absent.** Every stage
here was read-only with respect to the service; `is-active` was never invoked; and the decisive
witness is that **`/etc/sing-box`'s mtime has not moved since 2026-08-11** — `sc reload`, `sc on` and
`sc update-rules` all regenerate `config.json` and would have moved it. `NRestarts=0` with a fresh
`ExecMainStartTimestamp` and no reboot is the signature of an external stop/start, not of a
`Restart=` policy firing. Most likely the owner acting on the standing **R-30** obligation, or a
package/binary update.

**AC-21 is unaffected**: its claim is that *this task* left the host untouched, and every run's
before/after pair is identical. What is now **false** is the *programme-level* invariant my own
dispatch asserted — "`MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`, unchanged
across all three pools". **I will report that at delivery rather than repeat the stale figure**, which
is precisely this task's own thesis applied to the task's own brief: a number carried forward in
every dispatch is still a claim, and it has to be true of the system when it is written. Stage 6 is
instructed to **re-take the host witness rather than inherit either figure.**

### Stage 5′ (round 2) round record + PM decisions

`round 2 · Re-reviewed the two changed files only and spot-verified the unchanged claim at every
round-1 coordinate reachable without a shell. CR-1 CLOSED — the replacement enumeration partitions one
named population (rows: 9 + R-94 + R-74), switches population explicitly for R-94's clauses, and every
number is true of the tree; B.6 verified as a real committed-floor ratchet at verify_all.sh:116-134;
the decline's substance is intact and its two partitions cross-check to the same eleven. CR-2 CLOSED —
04's Open issue 4 now states what is true of the tree and names I-6/V-12's absolute phrasing as false
of a compliant tree, which disarms the stage-6 AC-14 trap. CR-3 CLOSED — D-6 exists with the same shape
as D-1…D-5. CR-4 unchanged as instructed. Two NEW findings, both PM-owned at delivery: CR-5 (MINOR) and
CR-6 (NIT), both in docs/tasks.md:16. Three residuals added: RES-8, RES-9, RES-10. Verdict APPROVED ·
CR-1, CR-2, CR-3, CR-4, CR-5, CR-6`

Both portions **replaced**; pre-write checks passed; the reviewer's `# Header` block and its
```markdown fences are message-level delimiters and were **not** written into either file — the bodies
begin at their declared opening lines, exactly as returned.

**The re-review earned its round.** The reviewer did not merely accept the new enumeration; it
**cross-checked the record's two partitions against each other** (rows: 9 semantic + R-94 + R-74 = 11;
and 7 corrected + 3 discharged + R-74 = 11, refining to the same eleven), and it **verified the one
genuinely new claim** the fix introduced — that B.6 is a real committed-floor ratchet — at
`verify_all.sh:116-134` rather than taking it on the developer's word. That is exactly why I spent
the round: the fix for a false enumeration was itself a new enumeration.

**I discharged two of RES-9's shell-owed items myself** (the reviewer correctly marked them owed
rather than certifying them): `sha256sum bin/sc` = **`0afdc3b69307defc5e49f81cb148c5124b8b469ebb6dc77fe4dc23bf2f11b669`**,
matching the developer's reported `0afdc3b6…f669`; and `git diff --stat` confirms `docs/tasks-archive.md`
at +38/-0 and `docs/tasks.md` at +32/-20, both unchanged since stage 4 round 1.

**CR-5 and CR-6 are mine, and I accept both.** Both are in `docs/tasks.md:16` — T-32's own delivery row,
whose final wording `04`'s Open issue 3 already assigns to the PM. CR-5 is the sharper of the two and
is this task's defect class landing inside this task's own delivery record: the row still names
`MainPID 2566751` as the witness, which the delivery's own final run contradicts. I fix both while
writing the row at stage 7 — **not** by a third developer round, which the reviewer explicitly argued
against and which I agree would be waste.

**Stage gate before stage 7 requires stages 5 and 6 both PASS.** Stage 5 is APPROVED. Advancing to
stage 6.

### Stage 6 → PM decisions

Verdict **APPROVED FOR DELIVERY**. `## Adversarial tests` present verbatim (E.6 PASS, grep count 1).
`verify_all` run four times, step lines byte-identical.

**QA closed the one thing two prior stages had left open as unexplained.** Stage 4 and stage 5 both
recorded the service restart as "something outside this pipeline — no explanation". QA identified it
**read-only**: `sing-box-rules-update.timer` `LastTriggerUSec=Mon 2026-08-17 00:44:43`, running
`/usr/local/bin/sc update-rules`, `ExecMainExitTimestamp=00:44:47` — the unit's own
`ActiveEnterTimestamp` — with all four `.srs` at mtime `00:44`. **This project's own weekly rule-set
timer restarted the service.** Negatives checked too: binary, unit file and installed `sc` mtimes
unmoved, `/etc/sing-box` unmoved, `NRestarts=0`, no reboot. That converts a loose end into the
delivery's best insight, and it is the correct discharge of RES-8.

**QA reported four criteria NOT-DISCRIMINATING rather than passed** — including **AC-19 itself**.
Mutant T-2 (the AAAA sentence's advice inverted, false of the code at all three sites, placeholders
preserved) produces a **byte-identical verdict** from B.4, `py_compile`, the folded-AST identity, the
placeholder equality and a full `verify_all`. This is the honest and important result of the task:
when the artifact *is* the deliverable, the machine goes blind, and what decided truth here was
first-hand re-derivation at stages 3, 5 and 6 independently. **17 `bin/sc` mutants run / 17 killed /
0 survivors; 9 document mutants run / 9 killed; 0 BLOCKED.** QA also disclosed **a false kill in its
own checker** (`chk_ac9` matched the wrong `CHANGELOG.md` line), caught and fixed before reporting —
the T-31 standard.

**Two QA corrections I accepted against my own figures**: `docs/tasks.md` is **+13/−19**, not the
"+32/−20" I read off `git diff --stat` (32 is the combined change bar, not insertions), and AC-14's
"read B.4's `N defined` line from a run" leg is **not executable as written** — B.4 prints it only on
FAIL — discharged via `--list` instead. QA declined to commit its reproducers, correctly: FR-11
declines every mechanism and AC-18 forbids adding a check, so committing a harness would fail the
criterion it checks. `baseline.json` therefore not raised; floor stays 19.

### Stage 7 — delivery

- **Both PM-owned corrections applied** to `docs/tasks.md:16`: **CR-5/QA-1** (the row named the dead
  `MainPID 2566751` as its witness — replaced with the measured `1776263` / `Mon 2026-08-17 00:44:47`
  **plus** the timer explanation) and **CR-6/QA-3** ("eleven filed *sentences*" → "eleven filed
  **rows** … seven sentences corrected, three already discharged, R-74 amended").
- **Rotation before adding**, per BC-6/K-10/G-13: the board was at 293/300 with six rows to file. I
  rotated the **T-06 block (R-42 … R-47)** to `docs/tasks-archive.md` under the existing
  "Still-open rows rotated for space (NOT closed)" section, with a pointer bullet on the board.
  **Nothing was closed by moving.** Board ends at **297/300**, F.5 PASS.
- **Six rows filed: R-112 … R-117**, including **R-117**, which re-homes R-98 and R-106(a)-(b) — whose
  owner was T-32, the programme's final task — carrying stage 1's corrected pricing so the next task
  inherits a better-characterised row than T-32 found (R-98(a) is **six** sites, not the two filed).
- **Entropy watch: NOT-DUE.** `.harness/scripts/entropy-cadence` does not exist on this host (R-88).
  Resolved fail-open per the cadence's own rule, so **no scan ran and no `## Entropy watch` section
  was written**. Recorded, not silently skipped.
- **`archive-task.sh` rotation fired correctly — the sixth independent confirmation** after T-27's
  fix and T-28/T-29/T-30/T-31: `Harvested 5 insight(s)` → `Rotating 5 old insight(s) to
  insight-history.md` → index at **exactly 30 lines**, F.4 PASS, **no hand-rotation**. Exit 0.
- **Final `verify_all`: PASS 20 / WARN 0 / FAIL 0 / SKIP 1, exit 0** — identical to the task-start
  baseline at all four PM checkpoints.
- **Commit**: `git commit -F` from a scratch file (**R-86**, sixteenth instance); `HARNESS_ALLOW_OUTSIDE_RM`
  never set. `docs/batches/closeout/*` left **unstaged**.

**Rollback ledger: 2 total, no stage rolled back twice in a row** — stage 1 once (gate F-1), stage 4
once (PM override on CR-1/CR-2). The three-consecutive-rollback stop was never approached.
