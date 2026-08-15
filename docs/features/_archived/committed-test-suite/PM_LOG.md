# PM Log — T-28 / committed-test-suite

Mode: **full** (7 stages). Invoked by `/harness-batch`, pool `followups`, **final row**.
Decision mode: standing authority granted by the owner (「你来决策就行」). `BLOCKED: NEEDS-HUMAN`
reserved for a genuine safety red line — for this task, any design that could cause `verify_all`
to touch the live service or elevate privileges **is** that red line.

## Pre-flight (2026-08-16)

- `task-state.js` is absent in this project (`.harness/scripts/` is a `.sh`/`.ps1` set). Counters
  are kept in this log instead.
- `.harness/intervention.md` — **absent** (checked before stage 1 dispatch).
- Partition agents: `.harness/agents/` does not exist ⇒ **single-Developer mode**
  (`harness-kit:developer`).
- Baseline measured independently at PM: `bash .harness/scripts/verify_all.sh` →
  **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**. HEAD = `55f39f0`.
- `.harness/scripts/baseline.json` reads `test_count: 0` (R-4/R-9), seventeen deliveries on.
- Insight index read in full (30 lines). Entries surfaced to downstream stages: the whole file is
  named in every dispatch, with lines 14/15/20/21/22/25 (locale, stdout wrapper, fixture loader,
  one-`main()`-per-process) flagged as directly binding on a `bin/sc` test harness.

## Routing decisions

| # | Time | Decision |
|---|---|---|
| 1 | 2026-08-16 | Dispatch stage 1 (`harness-kit:requirement-analyst`). |
| 2 | 2026-08-16 | Stage 1 **READY** — 19 FR / 12 out-of-scope / 16 BC / 24 AC / 16 resolved questions. `.harness/intervention.md` absent at this boundary. **Advance to stage 2.** No rollback. |

### Stage 1 record

Five clauses of the brief refuted or corrected, each with evidence:
1. **A.1 cannot see the suite at all.** A.1's pathspec excludes `.harness/*` in both mirrors, so
   the "fixture credentials trip A.1" hazard is not the real one — the real finding is that the
   secret gate is blind to the directory holding the test artifacts. BC-8/AC-22 bind the content
   anyway, evaluating the regex **with the exclusions removed**.
2. **A `bin/sc` suite is NOT the natural place to close B.2's blind spot.** R-7's blind spot is
   `install.sh`'s Bash `t()` dying under `set -u`; `bin/sc:480-482` returns the key itself, the
   opposite failure direction, no shared artifact. The filed fix would be the silent B.2 widening
   the brief bans. R-7 stays open. The real `bin/sc` analogue is covered instead (FR-13).
3. **R-85 was misattributed by the brief** — the AAAA `[] == []` silent mode is **R-80**; R-85 is a
   CHANGELOG wording row, out of scope. FR-12/AC-12 discharge R-80.
4. **R-71 reports one NOT-DISCRIMINATING criterion plus a related QA-4**; the "two" belongs to
   T-25's block. Substance unaffected — AC-11 still discharges it.
5. **`baseline.json`'s honesty ruling sharpened**: T-07's actual ruling was "nothing in the repo
   *reads* it", so being *read* is the missing act. B.4 reads `test_count` as a **floor**.

PM accepts all five. The brief's clauses are not binding where the code refutes them; the R-9
scope statement is, and FR-14…FR-17 cover all four of its elements.

Note: stage 1 also added one glossary term (`assertion floor`) to `/home/alan/Programs/singbox-cli/CONTEXT.md`
(+8 lines). Not a red-line file; allowed.

| # | Time | Decision |
|---|---|---|
| 3 | 2026-08-16 | Dispatch stage 2 (`harness-kit:solution-architect`). |
| 4 | 2026-08-16 | Stage 2 **READY** — one new file `.harness/scripts/check-sc-contracts.py`, 14 named assertions, 303 lines planned vs the 330 cap, 59/60 external lines. `.harness/intervention.md` absent at this boundary. **Advance to stage 3.** No rollback. |

### Stage 2 record

Rule 85 was applied in both directions and recorded: three sizing calls went to the **smaller**
option (no `sing-box` stub — `SB_BIN` points at a non-existent path, one line and fail-closed; a
two-line `Path`-attribute scan instead of eight named asserts; the `baseline.json` floor comparison
stays in B.4 rather than becoming a `--min` flag in the suite). One went to the **larger**: 14
assertions instead of 7 fat ones, ~20 lines of boilerplate, bought because a fat assertion makes
every clause it contains *look* discriminating once any one clause dies — the exact R-22 hole AC-10
exists to detect. A stopping rule was stated so stage 3 can test it: **one assertion per
independently mutatable clause**.

The R-61 lesson was applied to the cap rather than inherited: the architect **re-derived** its own
element list and confirmed 330 (303 planned, ~8 % headroom) rather than approving a number it had
not checked.

**Three items the architect asks stage 3 to rule on** — carried into the stage-3 dispatch verbatim:
1. **RS-2 / I-10** — FR-6's "exits 0 iff every assertion *defined* was executed and passed" collides
   with AC-3 and AC-10 (a name-selected run would always exit non-zero, so the mutation sweep could
   not read a verdict). The architect's reading: FR-6 governs the default run; a selected run
   reports its own verdict; the summary carries `defined`/`run`/`passed` so B.4's floor is what
   turns a partial run red.
2. **C-8** — a seventh file (`CONTEXT.md`, one glossary entry, 6 lines) beyond the requirement's
   named six. Declared, not slipped in.
3. **C-9** — conditional and predicted empty: a static read of `bin/sc:132-392` found **zero**
   offending `zh` entries, so assertion 14 is a forward guard and BC-11 is not expected to fire.

| # | Time | Decision |
|---|---|---|
| 5 | 2026-08-16 | Dispatch stage 3 (`harness-kit:gate-reviewer`). Reviewer holds no write capability; PM transcribes its returned body verbatim. |
| 6 | 2026-08-16 | Stage 3 round 1 returned **APPROVED FOR DEVELOPMENT** subject to BC-A…BC-K. Pre-write checks passed (declared opening line present, body ends at `## Verdict`, both header-named portions present, no partial return) → transcribed verbatim to `03_GATE_REVIEW.md` + `03_RATIONALE.md`. |
| 7 | 2026-08-16 | **PM routed one finding back to stage 3** (scoped round 2, not a stage rollback). F-2 asserted `docs/tasks.md` is 301 lines and that `verify_all.sh` "WARNs and exits 1 today" — falsified by the PM's own two independent baseline measurements (`EXIT=0`, `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, `grep -c '' docs/tasks.md` = 300, F.5 tests `n > 300`). The measurement is the PM's own baseline duty, not a professional opinion on the review. |
| 8 | 2026-08-16 | Stage 3 round 2 returned; both portions **replaced wholesale** (never appended). Verdict unchanged. `.harness/intervention.md` absent at this boundary. **Advance to stage 4.** Consecutive rollbacks at stage 3: **0** (the round-2 request was a finding correction inside an approving verdict, not a rejection). |

### Stage 3 round record

`round 2 · F-2 amended MAJOR→MINOR (the "tasks.md is 301, so verify_all WARNs and exits 1" premise
withdrawn; zero-headroom-at-cap risk retained and re-worded), BC-C rewritten to discharge AC-1 as
the full PASS 19 / WARN 0 / FAIL 0 / SKIP 1 with exit 0 and no attributable-away WARN, dimensions 1
and 4 re-reasoned · because ripgrep and wc put tasks.md's last line at 300 and insight-index.md at
30 while my round-1 count came from the file viewer's phantom EOF line number, and
verify_all.sh:216/224 compare strictly while :248-250 exits 0 at warns=0 · F-2 (and BC-C)`

**Why this mattered enough to spend a round.** F-2 was MAJOR and drove BC-C, which as originally
worded would have let stage 4/6 ship with a residual WARN and attribute it to a pre-existing cap.
That is one step away from "`verify_all` weakened to make a step pass", the task's own hard
constraint. The amended BC-C now demands **all four numbers plus exit 0** and forbids attributing
any WARN away. The gate diagnosed its own error rather than merely conceding it: its file viewer
numbers the empty position after the final newline, which produced a phantom `301` on
`docs/tasks.md` and a phantom `31` on a 30-line index — an artifact worth knowing about, since it
would recur on any cap file read that way.

**The gate's own contribution beyond the requirement** (carried into stage 4's dispatch as binding):
- **F-1 / BC-A — the safety spine was found insufficient and strengthened.** The dev-map recipe
  neutralises a **predicate** (`geteuid`), not a **capability**: the shim copies the real
  `os.__dict__`, so `os.execvp` stays live, and a future `bin/sc` refactor to `os.getuid()`,
  `os.getresuid()` or `os.geteuid() > 0` would re-exec `/usr/local/bin/sc` under `sudo` from inside
  `verify_all`, forever — R-78's exact incident. The inherited "fails closed if `geteuid` moves"
  claim is **false** and BC-B forbids carrying it forward unnarrowed.
- **F-3 / F-4 → BC-D / BC-E — R-61 was applied rather than repeated.** The gate found BOTH caps not
  credible and **amended** them against re-derived element lists (external 60 → **80**, metric
  defined as `+` lines per `git diff --numstat`; suite 330 → **350** over a floor of 325) instead of
  approving numbers it disbelieved. This is precisely what T-07's gate failed to do.
- Rule 85's required test was **performed, not asserted**: a 14-row mutation table showing every
  assertion has a private mutation (no pair should merge), and all three smaller-direction calls
  re-tested for what they gave up. It refuted the architect's stated *ground* while sustaining the
  design — per-clause mutation, not assertion count, is what closes R-22 (F-8/BC-I).

| # | Time | Decision |
|---|---|---|
| 9 | 2026-08-16 | Dispatch stage 4 (`harness-kit:developer`, single-Developer mode — no `.harness/agents/dev-*.md`). |
| 10 | 2026-08-16 | Stage 4 **READY FOR REVIEW**. Stage gate for stage 5 (`verify_all` PASSED in the development doc) is **met** and re-measured by the PM. `.harness/intervention.md` absent. **Advance to stage 5** with the cap overruns as the reviewer's first required ruling. No rollback. |

### Stage 4 round record

`round 1 · initial implementation of C-1…C-8, C-9 not fired · verify_all 19/0/0/1 exit 0 · no
findings to answer`

**PM's own independent re-measurement after stage 4** (not taken from the developer's report):
- `bash .harness/scripts/verify_all.sh` from the repo root → **PASS 19 / WARN 0 / FAIL 0 / SKIP 1**,
  **EXIT=0**. AC-1 discharged in full; no residual WARN to attribute away (BC-C).
- Live-service witness `systemctl show` → `MainPID=2566751`, `NRestarts=0`,
  `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` — identical to the batch loop's independent
  pre-task check. `is-active` never invoked.
- `git status` confirms **`bin/sc` is untouched** (C-9 did not fire — assertion 14 found
  `182 entries in 1 table(s), 0 offenders`, confirming the gate's BC-K prediction).
- `check-sc-contracts.py` is 446 lines, mode 0755, beside `check-i18n-parity.sh` (FR-1 placement).

**Two declared drifts, carried to stage 5 as its first ruling:**
- **D-1 — the suite is 446 lines against BC-E's amended 350 cap** (+27 %), over `02_RATIONALE.md`'s
  303-line derivation; the developer reports every element ran over except `fixture()`.
- **D-2 — 92 added lines externally against BC-D's amended 80** (net +46; C-5 is +20/−20, net 0).

The developer **refused K-14's trim step 2** (merge assertions) on the ground that it contradicts
K-17/BC-I and would move `baseline.json`. That is a reasoned refusal, not a shrug, and it is the
right shape — but a cap blown twice after being amended twice is exactly R-61's subject matter, so
it is routed to the independent reviewer rather than accepted here. **T-07's precedent is the
model**: its stage 5 spent the burden of proof region by region and judged a 330-line result
*earned*, demanding no refactor and dropping nothing to make a number. The PM does not rule on it —
that is a professional judgment and belongs to stage 5.

**BC-A was implemented as a capability defence, not a predicate defence** (the gate's F-1): every
`exec*` / `spawn*` / `fork*` name plus `system` on the shim raises `LoadRefused`. Recorded against a
scratch `bin/sc` copy whose guard reads `os.getuid()` — the load refuses, `os` is restored, `0 run`,
`EXIT=2`. The developer also declares the defence's **limit** in the file header: an import-time
re-exec routed around the module's `os` (via `subprocess`, `ctypes`) is not denied. Stage 5 must
rule whether that stated limit is acceptable.

| # | Time | Decision |
|---|---|---|
| 11 | 2026-08-16 | Dispatch stage 5 (`harness-kit:code-reviewer`). Reviewer holds no write capability; PM transcribes its returned body verbatim. |
| 12 | 2026-08-16 | Stage 5 returned **CHANGES REQUIRED (0 CRITICAL, 1 MAJOR)**. Pre-write checks passed → transcribed verbatim to `05_CODE_REVIEW.md` + `05_RATIONALE.md` (the returned bodies were wrapped in transport code fences; the fences are the message envelope, not document content, and were not written — nothing inside them was altered, added to or repaired). `.harness/intervention.md` absent. **ROLLBACK 1 → stage 4 (developer)**: CR-1 is a code defect, and only the implementer fixes code. |

### Stage 5 record

**CR-1 (MAJOR) — the safety spine was found short a second time, one level up.** Stage 4 replaced
the gate's predicate defence with a **capability** defence, but implemented it as a *name prefix*
test: `name.startswith(("exec", "spawn", "fork")) or name == "system"`. Three process-start names
in `os` fall outside it — **`os.popen`** (spawns `/bin/sh -c`), **`os.posix_spawn`** and
**`os.posix_spawnp`**. The reviewer's words: *a name prefix is not a capability either* — the same
substitution the gate's F-1 caught at the predicate level, repeated one level up. Nothing is live
today (`bin/sc:126` uses `os.execvp`, covered), but BC-A's entire content is the **forward**
guarantee, and the file header's "Covered: … whatever uid source its guard reads" is false as
written while `docs/dev-map.md:134` now propagates the incomplete list as project guidance.

This is the third stage at which this task's safety spine was strengthened by a stage that did not
introduce the weakness — the T-07 pattern ("four vacuous greens, each at a different stage, none by
the stage that introduced it") holding again.

**Both cap overruns ruled EARNED, and both caps amended rather than approved-in-disbelief.** The
reviewer did the T-07 arithmetic region by region: binding floor **429**, delivered **446**,
recoverable surplus **≈17** (3.8 %) — and **tested** stage 4's refusal of the merge instead of
accepting it, showing the maximal permitted in-group merge (14→7) lands at ≈390, *still* over
BC-E's 350, so the cap was **unattainable by every permitted lever combined** and could only be met
by dropping a clause, which BC-D/BC-E forbid in the same breath. Cap amended to **450/429**. D-2's
metric was likewise falsified: `git diff --numstat`'s `+` count charges an in-place rewrite twice
(C-5 is +20/−20, **net 0**), so it measures editing style, not growth; restated as **60 net**, the
delivered figure is **46** — inside even the original budget. R-61's lesson has now held at three
stages of this one task, each time by amending against a re-derivation rather than trimming to a
number.

**The reviewer's own R-22 pass**: all 14 private mutations from the gate's table were re-checked
against the *delivered* fixtures and all 14 survive — no implementation choice destroyed one — plus
one systemic caveat handed to stage 6 (`LANG = "en"` with no `en` table means the sentence
assertions are literal comparisons in a `t()` costume, so a zh-only wording mutation is invisible
to the 14).

**Rework scope routed to stage 4** — CR-1 (MAJOR, required), CR-2, CR-3, CR-4, CR-7, CR-9. CR-5 and
CR-6 are rulings requiring no code change; CR-8 is a note so stage 6 does not misread a pre-existing
line as this task's AC-22 failure.

| # | Time | Decision |
|---|---|---|
| 13 | 2026-08-16 | Re-dispatch stage 4 (`harness-kit:developer`) for the CR-1…CR-9 rework. Consecutive rollbacks at stage 4: **1** of 3. |
| 14 | 2026-08-16 | Stage 4 round 2 **READY FOR REVIEW**. PM re-measured: `PASS 19 / WARN 0 / FAIL 0 / SKIP 1`, **EXIT=0**; suite **449** lines vs the amended 450 cap; live service identical (`MainPID=2566751`, `NRestarts=0`, same `ActiveEnterTimestamp`); `bin/sc` still untouched. `.harness/intervention.md` absent. **Advance to stage 5 round 2** (the reviewer must rule on its own findings' closure and on the self-found D-6). |

### Stage 4 round-2 record

`round 2 · CR-1: the shim's denial list now enumerates every process-start name in dir(os)
(exec/spawn/fork/system + popen + posix_spawn), and the header's "Covered:" sentence plus
docs/dev-map.md's recipe were corrected to say the list IS the guarantee; CR-2: _execute no longer
returns early on load/fixture failure, so BC-5's after-witness runs on both exit paths (exit 2
preserved); CR-3: the inside-root predicate is now == root or startswith(root + os.sep); CR-4:
encoding="utf-8" moved into the copy-pasteable recipe block; CR-7: the two-line docstring re-flowed
to one line so --list stops truncating; CR-9: the recipe's repointing clause now names nine
constants incl. LIB_DIR; also found and declared D-6 · why: stage-5 finding CR-1 (MAJOR) made BC-A's
forward guarantee and its header sentence false, and CR-2/3/4/7/9 were MINOR/NIT contract
inaccuracies · findings CR-1, CR-2, CR-3, CR-4, CR-7, CR-9 (+ self-found D-6)`

**The CR-1 fix was proved with a control, not asserted.** Three scratch `bin/sc` copies (guards
reading `os.getuid()` + `os.execvp`, + `os.popen`, + `os.posix_spawn`) are each refused with
`LoadRefused`, `os restored True`, `0 run`, exit 2 — and the **control** re-ran the `posix_spawn`
copy under the *round-1* filter, where it was **not** denied (`FileNotFoundError` from the real
`os.posix_spawn`, i.e. the call went through and stopped only on the missing path). That control is
what makes the fix a demonstration: it shows the hole was real and is now closed. The `popen` copy's
payload string never printed, so no shell ran.

The mechanism stayed **name-based on purpose** and the alternatives were priced: an `os` allow-list,
a second `subprocess` shim, and `sys.addaudithook` (3.8+, below this project's 3.6 floor) are all
larger. Rule 85 applied to a fix, not just to a design. Net cost of the whole round: **+3 lines**
(449 vs 446), and two of them were paid for by reclaiming comment lines elsewhere.

**D-6, self-found and declared: the PM can resolve its provenance from this log.** Round 1 reported
`CONTEXT.md` as +8 lines / one glossary entry, and the gate's PQ-2 called the **assertion floor**
entry pre-existing at `CONTEXT.md:198-203`. Neither is right about HEAD: **stage 1 wrote that entry**
(recorded in this log at decision #2, "+8 lines"), so the gate was reading the uncommitted working
tree, and round 1's own C-8 entry is the second. `CONTEXT.md` is now **+15 / two entries**, which is
the honest figure. No red line is involved (`CONTEXT.md` is the project glossary, not a stub), and
both entries are this task's own work — but stage 5 should rule on it rather than the PM.

| # | Time | Decision |
|---|---|---|
| 15 | 2026-08-16 | Re-dispatch stage 5 (`harness-kit:code-reviewer`) round 2. |
| 16 | 2026-08-16 | Stage 5 round 2 returned **APPROVED**. Pre-write checks passed → both portions **replaced wholesale**. `.harness/intervention.md` absent. **Advance to stage 6.** Consecutive rollbacks at stage 4 reset to **0** (the rework was accepted). |

### Stage 5 round-2 record

`round 2 · re-verified CR-1…CR-4/CR-7/CR-9 against the delivered tree and ruled the new
self-declared D-6 · CR-1 closed (denial tuple POSIX-complete, control run valid), CR-2/CR-3/CR-4/
CR-7/CR-9 closed, three new NIT/MINOR raised (CR-10 os.startfile, CR-11 dev-map eight-vs-nine,
CR-12 D-6 cause misattributed), BC-E re-derived to 465 over floor 432 · findings CR-1, CR-2, CR-3,
CR-4, CR-7, CR-9, CR-5, CR-6, CR-10, CR-11, CR-12`

**CR-1 closed by enumeration, not by assurance.** The reviewer checked the delivered tuple name by
name against CPython's POSIX `os` and confirmed every process-start family is matched
(`exec*`, `spawn*`, `fork`/`forkpty`, `system`, `popen`, `posix_spawn`/`posix_spawnp`), that
`"system"` as a *prefix* over-denies nothing, and that nothing else in `os` starts a process. It
also ruled the developer's **control** valid and discriminating: the same scratch copy raises
`FileNotFoundError` under the round-1 filter (the real `os.posix_spawn` ran) and `LoadRefused`
under the delivered one — two distinguishable outcomes, one variable changed. One residual, **CR-10
at NIT**: `os.startfile` is Windows-only and unmatched, so the header's "EVERY process-start name in
`dir(os)`" is true on POSIX and false on Windows. No live exposure (B.4 SKIPs on the `.ps1` mirror).

**The cap was re-derived a fourth time and, this time, for a stated reason.** 303 → 325/350 → 450 →
**465** over a measured floor of **432** (delivered 449). The reviewer's ruling is the one worth
keeping: *a cap's job changes once the artifact exists* — before delivery it estimates an unwritten
file, after delivery it is a maintenance ratchet whose derivation should be measured. A 450 cap over
a 449-line file "constrains nothing except the next required clause". D-2 likewise settled at **50
net vs 60 net**, the `+`-only metric withdrawn (it charges an in-place rewrite twice).

**CR-12 — the reviewer refused to let a false cause travel.** Stage 4's self-declared D-6 blamed the
design and the gate for citing a `CONTEXT.md` range that "carries the state-document entry". The
reviewer read the file (`:189-196` state document, `:198-204` assertion floor, `:206-211` contract
suite) and used the PM's provenance from this log: **stage 1 wrote the assertion-floor entry during
this task**, so PQ-2 read the working tree correctly and stage 4's `git show HEAD:CONTEXT.md` was
looking at a commit predating its own task's stage 1. Left uncorrected, D-6 would have told a future
gate that a stage-3 citation was fabricated — *a worse defect than the one it was declaring*. The
content (two entries, +15 lines, no governing cap) is accepted; only the stated cause is struck, and
RES-10 carries the correct sentence to delivery.

The reviewer also corrected **its own** round-1 omission in writing (AC-4 was missing from the
coverage table) rather than silently repairing it — the same honesty discipline it applied upstream.

| # | Time | Decision |
|---|---|---|
| 17 | 2026-08-16 | Dispatch stage 6 (`harness-kit:qa-tester`). |
| 18 | 2026-08-16 | Stage 6 **APPROVED FOR DELIVERY** — 24/24 AC PASS, 0 FAIL, 0 BLOCKED, no operator obligation added. `## Adversarial tests` heading present and unnumbered (line 38; `verify_all` E.6 PASSes). PM re-measured `PASS 19 / WARN 0 / FAIL 0 / SKIP 1`, EXIT=0. `.harness/intervention.md` absent. **Stage gate for delivery met** (stages 5 and 6 both PASS). **Advance to stage 7.** |
| 19 | 2026-08-16 | Stage 7: compose `07_DELIVERY.md` → entropy watch → `docs/tasks.md` → `archive-task.sh` → commit + push. |

### Stage 6 record

The sweep was taken **per clause** as BC-I requires: **32 clauses, 29 killed, 14/14 assertions killed
at assertion level**, every mutation applied to a scratch **copy** of `bin/sc` driven through the
suite's own `--source` — so no mutation machinery is committed. **3 clauses NOT-DISCRIMINATING, all
pre-declared and each confirmed rather than inherited**, none newly found: two are fixture *controls*
no `bin/sc` mutation can reach by design (the bare `mkstemp` reading 0400 at umask `0o277`; the
`json.loads`-accepts-these-bytes pre-assertion), and one is logically implied by its sibling clause.

**Three things QA did that the PM did not ask for and that matter:**
1. **It re-took BC-A's proofs independently instead of inheriting stage 4's** — and the control is
   decisive. Under the round-1 prefix-only filter a `bin/sc` guard calling `os.popen` **started a
   shell** (`PROBE ARTIFACT … EXISTS: True`) while the suite reported `14 defined, 14 run, 14
   passed`, **exit 0**. A fully green run with a process started from `bin/sc`'s import. CR-1 was not
   theoretical.
2. **It refuted CR-8 rather than inheriting it.** A.1's regex is case-**sensitive**
   (`case-sensitive: 0 / case-insensitive: 1`), so the reviewer's predicted pre-existing hit at
   `restricted-network-regression.sh:43` does not exist at all.
3. **It swept something outside the 14** — the host-witness comparison itself — and found a falsified
   `before` yields `14/14 passed` **with exit 1**: a green suite still reddens B.4 when the host moved.

It also confirmed RES-3 the right way round: deleting `encoding=` **survives** on this UTF-8 host and
only a codec substitution kills, so the obvious sweep would have reported a **false kill**.

### Stage 7 record

- **Entropy watch: NOT-DUE, fail-open.** `.harness/scripts/entropy-cadence` does not exist on this
  host — the standing condition **R-88** already records, with the stated consequence that the
  cadenced holistic sweep never fires here. No `entropy-cadence delivered`, no scan, no
  `## Entropy watch` section, delivery unchanged. Same handling as every task since T-16.
- **`docs/tasks.md` kept under F.5 by rotating COMPLETED work first**, per rule 70's ordering: T-26's
  completed row moved to `docs/tasks-archive.md`, then T-07's `R-56 … R-61` block moved after it with
  a pointer bullet left behind (three of its rows close here, three stay open). Board: **300/300**,
  F.5 PASS (strict `>`). No cap was edited and no open row was displaced to make room.
- Rows closed and stated plainly: **R-9** (five deferrals), **R-4**, **R-6**, **R-56**, **R-58**,
  **R-59**, **R-71**, **R-80**. **R-57 stays open** by stage 1's explicit ruling. **R-85 was not this
  task's row** — the brief misattributed it, and it stays open with its own owner. Rows filed:
  **R-93 … R-96**.
