# 06 — Test Report — `sc doctor` (T-05)

Mode **full** · Stage 6 (+ **stage 6b targeted re-verification** after DEF-1's fix) · Decision mode
**deferred-human (defer, do not ask)** — judgment calls are resolved here and recorded. Repo root for
every relative path: `/home/alan/Programs/singbox-cli`.

- **Verdict: PASS WITH DEFECTS** — 1 MINOR (DEF-2, shipping as a documented follow-up), 0
  BLOCKER/CRITICAL/MAJOR. **DEF-1 is fixed and independently re-verified on the real binary** (§11).
- **721 assertions, 0 failures**, three consecutive identical suite runs (6: 688; 6b adds q11's 33).
- `verify_all` **PASS 16 / WARN 1 / FAIL 0 / SKIP 1**, unchanged from stage 6; the one WARN is F.6,
  PM-accepted — but its *contents* changed at 6b, see §6.
- Harness: **mine**, 15 files, runnable at `docs/features/sc-doctor/qa-harness/` (`run_all.sh`).

---

## 0. Live-service witness (verbatim, before and after each run)

```
stage 6   BEFORE  MainPID=2500438   ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
          AFTER   MainPID=2500438   ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
stage 6b  BEFORE  MainPID=2887037   ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST
          AFTER   MainPID=2887037   ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST
```

Identical within each run, and re-read mid-run inside `q3_readonly.py` (3 readings) and
`q7_regress.py` (5 readings) — unchanged at every one, both runs. `systemctl is-active` was never
used as evidence: it prints `active` on both sides of a restart and would have passed during the very
incident it was written for (`insight-index.md:22`).

**The unit was restarted between the two runs, and it was not the pipeline.** Attributed by the PM
before 6b began: `NRestarts=0`, and the owner was working by hand in another terminal (`pts/4`) at
10:06 — `sc status` / `sc update-rules` / `sc reload` plus a `sed -i` against the installed binary.
6b therefore takes **2887037 / Sat 10:06:40** as its baseline. Not a violation; nothing "restored".

## 0.1 Safety and independence

**I rebuilt rather than inherited.** I read nothing of the developer's harness; my scripts, fixtures,
loader and assertions are my own, written from `01_`'s ACs, not from `04_`'s test code.

Every script — including every throwaway and one-liner — loads `bin/sc` through one loader,
`qa-harness/qa_load.py`, which:

1. asserts the import-time re-exec `os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])`
   (`bin/sc:84`) is present **exactly once**, replaces it, and asserts both that the needle is gone
   and that no `execvp("sudo"` survives — *before* `compile()`/`exec()` (`qa_load.py:88-97`);
2. hard-blocks `os.exec*` process-wide (`qa_load.py:31-36`);
3. hard-blocks service-affecting subprocess argv process-wide — `systemctl start/stop/restart/reload/
   enable/disable/mask/daemon-reload/kill`, `rc-service start|stop|restart`, `rc-update add|del`, any
   `sudo`, any invocation of the installed `/usr/local/bin/sc`, and any string/shell command
   (`qa_load.py:39-60`);
4. forces `SYSTEMD = OPENRC = False` unless the caller opts out (`real_init=True`), which only the
   scripts whose subject *is* S4 or `main()` do.

Nothing ran that can mutate live state: no `install.sh`, no `sc update-rules`, no `generate_config()`,
no `restart_service()`/`reload_or_restart()`, no `systemctl` mutation. `git status` is unchanged
(same 7 modified files + the untracked task folder); nothing was committed or pushed.

**Deliberate stubbing around the guard, stated explicitly** (rule: say so where you step around it):

- `q3_readonly.py` and `q9_misc.py` set `SYSTEMD = True` with the **real** `systemctl`, to exercise
  S4 against the live init system. Only `is-active` and `is-enabled` are reachable; both are queries
  and both are additionally allowed-listed by guard 3.
- `q6_status.py` (AC-16) replaces five module attributes — enumerated in §5.
- `q2/q9/q10` put fake `systemctl`/`ip`/`sing-box` scripts first on `PATH`; the real ones are never
  reached in those runs.
- **Privilege caveat**: I am not root and this host has `NOPASSWD` only for the *installed*
  `/usr/local/bin/sc`, which is an **older build with no `doctor`** (sha256
  `3a9a15d…`, no `cmd_doctor`). Every "real run" below is therefore the **working-tree** `bin/sc`
  executed as `alan`. See §8 for exactly what that leaves unverified.

---

## 1. The owner's goal — the failure chain, rendered

Fixture (`q1_chain.py`): rules directory **empty**, a `config.json` of `generate_config()`'s shape
whose four `route.rule_set` entries point at the missing `.srs` files, no init system, no Clash port
recorded, egress stubbed. The checker is the **real** `/usr/local/bin/sing-box` 1.13.15.

**Re-rendered at stage 6b**, after DEF-1's fix, in both languages. The S3 row below is now clean;
the stage-6 rendering carried `[31mFATAL[0m` there (kept on the record in §7 / DEF-1).

```
[OK] sing-box binary: /usr/local/bin/sing-box
[OK] sing-box version: sing-box version 1.13.15
[PROBLEM] rule-sets: 0/4 usable
[PROBLEM] geoip-cn.srs: missing, size unavailable
[PROBLEM] geosite-cn.srs: missing, size unavailable
[PROBLEM] geosite-google.srs: missing, size unavailable
[PROBLEM] geosite-private.srs: missing, size unavailable
[OK] configuration: /tmp/qa-chain-oyx79h_l/etc-sing-box/config.json
[PROBLEM] sing-box check: the checker reported an error:
    FATAL[0000] initialize router: parse rule-set[0]: open /tmp/qa-chain-oyx79h_l/etc-sing-box/rules/geoip-cn.srs: no such file or directory
[UNKNOWN] service: no init system detected (neither systemd nor OpenRC)
[UNKNOWN] boot autostart: no init system detected (neither systemd nor OpenRC)
[OK] TUN interface: sb-tun
[OK] TUN addresses: 172.19.0.1/30, fe80::d148:d1e6:e9c9:d1ed/64
[UNKNOWN] Clash API: no port recorded in settings.json
[UNKNOWN] Clash API responding: not probed — no port recorded
[OK] egress IP: 203.0.113.7
```

```
[正常] sing-box 可执行文件: /usr/local/bin/sing-box
[正常] sing-box 版本: sing-box version 1.13.15
[异常] 规则集: 0/4 个可用
[异常] geoip-cn.srs: 缺失，大小未知
[异常] geosite-cn.srs: 缺失，大小未知
[异常] geosite-google.srs: 缺失，大小未知
[异常] geosite-private.srs: 缺失，大小未知
[正常] 配置文件: /tmp/qa-chain-oyx79h_l/etc-sing-box/config.json
[异常] sing-box 配置检查: 检查器报告了错误：
    FATAL[0000] initialize router: parse rule-set[0]: open /tmp/qa-chain-oyx79h_l/etc-sing-box/rules/geoip-cn.srs: no such file or directory
[未知] 服务: 未检测到 init 系统（既没有 systemd 也没有 OpenRC）
[未知] 开机自启: 未检测到 init 系统（既没有 systemd 也没有 OpenRC）
[正常] TUN 接口: sb-tun
[正常] TUN 地址: 172.19.0.1/30, fe80::d148:d1e6:e9c9:d1ed/64
[未知] Clash API: settings.json 中没有记录端口
[未知] Clash API 是否响应: 未探测 —— 没有记录端口
[正常] 出口 IP: 203.0.113.7
```

**Judged as a human reading a bug report: YES, the root cause is nameable from the screen alone, in
causal order.** Four rule-sets missing → the checker refusing the config *because of the first of
them, by name* → the service facts below it. Exit `1`. Nothing above the rule-set rows could have
caused them, and nothing below them is left unexplained. AC-4 holds in both languages.

**The one blemish stage 6 found in exactly this row is gone.** It rendered
`    [31mFATAL[0m[0000] initialize router: …` — DEF-1, now fixed and re-verified against the real
checker (§7, §11). The line above is the product's own output, byte-for-byte, at stage 6b. Note that
`[0000]` (logrus' elapsed field) and `rule-set[0]` — the two pieces of legitimate text a CSI-stripper
could have eaten — both survive.

---

## 2. Test plan — per acceptance criterion

Harness files are under `docs/features/sc-doctor/qa-harness/`.

| AC | Test(s) | File | Verdict |
|---|---|---|---|
| AC-1 registered + dispatched | subparser/handler inspection + `sc doctor` through `main()` prints a report, not help | `q9_misc.py:21-29` | PASS |
| AC-2 help + READMEs | both blocks gain equal lines, `doctor` immediately after `status`; `sc help` renders in both languages; README heading counts and insertion index equal | `q9_misc.py:32-67` | PASS |
| AC-3 causal order | 7 labels, each exactly once, in S1..S7 order; all 8 FR-7 pairs `X→Y` asserted individually | `q1_chain.py:41-60` | PASS |
| AC-4 chain reads off the screen | §1 above; 4 PROBLEM rule-set rows → failing check naming the `.srs` → service rows | `q1_chain.py:62-74` | PASS |
| AC-5 read-only (files) | live `/etc/sing-box` + `/var/lib/sing-box` sha256/size/mtime_ns/mode/inode snapshot ×11 paths; fresh-host half via redirected root | `q3_readonly.py` | PASS (non-root, §8) |
| AC-6 read-only (service) | `MainPID`+`ActiveEnterTimestamp` around a real run | `q3_readonly.py:38-48` | PASS |
| AC-7 read-only (code) | AST closure from `cmd_doctor` + the seven probes → 22 functions; no writer, no mutating fs call, no non-`"rb"` open | `q9_misc.py:69-107` | PASS |
| AC-8 no probe kills the report | **seven** independent forced failures, each asserting all 7 labels + normal exit | `q2_probes.py:60-160` | PASS |
| AC-9 dead service ≠ suppressed rule-sets | asserted separately, fake `systemctl` reporting inactive | `q2_probes.py:118-125` | PASS |
| AC-10 invalid config suppresses nothing | malformed `config.json`, 7/7 sections | `q2_probes.py:100-104` | PASS |
| AC-11 three outcome classes | marker set over 11 scenarios == `{OK,PROBLEM,UNKNOWN}`; missing binary ⇒ S3 check UNKNOWN | `q2_probes.py:88-90,167-171` | PASS |
| AC-12 streaming | parent reads the capture file while the child is blocked in S7, then SIGINT | `q4_stream_reuse.py:29-61` | PASS |
| AC-13 rule-set reuse (C-6) | deletion test against `ruleset_states()` **and** `ruleset_state()` | `q4_stream_reuse.py:63-92` | PASS |
| AC-14 no `st_size` | AST over the whole graph + behavioural: `/proc/version` symlink (st_size 0, read 179) | `q4_stream_reuse.py:94-130` | PASS |
| AC-15 single definitions | `"sb-tun"` ×1, `"https://api.ipify.org"` ×1, `clash_api_port` on exactly 2 code lines (1 read, 1 write) | `q4_stream_reuse.py:132-146` | PASS |
| AC-16 `sc status` unchanged | HEAD vs tree in separate child processes, fd-level capture, 4 comparisons + 2 negative controls | `q6_status.py` | PASS (§5) |
| AC-17 non-TTY purity | `> out.txt` in **every** AC-8 scenario: 0 × `0x0D`, 0 × `0x1B`; plus a checker emitting real ESC+CR; **+ 40 000 fuzzed `_plain()` inputs at 6b** | `q2_probes.py:56-57`, `q10_vacuity.py:77-96`, `q11_plain_csi.py` | PASS |
| AC-18 bilingual coverage | 42 new zh keys enumerated by diffing key sets HEAD vs tree; placeholder-set equality each; 5 zh runs, label/value/marker leak scan | `q5_i18n.py` | PASS |
| AC-19 no namespaced keys | every added key is prose; no dotted/underscored token | `q5_i18n.py:42-46` | PASS |
| AC-20 no grep-literal collision | `t("failed: {e}")` **rendered at run time** → `失败：`, searched in 5 zh reports | `q5_i18n.py:49-77` | PASS |
| AC-21 exit status | documented in both help blocks + both READMEs; identical across en/zh, pipe/file, repeats; 0/1/2 all reachable, nothing else | `q2_probes.py:173-215`, `q9_misc.py:45,65-67` | PASS |
| AC-22 no traceback | stderr checked in every scenario of q1/q2/q3/q5/q7/q10 | throughout | PASS |
| AC-23 Python floor | `ast.parse(feature_version=(3,6))`, `py_compile`, `capture_output=` **exactly 3** (`:1020`, `:1065`, `:1719` at 6b — the third only shifted; same 3 at HEAD), diff free of the six forbidden tokens | `q9_misc.py:112-132` | PASS |
| AC-24 screen budget | healthy report **16** physical lines, widest **67** columns; fresh-host 15 | `q2_probes.py:222-228` | PASS |
| AC-25 gate | §6 | — | PASS |
| AC-26 scope | 5 product files; `install.sh`/`uninstall.sh`/`systemd/` `git diff --quiet` → 0; `--numstat` **`491 37 bin/sc`**; shortstat **`5 files changed, 573 insertions(+), 43 deletions(-)`** (6b figures; §11) | `q9_misc.py:134-159` | PASS |

**Boundary conditions**: BC-1 (`q2:81`), BC-2/BC-3 (`q2:92-97` — the rules dir is *not* created),
BC-4 directory / zero-byte / HTML page / good file (`q2:243-256`), BC-6 absent vs EACCES
(`q2:99-115` — permission is never rendered as absence), BC-7 nine-line checker message → 5 quoted +
`... 4 more line(s) not shown` (`q2:230-241`), BC-8 (`q2:128`), BC-9 vs BC-10 (`q2:134-141`), BC-11
(`q2:151`), BC-12 (`q2:146`), BC-13 (`q2:157`), BC-14 (AC-17 rows), BC-16 two concurrent runs
byte-identical (`q10:141-150`), BC-18 (`q5`).

---

## Adversarial tests — section 3, one per acceptance criterion

One stated failure hypothesis per acceptance criterion, an **independent** reproducer, and what
actually happened. Where the implementation survived, I say what I tried and why it held.

| AC | Hypothesis ("I expect failure when…") | Reproducer (all NEW, mine) | Outcome |
|---|---|---|---|
| AC-1 | `doctor` falls through to `cmd_help` because `main()`'s new branch changed dispatch | `q9_misc.py` via `main()` | Survived — output begins `[OK] sing-box binary:`, no `Usage:` |
| AC-2 | the two help blocks drift by a line, or the READMEs insert at different points | structural diff of heading lists | Survived — equal line counts, `doctor` at `status+1` in both, identical heading index |
| AC-3 | the config check prints above the rule-set rows | `q1_chain.py` + a **mutant** that transposes `DOCTOR_SECTIONS` | Survived; mutant gives `configuration@2 < rule-sets@7` — the assertion can fail |
| AC-4 | the quoted checker message does not name the rule-set, so the cause is not readable | real `sing-box check` on a real broken config | Survived — `parse rule-set[0]: open …/geoip-cn.srs: no such file or directory`. **But see DEF-1** |
| AC-5 | the run bumps `cache.db`'s mtime, or `main()` still initialises for `doctor` | 11-path sha256 snapshot; **mutant** flipping `if args.cmd == "doctor"` to `"__never__"` | Survived; mutant creates `['etc-sing-box']` — the assertion can fail |
| AC-6 | a probe touches the unit | `systemctl show -p MainPID -p ActiveEnterTimestamp` ×9 readings | Survived — byte-identical every time |
| AC-7 | a writer is reachable via a transitive call I did not expect | AST closure seeded with `cmd_doctor` **and** the seven probes (`DOCTOR_SECTIONS` holds references, not calls — seeding only `cmd_doctor` reaches 4 functions and proves nothing) | Survived at 22 functions |
| AC-8 | one forced failure truncates the report | 7 scenarios + a **mutant** deleting the driver's `except Exception` with `_doctor_tun` raising | Survived; mutant prints 4/7 sections + a traceback |
| AC-9 | the dead-service branch short-circuits S2 | fake `systemctl is-active` → 3 | Survived — 4/4 rule-set rows, `[OK] rule-sets: 4/4 usable` |
| AC-10 | a malformed config aborts before S4..S7 | `config.json` = `{ this is not json ` | Survived — 7/7 sections, exit 1 |
| AC-11 | a prerequisite failure renders as class 2 in a dependent section | binary removed from `PATH` | Survived — `[UNKNOWN] sing-box check: no sing-box binary on PATH` |
| AC-12 | the report sits in the block buffer until exit | **parent** reads the file mid-flight, then SIGINT (developer's version had the child read its own file) | Survived — S1..S6 present, S7 absent, final == mid |
| AC-13 | an independent path to rule-set facts survives deletion | delete `ruleset_states()` / `ruleset_state()` from the module namespace | Survived — `NameError` in S2 **and** in `ruleset_report()` together |
| AC-14 | the size printed is `st_size` | `.srs` → symlink to `/proc/version` (st_size **0**, read **179**); plus a **mutant** returning `path.stat().st_size` | Survived — prints `179 bytes`; mutant prints `0 bytes` |
| AC-15 | a second copy of a literal crept in | source counts | Survived |
| AC-16 | E-12/E-13 moved a byte of `sc status` | HEAD vs tree, separate processes, fd capture, 4 comparisons + **2** negative controls | Survived; both controls differ |
| AC-17 | a real tool's colour reaches a redirected report | fake checker emitting `\033[31m…\r\n`; **mutant** removing `_plain()` from `_doctor_run` | Survived — 0 × `0x1B`; mutant yields 2 × `0x1B` |
| AC-18 | a zh entry is missing (silent English) or a placeholder mismatches (`KeyError`) | key-set diff + 5 zh runs; **mutants**: delete `"rule-sets"`'s zh entry; rename `{size}`→`{bytes}` | Survived; mutant 1 leaks `rule-sets`, mutant 2 surfaces the failure |
| AC-19 | a namespaced key slipped in | regex over the 42 added keys | Survived |
| AC-20 | a zh string contains `失败：` | literal **rendered at run time**, searched in 5 zh reports | Survived — absent everywhere |
| AC-21 | the status differs between languages or between pipe and file | 4 runs ×2 languages + a file run + an all-OK fixture | Survived — `{1}` across languages/repeats, 0 on all-OK, statuses ⊆ {0,1,2} |
| AC-22 | an interpreter traceback escapes | stderr asserted in ~25 runs incl. a probe raising `ValueError` | Survived |
| AC-23 | the diff adds a 3.7-only construct | 3.6 `feature_version` parse + token scan of the `+` lines | Survived — `capture_output=` still exactly 3 |
| AC-24 | zh double-width text or a long path pushes a fixed row past 80 | healthy report measured | Survived — 16 lines, 67 columns |
| AC-25 | the change adds a `verify_all` FAIL | working tree vs pristine **clone** | Survived — delta is one predicted WARN |
| AC-26 | an incidental edit outside the five files | `git diff --name-only`, `--quiet`, `--numstat` | Survived |
| **T-10** | the `(status, digest, size)` widening restarts the service every Monday | `cmd_update_rules` twice against an offline `file://` mirror, apply helpers replaced by counters | Survived — run 1: 1 apply; run 2: **0** applies, "No rule-set changed"; a changed body ⇒ exactly 1 apply naming exactly that tag |
| **C-2** | the first-run port resolution erases `lang`/`mode`/`default_tun`/`update_interval` | fixture settings file + `_resolve_clash_port()`; control: `save_settings({"clash_api_port": …})` | Survived — all four intact; the control **does** erase them |
| **C-1** | some other subcommand stopped initialising | `lang`, `mode`, `status`, `ls`, `now`, `help`, bare `sc` on an empty root | Survived — tree created, `nodes.json` 0600, `clash_api_port` persisted, every time |
| **T-1** | `sing-box check -c` creates/updates the declared `cache_file` | 3 arms on temp-dir copies + live-cache control | Survived — see §4 |
| **I-2** | a credential reaches stdout through the quoted checker message | 9 deliberately-failing configs carrying a UUID and a password | Survived — see §4 |

---

## 4. Findings that needed measurement, not prediction

**T-1 / RISK-1 / C-7 — measured independently, read-only, on copies.** `sing-box check -c`
(**1.13.15**) against a config whose `experimental.cache_file.path` points inside a harness-owned temp
dir: arm A (file absent) → still absent, nothing else created; arm B (file pre-existing, mtime 0) →
size, `st_mtime_ns` and sha256 unchanged; arm C (a **failing** check) → still no cache file, nothing
modified. Control: the live `/var/lib/sing-box/cache.db` fingerprint identical across the whole
experiment. **RISK-1 does not materialise; the design's prediction is confirmed by measurement, so
C-7's "inconclusive" trigger does not fire and `02_` §3.8's contingency is not needed.** Scope of the
claim: one sing-box version, on a shape-equivalent copy (the installed config is root-only to me), and
side effects outside the config's directory and the live cache file were not enumerated.

**I-2 — the credential channel, eyeballed on real messages.** Nine failing configs carrying
`uuid=1111…5555` and `password=SUPERSECRETPASSWORD` (missing rule-set, unknown field, wrong password
type, bad shadowsocks method, undecodable 2022 key, port as string, hysteria2 obfs, duplicate tag,
malformed JSON). **No credential value appeared in any message.** sing-box's errors are structural:
Go struct/field paths, field *names*, file paths, offsets. Two things do reach stdout and the owner
should know: the **config file path**, and an **outbound tag** (`duplicate outbound/endpoint tag: p`)
— and this project derives tags from share-link fragments/hostnames (`bin/sc:346`), so a node *name*
can appear. That is not a credential and it is what makes the report diagnostic. **Assessment: the
report is safe to paste, with the caveat that node tag names may be visible.** Empirical over 9
variants, not a guarantee — the channel is unbounded in content (bounded to 5 lines by BC-7).

**T-4 / NFR-2 — runtime.** Healthy (all probes local and answering): **0.05 s** best of 3, well under
the 2 s claim. Broken-but-DNS-responsive: **11.10 s**, inside the design's ≤ 15 s claim. I made both
bounds genuinely payable rather than assuming them: the 3 s Clash bound via a loopback listener that
accepts the connection and never answers (a *refused* port returns instantly, which is why the
developer's 0.94 s figure does not exercise it), and the 8 s egress bound via a second such listener
with the endpoint redirected in a labelled mutant — no DNS involved, so this is exactly the
"DNS-responsive" case. The DNS-blackholed case is **unverified** (§8).

---

## 5. AC-16 / C-4 / M-1 — the comparison, stated so it can fail

`HEAD:bin/sc` and the working tree each run in **their own child process** (no shared module object,
no stub leakage), each through the QA loader, with fd-level capture so the real
`ip -br addr show sb-tun` subprocess output is inside the compared bytes.

Replaced module attributes (`q6_status.py:70-79`) — this is the list `04_` §5 originally omitted:

```
SYSTEMD = False ; OPENRC = False    # the systemctl-status subprocess does not run
is_running  = lambda: True          # <- WITHOUT THIS the gate at bin/sc:1201 is never taken
                                    #    and E-13's region is outside the capture entirely
load_nodes  = lambda: {"active": "LosAngeles-US", "nodes": [1]}
clash_api   = lambda *a, **k: {"mode": "rule"}
CLASH_PORT  = 29099
urlopen     = stub (fixed value, or a deterministic raise)
```

**Compared**: `=== Service status ===`, `=== TUN interface ===` **and the real `ip` output**,
`=== Current node ===`, `=== Route mode ===`, `=== Clash API ===`, `=== Egress IP ===` and the egress
value — plus the `(error: …)` arm. Four comparisons (`en`/`zh` × egress-succeeds/egress-raises): all
**byte-identical**.
**Excluded**: the `systemctl status --no-pager -n 5` / `rc-service status` subprocess output
(`bin/sc:1195-1198`). It carries a live PID, an elapsed time and five journal lines, so two captures
of even *unmodified* code differ. I additionally asserted that this region's **source is byte-identical
at HEAD and in the tree**, so excluding it cannot hide a change.
**Non-vacuity**: two negative controls — perturbing `TUN_IFACE` to `"lo"`, and appending a byte to
`_egress_ip()`'s return — each make the captures differ. Three positive assertions confirm the capture
really contains the `ip` output, the egress value and the post-gate region.

M-1 is thereby discharged: the developer's *assertions* were sound, the *stated premises* were
incomplete; re-run independently here with the premises complete.

---

## 6. `verify_all` result

| tree | PASS | WARN | FAIL | SKIP |
|---|---|---|---|---|
| pristine `HEAD` `49506f8` (**clone**, `.git` is a directory) | 17 | 0 | **0** | 1 |
| working tree (this change, before `06_`) | 16 | 1 | **0** | 1 |
| working tree, final (with `06_` and `qa-harness/`) | 16 | 1 | **0** | 1 |
| **stage 6b**, after DEF-1's fix | 16 | 1 | **0** | 1 |

**Delta: one PASS→WARN, on F.6 only.** F.6 prints no detail for a WARN (`verify_all.sh:230-237`), so
I enumerated its cause from the predicate directly — `find docs/features -name 'PM_LOG.md' -o -name
'0[1-7]_*.md'`, cap 500, `_archived/` excluded. **Its contents changed at 6b.** At stage 6 exactly
one file was over cap: `02_SOLUTION_DESIGN.md` (857). At 6b **two** are: `02_` (857) **and
`04_DEVELOPMENT.md`, which the §13 fix-up append pushed 462 → 508**. F.6 is a single WARN step
either way, so the summary is unchanged and there is still **0 FAIL** — but the PM's prediction "the
single WARN is F.6 naming `02_`" is now only half true. Current: `01_` 496 · `02_` **857** · `03_`
189 · `04_` **508** · `05_` 489 ·
`PM_LOG` 199 · this file (under cap, checked last). Both clear when the task archives, since F.6
skips `_archived/`. Not a defect, and not mine to fix — flagged for the PM.

Baseline was a `git clone --no-hardlinks`, not a worktree: a worktree's `.git` is a *file*, which
silently turns A.1/A.2 into SKIP and misreports the summary (`insight-index.md:26`) — reconfirmed here
by asserting `.git` is a directory before running.

`.harness/scripts/baseline.json` **deliberately not updated**, following the standing project
precedent (T-10 `06_` §4): it reads `test_count: 0` because **no suite is committed** — T-07 is
declined for the fourth time (`.harness/rejected-decisions.md` → `ruleset-unit-tests-in-t02`), so
this task's 721 assertions live in an uncommitted harness. Raising the number would assert coverage
the repository cannot re-run. It goes up in T-07, when a suite is committed and wired into
`verify_all` B. **`verify_all` and its checks were not modified.**

---

## 7. Defects

Both were MINOR. No BLOCKER, CRITICAL or MAJOR. **DEF-1 is now FIXED and re-verified (§11); DEF-2
ships open as a documented follow-up.** The original findings are kept below — what was caught is
part of the record, and DEF-1's evidence is what makes the fix checkable.

- **DEF-1 [MINOR / cosmetic] — ✅ FIXED at stage 4c, RE-VERIFIED at stage 6b (§11).** Fix:
  `_plain()` (`bin/sc:1236-1278`) now removes a **complete** CSI sequence instead of the ESC byte
  alone. Re-measured on the real checker through the product's own `_doctor_run()`/`_plain()` path —
  raw output 2 × `0x1B`, rendered row 0 × `0x1B` / 0 × `0x0D`, `[0000]` and `rule-set[0]` intact;
  §1's rendering above is the corrected one. **Original finding, as filed at stage 6:** the quoted
  `sing-box check` line carried ANSI CSI litter in the one row AC-4 depends on. `bin/sc:1236-1244`
  (`_plain()`) stripped ESC **byte-wise**, so `\x1b[31m` lost the ESC and left the literal text
  `[31m`. sing-box 1.13.15 colourises **unconditionally, even when stdout is a pipe** (measured:
  `p.stdout[:60]` = `b'\x1b[31mFATAL\x1b[0m[0000] initialize router: …'` with `stdout=PIPE`), so
  **every** real broken host rendered
  `    [31mFATAL[0m[0000] initialize router: parse rule-set[0]: open …`. AC-17 still passed
  (0 × `0x1B`) and the diagnosis was still readable, but the design's own sample (`02_` §6.2) shows
  this line clean, and NFR-3 makes this artefact's readability the point. *Reproducer:*
  `qa-harness/q1_chain.py`, or 3 lines of `subprocess.run([SB,"check","-c",cfg], stdout=PIPE)` on any
  config referencing a missing `.srs`. *Owner: solution-architect (D-6 chose byte-wise stripping over
  importing `re`) → developer.* Two one-line remedies existed (a CSI-aware strip without `re`, or
  `env NO_COLOR=1` on the checker); the developer took the first. The defect's own lesson drove
  §11's method: it went unseen at stage 4 because the developer's fixtures used a **fake** checker.

- **DEF-2 [MINOR / already ruled at gate F-12, but now OBSERVED] — a *hung* Clash port loses S6's port
  row.** `clash_api()` (`bin/sc:1043-1057`) catches only `URLError`/`HTTPError`, so a **read-phase**
  `socket.timeout` escapes to `cmd_doctor`'s backstop and S6 renders as **one** row,
  `[UNKNOWN] Clash API: this check could not run: timed out`, instead of the designed two
  (`[OK] Clash API: 127.0.0.1:<port>` + `[PROBLEM] Clash API responding: no answer within the 3s
  timeout`). The recorded port — a fact the reader needs — is not printed, and the row is UNKNOWN
  where BC-12 says PROBLEM. A **refused** port (service simply down, the common case) behaves exactly
  as designed and is PROBLEM: verified separately. *Reproducer:* `qa-harness/q9_misc.py` T-4 section —
  bind a loopback listener, never read from it, put its port in `settings.json`, run `doctor`. All
  seven section labels still print and the exit map still holds, so FR-9/AC-8/AC-21 are unaffected.
  *Owner: developer (gate ruled it INFO/"not a bug to chase"; I file it MINOR because it is now
  observed rather than predicted, and it costs the reader the port number on a firewalled host).*
  **Disposition — SHIPPING OPEN, as a documented follow-up.** The owner ruled it not to be fixed in
  this task: it was predicted by the gate as F-12 and accepted *before* code was written, the report
  stays complete (FR-9 holds), and a **refused** port — the case that actually happens when the
  service is down — behaves exactly as designed. **Re-confirmed unchanged at stage 6b**, deliberately
  as a description check and not as a defect re-test: `q9_misc.py` still prints the single row
  `[UNKNOWN] Clash API: this check could not run: timed out`, so the text above is still accurate.

**Observations, not defects** (no action requested):

- `_init_files()` hard-codes `/var/lib/sing-box` (`bin/sc:309`) — unlike `CFG_DIR`/`RULES_DIR` it is
  not repointable, so any harness driving a **non-doctor** command through `main()` touches the real
  `/var/lib`. Harmless here (`mkdir(exist_ok=True)` on an existing directory is a no-op and the
  snapshot confirms it), but a QA-harness trap worth knowing.
- Redirected `sc status` interleaves the `ip` subprocess output above the Python prints (visible in
  §5's capture) because the subprocess writes unbuffered to fd 1 while Python block-buffers to a file.
  Pre-existing at HEAD, byte-identical on both sides, untouched by this task.
- `04_` §3 says `02_` is 858 lines; `wc -l` says **857**. Cosmetic record drift only.
- **(6b)** `04_DEVELOPMENT.md` is now **508** lines, over F.6's 500 cap — see §6. Document hygiene,
  not a product defect; clears on archive.
- **(6b, out of scope — T-12)** The installed `/usr/local/bin/sc` carries `query_type: [28, 64, 65]`
  where the repo's `bin/sc:960` has `[64, 65]`. **It does not affect any `doctor` probe's result** —
  measured, not assumed. `query_type` lives in `generate_config()`'s DNS block, which `doctor` never
  calls (AC-7's closure), and the only channel to a probe is S3's real `sing-box check` over whatever
  config is on disk; 1.13.15 accepts both shapes identically (`[64, 65] -> rc=0, out=''` and
  `[28, 64, 65] -> rc=0, out=''`, temp-dir configs). Left to T-12.

---

## 8. What I could NOT verify, and why

An honest "unverified" is worth more than an asserted pass.

1. **`sc doctor` as root, and the installed command.** This host grants `NOPASSWD` only for
   `/usr/local/bin/sc`, which is an **older build without `doctor`**; general `sudo` needs a password
   I do not have. Every run above is the working-tree `bin/sc` as `alan`. Consequences: (a) AC-5's
   live half is a real run against the real paths, but at reduced privilege; (b) S3 could not read
   the root-only `/etc/sing-box/config.json`, so **the live-tree run never invoked `sing-box check`
   on the real config** — RISK-1's channel is therefore covered only by §4's temp-dir measurement,
   not against the live cache; (c) `nodes.json`/`config.json` sha256 could not be computed (mode 0600)
   — the live snapshot compares their size, mtime_ns, mode and inode, which is enough to detect a
   rewrite but not a same-length in-place edit. The developer's open item "QA should run the installed
   binary once as root" is **not discharged**; it needs the owner or an upgraded install.
2. **NFR-2 with DNS blackholed.** Dropping routes / blackholing a resolver needs root. The
   design's honest statement ("may exceed the sum without bound; reported, not failed") is
   **untested**. What I did measure is §4's DNS-free 11.10 s.
3. **OpenRC.** No OpenRC host exists here, so S4's `rc-update show default` arm, the
   `not in the default runlevel` drift key and gate F-11 (`is_running()`'s `capture_output=` on a
   3.6 OpenRC host) are verified by inspection only.
4. **Python 3.6 execution.** `bin/sc` *parses* under `feature_version=(3,6)`; no 3.6 interpreter is
   installed, so it was never *run* on one.
5. **A real `.srs` mid-replacement (BC-15).** I asserted the reader's contract and BC-16's two
   concurrent runs, but did not race a real `sc update-rules` against a `doctor` — that would mean
   running the real downloader against the live tree.
6. **AC-2's "READMEs are line-for-line mirrors".** Verified structurally (equal heading counts, equal
   insertion index, both exit tables present, `+31/+31` lines); I did not diff them sentence by
   sentence.

---

## 9. Stability

| Run | Result |
|---|---|
| stage 6 — full suite, 3 consecutive passes | 36 / 183 / 17 / 25 / 276 / 12 / 64 / 12 / 47 / 16 = **688 PASS, 0 FAIL**, identical each time |
| **stage 6b — full suite, 3 consecutive passes** | 36 / 183 / 17 / 25 / 276 / 12 / 64 / 12 / 47 / 16 / **33** = **721 PASS, 0 FAIL**, identical each time |
| Same fixture, 10 repeats | 1 distinct report sha256, 1 distinct exit status |
| Two concurrent `doctor` runs (BC-16) | byte-identical reports, identical exit status |
| Live-service witness | re-read 9 times per run — unchanged in both |

No flakes in either run. The **per-file counts are identical** across 6 and 6b for q1–q10; the only
change is the new q11. That is the load-bearing no-collateral evidence: 688 assertions spanning all
26 ACs produced the same verdict, one by one, before and after the fix.

---

## 10. Verdict

**PASS WITH DEFECTS: DEF-2 (MINOR — a hung Clash port loses S6's port row to the driver backstop; gate F-12, observed, ruled acceptable and shipping as a documented follow-up).** DEF-1 is fixed and re-verified.

---

## 11. Stage 6b — targeted re-verification of DEF-1's fix

Scope: DEF-1 only, plus the collateral it could plausibly have caused. Not a re-QA. `04_` §13 was
read as a **claim to falsify**, not as evidence — every number below is one I measured.

### 11.1 The adversarial questions, and what happened

New reproducer `qa-harness/q11_plain_csi.py` (mine, 33 assertions), driving `_plain()` directly. Its
oracle for "unchanged behaviour" is the **pre-fix implementation quoted from `02_` §3.6** —
`text.replace("\r","").replace("\x1b","").rstrip()` — the design document's, not the developer's
code, so the two share no assumption.

| # | Hypothesis ("I expect failure when…") | Outcome |
|---|---|---|
| H1 | the CSI scanner leaves an ESC on some path, breaking AC-17 — the criterion the fix could most plausibly have broken | Survived — 40 000 fuzzed inputs over an ESC-heavy alphabet: 0 results containing `0x1B` or `0x0D` |
| H2 | an ESC-free row is no longer byte-identical (e.g. the early return drops an LF, or `rstrip` moved) | Survived — every ESC-free input in the 40 000, plus 20 000 more over a wider alphabet, equals the `02_` §3.6 oracle exactly |
| H3 | the whole-CSI strip eats real text — `[0000]` or `rule-set[0]` | Survived — both intact in the real line; the *only* input that loses `[0000]` is a synthetic `ESC` + `[0000]`, which **is** a valid CSI by the grammar and cannot arise from logrus (whose `[0000]` always follows a completed `\x1b[0m`). Asserted explicitly so it is on the record |
| H4 | a truncated/exotic escape (`\x1b[`, `\x1b[31`, OSC, charset selection) throws, hangs, or eats the following text | Survived — each loses only its ESC, i.e. HEAD's behaviour; `\x1b`×50, `\x1b[`×50, a 5000-digit parameter run and `\x1b[\x1b[\x1b[m` all return, none raise |
| H5 | the fix leaked outside `_plain()` | Survived — `re` still not imported (`bin/sc` imports are unchanged); one `def _plain(`; and the arithmetic closes exactly: `_plain` grew 9 → **43** lines = **+34**, and `bin/sc`'s insertions grew 457 → **491** = **+34**, with deletions unchanged at **37** |

**Non-vacuity.** q11 runs the pre-fix oracle against the same real coloured line and asserts it
**fails** — so these assertions can go red.

### 11.2 DEF-1 measured on the real binary, through the product's own path

Not a fake checker — that was the whole lesson of the defect. Real `/usr/local/bin/sing-box` 1.13.15,
`check -c` on a **temp-dir copy** of a config referencing missing `.srs` files. Read-only; the live
service and `/etc/sing-box/config.json` were never touched.

```
RAW rc=1  0x1B count=2
RAW repr[:80] = b'\x1b[31mFATAL\x1b[0m[0000] initialize router: parse rule-set[0]: open /tmp/qa-def1-raw'
_doctor_run rc=1  0x1B=0  0x0D=0
first_line = 'FATAL[0000] initialize router: parse rule-set[0]: open /tmp/qa-def1-raw-xz2mcytl/etc-sing-box/rules/geoip-cn.srs: no such file or directory'
```

The raw bytes really are coloured (2 × `0x1B`) in this very run, so the clean result is the fix
working, not the checker declining to colour. §1 is the same thing end-to-end through `cmd_doctor`.

### 11.3 The rest of the checklist

- **AC-17** — `q2_probes.py` redirects **every** AC-8 scenario to a real file and asserts 0 × `0x0D`
  and 0 × `0x1B` per scenario: **183 PASS, 0 FAIL**, unchanged; `q1` the same for both languages of
  the failure chain; plus H1's fuzz.
- **AC-4 / AC-3** — re-rendered in both languages, §1. The chain still reads in causal order (four
  missing rule-sets → the checker refusing the config *by naming the first of them* → the service
  facts), now without the litter. 36 PASS.
- **No collateral** — `sc status` byte-identical HEAD vs tree in both languages (q6, 12 PASS);
  `ruleset_state()`/`ruleset_states()` contract and T-10's restart decision (q4 25, q7 64 PASS — run
  1 applies once, run 2 applies **0** times); `capture_output=` at exactly `[1020, 1065, 1719]`;
  `ast.parse(feature_version=(3,6))` OK; `git diff --quiet -- install.sh uninstall.sh systemd/` → **0**.
- **Diffstat corrected** — authoritative figures are now `5 files changed, 573 insertions(+), 43
  deletions(-)` and `git diff --numstat -- bin/sc` → `491  37`; the earlier `539`/`457 37` (here and
  in `04_` §3) are superseded.
- **`verify_all`** — **PASS 16 / WARN 1 / FAIL 0 / SKIP 1** (§6). Not modified.
- **My harness's failures** — the developer reported 2; I found **3**. Two were the stale pinned
  diffstat literals, as claimed. The third appeared *after* their run: `q9`'s AC-26 file-set
  assertion caught `docs/batches/default/BATCH_PLAN.md`, which the PM edited at 10:06 to file pool
  row T-12. That is pipeline bookkeeping, not shipping code, so the harness now excludes
  `.harness/`, `docs/batches/`, `docs/features/` and `docs/tasks.md` **by name, with the reason
  written down**, rather than by loosening the assertion. All three fixed; `q9` is **47 PASS, 0
  FAIL**, and the harness runs green verbatim via the new `qa-harness/run_all.sh`.
- **Baseline** — `.harness/scripts/baseline.json` still not raised, for §6's unchanged reason: no
  suite is committed, so a raised count would assert coverage the repository cannot re-run.
