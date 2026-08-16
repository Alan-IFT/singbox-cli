# 02 — Rationale · T-30 `validate-before-baseline`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Install a credential document safely (0600 from before the first byte, atomic, symlink-proof) | `_write_private(path, text)` | `bin/sc:488-538` | **Reuse as-is, twice per call.** It already does every single thing BC-1 asks of the transient object. Not extended, not parameterised (Q-8) |
| A fresh exclusive name in a given directory | `tempfile.mkstemp(dir=…, prefix=…)` | already used at `bin/sc:515` and by `_temp_path()` | Reuse the same stdlib call and the same naming idiom |
| Run a tool and get its merged output as safe text, on the 3.6 floor | `_doctor_run(cmd)` → `(code, _plain(out))` | `bin/sc:2538-2547` | **Reuse.** It is a general child-process runner with two callers today; this makes three. See §2 for why this is not the declined wrapper |
| Strip a tool's terminal control sequences | `_plain(text)` | `bin/sc:2493-2535` | Reuse (inside `_doctor_run`). Verified first-hand: it removes a **complete** CSI sequence (ESC `[`, params `0x30-0x3F`, intermediates `0x20-0x2F`, final `0x40-0x7E`), not merely the ESC byte — `:2518-2534` |
| State "the checker failed but printed nothing" | `t("the checker reported an error, no message (exit {code})")` | `bin/sc:313` (zh at `:314`), reader at `:2679` | **Reuse the key.** BC-10 costs zero new strings and the fact is worded once in the product |
| Record what `sc` last installed | `_record_generated()` | `bin/sc:1983-2000` | Reuse unchanged; only its call site moves |
| Three-valued drift judgement | `_drift_state()` | `bin/sc:2003-2029` | Untouched. No drift state is computed a second way (BC-8) |
| Render a write failure | `t("Could not write {path}: {err}")` + `_plain(getattr(e, "strerror", …))` | `bin/sc:2151-2152` | Reuse **one** handler for all three filesystem operations of the tail — creating the candidate, writing it, writing `config.json`. A second `except OSError` for the creation was priced and rejected (§3, S-5) |
| Check a config against `sing-box` | `sc doctor` S3 (`_doctor_config`) | `bin/sc:2662-2688` | **Not reused as a unit** — it classifies, truncates to `DOCTOR_MSG_LINES`, and must never write. Only the runner below it is shared |
| A committed assertion harness with a safe `bin/sc` loader | `check-sc-contracts.py` | `.harness/scripts/` | Reuse; one function appended, its `fixture()` and loader untouched |

Nothing here is a new module, and no new dependency of any kind is introduced — no import is
added to `bin/sc`.

## 1. Why the design is this and not a pipeline

`sing-box check` takes a **path**. That single fact is the whole design problem: "ask before you
install" needs an on-disk object, and the only question worth arguing is which object and who
creates it. Every other part of the fix is a re-ordering of three calls that already exist.

The temptation the dispatch names — a validation pipeline, a transactional-write abstraction, a
`_check_config()` helper, a `validate=` hook on the writer — buys nothing here, because there is
exactly **one** call site and the three arms differ only in which of two existing statements they
run afterwards. Delete any such helper and no complexity reappears; it fails the deletion test on
its first day. So the design has no new function at all (the T-25 bar), and its entire cost is the
seven lines that create and unconditionally remove one file plus the three-line arm FR-4 asks for.

## 2. Q-8: is reusing `_doctor_run()` the declined shared wrapper? — re-opened explicitly, and the
decline **upheld**

Q-8 binds me to re-open a decline in the open rather than slide past it, so here it is.

**What is declined** (`.harness/rejected-decisions.md` § `shared-singbox-check-wrapper`): a shared
`sing-box check` wrapper serving both `sc doctor`'s S3 and `generate_config()`. Its three recorded
reasons are (1) the judgment "is this config valid" is formed by the external binary, so a wrapper
is a pass-through, (2) the two call sites genuinely differ — one is an apply flow routing a stderr
warning, the other classifies and truncates for a report, and (3) `generate_config()`'s invocation
is one of the three `capture_output=` sites filed as their own pool row.

**What this design does** is call `_doctor_run(cmd)` — a function that takes an arbitrary argv,
starts a child, merges its streams, decodes with `errors="replace"` and returns
`(returncode, _plain(text))`. It knows nothing about `sing-box`, nothing about `check`, nothing
about configurations, and it forms no verdict. Its other caller runs `sing-box version`. Every
element the decline protects stays at the call site: the argv, the three-arm classification, the
message text, the routing to stderr, and the `return False`.

**So the decline is upheld, not overturned**: the shape it refuses — one function that both sites
ask "is this config valid, and what should I print" — is still not built, and `## Constraints` K-2
plus `## Interfaces` I-15 forbid `_doctor_run` growing into it. What is shared is a *different*
judgement, "how does a child process's output become text this project may print", which already
had one home and two callers before this task. Rule 85's "prefer reusing an existing seam over
adding a parallel one" applies to that judgement directly: the alternative is a **fourth**
spelling of the capture-and-neutralise idiom, and reason (3) of the decline is an argument *for*
this reuse — it is precisely how this site leaves the 3.7-only population instead of adding a
fourth occurrence.

The same test kills the second decline (`shared-atomic-write-helper-with-ruleset-downloader`) as a
candidate here without any re-opening: a `validate=` hook on `_write_private()` is the exact
parameter that record refuses by name, and the design does not add it — the candidate is a
*caller* of the writer, not a variant of it.

**Residual coupling, disclosed:** `generate_config()` now depends on a function that lives in the
`# doctor` block. That is the same standing as `_plain()`, which `docs/dev-map.md:78` already
describes as "a general utility that merely *lives* in the doctor block". A rename to
`_run_plain()` was considered and rejected as churn: four modified lines and a dev-map row, no
behavioural payoff, and it enlarges a surface AC-9 freezes.

## 3. The alternatives, and what the extra code buys

Rule 85 puts the burden of proof on the larger design. Four smaller candidates were priced; the
first is forbidden, the next two are equal-or-smaller and break a binding boundary condition, the
last is smaller and unverifiable. S-5, at the end, is the one *larger* candidate, and it is the
comparison that decides where I-1/I-2's boundary falls: both shapes discharge BC-11, so the choice
has to be argued on something other than correctness.

**S-1 — move `_record_generated()` below the checker call (0 added lines).** Forbidden by Q-6, and
independently wrong: it leaves the rejected document installed at `config.json` (Q-1's severe half
— the daemon reloads it at the next start of any kind, including the weekly timer's), and makes
`_drift_state()` answer *drifted*, whose one rendered sentence tells the user their own edit
changed the file and to move it into `override.json` — an accusation for a write `sc` performed.
**What the extra 21 lines buy over S-1: FR-2 itself.** This is not a close call and it is recorded
only because the requirement asked for it to be.

**S-2 — check the candidate, then `os.replace(name, str(CFG_PATH))` instead of calling the writer
a second time (≈ 0 net lines, one fewer document write at runtime).** Genuinely equal in size and
cheaper at runtime, so it was taken seriously. Rejected on BC-7: `_write_private()` is *the* single
definition of "install a credential document", and the whole content of T-13 is that the guarantee
lives in the **combination** of `mkstemp`+`fchmod`+`replace`, not in any one of them. A bare
`os.replace` of `config.json` outside that function is a second, partial spelling of the same
guarantee — correct today only because the candidate happened to be written by the writer, and
silently wrong the day someone changes how the candidate is produced. It also muddies BC-1: "the
candidate is removed on every outcome" becomes "removed, or renamed away, depending on the arm",
and the `finally` degrades into a best-effort cleanup whose success no longer means anything.
**What the extra buys: one definition of how `config.json` reaches disk, and a `finally` whose
postcondition is unconditional.** The price is one extra write and `fsync` of a few-kilobyte
document, once per regeneration.

**S-3 — a deterministic candidate name (`config.json.check.<pid>`), dropping `mkstemp` and
`os.close` (−2 lines).** Rejected on BC-1's words ("created under a fresh **exclusive** name"), and
on substance: a pid is unique among live runs but is recycled, so the design would have to answer
"what does a run do when it finds a candidate already there" — a question `O_EXCL` deletes. Two
lines is not worth re-opening a question the requirement closed. Note the honest counter-argument:
a deterministic name is *better* under BC-1's no-sweeper clause, because a leaked file is reused
rather than accumulated (RS-6). It still loses: leaks come from SIGKILL, which is rare, whereas the
concurrency question would be permanent.

**S-4 — no transient object at all: point the checker at `/dev/stdin` and feed the document
through a pipe (≈ −4 lines, and BC-1 becomes vacuous).** The most attractive candidate on paper —
credential bytes would never touch the disk twice. Rejected as unverifiable: whether
`sing-box check -c` accepts a non-seekable path is a property of a binary this project does not
control and does not pin a version of, no fixture on a host without `sing-box` can establish it
(the same wall AC-11 hits), and a stub checker would report success for a shape the real binary may
reject — the T-05 DEF-1 failure mode exactly. A design whose central mechanism is testable only on
the one row that may be BLOCKED is not a design this task can ship.

**S-5 — a second guarded region around `mkstemp` alone (+3 executable lines *over* this design).**
The problem it solves is real, and it is the easiest one in this design to miss: creating the
candidate can fail exactly as writing it can (EROFS, ENOSPC, an absent or non-directory
`/etc/sing-box`), and a `mkstemp` outside the guarded region ends the run in a traceback with **no
run-level outcome line** — BC-11's floor, and a regression against HEAD, which printed
`Could not write /etc/sing-box/config.json: Read-only file system` and exited non-zero for the same
host state. Nothing above `generate_config()` would catch it: `main()`'s envelope takes
`OverrideError` **only**, by its own comment ("THE one rendering site for any unusable *document*"),
`cmd_reload()` has no `try`, and `cmd_update_rules()`'s recovery arm re-raises anything whose
`.path` is not `SETTINGS_PATH`.

Two repairs discharge BC-11 equally, so correctness does not discriminate:

- **S-5, the larger:** wrap `mkstemp` in its own `try:` / `except OSError:` rendering the same
  `"Could not write {path}: {err}"` key against `CFG_PATH` and returning `False`, leaving the
  existing region and its unconditional `finally` untouched. Five physical executable lines
  (`try:`, `except`, a two-line message expression, `return False`) → **+24 net**, one line under
  NFR-3's hard 25.
- **What the design does instead:** open the existing `try` one statement earlier so `mkstemp` is
  its first statement, and guard the `finally` with `if name is not None:`. Two physical lines →
  **+21**, four lines of headroom.

Rule 85 takes the smaller unless the larger earns it, and S-5 does not earn it, for three reasons
beyond the line count. **(1) One judgement, one home.** "The filesystem refused to put this
document on disk → one line naming `config.json`, `return False`" is a single judgement and I-9
already owns it; the design's own argument for I-9 is that a candidate that cannot be *written* is
`config.json` that cannot be written, and a candidate whose *name* cannot be created is that same
fact one syscall earlier. S-5 gives the judgement a second home and a second copy of the message
expression — the shape §2 spends a page refusing for `sing-box check`, and the one rule 85 names
outright ("a second opinion of the same fact is the defect, not the feature"). Two copies also
drift: this function already drew a ruling about two `OSError` renderings, and a third would be one
more thing to keep equal. **(2) The invariant gets simpler rather than harder.** S-5 leaves the
tail with *two* guarded regions, so "is this statement guarded?" stays a per-statement question —
the question whose wrong answer costs a run its outcome line. Under this design the answer is
structural: the
tail is one `try` statement, the only thing outside it is a `None` assignment, and anything added
goes inside. A future editor adding a fourth filesystem call is covered by default rather than by
remembering. **(3) Headroom.** NFR-3's 25 is a bound and 21 is a prediction (G-8/C-8); S-5 spends
the budget down to one spare line, so a later wrapping change would force a choice between breaking
a stated NFR and compressing a message — exactly what C-8 forbids.

**What S-5 would have bought, priced honestly, because it is not nothing:** a `finally` with *no*
precondition. Under this design the `finally` can run in a state the `try` never could — `name is
None`, no candidate on disk — and BC-1's postcondition reads "the candidate is gone, or was never
created" instead of "the candidate is gone". That is not a weaker guarantee (there is nothing to
remove), but it *is* a fence, and a fence can be deleted: an editor who reads `if name is not
None:` as redundant gets `os.unlink(None)` → `TypeError`, which the inner `except OSError` does not
catch — the same defect class in a rarer form. Three things answer that, and together they cost
less than S-5's three lines: the guard **states** a precondition rather than working around one
(I-2 names the single state it holds in); a comment at the guard says why, and comments are outside
NFR-3's count; and it is **controlled** — I-14's fourth arm calls `generate_config()` with a parent
directory that does not exist and asserts `False` with no raise, so deleting the guard reddens B.4
with the `TypeError` and moving `mkstemp` back above the `try:` reddens it with the `OSError`. One
arm, both directions, zero executable lines in `bin/sc`. S-5's advantage is an invariant that is
easier to *state*; this design's is an invariant that is cheaper to *keep*, and only one of the two
can be made a test.

A third variant — no sentinel at all, `except (OSError, NameError)` in the `finally`, leaning on
`UnboundLocalError` being a subclass of `NameError` — is +0 lines and was rejected outright. It
turns an exception into a control-flow signal, reads as a trick to every reader but its author, and
would swallow a genuine typo in the unlink statement. Rule 85 counts a design's size as its diff
**plus** what every future reader must hold in their head; that variant trades two visible lines
for one invisible language fact.

**Priced honestly, the 21 lines break down as:** 7 for creating and unconditionally removing the
candidate inside one guarded region (BC-1, BC-11), 4 for the cannot-validate arm (FR-4/AC-4/AC-5),
6 for the rejection arm's message including the path substitution and the BC-10 fallback
(FR-5/BC-10), 1 for the second `_write_private` (BC-7), and 3 for the extra nesting the re-order
forces on lines that already exist. Nothing in that list is machinery; every item is a stated
requirement with nowhere cheaper to live.

## 4. The FR-4 / AC-6 tension, and how it resolves at zero cost

FR-4 lists "checker output the run cannot decode" as a **cannot-validate** verdict (install,
record, warn, succeed). AC-6 says a checker that "exits non-zero writing bytes the run's decoder
cannot decode" must be reported as a **rejection** with AC-2's on-disk state. Read as two rules
over the same event they contradict each other.

They do not contradict, because "the run's decoder cannot decode" is a property of the decoder the
design picks. `_doctor_run()` decodes with `errors="replace"`, which is **total over every byte
string**: there is no input for which it fails. FR-4's third disjunct therefore has an empty
extension, AC-6 governs the observable, and both units are satisfied simultaneously — by *removing*
the failure mode rather than by adding an arm for it. R-99's fix at this site is thus free: it is
the same expression FR-1 moves, and the neutralising shape already existed.

This is the one place the design resolves an upstream tension rather than implementing it, which is
why it travels to stage 3 as RS-4 rather than sitting silently in a constraint.

## 5. Risks and mitigations

**R-a — the checker quotes the candidate's path, and the message leaks a name that exists only
during the run (FR-5, AC-8's first clause).** Near-certain rather than hypothetical: `sing-box`
names the file it was handed in its `decode config at …` line, and AC-8 anticipates exactly this
("a build naming the transient path FAILS the first clause"). *Mitigation:*
`out.replace(name, str(CFG_PATH))` before the words reach `t()` — total, zero extra lines, and it
makes the sentence *more* true, since the fault is in the document destined for `config.json`.
*Verified by:* V-6 (asserts the candidate's name is absent) and V-10 against the real binary.

**R-b — the candidate leaks under `/etc/sing-box`.** The directory has no sweeper and gains none
(BC-1). *Mitigation:* `mkstemp` is the **first statement inside** the `try`, so the region in which
the candidate can exist and the region the `finally` covers are the same region by construction,
and the `finally` unlinks on every arm including both `return False` and any exception; the unlink
is itself guarded so it can never become the exception that escapes. *Residue accepted:* SIGKILL
between the two (RS-6), a class `_write_private()` already has at HEAD for its own `.tmp.` name.
*Verified by:* V-5's before/after directory listing on every case, and V-1's no-new-entry clause.

**R-c — the write-failure handler swallows the checker's `OSError` and tells the user
`config.json` could not be written when the truth is that `sing-box` is missing.** Real: the outer
handler catches `OSError`, and `FileNotFoundError` from `subprocess` is one. *Mitigation:* the
checker call carries its own inner `try`/`except OSError`, which binds first; the design makes
this an ordering property of nested handlers rather than a discrimination on the exception's
attributes. *Verified by:* V-3's AC-4/AC-5 cases assert the rendered line names the binary and the
run returns `True` — a build with the wrong nesting returns `False` and names the wrong file.

**R-d — a stub checker certifies a message property only a real one can falsify.** T-05 shipped
DEF-1 for exactly this, and this task's whole rendering path leans on `_plain()` removing a
complete CSI sequence. *Mitigation:* `_plain()` was read first-hand at design time
(`bin/sc:2501-2535`) rather than assumed, the design adds no scrubbing of its own (K-5), and AC-11
is the only row allowed to establish the ESC clause — reported **BLOCKED** with its recipe rather
than substituted if the verifying host has no `sing-box` (RS-3).

**R-e — the new B.4 assertion passes for the wrong reason.** A rejected-arm-only assertion is
satisfied by a build that never writes anything (the requirement says so at AC-2). *Mitigation:*
one function, two arms, and a stub that records the argv, the candidate's mode and `config.json`'s
bytes **at the instant of the call** — so the assertion pins the ordering positively (the checker
saw a path that is not `config.json`, while `config.json` still held its old bytes) and both
directions of the outcome. *Second-order risk:* the stub replaces `sc.subprocess`, so a leak would
poison the rest of the suite — restored in a `finally`, and the suite's docstring claim "spawns no
child process" stays true, which is why the stub was preferred over `SB_BIN=/bin/false`.

**R-f — a future editor re-couples the two sites through `_doctor_run`.** Adding a timeout, a
truncation or a `for_report=` flag to serve `sc doctor` would silently change the apply path.
*Mitigation:* I-15 states the function's invariant and K-2 forbids the parameter; the dev-map row
(E-4) carries it where the next editor reads.

**R-g — the `finally`'s `if name is not None:` guard is deleted as redundant, or a future fallible
statement is placed between the sentinel and the `try:` line.** Both re-create the defect this
design was corrected for: the first as `os.unlink(None)` → `TypeError` past the inner
`except OSError`, the second as an uncaught `OSError` with no run-level outcome line. Neither is
hypothetical — the guard *looks* redundant to a reader who has not noticed that `mkstemp` is now
inside the region. *Mitigation:* I-2 states the one state the guard holds in rather than leaving it
to be inferred, K-1 binds the developer to the I-rows' enumeration instead of to a statement count
(a count can forbid a shape without being able to describe one), and I-14's fourth arm is a control
that reddens B.4 for **both** shapes. *Verified by:* V-14, and by B.4 on every later run.

## 6. Line-budget provenance

T-29's gate ruled a budget's *provenance* the defect when a modified line was priced as an added
line, so the rule used here is stated before the number: **a physical line is counted on both
sides; a line that is modified appears once in "removed" and once in "added"; comments, blanks and
`TRANSLATIONS` data lines are excluded from the executable count and reported separately.**

- Removed, executable: `bin/sc:2148, 2149, 2150, 2151, 2152, 2153, 2154, 2156, 2157, 2158, 2159, 2160, 2161` = **13**.
- Added, executable: 34 physical lines (I-1…I-11 as written, wrapped at the file's ~88-column
  convention). Net **+21**, against NFR-3's ceiling of 25.
- Two of the 34 are what puts `mkstemp` inside the guarded region: `name = None` and the
  `finally`'s `if name is not None:`. The `mkstemp` call and the unlink block are re-indented,
  which the counting rule above scores as modified, and re-indentation forces no new continuation
  line — the longest affected line reaches roughly 80 columns at its new depth.
- The four lines of slack are wrapping tolerance: two message expressions and the `mkstemp` call
  sit near the column limit, and one extra continuation line each is a formatting outcome, not a
  design change. **25 is the bound; 21 is a published prediction to be re-derived** (G-8/C-8), and
  a measured 22 or 23 is a PASS reported as measured, never a reason to compress anything.
- Outside NFR-3: about +3 `TRANSLATIONS` data lines (two keys added at ~2 physical lines each, one
  deleted), about +6 comment lines, and about +55 lines in `check-sc-contracts.py` (I-14's fourth
  arm binds no stub and shares no body with the loop over the other three).

Two structural choices are what keep the number this low, and both are worth naming because the
obvious drafting is bigger: using **one** `try` statement with *both* an `except` and a `finally`
(rather than a `try/finally` wrapped around a `try/except`) removes a whole nesting level, and
therefore a `try:` line plus one continuation line on each of the two message expressions; and
reusing `_doctor_run()` removes the `subprocess.run` continuation line and the
`_plain(r.stdout.decode(...))` expression. Drafted naively the same behaviour costs +23 to +25.
Note what the one-`try` shape also buys beyond lines: because the same statement carries the
`except` and the `finally`, widening it to cover `mkstemp` (§3, S-5) cost two lines rather than a
nesting level, and the tail ends up with exactly one guarded region instead of two.

## 7. The B.4 decision, argued

**Adding one assertion, floor 17 → 18.** Three reasons, in order.

1. The invariant is an **ordering**, which is what a run-observed assertion is uniquely good at:
   the stub sees `config.json`'s bytes at the instant the checker is consulted, which no static
   reading of the source can establish.
2. `docs/dev-map.md:76` already records the suite's known blind spot — a contract that "gets no red
   from `verify_all`" and must be re-established by hand. Shipping this ordering into the same
   category would repeat a mistake the project has already written down.
3. It is cheap and it discriminates in every direction that matters: the same function fails on
   HEAD (the rejected arm), fails on a build that never writes (the accepted arm), fails on a build
   that lets a missing binary escape (the cannot-run arm), and fails on a build that lets the
   candidate's *creation* escape (the fourth arm).

**The fourth arm, and why the suite grows an arm rather than a function.** The other three arms all
pass with `mkstemp` unguarded, because their fixtures have a writable `CFG_DIR` — so BC-11 at I-1
is a clause the suite cannot see, and a filesystem call two characters outside a `try` is a
one-character-looking mistake with a whole-run consequence. An arm that repoints `CFG_PATH` under an absent parent and asserts `generate_config()`
returns `False` **without raising** is the cheapest control that exists for that class: it needs no
stub, no child process and no executable fixture, it fails for root and non-root alike (a
permission-based fixture would silently pass as root), and it reddens for **both** ways the
invariant can be re-broken — `mkstemp` moved back outside the guard (`OSError` escapes) and the
`finally`'s guard deleted (`TypeError` escapes). It stays inside the one function because it is the
same contract sentence read at its boundary, and K-10 counts functions, not arms.

**Not an `ast` shape check.** T-29/R-97 declined one because it pins a *spelling*; the same applies
here with more force — an `ast` assertion over "the `subprocess` call precedes the
`_write_private(CFG_PATH, …)` call" reddens B.4 for an equally correct refactor (a helper, an
inverted guard, a different temp variable name) and stays green for a build that gets the order
right and the *arms* wrong. The behaviour is observable in a run; there is no reason to assert the
text.

**Not two assertions.** The floor counts functions, and every arm belongs to one contract sentence
— "a configuration reaches disk only when the checker did not reject it". Two functions would split
one invariant across two names and invite a later editor to delete the control half.

**Never by lowering the floor.** No existing assertion changes behaviour under this design: the two
that reach `generate_config()` (`unusable_fault_clause_is_a_class_name`,
`unusable_settings_refuses_regeneration`) both raise `OverrideError` well before the new block and
keep asserting `CFG_PATH.exists() == False`.

## 8. What stage 3 should test hardest

1. **The line budget's arithmetic** (§6) — re-derive it, do not accept it.
2. **RS-4's reading of FR-4 vs AC-6** — if the gate concludes FR-4's third disjunct must be
   reachable, `generate_config()` needs a fourth *verdict* arm and the budget moves.
3. **Whether `_doctor_run` reuse crosses `shared-singbox-check-wrapper`** (§2). The design's answer
   is that the shared judgement is a different one; test it, do not accept it.
4. **R-a** — whether the real `sing-box` quotes the path it was handed, and therefore whether the
   substitution in I-7 is load-bearing or decorative. If the gate has a `sing-box`, one run settles
   it.
5. **Whether the `finally` really covers `return False`**, whether `_record_generated()` sits
   outside it, and — the clause this design leans on hardest — **whether every fallible
   statement of the tail is inside the `try`**: read `generate_config()`'s tail as control flow and
   name each statement that can raise, rather than reading the comments. `name = None` is the only
   statement that may sit outside, and it is the only one that cannot raise.
6. **§3's S-5 comparison.** The design takes the smaller of two BC-11-discharging shapes and pays
   for it with a `finally` that carries a precondition. Test whether the guard's deletion really is
   caught by I-14's fourth arm, and whether the arm is reachable in the fixture (an absent parent
   directory must fail `mkstemp` before `_write_private` is ever called).
