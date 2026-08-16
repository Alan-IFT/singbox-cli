> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `/home/alan/Programs/singbox-cli/README.md`
- `/home/alan/Programs/singbox-cli/README.zh-CN.md`
- `/home/alan/Programs/singbox-cli/bin/sc`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py`
- `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json`
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`

## Findings

| id | severity | axis | file:line | finding |
|---|---|---|---|---|
| CR-1 | MINOR — **discharged** | Standards-conformance | `docs/dev-map.md:76` (subject: `bin/sc:3405-3411`) | E-10's `.path` guard is pinned by no committed assertion; ruled a **written boundary, not a fourth assertion**. The clause landed: `:76` now states that no committed assertion covers the discrimination, that the suite still reports 17/17/17 if the arm is collapsed, that AC-19 / V-19 was its only control, that the honest pin is a command-level fixture (pool row) and that an `ast` shape check would pin a spelling. No new row, no assertion, floor unmoved at 17, no `bin/sc` line. RES-1 and RES-2 still carry the stage-6 and pool duties. |
| CR-2 | MINOR | Standards-conformance | `README.md:124`, `README.md:152`, `README.zh-CN.md:124`, `README.zh-CN.md:152` | "like every command except `sc doctor`, it still runs the ordinary start-up path first" / "和除 `sc doctor` 以外的所有子命令一样" names a one-command exception set; `bin/sc:3769` has read `("doctor", "config")` since T-06. **Pre-existing, and verified untouched this round** — all four sentences still carry HEAD's wording at HEAD's line numbers, which is what K-12's freeze requires. No edit is owed in this task. Carried as RES-3. |
| CR-3 | NIT | Standards-conformance | `.harness/scripts/check-sc-contracts.py:484` | I-6's fixture uses `"password": "pw"`, deviating from P-7's advice ("use no credential-shaped literal at all"). Not a real credential (NFR-7 holds), 2 characters against the file's own ≤7 bound, and it copies the house fixture at `:286` — but `verify_all` A.1 does not scan `.harness/*`, so the artifact is the only guard. |
| CR-4 | NIT | Standards-conformance | `.harness/scripts/check-sc-contracts.py:458` | I-5 looks `encoding` up as a keyword only, so a future *correct* site spelling it positionally (`open(p, "r", -1, "utf-8")`) is reported as an offender. Fails closed, never open; the message names the site. |
| CR-5 | NIT | Standards-conformance | `.harness/scripts/check-sc-contracts.py:405-413` | The bytes-to-parser clause matches only a `read_bytes()` call syntactically nested inside `json.load(s)`; a two-statement form, or `json.load(open(p, "rb"))`, evades it. I-4 and the docstring both say "directly", so no document overclaims, and no shipped site violates BC-7. |
| CR-6 | NIT | Standards-conformance | `.harness/scripts/check-sc-contracts.py:526-528` | `settings_write_failure_is_a_sentence` repoints `sc.SETTINGS_PATH` outside `fixture()`'s `PATHS` table and never restores it. Harmless today — it is last in `TESTS` — but an assertion appended after it that does not call `fixture()` first would inherit a stale path. |
| CR-7 | MINOR | Standards-conformance | `bin/sc:3119-3122` | `cmd_config()`'s docstring enumerates **two** of the three spellings ("`\xNN` / `\UNNNNNNNN` are not JSON escapes"), is silent on `\uNNNN`, and closes "Both READMEs state the same condition" — now an understatement rather than an equality, since both READMEs carry the full three-way rule. **Ruled: acceptable to ship.** Nothing false is stated (both named spellings genuinely are not JSON escapes; the "holds for a stdout whose encoding can represent the document" clause is a *sufficient* condition, not an exclusive one), it draws **no** conclusion about the saved file, so neither AC-11 negative is engaged, and it points the source-only reader at the corrected paragraphs. Correcting it costs a `bin/sc` line no ledger row authorises and moves the measured `+24/−9` that NFR-1 / K-11 / AC-17 / V-17 all cite. Disclosed by the developer rather than fixed quietly, which is the right disposition; carried as RES-5 to T-32. |
| CR-8 | NIT | Standards-conformance | `README.md:297`, `README.zh-CN.md:297` | Each paragraph's opening clause keeps HEAD's hedge — "whenever stdout's encoding can represent that document" / "只要标准输出的编码表示得了这份文档" — which a hurried reader may take as an *only-when*. **Ruled: not a violation of AC-11's first negative.** It states a sufficient condition, the very next two sentences state the exact three-way rule that bounds it, and both languages hedge identically, so the two paragraphs stay fact-for-fact equal. Pure preference; recorded so a later reader does not mistake the retained clause for an oversight. |

## Requirement coverage check

| criterion | implementation | status |
|---|---|---|
| AC-1 | `bin/sc:2074` (refusal before composition) → `:3786-3803` (envelope); `:2149` / `:1994` unreached | ✅ code present; [B] observation owed to stage 6 |
| AC-2 | same site; the candidate emits no document because the raise precedes `_compose()` at `:2100` | ✅ code present; [B] control owed to stage 6 |
| AC-3 | `load_settings()` at `:2074` returns the document unchanged on a usable file; `_dns_overlay` / `_telemetry_overlay` / `_saved_clash_port` untouched | ✅ code present; [B] owed to stage 6 |
| AC-4 | `:3769-3773` (`_load_lang()` on both arms) + `:603-613` degrade; no reporting command reaches `generate_config()` | ✅ code present; [B] owed to stage 6 |
| AC-5 | `:3405-3411` (`regen_ok = False`) → `:3421-3440` (one outcome line, one exit site) | ✅ code present; [B] owed to stage 6 |
| AC-6 | `bin/sc:616-623` — `except (OSError, ValueError)` → `sys.exit(t("Could not write {path}: {err}"))` | ✅ code present; [B] owed to stage 6 |
| AC-7 | same site; cause clause `getattr(e, "strerror", None) or str(e)` (`:623`) cannot raise inside the handler | ✅ code present; [B] owed to stage 6 |
| AC-8 | `:449-453` — `except SystemExit: pass`, `try` holding exactly one statement | ✅ code present; [B] owed to stage 6 |
| AC-9 | `:3130` (`read_text(encoding="utf-8")`) + `:3731` (`errors="backslashreplace"`, encoding preserved) | ✅ code present; [B] owed to stage 6 |
| AC-10 | `:2714` (`json.loads(CFG_PATH.read_text(encoding="utf-8"))`), clause order `(OSError, ValueError)` at `:2715` | ✅ code present; [B] owed to stage 6 |
| AC-11 (a) run does not end | `README.md:297` "written as a backslash escape rather than ending the run: the whole masked document still reaches stdout and the command still exits `0`"; `README.zh-CN.md:297` "会以反斜杠转义写出、而不是让命令中断：整份隐去后的文档照样完整地写到标准输出，命令照样以 `0` 退出" — read against `bin/sc:3731` + `:3163-3166` | ✅ both languages |
| AC-11 (b) three spellings, chosen by the character | EN "`\xNN` for one in the Latin-1 range, `\uNNNN` for one elsewhere in the BMP (the CJK case), `\UNNNNNNNN` for one above the BMP"; ZH "Latin-1 范围内的字符写成 `\xNN`，BMP 之内其余的字符（中文正是这一类）写成 `\uNNNN`，BMP 以上的写成 `\UNNNNNNNN`" — matches `04_DEVELOPMENT.md`'s measured boundary U+0080…U+00FF / U+0100…U+FFFF / ≥ U+10000 | ✅ both languages |
| AC-11 (c) only `\uNNNN` is a JSON escape | EN "of those three **only `\uNNNN` is a JSON escape**. A saved file whose escapes are all of that form is therefore still valid JSON; one carrying a `\xNN` or a `\UNNNNNNNN` is not"; ZH "这三种里**只有 `\uNNNN` 是 JSON 的转义写法**。所以转义全是这一种的文件，存下来仍然是合法 JSON；只要其中出现了 `\xNN` 或 `\UNNNNNNNN`，存下来的文件就不是" — the clause HEAD got wrong, now stated in the direction V-11's three-row table measured | ✅ both languages |
| AC-11 (d) UTF-8 stdout is the unescaped route | EN "In every case, running the command under a UTF-8 stdout is what gets you the document unescaped"; ZH "任何情况下，想拿到未经转义的文档，都是在 UTF-8 的标准输出下运行这条命令" | ✅ both languages |
| AC-11 negative 1 (no "invalid irrespective of the character") | Neither paragraph makes an unconditional invalidity claim; both condition on the spelling. The retained opening hedge is a sufficient condition, not an exclusive one (CR-8) | ✅ |
| AC-11 negative 2 (no unverified saved-file claim) | Every saved-file claim in each paragraph maps onto a row of the three-tag table (`香港-01` parses, `café-02` and `🚀-03` do not); no claim about size, completeness or masking of the saved file beyond "the whole masked document reaches stdout", which the table measured at 267 / 262 / 265 B with `uuid` masked | ✅ |
| AC-11 blast radius (one hunk per file, every other line byte-identical) | Not machine-diffable at this stage. First-hand: `:124` / `:152` in both files still carry HEAD's wording, and every line number this review cited in round 1 is unmoved in both READMEs — consistent with a one-line-for-one-line `@@ -297 +297 @@` and no insertion or deletion above it | ✅ code-level; git-level confirmation owed to V-11 / V-17 (RES-4) |
| AC-12 | 8 text sites all name `utf-8` (`:521`, `:619`, `:1673`, `:2021`, `:2714`, `:3130`, `:3467`, `:3514`); 5 binary sites admitted by a literal mode; no `json.loads` over `read_bytes()` | ✅ verified round 1, unmoved |
| AC-13 | `check-sc-contracts.py:416-532` + the transcript in `04_RATIONALE.md`; each new assertion has a stated kill, the codec kill is a substitution | ✅ mechanism present; stage 6 re-runs. The E-10 collapse mutant kills nothing by design (CR-1) |
| AC-14 | `baseline.json:4-5` `test_count`/`passing_count` = 17 = `len(TESTS)`; stage 4 round 3 re-ran `verify_all` after E-18 and reports PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0 | ✅ floor consistent; the run itself is stage 6's |
| AC-15 | `_write_private()` `:488-538`, `_config_digest()` `:1958-1980`, `_record_generated()` `:1983-2000` unchanged; `settings.json` still `write_text`, no `chmod` on `SETTINGS_PATH` | ✅ |
| AC-16 | `cmd_config()` `:3114-3176` — exactly one `sys.stdout.write` (`:3164`), argument through `_redact()`; `MASK` / `SECRET_KEYS` / `VISIBLE_IN_OUTBOUND` / `_redact()` untouched; no flag, setting or env var added. Re-read this round: the docstring above it changed nothing in the body | ✅ |
| AC-17 | No new `t()` key; no new file, module or format; `bin/sc` still `+24/−9` as itemised, and E-18 adds no product code line — the two README hunks are prose | ✅ against the shipped source and the supplied `--numstat` |
| AC-18 | `docs/dev-map.md:37`, `:43`, `:76`, `:87` each read against the shipped code and true; `:43`'s `cmd_config()` clause names the codec; `:81`'s stream-configuration row describes `backslashreplace` without making any JSON-validity claim, so nothing there was falsified by this change | ✅ |
| AC-19 | Guard verified first-hand at all four raise sites in round 1 and re-read at `:3405-3411` this round; `None != SETTINGS_PATH` sorts to the bare `raise` at `:3410` | ✅ [S] half closed; [B] rows and the mutation control owed to stage 6 (CR-1) |

## Design fidelity check

| design item | implementation | status |
|---|---|---|
| Round-1 ledger verification (E-1…E-14, I-1…I-8, K-1…K-11, K-13, frozen set) | carried forward, not re-derived, per the round-2 scope. Re-read this round at `bin/sc:2074`, `:3130`, `:3405-3411`, `:3731`, `:3769` — all at their round-1 line numbers with their round-1 text | ✅ carried |
| E-1…E-6 (six codec arguments) | `:1673`, `:2021`, `:2714`, `:3130`, `:3466-3468`, `:3514` | ✅ |
| E-7 / I-1 (`save_settings()` renderer mirroring `save_nodes()`) | `:616-623` — same five elements, same order, same key, same cause clause as `:590-596` | ✅ |
| E-8 / FR-5 / P-3 (`except SystemExit:` + one comment; `try` holds one statement) | `:449-453` | ✅ |
| E-9 / I-2 / K-2 (one `load_settings()` after the override wrapper, before `load_nodes()`) | `:2072-2075` | ✅ |
| E-10 / I-3 / K-13 (guard first, `raise` first, `regen_ok = False` second) | `:3405-3411` | ✅ |
| E-11 / E-12 / I-5…I-8 / C-10 (three assertions, floor 14 → 17) | `check-sc-contracts.py:416-532`, `TESTS` `:537-547`, `baseline.json:4-5` | ✅ |
| E-13 (four in-place dev-map clause corrections, no new row) + CR-1's coverage clause | `docs/dev-map.md:37`, `:43`, `:76`, `:87`; `:76` now carries the coverage clause inside the existing row | ✅ |
| E-14 (one Chinese bullet at the head of `### 修复`) | `CHANGELOG.md:26` | ✅ |
| **E-18** (one hunk per README at `:297`, that paragraph only; four assertions + two negatives, in each language, same facts) | `README.md:297`, `README.zh-CN.md:297` — see the AC-11 rows above | ✅ |
| E-18's "adds no product code line" | `bin/sc` unmoved at every site round 1 cited; developer's `git diff --numstat bin/sc` still `24  9` | ✅ code-level; git-level owed to V-17 |
| **K-12 rewritten** (correct exactly that paragraph, freeze everything else) | `:124` / `:152` in both files still carry HEAD's text; no section added, retitled, moved or reflowed; the paragraph's first and last sentences still describe the stdout/stderr split and the three stderr notes, both true of `bin/sc:3149-3166` | ✅ |
| Frozen set as narrowed (both READMEs except `:297`) | every other paragraph read in this neighbourhood is HEAD's, including the one CR-2 names | ✅ |
| Out-of-scope 10 / NFR-3's permitted paths (two READMEs, that paragraph only) | 7 files in the change; no doc-lint step, prose template or documentation-accuracy mechanism anywhere in it | ✅ |
| Migration order 7 (E-18 last, after the product change **and** after V-11's measurement, both languages in one commit) | `04_DEVELOPMENT.md`'s three-row measured table was taken before either paragraph was written; both hunks land together | ✅ |
| K-10 / NFR-2 (no new translation key) | `TRANSLATIONS` untouched; E-18 is documentation, not output | ✅ |
| NFR-1 budget (+24/−9, 19 code / 5 comment) | unchanged by this round; E-18 changes no term of the accounting | ✅ |

## Axis status
- Standards-conformance: 7 findings, worst = MINOR (CR-2 a pre-existing frozen-document inaccuracy, verified untouched; CR-7 the `cmd_config()` docstring's two-spelling enumeration, ruled shippable; five NITs). CR-1 is discharged.
- Spec/design-fidelity: **no findings.** AC-11's four assertions and both negatives are carried in **both** languages; E-18, the rewritten K-12, the narrowed frozen set and migration order 7 all hold; no other ledger row, interface, constraint or migration step moved, and nothing round 1 approved was re-opened or disturbed.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | E-10's `.path` guard is covered by no committed assertion: the collapse mutant passes B.4 at `17/17/17`, exit 0. AC-19 / V-19 is its only control and must be reported as such — including the mutant's FAIL — rather than as one more passing row. The boundary is written at `docs/dev-map.md:76`; the report is still owed. | `06_TEST_REPORT.md` AC-19 row |
| RES-2 | Buy the committed pin: a contract-suite assertion that drives `cmd_update_rules()`'s recovery arm with stubbed fetches and an unusable `override.json`, raising the floor 17 → 18. It is the suite's first command-level fixture, so it is a pool row, not a patch. | `07_DELIVERY.md`, then the pool (T-30 family) |
| RES-3 | Both READMEs (`:124`, `:152` in each) say the start-up path runs for "every command except `sc doctor`"; `sc config` has skipped it since T-06 (`bin/sc:3769`). Pre-existing, frozen here, and verified untouched by E-18. | `07_DELIVERY.md`, then the pool |
| RES-4 | **Restated** (its byte-identity form is obsolete — AC-11 no longer requires the paragraph to be byte-identical). What is unverified at this stage is AC-11's **blast radius**: that `git diff -U0` shows exactly one hunk per README at `@@ -297 +297 @@`, that every other line of both files is byte-identical to HEAD, and that `git diff --numstat bin/sc` reads `24  9`. This stage holds no git (R-78 keeps it read-only), so those rest on the developer's reported output plus first-hand evidence: `:124` / `:152` in both files still carry HEAD's wording, and every `bin/sc` and README line number cited in round 1 is unmoved. Machine confirmation is owed. | `06_TEST_REPORT.md` V-11 row (READMEs) and V-17 row (`bin/sc` numstat) |
| RES-5 | `cmd_config()`'s docstring (`bin/sc:3119-3122`) enumerates two of the three escape spellings and closes with an equality claim about the READMEs that is now an understatement. Nothing false ships and it was disclosed, not hidden; a one-line alignment belongs with the prose sweep, where it costs no `bin/sc` line in a task whose diff is pinned at `+24/−9`. | `07_DELIVERY.md`, then T-32 |

## Verdict
APPROVED — 0 CRITICAL, 0 MAJOR (2 MINOR, 5 NIT recorded as notes; none blocking)
