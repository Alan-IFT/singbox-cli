# 04 — Development rationale · T-19 `ruleset-staleness-visibility`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

## The measurement behind DESIGN DRIFT D-1

**Trigger T4.1.** I opened `02_RATIONALE.md` before recording the drift; it discusses K-13 only as a
size line ("one `sys.stderr.write` for one `sys.exit`", `02_RATIONALE.md:127`) and says nothing
about stream ordering. `03_RATIONALE.md` says nothing about C-8 or A-3 either. So the reasoning
below is mine, not a contradiction of a recorded ruling.

A-3 answered the question I would otherwise have had to rediscover — "is `sys.stderr.write(s + "\n")`
byte-identical to `sys.exit(s)`, including the interleaving `install.sh` sees?" — with: *"The
interleaving is unchanged too: stderr is unbuffered in both, and the buffered stdout is flushed at
interpreter shutdown either way, so the merged `2>&1` capture keeps the same order. C-8 requires you
to prove it rather than inherit this answer."* I proved it, and the second half of that answer is
false as written.

Both runs are the all-mirrors-fail state, child process, stdout **and** stderr into one file
(`>file 2>&1`, i.e. the shape `install.sh:567` records), `SystemExit` allowed to reach the
interpreter in both so HEAD prints its aggregate exactly as it does in production. Temp-root paths
normalised to `<ROOT>` before diffing.

Candidate **before** the fix:

```
  ↓ geoip-cn.srs ... failed: file://<ROOT>/no-such-mirror -> <urlopen error [Errno 2] ...>
  ↓ geosite-cn.srs ... failed: ... -> skipped (this source already failed in this run)
  ↓ geosite-google.srs ... failed: ... -> skipped (this source already failed in this run)
  ↓ geosite-private.srs ...
4 ruleset(s) failed to update
failed: file://<ROOT>/no-such-mirror -> skipped (this source already failed in this run)
No rule-set changed — the sing-box service was not touched
```

HEAD:

```
  ↓ geoip-cn.srs ... failed: file://<ROOT>/no-such-mirror -> <urlopen error [Errno 2] ...>
  ↓ geosite-cn.srs ... failed: ... -> skipped (this source already failed in this run)
  ↓ geosite-google.srs ... failed: ... -> skipped (this source already failed in this run)
  ↓ geosite-private.srs ... failed: ... -> skipped (this source already failed in this run)
No rule-set changed — the sing-box service was not touched

4 ruleset(s) failed to update
```

`diff` reported three changed lines: the fourth rule-set's completion line is **split in two** by
the aggregate, and the aggregate moves from last to fourth.

The mechanism has two parts, both worth recording:

1. CPython's handling of `SystemExit` with a string argument **flushes `sys.stdout` before** writing
   the string to stderr. HEAD therefore always emits the aggregate after every buffered stdout byte.
   An in-run `sys.stderr.write` has no such flush: stderr is unbuffered, stdout to a file is
   block-buffered, so the aggregate overtakes everything still in the buffer.
2. `print(prefix, end="", flush=True)` at `bin/sc:2791` flushes the **whole** stdout buffer, not
   just `prefix` — which is why the first three per-file lines are intact in both captures and only
   the last one is split. Without that per-file flush the divergence would have been total.

The fix is one line, `sys.stdout.flush()` immediately before the write, which restores exactly the
property HEAD had and nothing else. Re-measured: `diff` reports no difference, i.e. the merged
captures are byte-identical after root-path normalisation. Rule-85 check: it removes a regression
rather than adding a mechanism; there is no smaller form (the alternative — keeping `sys.exit(<str>)`
— cannot coexist with K-12's single exit site and I-5's one determination); and it adds no envelope,
so K-15 stands.

This is why C-8 was worth writing as a condition rather than an assumption. Stage 6 still owns it —
this stage removed the failure it was aimed at, it did not discharge the condition.

## Why the +80 / −30 ceiling shaped the docstrings

The first pass landed at +89 / −30 and would have exceeded C-6 once C-1's help lines were added. The
excess was almost entirely prose: a full reflow of `ruleset_state()`'s DIGEST-CONTRACT paragraph, an
11-line `_age_text()` docstring, a 7-line `restart_service()` docstring, two-line comments where one
line says the same thing. I cut it by editing only the docstring lines the widening actually
falsifies (three of the seven in that paragraph) and by compressing the two new docstrings, rather
than by dropping the content — every constraint the design attaches to a symbol (K-1 … K-4, I-2's
"must stay a function", I-4's no-init-system arm) is still stated at the symbol. Two edits were
reverted outright for budget: a `# rule-sets:` group-comment update in `TRANSLATIONS` (the existing
comment is incomplete after five new keys, but not false) and a second sentence in
`_status_view()`'s docstring about the starred tail. Both are cosmetic; neither is a contract.

That the ceiling was reachable at all is a signal, not an accident: `02` estimated ≈ +72 / −32 of
`bin/sc` and the true cost of *truthful* docstrings on a file that documents its invariants this
heavily is higher than a per-hunk estimate suggests. The per-edit-id table in the contract portion
gives stage 5 the deltas one by one.

## Why the A-6 starred form, and what it costs

A-6 left the choice open. Starred unpacking wins on rule 85's own terms — same size today, one fewer
edit for T-20 and for every later widening — but it is not free: `for tag, fname, status, *_rest in
states` no longer fails loudly if the snapshot tuple *shrinks* or is passed the wrong list shape,
where `for tag, fname, status, _digest, _size in states` would have raised. The exposure is bounded
by there being exactly one producer (`ruleset_states()`) and by `_status_view()` still returning
three elements, which is the invariant the frozen set actually protects. I took it, and it is
recorded here so a later reader does not mistake the tolerance for an oversight.

## Fixture notes stage 6 may want

- The HEAD control is a `git clone` of the repo (commit `84c8d8b`), never a `git worktree`.
- Every child run is a separate process whose exit status is read from the process, not from a
  caught `SystemExit`. The harness has an `SC_RAW=1` mode that lets `SystemExit` reach the
  interpreter, which is required for any comparison involving HEAD's `sys.exit(<str>)` — catching it
  swallows the aggregate line entirely, and my first mirror-dead comparison was wrong for exactly
  that reason until I noticed HEAD's stderr was empty.
- Synthetic `.srs` bytes (`b"SRS" + 64 bytes`) are sound here because no step runs the real
  `sing-box` (A-5); every `check` return is stubbed explicitly.
- `os.utime` is what ages a file; the `-30 d` row renders `30 days ago`, and a `+1 h` row renders
  `0 seconds ago` through `max(0, …)`.
