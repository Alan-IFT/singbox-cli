# 02 — Solution Design · T-15 `proxy-urltest-group`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

Mode: **full**. Upstream `01_REQUIREMENT_ANALYSIS.md` verdict **READY**, read in full; no
`01_RATIONALE.md` exists and no T2.x trigger fired. `.harness/rules/70-doc-size.md` has no
`## Stage-doc boundary rule` section, so the agent schema is applied as written and
`## Byte-form specification` is absent (ungated).

Three design calls are resolved here under the owner's standing authority: **D-2** = `auto`
(K-1), **D-4** = always emit at ≥1 node (K-4), **D-11/AC-16** = the five parameter rows I-9…I-13.
AC-15's answer is K-14/K-15 + V-19.

## Architecture summary

- `bin/sc` gains one reserved outbound tag and one `urltest` outbound (the *auto-select group*),
  emitted by `_runtime_overlay()` as a member of the existing `proxy` selector; `CONFIG_BASE` is
  not touched and `generate_config()` gains no outbound literal, so the seam is the T-14
  composition layer exactly as FR-8 requires.
- Three new module-level functions carry every new judgment — `_auto_group_emitted()` (is the
  group in the document), `_valid_selection()` (FR-6's single judge), `stored_delays()` (FR-11's
  single reader) — and every other edit is a call site of one of them.
- Unchanged: the whole `dns` section, `_merge()` and its directive vocabulary, `_resolve_node()`,
  `clash_api()`, `cmd_now`, `cmd_status`, the `# doctor` block, `install.sh` / `uninstall.sh` /
  `systemd/`, and the emitted document at zero nodes.

## Change ledger

Total over every touched file. `sc` = `/home/alan/Programs/singbox-cli/bin/sc`. Partition column:
this project has no partition developers (see `## Partition assignment`).

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| L-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# Paths`, after `TUN_IFACE` (`sc:47`): add `AUTO_TAG` and `RESERVED_TAGS` (I-1, I-2) | developer |
| L-2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# i18n` `TRANSLATIONS["zh"]`, in the `# ls table headers` block (`sc:173-178`): **one** new pair (I-14) | developer |
| L-3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# Config composition`, immediately above `_runtime_overlay()` (`sc:1342`): add `_auto_group_emitted()` (I-3) and `_valid_selection()` (I-4) | developer |
| L-4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_runtime_overlay()` `sc:1356-1366`: build the group, widen the selector's members, derive `default` through I-4 (I-6, I-7, I-8) | developer |
| L-5 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `generate_config()` `sc:1471-1475`: the stale-active repair becomes a call to I-4 (K-7) | developer |
| L-6 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# Clash API`, after `is_running()` (`sc:1559`): add `stored_delays()` (I-5, I-15) | developer |
| L-7 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_unique_tag()` `sc:1587-1589`: the first-hit test also rejects `RESERVED_TAGS` (K-3) | developer |
| L-8 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `cmd_ls()` `sc:1598-1609`: one `stored_delays()` call, a sixth column, the group row (I-16, I-17, I-18) | developer |
| L-9 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `cmd_use()` `sc:1617-1627`: the reserved-tag arm, decided **before** `_resolve_node()` (I-19, K-10) | developer |
| L-10 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `cmd_add()` `sc:1641-1642`: the auto-pick becomes a call to I-4 (K-8) | developer |
| L-11 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `cmd_rm()` `sc:1655-1656`: the auto-pick becomes a call to I-4 (K-8) | developer |
| L-12 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `HELP_EN:2322` / `HELP_ZH` counterpart: `use <name\|index>` → `use <name\|index\|auto>`, description names the group; column alignment preserved (K-17) | developer |
| L-13 | `/home/alan/Programs/singbox-cli/README.md` | edit | `### Switch node` (`:76-84`) gains `sc use auto` + the group paragraph; `sc ls` delay column documented; roadmap `:279` checked; the `auto`-named-node carve-out documented (K-6) | developer |
| L-14 | `/home/alan/Programs/singbox-cli/README.zh-CN.md` | edit | the same edits at the same line positions — line-for-line mirror (AC-34) | developer |
| L-15 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | one Chinese bullet under `## [Unreleased]` → `### 新增` (`:5`) (K-18) | developer |
| L-16 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | reusable-utilities table gains the I-5 row; `# Config composition` and `# Clash API` section rows name the three new functions | developer |
| L-17 | `/home/alan/Programs/singbox-cli/docs/features/proxy-urltest-group/04_DEVELOPMENT.md` | new | the Developer's own stage doc | developer |

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `bin/sc` module constant | `AUTO_TAG = "auto"` | THE one definition of the auto-select group's tag (FR-2). Every consumer reads it; no consumer spells `"auto"`. Language-neutral, so `sc lang` cannot move it. |
| I-2 | `bin/sc` module constant | `RESERVED_TAGS = frozenset(("proxy", "direct", AUTO_TAG))` | The tags `sc` emits itself and no node may carry (FR-3). Built **from** I-1, so I-1 stays the single definition. |
| I-3 | `bin/sc` function | `_auto_group_emitted(node_tags) -> bool` — true iff `node_tags` is non-empty **and** `AUTO_TAG not in node_tags` | THE single condition "is the auto-select group in the emitted document". Four consumers (I-4, `_runtime_overlay`, `cmd_ls`, `cmd_use`). Never re-spelled inline. |
| I-4 | `bin/sc` function | `_valid_selection(active, node_tags) -> str or None` — returns `active` when `active in node_tags`, else `active` when `active == AUTO_TAG and _auto_group_emitted(node_tags)`, else `AUTO_TAG` when `_auto_group_emitted(node_tags)`, else `node_tags[0]` when `node_tags`, else `None` | FR-6's single judge: total over every persisted value including `None` and a hand-edited string. Pure — reads no file, writes nothing, prints nothing. Its result is always an outbound the same run defines (AC-3/AC-4). |
| I-5 | `bin/sc` function | `stored_delays(port=None) -> (delays, current)` — `delays` is `{outbound_tag: int_ms}`, `current` is `str` or `None` | FR-11's single reader. Prints nothing, writes nothing, issues at most **one** `GET`. Returns `({}, None)` when `is_running()` is false — no request at all (AC-27). `port` is passed straight to `clash_api(port=…)` and exists only to mirror that function's own contract (`sc:1537-1539`), so `sc doctor` can call it unchanged later; it is not an `sc ls` argument (FR-11). |
| I-6 | emitted `config.json` · new outbound | `{"type": "urltest", "tag": AUTO_TAG, "outbounds": [<node tags, nodes.json order>], "url": …, "interval": …, "tolerance": …, "idle_timeout": …}` — key order as written | Emitted iff I-3 (AC-1). Members are exactly the node tags, in `nodes.json` order; `direct` is never a member (FR-1). Never emitted with an empty member list (BC-6). |
| I-7 | emitted `config.json` · `proxy` selector | `"outbounds"` = `([AUTO_TAG] if I-3 else []) + node_tags + ["direct"]`; `"default"` = `_valid_selection(active, node_tags) or "direct"`; `type`/`tag`/`interrupt_exist_connections` unchanged | `default` is always an element of this array (FR-7/AC-3). At zero nodes the expression collapses to today's `["direct"]` / `"direct"` (AC-5). |
| I-8 | emitted `config.json` · `outbounds` array | `[selector] + ([group] if I-3 else []) + nodes + [{"type": "direct", "tag": "direct"}]` | Reached only through `_runtime_overlay()`'s existing `{"$replace": …}` on a key `CONFIG_BASE` already defines (FR-8/AC-7, NG-13 respected). No two elements share a `tag` (AC-6). At zero nodes byte-identical to HEAD (AC-5). |
| I-9 | I-6 key `url` | `"https://www.gstatic.com/generate_204"` | **Kept** from D-11. Reason: it is this binary's own compiled-in default (literal present ×1 in `/usr/local/bin/sing-box`), so it is the best-exercised path in v1.13.15; emitted **explicitly** so a future binary's default cannot silently move it. `https` is kept over `http` deliberately: the reported failure mode is a hanging TLS handshake, which a plain-HTTP 204 would score as healthy. |
| I-10 | I-6 key `interval` | `"3m"` | **Kept** from D-11. It is the upper bound on unattended failover latency (worst case ≈ one interval), against an incident measured in hours. Shorter (30 s) multiplies TLS handshakes on every node including idle ones; longer (10 m) leaves a dead node carrying DNS for ten minutes. Not covered by NG-6 (probe cadence, not an `sc` wait). |
| I-11 | I-6 key `tolerance` | `50` (ms) | **Kept** from D-11. Without it the group re-selects on jitter alone and flaps between two equally good nodes, interrupting nothing but re-pointing DNS constantly. 50 ms is below any real inter-continental difference and above ordinary jitter. |
| I-12 | I-6 key `idle_timeout` | `"30m"` | **Kept** from D-11, after the interaction D-11 asked about was checked: when the group is the selection it is never idle, because `remote_dns` carries `detour: proxy` (`sc:1071-1072`) and `dns.final` is `remote_dns` (`sc:1095`), so every name lookup on the host keeps the group in use. When a node is pinned the group *is* idle and probing stops — which is exactly BC-11/D-9's "no stored delay" state that FR-12's marker exists for. A host whose only traffic is the weekly `sc update-rules` therefore loses nothing: probing resumes on use. |
| I-13 | I-6 key `interrupt_exist_connections` | **omitted** (sing-box default `false`) | **Changed** from the selector's `true`. The selector's `true` serves a *user-typed* switch, where immediacy is the point. On the group the switch is automatic and can be triggered by a 51 ms improvement; killing every live connection for that is worse than letting them drain on the old member. Recorded as the D-14 call it is. |
| I-14 | `TRANSLATIONS["zh"]` | key `"Delay"` → `"延迟"` | The only new string. An English **sentence-as-key** (D-13), never `ls.delay` — the five namespaced keys at `sc:174-178` stay untouched (NG-10/R-19). No placeholder, so parity is trivially exact; contains no `失败：` (AC-33). |
| I-15 | consumed API envelope | `GET /proxies` → `{"proxies": {"<tag>": {"history": [{"delay": <int>}, …], "now": "<tag>"}}}` | Read-only, never `PUT`/`PATCH`/`DELETE` (AC-29, S-5). `delays[tag]` is set **only** from `history[-1]["delay"]` when that value is an `int` (not `bool`) and `> 0`. `current` is set only from `proxies[AUTO_TAG]["now"]` when it is a non-empty `str`. Every other shape — absent key, non-list, empty list, non-dict element, non-int, `0`, non-object body, `None` from `clash_api()` — yields *absence*, never an exception and never a fabricated value (BC-10/AC-25). |
| I-16 | `sc ls` header row | today's five cells (`sc:1605`) unchanged + `"  " + f"{t('Delay'):>9}"` appended | The delay column is **last**, so no existing column's width or position moves (AC-31) and the CJK display-width defect of the existing headers cannot cascade into it. |
| I-17 | `sc ls` node row | today's five cells (`sc:1609`) unchanged + `"  " + f"{cell:>9}"`, where `cell` = `str(ms) + " ms"` when `tag in delays`, else `"-"` | `-` is the unknown marker (FR-12): visible, never `0`, never blank, never a number, identical in both languages so it adds no translation surface. Right-aligned ⇒ the line never ends in whitespace. |
| I-18 | `sc ls` group row | rendered first, directly under the header, iff I-3: idx cell **empty**, marker `●` iff the selection is `AUTO_TAG`, type `urltest`, name `AUTO_TAG`, address `"→ " + current` when `current` is known else `-`, delay cell by I-17's rule on `AUTO_TAG` | No index number, so `_resolve_node()`'s index space and `sc use <n>` are untouched (FR-14/AC-31). When the selection is the group, the `●` is on this row and on no node row, and the address cell names the current node (FR-13/D-6). |
| I-19 | `sc use <spec>` call flow | `spec == AUTO_TAG` **and** `_auto_group_emitted(node_tags)` → set `active = AUTO_TAG`, `save_nodes`, then today's apply path verbatim (`is_running()` → `PUT /proxies/proxy {"name": AUTO_TAG}` → else `reload_or_restart()`); **any other spec, including `auto` when I-3 is false** → today's `_resolve_node(spec)` path, unmodified | The reserved tag is decided before `_resolve_node()` is consulted, so a node named `auto-jp` can never swallow `sc use auto` (BC-8/AC-12). Conversely, on a host whose node is literally tagged `auto` the arm is not taken and HEAD's behaviour is preserved exactly (AC-13). Zero nodes: falls through to `_resolve_node()`, which already exits with the existing "no nodes added yet" sentence (`sc:1568`) — no new string. |

## Constraints

**K-1** — The implementer must spell the reserved tag literal `auto` in exactly one place, I-1, and must not introduce a second literal, a localized variant, or a `sc lang`-dependent value.

**K-2** — The implementer must not add any parameter, flag or environment variable that turns the auto-select group on or off; "the group is emitted" is I-3 and nothing else.

**K-3** — The implementer must make `_unique_tag()` itself reject `RESERVED_TAGS`, not the `cmd_add` call site, so that "no node carries a reserved tag" is a property of the tag minter and a future second caller inherits it (FR-3/AC-11).

**K-4** — The implementer must emit the group whenever I-3 holds, including at exactly one node; no one-node special case may be added (D-4, cost accepted: one probe per interval that changes no routing decision).

**K-5** — The implementer must place the group element immediately after the selector and before the node outbounds, so that at zero nodes the array expression collapses to HEAD's `[selector] + nodes + [direct]` and AC-5 holds by construction rather than by a test.

**K-6** — On a host whose `nodes.json` already holds a node tagged `auto`, the implementer must emit **no** group (I-3's second clause) and must print no warning about it; the state is documented in both READMEs (L-13/L-14) and is self-healing the moment the user renames the node. Emitting the group there would put two outbounds with tag `auto` in the document and make `sc reload` fail `sing-box check` on an upgrade — the exact failure AC-17 forbids.

**K-7** — The implementer must keep the stale-selection repair as the only writer of `nodes.json` inside `generate_config()`, and must persist **only when `_valid_selection()` returns something different from what was loaded**; an unconditional `save_nodes()` would break AC-9's N-times-unchanged property.

**K-8** — The implementer must route all three of `sc`'s auto-picks (`cmd_add` `sc:1641-1642`, `cmd_rm` `sc:1655-1656`, `generate_config` `sc:1471-1475`) through `_valid_selection()`, so none of them can form a second opinion and none of them keeps `node_tags[0]` (D-5).

**K-9** — The implementer must not change `_resolve_node()` (`sc:1564-1584`) in any way, including its substring fallback and its error sentences (AC-13/AC-31).

**K-10** — The implementer must leave `nodes.json`'s write ordering in `cmd_use` as it is at HEAD (`save_nodes` before the apply attempt), so AC-22's API-rejection path still ends in `reload_or_restart()` with the selection applied.

**K-11** — The implementer must guard `stored_delays()` with `is_running()` **inside the function**, so every future caller inherits the guard and `sc ls` on a stopped host issues no request and waits nothing (D-10/AC-27).

**K-12** — The implementer must implement I-15's shape checks with `isinstance` tests and no `try`/`except`, so that no malformed body can reach a traceback and no bare `except` can hide a real defect (BC-10/AC-25).

**K-13** — The implementer must not add or change any timeout: `clash_api()`'s `timeout=3` must be byte-identical in the diff, and no new constant may be introduced (NG-6/AC-28).

**K-14** — The implementer must not add `domain_strategy` to any emitted outbound. AC-15's answer depends on it: with no domain strategy set, sing-box passes the probe URL's FQDN to the member outbound's remote server instead of resolving it locally (the binary's `missing domain resolver` error string, present ×1, is the guard on the branch that *does* resolve), so the probe consults **no** local DNS server and cannot reach `remote_dns`, hence cannot reach `proxy`, hence cannot depend on the group being probed.

**K-15** — The implementer must not touch the `dns` section of `CONFIG_BASE` (`sc:1068-1097`) or `route.default_domain_resolver` (`sc:1105`) (NG-2). AC-15's fallback branch rests on `default_domain_resolver` naming `direct_dns`, a server with no `detour`: if a local lookup happened after all, it is pinned to that server, which is still not the group. The doubly-counterfactual third branch — a local lookup that also traverses `dns.rules` — would reach `remote_dns` for *any* non-CN probe host, because `dns.final` is `remote_dns` (`sc:1095`); that is not fixable by changing the probe URL and is therefore re-homed to T-16 as a finding (RS-2), not designed around here.

**K-16** — The implementer must add no `sc doctor` row, no `/proxies/:name/delay` call, no persisted latency record and no ranking command (NG-7/NG-8/NG-12).

**K-17** — The implementer must keep `HELP_EN` / `HELP_ZH` hand-alignment (descriptions at column 30, sub-options at column 32) when editing the `use` line.

**K-18** — The implementer must write the `CHANGELOG.md` entry in Chinese, under the existing `## [Unreleased]` → `### 新增` heading, and must not add a new version heading.

## Frozen set

| path | why frozen |
|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` `sc:1068-1097` (`CONFIG_BASE.dns`) and `sc:1105` | NG-2 — T-16 owns DNS; AC-15's answer reads it, never changes it |
| `/home/alan/Programs/singbox-cli/bin/sc` `sc:1039` `DIRECTIVES`, `_directive_of`, `_apply_directive`, `_merge` | NG-13/D-12 — R-16 is not claimed by this task; the existing `$replace` suffices |
| `/home/alan/Programs/singbox-cli/bin/sc` `sc:1564-1584` `_resolve_node()` | AC-13/AC-31 — resolution rules, index space and error strings must be identical to HEAD |
| `/home/alan/Programs/singbox-cli/bin/sc` `sc:1536-1550` `clash_api()` | AC-28 — `timeout=3` byte-identical; the new reader is a caller, not an edit |
| `/home/alan/Programs/singbox-cli/bin/sc` `sc:174-178` (the five `ls.*` keys) | NG-10/D-13/R-19 — deliberately left broken; fixing them here widens scope |
| `/home/alan/Programs/singbox-cli/bin/sc` `cmd_now` (`sc:1612-1614`), `cmd_status` (`sc:1686-1707`) | NG-11/D-7 — `sc now` prints one token and is embedded in `$(…)` |
| `/home/alan/Programs/singbox-cli/bin/sc` `# doctor` block (`sc:1710`ff) | NG-7 — the reader must merely be *callable* from there later |
| `/home/alan/Programs/singbox-cli/bin/sc` `_warn_drift()` (`sc:1426-1452`) and its call at `sc:1502` relative to the write at `sc:1506` | AC-18 — both sides of the digest comparison describe the pre-replacement file; moving either breaks the quiet upgrade |
| `/home/alan/Programs/singbox-cli/bin/sc` `_write_private()` (`# State files`) | NFR-4 / T-13 — the only writer of credential documents |
| `/home/alan/Programs/singbox-cli/install.sh`, `/home/alan/Programs/singbox-cli/uninstall.sh`, `/home/alan/Programs/singbox-cli/systemd/` | NG-5 and NFR-5's permitted diff |
| `/home/alan/Programs/singbox-cli/docs/tasks.md`, `/home/alan/Programs/singbox-cli/.harness/**` | NFR-5 — outside the permitted diff; R-19 and the insight harvest are the PM's at delivery |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | L-1 | none | revert the two constants; nothing reads them yet |
| 2 | L-3 | L-1 landed | delete both functions; no caller yet |
| 3 | L-4, L-5 | L-3 landed; V-1 run **before** this step to capture the HEAD baseline at the same fixture path (S-7) | revert both; the document returns to HEAD's shape and any persisted `active == "auto"` is repaired away by HEAD's own `active not in node_tags` branch |
| 4 | L-10, L-11 | L-3 landed | revert to `node_tags[0]` / `outbound["tag"]` |
| 5 | L-9, L-7 | L-1, L-3 landed | revert; `sc use auto` then resolves through `_resolve_node()` only |
| 6 | L-6 | none (independent of half A) | delete the function; no caller yet |
| 7 | L-2, L-8 | L-6 landed | revert `cmd_ls` to the five-column form and drop the key |
| 8 | L-12…L-16 | code steps landed | revert the docs |
| 9 | L-17 | all above | — |
| U-1 | upgrade of an existing host (BC-13) | `sc reload` after the new `bin/sc` is installed; no file under `/etc/sing-box` is hand-edited | reinstall the previous `sc` and run `sc reload`: the config is regenerated, never patched, and a persisted `active == "auto"` is rewritten to `node_tags[0]` by the old build's own repair, so the downgrade is self-healing and leaves no dangling reference |
| U-2 | a host whose `active` is already a node tag | nothing happens: I-4's first clause returns it unchanged, so no host's traffic silently moves (D-5, AC-17/AC-18) | — |

## Out of scope

- The five namespaced `ls.*` translation keys that print literally in English (R-19).
- Any change to the DNS section, including the `remote_dns` detour that BC-12 turns on (T-16).
- CJK display-width alignment of the `sc ls` table; the new column is last precisely so the existing defect cannot grow.
- Distinguishing "probed and failed" from "never probed" in the delay column — both render as `-` (see RS-3).
- An on-demand delay measurement (`sc ping`, `/proxies/:name/delay`), a `sc doctor` node row, a persisted latency history, a best-node ranking.
- Defending the group against a user `override.json` that `$replace`s `outbounds` (BC-14 — documented contract).
- Extending `_merge()`'s directive vocabulary (R-16 stays open and unclaimed).

## Verification plan

Every fixture obeys S-1…S-9: the `docs/dev-map.md:109-135` import recipe, all seven path constants
inside one `mkdtemp()` root **and asserted so**, `SYSTEMD = OPENRC = False`, `_init_files()` never
driven, no `PUT`/`PATCH`/`DELETE` to the live API, `LANG` set the way `main()` does.

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | differential `generate_config()`, HEAD clone vs candidate, **same** fixture path (S-7/S-8), zero nodes | emitted `outbounds` byte-identical | AC-5 |
| V-2 | emitted document at 1 and 3 nodes | exactly one `urltest`; its `outbounds` == node tags in `nodes.json` order; no `direct` among them; selector holds `auto` + every node tag + `direct` | AC-1, AC-2 |
| V-3 | reference-closure scan of the emitted document in each of BC-1…BC-4 | every tag referenced by `proxy.outbounds`, `proxy.default`, the group's `outbounds`, `route.rules[].outbound`, `route.final`, `dns.servers[].detour` is defined in the same document; no duplicate `tag` | AC-3, AC-4, AC-6 |
| V-4 | **real** `/usr/local/bin/sing-box check` on: 0 / 1 / 3 nodes × selection ∈ {node, `auto`}, plus one degraded rule-set state; and, for the record, one hand-made `urltest` with an empty member list | all six generated documents accepted; the empty-member document's verdict recorded as BC-6's answer (the design makes that state unreachable either way) | AC-14, BC-6 |
| V-5 | `git diff` of `generate_config()`'s body | no outbound literal added; every new key/value arrives via `_runtime_overlay()` | AC-7 |
| V-6 | `generate_config()` run 3× with `active == "auto"`, ≥1 node | `nodes.json` byte-identical after each run | AC-9 |
| V-7 | remove the last node with `active == "auto"` | emitted document passes V-3; persisted `active` is `None` | AC-10 |
| V-8 | `sc add` with fragment `#auto` | node tag is `auto #2`; V-3 passes | AC-11 |
| V-9 | node tagged `auto-jp`, then `sc use auto` | `active == "auto"`; the node is not selected | AC-12 |
| V-10 | `sc use <name>` / `<index>` for every node, both languages, against a HEAD clone | identical resolution, identical indices, identical output bytes | AC-13, AC-31 |
| V-11 | BC-13 upgrade fixture (pre-T-15 `config.json` + matching `.config.sha256` + node-tag selection): `sc reload`, then a second `sc reload` | first reload succeeds with no hand-editing and **no** drift warning; `.config.sha256` then holds the new file's digest; second reload also silent | AC-17, AC-18, AC-19 |
| V-12 | `sc update-rules` with no rule-set byte changed, witness `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` (S-6) | witness identical before/after; the "No rule-set changed" line printed | AC-20, AC-21 |
| V-13 | `sc use auto` against a **stub** HTTP server on the fixture port with `is_running` stubbed true and `SYSTEMD = OPENRC = False` (S-5) | exactly one request, `PUT /proxies/proxy` with body `{"name": "auto"}`; `active` persisted; the switched-to line printed; no service call possible | AC-8 |
| V-14 | same stub answering 4xx (pre-T-15 process rejects an unknown member) | falls through to `reload_or_restart()`; ends with the selection applied | AC-22 |
| V-15 | `stored_delays()` against the stub for each BC-10 body: well-formed, no `history`, empty `history`, no `delay`, `delay` non-int, `delay == 0`, non-object top level, connection refused | never raises; only well-formed positive integers appear in `delays`; `current` only from a non-empty string `now` | AC-25, AC-26 |
| V-16 | `sc ls` with the API unreachable, both languages | today's table plus a `-` in every delay cell; exit 0; no traceback, no Python text; no `\r`; one line per entry | AC-24, BC-15 |
| V-17 | `sc ls` with `is_running()` false, stub server counting connections | zero connections; wall-clock within noise of HEAD | AC-27 |
| V-18 | `sc ls` with zero nodes | today's "(no nodes …)" line, unchanged, and no API call | AC-30 |
| V-19 | **live host, read-only, stage 6**: after delivery with the group emitted and selected, wait > one `interval`, run `sc ls` | numeric delays appear for reachable nodes — which is only possible if the probe resolved `www.gstatic.com` and completed, i.e. BC-12's circular path was not taken | AC-15, AC-23 |
| V-20 | `git diff` greps | `timeout=3` unchanged; the new code path contains no non-`GET` method argument; no new timeout constant | AC-28, AC-29 |
| V-21 | `python3 -m py_compile bin/sc`; 3.6-syntax scan of the diff; new-key parity check (`zh` entry present, no placeholder on either side, no `失败：`) | all pass | AC-33, AC-35 |
| V-22 | `bash .harness/scripts/verify_all.sh`; README line-count/mirror check | no FAIL (the F.6 doc-size WARN on this task's stage docs is **predicted**, clears on archive); both READMEs line-for-line mirrors | AC-32, AC-34 |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RS-1 | **FR-9 report — nothing was inexpressible.** The T-14 layer carried this change whole: the group reaches the document through `_runtime_overlay()`'s existing `{"$replace": …}` on `outbounds`, a key `CONFIG_BASE` already defines, with no new directive and no literal in `generate_config()`. One observation, not a shortfall: because the shipped overlay `$replace`s the entire array, a *future* second shipped overlay that wants to add an outbound must use `$append`/`$prepend` rather than re-stating the array — worth a dev-map line when T-16/T-17 arrive. | `03_GATE_REVIEW.md` |
| RS-2 | **BC-12 residual, re-homed to T-16.** If a dial-side lookup ever does traverse `dns.rules`, every non-CN probe host resolves through `remote_dns` (`detour: proxy`) because `dns.final` is `remote_dns`; no probe-URL choice can avoid it, only a DNS change can. NG-2 forbids that change here. | `07_DELIVERY.md` → T-16 |
| RS-3 | A `delay` of `0` (probe ran and failed) and an absent history (never probed) both render `-`. Splitting them needs a second marker and a verified failure-storage convention that E-4 did not establish. | `07_DELIVERY.md` (future row) |
| RS-4 | **BC-6 could not be settled at stage 2**: this session had no shell tool, so no `sing-box check` could be run. The design makes an empty member list unreachable (I-3/K-4), and V-4 records the binary's answer for the record. | `03_GATE_REVIEW.md`, `06_QA_REPORT.md` |
| RS-5 | R-19 (the five `ls.*` keys) is untouched and still open; the new header key deliberately does not copy the defect. | `07_DELIVERY.md` → PM files the row |
| RS-6 | Insight candidates for harvest: (a) a `urltest` group is emitted *before* the node outbounds it references and sing-box accepts it — the shipped selector already proved forward references are fine; (b) the auto-select group is never idle while it is the selection, because `remote_dns`'s `detour: proxy` keeps DNS on it. | `07_DELIVERY.md` |

## Partition assignment

**Not applicable.** This project has no `.harness/agents/dev-*.md` files, and
`.harness/rules/50-singbox-cli.md:110-121` states single-developer mode as a project rule ("the repo
is flat and small — one CLI file… all code tasks go to the plugin-provided `harness-kit:developer`").
Stage 4 is therefore single-Developer mode; the ledger's partition column reads `developer`
throughout and no dispatch order or parallelism applies.

## Verdict

**READY.**

All three handed-forward design calls are resolved (D-2 → K-1, D-4 → K-4, D-11/AC-16 → I-9…I-13),
AC-15 is answered with evidence in K-14/K-15 and made falsifiable by V-19, FR-9 is discharged by
RS-1, and every AC-1…AC-35 has a named design element and a verification step. One upstream gap was
found and closed inside this design rather than routed back: BC-7 covers a *colliding share-link
fragment* but not a node **already** tagged `auto` on an upgrading host, which would have emitted a
duplicate tag and failed AC-17; K-6 handles it.
