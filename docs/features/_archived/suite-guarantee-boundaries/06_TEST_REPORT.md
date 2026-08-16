# 06 — Test Report · T-31 `suite-guarantee-boundaries`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

## Test plan

Every reproducer below is **mine**, written from the acceptance criterion, not from
`04_DEVELOPMENT.md`'s code, and re-taken on the delivered tree rather than inherited.
`R` = `/home/alan/Programs/singbox-cli`,
`S` = `/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/r2`.
Subjects are scratch files only; targets are `/usr/bin/touch <marker under S>` (BC-7).
Destructive cases ran in `S/cloneA` (delivered change committed, `HEAD` floor 19) and
`S/cloneB` (pre-commit shape, `HEAD` 18 / tree 19).

| acceptance criterion | test case(s) | file |
|---|---|---|
| AC-1 escape measurement reported before FR-2's disposition — **PASS** | 10-variant escape sweep re-run on the delivered tree, plus three of the same probes against the task-start suite (`git show HEAD:`) | `S/escape_sweep.txt`, `S/ac1_wrongbuild.py` |
| AC-2 escaping subject refused, or named open in both texts — **PASS** | 7 documented `subprocess` entry points × `_USE_POSIX_SPAWN` True/False; `posix`, `ctypes`, `_posixsubprocess.fork_exec`, `os.path.os.system`, `subprocess.os.system` measured open and named in both texts | `S/entrypoints.txt`, `S/escape_sweep.txt` |
| AC-3 no claim-surface sentence asserts coverage the artifact lacks — **PASS** (was FAIL) | `dir(os)` re-enumerated two ways (ast scan of `os.py`, doc scan of every unmatched C callable); the shim's denied set read **directly** off `load()`; all three of family (ii)'s measured claims re-driven | `S/enum_os.py`, `S/enum_os2.py`, `S/half_a_direct.py`, `S/priv_r2.py` |
| AC-4 lowering the floor FAILs, naming both numbers — **PASS** | `cloneA` at floors 17 and `018` against `HEAD` 19; the FAIL detail pinned verbatim | `S/b6_cases.sh`, `S/b6_detail.sh` |
| AC-5 raising the floor leaves PASS, at the discriminating instant — **PASS** | real repository pre-commit (19 vs 18); `cloneA` equal (19 vs 19) and higher (20 vs 19); equality and flipped control mutants at both instants | `S/mutants_va.sh`, `S/b6_cases.sh` |
| AC-6 unreadable history: no FAIL, one printed line — **PASS** | four BC-2 shapes plus five unusable-value shapes (duplicate in tree, duplicate at `HEAD`, non-numeric, negative, string-valued) | `S/b6_cases.sh` |
| AC-7 a translated wording survives every re-run in any language — **PASS** | zh value of `"the top level must be a JSON object"` destroyed in a scratch `bin/sc`; delivered suite, a `LANG="zh"` fixture suite, and that suite against the unmutated source | `S/ac7_zh.py` |
| AC-8 no committed runner / no spawn, under C-6's scoping — **PASS** | `strace -f -e trace=execve,clone,clone3,fork,vfork` over a B.4 run; `strace` over B.5; repo-wide `git grep` of every committed reference to `bin/sc` and `/usr/local/bin/sc` | `S/nfr1.strace`, `S/b5.strace` |
| AC-9 clause red on `os.replace`, green on the task-start `bin/sc` — **PASS** | 8 subjects: control, `os.replace`, keyword, alias, helper, second-installer, invariant-preserving reshape, wrong destination | `S/m4_one_writer.txt` |
| AC-10 `bin/sc` byte-identical — **PASS** | `sha256sum bin/sc` at the start, middle and end of this round | this document |
| AC-11 `verify_all` PASS / FAIL 0 / WARN 0 / B.3 the only SKIP — **PASS** | my own run, three times | `S/va-1.out` … `S/va-3.out` |
| AC-12 every non-discriminating criterion reported as such — **PASS** | BC-4 (floor 5 committed with 19 assertions), RES-3, RES-4, RES-12, RES-13 each re-measured, not copied | `S/bc4.sh`, `S/drive_mutants.py`, `S/mutants_va.sh` |
| AC-13 no new file/dir/dependency; net executable within NFR-2 — **PASS** | `git diff --numstat` and `--name-status`; `-U0` diff of both scripts re-counted line by line | `S/ac13.txt`, `## verify_all result` |
| AC-14 a root-needing criterion reported BLOCKED, never substituted — **PASS (vacuous)** | none arose: every criterion including NFR-1's `strace` ran unprivileged | this document |

## Adversarial tests

One row per acceptance criterion, each with the failure I predicted before running and — for
the discriminating ones — the wrong build the criterion was shown to fail on. Cited output is
≤5 lines per row and was observed; the full runs are in `06_RATIONALE.md`.

| AC | hypothesis ("I expect failure when…") | reproducer | outcome (with tool output) |
|---|---|---|---|
| AC-1 | round 4 moved 175 lines of this file, so some inherited reading no longer reproduces | `python3 S/../escape_sweep.py` (mine, 10 variants) + `python3 S/ac1_wrongbuild.py` (NEW) | **Survived.** All ten reproduce unchanged. Wrong build: task-start suite — `subprocess-call task-start HEAD exit 1 marker PRESENT summary: 18 defined, 18 run, 0 passed` vs delivered `subprocess-call delivered exit 2 marker ABSENT summary: 19 defined, 0 run, 0 passed` |
| AC-2 | half (b) covers `Popen` but not the wrappers, or fails when CPython dispatches through `fork_exec` instead of `posix_spawn` | `python3 S/../entrypoints.py` (mine; 7 entry points × both dispatch settings) | **Survived**, 14/14 refused: `run exit 2 marker ABSENT LoadRefused True` … `getstatusoutput exit 2 marker ABSENT LoadRefused True` on both settings. Every route the texts call open is open: `posix-system marker PRESENT`, `ctypes-CDLL-system marker PRESENT`, `realos-os-path-os-system marker PRESENT` |
| AC-3 | round 4 closed DEF-1 with prose only, so the **new** sentence is now either too narrow (false modesty) or still too wide — a public `os` name outside the tuple, or a private one the enumeration missed | `python3 S/enum_os2.py` + `python3 S/half_a_direct.py` + `python3 S/priv_r2.py` (all NEW) | **Survived — the sentence is exactly true.** Denied set read off the shim: `names bound to _no_new_process : 22` / `names the tuple matches in dir(os) : 22` / `set equality : True`. Of the 380 unmatched, the ast scan of `os.py` yields exactly `['_execvpe', '_spawnvef']`; the C-level doc scan yields only `wait/wait3/wait4/waitpid/register_at_fork/unshare`, none of which start a process |
| AC-4 | the FAIL detail lost a number in the reflow, or the `10#` pin broke the plain lowering | `bash S/b6_detail.sh` in `cloneA` (19 committed) | **Survived.** `test_count is 17 in .harness/scripts/baseline.json and 19 at HEAD — the floor only goes up`, and at the leading-zero shape `test_count is 018 in .harness/scripts/baseline.json and 19 at HEAD — the floor only goes up`. Wrong build: task-start `verify_all`, which has no B.6 at all |
| AC-5 | the control is written as equality, so the delivery's own 18→19 raise FAILs it | `bash S/mutants_va.sh` — equality and `>` mutants at both instants | **Survived, and the instant is what discriminates.** Delivered, pre-commit: `[B.6] … PASS`. Equality mutant, same instant: `[B.6] … FAIL` / `test_count is 19 … and 18 at HEAD`. Post-commit (19 vs 19) **both** PASS — G-9 measured, not assumed |
| AC-6 | one of the nine unreadable shapes takes a different branch, or the SKIP line prints twice | `bash S/b6_cases.sh` cases 4–7, 9, 10, 13 | **Survived.** All nine: `[B.6] … SKIP` with `NOT-performed lines: 1`, `comparison NOT performed: no single readable test_count in the working tree or at HEAD`, and **no** B.6 FAIL in any of them. Wrong build: M23 (shape test removed) → `[B.6] … PASS` on the same duplicated floor |
| AC-7 | the zh mutant dies — expectation and observation do **not** share the `t()` lookup, and FR-5's sentence is false | `python3 S/ac7_zh.py` (NEW; suite-zh rebuilt from the **delivered** file, round 1's copy was stale) | **Survived — the boundary sentence is true.** `delivered suite x zh-DESTROYED bin/sc exit 0 | summary: 19 defined, 19 run, 19 passed | FAILs 0`; `zh-fixture suite x zh-DESTROYED bin/sc` identical; `zh-fixture suite x unmutated bin/sc` identical. No re-run discriminates it |
| AC-8 | a committed step runs `bin/sc`, or B.4 forks something now that `_spawnvef` is known to reach the real `fork` | `strace -f -e trace=execve,clone,clone3,fork,vfork python3 .harness/scripts/check-sc-contracts.py` | **Survived.** Two-line trace: `execve("/usr/bin/python3", ["python3", ".harness/scripts/check-sc-contra"...]) = 0` then `+++ exited with 0 +++`; `execve 1, clone 0, clone3 0, fork 0, vfork 0`; `summary: 19 defined, 19 run, 19 passed`. B.5 execs `bash sed grep sort wc dirname` only |
| AC-9 | the clause is vacuous — it would pass the `os.replace` mutant too | `python3 S/../m4_one_writer.py` (mine, 8 subjects) | **Survived.** Control `PASS … at line(s) 2202`; wrong build `mut-os-replace` → `FAIL … no _write_private(CFG_PATH, ...) call inside generate_config()`. Known reds reproduce (keyword, alias, helper); the invariant-preserving reshape stays green (`at line(s) 2204`); the second-installer blind spot is real (`PASS`) |
| AC-10 | some probe wrote to `bin/sc` | `sha256sum bin/sc` ×3 | **Survived.** `81d65da83ba23808c1f09ce81c94e067449eac698db7c625d67b775dbd31b312` at start, middle and end |
| AC-11 | a second SKIP or a stderr leak appeared with B.6's twenty new lines | `bash .harness/scripts/verify_all.sh` ×3 | **Survived.** `PASS: 20  WARN: 0  FAIL: 0  SKIP: 1`, exit 0, `stderr 0 lines`, **one** distinct stdout digest across three runs; the one SKIP is `[B.3] Lint ... SKIP` |
| AC-12 | one of the declared non-discriminating items is actually discriminating (or vice versa) | `bash S/bc4.sh`, `python3 S/drive_mutants.py`, `bash S/mutants_va.sh`, `bash S/m15.sh` | **All five re-measured, none rounded up.** BC-4 blind: floor **5** committed with 19 assertions → `[B.4] … PASS` `[B.6] … PASS` `FAIL: 0`. RES-3 kills a deleted restore (`M2 D1 exit 2 | 19 defined, 0 run, 0 passed`) but not a moved one (`M3 exit 0 | 19/19/19`). RES-4, RES-12, RES-13 confirmed exactly as the reviewer states them |
| AC-13 | the executable count crossed 40 once round 4's `floor_of` shape test and the two `10#` pins are classified | `-U0` diff of both scripts, re-counted by hand; `git diff --name-status` | **Survived.** **31** net executable (E-1 3, E-2 14, E-4 14) against a cap of 40; `git diff --name-status` is 8 `M` lines and no `A`/`D`; no import line added or removed; `py_compile OK`, `bash -n OK`, mode `755`, `len(TESTS) = 19` |
| AC-14 | a criterion silently needed root and got a weaker substitute | review of every run in this round | **Survived.** None needed root; `strace` ran unprivileged; no operator obligation was created and none is owed |

**Mutation sweep of my own design, round 2** — rebuilt from the **delivered** files, because
round 4 moved 175 lines and a round-1 mutant file no longer applies. 23 items: **18 mutate a
delivered artifact** (6 killed, **12 surviving**); 5 are states or subjects reported separately
below. A mutant killed only by a probe I wrote is reported as **surviving the committed
controls**, which is this project's standard (T-28, T-30).

| AC | mutant | reproducer | outcome |
|---|---|---|---|
| AC-2 | M1 drop half (b) entirely | `S/mutants/M1.py` | **SURVIVES** — `D1 exit 0 | 19 defined, 19 run, 19 passed`, escape `marker PRESENT (exit 1)`. Nothing in `verify_all` sees the denial go |
| AC-2 | M2 delete the `Popen` restore from the `finally` | `S/mutants/M2.py` | **KILLED** — `D1 exit 2 | 19 defined, 0 run, 0 passed`, `LoadRefused: a displacement made by the load did not survive its finally` |
| AC-2 | M3 move the restore out of the `finally` | `S/mutants/M3.py` | **SURVIVES** — `D1 exit 0 | 19/19/19`. RES-3's exact shape |
| AC-2 | M4b re-introduce a LOCAL capture below the displacement (round 1's DEF-2) | `S/mutants/M4b.py` | **KILLED by round 4** — `D1 exit 2 | 19 defined, 0 run, 0 passed`, `LoadRefused: a displacement made by the load did not survive its finally`; delivered control `subprocess.Popen after load() -> <class 'subprocess.Popen'>`. `REAL_POPEN` at `:161` makes the reorder unreachable |
| AC-2 | M21 **NEW** — rebind `REAL_POPEN` inside `load()` | `S/mutants/M21.py` | **SURVIVES**, and is the worst of the twelve: `D1 exit 0 | 19/19/19`, escape refused, yet `subprocess.Popen after load() -> <function _no_new_process at 0x…>`. This is RES-11 exactly: a deliberate rebinding, not a reorder; named in the code at `:159-160`, asserted by nothing |
| AC-2 | M5 drop `"system"` from the prefix tuple | `S/mutants/M5.py` | **SURVIVES** — `D1 exit 0 | 19/19/19`; only my `os.system` probe kills it (`marker PRESENT` vs delivered `ABSENT`) |
| AC-2 | M6 drop `mod.os is not shim` from the leak check | `S/mutants/M6.py` | **SURVIVES** — `D1 exit 0 | 19/19/19` |
| AC-9 | M7 drop the `CFG_PATH` argument test | `S/mutants/M7.py` | **SURVIVES `verify_all`.** Killed only by a QA subject: against `mut-os-replace` delivered is `exit 1 | 1 run, 0 passed`, M7 is `exit 0 | 1 run, 1 passed` |
| AC-9 | M8 delete `encoding="utf-8"` from the clause's `open()` | `S/mutants/M8.py` | **SURVIVES** — `D1 exit 0 | 19/19/19`. T-28's false-kill trap reproduced: this host's locale codec is UTF-8 |
| AC-9 | M9 substitute the codec (`ascii`) in the clause's `open()` | `S/mutants/M9.py` | **KILLED** — `D1 exit 1 | 19 defined, 19 run, 18 passed`, so B.4 FAILs on both counts. Anchored one-point this round (the same two lines occur at `:545`; round 1's M9 was two-point) |
| AC-9 | M10 drop `_eq(len(defs), 1, …)` | `S/mutants/M10.py` | **SURVIVES `verify_all`.** Killed only by a two-`generate_config` subject (delivered `exit 1 | 1 run, 0 passed`, M10 `exit 0 | 1 run, 1 passed`) |
| AC-13 | M11 remove the new name from `TESTS` | `S/mutants/M11.py` in `cloneA` | **KILLED by B.4** — `[B.4] … FAIL` / `18 assertion(s) passed, floor is 19` / `FAIL: 1` |
| AC-4 | M12 B.6 written as equality (`!=`) | `S/mutants_va.sh` | **KILLED at the pre-commit instant** (`FAIL … 19 … and 18 at HEAD`), survives post-commit |
| AC-4 | M13 B.6 comparison flipped (`>`) | same | **KILLED at the pre-commit instant**, survives post-commit — same shape as M12 |
| AC-4 | M14 swap `2>/dev/null` and `<` at both `floor_of` call sites | same, with `baseline.json` absent | **SURVIVES** every automated step; killed only by hand — mutant `stderr 2 line(s)`: `verify_all.sh: line 99: … No such file or directory` and `line 125: …`; delivered `stderr 0 line(s)` |
| AC-4 | M15 drop the FAIL detail string | `bash S/m15.sh`, at the state that makes B.6 FAIL | **SURVIVES** (run this round, not inferred): both delivered and mutant print `[B.6] … FAIL`; only the mutant prints no numbers. Nothing automated asserts the detail — AC-4's own reproducer is the whole control |
| AC-4 | M22 **NEW** — drop the `10#` pin from B.6's comparison | `S/mutants_va.sh`, tree floor `018` vs `HEAD` 19 | **SURVIVES the committed controls** — `M22 (unpinned): [B.6] … PASS` where delivered gives `[B.6] … FAIL / test_count is 018 …`. No committed step creates a leading-zero floor, so only a hand-built state discriminates it |
| AC-6 | M23 **NEW** — drop `floor_of()`'s shape test (`if [[ $v =~ ^[0-9]+$ ]]`) | `S/mutants_va.sh`, duplicated `test_count` | **SURVIVES the committed controls** — `M23 (no shape test): [B.4] … PASS  [B.6] … PASS` where delivered gives `[B.4] … FAIL` + `[B.6] … SKIP`. Round 1's DEF-3 restored in one edit, with nothing to catch it |

**The five items that are not artifact mutants**, reported rather than folded into the ratio:
M16 (a JSON-**escaped** second `"test_count"` literal in `notes`) is a **false mutant** — `[B.6] …
PASS` is correct behaviour, the sed never matches; M17 (an **unescaped** duplicate) was round 1's
DEF-3 and is now a handled state, not a survival — `[B.4] … FAIL` + `[B.6] … SKIP`; M18
(non-numeric, negative, string-valued floors) is the same handled state; M19 (`os.path.os.system`)
and M20 (`os._execvpe`) **survive by design and are named open in both claim-surface texts** —
M20 was DEF-1 and is now present-tense in family (ii).

**Delta against round 1's nine survivors:** M4b is now killed (DEF-2 closed) and M17's fail-open
is closed (DEF-3); the other seven — M1, M3, M5, M6, M14, M19, M20 — still survive, and three new
survivors were found this round (M21, M22, M23).

## Boundary tests added

- Floor comparison at every relation and every spelling: lower (17 vs 19 → FAIL), lower with a
  leading zero (018 vs 19 → FAIL, the `10#` pin), equal (19 vs 19 → PASS), equal with a leading
  zero (019 vs 19 → PASS), higher (20 vs 19 → B.6 PASS with B.4 FAILing for the unmet floor).
- Null-shaped input to the floor reader, nine shapes, each yielding an empty `floor_of` answer:
  `test_count` absent from the tree, absent at `HEAD`, non-numeric, negative, string-valued,
  duplicated in the tree, duplicated at `HEAD`, and the two no-history shapes. B.4 FAILs on the
  tree-side ones, B.6 SKIPs on all nine, with exactly one printed line and never a FAIL.
- Empty history: no `.git`; `.git` present as a **file** (Q-F's worktree shape); `baseline.json`
  absent at `HEAD`; `baseline.json` absent in the working tree.
- BC-4's blind spot exercised, not assumed: floor **5** committed with 19 assertions present →
  `[B.4] … PASS`, `[B.6] … PASS`, `FAIL: 0`.
- Unicode / codec boundary: a destroyed **zh** rendering of an asserted sentence (non-ASCII,
  multi-byte) survives the suite in both languages; an ASCII codec substitution in the clause's
  `open()` kills it, and the same substitution *deleted* rather than substituted does not.
- Process-route boundary by capability rather than by name: seven `subprocess` entry points × two
  dispatch choices; the shim; the real `os` one attribute hop away; `posix`; `ctypes`;
  `_posixsubprocess.fork_exec`; the private helpers `os._execvpe` / `os._spawnvef`; and
  `os.path.os._execvpe`, family (ii) reached through family (iv).
- Half (a) checked as a **set**, not case by case: the names bound to `_no_new_process` on the
  shim the delivered `load()` builds are exactly the 22 the tuple matches, and `shim._execvpe` /
  `shim._spawnvef` are still the real functions.
- Subject-shape boundary for the one-writer clause: zero, one and two `generate_config`
  definitions; keyword, aliased, helper-moved, second-installer and wrong-destination installs;
  one invariant-preserving reshape that must stay green.
- RES-1 (routes still open) re-measured on the delivered tree: `posix.system`,
  `ctypes.CDLL(None).system`, `_posixsubprocess.fork_exec`, `os.path.os.system`,
  `subprocess.os.system` each leave their marker, and each is named open in **both** texts.
- RES-2 is closed as re-measurement: the four families were re-driven here, including the two
  private helpers round 4 added to family (ii).
- RES-3: the post-`finally` clause is NOT-DISCRIMINATING only for a `finally` that restores
  unconditionally (M3). It **does** kill an outright deletion of the restore (M2), and after
  round 4 it also kills a capture-order error (M4b). Report it as that, never as a passed check.
- RES-4: the redirection order (`verify_all.sh:99`, `:125`) has **no automated control by
  construction** — no committed step creates an absent `baseline.json`. Measured by hand only.
- RES-12: the denial has **zero** committed controls. M1, M5 and M6 are one class — each leaves
  `verify_all` fully green. Closing any of them needs a committed escaping subject driven through
  `--source`, i.e. a new file, which AC-13 / NFR-3 forbid in this task.
- RES-13: with an unusable floor B.6 SKIPs, so the ratchet goes **silent** rather than being
  violated, while B.4 FAILs the same run when the unusable value is the tree's (measured: tree-side
  → `FAIL: 1`; `HEAD`-side → `FAIL: 0`). No committed step produces either state.
- RES-14 re-taken mechanically and **exact**: `3.12.3 402 22`, and the 380 unmatched contain
  exactly two process starters.
- **New, mine:** round 4's hardening has no control of its own. M22 and M23 restore round 1's two
  fail-opens in one edit each and leave `verify_all` green, because the only states that
  discriminate them are hand-built. Same class as RES-4, and it now covers the lines that closed
  DEF-3.
- Family (iii)'s closing sentence checked rather than accepted: of the twelve modules on the
  pre-import line, only `subprocess` contains a process-start primitive (`Popen(`,
  `from _posixsubprocess import fork_exec`); the other eleven show zero hits (`time` is a C module
  with no readable source and no process API in `dir(time)`).
- C-5 re-verified independently: `git grep passing_count|warnings_baseline` returns
  `baseline.json` itself and archived stage documents only — no script, no step, nothing executable.
- C-11 re-taken by set difference at the delivered line numbers: of `HEAD`'s 190 `docs/dev-map.md`
  lines exactly **4** are absent from the worktree's 277, all four inside the two falsified
  sentences (`HEAD:137-140`); the fenced recipe block (`:204-214`), the "nine path constants"
  clause (`:216`), R-77 (`:236`), R-78 (`:239`) and R-84 (`:240`) are byte-identical.

## verify_all result

```
my own run (real repository, delivered tree) : PASS 20 / WARN 0 / FAIL 0 / SKIP 1, exit 0
task-start baseline (PM, HEAD 2a6b6e8)       : PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0
delta                                        : +1 PASS (B.6); 0 new FAIL, 0 new WARN, SKIP unchanged
the one SKIP                                 : B.3 Lint (verify_all.sh:77), the standing SKIP
B.4                                          : PASS — summary: 19 defined, 19 run, 19 passed
B.6                                          : PASS — tree test_count 19 vs HEAD 18
verify_all stderr                            : 0 lines, on each of three runs
total tests (assertions)                     : 18 -> 19 (len(TESTS) = 19, --list = 19 names)
pass                                         : 19
fail                                         : 0
warn                                         : 0
new committed assertions added by QA         : 0 — the delivered count is bound to baseline.json's
                                               floor in the same commit (BC-10 / K-5); adding one at
                                               stage 6 would break that binding. My reproducers are
                                               scratch files, named per row above.
baseline updated by QA                       : no — test_count/passing_count are already 19, raised
                                               by the delivered change; the floor is never lowered.
C-9 pre-commit reading (real repository)     : tree 19 vs HEAD 18 (HEAD = 2a6b6e8) -> B.6 PASS
C-9 post-commit reading (19 vs 19)           : OWED — the PM's at delivery. Pre-exercised in cloneA
                                               (PASS 20 / FAIL 0) but NOT claimed for the real
                                               repository here.
C-2 real-os attribute chain, delivered tree  : os.path.os.system marker PRESENT, exit 1,
                                               19 defined, 19 run, 0 passed; subprocess.os.system
                                               identical. Named open (iv) in both texts.
C-6 AC-8 scope                               : no committed artifact runs THIS repository's bin/sc as
                                               a program (git grep: every hit is prose, install.sh:487
                                               INSTALLS it, restricted-network-regression.sh:285 runs
                                               the INSTALLED build); B.5 execs bash/sed/grep/sort/wc/
                                               dirname only.
NFR-1 (V-11)                                 : strace -f -e trace=execve,clone,clone3,fork,vfork over
                                               a B.4 run — execve 1, clone 0, clone3 0, fork 0,
                                               vfork 0. Not BLOCKED: strace ran unprivileged.
RES-14 denominator                           : 3.12.3 402 22 — exact, re-taken; the 380 unmatched
                                               contain exactly two process starters (os.py:593
                                               _execvpe, os.py:853 _spawnvef).
C-10 raw diff (git diff --numstat), change   : 67/5 rejected-decisions.md · 3/3 baseline.json ·
                                               175/19 check-sc-contracts.py · 38/2 verify_all.sh ·
                                               91/4 dev-map.md
C-10 raw diff, PM ledger (not the change)    : 8/0 CONTEXT.md · 7/0 BATCH_LOG.md · 3/3 BATCH_PLAN.md
C-10 files added / removed                   : 0 / 0 — git diff --name-status is 8 M lines, no A, no D
C-10 net executable · E-1 denial              : 3 (REAL_POPEN :161; subprocess.Popen = _no_new_process
                                               :222; the restore :233. The leak-check condition :234,
                                               the os-restore comment :232 and _no_new_process's
                                               message :182-184 are rewrites at 0 net)
C-10 net executable · E-2 clause + registry   : 14 (def :587 + 13 body lines :615-627; the TESTS row
                                               is a -2/+2 re-wrap, 0 net)
C-10 net executable · E-4 floor_of + B.6      : 14 (floor_of :90-93 = 4, incl. round 4's shape test;
                                               B.6 :125-134 = 10; B.4's read :99 and its 10# pin :106
                                               are rewrites; the 21 comment lines are not executable)
C-10 net executable · E-3/E-5/E-6/E-7         : 0 (prose; baseline.json's two numbers are rewrites)
C-10 net executable · TOTAL                   : 31 against NFR-2's cap of 40 — the +1 over round 1's
                                               reading is floor_of()'s shape test, the line that turns
                                               two fail-open comparisons into fail-closed ones.
                                               Nothing blocks on size.
AC-13 stack                                   : no new file, directory, dependency or framework; no
                                               import line added or removed; suite mode 0755;
                                               py_compile OK; bash -n OK; no f-string and no walrus in
                                               any added line (3.6 floor intact)
```

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| DEF-1 | **CLOSED** (was CRITICAL) | `python3 S/enum_os2.py` → unmatched process starters are exactly `['_execvpe', '_spawnvef']`; `python3 S/half_a_direct.py` → `names bound to _no_new_process : 22`, `set equality : True`; `python3 S/priv_r2.py` → `os-_execvpe delivered suite exit 0 marker PRESENT summary lines : NONE`, `os-_spawnvef … exit 1 marker ABSENT … strace execve 1 / clone 1`, `realos-path-os-_execvpe … exit 0 marker PRESENT`. Every factual claim family (ii) now makes is reproduced, and half (a)'s scoped sentence is true of exactly the set the artifact denies — no more, no less. Family (ii) is present-tense in both texts and in `rejected-decisions.md:761-773`. | `.harness/scripts/check-sc-contracts.py:19-28`, `:51-65`; `docs/dev-map.md:137-145`, `:166-179` |
| DEF-2 | **CLOSED** (was MINOR) | `python3 S/drive_mutants.py`, mutant M4b (a local capture re-introduced below the displacement): `D1 real bin/sc : exit 2 | summary: 19 defined, 0 run, 0 passed`, `D3 in-process state : m.LoadRefused: a displacement made by the load did not survive its finally`. The clause now compares against a binding made at import, so no statement order inside `load()` can make the restoration assert itself. What remains is a deliberate rebinding (M21), which is RES-11, not this defect. | `.harness/scripts/check-sc-contracts.py:155-161`, `:233-235` |
| DEF-3 | **CLOSED** (was MINOR) | `bash S/b6_cases.sh` cases 9–13: a duplicated `test_count` now gives `[B.4] … FAIL` + `[B.6] … SKIP` with one printed line (was a silent `PASS`), and `018` vs `19` now gives `[B.6] … FAIL / test_count is 018 … and 19 at HEAD` (was fail-open). All four BC-2 shapes still SKIP with exactly one line and no FAIL. `floor_of()` decides the shape once for both callers and both comparisons are `10#`-pinned. | `.harness/scripts/verify_all.sh:90-93`, `:106`, `:130` |
| DEF-4 | **CLOSED** (was NIT) | `sed -n '2599p;2614p' bin/sc` → `def _doctor_run(cmd):` and `r = subprocess.run(cmd, …)`. Both texts now read "`def` at `bin/sc:2599`, its one `subprocess.run` at `:2614`". Every other citation in that paragraph re-verified exact: `:2175 :2504 :2634 :2727 :2731 :2816 :2827 :2831 :2853 :3406 :3607 :3609`, plus `verify_all.ps1:90-93` and `restricted-network-regression.sh:142-148 / :285`. | `.harness/scripts/check-sc-contracts.py:83`; `docs/dev-map.md:191` |
| DEF-5 | **schema-gap row** (not a defect of the change) | This report's declared schema has no shape for the gate-condition ledger (C-1 … C-11) or the stage-7 carry list (RES-1 … RES-14). Resolved as `.harness/rules/70-doc-size.md`'s `## Stage-doc boundary rule` prescribes — *"recorded as a schema-gap row, naming the unit and the destination it was given instead. Never invent a section"*. Destinations given: the C-* readings are `key: value` lines under `## verify_all result`; the RES-* answers are statements under `## Boundary tests added`; the stage-7 carry list is in the round message to the PM. No section was invented and no third document opened. | `docs/features/suite-guarantee-boundaries/06_TEST_REPORT.md` |

**Open findings against the delivered tree: none.** Judged and **not** fixed by me:

- **CR-13 (NIT, stage 5) — I agree with the reviewer and add a measurement.** "Adding the two
  names would deny those two spellings and buy nothing" is loose about spelling and exact about
  capability, and it does not mislead: the same clause names the effect it denies, the ground it
  gives is the binding rather than the name, and `os.path.os._execvpe` is measured handing the
  capability straight back (`exit 0 marker PRESENT`). My addition: `os.execvp` and `os.execvpe` —
  the only public routes that reach `_execvpe` — are both refused on the shim (`exit 2 marker
  ABSENT` each), so the private spelling is unreachable except by naming it deliberately, which is
  outside the stated threat model ("an ACCIDENTAL process start"). The exact form remains the
  reviewer's: *denies two spellings, closes no capability*.
- **RES-10 stands.** `01_REQUIREMENT_ANALYSIS.md`'s FR-6 / AC-8 / BC-11 wording ("no committed
  artifact starts a child process") is still false of the tree; AC-8 is reportable only under
  C-6's scoping, which is what I reported it against.
- **R-93's wording is now stale in the other direction.** It says the hole re-opens on "a name a
  future CPython adds"; a **present** name has been measured. A row correction is owed at stage 7.

## Stability

- `verify_all` ran three times on the delivered tree: `PASS: 20  WARN: 0  FAIL: 0  SKIP: 1`,
  exit 0 each time, **one** distinct stdout digest across the three, 0 stderr lines each. No flakes.
- The contract suite ran ten times: exit 0 ×10, `summary: 19 defined, 19 run, 19 passed` ×10, one
  distinct stdout digest over the ten, **zero** `WITNESS` lines, `--list` = 19 names.
- The suite writes **11 stderr lines** per direct run — `bin/sc`'s own translated warnings from the
  four `generate_config` arms, not a fault. They are stable: one distinct digest over ten runs once
  the `mkdtemp` root is normalised, and B.4 captures them with `2>&1`, which is why `verify_all`'s
  own stderr stays at 0 lines. No child process is behind the `Exec format error` line — the
  `_CheckerStub` at `:798-799` replaces `sc.subprocess`, and the `strace` shows `clone 0`.
- Host witness, `systemctl show sing-box -p MainPID -p NRestarts -p ActiveEnterTimestamp`, never
  `is-active`: **start**, **middle** and **end** all
  `MainPID=2566751 NRestarts=0 ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`.
  `/etc/sing-box` entries unchanged (`config.json`, `config.json.bak-2026-08-01-1001`,
  `.config.sha256`, `nodes.json`, `rules`, `settings.json`); `/var/lib/sing-box` unchanged
  (`cache.db`); nothing written under either; no `sudo`; the installed `/usr/local/bin/sc` was
  never named as a subject.
- Destructive cases ran in two fresh scratch clones (`S/cloneA` with the change committed,
  `S/cloneB` in the pre-commit shape). The real repository's floor was never lowered and no file in
  it was modified: `git diff --numstat` is identical at both ends of this round,
  `git status --short` shows the same 8 modified entries plus the untracked
  `docs/features/suite-guarantee-boundaries/` and **no added file**, and `sha256sum bin/sc` is
  `81d65da83ba23808c1f09ce81c94e067449eac698db7c625d67b775dbd31b312`, unchanged.
- Every escape probe was built so that an escape runs nothing but `/usr/bin/touch` on a marker
  under this round's scratch directory; every marker was read and then removed, and the marker
  directory is empty at the end of the round.

## Verdict

APPROVED FOR DELIVERY
