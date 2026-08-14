# 04 — Development · T-16 `dns-resilience`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

Mode: **full**, single developer (no partitions). Upstream read in full: `01_REQUIREMENT_ANALYSIS.md`,
`02_SOLUTION_DESIGN.md`, `03_GATE_REVIEW.md` (conditions C-1 … C-11 and the pre-answered questions
D-1 … D-6), plus the PM's measurement probe M-1 … M-5 in `PM_LOG.md`. No rationale sibling of `01`/`02`
was opened: no T4.1 … T4.3 trigger fired — the one contract deviation below is mandated by gate
condition C-5, not chosen. **T4.4 fired** (rework after `05_CODE_REVIEW.md`): `05_RATIONALE.md` was
read in full, and its reasoning on CR-1 (`:57-74`) and CR-2 (`:31-55`) is what the corrected text below
is written against. `.harness/rules/70-doc-size.md` carries no `## Stage-doc boundary rule` section, so
this schema is applied as written; see `## Open issues for review` for the one unit it has no shape for
(C-7's fixture recipe, which a binding condition requires to live in *this* file).

## Summary

- AAAA suppression now ships as one `predefined` rule `$prepend`ed to `dns.rules[0]` by a new
  `_dns_overlay()`, with the base's `query_type` element (`bin/sc:1101` at HEAD) deleted in the same
  edit — so exactly one such rule exists, it precedes both `clash_mode` rules, and it carries no
  `rule_set` key.
- `sc ipv6 on|off|auto|show` exposes it, over `ipv6_decision()` — the single definition of the
  effective decision — reading the new `settings.json` key `ipv6` and, only under `auto`,
  `/proc/net/if_inet6`.
- `OverrideError` gained a `path` attribute so a failure in an overlay `sc` authored no longer names
  the user's `override.json`; no DNS wait, no fallback resolver and no re-point of `dns.final` was
  emitted anywhere, because M-1 … M-4 measured all three to be impossible in sing-box 1.13.15.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | `# Paths`: `IF_INET6_PATH = Path("/proc/net/if_inet6")` after `RESERVED_TAGS` (`:57-62`) — the **eighth** repointable path constant | L-1 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `TRANSLATIONS["zh"]`, settings block (`:165-183`): the ten Q-15 pairs, verbatim in both languages; no eleventh | L-2 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `OverrideError` (`:1062-1081`): class attribute `path = None` + why the default is `None` and not `CFG_PATH` | L-3 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `CONFIG_BASE["dns"]["rules"]`: the `query_type` element deleted (`:1138-1141`, a comment in its place); `servers`, `final`, the other seven rules and their order untouched | L-4 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `# Config composition`, above `_runtime_overlay()`: `_ipv6_setting()` (`:1439`), `_global_ipv6_iface()` (`:1468`), `ipv6_decision()` (`:1524`), `_dns_overlay()` (`:1562`) | L-5 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `_global_ipv6_iface()` also catches `UnicodeDecodeError` (`:1491-1499`) — a `ValueError`, so it escaped the `except OSError` above it and a non-UTF-8 address source reached the user as a traceback (CR-5). Same `(None, t("unreadable"))` return as the malformed-content branch, so I-4's "never raises" is now total and the string budget is untouched | L-5 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `generate_config()`: provenance wrapper around `_load_override()` (`:1731-1738`), `_compose([_runtime_overlay(...), _dns_overlay()])` + the user's overlay merged at its own named site (`:1762-1771`), and the three-key array guard sets `path` too (`:1773-1782`, C-5) | L-7 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `# Commands`, after `cmd_mode()`: `cmd_ipv6()` (`:2437-2476`) | L-8 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `main()`: the `ipv6` subparser (`:2882`) and its `handlers` entry (`:2912`) | L-9 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `main()`'s `OverrideError` handler (`:2929-2936`): renders `e.path or CFG_PATH`; the old comment replaced by what `path` means | L-10 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `HELP_EN` (`:2767-2770`) / `HELP_ZH` (`:2830-2833`): the `ipv6` row at column 30 with its sub-options at 32/39 | L-11 |
| `/home/alan/Programs/singbox-cli/README.md` | new `### IPv6 name resolution` after `### Switch route mode` (`:113-138`). Corrected sentences: `:122` names *which* AAAA lookups reach the proxied resolver instead of "every" one (CR-2), `:124` scopes `sc ipv6 show` to what it decides and applies and then states the start-up path (CR-1) **and now states the true set of hosts that path writes on** (QA-1/CR-10: the write is no longer scoped to "on a fresh host" — it also names any host that has not yet recorded a valid Clash API port, including one upgraded from a version predating the port auto-probe), `:136` names `rule` as the mode whose row shrinks when the rulesets are gone (CR-3). No new heading, no new line — corrections to existing prose, so the ten-string budget is untouched | L-12 |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` | the same section at the mirrored position (`:113-138`), with the same corrections at the same line numbers, QA-1's clause included; both files are still 332 lines, and headings, fences and table rows sit at identical line numbers | L-13 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | one Chinese bullet under `## [Unreleased]` → `### 新增`; its two over-claims corrected in the same terms — "每一次 AAAA 查询" narrowed to the names the config actually sends to the proxied resolver (CR-2), and "`sc ipv6 show` … 不发网络请求" replaced by the scoped claim plus the start-up path (CR-1) — and its start-up-path parenthesis carries QA-1's clause verbatim in the same terms as the READMEs' | L-14 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | `# Paths` row (seven → **eight** repointable constants, and the recipe's repoint list), `# Config composition` row (the four new functions), `# Config generation` row (the two-step composition + the provenance rule), `# Commands` row (`cmd_ipv6`), two new reusable-utility rows (`ipv6_decision`, `_dns_overlay`) | L-15 |
| `/home/alan/Programs/singbox-cli/docs/features/dns-resilience/04_DEVELOPMENT.md` | this document | L-16 |

Diff total (`git diff --numstat`, re-measured): `bin/sc` **+272/−12**, `README.md` +27, `README.zh-CN.md`
+27, `CHANGELOG.md` +2, `docs/dev-map.md` +14/−9. Nothing outside NFR-3's permitted set; `CONTEXT.md`,
`.harness/**`, `install.sh`, `uninstall.sh`, `systemd/` untouched, and nothing I wrote is under
`docs/batches/**` (`BATCH_PLAN.md`'s status column and `BATCH_LOG.md` are the PM's own bookkeeping, not
part of this diff). Not committed — delivery is the PM's.

**CR-7 reconciled.** The two numbers were measuring different things, and both were right about their
own quantity: `git diff --numstat -- bin/sc` reports `263  12` for the round-1 tree (re-derived here
with `git diff --no-index` against a reconstructed pre-CR-5 file: `263  12`, exact), while
`git diff --stat`'s bar column prints **275 = 263 insertions + 12 deletions** — that column counts
changed lines, not added ones, and its own trailer said `263 insertions(+), 12 deletions(-)`. So no
added line was ever outside V-24's scope. The count is now **272 added** (the 9-line CR-5 clause) /
12 deleted, bar column 284, and V-24 was re-run over that added set — extracted from the diff body
rather than trusted from a record — plus over `added ∪ deleted` (284 lines) and, count-independently,
over the whole file by `ast`.

## verify_all result

```
command: bash .harness/scripts/verify_all.sh
baseline (before any edit): PASS: 17  WARN: 0  FAIL: 0  SKIP: 1
after (current tree):       PASS: 17  WARN: 0  FAIL: 0  SKIP: 1
delta: 0 new failures, 0 new warnings, baseline preserved
re-run after the CR-1/CR-2/CR-3/CR-5 corrections: PASS: 17  WARN: 0  FAIL: 0  SKIP: 1 — unchanged
re-run after the QA-1 text correction: PASS: 16  WARN: 1  FAIL: 0  SKIP: 1 — overall PASS, 0 FAIL
  the one WARN is the F.6 predicted below, and it fired *before* this round's edit: the only active
  task doc over the cap is `PM_LOG.md` (517 lines), which is the PM's file and outside my diff — this
  round touched `README.md`, `README.zh-CN.md`, `CHANGELOG.md` only, none of them a task doc. Measured
  the same way on the pre-edit tree of this round
predicted WARN, now fired: F.6 (active task docs <= 500 lines) — `PM_LOG.md` is the only file over it;
  every other doc in this task is under the cap, and the WARN clears on archive (the archived
  `proxy-urltest-group/PM_LOG.md` sits at 608 lines, so this is the accepted end state, not a defect)
note: B.3 (lint) is the pre-existing SKIP, unchanged
live-service witness, before and after every run in this stage:
  MainPID=2566751 | ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST  (identical, never restarted)
```

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| DR-1 | K-7 — set `e.path` "at exactly the two sites … and nowhere else" | Three sites: `_load_override()`'s wrapper, the user-overlay `_merge()`, **and** `generate_config()`'s three-key array guard (`bin/sc:1773-1782`) | Gate condition **C-5** mandates it and states K-7 is incomplete as written: the guard raises *after* the user's merge and can only fire when an override is present, so under `path = None` a genuinely user-caused fault would have stopped naming `override.json` (finding F-3). Verified both directions in V-23 |
| DR-2 | V-11(a) — "walk the emitted JSON … for any key whose name contains `timeout`" | Tightened to: **no** `timeout`-ish key anywhere under `dns` in all six states, **and** the whole document's set of such keys is exactly HEAD's for the same state | Literally as written the step fails at HEAD: T-15's `urltest` group emits `outbounds[].idle_timeout` (frozen set, out of scope item 4). The rewritten form is strictly stronger for what AC-7 is about and cannot pass by accident |
| DR-3 | I-4 — `err` "is set … when the file is non-empty and no line yields six fields" (no text specified) | That `err` is the **existing** translation key `"unreadable"` (`bin/sc:194`), rendered into the Q-15 sentence's `{err}` slot — at **two** sites now: the malformed-content branch (`:1520`) and, since CR-5, the non-UTF-8 source (`:1499`), which is the same fact about the same file and so must not read differently | K-9 caps the new strings at Q-15's ten and requires reusing an existing key where one says what is needed. The alternative — a bare untranslated English fragment — would have been an eleventh user-facing string with no `zh` entry (NFR-2) |
| DR-4 | Verification preamble — "three derivations of the emitted document, and no fourth" | A **fourth, declared** derivation: `remote_dns` is derived from DoH (`type: https`, `path: /dns-query`) to plain UDP, tag/order/`detour: proxy` preserved. `local_local` is repointed at the non-proxied stub as well, so no fixture query can reach the public internet (K-14) | Gate condition **C-7** requires the transport derivation to be declared explicitly and counted rather than smuggled; a DoH stub would need a certificate sing-box trusts, which this fixture cannot install. M-5 leaves DoH-versus-UDP behaviour unestablished, so no claim in this document rests on it |
| DR-5 | Verification preamble — "*usable* = a `direct` outbound tagged `proxy`" | *usable* = a **selector** tagged `proxy` whose single member is `direct` — the shape the shipped document itself collapses to at zero nodes (`bin/sc:_runtime_overlay`) | Measured: sing-box 1.13.15 **refuses to start** when a DNS server's `detour` names a bare `{"type":"direct","tag":"proxy"}` — `FATAL start dns/udp[remote_dns]: detour to an empty direct outbound makes no sense`. The selector form is accepted and is what production actually runs |

## Condition disposition

| gate condition | disposition | evidence |
|---|---|---|
| C-1 | discharged | V-26/V-27/V-28/V-34's third probe is **TYPE64** (a type HEAD already suppresses), stated in each row; all four HEAD controls produced the candidate's outcome (`NOERROR`, 0 answers, ≤ 19.2 ms), so they are genuine agreement controls. Type 28 stays only in V-29/V-31/V-36, which AC-B10 classifies as defect-reproducing |
| C-2 | discharged | V-31 was run against the **corrected** text: `global` — HEAD stalls (no answer, client's own 15 s limit; sing-box's log: `[10.0s] dns: exchange failed … context deadline exceeded`); `direct` — HEAD exhibits the defect as the **absence of suppression**, the non-proxied stub records `28` and HEAD answers it (`ans=1`, 19.9 ms). Candidate answers empty `NOERROR` in both modes with neither stub touched |
| C-3 | discharged | The README's node-independent-class text was written **after** V-26 … V-28, V-32, V-34 and the added per-mode measurement (below) had run. Measurement does **not** contradict I-17; it is more specific, and the one extra fact it produced (with the rulesets usable, `geosite-cn`/`geosite-private` names also resolve without a node in `rule` mode) is stated in the README as exactly that conditional. See `## Open issues for review` for the one clarification I-17 could carry. C-3 also governs the two sentences corrected this round: CR-2's per-mode clauses at `:122` restate the table V-26(b) measured and V-32 confirmed per name, and CR-3's clause at `:136` rests on V-27 (`rule` shrinks), V-26(b) (`global` is already shorter) and V-32's degraded-state row (`direct` does not depend on the rulesets). Neither sentence adds a fact no step observed. The QA-1 clause added to `:124` in both languages rests on QA's own measurement (`06_TEST_REPORT.md` QA-1: a seeded `settings.json` holding `lang`/`mode`/`update_interval` and no `clash_api_port` is rewritten and gains the key) plus the predicate in `_saved_clash_port()`; it states nothing wider than that |
| C-4 | discharged | V-13's row states its scope. **In this document, explicitly: `main()`'s startup path still runs for `sc ipv6` exactly as for every other non-`doctor` command** — `_init_files()` creates `/etc/sing-box`, `/etc/sing-box/rules` and `/var/lib/sing-box` and seeds `nodes.json`/`settings.json`, and `_resolve_clash_port()` may bind a probe socket and persist a port. "Writes nothing / no network request / one local read" is true of `cmd_ipv6()`, never of the command on a fresh host. K-10 stands: the read-only opt-out arm is untouched and `doctor` is still its only member. **The shipped text now says the same** (CR-1): `README.md:124` / `README.zh-CN.md:124` / `CHANGELOG.md:7` scope the claim to what the command decides and applies and then state the start-up path outright. The claim itself is observed by the added step **V-13(b)** — `ast`, never execution, because the safety rule forbids driving `_init_files()` (it hard-codes `/var/lib/sing-box`). **QA-1/CR-10 closed** without weakening any of that: the disclosure sentence is still unqualified ("like every command except `sc doctor`, it still runs the ordinary start-up path first"), and only the *scope of the write it then describes* was widened from "on a fresh host" to what `_saved_clash_port()` (`bin/sc:329-342`) actually decides — `None` for any host recording no `clash_api_port`, one outside 1…65535, or an unparseable file, which is the case `_resolve_clash_port()`'s own comment (`:357-359`) exists for. Behaviour unchanged; the edit is confined to the three texts |
| C-5 | discharged | V-23 extended to four runs; the added one has an `override.json` turning `dns.rules` into the scalar `7` and the rendered message names `…/override.json` (see V-23's row). DR-1 records the K-7 deviation this required |
| C-6 | discharged | The service witness is a counter on `sc.restart_service` / `sc.generate_config` (which fire under `SYSTEMD = OPENRC = False`, where an init-command shim never can), **plus** `PATH` shims for `systemctl`/`rc-service`/`rc-update` and a counting `socket.socket`. Non-vacuity: V-15 fires the same witness exactly once |
| C-7 | discharged | The complete recipe is pasted below this table, verbatim and runnable; DR-4/DR-5 declare the transport derivation and the staged shape of `proxy` for each node state; this document records that M-5 leaves DoH-versus-UDP unestablished and that no claim rests on it |
| C-8 | discharged | V-3(b), an added source-level step for AC-10: `ast` comparison of `generate_config()` against HEAD — the three-key guard tuple is byte-identical and still three keys, there is **no** dict literal in the function in either revision, and the set of constants in it is unchanged (no new configuration literal) |
| C-9 | discharged | V-32's degraded-state expectation was checked per mode and observed as corrected: the three ruleset names reach the **proxied** stub in `rule` and `global` and the **non-proxied** stub in `direct`, identically in both runs |
| C-10 | discharged | Neither README, the changelog, the help blocks nor this document states any mechanism for BC-14; the only claim made anywhere is "a node whose address resolves only over IPv6 needs `sc ipv6 on`" (README `:138` / `:138`). V-21 greps for the over-claim shapes and finds none. That sentence is **byte-unchanged** by this round's corrections, and the re-run greps still find only the K-16 denials at `:138`. The mechanism remains **unverified** (RS-3) and is observed by no step here |
| C-11 | stage 6's | Not mine to discharge; the input it needs is in `## Open issues for review` |

C-7's fixture recipe, verbatim — stage 6 must be able to rebuild it independently:

```python
# ---- loading bin/sc without letting it re-exec the INSTALLED /usr/local/bin/sc ----
assert os.geteuid() != 0                       # refuse to run as root, loudly
sc = types.ModuleType("sc")
shim = types.ModuleType("os"); shim.__dict__.update(os.__dict__)
shim.geteuid = lambda: 0
sys.modules["os"] = shim
try:
    exec(compile(open(path).read(), path, "exec"), sc.__dict__)
finally:
    sys.modules["os"] = os                     # restore IMMEDIATELY, in a finally
# repoint EIGHT constants into ONE mkdtemp() root and ASSERT each resolves inside it:
#   CFG_DIR CFG_PATH NODES_PATH SETTINGS_PATH RULES_DIR OVERRIDE_PATH STATE_PATH IF_INET6_PATH
# sc.SYSTEMD = sc.OPENRC = False ; sc.LANG = sc._load_lang() (what main() does) ;
# never drive _init_files() — seed nodes.json / settings.json / rules/*.srs directly.
# The document under test is what generate_config() really emits in that fixture.

# ---- the four DECLARED derivations of that document, and nothing else ----
d["inbounds"] = [{"type": "direct", "tag": "dns-in", "listen": "127.0.0.1",
                  "listen_port": P_IN, "network": "udp"}]        # (1) TUN -> direct UDP
# route.rules is untouched: {"action":"sniff"} MUST stay ahead of the hijack-dns rule
# (without it the direct inbound forwards the packet to itself in a silent loop), and
# route.default_domain_resolver MUST stay present (1.13.15 fails `check` without it).
for s in d["dns"]["servers"]:                                    # (2) servers -> stubs
    remote_dns -> {"server":"127.0.0.1","server_port":P_REMOTE,"type":"udp",
                   "tag":"remote_dns","detour":"proxy"}          # (4) DoH -> plain UDP
    direct_dns -> {"server":"127.0.0.1","server_port":P_DIRECT,"type":"udp","tag":...}
    local_local -> same as direct_dns   # nothing may reach the public internet (K-14)
    hosts_dns  -> verbatim
d["dns"]["disable_cache"] = True                 # measure the document, not a cache
d["experimental"] = {"cache_file": {"enabled": False, "path": <fixture>/cache.db},
                     "clash_api": {"external_controller": "127.0.0.1:P_CLASH"}}  # (3)
# node state is staged at the `proxy` OUTBOUND, never at a stub:
#   usable   = {"type":"selector","tag":"proxy","outbounds":["direct"],"default":"direct"}
#              (a bare {"type":"direct","tag":"proxy"} makes sing-box refuse to start:
#               "detour to an empty direct outbound makes no sense")
#   unusable = {"type":"vless","tag":"proxy","server":"127.0.0.1","server_port":P_HANG,
#               "uuid":"11111111-1111-1111-1111-111111111111"}  + a TCP listener that
#              accepts and never answers   |  refusing = the same vless at a closed port
#   0 nodes  = the emitted outbounds verbatim (the selector collapses to `direct`)
# outbounds := [<staged proxy>, {"type":"direct","tag":"direct"}]

# ---- stubs, probes, witnesses ----
# Two UDP stub resolvers, each logging "<qname> <qtype>" per query: remote answers
# A 10.77.0.1 / AAAA 2001:db8:77::1, direct answers A 10.88.0.1 / AAAA 2001:db8:88::1,
# every other type an empty NOERROR.  Client: dig @127.0.0.1 -p P_IN +tries=1 +time=N.
# Probe names, each CLASSIFIED by measurement against HEAD (usable node, rule mode, all
# rulesets usable) rather than assumed:
#   doh.pub          -> the hosts table, no upstream at all
#   360.cn           -> the enumerated domestic domain_suffix rule -> direct_dns
#   baidu.com        -> geosite-cn      -> direct_dns
#   probe-x.test     -> geosite-PRIVATE -> direct_dns   (`test` is in geosite-private!)
#   www.google.com   -> geosite-google  -> remote_dns
#   t16-nomatch.org  -> matched by NO rule -> dns.final -> remote_dns
# Every fixture sing-box: unprivileged, no TUN inbound, own cache path, own Clash port,
# `sing-box check` before `run`. Live witness at every checkpoint:
#   systemctl show sing-box -p MainPID -p ActiveEnterTimestamp     (never is-active)
# No PUT/PATCH/DELETE ever reaches 127.0.0.1:29090 — only the fixture's own controller.
```

## Verification plan results

Every step was run. Live-service witness **before**: `MainPID=2566751 |
ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`; **after**: identical. Full transcripts in
`04_RATIONALE.md`.

| step | verdict | observed |
|---|---|---|
| V-3 | PASS | HEAD vs candidate at the **same** fixture path, suppression off, all rulesets usable: `dns.rules` differs in exactly one way — the `query_type` element moved from index 3 to index 0, list exactly `[64, 65]`; every other rule, `dns.servers`, `dns.final` (`remote_dns`), every other key **and the key order** identical |
| V-3(b) | PASS | (C-8, AC-10's source half) guard tuple `("dns.rules", "route.rules", "route.rule_set")` byte-identical and still three keys; 0 dict literals in `generate_config()` in both revisions; no new constant in it |
| V-4 | PASS | Suppressing: `dns.rules[0]` == `{"action": "predefined", "rcode": "NOERROR", "query_type": [28, 64, 65]}`, no `answer` key |
| V-5 | PASS | All four {suppression} × {rulesets} states: `index == 0`, strictly below both `clash_mode` rules and every `remote_dns` rule; surviving order matches I-17 exactly; `{"clash_mode": "Direct"}` still matches exactly one element (T-17's slot stays expressible) |
| V-6 | PASS | The added rule is present in both ruleset states and carries no `rule_set` key |
| V-7 | PASS | **Real** `/usr/local/bin/sing-box check`, exit 0 in all six states (0/1/3 nodes, suppression on, suppression off, all rulesets unusable) |
| V-8 | PASS | `ast` segments of `_merge`, `_directive_of`, `_apply_directive`, `DIRECTIVES`, `_load_override` byte-identical to HEAD |
| V-9 | PASS | `ast`-extracted `timeout=` arguments: `clash_api` 3, `_egress_ip` 8, `_fetch_to_temp` 30 — unchanged; no `grep` used |
| V-10 | PASS | One definition, two callers (`_dns_overlay`, `cmd_ipv6`), no re-derivation anywhere; deletion test: with `cmd_ipv6` removed, `_dns_overlay()` returns byte-identical output |
| V-11 | PASS | (a) six states: no `timeout`-ish key anywhere under `dns`, whole-document set exactly HEAD's (`outbounds[].idle_timeout`, frozen since T-15), `dns.final == remote_dns` in all six. (b) no new wait constant — the one new module constant is `IF_INET6_PATH` — and no new `timeout=` argument. See DR-2 |
| V-12 | PASS | Eight `main()`-driven runs (`on`/`off`/`auto`/`show` × `en`/`zh`), all exit 0, each printing the setting line and the evidence sentence, no `\r`, one complete line per fact |
| V-13 | PASS | `cmd_ipv6("show")`: 0 mtime changes over the whole fixture root (9 files), restart/generate witness silent, **0 sockets opened**, init shims never invoked. Scope per C-4 |
| V-13(b) | PASS | Added under C-4 to observe the start-up-path half of the corrected README/CHANGELOG sentence, **statically** (driving `_init_files()` is forbidden). `ast` over `main()`: the read-only gate is `args.cmd == 'doctor'`, its constant set is exactly `['doctor']`, its `if` arm calls only `_load_lang`, and the `else` arm calls `_init_files` → `_load_lang` → `_resolve_clash_port`; the `handlers` dict has 21 members and `ipv6` is one of them. So every form of `sc ipv6`, `show` included, runs the writing start-up path **before** `cmd_ipv6()` is reached |
| V-14 | PASS | `sc ipv6 auto` on an already-`auto` host and `sc ipv6 on` on a host with a global address: `config.json` mtime unchanged, witness silent, `Nothing changed …` printed exactly once each |
| V-15 | PASS | `sc ipv6 off` while not suppressing: `dns.rules[0].query_type` → `[28, 64, 65]`, restart witness fired **exactly once**, `Configuration regenerated; sing-box restarted` printed. This is C-6's non-vacuity control for V-13/V-14 |
| V-16 | PASS | Absent / no-`ipv6`-key / `"ipv6": "yes"` × both languages: all six decide `auto`; only the third writes one stderr line, naming the file, the key and the three accepted values, in the run's language |
| V-17 | PASS | This host's real 7-entry file → no global; + `2000::/3` on `enp3s0` → `enp3s0`; + `2000::/3` on `sb-tun` **only** → no global; empty file → no global, silently |
| V-18 | PASS | **Extended under CR-5** to five sources × both languages, each checked twice (the predicate alone, then the whole `ipv6_decision()` path): source removed → `(None, "No such file or directory")`; one line of UTF-8 prose → `(None, "unreadable")`; **raw non-UTF-8 bytes**, **non-UTF-8 inside an otherwise kernel-shaped line**, and a **UTF-16-encoded** kernel line → `(None, "unreadable")`. All five: nothing raised, no suppression, exactly one stderr line naming cause and assumption, no `\r`, no traceback. **Non-vacuity**: the same fixture run against the round-1 shape of `_global_ipv6_iface()` (reconstructed by deleting only the new clause) failed 12 of its 20 checks with `UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff …` escaping to the caller on all three new sources — and passed the two round-1 sources, which is exactly why the old fixture could not have caught it. HEAD is not a control here: HEAD has no IPv6 code at all |
| V-19 | PASS | BC-16 upgrade fixture (HEAD-generated `config.json` + its matching digest): first `sc reload` succeeds with no hand-editing and **no** drift warning (stderr empty), the record then matches the new file on disk, the second reload is silent too |
| V-20 | PASS | Re-run after CR-5: still exactly **10** new keys, each with a `zh` entry, identical placeholder sets, none containing `失败：`, none `ls.*`-shaped; **0 keys removed and 0 pre-existing `zh` values changed** (`ast`-extracted `TRANSLATIONS["zh"]`, working tree vs HEAD). The CR-5 branch reuses `"unreadable"`, so the budget is untouched |
| V-21 | PASS | Re-run after the CR-1/CR-2/CR-3 corrections: both READMEs still **332 lines**, and headings, fences and table rows now checked to sit at *identical line numbers* in both files (diff of the two line-number lists is empty); both document the four forms, the effective-decision rule, I-17's per-mode class, BC-4's consequence and BC-22's limit; `CHANGELOG.md` still carries exactly one Chinese bullet for this task under `### 新增`. K-16 greps (`fallback`/`回退`/`second resolver`/`第二个解析器`/`configurable wait`/`可配置的等待`/`DNS timeout`) over the IPv6 section: the only hits are the two **denials** at `README.md:138` / `README.zh-CN.md:138` and their changelog mirror — no surface claims either. C-10's ceiling sentence is byte-unchanged by this round's edits. **Re-run again after the QA-1 clause**: both files still 332 lines, the structural line-number lists (headings, fences, table rows — 102 marks each) still identical, no `\r` in any of the three texts, the K-16 greps still hit only the `:138` denials, and `:138` is still byte-unchanged, so C-10's ceiling holds |
| V-22 | PASS | `ipv6 <on\|off\|auto\|show>` present in `HELP_EN` and `HELP_ZH`, description at display column 30 like every other row, sub-options at 32 with the wrapped line at 39 (the `use` block's own pattern) |
| V-23 | PASS | Fault-injected `sc` overlay, with and without an `override.json` present: both render `Cannot use …/config.json: at dns.no_such_key: $prepend can only be applied to an array that already exists` — `override.json` is named in neither. User-caused faults still name it: a scalar `dns.rules` → `…/override.json: at dns.rules: this must stay an array` (C-5), malformed JSON → `…/override.json: not valid JSON (…)` |
| V-24 | PASS | **Re-run over the reconciled added set** (CR-7). `py_compile bin/sc` exit 0. The added set is now extracted from the diff body itself, not from a record: 272 added / 12 deleted, matching `git diff --numstat` exactly. 18 post-3.6 patterns scanned (walrus, `dataclasses`, `capture_output=`, `missing_ok=`, `dirs_exist_ok=`, `cached_property`/`functools.cache`, `breakpoint()`, `remove*fix`, `fromisoformat`, `isascii`, `*_ns`, `nullcontext`, `match`-statement, `Path.readlink`/`is_mount`, f-string `=`, positional-only params, builtin generics, PEP-604 unions) — **0 hits over the 272 added lines and 0 over the 284 added ∪ deleted**. Count-independent halves: `ast` over the whole file finds no `NamedExpr`/`Match`/positional-only def; the import set is byte-identical to HEAD's; the module-constant set gains exactly `IF_INET6_PATH` (which is also V-11(b)) |
| V-25 | PASS | `bash .harness/scripts/verify_all.sh` — see `## verify_all result` |
| V-26 | PASS | Node **unusable**, suppression in effect, all rulesets usable, `rule` mode. `doh.pub`/A `NOERROR` 2 answers 18.3 ms; `360.cn`/A `NOERROR` 1 answer 17.7 ms; **TYPE64** (C-1) of a no-rule name `NOERROR` 0 answers 17.4 ms. Proxied stub recorded nothing. HEAD control (agreement): 19.2 / 18.9 / 18.6 ms, same outcomes, proxied stub empty |
| V-27 | PASS | V-26 with the fixture rules directory empty: 18.2 / 7.9 / 17.4 ms, same outcomes; HEAD control agrees |
| V-28 | PASS | V-26 with `proxy` at a closed port: 18.2 / 8.9 / 17.8 ms, same outcomes; HEAD control agrees |
| V-29 | PASS | Suppression in effect, node unusable, `rule` mode, AAAA of a name HEAD routes to `remote_dns`: candidate `NOERROR` 0 answers **18.7 ms**, proxied stub recorded nothing. HEAD control (defect-reproducing) **exhibited the defect**: no answer at all, client's own 15 s limit, sing-box logging `[10.0s] dns: exchange failed … context deadline exceeded` |
| V-30 | PASS | Same fixture after `sc ipv6 on`, node usable: the proxied stub **records the AAAA query** and it resolves normally (1 answer). HEAD control agrees |
| V-31 | PASS | Fixture instance's own Clash API set to `global`, then `direct`. Candidate: empty `NOERROR`, 0 answers, 18.3 / 18.7 ms, **neither** stub records the query in either mode. HEAD control, C-2's corrected text: `global` stalls (no answer, 15 s client limit); `direct` does not stall — the **non-proxied** stub records type 28 and HEAD answers it (1 answer, 19.9 ms) |
| V-32 | PASS | Node usable, both stubs instrumented, six probe names × 2 ruleset states × 3 modes = **36 combinations**, type A throughout: the same stub receives each probe name in the candidate and HEAD runs — **0 mismatches**. Degraded state per mode (C-9): the three ruleset names reach the proxied stub in `rule` and `global`, the non-proxied stub in `direct`, identically in both runs |
| V-33 | PASS | Node unusable, a no-rule name, `dig +tries=1 +time=15`: sing-box returns no answer, **neither** stub records the query, the client's outcome arrives at its own 15 s limit (15 031 ms); HEAD control 15 029 ms — no smaller |
| V-34 | PASS | V-26's three probes on a **0-node** fixture (the selector collapses to `direct`): 18.4 / 18.2 / 7.7 ms, all answered; the same document passed V-7's 0-node `sing-box check` |
| V-35 | PASS | Every one of V-26 … V-34 and V-36 was re-run against the pristine HEAD tree at the identical fixture and derivation, recorded verbatim in `04_RATIONALE.md`. Defect-reproducing controls (V-29, V-31, V-36) **exhibited** their defect; agreement controls (V-26 … V-28, V-30, V-32 … V-34) produced the candidate's outcome. **No run was inconclusive** (NFR-7) |
| V-36 | PASS | Non-vacuity for AC-B4: node usable, suppression in effect, one A and one AAAA for the same name — the proxied stub recorded query type `1` and **not** `28`, and the AAAA answer was an empty `NOERROR`. HEAD control recorded **both** `1` and `28` |
| V-26(b) | PASS | Added under C-3 to measure I-17's per-mode class before the README states it. Node unusable, all rulesets usable: `rule` → hosts, domestic suffix, `geosite-cn` and both suppressed types answered (7–18 ms), the no-rule class unanswered; `global` → only hosts and the suppressed types answered, everything else unanswered; `direct` → everything answered without a node. HEAD control, same fixture: identical except that HEAD leaves **both** suppressed types unanswered in `global` and sends **both** to the non-proxied resolver in `direct` |

## Open issues for review

- **This schema has no shape for C-7's fixture recipe**, which a binding gate condition requires to
  live in this contract file; `.harness/rules/70-doc-size.md` has no `## Stage-doc boundary rule`
  section to classify it. I carried it as a fenced block under `## Condition disposition` rather than
  inventing a section, and name the gap here as instructed.
- **I-17's `rule`-mode clause is an intersection over ruleset states, not the whole class.** Measured:
  with the rulesets usable, `geosite-cn` and `geosite-private` names are *also* answered while every
  node hangs (they carry no detour). This does not contradict I-17 — FR-8 promises the class that
  survives "in every ruleset state" — but the text reads as an enumeration and cost a re-read. The
  READMEs state it as the conditional it is.
- **The 10.0 s deadline is never what the user sees.** In V-29/V-31/V-33 the client's outcome arrived
  at *its own* timeout (15 s), while sing-box had dropped the query at 10.0 s and logged it. Any
  user-facing text that promises "you get an error after 10 s" would be wrong; the READMEs say the
  error comes from the client's own timeout.
- **For C-11 (stage 6's):** no behavioural run here exercises the shipped document's own DNS path —
  TUN capture, `route.rules[0]`'s `process_name` rule, the real DoH transport for `remote_dns`, or
  T-15's selector/auto-select group. All of it is evidenced only by V-3's differential and V-7's real
  `sing-box check`. M-5's three unestablished items stand untouched by anything measured here.
- **BC-14 remains unobserved** (RS-3): nothing here tests whether a node whose address resolves only
  to AAAA actually becomes unreachable under suppression, and `route.default_domain_resolver`
  (`bin/sc:1158`) argues it may not.
- **QA-1's second half — a malformed `settings.json` being rewritten to a single key, dropping
  `lang`/`mode` — is deliberately *not* in the user-facing text.** QA did not insist, and I judged the
  clause would cost more than it buys in a sentence whose subject is "does `sc ipv6 show` change
  anything": the loss is only reachable on a file that is already unparseable, and in that state every
  reader in `sc` (`_load_lang()` at `:312-314`, `load_settings()`'s callers) already treats those keys
  as absent — so what the rewrite discards is a value that was not in effect anyway, and naming it
  would put a corrupted-file edge case in front of the fact users need (the port write happens on more
  hosts than "fresh" ones). The merge at `bin/sc:360-364` is what keeps this to the malformed case;
  its `except` arm falling back to `{}` is the only path that loses keys. Recorded here, unfixed and
  unclaimed, so the decision is visible rather than silent.
- `sc ipv6` with no argument takes argparse's own error and exit 2, deliberately un-special-cased and
  identical to `sc lang` (I-14). Not covered by a numbered step; noted so the reviewer is not surprised.
- **Two review findings are upstream's, and I deliberately changed no code for them.** CR-6 (BC-13's
  unsignalled repair path) is routed to the requirement-analyst: `cmd_ipv6()` compares two decisions
  both computed from the current host, which is what FR-5/Q-9/I-10 specify and what AC-6 requires — any
  "fix" here would create the second opinion AC-6 forbids. CR-8 (gating the array guard on
  `override is not None`) is routed to the solution-architect for K-7's text: C-5 mandated the site as
  it stands and V-23 verified both directions, so changing it now would be drift against a binding
  condition. CR-4 and CR-9 are design-sanctioned (`02_RATIONALE.md` R-8; I-5 with V-12) and were left
  exactly as they are.
- **CR-5's class is wider than the one line it was found on, and this repo already knew it.** There are
  five `read_text()` sites in `bin/sc`. `:1711` (`STATE_PATH`) already catches `(OSError, ValueError)`
  and is therefore immune — the in-repo precedent I matched. `:458` and `:470` are deliberately
  unguarded (their callers guard). But `_load_lang()` at `:312-314` catches
  `(FileNotFoundError, json.JSONDecodeError, OSError)`, so a `settings.json` that is not UTF-8 still
  reaches the user as a traceback, from `main()`, before any command runs. **Pre-existing, not caused
  by T-16, and outside NFR-3's permitted diff** — named here rather than fixed, because widening it
  would be an unrequested change to a frozen-adjacent function.

## Dev-map updates

No further dev-map change was needed this round: the CR-5 fix adds no file, module or function, and the
text corrections touch no structure. The rows below are the ones this task added.

- `# Paths` row: `IF_INET6_PATH` added, and "seven path constants" → "**eight**".
- The import-recipe block under "Patterns to avoid": the repoint list and its assertion now name eight
  constants, with a sentence on why `IF_INET6_PATH` is the one that is not under `/etc/sing-box` —
  without repointing it the host's real IPv6 state decides what a fixture emits.
- `# Config composition` row: `_ipv6_setting`, `_global_ipv6_iface`, `ipv6_decision`, `_dns_overlay`.
- `# Config generation` row: the two-step composition and the `OverrideError.path` provenance rule.
- `# Commands` row: `cmd_ipv6()`.
- Two new "Reusable utilities" rows: `ipv6_decision()` (the single definition of the decision) and
  `_dns_overlay()` (the single place it reaches the document, and why index 0 is a contract).

## Insight to surface

- `geosite-private` matches the reserved TLD `test`, so a probe name like `probe.test` is **not** "matched by no DNS rule" — it is routed to `direct_dns`, silently invalidating any measurement of the no-rule class that uses a `.test` name · evidence: dns-resilience, `04_RATIONALE.md` probe-classification transcript
- sing-box 1.13.15 refuses to start when a DNS server's `detour` names a bare `{"type":"direct"}` outbound (`FATAL start dns/udp[remote_dns]: detour to an empty direct outbound makes no sense`), while a `selector` whose only member is `direct` is accepted — which is the shape the shipped document already collapses to at zero nodes · evidence: dns-resilience, `bin/sc` `_runtime_overlay()`
- At HEAD the `query_type` rule sat *after* both `clash_mode` rules, so types 64/65 were measurably **not** suppressed in clash mode `direct` (the non-proxied stub received the type-64 query) — moving the rule to index 0 changes real behaviour for 64/65, not only for the newly added type 28 · evidence: dns-resilience, V-26(b) HEAD control
- `Path.read_text()` behind any of `bin/sc`'s eight repointable path constants can raise `UnicodeDecodeError`, which is a `ValueError` and not an `OSError`, so the repo's habitual `except OSError` lets it through as a traceback — `:1711` already guards with `(OSError, ValueError)` while `_load_lang()` at `:312` does not · evidence: dns-resilience, `bin/sc:1491` and the extended V-18 non-vacuity control
- `git diff --stat`'s bar column is insertions **plus** deletions, so quoting it as an added-line count inflates the number and silently rescopes any "the added lines were scanned" claim built on it — the added count is the `--numstat` first field, or the `N insertions(+)` trailer · evidence: dns-resilience, CR-7 reconciliation (263 + 12 = 275)
- A `hosts`-type DNS server as `dns.rules[0]`-adjacent does **not** terminate the rule chain when it holds no entry for the name: with the suppression rule at index 0 and `hosts_dns` at index 1, rules `[2]` … `[7]` were all observed matching, per name and per mode · evidence: dns-resilience, V-32's 36-combination table

## Verdict

READY FOR REVIEW
