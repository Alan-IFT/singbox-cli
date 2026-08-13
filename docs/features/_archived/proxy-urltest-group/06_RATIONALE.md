# 06 — Rationale · T-15 `proxy-urltest-group`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

Full tool runs whose ≤5-line excerpts the contract portion cites, plus the measurement narrative.
Every suite lives under
`/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/qa/`.

## Rationale triggers that fired

- **T6.1** — `02` V-19's precondition is under-specified against S-5 (gate finding F-2 says so
  explicitly). `02_RATIONALE.md` was opened; it argues K-14 from one binary string
  (`missing domain resolver`, present ×1). That is an inference, not an observation, which is exactly
  why `t_v19.py` was built to falsify it. It survived.
- **T6.2** — C-6's disposition rests on a `strings /usr/local/bin/sing-box` transcript in
  `04_RATIONALE.md`. Read; not re-run, because C-6 changes no emitted key and `t_static.py` asserts
  the emitted shape directly (`interrupt_exist_connections` absent on the group, `True` on the
  selector). RES-4 stands: no live re-selection was observed *on the service*, though
  `t_control.py` observed one on a second process.
- **T6.3** — did not fire: every CR-1…CR-5 finding is self-contained in `05_CODE_REVIEW.md`.

## The harness, and why it is not stage 4's

`qa/h.py` is 130 lines written from `docs/dev-map.md:109-135`. Three things in it are assertions
rather than conventions, because that is what stops a forgotten constant:

```
assert sc.os is shim and sc.os.geteuid() == 0      # S-1: the elevate branch was not taken
assert sys.modules["os"] is os                     # and the shim was restored
for name in SEVEN: assert realpath(getattr(sc,name)).startswith(root)   # S-3
sc._init_files = _poison("_init_files")            # S-2: driving it raises, loudly
sc.SYSTEMD = sc.OPENRC = False                     # S-4
```

One harness bug is worth recording because it would have made every AC-14 observation meaningless:
seeding `RULES_DIR` with `b"SRS" + b"\x00"*4096` passes `sc`'s own `SRS_MAGIC` / `SRS_MIN_BYTES`
check but the **real** binary rejects it —
`FATAL initialize router: parse rule-set[0]: zlib: invalid header`. `h.seed()` therefore copies the
real `.srs` bytes read-only out of `/etc/sing-box/rules` (mode 0644, no sudo, nothing written under
`/etc`). This is T-05's "fixtures hide what the real binary rejects" in its mirror image: a fixture
can also make the real binary reject what it would accept.

## RES-2 — the frozen set, full run

```
$ python3 qa/frozen.py
_resolve_node          IDENTICAL  (801 bytes head / 801 cand)
clash_api              IDENTICAL  (752 bytes head / 752 cand)
_merge                 IDENTICAL  (2500 bytes head / 2500 cand)
_directive_of          IDENTICAL  (1434 bytes head / 1434 cand)
_apply_directive       IDENTICAL  (1448 bytes head / 1448 cand)
_write_private         IDENTICAL  (2353 bytes head / 2353 cand)
cmd_now                IDENTICAL  (100 bytes head / 100 cand)
cmd_status             IDENTICAL  (891 bytes head / 891 cand)
_warn_drift            IDENTICAL  (1198 bytes head / 1198 cand)
restart_service        IDENTICAL  (199 bytes head / 199 cand)
reload_or_restart      IDENTICAL  (114 bytes head / 114 cand)
DIRECTIVES             IDENTICAL
CONFIG_BASE.dns        IDENTICAL  (1576 bytes)
default_domain_resolver IDENTICAL  ['        "default_domain_resolver": {"server": "direct_dns"},']
the five ls.* keys     IDENTICAL  (5 keys)
timeout=3 in clash_api:  head=1 cand=1 occurrences
generate_config order    head warn@[47] write@[51] record@[56] | cand warn@[53] write@[57] record@[62]
ordering warn<write<record preserved: True

FROZEN-SET RESULT: 0 anchor(s) differ
```

Non-vacuity, and a lesson about the check itself. The first mutation attempt used
`s.replace("timeout=3","timeout=5",1)` and the check still said `clash_api IDENTICAL` — because the
file's *first* `timeout=3` substring is `timeout=30` at `bin/sc:989`, in `_fetch_to_temp`, which is
not frozen. Re-mutating the whole statement:

```
$ python3 qa/mutate_frozen2.py
clash_api              *** DIFFERS ***  (752 bytes head / 752 cand)
-        with urllib.request.urlopen(req, timeout=3) as r:
+        with urllib.request.urlopen(req, timeout=9) as r:
FROZEN-SET RESULT: 1 anchor(s) differ        exit status: 1
```

Two conclusions: the check does fail when an anchor moves, and a grep-based freeze check on this file
is unsound — `timeout=3` is a prefix of `timeout=30`. Stage 4 reports having grepped; the AST
extraction here is what makes the claim byte-exact.

## DEF-1 — the four escape routes out of `clash_api()`

```
$ python3 qa/t_broken.py
== P2  RES-1/CR-1: a 200 text/html body on the Clash port ==
  OBSERVED: json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
  frames:   sc:1748 cmd_ls <- sc:1673 stored_delays <- sc:1637 clash_api <- __init__.py:346 loads
  HEAD `sc status` with the same stub: 'json.decoder.JSONDecodeError: Expecting value: line 1 …'
  PASS  RES-1 is PRE-EXISTING: HEAD's own `sc status` raises the same way
== P4  a 2xx body that is not valid UTF-8 ==
  OBSERVED: UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 0
== P3  BC-9: connection refused, and a port that never answers ==
  PASS  BC-9 refused: no exception, table intact, all cells '-' :: exc=None dt=0.0002
  OBSERVED: TimeoutError: timed out
  frames:   sc:1748 cmd_ls <- sc:1673 stored_delays <- sc:1635 clash_api
  PASS  BC-9 hung port: bounded by the existing 3 s timeout, nothing longer :: 3.00 s
  HEAD `sc status`: TimeoutError('timed out') after 3.00 s
== P6  a 2xx whose Content-Length over-declares the body ==
  OBSERVED: http.client.IncompleteRead: IncompleteRead(15 bytes read, 50 more expected)
```

Why this is worse than CR-1's compound-reachability analysis. The reviewer scoped RES-1 to
"sing-box running while a *foreign* HTTP server holds the persisted Clash port" — a conjunction that
is genuinely rare. The `TimeoutError` route needs no foreign server at all: sing-box's own Clash
listener accepting a connection and not answering within 3 s is enough, which is a plausible state on
exactly the loaded or wedged host a user reaches for `sc ls` on. And BC-9 enumerates four states;
two of them (stopped, refused) survive and two (hung, answering-but-not-sing-box) do not, so AC-24 is
half-met rather than met-with-a-corner-case.

Why it is nevertheless not a route-back to the developer: `clash_api()` is byte-identical to HEAD and
AC-28 requires it to be; K-12 forbids a `try`/`except` inside `stored_delays()`. There is no edit
inside this task's permitted set that fixes it. The correct owner is a follow-up row against
`clash_api()` itself — widening the two-exception catch, which would fix `sc status`, `sc mode` and
`sc use` at the same time. RES-1 as filed names one body shape; the row should name the class.

## AC-25 / BC-10 — the 28 bodies

Driven through `cmd_ls()`, not through `stored_delays()`, because `05` already establishes that
`stored_delays()` is total on its own and the question an independent tester adds is whether the
*command* survives. Bodies: top level `[]` / `"hello"` / `null` / `42`; `proxies` absent / list /
null; entry non-dict; `history` absent / `"x"` / `[]` / `[[1]]` / `[None]`; `delay` absent / `"90"` /
`90.5` / `True` / `0` / `-5` / `10**30` / `{"a":[1]}`; `now` `7` / `""` / `"GHOST-9"` / 400×`"X"`;
proxy set omitting every known node; `{}`; a unicode tag key. Each × `en` and `zh`, each checked for
exception, traceback text, row count, `\r`, trailing whitespace and fabricated values.

```
  PASS  AC-25/BC-10: all 28 malformed bodies x 2 languages survive cmd_ls :: []
  group row when the API's `now` names a node sc does not know:
    '      ●   urltest     auto                            → GHOST-9                       5 ms'
  PASS  BC-15: a 400-char `now` is truncated, the row stays one line :: len=90
```

`→ GHOST-9` is correct behaviour, not a defect: FR-13 says `sc ls` states which node the group is on,
and the running sing-box is the authority on that. Inventing a "must be one of my nodes" filter would
be `sc` forming a second opinion about a fact it reads.

## V-19, run — the full transcript

The route: a **second** sing-box process, unprivileged, in the scratchpad, on the document `sc` emits.
The group is *selected* because `_valid_selection()` makes it `proxy.default` at generation time — so
`02`'s precondition is reached with **no** `PUT`, no `sc use`, and no live-service state change.
Three forced deviations, all recorded in the file's own header: the `tun` inbound is dropped
(CAP_NET_ADMIN), `experimental.cache_file.path` is moved into the fixture (`/var/lib` is root-only),
and the three node outbounds are `socks` outbounds pointing at a local relay, because the owner's real
credentials are 0600 root and were not read. The group object itself, the whole `dns` section and
`route.default_domain_resolver` are the emitted ones, untouched.

```
$ python3 qa/t_v19.py
  PASS  the document `sc` emits for these nodes passes the real checker
  PASS  V-19 precondition WITHOUT a PUT: the group is the selector's own default :: default='auto'
  group as emitted: {"type": "urltest", "tag": "auto", "outbounds": ["R-1","R-2","DEAD-3"],
    "url": "https://www.gstatic.com/generate_204", "interval": "3m", "tolerance": 50,
    "idle_timeout": "30m"}
  PASS  S-4: this is a SECOND sing-box, not the service (different pid) :: pid=292620
  entries: ['DEAD-3', 'GLOBAL', 'R-1', 'R-2', 'auto', 'direct', 'proxy']
  PASS  the running process reports an `auto` URLTest group :: 'URLTest'
  PASS  `proxy` is on `auto` from startup -- no PUT was ever issued :: 'auto'
    t=1s  histories: {'auto': 916, 'R-1': 980, 'R-2': 916}
  SOCKS5 CONNECTs recorded: atyp={3} hosts={'www.gstatic.com'}
  PASS  AC-15/K-14 CONFIRMED BY OBSERVATION
ls.idx  ls.active  ls.type     ls.name                    ls.address                Delay
      ●   urltest     auto                            → R-2                         916 ms
   1      socks       R-1                             127.0.0.1:36401               980 ms
   2      socks       R-2                             127.0.0.1:36401               916 ms
   3      socks       DEAD-3                          127.0.0.1:1                        -
```

The `ATYP=3` line is the whole answer to BC-12. SOCKS5 address type 3 is *domain*: sing-box handed
the literal string `www.gstatic.com` to the member outbound instead of an address it had resolved
itself. No local DNS server was consulted, so `dns.rules` was never traversed, so `remote_dns` and
its `detour: proxy` were never reached, so the probe cannot depend on the group it is probing.
K-14's inference from a binary string is now an observation. RS-2's counterfactual third branch
remains counterfactual and stays re-homed to T-16.

`RS-3/RES-5` is also visible on real data here: `DEAD-3` was probed, failed, and renders `-`.

## DEF-2 — the headline behaviour, three fault classes

`01 §2` states the goal as "a degraded node stops carrying traffic … without human intervention".
No AC-1…AC-35 observes it (DEF-4). Three runs, each a second unprivileged sing-box on the emitted
document with a `mixed` inbound and `route.final = "proxy"`, real traffic to
`http://cp.cloudflare.com/generate_204` every 10 s.

**Positive control first** (`qa/t_control.py`), because a negative result is worthless without one.
Only the members' latency changes; nothing ever refuses or hangs:

```
  phase 1: A lag=400ms  B lag=0   -> now='NODE-B'  hist={'NODE-A': 1102, 'NODE-B': 728}
  phase 2: latencies swapped. No command issued.
    t=150s now=NODE-B  traffic=204    histA=1102 histB=728
    t=182s now=NODE-A  traffic=204    histA=884  histB=1133
  PASS  CONTROL: the group re-selected … :: moved after 183 s
```

So the harness can see a re-selection, and I-10's "worst case ≈ one interval" is confirmed by
measurement (183 s against an emitted `interval` of 3m).

**Refusing member** (`qa/t_refuse_long.py`) — the listener is closed:

```
    t= 10s now=NODE-A  traffic='HTTPError'    histA=740  histB=719
    t= 20s now=NODE-A  traffic='HTTPError'    histA=None histB=719
    …  (17 consecutive samples, every request HTTPError, now unchanged)
    t=190s now=NODE-B  traffic='HTTPError'    histA=None histB=1693
  PASS  the group left the degraded member with NO human command :: moved after 190 s
```

It recovers — after one full `interval`. Note `histA=None` from t=20: the failed dial deletes the
history immediately, yet the selection does not move for another 170 s. So the delay column can show
`-` for the member that is *still carrying all the traffic*, for up to three minutes. That is a
truthful rendering of a stored fact, but it is not what a user would guess it means.

**Hanging member** (`qa/t_hang_long.py`) — accepts the TCP connection, never answers. This is the
failure `01 §1.2` leads with ("TLS handshakes that hang rather than refuse"):

```
    t= 20s now=NODE-A  traffic='TimeoutError' histA=692  histB=724 conns A=+1  B=+0
    t=180s now=NODE-A  traffic='TimeoutError' histA=692  histB=724 conns A=+10 B=+1
    t=300s now=NODE-A  traffic='TimeoutError' histA=None histB=710 conns A=+16 B=+1
    t=440s now=NODE-A  traffic='TimeoutError' histA=None histB=710 conns A=+23 B=+1
  FAIL  the group left the degraded member with NO human command :: moved after never s
```

Read the counters. `conns A=+10 B=+1` at t=180 proves the interval check ran on schedule. `histA`
stayed at its stale `692` through two intervals while `histB` was refreshed, so the min-delay
comparison kept choosing the dead member. And the decisive line is t=300: `histA` finally became
`None` — and the group *still* did not move for the remaining 140 s, which means invalidating the
history is not sufficient either; the cached selection is only revisited when a check completes, and
a check that hangs never completes. Three independent runs (240 s, 260 s, 440 s) gave the same
outcome, against a control that moved in 183 s.

Nothing in this diff is wrong. Nothing in the emitted parameters can fix it either — sing-box's
`urltest` exposes no per-probe timeout, and `interval` / `tolerance` / `idle_timeout` are all already
at defensible values (I-9…I-12 survive this scrutiny unchanged). The defect is that both READMEs and
`CHANGELOG.md` promise the behaviour without the qualification, and the docs are inside NFR-5's
permitted diff. A one-clause qualification — the switch takes up to one probing interval, and a node
that hangs rather than refuses may need `sc use <node>` — makes the promise true and costs no code.

## What this changes about the four insight candidates in `04`

- **`interrupt_exist_connections` governs external connections only** — not tested here and not
  contradicted; the emitted shape is asserted, the semantics are not. RES-4 stands.
- **empty member list is a hard rejection** — reproduced independently, exit 1, `missing tags`.
  Confirmed.
- **a `urltest` emitted before the members it references is accepted** — confirmed on seven
  documents plus two live processes.
- **`/proxies` carries `now`** — confirmed, and **sharpened**: the response also carries entries that
  are not `sc` outbounds at all. The live pre-T-15 service returns `GLOBAL`, and the second process
  returned `['DEAD-3','GLOBAL','R-1','R-2','auto','direct','proxy']`. `stored_delays()` returns all
  of them by design (FR-11 forbids an `sc ls`-specific filter), which is right — but it is why DEF-3
  exists, and any future caller must know the map is not node-keyed.

A fifth candidate this stage adds: **on a pre-T-15 host every url-test history is empty**, measured
read-only on the live service (`{'GLOBAL': 0, 'proxy': 0, '233boy-…': 0, 'direct': 0}`). F-6's
prediction that an upgraded pinned host shows `-` everywhere is not a guess; it is the observed state
of the owner's own machine right now.

## DEF-2, closing it — the full run

The defect was that the docs promised unattended failover with no bound. The remedy was never code:
the behaviour is sing-box's `urltest`, and the three measurements are what they are. So the only
question worth verifying is whether the shipped sentences now say what the stopwatch said.

I did **not** re-derive that from the developer's diff. `qa/t_def2.py` asserts the claim atoms I
extracted from my own measurements — promise, probe-round mechanism, ~3 min magnitude, hang carve-out
with its mechanism, observation plus manual escape — independently in each language, then sweeps both
files for any surviving unqualified promise outside `:89`, then checks the promise and its bound are
one semicolon-joined sentence (a bound in a later paragraph is a bound a reader skips), then a mutant
arm deletes the bound clause and confirms the suite notices.

```
$ python3 qa/t_def2.py
  PASS  README.md:89 -- BOUND 1 magnitude: ~3 min of failing requests, not instant :: all 2 phrases present
  PASS  README.zh-CN.md:89 -- BOUND 2: the hang is carved out, with its mechanism :: all 3 phrases present
  PASS  zh: joined by a semicolon, not left as two independent statements :: '不需要任何人敲命令；但切走发生在**'
  PASS  README.zh-CN.md: :89 is the ONLY place the unattended promise is made :: no other occurrence
  PASS  mutant arm (bound clause removed) IS detected :: missing=['next probe round', 'not an instant cut-over']
FAILURES: 0
```

Two judgements are mine and belong on the record, because no other stage holds the numbers.

**"up to about 3 minutes" against 190 s.** The refusing member moved at 190 s, which is 3 m 10 s, and
"about 3 minutes" rounds down across it. I accept this: the figure a reader can act on is the probe
`interval`, which *is* 3 m, and the sentence's operative claim — "the switch happens on the next probe
round … not an instant cut-over" — is exactly the mechanism I observed, in both the 183 s and the
190 s run. Had the text said "at most 3 minutes" I would have filed it; "up to about" with the
mechanism named alongside is a fair statement of a period-quantised delay.

**The zh generalises the hang slightly further than the en.** `实测中组会一直留在这种节点上，测多久都不动`
reads "no matter how long you test", where the en says "for as long as the test ran". My data is
440 s over three runs, so the zh is the wider empirical claim. I accept it because both languages
already carry the *unbounded mechanistic* claim it follows from — en "a probe that never finishes
never revises the choice", zh `一次永远结束不了的探测也就永远不会更新选择` — and because it errs toward
warning the reader, not toward promising them. NFR-3 parity is about the claim set, and the claim set
matches atom for atom.

The en names the manual escape as "switch by hand" and the command `sc use <name>` in the following
sentence rather than the same one; the zh does the same thing in the same two positions, and
`CHANGELOG.md:7` names `sc use <名称>` inline. Mirrored, so not a parity finding.

## Why round 2 re-ran almost nothing

`bin/sc` in the tree hashes `ae8198cf…82f8`, byte-identical to `qa/cand_sc`, the copy every suite ran
against. The 13-suite battery therefore still describes this code exactly; re-running the two
live-sing-box timing suites would have cost ~14 minutes to re-measure a binary and a config that did
not change. What did change is text, and text is what round 2 tested: `t_readme.py` (unchanged from
round 1, so it is a regression arm here — the edit sits two lines above C-8's paragraph and could
have shifted it) and the new `t_def2.py`. Both clean. `verify_all` re-run for C-9.

F.6's WARN now covers two files, not one: `01_REQUIREMENT_ANALYSIS.md` at 597 lines and `PM_LOG.md`
at 504. Neither is QA's to edit and both leave the glob on archive; the check counts one WARN either
way, so C-9's bar is unaffected.

## Safety ledger

- S-6 witness, start and end of stage — including a fresh reading at the end of round 2:
  `MainPID=2566751`,
  `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` — identical. The 2026-08-11 start predates this
  batch; the drift from `01 §9 S-6`'s figure is pre-existing, as the dispatch states.
- S-5: every `PUT`/`PATCH`/`DELETE` in this stage went to a `http.server` stub bound to
  `127.0.0.1:0`. Against the live API only `GET /proxies` and `GET /configs` were issued.
- S-4: `/usr/local/bin/sc` was never invoked. `/usr/local/bin/sing-box` was invoked as `check` (read
  only) and as `run` against scratchpad configs in three short-lived child processes, each terminated
  in a `finally`; `pgrep -a sing-box` at the end of the stage shows one process, the service's own.
- S-3: `/etc/sing-box/` mtimes unchanged; the only `/etc` access was reading the world-readable
  `rules/*.srs`.
- `git status` at the end of the stage lists exactly the pre-existing modified files plus this task's
  stage-doc directory. No harness file entered the repo (NG-9).
