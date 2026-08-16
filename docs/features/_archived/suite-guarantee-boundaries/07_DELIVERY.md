# Delivery Summary

## Summary

- Task: **T-31 / suite-guarantee-boundaries** — make the committed contract suite's guarantees match its claims: the privilege denial that keeps `verify_all` from ever elevating was a **name list** covering only `os.*`, and the suite was structurally blind to zh-only regressions and to T-25's output-layer contract.
- Mode: full (7 stages), pool `closeout`.
- Stages traversed, all 2026-08-16: 1 requirement-analyst → **M-1 measurement** (routed to an independent runner, stage 2 holding no shell) → 2 solution-architect → 3 gate-reviewer → 4 developer (**4 rounds**) → 5 code-reviewer (**3 rounds**) → 6 qa-tester (**2 rounds**) → 7 delivery.
- Rollbacks: **2** — stage 5 → stage 4 on **CR-1 (MAJOR)**, and stage 6 → stage 4 on **DEF-1 (CRITICAL)**. Two further stage-4 rounds were **scoped corrections inside approving verdicts** (CR-11/CR-12; and the post-QA re-review), recorded as such rather than counted as rejections. The stage-4 streak never reached 3.
- Final verify_all result: **PASS** — `PASS 20 / WARN 0 / FAIL 0 / SKIP 1`, **exit 0**, stderr empty; B.3 (Lint) remains the single untouched SKIP. Task-start baseline was `PASS 19 / WARN 0 / FAIL 0 / SKIP 1` at HEAD `2a6b6e8`; the new step is **B.6** (`Assertion floor never below its last committed value`). Measured independently by the PM at five checkpoints and by QA three consecutive times, byte-identical.
- Baseline changes: `.harness/scripts/baseline.json` `test_count` / `passing_count` **18 → 19**, raised in the **same** commit as the 19th assertion; the floor was never lowered anywhere in the real repository. B.4 reports `19 defined, 19 run, 19 passed`.
- Outstanding risks: the denial has **zero committed controls** (R-108) — dropping half (b), a tuple entry, or the leak clause leaves `verify_all` green, because a control needs a committed escaping subject (a new file this task's scope forbids) or a second interpreter invocation (which the output-layer boundary denies). Four route families stay **open and are now written where a reader meets them**: `posix` / `ctypes` / `_posixsubprocess.fork_exec`, the **private** `os` helpers, the pre-import line, and the real-`os` attribute chain. On Windows neither the floor nor its monotonicity is checked at all (R-107).
- Files changed: **6 files, +382 / −33** excluding `docs/features/**` and `docs/batches/**` — `.harness/scripts/check-sc-contracts.py` +194/−13, `docs/dev-map.md` +95/−4, `.harness/rejected-decisions.md` +72/−5, `.harness/scripts/verify_all.sh` +40/−2, `CONTEXT.md` +8/−0, `.harness/scripts/baseline.json` +6/−3. **0 files added, 0 removed.** Net **executable** addition: **31** lines against NFR-2's cap of **40** (E-1 denial **3** · E-2 one-writer clause **14** · E-4 `floor_of()` + B.6 **14**), counted independently by the developer, the reviewer and QA and agreeing. Everything else in that diff is prose, docstring, comment or two data values — which is the shape a task about claims should have. **`bin/sc` is byte-identical to `2a6b6e8`** (`sha256 81d65da8…b312`), re-verified at seven checkpoints.
- Next steps for user: none required. `bash .harness/scripts/verify_all.sh` now also fails when `baseline.json`'s floor falls below its last committed value, and the suite's header states — in the same six claims as `docs/dev-map.md`'s recipe bullet — exactly what its process-start denial does and does not cover.

### Rows closed, and how — three of five by a sentence

**Say it plainly, because a future reader must not mistake a documented limit for a verified guarantee:**

- **R-93 — half closed by a check, half closed by narrowing the claim.** The `subprocess` route is now **refused**: `subprocess.call` / `Popen` / `run` moved from *marker present, exit 1* to `LoadRefused` / no marker / `os restored True` / `19 defined, 0 run, 0 passed` / **exit 2**. The enumeration half closed as **prose**: no name was added to the tuple, and the completeness claim is now scoped **twice** — to POSIX, and to the **public** spellings.
- **R-95 (zh blindness) and R-96 (T-25's output-layer contract) — closed by a WRITTEN BOUNDARY, at zero executable lines.** No second-language pass (it would be vacuous: expectation and observation share the `t()` lookup, so a wording change moves both sides — measured), and **no child-process test runner** (it would trade the suite's whole safety property for coverage). R-96's boundary names what *does* verify that contract: review at change time plus out-of-process measurement when the output layer itself changes — **not** B.4, and deliberately **not** claimed for B.5.
- **R-102(a) — closed by a check**, a source-level clause bounded to `generate_config()` and driven by the suite's existing `--source` parameter, red on the `os.replace` shape and green on the task-start `bin/sc`. **R-102(b) stays filed with its characterisation corrected**: the arm-position mutant diverges on a *behavioural* condition, so "needs a structural control" was not inherited as fact.
- **R-104 — closed by a check**: `verify_all` B.6, proven non-vacuous by lowering the floor and watching it FAIL naming both numbers (`17` vs `19`), and by four unreadable-history shapes that SKIP with exactly one line and no FAIL.
- **R-67 — honoured as the practice it is, not closed as work**: BC-4's non-discriminating case was declared at **stage 1**, before any code existed, and QA reported it as such rather than rounding it up.

### The measurement chain, which is the part worth inheriting

Every disposition here was decided by a run, and three of them **refuted the document that preceded them**.

1. **The brief's suspicion was right, and bigger than filed.** `subprocess.call/Popen/run` **and** `ctypes.CDLL(None).system` each started a process and left a marker while the suite ran on into its assertion phase; the `os.posix_spawn` control was refused. The design was fixed only after that reading.
2. **The gate found the residual list was missing its cheapest member** (G-1): `shim.path` **is** the real `posixpath`, whose `.os` is the real `os`, so `os.path.os.execvp(...)` passes through neither half of the denial. It closed that with a **sentence and a measurement**, not code.
3. **QA found the delivery's own defect one level down (DEF-1, CRITICAL), and it is the whole task in miniature.** `os._execvpe` and `os._spawnvef` are process-start names in `dir(os)` **today** and match no prefix in the tuple — every tuple spelling is public. A subject calling `os._execvpe` **replaced the loading interpreter with `touch`**: marker present, **exit 0, no summary, no refusal**. The completeness sentence this task had just written was false. It was fixed the way the task's thesis demands — by **scoping the claim**, not by lengthening the list, because `os.path.os._execvpe` was then measured escaping too: a name denies a spelling, not a capability.
4. **QA also found two controls that failed OPEN** (DEF-3): `(( ))` on an unparseable value is a bash *syntax error*, not false, so a duplicated `test_count` and a leading-zero floor both fell through to the PASS arm. One shape test in the single reader closed it in **B.6 and B.4 alike**.
5. **The reviewer re-derived DEF-1's closure from CPython's own source** rather than accepting the developer's audit script — the tuple matches exactly 22 names and **no public process-start spelling is unmatched** — and the PM measured the one figure nobody had read: `3.12.3 402 22`, exact.

### R-22, recursively — and the numbers reported rather than rounded up

QA ran **23 mutants** (18 mutating a delivered artifact): **6 killed, 12 surviving, every survivor named**. Four criteria are reported **NOT-DISCRIMINATING inside the AC-12 list** rather than as passes: BC-4, the post-`finally` `Popen` clause, the redirection order, and the read-the-artifact pair. **Nothing was BLOCKED** and no substitution was made; `strace` over a B.4 run reads `execve` **1**, `clone`/`clone3`/`fork`/`vfork` **0**. The final AC table is **14/14 PASS** after AC-3 moved from FAIL to PASS on a re-measured artifact — not on a re-worded criterion.

### Rule 85 — 「以少就是多」, and what the burden of proof bought

Stage 2 named the smaller alternative for every element and stage 3 **re-priced them itself**, re-deriving NFR-2's cap over its own element list (31–34 against a cap of 40, **upheld unamended**). Five of six rows closed on sentences. The one line added after review — `floor_of()`'s shape test — is the cheapest line in the change and is what makes two controls fail closed instead of open. Three candidate closures were priced and **rejected**, one of them *because* it appeared to work: denying the real `os`'s names stops today's `subprocess` only through one CPython's internal dispatch choice, and stops nothing the day `_posixsubprocess.fork_exec` is taken — a spelling standing in for a capability, which is the defect this task exists to stop.

### Live host and safety

Untouched throughout. `MainPID=2566751`, `NRestarts=0`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` identical at every PM checkpoint and at every stage's start, middle and end; `systemctl show` only, `is-active` **never** invoked. `/etc/sing-box` and `/var/lib/sing-box` unchanged. Every escape probe used a **scratch subject file** and a marker target — `--source` never pointed at `bin/sc` or at the installed `/usr/local/bin/sc`, and no probe could have run anything harmful had it escaped. **`guard-rm.sh` blocked an `rm`-free command a fifteenth time** (an `ls /etc/sing-box` inside a compound); the bypass was **not** set.

## Archive

`.harness/scripts/archive-task.sh --task suite-guarantee-boundaries` output is recorded in `PM_LOG.md`,
including whether the insight-index rotation fired (the index stood at **30/30** before the harvest, so
the branch T-27 repaired was on the critical path again). `.harness/scripts/entropy-cadence` does not
exist on this host (**R-88**, unchanged), so the delivery-time entropy watch resolved **NOT-DUE**
fail-open: no scan was run and no `## Entropy watch` section is written.

## Insight

- 2026-08-16 · A `sys.modules` `os`-shim cannot deny a capability by attribute at all: `shim.__dict__.update(os.__dict__)` copies **function objects** whose `__globals__` is the real `os` module's dict, so `os._execvpe` and `os._spawnvef` — private, present in `dir(os)` today, matched by no public-name prefix — call the real `execv`/`fork` whatever the shim's attributes say, and a subject invoking `os._execvpe` **replaced the loading interpreter with `touch` at exit 0 with no summary line**; the same is true one hop out (`os.path.os._execvpe`), so adding names buys a spelling and never the capability · evidence: suite-guarantee-boundaries
- 2026-08-16 · Every module imported **before** a `sys.modules["os"]` shim keeps the real `os` and re-exports it: `posix.system is os.system` is `True` and `sys.modules["posix"]` is never replaced, so `import posix; posix.system(...)` is a **two-token** escape cheaper than `ctypes` or any attribute chain, while `subprocess` funnels `run`/`call`/`check_output` through the module-global `Popen` and is therefore closable at one choke point · evidence: suite-guarantee-boundaries
- 2026-08-16 · Bash `(( ))` on an unparseable value is a **syntax error, not false**, so an `if / elif / else` chain built on it falls through to the `else` arm with only a stderr line: `verify_all`'s floor comparisons PASSed on a duplicated `test_count` (`19\n3`) and on a leading-zero floor (`018`) until the reader itself decided what a floor **is** (`[[ $v =~ ^[0-9]+$ ]]`, whose anchors are string-boundary so a two-line value fails it) and both comparisons were `10#`-pinned — a control that fails open reports nothing and passes everything · evidence: suite-guarantee-boundaries
- 2026-08-16 · A committed suite whose sentence assertions are written `sc.t("<English key>")` cannot be made to see a translation-only regression by re-running it under another language, because the expectation and the observation come from the **same** lookup and a destroyed rendering moves both sides — measured green under `en` and under `LANG="zh"` — so the honest closure of a zh-blindness row is a written boundary, and a second-language pass is machinery that adds runs and no discrimination · evidence: suite-guarantee-boundaries

## Verdict

DELIVERED
