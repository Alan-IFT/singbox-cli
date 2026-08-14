# 01 — Rationale · T-17 `telemetry-reject-list`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## Related-task survey

Contract portions read in full; rationale siblings opened only where noted. Linked, not re-described.

| Task | Doc | What it binds here |
|---|---|---|
| T-14 `config-composition-layer` | `docs/features/_archived/config-composition-layer/01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md` | The layer FR-10 makes binding. D-7 (anchor, never a numeric index) is why FR-9's anchors are objects; D-5/D-6 are why a bare array at `dns.rules` is loud; O-12 filed R-16 with the ownership clause Q-1 answers. |
| T-15 `proxy-urltest-group` | `docs/features/_archived/proxy-urltest-group/01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md` | The overlay idiom (FR-8/FR-9 there), D-12's decline of R-16, D-13's English-sentence key rule, and R-22 — the reason AC-B1…AC-B7 exist at all. |
| T-16 `dns-resilience` | `docs/features/_archived/dns-resilience/01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`, `06_TEST_REPORT.md` | The rule this task must not contradict: I-17's emitted order, Q-5's rcode reasoning, Q-13's deliberate silence about T-17's slot, V-5's proof that both anchors still match exactly one element, Q-1's own R-16 ruling, and the measured DNS facts behind out-of-scope item 8. |
| Open rows | `docs/tasks.md` | R-16 (Q-1), R-22 (AC-B series, NFR-8), R-23 (out-of-scope 8), R-24 (Q-9), R-25 (BC-5), R-9 (out-of-scope 10). |
| Rejected decisions | `.harness/rejected-decisions.md` § `override-as-confd-fragment-directory` | States that T-15/T-16/T-17 ship their overlays as code inside `bin/sc`; FR-10 keeps that. No prior decline matches this request. |

## Evidence

Backward-looking, verified in the working tree at `1e454b6` plus the T-16 delivery on top.

- `bin/sc:1134-1147` — `CONFIG_BASE["dns"]["rules"]`: seven elements, with the comment at `:1138-1141`
  recording that the suppressed-query-type rule left this array and is emitted at index 0 by
  `_dns_overlay()`. This is the array T-17 inserts into and the order FR-4 reasons about.
- `bin/sc:1562-1583` — `_dns_overlay()`: `$prepend` on `dns.rules`, one rule, no anchor. The idiom FR-10
  points at, and the rule FR-11 freezes.
- `bin/sc:1089` — `DIRECTIVES`, five members, with the comment at `:1084-1088` stating that
  `$before`/`$after` take an anchor rather than an index *because* two overlays into `dns.rules` would
  otherwise collide. T-17 is the second of those two overlays; the comment is now discharged.
- `bin/sc:1222-1242` — `_anchor_index()`: subset equality, and zero or several matches is an error, never
  a silent no-op. This is what makes AC-3's "exactly one element" a hard property rather than a hope.
- `bin/sc:1292-1315` — `_merge()`: a dict value at a key whose target is a **list** is deep-copied over it
  (`:1297-1300`), which is R-16's silent replacement. `bin/sc:1778-1782` — `generate_config()`'s three-key
  guard raises `at dns.rules: this must stay an array` before any write, which is why the silence R-16
  names does not exist at T-17's one surface (Q-1a).
- `bin/sc:895-909` — `_filter_rules()`: a rule with no `rule_set` key is kept unconditionally. FR-5 rests
  on this, exactly as T-16's I-7 did.
- `bin/sc:1765-1771` — `generate_config()` composes `sc`'s overlays first and merges the user's document
  last through the one `_merge()`. FR-9's recipes are user-document merges and therefore apply after the
  shipped reject rule exists, which is what makes both anchors resolvable.
- `docs/features/_archived/dns-resilience/06_TEST_REPORT.md:82` — QA's V-5 line
  (`clash@[2,3] remote@[2,4] n=8` and `clash@[2,3] remote@[2] n=5`), measured in both rule-set states:
  each `clash_mode` anchor matches exactly one element in both. FR-9 and AC-3 are extensions of an
  already-measured property, not new hope.
- `docs/features/_archived/dns-resilience/06_TEST_REPORT.md:73-79` — the AAAA runs: candidate `19.7 ms`
  against a HEAD control logging `[10.0s] … context deadline exceeded`. The 100 ms bound in FR-3 is the
  same bound that suite already met on this hardware with the same fixture shape, so it is a measured
  budget rather than a guess.
- `.harness/insight-index.md:24-26,30` — the four DNS facts out-of-scope item 8 and NFR-7 are built on.

## Why the goal sentence is satisfiable as data plus a toggle

Counting the change against FR-10's envelope, before any design exists: one name list (data), one
function returning the effective setting, one overlay function, one `cmd_telemetry()`, one settings key,
six strings, one help row, two README sections. Every one of those has a shipped precedent one task old.
The only genuinely new *decision* is the insertion anchor, and T-14 built the anchor vocabulary for
exactly this insertion. If a design grows past this list, FR-10's last sentence forces it to name the
behaviour the two layers below cannot express — the same discipline T-16's FR-13/RS-1 ran, which
correctly reported "nothing" for the composition layer and located the real shortfall one level down in
the binary.

## Candidates each question beat

### Q-2 / Q-3 — what the list is

Candidates: (a) a `geosite` category shipped as a fifth `.srs`; (b) a curated literal list in `bin/sc`;
(c) both, with the category as the bulk and the literal list as a supplement; (d) a user-supplied list
file with an empty default.

(a) and (c) lose on three independent grounds, any one of them sufficient: a `rule_set`-referencing DNS
rule is deleted by `_filter_rules` on a degraded host, so the feature would disappear on exactly the
host whose owner is least equipped to notice; a fifth rule-set adds a download, a digest, a degradation
state, an update path and a `verify_all`-visible surface, which is the new machinery the goal forbids;
and an ads/tracking category admits tens of thousands of names selected by somebody else's criterion,
which cannot satisfy FR-1's second clause name by name and therefore cannot satisfy the through-line
that a generated artifact must not carry an opaque blocklist. (d) is not the requested feature: an
opt-out list with an empty default is opt-in with extra steps, and it moves the whole selection problem
onto the user.

(b) wins, bounded at 24 names so the list stays auditable in one screen — the number is the point at
which `sc telemetry show`'s output stops being readable in one terminal page, and it is comfortably
above what FR-2's four classes need.

**Candidate members considered**, for stage 2 to evidence, accept or drop under FR-1 — this list is
non-binding and deliberately errs toward names whose only documented role is measurement:
desktop-OS diagnostics (`*.telemetry.microsoft.com`, `vortex.data.microsoft.com`,
`watson.telemetry.microsoft.com`); browser telemetry (`incoming.telemetry.mozilla.org`,
`telemetry-coverage.mozilla.org`); global analytics/crash SDKs (`google-analytics.com`,
`app-measurement.com`, `crashlytics.com`, `demdex.net`); domestic analytics SDKs (`hm.baidu.com`,
`mmstat.com`, `umeng.com`, `umengcloud.com`, `talkingdata.com`, `sa.xiaomi.com`, `tracking.miui.com`,
`pingma.qq.com`).

**Names named as excluded**, as worked examples of FR-1's second clause rather than as claims about a
vendor: `settings-win.data.microsoft.com` (carries settings/update policy alongside diagnostics),
`googletagmanager.com` (sites gate content on it), `connect.facebook.net` (login widgets),
`mtalk.google.com` and Apple's push endpoints (message delivery), safe-browsing endpoints (a security
feature), `nexusrules.officeapps.live.com` (Office policy retrieval). A stage-2 membership proposal that
includes any of these must argue against this paragraph explicitly.

Sources the enumeration should be evidenced against, in preference order: the vendor's own
documentation of the endpoint; the endpoint's presence in the vendor's published telemetry
configuration; and, last and only as corroboration, a widely used public blocklist. "It is on a
blocklist" alone does not satisfy FR-1 — that is precisely how a functional endpoint gets into a
shipped artifact.

### Q-4 / Q-5 — what "reject" returns

Candidates: `NXDOMAIN`; empty `NOERROR`; `REFUSED`; sinkhole to `0.0.0.0`/`127.0.0.1`; drop.

Drop is eliminated by the loudness through-line: it is byte-for-byte the user experience of the 10 s
deadline T-16 measured, so the tool would ship a second thing indistinguishable from a broken network.
Sinkhole moves the failure to a connection attempt against the user's own host, which is later, less
legible and occasionally routed oddly under TUN. `REFUSED` is a resolver-policy answer that some stub
resolvers retry against a second server, and this project's document has no second server (T-16 Q-14).
Empty `NOERROR` is what T-16 chose for a *query type* denial and is wrong for a *name* denial, because
it says "this name exists, just not with this record", which invites A/AAAA retries and leaves the name
resolvable for other types. `NXDOMAIN` says what is meant, covers the whole name, and fails clients
fast.

**PM amendment at delivery, per gate condition C-7 (finding F-11).** The sentence above originally
read "is cached negatively for the whole name". That clause asserted downstream **client** caching
which the PM-commissioned probe **did not measure** — and F-11's point was precisely that RS-2 named
only the contract's Q-5, so amending Q-5 alone would have archived this copy intact. What *was*
measured: the reply carries `AUTHORITY: 0` and **no SOA record**, so under RFC 2308 a downstream
resolver has no MINIMUM from which to derive a negative TTL, and sing-box's own side needs no cache
(the denial costs ~2–7 ms and never leaves the box). The conclusion — `NXDOMAIN` over empty `NOERROR`
— is unchanged and rests on the semantics: this rule denies the **name**, T-16's denies a **type**.
K-12 keeps the caching claim off every shipped surface.

BC-15 exists because none of this is measured against 1.13.15 by this stage: T-16 used
`{"action": "predefined", "rcode": "NOERROR"}`, and that the same action accepts `NXDOMAIN` is a
reasonable reading of the decoder's behaviour, not a probe result. Stage 2 measures it; if it does not
hold, the shortfall is reported rather than papered over with a drop.

### Q-6 — position

Candidates: (a) after both `clash_mode` rules, before the routing rules — the field report's stated
constraint, the slot T-14 and T-16 preserved; (b) before both `clash_mode` rules, after the
predefined-hosts rule; (c) at index 0, before T-16's suppression rule.

(c) is out on FR-11 and on BC-11's mechanism: shadowing `sc`'s own DoH bootstrap names would be
reachable the moment a user extends the list, and T-16's rule is deliberately first.

(a) versus (b) is the real call, and it is a semantics argument, not a preference. The emitted
`dns.rules` array has two kinds of member: rules that *answer the query here* (T-16's suppression rule;
the predefined-hosts rule; this task's reject rule) and rules that *choose which resolver answers it*
(the two `clash_mode` rules, the rule-set rules, the domestic suffix rule). `clash_mode` is a live user
instruction about *path*, not about *whether*. Interleaving the two kinds is what produced T-16's actual
defect — a query-type answer sitting after the `clash_mode` rules and therefore silently absent in the
two modes people switch to when something is already broken, which QA's ADV-2 measured rather than
argued. Adopting (a) would reproduce that shape one task later with a privacy decision instead of an
IPv6 one: `sc mode global` would silently un-block every telemetry name, and nothing in the tool would
say so.

The honest cost of (b), recorded so the gate can weigh it: the field report's stated constraint is
overruled, and switching routing mode is no longer an escape hatch for an application broken by the
list. The second half is the reason BC-14, Q-11 and FR-12 exist — an escape hatch nobody documented is
not an escape hatch, and the two this task documents are better ones because neither of them also
re-routes all of the user's traffic as a side effect.

### Q-7 — the toggle's surface

Candidates for the command: `sc telemetry <value>`; `sc reject-telemetry on|off`; a `--no-telemetry`
flag on `sc reload`; a `settings.json` key with no command.

The flag dies because the setting must persist across regenerations; a key with no command dies because
`sc` owns `settings.json` and the project has never asked a user to hand-edit it. `reject-telemetry`
reads as a verb where every existing subcommand is a noun (`lang`, `mode`, `ipv6`, `default-tun`).

Candidates for the values: `on|off`; `block|allow`; `on|off|show` with the feature named in the help
text. `on|off` loses on the inversion: with a subject noun, `sc telemetry off` is exactly as readable as
"turn telemetry off" (block) and "turn this feature off" (allow), and the two readings produce opposite
traffic. A silently-opposite outcome for a plausible reading is the failure class this project treats as
worst; `block|allow` cannot be read backwards, and a user who types `on` gets a loud line naming the
three accepted values rather than a guess. The accepted cost is a family split with
`sc ipv6 on|off|auto|show` and `sc default-tun on|off`; those name a capability, not a subject, so the
inversion does not arise there.

Default `block`: the goal sentence says opt-out. The behaviour change on upgrade is real and is handled
the way this project has handled every other one — changelog, both READMEs, and a `show` form that
states the current state — rather than with a first-run notice, which would need persisted "have I told
you yet" state and is the machinery the goal forbids (out-of-scope item 9).

### Q-9 — the no-op line

T-16 shipped `Nothing changed — the sing-box service was not touched` and QA filed R-24 against it: the
line appears at the moment the user is most likely to be sitting in front of a stale document, and names
no escape. T-17 cannot inherit that line unchanged without inheriting the row. The fix here is cheap
because T-17's state has no host-derived input: the only stale-document case is "the running document
predates the setting", and one added clause naming `sc reload` covers it exactly. That is a string, not
a mechanism, so it does not widen scope, and it makes no claim about `sc ipv6`, whose stale case is
harder (two decisions computed from the current host, neither read back from disk).

### Q-10 — the shape of user extension

Candidates: (a) a second user rule inserted before the `clash_mode: Global` rule; (b) extending the
shipped rule's name array in place; (c) a user-owned names file `sc` reads and concatenates.

(b) is not expressible: reaching a nested array inside an array *element* needs element addressing, and
T-14's documented boundary is explicit that an object keyed `"0"` does not address element 0. This is
also the sharpest reason Q-1 declines R-16 — R-16's vocabulary is about a bare object replacing an
array at a merge position, which would not help here even if it existed. (c) is a second override
mechanism beside `override.json`, i.e. the duplicated-judgment seam rule 85 forbids, and it would need
its own malformed-input model, size limit and symlink ruling — T-14 built all of that once already.

(a) costs the user four lines of JSON, works in both settings states, and is verified end-to-end by
AC-18 and AC-B6 rather than asserted in a README nobody ran. The per-name exception (BC-7) falls out of
the same mechanism because the DNS chain matches in order: a rule placed before the reject rule wins,
which is why the exception recipe anchors on the reject rule itself while the addition recipe anchors on
a rule `sc` emits unconditionally.

### Q-12 — the overlap with T-16

Worth stating because it is the one place a reader could see a contradiction: for a listed name, an AAAA
query under suppression returns empty `NOERROR` while an A query returns `NXDOMAIN`. Two different
rcodes for one name looks wrong until you notice both are immediate, neither queries upstream, and the
user-visible outcome — no address, no delay, no leak — is identical. The alternative (reordering so the
reject rule precedes suppression) would put a name-scoped rule ahead of a type-scoped one and reopen
T-16's mode-independence argument for no gain. BC-10 states the outcome so QA does not file it.

## R-22 discipline, restated as this task's own risk

T-15 shipped 35 green criteria and a promise wider than the behaviour, because every criterion read the
artifact. The artifact-only version of this task would be: "the emitted document contains a rule with
these 24 names" — which would stay green if the rule sat where sing-box never reaches it, if the rcode
were one the binary silently ignores, if `_filter_rules` deleted it on a degraded host, or if the
`clash_mode` rules captured the query first. All four of those are reachable failures of *this specific
design*, which is why AC-B1…AC-B6 observe the resolver and AC-B7 requires a classified control. The
non-vacuity trap T-16's ADV-1 caught applies here in mirror image: a fixture that cannot resolve
*anything* would make every rejection look green, so AC-B3 (the `allow` run resolving the same name
through a stub) doubles as the proof that the rig can observe a success.

## Residuals travelling to the PM

- **Glossary (`CONTEXT.md`, outside NFR-3's permitted diff).** Two terms this task coins:
  **telemetry reject list** — the fixed set of names `sc` answers locally with "no such domain",
  emitted as one DNS rule and switched by one setting; _Avoid_: blocklist, adblock, filter list.
  **reject rule** — the single emitted `dns.rules` element carrying that list, and the anchor object
  both READMEs publish for it; _Avoid_: block rule, deny rule.
- **`.harness/rejected-decisions.md` (same exclusion).** Three records this analysis would file:
  `telemetry-list-as-geosite-ruleset` (Q-3), `telemetry-toggle-as-on-off` (Q-7),
  `telemetry-reject-by-dropping-the-query` (Q-4).
- **R-16 stays open and unclaimed** after a third independent ruling (T-15 D-12, T-16 Q-1, T-17 Q-1).
  Q-1(c) adds a fact the earlier two did not have: for the extension case, R-16's vocabulary would not
  have helped, because the missing capability is element addressing. Whoever eventually owns R-16 should
  read that clause before scoping it.
