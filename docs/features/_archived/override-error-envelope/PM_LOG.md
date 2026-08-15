# PM Log — T-24 `override-error-envelope`

> Mode: **full** (7 stages). Pool: `followups`, dispatched by `/harness-batch`.
> Started: 2026-08-15.

## Task setup

- **Goal**: put one exception envelope and one type-mismatch vocabulary over the override/merge
  pipeline, so a malformed `override.json` (wrong type, too deep, non-object rule element) is a
  named sentence rather than a traceback or a silent array replacement.
- **Family to discharge (re-verify first-hand at stage 1, do not inherit)**: R-15, R-16, R-26,
  R-44, R-69.
- Task folder created; `docs/tasks.md` row to be added.

## Durable state (fail-open records)

- `.harness/scripts/task-state.js` **does not exist on this host** — verified by `ls`. No durable
  stage counter is available; rollback streaks are tracked in this log by hand (the 3-consecutive
  rule still binds).
- `.harness/scripts/entropy-cadence` **does not exist on this host** — verified by `ls`. The
  delivery-time entropy cadence resolves to **not-due** (fail-open, per the PM contract): no scan,
  no `## Entropy watch` section.

## Intervention checks

- **Check 1 (before stage 1 dispatch)**: `.harness/intervention.md` absent — nothing to consume.

## Insight index — entries surfaced to downstream

Queried `.harness/insight-index.md` (29 lines, at the F.4 cap of 30 — hand-rotation owed at
delivery per R-18). **Six entries applied and were surfaced whole** in the stage-1/2/4/6 dispatches
(quoted verbatim there, referenced here rather than re-pasted): `_init_files()`'s hard-coded
`/var/lib/sing-box` (sc-doctor); `main()`'s post-import `LANG` reassignment making zh assertions
vacuous (config-composition-layer); `verify_all.sh`'s relative paths giving a false red from any
subdirectory (share-url-userinfo-contract); and T-23's three — PEP 540 voiding `LC_ALL=C` locale
fixtures, `sys.stderr`'s `backslashreplace` vs strict stdout, and `json.loads`'s UTF-16
auto-detection. Two proved load-bearing in practice: the `LANG` entry shaped C-2's zh clause, and
the `verify_all` entry is why every stage ran it from the repository root.

## Related historical work (read from `docs/tasks.md` + archive)

- **T-14 `config-composition-layer`** (commit `1e454b6`) — the layer this task puts an error model
  over. Bounds: deep-copy discipline at every overlay entry point (the gate's **F-13** corrected
  the count to **seven** sites, not eight), and B-7 holding structurally because there is no
  call-graph edge from `_apply_directive` back to `_merge`.
- **T-23 `state-file-io-contract`** (commit `2de1339`) — filed **R-69**, addressed to this task by
  name: a second consumer of `OverrideError` exists; `_unusable()` is the single construction site
  and the one line to move if the class is re-parented; `main()`'s arm must keep honouring `e.path`.
- T-15/T-16/T-17/T-21 each declined **R-16** (R-54 re-homed it) — four declines.

## Stage transitions

### Stage 1 — requirement-analyst → `01_REQUIREMENT_ANALYSIS.md` (+ `01_RATIONALE.md`)

Verdict **READY**. Advance to stage 2.

- Shape: FR-1…FR-6, 10 non-goals, BC-1…BC-14, AC-1…AC-15, NFR-1…NFR-3, Q-1…Q-12.
- **Method limit stated by the agent**: stage 1 holds no `Bash`, so nothing was executed; clauses
  were re-derived by reading `bin/sc`, and the ones needing a run are marked `[needs a run]` and
  routed to stages 4/6 rather than presented as measured. Accepted — the gate and QA own execution.
- **Four brief clauses refuted / corrected** (detail in `01_RATIONALE.md`; the pool's
  re-verify-don't-inherit discipline held): (1) **R-16's counter-weight is false** — the ordering is
  `_write_private` → `_record_generated()` → `sing-box check`, so the binary's `rc=1` arrives
  *after* the working `config.json` was replaced and the broken digest baselined, and both READMEs
  already publish the opposite promise → **R-16 closes**; (2) **R-44's reachability half refuted**
  — the override route is already structurally closed by the deep copy → became **BC-8** (never
  raise the recursion limit); (3) **a third R-15 instance no row records (M0)** — the JSON
  scanner's depth exhaustion is a `RecursionError`, not the `ValueError` `_load_override()` catches,
  so a deep enough override tracebacks *before* `_merge`, which is why FR-2 encloses the load;
  (4) **R-69's "three differing policies" is five**.
- **R-26 refined**: gating the array assertion *alone* converts a mislabelled sentence into a
  traceback, so gate and envelope must land together — AC-7 kills a gate-only build.
- Dispositions: **R-15 closed, R-16 closed (R-54 discharged), R-26 closed**; R-44 **not** closed
  (honoured as a bound, no cap); R-69 discharged as constraints (BC-6); R-12 **not** closed and its
  population widens.
- R-22 discipline honoured: every malformed shape's criterion observes named sentence + non-zero
  exit + no write; AC-3 constructs the swallow-and-generate build and requires it to fail; AC-4
  pins a valid override's effect byte-for-byte. AC-15 **BLOCKED by construction** → operator
  obligation, nothing substituted. Four findings re-homed to the PM as rows rather than absorbed
  (`01_RATIONALE.md` "Re-homed findings") — to be filed at delivery.
- **Intervention check 2**: `.harness/intervention.md` absent.

### Stage 2 — solution-architect → `02_SOLUTION_DESIGN.md` (+ `02_RATIONALE.md`)

Verdict **READY**. Advance to stage 3.

- Design in one line: one `try` inside `generate_config()` spanning `if override is not None:`
  (`bin/sc:2069`) through a hoisted `json.dumps`, `except OverrideError: raise` first then
  `except Exception as e:` → `_unusable(OVERRIDE_PATH if override is not None else None, …) from None`;
  the same second arm on the load wrapper (`:2036-2040`) for M0; `_merge`'s loop re-derived around
  the **target's** current type so a list-valued key admits only `_apply_directive(...)`. FR-3 costs
  **zero** new keys and **deletes** a branch. **One** new user-facing string total (NFR-1 allows 2).
  No new function, class, file or module.
- Per-edit budget E1…E6 → `bin/sc` **+80/−65** (of which **+32/−32 is mechanical re-indent**,
  checkable with `git diff -w`); product cap **K-16: +86/−65 ± 6**.
- Rule 85 section present and substantial: Design **S** (`≈ +36/−31`) conceded correct on **19 of
  21** binding units including **all** of AC-1…AC-15, failing only FR-2's totality claim, with two
  constructible holes named (**M8** `TypeError: unhashable type: 'list'` at `:2093`; **M9** the
  `json.dumps` band at `:2104`). The **nearer** alternative is refuted by its own provenance.
- **Partition assignment**: none — no `.harness/agents/dev-*.md` on this project, so stage 4 is the
  single plugin `harness-kit:developer`.
- **Two items the architect routed to the PM**, both carried into the stage-3 dispatch:
  - **RS-1** — AC-7's *smallest-wrong-build annotation* is stale under K-13 (only the assertion's
    path **label** is gated, not its execution), so AC-7 no longer kills a gate-without-envelope
    build; AC-2 does, via M0–M3. The architect classes this an annotation defect, not a contract
    defect. **The gate rules on that**, not the PM.
  - **RS-6** — the contract carries two sections outside the generic schema
    (`## Smaller alternative rejected`, `## Requirement coverage`), both mandated by name in the PM
    dispatch; R-37 again (rule 70 declares no stage-doc boundary rule here). Recorded, not invented.
  - **RS-5** — asks the PM to file an `override-error-envelope-point-fixes-without-a-region` record
    into `.harness/rejected-decisions.md` at delivery, as T-18 R2 / T-19 RS-6 did. Noted for stage 7.
- **PM-observed tension routed to the gate**: the architect also edited **`CONTEXT.md`** (+8, one
  glossary term "document envelope") at stage 2, while **NFR-2** says the product diff touches
  `bin/sc`, both READMEs and `CHANGELOG.md` **and no other product file**. The PM does not rule on
  design or requirements; the gate is asked to rule explicitly (precedent: T-23 shipped
  `CONTEXT.md +9`).
- **Intervention check 3**: `.harness/intervention.md` absent.

### Stage 3 — gate-reviewer → `03_GATE_REVIEW.md` (+ `03_RATIONALE.md`)

Verdict **APPROVED FOR DEVELOPMENT — with binding conditions C-1…C-16**. Advance to stage 4.

- **Transcription**: the gate holds no write capability. Both bodies were returned in its final
  message under `===`-marked target paths and written **verbatim** by the PM. Pre-write checks:
  contract body begins with its declared opening line `> Contract portion. Rationale:
  03_RATIONALE.md (absent = none written).` (confirmed against the plugin contract, line 19 of
  `agents/gate-reviewer.md`) and ends with its `## Verdict` line; rationale begins with
  `> Rationale portion for 03_GATE_REVIEW.md. Non-binding.`; both header-named paths present, no
  partial return reported. Only the tool wrapper's own trailing `agentId:`/`<usage>` footer was
  excluded — it is not part of the returned body. 72 lines / 202 lines written.
Findings F-1…F-15 and conditions C-1…C-16 live in `03_GATE_REVIEW.md`; recorded here only what the
PM routes on.

- **Rule 85 duty discharged with teeth — the architect corrected in the smaller design's *favour*
  on two points, yet the larger design upheld.** **F-1**: M8 is real and reachable, but coverable
  inside the smaller Design S at **zero** added lines, so M8 alone does not buy the envelope.
  **F-2**: M9 is a **conjecture, not a constructed hole** (the design's own RS-3 concedes the band
  may be empty) → **C-11** sends it to stage 6 to be measured by bisection and **reported empty in
  writing if empty**. **F-3**: the nearer alternative's refutation-by-provenance is rhetoric as
  written. The decision therefore rests on **FR-2's totality plus the project's own measured
  leaf-enumeration evidence**, never on "two constructible holes" — **C-9** binds the PM to file the
  rule-85 record (RS-5) with that correction. No machinery to strike: FR-3 costs zero new keys, E3
  deletes a branch, nothing new added.
- **R-22 duty discharged — five criteria could not detect what they claimed**, all amended in
  writing rather than routed back: **F-4→C-1** (AC-2's "one line" and "non-zero exit" are **not
  observable at its own stated entry point**; recipe rewritten to drive `main()`), **F-5→C-4**
  (**worse than the stale annotation RS-1 reported** — AC-7 as written is passed by a build with E3
  and **no E6 at all**), **F-6→C-3** (AC-2 (iv) is **vacuous** without a pre-existing sentinel
  `config.json` — the clause carrying the whole R-22 gate), **F-7→C-2** (**BC-13 was vacuous**; new
  zh/en clause (v)), **F-8→C-5** (a **bare-literal** build passed AC-10 vacuously).
- **Open items ruled on**: **`CONTEXT.md` permitted, NFR-2 amended in writing (C-7)** following
  T-23's gate C-12, with stage-5 sign-off required since it predates stage 4's diff; **K-16
  endorsed with its arithmetic and two amendments (C-8)** — **R-61 honoured**, the derivation
  checked rather than accepted, E5's row itemised after F-12 found ~5 lines of unaudited slack, and
  the ±6 tolerance restricted to **added** lines; **AC-15 BLOCKED by construction (C-14)**, filed
  as an operator obligation, nothing substituted — the **eighth** consecutive one.
- **Hard constraints checked against the file, not the design's description**: BC-7 holds under E3;
  BC-8 satisfied **by absence**; BC-5 upheld (PQ-5 — the hoist binds an already-existing string);
  out-of-scope 3 vs AC-8 reconciled by **C-6** (enclosing indentation is not "touching the call
  site", binding both designs symmetrically).
- **F-13** corrects the design *and this PM's own dispatch*: `bin/sc` holds **seven**
  `copy.deepcopy` sites, not eight. **F-14** is a new PM-owned re-homed row: `bin/sc:2111` has no
  `shutil.which` guard where `cmd_doctor` does at `:2603`, so `sc reload` tracebacks on a host with
  no `sing-box` — outside this task's region by Q-8.
- **C-16**: every gate finding is **read-derived, not measured** (no execution tool at this stage);
  each is routed to stage 4 or 6 by name and none may be cited downstream as measured.
- **Intervention check 4**: `.harness/intervention.md` absent.
- **Stage gate before stage 4 satisfied**: stage 3 produced an explicit approval verdict.
- **Developer routing**: `ls .harness/agents/dev-*.md` → none. **Single-developer mode** —
  dispatching the plugin `harness-kit:developer`.

### Stage 4 — developer → `04_DEVELOPMENT.md` (+ `04_RATIONALE.md`)

Verdict **READY FOR REVIEW**. Advance to stage 5.

- **`verify_all` PASSED** — `bash .harness/scripts/verify_all.sh` from the repository root:
  baseline **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, after **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**.
  Zero new FAIL/WARN; A.1 (no hardcoded secrets) PASS on both runs. **Stage gate before stage 5
  satisfied.**
- Diff: `bin/sc` **+79/−55** (cap ≤ +80/−65, the +6 added-line tolerance unused), `README.md` +2,
  `README.zh-CN.md` +2, `CHANGELOG.md` +2 → **product +85/−55** against ≤ +86/−65. `CONTEXT.md` +8
  is stage 2's and excluded by C-7.
- **C-8 discharged exactly**: E5 split published as scaffolding +7 / hoist +1 / write-line rewrite
  +1−1 / explanatory comment +5 → **0 added lines beyond the split**, nothing absorbed. The region
  `:2069-2100` measured **32** lines — the gate's endorsed figure confirmed.
- **M0…M8 all measured through `main()` with `argv=["sc","reload"]`** and sentinel `config.json` +
  `.config.sha256` pre-placed (C-3): all nine PASS all four AC-2 clauses — **exactly 1 line, exit 1,
  both files byte-identical**. Two line shapes only; M4–M7 render one identical sentence (AC-5).
  C-2 discharged: M1 and M4 re-run at `lang=zh` render 无法据此生成配置, no `失败`.
- **The control correction the PM carried forward to stages 5 and 6 (major):** on HEAD, **M4–M7 at
  `dns.rules` do not discriminate** — the composed-document assertion already stops them with one
  line and exit 1, so AC-2's stated control is **wrong at the three guarded keys**. The silent-write
  class R-16 was filed for is real only at an **unguarded** array key (`{"dns": {"servers": …}}`).
  The developer ran **both** positions, so the criterion was measured where it discriminates.
  Routed to stage 5 to rule on whether an analyst round-trip was owed.
- **C-11 partially pre-measured** (stage 6 owns the report): `copy.deepcopy` overflows at depth
  **498**, `json.loads` at **9997** — a factor of **~20**, not the "roughly half" the stage-1
  rationale asserted. Bisected in child interpreters, never against the number 500.
- Controls that discriminated: AC-3's adversarial build **fails clause (iv)**; AC-7's HEAD/candidate
  path labels differ; AC-1 (24/24 states) and AC-4 (9/9 recipes) byte-identical and both shown
  non-vacuous by deliberate perturbation; AC-6 and C-13's fixtures string-equal to HEAD.
- **dev-map correction handed to the PM, not applied** (outside C-7): `docs/dev-map.md:38` is
  **false** — it says the three-key array guard sets `OverrideError.path = OVERRIDE_PATH`, which E6
  makes conditional. Exact current and replacement text are in `04_DEVELOPMENT.md`'s
  `## Open issues for review`, plus a second non-mandatory amendment for `:55`. **PM will apply at
  delivery** (T-23's stage 5 rolled its developer back for exactly this class of stale row).
- Design drift flagged by the developer (4 rows, D-1…D-4), all for stage 5 to rule on — notably
  **D-4**: the CHANGELOG says **eight** shapes where K-12 says seven, and BC-1 lists M0…M7.
- Could not measure: AC-15 (BLOCKED by construction, C-14 → operator obligation), the M9 band
  (C-11, stage 6's), any real `sing-box` behaviour (`subprocess.run` stubbed per C-1/PQ-8).
- Safety: `MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` identical at start
  and end; `is-active` never invoked; nothing written under `/etc/sing-box` or `/var/lib/sing-box`.
  Nothing committed, nothing pushed.
- **Intervention check 5**: `.harness/intervention.md` absent.

### Stage 5 — code-reviewer → `05_CODE_REVIEW.md` (+ `05_RATIONALE.md`)

Verdict **ROLLBACK TO DEVELOPER**. 2 MAJOR (one developer-owned, one PM-owned), 4 MINOR, 1 NIT.
**Rollback #1 of this task; consecutive rollbacks at stage 5: 1** (the 3-in-a-row escalation rule is
not yet in play).

- **Transcription** (same protocol at every stage-5 round, recorded once here): the reviewer holds
  no write capability; both bodies were returned under `===`-marked target paths and written
  **verbatim**, with the declared opening line and the `## Verdict` line checked before any write
  and only the tool wrapper's own `agentId:`/`<usage>` footer excluded.
- **The one developer-owned defect — CR-1 (MAJOR), with CR-3 (MINOR) in the same sentence.**
  `CHANGELOG.md:26` publishes **as unconditional** the silent-write claim that **stage 4's own
  measurement refutes** at `dns.rules` / `route.rules` / `route.rule_set` — the three keys the
  composed-document assertion guards, and the keys both READMEs' own directive examples target,
  where HEAD already renders one line and exits 1 with the bytes intact. The claim is true only at
  an **unguarded** array key (`dns.servers`, `inbounds`, `outbounds`) and the bullet names no key.
  The reviewer's aggravating point: the developer **applied exactly this standard to the code**
  (D-1 retired the same refuted premise from `bin/sc`'s comment) and then shipped it in the public
  note. CR-3: the same bullet promises a class-name fault clause for **every** failure, while
  M4…M7 render the vocabulary sentence with no class name.
- **Ruling on the PM-routed control correction: NOT a rollback to the requirement-analyst.**
  Discharged by the dual-position measurement — AC-2's four binding clauses are unchanged and pass
  at all nine members, BC-1 never pins which array key M4–M7 sit at, and what is falsified is the
  *annotation* about the pre-change build. The reviewer's fourth reason is the substantive one:
  **FR-3 was written over every array-valued key and E3 implements it over every array-valued key**,
  so the class R-16 was filed for is closed at `dns.servers` / `inbounds` / `outbounds` too — a
  design shaped like the (partly wrong) symptom list would have fixed only the guarded keys.
  Residual **RES-1** binds stage 6 to run the control at **both** positions and state the
  non-discriminating one in writing.
- Drift rows **D-1…D-4 all accepted**; on D-4 the CHANGELOG's count of eight is right and **K-12's
  "seven" is the erratum** → **RES-3**. **CR-2 (MAJOR) is PM-owned**: `docs/dev-map.md:38` confirmed
  **false**, the developer's replacement confirmed true clause by clause with CR-6's amendment →
  **RES-4**, applied by the PM before commit. **`CONTEXT.md` signed off** as C-7 required, with
  CR-4 (MINOR) on its glossary overreach. **CR-5 → RES-2**.
- **C-8 budget verified from the shipped file**: per-hunk numstat sums exactly to +79/−55, the E5
  split holds, the comment lands exactly at its cap of 5. "Mechanical" is *qualified* not false —
  and the developer's +29/−29 is **smaller** than the design's +32/−32 because the design
  double-counted E6's three replaced lines; the developer **reported** the discrepancy rather than
  absorbing it, which is exactly what C-8 asks for.
- **R-22 read confirmed structurally**: no path reaches `_write_private()` with a failed override —
  the region closes before it, `text` is unbound unless the region completed, both arms `raise` and
  neither returns, `except OverrideError: raise` is genuinely first (so `e.path` cannot be
  destroyed), `from None` on both, and no caller of `generate_config()` swallows the exception.
  Notably the reviewer records that stage 4's adversarial build emits **one line and no traceback**
  — a criteria set stopping at "no traceback" would have shipped it.
- Every stage-5 finding is **read-derived** (no execution tool); the `git` reads and every [B]
  criterion are routed to stage 6 as **RES-5**. **Intervention check 6**: absent.
- **Route**: back to stage 4 for CR-1 + CR-3 only — a `CHANGELOG.md` prose correction, no code.
  CR-2/CR-6 are withheld from the developer because C-7 forbids that file to it.

### Rework rounds 2–3 — stage 4 ⇄ stage 5, both on one CHANGELOG sentence

Two rollbacks, **no code change in either**. `bin/sc` has been byte-for-byte as first reviewed
(`79/55`) since round 1, and the product diff never moved from **+85/−55** — every correction was a
rewording inside an already-added line, so nothing was ever trimmed to fit a budget. Current state
of every finding lives in `05_CODE_REVIEW.md`; the round records, which live nowhere else, are here.

**Round 2 (developer → reviewer).** `round 2 · CHANGELOG.md:26 — the pre-change silent-write claim
scoped to the unguarded array keys (dns.servers/inbounds/outbounds) with the guarded-key outcome
stated as measured, and the fault-class clause narrowed from "every failure in the region" to the
envelope's two arms while the no-echo property is stated universally · because stage 4's own
dual-position measurement (04_RATIONALE.md:151-188) refutes the unconditional claim at
dns.rules/route.rules/route.rule_set, and D-1's standard — a refuted premise may not ship next to
the edit that retires it — applies to the public release note as it did to bin/sc's comment · CR-1
(MAJOR), CR-3 (MINOR); no code touched; CR-2/CR-6 left to the PM under C-7`

**Round 2 (reviewer → developer) — ROLLBACK #2.** `round 2 · re-review after the CR-1/CR-3
correction — both verified CLOSED against the shipped text and stage 4's measurements; scope claim
re-confirmed by reading every line round 1 cited, nothing executed · because the correction traded
CR-3's false universal for a new one: "绝不回显你文档里的任何一个值" is refuted by _anchor_index's
`match: {anchor}` (bin/sc:1400-1404), the very echo 01_RATIONALE.md:149-156 re-homed and
02_SOLUTION_DESIGN.md:294 declines to fix, while BC-4 scopes its ban to sentences this task
introduces or newly reaches · CR-8 (MAJOR, new — also in 04_DEVELOPMENT.md:25's E9 row), CR-9 +
CR-10 (NIT, new)`

**CR-8 mattered more than its predecessor**, and the reviewer's four aggravators are worth keeping:
the project **already knew** about the anchor echo (it is `01_RATIONALE.md`'s re-homed finding 1 and
`02_SOLUTION_DESIGN.md:294` says in terms that this design "does not fix" it); **BC-4 was scoped on
purpose** and the note removed the scope; the echo is reachable from the READMEs' **own published**
`$before`/`$after` recipe; and the promise is privacy-shaped, sitting next to a `sc config` entry
that names an un-redacted `auth_token`. **The code was never at fault** — BC-4 holds in `bin/sc`;
only the published note overclaimed. Two consecutive rollbacks here put the next round one step from
the 3-in-a-row human escalation, which was stated plainly in the round-3 dispatch.

**Round 3 (developer → reviewer).** `round 3 · CHANGELOG.md:26's no-echo clause re-scoped to the
class-name arm ("只写异常的类名，异常自己那句…消息不会被打印出来") and 04_DEVELOPMENT.md:25's E9 row
rewritten to assert the same scoped property and name _anchor_index:1400-1404 as the one sentence
excluded · CR-8`. The developer **enumerated every sentence-producing site reachable inside the
region before returning** — two rounds had been lost to a universal quantifier that did not survive
enumeration, and this time the enumeration came first.

**Round 3 (reviewer) — APPROVED, streak broken at 2.** `round 3 · CR-8 closed; CR-11 opened as a
NIT.` The reviewer **re-derived the enumeration independently rather than accepting the developer's**
(correctly noting the row grouping was an artifact), ran the two spot-checks asked for —
`_warn_drift` renders only the two path constants, and the load span's `not valid JSON ({err})`
prints a `JSONDecodeError` message carrying only `line/column/char`, never the offending text — and
confirmed the three settings-warning sites sit **above** the `try`. CR-8 closed **by construction
rather than by measurement**, the strongest form available: both sites of the class-name arm
reference `e` exactly once, inside `type(e).__name__`, with `from None` on both.

**CR-11 (NIT, new) → RES-9** was raised deliberately though it blocks nothing: "three rounds at this
stage have each turned on a clause in this one bullet that claimed slightly more than the code
delivers" — recorded so the pattern stays visible rather than passing unremarked because the round
finally came out clean. **A fourth instance then arrived from QA as QA-1.**

**The remaining MAJOR is the PM's, not the developer's.** CR-2 (`docs/dev-map.md:38` false) is
outside the developer's permitted set under C-7; the reviewer explicitly declined to spend the human
escalation routing a repair to the one agent contractually barred from making it, and instead made
**RES-4 block the commit, not the code** — noting that if the PM does not apply it before commit,
*that* is what should reach the human. The PM accepts RES-4 and applies it in the delivery pass,
with CR-6's amendment, RES-8 (CR-10) and RES-9.

- **Intervention checks 7, 8, 9, 10**: `.harness/intervention.md` absent at every boundary.
- **Stage gate before stage 6**: stage 5 APPROVED (0 developer-owned MAJOR), stage 4 `verify_all`
  PASSED. Advance.

### Stage 5″ — code-reviewer re-review round 3

Verdict **APPROVED**. **Rollback streak at stage 5 broken at 2** — the 3-consecutive escalation was
not reached. Advance to stage 6.

- Transcription per protocol; content at each path replaced.
- **CR-8 CLOSED, and closed *by construction* rather than by measurement** — the strongest form
  available. The reviewer verified both sites of the class-name arm (`bin/sc:2051-2052` and
  `:2122-2124`) reference `e` exactly once, inside `type(e).__name__`: no `str(e)`, no `e.args`, no
  `repr`, `from None` on both, and `main()`'s sole rendering site prints the already-composed
  message with no `__cause__`. A class name is a property of the exception's type, which no byte of
  the user's document can influence.
- The reviewer **re-derived the enumeration independently rather than accepting the developer's 17
  rows** (correctly noting the grouping was an artifact — `_anchor_index` has two raise sites, not
  four), and ran the two spot-checks asked for: `_warn_drift` renders only the two path constants,
  and the load span's `not valid JSON ({err})` prints a `JSONDecodeError` message that carries only
  `line/column/char` and never the offending text. It also confirmed the three settings-warning
  sites sit at `:2079-2080`, **above** the `try` at `:2086`.
- **CR-11 (NIT, new) → RES-9**: the bullet's two-way split is exhaustive over the eight enumerated
  shapes but is opened over the whole span, in which three pre-existing load-time faults are named
  by **cause** rather than by position or class. Nothing published is false. The reviewer raised it
  deliberately — "three rounds at this stage have each turned on a clause in this one bullet that
  claimed slightly more than the code delivers" — so the pattern stays visible rather than passing
  unremarked because the round finally came out clean.
- **The remaining MAJOR is the PM's, not the developer's.** CR-2 (`docs/dev-map.md:38` false) is
  outside the developer's permitted file set under C-7; the reviewer explicitly declined to spend
  the human escalation routing a repair to the one agent contractually barred from making it, and
  instead made **RES-4 block the commit, not the code** — noting that if the PM does not apply it
  before commit, *that* is what should reach the human. **The PM accepts RES-4 and will apply it in
  the delivery pass**, together with CR-6's amendment, RES-8 (CR-10) and, at the PM's option, RES-9.
- Round record returned and filed (round 3: the no-echo clause re-scoped to the class-name arm and
  `04_DEVELOPMENT.md:25`'s E9 row rewritten to match; CR-8 closed, CR-11 opened as a NIT).
- **Intervention check 10**: `.harness/intervention.md` absent.
- **Stage gate before stage 6**: stage 5 PASS (APPROVED, 0 developer-owned MAJOR), stage 4
  `verify_all` PASSED. Advance.

### Stage 6 — qa-tester, attempt 1: terminated by an infrastructure fault

**Not a rollback and not a stage verdict** — the QA agent ran to the end of its measurement
programme (91 tool calls, ~24 min) and was cut off by an **API transport error** at the moment it
began writing its two documents. Its last message was "All measurements done. Writing the two
documents." Recorded here because a lost stage attempt must be visible, not silently retried.

- **Nothing was lost.** The measurement corpus survived on disk in the session scratchpad under
  `qa/` — ~90 artifacts written 16:02–16:20, covering every condition (C-11's bisection, AC-2 on
  both builds and both languages, the R-22 wrong builds and their source patches, C-12, C-4, C-13,
  AC-1, AC-4, T-13's mode trace, the structural and boundary sweeps) plus its own pristine
  `head-clone/`.
- **The operator obligation was already filed** — `.harness/operator-obligations.md` showed as
  modified, so C-14/AC-15 was discharged before the cut; the resumed attempt had to verify it and
  **not duplicate the row**.
- **Resumption policy**: re-dispatch with the artifact inventory, requiring the agent to **re-run
  what is cheap and decisive itself** (`verify_all` from the root, the three `git` reads, the
  service witness) and to **state the provenance of every reused figure** — recorded transcript vs
  re-measured now. Nothing may be reported as measured that neither attempt actually ran.
- **Intervention check 11**: `.harness/intervention.md` absent.

### Stage 6 — qa-tester, attempt 2

Verdict **CHANGES REQUIRED (2 defects)** — `bin/sc` approved unchanged, no developer *code* change
requested. **14 PASS / 1 FAIL (AC-13) / 1 BLOCKED (AC-15) / 2 NOT-DISCRIMINATING / 0 CRITICAL.**

- **Provenance honoured**: the resumed attempt re-ran the cheap-and-decisive checks itself and
  re-ran eleven of the first attempt's harnesses, obtaining output **byte-identical** to the
  recorded transcripts (two runs hours apart, same answers). Four results are marked `[R1]`-only and
  none carries a criterion verdict on its own. This is the discipline the resumption required.
- **RES-5 discharged — the budget is now verified by a stage that could actually run `git`**:
  `bin/sc 79/55`; product **+85/−55** against C-8's ≤ +86/−65, tolerance unused, removals inside the
  hard cap. `git diff -w`: `bin/sc 60/36` (the 19/19 delta is D-1's re-indent). `git status` shows
  exactly the permitted set plus QA's own `.harness/operator-obligations.md` and the PM's
  `docs/batches/**`. Stage 5's read-derived figures are confirmed exactly.
- **C-11 discharged, and the M9 band is EMPTY** — measured by bisection against the interpreter,
  never against 500: `copy.deepcopy` overflows at **498**, `json.dumps(indent=2)` at **996**,
  `json.loads` at **9997** (CPython 3.12.3, limit 1000). **Band = [996, 498) → empty, width 0**,
  stated in writing as C-11 required. **Gate finding F-2 is confirmed: M9 was a conjecture and is
  not constructible here** — so the larger design's purchase rests on FR-2's totality and M8 alone.
  Stage 1's "roughly half" is refuted (~20×), and BC-8's bound is what keeps R-44 unreachable.
- **The wrong builds, and which criterion kills each** — this is the R-22 evidence: W-A (swallow +
  write) → AC-2 (ii)(iii)(iv); W-B (swallow + `return False`) → (ii); W-C (right sentence, exit 1,
  **but writes first**) → **(iv) alone, and only in C-3's amended sentinel form** — the gate's F-6
  amendment is what makes that build detectable at all; W-E (label never gated) → (ii) on
  M1/M2/M3/M8 but **not** M0; W-F (leaf enumeration instead of a region) → **M8 only**, which is the
  measured justification for C-10.
- **QA-3 (NOT-DISCRIMINATING, criteria gap)**: **W-D (`fault=str(e)`) is killed by nothing** — it
  survives all nine members, and its line carries `('int' object has no attribute 'get')`. No
  criterion in the set controls **BC-4 at runtime**; it holds by construction only. Six purpose-built
  carriers produced no actual echo, so the hazard is real but unrealised. **Re-homed to T-28's
  committed suite** rather than absorbed. **QA-4 (NOT-DISCRIMINATING)**: C-5 as worded is satisfied
  by a **partial** bare-literal build; the strengthened form ("no emission site is a bare literal")
  passes on the shipped file.
- **C-14 / AC-15**: operator obligation **id 5** verified complete, nothing substituted, **no second
  row added** — the **eighth** consecutive un-substituted obligation. Discipline held again.
- **RES-1 discharged in writing**, **C-12/RES-2**, **C-13**, **C-4**, **C-10**, **AC-1**, **AC-4**,
  **T-13's mode timeline** and **T-14's byte-digest** all reported. Service witness (AC-14):
  `MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`, `NRestarts=0`, identical
  at start and end and identical to stage 4's; `/usr/local/bin/sc` never invoked.
- **Intervention check 12**: `.harness/intervention.md` absent.

**Defect disposition — the PM routes each to its owner:**

- **QA-2 (MINOR, PM-owned) — CLOSED by the PM.** AC-13 failed as written: the working tree reported
  `PASS 16 / WARN 1` against the HEAD clone's `PASS 17 / WARN 0`, the single new WARN being `[F.6]`
  on **this file** — a stage document over the 500-line cap, no product file. **Rule 70 makes
  PM_LOG compaction the PM's own non-delegable job**, and it had gone undone because this task ran
  three extra rounds. Compacted the settled entries by reference-don't-paste (their detail lives in
  the stage documents themselves) and re-ran `verify_all` from the repository root: **PASS 17 /
  WARN 0 / FAIL 0 / SKIP 1**, matching the batch baseline. AC-13 now passes. *Second pass required*
  — the stage-6 entry itself pushed the file back to 531; the developer caught that at round 4 and
  reported it rather than assuming the briefing, which is the right instinct.
- **QA-1 (MAJOR) — routed to the developer, not absorbed.** QA classed it a "PM-owned document
  repair", but `CHANGELOG.md` is a **product file in the developer's permitted set under C-7**, and
  the routing table sends a defect QA finds in shipped content to the implementer. Rolling it back
  rather than editing it myself is the rule the PM does not get to bend for convenience.
  **Rollback #3 of this task, but #1 at this boundary** — the 3-consecutive-at-one-stage escalation
  is not triggered (stage 5's streak was broken at 2 by its APPROVED verdict).

### Stage 4‴ — developer rework round 4 (QA-1)

Verdict **READY FOR REVIEW**. QA-1 repaired; `bin/sc` untouched, `docs/dev-map.md` untouched.

**Round record, as returned by the developer:**

> `round 4 · rewrote the false tail of CHANGELOG.md:26 — dropped 而且退出码仍然是 0，这次运行会被当
> 成成功 and replaced it with the overwrite of the working config.json, the drift record baselined
> onto the broken document before the check, and the checker's non-zero exit measured on
> dns.servers / inbounds / outbounds; corrected the same claim in 04_DEVELOPMENT.md:25 (E9 row) and
> 04_DEVELOPMENT.md:127 (Insight to surface), and scoped the exit-0 transcript prose in
> 04_RATIONALE.md:184-186 as a stub artefact · why: stage 4 measured the exit code with
> subprocess.run stubbed to returncode 0 so sing-box check never ran, and stage 6 lifted the stub
> and measured lines=6 exit=1 with the real sing-box on all three named keys, making the shipped
> clause false on every host install.sh produces · finding QA-1 (MAJOR), discharging RES-7 / CR-9 ·
> bin/sc untouched, product diff unchanged at +85/−55`

- The repair **scopes rather than drops**: the exit-code claim is gone, replaced by exactly what QA
  measured un-stubbed — the working `config.json` overwritten, the drift record baselined onto the
  broken document **before** the check, then the checker's non-zero exit on all three keys. Every
  surviving clause is one QA verified; nothing was added that the project has not measured.
- **The claim was in three places, not one** — `04_DEVELOPMENT.md:25` (E9 row), `:127`
  (`## Insight to surface`, which is harvested into the insight index, so a false line there would
  have outlived the task), and `04_RATIONALE.md:184-186`'s prose over its transcript. The developer
  found all three by checking rather than by being told. The insight line stays **one physical
  line** as `archive-task` requires.
- Product diff **unchanged at +85/−55**, `bin/sc` byte-for-byte at `79/55` — the repair is a
  rewording inside an already-added line, consuming zero budget.
- The developer's own `verify_all` read `PASS 16 / WARN 1` and it **correctly refused to attribute
  the WARN to itself**: it re-measured `PM_LOG.md` at **531** lines, not the 505 the briefing
  implied, and reported that the PM's compaction "is not present at this tree". It was right — my
  stage-6 entry had re-inflated the file after the first compaction. Second compaction done;
  `verify_all` from the repository root now **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**.
- **Intervention check 13**: `.harness/intervention.md` absent.


### Stage 6′ — qa-tester verification round, and stage 4⁗ (QA-6)

QA re-verified both repairs and re-issued **APPROVED FOR DELIVERY**. `## Adversarial tests` heading
intact and unsuffixed.

- **QA-1 CLOSED** — verified clause by clause with **four new reproducers**, the earlier scratchpad
  being gone. The notable part: the new sentence's ordering claim (「在校验之前」 the drift record is
  baselined) was one **round 2 had published inferentially**, and QA said so rather than passing it —
  then built a `subprocess` façade that snapshots both files **at spawn time** and measured the
  digest already equal to the sha256 of the just-written broken document, on all three keys. A
  stubbed-checker control proves the non-zero exit is the checker's. **No fifth over-claim**; one
  clause is host-scoped (a host with no `sing-box` dies of `FileNotFoundError` instead — the
  overwrite and the baselined digest still happen) and that is recorded, not filed.
- **QA-2 CLOSED** — `verify_all` **PASS 17 / WARN 0 / FAIL 0 / SKIP 1, exit 0**, against a **freshly
  made** clone at `2de1339`; QA noted that a stale clone is how that comparison lies, and
  additionally checked `git status --porcelain .harness/scripts/` is empty, so the checks themselves
  are byte-unmodified.
- **QA-6 (NIT, new)**: `04_DEVELOPMENT.md` still asserted in the present tense that QA-2 was open and
  `PM_LOG.md` 531 lines. **Routed to the developer rather than absorbed** — the PM does not edit
  another stage's document, and the stage-doc contract requires current state. Round 5 removed the
  paragraph outright (a closed defect is not an open issue) and re-bound the `verify_all` figures to
  the moment they were observed, so the claim cannot go stale again; the developer **re-measured
  rather than copying the briefing's numbers**, which is precisely how this class of defect kept
  recurring.
- **Rollback tally: 3 (all prose, none code) + 1 NIT round.** No stage ever reached 3 consecutive.

### Stage 7 — delivery

- `07_DELIVERY.md` written. **Entropy watch: SKIPPED, fail-open** — `.harness/scripts/entropy-cadence`
  does not exist on this host (verified), so the cadence resolves to **not-due**: no scan, no
  `## Entropy watch` section, delivery verdict unaffected. Same fail-open for `task-state.js`.
- **RES-4 and RES-8 applied by the PM** (the only `docs/dev-map.md` edits, +3/−3): `:38`'s false
  clause replaced with the developer's text **as amended by CR-6** ("…whenever an override is
  present"), `:55` adopted in the shortened form, and `:57`'s `README*.md:384` citation corrected to
  `:402`/`:409` — the anchor's real position, which this task moved by one line.
- **C-9 discharged**: `.harness/rejected-decisions.md` +35, recording the rejected point-fix design
  **with the gate's corrections** — that Design S covers M8 at zero added lines, that M9 was
  unverified at gate time and **measured empty** at stage 6, and that the decision rests on FR-2's
  totality plus this repo's own leaf-enumeration evidence, never on "two constructible holes".
- **Five rows filed** (R-70…R-74) and **five closed** (R-15, R-16, R-26 and R-54 by this task; R-17
  by T-23, restated). R-44 and R-12 explicitly **not** closed, with reasons stated.
- **`docs/tasks.md` held at exactly 300 lines** (F.5 cap). Completed rows T-22 and T-23 rotated to
  `docs/tasks-archive.md` **in preference to displacing open rows**, and nine closed rows compacted
  to one-line stubs naming what closed them.
- **R-18 confirmed a thirteenth time**: `archive-task.sh` harvested 2 insights and left the index at
  **31** lines against its 30 cap. Hand-rotated two rule-set-sourcing entries into
  `docs/features/_archived/insight-history.md`, chosen because R-53's row and T-20/T-21's deliveries
  now carry them — every entry kept is a live hazard for the next harness someone writes.
- **`guard-rm.sh` blocked a `cat`-heredoc containing no `rm`** — the **tenth** confirmed instance.
  Worked around by writing the text to a file and appending it; **the `HARNESS_ALLOW_OUTSIDE_RM`
  bypass was never set**. The commit message went in via `git commit -F` for the same reason.
- `verify_all` at this checkpoint: **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**.
- **Intervention check 14 (final)**: `.harness/intervention.md` absent.
