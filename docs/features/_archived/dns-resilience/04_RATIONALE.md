# 04 — Development rationale · T-16 `dns-resilience`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

This file carries the verbatim tool transcripts behind `04_DEVELOPMENT.md`'s
`## Verification plan results`, plus the two measurement narratives that changed how a step
was written. Nothing here is a contract; where it disagrees with `04`, `04` wins.

## How the fixtures were driven

Throwaway scripts in a scratchpad, none committed (out-of-scope item: "a committed test
harness or a new `verify_all` step — R-9 owns it"):

- `schar.py` — the `docs/dev-map.md` import recipe verbatim, the eight-constant repoint with
  its containment assertion, and the fixture seeders. Every fixture root is one `mkdtemp()`.
- `v_struct.py`, `v_ac10.py`, `v_docs.py` — V-3 … V-25.
- `behav.py`, `stub_dns.py`, `hang_tcp.py`, `v_behav.py`, `v_26b.py` — V-26 … V-36.

`main()`-driven runs (V-12, V-14, V-15, V-23) replace `_init_files` with a no-op **before**
calling `main()`, so it is never driven (K-10 / NFR-6) while `LANG = _load_lang()` and the
`OverrideError` handler still run exactly as they do in production. `clash_api_port` is
pre-seeded, so `_resolve_clash_port()` only reads and binds no probe socket.

The pristine baseline is `git show HEAD:bin/sc` written into a separate tree — a file copy,
not a `git worktree` (a worktree's `.git` is a *file*, which turns `verify_all` A.1/A.2 into
SKIP and makes the summary lie).

## Two measurements that changed a step

**1. `.test` is not an unmatched name.** The first no-rule probe was `probe-nomatch-1.test`.
It reached the **non-proxied** stub, not the proxied one — `geosite-private` matches the
reserved TLD `test`. Every probe name was therefore re-classified by measurement against
HEAD before any behavioural step was trusted; the classification is in `04`'s recipe block.
Had this gone unnoticed, V-29/V-31/V-33's "a name HEAD routes to `remote_dns`" would have
been false and the defect-reproducing controls would have quietly stopped reproducing.

Discovery run (HEAD, node usable, `rule` mode, all rulesets usable):

```
www.google.com             NOERROR  ans=1  19.3ms remote='www.google.com 1' direct=''
baidu.com                  NOERROR  ans=1   8.4ms remote='' direct='baidu.com 1'
probe-x.test               NOERROR  ans=1  18.1ms remote='' direct='probe-x.test 1'
t16-nomatch.org            NOERROR  ans=1   9.0ms remote='t16-nomatch.org 1' direct=''
t16-nomatch.example.org    NOERROR  ans=1   8.9ms remote='t16-nomatch.example.org 1' direct=''
t16-nomatch.net            NOERROR  ans=1  18.2ms remote='t16-nomatch.net 1' direct=''
doh.pub                    NOERROR  ans=2  18.0ms remote='' direct=''
360.cn                     NOERROR  ans=1   7.8ms remote='' direct='360.cn 1'
home.arpa                  NOERROR  ans=1   8.0ms remote='' direct='home.arpa 1'
```

**2. A bare `direct` outbound cannot carry a DNS `detour`.** Staging *usable* as
`{"type":"direct","tag":"proxy"}` made every fixture die at startup with
`FATAL start dns/udp[remote_dns]: detour to an empty direct outbound makes no sense` —
`sing-box check` passes, so this is a *run*-time refusal a config check cannot catch. A
`selector` whose only member is `direct` is accepted, and that is the shape the shipped
document already collapses to at zero nodes, so the staging ended up closer to production
than the design's wording was.

## Transcript — structural steps (V-3 … V-24)

```
[V-3] PASS query_type moved 3 -> 0, list [64, 65]; everything else identical (key order included)
[V-4] PASS {"action": "predefined", "rcode": "NOERROR", "query_type": [28, 64, 65]}
[V-5] PASS supp=True rulesets=True order=[None, 'hosts_dns', 'remote_dns', 'direct_dns', 'remote_dns', 'direct_dns', 'direct_dns', 'direct_dns'] | supp=True rulesets=False order=[None, 'hosts_dns', 'remote_dns', 'direct_dns', 'direct_dns'] | supp=False rulesets=True order=[None, 'hosts_dns', 'remote_dns', 'direct_dns', 'remote_dns', 'direct_dns', 'direct_dns', 'direct_dns'] | supp=False rulesets=False order=[None, 'hosts_dns', 'remote_dns', 'direct_dns', 'direct_dns']
[V-6] PASS the added rule is present in both rule-set states, with no rule_set key
[V-7] PASS 0 nodes: exit 0; 1 node: exit 0; 3 nodes: exit 0; suppression on: exit 0; suppression off: exit 0; all rule-sets unusable: exit 0
[V-8] PASS byte-identical: _merge, _directive_of, _apply_directive, DIRECTIVES, _load_override
[V-9] PASS clash_api: ['3']; _egress_ip: ['8']; _fetch_to_temp: ['30'] (ast, no grep)
[V-11] PASS (a) in all 6 states: no key containing 'timeout' anywhere under dns; the whole document's timeout-ish keys are exactly HEAD's (['.outbounds[].idle_timeout'] — the urltest group's, frozen since T-15); dns.final == remote_dns in all 6. (b) timeout= arguments unchanged ['3', '30', '8'], new module constants ['IF_INET6_PATH'], none a wait
[V-10] PASS one definition; callers ['_dns_overlay', 'cmd_ipv6']; with cmd_ipv6 deleted _dns_overlay() is unchanged: {"dns": {"rules": {"$prepend": [{"action": "predefined", "rcode": "NOERROR", "query_type": [28, 64, 65]}]}}}
[V-12] PASS 8 runs, all exit 0; en on: IPv6 name resolution → on / AAAA queries are resolved normally (setting: on) / Configuration regenerated; sing-box restarted / || en off: IPv6 name resolution → off / AAAA queries are answered empty (setting: off) / Nothing changed — the sing-box service was not touched / || en auto: IPv6 name resolution → auto / AAAA queries are answered empty (setting: auto — this host has no global IPv6 address) / Nothing changed — the sing-box service was not touched / || en show: IPv6 name resolution → auto / AAAA queries are answered empty (setting: auto — this host has no global IPv6 address) / || zh on: IPv6 域名解析 → on / AAAA 查询正常解析（设置：on） / 配置已重新生成，sing-box 已重启 / || zh off: IPv6 域名解析 → off / AAAA 查询直接返回空结果（设置：off） / 设置无变化 —— 未改动 sing-box 服务 / || zh auto: IPv6 域名解析 → auto / AAAA 查询直接返回空结果（设置：auto —— 本机没有全局 IPv6 地址） / 设置无变化 —— 未改动 sing-box 服务 / || zh show: IPv6 域名解析 → auto / AAAA 查询直接返回空结果（设置：auto —— 本机没有全局 IPv6 地址） /
[V-13] PASS cmd_ipv6('show'): no mtime change over 9 files, restart/generate witness silent, no socket, init shims never invoked. SCOPE: main()'s startup path is not part of this observation (C-4).
[V-14] PASS auto-on-auto: IPv6 name resolution → auto / AAAA queries are answered empty (setting: auto — this host has no global IPv6 address) / Nothing changed — the sing-box service was not touched / || on-with-global: IPv6 name resolution → on / AAAA queries are resolved normally (setting: on) / Nothing changed — the sing-box service was not touched /
[V-15] PASS dns.rules[0].query_type -> [28, 64, 65]; restart witness fired exactly 1 time; output: IPv6 name resolution → off / AAAA queries are answered empty (setting: off) / Configuration regenerated; sing-box restarted /
[V-16] PASS en/absent -> auto  || en/no ipv6 key -> auto  || en/ipv6=yes -> auto ⚠️  /tmp/t16-v16-27i6l7b_/etc/sing-box/settings.json: ipv6 must be one of on / off / auto — using auto || zh/absent -> auto  || zh/no ipv6 key -> auto  || zh/ipv6=yes -> auto ⚠️  /tmp/t16-v16-yd2udjob/etc/sing-box/settings.json：ipv6 必须是 on / off / auto 之一 —— 已按 auto 处理
[V-17] PASS this host (7 entries, all fe80/::1) -> (None, None) suppress=True || + 2000::/3 on enp3s0 -> ('enp3s0', None) suppress=False || + 2000::/3 on sb-tun only -> (None, None) suppress=True || empty file -> (None, None) suppress=True
[V-18] PASS removed: suppress=False | ⚠️  Could not read this host's IPv6 addresses (No such file or directory) — assuming it has one, so AAAA queries are resolved normally; set it explicitly with `sc ipv6 on|off` || malformed (one line of prose): suppress=False | ⚠️  Could not read this host's IPv6 addresses (unreadable) — assuming it has one, so AAAA queries are resolved normally; set it explicitly with `sc ipv6 on|off`
[V-19] PASS pre-T-16 doc had query_type at index 3; first reload: no drift warning (stderr ''); record matches the new file; second reload silent too
[V-20] PASS 10 new keys, every one with a zh entry, identical placeholder sets, no 失败：, no namespaced key
[V-23] PASS no override.json -> Cannot use /tmp/t16-irq3q84x/etc/sing-box/config.json: at dns.no_such_key: $prepend can only be applied to an array that already exists || override.json present -> Cannot use /tmp/t16-r6cqn33x/etc/sing-box/config.json: at dns.no_such_key: $prepend can only be applied to an array that already exists || override turns dns.rules into a scalar (C-5) -> Cannot use /tmp/t16-_bqaz8p9/etc/sing-box/override.json: at dns.rules: this must stay an array || override.json is not JSON -> Cannot use /tmp/t16-uh8c7v6x/etc/sing-box/override.json: not valid JSON (Expecting property name enclosed in double quotes: line 1 column 3 (char 2))
[V-24] PASS py_compile exit 0; 263 added lines scanned: no walrus, no dataclasses, no capture_output=, no new import, no 3.7+ syntax

=== summary ===
FAILED: none
```

## Transcript — AC-10's source-level half (V-3(b), added under C-8)

```
[V-3b] PASS guard=("dns.rules", "route.rules", "route.rule_set") (3 keys, byte-identical to
HEAD); dict literals in generate_config: HEAD 0 / candidate 0; new constants: none
```

## Transcript — documents (V-21, V-22)

```
[V-21] PASS line-for-line mirror: True (332 lines each, headings at identical line numbers);
coverage [('sc ipv6 surface', True, True), ('show form', True, True),
('effective-decision rule', True, True), ('absent key means auto', True, True),
('per-mode class table', True, True), ('BC-22 limit', True, True),
('BC-4 degraded', True, True), ('BC-14, no more than the escape', True, True)];
forbidden claims none; CHANGELOG Chinese entry under 新增: True
[V-22] PASS ipv6 row present in both blocks, description at display column (30, 30)
(every other row: 30), sub-options at 32/39 like the `use` block
```

The K-16 grep list, for the reviewer: `fall back to (another|a second) resolver`,
`second resolver (is|will)`, `retries the (query|resolver)`, `configurable (DNS) timeout`,
`set the DNS timeout`, `tries the (direct|domestic) resolver instead`, `回退到…解析器`,
`备用解析器`, `可配置的超时时间`, `改用国内解析器重试`, plus a BC-14 over-claim guard
(`unreachable because`, `因为…抑制…连不上`). All zero hits in both READMEs.

## The three corrected sentences, verbatim, with the observation each rests on

Quoted in full so the correction can be checked without opening the files. The superseded text is
shown only to make the delta visible; `04_DEVELOPMENT.md` carries no round history.

**CR-2 · `README.md:122` / `README.zh-CN.md:122`.** Was: "On a host that cannot use IPv6, **every**
AAAA lookup still travels to the proxied resolver". Now:

> On a host that cannot use IPv6, an AAAA lookup for a name this config sends to the proxied resolver
> — in `rule` mode every name outside the table below, in `global` everything but the `hosts` table,
> in `direct` none at all — still travels there, and while a node accepts the connection but never
> answers, that lookup produces nothing at all, measured at sing-box's own 10.0 s per-query deadline.

> 在用不了 IPv6 的机器上，凡是被这份配置送往代理侧解析器的域名 —— `rule` 模式下是下表之外的全部域名，
> `global` 模式下是 `hosts` 表以外的全部，`direct` 模式下一个都没有 —— 它的 AAAA 查询仍然会走到那里；
> 而当节点「TCP 能连上、之后一直不回应」时，这次查询什么都拿不回来，实测正好卡在 sing-box 自己的每次
> 查询 10.0 秒上限。

The three per-mode clauses are not new claims: they are the section's own table (`:130-134`), which
V-26(b) measured per mode and V-32 confirmed per name across 36 combinations. The stall half is now
scoped to exactly what V-29 observed — an AAAA lookup for a name the document routes to `remote_dns`
(`t16-nomatch.org`), which is precisely the class the corrected clause names. Nothing in the sentence
is wider than a numbered step.

**CR-1 · `README.md:124` / `README.zh-CN.md:124`.** Was: "`sc ipv6 show` decides nothing, writes
nothing and restarts nothing." Now:

> `sc ipv6 show` only reports what the setting is and what it decides: it never changes the `ipv6`
> setting, regenerates no config and touches the service in no way — but, like every command except
> `sc doctor`, it still runs the ordinary start-up path first, which on a fresh host creates
> `/etc/sing-box` and `/var/lib/sing-box`, seeds `nodes.json` / `settings.json`, and probes and
> records the Clash API port.

> `sc ipv6 show` 只是报告当前设置以及它得出的结论：它不会改动 `ipv6` 这个设置、不重新生成配置、也完全
> 不碰服务 —— 但和除 `sc doctor` 以外的所有子命令一样，它仍然会先走一遍常规启动流程，全新机器上这一步
> 会创建 `/etc/sing-box` 与 `/var/lib/sing-box`、写入初始的 `nodes.json` / `settings.json`，并探测、
> 记下 Clash API 端口。

Deliberately "never changes the `ipv6` setting" and not "writes nothing": the start-up path *does*
write a setting — `_resolve_clash_port()` persists `clash_api_port` — so the general form would have
been the same over-claim in a smaller font. The first half is V-13's scope; the second is V-13(b)'s.

**CR-3 · `README.md:136` / `README.zh-CN.md:136`.** Was: "that list shrinks to …", no mode named. Now:

> **With all four rulesets unusable** (the degraded config `sc` already warns about), the `rule` row
> above shrinks to the `hosts` table, the five domestic suffixes and the suppressed query types; every
> other name waits for a usable node or for the rulesets to come back. `global`'s row is already
> shorter than that, and `direct`'s does not depend on the rulesets at all.

> **四个规则集全部不可用时**（也就是 `sc` 已经会告警的降级配置），上表中 `rule` 这一行会缩小到 `hosts`
> 表、五个国内域名后缀和被抑制的查询类型；其余域名要等到某个节点恢复可用、或者规则集补齐之后才能解析。
> `global` 那一行本来就比这更短，`direct` 那一行则根本不依赖规则集。

`rule` shrinking is V-27 (V-26 with the rules directory emptied). `global` already being shorter is
V-26(b). `direct` not depending on the rulesets is V-26(b) plus V-32's degraded-state row, where in
`direct` the three ruleset names reach the non-proxied stub in both the candidate and HEAD runs.

**`CHANGELOG.md:7`** carries the same two corrections in Chinese: "每一次 AAAA 查询也要走到代理侧的解析
器" became "凡是被这份配置送往代理侧解析器的域名（`rule` 模式下就是 `hosts` 表、五个国内域名后缀和
`geosite-cn` / `geosite-private` 之外的全部域名），它的 AAAA 查询也要走到那里", and "`sc ipv6 show`
不写文件、不重启、不发网络请求" became "`sc ipv6 show` 只是报告：它不会改动 `ipv6` 这个设置、不重新生成
配置、也不碰服务 —— 但它和除 `sc doctor` 以外的所有子命令一样，仍然会先走一遍常规启动流程（全新机器上
这一步会创建 `/etc/sing-box` 与 `/var/lib/sing-box`、写入初始的 `nodes.json` / `settings.json`，并
探测、记下 Clash API 端口）。" The "不发网络请求" clause is gone outright: `_free_port()` binds loopback
sockets, so it was false as a claim about the command even before the file-writing half.

## Transcript — V-13(b), the extended V-18, V-20, V-21 and the V-24 reconciliation

```
[V-13(b)]  ast over main(), no execution (driving _init_files() is forbidden: it hard-codes
           /var/lib/sing-box as a Path literal, so even a fully repointed fixture writes there)
gate condition rendered: args.cmd == 'doctor'
commands taking the read-only arm : ['doctor']
read-only (if) arm calls          : ['_load_lang']
every-other-command (else) arm    : ['_init_files', '_load_lang', '_resolve_clash_port']
subcommands dispatched            : 21, includes 'ipv6': True
PASS -- `sc ipv6` (every form, `show` included) takes the else arm

[V-18 extended, candidate]  5 sources x {predicate, ipv6_decision()} x {en, zh} = 20 checks
  source removed                   -> (None, 'No such file or directory')
  one line of prose (UTF-8)        -> (None, 'unreadable')
  non-UTF-8 bytes (0xff 0xfe ...)  -> (None, 'unreadable')
  non-UTF-8 in kernel SHAPE        -> (None, 'unreadable')
  UTF-16 encoded kernel line       -> (None, 'unreadable')
  every case: nothing raised, suppress=False, sentence=None, exactly one stderr line, no \r
  en: "⚠️  Could not read this host's IPv6 addresses (unreadable) — assuming it has one, so AAAA
       queries are resolved normally; set it explicitly with `sc ipv6 on|off`"
  zh: "⚠️  无法读取本机的 IPv6 地址（无法读取）—— 已按存在处理，AAAA 查询将正常解析；可用
       `sc ipv6 on|off` 明确指定"
  FAILS: 0

[V-18 extended, round-1 control]  the same fixture against _global_ipv6_iface() with ONLY the new
except clause deleted (git diff --no-index HEAD:bin/sc -> that file = 263  12, i.e. it reproduces
the round-1 tree's count exactly):
  FAIL non-UTF-8 bytes (0xff 0xfe ...)  UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff
       in position 0: invalid start byte          <- escapes to the caller, in en and zh alike
  FAIL non-UTF-8 in kernel SHAPE        UnicodeDecodeError: ... byte 0xff in position 46
  FAIL UTF-16 encoded kernel line       UnicodeDecodeError: ... byte 0xff in position 0
  PASS source removed / one line of prose (UTF-8)   <- the two round-1 sources, both still green
  FAILS: 12 of 20
HEAD is not a control for this step: HEAD has no _global_ipv6_iface at all (AttributeError on
import), which is why the defect class is "new code, this task's own", not a regression.

[V-20]  new keys: 10; removed keys: none; changed values on pre-existing keys: none;
placeholder sets identical for all ten; no `失败：`; none ls.*-shaped   PASS

[V-21]  332 / 332 lines; diff of the two files' heading+fence+table-row line-number lists: empty;
four forms present in both; K-16 greps -> the only hits are the denials at :138 in both languages
and their changelog mirror; C-10's ceiling sentence unchanged                              PASS

[V-24 / CR-7]  git diff --numstat -- bin/sc      -> 272   12
               git diff --stat   -- bin/sc       -> bar column 284, trailer "272 insertions(+),
                                                    12 deletions(-)"
               round-1 tree, reconstructed       -> 263   12   (bar column would be 275)
               => the PM's +275 is 263 + 12: the bar column counts CHANGED lines. No added line
                  was ever outside V-24's scope; the record and the measurement disagreed only
                  about which quantity they named.
               py_compile bin/sc: OK
               18 post-3.6 patterns x 272 added lines            -> 0 hits
               18 post-3.6 patterns x 284 added-and-deleted      -> 0 hits
               ast over the whole file: NamedExpr/Match/posonly  -> none
               imports added vs HEAD                             -> none
               module constants added vs HEAD                    -> ['IF_INET6_PATH']
```

## Transcript — behavioural steps and their HEAD controls (V-26 … V-36, V-35)

```
live-service witness BEFORE: MainPID=2566751 | ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
[V-26] PASS [AC-B1, agreement control] candidate: doh.pub/A NOERROR ans=2 18.3ms; 360.cn/A NOERROR ans=1 17.7ms; v26c-t64.org/TYPE64 NOERROR ans=0 17.4ms | proxied stub recorded '' | HEAD control: doh.pub/A NOERROR ans=2 19.2ms; 360.cn/A NOERROR ans=1 18.9ms; v26h-t64.org/TYPE64 NOERROR ans=0 18.6ms | HEAD proxied stub ''
[V-27] PASS [AC-B2, agreement control] candidate: doh.pub/A NOERROR ans=2 18.2ms; 360.cn/A NOERROR ans=1 7.9ms; v27c-t64.org/TYPE64 NOERROR ans=0 17.4ms | proxied stub recorded '' | HEAD control: doh.pub/A NOERROR ans=2 18.2ms; 360.cn/A NOERROR ans=1 8.6ms; v27h-t64.org/TYPE64 NOERROR ans=0 17.3ms | HEAD proxied stub ''
[V-28] PASS [AC-B3, agreement control] candidate: doh.pub/A NOERROR ans=2 18.2ms; 360.cn/A NOERROR ans=1 8.9ms; v28c-t64.org/TYPE64 NOERROR ans=0 17.8ms | proxied stub recorded '' | HEAD control: doh.pub/A NOERROR ans=2 8.2ms; 360.cn/A NOERROR ans=1 17.8ms; v28h-t64.org/TYPE64 NOERROR ans=0 8.8ms | HEAD proxied stub ''
[V-34] PASS [AC-B9/BC-1, agreement control] candidate: doh.pub/A NOERROR ans=2 18.4ms; 360.cn/A NOERROR ans=1 18.2ms; v34c-t64.org/TYPE64 NOERROR ans=0 7.7ms | proxied stub recorded '' | HEAD control: doh.pub/A NOERROR ans=2 18.4ms; 360.cn/A NOERROR ans=1 18.2ms; v34h-t64.org/TYPE64 NOERROR ans=0 17.9ms | HEAD proxied stub ''
[V-29] PASS [AC-B4, defect-reproducing control] candidate: NOERROR ans=0 18.7ms, proxied stub '' | HEAD control: None ans=0 15030.8ms (stalled: True), proxied stub ''
[V-30] PASS [AC-B5, agreement control] candidate: NOERROR ans=1, proxied stub recorded 'v30c.t16-nomatch.org 28' | HEAD: NOERROR ans=1, proxied stub 'v30h.t16-nomatch.org 28'
[V-31] PASS [AC-B6/BC-18, defect-reproducing control, C-2's corrected text] cand/global: NOERROR ans=0 18.3ms remote='' direct='' | cand/direct: NOERROR ans=0 18.7ms remote='' direct='' | head/global: None ans=0 15030.6ms remote='' direct='' | head/direct: NOERROR ans=1 19.9ms remote='' direct='v31hd.t16-nomatch.org 28'
[V-32] PASS [AC-B7, agreement control] 36 combinations, type A throughout: the same stub receives each probe name in both runs (0 mismatches). Degraded state (C-9): direct/geosite-cn -> non-proxied; direct/geosite-google -> non-proxied; direct/geosite-private -> non-proxied; global/geosite-cn -> proxied; global/geosite-google -> proxied; global/geosite-private -> proxied; rule/geosite-cn -> proxied; rule/geosite-google -> proxied; rule/geosite-private -> proxied
[V-33] PASS [AC-B8, agreement control] candidate: no answer, client outcome at its own 15 s limit (15031 ms), neither stub recorded the query (remote='' direct='') | HEAD control: 15029 ms, timed out=True (no smaller than the candidate's)
[V-36] PASS [AC-B4 non-vacuity, defect-reproducing control] candidate: proxied stub recorded query types ['1'] (A yes, AAAA no) and the AAAA answer was empty NOERROR | HEAD control: ['1', '28'] (both)
live-service witness AFTER: MainPID=2566751 | ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
elapsed 75 s
V-35: every step above carries its HEAD-clone control at the identical fixture and derivation;
the verdicts above already fold NFR-7 in.
NOT PASS: none
```

sing-box's own log line from V-29's HEAD control, verbatim (ESC sequences stripped):

```
2026-08-13 13:56:47 ERROR [3786597235 10.0s] dns: exchange failed for
v29h.t16-nomatch.org. IN AAAA: context deadline exceeded
```

That is M-3 reproduced independently, and it is why `04` says the 10.0 s is never what the
user sees: the client's own 15 s budget is what ends the wait.

## Transcript — V-26(b), I-17's per-mode class (added under C-3)

Node **unusable**, all rulesets usable, all three routing modes, candidate and HEAD.

```
cand  direct  domestic-suffix     -> NOERROR ans=1 18ms remote='' direct='360.cn 1'
cand  direct  geosite-cn          -> NOERROR ans=1 18ms remote='' direct='baidu.com 1'
cand  direct  hosts               -> NOERROR ans=2 19ms remote='' direct=''
cand  direct  no-rule             -> NOERROR ans=1 18ms remote='' direct='t16-nomatch.org 1'
cand  direct  suppressed type 28  -> NOERROR ans=0  7ms remote='' direct=''
cand  direct  suppressed type 64  -> NOERROR ans=0  8ms remote='' direct=''
cand  global  domestic-suffix     -> None    ans=0 2018ms remote='' direct=''
cand  global  geosite-cn          -> None    ans=0 2018ms remote='' direct=''
cand  global  hosts               -> NOERROR ans=2 19ms remote='' direct=''
cand  global  no-rule             -> None    ans=0 2017ms remote='' direct=''
cand  global  suppressed type 28  -> NOERROR ans=0  7ms remote='' direct=''
cand  global  suppressed type 64  -> NOERROR ans=0  8ms remote='' direct=''
cand  rule    domestic-suffix     -> NOERROR ans=1 18ms remote='' direct='360.cn 1'
cand  rule    geosite-cn          -> NOERROR ans=1  8ms remote='' direct='baidu.com 1'
cand  rule    hosts               -> NOERROR ans=2 18ms remote='' direct=''
cand  rule    no-rule             -> None    ans=0 2018ms remote='' direct=''
cand  rule    suppressed type 28  -> NOERROR ans=0 17ms remote='' direct=''
cand  rule    suppressed type 64  -> NOERROR ans=0 17ms remote='' direct=''
head  direct  domestic-suffix     -> NOERROR ans=1 18ms remote='' direct='360.cn 1'
head  direct  geosite-cn          -> NOERROR ans=1 18ms remote='' direct='baidu.com 1'
head  direct  hosts               -> NOERROR ans=2 18ms remote='' direct=''
head  direct  no-rule             -> NOERROR ans=1 18ms remote='' direct='t16-nomatch.org 1'
head  direct  suppressed type 28  -> NOERROR ans=1 18ms remote='' direct='v26b28hd.org 28'
head  direct  suppressed type 64  -> NOERROR ans=0 18ms remote='' direct='v26bhd.org 64'
head  global  domestic-suffix     -> None    ans=0 2017ms remote='' direct=''
head  global  geosite-cn          -> None    ans=0 2017ms remote='' direct=''
head  global  hosts               -> NOERROR ans=2 18ms remote='' direct=''
head  global  no-rule             -> None    ans=0 2018ms remote='' direct=''
head  global  suppressed type 28  -> None    ans=0 2018ms remote='' direct=''
head  global  suppressed type 64  -> None    ans=0 2017ms remote='' direct=''
head  rule    domestic-suffix     -> NOERROR ans=1 18ms remote='' direct='360.cn 1'
head  rule    geosite-cn          -> NOERROR ans=1 19ms remote='' direct='baidu.com 1'
head  rule    hosts               -> NOERROR ans=2  9ms remote='' direct=''
head  rule    no-rule             -> None    ans=0 2016ms remote='' direct=''
head  rule    suppressed type 28  -> None    ans=0 2017ms remote='' direct=''
head  rule    suppressed type 64  -> NOERROR ans=0 17ms remote='' direct=''
```

(`None` / ~2018 ms is `dig`'s own `+time=2` limit, i.e. sing-box answered nothing.)

Reading it: `rule` — hosts, the domestic suffix, `geosite-cn` and **both** suppressed types
are answered without a node; the no-rule class is not. `global` — only hosts and the
suppressed types survive, exactly as I-17 says, because the user's own `clash_mode: Global`
rule captures everything else. `direct` — everything reaches the non-proxied resolver.

The HEAD rows are the interesting half: at HEAD, type 64 is answered locally in `rule` mode
(its rule sits at index 3), but in `direct` mode it is **sent to the non-proxied resolver**
and in `global` mode it is left unanswered — because at HEAD that rule sits *after* both
`clash_mode` rules. D-2's argument, measured rather than reasoned, and evidence that this
task changes real behaviour for types 64/65 and not only for the newly added type 28.

## Live-service witness

```
before any fixture ran : MainPID=2566751 | ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
after every step       : MainPID=2566751 | ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
```

`systemctl show -p MainPID -p ActiveEnterTimestamp`, never `is-active` (which prints
`active` on both sides of a restart). `pgrep -af 'sing-box run'` after the run lists only
the live unit; every stub, hang-listener and fixture sing-box is dead. `/usr/local/bin/sc`
was never invoked, and `/usr/local/bin/sc.bak-2026-08-01-1006` was never read, restored or
deleted. No `PUT`/`PATCH`/`DELETE` reached `127.0.0.1:29090`; the only Clash API written to
was each fixture's own controller, for V-31/V-32's mode switches. Nothing was written under
`/etc` or `/var/lib`: `_init_files()` was never driven, and every one of the eight path
constants was asserted to resolve inside its `mkdtemp()` root before any fixture ran.
