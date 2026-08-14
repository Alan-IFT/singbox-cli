> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

Upstream contract portions read in full: `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`,
`03_GATE_REVIEW.md`, `04_DEVELOPMENT.md`, `PM_LOG.md`. Rationale siblings opened on triggers T5.1,
T5.2 and T5.3 — see `05_RATIONALE.md`. `.harness/rules/70-doc-size.md` carries no
`## Stage-doc boundary rule` section, so this schema is applied as written and the reasoning behind
the findings, the drift adjudications and the method limit live in `05_RATIONALE.md`.

## Files reviewed
- `/home/alan/Programs/singbox-cli/bin/sc`
- `/home/alan/Programs/singbox-cli/README.md`
- `/home/alan/Programs/singbox-cli/README.zh-CN.md`
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/docs/features/dns-resilience/04_DEVELOPMENT.md`
- `/home/alan/Programs/singbox-cli/docs/features/dns-resilience/04_RATIONALE.md`

## Findings

| id | severity | axis | file:line | finding |
|---|---|---|---|---|
| CR-4 | NIT | Standards-conformance | `bin/sc:2463-2467` | `sc ipv6 auto` calls `ipv6_decision()` twice, so on a host whose address source cannot be read the FR-7 stderr line prints twice in one command. Already anticipated and **accepted** by the architect (`02_RATIONALE.md:37`, R-8) as the price of not creating a second entry point; recorded here only so stage 6 is not surprised by it, since no numbered step observes the pair. |
| CR-6 | MINOR | Spec/design-fidelity | `bin/sc:2471-2473` | BC-13's sanctioned staleness has an unsignalled repair path. Both sides of the comparison are computed from the *current* host, never from the document on disk (correctly — reading it back would create the second opinion AC-6 forbids). So on a host whose IPv6 state changed after generation, `sc ipv6 auto` prints "Nothing changed — the sing-box service was not touched" and leaves a document that contradicts what `sc ipv6 show` just printed; in the harmful direction (host lost its global address) the 10 s stall persists. `sc ipv6 off` and `sc reload` both repair it. Route to requirement-analyst — the code matches FR-5/Q-9/I-10 exactly; BC-13 is the line that did not anticipate the repair path. |
| CR-8 | MINOR | Spec/design-fidelity | `bin/sc:1778-1782` | DR-1's third `path` site is correct **today** only by the argument in its own comment ("It cannot fire when there is no override — every overlay `sc` composes leaves all three arrays"), not by call structure — which is the property K-7, `OverrideError`'s docstring (`:1062-1081`) and `docs/dev-map.md:38` all claim for the mechanism. A future `sc`-authored overlay that broke one of the three arrays would blame `override.json`. Gating the guard on `override is not None` would make the attribution structural at zero behavioural cost. Not blocking — C-5 mandated the site and V-23 verified both directions. Route to solution-architect for the K-7 text at delivery. |
| CR-9 | NIT | Standards-conformance | `bin/sc:1552`, `:2458-2461` | In the FR-7 (detection-failed) case `sentence` is `None`, so `sc ipv6 show` puts only "IPv6 name resolution → auto" on **stdout**; the effective decision reaches the user only inside the stderr warning. Design-sanctioned by I-5 and accepted by V-12, so no change is asked for — noted because a user capturing stdout alone sees a setting with no decision. |
| CR-10 | MINOR | Spec/design-fidelity | `README.md:124`, `README.zh-CN.md:124`, `CHANGELOG.md:7` | The start-up-path disclosure is correct and unqualified ("like every command except `sc doctor`, it still runs the ordinary start-up path first"), but the *write* it then describes is scoped to "on a fresh host". `_resolve_clash_port()` (`:345-369`) also probes and persists on **any** host whose `settings.json` records no valid `clash_api_port` — its own comment (`:357-359`) names installs predating the port auto-probe as the hosts the branch exists for — and when that file is unreadable or malformed it is rewritten to a single key, dropping whatever else it held. C-4 is satisfied (no text claims `sc ipv6 show` is write-free as a command), so this is precision rather than a violation: one clause — "on a fresh host, or on any host that has not yet recorded a Clash API port" — closes it in all three texts. |

## Requirement coverage check

| criterion | implementation | status |
|---|---|---|
| AC-B1 | V-26, TYPE64 probe per C-1; `04:201`, transcript in `04_RATIONALE.md` | ✅ recorded at 4; stage 6 re-observes |
| AC-B2 | V-27 (`04:202`) | ✅ recorded at 4 |
| AC-B3 | V-28 (`04:203`) | ✅ recorded at 4 |
| AC-B4 | V-29 + V-36 non-vacuity (`04:204`, `:211`) | ✅ recorded at 4 |
| AC-B5 | V-30 (`04:205`) | ✅ recorded at 4 |
| AC-B6 | V-31 against C-2's corrected text (`04:206`) | ✅ recorded at 4 |
| AC-B7 | V-32, 36 combinations, 0 mismatches (`04:207`) | ✅ recorded at 4 |
| AC-B8 | V-33 (`04:208`) | ✅ recorded at 4 |
| AC-B9 | V-34, 0-node fixture (`04:209`) | ✅ recorded at 4 |
| AC-B10 | V-35; 3 defect-reproducing controls exhibited their defect, 7 agreement controls matched (`04:210`) | ✅ recorded at 4 |
| AC-1 | `bin/sc:1580-1583` — `{"action": "predefined", "rcode": "NOERROR", "query_type": [28, 64, 65]}`, no `answer` key | ✅ |
| AC-2 | `bin/sc:1582` — `[64, 65]` in that order when not suppressing | ✅ |
| AC-3 | `$prepend` on `dns.rules` (`:1580`) ⇒ index 0, ahead of `:1136`/`:1137` and every `remote_dns` rule | ✅ |
| AC-4 | The emitted rule carries no `rule_set` key; `_filter_rules()` keeps it at `:903-907` before any other branch | ✅ |
| AC-5 | V-7 — real `sing-box check`, exit 0 in all six states | ✅ |
| AC-6 | One definition `:1524`; callers `:1579` and `:2458`/`:2463`/`:2467`; no third reader of `settings["ipv6"]` (`:1460`) or `IF_INET6_PATH` (`:1488`); deletion test in V-10 | ✅ |
| AC-7 | No `timeout`-shaped key emitted anywhere; the only `timeout=` arguments in `bin/sc` are `:380`, `:1014`, `:1841` — three sites, values 8 / 30 / 3, no fourth; the one new module constant is `IF_INET6_PATH` (`:62`) | ✅ |
| AC-8 | `DIRECTIVES` `:1089`, `_directive_of` `:1196`, `_anchor_index` `:1222`, `_apply_directive` `:1245`, `_merge` `:1273`, `_load_override` `:1318` — all below the round-2 edit, unchanged in position and shape | ✅ shape verified here; byte-identity on V-8's `ast` transcript (RES-1) |
| AC-9 | `_egress_ip` `:380` = 8, `_fetch_to_temp` `:1014` = 30, `clash_api` `:1841` = 3, each line read in full, never decided by `grep` | ✅ values verified here; diff half on V-9 (RES-1) |
| AC-10 | `generate_config()` `:1725-1813` — no dict literal added, guard still the three keys at `:1778`; source-level step V-3(b) added under C-8 | ✅ |
| AC-11 | `cmd_ipv6()` `:2437-2476`, all four forms return/exit 0; V-12's eight runs | ✅ |
| AC-12 | `:2457-2462` — `show` writes no file, opens no socket, applies nothing | ✅ as scoped by C-4; the shipped text now states the scope, with the residual precision note CR-10 |
| AC-13 | `:2471-2473` — equal decisions ⇒ return before `reload_or_restart()`; V-14 | ✅ |
| AC-14 | `:2474-2476`; V-15 witness fired exactly once | ✅ |
| AC-15 | `_ipv6_setting()` `:1454-1465` — absent file, absent key and unrecognised value all yield `auto`, only the third writes one stderr line naming file, key and the three values | ✅ |
| AC-16 | `_global_ipv6_iface()` `:1511-1515` — `(first & 0xE0) != 0x20` plus `lo`/`TUN_IFACE` exclusion by name; V-17's four fixtures | ✅ |
| AC-17 | `:1487-1499` (`OSError` **and** `UnicodeDecodeError`) + `:1516-1520`; V-18 extended to five sources × two languages with a 12-of-20 non-vacuity control | ✅ — the "never raises" invariant is now total on this path |
| AC-18 | V-19 — first `sc reload` on a pre-T-16 host succeeds, no drift warning, second reload silent | ✅ |
| AC-19 | `TRANSLATIONS["zh"]` `:169-183` — ten pairs, placeholder sets identical, no `失败：`, no `ls.*` shape; the CR-5 branch reuses `"unreadable"` (`:194`), so the budget is untouched | ✅ |
| AC-20 | `README.md:113-138` / `README.zh-CN.md:113-138`, both files 332 lines with matching headings; `CHANGELOG.md:5-7` Chinese bullet under `### 新增`; the three corrected sentences are accurate against I-17's table, C-4, C-10 and K-16 | ✅ — CR-10 is a precision residue, not a false claim |
| AC-21 | `HELP_EN:2767-2770` and `HELP_ZH:2830-2833`, description at column 30, sub-options at 32, wrap at 39; no write-free claim in either block | ✅ |
| AC-22 | Wrapper at `:1734-1738`, user merge at `:1765-1771`, guard at `:1778-1782`, render at `:2934-2936`; V-23's four runs | ✅ |
| AC-23 | Added regions use no syntax above 3.6 and no new import (read directly); V-24 re-run over the reconciled added set — 272 added / 12 deleted, plus an `ast` pass that is count-independent | ✅ — the added-line count is reconciled (RES-3) |
| AC-24 | PM re-ran `verify_all` independently: PASS 17 / WARN 0 / FAIL 0 / SKIP 1 | ✅ |

## Design fidelity check

| design item | implementation | status |
|---|---|---|
| L-1 `IF_INET6_PATH` after `RESERVED_TAGS` | `bin/sc:57-62`, eighth repointable constant | ✅ |
| L-2 ten Q-15 pairs in the settings block | `:165-183` | ✅ |
| L-3 `OverrideError.path = None` | `:1062-1081`, default `None` not `CFG_PATH` | ✅ |
| L-4 delete the base `query_type` element, nothing else | `:1138-1141` (comment in its place); `servers`, `final`, the other seven rules and their order intact | ✅ |
| L-5 four new functions above `_runtime_overlay()` | `:1439`, `:1468`, `:1524`, `:1562` | ✅ |
| L-7 provenance wrapper + `_dns_overlay()` in the composition | `:1734-1738`, `:1765-1771` | ✅ |
| L-8 `cmd_ipv6()` after `cmd_mode()` | `:2437-2476` | ✅ |
| L-9 `ipv6` subparser + handler | `:2882`, `:2912` | ✅ |
| L-10 handler renders `e.path or CFG_PATH` | `:2934-2936`, comment replaced by what `path` means | ✅ |
| L-11 help row in both blocks | `:2767-2770`, `:2830-2833` | ✅ |
| L-12/L-13 README sections, mirrored | `README.md:113-138` / `README.zh-CN.md:113-138`, both 332 lines, corrected sentences mirrored at `:122`, `:124`, `:136` | ✅ |
| L-14 one Chinese changelog bullet | `CHANGELOG.md:7`, carrying the same two corrections | ✅ |
| L-15 dev-map rows | `docs/dev-map.md:30`, `:37`, `:38`, `:40`, `:56`, `:57`, `:127`, `:133` | ✅ |
| L-16 the developer's stage doc | `04_DEVELOPMENT.md` | ✅ |
| I-4 "never raises; prints nothing" | `:1487-1499` catches `OSError` **and** `UnicodeDecodeError`; `int(x, 16)`'s `ValueError` caught at `:1508`; `fields[5]` guarded by the `len(fields) != 6` continue | ✅ total on this path |
| I-5 `ipv6_decision()` is THE definition | `:1524-1559`; two callers; nothing re-derives | ✅ |
| I-6 `_dns_overlay()` is the ONE place it reaches the document | `:1562-1583`; `$prepend` only; emits no other key | ✅ |
| I-7 the rule, its shape, its index-0 position, no `rule_set` | `:1580-1583` + `_filter_rules:903-907` | ✅ |
| I-11 user's document applied last, at its own named site | `:1765-1771`; `_compose()` signature intact (`:1382`) | ✅ |
| I-12 provenance a property of the call structure | `:1737`, `:1770`, `:1781`, `:2935` | ⚠️ MINOR — CR-8 (third site rests on an argument, not on structure) |
| I-16 `dns.final` byte-identical `remote_dns` | `:1148` | ✅ |
| I-17 index order and the class it produces | V-5's four states; V-26(b)'s per-mode measurement; the READMEs' table `:130-134` states it as the conditional it is | ✅ |
| K-1 / K-3 / K-5 / K-13 | one decision function; base copy deleted in the same edit; `dns.servers` untouched incl. `detour: proxy` (`:1122`); `final` untouched | ✅ |
| K-6 / K-17 | `DIRECTIVES` still five members (`:1089`); no new wait constant; three socket waits unmoved | ✅ |
| K-7 two `path` sites and nowhere else | three sites | ⚠️ drift DR-1 — **legitimate**, mandated by C-5, which states K-7 incomplete; residue is CR-8 |
| K-8 stream split and `_plain()` on OS text | `:1463` and `:1549` to stderr, `:2459`/`:2461` to stdout; `_plain()` at `:1552`, `:1557` | ✅ |
| K-9 exactly ten strings, reuse where one exists | ten (`:169-183`); `Reload failed` and `Cannot use {path}: {problem}` reused; `"unreadable"` reused at two sites (DR-3) | ✅ — DR-3 legitimate at both sites |
| K-10 read-only opt-out arm untouched | `:2903-2908`, `doctor` still the sole member, no `READ_ONLY_COMMANDS`; V-13(b) observes it statically | ✅ |
| K-11 `ast`, never `grep`, for the freeze checks | V-8/V-9 `ast`-based; this review read each of the three `timeout=` lines in full | ✅ |
| K-14 / K-15 fixture constraints | recipe `04:108-166` — both stubs local, `sniff` ahead of `hijack-dns`, `default_domain_resolver` kept | ✅ |
| K-16 no fallback resolver, no configured wait in any user-facing text | greps over `README.md`, `README.zh-CN.md`, `CHANGELOG.md` for `fallback` / `回退` / `second resolver` / `第二个解析器` / network-request claims: within this feature's text the only hits are the **denials** at `README.md:138`, `README.zh-CN.md:138` and their changelog mirror; `不发网络请求` no longer occurs anywhere in the tree | ✅ re-checked against the corrected text |
| C-4's ceiling on `sc ipv6 show` text | `README.md:124` / `README.zh-CN.md:124` / `CHANGELOG.md:7` claim only that it changes no `ipv6` setting, regenerates nothing and touches no service, then state the start-up path outright | ✅ — with CR-10's precision residue |
| C-10's ceiling on BC-14 text | `README.md:138` / `README.zh-CN.md:138` / `CHANGELOG.md:7` say no more than "a node whose address resolves only over IPv6 needs `sc ipv6 on`"; byte-unchanged by this round | ✅ |
| C-3's class text vs measurement | `:122`'s three per-mode clauses restate the table V-26(b) measured and V-32 confirmed per name; `:136` rests on V-27, V-26(b) and V-32's degraded-state row; the stall clause names exactly V-29's class | ✅ no clause exceeds a numbered step |
| Frozen set — merge machinery, three socket waits, `_runtime_overlay`, `dns.servers`/`final`/other rules, `log`, `route`, `_filter_rules`, `_write_private`/`load`/`save_settings`, opt-out arm, doctor block, installer files | read in the working tree; shapes and values unchanged, positions unaffected by the round-2 edit | ✅ here; byte-identity on V-8/V-9 (RES-1) |
| Verification preamble — "three derivations and no fourth"; *usable* = a `direct` outbound tagged `proxy` | four declared derivations (DoH→UDP), and *usable* staged as a `selector` over `direct` | ⚠️ drift DR-4/DR-5 — **both legitimate**: C-7 required the transport derivation to be declared, and the design's staging is measurably unrunnable while the selector form is what `_runtime_overlay()` itself emits at zero nodes; no behavioural claim is weakened |

## Axis status
- **Standards-conformance: 2 findings, worst = NIT** (CR-4, CR-9 — both design-sanctioned, no change asked for). Repo conventions hold: 3.6 floor and stdlib only (18 post-3.6 patterns × 272 added lines, 0 hits, plus a count-independent `ast` pass), stdout/stderr split, `⚠️` outside `t()`, no `en` table and every new key readable as English prose, no `ls.*` key, no new `失败：`, exactly ten new strings with the CR-5 branch reusing an existing key, dev-map updated in the same change, both help blocks aligned, both READMEs line-for-line mirrors at 332 lines, doc-size caps respected. The added-line bookkeeping is reconciled: 272 added / 12 deleted by `--numstat`, and `--stat`'s bar column is changed lines, not added ones — no added line was ever outside V-24's scan. No invented rule was applied; every finding cites an upstream line or a repo rule.
- **Spec/design-fidelity: 3 findings, worst = MINOR** (CR-6, CR-8, CR-10). All 34 acceptance criteria have an implementation or a recorded observation; every ledger, interface and constraint id is honoured; the five drift rows are each legitimate corrections of an upstream error, none a convenience. The two MAJORs this axis carried are closed at their source: C-4's prohibition is satisfied in both languages and in the changelog, and the class sentence is now bounded per routing mode and by what V-29 measured. Two of the three remaining MINORs are routed upstream rather than to the developer.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | This review held no shell in either round: AC-8/AC-9 byte-identity against HEAD and NFR-3's diff confinement were verified by reading the working tree and by `04:49`'s `--numstat` record, V-8/V-9's `ast` transcript and the PM's `git` check, not by an independent extraction here. | `06_TEST_REPORT.md` |
| RES-2 | CR-6 — after the host's IPv6 state changes, `sc ipv6 auto` reports "Nothing changed" while the emitted document contradicts `sc ipv6 show`. Observed by no criterion; `sc ipv6 off` / `sc reload` repair it. | `06_TEST_REPORT.md`, `07_DELIVERY.md` |
| RES-3 | The `bin/sc` added-line count is **272** (`git diff --numstat`'s first field) with 12 deleted; `--stat`'s bar column (284) counts changed lines and is not an added-line count. V-24 covered 272 added and 284 added∪deleted plus a count-independent `ast` pass, so stage 6 re-runs it against 272/12 and does not re-derive a scope from a bar column. | `06_TEST_REPORT.md` |
| RES-4 | BC-14 stays unobserved (RS-3): C-10's ceiling is respected in the shipped text (`README.md:138`, `README.zh-CN.md:138`, `CHANGELOG.md:7`, no mechanism stated), and stage 6 must record the claim as unobserved rather than green. | `06_TEST_REPORT.md` |
| RES-5 | C-11's evidence limits and RS-9's shortfall against the batch goal are untouched by this review and still travel: no behavioural run exercises TUN capture, `route.rules[0]`'s `process_name` rule, the real DoH transport or T-15's selector/auto-select group. | `06_TEST_REPORT.md`, `07_DELIVERY.md` |
| RES-6 | CR-8 — K-7's "provenance is a property of the call structure" is now true of two sites out of three; the architect should either amend K-7 or gate the array guard on `override is not None`. | `07_DELIVERY.md` |
| RES-7 | The `.test`/`geosite-private` trap is contained — no shipped artifact or claim depends on it — and survives only as `04:272`'s insight row, which must reach the harvest. | `07_DELIVERY.md` |
| RES-8 | `_load_lang()` (`bin/sc:312-314`) catches `(FileNotFoundError, json.JSONDecodeError, OSError)`, so a non-UTF-8 `settings.json` reaches the user as a traceback from `main()` before any command runs, `sc doctor` included. Adjudicated **pre-existing and out of T-16's scope**: the path predates this task, `save_settings()` emits pure ASCII and every documented `ipv6` value is ASCII, so no new user is put on it, and BC-10 defines the target as "the behaviour every other setting already has on that host", which this parity satisfies. Open row, not a charge; the repo's own fix shape is `bin/sc:1712`'s `(OSError, ValueError)`. | `07_DELIVERY.md` |
| RES-9 | The class RES-8 names is repo-wide and **prescribed**: `_ipv6_setting()` (`:1454-1457`) and `_saved_clash_port()` (`:337-340`) carry the same catch tuple, and I-3 specifies it verbatim. So a fix belongs with `_load_lang()`'s and with the architect, not with this task's developer; `04:275`'s insight row is its carrier to the harvest. | `07_DELIVERY.md` |

## Verdict
APPROVED (0 CRITICAL, 0 MAJOR; 3 MINOR and 2 NIT, none blocking) — **stage 6 may proceed**: CR-1 and CR-2 are closed at their source in all three texts and in both languages, CR-5's invariant is now total, CR-7 is retired as a units mismatch that was never a defect, and the remaining findings are two upstream routings, two design-sanctioned notes and one precision residue that changes no behaviour and no interface.
