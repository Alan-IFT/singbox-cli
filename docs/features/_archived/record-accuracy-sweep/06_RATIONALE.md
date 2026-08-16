# 06 — Rationale · T-32 `record-accuracy-sweep`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

## 0 — Method, and one decision recorded

**Every criterion was re-taken first-hand.** No figure in this stage is inherited from
`04_DEVELOPMENT.md`, `05_CODE_REVIEW.md` or the dispatch — including the two the dispatch offered
as already discharged (RES-9's `sha256sum` and `git diff --stat`), one of which turned out to be
mis-transcribed (§9).

**Decision (standing authority):** the reproducers below are **not committed**. `FR-11` declines
every new mechanism and `AC-18` requires the delivered diff to add no check, script or template;
committing a QA harness would fail the criterion it exists to check. They live in this stage's
scratch directory and are **reproduced verbatim here**, so any later run can re-take them.
`baseline.json` is consequently not raised: the delivery defines no new assertion, and the floor
only ever goes up (B.6 PASS).

**Decision (safety):** `NFR-4` / `BC-9` forbid importing `bin/sc` outside `verify_all` B.4. Every
check below is therefore `ast.parse` / `tokenize` / text only — including the mutation batteries,
evaluated against in-memory scratch copies that are **never imported and never executed**.
`check-sc-contracts.py --source <mutant>` was available and was **not** used: it would import a copy
of `bin/sc` outside B.4. The one module load is B.4's own, through the mandated
`docs/dev-map.md:204-214` recipe; `--list` was run once and returns at `:903-905`, before `load()`.

---

## 1 — AC-19 · the three `verify_all` runs, in full

```
$ bash .harness/scripts/verify_all.sh          # run 1 of 3
Project: singbox-cli
Stack:   Python 3 CLI (sc) + Bash installer/uninstaller, systemd/OpenRC service units, multi-distro package managers (apt/dnf/pacman/zypper/apk), sing-box binary management

[A.1] No hardcoded secrets ... PASS          [A.2] No .env files committed ... PASS
[B.1] Syntax (bin/sc, install.sh, uninstall.sh) ... PASS   [B.2] install.sh bilingual key parity ... PASS
[B.3] Lint ... SKIP                          [B.4] bin/sc contract assertions ... PASS
[B.5] restricted-network self-check ... PASS
[B.6] Assertion floor never below its last committed value ... PASS
[E.1] Bootstrap files present ... PASS      [E.2] workflow.md present ... PASS
[E.3] Agents layout v0.30+ (.harness/agents/ = partition dev-* only) ... PASS
[E.4] Binding in sync (.harness/ -> .claude/) ... PASS      [E.4b] Hook commands resolve ... PASS
[E.5] AI-GUIDE.md indexes every .harness/rules/*.md ... PASS
[E.6] Adversarial tests section in completed task reports ... PASS
[F.1] AI-GUIDE.md <=200 lines ... PASS      [F.2] Rule fragments <=200 lines each ... PASS
[F.3] Agent definitions <=300 lines each ... PASS      [F.4] insight-index.md <=30 lines ... PASS
[F.5] docs/tasks.md <=300 lines ... PASS    [F.6] Active task docs <=500 lines each ... PASS

=== Summary ===   PASS: 20   WARN: 0   FAIL: 0   SKIP: 1        EXIT=0
```
(the E/F block is reflowed two-per-line for width; every step line is verbatim otherwise)

Runs 2 and 3 are byte-identical on the step lines:

```
$ for i in 1 2 3; do grep -E '^\[' verify_run$i.txt | md5sum; done
671c0101fefe44e6617b85edbb14d8f9  -    671c0101fefe44e6617b85edbb14d8f9  -    671c0101fefe44e6617b85edbb14d8f9  -
```

**What a PASS here does and does not establish.** No committed assertion quotes any of the seven
corrected sentences (`grep -n 'does not carry\|at the head of\|first dns.rules'
.harness/scripts/check-sc-contracts.py` returns only `:440`, a *docstring* of
`dns_overlay_prepend_is_head_of_dns_rules`), and `verify_all.sh` reads none of the five documents
the other six corrections live in. A green run is therefore compatible with all seven corrections
being false. It is a regression control, not evidence for FR-1…FR-9.

---

## 2 — RES-3 / AC-2 / NFR-1 · the AST identity, re-derived with the normalisation audited

`scratchpad/res3_ast.py` — folds **only** `str` constants (every other constant kind is left in
place and its census printed, which is the check RES-3 asked for), then compares dumps, node
counts, top-level def order, the positional `str`-constant list, and the comment-token multiset.

```
HEAD   nodes=15550 top-level-defs=113 str-constants-folded=1896 other-constant-kinds={'int': 151, 'bytes': 3, 'bool': 100, 'NoneType': 111}
WORK   nodes=15550 top-level-defs=113 str-constants-folded=1896 other-constant-kinds={'int': 151, 'bytes': 3, 'bool': 100, 'NoneType': 111}

AST identity after folding ONLY str constants: True ; top-level def order identical: True ;
node counts equal: True (15550 vs 15550)
str constants: HEAD 1896, WORK 1896     differing str constants (positional pairing): 3
  #283   HEAD@:312  len=171 '…does not carry this decision as the first dns.rules entry…'
       -> WORK@:312  len=274 '…does not carry that decision at the head of its dns.rules…'
  #466   HEAD@:313  len=98  '…dns.rules 第一条不是该决策对应的规则…' -> WORK@:313 len=127 '…dns.rules 开头没有…'
  #1338  HEAD@:2800 len=171 (the call-site literal) -> WORK@:2804 len=274, byte-identical to #283

comment tokens: HEAD 560, WORK 564, delta +4 — all four at :792-:795, the R-63 clause; none removed
```

`int 151 / bytes 3 / bool 100 / NoneType 111` on both sides is the audit RES-3 wanted: the
normalisation folds nothing but `str`, so an edit to any other constant would surface — mutants
M-03 (int), M-04 (bytes) and M-05 (bool) confirm it empirically (§7). `python3 -m py_compile bin/sc`
→ exit 0; `sha256sum bin/sc` → `0afdc3b6…f669` (§9), matching the developer's claim.

---

## 3 — RES-1 / AC-3 / G-16 · the historical retrieval, taken first-hand

```
$ git log -S 'backslashreplace' --oneline -- bin/sc
6d16caf fix(sc): give the user-facing output layer one contract (T-25)
$ git show 6d16caf^:bin/sc > sc_pre_T25.py ; wc -l → 3743 ; grep -c backslashreplace → 0
```
No `sc` — historical, current or installed — was executed. Only `git show` and reading.

**Site 1 — the `SB_RULES_BASE` / `--mirror` base**, retrieved text, `cmd_update_rules` from `:3296`:

```
3305:        prefix = f"  ↓ {fname} ... "          3306:        print(prefix, end="", flush=True)
3317:        for base in bases:   ← the first line that can carry a base string
3343:            print(t("failed: {e}", e="; ".join(causes)))    ← the cause list
```

`↓` is U+2193, `sc`-authored, unencodable on an ASCII stdout; `RULESET_FILES` is a 4-tuple
(`:106-111`) so the loop body is always entered; `main()` carries no `except` around the dispatch
(`grep -n 'except Exception'` → `:2355, :2436, :2866, :2987, :3331`, none enclosing it), so the
`UnicodeEncodeError` ends the run before any base string reaches a printed line. **SETTLED.**

**Site 2 — `_doctor_permissions()`'s `{path}` rows.** Retrieved text `:2870-2950`:

```
2933: t("{n} path(s) grant access to group or other — run the command shown for each", n=wide)  ← em dash
2938: t("{n} path(s) could not be judged — see below", n=links)                                 ← em dash
2945:    for line in details[:DOCTOR_MSG_LINES]:   rows.append(...)   ← details appended AFTER
```
Every `{path}` string built from `iterdir()` also carries an em dash (`:2901`, `:2920`), and the
clean-host branch (`:2940-2943`) returns one row naming no path. **SETTLED.** Neither site is
BLOCKED; no row is filed; both stay named in the delivered clause (`docs/dev-map.md:81`).

**Extension the delivery did not take — the strong quantifier.** The delivered clause says the
loss was "not a loss **any shipped build** took". `scratchpad/ac3_history.py` re-takes both
properties over **every one of the 21 commits that ever touched `bin/sc` up to `6d16caf^`**:

```
ab4e4a4 …  upd: first-nonascii-const@1088 ↓ ; base-loop@1099 ; before=True   (first build with a base loop)
…  every later build up to 6d16caf^: before=True
46fc683 …  perm: {path} strings -> @2843 nonascii=True '{path} is mode {mode} — run: {cmd}'; @2862 True …
```
Before `ab4e4a4` there is no base loop at all (no `_ruleset_bases()`, so the clause's subject does
not exist); after it, the `↓` constant precedes the loop in every build. `_doctor_permissions()`
first appears at `46fc683` and in every build its `iterdir()`-derived `{path}` strings carry a
non-ASCII character. The two ASCII-only `{path}` strings per build (`no directory at {path}`,
`cannot read {path}: {e}`) take `str(CFG_DIR)`, a module constant, not an `iterdir()` product —
outside the clause's subject. The strong quantifier **holds**.

---

## 4 — RES-2 / AC-9 / AC-10 / AC-11 / G-2 / G-3 / G-4 · the exit-code derivation, re-taken

```
$ git log -1 --format='%h %s' d849234
d849234 fix(sc): make three `sc doctor` rows establish the fact they report (T-26)
$ git show d849234^:bin/sc > sc_pre_T26.py ; git show d849234:bin/sc > sc_T26.py
```
Mapping, identical in **both** builds (`sc_pre_T26.py:2474/2478`, delivered `bin/sc:2550/2554`):
`DOCTOR_OK, DOCTOR_UNKNOWN, DOCTOR_PROBLEM = 0, 1, 2` (ordered) and
`DOCTOR_EXIT = {OK: 0, UNKNOWN: 2, PROBLEM: 1}`; `worst = max(worst, cls)` over rows with
`cls is not None` (`bin/sc:3110`), `sys.exit(DOCTOR_EXIT[worst])` (`:3111`).

**Population — all three probes `CHANGELOG.md:29` names, from the retrieved diff:**

| probe | before | after | class movement |
|---|---|---|---|
| IPv6 (AAAA) | `_aaaa_rule(suppress) in rules` — membership anywhere | `rules[:len(prepend)] == prepend` — head only | **OK → PROBLEM** only. PROBLEM→OK impossible: after-OK implies head, which implies membership, which implies before-OK. `rules is None` → PROBLEM in both. The UNKNOWN branches are byte-identical. |
| node delays | `if not is_running(): return {}, None` → `0/N` → PROBLEM on an init-less host | `if port is None and not is_running():` → doctor already passed `port=port` in **both** builds (`sc_pre_T26.py:2845`, `sc_T26.py:2851`), so the guard is bypassed and the answer is read | **PROBLEM → OK** only, and only where `is_running()` is False and the API answers |
| DNS 解析 | PROBLEM / OK / PROBLEM over three branches | PROBLEM / OK / PROBLEM — only the three sentences changed | **none** |

**Exhaustive transition enumeration** (`X` = the max class of every unchanged row):

| change set | before | after | X = OK | X = UNKNOWN | X = PROBLEM |
|---|---|---|---|---|---|
| AAAA only | `max(OK,X)` | `max(PROBLEM,X)` | **0 → 1** | **2 → 1** | 1 → 1 |
| delays only | `max(PROBLEM,X)` | `max(OK,X)` | 1 → 0 — **unreachable** | **1 → 2** | 1 → 1 |
| both | `max(OK,PROBLEM,X)` | `max(PROBLEM,OK,X)` | 1 → 1 | 1 → 1 | 1 → 1 |

**`1 → 0` unreachability, proved from the retrieved text rather than asserted.** The delays change
requires `is_running()` False. `is_running()` (`sc_T26.py:2201-2207`) returns a hard `False` when
neither `SYSTEMD` nor `OPENRC`. `_doctor_service()` (`:2728-2742`) returns **two UNKNOWN rows** in
exactly that case, and a **PROBLEM** service row when an init system reports not-running. So every
host on which the delays row can move carries an UNKNOWN or a PROBLEM row, and `X = OK` is empty.

**Derived set = `{0→1, 2→1, 1→2}`.** The delivered lead states `0 → 1`, `2 → 1`, `1 → 2` and
「恰好是下面三种，没有第四种」 — equal in both directions (§7, `chk_ac9`). One check the delivery
did not state: no probe changed in a way that can newly raise, so no probe newly returns
`cmd_doctor`'s except-arm UNKNOWN row — `_dns_overlay(suppress)["dns"]["rules"]["$prepend"]` and
`rules[:len(prepend)]` are total, and `clash_api()` is total by contract.

**AC-10 / G-4 — the witness's drift row, checked in the *pre-T-26* build.**

```
sc_pre_T26.py:1998  def _drift_state():  …docstring: "NO record means UNKNOWN, never drifted"
sc_pre_T26.py:2626      drift = _drift_state()          2627:      if drift is None:
sc_pre_T26.py:2628          drift_row = (DOCTOR_UNKNOWN, "config drift",
sc_pre_T26.py:2630                       t("no record of what sc last generated"))
```
Byte-identical to the delivered `bin/sc:2709-2713`. The witness host (no `.config.sha256`,
`override.json` putting its own rule at the head) therefore carries drift **UNKNOWN**, never
PROBLEM — `_drift_state()` reaches `True` only for a digest mismatch, and the host's `config.json`
is byte-for-byte what `sc` generated from that override. Before: AAAA OK + drift UNKNOWN → exit 2.
After: AAAA PROBLEM → exit 1. **2 → 1, reachable.**

---

## 5 — AC-5 / AC-6 / AC-8 · the directive derivation, and one attack that failed

`_apply_directive` (`bin/sc:1433-1458`) and `_anchor_index` (`:1410-1430`), read first-hand:

| directive | code | reaches index 0? |
|---|---|---|
| `$prepend` | `copy.deepcopy(payload) + current` `:1457` | yes (non-empty payload) |
| `$replace` | `copy.deepcopy(payload)` `:1454` | yes |
| `$before` | `i = _anchor_index(...)`; `current[:i] + values + current[i:]` `:1450` | yes, when the anchor is element 0 |
| `$after` | same insert after `i += 1` `:1449`, `i = hits[0] ≥ 0` `:1430` | no — lands at ≥ 1 |
| `$append` | `current + copy.deepcopy(payload)` `:1458` | no — while `current` is non-empty |

**Three**, not the filed four. The `$append` exception needs `current` non-empty; two independent
guards give it: `_dns_overlay` `$prepend`s exactly one element on every run (`:1786`), and
`generate_config` refuses a non-list `dns.rules` (`:2125-2130`).

**Attack that failed (worth recording).** Hypothesis: an override can chain `$replace: []` and then
`$append`, emptying `dns.rules` first and so reaching index 0 with `$append`. Refuted by
`_directive_of` (`bin/sc:1380-1398`): `len(keys) > 1` raises `OverrideError`, and `_merge` is
called exactly once with the user's document, so two directives can never apply to one array in one
run.

**Second attack that failed — G-6's branch, pushed harder.** Hypothesis: an override setting
`dns: null` produces an installed `config.json` with no `dns.rules`, for which the corrected
sentence's *first* clause ("run `sc reload` … if it is stale or was hand-edited") is wrong advice,
because regeneration would reproduce it. Refuted by the composed-document guard:

```
2125:        for at in ("dns.rules", "route.rules", "route.rule_set"):
2126:            if not isinstance(_dig(config, at), list):
2127:                raise _unusable(…, t("at {at}: this must stay an array", at=at))
```

`sc` therefore **cannot generate** a document with no `dns.rules`, so a `config.json` on disk that
carries none is stale or hand-edited — exactly the cause the sentence's first clause offers
`sc reload` for. G-6 holds, and holds for the right reason.

**Residual, recorded not filed.** An override that *removes* the head without putting a rule there
(`$replace: []`, leaving a list that passes the array guard) is displaced by neither clause: the
sentence offers no advice for it, and — because the `sc reload` offer is conditioned on "stale or
hand-edited" — offers no *wrong* advice either. AC-6's binding half ("offers `sc reload` only for
causes regeneration repairs") holds; its enumeration is not total over override causes.

---

## 6 — AC-7 / G-5 / G-9 · both directions, without B.4

```
str Constants containing 'at the head of its dns.rules': 2 at lines [312, 2804] ; distinct values: 1
EN key placeholders: ['{decision}', '{override}']    zh value placeholders: ['{decision}', '{override}']
EN subset of zh : True    zh subset of EN : True    SETS EQUAL: True
t() calls in _doctor_ipv6 carrying the mark: 1 ; call-site literal == TRANSLATIONS key: True (274/274)
call-site keywords: ['decision', 'override']   keywords cover placeholders exactly: True
EN / zh carry 失败： -> False / False ; carry 'failed: ' -> False / False
control -- raw text occurrences of the whole EN sentence: 1
```

The control reproduces F-4 on the delivered file: a whole-sentence `grep` returns **1**, which is
why K-3's check is not executable and `ast.parse` replaces it (G-5).

**G-9, established rather than accepted.** `check-sc-contracts.py:455-475` computes
`bad = sorted(f for f in got if f == "" or f.isdigit() or f not in want)` — one direction only. A
`zh` entry that **drops** `{override}` has `got ⊂ want` and raises nothing. Mutant M-14 (§7) is the
demonstration: it is killed by the equality read and **passes** the committed assertion.

**RES-6 — satisfied, and by the tree rather than obliquely.** `check-sc-contracts.py:94` states it
verbatim: `No assertion may drive cmd_status, cmd_sysproxy, cmd_log or a doctor probe.` The doctor
probe is not driven from a test, and a delivered artifact says so.

---

## 7 — The mutation batteries

### 7a — `scratchpad/mutants.py`, 18 mutants of `bin/sc` against 7 checks

Each mutant is an in-memory scratch copy; nothing is imported or executed. `SAME` means the check
cannot tell the mutant from the delivery.

```
columns: AST-identity | str-constants | comment-tokens | AC-1 | AC-13 | AC-7-equality | B.4-subset

M-01 reorder two statements in parse_ss                SKIPPED (SyntaxError — not a mutant)
M-02 add one executable statement (no-op assignment)   DIFF ------  -> KILLED by AST-identity
M-03 int constant   (CRED_MODE 0o600 -> 0o644)         DIFF ------  -> KILLED by AST-identity
M-04 bytes constant (SRS_MAGIC b"SRS" -> b"XXX")       DIFF ------  -> KILLED by AST-identity
M-05 bool constant  (flush=True -> False)              DIFF ------  -> KILLED by AST-identity
M-08 rename a top-level function                       DIFF ------  -> KILLED by AST-identity
M-09 weaken the stored_delays guard (`port is None`)   DIFF ------  -> KILLED by AST-identity
M-10 flip the AAAA head test back to membership        DIFF ------  -> KILLED by AST-identity
M-17 DOCTOR_EXIT remapped to a magnitude scale         DIFF ------  -> KILLED by AST-identity
M-06 change ONLY a comment                             SAME SAME DIFF ---   -> KILLED by comment-tokens
M-18 drop the R-63 comment block entirely              SAME SAME DIFF ---   -> KILLED by comment-tokens
M-07 change ONLY a docstring                           SAME DIFF SAME ---   -> KILLED by str-constants
M-11 second consumer of the last-@ split's product     DIFF SAME SAME DIFF  -> KILLED by AST-identity, AC-1
M-12 move a Path constant load to module level         DIFF SAME SAME SAME DIFF        -> KILLED by AC-13
M-13 add a tenth Path constant                         DIFF DIFF SAME SAME DIFF        -> KILLED by AC-13
M-14 zh entry DROPS {override}                         SAME DIFF SAME SAME SAME DIFF SAME  -> KILLED by AC-7-equality; **B.4 PASSES it**
M-15 zh entry ADDS a placeholder its key lacks         SAME DIFF SAME SAME SAME DIFF DIFF  -> KILLED
M-16 corrected EN sentence edited (ANY edit)           SAME DIFF SAME SAME SAME SAME SAME  -> "killed" only by "a string changed"

mutants run: 17 (1 skipped)   survivors: 0
```

### 7b — `scratchpad/doc_mutants.py`, document-level checks that compare the sentence with the code

```
=== baseline (delivered tree) ===
  AC-13  PASS   doc says nine/eight/CFG_DIR ; code has 9/8/['CFG_DIR']
  AC-9   PASS   lead states [('0','1'),('1','2'),('2','1')] (closed=True) ; derived [('0','1'),('1','2'),('2','1')]
  AC-12  PASS   ranges=[] missing-from-script=[] not-named=[]
  AC-15  PASS   preamble names ['B.3'] ; the run SKIPs ['B.3']

  D-01 nine->ten · D-02 property of all nine · D-03 wrong exception     -> each KILLED by AC-13
  D-04 lead drops a derivable transition · D-05 states 1 → 0 · D-06 drops the closure clause
                                                                        -> each KILLED by AC-9
  D-07 one line range re-introduced -> KILLED by AC-12 (ranges=[':186-194'])
  D-08 a token that does not grep   -> KILLED by AC-12
  D-09 preamble names a non-SKIP    -> KILLED by AC-15 (names ['B.2','B.3'])
```

**A false kill I caught and fixed, recorded because it nearly went the other way.** The first
version of `chk_ac9` selected the lead with `"sc doctor" in l and "退出码" in l`, which matches
`CHANGELOG.md:26` as well and returned the wrong line — the baseline read FAIL and D-04/D-05/D-06
read "killed" for the wrong reason. The extractor now anchors on the unique
`` `sc doctor` 的三行结论 `` and asserts uniqueness. A QA check that fails for the wrong reason is
the same defect class this task sweeps.

### 7c — The inverted R-22 trap, made concrete (`scratchpad/trap_mutant2.py`)

Mutant T-2 is the delivered tree with the AAAA sentence's **advice inverted** — "regeneration
repairs it, so `sc reload` is all you need here" — which is **false** of `bin/sc` (the user's
document is merged last on every run, `:2107` then `:2117`). All three sites change together and
the placeholder set is preserved, exactly as the true correction did.

```
check                             DELIVERED / MUTANT T-2 (false advice)
folded-AST identical to HEAD      True / True        str-constant count            1896 / 1896
str constants differing from HEAD 3    / 3           comment tokens added vs HEAD  4    / 4
AC-7 placeholder sets EQUAL       True / True        B.4 subset assertion passes   True / True
parses (py_compile-equivalent)    True / True
identical signature on every mechanical check: True
```

**This is the report's central negative result.** No mechanical check in this project — B.4,
`py_compile`, the AST identity, the placeholder equality, `verify_all` in full — can tell the true
correction from a false one. Only a derivation from the code decides it, which is why §3, §4 and §5
exist and why AC-2's `py_compile` leg, AC-7's B.4 leg and AC-19 are reported NOT-DISCRIMINATING
for the criterion "the corrected sentence is true of the code it describes".

---

## 8 — AC-13 / AC-12 / AC-14 / AC-15 / AC-16 / AC-17 / AC-20 · the remaining enumerations

**AC-13** (`scratchpad/ac13_paths.py`):
```
Path-valued module constants: 9 — CFG_DIR :23 CFG_PATH :24 NODES_PATH :25 SETTINGS_PATH :26
  RULES_DIR :27 OVERRIDE_PATH :32 STATE_PATH :38 LIB_DIR :43 IF_INET6_PATH :64
EXCLUDED (container of Paths, not a Path constant): PERIODIC_DIRS :79
module-level (depth-0) loads: CFG_DIR 6 [24, 25, 26, 27, 32, 38] ; the other eight 0 each
function-body-only constants: 8 of 9
```
The row's further claim — "it is the set the loader recipe below repoints" — is true:
`docs/dev-map.md:215-217` names all nine.

**AC-12**, each token read at its site in `.harness/scripts/upgrade-project.sh`: `refresh_set`
`:186-194` + the loop `:195`; `known` `:140` with the hand-maintained invariant comment `:135-138` /
`:182-185`; `VERIFY-SPLICE` `:542` inside the awk splice `:536-541`; `VERIFY-HALT` `:549` in the
`old_b_customized … && FORCE == false` branch that leaves the file untouched and sets `exit_code=2`;
`"$proj_file.bak-$stamp"` `:571` with `cp "$proj_file" "$bak"` `:572` **before** the write at `:575`.
Counts `5 · 7 · 1 · 2 · 1`; zero ranges in the paragraph; no `.bak` write inside the refresh loop
(`bak=` appears only at `:351`, `:424`, `:571`).

**AC-14.** `check-sc-contracts.py --list` prints **19** names (it returns at `:903-905` before
`load()`, so no `bin/sc` is opened). `baseline.json:4` = `test_count: 19`. B.4 invokes the suite
with no NAME argument (`verify_all.sh:104`), so `selected = list(TESTS)` and `run == defined == 19`;
B.4 PASSed, which requires the summary regex to have matched and `passed ≥ 19`, and `passed ≤ run`,
so the captured line is `summary: 19 defined, 19 run, 19 passed`. Tree sweep for count claims:
`dev-map.md:87` and `50-singbox-cli.md:29-30` state none; `docs/tasks.md:230-231` states **19**;
`docs/tasks.md:277` is the stale present-tense quotation (Defect QA-2); every other hit is an
archived past-tense record.

**AC-15.** `50-singbox-cli.md:47` — "until B.3 is real (it is the run's one SKIP)"; the run's SKIP
set is exactly `{B.3}`.

**AC-16.** `git diff -U0 -- docs/dev-map.md` → hunks at **33, 42, 81, 87**, all single-line; the
recipe block `:204-242`, its four clauses `:234-240` and `:76`'s frozen `18 … T-30` are outside
every hunk. Discharging commit, re-taken with `git log -S` on each clause's own text: all three land
in `2ea5e16` (T-28). Each clause is true of the delivered `bin/sc`: the recipe's
`open("bin/sc", encoding="utf-8")` `dev-map.md:210`; the import-time
`os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])` `bin/sc:125-126`; the read-only
arm `if args.cmd in ("doctor", "config"):` `bin/sc:3843`.

**AC-17 / G-13.** All eleven ids resolve in `docs/tasks.md` (≥3 hits each: the T-32 row's
disposition list, a pointer line, the amended R-74 row's instance list); five pointer lines at
`:135, :187, :204, :227, :252`, each naming the rows moved, the destination and the disposition.
`scratchpad/rotation_verbatim.py`: of the 19 lines the rotation removed, 16 arrive verbatim in the
archive; the three that do not are a section heading replaced by its pointer line (re-created in the
archive with a disposition annotation), the R-74 row (amended in place, as FR-10 requires) and the
`test_count` **18** line (corrected to 19 in place under R-94(e)). No row was edited while moving.

**AC-20 / BC-4 / BC-5.** `grep -n -e 'does not carry this decision' -e 'does not carry that
decision' -e 'first dns.rules entry' -e 'dns.rules 第一条' README.md README.zh-CN.md` → **exit 1,
0 hits**. Widened to `AAAA` / `dns.rules`: only the `sc ipv6` usage block, the doctor row-4 cell
(`README.md:263`, which describes what the row *checks* — still true of the delivered head test —
and is not the PROBLEM sentence), the exit-code table and the override recipe. Neither README
carries the corrected sentence, so there is nothing to mirror. Across the whole diff, added-or-
removed lines carrying `失败：` or `failed: ` = **0**; `bin/sc` carries seven such lines
(`:148, :216, :268, :356, :2231, :3463, :3550`), none in this diff. **K-5 / K-6:** no corrected
sentence carries a line coordinate (`dev-map.md:33/42/81/87`, `CHANGELOG.md:29`,
`50-singbox-cli.md:29/47`), and the shipped AAAA sentence names no directive.

---

## 9 — RES-9 re-taken, and one dispatch figure corrected

```
$ sha256sum bin/sc → 0afdc3b69307defc5e49f81cb148c5124b8b469ebb6dc77fe4dc23bf2f11b669   ← matches
$ git diff --numstat
30 0 .harness/rejected-decisions.md   8 4 rules/80-delivery-policy.md   2 2 rules/50-singbox-cli.md
1  1 CHANGELOG.md   11 5 bin/sc   4 4 docs/dev-map.md   38 0 docs/tasks-archive.md
13 19 docs/tasks.md   10 0 batches/closeout/BATCH_LOG.md   4 4 batches/closeout/BATCH_PLAN.md
```

`docs/tasks-archive.md +38/−0` matches the dispatch. `docs/tasks.md` is **+13/−19**, not the
dispatch's "+32/−20": 32 is `--stat`'s combined change bar (13+19), not an insertion count. Not a
delivery defect — a mis-read of `--stat`, recorded because the dispatch invited it to be re-taken.
NFR-2 (`scratchpad/nfr2_lines.py`): **26** changed lines outside the process paths, ceiling 30 —
`bin/sc` 11, rule 80 8, dev-map 4, rule 50 2, CHANGELOG 1; matches the developer's table exactly.

---

## 10 — AC-21 / RES-8 · the host, re-taken from zero — and the anomaly explained

Witness before the stage's first command and after the last, `systemctl show` only
(`is-active` never invoked):

```
MainPID=1776263   Result=success   NRestarts=0   ActiveState=active
ActiveEnterTimestamp=Mon 2026-08-17 00:44:47 CST
$ diff host-before.txt host-after.txt → IDENTICAL
/etc/sing-box      2026-08-11 12:13:57   /var/lib/sing-box  2026-07-30 12:59:24   (both unmoved)
$ uptime -s → 2026-07-30 23:38:28        ps start → Mon Aug 17 00:44:46  (one second below — the predicted rounding artefact)
```

No figure was inherited. The measured `MainPID` is **1776263**, not the `2566751` every dispatch in
this programme carried — RES-8 confirmed independently.

**And the cause is now measured rather than left open.** `04` and `05` both recorded that the
instance was replaced by "something outside this pipeline" and that they had no explanation. Four
read-only observations identify it:

```
$ ls -la /etc/sing-box/rules/    → rules/ and all four .srs carry mtime  Aug 17 00:44
$ systemctl show -p LastTriggerUSec sing-box-rules-update.timer
LastTriggerUSec=Mon 2026-08-17 00:44:43 CST   NextElapseUSecRealtime=Mon 2026-08-24 00:49:59 CST
$ systemctl show -p ExecStart -p ExecMainExitTimestamp sing-box-rules-update.service
argv[]=/usr/local/bin/sc update-rules ; start_time=[00:44:43] ; ExecMainExitTimestamp=…00:44:47 CST
```

The project's own **weekly rule-set timer** ran `/usr/local/bin/sc update-rules` at 00:44:43; the
four rule-sets' bytes changed, so `cmd_update_rules` restarted the service, and the unit's
`ActiveEnterTimestamp` / `ExecMainStartTimestamp` is the second that run exited, 00:44:47.
Corroborating negatives: `/usr/local/bin/sing-box` mtime 2026-07-30 12:47 (binary not replaced),
`sing-box.service` mtime 2026-08-11 12:13:49 (unit not edited), `/usr/local/bin/sc` mtime
2026-08-11 12:13:49 (no reinstall), `/etc/sing-box` directory mtime unmoved and `config.json` mtime
2026-08-11 12:13 (no regeneration — `cmd_update_rules` regenerates only when a rule-set is *gained*
and restarts when bytes merely *changed*), `NRestarts=0` (deliberate restart, not an automatic one).

**AC-21's claim is untouched** — this task disturbed nothing, and every run's before/after pair is
identical. What is void is the programme-level assumption that one instance spans every dispatch:
on this host it cannot, because the project restarts its own service every Monday at ~00:45.

---

## 11 — Worth harvesting as insight

1. **A record's host witness must name what makes it stable, or it decays on a schedule.** `MainPID`
   was carried as a programme-wide invariant across 20 dispatches on a host whose own weekly
   `sing-box-rules-update.timer` restarts the service — the invariant was guaranteed to break, at a
   cadence the project ships. The stable witness is the *(before, after)* pair taken in one run,
   never an absolute PID; and an unexplained host change is worth ten minutes of `ls -la` +
   `systemctl show -p LastTriggerUSec` before it is written down as unexplained. *Evidence:*
   `LastTriggerUSec=Mon 2026-08-17 00:44:43`, the four `.srs` mtimes, `ExecMainExitTimestamp=00:44:47`.
2. **When the artifact *is* the deliverable, every mechanical check goes blind at once.** A mutant
   inverting the corrected sentence's advice yields a byte-identical verdict from B.4, `py_compile`,
   the folded-AST identity, the placeholder equality and a full `verify_all`. The only discriminator
   is a derivation from the code — so a task of this shape should say, in its own criteria, which
   are regression controls and which decide truth. *Evidence:* §7c.
3. **A committed subset assertion reads as an equality assertion to everyone who quotes it.**
   `zh_placeholders_are_a_subset_of_their_key` (`check-sc-contracts.py:455-475`) passes a `zh` entry
   that *drops* a placeholder; three documents in this chain needed gate ruling G-9 to be told so.
   Its **name** is doing its job; the missing piece is the sibling for the other direction.
   *Evidence:* M-14 — killed by the equality read, passed by B.4.
4. **A "price of this design" clause should be tested for reachability before it is written.** Both
   sites the `backslashreplace` cost clause names were unreachable on **every** build that shipped
   without it (21 commits checked), because an `sc`-authored `↓` or em dash always reached the
   stream first. *Evidence:* §3.
