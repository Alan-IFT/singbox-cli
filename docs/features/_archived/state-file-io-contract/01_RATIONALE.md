# T-23 · state-file-io-contract — Rationale

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## Evidence — the family as it exists at HEAD

All line numbers are backward-looking evidence citations against `bin/sc` as read on 2026-08-15.
Verification was **static** (source reading plus CPython semantics): this analyst holds no `Bash`
tool, so no clause below was re-measured by execution. Every clause marked *measured* was measured
by an earlier stage and is cited to it.

### The two readers and the fourteen settings reads

- `load_settings()` (`bin/sc:555-556`) is `json.loads(SETTINGS_PATH.read_text())` — no `encoding=`,
  no catch, no shape check. `load_nodes()` (`:543-544`) is its twin for `nodes.json`.
- `_load_lang()` (`:388-392`) does **not** call `load_settings()`; it repeats the read inline and
  guards `(FileNotFoundError, json.JSONDecodeError, OSError)`. It runs in **both** arms of `main()`
  (`:3656-3660`), so it precedes every command including `doctor` and `config` — R-25's central
  claim, confirmed.
- The same three-name tuple appears at `_saved_clash_port()` (`:415-418`), `_resolve_clash_port()`
  (`:438-441`), `_ipv6_setting()` (`:1571-1574`) and `_telemetry_setting()` (`:1790-1793`).
  `UnicodeDecodeError` is a `ValueError` but not a `JSONDecodeError`, so it passes all four.
- Unguarded read-modify-write call sites of `load_settings()`: `:2345` (`sc on`), `:2357`
  (`sc off`), `:3090` (`sc mode`), `:3125` (`sc ipv6 <value>`), `:3188` (`sc telemetry <value>`),
  `:3217` (`sc default-tun`), `:3377` and `:3416` (`sc update-interval`, two arms), `:3454`
  (`sc lang`). Nine, not one.
- Unguarded call sites of `load_nodes()`: `:2017` (`generate_config`), `:2199` (`_resolve_node`,
  behind `use` / `rm`), `:2237` (`sc ls`), `:2271` (`sc now`), `:2282` (`sc use auto`), `:2308`
  (`sc add`), `:2376` (`sc status`). The eighth, `:2763` in doctor, is guarded — and correctly.

### What a non-object `settings.json` actually does, reader by reader

R-29 states one outcome (`TypeError: argument of type 'NoneType' is not iterable`). Reading the four
readers gives three:

| reader | access | `null` / `42` | `"telemetry"` (a JSON string) |
|---|---|---|---|
| `_load_lang()` `:390` | `.get("lang", …)` | `AttributeError` | `AttributeError` |
| `_saved_clash_port()` `:419` | `.get("clash_api_port")` | `AttributeError` | `AttributeError` |
| `_ipv6_setting()` `:1575` | `"ipv6" not in settings` | `TypeError` | **no exception** — `"ipv6"` is not a substring, so it returns `auto` |
| `_telemetry_setting()` `:1794` | `"telemetry" not in settings` | `TypeError` | `TypeError` at `settings["telemetry"]` — the substring *is* present |

`AttributeError` is not in R-29's prescribed `(OSError, ValueError, TypeError)`. This is why the
contract puts the shape check inside the reader (FR-1/FR-3) instead of widening four tuples: the
tuple-widening prescription closes two of the four readers and leaves a silently wrong answer in a
third.

### The write end

- `_write_private()` (`:504-521`) opens the descriptor with `os.fdopen(fd, "w")` (`:509`) — locale
  encoding — while `save_nodes()` (`:549`) and `generate_config()` (`:2079`) dump with
  `ensure_ascii=False`. R-62 *measured* the resulting `UnicodeEncodeError` under
  `LC_ALL=C PYTHONUTF8=0` at exactly these three anchors, and the anchors it recorded (`:477`,
  `:549`, `:2079`) still resolve to those functions today.
- `save_settings()` (`:559-560`) writes with `write_text()` and `ensure_ascii` at its default
  `True`, so its bytes are pure ASCII and it cannot raise on encode today; it is in the family for
  the explicit-encoding clause and for FR-12 only.
- `_init_files()` (`:538-540`) is a **second** writer of `settings.json`, while it deliberately
  routes the `nodes.json` seed through `save_nodes()` (`:533-537`) with a comment saying why. FR-12
  makes the two symmetric; rule 85's own test justifies it, because "add an encoding" is precisely
  the second edit the duplicated writer would otherwise force.
- `_config_digest()` (`:1906-1928`) hashes through `CFG_PATH.open("rb")`, so T-14's record is immune
  by construction (NFR-6 keeps it that way).
- The cleanup in `_write_private()`'s `finally` (`:519-526`) already covers a failure raised by
  `fh.write`, which is where an encode failure lands — so BC-11 preserves a property rather than
  buying one.

### The contract already exists in this file, twice

- `_load_override()` (`:1455-1496`) is the complete shape: bytes read, size cap, explicit
  `raw.decode("utf-8")`, `json.loads`, `isinstance(doc, dict)`, each failure a named clause; and
  `main()` (`:3673-3690`) renders all of them at **one** site as `Cannot use {path}: {problem}` with
  a `path` the raise site chose. T-22's lesson (a brief's "reference implementation" turning out to
  be a member of the defect family) does not apply here: this reader is locale-independent by
  construction. Stage 2 should look hard at whether the state-document failure can travel through
  that same envelope — it would give FR-6 and FR-8 seventeen call sites' worth of behaviour for one
  arm — while noting that the class is named for the override and T-24 owns that name.
- `cmd_config()` (`:3039-3058`) distinguishes absent / unreadable / not-JSON / not-an-object with
  four existing sentences; doctor's node-delay row (`:2762-2770`) and `_doctor_ipv6()` (`:2633-2644`)
  do the same in report form. The vocabulary FR-5/FR-6/FR-8 need is therefore already in
  `TRANSLATIONS` with Chinese entries at `:294`, `:347`, `:350`, `:351`, `:355`, `:356` and `:295` —
  which is what makes NFR-2's "zero new keys" credible rather than aspirational.

### Why the output layer is a different destination

`sys.stderr` is created with `errors="backslashreplace"` (CPython ≥ 3.5) while `sys.stdout` encodes
strictly, so every sentence this row adds — all of which go to stderr, via `sys.exit(str)` or
`sys.stderr.write` — is safe under `LC_ALL=C`, and every non-ASCII *tag* printed by `cmd_ls`
(`:2263-2267`) or `cmd_config` (`:3074`) is not. That asymmetry is the whole reason Q-6 and Q-8
resolve the way they do: giving `cmd_config`'s read a UTF-8 decode would convert T-06's *measured
good shape* (`cannot read …: 'ascii' codec can't decode byte 0xe9`, exit 1, one sentence) into a
traceback on the stdout write.

**The non-UTF-8 environment, as measured (stage 4, python 3.12.3 on this host).** `LC_ALL=C` plus
`PYTHONCOERCECLOCALE=0` is **not** a non-UTF-8 Python. PEP 538's C-locale coercion is indeed
suppressed by that pair, but PEP 540 then auto-enables UTF-8 Mode for any `C`/`POSIX` `LC_CTYPE`, so
`sys.stdout.encoding`, `locale.getpreferredencoding(False)` and the filesystem encoding all stay
UTF-8 and every encoding assertion passes on broken and fixed code alike. Measured:
`LC_ALL=C PYTHONCOERCECLOCALE=0` → `stdout=utf-8 preferred=utf-8`; adding `PYTHONUTF8=0` →
`stdout=ascii preferred=ANSI_X3.4-1968`. R-62's own measurement used `LC_ALL=C PYTHONUTF8=0`, which
is what the evidence above records; the first round of AC-11/AC-12 dropped that flag, so both
criteria passed vacuously at HEAD — the R-22 failure this row exists to design against, reproduced
inside its own criteria. AC-11/AC-12 now pin all three variables and make the environment a **proved
precondition**: an assertion made in a vacuously-UTF-8 environment is not evidence and credits
nothing.

## Related prior work (links, not re-descriptions)

- `docs/tasks.md` — R-17, R-25, R-27, R-29, R-62, and the unnumbered T-06 paragraph
  (`docs/tasks.md:185-200`) that supplies the acceptance oracle.
- `docs/features/_archived/config-write-permission-hardening/` (T-13) — NFR-5's source.
- `docs/features/_archived/config-composition-layer/` (T-14) — NFR-6's source; R-17's origin.
- `docs/features/_archived/sc-config-show/` (T-06) — the measured good shape and the repo-wide class.
- `docs/features/_archived/share-url-userinfo-contract/07_DELIVERY.md` (T-22) — R-62's measurement,
  the diff bar (+21/−11), and the precedent for filing a root-only criterion as an operator
  obligation rather than substituting for it.
- `docs/features/_archived/status-egress-via-clash-api/` (T-18) — Q-5's absent-file finding for
  `load_nodes()`, and the `CLASH_PORT` fixture trap that NFR-9's sibling insight records.
- `docs/batches/followups/BATCH_PLAN.md` — the T-23 row and its Notes bullet; T-24/T-25/T-28 own the
  scope this row declines.

## Candidates considered, and why the binding answers won

- **Q-1, widen the catch tuples in place (R-29's literal prescription).** Rejected: it misses
  `AttributeError` at two readers and cannot see the substring accident at a third, and it leaves
  four copies of the judgment — exactly the "three guard tuples" the row exists to remove.
- **Q-2, degrade `nodes.json` to an empty node list.** Rejected: `sc add` would then write a
  one-node file over the user's unreadable-but-recoverable node store, turning a display failure
  into data loss. Abort is the only answer that cannot destroy nodes.
- **Q-2, abort on `settings.json` for the accessors too.** Rejected: `_load_lang()` runs before every
  command, so aborting there would defeat `sc doctor` on precisely the wrecked host T-05 built it
  for — R-25's own complaint, inverted.
- **Q-3, stay silent (the current docstrings' promise at `:1561` and `:1763`).** Rejected: with no
  doctor row for state-document health, silence means a user whose `lang`/`mode` stopped taking
  effect has no signal anywhere. Considered and rejected as too large: a new `sc doctor` row (new
  keys, new surface, T-26's territory) and a per-reader warning (up to four identical lines per run).
- **Q-7, `ensure_ascii=True` everywhere.** Genuinely smaller on the write side and it would make the
  locale irrelevant for `sc`-authored bytes — but it does not remove the need for a UTF-8 decode on
  the read side (users hand-edit these files), and it turns every CJK tag in `config.json` and
  `nodes.json` into `\uXXXX` on disk, which T-14 chose against deliberately. Recorded here because
  rule 85 puts the burden of proof on the larger design and this is the smaller one that lost.
- **Q-8, harden the output streams in this row (three lines at the top of `main()`).** Rejected on
  the seam test: the terminal is a different destination with different semantics (mojibake versus
  an exception), the 3.6 floor makes `sys.stdout.reconfigure()` unavailable, and T-25 is two rows
  away and named for exactly this. Re-homed, not dropped — see "Findings to re-home" below.
- **AC-11/AC-12's exit clause: drop it, keep it as a pass/fail, or split it.** Dropping it was
  rejected — a criterion quietly weakened is as bad as one that over-promises, and "exits 0" is the
  clause a future reader would otherwise assume this row bought. Keeping it as a pass/fail was
  rejected — under the proved environment correct code cannot satisfy it, because the failure is the
  stdout encode of `cmd_add`'s own success line (an sc-authored `U+2192`, not a node tag), which is
  out-of-scope item 2 / BC-14 / T-25's territory; a criterion correct code must fail is a false
  signal in the other direction. The split wins: the disk state is owed and verified by this row, the
  process exit status is named and marked BLOCKED-BY-T-25, and the row stays discriminating because
  a `UnicodeEncodeError`/`UnicodeDecodeError` from the *state-document* path — the failure this row
  does own — remains a FAIL wherever it is raised.
- **AC-8's control: restate the control, or narrow the criterion.** Narrowing (dropping the `{}` ×
  `sc now` cell) was rejected: that cell discriminates perfectly well — HEAD prints `(none)` and
  exits 0, the candidate exits non-zero naming the file — and it is the only cell that catches a
  build which reads `active` without ever checking the `nodes` member. Only the *control* was wrong,
  so only the control is restated.
- **Q-10/Q-11, one universal document reader with a size cap, atomic writes and a mode policy.**
  Rejected as the over-build the counter-rule in rule 85 forbids: none of it is needed to close the
  defect family, and each element adds a failure mode with no filed row behind it.

## Findings to re-home (for the PM, not for this task's diff)

1. **The output-stream residual belongs to T-25.** Under a non-UTF-8 locale, `cmd_ls` and
   `cmd_config` raise `UnicodeEncodeError` while encoding their own stdout; this row makes the tag
   survive on disk and cannot make it printable. T-06 already named `cmd_ls` as part of the class.
2. **Two stale anchors.** R-25 cites `_load_lang()` at `bin/sc:312-314` (now `:388-392`) and the
   insight index cites `bin/sc:1712` as the repo's model `(OSError, ValueError)` guard (that line is
   now inside a DNS overlay). The living instances of the model shape are `_drift_state()` `:1970`,
   `_doctor_ipv6()` `:2635` and `cmd_config()` `:3043`.
3. **Proposed `CONTEXT.md` glossary entry, not written (this task's dispatch permits two files).**
   **state document**: a JSON file under the configuration directory that `sc` both authors and
   reads as its own persistent state — today `settings.json` and `nodes.json`. `config.json` is
   authored by `sc` but read by `sing-box`, and `override.json` is authored by the user; neither is a
   state document. Orthogonal to *credential document*, which classifies by content, not by role —
   `nodes.json` is both. _Avoid_: state file, config file, data file.
