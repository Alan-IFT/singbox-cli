# 06 — Test Report · T-16 `dns-resilience`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

Upstream contract portions read in full: `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`,
`03_GATE_REVIEW.md`, `04_DEVELOPMENT.md`, `05_CODE_REVIEW.md`, `PM_LOG.md`. No rationale sibling was
opened: T6.1 did not fire (every AC's verification column is specific), T6.2 did not fire (M-1…M-5 are
quoted in `PM_LOG.md`'s contract portion and I re-derived the 10.0 s deadline myself rather than
reproducing a developer measurement from `04_RATIONALE.md`), T6.3 did not fire (CR-4, CR-6, CR-8, CR-9,
CR-10 are each self-contained in `05_CODE_REVIEW.md`). `.harness/rules/70-doc-size.md` carries no
`## Stage-doc boundary rule` section, so this schema is applied as written; C-11's stated limits are
carried as boundary statements in `## Boundary tests added`, the only declared shape that can hold them.

**Everything below was rebuilt, not inherited.** Stage 4's fixture, transcripts and probe classifications
were used only as a recipe to re-implement from (C-7); every number in this document came out of a
harness I wrote in this session, run against a pristine HEAD clone (`git clone`, `.git` a real directory,
commit `9f85f9e`) and the working tree, at the **same** fixture root per scenario. Harness files (throwaway
per out-of-scope item 8 — R-9 owns a committed harness):
`/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/work/`
→ `t16lib.py` (the C-7 recipe re-implemented), `beh.py`, `adv5.py`, `classtext.py`, `struct1.py`,
`struct2.py`, `struct3.py`.

## Test plan

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-B1 node-independent class ≤100 ms, node accepts-never-answers | `scen_b123_9()` tag `B1`, 3 probes + HEAD agreement control | `beh.py` |
| AC-B2 same, all rule-sets unusable | `scen_b123_9()` tag `B2` (fixture `rules/` emptied) | `beh.py` |
| AC-B3 same, node refuses | `scen_b123_9()` tag `B3` (`proxy` at a closed port) | `beh.py` |
| AC-B4 AAAA empty `NOERROR` ≤100 ms, no upstream query | `scen_b4_b6_36()` rule mode + `scen_b5_36()` V-36 non-vacuity | `beh.py` |
| AC-B5 `sc ipv6 on` → AAAA resolved normally | `scen_b5_36()` env `B5`, node usable | `beh.py` |
| AC-B6 AC-B4 holds in clash `global` and `direct` | `scen_b4_b6_36()`, mode set through the **fixture's own** Clash API | `beh.py` |
| AC-B7 same resolver as HEAD, 6 names × 2 rule-set states × 3 modes | `scen_b7()`, 36 combinations, stub-receipt compared per name | `beh.py` |
| AC-B8 no-rule name: no answer, no stub, wall clock ≤ HEAD's | `scen_b8()`, `dig +tries=1 +time=15` both sides | `beh.py` |
| AC-B9 zero nodes | `scen_b123_9()` tag `B9`, plus a second run with `outbounds` **verbatim** | `beh.py`, `adv5.py` |
| AC-B10 every behavioural run has its control, of the declared kind | all of the above; classification asserted per row | `beh.py`, `adv5.py` |
| AC-1 suppressing → `predefined`/`NOERROR`/no records | `V-4/AC-1` | `struct1.py` |
| AC-2 not suppressing → exactly `[64, 65]` in that order | `V-3/AC-2` | `struct1.py` |
| AC-3 the rule precedes both `clash_mode` rules and every `remote_dns` rule | `V-5/AC-3`, four states | `struct1.py` |
| AC-4 no `rule_set` key on the added rule, both rule-set states | `V-6/AC-4` | `struct1.py` |
| AC-5 real `sing-box check` in six states | `V-7/AC-5` | `struct1.py` |
| AC-6 one decision function, every consumer calls it | `V-10/AC-6` + deletion test | `struct1.py` |
| AC-7 no DNS wait in the document or in `bin/sc` | `V-11a/AC-7`, `V-11b/AC-7` | `struct1.py` |
| AC-8 merge machinery byte-identical to HEAD | `V-8/AC-8`, `ast` segment bytes (RES-1 discharged) | `struct1.py` |
| AC-9 the three socket waits byte-identical | `V-9/AC-9`, `ast` keyword values | `struct1.py` |
| AC-10 no configuration literal, no fourth guard key | `V-3/AC-10` + `V-3b/AC-10` (C-8) | `struct1.py` |
| AC-11 four forms × two languages exit 0 | `V-12/AC-11`, eight `main()`-driven runs | `struct2.py` |
| AC-12 `sc ipv6 show` writes/opens/applies nothing (scoped by C-4) | `V-13/AC-12` + `V-13b/C-4` | `struct2.py` |
| AC-13 no-op set performs no service-affecting action | `V-14/AC-13`, two shapes | `struct2.py` |
| AC-14 decision-changing set regenerates and applies | `V-15/AC-14`, C-6 non-vacuity control | `struct2.py` |
| AC-15 absent / no-key / unrecognised value → `auto` | `V-16/AC-15`, 8 runs incl. an unreadable file | `struct2.py` |
| AC-16 global-address predicate incl. the `sb-tun` trap | `V-17/AC-16`, four address sources | `struct2.py` |
| AC-17 unreadable source → no suppression, one line, no traceback | `V-18/AC-17`, 5 sources × 2 languages + non-vacuity | `struct2.py` |
| AC-18 BC-16 upgrade: first `sc reload` clean, second silent | `V-19/AC-18` | `struct2.py` |
| AC-19 zh parity, no `失败：`, no `ls.*` key | `V-20/AC-19`, `ast`-extracted `TRANSLATIONS` | `struct3.py` |
| AC-20 both READMEs + changelog, line-for-line mirrors | `V-21/AC-20`, `V-21/K-16`, `C-10 ceiling` | `struct3.py` |
| AC-21 `ipv6` row in both help blocks at the existing alignment | `V-22/AC-21` | `struct3.py` |
| AC-22 an `sc`-authored overlay fault never names `override.json` | `V-23/AC-22`, four runs (C-5 included) | `struct3.py` |
| AC-23 `py_compile`, 3.6 floor, stdlib only | `V-24/AC-23`, 272/12 lines + count-independent `ast` | `struct1.py` |
| AC-24 `verify_all` ends with no FAIL against 17/0/0/1 | `## verify_all result` below | — |

## Adversarial tests

Every hypothesis was written before the run. Cited output is ≤5 lines per row; the full transcripts are
in `06_RATIONALE.md`. Controls are named by kind: **[D]** defect-reproducing (HEAD must exhibit the
defect), **[A]** agreement (HEAD must produce the candidate's outcome).

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-B1 | the domestic-suffix probe leaves via the hung node, so 360.cn stalls with the node down | `python3 beh.py b1239` (NEW) | Survived — `doh.pub/A NOERROR ans=2 20.0ms; 360.cn/A NOERROR ans=1 18.4ms; TYPE64 NOERROR ans=0 8.5ms`, proxied stub empty. **[A]** HEAD `8.5/18.2/17.9 ms`, same outcomes |
| AC-B2 | with `rules/` empty the suppression rule is deleted with the rest, so TYPE64 stalls | `python3 beh.py b1239` (NEW) | Survived — `21.5/19.5/10.0 ms`, all `NOERROR`; `dns.rules` shrank 8→5 and index 0 stayed. **[A]** HEAD `22.0/23.3/19.6 ms` |
| AC-B3 | a refused connection fails differently from a hang and leaks the domestic names | `python3 beh.py b1239` (NEW) | Survived — `18.9/20.6/9.7 ms`, proxied stub empty. **[A]** HEAD `20.4/20.4/22.0 ms` |
| AC-B4 | suppression only *looks* fast because the fixture cannot stall at all | `python3 beh.py b46` + `beh.py b5` (V-36) + ADV-1 below (NEW) | Survived — candidate `NOERROR ans=0 19.7 ms`, neither stub touched; with a **usable** node the proxied stub recorded `('t16-nomatch.org', 1)` and **not** 28. **[D]** HEAD: no answer, client's own 15 s limit, `[10.0s] dns: exchange failed for t16-nomatch.org. IN AAAA: context deadline exceeded` — and HEAD's V-36 stub recorded **both** `1` and `28` |
| AC-B5 | `sc ipv6 on` still emits `28` in the rule, so AAAA stays suppressed | `python3 beh.py b5` (NEW) | Survived — `dns.rules[0].query_type == [64, 65]`, `AAAA NOERROR ans=1 19.3 ms`, proxied stub recorded `('t16-nomatch.org', 28)`. **[A]** HEAD identical |
| AC-B6 | `direct` mode routes AAAA to `direct_dns` before index 0 is consulted | `python3 beh.py b46` (NEW), mode via the fixture's own Clash port | Survived — candidate `global 18.3 ms / direct 18.6 ms`, `NOERROR ans=0`, **neither** stub records. **[D]** per C-2's corrected text: HEAD `global` stalls (`15031 ms`, no answer); HEAD `direct` does **not** stall — `direct_stub=[['t16-nomatch.org', 28]]`, `ans=1 18.4 ms`, i.e. the defect is the **absence of suppression** |
| AC-B7 | moving the rule to index 0 re-routes some type-A name to another resolver | `python3 beh.py b7` (NEW), 36 combinations | Survived — **0 mismatches**; e.g. `rule/usable: doh.pub=none 360.cn=direct baidu.com=direct probe-x.test=direct www.google.com=remote t16-nomatch.org=remote` in **both** runs. C-9's corrected degraded expectation observed: rule-set names → proxied in `rule`/`global`, non-proxied in `direct`, identically both sides. **[A]** |
| AC-B8 | the no-rule class silently starts reaching the non-proxied stub | `python3 beh.py b8` (NEW) | Survived — candidate `no answer, 15030.3 ms`, **neither** stub records. **[A]** HEAD `15030.9 ms` — no smaller |
| AC-B9 | at zero nodes the collapsed selector changes which names answer | `beh.py b1239` + `adv5.py` (outbounds **verbatim**) (NEW) | Survived — staged: `10.4/20.1/10.6 ms`; verbatim `outbounds=['proxy','direct']`: `18.3/18.2/17.9 ms`, all `NOERROR`. **[A]** HEAD `18.7/18.6/18.9 ms` |
| AC-B10 | some control does neither — green candidate, silent control | every run above, control kind asserted per row | Survived — 3 **[D]** controls exhibited their defect (AC-B4, AC-B6 `global`, AC-B6 `direct`), 8 **[A]** controls reproduced the candidate's outcome. **No run was inconclusive.** C-1 honoured: agreement probes use TYPE64 in `rule` mode, where HEAD already suppresses; type 28 appears only in the **[D]** rows |
| AC-1 | the rule carries an `answer` key or drops `rcode` | `struct1.py V-4` (NEW) | Survived — `{"action": "predefined", "rcode": "NOERROR", "query_type": [28, 64, 65]}`, no `answer` key |
| AC-2 | the list is `[65, 64]` or gains 28 when not suppressing | `struct1.py V-3` (NEW) | Survived — `query_type == [64, 65]`, order asserted as a list, not a set |
| AC-3 | in the degraded state the surviving indices put a `clash_mode` rule first | `struct1.py V-5` (NEW) | Survived — 4 states: `idx0=query_type clash@[2,3] remote@[2,4] n=8` and `clash@[2,3] remote@[2] n=5`; `{"clash_mode":"Direct"}` still matches exactly one element (T-17's slot) |
| AC-4 | `_filter_rules` deletes the new rule on the degraded host | `struct1.py V-6` (NEW) | Survived — present in both rule-set states, no `rule_set` key in either |
| AC-5 | `sing-box check` rejects the moved rule at 0 or 3 nodes | `struct1.py V-7`, **real** `/usr/local/bin/sing-box` (NEW) | Survived — `[('0 nodes',0),('1 node',0),('3 nodes',0),('suppression on',0),('suppression off',0),('rulesets unusable',0)]` |
| AC-6 | some second site re-derives the decision from `settings["ipv6"]` | `struct1.py V-10` + deletion test (NEW) | Survived — one definition; `callers=['_dns_overlay','cmd_ipv6']`; only `_global_ipv6_iface` reads `IF_INET6_PATH`; with `cmd_ipv6` cut out of the source the overlay is byte-identical |
| AC-7 | the diff smuggles a wait in under a non-`timeout` name | `struct1.py V-11a/V-11b` (NEW) | Survived — 0 keys matching `timeout|wait|delay` under `dns` in 6 states; whole-document set is exactly HEAD's `['.outbounds[1].idle_timeout']`; module names gained exactly `['IF_INET6_PATH']`; import set identical |
| AC-8 | a whitespace-level edit slipped into the merge machinery | `struct1.py V-8`, `ast` segment **bytes** (NEW — RES-1) | Survived — `_merge, _directive_of, _apply_directive, DIRECTIVES, _load_override, _anchor_index` byte-identical to HEAD |
| AC-9 | `timeout=3` was widened and a `grep` freeze check would miss it | `struct1.py V-9`, `ast` keywords (NEW — RES-1) | Survived — `{'clash_api': (3, 3), '_egress_ip': (8, 8), '_fetch_to_temp': (30, 30)}` cand/head |
| AC-10 | the guard gained a fourth key or a dict literal appeared | `struct1.py V-3b` (NEW) | Survived — `('dns.rules','route.rules','route.rule_set')`, 3 keys, byte-equal to HEAD; dict literals in `generate_config()`: `cand=0 head=0` |
| AC-11 | a `main()`-driven zh run prints English (the `LANG` reassignment trap) | `struct2.py V-12`, 8 runs, `lang` seeded in the **fixture settings.json** (NEW) | Survived — `zh/show -> exit 0, first='IPv6 域名解析 → auto'`; all 8 exit 0, no `\r` |
| AC-12 | `cmd_ipv6("show")` touches an mtime or opens a socket | `struct2.py V-13`, mtime witness + counting `socket.socket` + `PATH` shims (NEW) | Survived — `9 files, 0 mtime changes, restart/generate witness silent, 0 sockets, init shims never invoked`. BC-11 variant (no `config.json`, no nodes): `exit=0 files_unchanged=True` |
| AC-13 | a no-op set restarts anyway | `struct2.py V-14` (NEW) | Survived — both shapes: `{'restart': 0, 'generate': 0}`, `config.json` mtime unchanged, `Nothing changed …` once |
| AC-14 | the witness cannot fire under `SYSTEMD = OPENRC = False`, so V-13/V-14 are vacuous (C-6) | `struct2.py V-15` (NEW) | Survived — the **same** witness fired `{'restart': 1, 'generate': 1}` and `query_type` became `[28, 64, 65]`; V-13/V-14's silence is therefore evidence |
| AC-15 | a malformed `settings.json` raises instead of degrading | `struct2.py V-16`, 8 runs (NEW) | Survived — `absent/no-key/not-JSON → auto, 0 stderr lines`; `ipv6=yes → auto, exactly 1 line` naming file, key and the three values, in the run's language |
| AC-16 | an `fe80::` on `sb-tun` is counted as a global address | `struct2.py V-17` (NEW) | Survived — `real 7 entries -> None; +2000::/3 on enp3s0 -> 'enp3s0'; +2000::/3 on sb-tun only -> None; empty file -> None` |
| AC-17 | a non-UTF-8 source escapes as a traceback (`UnicodeDecodeError` is a `ValueError`) | `struct2.py V-18`, 5 sources × 2 languages + a round-1 control (NEW) | Survived — 10/10: nothing raised, `suppress=False`, exactly 1 stderr line, no `\r`, no traceback. Non-vacuity: with only the new `except` clause deleted, the round-1 shape **raises on 3 of the 5 sources** (`UnicodeDecodeError`) |
| AC-18 | the first `sc reload` on a pre-T-16 host prints a drift warning | `struct2.py V-19` (NEW, HEAD-generated document + its own digest) | Survived — first reload `exit 0, stderr empty`, record then equals the on-disk digest; second reload silent |
| AC-19 | a `zh` value lost a placeholder or a pre-existing one was edited | `struct3.py V-20`, `ast`-extracted `TRANSLATIONS` (NEW) | Survived — exactly 10 new pairs, placeholder sets equal, no `失败：`, no `ls.*` shape, **0 removed and 0 pre-existing `zh` values changed** |
| AC-20 | the two READMEs drifted apart, or a sentence claims a fallback | `struct3.py V-21` + `C-10 ceiling` (NEW) | Survived — both 332 lines, heading/fence/table-row skeletons at identical line numbers, `### IPv6 …` at `:113` in both; K-16 greps hit only the denials (`There is no second resolver and no wait to configure` / `这里没有第二个解析器`); exactly one Chinese changelog bullet under `### 新增` |
| AC-21 | the `ipv6` row is misaligned in `HELP_ZH` (wide characters) | `struct3.py V-22` (NEW) | Survived — description at display column `30` in `HELP_EN` and `HELP_ZH`, identical to the neighbouring `default-tun` row in both |
| AC-22 | with an `override.json` present, an `sc`-authored fault blames the user | `struct3.py V-23`, 4 runs (NEW) | Survived — both `sc`-overlay faults render `…/config.json` and never `override.json`; a scalar `dns.rules` (C-5) and malformed JSON still render `…/override.json` |
| AC-23 | an added line uses post-3.6 syntax and the bar-column count hid it (RES-3) | `struct1.py V-24` (NEW) | Survived — `py_compile exit 0`; `--numstat = 272 added / 12 deleted`; 20 patterns × 284 lines → **0 hits**; `ast`: no `NamedExpr`/`Match`/pos-only |
| AC-24 | this report's own size trips F.6 into a FAIL | `bash .harness/scripts/verify_all.sh` | Survived — see `## verify_all result` |

Four adversarial tests of my own, outside the numbered plan:

| id | Hypothesis | Reproducer | Outcome |
|---|---|---|---|
| ADV-1 | **the candidate's green is the fixture's, not the fix's** — this rig cannot observe a stall at all | `beh.py adv`, candidate build, `ipv6 on`, node accepts-never-answers (NEW) | **Stalls, as predicted** — `no answer, 15030.8 ms`, `[10.0s] dns: exchange failed for t16-nomatch.org. IN AAAA: context deadline exceeded`, `rule0.query_type == [64, 65]`. The rig *can* see a stall; every candidate green above is therefore non-vacuous on the candidate side as well as the HEAD side |
| ADV-2 | types 64/65 behave identically at HEAD and candidate, so the changelog's `global`/`direct` claim is unearned | `beh.py adv`, TYPE65 in clash mode `direct` (NEW) | **HEAD fails, candidate holds** — candidate `NOERROR ans=0`, no stub touched; HEAD `direct_stub=[['t16-nomatch.org', 65]]`, `ans=1`. The claim is earned |
| ADV-3 | index 0 does not really precede `hosts_dns` / the domestic rule / the rule-set rules | `beh.py adv`, AAAA of `doh.pub`, `360.cn`, `www.google.com`, `probe-x.test` (NEW) | Survived — all four `NOERROR ans=0`, `8.7–18.5 ms`, **no stub recorded anything** |
| ADV-4 | a 253-byte name, a 63-byte label, punycode or 40 concurrent AAAA queries break the predefined answer | `beh.py adv` (NEW) | Survived — all three name shapes `NOERROR ans=0 ≤18.7 ms`; 40 concurrent AAAA: `40/40 NOERROR`, answers `[0]`, worst `51.2 ms`, whole batch `75.0 ms`, both stubs untouched |

## Boundary tests added

- Null/absent: `settings.json` absent; the `ipv6` key absent; `IF_INET6_PATH` removed; zero nodes; `rules/` empty; no `config.json` at all (BC-11).
- Malformed: `settings.json` not valid JSON; `ipv6: "yes"`; `/proc/net/if_inet6` as prose; raw non-UTF-8 bytes; non-UTF-8 inside a kernel-shaped line; a UTF-16-encoded kernel line.
- Encoding/size: a 63-byte label, a 253-byte name, a punycode IDN — all under suppression.
- Case and vocabulary: `sc ipv6 ON|Show|BOGUS|yes` — lower-cased like every other subcommand, unknown values exit non-zero and write nothing (BC-21).
- Concurrency: 40 parallel AAAA queries through one instance under suppression.
- Address-source traps: a `2000::/3` address on `sb-tun` **only** (must not count), and one on `enp3s0` (must count).
- Node states: accepts-never-answers, refuses, usable, zero nodes — each staged at the `proxy` **outbound**.
- Routing modes × rule-set states: all 3 × 2 for the class measurement and for AC-B7.
- **C-11 — limits of the behavioural evidence (boundaries deliberately *not* crossed).** No behavioural run exercises the shipped document's TUN capture path; nor `route.rules[0]`'s `{"outbound":"direct","process_name":["sing-box"]}` rule; nor the real DoH transport for `remote_dns` (derived to plain UDP, DR-4 — M-5 leaves DoH-versus-UDP unestablished and nothing here rests on it); nor T-15's `proxy` selector / `auto` urltest group (staged away per DR-5). The shipped document itself is evidenced only by V-3's differential and V-7's real `sing-box check`.
- **C-10 / RES-4 — BC-14 is UNOBSERVED, not green.** Nothing here tests whether a node whose address resolves only to AAAA becomes unreachable under suppression, and `route.default_domain_resolver` (`bin/sc:1158`) argues it may not. Checked instead that no shipped text claims more than "a node whose address resolves only over IPv6 needs `sc ipv6 on`" — one sentence in each README, no mechanism stated.
- Probe-method boundary found here: `dig … ANY` uses TCP, and the fixture inbound is UDP-only, so an `ANY` probe returns `connection refused` in ~16 ms and measures the harness, not the document. `MX`/`TXT` of the same name behave as the no-rule class (`12 017 ms`, node-dependent). Recorded so no future round reads an `ANY` row as a result.

## verify_all result

- Command: `bash .harness/scripts/verify_all.sh`
- Baseline before this report landed: `PASS: 17  WARN: 0  FAIL: 0  SKIP: 1`
- After this report landed: `PASS: 17  WARN: 0  FAIL: 0  SKIP: 1`
- Total tests: 17 verify_all steps → 17 (this task ships no committed test; out-of-scope item 8, R-9 owns one)
- Pass: 17
- Fail: 0
- Warn: 0
- Skip: 1 (`B.3` Lint — the pre-existing SKIP, unchanged)
- E.6 with this report present: PASS (`^##\s+Adversarial\s+tests` matched)
- F.6 doc-size: PASS — the V-25-predicted WARN did **not** fire; this report is under the 500-line cap and so is every other active task document
- New checks added by me: 36 structural assertions + 11 behavioural scenarios + 4 adversarial scenarios, all in throwaway harness files, none committed
- Baseline updated: **no** — `.harness/scripts/baseline.json` still reads `test_count: 0 / passing_count: 0 / warnings_baseline: 0`. Nothing may go up: this task commits no test (out-of-scope item 8), `verify_all`'s step count is unchanged at 17/0/0/1, and `.harness/**` is outside NFR-3's permitted diff. No operator obligation was created, so `.harness/operator-obligations.md` is untouched.

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| QA-1 | MINOR | Seed a fixture `settings.json` holding `{"lang","mode","update_interval"}` and **no** `clash_api_port`, then run `_resolve_clash_port()` (the start-up path every `sc ipv6` form takes): the file is rewritten and gains `clash_api_port`. With a malformed `settings.json` it is rewritten to that single key, dropping `lang`/`mode`. `struct3.py` → `ADV CR-10`. The shipped sentence scopes the write to "on a fresh host" / "全新机器上", so a user on an established host reads "`sc ipv6 show` writes nothing" and is wrong. This is CR-10's residue, now observed rather than argued. Fix is one clause, exactly as CR-10 proposed: "on a fresh host, **or on any host that has not yet recorded a Clash API port**". **Route: developer.** Not blocking — C-4's prohibition is satisfied (no text claims the command is write-free), behaviour is unchanged from HEAD, and the residue is precision, not a false capability claim | `README.md:124`, `README.zh-CN.md:124`, `CHANGELOG.md:7` (`bin/sc:345-369`) |
| QA-2 | MINOR | Generate with `ipv6: auto` on a host with no global IPv6 (document gets `[28,64,65]`), then give the fixture `IF_INET6_PATH` a `2000::/3` address on `enp3s0` and run `sc ipv6 auto`: stdout reads `AAAA queries are resolved normally (setting: auto — … global IPv6 address on enp3s0)` **and** `Nothing changed — the sing-box service was not touched`, while `config.json` still carries `query_type: [28, 64, 65]`. `struct3.py` → `ADV CR-6`. Carried, not new: this is CR-6 / RES-2 reproduced. The code matches FR-5/Q-9/I-10 and AC-6 forbids the obvious "fix"; BC-13 is the line that did not anticipate the repair path. `sc ipv6 off` and `sc reload` repair it. **Route: requirement-analyst (BC-13).** Not blocking | `bin/sc:2471-2473` (BC-13, `01_REQUIREMENT_ANALYSIS.md`) |
| QA-3 | NIT | `sc ipv6 auto` with `IF_INET6_PATH` removed prints the FR-7 warning **twice** (`stderr_lines=2`) because `cmd_ipv6` calls `ipv6_decision()` on both sides of the comparison. This is CR-4, design-sanctioned by `02_RATIONALE.md` R-8 and observed by no numbered step until now; recorded so it is a known, priced consequence rather than a surprise. No change asked for | `bin/sc:2463-2467` |
| QA-4 | NIT | In the FR-7 case `sc ipv6 show` puts only `IPv6 name resolution → auto` on **stdout**; the effective decision reaches the user only inside the stderr line. Confirmed: `stdout='IPv6 name resolution → auto', stderr_lines=1`. This is CR-9, design-sanctioned by I-5/V-12. No change asked for | `bin/sc:1552`, `bin/sc:2458-2461` |

No BLOCKER, CRITICAL or MAJOR defect was found. Also re-checked and **not** defects: C-3's class text (every clause of both READMEs' per-mode table was reproduced by my own measurement, including the degraded-state shrink); K-16 (no surface claims a fallback or a wait); RES-8/RES-9 (`_load_lang()`'s non-UTF-8 traceback — pre-existing, outside this diff, carried to `07`).

## Stability

- Structural suites (`struct1.py`, `struct2.py`, `struct3.py`) run **3 times each**: `15 pass / 0 fail`, `11 pass / 0 fail`, `10 pass / 0 fail` on every round. No flakes.
- The AC-B1 fixture was rebuilt and re-measured **10 times** from scratch (new `mkdtemp` root, new ports, new sing-box process, a distinct query name per round so no cache can be measured): 10/10 rounds identical outcomes, worst wall clock **23.9 ms** against a 100 ms bound.
- AC-B4 / AC-B6 (candidate + both defect-reproducing HEAD controls) were run twice end-to-end: round 1 `19.7/18.3/18.6 ms` candidate, HEAD `15030/15031 ms` + `direct` non-suppression; round 2 `19/19/19 ms`, HEAD `15031/15021 ms` + `direct` non-suppression. Identical classification both times.
- Two harness defects were found and fixed **in the harness** during stabilisation, neither in `bin/sc`: an unstubbed `_egress_ip()` made `cmd_status` hit the network and differ between the two revisions, and a case-sensitive assertion on the new help sub-lines. Both are recorded in `06_RATIONALE.md` so the fix is not mistaken for a product change.
- Live-service witness, checked at every scenario boundary and after the last run: `MainPID=2566751 | ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` — identical to the value recorded at stage 4, never restarted. `systemctl show`, never `is-active`. No `PUT`/`PATCH`/`DELETE` reached `127.0.0.1:29090`; every mode change went to the fixture's own controller on its own port. `ps` after the last run shows exactly one `sing-box` process, the live one; no fixture instance, stub or listener survives.
- `/usr/local/bin/sc` was never invoked; `/usr/local/bin/sc.bak-2026-08-01-1006` was never read, restored or deleted; `_init_files()` was never driven; all eight path constants were repointed into one `mkdtemp()` root and asserted inside it on every load; `SYSTEMD = OPENRC = False` throughout.

## Verdict

APPROVED FOR DELIVERY
