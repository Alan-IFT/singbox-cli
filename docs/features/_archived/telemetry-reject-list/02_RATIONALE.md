# 02 — Rationale · T-17 `telemetry-reject-list`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

Mandatory (`harness-kit:solution-architect` hard rule 5). Every row was read in the working tree before
the design was drafted; nothing here is inferred from a document.

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Insert one element at a named position in an emitted array | `$before` + `_anchor_index()` (subset equality, exactly-one-match or error) | `bin/sc:1222-1242`, `DIRECTIVES` `bin/sc:1089` | **Reuse as-is.** The comment at `bin/sc:1084-1088` states that `$before`/`$after` take an anchor rather than an index *because* two future overlays into `dns.rules` would collide — T-17 is the second of those two, so this is the capability being used for the purpose it was built for |
| Carry a shipped change into the emitted document as an overlay | `_dns_overlay()` (T-16) | `bin/sc:1562-1583` | **Copy the idiom, add a sibling.** Not an extension of it: one overlay object cannot carry two directives on the same array (`_directive_of`, `bin/sc:1206-1219`, rejects an object with two `$` keys), and the two rules need different positions. Different input, different failure mode — the same argument `docs/dev-map.md:57` makes about `_dns_overlay` vs `_runtime_overlay` |
| Read one settings key with a default and one loud line for a bad value | `_ipv6_setting()` | `bin/sc:1439-1465` | **Reuse the shape verbatim** (guard tuple, silent degrade, one stderr line for a present-but-invalid value). `_saved_clash_port()` (`bin/sc:312-317`) is the older precedent both follow |
| A `<value>`-style subcommand that persists, compares and only then applies | `cmd_ipv6()` | `bin/sc:2437-2476` | **Reuse the shape**, minus `ipv6_decision()` — T-17 has no host-derived input, so the setting is the decision and a second function would be a second name for one value |
| Compose overlays and apply the user's document last | `_compose()` + `generate_config()`'s two-step merge | `bin/sc:1382-1392`, `1765-1771` | **Reuse unchanged.** T-17 adds one list element; the user's `override.json` is still merged after, which is what makes both README recipes anchor against a document that already has the reject rule |
| Keep a shipped rule alive on a degraded host | `_filter_rules()` keeps any rule with no `rule_set` key | `bin/sc:902-907` | **Reuse by construction** — the reject rule carries no `rule_set`, exactly as T-16's I-7 does. This is also the whole of Q-3's argument against a `.srs` category |
| Bilingual output | `t()` + `TRANSLATIONS["zh"]` | `bin/sc:120-185` | **Extend with six keys**, reusing `Configuration regenerated; sing-box restarted` and `Reload failed` |
| Warning to stderr | `sys.stderr.write("⚠️  " + t(...) + "\n")` | `bin/sc:1463`, `_warn_degraded` | **Reuse the shape** for BC-5's line |
| A shipped list of names in the emitted document | the five domestic `domain_suffix` entries inside `CONFIG_BASE` | `bin/sc:1144-1145` | **Same technique, separate constant.** Those five are a *routing* decision (which resolver answers) and live in the base because they are unconditional; T-17's are an *answering* decision behind a toggle, so they cannot live in a static literal. Merging them would put two judgments in one array |
| An ordered tuple constant whose order is emission order | `RULESET_FILES` | `bin/sc:96-103` | **Reuse the pattern** for `TELEMETRY_NAMES`, including the comment that states why it is a tuple |
| A name list from a rule-set / geosite category | (none — and deliberately so) | `.harness/rejected-decisions.md` | Declined by Q-3 before this stage; `RS-4` records the fourth decline this stage adds |
| A merge capability for adding to a nested array inside an array element | (none found — R-16 does not provide it either) | — | Not built. Q-10 re-homes the need to a second rule; building element addressing for one recipe is the machinery the goal forbids |

## Why the owner's shape is already right (rule 85, and its counter-rule)

The pool's goal sentence says this should collapse to "data plus a toggle, not new machinery". It does,
and the honest way to show that is to count what the design adds against what already exists:

- **Data:** one tuple of 18 strings. No file, no format, no download, no digest, no degradation state.
- **Toggle:** one settings key, one reader, one command — each a copy of a shape shipped one task ago.
- **Reach into the document:** one overlay function using one existing directive and one existing anchor
  mechanism, plus **one changed line** in `generate_config()` (a third element in a list literal).

Nothing else. There is no new seam, because nothing varies across one: the "two adapters make a real
seam" test fails for every candidate abstraction here. A `_reject_overlay()` generalised over "lists of
names to answer locally" would have exactly one adapter; a shared `_setting_reader(key, values,
default)` factored out of `_ipv6_setting()` and `_telemetry_setting()` would have two — and is still
declined, because `_ipv6_setting()` is frozen by FR-11's spirit and by AC-7's neighbours, so the refactor
would edit a T-16 surface to save nine lines and would put two commands' failure text through one
parameterised sentence. Rule 85's counter-rule names that as over-building: the future edit it prevents
cannot be named.

The one place the design *does* exercise judgment rather than copy is the insertion anchor, and that is
the decision T-14's D-7 explicitly deferred to this task.

**Deletion test on the three new definitions.** Delete `TELEMETRY_NAMES` → the rule and `sc telemetry
show` both lose their content, and the "one definition" property of AC-6 is what makes them impossible
to drift apart. Delete `_telemetry_setting()` → two call sites must each re-derive absent-means-block and
each print their own bad-value line, which is precisely the duplicated judgment rule 85 forbids. Delete
`_telemetry_overlay()` → the rule would have to be built inside `generate_config()`, which is the
configuration literal AC-8 forbids. All three earn their keep by locality, not by size.

## Membership: how N-1…N-18 were selected, and what was excluded

The selection rule that produced the table, in the order it was applied:

1. **Vendor and role must be nameable in one line** (FR-2). A name I could not attribute to a vendor and
   a payload was not shipped.
2. **The endpoint's only possible role is reporting.** Preferred: a host whose *name* is its role
   (`telemetry.`, `metrics.`, `tracking.`, `ulogs.`, `vortex.`), or a domain that carries no user-facing
   web property at all (`demdex.net`, `app-measurement.com`, `scorecardresearch.com`). This is what makes
   a residual hostname uncertainty one-directional: a name that does not exist rejects nothing, and a
   name that does exist can only be a beacon.
3. **Apex vs host chosen by what else lives under the apex.** `telemetry.microsoft.com` is listed as an
   apex because Q-C measured that one dotless suffix covers `watson.`/`oca.`/`sqm.` and all three are
   diagnostics. `data.microsoft.com` is **not**, because `settings-win.` lives there. `umeng.com` is
   **not**, because U-Push lives there. That single test — "does blocking the apex take a functional
   sibling with it?" — decided every apex/host choice in the table.
4. **FR-1's second clause is a veto, applied last**, with the worked exclusions below.

**Excluded, with the reason** (each is a name a naive list would contain):

| Name | Why it is not shipped |
|---|---|
| `googletagmanager.com` | Sites gate content and consent flows on it; blocking it breaks pages (named in `01_RATIONALE.md`) |
| `analytics.google.com` | Also serves the Google Analytics console UI — blocking it disables a user-visible function of the product it belongs to |
| `omtrdc.net` | Adobe Target shares it with Adobe Analytics and delivers page content / A-B variants |
| `settings-win.data.microsoft.com` | Carries settings and update policy alongside diagnostics |
| `clients2.google.com` | Chrome extension updates share it with crash uploads |
| `connect.facebook.net` | Login widgets |
| `msg.umeng.com`, `mtalk.google.com`, `jpush.cn`, `getui.com` | Push delivery — excluded by FR-1 whatever their analytics role |
| Safe-browsing endpoints | A security feature |
| `doubleclick.net` and ad-serving domains generally | Ad *serving* is content, not identifier reporting; this task is not an ad blocker and NFR-10 forbids implying it is |
| `branch.io`, `appsflyer.com`, `app.adjust.com` | Attribution SDKs that also resolve deferred deep links — blocking them sends a user to the wrong page, a user-visible break |
| `sentry.io`, `bugsnag.com`, `mixpanel.com` | Dashboards for their own users share the apex, and none is dominant enough in consumer traffic to justify a narrowed host |

**Why the browser class has only two members.** Firefox is the one major browser whose telemetry
submission is on a dedicated endpoint. Chrome's equivalent traffic rides on endpoints that also carry
extension updates, variations/config and safe-browsing, all of which FR-1's second clause excludes — so
the honest outcome is a small class, not a padded one. Stating that is better evidence of having applied
the criterion than a longer list would be.

**Confidence.** Fifteen of the eighteen host strings are ones I can state first-hand. Three
(`telemetry-coverage.mozilla.org`, `ulogs.umeng.com`, `data.mistat.xiaomi.com`) are firm on vendor and
role and weaker on the exact host string; RS-8 files that for the gate rather than hiding it, and the
selection rule above is why the downside is bounded.

## Options compared, and why the chosen one won

**Anchor: `$before {"clash_mode": "Global"}` vs `$after {"server": "hosts_dns"}`.** Both put the rule at
index 2 today — the base's hosts rule and Global rule are adjacent — so the choice only matters against a
future edit to `CONFIG_BASE`. Chosen `$before` on the Global rule, because the *measured* failure (Q-D)
is what happens when the rule falls after a `clash_mode` rule: the listed name is not merely unblocked,
it is recorded by an upstream stub, in **both** non-`rule` modes. The BC-11 half ("after the hosts rule")
has no comparable failure — a listed name would have to be added to `sc`'s own DoH bootstrap table for it
to matter — and is verified as an index relation by V-3 rather than pinned by the anchor. Anchoring on
the *dangerous* boundary and asserting the other is the right way round.

**Rule shape: one `predefined` rule vs one rule per name vs a `reject` action.** One rule, because
nothing distinguishes the names from each other and 18 rules would be 18 chances for the index relation
to drift. `reject` is excluded by K-4 on three measured grounds (it answers `REFUSED` bare, drops
silently under `method: "drop"` — the shape BC-15 forbids — and its decoder accepts unknown fields, so a
typo in it is silent).

**Under `allow`: an empty overlay vs a conditional list element in `generate_config()`.** Chosen the
empty overlay (`{}`), because `_merge()` treats it as a no-op by iteration and `generate_config()` keeps
exactly one changed line with no branch. A conditional would put a second opinion about the setting
inside `generate_config()`, which is the one place T-14 removed configuration decisions from.

**`show` output: bare names vs name + class + vendor.** Chosen bare names. Q-13 closes the string budget
at six, and FR-13 makes that budget binding, so a per-name description would either ship untranslated
English mid-list (the R-19 defect NFR-2 calls a correctness bug) or need 18–22 new keys. The
justification the user needs is in both READMEs, where it is bilingual by mirroring. This is a genuine
tension with FR-7's phrase "one complete line per name, **in the user's language**", resolved toward
FR-13/Q-13 because that clause is a hard budget and a domain name is language-neutral; the gate should
confirm the reading. Recorded here rather than silently decided.

## Risks and mitigations

| # | Risk | Mitigation |
|---|---|---|
| R-1 | **A shipped name turns out to be functional** and an application breaks on a host the owner cannot debug. This is the only risk in the task that reaches the user's traffic. | The FR-1 veto and the apex/host test above; the exclusion table as evidence that the veto was actually exercised; two documented recourses that need no source edit (BC-14) and are measured end-to-end by V-27; the gate audits the table name by name (AC-9), which is a second reader before shipping |
| R-2 | **The rule lands after a `clash_mode` rule** through a future `CONFIG_BASE` edit, and the feature silently leaks in `global` / `direct` — measured as a real upstream stub receipt, not a theoretical gap (Q-D). | The anchor is `{"clash_mode": "Global"}`, so the rule cannot fall behind it without `_anchor_index` erroring loudly; V-3 asserts the index relation in all four states; the frozen set pins the base's `dns.rules` order with this reason attached |
| R-3 | **`answer` or a lowercase `rcode` slips into the rule** and it passes `sing-box check` while answering wrongly — `NXDOMAIN` *with* one record was measured to validate (Q-B). | K-2/K-3 state the exact byte-shape; V-2 asserts the absence of `answer` as an explicit key check rather than as a value check; V-22 observes `ANSWER: 0` at run, so an artifact-only pass cannot hide it |
| R-4 | **A `dig`-driven harness measures the harness.** `dig` costs ≈17.5 ms of startup and its default EDNS COOKIE defeats sing-box's upstream cache entirely (5 queries → 5 upstream lookups). | K-18 makes `+nocookie` mandatory and forces every latency claim to state the ≈82 ms real headroom; V-30 is written so that no caching claim is made at all |
| R-5 | **A green run proves nothing** because the fixture cannot resolve anything (T-15's R-22 failure, in mirror image). | AC-B3/V-24 is the non-vacuity proof (the same name resolving through a stub under `allow`); AC-B7/V-28 requires a classified control for every behavioural step, and an unclassified one is reported inconclusive |
| R-6 | **The list ages** and nobody owns re-checking it, so the artifact silently drifts from its own evidence table. | RS-7 files it as a pool row candidate at delivery; the per-name table in `02_SOLUTION_DESIGN.md` is the baseline a future re-audit diffs against |
| R-7 | **An upgrading host changes behaviour at its next `sc reload`** with no in-tool announcement (Q-7 forbids a first-run notice). | Changelog, both READMEs, the help row and `sc telemetry show`, which prints the whole list so a user debugging an application can see the name without reading source; BC-13/V-15 proves the reload itself is quiet and needs no hand-editing |
| R-8 | **Bilingual parity slips** on the six new strings; `bin/sc` has no automated parity gate (B.2 covers `install.sh` only). | V-16's scripted parity check over exactly Q-13's key set, run by the developer and again by QA |

## What this stage did not measure

Everything about `sing-box 1.13.15` above comes from the PM-commissioned probe (Q-A…Q-F); this stage
holds no shell and ran nothing. Two clauses are explicitly *not* facts and are treated as such in the
contract: whether any downstream client caches the `NXDOMAIN` (unmeasured — K-12 forbids the claim,
RS-2 carries the correction to `01`), and the exact host strings behind N-7, N-16 and N-18 (RS-8).
