# 01 — Rationale · T-31 `suite-guarantee-boundaries`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

Routing follows `.harness/rules/70-doc-size.md`'s `## Stage-doc boundary rule`; every unit below
either explains, measures or compares, and no later stage has to satisfy it. Contract triggers that
point here: FR-2's measured disposition (see `## Open measurements`), FR-3 / Q-2 / Q-3 (the
enumeration argument), Q-4 / Q-5 (why a second language pass is vacuous), Q-7 (the fresh R-102
ruling's ground), NFR-2's element list.

## EVIDENCE — every row re-verified first-hand at HEAD `2a6b6e8`

**R-93, the denial.** `.harness/scripts/check-sc-contracts.py:107-109` is
`for name in dir(os): if name.startswith(("exec","spawn","fork","popen","posix_spawn","system"))`
— a prefix tuple over one module's namespace, exactly as filed. The shim is built at `:104-106`
(`shim.__dict__.update(os.__dict__)`, `shim.geteuid = lambda: 0`) and installed at `:111` for the
duration of `exec()` only, restored in the `finally` at `:120` and asserted restored at `:121-122`.

The **escape route** is visible without running anything. `:52-53` imports `subprocess` (and
`socket`, `http.client`, …) **before** the shim exists, deliberately — the comment at `:49-51`
says so — which means `subprocess`'s own module globals bind the **real** `os`. `subprocess.Popen`
then reaches a child through `_posixsubprocess.fork_exec` (a C extension that consults no module
attribute at all) or, on 3.8+, through the real `os.posix_spawn`. Neither passes through the
shimmed attribute lookup. `ctypes` is the second route and is *not* pre-imported, so it would bind
the shim as its `os` — and still reach `libc.system` / `libc.fork` without touching it.

So the header's own `:26` line — *"NOT covered: an import-time re-exec that avoids `os`
(subprocess, ctypes)"* — reads as **accurate** on the code. Three qualifications matter:

- It is **reachable only in combination**. `shim.geteuid` returns 0, so `bin/sc:125`'s
  `if os.geteuid() != 0:` is not taken at all; the capability denial is the *second* line of
  defence, for a guard reading a uid source the shim does not cover. An escape therefore needs
  both a moved predicate **and** a non-`os` process start. That compound is what AC-1 measures.
- The claim is **not repeated where the next test task will meet it**. `docs/dev-map.md:132-141` —
  the mandated recipe, the block every future fixture copies — says "Deny the capability too …
  that list is the whole guarantee" and names **no** uncovered route. That asymmetry, not the
  header, is the actual defect of this row.
- `:18-19`'s "on the shim, EVERY process-start name in `dir(os)` raises" is false off POSIX
  (`os.startfile`), which is R-93's own second half.

Aside, recorded and **not** requiring action here: `:15-16` and `docs/dev-map.md:135` offer
`os.geteuid() > 0` as an example of a guard that would escape the predicate defeat. With
`geteuid()` shimmed to 0, `0 > 0` is False and the branch is *not* taken, so that third example
looks wrong while `os.getuid()` / `os.getresuid()` are right. It is prose, it is not one of T-32's
eleven, and nothing this task changes falsifies it — flagged for whoever next opens the sentence.

**R-95, the zh blindness — and why the filed "obvious closure" does not work.** `fixture()` sets
`sc.LANG = "en"` (`:136`) and `bin/sc:132-133`'s `TRANSLATIONS` has a `zh` table only, so under
`en` `t()` is the identity on its key. Every sentence assertion is written as
`sc.t("<the English key>")` (e.g. `:252`, `:263`, `:265-266`, `:293`) — under `en` the assertion's
own literal **is** an independent oracle for the English wording, which is why T-28's sweep killed
those clauses. Under `zh`, both sides of the comparison go through the same table lookup, so a
destroyed `zh` value moves the expectation with the observation and the comparison holds. A second
`LANG="zh"` pass therefore adds runs, not discrimination — R-95's suggested closure is vacuous, and
that is the finding of this row rather than a scheduling decision.

What is left after that: (i) a *missing* `zh` entry, which `docs/dev-map.md:102-103` states renders
English **by design** ("the fallback, not a gap") — so a presence check would assert against the
project's own stated design; (ii) a *malformed* `zh` placeholder, already covered by
`zh_placeholders_are_a_subset_of_their_key` (`:342-362`, 0 offenders over the current table); (iii)
a *wrong wording*, for which the only possible oracle is a second copy of the Chinese literal
inside the suite — a change-detector, and the one thing T-28's design refused. Hence FR-5.

**R-96, the output layer.** Three grounds, all re-checkable and none needing a run: `io.StringIO`
presents no `.buffer`, so a capture exercises the unwrapped stream; the insight index's line 25
records that `main()` cannot be called twice in one process (the `io.TextIOWrapper` re-wrap closes
the previous `BufferedWriter`); and a locale criterion needs `PYTHONUTF8=0` in a **child**, i.e.
executing `bin/sc` as a program. What verifies T-25's contract today, checked rather than assumed:
`verify_all` B.5 is `restricted-network-regression.sh --self-check`, which derives blackout bases
and checks coverage (`:112-118`, `:142-148`) and asserts **nothing** about rendering — so naming
B.5 as the output layer's cover would have been a fresh false claim. The honest naming is review at
change time plus the out-of-process measurement a task touching the layer takes itself, which is
what T-25 did.

**R-104, the floor.** `verify_all.sh:83` reads `test_count` with `sed` and `:90` compares
`b4_passed < b4_floor`. Nothing anywhere reads a previous value; `git` is already used by A.1/A.2
(`:33`, `:44`), so the mechanism is present in the file. QA's measurement stands: 19 → FAIL,
18 → PASS, **17 → PASS**. The `.ps1` mirror needs nothing — its B.4 is an unconditional SKIP
(`verify_all.ps1:90-93`).

**R-102(a), the one writer.** `bin/sc:2165-2202`: `mkstemp` → `_write_private(Path(name), text)` →
one `_doctor_run` verdict → `_write_private(CFG_PATH, text)`. The declined shape and its full
argument are in `.harness/rejected-decisions.md:656-681`; T-30 QA measured 0 observable differences
across 13 cases. The point that makes a source-level clause cheap here was not in the row: the
suite **already** parses the subject's source — `every_file_read_and_write_names_utf8` at `:416-471`
takes `sc.generate_config.__code__.co_filename`, `ast.parse`s it and walks it, so `--source` drives
it. A clause for FR-7 is a walk over the same tree, not a new mechanism; rule 85's "reuse an
existing seam" points at adopting it, and its discriminating mutant is already built and named
(`mut-res9-os-replace`).

**R-102(b), corrected.** `bin/sc:2184-2188` states the divergence condition in its own comment: the
absorbed arm differs from HEAD only when *"a rejection whose own stderr write raises OSError"* is
caught by the inner `except OSError`, re-reported as cannot-validate, and falls through to the
install. That is a **behavioural** condition — a rejected-verdict arm with a raising `sys.stderr`
would reach it — so the row's "needs a structural control" is true of (a) and not established for
(b). Recorded as an expectation from reading, not a measurement; anyone acting on it owes the run.
The arm itself belongs to the coverage family this task does not open (R-101 asks for the same
`sys.stderr` capture, and T-30's `02` out-of-scope 9 declined a fifth arm).

**R-67 / R-22.** Honoured by declaring BC-4 up front: the floor control binds at the pre-commit
instant only, and cannot see a lowering that is already committed. Two other declared
non-discriminators: AC-3 and AC-8 are read-the-artifact criteria whose "wrong build" is a document,
not a program; they discriminate against today's text and against nothing else.

## Related historical work

- `docs/features/_archived/committed-test-suite/` (T-28) — built the artifact this task bounds;
  `07_DELIVERY.md`'s safety-spine section is the origin of the capability-vs-name argument.
- `docs/features/_archived/validate-before-baseline/` (T-30) — filed R-102 and R-104 and measured
  both; `.harness/rejected-decisions.md`'s `candidate-installed-by-os-replace-instead-of-the-one-writer`
  is its record.
- `docs/features/_archived/output-layer-contract/` (T-25) — the contract R-96 is about.
- `docs/features/_archived/state-file-contract-completion/` (T-29) — closed a row at zero code by
  ruling; its `01_RATIONALE.md` carries the R-67 trap in its own words.
- `docs/tasks.md` rows R-22, R-67, R-93 … R-97, R-101 … R-104; `docs/batches/closeout/BATCH_PLAN.md`
  §"How these four were derived" for T-31's provenance and for what is deliberately not built.

## Open measurements — owed downstream, outcomes NOT asserted here

**M-1 (owed by stage 2 before its design is fixed; re-taken by stage 6).** Does a process start
reached through the standard library's process API escape the load-time denial?

Probe shape, built so that an escape harms nothing (BC-7). In the scratch directory, a **new**
source file — never `bin/sc`, never the installed `sc`:

```python
import os, subprocess
if os.getuid() != 0:                       # a uid source the shim does not neutralise
    subprocess.call(["/usr/bin/touch", "<scratch>/escaped-subprocess"])
```

Run as a non-root user: `python3 .harness/scripts/check-sc-contracts.py --source <scratch>/probe.py`.
The marker's existence after the run is the escape; `LoadRefused` plus no marker is the denial
holding. A second variant substitutes `ctypes.CDLL(None).system(b"touch <scratch>/escaped-ctypes")`.

*Expectation, from reading and labelled as such:* the `subprocess` marker **will** exist —
`subprocess` is bound to the real `os` at `:52` and reaches `_posixsubprocess.fork_exec`, which
consults no attribute the shim owns. The `ctypes` variant is expected to escape for the same reason
one level lower. If the expectation holds, FR-2's branch (a) applies.

Candidate closures, for stage 2 to price rather than inherit — all strictly narrowing, all
restored in the same `finally` as the shim:
(1) replace `subprocess.Popen` on the real module for the duration of the load — one choke point
through which `run` / `call` / `check_output` / `check_call` / `getoutput` and both the `fork_exec`
and `posix_spawn` paths funnel; (2) install a shimmed `subprocess` in `sys.modules` — larger blast
radius, and the binding would outlive the load into the assertion phase, where the checker stub
lives (BC-6); (3) deny the real `os` module's process-start names too — does **not** close
`fork_exec`, so it buys a longer list and no capability, i.e. the defect repeating; (4)
`sys.addaudithook` — 3.8+, below the project's floor, already priced and rejected by T-28.
`ctypes` is expected to remain uncovered under every one of them: that residual is FR-1's job.

**M-2 (owed by stage 6).** Does any re-run of the committed assertions discriminate a
translation-only defect? Copy `bin/sc` to scratch, replace one `zh` value that a sentence assertion
names, run the suite against it — and again with a scratch copy of the suite whose `fixture()` sets
`LANG="zh"`. *Expectation:* green in both, because the expectation and the observation share the
lookup. AC-7 fails if the mutant dies, which would refute FR-5's sentence.

**M-3 (owed by stage 6).** Non-vacuity of the floor control: with the delivered tree, set
`test_count` to 17 while 18 is committed → the run must FAIL naming both numbers; restore → PASS;
raise past the delivered assertion count → the pre-existing passing-count clause FAILs. Plus BC-2's
case in a scratch copy with `.git` removed → no FAIL attributable to the control.

**M-4 (owed by stage 6, if FR-7's first branch is taken).** The clause FAILs against a subject
rebuilt in the `mut-res9-os-replace` shape and PASSes against the task-start `bin/sc`.

**M-5 (not owed; recorded).** R-102(b)'s divergence condition above — measurable with a rejected
verdict and a raising `sys.stderr`, by whoever opens that row.

## Candidate answers that lost

- **Q-2, add `os.startfile`.** It is the row's own "cheap fix" and it is one line. Rejected because
  B.4 SKIPs on the only platform where the name exists, so the line changes no behaviour anywhere
  it runs, and it converts an honest boundary into a satisfied-looking sentence — the substitution
  T-28's CR-1 was rolled back for. T-26's R-48 precedent (narrow the claim, leave the probe
  byte-identical) is the shape that applies.
- **Q-3, the meta-assertion over `dir(os)`.** It needs a committed list of "known process-start
  names" to compare against, which is the same enumeration displaced by one level, and it reports
  green on exactly the day the risk it names materialises.
- **Q-4, the second language pass.** Lost on the oracle argument above; it also costs a run of every
  assertion, which is the largest cost in the row for the least discrimination.
- **Q-5, "every asserted sentence has a `zh` entry".** Cheap and non-vacuous, but it asserts the
  negation of a stated design rule; a check that contradicts the design is worse than no check.
- **Q-6, a child-process runner for the output layer.** Refused under the safety spine; the
  exchange is the worst available — the suite's whole guarantee for the one contract it cannot see.
- **Q-7, leave R-102(a) to the decision record.** Defensible and it is the status quo; it lost on
  two facts, the parsing seam already existing in the suite and the mutant already existing as a
  named build. If the gate finds the clause pins spelling rather than ownership, this candidate
  wins and FR-7's second branch applies.
- **A "boundaries" section, or a new document, collecting all five statements.** Rejected: a reader
  meets the guarantee at the header and at the recipe, and a third home is where a claim goes stale
  — the same shape as the two documents that already give two counts for one set (R-94).

## NFR-2's derivation

Element list, priced from the artifacts as they stand: floor monotonicity control in
`verify_all.sh` — read the committed value, compare, compose the failure detail — **8–12**;
load-time route denial plus its restoration and the assertion that it was restored — **3–6**;
FR-7's clause plus its registry row and docstring-carried evidence line — **10–18**; the floor edit
— **2**. Sum 23–38, cap **40**. Recent bar: T-30 **+21** net executable lines, T-27 **8** added and a
designed table deleted. Prose lines in the claim surface are outside the cap and are expected to
exceed the executable count — which is the intended shape of this task, not an overrun.

## Glossary note

`CONTEXT.md` gains **claim surface** (the set of guarantee-shaped sentences a maintainer meets:
the contract suite's header, the fixture-loader recipe block, the assertion floor's `notes`). It is
this document's one coined term; `contract suite` and `assertion floor` are already canonical there
and are used as written.
