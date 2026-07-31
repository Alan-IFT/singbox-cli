# 06 — Test Report · T-10 `ruleset-update-no-needless-restart`

- **Task**: T-10 · **Mode**: full · **Stage**: 6 · **Date**: 2026-08-01 · **Deferred-human**: `defer, do not ask`
- **Upstream read**: `01` (25 ACs, NFR-1…NFR-5) · `02` rev. 2 (§11 G-1…G-7) · `03` (C-1…C-11) · `04` · `05` (APPROVED, §Routing)
- **Verdict**: **PASS WITH NOTES** — 522 assertions, 0 failures, `verify_all` 16 PASS / 0 WARN / 0 FAIL / 2 SKIP, delta **0** against a pristine `HEAD` baseline I rebuilt. 0 product defects. 3 notes, all recorded not fixed.
- **Harness (C-11)**: complete and runnable verbatim in **`QA_HARNESS_T10.md`** (this folder, ~2 260 lines). It is *not* pasted into this file because F.6 caps `0[1-7]_*.md` at 500 lines and any WARN makes `verify_all` exit 1; F.6 does not match that filename, so nothing is bypassed and nothing is elided.
- Repo root for every relative path: `/home/alan/Programs/singbox-cli`.

## 0. Independence statement

I wrote my **own** loader, my own shims and my own eight scripts in a fresh directory
(`<scratchpad>/qa_t10/`), from `01` §6/§7, **not** from `04`'s test code. The developer's
`<scratchpad>/t10/` harness was read once for its safety shape (C-3 inheritance) and never
executed. The live hazard `<scratchpad>/main_sc.py:54` (an un-neutralised copy of `bin/sc`
carrying `os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] …)`) was **not read as a pattern and
not run**; nothing was ever executed from the shared scratchpad root.

## 1. Safety — NFR-1 / C-2 / C-3 / C-4

Three layers, all of them **proved to fire** before their silence was treated as evidence
(`q0_safetynet.py`, 26 assertions):

| Layer | Covers | Positive control result |
|---|---|---|
| 0 `ExecTripwire` | `os.execvp / execv / execl / system / spawn*` inside the loaded module | `os.execvp` is a raising stub ✓ |
| 1 `Tripwire` | `subprocess.run / Popen / call / check_call / check_output / getoutput / getstatusoutput`; **nothing whitelisted, `sing-box` least of all** (C-4) | all 7 entry points raise; `restart_service()` with `SYSTEMD=True` re-armed is stopped with argv `['systemctl','restart','sing-box']` ✓ |
| 2 PATH shims | any real `systemctl / rc-service / sing-box / sc / sudo / service / openrc / rc-update / systemd-run`, via **any** route incl. a re-import or a forgotten script | all 5 probed shims exit 91 and are recorded in a side marker ✓ |

Loader hard-fail proved, not asserted: mutating one space into `if os.geteuid() != 0 :` makes
`load_sc()` exit **97** with `*** SAFETY VIOLATION *** the auto-elevate block does not match
qalib.ELEVATE_SRC — refusing to load`. A drift in `bin/sc` cannot silently produce an
un-neutralised import.

**G-3 is a grep, not a promise** — `run.sh` refuses to run until every `.py` in the directory
imports the one loader and none contains a raw `exec`/`os.exec*`/`/usr/local/bin/sc` call site:

```
### euid: 1000  (alan)
### G-3: every .py here loads bin/sc only through qalib
    q0_safetynet.py OK   q1_digest_contract.py OK   q2_comparator.py OK   q3_run.py OK
    q4_negative_control.py OK   q5_static.py OK   q6_init_tty_cost.py OK   q7_generate_config.py OK
### which systemctl -> <scratchpad>/qa_t10/shims/systemctl
```

Nothing executed `/usr/local/bin/sc`. `restart_service()` was never invoked against the live
system. Every fixture lived under `tempfile.mkdtemp()`; `CFG_DIR/CFG_PATH/NODES_PATH/
SETTINGS_PATH/RULES_DIR` are self-asserted inside the temp root and not under `/etc/` before the
first call. euid was 1000 for every command.

### C-2 witness — process identity, before and after the WHOLE run

`systemctl is-active` is kept because AC-24 names it, but it is **not** the witness: it prints
`active` on both sides of a restart and would have passed *during* the T-02 incident.

```
--- BEFORE (2026-08-01T00:11:39+08:00, before anything was loaded) ---
$ systemctl is-active sing-box
active
$ systemctl show sing-box -p MainPID -p ActiveEnterTimestamp
MainPID=2500438
ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST

--- AFTER (2026-08-01T00:27:48+08:00, after 10 full suite runs + both verify_all runs) ---
$ systemctl is-active sing-box
active
$ systemctl show sing-box -p MainPID -p ActiveEnterTimestamp
MainPID=2500438
ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
```

**Identical `MainPID` (2500438) and identical `ActiveEnterTimestamp`** ⇒ the live sing-box was
never restarted, reloaded, started or stopped. AC-24's two `is-active` readings are `active` and
`active`.

**G-5** — `ls -la --time-style=full-iso /etc/sing-box /etc/sing-box/rules` before vs after
diffs **IDENTICAL** (config.json 5572 B @ 2026-07-30 13:00:14; the four `.srs` unchanged at their
17:04 timestamps), and `find /etc/sing-box -newermt '2026-08-01T00:11:39+08:00'` printed nothing.
Nothing under `/etc/sing-box/**` was written.

**Shim marker** at the end of every script and again by the runner, on all 10 stability runs:
`(absent — no systemctl / rc-service / sing-box / sc / sudo invocation)`.

## 2. Test plan — every acceptance criterion has a test

| AC | Test case(s) | Script | Result |
|---|---|---|---|
| AC-1 no restart/reload/start/stop on identical bytes | `BC-1 no-op` ×2 langs, service log `[]` | `q3_run.py` | PASS |
| AC-2 `config.json` byte-identical | sha256 **and** `st_mtime_ns` before/after | `q3_run.py` | PASS |
| AC-3 exit 0 + outcome once | exit `0`, `Done` printed, 1 outcome line | `q3_run.py` | PASS |
| AC-4 exactly one apply per run | `svc.count("restart_service") == 1` | `q3_run.py` | PASS |
| AC-5 equal size, different content | equal-size fixture at run level **and** two 100 003-byte files sharing their first 70 KiB at reader level | `q3_run.py`, `q1_digest_contract.py` | PASS |
| AC-6 mtime ignored | `os.utime(…,(1,1))` ⇒ identical `(status,digest)`; full rewrite of identical bytes ⇒ no apply | `q1`, `q3` | PASS |
| AC-7 absent → usable regenerates + applies + restored line | `['generate_config','is_running','restart_service']`, regen precedes restart | `q3_run.py` | PASS |
| AC-8 bad-magic → usable | same, plus too-small → usable | `q3_run.py` | PASS |
| AC-9 stopped service never started | `is_running=False` ⇒ log `['is_running']` only | `q3_run.py` | PASS |
| AC-10 no `config.json` ⇒ nothing | log `[]`, no config created, exit 0 | `q3_run.py` | PASS |
| AC-11 all mirrors fail | log `[]`, `sys.exit("\n4 ruleset(s) failed to update")`, no file modified | `q3_run.py` | PASS |
| AC-12 apply **before** the non-zero exit | ordered stub log + stdout index ordering | `q3_run.py` | PASS |
| AC-13 pre-state observation never raises | 12 fixture shapes + 3 duck-typed fault shapes | `q1_digest_contract.py` | PASS |
| AC-14 every added key has a `zh` entry | key extractor over the diff ∩ `TRANSLATIONS["zh"]`; `t()` in `zh` never falls back | `q5_static.py` | PASS |
| AC-15 no `失败：` in added zh | plus `失败 / 成功 / 错误： / ⚠️ / 已跳过` collision audit | `q5_static.py` | PASS |
| AC-16 non-TTY: one line per rule-set, no `\r` | 4 prefixes, 4 completion lines, `\r` absent, outcome is run-level | `q3`, `q6` | PASS |
| AC-17 TTY redraw + per-file causes unchanged | real `pty.fork()` run, both languages | `q6_init_tty_cost.py` | PASS |
| AC-18 outcome states what happened | 4 scenarios × 2 langs, stdout cross-checked against the stub log | `q3_run.py` | PASS |
| AC-19 non-disruptive fallback | **n/a** — `02` §2.3 resolved B-4 to restart-only; no such mechanism exists to test | — | n/a |
| AC-20 `verify_all` no new WARN/FAIL vs pristine HEAD | re-run by me on both sides (§4) | — | PASS |
| AC-21 3.6 floor, stdlib only | 15 banned-construct regexes over the 141 added lines + whole-file counters | `q5_static.py` | PASS |
| AC-22 diff boundary | attributed list, per PM ruling (§5) | `q5_static.py` | PASS |
| AC-23 `CHANGELOG.md:15` corrected + new entry | old clause absent, new clause and bullet present | `q5_static.py` | PASS |
| AC-24 `is-active` same before/after, both stated | §1 | — | PASS |
| AC-25 no second on-disk judgment | delete `srs_reject_reason` ⇒ `ruleset_state` **and** `changed_usable_tags` break | `q1_digest_contract.py` | PASS |

## Adversarial tests (section 3, REQUIRED) — one predicted failure per criterion

Independent reproducers, each with the hypothesis written **before** the run. Verdict rests on
whether the implementation survived these, not on the developer's tests passing.

| # / AC | Hypothesis ("I expect failure when…") | Reproducer (all NEW, written by me) | Outcome |
|---|---|---|---|
| H1 / AC-13, C-5 | a mid-read `OSError` leaks a **partial** digest (the hash object *is* updated before the raise) | `q1_digest_contract.py` `FaultingPath` — OSError after 1 good chunk, on the first read, and from `open()` | **Survived.** `('unreadable', None)` all three; the digest of the bytes that *were* read is provably not returned |
| H2 / AC-13, C-5 | a readable **empty** file returns `None` (a `if size == 0: return None` guard looks reasonable) | 0-byte fixture | **Survived.** `('too-small', 'e3b0c442…b855')` = a real `sha256(b"")` |
| H3 / AC-5 | the `SRS` magic is missed when the first chunk is shorter than 3 bytes | `ChunkyPath([b"S",b"R",b"S",…])` | **Survived.** `usable`; the wrong-3rd-byte control is `bad-magic` |
| H4 / AC-13 | `ruleset_state()` raises on a directory / dangling symlink / mode-000 path | 12 real fixtures incl. a unicode filename and a 6 MiB file | **Survived.** No branch raises; peak traced memory 136 442 B on 6 MiB (BC-15) |
| H5 / AC-5 | the digest covers only the first chunk, so two files agreeing on their first 64 KiB compare equal | two 100 003-byte files, identical first 70 000 bytes | **Survived.** Digests differ; digest == `sha256(whole file)` |
| H6 / BC-6 | two never-read files (`None` vs `None`) compare **equal** | `changed_usable_tags` table | **Survived.** `unreadable→usable` with `None` on both sides still yields `['a']` |
| H7 / F-10 | pairing is positional, so a reordered `before` mis-pairs | **every permutation** of `before` over all 17 table cases + a swapped-order control | **Survived.** Identical answers; the control a positional comparator would fail returns `[]` |
| H8 / BC-13 | a LOSS is reported as a change ⇒ restart into a config naming an unparseable file | usable→absent / →bad-magic / →unreadable, and a live mid-run `unlink()` during the download loop | **Survived.** `[]`, no service action, exit 0, no crash |
| H9 / AC-4 | `gained ⊄ changed` for some transition, so recovery silently stops applying | exhaustive 5×5 status transition sweep | **Survived.** 0 violations |
| H10 / AC-1 | the no-op run still touches the service, or does so through a path the stubs cannot see | tripwire argv log **and** `os.exec*` log **and** PATH-shim marker, on every scenario | **Survived.** All three empty on every no-op run |
| H11 / AC-4 | a changed run applies once per changed file | `svc.count("restart_service")` with 1, 2 and 4 changed tags | **Survived.** Always exactly 1 |
| H12 / C-10 | the outcome line is doubled, or missing on the `sys.exit` path | outcome-line counter over all six shapes, both languages, both exit paths | **Survived.** Exactly 1 in all 40 scenario runs |
| H13 / AC-18 | "restarted" wording appears where no restart was issued | 4 scenarios × 2 langs, said-vs-did cross-check on the **distinguishing suffix** | **Survived.** `said == did` in 8/8 |
| H14 / AC-2 | `config.json` is rewritten on a no-op run | `st_mtime_ns` (stricter than a digest) | **Survived.** Not even touched |
| H15 / AC-9 | a stopped service gets started | `is_running=False` + changed bytes | **Survived.** `['is_running']`, no restart |
| H16 / AC-10 | with no `config.json`, a changed run still touches the service | fresh-install fixture | **Survived.** `[]`, no config created, exit 0 |
| H17 / AC-14 | `zh` leaks an untranslated English key | 6 English fragments searched in the whole `zh` stdout | **Survived.** 0 leaks |
| H18 / the defect | the fixture is too weak to tell the defect from the fix | negative control on `HEAD:bin/sc` + **4 mutants** (§6) | **Survived.** All 4 mutants killed |
| H19 / AC-21 | a sixth 3.7+ construct crept in | whole-file counters + 15 regexes over added lines | **Survived.** `:922 :964 :1289`, exactly the 5 pre-existing sites |
| H20 / AC-15 | a new zh string carries `失败：` or a grep-colliding token | 6 tokens × 3 keys | **Survived.** 0 hits |
| H21 / AC-14 | a key was added without a zh entry, or placeholders diverge | diff-derived key list vs `TRANSLATIONS["zh"]` | **Survived.** Exactly 3 keys, `{names}` parity |
| H22 / AC-22 | an unauthorised **product** file carries a T-10 change | attributed `git diff --name-only` (§5) | **Survived.** Product diff = `bin/sc`, `CHANGELOG.md`, `docs/dev-map.md` |
| H23 / C-11 | R6's comment is gone, so a future edit can restore the unconditional restart | window scan above the single apply call site | **Survived.** Comment names `changed_usable_tags()` **and** "T-10 defect" at `bin/sc:1240-1242` |
| H24 / B-12 | the decision is systemd-specific; an OpenRC host still restarts on a no-op run (E-4) | **real** `is_running`/`restart_service` (deliberately un-stubbed) under `SYSTEMD=True` and `OPENRC=True` | **Survived.** No-op: 0 subprocess calls on both. Changed: first argv is `['systemctl','is-active','--quiet','sing-box']` / `['rc-service','sing-box','status']` respectively, both stopped by the tripwire |
| H25 / D-5 | the outcome line is suppressed when stdout is not a terminal (the timer/install.log path) | real `pty.fork()` **and** a redirected pipe, both languages | **Survived.** Exactly once in all four; `\r` absent on the pipe |
| H26 / NFR-3 | the run reads each file more than twice | `Path.open` counter | **Confirmed, as a NOTE** — see N-1 |
| H27 / BC-14 | concurrency corrupts a file or crashes a run | 2-way and 10-way real process races | **Survived.** All exit 0, files intact, no temp debris, one outcome line each |
| H28 / F-7 | `generate_config()`'s 3-tuple destructuring broke on 4-tuples | **real** `generate_config()` to the `sing-box check` tripwire | **Survived.** All four rule-sets defined and named correctly |
| H29 / T-02 | the degradation matrix regressed | bad-magic / too-small / empty / absent / directory / all-four-unusable | **Survived.** Identical to T-02 behaviour incl. dropping `route.rule_set` entirely |
| H30 / F-7 | the widened failure surface is bigger than `04` records | fault injected at the **file-object** boundary at byte 500 000, measured on **HEAD and the change** | **Confirmed and correctly bounded** — see N-2 |

### Evidence for the two that were not refuted

```
-- NFR-3 / M-4 / H26
  PASS  NFR-3 no-op run: each rule-set file opened exactly twice
        {'geoip-cn.srs': 2, 'geosite-cn.srs': 2, 'geosite-google.srs': 2, 'geosite-private.srs': 2}
     gained run, REAL generate_config(): {'geoip-cn.srs': 3, 'geosite-cn.srs': 3,
        'geosite-private.srs': 3, 'geosite-google.srs': 2}
        (tripwire stopped it: TripwireError: ['sing-box', 'check', '-c', '…/config.json'])

-- H30 / F-7
     HEAD (pre-change)    file readable at byte 0, faults at byte 500 000 -> rule-set KEPT
     working tree         file readable at byte 0, faults at byte 500 000 -> rule-set DROPPED
  PASS  HEAD (pre-change): a 900 KB rule-set that reads cleanly is kept
  PASS  working tree: a 900 KB rule-set that reads cleanly is kept
```

## 4. `verify_all` result

Both sides re-run by me; the pristine baseline is my own `git clone --no-hardlinks` checked out
at `10fa8e8` (`git status --porcelain` empty), not the developer's numbers.

| Run | PASS | WARN | FAIL | SKIP | exit |
|---|---|---|---|---|---|
| Baseline — pristine `HEAD` `10fa8e8` | 16 | 0 | 0 | 2 | 0 |
| Working tree (T-10 change) | 16 | 0 | 0 | 2 | 0 |
| Working tree, **final state** (this report + `QA_HARNESS_T10.md` present) | 16 | 0 | 0 | 2 | 0 |

`diff` of the per-check status lists, pristine vs final: **IDENTICAL — delta 0.** No check
regressed, no new WARN, no FAIL.

One honest detail: my **first** draft of this report headed the adversarial section
`## 3. Adversarial tests …`, which check **E.6** rejects (its regex is `^##\s+Adversarial`).
`verify_all` correctly went to `FAIL: 1`. I renamed the heading; I did **not** touch
`verify_all.sh` or its regex. The check earned its keep. The two SKIPs are `B.2 Tests pass` and `B.3 Lint`, the project's standing state;
B.2 stays SKIP with its recorded reason (D-8/C-11).

- QA assertions: **522** across 8 scripts (q0 26 · q1 62 · q2 24 · q3 260 · q4 15 · q5 73 · q6 35 · q7 27). Failures: **0**.
- New tests added: 8 scripts / 522 assertions, **not committed** (D-8/C-11 upheld — no `tests/` tree, `verify_all.sh` untouched).
- **`baseline.json` deliberately NOT updated.** It records `test_count: 0` because B.2 is SKIP; raising it while no committed suite exists would assert coverage the repository does not have. The number goes up in T-07, when the harness is committed and B.2 is wired. `verify_all` and its checks were not modified.
- F.6 doc sizes measured: `01` 370 · `02` 495 · `03` 207 · `04` 497 · `05` 227 · `PM_LOG` 267 · this file — all ≤ 500. `QA_HARNESS_T10.md` is not matched by F.6's `0[1-7]_*.md` / `PM_LOG.md` pattern.

## 5. Stage-5 hand-offs, discharged

**C-6 whole-file counters, against the corrected numbers.** `grep -nE
'capture_output=|text=True|:=|missing_ok=' bin/sc` returns exactly three lines:

```
bin/sc:922   capture_output=True, text=True)
bin/sc:964   capture_output=True).returncode == 0
bin/sc:1289  capture_output=True, text=True,
```

`capture_output=` ×3, `text=True` ×2 = the five pre-existing 3.7+ sites. **No sixth. No walrus
anywhere in the file. No `missing_ok=`.** Exactly one import added: `import hashlib`. `05`'s M-1
correction is confirmed; `04`'s numbers now match.

**C-8 as an attributed list (PM ruling — not set-inclusion).**

| File | Stage that wrote it | Class |
|---|---|---|
| `bin/sc` | 4 (developer) | **PRODUCT** (authorised) |
| `CHANGELOG.md` | 4 (developer) | **PRODUCT** (authorised, D-9) |
| `docs/dev-map.md` | 4 (developer) | **PRODUCT** (authorised by C-8) |
| `CONTEXT.md` | **1** (requirement analyst) — mtime 22:32:18, between `01` 22:31:52 and `03` 23:08:30, and 62 min before `bin/sc` 23:34:56 | bookkeeping, mandated by `01` §3 |
| `docs/tasks.md` · `docs/batches/default/BATCH_PLAN.md` | 0/1 (PM) — mtimes 22:24 / 22:25 | bookkeeping |
| `.harness/rejected-decisions.md` | 2 (architect) — mtime 23:28:53, alongside `02` 23:28:18 | bookkeeping |
| `docs/features/ruleset-update-no-needless-restart/*` (6 untracked) | 0–5 | stage documents |

**No unauthorised product file carries a T-10 change.** `install.sh`, `uninstall.sh`, `systemd/*`,
`README.md`, `README.zh-CN.md` are all absent from the diff. `git diff --stat`:
`bin/sc | 169 ++++---`, `CHANGELOG.md | 3 +-`, `docs/dev-map.md | 6 +-` (147 insertions, 31
deletions). C-8's substance holds.

**M-4 recorded against NFR-3** — see N-1. **N-1's restatement** (`04:413-420`) reads correctly:
`ruleset_status()` is protected by one-line delegation, not by a test that does not ship.

## 6. Negative control and mutation testing — proof the fixtures have teeth

```
== PRE-CHANGE bin/sc (HEAD 10fa8e8) on the identical no-op fixture
     service-layer call log: ['is_running', 'restart_service']
     stdout tail: ['→ Restarting sing-box ...', 'Done']
== CHANGED bin/sc (working tree) on the identical fixture
     service-layer call log: []
     stdout tail: ['No rule-set changed — the sing-box service was not touched', 'Done']
== delta: ['is_running', 'restart_service']  ->  []
```

The **F-11 delta measured from both sides** on the same "2 changed + 2 failed" fixture:
HEAD `[]` (its `sys.exit` short-circuits the restart) → change `['is_running','restart_service']`
then a non-zero exit. Requirement-sanctioned (B-14/BC-9/AC-12), and it is the one case where
R9's lost-rule-set hazard is genuinely new rather than inherited.

Four defects injected into the **changed** `bin/sc`, one at a time; every one was killed:

| Mutant | Assertion that went red |
|---|---|
| M-A restore the unconditional restart tail (`if changed and CFG_PATH.exists()` → `if CFG_PATH.exists()`) | BC-1 — the no-op run restarts again |
| M-B compare file **size** instead of content (`digest.hexdigest()` → `str(size)`) | AC-5 only. A different-size change still trips BC-2, so AC-5 is the *sole* assertion that kills it — exactly why B-1 forbids size |
| M-C "tidy" the `None` arms into plain `old != new` | BC-6 — `unreadable → usable` with `None` on both sides returns `[]` instead of `['a']` |
| M-D drop the `usable in after` filter | BC-13 — a pure loss becomes a "change" |

## 7. Boundary tests added

Null / absent (`absent`), unreadable (EPERM file, mode-000 **parent** directory, dangling
symlink, directory-in-place, injected mid-read `OSError`), empty (0 bytes), size-floor edges
(15 vs 16 bytes), sub-magic chunking (1-byte reads), unicode filename (`uni-中文.srs`),
equal-size-different-content, first-64-KiB-identical-different-tail, large file (6 MiB, peak
traced memory 136 442 B), 900 KB with a fault at byte 500 000, empty `RULESET_FILES` tuple
(BC-16), mid-run external deletion (BC-13), concurrency (2-way per BC-14's literal wording and a
10-way stress), `--mirror` override (BC-19), both init systems, TTY and pipe, both languages.

**Mode-000 parent directory** (stage 5 asked me not to report it as a defect, and it is not one):
stage 5 predicted `absent`; on this host (Python 3.12.3) I **measured `unreadable`**, because
`Path.exists()` propagates `EACCES` and the outer `except OSError` catches it. Either label is
inside the `None` set, so the C-5 invariant is unaffected. Stage 5's *label* prediction was wrong;
its *conclusion* was right. Recorded for accuracy only.

## 8. Stability

- Full suite run **10 times**: `522 PASS / 0 FAIL`, runner exit 0, shim marker absent, on every run.
- **One flake found and fixed — in my own test, not in the product.** An earlier `q6` asserted
  "at most 1 of 10 concurrent runs applies"; it failed 1 in 3. BC-14 is scoped to *two* runs
  ("timer + manual") and bounds *redundant* applies, so with N racing runs up to N may each
  legitimately observe a change — each takes its own `before` snapshot (R4). The corrected test
  asserts BC-14's real bound (≤ 2 applies for 2 racing runs) and adds the comparison that matters:
  in a 10-way race **HEAD applies 10 times, the change applies 1** — never worse than today.
  Re-run 5× after the fix, then 10× as part of the full suite: no further flakes.
- `verify_all` run twice per side: identical output.

## 9. Notes (recorded, not defects to fix here)

**N-1 — NFR-3's literal "at most twice per run" is not met on the recovery path (M-4).** Measured,
not inferred: a `gained` run opens each rule-set file **three** times — `before`, `after`, and
`generate_config()`'s own `ruleset_report()`. The no-op path is exactly two. The third pass is
inherited from T-02 and lives on a path `02` §3 lists as "not touched"; NFR-3's real intent (no
network, no new timeout, bounded chunks, O(1) memory) is met. Recorded against NFR-3, not a T-10
regression.

**N-2 — F-7's widened failure surface, measured on both sides.** A file readable at byte 0 that
faults at byte 500 000 is **KEPT** by HEAD's `generate_config()` and **DROPPED** by the change,
so its routing rules go with it. This is exactly the residual `04` §C-7(iii) records, and no
larger: the same 900 KB file read cleanly is kept on both sides, so the change is confined to the
fault case and is not a large-file regression. `05`'s M-3 (unbounded hashed *length*) stands as a
follow-up pool-row candidate.

**N-3 — R5's residual is unchanged and still true.** `restart_service()` runs with `check=False`,
so "sing-box restarted to load them" claims a restart was *issued*. On a host with neither init
system `is_running()` is `False`, so the run prints "the service was not touched" — I verified no
dishonest "restarted" line is reachable.

## 10. Defects found

**None.** 0 BLOCKER, 0 CRITICAL, 0 MAJOR, 0 MINOR against the product. The only failures during
this stage were four in my own test code (an AC-18 predicate matching a shared prefix, an AC-25
fixture that short-circuited before the deletion could matter, an import regex matching a
docstring line, and the BC-14 concurrency bound) — all corrected, all documented above.

## 11. What I could NOT verify — stated plainly

1. **A real OpenRC host.** B-12 was verified by driving the OpenRC branch with `OPENRC=True` and
   observing that the run reaches `['rc-service','sing-box','status']` only when something
   changed. No OpenRC machine, no `/etc/periodic/<period>/singbox-update-rules` execution.
2. **A real Python 3.6 interpreter.** The 3.6 floor is verified by 15 banned-construct regexes and
   whole-file counters (C-6's technique), plus `py_compile` on 3.12. Not executed on 3.6.
3. **The weekly timer firing end to end.** `systemctl start sing-box-rules-update.service` is
   forbidden by NFR-1.3 and was not run. The scheduled path is covered only by the non-TTY
   fixtures (D-5) and by reading the unit files.
4. **A genuine hardware/IO fault.** The mid-read `OSError` of H1/H30 is injected at the file-object
   boundary (a duck-typed `read()`), not produced by a failing disk. The injection point is the
   same one the kernel would raise from, but it is an injection.
5. **`install.sh` end to end (BC-12).** `install.sh` is untouched and outside the diff; step 6's
   consumption of the exit status was verified only at the level of "a no-op run exits 0".
6. **Whether sing-box's own fswatch reloads a renamed-over `.srs`** (`02` F-4a). Deliberately not
   attempted — "just try a real restart and see" is the NFR-1 red line on this host, and the
   decline record's unblock path requires a disposable machine. The design does not depend on it.
7. **`sc doctor` / `sc config --show` interactions** (T-05/T-06) — not filed, nothing to test.
8. **AC-19** is not-applicable by design (`02` §2.3), not untested: B-4 resolved to restart-only,
   so there is no non-disruptive mechanism whose failure path could be exercised.

## 12. Verdict

**PASS WITH NOTES — APPROVED FOR DELIVERY.**

The defect is gone and gone structurally. The negative control settles it rather than asserting
it: one identical fixture yields `['is_running','restart_service']` on `HEAD` and `[]` on the
change, and four injected mutants — including a straight restoration of the unconditional restart
— are each killed by a named assertion. The C-5 contract, the one place this could have been
implemented wrongly, survived direct attack: no partial digest escapes a mid-read `OSError`, a
readable empty file gets a real `sha256(b"")`, and the equivalence holds in both directions over
every fixture. T-02's recovery is intact in effect and in ordering, `gained ⊆ changed` holds over
all 25 status transitions, and both languages print exactly one truthful outcome line on both exit
paths.

The three notes are recorded, not fixed: N-1 (NFR-3's literal count, inherited), N-2 (F-7's
measured surface, correctly bounded and already disclosed), N-3 (R5, unchanged). None changes
behaviour and none was introduced by this task beyond what `04` already recorded.

The live sing-box was never touched: `MainPID=2500438` and
`ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST` are identical before and after,
`/etc/sing-box` is byte-for-byte unmodified, and no PATH shim was invoked in any of the ten runs.

**Not committed, not pushed** — the owner handles delivery.

**Next:** PM — deliver, and consider pool rows for `05` M-3 (unbounded hashed length), R9's
restart-during-a-loss, R5's issued-vs-succeeded, and `05` M-2 (`bin/sc:1258` PEP 8 E302).
