# 01 — Requirement Analysis · T-10 `ruleset-update-no-needless-restart`

Mode: **full** · Deferred-human mode: **defer, do not ask** (standing decision authority;
resolutions recorded in §10) · Author: Requirement Analyst · Date: 2026-07-31

---

## 1. Goal

`sc update-rules` terminates every live sing-box connection on every run, including runs in
which no rule-set file changed; the run must leave the service untouched unless the rule-set
state on disk actually changed.

---

## 2. Evidence (backward-looking — path:line citations are proof of the current state)

| # | Fact | Evidence |
|---|---|---|
| E-1 | The run ends with an unconditional restart whenever nothing was newly *gained*: `if not applied and is_running(): print(...); restart_service()`. `applied` is set only inside the `gained and CFG_PATH.exists()` branch, so a run that re-downloads four byte-identical files takes this branch. | `bin/sc:1127-1144` |
| E-2 | `restart_service()` issues `systemctl restart sing-box` / `rc-service sing-box restart` — a full process restart, which drops every proxied connection. | `bin/sc:834-838` |
| E-3 | The weekly timer now really fires (T-09, commit `0bb2373`): `ExecStart=/usr/local/bin/sc update-rules`, `OnCalendar=weekly`, `RandomizedDelaySec=1h`, `Persistent=true`. Before T-09 the unit had never executed. | `systemd/sing-box-rules-update.service:7`, `systemd/sing-box-rules-update.timer:4-7` |
| E-4 | The same command is scheduled on OpenRC hosts through `/etc/periodic/<period>/singbox-update-rules`, so this is not a systemd-only defect. | `bin/sc:1217` |
| E-5 | `install.sh` runs `sc update-rules` at step 6, before the config exists on a first install and while the service is already running on a re-install (the documented upgrade path). | `install.sh:456`, `install.sh:479-492` |
| E-6 | The single on-disk rule-set judgment already exists and is explicitly declared the only one allowed: `srs_reject_reason` / `ruleset_status` / `ruleset_report` / `usable_tags`, with the header comment "Adding a second notion of usability anywhere else is a defect". | `bin/sc:492-546` |
| E-7 | T-02 chose restart deliberately for the *recovery* case and recorded why: "Hot-apply is not available here … the Clash API can switch proxy and mode only; a changed `route.rule_set` is structural." That conclusion was drawn about the code paths `sc` uses today, not from a documented sing-box reload contract. | `docs/features/_archived/config-degrade-missing-rulesets/02_SOLUTION_DESIGN.md:354-358` |
| E-8 | The Clash API client exists and is loopback-only, on an auto-probed persisted port. | `bin/sc:850-861`, `bin/sc:187-205` |
| E-9 | T-02 explicitly froze today's behavior as BC-28 ("usable set unchanged ⇒ behavior identical to today: restart only if the service is running"), so the restart is inherited, not introduced by T-02. | `docs/features/_archived/config-degrade-missing-rulesets/01_REQUIREMENT_ANALYSIS.md:178` |
| E-10 | A user-facing document already asserts the disruption: the T-09 CHANGELOG bullet says running the unit "在 sing-box 正在运行时会重启 sing-box（连接会中断几秒）". It becomes false with this change. | `CHANGELOG.md:15` |
| E-11 | Project convention: "Hot-apply over restart. … Prefer the API path over `systemctl restart`", plus bilingual output as a hard requirement, the Python 3.6+ floor, and "config is regenerated, never patched". | `.harness/rules/50-singbox-cli.md:83-106` |
| E-12 | README (both languages) advertises hot node switching with no restart, and promises that rule-sets "come back automatically" after `sc update-rules`. | `README.md:12,84,118`, `README.zh-CN.md:12,84,118` |
| E-13 | Insight-index: all four configured mirror bases return byte-identical content — i.e. a successful re-download of unchanged bytes is the common case, not an edge case. | `.harness/insight-index.md:15` |
| E-14 | Insight-index: `bin/sc`'s import-time auto-elevate re-execs the **installed** `/usr/local/bin/sc` and sudo's `env_reset` drops `SB_RULES_BASE`, so an un-neutralised test import runs the *installed* tool against the *live* service. | `.harness/insight-index.md:13`, `bin/sc:77-78` |
| E-15 | Insight-index: `失败：` in `bin/sc` output is a load-bearing diagnostic grep meaning "this file was not updated". | `.harness/insight-index.md:16` |

---

## 3. Terminology (used with these exact meanings throughout; added to `CONTEXT.md`)

- **usable rule-set** — a `.srs` file that exists, is a regular file, carries the `SRS` magic and
  meets the size floor. The single judgment at `bin/sc:492-546`.
- **gained** — a rule-set whose status changed from not-usable to usable during one run. Drives
  *config* regeneration, because the generated `config.json` contents depend on which rule-sets
  are usable (T-02).
- **content-changed** — a rule-set whose installed bytes at the end of a run differ from its
  installed bytes at the start of that run. Drives *rule-set data* re-application, because the
  generated `config.json` is byte-identical while the data sing-box loaded is stale.
- **service-affecting action** — any operation that restarts, reloads, starts or stops the
  `sing-box` service, or that instructs the running process to re-read configuration or rule-set
  data.
- **run** — one execution of `sc update-rules`.

Every gained rule-set is content-changed; the converse is false. This document keeps the two
words distinct and never uses one for the other.

---

## 4. In-scope behaviors

**B-1** `sc update-rules` determines, for each rule-set it manages, whether that rule-set is
content-changed by the run, by comparing the installed bytes observed before the run against the
installed bytes present after the run. The comparison is over file **content** (full byte
equality, or a digest of the full content). Modification time, `Content-Length`, "the HTTP request
returned 200", "a file was written" and file size alone are each insufficient signals and are not
used as the change signal.

**B-2** A run in which no rule-set is content-changed and no rule-set is gained performs **no
service-affecting action**: no restart, no reload, no start, no stop, no config regeneration.

**B-3** A run in which at least one rule-set is content-changed applies the new rule-set data to
the sing-box service when that service is running, and reports which rule-sets changed.

**B-4** The apply mechanism of B-3 minimises service disruption: when the sing-box version this
project installs exposes a mechanism that makes changed rule-set data effective without
terminating established connections, that mechanism is used; otherwise the service is restarted.
Stage 2 establishes which of the two holds, records the evidence for it in
`02_SOLUTION_DESIGN.md`, and the shipped user-facing text states whichever is true. A claim that a
non-disruptive apply succeeded is made only when the run has evidence that it succeeded.

**B-5** When the chosen non-disruptive mechanism (if any) is attempted and does not succeed, the
run falls back to the restart path and reports that it restarted. Silently reporting "applied"
after a failed non-disruptive attempt is a defect.

**B-6** T-02's recovery behavior is preserved unchanged in effect: when at least one rule-set is
gained and `/etc/sing-box/config.json` exists, the run regenerates the config (never patches it),
prints the existing "Rule-sets restored" message, and applies it when the service is running.

**B-7** A run in which rule-sets are content-changed but the set of usable rule-sets is identical
does **not** regenerate `config.json`; only the rule-set data is re-applied per B-3/B-4.

**B-8** When the sing-box service is not running, no run starts it, whatever changed. `sc off`
semantics are preserved.

**B-9** When `/etc/sing-box/config.json` does not exist (fresh install, `install.sh` step 6), the
run creates no config and performs no service-affecting action, whatever changed.

**B-10** Every run states, on stdout, exactly one truthful run-level outcome from this closed set,
in the active language: (a) no rule-set changed and the service was not touched; (b) rule-sets
changed and the service was restarted; (c) rule-sets changed and were applied without restarting
the service — (c) exists only if B-4 resolves to a non-disruptive mechanism. The existing
`Done` line is retained.

**B-11** Every string added by this change ships in both English and Simplified Chinese in
`TRANSLATIONS["zh"]`. No zh string added by this change contains the substring `失败：`.

**B-12** Behavior is identical on systemd hosts and OpenRC hosts, and identical whether the run
is interactive (a terminal) or scheduled (timer / periodic script, output redirected).

**B-13** All existing per-file download reporting is unchanged: one completion line per rule-set
on a non-TTY, TTY progress redraws, per-file causes on stdout, the aggregate failure count on
stderr, and a non-zero exit status when at least one rule-set failed to update.

**B-14** Changes that were successfully installed before a later rule-set failed are still
applied before the run exits non-zero (the ordering T-02 established for the recovery path).

**B-15** The change/no-change determination consumes the existing rule-set state machinery
(`ruleset_report` / `ruleset_status` / `usable_tags` / `srs_reject_reason`). No second opinion of
"what is on disk" is introduced.

**B-16** User-facing documentation that asserts `sc update-rules` restarts sing-box is corrected
in the same change (at minimum `CHANGELOG.md:15`, E-10), and a `CHANGELOG.md` entry describing
this fix is added.

---

## 5. Out of scope

1. `install.sh`, `uninstall.sh`, `systemd/*`, `/etc/periodic/*` script content — not modified.
2. The mirror list, mirror-fallback logic, validation rules, size floor, `--mirror` /
   `SB_RULES_BASE` handling, download progress rendering, temp-file naming and stale-temp
   cleanup — not modified.
3. Any timeout constant — not modified in value.
4. `sc doctor` (T-05), `sc config --show` (T-06), the restricted-network end-to-end verification
   and the committed test harness (T-07).
5. The six follow-up rows recorded under "Follow-up rows surfaced by T-02" in `docs/tasks.md`
   (Python-floor violations, missing `en` table, `--mirror` scheme allow-list, D-4 local-disk-fault
   attribution, D-5 stray blank line, `_temp_path` prefix coupling) — none is a precondition here.
   Exception: if this change touches a line carrying one of those defects, it must not *worsen* it.
6. Regenerating the config when a rule-set is *lost* (usable → unusable) during a run — T-02's
   asymmetric `gained`-only rule is preserved (see D-4 in §10).
7. Changing the update cadence, adding a `--force` / `--no-restart` flag, or adding an "apply now"
   subcommand.

---

## 6. Boundary conditions

| # | Condition | Required behavior |
|---|---|---|
| BC-1 | All four rule-sets re-download successfully with byte-identical content (the common case, E-13) | No service-affecting action; run-level outcome (a); exit 0 |
| BC-2 | One rule-set's new body differs; three identical | Apply per B-3/B-4; the report names the changed rule-set |
| BC-3 | New body differs from the old body but has the same byte size | Counted as content-changed (size alone is not the signal) |
| BC-4 | Rule-set absent before the run, downloaded successfully | Content-changed **and** gained: config regenerated (B-6) and applied |
| BC-5 | Rule-set present but rejected as unusable before the run (bad magic / too small), replaced by a valid body | Content-changed and gained; as BC-4 |
| BC-6 | Rule-set unreadable before the run (EPERM, dangling symlink, directory in its place) and the run installs a valid body over it | Counted as content-changed. Reading the pre-state never raises and never aborts the run |
| BC-7 | Rule-set unreadable before the run and the run installs nothing for it | Not content-changed; no service-affecting action results from this file |
| BC-8 | Every mirror fails for every rule-set | No file is modified ⇒ nothing content-changed ⇒ no service-affecting action; existing per-file causes on stdout, aggregate on stderr, non-zero exit |
| BC-9 | Two rule-sets succeed and change, two fail on all mirrors | The two changed ones are applied, then the run exits non-zero (B-14) |
| BC-10 | Service stopped (`sc off`) and rule-sets changed | Files installed; no start, no restart; the run-level outcome states the service was not touched |
| BC-11 | No `config.json` yet (fresh install, E-5) | No config created, no service-affecting action, exit status governed only by download outcomes |
| BC-12 | Re-run of `install.sh` on a host whose rule-sets are current | Step 6 performs no service-affecting action; step 7's `sc reload` continues to behave exactly as today |
| BC-13 | Rule-set file deleted by an external actor between the pre-run observation and the post-run observation, and not re-installed by this run | Treated as not content-changed by this run; the run does not crash. (Config regeneration on loss is out of scope, §5.6) |
| BC-14 | A concurrent run (timer + manual) replaces a file between this run's two observations | Each run reports what it itself observed; at most one redundant apply results. No crash, no corrupted file (pid-scoped temps already guarantee this) |
| BC-15 | Rule-set file large (hundreds of KiB to a few MiB) | Change detection reads each file in bounded chunks; memory use does not scale with file size |
| BC-16 | Zero rule-sets to process (empty rule-set list) | No crash, no service-affecting action |
| BC-17 | Local disk fault (ENOSPC, `replace()` EPERM) prevents installing a downloaded body | That rule-set is not content-changed; existing failure reporting applies |
| BC-18 | The service is running but the non-disruptive apply mechanism is unreachable (API port drift, process wedged) | B-5 fallback: restart and say so |
| BC-19 | `sc update-rules --mirror <base>` where the alternate mirror serves identical bytes | Not content-changed (E-13); no service-affecting action |
| BC-20 | Run in language `zh`, and run in language `en` | Every run-level outcome line and every new message renders in the active language, with no untranslated English key visible in `zh` |

---

## 7. Acceptance criteria

Each criterion is verified against fixtures / stubs only (see NFR-1).

| # | Criterion | How it is verified |
|---|---|---|
| AC-1 | A run in which all rule-sets are re-fetched with identical bytes invokes no restart, no reload, no start, no stop | Stubbed service layer records zero invocations |
| AC-2 | The same run leaves `config.json` byte-identical (no regeneration) | File digest before / after |
| AC-3 | The same run exits 0 and prints the "nothing changed / service untouched" outcome exactly once | Exit status + stdout capture |
| AC-4 | A run in which one rule-set body differs performs exactly one apply action for the run (not one per changed file) | Stub invocation count == 1 |
| AC-5 | A run in which one rule-set body differs but its size is unchanged is detected as changed | Fixture with equal-size, different-content bodies |
| AC-6 | Change detection ignores modification time: touching a file's mtime without changing bytes yields "unchanged" | Fixture sets mtime, asserts no apply |
| AC-7 | A rule-set that goes absent → usable regenerates the config and applies it, and prints the existing "Rule-sets restored: {names} — config regenerated" message | T-02 regression fixture, re-run unchanged |
| AC-8 | A rule-set that goes bad-magic → usable behaves as AC-7 | Fixture |
| AC-9 | With the service stopped, no changed-rule-set run starts it | Stub `is_running()` False; assert zero service invocations |
| AC-10 | With no `config.json` present, no config is created and no service action occurs, whatever changed | Fixture without `config.json` |
| AC-11 | With all mirrors failing, no service action occurs and the exit status is non-zero with the existing aggregate message on stderr | Fixture with unreachable bases |
| AC-12 | With two rule-sets changed and two failed, the apply happens **before** the non-zero exit | Ordered stub call log |
| AC-13 | Pre-state observation of an unreadable / missing / directory-shaped rule-set path never raises | Direct call on each fixture shape |
| AC-14 | Every message key added by this change has a `zh` entry; running the whole command in `zh` produces no untranslated added key | Assertion over `TRANSLATIONS["zh"]` + `zh` run capture |
| AC-15 | No zh string added by this change contains `失败：` | Assertion over the added keys (E-15) |
| AC-16 | Non-TTY output still emits exactly one completion line per rule-set and contains no `\r` | Piped-output capture (T-02 AC-15 regression) |
| AC-17 | TTY progress redraw behavior and per-file cause reporting are unchanged | T-02 regression fixtures re-run |
| AC-18 | Whichever apply mechanism B-4 resolves to, the run-level outcome line states what actually happened, and the "restarted" wording is absent from every run in which no restart was issued | Stub log cross-checked against stdout |
| AC-19 | When the non-disruptive mechanism is attempted and fails, the run restarts and reports the restart | Stub that rejects the non-disruptive call. *(Not applicable if B-4 resolves to restart-only; record that as the reason.)* |
| AC-20 | `bin/sc` compiles under the project gate and `.harness/scripts/verify_all` reports no new WARN / FAIL against a pristine `HEAD` baseline | `verify_all` run + delta against baseline |
| AC-21 | `bin/sc` uses no syntax newer than Python 3.6 in the lines this change adds, and only the standard library | Inspection + `python3 -m py_compile`; no new import outside stdlib |
| AC-22 | The shipping diff touches only `bin/sc` and `CHANGELOG.md` | `git diff --stat` |
| AC-23 | `CHANGELOG.md:15`'s claim that the update command restarts sing-box is corrected, and a new entry describes this fix | Diff inspection (E-10, B-16) |
| AC-24 | `systemctl is-active sing-box` reports the same state before and after the entire verification run, and the report states the two readings | Recorded in `06_TEST_REPORT.md` (NFR-1) |
| AC-25 | No second on-disk rule-set judgment is introduced: removing the existing rule-set state functions breaks the new code path too | Structural deletion test (T-02 precedent) |

---

## 8. Non-functional requirements

**NFR-1 — Test safety (binding on stages 3, 4, 5 and 6; MANDATORY).** This task changes restart
behavior, so an un-neutralised test import can drop the owner's live connections — this happened
during T-02 (E-14).

1. The import-time auto-elevate block (`bin/sc:77-78`) is neutralised in **every** harness **and**
   in every developer/QA throwaway or scratch script. The T-02 gap was scratch scripts, not the
   committed harness.
2. `restart_service()`, and any reload / apply path this change introduces, is **never** invoked
   against the live system. Verification uses fixtures and stubs only.
3. No verification step invokes `systemctl restart|start|stop sing-box`, `rc-service sing-box …`,
   `systemctl start sing-box-rules-update.service`, or the installed `/usr/local/bin/sc`.
4. `systemctl is-active sing-box` reads the same value before and after any test run; each agent
   that runs verification checks it and states both readings in its stage document (AC-24).
5. Rule-set fixtures live under a temp directory; `/etc/sing-box/**` is never written during
   verification.

**NFR-2 — Compatibility.** Python 3.6+ syntax floor, standard library only (`.harness/rules/50`).
Both init systems (systemd, OpenRC) and both languages (`en`, `zh`) are supported by the same code
path.

**NFR-3 — Cost of the check.** Change detection adds no network request and no new timeout. It
reads each managed rule-set file at most twice per run (once before, once after) in bounded
chunks. Four files of a few hundred KiB each is the working set.

**NFR-4 — Observability.** The existing stream contract is preserved: per-file causes on stdout,
aggregate failure count on stderr (`.harness/insight-index.md:11`), one completion line per
rule-set on a non-TTY. The new run-level outcome line is a run-level line (like `Done`), not a
per-file line, so the timer's journal and `/var/log/sing-box/install.log` record what the run did.

**NFR-5 — Security / privilege.** No new privilege, no sudoers change, no file-mode change, no new
network endpoint. Any apply mechanism used stays loopback-only, as the existing Clash API client is
(E-8).

---

## 9. Related tasks

- **T-02 `config-degrade-missing-rulesets`** (`ab4e4a4`) — owns the rule-set usability judgment and
  the `gained` / `applied` recovery path this task must preserve and reuse.
  `docs/features/_archived/config-degrade-missing-rulesets/01_REQUIREMENT_ANALYSIS.md` (B-17,
  BC-26 … BC-29) and `02_SOLUTION_DESIGN.md` §5.3, §6.2 (the hot-apply conclusion, E-7).
- **T-09 `fix-rules-update-execstart`** (`0bb2373`) — made the weekly timer able to run, which
  turns this latent defect into a weekly connection drop.
  `docs/features/_archived/fix-rules-update-execstart/01_REQUIREMENT_ANALYSIS.md`.
- **T-01 `install-enable-start-split`** (`493eb6a`) — owns `install.sh`'s consumption of
  `sc update-rules` output (`/var/log/sing-box/install.log`); constrains NFR-4.
- **T-07** (not yet filed) — owns the committed test harness; see D-8.
- `.harness/rejected-decisions.md` — checked. No prior decline covers this request. The records
  `mirror-fallback-cause-on-its-own-line-or-on-stderr` (output-shape constraints) and
  `ruleset-unit-tests-in-t02` (no committed test tree yet) constrain how this task ships.

---

## 10. Decisions taken under standing authority

Deferred-human mode is active (`defer, do not ask`). Each item below is a question that would
otherwise have gone to the user; each is resolved here against `.harness/decision-rubric.md` and
is a **conditional escalation** the gate reviewer may challenge.

**D-1 — Apply mechanism: restart, or hot-apply?**
Candidates: (a) restart only, honestly reported; (b) attempt a non-disruptive apply, fall back to
restart; (c) assert hot-apply works without demonstrating it.
**Recommended / adopted: (b), gated on evidence — with (a) as the mandatory fallback.** Stage 2
must establish, for the sing-box version this project installs, whether a mechanism exists that
makes changed rule-set data effective without terminating connections, and record the evidence. If
no such mechanism is demonstrated, B-4 resolves to (a) and AC-19 is recorded as not-applicable with
that reason. (c) is forbidden — a wrong "reload works" claim is worse than an honest restart.
*Rubric basis:* honest reporting; prior art E-7 concluded hot-apply is unavailable for structural
rule-set changes, so (a) is the likely outcome and the requirement must not depend on (b).
*Why this is acceptable either way:* with B-1/B-2 in place the restart is reached only when the
rule-set data really changed, which E-13 says is rare — the weekly no-op drop disappears under
either resolution.

**D-2 — Are `gained` and `content-changed` one concept or two?**
Candidates: (a) one flag covering both; (b) two distinct facts about each rule-set, produced by one
query over the same on-disk state.
**Recommended / adopted: (b).** They drive different consequences: `gained` changes what
`config.json` *contains* (so it regenerates), `content-changed` changes only the data sing-box
loaded (so the config is untouched and only the apply happens). Collapsing them either regenerates
the config needlessly on every content change or loses T-02's recovery. Stage 2 owns the
representation, subject to B-15 (one on-disk opinion, extended — never duplicated).
*Rubric basis:* sound engineering / maintainability; rule 85 duplicated-judgment test.

**D-3 — Change signal: digest, or retained bytes?**
Candidates: (a) a stdlib content digest of each file before and after; (b) keep the pre-run bytes
in memory and compare; (c) size + mtime.
**Recommended / adopted: (a) or (b), architect's choice; (c) is forbidden by B-1.** Both (a) and
(b) are exact for our purposes; (a) has bounded memory (NFR-3, BC-15). Recorded as a decline in
`.harness/rejected-decisions.md` so mtime/size is not re-proposed later.
*Rubric basis:* correctness first; reversible implementation detail delegated to stage 2.

**D-4 — Should a rule-set *lost* during a run regenerate the config?**
Candidates: (a) keep T-02's asymmetric `gained`-only rule; (b) regenerate on any usable-set change
in either direction.
**Recommended / adopted: (a).** A file can only be lost mid-run through an external actor
(installation happens only after validation), and (b) would let a transient external event
regenerate a *degraded* config that drops routing rules. Out of scope (§5.6).
*Rubric basis:* no scope expansion; least-surprise for the user.

**D-5 — Does a "nothing changed" line print on the scheduled (non-TTY) path?**
Candidates: (a) print it always; (b) print it only on a TTY.
**Recommended / adopted: (a).** The timer journal and `install.log` are the only record a
scheduled run leaves; a silent run is indistinguishable from a broken one. It is a run-level line,
so the one-completion-line-per-rule-set contract (T-02 B-19) is untouched.
*Rubric basis:* honest reporting; observability NFR-4.

**D-6 — Exit status when nothing changed.**
Candidates: (a) 0; (b) a distinct status meaning "no-op".
**Recommended / adopted: (a).** `install.sh:456` branches on this exit status and would report a
successful no-op run as a ruleset failure under (b).
*Rubric basis:* match existing conventions; do not break a documented consumer.

**D-7 — Keep the existing `→ Restarting sing-box ...` message?**
Candidates: (a) keep it for the restart path and add new keys for the other outcomes; (b) replace
it wholesale.
**Recommended / adopted: (a).** It is already translated and already correct for the case it
describes; replacing it churns the diff and the T-02 output fixtures for no user benefit.
*Rubric basis:* match existing conventions; minimal diff.

**D-8 — Does this task commit a test tree (`verify_all` B.2 currently SKIP)?**
Candidates: (a) commit a harness now; (b) keep the harness in the scratchpad, paste it into
`06_TEST_REPORT.md`, leave B.2 for T-07.
**Recommended / adopted: (b).** Consistent with the existing decline record
`ruleset-unit-tests-in-t02` and with AC-22's diff boundary. Origin appended to that record rather
than opening a second one. **This is the weakest of the eight decisions** — a gate reviewer who
judges that restart-behavior verification must be permanently reproducible can overrule it, at the
cost of widening AC-22.
*Rubric basis:* no scope expansion; prior decision on record.

**D-9 — Is `CHANGELOG.md` inside the "`bin/sc` only" boundary?**
Candidates: (a) `bin/sc` strictly; (b) `bin/sc` + `CHANGELOG.md`.
**Recommended / adopted: (b).** `CHANGELOG.md:15` currently tells users that this command restarts
sing-box (E-10); shipping the fix while leaving that text in place publishes a false statement.
T-09 shipped the same two-file shape. READMEs were checked and need no change.
*Rubric basis:* honest reporting outranks a diff-size preference.

No item reached a red line in `.harness/rules/25-decision-policy.md`; no `BLOCKED: NEEDS-HUMAN`
marker is raised.

---

## 11. Open questions for the user

None outstanding — all nine judgment calls are resolved in §10 under standing authority, each with
its candidates and the adopted answer, and each is challengeable at the stage-3 gate. The one that
most deserves a second opinion is **D-8** (no committed test tree for a change to restart
behavior); the one that stage 2 must *close with evidence rather than judgment* is **D-1** (whether
a non-disruptive apply exists for the installed sing-box version).

---

## 12. Verdict

**READY.**

Stage 2 (Solution Architect) is additionally bound to:
1. Close D-1 with demonstrated evidence about the installed sing-box version, and to write down
   what was demonstrated — not what is plausible (B-4).
2. Honour B-15: extend the existing rule-set state query; do not create a second opinion of what
   is on disk.
3. Carry NFR-1 verbatim into the design's risk table, and restate it in the developer and QA
   dispatch prompts.
