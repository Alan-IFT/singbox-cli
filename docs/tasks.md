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
| T-08 | install-binary-download-progress | **DELIVERED** — the sing-box tarball (tens of MB, the largest transfer in the install) now shows curl's own `--progress-bar`, so the owner's 「不知道什么时候能完成」 is answered where it actually hurt. Shipping diff is **2 files, +27/−3**: a download flag policy block at `install.sh:116-132` (`CURL_OPTS_QUIET=(-f -s -S -L)`, literally today's `-fsSL`, and `CURL_OPTS_PROGRESS` = the same off a terminal, `(-f -S -L --progress-bar)` on one) selected by the file's **only** `[ -t 2 ]`, consumed at all three curl sites; exactly three lines replaced. **No hand-rolled meter, no helper function, no new file** — rule 85's counter-rule held. TTY gating is on **stderr**, verified three times: curl's meter is a stderr artefact *and* curl does not self-gate on `isatty(stderr)` when `-o <file>` is used, so `[ -t 2 ]` is correctness, not cosmetics (this supersedes `BATCH_PLAN.md:46-47`'s `[ -t 1 ]`, wrong in both directions). Every download was **assessed, and each remaining silence justified in writing** per 「每个下载部分」: five artifact name lines, version query meter-free as a boundary marker. **1 rollback** (stage 2 found a false justification leg in D-5; analyst verified, retracted it, and re-homed the live bug it concealed — the design was not re-dispatched and the gate audited and upheld that call). The curl **7.29** option floor — the claim whose failure kills step 2 on every RHEL/CentOS 7 host, invisibly on a modern box — was settled against the **official 7.29.0 release tarball** by two independent readers; the `curl-7_29_0` git tag is *not* valid evidence (`curlver.h` reads `7.28.2-DEV`). `verify_all PASS: 16 / WARN: 0 / FAIL: 0 / SKIP: 2`, delta 0 vs a pristine-HEAD **clone**. QA 39 scripted assertions + 5 probes, **0 product defects**; BC-3 (stdout TTY + stderr redirected → zero `0x0D`) proven with a real `openpty` driver and falsified on demand at 26. **Six vacuous greens caught rather than shipped**, one of which had already produced a false PASS. Live service provably untouched — identical `MainPID`/`ActiveEnterTimestamp` at three independent checkpoints. Uncommitted; owner owns delivery. | 2026-08-01 | `docs/features/_archived/install-binary-download-progress/` (mode: full) |
| T-10 | ruleset-update-no-needless-restart | **DELIVERED** — `sc update-rules` no longer restarts sing-box unless a rule-set's **bytes on disk** actually changed, so the timer T-09 just made live no longer drops every connection each Monday. `bin/sc:1141-1143`'s unconditional `if not applied and is_running(): restart_service()` is gone; `ruleset_state(path) -> (status, digest)` reads each file **once** and returns both facts, so `gained ⊆ changed` holds and "exactly one apply per run" is **structural** — one `restart_service()` call site outside `reload_or_restart()`, under `if changed and CFG_PATH.exists()`. T-02's 自动恢复 preserved with its inner order verbatim and still ahead of the non-zero exit. **Hot-apply was investigated, not assumed, and declined on evidence**: Clash API has `/providers/rules` but no `ruleCount`/`vehicleType` (compatibility stub); SIGHUP recreates the instance and OpenRC defines no `reload()`; sing-box *does* fswatch local rule-sets but our own `log.level=warn` closes the only channel that could witness it — recorded as a **deferred decline**, not a rejection. **0 rollbacks** (two document-only fixes, neither a defect). `verify_all PASS: 16 / WARN: 0 / FAIL: 0 / SKIP: 2`, delta 0 vs a pristine `HEAD` QA rebuilt itself; QA 522 assertions / 0 failures / 0 product defects, with a negative control (same fixture: HEAD `['is_running','restart_service']` → change `[]`) and 4 killed mutants. Live service provably untouched by identical `MainPID` + `ActiveEnterTimestamp`. Gate's sharpest finding: **`systemctl is-active` cannot detect a restart** — the check written after T-02's incident would have passed *during* it. Product diff 3 files, +147/−31. Uncommitted; owner owns delivery. | 2026-08-01 | `docs/features/_archived/ruleset-update-no-needless-restart/` (mode: full) |
| T-09 | fix-rules-update-execstart | **DELIVERED** — `systemd/sing-box-rules-update.service:7` now runs `/usr/local/bin/sc update-rules` instead of the never-installed `/usr/local/bin/proxy`, so the README-advertised weekly ruleset auto-update can run for the first time on any systemd host. Shipping diff is 2 files: the unit (1 insertion / 1 deletion) + one zh `修复` bullet in `CHANGELOG.md`. **0 rollbacks**; the stage-1 conditional escalation (Q1) did not fire — `daemon-reload` alone is sufficient, verified on mechanism at three stages, so `install.sh` stayed out of the diff and re-running the installer is the whole upgrade. `verify_all PASS: 16 / WARN: 0 / FAIL: 0 / SKIP: 2`, delta 0 against a pristine `HEAD` baseline QA rebuilt itself. `systemd-analyze verify`: pre-change exit 1 naming `/usr/local/bin/proxy`, post-change exit 0. End-to-end ("the timer now really updates") is **reasoned, not executed** — no root, no live mutation. QA found the host contradicts two upstream premises: the unit has **never run** (timer `disabled`, no stamp, journal empty), so the "~100% of hosts are in `failed`" premise is false and the BC-11 stamp claim has zero empirical support project-wide. Uncommitted; owner owns delivery. | 2026-07-31 | `docs/features/fix-rules-update-execstart/` (mode: full) |
| T-02 | config-degrade-missing-rulesets | **DELIVERED** — one rule-set usability judgment (`SRS` magic + 16-byte floor + Content-Length equality) consumed by config generation, the downloader and the progress display. Config now degrades per file, dropping unusable rule_sets *and* their references in both `dns.rules` and `route.rules`, so sing-box starts instead of FATALing. Ordered multi-mirror validated fetch (`--mirror` / `SB_RULES_BASE`), TTY-gated per-file progress, atomic temp-then-replace, and `sc update-rules` now regenerates the config so recovery is real. 2 rollbacks (both design-origin: D-1 cause-discarding → A-1; zh `失败：` grep collision → A-2). `verify_all PASS: 16 / WARN: 0 / FAIL: 0`; QA 846/846. Absorbed the former T-03 and the ruleset-progress row. Uncommitted; owner owns delivery. | 2026-07-31 | `docs/features/config-degrade-missing-rulesets/` (mode: full) |
| T-01 | install-enable-start-split | **DELIVERED** — installer now reports its true outcome (unconditional autostart registration, real cause logged to `/var/log/sing-box/install.log`, honest banner, non-zero exit on failure). Absorbed the former T-04. `verify_all PASS: 16 / WARN: 0 / FAIL: 0`. AC-9 unverified (no restricted-network VM) → T-07. Uncommitted; stream owns delivery. | 2026-07-31 | `docs/features/install-enable-start-split/` (mode: full) |

## Notes

### Open rows surfaced by T-08 — owner to number

1. **Version-query silent abort** (`install.sh:373-381`). Under `set -euo pipefail`,
   `SB_VER=$(curl … | grep … | sed …)` aborts *at the assignment* on HTTP 403/404 or transport
   failure, so the bilingual `download_failed`/`check_network` handler below it never runs **and
   `install_report()` never runs** — the installer can exit having stated no outcome, the exact
   property T-01 exists to guarantee. GitHub's unauthenticated rate limit makes this routine, not
   theoretical. Found at stage 2, verified against the source at stage 1', filed in
   `.harness/rejected-decisions.md`; deliberately not absorbed because it changes failure behaviour
   that T-08's AC-6/AC-14 pin as unchanged.
2. **Committed bilingual key-parity gate — now deferred four tasks running.** `install.sh`'s `t()`
   declares `local fmt` with no default, so a key present in only one language branch aborts the
   whole installer under `set -u`, and the zh branch is reachable only by answering `2`. Parity was
   proven three times independently during T-08 (41 keys, both tables) but the proof is **not
   committed**, so the hazard is exactly as shippable for the next task. The code reviewer calls this
   the highest-leverage open debt touching this file. `rejected-decisions.md:57-73` already says the
   next task "should probably widen its own diff instead"; T-08 could not, because AC-19 pinned the
   shipping diff.
3. **Two test-infrastructure defects inherited by T-07** with the harness: `gate_checks.sh` writes
   `faults.json` while `server.py` reads `control.json` (re-run as shipped it yields a false FAIL),
   and AC-3's non-vacuity is carried by the server **throttle**, not the fixture size, with no guard.
4. **`docs/dev-map.md` seam row** for `CURL_OPTS_QUIET`/`CURL_OPTS_PROGRESS` — belongs to T-07, which
   owns the next edit to these flags. Deliberately not added by T-08: dev-map is not in AC-19's
   carve-out, so editing it would have breached the criterion the gate made binding.
5. **`.harness/scripts/baseline.json` still reads `test_count: 0`** across all five delivered tasks —
   the project has no committed test suite (`verify_all` B.2/B.3 are permanently SKIP). Every task so
   far has built a throwaway harness and discarded it. A standing gap, not any one task's.

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
