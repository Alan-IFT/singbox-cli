# 02 — Rationale · T-15 `proxy-urltest-group`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

`docs/dev-map.md`'s reusable-utilities table and `bin/sc`'s section map were read before any
function was invented. Nothing here is a second opinion about something the codebase already
decides.

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Apply a configuration fragment | `_merge()` + `DIRECTIVES` (`$replace` on an array the base defines) | `bin/sc:1039`, `:1220` | **Reuse as-is.** The group reaches the document through `_runtime_overlay()`'s existing `outbounds` `$replace`. No new directive (NG-13/D-12 honoured), no second merge. |
| Run-time content of the config | `_runtime_overlay(nodes, active, report)` | `bin/sc:1342-1375` | **Extend in place.** It already builds the selector and the trailing `direct`; the group is one more element of the same array it already `$replace`s. |
| The base of the emitted config | `CONFIG_BASE` + `_compose()` | `bin/sc:1066`, `:1329` | **Untouched.** The group depends on run-time state (node tags), so by the T-14 split it belongs in the overlay, not the base. |
| "Is this selection stale, and what does it become" | `generate_config()`'s inline `if active not in node_tags: active = node_tags[0]` | `bin/sc:1471-1475` | **Promote, don't duplicate.** The judgment already exists but is inline and admits node tags only, and two other call sites (`cmd_add:1641`, `cmd_rm:1655`) re-implement the same arbitrary `node_tags[0]` pick. Extracting `_valid_selection()` turns three copies into one — rule 85 test 2 applied to code that already had the duplication. |
| Talk to the running sing-box | `clash_api(method, path, data=None, port=None)` | `bin/sc:1536-1550` | **Reuse as-is.** `stored_delays()` is a caller. Its `port=None` parameter is copied verbatim into the reader's signature so `sc doctor` (which passes a port explicitly, `bin/sc:1966`) can call it later without a second reader. |
| "Is the service up right now" | `is_running()` | `bin/sc:1553-1559` | **Reuse as-is** (D-10). Same guard `sc status:1694` and `sc use:1621` use. |
| Per-node latency / delay anywhere | **(none found)** | — | E-2/E-3 stand after re-checking: `bin/sc` contains no `delay`/`latency` notion and `DOCTOR_SECTIONS` (`bin/sc:1995-2003`) has no node concept. New function justified; FR-11/D-8 place it where the second one would otherwise be invented. |
| Mint a non-colliding node tag | `_unique_tag(tag, existing)` | `bin/sc:1587-1593` | **Extend by one condition.** It already owns "a new node's tag must not collide"; it simply did not know the emitted document has tags of its own. |
| Table rendering for `sc ls` | the two f-strings at `bin/sc:1605`, `:1609` | same | **Extend in place.** No table abstraction exists and one column does not justify inventing one. |
| Bilingual string | `t()` + `TRANSLATIONS` | `bin/sc:107-108` | **Reuse as-is**, with D-13's English-sentence key. |
| Foreign text made output-safe | `_plain()` | `bin/sc` `# doctor` | **Not needed.** Nothing new prints foreign text: the only externally-sourced value rendered is the group's `now`, which is an outbound tag `sc` itself emitted, and it is truncated to the address column's width. |

## Why these three functions and not fewer or more

`_valid_selection()` passes the deletion test loudly: delete it and the same four-clause rule
reappears in `generate_config`, `cmd_add`, `cmd_rm` and `_runtime_overlay`, where D-6 predicts they
will disagree (`active = auto` clobbered back to `node_tags[0]` on every regeneration is the
concrete disagreement).

`_auto_group_emitted()` earns its line only because K-6 made the condition non-trivial. With D-4's
plain arm the condition would have been `bool(node_tags)` and a named helper for that would have
been noise; once the second clause (`AUTO_TAG not in node_tags`) exists, four consumers must agree
on it and a mismatch between "the group is in the document" and "the selection may name the group"
emits a dangling reference. Two adapters make a real seam; here there are four.

`stored_delays()` is FR-11's requirement, but it would have been the right shape anyway: it is deep
in the intended sense — one 2-tuple return hides the Clash envelope, the history-list convention,
sing-box's stored-history semantics (E-4), the `0`-means-failed convention, the running-service
guard and every malformed-body case. Its callers learn a dict and an optional string.

Rejected: a `_selection_target(spec)` helper wrapping the `sc use` reserved-tag arm. One caller,
and `_resolve_node()` must stay frozen (AC-13), so the wrapper would be a seam nothing varies
across. Inlined in `cmd_use` with the ordering stated.

Rejected: a table-rendering helper for `sc ls`. Two f-strings, one new column; a renderer would be
an abstraction with one call each.

## Option comparisons

**D-2, the literal.** `auto` beats `urltest` (a type name, not a user word), `auto-select` (longer
to type for the one command users type most), and any localized word (tags live in `config.json`
and would change meaning under `sc lang`). Collision risk is handled structurally by I-2/K-3/K-6
rather than by picking an exotic literal, which is why the obvious word is affordable.

**Widening `RESERVED_TAGS` to `proxy` and `direct` as well.** Strictly this task needs only
`AUTO_TAG`. Two reasons to widen: stage 1's own vocabulary defines *reserved outbound tag* over all
three ("Today there are two (`proxy`, `direct`); this task adds…"), and the widened form costs the
same single line while closing a live AC-6 hole — today a share link with fragment `#direct` mints a
node tagged `direct` and the emitted document carries two `direct` outbounds, which `sing-box check`
rejects. Cost, stated: a user who deliberately named a node `proxy` or `direct` on an older build
keeps that name (nothing renames existing nodes) but a *new* one becomes `direct #2`.

**D-4, the one-node arm.** Taken as recommended. The alternative buys one probe per interval and
costs two state transitions (1→2, 2→1) in which a persisted `active = auto` is stale, reachable by
`sc rm` rather than by hand-editing — BC-3's trap, multiplied. The saved probe is one TLS handshake
per 3 minutes on a host that is already routing all its DNS through the proxy.

**K-6, the node-already-tagged-`auto` carve-out.** Three options were weighed. (a) Rename the
colliding node during config generation: preserves the feature, but silently renames a user's node
and needs a new bilingual notice. (b) Emit no group on that host: one condition, no persisted
mutation, no new string, and — decisively — every other behaviour falls out correctly, because
`sc use auto` then simply resolves to the node exactly as it did at HEAD (AC-13) and
`_valid_selection`'s last clause reverts to today's `node_tags[0]`. (c) Emit the group anyway:
rejected outright, it produces a document `sing-box check` rejects on an *upgrade*, breaking AC-17.
(b) was chosen. No warning is printed, on `_warn_drift()`'s own stated reasoning
(`bin/sc:1434-1436`): a permanent line on every run, for a documented naming choice that no
`sc`-created host can reach, teaches people to ignore warnings.

**The unknown marker.** `-` beats `(none)`/`（无）` (reusing that key would have read as a value
rather than an absence, and it is 6 columns wide), beats an em dash (double-width under CJK
locales, worsening a table that is already misaligned), and beats a new bilingual key (a key whose
two sides are identical is parity surface with no benefit). `-` is the conventional empty cell in
POSIX table output and is unmistakable next to `123 ms`.

**The delay column's position.** Last, so no existing column moves (AC-31) and the CJK
display-width defect of the existing headers cannot cascade into the new one. As a side effect the
rendered line no longer ends in padding whitespace, because the new cell is right-aligned.

**The group row's position.** First, under the header: it is the row that carries `●` on any host
that took the default, it mirrors the selector's member order, and the numbered rows stay a
contiguous block whose numbering is untouched.

## Evidence gathered at this stage

Read-only string inspection of `/usr/local/bin/sing-box` (v1.13.15), the technique
`.harness/insight-index.md:16` established. This session had **no shell tool**, so counts come from
ripgrep over the binary and no `sing-box check` could be executed (RS-4).

| Literal | Count | What it establishes |
|---|---|---|
| `LoadURLTestHistory` | 2 | E-4 re-confirmed: the proxies handler serves a **stored** history |
| `https://www.gstatic.com/generate_204` | 1 | the full URL is compiled in as a default — I-9 emits the binary's own best-exercised value |
| `http://www.gstatic.com/generate_204` | 0 | the http variant is not the built-in default |
| `json:"tolerance,omitempty"`, `json:"interrupt_exist_connections,omitempty"` | 1 each | both group options are accepted by this binary |
| `missing tags` | 2 | consistent with a group rejecting an empty member list; unreachable by design either way (I-3) |
| `missing domain resolver` | 1 | there is a failure path for "resolution was required and no resolver was configured" — i.e. resolution is conditional on configuration, not unconditional |
| `default domain resolver` | 1 | the `route.default_domain_resolver` mechanism that `bin/sc:1105` sets exists in this binary |
| `domain_strategy` in `bin/sc` | 0 hits | no emitted outbound asks for local resolution (K-14's premise) |

**AC-15, the full argument.** The probe dials through a *member outbound*, not through the router,
so `route.rules` are not consulted for it at all — and `dns.rules` are reached only if a local name
lookup happens first. It does not: no emitted outbound carries `domain_strategy`, so the FQDN is
carried inside the member's own protocol to the remote server, which resolves it. Counterfactually,
if a dial-side lookup did occur it is pinned to `route.default_domain_resolver` = `direct_dns`
(`bin/sc:1105`), a plain UDP server with no `detour` — still not the group. Only a third branch (a
local lookup that *also* traverses `dns.rules`) reaches `remote_dns → detour: proxy → the group`,
and that branch is untouchable from here: `dns.final` is `remote_dns`, so *every* non-CN probe host
lands there and no URL choice escapes it. Hence RS-2 (re-homed to T-16) rather than a redesign, and
V-19 as the falsifiable observation — if the third branch were real and harmful, no node would ever
acquire a stored delay.

**Forward references are fine.** The shipped selector at `bin/sc:1357-1366` is emitted *before* the
node outbounds it names and the current build passes `sing-box check` on every host, so placing the
group between the selector and the nodes (K-5) needs no new tolerance from the binary.

## Risk analysis

| # | Risk | Mitigation |
|---|---|---|
| 1 | **A dangling outbound reference in some reachable state** — the emitted `default` or a persisted `active` naming an outbound the same document does not define. Historically the sharpest failure here (D-6). | One judge (`_valid_selection`) with two consumers: `generate_config` for persistence and `_runtime_overlay` for the emitted `default`. Computing `default` through the same function makes AC-3/AC-4 structural rather than a consequence of call ordering, and costs one extra pure call per run. V-3 scans every reference in every BC-1…BC-4 state. |
| 2 | **The upgrade breaks a working host** — the whole feature is worthless if `sc reload` fails on a host that was fine. Two concrete paths: a node already tagged `auto` (duplicate tag → `sing-box check` FATAL) and a drift warning appearing on every host at first upgrade. | K-6 removes the first by not emitting the group there. The second is protected by the frozen ordering of `_warn_drift()` (`:1502`) versus the write (`:1506`): both sides of the comparison describe the *old* file, so a change to the generated shape cannot move either. V-11 exercises both on a BC-13 fixture. |
| 3 | **`sc ls` becomes a command that fails on a broken host** — the exact machine where the user runs it. A traceback from a malformed API body, or a 3 s stall on a stopped service, would make the diagnostic useless when it matters. | `is_running()` guard inside the reader (no request, no wait, AC-27); `clash_api()` already swallows every `URLError`/`HTTPError` into `None`; every field is `isinstance`-tested with no `try`/`except` (K-12), so absence is the only failure mode. V-15/V-16/V-17 drive all of it. |
| 4 | **The probe cannot resolve its own URL** (BC-12) — failover would then be dead exactly when needed, and silently. | K-14/K-15 pin the two premises the answer rests on; V-19 makes it observable on the live host (delays exist ⟺ probes completed); RS-2 carries the residual to the task that owns DNS. |
| 5 | **Flapping** — a group that re-selects on jitter re-points DNS and the data plane every few minutes. | `tolerance: 50` (I-11) plus omitting `interrupt_exist_connections` (I-13), so even a re-selection does not tear down live connections. |
| 6 | **Scope creep in a task that touches nine call sites** — the tempting adjacent fixes are the five `ls.*` keys, CJK column alignment, and a `sc doctor` delay row. | All three are named in `## Out of scope` and the first two are in the frozen set (NG-10, R-19); the third is NG-7, and FR-11's parameterless-but-port-carrying signature is what makes deferring it free. |
| 7 | **A gate reading of FR-11 that forbids the `port=None` parameter.** | The parameter is not an `sc ls` argument — `sc ls` calls `stored_delays()` with none. It exists solely because `clash_api()`'s own contract (`bin/sc:1537-1539`) says only `sc doctor` passes a port, and `sc doctor` skips `_resolve_clash_port()` so the module-level `CLASH_PORT` is stale there (`bin/sc:269`, `:2468`). Without the parameter, the "callable from `sc doctor` unchanged" clause of FR-11 would be false on any host whose port drifted. |

## Note on `CONTEXT.md`

The four terms this task fixes (*auto-select group*, *reserved outbound tag*, *selection*, *stored
delay*) are defined in `01_REQUIREMENT_ANALYSIS.md` §3 and recommended for the glossary there.
`CONTEXT.md` is outside NFR-5's permitted diff, so this design does not write them; the glossary
addition travels with delivery.
