> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

# 06 — Test Report · T-18 `status-egress-via-clash-api`

## Test plan

Rig built from scratch for this stage; nothing from `04_DEVELOPMENT.md` was reused. `<scratch>` =
`/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad`.
Control = `<scratch>/headclone-t18`, a `git clone` (K-12), verified
`sha256(clone/bin/sc) == sha256(git show HEAD:bin/sc) == 4fa09067bd44…5459d`.

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-B1 egress line is a public address this host egresses from | **BLOCKED** — see C-12 row. The egress comparison itself was run: `sc`'s value vs three independent echo endpoints in the same minute | `<scratch>/rig/v7shrunk.py` |
| AC-B2 one value line per fact heading, no `Traceback`, exit 0, live host | **BLOCKED** — see C-12 row. The same shape was observed on 68 fixture runs and on 2 live-Clash runs | `<scratch>/rig/v4.py`, `v7shrunk.py` |
| AC-B3 BC-1…BC-8, both languages, candidate and per-state control | 17 stand-in states × 2 languages × 2 sides = **68** `sc status` runs through `main()` | `<scratch>/rig/v4.py` → `v4.json` |
| AC-B4 egress endpoint unreachable → one localized line, four sections already printed | 2 Clash states × 2 languages × 2 sides = **8** runs, `getaddrinfo` for `ipify` broken in the child only | `<scratch>/rig/lib.py` + `drive.py --egress_break` → `v8.json` |
| AC-B5 `sc use` on BC-5 vs BC-8 | `sc use n2` over 9 states × 2 sides = **18** runs (plus 18 for `sc mode`, C-6) | `<scratch>/rig/v5.py` → `v5.json` |
| AC-S1 `_egress_ip()` byte-identical, call sites unchanged | AST extraction + sha256 against the HEAD clone; diff read at `:2243` / `:2526` | `<scratch>/rig/v1v9.py` |
| AC-S2 no new route, no `PUT`/`PATCH`/`DELETE`, no handler at any call site | `git diff -U0` hunk read; method-literal counts; `try:`/`except` line-start counts; call-site enumeration | `git diff`, `grep` (transcript in `06_RATIONALE.md`) |
| AC-S3 zero added/changed `TRANSLATIONS` entries, placeholder parity, no new `失败：` | AST-extract `TRANSLATIONS` from both sides, sha256 + key-set + value + placeholder diff | `<scratch>/rig/v1v9.py` |
| AC-S4 dev-map row states the contract; CHANGELOG gains a Chinese entry | `docs/dev-map.md:39` read; `git diff -U0 CHANGELOG.md` content assertions (CR-1) | `git diff`, `sed` |
| AC-S5 `py_compile`, 3.6 floor, stdlib only, permitted diff, `verify_all` no FAIL | `python3 -m py_compile`; `ast.parse(feature_version=(3,6))`; `git diff --name-only`; `bash .harness/scripts/verify_all.sh` | shell (transcript in `06_RATIONALE.md`) |
| **C-3** T-05's DEF-2 closure, on V6's BC-1 evidence only | `cmd_doctor` driven with `DOCTOR_SECTIONS` restricted to the Clash section, BC-1, both sides, both languages | `<scratch>/rig/v6.py` → `v6.json` |
| **C-5** control class declared per (state, body value) | 17 states declared individually, not per BC; `null` declared agreement, `5`/`"x"`/`[1,2]` declared defect | `<scratch>/rig/v3.py`, `v4.py`, `v6.py` |
| **C-7** "one value line per heading" scoped to the four fact sections | Per-section line counting over the four fact headings only; service and TUN counted for `Traceback` alone | `<scratch>/rig/v4.py` § `sections()` |
| **C-9 / F-7** every `main()`-driven fixture records `clash_api_port`; report the port actually talked to | Every run's opened URLs recorded and checked against its own stand-in port | `<scratch>/rig/drive.py` § `_recording_urlopen` |
| **C-10** endpoint disagreement tie-break | Three independent public-address echoes queried in the same minute | `<scratch>/rig/v7shrunk.py` |
| **C-11** BC-1 `sc use` issues no service action | Every subprocess argv recorded across all 36 V5 runs | `<scratch>/rig/drive.py` § `_rec_run` |
| **C-12** V7's five preconditions checked and recorded **before** the run | `ls -la /etc/sing-box`, `cat settings.json`, `ss -ltn`, `sudo -n true`, `find … -printf '%p %s %T@'` before and after | shell (record below) |
| **C-13** `## Adversarial tests`, unnumbered | This document; `verify_all` E.6 re-run after writing it | `.harness/scripts/verify_all.sh` |
| **RES-2 / CR-3** BC-6 reset variants are defect states | Two RST variants plus a clean-FIN variant, all three declared defect states | `<scratch>/rig/standin.py` |
| **RES-3** stage 5's line-shift arguments executed for real | V1, V2, V9, V10 all run against the HEAD clone | as above |
| **RES-4 / R3** wall clock as a measurement | BC-1 timed 10×; a drip-feeding peer timed once | `<scratch>/rig/vstab.py` |

**C-12 precondition record — taken before anything ran.**
`/etc/sing-box/nodes.json` exists (633 B, `-rw-------`) · `/etc/sing-box/settings.json` exists
(86 B) and **records `"clash_api_port": 29090`**, so `_resolve_clash_port()` early-returns and
`sc status` writes nothing · `/var/lib/sing-box` exists · `127.0.0.1:29090` is LISTEN ·
`cmd_status` makes exactly one Clash call, `GET /configs` (`bin/sc:2236`). **All five hold.**
The sixth, enabling condition does not: the invocation must be `sudo python3 <repo>/bin/sc status`
so `geteuid()` is 0, and `sudo -n true` on this host answers `sudo: a password is required`; this
agent has no interactive terminal. Running as non-root instead would take the import-time
`os.execvp("sudo", …)` branch and execute the installed `/usr/local/bin/sc` against the live
service. **The run was therefore not performed. AC-B1 and AC-B2 are BLOCKED, not substituted.**

**Operator obligation for the PM to file** (this stage may not write `.harness/**`): *on a terminal
with sudo, with the pre/post `find /etc/sing-box -printf '%p %s %T@'` + `find /var/lib/sing-box …`
+ `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` witness, run once:*
`sudo python3 /home/alan/Programs/singbox-cli/bin/sc status`, *capturing both streams; then compare
the `=== 出口 IP ===` line against an independent echo endpoint in the same minute.* Until that is
done, AC-B1 and AC-B2 remain unobserved.

**C-9 / F-7 result — the vacuity trap did not fire.** Across the 204 fixture runs of V3 + V4 + V5 +
V6: runs whose Clash URL port differed from their own stand-in port = **0**; runs that opened no
Clash URL at all = **0**; runs that touched the live port 29090 = **0**. Every fixture wrote
`clash_api_port` into its own `settings.json`, and `_resolve_clash_port()` was left real rather than
stubbed, so the trap was live and observably survived.

**C-10 result.** The two endpoints did not disagree, so no tie-break was needed; a third was
queried anyway. `sc` → `38.47.117.142`; `ifconfig.me/ip` → `38.47.117.142`; `icanhazip.com` →
`38.47.117.142`; `api.myip.com` → `{"ip":"38.47.117.142",…}`. This comparison stands on its own; it
does **not** discharge AC-B1, whose subject is the root invocation.

**C-11 result.** `sorted({argv[0] basename})` over every subprocess spawned by all 36 V5 runs is
`['sing-box-stub']`. No `systemctl`, `rc-service` or `rc-update` invocation was issued by any run,
and `sing-box check` ran only as
`<tmp>/sing-box-stub check -c <tmp>/etc-sing-box/config.json`. All eight path constants were
repointed into a `mkdtemp()` root and each was **asserted** to resolve inside it before the module
was driven.

**C-3 result — T-05's DEF-2 evidence obtained, on V6's BC-1 rows and nothing else.** `cmd_doctor`'s
own driver and `DOCTOR_EXIT` map, with `DOCTOR_SECTIONS` restricted to the Clash section so the exit
status is derived from that section alone (C-2's stated condition, made an observation):

```
BC-1 hang en candidate     exit=1 portrow=True  [OK] Clash API: 127.0.0.1:42713 | [PROBLEM] Clash API responding: no answer within the 3s timeout
BC-1 hang en control(HEAD) exit=2 portrow=False [UNKNOWN] Clash API: this check could not run: timed out
BC-1 hang zh candidate     exit=1 portrow=True  [正常] Clash API: 127.0.0.1:38605 | [异常] Clash API 是否响应: 3 秒超时内无响应
BC-1 hang zh control(HEAD) exit=2 portrow=False [未知] Clash API: 该项检查无法执行：timed out
```

On the candidate the port row survives **and** the `[PROBLEM]` row appears, where the control raises
and the whole section collapses to one `[UNKNOWN]` row with the port row lost. **T-05's DEF-2 ("a
hung Clash port loses S6's port row") may be recorded closed.** The exit move is `2 → 1` for this
class and `0 → 1` for the non-object class (`BC-5 j5 control exit=0 [OK] … yes`), conditional on no
other section reporting `[PROBLEM]` — which is exactly what restricting the section set measures.

## Adversarial tests

One row per acceptance criterion. Each hypothesis was written before the run. Reproducers are
mine, written from the criterion; the developer's tests were not consulted for any of them.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-B1 | the egress line is the ISP address, not the proxied one, because the TUN device does not capture `urllib`'s socket — or the two endpoints disagree and there is no tie-break | `python3 <scratch>/rig/v7shrunk.py` (NEW) — candidate `sc status` against the **live** Clash API, then three independent echoes in the same minute | **BLOCKED as AC-B1** (root invocation impossible; see C-12). The comparison itself held: <br>`=== 出口 IP ===  38.47.117.142`<br>`echo ifconfig.me/ip -> 38.47.117.142`<br>`echo icanhazip.com -> 38.47.117.142`<br>`echo api.myip.com -> {"ip":"38.47.117.142",…}` |
| AC-B2 | some heading prints two value lines, or `ip`'s output lands under the wrong heading | Same run, both streams captured whole; per-heading line counting over the four fact sections (C-7) | **BLOCKED as AC-B2.** On the two live-Clash runs and on all 68 fixture runs the four fact sections were `[1, 1, 1, 1]`, exit 0, no `Traceback`. **But** the ordering is wrong when stdout is a pipe — QA-D1 below |
| AC-B3 | with `is_running` forced `True` the *control* still fails to traceback, because the fixture port is free by construction (F-7) and every state degrades to "nothing listening" | `python3 <scratch>/rig/v4.py` (NEW) — 17 states × en/zh × candidate/control | **Survived.** Trap did not fire (0/204 degenerate runs). <br>`BC-2 badjson en candidate rc=0 tb=False mode=(unavailable) facts=[1,1,1,1] port_ok=True`<br>`BC-2 badjson en control(HEAD) rc=1 tb=True  facts=[1,0,0,0] port_ok=True`<br>`BC-2 badjson zh candidate rc=0 tb=False mode=（不可用）` |
| AC-B4 | the egress failure line renders English on a `main()`-driven zh run because `main()` reassigns `LANG` after import (K-11) | `python3 -c "lib.run('ok', CAND, argv=('sc','status'), lang='zh', egress_break=True)"` (NEW) — language set only through the fixture `settings.json` | **Survived.** <br>`=== 出口 IP ===`<br>`（错误：<urlopen error [Errno -2] Name or service not known>）`<br>`rc=0 tb=False`, and the four preceding sections were already printed |
| AC-B5 | `sc use` still prints a bare `Switched to:` on a non-object body, because `cmd_use` tests `r is not None` and `{}` and `None` are both falsy | `python3 <scratch>/rig/v5.py` (NEW) — `sc use n2` over 9 states × 2 sides | **Survived — and the control exhibits the defect.** <br>`use BC-5 j5 candidate  Switched to: n2 (service restarted)`<br>`use BC-5 j5 control(HEAD) Switched to: n2`<br>`use BC-8 c204 candidate Switched to: n2` (204 still reads as success) |
| AC-S1 | `_egress_ip()` moved by the +6 line shift and stage 5's line-shift argument hid a whitespace change | `python3 <scratch>/rig/v1v9.py` (NEW) — `ast.get_source_segment` + sha256 on both sides | **Survived.** <br>`_egress_ip candidate sha256=78ec7c96a5ce9005eb47c8a6c7ac879a74b2c14b28bc081a6ca6c14cb8a52ab3 lines 391-400`<br>`_egress_ip HEAD      sha256=78ec7c96a5ce9005eb47c8a6c7ac879a74b2c14b28bc081a6ca6c14cb8a52ab3 lines 391-400` |
| AC-S2 | a hunk reaches outside `clash_api()` and the import block, or the `except` count grew | `git diff -U0 -- bin/sc`; `grep -c` for the three method literals and for `try:`/`except` line starts, both sides | **Survived.** <br>`hunks: @@ -6,0 +7 @@ · @@ -15 +15,0 @@ · @@ -1979,3 +1979,8 @@ · @@ -1990,2 +1995,2 @@ · @@ -1992,0 +1998 @@`<br>`"PUT" 1/1  "PATCH" 1/1  "DELETE" 0/0`<br>`try: 45/45   except 46/46` |
| AC-S3 | a translation moved because line numbers shifted, or the placeholder sets drifted | `python3 <scratch>/rig/v1v9.py` (NEW) — `ast.literal_eval(TRANSLATIONS)` on both sides | **Survived.** <br>`TRANSLATIONS candidate sha256=2824d051…ed9a6c lines 123-323`<br>`TRANSLATIONS HEAD      sha256=2824d051…ed9a6c lines 123-323`<br>`zh keys 144/144 added=0 removed=0 changed=0; placeholder mismatches: []` |
| AC-S4 | the CHANGELOG's `sc doctor` clause still over-generalises the before-state (CR-1), or names an identifier | `git diff -U0 CHANGELOG.md` + string assertions; `sed -n 39p docs/dev-map.md`; the CR-1 claims re-measured by `<scratch>/rig/v6.py` | **Survived.** <br>`added chars: 801 · contains 失败： False`<br>`sc status/ls/use/mode/doctor: True · clash_api/bin/sc/config.json/OSError/None: False`<br>and the per-class move is measured: `BC-5 j5 control exit=0 [OK] … yes` → `candidate exit=1 [PROBLEM]`; `BC-1 hang control exit=2 [UNKNOWN]` → `candidate exit=1 [PROBLEM]` |
| AC-S5 | the diff uses a post-3.6 construct that `py_compile` on 3.12 accepts silently | `python3 -m py_compile bin/sc`; `ast.parse(src, feature_version=(3,6))`; `git diff --name-only`; `verify_all` | **Survived.** <br>`py_compile OK`<br>`ast.parse(feature_version=(3,6)) OK on the whole candidate bin/sc`<br>`git diff --numstat bin/sc -> 12  6`<br>`PASS: 17  WARN: 0  FAIL: 0  SKIP: 1` |

**Four extra attacks on the *shape* of K-1's tuple, beyond the design's matrix.** Hypothesis: a
three-family catch is still an enumeration in disguise and some HTTP-layer failure escapes it.

```
fin_noresp   candidate rc=0 None | control rc=1 http.client.RemoteDisconnected: Remote end closed …
badstatus    candidate rc=0 None | control rc=1 http.client.BadStatusLine: GARBAGE NOT A STATUS LINE
chunkbad     candidate rc=0 None | control rc=1 http.client.IncompleteRead: IncompleteRead(0 bytes read)
deepnest60k  candidate rc=1 RecursionError  | control rc=1 RecursionError   (BC-12's disclosed residue)
```

**Survived, and it found two escaping classes the pipeline had not named.** `BadStatusLine` is an
`HTTPException` and neither an `OSError` nor a `ValueError` — a sixth HEAD-escaping class, after the
four in the insight index and the fifth stage 4 filed. It is independent second evidence that
`http.client.HTTPException` is load-bearing (CR-4 argued it from `IncompleteRead` alone). The
`RecursionError` row confirms C-8's qualified wording is *accurate* rather than defensive: the
unqualified "never an exception" it replaced would have been observably false.

**CR-3's mechanism, re-measured.** The split is by how the peer closes, not by where the client is:
an actual RST before the status line surfaces as a plain `ConnectionResetError`, a clean FIN with no
response surfaces as `RemoteDisconnected`. Three distinct HEAD-escaping close behaviours, not two.
No code consequence — all three are inside the candidate's tuple — and RES-2's instruction to
declare them **defect** states was followed for all three.

## Boundary tests added

- Nothing listening on the Clash port (`refused`), connection reset before the status line
  (`reset_status`), connection reset during the body read (`reset_body`), clean FIN with no response
  at all (`fin_noresp`) — four distinct close behaviours, each with its own declared control class.
- Empty body under a `204` and under a `200 Content-Length: 0` — both must stay `{}`, asserted by
  **value and type** (PA-1's silent-regression warning), on both sides.
- Valid JSON that is not an object, one state per value: `5`, `"x"`, `[1,2]`, `null` — declared
  individually, never as one BC-5 (C-5).
- Body that is not valid UTF-8 (`\xff\xfe\xfd\x80{}`), body that is not valid JSON, body shorter
  than its declared `Content-Length`, malformed HTTP status line, malformed chunk length.
- Unicode, an embedded NUL and an embedded CR inside a legitimate `mode` value — `règle-🌐-\x00-\r`
  reaches stdout verbatim on candidate and control alike (QA-D3).
- A newline inside a legitimate `mode` value — two value lines under one heading, candidate and
  control alike (QA-D2).
- 1 MiB response body — decodes and prints normally, both sides.
- JSON nested 6 000 deep (no `RecursionError` on this build; rejected by the `isinstance` gate) and
  60 000 deep (`RecursionError`, BC-12's disclosed residue, both sides).
- A peer that drips one body byte every 2 s — 30.1 s wall clock against a nominal `timeout=3`.
- BC-16 concurrency: 10 `sc status` fixtures against one stand-in simultaneously.
- BC-15 non-TTY: every one of the 365 runs in this report captured stdout and stderr through a pipe,
  never a terminal.
- Both languages on every `main()`-driven Clash state (68 `sc status` + 68 `sc doctor` runs), with
  the language set through the fixture `settings.json` and never through `sc.LANG` (K-11).

## verify_all result

```
command:                bash .harness/scripts/verify_all.sh
before (pre-report):    PASS 17 · WARN 0 · FAIL 0 · SKIP 1
after  (final tree):    PASS 17 · WARN 0 · FAIL 0 · SKIP 1
E.6 (Adversarial tests section, unnumbered): PASS — matched in this file (C-13, NFR-7)
F.6 (active task docs <=500 lines): PASS — 06_TEST_REPORT.md and 06_RATIONALE.md both under cap
Total tests: 0 -> 0 (no committed suite exists; R-9 is out of scope, B.3 is a standing SKIP)
Pass: 17
Fail: 0
Warn: 0
Skip: 1
New tests added: 0 committed; 365 uncommitted observation runs + 18 structural checks this stage
Baseline updated: no — test_count is 0 with nothing to raise, and .harness/** is outside NFR-2's
                  permitted diff and outside this stage's grant
Observations declared: 262 (244 behavioural + 18 structural)
Pass: 260 · Fail: 0 · Blocked/inconclusive: 2 (AC-B1, AC-B2)
Permitted diff (NFR-2): bin/sc, CHANGELOG.md, docs/dev-map.md — exactly E1-E4. `docs/tasks.md`,
                  `docs/batches/default/BATCH_PLAN.md` and the untracked
                  `docs/batches/default/BATCH_LOG.md` are also modified; all three are PM-owned and
                  were already modified before stage 4 started (`04_DEVELOPMENT.md` records this).
```

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| QA-D1 | MAJOR (pre-existing at HEAD; **not** introduced by T-18, no AC covers it) | `sc status > out.txt` on a systemd host, or any run in `<scratch>/rig/v4.json`: `ip -br addr show sb-tun`'s output appears **above** `=== Service status ===` instead of under `=== TUN interface ===`. `print()` is block-buffered when stdout is a pipe while the subprocess writes to fd 1 immediately, so the whole section order is scrambled in exactly the bug-report case. `sc doctor` already flushes per row for this reason. | `bin/sc:2225-2231` (`cmd_status`), against `bin/sc:2570-2571` / `:2552`'s own comment |
| QA-D2 | MINOR (pre-existing; a promise wider than the behaviour) | Stand-in returns `{"mode":"rule\nINJECTED SECOND LINE"}` → **two** value lines under `=== Route mode ===`, candidate and control alike (`<scratch>/rig/vnewline.json`). FR-3 and AC-B2 promise "exactly one value line" without qualification; BC-12 declines to defend against a hostile loopback peer but its wording is about a size cap, not about output shape. The promise, not the code, is what needs narrowing. | `01_REQUIREMENT_ANALYSIS.md` FR-3 / AC-B2 / BC-12; `bin/sc:2238` |
| QA-D3 | MINOR (pre-existing; agreement state) | Stand-in returns a `mode` containing `\r` and `\x00` → both reach `sc status`'s stdout verbatim (`<scratch>/rig/vunicode.json`), so BC-15's "no carriage return" does not hold against a peer that sends one. `sc status` deliberately does not scrub through `_plain()` (Q-7); `sc doctor` does. Unchanged from HEAD. | `bin/sc:2238` vs `bin/sc:2526` |
| QA-D4 | MINOR (documentation) | `02_SOLUTION_DESIGN.md` V4's expected column says the candidate prints "the real mode for BC-8". Measured, BC-8 is an *empty* body → `{}` → `{}.get("mode", t("(unavailable)"))` → `(unavailable)`, on candidate and control alike (`v4.json`, `BC-8 c204/empty200`). The behaviour is correct; the expectation was wrong. | `02_SOLUTION_DESIGN.md` § Verification plan, V4 |
| QA-D5 | MINOR (observation, out of scope item 10) | `sc ls`'s header prints the raw keys `ls.idx  ls.active  ls.type  ls.name  ls.address` in both languages — R-19, already filed, already out of scope for T-18. Recorded because it is visible in every `sc ls` transcript in this report and a reader should not mistake it for a T-18 regression. | `bin/sc` `TRANSLATIONS` / `cmd_ls` |

None of the five requires a change to T-18's diff. QA-D1, QA-D2 and QA-D3 are present identically on
the HEAD clone, so no regression exists; QA-D4 is an upstream expectation, QA-D5 is a known open row.
All five are for the PM to file, not for the developer to fix inside this task.

## Stability

- The direct-call totality matrix (17 states, candidate) ran **3 times**: identical
  `(exit code, type, value)` in every state, every run. Flakes: none.
- The six timing-sensitive states (`hang`, `short`, `reset_body`, `reset_status`, `chunkbad`,
  `fin_noresp`) ran **10 times** each — 60 runs. Each state produced one distinct outcome 10/10.
  Flakes: none.
- BC-16: **10 concurrent** `sc status` fixtures against one stand-in — exit codes `{0}`, tracebacks
  0, one distinct route-mode line (`rule`), 6 headings in every run, 0.92 s wall for all ten.
- Wall clock (R3 / RES-4, measurements not criteria): BC-1 direct call 3.07–3.09 s over 10 runs, so
  `timeout=3` does bound that state; `sc status` end to end at BC-1 3.86–4.02 s; the live-Clash
  `sc status` 0.88 s / 1.04 s. **A peer that drips one body byte every 2 s takes 30.1 s**, candidate
  and control alike, and returns a successful `{'mode': 'rule'}` — CR-5's "per socket operation, not
  total wall clock" turned into a number. Agreement state, so not a T-18 defect; the number belongs
  on R3's row.
- BC-10's own state (every node accepts and never answers) was **not** reproduced: it needs the
  node-side network conditions, not a Clash stand-in, and no fixture in this stage's grant creates
  them. Reported as unmeasured rather than as a pass.
- Nothing under `/etc/sing-box/**`, `/var/lib/sing-box`, `/usr/local/bin/sc` or the live service was
  written by any run: the `find -printf '%p %s %T@'` witness over both trees and
  `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` were taken before and after and are
  byte-identical (`MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` both times).
  The only live-port traffic in the whole session was two read-only `GET /configs`.

## Verdict

APPROVED FOR DELIVERY — 0 defects require a developer round; AC-B1 and AC-B2 are **BLOCKED**, not
passed and not substituted, on the operator obligation recorded under `## Test plan` (C-12).
