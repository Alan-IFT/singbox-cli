# 02 — Rationale · T-27 `harness-self-maintenance`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

| Need | Existing code / artifact | Path | Decision |
|---|---|---|---|
| Measure the insight index against its cap | `wc -l < .harness/insight-index.md` | `.harness/scripts/verify_all.sh:213-219` (F.4) | **Reuse the measurement itself** — E-1 takes the same tool on the same file. This is the whole design of the rotation fix. |
| Rotate oldest entries to a history file | rotation branch: oldest-first slice, `## Rotated <date>` block, header + remaining + harvested rewrite | `.harness/scripts/archive-task.sh:96-121` | **Reuse as-is.** It is correct for the shapes this repository's index actually takes, and it has never run; only the condition that reaches it is wrong. No line of it is edited (K-5). Its two divergence shapes are reported, not repaired (RS-9). |
| Harvest wrapped `## Insight` bullets | local `awk` continuation-join fix | `.harness/scripts/archive-task.sh:51-71` | **Reuse as-is**, and pin it against regression (V-6). |
| A place that says what a delivery commit contains | `## The policy` step 1 ("`git add` only the files that task actually changed") | `.harness/rules/80-delivery-policy.md:16-24` | **Extend** with the process-path list — the fragment's subject already *is* what a delivery commit contains (OQ-3). |
| A place that says where a stage doc's units go | rule 70's `## Process discipline`, rules 1-4 | `.harness/rules/70-doc-size.md:31-77` | **Extend** with one H2 section. No new fragment (E.5 index duty, rule 85). |
| Decide whether a refreshed vendored script still needs a local fix | the fixtures this task already builds, plus `wc -l` and a `grep` of the resulting entry | `test/t27/**`, `verify_all.sh:215` | **Reuse.** B-3's checks are the AC-1 and AC-6 fixtures run against whatever arrived; the record adds no tool, no digest and no pin. |
| Recover the pre-replacement text when a check says a fix was lost | `git log -p -- <path>` over a tracked file | the repository itself | **Reuse, as a source and not as the mechanism.** Version control holds the prior bytes, but B-3 never instructs a restore of them — a refresh is a replacement, so the prior text is reference material for a bounded edit, not the answer. |
| Detect that `/harness-upgrade` replaced a file | (none found — and none built) | — | Rejected under BC-11/K-13: `upgrade-project.sh:216` already prints `REFRESH\|…` at the moment it happens and `git diff` shows it afterwards. A second detector would be a second opinion of a fact git already holds — and it would still not answer the question that matters, which is whether the *arriving text* needs the fix. |
| A human-owned standing obligation register | `.harness/operator-obligations.md` | `.harness/operator-obligations.md:6-12` | **Not used.** Its charter is "steps a human must perform on a host this project's agents cannot reach"; running a check against a refreshed file is an in-repo action any agent can take, and the file is outside AC-14's product list. |
| A record of declined approaches | `.harness/rejected-decisions.md` | same | **Used at delivery, by the PM** (RS-7) — outside this task's product diff. |
| A fixture home inside the tree, untracked | `test/` is gitignored; precedent `test/t20/.head-clone/` | `.gitignore:19` | **Reuse** — `test/t27/` satisfies BC-8/BC-9 and needs no destructive-command override (`75-safety-hook.md:92-94`: in-project deletions are allowed). |
| A glossary for new vocabulary | `CONTEXT.md` | repo root | **Not written to.** Its first paragraph scopes it to terms `sc`'s code, tasks and bilingual UI share; "rotation", "boundary rule" and "vendored local fix" are harness vocabulary (`01_RATIONALE.md:94-96`), and `CONTEXT.md` is not in AC-14's product list. |

Nothing here is a new dependency: the design adds no library, no service, no script and no tool
invocation the repository did not already make.

## Why the metric is the seam, not the symptom

`archive-task.sh:89` builds `current` by `grep -E '^[[:space:]]*-[[:space:]]'`, i.e. bullets, and
`:94` compares that count against 30. `verify_all.sh:215` reads `wc -l`. `70-doc-size.md:26` and
`05-insight-index.md:5,29,48` both state the cap in **lines**. Today's index is 8 header lines + 22
entries = 30 lines, so the script believes it has 8 lines of headroom it does not have; rotation fires
only above 38 lines, which is why sixteen deliveries hand-rotated.

Rule 85 asks for the abstraction behind the symptom. The symptom is "the branch never fires"; the
abstraction is **one cap, one measurement**. Any fix that leaves the script computing its own estimate
of the line count — a constant, an arithmetic reconstruction, a second grep — keeps two measurements
alive. And the constant is worse than it first looks: the script's "header" is a `grep -v` over the
whole file (`:114`), so a blank line between two entries, or a `## Rotated` heading pasted in by a
hand rotation, moves it without anyone editing the header block.

## What the corrected I-1 invariant costs, and why the rewrite is still frozen

E-1 decides on `wc -l` of the **input**; the frozen rewrite reconstructs the **output** as
`echo "$header"` + remaining + harvested (`:113-119`). Those two agree exactly when the input ends
with a newline and holds at least one non-bullet line. Two reachable shapes break that:

| shape | what the decision counts | what the rewrite emits | result |
|---|---|---|---|
| last line carries no trailing newline | `wc -l` undercounts by 1 | `echo` terminates every line, restoring the missing one | 31 lines, F.4 WARN |
| zero non-bullet lines | header contributes 0 | `header=""`, and `echo ""` writes one empty line | 31 lines, F.4 WARN |

Three responses were weighed. (1) **Guard in the decision** — add 1 to `index_lines` when the file has
no trailing newline, subtract 1 when `grep -v` is empty: two special cases bought to compensate for a
rewrite the design is not allowed to open, i.e. exactly the "adds a guard for a special case" shape
rule 85 ranks below deleting one. (2) **Fix the rewrite** — replace `echo "$header"` with a `printf`
over an array, which is what the 0.47.0 template does (`:386-395`). It is the right fix and it is an
**algorithm** change inside `:105-132`: AC-16 forbids it here and NFR-1's single-digit bar cannot hold
it. (3) **Measure and report** — adopted, and it is what C-3 asks for. Neither shape occurs in this
repository's index (it ends with a newline and carries 8 non-bullet lines), so the delivery run AC-15
observes is unaffected; both are fixtures (V-16) and a residual (RS-9) owned by whichever task next
opens the rewrite — most likely the OQ-11 adoption row, where the fix already exists upstream.

The honest statement is therefore not "the two can never disagree" (round 1's claim, which F-3
refuted) but "they agree under a stated condition, the condition holds for the artifact this task
delivers against, and the two shapes outside it are measured rather than assumed away".

## The durability ruling, re-derived against the artifact that will actually be copied

`upgrade-project.sh:56` resolves the refresh source to
`$TEMPLATE_ROOT/skills/harness-init/templates/common/.harness/scripts/`, which on this host is
harness-kit **0.47.0**. That `archive-task.sh` was read end to end this round: **425 lines**, a
different program from the vendored 151-line one — `mapfile` + an `insight_scan` classifier instead of
the harvest `awk`, `printf '%s\n'` instead of `echo`, an exit-3 refusal path, multi-line entries.
`refresh_set` names `archive-task.sh` (`:189`), the loop NOOPs on `cmp -s` (`:210-212`) and otherwise
emits `REFRESH` and `cp`s with no backup (`:216-226`).

Round 1 ruled "(a) local fix + a durable record whose re-application path is `git`". That ruling was
**false against this artifact**, and the two instructions it put in B-3 were false with it:
`git checkout -- <path>` after a refresh discards 425 lines of upstream work, and "re-apply the
harvest `awk` join" obliges a re-application of a fix whose harm that text does not reintroduce.

**Re-derived ruling: (a) local fix + a durable record outside the file whose content is a *check per
fix*, not a restore path.** The standing instruction is *keep what arrives*; each fix carries one
check the reader runs against the arriving text and one action per verdict. Three properties decide
it:

- **Whether a fix is still needed is a property of the arriving text, not of this repository.** Only a
  check can answer it. A record that asserts an answer is stale one version later — BC-13's rule, and
  the reason B-3 names no version and states no verdict.
- **The re-application, when a check says *lost*, is a bounded edit stated as a metric.** For the
  rotation fix the record says: make the decision read `wc -l` of the index — F.4's own measurement —
  and rotate until the file it writes is ≤30 lines. That is directive without pretending a patch is
  transcribable into an unknown program, which is what OQ-6 rules admissible.
- **No action discards the arriving text as its only path**, which is FR-5's explicit bar and the
  defect F-1 caught.

What happens at the next `/harness-upgrade` under this ruling: the run prints
`REFRESH|.harness/scripts/archive-task.sh (from current template)`; the reader opens rule 80, runs two
fixture archives against the new file, and gets two verdicts. Against 0.47.0 today those verdicts are
*lost* for the metric (it still decides on entries, `:333` + `:337-338`, and an entry may span several
index lines, so the AC-1 fixture ends at 33 lines) and *already provided* for the join (wrapped
bullets are classified `C` and every line of the entry is harvested, `:161-165` + `:299-303`, so the
continuation text and the `· evidence:` tag arrive). One bounded edit is made, four upstream fixes
this project has not paid for are kept, and nothing is discarded. Those verdicts are recorded by
whoever runs the drill together with the version measured — they are **not** written into the rule.

- **(b) rejected** — a project-side revert detector is a new gate; BC-11 forbids buying this before
  the cheaper route fails, and the cheaper route does not fail. It is also strictly weaker than the
  check: knowing a file was replaced does not tell you whether the replacement needs the fix.
- **(c) filed, not built** — reporting the metric mismatch upstream costs this repository zero lines
  and would eventually make one check redundant; it travels as RS-6, in the corrected shape (the
  branch there is not dead — it fires on the wrong metric).
- **(d) rejected** — removing the dependence means either a local replacement script (NFR-2 forbids)
  or hand-archiving forever (the cost this task exists to remove).
- **Taking the refresh instead** — out of scope by OQ-11 and out-of-scope 10, and not re-litigated
  here. The design does not lean on it: nothing this task ships depends on an upgrade happening, and
  nothing it ships is invalidated by one.

## AC-9(b) — every FR-6(c) kind against its witness

Witness citations are `01_RATIONALE.md:200-218`, read first-hand this round. "B-1 routes to" is what
the **shipped** text does — FR-6(a)'s test, with FR-6(b)'s precedence clause applied first.

| FR-6(c) kind | archived witness | portion the witness occupied | B-1 routes to | agrees? |
|---|---|---|---|---|
| `## Smaller alternative rejected` | `doctor-rows-establish-their-fact/02_SOLUTION_DESIGN.md:216`, `ruleset-staleness-visibility/02_SOLUTION_DESIGN.md:150` (divergence: `share-url-userinfo-contract/02_RATIONALE.md:19` and `restricted-network-regression-test/02_RATIONALE.md:53` put it in the rationale; most recent decides) | contract | contract — precedence: `85-design-discipline.md:41` names it in `02_SOLUTION_DESIGN.md` | ✔ |
| FR/BC/AC coverage table | `ruleset-staleness-visibility/02_SOLUTION_DESIGN.md:237` | contract | contract — a later stage must discharge each row | ✔ |
| per-edit-id size table | `doctor-rows-establish-their-fact/02_SOLUTION_DESIGN.md:253` (divergence: `ruleset-staleness-visibility/02_RATIONALE.md:119`; most recent decides) | contract | contract — it is the bar the next stage checks | ✔ |
| evidence section | `ruleset-staleness-visibility/02_RATIONALE.md:96`, `doctor-rows-establish-their-fact/02_RATIONALE.md:190` | rationale | rationale — it supports a claim, binds nobody | ✔ |
| re-verification record | `doctor-rows-establish-their-fact/01_RATIONALE.md:5` | rationale | rationale — it is how a verdict was reached | ✔ |
| rejected reading | `doctor-rows-establish-their-fact/05_RATIONALE.md:99`, `06_RATIONALE.md:396` | rationale | rationale — it explains a choice | ✔ |
| measurement obligation | `doctor-rows-establish-their-fact/01_REQUIREMENT_ANALYSIS.md:215` (T-26 OQ-11) | rationale | rationale — **precedence**: that row routes it "into `01_RATIONALE.md`, the destination the analyst contract names for exactly these units" | ✔ |

Seven of seven agree, so AC-9(b)'s final clause fires and the ten-line per-kind list is **deleted**.
The last row is the one that carries the decision, and it is worth stating why it is not a fudge:
round 1's table routed the measurement obligation to the **contract**, which contradicts the only
instance this project has. The bare test would make the same mistake — "someone must produce this
number" reads as *satisfy* — but the precedence clause reaches it first, in both directions this
project writes it: the analyst contract names `01_RATIONALE.md` for a stage-1 measurement obligation,
and the architect contract names `## Residuals travelling` for one travelling out of stage 2. A
measurement obligation's destination is therefore *always* decided by the naming contract and *never*
by the test, which is exactly what makes its table row redundant rather than merely wrong.

Two divergences are recorded rather than smoothed over: `## Smaller alternative rejected` and the
per-edit size table each sat in the rationale in an older task and in the contract in the most recent
one. Both resolve to the contract by AC-9(b)'s most-recently-delivered rule, and both are re-checked
by V-9 before E-2 lands.

## Process-path derivation (FR-9) — derived here, not transcribed

Enumerated first-hand from what this repository's pipeline writes as *process*, by reading the tree
rather than any prior criterion:

| path | who writes it | evidence |
|---|---|---|
| `docs/tasks.md`, `docs/tasks-archive.md` | PM, at task open and at delivery | both exist; rotation rule at `70-doc-size.md:58-62` |
| `docs/features/<slug>/**` | stages 1-7 (`0N_*.md`, `0N_RATIONALE.md`, `PM_LOG.md`) | this task's own folder |
| `docs/features/_archived/**` | `archive-task.sh:131`; `insight-history.md` at `:108-111` | 30+ archived task folders — and this is why the history file needs no bullet of its own (F-7) |
| `docs/batches/**` | the batch loop: `BATCH_PLAN.md`, `BATCH_LOG.md`, `BATCH_REPORT.md` | `docs/batches/{default,followups}/`; **this is R-36's omission** |
| `.harness/insight-index.md` | `archive-task.sh:118,124` | the file |
| `.harness/rejected-decisions.md` | any stage that declines an approach (`25-decision-policy.md`) | 3+ existing records |
| `.harness/operator-obligations.md` | stage 6/7 when a criterion needs a human | 5 rows, opened by T-20/T-07/T-22/T-23/T-24 — **also missing from T-19's prose** |
| `CONTEXT.md` | stage 2/4 when a term is introduced or sharpened | 20+ terms, per-task |

Deliberately **not** in the list: `docs/dev-map.md` (product documentation of the code — T-19 shipped
it in its *product* half), `AI-GUIDE.md` and `.harness/rules/*.md` (rules are product of a harness
task, not process output), `.harness/intervention.md` and `.harness/ambient.flag` (gitignored,
`.gitignore:23-24` — they can never appear in a commit), `evals/golden-tasks.md` (edited by a task
that targets it, not by every delivery). V-10 re-checks the list against three real delivery commits
before E-3 lands; anything it finds is added, which is the point of deriving rather than transcribing.

## Rejected homes for FR-5's record

AC-14 enumerates the product diff exactly: `archive-task.sh`, rule 70, the FR-8 host fragment, and
`AI-GUIDE.md`'s index line. That is not incidental — it *decides* this question, because a record in
any other file fails AC-14 as written.

| candidate | why rejected |
|---|---|
| a comment inside `archive-task.sh` (status quo, `:51-56`) | deleted by the replacement it warns about (`upgrade-project.sh:210-226`); FR-5 forbids it by name |
| `.harness/rules/70-doc-size.md` | AC-10 caps it at 130 lines, and rule 70's subject is document size, not vendored scripts; it hosts the *pointer* instead (the caps-table cell E-2 rewrites) |
| `.harness/insight-index.md` | one line cannot carry two checks, two verdict actions and two loss consequences; worse, the entry **rotates out** — the record would be deleted by the very mechanism this task repairs |
| `.harness/operator-obligations.md` | outside AC-14's product list; its charter is host-side human steps, and running a check against a refreshed file is an ordinary in-repo action |
| a new `.harness/rules/90-vendored-scripts.md` | a new fragment: rule 85, NFR-2 and out-of-scope 5 all forbid it, and E.5 would owe it an index line |
| `docs/dev-map.md` | product documentation of `bin/sc`; nothing in the delivery flow reads it for delivery facts |

`.harness/rules/80-delivery-policy.md` wins on all four counts: it is in the diff already (zero added
files), its declared read moment is delivery — which is when the archive run happens and when the loud
symptom appears — and the trigger E-3 adds names `/harness-upgrade` explicitly, so the record is read
at the moment a check becomes answerable. The loud symptom's other entry point is closed for free:
rule 70's caps-table cell for the insight index is rewritten in place (no line added) to point at the
record when F.4 still WARNs after an archive run.

## Size, against the bar

| unit | added | removed |
|---|---|---|
| E-1 `archive-task.sh` | ~7 | ~3 |
| E-1b `archive-task.sh` | 1 | 1 |
| E-2 rule 70 | ~20 | 1 |
| E-3 rule 80 | ~30 | 0 |
| E-4 `AI-GUIDE.md` | 1 | 1 |
| **total** | **≈ 59** | **≈ 6** |

Executable: **8 added lines**, one file, inside NFR-1's single-digit bar. Against the three most
recent deliveries — T-26 net-negative on one row, T-25 `+80/−41` with no new function, T-24 `+79/−55`
— this task adds no function, no file, no script, no fragment and no gate. Fifty-one of the ~59 added
lines are the policy texts FR-6 and FR-8 *are* (B-1 = 18 against a ≤35 budget, B-2 = 13 against ≤15,
B-3 = 14 unbudgeted), and this round removed 12 of them relative to round 1 by deleting B-1's unit
table and B-2's redundant bullet.

## Risks

| id | risk | mitigation |
|---|---|---|
| R-1 | The clamp path leaves `remaining` empty, and `"${remaining[@]}"` under `set -u` errors on bash < 4.4 — the archive dies after the harvest report, mid-run. | V-5 exercises exactly this fixture and reads the resulting file; the script already carries the sibling hazard note at `:46`. If it fires, the fix is the same `arr=()` pre-declaration the script already uses — no new construct. |
| R-2 | A fixture is run through the **repository's own** `archive-task.sh`, whose root resolves to the real repo (`:27`), rotating the real index and moving a real task folder before delivery — destroying AC-15's single observation. | K-9/PQ-4 require running the fixture's own copy; V-1's fixture tree contains `.harness/scripts/archive-task.sh` itself, so the correct invocation is the only convenient one. K-8 puts every fixture under `test/t27/`. |
| R-3 | `/harness-upgrade` runs between this delivery and the next task and **replaces** `archive-task.sh` with a different program; the metric fix goes with it and the next delivery hand-rotates again. | B-3 names the event, keeps what arrives, and gives one check per fix with an action per verdict; rule 70's caps cell routes the loud symptom (F.4 WARN after an archive run) to it; V-12 drills it against the text that would actually arrive. |
| R-4 | The drill is run against a **hand-made** "upstream" text, or against the vendored file, and passes vacuously. | V-12 pins the resolution path (`upgrade-project.sh:56` → the 0.47.0 template) and requires the version and path to be reported (BC-13, PQ-5). The copy is read-only and lands in `test/t27/refresh/`, never in `.harness/` (K-14). |
| R-5 | A later plugin version flips a verdict — e.g. it fixes the metric and breaks the harvest — and the drill's recorded result is quoted as if it still held. | B-3 states checks and never verdicts, and every stage that runs one names the version measured (BC-13). A flipped verdict is a residual, not a criterion failure. |
| R-6 | Deleting B-1's unit table leaves a kind mis-routed in practice, and the section is weaker than round 1's. | The deletion is measured, not assumed: `## AC-9(b) — every FR-6(c) kind against its witness` checks all seven against archived instances, and V-9 re-runs both clauses before E-2 lands. If a kind contradicts, RS-2 corrects B-1 in place — the rows come back, they are not waived. |
| R-7 | The precedence clause now carries most of B-1's weight, and a reader who does not know an agent contract's declared sections cannot apply it. | The clause is stated in both directions a naming can take (a section by name, or a destination for a kind of unit), and B-1's final clause tells the reader what to do when nothing names it: report a schema-gap row. V-9(a) is the measurement that this is enough for two real document pairs. |
| R-8 | AC-11's partition finds a delivery-commit path in neither list, and the developer treats it as a criterion failure and stops. | RS-3: a leftover path is *added to B-2 before E-3 lands*. FR-9 makes derivation the deliverable; V-10 is a derivation step, not only a check. |
| R-9 | V-16's two fixtures end at 31 lines, and a later stage "fixes" them by editing the rewrite or by hand-editing the fixture index. | The frozen set names `:105-132` and out-of-scope 8 names the repair; C-3 requires the result to be *reported*. RS-9 carries it to the pool with the upstream fix already identified. |
| R-10 | Rule 70 lands at ~111 of 130 lines and a later process rule pushes it over, turning F.2/AC-10 into a recurring WARN. | RS-8 states the headroom explicitly (now ~19 lines, up from 7) and names the `70b-` split as the intended next move (rule 70's own caps table prescribes it at `:24`). |

## Round-2 corrections that changed a design position

Recorded here because they are how a verdict was reached, not something a later stage must satisfy.

- The durability ruling's **mechanism** changed (git restore → check per fix). The **home** did not:
  rule 80 still wins for the reasons above.
- B-1 lost its unit table. Round 1's defence ("rejected by AC-9, which is contract") did not survive
  the gate's test and does not survive the witness table either; the smaller text is now the measured
  answer, not a concession.
- Three H2 sections were removed from `02_SOLUTION_DESIGN.md` so that document satisfies the clause it
  is installing. Nothing binding was lost — every unit landed in a declared shape, and E-5 reports the
  one gap (the coverage mapping) instead of inventing a section for it.
- E-1's estimate fell from +9 to +7 added lines because the clamp and its residual `echo` are written
  as one line and E-1b as a single-line `if`, which is what keeps the executable diff single-digit
  once E-1b became unconditional.

## Evidence cited (paths only, per rule 70)

- Metric divergence: `.harness/scripts/archive-task.sh:89,92-95` vs `.harness/scripts/verify_all.sh:213-219`;
  cap stated in lines at `.harness/rules/70-doc-size.md:26` and `.harness/rules/05-insight-index.md:5,29,48`.
- Vendored refresh mechanism: `.harness/scripts/upgrade-project.sh:56` (template root),
  `:186-194` (`refresh_set` includes `archive-task.sh`), `:210-226` (`cmp` then unconditional `cp`, no
  backup, no marker preservation), `:216` (the `REFRESH` emit a human sees).
- The refresh source, read first-hand this round:
  `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.47.0/skills/harness-init/templates/common/.harness/scripts/archive-task.sh`
  — 425 lines; `:161-165` + `:299-303` multi-line entry harvest, `:333` + `:337-338` entry-based
  rotation decision, `:340` clamp, `:364-366` guarded `touch`, `:382-395` header from the scanned
  range with `printf '%s\n'`, `:52-56` the `set -e` discipline note.
- Local fix and its self-defeating note: `.harness/scripts/archive-task.sh:51-56`.
- The prose instance of the path list R-36 is about:
  `docs/features/_archived/ruleset-staleness-visibility/01_REQUIREMENT_ANALYSIS.md:149`.
- AC-9(b) witnesses: the eleven citations tabulated above, sourced from `01_RATIONALE.md:200-218`.
- Fixture home: `.gitignore:19`, precedent `test/t20/.head-clone/`, guard boundary
  `.harness/rules/75-safety-hook.md:92-94`.
