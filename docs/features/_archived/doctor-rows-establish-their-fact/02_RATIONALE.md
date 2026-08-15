# 02 — Rationale · T-26 `doctor-rows-establish-their-fact`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Upstream reading record

`01_REQUIREMENT_ANALYSIS.md` read in full; verdict `READY`. No T2 trigger fired: nothing in the
contract was ambiguous enough to design around, no `## Resolved questions` answer is overridden, and
this is not a rework round. `01_RATIONALE.md` was therefore **not** opened beyond one line surfaced
incidentally by a repository-wide `dns/query` grep (`:65`, the sentence naming what BC-10 must probe),
which agrees with the contract and changed nothing.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| The authored AAAA rule, for one decision | `_aaaa_rule(suppress)` | `bin/sc:1743` | **Reuse as-is.** Content frozen; only its *position* gains a home. |
| The emitted position of that rule | `_dns_overlay()`'s `$prepend` payload | `bin/sc:1774` | **Extend by one parameter** so the doctor can read the same expression the generator emits. No new constant, no new function. |
| The effective IPv6 decision | `ipv6_decision()` | `bin/sc:1704` | **Reuse as-is**, still one call per run in each command. |
| "What delay does the running sing-box report?" | `stored_delays(port=None)` | `bin/sc:2211` | **Reuse as-is**; one guard condition narrowed. No re-implementation of the `/proxies` read anywhere. |
| "Is the process alive?" on the doctor's branch | the `/configs` answer `_doctor_clash()` already holds (`bin/sc:2821-2823`) | `bin/sc:2792` | **Reuse — by removing the competing judgement**, not by adding a check. |
| A bounded HTTP call to the Clash API | `clash_api()` | `bin/sc:2179` | **Reuse as-is.** Total over its three exception families; no envelope added (T-18). |
| A translated "nothing changed, run `sc reload`" sentence | `cmd_telemetry`'s key | `bin/sc:209-212`, printed at `:3271` | **Reuse verbatim** at `cmd_ipv6`'s print site; deletes the shorter sibling at `:192`. |
| The `{override}` placeholder convention in a doctor row | drift row | `bin/sc:2634` (`override=str(OVERRIDE_PATH)`) | **Reuse the convention.** |
| A cache-free / bounded DNS lookup | *(none found — see the probe)* | — | **Not built.** No mechanism exists to reuse and FR-9 forbids inventing one. |
| A position validator / config linter | *(none, and none wanted)* | — | **Not built.** Out-of-scope 5; the row judges `sc`'s own emission through `sc`'s own expression. |

Nothing in `docs/dev-map.md`'s "Reusable utilities" table is reinvented, and the two entries this task
touches (`stored_delays()`, `_dns_overlay()`) are edited in place rather than paralleled.

## Why the three fixes share nothing (OQ-4, AC-16)

They are, in order: an **expression** (`rules[:len(prepend)] == prepend`), a **condition**
(`port is None and not is_running()`), and **sentences**. A helper spanning them would have to
abstract "a row states only what it established", which is a rule about prose, not a computation —
the shape rule 85's counter-rule names as machinery bought with a coherence argument. The deletion
test settles it: delete any such helper and no complexity reappears at any of the three sites, because
none of them shares an input, an output or a failure mode with the others.

## BC-10 — method, and what it can and cannot establish

**Why this form.** Stage 2 held no execution tool on this run, so no HTTP request could be issued at
all — which is *convenient* rather than limiting, since the only admissible live probe would have been
the `GET /dns/query` the product already ships, and that probe cannot answer the question anyway (it
returns a DNS-JSON body with no cache indicator; see below). The question BC-10 actually asks —
*does a bounded cache-free lookup exist through the Clash route?* — is a question about the **route's
surface**, and the route's surface is a property of the artifact. So the artifact was read.

**Calibration matters more than the raw counts.** A literal search over a Go binary answers "is this
string present", not "is this feature absent" — unless the oracle is calibrated. Three controls make
it informative: `/proxies`, `/configs` and `/delay` are present, so route literals survive in this
build; `/dns/query` is **0** even though the endpoint demonstrably works (T-20 measured it), because
chi mounts `/dns` and registers `/query` separately — this is T-20's own negative control and it is
what stops a naive "absent ⇒ not there" reading; and `clashapi.queryDNS` / `clashapi.dnsRouter` are
present in the pclntab, which is how the endpoint's *existence* was established in the first place.

**What the search found, in one sentence:** the cache vocabulary this binary carries is either
**configuration** (`disable_cache`, `independent_cache`, `cache_capacity`, `disable_expire`) or
**mutation** (`clashapi.cacheRouter`, `clashapi.flushFakeip`, `/fakeip/flush`); the request vocabulary
a read-only bypass would need (`no_cache`, `bypass_cache`, `skip_cache`, `cache_bypass`, `fresh=`,
`refresh=`) is absent, and the one `no-cache` present five times is the HTTP `Cache-Control` header
value (chi's `NoCache` middleware), which governs caching of the *API response*, not of the DNS
answer.

**What it cannot establish.** Go dedupes string literals, so if the handler read a parameter named
`disable_cache` the literal would be indistinguishable from the config option's JSON tag. The search
therefore cannot *prove* the absence of a parameter with that exact name. This is why the ruling does
not rest on the search alone.

**The leg that does not depend on the search at all.** Suppose such a parameter existed. The row would
still be unable to state the stronger fact, because the response body carries no cache-hit indicator
(measured first-hand in T-20: `{"AD","Answer","CD","Question","RA","RD","Server","Status","TC"}`) — so
the row would be asserting "this was resolved upstream" on the evidence that *we asked for it to be*,
which is a proxy for the fact and exactly what FR-1 forbids. The only body-level discriminator is a
TTL that counts down between two queries, and a second query is forbidden by NFR-2 and AC-11. Hence
the narrowed claim is not a fallback: it is the strongest sentence this probe can support in either
world, which is also why a later observation cannot reopen the decision (RS-2).

**Safety.** Read-only throughout: one `Grep` over one binary. No request to the live Clash API, no
read or write under `/etc/sing-box` or `/var/lib/sing-box`, no `systemctl` invocation of any kind, no
service action.

## Row 1 — why *position*, and why the position needed a home

OQ-1 already ruled position over membership, so the design question was only *where the position
lives*. Three shapes were weighed.

1. **A module constant `AAAA_RULE_INDEX = 0`, read by both sites.** Impossible as stated: the emitter
   cannot consume an index. `bin/sc:1261-1264` records the reason as a deliberate design decision —
   `$before` / `$after` take an **anchor rather than a numeric index** precisely because an index
   computed against the base is wrong the moment an earlier overlay inserts. A constant only the probe
   reads is not "one definition, two readers"; it is prose with a number in it.
2. **A bare head slice in the probe** (`rules[:1] == [_aaaa_rule(suppress)]`). Smallest, correct
   today, and rejected in the contract's `## Smaller alternative rejected` for reasons stage 3 should
   test rather than accept.
3. **The overlay takes the decision as an argument** (chosen). This is `_aaaa_rule()`'s own argument
   applied one level up: `_aaaa_rule()` exists as a function rather than a literal *because* the
   caller passes the decision in, which is what let the doctor ask its question without a second
   `ipv6_decision()` call. Passing `suppress` to `_dns_overlay()` extends that same move to the
   position, and it **removes** the objection its docstring records — the doctor may now call the
   overlay, because the overlay no longer calls `ipv6_decision()`.

The cost is honest and small: one extra reader of `ipv6_decision()` at `generate_config()`'s compose
site, where the call count per run is unchanged.

BC-3's two causes are named on one line rather than in two branches because the probe cannot tell them
apart (a document missing the rule and a document whose head was reordered are the same observation),
and inventing a branch that guesses would be a fourth proxy-for-a-fact. Naming both admissible causes
on one line is T-20's BC-13 shape, already shipped in this report.

## Row 2 — the duplicated judgement, and the state that survives

The mechanism, re-read first-hand: `_doctor_clash()` establishes liveness at `bin/sc:2821-2823` (the
`/configs` answer), then `stored_delays(port=port)` at `:2845` re-decides it at `:2231` through
`is_running()`, whose final line returns `False` without ever running a subprocess when neither
`SYSTEMD` nor `OPENRC` is set. The weaker answer wins, `({}, None)` comes back, and the row prints a
count no request produced. Narrowing `is_running()` itself is inadmissible (AC-8, and it is `sc
status`'s and `_doctor_service()`'s judgement too); deleting the guard is inadmissible (AC-7);
changing the return shape is inadmissible (out-of-scope 7). What remains is to stop routing the
doctor's branch through the weaker judgement, and the cheapest expression of that is the argument the
doctor already passes and no other caller does.

Two objections, answered.

- *"An explicit port silently disables the guard for a future caller."* It does, and the docstring
  says so in the interface's own terms. The alternative (`running=True`) makes the claim explicit at
  the cost of a knob a future caller can pass **wrongly** — asserting liveness that does not hold buys
  back the 3 s wait the guard exists to prevent. `port=None` cannot be passed wrongly: a caller that
  names a port is by construction a caller that resolved one from settings and has a reason to believe
  something is there. `sc doctor` is the only such caller today, and `docs/dev-map.md` already records
  that fact as the parameter's meaning.
- *"NFR-2 says zero added requests, and this makes an init-less host issue `/proxies`."* NFR-2's
  subject is the probe inventory: no new endpoint, no new call site, no extra request per state. The
  request already exists at this exact call site; what changes is which hosts reach it, and AC-5
  **requires** that they do. Reading NFR-2 the other way would make AC-5 unsatisfiable.

One state survives the fix: `/configs` answers and `/proxies` does not (a service stopping between the
two calls, a body that is not an object). `stored_delays()` returns absence there, indistinguishable
from "answered, no history". Rather than reach for the forbidden return-shape change, I-6 makes the
sentence true of both — it reports the **read** (`a stored delay was read for 0/N nodes`) and adds
"or the list could not be read" to a cause list that already names two causes. This is the same
instrument as row 3, applied to the residue of row 2, and it costs one sentence. It also keeps AC-6's
`0/2` numerals and the `sc ls` next step intact.

## Row 3 — wording derivation, and why the clause survives the branch where nothing answered

The `[OK]` sentence loses the word *resolved* and gains the cache: "resolved … through the running
sing-box" invites the reading FR-8 forbids, that the milliseconds measured a resolution performed
upstream on this query. "answered for {name} in {ms} ms, possibly from its own DNS cache" states only
what the probe established — an answer arrived, and this is how long it took — and names the cache as
an admissible source.

The two PROBLEM branches share one clause **verbatim**, which is what OQ-3's "all three DNS-row
branches, one clause" asks for. Its exact form was chosen against a truth trap. Candidate wordings
such as "this may be a cached answer" are false on the branch where `clash_api()` returned `None` —
nothing was served there at all, so calling it possibly-cached would itself be an unestablished claim,
in the task whose subject is unestablished claims. (T-20's P-3 measurement pins the boundary: an
NXDOMAIN arrives as a **200 with a JSON object and no `Answer`**, i.e. on the *second* branch; the
third branch is the API not answering usably.) The shipped clause — "an answer already cached by the
running sing-box survives a node change" — is a standing, conditional property of the install: it is
true whether or not anything is cached, it is the reason the next step may not help, and it withdraws
the effectiveness assertion without replacing it with a new one. It also covers BC-12's asymmetry (a
negative answer is held far longer than a positive one) without any branch attempting to detect a
cache hit.

## R-24 — the truth check BC-11 demanded

The reused sentence names two things: that nothing was touched, and that `sc reload` applies *this
setting* to a configuration generated before it. Both hold for `sc ipv6`: the setting is persisted by
`save_settings()` before the comparison (`bin/sc:3200-3208`), so the "nothing changed" is about the
**effective decision**, not about the file; and the state the second clause names is real — a
`config.json` generated before the `ipv6` key existed, or before the decision it now records, is
exactly what `sc reload` repairs, and it is the state the AAAA row will now send more users to. No
placeholder, no branch, no second fact, so BC-11's three drop triggers are all absent. The swap also
deletes a key, which is the one direction rule 85 likes best.

## What was deliberately not built

- Any cache bypass, flush, warm-up, TTL inspection or hit detector (BC-10 ruled; FR-9 forbids).
- A second delay source, a `/proxies/<tag>/delay` call, or any measurement `sc` performs itself.
- A `config.json` position validator, an `override.json` linter, or any evaluation of sing-box's
  rule-matching semantics (out-of-scope 5).
- A shared helper, decorator or registry over the three rows (OQ-4, AC-16).
- A new exit value, a new row, a new section, a new flag, a new settings key.

Two of these are declines worth filing in `.harness/rejected-decisions.md`
(`position-test-by-a-bare-head-slice`, `doctor-cache-free-dns-lookup`); `.harness/**` is outside this
task's diff, so RS-7 routes them to the PM at delivery, following the T-18 / T-19 precedent.

## Evidence cited

- `bin/sc:192`, `:209-212`, `:309-311`, `:333-342` — the translation entries this task edits or deletes.
- `bin/sc:1261-1264` — why directives anchor by content, never by index.
- `bin/sc:1311-1318` — `CONFIG_BASE`'s `dns.rules` head, and its comment recording why the AAAA rule sits at index 0.
- `bin/sc:1743-1774` — `_aaaa_rule()` / `_dns_overlay()` and the docstring argument this design extends.
- `bin/sc:2092-2093` — the one `_dns_overlay()` call site.
- `bin/sc:2202-2255` — `is_running()`'s final-line `False` and `stored_delays()`'s guard.
- `bin/sc:2680-2722`, `:2792-2876` — the two probes this task edits.
- `bin/sc:3200-3213`, `:3263-3276` — `cmd_ipv6`'s and `cmd_telemetry`'s no-op lines.
- `README.md:126`, `:263-280` — the published position promise, the section table, the changes-nothing paragraph and the exit-status table (mirrored line-for-line in `README.zh-CN.md`).
- `docs/features/_archived/doctor-extended-checks/04_DEVELOPMENT.md:81-127` — T-20's first-hand `/dns/query` bodies (P-2a, P-3) reused as fixture bodies rather than invented.
- `docs/features/_archived/doctor-extended-checks/02_RATIONALE.md:58`, `03_RATIONALE.md:10-18` — the BC-16 probe this stage's BC-10 probe reproduces, including its negative control.
- `/usr/local/bin/sing-box` — the BC-10 probe's subject (read-only literal search; counts in the contract).
