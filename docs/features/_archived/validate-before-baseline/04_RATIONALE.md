> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

## 1. C-1 in full — the command, and what else it established

The gate asked one question. The probe answered three, and two of the answers changed how the
code had to be written.

```
$ ROOT=$(mktemp -d); SB=/usr/local/bin/sing-box
$ /usr/local/bin/sing-box version
sing-box version 1.13.15
Environment: go1.25.12 linux/amd64
Tags: with_gvisor,with_quic,with_dhcp,with_wireguard,with_utls,with_acme,with_clash_api,...
Revision: 3708fa18766cda1f11b77f6ed9c7bd61688f17df

# valid document, written twice under two names
$ $SB check -c $ROOT/valid.json                          ; echo $?
0
$ $SB check -c $ROOT/config.json.check.ab12cd            ; echo $?
0

# rejecting document, written twice under two names
$ $SB check -c $ROOT/bad.json                            ; echo $?
FATAL[0000] decode config at /tmp/tmp.toJ2f9iDbD/bad.json: dns.servers: json: cannot
unmarshal string into Go struct field RawDNSOptions.servers of type []option.DNSServerOptions
1
$ $SB check -c $ROOT/config.json.check.ef34gh            ; echo $?
FATAL[0000] decode config at /tmp/tmp.toJ2f9iDbD/config.json.check.ef34gh: dns.servers: json:
cannot unmarshal string into Go struct field RawDNSOptions.servers of type []option.DNSServerOptions
1

$ sha256sum $ROOT/valid.json $ROOT/config.json.check.ab12cd
7531fbf4828c4d41964e33e7a58aca610607525e3a00670985fc1fa3e9a715c8  .../valid.json
7531fbf4828c4d41964e33e7a58aca610607525e3a00670985fc1fa3e9a715c8  .../config.json.check.ab12cd
$ sha256sum $ROOT/bad.json $ROOT/config.json.check.ef34gh
959f40318a20fd9c6147582628eaae03983028b762ec62d481b1cf6979f2c6a9  .../bad.json
959f40318a20fd9c6147582628eaae03983028b762ec62d481b1cf6979f2c6a9  .../config.json.check.ef34gh
```

Piped through `cat -v`, the two rejecting outputs read `^[[31mFATAL^[[0m[0000] …` — the raw bytes
are `\x1b[31m` before `FATAL` and `\x1b[0m` after it.

**Answer 1, the one asked:** the extension is not consulted. Verdict and message text are a
function of the bytes and the path string, not of the suffix. G-1 discharged, positively.

**Answer 2, unasked and load-bearing:** the decode-class failure **interpolates the path it was
handed** into its message. Had I written I-7 without `out.replace(name, str(CFG_PATH))` — or had
I verified only with a stub that prints a fixed sentence — a user of a rejecting run would read a
sentence naming `/etc/sing-box/config.json.check.7k2x9p`, a path that no longer exists by the time
they read it. This is the single most fragile clause in the change, and it is invisible to any
fixture that does not make its stub quote `$3`.

**Answer 3, also unasked:** the colouring is real, into a pipe, exactly as `_plain`'s docstring
records for a different sing-box error class. So AC-11 is not ceremony — it is the only step in
the plan that can observe the interaction of a real ANSI sequence with `_plain`'s scanner.

`/etc/sing-box/config.json` was never an argument to any of these commands.

## 2. The `.stderr` drift (D-1), and why the first control was worthless

The first run of the new assertion against the HEAD clone reported:

```
FAIL  config_reaches_disk_only_when_the_checker_did_not_reject
      AttributeError: '_Verdict' object has no attribute 'stderr'
summary: 18 defined, 1 run, 0 passed
```

That is a failure, and it satisfies C-3's literal text ("the arm failing on the HEAD clone"). It
is also worthless. HEAD reads `r.stderr` because HEAD calls `subprocess.run(..., capture_output=
True, text=True)`; this build reads `r.stdout` as bytes because it goes through `_doctor_run`.
So the assertion was discriminating between two **keyword-argument spellings**, and it would have
gone on passing on any future build that kept the pre-check ordering but restored `capture_output=`
— which is precisely the regression K-8 exists to prevent, and precisely the regression this
assertion was supposed to catch on the ordering axis.

Giving `_Verdict` both attributes costs one line and one comment and moves the failure to:

```
FAIL  config_reaches_disk_only_when_the_checker_did_not_reject
      AssertionError: rejected: the checker was pointed at config.json itself
```

which is the sentence that names the defect, and is what the HEAD clone still reports today.
This is the same lesson `02_RATIONALE` R-e drew for the *positive* direction ("a rejected-arm-only
assertion is satisfied by a build that never writes") applied to the control direction, and R-e
did not reach it: it specified what the stub must record, never what the stub must *offer*. A stub
is a two-sided contract, and the side facing the build under test has to be wide enough that the
build under test gets to run.

Generalised, this is the trap: **a control that fails for a reason other than the property under
test is not a control.** It is worth re-reading any "fails on HEAD" claim for which failure was
observed but the failure *message* was not.

## 3. The three prefix/containment traps, all measured

C-2 asks for both directions. Asserting both directions is not the same as showing that either
clause can fail, so I mutated exactly one expression on a copy of the shipped file —
`checker=out.replace(name, str(CFG_PATH)) or t(` → `checker=out or t(` — and re-ran the rejecting
case:

```
MUTANT (no .replace): leaks_candidate=True   names_config_json=True
   stderr tail='FATAL decode config at /tmp/tmp.vyHh8RWftK/config.json.check.pqbf5o8i: STUBTOKEN unmarshal'
SHIPPED:              leaks_candidate=False  names_config_json=True
   stderr tail='FATAL decode config at /tmp/tmp.tTqJVmayBE/config.json: STUBTOKEN unmarshal'
```

Note the second column. **`names_config_json` is `True` on both.** `/tmp/…/config.json` is a
literal prefix of `/tmp/…/config.json.check.pqbf5o8i`, so `str(CFG_PATH) in stderr` is satisfied
by the leaking build. An AC-8 fixture written in the obvious way — "assert the message contains
config.json" — passes on the defect it exists to catch. The clause that does the work is the
negative one, and it only does that work because the stub quotes `$3`.

`03_RATIONALE` §6 names this as one relation appearing three times in one change. All three are
now measured rather than argued:

1. **V-6's positive clause** — above. Vacuous alone; FR-5 rests on the negative clause.
2. **The argv clause** (CR-4/C-17). `str(sc.CFG_PATH) in cmd[3]` is satisfied by HEAD's own argv,
   because HEAD hands the checker `str(CFG_PATH)` itself and a string contains itself — so the
   containment spelling cannot even do the job the *inequality* already does, let alone pin the
   directory. `os.path.dirname(cmd[3]) == str(sc.CFG_DIR)` is the clause that discriminates.
3. **The `listdir(CFG_DIR)` clause.** Measured on a `dir=None` build: the candidate goes to
   `/tmp`, and the assertion **passed in full** against round 1's suite — argv inequality, mode,
   pre-run bytes and the unchanged-listing clause all green, because "no new entry appeared here"
   and "it never lived here" are the same observation. With the `dirname` clause it goes red:
   `got '/tmp', want '<CFG_DIR>'`.

I used `str(sc.CFG_DIR)` rather than H-9's `str(sc.CFG_PATH.parent)` because BC-1/BC-2 word the
invariant over `CFG_DIR` and the gate declined to require the change; `fixture()` sets both from
one `PATHS` table over a `.resolve()`d root, so they cannot disagree today. If they ever can, the
`.parent` spelling is the one that survives, and that is why H-9 is worth keeping in view.

## 4. Harness construction, and the traps it was built against

One loader (`scfix.py`) shared by four case scripts for the stage-4 rows, each run **one case per
process**; the round-2 rows (V-14, the mutation probes) reuse `check-sc-contracts.py`'s own
`load()` / `fixture()` through an `importlib` load of the script, so the audited loader is used
rather than re-implemented.

- **The exec-denial shim** denies every name in `dir(os)` starting with `exec` / `spawn` / `fork` /
  `popen` / `posix_spawn` / `system` — the enumeration, not a prefix over three names (insight 23:
  `os.popen`, `os.posix_spawn`, `os.posix_spawnp` begin with none of `exec`/`spawn`/`fork`, and a
  harness reporting "14 defined, 14 run, 14 passed, exit 0" had started a shell). R-78's symptom is
  an argparse usage error at exit 2 that reads like a harness bug; it never appeared.
- **All nine constants repointed and asserted twice** — once by the generic "every `Path` attribute
  resolves inside the root" scan, once by an explicit per-name loop, because the generic scan
  cannot see `SB_BIN` (a `str`) or a `Path` inside a container. `TUN_IFACE` was left alone: it is
  captured into `CONFIG_BASE` at import and is not repointable afterwards.
- **`_init_files()` never driven** (`/var/lib/sing-box` is a `Path` literal inside it). The fixture
  calls `save_nodes()` directly, which is all `_init_files()`'s nodes branch does anyway.
- **`main()` never called**, so insight 17's `io.TextIOWrapper` re-wrap never fires and the
  one-case-per-process rule is satisfied for free. This also means PQ-3 applies: `sc.LANG = "zh"`
  set on the module survives into `generate_config()`. Both language renderings in `## V-6` are
  genuinely different strings, which is the observable proof the assignment was not overwritten.
- **Every mutant is a file copy, never a `git worktree`,** and the HEAD comparison is
  `git clone --no-hardlinks . head-clone` (HEAD `fc634e3`). `--source` then drives the mutated or
  cloned `bin/sc` through the unmutated suite, which is exactly what `--source` exists for: the
  committed artifact carries no mutation machinery.
- **Arm 4 needed its own isolation to be measured.** Against a HEAD clone the *rejected* arm fails
  first, so the loop aborts before arm 4 runs and "arm 4 passes on HEAD" cannot be read off the
  suite's output. I ran arm 4 alone by copying the suite and emptying the three-arm loop's tuple —
  a copy, not an edit of the artifact — and it reports `18 defined, 1 run, 1 passed` on the HEAD
  clone and on this build. Without that step, C-14's first claim would still be reasoning.

Stderr was captured by swapping `sys.stderr` for an `io.StringIO` inside a `try`/`finally`, since
`bin/sc` resolves `sys` to the real module. The AC-6 case therefore asserts on the *rendered
string* containing U+FFFD rather than on an encoded byte stream; PQ-4's warning about a non-UTF-8
host's `backslashreplace` spelling applies to a real fd-2 write, which this host would not
reproduce anyway. No claim is made about a non-UTF-8 host here.

**The differential (V-2) used one root.** `RULES_DIR` is emitted verbatim into
`route.rule_set[].path`, so running the two builds at two `mkdtemp` roots diffs the paths and
proves nothing about behaviour. Both runs used `/tmp/tmp.AeWAR8IBUs/fx`, the first was wiped
between them, and the installed documents were compared with `cmp` rather than field by field.

## 5. The two fences in this tail, stated in the form that holds

**The inner `else` (C-19, correcting CR-6).** The claim worth making about a fence is one a reader
cannot falsify in thirty seconds. "A reader who mentally re-indents the inner `else` one level
loses AC-2" fails that test, and I checked both directions by compiling them: at 4 spaces the
`else` precedes the outer `except` and CPython says `SyntaxError: expected 'except' or 'finally'
block`; at 12 it lands inside `except OSError` and CPython says `SyntaxError: invalid syntax`.
Neither is a silent loss; B.1 catches both before B.4 is reached.

The edit the `else` really protects against is a different one, and it is silent: **absorbing the
rejection arm into the inner `try:` body.** Today the rejection is written in the `else` of
`try: code, out = _doctor_run(...) / except OSError:`, so its own `sys.stderr.write` is *outside*
the inner `try`. Move it inside — which reads as a harmless tidy-up, since the two arms are about
the same call — and a rejection whose stderr write raises `OSError` is caught by
`except OSError as e`, re-reported as **cannot-validate**, and then falls through to
`_write_private(CFG_PATH, text)`: the rejected document is installed and the drift record is
written. That is AC-2 lost with no exception, no red arm and a warning that says the opposite of
what happened. The `else` is what makes the two arms disjoint by structure rather than by luck.

**The `finally`'s guard.** `if name is not None:` rather than widening the inner `except` to
`(OSError, NameError)` — which really is two lines cheaper and really does absorb the unbound
state, since `UnboundLocalError` is a `NameError`. It loses on a ground that has nothing to do
with taste: its failure mode is `os.unlink(nmae)`, or a later rename that misses this line, and
the widened handler **catches and passes** that — a `0600` credential file left under
`/etc/sing-box` on every run, silently, with arm 4 still green because the return value and the
no-raise clause both stay true. The sentinel's failure mode is loud: arm 4 goes red with
`TypeError`, measured. Keeping `OSError` alone as the swallowed family is the same argument in
miniature, which is why PQ-11's answer is a hard no.

**CR-7, recorded and not fixed.** `_Verdict` is faithful to neither shape: `.stdout` is bytes
(this build's `_doctor_run`) while `.stderr` is a str (HEAD's `text=True`). A build that keeps
this ordering but re-inlines `subprocess.run(..., capture_output=True, text=True)` and reads
`r.stderr` passes all four arms. No assertion pins the 3.6 floor today, so no existing control is
weakened by the hybrid — it *is* the reason the HEAD control is behavioural (§2), and narrowing
it would trade a real control for a hypothetical one. The docstring's "delete it and the control
stops being one" is the mitigation the trap needs; the hybrid shape is the part worth naming, and
it is named here rather than fixed because fixing it is a K-8 control, which is a different task.

## 6. Things I checked and found already true, so nobody re-checks them

- **The `finally` really covers both `return False` paths.** One `try` statement carrying both an
  `except` and a `finally` makes this a language property; the rejecting cases confirm it
  behaviourally (`listing_identical=True` on every rejecting run).
- **`_record_generated()` is unreachable from every `return False`.** Not asserted textually
  (K-3's rule) but observed: on the rejected arms the drift record is byte-identical to its
  sentinel pre-state, and on arm 4 `STATE_PATH` stays absent.
- **`_write_private()` needed no adaptation but `Path(name)`.** `mkstemp` returns a `str`; the
  writer wants `path.parent` and `path.name`, so the wrap is mandatory and is the only adaptation.
- **`_plain` and `_write_private` really are unchanged.** Verified by hashing each function's own
  text on both sides rather than by reading the diff — `f04a53be6c5599c8` and `c394797931d99deb`
  on HEAD and on this build. A diff can hide a change inside a moved block; a hash of the
  extracted span cannot. `_plain` has now moved by 56 lines and changed by zero bytes.
- **Nothing above `generate_config()` catches an `OSError`.** Re-read at the three sites the
  design names: `main()`'s envelope takes `OverrideError` only, `cmd_reload()` has no `try`, and
  `cmd_update_rules()`'s recovery arm re-raises anything whose `.path` is not `SETTINGS_PATH`.
  This is the premise the whole guarded-region argument rests on, and direction B's V-14 run is
  its measured form: an uncaught `FileNotFoundError` and **zero** outcome lines.
- **`sc doctor` forms no second opinion.** V-8's three-state comparison against the HEAD clone is
  row-for-row identical, and it is a **freeze** — it agrees with HEAD by design and is never
  evidence that this change works.
- **AC-10's freeze is real but not total.** `cmd_update_rules`' stdout, exit status, outcome-line
  count and restart count are byte-identical to HEAD; what differs is the stderr sentence and
  whether a rejected `config.json` is left on disk. Reporting "identical" without that distinction
  would have been a false freeze claim — which is exactly the claim `CHANGELOG.md:26` was making
  until C-18 scoped it to 标准输出与退出码.

## 7. The budget, re-derived rather than accepted

I did not trust `git diff -U0` and it turned out I was right not to. Git matches seven lines of
the old tail against textually identical lines in the new one — `try:`,
`_write_private(CFG_PATH, text)`, `except (OSError, ValueError) as e:`, its two message lines,
`return False`, `return True` — and reports 6 removed executable lines where K-9's derivation
counts 13. Both accountings are defensible; neither is the number NFR-3 bounds. What NFR-3 bounds
is the file's size, so I counted the file: one `ast`-driven classifier, run identically over the
HEAD clone and this build, bucketing every physical line as blank / comment / docstring /
`TRANSLATIONS`-interior / executable. That gives **+21** whole-file and **+21** inside
`generate_config()` alone (61 → 82) — two methods, one figure, and it lands exactly on K-9's
prediction of 34 − 13.

The prediction landed because the classifier's HEAD column reproduces round 1's figures line for
line (2097 / 459 / 613 / 225 / 414) and the round-2 delta is arithmetic on top of a measured 32.
Nothing was compressed to make it land: the round-1 → round-2 delta is +2 executable and +11
comment, measured by reconstructing the round-1 build and classifying the pair, and the +11 are
outside the count by the same rule on both sides. Had the two message expressions wrapped once
more the figure would be 22 or 23, still inside 25, and C-8 says in as many words that such a
figure is a PASS reported as measured — so there was never a reason to touch them.

## 7b. E-10 — the collapse probe behind `docs/dev-map.md:76`, re-run at 18

`docs/dev-map.md:76` carries a **negative** claim: no committed assertion covers
`cmd_update_rules()`'s `if e.path != SETTINGS_PATH: raise` discrimination, so B.4 stays green on a
build that swallows an `override.json` or `nodes.json` fault. T-29 established it by measurement at
17 assertions. **T-30 raised the floor to 18**, which falsified the number the sentence cites and
left the claim unmeasured at the new count. The obvious argument — the one assertion T-30 added
covers the candidate/verdict ordering and this discrimination not at all — is correct but is still
an argument, and this row has now been wrong about a number twice, the second time because of our
own change. So it was re-run.

**Method.** `git clone --no-hardlinks` of the repo into the scratchpad; **never** a `git worktree`
and never the working tree. The clone lands at HEAD `fc634e3` (= T-29), so T-30's uncommitted state
was carried in by copying `bin/sc`, `.harness/scripts/check-sc-contracts.py` and
`.harness/scripts/baseline.json`. The mutation was applied to a **copy** of the clone's `bin/sc`
and driven through the suite's own `--source`; then that copy was written over the clone's `bin/sc`
so `verify_all`'s real B.4 gate — not merely the suite in isolation — was what got measured.

The mutation is the row's own words, the arm collapsed to an undifferentiated handler:

```
-            except OverrideError as e:
-                # FR-7 scope: FR-6's refusal alone becomes an outcome this run reports.
-                if e.path != SETTINGS_PATH:
-                    raise
+            except OverrideError:
                 regen_ok = False
```

| run | source | result |
|---|---|---|
| working tree, control | T-30 as delivered | `18 defined, 18 run, 18 passed`, exit 0 |
| clone, control | same, carried into the clone | `18 defined, 18 run, 18 passed`, exit 0 |
| clone, **collapsed** | the mutant via `--source` | `18 defined, 18 run, 18 passed`, exit 0 |
| clone, **collapsed**, full gate | mutant over `bin/sc` | `PASS 19 WARN 0 FAIL 0 SKIP 1`, exit 0; **B.4 PASS** |

Not one assertion moved, and the gate did not redden. The property holds unchanged at the new
floor, so **R-97 is not closed by T-30** — the outcome the row needed, and precisely the one that
had to be *run* rather than assumed: the opposite finding would have been good news, and good news
is the kind that must not be asserted without a measurement. Only the number was ever stale.

The replacement clause therefore states the clean **sweep** and names the count as *whatever
`baseline.json`'s `test_count` floor currently is* (18 at T-30, 17 under T-29). That is the part
worth keeping: a row whose evidence is "the suite is entirely green under mutation" was written
against a *literal* count, so every future assertion re-falsifies a sentence whose substance never
changed. Naming the floor instead of the integer costs one clause and ends the cycle.

**Where this record lives.** The narrative above is measurement, so the boundary rule sends it
here; `04_DEVELOPMENT.md` keeps only the outcome, the tally and the pointer. It was moved here for
a second reason as well: the contract portion was at 498 of F.6's 500-line cap, and pasting the
transcript into it would have turned a green `verify_all` into `WARN 1 / exit 1` — the very tally
this round was asked to confirm.

## 8. What I would look at hardest if I were reviewing this

1. **The three-way nesting inside one function.** `try` → `mkstemp` → `_write_private` → inner
   `try`/`except OSError`/`else` → `_write_private` → outer `except`/`finally`/guard. It is
   correct and it is what I-1…I-11 specify, but it is the densest control flow in `bin/sc`, the
   binding order of the two `except` clauses is load-bearing, and §5 names the one edit that
   breaks it silently.
2. **Arm 4 is a single point of failure by design.** `03_RATIONALE` §3 is right that shape 2 turns
   a structural property into a tested one. One arm, in one function, is all that stands between
   this project and both re-breakages — and it is green on a HEAD clone, which is exactly the
   shape a future editor deletes as dead weight. The docstring is the whole mitigation. If a later
   task wants a second control, the honest one is not a fifth arm but an `ast`-free re-run of the
   two mutations in CI, and K-11 explains why the `ast` route is the wrong one.
3. **Whether the cannot-validate arm's new restart is wanted on a real host.** G-11 / C-11. It is
   the only behaviour in this change that is strictly *more* action than HEAD took, and the only
   one with no acceptance criterion over it.
4. **FR-5 still has no committed control** (CR-5). The property holds in this build and is
   measured three ways in `04_DEVELOPMENT.md`, but `verify_all` gives an editor of
   `out.replace(name, str(CFG_PATH))` no red at all — the same scar `docs/dev-map.md:76` already
   records for the recovery arm, in the same file, one task later.
