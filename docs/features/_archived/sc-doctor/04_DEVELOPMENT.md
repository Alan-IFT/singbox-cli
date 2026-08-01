# 04 — Development Record — `sc doctor` (T-05)

Mode: **full** · Stage 4 (+ **stage 4b fix-up round**) · Decision mode: **deferred-human (defer, do
not ask)**. Inputs treated as binding and unedited: `01_REQUIREMENT_ANALYSIS.md`,
`02_SOLUTION_DESIGN.md`, `03_GATE_REVIEW.md` (approved with conditions C-1..C-8). Nothing was
committed or pushed; the tree is left dirty for the owner.

> **Stage 4b (post-review fix-up).** Stage 5 returned `APPROVED WITH FOLLOW-UPS` (no BLOCKER, no
> MAJOR). The PM routed exactly two items back before QA: **M-2** (code — the dangling header) and
> **M-3** (record — three arithmetic slips), plus an explicit answer to **M-1**. §3, §4 E-2/E-15 and
> §7 below now carry the **re-measured** numbers; the new work is in **§5b**. Everything else in this
> document is the stage-4 record, unchanged.

---

## 1. Live-service witness (start and end, verbatim)

```
stage 4  BEFORE  MainPID=2500438
                 ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
stage 4  AFTER   MainPID=2500438
                 ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
stage 4b BEFORE  MainPID=2500438
                 ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
stage 4b AFTER   MainPID=2500438
                 ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
```

Identical at all four readings. `systemctl is-active` was never used as evidence
(`insight-index.md:22`): it prints `active` on both sides of a restart, so it cannot detect a bounce.
The witness was re-read after the S4 real-systemd probe, after the `update-rules` harness, and again
after every stage-4b harness — unchanged at every reading. Every harness loads `bin/sc` through one
shared loader (`scratchpad/schar.py`) that **asserts** the import-time sudo re-exec (`bin/sc:83-84`)
was replaced before executing the module, and sets `SYSTEMD = OPENRC = False`; no throwaway script,
including one-liners, bypasses it.

---

## 2. Summary

`sc doctor` is implemented as one driver plus seven probes inside `bin/sc`, with four supporting
changes: `ruleset_state()` now returns the byte count it already computed, `main()` parses arguments
before initialising so `doctor` reaches neither writer on the start-up path, `_resolve_clash_port()`
is split into a read-only reader plus the probing resolver, and the TUN name and egress query each
become one definition. No new file, module, flag or dependency. `sc status` is byte-identical.

---

## 3. Files changed (the permitted five, and nothing else)

**Corrected in stage 4b (M-3a).** Stage 4 recorded `bin/sc | +484/−43 lines, 1536 → 1946`, which does
not close (1536 − 43 + 484 = 1977). The mistake was reading `git diff --stat`'s **graph column**
(484 = *total* lines touched, 447 + 37) as the insertion count. The authoritative measurement, taken
after the M-2 fix, verbatim:

```
$ git diff --stat -- bin/sc README.md README.zh-CN.md CHANGELOG.md docs/dev-map.md
 CHANGELOG.md    |   2 +
 README.md       |  31 ++++
 README.zh-CN.md |  31 ++++
 bin/sc          | 494 +++++++++++++++++++++++++++++++++++++++++++++++++++-----
 docs/dev-map.md |  24 ++-
 5 files changed, 539 insertions(+), 43 deletions(-)
```

Per file, from `git diff --numstat` on the same tree (insertions / deletions — the numbers `--stat`'s
graph column does *not* give you):

| File | + | − | Change |
|---|---|---|---|
| `bin/sc` | **457** | **37** | E-1..E-18 (§4 below) + the M-2 fix (§5b); `grep -c '^'`: 1536 → **1956** |
| `README.md` | 31 | 0 | `sc doctor` in the service-control block + `### Diagnose the install` (seven sections, the changes-nothing promise, the exit table) |
| `README.zh-CN.md` | 31 | 0 | line-for-line mirror (`### 诊断安装`) |
| `CHANGELOG.md` | 2 | 0 | one bullet under `[Unreleased] → 新增`, zh |
| `docs/dev-map.md` | 18 | 6 | inventory updates (§8) |
| **total** | **539** | **43** | = the `--stat` summary line above |

It now closes on the file that matters: **1536 − 37 + 457 = 1956**, and `grep -c '^' bin/sc` returns
**1956**. (Before the M-2 fix the same file measured +447/−37 → 1946, matching the reviewer's
`grep -c '^'` reading of 1946; the fix adds 10 lines: 8 in `_doctor_config()`, 2 zh.)

**AC-26 re-verified at the end of stage 4b:** `git diff --quiet -- install.sh uninstall.sh systemd/`
→ **exit 0**, i.e. those three are byte-identical to `HEAD`. `.harness/rejected-decisions.md` and `docs/tasks.md` are
also dirty in the work tree — **not my edits**; they are the earlier pipeline stages' harness
artefacts (PM: `02_` §2 predicted the rejected-decisions records; they must be declared in `07_`).

---

## 4. What was implemented, against the edit list

| # | Where (post-diff) | Done |
|---|---|---|
| E-1 | `bin/sc:24-30` | `TUN_IFACE = "sb-tun"` with its three consumers named |
| E-2 | `bin/sc:170-215` | **41** zh entries under a `# doctor` comment (M-3c: stage 4 wrote 42; the reviewer's count of 41 is correct). Stage 4b's M-2 fix adds one more, so the doctor block now holds **42** and `TRANSLATIONS["zh"]` grows from 66 keys at HEAD to 108 — measured by loading both modules and diffing the key sets, not by eye |
| E-3 | `bin/sc:232-247` / `:250-278` | `_saved_clash_port()` split out; `_resolve_clash_port()` calls it (C-2 below) |
| E-4 | `bin/sc:281-290` | `_egress_ip()` — endpoint + 8 s timeout + decode, byte-faithful |
| E-5 | `bin/sc:583-628` | `ruleset_state()` → `(status, digest, size)`; contract extended by one clause |
| E-6 | `bin/sc:645-658` | `ruleset_states()` appends 5-tuples |
| E-7 | `bin/sc:661-667` | `_status_view()` unpacks five, emits the same 3-tuples |
| E-8 | `bin/sc:694,696` | `changed_usable_tags()` unpackings widen by one `_size` — **no logic line moved** |
| E-9 | `bin/sc:715-727` | `_status_text()` gains `"usable": t("usable")` |
| E-10/E-12/E-13 | `bin/sc:944`, `:1170`, `:1182` | `TUN_IFACE` substituted twice; `print(_egress_ip())` inside the existing `try` |
| E-11 | `bin/sc:1016-1020` | `clash_api(method, path, data=None, port=None)`, URL uses `port or CLASH_PORT` |
| E-14 | `bin/sc:1186-1420` | the doctor block: constants, `_plain()`, `_doctor_run()`, `_first_line()`, seven probes, `DOCTOR_SECTIONS`, `_doctor_print()`, `cmd_doctor()` |
| E-15 | `bin/sc:1802-1806`, `:1859-1863` | `doctor` after `status` in both help blocks, **+5 lines each** (M-3b: stage 4 wrote +3; the two diff hunks are `@@ -1405,0 +1802,5 @@` and `@@ -1457,0 +1859,5 @@` — one description line plus four sub-lines, the last three being the exit table), same relative position, descriptions at col 30 / sub-lines at col 32 |
| E-16/E-18 | `bin/sc:1917`, `:1946` | `sub.add_parser("doctor")`; `"doctor": cmd_doctor` |
| E-17 | `bin/sc:1932-1944` | **C-1's form** — see below |

One addition beyond `02_` §5.1: `_first_line(text)` (first non-empty line of a tool's output), used
by S1 and S4. It is two call sites of the same three-line loop; without it the loop is duplicated.

**Anchor caveat (stated so nobody trusts a stale number).** Only the E-2 and E-15 anchors above were
re-measured in stage 4b. The rest were written mid-implementation and drift from the finished file by
a few dozen lines (e.g. E-14's doctor block actually spans `bin/sc:1215-1510`, not `:1186-1420`).
Every row is also named by its function, which is how all eighteen resolved for the reviewer; the
authoritative locations are `git diff` and `05_CODE_REVIEW.md` §5, not this column.

---

## 5. How each gate condition was discharged

**C-1 — D-3 executed as the gate restated it.** `parse_args()` was **not** moved. The three
statements at old `:1501-1503` moved **down**, verbatim and in order, into the `else` arm
immediately after `args = parser.parse_args()`; `global LANG, CLASH_PORT` stays as the first line of
`main()`. Executed evidence (`t_regress.py`): `sc doctor` through `main()` leaves the sandboxed
`/etc/sing-box` stand-in **non-existent** and the whole sandbox root empty, while `sc lang zh`,
`sc mode global`, `sc status`, bare `sc` and `sc help` each still create the tree, write
`nodes.json` at mode 0600 and persist `clash_api_port` (RISK-2 / T-6, five commands, all PASS).
A usage error still exits 2 and now creates nothing (the stated, more conservative consequence).

**C-2 — the settings merge is preserved and proven.** `_resolve_clash_port()`'s first-run branch
re-loads the dict inside the same `(FileNotFoundError, json.JSONDecodeError, OSError)` guard,
assigns `settings["clash_api_port"] = port` into it and keeps `except OSError: pass`. No
`save_settings()` call anywhere takes a fresh single-key dict. **Executed check** (`t_unit.py`): a
pre-auto-probe `settings.json` carrying `lang`/`mode`/`default_tun`/`update_interval` survives a
first-run port resolution with all four values intact and the new key added. `_saved_clash_port()`
additionally returns `None` for: no file, no key, malformed JSON, out-of-range port — and creates
no file.

**C-3 — S6 never reads the global.** `_doctor_clash()` calls `clash_api(..., port=port)` only on
the non-`None` branch; on `None` it prints two UNKNOWN rows and does not call `clash_api()` at all.
Verified two ways: an **AST call-graph walk** over all twelve doctor functions finds no reference to
`CLASH_PORT` (nor to any writer, `stat`, `st_size`, `mkdir`, `write_text`, …), and a `doctor` run
through `main()` leaves `CLASH_PORT` at its module default `29090`.

**C-4 — AC-16 restated so it can fail.** The original method cannot pass for *any* diff:
`cmd_status` prints `systemctl status --no-pager -n 5` (elapsed time, PID, five journal lines) and a
live egress address, so two captures of even the unmodified code differ. What I actually compared
(`t_status.py`):

- `HEAD:bin/sc` and the working tree loaded **in the same process**, both neutralised;
- the two volatile regions made deterministic rather than deleted — `SYSTEMD = OPENRC = False` so the
  `systemctl status` block does not run (it is also the region the diff provably does not touch), and
  `urlopen` replaced by a fixed stub so the egress *value* is constant while the egress *code path*
  (E-13) still executes;
- everything the diff can reach is inside the capture: the real `ip -br addr show` subprocess (E-12,
  captured at fd level), the egress block, every header, blank line and the `is_running()` gate;
- four comparisons: `lang=en`/`lang=zh` × egress-succeeds/egress-raises. All byte-identical;
- a **negative control**: the same comparison with `TUN_IFACE` perturbed to `"lo"` produces
  *different* bytes — so "identical" is not vacuous. Two further assertions confirm the compared
  capture really contains the `ip` output and the egress line.

QA can re-run `t_status.py` as-is; it needs no root and touches nothing.

**C-5 — `_plain()` at the call sites only.** Eleven call sites inside the doctor block: every `{e}`
(S1, S3 ×2, S4, S5, the driver backstop), `_doctor_run`'s merged output, S4's `{state}`, and
`_egress_ip()`'s return value in S7. `_egress_ip()` itself contains no `_plain` (asserted by source
slice), which is what keeps `sc status` byte-faithful. Executed: a fake checker emitting `\r` and
ESC in eight lines produces a report with zero `0x0D` and zero `0x1B`. The documented residue is
real and expected — ESC is stripped byte-wise, so `[31m` survives as text (design D-6 chose this
over importing `re`); the report stays AC-17-clean.

**C-6 — AC-13's deletion test, and the reading it required.** AC-13's criterion says "the existing
per-rule-set **report/state** functions" (plural); its illustrative deletion test names "the rule-set
report function". Read literally the illustration fails — deleting only `ruleset_report()` leaves S2
working — and **satisfying it literally would violate FR-12**: `ruleset_report()` returns
`(tag, filename, status)` and can carry no size, so taking status from it and size from
`ruleset_states()` means two reads per file and a report that can contradict itself under BC-15. A
functional requirement outranks an illustration inside an acceptance criterion, so AC-13 was read as
the state/report *machinery*. Executed in that stronger form (`t_unit.py`): deleting
`ruleset_states()` breaks `doctor`'s S2 **and** `ruleset_report()` together; deleting
`ruleset_state()` breaks S2 as well. No independent path survives.

**C-7 — RISK-1 measured, not predicted.** See §6.

**C-8 — why `doctor` asks the init system, not `settings["default_tun"]`.** `sc on` / `sc off` /
`sc default-tun` write `settings["default_tun"]` (`bin/sc:1157`, `:1214`) *after* asking systemd or
OpenRC to enable/disable the unit — so that key records **what `sc` was last told to do**, while the
init system records **what will actually happen at boot**. They can disagree: an `enable` that
failed (`check=False` swallows it), a unit file changed by `install.sh` or by hand, an OpenRC
runlevel edited outside `sc`, or a settings file restored from a backup. A diagnostic must report the
authority, because the disagreement is itself the defect worth seeing; reading the settings key would
make `doctor` echo `sc`'s intention back at the user and report "enabled" on a host that will boot
without the service. This is written down (and in `docs/dev-map.md`) precisely so nobody later
"fixes" S4 toward the settings key. The `.harness/rejected-decisions.md` records and the F.6 doc-size
WARN are PM-ruled and needed no action from me beyond noting them here.

---

## 5b. Stage 4b — the fix-up round (M-2 code, M-1 answer)

### 5b.1 M-2 — the dangling header, fixed on the PM's ruling

**What was wrong.** At `bin/sc:1343-1352` (pre-fix numbering) S3 appended the header row
`the checker reported an error:` *before* computing `lines`. When the checker exits non-zero but its
merged stdout+stderr is empty or blank-only, `lines` is `[]`, both loops are skipped and the report
ends that section with a colon and nothing under it.

**The ruling I implemented (PM, stage 4b), recorded because it is the reason the change exists.**
The reviewer filed this MINOR/optional; the PM ruled it be fixed. Rationale: *this project's standing
discipline since T-01 is that a tool always states its outcome, and a diagnostic whose whole purpose
is honest reporting must not emit a header promising detail and then print nothing — least of all on
the broken host it exists for.*

**The change** (`bin/sc:1345-1356`, entirely inside `_doctor_config()`):

- `lines` is now computed **before** any row is appended.
- `if not lines:` appends one PROBLEM row — `the checker reported an error, no message (exit {code})`
  — and returns. The exit code is the only fact this path has, so it is the fact the row carries.
- The non-empty path is byte-for-byte what it was: same header row, same 5-line window, same
  `... {n} more line(s) not shown` marker.

Constraints honoured, each checked: outcome class still `DOCTOR_PROBLEM` and the run still exits **1**
(asserted in all four new fixtures); **no new helper and no new constant**; `_doctor_print()` untouched
(gate F-14); nothing outside `_doctor_config()` and the zh table changed; the row is **76 columns**
in en and 41 in zh, inside AC-24's 80. The one new key
`"the checker reported an error, no message (exit {code})"` is readable English prose (AC-19), has the
zh entry `检查器报告了错误，未输出信息（退出码 {code}）` with the **identical** placeholder set `{code}`
(machine-checked: zero placeholder mismatches across all 108 zh keys), and contains no `失败` —
verified the non-self-violating way, by grepping the **rendered zh report**, not the source.

**Executed test for exactly this path** — `t_doctor.py` section E2, four fixtures
(`exit 3` with empty stdout, and `printf '   \n\n\t\n'; exit 4` for blank-only) × (`en`, `zh`),
10 assertions each, **40 new PASS, 0 FAIL**. Each fixture asserts: exactly one S3 check row; it is
class PROBLEM; it carries the checker's exit code; **the row does not end in a colon** (neither `:`
nor `：`); the next physical line is the next section's `[`-marked row; **no indented quoted line
exists anywhere in the report**; exit status 1; the sandbox is byte-identical before and after; no CR
and no ESC. The zh fixtures add: no English key leaked, and no `失败` in the rendered output. The
en report for the silent checker, verbatim from the run:

```
[OK] configuration: /tmp/sc-doc-m2-silent-en-3d1t6bhr/etc-sing-box/config.json
[PROBLEM] sing-box check: the checker reported an error, no message (exit 3)
[UNKNOWN] service: no init system detected (neither systemd nor OpenRC)
```

**Regression re-run (nothing else moved).** `t_doctor.py` 88/88 (48 pre-existing + 40 new),
`t_unit.py` 26/26, `t_status.py` 8/8 (AC-16 HEAD-vs-tree still byte-identical, negative control still
fails as it must), `t_regress.py` 31/31 (incl. AC-18/19/20 parity over the enlarged table, AC-23's
3.6 parse and the `capture_output=` count still exactly **3**, at `:1020`, `:1065`, `:1685`),
`t_updrules.py` 13/13, `t_s4.py` real-systemd both languages with the witness unchanged. **0 failures
in 166 checks.** `t_risk1.py` was not re-run: it measures `sing-box check`'s side effects, which this
change cannot affect. Live-service witness re-read after every harness — unchanged (§1).

### 5b.2 M-1 — what `t_status.py` actually did, stated plainly

The reviewer is right that the stage-4 §5 C-4 write-up is internally inconsistent, and the omission is
mine. **The record left out three stubs.** `t_status.py`'s `capture_status()` sets, before every
capture (`t_status.py:62-68`):

```python
mod.SYSTEMD = False; mod.OPENRC = False        # the systemctl status block does not run
mod.LANG = lang; mod.CLASH_PORT = 29099
mod.is_running = lambda: True                  # <-- the stub the record omitted
mod.load_nodes = lambda: {"active": "LosAngeles-US", "nodes": [1]}
mod.clash_api = lambda *a, **k: {"mode": "rule"}
```

`is_running` is **replaced wholesale**, so `SYSTEMD = OPENRC = False` does not suppress the gate at
`bin/sc:1199` — it only suppresses the `systemctl status` subprocess at `:1193-1196`. The gate is
therefore taken, and the region `:1200-1212` (node, mode, port, the egress header and E-13's
`print(_egress_ip())`) **is** inside the compared capture. Two assertions in the same harness confirm
it from the bytes rather than from the reasoning: the capture contains the real `ip -br addr show`
output (`"sb-tun" in sample`, `t_status.py:114`) and the stubbed egress value
(`"203.0.113.7" in sample`, `:116`).

So the method's *assertions* were true and its *stated premises* were incomplete: it named
`SYSTEMD = OPENRC = False` and the `urlopen` stub, and silently dropped `is_running`, `load_nodes` and
`clash_api`. **What was not compared:** the `systemctl status` / `rc-service status` subprocess output
at `:1193-1196` — deliberately, as that is the volatile region (PID, elapsed time, five journal lines)
and the one the diff provably does not touch. Nothing else in `cmd_status` is outside the capture.

I am not claiming more than that: this is an in-process comparison of two module objects with four
attributes replaced, not a comparison of two installed `sc status` runs. QA owns the re-run and should
state the neutralisation as the five lines above.

---

## 6. RISK-1 / C-7 — the measurement and its verdict

**Question:** does `sing-box check -c <config>` write `/var/lib/sing-box/cache.db`?

**How it was measured, safely.** The installed `/etc/sing-box/config.json` is root-only (mode 0600)
and was never passed to the checker — doing so would aim the experiment at the live cache file while
the service holds it. Instead: a config **copy in a temp dir**, same shape as `generate_config()`
emits (`experimental.cache_file = {enabled: true, path: …, store_fakeip: false}` plus a loopback
`clash_api`), with the cache path redirected **into that temp dir**, so the only file the checker
could create or modify is one the harness owns. Two arms, matching `02_` §14 T-1:

| Arm | Setup | Result |
|---|---|---|
| A | declared cache file **absent** | `check` exits 0 and the file is **still absent**; no other file appeared in the directory |
| B | declared cache file **exists** with known bytes and mtime 0 | byte-identical afterwards — size, `st_mtime_ns` and sha256 all unchanged |
| control | the live `/var/lib/sing-box/cache.db` | fingerprint identical before and after the whole experiment |

**Verdict: RISK-1 does not materialise on this host.** `sing-box check -c` neither creates nor
modifies the cache file it is told about. The design's prediction is **confirmed by measurement**,
so §3.8's contingency is not needed and FR-4 is not amended.

**Honest scope of that claim** (QA should re-run T-1 against the real installed config as root):
measured on **sing-box 1.13.15** only; on a *shape-equivalent copy*, not the installed config itself
(unreadable to me); and the enumeration of side effects covers the config's own directory plus the
live cache file — files the checker might write elsewhere (`$HOME`, `/tmp`) were not enumerated.
AC-5's fresh-host half is immune either way: with no config, S3 short-circuits and never invokes the
checker.

---

## 7. What was executed (171 checks, 0 failures)

Seven harnesses in `scratchpad/`, all sandboxed (paths repointed after import), all offline except
one deliberate real egress query. Handing them to QA is the intent; they need no root.

| Harness | PASS | Covers |
|---|---|---|
| `t_unit.py` | 26 | C-2 merge; D-2 tuple + extended contract incl. readable-empty → real `0`; AC-14; T-10 tag pairing; **AC-13/C-6 deletion test** |
| `t_doctor.py` | **88** | AC-3/4/5(sandbox)/8/9/11/12/17/18/20/21/22/24, BC-1/2/3/6/7/9/11/12/13/18, D-1, R-8 — **+40 in stage 4b for M-2** (§5b.1) |
| `t_status.py` | 8 | **AC-16 / C-4** incl. the negative control |
| `t_regress.py` | 31 | D-3 through `main()`, RISK-2/T-6 ×5, AC-7 (AST call graph), AC-15, AC-18/19/20, R-7, AC-23 |
| `t_updrules.py` | 13 | **T-9** (T-10 non-regression, offline `file://` mirror) + S4's remaining branches |
| `t_risk1.py` | 5 | RISK-1 / C-7 |
| `t_s4.py` | — | S4 against real systemd, both languages, with the MainPID witness |

**Total 171, 0 failures.** All but `t_risk1.py` (5, unaffected by the M-2 change) were re-run in
stage 4b: 166 checks, 0 failures.

Selected results worth naming:

- **AC-4 (the owner's failure chain reads off the screen):** on an empty-rules + config-referencing-
  missing-rule-sets + no-service fixture, one run printed four `[PROBLEM]` rule-set rows, then
  `[PROBLEM] sing-box check: the checker reported an error:` quoting the checker's own
  `parse rule-set[0]: open …/geoip-cn.srs: no such file or directory`, then the service rows —
  in that order, exit 1.
- **AC-12 streaming:** the S7 stub reads the capture *file* at the moment its probe starts and finds
  S1..S6 already there, in order. That is the per-row `flush=True` doing its job on a pipe.
- **AC-24:** healthy report 16 physical lines, fresh-host 15; widest doctor-composed row 78 columns.
- **AC-18/AC-20 under `lang zh`:** every section label, every class marker and every value rendered
  in Chinese; the `失败：` literal was rendered *at run time* from `t("failed: {e}")` and searched
  for in the zh output — absent (not a repository grep, which `insight-index.md:19` shows is
  self-violating); no English key leaked.
- **AC-23:** `ast.parse(src, feature_version=(3, 6))` succeeds; the diff adds no
  `capture_output=` / `text=` / walrus / f-string `=` / `missing_ok=` / `dataclasses`; the
  pre-existing 3.7+ sites are still exactly three.
- **NFR-2 data point:** a sandboxed run with a dead Clash port and a **real** egress query took
  **0.94 s** — the 3 s Clash bound is a ceiling, not a cost, because a closed loopback port refuses
  immediately. The design's ≤15 s claim is not contradicted; QA still owns the blackholed-network
  measurement.

### verify_all

| | PASS | WARN | FAIL | SKIP |
|---|---|---|---|---|
| Baseline (this work tree, before my edits) | 16 | 1 | 0 | 1 |
| After changes (stage 4) | 16 | 1 | 0 | 1 |
| Stage 4b baseline (before the M-2 fix) | 16 | 1 | 0 | 1 |
| Stage 4b after the M-2 fix + this record | 16 | 1 | 0 | 1 |

**Delta: zero.** The single WARN is F.6 "Active task docs <=500 lines each", caused by `02_`'s 858
lines — the PM-ruled, predicted, accepted delta. (The PM's stated 17/0/0/1 was the pre-task baseline;
the WARN had already converted one PASS before I started, which is why my baseline reads 16/1.) This
document is kept under the cap so it cannot add a second.

---

## 8. Dev-map updates

- `# Paths` row gains `TUN_IFACE`.
- `ruleset_state(path)` row → `(status, digest, size)` with the extended contract
  `size is None ⇔ digest is None`, and "never `st_size`".
- `ruleset_report()` row → `ruleset_states()` yields 5-tuples; `_status_view()` named as the shield
  that keeps `generate_config()` / `usable_tags()` / `_warn_degraded()` on 3-tuples.
- Four **new** reusable-utility rows: `TUN_IFACE`, `_egress_ip()`, `_saved_clash_port()`, `_plain()`.
- `# Clash API` row: the new `port=` parameter and who passes it.
- `# Commands` row: the doctor block's contents.
- `main()` row: parses arguments before initialising; `doctor` is the one read-only arm.
- "Patterns to avoid": don't give `doctor` a second opinion; don't add a per-subcommand read-only
  flag; and neutralise the *sudo re-exec* specifically (see the insight below).

---

## 9. Deviations from the design — `DESIGN DRIFT` (four, all additive and minor)

1. **`DESIGN DRIFT` — one translation key beyond `02_` §10's table:**
   `"not in the default runlevel"` / `不在 default 运行级别`. §6's S4 row specifies the value
   `not enabled ({state})` for both init systems, but supplies a `{state}` source only for systemd
   (`is-enabled`'s output word). OpenRC's "absent from `rc-update show default`" has no state word to
   quote; the alternatives were to interpolate an untranslated English phrase (breaks BC-18) or a
   meaningless token. The key carries no placeholder, has a zh entry, contains no `失败`, and is
   covered by the executed parity check.
2. **`DESIGN DRIFT` — one helper beyond §5.1:** `_first_line(text)`, used by S1 and S4. Two call
   sites of the same loop; it forms no judgment. `_doctor_print()`'s single-caller status (gate F-14)
   is unchanged — it did not grow a parameter or a mode.
3. **Minor wording, not behaviour:** `_doctor_run`'s docstring originally said "never
   `capture_output=` or `text=`" — the literal tokens made a naive occurrence count read **4**
   instead of 3, which is exactly the gate a reviewer or QA runs. Reworded to "never the 3.7-only
   convenience keywords". No call site changed.
4. **`DESIGN DRIFT` (stage 4b, PM-ordered) — a second translation key beyond `02_` §10's table and a
   branch beyond §6's S3 row:** `"the checker reported an error, no message (exit {code})"` /
   `检查器报告了错误，未输出信息（退出码 {code}）`. `02_` §6's S3 row specifies one PROBLEM value for a
   failing checker and assumes the checker says *something*; it has no value for "non-zero, silent".
   The PM ruled the gap be closed in code rather than routed back (§5b.1). Additive only: same class,
   same exit status, same row shape, no new helper, no new constant, no new status vocabulary
   (FR-11 untouched); placeholder parity and the `失败` prohibition machine-checked. The reviewer's
   M-2 is thereby closed.

Also worth flagging for review, though not drift: **S3 quotes only non-blank checker lines**, so
BC-7's "how many lines were dropped" counts non-blank lines. And on a host with a Chinese-locale
`systemctl`, S4's `{state}` is foreign text that could in principle contain `失败` — outside this
task's control (the design assumes foreign text is English on supported paths), and no such string
originates in `bin/sc`.

---

## 10. Open issues for review / for QA

1. **AC-5 proper (root, live tree) is QA's.** I verified read-only behaviour against *sandboxed*
   copies of `/etc/sing-box` and `/var/lib/sing-box` (byte/mtime/mode/sha256 snapshots, both the
   populated and the never-created case) because the live tree is root-only. The AST call-graph
   check bounds the risk: no writer is even named inside `doctor`.
2. **AC-6 on the real command.** I never invoked the installed `sc doctor`; the equivalent probes
   were driven in-process, and the MainPID/ActiveEnterTimestamp witness is unchanged. QA should run
   the installed binary once as root with the same witness.
3. **BC-17 stands unchanged:** as non-root `./bin/sc doctor` re-execs the *installed* `sc`, which on
   a not-yet-upgraded host answers `invalid choice: 'doctor'` (gate Q-2). Expected, not a defect.
4. **F-11/F-12/F-13 residuals** (gate INFO) are untouched by design: `is_running()`'s OpenRC branch
   still uses `capture_output=` (3.7+, separate pool row) and would surface as one UNKNOWN row on a
   3.6 OpenRC host; a read-phase `socket.timeout` in `clash_api()` reaches the driver backstop rather
   than S6's PROBLEM row; `_doctor_print` runs outside the per-probe `try`.
5. **NFR-2's blackholed-network measurement** (T-4) still needs a host QA can blackhole.
6. **AC-16 re-run (M-1) is QA's**, with the neutralisation stated as §5b.2 gives it — five replaced
   module attributes, of which `is_running = lambda: True` is the one that makes the egress region
   reachable, and the `systemctl status` subprocess is the one region deliberately outside the
   capture. Take the five lines, not the stage-4 prose.
7. **I-2 (reviewer):** S3 quotes the external checker verbatim into a report meant for pasting. The
   M-2 fix does not change that channel — the new row quotes nothing, only an exit code, so it is
   strictly *less* exposed than the quoting path. QA still owes the one-time eyeball of a real
   failing-config message before the report is called safe to paste.

---

## 11. Insight to surface

`sing-box check -c` (v1.13.15) neither creates nor modifies the `experimental.cache_file` database it is told about — measured on a temp-dir copy, both with the file absent and with it pre-existing · evidence: sc-doctor `04_DEVELOPMENT.md` §6

A second candidate, lower value, offered only if the index has room: a test harness that neutralises `bin/sc`'s auto-elevate must strip the *sudo re-exec specifically* — a blanket "no `os.execvp`" assertion refuses to load a healthy file, because `cmd_uninstall` legitimately execs `bash` (`bin/sc:1768`).

---

## 12. Verdict

**READY FOR REVIEW** — stage 4b closed M-2 (code + 40 executed assertions), M-3 (a/b/c re-measured
from `git`) and M-1 (answered in §5b.2, not overstated). `verify_all` 16/1/0/1, unchanged.

---

## 13. Stage 4c — DEF-1 fixed (whole-CSI stripping in `_plain()`)

**One defect, one function.** `_plain()` (`bin/sc:1236`) now removes a **complete** CSI sequence
(ESC `[` · params `0x30-0x3F` · intermediates `0x20-0x2F` · final `0x40-0x7E`) instead of the ESC
byte alone. Nothing else moved: no new helper, constant or call site, no `_doctor_print` change
(F-14 intact), no new translation key, no timeout constant touched. DEF-2 untouched, as instructed.

**Real-binary measurement** (read-only, temp-dir copy; never the live config or service).
`/usr/local/bin/sing-box` 1.13.15, `check -c <temp cfg, missing .srs>`, `stdout=PIPE`:
`raw[:70] = b'\x1b[31mFATAL\x1b[0m[0000] initialize router: parse rule-set[0]: open /tmp/d'`
— 2 × `0x1B`. QA's finding reproduced independently: sing-box colours into a pipe.

```
before  [31mFATAL[0m[0000] initialize router: parse rule-set[0]: open …/geoip-cn.srs: no such file or directory
after   FATAL[0000] initialize router: parse rule-set[0]: open …/geoip-cn.srs: no such file or directory
```

Re-measured through the **product's own** `_doctor_run()`+`_plain()` on the real binary: 0 × `0x1B`,
0 × `0x0D`, and both `[0000]` (logrus' elapsed-time field) and `rule-set[0]` survive intact.

**Decision — hand-scanned; `re` rejected.** `re` is still not imported: importing it would put part
of the fix *outside* `_plain()` and add an import to delete a colour code, which is what `02_` §3.6
D-6 declined. Rejected alternative: `NO_COLOR=1` on the checker — cheaper, but it changes call
sites, trusts every future tool to honour the variable, and leaves `_plain()` wrong for the next
one. **Only a complete sequence is removed**, so no legitimate text can be eaten; anything that does
not parse as one loses just its ESC (HEAD's behaviour). **Other escape forms are deliberately not
handled** — OSC (`ESC ] … BEL`/`ST`) and charset selection have never been observed from these tools
and each needs its own terminator grammar (rule 85's counter-rule). AC-17 holds on every path.

**Byte-identity for ESC-free rows:** the function early-returns `text.replace("\r","").rstrip()`
when `"\x1b" not in text`; 12 fixed strings + **20 000** random ESC-free inputs compare equal to
HEAD's implementation. 50 assertions, 0 failures.

**Verification.** QA's harness re-run verbatim: 36·183·17·25·276·12·64·12·45·16 = **686 PASS**; the
only 2 failures are `q9`'s pinned copies of the old diffstat literals, superseded below.
`verify_all` **PASS 16 / WARN 1 / FAIL 0 / SKIP 1**, identical to the pre-fix baseline (WARN = the
predicted F.6). `capture_output=` still exactly 3 (`:1020`, `:1065`, `:1719` — the third only
shifted); `ast.parse(feature_version=(3,6))` OK; `git diff --quiet -- install.sh uninstall.sh
systemd/` → **0**. Live service before **and** after: `MainPID=2500438`,
`ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST`.

**Authoritative diffstat (supersedes §3 and `06_`):** `5 files changed, 573 insertions(+), 43
deletions(-)`; `git diff --numstat -- bin/sc` → `491  37`. **Verdict: READY FOR REVIEW.**
