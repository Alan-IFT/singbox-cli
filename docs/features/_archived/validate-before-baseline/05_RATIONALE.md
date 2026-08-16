> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## 1. What I could and could not measure this round

I was told to check for a shell and to use it. **There is none.** The tools exposed to this stage in
round 2 are `Read`, `Glob` and `Grep` — the same three as round 1. `verify_all.sh`,
`check-sc-contracts.py`, `git diff` and the two span hashes were therefore **not** re-run by me, and
RES-6 stays a disclosure rather than becoming a measurement. I have not dressed any inference up as
an observation anywhere in the contract portion.

What that leaves is still worth more than round 1's, because this round's central question — is the
guarded region really closed — is a **control-flow** question answerable from the source, and
because a great deal of what needed checking was *coordinates*, which `Grep` and `Read` settle
outright. Re-taken by me, first-hand, this round:

| claim | how | result |
|---|---|---|
| the two surviving `capture_output=` sites | `Grep` over `bin/sc` | exactly `:2271` and `:3536` — D-3 right, C-18's `:2258`/`:3523` stale |
| the sentinel, the `try:`, `mkstemp`, the guard, `_record_generated()` | `Read bin/sc:2130-2229` | `:2163`, `:2164`, `:2165-2166`, `:2211`, `:2216` — every C-12 coordinate exact |
| C-13's four citations | `Read bin/sc:1970-2005` | `_config_digest` `except OSError: return None` at `:1981-1982`; the `digest is None` return at `:1998-1999`; `_write_private` inside `try/except OSError: pass` at `:2000-2003`; the outer handler's write at `:2204-2205` — all four exact |
| arm 4, the docstring, the `dirname` clause, `TESTS` | `Read check-sc-contracts.py:530-701` | `:670-683`, `:611-629`, `:654-655`, `:690-701` — all exact |
| the floor | `Read baseline.json` | `test_count 18`, `passing_count 18` — unmoved, as C-16 requires |
| both new keys against their call sites | `Read bin/sc:128-145`, `:2180-2195` | the implicit concatenations reproduce the keys character for character; placeholders parity holds |
| `Config check failed:\n{stderr}` | `Grep` | absent from `bin/sc` |
| the empty-output key's readers | `Grep` | one definition `:316`, two readers `:2194` and `:2742` — no second wording |

What I could **not** re-derive: the +21 classification (it needs both files and a classifier), the
`_plain` / `_write_private` span hashes, and the four mutation probes. On the budget I note only
that C-8 forbids a trim, that 25 is the bound, that two independent methods produced the same 21,
and that the round-1 → round-2 delta of +2 executable is consistent with what I can see in the
source (exactly two new executable lines, eleven new comment lines). Nothing about it is worth
disputing on inference alone.

## 2. CR-1, read as control flow rather than as its comments

The comment block at `bin/sc:2150-2162` asserts the property. I ignored it and walked the
statements. The tail is:

```
2163  name = None
2164  try:
2165      fd, name = tempfile.mkstemp(...)
2167      os.close(fd)
2170      _write_private(Path(name), text)
2171      try:
2175          code, out = _doctor_run([SB_BIN, "check", "-c", name])
2176      except OSError as e:
2180          sys.stderr.write(... cannot-validate ...)
2183      else:
2184          if code != 0:
2190              sys.stderr.write(... rejected ...)
2196              return False
2197      _write_private(CFG_PATH, text)
2198  except (OSError, ValueError) as e:
2204      sys.stderr.write(... Could not write ...)
2206      return False
2207  finally:
2211      if name is not None:
2212          try:
2213              os.unlink(name)
2214          except OSError:
2215              pass
2216  _record_generated()
2217  return True
```

Four facts follow, each checked rather than assumed:

1. **Nothing fallible is outside.** The four operations that can touch the filesystem — `mkstemp`,
   both `_write_private` calls, and the child process — are all between `:2164` and `:2197`.
2. **The inner handler's body is protected.** `:2180-2182` is lexically inside the outer `try`, so a
   doomed `sys.stderr.write` there is caught at `:2198` and mis-worded as a write failure. Wrong
   words, no traceback. The developer says exactly this at `04_DEVELOPMENT.md:166-168` and it is
   correct.
3. **Binding order is right.** `except OSError` at `:2176` belongs to the inner `try` at `:2171`, so
   a checker `OSError` can never reach `:2198` and render as `Could not write`.
4. **Both `return False` pass through the `finally`.** They are inside the `try` statement, so the
   unlink runs for each — a language property, not a claim needing a test.

CR-1 is closed. Direction B's measured output (uncaught `FileNotFoundError`, **zero**
`Could not write` lines) is the same defect I described from the source in round 1, which is the
strongest possible confirmation of a source-only finding and is worth saying plainly.

## 3. The fifth member of C-13's enumeration (CR-11)

C-13 demanded the *true* enumeration, and I was asked to check that it is right rather than merely
present. It is right about the four it names and it is missing one.

An exception raised inside a `finally` **clause** propagates out of the whole `try` statement; the
`finally`'s own body is therefore not protected by the `try` it belongs to. That is not a subtle
reading — it is exactly what the developer's own direction-A probe measured: with the guard deleted,
`os.unlink(None)` raised `TypeError`, sailed **past** the inner `except OSError` and past the outer
`except (OSError, ValueError)`, and replaced the pending return. So the fifth member of the
enumeration is the one member the mutation probes prove can escape, and it is the member the whole
round-2 delta exists to make safe.

The property still holds in the shipped build, for two reasons the table should state:

- `if name is not None:` compares a local against a constant — no call, no attribute access.
- `os.unlink(name)` is inside its own `try:` / `except OSError: pass`, and `name` on that branch is
  always the `str` `mkstemp` returned, so the `TypeError` the mutation produces is unreachable here.

The narrow reason this is worth a row rather than a shrug: the gate's C-13 list was itself four
items, and the developer reproduced it faithfully. An enumeration inherited from the document that
commissioned it is exactly the kind that stops being audited. The load-bearing sentence — *no
statement outside the `try` can raise* — is only established once all five are covered.

## 4. The R-22 sweep over the round-2 suite

For each committed clause: what plausible wrong build passes it? Reported as NOT-DISCRIMINATING
where that is the answer.

| clause | site | a wrong build that passes |
|---|---|---|
| `_eq(got, want)` | `:648` | — (a build that never writes fails arms 2-3; one that always writes fails arm 1) |
| `_eq(len(stub.calls), 1)` | `:649` | — pins NFR-1 |
| `_eq(cmd[1:3], ["check","-c"])` | `:651` | — |
| `cmd[3] != str(CFG_PATH)` | `:652-653` | a build that mkstemps into `TMPDIR` — which is why `:654` exists |
| `dirname(cmd[3]) == str(CFG_DIR)` | `:654-655` | — the developer measured the `dir=None` build going red here and only here |
| `mode == 0o600` | `:656` | — read by the run at the one instant the candidate is complete |
| `during == installed` | `:657` | — this is the ordering clause |
| listing unchanged | `:658` | a candidate created **outside** `CFG_DIR`; measured, and `:654` is its answer |
| rejected: `(after, record) == (installed, recorded)` | `:660-662` | — |
| accepted: `after != installed`, parses as JSON, record is its sha256 | `:663-668` | **NOT-DISCRIMINATING** — a build installing a *different* valid document, and a build installing the candidate by `os.replace(name, CFG_PATH)` (the declined RS-1 decision, which also preserves 0600 and leaves the listing clean because the rename consumes the candidate and the `finally`'s unlink swallows `ENOENT`). CR-16 / RES-9 |
| arm 4: returns `False`, does not raise | `:681-682` | **NOT-DISCRIMINATING for half the invariant** — a build that catches the `mkstemp` `OSError` and returns `False` with no message. CR-12 / RES-8 |

**The fourth instance of the shape the gate named as a class.** The three found so far were all the
same relation: a clause whose satisfying set strictly contains the property, because a prefix or a
containment or an absence is not the observation it looks like (`str(CFG_PATH) in stderr` satisfied
by the leaking build; `str(CFG_PATH) in cmd[3]` satisfied by HEAD's own argv; "no new entry in
`CFG_DIR`" satisfied by a candidate that was never there). The fourth is arm 4's own pair of
clauses: *returns `False` and does not raise* strictly contains *renders one run-level outcome line
and returns `False`*, and the gap is precisely BC-11's operative words. It is the same class one
level up — not a string relation but a set relation over observables — and it lands on the single
arm the design elected as the sole control for the invariant, with the docstring and
`docs/dev-map.md:87` both asserting the wider claim.

I am not asking for a fifth arm or a widened one: `02` `## Out of scope` 9 declines the fifth arm,
I-14 specifies arm 4 exactly as written, and C-8 / K-1 close the door on adding statements. The
proportionate answer is that RES-8 travels to stage 6 and the docstring's second bullet is worth one
clause of precision whenever this file is next legitimately open.

## 5. CR-13, derived rather than asserted

The paragraph at `CHANGELOG.md:26` now says, correctly, that the freeze is over `标准输出与退出码`.
On the host class the same paragraph discloses two sentences earlier, that is still false:

- **HEAD**, no usable `sing-box`: `generate_config()` reaches `subprocess.run([SB_BIN, …])`,
  `FileNotFoundError` (or `[Errno 8]`) escapes, nothing above catches it — `main()`'s envelope takes
  `OverrideError` only — so CPython prints a traceback and the process exits **1**, with no restart
  and no outcome line.
- **This build**, same host: the cannot-validate arm warns, installs, records, returns `True`,
  `reload_or_restart()` restarts, and the run exits **0** having printed its normal stdout.

So on that host both the stdout and the exit code of `sc reload` and `sc update-rules` change. The
developer knows this — it is C-11 / G-11, and it is in the same paragraph as「请注意这一条的代价」.
The defect is only that the final sentence does not carry the qualifier the earlier one establishes,
which is why this is MINOR and not a repeat of round 1's CR-3. One clause fixes it.

## 6. Prose fidelity: the four corrections, and the third instance of the recurring class

The four C-18 / C-10 corrections are right and complete:

- `docs/dev-map.md:41` — the failure clause is now worded over the **three** filesystem operations,
  names the one guarded region, and states both *why* the candidate's creation is inside it and what
  the `finally`'s guard is for. It also keeps the `ValueError` half, which nothing else records.
- `:87` — 18 assertions, **four** arms, and the fourth named as passing on a HEAD clone by design.
- `:104-109` — two `capture_output=` sites with coordinates I verified myself, plus the sentence
  recording that there were three until T-30. This is the single most valuable of the four: it is in
  the file a developer agent reads before writing code.
- `CHANGELOG.md:26` — scoped, not deleted (CR-13 is its remaining half).

The gate asked whether the class recurs a third time. It does, twice more, and both are small:

1. **`bin/sc:1991-1992`** — `_record_generated()`'s docstring argues from adjacency ("would have
   failed the `config.json` write **one line earlier**"). The write is now nineteen lines and a
   whole `finally` block earlier. The *substance* survives — the write still precedes it, which is
   I-10's point — and the function is inside T-14's frozen span, so no in-task edit is owed. T-32.
2. **`04_DEVELOPMENT.md:8-9`, `:50`** — the tail cited as `bin/sc:2157-2217`, where `:2157` is
   round-1's `mkstemp` line and now points into a comment block. The end of the span was updated,
   the start was not. Trivially small, and worth naming only because it is the same failure mode the
   document diagnoses two tables lower for D-3.

Re-swept and **not** falsified by this round: both READMEs (no sentence describes the write/check
ordering; `README*.md:440`'s "0600 before its first byte" is now true of one more file, not less),
`docs/architecture.md:52-80` (redrawn and accurate), `CONTEXT.md:127-134` (the third disjunct
corrected, no second term coined), `docs/dev-map.md:70`, `:77`, `:78` (round-1 edits, re-read, still
true), and `docs/dev-map.md:76`'s recovery-arm scar, which CR-5 now mirrors one task later.
`README.zh-CN.md:423` / its English peer describe what the drift warning *says*, which is still what
it says — CR-9's ruling covers them and no edit is owed.

## 7. C-21, re-derived independently

The developer's argument is "every path that reaches the checker binds a real `name`". I re-derived
it from the delta rather than accepting it. The delta is three edits: a sentinel assignment, a guard
in the `finally`, and `mkstemp` re-indented from above the `try:` to inside it. For any run in which
`CFG_PATH.parent` exists:

- `mkstemp` succeeds ⇒ `name` is a `str` ⇒ `if name is not None:` is always true ⇒ the `finally`
  executes round 1's unlink block, unchanged;
- the re-indent changes *which handler covers `mkstemp`*, and `mkstemp` does not fail, so no handler
  is entered that was not entered before;
- the sentinel is dead code on that path.

So V-2, V-3, V-4, V-6, V-7, V-9, V-10 and V-5's listings are behaviourally identical statement for
statement, and V-8 never enters the tail at all (`sc doctor` does not call `generate_config()`). The
only path the delta changes is the one V-14 exists for. **No row is coasting**, and the three rows
that were re-run (V-11, V-12, V-14) are exactly the three that could move.

## 8. What I would look at hardest at stage 6

1. **RES-8 before RES-2.** FR-5's uncontrolled substitution (CR-5) is the better-known gap, but
   BC-11's uncontrolled *rendered line* (CR-12) sits on the one arm the design nominated as the sole
   control for the invariant this whole round exists to establish. A future editor reads a docstring
   that promises more than the code asserts.
2. **The `os.replace` shortcut (RES-9).** It is a declined decision, it is the obvious "tidy-up" for
   someone who notices the document is written twice, and every committed clause stays green under
   it. K-2 is enforced today by grep and by nothing else.
3. **Arm 4's isolation.** The developer had to empty the three-arm loop on a *copy* to observe "arm
   4 passes on HEAD", because on a HEAD clone the rejected arm fails first and the function aborts.
   Anyone re-establishing C-14 later must repeat that trick or they will read the wrong thing off
   the suite's output.
4. **The `finally`, once more.** It is the only region of this tail whose failures leave the
   function, it now carries the guard, and CR-11 is the sign that its status is easy to lose track
   of even for the people writing about it.
