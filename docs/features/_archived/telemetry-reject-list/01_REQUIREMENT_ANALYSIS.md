# 01 — Requirement Analysis · T-17 `telemetry-reject-list`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

Mode: **full**. `.harness/rules/70-doc-size.md` carries no `## Stage-doc boundary rule` section, so the
agent schema is applied as written: evidence, measurements, the related-task survey and the candidates
each question beat live in `01_RATIONALE.md`; the bilingual string table is carried by Q-13 rather than
by a section this schema does not declare. FR, BC, AC and Q ids are stable identifiers, not sequences.

## Goal

A host stops asking anyone to resolve the names whose only job is reporting its user's activity to a
vendor: a fixed, small, criterion-stated list of telemetry names is answered locally with "no such
domain" in every routing mode, the whole list is switched off with one command, and the list is
content the user can read, extend and make exceptions to — all expressed as data plus a toggle on
T-14's composition layer, with the mechanism sing-box 1.13.15 actually has (Q-4) and no claim beyond it.

## In-scope behaviors

**FR-1** — The emitted `config.json` carries a curated list of telemetry names, and a name is in it
only if its sole function is carrying usage, diagnostic, crash or advertising-identifier data to a
vendor, **and** blocking it disables no user-visible function of the product it belongs to. No update,
activation, licensing, authentication, push-delivery, CDN-content, captcha or security-feature endpoint
is a member — a name that gates site content, a login widget, message delivery or a safe-browsing check
fails the second clause and is excluded whatever its data-collection role.

**FR-2** — The list holds at most 24 names and covers at least four classes: desktop-OS diagnostic
endpoints, browser telemetry endpoints, the dominant global analytics/crash-reporting SDK endpoints, and
the dominant domestic analytics SDK endpoints. Every name carries one source-line stating its vendor and
what it carries, and `02_SOLUTION_DESIGN.md` enumerates the membership with per-name evidence, so
"the list contains X because Y" is answerable for every member without running the tool.

**FR-3** — With the setting at `block`, a query for a listed name or for any subdomain of one is
answered by sing-box itself with rcode `NXDOMAIN` and no records, within 100 ms, and issues no query to
any DNS server. A name that merely ends with a listed name's characters without a label boundary is not
a listed name and resolves as it does today.

**FR-4** — The reject rule is evaluated after the rule that answers from the predefined hosts table and
before both `clash_mode` DNS rules and before every DNS rule whose server is reached through a node
outbound. FR-3 therefore holds in all three routing modes — `rule`, `global` and `direct` alike — and a
user who switches mode changes which resolver answers other names, never whether a listed name is
rejected.

**FR-5** — The reject rule carries no `rule_set` key, so `_filter_rules` cannot delete it: FR-3 holds
in every rule-set state, the all-unusable one included.

**FR-6** — One setting with two values decides the whole feature: `block` rejects, `allow` does not. It
is persisted in `/etc/sing-box/settings.json`, `block` is the value of a host that has never set it, and
exactly one function in `bin/sc` is the definition of the effective setting; no other code re-derives
it. Under `allow` the emitted document carries no reject rule at all.

**FR-7** — `sc telemetry block|allow|show` sets and persists that setting; `show` reads it. All three
forms print the effective setting and what it means for a listed name; `show` additionally prints every
name in the list, one complete line per name, in the user's language. `cmd_telemetry()` itself writes
nothing in the `show` form — the scope of that no-write property is BC-16's.

**FR-8** — `sc telemetry <value>` performs a service-affecting action only when it changes the persisted
setting. When it does not, it states that nothing changed and names `sc reload` as the way to apply the
setting to a configuration generated before it, and leaves the service untouched.

**FR-9** — The emitted document leaves room for the user in three ways that survive `sc reload`: exactly
one element of the emitted `dns.rules` matches the anchor object both READMEs document, in every state
in which the reject rule is emitted; each `clash_mode` DNS rule still matches its own anchor object
exactly once, so a user rule can be inserted before them in **both** settings states; and both
documented recipes — adding the user's own names, and excepting one shipped name — are expressible with
the five directives the composition layer already has.

**FR-10** — Every change to the emitted document is expressed as composition: `CONFIG_BASE` and/or an
overlay applied through the existing `_merge()` with an existing directive. The directive vocabulary
gains no member, `generate_config()` gains no configuration literal, and the task adds no new file, no
new download, no new rule-set, no new command surface beyond FR-7 and no new persisted state beyond the
one settings key of FR-6. A design element outside this envelope is admissible only when
`02_SOLUTION_DESIGN.md` names the behavior in this document that T-14's composition layer and T-16's
overlay idiom cannot express.

**FR-11** — T-16's contract is preserved and proven preserved: the suppression rule keeps the first
position in the emitted `dns.rules`, `dns.servers` and `dns.final` are unchanged, and the resolver that
answers each class of names is the resolver that answers it before this task — for every name except a
listed one, whose answer this task deliberately changes.

**FR-12** — `README.md` and `README.zh-CN.md`, as line-for-line mirrors, state: the complete list and
the FR-1 criterion, the FR-7 command and its default, the two override recipes of FR-9, how to tell a
rejected name from a network failure (an immediate `NXDOMAIN` with no records, against a query that
never returns), and the limits — the list matches names, so a client using its own encrypted resolver or
connecting to an IP literal is unaffected. No shipped text claims more than that.

**FR-13** — Every new user-facing string is an English sentence used as the translation key with a `zh`
entry carrying the identical placeholder set; no new `zh` string contains `失败：`; no new key is
namespaced in the `ls.*` shape. Q-13 fixes the exact text of every new string in both languages, and
that is the whole budget.

**FR-14** — `HELP_EN` and `HELP_ZH` both document `sc telemetry <block|allow|show>` at the existing
column alignment.

## Out of scope

1. Any `dns.rules` entry other than the one reject rule, and any change to T-16's suppression rule, to `dns.servers`, to `dns.final` or to `independent_cache`.
2. Any change to `route.rules`, `route.final`, `outbounds`, the `proxy` selector or the auto-select group — no route-level `reject` action, no IP-level blocking.
3. A `geosite` category, a fifth rule-set file, any new download, and any change to `RULESET_FILES`, `sc update-rules` or the rule-set degradation model (Q-3).
4. Any `sc doctor` section, including a "is the reject list in effect" row — T-20 owns them.
5. Any change to `sc status`, `sc now`, `sc ls`, `sc use`, `sc mode`, `sc ipv6` or their output.
6. R-16's type-mismatch vocabulary in `_merge()` — see Q-1; `_merge`, `_directive_of`, `_anchor_index`, `_apply_directive`, `DIRECTIVES` and `_load_override` are unchanged by this task.
7. R-15 (one exception envelope over the override pipeline), R-19 (the five `ls.*` keys), R-20 (`clash_api()`'s exception coverage), R-24 (`sc ipv6`'s "Nothing changed" line), R-25 (`_load_lang()`'s non-UTF-8 traceback), R-26, R-27 — each has a named owner elsewhere.
8. R-23 — no requirement here presumes a DNS capability T-16 measured absent: no per-query wait, no fall-through on failure, no second resolver.
9. A first-run notice, a migration prompt, or any mechanism that tells an upgrading host its behaviour just changed beyond the changelog, the READMEs and `sc telemetry show` (Q-7).
10. A committed test harness or a new `verify_all` step — R-9 owns it.
11. `install.sh`, `uninstall.sh`, `systemd/`, and the shape of `settings.json` beyond adding one key's meaning.
12. Defending the emitted document against a user `override.json` that `$replace`s `dns.rules` — the documented contract, not a defect (BC-6).
13. Blocking telemetry that does not use the system resolver: a client's own DoH/DoT resolver, and a connection to an IP literal, are untouched and are stated as limits rather than covered.
14. Editing `CONTEXT.md`, `.harness/**` or `docs/tasks.md` — outside the permitted diff of NFR-3; what they would receive travels to the PM.

## Boundary conditions

**BC-1** — Zero nodes (fresh install, before the first `sc add`) → the emitted document passes the real
`sing-box check` and FR-3 holds; rejection depends on no node being usable.

**BC-2** — All four rule-sets unusable (the degraded document) → FR-3 and FR-5 hold: the reject rule is
present and answers, in every routing mode.

**BC-3** — Every node outbound accepts the connection and never answers → FR-3 holds within 100 ms; a
listed name is answered while every proxied resolver is unreachable.

**BC-4** — `settings.json` absent, or present with no `telemetry` key (every host upgrading to this
build) → the setting is `block`; nothing is written to seed it.

**BC-5** — `settings.json` holds an unrecognised `telemetry` value (hand-edited) → the setting is
`block`, and one complete stderr line names the file, the key and the two accepted values. An unreadable
or non-JSON `settings.json` behaves as it already does on that host — no traceback, no new failure mode,
and no widening of the R-25 family.

**BC-6** — A user `override.json` that `$replace`s `dns.rules` → the user's document wins and the reject
rule can be removed by it; the documented contract, and nothing here defends against it.

**BC-7** — A user `override.json` inserting a rule **before** the reject rule that routes one listed
name to a resolver → that name resolves and every other listed name stays rejected; this is the per-name
exception recipe of FR-9 and both READMEs carry it.

**BC-8** — A user `override.json` inserting the user's own reject rule before the `clash_mode: Global`
rule → the user's names are rejected in both settings states, and under `block` the shipped names are
rejected too. This is the recipe that must work under `allow` as well, which is why its anchor is a rule
`sc` emits unconditionally.

**BC-9** — A name that ends with a listed name's characters without a label boundary (the classic
false-positive shape, e.g. a name formed by prefixing a listed name with letters rather than a dot) →
resolves exactly as it does before this task, in all three modes.

**BC-10** — An AAAA query, or a type 64/65 query, for a listed name while AAAA suppression is in effect
→ answered by T-16's suppression rule with an empty `NOERROR`, not by the reject rule with `NXDOMAIN`.
Both are immediate, both issue no upstream query, and this ordering is required, not incidental: T-16's
rule is unconditional-by-type and must keep the first position (FR-11). With suppression not in effect,
an AAAA query for a listed name is rejected by FR-3 like any other type.

**BC-11** — A listed name that is also a member of the predefined hosts table (reachable only through a
user extension) → the hosts rule answers it, because FR-4 places the reject rule after it; `sc`'s own
DoH bootstrap cannot be broken by extending the list.

**BC-12** — `sc telemetry` with an argument outside `block|allow|show`, in any letter case → the
argument is lower-cased like every other `sc` subcommand's, and an unrecognised one exits non-zero
naming the three accepted values without writing anything. `on` and `off` are unrecognised values and
take exactly this path (Q-7).

**BC-13** — Upgrade of an existing host: `config.json` in the pre-T-17 shape plus a drift record → the
first `sc reload` succeeds with no hand-editing of any file under `/etc/sing-box`, prints no drift
warning, leaves a record matching the new file, and a second immediate `sc reload` is silent too. The
host starts rejecting listed names at that reload, by FR-6's default; the changelog and both READMEs
are what announce it.

**BC-14** — A host where an application depends on a listed name and breaks → the recourse is stated and
reachable without editing `bin/sc`: `sc telemetry allow` for the whole list, or the BC-7 recipe for that
one name. Both are in both READMEs alongside the way to recognise a rejected name.

**BC-15** — The real `sing-box` 1.13.15 cannot express "answer `NXDOMAIN` immediately with no records
and no upstream query" → the shortfall is reported as a finding in `02_SOLUTION_DESIGN.md` naming what
could not be expressed and what was measured, and no substitute that drops the query silently is
shipped; a silently dropped query is indistinguishable from the network failure this task must not
imitate.

**BC-16** — `sc telemetry show` on a host with no `config.json`, no nodes, or a stopped service →
prints the setting, its meaning and the list, itself writes nothing, performs no service-affecting
action, and exits 0. The no-write property belongs to `cmd_telemetry()`, not to the command:
`main()`'s start-up path runs for `sc telemetry` exactly as for every non-`doctor` command, so the
command creates `/etc/sing-box`, seeds `nodes.json` and `settings.json`, and persists a Clash API port
on a host that has recorded none. That path is unchanged by this task, and no user-facing or stage text
states that `sc telemetry show` is write-free as a command.

**BC-17** — Two `sc` invocations at once → unchanged from today: no lock exists, and `settings.json` is
written exactly as it is written today.

**BC-18** — Any new output stream that is not a terminal → one complete line per fact, no carriage
return, no intermediate state.

## Acceptance criteria

Class **[B]** = behavioural: it observes the user-visible outcome of a real resolver in a real sing-box
process. Class **[S]** = structural: it pins the artifact, the code or the documents. Every **[B]**
criterion declares its control kind — **[D]** defect-reproducing (the HEAD run must exhibit the defect)
or **[A]** agreement (the HEAD run must produce the candidate's outcome) — and AC-B7 binds it.

| id | criterion | class | verification |
|---|---|---|---|
| AC-B1 | With the setting at `block`, a listed name and a subdomain of a listed name are each answered `NXDOMAIN` with 0 records within 100 ms, and neither stub resolver records the query. **[D]** — the HEAD run resolves both names and a stub records them | [B] | Second, unprivileged sing-box from the emitted document with the TUN inbound replaced by a `direct` inbound on `127.0.0.1`, its own cache path and Clash port; `remote_dns` and `direct_dns` repointed at two local stub resolvers; queries driven with `dig @127.0.0.1 -p <port>` and timed |
| AC-B2 | AC-B1 holds with the fixture instance in clash mode `global` and in clash mode `direct`. **[D]** — the HEAD run resolves the name in both modes | [B] | As AC-B1, mode set through the **fixture's own** Clash API, never the live one |
| AC-B3 | After `sc telemetry allow`, the same name resolves normally and reaches the same stub it reaches at HEAD, in all three modes. **[A]** | [B] | As AC-B1, document regenerated after the setting change; stub receipt compared against the HEAD run. This run is also the non-vacuity proof that the rig can observe a *resolved* answer |
| AC-B4 | A BC-9 near-miss name, a domestic name, a `geosite-google` name and a name matched by no DNS rule are each answered by the same stub as at HEAD, in all three modes × both rule-set states. **[A]** | [B] | As AC-B1, both stubs instrumented, **6 combinations per probe name (3 modes × 2 rule-set states), 24 in total across the four names**, compared against a HEAD-clone run of the identical fixture; the no-rule probe name is not a `.test` name. *(PM amendment at delivery per RES-9 / finding F-9: this column originally read "24 combinations compared per name", overstating the count fourfold. Stage 6 ran and reported it as corrected here — 24 in total.)* |
| AC-B5 | With all four rule-sets unusable, and separately with every node outbound accepting and never answering, a listed name is still answered `NXDOMAIN` within 100 ms. **[D]** — the HEAD run resolves it or leaves it unanswered, never `NXDOMAIN` | [B] | As AC-B1 with the fixture rules directory emptied, and with the `proxy` outbound pointed at a listener that accepts and never answers |
| AC-B6 | The two documented override recipes work through the real binary: (a) a user rule added before the `clash_mode: Global` rule rejects the user's own name — **[A]**, HEAD rejects it too; (b) a user rule added before the shipped reject rule restores exactly one listed name while every other listed name stays rejected — **[D]**, at HEAD there is nothing to except and the name resolves anyway | [B] | As AC-B1 with an `override.json` in the fixture root carrying the recipe verbatim from `README.md` |
| AC-B7 | Every one of AC-B1 … AC-B6 has a control run of the identical fixture on a pristine HEAD clone, classified as **[D]** or **[A]** before the run. A run whose control does neither is reported as **inconclusive**, never as a pass, and a behavioural criterion is never replaced by an artifact check | [B] | The control runs, recorded verbatim in `06_TEST_REPORT.md` |
| AC-1 | With `block`, the emitted document contains exactly one reject rule, answering `NXDOMAIN` with no records, carrying every listed name and no `rule_set` key | [S] | Read the emitted document |
| AC-2 | Index relation over the emitted `dns.rules`, in all four combinations of {`block`, `allow`} × {all rule-sets usable, none usable}: the reject rule's index is greater than the predefined-hosts rule's and strictly less than both `clash_mode` rules' and than every rule whose `server` is `remote_dns`; T-16's suppression rule keeps index 0 | [S] | Index comparison over the emitted array in each state |
| AC-3 | Each of `{"clash_mode": "Global"}`, `{"clash_mode": "Direct"}` and the README's documented reject-rule anchor matches **exactly one** element of the emitted `dns.rules`, in every state in which that rule exists | [S] | Subset-equality match count per anchor, four states |
| AC-4 | With `allow`, the emitted `dns.rules` is byte-identical to the document the pre-T-17 build emits for the same inputs, in all six AC-5 states | [S] | Differential `generate_config()`, HEAD clone vs candidate, **same** fixture path |
| AC-5 | The emitted document passes the **real** `sing-box check` in each of: 0 nodes, 1 node, 3 nodes, `block`, `allow`, all rule-sets unusable | [S] | `sing-box check -c <fixture>` on the installed binary |
| AC-6 | Exactly one definition of the name list and exactly one definition of the effective setting exist, and every consumer calls them | [S] | Read the diff; deletion test on the second caller of each |
| AC-7 | `DIRECTIVES`, `_directive_of`, `_anchor_index`, `_apply_directive`, `_merge`, `_load_override` and `_filter_rules` are byte-identical to HEAD | [S] | `ast` extraction and byte comparison, not `grep` |
| AC-8 | `generate_config()` gains no configuration literal and no fourth key in its three-key array guard; `bin/sc` gains no new module-level path, no new wait constant and no non-stdlib import | [S] | Read the diff; `ast` scan for new module names and `timeout=` arguments |
| AC-9 | The list holds at most 24 names, every name carries its one-line source justification, and no member is an update, activation, licensing, authentication, push-delivery, CDN-content, captcha or security-feature endpoint | [S] | Read the list against FR-1 and against `02_SOLUTION_DESIGN.md`'s per-name evidence table |
| AC-10 | `sc telemetry block\|allow\|show` each exit 0 in both languages; `show` prints the setting, its meaning and every listed name, one complete line each, with no `\r` | [S] | Six `main()`-driven runs in a redirected fixture, `lang` seeded in the fixture `settings.json` |
| AC-11 | `cmd_telemetry()` in its `show` form writes no file, issues no network request and performs no service-affecting action. Scoped to that function: `main()`'s start-up path runs for `sc telemetry` as for every non-`doctor` command, and its writes are neither counted against this criterion nor claimed absent | [S] | mtime witness over the fixture root with `cmd_telemetry()` driven directly; shimmed `systemctl`/`rc-service` record no invocation |
| AC-12 | A `sc telemetry <value>` that does not change the persisted setting performs no service-affecting action and prints the FR-8 line naming `sc reload`; one that does change it regenerates, applies it, and the new document reflects it | [S] | Shims plus `config.json` mtime, both directions; a non-vacuity control shows the same witness firing on the changing run |
| AC-13 | An absent `settings.json`, an absent `telemetry` key and an unrecognised `telemetry` value each yield `block`; the unrecognised value yields exactly one stderr line naming file, key and the two accepted values, in the run's language | [S] | Fixtures in both languages, stderr line-counted |
| AC-14 | `sc telemetry` with an argument outside the three accepted values, in mixed case and including `on` and `off`, exits non-zero, names the accepted values and writes nothing | [S] | Fixture runs with an mtime witness |
| AC-15 | On a BC-13 host the first `sc reload` succeeds with no hand-editing and prints no drift warning; a second immediate `sc reload` prints none either | [S] | Fixture reproducing the pre-T-17 `config.json` plus its digest |
| AC-16 | Every new key has a `zh` entry with an identical placeholder set; no new `zh` string contains `失败：`; no new namespaced key; the new keys are exactly Q-13's set | [S] | `ast`-extracted `TRANSLATIONS`, placeholder sets compared |
| AC-17 | Both READMEs carry FR-12's six items and stay line-for-line mirrors; `CHANGELOG.md` gains a Chinese entry stating the default and the escape | [S] | Read both files; heading/line-number skeleton comparison; grep for any claim of blocking beyond name resolution |
| AC-18 | Both READMEs' override recipes are copy-pasteable and correct: applied verbatim to a fixture, each yields the document AC-B6 measures | [S] | Extract the fenced blocks from both READMEs and run them through `generate_config()` |
| AC-19 | `HELP_EN` and `HELP_ZH` both carry the `telemetry` row at the existing column alignment | [S] | Read both blocks; display-column comparison against a neighbouring row |
| AC-20 | `python3 -m py_compile bin/sc` passes; the diff uses no syntax newer than Python 3.6 | [S] | Compile plus an `ast` scan of the diff |
| AC-21 | `bash .harness/scripts/verify_all.sh` ends with no FAIL against the 17/0/0/1 baseline; any doc-size WARN that clears on archive is predicted before code is written | [S] | Run it |

## Non-functional requirements

- **NFR-1 — Python 3.6 syntax floor, standard library only** (`.harness/rules/50-singbox-cli.md`).
- **NFR-2 — Bilingual parity is a correctness requirement**, not a nicety: `TRANSLATIONS` has no `en`
  table, so a key missing from `zh` prints English mid-sentence (R-19).
- **NFR-3 — Permitted diff:** `bin/sc`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`,
  `docs/dev-map.md`, plus this task's stage documents. Nothing else.
- **NFR-4 — `settings.json` is not a credential document.** It keeps being written the way it is
  written today; nothing routes it through `_write_private()`.
- **NFR-5 — The document does not grow without bound.** At most 24 names (FR-2), one rule, and no
  measurable added cost to `sc reload`; `sc telemetry show` performs at most one local read, no network
  access and no new wait.
- **NFR-6 — Verification never touches the live system.** Every harness neutralises the import-time
  auto-elevate (`docs/dev-map.md`, the recipe), never drives `_init_files()`, never writes under `/etc`
  or `/var/lib`, never invokes `/usr/local/bin/sc`, sets `SYSTEMD = OPENRC = False`, issues no
  `PUT`/`PATCH`/`DELETE` to the live Clash API, and uses
  `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` as the service witness, never
  `is-active`. Every second sing-box runs unprivileged with no TUN inbound, its own cache path and its
  own Clash port; a differential run uses the **same** fixture path on both revisions and a **clone**,
  never a `git worktree`, for the pristine baseline.
- **NFR-7 — Behavioural-fixture facts that invalidate a measurement if ignored:** `{"action": "sniff"}`
  must stay ahead of the `hijack-dns` rule or a `direct` inbound forwards the DNS packet to itself in a
  silent loop; `route.default_domain_resolver` must stay present or 1.13.15 fails `check` outright;
  `dig … ANY` uses TCP and measures the harness rather than the document; a `.test` probe name is
  matched by `geosite-private` and is not a no-rule-class name.
- **NFR-8 — A behavioural criterion without a control is not evidence.** AC-B7 is binding on stages 4
  and 6: each behavioural criterion declares its control kind in advance, and a green run whose control
  neither reproduces the defect nor agrees is reported as inconclusive. This is R-22's lesson applied.
- **NFR-9 — One complete line per fact on every new output**, on stdout for results and on stderr for
  warnings, per the project's stream split.
- **NFR-10 — No shipped surface claims more than is measured.** No README, changelog, help or runtime
  string may state or imply that this task blocks telemetry carried over a client's own encrypted
  resolver, over an IP literal, or by any path that does not traverse this document's DNS rules.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Does T-17 claim R-16 (the merge's type-mismatch vocabulary)? | **No**, on three reasons of T-17's own. (a) T-17 creates no reachable case where the mismatch is silent: the only array it touches is `dns.rules`, and a bare object landing there is caught by `generate_config()`'s three-key array guard with a sentence naming the key, before any write and any service-affecting action. (b) T-17 adds no code that indexes a composed array, so the guard needs no fourth entry. (c) Most decisively, **R-16 would not serve T-17's own user-extension case even if claimed**: FR-9's need is to *extend a list nested inside an array element*, which requires element addressing — a capability R-16 does not provide and which the documented `"0"`-key boundary explicitly denies. FR-9 is discharged instead by making the shipped rule uniquely anchorable, which the five existing directives already express. R-16 stays open and unclaimed, with its README obligation. |
| Q-2 | What is "common telemetry", on what criterion, from what source, and how large? | **A curated literal list inside `bin/sc`, at most 24 names, admitted by FR-1's two-clause criterion and covering FR-2's four classes.** The criterion is the contract; membership is enumerated with per-name evidence in `02_SOLUTION_DESIGN.md` and audited at the gate (AC-9), and every name carries its justification in the source and in both READMEs, so nothing about the list is opaque to the user whose traffic it changes. Candidate members and the sources considered are in `01_RATIONALE.md`; a name whose purpose cannot be evidenced at stage 2 is not shipped. |
| Q-3 | A `geosite` category instead of, or alongside, a literal list? | **Neither: no rule-set is used.** A DNS rule carrying a `rule_set` tag is deleted by `_filter_rules` on a degraded host, so the reject list would vanish exactly where the user is least able to notice — the trap T-16 designed around. A fifth `.srs` also adds a download, a digest, a degradation state, an update path and a size class (an ads/tracking category is orders of magnitude larger than 24 names and admits members FR-1's second clause excludes), which is the "new machinery" this task's goal forbids. |
| Q-4 | What does "reject" mean observably, and is it distinguishable from a network failure? | **An immediate `NXDOMAIN` with no records and no upstream query** (FR-3). It is distinguishable on both axes a user can see: it arrives in milliseconds instead of at the client's own timeout, and it carries an rcode instead of no answer at all. A dropped or black-holed query is rejected as the mechanism precisely because it is *indistinguishable* from the failure mode T-16 measured sing-box already inflicts at its fixed 10 s deadline — the loudness through-line forbids shipping a second thing that looks like a broken network. Sinkholing to `0.0.0.0` or `127.0.0.1` is likewise rejected: it converts a name failure into a connection failure at a later, less legible layer. |
| Q-5 | T-16 chose empty `NOERROR` over `NXDOMAIN` for suppression. Why the opposite here? | **Because the two rules mean opposite things about the name.** T-16's rule denies one *query type* while the name itself is legitimate, so an `NXDOMAIN` there would poison the negative cache for the whole name including its A record — the reason Q-5 of T-16 rejected it. T-17's rule denies the *name*, so a denial that covers the whole name is the intent rather than the damage. This is a distinction, not a contradiction, and BC-10 fixes what happens where the two rules overlap. **PM amendment at delivery, per gate condition C-7 (finding F-11):** this answer originally read "caching the denial for the whole name is the intent", which asserted downstream client caching that **was never measured**. What the PM-commissioned probe did measure is that the reply carries `AUTHORITY: 0` and **no SOA record**, so RFC 2308 gives a downstream resolver no MINIMUM from which to derive a negative TTL; whether any client caches it is unknown and unclaimed. The decision above is unaffected — it stands on the semantic ground that the rule denies the **name**, not a **type**, which needs no caching claim. K-12 forbids the claim on every shipped surface and in every stage document. |
| Q-6 | Where does the reject rule sit, and what do `global` and `direct` users observe? | **Before both `clash_mode` rules and after the predefined-hosts rule; a listed name is rejected in all three routing modes** (FR-4). This overrules the field report's stated slot ("after `clash_mode`, before the routing rules"), which T-14 and T-16 left expressible without adopting (T-16 Q-13 states no opinion). The reason is that the emitted `dns.rules` has two layers — rules that *answer here* and rules that *choose a resolver* — and `clash_mode` belongs to the second: it says which path, never whether. Placing the reject rule among the resolver-selection rules would make `sc mode global` — the mode people switch to when something is already broken — silently revoke a standing privacy decision the user never touched, which is the silent scope change this project's discriminator rejects. The cost is stated rather than hidden: mode is *not* an escape hatch for a broken application; BC-14's two recourses are, and both READMEs carry them. |
| Q-7 | What is the toggle's surface, its default, and what does a fresh install do? | **`sc telemetry block\|allow\|show`, defaulting to `block`.** `block` is the value of a host that has never set it (FR-6), so a fresh install and an upgraded host behave identically and `_init_files()` is unchanged; an upgraded host starts rejecting at its next `sc reload` (BC-13). The values are `block`/`allow` rather than `on`/`off` because a noun naming the *subject* being blocked reads backwards under `on`/`off` — `sc telemetry off` could mean either "block it" or "disable this feature", and a wrong guess silently does the opposite of the user's intent. `on` and `off` are therefore unrecognised values that exit non-zero naming the accepted three (BC-12), which is loud rather than ambiguous. The values are language-neutral, so `sc lang` cannot move them. |
| Q-8 | Is the new key seeded into `settings.json`? | **No.** Absence *is* `block` (BC-4), which keeps `_init_files()` and the installer unchanged and makes the upgrade path one line of documentation rather than a migration. |
| Q-9 | Does `sc telemetry <value>` restart the service? | **Only when it changes the persisted setting** (FR-8) — an unconditional restart drops every live connection for a command that frequently changes nothing, the defect T-10 removed from `sc update-rules`. The no-op line additionally names `sc reload`, because the one state where "nothing changed" is misleading is a document generated before the setting existed; that is R-24's lesson applied here at the cost of one string, and it makes no claim about, and no change to, `sc ipv6`. |
| Q-10 | Can a user extend the list, and does the extension survive `sc reload`? | **Yes, through `override.json`, with the five directives that already exist** (FR-9, BC-8): the user adds their own reject rule before the `clash_mode: Global` rule, which `sc` emits in both settings states, so the recipe works whether the shipped list is on or off. Extending the shipped rule's own name array in place is **not** expressible and is not required — a second rule is equivalent in effect, since the DNS chain matches in order and both rules answer the same way. Both READMEs carry the recipe verbatim and AC-18 keeps it copy-pasteable. |
| Q-11 | What is the user's recourse when a listed name breaks an application, and how do they learn about it? | **Two recourses, both documented and both surviving `sc reload`:** `sc telemetry allow` disables the whole list, and a user rule inserted before the shipped reject rule restores exactly one name (BC-7). They learn about them from both READMEs, the changelog entry, the help row, and `sc telemetry show`, which prints every listed name — a user debugging a broken application can see whether the name they are chasing is on the list without reading the source or the generated document. FR-12 additionally states how a rejection *looks*, so the symptom leads to the right page. |
| Q-12 | What happens to types 28/64/65 for a listed name? | **T-16's suppression rule answers them first** when it is in effect (BC-10): an empty `NOERROR`, not `NXDOMAIN`. Both are immediate and neither queries upstream, so the user-visible outcome — no address, no delay, no leak — is the same; the difference is stated so that a measurement of an AAAA query against a listed name is not read as a defect. T-17 does not move, alter or duplicate that rule (FR-11). |
| Q-13 | What is the exact bilingual text of every new user-facing string? | **These six, en key → zh, placeholders identical in each pair, none containing `失败：`.** · `"Telemetry name rejection → {val}"` → `"遥测域名拦截 → {val}"` · `"Listed names are answered \"no such domain\" locally; nothing is asked upstream"` → `"名单内的域名在本地直接返回「域名不存在」，不会向上游查询"` · `"Listed names resolve normally"` → `"名单内的域名正常解析"` · `"Error: argument must be one of block / allow / show"` → `"错误：参数必须是 block / allow / show 之一"` · `"{path}: telemetry must be block or allow — using block"` → `"{path}：telemetry 必须是 block 或 allow —— 已按 block 处理"` · `"Nothing changed — the sing-box service was not touched; run \`sc reload\` to apply this setting to a configuration generated before it"` → `"设置无变化 —— 未改动 sing-box 服务；若当前配置生成于该设置之前，请运行 \`sc reload\` 使其生效"`. Reusing an existing key is permitted, and required, where its text already says exactly this — `"Configuration regenerated; sing-box restarted"` and `"Reload failed"` both exist. No seventh string ships. |
| Q-14 | Does T-17 block anything at the route layer? | **No** (out-of-scope item 2). A route-level `reject` would need an address set this task does not have, would block by IP rather than by name, and would put a second opinion about "is this telemetry" in the document — the duplicated-judgment seam rule 85 forbids. The list is a name list, and NFR-10 forbids any text implying otherwise. |
| Q-15 | Does this document's schema hold everything this analysis produced? | **Yes.** Evidence, measurements, the related-task survey and the candidates each question beat are in `01_RATIONALE.md`; the bilingual string table is held by Q-13, and the two glossary terms this task coins travel to the PM as a residual rather than to `CONTEXT.md`, which lies outside NFR-3's permitted diff. No unit needed a section this schema does not declare. |

## Verdict

READY
