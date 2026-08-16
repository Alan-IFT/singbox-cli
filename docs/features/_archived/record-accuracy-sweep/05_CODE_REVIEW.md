> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `/home/alan/Programs/singbox-cli/bin/sc`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`
- `/home/alan/Programs/singbox-cli/.harness/rules/80-delivery-policy.md`
- `/home/alan/Programs/singbox-cli/.harness/rules/50-singbox-cli.md`
- `/home/alan/Programs/singbox-cli/docs/tasks.md`
- `/home/alan/Programs/singbox-cli/docs/tasks-archive.md`
- `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md`
- `/home/alan/Programs/singbox-cli/.harness/scripts/upgrade-project.sh`
- `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py`
- `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh`
- `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json`
- `/home/alan/Programs/singbox-cli/README.md`
- `/home/alan/Programs/singbox-cli/README.zh-CN.md`
- `/home/alan/Programs/singbox-cli/.harness/insight-index.md`
- `/home/alan/Programs/singbox-cli/docs/features/record-accuracy-sweep/01_REQUIREMENT_ANALYSIS.md`
- `/home/alan/Programs/singbox-cli/docs/features/record-accuracy-sweep/02_SOLUTION_DESIGN.md`
- `/home/alan/Programs/singbox-cli/docs/features/record-accuracy-sweep/03_GATE_REVIEW.md`
- `/home/alan/Programs/singbox-cli/docs/features/record-accuracy-sweep/04_DEVELOPMENT.md`
- `/home/alan/Programs/singbox-cli/docs/features/record-accuracy-sweep/04_RATIONALE.md`

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | MINOR | Standards-conformance | `.harness/rejected-decisions.md:784-802` | **CLOSED** — closed by the replacement `Why` bullet (14 → 19 lines). It now partitions **one** named population and names it: counting **rows**, eleven = nine semantic claims + R-94 (the one row about a copied count) + R-74 (this decision's own subject), which is exhaustive and disjoint over the eleven filed rows. Inside R-94 it switches population **explicitly** ("counting **its clauses**") to say the assertion total stood in three documents outside `baseline.json` — of which two were deleted and the third corrected to 19 and still standing. Every number verified against the tree, not accepted: `.harness/rules/50-singbox-cli.md:29-30` states no count and keeps the floor pointer; `docs/dev-map.md:87` states "how many there are is not stated here"; `docs/tasks.md:230-231` states **19**; `baseline.json:4` is `test_count: 19`; and the newly-added third mechanism, **B.6's committed-floor ratchet**, is real and enforced (`verify_all.sh:116-134` compares the working tree's `test_count` against `git show HEAD:`'s and FAILs on a lowering). The decline's substance is intact and unweakened — "no committed check can decide a semantic claim", the check-would-have-to-re-derive-the-fact argument, the three precedents (T-27, T-31, this task's own two false filed repairs), and the count clauses' pre-existing mechanism all still stand. |
| CR-2 | MINOR | Spec/design-fidelity | `04_DEVELOPMENT.md:275-285` | **CLOSED** — the over-claim is gone and what replaced it is true of the delivered tree: the count is deleted from the two documents **K-8** names, and the one surviving copy outside `baseline.json` (`docs/tasks.md:230-231`, authorised by E-10 / R-94(e)) states **19**, which is right. The stage-6 trap is disarmed at its cause, not papered over: I-6's and V-12's absolute phrasing is now **named as false of a compliant tree**, with the explicit instruction that AC-14 be read against the tree (19 / 19 / 19 plus a correct `docs/tasks.md` copy) rather than against V-12's wording — so a QA agent following `04` can no longer report AC-14 FAIL against a compliant tree. The `02` I-6 / E-10 tension is recorded as upstream and left unrepaired, which is correct: `02` owns it, and the developer neither edited it nor pretended it away. Travels as RES-4. |
| CR-3 | NIT | Spec/design-fidelity | `04_DEVELOPMENT.md:78` | **CLOSED** — drift row **D-6** exists, in the same `id / design item / what was done instead / why` shape as D-1…D-5, recording I-10's three-bullet shape against the delivered four and giving the reason (G-12 makes the *What is NOT claimed* boundary binding, and it fits none of the three named bullets). The fourth bullet was correctly kept, not removed. The `## Files changed` E-12 row states the same deviation and cites D-6, so the two records agree. |
| CR-4 | NIT | Standards-conformance | `docs/tasks.md:277` | **OPEN, deliberately — filed-row candidate, confirmed untouched.** T-31's block still reads "`.harness/rules/50-singbox-cli.md:29-30` **still says** "14 contract assertions"" in the present tense, of text this task deleted. Re-read at this round and byte-for-byte unchanged at the same coordinate, per the PM's instruction. It sits outside R-94's declared five-clause population and is legible as a record of what T-31 observed; the PM files it at delivery. Travels as RES-7. |
| CR-5 | MINOR | Spec/design-fidelity | `docs/tasks.md:16` | **NEW this round.** T-32's delivery row still states the host witness as "`MainPID` 2566751, `NRestarts` 0, `ActiveEnterTimestamp` identical before and after". That instance no longer exists: the delivered run in `04_DEVELOPMENT.md:61-63` witnessed `MainPID` **1776263** / `ActiveEnterTimestamp` **Mon 2026-08-17 00:44:47 CST**, and `04`'s Open issue 7 states outright that the earlier figures describe an instance replaced by something outside this pipeline. AC-21's own claim survives untouched — the task left the host undisturbed and each run's before/after pair is identical — but the row's parenthetical now names a witness the delivery's own final run contradicts, and a reader takes it as the instance at delivery. This is the task's defect class inside the task's own delivery record. **PM-owned, not a developer round:** `04`'s Open issue 3 already assigns the row's final wording to the PM; correct the two figures (or drop the parenthetical and keep "live host untouched; `is-active` never invoked") while writing it. Travels as RES-10. |
| CR-6 | NIT | Standards-conformance | `docs/tasks.md:16` | **NEW this round.** The same row opens "eleven filed **sentences** swept, seven corrected", while the record repaired under CR-1 now says "swept **eleven filed rows** … seven sentences corrected, three rows found already discharged and edited nowhere, R-74 amended in place". Rows is the correct noun and the one the arithmetic needs: the row's own text says R-94's population is "**five** clauses not the three filed", so under a *sentence* population eleven and seven are both understated. Not false under the programme's settled reading (seven rows whose sentence was corrected — the reading `04`'s Summary and this review's round 1 both use), which is why this is a NIT and not a defect. Worth one word while the PM is editing the row anyway, because it is the exact noun CR-1 was raised about. Travels as RES-10. |

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 | `bin/sc:792-795` (clause) over `bin/sc:796` (binding) → sole use `_b64dec(userinfo)` at `:798`; every occurrence of the name enumerated at round 1 | ✅ re-derived round 1; `bin/sc` unchanged this round |
| AC-2 | `bin/sc:792-795` are `#` lines; `:312`/`:313`/`:2804-2807` are string literals in key and argument position | ✅ by reading; `py_compile` + B.4's `19/19/19` owed → RES-3 |
| AC-3 | `docs/dev-map.md:81` states the price as prospective and names **both** sites — re-read this round, unchanged | ⚠️ OWED — the historical retrieval needs `git show`; stage 5 held no shell → RES-1 |
| AC-4 | guard `if port is None and not is_running():` at `bin/sc:2307`; docstring `:2299-2300`; `dev-map.md:42` and `:68` state the same two clauses | ✅ re-derived round 1 |
| AC-5 | shipped sentence names no directive (G-7); set re-derived from `_apply_directive` `:1440-1458` + `_anchor_index` `:1421-1430` | ✅ re-derived round 1 |
| AC-6 | `generate_config` composes `sc`'s overlays at `bin/sc:2107` then merges the user's document at `:2117`, every run | ✅ re-derived round 1 |
| AC-7 | `bin/sc:312` EN `{decision}`,`{override}` vs `:313` zh `{decision}`,`{override}` — read in **both** directions | ✅ re-derived; the "not driven from a test" statement is carried obliquely → RES-6 |
| AC-8 | the filed "four" refuted; **three** reach index 0 | ✅ re-derived independently round 1 |
| AC-9 | `CHANGELOG.md:29`'s lead set = `{0→1, 2→1, 1→2}` + 「恰好是下面三种，没有第四种」 — line re-read this round, unchanged; derived set re-taken round 1 | ✅ after-half re-derived; before-half owed → RES-2 |
| AC-10 | the witness is in the **shipped** lead (「还没有漂移记录的升级机器 … 它的退出码变小了」); pair **2 → 1**, reachable | ✅ re-derived |
| AC-11 | 「没有哪台机器的退出码会变小」 refuted in `04_DEVELOPMENT.md` and in `.harness/rejected-decisions.md`, not adopted | ✅ |
| AC-12 | `.harness/rules/80-delivery-policy.md:68-78` re-read this round: zero ranges, five tokens present and unchanged | ✅ re-derived round 1, spot-verified round 2 |
| AC-13 | `dev-map.md:33` — nine enumerated, property asserted of eight, `CFG_DIR` named as the exception | ✅ re-derived round 1 (G-8's count-only repair was not made) |
| AC-14 | `check-sc-contracts.py:846-857` defines **19**; `baseline.json:4` = **19**; `dev-map.md:87` and `50-singbox-cli.md:29-30` re-read this round and carry no count; `docs/tasks.md:230-231` carries **19**, correctly and authorised | ✅ CR-2 closed — `04` now states the tree truthfully and tells stage 6 to read AC-14 against the tree, not against V-12's wording; B.4's `N defined` still owed → RES-3 |
| AC-15 | `.harness/rules/50-singbox-cli.md:47` names only B.3 — re-read this round, unchanged | ✅ by reading; the run's SKIP set owed (PM-measured B.3 the single SKIP) |
| AC-16 | `dev-map.md:211` explicit codec; clauses `:234-240`; `bin/sc:125-126` re-exec; `main()`'s arm `("doctor", "config")` at `bin/sc:3843` | ✅ each clause true of the delivered `bin/sc` |
| AC-17 | `docs/tasks.md:162` (amended R-74 row) against `:16` (eleven dispositions) | ✅ dispositions complete and reachable; the row's *wording* now carries CR-5 and CR-6, both PM-owned |
| AC-18 | 10 files in the change set = 8 ledger paths + 2 PM-owned `docs/batches/closeout/*`; no `.harness/scripts/**`, no new file. This round adds only E-12 and E-13, both already in the ledger | ✅ by file-set reasoning |
| AC-19 | — | ⚠️ OWED at stage 5 (no shell); PM's post-rework measurement is `PASS 20 / WARN 0 / FAIL 0 / SKIP 1, exit 0`, identical to the task-start baseline |
| AC-20 | README grep re-run at round 1: neither README carries the corrected sentence or its advice; `CHANGELOG.md`'s only `失败：` is `:50`, not the changed `:29` | ✅ re-derived round 1 |
| AC-21 | — | ⚠️ OWED at stage 5, and its **witness in the delivery row is stale** → CR-5. The criterion's claim (this task disturbed nothing) is unaffected and still supported: no stage touched the host, `is-active` was never invoked, `/etc/sing-box` mtime has not moved since 2026-08-11. Re-take, never inherit → RES-8 |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| E-1 (`bin/sc`, R-63 comment, ≤3) | 4 lines at `bin/sc:792-795` | ✅ over ceiling, **reported** as D-1 per G-10 |
| E-2 (`bin/sc`, AAAA key + zh + call site, ≤6) | `:312`, `:313`, `:2804-2807` | ✅ over ceiling (7), reported in the per-file table |
| E-3 (R-79 cost clause) | `dev-map.md:81`, both sites named | ✅ shape; truth owed → RES-1 |
| E-4 (R-82 `# Clash API` row) | `dev-map.md:42`, both clauses | ✅ |
| E-5 (R-94(a) `# Paths` row) | `dev-map.md:33` | ✅ |
| E-6 (R-94(d) utilities row states no count) | `dev-map.md:87` — "how many there are is not stated here"; points at `baseline.json`'s floor and B.4's `N defined` line | ✅ re-verified this round |
| E-7 (R-85 lead) | `CHANGELOG.md:29` | ✅ re-verified this round |
| E-8 (rule 80 durability, ≤4) | 8 lines at `80-delivery-policy.md:68-78` | ✅ over ceiling, **reported** as D-2 per G-10; re-verified this round |
| E-9 (rule 50 Test bullet + preamble) | `50-singbox-cli.md:29-30`, `:47` | ✅ re-verified this round |
| E-10 / E-11 (rotation, R-74 amendment, dispositions) | `tasks.md:16,135,162,187,204,227,252`; `tasks-archive.md:606-643` | ✅ structure holds; the T-32 row's wording carries CR-5 / CR-6 |
| E-12 (one decline entry) | `rejected-decisions.md:779-808` | ✅ **CR-1 and CR-3 both closed**: the enumeration partitions one named population and switches population explicitly; the four-bullet deviation is recorded as D-6 |
| I-2 (four clauses, placeholders exactly `{decision}`/`{override}`, names no directive, appears at key + call site) | `bin/sc:312`, `:2804-2807` | ✅ |
| I-5 (both numbers with their properties) | `dev-map.md:33` | ✅ G-8's forbidden count-only repair not made |
| I-6 (no count outside `baseline.json`) | `dev-map.md:87`, `50-singbox-cli.md:29-30` cleared; `tasks.md:230-231` retains one under E-10 | ⚠️ upstream tension, **now correctly recorded rather than repaired** (`04` Open issue 4) → RES-4 |
| I-7 (label set, then the derived set, then "a PROBLEM host is unchanged") | `CHANGELOG.md:29` | ✅ |
| I-8 (six mechanisms as greppable tokens, zero ranges) | five tokens, all resolving; the loop named in words with no range | ✅ |
| I-10 (the file's existing three-bullet shape) | four bullets — Decision / Why / What is NOT claimed / Origin | ✅ deviation recorded as **D-6**, bullet correctly kept (G-12) |
| K-2 (no statement added/removed/reordered) | comments and three string constants only | ✅ by reading; AST identity owed → RES-3 |
| K-3 / G-5 (key ↔ call-site identity) | replaced by `ast.parse` (D-5); identity re-established at round 1 by reassembling `:2804-2807` | ✅ |
| K-4 / BC-5 | no changed line carries `失败：` or `failed: ` | ✅ |
| K-5 (no coordinate inside a corrected sentence) | none of the seven carries a line number | ✅ |
| K-6 (no directive named in the shipped sentence) | `bin/sc:312` names none | ✅ |
| K-7 (zero ranges into `upgrade-project.sh`) | `80-delivery-policy.md:68-78` | ✅ |
| K-8 (the deletion's scope) | `dev-map.md`'s utilities row and rule 50's Test bullet, both cleared | ✅ and now stated exactly in `04` |
| K-10 (rotate closed rows only, ≤300, one pointer each) | `tasks.md` under cap (PM-measured 293/300) | ✅ |
| K-11 (one decline record, no mechanism) | `rejected-decisions.md:779` only; no check, linter, template or `verify_all` step added | ✅ |
| NFR-2 (≤30 changed lines outside the process paths) | 26 of 30, unchanged by this round | ✅ verified, not accepted: `02:22` states *process path* files "do not count against NFR-2's 30", and both files edited this round are ledgered as process paths (E-12, E-13) |
| Frozen: loader recipe block + four clauses | `dev-map.md:204-242` — outside the four reported hunks | ✅ |
| Frozen: `dev-map.md:76`'s past-tense `18 … T-30` | present and unchanged — re-read this round | ✅ |
| Frozen: `bin/sc:59-63` "as the eighth" | present and unchanged | ✅ |
| Frozen: READMEs, `.harness/scripts/**`, `baseline.json`, `CONTEXT.md`, `_archived/**`, `.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md` | none in the change set; `verify_all.sh` and `baseline.json` were **read** this round, never written | ✅ |
| Out of scope: R-106(a), R-98(a), R-86, R-89/R-90/R-92, R-107, R-109, R-110 | untouched | ✅ not leaked in |
| G-14 / RS-2 deliberately unrepaired | `.harness/insight-index.md:10` still carries its ranges; `80-delivery-policy.md:86` still cites `verify_all.sh:213-219` | ✅ as ruled → RES-5 |

## Axis status
- **Standards-conformance: 3 findings — 1 closed (CR-1), 2 open, worst open = NIT** (CR-4, CR-6; both filed-row candidates the PM disposes at delivery). The repo's conventions hold otherwise, re-checked over this round's two files: prose-only, zero executable lines, no mechanism and no `verify_all` step added; no rule fragment over F.2's 200 lines; `docs/tasks.md` under its cap; `04_DEVELOPMENT.md` 323 lines against F.6's 500; no `## Round N`, changelog or superseded-finding section in any stage document; no red-line path touched; the decline record keeps one entry for one concept, as its own preamble requires.
- **Spec/design-fidelity: 3 findings — 2 closed (CR-2, CR-3), 1 open, worst open = MINOR** (CR-5, PM-owned at delivery). Every FR still maps to a delivered artifact and every binding condition G-2…G-16 remains discharged as certified at round 1; nothing this round's two files changed disturbs that. The two enumerations in the repaired decline record cross-check to the same eleven rows — 9 semantic + R-94 + R-74, and 7 corrected + 3 already-discharged + R-74 — with the six non-R-94 corrected rows and the three discharged rows summing to the nine semantic claims, so the record is now internally consistent as well as true of the tree.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-1 | AC-3 is the one corrected sentence this review could not check against its own subject: the claim is about `git show 6d16caf^:bin/sc`, and stage 5 held `Read`/`Glob`/`Grep` only. Re-take the retrieval first-hand — two of eleven filed repairs were already false, and the delivered build corroborates only the *shape* of the claim (`cmd_update_rules`'s `prefix`/`print` at `bin/sc:3426-3427`; `_doctor_permissions()`'s summary rows at `:3042-3047` and its no-path clean branch at `:3048`). | `06_TEST_REPORT.md` |
| RES-2 | AC-9's *before* half (`git show d849234{,^}:bin/sc`) was not re-retrieved at review; the *after* half and the whole `1 → 0` closure were re-derived from the delivered file. Re-take the before half. | `06_TEST_REPORT.md` |
| RES-3 | NFR-1's AST identity (15550 nodes, 113 top-level defs, exactly three differing `str` constants), `python3 -m py_compile bin/sc`, and B.4's `19 defined, 19 run, 19 passed` line are the change's most load-bearing measurements and were not re-taken at stage 5. Re-derive rather than inherit — and check that the normalisation folds nothing but `str` constants. | `06_TEST_REPORT.md` |
| RES-4 | `docs/tasks.md:230-231` and T-32's own row at `:16` still state the committed assertion count (19). FR-9-compliant, E-10-authorised and correctly stated, but it is the same copy hazard I-6 removed from `dev-map.md` and rule 50, surviving in a line this task edited — it goes stale at the 20th assertion. The underlying `02` I-6 / E-10 tension is upstream and unrepaired by design. Filed-row candidate. | PM at delivery |
| RES-5 | Three deliberate non-repairs re-verified untouched: `.harness/insight-index.md:10`'s four ranges into `upgrade-project.sh` (G-14), `.harness/rules/80-delivery-policy.md:86`'s `verify_all.sh:213-219` (RS-2), and RS-1's AC-13 wording imprecision (G-15). | PM at delivery |
| RES-6 | AC-7's parenthetical — "the doctor probe is **not driven** from a test … and the delivery states that" — is carried only obliquely by `04_DEVELOPMENT.md`'s Open issue 4 and its G-9 row. Confirm as satisfied rather than fail the criterion on the missing verbatim sentence. | `06_TEST_REPORT.md` |
| RES-7 | CR-4's `docs/tasks.md:277` present-tense quotation of deleted text — outside R-94's declared population, re-verified untouched this round, offered as a filed-row candidate, not a defect of this delivery. | PM at delivery |
| RES-8 | The live `sing-box` instance was replaced by something outside this pipeline (`MainPID` 2566751 → 1776263, `ActiveEnterTimestamp` 2026-08-11 12:13:57 → 2026-08-17 00:44:47, `NRestarts` still 0, no reboot, `/etc/sing-box` mtime unmoved since 2026-08-11). **Re-take AC-21's host witness first-hand and inherit no figure — not `04`'s, not the PM's, not this review's.** AC-21's claim is unaffected; what is void is the programme-level assumption that one instance spans every dispatch. Note when re-taking: `ps`'s start time reads one second below `ActiveEnterTimestamp` and that is a rounding artefact, not a second instance. | `06_TEST_REPORT.md` |
| RES-9 | Stage 5 holds no shell, so the "only two files changed since round 1" claim was verified by reading, not by `git diff --stat`: every round-1 coordinate re-read this round resolves to the certified text at the same line number (`dev-map.md:76,81,87`, `50-singbox-cli.md:29-30,47`, `80-delivery-policy.md:68-78`, `CHANGELOG.md:29`, `tasks.md:16,230-231,277`). What remains **owed to a shell**: `bin/sc`'s `sha256 0afdc3b6…f669` and the byte-identity of `docs/tasks-archive.md`. | `06_TEST_REPORT.md` |
| RES-10 | CR-5 (the delivery row's stale `MainPID` witness) and CR-6 (its "eleven filed sentences" noun) are both in `docs/tasks.md:16`, whose final wording `04`'s Open issue 3 assigns to the PM. Both are PM edits at delivery, not a developer round. | PM at delivery |

## Verdict
APPROVED
