# T-29 · state-file-contract-completion — Development

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

## Summary

- E-1…E-10 landed in `bin/sc` exactly as the ledger itemises them: six explicit-codec arguments, the
  `save_settings()` write-failure renderer mirroring `save_nodes()`, `_resolve_clash_port()`'s swallow
  moved to `SystemExit`, FR-6's one `load_settings()` statement in `generate_config()`, and
  `cmd_update_rules()`'s recovery arm scoped by `OverrideError.path`.
- The committed contract suite gained the three assertions I-5 / I-6 / I-7 and the assertion floor moved
  14 → 17 in the same change; each new assertion is killed by its stated mutation on a scratch copy.
- `docs/dev-map.md` (E-13), `CHANGELOG.md` (E-14) and both READMEs' `sc config` stdout/stderr
  paragraph (E-18 — one hunk per file at `:297`, written from a measured three-spelling table, not
  reasoned) were corrected to the shipped code; `install.sh` and every other sentence of both READMEs
  are byte-identical to HEAD.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` `:1673` | `_global_ipv6_iface()`'s `IF_INET6_PATH.read_text()` names `encoding="utf-8"` | E-1 |
| `bin/sc` `:2021` | `_drift_state()`'s `STATE_PATH.read_text()` names the codec; `.strip()` unchanged | E-2 |
| `bin/sc` `:2714` | `_doctor_ipv6()`'s `CFG_PATH.read_text()` inside `json.loads(...)` names the codec | E-3 |
| `bin/sc` `:3130` | `cmd_config()`'s `CFG_PATH.read_text()` names the codec — the read's codec and nothing else on T-06's path | E-4 |
| `bin/sc` `:3466-3468` | the systemd timer drop-in `write_text(...)` names the codec on its argument line; the call is still three physical lines | E-5 |
| `bin/sc` `:3514` | the OpenRC periodic-script `write_text(...)` names the codec; `chmod(0o755)` untouched | E-6 |
| `bin/sc` `:616-623` | `save_settings()` wraps its existing `write_text` in I-1's renderer: same five elements, same order, same key and same `getattr(e, "strerror", None) or str(e)` cause clause as `save_nodes()` (`:590-596`). Path, `0644` mode and non-atomic `write_text` mechanism unchanged | E-7 |
| `bin/sc` `:449-454` | `_resolve_clash_port()`'s opportunistic persist catches `SystemExit` instead of `OSError`, plus one comment naming FR-5. The `try` still holds exactly one statement (P-3) | E-8 |
| `bin/sc` `:2072-2074` | `generate_config()` calls `load_settings()` after the `_load_override()` wrapper and before `load_nodes()` (K-2), value discarded (P-4), plus two comment lines | E-9 |
| `bin/sc` `:3405-3411` | `cmd_update_rules()`'s `regen_ok = generate_config()` moves inside a `try`; `except OverrideError as e:` re-raises first (`if e.path != SETTINGS_PATH: raise`) and assigns `regen_ok = False` second | E-10 |
| `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` | `import ast`; four private helpers (`_literal_str`, `_argument`, `_io_callee`, `_json_loads_over_read_bytes`), the assertion helper `_write_failure`, and the three assertions `every_file_read_and_write_names_utf8` / `unusable_settings_refuses_regeneration` / `settings_write_failure_is_a_sentence`, appended to `TESTS` in that order. No existing assertion, helper or docstring altered | E-11 |
| `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json` | `test_count` 14 → 17, `passing_count` 14 → 17; `notes` unchanged | E-12 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | four in-place clause corrections, no new row (see `## Dev-map updates`) | E-13 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | one Chinese bullet at the head of `## [Unreleased]` → `### 修复` | E-14 |
| `/home/alan/Programs/singbox-cli/README.md` `:297` | the `sc config` stdout/stderr paragraph: the escape clause now states that the run does **not** end (whole masked document on stdout, exit `0`), enumerates the **three** spellings against the character that selects each, states that **only `\uNNNN` is a JSON escape** — so an all-`\uNNNN` saved file is still valid JSON while a `\xNN` / `\UNNNNNNNN` one is not — and keeps UTF-8 stdout as the unescaped route in every case. One hunk, one line; the paragraph's first and last sentences are unchanged | E-18 |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` `:297` | the same four assertions in Chinese, same facts, same bounds. One hunk, one line | E-18 |

`git diff --stat`: `bin/sc | 33 ++++--- (24 insertions, 9 deletions)`, `README.md | 2 +-`,
`README.zh-CN.md | 2 +-`; whole change `7 files changed, 206 insertions(+), 17 deletions(-)`.
`git diff -U0` reports **exactly two** hunk headers across the two READMEs — `@@ -297 +297 @@` in each.

**NFR-1 spend, measured:** `bin/sc` **+24 / −9**, of which **19 added lines are code and 5 are
comments** — exactly the design's itemisation, per hunk: codec sweep +6/−6 (6 code); E-7 +6/−1
(5 code, 1 comment); E-8 +2/−1 (1 code, 1 comment); E-9 +3/−0 (1 code, 2 comment); E-10 +7/−1
(6 code, 1 comment). No deviation to report, no line trimmed to hit a number. **E-18 adds no product
code line** — a README hunk is not `bin/sc`, and `git diff --numstat bin/sc` still reads `24 9`.

## verify_all result

```
baseline (HEAD, repository root): PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0
after   (candidate, same shell) : PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0
delta                           : 0 new FAIL, 0 new WARN, baseline preserved
B.4 line (verbatim)             : [B.4] bin/sc contract assertions ... PASS
contract suite (direct run)     : summary: 17 defined, 17 run, 17 passed  (exit 0)
assertion floor                 : baseline.json test_count = 17 = len(TESTS)
new-assertion evidence          : every_file_read_and_write_names_utf8 — 8 text site(s) name utf-8; 5 binary site(s) admitted by a literal mode
                                  unusable_settings_refuses_regeneration — refused by name with a valid node store present; no config, no drift record
                                  settings_write_failure_is_a_sentence — OSError -> 'No such file or directory'; a value UTF-8 cannot encode -> "'utf-8' codec can't encode character '\ud800' ..."
after E-18 (READMEs only)       : PASS: 19  WARN: 0  FAIL: 0  SKIP: 1, exit 0; suite 17 defined, 17 run, 17 passed
                                  no number moved — A.3 is not defined in this project's verify_all, and
                                  every F-class row (F.1…F.6) is a size check no README feeds
```

Both runs were invoked as `bash .harness/scripts/verify_all.sh` **from the repository root** (a
subdirectory invocation self-reports a false red — insight 2026-08-15).

**E-18's measurement, taken first-hand before either paragraph was written** (V-11's three-tag
fixture; one case per process, `bin/sc` loaded through `docs/dev-map.md`'s recipe + the exec-denial
shim, every path constant repointed into a `mkdtemp` root and asserted inside it, stdout redirected
to a file by the shell). The environment was proved in-process before any clause was credited:
`sys.stdout.encoding='ascii'`, `locale.getpreferredencoding(False)='ANSI_X3.4-1968'`,
`sys.flags.utf8_mode=0` under `LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0`. The fixture document is
written with `ensure_ascii=False` and asserted to carry non-ASCII bytes on disk.

| tag | code point | written to stdout as | exit | saved file | `json.loads(saved)` |
|---|---|---|---|---|---|
| `香港-01` | U+9999 U+6E2F — BMP, outside Latin-1 | `"\u9999\u6e2f-01"` | `0` | 267 B, complete, `uuid` = `******` | **True** — tag round-trips |
| `café-02` | U+00E9 — Latin-1 range | `"caf\xe9-02"` | `0` | 262 B, complete, `uuid` = `******` | **False** — `Invalid \escape: line 8 column 18` |
| `🚀-03` | U+1F680 — above the BMP | `"\U0001f680-03"` | `0` | 265 B, complete, `uuid` = `******` | **False** — `Invalid \escape: line 8 column 15` |

The spelling boundary was measured separately in the same environment rather than assumed:
U+0080…U+00FF → `\xNN`, U+0100…U+FFFF → `\uNNNN`, ≥ U+10000 → `\UNNNNNNNN`. HEAD's own text is the
discriminating control and **fails clause (c) on row 1** — it says the saved file is then not valid
JSON, and that file parses.

## Design drift

None.

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| C-9 | **HELD** — the codec assertion's kill is a codec **substitution**. A scratch copy carrying `read_text(encoding="latin-1")` at the `cmd_config()` read fails `every_file_read_and_write_names_utf8` (`17 defined, 17 run, 16 passed`, exit 1). Recorded additionally, as a fact and not as the credited kill: because I-5 reads the **source** rather than the behaviour, an argument **deletion** also fails it — C-9's false-kill hazard is a property of the *behavioural* codec assertion (`write_private_writes_utf8_bytes`), and the substitution stays the mutation of record for V-13(a) | `04_RATIONALE.md` `## Mutation transcript` |
| C-10 | **HELD** — `test_count` 14 → 17 and `passing_count` 14 → 17 in the same change as the three assertions; no existing assertion deleted, weakened, renamed or reordered (`git diff .harness/scripts/check-sc-contracts.py` is additive apart from the `import ast` line and the `TESTS` tuple's two appended lines). The floor equals `len(TESTS)` | B.4 PASS; `summary: 17 defined, 17 run, 17 passed` |
| C-11 | **RECORDED, no code change** — `main()` calls `_load_lang()` on **both** arms (`bin/sc:3770-3773`, post-change numbering; the `if` arm skips only `_init_files()` and `_resolve_clash_port()`), so on a present-but-unusable `settings.json` **every** command — `doctor` and `config` included — writes exactly one `⚠️  Cannot use {path}: {problem}` line. AC-4 and FR-8 are correct as written and were not "corrected"; no line was added or removed anywhere for this. The corrected fact is now also in `docs/dev-map.md`'s "Is this state document usable?" row | `docs/dev-map.md`, this row |
| C-12 | **RECORDED as a residual, no code change** — a `sc update-rules` run that aborts through `main()`'s envelope prints **no** run-level outcome line, at HEAD and after this change: the raise leaves `cmd_update_rules()` at the regeneration call (`bin/sc:3406`), which is above the outcome block (`:3425-3435`), so the comment at `:3423-3424` ("exactly one truthful run-level outcome, always, before the exit") is true of the run that reaches the tail and not of the run that aborts. No code, comment or criterion in this task was changed for it; it is owed a pool row via `07_DELIVERY.md` (T-30 family) | `bin/sc:3406` vs `:3423-3435` |

## Open issues for review

- **No committed assertion covers E-10's guard — closed as a written boundary (CR-1).** The
  undifferentiated-arm mutant (a scratch copy whose recovery arm is one `except OverrideError:` with no
  `.path` guard) leaves the suite at `17 defined, 17 run, 17 passed`, exit 0: B.4 stays green on a build
  that re-installs the defect. Per code review the disposition is **a boundary, not a fourth
  assertion** — the property is a regression guard for a **HEAD** behaviour (AC-19's own text has HEAD
  passing that row), so FR-9 / Q-11 / I-8 / E-12 fix the suite's growth at three; the only honest
  committed pin would need the suite's first **command-level** fixture with a stubbed download loop,
  which is a pool row and not a patch; and an `ast` shape assertion would pin the `if e.path !=
  SETTINGS_PATH: raise` *spelling* rather than the behaviour, reddening B.4 for the `if`/`else` form
  stage 2 priced as correct. Discharged by one clause in `docs/dev-map.md`'s "Is this state document
  usable?" row (E-13's existing ledger scope — no new row, no new file, no assertion, floor unmoved at
  17, no `bin/sc` line) stating that no committed assertion covers this arm, that B.4 stays green if it
  is collapsed, and that AC-19 / V-19 (T-29) was its only control.
- **I-6's kill surfaces as a `FileNotFoundError`, not as "no OverrideError was raised".** With FR-6's
  statement deleted, `generate_config()` runs to completion and reaches `sing-box check`, where the
  fixture's deliberately non-existent `SB_BIN` stub raises first. The assertion still FAILs (the kill is
  real and loud) but its message names the stub rather than the missing refusal. A reviewer wanting a
  cleaner diagnostic would have to add a pre-check to `_refused()`, which no ledger row authorises.
- **RES-1 stands and got closer.** `subprocess.run(..., text=True)` at `bin/sc:2157` and `:3473` is now
  the *only* locale-dependent text decode left in the file; I-5's scan is bounded away from it by K-6,
  so nothing pins it.
- The `sc config` / `sc doctor` locale repair was measured at the **read**, in a proved non-UTF-8 child
  process, against a HEAD-equivalent control; the full command-level rows (AC-9 / AC-10, and every other
  [B] row) remain stage 6's to run. Transcript in `04_RATIONALE.md`.
- **`cmd_config()`'s docstring (`bin/sc:3119-3122`) now says less than the paragraph it points at.** Its
  "`\xNN` / `\UNNNNNNNN` are not JSON escapes" is *true* and neither of AC-11's two negatives is in it,
  so nothing false ships — but it enumerates two of the three spellings, is silent on `\uNNNN`, and its
  closing "Both READMEs state the same condition" is now an understatement rather than an equality.
  `bin/sc` is frozen for this round at `+24/−9` and no ledger row authorises the line, so it is left
  exactly as it is; a one-line docstring alignment belongs with T-32's prose sweep.
- **CR-2's "every command except `sc doctor`" inaccuracy at `README*.md:124` / `:152` is untouched**, by
  instruction: it is a different paragraph, inside the frozen set, and travels to delivery as RES-3.
  Nothing in this round read, re-worded or reflowed it.

## Dev-map updates

- `# State files` row: records that `save_settings()` renders its write failure exactly as
  `save_nodes()` does — same catch family, same key, same `getattr(e, "strerror", None) or str(e)` cause
  clause — so it now raises **only** `SystemExit`, while its path, its `0644` mode and its non-atomic
  `write_text` mechanism are unchanged and it is still not a credential document.
- `# Commands` row: `cmd_config()`'s clause now reads `one read_text(encoding="utf-8")` and states that
  the codec is named rather than taken from the process locale (AC-18).
- "Is this state document usable?" utility row: gains Q-1's project-wide rule (an unusable settings
  document blocks every run that writes and blocks no run that only reports), `generate_config()`'s
  `load_settings()` call and what it refuses, `_resolve_clash_port()`'s `SystemExit` catch and its
  one-statement `try`, `cmd_update_rules()`'s `.path`-discriminating arm and the three failures that
  still reach `main()`'s envelope, and C-11's corrected fact about `_load_lang()` on both arms. It also
  carries CR-1's coverage clause: no committed assertion covers the `.path` discrimination, B.4 stays
  green if the arm is collapsed, AC-19 / V-19 was its only control, and the honest pin is a
  command-level fixture (pool row) rather than an `ast` shape check that would pin a spelling.
- Contract-suite row: "14 named assertions" → 17, the subject list gains `generate_config()`'s settings
  refusal and `save_settings`, and the row now names the `ast` source scan with its binary-mode
  admission rule.

## Insight to surface

- `json.dumps()` defaults to `ensure_ascii=True`, so a locale fixture that writes `json.dumps(doc).encode("utf-8")` puts **pure ASCII** on disk and its non-UTF-8 criterion passes identically on broken and fixed code (measured: candidate and a HEAD-equivalent control both read the document and printed the same `sc doctor` row) — only `ensure_ascii=False` puts real UTF-8 bytes there, on which the control fails with `'ascii' codec can't decode byte 0xe8`; this is the same vacuous-pass class as the `os.environ` tag transport, reached through the fixture's own writer · evidence: state-file-contract-completion
- `backslashreplace` has **three** spellings and the BMP one is JSON-legal, so "a non-UTF-8 stdout escapes the output, therefore the redirected file is not valid JSON" is **false for exactly the CJK document this project's locale criteria mandate**: measured under `LC_ALL=C PYTHONUTF8=0`, `sc config` exits 0 for all three of `香港-01` / `café-02` / `🚀-03`, writing `\u9999\u6e2f` / `\xe9` / `\U0001f680`, and `json.loads` **succeeds** on the first saved file and fails on the other two (boundary: U+0080…U+00FF → `\xNN`, U+0100…U+FFFF → `\uNNNN`, ≥ U+10000 → `\UNNNNNNNN`) · evidence: README.md:297, README.zh-CN.md:297

## Verdict

READY FOR REVIEW
