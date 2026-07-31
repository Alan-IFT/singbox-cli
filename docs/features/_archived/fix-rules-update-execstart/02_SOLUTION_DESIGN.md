# 02 — Solution Design · T-09 `fix-rules-update-execstart`

> Mode: **full** · Deferred-human (defer, do not ask) · 2026-07-31
> Upstream (read-only, **not edited here**): `docs/features/fix-rules-update-execstart/01_REQUIREMENT_ANALYSIS.md` (verdict **READY**).
> Rules loaded: `00-core`, `05-insight-index`, `25-decision-policy`, `50-singbox-cli`, `80-delivery-policy`, `85-design-discipline`.
> Memory read: `.harness/insight-index.md` (lines 12 and 14 both bind — §11, §12); `.harness/rejected-decisions.md`
> (`ruleset-unit-tests-in-t02` binds §12); `CONTEXT.md` (untouched stub — this task coins no domain term, so nothing is appended).

---

## 1. Architecture summary

One byte-range in one file changes: `systemd/sing-box-rules-update.service:7` stops naming a binary this
project has never installed (`/usr/local/bin/proxy`) and names the one it does install (`/usr/local/bin/sc`).
Nothing else moves — no new module, no new seam, no new dependency, no installer or CLI change. At the system
level, an already-wired but permanently dead edge in the runtime graph (`…update.timer` → `…update.service` →
*nonexistent executable*) becomes live for the first time, so the weekly `.srs` refresh advertised in both
READMEs (`README.md:14`, `README.zh-CN.md:14`) starts executing the exact code path a manual
`sudo sc update-rules` already executes today. Because that edge becomes live, pre-existing behaviours behind
it become *reachable on a schedule* for the first time (weekly restart of sing-box, genuine `failed` state on
network-restricted hosts) — determining and documenting those is this design's real work, not the edit.

---

## 2. Affected modules

| File | Change | Owner-stated boundary |
|---|---|---|
| `/home/alan/Programs/singbox-cli/systemd/sing-box-rules-update.service` | **edit, line 7 only**: `proxy` → `sc` | in scope (the whole code change) |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | **edit**: one bullet appended to `## [Unreleased]` → `### 修复` | in scope — decision recorded in §8 |
| `/home/alan/Programs/singbox-cli/docs/features/fix-rules-update-execstart/*` | stage documents | in scope |

**No other tracked file changes.** Read but deliberately untouched: `install.sh`, `bin/sc`, `uninstall.sh`,
`systemd/sing-box.service`, `systemd/sing-box-rules-update.timer`, both READMEs, `verify_all.sh`.

### 2.1 The exact edit

Before (`systemd/sing-box-rules-update.service:7`):

```
ExecStart=/usr/local/bin/proxy update-rules
```

After:

```
ExecStart=/usr/local/bin/sc update-rules
```

Binding constraints on the edit (from B-1, B-2, BC-12):

- Replace the substring `proxy` with `sc` on line 7 **and nothing else**. Lines 1-6 and the file's
  terminating newline are byte-identical before and after; the resulting diff is `1 insertion(+), 1 deletion(-)`.
- Absolute path, literal, no `/usr/bin/env`, no quoting, no variable — systemd runs no shell.
- No trailing whitespace on line 7; file ends with exactly one `\n`.
- Do not add `User=`, `Environment=`, `ExecStartPre=`, `ExecStartPost=`, `Condition*=`, `Restart=`,
  `SuccessExitStatus=`, `[Install]`, or a second `ExecStart=`.

---

## 3. Module decomposition

**No new module.** Nothing is created, extracted, renamed, or generalised.

Explicitly, per the brief and per `.harness/rules/85-design-discipline.md`: **no abstraction is invented to
unify the systemd unit's invocation with the OpenRC periodic script's** (`bin/sc:1210-1218`, which already
writes `#!/bin/sh\n/usr/local/bin/sc update-rules\n` and is correct). The analyst ran the two seam tests
(01 §4 item 1); this design re-ran them and confirms the result:

1. *Patch-then-patch seam* — fails. Neither artifact computes anything the other consumes: the unit file is a
   static asset copied by `install.sh:407`; the OpenRC script is a string written by a Python function at
   runtime. No intermediate state; each is a complete, honest artifact on its own.
2. *Duplicated judgment* — fails. Neither side *decides* anything. "Which binary do I exec" is one literal
   appearing in five already-agreeing places (`install.sh:376,438,456,479`, `bin/sc:78`) plus the one that
   did not — not a judgment with a right answer to centralise.
3. *Shape check* — the layout (`systemd/` holds unit assets, `bin/sc` holds the CLI) mirrors the domain.

A shared constant would have to span a Bash-copied `.ini` asset and a Python string literal — i.e. a template
and a build stage, in a project that deliberately has **no build step** (`docs/dev-map.md:22`,
`.harness/rules/50-singbox-cli.md:22-27`). Under 85's counter-rule ("if you cannot name the future edit it
prevents, it is not justified"), the only edit it would prevent is a rename of the `sc` binary, which already
has a working handling path (`uninstall.sh:132-134`). **The owner's suggested shape is the right
granularity; this design keeps it and says so, as 85 requires.**

---

## 4. Data model changes

None. No schema, no config file format, no new state file, no new key in `/etc/sing-box/settings.json`.
One piece of *pre-existing* persistent state matters to the delivery text and is therefore named here:
systemd's timer stamp file `/var/lib/systemd/timers/stamp-sing-box-rules-update.timer`, whose mtime is the
last trigger time and which drives `Persistent=true`. This task neither creates nor writes it; §8 analyses
what it already contains.

---

## 5. Contracts

### 5.1 The unit ↔ CLI contract (the only interface that changes)

| Element | Value | Source of truth |
|---|---|---|
| Executable | `/usr/local/bin/sc` | `install.sh:376` (`install -m 755 "$ARTIFACT_DIR/bin/sc" /usr/local/bin/sc`) |
| Argv | `update-rules` (single argument, no flags) | `bin/sc` `cmd_update_rules`, invoked identically at `install.sh:456` |
| uid at exec | 0 (system unit, no `User=`) → the import-time auto-elevate at `bin/sc:77-78` does not fire | B-4 |
| Success | exit 0 → unit goes `activating` → `inactive (dead)`; unit leaves `systemctl --failed` | `Type=oneshot` semantics |
| Failure | exit non-zero (T-02 exit-status contract, `bin/sc:1139-1140`) → unit enters `failed`, `Result=exit-code` | B-3 |
| Missing executable | `203/EXEC`, `Result=exit-code` | BC-6 — deliberately unguarded (01 §8 Q8) |
| Output | stdout = per-file causes, stderr = aggregates; both captured by the journal, no `\r` in non-TTY mode | insight-index line 11 + `docs/dev-map.md:65-68` |

The path literal must be byte-identical across all five in-repo sites (AC-2) — `install.sh:376`, `:438`
(sudoers `NOPASSWD:`), `:456`, `:479`, `bin/sc:78` — and now the unit. Verified this task: all five already
read `/usr/local/bin/sc`.

### 5.2 What does *not* change

`sing-box-rules-update.timer` (`OnCalendar=weekly`, `RandomizedDelaySec=1h`, `Persistent=true`,
`WantedBy=timers.target`), the implicit timer→service binding by unit name, the `.timer.d/override.conf`
cadence mechanism written by `sc update-interval` (`bin/sc:1167-1171`), the sudoers scope, every `bin/sc`
code path.

---

## 6. Flow

### 6.1 Runtime flow after the fix (steady state)

```
timers.target
   └─ sing-box-rules-update.timer     [OnCalendar=weekly + up to 1h random delay;
       │                                cadence overridable via .timer.d/override.conf]
       │  elapses ──► writes /var/lib/systemd/timers/stamp-…timer  (unconditional, see §7)
       ▼
   sing-box-rules-update.service      [Type=oneshot, root, After=network-online.target sing-box.service]
       │
       ▼  execve("/usr/local/bin/sc", ["sc", "update-rules"])      ← THE FIX (was: .../proxy → 203/EXEC)
   bin/sc cmd_update_rules
       ├─ per rule-set: multi-mirror validated fetch → atomic replace         (T-02, bin/sc # Rule-sets)
       ├─ gained ∧ config.json exists → generate_config() → restart_service() (bin/sc:1129-1138)
       ├─ any failure                → sys.exit(non-zero)                     (bin/sc:1139-1140)  → unit `failed`
       └─ nothing gained ∧ is_running() → restart_service()                   (bin/sc:1141-1143)  → BC-10
       ▼
   journal (`journalctl -u sing-box-rules-update.service`)
```

### 6.2 Upgrade flow on an already-broken host (B-5, BC-2 — installer unmodified)

```
sudo bash -c "$(curl -fsSL …/main/install.sh)"   |   sudo ./install.sh
   step 0  ARTIFACT_DIR: local repo, or curl of the 5 artifacts from REF=main   install.sh:307-330
   step 3  install -m 755 bin/sc → /usr/local/bin/sc                            install.sh:376
   step 4  install -m 644 systemd/sing-box-rules-update.service → /etc/systemd/system/   install.sh:407
           systemctl daemon-reload                                              install.sh:409   ◄── makes it effective (§7)
   step 6  /usr/local/bin/sc update-rules      (rule-sets already refreshed by the upgrade itself)  install.sh:456
   step 7  systemctl enable  sing-box-rules-update.timer || true                install.sh:472
           systemctl start   sing-box-rules-update.timer || true                install.sh:486
```

**AC-5 ordering check, performed this task.** Lines 405-409 form one `if [ "$INIT_SYS" = "systemd" ]` block
with no early return, no `||`, no subshell, no skippable command; under `set -euo pipefail` (`install.sh:9`)
the only way not to reach line 409 is an `install -m 644` failure, which aborts the installer loudly (R-3).
The block runs **before** the two steps allowed to fail (step 6 rule-sets, step 7 config), so unit
installation is independent of ruleset/config success — the T-01 property (`493eb6a`) that B-5 leans on.

---

## 7. D-1 · Q1 determination — is `daemon-reload` sufficient, or is a timer restart required?

**Answer: reload alone is sufficient. A `systemctl restart sing-box-rules-update.timer` is NOT required.**
Requirement §8 Q1 option **(a)** is confirmed. **This is not a scope escalation**; `install.sh` stays
untouched and the fix remains inside the owner's diff boundary.

### 7.1 Why (mechanism)

1. **What changed is the `[Service]` fragment, not the `[Timer]` fragment.** The timer unit file is
   byte-unchanged, so the timer has nothing new to read. A timer restart re-reads and re-arms the *timer*;
   it does not re-read the service fragment and could not make a service change "more effective".
2. **`systemctl daemon-reload` re-reads unit files from disk and rebuilds the dependency tree**, preserving
   the runtime state of active units. After it, the manager's in-memory fragment for
   `sing-box-rules-update.service` is the new file. The reload is *necessary* (the timer keeps the service
   unit referenced and therefore loaded, so systemd would otherwise keep serving the cached old fragment) —
   and `install.sh:409` performs it unconditionally on the systemd branch.
3. **A `Type=oneshot` service has no process between triggers.** The caveat that makes unit-file changes
   "take effect at next start" — that a currently-running process keeps the settings it was started with —
   cannot apply: the unit sits in `inactive (dead)` or `failed`, with no process and no queued job. The next
   activation is therefore a fresh start against the reloaded fragment.
4. **The timer→service link is by unit name** (implicit `Unit=sing-box-rules-update.service`, derived from the
   timer's own name), resolved to whatever fragment the manager currently holds for that name — the reloaded
   one. Nothing about the link is snapshotted at timer-start time.
5. **`failed` does not block the next activation.** It is an inactive state; a new start job runs normally
   from it, and the default start-rate limit (`DefaultStartLimitIntervalSec=10s`, `DefaultStartLimitBurst=5`,
   with no `StartLimit*` in the unit) is unreachable at a weekly cadence. The ~100% of hosts currently in
   `failed` therefore need no intervention for the next trigger to run correctly (BC-3).

### 7.2 Why (in-repo precedent — both directions agree)

- **`bin/sc:1167-1179` restarts the timer, and only the timer, and only after writing a *timer* change.**
  `cmd_update_interval` writes `.timer.d/override.conf` (an `OnCalendar=` change), then `daemon-reload`, then
  `systemctl restart sing-box-rules-update.timer` — because an already-armed timer must be re-armed to pick
  up a new calendar expression. That precedent draws the line *between* timer and service changes; it does
  not extend to service changes.
- **`install.sh:405-409` rewrites all three unit files and restarts nothing.** The project has shipped
  `sing-box.service` changes through reload-only semantics for its whole history (including T-01, `493eb6a`)
  — and that is a *long-running* unit, the harder case. A oneshot unit is strictly easier.

### 7.3 Consequence for the design

`install.sh` is **not** modified, and no post-install command is added anywhere. The user-facing note in
§9 is what makes the answer visible; nothing in the product needs to change to make the fix take effect.

> Residual, stated honestly: a user who edits `/etc/systemd/system/sing-box-rules-update.service` **by hand**
> instead of re-running the installer must `sudo systemctl daemon-reload` themselves — so the delivery text
> leads with the installer path (B-5) and mentions the reload only for the hand-edit case.

---

## 8. D-2 · BC-11 confirmation — no immediate catch-up run (and the two exceptions)

**Confirmed, with one exception class that the delivery text must carry.** The analyst's reasoning holds.

### 8.1 The main case (host up, timer active — the overwhelming majority)

`Persistent=true` makes systemd compute the timer's next elapse from a stored base rather than from "now",
and fire immediately if that elapse is already past. The base is the last trigger time, persisted in
`/var/lib/systemd/timers/stamp-sing-box-rules-update.timer`.

The decisive fact: **the stamp is written when the timer elapses and successfully enqueues the start job —
not when the triggered service succeeds.** A `203/EXEC` failure happens in the forked child *after* the job
was enqueued and the unit began activating; the unit was loadable and its fragment parsed fine (the path was
wrong, not the syntax). Every weekly elapse since installation therefore advanced the stamp exactly as it
would on a healthy host. The stamp is current (≤ one calendar period old), the computed next elapse is in the
future, and neither `daemon-reload` nor the fix produces a catch-up run. **The first corrected run happens at
the next scheduled boundary plus up to `RandomizedDelaySec=1h`.** A host with **no** stamp file (fresh
install, or one that never reached timer start before T-01) also gets no catch-up: with no stored trigger,
systemd bases the calendar computation on the manager's userspace-start timestamp, yielding a future elapse.

### 8.2 Empirical confirmation available to QA and to the user (read-only, unprivileged)

```
systemctl list-timers --all sing-box-rules-update.timer --no-pager
systemctl show -p LastTriggerUSec --value sing-box-rules-update.timer
```

`LAST` within the current calendar period on a host whose service has been failing is the direct observation
that the stamp advances independently of the service's outcome. Both are D-Bus reads: neither starts, stops
nor reloads anything, and this repo's dev host is installed (§12), so the observation is available here.

### 8.3 The exceptions the delivery text must carry

| Case | What happens | Note |
|---|---|---|
| Timer was **stopped/disabled** and a stale stamp exists (older than the previous boundary); the upgrade's `install.sh:486` starts it | `Persistent=true` fires a catch-up run within moments of the install | Now that run *works* — it re-downloads what step 6 just downloaded and, per `bin/sc:1141-1143`, **restarts sing-box** if it is running. A short connection drop right after an upgrade is possible and must not surprise the user. |
| Host powered off across a scheduled boundary | Catch-up run shortly after the next boot | Standard `Persistent=true` behaviour, unchanged by this task — but now it executes instead of failing. |

---

## 9. D-3 · The user-facing repair recipe (B-6, AC-7)

The three answers, exactly as `07_DELIVERY.md` must state them (and `CHANGELOG.md` in condensed form).

**(0) Apply the fix — the documented upgrade path, nothing else needed:**

```
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"
# or, from a clone:  sudo ./install.sh
```

This replaces `/etc/systemd/system/sing-box-rules-update.service` (`install.sh:407`) and runs
`systemctl daemon-reload` (`install.sh:409`) in the same run. **No timer restart, no manual unit edit, no
`sed`, no migration step** (§7). Optional read-only confirmation that the loaded definition is the new one:

```
systemctl cat sing-box-rules-update.service                                  # what is on disk
systemctl show -p ExecStart --value sing-box-rules-update.service            # what the manager has loaded
```

**(a) Trigger one corrected run immediately** instead of waiting for the next weekly boundary:

```
sudo systemctl start sing-box-rules-update.service
systemctl status sing-box-rules-update.service --no-pager
journalctl -u sing-box-rules-update.service -n 50 --no-pager
```

Because the unit is `Type=oneshot`, `systemctl start` blocks until `sc update-rules` finishes and its exit
status reflects the run. **Caveat that must be printed with the command:** if sing-box is running, this run
restarts it (`bin/sc:1135-1143`) — expect a few seconds of connection interruption. A user who only wants
fresh rule-sets can equivalently run `sudo sc update-rules`; the restart caveat is identical, since it is the
same code path. This step is *optional* — right after an upgrade the rule-sets are already fresh, because
`install.sh:456` ran `sc update-rules` during the install.

**(b) Clear the residual `failed` state immediately:**

```
sudo systemctl reset-failed sing-box-rules-update.service
```

This only clears the bookkeeping entry; it runs nothing.

**(c) When it clears by itself:** on the **next successful start** of the unit — step (a), the §8.3 catch-up,
or the next weekly trigger. A successful oneshot run ends `inactive (dead)` and the unit disappears from
`systemctl --failed`. If the next run also fails (e.g. all mirrors unreachable, BC-7) the unit re-enters
`failed` with the new, *genuine* cause — the point being that the state is now informative rather than
permanent. The residual `failed` never blocks anything (§7.1 item 5).

---

## 10. D-4 · The `CHANGELOG.md` decision

**Decision: `CHANGELOG.md` IS edited — one bullet, Simplified Chinese only.** Requirement §3 B-9/B-10 and
§6 AC-9 are followed as written.

Reasoning (the owner's brief and the requirement are reconciled, not traded off):

1. **The requirement is binding and I may not edit it.** B-9 mandates the entry, B-10 puts the file inside the
   diff boundary; dropping it would contradict an upstream `READY` document, which under this role's hard
   rule #1 would have to be `BLOCKED`, not a silent narrowing. B-9 is coherent and cheap — nothing to escalate.
2. **The owner's "one line in one unit file" describes the *code* change**, and the four named do-not-touch
   files are precisely the ones with a competing task owner (`install.sh` → T-01, `bin/sc` → T-02,
   `uninstall.sh`, `systemd/sing-box.service`/`.timer`). `CHANGELOG.md` has neither owner nor behavioural risk.
3. **Repo precedent is unanimous:** every landed fix in this pool wrote a `### 修复` bullet — `CHANGELOG.md:14`
   (T-01), `:11` (T-02), `:13` (Clash-API port). Skipping it would leave the most user-visible defect of the
   three as the only one with no user-visible record — and this one uniquely *requires a user action*
   (re-run the installer) and leaves a visible artifact on every host (`systemctl --failed`).
4. **Language: zh only** (Q6 a). `CHANGELOG.md:1-37` is uniformly Simplified Chinese including `[Unreleased]`;
   bilingual parity binds runtime strings and the paired READMEs (`.harness/rules/50-singbox-cli.md:88-90`),
   and a lone bilingual entry would break the file's consistency with no owner instruction to convert it.

**Placement (deterministic, so the developer needs no judgment):** append **one** new `- ` bullet as the
**last** item of `## [Unreleased]` → `### 修复`, i.e. immediately after the current `CHANGELOG.md:14` bullet
(`**安装器如实报告安装结果**`), keeping the blank-line rhythm of lines 12-14. Do not touch `### 新增` or
`## [0.1.0]`, do not add a heading, do not reorder existing bullets.

**Content requirements** (all four, in the file's existing verbose style — exact prose is the developer's;
these are the load-bearing facts): (1) the defect — `ExecStart` pointed at `/usr/local/bin/proxy`, a file this
project never installs, so every weekly trigger failed `203/EXEC` and the advertised auto-update never ran on
any systemd host; (2) the fix — the unit now runs `/usr/local/bin/sc update-rules`; (3) the user action —
re-run the install one-liner (or `sudo ./install.sh`), which reloads systemd itself, so no manual unit edit
and **no timer restart** are needed; (4) what to expect — no immediate catch-up run (first corrected run at
the next scheduled point, ≤1 h random delay), `sudo systemctl start sing-box-rules-update.service` to run one
now **with the note that it restarts sing-box when the service is running**, and
`sudo systemctl reset-failed sing-box-rules-update.service` to clear the leftover `failed` entry, which
otherwise clears on the next successful run.

---

## 11. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Rule-set download + validation + atomic replace | `cmd_update_rules` / `_fetch_to_temp` / `srs_reject_reason` | `/home/alan/Programs/singbox-cli/bin/sc` `# Rule-sets` | **Reuse as-is** — the unit calls exactly the CLI verb the installer and the OpenRC script already call. Nothing is reimplemented for the timer path. |
| Correct invocation string for the CLI | `#!/bin/sh\n/usr/local/bin/sc update-rules\n` | `/home/alan/Programs/singbox-cli/bin/sc:1217` (OpenRC periodic script) | **Copy the literal, do not factor it out** — §3 seam tests fail; a shared constant would need a template/build step this project does not have. |
| Authoritative install path for the CLI | `install -m 755 … /usr/local/bin/sc` | `/home/alan/Programs/singbox-cli/install.sh:376` | **Reuse as the source of truth** for the value written into the unit (AC-2), and as the assertion target in verification (§12 V-2). |
| Deploying the corrected unit to existing hosts | step 4: `install -m 644` ×3 + `systemctl daemon-reload` | `/home/alan/Programs/singbox-cli/install.sh:405-409` | **Reuse as-is, unmodified** — already sufficient (§7); this is why B-5 needs no installer change. |
| Making the fix reach `curl \| bash` users | `RAW_BASE` at `REF="main"` + the 5-artifact fetch loop | `/home/alan/Programs/singbox-cli/install.sh:11-13,317-329` | **Reuse as-is** — `systemd/sing-box-rules-update.service` is already in the fetch list (line 321), so remote installs pick up the corrected file the moment the commit lands on `main` (BC-13). |
| Timer cadence + persistence | `OnCalendar=weekly`, `RandomizedDelaySec=1h`, `Persistent=true` | `/home/alan/Programs/singbox-cli/systemd/sing-box-rules-update.timer:4-7` | **Reuse as-is** — nothing to change (E-10). |
| Restart-the-timer precedent (for §7's determination) | `cmd_update_interval` systemd branch | `/home/alan/Programs/singbox-cli/bin/sc:1167-1179` | **Cited, not touched** — it bounds *when* a timer restart is needed; a `[Service]` change is outside that bound. |
| Legacy `proxy` name cleanup | `rm -f /usr/local/bin/sc /usr/local/bin/proxy` + sudoers twin | `/home/alan/Programs/singbox-cli/uninstall.sh:132-134` | **Retain deliberately** — the only two surviving `/usr/local/bin/proxy` literals in shipped code after this change; they are intentional pre-rename cleanup, not stale invocations (B-7/AC-3). |
| Unit-file lint | `systemd-analyze verify systemd/*.service` | `.harness/rules/50-singbox-cli.md:131` (named as a candidate, **not wired**) | **Run manually in QA, do NOT wire into `verify_all`** — wiring it would change the gate's PASS/SKIP counts and break AC-12, and `.harness/rejected-decisions.md § ruleset-unit-tests-in-t02` defers gate wiring to T-07. |
| New module for anything here | — | — | **None justified.** No new file, no new dependency, no new library, no new service. |

---

## 12. Verification design (static, unprivileged, no live mutation)

Hard constraints honoured: no root, no `systemctl` write command
(`start`/`stop`/`enable`/`disable`/`daemon-reload`/`reset-failed`), no `install.sh` / `uninstall.sh`
execution, and — per `.harness/insight-index.md` line 14 — **no execution and no import of `bin/sc` in any
form**: its import-time auto-elevate (`bin/sc:77-78`) re-execs the *installed* `/usr/local/bin/sc` under
`sudo`, whose `env_reset` drops overrides, so an un-neutralised import does not fail — it drives the live
tool against the live service. **This host has `/usr/local/bin/sc` installed** (confirmed this task by
listing `/usr/local/bin/`), so the hazard is real here, not theoretical. Every check below is read-only.

| # | Check | Command shape (read-only) | Asserts |
|---|---|---|---|
| V-1 | Exactly one `ExecStart=` in the unit, value exactly `/usr/local/bin/sc update-rules` | `grep -c '^ExecStart=' systemd/sing-box-rules-update.service` → `1`; `grep '^ExecStart=' …` string-equals `ExecStart=/usr/local/bin/sc update-rules` | AC-1, B-1, BC-12 |
| V-2 | Unit path == path the installer installs to == sudoers path == auto-elevate target == the two installer call sites | extract with `grep` from `install.sh:376`, `install.sh:438`, `install.sh:456`, `install.sh:479`, `bin/sc:78` and compare literals | AC-2 |
| V-3 | Nothing else in the unit moved | `git diff -- systemd/sing-box-rules-update.service` shows exactly one changed line, `1 insertion(+), 1 deletion(-)`; `git diff --stat` confirms | AC-4, B-2 |
| V-4 | Stale-path sweep | `git grep -n '/usr/local/bin/proxy'` → shipped-code hits are exactly `uninstall.sh:133` and (`proxy` sudoers twin) `uninstall.sh:134`; all other hits are `docs/` and `.harness/` prose | AC-3, B-7 |
| V-5 | Out-of-scope files byte-unchanged | `git diff --name-only` contains only `systemd/sing-box-rules-update.service`, `CHANGELOG.md`, `docs/features/fix-rules-update-execstart/*` | AC-8, AC-10, B-10 |
| V-6 | Unit still parses | `systemd-analyze verify systemd/sing-box-rules-update.service` (read-only parse + stat; starts nothing, needs no root) | AC-13 |
| V-7 | Gate unchanged | `bash .harness/scripts/verify_all.sh` before and after; PASS/WARN/FAIL/SKIP delta 0, no FAIL | AC-12 |
| V-8 | Installer ordering claim | re-read `install.sh:405-409` and its position relative to steps 6-7; no early exit between the `install -m 644` calls and `daemon-reload` | AC-5 |
| V-9 | `CHANGELOG.md` entry | one new bullet, last in `[Unreleased] / 修复`, zh-only, carries all four facts of §10 | AC-9 |

**Interpreting V-6 correctly (host-dependent, tell QA explicitly).** `systemd-analyze verify` stats the
`ExecStart` binary and reports an error when it is missing. Therefore:

- On a host **with** `/usr/local/bin/sc` installed (including this one): the pre-change file reports an error
  naming `/usr/local/bin/proxy`, the post-change file must report **no** such error. That disappearance *is*
  the discriminating evidence — capture both outputs in `06_TEST_REPORT.md`.
- On a host **without** the CLI: both versions report a missing-executable error and the check proves only
  that the unit parses. Record it as such, not as a failure of this change.
- Unrelated notices (e.g. `After=sing-box.service` absent) are pre-existing. If `systemd-analyze` is missing
  entirely, record AC-13 as SKIP with the reason.

**Explicitly not designed:** any test that imports, execs or subprocess-invokes `bin/sc`; any container/VM
install run; any new file under `tests/`; any new `verify_all` step.

---

## 13. Risk analysis

| # | Risk | Likelihood / impact | Mitigation (designed, not hoped) |
|---|---|---|---|
| R-1 | The fix makes the weekly run real, and `bin/sc:1141-1143` restarts sing-box even when **no** rule-set changed → every host silently gains a weekly connection drop (BC-10, E-13). | Certain / medium (seconds of downtime, weekly, possibly mid-session) | Out of this task's scope by owner decision (T-02 owns `bin/sc`), but **must not be discovered by users first**: AC-14 forces it into `07_DELIVERY.md`, the §9 recipe repeats the caveat on the manual-run command, and PM files a follow-up row to make the restart conditional on an actual config change. Not silently absorbed. |
| R-2 | Hosts on restricted networks move from a *constant, ignorable* `203/EXEC` failure to a *genuine, intermittent* failure (BC-7) — users may read the new failure as caused by this change. | Medium / low | `07_DELIVERY.md` states the difference and points at `journalctl -u sing-box-rules-update.service` plus the per-file causes on stdout (insight-index line 11); §9 (c) explains that re-entering `failed` with a real cause is now the informative outcome. |
| R-3 | The upgrade's `install -m 644` succeeds for the `.service` but the installer aborts before `install.sh:409` (read-only `/etc`, disk full) → corrected file on disk, manager still serving the cached old fragment. | Very low / low | `set -euo pipefail` makes the installer exit non-zero and print the failing command, so the state is loud, not silent. The corrected file is already correct on disk; any later `daemon-reload` or reboot activates it. Nothing to add — documented as a known residual, and the fix is idempotent, so re-running the installer resolves it. |
| R-4 | A user hand-edits `/etc/systemd/system/sing-box-rules-update.service` instead of re-running the installer and does not `daemon-reload` → still broken, and they conclude the fix does not work. | Medium / low | §9 leads with the installer path and mentions `sudo systemctl daemon-reload` only for the hand-edit case; §9 (0) gives the read-only `systemctl show -p ExecStart --value …` command that proves what the manager actually loaded. |
| R-5 | The `Persistent=true` catch-up exception of §8.3 fires right after an upgrade on hosts whose timer was inactive → sing-box restarts moments after install, contradicting a delivery text that promised "no immediate run". | Low / medium (credibility of the delivery text) | The delivery text states the main case **and** its two exceptions verbatim from §8; the claim shipped is "no catch-up on a host whose timer has been triggering", not an unqualified "never". |
| R-6 | The developer "helpfully" adds a `ConditionPathExists=`, `Wants=network-online.target`, `User=`, or a second `ExecStart` while in the file. | Low / medium (turns a loud failure into a silent skip; contradicts B-2/BC-6 and 01 §8 Q5/Q8) | §2.1 lists the forbidden directives explicitly; V-3 asserts a one-line diff, which makes any addition a hard verification failure, not a review opinion. |
| R-7 | Scope creep into `install.sh` to add `reset-failed` / an immediate `systemctl start`. | Low / high (breaks the diff boundary, collides with T-01) | §7.3 establishes that no installer change is needed; 01 §8 Q2/Q3 already recorded the decision; V-5 asserts `install.sh` is byte-unchanged. Q2 (b)/(c) and Q9 are re-homed to follow-up rows, not dropped. |

---

## 14. Migration / rollout plan

1. **Backward compatibility.** Total. The unit file is a leaf artifact: nothing else parses it, no state file
   references it, no CLI code reads it. Hosts that never install it (OpenRC/Alpine, BC-5) are unaffected
   byte-for-byte. No version skew exists — old `sc` + new unit works (the `update-rules` verb predates this
   task); new `sc` + old unit is exactly today's broken state.
2. **Feature flag: none, none warranted** — the change repairs a path that has never worked, so there is no
   prior behaviour to preserve behind a flag. **Data migration: none** (§4).
3. **Rollout sequence.** (a) Commit the corrected unit + the `CHANGELOG.md` bullet to `main`
   (`.harness/rules/80-delivery-policy.md` already authorises commit + push to `main`). (b) From that moment,
   and not one moment before, every **remote** install/upgrade (`install.sh:11-13,317-329`, `REF="main"`)
   serves the corrected file (BC-13) — `07_DELIVERY.md` must say this plainly so nobody expects hosts to
   self-heal. (c) Existing hosts are repaired **only** by re-running the documented install path (§9 step 0);
   no push mechanism exists and none is designed. (d) First corrected automatic run: next `OnCalendar=weekly`
   boundary + ≤1 h (§8), except for the §8.3 cases.
4. **Rollback.** `git revert` of the one-line commit; hosts revert on their next installer run. That restores
   a known-broken state, so the only realistic trigger is the newly-live weekly run proving harmful (R-1) —
   for which the cheaper per-host remedy is `sudo systemctl disable --now sing-box-rules-update.timer`,
   needing no release.
5. **Post-release watch item.** R-1's weekly restart is the one behaviour whose real-world effect appears only
   a week after rollout; its follow-up row must be filed at delivery, not after the first complaint.

---

## 15. Out-of-scope clarifications (design boundaries)

This design does **not** cover, and the developer must not implement:

1. Any change to `install.sh` (T-01, `493eb6a`) — including `reset-failed`, an immediate
   `systemctl start sing-box-rules-update.service`, or a timer restart. §7 proves none is needed.
2. Any change to `bin/sc` (T-02, `ab4e4a4`) — including the unconditional weekly restart at
   `bin/sc:1141-1143` (report-only, R-1) and the OpenRC periodic script at `bin/sc:1210-1218` (already
   correct, verified this task).
3. Any change to `uninstall.sh` (missing `systemctl reset-failed`, E-14 / 01 §8 Q9 — report-only), to
   `systemd/sing-box.service`, or to `systemd/sing-box-rules-update.timer`.
4. Any new unit directive on the changed file (`ConditionPathExists=`, `Wants=`, `User=`, `Restart=`,
   `Environment=`, `[Install]`) — 01 §8 Q5/Q8, B-2, R-6.
5. Any abstraction, template, constant file, or build step shared between the systemd unit and the OpenRC
   script — §3.
6. Any README change — 01 §8 Q7 (a): re-verified this task that neither file-location table lists the
   `.service` path (`README.md:155-170`, mirrored at `README.zh-CN.md:164-167`), so no README statement is
   falsified, and the auto-update claim becomes *true* by virtue of the fix. Migration guidance lives in
   `CHANGELOG.md` + `07_DELIVERY.md`.
7. Any new test file, test directory, or `verify_all` B.* wiring — `.harness/rejected-decisions.md
   § ruleset-unit-tests-in-t02` defers the harness to T-07, and a new step would break AC-12's delta-0
   requirement. (Nothing new is declined by this task, so no new record is appended to that file.)
8. Any live-system action during development, review, or QA — §12.
9. The systemd/OpenRC "auto-update by default" asymmetry (an OpenRC install schedules nothing until the user
   runs `sc update-interval`) — an existing owner question in the batch plan, not re-litigated here.

**Partition assignment:** not applicable. `.harness/agents/` contains no `dev-*.md` (confirmed this task);
`.harness/rules/50-singbox-cli.md:103-114` fixes this project as single-developer. All work goes to
`harness-kit:developer`.

---

## 16. Open questions — resolutions carried forward

Every one of 01 §8's nine questions resolves to the analyst's recommended option **(a)**, each determined
against repo evidence rather than adopted by default:
**Q1** reload alone is sufficient, **no scope escalation** (§7 — the one question with teeth, determined not
assumed); **Q2** residual `failed` is documented only, with commands and self-clearing condition (§9 b/c);
**Q3** no installer-triggered run — `install.sh:456` already refreshes rule-sets during the upgrade (§9 a);
**Q4** the weekly sing-box restart is reported, not fixed (§13 R-1, follow-up row for PM);
**Q5** `After=` without `Wants=` is left as-is and **Q8** no `ConditionPathExists=` guard (§2.1, §15 item 4);
**Q6** CHANGELOG entry is zh-only (§10); **Q7** no README change, re-verified against `README.md:155-170`
(§15 item 6); **Q9** uninstaller `reset-failed` residue is reported (§15 item 3).

No question required human escalation. **No `BLOCKED: NEEDS-HUMAN` line is raised.**

---

## Verdict

**READY.**

The requirement is complete and internally consistent; no requirement defect was found and nothing here
contradicts `01_REQUIREMENT_ANALYSIS.md`. The code change is one line in one file — the owner's stated shape,
which §3 confirms is the correct granularity rather than merely the requested one. The conditional escalation
attached to Q1 **does not fire**: `daemon-reload` alone is sufficient, so `install.sh` stays out of the diff
and the fix is deliverable inside the owner's boundary. Two calls made on this design's own authority:
`CHANGELOG.md` is edited (§10), and unit-file linting stays a manual QA step rather than a `verify_all`
addition (§11, §12). Handoff to `harness-kit:gate-reviewer`, then `harness-kit:developer`, with §2.1 (the
edit), §10 (the `CHANGELOG.md` bullet) and §12 (verification) as the implementation contract.
