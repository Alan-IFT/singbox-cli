> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Trigger record

- **T5.2 fired** (adjudicating DR-1 … DR-5, including DR-3's extension to a second `"unreadable"` site):
  `04_RATIONALE.md` opened. It carries the two measurements that forced DR-4/DR-5, the V-3 … V-36
  transcripts, and the round-2 transcript block (`:179-236`) with V-13(b), the extended V-18, V-20,
  V-21 and the V-24/CR-7 reconciliation.
- **T5.1 and T5.3 fired** (a design-fidelity finding on K-7's shape, CR-8; a risk finding on the
  duplicated FR-7 line, CR-4): `02_RATIONALE.md` opened. Its **R-8** (`:37`) already *accepts* the
  duplicate stderr line and states why, and its **R-9** (`:39`) states the intent K-7 was carrying.
  Both changed my severity: CR-4 is a NIT, not a defect, and CR-8 is a MINOR note rather than a drift
  charge.
- **T5.4 did not fire.** Every identifier I acted on (`L-`, `I-`, `K-`, `C-`, `DR-`, `AC-`, `RS-`, `M-`)
  is defined in a contract portion I read.

## Method, and its one limit

This review held **no shell in either round**. I read `bin/sc`, both READMEs, `CHANGELOG.md`,
`docs/dev-map.md` and the stage documents directly and walked the composition by hand. Consequences:

- AC-8 / AC-9 **byte-identity against HEAD could not be re-extracted by me.** I re-read every frozen
  symbol's position and shape in the working tree — `DIRECTIVES` `:1089`, `_directive_of` `:1196`,
  `_anchor_index` `:1222`, `_apply_directive` `:1245`, `_merge` `:1273`, `_load_override` `:1318`, all
  below the round-2 edit and therefore unshifted — and confirmed the three socket waits by reading each
  line in full: `:380` (`timeout=8`), `:1014` (`timeout=30`), `:1841` (`timeout=3`). Three call sites,
  three values, no fourth `timeout=` in the file. That is a *value* check on the current tree, not a
  *diff* check against HEAD; the diff half rests on V-8/V-9's `ast` transcript and on the PM's
  independent re-check. Recorded as RES-1.
- **The re-review scope I set could not be verified by `git diff` here.** What I could check, I did:
  the only new code region is `bin/sc:1487-1499`; `cmd_ipv6()` (`:2437-2476`), the three-key guard
  (`:1773-1782`), `CONFIG_BASE["dns"]` (`:1118-1150`), `_filter_rules()` (`:895-910`), both help blocks
  and the ten translation pairs are unchanged in shape and value, and every line number below 1491 is
  unshifted while everything above it moved by exactly the 9 lines of the CR-5 clause — which is itself
  corroboration that no other region of `bin/sc` was touched. NFR-3's confinement across *files* still
  rests on `04:49`'s `--numstat` record and the PM's `git` check.

## CR-1: why the corrected text clears C-4, and where it stops short

C-4's prohibition is precise: "no text may claim `sc ipv6 show` is write-free **as a command**". The
three corrected texts do the opposite — they state the writing path outright:

> `sc ipv6 show` only reports what the setting is and what it decides: it never changes the `ipv6`
> setting, regenerates no config and touches the service in no way — but, like every command except
> `sc doctor`, it still runs the ordinary start-up path first, which on a fresh host creates
> `/etc/sing-box` and `/var/lib/sing-box`, seeds `nodes.json` / `settings.json`, and probes and
> records the Clash API port.

Each surviving claim is true of the whole command, not merely of `cmd_ipv6()`:

- *"never changes the `ipv6` setting"* — `cmd_ipv6()`'s `show` arm returns at `:2462` before any write,
  and `_resolve_clash_port()` re-loads and **merges** (`:357-364`) rather than replacing, so a recorded
  `ipv6` value survives it. The developer's decision to write this instead of "writes nothing" is
  correct and load-bearing; the general form would have been false.
- *"regenerates no config"* — the start-up path calls `_init_files()`, `_load_lang()` and
  `_resolve_clash_port()`; none of them touches `config.json`.
- *"touches the service in no way"* — nothing on that path invokes `restart_service()` /
  `reload_or_restart()`.
- The changelog's `不发网络请求` is deleted outright, correctly: `_free_port()` (`:317-326`) binds
  loopback sockets. A repository-wide grep finds the phrase nowhere.

**What CR-10 is.** The write is qualified "on a fresh host", and the set of hosts on which
`_resolve_clash_port()` writes is strictly larger: `_saved_clash_port()` returns `None` whenever
`settings.json` records no `clash_api_port`, or one outside 1…65535, or cannot be parsed at all — and
the branch's own comment (`:357-359`) names installs predating the port auto-probe as "the exact hosts
this branch runs on". In the malformed-file case the merge falls back to `settings = {}` (`:362-363`)
and the file is rewritten to a single key, discarding whatever else it held. So a user on an upgraded
host who reads the sentence as "my host is not fresh, therefore nothing is written" is misled. This is
the same family as CR-1 at a much smaller radius, and the unqualified clause that precedes it ("it
still runs the ordinary start-up path first") is what keeps it out of C-4's prohibition — hence MINOR,
not a re-opened MAJOR. One clause fixes all three texts.

## CR-2: why the corrected sentence is no wider than a step

> On a host that cannot use IPv6, an AAAA lookup for a name this config sends to the proxied resolver
> — in `rule` mode every name outside the table below, in `global` everything but the `hosts` table,
> in `direct` none at all — still travels there, and while a node accepts the connection but never
> answers, that lookup produces nothing at all, measured at sing-box's own 10.0 s per-query deadline.

Checked clause by clause against the composed `dns.rules` and against the section's own table
(`README.md:130-134`):

- **`rule`** — the table's "answered without any node" column is the `hosts` table, the five domestic
  suffixes and, while the rulesets are usable, `geosite-cn` / `geosite-private`. Everything else — the
  `geosite-google` rule at index [4] and the no-rule class via `dns.final` — is exactly what reaches
  `remote_dns`. "Every name outside the table below" is therefore precise, and it inherits the table's
  own "while the rulesets are usable" qualifier by pointing at it.
- **`global`** — `{"clash_mode": "Global"}` (`:1136`) captures everything the `hosts` server did not
  answer. For the sentence's subject (AAAA lookups with suppression not in effect), "everything but the
  `hosts` table" is exact; the table's own row adds the suppressed types because it speaks about all
  query types, which is a different scope, not a contradiction.
- **`direct`** — `{"clash_mode": "Direct"}` (`:1137`) matches every name before `final` is ever
  consulted, so nothing reaches the proxied resolver. "None at all" is exact.
- **The stall half** is now restricted to a lookup for a name the document sends to the proxied
  resolver, which is precisely V-29's class (`t16-nomatch.org`, routed to `remote_dns`). The 10.0 s
  figure is attributed to sing-box's own per-query deadline — Q-2's binding measurement — and
  `README.md:138` separately states that the error the user sees comes from their own client's timeout,
  which is what V-29/V-31/V-33 actually observed. Nothing in the sentence exceeds a step.

The zh mirror at `:122` carries the same three clauses in the same order, and `CHANGELOG.md:7` narrows
to `rule` mode with the exclusions enumerated (`hosts` table, five suffixes, `geosite-cn` /
`geosite-private`) — which understates the affected set in the degraded rule-set state rather than
overstating it, the safe direction, with the READMEs carrying the full treatment.

## CR-3: the degraded paragraph

`:136` now names `rule` as the row that shrinks, and states that `global`'s is already shorter and
`direct`'s does not depend on the rulesets at all. Both follow from the document: `[2]` and `[3]` carry
no `rule_set` key, so `_filter_rules()` cannot delete them, and `global`'s answered set (`hosts` plus
the suppressed types) is a strict subset of `rule`'s degraded set (those plus the five suffixes).

## CR-5: is the invariant now total?

I walked every operation in `_global_ipv6_iface()` (`:1487-1521`) for an escaping class:

- `IF_INET6_PATH.read_text()` — `OSError` caught at `:1489`; `UnicodeDecodeError` caught at `:1491`.
  The remaining theoretical class is `LookupError` from a corrupt locale codec name, which is not a
  property of the file and which `_load_lang()` would raise first in `main()` on *every* command; it is
  not a defect this function can carry.
- `int(fields[0][:2], 16)` — `ValueError` caught at `:1508`. A slice cannot raise `IndexError`, and
  `str.split()` never yields an empty token, so the degenerate `int("", 16)` case is caught by the same
  clause.
- `fields[5]` — reachable only after `len(fields) != 6: continue` (`:1504-1505`), so `IndexError` is
  structurally impossible.
- `text.splitlines()`, `line.split()`, `t()`, the two tuple returns — none can raise here.

So yes: total for every class reachable through the file's content or the filesystem, which is the
scope I-4's contract and AC-17/BC-7 are about. The branch returns `(None, t("unreadable"))`, identical
to the malformed-content branch, so `ipv6_decision()` emits exactly one stderr line through `_plain()`
(K-8) and no eleventh string is added (K-9) — DR-3 is legitimate at both sites. V-18's non-vacuity
control is real evidence, not a shape check: the round-1 function, reconstructed by deleting only the
new clause, fails 12 of 20 with the `UnicodeDecodeError` escaping to the caller, and passes exactly the
two round-1 sources — which is why the old fixture could not have caught it.

## CR-7: adjudicated in the developer's favour, and withdrawn

The developer is right, and my round-1 finding was a false charge that I retire here rather than leave
standing. `git diff --stat`'s bar column counts insertions **plus** deletions; `--numstat`'s first
field is the added count. 263 + 12 = 275 reconciles the PM's number with `04`'s record exactly, and
`--stat`'s own trailer says `263 insertions(+), 12 deletions(-)`. Three independent corroborations:
the CR-5 clause is 9 lines (`:1491-1499`), the tree now reads 272 / 12 (263 + 9), and the new bar
column is 284 (272 + 12). No added line was ever outside V-24's scan, and V-24 has since been re-run
over the added set extracted from the diff body itself, over `added ∪ deleted`, and over the whole file
by `ast` — the last of which is count-independent and would have caught a mis-scoped set anyway.
RES-3 is rewritten from an obligation into the reconciled fact.

## `_load_lang()`: the developer's classification is right

The question is whether T-16 newly puts a user on that path. It does not:

- The path predates this task. `_load_lang()` is called in **both** arms of `main()` (`:2904`, `:2907`),
  so a non-UTF-8 `settings.json` has always produced a traceback before any command runs, `sc doctor`
  included. T-16 changes neither arm (K-10 forbids it).
- T-16 cannot create such a file: `save_settings()` writes `json.dumps(d, indent=2)`, which is pure
  ASCII, and every value the new surface documents (`on` / `off` / `auto`) is ASCII. The new stderr
  line for an unrecognised value does point a user at the file, but a hand-edit that changes the file's
  *encoding* is not a path this task opened.
- BC-10 already fixes the standard: "`settings.json` is unreadable or not valid JSON → **the behaviour
  every other setting already has on that host**; no traceback and no new failure mode." A non-UTF-8
  file produces the behaviour every other setting already has — the same traceback, from the same call,
  at the same point. No *new* failure mode is introduced.
- The precedent the developer cites is accurate: `bin/sc:1712` catches `(OSError, ValueError)`, and
  `UnicodeDecodeError` is a `ValueError`, so that shape genuinely closes it.

One thing worth stating so nobody fixes half of it later: the class is repo-wide and, in this task's
own new code, **prescribed by the design**. `_ipv6_setting()` (`:1454-1457`) carries exactly the catch
tuple I-3 specifies — `except (FileNotFoundError, json.JSONDecodeError, OSError)` — as does the
pre-existing `_saved_clash_port()` (`:337-340`). Widening `_ipv6_setting()` alone would change nothing
a user can observe, because `_load_lang()` raises first on every invocation; and it would be a
deviation from a contract line the developer was bound to. So this is not a finding against stage 4 in
any of its three instances — it is one open row (RES-8) plus the note that a fix must take the family
together (RES-9), with `04:275`'s insight row as the carrier to the harvest.

## What I re-checked clean this round, so stage 6 need not re-derive it

- **K-16, against the new text rather than the old.** Greps over `README.md`, `README.zh-CN.md` and
  `CHANGELOG.md` for `fallback` / `回退` / `second resolver` / `第二个解析器` / network-request claims
  return, inside this feature's text, only the **denials** at `:138` in both languages and their
  changelog mirror. The two other hits (`README.zh-CN.md:193`, `CHANGELOG.md:13`) are the rule-set
  mirror fallback, a different feature, pre-existing and untouched.
- **C-10, against the new text.** The ceiling sentence is byte-unchanged in all three files: "A node
  whose address resolves only over IPv6 needs `sc ipv6 on`" / "地址只能通过 IPv6 解析出来的节点需要
  `sc ipv6 on`". No mechanism is stated anywhere, help blocks included.
- **The bilingual budget.** Ten new keys at `:169-183`, counted individually; placeholder sets identical
  in each pair; none contains `失败：` (the `:185` occurrence is pre-existing); none is `ls.*`-shaped;
  the CR-5 branch reuses `"unreadable"` (`:194`), so there is no eleventh.
- **Both READMEs are 332 lines** and end on the same structure (`## 📄 License` / `## 📄 许可证` at
  `:330`, content at `:332`).
- **The help blocks** (`:2767-2770`, `:2830-2833`) make no write-free claim and are unchanged.
- **The rule and its position.** `_dns_overlay()` `$prepend`s at `:1580`, the base's copy is still gone
  with the comment in its place (`:1138-1141`), `dns.final` is still `remote_dns` (`:1148`),
  `remote_dns` still carries `detour: proxy` (`:1122`), and the emitted rule has no `rule_set` key so
  `_filter_rules()` keeps it at `:903-907` before any other branch runs.
- **`cmd_ipv6()` and the array guard are byte-unchanged in shape**, which is what CR-4, CR-6, CR-8 and
  CR-9 required — all four were routed, not actioned, and the code confirms it.

## Judgement on the five drift rows (unchanged, with DR-3 extended)

- **DR-1** — legitimate; C-5 mandated it and K-7 was incomplete as written. Residue is CR-8.
- **DR-2** — legitimate and strictly stronger. V-11(a) as written fails at HEAD because T-15's frozen
  `urltest` group emits `outbounds[].idle_timeout`.
- **DR-3** — legitimate, and it stays legitimate at its **second** site. Reusing `"unreadable"` for the
  non-UTF-8 source is exactly what K-9 requires, it is the same fact about the same file as the
  malformed-content branch, and the codec's own untranslated message never reaches a user-facing
  sentence.
- **DR-4** — legitimate and correctly declared under C-7; `M-5`'s DoH-versus-UDP gap is carried rather
  than papered over.
- **DR-5** — legitimate. `sing-box check` passing while the process dies at run (`FATAL … detour to an
  empty direct outbound makes no sense`) is a run-time refusal a config check cannot catch, so the
  design's staging was unrunnable; the substitution is the shape `_runtime_overlay()` itself collapses
  to at zero nodes and weakens no behavioural claim.
