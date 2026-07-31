# 03 — Gate Review · T-09 `fix-rules-update-execstart`

> Mode: **full** · Deferred-human (defer, do not ask) · 2026-07-31
> Upstream read, never edited: `01_REQUIREMENT_ANALYSIS.md` (READY), `02_SOLUTION_DESIGN.md` (READY).
> Rules loaded: `00-core`, `05-insight-index`, `50-singbox-cli`, `70-doc-size`, `80-delivery-policy`,
> `85-design-discipline`. Memory: `.harness/insight-index.md`, `.harness/rejected-decisions.md`.
> Every code claim below was re-read from source this stage; nothing is inherited from 01/02.
>
> Authored by `harness-kit:gate-reviewer` (read-only tool set); transcribed verbatim by the PM
> orchestrator, which added no content of its own.

---

## 1. Independent verification performed

| Upstream claim | Source re-read | Result |
|---|---|---|
| Defect at `systemd/sing-box-rules-update.service:7` | file read whole (7 lines) | Confirmed: `ExecStart=/usr/local/bin/proxy update-rules`, single `ExecStart`, `Type=oneshot`, no `[Install]`, no `User=`/`Environment=` |
| Installer installs CLI as `/usr/local/bin/sc` | `install.sh:376` | Confirmed |
| Sudoers `NOPASSWD: /usr/local/bin/sc` | `install.sh:437-441` | Confirmed |
| Auto-elevate target | `bin/sc:77-78` | Confirmed (`os.execvp("sudo", ["sudo","/usr/local/bin/sc"]+argv)`) |
| Installer's own two call sites | `install.sh:456`, `:479` | Confirmed |
| Unit install + reload, systemd branch only, before the failure-tolerant steps | `install.sh:405-409` vs `:456`, `:470-486` | Confirmed; one `if` block, no `\|\|`, no subshell, no early exit under `set -euo pipefail` (`install.sh:9`) |
| Remote path serves the unit from `REF="main"` | `install.sh:11-13`, `:317-329` (unit at `:321`) | Confirmed |
| Timer already correct | `systemd/sing-box-rules-update.timer:1-10` | Confirmed; no `Unit=`, so the link is the implicit same-name `.service` |
| OpenRC periodic script already correct | `bin/sc:1210-1218` (write at `:1217`) | Confirmed |
| Timer-restart precedent is timer-only | `bin/sc:1167-1179` | Confirmed |
| Unconditional weekly restart (R-1) | `bin/sc:1141-1143` + `restart_service` `:834-838` + `is_running` `:864-866` | Confirmed: `systemctl restart sing-box` whenever the service is active, gained or not |
| Uninstaller: legacy cleanup, no `reset-failed` | `uninstall.sh:113-134` | Confirmed |
| Neither README file-location table lists the `.service` path | `README.md:153-170`, `README.zh-CN.md:155-170` | Confirmed; the timer and the `.timer.d` override are listed, the `.service` is not |
| `CHANGELOG.md` is zh-only; last `修复` bullet is line 14 | `CHANGELOG.md:1-37` | Confirmed; `:11` T-02, `:13` Clash-API, `:14` T-01 |
| Auto-elevate hazard is live on this host | listed `/usr/local/bin/` | Confirmed: `/usr/local/bin/sc` **and** `/usr/local/bin/sing-box` both present |
| `.harness/rejected-decisions.md § ruleset-unit-tests-in-t02` defers the harness to T-07 | file read | Confirmed |
| Insight index contradicts nothing in the design | 8 entries read | Confirmed; line 12 is this defect, line 14 is the auto-elevate hazard the design honours in §12 |

**Repo-wide sweep, run this stage** (`/usr/local/bin/proxy`, plus `proxy` as a command):
shipped-code hits are exactly **two** — `systemd/sing-box-rules-update.service:7` (the defect) and
`uninstall.sh:133` (deliberate legacy cleanup). `uninstall.sh:134` removes `/etc/sudoers.d/proxy`, a
*different* literal. All other hits are `docs/` and `.harness/` prose. See F-3.

---

## 2. The three load-bearing claims, checked on the mechanism (not on the citation)

### 2.1 Q1 — is `systemctl daemon-reload` sufficient? **The design is CORRECT. No escalation.**

Verified independently against systemd semantics, not merely against the in-repo precedent:

1. The manager does **not** auto-detect changed unit files; it caches the parsed fragment and warns
   ("unit file changed on disk"). The service unit stays *loaded* because the timer references it, and a
   `failed` unit is pinned in memory (not garbage-collected). So a reload is genuinely **necessary** —
   §7.1 item 2 is right, and `install.sh:409` performs it unconditionally on the systemd branch.
2. `daemon-reload` re-reads all fragments from disk and rebuilds the dependency tree while preserving
   runtime state. After it, the in-memory `[Service]` for the unit **is** the new file.
3. `Type=oneshot` with default `RemainAfterExit=no` leaves no process and no queued job between
   triggers. The "settings apply at next start" caveat therefore cannot bite: the next activation is a
   fresh `execve` against the reloaded fragment.
4. The timer→service edge is resolved **by unit name at elapse time** (`[Timer]` has no `Unit=`, so the
   implicit target is `sing-box-rules-update.service`). Nothing about that edge is snapshotted when the
   timer starts, so re-arming the timer cannot make a `[Service]` change "more effective". Restarting
   the timer would in fact be the *wrong* unit to touch.
5. `failed` is an inactive state; a new start job runs from it normally. The default rate limit
   (`DefaultStartLimitIntervalSec=10s` / `DefaultStartLimitBurst=5`, no `StartLimit*` in the unit) is
   unreachable at a weekly cadence. So the ~100% of hosts sitting in `failed` need no intervention.

The in-repo precedent cited (`bin/sc:1167-1179` restarts *only the timer* and *only* after writing an
`OnCalendar=` override; `install.sh:405-409` rewrites all three units and restarts nothing, including for
the long-running `sing-box.service` — the harder case) was re-read and does bound the claim the way the
design says. **`install.sh` correctly stays out of the diff. The task's value does not collapse.**

### 2.2 BC-11 — the timer stamp advances on elapse, not on service success. **CORRECT.**

systemd's timer implementation advances `last_trigger` and touches
`/var/lib/systemd/timers/stamp-<timer>` **immediately after the start job is successfully enqueued**, then
moves the timer to `running`. A `203/EXEC` failure occurs in the forked child, long after enqueue; the
unit itself loaded and parsed fine (the *path* was wrong, not the syntax), so the job was always
enqueued. Every weekly elapse since installation therefore advanced the stamp exactly as on a healthy
host, the computed next elapse is in the future, and neither the fix nor `daemon-reload` produces a
catch-up run. The no-stamp case (fresh host) also yields a future elapse — the base falls back to the
timer unit's own activation timestamp. **The claim is safe to ship**, and `systemctl show -p
LastTriggerUSec --value sing-box-rules-update.timer` (§8.2) is the authoritative read-only proof.

The two stated exceptions are real and correctly reasoned — in particular exception 1 is *not*
hypothetical: `install.sh:486` starts the timer after `install.sh:482` started sing-box, so a stale-stamp
host gets a catch-up run that gains nothing and therefore hits `bin/sc:1141-1143` → `systemctl restart
sing-box` moments after the installer exits. Good catch by the architect. See **F-6** for a third path
the exception list does not name.

### 2.3 §9 repair recipe — commands correct, caveat correct and adequately flagged.

`systemctl cat` / `systemctl show -p ExecStart --value` / `list-timers` / `journalctl` are read-only;
`reset-failed` clears bookkeeping only; `start` on a `Type=oneshot` unit blocks until the command exits
and propagates its status. The restart caveat is **true**: `cmd_update_rules` calls `restart_service()`
on the gained path (`bin/sc:1135-1137`) *and* on the nothing-gained path (`:1141-1143`) whenever
`is_running()`; `restart_service()` is a plain `systemctl restart sing-box` (`:834-838`). The only run
that does **not** restart is a total failure (`sys.exit` at `:1139-1140` precedes the check). Printing
the caveat next to the command, and noting `sudo sc update-rules` is the same code path, is adequate.
`OnCalendar=weekly` resolves to Mon 00:00 local, so the recurring drop lands 00:00–01:00 Monday — worth
stating in delivery, it materially softens R-1.

---

## 3. The scope ruling the PM asked for

**`CHANGELOG.md` stays in the diff. The architect's §10 call is UPHELD.** Reasons, in the order they bind:

1. B-9/B-10 are upstream and `READY`. Dropping the entry would be a *silent narrowing* of an approved
   requirement — under rule 85 §"Recording the call" ("never silently drop a requested outcome") and the
   downstream-cannot-edit-upstream red line, the only legal way to remove it is a rollback, not a design
   choice. There is no defect in B-9 to roll back for.
2. Rule 85's counter-rule forbids **new files, speculative generality, and widened scope**. A bullet in
   the file the project already designates as the home for user-visible changes is none of those.
   `docs/dev-map.md:17` states it outright: `CHANGELOG.md ← user-visible changes (written in Chinese)`,
   and `.harness/rules/50-singbox-cli.md:66` repeats it.
3. The owner's four do-not-touch files are exactly the four with a competing task owner or behavioural
   risk (`install.sh` T-01, `bin/sc` T-02, `uninstall.sh`, the other two units). `CHANGELOG.md` has
   neither. "One line in one unit file" describes the **code** change, and the code change is one line.
4. This fix uniquely **requires a user action** (re-run the installer) and leaves a visible artifact on
   every existing host (`systemctl --failed`). A defect with a required user action and no changelog
   record is the one shape a changelog exists to prevent. All three landed fixes in this pool wrote a
   `### 修复` bullet (`CHANGELOG.md:11`, `:13`, `:14`).
5. zh-only is right and independently corroborated: `dev-map.md:17` says the file is written in Chinese;
   bilingual parity binds runtime strings and the paired READMEs (`50-singbox-cli.md:88-90`), not this file.

**Creep in the other direction: none found.** `git`-visible boundary is unit file + `CHANGELOG.md` +
stage docs. No installer change, no `bin/sc` change, no uninstaller change, no README change, no new
test file, no `verify_all` wiring, no new unit directive, no shared-constant abstraction. §2.1's explicit
forbidden-directive list plus V-3's one-line-diff assertion make R-6-style "helpfulness" a hard
verification failure rather than a review opinion — that is the correct mechanism, not a hope.

**Under-delivery: none material.** Every behavior B-1…B-10 has a design home (§2.1, §5.1, §6.2, §7, §9,
§10, §12) and every AC-1…AC-14 has a V-check or a named delivery obligation. The one traceability hole
is F-2 below.

---

## 4. Audit — 8 dimensions

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | 10 numbered behaviors, 13 boundary conditions and 14 acceptance criteria, every one of which is decidable by reading a file or a `git diff`; the nine open questions each carry an evidence-backed recommendation *and* a proceeding assumption, and the one with teeth (Q1) carries an explicit escalation trigger that the design was obliged to answer before proceeding. |
| 2 | Design completeness | **WARN** | Every in-scope behavior is covered and the design's real work (the three determinations, §7/§8/§9) is done properly — but the §5.1 unit↔CLI contract enumerates uid, argv, exit status and stream behaviour and **omits the process environment**, which is the single dimension that differs between the already-exercised manual path and the never-once-executed timer path (F-1). |
| 3 | Reuse correctness | **PASS** | All nine reuse rows were re-read at their cited lines and every symbol exists with the claimed semantics (`cmd_update_rules`, `_fetch_to_temp`, `restart_service`, `is_running`, `cmd_update_interval`, `install.sh` step 4, the `RAW_BASE` fetch list, the uninstaller's legacy cleanup). Nothing existing was missed: the correct invocation string genuinely already exists at `bin/sc:1217` and is correctly copied rather than factored out. |
| 4 | Risk coverage | **WARN** | R-6 (developer adds a directive) and R-7 (creep into `install.sh`) are precisely the two real creep vectors and both are mechanically countered by V-3/V-5; R-1 correctly identifies the one behaviour that genuinely changes for users. Missing: the execution-environment failure mode (F-1) and a third immediate-run path (F-6). |
| 5 | Migration safety | **PASS** | No schema, no state file, no backfill; the unit is a leaf artifact nothing else parses. Version skew is analysed in both directions and both are benign. Rollback is a `git revert` plus the cheaper per-host `systemctl disable --now sing-box-rules-update.timer`, and the design correctly declines a feature flag for a path that has never worked. |
| 6 | Boundary handling | **WARN** | BC-1…BC-13 all have a designed answer, including the awkward ones (failed state, `.timer.d` override survival, OpenRC no-op, concurrency, no-config, no-restart). The gap is the service-environment boundary (F-1), which no BC row asks about. |
| 7 | Test feasibility | **WARN** | All 14 AC are verifiable statically and unprivileged; V-1…V-9 are confirmed read-only and **none executes or imports `bin/sc`** — see §5 Q-D4 for the one near-miss and why it is safe. Two defects: V-4's assertion is literally false as written (F-3) and AC-12's delta-0 is fragile against the pipeline's own documents (F-5). |
| 8 | Out-of-scope clarity | **PASS** | §15's nine items plus §2's untouched list plus §16's question-by-question carry-forward leave no room for interpretation, and V-5 turns the boundary into an assertion rather than an instruction. The `85`-mandated "the owner's shape is already right, and here is why" statement is present and substantiated (§3's three seam tests), not asserted. |

---

## 5. Findings

**F-1 · WARN · owner: solution-architect (design completeness / risk coverage) · report-only, must reach delivery.**
The timer path will execute `sc update-rules` in a **systemd service environment** for the first time in
the project's history, and no document analyses that environment. Two concrete dependencies exist:
(a) `bin/sc:31` is `SB_BIN = "sing-box"` — a bare **PATH lookup**. Checked: systemd's compiled-in default
service `PATH` includes `/usr/local/bin`, so `sing-box check` inside `generate_config()` resolves. Safe,
but it is safe by luck, not by design, and nobody had verified it.
(b) **Encoding.** `cmd_update_rules` prints `f"  ↓ {fname} ... "` unconditionally at `bin/sc:1089`, before
any download, and `bin/sc:1136/1142` print `→ Restarting sing-box ...`; on a zh host every `t()` string is
non-ASCII. A system unit inherits no login-shell locale, and `LANG` reaches it only if the manager
environment carries one. On **Python 3.6** — the floor this project documents and defends
(`.harness/rules/50-singbox-cli.md:97-99`) — an unset/POSIX locale makes `sys.stdout` ASCII and that first
`print` raises `UnicodeEncodeError`. Python 3.7+ is immune (C-locale coercion), so the exposed population
is Ubuntu 18.04 / CentOS-7-era 3.6 hosts with no locale in the manager environment.
Severity is **WARN, not FAIL**: the crash would occur before any fetch, so nothing is written and nothing
is corrupted; the unit fails loudly in the journal with a traceback, which is strictly more informative
than today's `203/EXEC`; and on every affected host the fix is still a net improvement. But it is a way
the fix can *appear not to work* on exactly the hosts the project promises to support, and it is not
mentioned anywhere. I do **not** propose a remedy — any remedy touches a directive B-2 forbids or a file
the owner placed out of scope, so the routing decision is the PM's/owner's, not mine.

**F-2 · WARN · owner: requirement-analyst (traceability) · condition C-2.**
01 §8 Q9 states the uninstaller's missing `systemctl reset-failed` is carried by "B-7 and AC-3". It is
not: B-7/AC-3 are scoped to occurrences of `/usr/local/bin/proxy` and say nothing about `reset-failed`.
AC-14 enumerates three consequences (BC-10, BC-7, BC-11) and does not include it either. Design §15 item 3
mentions it only in an out-of-scope list, which creates no delivery obligation. **As written, the one
report-only item the owner explicitly asked to preserve has no acceptance criterion binding it to
`07_DELIVERY.md` and can evaporate.** R-1 by contrast *is* bound (AC-14 + §13 R-1 + §14 item 5).

**F-3 · WARN · owner: solution-architect (verification precision) · condition C-3.**
V-4 asserts that `git grep -n '/usr/local/bin/proxy'` yields shipped-code hits "exactly `uninstall.sh:133`
and `uninstall.sh:134`". Re-run this stage: `uninstall.sh:134` is `rm -f /etc/sudoers.d/sc
/etc/sudoers.d/proxy` and does **not** contain that literal. Post-fix the correct expectation is **one**
shipped-code hit (`uninstall.sh:133`). E-6/01 §2 carries the same imprecision ("exactly three hits").
As written, an honest QA run reports V-4 as a mismatch against a design that is actually correct in
substance.

**F-4 · WARN · owner: requirement-analyst (evidence accuracy) · non-blocking.**
E-17 says "all `B.*` build/test/lint checks are SKIP". False: `verify_all.sh:52-68` runs a real B.1 syntax
gate (`python3 -m py_compile bin/sc`, `bash -n install.sh`, `bash -n uninstall.sh`) that PASSes today;
only B.2/B.3 are SKIP, as `docs/dev-map.md:22-23` correctly states. The error is inherited from a stale
line in `.harness/rules/50-singbox-cli.md:34-36`. No consequence for this fix (B.1 stays PASS because
`bin/sc` is untouched), but it is a wrong fact in a `READY` document.

**F-5 · WARN · owner: solution-architect (test feasibility) · condition C-4.**
AC-12/V-7 assert a delta-0 `verify_all` result, and two of that gate's checks take **this pipeline's own
documents** as input: `F.6` WARNs if any active stage doc exceeds 500 lines, and `E.6` FAILs if any
`06_TEST_REPORT.md` lacks a `## Adversarial tests` heading. Measured now: `01` = 327 lines, `02` = **499
lines — one line under the cap**, `PM_LOG` = 89. Any amendment appended to `02_SOLUTION_DESIGN.md` during
development (the normal way a DESIGN DRIFT is recorded) flips F.6 PASS→WARN and fails AC-12; a
`06_TEST_REPORT.md` without the adversarial section flips E.6 PASS→FAIL, which makes `verify_all` exit 2
and blocks the commit under `.harness/rules/80-delivery-policy.md:30`. The baseline for "before" is also
undefined — it must be the current tree, and the "after" comparison must be made with all stage documents
in place.

**F-6 · WARN · owner: solution-architect (delivery-text precision) · condition C-5.**
§8.3's exception list is not exhaustive. A third path to an immediate run exists: `sc update-interval` to
a **shorter** cadence writes `.timer.d/override.conf` and restarts the timer (`bin/sc:1167-1179`); with
`Persistent=true` and a last-trigger base up to a week old, the recomputed elapse is already in the past
and fires at once — which, post-fix, means a real run and (via `bin/sc:1141-1143`) a sing-box restart.
It is user-initiated and therefore defensible, but the delivery text must not read as an unconditional
"the timer never fires immediately".

**F-7 · INFO.** §4 describes the stamp file's **mtime** as the last trigger time. systemd reads the
stamp's **atime** (it touches both). Harmless because §8.2 already prescribes the authoritative D-Bus
read (`LastTriggerUSec`); noted only so nobody builds a check on `stat -c %y`.

**F-8 · INFO.** §14 item 3(b) says remote installs serve the corrected file "from that moment, and not one
moment before". `raw.githubusercontent.com` caches for roughly five minutes; "within minutes of the push"
is the honest phrasing for `07_DELIVERY.md`.

**F-9 · INFO.** §10's "keeping the blank-line rhythm of lines 12-14" is ambiguous because the file itself
is inconsistent (blank line between bullets 11 and 13, none between 13 and 14). Pre-answered in §6.

---

## 6. High-probability developer questions — pre-answered

**Q-D1. The unit is one line away from being defensible — shouldn't I add `ConditionPathExists=`,
`Wants=network-online.target`, or `Environment=`?**
No. B-2, 01 §8 Q5/Q8, 02 §2.1 and 02 §15 item 4 all forbid it, and V-3 asserts a `1 insertion(+), 1
deletion(-)` diff, so any addition is a verification failure, not a debate. A `ConditionPathExists=`
guard would specifically convert the loud `203/EXEC` that made this defect findable into a silent skip.
If F-1 makes you want an `Environment=` line: do not add it — flag it and let PM route.

**Q-D2. Exactly where does the `CHANGELOG.md` bullet go, and does it need a preceding blank line?**
Immediately after the existing last `### 修复` bullet (`CHANGELOG.md:14`, the T-01 installer entry), with
**no blank line between it and line 14** — that is the local precedent (bullets 13 and 14 are adjacent) —
and keep the existing blank line before `## [0.1.0]`. One bullet, Simplified Chinese, carrying 02 §10's
four facts. Do not touch `### 新增`, do not add a heading, do not reorder.

**Q-D3. V-6 wants a before/after `systemd-analyze verify`, but I have already made the edit.**
Recover the pre-change file with `git show HEAD:systemd/sing-box-rules-update.service` into a scratch
path — the temp file **must still be named `sing-box-rules-update.service`**, because `systemd-analyze
verify` rejects a path whose basename is not a valid unit name. `systemd-analyze verify` parses and stats;
it never executes `ExecStart` and needs no root. On this host `/usr/local/bin/sc` exists, so the expected
discriminator is: pre-change output names `/usr/local/bin/proxy` as not executable, post-change output
does not. Capture both verbatim in `06_TEST_REPORT.md`. Any `sing-box.service`/`network-online.target`
not-found notice is pre-existing noise.

**Q-D4. Doesn't V-7 violate "no execution and no import of `bin/sc`"? `verify_all.sh` B.1 runs
`python3 -m py_compile bin/sc`.**
No, and this is worth stating so nobody stalls: `py_compile` **compiles to bytecode without executing
module-level code**, so the auto-elevate at `bin/sc:77-78` never runs. It writes `bin/__pycache__`, which
`verify_all.sh:59` removes; that is a repo-local artifact, not a live-system mutation, so AC-11 holds.
Running `verify_all` is safe. What is *not* safe, on this host specifically, is any `python3 -c "import
sc"`, any `./bin/sc …`, any `subprocess` invocation — `/usr/local/bin/sc` and `/usr/local/bin/sing-box`
are both installed here (verified this stage), so such a call would drive the installed tool against the
live service exactly as it did during T-02.

**Q-D5. What is AC-12's baseline, and can my own documents break it?**
Baseline = `verify_all` on the current tree, before the edit. Yes, your documents can break it: keep
every active stage document ≤500 lines (`02` is at 499 — if you must record a DESIGN DRIFT, compact
rather than append), and make sure `06_TEST_REPORT.md` contains a literal `## Adversarial tests` heading.
Those are the only two checks in the gate that this task can move.

**Q-D6. My dev host shows the unit in `failed`. Do I need to clear it, or start the unit to prove the fix?**
Neither, and you must not. `failed` does not block the next activation (§2.1 item 5 above), and AC-11
bans every live mutation — `systemctl start` on this unit would restart the developer's real sing-box
(`bin/sc:1141-1143`). The evidence for this task is static: the file diff, the five-site literal match,
`systemd-analyze verify`, and the two read-only D-Bus queries in 02 §8.2.

**Q-D7. Can anything prove end-to-end that the timer now works?**
Not inside this task, by design. The proof is decomposed: the path literal matches all five in-repo sites
(V-1/V-2), the unit parses and its `ExecStart` resolves (V-6), the installer copies it and reloads with no
reachable early exit (V-8), and the reload-sufficiency argument is mechanical (§2.1). An actual triggered
run is a post-release observation, not a gate artifact.

---

## 7. Conditions

- **C-1 (F-1).** `07_DELIVERY.md` must name the service-environment residual — the `SB_BIN` PATH
  dependency (verified benign) and the Python-3.6-plus-no-locale encoding exposure — as a known residual
  with a follow-up disposition, in the same way R-1 is carried. The developer must **not** remedy it by
  editing the unit; PM routes it.
- **C-2 (F-2).** `07_DELIVERY.md` must carry the uninstaller `systemctl reset-failed` residue
  (`uninstall.sh:113-130`, E-14 / 01 §8 Q9) as an explicit follow-up row, since no AC binds it.
- **C-3 (F-3).** V-4 is executed and reported as: literal `/usr/local/bin/proxy` → **one** shipped-code
  hit (`uninstall.sh:133`) after the change; `uninstall.sh:134`'s `/etc/sudoers.d/proxy` is reported
  separately as the sudoers twin. A "two hits" expectation is wrong and must not be recorded as a defect.
- **C-4 (F-5).** Every active stage document stays ≤500 lines (`02` is at 499); `06_TEST_REPORT.md`
  contains `## Adversarial tests`; the AC-12 comparison is made with all stage documents present.
- **C-5 (F-6, F-8).** Delivery text says "no catch-up run on a host whose timer has been triggering",
  never an unqualified "no immediate run", and names the `sc update-interval`-to-a-shorter-cadence path
  alongside 02 §8.3's two exceptions; and it says remote installs pick the fix up "within minutes of the
  push", not instantaneously.

None of these requires an upstream document to change. C-1…C-5 are discharged by the developer and QA
inside the existing diff boundary.

---

## Verdict

**APPROVED WITH CONDITIONS** — proceed to `harness-kit:developer`, conditions C-1…C-5 binding.

The one claim that could have collapsed the task holds: `systemctl daemon-reload` alone is sufficient for
the corrected `[Service]`, verified on the mechanism (fragment caching, oneshot has no live process,
name-resolved timer edge, `failed` does not block activation) and not merely on the in-repo precedent —
so `install.sh` stays out of the diff and the documented upgrade path genuinely repairs existing hosts.
The BC-11 stamp claim is correct as stated and safe to put in user-facing text. The repair recipe's
commands are correct and its restart caveat is true and adequately flagged. All nine verification checks
are read-only and none can trip the live auto-elevate hazard, which is confirmed live on this host.
`CHANGELOG.md` belongs in the diff and the architect's call is upheld; no scope has crept in beyond it,
and nothing the requirement demands is under-delivered. The six WARNs are documentation-completeness and
verification-precision defects, plus one genuine unexamined failure mode (F-1) that is report-only
because every available remedy lies outside the owner's boundary — none of them justifies holding a
one-line fix that repairs a feature which has never once worked.
