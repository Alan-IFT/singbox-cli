# 01 — Requirement Analysis · T-19 `ruleset-staleness-visibility`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).
>
> Mode: **full** · Standing decision grant for this pool (「你来决策就行」) — every judgment call below
> is resolved and recorded, none is deferred to the owner.

## Goal

A host whose rule-sets stopped updating looks healthy: nothing in `sc` reports how long a `.srs` file
has been sitting un-refreshed, and a scheduled `sc update-rules` run that downloads new rule-sets but
then fails to regenerate the config, or fails to restart the service, prints a warning and **exits 0**
— so systemd records the run as successful.

## In-scope behaviors

**FR-1** — The single on-disk rule-set reader (`ruleset_state()` for one file, `ruleset_states()` for
the snapshot) reports, per rule-set, the time that file's bytes were last written, obtained by the same
call that decides its status, digest and byte count. No other site in `bin/sc` queries a rule-set
file's timestamp.

**FR-2** — Exactly one function converts such a timestamp into a human-readable age. Every surface that
displays an age calls it; it takes no argument specific to any one command, so a later `sc doctor`
rule-set-age row (T-20) consumes it unchanged rather than re-deriving an age.

**FR-3** — `sc status` prints one section listing every known rule-set with its usability status and its
age, once per run, whether or not the sing-box service is running.

**FR-4** — Where the reader obtained no timestamp, the age is stated as unavailable in words. No run
renders a missing timestamp as a number, as zero, or as an epoch date.

**FR-5** — Rule-set age never reaches the generated configuration: for identical rule-set contents the
emitted `config.json` bytes are independent of every rule-set's timestamp, and no rule-set is dropped,
degraded or re-downloaded because of its age.

**FR-6** — `sc update-rules` derives its process exit status and its single run-level outcome sentence
from one determination of what the run achieved, so the sentence and the status cannot disagree.

**FR-7** — That determination counts three things as a failure of the run: a rule-set that failed on
every mirror, a config regeneration or config check that did not succeed, and a service-affecting
action that did not succeed. A run with none of them exits 0; a run with at least one exits non-zero.

**FR-8** — The run states only what it did: no line claims the config was regenerated when regeneration
failed, and no line claims the service was restarted when the restart did not succeed.

**FR-9** — Every existing `sc update-rules` output contract holds unchanged: exactly one completion line
per rule-set on a non-TTY, per-file causes on stdout, the aggregate failure sentence on stderr,
TTY-gated progress, and exactly one run-level outcome line per run drawn from T-10's closed set,
extended only by the truthful variants FR-8 requires.

**FR-10** — Every user-facing string this task adds ships as an English sentence used as the
translation key plus a Simplified-Chinese entry carrying the same placeholder set; no added Chinese
string contains the substring `失败：`; both READMEs' one-line description of `sc status` gains the
rule-set section in the same commit; `CHANGELOG.md` gains one entry in the file's existing single
language.

## Out of scope

1. No staleness threshold, no stale/fresh verdict, no age-derived warning, and no age-derived exit
   status anywhere in this task (Q-4).
2. No edit to any systemd unit or timer file, and none to the OpenRC periodic script or the code that
   writes it (Q-3, Q-7).
3. No structural enforcement of the run-level-outcome invariant on paths that unwind past the tail of
   `cmd_update_rules()` — open row **R-12** is narrowed, not claimed (Q-2).
4. No edit to `install.sh`, including its step-6 branch on `sc update-rules`' exit status (Q-9).
5. No behavior change for any caller of the shared service-restart helper other than `sc update-rules`
   (`sc reload`, `sc use`, `sc add`, `sc rm`, `sc ipv6`, `sc telemetry`).
6. No change to what counts as a content change for the restart decision — a timestamp stays excluded
   from that judgment (`.harness/rejected-decisions.md § mtime-or-size-as-a-ruleset-change-signal`).
7. No fix for `sc status`'s redirected-output section ordering (R-33) or any other pre-existing
   `sc status` defect.
8. No committed test harness and no new `verify_all` step (R-9).
9. No fix for the five literal `ls.*` keys (R-19) or any other pre-existing i18n defect.
10. No rule-set age row in `sc doctor` — T-20 owns that row and consumes FR-1/FR-2.
11. No new subcommand, no new setting, no new product file, no new config format, no new exit-status
    taxonomy. The `docs/dev-map.md` correction AC-S3 admits adds no file and no section — it is bounded
    there to two existing rows plus at most one added row in the same table.

## Boundary conditions

**BC-1** — Rule-set file absent → status `absent` and the age stated as unavailable, with no numeric
duration on that line.

**BC-2** — Rule-set path unreadable (dangling symlink, directory, FIFO, permission denied) → status
`unreadable` and the age stated as unavailable.

**BC-3** — Rule-set file readable and empty (0 bytes) → status `too-small` **and** a real age, because a
complete read happened; the existing invariant "no complete read ⟺ no digest and no size" extends to
the timestamp rather than acquiring a second, differently-shaped invariant.

**BC-4** — Timestamp later than the current clock (host clock skew, restored backup) → the age renders
as a zero-length duration; the run does not print a negative duration, does not warn, and does not fail.

**BC-5** — Rule-sets directory absent entirely (host before its first successful update) → every known
rule-set prints one row reading absent with the age unavailable, and `sc status` creates nothing.

**BC-6** — sing-box service stopped → the rule-set section still prints in full; it is not gated on the
service being reachable.

**BC-7** — `sc status` stdout is not a terminal → the section emits one complete line per rule-set, no
carriage return, no intermediate state.

**BC-8** — Every mirror fails for at least one rule-set → non-zero exit, per-file causes on stdout,
aggregate sentence on stderr, exactly one run-level outcome line. Unchanged from HEAD; this is a freeze,
not a change.

**BC-9** — Rule-sets gained and regeneration or `sing-box check` did not succeed → the run performs no
service-affecting action, its outcome does not claim the config was regenerated, and it exits non-zero.

**BC-10** — Content changed, service running, and the restart command reports failure → the run's
outcome line does not claim the service was restarted, and the run exits non-zero.

**BC-11** — Nothing changed and nothing failed → exit 0 with the "no rule-set changed — the service was
not touched" outcome. `install.sh` step 6 and T-10's D-6 both depend on this status staying 0.

**BC-12** — No `config.json` on disk (fresh install) → unchanged: no regeneration, no service-affecting
action, exit status governed only by download outcomes.

**BC-13** — A helper exits, or an `OverrideError` unwinds, past the tail of `cmd_update_rules()` (R-12's
two known paths) → the process still exits non-zero with the cause named on stderr and with no
service-affecting action performed; the run-level outcome line is absent, and that absence remains
R-12's open row rather than becoming a T-19 defect.

**BC-14** — A timer run and a manual run overlap → unchanged (per-process temp names, atomic replace);
the reported age is that of whichever run last replaced the file.

## Acceptance criteria

Class `[B]` = observes the user-visible behavior; `[S]` = observes an artifact. Every `[B]` criterion is
verified in a redirected fixture built with `docs/dev-map.md`'s module-load recipe (all eight path
constants repointed into a temp root, `SYSTEMD = OPENRC = False` unless the criterion states otherwise,
`_init_files()` never driven, `/usr/local/bin/sc` never invoked). **A criterion that cannot be verified
is reported unverified with the reason; substituting a weaker artifact check for a behavioral criterion
is a defect (R-31 precedent).**

| id | criterion | class | verification |
|---|---|---|---|
| AC-B1 | With two usable rule-sets in the fixture, one written now and one whose timestamp is set 30 days in the past, `sc status` names both and reports the aged one with a duration of at least 29 days and the fresh one with a duration under one minute. | [B] | Fixture `cmd_status` run, stdout captured; `os.utime` sets the aged timestamp. Discriminating: HEAD prints no rule-set section at all. |
| AC-B2 | In the same run, an absent rule-set and an unreadable one each report the age as unavailable in words, and neither line carries a numeric duration. | [B] | Same capture, per-line assertions (BC-1, BC-2). |
| AC-B3 | The rule-set section prints in full on a run where the sing-box service is not reachable. | [B] | Fixture run with no Clash API listening (BC-6). |
| AC-B4 | For one fixture rule-set set, the bytes `generate_config()` emits are identical whether every rule-set's timestamp is current or 30 days old. | [B] | Two fixture generations at the same path, byte comparison (FR-5). |
| AC-B5 | A run in which a rule-set is gained and `sing-box check` rejects the composed config exits non-zero, performs no service-affecting action, and does not claim the config was regenerated. | [B] | Child-process run, exit status read from the process; stub `SB_BIN` returns non-zero for `check`. **HEAD control exits 0** — this is the discriminating observation of the goal's second half. |
| AC-B6 | A run in which the restart command reports failure exits non-zero and its run-level outcome line does not claim the service was restarted. | [B] | Child-process run with the loaded module's process-launch binding replaced (never a real `systemctl`), `SYSTEMD = True`. **HEAD control exits 0 and claims a restart.** |
| AC-B7 | Freeze: a run in which every mirror fails for at least one rule-set still exits non-zero with per-file causes on stdout and the aggregate on stderr; a run in which nothing changed and nothing failed still exits 0 with the "no rule-set changed" outcome. | [B] | Two child-process runs (`--mirror` at an unreachable base; a `file://` mirror serving byte-identical content). Control **agrees** at HEAD by design — declared a freeze, never quoted as evidence of a change. |
| AC-B8 | Across every fixture state exercised by AC-B5 … AC-B7, each run prints exactly one run-level outcome line, and every claim that line makes is true of that run. | [B] | Count and cross-check outcome lines against the stub call log per run. |
| AC-B9 | The shipped invocation form — the installed unit's command, run as root on a systemd host — records a failed unit when the run fails. | [B] | Read-only `systemctl show` / `journalctl` observation by the owner. **Reported BLOCKED if root or live-unit access is unavailable; never substituted with a unit-file read.** |
| AC-S1 | Exactly one site in `bin/sc` obtains a rule-set file's timestamp, inside the single reader, and exactly one function renders a timestamp as an age; the age renderer takes no `sc status`-specific argument. | [S] | Static sweep of `bin/sc` for timestamp queries and for age-rendering call sites; signature read (FR-1, FR-2). |
| AC-S2 | Every string added ships in both languages with matching placeholders, no added Chinese string contains `失败：`, and no redirected fixture run emits a carriage return. | [S] | Table read plus byte scan of every captured stream (FR-10, BC-7). |
| AC-S3 | **Product diff** — the committed diff changes no product file other than `bin/sc`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md` and `docs/dev-map.md`, and the `docs/dev-map.md` change is confined to its `## Reusable utilities` table: the two rows whose stated tuple shapes the widening falsifies — the one-file on-disk reader row and the per-file snapshot row — are corrected, at most one row is added to that same table naming the single age renderer, and no other line of the file changes (no section added or removed, no other row's text altered, no row deleted). **Ledger and stage documents** — the delivery commit additionally writes only `docs/tasks.md`, `docs/tasks-archive.md`, `.harness/insight-index.md`, `docs/features/_archived/insight-history.md`, `.harness/rejected-decisions.md` and this task's stage documents at their delivered path; these are the PM's delivery-time writes, they are not part of the product diff, and a path in neither list is a failure of this criterion. **Safety** — `.harness/scripts/verify_all.sh` reports PASS 17 / WARN 0 / FAIL 0 / SKIP 1; no verification step wrote `/etc/sing-box` or `/var/lib/sing-box`, invoked `/usr/local/bin/sc`, or touched the live service or its units. | [S] | `git diff --name-only` partitioned against the two lists; `git diff docs/dev-map.md` read line by line against the stated bound; verify_all before/after; command-log review. |

## Non-functional requirements

- `sc status` gains at most one additional filesystem metadata query per rule-set — four in total, on
  local files already being read — and no network call, no service call and no subprocess.
- The single rule-set reader stays non-raising and write-free: it creates, modifies and deletes nothing,
  and returns a value for every input including a path it cannot read.
- `.harness/scripts/verify_all.sh` ends at the batch baseline **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**; a
  FAIL stops the batch.
- Safety floor for every stage: never write `/etc/sing-box/` or `/var/lib/sing-box`, never drive
  `_init_files()` (it hard-codes `/var/lib/sing-box`), never invoke `/usr/local/bin/sc`, never start,
  stop, restart or reload the live service, and never write a systemd unit or drop-in.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | One task or two? | **Two independent changes, delivered as one task.** Re-derived against rule 85's tests after T-02: neither half computes anything the other consumes, neither ships an incoherent or dishonest intermediate state alone, and they need **different** judgments — "how old is this file" (a fact about disk) versus "did this run fail" (a fact about the run). Independence is an argument against coupling them in code, not for two pipelines: both are few-line changes in one file, so they ship together with no shared code path, separable acceptance criteria (AC-B1…B4 versus AC-B5…B8), and a rollback of either that cannot touch the other. |
| Q-2 | Does T-19 claim R-12? | **No — T-19 narrows R-12 and the PM records the narrowing.** T-19 owns the run's exit status; R-12's two unwind paths already exit non-zero with the cause named on stderr, before any service-affecting action, so they already satisfy everything the goal's second half asks for. What they still miss is T-10's run-level outcome *line*, and enforcing that structurally costs an envelope around the whole command whose failure modes (printing an outcome during an interrupt, printing after an exception's own message) are worse than the gap. After T-19, R-12 is a statement about the outcome line only. |
| Q-3 | Is OpenRC in scope? | **No file OpenRC owns is edited, and the fix reaches OpenRC anyway.** The whole of the second half lands in `sc update-rules`' own exit status, which both the systemd unit and the OpenRC periodic script consume by invoking the same command; T-09 already rejected unifying the two invocation paths and that ruling stands. |
| Q-4 | Does T-19 define what "stale" means? | **No threshold and no verdict. T-19 defines the age as one datum with one producer and one renderer.** `sc status` is a facts screen with no classification vocabulary; a fixed threshold would be wrong on every host that changed its cadence with `sc update-interval`, and deriving one from the configured cadence is machinery no stated requirement needs. The binding rule instead: any future staleness verdict must be a function of the age this reader produces, and no site may derive a rule-set's age a second way — which is what stops `sc status`, T-20's `sc doctor` row and config generation from ever holding two opinions. |
| Q-5 | What is "age" measured from? | The time the file's bytes were last written, which for every file this project installs is the time of the last successful fetch (each fetch replaces the target). This does **not** re-open `.harness/rejected-decisions.md § mtime-or-size-as-a-ruleset-change-signal`: that record declines a timestamp as the *content-change* signal for restarting, and FR-5 plus out-of-scope item 6 keep it out of that judgment. Here the very property that record objects to — being renewed on every successful run whether or not bytes differ — is exactly the fact the user needs. |
| Q-6 | Does a failed restart belong in T-19? | **Yes.** It is the loudest lie the run can tell: HEAD ignores the restart command's status and then prints "sing-box restarted to load them". Leaving it out would ship the run-outcome half in the state rule 85's own T-01 precedent names — a run that detects its own failure and reports success anyway. |
| Q-7 | Does the unit file need `SuccessExitStatus=` or any other edit? | **No.** The shipped unit is `Type=oneshot` with one un-prefixed `ExecStart` and no `SuccessExitStatus=` and no `Restart=`, so a non-zero exit is already recorded as a failed unit. The goal's phrase "make the timer actually fail" is satisfied entirely inside `bin/sc`. |
| Q-8 | Is the goal's second clause true at HEAD? | **Partly false, and the false part is the case it names.** HEAD already exits 1 when every mirror fails for a rule-set, so the timer already fails on a failed *download*. The real defects are the two states nobody enumerated: a failed regeneration or config check after new rule-sets landed, and a failed restart — both exit 0 today. FR-6/FR-7 are written against those, not against the clause as briefed. |
| Q-9 | `install.sh` step 6 branches on this exit status — is the new non-zero path a problem? | **Accepted, not fixed here, and filed.** On a re-install where rule-sets download but regeneration fails, step 6 will now report its ruleset-download warning for a non-download cause. The signal ("step 6 did not fully succeed") stays true, the cause is in the install log, and step 7's own `sc reload` failure states it accurately. `install.sh` is out of this task's diff; the PM files the imprecise message as a follow-up row. |
| Q-10 | Which exit status does a failed run use? | **1, for every failure class**, matching the existing aggregate exit. No taxonomy of codes is introduced: the only consumers are systemd (non-zero versus zero), `install.sh` step 6 and OpenRC's periodic runner, none of which distinguishes values. |
| Q-11 | How is the age rendered? | One deterministic short duration per rule-set with a coarse unit chosen by magnitude, in both languages, on one line per rule-set together with that file's status. The exact wording is stage 2's; what is binding is one line per rule-set, one renderer, one vocabulary, and an explicit word — never a number — when the timestamp is unavailable. |
| Q-12 | Does the new `sc status` section change the redirected section ordering defect (R-33)? | **No, and it is not fixed here.** The section is a `print()` like every other `sc status` heading, so under redirection it lands with the other buffered prints and adds no new class of reordering. A verification step that greps for a line is unaffected; one that asserts section order will see R-33 and must not report it as a T-19 defect. |
| Q-13 | Schema gap: the contract schema declares no shape for a premise the requirement rests on but nobody has measured. | The premises are carried in a task-local `## Premises to be measured` section below, because the PM's dispatch requires the list in the contract and `.harness/rules/70-doc-size.md` on this project defines no `## Stage-doc boundary rule` to classify it. Recorded here rather than resolved silently. |

## Premises to be measured

Nothing below is established fact. Each is `PREMISE (to be measured at stage 4/6)`; the requirement is
written so that a refuted premise narrows the work rather than invalidating it. T-09's precedent (a
widely-repeated claim about timer history with zero empirical support) and T-18's (a batch-goal cause
that existed in no commit) are why this list exists.

| id | premise | how it is settled |
|---|---|---|
| P-1 | `sys.exit(<str>)` writes the string to stderr and exits the process with status 1. | `python3 -c 'import sys; sys.exit("boom")' ; echo "status=$?"` with stdout and stderr captured separately. |
| P-2 | At HEAD, a run in which every mirror fails for at least one rule-set already exits non-zero (i.e. the goal's second clause is false for the case it names). | Fixture child-process run with `--mirror` pointed at an unreachable base; read the process exit status. |
| P-3 | At HEAD, a run in which a rule-set is gained and `generate_config()` returns False exits **0** and prints a line claiming the config was regenerated. | Fixture child-process run with an existing `config.json`, a `file://` mirror serving a valid `.srs`, and a stub `SB_BIN` whose `check` exits non-zero. |
| P-4 | At HEAD, a failed restart command is unobserved: the run exits 0 and claims the service was restarted. | Fixture child-process run with the loaded module's process-launch binding replaced by a stub returning non-zero. **Never with a real `systemctl` on `PATH`.** |
| P-5 | A `.srs` installed by a successful fetch carries the timestamp of that fetch, and a rule-set whose fetch failed keeps its previous timestamp. | Record each file's timestamp before and after a fixture run against a `file://` mirror, one rule-set succeeding and one failing. |
| P-6 | The shipped unit records a non-zero run as a failed unit on this host. | Read-only `systemctl show -p Result,ExecMainStatus sing-box-rules-update.service` after an owner-run trigger. **Not obtainable inside this pipeline** — no agent may touch the live unit. Report BLOCKED (AC-B9), never substitute the unit-file read that shows no `SuccessExitStatus=`. |
| P-7 | Anything about how often the timer has fired on this host, or what it produced. | **No requirement rests on this.** T-09 measured that the unit had never run here. If a later stage needs it: `systemctl list-timers --all sing-box-rules-update.timer` and `journalctl -u sing-box-rules-update.service` — read-only queries, no unit mutation. |
| P-8 | `install.sh` step 6 sets its ruleset phase from `sc update-rules`' exit status, so a new non-zero path re-labels that step (Q-9). | Read the step-6 branch in `install.sh`; no execution. |

## Verdict

**READY.**
