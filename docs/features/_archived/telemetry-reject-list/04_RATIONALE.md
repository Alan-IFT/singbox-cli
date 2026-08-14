# 04 — Development rationale · T-17 `telemetry-reject-list`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

Every transcript below is from this stage, on this host, against the real
`/usr/local/bin/sing-box version 1.13.15` (`go1.25.12 linux/amd64`). The live service was
witnessed with `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` at the start of the
task, after every fixture group and at the end: `MainPID=2566751`,
`ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`, unchanged throughout.

## Safety envelope, as actually enforced

Every fixture loads `bin/sc` through the `docs/dev-map.md:109-142` recipe verbatim, repoints all
eight path constants into one `mkdtemp()` root and **asserts** each resolves inside it, sets
`SYSTEMD = OPENRC = False`, and never drives `_init_files()`. `/usr/local/bin/sc` was never
invoked. No `PUT`/`PATCH`/`DELETE` reached the live Clash API — the only `PATCH /configs` calls
went to the fixture instance's own controller on `127.0.0.1:29091`. The second sing-box ran
unprivileged with no TUN inbound, its own `cache_file.path` and its own Clash port, and every
instance was terminated in a `finally`/`__exit__`.

Two deviations from the letter of the envelope, both taken deliberately and both **more**
restrictive than the text:

- The envelope says to witness the service with `systemctl show`, and to shim `systemctl` /
  `rc-service` for AC-11/AC-12. Because `SYSTEMD = OPENRC = False` is mandatory,
  `restart_service()` can reach **no** init system at all — there is nothing for a shim to
  observe, and a shim would have been vacuous. The witness used instead is a recording wrapper
  bound over the module's own `restart_service`, which fires on the changing run (V-12: exactly
  1) and not on the no-op one (V-12: 0). That is a strictly stronger witness than a PATH shim,
  because it cannot be bypassed by the code path under test.
- `_init_files()` was replaced, not driven, by a function doing exactly what it does minus its
  hard-coded `/var/lib/sing-box` `mkdir` (`.harness/insight-index.md`). `_resolve_clash_port()`
  was replaced by a constant so no socket is opened and no mtime witness is perturbed by it.

The `sing-box check` runs read the host's real `.srs` bytes from `/etc/sing-box/rules/` — a
read, never a write.

## C-3 — the three names, checked first-hand

The check that mattered. Recorded verbatim:

```
$ dig +nocookie +noall +comments +answer telemetry-coverage.mozilla.org A     # system resolver
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 45980
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

$ dig +nocookie @8.8.8.8   telemetry-coverage.mozilla.org A → status: NXDOMAIN, ANSWER: 0
$ dig +nocookie @223.5.5.5 telemetry-coverage.mozilla.org A → status: NXDOMAIN, ANSWER: 0
$ dig +nocookie @1.1.1.1   telemetry-coverage.mozilla.org A → status: NXDOMAIN, ANSWER: 0

# non-vacuity control on the same resolver — the rig can see a name that DOES exist:
$ dig +nocookie @8.8.8.8 incoming.telemetry.mozilla.org A → status: NOERROR, ANSWER: 3
```

Four independent resolvers, one control. N-7 is **dropped**. C-3 forbids substituting a
corrected spelling, and I did not: the gate's own recollection of a `coverage.telemetry.mozilla.org`
-shaped host is exactly the kind of guess that would smuggle a new member past K-10, and a new
member is the gate's to admit, not mine.

```
$ dig +nocookie +noall +answer ulogs.umeng.com A
ulogs.umeng.com.                            107 IN CNAME ulogs.umeng.com.gds.alibabadns.com.
ulogs.umeng.com.gds.alibabadns.com.         107 IN CNAME alog-default.umeng.com.
alog-default.umeng.com.                     107 IN CNAME alog-default.umeng.com.gds.alibabadns.com.
alog-default.umeng.com.gds.alibabadns.com.  107 IN A     223.109.148.141

$ dig +nocookie +noall +answer data.mistat.xiaomi.com A
data.mistat.xiaomi.com.                     25 IN CNAME data.mistat.xiaomi.com.mgslb.com.
data.mistat.xiaomi.com.mgslb.com.           25 IN CNAME data.mistat.xiaomi.com.download.ks-cdn.com.
data.mistat.xiaomi.com.download.ks-cdn.com. 25 IN CNAME l5.gslb.ksyuncdn.com.
l5.gslb.ksyuncdn.com.                       25 IN A     119.96.37.2 / 119.96.37.6
```

Both exist and both ship. N-18 resolving *through* a CDN provider's GSLB does not make it a
CDN-content endpoint: the delivery path is the CDN's, the host's role is MiStat upload, and
blocking the name blocks only that host.

The other fifteen were checked on the same pass and all return `NOERROR` (`demdex.net` and
`mmstat.com` return `NOERROR` with no A record at the apex, which is normal for a zone whose
records live on subdomains — and irrelevant to a `domain_suffix` match).

## C-4 — the measurement that forced DD-1 and DD-2

### The published anchor does not exist under `allow`

```
== 1. the 02/I-9 anchor {"rcode": "NXDOMAIN"} — where it exists ==
ok      candidate / block : applied cleanly
RAISES  candidate / allow : OverrideError: at dns.rules: $before matched 0 elements, but exactly one is required — match: {"rcode": "NXDOMAIN"}
        rendered: Cannot use …/etc/override.json: at dns.rules: $before matched 0 elements, but exactly one is required — match: {"rcode": "NXDOMAIN"}
RAISES  HEAD clone / n/a   : OverrideError: at dns.rules: $before matched 0 elements, but exactly one is required — match: {"rcode": "NXDOMAIN"}
        rendered: Cannot use …/etc/override.json: at dns.rules: $before matched 0 elements, but exactly one is required — match: {"rcode": "NXDOMAIN"}
```

This is C-1's message, recorded verbatim. It is also the whole of C-4's case.

### …so BC-14's first recourse fails on the host that used its second

`sc telemetry allow`, driven through the real `main()` on a fixture carrying that `override.json`:

```
        exit=1
        | Telemetry name rejection → allow
        | Listed names resolve normally
        | Cannot use …/etc/override.json: at dns.rules: $before matched 0 elements, but exactly one is required — match: {"rcode": "NXDOMAIN"}
```

The setting **is** persisted before the failure (the two printed lines are past
`save_settings()`), so the host ends up recorded as `allow` with a `config.json` that was never
regenerated — the worst of both. `reload_or_restart()` (`sc:1822-1826`) does not catch
`OverrideError`; `main()`'s renderer turns it into `sys.exit(...)`, hence exit 1.

### The replacement anchor exists everywhere it must

`{"server": "hosts_dns"}` with `$after`, 18 combinations — candidate × {block, allow} ×
{rule-sets usable, none} × {except, add, both}, plus the HEAD clone × {rule-sets, none} ×
{except, add, both} — all applied cleanly, and in every one the user's rules land at index 2
(and 2–3 for the combined form) with the shipped reject rule immediately after at 3 (or 4):

```
ok  candidate / block / except / rulesets=True   user=[2] mine=[]  shipped=[3]
ok  candidate / block / both   / rulesets=True   user=[2] mine=[3] shipped=[4]
ok  candidate / allow / both   / rulesets=False  user=[2] mine=[3] shipped=[]
ok  HEAD clone / block / both  / rulesets=True   user=[2] mine=[3] shipped=[]
…18/18
```

Real `sing-box check` accepts all three recipes' documents. Why `hosts_dns` and not something
else: it is the one `dns.rules` element that is neither emitted by an overlay (so no setting can
remove it) nor carries a `rule_set` key (so `_filter_rules()` cannot delete it), and `$after` on
it is the *only* slot that is simultaneously after the hosts table — which BC-11 requires, and
which is what stops a user's own extension breaking `sc`'s DoH bootstrap — and before everything
that chooses a resolver.

### Two directives on one array

```
RAISES  OverrideError: at dns.rules: $after cannot be combined with other keys in the same object
```

Quoted in both READMEs so a user who tries it recognises the message.

## C-5 — what actually happens, including the part nobody asked about

Set form, `settings.json` = `{ this is not json`:

```
exit=1
  File "/usr/lib/python3.12/json/decoder.py", line 353, in raw_decode
    obj, end = self.scan_once(s, idx)
json.decoder.JSONDecodeError: Expecting property name enclosed in double quotes: line 1 column 3 (char 2)
```

Exactly as `sc ipv6 off` does today. No guard added.

Then the case C-5 did not ask for, found because the harness itself tripped over it —
`settings.json` = `\xff\xfe\x00not utf-8`:

```
set  form                exit=1  UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 0
show form                exit=1  UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 0
`sc ipv6 show` control   exit=1  UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 0
```

The `show` form is supposed to be the guarded one. It is not, because I-3 mandates
`_ipv6_setting()`'s guard tuple verbatim and `UnicodeDecodeError` is a `ValueError`. The third
line is the control that makes this a **pre-existing** hole rather than something T-17
introduced: identical behaviour, identical message, on code this task did not touch. D-10 and
C-5 both forbid widening the tuple, so the finding is recorded in `04_DEVELOPMENT.md` and the
function's docstring names both holes explicitly, so the next reader is not misled by the word
"silently".

Non-JSON but valid UTF-8, `show` form: exits 0 and prints `Telemetry name rejection → block`
with no traceback — the guard's real scope, confirmed.

## V-5 — why the first `sing-box check` run failed, and what that taught

The first attempt seeded the fixture's four `.srs` files with `b"SRS" + b"\x01" + os.urandom(4096)`
— bytes that satisfy `srs_reject_reason()`'s magic and size floor, which is what `sc`'s own
usability model checks. Five of six states failed:

```
FAIL V-5 1 node, block  rc=1  FATAL initialize router: parse rule-set[0]: zlib: invalid header
ok   V-5 1 node, block, all rule-sets unusable  rc=0
```

Only the all-unusable case passed, because it is the only one that references no rule-set.
`sing-box check` fully **parses** every rule-set the document names; `sc`'s usability model
deliberately does not. Fixed by copying the host's real `.srs` bytes in read-only. All six states
then pass. This is worth carrying: any future `check`-based fixture that fakes a rule-set is
testing one state and reporting six.

## V-27b — the observation that came back inconclusive, and why splitting it is not cheating

Run as AC-B6b writes it, one observation classified `[D]`:

```
V-27b exception [D] INCONCLUSIVE the excepted name resolves and reaches a stub
              candidate: NOERROR ANSWER:1 stub=direct 18.5ms
              control  : NOERROR ANSWER:1 stub=direct 19.1ms (HEAD exhibits the defect)
```

The control agrees instead of reproducing, so NFR-8 makes it inconclusive. That is the correct
report and it is kept. The reason is not a rig problem: at HEAD the name resolves because there
is nothing to except, and at the candidate it resolves because the exception works — the *same
outcome from opposite causes*. The half that distinguishes them is the other one, which AC-B6b
states in the same sentence and does not classify separately:

```
V-27b-i  [A] pass  the excepted name resolves and reaches a stub
         candidate: NOERROR ANSWER:1 stub=direct 9.8ms
         control  : NOERROR ANSWER:1 stub=direct 18.6ms  (HEAD agrees)
V-27b-ii [D] pass  every OTHER listed name stays rejected (5 checked)
         candidate: app-measurement.com=NXDOMAIN/0/stub=None; hm.baidu.com=NXDOMAIN/0/stub=None;
                    telemetry.microsoft.com=NXDOMAIN/0/stub=None; demdex.net=NXDOMAIN/0/stub=None;
                    mmstat.com=NXDOMAIN/0/stub=None
         control  : app-measurement.com=NOERROR/1/stub=remote; hm.baidu.com=NOERROR/1/stub=direct;
                    telemetry.microsoft.com=NOERROR/1/stub=remote; demdex.net=NOERROR/1/stub=remote;
                    mmstat.com=NOERROR/1/stub=remote  (HEAD exhibits the defect)
```

C-2 orders classification "per *observation*, not per step". AC-B6b is one criterion holding two
observations; the split applies C-2's own rule rather than relaxing it, and both the bundled
result and the split results are reported.

## The behavioural rig

Three derivations, and nothing else about the emitted document is touched:

1. the TUN inbound → `{"type": "direct", "tag": "tun-in", "listen": "127.0.0.1",
   "listen_port": 15353, "network": "udp"}`. `{"action": "sniff"}` stays ahead of the
   `hijack-dns` rule (K-17) because `route.rules` is emitted unmodified;
   `route.default_domain_resolver` stays present for the same reason.
2. `remote_dns` and `direct_dns` → local UDP stubs on 15354 / 15355, **tag, array order and
   `detour` preserved** (`remote_dns` keeps `detour: "proxy"`); `local_local` repointed too so
   nothing can reach a real resolver.
3. node state at the `proxy` outbound only: a selector over `direct` for the reachable case, and
   for BC-3 a `socks` outbound pointed at a TCP listener that accepts and never answers. Never
   at a stub — a stub that lies is a rig that proves nothing.

The stubs record `(name, qtype)` per query and answer `A 203.0.113.10` / `203.0.113.20`, which is
what makes "which resolver would have answered this" observable per probe. Every probe is
`dig +nocookie +tries=1` (K-18); `dig … ANY` is never used (K-17).

Non-vacuity, before any assertion was trusted — the same rig, same instance, three names:

```
example.org      NOERROR   ANSWER:1  qr rd ra      18.4 ms   remote stub saw it
hm.baidu.com     NXDOMAIN  ANSWER:0  qr aa rd ra   17.6 ms   neither stub saw it
www.qq.com       NOERROR   ANSWER:1  qr rd ra      17.7 ms   direct stub saw it
```

`aa` set on the rejection, absent on the resolved answers: the reject rule is answering
authoritatively and locally, which is Q-A's measurement reproduced independently here.

## Latency, honestly

V-30's ten `+nocookie` probes of a listed name: `9.6, 9.7, 11.3, 19.7, 20.2, 20.7, 20.9, 21.0,
21.5, 21.7` ms — no warm-up curve (the fastest probes are not the last ones), every one
`NXDOMAIN` with `ANSWER: 0` and no stub receipt. A `dig` subprocess costs ≈17.5 ms of startup on
this host, so **the 100 ms budget is being asserted with ≈82 ms of real headroom**, and the
sub-11 ms samples are the ones where the subprocess happened to start fast, not a different DNS
path. sing-box itself reports ~4 ms for this answer. No claim is made or tested about
client-side negative caching (K-12): the reply carries `AUTHORITY: 0` and no SOA, and what a
downstream client does with that was not measured.

## What was deliberately not done

- No `reject` action anywhere, not even as a control (K-4).
- No second matcher key on the rule, and no leading dot (K-5). The BC-9 near miss
  `notcrashlytics.com` reaches the same stub as at HEAD in all six combinations, so the
  false positive the `domain` + `.suffix` pairing would have defended against does not exist in
  this binary.
- `_dns_overlay()` and T-16's index-0 rule untouched (K-6); V-7 compares them byte for byte
  against HEAD by `ast` extraction, along with `_merge`, `_directive_of`, `_anchor_index`,
  `_apply_directive`, `DIRECTIVES`, `_load_override`, `_filter_rules`, `_runtime_overlay`,
  `_compose`, `CONFIG_BASE`, `_init_files`, `load_settings`, `save_settings`, `_write_private`,
  `cmd_ipv6` and `cmd_mode`. No `grep` was used for any freeze check (K-15).
- No seventh string (K-8); `Configuration regenerated; sing-box restarted` and `Reload failed`
  are reused. No per-name description in `show` (K-9).
- `main()`'s read-only opt-out arm untouched (K-14): `telemetry` takes the `else` arm, and
  `docs/dev-map.md`'s "don't add a `READ_ONLY_COMMANDS` set" pattern is intact.
- No Features-list bullet in either README: T-16's `sc ipv6` did not get one either, and adding
  one to a line-for-line-mirrored file for a feature whose own section is 100 lines away is
  scope the ledger does not carry.
- The intra-document link I first wrote from the new section to **Custom configuration** was
  removed in favour of naming the section in prose: neither README has any other `](#…)` link,
  so there is no established convention, and the GitHub anchor for a heading carrying an emoji,
  backticks and full-width parentheses is a guess that fails silently.

## FR-10 report, confirmed by implementation (RS-1)

Nothing was inexpressible. `$before` with an object anchor on an array `CONFIG_BASE` already
defines carried the whole change: no new directive, no new file, no new persisted state beyond
one key, one changed statement in `generate_config()`. The one thing that remains inexpressible
— extending the shipped rule's own name array in place — was already re-homed to the second-rule
recipe by Q-10, and the recipe is measured working here.

The one place the design was **larger** than it needed to be is the one the gate named as F-2:
two published anchors, one of which existed in a single state. After DD-1/DD-2 there is one
published anchor, used by all three recipes, valid in every state. That is smaller in the only
way that counts — the number of things a user must hold — and it is the direct consequence of
the gate having refused to name the anchor itself and left the choice, with its evidence
obligation, at this stage.
