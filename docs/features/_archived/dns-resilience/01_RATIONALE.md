# 01 — Rationale · T-16 `dns-resilience`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## 1. Evidence, read at the source

Backward-looking citations, verified in the working tree at `1e454b6` and against the installed
binary. Requirement prose deliberately carries none of these anchors.

**E-1 — the DNS region as it stands.** `bin/sc:1081-1110`, inside `CONFIG_BASE`: four keys only —
`servers` (5 entries: `local_local` udp 119.29.29.29, `remote_dns` DoH `cloudflare-dns.com` with
`detour: proxy`, `direct_dns` udp 119.29.29.29, a `hosts` server `hosts_dns`), `rules` (8 entries),
`final: remote_dns`, `independent_cache: True`. **No wait of any kind is emitted anywhere in it** —
that is the whole factual basis of Q-2. The rule order is: `hosts_dns` (`ip_accept_any`) ·
`clash_mode: Global` → `remote_dns` · `clash_mode: Direct` → `direct_dns` · `predefined NOERROR
query_type [64, 65]` · four rule-set/suffix rules · then `final`.

**E-2 — the repository does not carry the hand-patch.** `bin/sc:1101` reads `"query_type": [64, 65]`.
The installed `/usr/local/bin/sc` carries `[28, 64, 65]` from the 2026-08-01 `sed`. `install.sh`
rewrites the installed file, so the patch dies at the next install with no warning — BC-17.

**E-3 — this host has no global IPv6.** `/proc/net/if_inet6` holds 7 entries: six `fe80::/10`
link-local (`veth2ea63d2`, `br-f6dfc9970942`, `br-03a0c8b0ebdf`, **`sb-tun`**, `enp3s0`, `docker0`)
and `::1` on `lo`. Two consequences: `auto` suppresses here, so the shipped default reproduces the
hand-patch's effect (Q-10); and a naive "does any IPv6 address exist" test answers **yes** on this
host — one of the link-local addresses is on the project's own TUN device — which is why FR-6 names
`2000::/3` and excludes the TUN device explicitly (BC-6).

**E-4 — sing-box 1.13.15 has no DNS fallback transport.** Path-table probes of
`/usr/local/bin/sing-box` (the technique T-10 used for `route/rule/rule_set_local.go`):
`dns/transport/` → 5 hits, `dns/transport/local|hosts|udp` → 4, `dns/transport/fallback.go` → **0**.
`fallback.go` exists once in the binary but not under `dns/transport/`. So "add a fallback resolver"
cannot mean "declare a failover server"; hence Q-14, and hence FR-8 is written as *which resolver
answers which class of names*, which is expressible with the rule engine that does exist.

**E-5 — the only wait this binary certainly accepts cannot reach the hang.** `json:"connect_timeout`
→ 2 hits, both inside a dial-fields struct; `json:"query_timeout`, `json:"dns_timeout` and
`json:"exchange_timeout` → 0 each; the single `json:"timeout,omitempty"` sits among inbound/sniffer
strings. `connect_timeout` is a **dial** field and BC-2's hang is *after* the dial returns (the node
accepts the TCP connection; the DoH TLS handshake is what never completes), so no dial-level bound
can see it. This is superseded as a design lead by E-10, which measured the question directly.

**E-6 — the measurement this task inherits.** The second field report, two production hosts, Ubuntu
24.04, pure TUN: an AAAA query cost **10.0 s** and, after the `query_type` patch, **0.016 s**. Both
numbers are quoted in `docs/batches/default/BATCH_PLAN.md`. E-11 identifies the 10.0 s: it is
sing-box's own per-query deadline, and the field number is corroborated rather than coincidental.

**E-10 — no DNS-query-level `timeout` exists in this build.** Measured with the real
`sing-box 1.13.15` (`Revision 3708fa18766c`), read-only, live service witnessed untouched throughout.
`sing-box check` rejects `"timeout": "4s"` on `remote_dns` (`dns.servers[1].timeout: json: unknown
field "timeout"`), on `direct_dns`, at the `dns` block level and on a DNS rule; a **bogus-key control**
on the same four objects is rejected with the identical error shape, and the base fixture — byte-
identical to `CONFIG_BASE`'s DNS section — is accepted with exit 0. The control is what makes the
result informative: the decoder rejects unknown fields, so the rejection proves the field does not
exist rather than that it was ignored. Deliberately **not** established, and therefore claimed
nowhere: that no *other* key name bounds a DNS query.

**E-11 — the 10.0 s is sing-box's own per-query deadline, and it drops the query.** sing-box logged
`dns: exchange failed …: context deadline exceeded` stamped `[10.0s]`, reproducibly across three runs
at two different client timeouts. At the deadline it does not answer, does not retry and does not
consult another server — it stops, silently. This is Q-2's answer and it is the reason FR-9 promises
a bound the document does not worsen instead of a number the document cannot carry.

**E-12 — the DNS rule chain never falls through on failure.** A fixture with an always-true last rule
(`{"server": "remote_dns", "domain_regex": [".*"]}`) and `final: direct_dns`, two local stub
resolvers, non-vacuity proved by sing-box's own trace: remote answers → remote stub only, 0.018 s;
remote `NXDOMAIN` → remote stub only, relayed verbatim, 0.017 s; remote `SERVFAIL` → remote stub
only, relayed, 0.007 s; **remote accepts and never answers → the direct stub is never consulted**,
30.046 s (the client's own limit), `no servers could be reached`, sing-box having sent nothing. Two
consequences: an always-true catch-all makes `final` structurally unreachable, and the privacy leak
an eager fall-through would have caused does not exist in this build.

**E-13 — `dns.final` is the no-rule-matched routing default.** Control on the same fixture with the
rule changed so nothing matches: the direct stub received the query in 0.006 s. So `final` is reached
only when the rule chain produces no match — never as a failure fallback. Together with E-12 this is
why FR-8 is a statement about *static assignment* and why Q-17's conflict is real rather than
resolvable by mechanism.

**E-7 — the failure `urltest` cannot fix.** `.harness/insight-index.md:27` (measured by T-15's QA
over 440 s, three runs): a member that accepts the connection and never answers is **never**
demoted. T-15 made DNS follow a healthy node, and that is real, but it does not cover this state —
which is why BC-2 is T-16's primary case rather than an edge.

**E-8 — the degraded-config trap.** `generate_config()` runs `_filter_rules` over `dns.rules` with
the rule-set tags the composed document defines, so on a host where all four `.srs` are unusable
every rule-set-referencing DNS rule is deleted and **everything** falls through to
`final: remote_dns`, i.e. through the proxy. That is the original batch incident's own state, which
makes BC-4 the intersection of the two failures rather than a hypothetical, and it is why FR-12
forbids the new rules from carrying a `rule_set` key.

**E-9 — the overlay error message names the wrong file.** `bin/sc:2664-2676`: `main()`'s
`OverrideError` handler renders `Cannot use {path}` with `OVERRIDE_PATH` unconditionally, and its
comment says outright that a later task shipping a content overlay that can raise must revisit the
line. T-16 is that task, which is FR-14.

## 2. Related historical work

Linked, not re-described.

| Task / row | Why it is load-bearing here |
|---|---|
| **T-14** `config-composition-layer` — `docs/features/_archived/config-composition-layer/02_SOLUTION_DESIGN.md` | The layer FR-13 makes binding: `CONFIG_BASE` + `_runtime_overlay()` + `override.json` through one `_merge()` with five directives. `01 §12.4` carries the R-15/R-16 rulings Q-1 answers for T-16. |
| **T-15** `proxy-urltest-group` — `docs/features/_archived/proxy-urltest-group/01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md` | The overlay idiom to follow (existing directive, array the base already defines, no outbound literal in `generate_config()`), its NG-2 which reserved DNS for this task, and its BC-12/AC-15 evidence that the probe FQDN is not resolved by a server this project runs. |
| **R-22** (`docs/tasks.md:240-249`) | The reason AC-B1 … AC-B10 exist at all, and the reason NFR-7 makes a control run part of the criterion rather than of QA's good judgment. |
| **R-16** (`docs/tasks.md:173-180`) | Ruled on in Q-1; left open. |
| **T-10** `ruleset-update-no-needless-restart` | The precedent Q-9 follows: act on the service only when something really changed, and prove it with the `MainPID`/`ActiveEnterTimestamp` witness. |
| **T-02** `config-degrade-missing-rulesets` | Owns the degradation model E-8 rests on. |
| **T-05** `sc-doctor` | Owns "no second opinion" (Q-11) and the finding that fixtures hide what the real binary rejects (AC-5). |

## 3. Candidates each question beat

**Q-1 (R-16).** *Claim it* was argued seriously, on two grounds: T-16 is the first task to make an
array outside `generate_config()`'s three-key guard (`dns.servers`) a documented user knob, and the
guard is an allow-list that grows one key per task. Both fail on the facts: the guard exists to stop
`sc`'s **own** indexing from raising, T-16 indexes no composed array, and the binary rejects an
object at `dns.servers` before any service-affecting action — T-14's own discriminator ("is the
wrong result silent, or does the binary tell the truth?") still answers *the binary tells the truth*.
Also rejected: *claim only the `"0"`-key half* — it is the same code path, and splitting one merge
judgment across two tasks is the seam rule 85 forbids. What would flip this ruling, recorded so the
next owner does not re-derive it: a task whose own code indexes a composed array not in the guard, or
a measured case where the mismatch yields a document `sing-box check` accepts.

**Q-3 (the budget).** Candidates that assumed the document could state a wait — 2 s, 4 s, 5 s, 8 s —
are all moot: E-10 measured that there is no position at which any of them could be written. The
surviving candidates were *state a budget anyway and let the design find a key* (rejected — E-10's
bogus-key control makes "some other key might work" a hope, not a fact, and a requirement that names
an unmeasured mechanism is exactly what sent this document back), and *state the 10.0 s as the budget*
(rejected — it is not this project's number to promise: it is a constant inside a third-party binary,
so restating it as a requirement would make T-16 fail the day sing-box changes it, while promising the
user nothing new). What is left is the only thing this project controls: **which resolver is asked**,
plus a no-regression bound. That is FR-9's shape.

**Q-17 (FR-8 versus FR-11, for the class matched by no rule).** Candidate: *re-point `final` to
`direct_dns`*. It is the one-line version of the whole feature and it does satisfy FR-8's second
class. Rejected on the balance of harms, measured rather than assumed: the class is the foreign
internet, so the cost is paid **on every healthy host, permanently** — foreign names answered by a
domestic resolver return different addresses and disclose every foreign name queried — while the
benefit is resolution of names whose destinations are unreachable anyway for as long as the node is
down. T-14's discriminator ("is the wrong result silent, or does the failure tell the truth?") is
decisive: a polluted answer is silent and wrong; an unanswered foreign name while the proxy is dead
is a failure the user is already living through. Candidate: *re-point `final` only when the node is
unusable* — rejected because the emitted document is static and E-12 proves nothing observes node
health at query time; there is no such conditional to write. Candidate: *keep the architect's
always-true catch-all as insurance* — rejected as a no-op that reads like a guarantee: E-12 shows it
makes `final` unreachable, so it would encode a promise nobody could keep.

**Q-18 (the degraded rule-set state).** Candidate: *re-point `final` to `direct_dns` only when every
rule-set is unusable* — this is expressible, because `generate_config()` already knows that state at
generation time. Rejected: on a degraded host with a **working** node it turns correct foreign
resolution into polluted foreign resolution, and a degraded host still routes foreign traffic through
the proxy, so the polluted address is what the proxy would dial. It trades a total outage in one
sub-state for a new breakage in another, and the sub-state it fixes is one the tool already warns
about and that `sc update-rules` resolves properly. Candidate: *add a rule-set-free domestic
classifier (a `.cn` suffix rule, say)* — rejected as an invented mechanism: it is a new routing
policy no measurement forces, it approximates `geosite-cn` badly, and inventing one to rescue a
promise is precisely the move this rework exists to undo. The honest outcome is the narrower promise
plus a filed shortfall.

**Q-19 (loudness for a silently dropped query).** Candidate: *raise the emitted `log.level` so the
`context deadline exceeded` line reaches the journal* — rejected twice over: the `log` region is
outside this task's edit surface, and E-11 does not establish at which level that line is recorded,
so the change could be pure noise for no gain. Candidate: *a `sc doctor` DNS-timing row* — T-20 owns
it, and a second opinion is what T-05 exists to prevent. What remains is the obligation not to
overstate: both READMEs state the limit.

**Q-4 (mode independence).** Candidate: keep the existing rule's position (after the `clash_mode`
rules) and add `28` to its list — the smallest possible diff, and the shape of the hand-patch.
Rejected: it leaves the 10 s stall alive in `global` and `direct`, i.e. in the mode a user switches
to *because* something is broken. The cost of the ruling is honest and small: types 64/65 become
suppressed in those two modes as well, which is what the rule already means in `rule` mode.

**Q-6 (the predicate).** Candidates: any IPv6 address (rejected — E-3 shows it answers "yes" on a
host with none, on the strength of the project's own TUN device), a global address **plus** a default
route (rejected — a second query and a second failure mode for a host `sc ipv6 off` already serves),
an outbound reachability probe (rejected — network access inside config generation, which nothing
else in `generate_config()` does).

**Q-7 (detection failure).** Candidate: suppress on failure, on the argument that the reported hosts
are IPv4-only. Rejected: it makes the unknown case break IPv6-only destinations, and the cost of the
other direction is latency the user already has.

**Q-9 (restart policy).** Candidate: always regenerate and restart, mirroring `sc reload`. Rejected
on T-10's measured precedent — a command that frequently changes nothing must not drop every live
connection. Candidate: never restart, print "run `sc reload`". Rejected: it makes `sc ipv6` a command
that does not do what it says.

**Q-12 (naming).** Candidates: `sc dns ipv6 …` (rejected — introduces a two-level subcommand the
CLI has nowhere else), `sc aaaa …` (rejected — names the record type rather than the user's concept),
localized values (rejected — `sc lang` would move a value stored in `settings.json`).

## 4. Observation design behind the [B] criteria

The constraint is hard: the live sing-box service, `/etc/sing-box/` and `/var/lib/sing-box` must be
untouched, and `bin/sc`'s import-time auto-elevate re-execs the **installed** binary — which on this
host additionally carries the hand-patch, so an un-neutralised import measures the wrong build
*and* the wrong config. Everything below is therefore offline and unprivileged.

- **The instance.** A second `sing-box` run as a normal user from a `mkdtemp()` root, its config
  derived from the emitted document with the TUN inbound removed (TUN needs root and would alter
  host routing), its own `cache_file.path`, and a Clash port that is not the live one. T-15's QA
  established this shape and used it to answer BC-12 with a measurement.
- **The hanging node.** A local TCP listener that accepts and never answers, standing in for the
  node outbound. It reproduces E-7's exact state without any foreign server.
- **Which resolver answered.** Local stub DNS servers stand in for the proxied and the non-proxied
  upstreams; the stub that receives a probe name *is* the answer to FR-11 and to AC-B4's "no upstream
  query". This is the same technique that let T-15's QA observe `atyp=3 host=www.gstatic.com` on a
  SOCKS relay instead of inferring it.
- **Driving a query.** The installed binary carries a `tools` command surface (3 hits for
  `synctime|tools fetch|sing-box tools`), which is one candidate driver; any client that provably
  routes the query through the instance is equally acceptable. Non-vacuity is what matters: the run
  must show the query reaching the stub.
- **Two kinds of control, and why the distinction is not a loophole.** Once E-10…E-13 narrowed what
  can be promised, some [B] criteria stopped being "the defect is gone" and became "the guarantee did
  not regress" — AC-B7 above all, which is now the load-bearing one, since Q-17's ruling is only worth
  anything if a test can catch a design that quietly re-points the unmatched class. A no-regression
  criterion cannot take a defect-reproducing control, because at HEAD there is no defect to reproduce;
  it takes an **agreement** control instead, and a run whose control disagrees is as inconclusive as
  one whose defect control stays green. AC-B10 names which criterion takes which, so neither kind can
  be chosen after the fact to suit the result — and the count is itself the honest measure of this
  task's reach: **two** defect-reproducing criteria (both of them the unsuppressed AAAA query — as a
  stall in `rule` and `global` modes, where HEAD sends it to the proxied resolver, and as the plain
  absence of suppression in `direct`, where HEAD answers it from a resolver no node touches), seven
  no-regression criteria.
- **Nothing is downgraded quietly.** If a [B] criterion turns out to be unobservable under these
  constraints, NFR-7 requires it to be reported as inconclusive with the safe proxy named — not
  silently replaced by an artifact check. That substitution is exactly how R-22 happened, and it is
  why the criteria that shrank in the face of E-10…E-13 shrank to *smaller observed behaviour* (a
  100 ms bound on a smaller class of names, an unanswered query observed at two instrumented stubs)
  rather than to a check that the emitted document contains a key.

## 5. Two through-lines, and where each landed

- **Failures must be loud.** FR-7 (detection failure states its assumption), BC-9 (an unrecognised
  persisted value names file, key and accepted values), FR-14 (a failure in `sc`'s own overlay stops
  blaming the user's file), and AC-B10 (a control that does not do its job is reported, not quietly
  accepted). The one place this through-line cannot reach is E-11's silent drop, which happens inside
  sing-box with no `sc` process alive to speak: Q-19 rules that the honest substitute is a documented
  limit and a promise narrowed to what is deliverable — the loudest thing a requirement can do about a
  capability the software lacks is refuse to claim it.
- **A generated artifact must leave room for the user.** FR-3/FR-4 make the IPv6 judgment the user's
  whenever they want it; BC-15 keeps the override's last-word contract intact and says so out loud;
  FR-13 keeps everything on the layer that exists precisely so a user's file survives regeneration.

## 6. Scope pressure declined, with the reason

- **A `sc doctor` DNS-timing section** — T-20 owns it and depends on this row; adding it here creates
  the second opinion T-05 exists to prevent.
- **Fixing the five `ls.*` keys (R-19) while adding new strings** — rule 85's counter-rule; the new
  keys are English sentences instead, which is the `Delay` precedent from T-15.
- **A `dns.servers` entry for the telemetry list, "while we are in here"** — T-17, and it is a
  different judgment (routing policy, not host capability).
- **Making `settings.json` atomic / mode-managed** — NFR-4; it is not a credential document and
  nobody asked.
- **A requirement that `sc ipv6` announce the stale-document repair path at the moment it says
  "nothing changed"** — BC-13 states the behaviour and the escape, and that is the whole of what this
  task carries. The candidates were (a) a new FR plus a criterion, (b) a README sentence, (c) the
  boundary correction alone. (a) and (b) both require a code or document change that is authorised by
  nothing, and a contract line with neither an implementation nor a criterion behind it is the
  over-claim NFR-7 exists to prevent; the escape itself already exists and works, so what is missing is
  a *prompt*, not a capability. (c) it is — the gap between "the escape exists" and "the user is told
  it at the moment they need it" is a candidate for a later task, not a line this delivered contract
  may promise.
