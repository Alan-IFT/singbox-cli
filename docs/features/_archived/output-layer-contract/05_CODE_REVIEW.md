> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

# T-25 — output-layer-contract · Code Review

## Files reviewed
- `/home/alan/Programs/singbox-cli/bin/sc`
- `/home/alan/Programs/singbox-cli/README.md`
- `/home/alan/Programs/singbox-cli/README.zh-CN.md`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` (CR-7 / C-11 record, not product code)
- `/home/alan/Programs/singbox-cli/.harness/scripts/restricted-network-regression.sh` (consumer of `OK (` / `failed: `, frozen)
- `/home/alan/Programs/singbox-cli/.harness/rules/85-design-discipline.md`, `/home/alan/Programs/singbox-cli/.harness/rules/70-doc-size.md`
- `/usr/local/bin/sc` (installed older build — read only, to rule on the round-2 safety event)

## Findings

| id | severity | axis | file:line | finding |
|---|---|---|---|---|
| CR-1 | MAJOR | Spec/design-fidelity | `bin/sc:3113`, `README.md:297`, `README.zh-CN.md:297`, `bin/sc:3102-3105` | **DISCHARGED.** Door one taken. The developer confirmed the claim by measurement rather than deferring, and found it wider (exit 0 with 269 ASCII bytes `json.loads` rejects, against HEAD's exit 1). Both published sentences now carry BC-8's condition symmetrically, clause for clause: condition → mechanism (escape, not abort) → why the escape is not JSON → remedy. The frozen-set release is used for exactly one line; `README.zh-CN.md:94`'s `sc ls` sample is untouched (numstat 1/1 confirms). The **third home** is the same sentence and not scope creep: `cmd_config`'s docstring made the identical unconditional promise ("`sc config > file` yields a JSON document a parser accepts") and now carries the identical condition, in the function whose reader is the defect — 4 prose lines, no behaviour, no new concept, and leaving it false would have been CR-2's exact class. Coupling travels as RES-6. |
| CR-2 | MINOR | Standards-conformance | `bin/sc:470-475`, `docs/dev-map.md:71` | **DISCHARGED.** The docstring no longer claims the value is printed verbatim and that no scrubbing happens in here; it states that both consumers spell the identical `_plain(_egress_ip())` (`:2456`, `:2886`) and that scrubbing belongs at the call sites. `docs/dev-map.md:71` carried the same stale premise and was corrected with it. DD-2's premise survives: `:478` still returns `resp.read().decode()`, i.e. `str` or an exception. |
| CR-3 | MINOR | Standards-conformance | `bin/sc:3151-3158`, `docs/dev-map.md:78` | **DISCHARGED.** The "this process holds no other buffered stream" clause is gone; the block now states that fd 1's `BufferedWriter` carries two wrappers (the re-wrap and the one `sys.__stdout__` keeps alive) and points at the one home. The general fact, its teardown safety and the double broken-pipe report are on the dev-map row. |
| CR-4 | MINOR | Standards-conformance | `04_DEVELOPMENT.md` DD-3 | **DISCHARGED.** DD-3 now reports **five** blocks, names `:2436-2438` (which appeared in no row at all), and gives the `#`-line share as +33/−9 against a +80/−41 diff. Re-counted in the tree: `:224-225` (2) + `:298-300` (3) + `:2436-2438` (3) + `:2444-2447` (4) + `:3697-3704` (8) = 20, exactly as filed. Rule 85's size bar now reads a true input. |
| CR-5 | MINOR | Standards-conformance | `bin/sc:3697-3704` vs `docs/dev-map.md:78` | **DISCHARGED.** 15 lines → 8: the block names the arguments and defers the five clauses to the row that owns them ("That row is the home; this is only the site"). One home, one pointer. |
| CR-6 | MINOR | Spec/design-fidelity | `bin/sc:145` | **OPEN — PM.** Unchanged by round 2 and re-verified: seven `失败` string sites (`:136, :145, :147, :148, :158, :214, :234`), of which `:136` / `:145` / `:214` carry the full-width `失败：`, and `:145` alone carries **both** load-bearing literals (`failed: ` in English, `失败：` in Chinese). D-4's pool row must name the family, not the one site. RES-5. |
| CR-7 | MINOR | Standards-conformance | `.harness/rejected-decisions.md:39` | **DISCHARGED (PM).** The record now transcribes `OK (n byte(s)); fell back after: …` and states that the noun became invariant in T-25. Corrected in place; no second record; the one-completion-line invariant is untouched. |
| CR-8 | MINOR | Spec/design-fidelity | `bin/sc:2448`, `:2451` | **OPEN — QA.** DD-2's `str()` guard still carries no measurement against a non-`str` value, which is the only case it exists for. Reading settles that it is right (`print(x)` is `write(str(x))`, and `_plain` strips no repr character); the evidence gap is RES-1. |
| CR-9 | MINOR | Standards-conformance | `docs/dev-map.md:78` | **DISCHARGED in substance.** The row now states what `backslashreplace` **costs** — it displaces the POSIX locale's `surrogateescape`, so undecodable-byte data renders `\udcXX` — and names a reachable site, so the give-up survives delivery rather than dying with the archived stage doc. RES-3 retires into the deliverable; the site list itself is CR-11. |
| CR-10 | MINOR | Spec/design-fidelity | `README.md:297`, `README.zh-CN.md:297` | **NEW.** The narrowed sentences name two causes — "a non-UTF-8 locale, or `PYTHONIOENCODING` set to a narrower codec" — and only the second is reachable through `sc config` today. Under a non-UTF-8 locale `CFG_PATH.read_text()` (`bin/sc:3113`) fails **first**: exit 1 and `cannot read …`, i.e. the run *does* end, which is what the sentence says it does not. This is the developer's own finding read the other way — `04_RATIONALE.md` §4(b) reaches that environment only in a **counterfactual** with the repair applied. Harmless in direction (the remedy named is right for both cases) and self-healing when the filed row lands. Two acceptable dispositions: narrow the parenthetical to `PYTHONIOENCODING`, or leave both sentences as written for the post-repair world and let RES-6 verify rather than rewrite them. **Developer**, non-blocking. |
| CR-11 | MINOR | Standards-conformance | `docs/dev-map.md:78` | **NEW.** "One reachable site today: the `{path}` rows `_doctor_permissions()` builds from `CFG_DIR.iterdir()`" replaces CR-9's class with a single instance and drops the class. Under the POSIX locale **every** OS byte interface decodes with `surrogateescape`, argv and `os.environ` included: `SB_RULES_BASE` (`bin/sc:1129`) reaches stdout through the cause lines at `:3346` → `:3370`, and `sc update-rules --mirror <arg>` reaches the same lines from argv. The one home should carry class **and** instance, or the next reader concludes a filename is the only route. One clause. Developer; the executable half is RES-3. |
| CR-12 | NIT | Standards-conformance | `bin/sc:3155` | "Since main()'s re-wrap that message would come TWICE" reads as though a word is missing (…re-wrap *landed*). Pure wording in a comment. Developer, do not block. |

## Requirement coverage check

| criterion | implementation | status |
|---|---|---|
| AC-1 | `bin/sc:2315-2316` + keys `:249-254`; compares against the six **words**, not "is ASCII" | ✅ (read + V-1) |
| AC-2 | `zh` values `:249-254` byte-identical, pairing verified key-by-key (`#`→序号 … `Delay`→延迟) | ✅ (read + V-2) |
| AC-3 | field widths 4/2/10/30/25/9 at `:2315-2316` vs data rows `:2323-2324`, `:2328-2329`; all six headings ≤ their field | ✅ (read + V-3) |
| AC-4 | V-4 enumeration, unchanged by round 2 (206 / 203 / 160 distinct / 0 offenders); the three undecidable sites resolve to the real `bin/sc:1067` (`_age_text`'s unit tuple) and `:2999` twice (`t(DOCTOR_MARK[cls])` **and** `t(label)` on one line) | ✅ (record, cross-checked) |
| AC-5 | `_age_text` `:1061-1068` over keys `:226-229`; 36 h → `1 day(s) ago` | ✅ (read + V-5) |
| AC-6 | population of 14 at `04_DEVELOPMENT.md` C-8, re-derived over `TRANSLATIONS` — no count phrase omitted, no fraction admitted | ✅ (read + V-6) |
| AC-7 | `bin/sc:2439-2440` (`{reason}, {age}`, key `:301`) vs `:2606` (`{reason}, {size} byte(s), {age}`, key `:294`) — same `，` / `, ` | ✅ (read + V-7) |
| AC-8 | `line_buffering=True` at `:3708`, set before `parse_args()` (`:3709` builds the parser); subparser `-h` is inside the guarantee | ✅ (record, V-8) |
| AC-9 | `errors="backslashreplace"` at `:3707`; proof recorded (`encoding=ascii`, `ANSI_X3.4-1968`, `PYTHONUTF8=0`) | ✅ (record, V-9) |
| AC-10 | same statement; K-11 misalignment accepted, no glyph claim | ✅ (record, V-10) |
| AC-11 | C-7 census, 104 forms/language; round 2 touched **no** rendered string (the four edited regions are docstring/comment tokens), re-verified in the tree: `OK (` intact at `:213`, `failed: {e}` intact at `:214`, both still counted by `restricted-network-regression.sh:284` | ✅ (independently checked) |
| AC-12 | `:2451` (`sc status` half) + re-pointed egress class `:2456` ≡ `_doctor_egress:2886`, character-identical | ✅ with CR-8 |
| AC-13 | `:2451` prints the value and nothing else; C-4 proved the section rendered on both builds | ✅ (record, V-13) |
| AC-14 | diff confined to I-2…I-6 + FR-6 reordering; C-9 pinned the one variable line before the run; round 2 added no executable line | ✅ (record, V-14) |
| AC-15 | `README.md:93-99` re-derived from the format string at three independent column boundaries and it matches; `docs/dev-map.md:91-99` states the convention in four binding clauses and names no `ls.*` key | ✅ |
| AC-16 | `check-i18n-parity.sh` outside the dirty set; `verify_all` PASS 17 / WARN 0 / FAIL 0 / SKIP 1, the task-start baseline | ✅ (record, V-16) |

## Design fidelity check

| design item | implementation | status |
|---|---|---|
| I-1 stream statement | `bin/sc:3705-3708`, guarded, encoding preserved | ✅ (+ DD-1) |
| I-2 heading row | `bin/sc:2315-2316`, widths/gutters/order byte-identical to HEAD's shape | ✅ |
| I-3 five heading keys | `bin/sc:249-254`, values untouched, no `identifier.identifier` key left in the file | ✅ |
| I-4 age ladder | `bin/sc:226-229` + `:1064-1068`; `last update unknown` (`:230`) untouched | ✅ |
| I-5 byte family (six) | `bin/sc:213, 232, 233, 294, 296, 366`; `{done}/{total} bytes ({pct}%)` (`:231`) correctly out | ✅ |
| I-6 separator, one new entry | `bin/sc:301` + call site `:2439-2440`; `%-20s ` pad stays outside `t()` | ✅ |
| I-7 dev-map convention bullet | `docs/dev-map.md:91-99`, four binding clauses, records no defect | ✅ |
| I-8 dev-map utilities row | `docs/dev-map.md:78` + `main()` row `:42` | ✅ with CR-11 |
| L-4 four `_plain()` routes | `bin/sc:2448, 2451, 2456, 2458`; `:2456`/`:2458` character-identical to `_doctor_egress` `:2886`/`:2888` | ✅ (+ DD-2) |
| L-5 / L-6 documents | `README.md:93-99` + `:297`, `README.zh-CN.md:297`, `docs/dev-map.md` | ✅ with CR-10 |
| K-1 exactly once, first executable statement | `global` is a declaration; `:3705` is the first statement; `main()` called only at `:3781-3782` | ✅ |
| K-2 no post-3.6 API | `io.TextIOWrapper` only; no `reconfigure()` anywhere; encoding read, never forced | ✅ |
| K-3 guard | `bin/sc:3705`, `getattr(sys.stdout, "buffer", None)` | ✅ |
| K-4 stderr + existing flushes untouched | all six survive (`:1214`, `:1227`, `:3149`, `:3334`, `:3412`, stderr `:3145`), `_doctor_print`'s per-row `flush=True` pinned at `:2997`/`:2999`, no message added or moved | ✅ |
| K-9 phrases deliberately not changed | fractions, `ms` units and `matched {count} elements` all unchanged | ✅ |
| K-12 one file, one new import | `import io` at `bin/sc:8`; four product files dirty, none new | ✅ |
| Frozen set | `t()` `:481-483` unchanged; `TRANSLATIONS` still `{"zh": …}` only; `_doctor_print` unchanged; `:136` and `:214` untouched; `README.zh-CN.md:94` and `CHANGELOG.md` byte-identical; `check-i18n-parity.sh` outside the dirty set | ✅ |
| Rule 85 over-build sweep | the round **shrank**: `main()`'s block 15 → 8 lines. No `en` table, catalogue, formatter, plural helper, print wrapper, second key per phrase, new file, new function (`bin/sc`'s top-level `def`/`class` count is **113**, unchanged) or new concept. Round 2's whole product delta is prose, and each piece of it replaces a false statement | ✅ |
| T-13 / T-06 credential contract | `_write_private` remains the sole writer of `CFG_PATH` (`:2141`; every other `CFG_PATH` site is a read); `sc config`'s single `sys.stdout.write` still takes `_redact(doc, False)` (`:3147`); no credential path is on the diff | ✅ |
| DD-1 `newline="\n"` | `bin/sc:3707` | ✅ upheld — required, not merely authorised (CPython pins `\n` explicitly, so omission would have swapped it for `os.linesep`) |
| DD-2 `_plain(str(v))` | `bin/sc:2448`, `:2451` | ✅ upheld — correct totality guard; `:2456` correctly has none; evidence gap is CR-8 |
| DD-3 extra comment blocks | `bin/sc:224-225, 298-300, 2436-2438, 2444-2447, 3697-3704` | ✅ upheld, record now honest (CR-4) |
| C-6 discharge | `04_DEVELOPMENT.md` C-6 vs `README.md:297` / `README.zh-CN.md:297` / `bin/sc:3102-3105` | ✅ (CR-1 discharged; CR-10 is a clause inside the new sentence, not a re-opening) |

## Axis status
- **Standards-conformance**: 8 findings (CR-2, CR-3, CR-4, CR-5, CR-7, CR-9 discharged; CR-11 MINOR and CR-12 NIT open), worst open = MINOR. Rule 85 is satisfied and the round moved the right way — fewer lines at the site, the same 113 top-level definitions, no new concept, and every over-build shape the design named by name still absent. Logic, performance and security produced no new finding on this axis: the four edited regions tokenize as docstring and comment only (verified by reading each), `__doc__` is read **nowhere** in `bin/sc`, so a docstring edit cannot reach a rendered line, and no executable statement, key or format string moved.
- **Spec/design-fidelity**: 4 findings (CR-1 MAJOR discharged; CR-6, CR-8, CR-10 MINOR open), worst open = MINOR. Every FR/BC/AC lands in its named home; BC-8's narrowing is now published symmetrically in both READMEs and stated once more where the code makes the promise; the frozen set held; T-13/T-06 are intact.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | DD-2's `str()` guard at `bin/sc:2448`/`:2451` has no measurement against a non-`str` value; assert a JSON `mode` that is a number, a boolean and an object renders identically to HEAD. | `06_TEST_REPORT.md` |
| RES-2 | This review read the working tree and ran nothing. Two hunk-level confirmations are owed: that `bin/sc` carries no change outside L-1…L-4 plus the four round-2 comment/docstring regions, and that the developer's post-edit `sc config` capture is `cmp`-identical to the pre-edit one on the delivered tree. | `06_TEST_REPORT.md` |
| RES-3 | Named check for CR-11: under `LC_ALL=C PYTHONUTF8=0`, an `SB_RULES_BASE` value carrying an undecodable byte (`bin/sc:1129` → `:3346` → `:3370`) renders `\udcXX` on the candidate and its raw bytes on HEAD — confirming the `backslashreplace` cost has a second route and that `docs/dev-map.md:78`'s site list is complete only as a class. | `06_TEST_REPORT.md` |
| RES-4 | R-45's price rose: an un-guarded command at pipe-buffer scale now emits two extra `Exception ignored in: <_io.TextIOWrapper …>` stderr lines. R-45 stays declined; its row should carry the new cost. | `docs/tasks.md` (PM pool row) |
| RES-5 | D-4's pool row must name the `失败：` family, not one site: `bin/sc:145` collides in **both** languages, `bin/sc:136` in one. | `docs/tasks.md` (PM pool row) |
| RES-6 | The filed `cmd_config` locale-decode row (`bin/sc:3113`) must record that the two READMEs' `:297` sentences are already written for the **post-repair** world, so the repair's duty is to *verify* them (and CR-10's parenthetical becomes true at that moment) rather than to change them. | `docs/tasks.md` (PM pool row) |
| RES-7 | `docs/dev-map.md:121-158` states the loader rule and the consequence but not the **failure signature** a fresh context actually sees — a re-exec into the *installed* build whose argparse rejects the harness argv at exit 2, which reads like a harness bug rather than a safety event. One clause; PM's call whether it belongs in this task's dev-map edit or a pool row. | `docs/tasks.md` (PM pool row) |
| RES-8 | Round-2 safety-event ruling: the void run is credibly write-free and the re-taken evidence is **sound**; the decision not to file it as an insight was **right**. Reasoning and the independent check are in `05_RATIONALE.md` §3. | `PM_LOG.md` |

## Verdict
APPROVED
