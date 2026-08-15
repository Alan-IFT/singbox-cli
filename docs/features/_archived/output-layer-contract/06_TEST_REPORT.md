> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

# T-25 — output-layer-contract · Test Report

Every result below is an **independent** measurement: my own harness, my own enumerations, my
own reproducers written from `01_REQUIREMENT_ANALYSIS.md`'s criteria, never from
`04_DEVELOPMENT.md`'s test code. Where my number coincides with the developer's, it is a
reproduction, not a citation. Full transcripts: `06_RATIONALE.md`.

`.harness/rules/70-doc-size.md` declares no `## Stage-doc boundary rule` (Q-16 / R-37, a
fifteenth time), so this contract's schema is applied **as written** and no section is invented.
The units it declares no shape for — C-1's safety record and the C-3 / C-9 / C-12 / RES-2
discharges, none of which is a criterion, a boundary, a total, a defect or a stability
statement — are carried in this preamble, ahead of every result, which is also where C-1
requires them. The preamble carries no heading of its own, so no section is invented.

**C-1 — safety floor, established before any result was recorded.**

Loader: `docs/dev-map.md:121-158`'s mandated recipe verbatim (the `os` shim keeping
`bin/sc:125-126`'s auto-elevate branch untaken, restored in a `finally`), with **one** addition
recorded as defect QA-1 below. `sc._init_files` is **rebound** immediately after the module
`exec` and before any command runs, so `bin/sc:544`'s `Path("/var/lib/sing-box").mkdir` is on no
code path of any process in this document. All eight path constants are repointed into the
fixture root and asserted there; `sc.SYSTEMD` / `sc.OPENRC` / `sc.SB_BIN` are set explicitly.
Every `main()`-driven run took `lang` from the **fixture's own `settings.json`**, never from
`sc.LANG` (`main()` reassigns it at `bin/sc:3706`/`:3709`); `clash_api_port` likewise
(`bin/sc:3710`). `sc.LANG` was assigned in exactly one step — the AC-6 direct-render — which
asserts nothing about I-1 (gate answer D-4).

Assertion output, one run, verbatim (rule 70 — 5 lines; identical on all 142 runs apart from
the root):

```
[C-1] loader = docs/dev-map.md:121-158 recipe; _init_files neutralised=True (bin/sc's Path('/var/lib/sing-box').mkdir never run)
[C-1] eight path constants inside <scratch>/t25qa/fx: OK
[C-1] protected paths after the run:
  /var/lib/sing-box  UNCHANGED
  /etc/sing-box      UNCHANGED
```

`grep -h '^\[C-1\] VERDICT'` over the session: **142 runs, 142 `OK`, 0 `VOID-RUN`**. Both
protected paths exist on this host and are root-owned, so the witness
(`exists, st_mtime_ns, st_ctime_ns, sorted(listdir)`, taken before the run and again from an
`atexit` hook) is a real observation. Session-end direct check: `/var/lib/sing-box` mtime
`1785387564`, `/etc/sing-box` mtime `1786421637` — the values `04_DEVELOPMENT.md` recorded at
stage 4, unchanged. Live service witnessed with `systemctl show`, never `is-active`:
`MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` — a start that predates
this session. No credential byte appears in this document. No file entered version control
(`git status --porcelain` after QA is identical to before).

One further hard-coded write path was found and jailed rather than driven blind:
`cmd_update_interval` builds `Path("/etc/systemd/system/sing-box-rules-update.timer.d")` at
`bin/sc:3439` and `write_text`s into it. AC-8's second site was measured under a **fail-closed
path jail** — every absolute path `bin/sc` constructs at run time is redirected under the
fixture root, so the function under test runs verbatim while the environment cannot be reached.
Proof it worked: the override landed at `<fx>/jail/etc/systemd/system/…/override.conf` and
`ls -d /etc/systemd/system/sing-box-rules-update.timer.d` reports **No such file or directory**.

**C-3 — AC-12's comparison clause.** Confirmed **NOT-DISCRIMINATING** by my own measurement, not
by reading: with a CSI+CR routing mode injected, `grep -ci 'route mode\|routing mode'` over
`sc doctor`'s whole screen is **0** on candidate and on HEAD — the screen renders no routing mode
for any input, so "identically to what `sc doctor` prints" compares against nothing. **Decision
(standing authority): re-point**, and carry the `sc status` half separately. Comparand = the
egress body, the value class both screens carry for the same input (`bin/sc:2456` ≡
`_doctor_egress:2886`, character-identical). Evidence in the AC-12 row. No upstream document
edited.

**C-9 — expected-variable lines declared and pinned before the run.** Written to
`c9-declaration.txt` before the AC-14 differential executed; reproduced in `06_RATIONALE.md` §5.
One line declared variable by construction (`sc doctor`'s measured `{ms}` DNS row); seven
ingredients pinned rather than tolerated (mtimes at `now−5000 s`, 2200 s of margin to the 7200 s
boundary; stubbed egress; one in-process Clash responder with fixed bodies; fixed port from the
fixture's own `settings.json`; no child output in the differential; one fixture path for both
builds; no `config.json`, so both drift rows read the same). In the event the declared line read
`0 ms` on all ten repeats and did not enter the diff.

**C-12.** `verify_all` invoked **only** from the repository root (`bash
/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh`), three times. The non-UTF-8
environment is proved, not assumed — measured on this host:
`LC_ALL=C PYTHONCOERCECLOCALE=0` alone gives `stdout.encoding=utf-8 preferred=utf-8` (the T-23
vacuity trap, live); adding `PYTHONUTF8=0` gives `stdout.encoding=ascii
preferred=ANSI_X3.4-1968`, and every AC-9 / AC-10 / RES-3 run recorded that pair per run. Every
differential baseline is a **pristine `git clone`** of `6c034d62` (`git status --porcelain`
empty) run at the **same** fixture path; no `git worktree` was created.

**RES-2 — hunk-level confirmation.** `bin/sc` carries **28** hunks. 27 map exactly onto L-1
(`import io` at `:8`; the `main()` statement + its comment at `:3697-3708`), L-2 (`:213`,
`:224-229`, `:232-233`, `:244-253`, `:294`, `:296`, `:298-301`, `:366`), L-3 (`:1064-1068`,
`:1212`, `:1216`, `:1549`, `:2315-2316`, `:2436-2440`, `:2603`, `:2606`, `:3356`), L-4
(`:2444-2458`) and the round-2/3 prose regions (`:471-475`, `:3102-3105`, `:3151-3158`). The
28th is defect QA-3. `bin/sc`'s top-level `def`/`class` count is **113** on both builds; the only
import added is `io`; `#`-line delta is **+33/−9**, exactly as DD-3 filed.
The "rounds 2-3 changed no behaviour" claim is discharged by **measurement, not reading**: I
built **build X** = the delivered tree with only those prose regions reverted to HEAD's text
(34 changed lines, every one a comment or docstring body), compiled it clean under
`python3 -W error`, and ran both builds at one fixture — `sc config`, `sc status`, `sc doctor`
and `sc ls` are all **`cmp`-identical** (211 / 376 / 2244 / 459 bytes). `sc config`'s output
re-parses as JSON under a UTF-8 stdout.

## Test plan

| Acceptance criterion | Test case(s) — and the wrong build the criterion would still pass | File |
|---|---|---|
| AC-1 six English headings | **PASS** — `sc ls` through `main()`, `lang: "en"` in the fixture's own `settings.json`; heading cells sliced at the format's own field offsets and compared to the six **words**: `['#','On','Type','Name','Address','Delay']`, no `.` in any. R-22 guard, measured: HEAD's row `.isascii()` is **True**, so an "is in English / is ASCII" check passes the broken build. Control: HEAD renders `ls.idx …`. Still passes: a build that hard-codes the six words outside `t()` (AC-2 catches it). | `runner.py`, `out/ls_en.*` |
| AC-2 zh byte-identical | **PASS** — same fixture, `lang: "zh"`; `diff` candidate vs pristine HEAD clone at the same path is **empty**. Renders 序号/激活/协议/名称/地址/延迟. Still passes: HEAD itself (AC-1 catches it). | `out/ls_zh.*` |
| AC-3 column offsets | **PASS** — gutters computed from widths 4/2/10/30/25/9 (starts 0/6/10/22/54/81) and asserted `"  "` on the heading row and all four data rows. Control: HEAD fails at **three** gutters (`'dx'`, `'ls'`, `'s.'`). Still passes: any six headings that merely fit their fields (AC-1 pins the words). | `ac3.py` |
| AC-4 call-site key enumeration | **PASS** — my own `ast` pass over every `Call` with `func == Name('t')`. Candidate **206 sites / 203 resolved / 160 distinct / 3 UNDECIDABLE @ 1067, 2999, 2999 / 183 zh keys / OFFENDERS 0 / identifier-shaped table keys 0**; HEAD 205/202/159 @1054,2978,2978 / 182 / 0 / **5**. Implicit concatenation resolves (20 multi-line keys, all in the table). The three undecidable sites are reported **by line, never as a pass**, and resolved by name (see QA-2). Cross-checked at runtime: `sc doctor` exercised 45 keys, the only four outside the table are the rule-set filenames (K-6's data pass-through). Still passes: an enumeration taken from the **table** (Q-8's named blind spot). | `ac4.py` |
| AC-5 age ladder | **PASS** — rendered **through `sc status`**, not through `_age_text`, at 0/1/59/60/120/3600/7200/23 h/86399/86400/129599/129600/172800 s in **both** languages. 36 h reads `1 day(s) ago` / `1 天前`; 1-unit and 2-unit forms differ only by the number; no `1 <plural>`. Control: HEAD fails at **all four** units (`1 seconds`, `1 minutes`, `1 hours`, `1 days`). Still passes: a build that fixed only the day unit (my run covers all four). | `out/age_*` |
| AC-6 count phrases | **PASS** — population **derived independently** from the shipped table by one test (a numeric placeholder next to the noun it counts, not a fraction numerator, noun not a unit symbol), then each member rendered at 0/1/2 in **each** language and checked for one invariant skeleton. **15** members by form; **14 OK**; the 15th (`at {at}: {name} matched {count} elements…`) is excluded by a reachability argument I verified at its sole call site — `bin/sc:1413` raises only when `len(hits) != 1`, so `1` is unreachable (K-9 / R-72). Population = the developer's 14, re-derived. Control: HEAD scores **4/15**. Still passes: a population narrowed to the age ladder. | `ac6.py` |
| AC-7 one separator | **PASS** — both screens, same fixture, same run, both languages. zh candidate: `可用，1 小时前` (status) and `可用，64 字节，1 小时前` (doctor) — same `，`. en: `usable, 1 hour(s) ago` / `usable, 64 byte(s), 1 hour(s) ago` — same `, `. Control: HEAD status `可用, 1 小时前` against doctor's `可用，…` — one fact, two punctuations. Still passes: a build that changed only one screen (the same-run comparison catches it). | `out/ac7_*` |
| AC-8 write order | **PASS** — `sc status` to a real **file** and to a real **pipe**, `SYSTEMD=True`, `subprocess.run` spawning a **real child** on the inherited fd 1. Candidate: heading, child, heading, child (lines 1/2, 4/5). Control: HEAD prints both children as lines **1-2** and every heading below. Second FR-6 site also measured: `sc update-interval daily` under the path jail — candidate `=== Next run ===` above `list-timers`; HEAD's child at line 2, above both. Still passes: a `StringIO` capture (K-3 skips I-1 — F-10), or a TTY. | `out/st_en.*`, `out/ui.*` |
| AC-9 non-UTF-8 survival | **PASS** — `PYTHONUTF8=0 LC_ALL=C PYTHONCOERCECLOCALE=0`, proof recorded per run (`encoding=ascii`, `errors=surrogateescape` before / `backslashreplace` after, `preferred=ANSI_X3.4-1968`). `sc ls` prints the whole table, `sc add` prints `Added: NEW-ASCII (vless → 9.9.9.9:443)`, both exit **0**, 0 tracebacks. Control: HEAD aborts `UnicodeEncodeError '●'` / `'→'`, exit 1. Still passes: `LC_ALL=C` alone — measured to leave `encoding=utf-8`. | `out/ac9_*` |
| AC-10 non-ASCII tag | **PASS** — tag delivered **base64-safe** so it reaches the process as a real character (`nodes.json` holds `日本-1`); candidate prints every row, exit 0, no glyph claim. Control: HEAD aborts at `position 22-23`, **0** data rows. Still passes — and this is the sharp one: a tag arriving through `os.environ` under the POSIX locale is surrogate-escaped and **round-trips on HEAD**, which printed `日本-1` perfectly (measured). That fixture certifies nothing. | `out/ac10f.*` |
| AC-11 `失败：` / `failed: ` census | **PASS** — the edited set derived by **diffing the two shipped tables** (16 added, 15 removed, **0** zh values changed for a surviving key), then **490 rendered forms** across both languages with every `_status_text` × `_age_text` substitution. **0** contain either literal. Both grep consumers of `.harness/scripts/restricted-network-regression.sh:284` survive: `OK (` at `bin/sc:213`, `failed: {e}` / `失败：{e}` at `:214`. Still passes: a census taken over **keys** instead of rendered forms. | `ac11.py` |
| AC-12 CSI + CR | **NOT-DISCRIMINATING as written; re-pointed and PASS on both halves.** See C-3. `sc status` half: candidate `globalREDX`, HEAD `global^[[31mRED^[[0m^MX`. Re-pointed half: candidate status `203.0.113.7RED` ≡ candidate doctor `203.0.113.7RED`; HEAD status `203.0.113.7^[[31mRED^[[0m^M` ≠ HEAD doctor `203.0.113.7RED`. `=== Route mode ===` proved printed **1×** on both builds first (C-4). | `out/ac12_*` |
| AC-13 line count | **PASS** — a 3-line mode occupies exactly 3 lines under its heading; `sc` adds none; identical on HEAD. C-4 re-asserted: `grep -c '=== Route mode ==='` is **1** on candidate and **1** on HEAD before anything under it was read. Still passes: a fixture where `is_running()` is false and the section never rendered (F-3). | `out/res1_nl.*` |
| AC-14 differential | **PASS** — English `sc ls` / `sc status` / `sc doctor` against a pristine HEAD clone at the same fixture path. **3 changed lines total**: the heading row (I-2), `usable, 1 hour(s) ago` (I-4), `usable, 64 byte(s), 1 hour(s) ago` (I-4+I-5). Nothing else moved on 5 + 21 + 21 lines. C-9 pinned first. Still passes: a differential that tolerates variable lines. | `out/ac14_*` |
| AC-15 documents | **PASS** — `README.md:94-98` is `cmp`-identical to a **live capture of my own fixture** (auto → JP-2 141 ms, US-1 210, JP-2 141, SG-3 `-`). `docs/dev-map.md` names **0** `ls.*` keys and no longer records the defect (`grep` for "pre-existing defect, not a pattern to copy" = 0). `README.zh-CN.md:94` byte-identical to HEAD. Still passes: a sample transcribed by hand from the design. | `out/ac14_ls.cand.out` |
| AC-16 no new FAIL/WARN | **PASS** — `.harness/scripts/check-i18n-parity.sh` is outside the dirty set and sha256-identical to HEAD (`3b5ba570…`). `verify_all` from the repository root: PASS 17 / WARN 0 / FAIL 0 / SKIP 1, three times. Still passes: an invocation from a subdirectory (self-reports a false red). | `.harness/scripts/verify_all.sh` |

## Adversarial tests

Cases nobody specified, each with the failure I predicted before running it.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1/AC-3 | a node tag that is **pure combining marks** (U+0301 ×4) plus a ZWJ breaks the row or the gutters | `QA_TAGS_B64=<combining marks> … sc ls` (NEW) | Survived — all gutters `OK` on every row, 0 tracebacks, 4 lines: `   1      vless       M-LM-^AM-LM-^AM-LM-^AM-LM-^A                            1.1.1.1:443` |
| AC-5 | a rule-set mtime **exactly on** a unit boundary, and one **ahead of the clock**, break the ladder | `QA_SRS='{"a":-100000,"b":86400,"c":3600,"d":60}' sc status` (NEW) | Survived — `0 second(s) ago` for the future stamp (never negative), then `1 day(s) ago` / `1 hour(s) ago` / `1 minute(s) ago` |
| AC-9/AC-10 | a codec that can encode **some** of the tag degrades the whole line, or aborts | `PYTHONIOENCODING=latin-1 … sc ls` with tags `café-é` and `日本-jp` (NEW) | Survived, and highly discriminating — candidate prints `cafM-i-M-i` **and** `日本-jp`, exit 0; HEAD renders row 1 then aborts: `UnicodeEncodeError: 'latin-1' codec can't encode characters in position 22-23` |
| AC-8/FR-6 | the `ip` child writing **more than one pipe buffer** (240 KB) defeats line buffering | `QA_CHILD=big sc status > file` and `\| cat` (NEW) | Survived — candidate headings at lines **1 / 4003 / 8005**, each child immediately below; HEAD headings at **8001 / 8003 / 8005**, all 8000 child lines above. Identical on a file and a pipe |
| FR-6 | **stdout and stderr redirected to the same file** interleave or lose the aggregate's position | `sc status > f 2>&1`, and `sc update-rules > f 2>&1` with a dead base (NEW) | Survived — per-file stdout lines 1-5 then the stderr aggregate `4 ruleset(s) failed to update` last, on **both** builds; no intra-line splice |
| BC-14 | a **10 MB** Clash `mode` exhausts memory or truncates | `QA_MODE_REPEAT=10485760 sc status` (NEW) | Survived — `cand: stdout bytes=10486132 lines=21 tb=0 TIME 0.13 s RSS 68988 KB`; HEAD 10486130 bytes, the 2-byte delta being AC-14's single string change |
| RES-1 | `_plain(str(v))` at `bin/sc:2448`/`:2451` was never measured against a non-`str`; a number / boolean / object / null renders differently from HEAD, or crashes | `QA_MODE` and `QA_ACTIVE_JSON` set to `12345`, `true`, `{"a":1,"b":[2,3]}`, `null`; `sc status` on both builds (NEW) | Survived — every value renders **identically to HEAD** (`12345`, `True`, `{'a': 1, 'b': [2, 3]}`, `None`), 0 tracebacks either side. Counterfactual proves the guard load-bearing: `_plain(12345) -> AttributeError: 'int' object has no attribute 'replace'` |
| RES-3 | an **undecodable byte** in `SB_RULES_BASE` has no second route beyond the `{path}` rows | `SB_RULES_BASE=$(printf 'http://…/x\377y') sc update-rules` under `LC_ALL=C PYTHONUTF8=0`; and `sc doctor` with a `bad\xffname.json` in `CFG_DIR` (NEW) | **Second route confirmed** — `failed: http://127.0.0.1:1/x\udcffy -> …` on all four cause lines, and the permission row prints `…/bad\udcffname.json is mode 664`. But the HEAD half is **not observable**: see defect QA-5 |
| BC-6 | `sc ls >&-` raises inside the K-3 guard | `python3 runner.py >&-` on both builds (NEW) | Survived — `sys.stdout=None`, guard's false arm, **exit 0, 0 tracebacks on both**. `sc config >&-` fails identically on both (`AttributeError: 'NoneType' object has no attribute 'write'`), i.e. no worse than today |
| BC-12 | three concurrent `sc status` appending to one file splice a line | 3 × `sc status >> shared` in parallel (NEW) | Survived — 69 lines = 3 × 23, no partial or spliced line; one heading/child pair was separated by another process, which is exactly what BC-12 declines to promise |
| BC-8 | the narrowed `README*.md:297` sentence overstates what `sc config` does | `PYTHONIOENCODING=ascii sc config` on a document holding `é 日 🇯🇵` (NEW) | Reproduced the developer's claim independently — candidate **exit 0, 189 bytes**, `json.loads` → `Invalid \escape: line 5 column 15`; HEAD **exit 1, 0 bytes**, `UnicodeEncodeError '\xe9'`. Documented behaviour, not a defect |
| RES-4 | the double-wrapper price at pipe scale is larger than filed | `sc ls \| head -2` at 4000 nodes (NEW) | Reproduced — `cand: BrokenPipe=2 'Exception ignored'=1` vs `head: BrokenPipe=1 'Exception ignored'=0`; `sc config \| head -3` at 1.5 MB is clean on both (`os._exit` skips finalisation) |
| BC-5 | a language with no table (`lang: "fr"`) renders identifiers | `QA_LANG=fr sc ls` (NEW) | Survived — candidate renders the six English words; HEAD renders `ls.idx  ls.active …`, which is FR-1's whole point |
| BC-10/BC-11 | a heading whose child is absent, or whose value is empty, loses the heading or gains a message | `QA_CHILD=none`, `QA_MODE='""'`, `QA_ACTIVE=''` (NEW) | Survived — **7** headings in the same order on both builds, empty mode → an empty line on both, absent active → `(none)` on both; no message added or moved |

## Boundary tests added

- Null / absent: `mode` = JSON `null` → `None`; `active` absent → `(none)`; `mtime` unknown → `last update unknown` (word form, never a number — BC-4).
- Empty: `mode` = `""` → an empty line, identical to HEAD; a fixture with no rule-set files (all four `missing`).
- Boundaries of the age ladder, both sides: 0, 1, 59, 60, 120, 3599, 3600, 7200, 86399, 86400, 129599, 129600, 172800 s, and a timestamp 100000 s **ahead** of the clock.
- Count phrases at 0, 1 and 2 for every population member in both languages (`ac6.py`).
- Unicode: pure combining marks; ZWJ; CJK; U+2603; a lone-surrogate tag; a filesystem name carrying an undecodable byte; an environment value carrying an undecodable byte.
- Encodings: UTF-8; `ascii` via `PYTHONUTF8=0 LC_ALL=C`; `latin-1` via `PYTHONIOENCODING` (a codec that encodes *part* of the data); `PYTHONIOENCODING=ascii` against a document with non-ASCII.
- Streams: a real file; a real pipe; stdout and stderr to one file; a closed stdout (`>&-`); a broken pipe at 4000 nodes and at 1.5 MB.
- Max size: a 10 MB Clash `mode`; a 1.5 MB `config.json`; a child writing 240 KB (≫ one pipe buffer).
- Concurrency: three `sc status` processes appending to one file.
- Injection: CSI `ESC[31m` + `ESC[0m` + CR in `mode` and in the egress body; a 3-line `mode`.
- Non-`str` JSON at both `str()` sites: int, bool, object, null (RES-1).

## verify_all result

- command: `bash /home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` (repository root, C-12)
- total checks: 18 → 18 (no check added, none removed; out-of-scope 4/10)
- pass: 17 (baseline 17)
- fail: 0 (baseline 0)
- warn: 0 (baseline 0)
- skip: 1 (B.3 lint, baseline 1)
- runs: 3 of 3 identical
- new tests added: 0 committed — out-of-scope 10 and the frozen set forbid a committed test or fixture; 14 independent QA reproducers live outside the repository
- baseline updated: **no** — `.harness/scripts/baseline.json` is in the design's frozen set, out-of-scope 10 forbids changing it, and the test count did not rise
- operator obligation appended: **no** — no criterion required root, a live service or a network; nothing was reported BLOCKED
- git diff --numstat (product): `bin/sc` 80/41 · `README.md` 6/6 · `README.zh-CN.md` 1/1 · `docs/dev-map.md` 12/5

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| QA-1 | MINOR | The mandated loader recipe's bare `open("bin/sc").read()` decodes with the **locale** codec, while CPython reads a script as UTF-8 by default (PEP 263). Under the very environment AC-9 / AC-10 / RES-3 require it cannot load `bin/sc` at all: `LC_ALL=C PYTHONUTF8=0 python3 -c 'open("bin/sc").read()'` → `UnicodeDecodeError: 'ascii' codec can't decode byte 0xe2 in position 29`. My harness added `encoding="utf-8"`; the recipe should carry it, or the next locale test will read the failure as a harness bug. | `docs/dev-map.md:136` |
| QA-2 | MINOR | `04_DEVELOPMENT.md`'s K-6 resolution says `t(label)` = "16 static labels (9 sections ∪ 7 probe row labels)". Independent enumeration of `rows.append((cls, <label>, …))` finds **6** static probe labels (`sing-box version`, `sing-box check`, `boot autostart`, `Clash API responding`, `node delays`, `DNS lookup`), i.e. **15** static labels, **18** with `DOCTOR_MARK`'s three. All 18 are in the `zh` table, so AC-4's verdict is unaffected; the recorded number is not. | `bin/sc:2976-2986`, `04_DEVELOPMENT.md` FR-3 block |
| QA-3 | MINOR | The 28th `bin/sc` hunk — the `_age_text` docstring line `36 hours reads "1 day(s) ago"` — is named by **no** `L-` row and by **no** `DD-3` comment block, so `04_DEVELOPMENT.md`'s "the four edited regions" enumeration is short by one. Correct, non-executable and consequent on I-4; measured to change nothing (build X). `git diff -U0 bin/sc \| grep '^@@'` shows all 28. | `bin/sc:1059` |
| QA-4 | MINOR | `.harness/operator-obligations.md` row **4**, step R-5 tells the operator that under a non-UTF-8 locale `sc add` "will still exit non-zero — that is T-25's residual (`bin/sc:2345` prints an sc-authored `U+2192` to a strict stdout)". T-25 closes it: measured, `LC_ALL=C PYTHONUTF8=0 sc add …` prints `Added: NEW-ASCII (vless → 9.9.9.9:443)` and exits **0**. Stale guidance. Not edited by me — ids are permanent and the row is T-23's; PM's call whether to mark it in place. | `.harness/operator-obligations.md` row 4 |
| QA-5 | MINOR | RES-3 / `docs/dev-map.md:78` state that `backslashreplace` costs byte fidelity because an undecodable-byte value "used to round-trip to its original bytes". On **both** named instances that is unobservable on the shipped HEAD: under `LC_ALL=C PYTHONUTF8=0` HEAD aborts before reaching either line — `sc update-rules` at `↓` (`UnicodeEncodeError: '↓' in position 2`, HEAD `bin/sc:3307`) and `sc doctor` at `—` (`'—' in position 34`), printing 0 and 15 lines respectively. The candidate half is confirmed on both routes. The cost is real against a *future* reader, never against today's; the row should say so or a reader will hunt a regression that never shipped. | `docs/dev-map.md:78` |

No BLOCKER, no CRITICAL, no MAJOR. Nothing is BLOCKED; no criterion needed root, a live service or
a network, so no row is filed against an unreachable host.

## Stability

- The three English screens (`sc ls`, `sc status`, `sc doctor`) were run **10 times** on the candidate at a fresh fixture each time: **0 flakes**, every run byte-identical to the first outside the C-9-declared line.
- The C-9-declared variable line was in fact invariant across all ten: `[PROBLEM] DNS lookup: api.ipify.org returned no records after 0 ms …` ×10.
- `verify_all` ran **3 times** from the repository root: PASS 17 / WARN 0 / FAIL 0 / SKIP 1 every time.
- 142 harness runs, 142 `[C-1] VERDICT OK`, 0 `VOID-RUN`; no run was taken before the assertion was in place, and none was reported before it passed.
- No test in this report is named as flaky.

## Verdict

APPROVED FOR DELIVERY
