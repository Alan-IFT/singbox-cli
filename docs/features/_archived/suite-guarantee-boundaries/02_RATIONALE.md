# 02 — Rationale · T-31 `suite-guarantee-boundaries`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

Routing follows `.harness/rules/70-doc-size.md`'s `## Stage-doc boundary rule`: nothing below has to
be satisfied, implemented or verified by a later stage — it explains, prices, measures or compares.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Parse the subject's source, driven by `--source` | `every_file_read_and_write_names_utf8` — takes `sc.generate_config.__code__.co_filename`, `ast.parse`s it, walks it | `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py:416-471` | **Reuse the seam** — the new clause is a second walk over the same kind of tree, driven by the same parameter. No new mechanism, no new import (`ast` is imported at `:39`). |
| Refuse a process start during load | `_no_new_process` + `LoadRefused` | `check-sc-contracts.py:69-76` | **Reuse as-is** — the `subprocess` denial binds the *same* callable; no second refusal type, no second message. |
| Undo what the load displaced | the single `try/finally` + the post-`finally` leak assertion | `check-sc-contracts.py:112-122` | **Reuse as-is** — the new restoration goes in that `finally`, the leak check gains one clause (BC-5). |
| Read `baseline.json`'s floor | the inline `sed` at B.4 | `.harness/scripts/verify_all.sh:83` | **Extract to `floor_of()`** — B.6 needs the same read of a different stream. Rule 85 test 2 (duplicated judgment): "how the floor is read" gets one home instead of two. |
| Read a value out of git history in `verify_all` | `git grep` (A.1) and `git ls-files` (A.2), each guarded on `.git` | `verify_all.sh:30-46` | **Reuse the pattern** — `git show HEAD:<path>` with stderr suppressed; no new tool, no new dependency. |
| Report a step's outcome | `step()` | `verify_all.sh:13-22` | **Reuse as-is** — B.6 is one more call; `step` prints detail only on FAIL, which is why BC-2's "not performed" line is an explicit `echo` beside a SKIP. |
| Record a declined approach | `.harness/rejected-decisions.md` | repo root `.harness/` | **Reuse** — one appended record, one amended record; no new memory file. |
| A place to state a boundary | the suite header + `docs/dev-map.md`'s recipe block | `check-sc-contracts.py:1-38`, `docs/dev-map.md:128-180` | **Reuse both** — stage 1's Q-11 already ruled a third home out; T-31 adds no `## Boundaries` section and no new document. |

Nothing in `docs/dev-map.md` or the suite already does the floor-monotonicity comparison or the
one-writer clause; both are new, and both are justified above by what they close (M-1's measurement,
and T-30's measured `mut-res9-os-replace`).

## AC-1's measurement — the readings this design is fixed on

Taken by an independent runner constrained to `01_RATIONALE.md`'s probe, scratch subject only, never
`bin/sc` (BC-7). Host: CPython **3.12.3**, `subprocess._USE_POSIX_SPAWN` **True**.

| variant | exit | marker | reading |
|---|---|---|---|
| `subprocess.call([...])` | 1 | **YES** | the subject's import ran to completion; a process started |
| `subprocess.Popen([...]).wait()` | 1 | **YES** | same |
| `subprocess.run([...])` | 1 | **YES** | same |
| `ctypes.CDLL(None).system(b"…")` | 1 | **YES** | same |
| `os.posix_spawn(...)` (**control**) | 2 | **NO** | `LoadRefused: … first argument: ('/usr/bin/touch',)`, `os restored True`, `18 defined, 0 run, 0 passed` |

The exit-1 runs are non-zero only because a scratch subject defines none of `sc`'s functions, so the
assertions `AttributeError` out — the process had already started, before any assertion ran. So
FR-2's branch (a) is available for the `subprocess` family and branch (b) is forced for `ctypes`.
The stage-1 expectation held; nothing here is re-derived from reading.

## Why the subprocess choke point and not a wider enumeration

**Chosen: candidate (1)** — replace `subprocess.Popen` on the real module for the duration of the
load. Four lines. Every documented entry point of the module (`run`, `call`, `check_call`,
`check_output`, `getoutput`, `getstatusoutput`, and `Popen` itself) funnels through that one class
attribute, and it does so **above** CPython's internal dispatch: `_USE_POSIX_SPAWN` decides only
what `Popen._execute_child` does *after* the denial has already raised. It is therefore a capability
choke point for that module, not a spelling.

- **(2) shim `subprocess` in `sys.modules`.** Rejected on BC-6 and on size. Any module the subject
  imports afterwards would bind the shim, and the binding outlives the load into the assertion phase
  where `_CheckerStub` legitimately supplies a `subprocess`-shaped object
  (`check-sc-contracts.py:551-573`). It costs more lines and buys nothing candidate (1) does not,
  because `subprocess` is pre-imported at `:52-53` and the subject's `import subprocess` returns the
  same module object either way.
- **(3) deny the real `os`'s process-start names too.** Rejected, and this is the ruling the brief
  asked for explicitly: with `_USE_POSIX_SPAWN` True it *would* stop today's `subprocess.run`,
  because `subprocess` reaches the real `os` module it bound at its own import. That is exactly what
  makes it wrong. It holds only for one CPython's internal dispatch choice — the moment
  `posix_spawn` is unusable (`preexec_fn`, some `close_fds` / `cwd` / `restore_signals`
  combinations, or a future CPython), `Popen` takes `_posixsubprocess.fork_exec`, which consults no
  module attribute at all, and the denial reports nothing. It is a longer name list standing in for
  a capability — the defect this task exists to stop — and it would also mutate a module the harness
  itself uses, for no coverage candidate (1) does not already give.
- **(4) `sys.addaudithook`.** Rejected on three grounds: 3.8+ against a 3.6 floor (NFR-3); already
  priced and rejected by T-28; and — the ground that is new here — an audit hook **cannot be
  removed**, so it cannot be restored in the `finally` (BC-5) and would necessarily reach the
  assertion phase (BC-6). Even if the floor moved, this candidate would still fail two boundary
  conditions.
- **(5), found here: `resource.setrlimit(RLIMIT_NPROC, (0, hard))` for the load.** A genuine
  capability closure one level below all of the above: it would stop `ctypes`' `fork`/`system` and
  `_posixsubprocess.fork_exec` as well. Rejected anyway. It does **not** stop process *replacement*
  (`ctypes…execv` replaces the image without creating a task), so K-8's residual sentence stays true
  either way — the extra mechanism shrinks a written residual without removing it. Against that it
  costs a second, process-global mechanism nobody in this project reasons about, whose failure mode
  is an `EAGAIN` surfacing as `BlockingIOError` rather than a named refusal, and whose restoration
  is a resource-limit round trip rather than an attribute assignment. Rule 85: take the smaller.
- **The smallest alternative of all — FR-2 branch (b), zero lines, one sentence.** AC-2 admits it,
  and it was live. It lost on one fact about the subject: `bin/sc` imports and uses `subprocess`
  throughout (`bin/sc:2157`, `:2175`, `:3473`, …) and imports `ctypes` nowhere and never will. The
  realistic shape of the incident this denial exists for — R-78, which *has* happened here — is an
  elevate guard rewritten as `subprocess.run(["sudo", …])`, not a `ctypes` call. Four lines close the
  route the subject can plausibly take; a sentence covers the route it cannot. That asymmetry, not
  the line count, is what the four lines buy.

**What the four lines do not buy, stated so stage 3 can test it:** they do not make the denial total,
they do not change any `os` name, and they do not discriminate a `bin/sc` that starts a process by
any other route. The claim surface is where that is said (K-8).

## The FR-7 ruling — adopted, with this task's own ground

Stage 1's Q-7 said "adopt unless the gate refutes the ground". This stage adopts it, and the ground
is re-derived rather than inherited:

1. **The property has zero behavioural reach.** T-30 stage 6 measured `mut-res9-os-replace` at 0
   observable differences over 13 cases with the suite green
   (`.harness/rejected-decisions.md:656-681`). No byte-, mode- or timing-comparing assertion can pin
   it. Either a structural clause exists or the invariant is held by memory. There is no third state.
2. **The seam already exists.** `every_file_read_and_write_names_utf8` already parses the subject's
   source, driven by `--source` (`check-sc-contracts.py:416-471`). The clause is a walk, not a
   mechanism — rule 85's "reuse an existing seam".
3. **T-30's `K-11` does not transfer, and the reason is testable.** `K-11` declined `ast` checks for
   statement *order*, whose satisfying set is a shape a legitimate refactor changes. This clause
   asserts *which callee owns the write*, which a legitimate refactor does **not** change: T-13's
   contract is literally "`_write_private()` is the sole writer". The clause names the invariant's
   own two nouns and nothing else — no order, no argument count, no keyword spelling, no
   surrounding block.
4. **Its discriminator is already built and named.** `mut-res9-os-replace` exists as a described
   shape, so M-4 is a re-build, not an invention.

**Why the clause is positive-only.** The exclusivity half — "and nothing *else* installs
`config.json`" — is not statically decidable, and the only implementable approximation is a list of
rename/replace/write spellings (`os.replace`, `os.rename`, `shutil.move`, `Path.replace`, …). That
is the same defect one level down: a spelling standing in for a capability, green on the day a new
spelling arrives. A negative clause was priced at ~3 extra lines and rejected on that ground; the
positive clause already kills the one measured mutant (which *deletes* the writer call), and what it
misses is written as RES-4 rather than approximated. This is the same ruling shape as Q-2 and Q-3,
applied to this task's own new code so the design does not do what it forbids the denial to do.

**Why bounded to `generate_config()`.** BC-8 requires it, and the wider alternative (search the
whole module for `_write_private(CFG_PATH, …)`) would survive a helper reshape at the cost of
passing when some unrelated function holds the call. The bound is the honest scope; its cost is
RES-4's second half, written in the assertion's own docstring so the maintainer who reshapes the
function meets the instruction to re-aim the clause.

## Where the floor control lives, and why a new step

Q-9 fixed the file (`verify_all`, never the suite). The remaining call was extend-B.4 vs new-step.

- **Extend B.4** — the smaller diff by two or three lines. Rejected on two grounds. It fuses two
  different judgments under one status: "the suite regressed" and "the floor was lowered" would both
  read as `[B.4] bin/sc contract assertions … FAIL`, and the second is not about the suite's
  assertions at all. And BC-2's "the comparison was not performed" has nowhere to be said inside a
  PASSing B.4, because `step()` prints its detail only on FAIL (`verify_all.sh:19`) — the only
  honest report of a not-performed comparison is a status of its own.
- **New step B.6** — chosen. It reports SKIP for BC-2 (which is already how A.1/A.2 report a missing
  `.git`, so a no-`.git` scratch run reads consistently), FAIL naming both numbers for BC-3, and
  PASS otherwise. The delivery run gains one PASS: `PASS 20 / WARN 0 / FAIL 0 / SKIP 1`.

`floor_of()` is the part that makes this *smaller* rather than larger: it removes the second copy of
the `sed` expression B.6 would otherwise need, so the two steps cannot disagree about what a floor
is. That is the one refactor here, and the future edit it prevents is the day `test_count`'s spelling
changes and only one of the two readers is updated.

**The mirror.** `verify_all.ps1`'s B.4 is an unconditional SKIP (`:90-93`) and out-of-scope 10
forbids a step there, so the mirror gains nothing. The drift is real and is handled by naming it
where it is created (K-15, a comment beside B.6) and filing it (RES-5) — not by a comment in a file
no gate reads, which would be a fresh unenforced claim in the one place this task is trying to stop
producing them.

## Risks and mitigations

| # | Risk | Mitigation |
|---|---|---|
| 1 | The `subprocess.Popen` denial leaks past the load and breaks assertion 18, which binds a `subprocess`-shaped stub. | Restored in the same `finally` as the shim (K-2) and asserted restored by the extended leak check; the stub binds `sc.subprocess`, a different object, and only after `load()` returns. V-10's full run is the observation. |
| 2 | The denial refuses a *legitimate* load. | Nothing in `bin/sc`'s import-time path calls `subprocess` — the elevate guard at `:125-126` is the only import-time action — and every stdlib module `bin/sc` imports is pre-imported at `:52-53` before the denial exists. If a future `bin/sc` legitimately starts a process at import, that is the event the denial is for. |
| 3 | The new assertion reddens on a legitimate refactor of `generate_config()`. | The clause names only `_write_private` and `CFG_PATH`, no order and no other spelling (BC-8). The one refactor that reddens it — moving the install into a helper — is written in the docstring with its remedy (re-aim, do not delete). RES-4. |
| 4 | The delivery's own floor raise trips the new control. | BC-3 makes higher a PASS; sequence step 5 requires B.6 to be exercised at both instants (19 vs `HEAD` 18, and 19 vs 19). A control written as equality fails V-4 and is the specific wrong build this row is looking for. |
| 5 | E-2 lands without E-5 (or the reverse) across two commits. | K-5 binds them to one commit; the E-5-without-E-2 direction FAILs B.4 loudly, and the silent direction is the one the constraint exists for. |
| 6 | The header and the recipe block drift apart again — the exact defect R-94 records for a different pair of documents. | Both are edited in the same edit (E-3/E-6) from one constraint list (K-6 … K-11), and V-2 reads them against each other rather than each on its own. |
| 7 | A future task adds a module to the `:52-53` pre-import line and silently re-opens a route. | K-8 (iii) makes that obligation part of the header's own text, beside the line that creates the hazard. |
| 8 | `git show HEAD:…` behaves unexpectedly (detached HEAD, a fresh repo with no commits, a worktree). | All of those produce an empty read, which K-14 routes to the SKIP branch — the control's failure mode is "not performed", never a false FAIL (BC-2). |

## NFR-2 — the cap, re-derived over this design's own element list

| element | stage 1's estimate | this design | delta and why |
|---|---|---|---|
| floor monotonicity control | 8–12 | **10** | `floor_of()` (1) + B.6's block (~9); the `sed` extraction is a net wash against `:83`. |
| load-time route denial | 3–6 | **4** | capture, replace, restore, one extended leak-check line. |
| source-level clause + registry row | 10–18 | **13** | 12 in the function + 1 `TESTS` row; the predicate is inlined rather than given a helper. |
| floor edit | 2 | **2** | `test_count`, `passing_count`. |
| **total** | 23–38 (cap 40) | **≈29** | Within the cap; no re-derivation of the number is needed, only of the list. |

Prose is outside the cap by stage 1's own framing, and this delivery is prose-heavy by design: five of
the six rows close on a sentence. Recent bar for comparison: T-30 **+21** executable, T-27 **8**
added and a table deleted.

## The `rejected-decisions.md` record this design owes

One appended record, handle `denying-the-non-os-process-routes-by-a-wider-name-enumeration`:
declined — the closures priced above as (2), (3) and (5), with (3)'s reason stated as the load-bearing
one (it holds only for one CPython's internal dispatch choice, leaves `_posixsubprocess.fork_exec`
open, and is a longer list standing in for a capability), plus (5)'s (a real capability closure that
still does not cover process *replacement*, at the cost of a second global mechanism). Origin: T-31,
priced against M-1's readings. And one amendment to
`candidate-installed-by-os-replace-instead-of-the-one-writer`, whose closing sentences are falsified
by E-2 (K-16).

## Related historical work

- `docs/features/_archived/committed-test-suite/` (T-28) — built the artifact; origin of the
  capability-vs-name argument this design applies to its own new code.
- `docs/features/_archived/validate-before-baseline/` (T-30) — filed and measured R-102 and R-104;
  `mut-res9-os-replace` is its build.
- `docs/features/_archived/doctor-rows-establish-their-fact/` (T-26) — the precedent for closing a
  row by narrowing the claim with the probe byte-for-byte unchanged (applied here at K-3/K-6).
- `docs/features/_archived/state-file-contract-completion/` (T-29) — closed a row at zero code by
  ruling; the shape of FR-5 / FR-6's disposition here.
