# 04 — Development Record · T-09 `fix-rules-update-execstart`

> Mode: **full** · Deferred-human (defer, do not ask) · 2026-07-31
> Upstream read, never edited: `01_REQUIREMENT_ANALYSIS.md` (READY), `02_SOLUTION_DESIGN.md` (READY),
> `03_GATE_REVIEW.md` (APPROVED WITH CONDITIONS, C-1…C-5 binding).
> Rules loaded before writing anything: `AI-GUIDE.md` → `.harness/rules/00-core.md`,
> `05-insight-index.md`, `50-singbox-cli.md`, `70-doc-size.md`, `85-design-discipline.md`.
> Memory read: `.harness/insight-index.md` (line 12 = this defect; line 14 = the auto-elevate hazard,
> honoured throughout §4), `docs/dev-map.md`.
> Base commit: `d879ab3`. **Not committed, not pushed** — the owner handles delivery.

---

## Summary

`systemd/sing-box-rules-update.service:7` now names the binary this project actually installs
(`/usr/local/bin/sc`) instead of the one it has never installed (`/usr/local/bin/proxy`), so the
weekly `.srs` auto-update advertised in both READMEs can execute for the first time. One bullet was
added to `CHANGELOG.md`'s `[Unreleased] / 修复` section carrying the defect, the fix, the required
user action and what to expect after the upgrade. **No other tracked file was touched**: no
`install.sh`, no `bin/sc`, no `uninstall.sh`, no other unit, no README, no new unit directive, no new
test file, no `verify_all` wiring. `verify_all` is delta-0 with no FAIL.

---

## Files changed

- `systemd/sing-box-rules-update.service` — line 7 only:
  `ExecStart=/usr/local/bin/proxy update-rules` → `ExecStart=/usr/local/bin/sc update-rules`.
  Diff shape: **1 insertion(+), 1 deletion(-)** (V-3). Lines 1-6 and the terminating newline are
  byte-identical; no directive added, no `[Install]` section, no second `ExecStart=`.
- `CHANGELOG.md` — one new `- ` bullet at line 15, immediately after the existing last `修复` bullet
  (line 14, the T-01 installer entry), **no blank line between 14 and 15** (local precedent: 13 and 14
  are adjacent), blank line 16 before `## [0.1.0]` preserved. Simplified Chinese only. Diff shape:
  **1 insertion(+), 0 deletions(-)**. `### 新增` untouched, no heading added, nothing reordered.
- `docs/features/fix-rules-update-execstart/04_DEVELOPMENT.md` — this document (new).

**Pre-existing, not mine:** `docs/tasks.md` was already modified in the working tree at baseline (the
PM's T-09 board row, `_(none)_` → the T-09 line). Recorded here so the reviewer does not attribute it
to this stage; I did not touch it.

### The exact edit (design §2.1)

```diff
--- a/systemd/sing-box-rules-update.service
+++ b/systemd/sing-box-rules-update.service
@@ -4,4 +4,4 @@ After=network-online.target sing-box.service

 [Service]
 Type=oneshot
-ExecStart=/usr/local/bin/proxy update-rules
+ExecStart=/usr/local/bin/sc update-rules
```

Post-change file in full (`cat -A`, `$` = end of line — BC-12 hygiene: no trailing whitespace on any
line, exactly one terminating `\n`):

```
[Unit]$
Description=Update sing-box rule sets$
After=network-online.target sing-box.service$
$
[Service]$
Type=oneshot$
ExecStart=/usr/local/bin/sc update-rules$
```

---

## Safety posture actually observed (AC-11, insight-index line 14)

`/usr/local/bin/sc` **and** `/usr/local/bin/sing-box` are both installed on this host, so the
auto-elevate hazard was live, not theoretical. During this stage:

- **No** execution, import, or subprocess invocation of `bin/sc` in any form. No `./bin/sc`, no
  `python3 -c "import sc"`, no `runpy`.
- **No** `systemctl` write command (`start` / `stop` / `enable` / `disable` / `daemon-reload` /
  `reset-failed`), no `install.sh` / `uninstall.sh` execution, no root, no live-system mutation.
- The only command that touched `bin/sc` at all was `verify_all.sh` B.1's `python3 -m py_compile bin/sc`
  — per gate §6 Q-D4, `py_compile` compiles to bytecode without executing module-level code, so the
  auto-elevate at `bin/sc:77-78` never fires; the `bin/__pycache__` it writes is removed by
  `verify_all.sh:59` and is a repo-local artifact, not a live-system mutation.
- `systemd-analyze verify` parses and `stat`s; it never executes `ExecStart` and needs no root.
- No `systemctl show` / `list-timers` D-Bus read was needed at this stage either (those belong to QA's
  optional BC-11 evidence, design §8.2); nothing here required them.
- All scratch files live in the session scratchpad, never in the repo.

Per gate §6 Q-D6, the dev host's residual `failed` unit state was **not** cleared and the unit was
**not** started: `failed` does not block the next activation, and starting it would restart the
developer's real sing-box via `bin/sc:1141-1143`.

---

## Verification performed (design §12 V-1…V-9) — all read-only

### V-1 · One `ExecStart=`, exact value · AC-1, B-1, BC-12 — **PASS**

```
$ grep -c '^ExecStart=' systemd/sing-box-rules-update.service
1
$ grep -n '^ExecStart=' systemd/sing-box-rules-update.service
7:ExecStart=/usr/local/bin/sc update-rules
$ [ "$(grep '^ExecStart=' …)" = "ExecStart=/usr/local/bin/sc update-rules" ] → V-1 string-equality: OK
$ grep -c '[[:space:]]$' systemd/sing-box-rules-update.service
0            # no trailing whitespace on any line
$ tail -c 1 systemd/sing-box-rules-update.service | od -c
0000000  \n   # exactly one terminating newline
```

Absolute path, literal, no `/usr/bin/env`, no quoting, no variable, no shell metacharacter.

### V-2 · The path literal is byte-identical across every in-repo site · AC-2 — **PASS**

| Site | Line read this stage |
|---|---|
| `install.sh:376` (installs the CLI) | `install -m 755 "$ARTIFACT_DIR/bin/sc" /usr/local/bin/sc` |
| `install.sh:438` (sudoers `NOPASSWD:`, block `437-441`) | `$INSTALL_USER ALL=(ALL) NOPASSWD: /usr/local/bin/sc` |
| `install.sh:456` (installer's own step-6 call) | `if /usr/local/bin/sc update-rules >>"$LOG_SINK" 2>&1; then` |
| `install.sh:479` (installer's own step-7 call) | `if /usr/local/bin/sc reload >>"$LOG_SINK" 2>&1; then` |
| `bin/sc:78` (import-time auto-elevate, `77-78`) | `os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])` |
| `bin/sc:1217` (OpenRC periodic script) | `script.write_text("#!/bin/sh\n/usr/local/bin/sc update-rules\n")` |
| **the unit, line 7 (changed)** | `ExecStart=/usr/local/bin/sc update-rules` |

The command string the unit now runs (`/usr/local/bin/sc update-rules`) is byte-identical to the one
the OpenRC periodic script writes (`bin/sc:1217`) and to the one the installer runs
(`install.sh:456`). Copied as a literal, **not** factored out — design §3's seam tests, re-checked and
unchanged: no intermediate state is passed between the unit asset and the Python-generated shell
script, and neither side decides anything.

### V-3 · Nothing else in the unit moved · AC-4, B-2, R-6 — **PASS**

```
$ git diff --stat -- systemd/sing-box-rules-update.service
 systemd/sing-box-rules-update.service | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --numstat -- systemd/sing-box-rules-update.service
1	1	systemd/sing-box-rules-update.service
```

Exactly the shape the design mandates. No `ConditionPathExists=`, no `Wants=network-online.target`,
no `Environment=`, no `User=`, no `Restart=`, no `SuccessExitStatus=`, no `ExecStartPre/Post=`, no
`[Install]` section — gate §6 Q-D1 obeyed literally.

### V-4 · Stale-path sweep · AC-3, B-7, **condition C-3** — **PASS (as corrected by C-3)**

`git grep -n '/usr/local/bin/proxy'` after the change:

- **Shipped code: exactly ONE hit — `uninstall.sh:133`**
  `rm -f /usr/local/bin/sc /usr/local/bin/proxy`, under the comment at `uninstall.sh:132`
  (`# Also remove legacy `proxy` filenames left from pre-rename installs.`).
  **Disposition: deliberately retained.** It is a removal of a legacy filename, not an invocation.
- **The sudoers twin, reported separately as C-3 requires:** `uninstall.sh:134` is
  `rm -f /etc/sudoers.d/sc /etc/sudoers.d/proxy` — a **different literal** (`/etc/sudoers.d/proxy`),
  which does *not* match `/usr/local/bin/proxy`. **Disposition: deliberately retained**, same legacy
  cleanup. The design's "two shipped-code hits" expectation was the imprecision the gate corrected;
  the run matches the corrected expectation and **is not recorded as a defect**.
- **`CHANGELOG.md:15`** now contains the literal as **prose** — the changelog bullet names the wrong
  path as part of describing the defect, which design §10 content requirement (1) mandates. Not code,
  not an invocation. Flagged explicitly so nobody reads it as a missed occurrence.
- All remaining hits are documentation/memory prose: `.harness/insight-index.md:12`,
  `docs/batches/default/BATCH_PLAN.md:17,58`, and eight lines inside
  `docs/features/_archived/{config-degrade-missing-rulesets,install-enable-start-split}/*`. These are
  historical records of the defect; nothing invokes anything.
- **No other invocation of a `proxy` executable exists in shipped code.** Sweeping non-Markdown
  shipped files for `proxy` used as a command returns only `bin/sc:122`, `:1075` and `:1298` — the
  GNOME **system proxy** UI string, its `print`, and the `sysproxy` help line. None is an executable
  named `proxy`.

### V-5 · Diff boundary · AC-8, AC-10, B-10 — **PASS**

```
$ git status --porcelain
 M CHANGELOG.md
 M docs/tasks.md                                  ← pre-existing at baseline (PM board row), not mine
 M systemd/sing-box-rules-update.service
?? docs/features/fix-rules-update-execstart/       ← this task's stage docs (untracked folder)
$ git diff --name-only
CHANGELOG.md
docs/tasks.md
systemd/sing-box-rules-update.service
```

Explicit byte-unchanged assertion (`git diff --quiet -- <file>`), each one confirmed **unchanged**:
`bin/sc`, `install.sh`, `uninstall.sh`, `systemd/sing-box.service`,
`systemd/sing-box-rules-update.timer`, `README.md`, `README.zh-CN.md`,
`.harness/scripts/verify_all.sh`, `docs/dev-map.md`.

### V-6 · Unit still parses; the discriminator appears · AC-13 — **PASS**

`systemd-analyze` **is** available here: `systemd 255 (255.4-1ubuntu8.16)`, `/usr/bin/systemd-analyze`.
Pre-change file recovered per gate §6 Q-D3 with `git show HEAD:systemd/sing-box-rules-update.service`
into a scratch path whose basename is still `sing-box-rules-update.service`.

**Before** (scratchpad copy of `HEAD`):

```
$ systemd-analyze verify …/pre/sing-box-rules-update.service
sing-box-rules-update.service: Command /usr/local/bin/proxy is not executable: No such file or directory
EXIT=1
```

**After** (the working-tree file):

```
$ systemd-analyze verify systemd/sing-box-rules-update.service
EXIT=0
```

Exactly the expected discriminator: the pre-change run names `/usr/local/bin/proxy` as not executable
(because `/usr/local/bin/sc` exists on this host and `proxy` does not); the post-change run emits no
output at all and exits 0. No `sing-box.service` / `network-online.target` not-found notice was
emitted by this systemd version in either run, so there is no pre-existing noise to discount.

### V-7 · `verify_all` unchanged · AC-12, **condition C-4** — **PASS, delta 0, no FAIL**

See the dedicated section below.

### V-8 · Installer ordering — the upgrade path genuinely repairs a broken host · AC-5, B-5 — **PASS**

Re-read `install.sh:403-409` (and `:1-13`, `:435-465`) this stage:

```
403  # ----------------- step 4: service -----------------
404  t step4
405  if [ "$INIT_SYS" = "systemd" ]; then
406      install -m 644 "$ARTIFACT_DIR/systemd/sing-box.service" /etc/systemd/system/
407      install -m 644 "$ARTIFACT_DIR/systemd/sing-box-rules-update.service" /etc/systemd/system/
408      install -m 644 "$ARTIFACT_DIR/systemd/sing-box-rules-update.timer" /etc/systemd/system/
409      systemctl daemon-reload
410  else
```

- `install.sh:9` is `set -euo pipefail` (confirmed by reading lines 1-13).
- A scan of lines 403-409 for `exit`, `return`, `||`, `&&`, `trap` or a subshell returns **nothing**:
  one `if` block, three plain `install -m 644` calls, then the unconditional `daemon-reload` at 409.
  The only way not to reach 409 is an `install` failure, which aborts the installer loudly (R-3).
- Ordering: step 4 (405-409) runs **before** the two failure-tolerant steps — step 6 rulesets at
  `install.sh:456` and step 7 enable/start at `install.sh:465+` — so unit installation and the reload
  are independent of ruleset/config success. That is the T-01 property B-5 leans on, and it holds.

No installer change was needed or made (design §7.3).

### V-9 · The `CHANGELOG.md` entry · AC-9, B-9 — **PASS**

- **One** new bullet, at **line 15**, i.e. immediately after the existing last `修复` bullet (line 14).
- Blank-line shape measured after the edit: `13:<text> 14:<text> 15:<text> 16:<BLANK> 17:## [0.1.0]`
  — no blank line between 14 and 15 (gate §6 Q-D2 local precedent), existing blank line before
  `## [0.1.0]` kept.
- `### 新增` untouched; no heading added; no bullet reordered; `git diff --numstat -- CHANGELOG.md`
  = `1  0` (one insertion, zero deletions).
- Simplified Chinese only (Q6 (a)); the file stays single-language. No new runtime string, so no
  translation key and no README change — bilingual parity (B-8) is unaffected.
- All four load-bearing facts of design §10 are carried: **(1)** the defect — `ExecStart` pointed at
  `/usr/local/bin/proxy`, a file this project never installs, so every weekly trigger failed
  `203/EXEC` and the advertised auto-update never ran on any systemd host (plus the visible
  `systemctl --failed` artifact); **(2)** the fix — the unit now runs `/usr/local/bin/sc update-rules`;
  **(3)** the user action — re-run the install one-liner or `sudo ./install.sh`, which reloads systemd
  itself, so no manual unit edit and **no timer restart**; **(4)** what to expect — no catch-up run on
  a host whose timer has been triggering (first corrected run at the next weekly point + ≤1 h random
  delay), `sudo systemctl start sing-box-rules-update.service` to run one now **with the note that it
  restarts sing-box when the service is running**, and
  `sudo systemctl reset-failed sing-box-rules-update.service` to clear the leftover `failed` entry,
  which otherwise clears on the next successful run.
- **C-5 applied to the user-facing text**: the "no immediate run" claim is written **conditionally**
  (「在定时器一直正常触发的机器上不会立刻补跑一次…若定时器此前被停用过、时间戳已经过期，
  `Persistent=true` 会在安装结束后立刻补跑一次」), never as an unqualified "never fires immediately".
  The third path C-5 names (`sc update-interval` to a shorter cadence) is left to `07_DELIVERY.md`,
  which is where C-5 binds; the changelog bullet is already the longest in the file and naming the
  main case plus the stale-stamp exception is the honest minimum for a user-facing note.

---

## verify_all result

Command: `bash .harness/scripts/verify_all.sh` (repo root). Baseline captured **before** any edit, on
the current tree, per gate §6 Q-D5.

| Run | When | PASS | WARN | FAIL | SKIP | exit |
|---|---|---|---|---|---|---|
| Baseline | before the edit (`d879ab3` tree + PM's `docs/tasks.md` row + stage docs 01-03) | 16 | 0 | 0 | 2 | 0 |
| After code+changelog | unit file + `CHANGELOG.md` edited | 16 | 0 | 0 | 2 | 0 |
| **Final, all stage documents present** | + `04_DEVELOPMENT.md` | **16** | **0** | **0** | **2** | **0** |

**Delta: 0 across PASS / WARN / FAIL / SKIP. No FAIL. Exit code 0 (green).**

Per-check result, identical in all three runs:
`A.1 PASS · A.2 PASS · B.1 PASS · B.2 SKIP · B.3 SKIP · E.1 PASS · E.2 PASS · E.3 PASS · E.4 PASS ·
E.4b PASS · E.5 PASS · E.6 PASS · F.1 PASS · F.2 PASS · F.3 PASS · F.4 PASS · F.5 PASS · F.6 PASS`

The two checks C-4 warned about:

- **F.6 (active task docs ≤500 lines)** — still PASS. Measured this stage:
  `01` = 327, `02` = **499** (untouched — I made no amendment to it; there was no DESIGN DRIFT to
  record, so the 499-line cap was never approached), `03` = 321, `PM_LOG` = 125, and this document is
  well under the cap. `02_SOLUTION_DESIGN.md` is byte-unchanged.
- **E.6 (`## Adversarial tests` in every `06_TEST_REPORT.md`)** — still PASS. No
  `06_TEST_REPORT.md` was created for this task; no stub that could break the check was written.
  QA must include the literal `## Adversarial tests` heading when it writes that file.

B.1's `python3 -m py_compile bin/sc` passes because `bin/sc` is byte-unchanged.

---

## Design drift

**None.** The implementation is the design's §2.1 edit verbatim plus the §10 `CHANGELOG.md` bullet,
and nothing else. No forbidden directive was added, no out-of-scope file touched, no abstraction
invented across the systemd/OpenRC invocation paths (§3), no `verify_all` wiring, no test file
(`.harness/rejected-decisions.md § ruleset-unit-tests-in-t02`). The one-line shape is the correct
granularity under `.harness/rules/85-design-discipline.md` and was left alone.

Two deliberate, non-drift precision notes for the reviewer:

1. **V-4's expectation was executed as corrected by gate condition C-3** (one shipped-code hit, not
   two), not as literally written in design §12. That is the gate's instruction, not a deviation I
   chose, and the design is correct in substance.
2. **The C-5 conditional phrasing was applied to the `CHANGELOG.md` bullet as well as to the delivery
   text.** C-5 binds `07_DELIVERY.md`; the changelog makes the same user-facing claim, so leaving it
   unqualified would have shipped exactly the sentence C-5 forbids. Content still matches design §10
   fact (4); only the qualification was added.

---

## Conditions carried forward to QA / delivery (reported, not fixed — as instructed)

- **C-1 · F-1 · service-environment residual.** The timer path will run `sc update-rules` inside a
  systemd service environment for the first time. (a) `bin/sc:31` is `SB_BIN = "sing-box"`, a bare
  **PATH lookup** — benign here because systemd's compiled-in default service `PATH` includes
  `/usr/local/bin`, where `install.sh` puts the binary; safe, but safe by luck rather than by design.
  (b) **Encoding exposure:** `bin/sc:1089` prints `f"  ↓ {fname} ... "` unconditionally before any
  download, and `bin/sc:1136/1142` print `→ Restarting sing-box ...`; on a zh host every `t()` string
  is non-ASCII. A system unit inherits no login-shell locale, and on **Python 3.6** (the documented
  floor, `.harness/rules/50-singbox-cli.md:97-99`) an unset/POSIX locale makes `sys.stdout` ASCII and
  that first `print` raises `UnicodeEncodeError`. Python 3.7+ is immune (C-locale coercion), so the
  exposed population is Ubuntu 18.04 / CentOS-7-era hosts with no locale in the manager environment.
  **Not remedied here** — every available remedy needs either an `Environment=` directive that B-2
  forbids or a `bin/sc` change the owner placed out of scope. `07_DELIVERY.md` must carry it as a
  known residual with a follow-up disposition, the way R-1 is carried. PM routes.
- **C-2 · F-2 · uninstaller residue.** `uninstall.sh:113-130` disables the timer, deletes the three
  unit files and the `.timer.d/` drop-in and reloads the manager, but never runs
  `systemctl reset-failed`, so a unit that had entered `failed` can linger in `systemctl --failed`
  after uninstall. Re-read this stage; still true. No AC binds it, so `07_DELIVERY.md` must carry it
  as an explicit follow-up row.
- **R-1 · weekly restart of sing-box on an unchanged run.** `bin/sc:1141-1143` — when nothing was
  gained and `is_running()`, `cmd_update_rules` still calls `restart_service()` (a plain
  `systemctl restart sing-box`, `bin/sc:834-838`). Once this fix makes the timer live, every host
  gains a weekly connection drop, landing 00:00–01:00 local Monday (`OnCalendar=weekly` +
  `RandomizedDelaySec=1h`). Pre-existing `bin/sc` behaviour owned by T-02 and out of scope here;
  reported so users do not discover it first. AC-14 binds it to `07_DELIVERY.md`; PM files the row.

---

## Open issues for review

1. `CHANGELOG.md:15` contains the string `/usr/local/bin/proxy` as prose (V-4). Intentional and
   required by design §10 fact (1); listed so no automated stale-path sweep in review or QA reports it
   as a miss.
2. `docs/tasks.md` is modified in the working tree from before this stage (PM's board row). It is
   outside this task's stated diff boundary as written in B-10, but it is not my edit and I did not
   revert it. PM/reviewer should decide whether it rides along with the delivery commit.
3. End-to-end proof that the timer now runs is out of reach inside this task by design (gate §6 Q-D7):
   the evidence is decomposed into V-1/V-2 (literal match at all seven sites), V-6 (`systemd-analyze
   verify` discriminator), V-8 (installer copies + reloads with no reachable early exit) and the
   mechanical reload-sufficiency argument (design §7, gate §2.1). An actual triggered run is a
   post-release observation.
4. Design §12's optional read-only D-Bus checks (`systemctl list-timers`,
   `systemctl show -p LastTriggerUSec …`) were **not** run at this stage — they are QA's BC-11
   evidence, not a developer gate, and nothing in V-1…V-9 depends on them.

---

## Dev-map updates

**None required.** No file was added, moved or removed; no module or folder was created. The layout in
`docs/dev-map.md:9-20` (which already lists `systemd/` as holding
`sing-box.service, sing-box-rules-update.{service,timer}`, and `CHANGELOG.md` as user-visible changes
written in Chinese) remains accurate byte-for-byte. `docs/dev-map.md` is confirmed unchanged in V-5.

---

## Insight to surface

None. Nothing surfaced during implementation that beat a reasonable prior: the defect, the correct
literal, the reload-sufficiency mechanism and the auto-elevate hazard were all already established and
evidenced in `01`–`03`, and `.harness/insight-index.md:12` already records the defect itself. The one
new fact of the stage — `systemd-analyze verify` exits 0 with no output on the corrected unit and
exits 1 naming `/usr/local/bin/proxy` on the old one — is a verification observation, derivable in
seconds, not a project truth worth one of the index's 30 lines.

---

## Verdict

**READY FOR REVIEW.**

The diff is exactly the approved design: one line in `systemd/sing-box-rules-update.service`
(1 insertion / 1 deletion) plus one Simplified-Chinese `修复` bullet in `CHANGELOG.md`
(1 insertion / 0 deletions), plus this stage document. All nine verification checks V-1…V-9 were
executed read-only, with no execution or import of `bin/sc`, no `systemctl` write command, no
installer/uninstaller run and no root; `verify_all` is delta-0 with no FAIL and exit 0. Gate
conditions C-3, C-4 and C-5 are discharged here; C-1, C-2 and R-1 are reported for `07_DELIVERY.md`
as instructed. Not committed and not pushed — delivery is the owner's.
