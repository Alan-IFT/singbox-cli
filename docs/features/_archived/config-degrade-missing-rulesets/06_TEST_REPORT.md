# 06 — Test Report — config-degrade-missing-rulesets (T-02)

- **Task**: T-02 · **Mode**: full · **Date**: 2026-07-31 · deferred-human (no questions asked)
- **Upstream**: `05_CODE_REVIEW.md` = `APPROVED` (0 CRITICAL, 0 MAJOR, 6 MINOR, 8 NIT)
- **Verdict**: ~~**`ROLLBACK: developer`** — 1 MAJOR defect (D-1)~~ — **superseded**: D-1 is closed by
  Amendment A-1/A-2 and re-verified below. **Current verdict: `PASS`** (see `## Re-test — A-1 / A-2`).

> **Harness**: written from scratch by QA against `01`'s acceptance criteria, **not** copied from
> `04_DEVELOPMENT.md`'s test code. Lives at `<scratchpad>/qa/` (8 files, 563 assertions).
> The developer's `<scratchpad>/check.py` was read but **not executed and not reused** — an
> independent reproducer is the point of this stage.

---

## 1. Environment and what was actually executed

| Fact | Value |
|---|---|
| Host | Ubuntu, `Linux 6.8.0-136-generic`, Python **3.12.3**, euid **1000** (non-root) |
| `sing-box` | **real binary** `/usr/local/bin/sing-box` **1.13.15** — AC-7 executed for real |
| Network | **available** — AC-27 and F-7 executed for real, not deferred |
| Restricted-network VM | **none** — all mirror behaviour driven by local `http.server` stubs (as mandated) |
| Module loading | `02` §13 recipe re-derived: replace the single `os.execvp("sudo", …)` line with `pass`, `exec(compile(...))`, repoint `CFG_DIR`/`CFG_PATH`/`NODES_PATH`/`SETTINGS_PATH`/`RULES_DIR` at a tmpdir |

**F-3 (binding) — technique used: BOTH layers.**
1. `mod.SYSTEMD = mod.OPENRC = False` immediately after `exec` (in `qalib.load_sc`), and
2. a PATH-prepended stub directory containing `systemctl` and `rc-service` shims that **append to a
   marker file** on any invocation.
Every test file asserts the marker does not exist at the end. It never did, in any of the 3 stability
runs. **This box's real sing-box service was never touched.** (Layer 2 exists because layer 1 alone
would not catch a code path that shelled out without consulting the module globals.)

**F-5 (binding) — AC-20's stale-temp PID.** The dead PID is `/proc/sys/kernel/pid_max` (an
*exclusive* upper bound, so it is never allocated). The harness asserts `os.kill(pid, 0)` raises
`ProcessLookupError` **before** using it, so the fixture cannot be flaky by construction.

**AC-16 fixture constraint (developer's finding) — honoured.** The progress body is **200 000 bytes**
(> 64 KiB). A 404-byte control body is run alongside to confirm the stated `http.client` behaviour.

---

## 2. verify_all — re-run by QA, not inherited

```
$ bash .harness/scripts/verify_all.sh
[A.1] PASS  [A.2] PASS  [B.1] PASS  [B.2] SKIP  [B.3] SKIP
[E.1..E.6] PASS x6      [F.1..F.6] PASS x6
=== Summary ===   PASS: 16   WARN: 0   FAIL: 0   SKIP: 2      exit 0
```

| | PASS | WARN | FAIL | SKIP | exit |
|---|---|---|---|---|---|
| Baseline (`04_DEVELOPMENT.md`, pre-edit) | 16 | 0 | 0 | 2 | 0 |
| Developer-reported (post-edit) | 16 | 0 | 0 | 2 | 0 |
| **QA re-run (this document)** | **16** | **0** | **0** | **2** | **0** |

**Delta vs baseline: 0.** No FAIL, no new WARN, nothing weakened. `B.2`/`B.3` remain `SKIP` by
adjudicated decision (Q8 / `.harness/rejected-decisions.md`); rule 50's "first task adding a
build/test command replaces the SKIP" is not triggered because no command was added.
The gate's prediction that `F.6` would WARN did not materialise — `02_SOLUTION_DESIGN.md` measures
500 lines (`wc -l` counts newlines; the last line has none), exactly at the cap. **Verified: 500.**

**`baseline.json` not updated.** It records `test_count: 0` and this task deliberately commits no
tests (Q8). The committed test count did not increase, so the baseline stays where it is; raising it
would assert a coverage this repo does not yet have. T-07 owns that change.

---

## 3. Test plan — every acceptance criterion mapped to an executed test

| AC | Test case(s) | File |
|---|---|---|
| AC-1 | `verify_all` re-run + `py_compile bin/sc` | §2, `t4_static_and_cmds.py` |
| AC-2 | 8 fixture kinds × (status, nothing raised, directory unchanged) + floor boundary at 15/16 | `t1_judgment_config.py` |
| AC-3 | config vs `git show main:bin/sc`'s own `generate_config()`, byte compare | `t1_judgment_config.py` |
| AC-4 | 16 masks: `defined == usable`; + explicit google-only-unusable case vs baseline rules | `t1_judgment_config.py` |
| AC-5 | 16 masks: core sections byte-identical; mask 0 deletes the `rule_set` key | `t1_judgment_config.py` |
| AC-6 | 16 masks: `referenced ⊆ defined` over `dns.rules ∪ route.rules` (**and** `referenced == usable`, so no over-deletion) | `t1_judgment_config.py` |
| AC-7 | 16 masks × **real** `sing-box 1.13.15 check` with **real** `.srs` payloads | `t1b_singbox_check.py` |
| AC-8 | 0 / 1 / 3 / 4 unusable, en + zh, single-line, `⚠️` prefix, `tag (phrase)` naming | `t1_judgment_config.py` |
| AC-9 | `cmd_add` on a 4/4-degraded config: exit 0, normal result line, warning on stderr | `t4_static_and_cmds.py` |
| AC-10 | stub base 1 = HTML 200, base 2 = valid; bytes, temps, request counts, **output clause** | `t2_download.py`, `t2b_repro_silent_fallback.py` |
| AC-11 | base 1 = connection-refused, base 2 = 404, base 3 = valid; **output clause** | `t2_download.py`, `t2b` |
| AC-12 | stub request log: failed base = 1 hit for the whole run, good base = 4 | `t2_download.py` |
| AC-13 | all bases fail: exit≠0, causes on stdout, aggregate alone on stderr, good file hash | `t2_download.py` |
| AC-14 | AST extractor over all 67 `t()` call sites + runtime format pass in en and zh | `t4_static_and_cmds.py` |
| AC-15 | real pipe, byte-level `b"\r" not in`, `b"\x1b" not in`, one `↓` line per rule-set | `t3_tty_conc_recovery.py` |
| AC-16 | `pty.openpty()`, 200 000-byte body, ≥2 increasing states with a percentage | `t3_tty_conc_recovery.py` |
| AC-17 | PTY + HTTP/1.0 close-delimited body: bytes only, no `%`, still succeeds | `t3_tty_conc_recovery.py` |
| AC-18 | over-declared `Content-Length`; and single-base variant so the cause is printed | `t2_download.py`, `t2b` |
| AC-19 | 2 real subprocesses vs a **threaded** slow stub, 200 KB bodies | `t3_tty_conc_recovery.py` |
| AC-20 | 4 stale shapes (legacy, dead-pid, non-integer, `.tmp.0`) + 1 live-pid temp | `t2_download.py` |
| AC-21 | `--mirror` vs `SB_RULES_BASE`, each alone, whitespace-only, whitespace-split, trailing slash, malformed scheme | `t2_download.py` |
| AC-22 | degraded config + **sentinel key** → regenerated (sentinel gone); empty dir → no config | `t3_tty_conc_recovery.py` |
| AC-23 | all-usable → 0; one still unusable → 1 | `t2_download.py` |
| AC-24 | `HELP_EN`/`HELP_ZH` + both READMEs, matching line positions, `env_reset` caveat | `t4_static_and_cmds.py` |
| AC-25 | **real `git` byte diff** — see §4 | shell |
| AC-26 | 9 banned-construct regexes over the 346 added lines of `bin/sc` | `t4_static_and_cmds.py` |
| AC-27 | real fetch from **each of the 4 bases** + a real default-list `update-rules` run | shell, `t5_timeout_bc17_e2e.py` |

Boundary conditions additionally executed: **BC-1..BC-6, BC-8, BC-9, BC-11, BC-12 (real 30 s socket
timeout), BC-14, BC-15, BC-17, BC-18, BC-19, BC-20, BC-21, BC-22, BC-23, BC-24, BC-26, BC-27,
BC-28, BC-30**, plus F-1, F-4, F-6, F-8.

---

## 4. AC-25 — evaluated with a real byte diff (the reviewer could not run this)

Per gate F-9, the scope assertion is evaluated against the **product** diff only.

```
$ git diff --name-only -- . ':(exclude).harness/**' ':(exclude)docs/**'
CHANGELOG.md
README.md
README.zh-CN.md
bin/sc
```

Load-bearing half, asserted strictly by SHA-256 against `main` (**not** by inspection):

```
IDENTICAL install.sh                          4773b88f75b80d94...
IDENTICAL uninstall.sh                        9bf90dde3cd9170f...
IDENTICAL systemd/sing-box.service            e5649b1d5d8659ac...
IDENTICAL systemd/sing-box-rules-update.service 3bb5daad84d872e9...
IDENTICAL systemd/sing-box-rules-update.timer b933b8009853b824...
```
`git ls-tree main systemd/` and `ls systemd/` agree on the file set — no unit added or removed.

Timeout constants — `grep -n timeout` on both revisions:

| | `main` | worktree |
|---|---|---|
| Clash API | `:583 timeout=3` | `:852 timeout=3` |
| Egress IP | `:742 timeout=8` | `:1011 timeout=8` |
| Ruleset download | `:812 timeout=30` | `:674 timeout=30` |

**Three constants, three values, unchanged.** `.harness/rejected-decisions.md`, `docs/dev-map.md`,
`docs/tasks.md` and `docs/features/**` are harness bookkeeping, excluded per F-9. **AC-25 PASS.**

---

## Adversarial tests (section 5 — one predicted failure per acceptance criterion)

Each row: an independent reproducer I wrote, the failure I predicted **before** running it, and the
outcome with real tool output. Verdict is based on whether the implementation survived *these*, not
on whether the developer's tests pass.

| AC | Hypothesis ("I expect failure when…") | Reproducer (all NEW, QA-authored) | Outcome |
|---|---|---|---|
| AC-2 | a directory or a `chmod 000` file makes `stat()`/`open()` raise **out of** `ruleset_status` — the `except OSError` sits after `is_file()` | `t1` 8 fixtures × 3 assertions, dir listing snapshotted before/after | **Survived.** All 8 tokens exact, nothing raised, `(mode,size,mtime_ns)` listing unchanged. euid 1000, so mode-000 is genuinely unreadable |
| AC-3 | a byte difference: the literal `rule_set` list became a comprehension | `t1` loads `git show main:bin/sc` as a second module, same nodes, `RULES_DIR` normalised | **Survived. Byte-identical.** stderr also empty |
| AC-4/6 | a dangling tag survives in `dns.rules` — the brief originally forgot that array | `t1` 16 masks, `referenced ⊆ defined` **and** `referenced == usable` | **Survived**, 16/16, both directions |
| AC-5 | core sections drift when the `rule_set` key is deleted | `t1` `json.dumps(core, sort_keys=True)` compared across all 16 masks | **Survived**, 16/16 |
| AC-7 | mask 0 (**no** `rule_set` key at all) is rejected — design R2, never executed by anyone | `t1b`, real `sing-box 1.13.15`, real `.srs` payloads | **Survived.** `mask -> rc: [(0,0),(1,0)…(15,0)]` — **R2 closed** |
| AC-8 | "no-splitting" wording leaks into the 3/4 case; HTML-on-disk indistinguishable from missing | `t1` warn capture at 0/1/3/4, en + zh | **Survived.** `4/4 … (geoip-cn (not a rule-set file), geosite-cn (missing), …)`; `no-splitting` present only at 4/4 |
| AC-9 | `sc add` exits non-zero or prints a failure on a degraded config | `t4` `cmd_add` with a real share link, 0 usable rule-sets | **Survived.** stdout `Added: qa-node (vless → 1.2.3.4:443)`, exit 0, warning on **stderr** only |
| **AC-10** | the HTML page reaches disk (200 + correct `Content-Length`), or the run aborts instead of trying base 2 | `t2b_repro_silent_fallback.py` | **Partly FAILED.** Rejection + fallthrough + atomicity all hold, but **base 1's failure never appears in the output** → **D-1**. *(**Now PASS** after A-1 — re-test §R)* |
| **AC-11** | the 404 base aborts the run | `t2b` (refused → 404 → valid) | **Partly FAILED.** Correct file installed from base 3, but the output names **neither** failing base → **D-1**. *(**Now PASS** after A-1 — re-test §R)* |
| AC-12 | a dead-marked base is retried for the later files | `t2` stub request log | **Survived.** failing base = 1 hit, good base = 4 |
| AC-13 | the pre-existing good file is clobbered; aggregate leaks to stdout | `t2` all-fail run, sha256 before/after, streams captured separately | **Survived.** hash identical; stderr is exactly `4 ruleset(s) failed to update`; `failed:` only on stdout |
| AC-14 | a zh string carries a placeholder the call site never supplies → runtime `KeyError` | `t4` AST extractor over **67** call sites / **62** keys + runtime format pass | **Survived.** 62/62 zh entries, 0 placeholder mismatches, 0 kwarg gaps, 0 orphan keys |
| AC-15 | a `\r` survives into the redirected stream | `t3` real pipe, 200 KB body, byte-level | **Survived.** no `\r`, no `\x1b`, exactly 4 `↓` lines |
| AC-16 | 0 or 1 intermediate state — a local stub is too fast and `read(65536)` blocks | `t3` PTY + 200 000-byte body | **Survived.** per file: `65536/200000 (32%) → 131072 (65%) → 196608 (98%) → 200000 (100%)` |
| AC-17 | `ZeroDivisionError` or a bogus `0%` when no length is declared | `t3` PTY + HTTP/1.0 close-delimited | **Survived.** raw byte counts, zero `%` renders, no traceback |
| AC-18 | the truncated body is installed (server closes the connection mid-stream) | `t2` + single-base variant | **Survived.** `truncated: got 21839 of 26839 bytes`, real path untouched |
| AC-19 | one run unlinks the other's in-flight temp | `t3` 2 real subprocesses vs a **threaded** slow stub | **Survived.** both exit 0, all 4 files complete, 0 temp debris |
| AC-20 | a dead-pid temp survives, or a legacy `<name>.tmp` is counted as a rule-set | `t2` 4 stale shapes + 1 live-pid temp, PID = `pid_max` | **Survived.** all 4 removed, live-pid temp spared, report only ever names the 4 rule-sets |
| AC-21 | `SB_RULES_BASE` beats `--mirror`; whitespace-only wipes the list | `t2` 5 runs with request-logging stubs | **Survived.** env base got **0** hits; whitespace-only fell back to the built-ins; `ftp://` failed all four with **no** silent fallback |
| AC-22 | the config is patched, or left degraded | `t3` injects a `__qa_sentinel__` key into the degraded config first | **Survived.** sentinel **gone** ⇒ regenerated, not patched; all 4 tags + their rules back in both arrays |
| AC-23 | exit 0 despite a still-unusable rule-set | `t2` all-good vs one-404 (last file, so dead-marking cannot cascade) | **Survived.** 0 and 1 |
| AC-24 | one language block is missing the new surface | `t4` on `HELP_EN`/`HELP_ZH` + both READMEs | **Survived.** `--mirror` at line 107 in **both** READMEs; `env_reset` caveat in both |
| AC-25 | a stray `install.sh` / `systemd` edit | real `git` + `sha256sum` (§4) | **Survived** |
| AC-26 | a 3.7+/3.8+ API slipped into the 346 added lines | `t4` 9 regexes | **Survived.** no `capture_output=`, `text=True`, `missing_ok=`, walrus, dataclasses, f-string `=`, dict-merge |
| AC-27 | a path-layout typo in base 1/2/3 (gate F-7's concern) | `curl` × 4 bases × 2 files + a real default-list run | **Survived.** all 4 bases: HTTP 200, `magic=535253`, **identical sha256** per file, no `Content-Encoding` |

### Adversarial probes beyond the AC list

| Probe | Hypothesis | Outcome |
|---|---|---|
| **End-to-end, the reported failure** | fixed on paper only | **Survived, with side-by-side proof.** Same empty rules dir, same nodes: `main`'s `generate_config()` → `False` + `FATAL initialize router: parse rule-set[0]: open …/geoip-cn.srs: no such file or directory`; worktree → `True` under the **real** `sing-box`. Config keeps node outbounds, TUN, DNS servers, `dns.final`, `route.final: "proxy"`, and `sc add` on top exits 0 with `Added: second` |
| **BC-12 real socket timeout** | the run hangs, or pays 4×30 s | **Survived.** A base that accepts and never answers: whole run **30.1 s**, then base 2 served all four. Timeout constant untouched; dead-marking caps the penalty at 1× |
| **BC-17 good file + all mirrors fail** | the config degrades anyway | **Survived.** All 4 hashes unchanged, `config.json` **string-identical** to before, **no** warning emitted, all 4 still `usable` |
| **BC-18 disk-full surrogate** (read-only `RULES_DIR`) | unhandled traceback, or the good file is damaged | **Survived.** No traceback, exit 1, good file byte-identical, no debris, all 4 files still attempted. *(Cause text names the mirror for a local fault — see D-4)* |
| **F-1 short first read** | 1-byte first `read()` ⇒ false `bad-magic` | **Survived.** magic accumulated across chunks |
| **F-4 garbage `Content-Length`** | crash, or the base is wrongly marked dead | **Survived.** `Content-Length: not-a-number` → BC-14 path, `OK`, base got all 4 requests |
| **F-6 gzip body** | silent corruption on disk | **Survived, signature recorded.** See §7 |
| **F-8 install re-run** | undocumented restart behaviour | **Confirmed as designed.** See §7 |
| **B-5 mixed/other-matcher branches** (dead against today's config) | wrong survivor set | **Survived.** 9 unit cases: partial-tag retention preserves order; answer-key-only rule dropped; other-matcher rule keeps the rule and drops the reference; no-`rule_set` rule passed through by **identity** |

---

## 6. Defects found

### D-1 · **MAJOR** · **[CLOSED — fixed by Amendment A-1, re-verified in §R]** · A mirror failure is silently discarded when a later base succeeds

**AC-11 fails on its criterion text; AC-10 fails on its stated verification method.**

- AC-11 criterion, verbatim: *"…base 3's content is installed **and the output names bases 1 and 2
  with distinct causes**."*
- AC-10 check, verbatim: *"…**assert the failure of base 1 appears in the output**."*

`bin/sc:1086-1108`: `causes` is appended to inside `except`, but the success path does
`print(t("OK ({size} bytes)", size=got)); break` and the accumulated `causes` list is dropped. The
enumeration is only ever printed in the `for…else` total-failure branch (`:1105-1108`).

**Reproducer** (`<scratchpad>/qa/t2b_repro_silent_fallback.py`, deterministic across 3 runs):
base 1 = HTTP 200 `text/html` error page, base 2 = valid fixtures.

```
STDOUT:
  ↓ geoip-cn.srs ... OK (21839 bytes)
  ↓ geosite-cn.srs ... OK (450045 bytes)
  ↓ geosite-google.srs ... OK (7916 bytes)
  ↓ geosite-private.srs ... OK (696 bytes)
Done

STDERR:
(empty)

base1 (HTML) hit count: 1   base2 hit count: 4
ASSERT-FAIL: AC-10 CLAUSE: base 1's failure appears in the output
ASSERT-FAIL: AC-11 CLAUSE: output names bases 1 and 2 with distinct causes
```

The rejection itself is correct — base 1 was tried exactly once, its HTML never reached disk, no temp
survived, base 2's bytes are exact. **Only the reporting is missing**, on both streams.

**Why it matters, not cosmetic.** Gate F-7's stated concern is precisely this: *"a path-layout typo in
base 1, 2 or 3 would ship undetected and only surface as a silent extra 30 s on a user's machine."*
As built, a dead or misconfigured mirror is invisible in `/var/log/sing-box/install.log` whenever any
later mirror works — which is the common case on the target network (jsDelivr blocked, `ghfast.top`
works). The Observability NFR (`01` §7: *"Base-by-base causes make a mirror-layout error
distinguishable from an unreachable network in `/var/log/sing-box/install.log`"*) is only honoured on
total failure. **The mainland-China user this task exists for gets no signal at all** that three of
four mirrors are unreachable.

**Provenance, so it is routed fairly.** `02_SOLUTION_DESIGN.md` §6.2's pseudocode already discards
`causes` on `break`, and `03_GATE_REVIEW.md` did not check AC-10/AC-11 against it. The developer
implemented the design faithfully. It is still a code change, and it is small.

**Suggested fix shape (developer's call).** Append the accumulated causes to the *same* completion
line, e.g. `OK (21839 bytes) [<base1> -> not a rule-set file]`, so:
- AC-15 / B-19 "exactly one completion line per rule-set" stays literally true (re-assert it);
- AC-3 / the NFR "unchanged when nothing is wrong" stays true (`causes` is empty in the happy path —
  QA re-verified that the all-usable non-TTY output is identical to `main`'s);
- the stdout/stderr split is untouched (it stays on stdout with the rest of the per-file cause text);
- a new `zh` entry may be needed — AC-14's extractor must be re-run.

**Regression tests to re-run after the fix:** AC-3, AC-10, AC-11, AC-13, AC-14, AC-15, AC-16, AC-21.

### D-2 · MINOR · `--mirror` crosses the sudo boundary, contradicting the security NFR
Confirmed independently of the reviewer: `bin/sc:77-78` re-execs `sudo … + sys.argv[1:]`, so
`--mirror` survives elevation while `SB_RULES_BASE` does not. `01` §7 says the override "is only
effective for a caller who is already root". `urllib` accepts `file://`, so
`--mirror file:///tmp/x` makes root copy `<dir>/geoip/cn.srs` into `/etc/sing-box/rules/`.
No privilege is gained (the same sudoers entry already permits `sc uninstall`). **Pool row, not a
change here** — a scheme allow-list would exceed B-14/BC-24 as written. *(Not re-executed as root:
this host runs QA at euid 1000. Marked **reasoned, not executed**.)*

### D-3 · MINOR · Dropping `rule_set` from a rule with another matcher **broadens** it
Executed, not inferred: `_filter_rules([{"action":"reject","network":["udp"],"rule_set":["a"]}], set())`
returns `[{"action":"reject","network":["udp"]}]` — a strictly wider reject. Dead against today's
config (all 7 rule-set rules are `{answer-key, rule_set}`) and mandated verbatim by B-5. The comment
at `bin/sc:579` should say the surviving rule matches **more**.

### D-4 · MINOR · A local disk fault is reported as a mirror failure, with a full temp path
BC-18 output, executed:
```
  ↓ geoip-cn.srs ... failed: http://127.0.0.1:33879/geo -> [Errno 13] Permission denied:
    '/tmp/qa-t4-…/rules/geoip-cn.srs.tmp.1829272'
  ↓ geosite-cn.srs ... failed: http://127.0.0.1:33879/geo -> skipped (this source already failed…)
```
The temp-creation `OSError` is caught by the same `except Exception` that marks the **base** dead, so
files 2-4 fast-fail with mirror-flavoured causes for what is a local-disk fault, and the internal
temp path leaks into `install.log`. BC-18's "the run continues with the remaining files" is still
literally true and this is Q6's sanctioned semantics. Note only.

### D-5 · NIT · Stray blank line in the recovery output
Executed capture: `…— config regenerated\n\n→ Restarting sing-box ...\n`. The `"\n"` was carried over
from `main`, where it separated the restart notice from the last completion line.

**No BLOCKER, no CRITICAL.** The user-observable failure this task exists to remove is gone —
proven side-by-side against `main` with the real `sing-box` binary (§5).

---

## 7. Records required by the gate conditions

**F-6 — gzip failure signature (for future diagnosability).** Executed against a stub serving
`Content-Encoding: gzip` over a valid body. `urllib` does not decode it, so the body fails the magic
check and the base is marked dead run-wide:
```
  ↓ geoip-cn.srs ... failed: http://127.0.0.1:37363/geo -> not a rule-set file
  ↓ geosite-cn.srs ... failed: http://127.0.0.1:37363/geo -> skipped (this source already failed in this run)
  … (exit 1, "4 ruleset(s) failed to update" on stderr)
```
**Signature: `not a rule-set file` from *every* mirror, with only 1 real request per base.** If that
is ever reported, suspect a proxying mirror that started compressing — not a corrupt upstream file.
Confirmed today that none of the four real bases sends `Content-Encoding` (§5, AC-27 row), and
`bin/sc:674` still sends a bare URL with no `Accept-Encoding` header.

**F-8 — double restart on an `install.sh` re-run.** Demonstrated, not assumed
(`t5`, `restart_service` instrumented, `is_running() → True`, config pre-existing):
```
F-8 restarts: step6 update-rules = 1  + step7 reload = 1     (2 total)
```
Fresh install (no config): `update-rules` performs **no** recovery, creates **no** config, and only
the ordinary BC-28 restart fires. Both restarts land in `LOG_SINK`; `install.sh` is byte-identical to
`main`. **Expected, recorded, not a defect.**

**F-7 / AC-27 — all four real bases fetched by hand** (`curl`, 2 files each):

| base | `geosite/private.srs` | `geoip/cn.srs` |
|---|---|---|
| `cdn.jsdelivr.net` | 200, 696 B, `535253`, sha `3c2a2cff…` | 200, 21899 B, sha `56f5edab…` |
| `testingcf.jsdelivr.net` | 200, 696 B, sha `3c2a2cff…` | 200, 21899 B, sha `56f5edab…` |
| `ghfast.top/…` | 200, 696 B, sha `3c2a2cff…` | 200, 21899 B, sha `56f5edab…` |
| `raw.githubusercontent.com` | 200, 696 B, sha `3c2a2cff…` | 200, 21899 B, sha `56f5edab…` |

**All four byte-identical, no path-layout typo, no `Content-Encoding`.** Smallest real rule-set is
`geosite-private.srs` at **696 bytes**, so `SRS_MIN_BYTES = 16` is 43× below it. **Q1's binding
constraint holds; F-7's residual risk is closed.**

**Q5 corollary, discovered by an over-strict QA fixture and worth keeping.** A synthetic
`b"SRS" + random` body is byte-valid under the model but semantically corrupt; the real `sing-box`
then rejects the config with `initialize router: parse rule-set[0]: zlib: invalid header`, and
`generate_config()` returns `False` with the failure on stderr — **exactly as today, no automatic
retry**. That is Q5(a) working as adjudicated, now with an executed example.

---

## 8. Stability

The full suite (8 files, **563 assertions**) was run **3 consecutive times**:

```
RUN 1   T1 230/0   T1b 44/0   T2 79/7   T2b 27/2   T3 44/0   T4 71/0   T5 45/0
RUN 2   T1 230/0   T1b 44/0   T2 79/7   T2b 27/2   T3 44/0   T4 71/0   T5 45/0
RUN 3   T1 230/0   T1b 44/0   T2 79/7   T2b 27/2   T3 44/0   T4 71/0   T5 45/0
```
(`T6` 14/0, run separately.) **Identical every run — zero flakes.** The 9 failures are all
deterministic manifestations of the single D-1 root cause: 5 in `T2`/`T2b` on the AC-10/AC-11 output
clauses, and 4 more where a rejected body's cause (truncated / zero-length) is likewise swallowed
because a later base succeeded. All 9 disappear when the failing base is the *only* base, which is
how `t2b` proves the causes themselves are correct and complete.

---

## 9. Unverified (stated honestly, not silently passed)

| Item | Why | Residual |
|---|---|---|
| **BC-25** — `SB_RULES_BASE` stripped by sudo's `env_reset` | QA runs at euid 1000 and `bin/sc`'s auto-elevate is neutralised to load the module at all; testing it needs a real root/sudoers host | Low. Both READMEs document it; `install.sh:437-441`'s `NOPASSWD:` rule with no `env_keep` is unchanged and was re-read |
| **AC-26 against a real 3.6 interpreter** | this box only has Python **3.12.3**; no 3.6 available | Low. 9 banned-construct regexes over the 346 added lines all clean; reviewer's construct-by-construct audit agrees |
| **D-2's `file://` escalation as a real sudo caller** | same root constraint | Low. Reasoned from `bin/sc:77-78`, not executed — labelled as such |
| **BC-32** — degradation warning landing in `install.log` | needs a real install run as root | Low. Stream routing verified directly (warning on stderr; `install.sh:479` merges `2>&1`, and `install.sh` is byte-identical to `main`) |
| **Restricted-network E2E** | out of scope (`01` §4.5); T-07 owns it | Carried to T-07 |

---

## 10. Handing the harness forward to T-07

**Recommendation: hand forward QA's `<scratchpad>/qa/` (8 files, 563 assertions), not the
developer's `check.py`.** QA's version was written from the ACs rather than from the implementation,
and it carries three things T-07 needs and cannot cheaply rebuild:

- `qalib.py` — the module loader with **both** F-3 layers (module globals *and* fail-loud PATH stubs
  with a marker file), fixture planting, and a pass/fail harness;
- `stubs.py` — 12 scripted mirror behaviours including `hang` (real 30 s socket timeout),
  `gzipbody` (F-6), `onebyte` (F-1), `truncated`, `badlength`, and a threaded variant for AC-19;
- `runner.py` — a real-subprocess driver, so `isatty()`, the exit status and the stdout/stderr split
  are genuine rather than simulated.

The developer's harness was **read but not executed**; its claims are all independently reproduced
above, and where its summary is thinner than the AC text (AC-11's "output names bases 1 and 2") the
gap is exactly D-1. That is the argument for QA's version being the one T-07 inherits.
This task still commits no tests (Q8, `.harness/rejected-decisions.md`), so `verify_all` B.2/B.3
stay `SKIP` and `baseline.json` stays at 0.

---

## Verdict

**`ROLLBACK: developer`** — D-1 (MAJOR): `cmd_update_rules` discards the accumulated per-base failure
causes when a later mirror succeeds (`bin/sc:1093-1097`), so **AC-11's criterion text** ("the output
names bases 1 and 2 with distinct causes") and **AC-10's stated check** ("assert the failure of base 1
appears in the output") both fail. Reproducer:
`python3 <scratchpad>/qa/t2b_repro_silent_fallback.py` — deterministic, 3/3 runs.

Everything else is green: 554 of 563 assertions pass, `verify_all` is `PASS: 16 / FAIL: 0` with a
zero delta, the diff scope and all three timeout constants are asserted with a real byte diff, the
reported production failure is proven gone side-by-side against `main` with the real `sing-box`
binary, and the four residual risks the gate carried into development (R2, F-6, F-7, Q1's floor) are
now **closed by execution** rather than deferred.


---

# §R · Re-test — A-1 / A-2 · **`PASS`**

2026-07-31, second QA pass, deferred-human. Scope: the architect's re-run list **plus the whole existing
harness**. Re-read `02` A-1 (revised §6.2/§5.3/§5.4/§9 R4,R8,R10) and A-2 (§5.4 key, R10 audit), `04`'s two
fix-pass sections, `05`'s delta review. **The developer's fix-pass tables were read but not reused**:
T7/T8/T9 were written from the amended AC text, and `t2b` (the original D-1 reproducer) re-run **unmodified**.

**F-3 — technique, and proof.** Both layers again: `mod.SYSTEMD = mod.OPENRC = False` in `qalib.load_sc`
**and** a PATH-prepended `systemctl`/`rc-service` stub dir that appends to a marker file. Every run is a
subprocess whose module is loaded with the auto-elevate line replaced by `pass` (`qalib` asserts that needle
occurs **exactly once**); no test executes `bin/sc` as a program and `/usr/local/bin/sc` is never named, so
the developer's accident cannot recur. After all 3 stability runs: `ls …/pathstubs/` → `rc-service systemctl`
(**no TOUCHED marker**); `systemctl show sing-box` → `NRestarts=0 ActiveState=active ActiveEnterTimestamp=Fri
2026-07-31 17:04:23 CST`, **unchanged** throughout (still the developer's 17:04 restart). **Nothing touched.**

## R.1 Suite delta — 554/563 → **846/846, 0 failed** (+283 assertions, 0 regressions)

| Suite | Rollback pass | Now |
|---|---|---|
| T1 / T1b / T3 / T4 / T5 / T6 | 230 / 44 / 44 / 71 / 45 / 14, 0 fail | identical, 0 fail (AC-13/15/16/17 did not move) |
| T2 · T2b (original reproducer, unmodified) | 79 / **7 fail** · 27 / **2 fail** | **86 / 0** · **29 / 0** — all 9 were D-1 |
| **T7** `t7_a1a2_delta.py` · **T8** `t8_tty_note.py` · **T9** `t9_dup_mirror.py` (all new) | — | **222 / 0** · **35 / 0** · **26 / 0** |

## R.2 The four things that had to be proven

**1 · D-1 closed on every rejection path.** T7/A: base 1 in each rejection mode, good base 2, cause asserted
on the *success* line of the file that hit it — transport error, 404, 500, truncation, body rejection (HTML /
empty / gzip), 7 of 7; the AC-11 line carries two **distinct** causes on **one** line; `t2b` now prints base
1's cause where it printed nothing. **AC-10/11/18 PASS.** Verbatim:
`  ↓ geoip-cn.srs ... OK (21899 bytes); fell back after: <b1> -> truncated: got 21899 of 26899 bytes`
`  ↓ geoip-cn.srs ... OK (21899 bytes); fell back after: <refused> -> <urlopen error [Errno 111] Connection refused>; <b2> -> HTTP Error 404: Not Found`
**2 · Dead-skip exclusion is real.** T7/B — base 1 = HTML always, base 2 good on file 1 then 404 on file 2,
base 3 good. File 2 names only the base it contacted, base 1 does **not** repeat, no `skipped` text on any
success line, files 3-4 **string-equal** to the plain form; hits b1=1, b2=2, b3=3. **No spam.**
`  ↓ geoip-cn.srs ... OK (21899 bytes); fell back after: <b1> -> not a rule-set file`
`  ↓ geosite-cn.srs ... OK (450045 bytes); fell back after: <b2> -> HTTP Error 404: Not Found`
`  ↓ geosite-google.srs ... OK (7916 bytes)` ← no note at all; file 4 idem
**3 · A-2.** Every zh fallback-*success* run (T7/C en+zh AC-10/11/18, T8, T9) asserts
`stdout.count("失败：") == 0` **and** `count("已失败") == 0` — neither the colon form nor the colon-less
dead-skip token reaches a success line; `前序镜像失败：` is absent from the tree. The zh total-failure run
asserts `count("失败：") == 4`, one per not-updated rule-set, with `已跳过（…已失败）` **only inside** those
lines. §9 R10's invariant ("dead-skips never enter `tried`") holds **in execution**, not just on paper:
`  ↓ geoip-cn.srs ... 成功（21899 字节）；已回退，前序镜像未成功：<b1> -> 不是规则集文件`
`  ↓ geosite-cn.srs ... 失败：<b1> -> 已跳过（该源在本次运行中已失败）; <b2> -> 已跳过（…）` [total-failure run]
**4 · AC-15 / streams.** With the note present, real pipe, en + zh: `b"\r" not in`, `b"\x1b" not in`, exactly
4 `↓` lines, note on exactly **one** physical line. stderr **empty** on every fallback-success run; on total
failure the aggregate (`4 ruleset(s) failed to update` / `4 个规则集更新失败`) is alone on stderr with **zero**
`↓` lines. On a real PTY (T8) the note survives the `\r`/`\033[K` redraws on the final visible line and is
terminated by `\n` before the next prefix — **§9 R4 confirmed by execution.**

## R.3 Guards that had to stay still

**AC-3**: T7/E runs *both* revisions as subprocesses against the same stub base — worktree with `--mirror`, `git show main:bin/sc`
with `RULESET_URLS` repointed (new `runner_main.py`) — comparing raw bytes: `eq(out_new, out_old)` and `eq(err_new, err_old)`
**pass** (`b'  \xe2\x86\x93 geoip-cn.srs ... OK (21899 bytes)\n…\nDone\n'`); T1's config byte-comparison vs `main`'s
`generate_config()` still passes; `tried` empty ⇒ note `""`. **AC-13/15/16/17** (T2, T3) and **AC-12/21/23** (T2) re-run, 0 fail,
same numbers. **AC-14** extractor: `68 t() call sites, 63 distinct keys, 63 zh entries`, 0 placeholder mismatches, 0 kwarg gaps, 0
orphan keys, 0 keys without a zh entry; `{causes}` in both languages, both render. **AC-25/26**: product diff still exactly
`bin/sc`, `CHANGELOG.md`, `README.md`, `README.zh-CN.md`; `install.sh`, `uninstall.sh` and all three unit files sha256-**IDENTICAL**
to `main`; timeouts still `30`/`3`/`8`; `CHANGELOG.md:7` quotes the shipping string.

## Adversarial tests (delta) — hypothesis stated before each run

| # | Hypothesis ("I expect failure when…") | Reproducer (NEW, QA-authored) | Outcome |
|---|---|---|---|
| 1 | A-1 was wired only into the branch D-1 named, so **truncation** / **validation** rejections are still swallowed | `t7` A, 7 modes × 2 bases, en + zh | **Survived.** All 7 named |
| 2 | `tried` is initialised outside the file loop, so file 2 inherits file 1's causes | `t7` B + `t2b` file-2..4 assertions | **Survived.** Files 3-4 string-equal to the plain `OK` form |
| 3 | A dead base's skip text leaks into `tried` on a later file, putting `已失败` on a success line (R10's colon-less re-opening) | `t7` B/C + `t9` (same base twice in `--mirror`) | **Survived.** `已失败`/`skipped` on success lines = **0**; a duplicated base is named **once**, contacted **once** |
| 4 | The zh fix changed the table entry but a second copy of the old string survives | `t7` C + `grep` over `bin/sc` / `CHANGELOG.md` | **Survived.** 0 occurrences of `前序镜像失败：` |
| 5 | The longer line wraps under the TTY redraw and the next prefix erases part of it | `t8`, `pty.openpty()`, 200 000-byte body, redraws replayed | **Survived.** Note intact, `\n` before the next prefix |
| 6 | The note's value is user-influenced, so `{}`/`%s` in `--mirror` hits `str.format` twice (`KeyError`), and a `\r` breaks the one-line contract | `t7` F: `--mirror 'http://…/{x}%s/geo'`, and a base string containing `\r\n` | **Survived.** Braces and `%s` appear literally, no traceback; the CR is eaten by `_ruleset_bases`' `split()` |
| 7 | The happy path is no longer byte-identical (an empty note still adds a space) | `t7` E, both revisions side by side | **Survived.** stdout **and** stderr byte-identical to `main` |

## R.4 verify_all, stability, defects

`bash .harness/scripts/verify_all.sh`, re-run by QA: **PASS 16 / WARN 0 / FAIL 0 / SKIP 2, exit 0** — **delta 0** vs both the first
QA pass and the pre-edit baseline. `B.2`/`B.3` stay `SKIP` (Q8). **`baseline.json` not updated**: `test_count: 0`, this task still
commits no tests, so the committed count did not rise; the baseline is neither raised nor lowered — T-07 owns that. Stability: the
full suite (10 files, **846 assertions**) ran **3 consecutive times** — `T1 230 · T1b 44 · T2 86 · T2b 29 · T3 44 · T4 71 · T5 45 ·
T6 14 · T7 222 · T8 35 · T9 26`, **0 failed every run**, plus `t9` 3× standalone. **Zero flakes.** **No new defect. D-1 → CLOSED.**
D-2, D-3 (comment applied), D-4, D-5 stand as filed — all MINOR/NIT and PM-deferred; D-4's reach is now slightly wider (a local
`OSError` on temp creation can also surface on a *success* line via `tried`), disclosed by the developer, still cosmetic-severity.
The four **unverified** items stay unverified and unchanged: **BC-25** (`env_reset`), **D-2** escalation as a real sudo caller,
**AC-26** on a real 3.6 interpreter, **BC-32** (`install.log` capture) — none closed this pass, none affected by A-1/A-2.
Observation, not a defect: neither README documents the new note (AC-24 does not require it; `CHANGELOG.md` does carry it).

## R.5 Harness handover to T-07 — yes, stronger than before

`<scratchpad>/qa/` is now **11 files / 846 assertions** and covers A-1/A-2 end to end: `t7_a1a2_delta.py`
(rejection-path coverage, dead-skip exclusion, the `失败：` grep contract, and a **cross-revision byte-identity**
check that loads `git show main:bin/sc` as a second module via `runner_main.py`), `t8_tty_note.py` (PTY redraw
replay) and `t9_dup_mirror.py`. The A-2 assertions are invariants over the output (`count("失败：") == 0` on
success, `== 4` on total failure) rather than string equality, so they survive a retranslation. T-07 should
take this, not the developer's fix-pass driver.

## R.6 Verdict — **`PASS`**

D-1 is closed on every rejection path in both languages, dead-skips stay out of the note, A-2 restores the
`失败：` grep contract, and nothing that had to stay still moved: AC-3's happy-path output is byte-identical
to `main`, AC-13/15/16/17 unchanged, the stdout/stderr split intact, `verify_all` `PASS 16 / FAIL 0` with a
zero delta, product diff and all three timeout constants unchanged. Tree dirty; nothing committed or pushed.
