# Delivery Summary

## Summary

- Task: `dns-resilience` (T-16) — stop a single flaky node from killing all name resolution, expressed as overlays on T-14's composition layer.
- Mode: full
- Stages traversed: 1 (2026-08-13) → 2 → *probe* → 1′ → 2′ → 3 → 4 → 5 → 4′ → 5′ → 6 → 4″/1″ closures → 7 (2026-08-14)
- Rollbacks: **2.** (a) stage 2 → 1, because FR-9 promised a DNS budget the software cannot express and FR-8/FR-11 could not both hold; (b) stage 5 → 4, on two MAJOR defects, both in shipped *text*. Peak streak at any single stage: 1 — the three-rollback stop rule never approached firing.
- Final verify_all result: **PASS** — `PASS: 17 / WARN: 0 / FAIL: 0 / SKIP: 1`, identical to the batch baseline. No FAIL at any point in the run.
- Baseline changes: none. `.harness/scripts/baseline.json` still reads `test_count: 0` — this task commits no test (out-of-scope item 8; R-9 owns a committed suite), and `verify_all`'s step count is unchanged.
- Files changed: 5 files, **+342 / −21** (`bin/sc` 272/12, `README.md` 27/0, `README.zh-CN.md` 27/0, `CHANGELOG.md` 2/0, `docs/dev-map.md` 14/9).
- Outstanding risks: see **Shortfall** and **Open rows** below. Nothing blocking; three MINOR and two NIT ship known, filed and unclaimed.

### What shipped

`generate_config()` gains one computed overlay, `_dns_overlay()`, which `$prepend`s a single
`predefined` rule to `dns.rules[0]` answering AAAA (type 28) plus SVCB/HTTPS (64, 65) with an empty
`NOERROR`. The base's own `query_type` element is deleted in the same edit, so exactly one such rule
exists. Because the rule sits at index 0 — ahead of both `clash_mode` rules — suppression holds in
`rule`, `global` and `direct` alike; at HEAD that rule sat *after* them, so 64/65 were measurably not
suppressed in the two modes users switch to when something is already broken. It carries no `rule_set`
key, so `_filter_rules()` cannot delete it on precisely the degraded host that needs it.

Whether to suppress is decided by one new setting, `ipv6: on|off|auto`, with `ipv6_decision()` as the
single definition of the effective decision (two callers, nothing re-derives it) and `sc ipv6
on|off|auto|show` as its surface. `auto` — the default, and the meaning of an absent key — suppresses
exactly when the host holds no `2000::/3` address on a non-loopback, non-TUN interface. `sc ipv6
<value>` regenerates and restarts **only when the effective decision actually changes**.

Two things were composed, not bolted on: no new merge directive was added, `generate_config()` gained
no configuration literal, and the `OverrideError` provenance defect the code's own comment had been
waiting for was fixed — a failure in an overlay `sc` authored no longer blames the user's
`override.json`.

### Shortfall against the batch goal — stated plainly

The batch row asked for three things. **One shipped; two are impossible in sing-box 1.13.15**, and
that was established by measurement rather than assumed:

- **"Converge the 10 s DNS timeout" cannot be done.** `"timeout"` is rejected by the real
  `sing-box check` on a DNS server, at the `dns` block level and on a DNS rule, with a bogus-key
  control proving the decoder rejects unknown fields. The 10 s is sing-box's own fixed per-query
  deadline, and at it the query is **dropped silently**.
- **"Add a non-proxied fallback resolver" cannot be done either.** The DNS rule chain never falls
  through on failure, and `dns.final` is the no-rule-matched routing default, not a failure fallback.
  The only lever would have been re-pointing `final` to the domestic resolver — which was **rejected on
  the merits** (Q-17): the no-rule-matched class is the foreign internet, so it would have changed
  answers permanently and disclosed every foreign name to the domestic resolver **on every healthy
  host**, to buy resolution of names whose destinations are unreachable anyway while the node is down.
- **What therefore remains true and is filed as R-23:** a name whose only resolver is reached through a
  node stays unresolvable while that node accepts and never answers.

No user-facing surface claims either capability; that prohibition is mechanically checked (K-16 + V-21)
because the temptation to claim it was real and was caught twice.

### Limits of the evidence (gate condition C-11, from `06`)

No behavioural run exercises the shipped document's TUN capture path, `route.rules[0]`'s
`process_name` rule, the real DoH transport for `remote_dns` (derived to plain UDP; M-5 leaves
DoH-versus-UDP unestablished and nothing rests on it), or T-15's `proxy` selector / `auto` urltest
group. The shipped document itself is evidenced only by V-3's differential and V-7's real
`sing-box check`. **BC-14 is recorded UNOBSERVED, not green** — nothing tests whether a node reachable
only over IPv6 becomes unreachable under suppression, and no shipped text claims more than "a node
whose address resolves only over IPv6 needs `sc ipv6 on`".

### Safety record

Live service provably untouched at every checkpoint of every stage: `MainPID=2566751` /
`ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`, witnessed with `systemctl show`, never
`is-active`. `/usr/local/bin/sc` never invoked and the 2026-08-01 `.bak` never read, restored or
deleted; `_init_files()` never driven; all eight path constants repointed into one `mkdtemp()` root and
asserted inside it; no `PUT`/`PATCH`/`DELETE` ever reached the live Clash API. Every fixture sing-box
ran unprivileged with no TUN inbound, its own cache path and its own Clash port, and none survived.

### Note on the host's hand-patch

The 2026-08-01 `sed` patch to the **installed** `/usr/local/bin/sc` (`query_type: [28, 64, 65]`) is
overwritten by the next `install.sh` **by design**. The shipped default reproduces its effect on this
host — `/proc/net/if_inet6` holds only `fe80::/10` entries plus `::1`, so `auto` suppresses — and does
so mode-independently, regenerated from source rather than patched into it, and reversible with
`sc ipv6 on`. Nothing in this task reads, restores or deletes the backup.

## Insight

- 2026-08-14 · sing-box 1.13.15 has **no DNS-query-level timeout at any level** — `"timeout"` is rejected on a DNS server, on the `dns` block and on a DNS rule, with a bogus-key control proving the decoder rejects unknown fields — and its own per-query deadline is a fixed 10.0 s at which the query is **dropped silently**, with no answer, no retry and no second server · evidence: dns-resilience
- 2026-08-14 · A sing-box DNS rule chain **never falls through on failure**: a black-holed, `NXDOMAIN` or `SERVFAIL` answer is final, and `dns.final` is the *no-rule-matched* routing default rather than a failure fallback — so an always-true catch-all rule makes `final` structurally unreachable, and "add a fallback resolver" is not expressible in the document at all · evidence: dns-resilience
- 2026-08-14 · `geosite-private` matches the reserved TLD `test`, so a probe name like `probe.test` is **not** "matched by no DNS rule" — it is routed to `direct_dns`, silently invalidating any measurement of the no-rule class that uses a `.test` name · evidence: dns-resilience
- 2026-08-14 · sing-box 1.13.15 refuses to start when a DNS server's `detour` names a bare `{"type":"direct"}` outbound (`FATAL start dns/udp[remote_dns]: detour to an empty direct outbound makes no sense`) while accepting a `selector` whose only member is `direct` — so a fixture can pass `sing-box check` and still die at run · evidence: dns-resilience
- 2026-08-14 · `Path.read_text()` behind any of `bin/sc`'s eight repointable path constants can raise `UnicodeDecodeError`, which is a `ValueError` and **not** an `OSError`, so the repo's habitual `except OSError` lets it through as a traceback — `bin/sc:1712` already guards with `(OSError, ValueError)` while `_load_lang()` at `:312` does not · evidence: dns-resilience
- 2026-08-14 · `git diff --stat`'s bar column counts insertions **plus** deletions, so quoting it as an added-line count inflates the number and silently rescopes any "the added lines were scanned" claim built on it — the added count is `--numstat`'s first field, or the `N insertions(+)` trailer · evidence: dns-resilience
- 2026-08-14 · `dig … ANY` uses TCP, so an `ANY` probe against a UDP-only fixture inbound returns `connection refused` in ~16 ms and measures the harness rather than the document, while `MX`/`TXT` of the same name behave as the no-rule class · evidence: dns-resilience

## Verdict

DELIVERED
