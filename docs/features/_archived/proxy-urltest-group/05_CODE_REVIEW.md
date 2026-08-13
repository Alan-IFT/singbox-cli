> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `bin/sc`
- `README.md`
- `README.zh-CN.md`
- `CHANGELOG.md`
- `docs/dev-map.md`
- `docs/features/proxy-urltest-group/01_REQUIREMENT_ANALYSIS.md`
- `docs/features/proxy-urltest-group/02_SOLUTION_DESIGN.md`
- `docs/features/proxy-urltest-group/03_GATE_REVIEW.md`
- `docs/features/proxy-urltest-group/04_DEVELOPMENT.md`
- `.harness/rules/70-doc-size.md`, `.harness/rules/50-singbox-cli.md` (conventions)
- `/usr/local/bin/sing-box` (read-only, symbol presence only — C-6 adjudication)

Not reviewed, per dispatch: `docs/tasks.md`, `docs/batches/**`. No rationale sibling was
opened: no T5.x trigger fired (no adjudicated `DESIGN DRIFT`, no reuse/risk finding needing
`02_RATIONALE.md`, and every identifier this document acts on — C-1…C-9, K-1…K-18, I-1…I-19,
Q-1…Q-6, RS-1…RS-6 — is defined in a contract portion).

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | MINOR | Spec/design-fidelity | `bin/sc:1637` via `bin/sc:1673` | `stored_delays()` cannot raise on its own, but `clash_api()` can: `json.loads(text)` is inside the `try` that catches only `URLError`/`HTTPError`, so a 2xx body that is not JSON (BC-9's fourth state, "port answering but not sing-box") raises `ValueError` — and `.decode()` a `UnicodeDecodeError` — through `stored_delays()` into `cmd_ls()`. AC-24/AC-25's "no traceback, no Python exception text" therefore holds for every *malformed JSON* body (all 15 shapes V-15 exercised) but not for a *non-JSON* one. Not the developer's to fix: `clash_api()` is frozen (AC-28) and K-12 forbids the local `try`/`except`, so the gap is upstream. `sc status:1877` carries the same exposure at HEAD and `sc doctor` is immune only because `cmd_doctor:2202-2209` wraps each probe. Reachability is narrow (sing-box running while a *foreign* HTTP server holds the persisted Clash port) and no fix is available inside this task's constraints; carried as RES-1. |
| CR-2 | MINOR | Spec/design-fidelity | `bin/sc:1543` vs `bin/sc:1560` | `cmd_rm` keeps HEAD's `active == removed_tag` guard (`bin/sc:1832`), so removing the **last** node while `active == AUTO_TAG` does not fire it; the repair is deferred to `generate_config()`. Q-2 licensed that shape on the premise that the repair "persists before anything downstream can fail" — true only *downstream of the override parse*: `_load_override()` runs at `:1543`, before the repair at `:1560-1564`, and an `OverrideError` there aborts the command (rendered at `:2664`). A host with a malformed `override.json` is therefore left holding `active: "auto"` with zero nodes. No document is emitted in that run, so AC-3/AC-4/AC-10 are not violated on any emitted output, and the next successful generation repairs it; `sc ls`/`sc now` are unaffected in kind (HEAD has the same deferral for any hand-edited stale value). Self-healing, no action required. |
| CR-3 | NIT | Standards-conformance | `README.md:94-98`, `README.zh-CN.md:94-98` | The sample table reproduces the header *text* verbatim but not the emitted column widths — `cmd_ls:1755` pads the name field to 30 and the address field to 25, the sample shows roughly 10 and 15. Legitimate for a README (the real line is ~90 columns), but `04_DEVELOPMENT.md`'s "verbatim rather than a prettified one" claims more than the artifact delivers. Mirrored identically in both files, so AC-34 is unaffected. |
| CR-4 | NIT | Standards-conformance | `README.md:9-15`, `README.zh-CN.md:9-15` | The `✨ Features` list still ends at "Hot node switch" and does not name automatic failover, which is now the headline behaviour. L-13/L-14 scoped the README edits to `### Switch node`, the new section and the roadmap, so this is outside the design's own ledger — an opportunity, not a violation. |
| CR-5 | NIT | Standards-conformance | `bin/sc:2501-2503`, `bin/sc:2560-2562`, `README.md:82`, `README.md:89`, `README.zh-CN.md:82`, `README.zh-CN.md:89` | The literal `auto` appears in help and prose. K-1/FR-2 bind *consumers* (code that decides), and every one of those reads `AUTO_TAG` (`bin/sc:52` is the sole definition; grep confirms no second code literal), so the constraint holds. Recorded only so a future rename of `AUTO_TAG` knows the six documentation sites that do not move with it. |

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 | `bin/sc:1426-1434` (the one `urltest`), members `list(node_tags)`, `direct` never among them | ✅ |
| AC-2 | `bin/sc:1438` — `([AUTO_TAG] if auto else []) + node_tags + ["direct"]` | ✅ |
| AC-3 | `bin/sc:1440` `default` = `_valid_selection(...) or "direct"`, whose every branch returns a member of `:1438`'s array | ✅ |
| AC-4 | group members = node tags (`:1429`); `dns`/`route` references untouched (`bin/sc:1100-1137`); `_filter_rules` unchanged | ✅ |
| AC-5 | `bin/sc:1414` `auto=False` at zero nodes ⇒ `:1438` collapses to `["direct"]`, `:1448` to `[selector, direct]`, `:1440` to `"direct"`; key order of the selector matches E-1's HEAD quote | ✅ by construction (K-5) |
| AC-6 | `_unique_tag:1728` (no node may mint a reserved tag) + `_auto_group_emitted:1371` second clause (no group where a node already holds the tag) | ✅ |
| AC-7 | `generate_config:1538-1607` contains no outbound literal; the group reaches the document only through `_runtime_overlay:1447` `$replace` | ✅ |
| AC-8 | `cmd_use:1794-1798` — `is_running()` → one `PUT` → print → `return` before any service call | ✅ |
| AC-9 | `bin/sc:1561` `if repaired != active:` — `_valid_selection` returns `AUTO_TAG` unchanged when the group is emitted, so N runs write nothing (K-7) | ✅ |
| AC-10 | `cmd_rm:1832-1836` → `reload_or_restart()` → repair at `:1560-1564` yields `active=None` and the zero-node document | ✅ (CR-2 names the one abort path) |
| AC-11 | `_unique_tag:1728` — `tag not in RESERVED_TAGS` in the first-hit test, so `#auto` mints `auto #2` | ✅ (K-3: in the minter, not the call site) |
| AC-12 | `cmd_use:1783-1786` — the reserved arm is decided before `_resolve_node()` is reached at `:1790` | ✅ |
| AC-13 | `_resolve_node:1700-1720` — 21 lines, substring fallback and all three error sentences intact | ✅ |
| AC-14 | real `sing-box check`, 7 documents — developer's V-4 (harness evidence, not re-runnable here) | ✅ evidenced; QA re-verifies |
| AC-15 | `02` K-14/K-15; V-19 not run (C-3) | ⚠️ carried to QA — RES-3 |
| AC-16 | `bin/sc:1430-1433` emit exactly I-9…I-12; `interrupt_exist_connections` absent per I-13; no other key | ✅ |
| AC-17 | Emitted shape passes the real checker (V-4); no file under `/etc/sing-box` is read for hand-editing | ✅ evidenced |
| AC-18 | `_warn_drift()` at `bin/sc:1591` still precedes the write at `:1595`; both sides describe the pre-replacement file | ✅ |
| AC-19 | `_record_generated()` at `bin/sc:1600`, only after a successful write | ✅ |
| AC-20 | `sc update-rules` path untouched by the diff | ✅ evidenced (V-12) |
| AC-21 | C-4's counting proxy on `restart_service()`; `restart_service`/`reload_or_restart` (`bin/sc:1609-1620`) are HEAD's shape, so no restart is suppressed by construction | ✅ |
| AC-22 | `cmd_use:1795-1800` — `clash_api` returns `None` on the 4xx, falls through to `reload_or_restart()`, selection already persisted at `:1793` (K-10) | ✅ |
| AC-23 | live host, `sc ls` after one interval | ⚠️ carried to QA — RES-3 |
| AC-24 | `stored_delays:1671-1695` returns `({}, None)` on every handled path; `_delay_cell:1751` renders `-` | ✅ except CR-1's non-JSON body |
| AC-25 | `bin/sc:1676-1694` — six `isinstance` gates, no `try`/`except`, `bool` excluded, `0` excluded (K-12) | ✅ except CR-1 |
| AC-26 | `bin/sc:1751` — `"-"` versus `"<n> ms"`, never `0`, never blank | ✅ |
| AC-27 | `bin/sc:1671` `if not is_running(): return {}, None` — inside the function (K-11), before any socket | ✅ |
| AC-28 | `bin/sc:1635` `timeout=3` intact; the file's only `timeout` tokens are 8 s / 30 s / 3 s (pre-existing) and the group's `idle_timeout` key at `:1433` | ✅ |
| AC-29 | `bin/sc:1673` — the sole new call is `clash_api("GET", "/proxies", …)` | ✅ |
| AC-30 | `cmd_ls:1742-1744` returns before `stored_delays()` is reached | ✅ |
| AC-31 | `cmd_ls:1765` `enumerate(nodes, 1)` — the group row at `:1763` prints `{'':>4}`, entering no index space; the five leading cells of header and node row are byte-prefixes of HEAD's | ✅ |
| AC-32 | `verify_all` PASS 16 / WARN 1 / FAIL 0 / SKIP 1; no FAIL (C-9 supersedes the stated baseline) | ✅ |
| AC-33 | `bin/sc:191` `"Delay": "延迟"`, no placeholder either side, no `失败：`; the five `ls.*` keys at `:183-187` untouched | ✅ |
| AC-34 | both READMEs 305 lines; all 24 headings and all 5 roadmap rows align 1:1; C-2 blockquote at `:103` and C-8 paragraph at `:101` in both | ✅ (CR-3 is a NIT on the sample only) |
| AC-35 | f-strings only, no walrus/dataclasses/`capture_output=` added, stdlib only | ✅ |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| I-1 `AUTO_TAG = "auto"` | `bin/sc:52`, sole code literal | ✅ |
| I-2 `RESERVED_TAGS = frozenset(("proxy", "direct", AUTO_TAG))` | `bin/sc:56`, built from I-1 | ✅ |
| I-3 `_auto_group_emitted(node_tags)` | `bin/sc:1355-1371`; four consumers (`:1394`, `:1414`, `:1757`, `:1785`), never re-spelled | ✅ |
| I-4 `_valid_selection(active, node_tags)` | `bin/sc:1374-1396` — the four clauses in the declared order; pure (no file, no print, no write) | ✅ |
| I-5 `stored_delays(port=None) -> (delays, current)` | `bin/sc:1651-1695`; no `sc ls`-specific argument, prints nothing, one `GET` | ✅ |
| I-6 group object, key order as written | `bin/sc:1426-1434` — `type, tag, outbounds, url, interval, tolerance, idle_timeout` | ✅ |
| I-7 selector | `bin/sc:1435-1442` — `type, tag, outbounds, default, interrupt_exist_connections: True` | ✅ |
| I-8 `outbounds` array | `bin/sc:1447-1449` through the existing `$replace` | ✅ |
| I-9…I-12 parameter values | `bin/sc:1430-1433` — `generate_204` over https, `3m`, `50`, `30m` | ✅ |
| I-13 `interrupt_exist_connections` omitted on the group | absent from `bin/sc:1426-1434`; still `True` on the selector at `:1441` | ✅ |
| I-14 `"Delay" → "延迟"`, an English-sentence key | `bin/sc:191`, preceded by the comment that says why it is not a sixth `ls.*` | ✅ |
| I-15 consumed envelope | `bin/sc:1676-1694` — `history[-1]["delay"]` only when `int`, not `bool`, `> 0`; `current` only from a non-empty `str` `now` on the `AUTO_TAG` entry | ✅ |
| I-16 header cell appended last | `bin/sc:1755-1756` — HEAD's five cells byte-identical, then `"  " + f"{t('Delay'):>9}"` | ✅ |
| I-17 node row cell | `bin/sc:1768-1769` + `_delay_cell:1750-1751` | ✅ |
| I-18 group row | `bin/sc:1757-1764` — first, empty idx, `●` iff `active == AUTO_TAG`, type `urltest`, address `→ <current>` else `-` | ✅ |
| I-19 `sc use` call flow | `bin/sc:1777-1800` — reserved arm, then HEAD's apply path verbatim | ✅ |
| K-1 / K-2 | one literal; no flag, env var or parameter gates the group | ✅ |
| K-3 / K-5 / K-7 / K-8 / K-10 / K-11 / K-12 | `:1728` · `:1448` · `:1561` · `:1560`,`:1818`,`:1834` · `:1793` before `:1794` · `:1671` · `:1676-1694` | ✅ |
| K-4 no one-node special case | `bin/sc:1371` is `bool(node_tags)`, not `len(node_tags) > 1` | ✅ |
| K-6 node already tagged `auto` | `bin/sc:1371` second clause; no warning printed anywhere; documented at `README.md:103` / `README.zh-CN.md:103` | ✅ |
| K-9 `_resolve_node` unchanged | `bin/sc:1700-1720` | ✅ (structural — see RES-2) |
| K-13 no timeout added or changed | `bin/sc:1635`; file-wide `timeout` grep shows only the three owner-directed waits + `idle_timeout` | ✅ |
| K-14 / K-15 no `domain_strategy`, DNS untouched | no `domain_strategy` anywhere in the emitted outbounds; `CONFIG_BASE.dns` and `route.default_domain_resolver` (`bin/sc:1118`) intact | ✅ |
| K-16 no doctor row, no `/delay`, no ranking | `# doctor` block untouched; no `/proxies/` path other than `:1673` and HEAD's `:1795` | ✅ |
| K-17 help alignment | `bin/sc:2501-2503` / `:2560-2562` — descriptions at column 30, sub-options at 32, CJK width counted (zh `use` line measures 22 display columns + 8 spaces) | ✅ |
| K-18 CHANGELOG | `CHANGELOG.md:7`, Chinese, under the existing `## [Unreleased]` → `### 新增`, no new version heading | ✅ |
| L-16 dev-map | `docs/dev-map.md:30`, `:37`, `:39`, `:56` (Q-5 `$replace` note), `:57`, `:58` — two new reusable-utility rows as `04` declares | ✅ |
| Frozen set | `_resolve_node`, `clash_api`'s `timeout=3`, `_merge`/`_directive_of`/`_apply_directive`/`DIRECTIVES`, `_write_private`, `cmd_now`, `cmd_status`, `_warn_drift` and its ordering, the five `ls.*` keys, `CONFIG_BASE.dns`, `route.default_domain_resolver` — each read at source and matching the HEAD shape `01`/`02`/`03` describe | ✅ structural; byte-identity delegated — RES-2 |
| C-6 disposition (`interrupt_exist_connections` kept omitted) | the emitted document is unchanged, and the inference the decision rests on is sound: `/usr/local/bin/sing-box` carries the external-connection context symbols, and `interrupt.(*Group).Interrupt(bool)` skips only connections flagged external, closing internal ones — so the internally dialled DoH transport is torn down on re-selection regardless | ✅ adjudicated, no drift |

## Axis status
- **Standards-conformance:** 3 findings (CR-3, CR-4, CR-5), worst = NIT. Repo conventions hold — one definition per fact, WHY-comments only, no dead code, no premature abstraction (`stored_delays`' `port` parameter is I-5's stated contract, not speculation), 3.6 floor and stdlib-only respected, bilingual parity exact, non-TTY contract preserved (no `\r`, one line per entry, and the right-aligned last cell removes the trailing whitespace HEAD's rows carried), doc-size caps respected, and the two READMEs are 1:1 structural mirrors. No invented rule is asserted anywhere in this document.
- **Spec/design-fidelity:** 2 findings (CR-1, CR-2), worst = MINOR. All 35 ACs are accounted for (33 satisfied in code, 2 — AC-15/AC-23 — carried to QA by C-3, as the design itself directs); every I-1…I-19 shape and every K-1…K-18 constraint holds as written; no design drift, silent or declared. The two findings are boundary states the contracts named but modelled slightly more favourably than the code delivers; neither is fixable inside the frozen set and neither changes an emitted document.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-1 | CR-1: a non-JSON 2xx body on the Clash port raises out of `clash_api()` into `sc ls`. Worth one adversarial case (a stub answering `200 text/html`) and, if confirmed, a follow-up pool row against `clash_api()` — not against this diff. | `06_TEST_REPORT.md` (`## Adversarial tests`), then `07_DELIVERY.md` |
| RES-2 | Byte-identity of the frozen set is asserted by stage 4 and verified here only structurally — this reviewer holds no diff capability. One `git diff` restricted to the eleven frozen anchors closes it. | `06_TEST_REPORT.md` |
| RES-3 | C-3 stands: V-19 is unrun, so AC-15/AC-23 rest on K-14/K-15 plus the design's evidence. QA records it as not-run-and-why, or runs it by a route that issues no `PUT`/`PATCH`/`DELETE`. | `06_TEST_REPORT.md` |
| RES-4 | C-6's conclusion is an inference from symbol presence plus sing-box's interrupt semantics, not a live observation. If QA ever reaches a real re-selection on the live host, one observation of DNS surviving it would retire the inference. | `07_DELIVERY.md` |
| RES-5 | RS-3 carried unchanged: `delay == 0` and never-probed both render `-`. Known, accepted, not re-reported. | `07_DELIVERY.md` |
| RES-6 | CR-3/CR-4: the README sample table is condensed rather than byte-exact, and the Features list does not yet name automatic failover. Both are cosmetic and mirrored. | `07_DELIVERY.md` |

## Verdict
APPROVED
