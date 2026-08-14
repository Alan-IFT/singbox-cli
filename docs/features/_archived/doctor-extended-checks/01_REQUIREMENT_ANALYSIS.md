# 01 — Requirement Analysis · T-20 `doctor-extended-checks`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

`sc doctor` reports seven facts and stops at the boundary of the features that landed after it, so a
host whose rule-sets are months old, whose `config.json` was hand-edited, whose AAAA decision no
longer matches the document on disk, whose nodes have never been probed, whose name resolution
stalls, or whose credential documents are world-readable reads `[OK]` on every row it prints.

## In-scope behaviors

**FR-1** — `sc doctor` states each rule-set's age on that rule-set's existing row, beside the status
and byte count already there. The age comes from the timestamp the single rule-set reader returns
with the status and the digest, rendered by the project's one age renderer; no second timestamp
source for a rule-set exists anywhere in the tool.

**FR-2** — A rule-set that is usable and older than the staleness threshold is reported as a PROBLEM
row naming its age and the command that refreshes it. The threshold is one named constant, fixed at
**60 days** — strictly greater than the longest cadence `sc update-interval` offers as a preset — so
no host whose auto-update is working reports it on any preset cadence.

**FR-3** — `sc doctor` states whether `config.json` is the document `sc` last generated, taken from
the project's single drift judgement and its three states. Drifted is a PROBLEM row naming the user
override as the durable home for the change; unknown is an UNKNOWN row; matching is an OK row.

**FR-4** — `sc doctor` states this host's effective AAAA decision and whether the document on disk
carries that decision. The decision comes from the one existing IPv6 decision function and no part of
it is re-derived; a document that carries the other decision is a PROBLEM row whose next step
regenerates the document.

**FR-5** — `sc doctor` states in one row how many of the configured nodes carry a stored round-trip
delay, out of how many exist, and which outbound the auto-select group is on right now. The values
come from the existing stored-delay reader, addressed at the **persisted** Clash port, and the row
states them as stored history — no row claims a fresh measurement.

**FR-6** — `sc doctor` states one measured DNS fact about the running install: whether a name lookup
issued through it returns an answer inside a bounded wait, and the elapsed time of a lookup that
answered. The row never reports a configured DNS timeout value and never implies one is
configurable.

**FR-7** — `sc doctor` states whether any regular file directly inside the configuration directory
grants any permission to group or other, and whether the configuration directory itself grants write
to group or other. Each offending path is named with the mode found and the command that narrows it;
`settings.json` is excluded because it is not a credential document.

**FR-8** — Every PROBLEM row this task adds names, on the same line as its conclusion, one next step
the reader can perform — a command this project ships or a standard shell command. No row proposes an
action this project cannot perform, and no row proposes an action `sc doctor` performs itself.

**FR-9** — The Clash API row's PROBLEM message stops asserting a cause it did not observe (R-32); it
states that no usable answer was obtained at the named port and nothing about why.

**FR-10** — The row grammar `[<class>] <label>: <value>`, the three outcome classes, their markers and
the exit-status mapping are unchanged; every new fact is a row in that grammar and the next step is
part of the row's value text.

**FR-11** — The report's order stays decided in the one ordering table whose only reader is the
`doctor` driver, and the new facts obey the causal relation in FR-12.

**FR-12** — The following precedence pairs hold in the printed report: drift precedes the
`sing-box check` row; the AAAA-consistency row precedes the DNS row; the DNS row precedes the egress
row; the Clash API rows precede the node-delay row; the node-delay row precedes the egress row; every
permission row follows every other row.

**FR-13** — `sc doctor` remains process-wide read-only: no new probe writes, creates, removes or
renames any path, performs a service-affecting action, or reaches `_init_files()` /
`_resolve_clash_port()` through the `doctor` arm of the start-up dispatch.

**FR-14** — Both READMEs' `sc doctor` section table and its "seven facts" count are updated to the
report this task ships, and `CHANGELOG.md` gains one entry under `[Unreleased]` in Chinese.
`docs/dev-map.md` is updated if and only if this task changes the reusable-utility inventory it
records.

## Out of scope

1. Any repair: no `chmod`, no `sc reload`, no `sc update-rules`, no service action. `sc doctor`
   diagnoses only, and every next step is a sentence the user acts on.
2. `install.sh`, `uninstall.sh` and `systemd/` — so R-11's second half (setting the configuration
   directory's mode deliberately) stays open after this task.
3. `sc status` and `sc ls` — R-33, R-38 and R-19 are untouched and stay open.
4. A per-node latency table in `sc doctor`. `sc ls` already prints one; the report states the
   conclusion and names `sc ls` for the detail.
5. Any fresh latency measurement, any probe request to the Clash API other than reads, and any
   widening of the stored-delay reader's return shape.
6. Any staleness threshold derived from the configured update cadence, and any per-rule-set
   threshold.
7. Machine-readable output, per-section selection flags, a quiet mode, historical trending.
8. Any change to the wording of an existing `sc doctor` row other than FR-9's.
9. Any change to `_drift_state()`'s judgement, to the single rule-set reader's contract, to
   `ipv6_decision()`, or to `stored_delays()`'s return shape.
10. Any change to the existing 3 s / 8 s / 30 s socket timeouts, and any new exit-status value.
11. The credential write path's missing `encoding=` (R-17): this task opens no write path and adds no
    unguarded reader, so R-17 stays open and unclaimed.
12. Printing any byte of any credential document. The permission rows print paths and modes only.

## Boundary conditions

**BC-1** — A rule-set with no readable bytes (absent, unreadable) → its row prints the word form for
an unknown timestamp, never a number, and never the stale verdict; the row's PROBLEM class comes from
its status, as today.

**BC-2** — A rule-set timestamp ahead of the host clock (skew, restored backup) → a zero-length age,
never a negative one, never stale.

**BC-3** — Every rule-set usable and none stale → the section's summary row stays OK; one stale
rule-set → the summary row is PROBLEM, exactly as one unusable rule-set already makes it.

**BC-4** — No drift record, an empty one, or one that cannot be read → the drift row is UNKNOWN, never
"drifted".

**BC-5** — A drift record that is present, non-empty and not a digest → the drift row is PROBLEM
("drifted"), matching the existing judgement rather than overriding it (see Q-9).

**BC-6** — `config.json` absent or unreadable → the drift row and the AAAA-consistency row are both
UNKNOWN; the configuration row above already owns "there is no readable document".

**BC-7** — `config.json` present but not parseable as JSON → the AAAA-consistency row is UNKNOWN,
never PROBLEM; the `sing-box check` row above owns that verdict.

**BC-8** — The host's IPv6 address source cannot be read → the AAAA-consistency row is UNKNOWN, and
the one stderr line the existing decision function writes in that state may appear outside the row
grammar; no row is lost to it.

**BC-9** — `settings.json` carries an unrecognised `ipv6` value → the existing reader's stderr line
appears and the row renders the effective decision (`auto`), never the rejected value as if it were in
force.

**BC-10** — No Clash API port recorded in settings → the node-delay row and the DNS row are UNKNOWN
and issue no request. Neither row falls back to the module-level port constant, which a `doctor` run
deliberately leaves unresolved.

**BC-11** — The service is not running → the node-delay row and the DNS row are UNKNOWN and issue no
request and no lookup. An empty delay map is not by itself evidence of a probe failure, and a DNS
lookup issued while the tunnel is down would leave the host's resolver path unproxied.

**BC-12** — The service is running and the Clash API does not answer → the node-delay row and the DNS
row are UNKNOWN, never PROBLEM: a prerequisite failure produces UNKNOWN in the sections that depend on
it, and the Clash API row above states the failure once.

**BC-13** — The service is running, the API answers, and zero of the configured nodes carry a stored
delay → PROBLEM. Its next step names both admissible causes — no probe has completed yet, or every
node is failing — and points at `sc ls`; `sc doctor` never sleeps, retries or waits for a probe.

**BC-14** — No nodes are configured → the node-delay row states that and is OK, not PROBLEM.
`nodes.json` absent, unreadable or malformed → UNKNOWN naming the file, never a traceback.

**BC-15** — No answer to the DNS lookup inside the bounded wait → PROBLEM stating that no answer
arrived inside that wait, and nothing about the cause beyond the next steps the rows above establish.

**BC-16** — No lookup mechanism exists that the caller can bound and that reaches the running
install's resolver, as established at stage 2 by a first-hand read-only probe → FR-6 ships no code,
the probe and its result are recorded in `02_SOLUTION_DESIGN.md`, and FR-6 is re-homed as a pool row.
FR-1…FR-5 and FR-7…FR-14 are unaffected by that outcome.

**BC-17** — A lookup mechanism whose wait the caller cannot bound (`socket.getaddrinfo` takes no
timeout argument) is inadmissible for FR-6, whatever else it offers.

**BC-18** — The configuration directory does not exist → the permission rows are UNKNOWN and `doctor`
does not create it. The directory exists but cannot be listed → UNKNOWN naming the reason.

**BC-19** — A symlink directly inside the configuration directory → reported as a symlink, by a
metadata read that does not follow it, so a planted link's target mode is never reported as the
link's. Sub-directories (`rules/`) are reported by the directory predicate at most for the
configuration directory itself and are never descended.

**BC-20** — Every file in the configuration directory is 0600 or narrower and the directory is not
group- or other-writable → exactly one OK permission row, naming no path.

**BC-21** — Many offending files → they are elided by the same rule and the same constant the existing
multi-line quotation already uses, stating how many were not shown.

**BC-22** — A host on which a new check reports PROBLEM where none did before (a stale rule-set, a
drifted document, a wide mode) → `sc doctor` exits 1 through the existing mapping. No new exit value
is introduced and the mapping is unchanged.

**BC-23** — Any new probe raising → the section's existing isolation renders one UNKNOWN row for that
section and every other section still prints.

**BC-24** — `sc lang zh` → every new row, every new conclusion and every new next step renders in
Chinese, marker included.

**BC-25** — Output redirected to a pipe or file → every new row is flushed as it is printed, like every
existing row.

**BC-26** — A concurrent `sc reload` / `sc update-rules` while `doctor` reads → `doctor` reports what
it read, never blocks, never locks and never retries; a mid-generation observation is reported as the
state it is.

## Acceptance criteria

| id | criterion | class | verification |
|---|---|---|---|
| AC-B1 | On a fixture whose `.srs` files are usable with an mtime 90 days in the past, the rule-set section prints a PROBLEM row per file naming the age and the refresh command, and the section summary is PROBLEM. | [B] | Run against a redirected-path fixture; capture stdout; assert marker, age text and command literal. Control: same fixture with a current mtime → OK, no next-step text. |
| AC-B2 | On a fixture whose drift record holds a digest different from the `config.json` present, the drift row is PROBLEM and names the user override. | [B] | Fixture run; assert marker + `override.json` in the row. Controls: matching digest → OK; absent record → UNKNOWN. |
| AC-B3 | On a fixture whose `config.json` suppresses AAAA while the repointed IPv6 address source shows a global address (and its mirror image), the AAAA-consistency row is PROBLEM and names the regeneration command. | [B] | Two fixture runs, one per direction; assert marker and command. Control: document agreeing with the source → OK. |
| AC-B4 | On a fixture whose stub Clash API answers `/proxies` with entries carrying no history, while the service reads as running, the node-delay row is PROBLEM and names `sc ls`. | [B] | Stub HTTP server on a port proved free and recorded in the fixture's own `settings.json`; assert marker and text. Control: entries carrying a delay → OK with the counts. |
| AC-B5 | On a fixture in which the lookup returns no answer inside the bounded wait, the DNS row is PROBLEM stating that; on one in which it answers, the row is OK and states an elapsed time. | [B] | Two fixture runs. Discharged as BC-16 if the mechanism ruling drops FR-6, with the stage-2 probe recorded. |
| AC-B6 | On a fixture whose configuration directory contains `config.json.bak-<date>` at 0644, that path is named in a PROBLEM row with its mode and a `chmod` command. | [B] | Fixture run; assert path, `644` and the command. This is R-10's exact reported instance. |
| AC-B7 | On a fixture whose configuration directory is itself mode 0777, the directory is named in a PROBLEM row with its mode and the command that narrows it. | [B] | Fixture run; assert marker, path, mode. This is R-11's instance. Control: 0755 → OK, no PROBLEM. |
| AC-B8 | On a wholly healthy fixture, every new row is OK, no new row names a path or a next step, the run exits 0, and the report grows by at most one row per new check over the seven-section baseline. | [B] | One run; diff the row count against a HEAD run on the same fixture; assert exit 0. This is the control that a build printing PROBLEM everywhere fails. |
| AC-B9 | Under `sc lang zh`, every new row, conclusion and next step renders in Chinese. | [B] | Repeat AC-B1…AC-B7 with the fixture's `settings.json` carrying `lang: zh`; assert no untranslated key text and no ASCII conclusion. |
| AC-B10 | A `sc doctor` run creates, modifies and removes nothing: a full snapshot (existence, size, mtime, sha256, mode) of the fixture root before and after is identical, and on a fixture with no configuration directory none is created. | [B] | Two runs, snapshot compared; plus a positive control proving the harness's raisers fire for a command that does initialise. |
| AC-B11 | Forcing each new probe to fail independently still prints every section label and terminates normally. | [B] | One run per new probe (record removed; API port closed; directory unlistable; IPv6 source unreadable; nodes file malformed). |
| AC-B12 | With the Clash API unreachable while the service runs, the node-delay row and the DNS row are UNKNOWN, not PROBLEM. | [B] | Fixture run with a port nothing listens on; assert both markers. |
| AC-B13 | A symlink in the configuration directory pointing at a 0777 file outside it is reported as a symlink, and the 0777 target's mode appears nowhere in the report. | [B] | Fixture run; assert the target mode string is absent from stdout. |
| AC-B14 | The shipped invocation — `sc doctor` as root on the live host — prints the extended report, exits with the mapped status, and leaves the service witness unchanged. | [B] | One run. If no interactive root credential is available, report **BLOCKED and file it**; never substitute a weaker artifact check (R-31 / R-41 / R-47 precedent). |
| AC-S1 | Each new fact stands on its feature owner's existing call: deleting the age renderer, the drift judgement, the stored-delay reader or the IPv6 decision function breaks the corresponding row at import or definition time rather than leaving it working through an independent path. | [S] | Four deletion tests plus a call-graph read of the new code. |
| AC-S2 | The diff introduces no second opinion of any reported fact: no `st_size`, no second timestamp read of a rule-set, no second digest of `config.json`, no second Clash exception envelope, no second AAAA decision. | [S] | Grep the diff for each; read every new call site. |
| AC-S3 | The report's order is decided in exactly one table, and every precedence pair in FR-12 holds in captured output. | [S]+[B] | Read the ordering table; assert label order in one healthy-fixture capture. |
| AC-S4 | `sc doctor` reaches no writer: no config generation, restart, reload, download, settings or nodes writer, and no `_init_files()` / `_resolve_clash_port()` call appears in the new code's reachable call graph. | [S] | Call-graph read of every function the new rows call. |
| AC-S5 | Every new user-facing string is a readable English sentence and has a `TRANSLATIONS["zh"]` entry, and no new zh string contains `失败：`. | [S] | Enumerate new `t()` keys from the diff; check both properties per key. |
| AC-S6 | No existing timeout constant changed, no new exit-status value, and the row grammar and marker set unchanged. | [S] | Diff read against the three constants and the class/exit tables. |
| AC-S7 | The committed diff touches only the files this task declares, excluding this task's own stage documents and anything under `docs/batches/**` (R-36's missing carve-out, closed for this template). | [S] | `git status` + `git diff --numstat` read at delivery. |
| AC-S8 | No row of the report contains a byte read from the content of `config.json`, `nodes.json` or `override.json`. | [S]+[B] | Read the new code for content reads; grep a fixture run's stdout for a planted credential literal. |
| AC-S9 | A staleness threshold exists as one named constant, is read in exactly one place, and its value exceeds the longest preset cadence. | [S] | Grep for the constant; read its single reader. |

## Non-functional requirements

1. Every new probe's socket operations carry an explicit caller-set timeout. The report's **total**
   wall clock is not claimed to be bounded: `urlopen(timeout=N)` bounds each socket operation and not
   the call (R-35, measured at 30.1 s for a 3 s request), so no row and no document may state "it
   gives up after N seconds".
2. The added cost on a healthy host is one Clash API read (FR-5), one bounded lookup (FR-6), one
   directory listing plus one metadata read per entry (FR-7), and no additional read of any rule-set
   or of `config.json` beyond the ones the existing readers already perform.
3. The user-facing surface grows by at most one row per new check on a host where that check passes
   (AC-B8). Per-item enumeration appears only where there is a problem to name.
4. New translation keys land in `TRANSLATIONS["zh"]`'s existing thematic groups; the table has no
   `en` half, so every key is itself the English text (R-19 must not spread).

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Does the goal's "DNS timing" clause survive? | **No — it is refuted and re-scoped.** sing-box 1.13.15 accepts no DNS `timeout` at any level, the rule chain never falls through on failure, and nothing `sc` emits carries one; a row reporting a configured DNS timeout would report a value that does not exist. The row becomes one **measured** fact (FR-6), and its mechanism is settled by a first-hand read-only probe at stage 2 under BC-16/BC-17 — including the outcome in which the row ships nothing. |
| Q-2 | Do the other five clauses survive? | **Yes, all five, each standing on a call its feature owner already ships**: rule-set age on the single rule-set reader's timestamp and the one age renderer (T-19, K-17); node delay on the stored-delay reader (T-15); drift on the extracted drift judgement (T-14/T-06); AAAA state on the IPv6 decision function (T-16); permissions on this tool's own credential-mode constant and T-13's own predicate. "DNS timing" is the only clause of the six with no owning call, which is exactly why it is the one that was wrong. |
| Q-3 | Does T-20 define what "stale" means, given T-19 declined to? | **Yes, and only as a function of the age T-19's reader produces**, which is the rule T-19 made binding. One constant, 60 days, strictly above the longest preset cadence so a working auto-update never trips it; a cadence-derived threshold is declined because a custom `OnCalendar` expression is not convertible to a duration. |
| Q-4 | Is R-10 (hand-made credential backups invisible to the enumerated sweep) in scope? | **In scope, and it is the row's main value.** The installer's sweep must not roam because it *chmods*; a reporter only *reports*, so it may enumerate where a writer may not. The predicate is T-13's own (`mode & 0o077`), the exclusion list is `settings.json` alone, and a hand-made backup at a wide mode is caught with no filename pattern anywhere. |
| Q-5 | Is R-11 (the configuration directory's own mode) in scope? | **In scope, narrowed to the attack R-11 names.** The directory row is PROBLEM only when the directory grants **write** to group or other — the rename-between-fchmod-and-replace window — and never for the world-readable, traversable mode every host has, which would fire on 100% of installs and teach people to ignore the row. R-11's other half (setting the mode deliberately in `install.sh`) stays open. |
| Q-6 | Is R-32 (the Clash row naming a cause it does not have) in scope? | **In scope.** `docs/tasks.md` assigns it to T-20, it is one key plus one zh entry, and the node-delay and DNS rows are now dependent on that row — a dependency stated on a message that asserts an unobserved cause would propagate the imprecision. |
| Q-7 | Are R-38 (the `sc status` separator), R-19 (the five `ls.*` keys), R-33 and R-17 claimed here? | **No, none of them.** All four live in commands this task does not touch (`sc status`, `sc ls`) or in a write path this task does not open; claiming them would widen the diff for no requirement. They stay open with their existing owners. |
| Q-8 | Where does the next step live, given T-05 put remediation out of scope? | **Inside the row's value text, on the same line, on PROBLEM rows only.** The row grammar is pinned in one place and stays pinned; an UNKNOWN row names the fact that could not be established and why, and an OK row carries no next step. Nothing becomes a fourth tuple element and no new print path is added. |
| Q-9 | R-43 — BC-13's third clause and T-06's K-14 cannot both hold. Which gives way? | **BC-13's third clause gives way; the judgement is not touched.** A present, non-empty, non-digest drift record reads as **drifted** here, exactly as the existing warning renderer already treats it. Changing the judgement to return "unknown" would change an existing command's observable behaviour and give two commands two opinions about drift, which is the defect this subsystem exists to prevent. R-43 is closed by this ruling. |
| Q-10 | Does the report show per-node latency as a table? | **No — one row.** The per-node table is `sc ls`'s, and re-printing it here would make the report's size scale with the node list on a healthy host. The row states the conclusion and names `sc ls` for the detail. |
| Q-11 | Is drift a PROBLEM, given a drifted host may be working fine? | **PROBLEM.** It is the only class that carries an action, the user's edits are about to be discarded by the next regeneration, and UNKNOWN is reserved for facts that could not be established. The exit-status consequence is stated in BC-22. |
| Q-12 | Where do the permission rows print, given the order is causal? | **Last, after the egress row.** The ordering rule places a row above another only when its failure explains the other's; a wrong mode explains no other row on the screen, so putting it higher would push the failure chain down. |
| Q-13 | Which name does the DNS lookup use, if FR-6 ships? | **The same name the egress probe resolves, with the literal keeping exactly one home.** This makes the two rows a causal pair (the DNS row explains the egress row's failure) and adds no second endpoint constant. |
| Q-14 | Schema gap: `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` on this project (**R-37, third confirmation**), so the per-clause refutation of the goal sentence, the related-task survey and the candidate answers fit no declared contract shape. | They are carried in `01_RATIONALE.md`, which is the destination the analyst contract names for exactly these units, and this row records the gap rather than inventing a contract section for them. |
| Q-15 | Two glossary terms are sharpened by this task — **stale rule-set** and **credential directory**. Where do they go? | **Defined in `01_RATIONALE.md` and proposed for `CONTEXT.md`, not written into it here** — the T-19 precedent, so no file outside this task's declared diff is edited before the diff is declared. |

## Verdict

READY
