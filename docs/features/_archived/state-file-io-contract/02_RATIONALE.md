# 02 — Rationale · T-23 `state-file-io-contract`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

All line numbers are backward-looking citations against `bin/sc` as read on 2026-08-15. Verification
was **static** (source reading plus CPython semantics); this architect holds no `Bash` tool, so no
clause below was re-measured by execution. `01_RATIONALE.md` was opened under trigger **T2.1** (the
analyst's explicit hand-off of four design decisions) and is cited where used.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| "This document cannot be used" as an exception with a translated one-clause problem and a path | `OverrideError` + `main()`'s one rendering arm | `bin/sc:1179-1198`, `:3673-3690` | **Reuse as-is, unchanged.** `.path` already exists for exactly this purpose and already defaults to `None` → `CFG_PATH`. Buys FR-6 and FR-8 at 17 call sites for zero edits and zero new translation keys. |
| The four failure clauses (`cannot be read`, `not valid UTF-8 text`, `not valid JSON ({err})`, `the top level must be a JSON object`) | `TRANSLATIONS` | `bin/sc:350-356` | **Reuse verbatim**, in both languages. This is what makes NFR-2's "zero new keys" real rather than aspirational. |
| The shape of a locale-independent JSON reader (bytes → explicit UTF-8 decode → `json.loads` → `isinstance` → named clause per failure) | `_load_override()` | `bin/sc:1456-1496` | **Copy the shape, not the code.** Its `os.stat` first, `OVERRIDE_MAX_BYTES` cap, `S_ISREG` test and whitespace-as-absent rule are policies for the **user's** document (Q-11 rejects the cap for `sc`'s own), and out-of-scope item 1 forbids changing it. Collapsing the two is T-24's call → RT-2. |
| Non-TTY-safe rendering of foreign text inside a sentence | `_plain(text)` | `bin/sc:2412` | **Reuse** at the one new warning site, exactly as `main()`, `save_nodes()` and `generate_config()` do. |
| Atomic, 0600, encode-safe write of a credential document | `_write_private()` | `bin/sc:477-526` | **Reuse; add one argument.** Its `finally` already unlinks the temporary on any exception raised by `fh.write`, which is where an encode failure lands — so BC-11 is *preserved*, not bought (`01_RATIONALE.md` §"The write end"). |
| A cause clause for a write failure | `_plain(e.strerror or str(e))` | `bin/sc:552`, `:2082` | **Reuse the sentence, fix the accessor.** `getattr(e, "strerror", None) or str(e)` — `UnicodeEncodeError` carries no `strerror` (Q-9). |
| "Exactly once per run, before anything else" | `main()`'s single `LANG = _load_lang()` in both arms | `bin/sc:3656-3661` | **Reuse as the warn-once mechanism** instead of a module-level flag. See §"FR-5" below. |
| Single-writer discipline for a seeded document | `_init_files()`'s nodes branch through `save_nodes()` + its comment | `bin/sc:533-537` | **Extend to `settings.json`** — FR-12 makes the two branches symmetric, and the existing comment already states the reason. |
| Degrading settings reader (a shared "settings or default") | *(none found)* | — | New 8-line function justified: four readers currently repeat the judgment and produce three different wrong answers on a non-object document (`01_RATIONALE.md` table). |
| A per-document JSON schema / validation layer | *(none found, and none wanted)* | — | Not built (NFR-3, Q-5). One top-level shape check, parameterised by one member name. |

## Requirement coverage

| requirement | edit ids | note |
|---|---|---|
| FR-1 one reader, three outcomes | E-1, E-2, E-3, E-4, E-6 | outcome shape proved minimal below |
| FR-2 UTF-8 independent of locale, two causes | E-2 | K-1, K-2 |
| FR-3 one top-level shape check per document | E-2, E-17 | `member="nodes"` for the node store |
| FR-4 four accessors keep their defaults | E-5, E-6, E-7, E-9, E-10 | defaults fall out of `{}` |
| FR-5 exactly one warning line per run | E-5, E-6 | once-ness from `main()`'s call structure |
| FR-6 persisting commands abort | E-4 + I-8 (no edit) | nine call sites, zero edits |
| FR-7 never write an unusable `settings.json` | E-8 | discharges R-27 |
| FR-8 `nodes.json` commands abort | E-2, E-3 + I-8 (no edit) | seven call sites, zero edits |
| FR-9 `sc doctor` never aborts | E-16 | plus `_saved_clash_port` via E-7 |
| FR-10 every authored document UTF-8, literal non-ASCII | E-11, E-13 | drift record inherits E-11 |
| FR-11 no write reaches the user as a traceback | E-12, E-15 | scoped to the two existing renderers; RT-4 |
| FR-12 one writer of `settings.json` | E-14 | |
| BC-1 / BC-2 / BC-3 | E-2, E-4, E-5, E-7, E-9, E-10 | BC-3's substring accident dies with the `isinstance` |
| BC-4 | *(frozen)* | unrecognised-value notices untouched |
| BC-5 / BC-6 | E-2, E-3 | absent node store → `cannot be read (No such file or directory)` |
| BC-7 empty `nodes` array stays success | E-2 | the check is `isinstance(..., list)`, never truthiness |
| BC-8 read whole or not at all | E-2 | one `read_bytes()`; writer still renames |
| BC-9 per-element residual | E-16 | doctor keeps `TypeError` / `KeyError` |
| BC-10 lone surrogate on the write path | E-11, E-12, E-15 | |
| BC-11 failed write leaves the document intact | *(preserved)* | K-4 |
| BC-12 English for the `settings.json` class | E-6 | structural: the warning precedes `LANG`'s assignment |
| BC-13 `sc on` / `sc off` ordering | *(unchanged)* | RT-5 |
| BC-14 tags do not become printable | E-18 (K-15) | |
| BC-15 re-probed port each run | E-8 | accepted consequence of FR-7 |
| BC-16 drift digest over bytes | *(frozen)* | AC-16 |
| AC-1 … AC-21 | V-1 … V-21 | `## Verification plan` |
| NFR-1 … NFR-9 | budget below; K-4, K-11, K-13, K-14, K-16 | |

## The four decisions the analyst handed to stage 2

### 1. Route the state-document failure through `OverrideError` — reuse, no rename, no sibling

`main()`'s arm (`bin/sc:3675-3690`) already renders `Cannot use {path}: {problem}` for a path chosen at
the raise site, in both languages, with exit 1 on stderr. Routing through it is the difference between
**zero** edits and **sixteen** at the unguarded call sites, and it is the only option that keeps AC-18's
count at three.

The three alternatives and their prices: a **sibling class** duplicates the judgment "a document cannot
be used" and adds a second arm to a site whose whole design is being the only one (rule 85 test 2); a
**rename** to a document-neutral name is `+23 / −23` across 18 `raise` sites, three `except` clauses and
one class, for zero behaviour — it alone would consume a third of NFR-1's budget and would collide with
T-24's diff line-for-line; **not routing through it** costs 16 guards and fails AC-18 by 13.

**What the choice costs T-24, stated so it is not discovered later:** the class name is now narrower
than its population. T-24 inherits three obligations — (a) a rename or re-parenting must move exactly
one construction site, `_unusable()`, which is why that factory exists as a named function rather than
as five inline `err.path = …` blocks; (b) `main()`'s arm must keep honouring `e.path` and must not be
narrowed to "the user's override"; (c) if T-24 collapses `_load_override()` into `_read_state()` it must
keep the override's stat-first ordering, size cap and whitespace-as-absent rule. All three are filed as
RT-1 / RT-2. Nothing in this design *forces* T-24 to unpick anything: the override's own code,
sentences and behaviour are byte-identical after this task.

### 2. FR-1's return shape, proved minimal in both directions

The reader answers with **the document**, **the caller's `default`**, or **a raised
`OverrideError(problem, path)`**. Each component is unrecoverable from the others:

- Drop *absent* (fold it into unusable): BC-1 / AC-4 forbid a warning or a failure on an absent
  `settings.json`, and FR-5 distinguishes the two states explicitly.
- Fold *absent* into *usable* by always returning `{}`: legal, one parameter smaller — and it tells a
  user whose `nodes.json` was deleted that its `"nodes"` member is not an array. Rejected on honesty;
  FR-8 requires the cause, not a cause.
- Make *unusable* a return value instead of a raise: 17 call sites must test it (AC-18 fails by 14).
- Drop the problem clause: FR-2 and FR-3 name five distinct causes and AC-1 / AC-3 / AC-8 assert them.
- Drop `.path`: `e.path or CFG_PATH` then names `config.json` for a `nodes.json` failure. FR-6 and FR-8
  both say "naming the file".

The `default` parameter is what makes *absent* a caller's decision rather than a second reader:
`load_settings()` supplies `{}` ("an absent settings document is an empty one" — which is precisely
BC-1's behaviour), `load_nodes()` supplies none ("absence is a failure" — BC-5), and neither needs a
guard of its own. `member` is the same trick for FR-3's one shape check.

### 3. FR-5's warn-once: no new global, no flag, no memoisation

The once-per-run state is **`main()`'s call structure**, which already guarantees exactly one
`_load_lang()` per run in both arms (`bin/sc:3656-3661`) and before every command including `doctor`
and `config` — R-25's own central claim, re-confirmed by grep: `_load_lang` has no other caller in the
file. Two properties come free: the line is emitted **before `LANG` is assigned**, so it renders in
English exactly as BC-12 requires, without anyone remembering to force it; and the three other
accessors stay silent with no coordination.

**Memoising `_settings_or_empty()` was considered and is a live defect, not a style choice.**
`cmd_ipv6()` computes `before = ipv6_decision()[1]`, writes the file, then re-reads to compute `after`
(`bin/sc:3124-3132`); a cached document makes `after == before` always, so `sc ipv6 on` would print
"Nothing changed — the sing-box service was not touched" and never regenerate. `cmd_telemetry()` has the
same before/after shape (`:3187-3197`). A module-level `_WARNED` flag was the remaining option and was
rejected as a new global that a fixture must reset between runs.

**Accepted consequence, stated rather than hidden:** on a command that both degrades *and* aborts —
`sc lang zh` on an unusable `settings.json` — the user sees the warning line and then the abort sentence
with the same text, one prefixed `⚠️`, one carrying the exit status. Suppressing the second would need
the flag this design refuses; suppressing the first would need `_load_lang()` to know which command is
about to run. AC-6 asks for one sentence and a non-zero exit, and both are present; V-23 counts warning
lines, not sentences.

### 4. FR-12's single writer, and why it is in this row at all

`_init_files()` (`bin/sc:538-540`) composes and writes `settings.json` directly while deliberately
routing the nodes seed through `save_nodes()` with a comment explaining why. Rule 85's own test settles
it: "add an encoding" is exactly the second edit the duplicated writer forces — this task would have to
add `encoding="utf-8"` twice, and the next one would too. Routing the seed through `save_settings()`
costs `+1 / −2` and makes the asymmetry disappear. The seeded bytes are unchanged (the dict is pure
ASCII, so `ensure_ascii=False` is a no-op on it), which is what keeps AC-13 true for a fresh host.

### 5. FR-11's cause clause, and why `save_settings()` is *not* widened

`e.strerror` on a `UnicodeEncodeError` raises `AttributeError` **inside the error handler** — the
handler for the exception FR-11 exists to render. `getattr(e, "strerror", None) or str(e)` is the
minimal form that keeps HEAD's output for an `OSError` (`Permission denied`, not
`[Errno 13] Permission denied: '/etc/sing-box/nodes.json'`) and produces a non-empty clause for a
`ValueError`. It lands at two sites; a `_cause(e)` helper would add two lines to save none and prevents
no nameable future edit, so it is inlined (rule 85's counter-rule).

`save_settings()` deliberately gets **no** guard. FR-11 says the sentence is rendered "at the site that
already renders it", and its second half — "leaves the previous document byte-identical with no
temporary file surviving" — describes `_write_private()`'s atomic install, which out-of-scope item 7
and Q-10 explicitly exclude `settings.json` from. A guard there would be six unbudgeted lines for a
property the requirement declines to ask for; the hole is real, pre-existing and filed as RT-4.

## Budget excess

**Spent: `+70 / −43` in `bin/sc`, of which 46 added lines are code.** NFR-1's figures are `+70 / −30`
with ≤40 added code lines, so the excess is **+6 code lines** and **−13 deletion**.

NFR-1's itemisation models the degrade as "four guard tuples narrowed" (`+4 / −4`) and models neither a
warn-once home nor a path-carrying raise. This design instead spends `+8` on `_settings_or_empty()` and
`+4` on `_unusable()`, and **deletes 12 lines** the itemised model keeps (four `try` / `except` /
`return` blocks at `:415-418`, `:1571-1574`, `:1790-1793` and `:389-392`). Reckoned as net file growth —
which is the size rule 85 actually cares about — the itemised model grows `bin/sc` by ≈19 lines and this
design grows it by 16. The −13 deletion excess is 11 lines of `_telemetry_setting()`'s
"THE SILENCE HAS TWO HOLES" docstring paragraph (`:1768-1778`), which this change makes **false**, plus
two lines of `_ipv6_setting()`'s matching clause. Leaving a docstring that describes closed holes as
open would be worse than the overrun.

Cutting order if the developer lands over `+70`: docstring lines first (`_read_state` 7 → 5,
`_settings_or_empty` 4 → 3), never a line named in the change ledger.

## Risk analysis

| # | risk | mitigation | AC that catches it |
|---|---|---|---|
| R1 | The abort path repeats the warning's sentence (§3 above), and a reviewer reads AC-6's "one sentence" literally. | Disclosed in the contract (K-7's neighbourhood) and here; the abort sentence is the one carrying the exit status, and V-23 counts *warning* lines specifically. | AC-6, AC-3 |
| R2 | `except OverrideError` at the four accessors is *too* narrow — a real `OSError` escapes and tracebacks. | It cannot: `_read_state` converts every `OSError` from `read_bytes()` into `OverrideError`, and the accessors touch no other file. The narrowing is *to* the reader's total outcome, which is the point of Q-1's answer. | AC-1, AC-3 |
| R3 | `ensure_ascii=False` on `save_settings()` breaks AC-13's byte-identity for a `settings.json` holding a non-ASCII value. | No `sc` code path can put one there — `lang`/`mode`/`ipv6`/`telemetry`/`default_tun`/`clash_api_port` are validated enumerations, and both `update-interval` arms exit before the save when the value is not accepted by systemd or by `PERIODIC_DIRS`. Where a hand-edited value exists, the new bytes decode to the same value and the difference is FR-10's stated intent. AC-13's differential must therefore use documents `sc` itself authors. | AC-13 |
| R4 | Adding `encoding=` disturbs `_write_private()`'s descriptor dance and a credential lands at a wider mode or a temp survives. | K-4 freezes every other element; `os.fdopen` takes the fd *after* `os.fchmod`, and the argument changes only how the wrapper encodes. V-15 reads the shipped function; V-14 stats every product. | AC-15, AC-14, BC-11 |
| R5 | `_load_lang()` now depends on `load_settings()`, which is defined ~170 lines below it; a reader thinks it is a forward reference bug. | Name resolution is at call time, and the file already does exactly this (`_saved_clash_port` `:407` calls `load_settings` `:555`). Recorded in the docstring. | AC-5 (a build where it fails renders English on a `zh` fixture) |
| R6 | A fixture drives `main()` and `_init_files()` writes the real `/var/lib/sing-box` — the standing safety trap of this repo. | K-13 requires replacing `sc._init_files` with a no-op **before** driving `main()`, on top of the eight repointed constants and the assertion that each resolves inside the temp root. FR-12's own verification is [S] plus a direct `save_settings()` call, never a driven `_init_files()`. | NFR-7 (binding on stages 4 and 6), V-22 |
| R7 | Doctor's guard loses `OSError` / `ValueError` and a future path inside that `try` raises one, aborting the row. | The `try` covers three statements only (`load_nodes()`, `len`, a set comprehension); `stored_delays()` is outside it, and `cmd_doctor`'s per-section `except Exception` isolation is the backstop that keeps the table complete either way. | AC-9 |
| R8 | A future accessor calls `load_settings()` and aborts where it should degrade (or the reverse). | Two names that differ in exactly the right way, one dev-map row (E-19), and RT-6. The default direction — abort — is the safe one for the nine persisting commands, which are the majority. | AC-18 (the count would grow) |
| R9 | The new translation key is judged a violation of NFR-2. | NFR-2 says zero keys are *required*; AC-17 permits one that carries a zh entry and no `失败`. The alternative — reusing `the top level must be a JSON object` for a `{}` node store — states something false about the document. | AC-17 |

## Evidence and citations

- HEAD's two readers and the fourteen reads: `01_RATIONALE.md` §"The two readers and the fourteen
  settings reads", re-checked by grep — `load_settings()` has 13 call sites (`:416`, `:439`, `:1572`,
  `:1791`, `:2345`, `:2357`, `:3090`, `:3125`, `:3188`, `:3217`, `:3377`, `:3416`, `:3454`),
  `load_nodes()` 8 (`:2017`, `:2199`, `:2237`, `:2271`, `:2282`, `:2308`, `:2376`, `:2763`), and
  `_load_lang()` 2 (`:3657`, `:3660`).
- The three different wrong answers a non-object `settings.json` produces, reader by reader:
  `01_RATIONALE.md` §"What a non-object `settings.json` actually does" — the source of Q-1's ruling that
  the `isinstance` check, not the catch tuple, is the fix.
- T-13's construction and why each element is load-bearing:
  `docs/features/_archived/config-write-permission-hardening/02_SOLUTION_DESIGN.md`; the umask bracket
  and the shared-writer helper were both declined there
  (`.harness/rejected-decisions.md` §`umask-bracket-for-credential-writes`,
  §`shared-atomic-write-helper-with-ruleset-downloader`).
- T-14's byte-digest record: `bin/sc:1906-1928` reads through `CFG_PATH.open("rb")`, so NFR-6 is
  preserved by not touching it.
- T-22's precedent for the shape of this ruling — a smaller design confirmed correct on every FR and
  rejected only because one FR made the *premise* checkable:
  `.harness/rejected-decisions.md` §`share-url-userinfo-five-local-fixes`.
- The locale recipe V-11 / V-12 pin, measured by stage 4 on this host (python 3.12.3):
  `LC_ALL=C` → `stdout=utf-8 preferred=utf-8`; `LC_ALL=C PYTHONCOERCECLOCALE=0` → `stdout=utf-8
  preferred=utf-8`; `LC_ALL=C PYTHONCOERCECLOCALE=0 PYTHONUTF8=0` → `stdout=ascii
  preferred=ANSI_X3.4-1968` (`04_RATIONALE.md` §"Lie 2"). `PYTHONCOERCECLOCALE=0` disables PEP 538
  coercion only; PEP 540 UTF-8 Mode is auto-enabled whenever `LC_CTYPE` is `C`/`POSIX` and needs
  `PYTHONUTF8=0` to switch off. Under the two-variable recipe HEAD stores `péq` correctly and rewrites a
  `香港节点` fixture without error, so both controls were void and both steps would have certified the
  unfixed build — hence V-11/V-12 pin all three variables and assert the environment before crediting
  any assertion made in it. With the flag added, stage 4 measured `UnicodeEncodeError` (V-11, nothing
  stored) and `UnicodeDecodeError` (V-12, node count unchanged) at HEAD, and both disk clauses holding
  on the candidate; both builds then die at `bin/sc:2345` on the arrow, which is why the exit clause is
  BLOCKED-BY-T-25 rather than an observable. `01_RATIONALE.md` §"The write end" had R-62's original
  measurement right (`LC_ALL=C PYTHONUTF8=0`); the flag was dropped downstream of it.
- Insight index entries consumed: `Path.read_text()` → `UnicodeDecodeError` is a `ValueError`
  (2026-08-14, applied at K-1/K-2); `main()` reassigns `LANG` after import (2026-08-01, applied at K-14
  and §3); `_init_files()` hard-codes `/var/lib/sing-box` (2026-08-01, applied at K-13/R6);
  `settings.json` is 0644 on every default install (2026-08-14, applied at the frozen set and RT-4);
  `verify_all.sh` must run from the repository root (2026-08-15, applied at V-20).
- `.harness/rejected-decisions.md` was read before designing: no record covers a state-file reader, an
  exception envelope for `sc`'s own documents, or an encoding argument, so nothing here re-litigates a
  prior decline. Two records to append **at delivery** (PM-owned, `.harness/**` is outside this task's
  diff): the smaller design of §"Smaller alternative rejected" and the declined `save_settings()` write
  guard.
