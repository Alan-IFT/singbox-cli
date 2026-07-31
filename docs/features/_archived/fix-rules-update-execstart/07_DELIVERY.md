# Delivery Summary — T-09 `fix-rules-update-execstart`

- **Task:** `fix-rules-update-execstart` — point the systemd ruleset-update unit at the CLI that is
  actually installed, so the weekly auto-update can run for the first time.
- **Mode:** full (7 stages)
- **Stages traversed:** 1 requirement → 2 design → 3 gate → 4 development → 5 code review → 6 QA →
  7 delivery. All on 2026-07-31.
- **Rollbacks:** **0.** One conditional escalation was armed at stage 1 (Q1) and did not fire; one
  rollback was considered at stage 5 and declined (see "Routing decisions" below).
- **Final `verify_all` result:** **PASS 16 / WARN 0 / FAIL 0 / SKIP 2, exit 0** — delta 0 against a
  pristine `HEAD` baseline that QA rebuilt itself in a scratch copy rather than trusting the
  developer's number. **No FAIL.**
- **Baseline changes:** none. `test_count` remains 0; no committed test was added, and adding one is
  forbidden upstream (`.harness/rejected-decisions.md § ruleset-unit-tests-in-t02`, deferred to T-07).
- **Files changed:** `systemd/sing-box-rules-update.service` (1 insertion / 1 deletion),
  `CHANGELOG.md` (1 insertion / 0 deletions), plus this task's stage documents.
  `docs/tasks.md` (1/1) is the PM's board row, not part of the fix.
  **Not committed, not pushed** — the owner handles delivery.

---

## 1. What changed

`systemd/sing-box-rules-update.service:7`:

```ini
-ExecStart=/usr/local/bin/proxy update-rules
+ExecStart=/usr/local/bin/sc update-rules
```

Nothing else in the unit moved: lines 1-6 are byte-identical to `HEAD`, and a directive grep returns
exactly two lines (`Type=oneshot`, the one `ExecStart`). No `ConditionPathExists=`, no
`Environment=`, no `Wants=`, no `User=`, no `Restart=`, no `[Install]`. `git diff --summary` is empty
(no mode or rename change).

Plus one Simplified-Chinese `修复` bullet at `CHANGELOG.md:15`, carrying the defect, the fix, the
upgrade action, and what to expect afterwards.

**The path was verified against every other place the repo names the CLI — 11 byte-identical
occurrences in shipped code** (the requirement counted four, the developer six, QA found eleven):
`install.sh:376` (the install itself), `:438` (sudoers `NOPASSWD`), `:456`, `:479`, `bin/sc:78`
(auto-elevate re-exec target), `bin/sc:1217` (the OpenRC periodic script), among others.

---

## 2. The upgrade path — does re-running the installer actually repair a broken host?

**Yes, and no manual step is required.** This was the owner's first question and the one claim that
could have collapsed the task, so it was verified on the mechanism at three stages independently.

`systemctl daemon-reload` alone **is sufficient**; the timer does **not** need restarting:

1. What changed is the `[Service]` fragment, not the `[Timer]`. Restarting the timer would re-arm the
   wrong unit.
2. systemd does not auto-detect changed unit files — it caches the parsed fragment (and the service
   stays *loaded*, because the timer references it). A reload is therefore genuinely **necessary**,
   and `install.sh:409` performs it unconditionally on the systemd branch.
3. The usual "settings apply at next start" caveat cannot bite: a `Type=oneshot` unit with default
   `RemainAfterExit=no` has no process and no queued job between triggers, so the next activation is
   a fresh `execve` against the reloaded fragment.
4. The timer→service edge is resolved **by unit name at elapse time** (the `[Timer]` has no `Unit=`),
   and is never snapshotted.
5. A `failed` state does not block the next activation, and a weekly cadence cannot approach
   `DefaultStartLimitBurst=5`.

In-repo precedent agrees in both directions: `bin/sc:1167-1179` restarts the timer *only* after
writing an `OnCalendar=` override (a genuine *timer* change), while `install.sh:405-409` rewrites all
three unit files and restarts nothing — including for the long-running `sing-box.service`, which is
the harder case, and which this project has shipped that way for its entire history.

`install.sh:405-409` is one `if` block: three plain `install -m 644` followed by the reload, with no
`exit`, `return`, `||`, `&&`, `trap` or subshell between them, under `set -euo pipefail`. It runs
*before* the failure-tolerant steps 6 and 7, so a host whose ruleset download or config generation
fails still gets the corrected unit file installed and the manager reloaded.

### The step that is genuinely load-bearing and was almost missed (QA D-3)

On a host where the timer is **disabled**, the `ExecStart` fix alone changes nothing — forever. The
repair works because the same installer run also *enables and starts the timer*
(`install.sh:472`/`:486`, made unconditional by T-01). This is not hypothetical: it is the state of
the verification host (§4). Anyone who repairs the unit by hand-editing
`/etc/systemd/system/sing-box-rules-update.service` instead of re-running the installer will fix the
path and still never get an automatic update.

**Re-run the installer. Do not hand-edit the unit.**

---

## 3. What a user must do, and what to expect

**To pick up the fix** — re-run the documented one-liner, or from a clone:

```bash
sudo ./install.sh
```

That is the whole upgrade. The installer overwrites the unit file, reloads the manager itself, and
enables the timer. No manual unit edit, no `daemon-reload` by hand, no timer restart.

**To run one corrected update immediately** instead of waiting for the next weekly trigger:

```bash
sudo systemctl start sing-box-rules-update.service
```

⚠️ **This restarts sing-box if it is running** (connections drop for a few seconds).
`bin/sc:1135-1143` calls `restart_service()` on both the "something was updated" path *and* the
"nothing changed" path whenever `is_running()`. `sudo sc update-rules` is the same code path and has
the same effect.

**To clear a residual `failed` unit:**

```bash
sudo systemctl reset-failed sing-box-rules-update.service
```

It also clears by itself after the **next successful run** — note *successful*, not merely *next*.

**When the first automatic run happens.** On a host whose timer has been triggering normally, there
is **no immediate catch-up run**: the trigger stamp advances when the timer *elapses and enqueues the
job*, not when the service succeeds, and a `203/EXEC` failure happens in the forked child long after
enqueue — so every weekly elapse advanced the stamp exactly as on a healthy host. The first real
update lands at the next weekly point plus up to one hour of randomized delay
(`RandomizedDelaySec=1h`), i.e. Monday 00:00–01:00 local.

**Three exceptions where a run does happen promptly** — the claim above is deliberately conditional,
never an unqualified "the timer never fires immediately":

1. A host whose timer was previously **stopped or disabled** so the stamp is stale: `Persistent=true`
   makes it catch up moments after `install.sh:486` starts the timer.
2. A host **powered off** across a scheduled boundary: it catches up at next boot.
3. A user who runs `sc update-interval` to a **shorter** cadence: that writes `.timer.d/override.conf`
   and restarts the timer (`bin/sc:1167-1179`), and with a last-trigger base up to a week old the
   recomputed elapse is already in the past, so it fires at once.

In all three, the run is real and therefore restarts sing-box.

**For `curl | bash` users:** the installer fetches the unit from `REF="main"`, so remote installs pick
the fix up **within minutes of the push** (raw.githubusercontent caches for roughly five minutes) —
not instantaneously, and not before the commit lands on `main`.

---

## 4. Verification — executed vs. reasoned

The owner asked for this split explicitly. **No live-system mutation occurred at any stage.**

### Executed, with real output

| Check | Result |
|---|---|
| `git diff --numstat` | `1 1` unit, `1 0` CHANGELOG, `1 1` `docs/tasks.md` (PM's row). Lines 1-6 of the unit byte-identical to `HEAD`. |
| Out-of-scope files | `git diff --quiet` clean on `bin/sc`, `install.sh`, `uninstall.sh`, both other units, both READMEs, `verify_all.sh`, `dev-map.md`, `insight-index.md`. |
| `systemd-analyze verify` (systemd 255) | **pre-change:** `Command /usr/local/bin/proxy is not executable: No such file or directory`, exit 1. **post-change:** silent, exit 0. |
| `verify_all` | Pristine `HEAD` tree rebuilt by QA in a scratch copy: PASS 16 / WARN 0 / FAIL 0 / SKIP 2, exit 0. Working tree with the change + all stage docs: identical. **Delta 0.** |
| Stale-path sweep | Exactly **one** shipped-code `/usr/local/bin/proxy` hit remains: `uninstall.sh:133`. |
| No-mutation attestation | sing-box PID 2500438 / start 17:04:23 unchanged; unit-file mtimes unchanged; timer state unchanged; no stamp file created; `systemctl --failed` still 0. |

QA also ran **five mutation controls** against `systemd-analyze verify` to prove it was not passing
vacuously — a typo'd path and a bad `ExecReload` are caught (exit 1), while a bare PATH lookup, CRLF
line endings and `/usr/bin/env` all pass (exit 0). So AC-13 is a *narrow* gate: it proves this
specific defect class is gone, not that the unit is generally well-formed.

### Reasoned only — not proven here

**The end-to-end claim "the weekly timer now updates rulesets" was not executed and is not proven.**
Links 1-3 of the chain are mechanically evidenced (the path literal matches every install site; the
unit parses and its `ExecStart` resolves; the installer copies it and reloads with no reachable early
exit). **Link 4 — that `daemon-reload` alone makes the corrected `[Service]` effective on the next
trigger — rests on argument**, not on an observed triggered run. §2 is that argument, cross-checked
independently at stages 2, 3 and 5. The first triggered run is a post-release observation.

Proving it would require root, installing units, and mutating the live system. That was forbidden,
for good reason: T-02 had a real incident in which a test import re-execed the *installed* `sc` under
sudo and restarted the live service. `/usr/local/bin/sc` and `/usr/local/bin/sing-box` are both
installed on this host, so the hazard was live throughout. No stage executed or imported `bin/sc`;
the only thing that touched it was `verify_all` B.1's `python3 -m py_compile`, which compiles to
bytecode without executing module-level code, so the auto-elevate at `bin/sc:77-78` never fired.

### The host contradicted two upstream premises (QA D-1, D-2)

Worth stating plainly, because both this task's brief and its own stage documents asserted otherwise:

- **"~100% of existing systemd hosts sit in `failed`" is not true here.** On the verification host the
  unit is `inactive (dead)` with `Result=success`, `systemctl --failed` lists 0 units, and
  `journalctl -u sing-box-rules-update.service` returns **"-- No entries --"**. The unit has **never
  run at all** — the timer is `disabled`, `LastTriggerUSec` is empty, `list-timers` reports "0 timers
  listed", and no stamp file exists.
- **Consequently the BC-11 stamp argument has zero empirical support anywhere in this project.** It is
  correct as reasoning (and was independently re-derived at stage 3), but nobody has ever observed the
  stamp advancing on a `203/EXEC` host, because no such host was available. §3's "no immediate catch-up"
  sentence is the one user-facing claim resting purely on argument.

This also refines the T-01 interaction: T-01 made `systemctl enable …timer` unconditional, so hosts
installed **after** T-01 landed do get a weekly timer firing into `203/EXEC`. Hosts installed before
it — like this one — may have no enabled timer at all, and for them the timer has simply never fired.
Both populations are repaired by the same action (re-run the installer), which is why the recipe in §3
needs no branching.

---

## 5. Outstanding risks and residuals

None blocks delivery. All are pre-existing or activated-but-unchanged behaviour; each is filed below.

**R-1 — the fix activates a weekly sing-box restart.** `bin/sc:1141-1143` calls `restart_service()`
even when *nothing changed*, whenever sing-box is running. Because the timer has never fired, no user
has ever experienced this. Once the fix lands, every host gains a **weekly connection drop**, landing
Monday 00:00–01:00 local. Pre-existing `bin/sc` behaviour owned by T-02, already reachable today from
a manual `sc update-rules` and from the OpenRC periodic script — so shipping the ExecStart fix without
it is not a dishonest half-state. But it is the one thing users will actually *notice*, and it should
not be discovered by them first. **Follow-up row recommended.**

**C-1 — the unit will run `sc` in a systemd service environment for the first time in project
history**, and nothing analysed that environment until stage 3 asked:

- (a) `bin/sc:31` is `SB_BIN = "sing-box"` — a bare **PATH lookup**. Empirically corroborated as safe:
  `systemctl show-environment` on this host gives
  `PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/snap/bin`, so `sing-box check` resolves.
  Safe, but safe by luck rather than by design.
- (b) **Encoding.** `bin/sc:1089` unconditionally prints a non-ASCII `↓` before any download. A system
  unit inherits no login-shell locale. On **Python 3.6** — the floor this project documents — an
  unset/POSIX locale makes `sys.stdout` ASCII and that first `print` raises `UnicodeEncodeError`.
  Python 3.7+ is immune via C-locale coercion, so the exposed population is Ubuntu 18.04 /
  CentOS-7-era hosts. Verified **by reading only**; not reproducible here (Python 3.12,
  `LANG=en_US.UTF-8` in the manager environment). Severity is bounded: the crash occurs before any
  fetch, nothing is written or corrupted, and it fails loudly in the journal — strictly more
  informative than today's `203/EXEC`. But it is a way the fix can *appear not to work* on exactly the
  hosts the project promises to support. Every available remedy lies outside this task's boundary (an
  `Environment=` directive the requirement forbids, or a `bin/sc` edit T-02 owns). **Follow-up row.**

**C-2 — the uninstaller never runs `systemctl reset-failed`.** `uninstall.sh:113-130` disables the
timer, deletes the unit files and reloads, so a unit that entered `failed` can linger in
`systemctl --failed` after uninstall. Re-verified true this task (`git grep reset-failed` over shipped
code returns nothing). This is the one item the owner asked to be reported even though it is not fixed
here — and it nearly evaporated: stage 1 mis-cited it as carried by B-7/AC-3, which are scoped to
`/usr/local/bin/proxy` only, so no acceptance criterion actually bound it until the gate caught it.
**Follow-up row.**

**D-4 — `systemd-analyze verify` is a narrow gate**, not general unit lint (see the mutation controls
in §4). Do not read AC-13 as broader assurance than it gives.

**F-4 — a wrong fact is being inherited across tasks.** Stage 1's E-17 claims all `B.*` checks in
`verify_all` are `SKIP`. False: `verify_all.sh:52-68` runs a real B.1 syntax gate (`py_compile bin/sc`,
`bash -n install.sh`, `bash -n uninstall.sh`) that passes today; only B.2/B.3 are `SKIP`. No
consequence here, but the root cause is a stale line in `.harness/rules/50-singbox-cli.md:34-36`, so
the error will keep propagating into future tasks until the rule file is corrected. **Follow-up row.**

**Two documentation-precision defects, report-only, no rework:**

- AC-3 ("no occurrence of `/usr/local/bin/proxy` anywhere in the repository") is literally
  unsatisfiable — `01_REQUIREMENT_ANALYSIS.md` contains the literal **five times, including inside
  AC-3's own table cell**, as do the insight index and eleven archived-doc lines. It was already false
  on a clean tree. The operative reading is the one AC-3's own verification column supplies
  ("enumerate every hit with its disposition"), which was satisfied. Do not reuse that phrasing as a
  literal gate.
- `04_DEVELOPMENT.md:401` claims gate condition C-5 discharged while two of its clauses were still
  stage-7 obligations. Both are discharged in §3 above (the third catch-up path; the "within minutes
  of the push" phrasing).

**Not fixed, correctly:** `After=network-online.target` with no `Wants=` (pre-existing, inert for a
timer firing days after boot); the OpenRC periodic script at `bin/sc:1217` (already correct — verified,
deliberately not unified with the systemd unit, since two init systems each writing their own
invocation is the domain shape, not a duplication defect).

---

## 6. Routing decisions worth recording

- **Stage 1 armed a conditional escalation and it did not fire.** If `daemon-reload` had proven
  insufficient, the repair would have required editing `install.sh` — out of scope (T-01) — and would
  have come back to the owner rather than being resolved by silently widening scope. The analyst wrote
  that trigger explicitly instead of assuming the convenient answer.
- **A rollback was considered at stage 5 and declined.** The code reviewer's C-5 bookkeeping MINOR
  offered two remedies: a one-line developer edit, or the PM restating C-5 at stage 7. Sending the task
  back through a full development stage to correct a sentence in a stage document — tracking an
  obligation the PM discharges personally at stage 7 — would have burned a stage to buy nothing. Taken
  the second; discharged in §3.
- **Stages 3 and 5 have read-only tool sets** and returned their documents as text; the PM transcribed
  `03_GATE_REVIEW.md` and `05_CODE_REVIEW.md` verbatim, adding no content. Noted because a PM writing
  into a stage document is normally a red line.
- **QA self-disclosed a near-miss:** its first draft was 515 lines and did trip `verify_all` F.6 to
  WARN — exactly the trap gate condition C-4 predicted. It compacted the document rather than touch the
  gate.

---

## 7. Next steps for the owner

1. **Review and commit.** Nothing was committed or pushed. The shipping diff is two files:
   `systemd/sing-box-rules-update.service` and `CHANGELOG.md`.
2. **Push to `main`** — `curl | bash` users are served from `REF="main"` and pick the fix up within
   minutes of the push.
3. **File the follow-up rows** surfaced above: R-1 (weekly restart on an unchanged run), C-1 (systemd
   service environment: `SB_BIN` PATH dependency + Python-3.6 encoding exposure), C-2 (uninstaller
   `reset-failed`), F-4 (stale `B.*`-are-all-SKIP claim in `.harness/rules/50-singbox-cli.md:34-36`,
   which is propagating into task documents).
4. **Consider a real triggered run as post-release verification.** Link 4 of the chain (§4) is the only
   part resting on argument, and no host in this project has ever observed the timer fire successfully.

---

## Insight

- 2026-07-31 · `systemd-analyze verify` only catches an unresolvable absolute `ExecStart`; a bare PATH
  lookup, CRLF line endings and `/usr/bin/env` indirection all exit 0, so it proves a wrong-path defect
  is gone but is not general unit lint · evidence: fix-rules-update-execstart
- 2026-07-31 · A systemd timer's stamp advances when the timer elapses and *enqueues* the job, not when
  the service succeeds, so a unit failing `203/EXEC` still advanced its stamp weekly and `Persistent=true`
  produces no catch-up burst once the command is fixed · evidence: fix-rules-update-execstart
- 2026-07-31 · An acceptance criterion of the form "no occurrence of `<literal>` anywhere in the
  repository" is self-violating, because the requirement document stating it contains the literal — here
  five times, once inside the criterion's own table cell · evidence: fix-rules-update-execstart
- 2026-07-31 · The systemd manager's default service `PATH` on this project's hosts includes
  `/usr/local/bin`, which is the only reason `bin/sc:31`'s bare `SB_BIN = "sing-box"` lookup resolves
  when the CLI runs from a unit rather than a login shell · evidence: fix-rules-update-execstart
