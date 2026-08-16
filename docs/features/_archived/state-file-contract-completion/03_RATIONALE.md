> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## G-1 — how the re-derived arm was checked, and why it is closed

The round-1 defect was width, so the re-review is an enumeration, not a reading of the prose. Every
`OverrideError` that can leave `generate_config()` was traced to its raise site in `bin/sc` and its
`.path` read there:

1. **The override wrapper** — `:2057-2061`. `_load_override()` raises bare `OverrideError`s
   (`:1535`, `:1539`, `:1541`, `:1546`, `:1548`, `:1552`, `:1558`, `:1560`), all with `.path` unset;
   the wrapper assigns `e.path = OVERRIDE_PATH` and re-raises. Its `except Exception` sibling
   (`:2062-2064`) builds `_unusable(OVERRIDE_PATH, …)`. Both ⇒ `OVERRIDE_PATH`.
2. **The node store** — `load_nodes()` at `:2066` → `_read_state(NODES_PATH, member="nodes")` →
   `_unusable(NODES_PATH, …)` at `:573`, `:575`, `:577`, `:579`, `:581`. ⇒ `NODES_PATH`.
3. **FR-6's new statement** — `load_settings()` → `_read_state(SETTINGS_PATH, default={})` ⇒
   `SETTINGS_PATH`, and only for a **present** document: `default={}` is not `None`, so a
   `FileNotFoundError` returns `{}` at `:571-572` and BC-1 holds untouched.
4. **The composition region** — `:2098-2136`: the inner `_merge` wrapper (`:2102-2104`) forces
   `OVERRIDE_PATH`; the array-shape clause (`:2113`) and the fault clause (`:2134`) build
   `_unusable(OVERRIDE_PATH if override is not None else None, …)`. ⇒ `OVERRIDE_PATH` or `None`.

`if e.path != SETTINGS_PATH: raise` therefore re-raises 1, 2 and 4 and falls through only for 3.
Three details make that airtight rather than merely true today:

- **`None` sorts to the re-raise**, which is the safe direction, and the class default `path = None`
  (`:1256`) means an `OverrideError` raised by some future site that forgets to set `.path` also
  re-raises instead of being silently absorbed. The guard fails safe.
- **Nothing else in `generate_config()`'s call graph can raise with `.path == SETTINGS_PATH`.** The
  only other reader of `settings.json` under it is `_resolve_clash_port()`, which catches
  `OverrideError` at `:445-447` and returns the probed port; every overlay reads settings through
  `_settings_or_empty()` (`:1636`, `:1839`, `:424`), which never raises. So the arm cannot absorb
  a settings failure it did not cause.
- **`Path.__eq__` is value equality**, and both sides read the module global when the call runs, so a
  fixture repointing `SETTINGS_PATH` moves raise site and guard together, exactly as I-3 claims.

The rejected alternatives were re-checked rather than accepted: the `if/else` spelling really is one
line longer for identical behaviour; a `SettingsError(OverrideError)` subclass really does cost a
class plus a raise-site wrapper for a discrimination `.path` already carries, and `bin/sc:3781-3785`
really does state that this project answers "whose document" with an attribute and needs no exception
taxonomy. Dropping E-10 really would leave FR-6's own refusal with no outcome line. The taken shape
is the smallest correct one. **G-1 is closed at all four raise sites.**

## G-2 — why AC-19 discriminates

The build C-1's negation produces is one undifferentiated `except OverrideError:` at `:3396`. On
AC-19's fixture (usable `settings.json`, unusable `override.json`) that build sets `regen_ok = False`,
skips `:3397-3399`, prints `Rule-sets updated: … — the sing-box service was not touched` and exits 1
with the cause named nowhere — no pre-dispatch degrade line exists, because settings is usable. AC-19
demands a sentence naming `override.json` with a non-empty cause; the mutant supplies none, so the row
fails it. That is a real kill, not an absence-of-traceback pass, and V-19 names the mutant as the
control rather than HEAD, which is correct because HEAD passes the row (`main()`'s envelope renders
`.path`). The second case swaps in a `nodes.json` whose top level is an array, which `_read_state`
rejects at `:579` with `.path = NODES_PATH`, and nothing in `cmd_update_rules()` reads the node store
before `generate_config()` does.

## Ruling on the NFR-1 spend — and on NFR-1

Checked line by line against `bin/sc`, and the arithmetic first:

| hunk | added | removed | code | comment |
|---|---|---|---|---|
| E-1…E-6 (`:1667`, `:2015`, `:2705`, `:3121`, `:3451-3453`, `:3499`) | 6 | 6 | 6 | 0 |
| E-7 (`:615-617` → `save_nodes()`'s shape at `:589-595`) | 6 | 1 | 5 | 1 |
| E-8 (`:449-452`) | 2 | 1 | 1 | 1 |
| E-9 (between `:2065` and `:2066`) | 3 | 0 | 1 | 2 |
| E-10 (`:3396`) | 7 | 1 | 6 | 1 |
| **total** | **24** | **9** | **19** | **5** |

+24 ≤ +25, −9 ≤ −12, 5 comment ≤ 6, and 19 code against ≤14. K-11's itemisation
(`+1, +1, −1, +4` on 14) sums to 19 exactly. The declared numbers are right.

Each line, first-hand:

- **The six codec lines are forced and at budget.** The population is closed: `:520` and `:617`
  already name UTF-8, `:569` decodes explicitly, and `:932` / `:1196` / `:1543` / `:1966` / `:2640`
  are binary by a literal mode. Six sites, six arguments.
- **E-7's five.** `save_nodes()` (`:589-595`) is itself five code lines plus one comment. A faithful
  mirror cannot be four. Collapsing the `sys.exit(t(...))` onto one physical line would run ~125
  characters; only 51 of `bin/sc`'s ~3790 lines reach 100, and none of them is a handler. The mirror
  is both smaller-in-concept and the shape K-3's frozen mechanism already uses. **Earned.**
- **E-8's one.** `except OSError:` → `except SystemExit:` is one word on an existing line, counted
  `+1/−1` under precisely the accounting NFR-1 used for its six codec lines. FR-5 is a stated
  requirement with **no budget line at all**. **Earned.**
- **E-9's minus one.** FR-6 is one statement where the provenance assumed two. A real saving, and the
  single best evidence that the design is not padded.
- **E-10's six.** Two are the `try:` and the re-indented `regen_ok = generate_config()` — the
  mechanical cost of wrapping any statement, which the provenance's "+2 for FR-7" did not model while
  charging a full line for a one-word codec edit. Two are `except OverrideError as e:` and
  `regen_ok = False`, which *is* the "+2". Two are the guard `if e.path != SETTINGS_PATH:` and
  `raise` — the lines this gate itself required in round 1, buying three documents their sentence.
  **All six earned.**

**Ruling: the whole spend is justified and no line comes out.** And the honest statement about the
budget: NFR-1's provenance is internally inconsistent. It priced a modified line as an added line for
the codec sweep, then priced the renderer at +4 while naming a five-line renderer as the shape to
mirror, priced FR-7 at +2 for a construct that cannot exist without a `try:` and a re-indent, and
omitted FR-5 entirely. Under its own accounting the design it described costs **17** added code
lines — 6 + 5 + 1 + 1 + 4 — before the guard; with the guard this gate required, **19**. The correct
number was always 19; 14 is a defect in the budget, not an overage in the design. What actually
guards against bulk here is not the arithmetic but the deletion test, and this change passes it: zero
new functions, classes, modules, files, keys, flags, formats or seams; the whole product change is
six arguments, one guard mirroring an existing guard, one statement and one try/except.

## Ruling on AC-19's outcome-line clause

The analyst's "at most one" is right and the PM's stricter gloss would have been wrong. Three
observations, all first-hand:

1. **HEAD already prints none on this path.** `cmd_update_rules()` calls `generate_config()` at
   `:3396`; the outcome block is `:3410-3420`. An `OverrideError` from any of the four raise sites
   leaves the function above the block, reaches `main()`'s envelope and exits 1 with
   `Cannot use {path}: {problem}`. So the re-raise arm does not *break* a contract HEAD kept — it
   **preserves HEAD byte for byte**, which is exactly what out-of-scope 7 and I-3 promise.
2. **The comment at `:3408` is scoped to the tail it introduces.** "Exactly one truthful run-level
   outcome, always, before the exit" is a statement about the four mutually exclusive branches below
   it and the single exit site at `:3424-3425`; it is not, and at HEAD has never been, a statement
   about a run that aborts through the envelope. `save_nodes()`'s `sys.exit` inside
   `generate_config()` (`:594`) ends the same way today.
3. **Demanding it would have failed the smallest correct C-1 arm**, and would have required E-10 to
   render the outcome block and then re-raise — new output over the user's override, the node store
   and the composition fault, i.e. precisely the exclusion this gate enforced in round 1.

The residual is genuine and small: after this change, as before it, `sc update-rules` can end
non-zero without saying what it did to the service. That is a HEAD hole, it widens nothing, and the
right instrument is a filed row (G-10 / C-12), not four lines in this task. Recording it costs one
line; discovering it again in a year costs a re-derivation.

## G-9 — how the K-4 error was found, and why it is a condition rather than a rollback

Reading `main()` to confirm the announcement's guarantee for `sc update-rules` showed that `:3754`'s
enumeration gates only `_init_files()` and `_resolve_clash_port()`: `LANG = _load_lang()` appears on
**both** arms (`:3755` and `:3758`). `_load_lang()` is `_settings_or_empty(warn=True)`, so the
`⚠️  Cannot use …` line is written for `sc doctor` and `sc config` too. `docs/dev-map.md`'s state
document row says the same thing correctly ("`warn=True` writes the run's single stderr line and only
`_load_lang()` passes it"), and AC-4 requires exactly that line for `sc doctor`. So stage 1 and the
project's own navigation are right, and the false clause is confined to K-4's justification and one
citation gloss in `02_RATIONALE.md`. My own round-1 P-1 repeated the error and is corrected in this
round's document.

It changes no code, no criterion and no line count, and the operative half of K-4 survives it intact
— which is why it is C-11 rather than a third rollback of stage 2. What it could have cost is real
though: a stage-6 reader holding K-4's model would expect zero warning lines from `sc doctor` and
would have reported AC-4 failing or NOT-DISCRIMINATING against correct code.

## Verified good, and what was read to say so

- **No fourth seam crept in, and the design is not under-designed.** NFR-3's temptation — a
  serialization layer, a document registry, a per-document class — is absent from the rework; the
  only structure added is a two-line guard reading an attribute the raise sites already set. Equally
  the design does not scatter a judgement: FR-6 remains one statement reusing `_read_state()`'s
  *unusable* outcome, and K-1 / K-13 together forbid any second opinion about usability.
- **T-13 / T-14 / T-06.** `_write_private()` (`:487-537`, `def` at `:487`, `_init_files` at `:540`)
  is unchanged and still the only writer of `config.json`, with `os.fchmod` on the empty descriptor
  before the first byte (`:514-528`). `_config_digest()` (`:1952-1974`) still hashes the file's bytes
  through a binary `Path.open` and is untouched by every codec edit; the frozen span `:1952-1994`
  now starts at the `def` and ends before `_drift_state()` at `:1997`, so G-8 is closed. `cmd_config()`'s
  single `sys.stdout.write` and `_redact()` are untouched; `:2705` and `:3121` are read-codec edits on
  that path and create no opt-out.
- **`settings.json` is not a credential document, and a failure is what this task renders.** K-3
  freezes the `0644` mode and the non-atomic `write_text`; I-1 adds a handler and nothing else. E-8
  is the guard against turning FR-4 into a new failure mode for read-only hosts, and its `try` holds
  exactly one statement (`:449-452`), which is the whole of the argument.
- **The assertion floor.** `TESTS` holds 14 (`check-sc-contracts.py:366-374`) and `baseline.json`
  carries `test_count`/`passing_count` 14; E-12 / I-8 move both to 17 and K-7 forbids lowering.
  Each new assertion pins a property nothing existing covers: no assertion scans the source, none
  drives `generate_config()` with an unusable **settings** document (`unusable_fault_clause_is_a_class_name`
  drives it with a bad override), and none touches `save_settings()`. `_refused()`'s signature
  (`sc, call, path, sentence, what`, `:87-96`) matches I-6's use, and `[]` yields the fixed key
  `the top level must be a JSON object` at `:579` with no interpolated parser text.
- **Locale criteria.** AC-9 / AC-10 / K-9 / V-9 / V-10 all carry `PYTHONUTF8=0` beside `LC_ALL=C`
  plus the in-process `sys.stdout.encoding` / `locale.getpreferredencoding(False)` proof, credited
  before any other clause. The 2026-08-15 insight is explicit that `LC_ALL=C` alone certifies nothing.
- **R-22 defence.** No criterion is dischargeable by the absence of a traceback — AC-19 says so in
  its own text — and AC-3 still observes a *valid* settings document taking effect unchanged, with
  four settings, the drift record and Chinese output.
- **Insight index sweep.** All 22 entries were read against this design's load-bearing terms. None
  contradicts an assumption; four support it (locale vacuity, `json.loads` over `bytes`, `main()`
  once per process, the codec-deletion false kill) and one — A.1's blindness to `.harness/*` — is
  answered by P-7 rather than by a new criterion, because none of the three assertions needs a
  credential-shaped literal.
- **Safety.** K-8 restates the mandated loader recipe plus the exec-denial shim, forbids driving
  `_init_files()`, forbids writing `/etc/sing-box` and `/var/lib/sing-box`, and restricts service
  witnessing to `systemctl show`. `check-sc-contracts.py:99-143` is a working demonstration,
  including the by-name enumeration of process-start attributes R-78 taught this project to require.
  This review took no measurement of any kind: every claim above is a read.
- **Out of scope stayed out.** R-73 / R-81 (T-30), R-89 / R-90 / R-92, R-86 appear nowhere in either
  document except in the exclusion list. No stage document of this task contains a credential byte;
  the only credential-shaped literals are `"\udXXX"` and the port `29500`.
- **Two harmless drifts, recorded and not filed.** `02_RATIONALE.md` cites `:1237-1250` for
  `OverrideError`'s `path` default, which is assigned at `:1256` (the docstring in that span does
  describe it), and calls `reload_or_restart()`'s six callers "five … plus `cmd_reload`". Neither
  misleads a developer to a wrong site.

## Insight candidate (for `07_DELIVERY.md` to consider, not harvested here)

`main()`'s read-only enumeration at `bin/sc:3754` gates `_init_files()` and `_resolve_clash_port()`
only — `_load_lang()` runs on **both** arms — so the once-per-run `⚠️  Cannot use settings.json …`
line is written by *every* command, `doctor` and `config` included. Three documents in a row
(`02_SOLUTION_DESIGN.md` K-4, its rationale, and this gate's own round-1 P-1) read that `if/else` as
gating the announcement, because the two facts sit on adjacent lines and only one of them is
enumerated.
