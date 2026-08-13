> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## Verified good — what I read and confirmed

Every claim below was checked at the source, not inherited from either upstream document.

- **The premise correction (E-1).** `bin/sc:1356-1363` is a `selector` over `node_tags + ["direct"]` with `default: active or "direct"`. Stage 1's correction of the field report is right.
- **The repair predicate (D-6/K-7).** `bin/sc:1471-1475` is `if active not in node_tags: active = node_tags[0] if node_tags else None; nodes_data["active"] = active; save_nodes(...)`. The write is already inside the difference test, so K-7's "persist only when I-4's result differs from what was loaded" is a faithful generalisation, not a new rule.
- **The tag minter (K-3/AC-11).** `_unique_tag` at `bin/sc:1587-1593` has exactly one call site, `cmd_add` at `:1639`. Adding `RESERVED_TAGS` to the first-hit test yields `auto #2` for a fragment of `auto`, which is exactly what V-8 predicts.
- **The quiet upgrade (AC-18).** `_warn_drift()` is called at `bin/sc:1502` and the replacement write is at `:1506`; `_config_digest()` hashes the file on disk. Both sides of the comparison therefore describe the pre-replacement document and no change to the generated shape can move either. The frozen-set row for this is correctly stated.
- **AC-20/AC-21's mechanism.** `cmd_update_rules` regenerates only when `gained` and restarts only when `changed and CFG_PATH.exists()` (`bin/sc:2153-2167`), both driven by installed bytes rather than by the generated shape — so a differently shaped config genuinely cannot provoke a restart.
- **The API envelope (I-15).** Consistent with the project truth that `/proxies` serves a stored `LoadURLTestHistory` with `json:"delay"` and no `meanDelay`.
- **The document anchors.** `README.md:76-84` is `### Switch node`, `:279` is the `urltest support beyond selector` roadmap box, `CHANGELOG.md:3/:5` are `## [Unreleased]` / `### 新增`, `HELP_EN:2322` and `HELP_ZH:2379` are the `use` lines. `docs/dev-map.md:77-79` bans copying the namespaced-key defect and `:83-84` lists the three owner-directed timeouts, both exactly as D-13 and NG-6 read them.
- **The insight index.** No entry contradicts a design assumption. The one that comes closest — `check-i18n-parity.sh` being blind to a call site whose key is in neither table — does not fire, because I-14 puts `Delay` in the `zh` table and English is the key itself.

## Why AC-9 genuinely cannot clobber `active == "auto"`

Walking I-4 against the real code: with `active == "auto"`, ≥1 node and no node tagged `auto`,
`_auto_group_emitted` is true, so clause two returns `"auto"` unchanged; K-7's difference test is
false; `save_nodes` is not reached; `nodes.json` is byte-identical. Run N times, nothing moves.
This was stage 1's sharpest surface (D-6's parenthesis) and the design closes it with a total,
pure function rather than with a second condition at the call site — which is also what makes the
three auto-picks at `:1471-1475`, `:1641-1642` and `:1655-1656` collapse into one opinion. I found
no path by which a second opinion survives.

## Why K-14 is accepted on substance and only its falsifier is flagged

The mechanism K-14 rests on is standard sing-box behaviour rather than a guess: an outbound with no
`domain_strategy` does not resolve the destination locally, it hands the FQDN to the member's remote
server, and the compiled-in `missing domain resolver` string is the guard on the branch that *would*
resolve. The url-test probe dials the member's own dialer with the URL host as the destination, so
`dns.rules` — and therefore `remote_dns`'s `detour: proxy` — is never consulted. K-15's second branch
is a real safety net rather than rhetoric: `route.default_domain_resolver` is `{"server":
"direct_dns"}` (`bin/sc:1105`) and `direct_dns` (`:1073-1074`) carries no `detour`, so even a
counterfactual local lookup lands somewhere that is not the group. A third, independent reason
points the same way: `route.rules[0]` is `{"outbound": "direct", "process_name": ["sing-box"]}`
(`bin/sc:1108`). Three independent paths all terminate away from the group, so I did not treat
post-hoc falsifiability as the load-bearing element — which is why F-2 is minor and why C-3 permits
recording V-19 as not-run rather than demanding it be forced.

## Why K-6 was the right call to close in-design, and where the closure stops

Routing a one-line ruling back to stage 1 would have cost a round for a state stage 1 had already
half-reached in BC-7, and the *mechanism* the architect chose is right: I-3's second clause keeps the
document valid, `_valid_selection`'s first clause keeps the selection stable, `_resolve_node`'s exact
match keeps HEAD's behaviour, `sc rm` or a rename self-heals into the group seamlessly. Nothing here
is unsafe. What the architect could not legislate from stage 2 is the *user-facing* half: the
decision to say nothing is a requirements-shaped call, and it collides with the analyst's own
diagnosis in `§1.2` — the reported incident was expensive precisely because a host that silently
differed from its neighbours had to be found by comparing machines by hand. The sting is not the
missing group, it is that `Switched to: auto` is byte-identical in both worlds, so the surface the
user would consult to check actively confirms the wrong belief. I did not block on it: no config
breaks, no traffic moves unexpectedly, the affected population is small, and both halves of the gap
are closable inside stage 4's existing L-13/L-14 scope. Hence C-1 and C-2 rather than a route-back.

## On F-3, and on not proposing the fix

I deliberately state the tension and not its resolution. Both readings are defensible: I-13's
"a 51 ms improvement should not kill live connections" is sound for bulk traffic, and F-3's "the DoH
transport is the one connection whose survival defeats the purpose of switching" is sound for the
plane `§1.2` item 3 makes the headline. Which wins depends on how long a DoH transport through a
half-dead member takes to error out, which nobody in this pipeline has measured. C-6 therefore asks
for the case to be weighed and the answer recorded, not for a particular value.

## Feasibility, and the rollback column

The edit ledger is one CLI file plus four documents, three new module-level functions and six call
sites — a normal single-stage task for one developer, and `## Partition assignment` is correct that
this project is single-Developer. The cost centre is verification, not implementation: V-1 and V-10
need a pristine HEAD **clone** (a worktree turns A.1/A.2 SKIP), V-13/V-14/V-15/V-17 need a stub HTTP
server, V-4 needs the real binary, V-11 needs an upgrade fixture, and C-1/C-5 add two more fixture
states. Those five stub-server rows are one harness and should be built as one.

The rollback column is real rather than decorative, which is unusual enough to note. Step 3's claim
that a reverted build repairs a persisted `active == "auto"` is true at `bin/sc:1472-1475`, and U-1's
downgrade claim is the same mechanism seen from the installed side; because the config is regenerated
and never patched, no reverted step can leave a dangling reference behind. The one ordering detail
that matters — capturing the V-1 baseline *before* step 3, at the same fixture path — is stated in
the precondition column, which is where a developer will actually read it.
