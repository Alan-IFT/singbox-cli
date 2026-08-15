# 06 — Rationale · T-24 `override-error-envelope`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

## How this stage ran, and why the transcripts come in three rounds

This stage ran twice. **Round 1** (16:02–16:20) executed the whole measurement programme and was cut
off by an API transport error at the moment it began writing its documents; its ~90 artifacts survive
in the session scratchpad. **Round 2** (16:28–16:45) re-read that corpus, re-ran everything that was
cheap and decisive, added six new probes of its own, and wrote the two documents. The contract marks
every figure `[R2]` (re-measured in round 2) or `[R1]` (round-1 transcript). Where round 2 re-ran a
round-1 script, the output was compared byte-for-byte; eleven scripts matched exactly, which is the
strongest stability evidence this task has (two runs, hours apart, identical answers).

Round 2's own new work, none of it inherited: `wrongbuilds2.py` (builds W-D, W-E, W-F),
`qa2-probe.py` (format-string injection; echo carriers), `qa2-lang.py`, `qa2-res7.py` /
`qa2-res7b.py` (the real `sing-box check`, un-stubbed), `qa2-bc2-res9.py`, `qa2-extractors.py`,
`qa2-conc.py`, `qa2-stability.py`, plus both `verify_all` runs and the `git` re-runs.

**Round 3 — the verification round** (2026-08-15 17:00–17:25, `[R3]`), after the PM compacted
`PM_LOG.md` (QA-2) and the developer replaced the false CHANGELOG tail (QA-1). Its scope was chosen
by asking what the two repairs could possibly have moved: `verify_all` on both trees, the `git`
figures, the service witness, and the new sentence's every clause. `bin/sc` is byte-unchanged since
round 2 (mtime `15:01:00`, earlier than round 2 itself; `--numstat` identical), so nothing measured
against the binary was re-run — re-measuring it would have produced the same numbers with a fresh
chance of transcription error, and the contract keeps the round-2 markers instead.

Round 3 had to write a **new** harness: rounds 1–2 ran in an earlier session whose scratchpad no
longer exists, so `qa2-res7.py` and its siblings could not be re-executed. That is a better position
than it sounds — the round-3 reproducers were written from the *repaired sentence*, with no sight of
the code that produced the earlier figures, and they reproduce round 2's digests exactly where they
overlap (the sentinel `config.json` still hashes to `bb2499315a356468…`, HEAD's `{"outbounds": 5}`
result still to `d590372cbd0c3775…`).

## Rationale triggers

- **T6.1** (an acceptance criterion's verification step under-specified) fired for AC-2, AC-7 and
  AC-10 — and `01_RATIONALE.md` exists, but it did not need to be consulted: the gate amended all
  three in the **contract** (`03_GATE_REVIEW.md` C-1…C-5), which is binding and self-contained.
- **T6.2** (reproducing a developer-claimed measurement) fired for `04_RATIONALE.md`'s HEAD
  `dns.servers` exit-0 figure and its 498/9997 depth thresholds. Both re-derived independently; the
  depth thresholds reproduce, the exit-0 figure does **not** survive un-stubbing (QA-1).
- **T6.3** (a code-review finding to re-test that is not self-contained) fired for CR-5 → RES-2 and
  CR-9 → RES-7. `05_RATIONALE.md` was read for both; RES-2's fixture requirements were stated fully
  in the contract, and RES-7's stub scoping was too.

No upstream **contract** portion was missing, so nothing was returned `BLOCKED ON UPSTREAM`.

## Full runs, whose ≤5-line excerpts the contract cites

### AC-2, candidate, all 13 members (`re/ac2-cand.txt`, `[R2]`)

```
=== AC-2 candidate=cand src=/home/alan/Programs/singbox-cli/bin/sc ===
M0    en lines=1 exit=1 (i)=True (ii)path=True fault=True (iii)=True (iv)bytes_identical=True tb=False -> PASS
      Cannot use <fx>/override.json: no configuration could be produced from it (RecursionError)
M1    en … PASS   Cannot use <fx>/override.json: no configuration could be produced from it (RecursionError)
M2    en … PASS   Cannot use <fx>/override.json: no configuration could be produced from it (AttributeError)
M3    en … PASS   Cannot use <fx>/override.json: no configuration could be produced from it (AttributeError)
M4    en … PASS   Cannot use <fx>/override.json: at dns.rules: an existing array must be changed with one of $prepend, $append, $replace, $before, $after
M5    en … PASS   (same sentence)
M6    en … PASS   (same sentence)
M7    en … PASS   (same sentence)
M8    en … PASS   Cannot use <fx>/override.json: no configuration could be produced from it (TypeError)
=== RES-1: the same shapes at an UNGUARDED array key (dns.servers) ===
M4b/M5b/M6b/M7b  en lines=1 exit=1 … PASS
      Cannot use <fx>/override.json: at dns.servers: an existing array must be changed with one of $prepend, …
verdicts: 13 PASS / 0 FAIL
```

### AC-2, HEAD control (`re/ac2-head.txt`, `[R2]`) — what the fix actually changed

```
M0  lines=29   exit=1 tb=True  -> FAIL
M1  lines=2998 exit=1 tb=True  -> FAIL      <- BC-3's "2 999 lines", reproduced
M2  lines=20   exit=1 tb=True  -> FAIL
M3  lines=20   exit=1 tb=True  -> FAIL
M4..M7 lines=1 exit=1 (iv)=True -> PASS     Cannot use <fx>/override.json: at dns.rules: this must stay an array
M8  lines=17   exit=1 tb=True  -> FAIL
M4b..M7b lines=2 exit=0 (iv)bytes_identical=False -> FAIL
      ⚠️  <fx>/config.json was modified outside sc — those changes are about to be replaced; …
verdicts: 4 PASS / 9 FAIL
```

RES-1 in one line: at the three **guarded** keys HEAD already did the right thing (1 line, exit 1,
bytes identical) — the control there does not discriminate and only the sentence's vocabulary
changed. At `dns.servers` it discriminates hard: **2 lines, exit 0, bytes changed**. That is the
whole of the falsified annotation, and no clause of AC-2 and no member of BC-1 shifts meaning.

### C-2, both languages (`re/qa2-lang.txt`, `[R2]`)

```
M0 zh lines=1 exit=1 iv=True has_zh_fault=True has_shibai=False
    无法使用 <fx>/override.json：无法据此生成配置（RecursionError）
M4 zh lines=1 exit=1 iv=True
    无法使用 <fx>/override.json：在 dns.rules：修改已有数组必须使用 $prepend, $append, $replace, $before, $after 之一
M8 zh …  无法使用 <fx>/override.json：无法据此生成配置（TypeError）
```

The language is selected only by the fixture's own `settings.json`, so `main()`'s post-import
reassignment is what picks it — BC-13's trap, avoided. `失败` appears in none of the new sentences.

### C-12 / RES-2, forced raise on a drifted **and** degraded fixture (`re/c12.txt`, `[R2]`)

```
--- _warn_degraded raises, override PRESENT (valid)
    lines=1 exit=1 bytes_identical=True traceback=False
    [1] Cannot use <fx>/override.json: no configuration could be produced from it (ValueError)
--- _warn_degraded raises, NO override
    [1] Cannot use <fx>/config.json: no configuration could be produced from it (ValueError)
--- _warn_drift raises,   override PRESENT (valid)
    lines=2 exit=1 bytes_identical=True traceback=False
    [1] ⚠️  2/4 rule-sets unusable (geosite-google (missing), geosite-private (missing)) — …
    [2] Cannot use <fx>/override.json: no configuration could be produced from it (KeyError)
--- _warn_drift raises,   NO override
    [2] Cannot use <fx>/config.json: no configuration could be produced from it (KeyError)
```

Both statements the region encloses take no override-supplied input, and a fault in either is still
named against `override.json` when an override is present — accepted under BC-11, and the fault
clause (`ValueError` / `KeyError`) is exactly what keeps such a defect reportable. The line count is
**measured, not assumed**: one line when the abort precedes the degraded warning, two when it
follows it. BC-3 is BC-1-scoped and is not breached.

### C-13, precedence at every target type (`re/c13.txt`, `[R2]`)

```
unknown @ list / dict / scalar / absent   equal=True  exit c=1 h=1
mixed   @ list / dict / scalar / absent   equal=True  exit c=1 h=1
C-13 dns.$nope    equal=True   at dns.rules: unknown directive $nope — use one of $prepend, …
C-13 log.$append  equal=True   at log: $append can only be applied to an array that already exists
AC-6 bare array   equal=True   at dns.rules: an existing array must be changed with one of …
candidate == HEAD on 11/11 precedence/AC-6 fixtures
```

`_directive_of`'s two errors fire ahead of every test on `target`, for all four target types, with
today's sentences byte-identical to HEAD in text and in trigger. The `{"log": {"$append": []}}`
fixture lands on the pre-existing "can only be applied to an array that already exists" sentence,
which is the correct one for a non-list target and is unchanged.

### The six wrong builds (`re/wrongbuilds.txt`, `re/wrongbuilds2.txt`, `[R2]`)

Each build is a textual substitution of the shipped `except` arms, applied to the source before
`exec`, so the rest of the file is the shipped file. Round 1 built W-A/W-B/W-C; round 2 added
W-D/W-E/W-F.

```
=== W-A ===  M2/M4/M8: lines=1 exit=0 bytes_identical=False -> ['ii','iii','iv']   line = "Reloaded"
=== W-B ===  M2/M4/M8: lines=1 exit=1 bytes_identical=True  -> ['ii']              line = "Reload failed"
=== W-C ===  M2/M4/M8: lines=1 exit=1 bytes_identical=False -> ['iv']              correct sentence, file written
=== W-D ===  M0..M8: failing NONE (SURVIVED)      … from it ('int' object has no attribute 'get')
=== W-E ===  M1/M2/M3/M8 -> ['ii_path'] (names config.json);  M0/M4..M7 SURVIVED
=== W-F ===  M8 only: lines=17 tb=True -> ['i','ii_path','ii_fault'];  M0..M7 SURVIVED
```

Three readings worth keeping:

1. **W-C is the reason C-3 exists.** It renders the right sentence, exits non-zero, prints exactly
   one line and produces no traceback — everything a naive criterion asks for — and still ships a
   `config.json` in which the user's override was ignored. Only clause (iv), and only in C-3's
   amended form (survival of *pre-existing* sentinel bytes, not absence of a file), kills it. Under
   F-6's vacuous reading it would have passed.
2. **W-E shows M0 and M1 are not redundant.** M0 aborts at the **load** arm (`bin/sc:2051`), whose
   `OVERRIDE_PATH` is unconditional, so W-E's un-gated label is invisible there; M1 aborts inside the
   region, where it shows. Two members, two edits (E4 and E5).
3. **W-F is the measured case for a region over a leaf list.** An envelope catching
   `(RecursionError, AttributeError)` — a perfectly reasonable leaf enumeration, and exactly the
   shape `.harness/rejected-decisions.md` §`clash-api-bare-except-and-leaf-enumeration` warns about —
   passes M0…M7 and dies on M8's `TypeError`. C-10's promotion of M8 to a required fixture is what
   makes this criteria set able to tell the two designs apart.

### QA-3 in full: what W-D actually leaks, and what it does not

W-D replaces `fault=type(e).__name__` with `fault=str(e)`. Nine members and six purpose-built
carriers later, **no document value ever reached the line**:

```
M1  … from it (maximum recursion depth exceeded)
M2  … from it ('int' object has no attribute 'get')
M8  … from it (unhashable type: 'list')
P2 carriers (unhashable tag / dict rule_set ref / dns scalar deep / route rules dict outbound /
   log replaced by scalar / experimental scalar):  echoes_sentinel=False on all six
```

Four of the six carriers were not even faults — they are valid overrides that reload cleanly, which
is itself informative: the exception surface reachable from a document is narrower than it looks.
So QA-3 is filed as an **uncontrolled property**, not as a realised leak: the shipped build is
correct by construction, and nothing in the criteria set would notice if it stopped being.

### RES-7 in full (`re/qa2-res7.txt`, `re/qa2-res7b.txt`, `[R2]`)

Safety first: the patch restoring the real `subprocess` restores it **only** for `sc`'s own module
namespace, `restart_service` stays stubbed and `SYSTEMD`/`OPENRC` stay `False`, so no init-system
command can be formed. Every child process formed in the whole run is logged, and the log contains
exactly one distinct argv: `['sing-box','check','-c','<fx>/config.json']`.

```
HEAD  no override (sanity)   lines=3 exit=0  RAN sing-box check -> returncode=0   | Reloaded
HEAD  {"dns":{"servers":5}}  lines=6 exit=1  returncode=1   FATAL … dns.servers: cannot unmarshal number …
HEAD  {"inbounds": 5}        lines=6 exit=1  returncode=1   FATAL … inbounds: cannot unmarshal number …
HEAD  {"outbounds": 5}       lines=6 exit=1  returncode=1   FATAL … outbounds: cannot unmarshal number …
cand  all three              lines=1 exit=1  children: NONE   Cannot use <fx>/override.json: at <key>: …
HEAD  object @ dns.servers   lines=6 exit=1  FATAL … cannot unmarshal object …
HEAD  null   @ dns.servers   lines=6 exit=1  FATAL … initialize outbound[2]: default domain resolver not found
HEAD  bare array @ dns.servers (valid)  lines=1 exit=1 cfg+drift unchanged=True  checker_ran=False
      Cannot use <fx>/override.json: at dns.servers: an existing array must be changed with one of …
```

The last row is the one that closes the question. A **bare array** at an unguarded array key does
not silently replace even on HEAD — the pre-existing sentence (AC-6's) already rejects it. So every
silent replacement HEAD can perform at an unguarded key produces a document `sing-box check`
rejects, and the run exits **1**, not 0. The three substantive harms remain and are the point of the
fix: the broken document is written, `_record_generated()` baselines its digest *before* the check
runs, and the previous working `config.json` is gone. `退出码仍然是 0` was the one clause that did
not survive contact with a real checker, and the CHANGELOG published it unscoped — QA-1.

Why it was MAJOR rather than a NIT: this project has twice sent a round back for a published clause
that a measurement refutes (CR-1, CR-8), and `05_CODE_REVIEW.md` CR-2 states the principle plainly —
"a false published row must not ship". The clause is user-facing, in a delivered product file, and
the repair was one clause long.

### QA-1's repair, and the one thing round 2 had not actually measured (`r2-order.txt`, `[R3]`)

Round 2 asserted, and the contract published, that HEAD "baselines the digest *before* the check".
Re-reading my own evidence in round 3, that was **not** established: `qa2-res7.py` reported
`cfg+drift unchanged=False`, which is a statement about the *end* of the run and is equally
consistent with the digest being written after the checker returned. The repaired CHANGELOG makes
the ordering explicit (「在校验之前」), so it had to be measured rather than inferred from reading
`generate_config()`. `r2_order.py` therefore wraps `subprocess` in a façade that snapshots both
files **at spawn time** and then delegates to the real `sing-box`:

```
=== HEAD build, override = {"dns": {"servers": 5}} ===
exit=1   config.json sha before=bb2499315a356468 after=03b0b2e4b75e1de9 changed=True
         drift record before=0000000000000000  after=03b0b2e4b75e1de9 changed=True
AT SPAWN ['sing-box', 'check', '-c', '<fx>/config.json']
   O1 drift record already baselined onto the just-written document: True
   O1b it is NOT still the pre-existing record: True
```

Identical on `{"inbounds": 5}` and `{"outbounds": 5}`. Two controls keep it from being vacuous:
`r2_order_control.py` re-runs all three with the checker stubbed to `returncode 0` and gets
`exit=0` with the whole output being `Reloaded` — so the non-zero exit is the checker's doing and
stage 4's exit-0 figure is exactly the harness artefact it was said to be; and
`r2_working_overwritten.py` first generates a configuration the **real** checker accepts
(`PHASE 1 … exit=0 … returncode=0`) and only then applies the override, so 「原来那份能用的配置就此
被覆盖」 is measured against a genuinely working document rather than against a sentinel.

The one clause that is host-scoped rather than universal: with no `sing-box` on `PATH`, HEAD dies of
an uncaught `FileNotFoundError` (`exit=1 traceback=True`, `emitted dns.servers=5`) — the overwrite
and the baselined drift record still happen, the non-zero exit still happens, only the attribution
to the checker does not. Every host `install.sh` produces has the binary, so the sentence is not
wrong; it is simply not the widest true statement. Not filed.

### AC-13 in full

```
[R3] working tree : PASS: 17   WARN: 0   FAIL: 0   SKIP: 1   (exit 0)
[R3] HEAD clone   : PASS: 17   WARN: 0   FAIL: 0   SKIP: 1   (exit 0)
[R2] working tree : PASS: 16   WARN: 1 — [F.6] … PM_LOG.md:505L   (exit 1)   -> QA-2, now closed
```

AC-13's text is "no new FAIL **and no new WARN** against a pristine HEAD clone". At `[R2]` there was
a new WARN — caused by a stage document five lines over the cap, involving no product file, with
`FAIL: 0` throughout — and reporting that as a pass would have required reading the criterion as
something other than what it says, which is the failure mode this whole task exists to correct. It
was filed MINOR and routed to the PM, who owns `PM_LOG.md`; the PM compacted it to 482 lines and the
two runs are now identical. The clone was re-made from scratch at `[R3]` rather than reused, because
a stale clone is the obvious way for this comparison to lie. `verify_all.sh` is byte-unmodified —
checked explicitly, since "make the WARN go away" has a cheaper wrong answer than compaction.

### T-13 / T-14 timeline (`re/t13.txt`, `[R2]`)

```
mkstemp <fx>/config.json.tmp.<pid>.<rand>  0o600  size=0
fchmod  <fd>                               0o600  size=0
fsync(content on disk) <fd>                0o600  size=6373
replace <fx>/config.json                   0o600  size=6373
… identical four-step sequence for .config.sha256 (size=65)
final config.json 0o600 | nodes.json 0o664 | .config.sha256 0o600
drift record is 64 hex: True | equals sha256(config.json bytes): True | contains any config byte-run: False
```

The mode is set on an **empty** descriptor before any byte is written, so the content never exists
at a wider mode at any instant; `nodes.json` at `0664` carries no credential in this fixture and is
HEAD's behaviour unchanged (T-23 AC-14 measured the same under the same umask). The drift record is
a digest of the file's **bytes** and contains no run of the config's bytes. The candidate's timeline
is identical to HEAD's, which is what the `json.dumps` hoist was required not to disturb.

### Boundary sweep, the two rows that matter (`re/boundary.txt`, `[R2]`)

```
candidate produced a traceback on: NONE
candidate echoed the sentinel VALUE on: ['B04 anchor echo (pre-existing)']
HEAD produced a traceback on: ['B22 deeply nested list']
B04  Cannot use <fx>/override.json: at dns.rules: $after matched 0 elements, but exactly one is
     required — match: {"nope": "ZQX-SENTINEL-VALUE-9f2a"}
```

B04 is `_anchor_index`'s pre-existing echo (`bin/sc:1400-1404`). It travels through
`except OverrideError: raise`, is neither introduced nor newly reached by this task, is explicitly
permitted by BC-4's scoping, was declined by `02_SOLUTION_DESIGN.md:294`, and is already re-homed as
a PM row by `01_RATIONALE.md` §"Re-homed findings". The delivered CHANGELOG's no-echo claim is
scoped to the class-name arm and does not reach it — verified by reading the shipped text, which is
what CR-8 closed at round 3. No new sentence echoes anything.

### Format-string injection (`re/qa2-probe.py` P1, `[R2]`)

A document-supplied key becomes `at {at}` through `t()`. If the key itself carried template
metacharacters and `t()` formatted after substitution, an override could inject into `sc`'s own
message. Five shapes tried (`{at}`, `{}`, `{0}`, `{fault}`, `%s`), all rendered literally:

```
Cannot use <fx>/override.json: at a{at}b: unknown directive $nope — use one of $prepend, …
Cannot use <fx>/override.json: at dns.rules: unknown directive $nope{fault} — use one of …
```

`t()` formats the key template once and inserts the value afterwards, so the value cannot become a
template. One line, exit 1, both files byte-identical on every shape.

## What neither attempt could measure

- **AC-15**, the shipped invocation — root, the installed `/usr/local/bin/sc`, the live service, and
  `/var/log/sing-box/install.log` as the observable. Operator obligation **id 5** carries V-12
  verbatim plus the instruction to rebuild M0/M1's depths **by bisection on that host**, never from
  the constants measured here. Nothing was substituted; this is the eighth consecutive time the
  discipline has held (obligations 1–4 are T-20, T-07, T-22, T-23).
- **`_init_files()`'s own writes.** It hard-codes `/var/lib/sing-box` as a literal that no harness
  can repoint, so every `main()`-driven fixture replaces it with a no-op. Whatever it would do on a
  real host is out of this stage's reach by construction (BC-12 / C-15).
- **A host without `sing-box`.** Measured at `[R3]` after all (`r2_no_singbox.py`, `SB_BIN` pointed
  at a name not on `PATH`): `bin/sc:2135` still has no `shutil.which` guard (F-14), so `sc reload`
  on HEAD raises an uncaught `FileNotFoundError` from outside the region — `exit=1 traceback=True`,
  with the broken document written and its digest baselined. It is outside FR-2 by Q-8 and outside
  this task; it stays a PM-owned re-homed row. What it settles is that the old "exit 0" clause had
  **no** host on which it was true, and that the replacement clause's checker attribution is
  host-scoped while its non-zero exit is not.
- **A second interpreter.** The M9 band is empty on CPython 3.12.3 at `sys.getrecursionlimit() == 1000`.
  On an interpreter with a different C-stack budget the ordering of the two thresholds could differ;
  the bisection method is in the obligation so it can be re-derived rather than assumed.
- **`inbounds` / `outbounds` at HEAD beyond the type-mismatch shape.** Both are now measured for the
  scalar shape and behave exactly as `dns.servers`; no other shape at those keys was enumerated.
