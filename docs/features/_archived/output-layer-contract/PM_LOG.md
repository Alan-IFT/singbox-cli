# PM_LOG — T-25 / output-layer-contract

Pool: `followups` (`docs/batches/followups/BATCH_PLAN.md`, row T-25) · Mode: **full** (7 stages)
Dispatched by `/harness-batch`, deferred-human mode NOT set — standing decision authority granted
(「你来决策就行」), so judgment calls are resolved downstream and recorded. `BLOCKED: NEEDS-HUMAN`
only for a genuine safety red line.

## Task-start state (2026-08-15)

- `.harness/scripts/task-state.js` — **does not exist on this host**. Fail-open per dispatch:
  no durable counters; rollback streaks are tracked in this log by hand.
- `.harness/scripts/entropy-cadence` — **does not exist on this host**. Fail-open: the stage-7
  entropy watch resolves to NOT-DUE, no `## Entropy watch` section, no supervisor scan.
- `.harness/intervention.md` — absent at task start (checkpoint 1, before stage-1 dispatch).
- `.harness/agents/dev-*.md` — directory does not exist ⇒ **single-Developer mode**, dispatch
  `harness-kit:developer`.
- `docs/tasks.md` — **300 lines**, exactly its F.5 cap. Rotation required before adding the T-25 row.
- `.harness/insight-index.md` — **29 lines** against F.4's 30. Any insight harvested at delivery
  overflows it; hand-rotation into `docs/features/_archived/insight-history.md` is required
  (R-18, confirmed thirteen times; the script fix is T-27's, not this task's).
- Baseline `verify_all`: PASS 17 / WARN 0 / FAIL 0 / SKIP 1 (measured independently after T-24).

## Insight-index entries surfaced to downstream stages

Queried before stage 1 on the task's salient terms (output, print, buffering, locale, LANG,
encoding, translation). Seven entries apply and are carried verbatim in the dispatch prompts:

- the `main()` reassigns `LANG` vacuity trap (evidence: config-composition-layer) — load-bearing
  here because this task is *about* rendering
- `cmd_status` block-buffering vs `ip` children; `_doctor_print()` already flushes (evidence:
  status-egress-via-clash-api) — this is R-33's mechanism
- `sys.stderr` line-buffering only since 3.9 (evidence: sc-config-show)
- `LC_ALL=C PYTHONCOERCECLOCALE=0` does not give a non-UTF-8 Python; `PYTHONUTF8=0` required
  (evidence: state-file-io-contract)
- `sys.stderr` `backslashreplace` vs strict `sys.stdout`; `cmd_add`'s `U+2192` at `bin/sc:2345`
  (evidence: state-file-io-contract) — this is the T-23 hand-off clause
- `main()` reassigns `CLASH_PORT` too (evidence: status-egress-via-clash-api)
- `verify_all.sh` must be invoked from the repository root (evidence: share-url-userinfo-contract)

## Stage transitions

### Stage 1 — requirement-analyst · round 1 · verdict READY · ADVANCE

Wrote `01_REQUIREMENT_ANALYSIS.md` (9 FR / 14 BC / 16 AC / 4 NFR / 18 resolved questions /
11 out-of-scope items) + `01_RATIONALE.md`. Intervention checkpoint 2: none present.

**Four dispatch claims the analyst refuted by first-hand re-verification** — downstream inherits the
analyst's wording, not the dispatch's:

1. R-19's stated cause is wrong. `t()`'s key-on-miss is not the defect; in English *every* lookup is
   a designed miss and the key **is** the rendering (one `zh` table only). The cause is a key that is
   not its own English rendering (FR-1). A "fail loudly on miss" design is not expressible.
2. R-33 is **wider than filed** — `cmd_status` runs two children (`systemctl`/`rc-service` then
   `ip`), so two headings invert; `cmd_update_interval` has the identical shape.
3. The T-23 hand-off is far wider than `cmd_add`'s one `→`: `sc ls` prints `●`/`→` on ordinary rows,
   so under a proved non-UTF-8 stdout **`sc ls` is broken outright in English**. No filed row says so.
4. The defect is **published**: `README.md:94` ships `ls.idx …` as English sample output and
   `docs/dev-map.md:90-92` records it as a pattern note. Both in scope (FR-9/AC-15).

**New finding, filed not fixed (PM to open a row at delivery):** `配置检查失败：…` already contains the
`失败：` diagnostic literal and is reachable into `install.log` via `sc update-rules` → regeneration,
so that grep already matches a line meaning something else. Pre-existing; Q-17 rules it out of scope.

R-37 confirmed a **fourteenth** time (rule 70 still declares no stage-doc boundary rule). Recorded,
not blocking; T-27 owns it.

### Stage 2 — solution-architect · round 1 · verdict READY · ADVANCE

Wrote `02_SOLUTION_DESIGN.md` + `02_RATIONALE.md`, and appended one record
(`per-print-flush-instead-of-one-stdout-configuration`) to `.harness/rejected-decisions.md`
(ledger row L-7 — flagged to the gate for an in-bounds ruling, see F-11). Intervention: none.

Design in one line: the output contract has **two homes, both already in the file** — the string
layer (keys carry their own English rendering, their own field punctuation, one invariant count
form) and the stream layer (**one** statement at the top of `main()`). FR-8 is not a third home,
it is four call sites calling the existing `_plain()`. Size estimate `bin/sc` +47/−35, total
≈ +71/−44 against the bar (T-22 +21/−11, T-23 +76/−51, T-24 +79/−55).

Rule-85 record: the smaller alternative (copy `_doctor_print`'s `flush=True` to the prints
preceding a child) was rejected because it answers FR-6 only and FR-7 on that route needs a
per-call-site mechanism plus a fix for `sc config`'s own `sys.stdout.write`.

### Stage 3 — gate-reviewer · round 1 · verdict APPROVED WITH CONDITIONS · ADVANCE

Transcription check before writing: contract body began with its declared opening line and ended
with its `## Verdict` line; both header-named paths carried a portion; no partial return reported.
Written verbatim to `03_GATE_REVIEW.md` and `03_RATIONALE.md` — nothing added, nothing repaired.
Intervention checkpoint after stage 3: none present.

11 findings (5 major / 5 minor / 1 info), 12 binding conditions C-1…C-12, 6 pre-answered developer
questions. **No rollback**: every finding is a fixture, criterion-wording or document defect, and
none changes an interface or a design decision.

The gate did the rule-85 job it was asked to do — it **re-priced the declined route itself** and
found no smaller construct exists on the 3.6 floor (`reconfigure()` is 3.7-only, `sys.stdout.errors`
is read-only), so the smaller design won *and* it is the one stage 2 took. It also corrected the
declined route's site count (4 → 3; `bin/sc:2421` precedes no child), a correction that **favours**
the rejected route and still does not change the ruling. Over-build risk did not materialise.

R-22 duty discharged: every AC tested as a discriminator, and **two reported NOT-DISCRIMINATING
rather than passed** — AC-12 (its comparison clause names a `sc doctor` routing-mode rendering that
does not exist) and AC-13 (nothing asserts the section was printed at all; `is_running()` returns
`False` off its final line when neither init system is set). This repeats T-24's R-71 outcome
deliberately. AC-1 is the criterion that satisfies the R-22 requirement: it compares against the
**words** the keys mean, which `ls.idx` fails on both clauses.

**Safety-floor finding F-1 / C-1** — the design's claim that every run uses the `docs/dev-map.md`
import recipe is false as written: every `main()`-driven V-step executes `_init_files()`, whose
`Path("/var/lib/sing-box")` is the one non-repointable path, and the same recipe says "never drive
`_init_files()`". No V-step result taken before the neutralisation + assertion is in place may be
recorded.

#### PM rulings on the two PM-owned conditions

- **C-11 — discharged now.** `.harness/rejected-decisions.md` corrected **in place**: four sites →
  three (`bin/sc:2413`, `:2418`, `:3431`), `4 + N` → `3 + N`, and the Origin line now records the
  stage-3 upholding and its independent re-pricing. **No second record added.** F-11's ruling that
  the stage-2 write was in-bounds stands (the file's own header instructs "append when something is
  deliberately declined" and names no stage; T-24's record carries the same stage-2-writes /
  stage-3-corrects provenance).
- **C-6 — ruled: `README.zh-CN.md` is RELEASED from the frozen set, for line 297's sentence only.**
  Scope, not expertise, is the PM's lane here, and the frozen set must not force an asymmetric
  outcome in which the English sentence is corrected and its Chinese twin silently diverges. The
  release is narrow: the developer may edit **that sentence only**; `README.zh-CN.md:94`'s `sc ls`
  sample stays frozen (out-of-scope 5 — the Chinese rendering is byte-identical after this task).
  Both branches C-6 offers remain open: correct both sentences, **or** record per sentence why each
  stays true under BC-8. The developer chooses on the merits and records the choice.

### Stage 4 — developer · round 1 · verdict READY FOR REVIEW · ADVANCE to stage 5

`verify_all` **PASS 17 / WARN 0 / FAIL 0 / SKIP 1** from the repository root — identical to the
task-start baseline, 0 new FAIL, 0 new WARN. Stage-5 gate satisfied. Intervention: none.
`git diff --stat` (product only): `bin/sc` +104/−43-ish, `README.md`, `docs/dev-map.md` —
86 insertions / 43 deletions across three files, against the bar (T-22 +21/−11, T-23 +76/−51,
T-24 +79/−55). Nothing staged, nothing committed.

C-1 discharged as a real safety floor: `sc._init_files` rebound before every run, eight-constant
`resolve()` assertion plus a before/after `(exists, mtime_ns, ctime_ns, listdir)` witness of
`/var/lib/sing-box` **and** `/etc/sing-box` on every run, all UNCHANGED; `bin/sc:532` executed on no
path. C-2, C-4, C-5, C-7, C-8, C-9, C-10, C-12 discharged; C-3 prepared for QA (AC-12's clause
confirmed NOT-DISCRIMINATING and re-pointed at the egress body, the one class both screens carry).
**C-6 discharged by measurement with both README sentences kept** — the PM's `README.zh-CN.md`
release went unused. Three design drifts filed (DD-1 `newline="\n"`, DD-2 `_plain(str(v))`,
DD-3 extra comment blocks).

### Stage 5 — code-reviewer · round 1 · verdict CHANGES REQUIRED (0 CRITICAL, 1 MAJOR) · ROLLBACK to stage 4

Transcription check before writing: contract body opened with its declared opening line and closed
with its `## Verdict` line; both header-named paths carried a portion; no partial return reported.
Written verbatim to `05_CODE_REVIEW.md` and `05_RATIONALE.md` — nothing added, nothing repaired
(one transcription slip caught and restored: a `日` escape in the rationale had been rendered as
the character it denotes). Intervention checkpoint after stage 5: none present.

**Rollback streak at stage 4: 1 of 3.** Routing back to the developer, not to stage 1 or 2 — the
MAJOR is a *record* defect on a binding gate condition, not a behaviour defect, and the reviewer
states no code change is required.

- **CR-1 (MAJOR)** — C-6's discharge claims BC-8's silent-corruption mode is **structurally**
  unreachable through `sc config`. It is *conditional*, on two things the record does not state:
  (a) `sys.stdout.encoding` equals the locale codec only while `PYTHONIOENCODING` is unset — with
  `PYTHONIOENCODING=ascii` the candidate exits **0** with a file a parser rejects where HEAD aborted
  loudly; (b) the premise is `cmd_config`'s own locale-decode defect, which the developer files for
  repair — fixing that filed row makes `README.md:297` false under `LC_ALL=C` in the *default*
  environment. So F-5 is carried as closed when it is not.
- CR-2…CR-5, CR-9 (MINOR) → developer. CR-6, CR-7 (MINOR) → PM. CR-8 (MINOR) → QA.
- All three drifts **upheld**; DD-1 is upheld *more strongly than filed* (CPython builds
  `sys.stdout` with an explicit `newline="\n"`, so omitting it would have been a regression, not a
  neutral omission). Both flagged behaviour changes accepted, and **R-45 is explicitly not
  re-opened** — only its price rises (RES-4).
- Rule-85 sweep **clean**: no `en` table, no catalogue, no formatter, no plural helper, no print
  wrapper, no second key per phrase, no new file, no new function, no new concept. The batch's
  highest-over-build-risk row did not over-build.
- R-22 duty discharged at stage 5 too: AC-1 compares against the words the keys mean, and `ls.idx`
  fails it on both clauses, so no criterion is passed by the key name's ASCII-ness.

#### PM rulings on CR-1's PM half and CR-7

- **CR-1, PM half — ruled: both published sentences TAKE BC-8's narrowing.** The behaviour genuinely
  changed (HEAD aborted loudly; the candidate can now exit 0 with a document a parser rejects), so
  FR-9's general clause applies and an unconditional published promise is no longer true. The
  `README.zh-CN.md:297` frozen-set release **stands and is now used**; `README.zh-CN.md:94` remains
  frozen. Wording is the developer's, on the merits — my ruling is scope only.
- **CR-7 — discharged now.** `.harness/rejected-decisions.md:38` corrected **in place** to
  `OK (n byte(s)); fell back after: …`, with a clause noting the noun became invariant in T-25 and
  that `OK (` and the one-completion-line invariant are unchanged. No second record.
- CR-6, RES-4, RES-5, RES-6 are PM pool rows, filed at delivery in `docs/tasks.md`.

### Stage 4 — developer · round 2 · verdict READY FOR REVIEW · re-dispatch to stage 5

**Round record (author's own words, recorded here and not in the stage document):** `round 2 ·
corrected the C-6 discharge to state both preconditions and narrowed both published `sc config`
sentences per the PM ruling; corrected three now-false comments and the DD-3 drift count; moved the
stream-discipline rationale to its single dev-map home and gave that home the `backslashreplace`
cost clause and the two-wrappers fact · because CR-1 showed the "structurally unreachable" claim was
conditional, and CR-2/3/4/5/9 showed producer contracts and the record contradicting the shipped
code · findings CR-1, CR-2, CR-3, CR-4, CR-5, CR-9`

`verify_all` **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, baseline preserved. Product diff now
`bin/sc` +80/−41, `README.md` 6/6, `README.zh-CN.md` 1/1, `docs/dev-map.md` 12/5. No behaviour
changed this round — the four edited `bin/sc` regions tokenize as `STRING`/`COMMENT`/`NL` only, and
the post-edit `sc config` capture is `cmp`-identical to the pre-edit one. Intervention: none.

**The reviewer's CR-1 claim was CONFIRMED by measurement, not refuted** — and so was its second
half. Under `PYTHONIOENCODING=ascii` the candidate exits **0** with 269 ASCII bytes that
`json.loads` rejects, where HEAD raised and exited 1; and with T-23's explicit UTF-8 decode applied
to `cmd_config`'s reader, the same defect reproduces under plain `LC_ALL=C` **with no env var at
all**. The escape shapes are wider than the review assumed (`\xe9`, `\U0001f1ef`, `\U0001f1f5` are
not JSON escapes; `日`, `本` coincidentally are), which strengthens rather than weakens the
finding. The developer took **door one** — both published sentences narrowed symmetrically — and
also narrowed the promise's third, unpublished home (`cmd_config`'s docstring), flagged because the
PM ruling covered only the two published sentences. **I accept that extension**: it is the same
sentence in its third copy, and leaving one copy unconditional would recreate exactly the divergence
the ruling exists to prevent.

#### Safety near-miss — recorded in full, no harm, work re-taken

In a fresh context the developer wrote its own `importlib` loader instead of the mandated
`docs/dev-map.md:121-158` recipe and **re-exec'd into the installed `/usr/local/bin/sc` under
password-less `sudo`** — the exact trap that row exists to prevent. Caught immediately: the older
installed build's argparse rejected the harness argv at exit 2 **before** `_init_files()` or any
command ran, so there was no write and no service contact. The run was declared **void** (C-1's own
rule) and every affected result was re-taken on the dev-map recipe verbatim, with all eight
constants repointed and asserted; all five cases reproduce byte-for-byte. Not filed as an insight —
the dev-map already states the rule, so the failure was in following it, not in the project's
knowledge. Recorded here because a void-and-retake is exactly what C-1 is for, and it worked.

### Stage 5 — code-reviewer · round 2 · verdict APPROVED · ADVANCE

Transcription check passed (declared opening line, `## Verdict` close, both header-named portions
present, no partial return); the reviewer's own note that the outer code fences are delimiters and
not body was honoured. Content at both paths **replaced**, not appended. Intervention: none.

**Round record (author's own words):** `round 2 · CR-1 discharged (door one: both published sentences
+ the unpublished third home narrowed to BC-8's condition; the third home verified to be the same
sentence, not new scope), CR-2/CR-3/CR-4/CR-5/CR-7/CR-9 discharged, CR-6 and CR-8 still travelling as
RES-5 / RES-1 · three new MINOR/NIT findings raised from the round's own edits (CR-10 README
parenthetical, CR-11 dev-map site list, CR-12 comment wording), none blocking · verdict moves CHANGES
REQUIRED (0 CRITICAL, 1 MAJOR) → APPROVED · the round's central claim (no behaviour change) was
verified independently, not accepted: the four edited regions are docstring/comment tokens only,
`__doc__` is read nowhere in bin/sc, and the safety-event void run was ruled sound against the
installed build's own source ordering.`

The reviewer did not accept "no behaviour changed" — it closed the docstring half with a check the
developer had not made: **`__doc__` is read nowhere in `bin/sc`**, so a docstring edit has no route
to any rendered line at all. Stronger than "tokenize reports STRING".

**RES-8 — the safety-event ruling, recorded here as its contract requires.** The reviewer ruled the
void run credibly write-free on evidence independent of the harness's own witness (which could not
settle it, being taken by the re-take): it read `/usr/local/bin/sc` and found `parse_args()` at
`:2453` reached before `_init_files()` at `:2466`, so an argparse `invalid choice` ended execution
**before the first writer on the start-up path** — root or not. The re-take is independent of the
void run (different loader, five cases byte-for-byte). It also ruled the **non-filing right**: the
fact already has one home in `docs/dev-map.md:121-158`, and an insight index that restates the
dev-map is how both stop being read. What the episode shows is that the row's *rule* was enough and
its *failure signature* was not — RES-7.

### Stage 4 — developer · round 3 · verdict READY FOR REVIEW · ADVANCE to stage 6

PM-initiated, documentation-only, after the APPROVED verdict: closing two of the reviewer's own open
non-blocking findings rather than filing them, because both are one-clause fixes in files this task
already edits, and shipping a known-incomplete clause in a durable doc is the patch-then-patch shape
rule 85 forbids.

**Round record (author's own words, condensed):** `round 3 · dev-map:78's backslashreplace cost
clause now carries the class AND two instances (CR-11); bin/sc:3155-3158 comment wording (CR-12);
04_DEVELOPMENT.md records the CR-10 disposition — both README:297 sentences stay as written for the
post-repair world, with the duty to *verify* rather than change them attached to RES-6; record kept
consistent across ## Files changed, the no-behaviour proof, ## Dev-map updates and 04_RATIONALE §6(a)`

The reviewer's second `surrogateescape` route **held on independent reading, and was refined**: the
same value also reaches the success line's `fell back after: {causes}` note via `tried`
(`bin/sc:3353-3356`), so it is **three** print routes, not one, and `:3360-3361` — not only `:3346` —
is what makes a single bogus base sufficient to reach `:3370`. `verify_all` PASS 17 / WARN 0 / FAIL 0
/ SKIP 1. `bin/sc` numstat unchanged at 80/41; `tokenize` reports `COMMENT`/`NL` only for the edited
region; `python3 -W error` compiles clean; both diagnostic literals byte-intact. Nothing was run
against `sc` at all this round, so the C-1 envelope was not exercised.

**PM routing decision (recorded, not silent):** I did **not** re-dispatch stage 5 for round 3. The
verdict is already APPROVED; round 3 closed two of that reviewer's own findings in the exact form it
prescribed, its change class was pre-ruled inert by that same reviewer, and I hold no channel to
resume the reviewer's context for a two-line confirmation. Instead the hunk-level verification of
round 3's delta is routed to **QA** under the reviewer's own **RES-2**, which already owes a
hunk-level confirmation that `bin/sc` carries no change outside the ledger and the comment/docstring
regions. CR-10 stays open by design (disposition taken, duty attached to RES-6).


### Stage 6 — qa-tester · round 1 · verdict APPROVED FOR DELIVERY · ADVANCE to stage 7

Intervention checkpoint after stage 6: none present (as at every prior boundary — the file never
existed during this task). `verify_all` re-run by QA **four times**, all identical:
**PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, the task-start baseline. `baseline.json` not updated
(frozen set + out-of-scope 10 — a committed test is forbidden here and is T-28's row).

**16/16 criteria, nothing BLOCKED** — no criterion needed root, a live service or a network, so for
the first time in this pool's recent history **no operator obligation was appended**. AC-12 was
reported **NOT-DISCRIMINATING as written**, then re-pointed under C-3 and passed on both halves;
AC-13 passed only after C-4's proof that the section rendered on candidate *and* HEAD.

C-1 held as a real floor: **142 runs, 142 `[C-1] VERDICT OK`, 0 void**, and QA found a **second**
hard-coded write path nobody had named (`cmd_update_interval` builds
`Path("/etc/systemd/system/sing-box-rules-update.timer.d")` at `bin/sc:3439`), handling it with a
fail-closed path jail rather than driving it. Live host witnessed with `systemctl show`.

Five MINOR defects filed, none holding delivery — QA-1 (the mandated loader recipe cannot load
`bin/sc` under the very environment every locale criterion needs), QA-2/QA-3 (record counts),
QA-4 (`.harness/operator-obligations.md` row 4 step R-5 stale — T-25 closes it), QA-5 (a cost clause
stating a loss that was never available to lose).

### Stage 7 — delivery · verdict DELIVERED

- **Entropy watch: SKIPPED, fail-open.** `.harness/scripts/entropy-cadence` does not exist on this
  host, so `check` resolves to NOT-DUE by the documented fail-open rule: no scan, no
  `## Entropy watch` section, no digest. Recorded rather than silently omitted.
- **`task-state.js` absent** throughout — no durable counters; the single stage-4 rollback streak
  (1 of 3) was tracked here by hand.
- `07_DELIVERY.md` composed with a 3-line `## Insight` section.
- **QA-4 discharged by the PM**: `.harness/operator-obligations.md` row 4 step R-5 **marked closed
  in place** (the id is permanent and the row stays T-23's), with the measurement that closes it.
- `docs/tasks.md` **rotated before adding anything** — it sat at exactly 300, its F.5 cap. Rotation
  took **completed** rows first (T-24's outcome row → `docs/tasks-archive.md`) and compacted only
  rows verified closed by shipped work (T-14's R-15/R-16/R-17, T-15's R-19/R-20/R-22); every open
  row keeps its full text. T-25's row added; **R-19, R-33, R-34, R-38, R-40 marked CLOSED** with
  their evidence; **R-45's row updated in place** with its risen price (RES-4); **R-75 … R-79**
  filed. Final: **300 lines**, at the cap, not over it.
- `.harness/insight-index.md` **hand-rotated** (R-18, confirmed a **fourteenth** time — T-27 owns
  the one-line fix, deliberately not fixed here): three entries whose knowledge is now carried by
  shipped code and a closed row moved to `docs/features/_archived/insight-history.md`, taking the
  index 29 → 26 so `archive-task.sh`'s harvest of 3 lands at **29**, under the 30-line F.4 cap.
- `.harness/scripts/archive-task.sh --task output-layer-contract` run: 3 insights harvested,
  14 stage docs moved to `docs/features/_archived/output-layer-contract/`.
- `docs/dev-map.md` updated by the developer (L-6 / I-7 / I-8) — structure statement, not structure
  change: one convention bullet restated, one `## Reusable utilities` row for the stream discipline.
- `docs/batches/**` left **unstaged** per the delivery policy.
