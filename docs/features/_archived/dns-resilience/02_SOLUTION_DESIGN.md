# 02 — Solution Design · T-16 `dns-resilience`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

Mode: **full**. Upstream `01_REQUIREMENT_ANALYSIS.md` verdict **READY**, read in full; `01_RATIONALE.md`
read under **T2.1** and **T2.4**; `03_GATE_REVIEW.md` does not exist yet.
`.harness/rules/70-doc-size.md` carries no `## Stage-doc boundary rule` section, so the agent schema is
applied as written: `## Byte-form specification` is absent (ungated), risks and the reuse audit live in
`02_RATIONALE.md`, and the per-AC traceability is carried by the `AC` column of `## Verification plan`
(all 34 criteria appear there). Ledger, interface, constraint, step and residual ids are stable
identifiers, not sequences — a gap in the numbering carries no meaning.

`sc` below = `/home/alan/Programs/singbox-cli/bin/sc`. Line anchors are the working tree at `1e454b6`.

## Architecture summary

- **What changes:** the emitted document changes in exactly one structural way — the `query_type`
  element leaves `CONFIG_BASE` (`sc:1101`) and re-appears at `dns.rules[0]`, emitted by one new computed
  overlay `_dns_overlay()` whose list is `[28, 64, 65]` or `[64, 65]`; four new functions carry the
  decision behind it and `sc ipv6` exposes it; `generate_config()` gains no configuration literal and the
  directive vocabulary gains no member.
- **What does not change:** `dns.servers`, `dns.final` (`remote_dns`), every other `dns.rules` element
  and the relative order of all of them, `_merge()` and its five directives, `_load_override()`,
  `_filter_rules()`, `_runtime_overlay()`, `route.*`, `outbounds`, the `proxy` selector, the auto-select
  group, `sc`'s three socket waits, and `install.sh` / `uninstall.sh` / `systemd/`.
- **Where the seam is:** `ipv6_decision()` is the only place the effective decision is made and
  `_dns_overlay()` the only place it reaches the document; **index 0** is the seam inside the document —
  the one position that precedes both `clash_mode` rules, which is what makes the suppressed class
  node-independent and mode-independent (I-17).

## Change ledger

Total over every touched file. This project has no partition developers
(`.harness/rules/50-singbox-cli.md:110-121`), so the partition column reads `developer` throughout.

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| L-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# Paths`, after `RESERVED_TAGS` (`sc:56`): add `IF_INET6_PATH` (I-1) | developer |
| L-2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# i18n` `TRANSLATIONS["zh"]`, in the settings block (`sc:154-158`): ten new pairs, verbatim from Q-15 (I-13) | developer |
| L-3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `OverrideError` (`sc:1037-1044`): add the class attribute `path = None` (I-12) | developer |
| L-4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `CONFIG_BASE["dns"]["rules"]`: delete the `query_type` element (`sc:1101`) and nothing else — the array's remaining seven elements, their order, `dns.servers` and `dns.final` are untouched (K-3, K-5, K-13) | developer |
| L-5 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# Config composition`, immediately above `_runtime_overlay()` (`sc:1399`): add `_ipv6_setting()` (I-3), `_global_ipv6_iface()` (I-4), `ipv6_decision()` (I-5), `_dns_overlay()` (I-6) | developer |
| L-7 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `generate_config()` `sc:1543` and `sc:1566-1569`: provenance wrapper around `_load_override()`, `_dns_overlay()` added to the composed overlays, the user's overlay merged at its own named site (I-11) | developer |
| L-8 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# Commands`, after `cmd_mode()` (`sc:2229`): add `cmd_ipv6()` (I-10) | developer |
| L-9 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `main()` `sc:2617-2634` and `sc:2652-2661`: the `ipv6` subparser and its `handlers` entry (I-14) | developer |
| L-10 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `main()`'s `OverrideError` handler `sc:2675-2676`: the rendered path becomes `e.path or CFG_PATH`; the comment at `sc:2672-2674` is replaced by the statement of what `path` now means (I-12) | developer |
| L-11 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `HELP_EN:2519` and the `HELP_ZH` counterpart (`sc:2578`): one `ipv6 <on\|off\|auto\|show>` row at the existing column alignment (I-15) | developer |
| L-12 | `/home/alan/Programs/singbox-cli/README.md` | edit | new `### IPv6 name resolution` after `### Switch route mode` (`:105-111`): the four `sc ipv6` forms, the effective-decision rule, **which classes of names do not depend on a node** (I-17, per routing mode), BC-22's limit (a proxied resolver that does not answer produces no answer and no second attempt), and BC-4's degraded consequence (Q-18). No sentence may claim a fallback resolver (K-16) | developer |
| L-13 | `/home/alan/Programs/singbox-cli/README.zh-CN.md` | edit | the same edits at the mirrored positions — line-for-line mirror (AC-20) | developer |
| L-14 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | one Chinese bullet under `## [Unreleased]` → `### 新增` | developer |
| L-15 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | `# Paths` row (the repoint list becomes **eight** paths, `:123`), `# Config composition` row (the four new functions), `# Commands` row (`cmd_ipv6`), two new reusable-utility rows (I-5, I-6), and the `generate_config()` row (the two-step composition of I-11) | developer |
| L-16 | `/home/alan/Programs/singbox-cli/docs/features/dns-resilience/04_DEVELOPMENT.md` | new | the Developer's own stage doc | developer |

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `sc` module constant | `IF_INET6_PATH = Path("/proc/net/if_inet6")` | THE one source of the host's IPv6 address state. Referenced only inside function bodies, so it joins the seven repointable path constants as the **eighth** (`docs/dev-map.md:123`) — without it AC-16/AC-17 cannot be driven without root. |
| I-2 | `/etc/sing-box/settings.json` key | `"ipv6": "on" \| "off" \| "auto"` | The only key this task adds to the file. Never seeded (`_init_files()` unchanged, Q-8): absent **is** `auto`. Written only by `cmd_ipv6()`, through the existing `load_settings()`/`save_settings()` pair — not through `_write_private()` (NFR-4). |
| I-3 | `sc` function | `_ipv6_setting() -> str` — returns exactly one of `"on"`, `"off"`, `"auto"` | THE single reader of I-2, in the shape `_saved_clash_port()` already uses (`sc:312-317`): `load_settings()` guarded by `except (FileNotFoundError, json.JSONDecodeError, OSError)` → `"auto"`, silently (BC-8, BC-10 — no new failure mode, no traceback). A value present but not one of the three exact lowercase strings → `"auto"` **plus one stderr line** naming file, key and the three accepted values (BC-9). Reads one file; writes nothing. |
| I-4 | `sc` function | `_global_ipv6_iface() -> (iface, err)` — `iface` is a device name `str` or `None`; `err` is a short cause `str` or `None` | FR-6's predicate and nothing else: the device of the **first** line of I-1 whose address has `(first_byte & 0xE0) == 0x20` (i.e. inside `2000::/3`) and whose device is neither `"lo"` nor `TUN_IFACE`. `::1`, `fe80::/10` and `fc00::/7` can never satisfy it, and a link-local address on `sb-tun` is excluded by name (BC-6). An empty file is a legitimate "no IPv6 at all" → `(None, None)`. `err` is set only when the source cannot be read (`OSError` → `e.strerror or str(e)`) or when the file is non-empty and **no** line yields six whitespace-separated fields whose first parses as hex (BC-7). Never raises; prints nothing. |
| I-5 | `sc` function | `ipv6_decision() -> (setting, suppress, sentence)` — `setting` from I-3, `suppress` a `bool`, `sentence` an already-translated `str` or `None` | **THE definition of the effective IPv6 decision (FR-3/AC-6).** Exactly two callers: I-6 and I-10; no other code re-derives it. `off` → `(setting, True, <off sentence>)`. `on` → `(setting, False, <on sentence>)`. `auto` → I-4 is consulted: a global address → `(auto, False, <auto-global sentence with {iface}>)`; none → `(auto, True, <auto-no-global sentence>)`; `err` set → `(auto, False, None)` **plus one stderr line** carrying the cause and the assumption (FR-7). It reads I-1 **only** under `auto`, so `on`/`off` cost exactly one file read (NFR-5). It writes no file, issues no request and performs no service-affecting action; its only side effect is at most two stderr lines, in the shape `_warn_degraded()`/`_warn_drift()` already use. |
| I-6 | `sc` function | `_dns_overlay() -> dict` — `{"dns": {"rules": {"$prepend": [<the I-7 rule>]}}}` | The ONE place the decision reaches the document. Uses `$prepend`, an existing directive (FR-13), on `dns.rules`, an array `CONFIG_BASE` always defines — so it can never raise, and it needs no anchor that a later base edit could break. It calls I-5 exactly once and consumes only `suppress`. It emits **no** other key: no `timeout`, no `final`, no server (K-13, K-17). |
| I-7 | emitted `config.json` · `dns.rules[0]` | `{"action": "predefined", "rcode": "NOERROR", "query_type": [28, 64, 65]}` when suppressing, `{"action": "predefined", "rcode": "NOERROR", "query_type": [64, 65]}` when not — key order as written, values as integers | The suppression rule, and the **only** `query_type` rule in the document (the base's copy at `sc:1101` is deleted by L-4, so there is one definition, not two). Its position is the index relation `index == 0`, hence strictly less than the index of both `clash_mode` rules and of every rule whose `server` is `remote_dns` (FR-2/AC-3), in every routing mode and in every rule-set state. It carries no `rule_set` key, so `_filter_rules()` keeps it unconditionally (`sc:879-881`, FR-12/AC-4). A query it answers issues no upstream query at all (FR-1). Answering types 64/65 ahead of the `hosts_dns` rule costs nothing: `remote_dns`'s bootstrap uses the **server-level** `domain_resolver: hosts_dns` (`sc:1084`), not `dns.rules`. |
| I-10 | `sc` command | `cmd_ipv6(args)`; call flow: lower-case `args.value`; reject anything outside `on\|off\|auto\|show` with `sys.exit(t("Error: argument must be one of on / off / auto / show"))`; **show** → one `ipv6_decision()` call, print the setting line then the sentence, return; **set** → `before = ipv6_decision()[1]`, `load_settings()` / assign / `save_settings()`, `setting, after, sentence = ipv6_decision()`, print the setting line and the sentence, then `after == before` → print `Nothing changed …` and return, else `reload_or_restart()` → print `Configuration regenerated; sing-box restarted`, or `sys.exit(t("Reload failed"))` | `show` writes nothing, issues no request and performs no service-affecting action (AC-12/NFR-5). A set that leaves the effective decision unchanged performs no service-affecting action (FR-5/BC-12/AC-13) — the comparison is between two results of I-5, so no second opinion about the document is created (Q-9). The setting is persisted on every set, including one that changes no decision, so a hand-edited unrecognised value is repaired by `sc ipv6 auto`. Exit 0 on all four forms in both languages (AC-11). |
| I-11 | `sc` function | `generate_config()` composition flow: `override = _load_override()` inside `try/except OverrideError as e: e.path = OVERRIDE_PATH; raise`; … unchanged …; `config = _compose([_runtime_overlay(nodes, active, report), _dns_overlay()])`; then, when `override is not None`, `_merge(config, override)` inside the same wrapper shape | The user's document is still applied **last** and still through the one `_merge()` (T-14's contract, `docs/dev-map.md` "Patterns to follow"), so the emitted bytes are unchanged by the move. What changes is that the two failure provenances now have two different code sites instead of one, which is what makes I-12 truthful without an exception taxonomy. `_compose()`'s signature, `_merge()`, `_load_override()` and the three-key shape assertion (`sc:1574-1576`) are untouched. `generate_config()` gains no configuration literal and no fourth key in the guard (AC-10). |
| I-12 | `sc` exception + rendering site | `class OverrideError(Exception): path = None`; `main()` renders `t("Cannot use {path}: {problem}", path=e.path or CFG_PATH, problem=str(e))` | FR-14/AC-22: a failure raised while applying an overlay `sc` authored leaves `path` at `None` and is rendered against `CFG_PATH`, so `override.json` is named **only** when the user's document is what failed. No new translation key (Q-15 permits reusing an existing key whose text says exactly this); `_plain()` and the newline collapse stay exactly where they are (`sc:2675-2676`). The class attribute is `None`, never `CFG_PATH`, so a harness that repoints `CFG_PATH` after import still gets the repointed value. |
| I-13 | `TRANSLATIONS["zh"]` | the ten pairs fixed by Q-15, inserted in the settings block (`sc:154-158`) | Every key is the English sentence itself (no `ls.*` namespacing); each `zh` value carries the identical placeholder set; no `zh` value contains `失败：` (FR-16/AC-19). Ten is the whole budget: this design adds no eleventh user-facing string. |
| I-14 | `sc` CLI surface | `sc ipv6 <on\|off\|auto\|show>` — `p = sub.add_parser("ipv6"); p.add_argument("value")`, `handlers["ipv6"] = cmd_ipv6` | Shaped exactly like `sc lang` / `sc mode` / `sc default-tun`: one positional value, lower-cased by the handler (BC-21), values language-neutral so `sc lang` cannot move them (Q-12). `sc ipv6` with no argument takes argparse's own required-argument error and exit 2 — identical to `sc lang` today, and deliberately not special-cased. `main()`'s read-only opt-out arm (`sc:2646-2651`) is **not** touched: `ipv6` takes the `else` arm like every other command (`docs/dev-map.md` "Patterns to avoid"). |
| I-15 | `HELP_EN` / `HELP_ZH` | one row, `ipv6 <on\|off\|auto\|show>` at column 30 with two sub-option lines at column 32, inserted between the `mode` block and `default-tun` (`sc:2519`) | Hand alignment preserved in both blocks (AC-21). |
| I-16 | emitted `config.json` · `dns.final` | `"final": "remote_dns"` — byte-identical to HEAD in every state this task emits | `dns.final` is the **no-rule-matched routing default**, never a failure fallback (Q-2/Q-14, measured). This task never re-points it and emits no rule that would make it unreachable: the class of names matched by no DNS rule keeps being answered by the proxied resolver (FR-11, Q-17, requirement out-of-scope 13). Nothing in this design, in either README or in any stage document may describe `final`, or any rule, as a fallback that answers when another resolver fails — no such mechanism exists in this build (K-16). |
| I-17 | emitted `config.json` · `dns.rules` index order, and the node-independent class it produces | `[0]` suppression (I-7) · `[1]` `hosts_dns` · `[2]` `clash_mode: Global` → `remote_dns` · `[3]` `clash_mode: Direct` → `direct_dns` · `[4]` `geosite-google` · `[5]` `geosite-private` · `[6]` the five domestic `domain_suffix` names · `[7]` `geosite-cn` | **This is where FR-8 is discharged.** The class answered while every node outbound is unusable, per routing mode: `rule` → the query types `[0]` answers (all names), the six names `[1]` answers from its predefined table, and the five suffixes `[6]` sends to `direct_dns`; `global` → `[0]` and `[1]` only, because `[2]` captures everything else by the user's own instruction; `direct` → `[0]`, `[1]` and everything `[3]` sends to `direct_dns`. With every rule-set unusable, `_filter_rules()` deletes `[4]`, `[5]` and `[7]` and keeps `[0]`, `[1]`, `[2]`, `[3]`, `[6]` — so the `rule`-mode class is unchanged (BC-4/Q-18). Node-independence of `[6]`/`[3]` rests on `direct_dns` carrying no `detour` **and** on `route.rules[0]` (`{"outbound": "direct", "process_name": ["sing-box"]}`, `sc:1121`) preceding both `clash_mode` route rules, so sing-box's own DNS dial leaves via `direct` in every mode. T-16's own contribution to this class is exactly `[0]`: query type 28 while suppressing, and mode-independence for 28/64/65. `[1]` and `[6]` are HEAD behaviour that this task must **preserve, and prove it preserved** (V-26…V-28, V-34) rather than assert. The only (name, type) pairs whose answering resolver differs from HEAD are the suppressed query types, sanctioned by FR-2/Q-4; every type-A pair keeps its HEAD resolver, which is what makes FR-11 testable (V-32). |

## Constraints

**K-1** — The implementer must make `ipv6_decision()` (I-5) the only function that answers "does this host
suppress AAAA", and must not re-derive it at either call site: deleting one caller must leave the other
one working unchanged (AC-6's deletion test).

**K-3** — The implementer must delete the `query_type` rule element at `sc:1101` in the same edit that
adds I-6, so that at no commit do two `query_type` rules exist in the emitted document.

**K-5** — The implementer must not add, remove, reorder or edit any element of
`CONFIG_BASE["dns"]["servers"]` (`sc:1082-1096`), `remote_dns`'s `detour: proxy` included (FR-15).

**K-6** — The implementer must not touch `_merge`, `_directive_of`, `_apply_directive`, `DIRECTIVES` or
`_load_override` (AC-8), and must express every document change through `CONFIG_BASE` or through an
overlay applied by the existing `_merge()` with an existing directive (FR-13). If something cannot be
expressed that way, it is reported as a finding naming what could not be expressed — never by widening the
vocabulary.

**K-7** — The implementer must set `e.path` at exactly the two sites where the **user's** document is
being handled (I-11) and nowhere else, so that "who is at fault" is a property of the call structure
rather than of a flag someone has to remember to set.

**K-8** — The implementer must route the FR-7 and BC-9 lines to **stderr** and the setting line and
evidence sentence to **stdout**, one complete line per fact, with no carriage return and no intermediate
state (NFR-8/BC-20). Any `{err}` value taken from the operating system must pass through `_plain()` at the
print site, as `save_nodes()` and `generate_config()` already do.

**K-9** — The implementer must add exactly the ten strings Q-15 fixes, verbatim in both languages, and no
eleventh; where an existing key already says exactly what is needed (`Reload failed`,
`Cannot use {path}: {problem}`) it must be reused rather than duplicated.

**K-10** — The implementer must not modify `main()`'s read-only opt-out arm, must not add a
`READ_ONLY_COMMANDS` set or a per-command flag, and must not drive `_init_files()` from any fixture — it
hard-codes `/var/lib/sing-box` (NFR-6, `.harness/insight-index.md:19`).

**K-11** — Every freeze check the implementer writes for AC-8 and AC-9 must extract the symbol with `ast`
and compare bytes; a `grep` check is unsound here because `timeout=3` is a textual prefix of `timeout=30`.

**K-12** — The implementer must keep the diff inside NFR-3's permitted set. `CONTEXT.md` (three glossary
terms this design introduces) and `.harness/rejected-decisions.md` (three approaches declined here) are
**outside** it; both are recorded as residuals for the PM rather than edited (RS-6).

**K-13** — The implementer must leave `CONFIG_BASE["dns"]["final"]` at `remote_dns` and must add no DNS
rule that matches unconditionally, so that the class of names matched by no DNS rule keeps reaching the
proxied resolver (I-16, FR-11, Q-17, requirement out-of-scope 13).

**K-14** — Whoever builds a behavioural fixture must repoint **both** `remote_dns` and `direct_dns` at
local stub resolvers inside the fixture root and must stage every node state at the `proxy` outbound, so
that no behavioural measurement depends on the public internet and the 100 ms bound is a property of the
document rather than of the network.

**K-15** — Whoever builds a behavioural fixture must keep `route.rules`' `{"action": "sniff"}` element
(`sc:1122`) ahead of the `hijack-dns` element (`sc:1123`) and must keep `route.default_domain_resolver`
(`sc:1118`) present, because without the first a `direct` inbound forwards the DNS packet to itself in a
silent loop and without the second sing-box 1.13.15 fails `check` outright.

**K-16** — Nobody writing user-facing text for this task — either README, the changelog, the help blocks
or any new string — may state or imply that a second resolver answers when the proxied one fails, or that
any wait is configured: neither exists in this build, and claiming resilience this task does not have is
the failure mode the loudness through-line forbids (Q-19, BC-22).

**K-17** — The implementer must emit no key expressing a wait anywhere in the document and must define no
new wait constant in `bin/sc`; the three existing socket waits keep their values and their call sites
(FR-10/AC-7, out-of-scope item 5).

## Frozen set

| path | why frozen |
|---|---|
| `bin/sc` `sc:1052` `DIRECTIVES`, `_directive_of` (`sc:1156`), `_anchor_index` (`sc:1182`), `_apply_directive` (`sc:1205`), `_merge` (`sc:1233`), `_load_override` (`sc:1278`) | AC-8 — byte-identical to HEAD; the provenance fix is a wrapper at the call site, never an edit here |
| `bin/sc` `clash_api()`'s `timeout=3` (`sc:1635`), `_egress_ip()`'s `timeout=8` (`sc:355`), `_fetch_to_temp()`'s `timeout=30` (`sc:989`) | AC-9 — none of them is a DNS wait; enlarging or moving one is out of scope item 5 |
| `bin/sc` `_runtime_overlay()` (`sc:1399-1458`) and everything it emits — `outbounds`, the `proxy` selector, the auto-select group, `route.rule_set` | Out of scope item 4; T-15's differential and AC-5 both rest on it being untouched |
| `bin/sc` `CONFIG_BASE["dns"]["servers"]` (`sc:1082-1096`), entirely | FR-15, K-5 — no key of any server is added, removed or changed; `remote_dns` keeps `detour: proxy`, `direct_dns` keeps no detour |
| `bin/sc` `CONFIG_BASE["dns"]["final"]` (`sc:1108`) | K-13, I-16 — re-pointing it is requirement out-of-scope item 13 and an FR-11 violation on every healthy host |
| `bin/sc` `CONFIG_BASE["dns"]["rules"]` elements other than `sc:1101`, and their order (`sc:1097-1107`) | I-17 — the node-independent class is an index relation over exactly these elements; reordering one silently changes which class survives BC-2 |
| `bin/sc` `CONFIG_BASE["log"]` (`sc:1080`) | Requirement out-of-scope item 15 (Q-19) — no change to what sing-box records, or at which level, when it abandons a query |
| `bin/sc` `CONFIG_BASE["route"]` (`sc:1117-1137`), including `default_domain_resolver` (`sc:1118`) and the `process_name` rule (`sc:1121`) | Out of scope items 4 and 11, and I-17 depends on `sc:1121`'s position |
| `bin/sc` `_filter_rules()` (`sc:870-898`) and both call sites (`sc:1588-1589`) | It must keep one definition and no array-name parameter; the new rule is designed to survive it, not to change it |
| `bin/sc` `_write_private()`, `load_settings()` / `save_settings()` (`sc:444-449`) | NFR-4 — `settings.json` keeps being written exactly as it is written today |
| `bin/sc` `main()`'s read-only opt-out arm (`sc:2646-2651`) | K-10 — `doctor` stays the one positively named read-only command |
| `bin/sc` the `# doctor` block (`sc:1710`ff), `cmd_status`, `cmd_now`, `cmd_ls`, `cmd_use`, `cmd_mode` | Out of scope items 2 and 3 — T-20 owns any doctor row |
| `/home/alan/Programs/singbox-cli/install.sh`, `uninstall.sh`, `systemd/` | Out of scope item 12 and NFR-3's permitted diff |
| `/home/alan/Programs/singbox-cli/CONTEXT.md`, `.harness/**`, `docs/tasks.md` | NFR-3 — outside the permitted diff; RS-6 carries what they would otherwise receive |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | L-1, L-3 | none | revert two lines; nothing reads them yet |
| 2 | L-5 | L-1, L-3 landed | delete the four new definitions; no caller yet |
| 3 | L-2 | none | delete the ten pairs |
| 4 | L-4, L-7 | L-5 landed; **V-3's HEAD baseline captured at the same fixture path first** (`.harness/insight-index.md:23`) | revert both; the emitted document returns to HEAD's shape byte for byte, and no state on any host needs repair — the change is in the generated artifact only |
| 5 | L-8, L-9, L-11 | L-5 landed | revert; `sc ipv6` disappears and the persisted key is simply never read |
| 6 | L-10 | L-3 landed | revert one expression; the handler names `OVERRIDE_PATH` again |
| 7 | L-12…L-15 | code steps landed | revert the docs |
| 8 | L-16 | all above | — |
| U-1 | upgrade of an existing host (BC-16) | the new `bin/sc` is installed and `sc reload` is run; no file under `/etc/sing-box` is hand-edited | reinstall the previous `sc` and run `sc reload`: the configuration is regenerated, never patched, and the `ipv6` key left in `settings.json` is ignored by the old build (BC-8's shape in reverse) |
| U-2 | a host whose `settings.json` has no `ipv6` key | nothing to do — absence **is** `auto` (Q-8); nothing is written to seed it, so `_init_files()` and the installer are unchanged | — |
| U-3 | this host's `sed` hand-patch at `/usr/local/bin/sc` (BC-17) | overwritten by the next `install.sh` **by design**; the shipped default reproduces its effect here because `auto` suppresses on a host with no global IPv6 | `sc ipv6 on` |

## Out of scope

- Re-pointing `dns.final`, adding an unconditional DNS rule, or any other construction presented as a resolver that answers after another one fails — no such mechanism exists in this build (I-16, K-13, requirement out-of-scope items 13 and 14).
- Bounding a DNS query inside sing-box, or emitting any key that expresses a wait — measured absent (Q-2); this task neither invents nor emulates one (K-17).
- Any change to the emitted `log` region, and any new `sc`-side signal for a query sing-box abandons: no `sc` process is alive at that moment (Q-19, requirement out-of-scope item 15).
- Bounding a **node outbound's** dial or handshake — the only other place BC-2's hang could be bounded, and out of scope item 4 forbids it.
- Any DNS rule serving the telemetry reject list, and any opinion about where T-17's rule sits beyond leaving both positions expressible (Q-13).
- Any `sc doctor` section, including a DNS-timing or IPv6-consistency check — T-20 owns them.
- Any change to `sc status` / `now` / `ls` / `use` / `mode`, to `route.*`, to `outbounds`, to the `proxy` selector or to the auto-select group.
- Enlarging, shrinking or moving `sc`'s three socket waits.
- R-15, R-16, R-19, R-20, R-21 — each has a named owner elsewhere; `_merge`'s type-mismatch vocabulary stays open and unclaimed (Q-1).
- A committed test harness or a new `verify_all` step (R-9 owns it); every fixture below is throwaway and is pasted into the stage documents.
- Any daemon, timer or hook that regenerates the configuration when the host's IPv6 state changes (BC-13).
- Defending the emitted document against a user `override.json` that `$replace`s `dns.rules` or `dns.servers` (BC-15 — the documented contract).
- IPv6 handling outside name resolution: no `domain_strategy`, no inbound address, no route-level IPv6 rule.

## Verification plan

Every fixture obeys NFR-6: the `docs/dev-map.md:109-137` import recipe verbatim, **eight** path constants
(the seven of T-14/T-15 plus `IF_INET6_PATH`) inside one `mkdtemp()` root **and asserted so**,
`SYSTEMD = OPENRC = False`, `_init_files()` never driven, `LANG` set the way `main()` does, no
`PUT`/`PATCH`/`DELETE` to the live Clash API, and every second sing-box unprivileged with no TUN inbound,
its own `cache_file.path` and its own Clash port. Service witness at every checkpoint:
`systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`.

**Behavioural fixtures — three derivations of the emitted document, and no fourth.** (1) *Inbound*: the
TUN inbound is replaced by a `direct` inbound on `127.0.0.1` at a free port, and queries are submitted
with `dig @127.0.0.1 -p <port>`; `route.rules`' `{"action": "sniff"}` (`sc:1122`) must stay ahead of
`hijack-dns` (`sc:1123`) or the inbound forwards the packet to itself in a silent loop instead of erroring
(K-15). (2) *Servers*: `remote_dns` and `direct_dns` are repointed at two local stub resolvers, with every
tag, the array order, `detour: proxy` and all of `dns.rules` preserved; `route.default_domain_resolver`
(`sc:1118`) must stay present or 1.13.15 fails `check` (K-15). (3) *Paths*: `cache_file.path` and
`clash_api.external_controller` move inside the fixture root. **Node state is staged at the `proxy`
outbound, never at a stub** — *unusable* = a TCP listener that accepts and never completes the handshake,
*refusing* = a closed port, *usable* = a `direct` outbound tagged `proxy`; at zero nodes the selector
collapses to `direct` by construction (`sc:1438-1440`), so no node state is stageable there. Every HEAD
control run (AC-B10) uses the identical derivation. **A probe name for a defect-reproducing control must
be one HEAD routes to `remote_dns`** — matched by no DNS rule, or a `geosite-google` name; a domestic name
reaches `direct_dns` at HEAD and reproduces nothing.

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-3 | Differential `generate_config()`, HEAD clone vs candidate, **same** fixture path, suppression **off** (`sc ipv6 on`), all rule-sets usable | `dns.rules` differs from HEAD in exactly one way — the `query_type` element moved from index 3 to index 0, its list exactly `[64, 65]` in that order; `dns.final` is byte-identical (`remote_dns`); `dns.servers` and every other array and key byte-identical | AC-2, AC-10 |
| V-4 | Same fixture with suppression **in effect** | `dns.rules[0]` is `{"action": "predefined", "rcode": "NOERROR", "query_type": [28, 64, 65]}` and carries no `answer` key | AC-1 |
| V-5 | Index comparison over the emitted `dns.rules` in all four combinations of {suppression on, off} × {all rule-sets usable, none usable} | `index(I-7) == 0`, strictly less than the index of both `clash_mode` rules and of every rule whose `server` is `remote_dns`; the surviving order matches I-17 in each state; the anchor `{"clash_mode": "Direct"}` still matches exactly one element, so T-17's slot stays expressible | AC-3 |
| V-6 | The same two rule-set states, comparing the emitted arrays | the added rule is present in both states and carries no `rule_set` key | AC-4 |
| V-7 | **Real** `/usr/local/bin/sing-box check` on the emitted document in each of: 0 nodes, 1 node, 3 nodes, suppression on, suppression off, all rule-sets unusable | all six accepted | AC-5 |
| V-8 | `ast` extraction and byte comparison of `_merge`, `_directive_of`, `_apply_directive`, `DIRECTIVES`, `_load_override` against HEAD | byte-identical | AC-8 |
| V-9 | `ast` extraction of the `timeout=` keyword argument of `clash_api()`, `_egress_ip()` and `_fetch_to_temp()` | `3`, `8`, `30` unchanged; no `grep` used | AC-9 |
| V-10 | Repository-wide search for a second derivation of the decision; deletion test on `ipv6_decision()`'s second caller | exactly one definition, two callers, no re-derivation | AC-6 |
| V-11 | **Both halves of AC-7.** (a) Walk the emitted JSON in each of V-7's six states for any key whose name contains `timeout`, and for `dns.final` ≠ `remote_dns`. (b) `ast`/diff scan of `bin/sc` for a new module constant or literal expressing a wait | (a) no such key in any of the six states; `dns.final` is `remote_dns` in all six. (b) the diff introduces no wait constant and no new `timeout=` argument | AC-7 |
| V-12 | `sc ipv6 on`, `off`, `auto`, `show` in a redirected fixture, `LANG` in `en` and `zh` (eight runs) | each exits 0; each prints the setting line and, except in the FR-7 case, the evidence sentence; no `\r`, one complete line per fact | AC-11, BC-20 |
| V-13 | `sc ipv6 show` with an mtime witness over the whole fixture root and shimmed `systemctl`/`rc-service` | no file mtime changes; no init command invoked; no socket opened | AC-12 |
| V-14 | `sc ipv6 auto` on a host already deciding `auto`, and `sc ipv6 on` on a host with a global IPv6 address (decision unchanged) | `config.json` mtime unchanged; shims record no invocation; the `Nothing changed …` line printed once | AC-13 |
| V-15 | `sc ipv6 off` on a host currently not suppressing | the emitted document's `dns.rules[0]` gains `28`; the service is restarted once; the `Configuration regenerated …` line printed | AC-14 |
| V-16 | Three `settings.json` fixtures — absent, present without `ipv6`, present with `"ipv6": "yes"` — in both languages | all three decide `auto`; only the third writes one stderr line, naming file, key and the three accepted values | AC-15, BC-8, BC-9 |
| V-17 | Four `IF_INET6_PATH` fixtures: this host's real seven-entry content; the same plus a `2000::/3` address on `enp3s0`; the same plus a `2000::/3` address on `sb-tun` only; an empty file | no global IPv6 / global IPv6 on `enp3s0` / **no** global IPv6 / no global IPv6 | AC-16, BC-5, BC-6 |
| V-18 | `IF_INET6_PATH` removed, and a malformed one (a single line of prose) | both yield no suppression plus exactly one stderr line naming the cause and the assumption; no traceback | AC-17, BC-7 |
| V-19 | BC-16 upgrade fixture (a pre-T-16 `config.json` plus its matching `.config.sha256`): `sc reload`, then a second `sc reload` | first reload succeeds with no hand-editing and **no** drift warning; the record then matches the new file; the second reload is silent too | AC-18, BC-16 |
| V-20 | Parity check over the ten new keys: `zh` entry present, `set(re.findall(r"{(\w+)}", key))` equal on both sides, no `失败：`, no `ls.*`-shaped key | all pass | AC-19 |
| V-21 | Read both READMEs; line-count and section-order comparison; read `CHANGELOG.md`; grep both READMEs for any fallback/second-resolver/wait claim (K-16) | both document `sc ipv6`, the effective-decision rule, I-17's per-mode class, BC-22's limit and BC-4's consequence, and stay line-for-line mirrors; no sentence claims a fallback resolver or a configured wait; the changelog entry is in Chinese under `### 新增` | AC-20 |
| V-22 | Read `HELP_EN` and `HELP_ZH` | both carry the `ipv6` row at the existing column alignment | AC-21 |
| V-23 | Fault-injected overlay: a fixture in which `_dns_overlay()` returns a directive against a key the base does not define, with and without a user `override.json` present | the message names `config.json`, never `override.json`, in both runs; the user-document failures still name `override.json` | AC-22 |
| V-24 | `python3 -m py_compile bin/sc`; 3.6-syntax scan of the diff; import scan | passes; no walrus, no `dataclasses`, no `capture_output=` added, no non-stdlib import | AC-23 |
| V-25 | `bash .harness/scripts/verify_all.sh` | no FAIL against the 17/0/0/1 baseline. **Predicted WARN:** F.6 doc-size on this task's stage documents once `04`/`06` land — it clears on `archive-task` and is predicted here, before code is written | AC-24 |
| V-26 | Behavioural, node **unusable** (accepts, never answers), suppression in effect, all rule-sets usable, `rule` mode. Three probes, each timed from `dig` start: a `hosts_dns` name (`doh.pub`, type A), a domestic-suffix name (`360.cn`, type A), and a suppressed type (AAAA of a name matched by no rule) | all three answered, each within 100 ms; the proxied stub records nothing | AC-B1 |
| V-27 | V-26 with the fixture rules directory empty (degraded config) | the same three probes answered within 100 ms — this is exactly BC-4's subset | AC-B2 |
| V-28 | V-26 with the `proxy` outbound pointed at a closed port | the same three probes answered within 100 ms | AC-B3 |
| V-29 | Suppression in effect, node **unusable**, `rule` mode: one AAAA query for a name HEAD routes to `remote_dns` | empty `NOERROR` within 100 ms, no records; the proxied stub records nothing. HEAD control: the same query stalls and is abandoned at ≈10 s | AC-B4 |
| V-30 | The same fixture regenerated after `sc ipv6 on`, node **usable** | the proxied stub records the AAAA query and it resolves normally | AC-B5 |
| V-31 | V-29 repeated with the **fixture** instance's own Clash API set to mode `global`, then `direct` | candidate: empty `NOERROR` within 100 ms in both modes, no stub records the query. HEAD control: in `global` the query stalls at ≈10 s; in `direct` it does **not** stall — HEAD's `clash_mode: Direct` rule sends it to `direct_dns`, so the reproduced defect there is that the non-proxied stub records the AAAA query and answers it (see RS-10) | AC-B6, BC-18 |
| V-32 | Node **usable**, both stubs instrumented. Six probe names, all type A — a `hosts_dns` name, a domestic-suffix name, a `geosite-cn` name, a `geosite-private` name, a `geosite-google` name, one matched by no rule — × both rule-set states × all three routing modes, each compared against a HEAD-clone run of the identical fixture | the same stub receives each probe name in both runs, in all 36 combinations; in the degraded state the three rule-set names reach the **proxied** stub in both runs; type A is used throughout, because the suppressed types are the one class whose answering resolver FR-2/Q-4 deliberately changes | AC-B7 |
| V-33 | Node **unusable**, both stubs instrumented, one name matched by no DNS rule, `dig +tries=1 +timeout=15` (larger than sing-box's 10 s deadline); wall clock recorded client-side in both runs | sing-box returns no answer; **neither** stub records the query; the client's outcome arrives at its own 15 s limit, and the HEAD control's wall clock is no smaller | AC-B8 |
| V-34 | V-26's three probes on a 0-node fixture (`proxy` collapses to `direct`, `sc:1438-1440`) | all three answered within 100 ms; the same document also passes V-7's 0-node check | AC-B9, BC-1 |
| V-35 | Every one of V-26…V-34 re-run against a pristine HEAD clone with the identical fixture and derivation, recorded verbatim | **Defect-reproducing** (AC-B4, AC-B6): V-29's and V-31's HEAD runs must exhibit the defect as their rows state. **Agreement** (AC-B1…B3, AC-B5, AC-B7…B9): the HEAD run must produce the candidate's outcome. A run whose control does neither is reported as **inconclusive**, never as a pass (NFR-7) | AC-B10 |
| V-36 | Non-vacuity for AC-B4: node **usable**, suppression in effect, the proxied stub instrumented; one AAAA and one type-A query for the same name | the stub records the A query and **no** AAAA query, so "issues no upstream query" is observed rather than inferred from an unreachable upstream; the HEAD control records both | AC-B4, AC-B10 |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RS-1 | **FR-13 report — what the composition layer could not express: nothing.** `$prepend` on an array `CONFIG_BASE` already defines carried the whole change, with no new directive, no anchor, and no configuration literal in `generate_config()`. The shortfall is one level down and is now measured rather than inferred: sing-box 1.13.15 offers no position at which a DNS-query-level wait can be written, its DNS rule chain never falls through on failure, and `dns.final` is the no-match routing default — so "a name whose only resolver is reached through a node stays unresolvable while that node accepts and never answers" is not expressible by any document this project emits. | `03_GATE_REVIEW.md`, `07_DELIVERY.md` |
| RS-3 | **BC-14's mechanism is unverified.** `route.default_domain_resolver` (`sc:1118`) pins dial-side lookups to `direct_dns`, so a node's own hostname lookup does not traverse `dns.rules` and AAAA suppression may not affect a node's reachability at all. Neither README may claim more than is observed; the honest text is "a node reachable only over IPv6 needs `sc ipv6 on`". | `04_DEVELOPMENT.md`, `06_TEST_REPORT.md` |
| RS-6 | **Two files this design would otherwise edit are outside NFR-3.** `CONTEXT.md` wants three entries (*effective IPv6 decision*, *AAAA suppression*, *node-independent class*); `.harness/rejected-decisions.md` wants three records (`connect-timeout-on-a-detoured-dns-server`, `dns-rule-catch-all-as-a-failure-fallback`, `unconditional-direct-dns-final`). Both are the PM's to apply at delivery. | `07_DELIVERY.md` |
| RS-7 | Insight candidates for harvest: (a) sing-box 1.13.15's DNS rule chain never falls through on a failed, negative or unanswered exchange, and `dns.final` is reached only when no rule matches — so no rule ordering can express a failure fallback; (b) sing-box's own per-query DNS deadline is 10.0 s, is not configurable, and at expiry the query is dropped silently; (c) a fixture inbound needs `{"action": "sniff"}` ahead of `hijack-dns` or a `direct` inbound loops silently, and 1.13.15 fails `check` outright without `route.default_domain_resolver`; (d) `/proc/net/if_inet6` on a host running this project always carries a link-local entry for `sb-tun`, so "any IPv6 address" is never a usable predicate here. | `07_DELIVERY.md` |
| RS-8 | This stage holds no shell, so every acceptance claim above is a prediction until stage 4 or 6 runs it; the mechanism claims it rests on were measured by the PM-commissioned probe against the real binary, not by this stage. | `03_GATE_REVIEW.md` |
| RS-9 | **The batch goal is not fully delivered, by measurement.** Delivered: the suppression class, its mode-independence, `sc ipv6`, the `OverrideError` provenance fix, and FR-11 as a tested no-regression guarantee. Not delivered, and not deliverable by any document this project emits: a name whose only resolver is reached through a node outbound stays unresolvable while that node accepts and never answers. It must be filed as an open row at delivery rather than left implicit in a green test report. | `07_DELIVERY.md` |
| RS-10 | **AC-B10's `direct`-mode clause is not reproducible as written.** It requires AC-B6's HEAD control to stall at ≈10 s in clash mode `direct`; at HEAD an AAAA query in that mode matches `{"server": "direct_dns", "clash_mode": "Direct"}` (`sc:1100`) and is answered by a resolver that is **not** reached through a node, so it cannot stall — the defect there is the absence of suppression, not a stall. (In `global` mode the same query does match `{"server": "remote_dns", "clash_mode": "Global"}` (`sc:1099`) and does stall, so that half of the clause is sound.) V-31 substitutes the equivalent defect-reproducing observation (HEAD issues and answers the AAAA query; the candidate answers it empty with no upstream query), which preserves AC-B10's substance. The AC text should be corrected to match. | `03_GATE_REVIEW.md`, `01_REQUIREMENT_ANALYSIS.md` |

## Verdict

**READY** — every requirement line has an implementable expression: FR-1…FR-7 and FR-16 in I-3…I-7 and
I-10…I-15, FR-8/FR-9's node-independent class in I-17's index relation (measured by V-26…V-28, V-34),
FR-10 in K-17 and V-11, FR-11 in I-16/K-13 (measured by V-32/V-33), FR-12 in I-7's absence of a
`rule_set` key, FR-13 in RS-1's report, FR-14 in I-11/I-12, FR-15 in K-5. One requirement defect is
carried rather than blocking: **AC-B10's `direct`-mode clause is unreproducible as written** (RS-10) — the
design satisfies AC-B6 and AC-B10's substance and names the correction the analyst should make; the gate
should rule on whether the AC text is amended now or at stage 6. Two limits are stated rather than
covered: sing-box abandons a proxied query at its own fixed 10 s deadline with no signal `sc` can emit
(Q-19), and RS-9's shortfall against the batch goal must be filed at delivery.
