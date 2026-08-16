# T-29 · state-file-contract-completion — Solution Design

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

- What changes: six call sites in `bin/sc` gain `encoding="utf-8"`; `save_settings()` gains the
  write-failure renderer `save_nodes()` already has; `generate_config()` gains **one call** to the
  existing `load_settings()`, which is the whole of FR-6; `_resolve_clash_port()`'s swallow names one
  more exception class, and `cmd_update_rules()`'s recovery call gains a handler scoped, by the
  `.path` the raiser already attached, to FR-6's refusal alone.
- What does not change: no new function, class, module, file, translation key, setting, flag or
  document format; `_read_state()` / `_unusable()` / `_settings_or_empty()` / `main()`'s abort
  envelope / `_write_private()` / `_config_digest()` / `_redact()` are read, not edited — and every
  unusable-document failure other than FR-6's still reaches that envelope and names its document
  exactly as at HEAD.
- Where the seam is: `generate_config()` is the single composition entry point — every regenerating
  command reaches it and no reporting command does — so FR-6 is one statement at one site, and it is
  the T-23 reader's own *unusable* outcome, not a new predicate (Q-2).

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| E-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_global_ipv6_iface()` `:1667` — `IF_INET6_PATH.read_text()` gains `encoding="utf-8"`. +1/−1 | single |
| E-2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_drift_state()` `:2015` — `STATE_PATH.read_text()` gains `encoding="utf-8"`, `.strip()` unchanged. +1/−1 | single |
| E-3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_doctor_ipv6()` `:2705` — `CFG_PATH.read_text()` inside `json.loads(...)` gains `encoding="utf-8"`. +1/−1 | single |
| E-4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `cmd_config()` `:3121` — `CFG_PATH.read_text()` gains `encoding="utf-8"`. +1/−1 | single |
| E-5 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `cmd_update_interval()` systemd arm `:3451-3453` — the drop-in `write_text(...)` gains `encoding="utf-8"` on its argument line; the call stays three physical lines. +1/−1 | single |
| E-6 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `cmd_update_interval()` OpenRC arm `:3499` — the periodic-script `write_text(...)` gains `encoding="utf-8"`; `chmod(0o755)` untouched. +1/−1 | single |
| E-7 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `save_settings()` `:615-617` — the existing `write_text` is wrapped in the renderer of I-1; existing comment `:616` kept. +6/−1 (5 code, 1 comment) | single |
| E-8 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_resolve_clash_port()` `:449-452` — `except OSError:` becomes `except SystemExit:` plus one comment line naming FR-5. +2/−1 (1 code, 1 comment) | single |
| E-9 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `generate_config()` — one `load_settings()` statement inserted between the override wrapper (`:2065`) and `nodes_data = load_nodes()` (`:2066`), plus two comment lines. +3/−0 (1 code, 2 comment) | single |
| E-10 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `cmd_update_rules()` `:3396` — the `regen_ok = generate_config()` call is wrapped per I-3: `try:`, the re-indented call, `except OverrideError as e:`, one comment line naming FR-7's scope, the guard clause `if e.path != SETTINGS_PATH:` + a bare `raise`, then `regen_ok = False`. +7/−1 (6 code, 1 comment) | single |
| E-11 | `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` | edit | three assertion functions added (I-5, I-6, I-7) and appended to `TESTS` `:366-374` in that order; no existing assertion, helper or docstring altered | single |
| E-12 | `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json` | edit | `test_count` 14 → 17 and `passing_count` 14 → 17; `notes` unchanged | single |
| E-13 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | four in-place clause corrections, no new row: (a) the `# Commands` row's `cmd_config()` clause "one `read_text()`" names the codec (AC-18); (b) the `# State files` row records that `save_settings()` renders its write failure like `save_nodes()`, mode/mechanism unchanged; (c) the "Is this state document usable?" utility row gains the clause that `generate_config()` calls `load_settings()`, so an unusable settings document refuses every regenerating run, and that `_resolve_clash_port()`'s persist catches `SystemExit`, and one clause recording that `cmd_update_rules()`'s recovery arm handles that refusal alone, discriminating on `OverrideError.path`, so every other unusable document still reaches `main()`'s envelope; (d) the contract-suite row's "14 named assertions" → 17 and its subject list gains `save_settings` and the source scan | single |
| E-14 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | one bullet under `## [Unreleased]` → `### 修复`, Chinese, stating: a regenerating run now refuses on an unusable `settings.json` (and that deleting the file restores every default), a failed `settings.json` write is now one sentence instead of a traceback, and every file read/write now names UTF-8 so `sc config` / `sc doctor` behave identically under any locale | single |
| E-15 | `/home/alan/Programs/singbox-cli/docs/features/state-file-contract-completion/04_DEVELOPMENT.md` | new | Developer's stage output | single |
| E-16 | `/home/alan/Programs/singbox-cli/docs/features/state-file-contract-completion/05_CODE_REVIEW.md` | new | Code Reviewer's stage output | single |
| E-17 | `/home/alan/Programs/singbox-cli/docs/features/state-file-contract-completion/06_TEST_REPORT.md` | new | QA Tester's stage output | single |
| E-18 | `/home/alan/Programs/singbox-cli/README.md`, `/home/alan/Programs/singbox-cli/README.zh-CN.md` | edit | the `sc config` stdout/stderr paragraph (`README.md:297`, `README.zh-CN.md:297`) is corrected in place — **one diff hunk per file, that paragraph and nothing else**. Acceptance surface is AC-11's four behavioural assertions, each carried in each language: **(a)** a character stdout cannot encode is written as a backslash escape and the run does **not** end — the whole masked document reaches stdout, exit 0; **(b)** the escape has **three** spellings, `\xNN` / `\uNNNN` / `\UNNNNNNNN`, chosen by the character (Latin-1 range / elsewhere in the BMP, the CJK case / above the BMP); **(c)** **only `\uNNNN` is a JSON escape**, so a redirected file whose escapes are all of that form is still valid JSON while a file carrying either other spelling is not; **(d)** a UTF-8 stdout is how an unescaped document is obtained in every case. Two negatives bind as well: neither paragraph may claim that escaping invalidates the saved file irrespective of the character, and neither may make a claim about the saved file that V-11's three-tag fixture does not verify. Wording is the implementer's, **in each language**; both languages must carry the **same facts** (project language policy puts human-facing docs in Chinese, and both READMEs exist, so the English paragraph alone is not the correction). This row adds **no product code line**: a README hunk is not `bin/sc` | single |

Itemised NFR-1 spend for `bin/sc` (E-1…E-10): **+24 / −9, of which 19 added lines are code and 5 are
comments.** E-18 touches neither `bin/sc` nor any other product file and changes no term of this
accounting. Per hunk: codec sweep +6/−6 (6 code); E-7 +6/−1 (5 code, 1 comment); E-8 +2/−1 (1 code,
1 comment); E-9 +3/−0 (1 code, 2 comment); E-10 +7/−1 (6 code, 1 comment). A comment trailing a code
line occupies no line of its own and is never counted as one. Budget is +25/−12 with ≤14 added code
lines and ≤6 documentation lines: the line budget holds with 1 line of slack and the comment count
with 1 of slack; the code count exceeds by **5**, itemised line by line in K-11.

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `save_settings(d)` — `bin/sc` `# State files` | signature unchanged; body becomes `try: <the existing write_text, now inside the try> / except (OSError, ValueError) as e: sys.exit(t("Could not write {path}: {err}", path=SETTINGS_PATH, err=_plain(getattr(e, "strerror", None) or str(e))))` — the same five elements, same order, same key as `save_nodes()` (`bin/sc:589-595`) | After this change `save_settings()` raises **only** `SystemExit`: no `OSError` and no `ValueError` escapes it. The cause clause is `getattr(e, "strerror", None) or str(e)` — never a bare `e.strerror` (a `UnicodeEncodeError` carries none and the handler would raise `AttributeError` inside itself). The path, the mode (`0644`) and the write mechanism (`write_text`, non-atomic) are unchanged, and `ensure_ascii=False` + `encoding="utf-8"` stay as they are |
| I-2 | `generate_config()` — `bin/sc` `# Config generation` | signature and return type unchanged (`True`/`False`); one added precondition statement `load_settings()` whose value is discarded, placed after the `_load_override()` wrapper and before `nodes_data = load_nodes()` | On an unusable `settings.json` it raises `OverrideError` with `.path == SETTINGS_PATH` before it composes, before the stale-selection `save_nodes()`, before `_write_private()`, before `_record_generated()` and before any caller's restart — so `config.json`, `.config.sha256` and `settings.json` are all byte-identical after the raise. On an **absent** settings.json it returns `{}` and nothing changes (BC-1). It forms no opinion of its own about usability: the judgement is `_read_state()`'s and the sentence is `_unusable()`'s |
| I-3 | `cmd_update_rules()`'s recovery regeneration — `bin/sc:3392-3396` | `regen_ok = generate_config()` moves inside `try:`; `except OverrideError as e:` opens with the guard clause `if e.path != SETTINGS_PATH:` → bare `raise` (no `else`), and only past that guard sets `regen_ok = False` | The arm is scoped to FR-6's refusal and to nothing else. `generate_config()` raises `OverrideError` from four sites; the three that are not FR-6's — `_load_override()`'s wrapper (`.path = OVERRIDE_PATH`, `:2057-2064`), `load_nodes()` (`.path = NODES_PATH`, `:2066`) and the composition fault clause (`.path` `OVERRIDE_PATH` or `None`, `:2131-2136`) — leave `cmd_update_rules()` untouched, reach `main()`'s envelope (`:3773-3788`) and print their sentence exactly as at HEAD, so no run-level outcome line is printed for them, also exactly as at HEAD. The guard reads **provenance, not usability**: `.path` is what the raiser attached (`_unusable()`, `:554-558`) and the class carries `None` as its default (`:1237`), so no `getattr` is needed, no document is judged a second time (Q-2, K-1) and `None` sorts to the re-raise. The bare `raise` preserves the exception object and its traceback. For FR-6's own refusal the run keeps its one-outcome contract: `ok` is still the single determination (`:3407`), exactly one run-level outcome line is printed (`:3410-3420`), the conditional restart at `:3400` is not taken because `regen_ok` is False, the run exits 1 at the one exit site (`:3424-3425`), and the sentence naming the file and the cause is the announcement `_load_lang()` already wrote for this run (K-4). Both sides of the comparison read the module global `SETTINGS_PATH` when the call runs, so a fixture that repoints it moves the raise site and the guard together |
| I-4 | the codec property, as the shipped rule | every call in `bin/sc` to `Path.read_text` / `Path.write_text` / `Path.open` / `os.fdopen` / `open()` that is **not** in binary mode carries `encoding="utf-8"` spelled exactly, and no call to `json.loads` takes a `read_bytes()` result directly | The population is file text I/O and it has **no exception**. `Path.open` is inside it, at all four of its call sites (`:932`, `:1196`, `:1966`, `:2640`); each is admitted today by its **mode literal** being binary, never by the callee being out of scope, so a future text-mode `Path.open` is a violation of the shipped rule rather than a hole in it. Binary-ness is decided from a literal `mode` argument (positional or keyword); a call whose mode is not a literal cannot be proved binary and is a failure, not a pass. `bytes.decode()` / `str.encode()` with no argument are UTF-8 by definition and are not file I/O sites |
| I-5 | `every_file_read_and_write_names_utf8(sc)` — new assertion, `check-sc-contracts.py` | module-level function of the loaded module, one `sc` parameter, returns an evidence `str`, raises `AssertionError` on failure — the shape of every existing assertion. Reads the source of the **loaded** module (its path is `sc.generate_config.__code__.co_filename`, so `--source` drives a mutated clone) and walks it with `ast`; asserts I-4 over every matching `ast.Call`; reports two counts and asserts both are non-zero — text-mode sites asserted, and binary-mode sites admitted by their mode literal | Kills a codec **substitution** at any of the sites (`latin-1`), not only a deletion (insight 2026-08-16: deletion is invisible on a UTF-8 host). Reporting the binary count is what stops the assertion passing vacuously by classifying a site as unseen rather than as inspected-and-binary. Pure: no fixture, no I/O outside reading that one source file, no subprocess |
| I-6 | `unusable_settings_refuses_regeneration(sc)` — new assertion | same shape; uses `fixture()`, writes a valid node store through `save_nodes()` and a `settings.json` whose content is `[]`, then drives `_refused(sc, sc.generate_config, sc.SETTINGS_PATH, sc.t("the top level must be a JSON object"), …)` and asserts `CFG_PATH` and `STATE_PATH` do not exist and `SETTINGS_PATH`'s bytes are unchanged | `[]` is chosen because its sentence is a fixed translation key with no interpolated parser text (BC-3). Asserting `.path == SETTINGS_PATH` with a *valid* node store present is what proves the refusal precedes `load_nodes()`. Killed by deleting I-2's statement |
| I-7 | `settings_write_failure_is_a_sentence(sc)` — new assertion | same shape; two cases against `save_settings()`, each expecting `SystemExit`: (a) `SETTINGS_PATH` repointed at a path whose parent does not exist (an `OSError` carrying `strerror`), (b) a value UTF-8 cannot encode, supplied as a lone surrogate (a `ValueError` carrying no `strerror`). Asserts for both: `str(e.code)` starts with the rendered `t("Could not write {path}: {err}")` prefix, contains `str(SETTINGS_PATH)`, and its cause clause is non-empty; asserts no exception other than `SystemExit` leaves the call | Killed by replacing the cause clause with a bare `e.strerror` (case b then raises `AttributeError` inside the handler) and by removing the `try` (case a then raises `OSError`). It asserts nothing about whether a file exists afterwards — a part-way `write_text` legitimately leaves a truncated document (BC-5) |
| I-8 | `.harness/scripts/baseline.json` | `test_count: 17`, `passing_count: 17` | The floor equals `len(TESTS)`; it is raised by exactly the number of assertions added (three) and no assertion is removed (BC-16) |

## Constraints

**K-1** — The implementer must not add any predicate, flag, helper or set that decides whether
`settings.json` is usable; FR-6's refusal is the existing `load_settings()` → `_read_state()`
outcome and nothing else (Q-2, NFR-3).

**K-2** — The implementer must place I-2's statement **after** `generate_config()`'s `_load_override()`
try/except and **before** `nodes_data = load_nodes()`, so the comment at `bin/sc:2049-2052` ("the
override is parsed FIRST, before any state is read or written") stays true and the override keeps
precedence in the reported cause.

**K-3** — The implementer must not give `save_settings()` a second writer, a temp-and-replace, a mode
change or an atomicity guarantee; only the failure rendering is added (Q-9, out-of-scope 1 and 2).

**K-4** — The implementer must rely on `main()`'s `_load_lang()` announcement as the FR-6 sentence for
`sc update-rules` and must not render a second one at `cmd_update_rules()`: `main()`'s `else` arm
(`bin/sc:3756-3758`) runs `_load_lang()` → `_settings_or_empty(warn=True)` for every command except
`doctor` and `config`, so the run has already written `⚠️ Cannot use {path}: {problem}` naming the
file and the cause before the download loop starts. This binds FR-6's refusal only: for every other
unusable document `cmd_update_rules()` still renders nothing, because K-13's re-raise hands the
failure back to `main()`'s envelope, which is the site that renders it.

**K-5** — The implementer must keep `UnicodeDecodeError` reported as a **read** failure at every site
E-1…E-4 touches: the existing clause order (`OSError` first, then `UnicodeDecodeError` / `ValueError`)
is load-bearing because `UnicodeDecodeError` is a subclass of `ValueError` and not of `OSError`, and
no site may hand `bytes` to `json.loads` (BC-7, BC-8).

**K-6** — I-5's scan must cover file text I/O only — `Path.read_text` / `Path.write_text` /
`Path.open` / `os.fdopen` / `open()` in text mode — and its docstring must state that bound **and**
I-4's binary-mode admission rule: `Path.open`'s four call sites are inside the population and pass on
a literal binary mode, counted as inspected rather than as unseen, and a site whose mode argument is
not a literal fails the assertion. A `subprocess.run(..., text=True)` pipe decode is **not** in the
population (RES-1 carries it), and the assertion must not be widened to it in this task.

**K-7** — The implementer must not lower `test_count` and must not delete or weaken any of the 14
existing assertions to make a number pass (BC-16, B.4 is a committed gate).

**K-8** — Every fixture written for this task must load `bin/sc` through the mandated recipe in
`docs/dev-map.md` **plus** the exec-denial shim `check-sc-contracts.py` demonstrates, must repoint
all nine path constants into a `mkdtemp` root, must never drive `_init_files()` (replace it on the
loaded module when a command's start-up path is needed), must never write `/etc/sing-box` or
`/var/lib/sing-box`, must never touch the live service, and must witness service state with
`systemctl show` only (NFR-5, R-78).

**K-9** — Every locale criterion must set `LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0` together and
must assert, in the same process and before any other clause of that criterion is credited, that
`sys.stdout.encoding` and `locale.getpreferredencoding(False)` are not UTF-8 aliases (NFR-6).

**K-10** — The implementer must add no translation key: every sentence this task renders already
exists in `TRANSLATIONS` (`Could not write {path}: {err}`, `Cannot use {path}: {problem}`, `the top
level must be a JSON object`, `not valid JSON ({err})`, `not valid UTF-8 text`) (NFR-2, AC-17).

**K-11** — The implementer must hold `bin/sc` to **+24/−9** as itemised in the change ledger, must
report any deviation line by line, and must never delete a comment or a guard to make a number come
out. Against NFR-1's own provenance (6 codec + 4 renderer + 2 FR-6 + 2 FR-7 = 14 added code lines)
the five extra code lines are: **+1** at E-7, because mirroring `save_nodes()` exactly puts its
`sys.exit(t(...))` on two physical lines; **+1** at E-8, which that provenance does not budget at all
(FR-5's one word lands on an existing line and is counted as one added line); **−1** at E-9, where
FR-6 costs one statement rather than two; **+4** at E-10, of which two are wrapping artefact (`try:`
and the re-indented existing call, the same accounting NFR-1 applied to its six codec lines) and two
are I-3's guard clause (`if e.path != SETTINGS_PATH:` and `raise`), which is what keeps the other
three unusable-document sentences.

**K-13** — The implementer must not let E-10's arm handle an `OverrideError` whose `.path` is not
`SETTINGS_PATH`: the arm re-raises first and assigns `regen_ok` second, and must not be collapsed
into one undifferentiated clause (C-1, out-of-scope 7). The guard must test only the `.path` the
raise site attached — never the document's content, its name on disk, or a fresh read of it — so it
adds no second opinion about whether any document is usable (Q-2, K-1).

**K-12** — The implementer must correct exactly the `sc config` stdout/stderr paragraph of both
READMEs (E-18) and must leave every other sentence of both files byte-identical to HEAD — the freeze
is lifted for that one paragraph and, in the same breath, for nothing else, because the freeze is
what stops a true-sentence repair becoming a README rewrite. No section is added, retitled, moved or
reflowed; no other paragraph of either file is re-read for accuracy (that sweep is T-32's, at its own
"correct the sentences and add nothing" limit); and no doc-lint step, prose template or
documentation-accuracy mechanism is introduced anywhere in this task (Q-14, out-of-scope 10, NFR-3's
permitted-paths clause, `.harness/rules/85-design-discipline.md`).

## Frozen set

| path | why frozen |
|---|---|
| `/home/alan/Programs/singbox-cli/README.md`, `/home/alan/Programs/singbox-cli/README.zh-CN.md` — **every sentence except** the `sc config` stdout/stderr paragraph (`:297` in each) | NFR-3 admits these two files for that one paragraph only. The paragraph itself is unfrozen by K-12 / E-18, because the repair makes one of its two claims false (Q-5) and a change may not ship a sentence it has itself falsified; everything else in both files stays frozen — exactly one hunk per file, no other sentence read, re-worded or reflowed |
| `/home/alan/Programs/singbox-cli/bin/sc` `_write_private()` (`:487-537`, `def` at `:487`) | T-13 / BC-9 / AC-15 — the single definition of installing a credential document, the only writer of `config.json`, `fchmod` before the first byte |
| `bin/sc` `_config_digest()` / `_record_generated()` (`:1952-1994`, `def`s at `:1952` and `:1977`) | T-14 / BC-10 / AC-15 — the drift record is a sha256 of the file's **bytes**; immune to every codec change here by construction, and it must stay that way |
| `bin/sc` `MASK` / `VISIBLE_IN_OUTBOUND` / `SECRET_KEYS` / `_redact()` and `cmd_config()`'s single `sys.stdout.write` (`:3055-3167`) | T-06 / BC-11 / AC-16 — always-redacted with no opt-out; E-4 changes the read's codec and nothing else on that path |
| `bin/sc` `_read_state()` / `_unusable()` / `_settings_or_empty()` (`:554-612`) | NFR-3 — the three T-23 seams are reused exactly as they stand; this task adds no fourth |
| `bin/sc` `main()`'s `except OverrideError` envelope (`:3773-3788`) and its read-only enumeration (`:3754`) | The one rendering site; adding a command to the enumeration or a second render site is out of scope |
| `bin/sc` `TRANSLATIONS` (`:130-392`) | NFR-2 / AC-17 — zero new keys |
| `bin/sc` `_init_files()` (`:540-551`) | Hard-codes `/var/lib/sing-box`; never edited and never driven by a fixture |
| `/home/alan/Programs/singbox-cli/install.sh`, `uninstall.sh`, `systemd/` | Outside NFR-3's permitted paths; `install.sh`'s own settings writer is RES-2, not this task |
| `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` | B.4's floor is read from `baseline.json`; the gate itself is not edited to make a step pass |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | E-1…E-6 | none — behaviour-preserving on a UTF-8 host, and the two sites that carry a demonstrable defect (`:2705`, `:3121`) only stop failing | revert the six arguments; no state on disk changed |
| 2 | E-7 **and** E-8 together | must land in the same step: E-7 alone converts `_resolve_clash_port()`'s opportunistic persist from a swallowed `OSError` into a fatal `SystemExit`, which turns every command on a read-only host into a failure (Q-7, AC-8) | revert both together |
| 3 | E-9 | E-7/E-8 in place, so a refusing run cannot also hit an unrendered write failure | revert one statement; no persisted state has changed shape, so a downgraded build reads every document it wrote |
| 4 | E-10 | E-9 in place, otherwise the arm's `SETTINGS_PATH` branch is unreachable and untestable (its re-raise branch is reachable at HEAD and stays behaviour-preserving) | revert the wrapper; every `OverrideError` returns to `main()`'s envelope and `regen_ok` to its hoisted value |
| 5 | E-11 **and** E-12 together | E-1…E-10 shipped: the three assertions fail on HEAD by construction, so raising the floor before the product change reddens B.4 | revert both together; the floor is never left above `len(TESTS)` |
| 6 | E-13, E-14 | product change final, so the documents describe shipped code (AC-18) | revert |
| 7 | E-18 | product change final **and** V-11's three-tag measurement taken, so every clause of the corrected paragraph is written against a measured row rather than from reasoning; both languages are corrected in the same commit (a commit correcting only English ships a half-true pair) | revert the one hunk in each file; both READMEs return to HEAD, and the paragraph is again vacuously wrong rather than live |

No data migration, no schema change, no feature flag, no compatibility shim: no document's on-disk
format, name, mode or location changes. The one user-visible behaviour change is that a regenerating
run on a **present but unusable** `settings.json` now fails instead of installing a configuration
built from defaults; the user's route back to a working host is to delete the file (every default
returns, BC-1), and that route is stated in E-14's changelog entry, never in a new product sentence
(Q-8, out-of-scope 8).

## Out of scope

- The error model of the user override, the node store and the composition fault (out-of-scope 7): E-10 re-raises all three untouched, and `main()`'s envelope keeps rendering them.
- The write-failure rendering of the systemd timer drop-in and the OpenRC periodic script — codec only (Q-10).
- `settings.json`'s mode, atomicity, second writer, size cap or `S_ISREG` test (Q-9, out-of-scope 1, 2, 9).
- Any reordering of a command's settings read against its service action (out-of-scope 4).
- `install.sh`'s own `settings.json` reader/writer at `install.sh:492-506` (RES-2).
- `subprocess.run(..., text=True)`'s locale-dependent pipe decode at `bin/sc:2148` and `:3458` (RES-1).
- The drift record's ordering against `sing-box check` and the delay reader's return shape — T-30 (out-of-scope 5).
- `archive-task.sh`, `guard-rm.sh` and every R-73/R-81/R-86/R-87/R-89/R-90/R-92 row.
- Any new user-facing sentence **the program emits**, translation key, repair hint or `sc config` behaviour/surface change — E-18 corrects documentation, not output, and adds no key.
- Any README change beyond E-18's single paragraph in each language: no other sentence of either file is reviewed, corrected or reflowed here (T-32 owns the remaining prose sweep), and no doc-lint step, prose template or general documentation-accuracy mechanism is added anywhere (Q-14, out-of-scope 10).

## Verification plan

Every [B] row runs one case per child process (a fixture cannot call `main()` twice — insight
2026-08-15), through K-8's loader, with `SYSTEMD = OPENRC = False`, `SB_BIN` a stub exiting 0, and
`_init_files` replaced on the loaded module. "HEAD control" means the same fixture driven against a
pristine **clone** of the repository at HEAD, never a worktree.

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | `sc reload` on a fixture with a usable node store, a `config.json` of known bytes, a `.config.sha256` of known bytes and a `settings.json` that is not valid JSON; sha256 of all three before/after | exit non-zero; the refusal sentence names `settings.json` and its cause; all three digests unchanged; no restart attempted (`SYSTEMD`/`OPENRC` false and `restart_service()` never reached). HEAD control on the same fixture exits **0** and replaces `config.json` and the record | AC-1 |
| V-2 | Same fixture, whose `config.json` was generated while settings were usable with `telemetry: allow` and a recorded `clash_api_port: 29500` — outside `[CLASH_PORT_BASE, CLASH_PORT_BASE + CLASH_PORT_SPAN)` = `[29090, 29190)` and different from `_free_port()`'s `29090` fallback, so the prober can never return it (`bin/sc:70-71`, `:404-413`): diff HEAD's regenerated document against the pre-existing one; assert no document is emitted by the candidate | control shows both differences — a telemetry NXDOMAIN rule appears and the Clash API `external_controller` port moves off 29500; candidate emits nothing. The report names **which** difference reproduced, one line each, never a single joint verdict: neither reproduced ⇒ the row is NOT-DISCRIMINATING; exactly one reproduced ⇒ that half is credited and the other half is reported NOT-DISCRIMINATING with the observed port | AC-2 |
| V-3 | `sc reload` with a **usable** `settings.json` (`lang: zh`, `ipv6: off`, `telemetry: allow`, a recorded port); read the emitted document and `.config.sha256` | exit 0; no telemetry rejection rule; `_aaaa_rule(True)` at `dns.rules[0]`; the recorded port in the Clash API block; record == sha256 of the written file's bytes; output Chinese | AC-3 |
| V-4 | `sc doctor` and `sc ls` on V-1's fixture | doctor prints its complete table including its last row and exits on 0/1/2; `sc ls` exits 0 with its node rows; each run writes exactly one warning line naming `settings.json`; no `Traceback` | AC-4 |
| V-5 | `sc update-rules` on V-1's fixture with stubbed fetches, no init system, an existing `config.json`, and a rule-set whose bytes changed and which became usable; count run-level outcome lines | exactly one outcome line ("the sing-box service was not touched"), then exit 1; the restart arm is unreachable under this fixture and is named as excluded, not counted; `config.json` and the record byte-identical | AC-5 |
| V-6 | `sc mode global` with `settings.json` at mode `0444`, process not root. Its content is a usable document recording `clash_api_port: 29500`, so `_resolve_clash_port()` returns at `bin/sc:437-438` and the opportunistic persist at `:449-452` is never reached — the measured write is `cmd_mode`'s `save_settings()` at `:3176` and nothing else | exit non-zero, `Could not write {path}: {err}` naming `settings.json` with a non-empty cause, no `Traceback`. HEAD control raises `PermissionError` as a traceback out of that same call site | AC-6 |
| V-7 | `sc mode global` with `settings.json` carrying a lone surrogate under a key `sc mode` does not rewrite (a `"\udXXX"` escape the parser accepts) **and** a recorded `clash_api_port: 29500`, so again the only `save_settings()` the run reaches is `cmd_mode`'s at `:3176` | exit non-zero, the same sentence with a non-empty cause, no `Traceback` and no error raised inside the handler. HEAD control must show the encode error escaping as a traceback, else NOT-DISCRIMINATING | AC-7 |
| V-8 | `sc ls` with a usable `settings.json` recording no Clash port, mode `0444`; digest before/after | usual output and exit status, no "could not write" sentence, file byte-identical. The discriminating control is a scratch mutant of the **candidate** that keeps `except OSError:` at `bin/sc:451` — it must fail this row (HEAD passes it, so HEAD is not the control here) | AC-8 |
| V-9 | Under K-9's proved environment: `sc config` on a `config.json` carrying a CJK node tag (written to disk as real UTF-8 bytes, not transported through `os.environ` — insight 2026-08-15) and a fixture credential | environment proof printed first; exit **0**; the masked document on stdout with the tag as a backslash escape; no "cannot read" sentence. HEAD control in the same environment exits 1 with "cannot read" and prints no document | AC-9 |
| V-10 | Under the same environment and document, `sc doctor`'s AAAA row | states the host's decision and whether `config.json` carries it; never reports that the file cannot be read. HEAD control reports UNKNOWN naming a decode error | AC-10 |
| V-11 | Under AC-9's proved non-UTF-8 environment (K-9), `sc config` on a configuration carrying **one node tag per escape spelling** — `香港-01` (BMP outside Latin-1, AC-9's own mandated CJK fixture), `café-02` (Latin-1 range), `🚀-03` (above the BMP) — stdout redirected to a file, one run per tag; `json.loads` each saved file. Then `git diff` both READMEs and read each paragraph against that measured three-row table | The table: all three runs exit **0** with the whole masked document on stdout; the tag appears as `\uNNNN`, `\xNN`, `\UNNNNNNNN` respectively; `json.loads` **succeeds** for the CJK file and **fails** for the other two. Each paragraph, in its own language, carries all four assertions (a)–(d) of E-18 and neither of its two negatives; the two paragraphs assert the same facts. `git diff` shows **exactly one hunk per file**, and that hunk is the `sc config` stdout/stderr paragraph — every other line of both files byte-identical to HEAD. **The discriminating control is HEAD's own text, which FAILS clause (c) on the CJK row** (its saved file parses, while the text says the saved file is then not valid JSON), so this row cannot pass vacuously: a build that leaves either paragraph at HEAD — including one that corrects only the English file — FAILS | AC-11 |
| V-12 | Source scan of the shipped `bin/sc` for I-4 | every text read and write names `encoding="utf-8"`; no `json.loads` over a `read_bytes()`; the count of scanned sites is reported and non-zero | AC-12 |
| V-13 | `check-sc-contracts.py` full run, then once per mutation on a scratch **copy**: (a) `latin-1` substituted for `utf-8` at `bin/sc:3121`, (b) I-2's `load_settings()` statement deleted, (c) the cause clause replaced by a bare `e.strerror` | `17 defined, 17 run, 17 passed`; (a) kills I-5, (b) kills I-6, (c) kills I-7; each mutation kills its own assertion and is reverted before the next. An assertion no mutation kills is NOT-DISCRIMINATING, never passed. A codec **deletion** is explicitly not used — it is invisible on a UTF-8 host | AC-13 |
| V-14 | `.harness/scripts/verify_all` from the repository root, at stages 4 and 6 | `PASS 19 / WARN 0 / FAIL 0 / SKIP 1`, exit 0; `baseline.json`'s `test_count` equals `len(TESTS)`. A subdirectory invocation self-reports a false red and is not evidence | AC-14, NFR-4 |
| V-15 | Read `_write_private()`, `_config_digest()`, `_record_generated()` in the shipped file; `stat` `settings.json` after V-3's run | credential writer unchanged and still the only writer of `config.json`, mode still set on the descriptor before the first byte; digest still over the file's bytes; `settings.json` still `0644` and still written by `write_text` | AC-15, BC-9, BC-10 |
| V-16 | Read `cmd_config()` and diff `SECRET_KEYS` / `VISIBLE_IN_OUTBOUND` / `MASK` | exactly one `sys.stdout.write`, its argument through `_redact()`; key sets and mask literal unchanged; nothing added here reaches an unmasked rendering | AC-16 |
| V-17 | `git diff --stat` and a diff of the translation table | no new translation key, no new file/module/package/format; `bin/sc` within +24/−9 with 19 added code lines and 5 comment lines, itemised per hunk against K-11; `verify_all` A.1 PASS with this task's documents in place | AC-17, NFR-1, NFR-2 |
| V-18 | Read `docs/dev-map.md`'s corrected entries against the shipped code | the `cmd_config()` reader clause, the `save_settings()` clause, the state-document utility row and the contract-suite count are all true of the shipped file; no document claims a read decodes with the process locale | AC-18 |
| V-19 | Two runs of `sc update-rules` on V-5's fixture shape (no init system, stubbed fetches, an existing `config.json`, one rule-set whose bytes changed and became usable) but with a **usable** `settings.json` recording `clash_api_port: 29500`: (a) `override.json` that is not valid JSON, (b) a usable `override.json` and a `nodes.json` whose top level is a JSON array. Record both streams, the exit status, and the count of run-level outcome lines | each run exits non-zero and writes **one** sentence naming that run's failing document (`override.json` / `nodes.json`) with a non-empty cause clause; no "Rule-sets restored … config regenerated" line; **zero** run-level outcome lines, because under I-3 the failure reaches `main()`'s envelope — the same count HEAD produces. No pre-dispatch degrade line exists to be mistaken for the cause sentence (settings is usable), and the composition-fault path cannot fire under this fixture: it is named as excluded, not counted. The **discriminating control is a mutation**: a scratch copy of the candidate whose arm is one undifferentiated `except OverrideError:` must FAIL both cases; if it passes, report NOT-DISCRIMINATING. The HEAD control also passes this row, so it is reported as a **regression guard**, not a defect fix | AC-19 |
| V-20 | BC-1 regression: `sc reload` with `settings.json` **absent** on an otherwise valid fixture | the file is seeded, every accessor answers its default, no warning line, no refusal, exit 0 — absence is not unusability | BC-1 |
| V-21 | BC-14 regression: `sc use <tag>` on a fixture whose Clash API answers, with an unusable `settings.json` | the hot switch applies and the run does not reach `reload_or_restart()`, so FR-6 does not fire; the node store write of BC-13 stands and is not rolled back | BC-13, BC-14 |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | `subprocess.run(..., text=True)` at `bin/sc:2148` and `:3458` decodes a child's stderr with the process locale — outside FR-1's stated six-site population and outside I-5's scan (K-6), but it is the last locale-dependent text decode in the file; `bin/sc:2537-2538` already shows this repo's fix shape (`.decode("utf-8", "replace")`) | `07_DELIVERY.md`, then the pool as a T-30-family row |
| RES-2 | `install.sh:492-506` reads `settings.json` with `read_text()` and writes it with `write_text()` (both locale-dependent) and catches only `json.JSONDecodeError`, so a non-UTF-8 `settings.json` aborts the installer with a Python traceback under `set -euo pipefail`. It is also the second writer of that document and the reason a fresh install is unaffected by FR-6 | `07_DELIVERY.md`, then the pool |
| RES-3 | AC-1 counts **refusal sentences**, not stderr lines (C-8, settled): `sc reload` on an unusable `settings.json` puts two stderr lines carrying the same rendered key — `⚠️  Cannot use …` from `_load_lang()` → `_settings_or_empty(warn=True)` (`bin/sc:610-611`) and `Cannot use …` from `main()`'s envelope (`:3786-3788`). Both must be reported and only the second counted; neither is removed (K-4, P-1) | `06_TEST_REPORT.md` AC-1 row |
| RES-4 | Q-1's project-wide rule ("an unusable settings document blocks every run that writes, blocks no run that only reports") has no glossary term; `CONTEXT.md` is outside NFR-3's permitted paths, so no entry is added here | `07_DELIVERY.md`, then `CONTEXT.md` in a later task |
| RES-5 | The AC-13 mutation for I-5 is a codec **substitution** (`latin-1`); an argument **deletion** is invisible on a UTF-8 host and must be reported as a false kill, never as a kill (C-9) | `04_DEVELOPMENT.md`, `06_TEST_REPORT.md` mutation table |
| RES-6 | `baseline.json`'s `test_count` is a floor: 14 → 17 in the same commit as the three assertions, never lowered, and no existing assertion deleted or weakened to make a number pass (C-10, K-7) | `04_DEVELOPMENT.md`, then `verify_all` B.4 at stages 4 and 6 |

## Partition assignment

partition: **single**. This project has no `.harness/agents/dev-*.md` partition agents; one Developer
implements E-1…E-14 and E-18 in the order of `## Migration & edit sequence`. No parallelism, no
dispatch order beyond that table.

## Verdict

READY
