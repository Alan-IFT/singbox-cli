# 04 — Development · T-23 `state-file-io-contract`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

## Summary

1. `bin/sc` gained one state-document reader — `_read_state(path, default=None, member=None)` with its
   `_unusable()` factory — so `settings.json` and `nodes.json` decode as UTF-8 independently of the
   process locale, get one top-level shape check each, and fail as one `OverrideError` that `main()`'s
   **untouched** arm renders; the 16 unguarded call sites inherit a sentence and a non-zero exit with no
   edit of their own.
2. `_settings_or_empty(warn=False)` is the single degrade — an unusable `settings.json` means an empty
   settings document — from which the four accessors' documented defaults (`en` / `None` / `auto` /
   `block`) fall out, with the run's one warning line written by `_load_lang()` before `LANG` exists.
3. Every document `sc` authors is now written as UTF-8 with non-ASCII literal, both write-failure
   renderers survive a non-encodable argument, and `settings.json` has exactly one writer.

## Files changed

One row per ledger edit id. `+n/−n` are **physical diff lines**; the parenthesis splits added lines into
code and comment/docstring. Blank lines separating the three new functions are counted once, at the end.

| path | what changed | ledger id |
|---|---|---|
| `bin/sc` | **New** `_unusable(path, problem)` in `# State files` above `load_nodes`: builds the `OverrideError` and sets `.path`; returns it so callers `raise` it. `+5 (4 code, 1 doc) / −0`. | E-1 |
| `bin/sc` | **New** `_read_state(path, default=None, member=None)` below it — THE reader (I-1): one `read_bytes().decode("utf-8")`, four causes, the `member` array check. `+22 (16 code, 6 doc) / −0`. | E-2 |
| `bin/sc` | `load_nodes()` body → `_read_state(NODES_PATH, member="nodes")`; no `default`, so an absent node store is a failure. `+1 code / −1`. | E-3 |
| `bin/sc` | `load_settings()` body → `_read_state(SETTINGS_PATH, default={})`; absent and empty are one state. `+1 code / −1`. | E-4 |
| `bin/sc` | **New** `_settings_or_empty(warn=False)` below `load_settings()` — THE degrade and the only writer of FR-5's line. `+11 (8 code, 3 doc) / −0`. | E-5 |
| `bin/sc` | `_load_lang()`: inline `json.loads(read_text())` and its three-name tuple deleted; body is `_settings_or_empty(warn=True).get("lang", "en")`. `+3 (1 code, 2 doc) / −4`. | E-6 |
| `bin/sc` | `_saved_clash_port()`: try/except deleted; `port = _settings_or_empty().get("clash_api_port")`. Range check unchanged. `+1 code / −5`. | E-7 |
| `bin/sc` | `_resolve_clash_port()`: tuple → `except OverrideError`, body → `return port` **without** `save_settings()` (K-6). `+3 (2 code, 1 comment) / −2`. | E-8 |
| `bin/sc` | `_ipv6_setting()`: try/except → `settings = _settings_or_empty()`; the docstring's "silently" clause corrected to name `_load_lang()` as the warning's home. `+2 (1 code, 1 doc) / −5`. | E-9 |
| `bin/sc` | `_telemetry_setting()`: same body change; the now-false **"THE SILENCE HAS TWO HOLES"** paragraph deleted and the first paragraph restated in three lines. `+4 (1 code, 3 doc) / −20`. | E-10 |
| `bin/sc` | `_write_private()`: `os.fdopen(fd, "w")` → `os.fdopen(fd, "w", encoding="utf-8")` and nothing else; `mkstemp → fchmod → write/flush/fsync → replace` and the `finally` are byte-for-byte intact (K-4). `+2 (1 code, 1 comment) / −1`. | E-11 |
| `bin/sc` | `save_nodes()`: `except OSError` → `except (OSError, ValueError)`; cause clause → `getattr(e, "strerror", None) or str(e)` (K-5). `+3 (2 code, 1 comment) / −2`. | E-12 |
| `bin/sc` | `save_settings()`: `ensure_ascii=False` + `encoding="utf-8"`. Mode, atomicity and mechanism unchanged (Q-10). `+2 (1 code, 1 comment) / −1`. | E-13 |
| `bin/sc` | `_init_files()`: the direct `SETTINGS_PATH.write_text(...)` seed → `save_settings({...})` with the identical dict; the `/var/lib/sing-box` literal untouched. `+2 (1 code, 1 comment) / −2`. | E-14 |
| `bin/sc` | `generate_config()`'s write renderer: same catch widening and cause clause as E-12. `+3 code / −3`. | E-15 |
| `bin/sc` | `_doctor_clash()`'s node-delay guard: `(OSError, ValueError, TypeError, KeyError)` → `(OverrideError, TypeError, KeyError)`. Row text unchanged. `+1 code / −1`. | E-16 |
| `bin/sc` | `TRANSLATIONS`: one new key, `the "{member}" member must be a JSON array` → `"{member}" 成员必须是 JSON 数组`, beside `the top level must be a JSON object`. `+1 code / −0`. | E-17 |
| `bin/sc` | **C-4 (gate-added, not in the ledger):** `OverrideError`'s docstring opener and `main()`'s handler comment opener no longer claim the class or the arm is only about the user's override. Comment/docstring only; no executable line inside either region moved. `+3 doc / −3`. | C-4 |
| `bin/sc` | Blank lines separating the three new module-level functions. `+6 / −0`. | E-1, E-2, E-5 |
| `CHANGELOG.md` | One Chinese bullet under `## [Unreleased]` → `### 修复`, stating the read contract, the UTF-8 write and the single `settings.json` writer. The read-site count is **三处** (`load_nodes()`, `load_settings()`, `_load_lang()`'s inline read). The write half's claim is **write-scoped** — 「写入不再失败、凭据按 UTF-8 原样落盘」 — and the closing 注意 states K-15's limit in full: this closes the **disk** layer only, and under a non-UTF-8 locale `sc add` still fails printing its own success line (its `→` is sc-authored, so an all-ASCII share URL fails too) and exits non-zero **with the node already correctly in `nodes.json`**, so the user must not re-add it. `+2 / −0`. | E-18 |
| `docs/dev-map.md` | Four rows amended plus one new row. `# State files` cell (the three new symbols, and that both `_init_files()` branches are now a single `save_*()` call); `# Config generation` cell (the write renderer's catch is now `(OSError, ValueError)`); the `_telemetry_setting()` row (the stale "inherits the same hole … `UnicodeDecodeError`" sentence **deleted** — this diff closed that hole); the `_write_private()` row (records the explicit `encoding="utf-8"` in the `fdopen`). New `## Reusable utilities` row, "Is this state document usable?", carrying RT-6's one-word rule for a future call site. `+5 / −4`. | E-19 |
| `CONTEXT.md` | One glossary term, **state document**, appended to `## Language` before `## Project intent`, naming the two documents in the category and excluding `override.json` and `config.json` by name. `+9 / −0`. | E-20 |
| `docs/features/state-file-io-contract/04_DEVELOPMENT.md` | This document; `04_RATIONALE.md` beside it. | E-21 |
| *(no path)* | E-22 is the schema-gap row: no test artifact is committed. The fixtures below live under the session scratchpad and are not in the worktree (RT-7, T-28). | E-22 |

**Measured product diff — `git diff --stat bin/sc`: `127 ++++----`, i.e. `+76 / −51`.** Of the 76 added
lines, **46 are code**, 24 are comment or docstring, and 6 are blank separators. Against C-8's amended
cap (`≤ +76 added, of which ≤ 48 code`) both figures are inside, the added-line figure exactly at it.
Whole-worktree `git diff --stat`: `bin/sc +76/−51`, `CHANGELOG.md +2/−0`, `CONTEXT.md +9/−0`,
`docs/dev-map.md +5/−4`.

**`bin/sc` is byte-unchanged since the reviewed state** — the only edits after review are in
`CHANGELOG.md` and `docs/dev-map.md`, both prose. `git diff --numstat bin/sc` still reads `76 51`, so
C-8's independently reconstructed measurement (76 added / 51 deleted / 46 code, exactly at the amended
added-line cap) stands unchanged and needs no re-count.

## verify_all result

```
invocation: bash .harness/scripts/verify_all.sh   (from the repository root — never a subdirectory)
baseline (before any edit): PASS 17 / WARN 0 / FAIL 0 / SKIP 1
after (all edits, all four files): PASS 17 / WARN 0 / FAIL 0 / SKIP 1
delta: 0 new failures, 0 new warnings, baseline preserved
A.1 no hardcoded secrets: PASS (with this task's documents and the CHANGELOG bullet in place)
B.1 syntax (bin/sc, install.sh, uninstall.sh): PASS
B.2 install.sh bilingual key parity: PASS (it parses install.sh only — I-9's zh entry is checked by hand, C-9)
E.6 adversarial-tests heading: PASS (untouched; no numbered variant introduced anywhere)
F.6 active task docs <=500 lines each: PASS
python3 -m py_compile bin/sc: OK
```

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| D-1 | `02` §I-1 and K-2 describe `_read_state` decoding and parsing as separate steps with the `UnicodeDecodeError` arm placed before the `ValueError` arm. | One `try` block wrapping `json.loads(path.read_bytes().decode("utf-8"))` with three arms in the order `OSError` → `UnicodeDecodeError` → `ValueError`. | Q-D rules both shapes acceptable and forbids only `ValueError` before `UnicodeDecodeError` in one block, which this is not. The single block is 2 lines shorter, which the C-8 cap needed. Behaviour is identical and is measured per cause in `06`'s inputs (V-1, V-8). |
| D-2 | I-1's *absent* outcome reads as a dedicated `FileNotFoundError` path. | The absent case is decided inside the single `except OSError` arm by `if default is not None and isinstance(e, FileNotFoundError)`. | Same 2-line saving; `FileNotFoundError` is an `OSError` subclass so the ordering question does not arise. **Named here because C-10 forbids a fifth `isinstance` guard** — this one is inside the reader, deciding which *cause* applies, not a guard around a state read. The two other `isinstance` calls in the reader are FR-3's shape checks, likewise inside it. |
| D-3 | The ledger's per-edit doc counts (e.g. E-2 `+7 doc`, E-5 `+4 doc`) assume the file's usual expansive docstring style. | Every new docstring is 1–6 lines and closes on its last text line; the rationale that would normally sit in them (why `_unusable()` is a factory, why the reader copies none of `_load_override()`'s policies) is in `02` §I-1/I-2 and is not repeated in the file. | C-8's 76-line cap is binding and the design's own `+70` budgeted neither the 6 blank separators a new module-level function costs nor C-4's 3 prose lines, which the gate added after the budget was set. Terse prose was the only line item left to spend. |

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| C-1 | Applied | The twelve runs are `sc ls` / `sc now` / **`sc use 1`** × the four `nodes.json` fixtures (non-UTF-8, non-JSON, non-object, `{}`). Candidate: 12/12 exit 1, one `Cannot use …nodes.json: <cause>` line, no `Traceback`, file byte-identical. `sc status` was run alongside and **not counted** — under `SYSTEMD = OPENRC = False` it never reaches its `load_nodes()`. |
| C-2 | Applied, confirmed by measurement | For `null` / `42` / `"telemetry"` / `[]` the discriminator used is FR-5's single warning line plus the absence of a traceback, never the value `auto`. The through-`main()` HEAD control is exactly what C-2 predicted: one `AttributeError` from `_load_lang()` at `bin/sc:390` for all four (`'NoneType'` / `'int'` / `'str'` / `'list'` object has no attribute `get`), raised outside `main()`'s try. Candidate: exit 0, one warning line, `IPv6 name resolution → auto` on all four. The per-accessor controls were not reproduced through `main()` and are not claimed. |
| C-3 | Satisfied | E-3, E-4, E-5, E-6, E-7, E-9, E-10 **and E-8** are all present in the working tree as one uncommitted change set; nothing is staged separately, so the PM's single delivery commit carries all eight edit ids. No intermediate state exists in which `_resolve_clash_port()` still holds the old tuple. |
| C-4 | Done | `OverrideError`'s docstring opener now reads "A JSON document that cannot be used — the user's override, or a state document sc authors itself"; `main()`'s comment opener now reads "THE one rendering site for any unusable document, not just the user's". 3 changed lines total (2 + 1), comment/docstring only. `path`, the class body, `_load_override()` and the arm's three executable lines are untouched. |
| C-5 | Applied | The AC-13 differential fixture holds only sc-authored validated values: `settings.json` = `{"lang": "en", "mode": "rule", "default_tun": true}` plus the probed `clash_api_port`, `nodes.json` from one ASCII `trojan://` share URL. No `update_interval`, no hand-edited value, no non-ASCII. `settings.json`, `nodes.json` and `config.json` are byte-identical between builds. |
| C-6 | Applied at stage 4; stage 6 owns the re-run | `sc.clash_api` was stubbed to return a `dict` and the fixture's `settings.json` records `clash_api_port: 29099`, so `_doctor_clash()` reaches E-16's guard. **Against HEAD the observable is identical** (HEAD's wider tuple also catches the four causes), so AC-9 is reported as **not discriminating vs HEAD**. E-16 is instead verified by a within-candidate negative control: with E-16 reverted, doctor's Clash section collapses from four rows to one `[UNKNOWN] Clash API: this check could not run: not valid UTF-8 text` and the table loses 3 rows. |
| C-7 | Applied | The R-27 clobber control ran on the **valid-UTF-8-but-not-JSON** `settings.json` (`this is not json but it is utf-8`). HEAD replaced it with `{ "clash_api_port": 29091 }`; the candidate left it byte-identical. The non-UTF-8 and non-object fixtures were not used as R-27 controls. |
| C-8 | Satisfied and quoted | `git diff --stat bin/sc` = `+76 / −51`; code/doc split = **46 code**, 24 comment/docstring, 6 blank. Cap: ≤76 added, ≤48 code. |
| C-9 | Satisfied | Exactly one key added, I-9's, with its `zh` entry and the same single placeholder `{member}` in both languages; the literal contains no `失败`. B.2 parses `install.sh` only, so the Chinese entry was checked by hand (both halves quoted in the E-17 row above) and rendered live — the `{}` fixture prints `Cannot use …nodes.json: the "nodes" member must be a JSON array`. |
| C-10 | Satisfied | Enumeration of every `except OverrideError` in the shipped file: `:436` `_resolve_clash_port` (the permitted write-refusal), `:595` `_settings_or_empty` (degrade), `:2038` and `:2072` `generate_config`'s two **pre-existing** override-provenance wrappers (unchanged by this diff — they set `.path = OVERRIDE_PATH` and re-raise), `:2791` `_doctor_clash` (doctor's row), `:3700` `main()` (abort). No fifth decide-site, no `try`, no `isinstance` was added at any of the 16 unguarded call sites; see D-2 for the three `isinstance` calls that live inside the reader. |
| C-11 | Honoured; ground recorded | `save_settings()` is unguarded, exactly as at HEAD. **The ground:** no value reaching it can fail a UTF-8 encode. Every settings key but `update_interval` is a validated ASCII enum or boolean — `lang` (`en`/`zh`), `mode`, `ipv6` (`on`/`off`/`auto`), `telemetry` (`block`/`allow`), `default_tun` (bool), `clash_api_port` (int) — and `update_interval` is the one key copied verbatim from `argv` (`bin/sc:3377`), whose only non-ASCII path already dies earlier at `bin/sc:3365`'s locale-encoded `write_text` of the timer file. So this diff provably does not change that function's failure surface, "unchanged from HEAD" is true, and RT-4 travels to the pool with this ground appended. |
| C-12 | Satisfied | Files I touched: `bin/sc`, `CHANGELOG.md`, `docs/dev-map.md`, `CONTEXT.md`, and this task's own documents. **No new file created anywhere in the worktree.** `git status` also shows `docs/batches/followups/BATCH_LOG.md` and `BATCH_PLAN.md` modified — those were already modified in the working tree when this stage started (PM batch bookkeeping) and carry none of my edits. |
| C-13 | Recorded | On an FR-6 abort the same sentence reaches stderr **twice**: `_load_lang()`'s `⚠️  Cannot use …` warning first (written before `LANG` exists, hence English), then `main()`'s abort line without the `⚠️` prefix. Measured on `sc lang zh` over an unusable `settings.json`: two occurrences of the string, exit 1, and the *last* stderr line is the abort sentence. AC-6 must be read as "the abort sentence on the exit path", never as an occurrence count. |
| C-14 | Restated | The frozen region is `_load_override()` at **`bin/sc:1435-1496`** (not `:1425-1496`, which sweeps in ten lines of `_merge()`). `_load_override()` is unchanged by this diff — verified by `git diff`: no hunk touches any line in that range, nor `OverrideError`'s `path` attribute, nor `main()`'s three executable handler lines. |
| C-15 | Honoured | AC-21 stays **BLOCKED**. Nothing on this host was run as root, no `/usr/local/bin/sc` was invoked, no `/etc/sing-box` or `/var/lib/sing-box` path was written, and the live service was never touched or queried. No fixture result anywhere in this document is offered as satisfying AC-21. |

## Open issues for review

1. **AC-11 and AC-12 name an environment that is not a non-UTF-8 environment.** Under
   `LC_ALL=C PYTHONCOERCECLOCALE=0` on Python 3.7+ (this host: 3.12.3) PEP 540 auto-enables UTF-8 Mode
   because `LC_CTYPE` is `C`, so `sys.stdout.encoding`, `locale.getpreferredencoding(False)` and the
   filesystem encoding are **all UTF-8** and every locale assertion passes vacuously — HEAD stores
   `péq` correctly and shows no control failure at all. `PYTHONUTF8=0` must be added. `01_RATIONALE.md`
   already records R-62's own measurement as `LC_ALL=C PYTHONUTF8=0`; only its §"Where the sentences
   go" paragraph, and AC-11/AC-12/V-11/V-12 with it, drop the flag. Stage 6 must pin all three.
2. **AC-11's and AC-12's "exits 0" clause is unsatisfiable in this row's scope, and the row still
   passes on substance.** Under the corrected environment the candidate writes the correct bytes and
   *then* dies in `cmd_add`'s own success line at `bin/sc:2345`, `print(t("Added: {tag} ({type} → …"))`
   — `U+2192`, an sc-authored character, not a node tag — because stdout encodes strictly. That is
   out-of-scope item 2 / BC-14 / RT-3, i.e. T-25. What is verified: the password on disk decodes to
   exactly `péq` with no `\uXXXX`, and a pre-existing `香港节点` tag survives a read-modify-write
   byte-identically while HEAD raises `UnicodeEncodeError` (V-11) and `UnicodeDecodeError` (V-12).
   Stage 6 should record AC-11/AC-12 as PASS on the disk clause and BLOCKED-BY-T-25 on the exit clause,
   not as an outright pass or fail.
3. **AC-8's control is not twelve tracebacks — it is eleven tracebacks and one silently wrong
   answer.** `sc now` on a `{}` `nodes.json` exits **0** at HEAD and prints `(none)`, because
   `cmd_now` only does `.get("active")`. The cell still discriminates (candidate exits 1 naming the
   file), but a `06` row asserting "HEAD tracebacks all twelve" would be false.
4. **RT-4 is now the only authored document without a rendered write failure**, and after E-14 its
   writer also carries the first-run seed — so an `EROFS`/`ENOSPC` at seed time is a traceback on a
   *fresh* install, where before it was a traceback on the same line by a different route. No change
   in kind; the pool row should carry C-11's ground.
5. `_read_state` gives `nodes.json` no `default`, so a **missing** node store now renders
   `Cannot use …/nodes.json: cannot be read (No such file or directory)`. Reachable only when
   `_init_files()` did not run (`sc doctor`, `sc config`) or the file was removed mid-run; `sc doctor`
   answers it on its own scale. Intended (I-4, BC-5), but it is the one new sentence a user could meet
   on a half-installed host, so it is stated here rather than discovered in review.

## Dev-map updates

1. `## bin/sc internal sections` → `# State files` cell: now lists `_unusable`, `_read_state` and
   `_settings_or_empty`, states that `_read_state()` is THE reader and that `load_nodes()` /
   `load_settings()` are one-line adapters, and records that both `_init_files()` branches are now a
   single `save_nodes()` / `save_settings()` call — which is what gives each document one writer.
2. `## Reusable utilities` → new row **"Is this state document usable?"** for
   `_read_state` / `_unusable` / `_settings_or_empty`: the explicit UTF-8 decode, the one shape check,
   the one failure family rendered by `main()`'s existing arm, why `default` differs between the two
   documents, what the reader deliberately does *not* claim (BC-9, and `_load_override()`'s three
   policies), and RT-6's rule for a future call site — **read-only accessors call
   `_settings_or_empty()`, read-modify-write callers call `load_settings()` so they abort instead of
   clobbering.**
3. Three existing rows corrected so the ledger cannot contradict the shipped file:
   `## Reusable utilities` → `_telemetry_setting()` row — the sentence "Its guard tuple is
   `_ipv6_setting()`'s and inherits the same hole: a non-UTF-8 `settings.json` raises
   `UnicodeDecodeError` …" is **deleted**, because E-9/E-10 removed both guard tuples and this diff
   closed that hole; the row now ends at "Reads one file; writes nothing". `## Reusable utilities` →
   `_write_private()` row now spells the `fdopen(fd, "w", encoding="utf-8")` step in the ordered
   chain. `## bin/sc internal sections` → `# Config generation` cell now says an `OSError` **or
   `ValueError`** there is one translated stderr line + `return False` (E-15).
4. No folder, module or script was added or moved, so `## Folder layout` is unchanged.

## Insight to surface

- `LC_ALL=C PYTHONCOERCECLOCALE=0` does **not** give a non-UTF-8 Python: PEP 540 auto-enables UTF-8 Mode whenever `LC_CTYPE` is `C`/`POSIX`, so stdout, `getpreferredencoding()` and the filesystem encoding all stay UTF-8 and every encoding assertion passes on broken and fixed code alike — only adding `PYTHONUTF8=0` produces `ascii`, and it is the flag R-62's original measurement used · evidence: measured on python 3.12.3, `LC_ALL=C PYTHONCOERCECLOCALE=0` → `stdout=utf-8 preferred=utf-8`, `+PYTHONUTF8=0` → `stdout=ascii preferred=ANSI_X3.4-1968`; docs/features/state-file-io-contract/04_RATIONALE.md
- A `sc doctor` probe that raises loses its **whole section**, not one row: `_doctor_clash()` returns its four rows as one list, so an exception anywhere in it collapses Clash API + responding + node delays + DNS lookup into a single `this check could not run: {e}` row — measured by reverting E-16 alone, which drops the table from 22 rows to 19 while still printing no traceback and still exiting 1 · evidence: bin/sc:2791 guard vs `_doctor_run`'s per-probe catch
- A harness that loads `bin/sc` with `exec(compile(open("bin/sc").read(), …))` must pass `encoding="utf-8"`: under a genuinely non-UTF-8 locale the plain `open()` decodes the *source* with the locale and dies with `UnicodeDecodeError` at the first `⚠️`, which looks exactly like the product bug under test — the interpreter itself always reads source as UTF-8 (PEP 263), so the plain form is a harness artefact, not sc's behaviour · evidence: docs/dev-map.md "patterns to avoid" neutralisation recipe

## Verdict

READY FOR REVIEW
