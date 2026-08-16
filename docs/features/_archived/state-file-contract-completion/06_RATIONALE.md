# T-29 · state-file-contract-completion — QA Rationale

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

## How every [B] row was driven

One `sc` command per child process (a fixture cannot call `main()` twice — the re-wrap leaves the
previous run's `io.TextIOWrapper` over the same `BufferedWriter`). The runner is `run_case.py` in the
session scratchpad, **not** committed. It loads `bin/sc` through `docs/dev-map.md`'s mandated recipe
**plus** `check-sc-contracts.py:100-123`'s exec-denial shim (every process-start name in `dir(os)`
raises, enumerated by name, not by prefix), repoints all **nine** path constants into a `mkdtemp`
root and asserts every `Path` attribute resolves inside it, sets `SYSTEMD = OPENRC = False`, replaces
`_init_files()` (it hard-codes `/var/lib/sing-box`), points `SB_BIN` at a stub exiting 0, then calls
`main()` once and lets `SystemExit` propagate.

Two default fixture stubs, named rather than hidden, because both would otherwise leave this
process: `clash_api()` → `None` (the single door to the Clash API) and `_egress_ip()` → raises (an
8 s HTTP request to `api.ipify.org` over the host's live routing). Neither is on any measured path.
"HEAD control" is a pristine **clone** (`git clone --no-hardlinks`) at `3a0ba42`, never a worktree,
its `bin/sc` verified byte-identical to `git show HEAD:bin/sc`. Mutants are scratch **copies** built
by `mutants.py`, each anchored on a unique string (the builder refuses if an anchor matches ≠ 1
time) and `py_compile`-checked; the shipped file is never edited.

## Safety, witnessed

- `systemctl show sing-box -p MainPID -p NRestarts -p ActiveState -p ActiveEnterTimestamp`, at the
  start and end of **all three** rounds, every reading identical: `MainPID=2566751 / NRestarts=0 /
  ActiveState=active / ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`. `systemctl is-active` was
  never invoked (the fixture's `is_running()` cannot reach it).
- `ls -la /etc/sing-box` at each session end, round 3 included: every entry's mtime is
  `2026-08-11 12:13` or earlier, `/var/lib/sing-box` `2026-07-30 12:59`. Nothing under either path
  was created, modified or removed; round 3 started no fixture process at all.
- `HARNESS_ALLOW_OUTSIDE_RM` was never set; two `guard-rm.sh` hook BLOCKs (heredoc composition) were rewritten through the editor, never overridden.
- No real credential appears in any fixture or in either document: node passwords are the
  two-character literal `pw`, hosts are `.invalid`.

## T6.x rationale reaches

- **T6.2** (reproducing a developer-claimed measurement), round 1: `04_RATIONALE.md`'s mutation
  transcript and locale probe were **not** read before the independent runs — the mutations were
  re-derived from `V-13`'s own text and the reproducers written from the AC text, per iron rule 2.
- **T6.2**, round 2: I *did* read `04_RATIONALE.md`'s E-18 transcript before writing mine —
  recorded plainly, not glossed. The driver was still written from AC-11 / V-11's text, differs
  from that probe in the four ways the AC-11 section names, and agrees with its boundary.
- **T6.1 / T6.3** never fired: every AC's verification step is fully specified by V-1…V-21, and
  CR-1 / RES-1 / RES-4 are self-contained in `05_CODE_REVIEW.md`. At round 3 no trigger fired at
  all — AC-14's verification step is a command and an exit status, and I read no rationale for it.

## Rounds 2–3: what was re-run, the one thing that regressed, and how it closed

The only files that moved between round 1 and round 2 are two README lines, three upstream
stage documents and `PM_LOG.md`. That the **product** did not move is measured, not assumed:
`diff <(sed '3408,3410d' bin/sc) qa/mutants/m_arm_collapsed` is empty and that mutant was cut from
the round-1 candidate, so the shipped `bin/sc` is byte-for-byte the file every round-1 row was
measured on. `check-sc-contracts.py`, `baseline.json` and `docs/dev-map.md` are unmodified since
round 1 (dev-map's coverage clause predates round 1's report and round 1 cited it; re-read clause
by clause anyway). Re-run in full at round 2: AC-5, AC-11, AC-14, AC-18, AC-19. In part: AC-9
(candidate arm), AC-13 (`m_arm_collapsed`), AC-17 (`--numstat` + A.1). Carried: AC-1…AC-4,
AC-6…AC-8, AC-10, AC-12, AC-15, AC-16.

`verify_all`, from the repository root, three consecutive invocations at round 2 — **not green**:

```
[A.1]…[B.2] PASS · [B.3] Lint ... SKIP · [B.4] bin/sc contract assertions ... PASS · [B.5] PASS
[E.1]…[E.6] PASS · [F.1]…[F.5] PASS · [F.6] Active task docs <=500 lines each ... WARN
=== Summary ===  PASS: 18  WARN: 1  FAIL: 0  SKIP: 1        exit 1   (identical on all three runs)
```

F.6's own predicate, re-run by hand (`find docs/features … -name 'PM_LOG.md' -o -name '0[1-7]_*.md'`,
`wc -l`, cap 500), named exactly one file: `PM_LOG.md:550`. `verify_all` exits 1 on any WARN
(`verify_all.sh:270`), so AC-14's "exit 0" was not met and D-2 was filed. Rule 70's Rule 2 makes
PM_LOG compaction PM-owned and forbids delegating it to an agent reading the file: routed, not
fixed, and nothing was edited to make the gate green.

**Round 3 is that one criterion and nothing else.** The PM compacted the log at a stage boundary
(stages 1–4 to one-line summaries, stages 5–6 kept whole, `550 → 203`); I re-ran the gate myself
rather than take the number — five consecutive invocations, all 21 check lines identical:

```
[B.4] bin/sc contract assertions ... PASS   [F.6] Active task docs <=500 lines each ... PASS
=== Summary ===  PASS: 19  WARN: 0  FAIL: 0  SKIP: 1        exit 0   (identical on all five runs)
```

F.6's predicate re-run by hand again, since the check still names no file. All 13 files it reads,
largest first: `06_RATIONALE.md` 496 · `01_RATIONALE.md` 266 · `02_SOLUTION_DESIGN.md` 240 ·
`01_REQUIREMENT_ANALYSIS.md` 221 · `PM_LOG.md` 203 · `03_RATIONALE.md` 201 · `02_RATIONALE.md` 194 ·
`06_TEST_REPORT.md` 220 · `04_RATIONALE.md` 169 · `05_RATIONALE.md` 169 · `04_DEVELOPMENT.md` 164 ·
`05_CODE_REVIEW.md` 92 · `03_GATE_REVIEW.md` 57. Two adversarial checks on the green: `SKIP` is
still 1, so 18 → 19 is a repair, not a check degrading to SKIP; and repo-wide, `find . -newermt`
at this report's round-2 write returns only `05_CODE_REVIEW.md`, `05_RATIONALE.md` and `PM_LOG.md`
— no product file, no script, and no document grew while `PM_LOG.md` shrank, so its 347 lines were
dropped rather than relocated into a file F.6 would then have to catch. This file is the closest to
the cap, so round 3's addition was paid for by compacting round-1 prose inside it (the
mutation-matrix commentary and "what I tried to break"), never by crossing 500. Carried rows were
not re-run: `git diff --numstat` still reads the round-2 tuple (`bin/sc 24 9`,
`check-sc-contracts.py 173 0`, `baseline.json 2 2`, `dev-map.md 4 4`, both READMEs `1 1`), and
`A.1` — the one gate clause a carried row cites — is a `git grep` over tracked files with `':!*.md'`
excluded (`verify_all.sh:33-34`), so no document could have moved it in either direction.

## Full run: the contract suite, shipped source

```
PASS  userinfo_ends_at_last_at … zh_placeholders_are_a_subset_of_their_key  (the 14 originals)
PASS  every_file_read_and_write_names_utf8  8 text site(s) name utf-8; 5 binary site(s) admitted by a literal mode
PASS  unusable_settings_refuses_regeneration  refused by name with a valid node store present; no config, no drift record
PASS  settings_write_failure_is_a_sentence  OSError -> 'No such file or directory'; a value UTF-8 cannot encode -> "'utf-8' codec can't encode character '\ud800' in position 13: surrogates not allowed"
summary: 17 defined, 17 run, 17 passed        exit=0     (identical on 10 consecutive runs)
```

## Full run: the mutation matrix (AC-13, and the three coverage controls)

Each mutation on its own scratch copy, the suite run once per copy; nothing shared a file.

```
m_codec_latin1          FAIL every_file_read_and_write_names_utf8  17 defined, 17 run, 16 passed  exit=1
m_codec_deleted         FAIL every_file_read_and_write_names_utf8  17 defined, 17 run, 16 passed  exit=1
m_fr6_deleted           FAIL unusable_settings_refuses_regeneration 17 defined, 17 run, 16 passed exit=1
m_cause_bare_strerror   FAIL settings_write_failure_is_a_sentence   17 defined, 17 run, 16 passed exit=1
m_arm_collapsed         (no failure)                                17 defined, 17 run, 17 passed exit=0
m_persist_oserror       (no failure)                                17 defined, 17 run, 17 passed exit=0
m_refusal_global        (no failure)                                17 defined, 17 run, 17 passed exit=0
```

Each of the first four killed **exactly one** assertion (16 of 17): no mutation kills a neighbour,
none is killed by two. Two failure messages, quoted because their shape is the evidence:

```
FAIL  unusable_settings_refuses_regeneration  FileNotFoundError: [Errno 2] No such file or
      directory: '/tmp/sc-contract-yb6qrx4q/unusable-settings/no-sing-box'
FAIL  settings_write_failure_is_a_sentence  AssertionError: a value UTF-8 cannot encode:
      AttributeError left save_settings(): 'UnicodeEncodeError' object has no attribute 'strerror'
```

The first confirms the developer's disclosed diagnostic weakness first-hand: with FR-6's statement
deleted, `generate_config()` runs on to `sing-box check` and the absent `SB_BIN` raises before the
assertion can say "no `OverrideError` was raised" — a real, loud kill whose wording names the stub
rather than the missing refusal. **C-9 / RES-5**: `m_codec_deleted` fails the same assertion, which
is a fact about *this* assertion (I-5 is a **source scan**, so a missing `encoding=` is directly
visible to it) and no refutation of C-9, whose false-kill hazard belongs to a *behavioural* codec
assertion, where on a UTF-8 host a deleted argument changes no observable byte. The kill of record
for V-13(a) stays the **substitution** (`latin-1`); the deletion is corroboration, never the kill.

## Full run: AC-1 / AC-2

```
[candidate]     exit=1
  err| ⚠️  Cannot use …/settings.json: not valid JSON (Expecting property name enclosed in double quotes: line 1 column 37 (char 36))
  err| Cannot use …/settings.json: not valid JSON (Expecting property name enclosed in double quotes: line 1 column 37 (char 36))
  stderr lines carrying 'Cannot use': 2 | pre-dispatch announcements: 1 | REFUSAL sentences counted by AC-1: 1
  Traceback in stderr: False
  config.json UNCHANGED | .config.sha256 UNCHANGED | settings.json UNCHANGED
  restart_service() reached: False
[HEAD-control]  exit=0
  out| Reloaded
  err| ⚠️  Cannot use …/settings.json: not valid JSON (…)
  err| ⚠️  4/4 rule-sets unusable (…) — degraded to no-splitting mode: …
  stderr lines carrying 'Cannot use': 1 | REFUSAL sentences counted by AC-1: 0
  config.json REPLACED | .config.sha256 REPLACED | settings.json UNCHANGED
  restart_service() reached: True
AC-2  telemetry NXDOMAIN rules: pre-existing=0  regenerated=1  -> REPRODUCED
AC-2  clash external_controller: '127.0.0.1:29500' -> '127.0.0.1:29091'  -> REPRODUCED
AC-2  candidate emitted a NEW document: False (config.json byte-identical to the pre-existing one)
```

`restart_service()` was wrapped so "was it reached at all" is observable; the original still runs and
asks no init system anything. C-8 held exactly as written — two stderr lines render the same key,
`bin/sc:610-612` (prefixed `⚠️`) and `bin/sc:3801-3803` (unprefixed); only the second counts. AC-2's
`29091`: `_free_port(29090, 100)` skipped a port this host holds, and `29500 ∉ [29090, 29190)`, so
the prober can never return the fixture's own value (C-6).

## Full run: AC-3, the control that a valid settings file still takes effect

Candidate and HEAD control identical on every clause: the usable path did not move.

```
exit=0 | out: 已重新加载
telemetry rejection rules present : 0
dns.rules[0] : {'action': 'predefined', 'rcode': 'NOERROR', 'query_type': [28, 64, 65]} == _aaaa_rule(suppress=True) : True
clash external_controller : '127.0.0.1:29500'
drift record : b946ab02294947b91ace7f2413d0f52a9f419c46ea05ac8c7634030fb85804c4
sha256(config.json bytes) : b946ab02294947b91ace7f2413d0f52a9f419c46ea05ac8c7634030fb85804c4  (equal)
settings.json byte-identical : True
```

## Full run: AC-4 and its control

```
candidate      sc doctor  exit=1  rows=20  last section 'file permissions' present  warnings=1  Traceback=False
candidate      sc ls      exit=0  node rows=1                                        warnings=1  Traceback=False
HEAD-control   sc doctor  exit=1  rows=20  warnings=1     (HEAD passes this row too)
HEAD-control   sc ls      exit=0  node rows=1  warnings=1
MUTANT global  sc doctor  exit=1  rows=0   node rows=0  Traceback=True
MUTANT global  sc ls      exit=1  rows=0   node rows=0  Traceback=True
```

C-11 confirmed: `sc doctor` writes exactly **one** `⚠️  Cannot use …` line.

## Full run: AC-5

```
[candidate]  exit=1   (4× `↓ <name>.srs ... OK (43 byte(s))` from the stubbed fetches)
  out| Rule-sets updated: geoip-cn, geosite-cn, geosite-google, geosite-private — the sing-box service was not touched
  err| ⚠️  Cannot use …/settings.json: not valid JSON (…)
  run-level outcome lines: 1 | 'Rule-sets restored … regenerated': 0 | Traceback: False
  config.json UNCHANGED | .config.sha256 UNCHANGED | restart_service() reached: False
[HEAD-control]  exit=0
  out| Rule-sets restored: … — config regenerated | Rule-sets updated: … | Done
  config.json REPLACED | .config.sha256 REPLACED
```

The restart arm is unreachable here on two independent grounds — `is_running()` is a hard `False`
with neither init system (`bin/sc:2210-2216`), `regen_ok` is `False` — so it is excluded, not counted.

## Full run: AC-6 / AC-7

```
AC-6 candidate  exit=1  err| Could not write …/settings.json: Permission denied
                cause clause non-empty: True | names settings.json: True | Traceback: False
AC-6 HEAD       exit=1  PermissionError: [Errno 13] Permission denied: '…/settings.json'  (traceback, 16 frames)
AC-7 candidate  exit=1  err| Could not write …/settings.json: 'utf-8' codec can't encode character '\ud800' in position 99: surrogates not allowed
AC-7 HEAD       exit=1  UnicodeEncodeError: 'utf-8' codec can't encode character '\ud800' … (traceback)
AC-7 MUTANT bare e.strerror  exit=1  AttributeError: 'UnicodeEncodeError' object has no attribute 'strerror'
                              ("During handling of the above exception, another exception occurred")
```

AC-7 also produced a first-hand sighting of **BC-5**: after the failing run the settings document is
no longer byte-identical — `write_text` opened `"w"`, truncated, and the encode failed mid-write.

## Full run: AC-8 and its control

```
candidate                      exit=0  node rows=1  'Could not write' sentences=0  settings.json byte-identical
HEAD-control                   exit=0  node rows=1  'Could not write' sentences=0   (HEAD passes; not the control)
MUTANT persist except OSError  exit=1  node rows=0  err| Could not write …/settings.json: Permission denied
```

## Full run: AC-9 / AC-10, environment proof first

The proof is taken **in the measured process**, written to `_env_proof.json` and read **before**
any other clause is credited; a process whose proof fails aborts with "environment is UTF-8: …".

```
LC_ALL='C' LANG='C' PYTHONUTF8='0' PYTHONCOERCECLOCALE='0'   sys.flags.utf8_mode = 0
sys.stdout.encoding = 'ascii'   locale.getpreferredencoding(False) = 'ANSI_X3.4-1968'
sys.getfilesystemencoding() = 'ascii'   sys.stderr.errors = 'backslashreplace'
NON_UTF8_PROVED = True
```

Fixture-vacuity trap avoided explicitly: the document was written by `generate_config()` itself
(`ensure_ascii=False` → `_write_private(..., encoding="utf-8")`), the driver asserting the bytes
non-ASCII first — `config.json is 4677 bytes, 48 of them non-ASCII`.

```
AC-9  candidate exit=0
  out| "\\u9999\\u6e2f\\u8282\\u70b9-01",
  out| "default": "\\u9999\\u6e2f\\u8282\\u70b9-01",
  err| Showing the configuration on disk: …/config.json
  err| Node credentials are masked; a masked value shows as ******.
  'cannot read' sentences: 0 | raw CJK bytes on stdout: False | mask present: True
AC-9  HEAD      exit=1
  err| cannot read …/config.json: 'ascii' codec can't decode byte 0xe9 in position 2908: ordinal not in range(128)
  a JSON document reached stdout: False
AC-10 candidate  [OK] IPv6 (AAAA): AAAA queries are answered empty (setting: auto — this host has no global IPv6 address); config.json carries this decision
AC-10 HEAD       [UNKNOWN] IPv6 (AAAA): cannot read …/config.json: 'ascii' codec can't decode byte 0xe9 in position 2908: ordinal not in range(128)
```

## Full run: AC-11, re-measured against the corrected paragraphs (round 2)

D-1 was accepted in full and routed through stage 1 round 4 (AC-11 restated), stage 2 round 3 (E-18,
K-12, V-11 amended in place) and stage 4 round 3 (one hunk per README); the round-1 finding lives
closed in D-1's row.

**Independent reproducer, written from AC-11's text rather than from stage 4's probe.** Three
drivers in `qa11/`: `ac11_behaviour.py` (three-tag table + swept codec boundary), `ac11_extra.py`
(clause (d) under a UTF-8 stdout, a two-spelling file, an ASCII-only file), `ac11_rule.py` (the
paragraph ruling, per language, against the measured table). Four deliberate differences from stage
4's probe: the fixture document is built here and asserted to hold **no backslash**, so no fixture
byte can be mistaken for a stdout escape; the tags are built from source escapes **inside** the
driver (never through `argv` or `os.environ` — the transport stage 4 round 3 discarded its own first
probe over); the whole-document clause normalises all three spellings back to characters and
compares the decoded document to the expected masked one; and the fixture carries a credential, so
"the whole **masked** document" is verified, not assumed.

The environment proof is taken in the measured process by `run_case.py --prove-non-utf8`, written
to `_env_proof.json`, and read by the driver **before** any other clause is credited:

```
[bmp-cjk] proof: stdout.encoding='ascii' getpreferredencoding='ANSI_X3.4-1968' utf8_mode=0 PYTHONUTF8='0'
[bmp-cjk] fixture: on-disk non-ASCII bytes=18 | exit=0 | saved bytes=493 pure-ASCII=True
[bmp-cjk] tag line on stdout: "tag": "香港-01",
[bmp-cjk] json.loads(saved file) valid=True
[bmp-cjk] whole masked document reached stdout (decoded == expected): True
[bmp-cjk] MASK present=True | raw fixture credential absent=True
[latin1]  exit=0 | tag line: "tag": "caf\xe9-02",      valid=False Invalid \escape: line 8 column 18 (char 101)
[latin1]  whole masked document reached stdout: True
[astral]  exit=0 | tag line: "tag": "\U0001f680-03",   valid=False Invalid \escape: line 8 column 15 (char 98)
[astral]  whole masked document reached stdout: True

=== AC-11 measured table ===
bmp-cjk  exit=0  spelling(s)=['u'] (expected 'u')  saved file valid JSON=True   whole document=True
latin1   exit=0  spelling(s)=['x'] (expected 'x')  saved file valid JSON=False  whole document=True
astral   exit=0  spelling(s)=['U'] (expected 'U')  saved file valid JSON=False  whole document=True
```

Clause (b) is a claim about the **codec**, not three lucky tags, so it was swept — 8 835 code points, surrogates excluded:

```
boundary sweep (code point -> spelling), swept over 8835 code points:
   U  : U+10000 … U+10FFFF  (515 sampled)
   u  : U+0100 … U+FFFF  (8192 sampled)
   x  : U+0080 … U+00FF  (128 sampled)
   edge U+0007F -> '\x7f'    edge U+00080 -> '\\x80'      edge U+000FF -> '\\xff'
   edge U+00100 -> '\\u0100'  edge U+0FFFF -> '\\uffff'    edge U+10000 -> '\\U00010000'
   \uNNNN      alone in a JSON string: valid JSON
   \xNN        alone in a JSON string: NOT valid JSON (Invalid \escape: line 1 column 8 (char 7))
   \UNNNNNNNN  alone in a JSON string: NOT valid JSON (Invalid \escape: line 1 column 8 (char 7))
```

(`edge U+0007F` is the unescaped character under `repr`; the other five are backslash sequences,
hence the doubling.) This reproduces stage 4 round 3's boundary independently and settles the
sub-claim the correction turns on: `\uNNNN` alone of the three is JSON-legal.

```
--- P1: clause (d), the same three tags under a UTF-8 stdout (LC_ALL=C.UTF-8 PYTHONUTF8=1) ---
[utf8-bmp-cjk] stdout.encoding='utf-8'  exit=0  escapes present: none  json.loads valid=True
               tag line: "tag": "香港-01",  decoded == expected masked document: True  tag raw: True
[utf8-latin1]  exit=0  escapes: none  valid=True  tag line: "tag": "café-02",   tag raw: True
[utf8-astral]  exit=0  escapes: none  valid=True  tag line: "tag": "🚀-03",      tag raw: True
--- P2: one file carrying TWO spellings (Latin-1 + CJK in one tag) ---
[mixed] NON_UTF8_PROVED=True  exit=0  escapes present: ['\xNN', '\uNNNN']
        tag line: "tag": "caf\xe9香港-04",  json.loads valid=False Invalid \escape
--- P3: an ASCII-only document under the same proved non-UTF-8 stdout ---
[ascii-only] NON_UTF8_PROVED=True  exit=0  escapes present: none  json.loads valid=True
```

P1 exists because clause (d) is a claim about the saved file and negative 2 forbids one the fixture
does not verify; P2 because clause (c) is worded per **file** ("a file carrying either other
spelling"), stronger than per character; P3 is negative 1's vacuity control.

### The ruling, and why the row cannot pass vacuously

`ac11_rule.py` pastes the measured table in **as data** and rules each paragraph against it, per
language, clause by clause — mechanical where a claim has a token (the three spellings, the
JSON-escape claim, exit 0, the UTF-8 route), the reading of the surrounding sentence mine. Three
builds: the worktree, HEAD, and a synthetic **English-only** build (worktree en + HEAD zh).

```
=== build: worktree (candidate) ===
  en paragraph: 1201 chars, spellings named: ['\xNN', '\uNNNN', '\UNNNNNNNN']
  zh paragraph:  581 chars, spellings named: ['\xNN', '\uNNNN', '\UNNNNNNNN']
  ==> worktree (candidate): PASS
=== build: HEAD (control: must FAIL) ===
  en: 11 clauses FAIL, incl. FAIL (c) only \uNNNN is a JSON escape / FAIL neg-1
  zh: 10 clauses FAIL, the same two among them        ==> HEAD: FAIL
=== build: english-only (control: must FAIL) ===
  en: no failure;  zh: 10 clauses FAIL, every one [zh] ==> english-only: FAIL
controls behaved: HEAD fails=True, english-only fails=True
```

HEAD's Chinese paragraph passes `(a) escape, run does not end` and fails the other ten — the right
shape, since that clause was already true prose and it is the *conclusion about the saved file*
HEAD gets wrong. Read against the measured table, HEAD says 「于是存下来的文件**不是**合法 JSON」 while
`bmp-cjk` reads `valid JSON=True`: **HEAD fails clause (c) on the CJK row**, in both languages.

I read the Chinese paragraph as carefully as the English one and record the reading, not only the
token check. 「整份隐去后的文档照样完整地写到标准输出，命令照样以 `0` 退出」 is (a), measured by the
`exit=0` + whole-document rows. 「用哪一种转义由字符本身决定 —— Latin-1…`\xNN`，BMP 之内其余的字符
（中文正是这一类）…`\uNNNN`，BMP 以上的…`\UNNNNNNNN`」 is (b), matching the swept boundary including
the CJK case. 「这三种里**只有 `\uNNNN` 是 JSON 的转义写法**……所以转义全是这一种的文件…仍然是合法
JSON；只要其中出现了 `\xNN` 或 `\UNNNNNNNN`…就不是」 is (c) in both directions, P2 making its second
half a per-file claim; 「任何情况下…都是在 UTF-8 的标准输出下运行这条命令」 is (d), measured by P1. Both
negatives hold: each language's scope phrase (「`sc` 编码不了的字符」 / "a character `sc` cannot
encode") keeps "Latin-1 range → `\xNN`" from reading as a claim about ASCII, which P3 confirms.

### Blast radius, machine-checked with git — what RES-4 actually owed

```
README.md        git diff -U0 → 1 hunk header: @@ -297 +297 @@ ;  diff vs HEAD → 1 changed line
README.zh-CN.md  git diff -U0 → 1 hunk header: @@ -297 +297 @@ ;  diff vs HEAD → 1 changed line
README.md:124 HEAD=93e2494efc53 worktree=93e2494efc53 same=yes      (:152 same=yes)
README.zh-CN.md:124 HEAD=ef5f330669e3 worktree=ef5f330669e3 same=yes (:152 same=yes)
git diff --numstat bin/sc → 24  9
```

CR-2's paragraphs were not merely left byte-identical — they were read, and still carry the
inaccuracy ("like every command except `sc doctor`" / 「和除 `sc doctor` 以外的所有子命令一样」):
RES-3's, still open, still frozen, correctly untouched by E-18's one hunk. `bmp-cjk` **is** AC-9's
mandated fixture shape, so AC-9's candidate half was re-observed here (`exit=0`, the escape on
stdout, mask present, no `cannot read` sentence); its HEAD control, whose subject is the untouched
clone at `3a0ba42`, was not re-run.

## Full run: AC-12, independent scan

Written from I-4's text rather than reused from `check-sc-contracts.py`; every matched call site is printed with its verdict, so nothing is classified as "unseen".

```
TEXT, names utf-8 : 521 os.fdopen · 619 write_text · 1673/2021/2714/3130 read_text ·
                    3466/3514 write_text
BINARY, literal mode : 938 'rb' · 1202 'wb' · 1549 'rb' · 1972 'rb' · 2649 'rb'
text sites naming utf-8 : 8 | binary sites admitted : 5 | offending sites : 0
json.load(s) over read_bytes(): []
subprocess.run(text=True) pipe decodes (RES-1, OUTSIDE I-4's population): [2156, 3471]
HEAD control on the same scanner: text sites 2 | binary 5 | offending sites 6
```

Independently recomputed 8/5 agrees with the shipped evidence string and the reviewer's hand count; RES-1's line numbers differ from stage 4/5's only by `ast` convention.

## Full run: AC-15 / AC-16 / AC-17 / AC-18

```
AC-15 function-body identity vs HEAD (regex-extracted whole defs), all identical=True:
  _write_private _config_digest _record_generated _redact _init_files _read_state _unusable
  _settings_or_empty save_nodes _load_override
  _write_private() call sites: NODES_PATH(:592), STATE_PATH(:1998), CFG_PATH(:2149) — sole writer of config.json
  no chmod on SETTINGS_PATH anywhere in the file
  sc lang zh (creates settings.json, umask 022): candidate mode=0o644, HEAD mode=0o644
  sc lang en (rewrites):                          candidate mode=0o644, HEAD mode=0o644
AC-16 sys.stdout.write sites: :1218, :1231 (_fetch_to_temp's progress meter) and :3164 —
      cmd_config() has exactly one, its argument through _redact(); MASK / VISIBLE_IN_OUTBOUND /
      SECRET_KEYS / _redact block diff vs HEAD is empty.
AC-17 git diff --numstat: baseline.json 2/2 · check-sc-contracts.py 173/0 · CHANGELOG.md 1/0 ·
      bin/sc 24/9 · dev-map.md 4/4.  bin/sc added lines: 19 code + 5 comment (K-11's itemisation).
      TRANSLATIONS block diff vs HEAD: empty (zero new keys).  No new file in the product diff.
      verify_all A.1 PASS with this task's documents in place.
AC-18 dev-map:37, :43, :76, :87 each read against the shipped code and true. The only live
      documents with a bare `read_text()` are dev-map:76 — which calls it the defect — and the
      historical rows in docs/tasks.md / docs/tasks-archive.md.
AC-18 round 2, :76's coverage clause taken sub-claim by sub-claim against named lines:
      generate_config() calls _load_override():2064 -> load_settings():2074 -> load_nodes():2075
        ("after the override wrapper, before load_nodes()")                          true
      _resolve_clash_port() try:449 holds ONE statement save_settings():450, except SystemExit:452 true
      the FR-7 comment is at bin/sc:3408 and states scope, not coverage                true
      m_arm_collapsed through the suite: 17 defined, 17 run, 17 passed, exit 0         true
      :87's "17 named assertions" vs `--list | wc -l` = 17                             true
      :43's "one read_text(encoding=\"utf-8\")" in cmd_config vs bin/sc:3130           true
```

`docs/tasks.md:228`'s pool row R-76 still asserts "`bin/sc:3113` has no `encoding=`", which this
change makes false; `docs/tasks.md` is stage 7's to close, so it is recorded, not filed against AC-18.

## Full run: AC-19, the guard's only control

```
candidate (a) unusable override.json   exit=1  err| Cannot use …/override.json: not valid JSON (Expecting value: line 1 column 11 (char 10))
                                       outcome lines=0  'Rule-sets restored…'=0  config/record UNCHANGED
candidate (b) unusable nodes.json      exit=1  err| Cannot use …/nodes.json: the top level must be a JSON object
                                       outcome lines=0  'Rule-sets restored…'=0  config/record UNCHANGED
HEAD-control  (a) and (b)              identical to the candidate on every clause
MUTANT arm-collapsed (a)               exit=1  sentences naming override.json = 0  outcome lines=1
MUTANT arm-collapsed (b)               exit=1  sentences naming nodes.json    = 0  outcome lines=1
```

**Re-run at round 2** — RES-1's single pin is not carried forward on anyone's word — and every
clause reproduced identically, mutant included. The mutant satisfies the row's *exit-status* clause
and nothing else: it swallows the failure, prints the run-level outcome line as if the run had
merely failed to regenerate, never names the document, and still leaves the suite at `17/17/17`,
exit 0 — exactly the build CR-1 warns ships green. `settings.json` is usable in both cases, so the
pre-dispatch degrade line does not fire (zero `⚠️` lines); nor does the composition-fault path — in
(a) the override never parses, in (b) `load_nodes()` raises first. Excluded, not counted.

## Coverage boundaries measured beyond CR-1

Three of the seven mutants leave `verify_all` B.4 fully green:

| mutant | property it re-installs the defect in | suite result |
|---|---|---|
| `m_arm_collapsed` | E-10's `.path` guard (FR-7 scope) | 17/17/17 exit 0 |
| `m_persist_oserror` | FR-5's silent, non-fatal opportunistic persist | 17/17/17 exit 0 |
| `m_refusal_global` | FR-8's "an unusable settings document blocks no run that only reports" | 17/17/17 exit 0 |

CR-1 / RES-2 already own the first; the other two are the same shape and cure (the suite's first
**command-level** fixture), so they belong on RES-2's pool row. No committed assertion was added at
any round: FR-9 / Q-11 / I-8 / E-12 fix suite growth at three, `05_CODE_REVIEW.md` ruled the pin a
pool row, and the floor (17) was never lowered or padded.

## What I tried to break and could not

- **A silent-swallow build passing AC-1.** Every refusing run was measured for a *named* sentence
  *and* a non-zero exit *and* three unchanged digests *and* an unreached `restart_service()`: a
  build avoiding the traceback while still writing `config.json` fails on the digests; one writing
  nothing but saying nothing fails on the sentence count.
- **A vacuous locale row.** `LC_ALL=C` alone was never used; the proof is taken in the measured
  process, no clause is credited without it, and both rounds' fixtures were asserted to carry
  non-ASCII bytes on disk first.
- **A vacuous AC-11.** Ruled against a measured table with two controls, both of which FAIL, the
  Chinese paragraph read clause by clause rather than assumed to mirror the English. (Same shape
  for AC-3: run on both builds, required identical on all seven clauses.)
- **Concurrency against the refusal.** 12 parallel `sc reload` runs on one fixture holding `[]`:
  all 12 exited 1, all 12 wrote the refusal sentence, `config.json` and the drift record stayed
  byte-identical, no traceback. No race lets one run through.
- **`sc use`'s hot-switch exemption (BC-14).** Structurally unreachable under the mandated fixture
  (`is_running()` reads `SYSTEMD`/`OPENRC`, not the Clash API); stubbing the *gate* plus an
  answering `clash_api()` reproduces it — `exit=0`, `PUT /proxies/proxy` issued,
  `reload_or_restart()` never reached, `config.json` not written — reported with the stub named.
  **BC-13**: in the un-stubbed run the node-store write stood (`nodes.json` `active` = `'n1'`)
  while `config.json` was not written and the run exited 1.
