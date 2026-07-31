# PM Log — install-binary-download-progress (T-08)

- Mode: `full` (7 stages)
- Started: 2026-08-01
- Dispatch source: owner, deferred-human mode (`defer, do not ask`), standing decision authority granted
- Developer mode: **single** (`.harness/agents/dev-*.md` → none found)

## Pre-flight

- `.harness/intervention.md` — checked before stage 1 dispatch: **absent** (no pending intervention).
- `.harness/insight-index.md` — read, 15 entries. Entries surfaced to downstream dispatches:
  - L10 `install.sh`'s `t()` uses `local fmt` with no default → a key present in only one language
    branch **aborts the installer under `set -u`**; zh branch reachable only by answering `2`, so an
    English-only test run cannot detect it. → surfaced to **Analyst, Architect, Developer, QA**.
  - L12 Under `set -euo pipefail`, redirecting to an unwritable path fails *before* the command runs;
    a `tee` pipeline lets a logging fault flip a healthy phase under `pipefail`. → surfaced to
    **Architect, Developer** (bears on any progress-output redirection).
  - L13 `bin/sc`'s import-time auto-elevate re-execs the **installed** `/usr/local/bin/sc` → the live
    service incident. → surfaced to **Developer, QA** as the safety discipline for this task.
  - L14 chunked-read progress emits exactly one redraw for a body under the chunk size → progress
    fixtures must exceed the buffer. → surfaced to **QA** (analogue: curl's meter refresh interval).
  - L21 `archive-task.sh` harvests only the FIRST physical line of an `## Insight` bullet → PM keeps
    delivery bullets on one physical line.
- `docs/tasks.md` — related historical work:
  - **T-02** `config-degrade-missing-rulesets` — shipped the *ruleset* half of the owner's progress
    requirement in `bin/sc` (chunked read, byte/percent, `sys.stdout.isatty()` gating). This task is
    the `install.sh` half; **match visual language, do not share code** (Bash/curl vs Python/urllib).
  - **T-01** `install-enable-start-split` — reworked `install.sh` (`$LOG_SINK`, `PHASE_*`,
    `install_report()`). Step 2 is upstream of the phase model; must not be disturbed.
  - **T-10**, **T-09** — `bin/sc` / `systemd/` only; out of scope here.
- `docs/dev-map.md` — read for module ownership before stage 4.

## Stage transitions

| # | Stage | Agent | Verdict | Route decision |
|---|---|---|---|---|
| 1 | Requirement | requirement-analyst | `READY` — 20 AC, 18 BC, 10 recorded decisions, 0 open questions | **Advance to stage 2** |

### Stage 1 → 2 (2026-08-01)

Analyst returned `READY` with no blocking questions — correct under deferred-human mode; every
ambiguity was resolved as a *recorded* decision (D-1…D-10) rather than a silent guess, which is
exactly what the standing authority asks for. Nothing approached a safety red line, so no
`BLOCKED: NEEDS-HUMAN`.

Points I am carrying forward into the architect's brief because they are design-shaping, not
merely informational:

- **D-1 (`[ -t 2 ]` not `[ -t 1 ]`)** is a correctness claim about which stream curl's meter uses.
  The architect must independently confirm it rather than inherit it — if it is wrong, the whole
  degradation contract is wrong.
- **D-4** grants the five remote artifacts a name line but no meter; **D-5** leaves the GitHub API
  query meter-free with a written justification. Both discharge the owner's 「每个下载部分」
  obligation by *justifying* silence rather than skipping it. Gate should test that justification.
- **BC-10** records a curl 7.29 option floor (bans `--no-progress-meter`). This constrains the
  implementation and is the kind of claim stage 3 should verify against a real curl.
- The analyst surfaced a **new finding, deferred not dropped**: `install.sh:456` redirects
  `sc update-rules` to `$LOG_SINK`, so T-02's ruleset progress has never been visible to an
  installing user. Out of scope here (un-redirecting breaks T-01's design; a `tee` is barred by
  insight L12). Re-homed to `.harness/rejected-decisions.md`; I will surface it at delivery for the
  owner to number as a pool row. **PM note:** this is the correct handling — it is a second
  requirement, not this one.

Checked `.harness/intervention.md` after stage 1: absent.

| 2 | Design | solution-architect | Design written; **requirement defect R-D reported**, non-blocking | **Rollback 1 → stage 1** (targeted correction), then resume at stage 3 |

### Stage 2 → 1 rollback (2026-08-01) — rollback #1

The architect delivered a complete design AND independently confirmed D-1 (curl's meter is a stderr
artefact, and curl does **not** self-gate on `isatty(stderr)` when `-o <file>` is in play — leg two
is what makes the `[ -t 2 ]` gate necessary rather than cosmetic). It also supersedes
`BATCH_PLAN.md:46-47`, which had proposed `[ -t 1 ]`. That is exactly the independent verification
I asked for, and it changed a fact.

It also reported **R-D: a factually wrong justification inside `01_REQUIREMENT_ANALYSIS.md`** (one
of D-5's three legs), and separately found a live bug the wrong leg was concealing.

Routing decision: **rollback to requirement-analyst**, scoped to a correction — not a re-analysis.
Rationale:

- Hard rule 2. Downstream cannot edit upstream documents. The architect correctly reported instead
  of editing. Only the analyst may fix the requirement text.
- The defect is *non-blocking* (D-5's conclusion survives on its other two legs), so this is a
  cheap, targeted fix — but leaving a known-false statement in the contract document is not an
  option: stage 3 reviews requirement + design holistically and would flag it, costing a rollback
  later at higher price.
- I am bundling the architect's three AC-interpretation questions (R-A, R-B, R-C) into the same
  dispatch. Those are questions about **what an acceptance criterion means**, and only its author
  can answer authoritatively. Resolving them now prevents QA and the developer from testing to two
  different readings of AC-6 and AC-9.

Scope of the correction is explicitly fenced: no new AC, no scope change, no fix to the live bug
(which is a separate requirement and must be re-homed, not absorbed — rule 85's counter-rule).

Checked `.harness/intervention.md` after stage 2: absent.

| 1' | Requirement (correction) | requirement-analyst | R-D fixed; D-5 conclusion survived; R-A/R-B/R-C answered as D-11/D-12/D-13 | **Resume at stage 3** — no design revision needed |

### Stage 1' → 3 (2026-08-01)

The analyst verified R-D against the real source rather than accepting the architect's report, and
confirmed it — then sharpened it twice: the abort is **not literally silent** (`-S` still prints
curl's raw English one-liner), and it exits **1**, the same status as the properly diagnosed path,
so a caller cannot distinguish the two. It retracted the false sentence explicitly instead of
quietly rewriting it, which is the honest form.

I am **not** re-dispatching the architect. Every one of the corrections ratified a reading the
design had already adopted: D-5's conclusion survived intact, and D-11/D-12/D-13 confirm R-A/R-B/R-C
exactly as the architect proposed (including S-7's diff-shape substitution for AC-10/AC-11). The
design's conclusions are unchanged, so a revision pass would produce no delta and cost a stage.
Stage 3 reviews requirement + design **holistically** and will catch any drift between the two
documents that I have misjudged here — that is the checkpoint's job, and it is the right place to
absorb this risk rather than spending a rollback on speculation.

The live bug (`VAR=$(pipeline)` abort at `install.sh:352`) is **re-homed, not absorbed** — §4 item
11 plus `.harness/rejected-decisions.md` record `installer-version-query-silent-abort`. Correct
call: it is honest-failure-reporting, not download progress, and absorbing it would violate rule
85's counter-rule. I will surface it at delivery for the owner to number.

Noted for the delivery insight harvest: the analyst flagged `VAR=$(pipeline)` abort semantics under
`set -euo pipefail` as a cross-task truth candidate. Index is at 25/30 lines — I will be selective.

| 3 | Gate | gate-reviewer | **`APPROVED FOR DEVELOPMENT`** — 0 FAIL / 6 WARN / 4 INFO, conditions C-1…C-8 binding | **Advance to stage 4** (stage gate satisfied) |

### Stage 3 → 4 (2026-08-01)

**Stage gate satisfied**: explicit `APPROVED FOR DEVELOPMENT` verdict, no FAIL in any of the eight
dimensions, no rollback requested.

**Tooling note.** The gate-reviewer agent runs read-only (Read/Glob/Grep) and could not create its
own document. It returned the full review inline and I persisted it verbatim to
`03_GATE_REVIEW.md` with a provenance header. I edited none of the content — persisting a
downstream agent's output is bookkeeping, not authorship.

**It audited my stage-2→1' routing call, as instructed, and upheld it** — checking all seven
corrected items against the design independently and concluding a re-dispatch would have produced a
byte-identical design. That is the check I wanted; the call is no longer resting on my judgment alone.

Three things I am carrying into the developer's brief because they are the difference between a
green run and a *vacuously* green one:

- **C-1 / F-3 is the one place where "stop and escalate" is the correct developer behaviour.** The
  curl 7.29 `--progress-bar` floor claim is now unverified after three stages, and no stage so far
  had an execution tool. If an unknown option makes curl exit 2, step 2 fails outright on
  RHEL/CentOS 7 — invisible on a modern box, fatal on the oldest supported distro. The reviewer's
  corroboration (`-#` predates 7.29 by ~a decade, and the three options BC-10 bans are all
  post-floor) lowers the probability but is explicitly **not** a substitute for evidence. I am
  passing C-1's escalation clause through verbatim.
- **The predicted failure mode is the harness, not the diff.** ~14 product lines against a stub
  server, a fragment extractor and a PTY driver. Named vacuous-green modes: an anchored `sed`
  extract that silently yields nothing; a fixture too small/fast to force a redraw (insight L14,
  the T-02 precedent); and `script -qec`, which **cannot express BC-3** (stdout TTY, stderr
  redirected) and would report PASS while leaving the gate's central claim untested.
- **C-5 + insight L22**: the AC-20 live-system witness must be `systemctl show -p MainPID -p
  ActiveEnterTimestamp`, never `is-active` — `is-active` prints `active` on both sides of a restart
  and would have passed *during* the T-02 incident it was written to catch.

**F-11 is cross-task and I am taking it off this task's back.** The committed key-parity gate has
now been deferred three tasks running, and `rejected-decisions.md:57-73` says so in its own text.
Deferring again is *correct* here (AC-19 fences the diff to product paths), but the debt is mine to
carry to the owner at delivery, not the developer's to absorb.

Checked `.harness/intervention.md` after stage 3: absent.

| 4 | Development | developer (single mode) | `READY FOR REVIEW` — C-1…C-8 discharged, `verify_all` 16/0/0/2 zero delta | **Advance to stage 5** (stage gate satisfied) |

### Stage 4 → 5 (2026-08-01)

**Stage gate satisfied**: `verify_all` PASSED in the development doc — `PASS 16 / WARN 0 / FAIL 0 /
SKIP 2`, identical to baseline (zero delta).

**C-1 was discharged properly, which is the outcome I was least confident of.** The developer did
not settle the curl 7.29 floor against this box. It fetched the **official curl 7.29.0 release
tarball** (`https://curl.se/download/archeology/curl-7.29.0.tar.gz`), version-dated the artifact
from `include/curl/curlver.h:33`/`:67` (`7.29.0`, timestamp 2013-02-06), and located
`--progress-bar` inside it at `src/tool_getparam.c:260`, `:863`, `src/tool_help.c:146`,
`docs/curl.1:112`. It also confirmed the three BC-10-forbidden options are absent from that tree,
and proved **on the floor version** that `-s` beats `--progress-bar`
(`tool_operate.c:1123-1124` + `tool_getparam.c:1481-1484`) — so `CURL_OPTS_QUIET` cannot leak a
meter on RHEL 7 either. The escalation clause did not need to fire.

It also surfaced a trap worth more than the answer: the obvious shortcut — the `curl-7_29_0` **git
tag** — is *not* a valid version-dated source, because `curlver.h` at that tag still reads
`7.28.2-DEV`. That is a genuine insight-index candidate.

**The gate's prediction was right: the harness was the hard part.** It caught **three vacuous-greens
on itself**, one of which had already produced a *false PASS* (a server restart moving the ephemeral
port). The other two: the host's real `sing-box` on `PATH` short-circuiting step 2 entirely, and a
cooked-mode pty injecting CR into every capture. Three negative controls prove the tests can fail.
BC-3 (stdout TTY, stderr redirected) was expressed and measured `0 × 0x0D` — the exact case the gate
warned `script -qec` could not express.

**PM decision — `docs/dev-map.md` NOT updated.** The developer correctly declined to take this
unilaterally and asked. My call: **do not update it.** dev-map documents *project structure*, and no
structural change occurred — two shell arrays inside an existing file are not structure. It is also
not in AC-19's carve-out (`docs/features/**`, `CONTEXT.md`, `.harness/**`), so editing it would
widen the shipping diff and fail the very criterion the gate made binding as C-3. The T-07 pointer
at `CURL_OPTS_QUIET`/`CURL_OPTS_PROGRESS` is genuinely useful and is **re-homed, not dropped** — I
will carry it into `07_DELIVERY.md` where it costs no product diff. Declining to widen the diff was
the right instinct.

One honest refinement the developer volunteered rather than hid: under design C-3 the progress
variant's stderr is **one byte longer** (a bare trailing `\n`); the error *text* is identical. Flagged
to the code reviewer as an AC-6 byte-identity question rather than assumed benign.

Checked `.harness/intervention.md` after stage 4: absent.

| 5 | Code review | code-reviewer | **`APPROVED`** — 0 CRITICAL / 0 MAJOR / 2 MINOR / 5 NIT | **Advance to stage 6** — nothing returns to the developer |

### Stage 5 → 6 (2026-08-01)

Read-only tools again; review returned inline and persisted verbatim to `05_CODE_REVIEW.md` with a
provenance header.

The reviewer did the two things I most wanted and would not have accepted on assertion:

1. **It re-derived the bilingual parity claim itself** rather than trusting the developer's S-6
   output — extracting both `case` blocks and confirming 41 keys, identical names in identical order,
   `fetching_item` as the 5th entry of each (`install.sh:149` zh / `:193` en). This is the one defect
   class that ships a **dead installer** reachable only by answering `2`, so an independent
   re-derivation is worth its cost.
2. **It re-verified C-1 off the same version-dated artifact**, which was still on disk — reaching the
   same conclusion via `curlver.h:33`, `tool_getparam.c:260`, and additionally proving on the floor
   version that `-s` sets `mute=noprogress` (`tool_getparam.c:1484`) gated at
   `tool_operate.c:1124`, and that `-S` without `-s` is inert (`tool_operate.c:191`). Two independent
   readers, one artifact, same answer. The project's highest-consequence unverified claim is closed.

**The one-byte discrepancy is resolved, and correctly.** I asked for a derivation rather than a
"cosmetic" hand-wave and got one: the extra byte is an **LF, not a `0x0D`**, it exists only when
`--progress-bar` is in the argv, and nothing rebinds fd 2 between the gate at `:130` and the transfer
at `:384` — so it can only ever reach a **terminal**, never a log. AC-6's byte-identity clause is
scoped by D-11 to the non-TTY capture, which came back byte-identical at 49 bytes. Not a defect and
not a waiver. Worth recording that design C-3's prediction was true of the *text* and false of the
*bytes*, and the developer corrected the design's wording rather than restating it.

**Two MINORs, neither routed to the developer** — I accept both routings:

- **dev-map row** → routed to **PM**, and it lands where I had already put it: my stage-4 decision
  declined the edit because `docs/dev-map.md` is not in AC-19's carve-out, and the reviewer
  independently reached the same conclusion (editing it would be a *literal* AC-19 breach). Carried
  to `07_DELIVERY.md` for T-07.
- **AC-2's evidence form** — `verify_all` counts asserted in prose, not a pasted capture. Correctly
  flagged as "do not treat as discharged"; stage 6 re-runs `verify_all` by charter, so I am passing
  this to QA as an explicit obligation rather than letting it dissolve.

**F-11 escalates**: the committed key-parity gate is now **four** tasks deep, and the reviewer names
it "the highest-leverage open debt touching this file". Still correctly out of scope (AC-19 forbids
the diff), still mine to carry. It goes to the owner at delivery with the count attached.

Checked `.harness/intervention.md` after stage 5: absent.

| 6 | QA | qa-tester | **`PASS`** — 39 scripted assertions + 5 probes, 0 product defects | **Advance to stage 7** (both stage-7 gates met) |
| 7 | Delivery | PM | `07_DELIVERY.md` written; board updated; archived | **DELIVERED** |

### Stage 6 → 7 (2026-08-01)

**Stage-7 gate satisfied**: stages 5 and 6 both PASS.

QA discharged every obligation I handed it **with pasted output**, and did not report the
developer's transcripts as its own:

- **AC-2**, which the code reviewer explicitly refused to treat as discharged, is now backed by a
  real `verify_all` capture: `PASS 16 / WARN 0 / FAIL 0 / SKIP 2`, delta **0** against a pristine
  `HEAD` clone. It also found the methodology trap underneath it — a `git worktree` is *not* a valid
  baseline here (`.git` is a file, A.1/A.2 turn SKIP, summary falsely reads `14/4`).
- **AC-8** was taken further than asked: rather than accept the `LANG_CHOICE` preset substitution, QA
  drove the **real language prompt** with `2` and asserted zero `unbound variable` hits on both
  streams. That is the strongest available form of the insight-L10 check.
- **The one-byte delta was tested, not re-derived**, per my instruction — measured as `0x0a`, and off
  a TTY the failure stderr is byte-identical to pre-change.

**I asked QA to assume a fourth vacuous green existed. There was one**, and it is the most valuable
finding of the stage: `mkfixture.py` and insight L14 both attribute AC-3's non-vacuity to the 8 MiB
fixture **size**, but decomposition shows `8 MiB / sleep=0 → states=1` — identical to a 1 KiB body.
The **throttle** is the carrier, and nothing guards it. Today's PASS is real; drop the `sleep` and
AC-3 goes vacuous silently. It also caught two vacuous greens in its *own* new work and discarded
them before reporting (a `$(...)` tty probe that redirects fd 1, and a `bash … & ; kill -INT`
Ctrl-C test defeated by POSIX async SIGINT-ignore). Six caught across the task, one of which had
already produced a false PASS.

**No product defects. No rollback target. 1 rollback total for the task**, at stage 2→1'.

### Delivery (stage 7)

- `07_DELIVERY.md` written; `docs/tasks.md` updated with the T-08 row **and** five numbered open rows
  under `## Notes` for the owner — every deferred item is re-homed, none dropped.
- **Live-system witness taken a third time at delivery**, independently of developer and QA:
  `MainPID=2500438`, `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST` — identical. Insight L13's
  incident class did not recur.
- **Entropy watch: not run.** The task mode is `full`, so the cadence applies, but this project ships
  no `.harness/scripts/entropy-cadence` pair. Per the cadence's fail-open rule, a missing script
  resolves to **NOT-DUE**: no scan, no `## Entropy watch` section, delivery verdict unchanged.
- **Insight harvest: 4 bullets**, index at 24/30 lines so there is room, each one physical line
  (insight L21). Selected against the rule-05 bar — each cost real time to learn and none is
  derivable from the codebase in ten minutes: the curl git-tag-vs-release-tarball trap, the
  worktree-baseline trap, the throttle-not-size correction to L14's reading, and the
  `VAR=$(pipeline)` abort that bypasses `install_report()`. Deliberately **not** harvested: the POSIX
  async-SIGINT behaviour (general knowledge, not project truth).
- **Not committed, not pushed** — the owner owns delivery, as instructed.

Checked `.harness/intervention.md` after stage 6 and before delivery: absent both times.
