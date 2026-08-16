# 01 — Requirement Analysis · T-30 `validate-before-baseline`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

`sc` installs the composed configuration at `config.json` and baselines its drift digest **before**
asking `sing-box check` whether the document is usable, so a rejected document replaces the working
one on disk and is recorded as "what `sc` last generated" — and the same checker invocation raises
out of the process on a host where the binary is missing, unexecutable, or emits output the run's
decoder refuses.

## In-scope behaviors

**FR-1** — `generate_config()` obtains the checker's verdict on the composed document **before** that
document becomes `config.json`. The verdict is taken on exactly the bytes that would be installed,
with exactly one `sing-box check` invocation per `generate_config()` call.

**FR-2** — A **rejected** verdict installs nothing. `config.json` and the drift record are left
byte-identical to their content at the start of the run — including the absent state on a host that
has neither — no service-affecting action is taken, and the function reports failure to its callers
exactly as today.

**FR-3** — An **accepted** verdict installs the document through the single credential writer and
then records the drift digest, in that order. For inputs whose document the checker accepts, the
installed bytes, the file's mode and the recorded digest are identical to what the current build
produces.

**FR-4** — A **cannot-validate** verdict — no `sing-box` binary on `PATH`, a binary present that
cannot be executed, or checker output the run cannot decode — installs and records exactly as an
accepted verdict does, writes one stderr line saying the document was installed without being
validated and why, and reports success. No state of the checker invocation raises out of
`generate_config()`.

**FR-5** — The rejection message names `config.json`, states that it was left unchanged, and quotes
the checker's own words with terminal control sequences removed by the existing output neutraliser.
No path that exists only for the duration of the run appears in any message the user sees.

**FR-6** — The drift record is written only after a document the checker did not reject reached
`config.json`, so the record, the file and the running service describe one configuration in every
outcome of a run.

## Out of scope

1. **R-81** (`stored_delays()` cannot distinguish "no `/proxies` answer" from "an answer carrying no
   history") — ruled not a one-line ride-along (Q-3); stays filed.
2. **R-100** (`sc update-rules` prints no run-level outcome line on an abort) — this change adds no
   abort to that path and removes three (Q-4); T-29's decline stands, not re-opened.
3. Any backup, copy or rollback of a previous `config.json`; the drift record stays a digest.
4. A `sing-box check` wrapper shared with `sc doctor` (`shared-singbox-check-wrapper`, declined).
5. Parameterising the credential writer into a general or shared helper
   (`shared-atomic-write-helper-with-ruleset-downloader`, declined).
6. Any validation `sc` performs itself: the composed-document array assertion keeps its current
   extent, and no schema knowledge moves into `sc`.
7. The second locale-dependent pipe decode named by R-99 and `install.sh`'s own `settings.json`
   reader/writer.
8. `sc doctor`'s rows, `sc config`'s provenance line, and the emitted document's bytes.
9. Retrying, degrading or repairing a document the checker rejected.
10. Anything reached only from `cmd_update_rules()`'s download loop or its outcome block.

## Boundary conditions

**BC-1** — Any transient object that carries the composed document before it is installed is a
**credential document**: mode exactly `0600` from before its first byte (mode set on the descriptor,
never a `chmod` after content), created under a fresh exclusive name inside `config.json`'s own
directory, and removed on **every** outcome — accepted, rejected, cannot-validate, or an exception.
The credential directory has no stale-temp sweeper and gains none.

**BC-2** — The verdict taken before installation is the verdict the same bytes would earn at
`config.json`: the emitted document carries absolute paths only, and any transient location lies in
`config.json`'s own directory, so neither the filename nor the process working directory can move the
answer.

**BC-3** — Fresh host, no `config.json` and no drift record: a rejected verdict leaves both absent. A
cannot-validate verdict creates both.

**BC-4** — Drift record absent or unreadable: the three-valued drift judgement keeps its current
meaning (drifted / matches / unknown) and keeps its single home. A rejected run writes no record and
therefore cannot move "unknown" to any other state.

**BC-5** — `config.json` hand-edited before the run (drift = drifted): a rejected verdict leaves the
user's edit on disk untouched, and the run's own message is what tells the user the replacement the
drift warning predicted did not happen.

**BC-6** — Two `sc` runs at once: no window is added. The install and the record stay two steps in
the same order, each through the existing single writer, and a run's transient object never collides
with another's.

**BC-7** — `_write_private()` remains the only mechanism by which `config.json` reaches disk, with
T-13's five guarantees intact and unweakened.

**BC-8** — The drift judgement keeps exactly one definition and `sc doctor` stays process-wide
read-only with no second opinion: no drift state is computed a second way, at a second site, in this
task.

**BC-9** — "Exactly one apply per run" stays structural: no second `restart_service()` call site
outside `reload_or_restart()` is added, and `sc update-rules`' recovery-before-exit ordering and its
single folded `generate_config()` boolean are unchanged.

**BC-10** — Checker output that is empty on a rejecting exit still yields a message stating a fact
(the exit status), never a header promising detail followed by nothing.

**BC-11** — No new path exits non-zero without a stated outcome; the population of runs that unwind
with no run-level outcome line does not grow.

**BC-12** — Every new user-facing string ships in both languages with identical placeholders; the key
is the English sentence; no new string contains `失败：`.

**BC-13** — Verification safety, binding on every stage: never write `/etc/sing-box` or
`/var/lib/sing-box`, never drive `sc reload` against the live host, never restart the service. A
`bin/sc` load uses the mandated loader recipe plus the exec-denial shim, repoints every path constant
into a `mkdtemp` root, and never drives `_init_files()`. Live service state is witnessed with
`systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts`, never `is-active`.

**BC-14** — A criterion that needs root, the installed `sc`, or a real `sing-box` binary the verifying
host does not have is reported **BLOCKED** with the recipe that discharges it. Nothing is substituted
for a run.

## Acceptance criteria

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | Accepted verdict, host with an existing configuration: `config.json` is replaced, its bytes are identical to the current build's output for the same inputs, its mode is `0600`, the drift record equals the sha256 of the installed file, the call returns success, and the caller performs exactly one restart. | [B] | Fixture run under the loader recipe, paths in a `mkdtemp` root, `SB_BIN` a stub exiting 0; byte-compare against the same fixture run on the HEAD clone. **HEAD passes; a build that rejects everything, or one that never writes, FAILS.** This is the criterion the whole task must not break. |
| AC-2 | Rejected verdict, existing configuration present: `config.json` bytes and the drift record are byte-identical to their pre-run content, the call returns failure, no restart is attempted, and one stderr line carries the checker's words. | [B] | Same fixture, `SB_BIN` a stub exiting non-zero with a message. **HEAD FAILS both file clauses (it overwrites and re-baselines) — this is the defect.** A build that writes nothing at all also satisfies this row, which is why AC-1 is mandatory. |
| AC-3 | Rejected verdict, fresh host: no `config.json` and no drift record exist after the run. | [B] | Same fixture with neither file pre-created. **HEAD creates both**; a correct build creates neither. |
| AC-4 | `SB_BIN` pointing at a path that does not exist: no exception escapes, the document is installed, the record is written, the call returns success, and one stderr line says the document was not validated and why. | [B] | Fixture with `SB_BIN` set to an absent path. **HEAD raises `FileNotFoundError` and tracebacks** (R-70). A build that refuses to install here FAILS the row. |
| AC-5 | `SB_BIN` pointing at a non-empty, executable file that is not a valid executable: same observable outcome as AC-4. | [B] | Fixture with a mode-`0755` file of non-executable content. **A guard that only tests binary presence passes AC-4 and FAILS this row**, which is what makes the pair discriminating. |
| AC-6 | Checker exits non-zero writing bytes the run's decoder cannot decode: no exception escapes, the run reports rejection, and the on-disk state satisfies AC-2. | [B] | Stub emitting invalid UTF-8 on stderr. **HEAD raises `UnicodeDecodeError` from inside the invocation** (R-99, this site). A build catching only the missing-binary case FAILS. |
| AC-7 | The transient object holding the composed document is mode `0600` at the instant it holds the full document, and no `config.json.tmp.*` or comparable entry survives any of AC-1…AC-6. | [B] | The stub checker `stat`s the file it is handed and reports the mode, which the assertion reads — the mode is observed at the one instant the object is complete, by a run, not by inspection. Directory listing compared before and after each case. **A build that writes the candidate at the umask's mode FAILS the first clause; a build that leaks a temp on the rejected path FAILS the second.** |
| AC-8 | The rejection message names `config.json`, states it was left unchanged, and contains no ESC and no CR. | [B] | Assert on captured stderr in the AC-2 fixture, in both `en` and `zh`. **A build that passes the checker's raw output through FAILS the control-sequence clause under a real binary (AC-11); a build naming the transient path FAILS the first clause.** |
| AC-9 | Freeze: `sc doctor`'s S3 rows (configuration / drift / check) for a given on-disk state are identical to HEAD's, and `_drift_state()` has one definition. | [B] | `_doctor_config()` driven in the fixture over three on-disk states; compare rows against the HEAD clone. **Control agrees with HEAD by design — a freeze, never quoted as evidence of a change.** |
| AC-10 | Freeze: with the checker rejecting, `sc update-rules` prints exactly one run-level outcome line and exits 1; `sc reload` exits non-zero; `sc add` prints its check-failed line and exits 0. | [B] | Command-level fixture with stubbed fetches for the first; direct calls for the others. **Control agrees with HEAD**; a build that adds an unwind or an outcome line FAILS (BC-11, R-100 untouched). |
| AC-11 | With the **real** `sing-box` binary: a composed document the real checker rejects leaves `config.json` byte-identical, and the rendered message satisfies AC-8's clauses against the checker's genuinely coloured output. | [B] | Same fixture, `SB_BIN` set to a real `sing-box`, no root and no live service. **A stub checker cannot reveal the colouring** (T-05 DEF-1), so this row is the only one that establishes AC-8's ESC clause. **BLOCKED** if the verifying host has no `sing-box` on `PATH`; discharged by re-running the same fixture on a host that has one. |
| AC-12 | On an installed host: after a run whose document the checker rejects, `systemctl restart sing-box` still starts the service, and the unit survives a reboot. | [B] | **BLOCKED** — needs root, the installed `/usr/local/bin/sc` and the live service. Discharged by an operator: install the new `bin/sc`, provoke a rejecting override, then `systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts sing-box` before and after a restart. File as an operator obligation with this recipe. |
| AC-13 | The committed contract suite's existing assertions all still pass and its assertion floor does not fall. | [S] | `.harness/scripts/verify_all` B.4 against the recorded floor. |

## Non-functional requirements

1. Exactly **one** `sing-box check` process is spawned per `generate_config()` call — the same number
   as today. A design that checks both a candidate and the installed file is a regression.
2. The set of entries under `/etc/sing-box` after any run is unchanged from today's set.
3. Budget: **≤ 25 net added executable lines** in `bin/sc`. The recent bar is T-27's 8 added
   executable lines and T-29's zero; a larger design must state what the extra lines buy (rule 85
   puts the burden of proof on the larger design).
4. The emitted document's bytes are unchanged for every input whose document is accepted today
   (T-15's differential).

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | What does a user actually experience today — is this severe or cosmetic? | **Severe: a latent, delayed, unattended outage, whose trigger is disconnected from the moment the user saw the error.** Evidence: `bin/sc:2149` writes `config.json`, `:2154` records the digest, `:2156` runs the checker, and `:2158-2160` returns failure, so `reload_or_restart()` (`:2178-2182`) never reaches `restart_service()`. The daemon therefore keeps serving its in-memory previous configuration while `/etc/sing-box/config.json` holds a document `sing-box` refuses — and `systemd/sing-box.service:9` reads exactly that file at every start, with `Restart=on-failure` / `RestartSec=5` at `:11-12`. The next start of any kind loads the rejected document and fails: a reboot, a crash, `sc on`, or — unattended — the weekly timer, because `cmd_update_rules()` restarts the service on `changed and not gained` (`bin/sc:3400`, `:3415-3420`) **without** regenerating, which is the ordinary weekly case. The drift half is the milder half: the record is literally true ("what `sc` last wrote"), and `sc doctor` still reports the invalidity through its independent checker row (`:2662-2684`) — what the baselined record removes is the one signal that the file on disk is not the trusted one. **The harm is in the write, not in the record**, which is what shrinks the fix to the ordering. |
| Q-2 | Are R-70 and R-73 one design or two? | **One.** Both are the same six lines and the same single judgement — "what does the checker say about this document, and what does the run do with each possible answer". Today that judgement has two answers (accepted / rejected), no third, and sits **after** the irreversible act. The fix is to move it ahead of the act and give it its third arm; fixing R-70 alone would place a guard on a call the R-73 fix then moves, i.e. two edits to one region — rule 85's duplicated-judgment test, not its patch-then-patch test. Binding on stage 2: one design, one call site, three arms, one ordering. |
| Q-3 | Does R-81 ride along? | **No — it is not one line, and it is a different seam.** `stored_delays()` (a Clash-API reader) would need a widened return, and both call sites (`sc ls`, `sc doctor`) would each need a rendering decision, or the new distinction is computed and unconsumed — rule 85's first test, failed. Leave R-81 filed; it does not touch config installation. |
| Q-4 | Does this change touch R-100's path? | **No, and it narrows it.** The change lives inside `generate_config()` and adds no exception that can escape it; `cmd_update_rules()`'s recovery arm, its one determination and its outcome block are untouched. It **removes** three uncaught-exception aborts (missing binary, unexecutable binary, undecodable output) that today leave that run with no outcome line at all, so R-100's population shrinks. T-29's decline stands; do not re-open AC-19. |
| Q-5 | Does the change add or move an unwind (R-12)? | **It moves one and removes three.** The rejection unwind keeps its shape — one stderr line, a `False` return, the callers' existing exits and outcome lines — and only its position changes, from after the write to before it. The three removed unwinds are the traceback paths of Q-4. R-12 stays narrowed and is not widened. |
| Q-6 | Is the minimal fix just moving the digest record below the checker call? | **No — that answer is forbidden.** It leaves the rejected document installed (the severe half of Q-1) and makes the drift judgement report *drifted*, whose one rendered sentence tells the user their own edit changed the file and to move it into the override — an accusation against the user for a write `sc` itself performed. The requirement is FR-2: the rejected document must not reach `config.json` at all, which is also what keeps the file, the record and the running service one consistent statement. |
| Q-7 | What happens when the checker cannot be consulted at all? | **Install, record, warn, succeed** (FR-4). "Cannot validate" is not "invalid": that judgement already exists in this codebase — `sc doctor` reports a missing binary as a problem in its own row while its check row reads *unknown*, never *invalid* (`bin/sc:2559-2563`, `:2659-2661`, `:2664-2667`) — and forming the opposite opinion here would be a second opinion about one fact. A document was produced; only the verdict is missing. `install.sh` is unaffected either way: it installs the binary before the run that generates the first configuration. |
| Q-8 | May the fix parameterise or wrap the existing writer / checker? | **No.** `shared-singbox-check-wrapper` and `shared-atomic-write-helper-with-ruleset-downloader` are both recorded declines; a validate-hook parameter on the credential writer is the exact shape the second one refused. The credential writer keeps its single job and its five guarantees (BC-7), and any transient object inherits every one of them (BC-1). If stage 2 believes a shared shape is now correct, it re-opens the decline explicitly per the decision policy rather than sliding past it. |
| Q-9 | Does the checker call's locale-dependent pipe decode belong in this task? | **Yes, for this site only.** It is the same expression FR-1 moves and FR-5 rewrites; leaving it is the patch-then-patch seam, and the neutralising shape already exists at the doctor's own invocation. R-99's second site and its `install.sh` half stay filed. |
| Q-10 | Does `generate_config()`'s boolean change meaning? | **No.** It keeps meaning "a configuration was produced and installed": `False` for a rejected document and for a write that failed, `True` for accepted and for cannot-validate. T-19's folding of "regenerated + checked" into that one boolean stays valid, and `sc update-rules`' determination is unchanged. |
| Q-11 | Schema gap: the dispatch requires the true-consequence answer and its evidence in the contract, but the contract schema declares no evidence section. | Recorded as a schema-gap row per the stage-doc boundary rule's precedence clause: the answer is carried by **Q-1** above, with backward-looking `path:line` citations (exempt from the forward-looking anchor ban), and the full measurement narrative lives in `01_RATIONALE.md`. No section was invented. |
| Q-12 | Does a new glossary term get coined? | **Yes, one: "checker verdict"** — the three-valued result of consulting `sing-box check` on a document (accepted / rejected / cannot-validate). Recorded in `CONTEXT.md`; no other term is coined and none is redefined. |

## Verdict

READY
