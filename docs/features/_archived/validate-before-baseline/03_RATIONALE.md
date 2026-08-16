> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## 0. What I could and could not measure

This session holds `Read`, `Grep` and `Glob` and **no shell**. Everything below that reads as a
measurement of the tree is a first-hand read of the file at the cited line. Everything that reads as
a claim about what a mutated build would *do* — arm 4's two directions especially — is **reasoned**
from the delivered source and from CPython semantics, and is labelled as such. Stage 6 runs it.

## 1. Claim 1 — does arm 4 redden B.4 in both directions?

Reasoned, not measured. Both directions redden, and a third spelling of the first one does too.

**The shape under test**, from `02` I-1/I-2, with the delivered tail (`bin/sc:2157-2204`) as the base:

```
name = None
try:
    fd, name = tempfile.mkstemp(dir=str(CFG_PATH.parent), prefix=CFG_PATH.name + ".check.")
    os.close(fd)
    ...
except (OSError, ValueError) as e:
    <one line>            ; return False
finally:
    if name is not None:
        try: os.unlink(name)
        except OSError: pass
_record_generated()
return True
```

**Arm 4's state:** `CFG_PATH` under a parent that does not exist, no stub bound. `mkstemp` raises
`FileNotFoundError`.

- **Correct build.** `FileNotFoundError` ⊂ `OSError` → the outer handler renders and returns `False`;
  the `finally` runs with `name is None` and does nothing. Arm 4 passes.
- **Direction A — the guard deleted.** `os.unlink(None)`: CPython's path converter raises
  `TypeError`, which the inner `except OSError` does not catch and which is raised *inside* the
  `finally`, so it replaces the pending return and leaves `generate_config()`. Arm 4's "returns
  `False` without raising" fails. **Red.**
  - *Third spelling:* if the editor deletes the sentinel too, `name` is unbound and
    `os.unlink(name)` raises `UnboundLocalError` — still not an `OSError`, still escaping. **Red.**
  - *Fourth spelling:* deleting the `if` line without dedenting its body is an `IndentationError`,
    caught by B.1 before B.4 ever runs. Red earlier.
- **Direction B — `mkstemp` moved back above the `try:`.** The `FileNotFoundError` escapes
  `generate_config()` with nothing above it to catch (`main()`'s envelope takes `OverrideError` only,
  `cmd_reload()` has no `try`, `cmd_update_rules()`'s recovery arm re-raises anything whose `.path`
  is not `SETTINGS_PATH`). Arm 4 sees a raise. **Red.**

**And the arm is reachable**, which is the half worth checking rather than assuming. Walking
`generate_config()` from `:2057`: `_load_override()`, `load_settings()`, `load_nodes()`,
`ruleset_report()`, `_valid_selection()`/`save_nodes()`, `_compose()`, the array guard,
`_filter_rules()`, `_warn_degraded()`, `_warn_drift()`, `json.dumps` — none of them names
`CFG_PATH.parent`. `_warn_drift()` degrades to silence because `_drift_state()` calls
`_config_digest()`, whose `except OSError: return None` (`bin/sc:1981-1982`) covers an unreadable
`CFG_PATH`. So the first statement that touches the absent directory is `mkstemp`, and
`_write_private` is never called — which is exactly the precondition `02_RATIONALE` §8.6 asked the
gate to check.

A raised exception inside an assertion is reported by `_execute` (`check-sc-contracts.py:670-677`) as
`FAIL <name>` and counts against `passed`, so both directions surface as a red B.4 rather than as a
suite abort. And no child process is involved: `mkstemp` fails before `_doctor_run` is reached, so
the module docstring's "spawns no child process" claim survives arm 4.

**Conclusion:** the mitigation is as strong as the architect claimed. The shape choice does not have
to move on this ground. What is *not* as strong as implied is its **concentration** — see §3.

## 2. Claim 2 — the tail as control flow, read for what is outside the guard

This is the reading my round-1 dimension-2 audit did not do, and it is the reason CR-1 shipped. Doing
it in the other direction now, statement by statement, under the corrected shape:

| statement | inside I-2's `try`? | can it raise? |
|---|---|---|
| `name = None` | no | no — a constant binding |
| `fd, name = mkstemp(...)` | **yes**, first | `OSError` → outer handler. No partial bind: a 2-tuple unpack either completes or the call raised before it |
| `os.close(fd)` | yes | `OSError` → outer handler |
| `_write_private(Path(name), text)` | yes | `OSError` / `ValueError` → outer handler |
| `_doctor_run([...])` | yes, in its own inner `try` | `OSError` → inner arm (binds first); `ValueError` → outer handler |
| the cannot-validate `sys.stderr.write` | inside the **inner handler**, which is inside the outer `try` body | `OSError` → **outer** handler, rendered as a write failure. Mis-worded on a doomed-stderr run, never uncaught |
| the rejection `sys.stderr.write` | inside the inner `else`, inside the outer `try` | same — caught, `return False`, and AC-2's on-disk state still holds |
| `_write_private(CFG_PATH, text)` | yes | `OSError` / `ValueError` → outer handler |
| the outer handler's own `sys.stderr.write` | **no — it is the handler** | `OSError` **escapes**. See below |
| `if name is not None:` | in the `finally` | no — an identity test |
| `os.unlink(name)` | in the `finally`, own `try` | `OSError` swallowed by design; `TypeError`/`NameError` impossible while the guard stands |
| `_record_generated()` | **no** | effectively no: `_config_digest()` returns `None` on `OSError` (`:1981`), and the `_write_private` below it sits in `try: … except OSError: pass` (`:2000-2003`). A `ValueError` is unreachable for a 64-char hex digest |
| `return True` | **no** | no |

Two things fall out.

**(a) I-2's sentence is wrong, and it is wrong in the direction that matters.** Three statements are
outside the `try`, not one. The design's own K-3 *requires* two of them to be there. A developer
reconciling I-2 with K-3 literally has a conflict, and the only reading that makes both true is the
one I-2 does not state: *no statement outside the `try` can raise*. That is a true and checkable
sentence, and its truth depends on a fact about `_record_generated()` that lives in a different
function and is nowhere cited in `02`. C-13 makes the developer write the enumeration down, because
the next person to widen this tail will read `04`, not this file.

**(b) The one path that still escapes.** A `sys.stderr.write` raising inside the outer handler is
uncaught and always was: HEAD's handler at `:2150-2153` had the identical shape at the identical
place. BC-11 is worded as a floor over the *population*, and this member is a pre-existing one, so it
does not violate it. I decline to require a fix, and the reasons are worth stating because "the
reviewer declined to file it" is not one: guarding a handler's own render needs either a second
nested `try` per arm (three of them) or an `except Exception` envelope above `generate_config()`,
which K-12 forbids and which would be a strictly larger design than the one under review, bought for
a state in which the process has already lost its ability to say anything at all. Recorded as a
residual (C-20) rather than silently dropped, because the *next* reviewer should not have to
re-derive it either.

## 3. Claim 3 — the shape ruling, and the cost the smaller shape hides

Rule 85 puts the burden on the larger design, and shape 1 is the larger. It does not discharge it.
But the standing directive asks the reverse question, so here is the honest ledger.

**What shape 2 genuinely buys, verified rather than accepted:**

1. *One judgement, one home.* I-9 already owns "the filesystem refused to put this document on
   disk". This function has **already** had to be ruled on for having two `OSError` renderings
   (CR-8, ruled "confirmed wanted" on the ground that one names a program and the other a file). A
   third rendering of the *same* fact as I-9's, three lines apart, is a different thing from CR-8's
   pair and is the shape §2 spends a page refusing elsewhere. This argument is sound.
2. *The invariant becomes structural.* Under shape 1, "is this statement guarded?" stays a
   per-statement question — the exact question whose wrong answer produced CR-1. That is the
   strongest argument in §3 and it is correct.
3. *Headroom.* This one carries no weight and does not need to. C-8 already ruled that the budget is
   a bound and not a target; "24 leaves one spare line" is an argument about a number, and if it were
   the deciding argument the decision would be wrong. It is not deciding, so no harm done.

**What the architect did not say, and should have** — and it is the single most load-bearing fact
about the fence: **the guarded `finally` is already this file's idiom, in the very function the
candidate is written by.** `_write_private` (`bin/sc:534-541`) ends in

```
    finally:
        if fd >= 0:
            os.close(fd)
        if tmp is not None:
            try:
                os.unlink(tmp)
            except OSError:
                pass
```

— two preconditions, two guards, one of them the identical `if <name> is not None:` around an
identical guarded `unlink`. So §3's honest worry ("a fence can be deleted by an editor who reads it
as redundant") is a worry about deleting a spelling this codebase uses twice, thirty lines apart,
inside T-13's frozen writer. That lowers the residual risk materially, and it means the new
`finally` is a **reuse of an existing shape** rather than the novel invariant §3 priced. Rule 85's
"prefer reusing an existing seam" applies to shapes as well as to functions.

**The cost shape 2 does hide, and shape 1 would not have.** Shape 2 converts a *structural* property
into a *tested* property. Under shape 1, "the `finally` has no precondition" is true by construction
and needs no control at all; under shape 2, one arm of one assertion is the only thing standing
between the project and both re-breakages. This project has its own recorded scar about exactly that
(`docs/dev-map.md:76` — a contract that "gets no red from `verify_all`" and must be re-established by
hand), and §7 cites it as an argument *for* adding arm 4 without noticing that shape 2 is what makes
arm 4 load-bearing rather than merely nice. It is still the right trade — a tested property in a
suite that runs on every `verify_all` beats a structural property nobody re-reads — but it is a
trade, and C-14 prices it the only way it can be priced: the arm's own docstring says it is the sole
control, so deleting it is loud.

One further cost, checked and found inert: widening the `try` also widens what its
`except (OSError, ValueError)` swallows. For `mkstemp` that is exactly right (its failure *is*
"config.json cannot be written"). The forward-looking half — a future statement added at the top of
the region is now auto-guarded *and* auto-rendered as a write failure even when that is the wrong
sentence — is the mirror image of argument (2) and is bounded by the same K-1 that forbids adding
statements at all.

**Ruling: shape 2, for reasons (1) and (2), reinforced by the idiom precedent. Shape 1's three lines
do not buy a simpler invariant; they buy a simpler *statement* of one, and this project can test the
former and cannot test the latter.**

## 4. Claim 4 — pricing the `except (OSError, NameError)` variant myself

"A trick" is a conclusion. The argument, priced:

- **The language fact is real.** `UnboundLocalError` **is** a subclass of `NameError`, so
  `except (OSError, NameError): pass` in the `finally` really does absorb the unbound-`name` state
  with no sentinel. The line count is honest too: the `except` line is *modified*, so the counting
  rule scores it zero, and the variant is **+19** against shape 2's **+21** — two lines cheaper than
  the design, five cheaper than shape 1.
- **It is equally controlled in one direction.** Delete `NameError` from the tuple and arm 4 goes
  red with `UnboundLocalError`; move `mkstemp` outside and it goes red with `OSError`. On that axis
  it ties with the sentinel.
- **It loses on an axis §3 does not name.** Its failure mode is not "someone deletes a fence" — there
  is no fence to delete. It is "someone writes `os.unlink(nmae)`", or a later edit renames the
  variable and misses this line. That produces a `NameError`, which the handler **catches and
  passes**: a `0600` credential file is left under `/etc/sing-box`, silently, on every run, and **no
  arm can redden it** — arm 4 asserts on the return value and on no-raise, both of which stay true.
  The sentinel's failure mode is caught; the variant's is not. That is decisive, and it is a stronger
  argument than the readability one §3 leads with.
- **The readability point is nonetheless true**, and this project has already decided it: the
  codebase repeatedly prefers a *value* over an exception family as a signal (`_drift_state()`'s
  three-valued return, `stored_delays()`'s "every shape check is an `isinstance` test with no
  `try`/`except` — a malformed body yields absence, never a traceback"). `if name is not None:`
  names the state; `except NameError` names the interpreter's reaction to it.

**Decline upheld, on the swallowing argument rather than on the aesthetic one.**

## 5. Claim 5 — arm 4 "passes on the HEAD clone"

Honest, and verified by reading HEAD's tail as recorded in `01_RATIONALE.md:23-28`: HEAD's first
statement is `_write_private(CFG_PATH, text)` *inside* its `try`, whose own `mkstemp(dir=path.parent)`
(`bin/sc:518-520`) raises `FileNotFoundError` for the same fixture, is caught by HEAD's
`except (OSError, ValueError)` and renders the same key. So arm 4 passes on HEAD, and the design says
so in I-14 in the plainest available words. That is the correct classification: it is a **regression
control for this design's own boundary**, and the rejected arm remains the HEAD discriminator.

Where the documentation falls short is location, not honesty. The sentence lives in `02`, which no
future editor of `check-sc-contracts.py` will read. The file itself already knows how to carry this
kind of fact — `_Verdict`'s docstring ends "Delete it and the control stops being one" — and C-14
asks for the same treatment, with the two mutations named, so that an editor who sees a green arm on
a HEAD clone does not conclude the arm is worthless and delete it.

## 6. Claim 6 — the `dirname` clause, and the third instance of the prefix shape

`fixture()` (`check-sc-contracts.py:126-144`) sets `CFG_DIR = d` and `CFG_PATH = d / "config.json"`
from one `PATHS` table, and `ROOT` is `.resolve()`d in `main()` (`:716`), so no symlink can make the
two spellings disagree. `mkstemp(dir=str(CFG_PATH.parent))` returns an absolute path whose
`os.path.dirname` is exactly `str(d)`. A build mkstemping into `TMPDIR` yields `/tmp` and goes red.
**The clause discriminates.** `str(sc.CFG_PATH.parent)` would be the spelling closest to I-1's own
`dir=`, and is what I would write if the two names could ever diverge (H-9) — but `CFG_DIR` is what
BC-1/BC-2 word the invariant over, so the mandated spelling is defensible and I do not require a
change.

**The third instance of the prefix/containment shape.** Asked for, and found — it is in the design
still, unmoved since round 1:

1. **V-6's positive clause**, "contains `str(CFG_PATH)`" (G-2, round 1). Vacuous **alone**: the
   candidate's name has `str(CFG_PATH)` as a literal prefix, so an unsubstituted line satisfies it.
2. **I-14's argv clause** (CR-4): `str(sc.CFG_PATH) in cmd[3]` would be vacuous for the same reason;
   `dirname` is the repair.
3. **The `listdir(CFG_DIR)` clause** in V-1/V-5 and NFR-2: "no new entry appeared" is satisfied both
   by "the candidate was removed" and by "the candidate was never in this directory at all" — CR-4's
   second half, closed by the same `dirname` clause.

They are one relation appearing three times in one change, which is worth naming as a class rather
than as three coincidences: *a clause asserting containment or membership over a directory or a path
string is satisfied by the wrong build whenever the object under test is named after, or lives
beside, the object it is being distinguished from.* In this task the shape is closed at (2) and (3)
by `dirname`, and at (1) only by V-6's fourth clause — which is a one-off stage-4 run, per CR-5. FR-5
therefore still has **no committed control**, exactly as the reviewer recorded; the design declines a
fifth arm in `## Out of scope` 9, and I do not re-open that, because the decline is upstream-ruled
and the property does hold in the delivered build.

## 7. Claim 7 — re-deriving the budget

Counting rule (unchanged, `02_RATIONALE` §6): a physical line, executable iff not blank, not
comment-only, not a `TRANSLATIONS` data line; a modified line appears once on each side.

**Removed at HEAD:** `:2148-2154` (7) + `:2156-2161` (6) = **13**. Verified line by line in round 1.

**Added, delivered build:** I counted the executable physical lines of the delivered tail
(`bin/sc:2157-2204`) by hand: `2157, 2158, 2159, 2160, 2163, 2164, 2168, 2169, 2173, 2174, 2175,
2176, 2177, 2183, 2184, 2185, 2186, 2187, 2188, 2189, 2190, 2191, 2195, 2196, 2197, 2198, 2199,
2200, 2201, 2202, 2203, 2204` = **32**. Net **+19** — which is the developer's V-12 figure measured a
different way (a whole-file `ast` classification, 2097 → 2116), so two independent methods agree on
the base.

**Round 2 adds two executable lines** and re-indents the `mkstemp` call and the unlink block, which
the counting rule scores as modified: **34 − 13 = +21**, against NFR-3's **25**. The re-indentation
forces no new continuation — the longest affected line (`:2196`) is ~88 columns today and the two
re-indented blocks sit well inside it; the only line that gains depth and length together is
`os.unlink(name)` with its trailing comment, and a comment may be reflowed freely because comments
are outside the count.

So **+21 is correct as a prediction**, and it is arithmetic on a measured 32 rather than a fresh
guess. C-8 stands unweakened: 22 or 23 measured is a PASS reported as measured, and nothing is
trimmed to reach a number. The whole-file method makes the round-2 expectation 2097 → 2118.

## 8. Claim 8 — BC-11, three out and zero in

Enumerated over every way control can leave `generate_config()` non-zero without a stated outcome,
under the corrected shape:

- **Removed (three):** an absent `SB_BIN`, an unexecutable `SB_BIN` (both `OSError` → I-6's arm), and
  undecodable checker output (`_doctor_run`'s `errors="replace"` is total, so the `UnicodeDecodeError`
  HEAD raised through `text=True`'s locale decode has no input left to raise on).
- **Added (zero):** `mkstemp`, `os.close`, both `_write_private` calls and `_doctor_run`'s
  non-`OSError` failures are all inside the outer `try`, whose `except` takes `OSError` **and**
  `ValueError`; the inner arm binds first for a checker `OSError`; the `finally` cannot raise while
  the guard stands; `_record_generated()` is total (§2); `return True` cannot raise.
- **Pre-existing, unchanged (one):** the outer handler's own `sys.stderr.write` (§2b, H-10) — the same
  member HEAD already had, in the same place.

**BC-11 is satisfied as the floor it is worded as.** RS-8's "three out, zero in" is therefore correct
about the population — and its *other* claim is not: Q-5 says "**it moves one and removes three**",
where "moves one" names the rejection unwind changing **position** (after the write → before it),
which is still exactly what happens. Q-4 says the change "adds no exception that can escape" and
"removes three", both now true. So `01` needs no round, and RS-8 should travel to the PM as a note
that closes the question rather than as one that opens it (H-8, C-22).

## 9. Claim 9 — E-4 and E-6's new ledger authorisations

All three are the right corrections and all three stay inside "correct only the sentences this change
falsifies":

- **`:105-106`'s `capture_output=` bullet.** Read first-hand: the bullet says "at three sites" and
  two remain (`bin/sc:2258`, `:3523`). This change is what falsified it; T-32's sweep does not own a
  sentence *this* task made false. Correct, and it is one clause inside an existing bullet, not a
  sixth row — C-10 is amended in place rather than stretched.
- **Row `:41`'s failure clause.** The row currently says an `OSError` or `ValueError` "from either
  **write**" is one line and `return False`. Under CR-1's shape that was literally true and
  misleading (the reviewer noticed); under the corrected shape it is simply incomplete, because the
  handler now covers three filesystem operations. Rewording to three is a correction, not a
  completion.
- **`CHANGELOG.md:26`.** Verified: the paragraph's closing clause claims `sc reload` / `sc add` /
  `sc update-rules` 的**输出**与退出码均无任何改动 while the same paragraph describes a reworded
  rejection message and a new stderr line. Scoping to **标准输出与退出码** makes the sentence true
  without deleting the freeze claim, which is the honest repair — and it is in the user-facing file,
  which is where a self-contradicting paragraph costs most.

**What the ledger misses** is the sentence *this round* falsifies: dev-map `:87` currently reads
"T-30: three arms — rejected / accepted / could-not-be-run" (H-3). The row is already open under
C-10, so the fix is one clause in an authorised row; it just has to be named, or the same class of
finding that produced CR-2 recurs in the same file, in the same task, two rounds apart.

Related and smaller: the ledger's coordinates are HEAD-relative while the next round is a delta on
the delivered tree (H-4). `TESTS` has moved from `:537-547` to `:644-655`; `baseline.json` already
reads `18`/`18`, so E-3's "17 → 18" is spent and K-10's "adding an arm is not adding an assertion" is
the clause that must govern. C-16 states the end-state so nobody increments a floor that a fourth arm
does not move.

## 10. Claim 3's own question — does K-1's re-statement prevent a recurrence?

Partly. It fixes the half that made CR-1 *unrepairable in place*: round-1 K-1 forbade a twelfth
statement by arithmetic, so the developer who wanted to guard the `mkstemp` would have had to break a
constraint to do it. "The bound is the enumeration, not a count" removes that, and it is the right
correction.

It does not fix the half that made CR-1 *happen*. The defect was an enumeration that was wrong at one
boundary; a developer bound to an enumeration implements a wrong one just as faithfully as a right
one. What actually catches the next instance is the combination the design now has — I-2's corrected
boundary sentence (once H-1 is repaired), arm 4, and a gate that walks the tail as control flow
instead of reading its comments.

And it does move the ambiguity by one word: "require" is now load-bearing. The reading I take, and
that the developer should take, is the strict one — a statement the I-rows do not require is
forbidden, so a developer who finds a *second* gap routes it back rather than patching it, exactly as
stage 5 did here. That is the correct policy and it is the whole reason this task has a
frozen-set/constraint structure at all. It is simply left implicit, which is why it is filed as H-11
rather than as a condition: the process handled it correctly once already, without the sentence.

## 11. Verified good, so the next reader does not re-derive it

- `_write_private` (`bin/sc:491-541`) is byte-identical to its pre-task shape, signature `(path,
  text)`, no hook, no mode parameter, two callers. BC-7/K-2 hold.
- `TESTS` really holds 18 entries (`:644-655`), and `baseline.json` reads `18`/`18`. AC-13's floor is
  where the review says.
- `_execute` (`:670-677`) reports a raised exception as `FAIL` and does not abort the run, so a red
  arm 4 is a legible failure rather than a suite crash.
- `fixture()`'s BC-2 scan (`:138-143`) compares against the resolved `ROOT` with an explicit
  `root + os.sep` test, so a sibling sharing the prefix is not admitted — the one place in this file
  where the prefix relation was already handled correctly.
- `CONTEXT.md:127-134` carries one new term and states K-6's disjunct positively; C-4 stayed
  discharged through the correction.
- `_doctor_run`'s widened docstring names the second caller and the four things the runner must never
  gain, in the file a "just add a timeout" edit would touch. I-15's fence is where it is useful.
- `docs/architecture.md`'s diagram draws the candidate ahead of `config.json`; E-5 needs nothing from
  this round.
- The rejection arm's `else:` really is load-bearing, and CR-6's re-derivation of *why* is right: the
  edit it blocks is absorbing the rejection into the inner `try:` body, after which a failing
  `sys.stderr.write` would be re-reported as cannot-validate and the rejected document then
  installed. Worth carrying in the words that hold (C-19), because a fence a reader can falsify in
  thirty seconds stops being read.
