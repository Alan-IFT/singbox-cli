> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Scope of this round

Round 2 returned `APPROVED WITH MINOR FINDINGS`. Stage 6 then returned `CHANGES REQUIRED` and round 4
changed executable lines after that approving verdict, so this round re-establishes the gate over
what round 4 touched and what it could have broken. Settled findings are not re-litigated; the two
findings that survive are one carried by my own round-1 ruling (CR-10) and one introduced by round 4
(CR-13).

Rationale triggers fired and honoured: **T5.2** (adjudicating the developer-recorded drifts D-4 and
D-5) and **T5.3** (a reuse-correctness ruling on the decline of `os._execvpe` / `os._spawnvef`) —
`04_RATIONALE.md` read at both. **T5.1** did not fire: no design-fidelity finding remains.

## DEF-1: re-deriving half (a)'s completeness claim without the developer's script

The developer's evidence is a printed audit (`04_RATIONALE.md:139-176`). Accepting a completeness
claim on the strength of the script that produced it is the failure this task exists to stop, so I
re-derived the load-bearing half from CPython's own source at `/usr/lib/python3.12/os.py` and from
what `posix` exports on Linux.

**What the tuple matches.** `load()`'s predicate is
`name.startswith(("exec", "spawn", "fork", "popen", "posix_spawn", "system"))` (`:216`). Over
`dir(os)` on POSIX that is exactly:

```
exec*    (8) execl execle execlp execlpe execv execve execvp execvpe
spawn*   (8) spawnl spawnle spawnlp spawnlpe spawnv spawnve spawnvp spawnvpe
fork*    (2) fork forkpty
popen    (1) popen
posix_*  (2) posix_spawn posix_spawnp     <- begins with none of the first three
system   (1) system
             ---- 22
```

That reproduces the delivered sentence's "the tuple matches 22" exactly, from source rather than from
the audit — which is the figure the claim actually leans on. The `os.py` anchors: `execl` … `execvpe`
at `:543-591`, `_execvpe` at `:593`, `_spawnvef` at `:853`, `spawnv` … `spawnlpe` at `:880-978`,
`popen` at `:984`.

**Whether any public process-starter is unmatched.** Walking the process-affecting surface of `posix`
+ `os.py`: `execv` / `execve` / `fork` / `forkpty` / `posix_spawn` / `posix_spawnp` / `system` are all
matched; `os.py` adds only `exec*`, `spawn*`, `popen` and the two private helpers. The remainder that
looks process-ish does not start one — `_exit` ends this process, `abort` raises SIGABRT in it,
`kill` / `killpg` signal an existing one, `wait*` reap, `register_at_fork` registers a callback,
`openpty` allocates a pty **without** forking (`forkpty`, which does fork, is matched),
`get_exec_path` returns a list, `pidfd_open` opens a descriptor onto a process that already exists.
`startfile` is Windows-only, which is the other scope. **No public spelling is unmatched.** That is
what makes the delivered sentence true rather than merely narrower, and it is the difference between
this round's prose and round 3's.

**Why the two private helpers escape, checked at the mechanism rather than taken on trust.**
`shim.__dict__.update(os.__dict__)` (`:213`) copies *function objects*. A function's `__globals__` is
the dict of the module that **defined** it — the real `os` module's `__dict__` — not the shim's copy.
So `_execvpe`'s `execv` / `execve` lookups (`os.py:593-620`) and `_spawnvef`'s `fork` (`os.py:853-878`)
resolve to the real callables no matter what the shim's attributes were set to. The delivered text
says exactly this at `:58-62` and `dev-map:173-177`, and it is correct.

**Why the fix had to be prose.** FR-3 / K-3 forbid adding a name, and independently the addition would
not close the capability: `os.path.os._execvpe` reaches the same helper through family (iv), which is
already named open and was measured escaping with both halves in force. Adding names would buy a
spelling. That is the reuse-correctness ruling behind CR-13: the reasoning is right, only the phrase
"buy nothing" compresses "denies two spellings, closes no capability" into a clause that reads, on
first pass, as "cannot be denied at all".

The one figure I could not reach by reading is the denominator, 402. It is a measured print in
`04_RATIONALE.md:146`, it is consistent with the 22 I derived independently and with the 19-name
"stem-suspicious" residual list, and no guarantee moves if it is off by one. RES-14 sends it to QA.

## DEF-2: whether the module-scope binding introduces a new hazard

The delivered shape is `REAL_POPEN = subprocess.Popen` at `:161` (after `import subprocess` at
`:153`), displacement at `:222`, restore at `:233` inside the **same** `finally` as the `os` shim
(`:231-233`), leak check at `:234` reading `subprocess.Popen is not REAL_POPEN`.

- BC-5 holds and is stronger than before: the restore-and-assert pair no longer shares a captured
  value that a statement reorder inside `load()` can invert. QA's M4b — capture written *below* the
  displacement, which reads as a tidy-up — is unreachable, because there is no capture inside
  `load()` left to move.
- The denial is still strictly narrowing: `:222` and `:223` are adjacent, nothing raisable stands
  between them and the `try:` at `:224`, and the window closes at `:233` before `return mod` at
  `:236`.
- BC-6 holds: `_CheckerStub` (`:798-803`) runs entirely after `load()` returned, with the real
  `Popen` restored.
- The residual hazard is a deliberate **rebinding** of `REAL_POPEN` inside `load()`. Is naming it
  enough? I judge yes. The two hazards are not the same kind of edit: a reorder is a plausible
  tidy-up that preserves apparent meaning, which is why it needed a structural answer; a rebinding of
  a module-level constant named `REAL_POPEN`, sitting under a four-line comment that says why it is
  there, is an edit that has to argue with the code to be written. A mechanism against it would cost
  more than the hazard. Filed as RES-11 so it is not carried only in a comment.

## DEF-3: the two bash semantics the fix turns on

`floor_of()` (`:90-93`):

```bash
local v; v=$(sed -n 's/.*"test_count"[[:space:]]*:[[:space:]]*\([0-9]\{1,\}\).*/\1/p')
if [[ $v =~ ^[0-9]+$ ]]; then printf '%s\n' "$v"; fi
```

1. **The shape test.** Bash compiles `=~` patterns with `regcomp` and no `REG_NEWLINE`, so `^` and
   `$` anchor at string boundaries, not line boundaries, and `[0-9]` never matches `\n`. A
   two-line `sed` result (`19\n3`, from a duplicated or nested unescaped `"test_count"`) therefore
   fails the test and `floor_of` emits nothing — which both callers already treat as "no floor".
   Command substitution strips trailing newlines, so a well-formed file is unaffected.
2. **Why the old shape failed open.** `(( 19 3 < 19 ))` is a bash *syntax error*; the construct
   returns non-zero, `set -e` is not in force (`:6` is `set -uo pipefail`), so control falls through
   the `elif` to the **`else`** — B.6's PASS arm — with the only trace a stderr line. Same class for
   a leading-zero floor: `(( 018 < 19 ))` is "value too great for base", same fall-through. The `10#`
   pinning at `:106` and `:130` removes the second half of that; the shape test removes the first.
3. **BC-2 is intact.** All four unreadable-history shapes still land on one branch (`:127-129`),
   printing one `step` SKIP line plus exactly one `echo`. The message gained the word "single", which
   is now accurate.
4. **B.4 on a valid file is unchanged.** `:99` reads through the same function, `:101` already
   FAILed on an empty floor, and `:106`'s comparison is the same comparison base-pinned. The only
   behavioural delta for B.4 is that an *unusable* floor now FAILs instead of PASSing — the safe
   direction, and the direction its own branch text already described.

On scope: QA filed only B.6. The fix lives in the one reader because the defect is in the shape of the
value, not in either caller; I-5 forbids two spellings of one judgement, so a call-site fix would have
been the drift. The one token beyond QA's finding is `10#` at `:106`. Defensible widening.

## The frozen set, and what the numstat proves on its own

Two facts fall out of the PM's `--numstat` without needing a further command:

- `verify_all.sh` **38/2**. Two deletions total, and both are accounted for by B.4's read (`:99`) and
  its comparison (`:106`) being rewrites. No other line of that file was removed or altered, so B.3's
  SKIP (`:77`) and B.5's `--self-check`-only wiring (`:112`) are untouched *structurally*, not merely
  by inspection.
- `docs/dev-map.md` **91/4**. Four deletions total; the developer and QA independently located all
  four inside the two sentences this change falsified. It follows that the 11-line fenced recipe block
  (`:204-214`) and T-32's sentences are byte-identical — a block edit would have had to consume one of
  those four. I also read the block and the anchors: R-77 `:236`, R-78 `:239`, R-84 `:240`, "nine path
  constants" `:216`.

Re-counted by hand at the delivered line numbers: E-1 = 3 (`:161`, `:222`, `:233`), E-2 = 14
(`def :587` + `:615-627`), E-4 = 14 (`floor_of` `:90` `:91` `:92` `:93` = 4; B.6 `:125` … `:134` = 10).
**31**, against NFR-2's 40 and the gate's 31–34. C-10 does not bind.

Citations re-derived first-hand after the header grew (round 1's CR-8/CR-9 were exactly this defect):
`bin/sc:14`, `:79-83`, `:125-126`, `:2175`, `:2504`, `:2599`, `:2614`, `:2628`, `:2634`, `:2727`,
`:2731`, `:2816`, `:2827`, `:2831`, `:2853`, `:3406`, `:3607`, `:3609` — all exact.
`check-sc-contracts.py:152-153`, `:213`, `:216`, `:234-235`, `:602-613`, `:854`, `:868` — all exact.
`verify_all.sh:90-93`, `:99`, `:106`, `:116-124`, `:125-134` — all exact.

## Ruling on QA's nine surviving mutants

Two were closed by round 4: **M4b** by the import-time `REAL_POPEN` binding, **M17** by the digit-run
shape test. On the remaining eight I agree with recording each, and I would close none of them in this
task:

- **M1** (drop half (b)), **M5** (drop `"system"` from the tuple), **M6** (drop `mod.os is not shim`)
  are one class: the denial has no committed control at all. A control needs a committed escaping
  subject driven through `--source` — a new file, which AC-13 / NFR-3 forbid here — or a second
  interpreter invocation, which the output-layer sentence denies. Recording is correct; the *class*
  deserves a filed row, which is why I added RES-12 rather than leaving three mutant rows to speak
  for it.
- **M3** (move the restore out of the `finally`) is RES-3's shape, declared NOT-DISCRIMINATING by
  G-6 at design time and confirmed by measurement. Record.
- **M8** (drop `encoding="utf-8"` from the clause's `open()`) survives only because this host's locale
  codec is UTF-8 — T-28's known false-kill trap. Killing it needs a re-invocation under `LC_ALL=C`,
  i.e. a process start. Record; the reason is already in the code at `:225-227`.
- **M14** (swap `2>/dev/null` and `<`) is RES-4: unobservable except in a state no committed step
  creates. Record.
- **M19** (real `os` through the shim's own `path`) and **M20** (`os._execvpe`) are open **by design
  and by declared sentence**, families (iv) and (ii). A mutant that reproduces a documented open route
  is evidence the document is honest, not a defect. Record.

If exactly one had to be named as the strongest candidate for closure in a *later* task, it is
**M5** — the tuple is the artifact the whole task is about, and nothing anywhere checks that it still
contains what the sentence says it contains. That is RES-12's first customer.

## Measurements I would like, none of them blocking

The PM's readings (`verify_all` PASS 20 / WARN 0 / FAIL 0 / SKIP 1 with B.4 and B.6 both PASS;
`sha256sum bin/sc` unchanged; `--numstat`; `git status --short`) cover the gate. One optional command,
whose only possible outcome is a MINOR prose correction (RES-14):

```
python3 -c "import os,sys;n=dir(os);p=('exec','spawn','fork','popen','posix_spawn','system');print(sys.version.split()[0],len(n),sum(1 for x in n if x.startswith(p)))"
```

Expected: `3.12.3 402 22`. I verified the `22` from CPython source by hand; only the `402` is
unread. If it differs, the correction is one number in `check-sc-contracts.py:52` and
`docs/dev-map.md:167`, at 0 executable lines.
