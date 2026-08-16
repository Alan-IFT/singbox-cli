# 06 — Rationale · T-31 `suite-guarantee-boundaries`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

`S` = `/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/r2`.
Everything below is a full run whose ≤5-line excerpt the contract cites, or the reasoning that
chose the run. Nothing here is a requirement on a later stage.

## Upstream rationales opened, and why

- **T6.1** did not fire: `02_RATIONALE.md` was not needed — every acceptance criterion's
  verification step is spelled in the contract portion of `01`/`02`.
- **T6.2** fired once. `04_RATIONALE.md` carries the developer's own enumeration of `dir(os)`
  (402 / 22 / 2). I reproduced that measurement independently rather than reading it, by two
  methods the developer did not use (an `ast` scan of `/usr/lib/python3.12/os.py`, and reading the
  denied set directly off the shim `load()` builds).
- **T6.3** fired once. `05_RATIONALE.md` carries the reviewer's hand re-derivation of the 22 names
  and the disposition of RES-3 / RES-4 / RES-12 / RES-13 / RES-14. Those five residuals are
  addressed to me and are self-contained enough to re-measure, which is what I did; I read the
  rationale only to confirm I was measuring the same thing the reviewer means.

## Why this round's mutants were rebuilt rather than re-run

Round 4 changed `check-sc-contracts.py` by +175/−19. Round 1's mutant files were generated from
the round-3 text and no longer apply — `write()`'s `assert text.count(old) == 1` fails on three of
them. Every mutant in `## Adversarial tests` was therefore regenerated from the delivered file
(`S/gen_mutants.py`), and two were re-anchored:

- **M8 / M9** — the pair `src = sc.generate_config.__code__.co_filename` +
  `with open(src, encoding="utf-8") as fh:` occurs **twice** (`:545` in
  `every_file_read_and_write_names_utf8`, `:615` in the one-writer clause). Round 1's M9 hit both
  and killed two assertions; this round both are anchored on the clause's next line, so M9 is a
  one-point mutant and kills exactly one (`19 run, 18 passed`).
- **M4b** — round 1's shape (swap the capture and the displacement lines) has no target on the
  delivered file, because there is no capture inside `load()` any more. The equivalent hostile edit
  is to *re-introduce* one below the displacement and restore from it; that is what M4b is now, and
  it is what the delivered leak check must catch.

## Full run — the `dir(os)` enumeration (AC-3, DEF-1, RES-14)

`python3 -c "import os,sys;n=dir(os);p=('exec','spawn','fork','popen','posix_spawn','system');print(sys.version.split()[0],len(n),sum(1 for x in n if x.startswith(p)))"`

```
3.12.3 402 22
```

First method (`S/enum_os.py`) tried `inspect.getsource` on every unmatched callable and found
**nothing**, which is a false negative rather than a result: on CPython 3.11+ `os` is a **frozen**
module, so `os._execvpe.__code__.co_filename` is `'<frozen os>'` and `getsource` raises. The
contract's numbers rest on the second method, not this one.

```
getsource on os._execvpe: OSError: could not get source code   (co_filename='<frozen os>')
```

Second method (`S/enum_os2.py`), full output of the two scans:

```
-- python-level defs in /usr/lib/python3.12/os.py that reach a process-start primitive
   _execvpe       os.py:593   exec_func,execv,execve                 UNMATCHED by the tuple
   _spawnvef      os.py:853   fork,func                              UNMATCHED by the tuple
   execl          os.py:543   execv                                  matched by the tuple
   execle         os.py:550   execve                                 matched by the tuple
   execlp         os.py:558   execvp                                 matched by the tuple
   execlpe        os.py:565   execvpe                                matched by the tuple
   execvp         os.py:574   _execvpe                               matched by the tuple
   execvpe        os.py:582   _execvpe                               matched by the tuple
   spawnl         os.py:929   spawnv                                 matched by the tuple
   spawnle        os.py:938   spawnve                                matched by the tuple
   spawnlp        os.py:956   spawnvp                                matched by the tuple
   spawnlpe       os.py:966   spawnvpe                               matched by the tuple
   spawnv         os.py:880   _spawnvef                              matched by the tuple
   spawnve        os.py:889   _spawnvef                              matched by the tuple
   spawnvp        os.py:901   _spawnvef                              matched by the tuple
   spawnvpe       os.py:911   _spawnvef                              matched by the tuple

-- of those, the ones the tuple does NOT match, and are exported in dir(os):
   ['_execvpe', '_spawnvef']

-- C-level unmatched callables whose FULL doc mentions the process vocabulary
   register_at_fork       Register callables to be called when forking a new process.
   unshare                Disassociate parts of a process (or thread) execution context.
   wait                   Wait for completion of a child process.
   wait3                  Wait for completion of a child process.
   wait4                  Wait for completion of a specific child process.
   waitpid                Wait for completion of a given child process.

-- module-valued attributes of os (family (iv) by the header's own carve-out)
   ['abc', 'path', 'st', 'sys']
```

None of the six C-level hits starts a process: four wait for one, one registers callbacks around
`fork`, and `unshare` re-parents namespaces of the *calling* process. The four module-valued
attributes (`os.path`, `os.sys`, `os.abc`, `os.st`) do not start a process either — they are
routes, and the header carves them into family (iv) explicitly ("An attribute of that same `os`
which is itself a MODULE is family (iv) below, not this").

**The bound of this method, stated so no one over-reads it.** The Python half is exhaustive: I
parsed `os.py` and looked at every `FunctionDef`. The C half is a docstring scan, so a C-level
`os` function that starts a process *and* documents itself without any of `execut|new process|
child process|replace the current|spawn|fork|shell command|start a process|create a process|run a`
would escape it. I judge that residual negligible on CPython, but it is a scan, not a proof.

## Full run — half (a) read directly off the shim (AC-3)

The strongest single measurement in this round: rather than probing one name at a time, load a
scratch subject that hands its own `os` back, then compare the denied set with the matched set
(`S/half_a_direct.py`).

```
shim is the loaded module's own os : True
names bound to _no_new_process     : 22
names the tuple matches in dir(os) : 22
set equality                       : True
denied set                         : ['execl', 'execle', 'execlp', 'execlpe', 'execv', 'execve',
 'execvp', 'execvpe', 'fork', 'forkpty', 'popen', 'posix_spawn', 'posix_spawnp', 'spawnl',
 'spawnle', 'spawnlp', 'spawnlpe', 'spawnv', 'spawnve', 'spawnvp', 'spawnvpe', 'system']
private process-starters on the shim, still the REAL functions:
   shim._execvpe   -> <function _execvpe at 0x7bfbfe315ee0>
   shim._spawnvef  -> <function _spawnvef at 0x7bfbfe316b60>
os module restored                 : True | subprocess.Popen restored: True
```

Together with the enumeration above this settles AC-3 in both directions. *No less*: every public
process-start name is in the denied set. *No more*: the denied set is exactly the 22, and the two
names the text calls open are open on the object the subject actually sees.

## Full run — the three claims family (ii) makes (DEF-1)

`python3 S/priv_r2.py`:

```
=== os-_execvpe              bare python3     exit 0  marker PRESENT
    summary lines  : NONE
    refusal lines  : NONE
=== os-_execvpe              delivered suite  exit 0  marker PRESENT
    summary lines  : NONE
    refusal lines  : NONE
=== os-_spawnvef             bare python3     exit 0  marker PRESENT
=== os-_spawnvef             delivered suite  exit 1  marker ABSENT
    summary lines  : ['summary: 19 defined, 19 run, 0 passed']
    strace execve : 1
    strace clone3 : 0
    strace clone  : 1
    strace fork   : 0
    strace vfork  : 0
=== realos-path-os-_execvpe  bare python3     exit 0  marker PRESENT
=== realos-path-os-_execvpe  delivered suite  exit 0  marker PRESENT
    summary lines  : NONE
```

Read against the delivered sentence, clause by clause: "`os._execvpe` REPLACED the loading
interpreter (marker left, exit 0, no summary, no refusal)" — reproduced exactly. "`os._spawnvef`
FORKED (strace: execve 1, clone 1) before the child's exec was refused" — reproduced exactly; the
child died on the shim's `os.execv`, which is why the marker is absent while `clone` is 1, and the
19 `AttributeError` FAILs are the parent finishing its run against a module that never finished
importing. "Measured: … `os.path.os._execvpe(...)` … replaced the interpreter too, marker left,
exit 0" — reproduced exactly.

## Why CR-13 is a NIT and not a defect (my own measurement)

The clause under review is "Adding the two names would deny those two spellings **and buy
nothing**". I checked the one thing that would turn it from loose to false: whether any *public*
route reaches `_execvpe`, in which case denying the private spelling would close a real accidental
path.

```
os-execvp-PUBLIC     exit 2 marker ABSENT | ['load failed  LoadRefused: a process start …',
                                             'summary: 19 defined, 0 run, 0 passed']
os-execvpe-PUBLIC    exit 2 marker ABSENT | ['load failed  LoadRefused: a process start …',
                                             'summary: 19 defined, 0 run, 0 passed']
```

Both public callers of `_execvpe` are refused at the shim, so the private helper is reachable only
by naming it — a deliberate act, and the header's stated threat model is "an ACCIDENTAL process
start … NOT a sandbox against a subject that seeks to escape". Under that model "buys nothing" is
true of everything the guard is aimed at, and the same sentence already says what it *would* buy.
I would not have written it that way; I would not send it back either.

## Full run — the B.4 / B.6 case sweep (AC-4, AC-6, DEF-3, RES-13)

`bash S/b6_cases.sh` in `cloneA` (`HEAD` floor 19). Thirteen cases; the shape of each line is
`[B.4]`, `[B.6]`, the count of `comparison NOT performed` lines, then the run totals.

```
CASE  1  17 vs 19          [B.4] PASS  [B.6] FAIL   NOT-performed 0   PASS 19 FAIL 1 SKIP 1  exit 2
CASE  2  19 vs 19          [B.4] PASS  [B.6] PASS   NOT-performed 0   PASS 20 FAIL 0 SKIP 1  exit 0
CASE  3  20 vs 19          [B.4] FAIL  [B.6] PASS   NOT-performed 0   PASS 19 FAIL 1 SKIP 1  exit 2
CASE  4  no .git           [B.4] PASS  [B.6] SKIP   NOT-performed 1   PASS 17 FAIL 0 SKIP 4  exit 0
CASE  5  .git is a file    [B.4] PASS  [B.6] SKIP   NOT-performed 1   PASS 17 FAIL 0 SKIP 4  exit 0
CASE  6  absent at HEAD    [B.4] PASS  [B.6] SKIP   NOT-performed 1   PASS 19 FAIL 0 SKIP 2  exit 0
CASE  7  absent in tree    [B.4] FAIL  [B.6] SKIP   NOT-performed 1   PASS 18 FAIL 1 SKIP 2  exit 2
CASE  8  escaped literal   [B.4] PASS  [B.6] PASS   NOT-performed 0   PASS 20 FAIL 0 SKIP 1  exit 0
CASE  9  dup in tree       [B.4] FAIL  [B.6] SKIP   NOT-performed 1   PASS 18 FAIL 1 SKIP 2  exit 2
CASE 10  dup at HEAD       [B.4] PASS  [B.6] SKIP   NOT-performed 1   PASS 19 FAIL 0 SKIP 2  exit 0
CASE 11  018 vs 19         [B.4] PASS  [B.6] FAIL   NOT-performed 0   PASS 19 FAIL 1 SKIP 1  exit 2
CASE 12  019 vs 19         [B.4] PASS  [B.6] PASS   NOT-performed 0   PASS 20 FAIL 0 SKIP 1  exit 0
CASE 13a "nineteen"        [B.4] FAIL  [B.6] SKIP   NOT-performed 1   PASS 18 FAIL 1 SKIP 2  exit 2
CASE 13b -5                [B.4] FAIL  [B.6] SKIP   NOT-performed 1   PASS 18 FAIL 1 SKIP 2  exit 2
CASE 13c "19" (a string)   [B.4] FAIL  [B.6] SKIP   NOT-performed 1   PASS 18 FAIL 1 SKIP 2  exit 2
```

Every run wrote **0 stderr lines**. Cases 4 and 5 show 17 PASS / 4 SKIP because A.2, E.5 and B.6
all lose their history, not because anything regressed. Case 9 versus case 10 is RES-13's whole
content: when the unusable value is the working tree's, B.4 FAILs the run and B.6 goes quiet; when
it is `HEAD`'s, only B.6 goes quiet and the run is green. Both are the safe direction, and no
committed step reaches either state.

The verbatim detail line, taken separately (`bash S/b6_detail.sh`), is what AC-4 actually asserts:

```
=== tree test_count = 17, HEAD 19
[B.6] Assertion floor never below its last committed value ... FAIL
      test_count is 17 in .harness/scripts/baseline.json and 19 at HEAD — the floor only goes up
=== tree test_count = 018, HEAD 19
[B.6] Assertion floor never below its last committed value ... FAIL
      test_count is 018 in .harness/scripts/baseline.json and 19 at HEAD — the floor only goes up
```

Note the FAIL prints `018`, the file's own spelling, while the comparison used `10#018`. That is
the right choice: the message names what a maintainer will find in the file.

## Full run — the suite mutation sweep (`python3 S/drive_mutants.py`)

```
### control -- the DELIVERED suite
  D1 real bin/sc        : exit 0 | summary: 19 defined, 19 run, 19 passed
  D2 os.system probe    : marker ABSENT (exit 2)
  D2 subprocess probe   : marker ABSENT (exit 2)
  D3 in-process state   : subprocess.Popen after load() -> <class 'subprocess.Popen'>
### M1 drop half (b) entirely
  D1 exit 0 | 19 defined, 19 run, 19 passed   D2 marker PRESENT (exit 1)   D3 <class 'subprocess.Popen'>
### M2 delete the Popen restore from the finally
  D1 exit 2 | 19 defined, 0 run, 0 passed     D2 marker ABSENT (exit 2)
  D3 m.LoadRefused: a displacement made by the load did not survive its finally
### M3 move the restore out of the finally
  D1 exit 0 | 19 defined, 19 run, 19 passed   D2 marker ABSENT (exit 2)   D3 <class 'subprocess.Popen'>
### M4b reintroduce a LOCAL capture BELOW the displacement (DEF-2's shape)
  D1 exit 2 | 19 defined, 0 run, 0 passed     D2 marker ABSENT (exit 2)
  D3 m.LoadRefused: a displacement made by the load did not survive its finally
### M21 rebind REAL_POPEN inside load() (RES-11's shape)
  D1 exit 0 | 19 defined, 19 run, 19 passed   D2 marker ABSENT (exit 2)
  D3 subprocess.Popen after load() -> <function _no_new_process at 0x769f272da700>
### M5 drop 'system' from the prefix tuple
  D1 exit 0 | 19 defined, 19 run, 19 passed   D2 marker PRESENT (exit 1)
### M6 drop `mod.os is not shim` from the leak check
  D1 exit 0 | 19 defined, 19 run, 19 passed   D2 marker ABSENT (exit 2)
### M7 drop the CFG_PATH argument test      D1 exit 0 | 19 defined, 19 run, 19 passed
### M8 delete encoding= from the clause's open()   D1 exit 0 | 19 defined, 19 run, 19 passed
### M9 substitute the codec (ascii)         D1 exit 1 | 19 defined, 19 run, 18 passed
### M10 drop the single-FunctionDef check   D1 exit 0 | 19 defined, 19 run, 19 passed
### M11 remove the new name from TESTS      D1 exit 0 | 18 defined, 18 run, 18 passed
```

M4b's line is the one that closes DEF-2. Round 1's M4b gave `D1 exit 0 | 19/19/19` with
`subprocess.Popen after load() -> <function _no_new_process …>` — green run, denied `Popen` for
the rest of the process. With `REAL_POPEN` bound at import (`:161`) the same edit is caught at
`:234` before `load()` returns.

M21 is the shape that is left, and it is worth being precise about why it is a residual and not a
defect: it is not a *reorder* of existing statements, it is an added `global REAL_POPEN` assignment
inside `load()`. The code says so at the binding (`:159-160`), the reviewer filed it as RES-11, and
a mechanism against it (re-deriving the real `Popen` from a private import at assertion time) costs
more than the hazard.

M7 and M10 need their own subject to discriminate (`python3 S/m7_m10.py`):

```
=== M7 (no CFG_PATH argument test) against mut-os-replace
    delivered : exit 1 | summary: 19 defined, 1 run, 0 passed
    M7        : exit 0 | summary: 19 defined, 1 run, 1 passed
=== M10 (no single-FunctionDef check) against a TWO-def subject
    delivered : exit 1 | summary: 19 defined, 1 run, 0 passed
    M10       : exit 0 | summary: 19 defined, 1 run, 1 passed
```

Both discriminate; neither is killed by anything `verify_all` runs, so both are reported as
surviving the committed controls.

## Full run — the `verify_all` mutation sweep (`bash S/mutants_va.sh`)

```
=== unmutated control
-- pre-commit  (19 vs 18): [B.4] PASS   [B.6] PASS
-- post-commit (19 vs 19): [B.4] PASS   [B.6] PASS
=== MUTANT: equality
-- pre-commit  (19 vs 18): [B.6] FAIL  test_count is 19 … and 18 at HEAD — the floor only goes up
-- post-commit (19 vs 19): [B.6] PASS
=== MUTANT: flip
-- pre-commit  (19 vs 18): [B.6] FAIL  test_count is 19 … and 18 at HEAD — the floor only goes up
-- post-commit (19 vs 19): [B.6] PASS
=== MUTANT M22: the 10# pinning removed, tree floor 018 vs HEAD 19
-- M22 (unpinned): [B.4] PASS  [B.6] PASS
-- delivered:      [B.4] PASS  [B.6] FAIL  test_count is 018 … and 19 at HEAD
=== MUTANT M23: floor_of's shape test removed, DUPLICATED test_count
-- M23 (no shape test): [B.4] PASS  [B.6] PASS
-- delivered:           [B.4] FAIL  [B.6] SKIP
                        comparison NOT performed: no single readable test_count …
=== MUTANT M14: redirection order swapped, baseline.json ABSENT
-- mutant stderr : 2 line(s)
.harness/scripts/verify_all.sh: line 99: .harness/scripts/baseline.json: No such file or directory
.harness/scripts/verify_all.sh: line 125: .harness/scripts/baseline.json: No such file or directory
-- delivered stderr: 0 line(s)
=== MUTANT M11 under verify_all B.4 (cloneA, floor 19)
[B.4] bin/sc contract assertions ... FAIL
      18 assertion(s) passed, floor is 19
  FAIL: 1
```

And M15, which round 1 declined to run (`bash S/m15.sh`), at the state that makes B.6 FAIL:

```
-- delivered, tree 17 vs HEAD 19:
[B.6] … FAIL
      test_count is 17 in .harness/scripts/baseline.json and 19 at HEAD — the floor only goes up
-- M15 (detail dropped), same state:
[B.6] … FAIL
```

**The observation I would carry forward.** M22 and M23 are mutants of the two lines that closed
round 1's DEF-3, and both leave `verify_all` completely green — because the only states that
discriminate them (a leading-zero floor, a duplicated key) are states no committed step creates.
That is not a defect: `verify_all` is the root of this project's trust chain, and a control on the
control would be an infinite regress. It *is* worth a filed row, in the same class as RES-4, so
that a future editor of `floor_of()` knows the shape test and the two `10#` pins are load-bearing
and unguarded.

## Full run — BC-4's blind spot (`bash S/bc4.sh`)

```
HEAD floor: "test_count": 5  tree floor: "test_count": 5
[B.4] bin/sc contract assertions ... PASS
[B.6] Assertion floor never below its last committed value ... PASS
  PASS: 20   WARN: 0   FAIL: 0   SKIP: 1
```

Nineteen assertions passing against a committed floor of five, everything green. B.6 answers "did
*this change* lower the floor", never "is this floor honest", exactly as `baseline.json`'s `notes`
and the B.6 comment (`verify_all.sh:116-121`) both say.

## Full run — AC-7, AC-8, AC-13 supporting output

`python3 S/ac7_zh.py`:

```
delivered suite  x  zh-DESTROYED bin/sc        exit 0 | summary: 19 defined, 19 run, 19 passed | FAILs 0
zh-fixture suite x  zh-DESTROYED bin/sc        exit 0 | summary: 19 defined, 19 run, 19 passed | FAILs 0
zh-fixture suite x  unmutated  bin/sc          exit 0 | summary: 19 defined, 19 run, 19 passed | FAILs 0
delivered suite  x  unmutated  bin/sc          exit 0 | summary: 19 defined, 19 run, 19 passed | FAILs 0
```

`strace` over a full B.4 run — the whole file, two lines:

```
3957382 execve("/usr/bin/python3", ["python3", ".harness/scripts/check-sc-contra"...], 0x7ffc00695700 /* 45 vars */) = 0
3957382 +++ exited with 0 +++
```

`strace` over B.5, by callee:

```
      2 execve("/usr/bin/wc"      1 execve("/usr/bin/sort"    1 execve("/usr/bin/sed"
      1 execve("/usr/bin/grep"    1 execve("/usr/bin/dirname" 1 execve("/usr/bin/bash"
```

`bash S/ac13.sh` (the stack facts behind AC-13 and NFR-3):

```
--- modes:        755 .harness/scripts/check-sc-contracts.py
--- added lines using an f-string or a walrus (3.6 floor):   (nothing)
--- import lines added or removed:                           (nothing)
--- name status:  M ×8, no A, no D        --- untracked: ?? docs/features/suite-guarantee-boundaries/
--- py_compile OK     --- bash -n OK      --- len(TESTS) = 19     --list = 19
```

Family (iii)'s closing sentence (`python3 S/family_iii.py`), which I checked rather than accepted:

```
argparse 0 · base64 0 · copy 0 · hashlib 0 · http.client 0 · io 0 · socket 0 · stat 0
subprocess 8 hit(s): line 20 Popen(...) · line 104 from _posixsubprocess import fork_exec
time (no source: C module) · urllib.parse 0 · urllib.request 0
```

## The C-10 count, line by line

`verify_all.sh` (+38/−2): hunk 1 adds 16 lines — 11 comment, 1 blank, **4 executable**
(`floor_of() {`, the `local v; v=$(sed …)`, the shape test, `}`). Hunks 2 and 3 are −1/+1 rewrites
(B.4's read, B.4's `10#` pin) at 0 net. Hunk 4 adds 20 — 9 comment, 1 blank, **10 executable**
(`b6_now`, `b6_was`, `if`, `step SKIP`, `echo`, `elif`, `step FAIL`, `else`, `step PASS`, `fi`).
E-4 = **14**.

`check-sc-contracts.py` (+175/−19): the two docstring hunks (+81, +30) are prose at 0. `REAL_POPEN`
adds 6 comment + 1 blank + **1 executable**; the `load()` hunk adds 3 comment + **1 executable**;
the `finally` hunk is −3/+4, so **1 executable** net and three rewrites. E-1 = **3**. The clause
hunk adds 43 — 1 `def`, ~26 docstring, 13 body, 2 blank — so E-2 = **14**. The `TESTS` row is
−2/+2. `_no_new_process`'s message is −3/+3.

**3 + 14 + 14 = 31**, against NFR-2's cap of 40. Round 1 counted 30 because round 3's `floor_of()`
was three lines; the added line is the shape test, and it is the line that turns two fail-open
comparisons into fail-closed ones. If the total had crossed 40 I would have filed it as blocking
rather than re-priced the cap.

## The C-11 reading, taken by set difference

`git show HEAD:docs/dev-map.md` is 190 lines; the worktree's is 277. Counting line-instances
present in `HEAD` beyond their multiplicity in the worktree gives exactly four:

```
total deleted line-instances: 4
  HEAD:137    capability too: on the shim, **every process-start name in `dir(os)`** must raise — `exec*` /
  HEAD:138    `spawn*` / `fork*` / `system`, **and** `popen` (it runs `/bin/sh -c`) and `posix_spawn*` (3.8+),
  HEAD:139    which begin with none of the first three. A name prefix is not a capability either: that list
  HEAD:140    is the whole guarantee, so a name a future CPython adds to `os` belongs in it.
```

All four are inside the two sentences this task falsified. Everything else in the file — including
the fenced recipe block, now at `:204-214`, the "nine path constants" clause at `:216`, and R-77 /
R-78 / R-84 at `:236` / `:239` / `:240` — survives byte-identical, which is what I-10 / K-12
require and what CR-10 is about.

## Stability detail: the suite's 11 stderr lines

Round 1 measured `verify_all`'s stderr (0 lines) but not the suite's own when run directly. It
writes 11 lines, all of them `bin/sc`'s translated warnings from the four `generate_config` arms
of `config_reaches_disk_only_when_the_checker_did_not_reject`:

```
⚠️  4/4 rule-sets unusable (geoip-cn (missing), …) — degraded to no-splitting mode: …
⚠️  /tmp/sc-contract-XXXX/checker-verdict-rejected/config.json was modified outside sc — …
⚠️  /tmp/sc-contract-XXXX/checker-verdict-rejected/config.json was left unchanged — `sing-box check` rejected …
⚠️  /tmp/sc-contract-XXXX/checker-verdict-cannot-run/config.json was installed without being checked — … [Errno 8] Exec format error …
⚠️  Could not write /tmp/sc-contract-XXXX/…/config.json: No such file or directory
```

Normalising the `mkdtemp` root gives **one** distinct digest over ten runs, so this is stable
output, not a flake. The `Exec format error` line is not a process start: `_CheckerStub`
(`:798-799`) replaces `sc.subprocess` for that arm, and the `strace` over the same run shows
`clone 0`. B.4 captures the suite with `2>&1`, which is why `verify_all`'s own stderr is 0.

## Safety ledger for this round

- Every escape subject was a scratch file under `S/subjects/`; the target was always
  `/usr/bin/touch <marker under S/markers/>`. `bin/sc` was read, never written
  (`sha256sum` identical at three checkpoints); `/usr/local/bin/sc` was never named as a subject.
- Every destructive case ran in `S/cloneA` or `S/cloneB`, both created fresh this round. The real
  repository's `baseline.json` floor was never lowered; `git diff --numstat` is identical at both
  ends of the round.
- `systemctl show sing-box -p MainPID -p NRestarts -p ActiveEnterTimestamp` at start, middle and
  end: `MainPID=2566751`, `NRestarts=0`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`, three
  times. `is-active` was never invoked. `/etc/sing-box` and `/var/lib/sing-box` listings unchanged.
- No `sudo`, no writes outside the scratchpad, no commit, and `HARNESS_ALLOW_OUTSIDE_RM` was never
  set — `guard-rm.sh` blocked one command in this round (the sixteenth overall) and the fix was to
  move the shell text into a file, as the rule says.
