> Rationale portion for 06_TEST_REPORT.md. Non-binding.

## How the sweep was driven, and why it is not the developer's tests

Every reproducer in the contract was written from the **acceptance criterion and the subject
code**, never from `04_DEVELOPMENT.md`'s test code. The one thing I did reuse is the delivered
suite itself — deliberately, and it is the opposite of a shared assumption: R-78's incident on
this machine was a stage-6 agent writing its *own* loader for `bin/sc` and re-exec'ing the
installed build under password-less sudo. The committed suite **is** the loader now, and `--source`
is the supported way to point it at a mutated copy, so the sweep needed no loader of mine. What I
did write independently is the mutation table (from `bin/sc`, read function by function), the
capability probes, the verdict driver, and the witness falsification.

Every mutant is a **copy** in `/tmp/claude-1000/…/scratchpad/`. `bin/sc` is byte-identical to
`55f39f0` (`sha256 b2b79856cb9459be19228e24c8baa615ad4726602de2bdf9c6b6029880b44d0e`, compared
against `git show 55f39f0:bin/sc`). The repository working tree at the end of the stage is the
same nine modified + two untracked entries it was at the start; one stray artifact I created
(`.harness/scripts/check-sc-contracts.cover`, from a `python3 -m trace` attempt) was removed and
`verify_all` re-measured afterwards.

`sweep.py` refuses to run a mutation whose `old` text does not occur **exactly once** in `bin/sc`
(`MUTATION-NOT-APPLIED (n matches)`). That caught two of my own errors rather than producing a
silent false kill: `M17` matched 0 times (I had guessed at `_unusable`'s parameter name; the real
line is `failure.path = path` at `bin/sc:557`) and `M19` matched 2 times (`fault=type(e).__name__`
appears at `bin/sc:2064` **and** `:2136`; I switched to the whole four-line `except` arm, which is
unique to `generate_config`). A sweep that silently mutated the wrong site would have reported a
kill for the wrong reason — the same failure shape T-08 caught six of.

## Full runs behind the cited excerpts

**AC-1, the measurement run.** 20 steps in order: A.1 A.2 PASS, B.1 B.2 PASS, B.3 SKIP, B.4 B.5
PASS, E.1 E.2 E.3 E.4 E.4b E.5 E.6 PASS, F.1 … F.6 PASS. `=== Summary === PASS: 19 / WARN: 0 /
FAIL: 0 / SKIP: 1`, `EXIT=0`. Three later runs identical. The task-start figure of 17/0/0/1 is not
re-runnable without checking out `55f39f0` (which would move the working tree), so I confirmed it
by arithmetic instead: the only step-adding hunk in the whole diff is `verify_all.sh`'s single
`@@ -75,6 +75,27 @@`, which adds exactly the two `step "B.4"` / `step "B.5"` call sites, and
`verify_all.ps1`'s hunk adds two `Step` blocks that both return SKIP (and the `.ps1` is not the
measured mirror). 18 + 2 = 20 steps; 19 PASS + 1 SKIP.

**The full suite output** (14 `PASS` lines + summary) is reproduced once in
`04_DEVELOPMENT.md`'s measurement block and matched mine byte for byte, including the evidence
strings — e.g. `6 SECRET_KEYS names at depths 1-3, inside and outside outbounds` and
`182 entries in 1 table(s), 0 offenders`.

**The sweep**, in full: 30 mutations + 1 codec control over 14 assertions, plus M28b added after
M28's outcome showed it did not exercise the clause I aimed at. 29 clause kills, 1 predicted
survival (M11b), 3 clauses no `bin/sc` mutation can reach (two controls, one implied clause).
Every mutant run printed exactly one `FAIL <assertion> <ExceptionType>: <message>` line followed
by `summary: 14 defined, 1 run, 0 passed` and exited 1 — the suite's failure shape is uniform,
which is what makes `verify_all.sh:88`'s anchored `sed` safe on a red run as well as a green one.

**BC-A.** Six runs: three mutant sources under the delivered filter (all `LoadRefused`, exit 2,
`os restored True`, `0 run`), one artifact-probe pair, and two round-1-filter controls. The first
pass of my own driver printed `!!! THE SHELL RAN !!!` on the delivered filter — that was **my
detector matching the refusal message**, which echoes the offending argument back verbatim
(`LoadRefused … ('echo THIS-SHELL-MUST-NOT-RUN',)`). I did not report it; I replaced the string
probe with a filesystem-artifact probe (`os.popen("touch <path>")`) and re-took both arms. Under
the delivered filter the artifact does not appear; under the round-1 filter it does. That is the
difference between a text coincidence and a side effect, and the corrected control is what the
contract cites.

**The round-1 control is the strongest single result of this stage.** Under the prefix-only
filter, a `bin/sc` whose elevate guard reads `os.getuid()` and calls `os.popen` **started a
shell** and the suite still reported `14 defined, 14 run, 14 passed`, **exit 0** — i.e. B.4 would
have been green while `verify_all` had spawned a shell out of `bin/sc`'s import on the owner's
live machine. CR-1 was not theoretical.

## Why three clauses are reported NOT-DISCRIMINATING rather than passed

**RES-3 / RS-4 (assertion 6).** Predicted before running, then measured both ways: the codec
substitution `utf-8`→`latin-1` raises `UnicodeEncodeError` on `"节点 ✓"` and kills the assertion;
deleting `encoding=` altogether leaves the run green on this UTF-8 host, because CPython's
`os.fdopen` default codec here **is** UTF-8. Insight-index lines 14/22 predicted exactly this. I
ran the wrong-way mutation on purpose so the report carries the refutation rather than the claim;
a sweep that used only the deletion would have printed a false kill and certified nothing.

**RES-4 / RS-3 (assertion 10's substring clause).** Confirmed by measurement and then by
argument. M21 embeds `json.dumps(override)` — which contains `sentinel-rule` — into the fault
clause, and the assertion fails at the **sentence-equality** check, never reaching the substring
check. The reason is structural, not fixture-specific in the way a different fixture could
repair: the equality clause demands the sentence be exactly `t("no configuration could be
produced from it ({fault})", fault="AttributeError")`, and no string equal to that can contain a
substring of the override document. So the substring clause is implied by its predecessor and no
reachable mutation can kill it alone. The assertion as a whole is discriminating (M19, M20), and
that is how it is reported.

**The two control clauses.** Assertion 4's `_eq(_mode(control), 0o400)` and assertion 7's
`_eq(json.loads(raw), {"nodes": []})` are assertions about the **fixture**, not about `bin/sc`.
No mutation of `bin/sc` can reach them, so against a `bin/sc` mutation they do not discriminate —
but their job is the opposite one: they falsify the fixture. Assertion 4's control is what turns
"0600 is exact" from an argument into an observation (a bare `mkstemp` beside the target reads
0400 under the same umask), and assertion 7's is what proves the UTF-16 bytes are JSON that a
non-explicit reader would have accepted. I report them under their own name rather than folding
them into the kill count, because counting them as kills would inflate the sweep and counting
them as vacuous would misdescribe them.

**Assertion 14.** PQ-3 predicted zero offenders and the delivered run agrees
(`182 entries in 1 table(s), 0 offenders`). I did not accept that as "passed": on today's `bin/sc`
the assertion separates no broken build from a fixed one, because there is no broken build to
separate. It is mutation-reachable (M30 kills it with one `{bogus}` placeholder), so it is a
**forward guard**, and that is the honest description.

## Things I probed that turned out fine

- **Order dependence.** All 14 run individually and pass individually, and the whole-run output
  is identical to the concatenation of the parts. `fixture()` builds a fresh sub-directory per
  assertion, so state cannot leak between them; I checked by running them individually and by
  running the whole suite 10× in parallel.
- **The `sed` extraction on a red run.** `verify_all.sh:88`'s pattern is anchored
  (`^summary: … passed$`). I exercised it on the 0-run summary (`14 defined, 0 run, 0 passed`)
  through the AC-13 case-3 run: B.4 reported `exit 1, passed='13'`, so both the exit code and the
  extraction behaved on a failing suite.
- **`$?` after a command substitution** at `verify_all.sh:96-97` (stage 5's unfiled note): B.5's
  form is correct in Bash and was exercised on both arms — PASS in every green run, and the FAIL
  arm is reached in the AC-19 driver's shape. Not a defect; left as the file's own idiom.
- **A tracer cannot attribute frames to `bin/sc`.** `python3 -m trace --count` records nothing for
  the loaded module, because `types.ModuleType("sc")` has no `__file__` and `trace`'s
  `globaltrace_lt` ignores frames whose globals lack one. I abandoned the line-coverage number
  and used a static call-surface count instead (13 of 113 named functions). Harmless, but worth
  knowing before someone tries to put a coverage gate on B.4.

## What I did not take, and why

- **No criterion needed root**, so nothing is BLOCKED and no operator obligation was added. AC-4
  is explicitly satisfied by stubbing the euid **read** — the criterion says so — and doing it any
  other way would mean running this suite as root, which is the one thing the whole task exists
  to prevent.
- **The `.ps1` mirror was read, not executed** — no PowerShell on this host, and Q-12 rules B.4/B.5
  Linux-only by subject. AC-16 is an `[S]` criterion and the extracted `(id, name)` pairs are its
  stated verification.
- **No committed test was added.** FR-1 caps the task at exactly one new committed file and
  out-of-scope 9 forbids a test directory, so my 8 scratch harnesses stay in scratch. RES-9's
  suggestion (a standing check that no `dir(os)` name outside the tuple is a known process-starter)
  is the right home for this work and belongs to a later task, not to a stage-6 edit of the
  artifact under test.

## Residuals I did not own, re-measured anyway

RES-1, RES-5, RES-8, RES-9 and RES-10 are addressed to `07_DELIVERY.md`, not here. One of them is
cheap to re-measure now and worth carrying: **RES-8** — `.harness/insight-index.md` is 30 lines
against a cap of 30 and `docs/tasks.md` is 300 against 300, both still PASS because F.4/F.5 test
`n > cap` strictly. Zero headroom stands, so stage 7's insight harvest or a new ledger row will
tip one of them; the remedy is rule 70's rotation plus a re-measurement, never a cap edit. The
other four are unaffected by anything measured here.
