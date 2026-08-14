# PM Log — T-18 / status-egress-via-clash-api

Mode: **full** (7 stages). Dispatched by `/harness-batch`, pool `default`.
Decision authority: owner's standing grant (「你来决策就行」). `BLOCKED: NEEDS-HUMAN` reserved for a
genuine safety red line only; a red-line-adjacent call ships on the grant **and is surfaced in
`07_DELIVERY.md`** (T-17 precedent).

## Pre-flight (PM, 2026-08-14)

- `.harness/intervention.md` — **absent**. No pending intervention. Re-checked at every stage boundary below.
- `.harness/scripts/task-state.js` — **does not exist on this host**. Fail-open: stage/round counters
  tracked in this log by hand (T-16 / T-17 precedent).
- `.harness/scripts/entropy-cadence` — **does not exist on this host**. Fail-open ⇒ NOT-DUE ⇒ no
  entropy scan, no `## Entropy watch` section at delivery.
- `docs/tasks.md` read: 298 lines (F.5 cap 300). No T-18 row existed; added under Active tasks.
- `.harness/insight-index.md` read: **31 lines** — already over the F.4 cap of 30 before this task
  harvests anything. Hand-rotation into `docs/features/_archived/insight-history.md` is required at
  delivery regardless of what T-18 adds (R-18, now confirmed a sixth time).
- Baseline `verify_all.sh` launched before any edit; result recorded at stage 4/6.

## PM context notes handed to stage 1 (pointers to verify, NOT conclusions)

The PM read `bin/sc` at HEAD to write an accurate dispatch. Everything below is a **pointer the
analyst must verify or refute first-hand**; none of it is a requirement or a ruling.

1. The batch goal's stated cause ("assumes a local inbound that does not exist") does not obviously
   match HEAD: `cmd_status`'s egress block calls `_egress_ip()` (`bin/sc:391-400`), which is a plain
   `urllib.request.urlopen("https://api.ipify.org", timeout=8)` with **no proxy argument**. `git log
   -S ipify -- bin/sc` shows this shape in the **first** commit of `bin/sc` (`41ffd08`) and in every
   commit since. T-16's precedent applies directly: **measure before designing against it.**
2. The goal's second clause ("bare traceback when it fails") does appear real, but two lines above
   the egress block: `cmd_status` calls `clash_api("GET", "/configs")` (`bin/sc:2230`) unguarded, and
   R-20 enumerates four exception classes that escape `clash_api()`'s `except (URLError, HTTPError)`.
3. Rule-85 "no second opinion": `sc status` and `sc doctor` **already** share `_egress_ip()` (T-05
   extracted it, commit `1b1b0e0`), and `docs/dev-map.md:67` pins it as the single query. Whether
   anything remains to unify here is the analyst's ruling.
4. The slug says "via clash api" — whether sing-box's Clash API can report an egress address at all
   is an unmeasured capability. Measure it (read-only) rather than design against it.

## Stage log

| # | Stage | Round | Dispatched | Verdict | Route |
|---|---|---|---|---|---|
| 1 | requirement-analyst | 1 | 2026-08-14 | **READY** — 10 ACs (5 `[B]`, 5 `[S]`) | → stage 2 |
| 2 | solution-architect | 1 | 2026-08-14 | **READY** — 3 files, ~15 lines, single-developer mode | → stage 3 |
| 3 | gate-reviewer | 1 | 2026-08-14 | **APPROVED WITH CONDITIONS** — C-1 … C-14 binding | → stage 4 |
| 4 | developer | 1 | 2026-08-14 | **READY FOR REVIEW** — `verify_all` PASS 17/0/0/1 | → stage 5 |
| 5 | code-reviewer | 1 | 2026-08-14 | **APPROVED WITH MINOR** — 0 MAJOR, 2 MINOR, 5 INFO | → stage 4 (CR-1 repair) |
| 4 | developer | 2 | 2026-08-14 | **READY FOR REVIEW** — CR-1 + CR-6 repaired, `verify_all` PASS 17/0/0/1 | → stage 6 |
| 6 | qa-tester | 1 | 2026-08-14 | **APPROVED FOR DELIVERY** — 262 observations: 260 pass, 0 fail, 2 blocked | → stage 7 |
| 7 | PM | 1 | 2026-08-14 | **DELIVERED** | archive + commit |

### Stage 6 → 7 (advance)

`.harness/intervention.md` re-checked: absent — no intervention was pending at any of the eight
boundaries this task passed.

QA rebuilt its rig from scratch rather than inheriting stage 4's, as the standard here requires.
**262 declared observations: 260 pass, 0 fail, 2 blocked**, plus 121 stability repeat-runs and 3
independent echo queries. The non-vacuity evidence is the part that matters: across 204 fixture runs,
runs that talked to a port other than their own stand-in = 0, runs that opened no Clash URL = 0, runs
that touched the live port = 0 — so all three vacuity traps (K-10, K-11, and the gate's own
C-9/F-7 `CLASH_PORT` trap) were live and all three were survived.

**AC-B1/AC-B2 BLOCKED, and the PM accepts that as the honest outcome rather than routing back.**
All five NFR-3 preconditions held and were recorded first; the *enabling* condition failed —
`sudo -n true` → "a password is required", with no interactive terminal, and running non-root would
have taken the import-time re-exec into the **installed** `/usr/local/bin/sc`. QA reported it blocked
and did **not** substitute an artifact check, which is exactly what C-12 and NFR-5 demand and the
opposite of the T-15 failure R-22 records. No downstream stage can fix a missing sudo credential, so
a rollback would buy nothing; filed as **R-31**, an operator obligation, on the R-30 precedent. The
behavioural goal itself *was* observed by another route (egress `38.47.117.142` agreeing with three
independent echo endpoints, route mode read back as `Rule`, witness delta none) — recorded in
`07_DELIVERY.md` with the distinction between what that proves and what it does not.

**C-3 discharged on evidence:** T-05's DEF-2 closed, `BC-1 candidate → exit=1 with the port row
present` vs `control → exit=2 with it lost`.

**Four things QA found that four upstream stages missed**, two of them new defects (QA-D1 stdout
buffering reorders `sc status > file`; QA-D2 the one-line-per-heading promise is falsifiable by a
newline in the mode value — the R-22 shape once more), one a sixth escaping class (`BadStatusLine`),
and one a correction to CR-3's *mechanism* (the split is by how the peer closes: RST →
`ConnectionResetError`, clean FIN → `RemoteDisconnected` — three distinct close behaviours, not two).

### Stage 7 — delivery actions (PM)

- `07_DELIVERY.md` composed with `## Summary`, `## Insight` (4 one-line entries), `## Verdict`.
- **Entropy watch: omitted.** `.harness/scripts/entropy-cadence` **does not exist on this host**, so
  the cadence check fails open ⇒ NOT-DUE ⇒ no scan, no `## Entropy watch` section, no digest. Same
  fail-open as `.harness/scripts/task-state.js`, absent throughout (stage counters kept here by hand).
- `docs/tasks.md`: T-18 moved to Completed; **R-20 marked closed** with its full row text rotated to
  `docs/tasks-archive.md` alongside how it closed; **T-17's completed row rotated** to the archive;
  three stale section intros compacted. Five new open rows filed (**R-31 … R-35**). Result **298/300**.
- `.harness/insight-index.md`: `archive-task.sh` harvested 4 and left it at **34/30** — **R-18
  confirmed a sixth time**, its rotation branch still counting bullets while F.4 counts lines.
  Hand-rotated 4 entries into `docs/features/_archived/insight-history.md`, chosen by rule 70's "what
  no longer earns its line": the superseded T-15 `clash_api()` entry (its defect is now fixed and the
  index carries the deeper `do_open` mechanism that explains why its enumeration was short) plus
  three narrow dns/telemetry fixture details. Back to **30/30**.
- **R2 discharged:** `.harness/rejected-decisions.md` gained
  `## clash-api-bare-except-and-leaf-enumeration`, recording both declined shapes with the tested
  purchase — the record the architect could not write because `.harness/**` was outside the task diff.
- `docs/dev-map.md` updated in-task (E3, one row). No structural change beyond it.
- `archive-task.sh --task status-egress-via-clash-api` run: stage docs moved to
  `docs/features/_archived/status-egress-via-clash-api/`, exit 0.
- Final `verify_all.sh`: **PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — batch baseline preserved.
- `guard-rm.sh` blocked two more commands this task (a `cat >>` heredoc and an append), on commands
  containing no `rm`, by misparsing them as a nested pwsh command — **now five occurrences on
  record**. Worked around with the Write/Edit tools; the `HARNESS_ALLOW_OUTSIDE_RM` bypass was never
  set. The commit itself used `git commit -F <file>` for the same reason.

### Stage 1 → 2 (advance)

Baseline `verify_all.sh` measured **before** any edit: `PASS 17 / WARN 0 / FAIL 0 / SKIP 1` — matches
the batch baseline stated in the dispatch. `.harness/intervention.md` re-checked: absent.

The analyst refuted the batch goal's **first** clause with evidence rather than implementing it
(Q-1): `_egress_ip()` has no proxy argument in any commit of `bin/sc` back to `41ffd08`, and in pure
TUN the request is captured by the TUN device like any other — so there is no local-inbound
assumption to fix. AC-S1 freezes `_egress_ip()` byte-identical so no downstream stage "fixes" the
phantom. The goal's **second** clause is real and lands at `bin/sc:2230`.

Rulings the PM asked for, all delivered explicitly:
- **R-20 claimed and closed by T-18** (Q-3): one envelope at `clash_api()` discharges all six call
  sites; AC-S2 forbids a second `try`/`except` at any caller. This is the whole task.
- **R-29 declined** (Q-5) with the promise *narrowed to match* (FR-3 scoped to the two remote
  dependencies; BC-13 states the state-file class is unchanged including its traceback). Q-5 also
  hands the PM a delivery obligation: R-29's family statement names two readers and should name
  three — `load_nodes()` is the third, called unguarded by `cmd_status`.
- **R-12 declined** (Q-6) — no `sys.exit` added or removed; FR-1 moves toward the invariant.
- **"via clash api" declined** (Q-4) on three independent grounds, only the first a measurement, so
  the ruling does not rest on the unmeasured one. The slug is an identifier, not a design.
- **Nothing left to unify** with `sc doctor` (Q-7).

A **fifth, unfiled** escape class was found by reading `clash_api()`'s callers: a 2xx body decoding
to non-object JSON is returned as-is, so `sc status` raises `AttributeError` on `.get()` and
`cmd_use` prints a switch line for a switch that never happened. R-20 as filed enumerates four.

R-22 discharged by AC-B1/AC-B2, which can only be satisfied by running the candidate on this live
host. Q-13 flags that as red-line-adjacent by construction and bounds it with five preconditions
plus an mtime+size witness. Per the T-17 precedent it ships on the owner's standing grant and is
**surfaced at delivery** rather than blocking the batch. Recorded here at first appearance.

### Stage 2 → 3 (advance, with two upstream defects routed to the gate rather than rolled back)

`.harness/intervention.md` re-checked: absent.

Design: `clash_api()` catches `(OSError, ValueError, http.client.HTTPException)` and returns the
decoded body only through one `isinstance(body, dict)` gate applied *after* the empty-body `{}`.
3 production files, ~15 lines, no net new import (`import urllib.error` becomes dead and is deleted;
`import http.client` takes its place). No call site moves. Single-developer mode confirmed — no
`.harness/agents/dev-*.md` exists.

Rule-85 burden of proof discharged as required: the architect names **`except Exception`** as the
*smaller* rejected alternative (one word, no import, one line smaller) and says what the extra line
buys — a genuine defect inside `clash_api()` stays a traceback instead of being reported to the user
as `[PROBLEM] Clash API responding`, i.e. `sc doctor` lying about the host to cover a bug in `sc`.
Grounded in two written project positions (`stored_delays()`'s docstring `bin/sc:2019-2022`;
`README.md:268`). It also rejected the *larger* leaf enumeration as incomplete the day it ships.
Hierarchy facts read out of the installed stdlib rather than recalled.

**Two upstream defects found by stage 2. Neither rolled back to stage 1 — both routed to the gate,
which is the independent verifier of requirement and design together, and R1 is a request to *widen*
a boundary condition rather than a contradiction of it:**
- **R1 — BC-14 is too narrow.** Making `clash_api()` total necessarily changes `sc doctor` for
  BC-1…BC-4 too, not only BC-5: today they raise inside `_doctor_clash()`, are caught by
  `cmd_doctor`'s per-section isolation, collapse the section into one `[UNKNOWN]` row **losing the
  port row already built**, and exit 2; under this design they yield the port row plus `[PROBLEM]
  Clash API responding` and exit 1. **PM note for the gate: that lost port row is T-05's shipped-open
  DEF-2** (a hung Clash port loses S6's port row), which this design would close as a side effect —
  the gate should rule whether T-18 may claim it.
- **R4 — AC-S2 says "six call sites"; there are five literal ones** (`sc ls` reaches the function
  indirectly via `stored_delays()`). The criterion holds under either reading; only the count is wrong.

R2 travels to the PM: the two declined exception shapes merit a `.harness/rejected-decisions.md`
record, but `.harness/**` is outside NFR-2's permitted diff, so no stage in this task may write it.
To be handled post-delivery, outside the task diff.

### Stage 3 → 4 (advance; both stage-2 residuals ruled at the gate, no rollback)

`.harness/intervention.md` re-checked: absent. **Transcription check before writing:** the gate holds
no write capability and returned two bodies under a header naming both target paths. Each was checked
to begin with its declared opening line and the contract to end with its `## Verdict` line; no
partial return was reported. Both were written **verbatim** to `03_GATE_REVIEW.md` and
`03_RATIONALE.md` — no heading added, no section completed, no round record inserted.

Verdict **APPROVED WITH CONDITIONS**, C-1 … C-14 binding. The stage-4 precondition (an explicit
approval at stage 3) is satisfied.

**Both stage-2 residuals ruled here rather than by a stage-1 round, and the gate justified the
choice rather than assuming it:**
- **R1 → C-1.** BC-14 is widened at the gate to read "`sc doctor` meets BC-1 … BC-5". The gate
  reproduced the mechanism first-hand (`_doctor_clash()` builds the port row *before* the call that
  raises; `cmd_doctor`'s isolation discards the frame; `DOCTOR_EXIT` maps `UNKNOWN`→2, `PROBLEM`→1).
  No stage-1 round because the change is already *entailed* by FR-2, cannot be avoided without a
  caller edit AC-S2 forbids, and the gate document binds stages 4-7 anyway.
- **T-05's DEF-2 may be claimed closed (C-3)** — but only on V6's BC-1 evidence, not by argument.
  The gate also established the exit-status move creates **no new user-visible contract**:
  `README.md:277-278` already publishes exit 1 = "an unanswered Clash API port", so the change moves
  the binary *onto* the published contract. C-2 pins the qualified wording (2 → 1 only when no other
  section reports `[PROBLEM]`) so nobody states it unconditionally.
- **R4 → C-4.** Five literal call sites confirmed by first-hand search; AC-S2's substance survives
  under both readings, and the count is corrected in place so stage 6 cannot report "6/6 checked".

Dimension 7 is **FAIL** and the gate still approved — deliberately, with its reasoning recorded in
`03_RATIONALE.md` §6: every cause is a statement about how a later stage *observes*, not about what
gets built, so a rollback would return the same design with three table cells edited. The PM accepts
this: C-5, C-7, C-9 correct the criteria in place at stage 6 and are checkable by reading
`06_TEST_REPORT.md`. If stage 6 discharges them and the observations still fail to separate candidate
from control, the requirement is reopened at that point.

**Three defects the gate found that neither upstream document caught** (this is the gate earning its
keep on two otherwise very strong documents):
- **F-7, a third vacuity trap** of exactly the K-11 family: `main()` reassigns `CLASH_PORT`
  (`bin/sc:3125`) just as it reassigns `LANG`, so a fixture whose `settings.json` records no
  `clash_api_port` gets a port that is free *by construction* and the whole BC matrix silently
  collapses to "nothing listening" on candidate **and** control. → C-9.
- **F-3, two unenumerated call-site behaviour changes**: for BC-1…BC-4 `cmd_use` newly reaches
  `reload_or_restart()` (regenerate + restart) and `cmd_mode` newly prints a success line for a mode
  the running process did not adopt. Both are correct (identical to today's refused-port behaviour)
  but must be observed and disclosed, not "fixed". → C-6, C-11.
- **F-1/F-2, a control that HEAD does not exhibit**: `json.loads("null")` yields `None`, so a `null`
  body is an **agreement** state, not a defect state, while `5`/`"x"`/`[1,2]` traceback — and at
  `_doctor_clash()` HEAD returns `[OK] … yes` rather than raising. BC-5 bundled four observations
  with two control classes, which is precisely the trap `insight-index.md:30` records. → C-5.

C-14 is addressed to the **PM** and lands at delivery: R2/R3/R6 must be filed with rule-70 rotation
rather than appended past the `docs/tasks.md` (300) and `insight-index.md` (30) caps.

### Stage 4 → 5 (advance)

`.harness/intervention.md` re-checked: absent. **Stage-5 precondition satisfied**: stage 4 reports
`verify_all` PASS, and the PM re-read the diff first-hand rather than taking the report on trust.

Product diff, verified by the PM against the design: `bin/sc` **+12 / −6** (E1+E2 exactly at K-9's
12-line ceiling, not over it), `docs/dev-map.md` 1 row, `CHANGELOG.md` 1 Chinese bullet. The
`docs/tasks.md` and `docs/batches/default/BATCH_PLAN.md` entries in `git status` are **PM-owned and
pre-existing**, untouched by stage 4; `docs/batches/**` stays unstaged per the delivery policy.

The implemented body is what stage 2 designed and stage 3 conditioned:
`except (OSError, ValueError, http.client.HTTPException)`, with `answer = json.loads(text) if text
else {}` kept first and `return answer if isinstance(answer, dict) else None` after the `try`.
`import urllib.error` deleted, `import http.client` added — import count 15 → 15.

Constraint evidence the PM checked or accepts as measured:
- **K-1** — clause is exactly the three-family tuple; `bin/sc` carries 45 `try:` / 46 `except` at HEAD
  and 45/46 in the candidate, so one clause was rewritten and none added anywhere (AC-S2).
- **K-3 / PA-1** — BC-8 asserted **by value and by type**, which is what PA-1 demanded now that a
  BC-8 regression would be silent rather than loud. BC-1…BC-7 → `None` across 15 states.
- **K-5 / K-6** — `_egress_ip()` AST+sha256 identical on both sides (`78ec7c96a5ce9005`);
  `TRANSLATIONS` identical (`2824d051c9006b21`). The phantom stayed dead.
- **C-8** — both the docstring and the dev-map row state the three families **and** the
  `RecursionError`/`MemoryError` residue; neither claims an unqualified "never an exception".
- **C-2 / C-6** — the changelog bullet names all five commands including `sc mode`, states that
  `sc use` now regenerates and restarts, and qualifies the exit move as 2 → 1 *whenever no other
  section reports `[PROBLEM]`*. Verified by reading the bullet.
- Non-vacuity: the developer's own rig was controlled against a **clone** at HEAD (`ed01efc`, not a
  worktree), which raised for BC-1…BC-4 and returned `5`/`'x'`/`[1,2]` for BC-5.

**A sixth escape class, newly measured at stage 4 and carried forward to QA:** BC-6's "unchanged from
HEAD" is false for one variant. A peer that resets *while the response is being read* escapes HEAD's
`except (URLError, HTTPError)` as a raw `ConnectionResetError`, because
`urllib.request.AbstractHTTPHandler.do_open` wraps only `h.request(...)`'s `OSError` into `URLError`
and re-raises `h.getresponse()`'s exceptions bare. No code consequence — it is an `OSError`, so K-1's
tuple already covers it — but **QA must declare that variant a defect state, not an agreement state**,
or NFR-5 marks it inconclusive. R-20 as filed enumerated four classes; this task has now measured six.

### Stage 5 → 4 (rollback, round 1 of a maximum 3 at this stage)

`.harness/intervention.md` re-checked: absent. Transcription check performed as at stage 3: two
bodies returned under a header naming both paths, each beginning with its declared opening line, the
contract ending at `## Verdict`, no partial return. Written verbatim to `05_CODE_REVIEW.md` and
`05_RATIONALE.md`.

Verdict **APPROVED WITH MINOR** — 0 MAJOR, 2 MINOR, 5 INFO, no rollback demanded by the reviewer.
It nonetheless verified the diff independently and confirmed the substantive claims: `_egress_ip()`
unchanged (the phantom was not re-introduced), K-1…K-9 discharged, and — traced first-hand through
`cmd_ls` → `stored_delays()` → `clash_api()` — **`sc ls` is genuinely fixed by this one edit, not
merely `sc status`**, which is the claim Q-3 made when T-18 took R-20.

**PM decision: route CR-1 back to the developer rather than waive it**, even though the reviewer
offered the waiver. CR-1 is an accuracy defect in a **user-facing published surface** (the Chinese
changelog bullet said the `sc doctor` exit move was 2 → 1 for all five classes; for the non-object
class HEAD printed a *lying* `[正常]` row contributing 0, so that class moves 0 → 1). Rule 85's
「少就是多」 clause was applied to published surface on its very first outing in T-17 and that is
exactly where T-17's real defect was found. A one-clause repair with the text already written is not
worth waiving. CR-6 (an elided verb in the docstring) went with it as an in-place-only repair.

CR-2 was explicitly **not** routed: `_doctor_clash()`'s message is frozen by out-of-scope item 5 and
BC-14, so it travels as RES-1 to a T-20 follow-up row instead of being patched here.

### Stage 4 round 2 → 6 (advance)

Round record returned by the developer, recorded here per the round-record rule (the stage document
carries no `## Round N` section and was corrected in place):

- `round 2 · CHANGELOG.md:21 — the sc doctor clause's before-state made per-class: added the
  parenthetical 「（正文不是对象的那一类过去这一行反而显示「正常」）」 and widened the move to 「由「未知」
  或「正常」变成「异常」」/「由 2 或 0 变成 1」, one clause inside the existing bullet, no new bullet or
  paragraph · because HEAD printed a [正常] row (exit contribution 0) for the non-object-body class
  instead of collapsing the section, so the all-five generalisation over-stated it · CR-1`
- `round 2 · bin/sc:1979 — docstring first sentence "never one of the three exception families" →
  "never raises one of the three exception families", inserted in place on the existing line,
  docstring still exactly 8 lines and E1+E2 still exactly 12 added lines · because the elided verb
  parses on first read as "never returns an exception family" · CR-6`

CR-6 was **taken, not skipped**, and K-9's two ceilings both still hold exactly (docstring 8 physical
lines; `git diff --numstat bin/sc` → `12 6`). A textwrap reflow at width 98 was tried first and
produced a 9-line docstring — the unbreakable 26-char token `http.client.HTTPException.` forces an
early break — so a single 99-char line was chosen instead. No line-length rule exists in `AI-GUIDE.md`
or `.harness/rules/*.md` and 44 other lines of `bin/sc` already exceed 98, so no convention breaks.

`verify_all` after round 2: **PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — baseline preserved.

**No stage-5 re-review dispatched.** The round-2 diff is one clause of Chinese prose and one word of
a docstring, both written *by the reviewer itself* in `05_RATIONALE.md` § Finding 5 and CR-6, and the
stage-5 verdict was already an approval. Re-running a full independent review over its own prescribed
text would be disproportionate. Instead the repairs are handed to stage 6 to verify as part of V10's
document read — an independent check by a different agent, at no extra round.
</content>
</invoke>
