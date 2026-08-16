# 06 — Test Report · T-32 `record-accuracy-sweep`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

## Test plan

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 R-63's clause is true of `parse_ss` | AST enumeration of every `Load` of the name bound by `body.rsplit("@", 1)`, with the enclosing call named; mutant M-11 adds a second consumer | `scratchpad/ac1_userinfo.py`, `scratchpad/mutants.py` |
| AC-2 zero executable lines | folded-AST identity HEAD↔work with the normalisation audited (`str` only), node count, top-level def order, positional `str`-constant diff, comment-token multiset; `python3 -m py_compile bin/sc`; mutants M-02…M-05, M-08…M-10, M-17 | `scratchpad/res3_ast.py`, `scratchpad/mutants.py` |
| AC-3 the `backslashreplace` cost clause is true of the build it describes | `git show 6d16caf^:bin/sc` retrieved and read in source order at both named sites; extended over **all 21** commits that ever touched `bin/sc` | `scratchpad/sc_pre_T25.py`, `scratchpad/ac3_history.py` |
| AC-4 `stored_delays()`'s two-clause `port` contract | guard, docstring, `# Clash API` file-map row and utilities row read side by side; mutant M-09 weakens the guard | `bin/sc:2299-2308`, `docs/dev-map.md:42,68` |
| AC-5 the sentence's directive set | `_apply_directive` / `_anchor_index` / `_directive_of` insert positions enumerated; shipped sentence grepped for all five directive names | `06_RATIONALE.md` §5 |
| AC-6 `sc reload` offered only for causes regeneration repairs | composition order read (`:2107` then `:2117`); two attacks — `dns: null` and a chained `$replace: []` + `$append` | `06_RATIONALE.md` §5 |
| AC-7 the `zh` twin's placeholder set | equality read in **both** directions by `ast.parse`; key↔call-site identity across the implicit concatenation; mutants M-14 (drop) and M-15 (add) | `scratchpad/ac7_placeholders.py` |
| AC-8 the filed "four" tested, not inherited | independent per-directive derivation → **three** | `06_RATIONALE.md` §5 |
| AC-9 the lead's transition set = the derived set | `git show d849234{,^}:bin/sc`; per-probe class movement over all three probes; exhaustive 3×3 transition table; `1 → 0` unreachability proved from `is_running()` + `_doctor_service()`; document-level set comparison + mutants D-04…D-06 | `scratchpad/sc_pre_T26.py`, `scratchpad/doc_mutants.py` |
| AC-10 the UNKNOWN-no-PROBLEM host | drift row read in the **pre-T-26** build; before/after pair named | `06_RATIONALE.md` §4 |
| AC-11 the filed wording not adopted | delivered lead compared against the derived table | `CHANGELOG.md:29` |
| AC-12 each rule-80 clause resolves to its code | zero-range grep over the paragraph; each of the five tokens read **at its site** in the arriving script; mutants D-07, D-08 | `scratchpad/doc_mutants.py` |
| AC-13 the repointable-`Path` count | AST enumeration of `Path`-valued module constants + depth-0 `Load` census; document numbers compared with it; mutants D-01…D-03 | `scratchpad/ac13_paths.py`, `scratchpad/doc_mutants.py` |
| AC-14 the committed assertion count | `--list` (no module load) = 19; `baseline.json:4` = 19; B.4's invocation + floor logic read; tree-wide sweep for count claims | `06_RATIONALE.md` §8 |
| AC-15 rule 50's preamble names only a SKIP | preamble parsed and compared with the run's SKIP set; mutant D-09 | `scratchpad/doc_mutants.py` |
| AC-16 R-77/R-78/R-84 discharged and untouched | `git diff -U0` hunk offsets vs the recipe block; `git log -S` per clause; each clause read against delivered `bin/sc` | `06_RATIONALE.md` §8 |
| AC-17 the R-74 ruling | amended row read against the FR-1 classification table; eleven-id reachability sweep | `docs/tasks.md:16,162` |
| AC-18 no mechanism added | `git diff --numstat` file set; `verify_all` step set compared run-to-baseline | `scratchpad/nfr2_lines.py` |
| AC-19 `verify_all` no FAIL | three full runs, output recorded | `06_RATIONALE.md` §1 |
| AC-20 both languages, `失败：`/`failed: ` untouched | README search recorded (0 hits) + widened search; diff-wide literal grep | `06_RATIONALE.md` §8 |
| AC-21 the live host | `systemctl show` before/after; mtimes; timer/unit provenance | `scratchpad/host-{before,after}.txt` |

## Adversarial tests

One row per acceptance criterion. Every reproducer is **mine**, written from the criterion, not
from `04_DEVELOPMENT.md`'s test code. `NOT-DISCRIMINATING` means the criterion's own stated check
cannot separate a good delivery from a bad one; it is never reported as a pass.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | the clause is satisfied by merely existing — a second consumer of the binding exists somewhere in `parse_ss` | `python3 scratchpad/ac1_userinfo.py` (NEW) | **Survived** — `NAME 'userinfo'  stores=[796]  loads=[(798, 30)]` / `load at :798 -> enclosing call: _b64dec(userinfo)`. Mutant M-11 (second consumer) → `AC-1 DIFF -> KILLED`, so the check discriminates |
| AC-2 | an executable change hides behind the `str`-normalisation, or the normalisation folds more than `str` | `python3 scratchpad/res3_ast.py` + `scratchpad/mutants.py` (NEW) | **Survived** — `nodes=15550 … other-constant-kinds={'int': 151, 'bytes': 3, 'bool': 100, 'NoneType': 111}` on both sides, `identity: True`, `differing str constants: 3`, `comment tokens +4`. Mutants M-03/M-04/M-05 (int/bytes/bool) all `KILLED`. **The criterion's `py_compile` and B.4 legs are NOT-DISCRIMINATING** — every mutant compiles and B.4 reads none of this |
| AC-3 | one of the two named sites cannot be settled from source order, or the loss *was* available on some older build | `git show 6d16caf^:bin/sc` + `python3 scratchpad/ac3_history.py` (NEW) | **Survived, neither site BLOCKED** — `3305: prefix = f"  ↓ {fname} ... "` / `3306: print(prefix, end="", flush=True)` precede `3317: for base in bases:`; `_doctor_permissions()` emits its em-dashed summary row before any `{path}` detail and no `{path}` row at all on the clean branch. Extended: over **all 21** historical builds, `before=True` in every build with a base loop and every `iterdir()`-derived `{path}` string non-ASCII |
| AC-4 | a named port is still overridden by the liveness guard | read `bin/sc:2307` + all call sites (NEW) | **Survived** — `if port is None and not is_running():`; call sites are `:2384 stored_delays()` and `:2934 stored_delays(port=port)`. Mutant M-09 (drop `port is None and`) → `KILLED`. All three statement sites agree |
| AC-5 | a directive that cannot reach index 0 is named, or one that can is missing | `_apply_directive`/`_anchor_index` read; `sed -n '312,313p' bin/sc \| grep -oE '\$(prepend\|append\|replace\|before\|after)'` (NEW) | **Survived under G-7** — grep returns `NONE`; the shipped sentence names no directive. Set re-derived independently = `{$prepend, $replace, $before-at-anchor-0}` |
| AC-6 | an override can produce a displaced head that the sentence promises `sc reload` will repair | two attacks: `dns: null`, and `$replace: []` chained with `$append` (NEW) | **Survived — both attacks refuted by the code.** `2125: for at in ("dns.rules", …)` / `2126: if not isinstance(_dig(config, at), list):` → `sc` cannot generate a document with no `dns.rules`, so that branch really is stale-or-hand-edited; `_directive_of` raises on two directives in one object, and `_merge` runs once |
| AC-7 | the `zh` twin drops a placeholder and the criterion's `[B]` leg still passes | `python3 scratchpad/ac7_placeholders.py` + mutant M-14 (NEW) | **Survived on the equality read; the criterion's own B.4 leg is NOT-DISCRIMINATING.** `EN subset of zh : True / zh subset of EN : True / SETS EQUAL: True`; M-14 (`zh` drops `{override}`) → `AC-7-equality DIFF` but `B.4-subset-only SAME`. Reported per G-9, established by reading `check-sc-contracts.py:455-475`, not by a B.4 PASS |
| AC-8 | the filed "four" is right and the delivery's "three" is wrong | per-directive derivation from the applier (NEW) | **Survived** — `$after` inserts at `i+1` with `i = hits[0] ≥ 0` (`:1430`, `:1449`); `$append` concatenates at the tail and `dns.rules` is never empty at merge time (`_dns_overlay` prepends one element `:1786`, the array guard `:2125-2130`). **Three**, filed four refuted |
| AC-9 | the lead states a strict subset of the derived set, or the derivation itself is an incomplete enumeration presented as exhaustive | `git show d849234{,^}:bin/sc` + exhaustive 3×3 table + `scratchpad/doc_mutants.py` (NEW) | **Survived, both directions** — `lead states [('0','1'),('1','2'),('2','1')] (closed=True) ; derived [('0','1'),('1','2'),('2','1')]`. `1 → 0` proved unreachable: `is_running()` is hard-`False` only where `_doctor_service()` returns two UNKNOWN rows or a PROBLEM row. D-04 (drop a transition), D-05 (add `1 → 0`), D-06 (drop the closure) all `KILLED` |
| AC-10 | the witness host's own displacement trips the drift row, destroying the "no PROBLEM row" premise | read `_drift_state()` + the drift row **in `git show d849234^:bin/sc`** (NEW) | **Survived** — `2627: if drift is None:` / `2628: drift_row = (DOCTOR_UNKNOWN, "config drift",` in the pre-T-26 build, byte-identical to delivered `:2709-2713`. Pair **2 → 1**, reachable, and stated in the shipped lead |
| AC-11 | the filed 「没有哪台机器的退出码会变小」 was adopted anyway | grep the delivered lead against the derived table (NEW) | **Survived** — the lead states `2 → 1` with 「它的退出码**变小了**」, i.e. it says the opposite of the filed wording. `DOCTOR_EXIT = {DOCTOR_OK: 0, DOCTOR_UNKNOWN: 2, DOCTOR_PROBLEM: 1}` (`bin/sc:2554`) is the refutation |
| AC-12 | a token greps but anchors a different mechanism than the clause claims | each token read **at its site** in `upgrade-project.sh` + mutants D-07/D-08 (NEW) | **Survived** — `542: verb="VERIFY-SPLICE"` inside the awk splice; `549: emit "VERIFY-HALT|$shell"` in the unmarked-custom-checks branch that leaves the file untouched; `571: bak="$proj_file.bak-$stamp"` / `cp` **before** the write. Zero ranges (`ranges=[]`); no `.bak` in the refresh loop |
| AC-13 | the count-only repair was made, or the property is asserted of all nine | `python3 scratchpad/ac13_paths.py` + D-01/D-02/D-03 (NEW) | **Survived** — `Path-valued module constants: 9`, `CFG_DIR 6 [24, 25, 26, 27, 32, 38]`, `the other eight 0 each`, `function-body-only: 8 of 9`. Doc says `nine/eight/CFG_DIR`; code has `9/8/['CFG_DIR']`. All three mutants `KILLED` |
| AC-14 | a delivered document states a count the tree does not carry, or the criterion's B.4 leg is not executable | `check-sc-contracts.py --list` + tree-wide count sweep (NEW) | **Survived against the tree** — `--list` prints 19 names (returns at `:903-905`, before `load()`); `baseline.json:4 test_count: 19`; `docs/tasks.md:230-231` = 19; `dev-map.md:87` and `50-singbox-cli.md:29-30` state none. **The "read B.4's own `N defined` line from a run" leg is not executable as written** — B.4 prints that line only on FAIL (`verify_all.sh:105-106`); discharged by `--list` plus the invocation reading |
| AC-15 | the preamble names a step that is no longer a SKIP | preamble parsed vs the run's SKIP set + mutant D-09 (NEW) | **Survived** — `preamble names ['B.3'] ; the run SKIPs ['B.3']`; `[B.3] Lint ... SKIP` is the run's only SKIP. D-09 (restore `B.2/B.3`) → `KILLED (names ['B.2','B.3'])` |
| AC-16 | a byte inside the frozen recipe block moved, or the discharging task is not the one claimed | `git diff -U0 -- docs/dev-map.md` + `git log -S` per clause (NEW) | **Survived** — hunks at `@@ -33 +33 @@`, `-42 +42`, `-81 +81`, `-87 +87`, all outside `:204-242` and `:76`. All three clauses land in `2ea5e16` (T-28); each is true of delivered `bin/sc` (`:125-126`, `:3843`, recipe `:210`) |
| AC-17 | a disposition is stated as an aside, or one of the eleven is unreachable after the rotation | eleven-id reachability sweep + rotation verbatim check (NEW) | **Survived** — every id resolves in `docs/tasks.md` ≥3 times; five pointer lines at `:135,187,204,227,252`. Of 19 removed lines, 16 arrive verbatim in the archive; the 3 that do not are the replaced heading, the R-74 row (amended in place per FR-10) and the `test_count 18`→`19` correction |
| AC-18 | a check, script or step was added somewhere the ledger does not name | `git diff --numstat` + step-set comparison (NEW) | **Survived** — 10 files, no `.harness/scripts/**`, no new file, no `verify_all.sh` change; the run reports the same 21 steps as the task-start baseline. `NFR-2: 26 changed lines outside the process paths (ceiling 30)` |
| AC-19 | a corrected sentence being false would redden the run | 3× `bash .harness/scripts/verify_all.sh` + provenance grep (NEW) | **PASS but NOT-DISCRIMINATING for FR-1…FR-9.** `PASS: 20 / WARN: 0 / FAIL: 0 / SKIP: 1`, exit 0, three times. No committed assertion quotes any of the seven corrected sentences (the only hit is `check-sc-contracts.py:440`, a *docstring*), and `verify_all.sh` reads none of the five documents. It is a regression control, not evidence of truth |
| AC-20 | a README carries a counterpart that was left behind, or a `失败：`/`failed: ` line moved | README search + diff-wide literal grep (NEW) | **Survived** — the targeted README search returns `exit=1`, 0 hits; the widened `AAAA`/`dns.rules` search finds only the `sc ipv6` block, the doctor row-4 cell (describes what the row *checks*, still true), the exit-code table and the override recipe. Added-or-removed lines carrying either literal across all ten files: **0** |
| AC-21 | this task disturbed the host, or the witness must be inherited to close | `systemctl show` before/after + `ls -la` + timer provenance (NEW) | **Survived, nothing inherited** — `MainPID=1776263 … NRestarts=0 … ActiveEnterTimestamp=Mon 2026-08-17 00:44:47 CST`, `diff host-before host-after → IDENTICAL`, `/etc/sing-box` mtime `2026-08-11 12:13:57` unmoved. **The instance change is now explained**: `sing-box-rules-update.timer LastTriggerUSec=Mon 2026-08-17 00:44:43 CST` ran `/usr/local/bin/sc update-rules`, which exited at `00:44:47` — the unit's own `ActiveEnterTimestamp` |
| **trap** | (the inverted R-22 trap itself) a criterion is satisfied by *any edit to the named line* rather than by the corrected sentence being true | `python3 scratchpad/trap_mutant2.py` (NEW) — mutant T-2 inverts the AAAA sentence's advice, all three sites together, placeholder set preserved | **Confirmed present, and named.** `folded-AST identical to HEAD: True/True · str constants differing from HEAD: 3/3 · comment tokens added: 4/4 · AC-7 placeholder sets EQUAL: True/True · B.4 subset assertion passes: True/True` — `identical signature on every mechanical check: True`. No mechanical check in this project separates the true correction from a false one; only the derivations in `06_RATIONALE.md` §3-§5 do |

## Boundary tests added

- Empty override payload: `$prepend: []` and `$before` with `values: []` cannot change index 0 — the "reaches element 0" derivation is stated for non-empty payloads only.
- Empty target array: `$append` reaches index 0 **iff** `dns.rules` is empty at merge time; proved impossible by two independent guards (`_dns_overlay`'s one-element `$prepend`, the composed-array guard at `bin/sc:2125-2130`).
- Absent array: `config.json` with `dns` absent or not a dict → `rules is None` → the same PROBLEM return (`bin/sc:2798-2802`); the corrected sentence is a non-existence claim and its `sc reload` clause is the correct advice there, because `sc` can never generate such a document.
- Two directives in one merge value: `_directive_of` raises `OverrideError` (`bin/sc:1394-1398`), so no directive chain can empty an array and then append into it.
- Unicode at a non-UTF-8 stdout: both `backslashreplace` sites re-checked under the `LC_ALL=C PYTHONUTF8=0` premise, in retrieved historical text, at the character level (`↓` U+2193, `—` U+2014).
- Placeholder-set boundaries in both directions: a `zh` entry that **drops** a placeholder (M-14) and one that **adds** one (M-15).
- Constant-kind boundary for the AST normalisation: `int`, `bytes`, `bool` and `None` constants are each mutated and each caught (M-03/M-04/M-05), so the fold is `str`-only.
- Historical boundary: the AC-3 claim re-checked at **every** commit that ever touched `bin/sc`, not only the immediately preceding build.
- Empty-count boundary for AC-14: `--list` is used because it returns before any module load, so the count is taken without an import.
- Repeat execution: three consecutive `verify_all` runs, step lines compared by digest.

## verify_all result

- Total tests: 19 → 19 (`check-sc-contracts.py --list` = 19; `baseline.json:4 test_count` = 19)
- Steps: 21 → 21 (no step added, removed or renamed)
- Pass: 20
- Fail: 0
- Warn: 0
- Skip: 1 (B.3 Lint — the run's only SKIP, which is what rule 50's corrected preamble names)
- Exit code: 0, on each of four runs — three over the delivered tree, and a fourth after both stage-6 documents existed (E.6 PASS over this report's `## Adversarial tests` heading; F.6 PASS at `06_RATIONALE.md` = 500 lines)
- New tests added: 0 committed — FR-11 declines every new mechanism and AC-18 forbids adding a check; the QA reproducers are deliberately uncommitted and are reproduced verbatim in `06_RATIONALE.md`
- Baseline updated: no — nothing to raise; the floor was never lowered (B.6 PASS, `test_count` 19 at HEAD and in the working tree)
- Operator obligations appended: none — no criterion ended BLOCKED, so `.harness/operator-obligations.md` is untouched

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| QA-1 | MAJOR | `systemctl show -p MainPID sing-box` → `MainPID=1776263`, against the row's `2566751`. The T-32 delivery row states the host witness as "`MainPID` 2566751, `NRestarts` 0, `ActiveEnterTimestamp` identical before and after" — a figure no instance on this host bears, and one the delivery's own final run (`04_DEVELOPMENT.md:61-62`) contradicts. This is the task's own defect class inside the task's own delivery record. AC-21 itself is unaffected: the task disturbed nothing and each run's before/after pair is identical. One-line PM edit at delivery (drop the parenthetical, or write `1776263` / `Mon 2026-08-17 00:44:47 CST`), already routed as CR-5 / RES-10 | `docs/tasks.md:16` |
| QA-2 | MINOR | `grep -n '14 contract assertions' docs/tasks.md` → `:277`, present tense ("**still says**"), of text **this task deleted** from `.harness/rules/50-singbox-cli.md:29`. Verified untouched by this diff (no hunk past `@@ -258 +251,2 @@`), so it is not a regression *introduced* by editing that line — but it was made false *by* this delivery and is not repaired. Outside R-94's declared five-clause population; filed-row candidate, as CR-4 / RES-7 rules | `docs/tasks.md:277` |
| QA-3 | MINOR | `grep -c 'sentences' docs/tasks.md` at `:16` — the row opens "eleven filed **sentences** swept, seven corrected" while its own text and the decline record both count **rows** (R-94's population is "five clauses not the three filed", so under a *sentence* population eleven and seven are understated). Not false under the programme's settled reading; one word while the PM is editing the row for QA-1 anyway. Already routed as CR-6 / RES-10 | `docs/tasks.md:16` |
| QA-4 | MINOR | `python3 scratchpad/ac1_userinfo.py` → `SPLIT line=807 targets=(method_pwd, hostpart) subject=decoded meth=rsplit args=['@', 1]` then `:808 method_pwd.split(':', 1)`. `parse_ss`'s **else**-branch applies both of `_userinfo()`'s rules — the last-`@` split and the first-colon boundary — to `decoded`, and carries no clause. Outside R-63's subject (its input is base64-decoded text, not URI text) and outside this task's scope, so AC-1 passes; filed-row candidate for the next task that opens `parse_ss`, because it is R-63's own trap with a sibling | `bin/sc:807-808` |

No BLOCKER and no CRITICAL. No defect blocks delivery; QA-1…QA-3 are PM edits at delivery and QA-4
is a filed-row candidate.

## Stability

- `bash .harness/scripts/verify_all.sh` run **three** times over the delivered tree: `PASS: 20 / WARN: 0 / FAIL: 0 / SKIP: 1`, exit 0 each time; the step lines are byte-identical across runs (`md5sum` of the `^\[` lines = `671c0101fefe44e6617b85edbb14d8f9` three times). No flakes observed, none named.
- A fourth run, taken **after** this report and its rationale existed, reports the same figures and `EXIT=0`. Disclosed rather than quietly fixed: at 502 lines `06_RATIONALE.md` tripped `[F.6] Active task docs <=500 lines each ... WARN` (`PASS: 19 / WARN: 1`, exit **1**) — a WARN introduced by *this stage's own document*, not by the delivery. It was trimmed to 500 lines with no evidence removed and the run is green again. Nothing in `verify_all` was modified.
- The live host's witness is identical before the stage's first command and after its last (`diff host-before.txt host-after.txt` → IDENTICAL); `is-active` was never invoked.
- Both mutation batteries are deterministic: 17 `bin/sc` mutants run, **17 killed, 0 survivors**; 9 document mutants run, **9 killed**. One batch was re-run after a defect in **my own** check (`chk_ac9` matched `CHANGELOG.md:26` as well as `:29` and produced three kills for the wrong reason); the extractor now asserts uniqueness of the lead, and the corrected battery is what is reported.
- `ps`'s start time reads `Mon Aug 17 00:44:46` against `ActiveEnterTimestamp=… 00:44:47` — the predicted one-second rounding artefact, observed and not a second instance.

## Verdict

APPROVED FOR DELIVERY
