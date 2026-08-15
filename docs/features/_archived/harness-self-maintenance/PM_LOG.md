# PM Log — T-27 / harness-self-maintenance

Mode: **full** (7 stages). Pool: `followups` (`docs/batches/followups/BATCH_PLAN.md`).
Dispatched by `/harness-batch` — **deferred-human mode: defer, do not ask**.
Decision authority: standing («你来决策就行»). Only a genuine safety red line or a
*proposed* `.claude/settings.json` change is surfaced rather than applied.

## Task-start state

- `.harness/scripts/task-state.js` — **absent on this host** (`ls .harness/scripts/` confirms).
  Handled fail-open, as every task since T-16 has; stage/rollback counters are kept in this file.
- `.harness/scripts/entropy-cadence` — **absent**. Delivery-time entropy watch therefore resolves
  **NOT-DUE** by the documented fail-open rule: no scan, no `## Entropy watch` section.
- `.harness/intervention.md` — **absent** at task start (checked before stage 1 dispatch).
- Baseline `bash .harness/scripts/verify_all.sh`, run from repo root at `d849234`:
  **PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — matches the dispatch's independently measured baseline.
- Working tree clean apart from `docs/batches/followups/BATCH_{PLAN,LOG}.md` (the batch loop's own,
  left unstaged by policy — and the very fact R-36 is about).

## Insight-index entries surfaced to downstream

Queried `.harness/insight-index.md` (22 bullets / 30 lines) for this task's salient terms
(`verify_all`, `insight-index`, `archive`, `harness`, `rules`). One entry applies:

- 2026-08-15 · `.harness/scripts/verify_all.sh` resolves its checks through **relative** paths, so run from any subdirectory it self-reports `PASS 4 / FAIL 4 / SKIP 10` — a false red that looks like a product regression and is purely the caller's cwd; it must be invoked from the repository root · evidence: share-url-userinfo-contract

The remaining 21 entries are `bin/sc` runtime facts; this task is expected to produce **no
`bin/sc` diff at all**, so they are not surfaced.

## Stage transitions

| # | Stage | Agent | Round | Verdict | Route decision |
|---|---|---|---|---|---|
| 1 | 1 — Requirement analysis | `harness-kit:requirement-analyst` | 1 | READY | Advance to stage 2. |
| 2 | 2 — Solution design | `harness-kit:solution-architect` | 1 | READY | Advance to stage 3. |
| 3 | 3 — Gate review | `harness-kit:gate-reviewer` | 1 | **ROLLBACK TO STAGE 2** | Rollback #1. Routed to **stage 1 first** (F-2/F-4/F-5/F-8 are `01`'s clauses; downstream may not edit upstream), then stage 2 (F-1 BLOCKER, F-3, F-5, F-6, F-7, F-9, C-1). |
| 4 | 1 — Requirement analysis | `harness-kit:requirement-analyst` | 2 | READY | Corrected in place; hand to stage 2 round 2. |
| 5 | 2 — Solution design | `harness-kit:solution-architect` | 2 | READY | Corrected in place; re-gate (stage 3 round 2). |
| 6 | 3 — Gate review | `harness-kit:gate-reviewer` | 2 | **APPROVED FOR DEVELOPMENT** | Stage gate satisfied. Advance to stage 4 (single-developer mode). |
| 7 | 4 — Development | `harness-kit:developer` | 1 | READY FOR REVIEW | `verify_all` PASS 17/0/0/1. Advance to stage 5. |
| 8 | 5 — Code review | `harness-kit:code-reviewer` | 1 | **CHANGES REQUESTED** (0 CRITICAL, 1 MAJOR) | Not a rollback — the reviewer says so explicitly. Route CR-1 + CR-3 to the **developer** (round 2), then re-review. |
| 9 | 4 — Development | `harness-kit:developer` | 2 | READY FOR REVIEW | CR-1 clause + CR-3 addresses landed; `verify_all` PASS 17/0/0/1. Re-review. |
| 10 | 5 — Code review | `harness-kit:code-reviewer` | 2 | **APPROVED WITH CONDITIONS** (0 CRITICAL, 0 MAJOR) | Stage-5 gate satisfied. RES-10 to developer (round 3) **in parallel** with stage 6 dispatch. |
| 11 | 4 — Development | `harness-kit:developer` | 3 | READY FOR REVIEW | Documentation-only (RES-10). No code touched; no re-review required (stage 5 said so). |
| 12 | 6 — QA | `harness-kit:qa-tester` | 1 | **PASS WITH RESIDUALS** | Stages 5 and 6 both pass → stage 7. |

### Round records

- **Stage 1, round 1** · initial contract + rationale written · defects re-verified first-hand by
  reading (`archive-task.sh:85-94` vs `verify_all.sh:213-219`; index 30 lines / 22 entries / 8 header
  lines; rule 70 at 91 lines with no boundary rule; T-19's AC-S3 at
  `ruleset-staleness-visibility/01_REQUIREMENT_ANALYSIS.md:149` against the existing
  `docs/batches/followups/BATCH_{PLAN,LOG}.md`) · covers R-18, R-36, R-37 plus rulings on
  `guard-rm.sh`, `task-state.js`/`entropy-cadence`, the `.ps1` mirrors, and rule 05's `summary.md`
  claim.

### PM notes — stage 1

- Intervention check before stage 1 dispatch and after stage 1 completion: **no
  `.harness/intervention.md`** present either time.
- Stage 1 delivered FR-1…FR-11, BC-1…BC-12, AC-1…AC-16, OQ-1…OQ-10. Eight criteria are declared
  discriminating (**AC-1, AC-5, AC-7, AC-9, AC-11, AC-12, AC-13, AC-15**); the rest are labelled
  controls in the document itself, which is the R-22 discipline the dispatch asked for.
- Four scope rulings accepted as within the analyst's authority and recorded: `guard-rm.sh` **out**
  (OQ-1, argued from `75-safety-hook.md:86` documenting the parse-failure BLOCK as designed
  behaviour, plus risk class), `task-state.js`/`entropy-cadence` **out** and explicitly *not* the
  same class (OQ-2), the `.ps1` mirrors **not** edited (OQ-4), rule 05's `summary.md` claim
  **filed, not fixed** (OQ-7).
- OQ-3 binds the committed-diff path list to `.harness/rules/80-delivery-policy.md`. Stage 2 may
  move it only by satisfying every FR-8 clause and saying why; a **new** fragment is excluded.
- Sizes: `01_REQUIREMENT_ANALYSIS.md` 204 lines, `01_RATIONALE.md` 157 — both well under the
  500-line stage-doc cap (F.6 PASS).

### PM notes — stage 2

- **Stage 2, round 1** · initial design written · no prior findings.
- Intervention check after stage 2 completion: **absent**.
- Edit ledger: **E-1** `archive-task.sh` +9/−3 (the entire executable diff), **E-1b** conditional
  +1/−1 (`:82`'s `set -e` AND-list aborts a `--dry-run` with no index — pending a stage-3 ruling as
  RS-1), **E-2** rule 70 +32/−1, **E-3** rule 80 +30/−0, **E-4** `AI-GUIDE.md` +1/−1. Total
  ≈ +73/−6 with **9 executable added lines**; no new function, file, script, fragment, hook or
  `verify_all` step; **no `bin/sc` diff proposed**, as required.
- **Durability ruling: (a)** — local fix plus a record outside the vendored file whose
  re-application path is `git`. Grounded on a first-hand reading of `upgrade-project.sh:186-194`
  (`archive-task.sh` is in `refresh_set`) and `:210-226` (unconditional `cp` on any difference, no
  marker preservation, no backup): the next `/harness-upgrade` deletes **both** local fixes — the
  rotation fix loudly (F.4 WARNs), the join fix silently. (b) a detector/digest gate rejected as
  strictly weaker than `git diff` and barred by BC-11; (c) upstreaming filed as RS-6; (d) removing
  the dependence rejected.
- Smaller alternative rejected is present in the contract portion (per R-37's own logic) and is
  the *right* one to argue: add the header size as a constant (`+8`, zero added lines). Rejected
  because 8 is a fact about today's header, not about the cap. Stage 3 must **test** that answer.
- Flagged as not-yet-discharged: **AC-15** (observes the delivery run itself — reachable only at
  stage 7, and RS-4 forbids a hand-rotation if it fails), **AC-9/AC-11** (derivation steps, not
  just checks), **RS-1** (needs the gate's include-or-file ruling).
- Architect's observation against `01`: FR-3's dry-run clause combined with BC-1 is unsatisfiable
  at HEAD because of the `set -e` AND-list at `archive-task.sh:82`. Correctly handled as a
  conditional edit rather than by re-opening stage 1 — **no rollback**.
- Sizes: `02_SOLUTION_DESIGN.md` 399 lines, `02_RATIONALE.md` 137 — under the 500-line cap.
  `.harness/rules/80-delivery-policy.md` is 53 lines today; E-3 takes it to ~83, well under F.2's
  200.

### PM notes — stage 3 (round 1) · ROLLBACK #1

- **Stage 3, round 1** · first gate round, no prior round to correct · 10 findings (F-1 BLOCKER,
  F-2…F-6 MAJOR, F-7…F-10 MINOR), 9 binding conditions C-1…C-9 · verdict `ROLLBACK TO STAGE 2` ·
  driving finding F-1.
- **Transcription:** the gate holds no write capability. Its returned body was written verbatim to
  `03_GATE_REVIEW.md` and `03_RATIONALE.md`; both portions were present and complete (contract
  opens with its declared `> Contract portion.` line and ends with `## Verdict`), so both were
  written. Nothing added, nothing repaired.
- Intervention check after stage 3: **absent**.
- **The BLOCKER is real and load-bearing.** F-1: the durability ruling was derived without opening
  the artifact `/harness-upgrade` actually copies. `upgrade-project.sh:56` resolves the refresh
  source to harness-kit **0.47.0**'s template `archive-task.sh`, a **425-line rewrite** — not a
  near-copy of the vendored 151-line file. It already harvests wrapped bullets as multi-line
  entries, already clamps `rotate_count`, already replaced the `grep -v` header filter, and already
  fixed the `[[ … ]] && touch` line, **while still deciding rotation on entries** (`:333`). B-3 as
  designed would therefore ship **two false instructions into a rule fragment** — exactly the defect
  class this task exists to close. Rollback accepted without question.
- **Routing.** Stage 1 owns AC-7 (F-4/C-4), AC-9 (F-5/C-5), AC-5 (F-8) and FR-5/AC-13 (F-2);
  stage 2 owns F-1, F-3, F-6, F-7, F-9 and C-1's unconditional E-1b. Downstream cannot edit
  upstream, so **stage 1 runs first**, then stage 2, then the gate re-runs. Consecutive rollbacks
  at stage 3: **1** (limit 3).
- Rule-85 test outcome recorded: the gate **confirmed** the architect's rejection of the `+8`
  constant and strengthened the reason (the count is a whole-file `grep -v`, so any stray non-bullet
  line shifts it — upstream reached the same conclusion at `0.47.0:382-385`), but **moved the
  pricing** of B-1's 10-line unit table: the cited discharge (AC-9) fails against a degenerate rule.
  Two deletions are now on the table.
- **AC-7 reported NOT-DISCRIMINATING** — HEAD's dry run reports `Rotated 0` and HEAD's wet run also
  rotates 0, so both clauses hold at HEAD. This is the third R-22 shape: a clause defined relative
  to its own run. Precedent held (T-24, T-25 both reported NOT-DISCRIMINATING rather than passed).

### PM notes — stage 1 (round 2)

- **Stage 1, round 2** · rewrote AC-7, AC-5, AC-9, AC-13 and FR-5; added BC-13 and OQ-11; corrected
  FR-6(c), BC-11, OQ-6; added out-of-scope item 10 · because three criteria did not discriminate (a
  self-referential count, a clause any `echo` satisfies, a count a degenerate rule scores 0/0 on)
  and one stated a property the real refresh source makes unsatisfiable · findings F-4/C-4, F-8,
  F-5/C-5, F-2, plus the scope ruling the gate declined to make.
- Intervention check after stage 1 round 2: **absent**.
- **New scope ruling (OQ-11): adopting the upstream 0.47.0 refresh is OUT of T-27, filed as its own
  pool row.** Four reasons, and the analyst declined the two cheap ones: it does **not** fix R-18
  (0.47.0 still decides on entries at `:313`/`:333`, and there one entry may span several index
  lines, so the divergence is *wider*); it replaces the program every criterion of this task
  measures, destroying AC-16's "metric not algorithm" bar and NFR-1's single-digit executable diff
  rather than arguing them; the mechanism cannot be taken selectively (`refresh_set` carries
  `archive-task.ps1` too, which OQ-4 froze and AC-14 pins); and it is an owner/PM action that
  changes the harness under a running pipeline. Explicitly **not** justified by "the rewrite is
  worse" — four of its behaviours are better — and explicitly **not** by the no-meta-tooling bar.
  The honest cost of declining is recorded rather than hidden. I accept the ruling: it is a scope
  call the analyst owns, and it is argued rather than defaulted.
- FR-5 now states a **property with teeth that survives a wholesale replacement**: per fix, the
  observable, loud/silent, **a check to run against the replacement text**, and **an action per
  verdict** — and it explicitly leaves "keep the replacement" admissible for the join fix. BC-13
  bans version-frozen prose, which is the F-1 defect class stated as a rule.
- Sizes after round 2: `01_REQUIREMENT_ANALYSIS.md` 224, `01_RATIONALE.md` 260 — under the cap.

### PM notes — stage 2 (round 2)

- **Stage 2, round 2** · re-derived the durability ruling against the 425-line refresh source;
  rewrote B-3 as a check-per-fix; **deleted** B-1's 10-line unit table; corrected I-1; made E-1b
  unconditional; deleted three invented H2 sections; corrected RS-6; trimmed B-2 · because the
  ruling and B-3 were derived from an artifact never opened, and three smaller texts were shown to
  be sufficient · findings F-1, F-3, F-5, F-6, F-7, F-9 and conditions C-1, C-2, C-3, C-5, C-6,
  plus PQ-2/PQ-3/PQ-6.
- Intervention check after stage 2 round 2: **absent**.
- **The BLOCKER is answered by re-derivation, not by argument.** The architect read the 425-line
  template end to end. New ruling is still **(a)**, but its content changed shape entirely: the
  record is a **check per fix**, not a restore path, and the standing instruction is **keep what
  arrives**. `git checkout -- <path>` is gone as a mechanism; `git log -p` survives only as a source
  of prior bytes. Under it, the next `/harness-upgrade` yields *metric = lost* (one bounded edit)
  and *join = already provided* (change nothing) — four upstream fixes kept, nothing discarded, and
  **neither verdict written into the rule** (BC-13).
- **Rule 85 produced a deletion, which is the outcome the rule prefers.** AC-9(b)'s seven witnesses
  all route correctly under FR-6(a)'s bare test plus FR-6(b)'s precedence clause, so the final
  clause fired and **B-1's per-kind table was deleted**: B-1 30 → 18 lines, rule 70 ~123 → ~111.
  Round 1's `measurement obligation → contract` row was also simply **wrong** (T-26's witness at
  `doctor-rows-establish-their-fact/01_REQUIREMENT_ANALYSIS.md:215` routes it to rationale).
- Design is now **≈ +59 / −6 with 8 executable added lines** (was ≈ +73/−6 with 9), inside NFR-1's
  single-digit bar even with E-1b unconditional. Three invented H2 sections in `02` were deleted
  (~40 doc lines) rather than legalised — F-6 resolved the direction FR-6(d) forces.
- Architect flags **RS-10** for the gate: B-1 ships *without* the per-kind list on the architect's
  own reading of AC-9(b)'s final clause. That is exactly the kind of self-scored call the gate
  exists to test, and it is named in the re-gate dispatch.
- Sizes: `02_SOLUTION_DESIGN.md` 369 (was 399), `02_RATIONALE.md` 259.

### PM notes — stage 3 (round 2) · APPROVED

- **Stage 3, round 2** · verdict moved `ROLLBACK TO STAGE 2` → `APPROVED FOR DEVELOPMENT`;
  F-1…F-9 and C-1/C-2/C-4/C-5 dropped as discharged, C-3 extended to a third fixture,
  C-6…C-9 carried, F-10 carried, seven new findings F-11…F-17 filed with C-10…C-14 · because
  B-3's two checks were run first-hand against harness-kit 0.47.0's template and returned the
  claimed verdicts, and all 40 requirement ids were traced through the re-homed coverage mapping.
- **Transcription (round 2):** both portions returned complete; content at
  `03_GATE_REVIEW.md` and `03_RATIONALE.md` was **replaced**, not appended. The trailing
  "transcription instruction / round record / summary" block of the agent's message is final-message
  content, not document body, and was not written into the file. Round record lands here only.
- Intervention check after stage 3 round 2: **absent**.
- **Stage-gate precondition for stage 4 is satisfied**: explicit `APPROVED FOR DEVELOPMENT`.
- **The gate did the work it was asked to do rather than accepting the rework.** It re-ran B-3's two
  checks itself against the 425-line template (verdicts *lost* / *already provided* reproduced), and
  it **re-derived RS-10 independently** — confirming the ten-line table stays deleted but finding
  that the routing which authorises the deletion is **not** the one `02_RATIONALE.md` gives
  (`measurement obligation → **contract**`, not rationale). C-11 binds the correction so stage 6
  cannot reinstate a false row.
- **All eight discriminating criteria now discriminate** — including AC-7, which round 1 reported
  NOT-DISCRIMINATING. None reported NOT-DISCRIMINATING this round.
- New MAJORs are all stage-4/5/6 conditions, not rollbacks: **F-11** (B-3's "every vendored
  script … no backup" is false of `verify_all.{sh,ps1}` — `upgrade-project.sh:136-141`, `:548-556`;
  C-10 authorises the bounded wording fix and overrides K-12 for that clause only), **F-12** (the
  mis-cited witness; C-11), **F-13** (a **third** divergence shape — final line a non-bullet line —
  satisfies I-1's `iff` and still diverges, silently deleting content; C-3 adds the fixture).
- Gate's one recommended deletion, carried into the stage-4 dispatch: B-1 clause (d)'s em-dash home
  enumeration, which names no home for stage 1 or stage 3 (C-14).
- Consecutive rollbacks at stage 3: reset to **0** (one rollback total this task).
- **Partition check:** `.harness/agents/` does not exist on this project → **single-developer mode**;
  stage 4 dispatches the plugin `harness-kit:developer`. (`verify_all` E.3 PASSes on that layout.)

### PM notes — stage 4

- **Stage 4, round 1** · implemented E-1, E-1b, E-2, E-3, E-4 as designed; applied the three
  gate-mandated wording changes (C-10's re-scoping of B-3's opening sentence, C-14's deletion of
  clause (d)'s enumeration, C-13's caps cell); ran V-1…V-16 on fixtures under `test/t27/` ·
  conditions C-3, C-6…C-14.
- Intervention check after stage 4: **absent**.
- **`verify_all` PASSED: PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — identical to baseline. The stage-5
  precondition is therefore satisfied.
- Working tree, verified by PM independently (`git status --porcelain` + `git diff --numstat`): the
  product diff is exactly four files — `.harness/rules/70-doc-size.md` `20/1`,
  `.harness/rules/80-delivery-policy.md` `35/0`, `.harness/scripts/archive-task.sh` `8/4`,
  `AI-GUIDE.md` `1/1`. **No `bin/sc` diff**, no `verify_all.*`, no `guard-rm.*`, no
  `archive-task.ps1`, nothing under `.claude/`. `docs/batches/followups/*` remain modified and
  **unstaged by policy** — the very carve-out R-36 is about. `test/` is untracked and ignored.
- Sizes: rule 70 **110** (AC-10 bar ≤130), rule 80 **88**, `AI-GUIDE.md` 97 — all inside F.1/F.2.
  Executable added lines **8**, function count 0 → 0, one whole-file `wc -l` per run outside every
  loop (AC-16, NFR-3 hold).
- **AC-7 now discriminates in measurement, not just on paper**: HEAD `Rotated 0` vs candidate
  `Rotated 3` over byte-identical index bytes, zero bytes written, with a positive control proving
  the snapshot detects a 1-byte write. Nothing was recorded NOT-DISCRIMINATING; nothing BLOCKED.
- **The developer reported an upstream statement of its own design as false, rather than quietly
  conforming** — the honest outcome this pipeline wants. HEAD does **not** abort on
  `--dry-run` with no index (**exit 0**): bash exempts a failing command inside an `&&` list from
  `errexit` unless it follows the final `&&`. E-1b landed anyway, exactly as gate C-1 pre-ruled
  ("reproduction is not a precondition; if HEAD does not abort, record the observation"). **Standing
  instruction to stage 7: RS-5's second candidate insight must NOT be written as stated.** Carried
  into the stage-5 and stage-6 dispatches.
- **C-3's three residuals are recorded, none repaired** (all against FR-1): (i) no trailing newline
  31 → 31, count divergence only, F.4 WARN; (ii) zero non-bullet lines 32 → 31, F.4 WARN; (iii)
  final line a non-bullet line 33 → **29** — **content loss** (the trailing blank disappears) **and
  reordering** (the mid-file non-bullet marker moved from line 19 to line 9), and **F.4 PASSes over
  it**, which is what makes it the dangerous shape. This is the gate's F-13, measured.
- Residual for stage 5 to rule on: **F-15** — B-3's metric check still carries no "exit status ≠ 0
  means the check did not complete" clause in its own bytes; C-12 covers it procedurally only, and
  C-10 authorised re-wording the opening sentence only. Named explicitly in the stage-5 dispatch.
- **AC-15 remains open by construction** — `.harness/insight-index.md` has no diff and stands at 30
  lines; the single archive run is the PM's, at delivery, under C-7.

### PM notes — stage 5 (round 1) · CHANGES REQUESTED

- **Stage 5, round 1** · initial review of the landed diff and of stages 1-4 · no prior round ·
  findings CR-1…CR-9.
- **Transcription:** both portions returned complete (contract opens `> Contract portion.` and ends
  with `## Verdict`); written verbatim to `05_CODE_REVIEW.md` and `05_RATIONALE.md`. The agent's
  leading "Header — targets" block, its `=== end ===` terminator and its closing report to the PM
  are final-message content, not document body, and were not written into either file.
- Intervention check after stage 5: **absent**.
- **This is a changes-requested, not a rollback**, and the reviewer says so explicitly. One MAJOR
  (**CR-1**) goes to the developer; every other finding is a stage-6/7 condition. Rollback count
  stays at 1 for the task.
- **CR-1 — F-15 ruled: the completion clause is required.** B-3's landed bytes bind the reader to
  act on the verdict a check returns and say nothing about a check that *did not complete*. Against
  the arrival sitting in the cache today, `0.47.0:336` sets `refusing` on any unclassifiable line
  and `:353-357` exits **3 having written nothing** — the index stays ≤30, the metric row reads
  *already provided*, the action is *change nothing*, and the line-count fix is silently dropped.
  That falsifies FR-5's binding property and I-5's own "resolvable from its own bytes". C-12 covers
  it only for this task and expires with it. Cost **+1 line** on a fragment under none of NFR-1's
  budgets. **I accept the ruling** — shipping a rule fragment that can hand a reader a wrong verdict
  is precisely the class T-27 exists to close. The reviewer supplied the byte-form so K-12 is not
  left to improvisation; the developer **transcribes, does not draft**.
- **CR-2 — the review independently confirmed the developer's contradiction of the design.** HEAD
  exits 0; bash's `errexit` exempts a failing command inside an `&&` list unless it follows the
  final `&&`. The landed E-1b stands on grounds that never depended on the abort (C-1, K-4, 1/1
  diff). **RES-4 is now doubly stated and binds stage 7: RS-5's second candidate insight must not
  be written into `07_DELIVERY.md`.**
- **The answer to the task's own question, re-derived by the reviewer on the real index rather than
  a fixture:** `.harness/insight-index.md` is 8 non-bullet + 22 bullets, so the delivery run
  computes `total_after = 30 + h`, rotates `h`, and emits `8 + (22 − h) + h` = **exactly 30** for
  any 1 ≤ h ≤ 22. R-18's fix works on this repository's own index.
- **C-10, C-13, C-14 all discharged** — in particular C-10's wholesale-replacement claim is now
  correctly scoped to `refresh_set` and asserts nothing of `verify_all.{sh,ps1}` (re-verified
  against `upgrade-project.sh:136-141`, `:186-194`, `:195-227`, `:535-573`). F-11 closed. C-3's
  three residuals confirmed real, correctly classified and correctly unrepaired; (iii) was checked
  by hand against the fixture.
- **RES-2 is the one that could silently fail AC-15 at delivery**, and it is mine: if
  `.harness/insight-index.md` does not end with a trailing newline, `wc -l` reads 29, the run lands
  at 31 and F.4 WARNs with E-1 working correctly. Measured before the delivery run (see stage 7).
- Nine residuals RES-1…RES-9 carried into the stage-6 and stage-7 dispatches.

### PM notes — stage 4 (round 2) and stage 5 (round 2) · APPROVED

- **Stage 4, round 2** · inserted CR-1's completion clause into B-3 (transcribed byte-for-byte from
  `05_RATIONALE.md` §5, reflowed to four physical lines) and corrected two off-by-one addresses in
  `04_DEVELOPMENT.md` · because a check that did not complete must yield no verdict, and a task
  about artifacts that state something untrue cannot itself cite bytes off by one · CR-1, CR-3.
- **Stage 5, round 2** · verified CR-1's clause on the landed bytes and CR-3's addresses; confirmed
  no executable line, cap or frozen path moved; re-ran rule 85 against the +1-line delta and ruled
  it earned · CR-1 and CR-3 discharged on landed evidence; two new MINORs (CR-10, CR-11) raised,
  one of them from a gap in CR-3's own scope · new residual RES-10.
- **Transcription (round 2):** both portions returned complete; content at `05_CODE_REVIEW.md` and
  `05_RATIONALE.md` **replaced**, not appended. The agent's leading "Header — targets and handling"
  block and its trailing round record / summary are final-message content and were not written.
- Intervention check after both rounds: **absent**.
- PM verified the landed clause independently at `.harness/rules/80-delivery-policy.md:66-83` and
  the file at **89** lines; `git diff --numstat` now `70-doc-size.md 20/1`, `80-delivery-policy.md
  36/0`, `archive-task.sh 8/4` (**unmoved**), `AI-GUIDE.md 1/1`. Product diff **+65 / −6**, still
  **8 executable added lines**.
- **Stage-5 gate is satisfied** (`APPROVED WITH CONDITIONS`, 0 CRITICAL / 0 MAJOR). Stage 6 may run.
- **RES-10 is a two-document, one-character-class correction the reviewer explicitly says needs no
  further review round.** `04` is the developer's document — a downstream stage may not edit it —
  so it goes back to the developer as a **round 3**, dispatched **in parallel** with stage 6: QA
  writes `06`, the developer edits `04`, so there is no write conflict, and QA is given the
  corrected figures directly in its dispatch so it cannot inherit the stale ones.
- Rollback count unchanged (**1** for the task). Two changes-requested rounds at stage 5, both
  discharged on landed evidence rather than on assertion.

### PM notes — stage 4 (round 3) and stage 6

- **Stage 4, round 3** · documentation-only: `04_RATIONALE.md` §6's three stale figures corrected
  (`35/0` → `36/0`, `64/6` → `65/6`, rule 80 `88` → `89`) and `04_DEVELOPMENT.md:23`'s bullet
  address (`:15` → `:16`), each re-measured first-hand · CR-10, CR-11.
- **Stage 6, round 1** · `06_TEST_REPORT.md` + `06_RATIONALE.md` written from **49 first-hand script
  executions across 37 self-built fixture trees** · because stage 5 held no execution capability
  (CR-8/RES-1) and RES-2 was unmeasured by anyone · RES-1, RES-2, RES-3, RES-7, RES-8, RES-10
  discharged; C-3, C-8, C-9, C-11, C-12 and C-6's stage-6 half discharged.
- Intervention check after both: **absent**.
- **QA verdict `PASS WITH RESIDUALS — APPROVED FOR DELIVERY`; 0 blocking defects.** `verify_all`
  **PASS 17 / WARN 0 / FAIL 0 / SKIP 1** on three consecutive runs plus a fourth with both stage-6
  documents in place. E.6's `## Adversarial tests` heading present at `06_TEST_REPORT.md:37`,
  unnumbered — PM verified by running E.6's own regex.
- **Nothing NOT-DISCRIMINATING, nothing BLOCKED.** AC-7 measured `Rotated 3` (candidate) vs
  `Rotated 0` (HEAD) over byte-identical trees with zero bytes written, and the write-detection
  snapshot was itself proved by a positive control (1561 → 1562 bytes).
- **RES-2 answered — the input AC-15 rides on is safe.** `wc -l .harness/insight-index.md` = **30**
  and `tail -c 1 | xxd` = **`0a`**: the file ends with a newline, all 8 non-bullet lines lead, and
  no blank sits between entries. So the delivery run rotates exactly `h` and lands at **exactly 30**
  for any 1 ≤ h ≤ 22. QA simulated it on a byte-identical **copy** (3 insights → `Rotating 3` → 30
  lines, F.4 PASS) and left the real index provably untouched (sha256 `e148278e434dfff7`). PM
  re-took both measurements independently: 30 and `0a`. C-7's single observation is intact.
- **C-3's three residuals reproduce stage 4's numbers exactly** — (i) 31→31 WARN, (ii) 32→31 WARN,
  (iii) 33→**29** with content loss *and* the mid-file marker moving line 19 → 9, **F.4 PASSing
  over it**. None repaired; the frozen range untouched.
- **AC-13's drill ran end to end from the landed rule-80 bytes alone**: 0.47.0, 425 lines, copied
  read-only, both checks exit **0**, verdicts *lost* / *already provided*, the *lost* action applied
  as a metric (+17/−5 onto the arriving text, nothing discarded), and the resulting script leaves
  the AC-1 fixture at **30** lines with the AC-6 tag intact.
- **QA exercised the delivery trap rather than reading it (QA-4)**: a heading of `## Insight to
  surface` — the very heading `04_DEVELOPMENT.md` uses — harvests **zero**, exits **0** and prints
  nothing. Stage 7's heading must be exactly `## Insight`.
- `baseline.json` deliberately not touched: raising `test_count` would invent a convention and add
  a fifth path to the diff, failing AC-14. Recorded, not hidden.
- New pool rows QA-1…QA-4 (+ RES-6's CR-4/CR-5) carried into `docs/tasks.md` at delivery.

### PM notes — stage 7 (delivery)

- **Entropy watch: NOT-DUE, fail-open.** `.harness/scripts/entropy-cadence` does not exist on this
  host, so the cadence check resolves NOT-DUE by the documented fail-open rule: no supervisor scan,
  no `## Entropy watch` section, delivery verdict unchanged. Same handling as `task-state.js`.
- **C-7 is mine and is being honoured literally**: the archive script runs **once**, no
  hand-rotation, no second run, no edit to `.harness/insight-index.md` or `insight-history.md`
  between the script's exit and `git add`, with both sha256 pairs recorded in `07_DELIVERY.md`.
