# 06 — Test Report · T-19 `ruleset-staleness-visibility`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).
>
> Mode: **full**. Every fixture below was written from `01`'s acceptance criteria, not from
> `04_DEVELOPMENT.md`'s test code: an independent `qafix.py` / `v_status.py` / `v_update.py` /
> `v_config.py` / `v_bounds.py` / `v_regress.py` / `v_e2e.py` / `v_time.py` set, never committed
> (out-of-scope 8). **106 sidecar-recorded child-process runs plus 3 ad-hoc probes**, 78 temp roots.
> Safety floor honoured throughout: no write under `/etc/sing-box` or `/var/lib/sing-box`,
> `_init_files()` never driven, `/usr/local/bin/sc` never invoked, `main()` never driven, no
> `sudo`, no `HARNESS_ALLOW_OUTSIDE_RM`, the live service never started/stopped/restarted/reloaded
> and never probed with `is-active`.
>
> **Schema note (E-20, fifth stage to record it).** `.harness/rules/70-doc-size.md` on this
> project defines no `## Stage-doc boundary rule`, so the units the PM's dispatch requires in this
> contract — the per-observation control ledger (C-3), the C-2 measurement, the C-4 pair, the C-5
> stub logs and the C-8 byte comparison — fit no declared section shape. They are carried below as
> named sections, per the precedent stages 2–5 set and stage 5 approved, and the gap is filed as
> QA-D1 in `## Defects found`.

## Test plan

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-B1 aged + fresh rule-set both named with a duration | `v_status.py base` (en, zh) — O-1, O-2 | `scratchpad/v_status.py`, captures `cap/base-{en,zh}.out` |
| AC-B2 absent + unreadable read as unavailable, no numeric duration | `v_status.py base` per-line assertions + a scan of every capture — O-3 | `v_status.py`, assertion sweep in `06_RATIONALE.md` |
| AC-B3 section prints when the service is not reachable | `v_status.py base` (`is_running()` False) — O-4; paired with `v_status.py running` (True) — O-5 | `v_status.py`, `cap/base-en.out`, `cap/running-{en,zh}.out` |
| AC-B4 emitted config is timestamp-independent (**FREEZE**) | `v_config.py` ×2 at one root, now vs −30 d — O-9; plus the HEAD-vs-candidate differential — O-10 | `v_config.py`, `cap/cfg/*.json` |
| AC-B5 failed regeneration ⇒ non-zero, no service action, no false claim | `v_update.py regenfail` (child process) — O-11 | `v_update.py`, `cap/u/regenfail-en.*`, `cap/u/H-regenfail-en.*` |
| AC-B6 failed restart ⇒ non-zero, no false restart claim | `v_update.py restartfail` (en, zh) — O-12; `restartok` control — O-13 | `v_update.py`, `cap/u/restartfail-*`, `cap/u/H-restartfail-en.*` |
| AC-B7 all-mirrors-fail and nothing-changed freezes | `v_update.py deadmirror` — O-14, and `nochange` — O-17 | `v_update.py`, `cap/u/{,H-}{deadmirror,nochange}-en.*` |
| AC-B8 exactly one true outcome line per run | outcome-line count + stub-log cross-check over 19 update captures — O-21, reported as the four separate observations C-3 requires | `06_RATIONALE.md` `## AC-B8 …` |
| AC-B9 shipped invocation as root against the live unit | **not attempted** — K-18 / P-6 — O-38 | — |
| AC-S1 one timestamp query, one age renderer | static sweep of `bin/sc` — O-33 | `grep` transcript in `06_RATIONALE.md` |
| AC-S2 both languages, matching placeholders, no `失败`, no `\r` | key table read + byte scan of 192 captured streams — O-34 | assertion script in `06_RATIONALE.md` |
| AC-S3 product diff, ledger carve-out, dev-map bound, verify_all | `git diff --name-only` / `--numstat` / `git diff docs/dev-map.md` / `verify_all.sh` — O-35 | `## verify_all result`, `## AC-S3 …` |

## Observation ledger (C-3 — control class is a property of the OBSERVATION)

`control` compares the **candidate** against a pristine `git clone` of HEAD `84c8d8b` run at the
**same fixture root**. A `FREEZE` row agrees at HEAD **by construction** and is never quoted as
evidence that the behaviour changed.

| id | step | what was observed | control |
|---|---|---|---|
| O-1 | V-1 / AC-B1 en | 4 rows in `RULESET_FILES` order; aged file `30 days ago`, fresh `0 seconds ago` | **disagrees** — HEAD prints no rule-set section |
| O-2 | V-1 / AC-B1 zh | `可用, 30 天前` / `可用, 0 秒前` | **disagrees** |
| O-3 | V-2 / AC-B2 | absent ⇒ `missing, last update unknown`; directory ⇒ `unreadable, last update unknown`; no digit after the filename column in any such row, any capture | **disagrees** |
| O-4 | V-3 / AC-B3 / BC-6, `is_running()` **False** arm | all 4 rows complete; the `=== Current node ===` … `=== Egress IP ===` block absent | **disagrees** |
| O-5 | C-4 pair, `is_running()` **True** arm | the same 4 rows print, above the node/route/egress block | **disagrees** |
| O-6 | V-4 / BC-5 | `RULES_DIR` deleted ⇒ 4 × `missing, last update unknown`; the directory still does not exist after the run and `CFG_DIR` gained nothing | **disagrees** |
| O-7 | V-5 / BC-4 | mtime 100 000 s **ahead** of the clock ⇒ `0 seconds ago` / `0 秒前`; the other three read `2 hours ago`, so the clamp is not confused with "just written" | **disagrees** |
| O-8 | V-7 / BC-3 | readable 0-byte ⇒ `("too-small", sha256(b""), 0, 1786698315.918187)` — a real digest, a real `0` **and** a real mtime | **disagrees** — HEAD returns a 3-tuple |
| O-9 | V-6 / AC-B4 | one root, timestamps now vs −30 d ⇒ identical `sha256 5a191d0b00dc2e72…`, 6435 bytes, `route.rule_set` identical (4 entries) | **agrees — FREEZE** |
| O-10 | FR-5 differential | HEAD and candidate `generate_config()` at the **same** root ⇒ same sha256, same byte count | **agrees — FREEZE** |
| O-11 | V-8 / AC-B5 / BC-9 | exit **1**; no `config regenerated` line; outcome `… — the sing-box service was not touched`; stub log holds only the `check` argv | **disagrees** — HEAD exits **0** and claims the regeneration |
| O-12 | V-9 / AC-B6 / BC-10 | exit **1**; outcome `… — the sing-box service could not be restarted`; exactly one `systemctl restart` in the log | **disagrees** — HEAD exits **0** and claims a restart |
| O-13 | restart returns 0 | exit 0, `… — sing-box restarted to load them`, `Done` | agrees — byte-identical to HEAD |
| O-14 | V-10 / AC-B7 / BC-8 | exit 1; per-file causes on stdout; one `4 ruleset(s) failed to update` on stderr, preceded by a blank line; one outcome line | **agrees — FREEZE** |
| O-15 | C-8 merged `>>file 2>&1` | HEAD and candidate captures **byte-identical**, 1121 bytes, `sha256 5d5aba6a…b380a` | **agrees — FREEZE** |
| O-16 | C-8 non-vacuity mutant | the candidate with `bin/sc:2869` deleted ⇒ merged capture **differs** from HEAD at byte 836 | disagrees — the check is not vacuous |
| O-17 | V-11 / AC-B7 / BC-11 | byte-identical mirror ⇒ exit 0, `No rule-set changed — …`, `Done`, empty stub log | **agrees — FREEZE** |
| O-18 | V-13 / BC-12 | no `config.json` ⇒ no `generate_config()` call (no `SB_BIN` in the log), no service action, exit 0 | agrees |
| O-19 | V-14a / BC-13 helper `sys.exit` | exit non-zero, cause on stderr, empty stub log, **no** outcome line | agrees |
| O-20 | V-14b / BC-13 `OverrideError` | exit non-zero, cause on stderr, empty stub log, **no** outcome line | agrees |
| O-21 | V-12 / AC-B8 | see `## AC-B8 …` — four separate observations, never one aggregate | per-observation |
| O-22 | R-22 behavioural goal, end to end | one file really refreshed, three really not ⇒ `sc status` reads `0 seconds ago` / `30 days ago` ×3, run exits 1 | **disagrees** |
| O-23 | P-5 | the succeeding fetch renews the timestamp; a failed fetch keeps the previous one | premise, confirmed |
| O-24 | out-of-scope 6 | four byte-identical re-fetches move every mtime 30 d → 0 s, yet `changed_usable_tags()` is `[]` and nothing was touched | agrees |
| O-25 | regression `sc doctor` | stdout, stderr, exit status and stub log identical HEAD vs candidate | agrees — FREEZE |
| O-26 | regression `sc ls` | identical | agrees — FREEZE |
| O-27 | regression `sc reload` with a **failing** restart | identical at both builds, exit 0 both — K-8 / out-of-scope 5 observed, not asserted | agrees — FREEZE |
| O-28 | `_age_text()` ladder, 17 deltas × 2 languages | boundaries at 59/60, 3599/3600, 86399/86400 all correct; negatives clamp to `0 seconds ago` | **disagrees** — no renderer at HEAD |
| O-29 | DIGEST CONTRACT over 8 file shapes | directory / dangling symlink / FIFO / mode 000 ⇒ `unreadable, None, None, None`; absent ⇒ `absent,…`; 0-byte, 3-byte and bad-magic ⇒ real digest + real size + real mtime | **disagrees** |
| O-30 | K-1 mechanically | `ruleset_state()` on a usable file ⇒ `sc.os` calls `{stat: 0, fstat: 1, lstat: 0}` | **disagrees** |
| O-31 | C-2 warm cache | see `## C-2` | measurement |
| O-32 | C-2 cold cache (`posix_fadvise(DONTNEED)`) | see `## C-2` | measurement |
| O-33 | V-15 / AC-S1 | exactly one `st_mtime` read, at `bin/sc:816` | static |
| O-34 | V-16 / AC-S2 | 7 zh keys, equal placeholder sets, no `失败`, 0 of 192 captured streams contain `\r` | static |
| O-35 | V-17 / AC-S3 | see `## AC-S3` | static |
| O-36 | C-1 | `HELP_EN` / `HELP_ZH` `status` lines and `README*.md:245` name the same five items, descriptions still at column 30 | static |
| O-37 | P-1 | `sys.exit("boom")` ⇒ status 1, stdout empty, stderr `boom\n` (5 bytes) | premise, confirmed |
| O-38 | V-18 / AC-B9 | **BLOCKED** — needs root and the live unit (K-18, P-6). Not substituted | — |

**37 pass · 0 fail · 1 BLOCKED.**

## Adversarial tests

One row per acceptance criterion. The hypothesis was written **before** the run. Every reproducer
is mine; none is stage 4's. Cited output is ≤5 lines; full runs are in `06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-B1 | the fresh file's age races the clock and renders `-1 seconds ago`, or the aged one rounds to `29 days` | `v_status.py <repo> base en <root>` (NEW), stdout redirected to a file | Survived — `geoip-cn.srs         usable, 0 seconds ago` / `geosite-cn.srs       usable, 30 days ago`; HEAD control prints no such section |
| AC-B2 | the unavailable rows leak a number — an epoch date, a `0`, or a digit from the status text | same capture + a regex sweep of the suffix after column 20 in **every** capture | Survived — `geosite-google.srs   missing, last update unknown` / `geosite-private.srs  unreadable, last update unknown`; sweep: `no digit anywhere after the filename column  OK` |
| AC-B3 | the section is really gated on port silence, so it vanishes when `is_running()` is True | `v_status.py base` (False arm) **and** `v_status.py running` (True arm, stubbed `is-active` → 0) | Survived, as a pair — both arms print all four rows. False-arm stub log is `[['ip','-br','addr','show','sb-tun']]` **before and after an extra `is_running()` probe**, i.e. no port and no command is consulted |
| AC-B4 (**FREEZE**) | a timestamp reaches `route.rule_set` or changes key order | `v_config.py <repo> <root> {0,2592000}` ×2 at one root, sha256 compared | Survived — `cand-fresh sha256=5a191d0b00dc2e72 bytes=6435` / `cand-30d sha256=5a191d0b00dc2e72 bytes=6435`; `AC-B4 … byte-identical: True ; route.rule_set identical: True`. Agrees at HEAD by construction |
| AC-B5 | the run still restarts, or still claims a regeneration, or still exits 0 | `v_update.py <repo> regenfail en <root>` (NEW, child process; the stub enumerates **no** restart argv, so a restart attempt would raise) | Survived — `EXIT=1`; `Rule-sets updated: geosite-private — the sing-box service was not touched`; stub log `[[<SB_BIN>,'check','-c',<CFG>]]`. **HEAD control: `EXIT=0`, `Rule-sets restored: geosite-private — config regenerated`, `Done`** |
| AC-B6 | the failed restart is swallowed, or the outcome line still claims a restart | `v_update.py <repo> restartfail {en,zh} <root>` (NEW) | Survived — `EXIT=1`; `Rule-sets updated: geosite-private — the sing-box service could not be restarted` (zh `…—— sing-box 服务重启未成功`); exactly one `['systemctl','restart','sing-box']`. **HEAD: `EXIT=0` + `… — sing-box restarted to load them` + `Done`** |
| AC-B7 (**FREEZE**) | the stderr aggregate moved stream, lost its leading blank line, or the zero-exit path regressed | `v_update.py deadmirror` and `v_update.py nochange`, HEAD and candidate at the **same** root | Survived — dead mirror: `EXIT=1`, stderr `\n4 ruleset(s) failed to update\n`; nochange: `EXIT=0`, `No rule-set changed — the sing-box service was not touched` + `Done`. Agrees at HEAD by design |
| AC-B8 | some state prints two outcome lines, or a line makes a claim untrue of its run | outcome-line counter + stub-log cross-check over 19 update captures (`## AC-B8 …`) | Survived — exactly one line from I-6's closed set in all 17 tail-reaching runs, zero on the two unwind paths; the only `config regenerated` claim on a failed check is **HEAD's** |
| AC-B9 | — | not attempted | **BLOCKED** — needs root and the live unit; K-18 forbids it to every agent here. **Not substituted with a unit-file read** (R-31 precedent) |
| AC-S1 | a second timestamp query hides behind `pathlib` or a display site | `grep -n "st_mtime\|st_ctime\|st_atime\|getmtime\|os\.stat\|\.stat()\|fstat\|time\.time()\|st_size" bin/sc` + a call counter on `sc.os` | Survived — one code hit, `816: mtime = os.fstat(fh.fileno()).st_mtime`; counter: `sc.os calls: {'stat': 0, 'fstat': 1, 'lstat': 0}`. `:1388` `os.stat` reads `st_mode` only (A-2's known non-timestamp hit) |
| AC-S2 | a zh key's placeholder set diverges, or a progress `\r` leaks into a redirected stream | key-table assertion + `\r` byte scan over every captured stream | Survived — 7 keys, `ph(en)==ph(zh)` for all; `no 'en' table: True`; `192 captured streams scanned; streams containing CR: 0` |
| AC-S3 | the diff reaches a file neither list admits, or `bin/sc` overruns +80/−30 | `git diff --name-only`, `--numstat`, `git diff docs/dev-map.md`, `verify_all.sh` | **Two paths in neither list** — `docs/batches/default/BATCH_PLAN.md` (M) and `BATCH_LOG.md` (??), both the batch loop's and both present before stage 4. Product diff and `bin/sc` **+80/−29** are clean. Filed QA-D2 |
| C-8 | the merged capture only *looks* frozen because the check cannot fail | a **mutant** candidate with `bin/sc:2869`'s `sys.stdout.flush()` deleted, same root | Check is live — HEAD vs candidate `BYTE-IDENTICAL`; HEAD vs mutant `differ: byte 836, line 4`, the fourth per-file line split by the aggregate exactly as `04_RATIONALE.md` describes |
| R-22 | every AC is green while the behavioural goal is unobserved | `v_e2e.py` (NEW): four rule-sets aged 30 d, a mirror serving **one** of them, then `sc status` | Goal observed — `geoip-cn.srs usable, 0 seconds ago` / three × `usable, 30 days ago`; the run itself exits 1 with `3 ruleset(s) failed to update` |
| out-of-scope 6 | the new timestamp silently became a content-change signal, so a byte-identical re-fetch now restarts the service | re-fetch all four byte-identical, compare mtimes and `changed_usable_tags()` | Survived — `mtime really changed for every file: True`, `changed_usable_tags(before, after) = []`, `stub log (service actions): []` |
| K-8 / out-of-scope 5 | `restart_service()` returning a bool changed `sc reload` | `v_regress.py reload` with `systemctl restart` → 1, HEAD vs candidate | Survived — stdout, stderr, exit status and stub log all `IDENTICAL`; both exit 0 |

## Boundary tests added

- Rule-set file **absent** → `absent`, age word form (BC-1).
- Rule-set path **unreadable** in all four shapes independently — a **directory**, a **dangling
  symlink**, a **FIFO**, and a **mode-000 regular file** — each → `("unreadable", None, None, None)`
  and the age word form (BC-2).
- Readable **0-byte** file → `too-small` with a real digest, a real `0` and a real mtime (BC-3).
- **3-byte** file (shorter than `SRS_MAGIC`) and a **bad-magic** file → real digest/size/mtime too:
  the DIGEST CONTRACT's equivalence is exercised on both sides, not only on the `None` side.
- Timestamp **ahead of the clock** by 100 000 s → `0 seconds ago`; unclamped the ladder would have
  rendered `-2 days ago` (BC-4).
- `_age_text()` unit boundaries: `0, 1, 59, 60, 61, 119, 3599, 3600, 3601, 86399, 86400, 86401,
  129600, 2592000, -1, -100000` seconds and `None`, in **both** languages — 35 renderings.
- Rule-sets **directory absent entirely**; asserted it still does not exist after the run (BC-5).
- Service **stopped and running**, as a pair (BC-6).
- stdout **not a terminal** for every run (the caller's shell owns the redirect); 192 captured
  streams scanned for `\r` (BC-7).
- **Every mirror fails** for every file (BC-8); **one file succeeds while three fail** (P-5, R-22).
- Config **regeneration fails** (BC-9); **restart fails** (BC-10); **nothing changed** (BC-11);
  **no `config.json`** (BC-12); **two unwind paths** past the tail (BC-13).
- Byte-identical re-fetch of all four files, i.e. the mtime-changes-but-content-does-not corner
  (BC-14's mechanism and out-of-scope item 6).

## C-2 — the NFR cost, measured

Fixture `.srs` are the **host's real rule-set bytes**, copied read-only out of
`/etc/sing-box/rules/` into the temp root:

| file | bytes |
|---|---|
| `geoip-cn.srs` | 21 944 |
| `geosite-cn.srs` | 447 370 |
| `geosite-google.srs` | 7 912 |
| `geosite-private.srs` | 696 |
| **total** | **477 922** |

`cmd_status()` only, one run per child process, `SYSTEMD = OPENRC = False` so both builds skip the
node/route/egress block, HEAD and candidate **alternated** at the same root:

| condition | HEAD (ms) | candidate (ms) | medians | added median |
|---|---|---|---|---|
| warm page cache | 0.013, 0.013, 0.012, 0.012, 0.012 | 0.461, 0.463, 0.470, 0.448, 0.455 | **0.012** → **0.461** | **+0.449 ms** |
| cold (`posix_fadvise(POSIX_FADV_DONTNEED)` before each run) | 0.012, 0.013, 0.013, 0.013, 0.012 | 1.673, 1.659, 1.061, 1.459, 1.528 | **0.013** → **1.528** | **+1.516 ms** |

The added median is **1.516 ms** at worst, against C-2's 250 ms ceiling — **no defect against this
condition**. The reading the gate narrowed the NFR to is confirmed by O-30: the *timestamp* costs
one `fstat` on an already-open handle and **zero** `os.stat` calls; the ~1.5 ms is RS-4's four full
`.srs` reads, which are the only honest source of the status the section prints.

## C-4 — BC-6 observed as a pair, and the lever named

The section printed in **both** `is_running()` states (O-4, O-5). V-3's expected observable as
written in `02` — "nothing listening on the fixture's `clash_api_port`" — is **not** the operative
mechanism and is corrected here rather than quoted: with `SYSTEMD = OPENRC = False`,
`is_running()` (`bin/sc:2044`) returns `False` from its final `return False` **without consulting
any port, any socket or any command**, and the section prints because K-6 places it above the
`if is_running():` guard. Measured rather than argued: in the `False`-arm run the stub call log is
`[['ip','-br','addr','show','sb-tun']]` **before** an extra explicit `is_running()` call and
**identical after it** — the call added no argv, so nothing was consulted.

The `True` arm made **no live network call and no live service call**: `systemctl is-active` was
answered by the stub, `_egress_ip` was replaced by a raiser (the capture shows
`(error: no live network call)`), and the one Clash call is a **GET** — `clash_api("GET","/configs")`
— against **port 45733**, proved free before use (`ss -lnt sport = :45733` → no listener; a TCP
connect → `ConnectionRefusedError`). **CR-3 / RES-3 discharged: `29090` was never used by this
stage**; `ss -lntp` confirms it is the live sing-box's port here.

## C-5 — the safety floor, as executed

Every step that set `SYSTEMD = True` ran in a **child process** and installed the stub in the
**loaded module's own namespace**: `sc.subprocess = qafix.stub_subprocess(table, log)`. The real
`subprocess` module object was never mutated — `subprocess.run = …` appears nowhere in the fixture
set. The stub is **total and closed**: a canned result per explicitly enumerated argv tuple, and
`raise StubRefused("STUB REFUSED un-enumerated argv: …")` on anything else; `Popen`, `call`,
`check_call` and `check_output` raise unconditionally. **No run raised `StubRefused`** — i.e. no
argv was ever executed rather than stubbed — and in AC-B5's table `["systemctl","restart",…]` is
deliberately **absent**, so an attempted restart there would have aborted the run loudly instead of
reaching the host. Full per-run call logs are in `06_RATIONALE.md`; the four load-bearing ones:

- AC-B5 (`regenfail`): `[[<SB_BIN>,'check','-c',<CFG>]]` — no `systemctl` at all.
- AC-B6 (`restartfail`): `[[<SB_BIN>,'check',…], ['systemctl','is-active','--quiet','sing-box'], ['systemctl','restart','sing-box']]`.
- AC-B7 (`deadmirror`, `nochange`), BC-12, BC-13 ×2: `[]` — empty.
- `sc status` False arm: `[['ip','-br','addr','show','sb-tun']]`.

Live-service witness, read-only `systemctl show -p MainPID -p ActiveEnterTimestamp sing-box`
(**never** `is-active`):

| | MainPID | ActiveEnterTimestamp |
|---|---|---|
| before stage 6 | `2566751` | `Tue 2026-08-11 12:13:57 CST` |
| after stage 6 | `2566751` | `Tue 2026-08-11 12:13:57 CST` |

Unchanged, and identical to the value stage 4 recorded. `/etc/sing-box` (mtime `2026-08-11
12:13:57`), `/etc/sing-box/rules` (same) and `/var/lib/sing-box` (mtime `2026-07-30 12:59:24`) are
all untouched by this stage.

## C-8 — the freeze on the stream `install.sh:567` captures

The all-mirrors-fail run was captured **merged** (`>>file 2>&1`) at HEAD and at the candidate, in
that order, **at the same fixture root** — so no path normalisation was needed and the comparison is
raw bytes:

```
HEAD exit=1
CAND exit=1
=== cmp HEAD vs candidate ===
BYTE-IDENTICAL
5d5aba6a42682988d8de6d3d863dfff5b14809d00fa6bae364e83212789b380a  head.merged   (1121 bytes)
5d5aba6a42682988d8de6d3d863dfff5b14809d00fa6bae364e83212789b380a  cand.merged   (1121 bytes)
```

**C-8 discharged; RES-1's re-examination of `bin/sc:2869` is not required.** The check was proved
non-vacuous by a mutant build with that one line deleted, which differs from HEAD at byte 836 —
`  ↓ geosite-private.srs ... ` is left unterminated and the aggregate overtakes both it and the
outcome line, exactly the shape `04_RATIONALE.md` measured. Repeated 10×: byte-identical 10/10.

## AC-S3 — the diff, partitioned

`git diff --numstat` (added lines quoted from the **first field**, never from `--stat`'s bar):

```
2  0   CHANGELOG.md
1  1   README.md
1  1   README.zh-CN.md
80 29  bin/sc
5  5   docs/batches/default/BATCH_PLAN.md
3  2   docs/dev-map.md
```

- **Product list** — `bin/sc`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, `docs/dev-map.md`:
  all five present, nothing else. `bin/sc` **+80 / −29**, inside C-6's +80 / −30.
- **`docs/dev-map.md`, read line by line** against out-of-scope item 11: `+3 / −2`, entirely inside
  `## Reusable utilities` — the on-disk-reader row corrected, the per-file-snapshot row corrected,
  one row added (`"How old is this rule-set file?" → _age_text(mtime)`). No section added or
  removed, no other row's text altered, no row deleted. **CR-2 is discharged in this diff**: the
  corrected row now names `_runtime_overlay():1815` / `usable_tags():905` / `_warn_degraded():976`
  and states that `generate_config()` destructures nothing.
- **Ledger carve-out** — the untracked stage documents of this task only.
- **Two paths in neither list**: `docs/batches/default/BATCH_PLAN.md` (modified) and
  `docs/batches/default/BATCH_LOG.md` (untracked). Both are the batch loop's, both predate stage 4,
  and neither is written by any T-19 stage — but AC-S3 as written says "a path in neither list is a
  failure of this criterion". Reported as **QA-D2**, a defect in AC-S3's carve-out text, not in the
  candidate.
- **Safety** — no verification step wrote `/etc/sing-box` or `/var/lib/sing-box`, invoked
  `/usr/local/bin/sc`, or touched the live service or its units (witness above).

**C-1 cross-check** (assigned to this stage by the gate): `HELP_EN:3023-3024`
(`Show service status, TUN interface, rule-set status + age,` / `active node, egress IP`),
`HELP_ZH:3090`, `README.md:245` and `README.zh-CN.md:245` name the **same five items in the same
order**, with the same rule-set phrase; descriptions still start at column 30 in both help blocks,
continuation line included. The one divergence — help says `active node`, README says
`current node` — is **pre-existing at HEAD** and is re-homed as a follow-up row, not a T-19 defect.

## AC-B8 — four separate observations, never one aggregate

| V-id | run | outcome lines | every claim true of the run? | control |
|---|---|---|---|---|
| V-8 | regeneration failed | 1 — `Rule-sets updated: geosite-private — the sing-box service was not touched` | yes; it makes **no** regeneration claim, and the stub log shows no service action | **disagrees** (HEAD prints a false `config regenerated` and `Done`) |
| V-9 | restart failed | 1 — `… — the sing-box service could not be restarted` | yes; the log shows exactly one `systemctl restart`, which returned 1 | **disagrees** (HEAD prints `restarted to load them`) |
| V-10 | every mirror failed | 1 — `No rule-set changed — the sing-box service was not touched` | yes; empty stub log | **agrees — FREEZE** |
| V-11 | nothing changed | 1 — `No rule-set changed — …` + `Done` | yes; empty stub log | **agrees — FREEZE** |

Also counted across all 19 update captures: `Done` appears on **exactly** the zero-exit runs; the
two unwind paths (BC-13) print **zero** outcome lines, which is R-12's open row and **not** a T-19
defect; `Done` is never counted as an outcome line.

## verify_all result

```
total checks: 18
PASS: 17
FAIL: 0
WARN: 0
SKIP: 1   (B.3 Lint — no linter enforces style on bin/sc on this host)
```

- Total tests: 0 → 0 (`.harness/scripts/baseline.json` `test_count` is 0; no committed test suite)
- Pass: 17
- Fail: 0
- Warn: 0
- New tests added: 0 committed (out-of-scope item 8 / R-9 forbid a committed harness and a new
  `verify_all` step); 106 uncommitted fixture runs
- Baseline updated: **no** — `verify_all` reports no test count, `baseline.json` `test_count` did
  not increase, and `.harness/scripts/baseline.json` is in `02`'s frozen set. Nothing was lowered.

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| QA-D1 | MINOR | Read `.harness/rules/70-doc-size.md` — it has `## What this is`, `## When to read this`, `## Caps`, `## Process discipline`, `## Adversarial check` and no `## Stage-doc boundary rule`, so five units the PM's dispatch requires in this contract (C-2, C-3, C-4, C-5, C-8 evidence) fit no declared stage-6 section shape. Fifth stage to record it (E-20 → RES-10). Owed to the harness rule fragment, not to any T-19 code. | `.harness/rules/70-doc-size.md:18` |
| QA-D2 | MINOR | `git diff --name-only` ⇒ `docs/batches/default/BATCH_PLAN.md`; `git ls-files --others --exclude-standard` ⇒ `docs/batches/default/BATCH_LOG.md`. Neither is in AC-S3's product list nor in its ledger carve-out, and AC-S3 says such a path "is a failure of this criterion" — yet both are the batch loop's own bookkeeping, present before stage 4 and written by no T-19 stage. The carve-out text needs `docs/batches/**`; the candidate is clean. Owed to **stage 1** (`01_REQUIREMENT_ANALYSIS.md` AC-S3) / the PM. | `docs/features/ruleset-staleness-visibility/01_REQUIREMENT_ANALYSIS.md:149` |

No defect was found in `bin/sc`, in either README, in `CHANGELOG.md` or in `docs/dev-map.md`.
Neither QA-D1 nor QA-D2 blocks delivery: both are documentation-side and neither is fixable inside
this task's permitted diff.

## Stability

- `cmd_status` AC-B1 fixture, 10 consecutive runs: **1** distinct rule-set section across all 10. No
  flakes.
- `cmd_update_rules` AC-B6 fixture, 10 consecutive runs: exit status `1` all 10, **1** distinct
  stdout. No flakes.
- C-8 merged HEAD-vs-candidate comparison, 10 consecutive pairs: **byte-identical in 10/10**.
- C-2 was measured five times per build in each cache condition; spread is ≤0.03 ms warm and
  ≤0.62 ms cold, both far inside the 250 ms ceiling, so no timing flake can change the verdict.
- No test in this stage is time-of-day, network or ordering dependent: every fetch is `file://`,
  every subprocess is stubbed, and every fixture is a fresh `mkdtemp()` root.

## Blocked, and not substituted

**AC-B9 / V-18 / P-6** — "the installed unit's command, run as root on a systemd host, records a
failed unit when the run fails" — is **BLOCKED**. Reason: it requires root and a live-unit trigger,
which K-18 forbids to every agent in this pipeline, and this session has no `sudo`. It was **not**
substituted with a unit-file read (the R-31 / T-18 precedent). The whole of the evidence for "a
non-zero exit makes the unit fail" therefore remains the `Type=oneshot` / one un-prefixed
`ExecStart` / no `SuccessExitStatus=` / no `Restart=` reading behind Q-7, which is C-7's sentence for
`07_DELIVERY.md`. `.harness/operator-obligations.md` was deliberately **not** created: `.harness/**`
is outside this task's permitted diff, and this project's precedent (R-30, R-31) routes an operator
obligation to `docs/tasks.md` through the PM.

## Follow-up rows for the PM (re-homed, not fixed here)

| # | row | owner |
|---|---|---|
| 1 | **Operator obligation** — run the shipped invocation as root against the live unit and read back `systemctl show -p Result,ExecMainStatus sing-box-rules-update.service`, closing AC-B9 / P-6. Same shape as R-30 / R-31. | owner |
| 2 | AC-S3's ledger carve-out omits `docs/batches/**`, which the batch loop writes on every task (QA-D2). Any future task using the same AC-S3 template inherits the false failure. | PM / next requirement analyst |
| 3 | `HELP_EN` says `active node` where `README.md:245` says `current node` — pre-existing at HEAD, unrelated to T-19, but the two enumerations are otherwise word-for-word. | next task touching `HELP_EN` |
| 4 | RES-4 (zh row separator `可用, 30 天前` vs doctor's `可用，5572 字节`), RES-5 (`_status_view()`'s docstring still repeats F-14's false attribution at `bin/sc:856-857`), RES-6 (`1 days ago` is reachable) — all confirmed present in the shipped build and all already homed by stage 5. | `07_DELIVERY.md` |
| 5 | R-33 was **not** observable in this stage's captures (the `ip` child is stubbed, so it writes no fd), so no evidence was added for or against it. Unchanged, out of scope (Q-12). | next task touching `cmd_status` |

## Verdict

APPROVED FOR DELIVERY
