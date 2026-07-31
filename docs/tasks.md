# Task Board — singbox-cli

> Maintained by **PM Orchestrator**. Each task appears here when started and is updated through its lifecycle.
>
> New tasks should check this board for related historical work before planning.

## Active tasks

| ID | Slug | Stage | Started | Doc folder |
|---|---|---|---|---|
| _(none)_ | | | | |

## Completed tasks

| ID | Slug | Outcome | Completed | Doc folder |
|---|---|---|---|---|
| T-10 | ruleset-update-no-needless-restart | **DELIVERED** — `sc update-rules` no longer restarts sing-box unless a rule-set's **bytes on disk** actually changed, so the timer T-09 just made live no longer drops every connection each Monday. `bin/sc:1141-1143`'s unconditional `if not applied and is_running(): restart_service()` is gone; `ruleset_state(path) -> (status, digest)` reads each file **once** and returns both facts, so `gained ⊆ changed` holds and "exactly one apply per run" is **structural** — one `restart_service()` call site outside `reload_or_restart()`, under `if changed and CFG_PATH.exists()`. T-02's 自动恢复 preserved with its inner order verbatim and still ahead of the non-zero exit. **Hot-apply was investigated, not assumed, and declined on evidence**: Clash API has `/providers/rules` but no `ruleCount`/`vehicleType` (compatibility stub); SIGHUP recreates the instance and OpenRC defines no `reload()`; sing-box *does* fswatch local rule-sets but our own `log.level=warn` closes the only channel that could witness it — recorded as a **deferred decline**, not a rejection. **0 rollbacks** (two document-only fixes, neither a defect). `verify_all PASS: 16 / WARN: 0 / FAIL: 0 / SKIP: 2`, delta 0 vs a pristine `HEAD` QA rebuilt itself; QA 522 assertions / 0 failures / 0 product defects, with a negative control (same fixture: HEAD `['is_running','restart_service']` → change `[]`) and 4 killed mutants. Live service provably untouched by identical `MainPID` + `ActiveEnterTimestamp`. Gate's sharpest finding: **`systemctl is-active` cannot detect a restart** — the check written after T-02's incident would have passed *during* it. Product diff 3 files, +147/−31. Uncommitted; owner owns delivery. | 2026-08-01 | `docs/features/_archived/ruleset-update-no-needless-restart/` (mode: full) |
| T-09 | fix-rules-update-execstart | **DELIVERED** — `systemd/sing-box-rules-update.service:7` now runs `/usr/local/bin/sc update-rules` instead of the never-installed `/usr/local/bin/proxy`, so the README-advertised weekly ruleset auto-update can run for the first time on any systemd host. Shipping diff is 2 files: the unit (1 insertion / 1 deletion) + one zh `修复` bullet in `CHANGELOG.md`. **0 rollbacks**; the stage-1 conditional escalation (Q1) did not fire — `daemon-reload` alone is sufficient, verified on mechanism at three stages, so `install.sh` stayed out of the diff and re-running the installer is the whole upgrade. `verify_all PASS: 16 / WARN: 0 / FAIL: 0 / SKIP: 2`, delta 0 against a pristine `HEAD` baseline QA rebuilt itself. `systemd-analyze verify`: pre-change exit 1 naming `/usr/local/bin/proxy`, post-change exit 0. End-to-end ("the timer now really updates") is **reasoned, not executed** — no root, no live mutation. QA found the host contradicts two upstream premises: the unit has **never run** (timer `disabled`, no stamp, journal empty), so the "~100% of hosts are in `failed`" premise is false and the BC-11 stamp claim has zero empirical support project-wide. Uncommitted; owner owns delivery. | 2026-07-31 | `docs/features/fix-rules-update-execstart/` (mode: full) |
| T-02 | config-degrade-missing-rulesets | **DELIVERED** — one rule-set usability judgment (`SRS` magic + 16-byte floor + Content-Length equality) consumed by config generation, the downloader and the progress display. Config now degrades per file, dropping unusable rule_sets *and* their references in both `dns.rules` and `route.rules`, so sing-box starts instead of FATALing. Ordered multi-mirror validated fetch (`--mirror` / `SB_RULES_BASE`), TTY-gated per-file progress, atomic temp-then-replace, and `sc update-rules` now regenerates the config so recovery is real. 2 rollbacks (both design-origin: D-1 cause-discarding → A-1; zh `失败：` grep collision → A-2). `verify_all PASS: 16 / WARN: 0 / FAIL: 0`; QA 846/846. Absorbed the former T-03 and the ruleset-progress row. Uncommitted; owner owns delivery. | 2026-07-31 | `docs/features/config-degrade-missing-rulesets/` (mode: full) |
| T-01 | install-enable-start-split | **DELIVERED** — installer now reports its true outcome (unconditional autostart registration, real cause logged to `/var/log/sing-box/install.log`, honest banner, non-zero exit on failure). Absorbed the former T-04. `verify_all PASS: 16 / WARN: 0 / FAIL: 0`. AC-9 unverified (no restricted-network VM) → T-07. Uncommitted; stream owns delivery. | 2026-07-31 | `docs/features/install-enable-start-split/` (mode: full) |

## Notes

### T-02 consolidation (rule 85)

T-02 deliberately absorbed what were originally three rows — config degradation, mirror/validation,
and download progress — because all three need the same judgment ("is this rule-set file usable?").
Split, degradation would have shipped a bare `path.exists()` and an HTML error page would have read
as "present". Recorded in `02_SOLUTION_DESIGN.md` §12 and verified structurally at stages 3 and 5
(deletion test: removing `srs_reject_reason` forces magic/floor logic back into two live call sites).

### Follow-up rows surfaced by T-02 (not yet filed — owner to number them)

Each was found by a stage agent, judged out of scope by the gate or the PM, and deliberately
**re-homed rather than dropped**:

1. **Python-floor violations — five sites, not two.** `capture_output=` (3.7+) at `bin/sc:822`,
   `:864`, `:1159`, plus `text=True` (3.7+) at `:822`, `:1159`. The documented 3.6+ floor is already
   false today. Either lower the code or raise the floor in both READMEs and `CHANGELOG.md`.
   *(Requirement Q9 counted two; the gate reviewer found the third, the code reviewer the rest.)*
2. **`TRANSLATIONS` has no `en` table**, so `t()` returns the key verbatim in English — `bin/sc:642`
   already prints a literal `ls.idx`. Constrains every future key to readable English prose.
3. **`--mirror` sudo/scheme hardening.** `--mirror` survives the auto-elevate re-exec (argv is
   preserved even though the environment is not) and `urlopen` accepts `file://`. Privilege impact
   negligible; the requirement's security NFR is nonetheless stale. A `http`/`https` allow-list is
   a one-line fix.
4. **D-4** — a local disk fault (ENOSPC, `replace()` EPERM) is reported as a *mirror* failure and
   leaks the internal temp path. A-1 widened this to a second surface: it can now appear on a
   success line as well as a failure line, so a fix must test both.
5. **D-5** — stray blank line before the restart notice in `cmd_update_rules`.
6. **`_temp_path` prefix coupling** — `_clear_stale_temps` builds `fname + ".tmp"` independently, so
   the `".tmp"` literal is written twice and coupled only by convention.

### Carried to T-07

Restricted-network end-to-end verification (never reproduced here — no such VM), the four items QA
left honestly unverified (BC-25, the D-2 escalation, AC-26 on a real 3.6 interpreter, BC-32), and
QA's 846-assertion harness, which T-07 should inherit in preference to the developer's.

## Conventions

- **ID** is sequential: `T-001`, `T-002`, ...
- **Slug** is lowercase-kebab, ≤40 chars (e.g. `csv-export-orders`).
- **Stage** is one of: `req`, `design`, `gate`, `dev`, `review`, `test`, `delivery`, `blocked`, `done`.
- **Doc folder** is the relative path under `docs/features/<slug>/`.

## How tasks relate

When starting a new task, the Requirement Analyst scans this board for related work:

- Same module → read prior `02_SOLUTION_DESIGN.md` first.
- Same feature → build on prior design, don't redesign.
- Conflicting decisions → flag for user.
