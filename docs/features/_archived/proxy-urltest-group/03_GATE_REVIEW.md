> Contract portion. Rationale: 03_RATIONALE.md (absent = none written).

Mode: **full**. Upstream `01_REQUIREMENT_ANALYSIS.md` verdict **READY** (no `01_RATIONALE.md` exists);
`02_SOLUTION_DESIGN.md` verdict **READY**; `02_RATIONALE.md` opened for I-13 and K-14 only.
`.harness/rules/70-doc-size.md` has no `## Stage-doc boundary rule` section, so the schema is applied
as written. Every design claim that references existing code was checked at the source; the
verified-good list is in the rationale portion.

## Dimension audit

| # | dimension | verdict | reason |
|---|---|---|---|
| 1 | Requirement completeness | WARN | All 35 ACs name an observable and BC-1…BC-16 are exhaustive for the states `sc` can reach, but no requirement governs what the user is told on a host whose `nodes.json` already holds a node tagged `auto` — the state BC-7 stopped one step short of, and the one place stage 2 had to legislate user-visible behaviour on its own (F-1). |
| 2 | Design completeness | PASS | Every FR-1…FR-15 and every AC-1…AC-35 resolves to a named element: the three new functions I-3/I-4/I-5 carry all new judgment, L-1…L-17 name a file and an anchor line for every edit, and the three calls stage 1 handed forward (D-2, D-4, D-11) are each closed with a stated reason (K-1, K-4, I-9…I-13). |
| 3 | Reuse correctness | PASS | Every cited symbol and line exists as described — the selector at `bin/sc:1356-1363`, the repair at `:1471-1475`, `_unique_tag` at `:1587-1593` with exactly one call site at `:1639`, `clash_api`'s `timeout=3` at `:1546`, the drift ordering `:1502` before `:1506`, the DNS anchors `:1071-1072`/`:1095`/`:1105`, `HELP_EN:2322`/`HELP_ZH:2379`, `README.md:76-84`/`:279`, `CHANGELOG.md:3`/`:5` — and I-15's envelope matches the insight-index truth that `/proxies` serves a stored history with `delay` and no `meanDelay`. |
| 4 | Risk coverage | WARN | The listed risks are the real ones (duplicate tag, stale selection, malformed API body, quiet upgrade), but I-13's omission of `interrupt_exist_connections` on the group is weighed only against throughput connections and not against the DoH transport that `01 §1.2` item 3 makes the headline of the failover promise (F-3). |
| 5 | Migration safety | PASS | There is no data migration to reverse: the config is regenerated and never patched, the U-1 downgrade is genuinely self-healing because HEAD's own `active not in node_tags` branch at `bin/sc:1472-1475` rewrites a persisted `auto`, the quiet upgrade rests on an ordering I confirmed rather than on an assertion, and K-2 correctly refuses the feature flag this change does not need. |
| 6 | Boundary handling | PASS | `_valid_selection()` (I-4) is total over `None`, a node tag, the reserved tag and a hand-edited string with no fall-through; I-15 enumerates every malformed-body shape and K-12 forbids the `try`/`except` that would hide a real defect; the zero-node, last-node-removed, service-stopped and API-unreachable paths each land on a stated element. |
| 7 | Test feasibility | WARN | 30 of 35 ACs have a step that observes what the AC claims, but AC-15's only falsifier is not executable under S-5 as written (F-2), AC-21's step observes AC-20 instead (F-4), AC-31's group-row case and AC-26's mixed-table case are observed by no step (F-5), and K-6 has no step at all (F-1). |
| 8 | Out-of-scope clarity | PASS | The frozen set is anchored file-and-line, every NG-1…NG-13 maps to a K-constraint that forbids the specific edit (K-9, K-13, K-15, K-16), and `## Out of scope` restates the five things a developer would most plausibly over-build — R-19, CJK width, `sc ping`, a doctor row, a persisted history. |

## Findings

| id | severity | owning upstream doc + section | finding |
|---|---|---|---|
| F-1 | major | `01 §5 BC-7` and `§11 D-9`, absorbed by `02 K-6` | On a host whose `nodes.json` already holds a node tagged exactly `auto`, K-6 emits no group and prints nothing, and `sc use auto` there resolves through `_resolve_node()` (`bin/sc:1576`) to that node and prints the byte-identical `Switched to: auto` (`bin/sc:1624`) that selecting the real group prints — so the task's headline feature is absent and its absence is indistinguishable from its presence at the only surface the user consults; no V-row observes this state at all. |
| F-2 | minor | `02` V-19 versus `01 §9 S-5` | V-19, the only step that falsifies K-14, states its precondition as the group being *selected* on the live host, which is reachable only through `sc use auto`'s `PUT /proxies/proxy` — the exact call S-5 forbids against the live API — so AC-15's falsifier as written cannot be run, though AC-15's literal demand (an evidenced answer inside `02`) is already discharged by K-14/K-15. |
| F-3 | minor | `02` I-13 versus `01 §1.2` item 3 | Omitting `interrupt_exist_connections` on the group means an established DoH transport to `remote_dns` (`bin/sc:1071-1072`) through a degraded member is not torn down when the group re-selects, so name resolution can keep riding the failed node after the data plane has moved — the one connection class for which I-13's "let them drain" reasoning inverts. |
| F-4 | minor | `02` V-12 | V-12's observables ("witness identical before/after", the no-change outcome line) discharge AC-20 only; nothing in V-12 or in V-11 — which runs with `SYSTEMD = OPENRC = False`, so `restart_service()` is inert — observes AC-21's claim that a genuinely needed restart still happens. |
| F-5 | minor | `02` V-10, V-15, V-16 | No step renders the `sc ls` table with the I-18 group row present, so AC-31's "including when the auto-select group entry is displayed" is verified by construction only; and no step renders a table mixing known and unknown delays, so AC-26's distinctness claim is never seen on the path FR-12 exists for. |
| F-6 | minor | `01 §10` test 1 versus `§11 D-5` and `02` I-12 | D-5 correctly leaves every upgraded host pinned to its node, so on those hosts the group goes idle and the new column shows `-` everywhere or freezes on values up to one `idle_timeout` old with nothing dating them — the "column that is dishonest on its own" `§10` used to argue the two halves are one task is, on the majority upgrade state, the delivered state. |
| F-7 | note | `02` RS-1 (residual addressed to this document) | Received and carried: nothing was inexpressible through the T-14 layer, and RS-1's observation that a *future* shipped overlay cannot add an outbound while this one `$replace`s the whole array (`bin/sc:1365`) is answered as Q-5 below rather than left to T-16 to rediscover. |

## Binding conditions

| id | condition | owner stage | discharged by |
|---|---|---|---|
| C-1 | The K-6 state — a fixture whose `nodes.json` holds a node tagged exactly `auto` — must acquire a verification step observing AC-3, AC-4, AC-6 and AC-17 there, plus what `sc ls` and `sc use auto` do on it. | stage 4 (developer) | a numbered step in `04_DEVELOPMENT.md` and its result in `06_TEST_REPORT.md` |
| C-2 | The K-6 paragraph L-13/L-14 already owe both READMEs must state that on such a host no auto-select group exists and `sc use auto` pins that node, so the printed `Switched to: auto` there does not mean failover; the mirror requirement of AC-34 applies to it. | stage 4 (developer) | `06_TEST_REPORT.md`'s README mirror check |
| C-3 | AC-15 must end the task either with V-19 run by a route that issues no `PUT`/`PATCH`/`DELETE` to the live API and changes no live service state, or with V-19 recorded as not-run and AC-15 resting on K-14/K-15 alone, stated as such rather than left implied. | stage 6 (QA) | `06_TEST_REPORT.md` |
| C-4 | AC-21 must acquire an observable of its own; V-12 may keep AC-20 but must stop being cited for AC-21. | stage 4 (developer) | `04_DEVELOPMENT.md` verification list |
| C-5 | At least one step must render the `sc ls` table with the group row present and node indices asserted against HEAD, and at least one must render a table mixing known and unknown delays. | stage 4 (developer) | `06_TEST_REPORT.md` |
| C-6 | I-13's omission of `interrupt_exist_connections` on the group must be restated against F-3's DoH-transport case and either kept with that case weighed or changed; if the emitted document changes, V-4 is re-run. | stage 4 (developer) | `04_DEVELOPMENT.md`; re-run of V-4 in `06_TEST_REPORT.md` if the document moves |
| C-7 | RS-4/BC-6 stays open into stage 4: V-4 must record the real `/usr/local/bin/sing-box check` verdict on a hand-made `urltest` with an empty member list, independently of the design having made that state unreachable. | stage 4 (developer) | `06_TEST_REPORT.md` |
| C-8 | Both READMEs must state that the delay figure is a value the running sing-box already held and exists only while the group is in use, so a host pinned to a node showing `-` or an old number is behaving as designed (F-6). | stage 4 (developer) | `06_TEST_REPORT.md`'s README mirror check |
| C-9 | Stage 6's adversarial section heading must match `^##\s+Adversarial\s+tests` unnumbered, and the declare-done bar is `bash .harness/scripts/verify_all.sh` ending with **no FAIL** — AC-32's stated `PASS 17 / WARN 0` baseline is superseded by `PASS 16 / WARN 1 / FAIL 0 / SKIP 1`, the WARN being F.6 on this task's own stage-1 doc. | stage 6 (QA) | `06_TEST_REPORT.md` |

## Pre-answered developer questions

| id | question | answer |
|---|---|---|
| Q-1 | Does routing `cmd_add`'s auto-pick through `_valid_selection()` (K-8/L-10) move an existing host's selection? | No — I-4's first clause returns a valid node tag unchanged, so only a `None` or stale value moves; on a fresh install the first `sc add` therefore yields `auto`, which is D-5's intent, and the five `save_nodes` call sites are `bin/sc:413,1475,1620,1643,1657` with `:1475` the only one inside `generate_config()`. |
| Q-2 | Must `cmd_rm` keep its `if active == removed_tag` guard when L-11 lands? | Either shape satisfies AC-10, because the `reload_or_restart()` `cmd_rm` already calls reaches the I-4 repair at `bin/sc:1471-1475` and persists before anything downstream can fail; what K-8 actually forbids is re-spelling `node_tags[0]`, not the guard. |
| Q-3 | Where does `stored_delays()` get its port when `cmd_ls` calls it with `port=None`? | `main()` assigns `CLASH_PORT = _resolve_clash_port()` at `bin/sc:2466-2468` before dispatching every non-`doctor` command, so `None` is correct from `cmd_ls`; the explicit `port` exists only for `sc doctor`, which deliberately skips that start-up path. |
| Q-4 | A member node whose `server` is a domain rather than an IP — does resolving *that* create BC-12's circularity? | No: a member's own server address is resolved through `route.default_domain_resolver` → `direct_dns` (`bin/sc:1105`, `:1073-1074`), which carries no `detour`; the circular server is `remote_dns` (`bin/sc:1071-1072`) and it is reachable only via `dns.rules`, which a dial-side lookup does not traverse — this is K-15's branch applied to the member rather than to the probe URL. |
| Q-5 | May a future shipped overlay (T-16/T-17) add an outbound without restating the array? | Not while this overlay `$replace`s `outbounds` wholesale at `bin/sc:1365`: a second shipped overlay must either compose into the same `$replace` payload or use an additive directive, and NG-13/D-12 leave R-16 unclaimed, so the additive route is not available today — L-16's dev-map edit is the place this belongs, not a new row. |
| Q-6 | `t('Delay')` renders as two CJK characters in I-16's `:>9` field — is the zh header misaligned? | Yes, by two display columns, and it is accepted: the column is last precisely so nothing after it can shift, and CJK display width is named out of scope; what must not happen is the alternative D-13 rejected — an `ls.delay` key that would print literally in English like the five at `bin/sc:174-178`. |

## Verdict

**APPROVED WITH CONDITIONS** — C-1…C-9 bind stages 4 and 6; no finding routes back to the requirement-analyst or the solution-architect, and no safety red line was reached.
