# PM Log — T-30 `validate-before-baseline`

> Mode: **full** (7 stages). Pool: `closeout` (`docs/batches/closeout/BATCH_PLAN.md`).
> Decision mode: standing authority granted by the owner ("你来决策就行") — resolve judgment calls
> downstream and record them; `BLOCKED: NEEDS-HUMAN` only for a genuine safety red line.

## Task start — 2026-08-16

- Goal: stop a configuration from being written and its drift digest baselined onto a document the
  checker then rejects (**R-73**), and stop `sc reload` tracebacking on a host with no `sing-box`
  binary (**R-70**) — one ordering, two symptoms. **R-81** rides along only if it is one line.
- HEAD at start: `fc634e3` (T-29 delivered).
- Intervention check #1 (before stage 1 dispatch): `.harness/intervention.md` **absent**.
- `node .harness/scripts/task-state.js show validate-before-baseline` → **module not found**; the
  script does not exist on this host. This is **R-88**, a known and ruled standing absence. Handled
  **fail-open**: no durable counters this task; rollback streaks tracked here by hand, as every task
  since T-16 has done. `.harness/scripts/entropy-cadence` likewise absent ⇒ the delivery-time
  **entropy watch resolves NOT-DUE**; no `## Entropy watch` section will be written. Recorded, not
  hidden.
- **Insight index queried before stage 1** (drift / digest / `_record_generated` / `_write_private` /
  checker / reload / ordering / fixture-loader / locale). Seven applicable entries were surfaced
  **whole** into the stage-1 and stage-2 dispatch prompts, and the fixture-trap entries into every
  later dispatch. The load-bearing one for this task is the `override-error-envelope` line: *the
  silent-replacement-reaches-disk class is only reachable at an unguarded array key, where HEAD
  overwrites `config.json` and baselines its digest before the checker runs — the harm that survives
  un-stubbing is the overwrite plus the baselined drift record, never the exit code.*
- Related historical tasks listed for downstream: T-24 (established R-73's mechanism by refuting its
  own brief), T-13 (`_write_private()`), T-14 (digest-never-a-copy), T-10 (one apply per run), T-19
  (the outcome path), T-02 (自动恢复 ordering), T-05/T-20 (`doctor` read-only, no second opinion),
  T-29 (the settings refusal; the four-document-catch gate finding).

---

## Compacted stages (rule 70, compacted 2026-08-16 at the stage-4/5 boundary)

Full narrative for stages 3 round 2 and 4 round 2 follows below; these entries are condensed.
Nothing here is a verdict change — every stage's verdict, evidence and ruling is preserved.

- **Stage 1 · requirement-analyst · round 1 · READY · advance.** Ordering **re-verified first-hand,
  not inherited**: `bin/sc:2149` `_write_private(CFG_PATH, text)` → `:2154` `_record_generated()` →
  `:2156` the checker → `:2158-2160` stderr + `return False`. **R-70 + R-73 ruled ONE design** (Q-2),
  on rule 85's *duplicated-judgment* test rather than its first seam test — one judgement with two
  arms, sitting after the irreversible act. **True consequence established as SEVERE with evidence**
  (Q-1): the rejected document stays at `/etc/sing-box/config.json`, which `systemd/sing-box.service:9`
  reads at *every* start under `Restart=on-failure`, and the weekly timer restarts on `changed and not
  gained` **without** regenerating (`bin/sc:3400`, `:3415-3420`) — an unattended outage up to a week
  after the error the user saw. The baselined digest is the **milder** half; **the harm is in the
  write, not the record**, which is what shrank the fix to the ordering. **R-81 ruled NOT a
  ride-along** (Q-3, needs a widened return plus two rendering decisions); **R-100 not re-opened**
  (Q-4); **R-12 not widened** (Q-5). **Q-6 forecloses the tempting one-liner** — moving only
  `_record_generated()` below the check would make `_drift_state()` accuse the user of a write `sc`
  performed. Q-7: cannot-validate ⇒ install + warn + success. 13 ACs, AC-1 the mandatory happy-path
  anchor that kills both "reject everything" and "write nothing"; AC-11/AC-12 **BLOCKED with discharge
  recipes**, nothing substituted. Coined **one** glossary term in `CONTEXT.md` (*checker verdict*).
  Budget NFR-3 ≤ 25 net added executable lines.
- **Stage 2 · solution-architect · round 1 · READY · advance.** Design: **candidate → verdict →
  install → record**, using the existing `_write_private()` at one extra `O_EXCL` name in
  `config.json`'s own directory and the existing `_doctor_run()` for the checker. **Smaller
  alternative named and priced** per rule 85: **S-2** (`os.replace` instead of a second
  `_write_private()`) is equal in lines and cheaper at runtime, rejected on BC-7; S-3 and S-4 also
  priced. Budget +19 derived line-class by line-class. **B.4: one assertion, floor 17 → 18; no `ast`
  check** (R-97's ground — it pins a spelling). **Q-8 re-opened explicitly and UPHELD.** Single-
  developer mode confirmed (`.harness/agents/` does not exist).
- **Stage 3 · gate-reviewer · round 1 · APPROVED WITH CONDITIONS (C-1…C-11) · advance.**
  1 RULING, 4 MAJOR, 8 MINOR. **S-2 re-priced independently and upheld on a ground stage 2 did not
  state** — `config.json`'s mode/symlink/atomicity guarantees are pinned in the committed suite only
  where `_write_private` is pinned, so S-2 would move the final arrival out from under both
  assertions. **No fifth shape exists**, established by exhausting the three degrees of freedom.
  **RS-4 ruled SOUND** (G-0): `errors="replace"` is total, so FR-4's third disjunct has an empty
  extension and a fourth arm would be unreachable code. **Budget re-derived, not accepted** (G-8) —
  +19 is a *prediction of a formatting outcome*; C-8 forbids trimming a message, comment or `try` arm
  to reach it, and NFR-3's 25 is the bound. **Three rows reported NOT-DISCRIMINATING rather than
  passed** (G-2, G-3, G-5). **G-1 (MAJOR)**: the design's central mechanism rested on an unestablished
  property of a binary this project does not control — *exactly the test S-4 was rejected on, never
  applied to the shape that was chosen* — discharged by C-1's one real command.
- **Stage 4 · developer · round 1 · READY FOR REVIEW · advance.** **C-1 POSITIVE against the real
  `/usr/local/bin/sing-box` 1.13.15**: identical bytes at a `*.json` and a `config.json.check.*` name
  give identical exit status and byte-identical messages modulo the path; `check -c` **ignores the
  extension**. Two answers C-1 was not asked for changed the code — the checker **interpolates the
  path it was handed** (so the `.replace()` is load-bearing) and it **colours into a pipe**, the
  property a stub cannot exhibit and that shipped as T-05's DEF-1. `verify_all` PASS 19/0/0/1; B.4
  18/18/18; live host bit-identical. Budget +19, measured with an **`ast` classifier over both whole
  files** because `git diff -U0` matched 7 of the 13 rewritten lines as context and would have
  reported 6 removed — a budget-provenance defect the developer caught on itself. **D-1 raised for the
  reviewer rather than resolved quietly.** **G-2's trap reproduced live.** AC-11 **not** blocked;
  AC-12 **BLOCKED**, nothing substituted.
- **Stage 5 · code-reviewer · round 1 · ROLLBACK TO SOLUTION-ARCHITECT.** 3 MAJOR, 3 MINOR, 4 NIT.
  **CR-1**, confirmed first-hand by the PM before routing: `tempfile.mkstemp()` sat **outside** the
  `try`, so an `OSError` creating the candidate escaped `generate_config()` uncaught — `main()`'s
  envelope takes `OverrideError` **only**, `cmd_reload()` has no `try`, `cmd_update_rules()`'s
  recovery arm re-raises anything whose `.path` is not `SETTINGS_PATH` — a traceback with **no
  run-level outcome line** where HEAD printed one sentence. **BC-11 violated.** *Routed to the
  architect, not the developer*: the code was **faithful** to I-1/I-2 as written, the hole was at the
  design's boundary, and the repair was the twelfth statement **K-1 forbade the developer to add**.
  The reviewer deliberately declined to choose between the two shapes. CR-2/CR-3 (MAJOR) are prose
  *this change falsifies* — R-74's class. **CR-4 is the second instance of G-2's prefix shape**,
  reported NOT-DISCRIMINATING. **D-1 UPHELD.** **RES-6 disclosed rather than hidden**: no shell at
  stage 5, so nothing was re-run there.
- **Stage 2 · solution-architect · round 2 · READY · advance.** Chose **shape 2** (widen the existing
  `try` to enclose the `mkstemp`; sentinel `name = None`; `if name is not None:` in the `finally`) —
  the smaller shape, but **on rule 85's argument rather than on size**: *one judgement, one home*
  (I-9 already owns "the filesystem refused to put this document on disk"), and shape 1's two guarded
  regions would leave *"is this statement guarded?"* a per-statement question — **the question whose
  wrong answer produced CR-1**. Priced shape 2's own cost honestly (a `finally` with a precondition;
  deleting the guard yields `os.unlink(None)` → `TypeError`, CR-1's class, rarer) and answered it with
  **a fourth arm on the B.4 assertion — zero executable lines in `bin/sc`**. Rejected a +0-line
  `except (OSError, NameError)` variant. **K-1 re-stated to fix the meta-defect**: *"the bound is the
  enumeration, not a count."* Budget +21 against 25. **I-14 gains CR-4's `dirname` clause explicitly**,
  with the containment spelling named vacuous so it cannot be reached for. Ledger gaps closed
  proactively (E-4's `:105-106` bullet, E-6's CHANGELOG scoping).
- **PM ruling — no stage-1 round** (later confirmed independently by the gate as H-8, and made
  binding as C-22). The architect reported Q-5 falsified. Read against the **round-2 design** rather
  than the round-1 build, Q-5's "moves one and removes three" is **true again** — the rejection unwind
  still moves and the three traceback paths still go, and nothing is added — and Q-4's "so R-100's
  population shrinks" is restored to strictly true. Q-5 was falsified only by an implementation shape
  that no longer exists; rolling stage 1 back to re-state a sentence the correction has made true
  would be a document round for nothing. RS-8 travels to `07_DELIVERY.md` as a **note**.

Rollback tally to this point: **1** (stage 5 → stage 2). Streak at any one stage: **1 of 3**.
Intervention checks #1…#7 all found `.harness/intervention.md` absent.

---

## Stage transitions (current)

### Stage 3 — gate-reviewer · round 2 · **APPROVED FOR DEVELOPMENT WITH CONDITIONS** · advance

- Both portions returned complete under headers naming their paths, opening lines and `## Verdict`
  present, nothing partial. **Content at both paths REPLACED, not appended** — transcribed verbatim.
- Findings: **1 MAJOR (H-2), 7 MINOR, 2 NIT, 3 RULINGS (H-0, G-0 carried, H-10). No FAIL.**
- **The gate did the reading it had not done in round 1, in the other direction, and said so.** Its
  round-1 dimension-2 audit read "a `finally` that covers `return False`" and never asked what lay
  *outside* that statement — which is how CR-1 shipped. Round 2 walks the whole tail statement by
  statement in a table with two columns: *inside the `try`?* and *can it raise?*
- **H-0 — shape 2 upheld, on a ground the architect did not use.** The sentinel plus
  `if name is not None:` around a guarded `unlink` in a `finally` is **already this file's own
  idiom** — `_write_private` itself ends in exactly that shape (`bin/sc:533-541`, with `if fd >= 0:`
  beside it), inside T-13's frozen writer, thirty lines from the new code. So the new fence is a
  **reuse of an existing shape**, not the novel invariant the architect priced. The gate also **struck
  down the architect's third argument** (headroom): *"an argument about a number, and if it were the
  deciding argument the decision would be wrong."*
- **And it named the cost the smaller shape hides, which the architect did not**: shape 2 converts a
  **structural** property into a **tested** one — arm 4 alone carries the whole guarded-region
  invariant — the very shape `docs/dev-map.md:76` already records a scar about. Ruled the right trade
  anyway, and priced it the only way it can be: **C-14 requires the arm's own docstring to say it is
  the sole control.**
- **H-2 (MAJOR) is the round's real catch, and it is a test-feasibility defect, not a code one**:
  V-14's observable *"exactly one stderr line"* **cannot hold in the fixture V-14 itself mandates** —
  the loader recipe's `rules/` is empty, so `_warn_degraded()` writes first. Caught **before** the
  developer ran it. C-15 corrects the observable to the line, never the count.
- **Arm 4's two directions REASONED, not measured** — the gate had no shell and **labelled that
  explicitly** rather than presenting reasoning as measurement. It found *four* mutation spellings,
  not two, and confirmed the arm **reachable** and child-process-free. Carried into stage 4 as a
  demand to convert it to a measurement.
- **The +0-line variant re-priced from scratch** rather than accepting "a trick": `UnboundLocalError`
  **is** a `NameError`, the variant is genuinely 2 lines cheaper and equally controlled in one
  direction — then killed on a ground the architect never stated: its failure mode (`os.unlink(nmae)`,
  or a later rename) is **caught and passed**, leaving a `0600` credential file under `/etc/sing-box`
  on every run, and **no arm can redden it**.
- **H-6 — the prefix/containment shape found a THIRD time in one change**, named as a class: *a clause
  asserting containment or membership over a directory or path string is satisfied by the wrong build
  whenever the object under test is named after, or lives beside, the object it is being distinguished
  from.* Closed at two of three by `dirname`; the third rests on C-2's second direction and no
  committed control — recorded, not re-opened.
- **H-10 ruled ACCEPTED with reasoning written down**: a `sys.stderr.write` raising inside the outer
  handler still escapes, but HEAD's handler has the identical shape at the identical place, so BC-11's
  **floor** wording is not violated; a fix needs three nested `try`s or an `except Exception` envelope
  K-12 forbids. Travels as C-20 *"so the next reviewer does not have to re-derive it either."*
- **H-3/H-4 — the gate caught its own class recurring in the same task**: this round falsifies
  `docs/dev-map.md:87`'s "three arms", which the ledger did not authorise (CR-2's class, two rounds
  apart, same file); and the ledger's coordinates are HEAD-relative while the next round is a delta on
  the delivered tree (C-16 stops anyone incrementing a floor a fourth *arm* does not move).
- **C-1…C-6 marked DISCHARGED per condition** so the developer does not re-spend the round; C-7…C-22
  bind it.
- Intervention check #8: absent. **Route: advance to stage 4 (developer, round 2).**

### Stage 4 — developer · round 2 · **READY FOR REVIEW** · advance

- **Round record:** *round 2 · the guarded region widened to enclose `tempfile.mkstemp` — sentinel
  `name = None` (`bin/sc:2163`), `try:` (`:2164`), `mkstemp` re-indented as its first statement
  (`:2165-2166`), `if name is not None:` in the `finally` (`:2211`); **exactly 2 executable lines**
  (C-12). `check-sc-contracts.py` gained arm 4 with C-14's three-fact docstring and the
  `os.path.dirname(cmd[3]) == str(sc.CFG_DIR)` clause on arms 1-3 (C-17); count and `baseline.json`
  held at 18/18 (C-16); four prose corrections landed (C-10, C-18). · why · **CR-1 (MAJOR)** ·
  discharging CR-1 with CR-2, CR-3, CR-4, CR-6, CR-7 in the same round.*
- **The gate's reasoning was converted to MEASUREMENT, which is what the round asked for**, against a
  `git clone --no-hardlinks` of HEAD `fc634e3` (never a worktree):
  | direction | mutation | B.4 |
  |---|---|---|
  | A | guard deleted, body dedented | **RED** 18/18/**17** — `TypeError: unlink: path should be string, bytes or os.PathLike, not NoneType` |
  | A′ | sentinel deleted too | **RED** 18/18/**17** — `UnboundLocalError` |
  | B | `mkstemp` moved back above the `try:` | **RED** 18/18/**17** — `FileNotFoundError`, **zero** `Could not write` lines — **CR-1 reproduced exactly** |
- **Bonus probe worth more than it cost**: a `dir=None` (TMPDIR) build **passed round 1's assertion in
  full** and goes red only on the new `dirname` clause. **CR-4's gap was real**, and is now closed by
  measurement rather than by argument.
- Arm 4 **PASSES on the HEAD clone** and on this build, exactly as classified — a regression control
  for this design's boundary, never a HEAD discriminator; the rejected arm remains the discriminator
  (`AssertionError: rejected: the checker was pointed at config.json itself`).
- Re-measured independently by the PM over the delivered tree: `verify_all` **PASS 19 / WARN 0 /
  FAIL 0 / SKIP 1**; B.4 **`18 defined, 18 run, 18 passed`**, `baseline.json` untouched at 18/18, and
  the assertion's own line now reads *"one check per call **in CFG_DIR** at a non-config.json path,
  mode 0600, config.json intact at verdict time; rejected -> False, accepted -> True, cannot-run ->
  True, **candidate-uncreatable -> False, no raise**"*. Live host **bit-identical**: `MainPID=2566751`,
  `NRestarts=0`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`; `is-active` never invoked.
- Budget: **+21 net executable** (2097 → 2118 whole file; `generate_config()` alone 61 → 82 — the same
  figure by a second method), **exactly the prediction**, against NFR-3's **25**. Round-1 → round-2
  delta measured by reconstructing the round-1 build: **+2 executable**, +11 comment. **Nothing
  compressed, no comment deleted, no `try` arm dropped** (C-8 honoured).
- **C-7 re-taken on the round-2 build, not carried**: `_plain` hash `f04a53be6c5599c8`, identical to
  HEAD, now at `:2549-2591` — **moved 56 lines, changed zero bytes**. `_write_private`
  `c394797931d99deb` on both sides (K-2/BC-7 intact).
- **D-3, disclosed rather than quietly absorbed**: the gate cited `bin/sc:2258` / `:3523` for the two
  surviving `capture_output=` sites; this round's own +13 physical lines moved them to **`:2271` /
  `:3536`**. The developer corrected the dev-map text to the true coordinates and flagged that
  `.harness/rejected-decisions.md:228` (PM-owned) still says "three".
- Intervention check #9 (after stage 4 round 2): `.harness/intervention.md` absent.
- Stage gate satisfied: `verify_all` PASSED, shown in `04_DEVELOPMENT.md` and re-measured here.
- **Route: advance to stage 5 (code review, round 2).** Rollback streak at stage 4: 0.

### Stage 5 — code-reviewer · round 2 · **APPROVED WITH FOLLOW-UPS** · advance (with one targeted round 3)

- Both portions returned complete under headers naming their paths; **content REPLACED, not
  appended**; transcribed verbatim.
- **0 CRITICAL, 0 MAJOR open.** 6 MINOR (CR-5 carried, CR-11, CR-12, CR-13, CR-17 new; CR-7 carried
  as recorded-not-fixed), 3 NIT, **5 CLOSED from round 1 (CR-1, CR-2, CR-3, CR-4, CR-6)**.
- **CR-1 CLOSED, verified as control flow rather than from the comments** — the reviewer explicitly
  ignored the new comment block and walked the statements: `:2163` sentinel → `:2164` `try:` with
  nothing between → `:2165-2166` `mkstemp` first → `:2211` guard → `:2216` `_record_generated()`
  after the whole statement. Its round-1 source-only finding was confirmed by the developer's
  direction-B measurement (uncaught `FileNotFoundError`, **zero** `Could not write` lines) —
  *"the strongest possible confirmation of a source-only finding."*
- **RES-6 stands: stage 5 had NO shell in either round.** The reviewer was asked to check and use one,
  found none, and **said so again in the same place rather than presenting reasoning as measurement**.
  It converted what reading *can* settle — every cited coordinate — and published a table of what it
  re-took first-hand versus what it could not. That includes **independently confirming D-3**: the
  two surviving `capture_output=` sites are `bin/sc:2271` / `:3536`, and the gate's `:2258` / `:3523`
  were stale. *Writing the gate's numbers would have reproduced CR-2 inside CR-2's own correction.*
- **CR-11 (MINOR) — the reviewer audited an enumeration it had itself commissioned and found it short
  by one.** C-13's list omits the **`finally` block's own body**, which is outside the guarded region:
  an exception there propagates out of the whole `try` statement — *exactly what direction A measured*.
  So the missing member is the one member the mutation probes prove can escape, and it is the member
  the entire round-2 delta exists to make safe. The property holds in the shipped build; the table is
  short. *"An enumeration inherited from the document that commissioned it is exactly the kind that
  stops being audited."*
- **CR-12 (MINOR, NOT-DISCRIMINATING) — the FOURTH instance of the class**, and the reviewer promoted
  it a level: the first three were string relations (prefix / containment / absence); this is the same
  **set** relation over observables — *returns `False` and does not raise* strictly contains *renders
  one outcome line and returns `False`*, and the gap is precisely BC-11's operative words. It lands on
  the single arm the design elected as the **sole** control for the invariant, whose docstring and
  `docs/dev-map.md:87` both assert the wider claim. Not re-opened (out-of-scope 9 declines a fifth
  arm); travels as RES-8.
- **CR-16 (NIT, NOT-DISCRIMINATING)**: no arm compares the installed bytes to the composed document,
  so a build installing a different valid document — **or installing the candidate by
  `os.replace(name, CFG_PATH)`, the explicitly declined RS-1 decision** — passes every committed
  clause. K-2 is enforced today by grep and nothing else. Travels as RES-9.
- **C-21 re-derived independently rather than accepted**: the reviewer reconstructed the delta's three
  edits and showed row by row that every carried V row is behaviourally identical statement for
  statement, and that V-8 never enters the tail at all. **"No row is coasting."**
- **CR-13 (MINOR) is the one finding I am NOT letting ride.** It is a sentence **this change
  falsifies** in a shipped, user-facing document: `CHANGELOG.md:26`'s
  `标准输出与退出码均无任何改动` is false on a host with no usable `sing-box`, where HEAD tracebacked
  at exit 1 and this build exits 0 after restarting — which the *same paragraph* discloses two
  sentences earlier. The pool's scope rule is explicit that T-32 owns prose sweeps **except sentences
  your own change falsifies**, and this project's most-repeated defect (R-74; T-24's three rollbacks
  were all prose) is exactly this. One clause fixes it.
- **Route: advance to stage 6, after a targeted developer round 3** covering CR-13 (the qualifier),
  CR-11 (the fifth enumeration member) and CR-15 (a stale span coordinate in `04_DEVELOPMENT.md`).
  No code change, no re-gate needed — nothing touches `bin/sc`'s executable lines, the design or any
  binding condition. Rollback streak at stage 5: 0 (this is a follow-up, not a rollback).
- Intervention check #10 (after stage 5 round 2): `.harness/intervention.md` absent.
- **R-86 fired on the PM during this delivery — instance fourteen.** A `cat >> … <<'EOF'` heredoc
  containing no `rm` was refused by `guard-rm.sh` (*"could not parse nested pwsh command safely"*).
  Worked around with the `Edit` tool; **`HARNESS_ALLOW_OUTSIDE_RM` was not set and must never be.**

### Stage 4 — developer · round 3 (targeted) · **READY FOR REVIEW** · advance

- Three one-clause corrections, nothing else. `bin/sc`, `check-sc-contracts.py` and `baseline.json`
  show the **identical diffstat as round 2** (81 / 154 / 4), which is the developer's own proof that
  they are byte-untouched this round.
- **CR-13 discharged — and the developer improved on the reviewer's suggested wording rather than
  transcribing it, flagging the change instead of making it silently.** The reviewer proposed
  `在 sing-box check 能运行的机器上`; the developer measured that this covers only **two of the three**
  HEAD-traceback cases the same paragraph lists. The third — output that cannot be decoded — is a host
  where `check` **does** run (HEAD's `capture_output=True, text=True` decoded strictly and raised
  `UnicodeDecodeError`), so the suggested shape would **still be falsified there**. Shipped
  `在 sing-box check 能运行、输出也能解码的机器上` — the exact complement of the paragraph's own three
  cases. It also **declined to over-scope**: the config-bytes and `sc doctor` claims stayed
  unqualified because they hold on every host (NFR-4, AC-9), and qualifying them would have weakened
  two true statements. That is the R-74 discipline applied in both directions.
- **CR-11 discharged**: the `finally` clause's own body added as the enumeration's fifth member, with
  the measured evidence (direction A's `TypeError` past **both** handlers) and the two reasons the
  property holds in the shipped build. The intro sentence and the condition-disposition row were both
  corrected to five; I-2's "the only statement" is still not restated anywhere.
- **CR-15 discharged, with the fix aimed at the failure mode rather than the symptom**: the span was
  re-read first-hand (`:2149` blank, comment header `:2150-2162`, first executable `name = None` at
  `:2163`, last `return True` at `:2217`) and both citations now name the **two spans separately**,
  *"which is what stops the same half-update recurring."*
- `04_RATIONALE.md` needed no edit — checked for a `:2157` citation and a member count, neither
  present.
- Re-measured by the PM: `verify_all` **PASS 19 / WARN 0 / FAIL 0 / SKIP 1**; B.4 18/18/18;
  `baseline.json` untouched; live host bit-identical (`MainPID=2566751`, `NRestarts=0`,
  `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`). `bin/sc` was never loaded this round.
- **No re-gate and no re-review**: nothing touched `bin/sc`'s executable lines, the suite, the floor,
  the design or any binding condition — the round is three prose clauses, two of them inside this
  task's own stage document.
- Intervention check #11: `.harness/intervention.md` absent.
- **Route: advance to stage 6 (QA).** Rollback streak at stage 4: 0.

### Stage 6 — qa-tester · round 1 · **APPROVED FOR DELIVERY** · advance

- `06_TEST_REPORT.md` (129) + `06_RATIONALE.md` (269). **Unnumbered `## Adversarial tests` heading
  present** (E.6). Appended **operator obligation id 6** to `.harness/operator-obligations.md`;
  ids 1-5 untouched.
- **AC tally: 11 PASS / 0 FAIL / 1 BLOCKED / 1 NOT-DISCRIMINATING.**
- **AC-1 verified discriminating, not assumed** — the mandatory anchor did its job: byte-identical to
  HEAD (4625 bytes, `0o600`, record = sha256, `restarts 1`), and **both** wrong builds die —
  `mut-W1-rejects-everything` and `mut-W2-never-installs`. The R-22 trap the brief named is closed by
  measurement.
- **AC-13 reported NOT-DISCRIMINATING rather than passed** — its suite-regression clause discriminates
  (`floor=19 → FAIL`) but its *"the floor does not fall"* clause does not: **`test_count` lowered to
  17 with 18 assertions present leaves B.4 PASS.** B.4's ratchet cannot see a lowered floor (DEF-7).
- **AC-12 BLOCKED with its recipe, nothing substituted** — the R-31/R-41/R-47/R-52/R-60/R-68
  precedent, honoured a **tenth** time. AC-11 was **not** blocked: driven against the real
  `/usr/local/bin/sing-box` 1.13.15, including C-1's colouring half.
- **RES-6 discharged in full — this is what stage 6 was for.** Stage 5 had no shell in either round,
  so QA was the **first independent execution**. It carried nothing material: `verify_all` ×4, the
  contract suite ×11 (no flakes), both span hashes **reproduced exactly on both sides** (spans located
  by `ast`, not by the cited line numbers, and it recovered the developer's hashing convention), the
  **+21** count reproduced by its own classifier, all four probes reproduced, C-1's colouring re-run.
  The only figure it could not reproduce was a *physical* line total (3808 vs 3807) — a
  trailing-newline convention in a class NFR-3 does not bound, and it said so rather than rounding.
- **16 mutants built from the candidate, 12 killed by the committed suite, 4 survive it, 1 survives
  everything.** The three residuals routed to QA were all **CONFIRMED by measurement**:
  - **RES-8 / DEF-1** — `mut-res8-silent` keeps B.4 at 18/18/18, **and arm 4 in isolation passes it
    too** (the arms-emptied trick performed). Made user-visible: `sc reload` on an unwritable
    `CFG_DIR` gives `"outcome_lines": []` and still exits `Reload failed` **with no stated reason**.
  - **RES-9 / DEF-2, DEF-3** — and QA found *the implied remedy is wrong for one of them*, which is
    worth more than the confirmation: `mut-res9-other-doc` is killed by an AC-1 byte differential, but
    **`mut-res9-os-replace` — the explicitly declined decision — shows 0 observable differences across
    13 cases** (9-case sweep + symlinked target + `0666` target + `umask 000` + real binary). **A
    byte-comparison arm would not kill it; K-2 needs a *structural* control.**
  - **RES-2 / DEF-4** — `mut-res2-no-substitution` keeps B.4 green and, with a real child echoing
    `argv[3]`, shows the user a run-lifetime path.
- **DEF-5 is QA's own find and the most consequential**: `mut-CR6-arm-inside-try` — absorbing the
  rejection arm into the inner `try:`, which reads as a tidy-up — keeps **B.4 green** and, with a
  stderr that refuses only the rejection sentence, **returns `True`, installs the rejected document,
  re-baselines the drift record and lets the caller restart**, telling the user it *was installed
  without being checked*. **R-73 re-created in full, silently.** The reviewer's CR-6 predicted this
  fence and CR-17 filed its placement; QA turned prediction into measurement.
- Live host bit-identical before and after; `is-active` never invoked; `/etc/sing-box` and
  `/var/lib/sing-box` entry sets unchanged. `verify_all` PASS 19/0/0/1 ×4; B.4 18/18/18;
  `baseline.json` untouched by QA — **floor neither raised nor lowered**.
- Rows to file at delivery: **DEF-1, DEF-2, DEF-4** (three named committed clauses with observables
  and costs, ≈6/≈3/≈3 lines, for a future task — QA added **none**, honouring out-of-scope 9);
  **DEF-3 + DEF-5** (need a **structural** control and a ruling, since K-11 declined `ast` checks for
  statement *order* and this is a different subject); **DEF-6** (NIT, T-32); **DEF-7** (MINOR,
  `verify_all`-owned).
- Intervention check #12 (after stage 6): `.harness/intervention.md` absent.
- Stage gate satisfied: stages 5 and 6 both PASS ⇒ stage 7 may start.
- **Route: advance to stage 7, after one final micro-round.** Rollback streak at stage 6: 0.

### Stage 4 — developer · round 4 (one comment) · **PM decision and result**

- **My call, made under standing authority, and it overrides an earlier reviewer ruling on new
  evidence.** CR-17 ruled that the inner-`else` fence needed no in-task edit because C-19 had named
  `04_RATIONALE.md` as its destination. **QA's DEF-5 post-dates that ruling and changes its pricing in
  one way neither the reviewer nor the gate could have weighed: `04_RATIONALE.md` is *archived at
  delivery*.** So the only durable warning against an edit that silently restores R-73 with a green
  suite would have disappeared at the exact moment the task closed. The sentinel's fence already
  carries its comment at the code site; this one — **the fence whose failure mode is silent** — carried
  none. Cost: five comment lines, **zero executable**, and comments are outside NFR-3's count by K-9's
  own rule (C-8's ban on *deleting* a comment to hit a number is symmetric).
- Result: comment at `bin/sc:2184-2188`, first statement of the inner `else:`, drawn from
  `04_RATIONALE.md:186-194` and matched to QA's measurement. **+21 executable held** (2097 → 2118,
  re-measured with the same `ast` classifier); `verify_all` PASS 19/0/0/1; B.4 18/18/18;
  `check-sc-contracts.py` byte-identical; live host bit-identical.
- **The developer's own placement check is the part worth recording**: rebuilding
  `mut-CR6-arm-inside-try` mechanically moves 18 lines, **the first five of which are the new
  comment** — so an editor making that edit reads the refutation as the first line of what they are
  moving. That is the property the comment had to have, and it was measured rather than hoped for.
- **It also declined to act unilaterally on two coordinates its own change invalidated**, and asked:
  `docs/dev-map.md:106`'s two `capture_output=` sites, and `:76`'s recovery-arm citation — the latter
  established **by measurement** as this task's own debt (line 3408 at HEAD *is* that comment; T-30's
  own +68 physical lines moved it, and round 2's C-10 sweep did not list row `:76`). **Authorized:**
  the pool's scope rule reserves T-32 the general sweep *except sentences this change falsifies*, and
  leaving them would ship CR-2's exact defect class in the one file a developer agent reads before
  writing code — in the same task that corrected two other instances of it.
- Honesty note worth keeping: the developer's independent `ast`-span digests produce **different
  values** from round 2's recipe, and it **said so** rather than restating round-2 digests as if it had
  reproduced them. QA independently reproduced round 2's values with the original convention. Both
  facts stand.
- **Round 4 also caught one more number this task's own change falsified**, same file, same class:
  `docs/dev-map.md:76` cited the suite as `17 defined / 17 run / 17 passed` — T-29's measurement, and
  T-30 raised it to 18. Corrected, **and made robust rather than re-stale**: the row now says the count
  is whatever `baseline.json`'s floor currently is and that *"it is the clean sweep that carries the
  point, never the number."* The collapse property was **re-measured at 18 before the sentence was
  written**, so **R-97 is confirmed still open** — T-30 did not accidentally close it, and that is
  stated rather than assumed.
- Three coordinates re-verified on the **final** tree before being written, not carried: `:2276`,
  `:3541`, `:3476`. The developer confirmed by `git show HEAD:bin/sc` that the row was **right when
  written** and that this task's own +68 lines moved it — the debt is T-30's, not inherited. It also
  noticed my own edit to `.harness/rejected-decisions.md` had already landed the correct pair, and
  corrected its document's claim to the contrary rather than shipping a third false coordinate.

### Stage 7 — delivery (PM)

- `07_DELIVERY.md` written: `## Summary` field list, **five** `## Insight` lines (one physical line
  each, bare `## Insight` heading so `archive-task.sh`'s `^##\s+Insights?\s*$` harvest matches),
  residuals, decision records, harness observations, `## Verdict: DELIVERED`.
- **Entropy watch: NOT-DUE, fail-open.** `.harness/scripts/entropy-cadence` does not exist on this
  host (**R-88**), so `delivered` / `check` / `swept` could not run; per the cadence's own fail-open
  rule the verdict is NOT-DUE. **No supervisor scan was dispatched and no `## Entropy watch` section
  was written** — and the absence means exactly that, not a skipped step.
- **`docs/tasks.md` rotation, completed material first**, as rule 70 requires: five blocks moved to
  `docs/tasks-archive.md` (T-14's fully-closed block plus four "unnumbered items" paragraphs), each
  leaving a one-line pointer, **nothing closed by moving**. Three more paragraphs compressed in place
  after the first pass still left F.5 at 301. Final: **298 lines, F.5 PASS**.
- Two decision records appended to `.harness/rejected-decisions.md` and the
  `shared-singbox-check-wrapper` record **re-opened, upheld and corrected** (its `capture_output=`
  count was three and is now two).
- `verify_all` re-measured after every PM edit; final **PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0**.
  Two WARNs appeared mid-delivery and both were cleared: **F.5 was mine** (rotation, above), and
  **F.6 was `04_DEVELOPMENT.md` at 543** — the developer's document under rule 70's "reference, don't
  paste", which it brought to exactly 500 itself. Neither was left to be buried by archiving.
- Intervention check #13 (final): `.harness/intervention.md` absent — as at all thirteen checks.
- Remaining: `archive-task.sh --task validate-before-baseline`, then commit and push per rule 80.
