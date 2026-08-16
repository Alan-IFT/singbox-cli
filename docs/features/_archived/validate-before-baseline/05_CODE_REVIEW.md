> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `bin/sc` (`:128-145` the two new `TRANSLATIONS` entries + `Could not write`, `:316` the reused empty-output key, `:1970-2054` the drift quartet incl. `_config_digest`/`_record_generated`'s own guards, `:2057-2069` `generate_config()`'s head, `:2130-2217` the whole re-ordered tail, `:2219-2229` `restart_service`, `:2586-2611` `_plain`'s tail + `_doctor_run`, `:2742` the doctor's reader of the shared key, `:2271` / `:3536` the two surviving `capture_output=` sites)
- `.harness/scripts/check-sc-contracts.py` (`:60-144` `PATHS` / `load()` / `fixture()`, `:535-582` `_Verdict` / `_CheckerStub` / `_bytes`, `:584-685` the assertion and its docstring, `:690-701` `TESTS`)
- `.harness/scripts/baseline.json`
- `docs/dev-map.md` (`:33-45` the section table incl. row `:41`, `:70`, `:77`, `:78`, `:87`, `:89-109` `## Patterns to follow`)
- `docs/architecture.md` (`:50-80`)
- `CHANGELOG.md` (`:24-26`)
- `CONTEXT.md` (`:115-141`)
- `README.md` / `README.zh-CN.md` (re-swept for sentences this round falsifies)
- `docs/features/validate-before-baseline/01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`, `03_GATE_REVIEW.md`, `04_DEVELOPMENT.md`, `04_RATIONALE.md`

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | CLOSED (was MAJOR) | Spec/design-fidelity | `bin/sc:2163-2166`, `:2207-2215` | **Closed, verified as control flow.** `name = None` (`:2163`) is immediately followed by `try:` (`:2164`) with nothing between them; `tempfile.mkstemp` (`:2165-2166`) is the `try`'s first statement; the `finally` opens `if name is not None:` (`:2211`). Every fallible statement of the tail — candidate creation, `os.close`, both `_write_private` calls, `_doctor_run`, both arms' `sys.stderr.write` — is now inside the one guarded region, so the `mkstemp` failure class renders `Could not write {path}` + `return False` instead of an uncaught `OSError`. BC-11 holds as a floor. The developer's direction-B mutation reproduced my round-1 defect exactly (uncaught `FileNotFoundError`, **zero** outcome lines), which is the measured form of the finding. |
| CR-2 | CLOSED (was MAJOR) | Standards-conformance | `docs/dev-map.md:104-109` | **Closed.** "`capture_output=` at **two** sites (`:2271`, `:3536`)" plus the sentence recording that there were three until T-30. I re-took the coordinates myself with `Grep` over `bin/sc`: the only two matches are `:2271` and `:3536` — D-3's correction is right and C-18's cited `:2258` / `:3523` were the stale pair. |
| CR-3 | CLOSED in substance (was MAJOR) | Standards-conformance | `CHANGELOG.md:26` | **Closed as scoped, not deleted:** the freeze claim now reads `标准输出与退出码` and names the stderr rewording as the one change. One qualifier is still missing on the cannot-validate host — carried forward as CR-13, MINOR. |
| CR-4 | CLOSED (was MINOR, NOT-DISCRIMINATING) | Standards-conformance | `.harness/scripts/check-sc-contracts.py:654-655` | **Closed.** `_eq(os.path.dirname(cmd[3]), str(sc.CFG_DIR), …)` runs on all three stubbed arms, never a containment. The developer's `dir=None` build measured the gap I asserted: it passed round 1's assertion **in full** and reddens only on this clause. `fixture()` (`:126-144`) sets `CFG_DIR` and `CFG_PATH` from one `PATHS` table, so the two spellings name one directory (H-9 stays a live note, not a defect). |
| CR-5 | OPEN, unchanged | Spec/design-fidelity | `.harness/scripts/check-sc-contracts.py:584-685` | FR-5 / K-4's `out.replace(name, str(CFG_PATH))` still has **no committed control**: delete it and B.4 stays 18/18. Within design scope (`02` `## Out of scope` 9 declines a fifth arm) and measured three ways at stage 4 (V-6, the leak mutant, the real binary). Travels as RES-2; not a developer fix in this task. |
| CR-6 | CLOSED (was MINOR) | Standards-conformance | `04_RATIONALE.md:177-194` | **Closed as required by C-19.** The re-indentation claim is gone (both directions compile to `SyntaxError`, checked by the developer, and the reasoning is reproduced), and the fence is restated in the form that holds: absorbing the rejection arm into the inner `try:` body makes a failing `sys.stderr.write` re-report as cannot-validate and then **install** the rejected document — AC-2 lost silently, with no red arm. The restatement is correct. Its durability is CR-17. |
| CR-7 | OPEN, recorded not fixed | Standards-conformance | `.harness/scripts/check-sc-contracts.py:535-548` | `_Verdict` is faithful to neither shape (`.stdout` bytes, `.stderr` str). Recorded per C-19 in `04_RATIONALE.md` §5 with the honest consequence: a build that keeps this ordering but re-inlines `capture_output=True, text=True` passes all four arms. No existing control is weakened; pinning the 3.6 floor is a different task. |
| CR-8 | CLOSED (ruled, no change) | Standards-conformance | `bin/sc:2182` vs `:2205` | Two `OSError` renderings in one function, confirmed wanted in round 1 and unchanged: the cannot-validate line carries the errno and the binary's path (which program could not be run is the actionable fact), the write line needs only `strerror` because `{path}` already names the file. |
| CR-9 | OPEN, upstream-ruled | Standards-conformance | `bin/sc:2051-2054`, `CONTEXT.md:123`, `README.zh-CN.md:423` / `README.md` peer | `_warn_drift()`'s "those changes are about to be replaced" is false on a rejected run. BC-5 rules the position frozen and makes the run's own rejection message the correction, so no edit is owed here; both READMEs describe the *message's* content accurately, so neither is falsified outright. Recorded so T-32's sweep does not re-discover it as a defect. |
| CR-10 | OPEN, PM-owned | Standards-conformance | `.harness/rejected-decisions.md:228` | "one of the **three** pre-existing `capture_output=` sites" — two remain, `bin/sc:2271` and `:3536` (coordinates re-taken by me this round, **not** the `:2258`/`:3523` the gate cited). PM-owned file; travels as RES-7 with RS-1's decision records. |
| CR-11 | MINOR | Spec/design-fidelity | `04_DEVELOPMENT.md:159-164` against `bin/sc:2207-2215` | **C-13's enumeration is incomplete by one member.** It lists `name = None`, `_record_generated()`, `return True` and the outer handler's body — the gate's own four — but the `finally` block's **own body** is also outside the guarded region: an exception raised there propagates out of the whole `try` statement, which is exactly what the developer's own direction-A probe measured (`TypeError` escaping past the inner `except OSError`). The property still holds — `if name is not None:` is a comparison against a constant, and `os.unlink(name)` sits inside its own `try:`/`except OSError: pass` with `name` always a `str` from `mkstemp` — so this is a missing row in a true table, not a defect in the code. The four citations the row does make (`bin/sc:1981-1982`, `:1998-1999`, `:2000-2003`, `:2204-2205`) I verified individually and all four are exact. |
| CR-12 | MINOR | Standards-conformance | `.harness/scripts/check-sc-contracts.py:618-620` + `:681-682`, echoed at `docs/dev-map.md:87` | **NOT-DISCRIMINATING, and the docstring over-claims by exactly the missing half.** Arm 4 asserts two things: `generate_config()` returns `False`, and no exception leaves. It asserts **nothing** about a rendered line. A build that catches the `mkstemp` `OSError` and returns `False` **silently** passes arm 4 while violating BC-11's sentence in full ("no new path exits non-zero without a **stated outcome**"). The docstring's second bullet claims arm 4 is "the ONLY control … for the guarded-region invariant: no filesystem call … may unwind **without a rendered run-level outcome line**"; the committed clause covers the unwind half only. The rendered-line half is measured at stage 4 (V-14, both builds, line `[2]` quoted) and committed nowhere — the same shape as CR-5. Faithful to I-14 as written, so this is the design's boundary, not a deviation. |
| CR-13 | MINOR | Standards-conformance | `CHANGELOG.md:26` | The scoped freeze claim `sc reload / sc add / sc update-rules 的标准输出与退出码均无任何改动` is unqualified over the host class the same paragraph discloses two sentences earlier: on a host with no usable `sing-box`, HEAD ended in a traceback (exit 1, no restart, no outcome line) and this build installs, warns, returns `True` and lets the caller restart — so **the exit code and the stdout of that run do change there** (C-11 / G-11 states precisely this). A missing qualifier rather than a hidden contradiction, but the sentence as written is falsified by the change it documents. One clause fixes it (`在 sing-box check 能运行的机器上…`). |
| CR-14 | NIT | Standards-conformance | `bin/sc:1991-1992` | `_record_generated()`'s docstring still argues from adjacency: "the realistic causes of a failure here (ENOSPC, EROFS) would have failed the `config.json` write **one line earlier**". After this change the write is at `:2197`, nineteen lines and a whole `finally` block earlier — the substance survives (it still precedes it in control flow, which is I-10's whole point), the phrase does not. **Out of scope to fix here**: `bin/sc:1954-2051` is frozen by T-14 and `02`'s frozen set moves the call site only. Files as a T-32 row (RES-10). |
| CR-15 | NIT | Standards-conformance | `04_DEVELOPMENT.md:8-9`, `:50` | The tail's span is cited as `bin/sc:2157-2217` in both the Summary and the Files-changed row. `:2157` is round-1's `mkstemp` line and now points **inside a comment block**; the re-ordered tail's comment opens at `:2150` and its first executable line is `:2163`. The end of the span was updated and the start was not — the stale-coordinate class this same document corrected for D-3, one table above. |
| CR-16 | NIT | Standards-conformance | `.harness/scripts/check-sc-contracts.py:663-668` | **NOT-DISCRIMINATING.** The accepted / cannot-run arms assert `after != installed`, that `after` parses as JSON, and that the record is its sha256 — never that `after` **is the composed document**. Two plausible wrong builds stay green: one that installs a different but valid document, and one that installs the candidate by `os.replace(name, CFG_PATH)` — the declined `candidate-installed-by-os-replace-instead-of-the-one-writer` (RS-1) — which also survives the mode, listing and `finally` clauses. AC-1's byte identity rests on V-2 alone and K-2's "no second temp-then-replace construction" on grep alone. Within design scope; recorded, not a fix. |
| CR-17 | MINOR | Standards-conformance | `bin/sc:2183-2189` against `04_RATIONALE.md:186-194` | The tail carries **two** fences and only one is marked at the site. The sentinel's fence has its comment at `:2208-2210` ("`is not None`, never `except NameError`"). The inner `else`'s fence — the one whose failure mode is *silent*, per CR-6's corrected statement — is documented only in `04_RATIONALE.md` §5, a non-binding stage document that is archived at delivery; the comment at `:2185-2189` explains the path substitution and says nothing about why the rejection arm must stay outside the inner `try:`. C-19 named `04_RATIONALE.md` as the destination, so the developer is compliant and **no in-task edit is owed**; the finding is placement durability and travels as RES-10 for the delivery/T-32 decision. |

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| FR-1 verdict before install, exactly one invocation | `bin/sc:2165-2197`; suite `:649` pins `len(calls) == 1`, `:657` pins `config.json` still holding pre-run bytes at verdict time | ✅ |
| FR-2 rejected installs nothing | `bin/sc:2184-2196` returns before `:2197`; suite `:660-662` | ✅ |
| FR-3 accepted: install then record, in that order | `bin/sc:2197` then `:2216` | ✅ |
| FR-4 cannot-validate installs, warns, succeeds | `bin/sc:2176-2182` falls through to `:2197`, `:2216-2217`; suite arm 3 | ✅ |
| FR-5 message names `config.json`, no run-only path | `bin/sc:2190-2195`, `out.replace(name, str(CFG_PATH))` | ✅ (no committed control — CR-5) |
| FR-6 record only after a non-rejected install reached disk | `bin/sc:2216`, textually after the whole `try`/`except`/`finally` | ✅ |
| BC-1 candidate is a credential document, removed on every outcome | `:2170` through `_write_private`; `finally` `:2207-2215` covers both `return False` paths and every exception | ✅ |
| BC-2 verdict is taken in `config.json`'s own directory | `dir=str(CFG_PATH.parent)` `:2165`; suite `:654-655` | ✅ |
| BC-3 fresh host, rejected ⇒ neither file created | V-3 (developer-measured) | ✅ |
| BC-4 / BC-8 drift judgement keeps one definition and one meaning | `bin/sc:2006-2032` untouched; V-8 freeze | ✅ |
| BC-5 hand-edited `config.json` survives a rejection | `:2196` returns before any write; `_warn_drift()` stays at `:2141` | ✅ (CR-9 recorded) |
| BC-6 two runs at once add no window | `mkstemp` `O_EXCL` per run; `_write_private` unchanged | ✅ |
| BC-7 `_write_private()` the only mechanism, five guarantees intact | body unchanged; developer's span hash `c394797931d99deb` both sides (not re-hashed here — RES-6) | ✅ |
| BC-9 exactly one apply per run, `update-rules` ordering unchanged | no `restart_service()` call site touched; V-9 freeze | ✅ |
| BC-10 empty rejecting output states the exit status | `:2193-2195` via the reused key `:316` | ✅ |
| **BC-11 no new path exits non-zero without a stated outcome** | `bin/sc:2163-2166` inside the guard; direction-B mutation reproduces the violation, direction A/A′ redden | ✅ **CR-1 closed** (rendered-line half uncommitted — CR-12) |
| BC-12 bilingual, identical placeholders, no `失败：` | `bin/sc:136-139`; keys re-read against `:2180-2182` / `:2190-2192` character by character — the implicit concatenations match the keys exactly | ✅ |
| BC-13 verification safety | `04_DEVELOPMENT.md` `## Verification results` + live-service witness (`MainPID 2566751`, `NRestarts 0`, unchanged) | ✅ developer-measured, PM re-measured |
| BC-14 blocked criteria reported with a recipe | V-13 / RS-2 | ✅ |
| AC-1 accepted, existing config, byte-identical | V-2 differential, one root, `cmp`-identical 4625 bytes | ✅ developer-measured (not pinned by the suite — CR-16) |
| AC-2 rejected, existing config | suite arm 1 + V-3 | ✅ |
| AC-3 rejected, fresh host | V-3 | ✅ |
| AC-4 absent `SB_BIN` | V-3 `[Errno 2]`; suite arm 3 | ✅ |
| AC-5 unexecutable `SB_BIN` | V-3 `[Errno 8] Exec format error` — distinct from AC-4, so the pair discriminates | ✅ |
| AC-6 undecodable rejecting output | V-4, U+FFFD, no exception (K-6's empty-extension reading) | ✅ |
| AC-7 candidate `0600` + no survivor | suite `:656` (mode read by the run, not by inspection) + V-5 listings incl. the arm-4 case | ✅ |
| AC-8 rejection message clauses, both languages | V-6, both directions, plus the leak mutant | ✅ (no committed control — CR-5) |
| AC-9 `sc doctor` freeze | V-8 row-for-row against the HEAD clone | ✅ |
| AC-10 `update-rules` / `reload` / `add` freeze | V-9: stdout and exits identical, stderr deliberately reworded | ✅ (CHANGELOG qualifier — CR-13) |
| AC-11 real `sing-box` | V-10, genuinely coloured output, complete CSI pair removed | ✅ not BLOCKED |
| AC-12 installed host / reboot | V-13 | **BLOCKED** — operator obligation with recipe (correct under BC-14) |
| AC-13 floor does not fall | `baseline.json:4-5` reads `18`/`18`, untouched this round; B.4 18/18/18 | ✅ |
| NFR-1 exactly one check process | suite `:649` | ✅ |
| NFR-2 `/etc/sing-box` entry set unchanged | V-5, K-13 | ✅ developer-measured |
| NFR-3 ≤ 25 net executable lines | V-12: +21 by two methods (whole file 2097→2118; `generate_config()` 61→82) | ✅ 4 lines of headroom — **not re-derived here** (RES-6); no trim demanded (C-8) |
| NFR-4 emitted bytes unchanged | V-2 `cmp` clean, same sha256 | ✅ |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| I-1 two statements: sentinel, then `mkstemp` as the `try`'s first statement | `:2163`, `:2165-2166`, `dir=str(CFG_PATH.parent)`, `prefix=CFG_PATH.name + ".check."` | ✅ |
| I-2 one `try` with one `except` and one `finally`, guard `if name is not None:` | `:2164`, `:2198`, `:2207`, `:2211`; both `return False` (`:2196`, `:2206`) are inside the statement, so the `finally` runs for each | ✅ |
| I-3 `os.close(fd)` immediately after `mkstemp` | `:2167` | ✅ |
| I-4 candidate through `_write_private` | `:2170`, `Path(name)` the only adaptation | ✅ |
| I-5 one `_doctor_run` at the candidate, no `shutil.which()` | `:2175`; the only other `check -c` is the doctor's, untouched | ✅ |
| I-6 cannot-validate arm falls through | `:2176-2182`, no `return`, reaches `:2197` | ✅ |
| I-7 rejected arm, substitution, `or` fallback | `:2184-2196` | ✅ |
| I-8 `_write_private(CFG_PATH, text)` | `:2197` | ✅ |
| I-9 one handler for all three filesystem operations, rendering `CFG_PATH` | `:2198-2206`; the inner `except OSError` (`:2176`) binds first, so a checker `OSError` can never render as a write failure | ✅ |
| I-10 / K-3 `_record_generated()` after the whole statement | `:2216`, column 4, after the `finally` block ends at `:2215`; unreachable from both `return False` | ✅ |
| I-11 boolean meaning unchanged | `:2217` | ✅ |
| I-12 / I-13 exactly two new keys, both languages | `bin/sc:136-139`; placeholder sets identical; `Config check failed:\n{stderr}` absent from the file | ✅ |
| I-14 / C-14 one assertion, four arms, stub restored in a `finally`, arm 4 binds none | `check-sc-contracts.py:584-685`, restore at `:646-647`, arm 4 at `:670-683` | ✅ (docstring over-claim — CR-12) |
| I-15 `_doctor_run` body unchanged, docstring widened | `bin/sc:2594-2610`: body is the 3.6-floor `stdout=PIPE` + `stderr=STDOUT` + `.decode("utf-8","replace")`; docstring names the second caller and forbids classification / truncation / timeout / per-caller parameter | ✅ |
| I-16 candidate spelling and lifetime | `config.json.check.<mkstemp suffix>`, unlinked in the `finally` | ✅ |
| K-1 no twelfth statement | the tail is exactly I-1…I-11 plus I-2's guard: no `shutil.which()`, no retry, no second check, no candidate/installed comparison, no third `try` | ✅ |
| K-2 `_write_private` byte-identical, no second temp-then-replace | signature `(path, text)`, no hook/mode/`keep=`/`check=`; developer's span hash identical both sides | ✅ (uncontrolled — CR-16) |
| K-4 every arm renders `CFG_PATH`, substitution applied before `t()` | `:2181`, `:2192-2193`, `:2204` | ✅ |
| K-5 / C-7 `_plain` frozen, hash re-taken on the round-2 build | `:2549-2591`, 43 lines; developer reports `f04a53be6c5599c8` on both sides after a **56**-line move | ✅ (not re-hashed here — RES-6) |
| K-6 no `except UnicodeDecodeError` | none added; `errors="replace"` inherited; CONTEXT's disjunct corrected to match | ✅ |
| K-7 old key deleted with its only reader, no third key | grep: `Config check failed` absent; `:316` reused by three readers | ✅ |
| K-8 3.6 floor at this site | no walrus, no `capture_output=`, no `text=`, no `unlink(missing_ok=)` in the new code; `capture_output=` now only at `:2271` and `:3536` (re-taken by me) | ✅ |
| K-10 / C-16 one function, floor stays 18, no existing assertion edited | `TESTS:690-701` holds 18; `baseline.json` reads `18`/`18` | ✅ |
| K-11 no `ast` shape check, no child process, `SB_BIN` never real | stub only; `fixture()` points `SB_BIN` at an absent path | ✅ |
| K-12 no `restart_service()` call site changed, no `except` at a caller | `bin/sc:2219-2229` and the recovery arm untouched | ✅ |
| K-13 mode and entry set measured, not asserted from source | `04_DEVELOPMENT.md` §K-13 | ✅ developer-measured |
| C-1…C-6 | **DISCHARGED round 1 by gate ruling; not re-done, and the C-1 transcript is intact and unweakened in `04_DEVELOPMENT.md` §C-1** | ✅ |
| C-7 `_plain` hash re-taken on the round-2 build | span moved 56 lines, zero bytes changed | ✅ |
| C-8 budget measured, no trim | +21 vs bound 25, two methods agreeing; nothing compressed, +11 comments explicitly outside the count | ✅ (not re-derived here — RES-6) |
| C-9 residuals carry their true window | RS-6 / RS-7 text names one whole `sing-box check`, unbounded on a hang, entry visible to `_doctor_permissions()` | ✅ carried |
| C-10 / C-18 six one-clause dev-map edits and nothing else | rows `:41` (three filesystem operations, one region, the guard's purpose), `:70`, `:77`, `:78`, `:87` (18 assertions, four arms), bullet `:104-109` (two sites, coordinates verified) | ✅ |
| C-11 / G-11 disclosure | `07_DELIVERY` text + `CHANGELOG.md:26`「请注意这一条的代价」 | ✅ (qualifier missing — CR-13) |
| **C-12 exactly two executable lines** | Verified structurally: `name = None` (`:2163`) with **nothing** between it and `try:` (`:2164`); `mkstemp` the `try`'s first statement (`:2165-2166`); `if name is not None:` (`:2211`) with the unlink block re-indented under it; `_record_generated()` (`:2216`) textually after the whole statement. No third statement is present anywhere in the tail. | ✅ |
| **C-13 true enumeration of what sits outside the `try`** | I-2's "the only statement" is correctly **not** restated; the load-bearing sentence is right; all four citations verified exactly | ⚠️ **partial — one member missing (CR-11)** |
| C-14 arm-4 docstring says all three things | `:611-629`: passes on a HEAD clone and is a regression control never a HEAD discriminator ✅; only control for the guarded region ✅ (over-broad — CR-12); reddens for both mutations with the exact exception each produces ✅. It would stop an editor deleting a green-on-HEAD arm: the first bullet answers the exact reason for deletion, and `Delete it and the control stops being one` closes it | ✅ |
| C-15 V-14's observable is the line, never a count | `_warn_degraded()` measured writing first; the assertion is on the `Could not write {path}` line, `str(CFG_PATH)` present, `.check.` absent | ✅ |
| C-17 `dirname` clause on arms 1-3, never a containment | `:654-655`, with the containment's vacuity spelled out in the docstring | ✅ |
| C-19 CR-6 restated in the form that holds, CR-7 recorded | `04_RATIONALE.md` §5 | ✅ (placement — CR-17) |
| C-20 H-10 travels as a residual | `## Residual text to carry forward` | ✅ carried |
| **C-21 re-run scope stated, not assumed** | Every V row is marked re-run or carried, and each carried row states its argument. I re-derived the argument independently: the delta is (a) a sentinel assignment, (b) a guard in the `finally`, (c) `mkstemp` re-indented into the `try`. For every V row except V-14, `CFG_PATH.parent` exists, so `mkstemp` succeeds, `name` is bound, `if name is not None:` is always true, and the `finally` executes round 1's block unchanged — behaviour is identical statement for statement. V-8 never enters the tail at all. **No row is coasting.** | ✅ |
| C-22 RS-8 travels as a note, no `01` round owed | PM-owned | ✅ |
| D-1 `_Verdict.stderr` | Upheld round 1 as an honest behavioural control; re-measured this round against the same clone | ✅ ruled (CR-7 is its stated cost) |
| D-2 +33 comment lines vs an estimate of +6 | Disclosed, not a constraint breach: K-9 / NFR-3 bound executable lines only, and C-8 forbids deleting a comment to reach a number. The eleven added this round carry the three facts an editor of this tail needs | ✅ correct disclosure |
| D-3 `capture_output=` coordinates | **Independently confirmed by me:** `bin/sc:2271` and `:3536` are the only two matches; the gate's `:2258` / `:3523` were round-1-relative. Writing the cited numbers would have reproduced CR-2 inside CR-2's own correction — the right call | ✅ |
| E-5 architecture diagram | `docs/architecture.md:52-80` draws 候选文档 → `sing-box check` → 拒绝 / 无法运行 / 通过 → `config.json` → 漂移记录; accurate to the shipped control flow | ✅ |

## Axis status
- **Standards-conformance: 6 open findings (CR-12, CR-13, CR-14, CR-15, CR-16, CR-17), worst = MINOR.** Both round-1 MAJORs on this axis (CR-2, CR-3) are closed; CR-2's coordinates I re-took myself. Nothing on this axis blocks.
- **Spec/design-fidelity: 2 open findings (CR-5 carried, CR-11 new), worst = MINOR.** The round-1 MAJOR (CR-1) is **closed** and verified as control flow, not as comments; every I-row, K-constraint and binding condition C-7…C-22 is discharged, with C-13 partial by one enumeration member.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-2 | CR-5: FR-5's path substitution and every AC-8 clause have no committed control; deleting `.replace(name, str(CFG_PATH))` leaves B.4 at 18/18. Re-establish by hand, or file the command-level fixture pool row `docs/dev-map.md:76` already names for the recovery arm. | `06_TEST_REPORT.md` |
| RES-3 | AC-12 / V-13 is **BLOCKED** and is never substituted for a run; the discharge recipe is the operator obligation quoted in `04_DEVELOPMENT.md`. | `06_TEST_REPORT.md`, then `07_DELIVERY.md` |
| RES-4 | RS-6, RS-7, H-10 (C-20) and C-11 / G-11 travel with their true window and their true cost, as the developer wrote them. | `07_DELIVERY.md` |
| RES-5 | Pool row: `_doctor_run()` has no timeout and now a caller on the write path — a hung `sing-box check` blocks `generate_config()` with a `0600` candidate on disk throughout. I-15 forbids the timeout here; the exposure moved rather than grew. Out of scope for T-30. | `docs/tasks.md` |
| RES-6 | **Round 2 was again performed by source reading only — no `Bash` was exposed to this stage in either round**, so `verify_all`, `check-sc-contracts.py`, `git diff` and the `_plain` / `_write_private` span hashes were **not** re-run here. What I did re-take by reading: the two `capture_output=` coordinates, every `bin/sc` and `check-sc-contracts.py` line number cited by `04_DEVELOPMENT.md`, the tail's control flow, the translation-key texts, and `baseline.json`. Every ✅ resting on execution (V-2…V-12, the four mutation probes, the +21 classification, the live-service witness) is the developer's, re-measured once by the PM (PASS 19 / WARN 0 / FAIL 0 / SKIP 1; B.4 18/18/18; `MainPID 2566751`, `NRestarts 0`). Stage 6 runs them independently. | `06_TEST_REPORT.md` |
| RES-7 | CR-10: `.harness/rejected-decisions.md:228` says "one of the **three** pre-existing `capture_output=` sites"; two remain, `bin/sc:2271` and `:3536` — the round-2 coordinates, not `:2258`/`:3523`. PM-owned file; travels with RS-1's decision records. | `.harness/rejected-decisions.md`, by the PM at delivery |
| RES-8 | CR-12: BC-11's *rendered-outcome-line* half has no committed control. Arm 4 pins `False` + no-raise only, so a build that catches the `mkstemp` `OSError` and returns `False` silently stays green while the docstring and `docs/dev-map.md:87` both claim the full invariant. V-14 is its only measurement, and V-14 is a one-off stage-4 run. | `06_TEST_REPORT.md` |
| RES-9 | CR-16: the accepted / cannot-run arms never compare the installed bytes to the composed document, so a build installing a *different* valid document, and one installing the candidate by `os.replace(name, CFG_PATH)` — the declined `candidate-installed-by-os-replace-instead-of-the-one-writer` — pass every committed clause. AC-1 rests on V-2 and K-2's "no second temp-then-replace construction" on grep. | `06_TEST_REPORT.md` |
| RES-10 | Three prose rows this change touches but must not fix in-task: `bin/sc:1991-1992`'s "one line earlier" adjacency (CR-14 — inside T-14's frozen span); `04_DEVELOPMENT.md`'s `:2157` span start (CR-15); and the inner-`else` fence recorded only in an archived stage rationale while the sentinel's fence is marked at the site (CR-17). | `docs/tasks.md` (T-32), by the PM |
| RES-11 | CR-13: `CHANGELOG.md:26`'s `标准输出与退出码均无任何改动` needs the qualifier its own paragraph establishes — the claim is false for a host with no usable `sing-box`, where HEAD tracebacked at exit 1 and this build completes and restarts. | `07_DELIVERY.md`, PM's call |

## Verdict
APPROVED WITH FOLLOW-UPS
