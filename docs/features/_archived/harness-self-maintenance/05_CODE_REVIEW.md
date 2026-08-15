> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `.harness/rules/80-delivery-policy.md` (re-read whole, 89 lines; `:66-83` byte-checked)
- `.harness/rules/70-doc-size.md` (re-read whole, 110 lines; `:14-17`, `:27`, `:80-98` byte-checked)
- `.harness/scripts/archive-task.sh` (re-read whole, 154 lines)
- `AI-GUIDE.md` (re-read whole, 97 lines)
- `.harness/scripts/verify_all.sh` (`:205-227`, F.4 metric)
- `.harness/scripts/archive-task.ps1` (`:60-84`, frozen-set check)
- `.harness/rules/85-design-discipline.md` (`:34-57`, rule-85 audit of the round-2 delta)
- `.harness/insight-index.md` (AC-15 arithmetic input, 30 lines)
- `.harness/scripts/upgrade-project.sh` (ground truth, `:136-148`, `:181-227`, `:535-576`)
- `.gitignore` (`:19`, C-9)
- `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.47.0/skills/harness-init/templates/common/.harness/scripts/archive-task.sh` (`:325-401`, the refusing-arrival path)
- `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.47.0/agents/developer.md`, `agents/qa-tester.md` (C-6 declared shapes)
- `test/t27/c3iii/.harness/insight-index.md`, `test/t27/head-archive-task.sh`, `test/t27/head-v2b/.harness/scripts/archive-task.sh` (C-3 and V-2b evidence)
- `docs/features/harness-self-maintenance/01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`, `02_RATIONALE.md` (T5.1/T5.3), `03_GATE_REVIEW.md`, `04_DEVELOPMENT.md`, `04_RATIONALE.md` (T5.2)

## Findings

| id | severity | axis | file:line | finding |
|---|---|---|---|---|
| CR-1 | MAJOR — **DISCHARGED** | Spec/design-fidelity | `.harness/rules/80-delivery-policy.md:75-78` | **The completion clause is landed and correct.** Verified byte-for-byte against the form this review specified: "A check whose command exits non-zero **did not complete** and yields no verdict — a run that wrote nothing is never *already provided*." It sits **in the paragraph** (`:68-78`), not in the table; the two table rows are byte-identical to `02_SOLUTION_DESIGN.md:180-181` and now occupy `:82-83`; the opening sentence is still scoped to `refresh_set` (C-10's landed wording, unchanged). Against the arrival in the cache today — `0.47.0:336` sets `refusing` on any unclassifiable line, `:353-357` exits **3** having written nothing — the reader can no longer reach *already provided* → *change nothing* on a run that wrote nothing, so **FR-5's binding property and I-5's "resolvable from its own bytes" now hold on a refusing arrival**: every arrival either completes (one verdict, its stated action, a script deciding rotation on `wc -l`) or visibly yields none. One residual reading, recorded not raised: the clause says what a non-verdict is **not**, and leaves the recovery step ("make the check complete, then re-read the verdict") to inference. That is inside the sentence's plain sense and costs no further line. Cost: rule 80 88 → **89**, F.2 bar 200, NFR-1 prices B-3 nowhere; no executable line moved. |
| CR-2 | MINOR | Spec/design-fidelity | `02_SOLUTION_DESIGN.md:31` (E-1b cell) · `02_SOLUTION_DESIGN.md:359` (RS-5) | **E-1b's stated basis is false, and I confirm the developer's measurement.** Bash does not exit when the failing command is part of an `&&` list and is not the command after the final `&&`; at HEAD (`test/t27/head-v2b/.harness/scripts/archive-task.sh:82`) the failing command *is* the `[[ … ]]`, so a `--dry-run` with no index runs to completion at exit 0. The landed edit is **still justified** (C-1 pre-ruled it unconditional; K-4 bans the form; net 1/1, so rule 85 charges it nothing) — hardening, not a bug fix. What must not travel is the claim: **RS-5's second candidate insight must not be written into `07_DELIVERY.md` `## Insight`** — it would put a false line into `.harness/insight-index.md`, this task's own defect class. `04_DEVELOPMENT.md:94` carries the true statement. Owner: architect (statement), PM/stage 7 (do not propagate). |
| CR-3 | MINOR — **DISCHARGED** | Standards-conformance | `04_DEVELOPMENT.md:23`, `:73` | Both off-by-one addresses corrected against the landed file and re-verified here: `## Stage-doc boundary rule` is `70-doc-size.md:80-96` (17 content lines), clause (d) is `:94-96`, line 97 is blank and line 98 is `## Adversarial check`. The document is now internally consistent. No landed byte changed for this finding. A **third** address in the same row was outside CR-3's naming and is still wrong — CR-11. |
| CR-4 | MINOR | Spec/design-fidelity | `.harness/rules/80-delivery-policy.md:68-74` | B-3 cites four line ranges into `.harness/scripts/upgrade-project.sh` (`:186-194`, `:195-227`, `:136-141`, `:548-556`). Every one resolves correctly today, but `upgrade-project.sh` is itself plugin-delivered and re-landed by the very event this section is about, so those numbers drift on the next refresh and the fragment then states four things that are false — BC-13's reasoning applied one level up. Mitigated, not eliminated, by the prose naming `refresh_set` and `VERIFY-HALT` by name. **No repair this task.** Travels to the pool with RS-9/RS-11. |
| CR-5 | MINOR | Spec/design-fidelity | `.harness/rules/70-doc-size.md:27` | The caps cell routes *every* post-archive F.4 WARN to rule 80's checks. Two of the three shapes that produce exactly that WARN — RS-9 (i) no trailing final newline and (ii) zero non-bullet lines — occur **with the fix present**; rule 80's metric check then runs on a fresh fixture, returns ≤30 → *already provided* → *change nothing*, and the reader is left with a WARN and no next step. The cell is **incomplete, not false**, and completing it costs lines the cell does not have. Belongs to whichever task opens `archive-task.sh:109-136` (RS-9), the only place either shape can be repaired. |
| CR-6 | NIT | Standards-conformance | `.harness/scripts/archive-task.sh:98` | The clamp line carries the test, the assignment and the report `echo` at ~190 characters, roughly twice the file's next-longest executable line. **Design-mandated** — I-2/PQ-2 require the residual to print on the clamp condition and NFR-1 prices the diff in single digits; splitting it into three lines is how the size bar gets reopened. Recorded so a future editor does not "tidy" it. No action. |
| CR-7 | NIT | Standards-conformance | `02_SOLUTION_DESIGN.md:276-277` | F-14 unrepaired and correctly so. `.harness/rules/85-design-discipline.md:41-42` names **no section and no document**, so `## Smaller alternative rejected` is not a section named by precedence. Under C-6 it is a gap-row unit. Its **destination is unchanged**: `:42` obliges a later stage to test the answer, so B-1's bare test routes it to the contract. Basis withdrawn, placement stands, no edit required. |
| CR-8 | MINOR | Standards-conformance | (whole diff) | **I hold no execution capability**, so `git diff --numstat`, `git status --porcelain`, the shell-function count and the untouched-path set are **not verified first-hand by this review** in either round. Verified by reading, this round: `verify_all.sh:215-216` still `n=$(wc -l < .harness/insight-index.md)` / `(( n > 30 ))`; `archive-task.ps1:74` still `$currentInsights.Count + $harvestedInsights.Count`; `70-doc-size.md` = 110 and `80-delivery-policy.md` = 89 and `AI-GUIDE.md` = 97; 11 rule fragments on disk and 11 index lines at `AI-GUIDE.md:22-32`; `archive-task.sh` byte-identical to round 1's reviewed state, `:44-77` and `:109-136` intact, no shell function anywhere; fixtures under `test/t27/` with `.gitignore:19` = `test/`. Stage 6 must re-measure (RES-1). |
| CR-9 | NIT | Standards-conformance | this document, schema | **Schema-gap row (B-1 clause d).** Four units of this review fit no declared shape of `05_CODE_REVIEW.md`: the per-gate-condition discharge, the per-edit-id review of the landed diff, the F-15 ruling and the E-1b basis audit. `03_GATE_REVIEW.md`'s "discharged by" column names `05_CODE_REVIEW.md` for C-6/C-10/C-13/C-14, which is B-1's precedence clause, so all four route to the **contract**. Destinations given instead of new sections: the condition discharge and the per-edit review are rows of `## Design fidelity check`; the F-15 ruling is CR-1; the E-1b audit is CR-2; their reasoning is in `05_RATIONALE.md`. No section was invented and no new file was opened. |
| CR-10 | MINOR | Standards-conformance | `04_RATIONALE.md:198-212` (§6) | **The round-2 delta was not carried into stage 4's size accounting.** §6 still reads `E-3 … 35 / 0`, `total 64 / 6`, and "`.harness/rules/80-delivery-policy.md` = 88". The landed file is **89** lines and `04_DEVELOPMENT.md:24`/`:28` correctly say `36 / 0` and `+65 / −6`. Three numbers in the rationale now contradict the contract portion beside them and the file they measure. Non-binding portion, so nothing downstream is misled by force — but this is a task whose whole subject is a harness artifact stating something untrue about a file, and the fix is three characters. Owner: developer (PM-directed edit, no re-review round). |
| CR-11 | MINOR | Standards-conformance | `04_DEVELOPMENT.md:23` | **A third off-by-one in the row CR-3 corrected.** The row says "one `## When to read this` bullet at `:15`"; the landed bullet ("When deciding which portion of a stage doc a unit belongs in — `## Stage-doc boundary rule` below.") is `70-doc-size.md:16` — `:15` is the pre-existing "Before pasting evidence into a stage doc" bullet. CR-3 named only the two section addresses, so this one was not in its scope and survives; my round 1 cited `:16` in the E-2 row and did not flag the mismatch. Same class, same one-character repair, same owner as CR-10. |

## Requirement coverage check

| criterion | implementation | status |
|---|---|---|
| FR-1 rotation on the cap's own measurement | `archive-task.sh:80-81` (`wc -l < "$insight_index"` behind `[[ -f ]]`), `:94`, `:97` | ✅ same tool, same file as `verify_all.sh:215` |
| FR-2 rotation conserves content | `:101-107` (oldest-first split), `:114-115` (history append in order), `:119-123` (header + remaining + harvested) | ⚠️ holds on the ideal index; three residual shapes reported under C-3, (iii) loses a line — unrepairable inside the frozen range |
| FR-3 no needless rotation; dry-run writes nothing | `:97` (`> 30` only), `:126-129` (`elif` append), write sites `:84`, `:109`, `:127`, `:133` each behind `DRY_RUN == false` | ✅ every write site guarded |
| FR-4 continuation-join preserved | `:44-77` unchanged, `awk` join at `:57-71`, local-fix comment `:51-56` | ✅ frozen range intact |
| FR-5 durable out-of-file record with a check per fix | `80-delivery-policy.md:66-83`, completion clause `:76-78` | ✅ **now holds on a refusing arrival** — no arrival yields a false verdict; a non-zero exit yields none (CR-1) |
| FR-6 `## Stage-doc boundary rule` with (a)(b)(d) | `70-doc-size.md:80-96`: test `:82-86`, two-destinations `:88`, precedence `:90-92`, schema-gap `:94-96` | ✅ (c) removed under AC-9(b)'s final clause + C-11 |
| FR-7 no third document kind | `70-doc-size.md:88` | ✅ |
| FR-8 one home, four properties | `80-delivery-policy.md:29-41` + trigger `:11-12` + `AI-GUIDE.md:30`; existing fragment; `docs/batches/**` at `:36` | ✅ 13 lines, NFR-1 bar ≤15 |
| FR-9 list derived first-hand | stage 4's V-10 partition + `51c0f47` + the modified `docs/batches/followups/*` | ✅ derivation is first-hand; the `docs/batches/**` bullet's justification is disclosed as coming from outside the three-commit sample |
| FR-10 criterion cites rather than transcribes | AC-14 in `01_REQUIREMENT_ANALYSIS.md:190`; binding sentence `80-delivery-policy.md:40-41` | ✅ |
| FR-11 invariants (a)-(d) | `verify_all.sh:213-219` unedited in form; `archive-task.ps1:74` untouched; no fragment added; B.2 untouched | ⚠️ full-diff emptiness → stage 6 (CR-8) |
| BC-1 index absent | `:82-85` warn + guarded `touch`; measurement at `:81` yields 0 | ✅ |
| BC-2 header-only / empty index | `total_after = index_lines + h`; `rotate_count = 0`; `elif` at `:126` appends | ✅ |
| BC-3 zero harvested | `:74` and `:126` both false → no rewrite, no history; `:133-136` still moves the dir | ✅ |
| BC-4 already over cap | `:97` computes `total_after − 30` whether or not `h > 0` | ✅ |
| BC-5 cap unreachable | `:98` clamp to `${#current[@]}` + residual echo on the clamp condition | ✅ identity re-derived on both AC-5 fixtures (`05_RATIONALE.md` §4) |
| BC-6 hostile entry bytes | `:115`, `:121-122` builtin `echo`, no `-e` | ✅ path unchanged from HEAD |
| BC-7 `--dry-run` on any of the above | all four write sites guarded; `rotated` populated at `:101-103` **before** the `:109` guard | ✅ report is the true count |
| BC-8 / BC-9 fixtures never real, untracked | 17 candidate + 8 HEAD fixture trees under `test/t27/`, each with its own script copy; `.gitignore:19` | ✅ verified first-hand by listing |
| BC-10 `verify_all` from root | stage 4's C-8 row, re-run after CR-1's insertion | ⚠️ artifacts corroborate; the run itself → stage 6 |
| BC-11 no new machinery | diff is 4 existing files; no script, hook, digest, CI job or `verify_all` step; 11 fragments before and after | ✅ |
| BC-12 no unit with two destinations or none | C-6 discharge below | ✅ stages 4 and 5; stages 6-7 bound by RES-8 |
| BC-13 checks not verdicts | `80-delivery-policy.md:75-78` ("a verdict is a property of that text, not a standing fact" + the non-completion clause); rows `:82-83` state thresholds; no version named | ✅ **strengthened by CR-1** — an incomplete check is now explicitly not a verdict |
| AC-1 30-line index + 3 harvested → ≤30 | `:94` 30+3=33 → `:97` rotate 3 → `:119-123` emits 8+19+3 | ✅ re-derived; = **30** exactly |
| AC-2 byte conservation, oldest, header intact | `:101-107`, `:114-115`, `:118-123` | ✅ on the real index shape (all 8 non-bullet lines leading, final line a bullet) |
| AC-3 25 lines + 2 → no rotation | 27 ≤ 30 → `elif` append | ✅ |
| AC-4 exactly 30 + 0 → byte-identical | 30 not > 30; `h = 0` → neither branch writes | ✅ |
| AC-5 residual == `wc -l` − 30, both fixtures | `:98` prints `total_after − 30 − rotate_count` | ✅ identity closes on the rewrite path **and** the clamp-to-zero append path |
| AC-6 wrapped bullet, tag intact | `:57-71` untouched | ✅ |
| AC-7 dry-run, absolute count, zero bytes | `:101-103` outside the guard; `:143` prints `${#rotated[@]}` | ✅ discriminating: HEAD's `total_after` at `test/t27/head-archive-task.sh:92` counts bullets → `Rotated 0` |
| AC-8 `verify_all` untouched, F.4 unchanged, PASS 17 | `verify_all.sh:215-216` read first-hand, unchanged after the round-2 delta | ⚠️ metric half ✅; empty-diff half → stage 6 (CR-8) |
| AC-9 (a) 30 units 0/0, (b) 7 kinds vs witnesses | stage 4 `## Condition disposition` C-11 row | ⚠️ taken from stage 4; the `measurement obligation → contract` ruling C-11 binds — spot-checked ✅ |
| AC-10 rule 70 ≤130, fragments ≤200, E.5 | 110 and **89** lines; 11 fragments, 11 index lines | ✅ verified first-hand after the +1 line |
| AC-11 three delivery commits partitioned | stage 4's V-10 | ⚠️ taken from stage 4 (no `git log` here) |
| AC-12 trigger word-for-word in both homes | `80-delivery-policy.md:11-12` vs `AI-GUIDE.md:30` | ✅ both trigger clauses byte-identical; only the connective prose differs, which AC-12 does not bind |
| AC-13 drill from B-3's bytes alone | stage 4 C-12 row + `04_RATIONALE.md` §4; gate PQ-5 reproduced independently | ✅ **for a completing arrival, and now for a refusing one** — CR-1's clause closes the gap the drill could not exercise |
| AC-14 product diff / delivery writes | four paths only; `+65 / −6` after the round-2 delta | ⚠️ → stage 6/7 (CR-8) |
| AC-15 delivery run needs no hand-rotation | `.harness/insight-index.md` at 8 non-bullet + 22 bullets = 30, unmodified this round | ⚠️ **lands at exactly 30 for any 1 ≤ h ≤ 22** — conditional on the index ending with a newline (RES-2) |
| AC-16 metric not algorithm | 8 added lines, 0 → 0 functions, one whole-file measurement, report strings unchanged, one report line added per I-2; **unchanged by the round-2 delta** | ✅ |

## Design fidelity check

| design item | implementation | status |
|---|---|---|
| E-1 metric (replaces `:92`, `:94`, `:95`) | `:80-81`, `:94`, `:96-98`, `:99` | ✅ measurement before every write incl. `touch` (PQ-3); **8/4**, unmoved by round 2 |
| E-1b `[[ … ]] && touch` → single-line `if` | `:84` | ✅ landed; stated basis false (CR-2), landing unaffected (C-1) |
| E-2 rule 70: section + trigger bullet + caps cell | `:80-96`, `:16`, `:27` | ✅ file 91 → 110; the bullet's address is misquoted in stage 4 (CR-11), the bullet itself is correct |
| E-3 rule 80: two sections + trigger | `:29-41`, `:66-83`, `:11-12` | ✅ file 53 → **89**, `36 / 0` — 35 at round 1 plus CR-1's single line; decomposition in `05_RATIONALE.md` §5, stale in `04_RATIONALE.md` §6 (CR-10) |
| E-4 `AI-GUIDE.md:30` restated | `AI-GUIDE.md:30` | ✅ file stays 97 lines |
| E-5 schema-gap row, not a file | `02_SOLUTION_DESIGN.md:35` | ✅ as a row; basis for `## Smaller alternative rejected` withdrawn (CR-7) |
| E-6 not edited, per the frozen set | `archive-task.ps1:74` still entry-counting; `verify_all.sh:213-219` unchanged | ⚠️ full set → stage 6 (CR-8) |
| I-1 same tool, same file, one measurement | `:81` vs `verify_all.sh:215` — identical form `wc -l < <file>` | ✅ invariant's `iff` is non-exhaustive (F-13), which C-3 carries |
| I-2 residual echo on the clamp condition | `:98`, printed even when the clamp reaches 0 | ✅ number == `wc -l` − 30 on both paths |
| I-3 B-1 placement and content | after `### Rule 4` (`:65-78`), before `## Adversarial check` (`:98`) | ✅ 17 content lines (18 minus C-14's deletion) |
| I-4 B-2 process half only | `:29-41`; `docs/dev-map.md` absent, `docs/batches/**` present, no `insight-history.md` bullet | ✅ byte-identical to the design's fence |
| I-5 record resolvable from its own bytes | `:66-83`, clause `:76-78` | ✅ **now holds** — a reader with only these bytes distinguishes "no verdict" from *already provided* (CR-1) |
| I-6 trigger parity, no fragment added | `:11-12` ↔ `AI-GUIDE.md:30` | ✅ |
| B-1 verbatim except C-14's deletion | `70-doc-size.md:80-96` | ✅ only the em-dash enumeration removed, replaced by the comma the sentence needs |
| B-2 verbatim | `80-delivery-policy.md:29-41` | ✅ |
| B-3 verbatim except C-10's opening and CR-1's clause | `80-delivery-policy.md:66-83`; both table rows byte-identical to `02_SOLUTION_DESIGN.md:180-181` | ✅ **both authorised departures verified byte-for-byte**; nothing else re-worded |
| K-1…K-5 (single measurement, clamp, branch head, no `&&`, frozen ranges) | `:80-81`, `:98`, `:99`, no bare `&&` remains in the file, `:44-77` / `:109-136` intact | ✅ |
| K-6, K-11, K-13, K-14 (frozen files, no host action, no machinery, no 0.47.0 bytes) | diff is four files; no digest/pin/hook/step; template read from the cache path only | ✅ as far as artifacts show (CR-8) |
| K-7 caps | 110 / 89 / 11 fragments | ✅ |
| K-8, K-9 (fixtures under `test/`, own copy) | 17 candidate + 8 HEAD trees, each with `.harness/scripts/archive-task.sh` | ✅ verified by listing |
| K-10, K-12 | stage 4's C-8 row; **four** bounded wording changes, each gate- or review-authorised | ✅ CR-1's clause transcribed from `05_RATIONALE.md` §5 rather than drafted — K-12 satisfied exactly as C-10 satisfied it |
| Rule 85 on the round-2 delta | one sentence, +1 line, in an existing paragraph | ✅ adds no file, no concept, no mechanism (`85-design-discipline.md:46-51`); it does not merely mention exit status, it assigns the exit a meaning and forecloses one named wrong verdict — the property, not a gesture at it |
| **C-3** three residuals measured, none repaired | stage 4's C-3 row | ✅ **all three re-derived and confirmed** — (i) 31→31 count divergence, WARN; (ii) 32→31 count divergence, WARN; (iii) 33→**29**, content loss + reorder, F.4 **PASS**. (iii) verified first-hand against `test/t27/c3iii/.harness/insight-index.md`: the mid-file marker sits at line **9** (was 19), the trailing blank is gone, 29 lines. Correctly left unrepaired — the repair is `:118`, inside the frozen `:109-136` (AC-16) |
| **C-6** every section a declared shape or a true-basis gap row | stage 4's nine sections == the nine rows of `agents/developer.md:57-65`; its one gap unit recorded in `## Open issues for review` with a true basis | ✅ discharged for stage 4 **and** for this document (CR-9). No unit of stages 4-5 has two destinations or none. Stages 6-7 → RES-8 |
| **C-7** script never run against this repository | stage 4's row; `.harness/insight-index.md` re-read at 30 lines, content unchanged | ✅ preserved through round 2 — the round-2 delta touched no script and ran no archive |
| **C-8** | stage 4's row: `bash .harness/scripts/verify_all.sh` from the repo root, PASS 17 / WARN 0 / FAIL 0 / SKIP 1, baseline, after round 1 and after CR-1's insertion | ⚠️ artifacts corroborate the metric (F.2 passes at 89); the run itself → stage 6 |
| **C-9** | fixtures under `test/t27/`, own-copy runs, template read-only in `test/t27/refresh/` | ✅ confirmed by listing; `git status --porcelain -- test/` → stage 6 |
| **C-10** B-3's opening true of `upgrade-project.sh` | `80-delivery-policy.md:68-74` | ✅ **discharged and unchanged by round 2.** `refresh_set` at `:186-194` names exactly the seven pairs listed; the loop's `cp` at `:218-226` writes no backup and preserves no marker; `verify_all.{sh,ps1}` is excluded — `:136-138` states the invariant and `:141` puts them in `known`. The wholesale-replacement claim is scoped to `refresh_set` and asserts nothing of `verify_all.{sh,ps1}`. F-11 closed. Two sub-line imprecisions in `05_RATIONALE.md` §6, neither false enough to act on |
| **C-11** B-1 ships without the per-kind list | `70-doc-size.md:80-96` carries no table; stage 4's V-9(a)/(b) rows | ✅ shipped text confirmed; no stage records `measurement obligation → rationale` |
| **C-12** every B-3 check records command, exit status, number | stage 4's C-12 row (both exits 0) | ✅ for this task — and CR-1 is what makes its expiry survivable |
| **C-13** caps cell, three properties, no line added | `70-doc-size.md:27` | ✅ **discharged.** (1) measurement named — "the file's **line** count, the one `verify_all` F.4 takes"; (2) points at rule 80 by that section's exact heading, spelled identically to `80-delivery-policy.md:66`; (3) names no version, template or fix state. One physical line before and after; rows `:23-26` and `:28-30` untouched in form. CR-5 is a completeness note, not a C-13 failure |
| **C-14** clause (d) without the home enumeration, B-1 ≤35 | `70-doc-size.md:94-96` | ✅ **discharged.** The em-dash enumeration is gone with no substitute; stage 1's `## Resolved questions` and stage 3's `## Findings` are reached by the precedence sentence at `:90-92`. Section is **17** content lines. Addresses now cited correctly in stage 4 (CR-3) |

## Axis status
- Standards-conformance: **7 findings, worst = MINOR** (CR-3 discharged, CR-6, CR-7, CR-8, CR-9, CR-10, CR-11). The landed diff conforms to AI-GUIDE, the frozen set, the doc-size caps, rule 85 and the no-invented-rules bar; the round-2 delta earns its single line. The two live MINORs are stale/off-by-one numbers in stage-4 documents, not in shipped bytes.
- Spec/design-fidelity: **4 findings, worst = MINOR** (CR-1 **discharged**, CR-2, CR-4, CR-5). Every rule fragment this task lands now delivers the binding property its requirement states, against both the completing and the refusing form of the arriving text that exists today.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | `git diff --numstat` for the four paths, `git status --porcelain`, the shell-function count and the untouched status of `verify_all.{sh,ps1}`, `guard-rm.*`, `archive-task.ps1`, `bin/sc` and `.claude/**` were not measured at review in either round (CR-8). V-13/V-14 must take them, against the round-2 totals `+65 / −6` and `36 / 0` for rule 80. | `06_TEST_REPORT.md` |
| RES-2 | **AC-15 rides on one unmeasured input.** `.harness/insight-index.md` must end with a trailing newline. At `wc -l` = 30 the delivery run rotates `h` and lands at exactly **30** for any 1 ≤ h ≤ 22. At `wc -l` = 29 (unterminated final line) it rotates `h−1`, lands at **31**, and F.4 WARNs — RS-9 shape (i), and AC-15 fails through no fault of E-1. No V step measures it. Take `wc -l` and `tail -c 1 \| xxd` before the run. | `06_TEST_REPORT.md`, `07_DELIVERY.md` |
| RES-3 | V-2b must quote both exit statuses and record that the design's stated basis (`02_SOLUTION_DESIGN.md:31`) is contradicted by measurement — HEAD exits **0**, it does not abort (CR-2). | `06_TEST_REPORT.md` |
| RES-4 | RS-5's **second** candidate insight (`set -e` + `[[ … ]] && cmd` aborting `archive-task.sh:82`) is false and must not be written into `07_DELIVERY.md` `## Insight`. `04_DEVELOPMENT.md:94` carries the true statement. | `07_DELIVERY.md` |
| RES-5 | `07_DELIVERY.md`'s harvest source must match `archive-task.sh:58` — the heading exactly `## Insight` or `## Insights`, bullets only and blank lines. A heading with a suffix harvests **zero** and AC-15's first clause fails by construction. | `07_DELIVERY.md` |
| RES-6 | CR-4 (B-3's line citations into a file a refresh re-lands) and CR-5 (the caps cell has no route for the RS-9 WARN shapes) join RS-9/RS-11 on the row that next opens `archive-task.sh:109-136`. | `07_DELIVERY.md` (pool) |
| RES-7 | AC-9(a)'s 30-unit hand-routing and AC-11's three-commit partition are taken from stage 4; neither was re-derived at review. | `06_TEST_REPORT.md` |
| RES-8 | C-6 is discharged for stages 4 and 5 only. Stage 6's per-criterion V-1…V-16 outcomes fit no declared shape of `06_TEST_REPORT.md` — `agents/qa-tester.md:30-33` sends such a unit to a `## Defects found` schema-gap row, not to a new section. Stage 7 owes the same check. | `06_TEST_REPORT.md`, `07_DELIVERY.md` |
| RES-9 | An index entry occupying more than one physical line (only reachable by hand edit — `archive-task.sh:57-71` joins every harvested bullet) is counted by `index_lines`, classified non-bullet, and hoisted into the header by `:118`. Same mechanism as C-3(iii); RS-9's statement should name it rather than only the trailing-blank case. | `07_DELIVERY.md` (pool) |
| RES-10 | CR-10 and CR-11: `04_RATIONALE.md` §6's three stale numbers (`35 / 0` → `36 / 0`, total `64` → `65`, rule 80 `88` → `89`) and `04_DEVELOPMENT.md:23`'s bullet address (`:15` → `:16`). Bounded corrections to stage-4 documents, no landed byte involved, no re-review round required; stage 6 re-measures the same numbers under RES-1 and must not inherit the stale ones. | `04_RATIONALE.md`, `04_DEVELOPMENT.md` (PM-directed), then `06_TEST_REPORT.md` |

## Verdict
APPROVED WITH CONDITIONS (0 CRITICAL, 0 MAJOR; CR-1 and CR-3 discharged on the landed bytes) — conditions are RES-10's two document corrections and RES-1…RES-9 as stage-6/7 obligations; no shipped byte is in question and no further review round is required.
