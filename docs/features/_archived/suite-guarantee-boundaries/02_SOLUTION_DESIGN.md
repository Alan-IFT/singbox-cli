# 02 — Solution Design · T-31 `suite-guarantee-boundaries`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

Triggers that point at `02_RATIONALE.md`: M-1's readings and the pricing of stage 1's four candidate
closures (`## Why the subprocess choke point and not a wider enumeration`), the reuse audit, the
risk table, the FR-7 ruling's ground, the NFR-2 re-derivation, and the smaller alternative rejected
for each element.

## Architecture summary

1. **What changes** — three artifacts gain content: `load()` in the contract suite gains one
   choke-point denial (`subprocess.Popen`) for the duration of the exec; the suite gains one
   source-level assertion bounded to `generate_config()`; `verify_all.sh` gains one step (B.6)
   comparing the assertion floor against its own last-committed value. Everything else this task
   closes is a **sentence** on the claim surface, at zero executable lines.
2. **What does not change** — `bin/sc` (FR-9), the `os` name enumeration (FR-3: no name is added),
   the `.ps1` mirror, B.3/B.5, the recipe's copyable code block, and every assertion already
   committed (FR-8).
3. **Where the seam is** — the denial's seam is `load()`'s single `try/finally`: everything it
   displaces is displaced there and restored there, so the assertion phase (where a legitimate
   process-API-shaped stub lives, BC-6) is reached with the real module state. The floor's seam is
   `verify_all`, never the suite (Q-9). The one-writer seam is the suite's **existing** source
   parse, driven by the same `--source` parameter.

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| E-1 | `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` | edit | `load()` gains the `subprocess.Popen` denial + its restoration + its restoration assertion (**+4 executable**); `_no_new_process`'s message is generalised so it does not assert a cause it cannot know (**0 net**) | dev |
| E-2 | `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` | edit | new assertion `config_json_is_installed_by_the_one_writer` + its `TESTS` row (**+13 executable**, of which 1 is the registry row); defined count 18 → 19 | dev |
| E-3 | `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` | edit | module header (prose only): the denial's two halves, the POSIX scope, the uncovered routes, and one `WHAT THESE ASSERTIONS DO NOT REACH` block carrying FR-5 / FR-6 / FR-7's residuals | dev |
| E-4 | `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` | edit | `floor_of()` (one definition of "how the floor is read", replacing the inline `sed` at `:83`) + new step **B.6** (**+10 executable net**) | dev |
| E-5 | `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json` | edit | `test_count` 18 → 19, `passing_count` 18 → 19, `notes` gains B.6's clause and BC-4's declared blind spot | dev |
| E-6 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | fixture-loader recipe block (prose only): the same denial statement, the same uncovered routes, and the FR-5 / FR-6 / FR-7 boundary sentences | dev |
| E-7 | `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` | edit | amend `candidate-installed-by-os-replace-instead-of-the-one-writer` (its "until then this record **is** the enforcement" is falsified by E-2); append one record for the declined wider-enumeration closures | dev |
| E-8 | `/home/alan/Programs/singbox-cli/docs/tasks.md` | edit | **PM at stage 7 only** — R-93 / R-95 / R-96 / R-102(a) / R-104 dispositions, and the one new row from `## Residuals travelling` | pm |

No other file is touched. No new file, directory, dependency or framework (AC-13).

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `check-sc-contracts.py` `load(src)` | unchanged signature, returns the loaded module | For the duration of `exec()`, a process can be started neither through the loaded module's own `os` (the shim's POSIX name enumeration, unchanged) nor through `subprocess`'s public API (`Popen` replaced on the real module object). Both displacements are undone in the **one** existing `finally`; if either is still displaced afterwards, `LoadRefused` is raised and the run ends non-zero. |
| I-2 | `check-sc-contracts.py` `_no_new_process(*args, **kwargs)` | unchanged signature, raises `LoadRefused` | Its message names **what was attempted** (a process start or replacement during load, with the first argument) and, as a possibility rather than a fact, the two causes: an elevate guard reading a uid source the `geteuid` shim does not cover, **or** a process API this load denies. It asserts no cause it cannot know. |
| I-3 | `check-sc-contracts.py` `config_json_is_installed_by_the_one_writer(sc)` | `(module) -> str` evidence, raises `AssertionError`; module-level `def` placed immediately after `every_file_read_and_write_names_utf8` | Parses `sc.generate_config.__code__.co_filename` (so `--source` drives it), finds the **single** `FunctionDef` named `generate_config`, and requires at least one `Call` inside it whose callee is the bare name `_write_private` and whose first positional argument is the bare name `CFG_PATH`. It reads no statement order and no other spelling; a reshaped `generate_config()` that still installs through that call passes (BC-8). |
| I-4 | `check-sc-contracts.py` `TESTS` | data tuple; the new name is appended **after** `every_file_read_and_write_names_utf8` | `len(TESTS)` is the "defined" count and equals `baseline.json`'s `test_count` (19) in the same commit. Order is run order and `--list` order, so two runs stay byte-identical. |
| I-5 | `verify_all.sh` `floor_of()` | shell function, **stdin → stdout**: the digits of `test_count`, empty when absent or non-numeric | The one definition of how a floor is read. B.4's current-floor read and B.6's committed-floor read call it; a second spelling of that `sed` is the defect this removes. Defined **inside** the `HARNESS:B-CUSTOM` markers. |
| I-6 | `verify_all.sh` step `B.6` | `step "B.6" "<name naming the floor and its last commit>" <STATUS> [detail]`, placed after B.5 and inside the `HARNESS:B-CUSTOM` markers | Compares `.harness/scripts/baseline.json`'s current `test_count` against `git show HEAD:.harness/scripts/baseline.json`'s. lower → **FAIL**, detail naming **both numbers and the file**; equal or higher → **PASS**; either value unreadable → **SKIP** plus one printed line stating the comparison was not performed and why. It never reads the suite's output and never runs the suite. |
| I-7 | `baseline.json` `notes` | JSON string value | States, in addition to what it states today: that `test_count` is compared by `verify_all` B.6 against its own last-committed value and that a lower value FAILs the run; and that a lowering already present in the last commit is invisible to that comparison (BC-4). |
| I-8 | `check-sc-contracts.py` module header, block `NEUTRALISATION -- A PREDICATE IS NOT A CAPABILITY` | prose block, existing heading kept | Carries K-6, K-7 and K-8 below. |
| I-9 | `check-sc-contracts.py` module header, new block `WHAT THESE ASSERTIONS DO NOT REACH` | prose block, new heading, placed after the `THE PATH INVARIANT` block | Carries K-9, K-10 and K-11 below, one clause each. |
| I-10 | `docs/dev-map.md` fixture-loader recipe block (`## Patterns to avoid`, the `Don't let a test harness import bin/sc …` bullet) | prose inside the existing bullet; the fenced code block is **not** edited | Carries the same claims as I-8 and I-9 — K-6 … K-11 — in the place every future test task meets them (Q-11). |

## Constraints

**K-1** — The developer replaces `subprocess.Popen` on the **real** `subprocess` module object (the one imported at `check-sc-contracts.py:52-53`) with `_no_new_process`, capturing the original first, immediately above the existing `sys.modules["os"] = shim`, with **no statement that can raise** between the capture, the replacement and the `try:` — the pattern `bin/sc:2161-2164` states in its own words.

**K-2** — The developer restores `subprocess.Popen` in the **same** `finally` that restores `sys.modules["os"]` (`check-sc-contracts.py:119-120`), and extends the existing post-`finally` leak check (`:121-122`) so that a still-displaced `Popen` raises `LoadRefused` (BC-5). No second `try`, no second `finally`.

**K-3** — The developer adds **no name** to the shim's process-start prefix tuple at `check-sc-contracts.py:108` and changes no character of it (FR-3, Q-2); `os.startfile` is not added.

**K-4** — The developer places the new assertion's `def` and its `TESTS` row so that no existing assertion's position in `TESTS` changes relative to its neighbours, and removes no assertion (FR-8).

**K-5** — The developer raises `baseline.json`'s `test_count` **and** `passing_count` to 19 in the **same commit** as E-2 (BC-10). Neither number is ever lowered to make a step pass; if the suite cannot reach 19 passing, the delivery is BLOCKED rather than re-floored.

**K-6** — The developer states, in **both** I-8 and I-10, that the load-time denial now has **two** halves: (a) on the shim, every process-start name in `dir(os)` **on POSIX** raises — the completeness claim is scoped to the platform where it holds, and `os.startfile` exists only where B.4 SKIPs; (b) for the duration of the exec, `subprocess.Popen` — the single choke point every documented `subprocess` entry point (`run` / `call` / `check_call` / `check_output` / `getoutput` / `getstatusoutput`) funnels through, on both the `posix_spawn` and the `fork_exec` dispatch — is replaced on the real module and restored in the same `finally`. Half (a) is a name enumeration and remains one; half (b) is not, and the text must not describe it as one.

**K-7** — The developer states, in both I-8 and I-10, that half (b) closes a **measured** hole rather than a theoretical one, in at most two lines: before this task, a subject calling `subprocess.call` / `Popen().wait()` / `subprocess.run` or `ctypes.CDLL(None).system(...)` from its import **started a process and left its marker** on CPython 3.12.3, while the `os.posix_spawn` control was refused.

**K-8** — The developer names, in both I-8 and I-10, the routes that remain open, and names them as open: **(i)** a call that reaches the C level without passing through `os` or `subprocess.Popen` — `ctypes` (`CDLL(None).system` / `fork` / `execv`) and a direct `_posixsubprocess.fork_exec`; **(ii)** a process-start name a future CPython adds to `os` that no prefix in the tuple matches; **(iii)** any module added to the pre-import line at `:52-53`, which by construction binds the **real** `os` — today `subprocess` is the only one of them that can start a process and its choke point is denied, so a future addition to that line must be priced the same way before it is made.

**K-9** — The developer states, in both I-8 and I-10, that the suite's sentence assertions pin the **English key spelling** of each sentence they name; that a translation-only wording regression is outside their reach; and that re-running the same assertions under another language cannot change this, because the expected value and the observed value are produced by the same `t()` lookup. The statement includes that no second-language pass exists and none is wanted (Q-4). No `LANG="zh"` pass, no translation-presence check (Q-5), is added.

**K-10** — The developer states, in both I-8 and I-10, that T-25's output-layer contract is outside the reach of any assertion in this suite; that no committed artifact runs `bin/sc` as a program or starts a child process; and that what verifies that contract is review at change time plus an out-of-process measurement taken by the task that changes the output layer — **not** `verify_all` B.5, which asserts nothing about rendering.

**K-11** — The developer states, in both I-8 and I-10, that the one-writer invariant is enforced by I-3 **bounded to `generate_config()`**, and names its two residuals: a *second* installer added **alongside** a surviving `_write_private(CFG_PATH, …)` call is not caught, and moving the install into a helper that `generate_config()` calls reddens the clause — at which point the clause is re-aimed at the new owner rather than deleted.

**K-12** — The developer leaves every other sentence in the recipe block byte-identical (BC-12), including the R-77 / R-78 / R-84 clauses and the fenced code block at `docs/dev-map.md:142-152`. Exactly two existing sentences are falsified by this change and are corrected in place: `docs/dev-map.md:137-140`'s "**every process-start name in `dir(os)`** must raise" (now scoped to POSIX and joined by half (b)) and its "that list is the whole guarantee" (now false).

**K-13** — The developer adds `floor_of()` and step B.6 **inside** the `>>> HARNESS:B-CUSTOM:BEGIN … END <<<` markers (`verify_all.sh:48`, `:99`), so `/harness-upgrade` preserves them; B.6 sits after B.5.

**K-14** — The developer writes B.6's unreadable-history branch to cover all four BC-2 cases with one condition (no `.git`, no `git` binary, the file absent at `HEAD`, a non-numeric `test_count` there): each yields an empty `floor_of` result, and the branch is **SKIP** plus one printed line naming that the comparison was not performed. B.6 never FAILs for an unreadable history and never runs the suite.

**K-15** — The developer touches neither `.harness/scripts/verify_all.ps1` nor `verify_all.sh`'s B.3 and B.5. B.6's own comment states that the mirror has no counterpart step, so on Windows neither the floor nor its monotonicity is checked at all — the mirror's B.4 is an unconditional SKIP (`verify_all.ps1:90-93`).

**K-16** — The developer amends `.harness/rejected-decisions.md`'s `candidate-installed-by-os-replace-instead-of-the-one-writer` record where E-2 falsifies it ("only a structural control … can, and adding one needs a ruling" → the ruling is T-31's and the clause is committed; "until then this record **is** the enforcement" → no longer true), leaving the measured 13-case finding and the coverage argument byte-identical, and appends **one** new record for the closures declined here (per `## Why the subprocess choke point and not a wider enumeration` in `02_RATIONALE.md`).

**K-17** — The developer keeps the suite at mode `0755`, Python 3.6 syntax, standard library only, and adds no import to `check-sc-contracts.py` (`ast`, `subprocess` and `os` are already imported).

**K-18** — The developer never lowers `baseline.json`'s floor, never edits `bin/sc`, never edits `.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md`, `archive-task.sh:109-136` or `guard-rm.sh`, and writes nothing under `/etc/sing-box` or `/var/lib/sing-box`.

## Frozen set

| path | why frozen |
|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | FR-9; AC-10 pins its task-start `sha256`. This task changes what is claimed and checked, never what is checked. |
| `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.ps1` | Out of scope 10: the mirror's B.4 stays SKIP and no step is added there. |
| `verify_all.sh` steps B.3 and B.5 | Out of scope 7: the standing SKIP is not repurposed; T-07's self-check is not widened. |
| `check-sc-contracts.py:108` (the prefix tuple) | FR-3 / K-3: a name added there buys a truer-looking sentence and no capability. |
| `docs/dev-map.md:142-152` (the recipe's fenced code) | The copyable T-13 recipe; the denial has always lived in the prose beside it, and splitting it across both is how the two drift. |
| `.harness/scripts/archive-task.sh:109-136`, `.harness/scripts/guard-rm.sh` | R-89 / R-90 / R-92 blocked on the owner's R-87 decision; R-86 — T-27's ruling stands. |
| `.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md` | Project red lines. |
| The eleven T-32-owned sentences (R-63, R-74, R-77 … R-85, R-91, R-94) | BC-12, including inside blocks this task edits. |
| `.harness/rules/50-singbox-cli.md` | Its "14 contract assertions" (`:29-30`) is already stale at 18 and this change does not falsify it further; it belongs to R-94's owner, not here. |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | E-1 | None. Strictly narrowing: the only behaviour it can add is a refusal. | Revert the four lines; the denial's absence is the task-start state, which the header then over-claims — so E-3/E-6 must be reverted with it. |
| 2 | E-2 | E-1 applied, so the new assertion runs under the widened denial. Suite reports `19 defined, 19 run, 19 passed` against the task-start `bin/sc`. | Revert the assertion **and** E-5's floor raise together; never revert one alone. |
| 3 | E-5 | Step 2 measured 19 passing. Committed **with** step 2 (BC-10). | Same commit, so a revert takes both. |
| 4 | E-3, E-6, E-7 | Steps 1–3 landed: every sentence describes the delivered artifact, not an intention. | Prose revert; no behaviour depends on it. |
| 5 | E-4 | Steps 1–4 in the working tree. B.6 must PASS at **both** instants: pre-commit (tree 19 vs `HEAD` 18 → higher → PASS, BC-3) and post-commit (19 vs 19 → equal → PASS). If B.6 FAILs on this delivery's own raise, the control is written as equality and is wrong. | Revert the step and `floor_of()`; B.4's inline `sed` returns. |
| 6 | E-8 | Delivery accepted; PM-owned at stage 7. | Document-only. |

Backwards compatibility: no data format, no CLI surface and no on-disk artifact of `sc` changes; `baseline.json` keeps its schema and only its numbers and `notes` move. No flag and no migration is needed. A tree that has E-5 without E-2 FAILs B.4 loudly (fewer passing than the floor), which is the intended failure direction; the reverse (E-2 without E-5) is silent and is why K-5 binds them to one commit.

## Out of scope

1. R-97, R-101, R-103 and end-to-end `sc config` redaction — coverage rows, not guarantee-boundary rows; they stay filed and are named as uncovered.
2. R-102(b) (the rejection arm's position) — stays filed with the corrected characterisation from `01_RATIONALE.md`.
3. Any `dir(os)` meta-assertion, any name added to the denial tuple, any second-language pass, any translation-presence check, any child-process runner, any coverage tracker, any `ast` linter beyond I-3's single bounded clause.
4. Closing the `ctypes` / `_posixsubprocess` routes: no mechanism inside the project's Python 3.6, stdlib-only, restore-in-a-`finally` envelope closes them, so they are written (K-8) rather than closed. `sys.addaudithook` is out for three reasons, the third of which is new here: 3.8+; already priced and rejected by T-28; and an audit hook **cannot be removed**, so it would survive into the assertion phase and violate BC-5 and BC-6 by construction.
5. Windows: `verify_all.ps1` gains nothing, and no claim is made about what is checked there (K-15).
6. `.harness/rules/50-singbox-cli.md`'s stale assertion count, and `01_RATIONALE.md`'s note that `os.geteuid() > 0` is a wrong example in two prose sentences — neither is falsified by this change.

## Verification plan

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | Re-take M-1 verbatim on the delivered tree: the four escape variants plus the `os.posix_spawn` control, scratch subject only (BC-7) | every `subprocess` variant now ends `LoadRefused … during load`, `os restored True`, `19 defined, 0 run, 0 passed`, exit 2, **no marker**; the `ctypes` variant still leaves its marker and is named in both documents; the control unchanged | AC-1, AC-2 |
| V-2 | Read `check-sc-contracts.py`'s header and `docs/dev-map.md`'s recipe block against the delivered denial | no sentence claims coverage the artifact lacks; the `dir(os)` completeness claim is scoped to POSIX; all three residuals of K-8 are named in **both** documents | AC-3 |
| V-3 | In a scratch clone with 19 committed: set `test_count` to 18, run `verify_all` | B.6 **FAIL** naming 18, 19 and `.harness/scripts/baseline.json`; B.4 unaffected. Restore → PASS | AC-4 |
| V-4 | The delivery run itself, at both instants of sequence step 5 | B.6 PASS pre-commit (19 > 18) and post-commit (19 = 19) | AC-5, AC-11 |
| V-5 | Scratch copy with `.git` removed, `verify_all` run | B.6 **SKIP** with the printed "comparison not performed" line; no FAIL attributable to it | AC-6 |
| V-6 | M-2: mutate one `zh` value a sentence assertion names, run the committed suite against the mutant, then again with a scratch suite whose `fixture()` sets `LANG="zh"` | green in both; if the mutant dies, K-9's sentence is false and the delivery is blocked | AC-7 |
| V-7 | `git diff` of the committed change, plus a read of both claim-surface documents | no committed artifact executes `bin/sc` or starts a child process; K-10's sentence names review + out-of-process measurement | AC-8 |
| V-8 | M-4: drive `--source` at a scratch subject rebuilt in the `mut-res9-os-replace` shape, and at the task-start `bin/sc` | the new assertion FAILs on the mutant naming the absent `_write_private(CFG_PATH, …)` call, PASSes on the task-start source | AC-9 |
| V-9 | `sha256sum bin/sc` at stage 2 and at delivery | byte-identical | AC-10 |
| V-10 | `bash .harness/scripts/verify_all.sh` | PASS, FAIL 0, WARN 0, B.3 the only SKIP; tally stated as **PASS 20 / WARN 0 / FAIL 0 / SKIP 1** against the task-start `PASS 19 / WARN 0 / FAIL 0 / SKIP 1` (the delta is B.6) | AC-11 |
| V-11 | NFR-1: re-take T-28's syscall reading over a B.4 run | `execve` 1, `clone` 0; if the tracer is unavailable, BLOCKED and filed, never substituted | NFR-1 |
| V-12 | Report BC-4's declared case, and any criterion that cannot discriminate, as NOT-DISCRIMINATING | `06_TEST_REPORT.md` names BC-4 (an already-committed lowering is invisible) and AC-3 / AC-8 as read-the-artifact criteria | AC-12 |
| V-13 | `git diff --stat` plus this document's element list | ≈30 net executable lines across the two scripts, within NFR-2's 40; no new file, directory or dependency | AC-13 |
| V-14 | Any criterion needing root | reported BLOCKED and filed as a row, never substituted with a weaker run | AC-14, BC-9 |
| V-15 | `systemctl show -p MainPID -p NRestarts -p ActiveEnterTimestamp sing-box` and the entries of `/etc/sing-box`, at every stage boundary | unchanged | NFR-5 |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | `ctypes` and a direct `_posixsubprocess.fork_exec` still start a process from a subject's import; the denial is not total and the claim surface says so. Re-measured, not asserted. | stage 6 (`06_TEST_REPORT.md`, as V-1's second half) and `docs/tasks.md` R-93's disposition |
| RES-2 | A process-start name a future CPython adds to `os` re-opens the enumeration silently — unchanged by this task, and Q-3's meta-assertion stays declined. | `docs/tasks.md` R-93 (stays open, narrowed) |
| RES-3 | Adding a module to `check-sc-contracts.py:52-53` binds the **real** `os` for it; the next task that adds one owes the same pricing K-6 gave `subprocess`. | the header (K-8 iii) and `docs/tasks.md` as a filed row |
| RES-4 | I-3 does not catch a second installer added alongside the surviving `_write_private(CFG_PATH, …)` call, and reddens on a reshape that moves the install into a helper. | the assertion's docstring, the claim surface (K-11), and `docs/tasks.md` R-102(a)'s disposition |
| RES-5 | `verify_all.ps1` has no B.6 and its B.4 SKIPs, so on Windows neither the floor nor its monotonicity is ever checked. | `docs/tasks.md` — **new row** at stage 7, owner "next task touching the mirror" |
| RES-6 | `.harness/rules/50-singbox-cli.md:29-30` says "14 contract assertions" and is stale at 19 after this task; it is R-94's, not this task's. | `docs/tasks.md` R-94 |
| RES-7 | BC-4: the floor control cannot see a lowering that is already committed. Declared, not discovered. | stage 6 (V-12) and `baseline.json`'s `notes` (I-7) |

## Partition assignment

This project has no `.harness/agents/dev-*.md`, so single-Developer mode. One developer, one commit for E-1 … E-7; E-8 is the PM's at stage 7.

| File | Partition | New / Edit | Dependency |
|---|---|---|---|
| `.harness/scripts/check-sc-contracts.py` | dev | edit (E-1, E-2, E-3) | — |
| `.harness/scripts/baseline.json` | dev | edit (E-5) | depends on E-2 (the count it records) |
| `docs/dev-map.md` | dev | edit (E-6) | depends on E-1, E-2 (it describes them) |
| `.harness/rejected-decisions.md` | dev | edit (E-7) | depends on E-2 |
| `.harness/scripts/verify_all.sh` | dev | edit (E-4) | depends on E-5 (its subject) |
| `docs/tasks.md` | pm | edit (E-8) | after delivery |

## Dispatch order

1. dev — E-1 → E-2 → E-5 → E-3/E-6/E-7 → E-4, in the `## Migration & edit sequence` order, one commit.
2. pm — E-8 at stage 7.

## Parallelism

None — a single developer and a single commit; the ordering above is a correctness constraint (E-5 must be measured from E-2, and E-4 must be exercised against E-5's raise at both commit instants).

## Verdict

READY
