# 01 — Requirement Analysis — restricted-network-regression-test (T-07)

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

- **Task ID**: T-07 · **Mode**: full · **Date**: 2026-08-14
- **Decision authority**: owner's standing grant — every ambiguity below is resolved, none deferred.

## Goal

The project has no repeatable way to observe what a restricted-network install actually ends
up as, so T-01's AC-9 and T-02's `install.log` capture have stayed unverified for eleven tasks
while the end state they described has silently changed underneath them.

## In-scope behaviors

**FR-1 — One committed regression artifact.** The project gains exactly one executable,
version-tracked artifact that drives the restricted-network install scenario end to end and
prints a verdict. It is tracked by git and matched by no `.gitignore` pattern.

**FR-2 — The scenario is fixed and named.** The scenario is: a disposable systemd host, running
as root, with the `sing-box` binary already installed, with no configured singbox-cli
installation present, with every rule-set source unreachable, and with `install.sh` invoked from
a repository checkout. Anything outside this scenario is not what the artifact claims to test.

**FR-3 — The blackout is derived from the shipped source list, never hardcoded.** The set of
unreachable destinations is computed at run time from the rule-set source list the candidate
`bin/sc` carries (`RULESET_BASES`), unioned with `github.com`, `raw.githubusercontent.com` and
`api.github.com`. A shipped source not covered by the blackout aborts the run.

**FR-4 — End-state condition E1, stated outcome and exit status.** In the blackout arm the
installer runs to completion, prints the **success** form of its stated outcome (the
`✅` banner), and exits `0`.

**FR-5 — End-state condition E2, autostart registration.** Both `sing-box.service` and
`sing-box-rules-update.timer` are registered for boot autostart, and the timer is also running
in the current session.

**FR-6 — End-state condition E3, the cause is preserved.** The install log
(`/var/log/sing-box/install.log`) exists at mode `0640` and contains, for each of the four
rule-sets, one line naming every source tried and its cause, plus the aggregate
`{n} ruleset(s) failed to update` line, plus the degradation warning; and the installer's step-6
screen line names that log path.

**FR-7 — End-state condition E4, a degraded config that the checker accepts.**
`/etc/sing-box/config.json` exists at mode `0600`, defines no rule-set, contains no routing or
DNS rule referencing a rule-set, and is accepted by the installed `sing-box` binary's own config
check.

**FR-8 — End-state condition E5, the service is running.** The `sing-box` service is active
after the install — the founding failure (a dead service after a rule-set outage) is absent.

**FR-9 — Recovery condition E6.** With the blackout lifted and nothing else changed, one
`sc update-rules` run installs all four rule-sets, regenerates the config so that it again
defines all four and references them, restarts the service, and exits `0`.

**FR-10 — Every condition is proven able to fail.** For each of E1 … E6 the artifact records at
least one observation in the same run in which that condition's assertion does **not** hold.
E1 … E5 are the blackout arm and E6 the recovery arm, so the rule-set-dependent assertions of E3,
E4 and E6 are each other's counter-observation; any condition without such a paired observation
is reported as unproven rather than as PASS.

**FR-11 — Fail-closed refusal.** Before any command that can mutate the host, the artifact
refuses to proceed unless an explicit operator confirmation token is present **and** the host
carries no configured installation; a node store that exists but cannot be read counts as
configured. A refusal prints its reason and exits non-zero.

**FR-12 — Preconditions are verified, and an unmet one is not a failure.** The artifact checks
FR-2's preconditions before the first arm and reports an unmet precondition under a status
distinct from a failed condition.

**FR-13 — One line per condition, and the exit status is derived from them.** The artifact
prints exactly one line per condition carrying one of `PASS` / `FAIL` / `BLOCKED` / `UNMET` and
the observation it was drawn from, and exits non-zero unless every condition is `PASS`. A
condition whose observation could not be taken is `BLOCKED`, never `PASS`.

**FR-14 — An unprivileged, non-mutating self-check.** The artifact supports a mode that performs
FR-3's derivation and coverage check and FR-11's refusal logic, prints their result, mutates
nothing, needs no root and no network, and exits non-zero when the coverage check does not hold.

**FR-15 — The two owed `docs/dev-map.md` rows.** `docs/dev-map.md` gains the seam row for the
installer's curl flag policy (`CURL_OPTS_QUIET` / `CURL_OPTS_PROGRESS`) and a row naming the new
artifact, what it asserts, and where it can run.

**FR-16 — An operator guide.** A human-facing section (Chinese, per `.harness/rules/00-core.md`)
states the scenario's preconditions, how to satisfy them on a disposable VM, the invocation
including the confirmation token, and the fact that the VM is single-use.

## Out of scope

1. Wiring any step into `.harness/scripts/verify_all.{sh,ps1}` and populating `baseline.json` — that is R-9's scope, and B.3's hardcoded SKIP still conflicts with T-13's zero-delta criterion.
2. Importing `bin/sc` as a module, and any `bin/sc` unit-test harness — R-9 owns it, including permanently defusing the import-time auto-elevate.
3. Rebuilding T-02's 846-assertion harness or T-08's mirror-fault server; neither was ever committed and neither is recoverable.
4. Container support (docker / podman / lxc / nspawn), VM image build automation, and installing any package, snap or container runtime.
5. Editing `install.sh`, `bin/sc`, `uninstall.sh` or any file under `systemd/`.
6. The OpenRC / Alpine install path.
7. T-02's other unverified items — BC-25 (`env_reset` stripping `SB_RULES_BASE`), the D-2 sudo escalation, and AC-26 on a real Python 3.6 interpreter.
8. T-11's R-1 … R-8 (`install.sh`'s `set -e` assignment-abort family); read for this task, and the scenario reaches none of those call sites.
9. Exercising `install.sh`'s remote-artifact branch, or redirecting `RAW_BASE`, which is a hardcoded constant with no override.
10. Any execution of `install.sh`, `uninstall.sh` or `sc` against the host this pipeline runs on.
11. Multi-distro coverage: one systemd distribution is the whole claim.
12. Node credentials and node-carrying configurations; the scenario configures no node.

## Boundary conditions

**BC-1 — Rule-sets already present.** A blackout arm that starts with any usable rule-set on disk
→ report `UNMET` for the arm and make no condition claim; the rule-set directory being empty is a
precondition of the arm, not an outcome of it.

**BC-2 — Uncovered source.** A source in the shipped list that the blackout does not cover →
abort with `UNMET` before the install runs; never `PASS`, never a silent skip.

**BC-3 — Environment-carried injection.** A blackout implemented through an environment variable
that `bin/sc` reads → the arm proves the variable reached `sc`'s effective source list before any
condition is claimed; an unproven injection makes the arm `BLOCKED`.

**BC-4 — No `sing-box` binary.** The scenario host has no `sing-box` binary → `UNMET`; the
artifact does not attempt to install one.

**BC-5 — No TUN device.** No `/dev/net/tun` on the scenario host → `UNMET` before the arm runs,
because E1 and E5 both depend on the service being able to start.

**BC-6 — Interactive prompts.** `install.sh` reads a language choice and, when it cannot identify
a non-root install user, a confirmation → the artifact supplies both answers; a run that ends at
a prompt is `UNMET`, never `FAIL`.

**BC-7 — Configured installation present.** A node store present (or present and unreadable) →
refuse per FR-11 before any mutation, exit non-zero.

**BC-8 — Confirmation token absent.** No token → refuse before any mutation, exit non-zero, and
name the token.

**BC-9 — Recovery arm has no reachable source.** Every source still unreachable after the
blackout is lifted → E6 is `BLOCKED`, and every non-vacuity claim that depended on it is reported
unproven.

**BC-10 — Install log unwritable.** The installer's log probe fails, so its messages take the
"log not writable" form → E3 is `FAIL` and the artifact records the alternate line it observed.

**BC-11 — Re-run on a used host.** A second run on a host where the previous run completed →
BC-1 applies; the artifact never uninstalls or resets the host on its own.

**BC-12 — Observation unavailable.** A command needed for an observation is missing or refused →
that condition is `BLOCKED` and the run's exit status is non-zero.

**BC-13 — Empty or unparsable source list.** The derivation in FR-3 yields no source or cannot
parse the shipped list → `UNMET`; an empty blackout must never read as full coverage.

**BC-14 — Zero nodes.** The scenario emits a config with no node outbound → E4's assertions are
written against a node-free document and require no node outbound to be present.

## Acceptance criteria

Verification tags: `[HOST]` = dischargeable in this pipeline's environment;
`[VM]` = dischargeable only on an owner-provided disposable VM.
Class: `[S]` structural (artifact / diff property), `[B]` behavioural (observed by running).

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | The artifact is tracked by git and is not matched by any ignore pattern. | [S] | `[HOST]` `git ls-files` lists it; `git check-ignore -v` reports no match. |
| AC-2 | The artifact parses, and `verify_all` counts are unchanged at `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`. | [S] | `[HOST]` `bash -n` on the artifact; `verify_all` re-run and compared to the batch baseline. |
| AC-3 | With no confirmation token, the artifact exits non-zero, names the missing token, and performs no write outside its own temporary area and no change to network configuration. | [B] | `[HOST]` run unprivileged with no token; compare the host's network configuration files and the live-service witness before and after. |
| AC-4 | With the token supplied but a configured installation present, the artifact refuses and exits non-zero before any mutation. | [B] | `[HOST]` run unprivileged, where every mutation would fail anyway, and confirm the refusal is reached before the first mutating command. |
| AC-5 | The self-check mode lists all four shipped rule-set sources as covered and exits 0; against a scratch source list carrying one uncovered entry it exits non-zero naming that entry. | [B] | `[HOST]` two runs of the self-check, the second over a copied source list; the failing run is the coverage guard's non-vacuity proof. |
| AC-6 | E1 holds: the installer completes, prints the success banner, exits 0. | [B] | `[VM]` captured installer output plus its exit status. |
| AC-7 | E2 holds: both units are enabled and the timer is running. | [B] | `[VM]` `systemctl is-enabled` for both units and the timer's active state. |
| AC-8 | E3 holds: the install log exists at `0640` and carries four per-rule-set cause lines naming every source, the aggregate count line, and the degradation warning; the step-6 screen line names the log path. | [B] | `[VM]` file mode plus a content match per element, and the captured installer output. |
| AC-9 | E4 holds: `config.json` exists at `0600`, defines no rule-set, references none in either rule array, and the installed `sing-box` accepts it. | [B] | `[VM]` file mode, a structural read of the document, and the binary's own config check exit status. |
| AC-10 | E5 holds: the `sing-box` service is active after the install. | [B] | `[VM]` service state read after a bounded settle window. |
| AC-11 | E6 holds: with the blackout lifted, one `sc update-rules` installs all four rule-sets, the regenerated config defines and references all four, the service is restarted, and the command exits 0. | [B] | `[VM]` command exit status, output, the document before and after, and the service witness before and after. |
| AC-12 | Each of E1 … E6 has a recorded observation in the same run in which its assertion does not hold. | [B] | `[VM]` the paired blackout / recovery observations, listed per condition in the test report. |
| AC-13 | Starting the blackout arm with a populated rule-set directory yields `UNMET`, never `PASS`. | [B] | `[VM]` one deliberate run with the directory pre-populated. |
| AC-14 | `docs/dev-map.md` carries the curl-flag-policy seam row and the artifact row. | [S] | `[HOST]` read the two rows. |
| AC-15 | The operator guide states the preconditions, the invocation with its token, and the single-use nature of the VM, in Chinese. | [S] | `[HOST]` read the section against this list. |
| AC-16 | `install.sh`, `bin/sc`, `uninstall.sh` and every file under `systemd/` are byte-identical to `HEAD`. | [S] | `[HOST]` per-file hash against a clone of `HEAD` — a clone, never a `git worktree`. |
| AC-17 | `.harness/scripts/baseline.json` is unchanged. | [S] | `[HOST]` byte comparison. |
| AC-18 | The live sing-box instance on this pipeline's host is untouched for the whole task. | [B] | `[HOST]` `systemctl show -p MainPID -p ActiveEnterTimestamp` identical at task start and delivery; never `is-active`. |
| AC-19 | Every `[VM]` criterion is reported as `BLOCKED` with its reason in `06_TEST_REPORT.md`, with no artifact inspection substituted for it. | [S] | `[HOST]` read the report against this table. |
| AC-20 | The artifact's report shows one line per condition with one of the four statuses, and its exit status is non-zero unless every line is `PASS`. | [B] | `[HOST]` for the refusal and self-check paths; `[VM]` for the full run. |

## Non-functional requirements

- The artifact introduces no dependency beyond what `install.sh` already requires on its target
  host: bash, coreutils, curl, python3 and systemd. No package, snap or runtime is installed.
- The artifact is one executable file of at most **250 lines**, plus the operator-guide section.
  A larger design must state, per rule 85, what the extra machinery buys.
- The artifact adds at most **30 seconds** of its own waiting across the whole run; all remaining
  wall-clock is the installer's and `sc`'s own network timeouts (30 / 8 / 3 s, unchanged).
- The artifact prints no byte of any credential document's content; only structural facts (key
  presence, array membership, file mode) are reported, so `verify_all` A.1 cannot be tripped.
- The artifact's own output is English, matching `verify_all` and `check-i18n-parity.sh`; the
  operator guide of FR-16 is Chinese.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Do the failure report's five end-state conditions still describe the code? | No. The report's section 四 is in no repository file; its only recorded restatements are T-01's AC-9 and the pool's Notes line, and both are superseded. The binding end state is E1 … E6 in FR-4 … FR-9. |
| Q-2 | Does a restricted-network install still end in the failure banner and a non-zero exit, as AC-9 says? | No. T-02's degradation makes config generation succeed with every rule-set missing, so the config phase records `ok`, the service starts, and the run ends in the **success** banner and exit `0`. Asserting AC-9's second and third clauses would fail the test on correct code. |
| Q-3 | Is blocking `github.com` and `raw.githubusercontent.com` enough to reproduce the scenario? | No. The shipped source list holds four entries across three failure domains; blocking those two names leaves two jsDelivr edges and `ghfast.top` reachable, the download succeeds, and nothing degrades. The blackout is FR-3's derived set. |
| Q-4 | Can the test run "the full one-liner install"? | No. The one-liner fetches `install.sh` from the blocked host, and under the blackout the remote-artifact branch exits at its first fetch. The artifact runs `install.sh` from a repository checkout, and that the remote-artifact branch is therefore unexercised is a stated coverage limit. |
| Q-5 | Container or VM? | A disposable VM with systemd and `/dev/net/tun`. Container support is out of scope; no container runtime is usable in this pipeline's environment and none may be installed. |
| Q-6 | Does T-07 inherit T-02's 846-assertion harness? | No — it cannot. That harness lived in a QA session scratchpad (11 files) and was never committed or pasted; nothing of it exists. T-07 does not rebuild it, and it is not this task's subject. |
| Q-7 | What happens to T-08's two inherited test-infrastructure defects? | The files carrying them (`gate_checks.sh`, `server.py`) were likewise never committed and do not exist, so neither is fixable. Both become binding requirements instead: the write-vs-read filename mismatch becomes FR-3's single derived source of truth plus BC-2/BC-13, and the unguarded non-vacuity becomes FR-10, AC-5 and AC-12. |
| Q-8 | Does T-07 discharge the `CURL_OPTS_*` dev-map seam row? | Yes — FR-15. It is one table row in a document this task edits anyway. |
| Q-9 | Does `baseline.json` finally get a non-zero `test_count`? | No. No script in this repository reads that file, and no assertion of the new artifact can be run in this pipeline's environment, so a count would be a claim about tests that never ran. It stays at 0 and R-4/R-9 keep it. |
| Q-10 | Does T-07 wire a `verify_all` step? | No. That is R-9's scope, together with the `.ps1` mirror and `baseline.json`, and the B.3 SKIP still collides with the zero-delta criterion T-13 made binding. |
| Q-11 | Where does the artifact live, given that `test/` is ignored? | Not under any ignored path. The concrete location is stage 2's; AC-1 is what binds. |
| Q-12 | Does T-07 cover T-11's R-1 … R-8? | No. The scenario reaches none of those call sites, so covering them would require faults the scenario does not inject. They stay open and unclaimed. |
| Q-13 | Which of T-02's four unverified items does T-07 close? | BC-32 only — the degradation warning reaching the install log — and it is closed by E3. BC-25, the D-2 escalation and AC-26 stay open. |
| Q-14 | May the artifact use `systemctl is-active` and mutate `/etc/hosts`? | Yes, inside the disposable VM. The prohibition on both is a property of this pipeline's host, which the artifact never runs against by FR-11. |
| Q-15 | Is "the harness ships but is never executed end to end here" an acceptable outcome? | Yes, and it is the expected one. Every `[VM]` criterion is reported `BLOCKED` with its reason per AC-19; substituting an artifact inspection for a `[VM]` run is a defect. |
| Q-16 | Does the artifact clean up after itself? | No. The VM is single-use; the artifact never runs `uninstall.sh` and never resets the host, and BC-11 makes a second run report `UNMET`. |
| Q-17 | Is a schema gap recorded for this contract? | Yes: `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` (R-37, now a third occurrence), so this document applies the analyst contract's schema as written and routes everything else to `01_RATIONALE.md`. |

## Verdict

`READY`
