# 01 — Requirement Analysis · T-15 `proxy-urltest-group`

Mode: **full**. Decision mode: **deferred-human** — every ambiguity below is resolved as a numbered
decision (`D-n`) under the owner's standing authority, not escalated. No `BLOCKED: NEEDS-HUMAN`
condition was found.

---

## 1. Corrected problem statement

### 1.1 What the field report says, and why it is wrong

The report says 「`proxy` 出站直接绑定单节点」. **That is false, and I verified it at the source
rather than inheriting the PM's reading.**

**EVIDENCE E-1** — `bin/sc:1356-1363`, inside `_runtime_overlay()`:

```python
node_tags = [n["tag"] for n in nodes]
selector = {"type": "selector", "tag": "proxy",
            "outbounds": node_tags + ["direct"],
            "default": active or "direct",
            "interrupt_exist_connections": True}
```

`proxy` is already a **selector** over every node tag plus `direct`, defaulting to the persisted
active node (or `direct` when there is none). The PM's premise check is confirmed independently.

### 1.2 The defect that survives the correction

**A selector picks and stays.** sing-box's `selector` performs no health probing of its members: it
routes to whichever member is currently chosen and never reconsiders. Nothing in `bin/sc` re-chooses
either — the only writers of that choice are `sc use` (`bin/sc:1617-1627`) and
`generate_config()`'s stale-active repair (`bin/sc:1471-1475`), both of which run only when a human
types a command.

**Observable failure today.** With node A degraded but not dead (packet loss, jitter, TLS handshakes
that hang rather than refuse):

1. Every connection routed to `proxy` keeps going to A until a human notices and runs `sc use B`.
2. `sc update-rules` downloads `.srs` files over that path, so rule-set fetches fail or time out on
   the affected machine and succeed on a machine pinned to a different node — the per-machine
   divergence the reporter observed and had to diagnose by comparing hosts by hand.
3. **DNS goes down with the data plane**, because `remote_dns` carries `"detour": "proxy"`
   (`bin/sc:1071-1072`) and `dns.final` is `remote_dns` (`bin/sc:1095`). One flaky node therefore
   takes out name resolution as well as traffic — a single point of failure spanning both planes.

**Observable behaviour that replaces it.** A probing group exists among the selector's members. When
that group is the selection, a node that stops answering the probe stops carrying traffic **without
a human command and without a service restart**, and DNS follows the healthy node automatically.
Manual pinning (`sc use <name>`) keeps working exactly as documented (`README.md:79-81`).

### 1.3 Second half — per-node latency is not a separate feature

There is **no latency notion anywhere in `bin/sc` today**.

**EVIDENCE E-2** — a search of `bin/sc` for `delay|latency|proxies|/delay` returns exactly four
hits: the `clash_api()` definition (`:1536`), `sc use`'s `PUT /proxies/proxy` (`:1622`),
`sc status`' `GET /configs` (`:1698`) and `sc mode`'s `PATCH /configs` (`:2048`). No `GET /proxies`
call exists.

**EVIDENCE E-3 — the dispatch brief is imprecise about `sc doctor`.** `sc doctor` does **not**
report node state. Its seven sections (`DOCTOR_SECTIONS`, `bin/sc:1995-2003`) are: sing-box binary,
rule-sets, configuration, service, TUN interface, Clash API, egress IP. It has no concept of a node
at all, and therefore no opinion about "how fast is this node". **We are in world 2** of the two the
brief names: nothing to reuse, so this task must create exactly one such opinion and place it where
`sc doctor` can call it later without a second one being invented.

### 1.4 What `GET /proxies` actually returns on this project's sing-box

Established against the installed binary at `/usr/local/bin/sing-box`, by literal presence/absence —
the same technique `.harness/insight-index.md:16` used for `/providers/rules`.

**EVIDENCE E-4** — string counts in `/usr/local/bin/sing-box`:

| Literal | Count | What it establishes |
|---|---|---|
| `1.13.15` | 3 | the version T-05 recorded is the version installed here |
| `/proxies` | 3 | the route exists |
| `/delay` | 1 | the per-proxy on-demand delay route exists |
| `LoadURLTestHistory` | 2 | the proxies handler serves a **stored** history, it does not measure |
| `json:"delay"` | 1 | the history entry carries a `delay` field |
| `meanDelay` | 0 | the Clash.Meta aggregate field is **absent** — do not expect it |
| `URLTest` | 22 | the group type is present and reported as a Clash proxy type |
| `json:"tolerance,omitempty"` / `json:"idle_timeout,omitempty"` / `json:"interrupt_exist_connections,omitempty"` | 1 each | all three group options are accepted by this binary |
| `generate_204` | 5 | a `generate_204` probe URL literal is compiled in as a default |
| `missing tags` | 2 | consistent with a group rejecting an empty member list (**hypothesis — BC-6 requires stage 2 to confirm against the real `sing-box check`**) |

**Conclusion (binding on every AC below):** the delay reported per proxy is a **stored** value
produced by url-test probing or by a prior explicit `/delay` call — never a fresh measurement taken
because we asked. A proxy that has never been probed has an empty history and therefore **no
delay**. This is the coupling between the two halves of this task: the probing group is what causes
delays to exist at all for a user who never calls `/delay` by hand.

---

## 2. Goal

Give the `proxy` selector a probing member so a degraded node stops carrying traffic (and DNS)
without human intervention, and surface the resulting per-node delay in `sc ls` so a bad node is
distinguishable from a bad network.

---

## 3. Vocabulary this document fixes

Named here because `CONTEXT.md` is the project's fixed vocabulary and these words are about to
appear in code, config and two READMEs. **Glossary additions recommended (§11).**

- **auto-select group** — the `urltest` outbound this task adds as a *member* of the `proxy`
  selector. It probes its members and routes to the fastest responding one. It is not a node and
  never appears in `nodes.json`. _Avoid_: urltest, auto node, failover node, load balancer.
- **reserved outbound tag** — an outbound tag that `sc` emits itself and that no node may carry.
  Today there are two (`proxy`, `direct`); this task adds the auto-select group's tag.
  _Avoid_: special tag, system tag.
- **selection** — the value of `nodes.json`'s `active` key: what the user last chose. Since this
  task it ranges over node tags **and** the auto-select group's tag. Distinct from the **current
  node**, which is the node actually carrying traffic at this instant (equal to the selection when
  the selection is a node; determined by the group when it is not). _Avoid_: active node (ambiguous
  exactly where it matters).
- **stored delay** — the per-outbound round-trip figure the Clash API reports from its url-test
  history. It is a value the running sing-box already had; reading it measures nothing.
  _Avoid_: latency, ping, speed.

---

## 4. In-scope functional requirements

### Half A — the auto-select group

- **FR-1.** The emitted `config.json` contains a `urltest` outbound (the *auto-select group*) whose
  members are exactly the node outbounds, and which is itself a member of the `proxy` selector.
  `direct` is not a member of the auto-select group.
- **FR-2.** The auto-select group's tag is a single module-level constant with exactly one
  definition. Every consumer (`_runtime_overlay()`, `sc use`, `sc ls`, the active-selection judge of
  FR-6) reads that constant; no consumer spells the tag literally.
- **FR-3.** The auto-select group's tag is a **reserved outbound tag**: `sc add` never creates a node
  carrying it, and `sc` never emits a document in which two outbounds share a tag.
- **FR-4.** `sc use <auto-tag>` sets the selection to the auto-select group and applies it through
  the Clash API without a service restart, by the same path `sc use <node>` uses today
  (`bin/sc:1621-1627`), including its restart fallback when the API does not accept the change.
- **FR-5.** `sc use <node>` continues to pin that node. The auto-select group's existence changes
  neither its behaviour, its resolution rules (`_resolve_node()`, `bin/sc:1564-1584`) nor the index
  numbering `sc use <n>` depends on.
- **FR-6.** There is exactly **one** definition of "is this selection valid, and what does it become
  if not", consumed by config generation. It admits node tags, admits the auto-select group's tag
  when the group is emitted, and admits nothing else. `sc add` / `sc rm` do not form a second
  opinion. *(Today's judge is `bin/sc:1472-1475`; it currently admits node tags only.)*
- **FR-7.** The `proxy` selector's `default` is always a member of the `proxy` selector's own
  `outbounds` array, in every reachable state.
- **FR-8.** The change to the emitted document is expressed **as composition** — inside
  `_runtime_overlay()` and/or `CONFIG_BASE`, applied through the existing single `_merge()`. No
  configuration structure is reintroduced as a literal inside `generate_config()`.
- **FR-9.** If the T-14 composition layer cannot express something this change needs, that fact is
  **reported in `02_SOLUTION_DESIGN.md`** as a finding, naming what could not be expressed. It is
  not worked around silently.

### Half B — per-node delay in `sc ls`

- **FR-10.** `sc ls` displays, per node, the **stored delay** the running sing-box reports for that
  node's outbound, obtained from `GET /proxies` through the existing `clash_api()`.
- **FR-11.** There is exactly **one** function owning "what delay does the running sing-box report
  per outbound". It returns the per-tag stored delays and the auto-select group's current member
  selection from a single API response. `sc ls` is its only caller in this task; it takes no
  `sc ls`-specific argument and prints nothing, so `sc doctor` can call it later unchanged.
- **FR-12.** A node with no stored delay renders as a distinct unknown marker — never `0`, never an
  empty cell that is indistinguishable from a zero-width value, never a fabricated number.
- **FR-13.** When the selection is the auto-select group, `sc ls` states which node is the **current
  node**, or states that it is unknown. It never leaves the reader to infer it.
- **FR-14.** `sc ls` renders an entry for the auto-select group **only when the group is emitted**,
  and that entry carries **no index number**, so `_resolve_node()`'s index space and therefore
  `sc use <n>` are unchanged.
- **FR-15.** Every new user-facing string ships in English and Simplified Chinese with the same
  placeholder set, and no new zh string contains `失败：` (`.harness/insight-index.md:12`).

---

## 5. Boundary conditions

- **BC-1 — zero nodes.** `nodes.json` holds an empty `nodes` array (fresh install before the first
  `sc add`). The emitted `outbounds` is exactly today's shape: `proxy` selector over `["direct"]`,
  plus `direct`. No auto-select group is emitted; the selection is `None` and `default` is `direct`.
- **BC-2 — one node.** Covered by FR-6/FR-7 whichever way D-4 is decided at stage 2; both arms must
  satisfy BC-3 and BC-4.
- **BC-3 — the last node is removed while the selection is the auto-select group.** `sc rm` of the
  final node leaves zero nodes, so the group is not emitted, so a selection naming it is stale. The
  emitted document must not reference an outbound it does not define. *(This is a live trap:
  `cmd_rm` at `bin/sc:1655-1656` rewrites `active` only when it equals the removed node's tag, so
  today's code path would leave `active` naming a vanished outbound.)*
- **BC-4 — a stale selection of any kind.** `active` names neither an existing node nor an emitted
  auto-select group (hand-edited `nodes.json`, a node removed out-of-band, a downgrade then upgrade).
  Config generation repairs it and persists the repair, as `bin/sc:1471-1475` does today.
- **BC-5 — the selection is the auto-select group and the service is stopped.** `sc ls`, `sc now`
  and `sc status` complete without error and without any service-affecting action.
- **BC-6 — a group with an empty member list.** Must never be emitted. E-4's `missing tags` finding
  makes it a likely hard rejection by `sing-box check`; stage 2 confirms against the real binary
  (AC-14) rather than trusting this reading.
- **BC-7 — a node tag colliding with the reserved tag.** A share link whose fragment is exactly the
  reserved tag reaches `_unique_tag()` (`bin/sc:1587-1593`), which dedupes only against existing
  **node** tags and would let the collision through. Two same-tagged outbounds and an ambiguous
  `sc use` follow.
- **BC-8 — a node tag that *contains* the reserved tag as a substring** (e.g. a node named
  `auto-jp` against a reserved tag `auto`). `_resolve_node()`'s substring fallback
  (`bin/sc:1578-1583`) would resolve the reserved word to that node. Exact-match on the reserved tag
  must be decided **before** `_resolve_node()` is consulted.
- **BC-9 — the Clash API does not answer** (service down, port wrong, process hung, port answering
  but not sing-box). `clash_api()` returns `None` on every `URLError`/`HTTPError`
  (`bin/sc:1549-1550`); a hung port costs the existing 3 s timeout and no more.
- **BC-10 — the Clash API answers with an unexpected body**: a proxy entry with no history array, a
  history entry with no `delay` key, a non-integer `delay`, a top-level shape that is not the
  expected object, or a proxy set that omits a node `sc` knows about. Each renders as unknown for
  the affected node; none produces a traceback and none suppresses the rest of the table.
- **BC-11 — a node has never been probed.** Its history is empty by E-4's mechanism. This is the
  normal state for every node on a host where the selection has always been a pinned node, and the
  normal state for every node in the first seconds after a restart.
- **BC-12 — the probe URL's own name resolution.** `remote_dns` carries `detour: proxy`
  (`bin/sc:1072`) and `dns.rules` routes `geosite-google` to `remote_dns` (`bin/sc:1089`), while
  `route.default_domain_resolver` is `direct_dns` (`bin/sc:1105`). Whether the auto-select group's
  probe resolves its URL through `direct_dns` (no circularity) or through `remote_dns → proxy →
  the group being probed` (a startup circularity that would make the failover path fail exactly when
  it is needed) must be **established**, not assumed. See AC-15.
- **BC-13 — an upgrade of an existing host.** `/etc/sing-box/nodes.json` holds nodes and a node-tag
  selection; `/etc/sing-box/config.json` holds the pre-T-15 shape;
  `/etc/sing-box/.config.sha256` holds the digest of that file. No hand-editing may be required.
- **BC-14 — a user `override.json` that `$replace`s `outbounds`.** The auto-select group is
  destroyed, because the user's document is applied last and by design
  (`README.md:250`). This is the documented contract, not a defect; nothing in this task tries to
  defend against it.
- **BC-15 — `sc ls` output redirected to a file or pipe.** The non-TTY output contract holds: no
  `\r`, one complete line per entry (`CONTEXT.md`, *non-TTY output contract*).
- **BC-16 — concurrent `sc` invocations.** Unchanged from today: no lock exists, `nodes.json` is
  written through `_write_private()`'s atomic replace, and the reads this task adds are read-only.

---

## 6. Acceptance criteria

Each is checkable by a fixture, by reading the emitted document, or by a command's observable output.

### Emitted configuration

- **AC-1.** With ≥1 node, the emitted `config.json` contains exactly one `urltest` outbound; its
  `outbounds` array equals the node tags in `nodes.json` order; `direct` is not among them.
- **AC-2.** With ≥1 node, the `proxy` selector's `outbounds` array contains the auto-select group's
  tag, every node tag, and `direct`.
- **AC-3.** In every state of BC-1 … BC-4, the `proxy` selector's `default` value is an element of
  that same selector's `outbounds` array.
- **AC-4.** In every state of BC-1 … BC-4, every outbound tag referenced anywhere in the emitted
  document (`proxy.outbounds`, `proxy.default`, the group's `outbounds`, `route.rules[].outbound`,
  `route.final`, `dns.servers[].detour`) is defined by an outbound in that same document.
- **AC-5.** With zero nodes the emitted `outbounds` array is **byte-identical** to what the current
  build emits for the same inputs — no auto-select group, no other change.
- **AC-6.** No two outbounds in the emitted document share a `tag`.
- **AC-7.** The diff introduces no new configuration structure inside `generate_config()`; every new
  key/value reaches the document through `CONFIG_BASE` or an overlay merged by `_merge()`. Verifiable
  by reading the diff: `generate_config()`'s body gains no outbound literal.

### Selection state machine

- **AC-8.** `sc use <auto-tag>` on a running service sets `nodes.json`'s `active` to the reserved tag,
  issues one Clash API call, prints the switched-to line, and performs **no service-affecting
  action**. The service witness (`systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`) is
  identical before and after.
- **AC-9.** With `active` equal to the reserved tag and ≥1 node, running config generation **does not
  rewrite `active`**. Re-running it N times leaves `nodes.json` unchanged.
- **AC-10.** Removing the last node while `active` is the reserved tag yields an emitted document
  satisfying AC-3/AC-4, and a persisted `active` that is not the reserved tag.
- **AC-11.** `sc add` with a share link whose fragment equals the reserved tag yields a node whose
  tag is **not** the reserved tag, and an emitted document satisfying AC-6.
- **AC-12.** With a node tagged `<reserved-tag>-XX`, `sc use <reserved-tag>` selects the auto-select
  group, not that node (BC-8).
- **AC-13.** `sc use <node>` and `sc use <index>` behave exactly as they do at HEAD for every node,
  in both languages — same resolution, same index numbers, same output strings.

### The real binary

- **AC-14.** The emitted document passes the **real** `sing-box check` (not a fixture checker) in
  each of: 0 nodes, 1 node, 3 nodes, selection = node, selection = auto-select group, and one
  degraded rule-set state. T-05 established that fixtures hide what the real binary rejects
  (`.harness/insight-index.md:21`).
- **AC-15.** BC-12 is answered with evidence in `02_SOLUTION_DESIGN.md`: which DNS server resolves
  the auto-select group's probe URL, and why that is not the group itself. If it is the group itself,
  the probe URL or the DNS routing of the probe is changed so it is not.
- **AC-16.** Every parameter emitted on the auto-select group (`url`, `interval`, `tolerance`,
  `idle_timeout`, and any other) is individually justified in `02_SOLUTION_DESIGN.md` — kept or
  changed from the report's starting point *with a stated reason*, not adopted wholesale.

### Compatibility with existing installs

- **AC-17.** On a host in BC-13's state, `sc reload` succeeds with **no hand-editing of any file
  under `/etc/sing-box`**, and afterwards `sing-box check` accepts the config.
- **AC-18.** On that same host, that first `sc reload` prints **no drift warning**. *(Mechanism to
  preserve: `_warn_drift()` (`bin/sc:1426-1452`) compares the recorded digest against the digest of
  `config.json` **as it is on disk before replacement** (`_warn_drift()` is called at `:1502`, the
  write at `:1506`); both sides describe the old document, so a change to the generated shape cannot
  move either. The AC exists to keep that property, which is currently a consequence of ordering
  rather than of an assertion.)*
- **AC-19.** After that `sc reload`, `/etc/sing-box/.config.sha256` holds the digest of the
  **new-shape** file on disk, and a second immediate `sc reload` again prints no drift warning.
- **AC-20.** `sc update-rules` on a host where no rule-set's bytes changed performs **no**
  service-affecting action and prints the "No rule-set changed" outcome line, exactly as T-10
  (`90ad762`) made it — unchanged by the fact that the *generated* shape now differs from the file on
  disk. Verified with the `MainPID`/`ActiveEnterTimestamp` witness, never `is-active`
  (`.harness/insight-index.md:15`).
- **AC-21.** The upgrade path that *does* need a restart still gets one: `sc reload` after an upgrade
  restarts the service. This task suppresses no genuinely-needed restart.
- **AC-22.** `sc use <auto-tag>` against a service still running the **pre-T-15** config (the API
  rejects an unknown member) falls through to the existing regenerate-and-restart path
  (`bin/sc:1626-1627`) and ends with the selection applied — it does not fail, and it does not leave
  `nodes.json` claiming a selection the running process does not have.

### `sc ls`

- **AC-23.** With a running service that has probed the nodes, `sc ls` shows a delay figure for each
  probed node in both languages.
- **AC-24.** **Degraded rendering — the API is unreachable** (service stopped, or port not
  answering): `sc ls` prints the same table it prints today plus the delay column filled with the
  unknown marker for every row, exits 0, and prints no traceback and no Python exception text. In
  both languages. This is the AC the brief calls hard: `sc ls` must work on a broken host.
- **AC-25.** Same as AC-24 for each malformed-body case of BC-10.
- **AC-26.** A node the API reports with no stored delay renders as the unknown marker, distinct from
  any numeric rendering (FR-12).
- **AC-27.** `sc ls` with the service stopped issues **no** Clash API request at all (no 3 s wait);
  measured wall-clock is within noise of today's.
- **AC-28.** `sc ls` adds no new timeout constant and changes none. `clash_api()`'s `timeout=3`
  is byte-identical in the diff.
- **AC-29.** `sc ls` performs **no** service-affecting action and issues no `PUT`/`PATCH`/`DELETE`.
  Verifiable structurally: the new code path contains no non-`GET` method argument.
- **AC-30.** With zero nodes `sc ls` prints today's "(no nodes …)" line unchanged.
- **AC-31.** Index numbers printed by `sc ls` for nodes are unchanged from HEAD in every case,
  including when the auto-select group entry is displayed (FR-14).

### Cross-cutting

- **AC-32.** `bash .harness/scripts/verify_all.sh` ends with **no FAIL** (baseline: PASS 17 / WARN 0
  / FAIL 0 / SKIP 1). A doc-size WARN that clears on archive is acceptable and must be predicted, not
  discovered.
- **AC-33.** Every new user-facing string exists in both `en` (the key itself) and the `zh` table with
  an identical placeholder set; no new zh string contains `失败：`.
- **AC-34.** `README.md` and `README.zh-CN.md` document the new behaviour and stay line-for-line
  mirrors of each other. `CHANGELOG.md` gains a Chinese entry.
- **AC-35.** `python3 -m py_compile bin/sc` passes and the diff uses no syntax newer than Python 3.6
  and no non-stdlib import.

---

## 7. Non-goals

- **NG-1.** Do not replace the `proxy` selector with a `urltest`. `sc use <name>` is documented
  behaviour (`README.md:79-81`) and manual pinning must survive.
- **NG-2.** Do not change the DNS section — servers, rules, `final`, or `remote_dns`'s `detour`.
  T-16 owns DNS. *(BC-12/AC-15 may **read** the DNS section to answer a question; reading is not
  changing. If the answer turns out to require a DNS change, that is a finding for `02`, re-homed to
  T-16, not a change made here.)*
- **NG-3.** Do not add the telemetry list (T-17).
- **NG-4.** Do not touch rule-source profiles (T-21).
- **NG-5.** Do not touch `install.sh`, `uninstall.sh` or `systemd/`.
- **NG-6.** Do not add or change any timeout constant. **This is about `sc`'s own waits** — the three
  the dev-map calls owner-directed (`docs/dev-map.md:83-84`: Clash API 3 s, egress IP 8 s, rule-set
  download 30 s). The auto-select group's `interval` / `idle_timeout` are **probe cadence emitted
  into sing-box's config**, not waits `sc` performs; they are governed by AC-16, not by NG-6. Stage 3
  must not re-litigate this distinction.
- **NG-7.** Do not add a delay probe to `sc doctor` in this task. FR-11 requires only that the reader
  be callable from there unchanged.
- **NG-8.** Do not issue an on-demand `/proxies/:name/delay` call. That would be `sc` measuring
  rather than reading, would cost real network time in `sc ls`, and would need a timeout NG-6 forbids.
- **NG-9.** Do not add a committed test harness / `verify_all` step. That is R-9's scope; see
  `.harness/rejected-decisions.md § ruleset-unit-tests-in-t02` (declined five times, do not
  re-litigate — but do not smuggle it in either).
- **NG-10.** Do not fix the five namespaced `ls.*` translation keys (`bin/sc:174-178`) that print
  literally in English. See D-13 and R-19.
- **NG-11.** Do not change `sc now` or `sc status`. See D-7.
- **NG-12.** Do not build a subscription updater, a node-health history, a "best node" ranking
  command, or any persisted latency record. Nothing stated asks for them.
- **NG-13.** Do not extend the `_merge()` directive vocabulary. See D-12 (R-16 ruling).

---

## 8. Non-functional requirements

- **NFR-1 — `sc ls` stays a basic command.** Its worst-case added wall-clock is one existing 3 s
  `clash_api()` timeout, and zero when the service is not running.
- **NFR-2 — Python 3.6 floor, stdlib only** (`.harness/rules/50-singbox-cli.md:104-106`).
- **NFR-3 — bilingual parity is a correctness requirement, not a nicety**
  (`.harness/rules/50-singbox-cli.md:95-97`).
- **NFR-4 — no credential exposure.** Nothing this task adds writes, logs or prints node credentials.
  `nodes.json` and `config.json` remain credential documents written only through `_write_private()`.
- **NFR-5 — permitted diff:** `bin/sc`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`,
  `docs/dev-map.md` (the reusable-utilities table gains the FR-11 reader), plus this task's stage
  docs. Nothing else.

---

## 9. Safety constraints — binding on stages 4 and 6

Carried forward verbatim in intent from `.harness/insight-index.md` and the dispatch brief.

- **S-1.** Every harness and every throwaway script **must neutralise `bin/sc`'s import-time
  auto-elevate** (`bin/sc:101-102`). Un-neutralised, it re-execs the **installed**
  `/usr/local/bin/sc` — an older, diverged build — under sudo against the **live** service
  (`.harness/insight-index.md:11`). Use the recipe in `docs/dev-map.md:109-135`; do not re-invent it.
- **S-2.** **Never drive `_init_files()`.** It hard-codes `/var/lib/sing-box` as a `Path` literal, so
  it writes to the real `/var/lib` even in a fully redirected fixture
  (`.harness/insight-index.md:23`).
- **S-3.** Never write under `/etc`. Repoint all seven path constants into a `mkdtemp()` root and
  **assert** each resolves inside it.
- **S-4.** Never invoke `/usr/local/bin/sc`. Never call `restart_service()` / `reload_or_restart()`
  against this machine; set `SYSTEMD = OPENRC = False` in every fixture.
- **S-5.** **This task touches the Clash API: issue no `PUT`, `PATCH` or `DELETE` to the live API.**
  A `PUT /proxies/proxy` would switch the owner's active node. `GET /proxies` and `GET /configs` are
  read-only and acceptable; anything that could change the selection is **stubbed**, not called.
- **S-6.** Service witness is `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`, **never
  `is-active`** — it prints `active` on both sides of a restart (`.harness/insight-index.md:15`).
  Baseline: `MainPID=2887037`, `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST`.
- **S-7.** A differential `generate_config()` harness must run baseline and candidate at the **same**
  fixture path — `RULES_DIR` is emitted verbatim into `route.rule_set[].path`
  (`.harness/insight-index.md:27`).
- **S-8.** A `bin/sc` harness must set `LANG` the way `main()` does, or Chinese assertions pass
  vacuously (`.harness/insight-index.md:28`). Use a **clone**, never a `git worktree`, for a pristine
  baseline (`.harness/insight-index.md:18`).
- **S-9.** QA's adversarial section heading must match `^##\s+Adversarial\s+tests` — an unnumbered
  heading (`.harness/insight-index.md:22`).

---

## 10. Rule-85 ruling — are the two halves one task?

**Ruling: one task.** Both of rule 85's first two tests fire.

**Test 1 (patch-then-patch seam) — fires.** E-4 establishes that the Clash API serves a *stored*
url-test history, not a measurement. Ship half B alone and `sc ls` gains a delay column that is empty
for every node on every host where the user has never opted into probing — a feature that computes
nothing anyone consumes, and an intermediate state that is *dishonest on its own*: a column headed
"delay" reading unknown everywhere invites the reading "these nodes are unreachable" when the truth
is "nobody has probed them". Ship half A alone and the failover is invisible: the user cannot see
which node the group chose or why, which is the exact diagnostic gap the reporter had to close by
comparing machines by hand. Half A *is* what makes half B's data exist; half B *is* what makes half
A observable. That is the T-01 `INSTALL_OK`-versus-lying-banner precedent, verbatim.

**Test 2 (duplicated judgment) — fires.** Both halves need "which node is traffic actually on right
now". Half A needs it because the selection can be a group rather than a node (FR-6, BC-3);
half B needs it to render FR-13. Split, each grows its own answer and they can disagree — which is
the seam `.harness/rules/85-design-discipline.md` test 2 names and which `sc doctor` (T-05) was
explicitly built to avoid. FR-11's single reader is the consolidation.

**Test 3 (shape check) — passes.** The two halves are not the report's section numbers; they are
"the config gains a probing member" and "the CLI reads what that probing produced" — one domain
concept (a probed selection) seen from the write side and the read side.

**Counter-rule check — is this over-building?** No new file, no new config format, no new command.
The diff is: one constant, one overlay change, one selection-validity predicate, one API reader, one
`sc ls` rendering change, plus strings and docs. NG-7/NG-8/NG-12 exist precisely to hold the line
against the generalizations this task could invite.

---

## 11. Decisions taken under standing authority (PM-authorized)

- **D-1 — shape: keep the selector, add the group as a member.** The owner's aim is adopted, not
  silently replaced. Reason: `sc use <name>` is documented (`README.md:79-81`) and a bare `urltest`
  destroys it; and `CONTEXT.md`'s "singbox-cli is a headless v2rayN" intent names failover groups
  and per-node latency as roadmap items, both of which this shape delivers. Rejected alternative:
  replacing the selector. Rejected alternative: a `fallback`-style ordered group — sing-box has no
  such outbound type; `urltest` with a `tolerance` is how sing-box expresses "prefer the current one
  unless another is meaningfully better".

- **D-2 — tag name.** **Recommended: `auto`.** It is the word v2rayN/Clash users already type, it is
  short (`sc use auto`), and it is language-neutral so it does not change under `sc lang`. The
  *literal* remains stage 2's call; whatever it picks must satisfy FR-2 (one constant), FR-3
  (reserved), BC-7 and BC-8. Rejected: a localized tag (tags live in `config.json` and would change
  meaning with the UI language); `URLTest` (a type name, not a user word).

- **D-3 — zero nodes: no group.** With no nodes the group would have no members; E-4's `missing tags`
  finding makes that a probable hard rejection, and AC-5 additionally keeps the fresh-install path
  byte-identical to today's, which is the cheapest possible compatibility guarantee for the state
  every new host starts in.

- **D-4 — one node: the invariant, not the arm, is the requirement.** The report's template keeps the
  indirection at one node so adding a second changes no references. **Recommended: always emit the
  group when ≥1 node exists**, because it makes "the group exists ⟺ at least one node exists" a
  single condition to test, and because the alternative creates a state transition (1 node → 2 nodes,
  and 2 → 1) during which a persisted selection of the reserved tag becomes stale — BC-3's trap,
  reachable by `sc rm` rather than by hand-editing. Stage 2 may instead special-case one node
  **provided** it satisfies AC-3, AC-4, AC-9 and AC-10 across both transitions. Cost of the
  recommendation, stated honestly: one probe per interval that changes no routing decision.

- **D-5 — the default selection.** **`sc` selects the auto-select group exactly where it today picks
  an arbitrary node on the user's behalf, and never rewrites a selection the user made.** Today
  `sc` auto-picks in three places, and all three pick `node_tags[0]` — an arbitrary choice: `sc add`
  onto an empty list (`bin/sc:1641-1642`), `sc rm` of the active node (`bin/sc:1655-1656`), and
  config generation's stale repair (`bin/sc:1472-1475`). Replacing an arbitrary pick with the
  failover group is strictly better and overrides nobody. **Existing hosts are untouched**, because
  their `active` is already a valid node tag so none of the three fires — which is what makes the
  upgrade quiet (AC-17/AC-18) while new installs get failover by default. Rejected: rewriting every
  host's selection to `auto` on upgrade (silently changes which outbound carries a user's traffic,
  precisely the surprise the compatibility ACs guard against). Rejected: pure opt-in with no default
  change (the reported incident then recurs for every user who does not read the changelog).

- **D-6 — `active` may hold a non-node value: the full correctness surface.** Enumerated here so
  stage 4 does not discover it: `_runtime_overlay()`'s `default` (FR-7/AC-3) · config generation's
  stale-active repair predicate (FR-6/AC-9 — **without this, `active = auto` is clobbered back to
  `node_tags[0]` on every single regeneration**) · `cmd_rm`'s last-node path (BC-3/AC-10) ·
  `_resolve_node()`, which must not be consulted for the reserved tag at all (BC-8/AC-12) ·
  `sc ls`'s `●` marker, which means "this is what the selection names" and therefore sits on the
  auto entry, not on any node row, when the group is selected (FR-13/FR-14) · `sc doctor`, which has
  no node concept and needs no change (E-3, NG-7).

- **D-7 — `sc now` and `sc status` are unchanged.** `sc now` prints one token today and is the
  obvious thing to embed in `$(…)`; printing `auto → US-1` would change that parse. `sc now`
  printing the reserved tag is already truthful — the selection *is* auto. The "which node right
  now" fact is carried by `sc ls` (FR-13), one place. Counter recorded: a user who runs only
  `sc status` sees `Current node: auto` and must run `sc ls` to learn more; judged acceptable
  against a tighter diff and one owner of the fact.

- **D-8 — one delay reader, created here, not reused.** E-2/E-3 establish that no latency notion
  exists in `bin/sc`, so this is world 2 of the two the brief names. FR-11 creates exactly one
  reader with no `sc ls`-specific parameter, so `sc doctor` can call it later — satisfying rule 85
  test 2 prospectively without building the doctor row now (NG-7).

- **D-9 — unknown is rendered, never faked.** A never-probed node (BC-11) is the *normal* state on a
  host that has always pinned a node, so this rendering is on the common path, not an edge. `0` would
  read as "instant" and an empty cell reads as "zero". FR-12 forbids both.

- **D-10 — the delay query is guarded by `is_running()`.** Same guard `sc status` (`bin/sc:1694`)
  and `sc use` (`bin/sc:1621`) already use. It costs one cheap init-system call and removes the
  3 s wait entirely on a stopped host (AC-27). Note for the record: `.harness/insight-index.md:15`'s
  warning is about `is-active` being unable to *detect a restart*; it is unaffected as a
  "is it up right now" guard, which is all this use needs.

- **D-11 — the report's urltest parameters are a starting point.** `url:
  https://www.gstatic.com/generate_204`, `interval: 3m`, `tolerance: 50`, `idle_timeout: 30m` are
  adopted as candidates only; AC-16 requires each to be justified individually. Two specific things
  stage 2 must weigh: BC-12 (the probe URL's resolution path — `www.gstatic.com` is in
  `geosite-google`, which `dns.rules` sends to `remote_dns`, which detours through `proxy`), and
  whether `idle_timeout` interacts badly with a host whose only traffic is the periodic
  `sc update-rules` run. NG-6 does **not** cover these values; the distinction is stated in NG-6
  itself so stage 3 need not re-open it.

- **D-12 — R-16 is NOT claimed by this task.** `docs/tasks.md` R-16 names its owner as "whichever of
  T-15/T-16/T-17/T-21 first needs the merge's type-mismatch vocabulary". This task does not need it:
  its overlay is authored **in code** (confirmed by
  `.harness/rejected-decisions.md § override-as-confd-fragment-directory`, which states that
  T-15/T-16/T-17 ship their overlays inside `bin/sc`), and it changes `outbounds` with the existing
  `$replace` directive on an array `CONFIG_BASE` already defines. R-16 is about a *user* override
  silently replacing an array with a bare object; nothing here approaches that surface. **R-16 stays
  open, unclaimed by T-15.** NG-13 makes this binding.

- **D-13 — the new column header uses an English-sentence key.** `TRANSLATIONS` has no `en` table,
  so `t()` returns the key (`bin/sc:107`), and the five `ls.*` keys therefore print literally as
  `ls.idx` / `ls.active` / … in English — a defect `docs/dev-map.md:77-79` explicitly says not to
  copy. The new key is an English sentence. Accepted consequence: the English header row is visibly
  mixed until the five are fixed. Rejected: adding `ls.delay` (copies a defect the dev-map bans).
  Rejected: converting all five here (a 6-line unrequested change to existing output —
  `.harness/rules/85-design-discipline.md`'s counter-rule forbids widening scope). Filed as **R-19**.

- **D-14 — group options beyond the four named** (`interrupt_exist_connections` on the group,
  member ordering inside the selector, whether the group precedes or follows the node tags) are
  stage 2's, constrained only by AC-1/AC-2/AC-16.

---

## 12. Related historical work

| Task | Why it matters here |
|---|---|
| **T-14** `config-composition-layer` (`1e454b6`) | The layer this task must build on. `CONFIG_BASE` + `_runtime_overlay()` + `override.json` through one `_merge()`. Landed specifically to make T-15 small. FR-8 makes using it binding; FR-9 makes a shortfall reportable. Archived at `docs/features/_archived/config-composition-layer/`. |
| **T-05** `sc-doctor` (`1b1b0e0`) | Owns the rule-85 "no second opinion" constraint. E-3 corrects the brief: doctor has **no** node/latency notion, so D-8 creates the first one rather than reusing one. Its QA also established that fixtures hide what the real binary rejects → AC-14. |
| **T-10** `ruleset-update-no-needless-restart` (`90ad762`) | Made the restart conditional on real rule-set content change. AC-20/AC-21 keep both halves of that promise. Its insight about `is-active` is S-6. |
| **T-13** `config-write-permission-hardening` | `_write_private()` is the only writer of `nodes.json` / `config.json`; NFR-4 keeps it that way. Also the source of the auto-elevate neutralisation recipe (S-1). |
| **T-02** `config-degrade-missing-rulesets` | Owns rule-set degradation, which AC-14 must exercise alongside the new outbound shape. |
| **R-15 / R-16 / R-18** (`docs/tasks.md:170-211`) | R-16 explicitly ruled not-ours (D-12). R-15 (override exception envelope) is untouched by this task. R-18: `archive-task.sh` rotation is dead and the index is at the 30-line cap — the PM already noted hand-rotation at delivery. |

---

## 13. Open rows this analysis surfaces

- **R-19 — the five `ls.*` translation keys print literally in English.** `bin/sc:174-178` +
  `bin/sc:1605`. English users see `ls.idx  ls.active  ls.type  ls.name  ls.address` as the `sc ls`
  header. Known since T-02 (`docs/tasks.md` note 2 of the T-02 follow-ups, "`TRANSLATIONS` has no
  `en` table"), but never filed against these specific five. One-line fix per key: replace each with
  the English word it means. Deliberately out of T-15's scope (D-13 / NG-10). Natural owner: the
  next task that changes `sc ls`'s columns, or a small cleanup row.

---

## 14. Verdict

**READY.**

Every ambiguity is resolved as a numbered decision under the owner's standing authority; none is
left open, and no safety red line was encountered. The premise correction is verified independently
at the source (E-1), the Clash API's actual behaviour is established from the installed binary
(E-4), and the brief's own claim about `sc doctor` is corrected with evidence (E-3).

Three items are deliberately handed forward as *design* questions with the requirements they must
satisfy already stated, per the dispatch: the exact reserved tag literal (D-2 → FR-2/FR-3/BC-7/BC-8),
the one-node arm (D-4 → AC-3/AC-4/AC-9/AC-10), and the group's parameters (D-11 → AC-15/AC-16).
