# 01 — Rationale · T-27 `harness-self-maintenance`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## 1. First-hand re-verification of the three defects

Stage 1 holds no execution tool here, so every claim below was re-established **by reading**, not
inherited. Where a claim needs a run, it is routed to a criterion instead of asserted.

### R-18 — the rotation branch cannot fire

- `archive-task.sh:85-90` fills `current` from `grep -E '^[[:space:]]*-[[:space:]]'` — bullet lines.
- `:92-94` computes `total_after = ${#current[@]} + ${#harvested[@]}` and tests `> 30`.
- `verify_all.sh:213-219` computes `n=$(wc -l < .harness/insight-index.md)` and tests `> 30`.
- The live index: 30 lines total, entries at lines 9-30 (**22**), header at lines 1-8 (**8**, two of
  them blank). So the two metrics differ by exactly 8 today, and the script's branch first fires at
  38 file lines — eight lines after F.4 has already warned. The rotation is unreachable in the
  region it exists to serve. This is the mechanism, not a threshold that wants tuning.
- The rewrite branch is otherwise sound and worth preserving: `:114` re-emits the non-bullet lines as
  the header, so a corrected metric does not need a restructured rewrite. `:107-111` creates
  `insight-history.md` with its own header on first use.
- Each index entry occupies exactly one line — the harvest loop joins wrapped bullets before they
  land (`:57-71`) — so "lines = header + entries" holds and FR-1 is achievable without changing what
  an entry is.

### R-37 — no boundary rule

`.harness/rules/70-doc-size.md` is 91 lines with no `## Stage-doc boundary rule`; its process
discipline covers "reference don't paste", PM_LOG compaction, tasks.md rotation and always-archive,
and nothing routes a unit between a stage doc and its rationale sibling. F.2's cap is 200
(`verify_all.sh:195-202`), so the headroom is ~109 lines and a ≤35-line section is comfortably
inside it. The recurring unroutable units were read from the record rather than imagined: T-19
recorded the gap at stages 2 (E-20), 3, 5 (RES-10) and 6 (QA-D1); T-26 recorded it as OQ-11.

The one real conflict the section must settle: `.harness/rules/85-design-discipline.md:41-42` places
`## Smaller alternative rejected` **in `02_SOLUTION_DESIGN.md` by name**, while the generic routing
test ("argument and evidence go to rationale") would send it to the sibling. FR-6(b) exists for
exactly this — a section another rule names by name is a declared shape of that stage doc, and its
supporting measurement is what moves. Without clause (b) the new section would contradict rule 85 on
its first use, which is why the section is four clauses rather than one test.

### R-36 — the path list omits the batch loop

The instance is `docs/features/_archived/ruleset-staleness-visibility/01_REQUIREMENT_ANALYSIS.md:149`
(T-19 AC-S3): it names a product list and a ledger list and rules that "a path in neither list is a
failure of this criterion". `docs/batches/followups/BATCH_PLAN.md` and `BATCH_LOG.md` exist, are
written by the batch loop before stage 4 of any task in the batch, and are in neither list — QA-D2
caught it as a false failure at T-19 and the row has been carried since. This task's own working
tree reproduces it: PM_LOG records the tree clean "apart from `docs/batches/followups/BATCH_{PLAN,LOG}.md`".

### The refresh source — what `/harness-upgrade` would actually copy (read first-hand)

FR-5, OQ-6, OQ-11 and AC-13 all turn on one artifact, and it was read end to end rather than assumed
to resemble the vendored file. `.harness/scripts/upgrade-project.sh:56` resolves the refresh source to
`$TEMPLATE_ROOT/skills/harness-init/templates/common/.harness/scripts`, which on this host is
harness-kit **0.47.0**. That `archive-task.sh` is **425 lines** and a different program from the
vendored 151-line one:

- wrapped bullets are classified as continuation lines and the entry's range extended (`:161-165`),
  then every line of the entry is harvested (`:299-303`) — the truncation the local `awk` join
  prevents cannot occur there, so an instruction to "re-apply the join" onto that text would oblige a
  re-application of a fix whose harm the text does not reintroduce;
- `rotate_count` is already clamped to the stored entry count (`:340`) — BC-5's clamp;
- the index rewrite emits the header from the scanned range with `printf '%s\n'` and says in its own
  comment that filtering the file for non-bullet lines is the defect (`:386-395`);
- the missing-index `touch` is already an `if` inside the write phase (`:364-366`);
- **rotation is still decided on entries** (`:313`, `:333`) against a `verify_all` F.4 that caps
  lines, and there one entry may occupy several index lines — so R-18's class not only survives
  upstream, it is wider there.

Two consequences follow, and both are corrections rather than notes. (1) The refresh is a
**replacement**, not a two-hunk revert: a record whose only re-application path discards it would
throw away four fixes this project would otherwise pay for, and a record obliging a transcribed
re-application of both fixes is asserting something the text makes false. (2) A record that hard-codes
"0.47.0 already does X" is a false instruction one version later — hence BC-13's rule that the record
states *checks*, and that whoever runs one names the version measured.

## 2. Related work already decided (linked, not re-described)

- `docs/tasks.md` §"Open rows surfaced by T-14" — R-18's row, owner T-27, twelve confirmations at the
  time of writing, plus the durability caveat this task's FR-5 discharges.
- `docs/tasks.md` §"Open rows surfaced by T-19" — R-36 and R-37 rows with their owners.
- `docs/features/_archived/ruleset-staleness-visibility/01_REQUIREMENT_ANALYSIS.md` — the AC-S3
  instance R-36 is about, and the house shape this task's AC-14 follows.
- `docs/features/_archived/doctor-rows-establish-their-fact/01_REQUIREMENT_ANALYSIS.md` — the house
  form for this document; its AC-17 is the first criterion in this repository that already carries the
  `docs/batches/**` carve-out by hand, which is the practice FR-10 makes inheritable.
- `.harness/rejected-decisions.md` was read end to end before proposing scope. No record covers any of
  R-18 / R-36 / R-37, so nothing here re-litigates a prior decline. The four declines this task makes
  (OQ-1, OQ-2, OQ-4, OQ-7) are filed there **at delivery by the PM**, which is this repository's
  standing practice for `.harness/**` records — see the "Filed by the PM at delivery" notes on the
  `clash-api-bare-except-and-leaf-enumeration` and `ruleset-timestamp-outside-the-single-reader`
  records. Stage 1 writes nothing into that file.
- `CONTEXT.md` was skimmed. Its glossary is product-domain (rule-set, drift, overlay, emitted
  position…); "rotation", "vendored local fix" and "boundary rule" are harness vocabulary with no
  product referent, so no entry is coined and none is needed.

## 3. Candidates weighed per resolved question

**OQ-1 (guard-rm).** Three candidates. (a) *Fix the parse*: add a destructive-verb pre-filter so an
unparseable segment containing no verb is allowed. Rejected — it is a permit widening in the one
artifact whose job is refusal, it needs adversarial tests this task has no budget for, and a
substring pre-filter over `rm rmdir unlink Remove-Item del erase Clear-RecycleBin shred srm` is a
heuristic on a string the guard has just admitted it cannot parse. (b) *Correct only the message*
(one `printf` block at `:316-319`), naming the tokenizer cause and `git commit -F <file>` instead of
attributing every parse failure to nested pwsh and offering only the disable switch. This was the
near miss, and it lost on a stated line: it removes **no** hand-work (the `-F` workaround stays
either way), it has empirically mis-steered nobody (eleven of eleven tasks chose the safe path, the
bypass never set), and it would drag a **second** plugin-vendored file under FR-5's durability
apparatus — doubling the surface of the task's only unresolved risk to buy a more accurate sentence.
(c) *Leave it, argued* — adopted. The decisive fact is that `.harness/rules/75-safety-hook.md:86`
already documents this block as designed behaviour with its remedy, so it is a policy this project
has already accepted, not a defect it has been tolerating unknowingly.

**OQ-2 (absent scripts).** Candidates: implement local stand-ins; wrap the absence in a documented
helper; declare out of scope. The first two are new machinery for plugin-owned assets and would
collide with `/harness-upgrade`; the third is adopted. The distinction that carries it is worth
keeping: R-18/R-36/R-37 are *present artifacts that are wrong*, these are *absent artifacts*, and
absence is already handled fail-open at a cost of two lines in `PM_LOG.md`.

**OQ-3 (where the list lives).** Four candidates.
1. `.harness/rules/80-delivery-policy.md` — **adopted**. Subject match (what a delivery commit
   contains), already indexed in `AI-GUIDE.md` so E.5 stays PASS, already carries a "Preconditions"
   list the new list sits beside, and it is loaded only by tasks that need it. Its one weakness is
   the trigger, fixed by one clause.
2. `.harness/rules/00-core.md` — rejected: it is loaded by **every** task, and a path list is exactly
   the kind of content rule 70's own adversarial check sends elsewhere.
3. A new fragment (`90-committed-diff.md`) — rejected under rule 85: a new file, a new index line, a
   new trigger, for one list.
4. `docs/dev-map.md` or `docs/tasks.md` — rejected: the first is product navigation, the second is a
   board that rotates its own content to an archive.

**OQ-4 (the `.ps1` mirrors).** Candidates: fix both; fix `.sh` and file the mirror; fix `.sh`
silently. The middle one is adopted. The argument that decided it is not "Windows does not matter"
but "an unverifiable edit that **activates a write path** is worse than a dead branch": the `.ps1`
rotation is dead in the same way today, so leaving it dead preserves the status quo, whereas an
untested activation could rewrite an index on a host nobody here can observe.

**OQ-6 (durability).** Candidates for the record's home, all left to stage 2: a line in
`docs/tasks.md`; a short block in a rule fragment; a `.harness/` note file; a digest gate in
`verify_all`. The last is named here only to be pre-emptively priced — it is a new gate, a new
failure mode at every upgrade, and it is the meta-tooling the dispatch forbids; BC-11 makes adopting
it require proving the cheap routes fail. What is **not** negotiable is that the record leaves the
vendored file, because today's record is a comment at `:51-56` that the replacement it warns about
deletes.

Three candidate *properties* were then weighed against the real template, and only the third survives
contact with it. (i) *Both fixes re-appliable from the record alone, without re-diagnosis* — the
original wording, and unsatisfiable: one fix's code site does not exist upstream and its harm is
prevented there by another mechanism, while the other's re-application site (`0.47.0:333`) counts
entries where the local formula counts lines, so any "re-apply" instruction is a guided edit into a
different program. (ii) *Restore the pre-refresh file* — satisfiable, and rejected: it makes
`git checkout -- <path>` the standing answer, i.e. discarding the replacement sight unseen, which is
the same class of false instruction the task exists to remove. (iii) *Per fix: an observable, a loss
consequence, a check against the replacement text, and an action per verdict* — adopted as FR-5.
It is satisfiable against the 425-line text (one verdict comes out *already provided*, one *lost*),
it still fails HEAD (no record survives the replacement at all), and it leaves stage 2 free to
prescribe "keep the replacement" for the fix upstream already provides — the option the template
makes newly attractive and which (i) and (ii) both forbid.

**OQ-11 (taking the refresh).** Three candidates. (a) *Adopt the 0.47.0 rewrite in this task* —
rejected on the four grounds in the row; the decisive one is that it does not fix R-18, so this task
would still owe its metric edit while having replaced the program all sixteen of its criteria are
written against. (b) *Adopt it and re-derive the criteria* — that is a task, not an amendment: 425
lines of unreviewed code, a `.ps1` mirror decision OQ-4 already settled the other way, and a diff two
orders of magnitude past NFR-1's bar. It is filed as its own pool row, with RS-6's upstream report
attached, precisely so the choice is made deliberately rather than by a refresh nobody scheduled.
(c) *Decline and make the eventual refresh survivable* — adopted, and it is what FR-5 is for. The
honest cost of (c) is stated rather than hidden: this repository keeps a 151-line script whose
harvest is line-joined and whose header filter is the one upstream calls a defect, and it keeps them
until the (b) row runs.

## 4. Why the criteria are shaped the way they are (R-22)

Two traps were named in the dispatch and both are answered structurally rather than by wording.

- *"The rotation branch is reachable"* would be satisfied by a script that rotates the wrong thing.
  AC-1 (the file ends under the cap **in lines**) and AC-2 (total conservation, oldest-first, header
  intact) are a pair: AC-1 is the discriminating half, AC-2 the half that kills a candidate which
  rotates the newest entries, reflows a long line, or eats the header. AC-2 is declared a control so
  nobody later quotes it as evidence of a change.
- *"F.4 passes after archiving"* would be satisfied by harvesting nothing. AC-15 therefore requires
  ≥1 harvested insight **and** ≤30 lines **and** digest equality between what the script produced and
  what was staged — the last clause is what makes "no hand-rotation" checkable rather than asserted.
  Sixteen consecutive deliveries hand-rotated, so a candidate that ships without this is visible.

A third shape of the same disease was not caught here first: **a criterion whose discriminating clause
is defined relative to its own run, or which a degenerate candidate satisfies.** Four criteria were
rewritten for it.

- **AC-7** compared the dry run to its own wet run, which HEAD satisfies by rotating 0 in both. The
  fix is an absolute number — `Rotated 3` over the AC-1 fixture — plus the obligation to measure the
  same report on HEAD and on the candidate and to record NOT-DISCRIMINATING if the strings match. A
  criterion that cannot be shown to separate two texts reports that fact instead of a pass.
- **AC-5** had three clauses HEAD satisfied by doing nothing and one any `echo` satisfied. The
  residual is now an arithmetic identity: the report's number equals `wc -l` of the resulting index
  minus 30. That is checkable and it is wrong-number-proof. The second fixture (header-only, over the
  cap, clamp to zero rotations) is there because that is the shape where the residual line is the
  *only* signal the file is over the cap — the run takes the append path and rotates nothing.
- **AC-9** counted routing collisions, which a rule reading "everything goes to the contract portion"
  scores 0/0 on. Clause (b) prices the per-kind list against practice instead. Witnesses read
  first-hand, one per kind: `## Smaller alternative rejected` → contract
  (`doctor-rows-establish-their-fact/02_SOLUTION_DESIGN.md:216`, `ruleset-staleness-visibility/02_SOLUTION_DESIGN.md:150`;
  earlier tasks put it in the rationale — `share-url-userinfo-contract/02_RATIONALE.md:19`,
  `restricted-network-regression-test/02_RATIONALE.md:53` — which is why divergence resolves to the
  most recent task); coverage table → contract (`ruleset-staleness-visibility/02_SOLUTION_DESIGN.md:237`);
  per-edit-id size table → contract by the most-recent rule (`doctor-rows-establish-their-fact/02_SOLUTION_DESIGN.md:253`)
  against `ruleset-staleness-visibility/02_RATIONALE.md:119`; evidence → rationale
  (`ruleset-staleness-visibility/02_RATIONALE.md:96`, `doctor-rows-establish-their-fact/02_RATIONALE.md:190`);
  re-verification record → rationale (`doctor-rows-establish-their-fact/01_RATIONALE.md:5`);
  rejected reading → rationale (`doctor-rows-establish-their-fact/05_RATIONALE.md:99`, `06_RATIONALE.md:396`);
  measurement obligation → rationale (`doctor-rows-establish-their-fact/01_REQUIREMENT_ANALYSIS.md:215`,
  T-26's OQ-11, which routes the re-verification record, the measurement obligations and the rejected
  readings into `01_RATIONALE.md` by name). That last one is expected to come back as a **finding**:
  any per-kind list sending the measurement obligation to the contract contradicts the only instance
  this project has. Two outcomes are therefore live and both are acceptable — the list is corrected
  in place, or it is deleted because FR-6(a)'s bare test already routes every witnessed kind
  correctly. Deletion is the outcome rule 85 prefers and the criterion now says so.
- **AC-13** asked for a property no record can deliver (see §3, OQ-6). It now measures what a record
  can deliver: run the recorded check against the text that would actually arrive, take the verdict,
  perform the stated action, and then measure the two observables that matter — the index at ≤30
  lines on the AC-1 fixture, and the wrapped bullet's continuation text plus its `· evidence:` tag
  reaching the index on the AC-6 fixture. Those two observables, not AC-6's one-line shape, are what
  the drill asserts, because upstream carries a wrapped entry as several index lines and the drill
  must not fail a text for being different where it is not worse.

Controls are labelled as such (AC-2, AC-3, AC-4, AC-6, AC-8, AC-10, AC-16) so the count of
discriminating criteria is honest: **AC-1, AC-5, AC-7, AC-9, AC-11, AC-12, AC-13, AC-15** are the
eight the current tree fails.

Nothing here needs root, a live service, or an installed `sc`, so no criterion is expected to report
BLOCKED. If one does, it is reported as BLOCKED with a filed row and never substituted (the R-31
practice).

## 5. Measurement obligations routed forward

- Stage 2 records the chosen mechanism for FR-5 and the price of the alternatives it declined
  (BC-11), re-derived against the 0.47.0 text named in §1 rather than against the vendored file.
- Stage 6 measures AC-7's dry-run report on **HEAD** and on the candidate over the one AC-1 fixture
  and quotes both strings; equal strings are reported as NOT-DISCRIMINATING, not as a pass.
- Stage 6 names the refresh-source version it ran AC-13's checks against (BC-13) and quotes each
  verdict, so a later version that flips one is visible as a residual rather than as a silent pass.
- Stage 6 reports AC-9(b) as a table of kind → witness citation → destination, so the finding that
  corrects or deletes the per-kind list is evidenced rather than argued.
- Stage 6 measures AC-15 at the real delivery run and reports the two digest pairs verbatim; that run
  is the only archive run this task performs against the real repository (BC-8).
- The claim "the bypass `HARNESS_ALLOW_OUTSIDE_RM=1` has never been set" is **inherited from the
  dispatch, not re-measured**, and no requirement rests on it — OQ-1 holds on rule 75's documented
  contract alone.

## 6. What this task deliberately does not build

A harness linter, a script-integrity checker, a vendored-file digest gate, a CI job, a template file
or snippet library for the committed-diff criterion, a local `task-state.js`, a cadence tool, and any
new rule fragment. Each was reachable from a defect above; each is priced in the section that
declined it. The three fixes are one metric, one section, and one list.

It also deliberately does not **take** anything: the 425-line upstream rewrite is declined here and
filed as its own row (OQ-11), so nothing this task ships depends on a harness upgrade happening, and
nothing it ships is invalidated by one either — that is the whole purpose of FR-5's record.
