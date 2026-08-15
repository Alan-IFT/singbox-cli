> Rationale portion for 06_TEST_REPORT.md. Non-binding.

Opened on **T6.2** — this stage reproduces developer-claimed measurements (V-1…V-16, the
enumeration counts, the `sc config` capture, the C-6 measurement). The full runs whose ≤5-line
excerpts the contract cites live here, together with the measurement narrative.

## 1. The harness, and why it is shaped this way

One env-driven runner outside the repository, `runner.py`, drives `main()` in a **subprocess**
per case so that fd 1 is a real file or a real pipe (C-2, F-10) and the process' encoding is the
one the environment actually gives it. Load path is `docs/dev-map.md:121-158` verbatim, with one
addition — `encoding="utf-8"` on the `open()` — which is defect QA-1: without it the run dies
before `bin/sc` is even compiled under the non-UTF-8 environment C-12 mandates.

`_init_files` is rebound, not called through. A `mkdtemp`-style fixture root holds
`etc-sing-box/`, `etc-sing-box/rules/`, a `var-lib-sing-box/` stand-in, a `sing-box-stub`, and
(for the AC-8 second site) a `jail/` under which every absolute path `bin/sc` constructs at run
time is redirected. The jail is fail-closed: it redirects *outward* paths inward and never the
reverse, so a forgotten constant lands in the fixture rather than in `/etc`.

Traps honoured, each because the record says it has bitten before:

- `lang` and `clash_api_port` live in the **fixture's own `settings.json`**. `main()` reassigns
  `LANG` (`bin/sc:3706`/`:3709`) and `CLASH_PORT` (`:3710`) after import, so a harness that sets
  `sc.LANG` renders English on every `main()`-driven path and every Chinese assertion passes
  vacuously; and a fixture that omits `clash_api_port` degrades the whole Clash matrix to
  "nothing listening" on candidate and control alike (C-4).
- `sc.LANG` was assigned in exactly one place — `ac6.py`, a direct-render step that asserts
  nothing about I-1 (gate answer D-4).
- No `StringIO`, no `redirect_stdout` anywhere. Every FR-6/FR-7 step writes to a real file or a
  real pipe; the runner prints `stdout=TextIOWrapper … isatty=False` before the run and
  `[post] … errors=backslashreplace line_buffering=True` after it, so the assertion is provably
  made against the **wrapped** stream.
- `is_running()` returns `False` from its final line when neither `SYSTEMD` nor `OPENRC` is set
  (`bin/sc:2189-2195`), so `sc.SYSTEMD = True` and a `systemctl is-active` stub returning
  `CompletedProcess(cmd, 0)` are what make `=== Route mode ===` render at all. Proved printed
  (`grep -c` = 1) on candidate **and** HEAD before anything under it was asserted.
- Every differential is candidate-vs-**pristine `git clone`** of `6c034d62`, run at the *same*
  fixture path, never a `git worktree`.

Full C-1 assertion, one run:

```
[C-1] loader = docs/dev-map.md:121-158 recipe; _init_files neutralised=True (bin/sc's Path('/var/lib/sing-box').mkdir never run)
[C-1] eight path constants inside <scratch>/t25qa/fx: OK
[C-1] protected paths after the run:
  /var/lib/sing-box  UNCHANGED
  /etc/sing-box      UNCHANGED
[C-1] VERDICT OK
[post] stdout=TextIOWrapper encoding=utf-8 errors=backslashreplace line_buffering=True
```

Session-end direct witness:

```
/var/lib/sing-box mtime=1785387564 ctime=1785387564   entries: . .. cache.db
/etc/sing-box     mtime=1786421637 ctime=1786421637
MainPID=2566751
ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
ls -d /etc/systemd/system/sing-box-rules-update.timer.d -> No such file or directory
```

## 2. The non-UTF-8 environment, proved rather than assumed (C-12)

```
LC_ALL=C PYTHONCOERCECLOCALE=0            -> stdout.encoding=utf-8 errors=surrogateescape preferred=utf-8
LC_ALL=C PYTHONCOERCECLOCALE=0 PYTHONUTF8=0 -> stdout.encoding=ascii errors=surrogateescape preferred=ANSI_X3.4-1968
```

The first line is the T-23 vacuity, alive on this host: PEP 540 auto-enables UTF-8 Mode for a
`C` `LC_CTYPE`, so the whole locale dimension certifies nothing without `PYTHONUTF8=0`.

The second line also carries the surprise that makes AC-10 hard: the *pre-wrap* handler is
`surrogateescape`, not `strict`. That is why a node tag transported through `os.environ` is
useless as a fixture — `os.environ` decodes with `surrogateescape` too, so the tag arrives as
lone surrogates and HEAD writes them straight back out as their original bytes. Measured, on
HEAD, with the tag passed as raw UTF-8 in the environment:

```
   1      vless       日本-1                        1.1.1.1:443                        -
   (HEAD, LC_ALL=C PYTHONUTF8=0, exit 0 — the "non-UTF-8 abort" test passing on broken code)
```

The candidate on that same fixture prints `\udce6\udc97\udca5…`, i.e. *worse*. Only after the
tag was delivered base64-encoded (a pure-ASCII environment value, decoded as UTF-8 inside the
harness, written into `nodes.json` as `"日本-1"`) did the criterion discriminate:

```
cand: exit 0, 2 data rows, `日本-1` in the Name cell
head: exit 1, 0 data rows, UnicodeEncodeError: 'ascii' codec can't encode characters in position 22-23
```

K-11 / D-6 confirmed in the same capture: the escaped tag is wider than the tag, so that row's
Address and Delay cells shift right. Expected, not a defect.

## 3. Enumerations, in full

`ac4.py` (AC-4), my own `ast` pass — every `Call` whose `func` is `Name('t')`, first argument
resolved when a string constant, everything else reported by line:

```
CAND      206 call sites | 203 resolved (160 distinct) | 3 UNDECIDABLE @ 1067, 2999, 2999
          183 zh keys | OFFENDERS 0 | identifier-shaped table keys: 0 []
HEAD      205 call sites | 202 resolved (159 distinct) | 3 UNDECIDABLE @ 1054, 2978, 2978
          182 zh keys | OFFENDERS 0 | identifier-shaped table keys: 5 ['ls.idx', 'ls.active', 'ls.type', 'ls.name', 'ls.address']
```

Implicit concatenation: 20 keys are written across source lines (`bin/sc:1109, 1114, 1389, 1392,
1413, 1468, 1484, 1490, 1643, 1739, 2064, 2633, 2721, 2849, 2855, 2866, 2874, 2942, 2952, 2964`);
the parser folds them and all 20 resolve to their whole value and are present in the table. No
site was skipped; the three undecidable ones are reported by line and then resolved by name:

```
DOCTOR_MARK (3): ['OK', 'UNKNOWN', 'PROBLEM']
DOCTOR_SECTIONS (9): ['sing-box binary', 'rule-sets', 'configuration', 'IPv6 (AAAA)', 'service',
                      'TUN interface', 'Clash API', 'egress IP', 'file permissions']
probe row labels (6): ['Clash API responding', 'DNS lookup', 'boot autostart', 'node delays',
                       'sing-box check', 'sing-box version']
indirect t() universe = 18 distinct; missing from zh: []
```

Four `rows.append` sites pass `None` as the label (`bin/sc:2673, 2675, 2967, 2969`) — the
`cls is None` verbatim-line arm, which never reaches `t(label)`. One passes a variable
(`bin/sc:2607`): the rule-set filename, K-6's data pass-through. Hence QA-2: the universe is 15
static labels, 18 with the marks, not the recorded 16.

Runtime cross-check, `sc doctor` with `sc.t` wrapped to record every key:

```
runtime t() keys during `sc doctor`: 45 ; NOT in zh table: 4 ->
['geoip-cn.srs', 'geosite-cn.srs', 'geosite-google.srs', 'geosite-private.srs']
```

`ac6.py` (AC-6). Population test, applied mechanically to all 183 keys: a numeric placeholder
followed by the noun it counts, the placeholder not part of a fraction, the noun not a unit
symbol. Result on the candidate — 15 by form, 14 invariant:

```
VERDICT: 14/15 members render ONE invariant form at 0/1/2 in each language
  FAIL at {at}: {name} matched {count} elements, … PLURAL-AT-1=['at X: X matched 1 elements, …']
EXCLUDED fraction (6)  EXCLUDED unit-symbol (3)  EXCLUDED no numeric placeholder next to a noun (159)
```

The one FAIL is R-72's line and is excluded on reachability, which I verified rather than
accepted: `bin/sc:1409-1417` computes `hits` and raises **only** when `len(hits) != 1`, and
`count=len(hits)`, so `1` cannot render. `larger than {n} byte(s)` is admitted by my form test
and by the developer's family test alike, so F-8's two membership tests reach the same answer
here; the asymmetry survives as a classification-rationale nit only.

HEAD on the same script scores **4/15**, failing on all four age keys, all four byte keys and
the two composite rule-set phrases with `PLURAL-AT-1` evidence per row.

`ac11.py` (AC-11). Edited set derived by diffing the two shipped tables:

```
added keys      : 16   removed keys : 15   zh VALUES changed for a surviving key: 0
rendered forms tested: 490 over 16 added/edited keys, both languages
forms containing 失败： or 'failed: ': 0
survives: 'OK (' -> ['OK ({size} byte(s))'] ; 'failed: {e}' ; '失败：{e}'
```

16 added against 15 removed is the one net new entry, I-6's `{reason}, {age}`. The 490 forms
come from substituting every `{reason}` with all five `_status_text` values and every `{age}`
with all six `_age_text` forms, in both languages.

## 4. The screens, before and after

AC-8, `sc status` to a real file (candidate left, HEAD right, both numbered):

```
1 === Service status ===        1 CHILD<systemctl status>
2 CHILD<systemctl status>       2 CHILD<ip -br>
3                               3 === Service status ===
4 === TUN interface ===         4
5 CHILD<ip -br>                 5 === TUN interface ===
```

AC-8's second site, `sc update-interval daily` under the path jail:

```
cand: 1 CHILD<systemctl daemon-reload> | 2 Ruleset auto-update cadence → daily (OnCalendar=daily) | 3 | 4 === Next run === | 5 CHILD<systemctl list-timers>
head: 1 CHILD<systemctl daemon-reload> | 2 CHILD<systemctl list-timers> | 3 Ruleset auto-update cadence → daily … | 4 | 5 === Next run ===
```

The 240 KB-child variant, which is the one that would defeat a per-site `flush=True` fix:

```
cand file : 8021 lines ; headings at 1, 4003, 8005 ; first child line at 2 and 4004
head file : 8021 lines ; headings at 8001, 8003, 8005 ; first child line at 1 and 4001
(identical numbers through a real pipe)
```

AC-12, one injected `mode` = `global<ESC>[31mRED<ESC>[0m\rX` and one injected egress body
`203.0.113.7<ESC>[31mRED<ESC>[0m\r`, both screens, both builds:

```
cand  '=== Route mode ===' printed: 1 | status mode: globalREDX | status egress: 203.0.113.7RED | doctor egress: [OK] egress IP: 203.0.113.7RED
head  '=== Route mode ===' printed: 1 | status mode: global^[[31mRED^[[0m^MX | status egress: 203.0.113.7^[[31mRED^[[0m^M | doctor egress: [OK] egress IP: 203.0.113.7RED
doctor rows matching 'route mode|routing mode': 0 on BOTH builds  <- C-3's evidence
```

RES-1, the four non-`str` `mode` values plus the three non-`str` `active` values, candidate
against HEAD:

```
mode 12345          cand '12345'            head '12345'            tb 0/0
mode true           cand 'True'             head 'True'             tb 0/0
mode {"a":1,"b":[2,3]} cand "{'a': 1, 'b': [2, 3]}" head same       tb 0/0
mode null           cand 'None'             head 'None'             tb 0/0
active 99 / true / {"x":1}   cand == head on all three              tb 0/0
counterfactual: _plain(12345) -> AttributeError: 'int' object has no attribute 'replace'
```

## 5. C-9, verbatim, as written before the AC-14 run

```
Lines I do NOT expect to be byte-identical across two runs of the same build:
  1. `sc doctor` DNS row: "{name} resolved in {ms} ms" / "no answer for {name} after {ms} ms"
     / "{name} returned no records after {ms} ms" — {ms} is a measured elapsed time.
Everything else is PINNED, not tolerated:
  2. rule-set mtimes: exactly now-5000 s -> "1 hour(s) ago"; nearest boundary 7200 s (2200 s margin)
  3. egress: _egress_ip stubbed to the constant 203.0.113.7 (no network)
  4. Clash API: one in-process http.server, fixed /configs and /proxies bodies, fixed port
  5. subprocess stubbed; no child output in this differential, so FR-6 does not enter the diff
  6. ONE fixture path for both builds (C-12); a pristine `git clone`, no worktree
  7. no config.json is generated, so the drift row reads the same on both
  8. file-permission rows name fixture paths only, identical for both builds
```

Result — the whole AC-14 diff, three screens, 47 lines of output:

```
ls     1c1  < ls.idx  ls.active  ls.type … | >    #  On  Type  Name  Address  Delay
status 6c6  < geoip-cn.srs   usable, 1 hours ago | > geoip-cn.srs   usable, 1 hour(s) ago
doctor 4c4  < [OK] geoip-cn.srs: usable, 64 bytes, 1 hours ago | > … 64 byte(s), 1 hour(s) ago
```

The declared-variable DNS row read `0 ms` on both builds and on all ten stability repeats, so it
never entered a diff.

## 6. RES-2's measurement, in full

Build X = the delivered `bin/sc` with only the round-2/3 prose regions reverted to HEAD's text
(`:471-475`, `:1059`, `:3102-3105`, `:3151-3158`, `:3697-3704`). 34 changed lines, every one a
comment or a docstring body; `python3 -W error` compiles it clean. Same fixture, four commands:

```
sc config : delivered == buildX  CMP-IDENTICAL (211 bytes)
sc status : delivered == buildX  CMP-IDENTICAL (376 bytes)
sc doctor : delivered == buildX  CMP-IDENTICAL (2244 bytes)
sc ls     : delivered == buildX  CMP-IDENTICAL (459 bytes)
```

Shape claims re-counted in the tree: 28 hunks; `#`-lines `+33/−9`; top-level `def`/`class` count
**113** on both builds; the only added import is `io`.

## 7. QA-5, at length

RES-3's cost clause says an undecodable-byte value "used to round-trip to its original bytes and
now renders `\udcXX`". The candidate half is confirmed on both routes:

```
  ↓ geoip-cn.srs ... failed: http://127.0.0.1:1/x\udcffy -> 'ascii' codec can't encode character '\udcff' …
  … /fx/etc-sing-box/bad\udcffname.json is mode 664 — run: chmod 600 …
```

The HEAD half is not observable, because HEAD cannot reach either line under the locale that
produces the surrogate in the first place:

```
head, sc update-rules: 0 stdout bytes; UnicodeEncodeError: '↓' in position 2   (HEAD bin/sc:3307)
head, sc doctor      : 15 stdout lines, last '[PROBLEM] Clash API responding: …';
                       UnicodeEncodeError: '—' in position 34
```

So on both named instances the byte fidelity `backslashreplace` displaces was never available to
a user of HEAD — the run aborted first. The give-up is real as a mechanism and as a promise to a
*future* reader; stated as a loss against today's behaviour it invites a hunt for a regression
that never shipped. One clause on `docs/dev-map.md:78` fixes it.

## 8. Judgment calls I resolved under standing authority

1. **AC-12 re-pointed rather than reported NOT-DISCRIMINATING alone** (C-3). Reason: a criterion
   carried on half of itself is weaker than one re-pointed at a comparand both screens really
   carry, and the egress body is that comparand — `bin/sc:2456` and `:2886` are the identical
   expression, so the comparison tests the *shared* implementation FR-8 is about. Both halves are
   reported, and the original clause is recorded NOT-DISCRIMINATING so the record is honest.
2. **AC-8's second site measured under a path jail rather than reported BLOCKED.** A jail
   redirects the *environment*; the function under test runs verbatim, with a real child on the
   inherited fd 1. That is not a weaker check, and the precedent it would otherwise burn
   (R-31/R-41/R-47/R-52/R-60) is reserved for cases where the *subject* is unreachable, not the
   filesystem.
3. **No new operator obligation appended.** No T-25 criterion observes the shipped invocation as
   root, and none was reported BLOCKED. QA-4 is a *correction* to an existing row, and rows are
   permanent — so it is filed to the PM rather than edited here.
4. **`baseline.json` untouched.** It is in the design's frozen set and out-of-scope 10 forbids
   changing it; the test count did not rise because out-of-scope 10 also forbids a committed
   test. The 14 reproducers live outside the repository, as NFR-2 requires.
5. **QA-1…QA-5 filed MINOR, not MAJOR.** None of them changes what the shipped build does; each
   is a record or a recipe that will mislead the next reader. The delivery is not held for them.
