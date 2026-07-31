# PM Log — install-version-query-abort (T-11)

- Mode: **full** (stages 1 → 7)
- Started: 2026-08-01
- Dispatch mode: **deferred-human** (`defer, do not ask`). Standing decision authority granted by
  the owner (「你来决策就行」). PM resolves judgment calls and records them; `BLOCKED: NEEDS-HUMAN`
  only for a genuine safety red line.
- Developer routing: **single-developer** (no `.harness/agents/dev-*.md` present).

## Goal (one line)

`install.sh` step 2's `SB_VER=$(curl … | grep … | sed …)` aborts the script *at the assignment*
under `set -euo pipefail`, so its own `download_failed`/`check_network` handler and T-01's
`install_report()` never run — the installer can exit having stated no outcome at all.

## Pre-flight checks

| Check | Result |
|---|---|
| `.harness/intervention.md` present before stage 1? | No |
| `.harness/insight-index.md` read? | Yes — 28/30 lines, near rotation threshold |
| `docs/tasks.md` related history? | Yes — see below |
| `docs/dev-map.md` read? | Yes (`install.sh` row, bilingual `t()` row) |

## Related historical tasks (from `docs/tasks.md`)

| Task | Relevance |
|---|---|
| **T-08** `install-binary-download-progress` | **Origin of this defect row.** Found at stage 2, verified at stage 1', filed in `.harness/rejected-decisions.md`; deliberately NOT absorbed because it changes failure behaviour that T-08's AC-6/AC-14 pin as unchanged. Also owns the curl flag policy at `install.sh:116-132` (`CURL_OPTS_QUIET` / `CURL_OPTS_PROGRESS`) — consume, do not modify. |
| **T-01** `install-enable-start-split` | Built `install_report()` + `PHASE_*` so the installer always states its outcome. This task closes the remaining hole in that guarantee. |
| **T-10 / T-02 / T-09** | `bin/sc`, `systemd/` — out of scope, boundary only. |

Open row #1 under `docs/tasks.md` "Open rows surfaced by T-08" **is** this task.
Open row #2 (uncommitted bilingual key-parity proof) is adjacent: `rejected-decisions.md:57-73`
says the next task "should probably widen its own diff instead" — T-08 could not because AC-19
pinned its diff. This task has no such pin, so whether to widen is a live design decision, not a
foregone one. Surfaced to stage 1 as a question, not a directive.

## Insights surfaced to downstream agents

- L28 (T-08) — the defect itself, verbatim: the `set -euo pipefail` assignment-abort mechanism.
- L10 (T-01) — `t()` declares `local fmt` with no default → a key in only one language table
  aborts the whole installer under `set -u`; zh reachable only by answering `2`.
- L22 (T-10) — `systemctl is-active` cannot detect a restart; the witness is
  `systemctl show -p MainPID -p ActiveEnterTimestamp`. **Safety-critical for QA.**
- L13 (T-02) — the live-restart incident: a test re-execed the *installed* binary under sudo.
- L26 (T-08) — a `git worktree` is not a valid pristine baseline for `verify_all.sh`; use a clone.
- L21 (T-09) — `archive-task.sh` harvests only the FIRST physical line of an `## Insight` bullet.

## Stage transitions

### Stage 1 — requirement-analyst — COMPLETE 2026-08-01 → `READY FOR DESIGN`

Output: `01_REQUIREMENT_ANALYSIS.md` (549 lines). 12 behaviors (B-1..B-12), 16 boundary conditions,
15 acceptance criteria, 7 recorded decisions (D-1..D-7), 4 re-homed rows (R-1..R-4).

Defect confirmed against source at HEAD `22502f9` and **refined**: three upstream conditions abort at
`install.sh:373`, not one. The sharpest is HTTP 200 with no `tag_name` (captive portal / proxy
interstitial / empty body) — curl exits 0 so `-S` prints nothing, `grep` exits 1 silently, `pipefail`
propagates, and the installer dies **producing no output at all**. Only a pipeline exiting 0 with an
empty/non-semver string reaches the handler at `:377` — the narrowest of four classes.

Sibling sweep: exhaustive, **11** command substitutions, verdict per row. Five (`:39 :61 :62 :307
:318`) terminate in `|| true` / `|| echo ""` → status forced 0 → not the defect. `:51` (`case
"$(uname -m)"`), `:368` and `:392` discard the substitution's status → not aborts. `:332` / `:371`
(`mktemp -d`) do abort by the same mechanism but make no handler unreachable → report-only (R-1).
The brief's pointer to `install.sh:347` **does not land on a substitution at HEAD** — the two
`sing-box version | head -1` sites are `:368` / `:392`, both examined.

### PM pre-flight (between stages 1 and 2) — capability-gap resolution

**Why**: AC-1 made running experiment E-0 a *blocking obligation on stage 2*, but the
`solution-architect` agent has tools Read/Glob/Grep only — **no shell**. So does `gate-reviewer`.
The first stage with execution capability is stage 4 (developer). AC-1 as written was unsatisfiable
at its assigned stage, and the design would otherwise have been written on an unverified premise.

**Routing decision (PM, capability routing is mine to own)**: run E-0 as a PM-owned pre-flight via a
general-purpose agent with shell access, before dispatching stage 2, and hand the transcript to the
architect to paste. Intent of AC-1 is preserved exactly — the premise is falsifiable *before* the
design exists, and the stop rule stays live. AC-1 is hereby **re-homed from stage 2 to this
pre-flight**; stage 2 satisfies it by citing this transcript, and the gate should verify it did.

**E-0 result: 7/7 MATCH.** `GNU bash, version 5.2.21(1)-release`.

| Case | Predicted | Observed | Verdict |
|---|---|---|---|
| E1 bare assignment, failing command | no `REACHED`, exit 1 | no `REACHED`, exit 1 | MATCH |
| E2 bare assignment, failing pipeline | no `REACHED`, exit 1 | no `REACHED`, exit 1 | MATCH |
| E3 same without `pipefail` | `REACHED`, exit 0 | `REACHED`, exit 0 | MATCH |
| E4 assignment in an `if` condition | `REACHED`, `done`, exit 0 | as predicted | MATCH |
| E5 `local` masks the status | `REACHED after local`, exit 0 | as predicted | MATCH |
| E6 substitution as an argument | `[]`, `REACHED`, exit 0 | as predicted | MATCH |
| E7 list ending in `\|\| true` | `REACHED, V=[]`, exit 0 | as predicted | MATCH |

**Stop rule NOT triggered** — E1 and E2 did not print `REACHED`. The task premise stands, and §2.3's
sweep verdicts are cleared by E5/E6/E7 as the analyst intended.

Two additional probes commissioned by PM (facts for stage 2, carrying no design preference):

- **E8** — `f() { V=$(false); …}; f` at top level: neither in-function nor after-function line
  printed; whole shell exited 1. **The abort fires inside a function body exactly as at top level**
  — a design cannot dodge it merely by moving the assignment into a function.
- **E9** — `if V=$(printf "x\n" | grep zzz | head -1); then … else echo "rc=$?"; fi`: else-branch
  ran, `$?` was **1** (the pipeline's status), `done` printed, overall exit 0. The `if` guard is an
  exempt context that **still captures `V` on the success leg** without a second evaluation.

**Baseline witnesses captured at task start:**

- Live service (AC-14 witness, `.harness/insight-index.md:22` — `is-active` is NOT valid):
  `MainPID=2500438`, `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST`
- `verify_all.sh` on the working tree: **PASS 15 / WARN 1 / FAIL 0 / SKIP 2**.
- Working tree: ` M CONTEXT.md`, ` M docs/tasks.md`, `?? docs/features/install-version-query-abort/`.
  `install.sh`, `bin/sc`, `.harness/scripts/` all clean.

### PM decisions arising from the pre-flight

**PM-1 — the F.6 WARN is known, attributable, and self-clearing. No stage may spend effort on it.**
The single WARN is `[F.6] Active task docs <=500 lines each`, caused **solely** by stage 1's own
`01_REQUIREMENT_ANALYSIS.md` at 549 lines. It did not exist at HEAD. Two consequences:
(a) AC-3's delta analysis must read this as a *second* expected delta alongside BC-16's B-8 flip —
BC-16 anticipated only one, so AC-3 is hereby widened to expect both;
(b) F.6 checks **active** task docs, so `archive-task` at delivery moves the folder to
`docs/features/_archived/` and the WARN clears by construction. Delivery must confirm that.
I did **not** order a compaction round-trip: the risk of a fresh agent dropping binding requirement
content while rewriting exceeds the cost of a transient WARN that is not a FAIL and that the stated
gate ("no FAIL") tolerates. **Stages 2-6 must keep their own docs ≤500 lines** so no second offender
appears. The gate reviewer retains authority to order stage 1 to compact if it judges otherwise.

**PM-2 — stage 1's `CONTEXT.md` edit is ACCEPTED, and the gate must audit it.**
Stage 1 edited a shared repo file outside the task folder. Facts: `CONTEXT.md` is the project's
pre-existing tracked canonical glossary (`# singbox-cli — glossary`), whose stated purpose is to fix
shared vocabulary "so two tasks cannot mean two different things by the same word"; the change is
**purely additive** (14 insertions, 0 deletions), follows the file's fixed three-part entry shape,
and adds exactly two terms — `stated outcome` and `assignment abort`. **Accepted** because `stated
outcome` is load-bearing in B-1 and B-4: the requirement's central obligation is phrased in terms of
it, so the term needed a definition of record. It was declared in AC-12 rather than slipped in. The
gate reviewer is explicitly empowered to overturn this and require the edit be reverted.

**PM-3 — D-2 (the bilingual key-parity gate, B-8) is provisionally ENDORSED, gate to audit.**
This widens the diff beyond `install.sh` into `.harness/scripts/`. The brief's scope boundary named
product files (`bin/sc`, `systemd/`, the curl flag policy); harness tooling was not addressed either
way, so this is a judgment call, not a boundary breach. Endorsed because the analyst's reason 1 is
the only one that actually decides it: B-7 needs a witness, and `.harness/insight-index.md:10` says
an English-only run cannot produce one — the check is *this task's own verification instrument*, not
a general test project. Reasons 2-4 (four-task deferral, rule 50 asks for it, it is cheap) are
supporting, not sufficient; "it has been deferred four times" is an argument about debt, not about
this task. The analyst's own overturn condition stands and I adopt it: **if stage 2 finds the check
cannot be written without a fragile parser of the two `case` blocks, defer it a fifth time — but
record that deferral in `.harness/rejected-decisions.md`.** A fifth *reasoned* deferral is
acceptable; a fifth *silent* one is not.

### Stage 2 — solution-architect — COMPLETE 2026-08-01 → `READY FOR GATE REVIEW`

Output: `02_SOLUTION_DESIGN.md` (exactly 500 lines — PM-1's cap respected, no second F.6 offender).
No rollback: the design accepted the requirement as written and did not report an upstream defect.

**AC-1 discharged by citation** of the PM pre-flight transcript, as routed. Every shell fact the
design rests on maps to E1-E9; where a fact was NOT covered (`VAR=$(…) || true`), the architect
**rejected the alternative rather than assume it** — the discipline I most wanted to see here.

Design decisions of record:

1. **Fix shape** — assignment moves into an `if` condition (E9's exempt context), and `head -1` is
   replaced by `sed -n '1s…p'`. The second change is not cosmetic: with `head -1` present, the
   guard's failure leg would wipe a correctly extracted `SB_VER` whenever SIGPIPE fires, so removing
   the only early-exiting reader makes B-6/BC-5 immunity **structural rather than race-dependent**.
   Five alternatives tabulated with rejection reasons.
2. **Reporting route — explicit early exit, NOT `install_report()`.** Routing through it as it
   stands would print six statements that are false or useless at step 2 (`fail_config`,
   `fail_rulesets`, `sc update-rules` / `sc reload` at `:398`, `systemctl status` at `:428`, the log
   path at `:397`). Making it truthful would need an era discriminator whose two branches share
   three `echo` lines and nothing else — failing both rule-85 seam tests and the deletion test.
   **Consequence: AC-11 holds with no exception at all** — nothing in the phase machinery or
   `install_report()` changes. Future edit prevented: "every task adding a pre-step-7 failure path
   must also extend `install_report()`'s discriminator."
3. **D-4 — reuse `download_failed` / `check_network`, no new key**, judged true of all five modes
   against B-4. The architect recorded the honest consequence unprompted: this **weakens D-2's
   reason 1**, since the parity check no longer guards a *new* string.
4. **B-8 ships — PM-3's overturn condition did NOT fire.** The parser is not the judge: it only
   enumerates *candidate* key names (union, never attributed to a block); the judgment is
   behavioural — source the extracted `t()` under `set -u` and render every key in both languages,
   reproducing insight L10's actual failure mode rather than a proxy. Over-inclusion → loud FAIL;
   under-inclusion → caught by "every `fmt=` line must yield a key" → exit 2. Wired as `verify_all`
   B.2. **No fifth deferral needed**, so no `rejected-decisions.md` entry is owed on that count.
5. **Safety harness specified concretely** (§6): fragment extraction with stubbed `curl` on PATH in
   `mktemp -d`, `LANG_CHOICE` assigned directly (this is how BC-11's zh path is exercised with no
   interactive prompt), plus a **refuse-to-run denylist** — the extracted block must not contain
   `install -m`, `tar `, `systemctl`, `visudo`, `chmod`, `mkdir`, `sudo`, `/etc/` or `/usr/local/`,
   or the harness aborts. This is what stops stage 4 / stage 6 improvising something dangerous.

Two items raised by the architect for the gate:

- **R-g** — AC-12's permitted-diff list **omits `.harness/rejected-decisions.md`**, yet D-5 requires
  appending to it. The architect could not edit the requirement (correct — downstream cannot edit
  upstream) and flagged it instead. Routed to the gate to widen AC-12, the way PM-1 widened AC-3.
- **E-10** — a cheap, required, non-blocking stage-4 probe with a stop rule, establishing whether
  the `head -1` removal was load-bearing or merely precautionary. The design does not change either
  way, so this is evidence-gathering, not a design dependency.

### Stage 3 — gate-reviewer — COMPLETE 2026-08-01 → `APPROVED FOR DEVELOPMENT` (C-1 … C-17 binding)

**No rollback.** Rollback count remains **0**. Stage gate satisfied: an explicit PASS verdict exists,
so stage 4 may begin.

**Second capability gap, PM-owned**: the `gate-reviewer` agent has tools Read/Glob/Grep — **no write
tool** — so it could not persist its own document. It returned the full 297-line review in its
message and I saved it verbatim to `03_GATE_REVIEW.md`, altering nothing. Recorded here because it
is the second time a review-only agent's tool set has collided with a document-producing stage
(stage 2 hit the same wall with AC-1's experiment). This is a harness-level observation, not a task
defect — see the delivery Insight candidate.

The gate verified upstream claims **against `install.sh` itself** rather than deferring — 24 claims
checked, 22 clean `V`, 2 corrected `V±`. All nine referred adjudications came back with reasons that
survive independent checking:

| Ref | PM question | Gate ruling |
|---|---|---|
| A-1 | Early exit vs `install_report()` | **UPHELD.** All six claimed-false statements verified real against `:263-285`. Decisively, the gate found the *originating record* already delegated the call: `rejected-decisions.md:129-134` names the expected shape, "an explicit `if ! SB_VER=$(…)`" — the design lands exactly there. AC-11 now holds **with no exception at all**. |
| A-2 | `head -1` → `sed -n '1s…p'` | **UPHELD**, equivalence re-derived independently rather than accepted. SIGPIPE risk judged "real in mechanism, near-unreachable in practice — and that is precisely why the change is right". The `1` address is what preserves `head -1` semantics; C-1/C-2 defend it. |
| A-3 | Does B-8 still belong after D-4 weakened PM-3's reason 1? | **SHIPS.** The gate conceded my reason 1 is weakened, then found an **independent** standing justification I had not relied on: `rejected-decisions.md:75-86` (`t-fmt-default-fallback`) already declined the cheap mitigation on the grounds that "the structural fix is a committed key-parity gate". Shipping it discharges a decline the project itself made. C-13 remains the escape hatch. |
| A-4 | R-g, AC-12's omission | **WIDENED** to an explicit 11-item permitted diff (adds `rejected-decisions.md`, rule 50, and delivery-tooling-only writes to `insight-index.md`). |
| A-5 | PM-2, the `CONTEXT.md` edit | **UPHELD** — and load-bearing: the gate used the glossary's own definition of `stated outcome`, not its own reading, to decide A-1. |
| A-6 | PM-1, the F.6 WARN | **UPHELD, no compaction.** Verified mechanically that `verify_all.sh:223-231` skips `*/_archived/*` and `archive-task.sh` moves the folder there — self-clearing is true by construction, not by hope. |
| A-7 | Safety-harness sufficiency | **SUFFICIENT after C-3/C-6/C-7.** Three real gaps found, the sharpest being that the denylist **omitted `sing-box` itself** — exactly insight L13's incident class, with `:392` running `sing-box version` nine lines below the fragment's end. |
| A-8 | Vacuous greens | **Five criteria + E-10 could have gone green proving nothing.** AC-6 could not have detected a dropped `1` address — the single highest-risk regression in the diff — because the fixture had one `tag_name` line. |
| A-9 | E-10 deferred to stage 4 | **ACCEPTABLE**, bound to run *before* `install.sh` is edited (C-8). |

11 findings (0 FAIL, 8 WARN, 3 INFO), each discharged by a numbered condition without reopening an
upstream document — which is why this is an approval and not a rollback. F-1 is a genuine upstream
miscount (11 substitution *sites* but **12** substitutions; `:318` nests `$(dirname …)`), resolved
by ruling C-9 rather than a round trip.

### Stage 4 — developer — COMPLETE 2026-08-01 → `READY FOR REVIEW`

`verify_all`: **PASS 16 / WARN 1 / FAIL 0 / SKIP 1** — exactly the gate's prediction. Clone-baseline
delta: 18/18 steps compared, exactly two changes (B.2 `SKIP→PASS`, F.6 `PASS→WARN`), both predicted.
Safety harness: **126 assertions, 0 failures**. Developer's own doc 496 lines (cap respected).

**Live service untouched.** Start and end witnesses both `MainPID=2500438` /
`ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST` — identical to the task-start baseline.
`install.sh` was never executed; `systemctl show` was the only systemctl call.

Stage gate for stage 5 satisfied: `verify_all` PASSED with 0 FAIL.

Three items the developer raised rather than swallowed:

1. **E-10's stop rule fired — because the design's probe was broken, not the design.** Run verbatim,
   *both* legs returned 141: `yes … | head -200000` is itself an early-exiting reader **inside the
   measured pipeline**, so it SIGPIPEs its own producer and `pipefail` returns 141 regardless of what
   the extraction tail does. The developer proved this in isolation (the generator alone, with no
   extraction at all, exits 141), then re-ran with the input materialised out of band **before**
   editing `install.sh`, honouring C-8's ordering. Corrected legs: `E10d` (with `head -1`) → exit
   141, assignment aborted; `E10e` (`sed -n '1s…p'`) → `V=[1.10.0]`, exit 0; `E10h` (same without
   the `1` address) → 1,399,999 chars vs 6. **Conclusion is stronger than the design allowed for:
   the `head -1` removal is load-bearing, not precautionary.** Routed to stage 5 to judge whether
   the corrected legs support that conclusion.
2. **C-7's `sing-box` denylist entry, changed and flagged `DESIGN DRIFT` by the developer itself.**
   A literal substring ban refuses the very fragment it exists to protect — the block's own handler
   argument is `t download_failed "GitHub API (sing-box version)"`. Reimplemented in **command
   position**. This is a deliberate deviation from a *binding gate condition*, so it is not the
   developer's to ratify: routed to stage 5 as an explicit adjudication.
3. **A sha-label dispute** — see the PM probe below.

### PM probe (during stage 5) — the `22502f9` / `9184171` sha dispute — SETTLED

**Why PM-owned**: the code-reviewer has Read/Glob/Grep only and cannot run git, so it could not
settle a claim about commit history. Third capability gap this task.

**Finding: HEAD is `9184171`. The `22502f9` label in every stage document is WRONG.** `22502f9` is a
real commit but sits **13 commits behind HEAD** — it is the last pre-harness-bootstrap commit
(`3ccf691` bootstrapped harness-kit on top of it). `git merge-base --is-ancestor 22502f9 9184171`
exits 0; the reverse exits 1. `install.sh` differs by **159/26** between them (386 lines vs 519) —
exactly what the developer reported. Every point of the developer's claim checks out.

**Consequence: cosmetic only, and both C-12 and the anchors survive.** All six anchors the stage docs
rely on were verified against the real HEAD:

| Anchor | vs HEAD `9184171` | vs working tree |
|---|---|---|
| `:9` `set -euo pipefail` | CORRECT | CORRECT |
| `:116-132` curl flag policy | CORRECT | CORRECT |
| `:128` `CURL_OPTS_QUIET` | CORRECT | CORRECT |
| `:139-238` `t()` | CORRECT | CORRECT |
| `:243-288` `install_report()` | CORRECT | CORRECT |
| `:373-381` the defect block | CORRECT | shifted — the fix is applied there now |

At `22502f9` the anchors resolve to **nothing coherent**: `:116-132` is Chinese i18n `case` arms,
`t()` starts at 108, `install_report()` does not exist at all, and the version query is at `:264`
with literal `-fsSL`. So the documents were written against the right file and mislabelled the
commit — not written against the wrong file.

**C-12's baseline is VALID.** HEAD's `install.sh:373` contains the unfixed defect in its bare form
and none of the fix's markers; a clone of HEAD is a correct pristine baseline, which is what the
developer used.

**PM ruling — no rollback.** The defect is a label, the anchors are sound, and the baseline is valid,
so a round trip through a 549-line document buys an accurate string at the risk of losing binding
content (the same trade PM-1 and gate A-6 already declined). **The correction is recorded here and
will be stated prominently in `07_DELIVERY.md`**, which is the document a future task reads first.
Rollback count remains **0**.

### Stage 5 — code-reviewer — COMPLETE 2026-08-01 → `APPROVED`

**No rollback.** Rollback count remains **0**. Stage gate for stage 6 satisfied.
Third capability gap: the code-reviewer also has no write tool; its document was returned in-message
and saved verbatim to `05_CODE_REVIEW.md`.

**0 CRITICAL, 0 MAJOR, 5 MINOR, 4 NIT.** The reviewer re-derived rather than inherited: it verified
C-1's `sed` expression **token by token** (`1` address and `p` flag both present, byte-identical to
the required literal), independently re-derived B-5's byte-equivalence including the multiple-
`tag_name` case, traced all five B-2 modes through the actual code, and **independently confirmed
AC-8 by reading both language tables** (41 keys, identical names and order) rather than trusting the
new checker.

Adjudications it was asked for:

- **C-7 `sing-box` denylist drift → the developer was right, and C-7 was defective.** The reviewer
  found the block contains the literal `sing-box` **three times** (`:392`, `:396`, `:397`), so a
  substring ban refuses the very fragment it exists to protect — C-7 was **unsatisfiable as
  written**. The command-position replacement preserves L13's intent (it matches `$(sing-box …)` at
  `:368`/`:406`), and the **poison-pill layer is a second interlock that does not depend on the
  regex at all** — that is what makes the deviation safe rather than merely argued. Recorded against
  stage 3 so the same literal is not reissued.
- **The parity checker did NOT degenerate** into the parser PM-3 forbade: union enumeration with no
  attribution, behavioural render under `bash -u`, exit 1 vs exit 2 strictly separated. The reviewer
  also noted it **strengthens** the design (`:57-59` refuses to source a fragment containing `$(` or
  a backtick) and that `verify_all.sh:6` is `set -uo pipefail` with **no `-e`**, so the harness
  cannot abort by this task's own mechanism — the right thing to check, given the subject.

**Two vacuous greens the gate did not anticipate**, both found by reading the committed checker:
[VAC-1] — if `install.sh:143`'s `LANG_CHOICE` test ever stopped selecting the zh table, both render
children would return the **en** table, every comparison would agree, and the check would print
`OK: 41 keys, both languages` — a literally false statement — and exit 0, while zh was entirely
unreachable. A silent degradation of a **permanent** gate. Owner: solution-architect (design blind
spot, not an implementation defect).

### PM routing of the five non-blocking observations

**PM-4 — [EVID-1] handled by PM, not by a round trip to the developer.** The reviewer is right that
"the `head -1` removal is load-bearing, not precautionary" overstates E10d/E10e (a 5 MB fixture; the
real endpoint is ~1.6 KB where the race is unreachable) and silently contradicts gate A-2. The
accurate statement is **load-bearing for large or hostile bodies, precautionary for the real
endpoint** — which remains a complete justification, since BC-5 forbids depending on the race
falling the friendly way either way. I did **not** send the developer back for one sentence: the
reviewer's stated concern is propagation into `06`/`07`, and I control both (the QA brief carries the
corrected framing, and `07_DELIVERY.md` states it). The overstatement survives only in `04`, where
`03` and this log both contradict it with reasoning. Cost of a fresh agent re-entering a 497-line
document to edit one sentence exceeds the benefit.

- **[VERIF-1] → stage 6 must REBUILD the harness from the acceptance criteria, not inherit the
  developer's.** Adopted as a binding QA instruction; this is the single highest-value routing call
  from stage 5, and it matches what T-10's QA did.
- **[VAC-1], D-A (the defective E-10 fixture), D-C (+14 not +11) → solution-architect**, as
  follow-up rows (R-7, R-8), **not** a rollback — none reaches the product code.
- **[DOC-1]** (rule 50 `:45` now stale for B.2) → follow-up row; C-11 correctly forbade touching it.
- **[DOC-2]** → stage 7 restates the insight with its `- YYYY-MM-DD · ` prefix. **Index is at 29/30
  lines** — at most ONE insight may be harvested, and the next task needs a rotation.

### Stage 6 — qa-tester — COMPLETE 2026-08-01 → `PASS`

**No rollback.** Rollback count final: **0**. Both delivery gates satisfied (stages 5 and 6 PASS).

QA **rebuilt** the harness from the acceptance criteria as instructed — fixtures, stub, poison pills,
guard, driver and every assertion its own — so [VERIF-1] became an independent second witness rather
than a re-run. **102 assertions / 0 failures** across 5 modes × 2 languages; 145 runs, 0 flakes;
198 stub calls and **0 real network requests**; 18 poison-pill executables leading `PATH` with
**0 `POISON` lines logged**. `install.sh` never executed — only a guarded 15-line fragment.

- **C-14 discharged where the reviewer could not**: the three range diffs against HEAD `9184171`
  (`:24-29`, `:243-288`, `install_report || exit 1` at `:518`→`:532`) and `:116-132` all **IDENTICAL**.
- **AC-6 proven able to fail**: dropping the `1` address from the `sed` flips three of three
  assertions. Negative controls reproduce the HEAD mute abort (`exit=1`, empty stdout) for modes 1-3.
- **[VAC-1] CONFIRMED with tool evidence**, plus **[QA-2]**, a *new* vacuous green neither the gate
  nor the reviewer found: the parity check cannot see a key missing from **both** tables, though that
  aborts the installer under `set -u`. Product clean today; the gate is not. → R-7.
- QA marked its own first mutant run **void** (missing `t()` fragment) and re-ran rather than
  reporting it — and fixed its own report when it tripped E.6/F.6, not the checks.

**PM-5 — [QA-4] process conflict adjudicated.** QA's role definition says raise `baseline.json`;
gate A-4/C-10 places it outside the permitted diff and `docs/tasks.md` files it as R-4. **The gate
wins**: a role default does not override a task-specific ruling that was made deliberately and with
reasons. QA followed the gate and left the file unmodified — correct.

### Stage 7 — PM — COMPLETE 2026-08-01 → DELIVERED

`07_DELIVERY.md` written. `docs/tasks.md` updated (T-11 moved to completed; R-7 and R-8 filed; the
stale "B.2/B.3 are permanently SKIP" sentence corrected). One insight harvested — the index sits at
28 file lines / 19 bullets, so one more bullet keeps F.4 comfortably PASS and leaves the next task
headroom. Final `verify_all`: **PASS 16 / WARN 1 / FAIL 0 / SKIP 1**. Live service identical at a
fourth checkpoint. Nothing committed or pushed.

**Harness observation for the owner** (not a task defect): three of the seven stage agents lack a
tool their assigned obligations require — `solution-architect` and `gate-reviewer` have no shell (so
an experiment assigned to stage 2 was unrunnable there), and `gate-reviewer` and `code-reviewer` have
no write tool (so neither could persist its own document). All four gaps were absorbed by the PM
without loss, but they are structural, not incidental to this task.
</content>
</invoke>
