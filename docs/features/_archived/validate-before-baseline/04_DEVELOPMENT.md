# 04 — Development · T-30 `validate-before-baseline`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

## Summary

1. `generate_config()`'s tail is re-ordered into **candidate → verdict → install → record**
   per I-1…I-11 (`bin/sc:2163-2222`, under its comment header `:2150-2162`), and **every
   fallible statement of it is inside one guarded region**: `name = None` (`:2163`) sits
   above the `try:` with nothing between them, `tempfile.mkstemp` is the `try`'s first
   statement (`:2165-2166`), and the
   `finally` opens with `if name is not None:` (`:2216`) for the one state in which no
   candidate exists.
2. The checker's three outcomes have three arms — rejected (`False`, nothing written),
   accepted and cannot-be-run (install, record, warn, `True`) — the site left the 3.7-only
   `capture_output=` population, and one `TRANSLATIONS` key was deleted with its only
   reader while exactly two were added (I-12, I-13).
3. `check-sc-contracts.py` carries **one** assertion with **four** arms (I-14, C-14) and
   the floor stays at 18/18 (C-16); `docs/dev-map.md`, `CONTEXT.md`,
   `docs/architecture.md` and `CHANGELOG.md` are corrected only where this change
   falsified them.

## C-1 — the gate's precondition, established first-hand before I-1 was written

Real binary, `sing-box version 1.13.15` at `/usr/local/bin/sing-box` (58069248 bytes). Run in a
`mktemp -d` root against fixture documents; `/etc/sing-box/config.json` was never an argument.

| # | command | exit | output |
|---|---|---|---|
| 1 | `sing-box check -c $R/valid.json` | `0` | *(empty)* |
| 2 | `sing-box check -c $R/config.json.check.ab12cd` | `0` | *(empty)* |
| 3 | `sing-box check -c $R/bad.json` | `1` | `^[[31mFATAL^[[0m[0000] decode config at $R/bad.json: dns.servers: json: cannot unmarshal string into Go struct field RawDNSOptions.servers of type []option.DNSServerOptions` |
| 4 | `sing-box check -c $R/config.json.check.ef34gh` | `1` | `^[[31mFATAL^[[0m[0000] decode config at $R/config.json.check.ef34gh: dns.servers: json: cannot unmarshal string into Go struct field RawDNSOptions.servers of type []option.DNSServerOptions` |

`sha256sum` proved the pairs identical: `1`/`2` both
`7531fbf4828c4d41964e33e7a58aca610607525e3a00670985fc1fa3e9a715c8`, `3`/`4` both
`959f40318a20fd9c6147582628eaae03983028b762ec62d481b1cf6979f2c6a9`.

**Result: POSITIVE.** Identical bytes earn the identical exit status and the identical message
whether or not the name ends in `.json`; `check -c` reads the file it is handed and does not
consult the extension. Two consequences beyond the gate's question, both load-bearing: the
checker **quotes the path it was handed**, which is what makes I-7's `out.replace(name,
str(CFG_PATH))` necessary rather than decorative, and it **colours its output** (`^[[31m` …
`^[[0m`) into a pipe, which only `_plain()`'s complete-CSI removal can clear. G-1 is discharged;
development proceeded.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `bin/sc` | `generate_config()`'s tail (executable `:2163-2222`, comment header `:2150-2162`) is I-1…I-11 with the candidate's creation **inside** I-2's `try`; the key `"Config check failed:\n{stderr}"` deleted with its only reader; the two keys of I-12 / I-13 added; `_doctor_run()`'s docstring widened to name its second caller (body untouched) | E-1 |
| `bin/sc` | **comment only, zero executable lines**: five lines at the rejection arm (`:2184-2188`, first statement of the inner `else:`) stating why that arm must stay outside the inner `try:` — absorbed into it, a rejection whose own `sys.stderr.write` raises `OSError` is caught by that `except OSError`, re-reported as cannot-validate, and the rejected document is then installed and baselined. The one fence in this tail whose failure mode is **silent**; placement confirmed against QA's `mut-CR6-arm-inside-try` shape (`### Mutation probes`) | E-8 |
| `.harness/scripts/check-sc-contracts.py` | one assertion `config_reaches_disk_only_when_the_checker_did_not_reject` (`:584-685`) with **four** arms, its `TESTS` entry (`:690-701`), the `dirname` clause (`:654-655`), and two stub classes (`_Verdict`, `_CheckerStub`) plus a `_bytes()` helper | E-2 |
| `.harness/scripts/baseline.json` | `test_count` and `passing_count` `17` → `18`, done in round 1 and **unchanged this round** (C-16) | E-3 |
| `docs/dev-map.md` | six one-clause edits: rows `:41` (three filesystem operations in one guarded region), `:70` (drift quartet), `:77` (`_write_private`), `:78` (`_plain` / `_doctor_run`), `:87` (18 assertions, **four** arms), and the `## Patterns to follow` bullet at `:104-109` (`capture_output=` at **two** sites) | E-4, C-10, C-18 |
| `docs/dev-map.md` | **three numbers, zero prose**: row `:106` `:2271` → `:2276` and `:3536` → `:3541`; row `:76` `bin/sc:3408` → `:3476`. All three re-verified first-hand against the final tree before writing (`grep -n capture_output bin/sc` → 2276, 3541, still `is_running()`'s OpenRC arm and `cmd_update_interval`'s timer restart; `grep -n "FR-7 scope" bin/sc` → 3476). Each was falsified by **this task's own +68 physical lines**, not inherited — closes D-3's owed correction and open issues 7 and 8 | E-9 |
| `docs/dev-map.md` | **one number, substance unchanged**: row `:76`'s mutation claim read `17 defined / 17 run / 17 passed` — T-29's measurement, falsified by **this task's own** raise of the floor to 18. Now states *every assertion passing* with `18 defined / 18 run / 18 passed` as the last measurement and the count named as whatever `baseline.json`'s `test_count` floor currently is, so a future assertion cannot re-stale it. Verified first-hand before writing, **including the collapse probe** (`### E-10`) — not carried over from T-29 | E-10 |
| `docs/architecture.md` | the relationship diagram now draws the candidate and the three verdicts ahead of `config.json`, with the drift record after the verdict | E-5 |
| `CHANGELOG.md` | one Chinese entry under `### 修复`, including G-11's cost; its freeze claim scoped to **标准输出与退出码**, to the hosts where `sing-box check` runs and its output decodes, and with the stderr change named (C-18) | E-6 |
| `CONTEXT.md` | **re-aimed per C-4**: no second term coined; the existing *checker verdict* entry's third disjunct corrected — undecodable checker output is a rejection, not a cannot-validate | E-7 (superseded by C-4) |

`git diff --stat` for this task's files (whole task, HEAD `fc634e3` → final tree):

```
 .harness/scripts/baseline.json         |   4 +-
 .harness/scripts/check-sc-contracts.py | 154 +++++++++++++++++++++++++++++++++
 CHANGELOG.md                           |   2 +
 CONTEXT.md                             |   9 ++
 bin/sc                                 |  86 ++++++++++++++++--
 docs/architecture.md                   |  14 ++-
 docs/dev-map.md                        |  17 ++--
 7 files changed, 265 insertions(+), 21 deletions(-)
```

`docs/tasks.md` and `docs/batches/closeout/*` also carry uncommitted PM edits; they are not
this task's diff.

## verify_all result

```
pre-task baseline (HEAD fc634e3):  PASS 19  WARN 0  FAIL 0  SKIP 1  exit 0
round-2 baseline (delivered tree): PASS 19  WARN 0  FAIL 0  SKIP 1  exit 0
after (final tree):                PASS 19  WARN 0  FAIL 0  SKIP 1  exit 0
delta:                             0 new failures, 0 new warnings, baseline preserved
B.4 at HEAD:                       17 defined, 17 run, 17 passed (baseline.json test_count 17)
B.4 round-2 baseline:              18 defined, 18 run, 18 passed (test_count 18)
B.4 after:                         18 defined, 18 run, 18 passed (test_count 18, NOT raised — C-16)
after E-8 (comment only):          PASS 19  WARN 0  FAIL 0  SKIP 1  exit 0; B.4 18/18/18
                                   B.1 syntax-checks bin/sc, so the added comment is compiled, not assumed
                                   executable lines re-measured: 2118, unchanged, +21 vs HEAD
after E-9 (dev-map coordinates):   PASS 19  WARN 0  FAIL 0  SKIP 1  exit 0; B.4 18/18/18
                                   three numbers in one doc file; no executable line, no suite and no
                                   baseline.json change, so the tally could only be re-confirmed, not moved
after E-10 (dev-map row :76 count): PASS 19  WARN 0  FAIL 0  SKIP 1  exit 0; B.4 18 defined/18 run/18 passed
E-10 collapse probe, in a clone:   PASS 19  WARN 0  FAIL 0  SKIP 1  exit 0; B.4 PASS, suite 18/18/18
                                   => still green with the arm collapsed; R-97 NOT closed by T-30
B.4 witness lines:                 none (/etc/sing-box and /var/lib/sing-box unchanged by the suite)
A.1 (no hardcoded secrets):        PASS — the new fixture's only literal is password "pw" (2 chars)
F.5 (docs/tasks.md <=300):         PASS
F.6 (task docs <=500):             PASS
```

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| D-1 | I-14 / C-3 — "arms driven by a stub bound to `sc.subprocess`" | The stub's result object also carries a `.stderr` **str** that no build in this tree reads | Without it the HEAD-clone control died with `AttributeError: '_Verdict' object has no attribute 'stderr'` — it detected the *spelling* of HEAD's `capture_output=True, text=True` shape, not its behaviour. With it the control fails on the real observable: `AssertionError: rejected: the checker was pointed at config.json itself` (re-measured this round against the same clone). Upheld by stage 5; its residual cost is CR-7, recorded in `04_RATIONALE.md` §5 and not fixed. |
| D-2 | `02_RATIONALE` §budget's estimate "about +6 comment lines" (a **non-binding** estimate — K-9 and NFR-3 bound executable lines only) | +38 comment lines against HEAD | C-8 forbids deleting a comment to reach a number, and the executable count is inside its bound with headroom either way. They carry the four facts a future editor of this tail needs **at the site**: why `mkstemp` is inside the guard, why `is not None` rather than `except NameError`, that the one handler covers three filesystem operations, and why the rejection arm sits outside the inner `try:` (`:2184-2188`, E-8). The last is the only one of the four whose loss is silent — B.4 stays 18/18 and the run still returns `True` — and it was the only fence in the tail carrying no comment. Disclosed because it is 6.3× the estimate, not because a constraint was broken. |
| D-3 | C-18's coordinates for the surviving `capture_output=` sites, `bin/sc:2258` and `:3523` | The true coordinates on the final tree are `bin/sc:2276` (`is_running()`'s OpenRC arm) and `:3541` (`cmd_update_interval`'s timer restart); `docs/dev-map.md:106` now carries those two numbers (E-9) | Same two sites throughout; only the numbering moved — `+13` physical lines in `generate_config()` first, then E-8's `+5`, both above both sites. Writing a stale number into `docs/dev-map.md` reproduces CR-2's exact defect (a false coordinate in the file the developer agent reads before writing code), which is why the correction was made here under E-9 rather than deferred: both numbers were falsified by this task's own lines, and the pool's scope rule exempts a sentence one's own change falsifies. Measured with `grep -n capture_output bin/sc` on the final tree, immediately before the edit. The same correction is still owed to `.harness/rejected-decisions.md:228`, which is PM-owned (RS-5 / CR-10). |

No other deviation. I-1…I-11 are present in order with no twelfth statement; K-1…K-13 hold.

## Condition disposition

| id | disposition | evidence |
|---|---|---|
| C-1 | **DISCHARGED round 1 — positive, preserved verbatim** | `## C-1` above: four commands, exit statuses and verbatim output, with the sha256 identity of both pairs. Real `/usr/local/bin/sing-box` 1.13.15, `mktemp -d` root, no stub. Not re-run this round and not weakened. |
| C-2 | **DISCHARGED round 1, carried** | V-6's two directions, quoted under `## Verification results`. The rendering path is byte-identical (`:2189-2201`, the whole `if code != 0:` block, has no hunk — E-8's five lines sit above it, inside the same `else:`, and are comment-only), so the row is carried under C-21 rather than re-run. |
| C-3 | **DISCHARGED, re-measured** | The rejected arm still fails on the HEAD clone (`fc634e3`, `git clone --no-hardlinks`, never a worktree): `FAIL … AssertionError: rejected: the checker was pointed at config.json itself`, `18 defined, 18 run, 17 passed`. Extended by C-14's fourth arm, not replaced. |
| C-4 | **DISCHARGED round 1** | No second glossary term; `CONTEXT.md`'s *checker verdict* entry corrected. Untouched this round. |
| C-5 | **DISCHARGED round 1** | One fixture root from a clone (`git clone --no-hardlinks . head-clone`, HEAD `fc634e3`), sentinel bytes `SENTINEL-CONFIG-PRE-STATE\n` / `SENTINEL-DIGEST-PRE-STATE\n`, installed documents `cmp`-identical (4625 bytes, sha256 `c976467141f3f0e12378d10e57fbcb564efd570d7d1ae0da78fc300dd4c9fdc2`). |
| C-6 | **DISCHARGED round 1** | Counter bound to the module global `sc.restart_service`, never inferred from an absent `systemctl`. Per-case counts under `## Verification results`. |
| C-7 | **DISCHARGED — hash re-taken on the final build** | `_plain` is byte-identical: HEAD `:2493-2535` and final `:2554-2596`, both 43 lines, both `sha256[:16] = f04a53be6c5599c8`. It has moved by **61** lines — the two executable lines came with the comment lines of D-2, E-8's five included — and changed by zero bytes. `_write_private` on the same run: `c394797931d99deb` on both sides. Re-confirmed on the final tree by a **second, independent** digest (whole `ast` span, `def` line through `end_lineno`, run identically over HEAD and the final file): equal across the two sides for both functions — `_plain` `23273b32d2c63125` at HEAD `:2493-2535` and final `:2554-2596`, `_write_private` `433f00cacff4e18b` at HEAD `:488-538` and final `:491-541`. The digest **values** differ from the round-2 line above because the span convention differs; the claim C-7 makes — HEAD ≡ final, zero bytes changed — is what both recipes measure, and both return it (K-2 / BC-7). |
| C-8 | **DISCHARGED — measured 21, re-measured 21** | Whole-file `ast` classification, run identically over both sides: executable **2097 → 2118 = +21**, exactly K-9's prediction (34 − 13); `generate_config()` alone 61 → 82, also +21. Against NFR-3's **25**: PASS with 4 lines of headroom. Nothing was compressed, no comment deleted and no `try` arm dropped — the count was +21 before and after the comment additions of D-2, E-8's five lines included, which the classifier scores separately. Table under `## Verification results`. |
| C-9 | **CARRIED** | RS-6 / RS-7 text for `07_DELIVERY.md` under `## Residual text to carry forward`, with the true window stated (one whole `sing-box check`, unbounded on a hung checker, leaked entry visible in `_doctor_permissions()` thereafter). |
| C-10 | **DISCHARGED** | Six one-clause edits in `docs/dev-map.md`: rows `:41`, `:70`, `:77`, `:78`, `:87` and the `## Patterns to follow` bullet at `:104-109`. Rows `:70`, `:77`, `:78` were written in round 1 and are still true, so they were re-read and left; `:41`, `:87` and the bullet were corrected in round 2. Plus E-9, three **pure coordinates** and no prose (`:106` `:2276` / `:3541`, `:76` `:3476`), taken under the scope rule's clause for a sentence one's own change falsifies — all three were falsified by this task's +68 physical lines. Plus E-10, one **count** and no prose: row `:76`'s `17/17/17` → the clean sweep at `18/18/18`, re-established by actually collapsing the arm in a `--no-hardlinks` clone (`### E-10`) rather than transcribed, and worded against the current `test_count` floor so an added assertion cannot re-stale it — falsified by this task's own raise of that floor. `git diff --stat docs/dev-map.md` = 17 changed lines (E-10 shares row `:76`'s line with E-9). No prose sweep — T-32 owns the rest. |
| C-11 | **CARRIED** | G-11 disclosure text under `## Residual text to carry forward`; also in the user-facing `CHANGELOG.md` entry as 「请注意这一条的代价」. |
| C-12 | **DISCHARGED — exactly two executable lines** | The round-1 build was reconstructed and diffed against the round-2 build: `name = None` (`bin/sc:2163`) and `if name is not None:` (`:2216`) are the only added executable lines; `mkstemp` (`:2165-2166`) is the `try`'s first statement, **nothing** sits between the sentinel and `try:` (`:2164`), the unlink block is re-indented and otherwise untouched, and `_record_generated()` (`:2221`) stays textually after the whole `try`/`except`/`finally` (K-3). Classifier on that pair: executable 2116 → 2118 = **+2**, everything else comment. |
| C-13 | **DISCHARGED** | The true enumeration of what sits outside I-2's `try`, and why none of it can raise, under `## Verification results` → `### C-13`. I-2's "the only statement" is **not** restated: **five** members — three statements (`name = None`, `_record_generated()`, `return True`) plus two unprotected bodies, the outer handler's and the `finally` clause's own — and the load-bearing sentence is *no statement outside the `try` can raise*. The `finally`'s own body is the member direction A's probe measured escaping (`TypeError` past both handlers); it is safe here by the guard's constant comparison and the unlink's own `except OSError`. |
| C-14 | **DISCHARGED** | Arm 4 at `check-sc-contracts.py:670-683`, with a docstring (`:611-629`) that states all three facts — it passes on a HEAD clone and is a regression control never a HEAD discriminator, it is the suite's **only** control for the guarded-region invariant, and it reddens for both mutations with the exact exception each produces. Measured, not reasoned: arm 4 alone **PASSES** against the HEAD clone and against the round-2 build; both mutation directions turn B.4 red (see `### Mutation probes`). |
| C-15 | **DISCHARGED** | V-14's observable is the **line**, never a count: in the mandated fixture `_warn_degraded()` writes first (measured — two stderr lines, the degradation line at [1]), and the assertion is that exactly one `Could not write {path}` line is rendered, that it contains `str(CFG_PATH)` and that it contains no `.check.`. Captured stderr under `### V-14`. |
| C-16 | **DISCHARGED** | One function, `TESTS` holds 18 entries (`:690-701`), `baseline.json` reads `test_count 18` / `passing_count 18` — **not touched this round** (`git diff` shows no hunk in `baseline.json` after round 1). B.4 reports `18 defined, 18 run, 18 passed`. Adding an arm did not add an assertion (K-10). |
| C-17 | **DISCHARGED** | `_eq(os.path.dirname(cmd[3]), str(sc.CFG_DIR), …)` at `:654-655`, on all three stubbed arms. Never a containment: `str(sc.CFG_PATH) in cmd[3]` is satisfied by HEAD's own argv (a string contains itself) *and* by every candidate name, since `str(CFG_PATH)` is a literal prefix of it. Measured: a build with `dir=None` (TMPDIR) passes the round-1 assertion in full and goes red on the new clause. |
| C-18 | **DISCHARGED, with D-3** | Three prose corrections: `docs/dev-map.md:104-109` "three sites" → **two** (with the measured coordinates, D-3); row `:41`'s failure clause worded over the **three** filesystem operations the one region guards; `CHANGELOG.md:26`'s freeze claim scoped to **标准输出与退出码** and the stderr change named — the sentence scoped, not deleted. The same sentence also carries the **host** qualifier its own paragraph establishes (`在 sing-box check 能运行、输出也能解码的机器上`): on a host where the checker cannot be run, or emits bytes HEAD could not decode, HEAD ended in a traceback at exit 1 with no outcome line while this build warns, installs and exits 0, so both stdout and the exit code of that run do change there (C-11 / G-11). Without it the sentence is falsified by the change it documents. |
| C-19 | **DISCHARGED** | CR-6 restated in the form that holds and CR-7 recorded rather than fixed: `04_RATIONALE.md` §5. Round 1's wording (re-indenting one level) is falsifiable in thirty seconds — both re-indentations are `SyntaxError`s, verified by compiling them — and is gone. |
| C-20 | **CARRIED** | H-10 travels as a residual, under `## Residual text to carry forward`. |
| C-21 | **DISCHARGED — scope stated, not assumed** | `## Verification results` marks every row **re-run** or **carried**, and the carried rows each carry the argument. |
| C-22 | **PM-owned** | RS-8 travels as a note; no `01` round is owed. Not a developer edit. |

## Verification results

Every run used `docs/dev-map.md:129-177`'s loader recipe **plus** the exec-denial shim (every
process-start name in `dir(os)`, `popen` / `posix_spawn*` included), all nine path constants
repointed into a `mkdtemp` root **and each asserted inside it by name**, `SYSTEMD = OPENRC =
False`, `_init_files()` never driven, `main()` never called. No run wrote `/etc/sing-box` or
`/var/lib/sing-box`, none drove `sc reload` against the host and none restarted the service.

| step | round-2 status | observables |
|---|---|---|
| V-1 | **re-run** | B.4's 18th assertion, now four arms. `18 defined, 18 run, 18 passed`, evidence line: *one check per call in CFG_DIR at a non-config.json path, mode 0600, config.json intact at verdict time; rejected -> False, accepted -> True, cannot-run -> True, candidate-uncreatable -> False, no raise*. |
| V-2 | **carried** | AC-1 differential (byte-identical `config.json`, 4625 bytes, mode `0o600`, drift record = sha256 of the installed file, restart count 1). Not reachable by this round's delta: the accepted path binds a real `name` at `:2165`, so `if name is not None:` is always true and the `finally` executes round 1's block unchanged — re-confirmed behaviourally by arm 2 of V-1, whose observables are V-2's. |
| V-3 | **carried** | AC-4 absent `SB_BIN` (`[Errno 2]`), AC-5 `0755` non-executable (`[Errno 8] Exec format error`) — the pair discriminates; AC-2 both files byte-identical; AC-3 fresh host, neither file exists afterwards. Same argument: every one of these reaches `_doctor_run`, so `name` is bound. Arm 3 of V-1 re-runs the cannot-run half on the round-2 build. |
| V-4 | **carried** | AC-6: stub exits 1 emitting `\377\376`; no exception, rejection reported, rendered line carries U+FFFD. `name` bound; the delta cannot reach it. |
| V-5 | **re-run for the arm-4 case, carried elsewhere** | Arm 4 fixture, measured this round: `CFG_DIR` listing `['if_inet6', 'nodes.json', 'rules']` **identical** before and after, whole-root walk identical, **zero** entries created anywhere, and `CFG_PATH.parent` still absent — so a failed candidate creation leaves nothing, on the one path the delta does change. V-2…V-4/V-10's listings are carried on the bound-`name` argument. |
| V-6 | **carried** | AC-8, both languages, both directions — quoted below. Rendering path untouched: the `if code != 0:` block (`:2189-2201`) has no hunk; E-8's five comment lines sit above it in the same `else:`. |
| V-7 | **carried** | BC-10: empty rejecting output → the reused key states the exit status; zh renders `检查器报告了错误，未输出信息（退出码 1）`. Rendering path untouched. |
| V-8 | **carried** | AC-9 freeze: `_doctor_config()` row-for-row identical to the HEAD clone over three on-disk states. `sc doctor` never enters `generate_config()`'s tail, so the delta is unreachable from it. |
| V-9 | **carried** | AC-10 freeze — table below. The three commands reach the tail only through paths that bind `name`; `cmd_update_rules()`'s recovery arm, its folded boolean and its outcome block have no hunk (K-12). |
| V-10 | **carried** | AC-11 with the real `sing-box`. **Not BLOCKED** — this host carries the binary. Rendering and substitution untouched. |
| V-11 | **re-run** | `verify_all` full run on the final tree: PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0, B.4 18/18/18. |
| V-12 | **re-run** | Classification below: **+21** executable, bound 25. |
| V-13 | **BLOCKED** | AC-12 needs root, the installed `/usr/local/bin/sc` and the live service. Nothing substituted; recipe carried forward below. |
| V-14 | **re-run, observable corrected first (C-15)** | Below. |

### C-13 — what sits outside I-2's `try`, and why none of it can raise

I-2's sentence "`name = None` … is the **only** statement of the tail that sits outside" is
**false** against the same design's K-3 and I-10/I-11 (H-1) and is not restated here. Three
statements sit outside it, plus two bodies that are lexically inside the statement but
unprotected by it: the outer handler's, and the `finally` clause's own. The load-bearing
sentence is: **no statement outside the `try` can raise.**

| statement | why it cannot raise |
|---|---|
| `name = None` (`bin/sc:2163`) | binds a constant to a local; no call, no attribute access, no import |
| `_record_generated()` (`:2221`) | total in practice, by its own two guards: `_config_digest()` returns `None` on `OSError` (`bin/sc:1981-1982`), `_record_generated()` returns immediately on that `None` (`:1998-1999`), and its `_write_private(STATE_PATH, …)` is inside `try: … except OSError: pass` (`:2000-2003`). A `ValueError` is unreachable for a 64-char hex digest. This fact lives in a **different function** and is nowhere cited by `02`, which is why it is written down here |
| `return True` (`:2222`) | a bare return of a constant |
| the outer handler's own `sys.stderr.write` (`:2209-2210`) | it **is** the handler, so an `OSError` there escapes uncaught — **HEAD-identically**, at the identical place (H-10). Not a BC-11 member: the population does not grow. Travels as a residual (C-20), recorded so it is not rediscovered as a defect |
| the `finally` clause's **own body** (`:2216-2220`) | an exception raised in a `finally` propagates out of the whole `try` statement, so this body is **not** protected by the `try` it belongs to — measured, not reasoned: direction A's `os.unlink(None)` raised `TypeError` past **both** handlers and replaced the pending return. In the shipped build it cannot raise, for two reasons: `if name is not None:` (`:2216`) compares a local against a constant — no call, no attribute access — and `os.unlink(name)` (`:2218`) sits in its own `try:` / `except OSError: pass` (`:2217-2220`) with `name` on that branch always the `str` `mkstemp` returned, so direction A's `TypeError` is unreachable here. This is the member the round-2 delta exists to make safe, and the only member the probes **prove** can escape |

The two inner arms' writes (`:2180-2182`, `:2195-2200`) are **inside** the outer `try` and are
therefore caught; a doomed stderr on those paths is mis-worded as a write failure, never
uncaught. Which one it is mis-worded as depends on where the arm sits: the cannot-validate
write is inside the **inner** `try`'s `except`, so a failure there reaches only the outer
handler; the rejection write sits in the `else` and so cannot be re-entered by the inner
`except OSError` — the property E-8's comment exists to hold at the site.

### Mutation probes — measured, not reasoned

The gate labelled its arm-4 analysis reasoned (no shell at stage 5). Both directions were run
here, each against a **copy** of the round-2 `bin/sc` driven through the suite's own
`--source` (never a `git worktree`), plus the V-14 driver for the run-level observable.

| direction | mutation | B.4 result | V-14 driver |
|---|---|---|---|
| A | delete `if name is not None:`, dedent its body | **RED** — `18 defined, 18 run, 17 passed`; `FAIL … TypeError: unlink: path should be string, bytes or os.PathLike, not NoneType` | the outcome line is still written, then `TypeError` escapes the `finally` and replaces the pending return — the run ends in a traceback |
| A′ | …and delete the sentinel with it | **RED** — `18 defined, 18 run, 17 passed`; `FAIL … UnboundLocalError: cannot access local variable 'name'` | same shape |
| B | move `mkstemp` back above the `try:` | **RED** — `18 defined, 18 run, 17 passed`; `FAIL … FileNotFoundError: [Errno 2] … config.json.check.7dlzwrmz` | **zero** `Could not write` lines and an uncaught `FileNotFoundError` — CR-1's defect reproduced exactly: a non-zero exit with no run-level outcome line |
| C | `dir=None` (candidate into `TMPDIR`) | **RED on the new clause only** — `AssertionError: rejected: the directory the candidate was created in: got '/tmp', want '<CFG_DIR>'`; against round 1's suite the same build **PASSES in full** | — |

The mitigation is at least as strong as the gate ruled: neither direction stays green, and
direction B's V-14 output is the measured form of the BC-11 violation that produced CR-1.

**`mut-CR6-arm-inside-try` — placement check for E-8, not a re-measurement.** QA measured this
mutant's behaviour (B.4 green, `True` returned, the rejected document installed and re-baselined);
that result is taken as given and was not re-run. What was checked here is only that E-8's comment
sits **where the edit is made**: the mutation was applied mechanically to a scratch copy (never the
working tree, never a worktree) by taking the whole body of the inner `else:` and splicing it into
the `try` body after `_doctor_run`, then deleting the `else:`. It moves **18** lines and the
**first five of them are E-8's comment**, which lands directly under the `_doctor_run` call and
above the `if code != 0:` it belongs to. The mutant compiles — silently, which is the whole
point. An editor performing this edit therefore reads the refutation as the first line of what
they are moving, at the moment they move it.

### V-14 — BC-11 at the candidate's creation, and the HEAD comparison

Fixture: `sc.CFG_PATH` repointed under a parent directory that does **not** exist (root-proof —
`FileNotFoundError` for any uid), node store and settings intact in the run root, no stub bound,
stderr captured. Run once outside the suite on both builds.

| observable | round-2 build | HEAD clone `fc634e3` |
|---|---|---|
| returned | `False` | `False` |
| raised | none | none |
| stderr lines | 2 | 2 |
| line [1] | `⚠️  4/4 rule-sets unusable … degraded to no-splitting mode …` (`_warn_degraded`, H-2/PQ-7 confirmed) | identical |
| line [2] | `⚠️  Could not write $R/v14/no-such-directory/config.json: No such file or directory` | identical |
| renders `str(CFG_PATH)` | yes | yes |
| contains a candidate name (`.check.`) | **no** | n/a |
| `_warn_drift()` fired | no (`_config_digest()` cannot read `CFG_PATH`, so `_drift_state()` is `None`) | no |
| `STATE_PATH` | unchanged (absent → absent) — `_record_generated()` not reached | unchanged |
| `CFG_DIR` listing / whole-root walk | identical before and after; **0** entries created | identical |

The run-level outcome is **preserved, not introduced**: HEAD prints the same key for the same
host state, because HEAD's first tail statement is `_write_private(CFG_PATH, text)` inside its
own `try`, whose `mkstemp(dir=path.parent)` raises the same error.

### V-6 — AC-8, captured stderr, both languages (carried from round 1)

```
en: ⚠️  $R/config.json was left unchanged — `sing-box check` rejected the new configuration:
    FATAL decode config at $R/config.json: STUBTOKEN unmarshal
zh: ⚠️  $R/config.json 未被改动 —— `sing-box check` 拒绝了新的配置：
    FATAL decode config at $R/config.json: STUBTOKEN unmarshal
```

Asserted on both: names `config.json` ✓, states it was left unchanged ✓, no `\x1b` ✓, no `\r` ✓,
does **not** contain the candidate's name ✓, the checker's own token survives ✓, zh contains no
`失败：` ✓. A mutant deleting only `.replace(name, str(CFG_PATH))` leaks
`…/config.json.check.pqbf5o8i` and still satisfies "contains `str(CFG_PATH)`" — the prefix trap,
reproduced live. The cannot-validate line, same shape:

```
en: ⚠️  $R/config.json was installed without being checked — `sing-box check` could not be run: [Errno 8] Exec format error: '$R/not-an-executable'
zh: ⚠️  $R/config.json 已写入，但未经检查 —— 无法运行 `sing-box check`：[Errno 8] Exec format error: '$R/not-an-executable'
```

### V-10 — AC-11, the real binary (carried from round 1)

Provoked with an override at an **unguarded** array key —
`{"dns": {"servers": {"$append": ["not-an-object"]}}}` — which reaches the checker and earns a
decode-class rejection, the class that quotes the path.

```
⚠️  $R/config.json was left unchanged — `sing-box check` rejected the new configuration:
FATAL[0000] decode config at $R/config.json: dns.servers[4]: json: cannot unmarshal string into Go struct field RawDNSOptions.servers of type option._DNSServerOptions
```

`config.json` byte-identical to its sentinel pre-state ✓, drift record byte-identical ✓, no
exception ✓, restart count 0 ✓, listing identical ✓, and against **genuinely coloured** output:
no `\x1b` ✓, no `\r` ✓, no candidate name ✓, the checker's words survive ✓. The surviving
`[0000]` is logrus' elapsed-time field, not a control sequence — the `\x1b[31m` … `\x1b[0m` pair
around `FATAL` was removed **whole**. This is the row that establishes AC-8's ESC clause; a stub
checker cannot (T-05 DEF-1).

### AC-10 freeze (V-9, carried from round 1)

| command | frozen and identical | differs, deliberately |
|---|---|---|
| `cmd_update_rules()` (stubbed fetches, rejecting checker) | **stdout byte-identical**; exit `1`; exactly **one** run-level outcome line; restart count 0 | stderr message text only — the deleted key's sentence becomes I-13's. The recovery arm, the folded boolean and the outcome block are untouched; R-100's population does not grow |
| `cmd_reload()` | exit `Reload failed`; stdout empty; restart count 0 | HEAD leaves a rejected `config.json` on disk, this build leaves none — **this is the fix**. HEAD's stderr had 4 lines to this build's 3, because `_plain()` rstrips the checker's trailing newline |
| `cmd_add()` | **stdout byte-identical** (`Added: n2 (⚠️ config check failed — see \`sc log\`)`); exit 0; restart count 0 | same on-disk difference |

### Restart counts (C-6, carried from round 1)

accepted 1 · cannot-validate/absent binary 1 · cannot-validate/unexecutable binary 1 · rejected
with existing config 0 · rejected on a fresh host 0 · rejected/undecodable output 0 ·
rejected/empty output 0 · rejected with the real `sing-box` 0. The counter wraps the module
global `sc.restart_service`; no count is inferred from an absent `systemctl`.

### K-13 — measured, not asserted from source

- **The candidate's mode at the instant the checker sees it: `0o600`**, read by the stub's own
  `os.lstat(argv[3])` inside `run()` in all three stubbed arms of the round-2 suite run.
- **`config.json`'s bytes at that same instant: still the pre-run sentinel**, in all three arms —
  the verdict really precedes the install.
- **`/etc/sing-box` entry set, before and after all round-2 work:** unchanged —
  `config.json`, `config.json.bak-2026-08-01-1001`, `.config.sha256`, `nodes.json`, `rules`,
  `settings.json` (the `.bak-` entry is the user's own and predates this task).
  `/var/lib/sing-box`: `cache.db`, unchanged. Fixture roots: identical before and after each
  case, in every outcome.

### V-12 line classification (C-8)

One `ast`-driven classifier run identically over both whole files: a physical line is executable
unless it is blank, comment-only, inside a docstring, or an interior line of the `TRANSLATIONS`
dict literal.

| class | HEAD `fc634e3` | round-1 build | round-2 build | final build | net vs HEAD |
|---|---|---|---|---|---|
| executable | 2097 | 2116 | 2118 | **2118** | **+21** |
| comment | 459 | 481 | 492 | 497 | +38 |
| docstring | 613 | 619 | 619 | 619 | +6 |
| `TRANSLATIONS` data | 225 | 228 | 228 | 228 | +3 |
| blank | 414 | 414 | 414 | 414 | +0 |
| total physical | 3808 | 3858 | 3871 | 3876 | +68 |

`generate_config()` alone: 61 executable lines (`:2054-2161` at HEAD) → 82 (`:2057-2222`),
also **+21** — two methods, one figure.

The final column is E-8's five comment lines and nothing else: the executable row is **identical**
to the round-2 build, re-measured by the same classifier on the same recipe rather than argued
from "comments cannot be executable". This is the direction C-8 cares about, since the round exists
to add a comment and the count it must not move is the one NFR-3 bounds.

**Against the two numbers:** +21 vs NFR-3's bound of **25** — 4 lines of headroom, PASS. +21 vs
K-9's prediction of **21** — exact, and it is arithmetic on a measured 32-added tail, not a
coincidence. Nothing was compressed, no message string shortened, no comment deleted and no
`try` arm dropped; the round-1 → round-2 delta is +2 executable and +11 comment, and the +11 do
not enter the count.

`git diff -U0` still reports a smaller removed set (it matches several old tail lines against
textually identical new ones); the whole-file count above is the accounting that is invariant
under that matching.

### CONTEXT.md diff (C-4, round 1, unchanged)

```diff
-or **cannot-validate** (no binary on `PATH`, a binary that will not execute, output the caller cannot
-decode). Cannot-validate is not rejected — …
+or **cannot-validate** (no binary on `PATH`, or a binary that will not execute). … Output the caller
+cannot decode is **not** a third cannot-validate case: the one decode is `utf-8`/`replace`, which is
+total over every byte string, so undecodable words from a rejecting checker are a *rejection*
+carrying U+FFFD.
```

## Live service witness

`systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts sing-box`, never `is-active`:

| when | MainPID | NRestarts | ActiveEnterTimestamp |
|---|---|---|---|
| before round-2 work | 2566751 | 0 | Tue 2026-08-11 12:13:57 CST |
| after round-2 work | 2566751 | 0 | Tue 2026-08-11 12:13:57 CST |
| before and after E-8 | 2566751 | 0 | Tue 2026-08-11 12:13:57 CST |
| after E-9 | 2566751 | 0 | Tue 2026-08-11 12:13:57 CST |

Identical, and identical to the batch's reference. The service was never restarted, reloaded or
touched. E-9 could not have touched it — three numbers in one Markdown file — and the reading is
taken anyway rather than assumed.

## Residual text to carry forward

**RS-6 (C-9), for `07_DELIVERY.md`** — Known cost, accepted: a run killed between the candidate's
creation and its `finally` (SIGKILL, power loss) leaves one `0600` `config.json.check*` entry
under `/etc/sing-box` that nothing removes, because BC-1 forbids a sweeper. The kind is not new —
`_write_private()` already has this residue class at HEAD for its own `.tmp.` name — but **the
window is not the same size**: `_write_private()`'s residue window is its own `mkstemp`→
`os.replace` interval with no child process in it, while the candidate's window spans a whole
`sing-box check` and is **unbounded on a checker that hangs**, since I-15 forbids a timeout. A
leaked entry is listed by `_doctor_permissions()` from then on.

**RS-7 (C-9), for `07_DELIVERY.md`** — A concurrent `sc doctor` can list the candidate in
`_doctor_permissions()`'s per-entry rows for the duration of one `sing-box check` — the same race
and same kind as `_write_private()`'s existing `.tmp.` entry, with the same enlarged window as
RS-6. Not fixed here.

**H-10 (C-20), for `07_DELIVERY.md`** — A `sys.stderr.write` that itself raises **inside the
outer handler** (`bin/sc:2209-2210`) still escapes `generate_config()` uncaught. This is **not**
a BC-11 member: HEAD's handler has the identical shape at the identical place, so the population
of runs that exit non-zero with no outcome line does not grow. No proportionate fix exists at
this size — guarding a handler's own render needs either a second nested `try` per arm or an
`except Exception` envelope above `generate_config()`, which K-12 forbids — and it is recorded
here so it is not rediscovered as a defect.

**C-11 / G-11, for `07_DELIVERY.md`** — On a host with no usable `sing-box` (absent binary, or a
binary that will not exec), a run that previously unwound with a traceback now installs the
document, warns that it was not checked, returns `True`, and therefore lets `reload_or_restart()`
and `cmd_update_rules()`'s recovery arm proceed to a **restart** that HEAD never reached. This is
FR-4's intended reading; no AC covers it. Measured: restart count 1 in both cannot-validate
cases. Also stated in the `CHANGELOG.md` entry.

**RS-2 (AC-12 / V-13), still BLOCKED** — Needs root, the installed `/usr/local/bin/sc` and the
live service; nothing was substituted. Discharge recipe for an operator: install the new
`bin/sc`, provoke a rejecting override (an `$append` of a non-object onto `dns.servers` reaches
the checker and is refused), run `sc reload`, confirm `/etc/sing-box/config.json` is byte-
identical to before, then `systemctl restart sing-box` and take
`systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts sing-box` before and after; the
unit must start and must survive a reboot.

**RS-5 / CR-10, for `docs/tasks.md`** — this site has left the `capture_output=` population; the
surviving **two** are `bin/sc:2276` and `:3541`, measured on the final tree (**not** the `:2258` /
`:3523` of round-1 coordinates, and **not** the `:2271` / `:3536` that were true before E-8's five
lines moved both by 5, D-3). Both places that carry the pair now agree with the tree:
`docs/dev-map.md:106` via E-9, and `.harness/rejected-decisions.md` (PM-owned) already reads
`:2276` / `:3541` at `:234`. Nothing owed here beyond the pool row's own wording.

## Open issues for review

1. **Schema gap, reported not designed around.** `.harness/rules/70-doc-size.md`'s
   `## Stage-doc boundary rule` has no numbered rows, and C-1, C-8, C-13, C-15, C-21 and K-13
   name **`04_DEVELOPMENT.md`** (a document, not a section) as the destination for units the
   developer schema declares no shape for — a real-binary transcript, a line classification, a
   control-flow enumeration, a captured stderr, a verification table and a measured mode. They
   are carried in `## Verification results` and `## C-1` under that rule's precedence clause;
   this row is the schema-gap record.
2. **`_doctor_run()` has no timeout, and now a caller on the write path.** I-15 forbids adding
   one and I did not. Consequence stated in RS-6. At HEAD the same hang blocked the same call —
   but after `config.json` had already been replaced, so the exposure moved rather than grew.
   Worth a pool row, not this task.
3. **The two `OSError` renderings in one function** (`:2182` `_plain(str(e))` vs `:2210`
   `_plain(getattr(e, "strerror", None) or str(e))`) — **ruled wanted** by CR-8, no change made.
   Kept visible only because the comment block above the handler now names three operations and
   a reader may re-open the question.
4. **FR-5's path substitution still has no committed control** (CR-5 / RES-2): deleting
   `.replace(name, str(CFG_PATH))` leaves B.4 at 18/18. `## Out of scope` 9 declines a fifth arm
   and I did not add one; V-6 remains a one-off stage-4 run. Same shape `docs/dev-map.md:76`
   records for the recovery arm, which E-10 re-measured at 18 — both are now stated at the floor.
5. **`verify_all` A.1 cannot see the new assertion's fixture literal** — its pathspec excludes
   `.harness/*` wholesale (insight 24). The only credential-shaped literal is `"password": "pw"`
   (2 characters, an `.invalid` host). Nothing to fix; noted so nobody credits A.1 with it.
6. **`docs/tasks.md` and `PM_LOG.md` keep growing.** F.5 and F.6 both PASS today. Both are
   PM-owned; not touched here.
7. ~~**E-8 shifted two coordinates in `docs/dev-map.md`.**~~ **DONE (E-9.)** `docs/dev-map.md:106`
   carried `:2271` / `:3536`, stale by 5 because E-8's five comment lines sit above both sites.
   Corrected to `:2276` / `:3541`, each re-verified against the final tree with
   `grep -n capture_output bin/sc` immediately before the edit and each confirmed to still be the
   arm the row names. Paid rather than deferred because a stale coordinate in the file the
   developer agent reads before writing code is exactly CR-2's defect, and because this task's own
   lines are what falsified it. The identical +5 owed to `.harness/rejected-decisions.md` is
   PM-owned and has since been applied there (`:234` reads `:2276` / `:3541`), so RS-5 now carries
   no debt.
8. ~~**`docs/dev-map.md:76` cites `bin/sc:3408` for the recovery arm's comment.**~~ **DONE (E-9.)**
   Corrected to `:3476`, verified with `grep -n "FR-7 scope" bin/sc` on the final tree. Measured,
   not assumed, in both directions: at HEAD `fc634e3` line 3408 **is** that comment — the row was
   exactly right — and **this task's own +68 physical lines** (63 from round 2, 5 from E-8) moved
   it, so the debt was T-30's and not inherited. Round 2's C-10 sweep simply did not list row
   `:76` among the six it corrected.
9. ~~**`docs/dev-map.md:76`'s mutation claim cites a 17-assertion suite.**~~ **DONE (E-10.)** T-29
   measured 17/17/17; this task's raise of the floor to 18 falsified the number, not the claim.
   Re-measured first-hand, collapse included, reworded against the floor (`04_RATIONALE.md` §E-10).

## Dev-map updates

Six one-clause edits in `docs/dev-map.md` (C-10), three coordinates (E-9), one count (E-10); no
other prose sweep. Three of the six were round 1 and re-read as still true; three were corrected
in round 2:

1. `# Config generation` (`:41`) — **corrected in round 2**: the failure clause is now worded
   over the **three** filesystem operations the one guarded region covers, with why the
   candidate's creation is inside it and what the `finally`'s guard is for.
2. The drift-quartet row (`:70`) — round 1, still true: `_record_generated()` runs after a
   verdict that did not reject, and that is a control-flow fact, not adjacency.
3. `_write_private` (`:77`) — round 1, still true: a second *caller* at a second path, never a
   variant of the writer.
4. The `_plain` row (`:78`) — round 1, still true: `_doctor_run(cmd)` has a caller outside
   `# doctor`, what it inherits and what it must never gain.
5. The contract-suite row (`:87`) — **corrected in round 2**: 18 named assertions and **four**
   arms, with the fourth named as passing on a HEAD clone by design and as the only control for
   the guarded region.
6. The `## Patterns to follow` bullet (`:104-109`) — **corrected in round 2**: `capture_output=`
   at **two** sites, with their measured coordinates and why there were three.

Plus **three pure coordinates** (E-9) and **one count** (E-10), no prose, each verified first-hand
against the final tree immediately before it was written — and all four falsified by this task's
own change (E-9's three by its `+68` physical lines, E-10's by its raise of the floor 17 → 18),
which is the scope rule's exemption from "do not sweep prose — T-32 owns that":

7. Row `:106` — `:2271` → `:2276`, `:3536` → `:3541` (`grep -n capture_output bin/sc`); still
   `is_running()`'s `elif OPENRC:` arm and `cmd_update_interval`'s timer restart, E-8's five
   comment lines above both. The `def` at `:2271` is what the stale number had been.
8. Row `:76` — `bin/sc:3408` → `:3476` (`grep -n "FR-7 scope" bin/sc`); at HEAD `fc634e3` that
   comment is at `3408`, so the row was right when written.
9. Row `:76`, **same physical line** (E-10) — the mutation claim's `17/17/17` (T-29's) now reads
   *every assertion passing*, `18/18/18` when last measured, the count named as whatever
   `baseline.json`'s `test_count` floor is. Collapse re-run in a clone; B.4 green at 18 (§E-10).

No other line of `docs/dev-map.md` was touched, and no file was added, moved or removed.

## Insight

- `sing-box check -c` reads the file it is handed and ignores the extension entirely — identical bytes at `x.json` and at `config.json.check.ab12cd` earn the same exit status and byte-identical output on 1.13.15 — and its decode-class rejection **quotes the path it was given**, which is why an install-after-verdict design must substitute that path out of the message rather than merely trusting a stub that never quotes anything · evidence: `docs/features/validate-before-baseline/04_DEVELOPMENT.md` §C-1
- A contract-suite stub that omits an attribute the *old* build read turns a behavioural control into a spelling control: without a `.stderr` on the fake `CompletedProcess`, T-30's new assertion failed the HEAD clone with `AttributeError` rather than `the checker was pointed at config.json itself`, and would have reported "fails on HEAD" while proving only that HEAD's keyword arguments differed · evidence: `.harness/scripts/check-sc-contracts.py` `_Verdict`
- `git diff -U0` is not a line budget: it matched 7 of the 13 lines this task rewrote against textually identical lines in the replacement and reported 6 removed executable lines instead of 13, so a net-added-lines criterion measured from the diff disagrees with the same criterion measured by classifying both whole files (which reproduced the design's prediction exactly) · evidence: `docs/features/validate-before-baseline/04_DEVELOPMENT.md` §V-12
- Moving a branch out of a `try`'s `else` and into its body is invisible to every control this repo has: measured by QA on T-30's rejection arm, the absorbed form keeps B.4 at `18 defined, 18 run, 18 passed` and still returns `True`, because the arm's own `sys.stderr.write` failure is then caught by the sibling `except OSError`, re-reported as the opposite outcome, and the rejected document is installed and baselined — so an `else` that exists to keep two arms disjoint needs a comment at the site, not only a stage document that gets archived · evidence: `bin/sc:2184-2188`
- A membership assertion over a directory is satisfied by an object that was never in that directory: measured, a `bin/sc` whose candidate goes to `TMPDIR` instead of `CFG_DIR` passed every clause of T-30's contract assertion — the argv inequality *and* the `sorted(os.listdir(CFG_DIR))`-unchanged clause — because "no new entry appeared here" and "it never lived here" are the same observation, and only `os.path.dirname(argv[3]) == str(CFG_DIR)` separates them · evidence: `.harness/scripts/check-sc-contracts.py:654-655`

## Verdict

READY FOR REVIEW
