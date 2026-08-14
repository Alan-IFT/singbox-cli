# 01 — Requirement Analysis · T-16 `dns-resilience`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

One unusable node stops taking name resolution down with it as far as a static DNS configuration can:
query types the host cannot use are answered immediately instead of stalling, the classes of names that
already resolve without a node keep doing so in every rule-set state, and no name changes which resolver
answers it — all expressed as composition on T-14's layer, with the IPv6 half under a user-controllable
setting. Names whose only resolver is reached through a node outbound stay dependent on that node; no
configuration this project emits changes that in sing-box 1.13.15 (Q-2, Q-17), and the task states that
limit rather than covering it.

## In-scope behaviors

**FR-1** — Whenever AAAA suppression is in effect, the emitted `config.json` answers every AAAA
query (DNS type 28) with an empty `NOERROR` response: no records, no error rcode, no upstream query.

**FR-2** — AAAA suppression is in effect in every routing mode, `rule`, `global` and `direct` alike.
The rule that carries it is evaluated before both `clash_mode` DNS rules and before every DNS rule
whose server is reached through a node outbound.

**FR-3** — One setting with three values decides suppression: `on` never suppresses, `off` always
suppresses, `auto` suppresses exactly when the host has no global IPv6 address. It is persisted in
`/etc/sing-box/settings.json`, and exactly one function in `bin/sc` is the definition of the
effective decision; no other code re-derives it.

**FR-4** — `sc ipv6 on|off|auto` sets and persists that setting. `sc ipv6 show` reads and prints it,
and `cmd_ipv6()` itself writes nothing in that form — the scope of the no-write property is BC-11's.
All four print the effective decision and the evidence that produced it, in the user's language.

**FR-5** — `sc ipv6 <value>` performs a service-affecting action only when the effective decision
changes. When the effective decision is unchanged it states that and leaves the service untouched.

**FR-6** — "The host has a global IPv6 address" is true exactly when the host holds at least one
IPv6 address inside `2000::/3` on an interface that is neither loopback nor this project's own TUN
device. Loopback (`::1`), link-local (`fe80::/10`) and unique-local (`fc00::/7`) addresses never
make it true.

**FR-7** — When the host's IPv6 address state cannot be read, the effective decision under `auto` is
"do not suppress", and one complete line on stderr names the cause and the assumption taken.

**FR-8** — Name resolution does not depend on any node being usable for the **node-independent class**:
the names the `hosts` server answers, the names matched by a domestic DNS rule that carries no rule-set
tag, and every query the suppression rule answers. That class is answered while every node outbound is
unusable and in every rule-set state; in `global` routing mode it narrows to what the `clash_mode` rules
do not capture, by the user's own instruction, and no class outside it is promised.

**FR-9** — The emitted document states no DNS wait and introduces no new stall: for each class of names
the acceptance criteria probe, the wall clock from query to user-visible outcome is no greater than the
same query's on the pre-T-16 document, and for the node-independent class it is at most 100 ms while
every node outbound is unusable. A query the document routes to a resolver reached through a node
outbound depends on that node being usable; sing-box abandons such a query at its own fixed per-query
deadline (Q-2), and this task neither changes that deadline, nor answers in its place, nor consults a
second resolver.

**FR-10** — `bin/sc` defines no DNS wait, and the emitted document contains no key expressing one in any
of its states. The three existing socket waits keep their values and their call sites.

**FR-11** — The resolver that answers each class of names is the resolver that answers it on the pre-T-16
document, in every routing mode and in both rule-set states: no name that resolves through `remote_dns`
there starts resolving through a non-proxied resolver, and the class of names the document matches by no
DNS rule keeps being answered by the proxied resolver. The assignment is static — it does not vary with
any node's health, and no name is re-routed to a non-proxied resolver as a consequence of a node being
unusable.

**FR-12** — Nothing FR-8 and FR-9 promise depends on an `.srs` rule-set being usable: no DNS rule
this task adds references a rule-set tag, so `_filter_rules` cannot delete the resilience on the
exact host that needs it.

**FR-13** — Every change to the emitted document is expressed as composition — `CONFIG_BASE` and/or
an overlay applied through the existing `_merge()`. `generate_config()` gains no configuration
literal, and the directive vocabulary gains no member. A shortfall of the composition layer is
reported as a finding in `02_SOLUTION_DESIGN.md`, naming what could not be expressed.

**FR-14** — A failure raised while applying an overlay `sc` authored is not reported as a fault in
the user's override file. The user's file is named only when the user's file is what failed.

**FR-15** — `remote_dns` keeps `detour: proxy`, so DNS continues to follow the selection T-15's
auto-select group makes.

**FR-16** — Every new user-facing string is an English sentence used as the translation key with a
`zh` entry carrying the same placeholder set; no new `zh` string contains `失败：`; no new key is
namespaced in the `ls.*` shape. Q-15 fixes the exact text of every new string in both languages.

## Out of scope

1. The telemetry reject list and any `dns.rules` entry serving it — T-17 owns it, including where its
   rule sits relative to the `clash_mode` rules.
2. Any `sc doctor` section, including a DNS-timing or IPv6-consistency check — T-20 owns them.
3. Any change to `sc status`, `sc now`, `sc ls`, `sc use`, `sc mode` or their output.
4. Any change to `route.rules`, `route.final`, `outbounds`, the `proxy` selector or the auto-select
   group; this task changes the `dns` region and the `sc ipv6` surface only.
5. Enlarging, shrinking or moving `sc`'s three own socket waits — `timeout=3` (`bin/sc:1635`,
   Clash API), `timeout=8` (`bin/sc:355`, egress IP), `timeout=30` (`bin/sc:989`, rule-set download).
   None of them is a DNS wait.
6. R-15 (one exception envelope over the override pipeline), R-19 (the five `ls.*` keys), R-20
   (`clash_api()`'s exception coverage), R-21 (`RESERVED_TAGS` versus `GLOBAL`) — each has a named
   owner elsewhere.
7. R-16's type-mismatch vocabulary in `_merge()` — see Q-1; `_merge`, `_directive_of`,
   `_apply_directive`, `DIRECTIVES` and `_load_override` are unchanged by this task.
8. A committed test harness or a new `verify_all` step — R-9 owns it.
9. Restoring, reading or deleting `/usr/local/bin/sc.bak-2026-08-01-1006`, or any other hand-made
   backup on any host.
10. Any daemon, timer or hook that re-generates the configuration when the host's IPv6 state changes.
11. IPv6 handling anywhere outside name resolution — no `domain_strategy`, no inbound address, no
    route-level IPv6 rule.
12. `install.sh`, `uninstall.sh`, `systemd/`, and the shape or mode of `settings.json` beyond adding
    one key's meaning.
13. Changing which resolver answers a name the emitted document matches by no DNS rule — Q-17 rules
    that it stays the proxied resolver, and FR-11 binds it.
14. Any mechanism that consults a second resolver after a failed, negative or unanswered exchange, and
    any attempt to bound a DNS query inside sing-box: neither exists in this build (Q-2), and this task
    neither invents nor emulates one.
15. The emitted `log` region, including `log.level` — no change to what sing-box records, or at which
    level, when it abandons a query (Q-19).

## Boundary conditions

**BC-1** — Zero nodes (fresh install, before the first `sc add`) → the emitted document passes the
real `sing-box check`, and every name in the node-independent class is answered within 100 ms.

**BC-2** — Every node outbound accepts the connection and never answers → FR-8, FR-9 and FR-11 hold: the
node-independent class is answered, every other class is left unanswered by sing-box, and no name is
re-routed. This is the state a `urltest` group provably never demotes
(`.harness/insight-index.md:27`), so it is the primary case, not an edge.

**BC-3** — Every node outbound refuses the connection → BC-2's outcome: the node-independent class is
answered within 100 ms and no name is re-routed. What sing-box returns for the other classes is
whatever it returns at HEAD in this state; T-16 changes it in no way.

**BC-4** — All four rule-sets unusable (the degraded config, where `_filter_rules` drops every
rule-set-referencing DNS rule) together with BC-2 → the node-independent class narrows to the names the
`hosts` server answers, the names the enumerated domestic suffix rule answers and the suppressed query
types, and those are still answered; every other name is left unanswered until a node is usable again.
`sc`'s existing degradation warning is the signal that the host is in this state, and both READMEs state
this consequence (Q-18).

**BC-5** — Host holds a global IPv6 address, setting `auto` → AAAA queries resolve normally.

**BC-6** — Host holds only loopback and link-local IPv6 addresses, setting `auto` → AAAA suppression
is in effect. One of this host's link-local addresses sits on `sb-tun` itself, so an "any IPv6
address" test is wrong here (`/proc/net/if_inet6`, 7 entries, all `fe80::/10` plus `::1`).

**BC-7** — The host's IPv6 address state cannot be read (source absent, unreadable, or in an
unexpected shape) → FR-7: no suppression, one loud line.

**BC-8** — `settings.json` absent, or present with no `ipv6` key (every host upgrading to this build)
→ the setting is `auto`; nothing is written to seed it.

**BC-9** — `settings.json` holds an unrecognised `ipv6` value (hand-edited) → the setting is `auto`,
and one complete stderr line names the file, the key and the three accepted values.

**BC-10** — `settings.json` is unreadable or not valid JSON → the behaviour every other setting
already has on that host; no traceback and no new failure mode.

**BC-11** — `sc ipv6 show` on a host with no `config.json`, no nodes, or a stopped service →
`cmd_ipv6()` prints the setting, the effective decision and the evidence, itself writes nothing,
performs no service-affecting action, and the command exits 0. The no-write property belongs to
`cmd_ipv6()`, not to the command: `main()`'s start-up path (`_init_files()` plus
`_resolve_clash_port()`) runs first for `sc ipv6` exactly as for every non-`doctor` command, so the
command creates `/etc/sing-box`, seeds `nodes.json` and `settings.json`, and binds a probe socket and
persists a Clash API port on any host that has recorded none. That path is unchanged by this task,
the read-only start-up opt-out keeps `sc doctor` as its only member, and no user-facing or stage text
states that `sc ipv6 show` is write-free as a command.

**BC-12** — `sc ipv6 <value>` where the effective decision is already that value → no regeneration,
no service-affecting action, one line stating that nothing changed.

**BC-13** — The host gains or loses a global IPv6 address after generation → the emitted document
keeps the decision made at generation time until the next regeneration; `sc ipv6 show` reports the
decision the *current* host state produces, so the discrepancy is visible on demand. `sc ipv6 <value>`
compares two decisions both computed from the current host and neither read back from the document on
disk (FR-5, Q-9, AC-6), so a value whose effective decision equals the current one prints the current
host's decision **and** that nothing changed, in the same run, while the stale document stays in
place — `sc ipv6 auto` on a host whose state changed under `auto` is exactly that case. The repair is
an unconditional regeneration: `sc reload` regenerates and applies the current decision in one step,
and a `sc ipv6 <value>` regenerates only when the value it sets flips the effective decision away from
the current one, which makes `sc ipv6 <opposite>` followed by `sc ipv6 <wanted>` the two-step form.
In the harmful direction — a host that lost its global address, where the stale document leaves the
AAAA stall this task exists to remove — that repair is the only escape, and nothing this task ships
detects the change, prompts for it, or names it at the moment the user meets it (out-of-scope
item 10).

**BC-14** — A node whose server address resolves only to AAAA, while suppression is in effect → that
node is unreachable, and `sc ipv6 on` is the stated escape. Under `auto` this state is unreachable,
because a host with no global IPv6 address cannot reach that node either way.

**BC-15** — A user `override.json` that `$replace`s `dns.rules` or `dns.servers` → the user's
document wins and the resilience this task adds can be removed by it. This is the documented
contract (`README.md`, override section), not a defect, and nothing here defends against it.

**BC-16** — Upgrade of an existing host: `config.json` in the pre-T-16 shape plus a drift record at
`/etc/sing-box/.config.sha256` → the first `sc reload` succeeds with no hand-editing of any file
under `/etc/sing-box`, prints no drift warning, and leaves a record matching the new file on disk.

**BC-17** — This host's installed binary carries the 2026-08-01 `sed` hand-patch
(`"query_type": [28, 64, 65]`) while the repository reads `[64, 65]` (`bin/sc:1101`) → the next
`install.sh` overwrites `/usr/local/bin/sc` and discards the hand-patch by design. The shipped
default reproduces its effect on this host, because the host has no global IPv6 address (BC-6) and
`auto` therefore suppresses; the shipped behaviour is additionally mode-independent (FR-2),
regenerated from source rather than patched into it, and reversible with `sc ipv6 on`.

**BC-18** — Clash mode `global` or `direct`, set live through the Clash API → FR-2 holds; suppression
does not depend on the mode.

**BC-19** — Two `sc` invocations at once → unchanged from today: no lock exists, and `settings.json`
is written exactly as it is written today.

**BC-20** — Any new output stream that is not a terminal → one complete line per fact, no carriage
return, no intermediate state (the non-TTY output contract).

**BC-21** — `sc ipv6` with an argument outside `on|off|auto|show`, in any letter case → the argument
is lower-cased like every other `sc` subcommand's, and an unrecognised one exits non-zero naming the
four accepted values without writing anything.

**BC-22** — A usable but slow node whose proxied resolver does not answer → sing-box abandons the query
at its own per-query deadline (Q-2), answers nothing, and consults no other resolver; the user-visible
failure is produced by the querying client at the client's own budget. No name is exposed to the
non-proxied resolver as a consequence, and a negative or error answer from the proxied resolver is
relayed verbatim rather than re-asked elsewhere. Both READMEs state this limit in the section that
describes name resolution.

## Acceptance criteria

Class **[B]** = behavioural: it observes the user-visible outcome of a real resolver in a real
sing-box process. Class **[S]** = structural: it pins the artifact, the code or the documents.

| id | criterion | class | verification |
|---|---|---|---|
| AC-B1 | With every node accepting and never answering, each name in the node-independent class — one the `hosts` server answers, one matched by the enumerated domestic suffix rule, one suppressed query type — is answered within 100 ms | [B] | Second, unprivileged sing-box from the emitted document with the TUN inbound removed, its own cache path and Clash port; the node outbound points at a local listener that accepts and never answers; resolution driven through that instance and timed |
| AC-B2 | Same as AC-B1 with all four rule-sets unusable (degraded config), over the BC-4 subset of that class | [B] | As AC-B1, fixture rules directory empty |
| AC-B3 | Same as AC-B1 with every node refusing the connection | [B] | As AC-B1, listener replaced by a closed port |
| AC-B4 | With suppression in effect, an AAAA query is answered empty `NOERROR` within 100 ms and issues no upstream query | [B] | As AC-B1; the upstream side is a local stub resolver that records every query it receives — it records none |
| AC-B5 | With `sc ipv6 on` on the same host, the same AAAA query is resolved normally | [B] | As AC-B4; the stub resolver records the AAAA query |
| AC-B6 | AC-B4 holds with the instance in clash mode `global` and in clash mode `direct` | [B] | As AC-B4, mode set through the *fixture* instance's own Clash API |
| AC-B7 | With a usable node, one probe name per class — `hosts`, domestic-suffix, `geosite-cn`, `geosite-private`, `geosite-google`, and one matched by no rule — is answered by the same server as at HEAD, in both rule-set states and in all three routing modes | [B] | Two local stub resolvers stand in for the proxied and the non-proxied server; the stub that receives each probe name is compared against a HEAD-clone run of the same fixture |
| AC-B8 | With every node accepting and never answering, a name matched by no DNS rule produces no answer from sing-box and reaches no non-proxied stub, and the wall clock to the client's own outcome is no greater than the HEAD control's | [B] | As AC-B1, both stubs instrumented, client driven with a single try and a fixed timeout larger than sing-box's deadline; wall clock recorded on both sides |
| AC-B9 | With zero nodes, the node-independent class is answered within 100 ms | [B] | As AC-B1 with an empty node list |
| AC-B10 | Every one of AC-B1 … AC-B9 has a control run of the identical fixture on a pristine HEAD clone. **Defect-reproducing** controls — AC-B4 and AC-B6 — must exhibit the defect, in the form the mode makes possible: in `rule` mode (AC-B4) and in clash mode `global` (AC-B6) the AAAA query stalls at about 10 s, because HEAD sends it to the proxied resolver; in clash mode `direct` the HEAD control must exhibit the defect as the **absence of suppression** — HEAD issues the AAAA query to the non-proxied resolver and answers it — because HEAD's `clash_mode: Direct` DNS rule reaches a resolver no node touches (`bin/sc:1100`), which makes a stall impossible there. **Agreement** controls — AC-B1 … AC-B3, AC-B5, AC-B7 … AC-B9 — must produce the candidate's outcome, AC-B8's HEAD run included, since the unmatched class is a no-regression guarantee and not a fix | [B] | The control runs, recorded verbatim in `06_TEST_REPORT.md` |
| AC-1 | With suppression in effect, the emitted document answers query type 28 with `action: predefined`, `rcode: NOERROR` and no records | [S] | Read the emitted document |
| AC-2 | With suppression not in effect, the emitted document's suppressed query-type list is exactly `[64, 65]`, in that order | [S] | Read the emitted document |
| AC-3 | The rule carrying suppression precedes both `clash_mode` rules and every rule whose `server` is reached through a node outbound, in the emitted `dns.rules` array | [S] | Index comparison over the emitted array |
| AC-4 | No DNS rule this task adds carries a `rule_set` key | [S] | Read the emitted document in the all-usable and the all-unusable rule-set states; both contain the added rules |
| AC-5 | The emitted document passes the **real** `sing-box check` in each of: 0 nodes, 1 node, 3 nodes, suppression on, suppression off, all rule-sets unusable | [S] | `sing-box check -c <fixture>` on the installed binary |
| AC-6 | Exactly one function returns the effective IPv6 decision, and every consumer calls it | [S] | Read the diff; deletion test on the second caller |
| AC-7 | No DNS wait is stated anywhere: the emitted document carries no key expressing one in any of its states, and `bin/sc` defines no DNS wait constant | [S] | Read the emitted document in each AC-5 state; repository-wide search for a new wait literal |
| AC-8 | `_merge`, `_directive_of`, `_apply_directive`, `DIRECTIVES` and `_load_override` are byte-identical to HEAD | [S] | AST extraction and byte comparison, not `grep` |
| AC-9 | `clash_api()`'s `timeout=3`, `_egress_ip()`'s `timeout=8` and `_fetch_to_temp()`'s `timeout=30` are byte-identical to HEAD | [S] | AST extraction — a `grep` freeze check is unsound here, `timeout=3` being a prefix of `timeout=30` |
| AC-10 | `generate_config()` gains no configuration literal and no fourth key in its three-key array guard | [S] | Read the diff |
| AC-11 | `sc ipv6 on\|off\|auto\|show` each exit 0 in both languages and print the effective decision and its evidence | [S] | Run all eight combinations in a redirected fixture |
| AC-12 | `cmd_ipv6()` in its `show` form writes no file, issues no network request and performs no service-affecting action. The criterion is scoped to that function: `main()`'s start-up path (`_init_files()` plus `_resolve_clash_port()`) runs for `sc ipv6` exactly as for every non-`doctor` command, and its writes are neither counted against this criterion nor claimed to be absent | [S] | mtime witness over the fixture root with `cmd_ipv6()` driven directly; shimmed init commands record no invocation; the start-up path's own writes are observed in a separate run |
| AC-13 | `sc ipv6 <value>` that does not change the effective decision performs no service-affecting action | [S] | Shimmed `systemctl`/`rc-service` record no invocation; `config.json` mtime unchanged |
| AC-14 | `sc ipv6 <value>` that changes the effective decision regenerates and applies it, and the new document reflects the new decision | [S] | Read the emitted document before and after |
| AC-15 | An absent `settings.json`, an absent `ipv6` key, and an unrecognised `ipv6` value each yield `auto`; the unrecognised value yields one stderr line naming file, key and accepted values | [S] | Three fixtures, both languages |
| AC-16 | A host with only loopback and link-local IPv6 addresses yields "no global IPv6"; a host with a `2000::/3` address on a non-loopback, non-TUN interface yields the opposite | [S] | Fixture address sources, including one carrying a link-local address on the TUN device |
| AC-17 | An unreadable IPv6 address source yields no suppression plus one stderr line, and no traceback | [S] | Fixture with the source removed and with a malformed one |
| AC-18 | On a BC-16 host, the first `sc reload` succeeds with no hand-editing and prints no drift warning; a second immediate `sc reload` also prints none | [S] | Fixture reproducing the pre-T-16 `config.json` plus its digest |
| AC-19 | No new zh string contains `失败：`; every new key has a `zh` entry with an identical placeholder set; no new namespaced key | [S] | Extract `TRANSLATIONS` and compare placeholder sets |
| AC-20 | `README.md` and `README.zh-CN.md` document `sc ipv6`, the effective-decision rule, which classes of names do not depend on a node, and BC-22's limit, and stay line-for-line mirrors; `CHANGELOG.md` gains a Chinese entry | [S] | Read both files; line-count and section-order comparison |
| AC-21 | `HELP_EN` and `HELP_ZH` both document `sc ipv6` at the existing column alignment | [S] | Read both blocks |
| AC-22 | An overlay `sc` authored that fails to apply produces a message that does not name `override.json` | [S] | Fault-injected overlay in a fixture |
| AC-23 | `python3 -m py_compile bin/sc` passes; the diff uses no syntax newer than Python 3.6 and no non-stdlib import | [S] | Compile plus read the diff |
| AC-24 | `bash .harness/scripts/verify_all.sh` ends with no FAIL against the 17/0/0/1 baseline; any doc-size WARN that clears on archive is predicted before code is written | [S] | Run it |

## Non-functional requirements

- **NFR-1 — Python 3.6 syntax floor, standard library only** (`.harness/rules/50-singbox-cli.md`).
- **NFR-2 — Bilingual parity is a correctness requirement**, not a nicety: a user-facing string
  missing from `zh` prints English mid-sentence, and `TRANSLATIONS` has no `en` table (R-19).
- **NFR-3 — Permitted diff:** `bin/sc`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`,
  `docs/dev-map.md`, plus this task's stage documents. Nothing else.
- **NFR-4 — `settings.json` is not a credential document.** It keeps being written the way it is
  written today; nothing routes it through `_write_private()`.
- **NFR-5 — `cmd_ipv6()`'s `show` form stays cheap:** at most one local read, no network access, no
  new wait, and zero added wall-clock when the service is stopped. The cost of `main()`'s start-up
  path, which `sc ipv6` pays exactly as every non-`doctor` command does, is unchanged by this task and
  lies outside this requirement.
- **NFR-6 — Verification never touches the live system.** Every harness neutralises the import-time
  auto-elevate (`docs/dev-map.md`, the recipe), never drives `_init_files()` (it hard-codes
  `/var/lib/sing-box`), never writes under `/etc` or `/var/lib`, never invokes `/usr/local/bin/sc`,
  sets `SYSTEMD = OPENRC = False`, issues no `PUT`/`PATCH`/`DELETE` to the live Clash API, and uses
  `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` as the service witness, never
  `is-active`. Every second sing-box process runs unprivileged with no TUN inbound, its own cache
  path and its own Clash port.
- **NFR-7 — A behavioural criterion without a control is not evidence.** AC-B10 is binding on stages 4
  and 6, and each behavioural criterion declares which kind of control it takes: a defect-reproducing
  control whose HEAD run must exhibit the defect, or an agreement control whose HEAD run must produce the
  candidate's outcome. A green run whose control does neither is reported as inconclusive, not as a pass,
  and a behavioural criterion is never replaced by an artifact check — where an observation must shrink,
  it shrinks to a smaller observed behaviour. This is R-22's lesson applied.
- **NFR-8 — One complete line per fact on every new output**, on stdout for results and on stderr for
  warnings and aggregates, per the project's stream split.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Does T-16 claim R-16 (the merge's type-mismatch vocabulary)? | **No.** T-16 creates no reachable case where the mismatch is silent: `dns.rules` is already caught by `generate_config()`'s three-key array guard with a sentence naming the key, and `dns.servers` — the array this task makes a documented override target — is rejected by the real `sing-box check` with a non-zero status before any service-affecting action, exactly as T-14's `06` measured. T-16 also adds no code that indexes a composed array, so the three-key guard needs no fourth entry and the "one key per task" seam does not fire. R-16 stays open and unclaimed, together with its `"0"`-key boundary. The measurements recorded in Q-2 and Q-14 bear on the `dns` region only and leave every clause of this ruling standing. |
| Q-2 | Which timeout is "the 10 s DNS timeout", and can this project bound it? | **It is sing-box's own per-query DNS deadline, it is 10.0 s in 1.13.15, and nothing this project emits can change it.** Measured against the real binary: `sing-box` logs `dns: exchange failed …: context deadline exceeded` stamped `[10.0s]`, reproducibly, and **at that deadline it drops the query — it does not answer, retry, or consult another server**. A `timeout` key is rejected by `sing-box check` on a DNS server, on the `dns` block and on a DNS rule (`json: unknown field "timeout"`), and a bogus-key control on the same objects is rejected identically, which proves the decoder rejects unknown fields rather than ignoring them — so `timeout` is not a field of those objects in this build. What is **not** established, and is therefore claimed by nothing here: that no other key name bounds a DNS query, where the 10.0 s constant lives, and that a detoured DoH server behaves identically to the plain-UDP path measured. |
| Q-3 | What is the DNS budget? | **There is none, and T-16 states none.** Q-2 measured that the emitted document has no position at which a DNS wait can be expressed, so a 4 s — or any — budget is unstatable, and the 10.0 s that governs is sing-box's own and fixed. FR-9 therefore promises a *bound the document does not worsen* plus a 100 ms bound on the node-independent class, both of which are observable, instead of a number the document cannot carry. |
| Q-4 | Does AAAA suppression depend on the routing mode? | **No** (FR-2). The predicate is a property of the host's IP stack, not of the routing policy, so a user who switches to `global` — the mode people switch to when things are broken — must not get the 10 s stall back. Accepted consequence: types 64 and 65 are suppressed in `global` and `direct` too, which is what the rule that already carries them means everywhere else. |
| Q-5 | What answer does a suppressed query get? | An empty `NOERROR`. `NXDOMAIN` would poison the negative cache for the whole name including its A record; a reject or drop reproduces the timeout this task exists to remove. |
| Q-6 | What exactly is "no global IPv6"? | FR-6's predicate: a `2000::/3` address on a non-loopback, non-TUN interface. A default-route test is deliberately not part of it — it adds a second system query and a second failure mode, and `sc ipv6 on\|off` already overrides the judgment for the rare host it would differ on. |
| Q-7 | What happens when detection fails? | No suppression (FR-7). The two errors are not symmetric: suppressing on a host that can use IPv6 makes IPv6-only destinations unreachable, while not suppressing on a host that cannot costs latency the user already has. The assumption is stated out loud, so it is never silent. |
| Q-8 | Is the new key seeded into `settings.json`? | **No.** Absence is defined as `auto` (BC-8), which makes an upgraded host and a fresh host behave identically and keeps `_init_files()` unchanged. |
| Q-9 | Does `sc ipv6 <value>` restart the service? | Only when the effective decision changes (FR-5). An unconditional restart drops every live connection for a command that frequently changes nothing — the defect T-10 removed from `sc update-rules`. The comparison is between the effective decision before and after the setting change, computed from the same one function, so no second opinion about the emitted document is created. |
| Q-10 | What happens to this host's hand-patch? | It is overwritten by design (BC-17). `install.sh` is idempotent and rewrites `/usr/local/bin/sc`; the backup at `/usr/local/bin/sc.bak-2026-08-01-1006` is not read, restored or deleted by anything this task ships. The shipped default reproduces its effect on this host, because `/proc/net/if_inet6` holds only `fe80::/10` and `::1` entries, so `auto` suppresses. |
| Q-11 | Where does the user see the decision? | `sc ipv6` — the four forms of FR-4. Not `sc status`, not `sc doctor`: T-20 owns the doctor's IPv6-consistency check, and adding a second surface here would create the second opinion rule 85 forbids. |
| Q-12 | Command name and values? | `sc ipv6 on\|off\|auto\|show`. `ipv6` is the word both READMEs and the field report already use, and `on/off` matches `default-tun` / `sysproxy`; `show` matches `update-interval show`. The values are language-neutral, so `sc lang` cannot move them. |
| Q-13 | Does T-16 shape T-17's rule position? | **No.** FR-2 fixes the position of the suppression rule only, and on a reason of its own (host capability). T-17's reject rule keeps its own stated constraint — after the `clash_mode` rules, before the routing rules — and this task states no opinion about it beyond leaving both positions expressible. |
| Q-14 | sing-box 1.13.15 carries no DNS fallback transport and its rule chain does not fall through. How is FR-8 satisfied? | **By static routing alone, and by nothing else.** Measured: with an always-true last rule and `final` pointing elsewhere, the direct resolver is never consulted in any upstream state — answer, `NXDOMAIN`, `SERVFAIL` or silence — while a control in which no rule matches reaches `final` in 0.006 s, so `dns.final` is the no-rule-matched routing default and never a failure fallback. FR-8 is therefore satisfied exactly when a name is *statically assigned* to a resolver reached without a node outbound, and a name assigned to the proxied resolver has no second chance; no catch-all, `final` re-point or retry changes this, and none may be presented as if it did. |
| Q-15 | What is the exact bilingual text of every new user-facing string? | These, en key → zh, placeholders identical in each pair, none containing `失败：`. · `"IPv6 name resolution → {val}"` → `"IPv6 域名解析 → {val}"` · `"AAAA queries are answered empty (setting: off)"` → `"AAAA 查询直接返回空结果（设置：off）"` · `"AAAA queries are resolved normally (setting: on)"` → `"AAAA 查询正常解析（设置：on）"` · `"AAAA queries are answered empty (setting: auto — this host has no global IPv6 address)"` → `"AAAA 查询直接返回空结果（设置：auto —— 本机没有全局 IPv6 地址）"` · `"AAAA queries are resolved normally (setting: auto — this host has a global IPv6 address on {iface})"` → `"AAAA 查询正常解析（设置：auto —— 本机在 {iface} 上有全局 IPv6 地址）"` · `"Could not read this host's IPv6 addresses ({err}) — assuming it has one, so AAAA queries are resolved normally; set it explicitly with \`sc ipv6 on\|off\`"` → `"无法读取本机的 IPv6 地址（{err}）—— 已按存在处理，AAAA 查询将正常解析；可用 \`sc ipv6 on\|off\` 明确指定"` · `"Error: argument must be one of on / off / auto / show"` → `"错误：参数必须是 on / off / auto / show 之一"` · `"{path}: ipv6 must be one of on / off / auto — using auto"` → `"{path}：ipv6 必须是 on / off / auto 之一 —— 已按 auto 处理"` · `"Nothing changed — the sing-box service was not touched"` → `"设置无变化 —— 未改动 sing-box 服务"` · `"Configuration regenerated; sing-box restarted"` → `"配置已重新生成，sing-box 已重启"`. Reusing an existing key in place of one of these is permitted where the existing text says exactly this. |
| Q-16 | Is the schema of this document able to hold everything? | Yes. Evidence, measurements, the related-task survey and the candidates each question beat are in `01_RATIONALE.md`; no unit needed a section this schema does not declare. The bilingual string table is held by Q-15 rather than by a section of its own, and the shortfall Q-18 records is carried to the PM as a question row rather than as a section this schema does not have. |
| Q-17 | FR-8 and FR-11 cannot both hold for the class of names the document matches by no DNS rule. Which promise wins? | **FR-11 wins; FR-8 retires that class.** The only lever for it is `dns.final` (Q-14), and that class is the foreign internet: re-pointing it to a domestic resolver changes the answers on every healthy host permanently — different addresses, and every foreign name disclosed to the domestic resolver — in exchange for resolving names whose destinations are unreachable anyway while the node is down. That is the silent-wrong-result class this project's discriminator rejects, against a loud failure in a state the user is already in, so the assignment stays as it is and FR-11 makes it a tested guarantee rather than an accident. |
| Q-18 | What does T-16 deliver for a host whose rule-sets are all unusable, where the domestic classes also fall into the no-rule-matched class? | **The BC-4 subset, and an honest statement of the rest.** Q-17's ruling applies unchanged in that state: `final` cannot be re-pointed there either without giving foreign names domestic answers, and identifying the domestic class without an `.srs` would be a new classifier this task did not set out to build and no measurement forces. So the names the `hosts` server and the enumerated domestic suffix rule answer, plus the suppressed query types, keep resolving; every other name waits for a usable node or for restored rule-sets. This is a **shortfall against the batch goal**, and it travels to delivery as a filed row rather than as silence — both READMEs state it (AC-20) and `sc`'s existing degradation warning already marks the host. |
| Q-19 | sing-box drops a stalled DNS query silently. What does the "failures must be loud" through-line require here? | **Documentation, not a new signal.** The drop happens inside sing-box with no `sc` process running, so the only surfaces that could speak are the `log` region (out of scope item 15) and a `doctor` row (T-20's, and adding one here is the second opinion T-05 exists to prevent). The loudness obligation T-16 does carry is therefore that it claims no resilience it does not have: BC-22's limit and FR-8's exact class are stated in both READMEs, and the string budget stays at Q-15's ten. |

## Verdict

READY
