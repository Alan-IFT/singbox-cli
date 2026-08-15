> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

# T-25 — output-layer-contract · Development

## Summary

1. `bin/sc`'s output contract now has its two designed homes and nothing else: the string layer
   (five identifier keys replaced by their English headings, one new separator entry, four age
   keys and six byte keys made invariant) and **one** guarded `io.TextIOWrapper` statement at the
   top of `main()` (`bin/sc:3706-3708`) that buys write-order fidelity and encode survival together.
2. Four `cmd_status` values that `sc` did not author now go through the existing `_plain()`
   (`bin/sc:2448, 2451, 2456, 2458`); no new function, no new file, no new concept was added.
3. `README.md`'s English `sc ls` sample is a verbatim capture of the built `bin/sc`; **both**
   READMEs' `sc config > current.json` sentence is narrowed to BC-8's condition (C-6), and
   `docs/dev-map.md` states the key convention and the stream discipline — what it buys **and**
   what it costs. `verify_all` is PASS 17 / WARN 0 / FAIL 0 / SKIP 1 — the task-start baseline.

## C-1 — the safety-floor precondition (recorded before any V-step result)

`sc._init_files` is **rebound** by the harness immediately after the module `exec` and before any
command runs, to a replacement that makes `CFG_DIR` / `RULES_DIR` and a `<root>/var-lib-sing-box`
stand-in — all inside the `mkdtemp()` root — and seeds through `save_nodes()` / `save_settings()`.
`bin/sc:544`'s `Path("/var/lib/sing-box").mkdir` (HEAD `:532`) is executed on no path of any run in
this document. The loader itself is `docs/dev-map.md:121-158`'s mandated recipe — the `os` module
shim that keeps `bin/sc:125-126`'s auto-elevate branch untaken, restored in a `finally` — with all
eight path constants repointed into the `mkdtemp()` root and asserted, and `SYSTEMD = OPENRC =
False`. The assertion has two halves and both ran on **every** run recorded below;
`04_RATIONALE.md` §1 carries the mechanism and one process error of mine that a re-run repaired.

Assertion output, one run, verbatim (rule 70 — five lines; every other run's is identical apart
from the root):

```
[C-1] loader = docs/dev-map.md:121-158 recipe; _init_files neutralised=True (bin/sc:541-552 never run)
[C-1] eight path constants inside <scratch>/fixture-root: OK
[C-1] protected paths after the run:
  /var/lib/sing-box  UNCHANGED before=('PRESENT',1785387564302353878,…,['cache.db']) after=(identical)
  /etc/sing-box      UNCHANGED before=('PRESENT',1786421637458351383,…,[6 entries])  after=(identical)
```

Both protected paths **exist** on this host and are root-owned, so the witness
(`exists, st_mtime_ns, st_ctime_ns, sorted(listdir)`, taken before the run and again from an
`atexit` hook) is a real observation rather than "absent before, absent after". No run created or
wrote either path; no run touched the live service; no credential byte appears in this document.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `bin/sc` | `import io` (`:8`); the stdout configuration as `main()`'s first executable statement, guarded on `getattr(sys.stdout, "buffer", None)` (`:3705-3708`), under an 8-line comment (`:3697-3704`) that names the arguments and points at their one home in `docs/dev-map.md` | L-1 (I-1) |
| `bin/sc` | `TRANSLATIONS["zh"]`: five `ls.*` keys → `#` / `On` / `Type` / `Name` / `Address` (`:249-253`, values untouched) and their comment block restated as the convention (`:244-248`); four age keys → `(s)` (`:226-229`); six byte keys → `byte(s)` (`:213, 232, 233, 294, 296, 366`); one **new** entry `"{reason}, {age}"` (`:301`) | L-2 (I-3…I-6) |
| `bin/sc` | call sites of those keys: `:1064-1068` (`_age_text` unit tuple + tail), `:1212`, `:1216`, `:1549`, `:2315-2316` (`sc ls` heading row), `:2603`, `:2606`, `:3356`, and `:2439-2440` (the `sc status` rule-set line adopts I-6, `%-20s %s`) | L-3 (I-2) |
| `bin/sc` | FR-8: four `cmd_status` values through the existing `_plain()` — `:2448` active tag, `:2451` Clash `mode`, `:2456` egress body, `:2458` `{e}` | L-4 |
| `bin/sc` | Review-directed corrections to three **existing** comments; no executable line touched (proof below). `_egress_ip()`'s docstring (`:470-475`) no longer claims the value is printed verbatim and that no scrubbing happens in here — both consumers spell the identical `_plain(_egress_ip())` at `:2456` and `:2886` (CR-2). `cmd_config`'s `os._exit` rationale (`:3151-3158`) no longer claims "this process holds no other buffered stream", and states the two-wrappers fact plus its one home instead (CR-3). `cmd_config`'s docstring (`:3102-3105`) carries the same JSON condition the two READMEs now publish (CR-1, third home of one sentence). Inside that `os._exit` block, "Since main()'s re-wrap that message would come TWICE" now reads "Since main()'s re-wrap **landed**, that message would come TWICE", rewrapped within the same five lines (CR-12) | — (CR-1/2/3, CR-12) |
| `README.md` | `:93-99`'s English `sc ls` sample replaced by a verbatim capture of the built `bin/sc` (K-7); surrounding prose unchanged; `:297` **narrowed** to BC-8's condition (C-6) | L-5 |
| `README.zh-CN.md` | `:297` narrowed symmetrically with `README.md:297` — the PM's frozen-set release is **used**. `:94`'s `sc ls` sample stays frozen and byte-identical (out-of-scope 5); nothing else in the file is touched | L-5 (PM release) |
| `docs/dev-map.md` | the translation-key bullet restated as the convention (`:91-99`); one new `## Reusable utilities` row for the stream statement (`:78`), now carrying what `backslashreplace` **costs** — as a class (every OS byte interface: filesystem names, `os.environ`, `sys.argv`) with two instances, CR-11 — and the two-wrappers fact (CR-9, CR-3); one clause on the `main()` row (`:42`); `:71` no longer says `sc status` prints the egress value verbatim (CR-2) | L-6 (I-7, I-8) |
| `.harness/rejected-decisions.md` | **not touched** — stage 2 wrote it, the PM corrected it in place per C-11 | L-7 |

**Proof that the comment corrections changed no behaviour** (they are the only `bin/sc` edits made
after the V-steps ran): `tokenize` over the shipped file reports, for each edited region, only
non-executable token kinds — `:465-476` `STRING`+`INDENT`/`NEWLINE` (one docstring), `:3100-3106`
`STRING`, `:3151-3158` and `:3697-3704` `COMMENT`+`NL`. `python3 -W error` compiles clean. The
`sc config` capture re-taken after the edits is `cmp`-identical to the one taken before them, and
the `t()` enumeration is unchanged (206 / 203 / 160 / 0 offenders). CR-12's wording fix is one
further edit inside the **same** region: `:3155-3158` tokenizes as `COMMENT`+`NL` only, the compile
is clean, `bin/sc`'s numstat is unchanged at 80/41 (five comment lines rewrapped into five), and
the two grep literals `.harness/scripts/restricted-network-regression.sh:284` counts are intact
(`OK (` at `:213`/`:3356`, `failed: {e}` → `失败：{e}` at `:214`/`:3370`). No rendered string, key,
format string or executable line moved in round 3.

## verify_all result

```
baseline (task start, repository root): PASS 17 · WARN 0 · FAIL 0 · SKIP 1
after    (same invocation, same cwd):   PASS 17 · WARN 0 · FAIL 0 · SKIP 1
delta:                                  0 new FAIL · 0 new WARN · 0 test removed
command: bash /home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh   (from the repo root)
git diff --numstat (mine): bin/sc 80/41 · README.md 6/6 · README.zh-CN.md 1/1 · docs/dev-map.md 12/5
                           4 files changed, 99 insertions(+), 53 deletions(-)
```

Verification-plan results — every step ran on the fixture described in `04_RATIONALE.md` §1, with
C-1's assertion in place. `cand` = the working tree, `head` = a pristine `git clone` at
`6c034d62` run at the **same** fixture path (C-12); no `git worktree` anywhere.

```
V-1  AC-1  PASS  en heading row = `#` `On` `Type` `Name` `Address` `Delay`; no heading contains `.`
V-2  AC-2  PASS  zh heading row 序号/激活/协议/名称/地址/延迟 — `diff head cand` empty (byte-identical)
V-3  AC-3  PASS  gutters [4:6][8:10][20:22][52:54][79:81] all "  " on heading + 4 data rows
                 control: HEAD FAILS at three gutters ('dx', 'ls', 's.') — the defect is detected
V-4  AC-4  PASS  see the enumeration block below; OFFENDERS 0 on HEAD and on the candidate
V-5  AC-5  PASS  0s/1s/60s/120s/3600s/7200s/86400s/129600s/172800s, both languages: 1-unit and
                 2-unit forms differ only by the number; 36 h reads `1 day(s) ago` / `1 天前`
V-6  AC-6  PASS  14 population members × counts 0/1/2 × 2 languages = 84 renderings, one form each
V-7  AC-7  PASS  zh: `可用，1 小时前` (status) and `可用，64 字节，1 小时前` (doctor) — same `，`
                 en: `usable, 1 hour(s) ago` and `usable, 64 byte(s), 1 hour(s) ago` — same `, `
                 control: HEAD status renders `可用, 1 小时前` (ASCII comma) against doctor's `，`
V-8  AC-8  PASS  every heading above its child's output, to a real file AND to a real pipe
                 control: HEAD prints CHILD<systemctl> + CHILD<ip> as lines 1-2, headings below
V-9  AC-9  PASS  proof: stdout encoding=ascii, getpreferredencoding()=ANSI_X3.4-1968, PYTHONUTF8=0
                 `sc ls` whole table + exit 0; `sc add` prints `Added: NEW-ASCII (vless → …)`
                 + exit 0; no traceback. control: HEAD aborts UnicodeEncodeError ● / →, exit 1
V-10 AC-10 PASS  CJK tag: 3 data rows printed, exit 0 unchanged; no claim made about glyphs
                 control: HEAD aborts on that row (`can't encode characters in position 22-23`)
V-11 AC-11 PASS  census below — 104 rendered forms per language, 0 introduce either literal
V-12 AC-12 PASS  `sc status` route mode with CSI+CR prints `globalREDX`; the egress value class
                 (the one BOTH screens carry) is identical on both: `203.0.113.7RED`
                 control: HEAD status prints `global^[[31mRED^[[0m^MX`; doctor already neutralised
V-13 AC-13 PASS  a 3-line mode occupies exactly 3 lines under its heading; sc adds none
V-14 AC-14 PASS  `reload`/`status`/`doctor`/`ls` en differential: 22 changed lines, every one inside
                 I-2…I-6 plus FR-6's reordering; `sc reload` byte-identical; see C-9 for the pinning
V-15 AC-15 PASS  README block == fresh capture of the shipped build: True (character by character)
V-16 AC-16 PASS  `git diff --stat .harness/scripts/check-i18n-parity.sh` empty; verify_all as above
BC-6       PASS  `sc ls >&-`: sys.stdout is None, guard's false arm, nothing raises, exit 0 on both
V-17 C-6   PASS  the CR-1 measurement — see the C-6 row; candidate exit 0 with a document
                 `json.loads` REJECTS, HEAD `UnicodeEncodeError` exit 1, on both preconditions
```

FR-3 / K-5 / D-1 enumeration (`ast`, every `Call` with `func == Name('t')`, first argument resolved
when a string constant, everything else reported by line), re-run from the repository root against
the **shipped** candidate and against HEAD before any string was edited:

```
HEAD:      205 call sites | 202 resolved (159 distinct keys) | 3 UNDECIDABLE @ 1054, 2978, 2978
           182 zh keys | OFFENDERS 0 | identifier-shaped keys in the table: 5 (the five `ls.*`)
candidate: 206 call sites | 203 resolved (160 distinct) | 3 UNDECIDABLE @ 1067, 2999, 2999
           183 zh keys | OFFENDERS 0 | identifier-shaped keys: 0
K-6 resolved by name: :1067 t(key)=_age_text's 3 unit literals · :2999 t(DOCTOR_MARK[cls])=OK/
  UNKNOWN/PROBLEM · :2999 t(label)=16 static labels (9 sections ∪ 7 probe row labels), all present,
  plus rule-set filenames (`bin/sc:2607`), which are data and correctly absent from TRANSLATIONS
```

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| DD-1 | I-1's argument list (`encoding`, `errors`, `line_buffering`) | `newline="\n"` added as a fourth argument (`bin/sc:3707`) | C-10 authorises stating it explicitly. `TextIOWrapper`'s write side translates `"\n"` through `os.linesep` when `newline` is `None`, so `docs/dev-map.md`'s "non-TTY output must contain no `\r`" would rest on a library default rather than on the statement that claims to own the stream. Byte-identical on Linux; one keyword, no new machinery. Upheld at review, and more strongly than filed: CPython builds the real `sys.stdout` with an explicit `newline="\n"`, so omitting it would have *replaced* a pinned `\n` with a platform-dependent one. |
| DD-2 | L-4's "route the value through `_plain()`" at `:2448` / `:2451` | `_plain(str(value))` rather than `_plain(value)` | `_plain()` calls `text.replace(...)` and so requires `str`, while the two values are arbitrary JSON — `nodes.json`'s `active` is only shape-checked at the top level, and `clash_api()` promises a JSON object, not a string `mode`. Without `str()` a hand-edited `nodes.json` or an odd Clash body turns HEAD's printed value into a `TypeError` traceback, i.e. a **new** failure mode. `str()` is the idiom the design already blesses at `:2458` (`_plain(str(e))`). `:2456` matches `_doctor_egress` exactly (`_plain(_egress_ip())`, no `str()`), because `_egress_ip()` returns `str` by contract. |
| DD-3 | L-2 rewrites the comment block at `:244-248` (4 lines → 5) | **five** further comment blocks, **20** lines, none of them named by any L-row: the age ladder (`:224-225`, 2), the new `{reason}, {age}` entry (`:298-300`, 3), the `%-20s` pad in `cmd_status` (`:2436-2438`, 3), the four `_plain()` routes in `cmd_status` (`:2444-2447`, 4) and the stream statement in `main()` (`:3697-3704`, 8) | FR-1's deliverable is a *convention*, and the convention has to be readable where the keys are; `bin/sc`'s prevailing style states every non-obvious invariant at its site. No code, no concept. **Honest size input for rule 85** (the round-1 record undercounted this by 3×, CR-4; `:2436-2438` appeared in no row at all): `bin/sc`'s diff is +80/−41 lines, of which `#` lines are **+33/−9** — 20 in the five blocks above, 5 in the ledger-named block that replaced 4, and 8 in the `os._exit` block corrected under CR-3. Two docstrings account for a further +9/−2 prose lines. The stream-statement block is 8 lines rather than round 1's 15: CR-5's ruling is that the five clauses have one home (`docs/dev-map.md:78`) and the site keeps a pointer, not a copy. |

## Condition disposition

| gate condition | disposition | evidence |
|---|---|---|
| C-1 | **DISCHARGED** | `## C-1` above: `_init_files` **and** the auto-elevate `execvp` neutralised before every run, `NEUTRALISED=True` printed per run; eight-constant assertion + before/after witness of `/var/lib/sing-box` and `/etc/sing-box` on every run, both UNCHANGED. No V-step result predates it. |
| C-2 | **DISCHARGED** | Capture object per step — V-8: a real **file** (`out/v14.cand.status.out`) and, repeated, a real **pipe** (`… \| head -6`); V-9 `sc ls` / `sc add`: a real file per build; V-10 and V-17: a real file. No `StringIO`, no `redirect_stdout` anywhere in the harness, so K-3's guard takes its true arm and the assertions are made against the **wrapped** stream. Each run prints `stdout='TextIOWrapper' encoding=… isatty=False`. |
| C-3 | **PREPARED for stage 6** | AC-12's comparison clause is confirmed NOT-DISCRIMINATING as written (`sc doctor` prints no routing mode; `_doctor_clash` reads `/configs` only to test `answer is None`). Re-pointed at a value class **both** screens carry for the same input — the egress body (`bin/sc:2456` vs `:2886`): one injected `203.0.113.7\x1b[31mRED\x1b[0m\r` renders `203.0.113.7RED` on both, identical; HEAD's `sc status` renders the raw sequence and `^M`. The `sc status` half of the criterion is carried separately (V-12). No upstream document was edited. RES-1 (the `str()` guard against a non-`str` `mode`) travels to stage 6 unmeasured here. |
| C-4 | **DISCHARGED** | `=== Route mode ===` printed **once** on candidate and **once** on HEAD (`grep -c` = 1 on both) before anything under it was asserted. `sc.SYSTEMD = True`; the `subprocess.run` stub returns `CompletedProcess(cmd, 0)` for `is-active` (so `is_running()` is `True` without touching the live service) and spawns a real `/bin/echo` child on the inherited fd 1 otherwise; `clash_api_port` is in the **fixture's own `settings.json`**, because `main()` reassigns `CLASH_PORT` after import. |
| C-5 | **DISCHARGED** | The auto-group address cell and the three delay values come from `stored_delays()` answering an **in-process `http.server` Clash responder** (`/proxies` → `auto.now = "JP-2"`, histories 141 / 210 / 141 / none) reached because `SYSTEMD=True` makes `is_running()` true and the port is in `settings.json`. The capture therefore really shows `→ JP-2` / `141 ms` / `210 ms` / `141 ms` / `-`, exactly K-7's node list; no Delay cell is `-` where the sample shows a number. AC-15 is reported satisfied on that capture, pasted verbatim with full column widths. |
| C-6 | **DISCHARGED — door one taken: both published sentences narrowed** | Round 1 took door two and discharged this per sentence, on the claim that BC-8's silent-corruption mode is *structurally* unreachable through `sc config`. That claim is **false as stated**, and I refuted it by measurement rather than deferring to the reviewer. It holds only under two preconditions the round-1 record did not state. **(a) `PYTHONIOENCODING` unset.** `Path.read_text()` uses `locale.getpreferredencoding(False)`; `sys.stdout.encoding` is resolved from `PYTHONIOENCODING` **first**. Measured on this UTF-8 host with `PYTHONIOENCODING=ascii` and one `config.json` carrying U+00E9 / U+65E5 / U+1F1EF U+1F1F5: **candidate exits 0** with 269 pure-ASCII bytes that `json.loads` **REJECTS** — `Invalid \escape: line 8 column 18` — because `backslashreplace` emitted `\xe9` and `\U0001f1ef`, which are not JSON escapes (`日` coincidentally is); **HEAD aborts** `UnicodeEncodeError: 'ascii' codec can't encode character '\xe9'`, exit 1, 0 bytes on stdout. **(b) `bin/sc:3113`'s bare `read_text()` unrepaired** — the very defect this document files as worth a pool row. Counterfactual measured, `LC_ALL=C PYTHONUTF8=0` with **no** env var set and `CFG_PATH.read_text()` given the explicit UTF-8 decode T-23 gave `settings.json` / `nodes.json`: candidate exit 0 / 269 bytes / `json.loads` REJECTS, HEAD aborts. So repairing an unambiguously good thing falsifies the published sentence in the **default** environment. Per the PM's binding scope ruling both sentences take BC-8's narrowing: `README.md:297` and `README.zh-CN.md:297` are rewritten symmetrically — the condition (stdout's encoding can represent the document), what happens instead (a backslash escape at exit 0, and `\xNN` / `\UNNNNNNNN` are not JSON escapes), and the remedy (a UTF-8 stdout). The `README.zh-CN.md` frozen-set release is **used**; `README.zh-CN.md:94`'s `sc ls` sample stays frozen and is byte-identical after this task. The same condition is stated once more where the code makes the promise (`bin/sc:3102-3105`). `04_RATIONALE.md` §4. |
| C-7 | **DISCHARGED** | The census below, reproduced per key against the **rendered** forms of the build I produced (not cited from the gate), including every `_status_text` × `_age_text` substitution. `OK (` survives verbatim (`OK (99 byte(s))`), and `failed: {e}` / `失败：{e}` are untouched — both are what `.harness/scripts/restricted-network-regression.sh:284` counts with `grep -cF`. No round-2 edit touches a rendered string, so the census is unchanged. |
| C-8 | **DISCHARGED** | The population table below records one membership test, each member's reachable minimum count, and every exclusion with the clause that excluded it. F-8's two tests are collapsed into one sentence in `04_RATIONALE.md` §3. |
| C-9 | **DISCHARGED** | Declared before V-14 ran: the **only** line variable by construction on this fixture is `sc doctor`'s `{name} resolved in {ms} ms`. Everything else was pinned, not tolerated: rule-set mtimes at `now − 5000 s` (→ `1 hour(s) ago`, boundary at 7200 s), `_egress_ip` stubbed to a constant, the Clash port in `settings.json`, one in-process responder with fixed bodies, a `subprocess` stub returning fixed bytes, `sc reload` run first so the drift row reads `matches`, one fixture path for both builds. In the event the declared line read `0 ms` on both builds and did not appear in the diff. |
| C-10 | **DISCHARGED** | `newline="\n"` is stated **explicitly** (DD-1). `TextIOWrapper` with `newline=None` translates `"\n"` through `os.linesep` on write; pinning it is what keeps the no-`\r` invariant a property of the statement rather than of the host. Verified in the captures: every non-TTY file above contains no `0x0D` (`cat -A` shows `$` line ends only). |
| C-11 | **NOT MINE, NOT TOUCHED** | `.harness/rejected-decisions.md` was corrected in place by the PM; I added no second record and made no edit to that file, in either round. |
| C-12 | **DISCHARGED** | `verify_all` invoked only from the repository root (full counts above), re-run after the round-2 edits. AC-9/AC-10 environment is `PYTHONUTF8=0 LC_ALL=C PYTHONCOERCECLOCALE=0` with the proof recorded per run: `encoding=ascii preferred=ANSI_X3.4-1968`. V-17's environment is recorded the same way (`encoding=ascii errors=strict PYTHONIOENCODING='ascii'`). Every differential baseline is a pristine `git clone` (`git status --porcelain` empty) run at the same fixture path; no `git worktree` was created. |

**C-7 — the `失败：` / `failed: ` census.** One row per added or edited string, both languages,
rendered (not keys). `{reason}` was substituted with all five `_status_text` values and `{age}`
with all six `_age_text` forms, so the three composite rows are 30 renderings each: **104 rendered
forms per language, 208 in total, 0 containing either literal.**

| # | added/edited string | rendered en | rendered zh | `失败：` | `failed: ` |
|---|---|---|---|---|---|
| 1 | `#` | `#` | `序号` | no | no |
| 2 | `On` | `On` | `激活` | no | no |
| 3 | `Type` | `Type` | `协议` | no | no |
| 4 | `Name` | `Name` | `名称` | no | no |
| 5 | `Address` | `Address` | `地址` | no | no |
| 6 | `Delay` (key unchanged, listed for the set) | `Delay` | `延迟` | no | no |
| 7 | `{n} second(s) ago` | `1 second(s) ago` | `1 秒前` | no | no |
| 8 | `{n} minute(s) ago` | `1 minute(s) ago` | `1 分钟前` | no | no |
| 9 | `{n} hour(s) ago` | `1 hour(s) ago` | `1 小时前` | no | no |
| 10 | `{n} day(s) ago` | `1 day(s) ago` | `1 天前` | no | no |
| 11 | `OK ({size} byte(s))` | `OK (1 byte(s))` | `成功（1 字节）` | no | no |
| 12 | `{done} byte(s)` | `1 byte(s)` | `1 字节` | no | no |
| 13 | `truncated: got {got} of {declared} byte(s)` | `truncated: got 1 of 1 byte(s)` | `传输不完整：收到 1/1 字节` | no | no |
| 14 | `{reason}, {size} byte(s), {age}` (30 forms) | `usable, 1 byte(s), 0 second(s) ago` … | `可用，1 字节，0 秒前` … | no ×30 | no ×30 |
| 15 | `{reason}, {size} byte(s), {age} — run …` (30 forms) | `usable, 1 byte(s), 0 second(s) ago — run …` … | `可用，1 字节，0 秒前 —— 运行 …` … | no ×30 | no ×30 |
| 16 | `larger than {n} byte(s)` | `larger than 1048576 byte(s)` | `超过 1048576 字节` | no | no |
| 17 | **new** `{reason}, {age}` (30 forms) | `usable, 0 second(s) ago` … | `可用，0 秒前` … | no ×30 | no ×30 |

The five `_status_text` substitutions are `usable/missing/not a rule-set file/file too small/
unreadable` ↔ `可用 / 缺失 / 不是规则集文件 / 文件过小 / 无法读取`; the six `_age_text` ones are the four
`(s)` phrases plus `last update unknown` ↔ `更新时间未知`. None contains `失败`. Unchanged and still
meaning "this rule-set file was not updated": `failed: {e}` → `失败：X` (`bin/sc:214`, emitted at
`:3370`). Unchanged and still greppable: `OK (` (`bin/sc:213`, emitted at `:3356`).

**C-8 — the AC-6 count-phrase population.** One test, stated in `04_RATIONALE.md` §3 and applied
once: *a number substituted next to the noun it counts, not the numerator of a fraction, whose
**family** has a reachable value contradicting the noun's number.* Derived mechanically from all
33 `TRANSLATIONS` keys matching a placeholder followed by a word.

| member | reachable minimum count | admitted by | edited? |
|---|---|---|---|
| `{n} second(s) ago` | 0 (`delta` is floored at 0) | form + family reachable at 1 | yes |
| `{n} minute(s) ago` | 1 (60 s) | same | yes |
| `{n} hour(s) ago` | 1 (3600 s) | same | yes |
| `{n} day(s) ago` | 1 (86400 s) | same | yes |
| `OK ({size} byte(s))` | 16 (`SRS_MIN_BYTES` floor at this site) | family reachable at 1 | yes |
| `{done} byte(s)` | 1 (a one-byte first chunk) | form + reachability | yes |
| `truncated: got {got} of {declared} byte(s)` | 1 (`{declared} == 1`; no slash in English) | form + reachability | yes |
| `{reason}, {size} byte(s), {age}` | 0 (a readable empty `.srs` has a real `0`) | form + reachability | yes |
| `{reason}, {size} byte(s), {age} — run …` | 0 (same) | form + reachability | yes |
| `larger than {n} byte(s)` | 1048576 (`OVERRIDE_MAX_BYTES`, sole site `:1549`) | **family** reachability — this is F-8's row, and the family test is what admits it | yes |
| `{n} ruleset(s) failed to update` | 1 (`len(failed) ≥ 1` guards it) | form + reachability | no — already invariant |
| `... {n} more line(s) not shown` | 1 | form + reachability | no — already invariant |
| `{n} path(s) grant access to group or other …` | 1 | form + reachability | no — already invariant |
| `{n} path(s) could not be judged — see below` | 1 | form + reachability | no — already invariant |

Excluded, each by the clause named:

| excluded | clause |
|---|---|
| `{done}/{total} bytes ({pct}%)`, `{n}/{total} rule-sets unusable …` (×2), `{n}/{total} usable`, `{n}/{total} nodes carry a stored delay …`, `0/{total} nodes …` | **fraction** clause (Q-7): the noun follows a fraction and is correct for every value |
| `{name} resolved in {ms} ms`, `{name} returned no records after {ms} ms`, `no answer for {name} after {ms} ms`, and `sc ls`'s `f"{delays[tag]} ms"` (not a key) | **unit-symbol** clause (K-9): `ms` is invariant, no form asserts a number |
| `at {at}: {name} matched {count} elements, …` | **family reachability**: a family of one, and the raise happens only when `len(hits) != 1`, so `1` is unreachable — R-72's line, untouched |
| `{iface} does not exist`, `{path} is mode {mode}`, `{path} is a symbolic link…`, `{path} was modified outside sc…`, `a symbolic link whose target {target}…`, the six `at {at}: …` directive sentences, `Uninstall script not found: {script}…` | **not a count**: the placeholder is not a number |

## Open issues for review

- **`cmd_config` decodes `config.json` with the locale's codec** (`CFG_PATH.read_text()`,
  `bin/sc:3113`) — the same defect T-23 closed for `settings.json` / `nodes.json`, surviving in a
  third reader. Under `LC_ALL=C` a `config.json` holding any non-ASCII byte cannot be read at all
  (one stderr line, exit 1), on HEAD and candidate alike. Out of this task's scope, and worth a
  pool row **with the coupling attached** (RES-6): repairing this line is what makes the newly
  narrowed `README*.md:297` sentence's *condition* bite in the default environment, so the repair
  carries a documentation change with it. `bin/sc:1668` (`IF_INET6_PATH`), `:2016` (`STATE_PATH`)
  and `:2704` (`_doctor_ipv6`) are the same family.
- **CR-10 — disposition: both `README*.md:297` sentences stay as written; not rewritten.** The
  reviewer is right that of the two causes they name, only `PYTHONIOENCODING` set to a narrower
  codec is reachable through `sc config` **today**: under a non-UTF-8 locale `CFG_PATH.read_text()`
  (`bin/sc:3113`) fails first, exit 1 with `cannot read …`, so the run does end — my own `LC_ALL=C`
  measurement reached the escape path only in the counterfactual carrying that repair
  (`04_RATIONALE.md` §4(b)). Of the reviewer's two acceptable doors the PM takes the second: the
  sentences are written for the **post-repair** world, the parenthetical becomes true the moment the
  filed `cmd_config` row lands, and narrowing them now would mean widening them back then. The duty
  that travels with RES-6 is therefore to **verify** these two sentences, not to change them.
- **The `backslashreplace` give-up is now recorded where it survives delivery** — one clause on
  `docs/dev-map.md:78` carrying the **class and two instances** (CR-9 / CR-11 / RES-3). Under
  `LC_ALL=C` CPython gives stdout `errors=surrogateescape` (measured) and decodes *every* OS byte
  interface the same way, so the class is "an OS-supplied byte string reaching a printed line", not
  "a filename": besides `_doctor_permissions()`'s `{path}` rows (`CFG_DIR.iterdir()`), the reviewer's
  second route **holds** — `_ruleset_bases()` takes `--mirror` from argv or `SB_RULES_BASE`
  (`bin/sc:1129`), `cmd_update_rules` copies each base verbatim into `causes` (`:3346` dead-skip,
  `:3360-3361` real failure) and prints the joined list at `:3370`; the same value also reaches the
  success line's `fell back after:` note (`:3353-3356`). Such a value used to round-trip to its
  original bytes and now renders `\udcXX`. Excluded on the reviewer's list and **not** added:
  `RULES_DIR.iterdir()` (`:1148`, no name printed), `cmd_sysproxy` (`:3303`/`:3320` print `val`, not
  the env-derived `user`) and `_doctor_run`'s `errors="replace"` (`:2536`, `U+FFFD` — an FR-7
  improvement over HEAD's abort). Survival is unchanged or better in every case; no fix exists that
  is not machinery K-1 and rule 85 forbid.
- **Two extra stderr lines on the broken-pipe path.** `sc ls | head -2` at 4000 nodes raises
  `BrokenPipeError` from the same `print()` on **both** builds; the candidate additionally emits
  `Exception ignored in: <_io.TextIOWrapper …> BrokenPipeError` at finalisation, because two
  wrappers now sit over one `BufferedWriter`. Exit status and the traceback itself are unchanged.
  `sc config` is unaffected — its `os._exit(1)` (`bin/sc:3159`) skips finalisation, measured clean
  on a 1 MB document through `| head -5`. Now recorded on `docs/dev-map.md:78` (CR-3); R-45's pool
  row should carry the price (RES-4).
- **K-6 says "the ten `DOCTOR_SECTIONS` labels"; the tuple has nine** (`bin/sc:2976-2986`), and the
  `t(label)` universe is **16** distinct static labels once the probes' own row labels are added.
  Nothing depends on the number; recorded so stage 6 does not re-derive it.
- **Q-17 / D-4 is untouched and still open**, and CR-6 widens it: `Config check failed:\n{stderr}`
  renders `配置检查失败：…` (`bin/sc:136`) and `Error: applying timer failed: {err}` renders
  `错误：应用 timer 失败：{err}` (`bin/sc:145`) — the second carries **both** load-bearing literals.
  The pool row must name the family, not the one site (RES-5). Neither is in this task's edited set.
- **K-11 / D-6 confirmed live**: under a non-UTF-8 stdout an escaped tag is wider than the tag, so
  `sc ls`'s columns shift on that row (visible in V-10's capture). Expected, not a defect.
- **Schema gap (Q-16 / R-37, again).** `.harness/rules/70-doc-size.md` declares no
  `## Stage-doc boundary rule`, and this contract's schema has no section for verification-step
  results or for the two enumerations C-7 and C-8 require *in this document*. Applied as written:
  the V-step results are `key: value` lines under `## verify_all result`, and the two enumerations
  are tables inside `## Condition disposition` under the rows that own them. No section invented.

## Dev-map updates

- `docs/dev-map.md:91-99` — the translation-key bullet now states the convention in four binding
  clauses (key **is** its English rendering; same placeholder set in `zh`; field punctuation lives
  inside the string; a count phrase renders one invariant form; a missing `zh` entry is the
  designed fallback). It records no defect and names no `ls.*` key.
- `docs/dev-map.md:78` `## Reusable utilities` — one new row, "What makes a printed line ordered
  and encodable?", pointing at the single `io.TextIOWrapper` re-wrap in `main()`: what each
  argument buys, why `newline` is explicit, why it is not `reconfigure()`, why the guard exists,
  the `io.StringIO`-has-no-`.buffer` trap that makes a harness certify nothing, **what
  `backslashreplace` costs** — stated as the class (every OS byte interface the POSIX locale
  surrogate-escapes: filesystem names, `os.environ`, `sys.argv`) with two instances, the
  `_doctor_permissions()` `{path}` rows and the `SB_RULES_BASE` / `--mirror` base
  `cmd_update_rules` prints in its cause list (CR-11) — **that the re-wrap adds a second wrapper
  over one `BufferedWriter`** (safe at teardown, and the reason a broken pipe reports twice), and
  the closing rule. It is the single home; `bin/sc`'s site comment points here rather than
  restating it.
- `docs/dev-map.md:42` `main()` row — one clause: `sys.stdout` is configured **first**, before
  `parse_args()`, so nothing (`-h` included) can print ahead of it.
- `docs/dev-map.md:71` `_egress_ip()` row — "byte-faithful on purpose" now reads against what the
  code does: the bytes are returned unaltered and both consumers spell `_plain(_egress_ip())`.

## Insight to surface

- Under the POSIX locale CPython gives `sys.stdout` `errors='surrogateescape'`, not `strict`, so a non-ASCII string that arrives through `os.environ` under `LC_ALL=C` is silently surrogate-escaped and prints back as its original bytes — a "non-ASCII tag" fixture built that way passes on broken code, and only a tag transported as `\uXXXX` escapes makes the encoding defect observable · evidence: docs/features/output-layer-contract/04_RATIONALE.md §6(a)
- On the 3.6 floor one `io.TextIOWrapper(sys.stdout.buffer, encoding=sys.stdout.encoding, errors="backslashreplace", newline="\n", line_buffering=True)` at the top of `main()` buys write-order fidelity and encode survival together, and `sys.stdout.reconfigure()` is not available to buy either · evidence: bin/sc:3706-3708
- `sys.stdout.encoding` is resolved from `PYTHONIOENCODING` *before* the locale while `Path.read_text()` only ever asks the locale, so "the reader's codec is the writer's codec" is never a structural argument — `PYTHONIOENCODING=ascii` on a UTF-8 host makes `sc config` exit 0 with a document `json.loads` rejects (`\xe9` and `\U0001f1ef` are not JSON escapes) where HEAD aborted loudly · evidence: bin/sc:3113 vs bin/sc:3706

## Verdict

READY FOR REVIEW
