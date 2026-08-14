# 06 — Test rationale · T-19 `ruleset-staleness-visibility`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

## Trigger log

- **T6.1** — fired for AC-B3 / V-3, whose verification step in `02` states a mechanism the gate had
  already found false (F-4). `02_RATIONALE.md` was opened and says nothing about V-3's lever;
  `03_RATIONALE.md` carries C-2's and C-4's reasoning. The correction is in the contract portion
  under `## C-4`, measured rather than argued.
- **T6.2** — fired twice: for D-1's merged-capture measurement (`04_RATIONALE.md`, present, read,
  and then **re-measured from scratch plus mutated**), and for C-2, which stage 4 explicitly did not
  measure. Neither measurement was inherited.
- **T6.3** — fired for CR-3 (the `29090` fixture hazard). `05_RATIONALE.md` was opened for the D-1
  adjudication and for the six-state enumeration, which is reproduced independently below.

## Why the fixture set was rebuilt from scratch

Stage 4's fixtures share their assumptions with the code under test — including the
`clash_api_port: 29090` hazard stage 5 filed as CR-3 — so `qafix.py` and the seven drivers were
written from `01`'s AC table and `02`'s `## Verification plan` alone. Two consequences:

1. The independent fixture reached the same `is_running()` mechanism the gate reasoned to (F-4), but
   **by measurement**: an extra `is_running()` call added **no entry** to the stub log, a direct
   observation that no port, socket or command is consulted.
2. It also showed the C-8 check needed a mutant to be worth anything. A freeze that agrees can agree
   because the property holds or because the harness cannot see it; deleting `bin/sc:2869` from a
   copy of the candidate is what separates those two.

## Port 45733, proved free before use (CR-3 / RES-3)

```
$ ss -lntp | grep 29090      -> LISTEN 0 4096 127.0.0.1:29090 0.0.0.0:*   (the LIVE sing-box)
$ ss -lnt "sport = :45733" | grep -c LISTEN      -> 0
$ python3 -c "import socket; socket.socket().connect(('127.0.0.1',45733))" -> ConnectionRefusedError
```

`29090` is the live sing-box's Clash port on this host, exactly as CR-3 states. Every fixture in
this stage sets `sc.CLASH_PORT = 45733` **and** writes `clash_api_port: 45733` into its own
`settings.json`, and the only Clash call any step makes is `clash_api("GET", "/configs")` — which,
against a free port, returns `None` and renders `(unavailable)`.

## The C-5 stub, in full

```python
class StubRefused(AssertionError):
    pass

def stub_subprocess(table, log):
    """TOTAL and CLOSED subprocess stub. `table`: {argv tuple: (rc, stdout, stderr)}."""
    mod = types.ModuleType("subprocess")

    def run(argv, *a, **kw):
        argv = list(argv)
        log.append(argv)
        key = tuple(argv)
        if key not in table:
            raise StubRefused("STUB REFUSED un-enumerated argv: %r" % (argv,))
        rc, out, err = table[key]
        return _Result(argv, rc, out, err)

    def _forbidden(*a, **kw):     # bound to call / check_call / check_output / Popen
        raise StubRefused("STUB REFUSED non-run subprocess entry point: %r" % (a,))
    mod.run = run; mod.call = mod.check_call = mod.check_output = mod.Popen = _forbidden
    return mod
```

Installed as `sc.subprocess = qafix.stub_subprocess(table, log)` — the **loaded module's own
namespace**, per C-5 and F-5. `subprocess.run = …` (mutating the real module) appears nowhere. The
module-load recipe is `docs/dev-map.md`'s verbatim, with `sys.modules["os"]` restored in a
`finally`, all **eight** path constants repointed and each asserted to resolve inside the temp root:

```python
for name in PATH_CONSTS:
    p = Path(getattr(sc, name)).resolve()
    assert str(p).startswith(str(root.resolve()) + os.sep), \
        "path constant %s escaped the temp root: %s" % (name, p)
```

No run in this stage raised `StubRefused`.

## Full run — AC-B1 / AC-B2 (V-1, V-2)

```
$ python3 v_status.py <candidate> base en <root> <sidecar> > base-en.out 2> base-en.err ; echo rc=$?
rc=0
$ cat base-en.out                                  # stderr empty
=== Service status ===
                                                   (blank)
=== TUN interface ===
                                                   (blank)
=== Rule-sets ===
geoip-cn.srs         usable, 0 seconds ago         | zh: 可用, 0 秒前
geosite-cn.srs       usable, 30 days ago           | zh: 可用, 30 天前
geosite-google.srs   missing, last update unknown  | zh: 缺失, 更新时间未知
geosite-private.srs  unreadable, last update unknown | zh: 无法读取, 更新时间未知
$ sidecar:
stub_log                              [['ip','-br','addr','show','sb-tun']]
stub_log_after_extra_is_running_probe [['ip','-br','addr','show','sb-tun']]
is_running False | rules_dir_exists_after True
cfg_dir_listing_after ['config.json','nodes.json','rules','settings.json']
```

HEAD control at the same case ends after `=== TUN interface ===`: there is no rule-set section to
compare against, which is the discriminating fact for AC-B1 … AC-B3.

## Full run — C-4's `True` arm

```
=== Rule-sets ===                                  === Current node ===
geoip-cn.srs         usable, 0 seconds ago         n1
geosite-cn.srs       usable, 30 days ago           === Route mode ===
geosite-google.srs   missing, last update unknown  (unavailable)
geosite-private.srs  unreadable, last update unknown
                                                   === Clash API ===  127.0.0.1:45733
(the four rows print ABOVE the node/route/egress   === Egress IP ===  (error: no live network call)
 block, in one run, exactly as in the False arm)
```

stub log: `[['systemctl','status','--no-pager','-n','5','sing-box'], ['ip','-br','addr','show','sb-tun'], ['systemctl','is-active','--quiet','sing-box']]`.
`(unavailable)` is the free-port GET returning `None`; `(error: no live network call)` is the
`_egress_ip` raiser. No live network call, no live service call.

## Full run — BC-4 (V-5), with the unclamped value computed

```
=== Rule-sets ===
geoip-cn.srs         usable, 0 seconds ago
geosite-cn.srs       usable, 2 hours ago
geosite-google.srs   usable, 2 hours ago
geosite-private.srs  usable, 2 hours ago
future by s: 99999.99984431267
unclamped days value: -2
```

The three 2-hour rows are the reason this is a real test and not a tautology: without
`max(0, ...)`, `int(now - mtime) // 86400` is `-2`, so the row would have read `-2 days ago`.

## Full run — BC-5 (V-4) and BC-3 (V-7)

```
# BC-5, RULES_DIR deleted
=== Rule-sets ===        (all four rows:)  <name>  missing, last update unknown
rules_dir_exists_after False | cfg_dir_listing_after ['config.json','nodes.json','settings.json']

# BC-3, a readable 0-byte file, direct ruleset_state()
candidate: ('too-small', 'e3b0c44298fc…7852b855', 0, 1786698315.918187)   len=4
HEAD:      ('too-small', 'e3b0c44298fc…7852b855', 0)                      len=3
=== Rule-sets ===   geoip-cn.srs         file too small, 0 seconds ago
```

## Full boundary sweep

```
===== _age_text() unit ladder (17 deltas × en/zh; delta = seconds since the mtime) =====
  None -> "last update unknown" / "更新时间未知"
  +0 -> 0 seconds ago | +1 -> 1 seconds ago | +59 -> 59 seconds ago | +60 -> 1 minutes ago
  +61 -> 1 minutes ago | +119 -> 1 minutes ago | +3599 -> 59 minutes ago | +3600 -> 1 hours ago
  +3601 -> 1 hours ago | +86399 -> 23 hours ago | +86400 -> 1 days ago | +86401 -> 1 days ago
  +129600 -> 1 days ago | +2592000 -> 30 days ago | -1 -> 0 seconds ago | -100000 -> 0 seconds ago
  zh identical in shape: 0 秒前 / 59 秒前 / 1 分钟前 / 59 分钟前 / 1 小时前 / 23 小时前 / 1 天前 / 30 天前

===== every `unreadable` / `absent` shape =====
  directory          -> status=unreadable digest=None   size=None  mtime=None   | last update unknown
  dangling symlink   -> status=unreadable digest=None   size=None  mtime=None   | last update unknown
  fifo               -> status=unreadable digest=None   size=None  mtime=None   | last update unknown
  mode 000           -> status=unreadable digest=None   size=None  mtime=None   | last update unknown
  absent             -> status=absent     digest=None   size=None  mtime=None   | last update unknown
  readable 0-byte    -> status=too-small  digest=yes    size=0     mtime=real   | 0 seconds ago
  bad magic          -> status=bad-magic  digest=yes    size=64    mtime=real   | 0 seconds ago
  3 bytes            -> status=too-small  digest=yes    size=3     mtime=real   | 0 seconds ago

===== K-1: exactly one fstat, zero os.stat, inside ruleset_state() =====
  ruleset_state(usable file) -> usable | sc.os calls: {'stat': 0, 'fstat': 1, 'lstat': 0}
```

`129600 s` (36 h) rendering `1 days ago` is RS-5 / RES-6, deliberate per Q-11 and already homed as a
follow-up row; `1 seconds ago` at `+1 s` is the same pluralisation choice at the other end of the
ladder. Recorded so no later reader mistakes either for a new finding. Neither is a T-19 defect.

## Full runs — AC-B5 and AC-B6, candidate and HEAD

Every run below opens with the same four `  ↓ <file> ... OK (N bytes)` per-file lines; only the tail
differs, so only the tail is quoted.

```
### candidate, regenfail                                     EXIT=1
Rule-sets updated: geosite-private — the sing-box service was not touched
-- stderr --  ⚠️  Config check failed: / boom: synthetic check failure
-- stub log -- [['sing-box-stub','check','-c','config.json']]

### HEAD, regenfail                                          EXIT=0
Rule-sets restored: geosite-private — config regenerated
Rule-sets updated: geosite-private — the sing-box service was not touched
Done                                     -- same stderr, same stub log --

### candidate, restartfail                                   EXIT=1
Rule-sets restored: geosite-private — config regenerated
→ Restarting sing-box ...
Rule-sets updated: geosite-private — the sing-box service could not be restarted
-- stub log -- [['sing-box-stub','check',…], ['systemctl','is-active','--quiet','sing-box'],
                ['systemctl','restart','sing-box']]

### HEAD, restartfail                                        EXIT=0
Rule-sets restored: geosite-private — config regenerated
→ Restarting sing-box ...
Rule-sets updated: geosite-private — sing-box restarted to load them
Done                                     -- identical stub log --

### candidate, restartfail, LANG=zh                          EXIT=1
规则集已更新：geosite-private —— sing-box 服务重启未成功
```

P-3 and P-4 are therefore both **confirmed**: at HEAD a failed regeneration and a failed restart each
exit 0, and each prints a claim that is false of the run.

## Full runs — the freezes and the two unwind paths

```
### deadmirror, candidate and HEAD alike                     EXIT=1
  ↓ geoip-cn.srs ... failed: file://<ROOT>/no-such-mirror -> <urlopen error [Errno 2] ...>
  ↓ geosite-cn.srs ... failed: ... -> skipped (this source already failed in this run)      (×3)
No rule-set changed — the sing-box service was not touched
-- stderr -- <blank line> then "4 ruleset(s) failed to update"     -- stub log --  []

### nochange                                                 EXIT=0
No rule-set changed — the sing-box service was not touched / Done   -- stub log --  []

### noconfig (BC-12)                                         EXIT=0
Rule-sets updated: geosite-private — the sing-box service was not touched / Done
-- stub log --  []   (no SB_BIN entry: generate_config() never ran)

### unwind_exit (BC-13, helper sys.exit)                     EXIT=1
stdout ends after the four OK lines -- NO outcome line       -- stub log --  []
-- stderr -- Could not write <ROOT>/etc/sing-box/nodes.json: Permission denied

### unwind_override (BC-13, OverrideError)                   EXIT=1
stdout ends after the four OK lines -- NO outcome line       -- stub log --  []
-- stderr -- Cannot use <ROOT>/etc/sing-box/override.json: not valid JSON (Expecting property name … char 2)
```

Both unwind paths are byte-identical between HEAD and candidate.

**How each unwind path was reached, since `02` names them without a recipe.** Path A: `nodes.json`
is given `"active": "gone"`, so `generate_config()`'s stale-selection repair calls `save_nodes()`;
the fixture's `CFG_DIR` is `chmod 0500` (inside the temp root only, restored afterwards), so
`_write_private` raises `OSError` and `save_nodes()` `sys.exit`s past the tail. Path B: a malformed
`override.json`, so `_load_override()` raises `OverrideError`, which `generate_config()` re-raises.

**One substitution, stated rather than hidden.** Path B's `OverrideError` is caught by `main()` in
production, and `main()` is forbidden here (it reassigns `LANG` and `CLASH_PORT` — the vacuity trap
— and drives `_init_files()`, which hard-codes `/var/lib/sing-box`). The driver therefore replicates
`main()`'s **one** handler verbatim from `bin/sc:3195-3210`:

```python
msg = sc._plain(sc.t("Cannot use {path}: {problem}",
                     path=e.path or sc.CFG_PATH, problem=str(e)).replace("\n", " "))
sys.exit(msg)
```

Path A needs no substitution at all: `save_nodes()`'s `sys.exit` reaches the interpreter directly.

## The six-state enumeration, reproduced independently (T6.3)

`05_RATIONALE.md` enumerated the tail as a state machine and asserted each branch's claim is true.
I did not take that on the page; each state was **run**:

| state | reached by | outcome line | exit | matches `05_RATIONALE.md`? |
|---|---|---|---|---|
| nothing changed | `nochange`, `deadmirror` | (a) `No rule-set changed — …` | 0 / 1 | yes |
| no config (fresh install) | `noconfig` | (d) `… — the sing-box service was not touched` | 0 | yes |
| regeneration / check failed | `regenfail` | (d), **no** regeneration claim | 1 | yes |
| service not running | `sc status` False arm + `restarted is None` in `noconfig` | (d) | 0 | yes |
| restart returned 0 | `restartok` | (b) `… — sing-box restarted to load them` | 0 | yes |
| restart returned non-zero | `restartfail` | (c) `… — could not be restarted` | 1 | yes |

Six states, six runs, one outcome line each, every claim true of its run. `Done` appears on exactly
the three zero-exit runs. The enumeration is correct as written.

## AC-B8 — the counting script and its result

Outcome lines were counted against I-6's closed set (en and zh forms), excluding per-file `  ↓`
lines and never counting `Done` / `完成`:

```
run                      exactly-1  #out  Done  regen claim  outcome line
deadmirror-en            True       1     0     False   No rule-set changed — …
nochange-en              True       1     1     False   No rule-set changed — …
nochange-zh              True       1     1     False   规则集内容无变化 —— 未改动 sing-box 服务
noconfig-en              True       1     1     False   … the sing-box service was not touched
regenfail-en             True       1     0     False   … the sing-box service was not touched
regenfail-zh             True       1     0     False   规则集已更新：geosite-private —— 未改动 sing-box 服务
restartfail-en           True       1     0     True    … could not be restarted
restartfail-zh           True       1     0     True    规则集已更新：… —— sing-box 服务重启未成功
restartok-en             True       1     1     True    … sing-box restarted to load them
unwind_exit-en           False      0     0     False   -
unwind_override-en       False      0     0     False   -
--- the 8 HEAD controls, same shape: exactly 1 outcome line on the 6 tail-reaching runs,
    0 on the 2 unwind runs; Done on 5 of 6; regen claim TRUE on H-regenfail-en ---
```

The `regen claim` column is the one that discriminates: `H-regenfail-en` prints
`config regenerated` on a run whose `sing-box check` returned 1. `regenfail-en` does not.

## C-2 — method, and why a cold-cache condition was added

The warm-cache measurement alone would have been a soft green: 477 KB of `.srs` sitting in the page
cache after the copy. `posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED)` after an `fsync` evicts the
clean pages **without root**, so the cold condition is measurable inside this pipeline's safety
floor. Both conditions alternate HEAD and candidate at the same root, one run per child process,
timing only the `cmd_status()` call (module load excluded), with `SYSTEMD = OPENRC = False` so
neither build enters the node/route/egress block.

```
HEAD ms      : [0.013, 0.013, 0.012, 0.012, 0.012] median 0.012   |  added median ms: 0.448
candidate ms : [0.461, 0.463, 0.47, 0.448, 0.455]  median 0.461
COLD HEAD ms      : [0.012, 0.013, 0.013, 0.013, 0.012] median 0.013  |  COLD added: 1.516
COLD candidate ms : [1.673, 1.659, 1.061, 1.459, 1.528] median 1.528
srs bytes: {geoip-cn 21944, geosite-cn 447370, geosite-google 7912, geosite-private 696} = 477922
```

Two orders of magnitude of headroom against C-2's 250 ms. The measurement also settles RS-4
empirically: the cost is the reads, not the timestamp — O-30 shows the timestamp adds exactly one
`fstat` on an already-open handle and no `os.stat` at all.

## C-8 — the full comparison and the mutant

All three runs at the **same** fixture root, so no path normalisation was applied:

```
HEAD exit=1 ; CAND exit=1 ; MUT exit=1        (all three captures 1121 bytes)
=== cmp HEAD vs candidate ===  BYTE-IDENTICAL
5d5aba6a42682988d8de6d3d863dfff5b14809d00fa6bae364e83212789b380a  cand.merged
5d5aba6a42682988d8de6d3d863dfff5b14809d00fa6bae364e83212789b380a  head.merged
ed921ed2e86176b808f2deac10f3bbc6f1e7f8f85fe8ea277c87f96adad6eea0  mut.merged
=== cmp HEAD vs mutant ===  head.merged mut.merged differ: byte 836, line 4
=== diff HEAD vs mutant ===
4,6c4
<   ↓ geosite-private.srs ... failed: file://<ROOT>/no-such-mirror -> skipped (this source already failed in this run)
< No rule-set changed — the sing-box service was not touched
<
---
>   ↓ geosite-private.srs ...
7a6,7
> failed: file://<ROOT>/no-such-mirror -> skipped (this source already failed in this run)
> No rule-set changed — the sing-box service was not touched
```

The mutant is the candidate with exactly one line removed — `bin/sc:2869`'s
`sys.stdout.flush()`. Its capture reproduces stage 4's "before the fix" transcript line for line:
the fourth per-file line is split in two by the aggregate, and the aggregate moves from last to
fourth. Two conclusions: D-1 is load-bearing rather than defensive, and the byte-identity in the
contract portion is a real measurement rather than a harness that cannot fail.

## Regression sweep — the commands no AC observes

The widening touches `_doctor_rulesets()` (E-7) and `restart_service()`'s return type (E-9), and no
acceptance criterion observes either through its own command. Three commands were run at HEAD and
at the candidate in the same fixture shape and diffed:

```
######## doctor : stdout IDENTICAL / stderr IDENTICAL / exit 1 both
    log= [['sing-box-stub','version'], ['sing-box-stub','check','-c','config.json'], ['ip',…]] both
######## ls     : IDENTICAL / IDENTICAL / exit 0 both / empty log
######## reload : IDENTICAL / IDENTICAL / exit 0 both      (restart stub returns 1)
    log= [['sing-box-stub','check','-c','config.json'], ['systemctl','restart','sing-box']] both
--- doctor's rule-set rows carry NO age (K-17 / out-of-scope 10) ---
[PROBLEM] rule-sets: 3/4 usable | [OK] geoip-cn.srs: usable, 64 bytes
[PROBLEM] geosite-private.srs: missing, size unavailable
```

`sc reload` is the K-8 / out-of-scope-5 observation: with `systemctl restart` returning **1**, both
builds print the same thing and both exit **0**, i.e. `reload_or_restart()` still discards
`restart_service()`'s new return.

(The `[UNKNOWN] TUN interface: 'str' object has no attribute 'decode'` row in both doctor captures
is a fixture artifact — my stub returns `str` where `_doctor_run` decodes bytes. It is identical at
both builds, so it cannot mask a regression; it is not a `bin/sc` defect.)

## R-22 — the behavioural goal, run end to end

The one observation the whole task exists for. Four rule-sets aged 30 days; a `file://` mirror that
serves **only** `geoip/cn.srs`, so one file really is refreshed and three really are not:

```
  ↓ geoip-cn.srs ... OK (200 bytes)
  ↓ geosite-cn.srs ... failed: file://<ROOT>/mirror -> <urlopen error [Errno 2] ...>   (+2 skipped)
Rule-sets updated: geoip-cn — the sing-box service was not touched
-- stderr --  3 ruleset(s) failed to update      -- run exit status 1
----- sc status after the partly-failed update -----
=== Rule-sets ===
geoip-cn.srs         usable, 0 seconds ago
geosite-cn.srs       usable, 30 days ago      (and geosite-google.srs, geosite-private.srs alike)
before_age_days {geoip-cn: 30.0, geosite-cn: 30.0, geosite-google: 30.0, geosite-private: 30.0}
after_age_days  {geoip-cn: 0.0,  geosite-cn: 30.0, geosite-google: 30.0, geosite-private: 30.0}
mtime_changed   {geoip-cn: True, geosite-cn: False, geosite-google: False, geosite-private: False}
```

All four still read `usable`, which is precisely the "looks healthy" symptom the goal names — and
the age column is now the thing that says otherwise. At HEAD the same run prints no rule-set
section at all. This also settles **P-5** in one run.

## Out-of-scope item 6, tested rather than assumed

The one way this task could have quietly re-opened
`.harness/rejected-decisions.md § mtime-or-size-as-a-ruleset-change-signal` is if the new `mtime`
had leaked into `changed_usable_tags()`. Four byte-identical files re-fetched:

```
mtime really changed for every file: True
age before/after (days): geoip-cn (30.0, 0.0), geosite-cn (30.0, 0.0),
                         geosite-google (30.0, 0.0), geosite-private (30.0, 0.0)
changed_usable_tags(before, after) = []
stub log (service actions): []
```

Every timestamp moved 30 days; the change set stayed empty; nothing was restarted.

## AC-S1 — the full sweep

```
$ grep -n "st_mtime\|st_ctime\|st_atime\|getmtime\|getctime\|os\.stat\|\.stat()\|fstat\|time\.time()\|st_size" bin/sc
816:  mtime = os.fstat(fh.fileno()).st_mtime   # same handle, inside the same try  <-- THE query
936:  delta = max(0, int(time.time() - mtime))                             <-- the only clock read
1388: st = os.stat(str(OVERRIDE_PATH))   <-- A-2's known non-timestamp hit: S_ISREG(st_mode)
776 / 785 / 792 / 1139 / 1372 / 1375 / 1390 / 1410: docstring or comment prose, no query
$ grep -n "_age_text" bin/sc
925:def _age_text(mtime):
2272:        print("%-20s %s, %s" % (fname, _status_text(status), _age_text(mtime)))
```

One `st_mtime` read, in code, inside `ruleset_state()`'s existing `with` and `try`. One renderer,
one call site, signature `(mtime)` — no `sc status`-specific argument, so T-20 consumes it
unchanged. `st_size` appears in prose only. The assertion was **not** widened to "exactly one
`os.stat` in the file"; `:1388` is reported as the known non-timestamp hit A-2 predicted.

## AC-S2 — the key table and the byte scans

```
key                                                            ph(en)    ph(zh)    equal
=== Rule-sets ===                                              []        []        True
{n} seconds ago                                                ['n']     ['n']     True
{n} minutes ago                                                ['n']     ['n']     True
{n} hours ago                                                  ['n']     ['n']     True
{n} days ago                                                   ['n']     ['n']     True
last update unknown                                            []        []        True
Rule-sets updated: {names} — the sing-box service could not…   ['names'] ['names'] True
no 'en' table: True
$ git diff -U0 bin/sc | grep '^+' | grep -c '失败'
0
=== AC-S2/BC-7: 192 captured streams scanned; streams containing CR: 0 []
=== AC-B2: checked every unavailable row: no digit anywhere after the filename column  OK
=== FR-3: candidate captures with !=1 rule-set section, HEAD captures with !=0: none
```

`check-i18n-parity.sh` (verify_all B.2) covers `install.sh` only and cannot see these keys, so the
table read above is the proof, exactly as V-16 anticipated.

## P-1, measured

```
$ python3 -c 'import sys; sys.exit("boom")' >p1.out 2>p1.err ; echo status=$?
status=1
stdout: []            stderr: [boom]        stderr bytes: 5
```

`sys.exit(<str>)` writes the string plus one newline to stderr and exits 1. Confirmed. This is the
premise K-13's replacement had to preserve, and C-8 is the observation that it did.

## Stability, in full

```
=== 10× AC-B1 (cmd_status) ===
895d3bee3966 ×10        distinct rule-set sections: 1
=== 10× AC-B6 (restart failure) ===
exit statuses: 1 1 1 1 1 1 1 1 1 1        distinct stdout: 1
=== 10× C-8 merged byte-identity ===
byte-identical in 10/10 runs
```

## What I checked and found nothing wrong with

Recorded so a later reader knows these were examined rather than skipped.

- **`docs/dev-map.md`'s diff, read line by line** against out-of-scope item 11: `+3 / −2`, which can
  only be two modified rows plus one added row inside `## Reusable utilities`. CR-2's correction is
  present in the shipped text.
- **CR-1** (stale `bin/sc` citations) is discharged in the shipped `04_DEVELOPMENT.md`: `:99` cites
  `bin/sc:2869`, the insight rows cite `:2869` and `:2277`, `04_RATIONALE.md:57` cites `:2791`.
- **RS-3 / Q-9** was **not** re-raised as a defect; `install.sh` is unmodified and out of scope.
- **R-33** was not observable here: every `subprocess.run` is stubbed, so no child writes fd 1 — no
  evidence either way; out of scope per Q-12.
- **The `Done` ⟺ exit-0 invariant** (A-4) holds in all 19 update captures at both builds.
- **`baseline.json`** was not touched: `test_count` is 0, `verify_all` reports no test count, and
  the file is in `02`'s frozen set. Nothing was lowered.
- **`.harness/operator-obligations.md`** was deliberately not created — `.harness/**` is outside
  this task's permitted diff, and this project's precedent (R-30, R-31) routes an operator
  obligation to `docs/tasks.md` through the PM. Recorded as a follow-up row instead.
