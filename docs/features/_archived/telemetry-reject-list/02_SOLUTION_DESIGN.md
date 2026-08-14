# 02 — Solution Design · T-17 `telemetry-reject-list`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

Mode: **full**. Upstream `01_REQUIREMENT_ANALYSIS.md` verdict **READY**, read in full; `01_RATIONALE.md`
opened under **T2.1** for Q-2's delegated membership list (the contract's Q-2 points at it by name) —
no `## Resolved questions` answer is overridden. `.harness/rules/70-doc-size.md` carries no
`## Stage-doc boundary rule` section, so the agent schema is applied as written:
`## Byte-form specification` is absent (ungated — boundary rows 3 and 4 cannot have matched), the reuse
audit and the risks live in `02_RATIONALE.md`, the emitted rule's exact key set and key order are carried
by `## Interfaces` I-4 (a shape, as T-16's I-7 carried its own), and `## Partition assignment` is omitted
because this project has no partition developers (`.harness/rules/50-singbox-cli.md:110-121`). Ledger,
interface, constraint, step and residual ids are stable identifiers, not sequences.

`sc` below = `/home/alan/Programs/singbox-cli/bin/sc`. Line anchors are the working tree at `1e454b6`
plus the T-16 delivery on top. Every fact about `sing-box 1.13.15` below is from the PM-commissioned
probe (Q-A…Q-F), not from this stage — which holds no shell.

## Architecture summary

- **What changes:** one shipped datum (`TELEMETRY_NAMES`, 18 names), one reader of one settings key
  (`_telemetry_setting()`), one overlay (`_telemetry_overlay()`) that `$before`-anchors a single
  `predefined` rule into `dns.rules` ahead of both `clash_mode` rules, one command (`cmd_telemetry()`),
  six strings, one help row, one README section per language.
- **What does not change:** `_dns_overlay()` and its index-0 rule, `dns.servers`, `dns.final`,
  `independent_cache`, every other `dns.rules` element and their relative order, `_merge()` and its five
  directives, `_load_override()`, `_filter_rules()`, `_runtime_overlay()`, `route.*`, `outbounds`, the
  `proxy` selector, the auto-select group, `generate_config()`'s three-key guard, `_init_files()`,
  `install.sh` / `uninstall.sh` / `systemd/`.
- **Where the seam is:** the anchor `{"clash_mode": "Global"}` is the seam inside the document — the
  first mode-selection rule, so inserting before it is exactly "answer here, before anything chooses a
  path" (I-9); `_telemetry_setting()` is the seam in the code — the one place the effective setting is
  decided, with the list as inert data beside it.

## Change ledger

Total over every touched file. No partition developers exist, so the partition column reads `developer`
throughout. Nothing outside NFR-3's permitted diff appears here; what would otherwise land in
`CONTEXT.md` and `.harness/rejected-decisions.md` travels as RS-3/RS-4.

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| L-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# i18n` `TRANSLATIONS["zh"]`, immediately after the IPv6 block (`sc:165-183`): six new pairs, verbatim from Q-13 (I-8) | developer |
| L-2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# Config composition`, immediately after `_dns_overlay()` (`sc:1584`): add `TELEMETRY_NAMES` (I-2, N-1…N-18), `_telemetry_setting()` (I-3) and `_telemetry_overlay()` (I-5), in that order | developer |
| L-3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `generate_config()` `sc:1765`: `_telemetry_overlay()` becomes the **third** element of the existing `_compose([...])` list. One list element; no branch, no literal, no fourth key in the guard at `sc:1778` (I-6) | developer |
| L-4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `# Commands`, immediately after `cmd_ipv6()` (`sc:2477`): add `cmd_telemetry()` (I-7) | developer |
| L-5 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `main()` `sc:2882` and `sc:2912`: the `telemetry` subparser and its `handlers` entry (I-10) | developer |
| L-6 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `HELP_EN:2771` and `HELP_ZH:2834`: one `telemetry <block\|allow\|show>` row with two sub-option lines, inserted between the `ipv6` block and `default-tun` (I-11) | developer |
| L-7 | `/home/alan/Programs/singbox-cli/README.md` | edit | new `### Telemetry name rejection` between `### IPv6 name resolution` (`:113-138`) and `### Service control` (`:140`), carrying FR-12's six items: the complete list with its class and vendor, the FR-1 criterion, `sc telemetry` and its `block` default, the two override recipes verbatim as fenced JSON (I-9's anchors), how a rejection differs from a network failure, and the limits. No sentence may claim blocking beyond name resolution (K-11) or client-side caching (K-12) | developer |
| L-8 | `/home/alan/Programs/singbox-cli/README.zh-CN.md` | edit | the same edits at the mirrored positions — line-for-line mirror (AC-17) | developer |
| L-9 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | one Chinese bullet under `## [Unreleased]` → `### 新增` (`:3-5`) stating the `block` default and the two escapes | developer |
| L-10 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | `# Config composition` row (`:37`, the three new definitions), `# Commands` row (`:40`, `cmd_telemetry`), `# Config generation` row (`:38`, the composition is now three overlays), and one new reusable-utility row for I-2/I-3/I-5 | developer |
| L-11 | `/home/alan/Programs/singbox-cli/docs/features/telemetry-reject-list/04_DEVELOPMENT.md` | new | the Developer's own stage doc | developer |

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `/etc/sing-box/settings.json` key | `"telemetry": "block" \| "allow"` | The only key this task adds. Never seeded (`_init_files()` unchanged, Q-8): absent **is** `block`, so a fresh install and every upgrading host behave identically (BC-4). Written only by `cmd_telemetry()`, through the existing `load_settings()`/`save_settings()` pair — never `_write_private()` (NFR-4). |
| I-2 | `sc` module constant | `TELEMETRY_NAMES = (...)` — a tuple of 18 lowercase name strings in the order N-1…N-18 below, each with its one-line source justification as a trailing comment | THE single definition of the list (AC-6). Two consumers, I-5 and I-7; no third derivation and no per-consumer subset. A tuple, not a list or a dict, for the reason `RULESET_FILES` is one (`sc:96-98`): this order **is** the emitted `domain_suffix` order and must not depend on anything else. Not a path and not a wait, so it is admissible under AC-8; it joins no repoint list. |
| I-3 | `sc` function | `_telemetry_setting() -> str` — returns exactly `"block"` or `"allow"` | **THE definition of the effective setting (FR-6/AC-6).** Shaped like `_ipv6_setting()` (`sc:1439-1465`): `load_settings()` guarded by `except (FileNotFoundError, json.JSONDecodeError, OSError)` → `"block"`, silently (BC-5's second clause — no new failure mode, no traceback, no widening of R-25); key absent → `"block"`; a value present but not one of the two exact lowercase strings → `"block"` **plus one stderr line** naming file, key and the two accepted values (BC-5). Reads one file; writes nothing; performs no service-affecting action. There is deliberately **no** `telemetry_decision()` sibling: unlike IPv6 there is no host-derived input, so the setting *is* the decision and a second function would be a second name for one value. |
| I-4 | emitted `config.json` · the reject rule | `{"action": "predefined", "rcode": "NXDOMAIN", "domain_suffix": [<the 18 names, in I-2 order>]}` — exactly these three keys, in this order, values as written | Measured (Q-A): accepted by `sing-box check`, and at run it answers `NXDOMAIN` with `ANSWER: 0`, flags `qr aa rd ra`, in ~4 ms, with neither stub resolver recording the query across ~40 probes. **`answer` is omitted entirely** — `predefined` with `rcode: "NXDOMAIN"` and a non-empty `answer` emits `NXDOMAIN` *with* `ANSWER: 1` and still passes `check` (Q-B trap 1). **`rcode` is written explicitly and uppercase** — omitted it defaults to `NOERROR` (trap 2) and `"nxdomain"` is a hard `check` failure (trap 3). No `answer`, no `rule_set` (so `_filter_rules()` keeps it unconditionally, `sc:902-907`, FR-5), no `server`, no `query_type`, no `domain` companion key. `domain_suffix` alone is total for FR-3 and BC-9: in 1.13.15 it is **label-boundary aware** (Q-C) — `example.com` matches the apex and every subdomain at any depth, case-insensitively, and does not match `notexample.com`, `xexample.com` or `example.com.evil.net`. A leading dot would silently leave the apex resolvable and is forbidden by K-5. |
| I-5 | `sc` function | `_telemetry_overlay() -> dict` — `{"dns": {"rules": {"$before": {"match": {"clash_mode": "Global"}, "values": [<I-4>]}}}}` under `block`, and `{}` under `allow` | The ONE place the list reaches the document. Calls I-3 exactly once and consumes nothing else. `$before` is an existing directive (FR-10) on an array `CONFIG_BASE` always defines; the anchor is an object, never an index, which is the capability T-14's D-7 built for exactly this second insertion (`sc:1084-1088`). Under `allow` it returns the empty document, which `_merge()` treats as a no-op by iteration, so `dns.rules` is byte-identical to the pre-T-17 build (AC-4) with no branch in `generate_config()`. It emits `list(TELEMETRY_NAMES)`, never the tuple object, and emits no other key anywhere in the document. |
| I-6 | `sc` function | `generate_config()`: `config = _compose([_runtime_overlay(nodes, active, report), _dns_overlay(), _telemetry_overlay()])` | The only edit to this function: one list element. The user's `override.json` is still merged **after** `_compose()` at its own site (`sc:1766-1771`), so both recipes of I-9 anchor against a document that already contains the reject rule. Overlay order inside the list is **not** load-bearing — `$prepend` at index 0 and an anchored `$before` commute, because the anchor is resolved by content — but it is fixed as written so that source order matches emitted order. `generate_config()` gains no configuration literal and no fourth key in its three-key guard (AC-8); its `OverrideError` provenance wrappers are untouched, and a fault inside I-5 is still rendered against `CFG_PATH`, never `override.json` (T-16 I-12). |
| I-7 | `sc` command | `cmd_telemetry(args)`; call flow: `val = args.value.lower()`; anything outside `block\|allow\|show` → `sys.exit(t("Error: argument must be one of block / allow / show"))`; **show** → one `_telemetry_setting()` call, print the setting line, print the meaning sentence, then print each element of `TELEMETRY_NAMES` on its own line, return; **set** → `before = _telemetry_setting()`, `load_settings()` / assign / `save_settings()`, `setting = _telemetry_setting()`, print the setting line and the meaning sentence, then `setting == before` → print the FR-8 no-op line naming `sc reload` and return, else `reload_or_restart()` → print `Configuration regenerated; sing-box restarted`, or `sys.exit(t("Reload failed"))` | `show` writes no file, issues no network request and performs no service-affecting action (AC-11) — scoped to this function, exactly as `cmd_ipv6()` states it: `main()`'s start-up path runs for `sc telemetry` as for every non-`doctor` command, and its writes are neither counted against that property nor claimed absent (BC-16). A set that leaves the effective setting unchanged performs no service-affecting action (FR-8/AC-12); the comparison is between two results of I-3, so no second opinion is created. The setting is persisted on **every** set, including a no-op one, so `sc telemetry block` repairs a hand-edited unrecognised value. Exit 0 on all three forms in both languages (AC-10). |
| I-8 | `TRANSLATIONS["zh"]` | the six pairs fixed by Q-13, inserted after the IPv6 block (`sc:165-183`) | Every key is the English sentence itself (no `ls.*` namespacing); each `zh` value carries the identical placeholder set; no `zh` value contains `失败：` (FR-13/AC-16). Six is the whole budget: `Configuration regenerated; sing-box restarted` (`sc:183`) and `Reload failed` (`sc:138`) are **reused**, and no seventh string ships — which is why the per-name lines of `sc telemetry show` carry the name and nothing else (K-9). |
| I-9 | emitted `config.json` · `dns.rules` index order and its two published anchors | `[0]` T-16 suppression · `[1]` `hosts_dns` · **`[2]` the reject rule (block only)** · `[3]` `clash_mode: Global` · `[4]` `clash_mode: Direct` · `[5]` `geosite-google` · `[6]` `geosite-private` · `[7]` domestic `domain_suffix` · `[8]` `geosite-cn`. Published anchors — **superseded at stage 4 under gate condition C-4 (DD-1/DD-2), corrected here by PM amendment at delivery per RES-5/D-5:** this row originally published `{"rcode": "NXDOMAIN"}` for the exception recipe and `{"clash_mode": "Global"}` for the addition recipe. **Both were replaced by `$after {"server": "hosts_dns"}`**, which all three shipped recipes now use. The first was measured to exist only under `block`, so a user carrying that recipe hit an uncaught `OverrideError` and `sc telemetry allow` exited 1 with the setting already persisted; the second resolves *after* the shipped rule and so cannot except anything. `{"clash_mode": "Global"}` remains a correct **internal** anchor for `_telemetry_overlay()` itself and is not published; `{"clash_mode": "Direct"}` is the other user-published anchor, shipped since T-14 | **This is where FR-4 and FR-9 are discharged.** The index relation — greater than the `hosts_dns` rule's, strictly less than both `clash_mode` rules' and than every rule whose `server` is `remote_dns` — holds in all four {`block`,`allow`} × {all rule-sets usable, none usable} states, because `_filter_rules()` can only delete `[5]`, `[6]`, `[8]`. Measured why it matters (Q-D): with the rule placed *after* the two `clash_mode` rules, a listed name in mode `Global` and in mode `Direct` returns `NOERROR` with 1 record **and the query is recorded by an upstream stub** — the exact leak the feature exists to prevent, in both non-`rule` modes. `{"rcode": "NXDOMAIN"}` matches exactly one element in every state in which the rule exists and nothing else in the document carries that key/value; `{"clash_mode": "Global"}` matches exactly one element in **both** settings states (T-16 V-5 measured both `clash_mode` anchors at exactly one), which is what makes the BC-8 recipe work under `allow` too. |
| I-10 | `sc` CLI surface | `sc telemetry <block\|allow\|show>` — `p = sub.add_parser("telemetry"); p.add_argument("value")`, `handlers["telemetry"] = cmd_telemetry` | Shaped exactly like `sc ipv6` / `sc mode` / `sc lang`: one positional value, lower-cased by the handler (BC-12), values language-neutral so `sc lang` cannot move them. `sc telemetry` with no argument takes argparse's own required-argument error and exit 2, identical to `sc ipv6` today and deliberately not special-cased. `main()`'s read-only opt-out arm (`sc:2903-2908`) is **not** touched: `telemetry` takes the `else` arm like every other command (K-14). |
| I-11 | `HELP_EN` / `HELP_ZH` | one row `telemetry <block\|allow\|show>` plus two sub-option lines, between the `ipv6` block and `default-tun` | The left column is 28 characters, so with its two-space indent it reaches column 30 and the description follows after **two** spaces — the convention the existing overflowing row `update-interval <freq\|show>` (`HELP_EN:2781`, `HELP_ZH:2843`) already uses. Sub-option lines at column 32, as every other block. Hand alignment preserved in both languages (AC-19). |
| N-1 | `telemetry.microsoft.com` | class 1 — desktop-OS diagnostics | Microsoft — the Windows diagnostics/error-reporting subtree: `watson.` (Windows Error Reporting crash uploads), `oca.` (Online Crash Analysis) and `sqm.` (Software Quality Metrics / CEIP usage counters) all sit under it and are covered by the one suffix. FR-1 second clause: blocking loses crash-report submission only; no Windows function the user can see stops. |
| N-2 | `vortex.data.microsoft.com` | class 1 | Microsoft — the Connected User Experiences and Telemetry (DiagTrack) upload endpoint for Windows diagnostic data. Listed as diagnostic-data in Microsoft's own connection-endpoint documentation. Nothing user-visible depends on it. |
| N-3 | `vortex-win.data.microsoft.com` | class 1 | Microsoft — the Windows-specific sibling of N-2, same diagnostic-data upload role. Listed by host rather than as `data.microsoft.com`, because that apex also carries `settings-win.data.microsoft.com`, which FR-1's second clause excludes (settings/update policy). |
| N-4 | `metrics.ubuntu.com` | class 1 | Canonical — the endpoint `ubuntu-report` POSTs the installer/hardware survey to. Sole function is measurement; nothing on the host waits on it. |
| N-5 | `daisy.ubuntu.com` | class 1 | Canonical — the whoopsie/Apport crash-report submission endpoint. Blocking it means crash reports are not uploaded; the crash itself, and every desktop function, are unaffected. |
| N-6 | `incoming.telemetry.mozilla.org` | class 2 — browser telemetry | Mozilla — the Firefox Telemetry ping submission endpoint (main, event and health pings). Documented as such by Mozilla. Firefox loads no content from it. |
| N-7 | `telemetry-coverage.mozilla.org` | class 2 | Mozilla — the Firefox "coverage" ping endpoint, a sampled measure of whether telemetry reporting itself is enabled. Its only possible payload is a measurement of the browser's own reporting state. |
| N-8 | `google-analytics.com` | class 3 — dominant global analytics / crash-reporting SDK | Google — Google Analytics hit collection (`/collect`, `/g/collect`); the suffix also covers `www.` and `ssl.`. Sites load it asynchronously and gate no content on it. `analytics.google.com` is deliberately **not** listed: it also serves the Analytics console UI (K-10). |
| N-9 | `app-measurement.com` | class 3 | Google — the Firebase / Google Analytics for Firebase mobile SDK measurement upload host. It carries app usage events and the advertising identifier and serves no app content. |
| N-10 | `crashlytics.com` | class 3 | Google — Firebase Crashlytics crash and session reporting (`reports.`, `e.`, `settings.`, `firebase-settings.` all sit under it). Blocking it disables crash reporting only. |
| N-11 | `demdex.net` | class 3 | Adobe — the Experience Cloud ID / Audience Manager service: cross-site visitor identification and audience segment sync. It delivers no page content. `omtrdc.net` is deliberately **not** listed, because Adobe Target shares it and does deliver page content (K-10). |
| N-12 | `scorecardresearch.com` | class 3 | Comscore — audience-measurement beacons (`sb.scorecardresearch.com/b`). The endpoint's entire published purpose is panel measurement; it returns no content a page uses. |
| N-13 | `hm.baidu.com` | class 4 — dominant domestic analytics SDK | Baidu — Baidu Tongji (百度统计) web analytics: the `hm.js` collector and its `hm.gif` beacon. Loaded asynchronously by sites; nothing is gated on it. |
| N-14 | `cnzz.com` | class 4 | Umeng+/CNZZ (Alibaba) — the CNZZ web-analytics counter and log collection domain (`z*.cnzz.com`, `c.cnzz.com`, `w.cnzz.com`). The console for site owners lives on `umeng.com`, not here. |
| N-15 | `mmstat.com` | class 4 | Alibaba — the group's usage/behaviour logging domain (`log.`, `gm.`, `sre.` and siblings). The whole domain is beacon collection; no Taobao/Tmall page content is served from it. |
| N-16 | `ulogs.umeng.com` | class 4 | Umeng (Alibaba) — the U-App analytics SDK's log upload host. Listed by host, **not** as `umeng.com`: that apex also carries U-Push message delivery, which FR-1's second clause excludes, and the vendor's own console. |
| N-17 | `tracking.miui.com` | class 4 | Xiaomi — MIUI's system usage/analytics upload host. Named for its role; carries no update, activation or push traffic (those are separate MIUI hosts). |
| N-18 | `data.mistat.xiaomi.com` | class 4 | Xiaomi — the MiStat statistics SDK's data upload host, used by Xiaomi's own applications for usage counters. Blocking it removes reporting only. |

## Constraints

**K-1** — The implementer must keep `TELEMETRY_NAMES` (I-2) the only definition of the list and
`_telemetry_setting()` (I-3) the only definition of the effective setting, and must not re-derive either
at a call site: deleting one consumer of each must leave the other working unchanged (AC-6's deletion
test).

**K-2** — The implementer must emit the reject rule with exactly the three keys of I-4, in that order,
and must **omit `answer` entirely**; a `predefined` rule with `rcode: "NXDOMAIN"` and a non-empty
`answer` passes `sing-box check` and emits a self-contradictory `NXDOMAIN` carrying one record (Q-B).

**K-3** — The implementer must write `rcode` explicitly as the uppercase string `"NXDOMAIN"`: an omitted
`rcode` defaults to `NOERROR`, and a lowercase value fails `sing-box check` outright.

**K-4** — Nobody on this task may emit, or use as a control, a DNS rule with `{"action": "reject"}` in
any form. `reject` bare and `method: "default"` answer `REFUSED`, `method: "drop"` answers nothing at all
(the shape Q-4/BC-15 forbid), and the `reject` decoder **accepts unknown fields** — so a bogus-key
acceptance control is sound only against `predefined`, and a `reject` rule carrying `rcode` validates and
silently does nothing.

**K-5** — The implementer must express the list as `domain_suffix` entries with **no leading dot** and
must add no second matcher key (`domain`, `domain_regex`, `domain_keyword`) to the rule. Measured (Q-C):
one dotless `domain_suffix` entry matches the apex and every subdomain at any depth and does not match a
character-suffix near-miss; a leading dot silently leaves the apex resolvable, and a `domain` +
`domain_suffix: [".x"]` pair yields the identical result set at twice the size.

**K-6** — The implementer must not touch `_dns_overlay()` (`sc:1562-1583`) or the position of the rule it
emits: T-16's suppression rule keeps index 0 (FR-11), and a listed name's AAAA query is therefore
answered by it — an empty `NOERROR`, not `NXDOMAIN` — while suppression is in effect (BC-10). Both
orderings were measured and **neither leaks a listed name upstream** (Q-E); this one is kept because it
keeps T-16's rule unconditional-by-type, which is what makes its class statable in one sentence, and the
user-visible outcome of the two is identical (no address, no delay, no upstream query).

**K-7** — The implementer must not touch `_merge`, `_directive_of`, `_anchor_index`, `_apply_directive`,
`DIRECTIVES`, `_load_override` or `_filter_rules` (AC-7), and must express every change to the emitted
document through `CONFIG_BASE` or through an overlay applied by the existing `_merge()` with an existing
directive (FR-10). If something cannot be expressed that way it is reported as a finding naming what
could not be expressed — never by widening the vocabulary (RS-1 is this task's report).

**K-8** — The implementer must add exactly Q-13's six strings, verbatim in both languages, and no
seventh; `Configuration regenerated; sing-box restarted` and `Reload failed` must be reused rather than
duplicated (I-8).

**K-9** — Because the string budget is closed, each line of `sc telemetry show`'s list is the name and
nothing else; the implementer must not attach a per-name description, class label or vendor to that
output. The per-name justification lives in the source comment beside each name (English, project
convention) and in both READMEs (bilingual by mirroring), which is where FR-1/Q-2 place it.

**K-10** — The implementer must not add a name to `TELEMETRY_NAMES` that is not in N-1…N-18, and must not
drop one without saying so. A name whose sole function is not carrying usage, diagnostic, crash or
advertising-identifier data, or whose blocking disables a user-visible function of its product, is
excluded whatever its data-collection role — `analytics.google.com`, `omtrdc.net`, `googletagmanager.com`,
`settings-win.data.microsoft.com`, `connect.facebook.net`, `clients2.google.com`, push hosts
(`msg.umeng.com`, `mtalk.google.com`), safe-browsing hosts and `doubleclick.net` are the worked
exclusions, and each is named in `02_RATIONALE.md` with its reason.

**K-11** — Nobody writing user-facing text for this task — either README, the changelog, the help blocks
or any new string — may state or imply that it blocks telemetry carried over a client's own encrypted
resolver, over an IP literal, or by any path that does not traverse this document's DNS rules (NFR-10),
nor that anything is blocked at the IP or route layer (Q-14).

**K-12** — No shipped text and no stage document may state that a rejected name is negatively cached by
the client. Measured (Q-F): the reply carries `AUTHORITY: 0` and no SOA record, so a downstream resolver
has no RFC 2308 MINIMUM to derive a negative TTL from, and **whether any client caches it was not
measured**. The rule's justification is semantic — it denies the *name*, not a *type* — and needs no
caching claim (RS-2 carries the correction back to `01`'s Q-5 wording).

**K-13** — The implementer must keep the diff inside NFR-3's permitted set: `bin/sc`, both READMEs,
`CHANGELOG.md`, `docs/dev-map.md` and this task's stage documents. `CONTEXT.md`,
`.harness/rejected-decisions.md` and `docs/tasks.md` are **outside** it and are recorded as residuals
(RS-3, RS-4) rather than edited.

**K-14** — The implementer must not modify `main()`'s read-only opt-out arm, must not add a
`READ_ONLY_COMMANDS` set or a per-command flag, and must not drive `_init_files()` from any fixture — it
hard-codes `/var/lib/sing-box` (NFR-6, `.harness/insight-index.md:12`).

**K-15** — Every freeze check written for AC-7 and AC-8 must extract the symbol with `ast` and compare
bytes; a `grep` check is unsound here for the reason T-16 recorded (a textual prefix match).

**K-16** — Whoever builds a fixture must obey NFR-6 verbatim: neutralise the import-time auto-elevate
with the `docs/dev-map.md:109-142` recipe and no other, repoint all **eight** path constants into one
`mkdtemp()` root **and assert every one resolves inside it**, never drive `_init_files()`, never write
under `/etc` or `/var/lib`, never invoke `/usr/local/bin/sc`, set `SYSTEMD = OPENRC = False`, issue no
`PUT`/`PATCH`/`DELETE` to the **live** Clash API, use
`systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` as the service witness (never `is-active`),
run every second sing-box unprivileged with no TUN inbound, its own `cache_file.path` and its own Clash
port, and use the **same** fixture path plus a **clone** (never a `git worktree`) for every differential.

**K-17** — Whoever builds a behavioural fixture must obey NFR-7 verbatim: `{"action": "sniff"}`
(`sc:1162`) stays ahead of the `hijack-dns` rule (`sc:1163`) or a `direct` inbound forwards the DNS
packet to itself in a silent loop; `route.default_domain_resolver` (`sc:1158`) stays present or 1.13.15
fails `check` outright; `dig … ANY` uses TCP and measures the harness rather than the document; and a
`.test` probe name is matched by `geosite-private` and is **not** a no-rule-class name.

**K-18** — Every `dig` probe in this task's verification must pass `+nocookie` (or `+noedns`): `dig`'s
default EDNS COOKIE defeats sing-box's upstream cache entirely — 5 client queries became 5 upstream
queries with it and 1 without — so any step about caching or "was upstream contacted twice" is otherwise
measuring the cookie. Every latency assertion against FR-3's 100 ms budget must state that a `dig`
subprocess costs ≈17.5 ms of startup on this host (in-process probes measured 1.6–2.6 ms; sing-box
itself reports 4 ms), so a `dig`-driven harness is asserting ≈82 ms of headroom, not 100 ms.

## Frozen set

| path | why frozen |
|---|---|
| `bin/sc` `DIRECTIVES` (`sc:1089`), `_directive_of` (`sc:1196`), `_anchor_index` (`sc:1222`), `_apply_directive` (`sc:1245`), `_merge`, `_load_override`, `_filter_rules` (`sc:895-925`) | AC-7 — byte-identical to HEAD; the whole design is expressed with what they already do |
| `bin/sc` `_dns_overlay()` (`sc:1562-1583`) and `ipv6_decision()` / `_ipv6_setting()` / `_global_ipv6_iface()` | FR-11, K-6 — T-16's rule keeps index 0 and its contract; this task neither moves, alters nor duplicates it |
| `bin/sc` `CONFIG_BASE["dns"]` (`sc:1118-1150`) entirely — `servers`, every existing `rules` element and their order, `final`, `independent_cache` | Out-of-scope item 1 and FR-11; I-9's index relation is a property of exactly these elements, and reordering one silently changes which class survives BC-2 |
| `bin/sc` `_runtime_overlay()` (`sc:1586`ff) and everything it emits — `outbounds`, the `proxy` selector, the auto-select group, `route.rule_set` | Out-of-scope item 2; T-15's differential and AC-4 both rest on it being untouched |
| `bin/sc` `CONFIG_BASE["route"]` (`sc:1157-1177`), `default_domain_resolver` and the `sniff` / `hijack-dns` pair included | Out-of-scope item 2; K-17 depends on `sc:1162-1163`, and no route-level reject is admissible (Q-14) |
| `bin/sc` `generate_config()` apart from the single list element of I-6 — the `OverrideError` wrappers, the three-key guard, the `_filter_rules` calls, `_warn_degraded`, `_warn_drift`, `_write_private`, `_record_generated`, the `check` call and their order | AC-8, AC-15; the drift/upgrade path must stay exactly as T-14 shipped it |
| `bin/sc` `RULESET_FILES` (`sc:98`), `RULESET_BASES`, `ruleset_report()`, `cmd_update_rules` | Out-of-scope item 3 — no fifth rule-set, no new download, no change to the degradation model (Q-3) |
| `bin/sc` `_init_files()`, `load_settings()` / `save_settings()`, `_write_private()` | Q-8, NFR-4 — nothing seeds the new key and `settings.json` keeps being written exactly as today |
| `bin/sc` `main()`'s read-only opt-out arm (`sc:2903-2908`) | K-14 — `doctor` stays the one positively named read-only command |
| `bin/sc` the `# doctor` block, `cmd_status`, `cmd_now`, `cmd_ls`, `cmd_use`, `cmd_mode`, `cmd_ipv6` | Out-of-scope items 4 and 5 — T-20 owns any doctor row |
| `/home/alan/Programs/singbox-cli/install.sh`, `uninstall.sh`, `systemd/` | Out-of-scope item 11 and NFR-3's permitted diff |
| `/home/alan/Programs/singbox-cli/CONTEXT.md`, `.harness/**`, `docs/tasks.md` | NFR-3 — outside the permitted diff; RS-3/RS-4 carry what they would receive |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | L-1 | none | delete the six pairs; nothing references them yet |
| 2 | L-2 | L-1 landed (I-3's BC-5 line needs its key) | delete the three new definitions; no caller yet, and the emitted document is untouched |
| 3 | L-3 | L-2 landed; **AC-4's HEAD baseline captured at the same fixture path first** (`.harness/insight-index.md:16`) | revert one list element; the emitted document returns to the pre-T-17 shape byte for byte, and no state on any host needs repair — the change is in the generated artifact only |
| 4 | L-4, L-5, L-6 | L-2 landed | revert; `sc telemetry` disappears and the persisted key is simply never read again |
| 5 | L-7, L-8, L-9, L-10 | code steps landed | revert the docs |
| 6 | L-11 | all above | — |
| U-1 | upgrade of an existing host (BC-13) | the new `bin/sc` is installed and `sc reload` is run; no file under `/etc/sing-box` is hand-edited | reinstall the previous `sc` and run `sc reload`: the configuration is regenerated, never patched, and the `telemetry` key left in `settings.json` is ignored by the old build |
| U-2 | a host whose `settings.json` has no `telemetry` key | nothing to do — absence **is** `block` (Q-8); nothing is written to seed it, so `_init_files()` and the installer are unchanged | `sc telemetry allow` |
| U-3 | a host where a listed name is load-bearing for an application (BC-14) | none — both recourses are documented and survive `sc reload` | `sc telemetry allow` for the whole list, or the I-9 per-name exception recipe for one name |

## Out of scope

- Any `dns.rules` entry other than the one reject rule, and any change to T-16's suppression rule, `dns.servers`, `dns.final` or `independent_cache`.
- Any route-level `reject`, any IP-level or address-set blocking, and any change to `route.rules`, `route.final`, `outbounds`, the `proxy` selector or the auto-select group (Q-14).
- A `geosite` category, a fifth rule-set, a new download and any change to `RULESET_FILES`, `sc update-rules` or the degradation model (Q-3).
- Any `sc doctor` row, including "is the reject list in effect" — T-20 owns them.
- Any change to `sc status` / `now` / `ls` / `use` / `mode` / `ipv6` or their output.
- `_merge()`'s type-mismatch vocabulary (R-16): unclaimed, and it would not serve FR-9's extension case anyway, which needs element addressing (Q-1c).
- A first-run notice, a migration prompt or any persisted "have I told you yet" state (Q-7).
- A mechanism for extending the shipped rule's own name array in place — not expressible and not required; the second-rule recipe of I-9 is equivalent in effect (Q-10).
- Defending the emitted document against a user `override.json` that `$replace`s `dns.rules` (BC-6 — the documented contract).
- A committed test harness or a new `verify_all` step (R-9 owns it); every fixture below is throwaway and is pasted into the stage documents.
- Any promise about telemetry that does not traverse this document's DNS rules — a client's own DoH/DoT resolver and a connection to an IP literal are stated as limits, not covered.
- Any ownership of the list's future freshness: nothing in this task re-checks, updates or expires a name (RS-7 files it).

## Verification plan

Every step obeys K-16 (safety) and, where behavioural, K-17 (fixture facts) and K-18 (`+nocookie`,
`dig` startup cost). Behavioural steps use the three derivations T-16 fixed: a `direct` inbound on
`127.0.0.1` replacing the TUN inbound, `remote_dns` and `direct_dns` repointed at two local stub
resolvers with every tag / order / `detour` preserved, and cache + Clash-API paths inside the fixture
root; node state is staged at the `proxy` outbound, never at a stub.

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | Differential `generate_config()`, HEAD clone vs candidate, **same** fixture path, setting `allow`, in all six AC-5 states | `dns.rules` and the whole document byte-identical to the pre-T-17 build in all six states | AC-4 |
| V-2 | The emitted document under `block`: read the reject rule | exactly one rule with `action`/`rcode`/`domain_suffix` in that key order, `rcode` the uppercase `"NXDOMAIN"`, **no `answer` key**, no `rule_set`, no `server`, and `domain_suffix` equal to `list(TELEMETRY_NAMES)` — 18 dotless names in I-2 order | AC-1 |
| V-3 | Index comparison over the emitted `dns.rules` in all four {`block`,`allow`} × {all rule-sets usable, none usable} states; plus a membership check of the 18 names against `CONFIG_BASE`'s `hosts_dns` predefined table | reject index > `hosts_dns` index and strictly < both `clash_mode` indices and < every index whose `server` is `remote_dns`; T-16's rule at index 0 in all four; no listed name appears in the predefined table (BC-11) | AC-2 |
| V-4 | Subset-equality match count for `{"clash_mode": "Global"}`, `{"clash_mode": "Direct"}` and `{"rcode": "NXDOMAIN"}` over the emitted `dns.rules`, four states | each `clash_mode` anchor matches exactly one element in all four; the reject anchor matches exactly one in the two `block` states and zero in the two `allow` states | AC-3 |
| V-5 | **Real** `/usr/local/bin/sing-box check` on the emitted document in each of: 0 nodes, 1 node, 3 nodes, `block`, `allow`, all rule-sets unusable | all six accepted | AC-5, BC-1 |
| V-6 | Repository-wide search for a second spelling of the list or of the setting; deletion test on the second consumer of each | exactly one definition each, two consumers each, no re-derivation | AC-6 |
| V-7 | `ast` extraction and byte comparison of `DIRECTIVES`, `_directive_of`, `_anchor_index`, `_apply_directive`, `_merge`, `_load_override`, `_filter_rules` — and of `_dns_overlay`, `ipv6_decision`, `_runtime_overlay` — against HEAD | byte-identical; no `grep` used (K-15) | AC-7 |
| V-8 | Read the diff of `generate_config()`; `ast` scan of `bin/sc` for a new module-level path constant, a new wait constant, a new `timeout=` argument and a non-stdlib import | one changed line (the third list element), no configuration literal, still three keys in the array guard; no new path, no new wait, no new import — `TELEMETRY_NAMES` is neither a path nor a wait | AC-8 |
| V-9 | Audit `TELEMETRY_NAMES` name by name against FR-1 and against N-1…N-18; check each name has its source-line comment; check the four classes are covered and the count | 18 names ≤ 24, four classes present, one source-line per name, no update / activation / licensing / authentication / push-delivery / CDN-content / captcha / security-feature endpoint among them (K-10) | AC-9 |
| V-10 | `sc telemetry block`, `allow`, `show` through `main()` in a redirected fixture, `lang` seeded in the fixture `settings.json`, both languages (six runs), output captured through a pipe | each exits 0; each prints the setting line and the meaning sentence; `show` additionally prints 18 lines, one complete line per name; no `\r` anywhere, one complete line per fact (BC-18) | AC-10 |
| V-11 | `cmd_telemetry()` driven directly in the `show` form with an mtime witness over the whole fixture root, shimmed `systemctl`/`rc-service`, and no `config.json` / no nodes / stopped service | no file mtime changes, no init command invoked, no socket opened, exit 0 (BC-16 — scoped to the function, `main()`'s start-up writes neither counted nor claimed absent) | AC-11 |
| V-12 | `sc telemetry block` on a host already at `block`, then `sc telemetry allow` on it; `config.json` mtime plus the shims, both directions; the changing run is the non-vacuity control for the witness | the no-op run leaves `config.json` mtime unchanged, invokes no init command and prints the FR-8 line naming `sc reload`; the changing run regenerates, restarts once, and the new document reflects the setting | AC-12 |
| V-13 | Three `settings.json` fixtures — absent, present without `telemetry`, present with `"telemetry": "yes"` — in both languages | all three yield `block`; only the third writes exactly one stderr line, naming file, key and the two accepted values, in the run's language | AC-13, BC-4, BC-5 |
| V-14 | `sc telemetry` with `BLOCK`, `Allow`, `on`, `off`, `xyz`, each with an mtime witness | each exits non-zero after lower-casing, names the three accepted values and writes nothing; `BLOCK`/`Allow` are accepted after lower-casing and `on`/`off` are not (BC-12) | AC-14 |
| V-15 | BC-13 upgrade fixture (a pre-T-17 `config.json` plus its matching `.config.sha256`): `sc reload`, then a second `sc reload` | the first succeeds with no hand-editing and **no** drift warning, and leaves a record matching the new file; the second is silent too | AC-15 |
| V-16 | Parity check over the six new keys: `zh` entry present, `set(re.findall(r"{(\w+)}", key))` equal on both sides, no `失败：`, no `ls.*`-shaped key, key set equal to Q-13's | all pass | AC-16 |
| V-17 | Read both READMEs and `CHANGELOG.md`; heading/line-number skeleton comparison; grep both READMEs for any claim of blocking beyond name resolution and for any client-caching claim | both carry FR-12's six items and stay line-for-line mirrors; the changelog entry is Chinese, under `### 新增`, and states the default and the escape; no claim violates K-11 or K-12 | AC-17 |
| V-18 | Extract the fenced JSON blocks from both READMEs, plant each as `override.json` in a fixture, run `generate_config()` | each applies cleanly and yields exactly the document AC-B6 measures; the two blocks are byte-identical across the two READMEs | AC-18 |
| V-19 | Read `HELP_EN` and `HELP_ZH`; display-column comparison against the neighbouring `ipv6` and `update-interval` rows | both carry the `telemetry` row at the existing alignment, sub-options at column 32 | AC-19 |
| V-20 | `python3 -m py_compile bin/sc`; 3.6-syntax scan of the diff; import scan | passes; no walrus, no f-string debug specifier, no `dataclasses`, no `capture_output=` added, no non-stdlib import | AC-20 |
| V-21 | `bash .harness/scripts/verify_all.sh` | no FAIL against the 17/0/0/1 baseline. **Predicted WARN:** F.6 doc-size on this task's stage documents once `04`/`06` land — it clears on `archive-task`, and is predicted here before any code is written | AC-21 |
| V-22 | Behavioural, setting `block`, all rule-sets usable, `rule` mode, both stubs instrumented: `dig +nocookie` for a listed name (apex), for a two-label subdomain of it and for a four-label subdomain, each timed | each answered `NXDOMAIN` with `ANSWER: 0` well inside 100 ms (≈82 ms of headroom after `dig`'s ≈17.5 ms startup, K-18); neither stub records any of the three | AC-B1 |
| V-23 | V-22 repeated with the **fixture's own** Clash API set to mode `global`, then `direct` | identical outcome in both modes: `NXDOMAIN`, 0 records, no stub receipt | AC-B2 |
| V-24 | The same fixture regenerated after `sc telemetry allow`, node usable: the same listed name and subdomain, all three modes | both resolve normally and reach the **same** stub they reach at HEAD; this run is the non-vacuity proof that the rig can observe a resolved answer | AC-B3 |
| V-25 | Node usable, both stubs instrumented, setting `block`: a BC-9 near-miss name formed by prefixing a listed name with letters, a domestic name, a `geosite-google` name and a name matched by no DNS rule (not a `.test` name, K-17) — × 3 modes × 2 rule-set states, each compared against a HEAD-clone run of the identical fixture | the same stub receives each probe in both runs, in all 24 combinations; the near-miss name is never rejected | AC-B4, BC-9 |
| V-26 | Setting `block`, with the fixture rules directory emptied, and separately with the `proxy` outbound pointed at a listener that accepts and never answers: one listed name, all three modes | `NXDOMAIN`, 0 records, within 100 ms in every combination; no stub receipt (FR-5, BC-2, BC-3) | AC-B5, AC-5 |
| V-27 | Both README recipes verbatim as `override.json` in the fixture root: (a) a user reject rule `$before {"clash_mode": "Global"}` carrying the user's own name, run under **both** settings; (b) a user resolver rule `$before {"rcode": "NXDOMAIN"}` naming one listed name, run under `block` | (a) the user's name is rejected in both settings states, and under `block` the shipped names are rejected too; (b) exactly that one listed name resolves and reaches a stub while the other 17 stay `NXDOMAIN` | AC-B6, BC-7, BC-8 |
| V-28 | Every one of V-22…V-27 re-run against a pristine HEAD **clone** with the identical fixture and derivation, classified before the run | **Defect-reproducing [D]** (AC-B1, AC-B2, AC-B5, AC-B6b): the HEAD run resolves the name and a stub records it, never `NXDOMAIN`. **Agreement [A]** (AC-B3, AC-B4, AC-B6a): the HEAD run produces the candidate's outcome. A run whose control does neither is reported **inconclusive**, never a pass, and no behavioural criterion is replaced by an artifact check (NFR-8) | AC-B7 |
| V-29 | BC-10 companion, setting `block`: an AAAA query and a type-65 query for a listed name with AAAA suppression in effect (`sc ipv6 off`), then the same with `sc ipv6 on` | with suppression: empty `NOERROR` from T-16's index-0 rule, no records, no stub receipt; without: `NXDOMAIN` from the reject rule. Neither leaks (Q-E) | AC-B1, AC-2 |
| V-30 | Repeat-query check with `+nocookie` on a listed name (10 probes) and a latency distribution | every probe `NXDOMAIN` in ~2–5 ms with no warm-up curve; no stub receipt on any probe. **No claim is made or tested about client-side negative caching** (K-12) | AC-B1 |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RS-1 | **FR-10 report — what the composition layer could not express: nothing.** `$before` with an object anchor, on an array `CONFIG_BASE` already defines, carried the whole change: no new directive, no new file, no new persisted state beyond one key, no new command beyond FR-7, and one changed line in `generate_config()`. T-14's D-7 built the anchor vocabulary naming this exact second insertion, and T-16's `_dns_overlay()` supplied the idiom verbatim. The one thing that is **not** expressible — extending the shipped rule's name array in place through `override.json`, which needs element addressing — was already ruled out and re-homed to the second-rule recipe by Q-10, so it costs the user four lines of JSON and nothing else. The design therefore is data plus a toggle, as the pool required. | `03_GATE_REVIEW.md`, `07_DELIVERY.md` |
| RS-2 | **`01`'s Q-5 wording overstates what is measured.** Its clause "caching the denial for the whole name is the intent" rests on downstream client behaviour that the probe did **not** measure; what was measured is that the `NXDOMAIN` carries `AUTHORITY: 0` with no SOA, so RFC 2308 gives a downstream resolver no MINIMUM to derive a negative TTL from. Q-5's *decision* stands unchanged on its semantic ground (the rule denies the name, not a type). The gate should rule on whether the AC/Q text is amended now or at stage 6; no rollback is performed here, and K-12 keeps the claim out of every shipped surface. | `03_GATE_REVIEW.md`, `01_REQUIREMENT_ANALYSIS.md` |
| RS-3 | **`CONTEXT.md` (outside NFR-3).** Two terms: **telemetry reject list** — the fixed set of names `sc` answers locally with "no such domain", emitted as one DNS rule and switched by one setting; _Avoid_: blocklist, adblock, filter list. **reject rule** — the single emitted `dns.rules` element carrying that list, sitting between the predefined-hosts rule and both `clash_mode` rules; _Avoid_: block rule, deny rule. **PM amendment at delivery, per stage-5 RES-5/CR-5 and stage-6 D-5:** this term originally defined the reject rule as "anchored by `{"rcode": "NXDOMAIN"}`". That anchor was replaced at stage 4 under gate condition C-4 (DD-1) because it exists only under `block`, and **no README publishes it**. Filed unamended, this residual would have written a project-wide glossary entry into `CONTEXT.md` that both shipped READMEs contradict — the one residual on this task whose text escapes the feature folder. The published anchor for all three user recipes is `$after {"server": "hosts_dns"}`; `{"rcode": "NXDOMAIN"}` survives only as the worked example of a **state-dependent** anchor in `docs/dev-map.md`. | `07_DELIVERY.md` |
| RS-4 | **`.harness/rejected-decisions.md` (outside NFR-3).** Four records: `telemetry-list-as-geosite-ruleset` (Q-3), `telemetry-toggle-as-on-off` (Q-7), `telemetry-reject-by-dropping-the-query` (Q-4), and one this stage adds — `telemetry-list-with-a-second-domain-key`: pairing `domain` with `domain_suffix: [".x"]` to defend against a `notexample.com` false positive, declined because Q-C measured that 1.13.15's `domain_suffix` is label-boundary aware and the false positive does not exist in this binary; the pair doubles the list's size for an identical result set. | `07_DELIVERY.md` |
| RS-5 | Insight candidates for harvest: (a) `domain_suffix` in sing-box 1.13.15 is **label-boundary aware** and case-insensitive — one dotless entry covers apex plus every depth of subdomain and rejects character-suffix near-misses, so the v2ray-era `domain` + `.suffix` pairing is dead weight here; (b) a `predefined` rule with `rcode: "NXDOMAIN"` **and** a non-empty `answer` passes `check` and emits a self-contradictory `NXDOMAIN` with one record, while an omitted `rcode` silently means `NOERROR` and a lowercase rcode is a hard `check` failure; (c) the `reject` DNS-rule decoder **accepts unknown fields** while `predefined` and routing rules reject them, so a bogus-key acceptance control is only sound on `predefined`; (d) `dig`'s default EDNS COOKIE defeats sing-box's upstream DNS cache (5 client queries → 5 upstream), so any cache measurement needs `+nocookie`; (e) a DNS rule placed after the two `clash_mode` rules is **absent in both non-`rule` modes**, and for a name rule that means the name is measurably leaked upstream, not merely unblocked. | `07_DELIVERY.md` |
| RS-6 | This stage holds no shell, so every acceptance claim above is a prediction until stages 4 and 6 run it. The mechanism claims it rests on (Q-A…Q-F) were measured by the PM-commissioned probe against the real `sing-box 1.13.15`, not by this stage; BC-15 is discharged by that probe, and nothing in this design substitutes a silently dropped query. | `03_GATE_REVIEW.md` |
| RS-7 | **The list has no freshness owner.** A shipped name list ages: an endpoint is retired, a vendor moves collection to a new host, a new dominant SDK appears. This task deliberately adds no update path (Q-3 forbids the machinery), so the list is only ever revised by editing `bin/sc` in a future task. That should be a pool row — "re-audit `TELEMETRY_NAMES` against N-1…N-18" — rather than an implicit expectation that nobody owns. | `07_DELIVERY.md`, `docs/tasks.md` |
| RS-8 | **Three names are shipped on a weaker hostname evidence than the other fifteen** — `telemetry-coverage.mozilla.org` (N-7), `ulogs.umeng.com` (N-16) and `data.mistat.xiaomi.com` (N-18): the vendor and the role are firm, the exact host string is not first-hand verified by this stage. The downside is bounded and one-directional — a name that does not exist rejects nothing — and each was chosen so that if it *does* exist it can only be a reporting endpoint. The gate should rule on whether that is acceptable or whether the three are dropped; dropping them costs class 2 one member and class 4 two, and leaves all four classes covered. | `03_GATE_REVIEW.md` |

## Verdict

**READY** — every requirement line has an implementable expression: FR-1/FR-2 in N-1…N-18 and K-10,
FR-3 in I-4 (measured Q-A/Q-C), FR-4 in I-9's index relation (measured Q-D), FR-5 in I-4's absence of a
`rule_set` key, FR-6 in I-1/I-3, FR-7 in I-7, FR-8 in I-7's before/after comparison, FR-9 in I-9's two
anchors, FR-10 in RS-1's report, FR-11 in K-6 and the frozen set, FR-12 in L-7/L-8 under K-11/K-12,
FR-13 in I-8, FR-14 in I-11. BC-15 is discharged: the mechanism exists, is accepted, and behaves as FR-3
requires. Two items are carried rather than blocking, both for the gate to rule on: `01`'s Q-5 negative-
caching clause is unmeasured and should be reworded (RS-2), and three of the eighteen names rest on
weaker hostname evidence than the rest (RS-8). Neither changes the design; both are visible before code
is written.
