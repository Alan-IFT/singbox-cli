> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

# T-25 — output-layer-contract · Solution Design

Mode: **full**. Upstream `01_REQUIREMENT_ANALYSIS.md` verdict: READY. Decision authority: standing
(owner) — every judgment call below is resolved, none is returned to the human.

## Architecture summary

1. The output contract has exactly **two** homes, both already in `bin/sc`: the **string layer**
   (`TRANSLATIONS` + `t()`, `bin/sc:131-471`) where a key *is* its English rendering and carries its
   own field punctuation and its own invariant count form, and the **stream layer** — one statement
   at the top of `main()` that configures `sys.stdout` once, so every later `print()` inherits both
   write-order fidelity (FR-6) and unencodable-character survival (FR-7).
2. What does not change: `t()`'s body, the absence of an `en` table, `TRANSLATIONS`' shape, the
   `⚠️`/stderr policy, `_doctor_print`'s row shape, `check-i18n-parity.sh`, `install.sh`, every
   `zh` **value** except the one new separator entry, and the set of messages `sc` emits.
3. The seam is `main()`'s first statement plus the table itself: FR-1/2/4/5 are **data** edits to
   keys, FR-6/7 are **one** stream statement, and FR-8 is four call sites re-using `_plain()`
   (`bin/sc:2461`) — no new function, no new file, no new concept.

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| L-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `import io` added to the import block (`bin/sc:3-19`); the stream statement I-1 becomes the first executable statement of `main()` (`bin/sc:3668-3670`) | dev |
| L-2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | string layer: keys I-3…I-6 edited/added in `TRANSLATIONS["zh"]` (`bin/sc:212-213,223-230,242-250,290-293,358,370`) and their comment block at `:247-250` rewritten to state the convention instead of the defect | dev |
| L-3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | call sites of the edited keys: `bin/sc:1052-1055` (`_age_text` ladder), `:1199`, `:1203-1204`, `:1536`, `:2302-2303` (`sc ls` heading row, I-2), `:2582`, `:2585`, `:3329`, and `:2423` (rule-set line adopts I-6, `%-20s %s`) | dev |
| L-4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | FR-8: four `cmd_status` values routed through the existing `_plain()` — `:2427` (active tag), `:2430` (Clash `mode`), `:2435` (egress body), `:2437` (`{e}`, as `_plain(str(e))`, the `_doctor_print` idiom at `:2992`) | dev |
| L-5 | `/home/alan/Programs/singbox-cli/README.md` | edit | the English `sc ls` sample block `README.md:93-99` — heading row and all four data rows replaced by a verbatim capture of the shipped build (K-7); surrounding prose unchanged | dev |
| L-6 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | the translation-key bullet `:90-92` restated as the convention (FR-9); one new `## Reusable utilities` row for the stream statement; one clause added to the `main()` row of the sections table | dev |
| L-7 | `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` | edit | **already appended by stage 2** — record `per-print-flush-instead-of-one-stdout-configuration`. No developer action; do not add a second record | — |
| L-8 | *(gap record, per Q-16)* | — | `.harness/rules/70-doc-size.md` declares no `## Stage-doc boundary rule`, so no `## Byte-form specification` section is admitted; the six headings and every edited key are carried as `## Interfaces` shapes, and README's sample is captured from a run rather than transcribed (K-7) | — |

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `bin/sc` `main()` — the stdout configuration | `sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding=sys.stdout.encoding, errors="backslashreplace", line_buffering=True)`, executed only when `getattr(sys.stdout, "buffer", None) is not None`, as the first statement of `main()` (before `parser.parse_args()`) | One statement, one place, 3.6-only API. `line_buffering=True` ⇒ every completed line reaches fd 1 before the next child process writes to it (FR-6, and `argparse`'s own `-h` output is inside the guarantee). `errors="backslashreplace"` ⇒ no character `sc` or the user authors can raise `UnicodeEncodeError` (FR-7, BC-8). The stream's **encoding is preserved**, never forced, so a UTF-8 terminal is byte-identical to HEAD (BC-7). Skipped, never raising, when stdout is absent or has no binary buffer (BC-6). |
| I-2 | `bin/sc:2302-2303` — the `sc ls` heading row | `f"{t('#'):>4}  {t('On'):2}  {t('Type'):10}  {t('Name'):30}  {t('Address'):25}" f"  {t('Delay'):>9}"` | Field widths, order, separators and the trailing `Delay` column are byte-identical to HEAD; only the six key strings change. Every heading is ≤ its field width (`#`=1≤4, `On`=2≤2, `Type`=4≤10, `Name`=4≤30, `Address`=7≤25, `Delay`=5≤9), so heading and data columns start at the same offsets in both languages (FR-2, AC-1, AC-3). |
| I-3 | `TRANSLATIONS["zh"]` — `sc ls` headings (`bin/sc:242-250`) | five keys renamed in place, values untouched: `ls.idx`→`#`, `ls.active`→`On`, `ls.type`→`Type`, `ls.name`→`Name`, `ls.address`→`Address`; `Delay` unchanged | The six `zh` values (`序号` / `激活` / `协议` / `名称` / `地址` / `延迟`) stay byte-identical to HEAD (AC-2). No key in the shipped file matches `identifier.identifier` afterwards (FR-1). None of these five words may be reused later as a key for a different line. |
| I-4 | `TRANSLATIONS["zh"]` — the age ladder (`bin/sc:223-226`) + `_age_text` (`bin/sc:1052-1055`) | four keys: `{n} second(s) ago`, `{n} minute(s) ago`, `{n} hour(s) ago`, `{n} day(s) ago`; the same four literals updated in `_age_text`'s unit tuple and its tail `return` | One rendered form per phrase for every value of `{n}`; the 1-unit and 2-unit renderings differ only by the number (AC-5). `zh` values (`{n} 秒前` …) byte-identical to HEAD. `last update unknown` (`bin/sc:227`) is untouched — BC-4 is unchanged. |
| I-5 | `TRANSLATIONS["zh"]` — the byte family (`bin/sc:212,229,230,290,292-293,358`) | six keys, `bytes`→`byte(s)` and nothing else: `OK ({size} byte(s))`, `{done} byte(s)`, `truncated: got {got} of {declared} byte(s)`, `{reason}, {size} byte(s), {age}`, `{reason}, {size} byte(s), {age} — run \`sc update-rules\` to refresh`, `larger than {n} byte(s)` | `zh` values byte-identical to HEAD (Chinese has no inflection). The literal prefix `OK (` is preserved verbatim — `.harness/scripts/restricted-network-regression.sh:284` counts it. `{done}/{total} bytes ({pct}%)` (`bin/sc:228`) is **not** in this set (Q-7). |
| I-6 | `TRANSLATIONS["zh"]` — the field separator (**one new entry**) + `bin/sc:2423` | key `"{reason}, {age}"` → `"{reason}，{age}"`; the call site becomes `print("%-20s %s" % (fname, t("{reason}, {age}", reason=_status_text(status), age=_age_text(mtime))))` | The separator between a status word and the field after it lives **inside** the translated string, exactly as `sc doctor`'s `{reason}, {size} byte(s), {age}` does; English renders `, ` (byte-identical to HEAD), Chinese renders `，` on both screens (FR-4, AC-7). The `%-20s ` column pad stays outside `t()` — it is alignment, not punctuation. |
| I-7 | `docs/dev-map.md:90-92` — the translation-key convention bullet | a heading-level statement of the convention: every key is readable English text and *is* its own English rendering; the `zh` entry carries the same placeholder set; punctuation joining fields belongs inside the string; a count phrase renders one invariant form; a key with no `zh` entry renders English **by design** (BC-5) | States the convention; records no defect and names no `ls.*` key (FR-9, AC-15). |
| I-8 | `docs/dev-map.md` `## Reusable utilities` — one new row | need: "what makes a printed line ordered and encodable"; existing: I-1 in `main()`; notes: line-buffered + `backslashreplace`, 3.6 floor (no `reconfigure()`), skipped when stdout has no buffer, and the closing rule — a new command adds **no** per-site `flush=True` and no character filtering of its own | One home for the stream discipline, so a later command inherits FR-6/FR-7 without an edit. |

## Constraints

**K-1** — The developer configures stdout **exactly once**, as the first executable statement of
`main()` (`bin/sc:3670`), before `parser.parse_args()`; no other site may re-wrap, re-encode,
detach or flush-decorate `sys.stdout`, and no `print()` may execute before it.

**K-2** — The developer uses no API introduced after Python 3.6: `io.TextIOWrapper(...)`, never
`sys.stdout.reconfigure(...)` (3.7-only, `docs/dev-map.md:93-95`, NFR-1). The developer does not
change the stream's encoding and does not force UTF-8.

**K-3** — The developer guards I-1 on `getattr(sys.stdout, "buffer", None) is not None`, so
`sc config >&-` and any harness that replaces `sys.stdout` with a non-binary object reach the
handler path they reach today and the guard itself never raises (BC-6).

**K-4** — The developer leaves stderr untouched: no change to the `⚠️` prefix, to which stream any
message uses, to `_doctor_print`'s per-row `flush=True` (`bin/sc:2978`), or to any existing explicit
`sys.stdout.flush()` / `sys.stderr.flush()` (`bin/sc:1201,1213,3121,3125,3307,3385`). Q-18 binds:
no message is added, removed or moved; the only new table entry in this task is I-6.

**K-5** — The developer runs the FR-3 enumeration **on HEAD, before editing any string**, from the
repository root, over `bin/sc`'s call sites: parse the file with `ast`, collect every `Call` whose
`func` is the name `t`, resolve the first argument when it is a string constant (adjacent implicit
concatenation across source lines — e.g. `bin/sc:1400-1401` — is folded by the parser and therefore
resolves to its whole value), and report every other first-argument form as **undecidable with its
line number, never as a pass** (AC-4). The script is written outside the repository and is not
committed (out-of-scope 10, NFR-2).

**K-6** — The three indirect call sites are `bin/sc:1054` (`t(key, …)`), and `bin/sc:2978`'s
`t(DOCTOR_MARK[cls])` and `t(label)`. The developer resolves them by naming their key sets —
`DOCTOR_MARK`'s three values (`bin/sc:2456`), the ten `DOCTOR_SECTIONS` labels (`bin/sc:2955-2965`)
and the static row labels the nine probes return — and records that the `t(label)` universe also
contains **rule-set filenames** (`bin/sc:2586`), which are data passing through `t()` and render as
themselves in both languages. No filename, and no other data value, is added to `TRANSLATIONS`.

**K-7** — The developer replaces `README.md:93-99`'s sample by capturing the real output of the
built `bin/sc` on a fixture whose node list is the one the surrounding prose describes (auto group
active at `→ JP-2` / 141 ms, then `US-1` 1.1.1.1:443 / 210 ms, `JP-2` 2.2.2.2:443 / 141 ms, `SG-3`
3.3.3.3:443 / `-`), pasted verbatim including the full column widths. No heading row in any document
is composed by hand or copied from this design (AC-15).

**K-8** — AC-11's enumeration is `## Interfaces` rows I-3…I-6; the developer restates it in
`04_DEVELOPMENT.md` as one row per added/edited string with its **rendered** English and Chinese
form and a yes/no column for `失败：` and `failed: `. The expected answer is "no" for every row: the
`zh` value of every edited key is byte-identical to HEAD, and I-6's only Chinese text is `，` while
its substituted fields draw from `_status_text` (`可用` / `缺失` / `不是规则集文件` / `文件过小` /
`无法读取`) and `_age_text` (`{n} 秒/分钟/小时/天前`, `更新时间未知`). `failed: {e}` / `失败：{e}`
(`bin/sc:213`, emitted at `:3343`) keeps meaning exactly "this rule-set file was not updated".

**K-9** — The developer changes no phrase of the shape `{n}/{total} …` (`bin/sc:215-218,228,289,
325-328`), no phrase whose noun is an invariant unit symbol (`{ms} ms`, `bin/sc:329-334`, and
`sc ls`'s `f"{delays[tag]} ms"` cell at `:2298`), and does **not** touch `at {at}: {name} matched
{count} elements …` (`bin/sc:370`) — `bin/sc:1399` raises it only when the count is not 1, and it is
R-72's line.

**K-10** — The developer routes each of the four `cmd_status` values through the **existing**
`_plain()` and adds no second neutralisation, no verdict, no `[CLASS] label: value` shape and no
line of `sc`'s own (Q-14, BC-9). `sc` does not capture a child process's output in order to filter
it — the child keeps writing to fd 1 directly.

**K-11** — Under a non-UTF-8 stdout the escaped form of a character is wider than the character it
replaces, so `sc ls`'s columns misalign on such a host. This is accepted behaviour, not a defect:
AC-10 asserts the row's presence and the exit status only, and no claim is made about glyphs
(Q-11/Q-12). The developer does not add padding compensation for it.

**K-12** — No new file enters version control and `bin/sc` stays one self-contained stdlib-only file
(NFR-2). `import io` is the only import added.

## Frozen set

| path | why frozen |
|---|---|
| `/home/alan/Programs/singbox-cli/.harness/scripts/check-i18n-parity.sh` | AC-16 requires byte-identity; Q-9 keeps B.2 scoped to `install.sh` |
| `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` + `.ps1` + `baseline.json` | out-of-scope 4/10; the PASS/WARN counts are the task-start baseline AC-16 compares against |
| `/home/alan/Programs/singbox-cli/install.sh`, `uninstall.sh`, `systemd/*` | this task changes no installer or unit behaviour; `install.sh`'s own `失败` strings are its own |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` | its `sc ls` sample (`:94`) publishes the **Chinese** rendering, which this task leaves byte-identical (out-of-scope 5) |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | its `[Unreleased]` entries publish Chinese renderings only, all unchanged; a release note is PM's call at delivery (residual D-3) |
| `bin/sc:469-471` (`t()`) | Q-1: the key-on-miss fallback is the design, not the defect |
| `bin/sc:131-132` (`TRANSLATIONS` shape) | Q-2: no `en` table, no second table, no catalogue |
| `bin/sc:135` (`Config check failed:\n{stderr}`) | Q-17: a pre-existing `失败：` collision, recorded and filed, not repaired here |
| `bin/sc:213` + `:3343` (`failed: {e}`) | BC-1: the load-bearing diagnostic literal and its one meaning |
| `bin/sc:2968-2978` (`_doctor_print`) | Q-14 + AC-14: the row shape and the per-row flush are pinned |
| `bin/sc:228` (`{done}/{total} bytes ({pct}%)`) | Q-7: a fraction phrase is already correct for every value |
| `bin/sc:2308-2313`, `:156-157`, `:238`, `:3600` (`●`, `→`, `⚠️`) | Q-12/Q-15: no character inventory; FR-7 is satisfied over the stream, not by removing characters |
| `bin/sc`'s `_init_files()`, `/etc/sing-box`, `/var/lib/sing-box`, the live service | safety: no fixture and no edit may reach them; `bin/sc` must be imported through `docs/dev-map.md:118-151`'s recipe |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | (none — measurement) | K-5's enumeration runs against **HEAD**, so its two counts describe the shipped file; if it reports an offender, that offender's `zh` entry is added as **data** in step 3 and no mechanism is added | read-only; nothing to roll back |
| 2 | L-1 (I-1) | none — no on-disk format, setting, flag or API changes anywhere in this task, so there is no data migration and no compatibility window | revert 1 import + 3 statements; behaviour returns to HEAD's buffering exactly |
| 3 | L-2, L-3 (I-2…I-6) | step 1 recorded, so the count-phrase population is confirmed over the union of table keys and call-site keys before any key is edited | revert `TRANSLATIONS` and the nine call sites together — a key edited without its call site (or the reverse) renders the raw key in English and is the one incoherent intermediate state |
| 4 | L-4 | step 3 done (unrelated, but keeps one reviewable string diff) | revert four `_plain()` wraps |
| 5 | L-5, L-6 (I-7, I-8) | steps 2-4 built and runnable — K-7's capture must come from the **changed** build | revert two documents |
| 6 | — | `.harness/scripts/verify_all` run **from the repository root** (an invocation from a subdirectory self-reports a false red) | — |

## Out of scope

- No `en` table, no message catalogue, no formatter, no plural-selection helper, no second key per phrase, no new module, no new runtime file (out-of-scope 1/2, NFR-2).
- No change to `t()`, to `check-i18n-parity.sh`, to `verify_all`, or to `install.sh`'s strings.
- No column-width or alignment redesign of `sc ls`, in either language, on any locale.
- No adoption by `sc status` of `sc doctor`'s row shape or verdict vocabulary; no new `sc status` line.
- No repair of Q-17's pre-existing `配置检查失败：` collision, and no change to `{fault}`/`{e}` values that carry a Python class name — those are T-24's deliberate diagnostic values, not translation keys.
- No change to `", ".join(...)` list separators (`bin/sc:1094,2768,3362,3377,3380,3383`): FR-4 binds punctuation between the **fields of one rendered line**, not the separator inside a homogeneous list.
- No permanent key-parity gate for `bin/sc` (Q-8 — T-28's), no committed test or fixture.
- No `CHANGELOG.md` entry (frozen set; PM's call at delivery).

## Verification plan

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | `sc ls` through `main()` on a fixture whose own `settings.json` carries `lang: "en"`, ≥1 node (never by assigning `sc.LANG`) | heading row reads `#`, `On`, `Type`, `Name`, `Address`, `Delay`; no heading contains `.` | AC-1 |
| V-2 | same fixture, `lang: "zh"` in `settings.json`; diff against a pristine HEAD **clone** at the same fixture path | 序号 / 激活 / 协议 / 名称 / 地址 / 延迟, byte-identical | AC-2 |
| V-3 | column start offsets computed from V-1's emitted text, heading row vs each data row | all six offsets coincide (HEAD fails: 6-char `ls.idx` overflows a 4-wide field) | AC-3 |
| V-4 | K-5's `ast` enumeration, once, from the repository root | two counts + every undecidable site by line + any offender; ≤5 lines in `04_DEVELOPMENT.md`; the three K-6 sites appear as undecidable and are resolved by name | AC-4 |
| V-5 | `_age_text` rendered at 0 s, 1 s, 60 s, 3600 s, 86400 s, 129600 s, both languages | 1-unit and 2-unit renderings differ only by the number; no `1 <plural>`; 36 h reads `1 day(s) ago` | AC-5 |
| V-6 | every member of I-4 + I-5 rendered at 0, 1 and 2, both languages, with the population table from K-8 attached | one form per phrase; the byte family is present in the listed population | AC-6 |
| V-7 | `sc status` and `sc doctor` on the same fixture in the same run, `lang: "zh"` then `lang: "en"` | zh: `，` in both rule-set renderings; en: `, ` in both | AC-7 |
| V-8 | `sc status` with stdout redirected to a real file (never a TTY), `sc.SYSTEMD = True`, `sc.subprocess.run` stubbed to spawn a **real child process** writing to the inherited fd 1; candidate vs pristine HEAD clone | candidate: every heading above its child's output. HEAD: the inversion must appear, or the fixture cannot detect the defect | AC-8 |
| V-9 | `sc ls` (active node) and `sc add` of an all-ASCII share URL under `PYTHONUTF8=0 LC_ALL=C PYTHONCOERCECLOCALE=0`, with `sys.stdout.encoding` and `locale.getpreferredencoding()` recorded as proof; control = same runs on a HEAD clone | candidate: whole output, unchanged exit status, no traceback. Control: aborts | AC-9 |
| V-10 | same environment, node tag containing non-ASCII characters | the row is printed and the exit status is unchanged; no assertion on glyphs or column alignment (K-11) | AC-10 |
| V-11 | K-8's enumeration table | every added/edited string listed with both rendered forms; no row introduces `失败：` or `failed: ` | AC-11 |
| V-12 | one Clash `mode` value carrying a CSI sequence and a `\r`, printed by `sc status` and by `sc doctor` in one run | both screens print the same neutralised text; HEAD differs on `sc status` | AC-12 |
| V-13 | a Clash `mode` value containing a line break | the value occupies exactly the lines it contains; `sc` adds none | AC-13 |
| V-14 | full English `sc status` / `sc doctor` / `sc ls` diff against a pristine HEAD clone on the same fixture | the diff is a subset of I-2…I-6's enumerated renderings | AC-14 |
| V-15 | `README.md`'s new sample compared character-by-character against a real capture of V-1's fixture; `docs/dev-map.md:90-92` read | sample matches; the bullet states the convention and records no defect | AC-15 |
| V-16 | `git diff --stat` on `.harness/scripts/check-i18n-parity.sh`; `.harness/scripts/verify_all` **from the repository root** | script byte-identical; PASS 17 / WARN 0 / FAIL 0 / SKIP 1, no new FAIL and no new WARN | AC-16 |

No criterion in this plan requires root, a live sing-box service, or a network: every run uses the
import recipe at `docs/dev-map.md:118-151` with all eight path constants repointed into a `mkdtemp()`
root, `sc.SYSTEMD`/`sc.OPENRC` set explicitly, and `sc.SB_BIN` pointed at a stub. Nothing is BLOCKED.

## Residuals travelling

| id | statement | must reach <stage/doc> |
|---|---|---|
| D-1 | The FR-3 enumeration's two counts, its undecidable sites and any offender it finds are this task's evidence for AC-4 and must be recorded, not summarised as "checked" | `04_DEVELOPMENT.md` |
| D-2 | Classification judgment to test rather than accept: `truncated: got {got} of {declared} bytes` is treated as a **byte phrase** (changed) while `{done}/{total} bytes ({pct}%)` is treated as a **fraction phrase** (unchanged, Q-7). Reasoning in `02_RATIONALE.md` §4 | `03_GATE_REVIEW.md` |
| D-3 | Whether this fix earns a `CHANGELOG.md` `[Unreleased]` line is PM's call at delivery; the design deliberately writes none | `07_DELIVERY.md` |
| D-4 | Q-17's pre-existing `配置检查失败：` / `失败：` collision (`bin/sc:135`, reachable into `install.log`) stays open and is not repaired here | `docs/tasks.md` (PM pool row) |
| D-5 | Candidate insight: on the 3.6 floor a one-statement `io.TextIOWrapper` re-wrap of `sys.stdout` in `main()` buys write-order fidelity and encode survival together, and `sys.stdout.reconfigure()` is not available | `07_DELIVERY.md` `## Insight` |
| D-6 | Under a non-UTF-8 stdout `sc ls`'s columns misalign because an escape is wider than its character — expected, not a defect (K-11) | `06_TEST_REPORT.md` |

## Partition assignment

Not applicable — this project has no `.harness/agents/dev-*.md` partitions; single-Developer mode, one dispatch, `bin/sc` then the two documents.

## Verdict

READY
