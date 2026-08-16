# 03 — Rationale · T-31 `suite-guarantee-boundaries`

> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

Routing follows `.harness/rules/70-doc-size.md`'s `## Stage-doc boundary rule`: nothing below has to
be satisfied by a later stage — it explains how each finding was reached, prices what the contract
portion binds, and records what was checked and found good.

## How G-1 was reached, and why it is not a rollback

The design's whole argument for E-1 rests on one fact stage 1 established by reading: modules
imported at `check-sc-contracts.py:52-53` bind the **real** `os`, because they were imported before
the shim existed. That fact has a second consequence neither stage followed: a module object that
binds the real `os` **exposes** it as an ordinary attribute. Two reads settle it —
`/usr/lib/python3.12/subprocess.py:47` (`import os`) and `/usr/lib/python3.12/posixpath.py:25`
(`import os`). The second is the sharper one: `load()` builds the shim with
`shim.__dict__.update(os.__dict__)` (`:105`), so `shim.path` **is** the real `posixpath` module, and
`os.path.os` inside the subject is the real `os` module with none of its process-start names
displaced. The denial is therefore one attribute hop deep in its own copy.

This is not a live safety hole and the review does not treat it as one. No plausible `bin/sc`
elevate guard is spelled `os.path.os.execvp`; the incident this project actually had (R-78) is a
guard rewritten in an ordinary way, which is exactly why E-1's four lines against `subprocess` are
worth their price. It is a **claim** hole, and this task's subject is claims. A residual list that
names `ctypes` and `_posixsubprocess.fork_exec` — the two hardest routes — while omitting the
easiest one reads as complete and is not, which is the defect the task exists to stop, reproduced in
the artifact meant to stop it.

FR-2 branch (b) explicitly permits closing this with a sentence, and rule 85's "less is more"
prefers the sentence to the ~6 further lines candidate (3) would cost. So the gate demands no code
for it: C-1 and C-3 are text, C-2 is a measurement. That is also why this is a condition and not a
rollback — the code plan (E-1, E-2, E-4, E-5) survives G-1 unchanged, and every remedy lands in
sentences the developer writes from a constraint list anyway. Sending the design back to re-emit
itself with two added clauses would buy a round trip and nothing else.

The gate did **not** run the probe: it holds no shell. C-2 states it exactly, and the contract's
clause is written to follow the reading rather than to assert it. The expectation, labelled as an
expectation: both variants leave their marker, before and after E-1, because neither touches the
shim's names nor `subprocess.Popen`.

## Why G-2 matters more than a rationale nit

Stage 2 rejected candidate (3) partly on "it would also mutate a module the harness itself uses, for
no coverage candidate (1) does not already give". The first half is true of the chosen candidate too
— `subprocess.Popen` is replaced on the real module object — so it discriminates nothing; the second
half is now false. What survives, and survives well, is the dispatch argument: `_USE_POSIX_SPAWN`
decides only what `Popen._execute_child` does, so denying real-`os` names stops today's
`subprocess.run` by accident and stops nothing the day `preexec_fn` or a future CPython routes
through `_posixsubprocess.fork_exec`. That argument alone still carries the decision.

The reason this is MAJOR rather than MINOR is destination: K-16 sends the comparison into
`.harness/rejected-decisions.md`, where it becomes the project's permanent answer to "why was the
wider denial declined". A record that under-states a declined option's coverage is how the next task
re-derives the wrong conclusion cheaply — the failure mode R-98 and R-106 already document for prose
in this repo.

## The R-22 sweep across AC-1 … AC-14, in full

Asked of each: which wrong build does it fail on?

- **AC-1** — a design that asserts M-1's outcome without a run. Discriminates; `02_RATIONALE.md`'s
  reading table with exit codes and marker states is the artifact.
- **AC-2** — a build that neither refuses the route nor names it. Discriminates today's tree, but it
  is a disjunction whose branch (b) is satisfiable by any wording, so it cannot alone catch a
  delivery that quietly drops E-1. V-1's stated observables (`LoadRefused`, no marker, exit 2,
  `19 defined, 0 run, 0 passed`) are what make it bite; QA should read the pair together.
- **AC-3, AC-8** — read-the-artifact criteria, already declared non-discriminating in
  `01_RATIONALE.md`. That declaration is correct. AC-8 additionally over-claims (G-3).
- **AC-4** — catches an absent control and a control that reads the wrong file. It does **not**
  catch a control written as equality; AC-5 is what does, and only pre-commit (G-9).
- **AC-6** — catches a control that FAILs on absent history. One test case (`.git` removed) covers
  all four BC-2 shapes only because K-14 folds them into a single empty-`floor_of` branch; if the
  developer splits that branch, three of the four go untested and QA must say so.
- **AC-7** — genuinely discriminating, and unusually so: it can **refute** the boundary sentence it
  guards. The ground holds on reading — every sentence assertion is written `sc.t("<English key>")`
  (e.g. `:488`), so under `zh` the expectation and the observation come from one lookup — and M-2
  measures it.
- **AC-9** — discriminates the built mutant. Its blind spot is the one C-7 makes explicit.
- **AC-10** — a digest. Discriminates any `bin/sc` edit.
- **AC-11** — catches a new FAIL, a new WARN or a second SKIP. Note the tally arithmetic checks out:
  the file defines 20 steps today (A×2, B×5, E×7, F×6) with B.3 the only SKIP, hence PASS 19; B.6
  makes it 21 steps and PASS 20, which is what V-10 states.
- **AC-12, AC-14** — meta-criteria over the report. AC-14 is vacuous for this task: nothing here
  needs root, since BC-1's euid-0 refusal is the one path that would and it is out of scope. That is
  fine — it is a standing policy criterion, not a gap.
- **AC-13** — discriminates a new file or dependency at a glance; its executable-line half is the
  soft one (G-8, C-10).

Two non-discriminating cases beyond stage 1's declared three are therefore reported now rather than
at stage 6: **E-1's leak-check clause** (G-6) and **AC-5 read post-commit only** (G-9). BC-4's own
declaration was re-derived and is right: B.6 compares tree against `HEAD`, so a lowering already in
`HEAD` compares equal and passes, and the control binds at the pre-commit instant — which is the
instant the delivery policy requires a passing run, so the blind spot is real but not load-bearing.

## Rule 85, priced element by element

- **E-1 (4 lines).** Smaller alternative: zero lines and a sentence, which stage 1 admitted through
  FR-2(b) and AC-2. It loses on a fact about the subject, checked here: `bin/sc` imports
  `subprocess` (`:14`) and uses it at `:2157`, `:2175`, `:3473`; it imports `ctypes` nowhere. The
  route the subject can plausibly take is the one the four lines close. Verified that the choke
  point is real rather than a spelling: `subprocess.call` (`:389`) and `run` (`:548`) both enter
  `with Popen(...)` through the module global, and `check_call`/`check_output`/`getoutput`/
  `getstatusoutput` reach one of those two. Smaller still would be 3 lines (drop the leak clause);
  C-8 leaves that open, since BC-5's "restoration asserted" is satisfied vacuously either way.
- **E-2 (13 lines).** The largest element and the one rule 85 puts the burden on. Kept, on four
  checked grounds: insight-index line 27 measured that no byte- or mode-comparing assertion can pin
  the property (0 differences over 13 cases); the parsing seam exists and is driven by the same
  `--source` (`:416-471`); the discriminating mutant exists as a described build; and R-102's own
  row asks for a **ruling**, which zero code cannot give. Stage 2's ground 3 ("no keyword spelling")
  is partly refuted — see G-5 — but its core survives: the subject is which callee owns the write,
  not statement order, which is what T-30's K-11 declined. Had the clause needed a list of
  installer spellings to work, the ruling would have gone the other way; the positive-only shape is
  why it does not.
- **E-4 (12-15 lines).** `floor_of()` is the part that makes this smaller rather than larger and it
  passes rule 85's own test for a justified refactor: the future edit it prevents is named (the day
  `test_count`'s spelling changes and only one of two readers is updated). New step over extended
  B.4 is correct for a reason confirmed at the source: `step()` prints detail only on FAIL
  (`verify_all.sh:19`), so a not-performed comparison has nowhere honest to be said inside a PASSing
  B.4.
- **E-3, E-6, E-7 (0 executable).** Five of six rows close on sentences. That is the shape the task
  was set to produce, and it is why the delivery will be prose-heavy with a small diff — expected,
  not an overrun.

## NFR-2's re-derivation, in detail

| element | design | gate | why the gate's number differs |
|---|---|---|---|
| load-time denial | 4 | 4 | capture, replace, restore, one leak clause — confirmed against `:110-122`. |
| one-writer clause + registry row | 13 | 13 | 12 in the function (source read, parse, locate the single `FunctionDef`, its guard, the call comprehension, its guard, evidence return) + 1 `TESTS` row. |
| `floor_of()` + B.6 | 10 | 12-15 | `verify_all.sh:83` is **rewritten**, not deleted, so `floor_of()` is +3 net rather than a wash; B.6 needs two reads, a `.git`/`git` guard, three `step` calls and BC-2's `echo`. |
| floor edit | 2 | 2 | `test_count`, `passing_count`. |
| **total** | ≈29 | **31-34** | Cap 40 upheld unamended (R-61 satisfied by re-deriving the list, not by moving the number). |

## Verified good — checked first-hand and found accurate

- Every file, line span and symbol the design cites exists as cited. Spot-verified: `:52-53`'s
  pre-import line, `:104-111`'s shim construction, `:112-122`'s single `try/finally` plus leak
  check, `:416-471`'s parse seam, `:551-573`'s `_CheckerStub`, `:642-647`'s stub bind/restore,
  `:690-701`'s 18-entry `TESTS`, `verify_all.sh:13-22` / `:30-46` / `:79-98` / `:129`,
  `baseline.json`'s four numbers, `dev-map.md:132-141` (the two sentences K-12 corrects) and
  `:142-152` (the frozen fenced block), `bin/sc:125-126`, `:2057`, `:2170`, `:2202`,
  `rejected-decisions.md:656-681`.
- The design's claim that `bin/sc` performs no import-time `subprocess` call is confirmed: the only
  module-level occurrence of the name is the import at `bin/sc:14`, and the only module-level action
  is the elevate guard at `:125-126`, which the `geteuid` shim keeps untaken. The denial cannot
  refuse a legitimate load today.
- BC-6 holds structurally, not by care: the stub is bound to the loaded module's attribute after
  `load()` returns, so no ordering mistake in E-1 can reach it.
- The safety spine is not traded anywhere. E-1 is strictly narrowing (its only new behaviour is a
  refusal), E-2 reads a file, E-4 reads git history, E-5 raises two numbers. Nothing in the design
  can make a `verify_all` run elevate, and BC-11's refusal never has to fire — which is why the
  verdict is not `BLOCKED: NEEDS-HUMAN`.
- The insight index was queried for the design's load-bearing terms. Line 18 (the prefix-vs-
  enumeration finding), line 27 (the one-writer property's zero behavioural reach) and line 29
  (B.4's floor never compared against its own history) each **support** the design rather than
  contradict it; line 12 (`main()` cannot run twice in one process) independently supports R-96's
  disposition. No index entry contradicts an assumption of this design.
- Stage 1's Q-4 ground was re-derived rather than accepted: the assertions are written
  `sc.t("<English key>")`, so under `zh` both sides of every comparison move together and a second
  language pass adds runs without discrimination. FR-5 as a written boundary is the right call, and
  AC-7 can refute it if the ground is wrong — which is the correct shape for a boundary claim.
