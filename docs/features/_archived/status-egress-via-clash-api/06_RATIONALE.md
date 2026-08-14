> Rationale portion for 06_TEST_REPORT.md. Non-binding.

# 06 — QA rationale · T-18 `status-egress-via-clash-api`

## Trigger record

- **T6.2** fired (reproducing a developer-claimed measurement: `04_DEVELOPMENT.md` § Open issues,
  the `ConnectionResetError` escaping HEAD's tuple). `04_RATIONALE.md` exists and was read.
- **T6.3** fired (re-testing CR-1, CR-3, CR-6 — not self-contained in `05_CODE_REVIEW.md`).
  `05_RATIONALE.md` exists and was read.
- **T6.1** did not fire: every acceptance criterion's verification step was executable as written
  except AC-B1/AC-B2, which are blocked on privilege, not on under-specification.

## The rig — built from scratch, not inherited

Stage 4 had a rig; none of it was reused. Everything below was written for this report, from the
acceptance criteria, not from `04_DEVELOPMENT.md`'s test code (T-17's standard).

| file | what it is |
|---|---|
| `<scratch>/rig/standin.py` | Raw-socket Clash API stand-in. 22 states. Writes the status line and headers itself, so a non-UTF-8 body, a short body, an RST mid-response, a bad chunk length and a malformed status line are all expressible. |
| `<scratch>/rig/drive.py` | One observation. Neutralises the import-time re-exec by `docs/dev-map.md`'s `sys.modules` recipe, repoints all eight path constants into a `mkdtemp()` root **and asserts each resolves inside it**, forces `is_running() -> True` (K-10), sets `SYSTEMD = OPENRC = False`, writes the fixture `settings.json` with `lang` **and** `clash_api_port` (K-11, C-9/F-7), records every URL opened and every subprocess spawned. |
| `<scratch>/rig/lib.py` | Starts the stand-in in one state on a fresh ephemeral port, drives one observation in a child process (so exit codes and both streams are real), tears the stand-in down. |
| `<scratch>/rig/v1v9.py` `v3.py` `v4.py` `v5.py` `v6.py` `v7shrunk.py` `vstab.py` | The step scripts. JSON transcripts beside each. |
| `<scratch>/headclone-t18` | `git clone` of the repository (K-12 — a clone, never a worktree). Verified: `sha256(clone/bin/sc) == sha256(git show HEAD:bin/sc) == 4fa09067bd44…5459d`. |

`<scratch>` = `/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad`.

**One deliberate deviation from a straight `main()` run, disclosed:** `sc._init_files` is replaced
with a fixture-local equivalent that creates `CFG_DIR` and `RULES_DIR` and nothing else. The real
`_init_files()` hard-codes `Path("/var/lib/sing-box").mkdir(...)`, which `docs/dev-map.md` names as
the one call that writes outside a fully redirected fixture. `_load_lang()` and
`_resolve_clash_port()` are left **real**, so K-11's and F-7's traps stay live rather than being
stubbed away.

## Full run — V3 (direct-call totality), candidate vs HEAD clone

```
BC-1  hang          candidate      rc=0 type=NoneType value=None                   tb=False   3.08s
BC-1  hang          control(HEAD)  rc=1 type=-        value=-                      tb=True  TimeoutError: timed out  3.08s
BC-2  badjson       candidate      rc=0 type=NoneType value=None                   tb=False   0.07s
BC-2  badjson       control(HEAD)  rc=1 type=-        value=-                      tb=True  json.decoder.JSONDecodeError: Expecting property name enclos  0.08s
BC-3  badutf8       candidate      rc=0 type=NoneType value=None                   tb=False   0.07s
BC-3  badutf8       control(HEAD)  rc=1 type=-        value=-                      tb=True  UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in   0.07s
BC-4  short         candidate      rc=0 type=NoneType value=None                   tb=False   0.27s
BC-4  short         control(HEAD)  rc=1 type=-        value=-                      tb=True  http.client.IncompleteRead: IncompleteRead(11 bytes read, 18  0.27s
BC-5  j5            candidate      rc=0 type=NoneType value=None                   tb=False   0.07s
BC-5  j5            control(HEAD)  rc=0 type=int      value=5                      tb=False   0.07s
BC-5  jstr          candidate      rc=0 type=NoneType value=None                   tb=False   0.07s
BC-5  jstr          control(HEAD)  rc=0 type=str      value='x'                    tb=False   0.07s
BC-5  jarr          candidate      rc=0 type=NoneType value=None                   tb=False   0.07s
BC-5  jarr          control(HEAD)  rc=0 type=list     value=[1, 2]                 tb=False   0.07s
BC-5  jnull         candidate      rc=0 type=NoneType value=None                   tb=False   0.07s
BC-5  jnull         control(HEAD)  rc=0 type=NoneType value=None                   tb=False   0.07s
BC-6  refused       candidate      rc=0 type=NoneType value=None                   tb=False   0.07s
BC-6  refused       control(HEAD)  rc=0 type=NoneType value=None                   tb=False   0.07s
BC-6  reset_status  candidate      rc=0 type=NoneType value=None                   tb=False   0.07s
BC-6  reset_status  control(HEAD)  rc=1 type=-        value=-                      tb=True  ConnectionResetError: [Errno 104] Connection reset by peer  0.07s
BC-6  reset_body    candidate      rc=0 type=NoneType value=None                   tb=False   0.87s
BC-6  reset_body    control(HEAD)  rc=1 type=-        value=-                      tb=True  ConnectionResetError: [Errno 104] Connection reset by peer  0.88s
BC-7  http404       candidate      rc=0 type=NoneType value=None                   tb=False   0.07s
BC-7  http404       control(HEAD)  rc=0 type=NoneType value=None                   tb=False   0.07s
BC-7  http500       candidate      rc=0 type=NoneType value=None                   tb=False   0.07s
BC-7  http500       control(HEAD)  rc=0 type=NoneType value=None                   tb=False   0.07s
BC-8  c204          candidate      rc=0 type=dict     value={}                     tb=False   0.07s
BC-8  c204          control(HEAD)  rc=0 type=dict     value={}                     tb=False   0.07s
BC-8  empty200      candidate      rc=0 type=dict     value={}                     tb=False   0.07s
BC-8  empty200      control(HEAD)  rc=0 type=dict     value={}                     tb=False   0.07s
--    ok            candidate      rc=0 type=dict     value={'mode': 'rule', 'port': 0} tb=False   0.07s
--    ok            control(HEAD)  rc=0 type=dict     value={'mode': 'rule', 'port': 0} tb=False   0.07s
```

Four states beyond the design's matrix, written to attack the *shape* of K-1's tuple:

```
fin_noresp  candidate      rc=0 type=NoneType  tb=False
fin_noresp  control(HEAD)  rc=1 type=-         tb=True  http.client.RemoteDisconnected: Remote end closed connection without respon
badstatus   candidate      rc=0 type=NoneType  tb=False
badstatus   control(HEAD)  rc=1 type=-         tb=True  http.client.BadStatusLine: GARBAGE NOT A STATUS LINE
chunkbad    candidate      rc=0 type=NoneType  tb=False
chunkbad    control(HEAD)  rc=1 type=-         tb=True  http.client.IncompleteRead: IncompleteRead(0 bytes read)
deepnest(6k) candidate     rc=0 type=NoneType  tb=False        (list -> isinstance gate -> None)
deepnest(6k) control(HEAD) rc=0 type=list      tb=False
deepnest(60k) candidate    rc=1 tb=True  RecursionError: maximum recursion depth exceeded while decoding a JSON array
deepnest(60k) control(HEAD) rc=1 tb=True RecursionError: maximum recursion depth exceeded while decoding a JSON array
```

**Reading.** `BadStatusLine` is an `http.client.HTTPException` and is neither an `OSError` nor a
`ValueError`, so it is a *sixth* escaping class at HEAD — beyond the four the insight index records
and beyond the fifth (`ConnectionResetError`) stage 4 filed. It is independent second evidence that
`http.client.HTTPException` is load-bearing (CR-4 argued the same from `IncompleteRead` alone), and
it is the strongest single argument against the leaf enumeration K-1 rejects: two of the six leaves
were unknown to the pipeline until this stage ran.

**On CR-3's mechanism.** CR-3 attributes variant (a) to `RemoteDisconnected` out of
`h.getresponse()`. Measured, the split is by *how the peer closes*, not by *where the client is*:
an actual RST before the status line surfaces as a plain `ConnectionResetError` (the receive queue
is discarded, `recv` fails with `ECONNRESET`), while a clean FIN with no response at all surfaces
as `RemoteDisconnected` (`recv` returns `b""`). So there are **three** distinct HEAD-escaping close
behaviours, not two. No code consequence — all three are inside the candidate's tuple — and RES-2's
operative instruction ("declare them defect states, not agreement states") is unchanged and was
followed.

**On BC-12's disclosed residue.** The published qualification is not defensive boilerplate: at
nesting depth 60 000 a `RecursionError` genuinely escapes `clash_api()` on the candidate, exactly as
`docs/dev-map.md:39` and the docstring say it can. At depth 6 000 the C scanner does not recurse
deep enough on this build (Python 3.12.3), and the body is simply a non-`dict` the gate rejects. The
qualified wording C-8 forced is therefore *accurate*, and the unqualified "never an exception" it
replaced would have been observably false.

## Full run — V6 (`sc doctor`'s Clash section), the C-3 / C-2 evidence

`DOCTOR_SECTIONS` was restricted to the Clash section and `cmd_doctor` itself was driven, so the
exit status is derived from that section alone — which is exactly C-2's "whenever no other section
reports `[PROBLEM]`" condition, made an observation instead of an assumption.

```
BC-1  hang         en candidate      exit=1 portrow=True  [OK] Clash API: 127.0.0.1:42713 | [PROBLEM] Clash API responding: no answer within the 3s timeout
BC-1  hang         en control(HEAD)  exit=2 portrow=False [UNKNOWN] Clash API: this check could not run: timed out
BC-1  hang         zh candidate      exit=1 portrow=True  [正常] Clash API: 127.0.0.1:38605 | [异常] Clash API 是否响应: 3 秒超时内无响应
BC-1  hang         zh control(HEAD)  exit=2 portrow=False [未知] Clash API: 该项检查无法执行：timed out
BC-5  j5           en candidate      exit=1 portrow=True  [OK] Clash API: 127.0.0.1:37273 | [PROBLEM] Clash API responding: no answer within the 3s timeout
BC-5  j5           en control(HEAD)  exit=0 portrow=True  [OK] Clash API: 127.0.0.1:40179 | [OK] Clash API responding: yes
BC-5  jnull        en candidate      exit=1 portrow=True  [OK] … | [PROBLEM] Clash API responding: …
BC-5  jnull        en control(HEAD)  exit=1 portrow=True  [OK] … | [PROBLEM] Clash API responding: …
BC-6  refused      en both sides     exit=1 portrow=True  (agreement)
BC-7  http404/500  en both sides     exit=1 portrow=True  (agreement)
BC-8  c204/empty   en both sides     exit=0 portrow=True  [OK] / [OK] Clash API responding: yes
```

BC-2, BC-3, BC-4, `reset_status`, `reset_body`, `fin_noresp` all behave as BC-1 does: candidate
`exit=1` with the port row, control `exit=2` with the port row lost. `jstr` and `jarr` behave as
`j5` does. All 68 rows are in `<scratch>/rig/v6.json`.

This is the per-class before-state CR-1's repair states, measured: the non-object class moves
`[正常]` → `[异常]` and `0` → `1`; the six raising classes move `[未知]` → `[异常]` and `2` → `1`.

## Full run — V5 (`sc use` / `sc mode`), and the C-11 statement

```
use  BC-5 j5    candidate  rc=0 tb=False  Switched to: n2 (service restarted)   svc=[] procs=[sing-box-stub x2]
use  BC-5 j5    control    rc=0 tb=False  Switched to: n2                       svc=[] procs=[]
use  BC-5 jnull candidate  rc=0 tb=False  Switched to: n2 (service restarted)
use  BC-5 jnull control    rc=0 tb=False  Switched to: n2 (service restarted)   (agreement)
use  BC-8 c204  both       rc=0 tb=False  Switched to: n2
use  BC-1 hang  candidate  rc=0 tb=False  Switched to: n2 (service restarted)
use  BC-1 hang  control    rc=1 tb=True   -
mode BC-1 hang  candidate  rc=0 tb=False  Route mode → global
mode BC-1 hang  control    rc=1 tb=True   -
mode BC-5/7/8   both       rc=0 tb=False  Route mode → global                   (agreement)
```

Every subprocess spawned across all 36 V5 runs, with argv:

```
["/tmp/t18-fx-rru6c4ky/sing-box-stub", "check", "-c",
 "/tmp/t18-fx-rru6c4ky/etc-sing-box/config.json"]     (twice — subprocess.run wraps Popen)
```

`sorted({argv[0].basename})` over all 36 runs is `['sing-box-stub']`. No `systemctl`, no
`rc-service`, no `rc-update` was issued by any run, and `sing-box check` ran only against the
fixture config. That is C-11, from the recorder rather than from the reasoning that
`SYSTEMD = OPENRC = False` makes `restart_service()` a no-op.

## Full run — the shrunk live observation (not AC-B1/AC-B2)

```
PRE  service: ['MainPID=2566751', 'ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST']
lang=zh rc=0 wall=1.04s urls=['http://127.0.0.1:29090/configs', 'https://api.ipify.org']
  === 服务状态 ===   (empty — SYSTEMD False)
  === TUN 接口 ===   sb-tun UNKNOWN 172.19.0.1/30 fe80::b18c:83d8:53b4:ff8c/64
  === 当前节点 ===   n1
  === 路由模式 ===   Rule
  === Clash API 端口 ===  127.0.0.1:29090
  === 出口 IP ===    38.47.117.142
lang=en rc=0 wall=0.88s   (same, English headings)
echo https://ifconfig.me/ip    -> 38.47.117.142   (0.94 s)
echo https://icanhazip.com     -> 38.47.117.142   (0.86 s)
echo https://api.myip.com      -> {"ip":"38.47.117.142","country":"United States","cc":"US"}
POST service: ['MainPID=2566751', 'ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST']
WITNESS DELTA (paths + service): NONE
```

`=== 路由模式 ===` reads `Rule`, not `（不可用）`, which is the proof the run really consulted the
**live** sing-box's Clash API rather than an absent one — the F-7 degeneracy, checked at the one
place it would matter most. The witness is `find /etc/sing-box -printf '%p %s %T@'` plus the same
over `/var/lib/sing-box` plus `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`, taken
before and after; the delta is empty on all three.

What this observation is **not**: it is not AC-B1/AC-B2. It ran at `geteuid() != 0` with the
re-exec neutralised and with the state files in a `mkdtemp()` root, not the real `/etc/sing-box`.
C-12 forbids substituting it for the blocked criteria, and this report does not.

## Why AC-B1/AC-B2 are blocked rather than failed

All five NFR-3 preconditions on the *host* hold and were recorded before anything ran:

```
/etc/sing-box/nodes.json     633 bytes, -rw------- root:root      exists
/etc/sing-box/settings.json   86 bytes, -rw-r--r-- root:root      exists, and records
                                                                  "clash_api_port": 29090
/var/lib/sing-box            exists (drwxr-xr-x, cache.db 32768 B)
127.0.0.1:29090              LISTEN (ss -ltn)
cmd_status                   makes exactly one Clash call, GET /configs (bin/sc:2236)
```

Because `clash_api_port` is already recorded, `_resolve_clash_port()` takes its early-return branch
and `sc status` writes nothing — the specific hazard C-12 names is absent. The blocker is the
*invocation*: `sudo -n true` reports `sudo: a password is required`, and this agent has no
interactive terminal. Running the candidate as a non-root user instead would take the import-time
`os.execvp("sudo", …)` branch and execute the **installed** `/usr/local/bin/sc` against the live
service, which is a red line. So the run was not performed.

## Measurements (R3 / RES-4 family), not criteria

| what | observed |
|---|---|
| `clash_api()` against a port that accepts and never writes (BC-1) | 3.07–3.09 s over 10 runs; `timeout=3` does bound this state |
| `sc status` end to end at BC-1 | 3.86–4.02 s (BC-1's 3 s plus the real egress query) |
| `clash_api()` against a peer that drips one body byte every 2 s | **30.1 s**, candidate and control alike, returning `{'mode': 'rule'}` |
| `sc status` against the live Clash API and the live network | 0.88 s / 1.04 s |

The 30.1 s figure is CR-5 / RES-4 turned from a source reading into a number: `timeout=3` bounds
each socket operation, and a peer that stays under it on every operation is unbounded in total. It
is an agreement state (identical at HEAD), so it is not a T-18 defect; it is the number the PM
should attach to R3's row so the next owner has a fact.

## Structural runs (RES-3 — stage 5 could not execute these)

```
_egress_ip     candidate sha256=78ec7c96a5ce9005eb47c8a6c7ac879a74b2c14b28bc081a6ca6c14cb8a52ab3 lines 391-400
_egress_ip     HEAD      sha256=78ec7c96a5ce9005eb47c8a6c7ac879a74b2c14b28bc081a6ca6c14cb8a52ab3 lines 391-400
TRANSLATIONS   candidate sha256=2824d051c9006b2197ca3776a39651cf49232f130100b4887a374c2594ed9a6c lines 123-323
TRANSLATIONS   HEAD      sha256=2824d051c9006b2197ca3776a39651cf49232f130100b4887a374c2594ed9a6c lines 123-323
zh keys candidate=144 HEAD=144  added=0 removed=0 changed=0
placeholder-set mismatches (whole table): []

git diff -U0 -- bin/sc  hunks: @@ -6,0 +7 @@ | @@ -15 +15,0 @@ | @@ -1979,3 +1979,8 @@
                                @@ -1990,2 +1995,2 @@ | @@ -1992,0 +1998 @@
"PUT" cand=1 head=1   "PATCH" cand=1 head=1   "DELETE" cand=0 head=0
try: cand=45 head=45  except cand=46 head=46
clash_api call sites: :2032 :2154 :2236 :2509 :2586   (five, C-4's corrected reading)
grep -c 'urllib\.error' bin/sc -> 0
python3 -m py_compile bin/sc -> OK
ast.parse(bin/sc, feature_version=(3,6)) -> OK
git diff --numstat bin/sc -> 12  6
docstring bin/sc:1979-1986 -> exactly 8 lines, first sentence reads "never raises one of the
                              three exception families its own body raises" (CR-6 repaired)
CHANGELOG added text: 801 chars; contains 失败： False; names sc status/ls/use/mode/doctor True;
                      names clash_api / bin/sc / config.json / OSError / None all False
```

`ast.parse(..., feature_version=(3,6))` is a real floor check rather than a reading: it rejects
walrus, positional-only parameters and `=` f-string debugging. The `f"http://…"` string in
`clash_api()` is pre-existing and unchanged by the diff.

## Things deliberately not done

- **`baseline.json` untouched.** There is no committed test suite (R-9 is out of scope, B.3 is a
  standing SKIP), `test_count` is 0 and this task adds no committed test, so there is no count to
  raise. `.harness/**` is also outside NFR-2's permitted diff and outside this stage's grant.
- **No mutating call to the live Clash API.** V5's `PUT /proxies/proxy` went to the stand-in in all
  36 runs; the only live-port traffic in the whole session was two `GET /configs`.
- **`sc doctor` run in full was not used for the exit-status evidence.** In a fixture its binary,
  rule-set and configuration sections report `[PROBLEM]` for reasons that have nothing to do with
  T-18, which would have made the exit status say nothing about the Clash section. Restricting
  `DOCTOR_SECTIONS` measures the conditional C-2 actually states.
