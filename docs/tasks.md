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
| T-05 | sc-doctor | **DELIVERED** — `sc doctor` prints the seven facts a broken install is diagnosed from in **causal** order, so the owner's post-mortem chain (four `.srs` timed out → rules dir empty → config references missing rule-sets → `sing-box check` FATAL → service dead → no autostart) reads off one screen instead of costing three hand-typed `grep`s and two `systemctl`s. Order is pinned in one place (`DOCTOR_SECTIONS`, its sole reader is `cmd_doctor`) and deliberately puts rule-sets **above** the config check, reversing the owner's listing because rule-set state is causally upstream of the check that fails because of it. **Read-only was made process-wide, not `doctor`-local** — the sharpest finding of the task: `main()` called `_init_files()`/`_resolve_clash_port()` *before* dispatch, so `sc doctor` on a wrecked host would have **created the very directory whose emptiness is the diagnosis** and persisted an invented Clash port; the init block now sits below `parse_args()` behind an `if/else` whose default arm is today's behaviour verbatim, so a forgotten opt-out can only ever produce "a new read-only command wrote files", never "an existing command lost its init". **Reuse held under rule 85**: rule-set health comes through `ruleset_states()` (and `ruleset_report()` *is* `_status_view(ruleset_states())`, so `doctor` and config generation stand on the same call); size comes from the byte counter inside the one existing reader, `st_size` appears nowhere on the graph; `sc status` byte-identical in both languages. Exit codes 0/1/2 (all-OK / any PROBLEM / any UNKNOWN) — two-value was rejected because folding UNKNOWN either way lies on real hosts. **2 rollbacks, both to the developer, neither reaching the design**; six alleged design drifts were audited and ruled on rather than bounced upstream, and one proved not to be a drift at all. QA **rebuilt** rather than inherited: 721 assertions / 0 failures, non-vacuity proven (the AC-16 oracle was quoted from `02_` §3.6, not from the developer's code, so it cannot agree by construction). Two real defects caught by QA on the **real** binary that fixtures had hidden: DEF-1 (sing-box colours into a pipe, so ESC-byte stripping left `[31mFATAL[0m` on the one row the whole requirement leans on) — **fixed**; DEF-2 (a hung Clash port loses S6's port row) — shipping open, gate-predicted as F-12 and ruled acceptable before code was written. `verify_all PASS: 17 / WARN: 0 / FAIL: 0 / SKIP: 1` measured after archive — **zero delta against a pristine `HEAD` clone**. Two WARNs were traversed to get there: F.6 doc-size (predicted and gate-ruled at C-8, cleared on archive) and then F.4 (**not** predicted — `archive-task.sh` harvested 3 insights but did not auto-rotate the overflow, leaving the index at 32/30; the PM hand-rotated two entries into `docs/features/_archived/insight-history.md`, choosing them by rule 70's "what no longer earns its line" rather than oldest-first). **`archive-task.sh`'s rotation is broken and will bite every future task that harvests at the cap** — the second archive-script defect on record. Live service provably untouched at every checkpoint (`MainPID` + `ActiveEnterTimestamp`, never `is-active`); the mid-task restart was the owner working by hand in another terminal, `NRestarts=0`. Product diff 5 files, +573/−43. **Unverified and owed: one run of the installed binary as root** (this host's NOPASSWD `sc` is an older build without `doctor`). Uncommitted; owner owns delivery. | 2026-08-01 | `docs/features/_archived/sc-doctor/` (mode: full) |
| T-11 | install-version-query-abort | **DELIVERED** — `install.sh`'s version query no longer kills the installer at the assignment. `SB_VER=$(curl … \| grep … \| head -1 \| sed …)` under `set -euo pipefail` carried the pipeline's status, so a failed fetch aborted at `:373`, bypassing both its own `download_failed`/`check_network` handler **and** `install_report()` — the exact "states no outcome" failure T-01 exists to prevent, on an everyday path (GitHub rate-limits unauthenticated calls at 60/hour/IP). Now `SB_VER=""` + `if ! SB_VER=$(…)`, with `head -1` replaced by `sed -n '1s…p'`. All **five** failure modes converge on the existing validator, which is now the *only* judge; the pipeline's status never decides. The sharpest mode was invisible before: HTTP 200 with no `tag_name` (captive portal) — curl exits 0 so `-S` prints nothing, `grep` exits 1 silently, and the installer died **producing no output at all**. **Reporting route decided, not defaulted**: explicit early exit, NOT `install_report()`, because routing there would print six statements false at step 2 (all six verified against source) — so **AC-11 holds with no exception**, the phase machinery byte-identical by range diff. Dropping `head -1` is **load-bearing for large or hostile bodies, precautionary for the real ~1.6 KB endpoint** (an early-closing reader + `pipefail` would report a *successful* fetch as failed). Also ships `check-i18n-parity.sh` as `verify_all` **B.2**, turning a permanently-SKIP step into a real gate and closing a hazard deferred four tasks running. **0 rollbacks**; three upstream defects discharged by ruling or re-homed row, none reaching product code. Premise established empirically by PM pre-flight (E-0 7/7) because stages 1-3 have no shell. QA **rebuilt** the harness rather than re-running the developer's: 102 assertions / 0 failures / 145 runs / 0 flakes, non-vacuity proven by making the success test fail on demand. `verify_all PASS: 16 / WARN: 1 / FAIL: 0 / SKIP: 1`, clone delta exactly the two predicted steps. `install.sh` never executed; live service identical at **four** checkpoints (`MainPID` + `ActiveEnterTimestamp`). Product diff `install.sh` **+18/−4**. Uncommitted; owner owns delivery. | 2026-08-01 | `docs/features/_archived/install-version-query-abort/` (mode: full) |
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
   the project had no committed test suite. **Partly resolved by T-11**, which made B.2 a real check;
   B.3 (lint) is still SKIP and `baseline.json` still reads zero — see R-4. Every task before T-11
   built a throwaway harness and discarded it.

### Open rows surfaced by T-11 (R-1 … R-8) — owner to number

Each was found by a T-11 stage agent, judged out of scope by the requirement or the design, and
deliberately **re-homed rather than dropped**. HEAD anchors are pre-T-11 line numbers.

1. **R-1 — unguarded `mktemp -d` assignments.** `ARTIFACT_DIR="$(mktemp -d -t …)"` (`install.sh:332`)
   and `SB_TMPDIR="$(mktemp -d)"` (`:371`) abort the run by exactly T-11's mechanism, leaving only
   `mktemp`'s raw English line. Re-homed (D-3/O-8) because no handler below them is made unreachable
   and the failure domain is the local temp filesystem, not the network.
2. **R-2 — empty version display.** `t step2_already "$(sing-box version | head -1)"` (`:368`) and
   `t step2_done "$(…)"` (`:392`) discard the substitution's status, so a `sing-box` that exits
   non-zero prints `▶ [2/7] sing-box already installed: ` with an empty version and the run
   continues. A display defect, not an abort.
3. **R-3 — the wider silent-abort class.** Bare `python3` heredoc (`:403-417`), `tar -xz` (`:390`),
   `install -m` (`:391`/`:398`/`:399`/`:428-430`), `chmod` (`:454`/`:462`), `visudo -c` (`:463`) all
   abort `install.sh` with no stated outcome. **T-01's "the installer always states its outcome"
   guarantee is not global, and T-11 does not make it so** (D-7). This row is the one that would.
4. **R-4 — `.harness/scripts/baseline.json` still reads `test_count: 0`.** T-11 made `verify_all`
   B.2 a real check (`check-i18n-parity.sh`, 41 keys × 2 languages), so the file can finally be
   populated instead of recording zero across six delivered tasks.
5. **R-5 — the `fail_download()` helper.** Three sites now share
   `t download_failed … ; t check_network ; exit 1` (`:346-348`, `:385-387`, and T-11's new block).
   The seam is real; T-11 declined it (`02_SOLUTION_DESIGN.md` §3.5, recorded in
   `.harness/rejected-decisions.md` as `installer-early-exit-download-helper`) because it would pull
   two untouched blocks into the diff and weaken the line-by-line audits AC-9 and B-5 rest on.
   Natural owner is R-3, which rewrites this failure class anyway.
6. **R-6 — the PowerShell mirror diverges.** T-11 wired B.2 in `.harness/scripts/verify_all.sh` only;
   `.harness/scripts/verify_all.ps1:79` still reads `Step "B.2" "Tests pass"` with a SKIP body, so
   the two mirrors now disagree about what B.2 is. Out of T-11's permitted diff by AC-12/A-4;
   recorded here so the divergence is not silent.
7. **R-7 — the new B.2 gate has two blind spots, and it is now permanent.** Confirmed with tool
   evidence at stage 6: mutating `install.sh:143`'s `LANG_CHOICE` dispatch makes
   `check-i18n-parity.sh` render the **en** table twice, agree on every comparison, print
   `OK: 41 keys, both languages` — a literally false statement — and **exit 0**, with zh unreachable.
   It also cannot see a key missing from *both* tables, though that aborts the installer under
   `set -u`. The product is clean today; the gate is not. Cheapest fix: assert at least one key
   renders differently between the two languages. Owner: solution-architect (design blind spot).
8. **R-8 — three T-11 document defects, none reaching product code.** (a) `02_SOLUTION_DESIGN.md`
   §10's E-10 fixture is defective: `yes … | head -200000` is itself an early-exiting reader *inside*
   the measured pipeline, so under `pipefail` both legs return 141 regardless of the extraction tail
   — the probe could never distinguish its own legs. (b) §4's "+11 line shift" is actually +14.
   (c) `04_DEVELOPMENT.md`'s "load-bearing, not precautionary" overstates the evidence; the accurate
   reading is *load-bearing for large or hostile bodies, precautionary for the real endpoint*.
   (d) `.harness/rules/50-singbox-cli.md:45` still opens "until B.2/B.3 are real", now false for B.2
   — C-11 correctly forbade touching it, so it belongs to the next rule-50 edit.

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
