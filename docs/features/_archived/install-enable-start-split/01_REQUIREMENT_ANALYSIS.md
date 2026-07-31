# 01 — Requirement Analysis — install-enable-start-split (T-01)

- **Task ID**: T-01
- **Mode**: full
- **Date**: 2026-07-31 (rev. 2 — scope expanded by the project owner mid-pipeline)
- **Dispatch context**: deferred-human mode (defer, do not ask)
- **Verdict**: `READY` (6 deferred decisions recorded with stated proceeding assumptions — see §8)

---

## 0. Revision history

| Rev | What changed | Why |
|---|---|---|
| 1 | Original: split `enable` from `start`, introduce `INSTALL_OK`, defer all messaging/exit-status work to T-04. | Initial decomposition mirrored the failure report's patch list. |
| **2 (this document)** | **T-04 absorbed into T-01.** One coherent behavior: *the installer reports its true outcome*. Adds error surfacing to a log file, an honest closing banner, a derived non-zero exit on failure, and first-class bilingual scope. | Owner directive **「优先用好的设计，避免不断的修修补补」**. Shipping "compute `INSTALL_OK`" now and "act on it" later is the patch-then-patch pattern being rejected, and the intermediate tree is **incoherent on its own**: step 7 computes the failure and the closing banner still prints `✅ 安装完成` unconditionally, i.e. the installer still lies on the failure path — the exact defect originally reported. Recorded in `docs/batches/default/BATCH_PLAN.md:14,22-27`. |

**What rev. 2 changes, item by item** (each is called out again where it lands):

- §1 Goal — rewritten around outcome reporting, not variable plumbing.
- §3 — **B-10 and B-11 are SUPERSEDED** (they said "no new strings" and "exit status unchanged"). B-4,
  B-6, B-7 are **revised**; B-12 … B-19 are **new**. B-1, B-2, B-3, B-5, B-8, B-9 are **unchanged** and
  are already implemented and code-reviewed (`05_CODE_REVIEW.md`, `APPROVED`).
- §4 — out-of-scope items 1 and 8 (banner, messaging) are **removed**; they are now in scope. All
  other exclusions stand.
- §6 — AC-11 and AC-12 are **superseded**; AC-13 … AC-20 are **new**.
- §8 — **Q2's resolution is REVERSED**: `2>&1` suppression at the source is no longer acceptable. This
  is also the resolution of gate finding **F-4**.
- Gate finding **F-3** (failure path regressed exit 1 → 0) is now **fixed by design**, not accepted.
- Code-review findings **STD-3** (one-language `t()` key aborts the installer under `set -u`) and
  **SPEC-1** (timer enabled but not started on the failure path) are folded in as binding requirements.

---

## 1. Goal

`install.sh` reports its true outcome: boot autostart is registered unconditionally, the real cause of a
step-6/step-7 failure is preserved in `/var/log/sing-box/install.log` instead of being discarded, and the
closing banner plus the process exit status are both derived from one recorded set of phase outcomes, so
the installer never prints "安装完成 / Install complete" for a run that did not install a working service.

---

## 2. Background and evidence

Reproduced failure (project owner, Ubuntu, mainland-China network — TLS handshake to GitHub succeeds,
large transfers time out; sing-box 1.13.14 pre-installed):

1. The ruleset step exhausted its timeout for all four `.srs` files, leaving `/etc/sing-box/rules/` empty.
   It is guarded and only prints a warning (`install.sh:355-361`).
2. The next step ran `sc reload`, which regenerates `config.json` still referencing the four local
   rule-set paths (`bin/sc:530-539`), then runs `sing-box check` (`bin/sc:552-556`). The check returned
   `FATAL: parse rule-set[0]: open …/geoip-cn.srs: no such file`, so `generate_config()` returned `False`
   and `cmd_reload` exited non-zero via `sys.exit(t("Reload failed"))` (`bin/sc:928-932`).
3. That call was unguarded under `set -euo pipefail` (`install.sh:9`), so the installer aborted before
   registering autostart and before the closing banner.

### 2.1 What is already built and reviewed (keep unless the redesign improves it)

`install.sh:363-386` now implements phase 7a (unconditional `systemctl enable` / `rc-update add`, each
`|| true`) and phase 7b (`sc reload` as an `if` condition, launch only on success, `INSTALL_OK` 0/1).
It passed gate (`03_GATE_REVIEW.md`, `APPROVED WITH CONDITIONS`) and code review (`05_CODE_REVIEW.md`,
`APPROVED`, 0 CRITICAL / 0 MAJOR). Rev. 2 keeps that behavior and builds the reporting layer on it.

### 2.2 New evidence gathered for rev. 2 — the "surface stderr" instruction is not sufficient as worded

Verified in the current tree:

- **`sc update-rules` emits the real cause on _stdout_, not stderr.** The per-file reason is printed by
  `print(t("failed: {e}", e=e))` at `bin/sc:817` — this is the `urlopen error timed out` text the owner
  wants preserved. Only the aggregate `"{n} ruleset(s) failed to update"` goes to stderr, via
  `sys.exit(...)` at `bin/sc:821`. Capturing **stderr only** from step 6 would log the count and lose the
  cause, i.e. reproduce the defect in a new place. See B-12 and deferred item Q2.
- **`sc reload` emits its cause on stderr.** `generate_config()` writes `⚠️ Config check failed:\n<check
  stderr>` to `sys.stderr` (`bin/sc:555`) and `cmd_reload` exits with the message on stderr
  (`bin/sc:932`). Stderr capture is sufficient there.
- **The log directory already exists before step 6.** `install.sh:287` runs
  `mkdir -p /etc/sing-box/rules /var/lib/sing-box /var/log/sing-box "$LIB_DIR"`, which is ordered before
  the ruleset step. No new directory-creation requirement is needed, only an ordering constraint (BC-16).
- **Uninstall already removes the log directory** (`uninstall.sh:137` `rm -rf /var/log/sing-box/`), so
  `install.log` leaves no residue.
- **`t()` aborts on a one-language key.** `t()` declares `local fmt` with no default and assigns it only
  inside the active language's `case` (`install.sh:109-111,177-182`); under `set -u` a key missing from
  the active branch makes `printf "%s\n" "$fmt"` fail with `fmt: unbound variable` and terminate the
  installer. The zh branch is only reached when the user answers `2` at the language prompt
  (`install.sh:195-199`), so an English-only test run cannot detect it (code review **STD-3**).
- **On the failure path the rules-update timer is `enable`d but never `start`ed**, so it is not armed
  until the next boot and cannot self-heal the missing rulesets in this session (code review **SPEC-1**).
- **Exit status today**: after the rev.-1 change every path exits `0`, including the failure path, which
  used to exit `1` (gate **F-3**). Rev. 2 makes non-zero-on-failure deliberate rather than accidental.
- **`CLEANUP_DIRS` expansion hazard**: `for d in "${CLEANUP_DIRS[@]}"` (`install.sh:215-216`) over an
  empty array raises `unbound variable` under `set -u` on bash < 4.4, reachable on CentOS/RHEL 7 (which
  the installer supports via `yum`). Harmless while every path exited 0; load-bearing now that the exit
  status is a contract (gate **F-5**, folded in as B-18).

---

## 3. In-scope behaviors

Behavioral statements only; none prescribes a file location or an implementation mechanism.

### 3.1 Unchanged from rev. 1 (already implemented and reviewed)

**B-1 — Unconditional systemd autostart registration.** On a systemd host the installer registers the
`sing-box` service for boot autostart during the autostart-and-start step, before invoking config
generation, and independently of whether config generation later succeeds.

**B-2 — Unconditional systemd timer registration.** Same, for `sing-box-rules-update.timer`.

**B-3 — Registration failure is non-fatal.** A non-zero exit from either registration command does not
terminate the installer; execution continues.

**B-5 — Config generation cannot abort the installer.** The config-generation invocation is evaluated as
a condition, so a non-zero exit selects the failure path instead of terminating the script under `set -e`.

**B-8 — Idempotency preserved.** Re-running the installer on a host where the units are already enabled
and running completes and leaves `/etc/sing-box/nodes.json` and `/etc/sing-box/settings.json` untouched.

**B-9 — Ordering is observable.** Registration executes before config generation; launch executes after
it. Ordering is assertable from a recorded command trace.

### 3.2 Revised in rev. 2

**B-4 (revised) — One phase-status model.** The installer records the outcome of three phases in
top-level shell state that survives to the final line of the script and is readable under `set -u` on
every path that reaches the closing block:

| Phase | Values | Set from |
|---|---|---|
| rulesets | `ok` \| `failed` | exit status of the ruleset-download step |
| config | `ok` \| `failed` | exit status of the config-generation invocation |
| service | `started` \| `not-started` | exit status of the service-launch command; `not-started` whenever launch is skipped |

The banner (B-15) and the exit status (B-11) are both derived from this state and from nothing else — no
second, ad-hoc condition re-derives "did it work". Two legal values per phase; no third state.
The existing `INSTALL_OK` variable is an acceptable carrier for the *config* phase if stage 2 judges its
granularity already correct; the requirement is the single source of truth, not the identifier.

**B-6 (revised) — Service launch is conditional, guarded, and recorded.** Launching `sing-box` (and, on
systemd, the rules-update timer) occurs only when config generation succeeded; a non-zero exit from a
launch command does not terminate the installer and sets the service phase to `not-started`.

**B-7 (revised) — OpenRC parity.** On an OpenRC host the installer adds `sing-box` to the default
runlevel unconditionally and guarded, starts it only on the config-`ok` path, guarded, records the same
three phases with the same semantics, and uses OpenRC-appropriate wording in the remediation list
(B-16). The OpenRC branch gains no rules-update registration and loses no existing behavior.

**B-10 (SUPERSEDES rev.-1 B-10 "no new user-facing strings") — Bilingual parity is mandatory.** Every
user-facing string added by this task exists in **both** the `zh` and the `en` branch of the installer's
`t()` table, and the two branches carry an identical key set (same names, same count). A key present in
only one branch is a release blocker, not a cosmetic miss: it aborts the installer under `set -u` for
users of that language (§2.2, code review STD-3).

**B-11 (SUPERSEDES rev.-1 B-11 "exit status unchanged") — Exit status is derived, and non-zero on
failure.** The installer's process exit status is `0` when config is `ok` **and** service is `started`,
and a single fixed non-zero value otherwise. It is computed from the B-4 state, not from the incidental
status of the last command. This deliberately reverses rev.-1 B-11 and resolves gate finding **F-3** in
the correcting direction: `main` exits `1` on the reported failure today, the rev.-1 tree exits `0`, and
rev. 2 restores a machine-detectable failure signal by design.

### 3.3 New in rev. 2

**B-12 — The real cause is preserved in `/var/log/sing-box/install.log`.** For every step-6 and step-7
command whose diagnostics are currently discarded, the diagnostic output that carries the *cause* of a
failure is appended to `/var/log/sing-box/install.log` instead of `/dev/null`. Because `sc update-rules`
prints the per-file cause on stdout and only the aggregate on stderr (§2.2, `bin/sc:817,821`), preserving
the cause for the ruleset step requires capturing both streams; for `sc reload` stderr alone carries the
cause. The binding requirement is *the cause reaches the log*, not *which stream is redirected*.

**B-13 — Nothing in steps 6 and 7 is silently discarded, and the terminal stays quiet.** No command in
those steps writes its diagnostics to `/dev/null` where the log is the alternative. Terminal output on
the success path is unchanged from today (no new lines, no leaked subprocess chatter).

**B-14 — The ruleset warning names the log path.** The step-6 failure warning states that the detailed
cause was written to `/var/log/sing-box/install.log`, in place of the current speculative wording
("可能是网络问题" / "likely a network issue"), and keeps its existing `sc update-rules` retry hint. Both
language branches.

**B-15 — Honest closing output.**
- On success (config `ok` **and** service `started`) the closing block is unchanged from today: the same
  banner, the same next-steps list, the same closing note.
- On failure the success banner and the success-only next-steps list do **not** print. Instead the
  installer prints, in the active language: (i) an explicit statement that installation did not complete
  and which phase failed, (ii) the remediation command list of B-16, and (iii) the literal path
  `/var/log/sing-box/install.log` as the place the real error was recorded.
- The failure output does not dump the log's contents; it names the path.
- A run in which rulesets are `failed` but config is `ok` and service is `started` counts as **success**
  for banner and exit-status purposes, because the installed service is functional; the ruleset
  degradation is already reported by B-14 at step 6.

**B-16 — Remediation list content.** The failure output lists, as literal commands the user can copy:
`sc update-rules`, `sc reload`, and a service-status command matching the detected init system
(`systemctl status sing-box` on systemd, `rc-service sing-box status` on OpenRC). The ordering and
wording make clear the user must run the repair themselves — the enabled-but-unstarted rules-update timer
does **not** re-download the rulesets in this session (§2.2, code review SPEC-1). No text may state or
imply that the system will self-heal before the next boot.

**B-17 — Logging never breaks the install.** If the log file or its directory cannot be written (missing,
read-only, out of space), the installer still completes its remaining steps, still prints the correct
banner per B-15, and still exits with the B-11 status. A logging failure is not itself an install
failure and does not change the phase status of any phase.

**B-18 — The derived exit status is the process exit status.** Nothing between the closing block and
process termination alters it — in particular the existing `EXIT` cleanup handler must not turn a derived
`0` into a non-zero status on any supported bash version, including bash 4.2 as shipped by the `yum`-era
distros the installer supports (§2.2, gate **F-5**).

**B-19 — The log is not world-readable.** `install.log` is created owned by root with a mode that
excludes other users (`0640` or stricter), because captured `sing-box check` output can echo fragments of
the generated configuration.

---

## 4. Out of scope

1. **`bin/sc` config degradation for missing rulesets** — T-02. `bin/sc` is not modified by this task.
2. **Ruleset download behavior** — mirrors, validation, atomic replace, retry policy: T-02. Step 6's
   *error surfacing* is in scope; its *download behavior* is not.
3. **Timeout values.** No timeout constant changes. The owner ruled enlargement out: `bin/sc:583` (3),
   `bin/sc:742` (8), `bin/sc:812` (30) are correct as-is; the failure was true unreachability.
4. **Step 4 service-unit installation, step 5 sudoers, and the sing-box binary install/version logic** —
   untouched.
5. **An OpenRC rules-update schedule** — none exists today; none is invented here.
6. **Restricted-network end-to-end regression harness** — T-07 (see AC-9).
7. **`sc doctor`** — T-05. This task records phase status for its own banner only; it defines no
   persisted health model and writes no state file for another command to read.
8. **Log rotation / retention for `install.log`** — the file is append-only across runs and is removed
   wholesale by `uninstall.sh`.
9. **`systemd/sing-box-rules-update.service`'s stale `ExecStart=/usr/local/bin/proxy`** (gate R2) —
   pre-existing, backlog.

Removed from rev. 1's out-of-scope list (now **in** scope): the closing banner and failure messaging, the
`install.log` capture, and the exit-status change.

---

## 5. Boundary conditions

| # | Condition | Required behavior |
|---|---|---|
| BC-1 | Config generation exits `0`, launch exits `0` | Units launched; config `ok`, service `started`; success banner; exit `0`. |
| BC-2 | Config generation exits non-zero | No launch command runs; config `failed`, service `not-started`; installer continues to the closing block; failure banner; exit non-zero. |
| BC-3 | Config-generation command missing / not executable (exit 127) | Identical to BC-2; does not terminate the installer; the "not found" diagnostic reaches the log. |
| BC-4 | A registration command exits non-zero (masked unit, no systemd bus, unknown unit) | Installer continues; the remaining registration and the config-generation attempt still run; registration failure alone does not make the run a failure. |
| BC-5 | Launch exits non-zero although config generation succeeded | Installer continues; service is `not-started`; failure banner; exit non-zero. |
| BC-6 | Host is OpenRC (no `systemctl` on `PATH`) | B-7 applies; no `systemctl` invocation, no rules-update unit referenced, OpenRC status command in the remediation list. |
| BC-7 | Host has neither systemd nor OpenRC | Unreachable — pre-flight already exits (`install.sh:50-54`). No new handling. |
| BC-8 | Re-run on a host where both units are already enabled and active | Registration is a no-op returning success; run completes; user data files unchanged; `install.log` gains a new appended run, existing content preserved. |
| BC-9 | `set -e` and the status assignments | Every status assignment yields exit status `0`. Forms that can yield status `1` (arithmetic increment on a zero value, `let`) are not used. |
| BC-10 | `set -e` and the guarded invocations | Failure-prone commands sit in condition position or are explicitly guarded, so a non-zero exit selects a path rather than terminating the shell. |
| BC-11 | `set -u` and the status variables | Every status variable is assigned before any read, on every path that reaches the closing block. |
| BC-12 | Subshell scope | Status assignments execute in the script's top-level shell — not inside `( … )`, a pipeline segment, or a command substitution — so the closing block sees them. |
| BC-13 | `set -o pipefail` | If a pipeline is introduced to capture output, the recorded phase status is that of the *command*, not of a downstream writer; a failing log writer does not mark a successful phase as failed (see B-17). |
| BC-14 | Empty `/etc/sing-box/rules/` (the reported real case) | rulesets `failed` → warning naming the log path; config `failed`; service `not-started`; both units still registered for boot; failure banner with remediation; exit non-zero; `install.log` contains the `urlopen error timed out` cause text. |
| BC-15 | Rulesets `failed` but config `ok` and service `started` | Success banner, exit `0`, plus the step-6 warning already printed. Not a failure (B-15). |
| BC-16 | Log write attempted before the log directory exists | Cannot occur: the first write is in step 6, and the directory is created in the earlier install step (`install.sh:287`). If a future reordering breaks this, B-17 governs. |
| BC-17 | Log path is unwritable (read-only FS, full disk, path is a directory) | B-17: install continues, banner and exit status still correct, no abort under `set -e`. |
| BC-18 | Log already exists from a previous run | Appended to, not truncated; a new run is distinguishable from previous ones in the file. |
| BC-19 | `install.log` contains no user-facing translated text requirement | Log content is verbatim diagnostic output plus a run marker; it is diagnostic, not UI, and is exempt from the bilingual rule. The *reference to the path* on screen is bilingual. |
| BC-20 | A `t()` key exists in only one language branch | Prohibited by B-10 and blocked by AC-16/AC-17 before merge; under `set -u` it would abort the installer for that language, not print an empty line. |
| BC-21 | Empty `CLEANUP_DIRS` on bash < 4.4 at exit | B-18: the cleanup handler does not change the derived exit status. |
| BC-22 | Non-interactive `curl \| bash` run where the language prompt reads no input | Existing default-language behavior is unchanged; the failure path still renders in the defaulted language with no unbound-variable error. |

---

## 6. Acceptance criteria

**Verification constraint (unchanged from rev. 1, restated because it still binds):** no network-restricted
VM and no systemd-capable test host exists in this environment. Criteria are checkable by (i) static
reading of the diff, (ii) syntax gates, and (iii) a shell-level harness that puts stub `systemctl`,
`rc-service`, `rc-update` and `sc` executables on `PATH`, records every invocation to a log file, and
controls each stub's exit status and emitted stdout/stderr. Any criterion that requires a real restricted
host is reported **deferred / unverified** — claiming it as executed is a defect.

| # | Criterion | How it is checked |
|---|---|---|
| AC-1 | `bash -n install.sh` parses cleanly. | Direct command; also `verify_all` gate B.1. |
| AC-2 | `bash .harness/scripts/verify_all.sh` ends with `FAIL: 0`. | Direct command. |
| AC-3 | **(a)** With a stubbed `sc reload` exiting non-zero, the recorded call log contains `enable sing-box` and `enable sing-box-rules-update.timer` and contains no `start` invocation for either unit. | Stub harness. |
| AC-4 | **(b)** In the same scenario the script reaches its final closing line — a failing `sc reload` does not abort it mid-way. | Stub harness; assert on output tail. |
| AC-5 | **(e)** With a stubbed `sc reload` exiting `0`, the call log contains both `enable` invocations and both `start` invocations, every `enable` recorded before the `sc reload` invocation and every `start` after it, and the on-screen output is byte-identical to the pre-change success output. | Stub harness; log ordering + output comparison against `main`'s success run. |
| AC-6 | The phase-status state has the expected values at the closing block in each scenario, and reading it under `set -u` raises no unbound-variable error. | Stub harness (harness-injected read at end of the extracted region). |
| AC-7 | In the OpenRC scenario (no `systemctl` on `PATH`; stub `rc-service`/`rc-update`), `rc-update add sing-box default` is recorded on both paths, `rc-service sing-box start` only on the config-`ok` path, and no invocation naming `sing-box-rules-update` appears. | Stub harness. |
| AC-8 | Running each scenario twice back-to-back produces the same end state and exit status both times, and the second run's `install.log` still contains the first run's lines. | Stub harness (idempotency proxy for B-8/BC-18). |
| AC-9 | On a host that cannot reach GitHub, the one-liner install leaves `systemctl is-enabled sing-box sing-box-rules-update.timer` reporting `enabled` for both units, prints the failure banner, and exits non-zero. | **Not executable here.** Deferred manual verification; T-07 makes it executable. Stages 04-07 report it as unverified. |
| AC-10 | The diff is confined to `install.sh` plus one `CHANGELOG.md` entry; `bin/sc`, `uninstall.sh`, `systemd/*` and every timeout constant are byte-identical to `main`. | `git diff` review. |
| AC-11 | ~~superseded~~ — rev. 1's "adds no user-facing string". Replaced by AC-16/AC-17. | — |
| AC-12 | ~~superseded~~ — rev. 1's "exit status unchanged from `main`", which was factually wrong for the failure path (gate F-3). Replaced by AC-13/AC-14. | — |
| AC-13 | **(c)** In the failure scenario the output contains the failure explanation, all three remediation commands of B-16, and the literal string `/var/log/sing-box/install.log`, and does **not** contain the success banner text (`安装完成` / `Install complete`). | Stub harness; assert presence and absence. |
| AC-14 | **(d)** The failure scenario exits non-zero; the success scenario exits `0`. | Stub harness; assert `$?` in both. |
| AC-15 | With a stub `sc update-rules` that exits non-zero after printing a distinctive cause string on **stdout** and an aggregate on **stderr**, `/var/log/sing-box/install.log` contains the stdout cause string after the run, and the terminal output does not contain it. | Stub harness; assert on file content and on captured terminal output. |
| AC-16 | **(f)** Every scenario runs twice, once with the language answer `1` (en) and once with `2` (zh); every assertion holds in both, no run emits `unbound variable`, and each new message renders as non-empty text in both languages. | Stub harness, two language passes. |
| AC-17 | The `zh` and `en` `case` branches of `t()` contain the identical set of keys (same names, same count). | Static extraction and comparison of the two key lists. |
| AC-18 | The step-6 warning text names `/var/log/sing-box/install.log` in both languages and no longer asserts a speculative cause. | Stub harness output assertion + diff review. |
| AC-19 | With the log path made unwritable, the run still completes, prints the correct banner, and exits with the same status as the equivalent writable-log scenario. | Stub harness (point the log path at a read-only location). |
| AC-20 | `install.log` is created with a mode that grants no access to `other`. | Stub harness `stat` assertion (harness-relative path). |

---

## 7. Non-functional requirements

- **Compatibility**: `install.sh` stays a single self-contained file served over `curl | bash` from raw
  `main`. No new external command beyond what the script already uses, no new dependency, no new network
  call, no new committed file required by the runtime path.
- **Portability**: identical behavior across the supported package managers and both init systems; no
  systemd-only construct leaks into the OpenRC branch or vice versa; nothing newer than bash 4.2 syntax.
- **Security**: no change to the privilege model, the sudoers scope, or existing file modes. The one new
  file (`install.log`) is root-owned and not world-readable (B-19).
- **Performance**: not material. No new network call and no loop is added.
- **Observability**: `/var/log/sing-box/install.log` is the durable artifact of a failed install; the
  banner is its on-screen index. The exit status is the machine-readable signal for wrappers around the
  one-liner.
- **Do not over-build**: no new file format, no config schema, no framework, no state persisted for other
  commands. The phase-status model is plain shell variables in one script.

---

## 8. Deferred decisions (deferred-human mode — recorded, not asked)

Each carries a proceeding assumption; none makes the requirement unspecifiable, so the verdict is not
`BLOCKED`.

**Q1 — CHANGELOG entry shape.** (a) One combined bullet covering the whole "installer reports its true
outcome" fix. (b) Several bullets, one per behavior.
**Recommended: (a).** The task is now one coherent change; one bullet under `## [Unreleased]` → `### 修复`
in the file's existing Chinese-only style. `CHANGELOG.md` being Chinese-only is the repo convention and
is not a bilingual-output violation — that rule governs runtime strings.
**Proceeding assumption**: (a). The rev.-1 bullet already on `main` is superseded or amended in place
rather than duplicated; AC-10 permits the CHANGELOG edit.

**Q2 (REVERSES rev.-1 Q2 (a)) — Which streams are captured.** Rev. 1 resolved "suppress both streams at
the source" (`>/dev/null 2>&1`). Rev. 2 rejects that: it is exactly gate finding **F-4** — suppression at
the source starves the very log the failure path needs. The owner's rev.-2 instruction says "stderr must
go to the log"; §2.2 shows that for `sc update-rules` the cause is on **stdout** (`bin/sc:817`), so
stderr-only capture would still lose it. (a) Capture whichever streams carry the cause per command
(stdout+stderr for the ruleset step, stderr for config generation), keeping the terminal quiet.
(b) Capture stderr only, literally as instructed, and accept losing the ruleset cause.
**Recommended: (a)** — it satisfies the instruction's intent ("the user must be able to see
`urlopen error timed out`") where the literal wording would not.
**Proceeding assumption**: (a). B-12 and AC-15 are written to (a).

**Q3 — Does a ruleset failure alone make the install a failure?** (a) No: if config generation succeeds
and the service starts, the install is a success with a degradation warning. (b) Yes: any failed phase
means a non-zero exit.
**Recommended: (a).** Before T-02, missing rulesets always cascade into a config failure, so (a) and (b)
agree today; after T-02 they diverge, and (a) is correct — a running proxy with degraded rules is a
working install, and exiting non-zero would train users to ignore the signal.
**Proceeding assumption**: (a). B-15 and BC-15 are written to (a).

**Q4 — Should `t()` get a default for `fmt` (turning a missing key into an empty line instead of an
abort)?** (a) No: keep the loud failure and prevent one-language keys with the static parity check
(AC-17) plus both-language runs (AC-16). (b) Yes: add `local fmt=""` as a safety net.
**Recommended: (a).** An empty line in a closing banner is a silent lie — the class of defect this task
exists to remove — whereas the parity check makes the abort unshippable. Also, (b) would edit `t()`
itself, widening the diff for a hazard the gate already classes as pre-existing.
**Proceeding assumption**: (a).

**Q5 — Is the bilingual key-parity check wired into `verify_all` B.2 as a committed command?** (a) Yes:
`.harness/rules/50-singbox-cli.md:34-36` says the first real task adding a test command must replace the
matching `SKIP`, and a key-parity assertion is a few lines of shell with no new dependency and no new
file. (b) No: leave B.2 `SKIP` and promote it in T-07 with the full stub harness.
**Recommended: (a)** for the parity check only — it is the standing guard for B-10/AC-17 and it is what
stops a future task from re-introducing STD-3. The stub-PATH scenario harness stays uncommitted
(`test/` is gitignored) and its promotion stays with T-07.
**Proceeding assumption**: (a), scoped strictly to the parity assertion. If stage 2 judges even that to
be scope creep, (b) is acceptable and AC-17 is then a manual/diff-review criterion.

**Q6 — Which non-zero exit status?** (a) `1` for every failure. (b) Distinct codes per failed phase.
**Recommended: (a).** One value keeps the contract trivial for `curl | bash` wrappers; per-phase detail
belongs in the banner and the log, and distinct codes would be an unrequested mini-protocol.
**Proceeding assumption**: (a).

---

## 9. Related work

- `docs/batches/default/BATCH_PLAN.md:11,14,22-27` — T-04 (`install-error-surfacing`) is **merged into
  T-01** by the owner's consolidation directive; T-02 owns config degradation and the ruleset resource
  abstraction; T-05 (`sc doctor`) and T-07 (restricted-network regression) consume this task's outcome
  but are not enlarged by it.
- `docs/features/install-enable-start-split/02_SOLUTION_DESIGN.md` — rev.-1 design; §5's step-7 text is
  the built-and-reviewed baseline that rev. 2 extends rather than replaces.
- `docs/features/install-enable-start-split/03_GATE_REVIEW.md` — F-3 (exit status regressed 1 → 0),
  F-4 (`2>&1` starves the log), F-5 (empty-array trap hazard) are folded in as B-11, B-12, B-18.
- `docs/features/install-enable-start-split/05_CODE_REVIEW.md` — STD-3 (one-language `t()` key aborts
  under `set -u`) → B-10/AC-16/AC-17; SPEC-1 (timer enabled but not started) → B-16.
- `docs/tasks.md` — T-01 is the only tracked task; no completed historical task exists.
- `.harness/insight-index.md` — header only; no recorded insight constrains this task.
- `.harness/rejected-decisions.md` — template only; nothing here re-litigates a prior decline.
- `.harness/rules/50-singbox-cli.md` — bilingual output as a hard requirement, installer idempotency,
  both init systems, single self-contained `install.sh`, the `SKIP`-replacement rule (Q5).
- `.harness/rules/80-delivery-policy.md` — each task pushes to `main` independently; with T-04 absorbed,
  the rev.-1 "silent-failure window" sequencing risk (rev.-1 §8 Q2, gate C-7/H-1) **no longer exists** —
  one push delivers a coherent installer. This dispatch additionally instructs: do not commit or push.
- `CONTEXT.md` — unmodified template; this task coins no domain term beyond implementation identifiers.

---

## Verdict

**READY.** The expanded requirement is fully specifiable. Six deferred decisions (§8) each carry a
recommended resolution and a stated proceeding assumption; Q2 and Q5 are the two the architect should
consciously confirm, because Q2 deviates from the literal wording of the owner's instruction in order to
honor its intent, and Q5 touches a file outside `install.sh`.
