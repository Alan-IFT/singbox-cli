> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `/home/alan/Programs/singbox-cli/bin/sc`
- `/home/alan/Programs/singbox-cli/README.md`
- `/home/alan/Programs/singbox-cli/README.zh-CN.md`
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/docs/features/doctor-extended-checks/01_REQUIREMENT_ANALYSIS.md`
- `/home/alan/Programs/singbox-cli/docs/features/doctor-extended-checks/02_SOLUTION_DESIGN.md`
- `/home/alan/Programs/singbox-cli/docs/features/doctor-extended-checks/04_DEVELOPMENT.md`
- `/home/alan/Programs/singbox-cli/.harness/rules/70-doc-size.md`

## Findings

| id | severity | axis | file:line | finding |
|---|---|---|---|---|
| CR-2 | MINOR | Spec/design-fidelity | `bin/sc:2637` | The AAAA membership test `_aaaa_rule(suppress) in rules` is **position-blind**, while `_dns_overlay()`'s own contract is that **index 0 is what makes the suppression mode-independent** (`bin/sc:1690-1694`, `docs/dev-map.md:61`: measured, at index 3 types 64/65 were *not* suppressed in `direct` mode). A `config.json` carrying the rule at a later index — a document from a pre-T-16 build, or one an override reordered — reads `[OK] … config.json carries this decision` while the decision is not in force in `global`/`direct`. Not developer drift: FR-4 and I-6 both specify a membership test. Deliberately not fixed at round 2 (it needs a design decision this stage may not take); travels as RES-1. |
| CR-3 | MINOR | Spec/design-fidelity | `bin/sc:2781-2795` | The DNS row can be answered from the running install's **own DNS cache** (`experimental.cache_file`, `bin/sc:1235` region), and the name it asks for is the one `_egress_ip()` resolves in the same command (Q-13's shared literal), so every `sc doctor` / `sc status` run warms it. Inside the answer's TTL (228 s measured in P-2a) the row reads `[OK] … resolved in {ms} ms, through the running sing-box` on a host whose resolution through the tunnel is broken — the failure the row exists to catch. The row's words remain literally true and the window is TTL-bounded, so this is a residual and not a wording defect. Deliberately not fixed at round 2; travels as RES-2. |
| CR-8 | INFO | Standards-conformance | `bin/sc` (whole diff) | Undeclared-growth arithmetic **re-closes exactly, with no slack, at the reworked candidate**: measured against every round-1 shipped line, the per-region shifts sum to **+6** (`_egress_ip()` docstring +1 · `ipv6_decision()` docstring +1 · the `_plain()` wrap's line break +1 · the clean-host comment +3), giving **+294 net**, which is precisely the declared `+331/−37`. Every anchor's shift equals the cumulative additions above it and nothing else, so there is no budget anywhere for a hidden helper, cap, flag or constant. Module-level inventory re-enumerated: the only constants this task adds are still `RULESET_STALE_DAYS` (`:102`) and `EGRESS_HOST` (`:454`); the only new function is still `_aaaa_rule()` (`:1670`); `_age_seconds()` is still correctly absent. Full anchor table in `05_RATIONALE.md` §1. |
| CR-9 | INFO | Standards-conformance | `.harness/rules/70-doc-size.md` | The fragment still defines no `## Stage-doc boundary rule` (**R-37**; re-checked at round 2 — the file's headings are `What this is` / `When to read this` / `Caps` / `Process discipline` / `Adversarial check`). Per this stage's contract I applied the review schema exactly as written and carried the arithmetic chain, the CR-1 closure proof and the per-row R-22 interrogation in `05_RATIONALE.md`; this row is the record, in place of an invented section. |
| CR-10 | MINOR | Standards-conformance | `04_DEVELOPMENT.md` (12 citations) | The rework's line citations were **not re-based** after the round-2 edits: `## Files changed` names `_aaaa_rule` `:1668` (shipped `:1670`), `_doctor_rulesets` `:2487` (`:2489`), `_doctor_config` `:2531` (`:2533`), `_doctor_ipv6` `:2598` (`:2600`), `_doctor_clash` `:2710` (`:2712`), `_doctor_permissions` `:2808` (`:2811`), `DOCTOR_SECTIONS` `:2890` (`:2896`), CR-5's wrap `:2769` (`:2772`); GC-3 names `:2828`/`:2850` (`:2831`/`:2853`); GC-10 names `:2841`/`:2864` (`:2844`/`:2867`); D-5 names `:2861` (`:2864`); and the one coordinate written **this** round — "the CR-1 comment at `:2874-2878`" — is `:2878-2882` shipped. The substance is correct in every case; only the coordinates are stale, so this is weaker than round 1's CR-6 (which mis-stated behaviour). It still costs stage 6 a re-derivation of every fixture anchor. Travels as RES-10. |
| CR-11 | INFO | Spec/design-fidelity | `bin/sc:2883-2885` vs `:2864` | After the CR-1 narrowing the OK sentence is now marginally **narrower** than the check rather than wider: the predicate flags any regular file directly inside `/etc/sing-box` except `settings.json`, so a stray non-credential file at 0644 is still reported PROBLEM while the clean-host sentence promises only about *credential* files. That is the safe direction (an under-promise can produce no false `[OK]`), and closing it inside the row would mean naming the exclusion on a healthy host, which BC-20 and NFR-3 forbid. Recorded, no action. |
| CR-12 | INFO | Spec/design-fidelity | `bin/sc:335-336`, `:1636-1639`, `:2772`, `:460-462`, `:2878-2885` | Round 1's five actionable findings verified closed **at the code**, not only in the record. CR-1: the key pair is `"no credential file grants access to group or other, and the directory is not group- or other-writable"` / 「没有凭据文件对同组或其他用户开放，目录本身也不可被同组或其他用户写入」, both halves placeholder-free and matched, mirrored at `README.md:268`+`:279`, `README.zh-CN.md:268`+`:279` and `CHANGELOG.md:7` — and the **check is byte-unchanged** (`:2841` `dir_mode & 0o022`, `:2864` `stat.S_ISREG(mode) and entry.name != "settings.json" and mode & 0o077`), so the repair landed on the sentence and never on the predicate. CR-4: docstring and `docs/dev-map.md:57` both read three callers; `ipv6_decision()`'s body (`:1650-1667`) is unchanged in length and unreachable by the round's arithmetic. CR-5: `current=_plain(current or t("(none)"))`, and `stored_delays()` guarantees `current` is `None` or a non-empty `str` (`:2181`), so the wrap adds no failure mode and the empty-`current` path still renders the pre-existing `(none)` / 「（无）」. CR-6: GC-10's disposition now states what shipped. CR-7: `_egress_ip()`'s docstring sources the literal to `EGRESS_HOST` and keeps the still-true 8 s half. |

## Requirement coverage check

| criterion | implementation | status |
|---|---|---|
| FR-1 rule-set age from the one reader's timestamp, one renderer | `bin/sc:2506` (`mtime` off the 6-tuple), `:2518` `_age_text(mtime)`, rendered on **every** row at `:2521`/`:2523`/`:2526`; no `os.stat`/`getmtime`/`st_size` on any rule-set path | ✅ |
| FR-2 stale = usable ∧ age ≥ one named 60-day constant, PROBLEM + refresh command | `bin/sc:102` `RULESET_STALE_DAYS = 60`; `:2508-2516`; `:2523` names `sc update-rules` | ✅ |
| FR-3 drift from the single judgement, three states | `bin/sc:2547-2556`, `_drift_state()` unmodified; `True`⇒PROBLEM naming `OVERRIDE_PATH`, `False`⇒OK, `None`⇒UNKNOWN | ✅ |
| FR-4 effective AAAA decision + does the document carry it | `bin/sc:2619-2642`; the sentence is `ipv6_decision()`'s own, no fifth string | ✅ (position-blind — CR-2) |
| FR-5 stored delays, persisted port, no fresh-measurement claim | `:2732` `_saved_clash_port()`, `:2765` `stored_delays(port=port)`, `:2769-2770` "history, not a fresh measurement" | ✅ |
| FR-6 one measured DNS fact, no configured-timeout claim | `:2781-2795`; elapsed measured around the one call on all three branches; no row names a timeout | ✅ |
| FR-7 wide modes in the config dir + the dir's own write bits | `:2811-2891`; `mode & 0o077` files, `mode & 0o022` dir, `settings.json` the one exclusion; **the clean-host sentence is now exactly as wide as the check** (`:2883-2885`, `TRANSLATIONS` `:335-336`) | ✅ (was CR-1) |
| FR-8 every added PROBLEM row names a next step on the same line | stale `:2523`, drift `:2553`, AAAA `:2641`, node delays `:2775`, DNS `:2786`/`:2794`, permissions `:2872` + per-path `chmod` at `:2843`/`:2866`; OK rows carry none; UNKNOWN rows name what could not be established | ✅ |
| FR-9 Clash PROBLEM asserts no unobserved cause | `:2748` `"no usable answer from {addr}"`; the old key is absent from `TRANSLATIONS` | ✅ |
| FR-10 grammar, classes, markers, exit mapping unchanged | `:2394-2399`, `_doctor_print()` `:2909-2919` untouched; `DOCTOR_EXIT` `:2398` = `{0:0, 1:2, 2:1}` | ✅ |
| FR-11 order decided in one table, one reader | `DOCTOR_SECTIONS` `:2896-2906`, sole reader `cmd_doctor` `:2925` | ✅ |
| FR-12 six precedence pairs | drift≺check `:2556`→`:2591`; AAAA≺DNS (table order 4≺7); DNS≺egress (7≺8); Clash rows≺node delays `:2740`,`:2751`→`:2763`; node delays≺egress; permissions last `:2905` | ✅ |
| FR-13 process-wide read-only, no `_init_files()` / `_resolve_clash_port()` | call graph unchanged this round; no writer, no `mkdir`, no non-GET; `main()`'s `if args.cmd in ("doctor", "config")` arm (`:3646`) byte-unchanged | ✅ |
| FR-14 both READMEs, CHANGELOG, dev-map | `README.md:256-280`, `README.zh-CN.md:256-280`, `CHANGELOG.md:7`, `docs/dev-map.md:31,40,50,57,60,61,70` | ✅ (CR-4's stale row now corrected) |
| AC-S1 each fact stands on its owner's call | four owner calls consumed verbatim; no independent path exists | ✅ (behavioural half is GC-5, stage 6) |
| AC-S2 no second opinion | no `st_size`, no second rule-set timestamp, no second `config.json` digest, **one** Clash exception envelope (no `try` around either new `clash_api()` call), **one** `ipv6_decision()` call site in the block | ✅ |
| AC-S3 one ordering table + FR-12 in output | `DOCTOR_SECTIONS` sole reader; row order verified inside `_doctor_config` / `_doctor_clash` / `_doctor_permissions` | ✅ |
| AC-S4 no writer reachable | as FR-13 | ✅ |
| AC-S5 every new key an English sentence with a matching-placeholder zh entry, no `失败` | `TRANSLATIONS` is **line-neutral across the rework** (`EGRESS_HOST` still `:454`), so the count is still 28 added / 3 deleted; the replaced pair at `:335-336` is placeholder-free on both halves and carries no `失败`; no new `ls.`-style key | ✅ |
| AC-S6 no timeout/exit/grammar change | `timeout=8` `:466`, `timeout=30` `:1121`, `timeout=3` `:2122` unchanged; `DOCTOR_EXIT` `:2398` unchanged | ✅ |
| AC-S7 diff touches only declared files | not verifiable at this stage (no shell); `git status` + `--numstat` is stage 6/7's read | ⏸ deferred |
| AC-S8 no credential byte in any row | new code reads modes and one JSON document; the only rendered values are the decision sentence, counts, a measured ms, paths and octal modes | ✅ |
| AC-S9 one constant, one reader, above the longest preset | `:102` defined, `:2511` the only reader; 60 > monthly | ✅ |
| AC-B1…AC-B13 | behavioural; discharged on stage 4 fixtures, re-run owned by stage 6. Statically consistent with the shipped code in every branch traced, including the reworked clean-host branch | ⏸ stage 6 |
| AC-B14 shipped invocation as root on the live host | not obtainable under K-18 | ❌ BLOCKED (filed, RES-3) |

## Design fidelity check

| design item | implementation | status |
|---|---|---|
| I-1 `RULESET_STALE_DAYS`, one reader, `>= days*86400` | `:102`, `:2511` | ✅ |
| I-2 `EGRESS_HOST`, request URL byte-identical | `:454`; `:466` `urlopen("https://" + EGRESS_HOST, timeout=8)`; two consumers (`:466`, `:2782`) | ✅ |
| I-3 `_aaaa_rule(suppress)`, `_dns_overlay()` one call, bytes unchanged | `:1670-1681`, `:1701`; keys/values/order preserved; V-11 byte proof is stage 4's | ✅ |
| I-4 age on every row, stale iff usable ∧ mtime ∧ threshold, no new row | `:2506-2530`; summary text unchanged | ✅ |
| I-5 drift row computed first, returned on all three paths | `:2547`, `:2562`, `:2566`, `:2567` | ✅ |
| I-6 AAAA probe | shipped per **D-1/GC-2**, not per I-6's formula — adjudicated at round 1, unchanged | ✅ (drift accepted) |
| I-7 node-delay row | `:2752-2777`; `stored_delays` sits in the `else` of the `try`, so its exceptions are not swallowed by the nodes guard; the auto-select tag is now `_plain()`ed (`:2772`) | ✅ |
| I-8 DNS row | `:2781-2795`; `clash_api` guarantees `dict`-or-`None`, so `lookup.get` cannot raise | ✅ |
| I-9 permission probe | `:2811-2891`; `CFG_DIR.stat()` follows, per-entry `lstat()` does not; links never followed, sub-dirs never descended, cap + existing overflow key. **Predicates byte-unchanged across the rework** | ✅ |
| I-9 / I-16 clean-host sentence | narrowed to *credential* file (`:335-336`, `:2883-2885`) and mirrored in both READMEs and `CHANGELOG.md`; recorded as **D-5** | ✅ (drift accepted — ordered by round-1 CR-1) |
| I-10…I-16 zh entries | 28 added, 3 deleted; the round-2 replacement is one pair for one pair, line-neutral | ✅ |
| I-17 `DOCTOR_SECTIONS` **exactly two** new entries, no reordering | `:2896-2906`, 9 entries in the declared order | ✅ |
| I-18 order inside the probes | verified row-by-row | ✅ |
| K-1 no second Clash envelope | no `try` around either `clash_api()` call; the envelope inside `clash_api()` is still the only one | ✅ |
| K-2 both rows only on the `/configs`-answered branch | `:2733-2750` return early with no request | ✅ |
| K-3 / GC-3 mode reads scoped | exactly two: `CFG_DIR.stat()` `:2831`, `entry.lstat()` `:2853`; the only other `os.stat` in the file is `_load_override()`'s pre-existing `:1447` | ✅ |
| K-5 / V-11 emitted bytes unchanged | `_aaaa_rule()` is pure and reproduces the literal | ✅ |
| K-6 one `ipv6_decision()` per run | call-site read of the whole block: `ipv6_decision(` = 1 (`:2619`), `_dns_overlay(` = 0, `_aaaa_rule(` = 1 (`:2637`). D-4's warning holds — the neighbouring grep hits are docstring | ✅ |
| K-7 one guarded document read | `:2623-2634`; `isinstance` at every level below the top (`:2636`) | ✅ |
| K-8 no writer, GET only | verified | ✅ |
| K-9…K-12 permission predicates, exclusion, cap | `:2841`, `:2860`, `:2864`, `:2886-2890` | ✅ |
| K-13 `_egress_ip()` untouched but sourced | `:466`; its docstring now names `EGRESS_HOST` and keeps the 8 s clause | ✅ |
| K-14 strings | see AC-S5 | ✅ |
| K-15 no timeout / wall-clock claim in any row | no row text contains `3s`, "timeout" or a bound | ✅ |
| K-16 nothing else moves | re-verified against the frozen set: `DOCTOR_EXIT`, `DOCTOR_MARK`, `_doctor_print()`, `main()`'s read-only arm, the three socket timeouts, `stored_delays()`, `_drift_state()`, `ipv6_decision()`'s body | ✅ |
| GC-1 row-level clauses | structurally +5 rows on a healthy host (16→21) and no new OK row names a path or a next step; the reworked OK sentence names no path | ✅ (evidence re-run is stage 6) |
| GC-2 | as K-6 | ✅ |
| GC-3 | as K-3, both sanctioned reads at `:2831` / `:2853` | ✅ |
| GC-4 | fixture-rig condition; stage 4/6 evidence | ⏸ stage 6 |
| GC-5 | explicitly stage 6's | ⏸ stage 6 (RES-8) |
| GC-6 P-2 verbatim | ran; body is a JSON object with a non-empty `Answer`; the PROBLEM branch's body copied from P-3 | ✅ |
| GC-7 lstat-`OSError` and non-object `dns` decided | `:2854-2859` skip-and-continue; `:2636` isinstance ⇒ PROBLEM (PQ-3) | ✅ |
| GC-8 README "changes nothing" amended | `README.md:272` / `README.zh-CN.md:272`; exactly as wide as the behaviour, FR-13's claim not widened to cover the service | ✅ |
| GC-9 age on a usable, non-stale row | `:2518` renders unconditionally; the phrase is on the OK branch at `:2526` | ✅ |
| GC-10 `_plain()` coverage | every `{e}` ✅; every filesystem-sourced path ✅; the one API-sourced value ✅ (`:2772`); checker output plained wholesale in `_doctor_run()` (`:2456`); mode strings are `"%03o" % int` this code formats itself — met **by construction**, and the record now says so in those words | ✅ (was CR-6) |
| D-1 membership test via `_aaaa_rule(suppress)` | adjudicated at round 1: correct and mandatory under GC-2 | ✅ |
| D-2 cause slot filled with an existing key | `"the top level must be a JSON object"` at `:351`; no new key | ✅ |
| D-3 block header "seven"→"nine facts" | `:2382-2388`; comment only | ✅ |
| D-4 AST sweep instead of substring grep | verified independently; every grep hit inside the block is docstring | ✅ |
| D-5 clean-host sentence scoped to *credential* files | the drift this stage ordered; sentence narrowed, check untouched, both languages and all three prose surfaces moved together | ✅ |
| Rule 85 "less is more" — are the seams load-bearing? | `_aaaa_rule()` yes; `EGRESS_HOST` yes; `_age_seconds()` correctly absent. The rework added **no** seam: no new function, constant, flag or cap anywhere in the +6 | ✅ |

## Axis status
- **Standards-conformance**: 3 findings (CR-10 MINOR; CR-8, CR-9 INFO), worst = **MINOR**. The rework obeys this repo's conventions: it invented no rule, added no constant/helper/flag, left `DOCTOR_SECTIONS` with one reader and the three timeouts and the exit mapping untouched, kept the docstring house style, changed no shell script (cross-shell parity unaffected), and the growth chain re-closes with no slack. The one MINOR is documentation coordinates, not behaviour.
- **Spec/design-fidelity**: 3 findings (CR-2, CR-3 MINOR; CR-11, CR-12 INFO — CR-12 is a closure record, not a defect), worst = **MINOR**. Every FR including FR-7's row text is now satisfied at a named line; the round-1 MAJOR is closed at the code with the check byte-unchanged in both the file and the directory predicate; all five recorded drifts (D-1…D-5) are correct and argued; the two remaining MINORs are pre-existing residuals no upstream stage owned.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | The AAAA membership test is position-blind, while index 0 is what makes the suppression mode-independent; a document carrying the rule at a later index reads `[OK]` (CR-2). | `07_DELIVERY.md` as a follow-up pool row |
| RES-2 | The DNS row can be served from the install's own DNS cache, whose entry for that very name is warmed by the egress probe in the same run — a TTL-bounded false `[OK]` (CR-3). | `06_TEST_REPORT.md`, then `07_DELIVERY.md` as a pool row |
| RES-3 | AC-B14 — `sc doctor` as root on the live host — is not obtainable under K-18 and is **BLOCKED**, never substituted. | `07_DELIVERY.md`, PM |
| RES-4 | RS-2 reproduced: a host with no init system but a live Clash API reads `0/{total}` on the node-delay row, because `stored_delays()`' internal `is_running()` returns `False`. | `07_DELIVERY.md` as a pool row |
| RES-5 | RS-3 / RS-4 stand as gated (F-12/F-14): a document from an older build, or a user override replacing `dns.rules` wholesale, reads PROBLEM on the AAAA row. | `07_DELIVERY.md` as pool rows |
| RES-6 | A group- or other-writable **sub-directory** (`/etc/sing-box/rules`) is never judged — BC-19 forbids descending — so a host on which anyone can plant a `.srs` still reads `[OK] file permissions`. Accepted boundary, unowned. | `07_DELIVERY.md` as a pool row |
| RES-7 | RS-5 (R-38, `sc status`'s zh separator), RS-6 (the two glossary terms), RS-7 (the `doctor-dns-row-by-a-host-side-lookup` rejected-decision record) are unchanged and still unwritten by any stage. | PM, at task close |
| RES-8 | GC-5's four deletion tests are stage 6's and are explicitly not discharged at stage 4; GC-1, GC-4 and the new V-9.5 / V-17c fixture evidence must be re-run and quoted, not inherited. | `06_TEST_REPORT.md` |
| RES-9 | R-37: `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule`, re-checked at this stage's round 2. | PM |
| RES-10 | `04_DEVELOPMENT.md`'s line citations were not re-based after the round-2 edits (twelve of them off by +2/+3/+6; substance correct throughout) — stage 6 must re-derive fixture anchors from the file rather than inherit them (CR-10). | `06_TEST_REPORT.md`, PM |
| RES-11 | The `git diff --numstat` figures (`bin/sc +331/−37`) are the developer's declaration; this stage holds no shell and verified the shipped line **geometry** instead, which pins the round's growth at exactly +6 and leaves no room for an undeclared unit. The numstat itself is re-read at delivery under AC-S7. | `07_DELIVERY.md` |

## Verdict
APPROVED WITH MINOR — CR-10 (`04_DEVELOPMENT.md`'s stale line citations, a documentation fix), plus CR-2 and CR-3, which are deliberately unfixed row-level residuals travelling as RES-1 / RES-2; no CRITICAL and no MAJOR on either axis, round 1's CR-1 closed at the code with the permission check byte-unchanged, and the undeclared-growth chain re-closing exactly at +294 net.
