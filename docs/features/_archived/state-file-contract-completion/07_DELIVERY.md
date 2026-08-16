# Delivery Summary

## Summary

- Task: T-29 / `state-file-contract-completion` — finish the contract T-23 started: four bare
  `read_text()` calls, one unrendered write failure, and a regenerating run that silently discarded
  the user's stored choices.
- Mode: full (7 stages), pool `closeout`, dispatched by `/harness-batch`.
- Stages traversed (all 2026-08-16): 1 req ×4 · 2 design ×3 · 3 gate ×2 · 4 dev ×3 · 5 review ×2 ·
  6 QA ×3 · 7 delivery. Eight intervention checks, none pending.
- Rollbacks: **6**. Stage 1 ×3 (AC-1 uncountable, found by the architect; C-2's missing criterion,
  found by the gate; AC-11 unsatisfiable, found by QA). Stage 2 ×2 (G-1 MAJOR, the four-document
  catch; E-18, the README unfreeze). Stage 4 ×2 (CR-1's boundary clause; the two prose hunks). Plus
  one **rollback to the PM**: QA's D-2 CRITICAL, an F.6 WARN caused by this task's own `PM_LOG.md` at
  550 lines — compacted by the PM under rule 70 Rule 2, never delegated.
- Final `verify_all` result: **PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0** — measured five
  consecutive times by QA over the delivered tree, `[B.4] bin/sc contract assertions ... PASS`, and
  the SKIP still `[B.3] Lint`, so the WARN→PASS flip was F.6 clearing and not a check degrading.
- Baseline changes: `.harness/scripts/baseline.json` `test_count` / `passing_count` **14 → 17**, a
  floor B.4 enforces, raised in the same change as the three assertions. **No assertion removed or
  weakened; the floor was never lowered.** Suite: `17 defined, 17 run, 17 passed`.
- Outstanding risks: E-10's `.path` guard is pinned by **no committed assertion** — the collapse
  mutant leaves B.4 green at 17/17/17 while FAILing AC-19. Ruled a **written boundary, not a fourth
  assertion**, and the boundary is written at `docs/dev-map.md:76`; the committed pin is filed as a
  pool row (R-97) because it needs the suite's first command-level fixture. `settings.json`'s write is
  still non-atomic, so a part-way failure leaves a truncated document — stated as BC-5, reported by
  name on the next run, deliberately not repaired.
- Files changed: 7 files, **+206 / −17**. `bin/sc` **+24 / −9** (19 code, 5 comment);
  `check-sc-contracts.py` +173; `baseline.json` 2/2; `docs/dev-map.md` 4/4; `CHANGELOG.md` +1;
  `README.md` 1/1; `README.zh-CN.md` 1/1.
- Rows closed: **R-65** (by code — the refusal), **R-66** (by code — the renderer), **R-76** (by code,
  the six-site sweep, **plus a ruling**: `bin/sc:567`'s docstring never contradicted the code, so the
  prose duty it named was the READMEs' and it was discharged here, not deferred). **R-77 confirmed
  already discharged in fact** by T-28. Rows filed: **R-97 … R-102**.
- Next steps for user: none required. T-30 is unblocked and untouched — R-73's ordering defect and
  R-81 were held out of this task by name.

## What shipped, and the three rulings behind it

**R-65 → REFUSE.** An unusable `settings.json` now blocks every run that **writes** and blocks no run
that only **reports** — one `load_settings()` statement inside `generate_config()`, whose two callers
cover all five regenerating commands while no reporting command reaches it, so FR-8 cost **zero code**.
The framing that kept it one line: the eight read-modify-write commands already refused; regeneration
was simply the read-modify-write nobody had spelled. It forms no second opinion about usability
(T-16's AC-6 intact) and bounds rather than overturns R-27 — that ground held while a discarded value
was only *read*, and stops holding when the run *installs* defaults over it.

**R-76 → blanket sweep, six sites** (`:1667`, `:2015`, `:2705`, `:3121` plus two locale-encoded
*writes* the row never counted), on the ground that a rule with **zero exceptions is pinnable by a
source scan** and one with an exception is not. The shipped scan reads 8 text sites naming `utf-8` and
5 binary sites admitted only by a **literal** mode.

**R-66 → render the failure, keep the swallow.** The renderer mirrors `save_nodes()` exactly, cause
clause `getattr(e, "strerror", None) or str(e)` — and T-23's finding was reproduced first-hand rather
than inherited: a bare `e.strerror` raises `AttributeError` **inside the handler**. FR-5's silent
persist survives because `_resolve_clash_port()`'s catch became `except SystemExit:` in the same
change, over a `try` holding exactly one statement.

**Size.** `bin/sc` +24/−9 against a budget of ≤14 added code lines. The gate checked every line and
ruled the overage justified in full **and named the budget as the defect**: NFR-1's provenance priced
a modified line as an added line, priced a five-line renderer at four, and omitted FR-5 entirely —
under its own accounting the design it described cost 19. No serialization layer, document registry,
per-document class, new module, new file, new translation key, flag or format. The pool's named
temptation was declined.

## Insight

- 2026-08-16 · CPython's `backslashreplace` has **three** spellings and only one of them is legal JSON — `\xNN` (Latin-1 range) and `\UNNNNNNNN` (above the BMP) are not JSON escapes but `\uNNNN` (the rest of the BMP, i.e. **every CJK character**) is, so `sc config > file` under a non-UTF-8 stdout yields a file that **still parses** for a Chinese-tagged document and fails to parse for a `café` or emoji one; a two-spelling enumeration reads as complete and is wrong for the most common tag this project sees · evidence: state-file-contract-completion
- 2026-08-16 · `json.dumps()`'s `ensure_ascii=True` **default** puts pure ASCII on disk, so a locale fixture written as `json.dumps(doc).encode("utf-8")` contains no byte the codec under test can fail on and **passes identically on broken and fixed code** — `ensure_ascii=False` is what makes the control fail with `'ascii' codec can't decode byte 0xe8`, and this is a second, independent way for a locale criterion to certify nothing even after `PYTHONUTF8=0` is set correctly · evidence: state-file-contract-completion
- 2026-08-16 · A non-ASCII tag passed to a `bin/sc` fixture through `argv` under `LC_ALL=C` is decoded with `surrogateescape`, so the run dies inside the **fixture's own writer** (`UnicodeEncodeError: … surrogates not allowed`) before `sc` is reached — the failure looks like a product defect but is the harness's, and the only reliable transport is building the tag from source escapes and asserting it surrogate-free · evidence: state-file-contract-completion
- 2026-08-16 · `main()`'s read-only enumeration at `bin/sc:3769` gates `_init_files()` and `_resolve_clash_port()` **only** — `_load_lang()` runs on *both* arms — so the once-per-run `⚠️ Cannot use settings.json …` line is written by every command, `doctor` and `config` included; three documents in a row read that `if/else` as gating the announcement, because the two facts sit on adjacent lines and only one of them is enumerated · evidence: state-file-contract-completion
- 2026-08-16 · `generate_config()` raises `OverrideError` from **four** sites carrying four different `.path` values (override, settings, node store, and a composition fault carrying `None`), so a bare `except OverrideError:` at either call site is a **four-document catch** wearing the shape of a one-document one — it silently destroys the provenance the envelope exists to preserve, and the resulting build ships green because no criterion written for the document you just added measures the other three · evidence: state-file-contract-completion

## Verdict

DELIVERED
