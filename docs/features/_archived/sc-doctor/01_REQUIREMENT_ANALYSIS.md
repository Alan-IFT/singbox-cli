# 01 — Requirement Analysis — `sc-doctor` (T-05)

Mode: **full** · Stage 1 · Decision mode: **deferred-human (defer, do not ask)** — every ambiguity is
resolved here, with evidence, in §8. No open questions are routed to the owner.

---

## 1. Goal

`sc doctor` prints, in one pass and one screen, the seven facts a broken singbox-cli install is
diagnosed from — binary, rule-sets, config validity, service state, TUN interface, Clash API,
egress IP — ordered so that the cause of a failure is printed above every effect it produced,
without changing anything on the machine.

The failure chain it must make readable at a glance (owner's post-mortem):
four `.srs` downloads timed out → rules directory empty → the generated config referenced missing
local rule-sets → `sing-box check` FATAL → service dead → no autostart. Today that diagnosis costs
three hand-typed `grep`s and two `systemctl` invocations.

---

## 2. In-scope behaviours (functional requirements)

Vocabulary used below is `CONTEXT.md`'s: **rule-set**, **usable rule-set**, **service-affecting
action**, **non-TTY output contract**.

### 2.1 The command

- **FR-1** — A new subcommand `doctor` is reachable as `sc doctor`, dispatched through the same
  argparse subparser + `handlers` mechanism as every other subcommand, and takes no arguments.
- **FR-2** — `doctor` appears in both help blocks (`HELP_EN`, `HELP_ZH`) and in both READMEs
  (`README.md`, `README.zh-CN.md`), which stay line-for-line mirrors of each other.
- **FR-3** — A `sc doctor` run performs **no service-affecting action**: it does not start, stop,
  restart, reload, enable or disable the service, and does not instruct the running process to
  re-read anything.
- **FR-4** — A `sc doctor` run creates, modifies, deletes, renames or truncates **no file**: not
  `config.json`, not `nodes.json`, not `settings.json`, not any `.srs`, not any directory under
  `/etc/sing-box` or `/var/lib/sing-box`. This includes writes performed by the process's own
  start-up path before the subcommand's own code runs (see §8 R-1).
- **FR-5** — `doctor` produces a complete report when the service is stopped, when the service has
  never been installed, when `config.json` is absent, when `config.json` is present but invalid,
  and when the `sing-box` binary is not on `PATH`. None of these is an early exit.

### 2.2 Report content and order

- **FR-6** — The report consists of exactly these seven sections, printed in exactly this order:

  | # | Section | Facts printed |
  |---|---|---|
  | S1 | sing-box binary | resolved absolute path of the binary, and its version string |
  | S2 | Rule-sets | one row per entry of the project's fixed rule-set list, in that list's order: filename, usability status, byte size |
  | S3 | Configuration | whether `config.json` exists, and the result of the sing-box configuration check on it |
  | S4 | Service | whether the service is running now, and whether it is registered to start at boot; plus which init system was detected |
  | S5 | TUN interface | whether the project's TUN interface exists, and its addresses |
  | S6 | Clash API | the port the report can determine, and whether that port answers |
  | S7 | Egress IP | the observed public egress address |

- **FR-7** — **Causal order is a binding property, defined as follows.** The dependency relation
  between sections is: S1→S3, S2→S3, S1→S4, S3→S4, S4→S5, S4→S6, S5→S7, S6→S7 (read `X→Y` as *a
  failure in X is a sufficient cause of a failure in Y*). The print order is a topological order of
  that relation: no section is printed before a section it depends on. FR-6's table **is** the chosen
  topological order and is the pinned, reviewable artefact.
- **FR-8** — Each section reports exactly one of three outcome classes, distinguishable by a reader
  and by a `grep`:
  1. **OK** — the probe ran and the fact is healthy;
  2. **PROBLEM** — the probe ran and the fact is unhealthy, accompanied by the specific cause;
  3. **UNKNOWN** — the probe could not run at all (tool missing, permission denied, prerequisite
     absent), accompanied by why it could not run.
  A prerequisite failure never renders as class 2 in a dependent section: the binary being absent
  makes S3's check **UNKNOWN**, not "config invalid".
- **FR-9** — No single failing probe ends the run. Every section is attempted and printed regardless
  of the outcome of every other section; an unexpected exception inside one probe becomes that
  section's UNKNOWN row and nothing more.
- **FR-10** — Sections are **streamed**: every section is written and flushed to stdout before the
  next section's probe begins. A run interrupted (Ctrl-C, kill, hung network probe) leaves every
  already-determined section on stdout.
- **FR-11** — S2 reports, for every rule-set, the status vocabulary already defined by the project —
  `usable` / `absent` / `bad-magic` / `too-small` / `unreadable` — rendered through the project's
  existing bilingual status renderer. `doctor` introduces no new status word and no second notion of
  "present".
- **FR-12** — S2's byte size is the byte count produced by the **same single read** that decided the
  status. `os.stat`/`st_size` is not an admissible source. Size is reported exactly when a complete
  read happened (i.e. exactly when the existing reader's digest contract yields a digest); for
  `absent` and `unreadable` the size field reads as not-available rather than `0`.
- **FR-13** — S3 distinguishes three cases: config file absent; config file present and the check
  passed; config file present and the check failed — the last carrying the checker's own message
  (see BC-7 for the length bound).
- **FR-14** — S4 reports "running now" and "starts at boot" as two separate facts, on both supported
  init systems, and reports UNKNOWN for both when neither init system is detected.
- **FR-15** — S6's port is taken from persisted settings; when no port is persisted, S6 reports the
  port as not-configured and the reachability probe as UNKNOWN. `doctor` never probes for a free
  port and never invents a port to test (see §8 R-2).
- **FR-16** — S7 runs unconditionally — including when the service is down, which is the case where
  its value is most diagnostic. `doctor` reports the observed address or the failure cause; it makes
  no claim about whether the address is proxied.

### 2.3 Reuse (load-bearing — rule 85 §"Duplicated judgment")

- **FR-17** — `doctor` forms **no second opinion** about any fact the codebase already decides. It
  consumes the existing definitions of: rule-set usability and per-file state; the per-rule-set
  report; the service-running check; the Clash API client; the egress-IP query; the sing-box binary
  reference; the config, rules and settings paths; the init-system detection; the bilingual status
  renderer. A duplicate implementation of any of these is a defect, not an optimisation.
- **FR-18** — The TUN interface name, the egress-IP endpoint and the Clash API port source each
  exist as **one** definition in `bin/sc` after this task. Today the interface name and the endpoint
  are literals inside one function each; `doctor` needing them a second time makes a single named
  definition mandatory, not optional.
- **FR-19** — `sc status`'s output is unchanged, byte for byte, in both languages — whether or not
  its internals are refactored to consume the definitions FR-18 introduces.

### 2.4 Output form

- **FR-20** — One fact per physical line, in `label` + separator + `value` form, so any single row
  can be quoted or grepped on its own.
- **FR-21** — When stdout is not a terminal, the output contains no carriage return (`\r`) and no
  ESC (`0x1B`) byte — the project's **non-TTY output contract**. Colour and terminal-only decoration
  are permitted on a terminal and are not required anywhere.
- **FR-22** — Alignment, if used, is by literal spaces and never changes the parsed content of a
  row. `doctor` adds no padding that pushes a fixed row past 80 columns; naturally long values (an
  error message, an address) are printed unabridged.

### 2.5 Bilingual

- **FR-23** — Every user-facing string `doctor` introduces is an English sentence used as the
  translation key, with a `zh` entry carrying the *same* placeholder set. Namespaced keys
  (`ls.idx`-style) are forbidden — in English `t()` returns the key verbatim.
- **FR-24** — No string `doctor` emits in zh collides with the load-bearing diagnostic literal
  produced by the existing `failed: {e}` key, whose zh rendering means "this rule-set file was not
  updated" and is grepped from captured `sc update-rules` output.

### 2.6 Exit status

The *choice* of mapping belongs to stage 2. The following constraints on it are binding here.

- **FR-25** — The exit status is a deterministic pure function of the findings printed. Identical
  findings ⇒ identical status, independently of language, of TTY-ness, of init system, and of the
  order in which probes happened to fail.
- **FR-26** — The full report is printed before the process exits; the exit status never truncates
  the report.
- **FR-27** — `doctor` never terminates through an uncaught exception, so an interpreter traceback
  and its status are never a `doctor` outcome.
- **FR-28** — The set of possible statuses is enumerated, finite (at most three distinct values), and
  each value's meaning is documented in both help blocks and both READMEs, naming which sections can
  produce it — a script author must be able to predict the status from the report.
- **FR-29** — Stage 2 records the chosen mapping and its rationale in `02_SOLUTION_DESIGN.md`. The
  two candidate policies, with the trade-off the owner named: **(a) always 0** — a diagnostic that
  never surprises a shell, at the cost of being useless as a health check; **(b) 0 = all sections OK,
  non-zero = at least one PROBLEM** — usable as a health check, at the cost of a non-zero status from
  a command that "only printed something".

### 2.7 Documentation

- **FR-30** — `CHANGELOG.md` gains one entry under `[Unreleased] → 新增` (zh, per project
  convention).
- **FR-31** — `docs/dev-map.md` is updated if and only if this task changes the reusable-utility
  inventory it documents (per FR-12's size source and FR-18's single definitions).

---

## 3. Out of scope

1. Any repair, regeneration, download, restart, enable or fix — `doctor` diagnoses only (FR-3/FR-4).
2. `install.sh` (T-01/T-08/T-11), `uninstall.sh`, and `systemd/` (T-09) — not touched.
3. The rule-set download path and the config-degradation logic (T-02/T-10) — called into, never
   modified beyond what FR-12 requires of the existing on-disk reader.
4. `sc config --show` — that is pool row T-06.
5. Any change to a timeout constant (Clash API 3 s, egress IP 8 s, ruleset download 30 s). Reachability
   is fixed with mirrors, not with longer waits.
6. Any change to the auto-elevate model.
7. The three pre-existing `capture_output=` sites (3.7+ on a 3.6+ floor) — a separate filed row. Not
   fixed here, and no new occurrence introduced.
8. Machine-readable output (`--json`), a `--quiet` flag, per-section selection flags, remediation
   suggestions, historical trending, log excerpts. Nobody asked; rule 85's counter-rule applies.
9. Changing `sc status` behaviour or output (FR-19).
10. Verifying that the egress address is actually flowing through the proxy.

---

## 4. Boundary conditions

- **BC-1 — no sing-box binary.** `SB_BIN` does not resolve on `PATH`: S1 = PROBLEM ("not found"),
  S3's check = UNKNOWN (no checker), S4..S7 still printed.
- **BC-2 — empty rules directory.** All four rule-sets `absent`: four PROBLEM rows with size
  not-available. This is the head of the owner's failure chain and must be visible above S3.
- **BC-3 — rules directory itself absent** (fresh or destroyed install): identical to BC-2; `doctor`
  does not create it.
- **BC-4 — a rule-set that is a directory, a FIFO, a dangling symlink, a zero-byte file, an HTML
  error page, or a truncated body**: each maps onto the existing status vocabulary
  (`unreadable` / `too-small` / `bad-magic`) with no new judgment.
- **BC-5 — an oversized `.srs`.** The existing reader is chunked, so memory stays bounded, but
  runtime is proportional to the bytes on disk. Accepted: an absurdly large file makes S2 slow, not
  wrong. `st_size` is still not admissible (FR-12).
- **BC-6 — `config.json` absent / unreadable (EACCES) / present-but-not-JSON.** Three distinct rows:
  absent = PROBLEM "no config"; EACCES = UNKNOWN "cannot read"; malformed = PROBLEM with the
  checker's cause. A permission failure is never rendered as absence.
- **BC-7 — a multi-line checker message.** The first line is always printed. At most five lines are
  printed; if more exist, the remainder is elided with a marker stating how many lines were dropped.
- **BC-8 — neither systemd nor OpenRC present.** S4 = UNKNOWN for both facts, naming that no init
  system was detected. S5..S7 still run.
- **BC-9 — the `ip` tool (or any external tool a probe shells out to) is missing.** That section =
  UNKNOWN; no traceback, no abort (FR-9).
- **BC-10 — the TUN interface does not exist.** S5 = PROBLEM, distinct from BC-9's UNKNOWN.
- **BC-11 — no Clash API port persisted** (e.g. an install predating port auto-probing): FR-15.
- **BC-12 — the Clash API port is persisted but the service is down**: S6 = PROBLEM "no answer"
  after the existing 3 s timeout, not UNKNOWN.
- **BC-13 — no network / blackholed network.** S7 = PROBLEM with the cause, after the existing 8 s
  timeout. See NFR-2 for the honest ceiling: name resolution is not covered by that timeout.
- **BC-14 — output redirected to a file or a pipe** (the bug-report path): FR-21 holds.
- **BC-15 — concurrent `sc update-rules` while `doctor` reads.** `doctor` may observe a rule-set
  mid-replacement; the existing reader yields a well-defined status for whatever it reads, and
  `doctor` reports that status. `doctor` never blocks, never locks, and never retries.
- **BC-16 — two concurrent `sc doctor` runs.** Both complete with identical behaviour; being
  read-only, they cannot interfere.
- **BC-17 — running from a source checkout as a non-root user.** The existing auto-elevate re-execs
  the *installed* `/usr/local/bin/sc`, so `./bin/sc doctor` diagnoses via the installed tool. `doctor`
  neither changes nor documents around this; it is the standing project behaviour.
- **BC-18 — `LANG` = zh.** Every row of every section renders in Chinese (FR-23), including all
  three outcome classes.

---

## 5. Acceptance criteria

Each is PASS/FAIL by inspection or by execution.

- **AC-1** — `sc doctor` exists and runs: it is registered in the subparser set and in the handler
  dict, and `sc doctor` prints a report rather than the help text.
- **AC-2** — `sc help` in **both** languages lists `doctor`, and both READMEs document it. A diff of
  the two READMEs' structure shows the same insertion point.
- **AC-3 (causal order — falsifiable)** — The report's section order is exactly S1, S2, S3, S4, S5,
  S6, S7 as tabulated in FR-6. A reviewer reads the output top to bottom and checks that (a) the
  seven section labels appear in that order, (b) each appears exactly once, and (c) for every pair
  `X→Y` in FR-7's relation, X's label precedes Y's. Any transposition — for instance printing the
  configuration check above the rule-set rows — is a FAIL.
- **AC-4 (the owner's failure chain reads off the screen)** — On a fixture with an empty rules
  directory, a `config.json` referencing the four missing rule-sets, and a stopped service, a single
  `sc doctor` run prints, in this order and with no other command being run: four rule-set PROBLEM
  rows (S2), a failed configuration check naming the rule-set problem (S3), a not-running service and
  a not-enabled-at-boot fact (S4). The reviewer can name the root cause from the screen alone.
- **AC-5 (read-only — files)** — Snapshot every path under `/etc/sing-box` and `/var/lib/sing-box`
  (existence, size, mtime, sha256, mode) before and after a `sc doctor` run; the two snapshots are
  identical. Repeat on a host where `/etc/sing-box` does **not** exist: it still does not exist
  afterwards, and neither does `/var/lib/sing-box`.
- **AC-6 (read-only — service)** — `systemctl show -p MainPID -p ActiveEnterTimestamp sing-box`
  before and after a `sc doctor` run returns identical values. (`is-active` is not admissible
  evidence — it reads `active` on both sides of a restart.)
- **AC-7 (read-only — code)** — Every subprocess `doctor` invokes and every file operation it
  performs is enumerated in the review, and each is read-only. No call to the config generator, the
  restart helper, the reload helper, the downloader, or any settings/nodes writer appears in
  `doctor`'s reachable call graph.
- **AC-8 (no probe kills the report)** — For each of the seven sections independently, force that
  section's probe to fail (binary renamed away; rules directory emptied; config removed; service
  stopped; TUN interface absent; Clash port unreachable; network blackholed) and confirm all seven
  section labels are still printed and the process still terminates normally. Seven runs, seven
  PASSes.
- **AC-9 (dead service does not suppress rule-set rows)** — With the service stopped, all four
  rule-set rows are printed. This is AC-8's most load-bearing instance and is asserted separately.
- **AC-10 (invalid config does not suppress anything)** — With a syntactically invalid
  `config.json`, all seven sections are printed and the run terminates normally.
- **AC-11 (three outcome classes)** — Each section's row is machine-classifiable into OK / PROBLEM /
  UNKNOWN, and the class markers are drawn from a fixed, documented set. A prerequisite failure
  produces UNKNOWN in dependent sections: with the binary absent, S3 is UNKNOWN and not "config
  invalid".
- **AC-12 (streaming)** — Interrupt the run during the S7 probe (blackholed network + SIGINT after
  S6 is printed): S1..S6 are already on stdout.
- **AC-13 (rule-set reuse)** — `doctor` obtains rule-set facts through the existing per-rule-set
  report/state functions. Deletion test: removing the existing rule-set report function breaks
  `doctor`'s S2 at import/definition time rather than leaving `doctor` working through an
  independent path.
- **AC-14 (no `st_size`)** — `doctor`'s reachable call graph contains no `stat`/`st_size`/`getsize`
  read of a `.srs` file; the size printed is the byte count from the read that also decided the
  status. Verified by inspection plus this behavioural check: a file whose apparent length and read
  length can differ is reported by read length.
- **AC-15 (single definitions)** — The TUN interface name literal, the egress-IP endpoint literal,
  and the Clash-API-port source each occur exactly once in `bin/sc` after this task. A repository
  search for each yields one definition plus references.
- **AC-16 (`sc status` unchanged)** — `sc status` output captured before and after the change, in
  both languages, on the same machine state, is byte-identical.
- **AC-17 (non-TTY purity)** — `sc doctor > out.txt 2>&1` on a host in every state exercised by AC-8
  produces a file containing zero `0x0D` and zero `0x1B` bytes.
- **AC-18 (bilingual coverage)** — Every new translation key introduced by this task is listed in the
  review, and for each: a `zh` entry exists, and the placeholder set of the `zh` value equals the
  placeholder set of the English key exactly. Executed check: run `sc doctor` under `lang zh` and
  confirm no line is the untranslated English key.
- **AC-19 (no namespaced keys)** — No key introduced by this task is an identifier-style token; every
  key is readable English prose, because in English `t()` returns the key itself.
- **AC-20 (no grep-literal collision)** — Under `lang zh`, no line of `sc doctor` output equals or
  contains the zh rendering of the existing `failed: {e}` key. Verified by rendering that key at run
  time and searching `doctor`'s zh output for it — **not** by a repository-wide search for the
  literal, which would be self-violating (a criterion of the form "this literal appears nowhere in
  the repository" is falsified by the document stating it).
- **AC-21 (exit status)** — The chosen mapping is documented in both help blocks and both READMEs;
  running `sc doctor` twice against identical machine state yields the same status; the status is
  identical between `lang en` and `lang zh` and between TTY and redirected stdout; at most three
  distinct values exist; and in every AC-8 scenario the full report precedes the exit.
- **AC-22 (no traceback)** — In every AC-8 scenario, stderr contains no Python traceback.
- **AC-23 (Python floor)** — `bin/sc` remains parseable by a 3.6 syntax check, and this task's diff
  introduces no `capture_output=`, no `text=`, no walrus, no f-string `=` specifier, no
  `unlink(missing_ok=)`, and no `dataclasses`.
- **AC-24 (screen budget)** — In the all-probes-complete case the report is at most 25 physical
  lines, and no line is padded by `doctor` beyond 80 columns.
- **AC-25 (gate)** — `.harness/scripts/verify_all` PASS, with the delta against a pristine `HEAD`
  **clone** (not a worktree — a worktree's `.git` is a file and silently turns A.1/A.2 into SKIP)
  limited to the steps this task's diff predicts.
- **AC-26 (scope)** — The shipping diff touches only `bin/sc`, `README.md`, `README.zh-CN.md`,
  `CHANGELOG.md` and (per FR-31) `docs/dev-map.md`. `install.sh`, `uninstall.sh` and `systemd/` are
  byte-identical.

---

## 6. Non-functional requirements

- **NFR-1 (safety)** — `doctor` is the command people run when the machine is already broken. It
  must be safe to run repeatedly, concurrently, and as the first thing after a failure. FR-3/FR-4 and
  AC-5..AC-7 carry this.
- **NFR-2 (bounded runtime, stated honestly)** — `doctor` adds no new blocking operation without a
  bound and introduces no new timeout constant. The worst case is the sum of the existing per-probe
  bounds (Clash API 3 s + egress 8 s + the local subprocesses). **Name resolution is not covered by
  the socket timeout** — a host with an unreachable DNS server can exceed that sum in S7. FR-10's
  streaming is what makes this acceptable: the other six sections are already on screen. Stage 2
  records the ceiling it claims; QA measures it.
- **NFR-3 (pasteability)** — The primary consumer is a bug report. Plain, `grep`-able, copy-pasteable
  text outranks visual polish (FR-20..FR-22).
- **NFR-4 (privilege)** — `doctor` neither weakens nor extends the existing import-time
  auto-elevation. Any probe that cannot run for lack of privilege is reported as UNKNOWN naming the
  permission cause (FR-8) — never as a failure of the thing being probed, and never as a prompt to
  re-run with more privilege.
- **NFR-5 (compatibility)** — Python 3.6+ syntax floor, standard library only, no new dependency, no
  new file, no new module. Both supported init systems and all supported distributions behave per
  FR-14/BC-8.
- **NFR-6 (security)** — `doctor` prints no node credentials, no share links, no UUIDs, no
  passwords, and no full config body. S7 prints a public IP the user asked for; nothing else leaves
  the machine, and no new outbound endpoint is contacted beyond the existing egress-IP query.
- **NFR-7 (design discipline)** — Rule 85 applies in both directions: no second opinion of an
  existing judgment (FR-17), and no new abstraction, file, flag or config format that the seven
  sections do not require (§3.8).

---

## 7. Related tasks and prior decisions

| Task | Relevance |
|---|---|
| **T-02** `config-degrade-missing-rulesets` (`docs/features/config-degrade-missing-rulesets/`) | Established the single rule-set usability judgment and the per-rule-set report. `doctor`'s S2 consumes it; forming a second opinion re-creates the bug T-02 removed. Also the origin of the load-bearing zh grep literal FR-24 protects. |
| **T-10** `ruleset-update-no-needless-restart` (`docs/features/_archived/ruleset-update-no-needless-restart/`) | Added the single on-disk `.srs` reader returning `(status, digest)` from one read, with a binding digest contract. FR-12's size requirement extends that reader's outputs rather than adding a third file-reading path. Also the source of the `is-active`-cannot-witness-a-restart insight behind AC-6. |
| **T-01** `install-enable-start-split` | Defined the "state your outcome" discipline and wrote the install log `doctor` complements. Out of this task's diff. |
| **T-09** `fix-rules-update-execstart` | Owns `systemd/`. Out of scope; S4's autostart fact is what makes its failure visible. |
| **T-08 / T-11** | `install.sh` only. T-08's TTY-gating precedent informs FR-21; T-11's B.2 parity gate covers `install.sh` only, which is why AC-18 is a manual enumeration for `bin/sc`. |
| **T-06** `sc config --show` | The next pool row. Deliberately not absorbed — see §8 R-8. |

Glossary: `CONTEXT.md` terms are used unchanged. This task coins no new domain term; "probe",
"section" and "outcome class" are describing this command's output shape, not the domain, so they are
defined inline here rather than added to the glossary.

`.harness/rejected-decisions.md` contains no prior decline covering a diagnostic command.

---

## 8. Resolved ambiguities (deferred-human mode — decided here, with evidence)

**R-1 — Does "read-only, absolute" cover the writes `sc`'s start-up path performs before `doctor`
runs? → YES.**
*Evidence:* `bin/sc:1499-1503` — `main()` calls `_init_files()` and `_resolve_clash_port()` before
dispatching to any handler. `_init_files()` (`bin/sc:222-231`) creates `/etc/sing-box`,
`/etc/sing-box/rules`, `/var/lib/sing-box`, and writes `nodes.json` (mode 0600) and `settings.json`
when absent. `_resolve_clash_port()` (`bin/sc:191-212`) calls `save_settings()` when no port is
persisted. So today, running `sc doctor` on a host with no install would *create the very directory
whose emptiness is the diagnosis*, and would persist a Clash port that never existed.
*Decision:* FR-4 is process-wide, and AC-5's second half (run on a host with no `/etc/sing-box`)
tests exactly this. *Rejected alternative:* scope the guarantee to `doctor`'s own code and document
the start-up writes as pre-existing — rejected because it makes `doctor` an evidence-destroying tool
in precisely the scenario it exists for, and because the owner's word was "Absolute". *Note for
stage 2:* satisfying this means touching the dispatch path, which is inside `bin/sc` and therefore
inside scope; no other command's behaviour may change as a result (that is AC-16's neighbourhood).

**R-2 — Where does S6's port come from, given that resolving it can invent one? → From persisted
settings only; never probed.**
*Evidence:* `_resolve_clash_port()` (`bin/sc:191-212`) returns a persisted port when present and
otherwise calls `_free_port()` (`bin/sc:179-188`), which binds candidate ports until one is free —
i.e. it returns a port that is free *by construction*. Probing reachability on such a port would
report "unreachable" as a tautology, and (per R-1) persist it.
*Decision:* FR-15. *Rejected alternative:* read the port from `config.json`'s
`experimental.clash_api.external_controller` (`bin/sc:906`) — rejected as the *primary* source
because `config.json` is exactly the artefact `doctor` cannot assume is present or parseable (S3
precedes S6 for that reason). *Coin-flip residue:* whether S6 should additionally flag a
**mismatch** between the persisted port and a parseable `config.json`'s port. This is a real
condition on hosts installed before Clash-port auto-probing (`CHANGELOG.md:15`: the port was
previously hard-coded to 9090). Decided: **out of scope for this task** — it is a second judgment
about which port is authoritative, and no owner requirement names it. What would change the answer:
one field report of a host where `sc status` prints a port the service is not listening on.

**R-3 — The owner listed "config check" before "per-`.srs`"; causal order requires the reverse.
→ Rule-sets first.**
*Evidence:* the owner's own failure chain: "rules dir empty → generated config referenced missing
local rule-sets → `sing-box check` FATAL". `generate_config()` emits `route.rule_set` entries from
the rule-set report (`bin/sc:896-900`) and the check runs on the result (`bin/sc:921-926`), so
rule-set state is causally upstream of the check.
*Decision:* FR-6 orders S2 before S3, and FR-7 makes the ordering rule explicit rather than
aesthetic. *Rejected alternative:* preserve the owner's listing order — rejected because the owner
made causal order an explicit requirement, and the listing was a content list, not an order.

**R-4 — Bilingual failure mode of `bin/sc`'s `t()` — verified by reading, not assumed.**
*Evidence:* `bin/sc:215-217` — `t()` is
`TRANSLATIONS.get(LANG, {}).get(s, s)` followed by `.format(**kwargs)` when kwargs are present.
`TRANSLATIONS` has exactly one language table, `"zh"` (`bin/sc:85-86`; a search for a second
top-level language key finds none). Consequences, all binding on this task: (a) a missing **zh**
entry degrades to the English key rather than aborting — unlike `install.sh`'s `t()`, which aborts
under `set -u` — so a missing zh entry is a silent defect, which is why AC-18 is an executed check
and not just an inspection; (b) in English the key *is* the output, hence FR-23/AC-19; (c) a zh value
containing a placeholder the caller does not pass raises `KeyError` at run time, hence AC-18's
placeholder-set equality.
*Rejected alternative:* rely on `verify_all` B.2 — it renders `install.sh` only, and it has a
documented blind spot (it can render the en table twice and still print `OK`).

**R-5 — Should the egress probe run when the service is down? → YES, unconditionally.**
*Evidence:* `cmd_status` (`bin/sc:1100-1114`) gates the egress query behind `is_running()`, so today
a stopped service produces no egress line at all. For a diagnostic, "the service is down and my
egress IP is my ISP address" is a *confirmation*, not noise.
*Decision:* FR-16. *Rejected alternative:* mirror `cmd_status`'s gating — rejected because it makes
the most common broken state print the least information. *Cost, accepted:* up to 8 s (plus DNS, see
NFR-2) on a broken host; mitigated by FR-10 streaming and by S7 being last.

**R-6 — Size for rule-sets: extend the existing reader, or `stat`? → Extend/reuse the reader.**
*Evidence:* `ruleset_state()` (`bin/sc:516-558`) already computes the true byte count during its
chunked read (`size += len(chunk)`, `bin/sc:552`) and discards it, returning only `(status, digest)`
(`bin/sc:558`); its docstring states the count is deliberately "the real byte count rather than
st_size". `docs/dev-map.md` names it "the ONE reader of a `.srs` on disk".
*Decision:* FR-12 + AC-14 — size comes from that read. *Rejected alternative:* `path.stat().st_size`
in `doctor` — rejected as exactly the "second notion of the file's facts" that T-02 and T-10 exist to
prevent, and because a size that disagrees with the size the usability judgment used would be a
report that contradicts itself. Mechanism (extend the return tuple, add a projection, or expose a
size-carrying view) is stage 2's.

**R-7 — Exit-status policy. → Deferred to stage 2 under binding constraints (FR-25..FR-29).**
*Evidence/rationale:* the owner explicitly assigned the decision to stage 2, and both candidate
policies are defensible; the requirement-level risk is inconsistency and undocumented behaviour, not
the choice itself. If stage 2 wants a tie-break from stage 1: **(b) 0/non-zero** matches the
project's existing precedent — `sc update-rules` already exits non-zero when rule-sets failed
(`bin/sc:1255-1256`) and `install.sh` derives its exit status from recorded phase state (T-01) — but
the counter-argument (a diagnostic that returns non-zero on a *successful diagnosis* surprises `set
-e` scripts) is real. Whatever is chosen, FR-28 makes it predictable.

**R-8 — Should `doctor` absorb `sc config --show` (T-06) or replace `sc status`? → NO to both.**
*Evidence:* rule 85's consolidation tests. Patch-then-patch seam: `doctor` ships a coherent,
independently useful artefact without T-06 — nothing it computes exists only for T-06 to consume.
Duplicated judgment: `doctor` reports *whether* the config is valid; `config --show` renders the
config's *content* — different questions over the same file. Replacing `sc status` would change a
documented command's output (`README.md:99`) for users who did not ask.
*Decision:* both stay separate; FR-19 pins `sc status`. *Consequence acknowledged:* `doctor` and
`status` overlap on TUN / Clash / egress facts, which is why FR-18 mandates single definitions of
the shared literals — the overlap must be in the *rendering*, never in the *facts*.

**R-9 — Does anything guarantee that the external config checker is itself read-only? → Not proven;
asserted by AC-5 and listed as a risk.**
*Evidence:* `generate_config()` invokes `sing-box check -c <config>` (`bin/sc:921-926`). That is an
external binary whose internal behaviour this project does not control; the generated config declares
a cache file at `/var/lib/sing-box/cache.db` (`bin/sc:903-905`).
*Decision:* AC-5 measures `/var/lib/sing-box` as well as `/etc/sing-box`, so if the checker touches
the cache the criterion fails loudly instead of the guarantee being quietly false. See RISK-1.

**R-10 — Is `doctor` allowed to change files outside `bin/sc` and the two READMEs? → Yes, for the
three documentation artefacts named in FR-30/FR-31 only.**
*Evidence:* `CHANGELOG.md` is the project's user-visible change record, written in zh, updated by
every prior delivered task (`CHANGELOG.md:7-20`); `docs/dev-map.md` states at its head that it is
updated whenever the module inventory changes. The PM's scope boundary enumerates *product* files.
*Decision:* AC-26's file list. *Rejected alternative:* read the boundary literally and skip the
changelog — rejected because it would make this the first feature since 0.1.0 with no user-visible
record; the risk of the wider reading is bounded (documentation only, no behaviour).

---

## 9. Risks

- **RISK-1** — AC-5 may fail through no fault of this task if the external config checker writes to
  the sing-box cache file (R-9). Detection is stage 6's; if it materialises, stage 2 must choose
  between invoking the checker in a way that does not touch runtime state and recording a documented,
  narrowly-scoped exception. Do **not** pre-emptively weaken FR-4.
- **RISK-2** — Satisfying FR-4 requires touching `sc`'s shared start-up path (R-1), which every other
  subcommand traverses. A careless change silently stops initialising state for `add`/`use`/`on`.
  AC-16 covers `status` only; stage 2 must state what protects the rest.
- **RISK-3** — Zh strings are double-width. Any column alignment computed from character counts
  misaligns under `lang zh`. FR-22 keeps alignment optional and content-neutral precisely so that
  this is cosmetic; a design that computes padding widths must account for it.
- **RISK-4** — No committed test suite exists (`baseline.json` still reads `test_count: 0`), so every
  AC above is verified by a harness built for this task. Any harness that imports `bin/sc` must
  neutralise the import-time auto-elevate line and set both init-system flags false — otherwise the
  test run drives the *installed* tool against the *live* service.
- **RISK-5** — Insight-index budget: the file holds 29 lines against a cap of 30, so this task's
  harvest is effectively one line and it must be a single physical line.

---

## 10. Verdict

**READY** — no question is routed to the owner; all ten ambiguities are resolved in §8 with evidence
and with the rejected alternative recorded. No safety red line was encountered.
