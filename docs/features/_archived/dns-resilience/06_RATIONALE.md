# 06 — Rationale · T-16 `dns-resilience`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

Full tool runs whose ≤5-line excerpts the contract cites, plus the measurement narrative. Nothing here
is a claim the contract does not already carry.

## What was rebuilt versus inherited

Inherited as **instructions only**: the C-7 fixture recipe (`04_DEVELOPMENT.md:108-166`), the four
declared derivations (DR-4/DR-5), the `.test`/`geosite-private` trap, the `{"action":"sniff"}`
prerequisite, and `route.default_domain_resolver`'s necessity. Rebuilt from scratch in this session:
the import shim, the eight-constant repoint and its assertion, both UDP stub resolvers, the hang
listener, the instance manager, the `dig` driver, every probe classification, and every number.

Nothing was taken from `04_RATIONALE.md`'s transcripts. The probe classification was re-derived by
measurement, not assumed — the smoke run below is the first thing that ran, before any assertion was
written:

```
dns.rules[0]: {"action": "predefined", "rcode": "NOERROR", "query_type": [28, 64, 65]}
doh.pub            A       status=NOERROR  ans=2    8.2ms      <- hosts table, no stub
360.cn             A       status=NOERROR  ans=1   18.6ms      <- direct stub (domestic suffix)
baidu.com          A       status=NOERROR  ans=1   18.0ms      <- direct stub (geosite-cn)
t16-nomatch.org    A       status=NOERROR  ans=1    8.5ms      <- remote stub (no rule -> final)
www.google.com     A       status=NOERROR  ans=1    7.2ms      <- remote stub (geosite-google)
remote stub log: [('t16-nomatch.org', 1), ('www.google.com', 1)]
direct stub log: [('360.cn', 1), ('baidu.com', 1)]
```

`probe-x.test` was separately confirmed to reach the **direct** stub (`geosite-private` matches the
`test` TLD), so it was used as the `geosite-private` probe and never as the no-rule probe.

The HEAD baseline is a `git clone --no-hardlinks` at `9f85f9e` (`.git` a real directory, so nothing
about `verify_all`'s A.1/A.2 is affected — a `git worktree` would have made `.git` a file). Its
`bin/sc` was verified to be the pre-T-16 shape before use:

```
$ grep -n "query_type\|IF_INET6_PATH\|ipv6" <clone>/bin/sc
1101:            {"action": "predefined", "rcode": "NOERROR", "query_type": [64, 65]},
```

One line, at rules index 3, and no IPv6 code at all — i.e. the repository HEAD, **not** the installed
`/usr/local/bin/sc` with its 2026-08-01 `[28, 64, 65]` hand-patch. That binary was never invoked and
`/usr/local/bin/sc.bak-2026-08-01-1006` was never touched.

## Safety envelope actually enforced

`t16lib.load_sc()` implements `docs/dev-map.md:107-137` verbatim: `assert os.geteuid() != 0`, an `os`
shim whose `geteuid` returns 0 so the elevate branch is not taken, `exec(compile(...))`, and
`sys.modules["os"] = os` restored in a `finally`. It then repoints
`CFG_DIR / CFG_PATH / NODES_PATH / SETTINGS_PATH / RULES_DIR / OVERRIDE_PATH / STATE_PATH /
IF_INET6_PATH` into one `mkdtemp()` root and **asserts each resolves inside it** (seven for HEAD, which
has no `IF_INET6_PATH`), sets `SYSTEMD = OPENRC = False`, `SB_BIN = /usr/local/bin/sing-box` and
`CLASH_PORT` to the fixture's own free port. `_init_files()` is never called; `nodes.json`,
`settings.json` and `rules/*.srs` are seeded directly. `tempfile.tempdir` points at the session
scratchpad, so not one byte was written under `/etc` or `/var/lib`.

`sing-box check` against the real binary is the only use of the installed sing-box; every fixture
instance is `sing-box run -c <fixture>.json -D <fixture root>`, unprivileged, no TUN inbound, own
`cache_file.path`, own Clash port, and is terminated in a `finally`.

## Live-service witness, verbatim, at every checkpoint

Recorded before and after every script (`systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`,
never `is-active`):

```
MainPID=2566751
ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
```

Identical at the start of the session, between every scenario, and after the last run — the same values
`04_DEVELOPMENT.md:77` recorded, so the service has not been bounced since 2026-08-11. Final process
check:

```
$ ps -eo pid,ppid,etimes,cmd | grep -E "sing-box|beh.py|classtext"
2566751       1  251982 /usr/local/bin/sing-box run -c /etc/sing-box/config.json
```

One process, the live one. No fixture instance, stub thread or hang listener survives.

## AC-B1 / AC-B2 / AC-B3 / AC-B9 — full transcript with controls

`python3 beh.py b1239`, one `mkdtemp` root per scenario, candidate and HEAD in turn at that same root:

```
{"ac":"AC-B1/V-26","run":"cand","probes":[{"q":"doh.pub/A","status":"NOERROR","ans":2,"ms":20.0},
 {"q":"360.cn/A","status":"NOERROR","ans":1,"ms":18.4},{"q":"t16-nomatch.org/TYPE64","status":"NOERROR","ans":0,"ms":8.5}],
 "remote_stub":[],"direct_stub":[["360.cn",1]],
 "suppression_rule":{"action":"predefined","rcode":"NOERROR","query_type":[28,64,65]}}
{"ac":"AC-B1/V-26","run":"head","probes":[... 8.5 ms, 18.2 ms, 17.9 ms ...],"remote_stub":[],"direct_stub":[["360.cn",1]]}
{"ac":"AC-B2/V-27","run":"cand","probes":[... 21.5, 19.5, 10.0 ms ...]}   {"run":"head", ... 22.0, 23.3, 19.6 ms}
{"ac":"AC-B3/V-28","run":"cand","probes":[... 18.9, 20.6, 9.7 ms ...]}    {"run":"head", ... 20.4, 20.4, 22.0 ms}
{"ac":"AC-B9/V-34","run":"cand","probes":[... 10.4, 20.1, 10.6 ms ...]}   {"run":"head", ... 22.6, 26.3, 11.5 ms}
```

Worst wall clock anywhere in the four agreement scenarios: **26.3 ms**, against a 100 ms bound. The
third probe is **TYPE64** in `rule` mode, per C-1 — a type HEAD already suppresses *in that mode*, which
is what makes the HEAD run a genuine agreement control. (The class measurement below shows why the mode
matters: in `global` mode HEAD leaves even TYPE64 unanswered, so a TYPE64 probe there would not have
been an agreement control either.)

AC-B9 was additionally re-run with `d["outbounds"]` taken **verbatim** from the emitted 0-node document
(no staging at all — the selector collapses to `direct` by construction), which is the more faithful
reading of "with zero nodes":

```
{"ac":"AC-B9/V-34 (outbounds verbatim)","run":"cand","outbounds":["proxy","direct"],
 "rows":[{"q":"doh.pub/A","status":"NOERROR","ans":2,"ms":18.3},{"q":"360.cn/A",...,"ms":18.2},
         {"q":"t16-nomatch.org/TYPE64","status":"NOERROR","ans":0,"ms":17.9}]}
{"ac":"AC-B9/V-34 (outbounds verbatim)","run":"head", ... 18.7, 18.6, 18.9 ms ...}
```

## AC-B4 / AC-B6 — the defect-reproducing controls, both rounds

`python3 beh.py b46`, round 1:

```
{"ac":"AC-B4/V-29","run":"cand","mode":"rule","probes":[{"q":"t16-nomatch.org/AAAA","status":"NOERROR","ans":0,"ms":19.7,"timeout":false}],"remote_stub":[],"direct_stub":[]}
{"ac":"AC-B6/V-31","run":"cand","mode":"global","probes":[... "NOERROR","ans":0,"ms":18.3 ...],"remote_stub":[],"direct_stub":[]}
{"ac":"AC-B6/V-31","run":"cand","mode":"direct","probes":[... "NOERROR","ans":0,"ms":18.6 ...],"remote_stub":[],"direct_stub":[]}
{"ac":"AC-B4/V-29","run":"head","mode":"rule","probes":[{"status":null,"ans":0,"ms":15030.0,"timeout":true}],
 "sblog":["+0800 2026-08-14 10:00:19 ERROR [477970098 10.0s] dns: exchange failed for t16-nomatch.org. IN AAAA: context deadline exceeded"]}
{"ac":"AC-B6/V-31","run":"head","mode":"global","probes":[{"status":null,"ms":15031.2,"timeout":true}],"remote_stub":[],"direct_stub":[]}
{"ac":"AC-B6/V-31","run":"head","mode":"direct","probes":[{"status":"NOERROR","ans":1,"ms":18.4}],"remote_stub":[],"direct_stub":[["t16-nomatch.org",28]]}
```

Round 2 (rerun for stability): candidate `19/19/19 ms`, HEAD `15031 ms` / `15021 ms` /
`NOERROR ans=1 9 ms` with `direct_stub=[['t16-nomatch.org', 28]]`. Identical classification.

This is C-2's corrected clause observed exactly: in `global` HEAD stalls at sing-box's own 10.0 s
deadline (the client's outcome arrives at *its* 15 s limit, which is why no user ever sees "10 s"); in
`direct` a stall is impossible because `bin/sc:1100` at HEAD sends the query to `direct_dns`, so the
defect there is the **absence of suppression** — HEAD issues the AAAA query to the non-proxied resolver
and answers it.

Mode changes were issued to the **fixture's** controller (`PATCH http://127.0.0.1:<fixture port>/configs`,
with `assert port != 29090` in the code path). The live Clash API received nothing.

## AC-B5 and V-36 — the "issues no upstream query" half

```
{"ac":"AC-B5/V-30","run":"cand","probes":[{"q":"t16-nomatch.org/AAAA","status":"NOERROR","ans":1,"ms":19.3}],
 "remote_stub":[["t16-nomatch.org",28]],"rule0":{"action":"predefined","rcode":"NOERROR","query_type":[64,65]}}
{"ac":"AC-B5/V-30","run":"head", ... "ans":1,"ms":18.7, "remote_stub":[["t16-nomatch.org",28]]}
{"ac":"AC-B4/V-36","run":"cand","probes":[{"q":".../A","ans":1,"ms":18.3},{"q":".../AAAA","ans":0,"ms":7.3}],
 "remote_stub":[["t16-nomatch.org",1]]}
{"ac":"AC-B4/V-36","run":"head","probes":[{".../A","ans":1},{".../AAAA","ans":1,"ms":17.8}],
 "remote_stub":[["t16-nomatch.org",1],["t16-nomatch.org",28]]}
```

With a **usable** node the upstream is reachable, so "no upstream query" is observed rather than inferred
from an unreachable upstream: the candidate's proxied stub saw type `1` and not `28`; HEAD's saw both.

## AC-B7 — the 36-combination differential, 0 mismatches

`python3 beh.py b7`. Which stub received each type-A probe, candidate first, HEAD second:

| rule-sets | mode | doh.pub | 360.cn | baidu.com | probe-x.test | www.google.com | t16-nomatch.org |
|---|---|---|---|---|---|---|---|
| usable | rule | none / none | direct / direct | direct / direct | direct / direct | remote / remote | remote / remote |
| usable | global | none / none | remote / remote | remote / remote | remote / remote | remote / remote | remote / remote |
| usable | direct | none / none | direct / direct | direct / direct | direct / direct | direct / direct | direct / direct |
| none | rule | none / none | direct / direct | remote / remote | remote / remote | remote / remote | remote / remote |
| none | global | none / none | remote / remote | remote / remote | remote / remote | remote / remote | remote / remote |
| none | direct | none / none | direct / direct | direct / direct | direct / direct | direct / direct | direct / direct |

Every cell agrees. C-9's corrected degraded-state expectation is the `none` block: the three rule-set
names reach the **proxied** stub in `rule` and `global` and the **non-proxied** stub in `direct`,
identically in both runs. Type A throughout, deliberately — the suppressed types are the one class whose
answering resolver FR-2/Q-4 changes on purpose.

## AC-B8 — the unmatched class, both sides

```
{"ac":"AC-B8/V-33","run":"cand","status":null,"ans":0,"ms":15030.3,"timeout":true,"remote_stub":[],"direct_stub":[]}
{"ac":"AC-B8/V-33","run":"head","status":null,"ans":0,"ms":15030.9,"timeout":true,"remote_stub":[],"direct_stub":[]}
```

Candidate 15030.3 ms, HEAD 15030.9 ms — the candidate's is no greater, neither stub was reached, and
sing-box answered nothing. This is FR-11/Q-17 as a *tested no-regression guarantee*, not a fix.

## The four adversarial tests of my own

**ADV-1 — candidate-side non-vacuity.** The one test that could have invalidated everything: if the rig
cannot observe a stall, "fast" proves nothing. Candidate build, `ipv6 on`, node accepts-never-answers:

```
{"ac":"ADV-1 candidate-side non-vacuity","run":"cand-ipv6-on","status":null,"ans":0,"ms":15030.8,"timeout":true,
 "rule0":{"action":"predefined","rcode":"NOERROR","query_type":[64,65]},
 "sblog":["+0800 2026-08-14 10:02:12 ERROR [608654223 10.0s] dns: exchange failed for t16-nomatch.org. IN AAAA: context deadline exceeded"]}
```

The *same build*, the *same fixture*, one setting apart, stalls. So the candidate's 19 ms is produced by
`dns.rules[0]`, not by the harness. This also re-derives Q-2's 10.0 s constant independently of M-2.

**ADV-2 — types 64/65 in `direct` mode.** Candidate `NOERROR ans=0`, no stub touched; HEAD
`direct_stub=[['t16-nomatch.org', 65]]`, `ans=1 20.0 ms`. The changelog's claim that the old rule's
position made 64/65 ineffective in `global`/`direct` is therefore earned, not asserted.

**ADV-3 — does index 0 really precede everything?** AAAA of a `hosts` name, a domestic-suffix name, a
`geosite-google` name and a `geosite-private` name, all under suppression: `NOERROR ans=0` at
18.5 / 18.0 / 18.2 / 8.7 ms, `remote_stub=[]`, `direct_stub=[]`. Nothing reached a resolver.

**ADV-4 — boundaries and concurrency.**

```
"probes":[{"q":"a*63.org/AAAA","status":"NOERROR","ans":0,"ms":18.2},
          {"q":"<253-byte name>/AAAA","status":"NOERROR","ans":0,"ms":18.7},
          {"q":"xn--fsq.xn--0zwm56d/AAAA","status":"NOERROR","ans":0,"ms":17.6}],
"conc_n":40,"conc_noerror":40,"conc_ans":[0],"conc_max_ms":51.2,"conc_wall_ms":75.0,
"remote_stub_n":0,"direct_stub_n":0
```

**The `ANY` probe is a harness artifact, not a result.** In the same run `t16-nomatch.org/ANY` came back
in 15.6 ms with no status. Investigated:

```
== ANY == ms=15.9 status=None ans=0
;; Connection to 127.0.0.1#48449(127.0.0.1) for t16-nomatch.org failed: connection refused.
== MX == ms=12017.2 status=None ans=0
;; communications error to 127.0.0.1#48449: timed out
```

`dig` sends `ANY` over TCP; the fixture inbound is `"network": "udp"`, so the connection is refused by
the kernel. `MX`/`TXT` of the same name behave as the no-rule class should (node-dependent, dropped at
sing-box's deadline). Recorded so no future round reads an `ANY` row as evidence of anything.

## C-3 — the class text, measured before it was believed

`python3 classtext.py`, node accepts-never-answers, eight probe classes × 3 modes × 2 rule-set states ×
2 revisions. Answered / unanswered:

| run | rule-sets | mode | answered without a node | unanswered |
|---|---|---|---|---|
| cand | usable | rule | hosts, domestic suffix, geosite-cn, geosite-private, 64, 28 | geosite-google, no-rule |
| cand | usable | global | hosts, 64, 28 | domestic suffix, geosite-cn, geosite-private, geosite-google, no-rule |
| cand | usable | direct | everything | — |
| cand | none | rule | hosts, domestic suffix, 64, 28 | geosite-cn, geosite-private, geosite-google, no-rule |
| cand | none | global | hosts, 64, 28 | everything else |
| cand | none | direct | everything | — |
| head | usable | rule | hosts, domestic suffix, geosite-cn, geosite-private, 64 | geosite-google, no-rule, **28** |
| head | usable | global | hosts | everything else, **64 and 28 included** |
| head | usable | direct | everything (64 and 28 answered by the **non-proxied** resolver) | — |
| head | none | rule | hosts, domestic suffix, 64 | geosite-cn, geosite-private, geosite-google, no-rule, **28** |
| head | none | global | hosts | everything else |
| head | none | direct | everything | — |

Each clause of the shipped README table maps onto a candidate row above: the `rule` row including its
"while the rulesets are usable, `geosite-cn` and `geosite-private` also match" conditional; the `global`
row ("the `hosts` table and the suppressed query types only"); the `direct` row ("everything"); and the
degraded paragraph ("the `rule` row shrinks to the `hosts` table, the five domestic suffixes and the
suppressed query types", "`global`'s row is already shorter", "`direct`'s does not depend on the
rulesets at all"). No shipped sentence exceeds a measured row, which is what C-3 asks stage 6 to confirm.

The HEAD block is also the evidence for the `04:274` insight row (moving the rule changed real behaviour
for 64/65, not only for 28) and for QA's ADV-2.

## Structural suites — full output of one round each

`struct1.py` (15 checks, all PASS): reproduced in the contract's Adversarial table; the notable lines are

```
V-3        PASS  query_type moved index 3->0, list [64, 65]; ... dns.final='remote_dns'
V-7/AC-5   PASS  real /usr/local/bin/sing-box check exit 0 in all six: [('0 nodes',0),('1 node',0),('3 nodes',0),
                 ('suppression on',0),('suppression off',0),('rulesets unusable',0)]
V-11a/AC-7 PASS  no timeout/wait/delay key under dns in any state; whole-doc set == HEAD's ['.outbounds[1].idle_timeout']
V-24/AC-23 PASS  py_compile exit 0; --numstat = 272 added / 12 deleted (RES-3); 272 added + 12 deleted lines
                 scanned for 20 post-3.6 patterns -> 0 hits; ast: no NamedExpr/Match/pos-only
```

**RES-1 discharged with a shell.** AC-8's byte-identity was extracted with `ast.get_source_segment` on
both revisions and compared as bytes for `_merge`, `_directive_of`, `_apply_directive`, `DIRECTIVES`,
`_load_override` and `_anchor_index`. AC-9's values were read as `ast` keyword nodes —
`{'clash_api': (3, 3), '_egress_ip': (8, 8), '_fetch_to_temp': (30, 30)}` — never by `grep`, because
`timeout=3` is a textual prefix of `timeout=30`. **RES-3 honoured**: the added-line scope came from
`git diff --numstat`'s first field (272), never from `--stat`'s bar column.

`struct2.py` (11 checks, all PASS). The `main()`-driven runs seed `lang` into the **fixture
settings.json** rather than assigning `sc.LANG`, because `main()` reassigns `LANG = _load_lang()` after
import — a harness that sets only `sc.LANG` renders English on every `main()` path and Chinese assertions
pass vacuously:

```
en/show -> exit 0, 2 stdout lines, first='IPv6 name resolution → auto'
zh/show -> exit 0, 2 stdout lines, first='IPv6 域名解析 → auto'
```

`_init_files()` was replaced by a no-op for those eight runs (it hard-codes `/var/lib/sing-box`), and
`_resolve_clash_port()` was stubbed; C-4's start-up-path half was therefore observed **statically**, by
`ast` over `main()` — read-only gate constant set exactly `['doctor']`, `else` arm calling
`_init_files → _load_lang → _resolve_clash_port`, `handlers` with 21 members including `ipv6`.

C-6's witness is a counter on `sc.restart_service` / `sc.generate_config` (which do fire under
`SYSTEMD = OPENRC = False`, where a `PATH` shim never can), plus `PATH` shims for
`systemctl`/`rc-service`/`rc-update` and a counting `socket.socket`. Its non-vacuity control is V-15:
the same witness that read `{'restart': 0, 'generate': 0}` for `show` and for both no-op sets read
`{'restart': 1, 'generate': 1}` for `sc ipv6 off`.

CR-5's non-vacuity control is not HEAD (HEAD has no IPv6 code): it is the candidate file with **only**
the new `except UnicodeDecodeError` clause deleted. That shape raises `UnicodeDecodeError` on 3 of the
5 address sources and passes the other 2 — which is exactly why the round-1 fixture could not have
caught it. (First attempt at this cut matched the *other* `except UnicodeDecodeError:` in `bin/sc`, at
`:1369` inside `_load_override`, and produced a `SyntaxError`; anchoring the search at
`text = IF_INET6_PATH.read_text()` fixed it. Harness bug, not a product finding.)

`struct3.py` (10 checks, all PASS). Two harness bugs were found here and are recorded so nobody mistakes
their fix for a product change:

1. `cmd_status` calls `_egress_ip()`, a live network request, so the candidate and HEAD runs saw
   different egress results and the regression comparison failed spuriously. Stubbed to a fixed value;
   with that, `ls`, `mode show`, `status` and `update-interval show` are byte-identical between the two
   revisions and `help` differs in exactly the 4 new `ipv6` lines.
2. The help-diff assertion tested `"ipv6" in line` case-sensitively, and two of the four new lines carry
   only `IPv6` or no occurrence at all. Replaced by a count-plus-first-line assertion.

The README mirror check compares `(line number, kind)` skeletons — heading level, fence, table-row cell
count — not line prefixes, since a translated table row legitimately differs in its first bytes. Both
files: 332 lines, 102 skeleton elements, identical positions.

## QA-1 — CR-10's residue, observed

```
ADV CR-10  PASS  REPRODUCED: on an ESTABLISHED host (settings.json with lang/mode/update_interval but no
clash_api_port) the start-up path `sc ipv6 show` runs WRITES settings.json (gained key
clash_api_port=29091); and on a host whose settings.json is malformed it is rewritten to a single key,
dropping lang/mode.
```

`_resolve_clash_port()` (`bin/sc:345-369`) returns early only when `_saved_clash_port()` yields a valid
`int`; otherwise it probes and persists. Its own comment names "every install that predates the port
auto-probe" as the hosts the branch exists for — i.e. established hosts, not fresh ones. The shipped
sentence scopes the write to "on a fresh host" / "全新机器上". Judgment: **correct it, but do not block
delivery.** C-4's prohibition ("no text may claim `sc ipv6 show` is write-free as a command") is
satisfied; the behaviour is unchanged from HEAD; the gap is one adjective in three files and the exact
replacement clause is already written in CR-10.

## QA-2 — CR-6 / RES-2, reproduced rather than argued

```
cmd_ipv6('auto') stdout: 'IPv6 name resolution → auto
AAAA queries are resolved normally (setting: auto — this host has a global IPv6 address on enp3s0)
Nothing changed — the sing-box service was not touched'
config.json on disk: dns.rules[0].query_type == [28, 64, 65]
```

Both sides of `cmd_ipv6`'s comparison are computed from the current host, which is what FR-5/Q-9/I-10
require and what AC-6 makes mandatory — reading the document back would be the second opinion AC-6
forbids. So this is a requirement gap (BC-13 did not anticipate the repair path), not a code defect, and
it is routed to the requirement-analyst. `sc ipv6 off` and `sc reload` both repair the document.

## QA-3 / QA-4 — the two design-sanctioned notes, now observed

```
CR-4 auto: exit=0 stdout_lines=2 stderr_lines=2
  stderr: "⚠️  Could not read this host's IPv6 addresses (No such file or directory) — assuming it has one, …"
          (the same line, twice)
CR-9 show(FR-7): exit=0 stdout='IPv6 name resolution → auto' stderr_lines=1
BC-11: exit=0 no-config-json=True files_unchanged=True
```

Neither was observed by any numbered step before this stage; both are as `05_CODE_REVIEW.md` describes
and as `02_RATIONALE.md` R-8 / I-5 price them. No change is asked for.

## Stability, verbatim

```
round 1 struct1: SUMMARY struct1: 15 pass / 0 fail
round 1 struct2: SUMMARY struct2: 11 pass / 0 fail
round 1 struct3: SUMMARY struct3: 10 pass / 0 fail
round 2 struct1: 15/0    round 2 struct2: 11/0    round 2 struct3: 10/0
round 3 struct1: 15/0    round 3 struct2: 11/0    round 3 struct3: 10/0

### STABILITY: 10 independent rebuilds of the AC-B1 fixture (candidate)
round  1: doh.pub 20.4ms | 360.cn 19.2ms | TYPE64 19.1ms | AAAA NOERROR/0 20.6ms
round  2: 18.3 | 8.2  | 17.9 | AAAA 19.9ms          round  3: 10.2 | 19.0 | 19.0 | AAAA 18.9ms
round  4: 18.1 | 17.9 | 17.8 | AAAA 17.8ms          round  5: 19.4 | 19.3 | 8.8  | AAAA 17.8ms
round  6: 18.3 | 18.3 | 7.8  | AAAA 8.8ms           round  7: 18.3 | 8.2  | 7.6  | AAAA 18.2ms
round  8: 18.2 | 19.3 | 7.7  | AAAA 17.8ms          round  9: 10.8 | 23.9 | 13.3 | AAAA 22.3ms
round 10: 18.8 | 18.8 | 18.6 | AAAA 9.2ms
STABILITY: 10/10 rounds identical outcome=True, worst wall clock 23.9 ms
```

Each round is a new `mkdtemp` root, new ports, a new sing-box process, and a **distinct query name**, so
what is repeated is the document's behaviour and not a cache (`dns.disable_cache = True` as well).

## verify_all, full output with this report in place

```
=== verify_all (generic) ===
[A.1] No hardcoded secrets ... PASS          [A.2] No .env files committed ... PASS
[B.1] Syntax (bin/sc, install.sh, uninstall.sh) ... PASS
[B.2] install.sh bilingual key parity ... PASS
[B.3] Lint ... SKIP
[E.1] Bootstrap files present ... PASS       [E.2] workflow.md present ... PASS
[E.3] Agents layout v0.30+ ... PASS          [E.4] Binding in sync ... PASS
[E.4b] Hook commands resolve to existing scripts ... PASS
[E.5] AI-GUIDE.md indexes every .harness/rules/*.md ... PASS
[E.6] Adversarial tests section in completed task reports ... PASS
[F.1] ... PASS  [F.2] ... PASS  [F.3] ... PASS  [F.4] ... PASS  [F.5] ... PASS
[F.6] Active task docs <=500 lines each ... PASS

=== Summary ===
  PASS: 17
  WARN: 0
  FAIL: 0
  SKIP: 1
exit code: 0
```

The V-25-predicted F.6 WARN did not fire: `06_TEST_REPORT.md` is 165 lines and this rationale is under
the cap too, so no active task document crosses 500. E.6 was verified to be matching *this* file's
heading — it read PASS before the report existed only because the `find` loop had no `06_TEST_REPORT.md`
to check.

## What the PM must carry to delivery

Beyond the report's own defect rows: RS-1, RS-6, RS-7, RS-9 and RES-5…RES-9 travel unchanged; RES-2
(QA-2) and RES-4 (BC-14 unobserved) are now evidenced rather than asserted; RES-1 and RES-3 are
discharged here and need not travel further; C-2's amendment to AC-B10's `direct` clause still has to be
filed into `01_REQUIREMENT_ANALYSIS.md`, and C-4's scoping alongside it.
