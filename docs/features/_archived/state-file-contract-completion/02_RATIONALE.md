# T-29 · state-file-contract-completion — Design Rationale

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| "Is this settings document usable?" | `_read_state()` + `_unusable()`, reached by `load_settings()` | `bin/sc:561-599` | Reuse as-is. It already answers *usable / absent / unusable*, already sets `.path`, and already raises the one failure family. FR-6 is one call to it |
| Rendering an unusable document's sentence + a non-zero exit | `main()`'s `except OverrideError` arm | `bin/sc:3773-3788` | Reuse as-is, unchanged, at zero cost: 16 call sites already inherit it |
| Rendering a failed write of an authored document | `save_nodes()`'s `(OSError, ValueError)` → `sys.exit(t("Could not write {path}: {err}", …))` | `bin/sc:589-595` | Mirror exactly into `save_settings()`. Same key, same catch family, same `getattr(e, "strerror", None) or str(e)` cause clause, same `_plain()` |
| Keeping the opportunistic port persist silent | the existing `try: save_settings(settings) / except …: pass` | `bin/sc:449-452` | Reuse the shape, widen the class by one word. `sys.exit(<str>)` only prints when the `SystemExit` reaches the interpreter, so catching it *is* the silent continue — no second mechanism, no flag argument on `save_settings()` |
| Making a run's failure honest for `sc update-rules` | `regen_ok` / `ok` — the run's one success record and one determination | `bin/sc:3385, 3407` | Reuse: the refusal becomes a fourth member of the existing "regeneration did not happen" family, beside a write failure and a failed `sing-box check` |
| Telling FR-6's refusal apart from the other three unusable-document failures of `generate_config()` | `OverrideError.path`, set by `_unusable()` at every raise site, defaulting to `None` on the class, and already the sole discriminator `main()`'s envelope renders by | `bin/sc:554-558`, `:1237-1250`, `:3781-3788` | Reuse as-is. The guard clause reads it; no new attribute, class, flag or predicate. This is the *only* discrimination in the change, and it is a read of provenance rather than a second judgement of usability |
| Explicit UTF-8 for a state document | `_read_state()`'s `read_bytes().decode("utf-8")`, `_write_private()`'s `fdopen(..., encoding="utf-8")`, `save_settings()`'s `write_text(..., encoding="utf-8")` | `bin/sc:569, 520, 617` | Reuse the pattern; six remaining sites get the same argument. No helper is introduced for it — a helper would be a fourth seam for a keyword argument |
| A committed test artifact and its floor | `check-sc-contracts.py` + `baseline.json` | `.harness/scripts/` | Extend with three assertions in the existing shape (`_eq`, `_refused`, `fixture`, `TESTS`) and raise the floor by three. No new harness, no new runner |
| Loading `bin/sc` safely in a fixture | the mandated recipe + the exec-denial shim | `docs/dev-map.md:139-177`, `check-sc-contracts.py:99-143` | Reuse verbatim (R-77 already discharged, R-78 is why) |
| Any new module for "documents" | (none found, and none justified) | — | Rejected. NFR-3 forbids a fourth seam, and the deletion test below shows a registry would delete no complexity |
| Telling the user what a non-UTF-8 stdout does to `sc config`'s output | the existing `sc config` stdout/stderr paragraph, one per language | `README.md:297`, `README.zh-CN.md:297` | Reuse the paragraph — correct it in place (E-18). It already sits in the right place, in both languages, and already holds three of the four facts; only its escape enumeration and its JSON-validity clause are wrong. No new section, no new heading, no second paragraph, and no doc-lint or prose-template mechanism (declined below) |

Nothing new is written that the repo does not already have: **zero new functions, zero new files in
the product, zero new dependencies.**

## The single insertion point — why one statement covers exactly the right commands

Call graph, from `bin/sc` (grep of `generate_config()` / `reload_or_restart()` / `load_settings()`):

- `generate_config()` has exactly two callers — `reload_or_restart()` (`:2170`) and
  `cmd_update_rules()` (`:3396`).
- `reload_or_restart()` has five callers: `cmd_use` (`:2361`), `cmd_add` (`:2383`), `cmd_rm`
  (`:2399`), `cmd_ipv6` (`:3221`), `cmd_telemetry` (`:3284`), plus `cmd_reload` (`:3530`).
- So the **regenerating** set is `reload / add / rm / use / update-rules` plus the two setting
  commands that regenerate after their own write.
- The **reporting** set — `doctor`, `config`, `ls`, `now`, `status`, `log` and the `show` arms of
  `ipv6` (`:3202-3207`), `telemetry` and `update-interval` (`:3432-3438`, `:3475-3486`) — reaches
  `generate_config()` from nowhere, and every settings value it needs comes through
  `_settings_or_empty()` (`_load_lang`, `_saved_clash_port`, `_ipv6_setting`, `_telemetry_setting`),
  which degrades and never raises. One insertion inside `generate_config()` is therefore sufficient
  **and** exact: FR-8 needs no work at all.
- `cmd_ipv6` / `cmd_telemetry` / `cmd_mode` / `cmd_lang` / `cmd_on` / `cmd_off` / `cmd_default_tun` /
  `cmd_update_interval` already call `load_settings()` for their read-modify-write (`:2409, 2421,
  3174, 3209, 3274, 3303, 3463, 3502, 3540`), so they already refuse today — the dev-map's
  "a read-modify-write calls `load_settings()` so it aborts instead of clobbering" rule. FR-6 is the
  same rule finally applied to the one read-modify-write nobody spelled: **regeneration reads the
  settings and writes `config.json`.** That framing is why the fix is one statement and not a feature.
- `cmd_use`'s Clash-API hot switch returns before `reload_or_restart()` (`:2356-2360`), which is
  BC-14 holding for free.

## The smaller alternative rejected, and what the extra code buys

Three sizing decisions were open. Two went to the smaller design. The third — FR-7's arm — is the
one place where the smaller design is *wrong* rather than merely lean, so it is priced in full: what
the extra lines buy, and every cheaper shape that was weighed and why it fails.

1. **FR-6 — a bare `load_settings()` (1 line) vs. a guard that catches, renders and returns `False`
   (6 lines).** Rejected the larger. The bare call reuses the raise → `main()` envelope path, which
   is the only path that yields a non-zero exit for `sc add` / `sc rm` / `sc use` — those three
   ignore or absorb a `False` return (`:2383-2388`, `:2399`, `:2361`) and would have exited **0**,
   failing FR-6 outright. The larger design would have had to edit three more commands. The smaller
   one is both smaller and the only correct one.
2. **FR-5 — one word (`except SystemExit:`) vs. a `quiet=` / `raise_on_error=` parameter on
   `save_settings()`.** Rejected the parameter. A flag argument makes every one of the eleven call
   sites answer a question only one of them has, and it puts a second policy inside the writer. The
   trap the analyst named is real and is closed by the one word: a renderer that calls `sys.exit`
   raises `SystemExit`, a `BaseException` that `except OSError` (and even `except Exception`) cannot
   catch, so E-7 without E-8 would make every command on a read-only host fail (AC-8). Catching it
   also keeps the run silent for free, because `sys.exit(<str>)` prints only when the exception
   reaches the interpreter.
3. **FR-7 — a bare `except OverrideError:` (4 added code lines) vs. the same arm opened by a
   `.path` guard clause (6).** Took the **larger**, and this is the one place in the design where a
   larger shape wins, so the price is stated line by line. `generate_config()` raises
   `OverrideError` from four sites, not one — the override wrapper (`bin/sc:2057-2064`), FR-6's new
   `load_settings()`, `load_nodes()` (`:2066`) and the composition fault clause (`:2131-2136`) — and
   every one of them reaches `main()`'s envelope at HEAD and names its document. A bare catch is
   four lines and catches all four: on an unusable `override.json` the run would end with only
   `Rule-sets updated: … — the sing-box service was not touched` and exit 1, the cause named
   nowhere. That is this task's own defect re-installed one document over, and it reaches into
   out-of-scope 7. **What the two extra lines buy is three documents keeping their sentence** —
   `override.json`, `nodes.json` and the composition fault — which is not a nicety but the
   provenance `OverrideError.path` exists to carry. Priced against everything else considered:
   * `except OverrideError as e:` + `if e.path != SETTINGS_PATH:` + bare `raise`, then fall through
     to `regen_ok = False` — **6 code lines, taken.** The guard clause reads the provenance the
     raise site attached; it forms no opinion about any document's usability, so Q-2 and K-1 hold,
     and FR-6's refusal still produces exactly one refusal sentence (`_load_lang()`'s) and exactly
     one run-level outcome line.
   * The `if / else` spelling of the same test (`if e.path == SETTINGS_PATH: regen_ok = False /
     else: raise`) — **7 lines**, one more for the `else`, identical behaviour. Rejected.
   * Dropping E-10 altogether — **0 lines**, and the smallest thing that could possibly work, but it
     is wrong: the `OverrideError` then leaves `cmd_update_rules()` before `:3410-3420`, so a run
     whose settings document is unusable prints **no** run-level outcome line at all, breaking the
     contract the comment at `:3408` pins ("exactly one truthful run-level outcome, always, before
     the exit"). Rejected.
   * A `SettingsError(OverrideError)` subclass caught by name — **2 lines at the call site but a new
     class plus a re-raise site at `generate_config()`**, i.e. more code and a new concept to carry,
     for a discrimination `.path` already makes. It is also the exception taxonomy the comment at
     `:3781-3785` explicitly says is not needed. Rejected under NFR-3 and 「少就是多」.
   * The escalation this design pre-specified for *sentence position* — store `e`, re-raise after
     the outcome line — stays **unspent**. `_load_lang()` already put the identical rendered
     sentence on stderr before the download loop (`:398-401` → `:610-611`), so the four extra lines
     would buy a duplicate at the bottom of the run, not information.

**The temptation named in the brief — a serialization layer or document registry — fails the
deletion test.** Delete it and no complexity reappears: every document already has exactly one
reader (`_read_state`) or one writer (`_write_private` / `save_settings`), and the only thing a
registry would centralise is a keyword argument that is already spelled identically at every site.
Two adapters would be needed for a real seam; here there is one shape and six literal call sites, so
the seam would be hypothetical. It would also cost every future reader a lookup for a fact the call
site currently states inline.

## Where the 19 added code lines come from, and why none of them comes out

NFR-1's provenance budgets 14: six codec arguments, +4 for the write-failure renderer, +2 for FR-6,
+2 for FR-7. The shipped count is **19 code + 5 comment inside +24/−9**, and the five over the 14
split into three kinds, none of which is new machinery:

- **Three are `try:`-wrapping artefact** — a statement that moves inside a `try` counts as one added
  line and one removed line under the same diff accounting NFR-1 used for its six modified codec
  lines. One at E-7 (the existing `write_text`), one at E-10 (the existing `regen_ok =
  generate_config()`), and E-10's `try:` itself, which the provenance's "+2 for FR-7" did not model.
- **One is E-8**, which the provenance does not carry at all: FR-5 is one word on an existing line,
  and a modified line is an added line under the same accounting.
- **Two are I-3's guard clause** (`if e.path != SETTINGS_PATH:` and `raise`) — the price of keeping
  `override.json`, `nodes.json` and the composition fault reaching `main()`'s envelope. Priced
  against its alternatives in the section above.
- **−1 at E-9**, a real saving: FR-6 is one statement, not the two the provenance assumed.

Nothing is trimmed elsewhere to make the total look smaller. The comment lines stay (five, against
NFR-1's ≤6 documentation lines) because each states a *why* the code cannot: FR-5's reason for
catching a `BaseException`, FR-6's reason for reading a document it discards, and FR-7's scope.
Deleting a comment to buy a code line would be paying for a number with the thing that makes the
next edit safe. The measured total, +24 of a permitted +25, leaves one line of slack, and K-11 binds
the implementer to report a deviation rather than absorb it.

## Risk analysis

| # | Risk | Mitigation |
|---|---|---|
| R-1 | **E-7 without E-8 turns a read-only host into a failing host.** `_resolve_clash_port()`'s persist runs on *every* non-`doctor`/`config` command that has no recorded port; once `save_settings()` exits, `except OSError` cannot catch it and `sc ls` on a 0444 settings file dies | The two edits are one step in `## Migration & edit sequence` (order 2), AC-8 covers it, and V-8 names the discriminating control as a mutant of the candidate rather than HEAD (HEAD passes that row) |
| R-2 | **FR-6 breaks a fresh install.** `install.sh` runs `/usr/local/bin/sc update-rules` and `sc reload` at steps 6-7 | `install.sh:492-506` rewrites `settings.json` with defaults + the chosen language before either call, and `_init_files()` seeds it when absent, so a fresh install never reaches `sc reload` with an unusable document. An *upgrade* over a hand-broken settings file now fails loudly at step 7 with the file named — which is the intended outcome of Q-1, and PHASE_CONFIG already renders it (`install.sh:28`, `fail_reload`) |
| R-3 | **The codec assertion certifies nothing** because it is killed by a deletion that is invisible on this host | I-5 is killed by a **substitution** (`latin-1`), stated in K-6/V-13 and drawn from the 2026-08-16 insight; a deletion sweep is explicitly excluded from the mutation set |
| R-4 | **A locale criterion passes vacuously.** `LC_ALL=C` alone leaves PEP 540 UTF-8 mode on, so AC-9/AC-10 would pass on broken and fixed code alike | K-9 requires `PYTHONUTF8=0` and an in-process proof of `sys.stdout.encoding` / `getpreferredencoding(False)` before any other clause is credited (NFR-6) |
| R-5 | **A fixture re-execs the installed `sc` under sudo** (R-78's live near-miss) | K-8: the mandated recipe *plus* the exec-denial shim, nine path constants repointed and asserted, `_init_files` replaced, `/var/lib/sing-box` never driven, a clone (never a worktree) for the HEAD control |
| R-6 | **AC-1's "exactly one sentence" is counted as "one stderr line"** and the build is failed for a pre-existing announcement | Settled: AC-1 counts refusal sentences, and stage 6 reports both stderr lines while counting only the envelope's (C-8). RES-3 carries the ruling to the test report so nobody re-derives it |
| R-7 | **The refusal fires on a document that is merely unrecognised**, breaking BC-4 | The refusal is `_read_state()`'s outcome, which is about the document's *encoding, syntax and top-level shape* only; an unrecognised value for a key is handled by the accessors' existing notice + default and never reaches it. V-3 (a usable document with four settings) is the control that fails any build which over-refuses |
| R-8 | **E-3/E-4 change `sc config` / `sc doctor` behaviour on a host whose `config.json` is genuinely not UTF-8** — it now fails at the same place for a different reason | The sentence is unchanged (`cannot read {path}: {e}` / the UNKNOWN row): `UnicodeDecodeError` is a `ValueError`, both sites already catch `(OSError, ValueError)`, and clause order is unchanged (K-5). Only the *decision of which bytes are text* moves from the locale to UTF-8 |
| R-9 | **The implementer simplifies E-10's arm back to one undifferentiated clause** — the shape that looks like it handles only the case just added while catching all four documents `generate_config()` can fail on. It ships green against every other criterion in this document | K-13 makes the scoping binding; AC-19 / V-19 measure it in both directions, with the undifferentiated arm as the **mutation control that must fail**; E-10's one comment line states the scope at the site, so the next reader does not have to re-derive it |
| R-10 | **The guard turns into a second opinion about a document.** A later edit "improves" `if e.path != SETTINGS_PATH` into a re-read, an `exists()` test or a usability predicate — the fourth seam NFR-3 forbids | K-13 permits testing only the `.path` the raise site attached; I-3 records that both sides of the comparison read the same module global, which is also what keeps a repointing fixture honest; K-1 already forbids any new usability predicate |
| R-11 | **The paragraph repair grows into a README pass.** Once either file is open, a nearby sentence looks stale and a heading looks improvable, and the diff stops being reviewable against a measurement — or the mirror failure: only the English file is corrected, leaving the project's Chinese human-facing doc carrying the falsified claim | E-18 binds one hunk per file **and** both languages; K-12 lifts the freeze for exactly that paragraph and re-states the freeze over everything else in the same breath; V-11 asserts `git diff` shows exactly one hunk in each file and FAILS a build that corrects only English. Its control is HEAD's own text failing clause (c) on the CJK row, so the row measures the repair rather than the diff's size alone. The remaining prose stays T-32's |

## Evidence and citations

- `bin/sc:589-595` — the renderer being mirrored, including the `getattr(e, "strerror", None) or
  str(e)` cause clause and the `# ValueError = the UnicodeEncodeError a lone surrogate raises` note.
- `bin/sc:449-452` — the swallow that must name `SystemExit`; `:443-447` already shows the same
  function absorbing `OverrideError` from `load_settings()`, which is why FR-8 survives FR-6 for
  every reporting command on the `else` arm.
- `bin/sc:2049-2066` — the region E-9 is inserted into, and the comment K-2 keeps true.
- `bin/sc:3385-3426` — `regen_ok` / `ok` / the four outcome lines / the one exit site, i.e. the
  contract FR-7 preserves.
- `bin/sc:1237-1250` — `OverrideError`'s docstring and its `path` class default of `None`, which is
  why I-3's guard needs no `getattr` and why a composition fault (`.path is None`) sorts to the
  re-raise rather than to FR-6's arm.
- `bin/sc:404-413`, `:70-71`, `:436-438` — `_free_port()`'s window `[29090, 29190)` and its `29090`
  fallback, and the early return that skips the opportunistic persist when a port is recorded: the
  two facts V-2, V-6 and V-7 pin their fixtures to.
- `bin/sc:932`, `:1196`, `:1966`, `:2640` — every `Path.open()` call site, all four binary today;
  they are inside I-4's population and admitted by their mode literal, not excluded by their callee.
- `bin/sc:3754-3759` — `main()`'s positive two-command read-only enumeration, which is what makes
  K-4's announcement guaranteed for `sc update-rules` and absent for `sc config` / `sc doctor`.
- `docs/dev-map.md` "Is this state document usable?" — the pre-existing rule this task completes:
  *a read-only accessor calls `_settings_or_empty()`; a read-modify-write calls `load_settings()`.*
- Insight index 2026-08-15 (×4) and 2026-08-16 (×2) — locale proof, stderr vs stdout error handlers,
  `json.loads` over `bytes`, `main()` once per process, and the false-kill of a codec deletion.

## Decisions declined (for `.harness/rejected-decisions.md`, at delivery)

- A per-document serialization layer / document registry / state-document class — declined: fails the
  deletion test, forbidden by NFR-3, and would centralise one keyword argument.
- A `quiet=` / `raise_on_error=` parameter on `save_settings()` — declined in favour of one word at
  the one call site that wants silence.
- A `SettingsError` subclass of `OverrideError` so `cmd_update_rules()` could catch FR-6's refusal by
  class — declined: `.path` already discriminates, the class would add a raise-site wrapper as well
  as the class itself, and `bin/sc:3781-3785` states that this project deliberately answers "whose
  document" with an attribute rather than an exception taxonomy.
- A doc-lint step, a prose template, or any general "documentation accuracy" mechanism attached to
  E-18 — declined. The defect is two sentences made false by this change, and the counter-rule in
  `.harness/rules/85-design-discipline.md` declines meta-tooling built from a single instance; T-32
  already owns the remaining sweep at its own "correct the sentences and add nothing" limit. The
  repair is the sentences.
- Deferring the paragraph correction to T-32 — declined by Q-14, and the design agrees: the claim is
  vacuous at HEAD and goes live the moment `sc config` starts reaching stdout, so deferring publishes
  a measured-false claim about the behaviour this very change introduces.
- Widening the codec sweep to `subprocess.run(..., text=True)` — declined **for this task** (R-76
  enumerates six sites and NFR-1 budgets them); recorded as RES-1 rather than dropped.
