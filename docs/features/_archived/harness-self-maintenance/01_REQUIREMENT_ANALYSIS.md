# 01 — Requirement Analysis · T-27 `harness-self-maintenance`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

Three harness artifacts state something untrue and every task pays the difference by hand: the
archive script decides rotation on a count that is not the count the cap is measured in, so its
rotation branch has never fired and sixteen consecutive deliveries hand-rotated the insight index;
rule 70 declares no stage-doc boundary rule, so units the pipeline requires fit no declared shape;
and the committed-diff acceptance criterion enumerates two path lists that omit the batch loop's own
files, so every task reusing it inherits a false failure.

## In-scope behaviors

**FR-1** — `archive-task.sh` decides rotation on the same measurement the cap is stated in and
`verify_all` **F.4** takes: the number of lines in `.harness/insight-index.md`. A run that would
leave the index over the cap rotates, and a completed archive run leaves F.4 PASS with no hand edit
to either file.

**FR-2** — Rotation conserves content exactly. The entries it moves are the **oldest** ones, written
verbatim and in their original order into `docs/features/_archived/insight-history.md`, and the
concatenation of (rotated entries, entries remaining in the index) equals the concatenation of
(entries present before the run, entries harvested this run) byte for byte; the index's header lines
survive unchanged and the harvested entries land last.

**FR-3** — A run that does not need to rotate does not rotate. Below and at the cap the script's
observable behaviour is what it is today — append the harvested entries, create no history file,
rewrite no header — and `--dry-run` writes nothing at all while reporting the rotation count the same
run would perform.

**FR-4** — The local continuation-join fix at `archive-task.sh:51-71` keeps its behaviour: a `##
Insight` bullet wrapped over several lines is harvested as **one** index entry that still carries its
trailing `· evidence: <slug>` tag. No harvested entry is truncated, split, or stripped of its tag.

**FR-5** — Both local fixes to the plugin-vendored `.harness/scripts/archive-task.sh` are recorded
outside that file, in an artifact this repository controls and the delivery flow reads, naming per fix
the observable it restores, whether its loss is loud (the rotation fix: the index grows past the cap
and F.4 WARNs) or silent (the continuation-join fix: harvested entries lose continuation text and
their evidence tag), and **one check the reader runs against the replacement text** to decide whether
that observable still holds there. `/harness-upgrade` **replaces** the file with the current plugin
template — a text of the plugin's choosing, not a revert of the local hunks; today a 425-line rewrite
(BC-13) — so the binding property is this: from the record and its checks alone, without the in-file
note the replacement deletes and without re-diagnosing either defect, the reader reaches one verdict
per fix plus the action the record states for that verdict, and applying those actions leaves the
resulting script deciding rotation on the cap's own measurement (FR-1) and delivering every wrapped insight's
continuation text and trailing `· evidence: <slug>` tag into the index (FR-4's observable). The record
names no action that discards the replacement wholesale as its only path; the mechanism is stage 2's
(BC-11, BC-13).

**FR-6** — `.harness/rules/70-doc-size.md` declares a section named exactly `## Stage-doc boundary
rule` that (a) states one test assigning every unit a stage produces exactly one destination —
the contract portion `0N_*.md` or its rationale sibling `0N_RATIONALE.md`; (b) states which wins when
another rule names a section of a stage doc by name; (c) names the destination for each recurring
unit kind this project has recorded as unroutable **and for which an archived stage document of this
project carries a citable instance** — `## Smaller alternative rejected`, the FR/BC/AC coverage table,
the per-edit-id size table, evidence sections, the re-verification record, the measurement obligation
and the rejected reading, minus any kind AC-9 finds no instance of; and (d) states what a unit fitting
no declared shape does, which is to be recorded as a schema-gap row rather than to have a section
invented for it.

**FR-7** — FR-6 introduces no new document kind: the only destinations are the stage doc and the
`0N_RATIONALE.md` sibling this project already writes.

**FR-8** — The path list a committed-diff acceptance criterion partitions against has exactly one
home, and that home satisfies four properties: it is outside every per-task and archived stage
document; it is a fragment a stage reads **before writing such a criterion**, with a "when to read"
trigger that says so and an `AI-GUIDE.md` index line stating the same trigger; it is an existing rule
fragment, not a new one; and it carries `docs/batches/**` alongside the ledger paths. See OQ-3 for
the binding home.

**FR-9** — That list is derived first-hand at fix time from what the pipeline actually writes as
process rather than as product — the task board and its archive, the batch loop's plan and log, the
per-task stage documents and `PM_LOG.md`, the insight index and its history, the rejected-decisions
record and the glossary — and not transcribed from any prior task's instance of the criterion.

**FR-10** — A committed-diff criterion written after this task enumerates its own **product** files
and **cites** the shared list for the rest instead of re-transcribing it; a path in neither remains a
failure of that criterion. This task's own AC-14 is written in that form and already carries the
`docs/batches/**` carve-out.

**FR-11 — invariants, all unchanged by this task.** (a) `verify_all.sh` is not edited: F.4's metric
and its threshold of 30 stay exactly as they are, and no check is relaxed, removed or made
conditional. (b) `bin/sc` has **no diff**, and neither do `install.sh`, `uninstall.sh`, `README.md`,
`README.zh-CN.md` or `CHANGELOG.md`. (c) Nothing under `.claude/` is edited, and rule fragments are
referenced rather than composed (`00-core.md:5-7`), so `verify_all` **E.4** is unaffected and no
`harness-sync` run is required by any edit this task makes. (d) B.2 `check-i18n-parity.sh` keeps its
present scope, blind spot included.

## Out of scope

1. `guard-rm.sh` — every part of it: what it blocks, what it permits, its tokenizer, and its BLOCK
   message (OQ-1). The file is unchanged in the committed diff.
2. `.harness/scripts/task-state.js` and `.harness/scripts/entropy-cadence` — absent, plugin-owned,
   and not substituted, wrapped or re-implemented here (OQ-2).
3. The PowerShell mirrors `archive-task.ps1` and `guard-rm.ps1`, which carry the same rotation defect
   and are not edited (OQ-4).
4. `.harness/rules/05-insight-index.md:47`'s claim that archiving compresses the stage documents into
   a `summary.md`, which the script does not do (OQ-7).
5. Any new script, rule fragment, hook, CI job, harness linter, script-integrity checker, vendored-file
   digest gate or scheduled self-check.
6. Any change to what an insight entry is, to the 30-line cap itself, to the harvest source
   (`07_DELIVERY.md`'s `## Insight` section), or to where archived stage documents are moved.
7. Any product behaviour, any user-visible string, any translation, and any `CHANGELOG.md` entry —
   this task changes nothing a user of `sc` can observe.
8. `docs/tasks.md` rotation, `PM_LOG.md` compaction, and every other rule-70 process rule not named
   in FR-6.
9. The live host: no install over `/usr/local/bin/sc`, no service action, no write under
   `/etc/sing-box` or `/var/lib/sing-box`, no `bin/sc` import.
10. Adopting harness-kit 0.47.0's 425-line `archive-task.sh` rewrite, in whole or in part, and running
    `/harness-upgrade` inside this task (OQ-11). The vendored 151-line script is the text this
    delivery edits and runs.

## Boundary conditions

**BC-1** — `.harness/insight-index.md` absent → the run creates it and states that it did, exactly as
today; rotation is not attempted against a file that does not exist.

**BC-2** — The index holds header lines and zero entries, or is empty → no rotation, no history file,
and the harvested entries are appended.

**BC-3** — Zero insights harvested (no `07_DELIVERY.md`, or no `## Insight` section, or an empty one)
→ the index is not rewritten and not rotated when it is at or under the cap, and the task's stage
documents still move.

**BC-4** — The index is already over the cap before the run → the run brings it to the cap, rotating
the oldest entries, whether or not anything was harvested this run.

**BC-5** — The cap cannot be met by rotating entries (the header alone reaches it, or every entry
would have to go) → the run rotates at most the entries that exist, deletes no header line and no
harvested entry, and states the residual over-cap in its report rather than exiting silently or
truncating the file.

**BC-6** — An entry's text begins with a character an unquoted shell write would interpret, contains
backslashes, or is the longest line in the file → it round-trips byte for byte through rotation
(FR-2), and length is never a reason to reflow, wrap or split it.

**BC-7** — `--dry-run` on any of the above → zero bytes written anywhere, verified by a before/after
snapshot of the fixture tree, and the reported counts equal what the same run without `--dry-run`
performs.

**BC-8** — A fixture must never be a real task: every criterion below is satisfied by a **fixture**
index and a **fixture** task folder in a scratch tree that mimics the repository layout (the script
derives its root from its own location, `archive-task.sh:27`), running a **copy** of the candidate
script. `docs/features/**` and `.harness/insight-index.md` of this repository are touched by exactly
one archive run: this task's own, at delivery.

**BC-9** — Fixture trees are created and removed inside the repository working tree at an untracked
path, so no cleanup requires the destructive-command override, and none of them appears in the
committed diff (AC-14).

**BC-10** — `verify_all.sh` is invoked from the repository root; a run from any subdirectory
self-reports a false red (insight index, 2026-08-15). Any reported count from elsewhere is void.

**BC-11** — If stage 2 finds that FR-5's property cannot be met without new machinery, the record
degrades to the smallest artifact that still carries, per fix, the loss consequence and the check
named in FR-5; a harness linter, a digest gate or a CI job is not adopted to satisfy FR-5.

**BC-12** — If routing this task's own later stages through FR-6's new section produces a unit with
two destinations or none, the section is corrected in place before delivery; the first consumer of
the new section is this task's stages 5 and 6.

**BC-13** — The replacement text FR-5's checks are run against is version-specific → each check is
stated so a reader applies it to whatever text a future refresh brings, and every stage that runs one
names the version it measured (today: harness-kit **0.47.0**'s
`skills/harness-init/templates/common/.harness/scripts/archive-task.sh`, 425 lines, resolved through
`upgrade-project.sh:56`). A later version that changes a verdict is a residual, not a criterion
failure; a record that hard-codes today's verdicts as standing fact fails FR-5.

## Acceptance criteria

Every criterion is verified from the repository root, against a fixture tree per BC-8, never against
the live host, the installed `sc`, or a real task folder.

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | A fixture index of 8 header lines + 22 entries (30 lines, the shape of the real one) plus 3 harvested insights ends the run at **≤30 lines** by `wc -l`, with exactly 3 entries appended to `insight-history.md`. | [B] | One fixture run; `wc -l` before and after, plus the history file's diff. **HEAD rotates nothing (22+3 = 25 ≤ 30 bullets) and leaves 33 lines — F.4 WARNs. HEAD fails.** |
| AC-2 | On the same run, (rotated ∥ remaining) equals (pre-existing ∥ harvested) byte for byte and in order, the rotated entries are the **oldest**, and the header's 8 lines are byte-identical. | [B] | Byte comparison of the three files' entry sequences. **Control, not discriminating: HEAD loses nothing because it rotates nothing.** It is what a candidate rotating the newest, reflowing, or dropping the header fails. |
| AC-3 | A fixture index of 25 lines with 2 harvested insights rotates nothing, creates no `insight-history.md`, and ends byte-identical to the old file plus two appended lines. | [B] | One fixture run; file existence + byte compare. **Control, not discriminating: HEAD passes.** It is what a candidate rotating unconditionally fails. |
| AC-4 | A fixture index at exactly 30 lines with 0 harvested insights leaves both files byte-identical. | [B] | One fixture run; sha256 before/after. **Control, not discriminating.** |
| AC-5 | Two over-cap fixtures whose header alone reaches the cap — one with 2 entries, one **header-only** where the clamp reduces the rotation to zero — each end the run with a report line stating a residual over-cap **number equal to `wc -l` of the resulting index minus 30**, with no header line and no harvested entry deleted and at most the entries present rotated. The residual prints on the clamp, including when nothing is rotated. | [B] | Two fixture runs; compute `wc -l` of each resulting index minus 30 and compare it digit for digit against the number the report states; diff header and harvested lines. **HEAD prints no residual line at all — no such `echo` exists in the file — and rotates nothing. HEAD fails both runs.** |
| AC-6 | A `## Insight` bullet wrapped across three lines, its `· evidence: <slug>` tag on the last, is harvested as one index line carrying the tag. | [B] | One fixture run; grep the resulting index line. **Control, not discriminating: HEAD passes** — it pins the local fix at `:51-71` against regression (FR-4). |
| AC-7 | `--dry-run` over the AC-1 fixture writes zero bytes anywhere in the fixture tree and its report states a rotation count of **3** — the absolute number, equal to the rotation the AC-1 wet run is measured performing on that same fixture. The dry-run report is measured on **HEAD** and on the candidate over that one fixture and both are quoted; if the two report the same string, AC-7 is recorded **NOT-DISCRIMINATING**, never passed. | [B] | Full-tree snapshot (existence, size, mtime, sha256) plus a positive control proving the snapshot detects a write; both report lines quoted verbatim. **HEAD reports `Rotated 0` on that fixture. HEAD fails.** |
| AC-8 | `git diff` for `.harness/scripts/verify_all.sh` is empty, F.4 still tests `wc -l > 30`, and `bash .harness/scripts/verify_all.sh` from the repository root reports **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**. | [S]+[B] | Diff read + one full run. **Control by construction; it is what a candidate that fixed F.4 instead of the script fails (OQ-5).** |
| AC-9 | Two clauses. **(a)** Every unit of two real archived stage-document pairs — T-26's `01_REQUIREMENT_ANALYSIS.md` + `01_RATIONALE.md` and T-19's `02_SOLUTION_DESIGN.md` + `02_RATIONALE.md` — routes through the new section to exactly one destination: zero units with none, zero with two. **(b)** Each unit kind FR-6(c) names is tabulated with an archived instance of that kind cited by path and line, and the section routes the kind to the portion — contract or rationale — that instance actually occupied; where two archived instances of one kind occupy different portions, the instance in the **most recently delivered** task decides and the divergence is recorded. A kind whose routing contradicts its witness is a finding that corrects the section in place before it ships (BC-12); a kind with no citable archived instance is removed from the section and from FR-6(c). **If clause (b) passes on a section text carrying only FR-6(a)'s test, the per-kind list is removed and the test alone ships.** | [S] | Hand-route both document pairs and count; tabulate every FR-6(c) kind against its cited witness. **HEAD has no such section: every unit has zero destinations and no kind has a routing. HEAD fails.** |
| AC-10 | `.harness/rules/70-doc-size.md` is ≤130 lines, every rule fragment is ≤200 lines (F.2 PASS), and `AI-GUIDE.md` indexes every fragment (E.5 PASS). | [S] | `wc -l` + the two verify_all checks. **Control, not discriminating.** |
| AC-11 | For each of the three most recently delivered tasks, every path in its delivery commit falls into either that task's own product file list or the shared list — with no path in neither. | [S] | `git log --name-only` for the three commits, partitioned against the list. **HEAD's only instance of the list is T-19's prose (`ruleset-staleness-visibility/01_REQUIREMENT_ANALYSIS.md:149`), under which `docs/batches/BATCH_PLAN.md` and `BATCH_LOG.md` fall in neither list. HEAD fails.** |
| AC-12 | The list's home is a rule fragment whose "when to read" trigger fires when a stage writes a criterion over the committed diff, and `AI-GUIDE.md`'s index line for that fragment states the same trigger. | [S] | Read both lines. **HEAD's rule 80 trigger is delivery-time only, and the list does not exist there. HEAD fails.** |
| AC-13 | Over a **read-only copy of the exact text a `/harness-upgrade` would copy over `.harness/scripts/archive-task.sh`** — resolved through `upgrade-project.sh`'s template source and reported by version and path (BC-13) — each fix FR-5's record names is resolved **from that record alone**: its stated check is run against that text, yields the verdict *already provided* or *lost*, and the action the record states for that verdict is performed. The resulting script then leaves the AC-1 fixture's index at **≤30 lines** by `wc -l` and delivers the AC-6 fixture's wrapped bullet — continuation text and trailing `· evidence:` tag — into the index. No step of the drill opens the vendored file's in-file note or re-derives either defect. | [B] | Copy the template text into the fixture tree; quote each check, each verdict and each action taken; re-run the AC-1 and AC-6 fixtures against the resulting script. **HEAD's only record is the in-file comment at `archive-task.sh:51-56`, which the replacement deletes — the drill has nothing to start from. HEAD fails.** |
| AC-14 | **Product diff** — the committed diff changes only `.harness/scripts/archive-task.sh`, `.harness/rules/70-doc-size.md`, the fragment hosting FR-8's list, and `AI-GUIDE.md`'s index line for that fragment; `bin/sc`, `install.sh`, `uninstall.sh`, both READMEs, `CHANGELOG.md`, `verify_all.{sh,ps1}`, `guard-rm.{sh,ps1}`, `archive-task.ps1` and everything under `.claude/` appear **nowhere**. **Delivery-time writes** — additionally only `docs/tasks.md`, `docs/tasks-archive.md`, `.harness/insight-index.md`, `docs/features/_archived/insight-history.md`, `.harness/rejected-decisions.md`, `CONTEXT.md`, **`docs/batches/**`** and this task's stage documents at their delivered path; these are not part of the product diff. A path in neither list is a failure. **This criterion carries the `docs/batches/**` carve-out that R-36 is about, and is written that way deliberately.** No fixture artifact is committed. | [S] | `git status` + `git diff --name-only` partitioned against the two lists at delivery. |
| AC-15 | This task's own delivery-time archive run needs **no** hand-rotation: it harvests ≥1 insight, leaves `.harness/insight-index.md` at ≤30 lines, and the sha256 of the index and of `insight-history.md` taken immediately after the script exits equals the staged content at `git add`. | [B] | Run the script once at delivery; record both digests then and at staging; report the pair. **Sixteen consecutive deliveries needed a hand-rotation at HEAD; a run that harvests nothing fails the first clause.** |
| AC-16 | The `archive-task.sh` change is a change of metric, not of algorithm: no new function, no new file, no new invocation per entry, and the rotation branch's structure, report lines and exit behaviour are otherwise unchanged. | [S] | Read the diff; count added lines and shell functions before and after. **HEAD passes; this pins the size bar against a rewrite.** |

## Non-functional requirements

1. Size bar, against the three most recent deliveries (T-26 net-negative on one of four rows, T-25
   `+80/−41` with no new function, T-24 `+79/−55`): the `archive-task.sh` change stays in single-digit
   added lines, the new rule-70 section stays ≤35 lines, and FR-8's list plus its citation rule stays
   ≤15 lines. Anything larger carries the burden of proof under `.harness/rules/85-design-discipline.md`.
2. The whole task adds zero executable artifacts: no new script, no new hook, no new gate, no new rule
   fragment, and no new step in `verify_all`.
3. `archive-task.sh`'s run cost stays of the same order — at most one additional whole-file
   measurement per run, never a per-entry subprocess.
4. Every document this task writes or edits is English, per `.harness/rules/00-core.md`.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| OQ-1 | Is `guard-rm.sh` in scope — the eleven blocked `git commit` / `cat` / `python3` heredocs that contain no `rm`? | **Out of scope, both its decision and its message, and it is not a fourth instance of this task's class.** Four reasons, in order. (1) **It is documented behaviour, not a defect**: `.harness/rules/75-safety-hook.md:86` already lists "Parse failure on nested pwsh / **unbalanced quotes** → BLOCK with explicit *could not parse …* message", with the remedy "re-issue without the nested quoting". The mechanism is `tokenize`'s unbalanced-quote return (`guard-rm.sh:114`) reached at `:206`, which sets the same `parse_failed` flag as the two genuine pwsh causes (`:205`, `:234`) — a heredoc body carrying one apostrophe is tokenized as shell words and trips it. (2) **Risk class**: R-18, R-36 and R-37 cannot make anything less safe; every fix here can only make the guard permit more, in the one artifact whose job is to refuse. (3) **Measured cost is one flag**: `git commit -F <file>` leaves no residue in the product, and eleven of eleven tasks took it while the bypass was never set — so the message has not in fact mis-steered anyone. (4) A correct fix means real shell tokenization — heredocs, command substitution, escapes — which is exactly the meta-tooling this task is forbidden to build. Filed with two unblock paths: a message-only correction inside whichever task next edits that file, or a scoped safety-hook row that adds a destructive-verb pre-filter with adversarial tests. |
| OQ-2 | Are the absent `task-state.js` / `entropy-cadence` a fourth instance of "the harness assumes assets it does not have"? | **No, and out of scope.** R-18/R-36/R-37 are artifacts **present in this repository** that state something false and are worked around by hand every delivery; these two are **plugin-owned artifacts that are simply absent**, with a documented fail-open path that costs no hand-work and produces no wrong result — the PM records two lines and proceeds. This repository cannot fix them: a local `task-state.js` or cadence tool is new machinery that the framework owns and that `/harness-upgrade` would collide with, i.e. precisely the meta-tooling ban. Filed with the standing consequence stated rather than hidden: the delivery-time entropy watch resolves NOT-DUE on this project indefinitely. Unblock path is an owner/PM action — re-run `/harness-upgrade` or raise it with harness-kit — not a task. |
| OQ-3 | Where must the corrected committed-diff path list live so a future task actually inherits it? | **In `.harness/rules/80-delivery-policy.md`**, as a list of paths the pipeline writes as process rather than as product, plus one sentence binding a committed-diff criterion to cite it rather than re-transcribe it. It is the only existing fragment whose subject is what a delivery commit contains; it needs one clause added to its "when to read" trigger (and the matching `AI-GUIDE.md` index line) because the criterion is written at stage 1 while the fragment is read at stage 7. The three rejected homes and the argument are in `01_RATIONALE.md`. Stage 2 may place it elsewhere only by satisfying every clause of FR-8 and stating why; a **new** fragment is not an option (rule 85, and E.5's index duty). |
| OQ-4 | Do `archive-task.ps1` and `guard-rm.ps1` get the same fix? | **No — the `.sh` alone is edited, and the divergence is stated rather than hidden.** `archive-task.ps1:71/:76` carries the identical bullets-against-30 defect, and it is equally dead there. Editing it would **activate an untested write path on a platform no one here can run** — a rotation branch that moves and rewrites files, verified by nobody — which is a worse outcome than a known-dead branch on a platform this project never targets (a Linux CLI with a Bash installer). The mirror divergence joins R-6's existing record of `verify_all.{sh,ps1}` drift; AC-14 pins the `.ps1` files as untouched. |
| OQ-5 | The metrics disagree — is the script wrong, or is F.4? | **The script.** The cap is stated in **lines** by both documents that define it: `.harness/rules/70-doc-size.md:26` ("`.harness/insight-index.md` | 30 lines") and `.harness/rules/05-insight-index.md:5,29,48` ("a ≤30-line append-only file", "Maximum 30 lines total", "if it exceeds 30 lines, rotates the oldest"). F.4 (`verify_all.sh:213-219`) implements exactly that; `archive-task.sh:89-94` counts `grep '^\s*-\s'` bullets, which differ from lines by the header (today 8), and is the sole deviant. Changing F.4 or either rule to match the script would be weakening a check to make a defect pass, which this task's constraints forbid outright; AC-8 pins it. |
| OQ-6 | What must hold after the next `/harness-upgrade`, given the file is plugin-vendored and already carries two local fixes? | **The property is FR-5, and the mechanism is stage 2's.** Ruled against the artifact the refresh actually copies, read first-hand: `upgrade-project.sh:56` resolves it to `…/harness-kit/0.47.0/skills/harness-init/templates/common/.harness/scripts/archive-task.sh`, a **425-line rewrite** that already harvests wrapped bullets as multi-line entries (`:299-303`), already clamps `rotate_count` (`:340`), already emits the header from a scanned range (`:386-395`) and already guards the missing-index `touch` with an `if` (`:364-366`) — while still deciding rotation on **entries** (`:333`) against an F.4 that caps lines. So the refresh is a **replacement, not a two-hunk revert**, and binding is: (a) the record lives **outside** the vendored file — a comment inside it is deleted by the event it warns about, the current arrangement at `:51-56`; (b) it states per fix a check the reader runs against whatever text the refresh brought, because whether a fix is still needed is a property of that text, not of this repository; (c) it states the action for each verdict, and never one that discards the replacement wholesale as its only path. Not binding, and not adopted without proving the cheaper route fails: any digest gate, vendored-file checker, `verify_all` step or CI job (BC-11). Where a verdict calls for re-application, that is a bounded edit guided by the record's stated metric — not a re-diagnosis, and not a promise of a transcribable patch. |
| OQ-7 | `.harness/rules/05-insight-index.md:47` says archiving compresses the stage documents into `summary.md`; `archive-task.sh:129-132` only moves the directory. Is that in scope? | **No — filed, not fixed.** It is untrue, but no task has paid hand-work for it and no wrong result follows: nothing reads a `summary.md`. This task's inclusion line is *defects that cost hand-work or produce a wrong artifact every delivery*; a merely inaccurate sentence in a fragment nobody acts on does not clear it, and clearing it here would put a third rule fragment in the diff for zero recovered cost. Filed for whichever task next edits rule 05. |
| OQ-8 | This task's own stage documents are written **under** the gap FR-6 closes. Where do their unroutable units go? | Into `01_RATIONALE.md` and its siblings, the destination the agent contracts already name, exactly as T-19's five stages and T-26's OQ-11 did — and this row is the seventeenth recorded confirmation of R-37 rather than an invented section. Once FR-6 lands mid-task, this task's stages 5 and 6 route by the new section and are its first consumers (BC-12). |
| OQ-9 | Fixtures must not archive a real task — where do they live, given the destructive-command guard? | **Inside the repository working tree, at an untracked path, removed there or left in place.** The guard blocks a destructive verb resolving outside the nearest `.git/` ancestor, so a fixture built under a system temp directory cannot be cleaned up without the override that OQ-1 keeps unset. BC-8 and BC-9 bind this; AC-14 checks that nothing from a fixture is committed. |
| OQ-10 | What exactly is "the committed-diff AC template" that R-36 says is broken — a file? | **Prose, instantiated per task, existing only inside archived stage documents** (the instance is `docs/features/_archived/ruleset-staleness-visibility/01_REQUIREMENT_ANALYSIS.md:149`). Therefore the fix is **not** a template artifact: no template file, no snippet library, no generator. What moves out of the prose is the one part that is identical in every instance and that drifted — the ledger path list — plus the rule that a criterion cites it. The product-file half stays per task, because it is per task. |
| OQ-11 | Is **taking the upstream refresh** — adopting harness-kit 0.47.0's 425-line `archive-task.sh` rewrite, in whole or in part — in scope for T-27, or a separate row? | **Out of scope here; filed as its own row.** Four reasons, in order. (1) **It does not fix this task's defect**: the rewrite still decides rotation on entries (`0.47.0:313`, `:333`) against an F.4 that caps lines, and there one entry may occupy several index lines — so the entries-vs-lines divergence is *wider* after adoption, and the metric edit still has to be made, now on 425 unfamiliar lines. (2) **It replaces the program every criterion of this task measures**: different report strings (`Insight tally: …`, `Rotating N old insight entry(ies)`), an exit-3 refusal path, multi-line entries, so AC-1…AC-7 and AC-16 would each be re-derived, and both AC-16's "change of metric, not of algorithm" bar and NFR-1's single-digit executable diff are destroyed rather than argued. (3) **The mechanism cannot be taken selectively**: `/harness-upgrade` refreshes `archive-task.ps1` from the same `refresh_set` (`upgrade-project.sh:189`), which OQ-4 froze and AC-14 pins as appearing nowhere; hand-copying only the `.sh` is not "taking the refresh" but vendoring a second upstream file by hand, unreviewed. (4) It is an owner/PM action that changes the harness under a running pipeline. **Not among the reasons**: NFR-2's no-meta-tooling bar — adopting a vendored upstream file builds no machinery and that bar does not reach it; and not "the rewrite is worse", because four of its behaviours are better than the vendored file's. Filed as a pool row — *adopt harness-kit's `archive-task.sh` rewrite* — carrying RS-6's upstream report, the 425-line review, the `.ps1` mirror question and a re-derivation of AC-1…AC-7. Until that row runs, FR-5's record is what makes the refresh survivable, which is exactly why it is not weakened here. |

## Verdict

READY
