# 02 — Rationale · T-16 `dns-resilience`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## 1. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Apply a configuration fragment | `_merge()` + the five `DIRECTIVES` | `bin/sc` `# Config composition` (`sc:1052`, `sc:1233`) | Reuse **unchanged**; `$prepend` on `dns.rules` needs no new directive and no anchor (I-6) |
| Carry run-time content into the document | `_runtime_overlay()` | same (`sc:1399`) | **Not** extended. Its inputs are node/rule-set state; the IPv6 decision is a different judgment with a different input and a different failure mode, and touching it would perturb T-15's differential baseline. A sibling overlay function is the cheaper seam |
| Compose base + overlays | `_compose(overlays)` | same (`sc:1342`) | Reuse with its signature intact; the user's document moves out of the list to its own named merge site so provenance is structural (I-11), and the emitted bytes are unchanged by the move |
| The single reader of a `settings.json` key | `_saved_clash_port()` | `bin/sc` (`sc:304-317`) | Copy the **shape** (guarded `load_settings()`, validate, never write) for `_ipv6_setting()`; not the function — it answers a different question about a different key |
| Persist one setting from a command | `cmd_lang()` / `cmd_mode()` | `bin/sc` (`sc:2469-2478`, `sc:2219-2228`) | Reuse the pattern verbatim: lower-case, validate, `load_settings` → assign → `save_settings`, print `X → {val}` |
| Act only when something really changed | T-10's `sc update-rules` and its `MainPID`/`ActiveEnterTimestamp` witness | `bin/sc`, `.harness/insight-index.md:12` | Reuse the principle and the witness for FR-5/AC-13 |
| A pure judge with one definition and several callers | `_valid_selection()` / `_auto_group_emitted()` (T-15) | `bin/sc` (`sc:1355-1396`) | Reuse the **shape** for `ipv6_decision()`: total, single definition, callers never re-derive |
| Keep a rule alive on a host with no rule-sets | `_filter_rules()`'s "no `rule_set` key → kept unconditionally" branch | `bin/sc` (`sc:879-881`) | Reuse by construction: the suppression rule carries no `rule_set`, so FR-12 needs no code at all |
| Keep sing-box's own DNS dial off the proxy | `route.rules[0]` `{"outbound": "direct", "process_name": ["sing-box"]}` | `bin/sc:1121` | Reuse as-is — it is what makes `direct_dns` node-independent in **every** clash mode, and the reason I-17's class survives `global` |
| Warning to stderr, one line | `_warn_degraded()` / `_warn_drift()` and the `"⚠️  " + t(...) + "\n"` idiom | `bin/sc` | Reuse for the FR-7 and BC-9 lines |
| Foreign text made output-safe | `_plain()` | `bin/sc` `# doctor` | Reuse at the `{err}` print site, as `save_nodes()` already does |
| Terminate with one translated line | `sys.exit(t(...))` | `bin/sc` (`save_nodes`, `cmd_reload`, `cmd_lang`) | Reuse for the bad-argument path and for `Reload failed` |
| Regenerate and apply | `reload_or_restart()` | `bin/sc` (`sc:1616-1620`) | Reuse as-is from `cmd_ipv6()` |
| Read the host's IPv6 addresses | (none found — `bin/sc` contains no IPv6 code at all; `sc status`'s `ip addr show` is a subprocess for display only) | — | New, and deliberately a file read rather than a subprocess: `sc doctor` already established that a diagnostic must not depend on an external tool being present, and `IF_INET6_PATH` is repointable so AC-16/AC-17 can be driven without root |
| A DNS failover primitive | (none found, and now measured absent: no fallback transport, no fall-through in the rule chain, `final` is the no-match default only) | — | **Not available at any level.** Nothing is invented in its place; the design states the limit instead (I-16, K-16, RS-9) |
| A per-query DNS wait | (measured absent — `timeout` is not a field of a DNS server, the `dns` block or a DNS rule) | — | Not available; no key is emitted and no constant is defined (K-17) |

## 2. Risks and mitigations

| # | Risk | Mitigation |
|---|---|---|
| R-1 | **The node-independent class is not what I-17 claims**, because the matcher-less `hosts_dns` rule (`sc:1098`) terminates the chain for every name rather than only for names its table holds — in which case rules `[2]`…`[7]` are dead and the class is wrong. | The field measurement already excludes it: at HEAD the `query_type` rule sits at index 3 and the hand-patch to it took an AAAA query from 10.0 s to 0.016 s, which is impossible unless the chain continues past rule 0. V-26 and V-32 observe the class directly per name and per mode, so a wrong claim is caught before delivery rather than shipped in a README. |
| R-2 | **The `$prepend` changes which component answers types 64/65 in `global`/`direct` mode** (HEAD sends them to `remote_dns` there; the candidate answers them locally), and a probe that used those types would read as an FR-11 violation. | Q-4 sanctions exactly this consequence, and no name is disclosed to a *non-proxied* resolver — the rule answers in-process. I-17 states the exception; V-32 probes with type A so AC-B7 measures the property FR-11 actually asserts. |
| R-3 | **The 100 ms bound is measured against the public internet** (`direct_dns` is 119.29.29.29 in the real document), making AC-B1…AC-B3 flaky and the number meaningless. | K-14 makes both servers local stubs and stages every node state at the `proxy` outbound. The bound then measures the document, not the network. |
| R-4 | **The behavioural fixture silently does nothing** — a `direct` inbound without `{"action": "sniff"}` forwards the DNS packet to itself in a loop, and a fixture without `route.default_domain_resolver` fails `check` — and stage 4/6 spend a day on it, as the probe did. | K-15 makes both prerequisites binding and the `## Verification plan` preamble carries the working submission recipe (`direct` inbound on loopback + sniff + `hijack-dns`, driven with `dig @127.0.0.1 -p <port>`). |
| R-5 | **A defect-reproducing control reproduces nothing** because its probe name is domestic — at HEAD that name reaches `direct_dns` and never stalls. | The plan's preamble makes the probe-name rule explicit: a defect control's name must be one HEAD routes to `remote_dns`. RS-10 records the one place the AC text itself gets this wrong. |
| R-6 | **`sing-box check` rejects something this design emits**, and `sc reload` fails on every host. | The only key this task emits is the `predefined`/`rcode`/`query_type` trio the shipped document already carries in production, moved to a different index. V-7 runs the real binary over six states, and V-3 proves nothing else in the document moved. |
| R-7 | **The IPv6 predicate answers "yes" on this very host** because a link-local address sits on `sb-tun`. | FR-6's predicate is address-based (`2000::/3`) *and* device-excluding; V-17's third fixture is exactly a `2000::/3` address on `sb-tun` alone and must answer "no global IPv6". |
| R-8 | **The two `ipv6_decision()` calls in the set path emit a duplicate stderr warning** on a host whose `/proc/net/if_inet6` is unreadable and whose setting is already `auto`. | Accepted, and stated: the second call happens after the write, so the BC-9 warning cannot repeat; only the FR-7 line can, and only on a host that is already broken. The alternative — a second entry point taking the setting — would create the second definition AC-6 forbids. |
| R-9 | **The provenance fix is forgotten at one of the two sites**, and an `sc`-authored failure blames the user again. | K-7 makes it structural (two named call sites, default `None`), and V-23 injects a fault into `_dns_overlay()` with and without a user override present. |
| R-10 | **A freeze check written with `grep` passes vacuously** because `timeout=3` is a prefix of `timeout=30`. | K-11 mandates `ast` extraction; V-9 is written that way. |
| R-11 | **The harness writes to the real system** — the failure mode this project has already had once (`.harness/insight-index.md:10`, `:19`). | The `docs/dev-map.md` recipe verbatim, eight repointed paths **asserted** inside the temp root, `_init_files()` never driven, `SB_BIN` repointed rather than `PATH`-shadowed. |
| R-12 | **The delivered feature is described as more than it is** — a README sentence, a changelog line or a later task reading `dns.final` as a fallback, which would make a user trust name resolution that cannot survive a hung node. | K-16 forbids the claim in every user-facing surface, I-16 states what `final` is in the contract itself, V-21 greps both READMEs for it, and RS-9 carries the shortfall to delivery as a filed row instead of leaving it implicit in a green report. |

## 3. What the measurements settled, and what they did not

Measured against the real `sing-box 1.13.15`, read-only, live service witnessed untouched (the raw output
is in `PM_LOG.md`; `01_RATIONALE.md` E-10…E-13 carries the analyst's reading of it):

- `"timeout": "4s"` is rejected on a DNS server, at the `dns` block level and on a DNS rule, with a
  bogus-key control rejected identically — so the decoder rejects unknown fields and `timeout` genuinely
  is not one of those objects' fields. The design therefore emits no wait and defines no constant.
- The rule chain never falls through on failure, on `NXDOMAIN` or on `SERVFAIL`; `dns.final` is reached
  only when no rule matches. So a catch-all rule plus a re-pointed `final` is a no-op on the failure path
  and an unconditional re-route on the healthy path — the worst of both, which is why neither is in this
  design.
- The 10.0 s is sing-box's own per-query deadline, is not configurable, and the query is dropped silently
  at expiry.

**Not established, and claimed nowhere in the design:** that no *other* key name bounds a DNS query (only
that `timeout` is not it, in three positions); where the 10.0 s constant lives; and that a detoured DoH
server behaves identically to the plain-UDP path that was measured. Nothing in the contract depends on any
of the three: the design emits no wait at all, so a hypothetical unknown key would be an *addition* a
later task could make, not a correction to anything asserted here.

## 4. Options considered and rejected

**Add `28` to the existing `query_type` rule where it sits** (the shape of this host's `sed` hand-patch,
and the smallest possible diff). Rejected by FR-2/Q-4: the rule sits after both `clash_mode` rules, so the
stall survives in `global` and `direct` — the modes people switch to *because* something is broken. Moving
the one rule to index 0 and varying only its list is what makes the suppressed class both node-independent
and mode-independent, and index 0 is the *only* position that achieves it.

**An always-true catch-all rule plus `final: direct_dns`** (the FR-8 shape this design carried before the
measurement). Rejected on measurement: with a catch-all in place `final` is structurally unreachable, so
the construction delivers nothing on the failure path while *reading* like a guarantee — and without the
catch-all, `final: direct_dns` hands every foreign name to a domestic resolver on every healthy host,
permanently. Q-17 rules the same way from the requirement side; K-13 and I-16 make the prohibition
checkable rather than tacit.

**Keep the rule in `CONFIG_BASE` and vary it with `$replace` on `dns.rules`.** Rejected: `$replace` takes
the whole array, so the overlay would have to restate seven static rules — a second definition of the DNS
rule list living in a function, i.e. exactly the literal FR-13/AC-10 forbid. Deleting the base element and
`$prepend`ing the one state-dependent rule leaves each rule with one home.

**Insert the suppression rule with `$after` anchored on the `hosts_dns` rule** (position 1 instead of 0).
Rejected on two counts: an anchor is a failure mode (`_anchor_index` raises when the base changes and the
match count moves off 1) where `$prepend` has none, and index 0 additionally answers AAAA for the six
`hosts_dns` names instantly instead of letting them traverse the chain. Nothing depends on `hosts_dns`
being consulted first: `remote_dns`'s bootstrap uses the server-level `domain_resolver` (`sc:1084`).

**`connect_timeout` on `remote_dns`.** Rejected on mechanism, not on schema: it is a **dial** field and
BC-2's hang is after the dial returns (the node accepts the TCP connection; the handshake above it never
completes), so a dial-level bound cannot see it. The document would pass `check` and do nothing — the
silent-wrong-result class T-14's discriminator rejects.

**Raise `log.level` so the abandoned query is at least recorded.** Rejected: the `log` region is outside
this task's edit surface (out-of-scope item 15), the level at which that line is recorded is not
established, and Q-19 already ruled that the honest response to a silent drop is a documented limit rather
than a new signal that may be pure noise.

**A second sing-box, a health-check daemon, or regenerating on an IPv6 state change.** Rejected as
out-of-scope items 10/12 and, more fundamentally, as a second opinion about a judgment `sc ipv6` already
owns (Q-11).

**`sc dns ipv6 …` / `sc aaaa …` / localized values.** Rejected in Q-12 and not re-litigated here.

## 5. The deletion test on `_dns_overlay()`

Deleting it does not make the complexity vanish — it reappears at every caller of `generate_config()` as
"which `query_type` list does this run emit", and at every test as a reason to reach past the seam. One
function with a zero-argument signature stands between a host-capability judgment and a document key, and
it is the only place the two meet; `ipv6_decision()` sits behind it as the only place the judgment is
made, with two callers that never re-derive it. That is the whole interface: two functions, no arguments,
one document key. The suppression behaviour, the three settings values, the detection failure mode and the
mode-independence all sit behind it.

## 6. Where the two through-lines landed

- **Failures must be loud.** FR-7's assumption is stated on stderr at every decision point, including
  during `sc reload`; BC-9 names file, key and accepted values; I-12 stops `sc` blaming the user's file
  for `sc`'s own overlay. Where the through-line **cannot** reach — sing-box abandoning a query at 10 s
  with no `sc` process alive to speak — the design's obligation inverts into K-16: claim nothing that is
  not there, in any user-facing surface, and file the shortfall (RS-9) rather than letting a green test
  report imply the goal was met. A design that quietly narrowed the promise would be the same defect as a
  silent failure.
- **A generated artifact must leave room for the user.** `sc ipv6 on|off` overrides the tool's judgment
  permanently; the user's `override.json` is still the last word (BC-15) and now the only document `sc`
  blames when it really is at fault.
