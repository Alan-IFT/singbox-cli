# 04 — Development · T-15 `proxy-urltest-group`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

Mode: **full**, single-Developer (no `.harness/agents/dev-*.md`; `02 ## Partition assignment`).
Upstream read in full: `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`, `03_GATE_REVIEW.md`.
No T4.1/4.2/4.3 trigger fired for `02_RATIONALE.md` / `03_RATIONALE.md`: no `DESIGN DRIFT`, no
`BLOCKED ON DESIGN`, no ambiguous contract row (Q-1…Q-6 answered every question the ledger raised).
**T4.4** fired on QA's DEF-2 — `06_RATIONALE.md` read in full (the three live-sing-box transcripts and
the "nothing in the emitted parameters can fix it" analysis at `:238-243`); the fix is prose only.
`.harness/rules/70-doc-size.md` still has no `## Stage-doc boundary rule`, so the agent schema is
applied as written.

## Summary

- `bin/sc` gains one reserved tag, one `urltest` outbound emitted by `_runtime_overlay()` as a member
  of the existing `proxy` selector, and three new functions that carry every new judgment —
  `_auto_group_emitted()` (`bin/sc:1355`), `_valid_selection()` (`:1374`), `stored_delays()` (`:1651`);
  every other code edit is a call site of one of them.
- `sc ls` gains a last delay column and, when the group is emitted, an index-less group row naming the
  node the group is on right now (`bin/sc:1738-1774`).
- Both READMEs, `CHANGELOG.md` and `docs/dev-map.md` document the feature, the K-6 carve-out (C-2),
  what the delay figure actually is (C-8), and what the failover promise is worth measured: the switch
  lands one probe round (≈3 min of failing requests) after a node slows down or starts refusing, and a
  node that accepts connections and then never answers is not covered at all (DEF-2).

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `bin/sc` | `# Paths`: `AUTO_TAG` (`:52`) + `RESERVED_TAGS` (`:56`), after `TUN_IFACE` | L-1 |
| `bin/sc` | `TRANSLATIONS["zh"]`: one pair `"Delay" → "延迟"` (`:191`); the five `ls.*` keys untouched | L-2 |
| `bin/sc` | `# Config composition`: `_auto_group_emitted()` (`:1355`) and `_valid_selection()` (`:1374`), immediately above `_runtime_overlay()` | L-3 |
| `bin/sc` | `_runtime_overlay()` (`:1420-1450`): builds the group, widens the selector, derives `default` through `_valid_selection()`; group placed immediately after the selector (K-5) | L-4 |
| `bin/sc` | `generate_config()` (`:1554-1564`): the stale-active repair is now `_valid_selection()`, persisting only when the judge returns something different (K-7) | L-5 |
| `bin/sc` | `# Clash API`: `stored_delays(port=None)` (`:1651`), after `is_running()` | L-6 |
| `bin/sc` | `_unique_tag()` (`:1723-1729`): the first-hit test also rejects `RESERVED_TAGS` (K-3) | L-7 |
| `bin/sc` | `cmd_ls()` (`:1738-1774`): one `stored_delays()` call, sixth column, group row | L-8 |
| `bin/sc` | `cmd_use()` (`:1777-1800`): the reserved-tag arm decided **before** `_resolve_node()` (K-10 ordering kept) | L-9 |
| `bin/sc` | `cmd_add()` (`:1817-1821`): the auto-pick is `_valid_selection()` | L-10 |
| `bin/sc` | `cmd_rm()` (`:1832-1835`): the auto-pick is `_valid_selection()`; the existing guard kept (Q-2) | L-11 |
| `bin/sc` | `HELP_EN:2501-2503` / `HELP_ZH:2560-2562`: `use <name\|index\|auto>` + a sub-option line; column 30 / 32 alignment re-measured, not eyeballed | L-12 |
| `README.md` | `### Switch node` gains `sc use auto`; new `### Auto-select the fastest node` (`:85-103`) with the table sample, the C-8 paragraph and the C-2 blockquote; the failover claim at `:89` states its two measured bounds (next probe round; the hanging member is uncovered) — DEF-2; roadmap `:298` checked | L-13 |
| `README.zh-CN.md` | the same edits at the same line numbers — 305 lines each, structural mirror asserted line by line (0 mismatches by position after the DEF-2 edit; no new zh string contains `失败：`) | L-14 |
| `CHANGELOG.md` | one Chinese bullet under `## [Unreleased]` → `### 新增` (`:7`), carrying the same two bounds; no new version heading (K-18) | L-15 |
| `docs/dev-map.md` | see `## Dev-map updates` | L-16 |
| `docs/features/proxy-urltest-group/04_DEVELOPMENT.md` | this document | L-17 |

Diff totals (`git diff --numstat` against HEAD `1e454b6`): `bin/sc` +200/-17, `README.md` +21/-2,
`README.zh-CN.md` +21/-2, `CHANGELOG.md` +2/-0, `docs/dev-map.md` +6/-4 — the DEF-2 qualification is
a rewrite *inside* the three lines `README.md:89`, `README.zh-CN.md:89` and `CHANGELOG.md:7`, so it
adds no line to either README and both stay 305 lines with 0 structural mismatches by position
(AC-34). Nothing outside NFR-5's permitted diff was touched: `docs/tasks.md`,
`docs/batches/**` and `.harness/**` carry the PM's own pre-existing modifications and none of mine.

## verify_all result

```
command:  bash .harness/scripts/verify_all.sh   (no extensionless dispatcher on this host)
baseline: PASS 16  WARN 1  FAIL 0  SKIP 1       (measured before the first edit)
after:    PASS 16  WARN 1  FAIL 0  SKIP 1       (re-measured after the DEF-2 documentation fix)
delta:    0 new failures, 0 new warnings, baseline preserved
warn:     F.6 — this task's own 597-line 01_REQUIREMENT_ANALYSIS.md; predicted by V-22, clears on archive
skip:     B.3 lint — no lint config in this project (pre-existing)
service:  MainPID=2566751  ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST — identical before and
          after stage 4 (S-6 witness; it already differed from the stage-1 figure when stage 4
          began, from a service start on 2026-08-11, i.e. before any work in this session)
```

## Design drift

**None.** Every ledger row landed as written, every K-1…K-18 constraint holds, and the frozen set is
byte-identical in the diff (grepped: `_resolve_node`, `clash_api`, `_merge`/`_directive_of`/
`_apply_directive`/`DIRECTIVES`, `_write_private`, `cmd_now`, `cmd_status`, `_warn_drift`, the five
`ls.*` key definitions, `CONFIG_BASE.dns`, `route.default_domain_resolver` — no `+`/`-` line touches
any of them). Two elaborations *inside* a ledger row's own file and intent, recorded so the reviewer
does not have to discover them:

- L-16 adds **two** reusable-utility rows rather than one (the I-5 reader and a combined
  `_auto_group_emitted` / `_valid_selection` row), plus Q-5's `$replace`-versus-`$append` note on the
  `_runtime_overlay` row, which Q-5 states is where that note belongs.
- L-13/L-14/L-15 state the failover promise with the two bounds QA measured (DEF-2). The design row
  prescribes *that* the group paragraph exists, not its wording, and no emitted parameter changed, so
  this is prose brought into line with observed behaviour rather than a departure from `02`.
- L-9 reads `nodes.json` once more than HEAD does, but **only** on the run where the user literally
  typed `sc use auto`; every other spec reaches `_resolve_node()` on exactly HEAD's path (V-10 proves
  identical exit, stdout bytes and persisted selection for 22 spec × language combinations).

## Condition disposition

| gate condition | disposition | evidence |
|---|---|---|
| **C-1** | **Discharged — step 8 below.** A fixture whose `nodes.json` holds a node tagged exactly `auto`, observed in both languages: **no** group emitted (K-6); the real `sing-box check` accepts the document (AC-17); no duplicate tag (AC-6); every referenced tag defined (AC-4); `proxy.default` = the node `auto` and an element of `proxy.outbounds` (AC-3); `nodes.json` not rewritten. `sc ls` prints **no** group row and the node keeps index 1; `sc use auto` **pins that node** and prints the ordinary switched-to line. | `v_config.py` §C-1 (8 assertions), `v_upgrade.py` §C-1 (12 assertions) |
| **C-2** | **Discharged.** The K-6 paragraph is the blockquote at `README.md:103` / `README.zh-CN.md:103` — same line number, mirrored: *no auto-select group exists on that host*, `sc use auto` *pins that node*, and the printed `Switched to: auto` **does not mean failover is on**, plus the self-healing instruction. C-1's run confirms the paragraph describes what the code really does, including the byte-identical line F-1 warns about. | `README.md:103`, `README.zh-CN.md:103`; structural mirror check (305 lines each, 0 mismatches) |
| **C-4** | **Discharged — AC-21 now has its own observable, and V-12 is no longer cited for it.** `restart_service()` is wrapped by a counting proxy that calls through to the real (inert) function, so the recorded fact is "the real restart path was entered". `sc reload` on the BC-13 upgrade fixture enters it **once per reload (2 for 2)**; `sc update-rules` with no rule-set byte changed enters it **zero** times. Two further facts: `restart_service()` / `reload_or_restart()` are byte-identical to HEAD in the diff, so no restart is suppressed by construction; and the fixture keeps `SYSTEMD = OPENRC = False`, so this is a call-site observable, deliberately **not** a live bounce (S-4) — the S-6 witness above shows nothing on this machine restarted. | `v_upgrade.py` V-11 / V-12 |
| **C-5** | **Discharged, both halves.** (a) A table rendered **with** the group row present: the row is first, carries no index number, shows `→ JP-2`, carries the group's own delay, holds the only `●`; node indices are `1,2,3`, and every HEAD row is a **byte-prefix** of the corresponding candidate row (header included) — the strongest available form of AC-31. (b) A table **mixing** known and unknown delays in one render, both languages: cells `["141 ms", "-", "141 ms", "-"]` for a never-probed node and a node absent from the API's proxy set — distinct from any numeric rendering, never `0`, never blank. | `v_api.py` §C-5a (7), §C-5b (6) |
| **C-6** | **KEPT — `interrupt_exist_connections` stays omitted on the group, and F-3's DoH case is answered by measurement rather than by "let them drain".** The gate's undecided fact (how long a DoH transport through a half-dead member takes to error out) turns out not to be the deciding one. The installed binary carries `common/interrupt.(*Group).Interrupt`, `interrupt.ContextWithIsExternalConnection` and `interrupt.IsExternalConnectionFromContext`: the interrupt group classifies each tracked connection as *external* (came from an inbound) or not, and the option governs **external** connections only — sing-box's own internal connections are interrupted on re-selection regardless. The DoH transport to `remote_dns` (`bin/sc:1071-1072`) is dialled by sing-box itself, not by an inbound, so it **is** torn down when the group re-selects; F-3's inversion does not occur. Keeping the omission therefore costs nothing on the DNS plane while still letting a user's own transfers drain on the old member. **The emitted document does not change, so V-4 was not re-run for this** (it was run in full anyway). | binary-string transcript in `04_RATIONALE.md`; `v_config.py` asserts the key is absent on the group and still `true` on the selector |
| **C-7** | **Discharged — RS-4/BC-6 settled against the real binary.** A hand-made document identical to a real one except that the `urltest` group's member list is `[]`: `/usr/local/bin/sing-box check` → **exit 1**, `FATAL[0000] initialize outbound[1]: missing tags`. E-4's hypothesis is confirmed, not merely plausible: an empty member list is a hard rejection, so `_auto_group_emitted()`'s first clause is load-bearing and not merely tidy. The state remains unreachable by construction (I-3 + K-4). | `v_config.py` §C-7 |
| C-3, C-8, C-9 | QA's. C-8's text is written now for QA to check: the paragraph at `README.md:101` / `README.zh-CN.md:101` states the figure is a value the running sing-box already holds (read once over the Clash API, not measured by `sc`), that it exists only while the group is in use, and that `-` on a pinned host is the designed behaviour. | `README.md:101`, `README.zh-CN.md:101` |

## Verification steps run

179 assertions, 0 failures, across four scratchpad harnesses (`harness.py` = the
`docs/dev-map.md:109-135` import recipe verbatim; all seven path constants under one `mkdtemp()` root
and **asserted** inside it; `SYSTEMD = OPENRC = False`; `_init_files()` never driven; no
`PUT`/`PATCH`/`DELETE` anywhere except against a local stub server; `SB_BIN` = the real
`/usr/local/bin/sing-box`, which is read-only and takes no service action). Nothing was added to the
repo (NG-9) and no new `verify_all` step exists.

| step | what was run | result |
|---|---|---|
| 1 · V-1 | differential `generate_config()`, HEAD **clone** vs candidate, **same** fixture path (S-7/S-8), zero nodes | the **whole** emitted document is byte-identical, not merely `outbounds`; both accepted by the real checker (AC-5) |
| 2 · V-2/V-3 | emitted document at 0 / 1 / 3 nodes × selection ∈ {node, `auto`, stale} | exactly one `urltest`; members = node tags in `nodes.json` order; no `direct` among them; selector = `auto` + node tags + `direct`; group immediately after the selector; reference closure and no duplicate tag in every state (AC-1…AC-4, AC-6) |
| 3 · V-4 | **real** `/usr/local/bin/sing-box check`, 7 documents | **all accepted**: 0 nodes; 1 node × {node, `auto`}; 3 nodes × {node, `auto`}; 3 nodes with a stale selection; 3 nodes + `auto` with only 2 of 4 rule-sets present (degraded, `route.rule_set` = `geoip-cn`, `geosite-cn`). Plus C-7's empty-member document → **rejected**, exit 1, `missing tags` (AC-14, BC-6) |
| 4 · V-5/V-20/V-21 | `git diff` greps + `python3 -m py_compile` + `ast.parse(feature_version=(3,6))` | `generate_config()`'s body gains no outbound literal (AC-7); `timeout=3` byte-identical and no new timeout constant — the only new `timeout` token is the group's `idle_timeout` key (AC-28); the new reader contains no non-`GET` method argument (AC-29); 3.6 parse OK, stdlib only, new key present in `zh` with an identical (empty) placeholder set and no `失败：` (AC-33, AC-35) |
| 5 · V-6/V-7 | `generate_config()` ×3 with `active == "auto"`; then `sc rm` of the last node with `active == "auto"` | `nodes.json` byte-identical after each of the three runs (AC-9); after removal the persisted `active` is `None`, the document is the zero-node shape and still satisfies AC-3/AC-4 (AC-10) |
| 6 · V-8/V-9 | `sc add` with fragment `#auto`; node `auto-jp` then `sc use auto` | tag minted as `auto #2`, no duplicate tag, and the first `sc add` selects the group (AC-11, D-5); `sc use auto` selects the **group**, not `auto-jp` (AC-12) |
| 7 · V-10 | `sc use <name>` / `<index>` / substring / miss / empty for every node, both languages, against the HEAD clone at the same fixture path | 22/22 identical exit status, identical stdout **bytes** and identical persisted selection (AC-13, AC-31) |
| 8 · C-1 | the K-6 host: `nodes.json` holding a node tagged exactly `auto` | see `## Condition disposition` |
| 9 · V-11 | BC-13 upgrade fixture: pre-T-15 `config.json` written by the HEAD clone + its real `.config.sha256`, node-tag selection; then `sc reload` twice with the new build | first reload succeeds with no hand-editing and **empty stderr** — no drift warning (AC-17, AC-18); `.config.sha256` then holds the new file's digest and the second reload is silent too (AC-19); the host's own selection never moved (U-2) |
| 10 · V-12 | `sc update-rules` against a **local** stub mirror serving bytes identical to the seeded rule-sets | "No rule-set changed — the sing-box service was not touched", exit 0, `config.json` untouched although the *generated* shape now differs, and `restart_service()` never reached (AC-20; AC-21 is step 9's, per C-4) |
| 11 · V-13/V-14 | `sc use auto` against a stub Clash API with `is_running()` stubbed true | exactly one request, `PUT /proxies/proxy` with body `{"name": "auto"}`, selection persisted, `Switched to: auto`, no service call at all (AC-8); with the stub answering 400, it falls through to `reload_or_restart()`, ends with the selection applied and the emitted document selecting the group (AC-22) |
| 12 · V-15 | `stored_delays()` over 15 body shapes + connection-refused | never raises; only well-formed positive integers appear; `delay` `0`, `True`, `"90"`, a missing/empty/non-list history, a non-object entry, a non-object top level and an absent `proxies` key all yield *absence*; `current` only from a non-empty string `now`; refused connection costs <1 ms (AC-25, BC-9, BC-10) |
| 13 · V-16/V-17/V-18 | `sc ls` with the API unreachable (both languages); with `is_running()` false against a connection-counting stub; with zero nodes | table plus `-` in every delay cell, exit 0, no traceback, no `\r`, no line ending in whitespace, one line per entry (AC-24, BC-15); **zero connections and zero requests**, 0.0001 s (AC-27); zero nodes prints today's line unchanged and issues no request (AC-30) |
| 14 · C-5 | `sc ls` with the group row present, and with mixed known/unknown delays | see `## Condition disposition` (AC-26, AC-31) |
| 15 · V-22 | `bash .harness/scripts/verify_all.sh`; README line-count and structural mirror | no FAIL; both READMEs 305 lines with 0 structural mismatches line-for-line (AC-32, AC-34) |

**Left to QA:** **V-19** only — the live-host, read-only, post-delivery step for AC-15/AC-23. It is
C-3's to settle: as `02` writes it, its precondition (the group *selected* on the live host) is
reachable only through the `PUT /proxies/proxy` that S-5 forbids here, so stage 4 did not attempt it.
AC-15's own demand (an evidenced answer inside `02`) is already discharged by K-14/K-15. QA also owns
the full README mirror/content check for C-2 and C-8, and the adversarial section (S-9/C-9).

## Open issues for review

- The feature does not cover a member that accepts connections and never answers (QA's DEF-2, three
  independent runs, up to 440 s / 2.4 intervals with 100 % of traffic failing): a `urltest` check that
  hangs never completes, so the cached selection is never revisited, and clearing the stale history
  does not move it either. `urltest` exposes no per-probe timeout, so nothing in the emitted document
  can fix this — the READMEs and `CHANGELOG.md` now say so instead. Closing it needs a health signal
  `sc` does not have today (e.g. an external prober driving `PUT /proxies/proxy`); that is a new task,
  not a change to this one.
- A slow or refusing member is demoted only on the next probe round — ≈183 s and ≈190 s measured
  against an emitted `interval` of `3m`, with every request failing throughout in the refusing case.
  Shortening `interval` would narrow that window at a probing cost I-9 deliberately declined; the
  documented bound is the honest statement of the current values.
- The English `sc ls` header now reads `ls.idx  ls.active  ls.type  ls.name  ls.address  Delay` — the
  new key is a correct English sentence and the five old ones are not (R-19, deliberately out of
  scope per NG-10/D-13). Both READMEs show that header verbatim in the sample table rather than a
  prettified one; it is honest, and it will read oddly until R-19 lands.
- Q-6's accepted defect is now visible: `t('Delay')` is two CJK characters in a `:>9` field, so the
  zh header is two display columns narrower than the en one. The column is last, so nothing shifts.
- `_valid_selection()` is called with `active=None` from `cmd_rm` (Q-2's shape) and with the loaded
  value everywhere else. Both are correct, but a reader may expect one calling convention; a future
  refactor could pass the loaded value in all three sites without changing any outcome.
- RS-3 stands unchanged: a probed-and-failed node (`delay == 0`) and a never-probed node both render
  `-`. V-15 confirms `0` is filtered exactly as I-15 requires; splitting the two still needs a second
  marker nobody has asked for.

## Dev-map updates

- `# Paths` section row now names `AUTO_TAG` (THE tag of the auto-select group, language-neutral) and
  `RESERVED_TAGS` (built from it).
- `# Config composition` section row now lists `_auto_group_emitted` and `_valid_selection`;
  `# Clash API` section row now lists `stored_delays(port=None)`.
- Reusable utilities gains two rows: **"Is the auto-select group in the document, and is this
  selection valid?"** (`_auto_group_emitted` / `_valid_selection` + the two constants) and
  **"Per-outbound stored delay"** (`stored_delays`, with its `is_running()`-inside guard, its
  one-`GET`/no-mutation contract and its no-`try`/`except` shape checks).
- The `_runtime_overlay` row now records Q-5/RS-1: it `$replace`s the whole `outbounds` array, so a
  second shipped overlay (T-16/T-17) must compose into that same payload — the additive route needs a
  directive `_merge()` does not have while R-16 is unclaimed.

## Insight to surface

- sing-box's `interrupt_exist_connections` governs **external (inbound-originated) connections only** — the installed binary carries `interrupt.ContextWithIsExternalConnection` / `IsExternalConnectionFromContext` alongside `(*Group).Interrupt`, so sing-box's own internal connections (the DoH transport that carries `remote_dns`) are torn down on every group re-selection whatever the option says · evidence: `strings /usr/local/bin/sing-box`, T-15 C-6
- `sing-box check` v1.13.15 rejects a `urltest` outbound with an empty member list outright — `FATAL initialize outbound[N]: missing tags`, exit 1 — so "never emit the group at zero nodes" is a hard requirement, not a tidiness rule · evidence: T-15 V-4/C-7
- A `urltest` group is accepted when it is emitted **before** the node outbounds it references, so outbound order in the emitted array carries no dependency meaning · evidence: T-15 V-4, `bin/sc:1445-1447`
- A sing-box `urltest` group demotes a member that is slow or refuses within about one `interval`, but never demotes a member that accepts the connection and then never answers — a check that hangs never completes, so the cached selection is never revisited even after the stale history is dropped, and there is no per-probe timeout option to change that · evidence: T-15 DEF-2, `06_RATIONALE.md:219-236` (three live-binary runs, positive control moved in 183 s)
- The Clash API's `/proxies` entry for a `urltest` group carries `now` (the member it is on), which is the only machine-readable way `sc` can state the current node when the selection is not a node · evidence: T-15 I-15/V-15, `bin/sc:1651-1690`

## Verdict

**READY FOR REVIEW**
