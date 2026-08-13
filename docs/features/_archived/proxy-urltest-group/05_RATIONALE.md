> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Method, and its one limit

This review is a source read. My tool set is `Read`, `Glob`, `Grep` — no shell, so no
`git diff`, no `python3`, no harness re-run, and (per the dispatch's live hazard)
`bin/sc` was never executed or imported. Three consequences worth stating plainly:

1. **Frozen-set byte-identity could not be measured**, only corroborated. What I did
   instead: read each frozen region at source and compare it against the HEAD shape the
   upstream contracts quote or anchor — `01 §1.1` E-1 quotes HEAD's selector verbatim
   (`type/tag/outbounds/default/interrupt_exist_connections`, matching `bin/sc:1435-1442`
   key for key); `03` dimension 3 anchors `_resolve_node` at HEAD `:1564-1584` (21 lines;
   `bin/sc:1700-1720` is 21 lines with the same three exits), `clash_api` at HEAD
   `:1536-1550` (15 lines; `bin/sc:1625-1639` is 15), the drift ordering `:1502` before
   `:1506` (now `:1591` before `:1595`), and the five `ls.*` keys at `:174-178` (now
   `:183-187`, intact, with the new key placed *after* them behind a comment). Nothing
   contradicts the developer's claim; nothing here proves it byte-wise. RES-2.
2. **Every "real binary" and "179 assertions" claim is evidence I read, not evidence I
   reproduced.** I marked those ✅ in the coverage table with the evidence class named,
   because re-running them is QA's stage and duplicating it here would add no independent
   information.
3. **Where I could substitute an independent check for a re-run, I did** — the `sing-box`
   symbol grep below, and the by-construction arguments for AC-5 and AC-9.

## Why CR-1 is MINOR and not MAJOR

`stored_delays()` is exactly what K-12 asked for: six `isinstance` gates, no `try`, no
`except`, `bool` excluded explicitly, `0` excluded, and absence rather than fabrication on
every rejected shape. I tried to break it from the body side and could not: `body` non-dict
→ return; `proxies` non-dict → return; a non-dict entry → `continue`; a non-list or empty
`history` → skipped; a non-dict last element → skipped; `delay` a `str`, a `float`, `True`,
`0`, or absent → skipped. `history[-1]` is guarded by the `and history` at `:1685`. The
function is total.

The raise is one frame up. `clash_api()` (`bin/sc:1634-1639`) wraps
`urlopen` → `read().decode()` → `json.loads(text)` in a `try` that catches
`URLError`/`HTTPError` only. A refused connection, a DNS-less loopback failure, a timeout
and any 4xx/5xx are all `URLError`/`HTTPError` subclasses and return `None` — which is why
V-15's "connection refused" case passes and why BC-9's first three states are genuinely
safe. The uncovered state is the fourth: **something that is not sing-box answering 2xx on
that port**. `json.loads("<html>…")` raises `json.JSONDecodeError` (a `ValueError`), and a
binary body would raise `UnicodeDecodeError` at `.decode()` one line earlier. Neither is
caught anywhere between there and `main()`.

Three reasons it is MINOR:

- **Reachability is compound.** `is_running()` must be true (so sing-box is up) *and* the
  persisted Clash port must be held by a foreign HTTP server — which requires sing-box to
  have been separated from that port first (an `override.json` that removes or moves
  `experimental.clash_api.external_controller` — the exact hazard `README.md:269` already
  warns about — or a hand-edited `settings.json`). If nothing listens, the socket is
  refused and the existing handler wins.
- **It is not new, and not this task's to fix.** `cmd_status:1877` calls `clash_api` on the
  same port at HEAD with the same exposure. `sc doctor` escapes only because
  `cmd_doctor:2202-2209` isolates each probe. `clash_api()` is in the frozen set (AC-28)
  and K-12 forbids the local `try`/`except`, so there is no edit the developer could have
  made that satisfies both the constraint and the gap. Routing this back to the developer
  would ask for a constraint violation.
- **Nothing is corrupted.** The failure mode is a traceback on a read-only command, on a
  host already misconfigured in a way `sc` documents as user-owned.

What I would *not* soften: the CHANGELOG (`CHANGELOG.md:7`) and the READMEs promise "API 不通
或返回内容异常时表格照常打印、不会抛 Python 报错" / "with the service stopped `sc` issues no query
at all". The first clause is wider than the code for one body class. That is a sentence to
remember if the follow-up row ever lands, not a reason to hold the merge.

## Why CR-2 is real but harmless

Q-2 permitted either `cmd_rm` shape and justified the kept guard with: "the
`reload_or_restart()` `cmd_rm` already calls reaches the I-4 repair … and persists before
anything downstream can fail". I traced the ordering inside `generate_config()`:

- `:1543` `_load_override()` — can raise `OverrideError`
- `:1545-1547` load nodes
- `:1552` `ruleset_report()`
- `:1560-1564` the repair and its `save_nodes`

So the override parse is **upstream** of the repair, not downstream. The comment at
`:1539-1542` is candid about exactly this ordering ("a merge-time fault still lands after
the active-node rewrite below") — merge-time faults do land after, but *parse*-time faults
land before. With a malformed `override.json`, `sc rm <last node>` therefore ends with
`nodes.json` holding `{"nodes": [], "active": "auto"}`.

Consequences I checked: `cmd_ls` takes the zero-node early return at `:1742` and prints
today's line; `cmd_now` prints `auto`, which is momentarily untrue but is HEAD's behaviour
for any stale value; no document is emitted, so no AC about the emitted document can be
violated; the next successful `generate_config()` repairs and persists. HEAD has the same
class of deferral for a hand-edited stale `active`. Hence MINOR, no action.

## The `cmd_rm(active=None)` inconsistency — checked, genuinely outcome-neutral

`04`'s own "open issues" flags that `_valid_selection` is called with `None` from `cmd_rm`
(`bin/sc:1834`) and with the loaded value elsewhere, and asserts both are correct. I did not
take that on faith; the guard at `:1832` means the call happens **only** when
`active == removed_tag`, so:

- **Ordinary node removal.** After the list comprehension at `:1831`, `active` (the removed
  tag) is no longer in `node_tags`, so clause 1 fails for both arguments; clause 2 needs
  `active == AUTO_TAG`, false for a node tag; both arguments fall to clause 3/4 and agree.
- **The one case where the arguments differ in kind** — a K-6 legacy host whose node is
  literally tagged `auto`, and the user removes *that* node. Then `active == "auto"` and
  the removal makes the group emissible. Passing `None`: clauses 1-2 fail, clause 3 returns
  `AUTO_TAG`. Passing `"auto"`: clause 1 fails (no node holds it any more), clause 2
  succeeds (`active == AUTO_TAG` and the group is now emitted) and returns `AUTO_TAG`.
  Same value, by two different clauses. This is the case a reader would most expect to
  diverge, and it does not.
- **Zero remaining nodes.** Both yield `None`.

So the inconsistency is cosmetic and the developer's "a future refactor could pass the
loaded value in all three sites without changing any outcome" is correct as stated. Not
filed as a finding — filing it would be filing a preference.

## AC-5 and AC-9, argued rather than fixtured

**AC-5.** With `nodes == []`: `:1414` `auto = _auto_group_emitted([])` = `bool([]) and …`
= `False`. `:1438` becomes `[] + [] + ["direct"]`. `:1448` becomes
`[selector] + [] + [] + [direct]`. `:1440` calls `_valid_selection(active, [])`, whose
clause 1 fails (`x in []`), clause 2 fails (`_auto_group_emitted([])` is false), clause 3
fails likewise, and clause 4 returns `None` because `node_tags` is falsy — so `or "direct"`
yields HEAD's literal. The remaining question is whether `active` can be non-`None` at that
point: it cannot, because `:1560-1564` runs first and `_valid_selection` returns `None` for
*every* input when `node_tags` is empty. K-5's "by construction" claim is exact, and V-1's
whole-document byte comparison is a confirmation rather than the proof.

**AC-9.** `:1561` is `if repaired != active`. `_valid_selection` is idempotent —
`f(f(a, t), t) == f(a, t)` for every branch, since each return value is either an element of
`node_tags` (clause 1 on the next call), `AUTO_TAG` with the group emitted (clause 2), or
`None` with no nodes (clause 4). So the N-times-unchanged property is structural, not a
fixture result.

## C-6: is the inference sound enough to rest an emitted-config decision on?

Yes, and I checked it two ways rather than accepting the transcript.

**Symbol presence.** A read-only content search of `/usr/local/bin/sing-box` for
`IsExternalConnectionFromContext|ContextWithIsExternalConnection|interrupt_exist_connections`
returns 8 matches. The context helpers exist as a *pair* (setter and getter), which is the
signature of a per-connection flag carried on the dial context, not of a config-key name.

**Semantics.** sing-box's `common/interrupt` group takes the option as the argument to
`Interrupt(interruptExternalConnections bool)`: with `false` it *skips* connections marked
external and closes the rest. So the option's effect is to **spare** external connections,
never to *enable* interruption of internal ones. That is the direction the developer's
claim needs, and it is the opposite of the direction F-3 feared. The DoH transport that
carries `remote_dns` is dialled by sing-box itself — no inbound context, so no external
flag — and it is dialled *through* the group (`detour: proxy` → the selector → the group),
so the group's own interrupt registry holds it. On re-selection it is closed and the
transport reconnects over the new member.

**What the inference does not establish**, and why it does not matter here: it says nothing
about *how long* the reconnect takes, and it rests on the installed v1.13.15 binary rather
than on an observed failover. Both are tolerable because the decision it supports is to
**change nothing** — the emitted document is identical either way, so being wrong costs a
slower DNS recovery, not a broken document, and V-4 did not need re-running. RES-4 records
the one observation that would retire the inference if QA ever reaches a live re-selection.

## Two smaller observations, deliberately not filed

- `04`'s Q-6 note says the zh header is "two display columns narrower than the en one". In
  the emitted line it is two columns *wider*: `f"{t('Delay'):>9}"` pads `延迟` (2 code
  points, 4 display columns) with 7 spaces, so the header text overhangs the 9-column data
  cells on the right. The gate accepted the misalignment either way and the column is last,
  so nothing shifts. Direction only; not worth a finding row.
- `stored_delays()` keys `delays` by whatever the API returns, so a node whose tag happened
  to collide with a Clash pseudo-entry would inherit that entry's history. `RESERVED_TAGS`
  already blocks `proxy`/`direct`/`auto`, and the remaining candidates (e.g. `GLOBAL`) carry
  no url-test history in this binary. Filing it would be inventing a rule.
