# 06 — Test Report: `install-binary-download-progress`

- **Task**: T-08 (`docs/batches/default/BATCH_PLAN.md:19`) · **Mode**: `full` · **Date**: 2026-08-01
- **Under test**: `install.sh:116-132` (download flag policy), `:149` / `:193` (`fetching_item`),
  `:344`, `:373`, `:384` (the three curl sites), plus one `CHANGELOG.md` entry.
- **Verdict**: **PASS** (see §9).

Everything below was re-executed by QA. No transcript from `04_DEVELOPMENT.md` is reported as a
result here; where a developer check is reused it is named as inherited and its **own** re-run output
is what is quoted.

---

## 1. Safety — the hard gate on this stage's own work

`.harness/insight-index.md:13` records a run that re-exec'd the *installed* CLI against the owner's
live service. Everything here ran as **uid 1000 (`alan`)**, never root, never `sudo`, against a
rebuilt `PATH` (`<tmp>/stubs:<tmp>/bin:/usr/bin:/bin`) in which `systemctl`, `rc-service`,
`rc-update`, all six package managers, `sudo` and `visudo` are stubs that `exit 99` loudly, `install`
refuses any destination outside the temp tree, `/usr/local/bin` is **absent**, `SB_BIN` and `TMPDIR`
point inside the temp tree, and the absence of a host `sing-box` is *asserted* (a visible one would
short-circuit step 2 and make every run vacuous). No fragment reaching `pkg_install`, `systemctl`,
`install -m` into a system path, `/etc` or `/usr/local` was ever executed.

**Live-system witness** — `systemctl show -p MainPID -p ActiveEnterTimestamp` (never `is-active`;
insight L22 records that `is-active` prints `active` on both sides of a restart):

| | MainPID | ActiveEnterTimestamp |
|---|---|---|
| before all testing | `2500438` | `Fri 2026-07-31 17:04:23 CST` |
| after all testing | `2500438` | `Fri 2026-07-31 17:04:23 CST` |

Unchanged. `/usr/local/bin/sing-box` and `/usr/local/bin/sc` still carry their `Jul 30 12:47` mtimes.
`sudo -n true` → `a password is required`, i.e. no passwordless path was exercised. **AC-20 holds.**

---

## 2. `verify_all` — run by QA, output pasted (discharges the AC-2 MINOR from `05`)

`05_CODE_REVIEW.md:101` recorded AC-2 as **not discharged**: `04` asserted the counts in prose with
no capture. Run here, on the working tree:

```
$ bash .harness/scripts/verify_all.sh
=== verify_all (generic) ===
Project: singbox-cli
[A.1] No hardcoded secrets ... PASS          [E.4b] Hook commands resolve ... PASS
[A.2] No .env files committed ... PASS       [E.5] AI-GUIDE indexes rules ... PASS
[B.1] Syntax (bin/sc, install.sh, uninstall.sh) ... PASS
[B.2] Tests pass ... SKIP                    [E.6] Adversarial tests section ... PASS
[B.3] Lint ... SKIP                          [F.1] AI-GUIDE.md <=200 lines ... PASS
[E.1] Bootstrap files present ... PASS       [F.2] Rule fragments <=200 lines ... PASS
[E.2] workflow.md present ... PASS           [F.3] Agent definitions <=300 lines ... PASS
[E.3] Agents layout v0.30+ ... PASS          [F.4] insight-index.md <=30 lines ... PASS
[E.4] Binding in sync ... PASS               [F.5] docs/tasks.md <=300 lines ... PASS
                                             [F.6] Active task docs <=500 lines ... PASS
=== Summary ===
  PASS: 16   WARN: 0   FAIL: 0   SKIP: 2
EXIT=0
```

**Baseline against pristine `HEAD`.** Taken by `git clone` of the repo at `90ad762` into the QA temp
tree — the working tree was never stashed, reset or otherwise disturbed (`git status` before and
after is the same four modified files plus the untracked task directory).

| tree | PASS | WARN | FAIL | SKIP |
|---|---|---|---|---|
| pristine `HEAD` (`90ad762`, clone) | 16 | 0 | **0** | 2 |
| working tree (this change) | 16 | 0 | **0** | 2 |
| **delta** | **0** | **0** | **0** | **0** |

**AC-2 holds**: 0 FAIL, PASS count not below baseline.

> Methodology note for whoever repeats this. A `git worktree` is **not** a valid baseline here: in a
> worktree `.git` is a *file*, so `verify_all`'s `[[ ! -d .git ]]` guard turns A.1 and A.2 into SKIP
> and the summary reads `PASS: 14 / SKIP: 4`. That looks like a 2-PASS regression and is purely an
> artefact of the checkout mechanism. A clone reproduces the real baseline.

---

## 3. Inherited harness — re-run, and audited for a fourth vacuous green

`04` left an uncommitted harness (`<scratch>/h/`). It was inherited rather than rebuilt, copied to a
QA-owned directory, and **re-executed**. The gate predicted the characteristic failure mode here is a
vacuous green; the developer had already caught three on itself (host `sing-box` short-circuit,
cooked-mode pty injecting CR, stub-server port drift that produced a *false PASS*).

| layer | what it is | QA re-run |
|---|---|---|
| G — `gate_checks.sh` | 5 pre-edit design checks (C-1…C-6) | 5 PASS **after repair — see D-1** |
| S — `static.sh` | 7 static checks on the repo tree | 7 PASS, 0 FAIL |
| H — `harness.sh` | 18 extracted-fragment checks against a stub server | 18 PASS, 0 FAIL |
| Q — `qa/qa.sh` | **9 checks written by QA** from `01`'s criteria | 9 PASS, 0 FAIL |

**39 scripted assertions**, plus six ad-hoc probes (§5, §6). Every layer green.

### D-1 — harness defect found: stale control-file name (MINOR, not product)

`gate_checks.sh` writes its fault injection to `$STUB/faults.json`; `server.py` was later changed to
read `$STUB/control.json` (its own docstring records why: restarting the server to change behaviour
would move the ephemeral port). Re-running the developer's gate script **as shipped** today:

```
### C-3  dropping -s while keeping -f -S does not change the failure text
  -fsSL                    exit=0  bytes=0     last non-empty:
  -f -S -L --progress-bar  exit=0  bytes=2081  last non-empty: ####...#### 100.0%
  byte delta: 2081 (one trailing LF closing the progress area)
  RESULT: FAIL
### C-4 ... exit from C-3 progress run = 0  (2 would mean 'option unknown')
  RESULT: FAIL
=== gate_checks fail=1 ===
```

The 500 fault never applied, so C-3 compared two *successful* transfers. This is the **same shape**
as the port-drift false PASS already recorded in `harness.sh:407-409` — a control channel whose name
drifted out from under a test. Here it fails loudly rather than passing falsely, so the developer's
recorded transcript (taken against the contemporaneous server) is not invalidated. Ported to
`control.json` in the QA copy and re-run, it reproduces the recorded result **exactly**:

```
  -fsSL                    exit=22  bytes=49  last non-empty: curl: (22) The requested URL returned error: 500
  -f -S -L --progress-bar  exit=22  bytes=50  last non-empty: curl: (22) The requested URL returned error: 500
  byte delta: 1 (one trailing LF closing the progress area)
=== gate_checks fail=0 ===
```

Not a product defect. Route to **T-07**, which owns the committed harness.

### D-2 — latent vacuous green found: AC-3's fixture is carried by the *throttle*, not the size

`mkfixture.py` asserts `n >= 8 MiB` with `"fixture too small - would assert nothing (L14)"`, and
insight L14 attributes non-vacuity to **size**. Decomposed (Q-3, §5) that attribution is **wrong for
this harness**:

```
  8MiB/0.02  -> states=26  distinct intermediate=25 [4.7, 8.6, ...]  monotonic=True  final=100.0
  8MiB/0     -> states=1   distinct intermediate=0  []               monotonic=True  final=100.0
  1KiB/0.02  -> states=1   distinct intermediate=0  []               monotonic=True  final=100.0
  1KiB/0     -> states=1   distinct intermediate=0  []               monotonic=True  final=100.0
      8MiB/0.02|ASSERT-HOLDS   8MiB/0|ASSERT-FAILS
      1KiB/0.02|ASSERT-FAILS   1KiB/0|ASSERT-FAILS
```

Over loopback an unthrottled 8 MiB body arrives fast enough that curl renders **one** state — the
8 MiB fixture alone does *not* save AC-3. The server-side `sleep` in `control.json` is the load-
bearing element, and `mkfixture.py`'s guard does not protect it. A future maintainer who removes the
throttle as an "optimisation" makes AC-3 vacuous, and the guard that exists will not fire. This is
the fourth vacuous green the task brief predicted: **latent rather than realised** — the shipped
fixture is throttled, so today's PASS is real. Recommend the insight index carry the corrected fact.

### D-3 — the pty driver itself, verified before anything is believed through it

`ptyrun.py` is what makes BC-3 expressible at all (`script -qec` cannot attach a terminal to stdout
while redirecting stderr). Every 0x0D assertion in the whole suite is measured through it, so it was
probed independently before being trusted — with a probe that does **not** use `$(...)`, which
redirects fd 1 and silently reports `N` for every mode (my first attempt did, and I discarded it):

```
out=tty  err=tty  | STDOUT-SIDE fd1_tty=Y fd2_tty=Y | 0x0D out=0 err=0
out=tty  err=file | STDOUT-SIDE fd1_tty=Y fd2_tty=N | 0x0D out=0 err=0
out=file err=tty  | STDOUT-SIDE fd1_tty=N fd2_tty=Y | 0x0D out=0 err=0
out=file err=file | STDOUT-SIDE fd1_tty=N fd2_tty=N | 0x0D out=0 err=0
control (plain shell redirection, no pty): fd1_tty=N fd2_tty=N
```

All four combinations are genuinely produced, and the raw-mode (`~OPOST/~ONLCR`) handling injects
**zero** CR of its own into a plain-LF stream. The tool is sound.

---

## 4. Test plan — every acceptance criterion mapped to an executed check

| AC | Check(s) | Layer | Result |
|---|---|---|---|
| AC-1 `bash -n` | S-1 | S | PASS |
| AC-2 `verify_all` 0 FAIL, PASS ≥ baseline | §2, both trees | — | PASS |
| AC-3 ≥2 increasing intermediate states on a pty | H AC-3 + **Q-3** | H,Q | PASS |
| AC-4 stderr redirected → 0 × `0x0D`, still installs | H AC-4 + **Q-4** | H,Q | PASS |
| AC-5 exactly one new stdout line, names version+arch | H AC-5 | H | PASS |
| AC-6 500 → same message/URL/exit 1; non-TTY byte identity | H AC-6 + **Q-5** | H,Q | PASS |
| AC-7 302 → 200 installs | H AC-7 + **BC-8 probe** | H,§6 | PASS |
| AC-8 both languages, no `unbound variable` | H AC-8 + **Q-6** | H,Q | PASS |
| AC-9 `t()` zh/en key-set parity | S-6 | S | PASS |
| AC-10 T-01 phase/report/exit unperturbed | S-7 + **Q-7** | S,Q | PASS |
| AC-11 step 2 writes nothing to the install log | S-7 + **Q-8** | S,Q | PASS |
| AC-12 5 name lines, loop order, both modes, no `0x0D` | H AC-12 + **Q-1** | H,Q | PASS |
| AC-13 loop 404 on artifact 3 | H AC-13 | H | PASS |
| AC-14 version query meter-free on a tty | H AC-14 + **Q-2** | H,Q | PASS |
| AC-15 already-installed → no notice, no HTTP request | H AC-15 | H | PASS |
| AC-16 no new external command / file | S-5 | S | PASS |
| AC-17 no option above the curl 7.29 floor | S-4 + **7.29.0 tarball probe** | S,§6 | PASS |
| AC-18 no timeout/retry option added or changed | S-5 | S | PASS |
| AC-19 shipping diff = `install.sh` + `CHANGELOG.md` | S-8 | S | PASS |
| AC-20 no install, no `sc`, no service touched | §1 witness | — | PASS |

Boundary conditions: BC-1/2/3/4 (H BC block, Q-4), BC-5 (H), BC-6/7 (H AC-6), **BC-8** (§6),
**BC-9** (§6), BC-10 (§6), BC-11 (S-6, Q-6), BC-12 (§6), **BC-13** (Q-9), BC-14/15/17 (unchanged by
construction), **BC-16** (§6). **18/18 addressed.**

---

## Adversarial tests
<!-- section 5 -->


Nine independent reproducers written by QA **from `01`'s criteria, not from `04`'s test code**. Each
carries a stated failure hypothesis, written before the run. Source: `<QA temp>/qa/qa.sh` (not
committed — D-12; handed to T-07 with the rest of the harness).

| # | Hypothesis — "I expect this to fail because…" | Outcome |
|---|---|---|
| Q-1 | `04` asserted loop **order** only on the non-TTY capture (`05` NIT). On a tty the five lines interleave with something and the order breaks. | **Survived** |
| Q-2 | AC-14's PASS is vacuous: the release JSON is ~1.6 KB and instant — the L14 shape — so a meter on the version query would render nothing and the assertion could never fail. | **Survived** (assertion proven falsifiable) |
| Q-3 | The 8 MiB fixture is not what makes AC-3 non-vacuous. | **Confirmed as stated** — see D-2 |
| Q-4 | `[ -t 2 ]` is evaluated once at `:130` but the tarball runs at `:384`; something in the 254 lines between rebinds fd 2, so the array no longer matches reality. | **Survived** |
| Q-5 | The `+1` byte `--progress-bar` adds to curl's failure stderr reaches a redirected stream, breaking AC-6/B-5. | **Survived** |
| Q-6 | `t()` declares `local fmt` with no default (L10); the zh branch is only reachable by answering `2`, and `04` used a `LANG_CHOICE` preset — the real prompt path aborts under `set -u`. | **Survived** |
| Q-7 | T-01's `install_report()` derivation shifted, so banner or exit code moved on some phase combination. | **Survived** |
| Q-8 | Step 2 leaks into `/var/log/sing-box/install.log` once `LOG_SINK` is armed. | **Survived** |
| Q-9 | Ctrl-C mid-transfer leaves the partial tarball behind. | **Survived** |

### Q-1 — AC-12 loop order, asserted in **both** modes

Compared byte-for-byte against a literal 5-line expectation. Closes the `05` NIT.

```
  stderr=file rc=0 lines=5 ORDER-OK  stdout_0x0D=0 stderr_0x0D=0     HTTP requests logged: 5
  stderr=tty  rc=0 lines=5 ORDER-OK  stdout_0x0D=0 stderr_0x0D=0     HTTP requests logged: 5
    |   ↓ Fetching bin/sc ...
    |   ↓ Fetching uninstall.sh ...
    |   ↓ Fetching systemd/sing-box.service ...
    |   ↓ Fetching systemd/sing-box-rules-update.service ...
    |   ↓ Fetching systemd/sing-box-rules-update.timer ...
```

Note the loop's stderr carries **zero** `0x0D` even with a terminal on fd 2 — D-4's "name line, no
meter" holds because the loop uses `CURL_OPTS_QUIET`, whose `-s` is unconditional.

### Q-2 — negative control for AC-14

The shipped code, then the same fragment with `CURL_OPTS_QUIET` deliberately forced to the progress
vector, both with stderr on a pty:

```
  shipped   : stderr_0x0D=0  lines-with-'%'=0  bytes=50
  meter-on  : stderr_0x0D=1  lines-with-'%'=1  bytes=131
  q2bad stderr head (cat -v): ^M####################################...#### 100.0%
```

A meter on the version query *is* detectable on that fixture. AC-14's PASS is real, not vacuous.

### Q-4 — the gate's verdict still holds at the download site (BC-3, independently)

Static half — the two constructs are distinguished, because a per-command `2>&1` does **not** rebind
the shell's own fd 2 (my first pattern conflated them and produced a false FAIL):

```
  gate at line 130, tarball curl at line 384, span=254 lines
  per-command 2>&1 in that span (do NOT rebind the shell's fd 2): [(367, 'if command -v sing-box >/dev/null 2>&1; then')]
  PERSISTENT fd-2 rebinding (exec/block redirect/--stderr): NONE
```

Dynamic half — `[ -t 2 ]` re-evaluated *at* the download site and compared with the gate's verdict,
with the selected array printed, in all four terminal combinations:

```
  out=tty  err=tty  | GATE_SAW=tty  AT_DOWNLOAD_SITE=tty  | array=[-f -S -L --progress-bar] | stderr_0x0D=26 rc=0
  out=tty  err=file | GATE_SAW=file AT_DOWNLOAD_SITE=file | array=[-f -s -S -L]             | stderr_0x0D=0  rc=0
  out=file err=tty  | GATE_SAW=tty  AT_DOWNLOAD_SITE=tty  | array=[-f -S -L --progress-bar] | stderr_0x0D=26 rc=0
  out=file err=file | GATE_SAW=file AT_DOWNLOAD_SITE=file | array=[-f -s -S -L]             | stderr_0x0D=0  rc=0
```

Row 2 is **BC-3**, the design's central claim: stdout *is* a terminal, stderr is not, zero `0x0D`.
Row 3 is BC-1 (`| tee install.log`): the bar is on the terminal where it belongs. The negative
control (inherited NEG-3 — force the progress array past the gate off a tty) yields `0x0D = 26`, so
the assertion can fail. `[ -t 2 ]`, not `[ -t 1 ]`, is confirmed as the correct predicate; the diff
contains exactly one executed `[ -t 2 ]` and zero `[ -t 1 ]` (S-3).

### Q-5 — the one-byte stderr delta, tested rather than re-derived

`05` argued *structurally* that the extra byte `--progress-bar` appends to a failed transfer's stderr
can only ever reach a terminal. Measured, post vs pre-change, on a 500:

```
  stderr=tty  | post=50 bytes  pre=49 bytes  delta=1  post_0x0D=0  rc post/pre=1/1
    on a tty : the extra byte is 0x0a (LF, not 0x0D)
  stderr=file | post=49 bytes  pre=49 bytes  delta=0  post_0x0D=0  rc post/pre=1/1
    off a tty: byte-IDENTICAL to pre-change -> the +1 byte cannot reach a log
```

The claim is empirically true, the extra byte is an LF (not a `0x0D`), and off a terminal the failure
stderr is byte-identical to pre-change. **B-5 / AC-6 hold.**

### Q-6 — zh reached through the **real** prompt, not a preset

`04` substituted a `LANG_CHOICE` preset (recorded method substitution R-E). Accepted, but the
insight that motivates AC-8 (L10) is specifically that the zh branch is *only* reachable by answering
`2`. So the actual language-choice block from `install.sh` was extracted and fed `1` / `2` on stdin,
in front of both the tarball fetch and the artifact loop, on both a tty and a file:

```
  answer=en stderr=file | LANG_CHOICE after prompt=en | rc=0 | 'unbound variable' hits=0 | notice lines=6
  answer=en stderr=tty  | LANG_CHOICE after prompt=en | rc=0 | 'unbound variable' hits=0 | notice lines=6
  answer=zh stderr=file | LANG_CHOICE after prompt=zh | rc=0 | 'unbound variable' hits=0 | notice lines=6
  answer=zh stderr=tty  | LANG_CHOICE after prompt=zh | rc=0 | 'unbound variable' hits=0 | notice lines=6
    |   ↓ 获取 sing-box v1.99.0 (amd64) ...
    |   ↓ 获取 bin/sc ...   ↓ 获取 uninstall.sh ...   ↓ 获取 systemd/sing-box.service ...
    |   ↓ 获取 systemd/sing-box-rules-update.service ...   ↓ 获取 systemd/sing-box-rules-update.timer ...
```

All six `fetching_item` renderings are non-empty prose in the answering language, both streams are
free of `unbound variable`, and `LANG_CHOICE` really did flip. **AC-8 / BC-11 hold on the real path.**

### Q-7 / Q-8 — T-01 regression sweep

Static: the phase block, `install_report()`, the log-sink probe with steps 6-7, and the tail are
**byte-identical** pre vs post. Dynamic: `install_report()` driven over all 8 `PHASE_*` combinations
× both languages, pre-change vs post-change:

```
  /^# Phase status/,/^PHASE_SERVICE=/p                        6 lines  IDENTICAL
  /^install_report() {/,/^}$/p                               46 lines  IDENTICAL
  /^# ----------------- install log/,/^# --------- step 7/p  23 lines  IDENTICAL
  /^# The closing report/,/^exit 0$/p                         4 lines  IDENTICAL
  install_report driven over 8 phase combinations x 2 languages = 246 captured lines
  banner text + derived exit status: BYTE-IDENTICAL pre vs post
  EXIT=0 rows (only ok+started qualifies): 4
```

Q-8 arms `LOG_SINK` with a writable file *before* step 2 and runs a full successful transfer with the
bar on a terminal:

```
  rc=0  install-log bytes after a full step-2 success with LOG_SINK pre-armed: 0
  stderr carried the bar instead: 2081 bytes, 0x0D=26
```

**AC-10 / AC-11 / B-10 hold**, dynamically as well as by diff shape.

### Q-9 — BC-13, a real Ctrl-C

```
  alive_at_signal=True child_rc=-2
  leftover temp dirs after the interrupt: 0 ; run reached 'Installed:' 0 time(s)
```

Getting this right required discarding two earlier methods of my own. `bash script & ; kill -INT $!`
does nothing: POSIX makes an asynchronous command ignore SIGINT when job control is off, `curl`
inherits that `SIG_IGN`, and the transfer runs to completion while the test reports "reaped" — a
would-be **fifth** vacuous green, caught only because I also asserted the run had *not* reached
`Installed:`. `setsid …&` then `kill -INT -$!` fails differently: `setsid` forks, so `$!` is not the
shell. The working reproducer spawns the child with `os.setsid()` **and** `SIGINT` restored to
`SIG_DFL`, then `killpg`. `child_rc=-2` is death by SIGINT mid-transfer; the `EXIT` trap still
removed `$SB_TMPDIR`. **BC-13 holds.**

---

## 6. Ad-hoc probes

- **BC-10 / AC-17, against the real curl 7.29.0 release tarball** (not a grep of our own file).
  Parsed 161 alias rows out of `curl-7.29.0/src/tool_getparam.c`: `-f/--fail`, `-s/--silent`,
  `-S/--show-error`, `-L/--location`, `-#/--progress-bar` all **present**; `--no-progress-meter`,
  `--fail-with-body`, `--retry-all-errors` all **absent from 7.29.0 and absent from `install.sh`**;
  the 7.29.0 man page carries `.IP "-#, --progress-bar"`. Header confirms `LIBCURL_VERSION "7.29.0"`.
  (The loose copy at `<scratch>/c729/include_curl_curlver.h` reads `7.28.2-DEV` and is not the
  release header — the tarball was used instead.)
- **BC-8, meter across a redirect**: 302 → 200 with the bar on a terminal. Requests logged
  `/api/… → /redir/… → /gh/…`; `states=26, distinct intermediate=25, monotonic=True, final=100.0`;
  exactly **one** bar restart; binary installed. The "restart at a hop is acceptable" allowance is not
  even needed — the meter stays monotonic.
- **BC-16, degenerate terminal**: `TERM` unset, `COLUMNS=1`. `rc=0`, 26 × `0x0D`, 25 distinct
  intermediate states, binary installed. No width or capability requirement is imposed and none is
  needed.
- **BC-9, non-semver `tag_name`**: the validation fires **before** the notice can name an empty
  version — `0` notice lines, `1` HTTP request (the API query only; the release host is never
  contacted), no meter, `✗ Download failed: GitHub API (sing-box version)` + `check_network`, exit 1.
- **BC-12, zero-byte tarball at HTTP 200**: `rc=2`, identical on both streams, `0x0D=0`, temp dir
  cleaned, nothing installed, and the only diagnosis is `tar: Error is not recoverable: exiting now`.
  This is E-13 exactly as `01` §4 item 8 describes it — **pre-existing and explicitly out of scope**;
  this task neither improves nor worsens it. Recorded here so it is visible, not lost.

---

## 7. Stability

Every layer executed **three** times end to end, plus `verify_all` three more times:

```
run 1: [H] PASS=18 FAIL=0 | [Q] PASS=9 FAIL=0 | [S] PASS=7 FAIL=0 | [G] fail=0 | verify_all PASS:16 FAIL:0
run 2: [H] PASS=18 FAIL=0 | [Q] PASS=9 FAIL=0 | [S] PASS=7 FAIL=0 | [G] fail=0 | verify_all PASS:16 FAIL:0
run 3: [H] PASS=18 FAIL=0 | [Q] PASS=9 FAIL=0 | [S] PASS=7 FAIL=0 | [G] fail=0 | verify_all PASS:16 FAIL:0
```

No flakes observed across 3 × 39 scripted assertions. The stub server binds an ephemeral port and the
port is re-read per run, so no drift recurred.

---

## 8. Defects

**Product defects: none.** No BLOCKER, CRITICAL, MAJOR or MINOR against `install.sh` or
`CHANGELOG.md`. No rollback target is named.

| # | Sev | Where | Description | Route |
|---|---|---|---|---|
| D-1 | MINOR | harness `gate_checks.sh` (uncommitted) | Writes `faults.json`; `server.py` reads `control.json`. Re-running as shipped gives a **false FAIL** on C-3/C-4. Repro: `bash h/gate_checks.sh` → `fail=1`. Fixed in the QA copy; recorded result reproduces exactly. | **T-07** (owns the committed harness) |
| D-2 | MINOR | harness `mkfixture.py` + insight L14 | AC-3's non-vacuity is carried by the server-side **throttle**, not the 8 MiB size; the existing `assert n >= 8 MiB` guard does not protect the throttle. Repro: set `control.json` `"sleep": 0` with the 8 MiB fixture → `states=1`, AC-3 becomes vacuous and no guard fires. | **T-07** + PM (insight index correction) |

Neither is a defect in the shipped change; both are test-infrastructure findings, and both are
reproducible with the steps given.

Also carried forward, unchanged and correctly out of scope: the version-query silent abort (`01` §4
item 11, `.harness/rejected-decisions.md#installer-version-query-silent-abort`) and the unguarded
`tar -xz` (E-13, confirmed live in §6 BC-12).

---

## 9. Verdict

**PASS**

- 20/20 acceptance criteria have at least one executed check; all pass.
- 18/18 boundary conditions addressed; all behave as specified.
- 39 scripted assertions across four layers, 0 FAIL, re-run 3× with no flakes; plus 5 ad-hoc probes.
- `verify_all`: **PASS 16 / WARN 0 / FAIL 0 / SKIP 2**, delta **0** against a pristine `HEAD` clone.
- Both items `05_CODE_REVIEW.md` handed to QA are discharged with pasted output: the AC-2 evidence
  MINOR (§2) and the AC-12 single-mode order NIT (Q-1).
- Two harness defects found and routed to T-07; **no product defect**.
- AC-20 witness unchanged before and after: `MainPID=2500438`,
  `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST`. Nothing was installed, no `sc` was invoked, the
  host's sing-box was never started, stopped or restarted.

Approved for delivery.
