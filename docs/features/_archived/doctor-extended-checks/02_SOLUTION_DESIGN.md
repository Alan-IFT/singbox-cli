# 02 — Solution Design · T-20 `doctor-extended-checks`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).
>
> Mode: **full** · single-Developer project (no `.harness/agents/dev-*.md`), so no
> `## Partition assignment` section. The reuse audit, the risk analysis and every option
> comparison live in `02_RATIONALE.md`. Three units that the PM's dispatch requires in the
> contract fit no declared section shape on this project (R-37, **fourth** confirmation) and are
> carried below as named sections, recorded as ledger row **E-20**: `## BC-16 probe and ruling`,
> `## Smaller alternative rejected` and `## Requirement coverage`.

## Architecture summary

1. **Six new facts, five new rows, two new sections.** `_doctor_rulesets()`, `_doctor_config()` and
   `_doctor_clash()` each gain rows inside the section that already owns their subject;
   `_doctor_ipv6()` and `_doctor_permissions()` are the only new probes, and `DOCTOR_SECTIONS` grows
   by exactly those two entries. Every new row stands on a call its feature owner already ships —
   `_age_text()`/`ruleset_states()` (T-19 K-17), `_drift_state()` (T-06), `ipv6_decision()` (T-16),
   `stored_delays()` (T-15), `CRED_MODE` (T-13), `clash_api()` (T-18) — and forms no second opinion.
2. **Three seams are touched outside the doctor block, each for a stated failure it removes**:
   `_aaaa_rule()` is extracted out of `_dns_overlay()` so the AAAA probe compares against the one
   authored rule instead of re-spelling it (and so `ipv6_decision()` is called once, not twice);
   `EGRESS_HOST` is extracted out of `_egress_ip()` so the name the DNS row resolves and the name the
   egress row resolves are one literal (Q-13); `RULESET_STALE_DAYS = 60` is the one staleness
   threshold. `ipv6_decision()`, `stored_delays()`, `_drift_state()`, `ruleset_state()`, `_age_text()`
   and `clash_api()` are unchanged.
3. **Nothing else moves**: `sc status`, `sc ls`, `sc config`, `main()`'s read-only dispatch arm, the
   row grammar, the three outcome classes, the exit mapping, the three socket timeouts, the emitted
   `config.json` bytes, `install.sh`, `uninstall.sh` and `systemd/` are all unchanged.

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| E-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `EGRESS_HOST = "api.ipify.org"` as a module constant immediately above `_egress_ip()` (`:407`), and `_egress_ip()` builds its URL from it. The request URL stays byte-identical (I-2, K-13). ≈ +6 / −1 | single-dev |
| E-2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `RULESET_STALE_DAYS = 60` in `# Rule-set constants` beside `SRS_MIN_BYTES` (`:95`), with the comment stating why 60 (I-1, K-4). ≈ +6 | single-dev |
| E-3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_aaaa_rule(suppress)` extracted immediately above `_dns_overlay()` (`:1618`); `_dns_overlay()`'s body becomes one call to it. Emitted bytes unchanged (I-3, K-5). ≈ +12 / −3 | single-dev |
| E-4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `TRANSLATIONS["zh"]`: **+28** entries in the existing thematic groups (I-10…I-16), **−3** entries that become dead (`"{reason}, {size} bytes"`, `"{reason}, size unavailable"`, `"no answer within the 3s timeout"`). ≈ +30 / −3 | single-dev |
| E-5 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_doctor_rulesets()` (`:2425`): destructures `mtime`, renders `_age_text(mtime)` on each existing row, adds the staleness verdict and its next step. No new row (I-4, K-3). ≈ +12 / −5 | single-dev |
| E-6 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_doctor_config()` (`:2453`): one drift row computed before the readability probe and returned on **all three** paths, between the `configuration` row and the `sing-box check` row (I-5, FR-12). ≈ +14 / −3 | single-dev |
| E-7 | `/home/alan/Programs/singbox-cli/bin/sc` | new (function) | `_doctor_ipv6()` — the AAAA-consistency probe, placed after `_doctor_config()` (I-6). ≈ +32, of which ~12 are docstring | single-dev |
| E-8 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_doctor_clash()` (`:2568`): FR-9's reworded PROBLEM value, plus the node-delay row and the DNS row, both on the branch where `/configs` answered (I-7, I-8, K-1, K-2). ≈ +38 / −3 | single-dev |
| E-9 | `/home/alan/Programs/singbox-cli/bin/sc` | new (function) | `_doctor_permissions()` — the credential-directory probe, placed after `_doctor_egress()` (I-9). ≈ +48, of which ~14 are docstring | single-dev |
| E-10 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `DOCTOR_SECTIONS` (`:2604`) gains `("IPv6 (AAAA)", _doctor_ipv6)` after `configuration` and `("file permissions", _doctor_permissions)` last; `DOCTOR_MSG_LINES`' comment (`:2335`) widens from "a checker message" to "a quoted list" (I-17, BC-21). ≈ +3 / −1 | single-dev |
| E-11 | `/home/alan/Programs/singbox-cli/README.md` | edit | `### Diagnose the install` (`:256-278`): the count word `seven` → `nine`, two new table rows (IPv6 (AAAA), File permissions) and the amended text of rows 2/3/6, the "all seven sections" sentence, and the exit-status table's `1` / `2` cause lists. | single-dev |
| E-12 | `/home/alan/Programs/singbox-cli/README.zh-CN.md` | edit | the line-for-line mirror of E-11. | single-dev |
| E-13 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | one entry at the top of `### 新增` under `## [Unreleased]`, in Chinese (FR-14). | single-dev |
| E-14 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | the reusable-utility inventory changes, so FR-14's condition fires: a row for `_aaaa_rule()`, `EGRESS_HOST` folded into the `_egress_ip()` row, `RULESET_STALE_DAYS` named on the `_age_text()` row as its one consumer, and the `# Commands` row's "seven probes" → "nine probes". | single-dev |
| E-15 | `…/docs/features/doctor-extended-checks/03_GATE_REVIEW.md` | new | stage 3 output. (This stage's own `02_SOLUTION_DESIGN.md` + `02_RATIONALE.md` are already written.) | single-dev |
| E-16 | `…/docs/features/doctor-extended-checks/04_DEVELOPMENT.md` | new | stage 4 output; carries probe **P-2**'s verbatim observation (K-20). | single-dev |
| E-17 | `…/docs/features/doctor-extended-checks/05_CODE_REVIEW.md` | new | stage 5 output. | single-dev |
| E-18 | `…/docs/features/doctor-extended-checks/06_TEST_REPORT.md` | new | stage 6 output; carries the fixture sources (never committed to the tree). | single-dev |
| E-19 | `…/docs/features/doctor-extended-checks/07_DELIVERY.md` | new | stage 7 output. | single-dev |
| E-20 | *(schema gap, no file)* | — | `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` (R-37, fourth confirmation), so `## BC-16 probe and ruling`, `## Smaller alternative rejected` (rule 85) and `## Requirement coverage` fit no declared shape. Recorded as a gap rather than invented into an existing section. | single-dev |

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `bin/sc` `# Rule-set constants` | `RULESET_STALE_DAYS = 60` | THE staleness threshold. Read in **exactly one** place, `_doctor_rulesets()`, as `time.time() - mtime >= RULESET_STALE_DAYS * 86400`. 60 is strictly greater than the longest preset cadence `sc update-interval` offers (`monthly`), so a working auto-update never trips it. Not derived from `settings["update_interval"]` and not per-rule-set. |
| I-2 | `bin/sc`, above `_egress_ip()` | `EGRESS_HOST = "api.ipify.org"`; `_egress_ip()` requests `"https://" + EGRESS_HOST` | THE one home of the name this project resolves. Two consumers: `_egress_ip()`'s URL and the DNS row's query. The composed request URL, the `timeout=8` and the decode stay byte-identical, so `sc status` and `sc doctor` still cannot report different egress addresses. |
| I-3 | `bin/sc` `# Config composition`, above `_dns_overlay()` | `_aaaa_rule(suppress) -> {"action": "predefined", "rcode": "NOERROR", "query_type": [28, 64, 65] \| [64, 65]}` | THE one place that rule dict is spelled. `_dns_overlay()` returns `{"dns": {"rules": {"$prepend": [_aaaa_rule(ipv6_decision()[1])]}}}` and is otherwise unchanged — same keys, same order, same values, so `config.json`'s bytes are unchanged in both decisions. Pure: no I/O, no print, never raises. `sc doctor` consumes it to ask "does the document carry this decision", which is a membership test and never a second derivation. |
| I-4 | `sc doctor` S2 rows | per rule-set: `[<class>] <filename>: {reason}, {size} bytes, {age}` · `{reason}, size unavailable, {age}` · stale ⇒ `{reason}, {size} bytes, {age} — run `sc update-rules` to refresh` | `{age}` is `_age_text(mtime)` over the **same** 6-tuple element the row's `{size}` came from; no `os.stat`, no `getmtime`, no second timestamp source. A row is stale iff `status == "usable"` **and** `mtime is not None` **and** `time.time() - mtime >= RULESET_STALE_DAYS * 86400`; a stale row is PROBLEM and makes the section summary PROBLEM by the same assignment an unusable row already uses. Clock skew ⇒ never stale (the difference is negative). No new row; the summary row's `{n}/{total} usable` text is unchanged. |
| I-5 | `sc doctor` S3, second row | `[<class>] config drift: <value>`, printed after `configuration` and before `sing-box check` on **every** path including both early returns | Value is `_drift_state()`'s three states and nothing else: `True` ⇒ PROBLEM `changed since sc generated it — keep the change in {override}, then run `sc reload`` (`override=OVERRIDE_PATH`); `False` ⇒ OK `matches what sc last generated`; `None` ⇒ UNKNOWN `no record of what sc last generated`. The judgement is not re-derived, not overridden and not widened (Q-9); no second digest of `config.json` is taken. |
| I-6 | `bin/sc` `# doctor`; section `IPv6 (AAAA)` | `_doctor_ipv6() -> [(cls, "IPv6 (AAAA)", value)]` — exactly one row | `ipv6_decision()` is called **once** per run. `sentence is None` (detection failed) ⇒ UNKNOWN `cannot determine this host's IPv6 addresses`, and the one stderr line the reader wrote stays outside the row grammar. Otherwise the document is read **once** — `CFG_PATH.read_text()` + `json.loads` under `except (OSError, ValueError)` plus an `isinstance(doc, dict)` guard — and an unreadable, absent or non-object/unparseable document ⇒ UNKNOWN `cannot read {path}: {e}` (existing key), never PROBLEM. Otherwise `carries = isinstance(rules, list) and all(r in rules for r in _dns_overlay()["dns"]["rules"]["$prepend"])` over `doc["dns"]["rules"]`: `True` ⇒ OK `{decision}; config.json carries this decision`; `False` ⇒ PROBLEM `{decision}; config.json does not carry this decision — run `sc reload` to regenerate it`. `{decision}` is `ipv6_decision()`'s already-translated `sentence` — no fifth decision string is written. |
| I-7 | `sc doctor` S6, third row | `[<class>] node delays: <value>` | Reached only on the branch where `clash_api("GET", "/configs")` answered; every other branch ⇒ UNKNOWN with no request (I-8). `delays, current = stored_delays(port=port)` — the reader's shape is not widened and no fresh measurement is requested or claimed. `load_nodes()` under `except (OSError, ValueError, TypeError, KeyError)` ⇒ UNKNOWN `cannot read {path}: {e}` naming `NODES_PATH` (BC-14). No nodes ⇒ OK `no nodes configured`. `n = len([node tags present in delays])`, `total = len(nodes)`: `n == 0` ⇒ PROBLEM `0/{total} nodes carry a stored delay — either no probe has completed yet or every node is failing; see `sc ls``; `n > 0` ⇒ OK `{n}/{total} nodes carry a stored delay (history, not a fresh measurement); auto-select is on {current}`, with `current or t("(none)")`. One row; never a per-node table (Q-10). |
| I-8 | `sc doctor` S6, fourth row | `[<class>] DNS lookup: <value>`; request `GET /dns/query?name=<EGRESS_HOST>&type=A` through `clash_api(..., port=port)` | Issued **only** when `/configs` answered on a port read from `_saved_clash_port()`. No port recorded ⇒ UNKNOWN `not probed — no port recorded` (existing key) for this row and I-7's; `/configs` did not answer (service stopped, port dead, API hung) ⇒ UNKNOWN `not probed — the Clash API did not answer` for both, and **no request is issued** (BC-10…BC-12). Elapsed is `int((time.monotonic() - t0) * 1000)` measured around the one call. `answer is None` ⇒ PROBLEM `no answer for {name} after {ms} ms — try another node with `sc use <n>``. An object carrying a non-empty `Answer` list ⇒ OK `{name} resolved in {ms} ms, through the running sing-box`. An object without one ⇒ PROBLEM `{name} returned no records after {ms} ms — try another node with `sc use <n>``. No second exception envelope, no retry, no sleep, and **no row states a timeout value or a total wall-clock bound** (NFR-1 / R-35). The `Answer` key is confirmed by probe P-2 before any code is written (K-20). |
| I-9 | `bin/sc` `# doctor`; section `file permissions` | `_doctor_permissions() -> [(cls, "file permissions", summary)] + quoted lines` | `CFG_DIR.stat()` (never `lstat`, so a directory that is itself a link is judged by its target) → `FileNotFoundError` ⇒ one UNKNOWN row `no directory at {path}` and **no `mkdir`**; other `OSError`, or an `OSError` from `sorted(CFG_DIR.iterdir())` ⇒ one UNKNOWN row `cannot read {path}: {e}` (BC-18). Findings: the directory itself when `mode & 0o022`; every entry whose `lstat()` says regular file, name ≠ `settings.json`, `mode & 0o077` (T-13's own predicate); entries that are symlinks are **not** followed and their mode is never printed; sub-directories are never descended (BC-19). Exactly one summary row: no findings and no links ⇒ OK `no file grants access to group or other, and the directory is not group- or other-writable`, **naming no path** (BC-20); any wide mode ⇒ PROBLEM `{n} path(s) grant access to group or other — run the command shown for each`; links only ⇒ UNKNOWN `{n} path(s) could not be judged — see below`. Detail lines are `cls is None` quoted lines, `"    " + t(...)`: `{path} is mode {mode} — run: {cmd}` with `mode = "%03o" % (st_mode & 0o777)` and `cmd` = `chmod {CRED_MODE as %03o} {path}` for a file / `chmod go-w {path}` for the directory, and `{path} is a symbolic link; sc never creates one here — check it with: ls -l {path}`. The list is capped at `DOCTOR_MSG_LINES` and the overflow is the existing `... {n} more line(s) not shown` key (BC-21). No byte of any file's **content** is read. |
| I-10 | `TRANSLATIONS["zh"]`, rule-set group | `"{reason}, {size} bytes, {age}"`→`"{reason}，{size} 字节，{age}"` · `"{reason}, size unavailable, {age}"`→`"{reason}，大小未知，{age}"` · ``"{reason}, {size} bytes, {age} — run `sc update-rules` to refresh"``→``"{reason}，{size} 字节，{age} —— 运行 `sc update-rules` 更新"`` | Replaces the two dead keys (E-4). The zh separator is the full-width `，`, matching the group's existing keys. |
| I-11 | `TRANSLATIONS["zh"]`, doctor group | `"config drift"`→`"配置改动"` · `"matches what sc last generated"`→`"与 sc 最近一次生成的内容一致"` · ``"changed since sc generated it — keep the change in {override}, then run `sc reload`"``→``"自 sc 生成以来已被修改 —— 请把改动写入 {override}，再运行 `sc reload`"`` · `"no record of what sc last generated"`→`"没有 sc 最近一次生成内容的记录"` | 1 label + 3 values. |
| I-12 | `TRANSLATIONS["zh"]`, doctor group | `"IPv6 (AAAA)"`→`"IPv6（AAAA）"` · `"{decision}; config.json carries this decision"`→`"{decision}；config.json 与该决策一致"` · ``"{decision}; config.json does not carry this decision — run `sc reload` to regenerate it"``→``"{decision}；config.json 与该决策不一致 —— 运行 `sc reload` 重新生成"`` · `"cannot determine this host's IPv6 addresses"`→`"无法确定本机的 IPv6 地址"` | 1 label + 3 values. The four decision sentences themselves are `ipv6_decision()`'s existing keys and are **not** duplicated. |
| I-13 | `TRANSLATIONS["zh"]`, doctor group | `"node delays"`→`"节点延迟"` · `"no nodes configured"`→`"未配置任何节点"` · `"{n}/{total} nodes carry a stored delay (history, not a fresh measurement); auto-select is on {current}"`→`"{n}/{total} 个节点有已记录的延迟（历史值，非实时测量）；自动选择当前走 {current}"` · ``"0/{total} nodes carry a stored delay — either no probe has completed yet or every node is failing; see `sc ls`"``→``"0/{total} 个节点有已记录的延迟 —— 可能探测尚未完成，也可能所有节点都不通；请查看 `sc ls`"`` | 1 label + 3 values. |
| I-14 | `TRANSLATIONS["zh"]`, doctor group | `"DNS lookup"`→`"DNS 解析"` · `"{name} resolved in {ms} ms, through the running sing-box"`→`"{name} 用时 {ms} 毫秒解析成功（经由正在运行的 sing-box）"` · ``"{name} returned no records after {ms} ms — try another node with `sc use <n>`"``→``"{name} 在 {ms} 毫秒后返回了空结果 —— 可用 `sc use <编号>` 换一个节点试试"`` · ``"no answer for {name} after {ms} ms — try another node with `sc use <n>`"``→``"{ms} 毫秒内没有收到 {name} 的解析结果 —— 可用 `sc use <编号>` 换一个节点试试"`` · `"not probed — the Clash API did not answer"`→`"未探测 —— Clash API 未响应"` | 1 label + 4 values. The last key serves both I-7 and I-8. |
| I-15 | `TRANSLATIONS["zh"]`, doctor group | `"no usable answer from {addr}"`→`"{addr} 未返回可用响应"` | FR-9 / R-32: replaces `"no answer within the 3s timeout"`, which is deleted. `{addr}` is the `"127.0.0.1:%d"` the row above already prints. States no cause. |
| I-16 | `TRANSLATIONS["zh"]`, doctor group | `"file permissions"`→`"文件权限"` · `"no file grants access to group or other, and the directory is not group- or other-writable"`→`"没有文件对同组或其他用户开放，目录本身也不可被同组或其他用户写入"` · `"{n} path(s) grant access to group or other — run the command shown for each"`→`"{n} 个路径对同组或其他用户开放 —— 请逐条执行下面给出的命令"` · `"{n} path(s) could not be judged — see below"`→`"{n} 个路径无法判断 —— 详见下方"` · `"{path} is mode {mode} — run: {cmd}"`→`"{path} 的权限是 {mode} —— 请运行：{cmd}"` · `"{path} is a symbolic link; sc never creates one here — check it with: ls -l {path}"`→`"{path} 是符号链接，sc 不会在此创建符号链接 —— 请用 ls -l {path} 检查"` · `"no directory at {path}"`→`"目录不存在：{path}"` | 1 label + 6 values. |
| I-17 | `bin/sc` `DOCTOR_SECTIONS` | `binary, rule-sets, configuration, **IPv6 (AAAA)**, service, TUN interface, Clash API, egress IP, **file permissions**` | Still THE one ordering table, still read only by `cmd_doctor`. Two insertions, no reordering of the seven existing entries. |
| I-18 | `sc doctor` report order | drift ≺ `sing-box check` · AAAA ≺ DNS · DNS ≺ egress · Clash rows ≺ node delays · node delays ≺ egress · every permission row last | Satisfied by I-17 plus row order **inside** `_doctor_config()` (configuration, drift, check) and `_doctor_clash()` (port, responding, node delays, DNS). No probe prints another section's rows and no cross-section state is passed. |

## Constraints

**K-1** — The implementer adds **no** `try`/`except` around either new `clash_api()` call and no second exception envelope anywhere: both callers read its `None` and nothing else (AC-S2, T-18's ruling).

**K-2** — The implementer computes the node-delay row and the DNS row **only** on the branch where `clash_api("GET", "/configs", port=port)` returned non-`None`; on the no-port branch and on the no-answer branch both rows are UNKNOWN and **no** request and no lookup is issued (BC-10, BC-11, BC-12).

**K-3** — The implementer derives the staleness verdict from the **same** `mtime` element the row renders through `_age_text()`; `os.stat`, `Path.stat`, `getmtime` and `st_size` appear nowhere in the diff (AC-S1, AC-S2, T-19 K-17).

**K-4** — The implementer reads `RULESET_STALE_DAYS` in exactly one place and derives no threshold from `settings["update_interval"]` (AC-S9, Q-3).

**K-5** — The implementer moves the predefined-rule literal into `_aaaa_rule()` without changing a key, a value or their order, and proves `config.json`'s bytes unchanged in both decisions before and after (V-11); `ipv6_decision()` itself is not edited (out-of-scope 9).

**K-6** — The implementer calls `ipv6_decision()` **once** per `sc doctor` run, so BC-8's and BC-9's stderr line appears at most once and `/proc/net/if_inet6` is read at most once.

**K-7** — The implementer reads `config.json` in the AAAA probe exactly once, guarded by `except (OSError, ValueError)` — `UnicodeDecodeError` is a `ValueError`, not an `OSError` — plus an `isinstance(doc, dict)` guard, and takes **no** second digest of the file (BC-6, BC-7, AC-S2).

**K-8** — The implementer's new code reaches no writer: no `_init_files()`, `_resolve_clash_port()`, `generate_config()`, `reload_or_restart()`, `restart_service()`, `save_nodes()`, `save_settings()`, `_write_private()`, `_record_generated()`, no `mkdir`, and no `clash_api()` call with a method other than `GET` (FR-13, AC-S4).

**K-9** — The implementer reads each directory entry's metadata with `lstat()`, never follows a symlink, never descends into a sub-directory, and never prints a symlink's own mode — so no planted link's target mode can appear in the report (BC-19, AC-B13).

**K-10** — The implementer excludes exactly one name, `settings.json`, and writes no filename pattern, no backup-name heuristic and no second exclusion list (Q-4, R-10).

**K-11** — The implementer uses `mode & 0o077` for a regular file and `mode & 0o022` for the directory, spells the file's fix command from `CRED_MODE` (`"chmod %03o %s"`), and uses `chmod go-w` for the directory so no directory-mode constant is invented — R-11's second half stays open (Q-5, out-of-scope 2).

**K-12** — The implementer prints **exactly one** row from `_doctor_permissions()` on a clean host and caps the detail lines with `DOCTOR_MSG_LINES` plus the existing `... {n} more line(s) not shown` key (BC-20, BC-21, NFR-3).

**K-13** — The implementer keeps `_egress_ip()`'s request URL, its `timeout=8` and its decode byte-identical while sourcing the host name from `EGRESS_HOST` (Q-13).

**K-14** — The implementer ships every new user-facing string as an English sentence used as the key **and** a `TRANSLATIONS["zh"]` entry with the same placeholder set; no new zh string contains `失败`; no new `ls.`-style namespaced key is added (AC-S5, R-19, NFR-4).

**K-15** — The implementer states no timeout value and no total-wall-clock bound in any row; the DNS row reports a **measured** elapsed time only (NFR-1, R-35).

**K-16** — The implementer changes no existing timeout constant, no marker, no outcome class, no `DOCTOR_EXIT` value, no `_doctor_print()` shape and no existing row's wording other than FR-9's (AC-S6, out-of-scope 8, 10).

**K-17** — The implementer **deletes** the three keys that become dead rather than leaving them in the table.

**K-18** — Every later stage honours the safety floor: never write `/etc/sing-box/` or `/var/lib/sing-box`, never drive `_init_files()`, never invoke `/usr/local/bin/sc`, never start/stop/restart/reload the live service, never write a unit file. The **only** admissible live-host action is a read-only `GET` against the Clash API on the persisted port (probes P-2/P-3), and no credential byte from the live host is printed into any stage document.

**K-19** — Every fixture repoints all **eight** path constants into a `mkdtemp()` root **with an assertion that each resolves inside it**, sets `sc.LANG` explicitly, records the stub Clash port in the fixture's **own** `settings.json`, never drives `main()`, and — for any step whose expected observable depends on `stored_delays()` issuing a request — makes `is_running()` true by replacing `sc.subprocess.run` with a stub that never execs `systemctl`. Without that last clause the whole node-delay matrix degrades to "no request issued" on candidate **and** control.

**K-20** — The implementer runs probe **P-2** before writing the DNS row and records its verbatim body shape in `04_DEVELOPMENT.md`. A body that contradicts I-8 (no `Answer` key, or a non-object) is a **design defect routed back to stage 2**, never a developer-side substitution.

## Frozen set

| path | why frozen |
|---|---|
| `bin/sc` `ruleset_state()`, `ruleset_states()`, `_status_view()`, `_age_text()`, `_status_text()` | T-19's contract; T-20 consumes them unchanged (K-17 of T-19, AC-S1). |
| `bin/sc` `ipv6_decision()`, `_ipv6_setting()`, `_global_ipv6_iface()` | Out-of-scope 9; the AAAA row is a consumer, never a second derivation. |
| `bin/sc` `stored_delays()`, `is_running()`, `clash_api()` | Out-of-scope 5/9 and T-18's envelope: no widened return shape, no second envelope, no new request kind. |
| `bin/sc` `_drift_state()`, `_config_digest()`, `_record_generated()`, `_warn_drift()` | Out-of-scope 9 and Q-9: the judgement is read, never changed; `_warn_drift()` keeps its own display site. |
| `bin/sc` `_write_private()`, `CRED_MODE`'s value | T-13's construction; this task opens no write path (out-of-scope 11). |
| `bin/sc` `CONFIG_BASE`, `_runtime_overlay()`, `_telemetry_overlay()`, `_compose()`, `_merge()`, `generate_config()` | T-14…T-17 differentials pin them; only `_dns_overlay()`'s body moves, byte-neutrally (K-5). |
| `bin/sc` `cmd_status()`, `cmd_ls()`, `cmd_config()`, `cmd_ipv6()` | Out-of-scope 3/4; R-33, R-34, R-38 and R-19 stay open with their owners. |
| `bin/sc` `main()`'s `if args.cmd in ("doctor", "config")` arm | FR-13 / AC-S4; the `config` arm is frozen too. |
| `bin/sc` `DOCTOR_OK/UNKNOWN/PROBLEM`, `DOCTOR_MARK`, `DOCTOR_EXIT`, `_doctor_print()`, `_plain()`, `_doctor_run()` | FR-10 / AC-S6: grammar, markers and exit mapping unchanged. |
| `bin/sc` the five `ls.*` keys | Out-of-scope 3 (R-19). |
| `install.sh` (`sweep_credential_modes()` included), `uninstall.sh`, `systemd/*` | Out-of-scope 2: the writer counterpart and R-11's second half stay open. |
| `.harness/scripts/*`, `.harness/scripts/baseline.json` | No new `verify_all` step; the count deltas stay at zero. |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | E-1, E-2, E-3 | none — all three are behaviour-neutral: `EGRESS_HOST` reproduces the same URL, `RULESET_STALE_DAYS` has no reader yet, `_aaaa_rule()` emits the same dict. `verify_all` B.1 must pass, and V-11's byte comparison of `config.json` must be clean **before** any row is written. | revert three hunks; nothing depends on them. |
| 2 | E-4 (I-10, I-11) | order 1 landed. | revert; the old keys return with the code that reads them. |
| 3 | E-5, E-6 | order 2 landed. First user-visible change: AC-B1, AC-B2 become observable. | revert two hunks; the rest of the report is untouched. |
| 4 | E-4 (I-12), E-7, E-10 (first insertion) | order 3 landed. AC-B3 becomes observable. | revert; `DOCTOR_SECTIONS` returns to eight entries. |
| 5 | E-4 (I-13, I-14, I-15), E-8 | order 4 landed **and probe P-2 recorded** (K-20). AC-B4, AC-B5, AC-B12 become observable. | revert one function body; the two Clash rows above return to HEAD wording. |
| 6 | E-4 (I-16), E-9, E-10 (second insertion) | order 5 landed. AC-B6, AC-B7, AC-B13 become observable. | revert; the report loses its last section only. |
| 7 | E-11, E-12, E-13, E-14 | orders 3-6 landed — the docs describe shipped behaviour, in the same commit (FR-14). | revert with the code. |

No data migration, no on-disk format change, no new file, no new setting, no new flag, no new exit
value: `settings.json`, `nodes.json`, `config.json`, `.config.sha256` and `rules/*.srs` are untouched,
so an upgrade needs no `sc reload` and a downgrade needs no repair. The one backwards-compatibility
consequence is stated in BC-22 and is deliberate: a host that is working but stale, drifted, wide-moded
or carrying an out-of-date AAAA decision now exits **1** where it exited **0**, through the unchanged
mapping. Consumers of `sc doctor`'s status are the user's own scripts; `install.sh` does not run it.

## Out of scope

- Everything in `01_REQUIREMENT_ANALYSIS.md` `## Out of scope` items 1-12, unchanged, and restated by the frozen set and K-8…K-16.
- Any repair of a wide mode, a stale rule-set, a drifted document or an out-of-date AAAA decision — including a `--fix` flag, an offer, or a prompt.
- `install.sh`'s `sweep_credential_modes()` and the deliberate setting of the configuration directory's mode (R-11's second half).
- R-38 (the `sc status` zh separator), R-33, R-34, R-19, R-17, R-29's settings-I/O family and R-21 (the delay map keyed by API tags): all untouched, all still open with their existing owners.
- Any second consumer of `RULESET_STALE_DAYS` (`sc status`, `sc update-rules`, a warning at generation time), and any age-derived behaviour outside the report.
- Any change to what `/dns/query` is asked (one name, type A, one query per run) and any second endpoint constant.
- Machine-readable output, per-section flags, a quiet mode, historical trending.

## Verification plan

Every `[B]` step runs in a redirected fixture built with `docs/dev-map.md`'s module-load recipe under
**K-19**, and drives `sc.cmd_doctor(None)` directly — never `main()`. K-18 binds every step.

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| P-1 | *(done at this stage, first-hand, read-only)* `Grep` over `/usr/local/bin/sing-box` for `/providers/rules`, `/dns/query`, `clashapi.queryDNS`, `clashapi.dnsRouter`, `invalid query type`, `TCRDRA`. | See `## BC-16 probe and ruling`: 1, 0, 1, 1, 1, 1. | BC-16 |
| P-2 | **Stage 4, before E-8 is written.** Read-only `GET` on loopback against the persisted port: `curl -s "http://127.0.0.1:$(python3 -c 'import json;print(json.load(open("/etc/sing-box/settings.json"))["clash_api_port"])')/dns/query?name=api.ipify.org&type=A"`. Repeat once with a name from `TELEMETRY_NAMES`. | A JSON **object**; a non-empty `Answer` array for the first; a rejected/empty answer for the second, which is what proves the route runs the running install's **rule chain** rather than a bypass. Body pasted verbatim into `04_DEVELOPMENT.md`; contradiction ⇒ back to stage 2 (K-20). | BC-16, AC-B5 |
| P-3 | Stage 4/6, read-only: `GET /dns/query?name=<a name that does not exist>&type=A` on the same port. | Either a JSON object with no `Answer` or `None` after a bounded read — records which, so the PROBLEM branch's wording is checked against a real body rather than a guess. | BC-15 |
| V-1 | Fixture: four `.srs`, all usable, one `os.utime`'d to now − 90 d. | That file's row is PROBLEM, names its age (`90 days ago` / `90 天前`) and `sc update-rules`; the section summary is PROBLEM; the other three rows are OK and carry no next step. Control: same fixture at a current mtime ⇒ every row OK, summary OK, no `update-rules` literal anywhere. | AC-B1, BC-3 |
| V-2 | Fixture: one `.srs` absent, one a directory; one usable file `os.utime`'d to now + 1 h. | The first two read `last update unknown` with no digit and are never called stale; the skewed one reads `0 seconds ago` and is OK. | BC-1, BC-2 |
| V-3 | Fixture: `.config.sha256` holding a digest ≠ the `config.json` present. | Drift row PROBLEM, names `override.json` and `sc reload`, printed **after** the `configuration` row and **before** the `sing-box check` row. Controls: matching digest ⇒ OK naming no path; record absent ⇒ UNKNOWN; record present, non-empty, not a digest ⇒ PROBLEM (Q-9). | AC-B2, BC-4, BC-5 |
| V-4 | Fixture: `config.json` suppressing AAAA while the repointed `IF_INET6_PATH` shows a global address — and the mirror image (`ipv6: off` in settings with a document that does not suppress). | Both runs: AAAA row PROBLEM naming `sc reload`. Control: a document agreeing with the decision ⇒ OK, no command. | AC-B3 |
| V-5 | Fixture: `config.json` absent; then present but truncated JSON; then valid JSON that is not an object; then `IF_INET6_PATH` unreadable. | AAAA row UNKNOWN in all four; never PROBLEM; the drift row and the configuration row still print; at most **one** IPv6 stderr line per run. | BC-6, BC-7, BC-8, K-6 |
| V-6 | Fixture: stub HTTP server on a **proved-free** port recorded in the fixture's `settings.json`, answering `/configs` with `{}` and `/proxies` with entries carrying no `history`; `is_running()` stubbed true. | Node-delay row PROBLEM, names `sc ls` and both admissible causes; the run still prints every section. Control: entries carrying a `delay` ⇒ OK with `{n}/{total}` and the auto-select target. | AC-B4, BC-13 |
| V-7 | Same rig, `/dns/query` answered (a) with a body carrying `Answer`, (b) with an object carrying none, (c) not at all (the stub sleeps past the socket timeout). | (a) OK with a measured ms; (b) PROBLEM "returned no records"; (c) PROBLEM "no answer after {ms} ms". No row contains `3s`, `3 秒`, "timeout" or any wall-clock promise. Stub bodies copied from P-2/P-3. | AC-B5, BC-15, NFR-1 |
| V-8 | Fixture with a port nothing listens on, `is_running()` stubbed **true**; and a second run with `settings.json` carrying no `clash_api_port`. | Run 1: node-delay and DNS rows both **UNKNOWN**, never PROBLEM, and the stub log shows no `/proxies` and no `/dns/query` request. Run 2: all four Clash-section rows UNKNOWN, no request at all. | AC-B12, BC-10, BC-11, BC-12 |
| V-9 | Fixture: `config.json.bak-2026-08-01` at 0644, `nodes.json` at 0600, `settings.json` at 0644, the directory at 0755; then a second run with the directory at 0777; then a run with a symlink to a 0777 file outside the root; then 12 offending files. | Run 1: PROBLEM naming the `.bak` path, `644` and `chmod 600 <path>`; `settings.json` absent from the output. Run 2: the directory named with `777` and `chmod go-w`. Run 3: the link reported as a symlink and the string `777` absent from stdout. Run 4: 5 detail lines plus `... 7 more line(s) not shown`. | AC-B6, AC-B7, AC-B13, BC-21, Q-4 |
| V-10 | Fixture: directory absent; then directory present but mode 0000 for a non-root user. | UNKNOWN row naming the path in both; the directory still does not exist after run 1 (`find` snapshot). | BC-18, AC-B10 |
| V-11 | `generate_config()` in a fully redirected fixture at HEAD and after E-3, under `ipv6: on` and `ipv6: off`; byte-compare the two `config.json` pairs. | Byte-identical in both decisions. | K-5, out-of-scope 9 |
| V-12 | Wholly healthy fixture: usable current rule-sets, matching drift record, agreeing AAAA decision, stub API answering `/configs`, `/proxies` with delays and `/dns/query` with an `Answer`, all files 0600, directory 0755. Row count diffed against a HEAD run on the same fixture. | Exit 0; every new row OK; **+5** rows exactly; no new row names a path or a next step; no `[PROBLEM]`, no `[UNKNOWN]`. This is the adversary of V-1…V-9. | AC-B8, NFR-3 |
| V-13 | Each new probe forced to fail independently (record removed; API port closed; directory unlistable; `IF_INET6_PATH` unreadable; `nodes.json` malformed; `nodes.json` absent). | Every section label still printed, run terminates normally, exit ∈ {1,2}, no traceback anywhere. | AC-B11, BC-14, BC-23 |
| V-14 | Full snapshot (existence, size, mtime, sha256, mode) of the fixture root before and after a run, plus raisers over `_init_files` / `_resolve_clash_port` / `_write_private` / `save_settings` and a positive control proving a raiser fires for `sc use`. | Identical snapshots; no raiser fires; the positive control does fire. | AC-B10, AC-S4, FR-13 |
| V-15 | Repeat V-1…V-10 with the fixture's `settings.json` carrying `"lang": "zh"` **and** `sc.LANG = "zh"`; grep every capture for `失败`, for an untranslated key and for an ASCII conclusion. | Every new row, conclusion and next step in Chinese, markers included; no `失败`; no key text. | AC-B9, AC-S5, BC-24 |
| V-16 | Static sweep of the diff: `st_size`, `os.stat(`, `.stat()`, `getmtime`, `hashlib`, a second `except` around `clash_api`, a second `ipv6_decision()` call site inside the doctor block, `RULESET_STALE_DAYS` readers, `_age_text` call sites; plus a call-graph read of all five new/edited probes; plus `git diff --numstat` and `verify_all`. | One threshold reader; no second digest, timestamp, envelope or AAAA decision; no writer reachable; diff limited to E-1…E-14 plus this task's own stage docs and `docs/batches/**`; `verify_all` PASS with unchanged counts. | AC-S1, AC-S2, AC-S3, AC-S6, AC-S7, AC-S9 |
| V-17 | Every capture piped to a file: byte-scan for `\r` and ESC; per-row flush check by reading a truncated capture from a killed run. | No `\r`, no ESC; rows appear in order as they are produced. | BC-25 |
| V-18 | Grep every fixture capture for a planted credential literal placed in `config.json`, `nodes.json` and `override.json`. | Absent from stdout in every run. | AC-S8, out-of-scope 12 |
| V-19 | AC-B14: `sc doctor` as root on the live host, the shipped invocation. | **Not obtainable inside this pipeline** (K-18, and the R-31/R-41 precedent): report **BLOCKED and file it**; never substitute an artifact read. | AC-B14 |

## BC-16 probe and ruling

*(First unit of the E-20 schema gap.)*

**Probe P-1, run first-hand at this stage** with the `Grep` tool (ripgrep) against the installed
binary. It is read-only, touches no service and prints no credential byte. I hold no `Bash` tool, so
**no live HTTP request was issued by me**; P-2 below is specified for stage 4 and its result is
binding under K-20.

| pattern | matches in `/usr/local/bin/sing-box` | what it establishes |
|---|---|---|
| `/providers/rules` | **1** | Calibration control: reproduces T-10's independently measured count, so the tool really is reading the installed binary's string table. |
| `/dns/query` | **0** | Negative control that stops a naive conclusion: the route is **not** a single literal. |
| `clashapi.queryDNS` | **1** | The Clash-API DNS query **handler** is present in the symbol table. |
| `clashapi.dnsRouter` | **1** | Its router is present too. Go's linker drops unreachable functions, so a present `dnsRouter` is a **mounted** one — which is also why `/dns/query` is absent as a literal: the path is composed from a `Mount("/dns", …)` and a `Get("/query", …)`. |
| `invalid query type` | **1** | The handler's own argument-validation string, i.e. the clash-derived `queryDNS` implementation and not a namesake. |
| `TCRDRA` | **1** | The packed literal blob of the response map's keys (`"TC","RD","RA","AD","CD"`) — the Google-DoH-shaped JSON object whose records live under `Answer`. |

**Ruling: a bounded lookup mechanism exists and FR-6 ships.** `GET /dns/query?name=…&type=A` through
the existing `clash_api()` satisfies all three clauses of BC-16:

1. **It exists** — established above.
2. **The caller can bound it** — `clash_api()` sets `timeout=3` on every socket operation of the one
   request; nothing about the mechanism is unbounded in the way `socket.getaddrinfo` is (BC-17). The
   report claims only a **measured** elapsed time, never a total (NFR-1 / R-35 / K-15).
3. **It reaches the running install's resolver** — the route asks the running process's own DNS router,
   which is the resolver `config.json` configures, rather than the host stub or a bypass. P-2's second
   half discriminates this empirically: a `TELEMETRY_NAMES` entry must come back rejected, which only
   the install's rule chain can do.

It is also strictly better than every host-side alternative considered: it needs no DNS wire-format
encoder, no second endpoint, no UDP socket, and — unlike a hijacked host lookup — it cannot silently
measure the host's own resolver on a run where the TUN device is down.

## Smaller alternative rejected

*(Second unit of the E-20 schema gap. Rule 85: the burden of proof is on the larger design.)*

| the smaller design | what the extra code buys |
|---|---|
| **Drop FR-6 under BC-16** — five checks, no DNS row, ~25 fewer lines and 5 fewer strings. It was a legitimate outcome and the probe was run to decide it honestly. | The probe found the mechanism, so the row costs one `clash_api()` call on a seam that already exists. It buys the only row in the report that catches R-23: a node that accepts and never answers keeps its stored delay, so the node-delay row reads OK, the Clash row reads OK, and **only the egress row fails** — leaving the reader with an effect and no cause. That is exactly the failure `sc doctor` exists to prevent. |
| **Six new `DOCTOR_SECTIONS` entries, one per fact** — the literal reading of "six checks ≈ six table entries". | Rejected as *larger and wrong*, not smaller. Drift must print **between** the `configuration` row and the `sing-box check` row (FR-12), which no separate section can do. The node-delay and DNS rows must know whether the Clash API answered (BC-12); as separate sections each would have to ask again — a second request and a second opinion of a fact `_doctor_clash()` already holds (AC-S2). The design lands at 2 new entries and 5 new rows because the causal order and the no-second-opinion rule *both* point there. |
| **No `_aaaa_rule()`** — index `_dns_overlay()["dns"]["rules"]["$prepend"][0]` from the probe (≈5 lines less). | The probe needs `sentence` *and* the rule. Without the extraction it calls `ipv6_decision()` once itself and once inside `_dns_overlay()`, so BC-9's stderr warning prints **twice** and `/proc/net/if_inet6` is read twice in one run; and a positional `[0]` silently checks the wrong rule the day a second one is prepended. The extraction is 4 lines of pure function and removes both. |
| **No `_age_seconds()` helper** — compare `time.time() - mtime` inline in `_doctor_rulesets()` while `_age_text(mtime)` renders the same fact. **This smaller option is the one taken.** | The helper would give "how old, in seconds" one home, but rule 85's counter-rule asks for the future edit it prevents and there is none today: no second consumer of the number exists, `_age_text()`'s contract must not widen (T-19 K-17), and both readings come from the same `mtime` the single reader produced, so no second opinion is possible. Taken as the smaller design, deliberately. |
| **No `EGRESS_HOST`** — spell `"api.ipify.org"` in the DNS row (1 line less). | Two homes for one literal, which is what Q-13 forbids and what makes the DNS row and the egress row a causal pair rather than two coincidental probes. |
| **One PROBLEM row per offending path** instead of a summary row plus quoted lines. | Rejected: the report's size would scale with the directory's contents on a broken host (NFR-3 / BC-21), and the section's class would have to be re-derived per row. The quoted-line list is the shape `_doctor_config()` already uses for a multi-line quotation, with the same constant. |
| **Reuse `install.sh`'s `sweep_credential_modes()` predicate by shelling out to it.** | Rejected as larger and cross-language: the predicate is `mode & 0o077`, six characters of Python; what the installer owns is the *chmod*, which is out of scope here. Reporting may enumerate where a writer may not (Q-4). |

## Requirement coverage

*(Third unit of the E-20 schema gap.)*

| id | where it is satisfied |
|---|---|
| FR-1, FR-2 | I-1, I-4, K-3, K-4; E-5. |
| FR-3 | I-5, E-6; the judgement is `_drift_state()`'s (Q-9). |
| FR-4 | I-3, I-6, K-5…K-7; E-3, E-7. |
| FR-5 | I-7, K-2; E-8. |
| FR-6 | `## BC-16 probe and ruling`, I-2, I-8, K-1, K-2, K-13, K-15, K-20; E-1, E-8. |
| FR-7 | I-9, K-9…K-12; E-9. |
| FR-8 | I-4 (stale), I-5 (drift), I-6 (AAAA), I-7 (node delays), I-8 (DNS), I-9 (each detail line) — every PROBLEM row this task adds carries its next step inside the row's value text; no fourth tuple element, no new print path (Q-8). |
| FR-9 | I-15; the old key is deleted (K-17). |
| FR-10 | K-16 + the frozen set: grammar, classes, markers and exit mapping untouched. |
| FR-11, FR-12 | I-17, I-18; V-16 reads the table, V-12 asserts the order in one capture. |
| FR-13 | K-8, K-18; V-14. |
| FR-14 | E-11…E-14. |
| BC-1…BC-3 | I-4; V-1, V-2. |
| BC-4, BC-5 | I-5; V-3. |
| BC-6…BC-9 | I-6, K-6, K-7; V-5. |
| BC-10…BC-13 | I-7, I-8, K-2; V-6, V-8. |
| BC-14 | I-7's guard tuple; V-13. |
| BC-15 | I-8; V-7, P-3. |
| BC-16, BC-17 | `## BC-16 probe and ruling`; P-1 run, P-2/P-3 specified. |
| BC-18…BC-21 | I-9, K-9…K-12; V-9, V-10. |
| BC-22 | Unchanged `DOCTOR_EXIT`; `## Migration & edit sequence`'s closing paragraph. |
| BC-23 | `cmd_doctor()`'s existing isolation, untouched; V-13. |
| BC-24 | K-14; V-15. |
| BC-25 | `_doctor_print()`'s existing per-row flush, untouched; V-17. |
| BC-26 | No lock, no retry, no sleep anywhere in the new code; every probe reports what it read. |
| AC-B1…AC-B14, AC-S1…AC-S9 | V-1…V-19 as columned above; **AC-B14 is the one criterion no agent here can discharge** (V-19). |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RS-1 | **NFR-2's literal wording vs FR-4.** The AAAA row performs one `read_text()` + `json.loads` of `config.json` that no existing reader performs (`_drift_state()` reads the bytes for a digest and returns none of them). FR-4 is not implementable without it. Read here as "the design adds no *second* read of a fact an existing reader already returns"; the gate should confirm that reading. | `03_GATE_REVIEW.md` |
| RS-2 | **A host with no init system but a live Clash API reports a false PROBLEM on node delays.** `stored_delays()`'s internal `is_running()` guard returns `False` when neither `SYSTEMD` nor `OPENRC` is set, so the reader returns `({}, None)` even though the API just answered, and the row reads `0/{total}`. Reproducing T-19's RS-2 class. Not fixed here: the alternatives are a second `is_running()` opinion or bypassing the reader, both forbidden. A fixture hits this by construction — hence K-19. | `07_DELIVERY.md` as a follow-up pool row |
| RS-3 | **A document produced by an older build reads as "does not carry this decision".** The AAAA membership test compares against the rule *this* build authors, so a host that upgraded `sc` without running `sc reload` gets a PROBLEM row. The conclusion is true as stated (the document is not what this build would emit) and its next step is the right one, but the row's subject is narrower than its cause. | `03_GATE_REVIEW.md`, then `07_DELIVERY.md` if the gate accepts it |
| RS-4 | **A user override that replaces `dns.rules` wholesale** removes the AAAA rule from the document, so the row reads PROBLEM on a host the user configured deliberately. Honest (the document really does not carry the decision) and unreachable through `$prepend`, the documented idiom. | `07_DELIVERY.md` as a follow-up pool row |
| RS-5 | **R-38 stays open**: `sc status`'s zh rule-set separator is still ASCII while `sc doctor`'s is full-width. This task adds the third and fourth full-width-separator keys (I-10) and still does not touch `cmd_status` (out-of-scope 3). | PM; the next task touching `cmd_status` |
| RS-6 | **Two glossary terms** — **stale rule-set** and **credential directory** — are defined in `01_RATIONALE.md` §6 and sharpened here (the threshold is `RULESET_STALE_DAYS`; the credential directory's own mode is judged by `mode & 0o022`). Not written into `CONTEXT.md` by this stage, per Q-15's T-19 precedent. | PM, at task close |
| RS-7 | **One durable declined approach earns a `.harness/rejected-decisions.md` record this stage may not write**: `doctor-dns-row-by-a-host-side-lookup` — declined; the DNS row asks the running sing-box through `GET /dns/query` on the Clash API, never `socket.getaddrinfo` (unbounded, BC-17), never a hand-rolled UDP DNS packet to a new server constant, and never a TCP connect whose resolution half is unbounded. Why: only the API route is caller-bounded *and* guaranteed to be the install's own resolver — a host-side lookup silently measures the host stub whenever the TUN device is down, i.e. exactly on the broken host the row exists for. Origin: T-20 `02_SOLUTION_DESIGN.md` `## BC-16 probe and ruling` + P-1. | PM, at task close |

## Verdict

**READY.**
