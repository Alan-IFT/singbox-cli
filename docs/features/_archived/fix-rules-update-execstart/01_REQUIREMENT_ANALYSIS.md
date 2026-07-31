# 01 — Requirement Analysis · T-09 `fix-rules-update-execstart`

> Mode: **full** · Deferred-human (defer, do not ask) · 2026-07-31
> Upstream inputs (read-only): `docs/batches/default/BATCH_PLAN.md` row T-09 + notes, PM dispatch prompt,
> `docs/features/fix-rules-update-execstart/PM_LOG.md`. No `INPUT.md` file exists for this task; the PM
> dispatch prompt is the requirement source.

---

## 1. Goal

The systemd rule-set auto-update unit executes a binary this project never installs, so the
README-advertised weekly `.srs` auto-update has never run on any systemd host; make the unit invoke the
CLI that is actually installed, and make the documented upgrade path repair hosts already carrying the
broken unit.

---

## 2. Evidence — the defect, confirmed from the repo

Backward-looking citations; each was read this task, not inherited.

| # | Fact | Source |
|---|---|---|
| E-1 | The unit's only `ExecStart` is `ExecStart=/usr/local/bin/proxy update-rules`. The unit has no `[Install]` section (it is timer-triggered), `Type=oneshot`, no `User=`, no `Environment=`, no `ExecStartPre/Post`. | `systemd/sing-box-rules-update.service:1-7` |
| E-2 | The installer installs the CLI as `/usr/local/bin/sc` (`install -m 755 "$ARTIFACT_DIR/bin/sc" /usr/local/bin/sc`). | `install.sh:376` (step 3) |
| E-3 | The password-less sudo rule is scoped to `NOPASSWD: /usr/local/bin/sc`. | `install.sh:437-441` (step 5) |
| E-4 | The CLI's import-time auto-elevate re-execs `sudo /usr/local/bin/sc …`. | `bin/sc:77-78` |
| E-5 | The installer itself calls `/usr/local/bin/sc update-rules` and `/usr/local/bin/sc reload`. Four independent sources therefore agree on the path; **no rule anywhere in the repo produces, downloads or installs a file named `proxy` in `/usr/local/bin`.** | `install.sh:456,479` + repo-wide sweep, §2a |
| E-6 | Repo-wide sweep for the literal `/usr/local/bin/proxy`: exactly three hits — the defective unit line, and the uninstaller's two deliberate legacy-cleanup lines (`rm -f /usr/local/bin/sc /usr/local/bin/proxy`, `rm -f /etc/sudoers.d/sc /etc/sudoers.d/proxy`, commented "legacy `proxy` filenames left from pre-rename installs"). No other stale `proxy` invocation exists in units, scripts, either README, `docs/`, or `CHANGELOG.md`; every other `proxy` match is the sing-box outbound tag, `sc sysproxy`, or prose. | `systemd/sing-box-rules-update.service:7`, `uninstall.sh:132-134` |
| E-7 | Step 4 installs all three unit files with `install -m 644` into `/etc/systemd/system/` and then runs `systemctl daemon-reload`, on the systemd branch only. | `install.sh:405-409` |
| E-8 | T-01 (landed) registers the timer unconditionally (`systemctl enable sing-box-rules-update.timer … || true`) before config generation, and starts it after a successful `sc reload`, treating it as auxiliary. | `install.sh:470-472,486` |
| E-9 | The remote (`curl \| bash`) install path downloads the same relative file from `RAW_BASE` = `https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main`, i.e. `REF="main"`. | `install.sh:11-13,317-329` |
| E-10 | The timer already carries `OnCalendar=weekly`, `RandomizedDelaySec=1h`, `Persistent=true`, `WantedBy=timers.target`. Nothing to change (confirms the batch-plan P3-2 note). | `systemd/sing-box-rules-update.timer:1-10` |
| E-11 | The OpenRC periodic script is written as `#!/bin/sh\n/usr/local/bin/sc update-rules\n` — correct, and only ever written by `sc update-interval`, never by the installer. **The brief's anchor `bin/sc:898` is stale** (that line is `_unique_tag`); the live location is `cmd_update_interval`'s OpenRC branch. | `bin/sc:1210-1218` |
| E-12 | `sc update-interval` on systemd writes `.timer.d/override.conf`, then `systemctl daemon-reload` **and** `systemctl restart sing-box-rules-update.timer` — the in-repo precedent that a *timer*-unit change needs a timer restart. | `bin/sc:1167-1179` |
| E-13 | `sc update-rules` exits non-zero when any rule-set is still unusable after all mirrors; on gain it regenerates the config and restarts sing-box; **and when nothing was gained it still restarts sing-box whenever the service is running** (`if not applied and is_running(): restart_service()`). | `bin/sc:1127-1144`, `restart_service` at `bin/sc:834-838` |
| E-14 | The uninstaller disables the timer and deletes the three unit files plus the `.timer.d/` drop-in, then `daemon-reload`s — it never runs `systemctl reset-failed`. | `uninstall.sh:113-130` |
| E-15 | The feature the defect breaks is advertised in both READMEs ("Auto ruleset update: systemd timer pulls `.srs` rulesets at a configurable cadence" / 「规则集自动更新：systemd timer 定期拉 `.srs`，频率可配」). Both file-location tables list the *timer* path and the cadence-override path; **neither lists the `.service` unit path**, so no README path text is falsified by this change. | `README.md:14,163-167`, `README.zh-CN.md:14,164-167` |
| E-16 | `CHANGELOG.md` is single-language (Simplified Chinese) throughout, including the `[Unreleased]` section. | `CHANGELOG.md:1-30` |
| E-17 | `verify_all` has no unit-file check; all `B.*` build/test/lint checks are `SKIP` and no systemd lint is wired. | `.harness/scripts/verify_all.sh`, `.harness/rules/50-singbox-cli.md:34-36,116-131` |

**Consequence chain (all four links evidenced above).** Unit points at a non-existent path (E-1, E-6) →
systemd cannot execute it → every trigger fails `203/EXEC` → the weekly ruleset refresh advertised in
both READMEs (E-15) has never executed on any systemd install, on any release. The one-line nature of
the defect and the four-source agreement on `/usr/local/bin/sc` (E-2, E-3, E-4, E-5) leave no ambiguity
about the correct value.

---

## 3. In-scope behaviors

Numbered, binding, testable.

**B-1 — The unit invokes the installed CLI.** The systemd rule-set update unit's `ExecStart` runs the
`sc` CLI at the absolute path the installer installs it to (`/usr/local/bin/sc`) with the `update-rules`
subcommand and no other arguments. The path is written absolutely and literally: no `$PATH` lookup, no
`/usr/bin/env`, no shell quoting, no variable expansion.

**B-2 — Everything else about the unit is unchanged.** The unit keeps exactly one `ExecStart`, keeps
`Type=oneshot`, keeps its existing `[Unit]` `Description` and `After=` line, and gains no `User=`,
`Environment=`, `ExecStartPre=`, `ExecStartPost=`, `Condition*=`, `Restart=`, `SuccessExitStatus=` or
`[Install]` section.

**B-3 — Failure stays visible.** A non-zero exit from `sc update-rules` continues to put the unit into
`failed` state and its stdout/stderr continue to reach the journal. Nothing in this task masks,
retries, or swallows that exit status.

**B-4 — The unit runs as root, so no elevation path is involved.** Because the unit is a system unit
with no `User=`, the CLI starts as uid 0 and its import-time auto-elevate `sudo` re-exec does not fire;
the unit therefore has no dependency on sudo, on `/etc/sudoers.d/sc`, on a TTY, or on the invoking
user's environment.

**B-5 — The documented upgrade path repairs an already-broken host.** Re-running the documented install
one-liner (or `sudo ./install.sh` from a clone) on a host carrying the defective unit replaces
`/etc/systemd/system/sing-box-rules-update.service` with the corrected file and reloads the systemd
manager, with no manual unit editing and no `sed`/migration step, such that the next timer trigger
executes the corrected command. The installer is not modified to achieve this (§4).

**B-6 — The repair steps a user must take by hand are stated at delivery.** The delivery document names
(a) whether the reload performed by the upgrade path is sufficient for the corrected `[Service]` to take
effect, (b) the exact command to trigger one corrected run immediately instead of waiting for the next
scheduled trigger, and (c) the exact command to clear the residual `failed` unit state, together with
the condition under which that state clears by itself.

**B-7 — Stale-path sweep is reported.** The delivery document lists every occurrence of
`/usr/local/bin/proxy` (and any other invocation of a `proxy` executable) remaining in the repository
after the change, with a one-line disposition for each: fixed, deliberately retained, or filed as a
follow-up row.

**B-8 — No new user-facing runtime string.** This change introduces no message printed by `bin/sc`,
`install.sh` or `uninstall.sh`, so no new translation key is created and bilingual parity holds
unchanged. If any documentation line in `README.md` changes, the corresponding line in
`README.zh-CN.md` changes in the same commit.

**B-9 — The change is recorded for users.** `CHANGELOG.md` gains one entry under `[Unreleased] / 修复`
stating that the weekly systemd ruleset auto-update never ran because the unit invoked a non-existent
binary, that it now invokes `sc`, and what an existing host must do to pick up the fix.

**B-10 — Diff boundary.** The committed change touches `systemd/sing-box-rules-update.service`,
`CHANGELOG.md`, and this task's `docs/features/fix-rules-update-execstart/*` documents. No other
tracked file changes.

---

## 4. Out of scope

Each item was checked this task and is deliberately excluded, not overlooked.

1. **The OpenRC periodic script (`bin/sc`).** It already writes `/usr/local/bin/sc update-rules`
   (E-11). It is correct; it is not touched. **No abstraction unifying the systemd and OpenRC
   invocation paths is created.** Under `.harness/rules/85-design-discipline.md` the seam tests fail:
   neither path computes anything the other consumes, each is a complete honest artifact on its own,
   and no future edit is prevented by extracting a shared constant across a Bash-installed unit file and
   a Python-generated shell script. Two init systems each writing their own invocation is the domain
   shape, not a duplication defect.
2. **`install.sh`** — owned by T-01 (delivered, commit 493eb6a). Its step 4 already installs the unit
   file and reloads the manager, which is exactly what B-5 needs; nothing is added to it.
3. **`bin/sc` rule-set / config logic** — owned by T-02 (delivered, commit ab4e4a4).
4. **`systemd/sing-box.service`** and **`systemd/sing-box-rules-update.timer`** — the timer already
   carries `Persistent=true` (E-10); nothing to change.
5. **The weekly unconditional restart of sing-box (E-13).** Once the timer works, a successful run in
   which no rule-set changed still calls `restart_service()` whenever sing-box is running, so every
   host will bounce the proxy weekly. Reported, not fixed here (§8 Q4): it is pre-existing
   `sc update-rules` behavior already reachable today from a manual run and from the OpenRC periodic
   script, so leaving it does not ship an incoherent half-state — the ExecStart fix is strictly an
   improvement on its own.
6. **`After=network-online.target` with no `Wants=`/`Requires=`.** Reported, not fixed (§8 Q5).
7. **`systemctl reset-failed` in `install.sh` or `uninstall.sh`.** Reported, not fixed (§8 Q2, §8 Q9).
8. **The systemd/OpenRC auto-update-by-default gap** (an OpenRC install schedules no automatic update
   unless the user runs `sc update-interval`) — already an open owner question in the batch plan; not
   re-litigated here.
9. **Adding a committed test suite or wiring a `verify_all` `B.*` check.** Deferred to T-07 by
   `.harness/rejected-decisions.md § ruleset-unit-tests-in-t02`; a unit-file change does not reopen it.
10. **Any live-system change during this task** — no `systemctl` write command, no install, no
    uninstall, no root (§6, §9 AC-11).

---

## 5. Boundary conditions

| # | Condition | Required behavior |
|---|---|---|
| BC-1 | Fresh systemd install, no prior unit present | The corrected unit is installed by step 4 and the timer is registered; the first scheduled trigger executes `sc update-rules` successfully (network permitting). |
| BC-2 | Host carrying the defective unit, upgraded via the documented one-liner | The unit file on disk is replaced by the corrected content and the manager reloads within the same install run; the next trigger runs the corrected command. |
| BC-3 | Host whose rules-update unit is currently in `failed` state (every existing systemd host) | The upgrade does not require the failed state to be cleared for the next trigger to run. The residual `failed` entry is either cleared by the first successful run or by an explicit reset command; whichever holds is stated at delivery (B-6). |
| BC-4 | Host that has run `sc update-interval` and owns `.timer.d/override.conf` | The override and the configured cadence survive untouched; only the `.service` file changes. |
| BC-5 | OpenRC / Alpine host | No unit file is installed and no behavior changes at all. |
| BC-6 | `/usr/local/bin/sc` absent when the timer fires (CLI removed without running the uninstaller) | The unit fails `203/EXEC` exactly as an unresolvable `ExecStart` does today. No condition guard hides this. |
| BC-7 | All mirrors unreachable at the scheduled trigger | The CLI exits non-zero, the unit enters `failed`, and the per-file causes land in the journal on stdout (the insight-index stream contract is unchanged by this task). |
| BC-8 | Timer trigger overlaps a manual `sc update-rules` | Safe as today: T-02's per-pid temp names plus atomic replace already cover concurrency; this task adds no new shared state. |
| BC-9 | Service not running, or no `config.json` yet, at trigger time | No restart is attempted (pre-existing guarded behavior). |
| BC-10 | Service running and no rule-set changed | sing-box is restarted (E-13). Recorded as a known consequence and reported (§4 item 5), not silently absorbed. |
| BC-11 | `Persistent=true` catch-up after the fix | Because the timer has been triggering all along (and only the triggered service failed), the trigger stamp is current, so daemon-reload produces no immediate catch-up run; the first corrected run happens at the next scheduled boundary plus the randomized delay. The design confirms this before the delivery text claims it. |
| BC-12 | Unit file text hygiene | The file remains valid unit syntax: one `ExecStart` key, no trailing whitespace on the command line, terminating newline, no shell metacharacters (systemd runs no shell). |
| BC-13 | Remote install path | The corrected file is the one served from `REF="main"` (E-9), so the fix reaches `curl \| bash` users as soon as the commit is pushed to `main` and not before; delivery states this. |

---

## 6. Acceptance criteria

All criteria are verifiable **statically, unprivileged, without mutating any live system** — no root, no
`systemctl` write commands, and (per the insight-index auto-elevate hazard) **no execution or import of
`bin/sc` in any form**, since an unprivileged import re-execs the *installed* CLI against the *live*
service.

| # | Criterion | How it is verified |
|---|---|---|
| AC-1 | `systemd/sing-box-rules-update.service` contains exactly one `ExecStart=` line, and its value is the absolute installed CLI path followed by `update-rules` and nothing else. | Read the file; assert one `ExecStart` occurrence and exact string equality. |
| AC-2 | That path string is byte-identical to the path the installer installs the CLI to, to the path in `/etc/sudoers.d/sc`, and to the CLI's own auto-elevate target. | Cross-read the four sites (E-2, E-3, E-4, and the unit) and compare the literal. |
| AC-3 | No occurrence of `/usr/local/bin/proxy` remains anywhere in the repository except the uninstaller's two legacy-cleanup lines, and no other file invokes a `proxy` executable. | Repo-wide search for `/usr/local/bin/proxy` and for `proxy ` used as a command; enumerate every hit with its disposition. |
| AC-4 | Aside from the `ExecStart` value, the unit file is unchanged: same `[Unit]` keys and values, `Type=oneshot`, no added directives, no `[Install]` section. | Line-by-line diff of the unit file against its pre-change content. |
| AC-5 | The upgrade path repairs a broken host: the installer's unit-installation step copies this exact file to `/etc/systemd/system/` and reloads the manager, unconditionally on the systemd branch and independently of whether ruleset download or config generation succeeded. | Read the installer's unit-install step and its ordering relative to the steps that can fail; confirm no early exit can be reached between them under `set -euo pipefail`. |
| AC-6 | The sufficiency question is answered explicitly, not assumed: the delivery document states whether the manager reload alone makes the corrected `[Service]` effective for the next trigger, or whether the timer unit must also be restarted, with the reasoning and the in-repo precedent it rests on. | Written determination in `02_SOLUTION_DESIGN.md` and restated in `07_DELIVERY.md`. If the answer is "a timer restart is required", that is a scope escalation (§8 Q1) because the installer is out of scope. |
| AC-7 | The delivery document names the exact command for an immediate corrected run, the exact command to clear the residual `failed` state, and the condition under which that state clears by itself. | Presence and correctness of those commands in `07_DELIVERY.md`. |
| AC-8 | The unit-file change alters no user-visible CLI behavior on OpenRC hosts and adds no translation key. | Confirm `bin/sc`, `install.sh`, `uninstall.sh` are byte-unchanged in the diff. |
| AC-9 | `CHANGELOG.md` carries one entry describing the defect, the fix, and the user-facing upgrade action, in the file's existing single language. | Read the entry. |
| AC-10 | Diff boundary holds: only the unit file, `CHANGELOG.md` and this task's stage documents are modified. | `git status` / `git diff --name-only` review at delivery. |
| AC-11 | Verification produced no live-system mutation: no `systemctl start/stop/enable/disable/daemon-reload/reset-failed`, no `install.sh`/`uninstall.sh` execution, no `bin/sc` execution or import, no root. | Command log review in `06_TEST_REPORT.md`; every command listed is read-only. |
| AC-12 | `.harness/scripts/verify_all` result is unchanged from the pre-change baseline (delta 0 across PASS/WARN/FAIL/SKIP). | Run before and after; compare counts. |
| AC-13 | Where a systemd installation exists on the verifying host, `systemd-analyze verify` on the changed unit reports no error attributable to this change. Where systemd is absent, this criterion is recorded as skipped with the reason. | `systemd-analyze verify` is a read-only parse-and-stat operation; it starts nothing. Host-dependent, therefore explicitly skippable. |
| AC-14 | The consequences the fix activates are documented rather than discovered later: the weekly restart of sing-box on an unchanged run (BC-10), the newly-possible genuine `failed` state on network-restricted hosts (BC-7), and the absence of an immediate catch-up run (BC-11). | Presence in `07_DELIVERY.md`, each with a follow-up disposition. |

---

## 7. Non-functional requirements

- **Compatibility.** `ExecStart=` with an absolute path is supported by every systemd version this
  project targets; no directive newer than the project's existing units is introduced. The change is
  init-system-neutral: OpenRC hosts never read this file.
- **Security.** The executed path stays a root-owned, mode-755 file installed by the installer into a
  root-writable-only directory; nothing is widened. The unit continues to carry no `Environment=`, so
  the mirror-override environment variable cannot be injected through it. `/etc/sudoers.d/sc` is not
  touched.
- **Operational cost.** Once corrected, the unit runs at most weekly (with up to one hour of randomized
  delay) and performs the same four small downloads a manual `sc update-rules` performs today.
- **Performance.** No material requirement.

---

## 8. Open questions (deferred-human mode — each carries a recommended answer and a proceeding assumption)

**Q1 — Is a manager reload sufficient for the corrected `[Service]`, or must the timer also be
restarted?** (a) Reload alone is sufficient. (b) The timer unit must additionally be restarted.
**Recommended: (a).** The changed unit is the *service*, not the timer; a reload re-reads unit files
from disk, and a `Type=oneshot` service is not running between triggers, so the next activation uses the
new definition. The in-repo precedent supports the distinction: the CLI restarts the timer only when it
writes a `.timer.d` override that changes the *timer* (E-12); the installer, which rewrites all three
unit files, reloads and does not restart anything (E-7).
**Proceeding assumption**: (a). B-5 and AC-5 are written to (a). **Escalation trigger:** if the
architect concludes (b), the fix stops being self-contained — a timer restart would have to come from
`install.sh`, which the owner placed out of scope — and the PM must be told before the design is
approved rather than the installer being edited silently.

**Q2 — What happens to the residual `failed` unit state on the ~100% of existing systemd hosts whose
rules-update service has been failing?** (a) Document only: it clears on the first successful run, and
`systemctl reset-failed sing-box-rules-update.service` clears it immediately. (b) Have the installer run
`reset-failed`. (c) Have the uninstaller run `reset-failed`.
**Recommended: (a).** The state is cosmetic — it does not prevent the next trigger from starting the
unit; weekly triggers cannot approach the default start-rate limit; and both (b) and (c) require editing
files the owner declared out of scope. B-6 makes the answer explicit at delivery instead of leaving the
user with an unexplained entry in `systemctl --failed`.
**Proceeding assumption**: (a). BC-3, B-6 and AC-7 are written to (a); (b)/(c) are re-homed as the
follow-up row in Q9.

**Q3 — Should the upgrade trigger one corrected run immediately (`systemctl start
sing-box-rules-update.service`)?** (a) No. (b) Yes, from the installer.
**Recommended: (a) no.** The installer already runs `sc update-rules` directly in its own step 6 (E-5),
so an install/upgrade refreshes the rule-sets in that same run; starting the unit as well would download
the same four files twice and would edit an out-of-scope file. The manual command is documented instead
(B-6).
**Proceeding assumption**: (a).

**Q4 — The weekly unconditional restart of sing-box that this fix activates (E-13, BC-10).** (a) Report
it as a new pool row; change nothing here. (b) Fix it in `bin/sc` inside this task.
**Recommended: (a) report.** `bin/sc`'s rule-set logic is owned by T-02 and declared out of scope, and
the behavior is pre-existing and already reachable (a manual `sc update-rules`, and the OpenRC periodic
script on hosts that enabled it), so shipping the ExecStart fix without it is not a dishonest half-state
under `.harness/rules/85-design-discipline.md`. It is nevertheless a real change in what users
*experience* — a weekly connection drop — and must not be discovered by them first.
**Proceeding assumption**: (a). AC-14 forces it into the delivery notes; PM to file the row.

**Q5 — `After=network-online.target` with no `Wants=`/`Requires=` on that target.** (a) Leave it and
report. (b) Add `Wants=network-online.target`.
**Recommended: (a).** `After=` alone does not pull the target in, but a timer firing days after boot
runs on a machine that is long past network setup, so the ordering is inert in practice; adding `Wants=`
changes what the trigger activates and exceeds a one-line path correction.
**Proceeding assumption**: (a).

**Q6 — Language of the `CHANGELOG.md` entry.** (a) Simplified Chinese only, matching every existing
entry in the file. (b) Bilingual.
**Recommended: (a).** The bilingual-parity rule binds user-facing *runtime* strings and the paired
READMEs; `CHANGELOG.md` is uniformly single-language today (E-16) and a lone bilingual entry would break
its internal consistency without an owner instruction to convert the file.
**Proceeding assumption**: (a). B-9 and AC-9 are written to (a).

**Q7 — Does either README need to change?** (a) No. (b) Add the `.service` unit path to the file-location
tables and/or add upgrade-repair instructions.
**Recommended: (a) no.** The README claim the defect falsified becomes true by virtue of the fix, and
neither file-location table lists the `.service` path (E-15), so nothing in either README is inaccurate
after the change. Migration guidance belongs in `CHANGELOG.md` and the delivery notes, which describe
transitions; the READMEs describe the current state.
**Proceeding assumption**: (a). If the architect adopts (b), B-8's parity obligation applies and both
READMEs change together.

**Q8 — Should the unit gain a guard such as `ConditionPathExists=/usr/local/bin/sc`?** (a) No.
(b) Yes.
**Recommended: (a) no.** A guard would convert the very failure mode that made this defect *findable*
(a loud `203/EXEC` in the journal) into a silent skip, and the unit is only ever installed by the same
installer step that installs the CLI. This is the counter-rule in
`.harness/rules/85-design-discipline.md`: no speculative machinery for a requirement nobody stated.
**Proceeding assumption**: (a). B-2 and BC-6 are written to (a).

**Q9 — The uninstaller leaves residue the installer creates: a unit that has entered `failed` state is
never `reset-failed`, so after the unit files are deleted and the manager reloaded, the unit can linger
in `systemctl --failed` (E-14).** (a) Report as a follow-up row; do not fix here. (b) Fix in
`uninstall.sh` now.
**Recommended: (a) report.** The brief explicitly scopes uninstaller residue to *report*, and
`uninstall.sh` is not in this task's diff boundary. Note the coupling: this residue is a *consequence*
of the defect being fixed here — until now every systemd host had a failing rules-update service to
leave behind — so the follow-up row is worth filing even though the population it affects shrinks after
this lands. No other installer-created artifact is missed by the uninstaller: binary, CLI, lib dir,
config tree, state, logs, sudoers, unit files and the `.timer.d` drop-in are all removed (the sing-box
core deliberately only on the purge prompt).
**Proceeding assumption**: (a). B-7 and AC-3 carry the report; PM to file the row.

---

## 9. Related work

- `docs/features/_archived/install-enable-start-split/` (T-01, delivered, 493eb6a) — made timer
  registration unconditional and independent of ruleset/config success. **Priority implication:** T-01
  strictly increased the population affected by this defect. Before it, a host whose install aborted
  early got no timer at all; after it, every systemd host gets an enabled weekly timer that fires into
  `203/EXEC` until this task lands. Its `04_DEVELOPMENT.md` and `05_CODE_REVIEW.md` both recorded the
  stale `ExecStart` as deliberately deferred to this row.
- `docs/features/_archived/config-degrade-missing-rulesets/` (T-02, delivered, ab4e4a4) — owns every
  behavior the corrected unit will now actually exercise: multi-mirror validated fetch, atomic replace,
  the non-TTY single-completion-line contract that keeps the journal readable, the exit-status contract
  (B-16), and the regenerate-and-restart recovery path (B-17) behind BC-10. Its `03_GATE_REVIEW.md`
  re-confirmed this defect and routed it here.
- `docs/batches/default/BATCH_PLAN.md` — row T-09 and the notes that scoped it down to systemd-only
  after checking the OpenRC path, plus the P3-2 note confirming `Persistent=true` needs no change.
- `.harness/insight-index.md` — both applicable lines are honored: the `/usr/local/bin/proxy` line is
  the defect this task removes (re-verified from source, §2), and the auto-elevate line is a hard
  constraint on verification, encoded in §6's preamble and AC-11.
- `.harness/rules/50-singbox-cli.md` — installer idempotency as the documented upgrade path (B-5),
  bilingual parity for user-facing strings (B-8), and the note that no build/test/lint gate exists yet
  (AC-12/AC-13 are therefore the whole automated surface).
- `.harness/rules/85-design-discipline.md` — applied twice: §4 item 1 (no invented abstraction across
  the two init systems) and §4 item 5 / Q4 (consolidation would re-home scope, and the minimal shape
  here is already the right granularity).
- `.harness/rejected-decisions.md` — no record is re-litigated by this task; the
  `ruleset-unit-tests-in-t02` deferral is the reason §4 item 9 adds no test suite.
- `CONTEXT.md` — untouched stub template; this task coins no domain term.

---

## Verdict

**READY.**

Nine open questions are recorded; each has an evidence-backed recommended answer and a proceeding
assumption, and none blocks the design. One conditional escalation exists: if the architect determines
under Q1 that a timer restart is required for the corrected `[Service]` to take effect, the fix can no
longer be delivered inside the owner's stated diff boundary, and the PM must be consulted before any
change reaches `install.sh`.
