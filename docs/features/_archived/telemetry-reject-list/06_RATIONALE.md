# 06 — QA rationale · T-17 `telemetry-reject-list`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

Every transcript below is from this stage, on this host, against the real
`/usr/local/bin/sing-box version 1.13.15` (`go1.25.12 linux/amd64`). The rig was **built
from scratch at this stage** from the acceptance criteria (RES-2) — stage 4's harness in the
shared scratch directory was neither imported nor read before mine ran. Sources live in
`/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/qa6/`:
`rig6.py` (library), `run_behav.py` (matrix), `compare.py` (control classification),
`struct6.py`, `deletion6.py`, `cmd6.py`, `docs6.py`, `adv6.py`, `boundary6.py`,
`boundary6b.py`, `freeze.py`, `freeze_nonvacuity.py`, `names6.py`, `stability6.py`,
`latency6.py`.

## Safety envelope, as actually enforced

- `bin/sc` is loaded with the `docs/dev-map.md:109-142` recipe verbatim (`rig6.load_sc`);
  `/usr/local/bin/sc` was **never** invoked.
- All eight path constants are repointed into one root and each is **asserted** to resolve
  inside it — `assert str(p) == str(root) or str(p).startswith(str(root) + os.sep)` — for
  `CFG_DIR / CFG_PATH / NODES_PATH / SETTINGS_PATH / RULES_DIR / OVERRIDE_PATH / STATE_PATH /
  IF_INET6_PATH`. Every load in every script goes through that one function.
- `SYSTEMD = OPENRC = False`. `_init_files()` was **never driven**; where `main()` needs it,
  it is *replaced* by the same body minus the hard-coded `/var/lib/sing-box` mkdir, and
  `_resolve_clash_port()` is replaced by a constant so no socket is opened and no mtime
  witness is perturbed.
- The fixture sing-box ran unprivileged, with no TUN inbound, its own `cache_file.path`
  inside the fixture and its own Clash port **29491**. The live controller is 29090
  (`/etc/sing-box/settings.json`) and received no request of any method. Every instance was
  terminated in `SingBox.__exit__`.
- `/etc/sing-box/rules/*.srs` was **read** (never written) to give the fixture real
  rule-set bytes — without them `sing-box check` fails with `zlib: invalid header` and only
  the all-unusable state is testable.
- Service witness, start and end of this stage:
  `MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` — identical.

Two deviations from the letter of the envelope, both deliberate and both **stronger** than
the text:

1. The envelope says to shim `systemctl` / `rc-service`. With `SYSTEMD = OPENRC = False`
   mandatory, `restart_service()` can reach no init system at all, so a PATH shim would be
   vacuous. The witness used instead is a recorder bound over the module's own
   `restart_service` — it cannot be bypassed by the code under test. (Same reasoning stage 4
   gave; reached independently.)
2. `redirect_stdout` is **not** thread-local, so the concurrency probe swaps `sys.stdout`
   process-wide around the whole race instead of per thread. The first attempt lost its own
   output to a leaked `StringIO` — recorded here because it is exactly the class of harness
   defect that turns a green into an artifact.

## RES-1 — AC-7's freeze, run mechanically (K-15)

`freeze.py` parses both revisions with `ast`, slices each symbol's exact source bytes by
node line span, and sha256s them. No `grep` anywhere.

```
IDENTICAL DIRECTIVES           RES-1  head=127be025ed8b3495 cand=127be025ed8b3495 bytes=70/70
IDENTICAL _merge               RES-1  head=33ea964355f8e787 cand=33ea964355f8e787 bytes=2504/2504
IDENTICAL _load_override       RES-1  head=8fe2b0ab64ecc122 cand=8fe2b0ab64ecc122 bytes=3385/3385
IDENTICAL _filter_rules        RES-1  head=6656a7f1c68b7f60 cand=6656a7f1c68b7f60 bytes=1403/1403
IDENTICAL _dns_overlay         RES-1  head=8545a7cf9b308c73 cand=8545a7cf9b308c73 bytes=1251/1251
IDENTICAL ipv6_decision        RES-1  head=16c2662c266475fe cand=16c2662c266475fe bytes=2053/2053
IDENTICAL _ipv6_setting        RES-1  head=75418000f45047fc cand=75418000f45047fc bytes=1269/1269
IDENTICAL _runtime_overlay     RES-1  head=86634ba41fd96d99 cand=86634ba41fd96d99 bytes=3193/3193
… (_directive_of, _anchor_index, _apply_directive identical too)
25/25 symbols byte-identical (RES-1 set: 11)
```

The 14 extras beyond RES-1's list are `_compose`, `CONFIG_BASE`, `_init_files`,
`load_settings`, `save_settings`, `_write_private`, `cmd_ipv6`, `cmd_mode`,
`_global_ipv6_iface`, `_dig`, `ruleset_report`, `RULESET_FILES`, `_valid_selection`,
`reload_or_restart` — the rest of stage 2's frozen set.

Non-vacuity of the comparator itself, and the K-15 trap demonstrated rather than asserted:

```
comparator on a 1-space, semantically-null mutation of _merge: DIFFERS (comparator can see a change)
  sha cand=33ea964355f8e787 mutant=2f392b82d3301edf
K-15 trap demonstrated: 'timeout=3' in 'r = subprocess.run(cmd, timeout=30)' -> True
```

## The rig, and the non-vacuity proof that precedes every assertion

Three derivations of the emitted document and nothing else: the TUN inbound becomes
`{"type": "direct", "tag": "tun-in", "listen": "127.0.0.1", "listen_port": 15353,
"network": "udp"}` (so `route.rules` — `{"action": "sniff"}` ahead of `hijack-dns` — and
`route.default_domain_resolver` are emitted untouched, K-17); `remote_dns` / `direct_dns` /
`local_local` are repointed at two recording UDP stubs on 15354 / 15355 with tag, array
order and `detour: "proxy"` preserved; `cache_file.path` and the Clash controller move
inside the fixture. Node state is staged at the `proxy` outbound only — a stub that lies is
a rig that proves nothing. Every probe is `dig +nocookie +tries=1` (K-18); `dig … ANY` is
never used.

Before any assertion was trusted, one instance, four names:

```
example.org          A  NOERROR   ANS=1 [qr rd ra]    stub=remote  qtime=2ms wall=18.3ms
hm.baidu.com         A  NXDOMAIN  ANS=0 [qr aa rd ra] stub=None    qtime=2ms wall=18.3ms
www.qq.com           A  NOERROR   ANS=1 [qr rd ra]    stub=direct  qtime=2ms wall=19.6ms
notcrashlytics.com   A  NOERROR   ANS=1 [qr rd ra]    stub=remote  qtime=2ms wall=20.1ms
```

The rig can see a resolved answer, a rejected one, and *which* resolver would have answered
— on the same instance, in the same second. `aa` is set on the rejection and absent on the
resolved answers.

## The control matrix

`run_behav.py` runs 12 scenarios at **one** fixture path (`…/qa6/fx`) — S1 block/rule-sets,
S1tcp, S2 no-rule-sets, S3 `allow`, S4 zero nodes, S5 node-accepts-never-answers, S6a/S6b
add recipe under both settings, S7 exception recipe (all 17 names), S7c combined recipe,
S8sup/S8on for BC-10, S9 latency — then the **identical** script runs against the pristine
HEAD clone (`git clone --no-hardlinks`, `69341b5`, working tree clean) at the **same** path.
`compare.py` pairs them and applies one classification per **observation**.

Result: **95 observations — 93 PASS, 0 FAIL, 2 INCONCLUSIVE. [D] 52 / [A] 43.**

### The two inconclusives, in full

```
O-B6b-asWritten  AC-B6b (as written)  [D] INCONCLUSIVE  S7|rule|hm.baidu.com|A
                 cand=NOERROR/1/stub=direct   head=NOERROR/1/stub=direct
O-ADV-allowUser  adversarial/BC-8     [D] INCONCLUSIVE  S6b|rule|hm.baidu.com|A
                 cand=NOERROR/1/stub=direct   head=NOERROR/1/stub=direct
```

The first is DD-5 reproduced independently: run as AC-B6b writes it, the control can only
agree — at HEAD the name resolves because there is nothing to except, at the candidate it
resolves because the exception works; the same outcome from opposite causes. The split
halves both pass (`O-B6b-i` `[A]`, and 16 × `O-B6b-ii` `[D]`), so DD-5 is upheld — and the
*bundled* result is carried into the contract's headline, which is RES-4.

The second is **my own mis-declaration**, kept rather than quietly re-classed: I declared
"under `allow` the shipped names resolve while the user's stay rejected" as `[D]`, but under
`allow` there is no HEAD defect to reproduce — it is an agreement observation by
construction, exactly AC-B6b's shape. The half that carries information is
`O-B6a-allow` (`[A]`, PASS): the user's own name is still rejected under `allow`.

### One classifier correction, recorded rather than buried

`O-B10-aaaa-on` (an AAAA query for a listed name with suppression **off**) first came back
INCONCLUSIVE because I had encoded AC-B1's defect predicate as "HEAD resolves it", and this
rig's stub answers `A` only, so HEAD returned `NOERROR/0` — with `stub=direct`. AC-B1's own
text is "the HEAD run resolves both names **and a stub records them**"; the stub receipt is
the leak the feature exists to prevent, and it was recorded. The predicate was corrected to
the criterion's wording. No implementation byte changed; the candidate's outcome
(`NXDOMAIN`, `ANSWER: 0`, no receipt) was the same before and after.

### AC-B4's count, as actually run

4 probe names (`nothm.baidu.com`, `www.qq.com`, `www.google.com`, `example.org`) × 3 modes ×
2 rule-set states = **6 per probe name, 24 in total** — C-10's correction, reproduced. In all
24 the candidate reaches the same stub as HEAD. `example.org` is matched by no DNS rule and
is not a `.test` name (K-17).

### AC-B5's three shapes

```
S2 (all four rule-sets unusable) rule/global/direct : NXDOMAIN ANS=0 aa, no stub receipt
S4 (zero nodes, C-10/BC-1)       rule/global/direct : NXDOMAIN ANS=0 aa, no stub receipt
S5 (node accepts, never answers) rule/global/direct : NXDOMAIN ANS=0 aa, no stub receipt
HEAD control, S5|global                             : NO-ANSWER after 6020.7 ms
```

The HEAD stall is the predicted ≈10 s deadline, cut short by `+time=6`; `[D]` is defined
negatively ("resolves it or leaves it unanswered, never `NXDOMAIN`"), so the stall satisfies
it and is not read as inconclusive. BC-1's behavioural clause is therefore **observed**, not
merely `check`-ed.

### RES-3 — AC-B6b's `[D]` half over the full census

With the README exception recipe in `override.json`, `hm.baidu.com` resolves
(`NOERROR/1/stub=direct`) and **all sixteen** other shipped names were probed, not five:

```
telemetry.microsoft.com NXDOMAIN/0/None   vortex.data.microsoft.com NXDOMAIN/0/None
vortex-win.data.microsoft.com NXDOMAIN/0/None  metrics.ubuntu.com NXDOMAIN/0/None
daisy.ubuntu.com … incoming.telemetry.mozilla.org … google-analytics.com …
app-measurement.com … crashlytics.com … demdex.net … scorecardresearch.com …
cnzz.com … mmstat.com … ulogs.umeng.com … tracking.miui.com … data.mistat.xiaomi.com
  — 16/16 NXDOMAIN, ANSWER: 0, aa set, no stub receipt; HEAD resolves all 16 via a stub
```

No sample, no stated limit needed: the criterion says *every*, and every one was observed.

## Latency, honestly

575 timed probes across 5 repetitions.

```
dig subprocess overhead (wall - dig's own Query time): min=4.1 p50=15.5 p95=17.0 max=19.7 ms
REJECTED-name probes: 290
  sing-box-side query time : min=2 p50=3 p95=4 max=7 ms
  end-to-end wall time     : min=7.4 p50=18.3 p95=20.2 max=25.8 ms
```

So the honest statement is: **a `dig`-driven assertion against FR-3's 100 ms budget is
asserting ≈84 ms of headroom, not 100 ms**, because ≈15.5 ms of every wall-clock sample is
the `dig` process itself. sing-box's own reported query time for a rejection is 2–7 ms with
no warm-up curve (the fastest samples are not the last ones). **No claim is made or tested
about client-side negative caching** (K-12): the reply carries no SOA, and what a downstream
client does with that was not measured.

## Structural criteria, independently re-derived

`struct6.py` — 0 failures. Highlights:

```
AC-1  key set and order = ['action', 'rcode', 'domain_suffix']; no answer/rule_set/server;
      domain_suffix == list(TELEMETRY_NAMES), 17 names, no leading dot
AC-2  block/rulesets=True : hosts=1 < reject=2 < Global=3, Direct=4, remote_dns=[3, 5]
      block/rulesets=False: hosts=1 < reject=2 < Global=3, Direct=4, remote_dns=[3]
AC-3  four states: {clash_mode:Global}=1, {clash_mode:Direct}=1, {server:hosts_dns}=1;
      {rcode:NXDOMAIN}=1 under block, 0 under allow
AC-4  allow x {0,1,3 nodes} x {rule-sets, none}: 6/6 byte-identical to the pre-T-17 build
      at the SAME fixture path (5334 / 3573 / 5712 / 3951 / 6006 / 4245 bytes)
AC-5  real `sing-box check`: 6/6 states rc=0
AC-8  new module-level constants = ['TELEMETRY_NAMES']; imports unchanged; timeout= args
      3 before / 3 after (by ast, not grep); array guard still names three keys
```

AC-6's crude first encoding counted the *string* `TELEMETRY_NAMES` and reported 4 consumers
— two of them are docstring prose. Re-encoded over `ast.Name` load nodes: **2 code
consumers, lines 1728 and 2670**. That is the K-15 unsoundness in miniature, inside my own
checker, and it is why the freeze check was never allowed to be textual.

AC-6's deletion test (`deletion6.py`):

```
reference: overlay emits 17 names, setting=block
after deleting cmd_telemetry()'s consumer: overlay still emits 17 names, identical=True
after deleting cmd_telemetry()'s reader:   _telemetry_overlay() under allow -> {}
                                           under block -> 17 names, identical=True
```

## Command surface (`cmd6.py`) — 0 failures

`main()` is driven for real. Selected evidence:

```
AC-10  en/zh x block/allow/show: exit 0, no CR; show prints 19 lines = setting + meaning
       + 17 names, and `lines[2:] == list(TELEMETRY_NAMES)` (order included)
       zh first line: '遥测域名拦截 → block'   (lang seeded in the fixture settings.json —
       main() reassigns LANG, so setting sc.LANG alone would have rendered English)
AC-11  cmd_telemetry('show') driven directly: 7 files, not one mtime or size changed;
       restart recorder 0 calls; same on a host with no config.json and zero nodes
AC-12  no-op set: exit 0, restarts=0, config.json never generated, FR-8 line names
       `sc reload`;  changing set: exit 0, restarts=1 (the SAME witness fires),
       config.json mtime changed, and no reject rule under `allow`
C-8    'yes' -> `sc telemetry block`: file changes to block, exactly 1 stderr line,
       restarts=0, FR-8 line printed, exit 0
AC-13  absent file / absent key -> 'block', 0 stderr lines, no traceback (en and zh);
       unrecognised value -> 'block' + exactly 1 stderr line naming file, key, both values
AC-14  BLOCK, Allow, Show, SHOW accepted after lower-casing; on, off, xyz exit 1, name the
       three accepted values, and the fixture snapshot is byte-for-byte unchanged
AC-15  BC-13 upgrade: first `sc reload` exit 0 with 0 drift warnings; second exit 0, stderr ''
```

C-5, re-measured with its control:

```
_telemetry_setting() on non-JSON settings.json -> 'block'  (guarded, silent)
the SET form on the same file raises JSONDecodeError       (unguarded, pre-existing)
non-UTF-8 file: _telemetry_setting() raises UnicodeDecodeError
                HEAD's _ipv6_setting() raises UnicodeDecodeError   <- the control
```

## Documents and recipes (`docs6.py`) — 0 failures

Both READMEs are **432 / 432** lines with all 25 headings, all 42 fence lines and all 63
table rows on identical line numbers; the shipped list table has 17 rows; C-6's mode
sentence is in both. `04_DEVELOPMENT.md:40` and `05_CODE_REVIEW.md:64` say 433 — off by one,
filed as D-1.

The three fenced recipes are byte-identical across the two languages and each was planted as
`override.json` and pushed through `generate_config()` on **both** revisions × both settings
× both rule-set states — 24 runs, all applying cleanly, the user's rules always ahead of the
shipped one:

```
recipe 3 / candidate / block / rulesets=True : applied=True user=[2, 3] shipped=[4]
recipe 3 / HEAD      / allow / rulesets=False: applied=True user=[2, 3] shipped=[]
```

Two checker defects were found and corrected here, neither an implementation problem:
the K-11 scan flagged `这里不在 IP 层或路由层拦截任何东西` — the **negation** K-11 requires;
and AC-19 was first encoded as "telemetry and update-interval start at the same column",
which D-7 never said. The convention D-7 authorised is *two spaces after an overflowing left
column*: `telemetry <block|allow|show>` is 28 chars → column 32, `update-interval
<freq|show>` is 27 → column 31, and the fitting `ipv6` row pads to 30. Re-encoded against
the convention, both help blocks pass.

## Adversarial round 2 (`adv6.py`)

DD-1's defect, re-measured independently — this is C-4's whole case, and C-1's message
verbatim:

```
stage-2 anchor {"rcode": "NXDOMAIN"} (NEVER shipped)  exit=1
  Cannot use …/etc/override.json: at dns.rules: $before matched 0 elements, but exactly
  one is required — match: {"rcode": "NXDOMAIN"}
shipped anchor {"server": "hosts_dns"}                exit=0
  Configuration regenerated; sing-box restarted
```

BC-6, the documented contract: an override that `$replace`s `dns.rules` leaves
`[{"server": "direct_dns"}]` and the reject rule is gone — `generate_config()` returns True.
Nothing here defends against it, as designed.

Boundary names, one instance:

```
aaaa…(63 chars).hm.baidu.com          NXDOMAIN ANS=0 aa   stub=None
x.x.x…(20 labels).hm.baidu.com        NXDOMAIN ANS=0 aa   stub=None
X.Hm.BaiDu.CoM                        NXDOMAIN ANS=0 aa   stub=None
xn--hm-baidu-0m3f.com  (IDN look-alike) NOERROR ANS=1     stub=remote
baidu.com  (the PARENT of a listed name) NOERROR ANS=1    stub=direct
hm.baidu.com.cn                       NOERROR ANS=1       stub=direct
```

The last three are the ones worth stating: the list is a **suffix** list, so the parent of a
listed name, a different TLD under the same prefix, and a punycode look-alike are all
untouched. Over-matching would have been the dangerous failure and it does not occur.

## Boundary round (`boundary6.py`, `boundary6b.py`)

A `settings.json` that is valid JSON but **not an object**:

```
content              T-17 _telemetry_setting()          HEAD _ipv6_setting() (control)
null                 TypeError: argument of type 'NoneType' is not …   (identical)
"telemetry"          TypeError: string indices must be integers …      (identical)
42                   TypeError: argument of type 'int' is not iter…    (identical)
[]                   'block'                            'auto'
{"telemetry": 5 / null / ["block"]}   'block'           'auto'
```

Concurrency (BC-17), 10 parallel set-form invocations, with HEAD's own `sc ipv6` as control:

```
candidate T-17   sc telemetry  -> 5/10 raised ['JSONDecodeError'] ; settings.json still parses: True
HEAD (pre-T-17)  sc ipv6       -> 1/10 raised ['JSONDecodeError'] ; settings.json still parses: True
```

`save_settings()` is a non-atomic `write_text()`, so a concurrent reader can see a truncated
file. It is byte-identical to HEAD (freeze check) and BC-17 declares this shape unchanged
and out of scope.

Persist-then-fail ordering, with control:

```
candidate T-17   sc telemetry allow  exit=1, settings['telemetry']='allow' persisted, config.json written=False
HEAD (pre-T-17)  sc ipv6 on          exit=1, settings['ipv6']='on'        persisted, config.json written=False
```

Identical at HEAD, so not a T-17 regression. It matters only because a *broken
`override.json`* is now reachable through a route T-17 documents; DD-1 removed the shipped
recipe that caused it, and this measurement is what shows the remaining exposure is the
generic one `sc ipv6` already has.

## C-3, re-measured (`names6.py`)

All 17 shipped names return `NOERROR` on the system resolver, `8.8.8.8` and `223.5.5.5`;
`telemetry-coverage.mozilla.org` (N-7, dropped at stage 4) returns `NXDOMAIN` on all three.
Stage 4's C-3 disposition is independently confirmed, including the drop.

## Stability (`stability6.py`)

The full matrix, 5 complete repetitions: 115 observation keys × 5 = **575 probes, 0 keys
whose `(status, answers, stub)` varied**. Elapsed 12.7 / 11.8 / 12.4 / 12.4 / 12.0 s. The
deterministic checkers (`freeze`, `struct6`, `cmd6`, `docs6`) were each re-run after every
edit to them and are pure functions of the tree.

## What was deliberately not done

- No `reject` DNS action anywhere, not even as a control (K-4).
- `.harness/**` was not edited — NFR-3 / K-13 put it outside the permitted diff, which is
  why `baseline.json` is untouched (it records `test_count: 0`; this project has no
  committed suite, out-of-scope item 10 / R-9) and why the operator obligation named in the
  contract travels to the PM instead of being appended to a file this task may not create.
- The live `sing-box` was not restarted, reloaded or stopped, and no `PUT`/`PATCH`/`DELETE`
  reached 127.0.0.1:29090.
- No upstream document was modified.
