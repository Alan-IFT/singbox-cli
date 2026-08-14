# 04 — Development · T-20 `doctor-extended-checks`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).
>
> Three units the PM's dispatch requires in the contract fit no declared section shape on
> this project (`.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary
> rule` — **R-37, sixth confirmation**) and are carried below as named sections, in the
> E-20 precedent: `## Probe P-2 and P-3 — verbatim`, `## Binding condition discharge` and
> `## Implementation against the design inventory`. The gap is filed in
> `## Open issues for review`.

## Summary

1. `sc doctor` grew from seven facts to nine: `RULESET_STALE_DAYS`, `EGRESS_HOST` and
   `_aaaa_rule()` were extracted as declared, five rows were added (rule-set age +
   staleness, config drift, AAAA consistency, node delays, DNS lookup, file permissions —
   five *rows*, six *facts*, because age lands on rows that already exist), and
   `DOCTOR_SECTIONS` grew by exactly two entries.
2. Probe **P-2 was run first-hand** against the live install's Clash API before the DNS row
   was written; its body carries a non-empty `Answer` array, so I-8 stands and FR-6 ships.
3. `verify_all` is unchanged at PASS 17 / WARN 0 / FAIL 0 / SKIP 1; a 54-step fixture suite
   covering V-1…V-18 and GC-1…GC-9 is green, and `config.json`'s bytes are identical to
   HEAD in all four IPv6 decision states (V-11).

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | `EGRESS_HOST = "api.ipify.org"` at `:454`; `_egress_ip()` composes `"https://" + EGRESS_HOST`, and its docstring now sources the literal to `EGRESS_HOST` (the 8 s timeout is still its own) | E-1 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `RULESET_STALE_DAYS = 60` at `:102` in `# Rule-set constants`, with the "why 60" comment | E-2 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `_aaaa_rule(suppress)` at `:1668`; `_dns_overlay()`'s body is now one line (`:1699`) | E-3 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `ipv6_decision()`'s docstring (`:1635`) — **prose only**, the function body is frozen and byte-unchanged: its caller count reads "three callers — `_dns_overlay()`, `cmd_ipv6()` and `sc doctor`'s AAAA row", which `_doctor_ipv6()` made true | CR-4 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `TRANSLATIONS["zh"]`: **+28** entries in the existing thematic groups, **−3** dead ones. The clean-host permission value is scoped to **credential** files (`no credential file grants access to group or other, …` / 「没有凭据文件…」), because `settings.json` is excluded by name whatever its mode — see D-5 | E-4 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `_doctor_rulesets()` (`:2487`): `mtime` destructured, `_age_text()` on every row, staleness verdict + next step. No new row | E-5 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `_doctor_config()` (`:2531`): the drift row, computed first and returned on all three paths, between `configuration` and `sing-box check` | E-6 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `_doctor_ipv6()` (`:2598`), new | E-7 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `_doctor_clash()` (`:2710`): FR-9's reworded PROBLEM value + the node-delay row + the DNS row, both only on the branch where `/configs` answered | E-8 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `_doctor_clash()` (`:2769`): the auto-select tag echoed by `/proxies` is rendered `_plain(current or t("(none)"))` — it is foreign text (a node tag built from a share-link fragment, `:574`), so it may not be the one value in the block that bypasses `_plain()` | CR-5 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `_doctor_permissions()` (`:2808`), new | E-9 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `DOCTOR_SECTIONS` (`:2890`) +2 entries; `DOCTOR_MSG_LINES`' comment widened to "a quoted list"; the block header's "seven facts" → "nine facts" with the two new causal clauses | E-10 |
| `/home/alan/Programs/singbox-cli/README.md` | `### Diagnose the install`: `seven` → `nine`, 2 new table rows, amended rows 2/3/7, the "all nine sections" sentence, both exit-status cause lists, **and the "changes nothing" paragraph (GC-8)**. Section 9's row says "any **credential** file directly inside `/etc/sing-box` … (`settings.json` is excluded — it carries no credential)" | E-11 |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` | the line-for-line mirror of E-11, including section 9's 「凭据文件（`settings.json` 除外 —— 它不含凭据）」 | E-12 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | one Chinese entry at the top of `### 新增` under `## [Unreleased]`; its permission clause carries the same exclusion, so no user-facing text promises more than the check performs | E-13 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | a row for `_aaaa_rule()`; `EGRESS_HOST` folded into the `_egress_ip()` row; `RULESET_STALE_DAYS` named in `# Rule-set constants` and on the `_age_text()` row as its one consumer; `# Commands`' "seven probes" → "nine probes" plus the two sanctioned mode reads; `ipv6_decision()`'s row reads **three** callers | E-14 |

`git diff --numstat`: `bin/sc` +331/−37, `README.md` +13/−11, `README.zh-CN.md` +14/−12,
`CHANGELOG.md` +1/−0, `docs/dev-map.md` +7/−6. No other tracked file is touched;
`docs/batches/**` is modified by the batch loop and left unstaged (AC-S7). `bin/sc`'s net
is **+294**, six more than the growth chain's +288: the CR-1 comment at `:2874-2878` (+3),
the two docstring corrections (+1 each, CR-4 and CR-7) and CR-5's wrapped argument (+1).
No helper, cap, flag or constant exists anywhere in the diff.

## verify_all result

```
baseline (measured before any edit): PASS 17  WARN 0  FAIL 0  SKIP 1
after   (measured after every edit): PASS 17  WARN 0  FAIL 0  SKIP 1
delta:                               0 new failures, 0 new warnings, baseline preserved
command:                             bash .harness/scripts/verify_all.sh
B.1 (syntax bin/sc + the two shell scripts): PASS
B.2 (install.sh bilingual key parity):       PASS — "OK: 48 keys, both languages", exit 0
bin/sc i18n parity (own AST check, B.2 does not cover bin/sc):
  157 t() literal keys, 180 zh entries, 0 missing zh entries, 0 placeholder mismatches,
  0 new keys namespaced `ls.`-style, 0 added lines containing 失败
  diffed against HEAD's own table: +28 keys, −3, 0 shared key's value changed;
  the 6 pre-existing 失败 values, the 5 pre-existing `ls.` keys and the one pre-existing
  dead entry ('Clash API') are HEAD's and are unchanged in number
fixture suite (V-1 … V-18, GC-1 … GC-9): 54 steps, 54 PASS, 0 FAIL
V-11 (config.json byte comparison, HEAD vs after E-3): IDENTICAL in all 4 decision states
```

## Probe P-2 and P-3 — verbatim

*(First unit of the R-37 schema gap. K-20 / GC-6 require the verbatim body here.)*

Run first-hand at this stage, before E-8 was written, as read-only `GET`s on loopback
against the persisted port (`clash_api_port: 29090`, read from
`/etc/sing-box/settings.json`, which is mode 0644). No service action, no write, no
credential byte.

**P-2a** — `curl -s "http://127.0.0.1:29090/dns/query?name=api.ipify.org&type=A"`:

```json
{"AD":false,"Answer":[{"TTL":228,"data":"104.26.12.205","name":"api.ipify.org.","type":1},{"TTL":228,"data":"104.26.13.205","name":"api.ipify.org.","type":1},{"TTL":228,"data":"172.67.74.152","name":"api.ipify.org.","type":1}],"CD":false,"Question":[{"Name":"api.ipify.org.","Qtype":1,"Qclass":1}],"RA":true,"RD":true,"Server":"internal","Status":0,"TC":false}
```

**P-2a re-issued through the code under test** — `clash_api("GET", "/dns/query?name=" +
EGRESS_HOST + "&type=A", port=29090)` on the neutralised module returned a `dict` whose
`Answer` is a non-empty list. PQ-1 is confirmed empirically: no query-string escape, no
`Request` change, no new envelope.

```json
{"AD": false, "Answer": [{"TTL": 176, "data": "104.26.13.205", "name": "api.ipify.org.", "type": 1}, {"TTL": 176, "data": "104.26.12.205", "name": "api.ipify.org.", "type": 1}, {"TTL": 176, "data": "172.67.74.152", "name": "api.ipify.org.", "type": 1}], "CD": false, "Question": [{"Name": "api.ipify.org.", "Qclass": 1, "Qtype": 1}], "RA": true, "RD": true, "Server": "internal", "Status": 0, "TC": false}
```

**Ruling: the body does not contradict I-8 — a JSON object with a non-empty `Answer`
list — so the DNS row ships as designed and nothing routes back to stage 2.**

**P-2b** — the design's second half (a `TELEMETRY_NAMES` entry, expected "rejected/empty")
came back **resolved**:

```json
{"AD":false,"Answer":[{"TTL":55,"data":"telemetry-incoming.r53-2.services.mozilla.com.","name":"incoming.telemetry.mozilla.org.","type":5},{"TTL":55,"data":"prod.ingestion-edge.prod.dataservices.mozgcp.net.","name":"telemetry-incoming.r53-2.services.mozilla.com.","type":5},{"TTL":55,"data":"34.54.185.247","name":"prod.ingestion-edge.prod.dataservices.mozgcp.net.","type":1}],"CD":false,"Question":[{"Name":"incoming.telemetry.mozilla.org.","Qtype":1,"Qclass":1}],"RA":true,"RD":true,"Server":"internal","Status":0,"TC":false}
```

**Measured cause, not a refutation of BC-16's ruling:** `grep -c TELEMETRY_NAMES
/usr/local/bin/sc` = **0**. The installed build (Aug 11) predates T-17's reject list, so
the live `config.json` carries no rejection rule for that name and there is nothing for the
rule chain to reject. The discriminator was inapplicable on this host, not failed. The
remaining evidence for BC-16 clause 3 is direct: the answer is served by the running
sing-box's own Clash API and names its resolver (`"Server":"internal"`), and P-3 below
shows an upstream NXDOMAIN propagating through it verbatim. Recorded as a residual so the
reader is not left with a prediction that reads as unmet.

**P-3** — `…/dns/query?name=nx-does-not-exist-t20.invalid&type=A`:

```json
{"AD":false,"Authority":[{"TTL":600,"data":"localhost. nobody.invalid. 1 3600 1200 604800 10800","name":"invalid.","type":6}],"CD":false,"Question":[{"Name":"nx-does-not-exist-t20.invalid.","Qtype":1,"Qclass":1}],"RA":true,"RD":true,"Server":"internal","Status":0,"TC":false}
```

A JSON **object with no `Answer` key** (`Status: 3`, NXDOMAIN). I-8's "an object without a
non-empty `Answer` list ⇒ PROBLEM `{name} returned no records`" branch is therefore real
and reachable, and V-7(b)'s stub body is copied from this measurement rather than invented.

**One further measurement, not asked for and worth recording:** `…&type=28` is answered
`{"message":"invalid query type"}` with a 4xx, i.e. the route accepts only the textual
type names it knows. The shipped row asks `type=A` and is unaffected.

## Implementation against the design inventory

*(Second unit of the R-37 schema gap.)*

| id | what was implemented |
|---|---|
| I-1 | `RULESET_STALE_DAYS = 60` (`:102`). **One** reader, asserted on the AST: `_doctor_rulesets()` at `:2509`, as `time.time() - mtime >= RULESET_STALE_DAYS * 86400`. Nothing reads `settings["update_interval"]`. |
| I-2 | `EGRESS_HOST` (`:454`); `_egress_ip()` composes `"https://" + EGRESS_HOST` with `timeout=8` and the decode untouched — V-11's fixtures and the live run both still reach the same URL. Two consumers, no third. |
| I-3 | `_aaaa_rule(suppress)` (`:1668`) returns the rule dict; `_dns_overlay()` is `{"dns": {"rules": {"$prepend": [_aaaa_rule(ipv6_decision()[1])]}}}`. Keys, values and order unchanged — proved by V-11, not by reading. |
| I-4 | `_doctor_rulesets()` renders `_age_text(mtime)` on **every** row from the same 6-tuple element the `{size}` came from; stale ⟺ `usable` ∧ `mtime is not None` ∧ age ≥ threshold; a stale row is PROBLEM and lifts the summary to PROBLEM through the existing assignment. `{n}/{total} usable` is unchanged and still counts a stale file as usable (it *is* usable). No new row. |
| I-5 | The drift row is `_drift_state()`'s three states and nothing else, computed **before** the readability probe and returned on all three paths, always between `configuration` and `sing-box check`. `True` names `OVERRIDE_PATH` and `sc reload`; `False` names no path; `None` is UNKNOWN. No second digest. |
| I-6 | Implemented **per GC-2, not per I-6's formula** — see `## Design drift` D-1. One `ipv6_decision()` call; `_aaaa_rule(suppress) in rules` as the membership test; `(OSError, ValueError)` + `isinstance` at every level; non-object document ⇒ UNKNOWN, non-object `dns` ⇒ PROBLEM (PQ-3). |
| I-7 | On the `/configs`-answered branch only. `load_nodes()["nodes"]`, `len()` and the tag set are read inside one `try` guarded by `(OSError, ValueError, TypeError, KeyError)`, so a `nodes.json` that is absent, unreadable, not UTF-8, not JSON or of the wrong shape is one UNKNOWN row naming the file. No nodes ⇒ OK and **no request**. Otherwise `stored_delays(port=port)`; `n == 0` ⇒ PROBLEM naming both causes and `sc ls`; `n > 0` ⇒ OK with `{n}/{total}`, the "history, not a fresh measurement" clause and `current or t("(none)")`. One row. |
| I-8 | `GET /dns/query?name=<EGRESS_HOST>&type=A` through `clash_api(..., port=port)`, issued only on the same branch. Elapsed is `int((time.monotonic() - t0) * 1000)` around the one call. `None` ⇒ PROBLEM "no answer for {name} after {ms} ms"; a non-empty `Answer` list ⇒ OK; anything else ⇒ PROBLEM "returned no records". No `try`/`except`, no retry, no sleep, and **no row states a timeout value or a wall-clock bound**. |
| I-9 | `CFG_DIR.stat()` → `FileNotFoundError` ⇒ one UNKNOWN row and **no `mkdir`**; other `OSError`, or an `OSError` from `sorted(CFG_DIR.iterdir())` ⇒ one UNKNOWN row naming the reason. Per entry: `lstat()`, symlinks reported and never followed, sub-directories never descended, `settings.json` the one exclusion, `mode & 0o077` for files and `mode & 0o022` for the directory. One summary row; details are `cls is None` quoted lines capped at `DOCTOR_MSG_LINES` with the existing overflow key. `%03o` modes; `chmod %03o` from `CRED_MODE` for a file, `chmod go-w` for the directory. No file content is read. |
| I-10…I-16 | 28 zh entries added in the existing thematic groups, 3 deleted (`"{reason}, {size} bytes"`, `"{reason}, size unavailable"`, `"no answer within the 3s timeout"`), each new key an English sentence with the same placeholder set in both halves. |
| I-17 | `DOCTOR_SECTIONS` = binary, rule-sets, configuration, **IPv6 (AAAA)**, service, TUN interface, Clash API, egress IP, **file permissions**. Two insertions, no reordering, still the one table, still read only by `cmd_doctor`. |
| I-18 | All five FR-12 precedence pairs asserted on one healthy capture, plus "every permission row last" (AC-S3, PASS). |

**Not implemented, deliberately:** no helper, cap, flag or constant the design did not
declare. `_age_seconds()` stays unwritten (the design took the smaller option); the
node-delay and DNS rows are inline in `_doctor_clash()` rather than in helpers of their
own, because E-8 declares one function edit and not three.

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| D-1 | `02_SOLUTION_DESIGN.md` I-6's membership test, spelled `all(r in rules for r in _dns_overlay()["dns"]["rules"]["$prepend"])` | `isinstance(rules, list) and _aaaa_rule(suppress) in rules`, with `suppress` from the probe's single `ipv6_decision()` call | Mandated by **GC-2** (gate finding F-1): I-6's formula re-enters `_dns_overlay()`, which calls `ipv6_decision()` at `bin/sc:1699`, shipping the exact double call K-6 forbids and voiding E-3's justification. `02_RATIONALE.md:16` already describes the shipped form ("`_aaaa_rule(suppress)` gives the rule one home; the probe does a membership test"), so this is I-6's prose catching up with the design's own reuse table, not a new decision. Reached for `02_RATIONALE.md` under T4.1 — present, consulted. |
| D-2 | I-6's "non-object/unparseable document ⇒ UNKNOWN `cannot read {path}: {e}` (existing key)" leaves `{e}` unfilled when nothing raised | The cause slot is filled with the **existing** key `"the top level must be a JSON object"` (already in `TRANSLATIONS["zh"]` from the override group) | I-6 names the key but not what fills its one placeholder when there is no exception. Reusing an existing translated sentence adds no string and no new key; inventing one would have widened E-4 past its declared +28. |
| D-3 | E-10 declares only the `DOCTOR_MSG_LINES` comment widening outside the table | The `# doctor` block header comment (`:2380`) also moved from "seven facts" to "nine facts", with the two new causal clauses | The header states the section count and the causal order in prose; leaving it at "seven" would have made the one comment reviewers read to review the ordering false. Comment only — no behaviour, no row, no string. |
| D-4 | The design's docstrings are not specified, and V-16/AC-S2 are stated as a substring sweep for `st_size` / `.stat()` / `getmtime` | The new docstrings **name** the banned calls in prose ("no `os.stat`, no `getmtime`", "`_dns_overlay()` is deliberately NOT called from anywhere in this block"), so V-16 was implemented as an **AST** sweep over call and attribute nodes rather than a substring grep | A substring grep over the diff cannot distinguish a docstring that states the ban from a call that violates it, and it produced three false FAILs on the first run. The prose is the note a future editor needs and was kept; the sweep was made sound instead. Recorded so stage 5's own grep is not surprised. |
| D-5 | I-9 / I-16 spell the clean-host permission value as `no file grants access to group or other, and the directory is not group- or other-writable`, and `README*.md`'s section-9 row mirrors it as "any file directly inside `/etc/sing-box`" | The value is scoped to **credential** files — `no credential file grants access to group or other, and the directory is not group- or other-writable` / 「没有凭据文件对同组或其他用户开放，目录本身也不可被同组或其他用户写入」 — and both READMEs plus `CHANGELOG.md` name the exclusion out loud (`settings.json` is excluded — it carries no credential) | The check excludes `settings.json` **by name, whatever its mode** (I-9's own predicate, `:2861`) and `save_settings()` writes it with `write_text()` (`:559`), so it is 0644 on a default install: the design's sentence asserts of every file something the check established only of the credential files, and it does so on the *default* host state rather than an edge case — the R-22 defect class this task exists to remove. Narrowing the sentence, never the check: Q-4 decided the exclusion and widening the check would fire on 100 % of installs. "credential file" is `02_RATIONALE.md:73`'s own vocabulary (`/etc/sing-box` is *the credential directory*, `settings.json` the one document in it that carries none). One key pair replaces one key pair, so E-4 stays at exactly +28/−3, the PROBLEM and UNKNOWN values are untouched and no other row moves. **V-9.5 is the control**: on a fixture that *is* a default install (every credential file 0600, the directory 0755, `settings.json` 0644) the row reads `[OK]` and its sentence is true of what was measured. Ordered by CR-1 with `05_RATIONALE.md` §3's wording; reached for `02_RATIONALE.md` under T4.1 — present, consulted. |

## Condition disposition

| gate condition | disposition | evidence |
|---|---|---|
| GC-1 | **Discharged.** The three row-level clauses are asserted separately from the exit-status clause. On the wholly healthy fixture: **every new row `[OK]`** (5/5); **no new row names a path or a next step** (0 offenders under a token-level path test plus the seven command literals); **exactly +5 rows** against a HEAD run **of the same fixture root** (16 → 21). Exit value reported as required: **0**, with no `[PROBLEM]` and no `[UNKNOWN]` anywhere — the five sections this task does not own were made green in-process per PQ-8 (a repointable `sc.SB_BIN` stub, one argv-dispatching `subprocess.run`, one `_egress_ip` replacement), so no clause had to be weakened and no partial is reported. | `GC-1a/b/c/d` PASS; both captures quoted in `04_RATIONALE.md` §2 |
| GC-2 | **Discharged.** `_doctor_ipv6()` consumes `_aaaa_rule(suppress)` with `suppress` from its single `ipv6_decision()` call (`:2617`, `:2635`). AST sweep of every `_doctor_*` / `cmd_doctor` function: `_dns_overlay()` call sites = **0**, `ipv6_decision()` call sites = **1**, `_aaaa_rule()` call sites = **1**. V-5 asserted as an **exact count**: on the detection-failure run the IPv6 stderr line appears **exactly once** (`err.count(...) == 1`), and on the unrecognised-`ipv6`-value run BC-9's line appears **exactly once**. | `V-16`, `GC-2a`, `GC-2b`, `V-5/*` all PASS |
| GC-3 | **Discharged, in these words:** the sweep is scoped to *"no `st_size` anywhere, and no `.stat()` / `getmtime` on a **rule-set** path"*. The rule-set section takes its timestamp only from `ruleset_states()`' 6-tuple, which comes from the one `os.fstat()` on the open handle inside `ruleset_state()` — this diff adds no path-based metadata read of any `.srs`. The **two sanctioned mode reads** are `_doctor_permissions()`'s `CFG_DIR.stat().st_mode` at **`bin/sc:2828`** and the per-entry `entry.lstat().st_mode` at **`bin/sc:2850`**. They read a *mode*, a fact nothing else in the tool reports, so they form no second opinion of any reported fact; they are also the only `.stat()`/`.lstat()` call sites the diff adds, asserted as an exact pair. | `V-16` PASS (both call sites enumerated and matched exactly) |
| GC-4 | **Discharged.** Every fixture step whose observable depends on `stored_delays()` sets `sc.SYSTEMD = True` **and** replaces `sc.subprocess.run` with an argv-dispatching stub returning an object carrying `.returncode` **and** `.stdout` bytes, so `_doctor_run()` still works and **no `systemctl` is ever exec'd**. Asserted **at the stub server** that the request was received: the stub's log for the V-6/V-12 rig reads `['/configs', '/proxies', '/dns/query?name=api.ipify.org&type=A']`. V-8's mirror is unchanged and also asserted: with no port recorded, the stub log is `[]`. | `GC-4a`, `V-6`, `V-6c`, `V-8/silent` PASS |
| GC-5 | **Owner is stage 6.** Not discharged here; nothing in this stage's code or fixtures asserts an import failure or a bare non-zero exit for a deleted symbol. The related property this stage *did* assert is V-13's: each probe forced to fail independently still prints **every** one of the 15 section labels, terminates normally and produces no traceback. | `V-13/*` PASS (5 sub-runs) |
| GC-6 | **Discharged — P-2 ran.** Verbatim bodies above, including the same request re-issued through `clash_api()`. The body does not contradict I-8; no stub body was invented (V-7's bodies are copied from P-2a and P-3); nothing routes back to the solution-architect. | `## Probe P-2 and P-3 — verbatim` |
| GC-7 | **Decided and recorded** — see `## GC-7 decisions` below. One V-13 sub-run per case, both green, no traceback, every other section still printed. | `GC-7a`, `GC-7b` PASS |
| GC-8 | **Discharged.** `README.md`'s "**`sc doctor` changes nothing**" paragraph and its zh mirror now carry: the command itself still touches no path, **but** section 7's lookup is performed *by the running sing-box*, which may record it in its own DNS cache at `/var/lib/sing-box/cache.db`. FR-13's claim is **not** widened to cover the service (PQ-5). Section 7's amended table text names the lookup ("one name lookup performed by the running sing-box with the time it took"). | `README.md:270`-region diff, `README.zh-CN.md` mirror |
| GC-9 | **Discharged.** V-2 asserts the age phrase on a **usable, non-stale** row: `[OK] geosite-google.srs: usable, 203 bytes, 0 seconds ago` — the phrase sits beside the status and the byte count exactly as FR-1 requires, on a healthy row, and the row carries no next step. The clock-skew row is `[OK] geoip-cn.srs: usable, 203 bytes, 0 seconds ago` (never negative, never stale) and the no-complete-read row is `[PROBLEM] geosite-cn.srs: unreadable, size unavailable, last update unknown` (word form, no digit, never stale). | `GC-9`, `V-2` PASS |
| GC-10 | **Discharged for every foreign value; one clause satisfied by construction rather than by a call, stated exactly.** (a) Every `{e}` goes through `_plain()` — including `_doctor_ipv6()`'s non-object cause, which is one of our own translated sentences and is `_plain()`ed anyway so no later edit can put foreign text in an un-plained slot. (b) Every **filesystem-sourced** path (`CFG_DIR.iterdir()`'s entries) is `_plain()`ed at the call site, in both the finding line and the command it prints; the module-constant paths (`CFG_PATH`, `NODES_PATH`, `OVERRIDE_PATH`, `CFG_DIR`) follow the existing `str(...)` house style, which is what GC-10's "filesystem-sourced" qualifier distinguishes. (c) The one API-sourced value, `/proxies`' auto-select tag, **is** `_plain()`ed (`:2769`, CR-5) — it is the only foreign value in the five new rows that was not, and `_plain()`'s docstring invariant ("everything doctor prints that it did not write itself goes through here") is now true of the whole diff. (d) The **mode strings are NOT `_plain()`ed**, at `:2841` and `:2864`: they are `"%03o" % (st_mode & 0o777)` over an `int` this code formats itself, so they are not foreign text and cannot carry CR or ESC — the condition's third clause is met by construction, not by a call, and a `_plain()` wrapper there would be a provable no-op a future reader has to re-derive. Recorded in these words because the shipped code and this record must say the same thing. (e) **No added line contains `失败`**. | `V-17` PASS (no `\r`, no ESC in any capture); `V-17c` PASS — with `/proxies` echoing the tag `n1\r\x1b[31mRED\x1b[0m`, stdout carries no CR and no ESC and the row reads `auto-select is on n1RED`; the same fixture against the un-plained form leaks both bytes. `V-15`, `V-15p` PASS |

## GC-7 decisions

**(a) A per-entry `lstat()` raising `OSError`** — BC-26's own scenario, a `_write_private()`
temporary renamed away mid-listing. **Decision: skip that entry and continue the listing.**
The path is gone, so there is nothing left to judge; skipping costs at most one finding
that a re-run would make anyway, whereas letting the `OSError` escape would degrade the
whole section to one UNKNOWN row and lose every other path's verdict — the opposite of what
the row exists for. `doctor` may not lock, retry or block (BC-26), and it does none of the
three. Verified by injecting a ghost entry the listing yields but which was never created:
the section still reads `[OK] file permissions: no credential file grants access to group
or other, and the directory is not group- or other-writable`, the vanished name appears
nowhere, all 15 labels print and there is no traceback.

**(b) A `doc["dns"]` that is not an object.** **Decision: PROBLEM, through the membership
test's `False` branch (PQ-3).** The document demonstrably does not carry the rule, which is
what the row states, and its next step is correct. The mechanism is `isinstance` guards in
`stored_delays()`' house style — `dns.get("rules") if isinstance(dns, dict) else None` —
so `TypeError` is never raised and K-7's `(OSError, ValueError)` tuple is never asked to
catch something it does not name. Verified with `config.json = {"dns": "hello"}`: the row
reads `[PROBLEM] IPv6 (AAAA): … config.json does not carry this decision — run
`sc reload` to regenerate it`, every other section prints, exit 1, no traceback.

## Binding condition discharge

*(Third unit of the R-37 schema gap: the fixture rig the discharges above stand on.)*

Every `[B]` step ran in a redirected fixture built with `docs/dev-map.md`'s `sys.modules`
neutralisation recipe **verbatim**, with all **eight** path constants repointed into a
`mkdtemp()` root and **asserted** to resolve inside it, `sc.LANG` set explicitly, the stub
Clash port recorded in the fixture's **own** `settings.json` and bound from a port proved
free by `bind(("127.0.0.1", 0))` (never 29090 — the live instance's), `sc.CLASH_PORT` set
to a value no server holds, `main()` never driven and `_init_files()` never reached. K-18's
safety floor held throughout: nothing under `/etc/sing-box` or `/var/lib/sing-box` was
written, the live service was never touched, and the only live requests issued were P-2 and
P-3, both read-only `GET`s.

Two fixture traps bit and were fixed rather than tolerated, both recorded in
`04_RATIONALE.md` §3: the emitted `config.json` embeds `RULES_DIR`, so V-11's two sides
must share **one** temp root or every pair differs for a reason that has nothing to do with
the change under test; and this host's umask is **002**, so `mkdir()` leaves `0775` and
`write_text()` leaves `0664` — both offending by `_doctor_permissions()`' own predicates,
which silently turns every permission fixture into a test of the harness.

**AC-B14 is not discharged and cannot be** (V-19, and the R-31/R-41/R-47 precedent): the
shipped invocation is `sc doctor` **as root on the live host**, which would require
installing the candidate build over `/usr/local/bin/sc`. K-18 forbids it and no weaker
artifact check is substituted. Reported as **BLOCKED**, for the PM to file.

## Open issues for review

- **R-37, sixth confirmation.** `.harness/rules/70-doc-size.md` still defines no
  `## Stage-doc boundary rule`, so this stage's three required-in-contract units (the P-2
  transcript, the inventory walk, the fixture-rig record) fit no declared section shape.
  They are carried as named sections above and the gap is filed here rather than invented
  into an existing section. Five stages of this task have now filed it.
- **RS-2 reproduced and unchanged.** `stored_delays()`' internal `is_running()` guard means
  a host with no init system but a live Clash API reads `0/{total}` on the node-delay row.
  Not fixable here without a second `is_running()` opinion or bypassing the reader, both
  forbidden. It travels to `07_DELIVERY.md`.
- **P-2b's discriminator was inapplicable on this host** (the installed build predates
  `TELEMETRY_NAMES`), so BC-16 clause 3 rests on the route being served by the running
  process, `"Server":"internal"`, and P-3's NXDOMAIN propagation rather than on the
  telemetry rejection the design expected. Stated in full above so the gate's expectation
  is not silently marked met.
- **The live host is itself a positive instance of FR-7 and FR-3.**
  `/etc/sing-box/config.json.bak-2026-08-01-1001` exists at mode 0600 (so it would *not*
  be reported), and `/etc/sing-box/settings.json` is 0644 — excluded by name whatever its
  mode, which is why the clean-host sentence is scoped to **credential** files (D-5). This
  host is the default install the row's wording now has to be true of, and V-9.5 is that
  host as a fixture.
- **Two row-level residuals are known and deliberately not fixed here** (they are stage 5's
  RES-1 and RES-2, travelling to `07_DELIVERY.md`): the AAAA membership test is
  position-blind, and the DNS row can be answered from the running install's own DNS cache
  for the very name the egress probe warms in the same run. Both need a design decision
  this stage may not take.
- **`sc status` still renders rule-set ages with an ASCII separator under zh** (RS-5 /
  R-38). This task added the third and fourth full-width-separator keys and still does not
  touch `cmd_status` — out of scope 3, unchanged.

## Dev-map updates

- `# Rule-set constants` now names `RULESET_STALE_DAYS` as THE staleness threshold, 60 days,
  one definition and exactly one reader.
- A new "Reusable utilities" row for `_aaaa_rule(suppress)`, stating why it is a function
  taking the decision as an argument rather than a literal inside `_dns_overlay()`.
- The `_egress_ip()` row is now `EGRESS_HOST` + `_egress_ip()`, naming both consumers.
- The `_age_text()` row names `sc doctor`'s rule-set section as its one staleness consumer
  and pins that the verdict reads the same `mtime` the phrase renders.
- The `_dns_overlay()` row is restated in terms of `_aaaa_rule(ipv6_decision()[1])`.
- The `ipv6_decision()` row now says **three** callers — `_dns_overlay()`, `cmd_ipv6()` and
  `sc doctor`'s AAAA row (`_doctor_ipv6()`, once per run) — matching the function's own
  docstring, so the sentence a future editor reads before adding a caller is true.
- The `# Commands` row now says nine probes and names `_doctor_permissions()`'s two mode
  reads as the block's only ones.

## Insight to surface

- sing-box's Clash API answers `GET /dns/query?name=<n>&type=A` with a Google-DoH-shaped JSON object whose records live under `Answer` and whose NXDOMAIN form carries **no `Answer` key at all** (only `Authority` + `Status`), while `type=28` is rejected outright as `{"message":"invalid query type"}` — so the route accepts only textual type names and "no records" and "no answer" are two structurally different bodies, not one · evidence: `docs/features/doctor-extended-checks/04_DEVELOPMENT.md` `## Probe P-2 and P-3 — verbatim`
- A generated `config.json` embeds `RULES_DIR` in `route.rule_set`, so any byte-for-byte before/after comparison of `generate_config()` must run both sides in the **same** `mkdtemp()` root — two different temp names alone make every pair differ, which reads exactly like the change under test having altered the document · evidence: `bin/sc:1769` `_runtime_overlay()`, measured in T-20's V-11
- A `bin/sc` permission fixture is decided by the **harness's umask**, not by what it plants: at the common umask 002 `Path.mkdir()` leaves 0775 and `write_text()` leaves 0664, both of which trip `_doctor_permissions()`' own `mode & 0o022` / `mode & 0o077` predicates, so a fixture that does not normalise to 0755/0600 measures its own loader · evidence: `bin/sc:2828-2856`, T-20 fixture harness
- A static "this call must not appear" sweep over a diff cannot be a substring grep on this codebase, because the docstrings deliberately **name** the calls they ban (`_dns_overlay()` is not called here, no `getmtime`) — the sweep has to walk the AST for `Call` / `Attribute` nodes or it produces false FAILs on exactly the well-documented code it was written to protect · evidence: `bin/sc:2601-2607`, T-20 V-16

- `/etc/sing-box/settings.json` is **0644 on every default install** and stays that way: `save_settings()` writes it with `write_text()` (never `_write_private()`), and the installer's credential sweep excludes it by name — so any check or sentence about "files in the credential directory" is false on 100 % of hosts unless it says *credential* file · evidence: `bin/sc:559`, `bin/sc:2861`, T-20 V-9.5

## Verdict

READY FOR REVIEW
