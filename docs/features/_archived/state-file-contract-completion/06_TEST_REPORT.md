# T-29 · state-file-contract-completion — Test Report

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

## Test plan

Every [B] row ran one `sc` command per child process, through `docs/dev-map.md`'s mandated
loader recipe plus `check-sc-contracts.py:100-123`'s exec-denial shim, with all nine path
constants repointed and asserted inside a scratch root, `SYSTEMD = OPENRC = False`,
`_init_files()` replaced on the loaded module and `SB_BIN` a stub exiting 0. "HEAD control" is a
pristine **clone** at `3a0ba42`, never a worktree. Reproducers are session-scratchpad drivers,
not committed artifacts; the reason no committed assertion was added is in `## Defects found`
(SG-1) and the full transcripts are in `06_RATIONALE.md`.

**Re-measured after D-1's repair**, and stated row by row rather than restated wholesale:
**AC-5, AC-11, AC-14, AC-18, AC-19 were re-run in full** this round, **AC-9, AC-13, AC-17 in the
part the repair could touch**, and the remaining eleven rows (AC-1…AC-4, AC-6…AC-8, AC-10, AC-12,
AC-15, AC-16) are **carried forward** on one measured fact: the shipped `bin/sc` is byte-identical
to the file every round-1 row was measured on — `diff <(sed '3408,3410d' bin/sc)
qa/mutants/m_arm_collapsed` is **empty**, and that mutant was cut from the round-1 candidate — while
`check-sc-contracts.py`, `baseline.json` and `docs/dev-map.md` are unmodified since round 1 and the
only files that moved are two README lines and the PM's own log. A row whose subject is that file
cannot have changed; a row whose subject is a README, the gate or a document was re-run.

**Round 3 re-ran AC-14 and nothing else**, and the carry-forward is stated rather than left
implied. The only thing that moved since the round-2 measurement is the PM's compaction of
`PM_LOG.md` (550 → 203 lines), and that is measured, not accepted: repo-wide,
`find . -type f -newermt '<this report's round-2 write>'` returns **exactly three** files, all
documents — `05_CODE_REVIEW.md`, `05_RATIONALE.md`, `PM_LOG.md` — and no product file, no script
and no `docs/tasks*.md` among them; `git diff --numstat` still
reads the exact tuple round 2 measured — `bin/sc 24 9` · `check-sc-contracts.py 173 0` ·
`baseline.json 2 2` · `docs/dev-map.md 4 4` · `README.md 1 1` · `README.zh-CN.md 1 1`. **No [B]
row's subject is `PM_LOG.md`.** The one carried clause whose input any document could touch is
AC-17's `[A.1]` clause — and `A.1` is a `git grep` over **tracked** files with `':!*.md'` excluded
(`verify_all.sh:33-34`), so no Markdown file can move it; it re-ran `PASS` this round regardless.
AC-14 is the only row whose subject (the gate's verdict, F.6 included) could have moved, so it is
the only row re-run. Recorded rather than glossed: `05_CODE_REVIEW.md` and `05_RATIONALE.md` carry
mtimes 2–3 minutes **later** than this report's round-2 write; they are untracked, so no pre-image
exists to diff and I do not claim byte-identity. Their content is the round-2 content this report
already cites (RES-4 restated, RES-1/2/3 unchanged), neither is the subject of a [B] row, and both
are far under F.6's cap (92 and 169 lines).

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 refusal on an unusable `settings.json` | `ac1_2.py` — candidate + HEAD control, sha256 of `config.json` / `.config.sha256` / `settings.json` before+after, `restart_service()` reachability probe | `qa/ac1_2.py`, `qa/setup_restart_probe.py` |
| AC-2 the two differences the defect names | same driver: HEAD's regenerated document diffed against the pre-existing one, per difference, one line each | `qa/ac1_2.py` |
| AC-3 a valid settings file still takes effect | `ac3.py` — `lang: zh` / `ipv6: off` / `telemetry: allow` / port 29500, run on **both** builds and required identical | `qa/ac3.py` |
| AC-4 reporting commands unaffected | `ac4.py` (`sc doctor`, `sc ls`, both builds) + `boundaries.py`'s `m_refusal_global` control | `qa/ac4.py`, `qa/boundaries.py` |
| AC-5 `sc update-rules` keeps one outcome line (**re-run at round 2**, same driver, same result) | `ac5_19.py` with stubbed fetches, no init system, an existing configuration | `qa/ac5_19.py`, `qa/setup_stub_fetch.py` |
| AC-6 `0444` settings write failure | `ac6_7.py` — `sc mode global`, both builds | `qa/ac6_7.py` |
| AC-7 lone-surrogate write failure | `ac6_7.py` — same command, plus the `m_cause_bare_strerror` mutant | `qa/ac6_7.py`, `qa/mutants.py` |
| AC-8 the opportunistic persist stays silent | `ac8_bc.py` — `sc ls`, usable settings with no port, mode `0444`, plus the `m_persist_oserror` mutant | `qa/ac8_bc.py` |
| AC-9 `sc config` under a proved non-UTF-8 process (**re-observed at round 2** on the candidate arm — AC-11's `bmp-cjk` case is this row's fixture shape; the HEAD control was not re-run) | `ac9_10.py` — env proof taken **in the measured process** and read before any other clause | `qa/ac9_10.py`, `qa/run_case.py`, `qa11/ac11_behaviour.py` |
| AC-10 `sc doctor`'s AAAA row, same process | `ac9_10.py` | `qa/ac9_10.py` |
| AC-11 (**re-run in full** against stage 1 round 4's restated criterion) both paragraphs corrected and true, one hunk per file, (a)–(d) in each language | `ac11_behaviour.py` — three tags, one spelling each, one process per tag under a proved non-UTF-8 stdout, plus a swept codec-boundary table; `ac11_extra.py` — clause (d) under a UTF-8 stdout, a two-spelling file, an ASCII-only file; `ac11_rule.py` — each paragraph ruled against that measured table in **both** languages, with the HEAD control and an English-only control; `git diff -U0` for the blast radius. **RES-4 is discharged and retired**: byte-identity is no longer the requirement, and the git-level check it owed is now this row's one-hunk-per-file assertion, taken with git in hand | `qa11/ac11_behaviour.py`, `qa11/ac11_extra.py`, `qa11/ac11_rule.py` |
| AC-12 no locale-decided codec in the shipped file | `ac12_scan.py` — an **independent** `ast` scan written from I-4, not reused from the shipped assertion | `qa/ac12_scan.py` |
| AC-13 each new assertion has a mutation that kills it (**the `m_arm_collapsed` coverage control re-run at round 2**; the four kill mutations carried forward — their subject is the unmodified `bin/sc`) | `mutants.py` + `check-sc-contracts.py --source` once per mutation | `qa/mutants.py` |
| AC-14 `verify_all` from the repository root (**re-run at round 2, ×3 — FAILED, D-2; re-run at round 3, ×5 after the PM's compaction — PASSES**) | `bash .harness/scripts/verify_all.sh` ×5, plus the `F.6` predicate (`find` + `wc -l`) run by hand over every file the check reads, at both rounds, because the check names no file on stdout | — |
| AC-15 T-13 / T-14 preserved | whole-function identity vs `HEAD` for ten functions; `settings.json` mode after a real `save_settings()` on both builds | `qa/ac15.py`, `qa/setup_umask.py` |
| AC-16 T-06 preserved | `sys.stdout.write` census + diff of the `MASK`…`_redact` block vs `HEAD` | — |
| AC-17 no new key/file, budget held (**`git diff --numstat` and A.1 re-run at round 2**; the code/comment split and the `TRANSLATIONS` diff carried forward — `bin/sc` is unmodified) | `git diff --numstat`, code/comment split, `TRANSLATIONS` diff, A.1 | — |
| AC-18 documents true of the shipped code (**re-read in full at round 2**, clause by clause, including the eight sub-claims of `:76`'s coverage clause) | four `docs/dev-map.md` clauses read against the shipped file; repo-wide search for a bare `read_text()` claim | — |
| AC-19 the `.path` guard's only control (**re-run at round 2** — RES-1's single pin is not carried forward on anyone's word) | `ac5_19.py` — two cases × three builds (candidate, HEAD, `m_arm_collapsed`) | `qa/ac5_19.py` |

## Adversarial tests

One predicted failure per criterion, stated before the run. Cited output is ≤5 lines per row and
verbatim; full runs in `06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | the refusal fires but a stale `config.json` is still replaced, or the "no traceback" clause is satisfied by a silent swallow | `python3 qa/ac1_2.py` (NEW, mine) | **Survived** — `exit=1`; `Cannot use …/settings.json: not valid JSON (Expecting property name enclosed in double quotes: line 1 column 37 (char 36))`; `config.json UNCHANGED · .config.sha256 UNCHANGED · settings.json UNCHANGED`; `restart_service() reached: False`. HEAD control: `exit=0 · config.json REPLACED · .config.sha256 REPLACED · restart_service() reached: True` |
| AC-1 (C-8) | the two `Cannot use` lines are one bug, not two by design | same run, stderr classified | **Both observed, only the second counted** — `stderr lines carrying 'Cannot use': 2 / pre-dispatch announcements: 1 / REFUSAL sentences counted by AC-1: 1` |
| AC-2 | only one of the two differences reproduces, or neither does — leaving the row NOT-DISCRIMINATING | same run, per-difference assertion | **Both reproduced** — `telemetry NXDOMAIN rules: pre-existing=0 regenerated=1 -> REPRODUCED`; `clash external_controller: '127.0.0.1:29500' -> '127.0.0.1:29091' -> REPRODUCED`; candidate: `config.json byte-identical to the pre-existing one` |
| AC-3 | FR-6's new `load_settings()` refuses, or perturbs, a run whose settings are perfectly usable | `python3 qa/ac3.py` (NEW) | **Survived, and identical on both builds** — `exit=0 · out 已重新加载`; `telemetry rejection rules present: 0`; `dns.rules[0] == _aaaa_rule(True): True`; `external_controller '127.0.0.1:29500'`; `record == sha256(file bytes): True` |
| AC-4 (C-11) | `sc doctor` writes **zero** warning lines because it takes `main()`'s read-only arm | `python3 qa/ac4.py` (NEW) | **Survived; C-11 is right** — `sc doctor exit=1 · rows=20 · last section 'file permissions' present · warning lines naming settings.json: 1 · Traceback: False`; `sc ls exit=0 · node rows=1 · warning lines: 1` |
| AC-4 control | a build that made the refusal global would still pass | `--source qa/mutants/m_refusal_global` | **Discriminates** — `MUTANT global sc doctor exit=1 rows=0 Traceback=True`; `MUTANT global sc ls exit=1 node rows=0 Traceback=True` |
| AC-5 | the refusal costs `sc update-rules` its one-outcome contract — zero outcome lines, or two | `python3 qa/ac5_19.py` (NEW) | **Survived** — `exit=1`; `Rule-sets updated: … — the sing-box service was not touched`; `run-level outcome lines: 1`; `'Rule-sets restored … regenerated': 0`; HEAD control `exit=0` with the restore line and a replaced `config.json` |
| AC-6 | the renderer never fires because `write_text` on a `0444` file succeeds for the owner | `python3 qa/ac6_7.py` (NEW) | **Survived** — `Could not write …/settings.json: Permission denied`, `exit=1`, no `Traceback`. HEAD control: `PermissionError: [Errno 13] Permission denied: '…/settings.json'` as a traceback |
| AC-7 | the cause clause is empty for an exception carrying no `strerror`, or the handler raises inside itself | same driver, plus `m_cause_bare_strerror` | **Survived** — `Could not write …/settings.json: 'utf-8' codec can't encode character '\ud800' in position 99: surrogates not allowed`. HEAD: `UnicodeEncodeError … ` traceback. Mutant: `AttributeError: 'UnicodeEncodeError' object has no attribute 'strerror'` — the hypothesis is real, the shipped clause defeats it |
| AC-8 | E-7 turned the opportunistic persist into a fatal exit, so a read-only host loses a reporting command | `python3 qa/ac8_bc.py` (NEW) | **Survived** — candidate `exit=0 · node rows=1 · 'Could not write' sentences=0 · settings.json byte-identical`. Control (the mutant keeping `except OSError:`) **FAILs**: `exit=1 · node rows=0 · Could not write …: Permission denied`. HEAD also passes and is **not** the control |
| AC-9 | the environment is silently UTF-8 (PEP 540) and the whole row certifies nothing | `python3 qa/ac9_10.py` (NEW), proof read before crediting | **Environment proved** — `LC_ALL='C' PYTHONUTF8='0' PYTHONCOERCECLOCALE='0'`; `sys.stdout.encoding='ascii'`; `locale.getpreferredencoding(False)='ANSI_X3.4-1968'`; `sys.flags.utf8_mode=0`; `NON_UTF8_PROVED=True` |
| AC-9 | …and, once proved, that the document on disk is pure ASCII so both builds behave alike | same driver, fixture asserted first | **Survived** — `config.json is 4677 bytes, 48 of them non-ASCII`; candidate `exit=0`, stdout carries the tag as an escape `"\\u9999\\u6e2f\\u8282\\u70b9-01",` and no raw CJK byte, mask present, `'cannot read' sentences: 0`. HEAD: `exit=1 · cannot read …/config.json: 'ascii' codec can't decode byte 0xe9 in position 2908` |
| AC-10 | the AAAA row reads UNKNOWN on the candidate too, because the probe has a second reader | same driver | **Survived** — candidate `[OK] IPv6 (AAAA): AAAA queries are answered empty (setting: auto …); config.json carries this decision`. HEAD: `[UNKNOWN] IPv6 (AAAA): cannot read …/config.json: 'ascii' codec can't decode byte 0xe9 …` |
| AC-11 (blast radius) | the correction spilled — a second hunk, a reflow, or CR-2's `:124` / `:152` paragraph quietly repaired while the file was open | `git diff -U0 README.md README.zh-CN.md`; `diff` count vs `HEAD`; sha256 of `:124` / `:152` per file; `git diff --numstat bin/sc` | **Survived** — `@@ -297 +297 @@` and nothing else in each file, `1` changed line per file; `README.md:124 HEAD=93e2494efc53 worktree=93e2494efc53 same=yes` (and `:152`, and both zh lines); the inaccuracy is still there, still unrepaired, still RES-3's; `bin/sc 24 9` |
| AC-11 (a)(b)(c) | the corrected paragraph is still false — D-1's repair fixed the CJK row and broke the other two, or the run no longer reaches stdout whole | `python3 qa11/ac11_behaviour.py` (NEW, mine; tags built from source escapes **inside** the file, never through `argv` or `os.environ`) | **Survived** — `bmp-cjk exit=0 spelling=['u'] valid JSON=True whole document=True`; `latin1 exit=0 spelling=['x'] valid JSON=False whole document=True`; `astral exit=0 spelling=['U'] valid JSON=False whole document=True`; proof first: `stdout.encoding='ascii' getpreferredencoding='ANSI_X3.4-1968' utf8_mode=0` |
| AC-11 (b) as a codec claim | the three-way boundary is an artefact of three lucky tags, not of `backslashreplace` | same driver's sweep over 8 835 code points | **Survived, boundary exact** — `x : U+0080 … U+00FF`; `u : U+0100 … U+FFFF`; `U : U+10000 … U+10FFFF`; edges `U+0007F -> '\x7f'` (unescaped), `U+00080 -> '\\x80'`, `U+10000 -> '\\U00010000'`. Independently reproduces stage 4 round 3's table |
| AC-11 (c) per **file**, not per character | a document carrying **both** a `\xNN` and a `\uNNNN` escape parses anyway, so "a file carrying either other spelling is not [valid JSON]" is too strong | `python3 qa11/ac11_extra.py` P2 (NEW) — one tag `café香港-04` | **Survived** — `escapes present: ['\\xNN', '\\uNNNN']`; `tag line: "tag": "caf\xe9\u9999\u6e2f-04",`; `json.loads valid=False Invalid \escape: line 8 column 18`. The claim is a per-file claim and holds as one |
| AC-11 (d) | the UTF-8 escape hatch the paragraph promises is a claim about the saved file that nothing verifies — negative 2's own prohibition | `python3 qa11/ac11_extra.py` P1 (NEW) — the same three tags, `LC_ALL=C.UTF-8 PYTHONUTF8=1` | **Survived** — `stdout.encoding='utf-8'`; all three `exit=0 escapes present: none`, `json.loads valid=True`, `decoded == expected masked document: True`, `tag read back raw: True` |
| AC-11 (neg-1) | the paragraph still reads as "a non-UTF-8 stdout invalidates the saved file", irrespective of the character | `python3 qa11/ac11_extra.py` P3 (NEW) — an ASCII-only document, same proved non-UTF-8 stdout | **Survived** — `NON_UTF8_PROVED=True`, `exit=0 escapes present: none`, `json.loads valid=True`. Escaping is a property of the character, and both paragraphs now say so |
| AC-11 (both languages) | the correction landed in English only — the project's language policy puts human-facing docs in Chinese and a half-corrected pair still ships a falsehood | `python3 qa11/ac11_rule.py` (NEW) — (a)–(d) + neg-1 checked per language against the **measured** table, three builds | **Survived, and both controls FAIL as required** — `worktree (candidate): PASS` (en and zh each name `['\\xNN', '\\uNNNN', '\\UNNNNNNNN']`); `HEAD (control): FAIL` — 11 clauses en / 10 zh, `FAIL (c) only \uNNNN is a JSON escape`; `english-only (control): FAIL` — 10 clauses, all `[zh]` |
| AC-12 | a site the shipped assertion classifies as "binary" or "unseen" is really an unguarded text read | `python3 qa/ac12_scan.py` (NEW, written from I-4, not from the shipped scanner) | **Survived** — `text sites naming utf-8 : 8 / binary sites admitted : 5 / offending sites : 0`; `json.load(s) over read_bytes(): []`. HEAD control on the same scanner: `offending sites : 6` |
| AC-13 | a new assertion is killed by no mutation, or one mutation kills a neighbour | `check-sc-contracts.py --source qa/mutants/<m>` ×7 | **Survived** — `m_codec_latin1 → FAIL every_file_read_and_write_names_utf8`, `m_fr6_deleted → FAIL unusable_settings_refuses_regeneration`, `m_cause_bare_strerror → FAIL settings_write_failure_is_a_sentence`, each `17 defined, 17 run, 16 passed  exit=1` — exactly one kill apiece |
| AC-13 (C-9) | the codec **deletion** is credited as a kill | `--source qa/mutants/m_codec_deleted` | **Recorded as a fact, not credited** — `FAIL every_file_read_and_write_names_utf8  17 defined, 17 run, 16 passed`. I-5 is a *source scan*, so deletion is visible to it; C-9's false-kill hazard belongs to the *behavioural* assertion. The substitution stays the kill of record |
| AC-14 (round 2) | the pool baseline moved, or a subdirectory invocation is quietly accepted as evidence | `bash .harness/scripts/verify_all.sh` from the repository root, ×3 | **FAILED — the baseline did move.** `PASS: 18  WARN: 1  FAIL: 0  SKIP: 1`, **exit 1**, three times, from the repository root; `[F.6] Active task docs <=500 lines each ... WARN`. AC-14's text requires `PASS 19 / WARN 0 / FAIL 0 / SKIP 1` and exit 0. `[B.4] bin/sc contract assertions ... PASS` and the suite is `17 defined, 17 run, 17 passed` — the product half is green. Filed **D-2** |
| AC-14 (round 3, after the PM's compaction) | the gate is green for the wrong reason: F.6's 347 dropped `PM_LOG.md` lines were *moved* into another file under `docs/features/`, so the per-file cap is met while a second file now sits at the edge — or a check went `SKIP` and the summary reads 19 by degradation, not by repair | `bash .harness/scripts/verify_all.sh` from the repository root, ×5 (mine, this round), + F.6's `find`/`wc -l` predicate by hand over **all 13** files it reads, + `find . -newermt` repo-wide | **Survived — the hypothesis is refuted on its own terms.** Five consecutive runs, four verbatim Summary lines each: `  PASS: 19` / `  WARN: 0` / `  FAIL: 0` / `  SKIP: 1`, **exit 0**; `[F.6] Active task docs <=500 lines each ... PASS`. `SKIP` is still 1 (`[B.3] Lint ... SKIP`, the pool's standing skip), so 18 → 19 is F.6 flipping WARN → PASS, not a degradation. By hand: the largest of the 13 files F.6 reads is **`06_RATIONALE.md` at 496**, then `01_RATIONALE.md` 266, `PM_LOG.md` **203** — nothing over 500, and no file in the tree other than `PM_LOG.md` was written at compaction time, so the 347 lines were dropped, not relocated |
| AC-15 | `save_settings()`'s rewrite moved `settings.json`'s mode or mechanism | `python3 qa/ac15.py` (NEW), umask 022, both builds | **Survived** — `sc lang zh (creates) candidate mode=0o644 · HEAD mode=0o644`; `sc lang en (rewrites) candidate 0o644 · HEAD 0o644`; `_write_private` / `_config_digest` / `_record_generated` byte-identical to `HEAD`; no `chmod` on `SETTINGS_PATH` anywhere |
| AC-16 | E-4's codec argument opened a second stdout write or moved a key set | `sys.stdout.write` census + block diff vs `HEAD` | **Survived** — `bin/sc:1218`, `:1231` (both inside `_fetch_to_temp`'s progress meter) and `:3164`; `cmd_config()` has exactly one, argument through `_redact()`; `MASK`…`_redact` block diff vs `HEAD`: empty |
| AC-17 | a translation key or a line crept in past K-11 | `git diff --numstat`, code/comment split, `TRANSLATIONS` diff | **Survived** — `bin/sc 24 9`; `added code lines: 19  added comment-only lines: 5`; `TRANSLATIONS` diff empty; no new file; `[A.1] No hardcoded secrets ... PASS` with this task's documents present |
| AC-18 (**re-read in full at round 2**) | stage 4 round 2's coverage clause at `docs/dev-map.md:76` is prose no one checked line by line — one of its eight sub-claims is wrong about the shipped file | the four clauses vs the shipped file, plus each sub-claim of `:76` against a named line | **Survived** — `generate_config()` calls `_load_override()`:2064 → `load_settings()`:2074 → `load_nodes()`:2075 ("after the override wrapper, before `load_nodes()`" ✓); `_resolve_clash_port()` `try`:449 holds **one** statement `save_settings(settings)`:450, `except SystemExit`:452 ✓; the FR-7 comment is at `bin/sc:3408` ✓ and states scope, not coverage ✓; `m_arm_collapsed` → `17 defined, 17 run, 17 passed`, exit 0 ✓; `:87`'s "17 named assertions" = `--list \| wc -l` = 17 ✓ |
| AC-19 (RES-1, **re-run at round 2**) | the `.path` guard is decoration — a collapsed arm passes this row too, in which case the row is NOT-DISCRIMINATING and pins nothing | `python3 qa/ac5_19.py` ×2 cases ×3 builds | **Survived, and the mutant FAILS as required** — candidate: `Cannot use …/override.json: not valid JSON (Expecting value: line 1 column 11 (char 10))` / `Cannot use …/nodes.json: the top level must be a JSON object`, `exit=1`, `outcome lines=0`. `m_arm_collapsed`: `sentences naming the document = 0`, `outcome lines=1`, exit 1 — the collapsed build is killed by this row and by nothing else |
| AC-19 (CR-1, **re-run at round 2**) | B.4 catches the collapse, so the boundary in `docs/dev-map.md:76` overstates the gap | `check-sc-contracts.py --source qa/mutants/m_arm_collapsed` | **The boundary is exact** — `17 defined, 17 run, 17 passed`, exit 0. AC-19 / V-19 is the guard's only control and this stage-6 run is that control |

## Boundary tests added

- `settings.json` **zero bytes** and **whitespace only** (BC-2): both unusable — `sc reload`
  exits 1 with `not valid JSON (… line 1 column 1 (char 0))` and writes no `config.json`;
  `sc ls` exits 0 and prints its rows.
- `settings.json` valid JSON but `null`, `42`, `"rule"` and `[]` (BC-3): all four unusable with
  the fixed sentence `the top level must be a JSON object`; regenerating runs refuse, reporting
  runs work, no `config.json` written in any of the eight runs.
- `settings.json` as **UTF-16** and carrying an **invalid UTF-8 byte** (BC-7, BC-8): both
  reported as `not valid UTF-8 text` — a *read* failure, never a JSON failure — so the clause
  order `OSError` → `UnicodeDecodeError` → `ValueError` is exercised in the direction that
  matters.
- `settings.json` with **unrecognised values** for two keys (BC-4): usable — one notice per
  accessor (`ipv6 must be one of on / off / auto — using auto`,
  `telemetry must be block or allow — using block`), regeneration proceeds, exit 0.
- **Lone surrogate** reaching the writer (BC-6): sentence + non-zero exit, and the truncated
  document BC-5 predicts was observed first-hand afterwards.
- **Absent** `settings.json` (BC-1): no warning line, no refusal, exit 0, defaults applied. The
  *seeding* half of BC-1 belongs to `_init_files()`, which K-8 / NFR-5 forbid driving; it is
  reported as not measurable under the mandated fixture rather than approximated.
- **Node-store write already performed** (BC-13): after a refusing `sc use n1`, `nodes.json`
  `active` is `'n1'` and `config.json` was not written — the refusal stops the configuration
  being replaced without unwinding the command.
- **Hot switch on an unusable document** (BC-14): reproduced only by stubbing the *gate*
  (`is_running()` reads `SYSTEMD`/`OPENRC`, not the Clash API, and is hard `False` with neither),
  after which `exit=0`, `PUT /proxies/proxy` issued, `reload_or_restart()` never reached.
- **Unicode on the output path**: a CJK tag, a Latin-1 tag and an astral tag, each measured under
  a proved non-UTF-8 stdout; all three exit 0 and all three escape rather than end the run.
- **The escape boundary itself**, swept rather than sampled: 8 835 code points through
  `backslashreplace` — `\xNN` over exactly U+0080…U+00FF, `\uNNNN` over exactly U+0100…U+FFFF,
  `\UNNNNNNNN` at and above U+10000, and U+007F unescaped.
- **Two escape spellings in one saved file** (a tag holding a Latin-1 *and* a CJK character):
  both spellings appear and the file does not parse — AC-11 clause (c) is a per-file claim.
- **An ASCII-only document under the same proved non-UTF-8 stdout**: no escape at all, file
  parses. The vacuity control for "escaping is decided by the character, not by the locale".
- **The same three tags under a UTF-8 stdout**: zero escapes, all three parse, and each tag
  reads back as the original character — clause (d) measured rather than asserted.
- **Concurrent access**: 12 parallel `sc reload` runs against one fixture holding `[]` — all 12
  exit 1, all 12 write the refusal sentence, `config.json` / `.config.sha256` / `settings.json`
  all byte-identical afterwards, no traceback.

## verify_all result

- Command: `bash /home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh`, from the repository root
- Result at **round 3** (verbatim Summary lines): `  PASS: 19` / `  WARN: 0` / `  FAIL: 0` /
  `  SKIP: 1`, **exit 0**, five consecutive runs — the last over the delivered tree itself
- The one SKIP (verbatim): `[B.3] Lint ... SKIP` — the pool's standing skip, unchanged at every
  round. `SKIP` did not move, so round 2's 18 → round 3's 19 is one check flipping WARN → PASS
- F.6 (verbatim): `[F.6] Active task docs <=500 lines each ... PASS`. `step()` prints a detail line
  for `FAIL` only (`verify_all.sh:19`), so a re-run of F.6's own predicate by hand
  (`find docs/features -type f \( -name 'PM_LOG.md' -o -name '0[1-7]_*.md' \)` minus `/_archived/`,
  `wc -l`, cap 500 — `verify_all.sh:250-258`) is the only way to see *which* files it read: **13
  files, all under the cap**. Largest first: `06_RATIONALE.md` 496 · `01_RATIONALE.md` 266 ·
  `02_SOLUTION_DESIGN.md` 240 · `01_REQUIREMENT_ANALYSIS.md` 221 · `PM_LOG.md` **203** ·
  `03_RATIONALE.md` 201 · `02_RATIONALE.md` 194 · `06_TEST_REPORT.md` 220 · `04_RATIONALE.md` 169 ·
  `05_RATIONALE.md` 169 · `04_DEVELOPMENT.md` 164 · `05_CODE_REVIEW.md` 92 · `03_GATE_REVIEW.md` 57.
  My own `06_RATIONALE.md` is the closest to the cap and stays under it: round 3's addition was paid
  for by compacting round-1 prose in the same file, never by crossing 500
- B.4 line at round 3 (verbatim): `[B.4] bin/sc contract assertions ... PASS`
- Contract suite direct run: `summary: 17 defined, 17 run, 17 passed` (exit 0)
- Pool baseline claimed at dispatch: PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0 — **matched at
  round 3**. Round 2 read `PASS: 18  WARN: 1  FAIL: 0  SKIP: 1`, exit 1, three consecutive runs
  (`[F.6] … WARN`, `PM_LOG.md` at 550 lines): that was D-2, now closed by the PM's compaction and
  re-measured green here rather than accepted on report
- Total tests: 14 → 17 (raised by the developer in this change; `len(TESTS)` = 17)
- Pass: 17 · Fail: 0 · Warn: 0 (the contract suite; the gate itself now carries no WARN at all)
- New tests added at stage 6: 0 committed (reason in SG-1); 12 uncommitted stage-6 drivers
  (9 from round 1, 3 written for round 2) and 7 scratch mutants. Round 3 loaded no `sc` module and
  started no fixture process — its one criterion is the gate's own verdict — so it added none
- Baseline updated: no — `baseline.json` `test_count` = `passing_count` = 17 = `len(TESTS)`, already correct and never lowered; the floor (17) was not touched at any round
- Live service witness, re-taken at round 3: `MainPID=2566751 / NRestarts=0 / ActiveState=active /
  ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` — bit-identical to rounds 1 and 2
  (`systemctl show`, never `is-active`)
- `/etc/sing-box` and `/var/lib/sing-box`, re-listed at round 3: newest entry `2026-08-11 12:13`
  (`/var/lib/sing-box` `2026-07-30 12:59`); every mtime predates this session, nothing created,
  modified or removed. No credential byte was printed at any round

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| D-1 | MAJOR — **accepted, corrected, re-measured PASS at round 2** | `sc config` on a `config.json` carrying a **BMP non-ASCII** node tag, under `LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0`, redirected to a file: the run exits 0, writes `"\\u9999\\u6e2f-01",` — and the saved file **is** valid JSON, contradicting the paragraph's "so the saved file is then **not** valid JSON". Reproducer unchanged and re-run this round (`qa11/ac11_behaviour.py`): `bmp-cjk → valid JSON True`, `latin1 → False`, `astral → False`. **Disposition**: stage 1 round 4 restated AC-11 (four behavioural assertions, two negatives), stage 2 round 3 added E-18 and amended V-11, stage 4 round 3 wrote one hunk per README. Re-ruled against the corrected paragraphs in **both** languages, with HEAD and an English-only build as controls — both controls FAIL, the candidate PASSes. **Closed.** Nothing about it travels to delivery | `README.md:297`, `README.zh-CN.md:297` (subject: `bin/sc:3130` + `:3731`) |
| D-2 | CRITICAL — **closed at round 3, re-measured green, nothing travels to delivery** | Round 2, `bash /home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` from the repository root: `PASS: 18  WARN: 1  FAIL: 0  SKIP: 1`, **exit 1**, three consecutive runs; the single WARN `[F.6] Active task docs <=500 lines each ... WARN`, whose predicate re-run by hand named `PM_LOG.md` at 550 lines (cap 500) and nothing else. AC-14 requires `PASS 19 / WARN 0 / FAIL 0 / SKIP 1` and **exit 0**, so the criterion failed and the project's red line ("not done until `verify_all` PASSes") was not met. No product code was ever implicated: `bin/sc` byte-identical to the round-1 candidate, B.4 PASS, suite 17/17/17. **I did not fix it and did not try** — `.harness/rules/70-doc-size.md` Rule 2 makes PM_LOG compaction PM-owned and forbids delegating it to an agent reading the file — so it was routed. **What closed it, and by whom**: the **PM**, at a stage boundary, per that same Rule 2, compacted stages 1–4 to one-line summaries under `## Compacted stages 1..4 (2026-08-16)` and kept stages 5–6 full; `PM_LOG.md` is **203** lines. **Verified by me, not accepted on report**: same command, same directory, ×5 → `PASS: 19  WARN: 0  FAIL: 0  SKIP: 1`, exit 0, `[F.6] … PASS`, `SKIP` still 1; F.6's predicate by hand shows all 13 files under the cap. Nothing in `verify_all.sh` or its checks was modified at any round — `verify_all.sh` mtime `2026-08-16 03:32`, older than every artefact of this task | `docs/features/state-file-contract-completion/PM_LOG.md` (was 550 lines; now 203; cap 500) |
| SG-1 | schema gap (not a product defect) | Three travelling residuals fit no declared section of this report's schema, so they are recorded here per `.harness/rules/70-doc-size.md` `## Stage-doc boundary rule` rather than in an invented section. **(a)** `m_persist_oserror` (FR-5's silent persist re-broken) and `m_refusal_global` (FR-8's degrade turned into a global refusal) each leave the contract suite at `17 defined, 17 run, 17 passed`, exit 0 — the same shape as CR-1's finding and the same cure, so they belong on **RES-2**'s pool row (the suite's first command-level fixture) rather than on two new rows. **(b)** `docs/tasks.md:228`'s pool row R-76 still asserts "`bin/sc:3113` has no `encoding=`", which this change makes false; closing it is stage 7's, and `docs/tasks.md` is outside this stage's edit scope. **(c)** **RES-4 is retired, not carried.** It routed a *byte-identity* check to this report; stage 1 round 4 replaced byte-identity with "corrected and true, one hunk per file", so the residual as worded is obsolete and would mislead delivery into looking for an identity that must **not** hold. What it actually owed — a git-level check, which stage 5 had no git for — is discharged in the AC-11 blast-radius row: `@@ -297 +297 @@` and nothing else per file, one changed line per file, `bin/sc 24 9`. Delivery should carry nothing under RES-4; **RES-1, RES-2 and RES-3 are unchanged** and RES-3 was re-witnessed intact this round. Destination given: this section, as the schema's only place for a unit a later stage must act on | `docs/dev-map.md:76`; `docs/tasks.md:228`; `05_CODE_REVIEW.md` RES-4 |

No committed assertion was added at this stage and the floor was not moved: `02_SOLUTION_DESIGN.md`
FR-9 / Q-11 / I-8 / E-12 fix this task's suite growth at exactly three, `05_CODE_REVIEW.md` ruled
the missing pin a pool row and not a patch (RES-2), and no criterion I ran needed an extension of
`check-sc-contracts.py` to discriminate.

## Stability

- `verify_all` run **5 times** from the repository root at round 3: `PASS: 19 / WARN: 0 / FAIL: 0 /
  SKIP: 1`, exit 0, all five times, every one of the 21 check lines identical run to run. No flake.
- The full history of that one command, so the green is read against its own record rather than in
  isolation: round 1 `19/0/0/1` exit 0 ×3 → round 2 `18/1/0/1` exit 1 ×3 (deterministic, not a
  flake — D-2) → round 3 `19/0/0/1` exit 0 ×5. The only check that ever moved is F.6, and the only
  input that ever moved under it is `PM_LOG.md`'s line count (550 → 203).
- `check-sc-contracts.py` run 10 times: `summary: 17 defined, 17 run, 17 passed` all 10 times.
  No flakes.
- Six discriminating [B] outcomes repeated 10× each (AC-1 candidate, AC-1 HEAD control, AC-19
  candidate, AC-19 collapse mutant, AC-9 candidate, AC-9 HEAD control), each reduced to a tuple
  of its load-bearing clauses: every one produced **1 distinct outcome in 10 runs**. No flakes
  observed, none named.
- AC-11's three-tag measurement repeated **10×** at round 2 (30 child processes), reduced to
  the tuple of exit status, spelling and JSON validity per tag: `10` identical outcomes,
  `1` distinct. The corrected paragraphs' ruling and the two controls were re-run 3× with
  identical verdicts. No flakes.
- The only run-to-run variation seen anywhere was the probed Clash port on the HEAD control
  (`29091` rather than `29090`, because another process on this host holds `29090`). Both values are inside
  `[29090, 29190)` and therefore differ from the fixture's recorded `29500`, which is the only
  property AC-2's clause rests on; recorded so a re-run reading `29090` is not mistaken for a
  change.

## Verdict

APPROVED FOR DELIVERY
