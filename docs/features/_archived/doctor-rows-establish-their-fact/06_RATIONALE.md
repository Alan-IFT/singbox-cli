> Rationale portion for 06_TEST_REPORT.md. Non-binding.

Everything here is a transcript, a fixture note, a measurement narrative or a rejected reading.
Nothing in it overrides the contract portion. It exists because `.harness/rules/70-doc-size.md`
still defines no `## Stage-doc boundary rule` (R-37, nineteenth confirmation) and the tester
contract's section schema has no shape that holds a byte-form transcript. T-27 owns the fix.

## Rationale siblings opened, and why

- **`04_RATIONALE.md`, under T6.2.** Stage 4 claims four byte-identity digests, the `telemetry:
  block` default, the telemetry rule's index 2 and a numstat. Every one of those is re-taken here on
  my own fixtures; none is inherited. Two of them (the default, the index) I now confirm; the
  digests I confirm as *relative* identity after normalising the fixture root, which is the only
  form in which two clones writing to two `mkdtemp()` roots can be compared at all (stage 4 quoted
  absolute digests, which are fixture-dependent and therefore not reproducible across roots — that
  is a property of the measurement, not an error in it).
- **`05_RATIONALE.md`, under T6.3.** RES-1…RES-8 are stated compactly in `05`'s contract portion and
  their reasoning (the tool limit, the surrogate discharges, the four rejected readings) is in the
  rationale. Two of those rejected readings bear directly on my work: BC-A's PROBLEM-vs-UNKNOWN
  shape, and NFR-2 on init-less hosts. I adopt both rulings and *measure* what they argued.
- **`01_RATIONALE.md` / `02_RATIONALE.md` not opened.** T6.1 did not fire: every criterion's
  verification step named a fixture shape and an observable I could build without further reading.

## The fixture harness

One file, `drive.py`, in the session scratchpad at
`…/scratchpad/t26qa/drive.py`, with `runall.sh` running one case on both sides. Runs live in
`…/scratchpad/t26qa/runs/<case>.<lang>.<side>.{out,err,json}` and stability repeats in
`…/scratchpad/t26qa/stab/`. Stage artifacts, never the worktree (T-28 owns the committed suite).

**The load, verbatim — the mandated recipe, not a hand-written loader (R-78, K-10):**

```python
def boot(repo):
    assert os.geteuid() != 0                       # refuse to run as root, loudly
    sc = types.ModuleType("sc")
    shim = types.ModuleType("os"); shim.__dict__.update(os.__dict__)
    shim.geteuid = lambda: 0                       # the elevate branch is simply not taken
    sys.modules["os"] = shim
    try:
        src_path = os.path.join(repo, "bin", "sc")
        with open(src_path, encoding="utf-8") as fh:      # R-77, added at use time
            src = fh.read()
        exec(compile(src, src_path, "exec"), sc.__dict__)
    finally:
        sys.modules["os"] = os                     # restore IMMEDIATELY, in a finally
    return sc
```

**The eight constants, with the assertion that is the actual safety net:**

```python
sc.CFG_DIR, sc.CFG_PATH, sc.NODES_PATH, sc.SETTINGS_PATH = cfg, cfg/"config.json", …
sc.RULES_DIR, sc.OVERRIDE_PATH, sc.STATE_PATH, sc.IF_INET6_PATH = …
for p in eight:
    assert str(Path(p).resolve()).startswith(str(root.resolve()) + os.sep), p
```

`sc.SB_BIN` is a stub script inside the root (a repointable constant, no `PATH` games).
`TUN_IFACE` is **not** repointable after import, so the TUN row runs a real read-only
`ip -br addr show sb-tun` — identical on both sides and not under test.

**Why `subprocess` is replaced as a module rather than patched.** `sc.subprocess` is the real module
object shared with the harness, so patching `subprocess.run` in place would patch my own process.
The fixture builds a copy (`types.ModuleType` + `__dict__.update`) whose `run` intercepts only
`systemctl` / `rc-service` / `rc-update` argv and delegates everything else to the real
`subprocess.run` — so `_doctor_binary`, `_doctor_tun` and `sing-box check` stay real while liveness
is controlled. `is_running()` itself is never stubbed: stubbing the function under test is how this
matrix goes vacuous.

**The three trap-avoidances, each measured on this project before it bit me:**

1. `main()` reassigns `LANG` after import, so `lang` is written into the fixture's own
   `settings.json`. Evidence that it took: the zh rows carry `[异常]` / `[正常]` and Chinese text.
2. `main()` reassigns `CLASH_PORT` — but not on the `doctor` arm — so the Clash port is written into
   the fixture's own `settings.json` and read back by `_saved_clash_port()`. The fixture is void
   unless the HEAD half also reaches the stub: **every** HEAD half of every Clash case logs
   `GET /configs`. For the `sc ls` cases I additionally set `sc.CLASH_PORT` to the stub port, so a
   deleted guard *would* have produced a logged request — the observation is real, not an artifact
   of a wrong port.
3. `sc.SYSTEMD = True` is always paired with a stubbed `subprocess.run`; no case sets one without
   the other.

**One case per process.** Every case is its own `python3 drive.py …` invocation. The developer's
insight (`main()` cannot be called twice in one process — the `io.TextIOWrapper` re-wrap closes the
previous run's `BufferedWriter` and every later `print()` raises into a discarded stderr) is taken as
binding; the harness never gets close to it. Side-channel data goes to a JSON file, not to stdout, so
sc's own output is captured byte-for-byte from a real file-backed stdout (which is also what keeps
`main()`'s `getattr(sys.stdout, "buffer", None)` branch on its real path — an `io.StringIO` harness
would have silently skipped the wrap).

**Snapshot.** `(size, mtime_ns, oct(mode), sha256)` per path under the whole fixture root, taken
immediately before and immediately after the run, with an unreadable file recorded as
`unreadable:PermissionError` rather than crashing the snapshot (the `aaaa-unreadable` fixture).

## Transcripts

### AC-1 / AC-2 / BC-F — the AAAA row (fixture `aaaa-index3`, `dns.rules = [Global, Direct, hosts_dns, aaaa]`)

```
CANDIDATE: [PROBLEM] IPv6 (AAAA): AAAA queries are answered empty (setting: off); config.json does not
carry this decision as the first dns.rules entry — run `sc reload` to regenerate it, and check
/tmp/t26-bsrti_2m/etc/sing-box/override.json if it prepends a rule of its own      EXIT = 1
HEAD:      [OK] IPv6 (AAAA): AAAA queries are answered empty (setting: off); config.json carries this
decision                                                                          EXIT = 1
```

zh (same fixture, `lang: zh` in the fixture's own `settings.json`):

```
CANDIDATE: [异常] IPv6（AAAA）: AAAA 查询直接返回空结果（设置：off）；config.json 的 dns.rules 第一条不是
该决策对应的规则 —— 运行 `sc reload` 重新生成；若 /tmp/t26-tak1nxr4/etc/sing-box/override.json 自己往前
插了规则，请检查它
HEAD:      [正常] IPv6（AAAA）: AAAA 查询直接返回空结果（设置：off）；config.json 与该决策一致
```

The index-1 variant matters more than index 3: `{"clash_mode": "Global"}` at index 0 matches every
query in `global` mode, so an AAAA rule at index 1 is dead in exactly the mode a user switches to
when something is already broken — and HEAD calls it `[OK]`.

### AC-3 — the divergence attempt (`aaaa-emit-append`)

The tamper is on the **emitter only**, at fixture level, never in `bin/sc`:

```python
sc._dns_overlay = lambda s: {"dns": {"rules": {"$append": [sc._aaaa_rule(s)]}}}   # candidate
sc._dns_overlay = lambda:  {"dns": {"rules": {"$append": [sc._aaaa_rule(sc.ipv6_decision()[1])]}}}  # HEAD
```

Then `generate_config()`, then `sc doctor`:

```
both builds: the emitted document now carries _aaaa_rule(suppress) at index 8 of 9
CANDIDATE:   [UNKNOWN] IPv6 (AAAA): this check could not run: '$prepend'
HEAD:        [OK] IPv6 (AAAA): … config.json carries this decision
```

This is I-3's claimed failure mode observed rather than asserted: the candidate's probe cannot be
separated from the emitter's position without raising, and the raise costs exactly one row (single-row
section, PQ-3) — the other 20 rows printed normally. HEAD's probe has no opinion about position at
all, so the emitter moved the rule to a dead index and the row still read `[OK]`.

The structural half, by AST over both builds:

```
CAND  _aaaa_rule()  callers: ['_dns_overlay:1773']                  (one)
HEAD  _aaaa_rule()  callers: ['_dns_overlay:1774', '_doctor_ipv6:2717']   (two)
CAND  _dns_overlay() callers: ['generate_config:2092', '_doctor_ipv6:2718']
HEAD  _dns_overlay() callers: ['generate_config:2092']
```

HEAD spelled the rule at two sites and the position at none; the candidate spells each once.

### AC-5 / BC-A / BC-B — the node-delay matrix

```
nd-initless-delays  (SYSTEMD=OPENRC=False, /proxies holds 111 ms and 222 ms)
  CANDIDATE [OK] node delays: 2/2 nodes carry a stored delay (history, not a fresh measurement);
                 auto-select is on n1
            log ['GET /configs', 'GET /proxies', 'GET /dns/query?name=api.ipify.org&type=A']
  HEAD      [PROBLEM] node delays: 0/2 nodes carry a stored delay — either no probe has completed
                 yet or every node is failing; see `sc ls`
            log ['GET /configs', 'GET /dns/query?name=api.ipify.org&type=A']

bca-configs-only  (BC-A: /configs 200, /proxies 503)
  CANDIDATE [PROBLEM] node delays: a stored delay was read for 0/2 nodes — either no probe has
                 completed yet, every node is failing, or the list could not be read; see `sc ls`
            log ['GET /configs', 'GET /proxies', 'GET /dns/query?…']
  HEAD      [PROBLEM] node delays: 0/2 nodes carry a stored delay — either no probe has completed
                 yet or every node is failing; see `sc ls`
            log ['GET /configs', 'GET /dns/query?…']

bcb-stopped-api-answering  (BC-B: SYSTEMD=True, is-active → rc 3, both routes answering)
  CANDIDATE [OK] node delays: 2/2 …            log [… 'GET /proxies' …]
  HEAD      [PROBLEM] node delays: 0/2 …       log [no /proxies]

nd-running-nohistory  (AC-6 control: SYSTEMD=True, is-active → rc 0, history: [])
  CANDIDATE [PROBLEM] node delays: a stored delay was read for 0/2 nodes — … see `sc ls`
  HEAD      [PROBLEM] node delays: 0/2 nodes carry a stored delay — … see `sc ls`
  (class, numerals and `sc ls` identical; both request /proxies)

nd-stopped-noapi  (AC-7 / V-7 coherent fixture)
  both      [PROBLEM] Clash API responding: no usable answer from 127.0.0.1:<port>
            [UNKNOWN] node delays: not probed — the Clash API did not answer      log []
```

### AC-7 / FR-7 — `sc ls`, the guarantee BC-11 was written for

`cmd_ls()` called directly (no `main()`, so no initialising arm), stub **answering**, `sc.CLASH_PORT`
= the stub port, `SYSTEMD=True` with `is-active` → `3`:

```
   #  On  Type        Name                            Address                        Delay
          urltest     auto                            -                                  -
   1  ●   vless       n1                              203.0.113.10:443                   -
   2      vless       n2                              203.0.113.11:443                   -
request log: []        (identical on candidate and HEAD; the two tables are byte-identical)
```

With `is-active` → `0` the same fixture gives `111 ms` / `222 ms` / `→ n1` and `log ['GET /proxies']`
on both builds. So the guard is intact for the caller that names no port, and only that caller.

### AC-9 / AC-10 — the DNS row

```
dns-answer     CAND [OK] DNS lookup: the running sing-box answered for api.ipify.org in 0 ms,
                          possibly from its own DNS cache
               HEAD [OK] DNS lookup: api.ipify.org resolved in 0 ms, through the running sing-box
dns-empty      CAND [PROBLEM] DNS lookup: api.ipify.org returned no records after 0 ms — try another
                          node with `sc use <n>`; an answer already cached by the running sing-box
                          survives a node change
               HEAD [PROBLEM] DNS lookup: api.ipify.org returned no records after 0 ms — try another
                          node with `sc use <n>`
dns-noanswer   CAND [PROBLEM] DNS lookup: no answer for api.ipify.org after 0 ms — try another node
                          with `sc use <n>`; an answer already cached by the running sing-box
                          survives a node change
               HEAD [PROBLEM] DNS lookup: no answer for api.ipify.org after 0 ms — …
zh (candidate) [异常] DNS 解析: 0 毫秒内没有收到 api.ipify.org 的解析结果 —— 可用 `sc use <编号>` 换一个
                          节点试试；正在运行的 sing-box 已缓存的应答不会因为换节点而失效
```

`grep 失败：` over every zh output of every case: **0 matches** (K-9 / R-75).

### AC-12 — `sc ipv6` no-op

```
ipv6-noop en  CAND  IPv6 name resolution → auto
                    AAAA queries are resolved normally (setting: auto — this host has a global IPv6
                    address on eth0)
                    Nothing changed — the sing-box service was not touched; run `sc reload` to apply
                    this setting to a configuration generated before it
              HEAD  … Nothing changed — the sing-box service was not touched
ipv6-noop zh  CAND  设置无变化 —— 未改动 sing-box 服务；若当前配置生成于该设置之前，请运行 `sc reload` 使其生效
              HEAD  设置无变化 —— 未改动 sing-box 服务
```

Regression on the key the swap borrows: `sc telemetry block` (already `block`) prints the identical
sentence on candidate and HEAD, in both languages — the deleted key was the orphan, not the shared
one. `sc ipv6 show` is byte-identical on both builds in both languages (no escape line leaked into
the `show` path).

### AC-14 — healthy host, row by row

`healthy-clean` (config generated by the build under test, drift recorded, modes tightened, stub
`sing-box version` line, init reporting running and enabled): **21 rows, every one `[OK]`, exit 0**
on both builds. Diff of the two reports after normalising the fixture root: two cells — the
fixture's own random port, and the DNS sentence. Row count, labels, order and exit identical.

### RES-3 — what the `main()`-driven non-doctor fixtures actually reach

```
ipv6-noop / ipv6-flip / telemetry-noop / ipv6-show, 8 runs (2 cases × 2 langs × 2 sides + 4)
  settings_after: {… 'ipv6': 'auto', 'clash_api_port': 29091}   ← only _resolve_clash_port() writes this,
                                                                  i.e. main()'s INITIALISING arm ran
  var_lib_before: [True, 1785387564302353878, ['cache.db']]
  var_lib_after:  [True, 1785387564302353878, ['cache.db']]     ← mtime_ns and entry list unchanged, 8/8
```

So stage 5's CR-2 is right and stage 4's remediation sentence was wrong: `ipv6` takes the
initialising arm exactly as `ls` did, `_init_files()` is driven, and `Path("/var/lib/sing-box")
.mkdir(parents=True, exist_ok=True)` runs against the real directory. The host effect is nil for the
reason both stages gave — the directory already exists and `exist_ok=True` neither writes nor stats
into it — and I re-measured that rather than inheriting it. `sc doctor` reaches neither writer: the
`aaaa-freshhost` case deletes the configuration directory entirely and the run leaves it absent.

### The `verify_all` run

```
$ bash .harness/scripts/verify_all.sh          # cwd = /home/alan/Programs/singbox-cli
=== verify_all (generic) ===
[A.1] No hardcoded secrets ... PASS      [E.6] Adversarial tests section in completed task reports ... PASS
[B.3] Lint ... SKIP                      [F.6] Active task docs <=500 lines each ... PASS
=== Summary ===   PASS: 17   WARN: 0   FAIL: 0   SKIP: 1
```

## DEF-1 — the measurement, in full

The claim under test (`CHANGELOG.md:26`): a host with no init system and an answering Clash API
moves the node-delay row `[异常]` → `[正常]` and the **exit code `1` → `0`**.

The mechanism that makes it unreachable is two lines apart in the shipped file:

```
bin/sc:2476   DOCTOR_OK, DOCTOR_UNKNOWN, DOCTOR_PROBLEM = 0, 1, 2   # ordered: OK < UNKNOWN < PROBLEM
bin/sc:2480   DOCTOR_EXIT = {DOCTOR_OK: 0, DOCTOR_UNKNOWN: 2, DOCTOR_PROBLEM: 1}
bin/sc:2739   if not SYSTEMD and not OPENRC:
bin/sc:2740       cause = t("no init system detected (neither systemd nor OpenRC)")
bin/sc:2741-2742  return [(DOCTOR_UNKNOWN, "service", cause), (DOCTOR_UNKNOWN, "boot autostart", cause)]
bin/sc:3027   worst = max(worst, cls)
```

*(Span corrected on re-verification. My first-pass citation said `bin/sc:2741` for the guard and
`:2741-2744` for the rows; the guard is `:2739` and the rows are `:2741-2742` — `:2743-2744` are
`init = "systemd" if SYSTEMD else "OpenRC"` / `running = is_running()`, the has-init branch. Three
documents now cite this span, so it is established here by reading the file, not by agreement:
`04_DEVELOPMENT.md`'s `:2740-2742` spans cause + rows, `02_SOLUTION_DESIGN.md`'s `:2739-2742` spans
guard + cause + rows, and each is true of what it claims.)*

`worst = max(...)`, so two `[UNKNOWN]` rows put the run at `UNKNOWN` unless something is worse. An
init-less host therefore exits `2` whenever nothing is `[PROBLEM]` — it cannot exit `0` on this
build or on HEAD. Measured on the otherwise wholly healthy init-less fixture:

```
HEAD       [PROBLEM] node delays: 0/2 nodes carry a stored delay — …          EXIT = 1
CANDIDATE  [OK] node delays: 2/2 nodes carry a stored delay …                 EXIT = 2
           (both: [UNKNOWN] service / [UNKNOWN] boot autostart, everything else [OK])
```

And the other half of the same published sentence, measured on `healthy-clean-override` (a wholly
healthy host whose `override.json` `$prepend`s one rule, pushing the AAAA rule to index 1):

```
HEAD       EXIT = 0   (all rows OK)
CANDIDATE  EXIT = 1   ([PROBLEM] IPv6 (AAAA) …)     ← the published `0` → `1` is true
```

### The re-verification, after the repair (full runs)

`bin/sc` was **not** touched by the repair, and I proved that before re-measuring anything rather
than accepting it: `md5sum bin/sc` = `10536f7ff4912c6dd7de97930dad582b`, identical to the digest
recorded for the candidate on the first pass; `md5(head-clone/bin/sc)` = `6631231690cffcdc…` at
`6d16cafc90a3fa7ca2289e9f546bffc83f87e028`; `git diff --numstat` → `55  45  bin/sc`. So the repair
could only have made a *sentence* false, which is what I went to measure.

```
$ ./runall.sh healthy-clean-initless en ; ./runall.sh healthy-clean-override en
healthy-clean-initless.en.head  exit = 1     healthy-clean-initless.en.cand  exit = 2
healthy-clean-override.en.head  exit = 0     healthy-clean-override.en.cand  exit = 1
```

The published pair is `1` → `2` and `0` → `1`. Both halves match, on my own fixtures.

Full row census of the init-less candidate run (21 rows, `[PROBLEM]` count = 0):

```
11 [OK] IPv6 (AAAA): AAAA queries are answered empty (setting: off); config.json carries this decision
12 [UNKNOWN] service: no init system detected (neither systemd nor OpenRC)
13 [UNKNOWN] boot autostart: no init system detected (neither systemd nor OpenRC)
18 [OK] node delays: 2/2 nodes carry a stored delay (history, not a fresh measurement); auto-select is on n1
19 [OK] DNS lookup: the running sing-box answered for api.ipify.org in 0 ms, possibly from its own DNS cache
```

and of the HEAD side of the same fixture, which is what makes the aside's 「新旧版本都一样」 a
measurement rather than a claim:

```
12 [UNKNOWN] service: no init system detected (neither systemd nor OpenRC)
13 [UNKNOWN] boot autostart: no init system detected (neither systemd nor OpenRC)
18 [PROBLEM] node delays: 0/2 nodes carry a stored delay — either no probe has completed yet or every node is failing; see `sc ls`
```

So the two UNKNOWNs pre-exist the task on that host class; the node-delay `[PROBLEM]` was masking
them **in the exit status only** (both builds print them as rows), and removing it lets `worst` land
on `UNKNOWN`. That is precisely what the repaired entry now says.

Six further runs, taken to show the rest of the entry did not drift while that clause was edited
(all reproduce the first pass byte-for-byte in the parts under test):

```
aaaa-index3.en.head  [OK] IPv6 (AAAA): … config.json carries this decision
aaaa-index3.en.cand  [PROBLEM] IPv6 (AAAA): … does not carry this decision as the first dns.rules entry — run `sc reload` …, and check …/override.json if it prepends a rule of its own
nd-initless-delays   head log ['GET /configs','GET /dns/query…']  → printed 0/2   |  cand log ['GET /configs','GET /proxies','GET /dns/query…'] → 2/2
dns-answer.en.head   [OK] DNS lookup: api.ipify.org resolved in 0 ms, through the running sing-box
dns-answer.en.cand   [OK] DNS lookup: the running sing-box answered for api.ipify.org in 0 ms, possibly from its own DNS cache
healthy-clean.en/zh  cand exit = 0, snapshot_identical = true
```

(Method note for anyone repeating this: `grep -h` over several run files did **not** print them in
argument order here, which briefly looked like a side swap. Every side attribution above is taken
per-file with `grep -H` and cross-checked against the run's own recorded `repo` field.)

`verify_all` after the repair, same invocation as before: `PASS: 17  WARN: 0  FAIL: 0  SKIP: 1`.

### The lead clause I chose not to raise

`CHANGELOG.md:26` still opens the passage with 「退出码的影响只有一个方向」. The developer left it
deliberately and recorded why. I ruled it accepted, and the reasoning is worth keeping because it is
not simply deference: the clause has two available readings of 方向, and the repair moved it from
false-under-both to true-under-one. Before, the published pair was `1` → `0` and `0` → `1` — down
then up numerically, and better then worse in severity. After, it is `1` → `2` and `0` → `1`: **both
upward numerically**, so "only one direction" is literally true of the exit-code values, i.e. no
affected host's exit code goes down. Under the severity reading (`PROBLEM` is worse than `UNKNOWN`,
so `1` → `2` is an improvement while `0` → `1` is a regression) 方向 remains a loose summary — but
every concrete transition beneath it is now measured true, and a loose summary over true facts
misdirects no reader and fails no acceptance criterion. Filing it would have been filing a wording
preference as a defect. It is recorded as a pool candidate instead: state the fact, not the
direction — 「没有哪台机器的退出码会变小」.

Why the first pass was worth a round rather than a note: FR-13 and AC-15 make published-sentence truth a
contract requirement **of this task**, and the task's own thesis is that a sentence may not claim
what its subject did not establish. Shipping a changelog that misstates the observable consequence
of the fix, inside the commit that fixes three rows for exactly that reason, is self-refuting. The
repair is one clause (`1` → `2` for that host class, or drop the exit-code half of the clause);
`README*.md:279/280` need nothing, and no code is involved.

## Rejected readings

**"BC-A's candidate row should be `[UNKNOWN]`, so the shipped `[PROBLEM]` is a defect."** Rejected,
following stage 5's ruling R-a and BC-A's own text, which ratifies the PROBLEM-with-three-causes
shape by name and was written before the code. My job under BC-A was to observe whether the two
renderings differ and whether the candidate's names the read; both hold. Re-litigating the shape at
stage 6 would overturn a discharged gate condition on the requirement's letter.

**"The candidate's extra `GET /proxies` violates NFR-2, so this is a defect."** Rejected — and now
measured rather than argued (RES-4). The request appears only where HEAD short-circuited it, only
after `/configs` answered, at no new endpoint, no new constant and ≤1 `GET` per `stored_delays()`
call. A reading of NFR-2 that forbids it forbids FR-6, which the same document mandates and OQ-3
rules non-negotiable.

**"`nd-foreign-tags` shows the row lying: it says 'a stored delay was read for 0/2' when two delays
were read."** Rejected on the sentence's own words: the row's subject is *your nodes*, and the count
is `len(tags & set(delays))`. Two delays were read for tags this host does not configure, so zero
were read **for 0/2 nodes** of its own. The three named causes do not include "the list held only
foreign tags", which is a fourth cause — but the sentence states the read and does not claim the
enumeration is exhaustive ("either … or …" over the common cases, with `sc ls` as the next step). No
finding; noted because I went looking for one.

**"`aaaa-emit-empty` is a defect in the coupling."** Rejected as a finding, recorded as a pool
candidate. With an emptied `$prepend` payload the candidate reads `[OK]` on a document carrying no
AAAA rule, because `rules[:0] == []`. Reaching that state needs an edit to the emitter that stops
emitting the rule at all — in which world the row's sentence ("the document carries this decision")
is vacuously true and the *emitter* is the defect. It is nevertheless the coupling's one silent
failure mode, against the rename's loud one, and worth a line in the pool.

**"AC-15 should be scored a pass because the code is right and only a changelog line is wrong."**
Rejected. AC-15's subject is the published sentence, not the code; the criterion has one failing
member and a criterion with a failing member has failed. Scoring it a pass would be the report
version of the very defect under repair.

**"The verdict should be APPROVED because one MAJOR documentation defect is not worth a round."**
Rejected, but stated so the PM can weigh it: everything else is green, the defect is one clause, and
a PM who fixes it in place and re-runs `verify_all` has discharged it. I still return CHANGES
REQUIRED, because a QA verdict of APPROVED with a known-false published sentence in the delivery is
the outcome R-22 exists to prevent, and because QA does not write the repair itself.

## What I did not do

No request of any kind was issued to the live Clash API; the only `/dns/query`, `/proxies` and
`/configs` traffic anywhere in this stage was against my own `http.server` stub bound to a loopback
port chosen per case. The installed `/usr/local/bin/sc` was never run and never overwritten. Nothing
under `/etc/sing-box` was read or written. `/var/lib/sing-box` was **witnessed** (mtime, entry list)
before and after every `main()`-driven non-doctor run and never written — the only reach into it is
`_init_files()`'s `exist_ok=True` `mkdir`, disclosed above. The live service was never started,
stopped, restarted, enabled or queried with `is-active`; the only real subprocesses any fixture ran
were `ip -br addr show sb-tun` (read-only) and the fixture's own `sing-box` stub. No file in the
repository was modified except this document and `06_TEST_REPORT.md`. `.harness/scripts/verify_all.sh`
and its checks were not touched, and `baseline.json` was not lowered or changed.
