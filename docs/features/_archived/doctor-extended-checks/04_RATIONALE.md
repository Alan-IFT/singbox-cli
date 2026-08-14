# 04 — Development rationale · T-20 `doctor-extended-checks`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

## 1. The 54-step fixture suite, step by step

Every step drives `sc.cmd_doctor(None)` directly on a neutralised module in a redirected
root; `main()` is never driven. `PASS` means every clause of the step's expected observable
held, not merely that the run terminated.

| step | result | observed |
|---|---|---|
| V-1 | PASS | `[PROBLEM] geosite-cn.srs: usable, 203 bytes, 90 days ago — run `sc update-rules` to refresh`; summary `[PROBLEM]`; the other three rows `[OK]` and carrying no next step |
| V-1 control | PASS | every row `[OK]`, summary `[OK]`, the literal `update-rules` absent from the whole capture |
| V-2 | PASS | `[PROBLEM] geosite-cn.srs: unreadable, size unavailable, last update unknown` (word form, no digit, never stale); skewed file `[OK] geoip-cn.srs: usable, 203 bytes, 0 seconds ago` |
| GC-9 | PASS | `[OK] geosite-google.srs: usable, 203 bytes, 0 seconds ago` — the age phrase on a usable, non-stale row |
| V-3 differ / match / absent / garbage | PASS ×4 | `[PROBLEM] … keep the change in …/override.json, then run `sc reload`` · `[OK] matches what sc last generated` (names no path) · `[UNKNOWN] no record of what sc last generated` · a present, non-empty, non-digest record reads **drifted** (Q-9). Position asserted per run: the row's predecessor is `configuration` and its successor is `sing-box check` |
| V-4 ×4 | PASS ×4 | host has a global v6 + document suppresses ⇒ `[PROBLEM]` naming `sc reload`; `ipv6: off` + document that does not suppress ⇒ `[PROBLEM]`; both agreeing directions ⇒ `[OK]` with no command |
| V-5 absent / truncated / non-object / v6-unreadable | PASS ×4 | `[UNKNOWN]` in all four, never `[PROBLEM]`; the drift row and the configuration row still print; the non-object document's cause slot reads `the top level must be a JSON object` |
| GC-2a | PASS | detection failure ⇒ the IPv6 stderr line appears **exactly once** (`== 1`, not `<= 1`) |
| GC-2b | PASS | `settings.json` carrying `"ipv6": "yes"` ⇒ BC-9's line **exactly once**, and the row renders the effective `auto` decision, never the rejected value |
| V-6 | PASS | `[PROBLEM] node delays: 0/2 nodes carry a stored delay — either no probe has completed yet or every node is failing; see `sc ls`` |
| GC-4a | PASS | stub request log `['/configs', '/proxies', '/dns/query?name=api.ipify.org&type=A']` — the `/proxies` request was **received**, with `SYSTEMD = True` and no `systemctl` exec'd |
| V-6 control | PASS | `[OK] node delays: 2/2 nodes carry a stored delay (history, not a fresh measurement); auto-select is on n1` |
| V-7 answer / no-records / hang | PASS ×3 | `[OK] … resolved in 0 ms, through the running sing-box` · `[PROBLEM] … returned no records after 0 ms — try another node with `sc use <n>`` · with the stub sleeping past the socket timeout, `[PROBLEM] no answer for api.ipify.org after **3002 ms**`. None of `3s`, `3 秒`, `timeout`, `gives up` appears anywhere in any capture |
| V-8 dead port / no port / silent | PASS ×3 | dead port ⇒ node-delay and DNS rows `[UNKNOWN]`, `Clash API responding` `[PROBLEM] no usable answer from 127.0.0.1:<port>`; no port ⇒ all four rows `[UNKNOWN]`; a stub that *would* answer sees an **empty request log** when no port is recorded |
| V-9.1…V-9.5 | PASS ×5 | the `.bak` at 0644 named with `644` and `chmod 600 <path>`, exactly one quoted line, `settings.json` in no quoted line · the directory at 0777 named with `777` and `chmod go-w` · a symlink to a 0777 file outside the root reported as a symlink with the string `777` **absent from stdout** and exit 2 · 12 offenders ⇒ 5 detail lines + `... 7 more line(s) not shown` · **V-9.5, the default install** (every credential file 0600, the directory 0755, `settings.json` at the 0644 `write_text()` leaves) ⇒ exactly `[OK] file permissions: no credential file grants access to group or other, and the directory is not group- or other-writable`, no quoted line, and the string `no file grants access` absent from the whole capture |
| V-10.1 / V-10.2 | PASS ×2 | no directory ⇒ `[UNKNOWN] no directory at <path>` and the directory **still does not exist** after the run; mode 0000 ⇒ `[UNKNOWN] cannot read <path>: [Errno 13] Permission denied` |
| V-14 | PASS | full snapshot (mode, size, mtime, sha256) of the fixture root identical before and after; **no** raiser over `_init_files` / `_resolve_clash_port` / `_write_private` / `save_settings` / `save_nodes` / `generate_config` / `restart_service` / `reload_or_restart` / `_record_generated` fired |
| V-14 positive control | PASS | the same raisers **do** fire when `_resolve_clash_port()` and `_init_files()` are called directly — so the negative above is a measurement, not an artefact of a raiser that never worked |
| V-13 ×5 | PASS ×5 | drift record removed · `nodes.json` malformed · absent · of the wrong shape (`{"nodes": ["n1"]}`) · `dns` not an object. In all five: **all 15 section labels printed**, exit ∈ {1,2}, no traceback |
| GC-7a | PASS | ghost entry injected into the listing ⇒ `[OK] file permissions: no credential file grants access to group or other…`, the vanished name absent, 15 labels printed |
| GC-7b | PASS | `{"dns": "hello"}` ⇒ `[PROBLEM] IPv6 (AAAA): … does not carry this decision — run `sc reload` to regenerate it` |
| V-17 | PASS | no `\r` and no ESC byte in any capture |
| V-17c | PASS | `/proxies` echoing the auto-select tag `n1\r\x1b[31mRED\x1b[0m` ⇒ stdout carries no CR and no ESC, and the row reads `auto-select is on n1RED`. Negative control on the un-plained form of the same line: the row printed `auto-select is on n1` while the raw CR **and** the live CSI sequence were in the stream |
| V-18 | PASS | planted literals in `config.json`, `nodes.json` and `override.json` absent from stdout in every run |
| V-16 | PASS | see §4 |
| GC-1a…d, AC-S3 | PASS ×5 | see §2 |
| V-15, V-15p | PASS ×2 | see §5 |
| V-11 | PASS | `config.json` byte-identical to HEAD under `ipv6: on`, `ipv6: off`, `auto` with a global address and `auto` without one |

## 2. GC-1 — the two captures, side by side

HEAD run, same fixture root, 16 rows, exit 0:

```
[OK] sing-box binary: …/sbstub.sh
[OK] sing-box version: sing-box version 1.13.15
[OK] rule-sets: 4/4 usable
[OK] geoip-cn.srs: usable, 203 bytes
[OK] geosite-cn.srs: usable, 203 bytes
[OK] geosite-google.srs: usable, 203 bytes
[OK] geosite-private.srs: usable, 203 bytes
[OK] configuration: /tmp/t20-y8bxy_o_/etc/sing-box/config.json
[OK] sing-box check: no error reported
[OK] service: running (via systemd)
[OK] boot autostart: enabled
[OK] TUN interface: sb-tun
[OK] TUN addresses: 172.19.0.1/30
[OK] Clash API: 127.0.0.1:34759
[OK] Clash API responding: yes
[OK] egress IP: 203.0.113.7
```

Candidate run, **the same fixture root**, 21 rows, exit 0:

```
[OK] sing-box binary: …/sbstub.sh
[OK] sing-box version: sing-box version 1.13.15
[OK] rule-sets: 4/4 usable
[OK] geoip-cn.srs: usable, 203 bytes, 0 seconds ago
[OK] geosite-cn.srs: usable, 203 bytes, 0 seconds ago
[OK] geosite-google.srs: usable, 203 bytes, 0 seconds ago
[OK] geosite-private.srs: usable, 203 bytes, 0 seconds ago
[OK] configuration: /tmp/t20-y8bxy_o_/etc/sing-box/config.json
[OK] config drift: matches what sc last generated
[OK] sing-box check: no error reported
[OK] IPv6 (AAAA): AAAA queries are answered empty (setting: auto — this host has no global IPv6 address); config.json carries this decision
[OK] service: running (via systemd)
[OK] boot autostart: enabled
[OK] TUN interface: sb-tun
[OK] TUN addresses: 172.19.0.1/30
[OK] Clash API: 127.0.0.1:34759
[OK] Clash API responding: yes
[OK] node delays: 2/2 nodes carry a stored delay (history, not a fresh measurement); auto-select is on n1
[OK] DNS lookup: api.ipify.org resolved in 0 ms, through the running sing-box
[OK] egress IP: 203.0.113.7
[OK] file permissions: no credential file grants access to group or other, and the directory is not group- or other-writable
```

Delta **+5** rows exactly. The five new rows are `config drift`, `IPv6 (AAAA)`,
`node delays`, `DNS lookup`, `file permissions`; the four rule-set rows gained their age
phrase **in place**, which is why six facts cost five rows.

**Why the "names a path" clause needed a second pass.** The first implementation of the
assertion banned any `/` in a new row's value, and `2/2 nodes carry a stored delay` failed
it — a count, not a path, and the same shape the pre-existing `4/4 usable` row has. The
test now tokenises the value and flags a token that *starts* with `/` or contains `/etc/`,
plus the seven command literals (`sc reload`, `sc update-rules`, `sc ls`, `sc use`,
`chmod`, `run:`, `` run ` ``). This is a fix to the assertion, not a weakening of GC-1:
under the corrected test the offender list is still empty and a build that printed a path
would still fail.

**Why exit 0 was reachable.** PQ-8's recipe held exactly: `sc.SB_BIN` repointed at a stub
script (no `PATH` games), one argv-dispatching `subprocess.run` stub covering
`_doctor_binary` / `_doctor_config` / `_doctor_service` / `_doctor_tun`, and one
`sc._egress_ip` replacement. No section this task does not own had to be excused, so
GC-1's "named partial" branch was never taken.

## 3. Two fixture traps that were measured, not reasoned about

**(a) `config.json` embeds the fixture's own temp root.** V-11's first run reported all
four decision states as DIFFERING — including `ipv6: on`, which E-3 cannot touch. Two
consecutive runs of the *same* side produced different digests, which is what gave it away:
`_runtime_overlay()` writes `route.rule_set[*].path` from `RULES_DIR`, so a fresh
`mkdtemp()` per side makes every pair differ for a reason with nothing to do with the
change. Running both sides in **one** root turned all four pairs IDENTICAL. Had this been
"explained" rather than diagnosed, E-3 would have been reverted for a defect it does not
have.

**(b) This host's umask is 002.** `Path.mkdir()` leaves the fixture's config directory at
`0775` and `write_text()` leaves its files at `0664` — both offending under
`_doctor_permissions()`' own `mode & 0o022` and `mode & 0o077`. Two steps failed for that
reason alone (the healthy-permissions control and GC-7a's ghost-entry run reported a wide
directory nobody planted). The harness now normalises the directory to `0755` after
`mkdir()`, and every permission step chmods what it plants; without it, a fixture measures
its own loader. This is the permission twin of the already-indexed `LANG` / `CLASH_PORT`
vacuity traps.

**(c) Two harness bugs that were *not* code defects**, recorded so stage 6 does not
re-derive them: `"settings.json"` appears in the `Clash API` row's own value
(`no port recorded in settings.json`), so "settings.json is absent from stdout" is the
wrong assertion for the exclusion — the right one is "absent from every quoted detail
line". And a broken-pipe traceback from the stub server during V-7's hang case is the
client giving up on a sleeping handler, which is precisely what that step is testing.

## 4. The V-16 sweep, and why it is an AST walk

The design specifies V-16 as a grep over the diff. Run that way it produced three FAILs on
a correct build:

- `getmtime` — from `_doctor_rulesets()`' docstring, "no `os.stat`, no `getmtime`, no
  second timestamp source".
- `_dns_overlay(` "called inside the doctor block" — from `_doctor_ipv6()`'s docstring,
  "`_dns_overlay()` is deliberately **NOT** called from anywhere in this block".
- `ipv6_decision()` call sites `= 3` — one real call and two prose mentions in the same
  docstring.

The prose is the note a future editor needs and was kept. The sweep now parses `bin/sc`
and walks `ast.Call` / `ast.Attribute` / `ast.Name` nodes inside every `_doctor_*`,
`cmd_doctor`, `_egress_ip`, `_dns_overlay` and `_aaaa_rule` definition. Under that sweep:

```
_dns_overlay() call sites in the doctor block : 0
ipv6_decision() call sites in the doctor block: 1   (_doctor_ipv6, bin/sc:2617)
_aaaa_rule() call sites in the doctor block   : 1   (_doctor_ipv6, bin/sc:2635)
RULESET_STALE_DAYS Load sites in the whole file: 1  (_doctor_rulesets, bin/sc:2509)
st_size / getmtime / hashlib in edited functions: 0
.stat()/.lstat() added by the diff            : exactly ["dir_mode = CFG_DIR.stat().st_mode",
                                                        "mode = entry.lstat().st_mode"]
mode reads inside _doctor_permissions()       : ["stat", "lstat"]
clash_api() calls wrapped in a try            : 0
writers reachable from any doctor function    : 0
  (_init_files, _resolve_clash_port, generate_config, reload_or_restart, restart_service,
   save_nodes, save_settings, _write_private, _record_generated, mkdir)
```

This is strictly stronger than the substring form: a grep would have passed a
`clash_api()` call wrapped in a `try` written on two lines, and would not have proved the
threshold has exactly one *reader* as opposed to one *occurrence*.

## 5. Chinese rendering — both captures

Healthy fixture, `sc.LANG = "zh"` **and** `"lang": "zh"` in the fixture's own
`settings.json` (the `LANG`-vacuity trap: a harness that sets only one of the two renders
English and every Chinese assertion passes vacuously). Same +5 delta:

```
[正常] 规则集: 4/4 个可用
[正常] geoip-cn.srs: 可用，203 字节，0 秒前
[正常] 配置改动: 与 sc 最近一次生成的内容一致
[正常] IPv6（AAAA）: AAAA 查询直接返回空结果（设置：auto —— 本机没有全局 IPv6 地址）；config.json 与该决策一致
[正常] 节点延迟: 2/2 个节点有已记录的延迟（历史值，非实时测量）；自动选择当前走 n1
[正常] DNS 解析: api.ipify.org 用时 0 毫秒解析成功（经由正在运行的 sing-box）
[正常] 文件权限: 没有凭据文件对同组或其他用户开放，目录本身也不可被同组或其他用户写入
```

Problem fixture (stale rule-set, drifted record, disagreeing AAAA decision, no stored
delay, an empty DNS answer, a wide directory and a wide file):

```
[异常] geoip-cn.srs: 可用，203 字节，90 天前 —— 运行 `sc update-rules` 更新
[异常] 配置改动: 自 sc 生成以来已被修改 —— 请把改动写入 …/override.json，再运行 `sc reload`
[异常] IPv6（AAAA）: AAAA 查询正常解析（设置：auto —— 本机在 enp3s0 上有全局 IPv6 地址）；config.json 与该决策不一致 —— 运行 `sc reload` 重新生成
[异常] 节点延迟: 0/1 个节点有已记录的延迟 —— 可能探测尚未完成，也可能所有节点都不通；请查看 `sc ls`
[异常] DNS 解析: api.ipify.org 在 0 毫秒后返回了空结果 —— 可用 `sc use <编号>` 换一个节点试试
[异常] 文件权限: 5 个路径对同组或其他用户开放 —— 请逐条执行下面给出的命令
    …/etc/sing-box 的权限是 775 —— 请运行：chmod go-w …/etc/sing-box
    …/etc/sing-box/.config.sha256 的权限是 664 —— 请运行：chmod 600 …/etc/sing-box/.config.sha256
    …/etc/sing-box/config.json 的权限是 664 —— 请运行：chmod 600 …/etc/sing-box/config.json
    …/etc/sing-box/nodes.json 的权限是 664 —— 请运行：chmod 600 …/etc/sing-box/nodes.json
    …/etc/sing-box/wide.json 的权限是 644 —— 请运行：chmod 600 …/etc/sing-box/wide.json
```

No capture contains `失败`; no new conclusion renders as an English key; six English key
literals were grepped for by name and none leaked. (This capture is also the one that
exposed trap (b) in §3 — the 775/664 modes are the umask's, deliberately left in the
problem fixture because they exercise the multi-finding path.)

## 6. Why the bin/sc i18n check had to be written here

`verify_all` B.2 covers `install.sh` only — `check-i18n-parity.sh`'s own docstring says so,
and `bin/sc` has no `en` table, so its shape is different. A one-off AST check was written
for this stage: it extracts every literal first argument to `t()`, compares the key set
against `TRANSLATIONS["zh"]`, compares the `string.Formatter` placeholder set of each pair,
and greps the diff's **added lines** for `失败`. Result: 157 literal `t()` keys, 180 zh
entries, **0** missing, **0** placeholder mismatches, **0** added lines containing `失败`.
The 23-entry surplus is the keys that reach `t()` through a table rather than a literal
call — `DOCTOR_MARK`, `_status_text()`, `_age_text()`, `DOCTOR_SECTIONS`' labels — which
the checker resolves by also collecting every string literal in the module. Three `t()`
call sites take a non-literal argument (`bin/sc:997`, `:2913` ×2); all three pass a value
that is itself one of the table keys above.

## 7. What was deliberately not built

Rule 85's counter-rule was applied at four points where the code wanted to grow:

- **No `_doctor_node_delays()` / `_doctor_dns()` helpers.** E-8 declares one function edit;
  `_doctor_clash()` is longer than its siblings as a result, and that is the design's
  choice — both rows must know whether `/configs` answered, and a helper would either take
  that as a parameter (no gain) or ask again (a second request and a second opinion).
- **No `_age_seconds()`.** The design took the smaller option and it held: the number has
  exactly one consumer.
- **No new constant for the directory's target mode.** `chmod go-w` says what to do without
  inventing a directory-mode constant, so R-11's second half stays open and unclaimed.
- **No new string for the "document is not an object" cause.** An existing translated
  sentence fills the slot, so E-4 lands at exactly the declared +28 / −3.
- **No `_plain()` wrapper on the two mode strings** (`:2841`, `:2864`). They are
  `"%03o" % (st_mode & 0o777)` over an `int` this code formats itself, so no byte of them
  is foreign and neither CR nor ESC is representable in the output of that format. Wrapping
  them would satisfy GC-10's third clause by a call that provably does nothing, and the
  next reader would have to re-derive that it does nothing. The clause is met by
  construction and `04_DEVELOPMENT.md`'s disposition says so in those words rather than
  claiming a call that is not there. The value that genuinely *is* foreign — the
  auto-select tag the Clash API echoes — is `_plain()`ed, and V-17c is its control:

  ```
  V-17c   PASS   [OK] node delays: 1/1 nodes carry a stored delay (history, not a fresh
                 measurement); auto-select is on n1RED
  negative control, same stub, _plain() removed from that one argument:
                 row printed 'auto-select is on n1'   stdout has CR: True   has ESC: True
  ```

  The negative control is the point: without `_plain()` the row *looks* right on a terminal
  (the CR hides the rest of the tag) while a redirected report carries a live CSI sequence.
