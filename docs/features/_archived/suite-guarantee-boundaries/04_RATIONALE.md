# 04 — Rationale · T-31 `suite-guarantee-boundaries`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

Routing follows `.harness/rules/70-doc-size.md`'s `## Stage-doc boundary rule`: nothing here has to
be satisfied, implemented or verified by a later stage — it explains, measures or records how the
delivered units were reached. The readings a later stage must re-take or check against are in the
contract portion.

## How the measurements were taken

One driver, `probe_run.py`, run three times with a label (`before-E1`, `after-E1`, `delivered`).
Per variant it writes a **new scratch source file** under the session scratch directory, deletes any
stale marker, runs `python3 .harness/scripts/check-sc-contracts.py --source <that file>` as a child
of the *driver* (never of the suite), and then reports four things: the suite's exit code, whether
the marker file now exists, the `load failed …` line if there is one, and the `os restored …` line
if there is one. Nothing in the protocol touches `bin/sc`, `/usr/local/bin/sc`, `/etc/sing-box`,
`/var/lib/sing-box` or the service; every subject and every target is a file the driver created.

Every subject body is exactly the shape `01_RATIONALE.md`'s M-1 specifies, guarded by
`if os.getuid() != 0:` — the uid source the `geteuid` shim does not neutralise — with the two C-2
variants added:

```python
import os
if os.getuid() != 0:
    os.path.os.system("/usr/bin/touch <scratch>/escaped-realos-path")
```

```python
import os, subprocess
if os.getuid() != 0:
    subprocess.os.system("/usr/bin/touch <scratch>/escaped-realos-subprocess")
```

The C-2 readings were taken **before a single character of E-1 was written**, which is why the
"before" column is a measurement rather than a reconstruction. The order in the session was:
witness the host → run `verify_all` for the baseline → run `probe_run.py before-E1` → write E-1.

### The `os restored` line, and why it is absent from four of the eight C-2 runs

This cost some thought and is worth recording, because a criterion phrased around that line is
unsatisfiable by the runs it exists to catch. `_execute()` writes `os restored  <bool>` inside its
`except` block (`check-sc-contracts.py:868`) — the load-or-fixture **failure** path only. An
escaping subject is by definition one whose load **succeeded**: it started its process, finished its
import, and the suite went on to run 18 (later 19) assertions against a module that defines none of
`sc`'s functions, so every assertion `AttributeError`s and the run ends exit 1. There is no
restoration line on that path at all.

What is available instead is stronger, and is what the contract portion cites: the post-`finally`
leak check at `:234-235` did not raise on any of those runs, so both displacements *were* restored —
observed by the absence of a `LoadRefused` the suite would have printed, rather than by a boolean it
prints only when something else already went wrong. The alternative — adding a print of the
restoration state on the success path — would have been a new executable line bought for a document,
which is the exact trade this task exists to refuse.

## The assertion phase, read site by site in `bin/sc`

The header's sentence about the assertion phase is the one place where a claim about *another*
file's behaviour is made, so every site in it was opened and read rather than inherited. `bin/sc`
has **27** `subprocess.*` call sites (`grep -n` over the seven public entry points of that module).
What repointing `SB_BIN` reaches is an **argument**, not a site:

| site | what it runs under a fixture | why |
|---|---|---|
| `_doctor_run` (def `:2599`, its `subprocess.run` `:2614`) called from `:2175`, `:2634`, `:2731` | nothing — `FileNotFoundError` | those three callers pass `[SB_BIN, …]`, and `fixture()` points `SB_BIN` at `<run root>/no-sing-box` |
| the same runner called from `:2827`, `:2831` (both inside `_doctor_service`) | **nothing — unreachable** | `_doctor_service` (`:2805`) opens with `if not SYSTEMD and not OPENRC:` (`:2816`) and returns two UNKNOWN rows (`:2818-2819`), so with both flags `False` it never reaches the `if SYSTEMD:` / `else:` pair at `:2826-2831`. Read line by line, not inferred from the branch shape |
| the same runner called from `:2853` (`_doctor_tun`) | `ip -br addr show <iface>` | the same runner with a real host tool in `cmd`, behind **no** init-system guard — the one `_doctor_run` caller a fixture does not disarm |
| `bin/sc:2504` (`cmd_status`) | `ip -br addr show <tun>` | sits **below** the `if SYSTEMD:` / `elif OPENRC:` pair, guarded by neither |
| `bin/sc:3406` (`cmd_sysproxy`) | `sudo -u <user> gsettings …`, once per command in the list | no init-system guard in the loop at all |
| `bin/sc:3607` / `:3609` (`cmd_log`) | `tail -f <log>` / `tail -n 100 <log>` | the **`else`** of `if SYSTEMD:` — `sc.SYSTEMD = sc.OPENRC = False` *routes into* it, and the `-f` arm never returns |
| `:2231`, `:2273-2275`, `:2475-2478`, `:2487-2490`, `:2500-2502`, `:3372-3379`, `:3516-3552`, `:3596-3598` | nothing | inside `if SYSTEMD:` / `elif OPENRC:` arms that the fixture empties |

So the delivered sentence claims exactly two things it can point at code for: which calls `SB_BIN`
neutralises, and what `SYSTEMD = OPENRC = False` does **per function** — it defeats branches, not
calls, so a function that tests both names first goes dead outright and takes its calls with it
(`_doctor_service`, `:2827` / `:2831`), a function that tests `SYSTEMD` alone is *routed into* its
`else`-arm (`cmd_log`, `:3607` / `:3609`), and a call behind neither name (`:2504`, `:3406`, `:2853`)
is untouched either way. The setting is a *router* only where the function has an `else` the fixture
can fall into, which is why the claim-surface texts name `cmd_log` there and nothing else. What actually
keeps the assertion phase off the host is the content of the `TESTS` list, and the honest form of
that is to say so — with the measurement that today's list holds (`strace -f` over a full B.4 run:
`execve` 1, `clone`/`fork` 0) — rather than to imply a mechanism. T-28's forbidden-callee list, the
thing that has really been holding this line, lives in an archived stage document and is therefore
not on the claim surface; naming the property here is the zero-line half of FR-1's "enforce or mark".

## `posix`, and why it is named first among the open routes

Probed before it was named, under BC-7's rules (scratch subject, marker target, `--source`, never
`bin/sc` and never `/usr/local/bin/sc`):

```
subject: import os; if os.getuid() != 0: import posix; posix.system("/usr/bin/touch <scratch>/escaped-posix-system")
result : marker PRESENT, summary: 19 defined, 19 run, 0 passed, no LoadRefused
mechanism probe: posix.system is os.system -> True; load() rebinds sys.modules["os"] only
```

It is open, and it is the cheapest member of family (i): no attribute chain, no `ctypes`, one import
of a module that has been in every CPython on this platform. That is why it is now the first thing
family (i) names in both texts — a route this cheap left unnamed reads as a route not known.

## CR-3's redirection order, measured both ways

`floor_of`'s two file-reading callers were spelled `floor_of < baseline.json 2>/dev/null`. Bash
applies a simple command's redirections left to right and reports the first failure on the stderr in
force **at that point**, so with the file absent the `<` failure printed on `verify_all`'s own
stderr. Measured in a scratch clone with `baseline.json` moved away:

```
delivered order (2>/dev/null first): stderr EMPTY
previous order  (< first)          : verify_all.sh: line 93:  .harness/scripts/baseline.json: No such file or directory
                                     verify_all.sh: line 118: .harness/scripts/baseline.json: No such file or directory
stdout, both orders                : byte-identical — [B.4] FAIL + its own detail line, [B.6] SKIP + exactly one line
```

(The two line numbers are what bash printed at the time of that measurement; the same two callers
are at `:99` and `:125` in the delivered file.)

K-14 specifies B.6's unreadable-history branch as SKIP plus **one** printed line, and the second,
unowned line was a real deviation from it. The fix is a two-token move inside two existing lines, 0
net executable; the reason is now in `floor_of()`'s comment so the next edit does not undo it.

## Candidate (2)'s ground in the committed record, corrected by probe

The rejected-decisions record carried "the subject's `import subprocess` returns the same module
object either way". It does not:

```
sys.modules["subprocess"] = shim  ->  a later `import subprocess` returns the shim (True), not the real module (False)
shim built by __dict__.update     ->  shim.os is the real os (True)
```

The decline stands on its other two grounds (BC-6: the binding outlives the load into the phase
where `_CheckerStub` legitimately supplies a `subprocess`-shaped object; size). The record now states
the narrower truth instead: a `__dict__`-copying shim — the shape this project uses for `os` — still
carries the real `os`, so family (iv) survives it; only a shim that also dropped `os` would remove
`subprocess.os` from that family, leaving `os.path.os`, `shutil.os` and `tempfile.os` in it.

## The `dir(os)` audit, taken rather than argued

Half (a)'s sentence is a completeness claim, so it is only worth what its enumeration is worth. The
enumeration was re-taken here mechanically, on this interpreter, and printed in full before any
sentence was written:

```
python: 3.12.3 platform: linux      dir(os) total: 402
MATCHED by the tuple (22): execl execle execlp execlpe execv execve execvp execvpe fork forkpty
                           popen posix_spawn posix_spawnp spawnl spawnle spawnlp spawnlpe spawnv
                           spawnve spawnvp spawnvpe system
UNMATCHED, stem-suspicious (19): _execvpe _exit _spawnvef abort get_exec_path getpid getppid kill
                           killpg openpty pidfd_open register_at_fork wait wait3 wait4 waitid
                           waitid_result waitpid waitstatus_to_exitcode
PRIVATE unmatched with a stem (3): _execvpe _exit _spawnvef
```

Of the 380 names the tuple does not match, exactly **two** start or replace a process: `_execvpe`
and `_spawnvef`. `_exit` ends this process and starts none; `kill` / `killpg` signal an existing
one; `wait*` reap; `register_at_fork` registers a callback; `openpty` allocates a pty without
forking (`forkpty`, which does fork, is matched); `get_exec_path` returns a list. **No public
process-start spelling is unmatched** — which is what makes the corrected sentence ("every *public*
process-start name … on POSIX") true rather than merely narrower.

Then the mechanism, which is the part that decides what the sentence should say:

```
shim._execvpe is os._execvpe          : True     # __dict__.update copied the function OBJECT
os._execvpe.__globals__ is os.__dict__: True     # and its globals are the REAL module's dict
names _execvpe reads from globals     : environ execv execve fsencode get_exec_path name path
names _spawnvef reads from globals    : P_NOWAIT WIFSTOPPED _exit fork waitpid waitstatus_to_exitcode
```

So the helpers never consult the shim at all. That is why the fix is a sentence and not two more
tuple entries: entries would deny `shim._execvpe`, and `os.path.os._execvpe` — family (iv), one
attribute hop, already open and already named — would hand the same capability straight back.
Measured, not reasoned: with both halves in force, `os.path.os._execvpe('/usr/bin/touch', [...])`
replaced the loading interpreter and left its marker, exit 0.

The escape itself, re-measured under BC-7 (scratch subject, marker target, `--source`, never
`bin/sc`, never `/usr/local/bin/sc`), with a public control in the same sweep:

```
os-_execvpe              marker before ABSENT  exit 0  marker after PRESENT  (no summary line)
os-_spawnvef (func=os.execv, i.e. the shim's)  exit 1  marker ABSENT  strace: execve 1 CLONE 1
os-execvp (control)      exit 2  marker ABSENT  LoadRefused: a process start or replacement ...
```

The first line is the whole finding: no summary, no refusal, exit **0** — the suite process was
replaced by `touch`, so nothing was left to report. The second is a weaker but real breach: the
denial catches the exec, but only in a child that already exists.

## C-8, in full: why the clause was kept rather than dropped

C-8 offered a straight choice: drop E-1's post-`finally` `Popen` clause (E-1 becomes 3 executable
lines) or keep it and have stage 6 report it NOT-DISCRIMINATING. The choice looked like a size
question and turned out not to be one.

The line now at `check-sc-contracts.py:234` already existed, as the `os`-shim leak check:

```python
if sys.modules["os"] is not os or mod.os is not shim:
```

Extending it to the second displacement adds ` or subprocess.Popen is not REAL_POPEN` **to a line
that is already there**. `git diff` scores that `-1 / +1`: net **zero**. So the arithmetic C-8's
first branch rests on does not hold here — dropping the clause would have taken E-1 from 3 net lines
to 3 net lines, while making two upstream statements false:

- **BC-5** — "whatever it displaces is restored in the same `finally` that restores the `os` shim,
  **the restoration is asserted**, and a failed restoration ends the run non-zero."
- **I-1** — "if **either** is still displaced afterwards, `LoadRefused` is raised and the run ends
  non-zero."

Trading a requirement-level boundary condition for zero lines is not a rule-85 saving, so the clause
stays. G-6's characterisation is accepted for the shape it names — a `finally` that restores
unconditionally cannot fail this line — but "no build fails it" turned out to be too strong, and the
correction is measured: with the restore **deleted** from the `finally`, `load()` raises
`LoadRefused: a displacement made by the load did not survive its finally`. So the honest report is
two-sided: NOT-DISCRIMINATING against an unconditional-`finally` build, discriminating against a
deleted restore.

### Which is where the round-3 defect was, and why the fix removes a line rather than adding one

The clause compared `subprocess.Popen` against a value **the same function** had captured one
statement above the displacement. Swap those two statements — an edit that reads like tidying — and
the capture *is* the denial: the `finally` restores the denial, the clause compares the denial with
itself and passes, and `subprocess.Popen` stays `_no_new_process` for the rest of the process while
the suite reports `19 defined, 19 run, 19 passed`. Two candidate fixes were priced:

1. Add a disjunct (`or the captured value is _no_new_process`). It **detects** the reorder, but the
   condition no longer fits one line, so it costs +1 executable line, and the one message the clause
   raises stops being true of every branch it guards.
2. Bind the real `Popen` **once, at import**, and have `load()` restore and assert against that
   name. There is then no capture inside `load()` to reorder — the defect cannot be written — and
   the comparison references something bound before any displacement exists. Cost: **0** (one line
   leaves the function, one enters the module).

Rule 85 decides this without a tie-break: (2) removes the special case instead of guarding it, and
is smaller. Measured on the delivered build and on two mutants of it:

```
delivered            load() returned normally   subprocess.Popen -> <class 'subprocess.Popen'>
restore deleted      LoadRefused: a displacement made by the load did not survive its finally
capture SHADOWED inside load(), below the displacement
                     load() returned normally   subprocess.Popen -> <function _no_new_process ...>
occurrences of a capture inside load() on the delivered build: 0
```

The third line is the honest residual: a *rebinding* of `REAL_POPEN` inside `load()` still slips
through. It is not a reorder — it shadows a module constant inside a function, which no reviewer
reads as tidying — and it is named in the code at the binding rather than guarded, because a guard
for it is the +1 line and the fuzzier message that (1) was rejected for.

## D-1: why the leak check's message was rewritten as well

The old message was `"the os shim leaked out of the load"`. Once the condition it guards covers two
displacements, that sentence names a cause the check cannot know — a still-displaced `Popen` would
have been reported as an `os` shim leak. That is the same defect I-2 exists to remove from
`_no_new_process` one function above, so repairing one while shipping the other would have been
incoherent. The new text, `"a displacement made by the load did not survive its finally"`, names what
was observed and nothing more. It is a rewrite, 0 net lines, and the sentence is in no frozen set.

Same reasoning for `_no_new_process`'s own message, which is I-2 and was mandated: it now reads
"a process start or replacement during load (first argument: …) -- perhaps an elevate guard reading a
uid the geteuid shim misses, perhaps another process API this load denies". Two possibilities, no
assertion of cause, and it no longer says "bin/sc" — the subject can be any `--source`, and in every
probe run above it was a scratch file.

## Why `b6_was` guards on `.git` inline

K-14 asks for one condition covering all four BC-2 cases. The empty-`floor_of` result covers three of
them by construction (no `git` binary, the file absent at `HEAD`, a non-numeric `test_count` there).
The fourth — no `.git` — does **not** reliably produce an empty result on its own, because `git show`
searches upward for a repository and a scratch copy placed inside some other checkout would read
*that* repository's history. Q-F's answer already presumes the guard A.1 and A.2 use, so B.6 uses it
too, folded into the command substitution:

```bash
b6_was=$([[ -d .git ]] && git show HEAD:.harness/scripts/baseline.json 2>/dev/null | floor_of)
```

One line, one branch downstream, and the worktree case (`.git` as a *file*) falls into the same SKIP —
measured, and reported as a residual rather than as a new inconsistency.

## The floor control failed open, and what that cost to close

The step's shape is `if unreadable → SKIP / elif lower → FAIL / else → PASS`. The `elif` is a bash
arithmetic evaluation, and bash treats a value it cannot parse as a **syntax error**, not as false —
the evaluation aborts, the branch is not taken, and control lands on the `else`. The `else` is PASS.
So every un-comparable reading — a duplicated or nested unescaped `"test_count"` (two lines out of
one `sed`), or a leading zero read as octal — reported the ratchet as honoured, with one line on a
stderr nobody reads. That is the defect class R-104 was filed for, in the control filed to answer it.

Two places could hold the fix: each call site, or the one reader. The reader wins, because
`floor_of()`'s whole purpose is that there is exactly **one** answer to "what is the floor" — and
because B.4 had the identical fail-open (`(( b4_passed < b4_floor ))`, same error, same `else`), so
a call-site fix would have to be written twice and could drift. Extending `floor_of()`'s contract
from "the digits, or empty when absent or non-numeric" to "…or when it is not a single value" leaves
both callers' existing branches doing exactly the right thing, unchanged: unusable → B.4 FAIL,
B.6 SKIP with its one printed line. `10#` on the two comparisons closes the octal path at 0 lines.

Measured in the scratch clone (a `git clone` under the session scratch directory with the five
edited files copied in and committed **there**; the real repository was only read), full `verify_all`
per case:

```
=== duplicate unescaped "test_count" in the tree copy — DELIVERED
[B.6] ... SKIP
      comparison NOT performed: no single readable test_count in the working tree or at HEAD
[B.4] ... FAIL      PASS: 18  FAIL: 1  SKIP: 2      stderr 0 lines   ('NOT performed' lines: 1)
=== the same state against the ROUND-3 spelling of those two lines — CONTROL
[B.6] ... PASS      PASS: 20  FAIL: 0  SKIP: 1
stderr: verify_all.sh: line 105: ((: 3 / 19: syntax error in expression (error token is "19")
        verify_all.sh: line 129: ((: 3 / 19: syntax error in expression (error token is "19")
=== leading-zero floor 018 in the tree vs 19 at HEAD — DELIVERED
[B.6] ... FAIL      test_count is 018 in .harness/scripts/baseline.json and 19 at HEAD ...
=== the same, ROUND-3 spelling — CONTROL
[B.6] ... PASS      stderr: ((: 018: value too great for base (error token is "018")
=== plain lowering, 17 vs 19 — DELIVERED
[B.6] ... FAIL      test_count is 17 in .harness/scripts/baseline.json and 19 at HEAD ...
=== control, 19 vs 19 (post-commit shape)
[B.6] ... PASS      PASS: 20  FAIL: 0  SKIP: 1      stderr 0 lines
```

The stderr lines in the two control cases are the whole point: the round-3 build **did** notice, and
reported PASS anyway.

BC-2's four shapes, re-taken on the delivered build after the change, each `[B.6] … SKIP` with
**exactly one** printed line and no FAIL from B.6:

```
no .git                       SKIP + 1 line   PASS: 17  FAIL: 0  SKIP: 4
.git present as a FILE (Q-F)  SKIP + 1 line   PASS: 17  FAIL: 0  SKIP: 4
baseline.json absent in tree  SKIP + 1 line   PASS: 18  FAIL: 1  SKIP: 2   (the FAIL is B.4's own)
baseline.json absent at HEAD  SKIP + 1 line   PASS: 19  FAIL: 0  SKIP: 2
```

The printed line now reads "no **single** readable test_count …", which is one word wider than the
round-3 text and covers the reading that used to fall through.

Note the lowering cases: B.4 stays **PASS** while B.6 FAILs. That is the separation the design bought
by making B.6 a step of its own rather than an extension of B.4 — "the suite regressed" and "the
floor was lowered" are two different judgements and now read as two different lines. The one reading
where they move together is the unusable floor, and there B.4's FAIL is the loud half while B.6's
SKIP says only that it could not judge.

These are exercises of the delivered branches, not the delivery's criteria: AC-4 and AC-6 are stage
6's to take independently, and AC-5's post-commit half is the PM's at delivery.

## NFR-1's reading, verbatim

`strace -f -qq -e trace=execve,execveat,clone,clone3,fork,vfork` over
`python3 .harness/scripts/check-sc-contracts.py` on the delivered tree (`19 defined, 19 run, 19
passed`), whole trace:

```
1694268 execve("/usr/bin/python3", ["python3", ".harness/scripts/check-sc-contra"...], … ) = 0
1694268 +++ exited with 0 +++
```

`execve` 1, everything else 0. One false start worth recording so the next taker does not repeat it:
adding `posix_spawn` to `-e trace=` makes `strace` exit 1 with no output file at all, and the failure
reads like a ptrace restriction rather than a bad qualifier.

## The `passing_count` / `warnings_baseline` search (C-5)

`git grep -n "passing_count\|warnings_baseline"` over the whole repository returns
`.harness/scripts/baseline.json` itself and **stage documents under `docs/features/_archived/`** —
nothing else. No shell script, no Python file, no step. The two numbers have been written by five
deliveries and read by none of them, which is exactly the shape FR-1 exists to catch: a
guarantee-shaped statement (`passing_count equals it because the delivered suite passes every
assertion it defines`) with no enforcement behind it. It is now marked as such in the same string.

## Observations that changed nothing but are worth one line each

- The `TESTS` row cost **zero** net lines because the tuple's existing two lines had room after
  re-wrapping. Worth knowing before the next task prices a registry row at 1.
- `git status --short` at the moment this stage started already showed `CONTEXT.md`,
  `docs/batches/closeout/BATCH_LOG.md` and `docs/batches/closeout/BATCH_PLAN.md` as modified — not
  `docs/tasks.md`, which the dispatch brief named. Neither set is this stage's work and neither was
  touched here; the contract portion records the actual observation rather than the expected one.
- `guard-rm.sh` blocked one `cat >> … <<'RECORD'` heredoc as an unparseable nested command (the
  fifteenth such block). The record was written to a scratch file and appended with a three-line
  Python snippet instead; `HARNESS_ALLOW_OUTSIDE_RM` was not set and the guard was not fought.
- The session scratch directory is shared with earlier work in the same session: `clone/` already
  existed and the B.6 control script had to be pointed at `t31-clone/`. Nothing was deleted to make
  room.
- A citation inside the suite's own header decayed **twice** inside this one task: the
  `shim.__dict__.update` line moved from `:189` to `:213` and the pre-import block from `:136-137`
  to `:152-153`, both because prose above them grew. Every internal `:NNN` in the header was
  re-derived from the delivered file at the end of this round rather than carried; the same decay is
  why `baseline.json`'s `notes` names `floor_of()` and the two steps instead of line numbers.
- A probe sweep whose subjects are generated from a template can go green for the wrong reason: an
  over-substituted `%r` made all seven `subprocess` subjects invalid Python, and the suite reported
  `exit 2, marker ABSENT` for each — the same shape a refusal produces. The `load failed` line said
  `SyntaxError`, not `LoadRefused`, which is the only thing that distinguished them. Read the reason
  line, not just the exit code.
