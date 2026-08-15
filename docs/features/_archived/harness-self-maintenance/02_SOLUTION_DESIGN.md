# 02 — Solution Design · T-27 `harness-self-maintenance`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

1. Three defects, three **data** edits and no machinery: `archive-task.sh` stops counting bullets and
   takes `verify_all` F.4's own measurement (`wc -l` of the index); `.harness/rules/70-doc-size.md`
   gains the `## Stage-doc boundary rule` section every agent contract already cites by name; and
   `.harness/rules/80-delivery-policy.md` gains the process-path list a committed-diff criterion
   cites instead of re-transcribing, plus the vendored-fix record FR-5 asks for. Eight added shell
   lines, one rule section, two rule blocks.
2. Unchanged: `verify_all.{sh,ps1}` (F.4 byte-identical), `guard-rm.*`, `archive-task.ps1`, the harvest
   `awk` at `archive-task.sh:44-77`, the rotation body and rewrite at `:105-132`, the report lines, the
   30-line cap, `bin/sc`, both READMEs, `CHANGELOG.md`, everything under `.claude/`, `docs/dev-map.md`,
   `.harness/rules/05-insight-index.md`, `check-i18n-parity.sh`. The vendored 151-line script is the
   text this delivery edits and runs; harness-kit 0.47.0's 425-line rewrite is not adopted here
   (out-of-scope 10, OQ-11).
3. The seams are existing ones. **Metric seam:** the cap has exactly one measurement — the file's line
   count — and after E-1 both the check that enforces it and the script that acts on it take that same
   measurement with the same tool. **Durability seam:** the record of each local fix lives outside the
   vendored file and carries a *check the reader runs against whatever text a refresh brings* plus an
   action per verdict — so a replacement that already provides a fix is **kept**, and only a fix that
   arriving text lost is re-applied.

## Change ledger

| id | path | new/edit | what changes | partition |
|---|---|---|---|---|
| E-1 | `/home/alan/Programs/singbox-cli/.harness/scripts/archive-task.sh` | edit | **Metric.** Replaces `:92`, `:94` and `:95`. `index_lines` ← one `wc -l < "$insight_index"` guarded by `[[ -f ]]` (0 when absent), taken **before** the write phase and never after a `touch` (PQ-3); `total_after = index_lines + ${#harvested[@]}`; `rotate_count` ← `total_after - 30` when positive, then clamped to `${#current[@]}` on a single line that also prints the residual over-cap (PQ-2); the existing branch head becomes `if (( rotate_count > 0 )); then`, keeping its `elif` and everything below it — oldest-first selection, history append, header + remaining + harvested rewrite, report lines — untouched. Discharges FR-1, FR-3, BC-2…BC-7, AC-1…AC-5, AC-7, AC-16. Est. **+7 / −3**. | single-dev |
| E-1b | `/home/alan/Programs/singbox-cli/.harness/scripts/archive-task.sh` | edit (**unconditional**, C-1) | `:82`'s `[[ "$DRY_RUN" == false ]] && touch "$insight_index"` becomes a **single-line** `if … ; then … ; fi` (one line replaced by one line, so the executable diff stays single-digit). Under `set -e` the AND-list returns 1 when the test fails, aborting a `--dry-run` run whose index is absent — the BC-1 × BC-7 intersection E-1's own measurement sits on, and the only instance of the form K-4 bans. It lands whatever V-2b observes; V-2b is a **measurement that is reported**, not a gate. Discharges FR-3, BC-1, BC-7. Est. **+1 / −1**. | single-dev |
| E-2 | `/home/alan/Programs/singbox-cli/.harness/rules/70-doc-size.md` | edit | Adds the `## Stage-doc boundary rule` section (B-1's exact text, **18 lines**) after `### Rule 4 — Always archive completed tasks` and before `## Adversarial check`; adds one `## When to read this` bullet; rewrites the `.harness/insight-index.md` caps-table cell in place (no line added) to name the metric and to point at rule 80's vendored-fix record when F.4 still WARNs after an archive run. Discharges FR-6, FR-7, AC-9, AC-10, BC-12. Est. **+20 / −1**; file 91 → ~111 lines (AC-10 bar: ≤130). | single-dev |
| E-3 | `/home/alan/Programs/singbox-cli/.harness/rules/80-delivery-policy.md` | edit | Adds `## Process paths — what the pipeline writes about its own work` (B-2's exact text, **13 lines**) after `## The policy`; adds `## Local fixes to plugin-vendored scripts` (B-3's exact text, **14 lines**) before `## Reporting`; adds one trigger line to `## When to read`. Discharges FR-5, FR-8, FR-9, FR-10, AC-11, AC-12, AC-13, BC-11, BC-13. Est. **+30 / −0**; file 53 → ~83 lines (F.2 bar: ≤200). | single-dev |
| E-4 | `/home/alan/Programs/singbox-cli/AI-GUIDE.md` | edit | Line 30, the rule-80 index line, restated so its trigger is word-for-word the one E-3 writes into rule 80 and its description names both new sections. Discharges FR-8, AC-12. One line replaced. Est. **+1 / −1**. | single-dev |
| E-5 | — | — | **Schema-gap row, not a file** (B-1's own final clause, applied to this document): the architect contract declares no shape for the **FR/BC/AC → edit coverage mapping**, and `.harness/rules/70-doc-size.md` declares no boundary rule at HEAD — this is R-37, the defect E-2 fixes. The unit is **not** given an invented section: the requirement→edit half is carried in this ledger's `what changes` cells and in `## Constraints`, and the requirement→verification half in `## Verification plan`'s fourth column. Round-1's three invented H2 sections (`## Durability ruling`, `## Requirement coverage`, `## Projected size`) are **removed** for the same reason; `## Smaller alternative rejected` stays because `.harness/rules/85-design-discipline.md:41` names it in this document by name, which is B-1's precedence clause, and `## Byte-form specification` is a declared section of the architect contract. | — |
| E-6 | — | — | **Not edited, deliberately:** `archive-task.ps1` (OQ-4), `.harness/rules/05-insight-index.md:47` (OQ-7), `guard-rm.sh` (OQ-1), `CONTEXT.md` (the new vocabulary is harness vocabulary, not product domain — `01_RATIONALE.md:94-96`), `.harness/rejected-decisions.md` and `.harness/operator-obligations.md` (PM writes at delivery, not product diff). Discharges FR-11, AC-8, AC-14 together with the frozen set. | — |

Total product diff ≈ **+59 / −6**, of which **8 added lines are executable** (E-1's 7 plus E-1b's 1),
inside NFR-1's single-digit bar; the rest is the policy text FR-6 and FR-8 require, inside NFR-1's
≤35 (B-1 = 18) and ≤15 (B-2 = 13) budgets.

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `archive-task.sh` rotation decision (replaces `:92`, `:94`, `:95`) | `index_lines` ← one `wc -l < "$insight_index"` when the file exists, else 0; `total_after = index_lines + ${#harvested[@]}`; `rotate_count = max(total_after - 30, 0)`, then clamped to `${#current[@]}`; the rotation branch head is `(( rotate_count > 0 ))` | The decision is taken with **the same tool on the same file** `verify_all` F.4 uses (`verify_all.sh:213-219`), and exactly one whole-file measurement is taken per run, never one per entry (NFR-3). The decision's number and the rewritten file's line count agree **iff the index ends with a newline and holds at least one non-bullet line** — the two conditions under which the frozen rewrite at `:113-119` re-emits the pre-existing content one line for one line. Outside that condition it emits one line more than the decision counted: an index whose last line carries no trailing newline (`wc -l` undercounts by one; `echo` restores it) and an index with **zero** non-bullet lines (`echo "$header"` writes an empty line where none existed) each end the run at 31 lines and F.4 WARN. Both shapes are measured by V-16 and **reported as residuals against FR-1** — never repaired by a hand edit and never by touching `:105-132` (AC-16, NFR-1). |
| I-2 | `archive-task.sh` over-cap report line | one `echo` on stdout, on the **clamp** condition, stating how many lines remain above 30 after rotating every entry present | Printed whenever the clamp fires, **including when the clamp reduces `rotate_count` to zero** (a header-only index over the cap), because then it is the run's only signal that the file is over the cap (PQ-2). The number it states equals `wc -l` of the resulting index minus 30 (AC-5). It is an added report line, not a changed one: `Rotating N old insight(s)`, `[DRY RUN] …`, `Archived task: …`, `Insights:` and `Rotated:` keep their text and their order (AC-16). |
| I-3 | `.harness/rules/70-doc-size.md` `## Stage-doc boundary rule` | H2 section, exact text in B-1 (18 lines), placed after `### Rule 4 — Always archive completed tasks` and before `## Adversarial check` | The heading is spelled exactly as every framework agent contract cites it. It names exactly two destinations (`0N_*.md`, `0N_RATIONALE.md`) and creates no third document kind (FR-7). It carries FR-6's four parts — the test (a), the precedence clause (b), the two-destinations sentence, and the schema-gap answer (d) — and **no per-kind list**: AC-9(b)'s final clause removes it (see `02_RATIONALE.md` `## AC-9(b) — every FR-6(c) kind against its witness`). |
| I-4 | `.harness/rules/80-delivery-policy.md` `## Process paths — what the pipeline writes about its own work` | H2 section, exact text in B-2 (13 lines): a 5-bullet path list + one binding sentence | The list is the **process** half only; a criterion enumerates its own product files itself. `docs/dev-map.md` is deliberately absent (it documents the code, so it is a product file — T-19 shipped it as one). `docs/batches/**` is present; its absence is R-36. `insight-history.md` is covered by the `docs/features/_archived/**` bullet and gets no line of its own. |
| I-5 | `.harness/rules/80-delivery-policy.md` `## Local fixes to plugin-vendored scripts` | H2 section, exact text in B-3 (14 lines): one paragraph naming `upgrade-project.sh:186-227` and the standing instruction *keep what arrives*, plus a 5-column table — fix · observable it restores and how its loss shows · check to run against the arriving text · action on *already provided* · action on *lost* | The record is resolvable **from its own bytes**: no step needs the in-file note the replacement deletes, and no step re-diagnoses either defect (AC-13). It states **checks, not verdicts** — it names no version and asserts nothing about what any particular template already does, so it stays true across refreshes and whoever runs a check names the version they measured (BC-13). No action discards the arriving text: the metric row's *lost* action is a bounded edit onto that text, stated as the metric it must reach rather than as a patch to transcribe (FR-5, OQ-6). |
| I-6 | `AI-GUIDE.md:30` rule-80 index line | one line: trigger parenthetical + description | The trigger parenthetical is word-for-word the trigger E-3 writes into rule 80's `## When to read` (AC-12), and the description names the process-path list and the vendored-fix record. E.5 stays PASS: one fragment, one index line, no fragment added. |

## Constraints

**K-1** — The implementer decides rotation on the index's line count taken by a single
`wc -l < "$insight_index"` behind `[[ -f ]]`, before the write phase, and adds no per-entry
subprocess, no new function, no new file and no second measurement (FR-1, NFR-2, NFR-3, AC-16, PQ-3).

**K-2** — The implementer clamps `rotate_count` to `${#current[@]}` and prints the residual over-cap
**on the clamp condition**, so it still prints when the clamp reduces the count to zero; no header
line and no harvested entry is ever deleted or reflowed to reach the cap (BC-5, AC-5, PQ-2).

**K-3** — The implementer enters the rotation branch only when `rotate_count > 0`, so a run that
cannot rotate anything still appends its harvested entries through the existing `elif` and creates no
`insight-history.md` (BC-2, BC-5, AC-3).

**K-4** — The implementer writes no bare `[[ … ]] && cmd` as a standalone statement in this
`set -euo pipefail` script; every added conditional is an `if … fi` (the `:82` hazard E-1b removes).

**K-5** — The implementer does not touch `archive-task.sh:44-77` (the harvest step, including the
local `awk` join) or `:105-132` (history append, index rewrite, `mv`), and adds no line between them
other than those K-1/K-2/K-3 require (FR-4, AC-6, AC-16).

**K-6** — The implementer does not edit `.harness/scripts/verify_all.sh` or `.ps1`,
`.harness/scripts/guard-rm.*`, `.harness/scripts/archive-task.ps1`, `bin/sc`, `install.sh`,
`uninstall.sh`, either `README`, `CHANGELOG.md`, or anything under `.claude/` (FR-11, AC-8, AC-14).

**K-7** — The implementer keeps `.harness/rules/70-doc-size.md` at ≤130 lines and every rule fragment
at ≤200, and adds **no** rule fragment (AC-10, NFR-2, E.5).

**K-8** — The implementer builds every fixture under `/home/alan/Programs/singbox-cli/test/t27/` — a
path `.gitignore:19` already ignores, inside the working tree, so cleanup needs no destructive-command
override — and never runs the script against `docs/features/**` or `.harness/insight-index.md` of this
repository before delivery (BC-8, BC-9, OQ-9, C-9; precedent `test/t20/.head-clone`).

**K-9** — The implementer runs a **copy** of the candidate script from inside each fixture tree
(`test/t27/<case>/.harness/scripts/archive-task.sh`), because the script derives its root from its own
location (`archive-task.sh:27`); a run of the repository's own copy with a fixture argument would
rotate the repository's index (BC-8, PQ-4).

**K-10** — The implementer invokes `.harness/scripts/verify_all.sh` only from the repository root; a
count reported from a subdirectory is void (BC-10, insight 2026-08-15, C-8).

**K-11** — The implementer performs no service action, writes nothing under `/etc/sing-box` or
`/var/lib/sing-box`, installs nothing over `/usr/local/bin/sc`, and imports `bin/sc` nowhere in this
task — there is no reason to load it at all (R-78; out-of-scope 9).

**K-12** — The implementer copies B-1, B-2 and B-3 verbatim into their target files; policy wording is
not the implementer's to improvise. Placement, and only placement, is stated in the ledger.

**K-13** — The implementer adds no mechanism that detects, pins or reverses a plugin refresh: no
digest, no stored copy, no `verify_all` step, no hook, no CI job. FR-5 is discharged by B-3's bytes
alone (BC-11, NFR-2).

**K-14** — The implementer does not run `/harness-upgrade` during this task and copies no part of
harness-kit 0.47.0's 425-line `archive-task.sh` into `.harness/scripts/archive-task.sh`. That template
is opened **read-only**, inside `test/t27/`, for V-12 only (out-of-scope 10, OQ-11).

## Byte-form specification

The gate columns are kept and answered honestly: **at HEAD this project's rule 70 has no numbered
boundary-rule rows at all** — that absence is R-37, the defect E-2 fixes. The rows below are therefore
admitted under the clause E-2 itself installs, cited as `(a)` (the binding test), with the test result
stated. All three artifacts are **policy text a later stage must install verbatim** — they exist
nowhere to cite, so rule 70's "reference, don't paste" (which governs *code citations* and caps *raw
evidence* at 5 lines) does not reach them.

| id | artifact | exact byte-form | boundary-rule row matched | test result |
|---|---|---|---|---|
| B-1 | the `## Stage-doc boundary rule` section of `.harness/rules/70-doc-size.md` | the fenced block below, 18 lines, copied verbatim | E-2 clause (a) | binding — stages 1-7 must satisfy it; a paraphrase would be a different rule → contract |
| B-2 | the `## Process paths …` section of `.harness/rules/80-delivery-policy.md` | the fenced block below, 13 lines, copied verbatim | E-2 clause (a) | binding — every future committed-diff criterion partitions against these exact paths → contract |
| B-3 | the `## Local fixes to plugin-vendored scripts` section of `.harness/rules/80-delivery-policy.md` | the fenced block below, 14 lines, copied verbatim | E-2 clause (a) | binding — AC-13 runs each check and each action out of these bytes alone → contract |

**B-1** (`.harness/rules/70-doc-size.md`, after `### Rule 4`, before `## Adversarial check`):

```markdown
## Stage-doc boundary rule

Every unit a stage produces has **exactly one** destination. One test decides it:

> **Does a later stage have to satisfy, implement or verify this unit?**
> Yes → the contract portion `0N_*.md`. No — it explains, justifies, measures, compares or
> records how the unit was reached → its sibling `0N_RATIONALE.md`.

Those two are the only destinations: this rule creates no third document kind.

**Precedence.** When another rule or an agent contract names a section of a stage doc — or names
the destination for a kind of unit — *by name*, that naming decides where it lives, and the test
above decides only what the naming does not cover.

**A unit that fits no declared shape of its stage doc** is recorded as a **schema-gap row** — in
stage 2's change ledger, or in the stage's own findings/residuals table — naming the unit and the
destination it was given instead. Never invent a section for it and never open a new file: a gap
is reported, not designed around.
```

**B-2** (`.harness/rules/80-delivery-policy.md`, after `## The policy`):

```markdown
## Process paths — what the pipeline writes about its own work

Every delivery commit carries some of these. They are **not** product files (`docs/dev-map.md` is:
it documents the code):

- `docs/tasks.md`, `docs/tasks-archive.md` — the task board and its archive
- `docs/features/<slug>/**`, `docs/features/_archived/**` — stage documents, `PM_LOG.md`, insight history
- `docs/batches/**` — the batch loop's plan, log and report
- `.harness/insight-index.md`
- `.harness/rejected-decisions.md`, `.harness/operator-obligations.md`, `CONTEXT.md`

**A criterion over the committed diff enumerates its own product files, cites this list for the
rest, and never re-transcribes it; a path in neither list is a failure of that criterion.**
```

**B-3** (`.harness/rules/80-delivery-policy.md`, before `## Reporting`):

```markdown
## Local fixes to plugin-vendored scripts

`/harness-upgrade` **replaces** every vendored script that differs from the plugin's current
template with that template (`.harness/scripts/upgrade-project.sh:186-227`) — no marker
preservation, no backup — so a note *inside* such a file dies with the fix it describes, and what
arrives is a text of the plugin's choosing, not a revert of the local hunks. **Keep what arrives.**
For each fix below, run its check against the arriving text and take the action for the verdict it
gives, naming the version measured: a verdict is a property of that text, not a standing fact.
`git log -p -- <path>` holds the pre-replacement text when an action needs it.

| `.harness/scripts/archive-task.sh` fix | observable it restores · how its loss shows | check to run against the arriving text | *already provided* | *lost* |
|---|---|---|---|---|
| rotation decided on the index's **line** count | an archive run leaves `verify_all` F.4 PASS with no hand edit · **loud**: the index passes 30 lines and F.4 WARNs after every archive run | archive a fixture whose index is at the cap with ≥1 harvested insight, then `wc -l` the resulting index | ≤30 → change nothing | >30 → make the rotation decision read `wc -l` of the index — F.4's own measurement, `verify_all.sh:213-219` — instead of whatever it counts, and rotate until the file it writes is ≤30 lines |
| the harvest carries a wrapped bullet whole | a `## Insight` bullet wrapped over several lines reaches the index with its continuation text and its trailing `· evidence: <slug>` tag · **silent**: entries truncate mid-sentence and lose the tag | archive a fixture whose `## Insight` bullet wraps over three lines with the tag on the last, then read what it wrote | continuation text and tag both present → change nothing | truncated or tag missing → restore the join inside the arriving text's own harvest step |
```

The trigger line E-3 adds to rule 80's `## When to read`, and E-4 mirrors into `AI-GUIDE.md:30`:
*"Read also **when writing an acceptance criterion over the committed diff** (stages 1-2) — for the
process-path list below — and **after `/harness-upgrade`**, for the vendored-script fixes below."*

## Frozen set

| path | why frozen |
|---|---|
| `.harness/scripts/verify_all.sh` `:213-219` and the whole file | AC-8: F.4's metric and its 30 stay byte-identical; OQ-5 ruled the script the deviant. |
| `.harness/scripts/verify_all.ps1` | Mirror of a file that is not edited. |
| `.harness/scripts/archive-task.sh` `:44-77`, `:105-132` | FR-4/AC-6 (the local `awk` join) and AC-16 (rotation body, rewrite, report, `mv` untouched). The two divergence shapes I-1 names are **reported**, not fixed here — fixing them means editing `:113-119`, which is an algorithm change (AC-16) and a second-digit diff (NFR-1). |
| `.harness/scripts/archive-task.ps1` | OQ-4: editing it activates an untested write path on a platform nobody here can run. |
| `.harness/scripts/guard-rm.{sh,ps1}`, `.harness/scripts/check-i18n-parity.sh` | OQ-1; B.2's scope must not widen. |
| `.harness/rules/05-insight-index.md` | OQ-7 filed, not fixed — a third rule fragment in the diff for zero recovered cost. |
| `bin/sc`, `install.sh`, `uninstall.sh`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md` | FR-11(b), AC-14: this task changes nothing a user of `sc` can observe. |
| `.claude/**`, `CLAUDE.md`, `.github/copilot-instructions.md` | Red line: runtime config, sync-generated agents, static stubs. No `harness-sync` run is required by any edit here. |
| `docs/dev-map.md` | Product documentation; it is deliberately outside B-2's process list. |
| `~/.claude/plugins/cache/harness-kit-marketplace/**` | Read-only for V-12. `/harness-upgrade` is not run in this task and no byte of the 0.47.0 template is copied into the repository (K-14, out-of-scope 10). |
| `docs/features/**` and `.harness/insight-index.md` of **this** repository, before delivery | BC-8: exactly one archive run touches them — this task's own, at delivery. |
| `/etc/sing-box/**`, `/var/lib/sing-box/**`, `/usr/local/bin/sc`, the live service | Out-of-scope 9; K-11. |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | — | Fixture trees built under `test/t27/` (K-8), each holding a **copy** of HEAD's `archive-task.sh` (K-9); HEAD's behaviour recorded on the AC-1, AC-5 and AC-7 fixtures as the control, with the dry-run report string quoted. | Delete `test/t27/`; nothing tracked was touched. |
| 2 | E-1 | Order 1's HEAD control captured, so V-1/V-5/V-8's "HEAD fails" clauses are measured rather than asserted. | `git checkout -- .harness/scripts/archive-task.sh`. No persisted state, no data migration: the script's inputs and outputs keep their format, and an index already over the cap is simply brought to it on the next run (BC-4). |
| 3 | E-1b | None — E-1b is unconditional (C-1). V-2b runs in the same order and both exit statuses are quoted whatever they are. | Same one-line revert. |
| 4 | E-2 | V-9's two clauses ran on the drafted text: the hand-routing of T-26's `01_*` and T-19's `02_*` produced no unit with two destinations or none, **and** every FR-6(c) kind routed to the portion its cited archived witness occupied. A contradiction corrects the text in place before it lands (BC-12, AC-9(b)). | `git checkout -- .harness/rules/70-doc-size.md`; nothing reads the section yet except this task's own stages 5-6. |
| 5 | E-3, E-4 | V-10's partition of the last three delivery commits ran and produced **no** path outside B-2 ∪ that task's product files; a leftover path is added to B-2 **before** E-3 lands (FR-9). V-12's drill ran against the read-only template copy and both checks resolved from B-3's bytes alone. E-3 and E-4 land together or AC-12's two triggers disagree. | Revert both files; no consumer exists until the next task writes a criterion. |
| 6 | — | `verify_all` from the repository root: PASS 17 / WARN 0 / FAIL 0 / SKIP 1 (AC-8, K-10, C-8). | The task is one commit; `git revert` restores HEAD behaviour. |
| 7 | — | Delivery: `07_DELIVERY.md` carries a non-empty `## Insight` section, then **one** run of the repository's own `archive-task.sh` (AC-15, C-7). | If that run leaves the index over 30, do **not** hand-rotate — the run is the criterion; report the failure against AC-1/AC-15. |

**Backwards compatibility.** No flag, no data migration, no format change, no user action. The index
and the history file keep their shape; a host running `sc` observes nothing. The one behaviour change
visible to a human is that the rotation branch now fires, so `insight-history.md` starts receiving the
`## Rotated <date>` blocks it was designed to receive. An index already over the cap (today: exactly
at it) is brought to the cap by the next run rather than by hand.

**Forward compatibility with the plugin.** Nothing here depends on a `/harness-upgrade` happening and
nothing is invalidated by one: after a refresh the reader runs B-3's two checks against whatever
arrived, keeps it, and re-applies only what the check says was lost.

## Out of scope

1. Everything `01_REQUIREMENT_ANALYSIS.md` `## Out of scope` lists — carried forward, not restated.
2. Any harness linter, script-integrity checker, vendored-file digest gate, CI job, new `verify_all`
   step, new hook, new script or new rule fragment (BC-11, NFR-2) — including any automated detection
   that `/harness-upgrade` replaced a file.
3. Any change to the 30-line cap, to what an insight entry is, to the harvest source, or to where
   archived stage documents are moved.
4. `docs/tasks.md` rotation, `PM_LOG.md` compaction and every other rule-70 process rule not named in
   FR-6; rule 70's caps table is edited only in the one cell E-2 names.
5. Re-homing any existing content of rule 80 or rule 70; both edits are additive apart from that cell
   and `AI-GUIDE.md:30`.
6. The PowerShell mirrors, `guard-rm.sh`'s tokenizer, `task-state.js` / `entropy-cadence`, and rule
   05's `summary.md` sentence (OQ-1, OQ-2, OQ-4, OQ-7).
7. Adopting harness-kit 0.47.0's 425-line `archive-task.sh` rewrite in whole or in part, and running
   `/harness-upgrade` inside this task (out-of-scope 10, OQ-11, K-14). The template is read, never
   copied.
8. Repairing the two index shapes I-1 names (no trailing newline; zero non-bullet lines). They are
   measured and reported as residuals against FR-1; the repair lives in the frozen rewrite.

## Verification plan

Every step runs from the repository root (K-10) against a fixture tree under `test/t27/` (K-8),
executing the fixture's **own copy** of the script (K-9). No step touches the live host, the installed
`sc`, `bin/sc`, or a real task folder. The fourth column **is** this design's requirement-coverage
mapping (E-5): every FR, BC and AC id appears in it at least once.

| step id | what is run/measured | expected observable | discharges (AC + the FR/BC ids it carries) |
|---|---|---|---|
| V-1 | AC-1 fixture: 8 header lines + 22 entries (30 lines) + a fixture `07_DELIVERY.md` carrying 3 `## Insight` bullets. Candidate run; `wc -l` before/after; diff of `insight-history.md`. | Index ends at **≤30 lines**, 3 entries appended to `insight-history.md` under one `## Rotated <date>` block. **HEAD control on the same fixture: 33 lines, no history file** (22+3 = 25 bullets ≤ 30). | AC-1, FR-1 |
| V-2 | Same run: concatenate (rotated ∥ remaining) and compare byte for byte against (pre-existing ∥ harvested); compare the 8 header lines; check the rotated 3 are the **oldest** 3. Include one entry beginning with `-`/`$`/`\` and one that is the file's longest line. | Byte-identical, in order, oldest rotated, header unchanged (PQ-6: bash's builtin `echo` interprets no escape). | AC-2, FR-2, BC-6 |
| V-2b | BC-1 × BC-7: fixture with **no** `.harness/insight-index.md`, run with `--dry-run`; `echo $?` captured on **HEAD** and on the candidate, both quoted. | Candidate: exit 0 with the dry-run report and zero bytes written. HEAD: whatever it does is recorded — an abort (exit 1, no report) confirms the `set -e` AND-list at `:82`; anything else is recorded as an observation. **E-1b lands either way** (C-1). | AC-7, FR-3, BC-1, BC-7 |
| V-3 | BC-3 fixtures: no `07_DELIVERY.md`; a `07_DELIVERY.md` with no `## Insight`; one with an empty `## Insight`. Index at 25 lines. | Index sha256 unchanged, no `insight-history.md`, the fixture task folder still moves to `_archived/`. | BC-2, BC-3 |
| V-4 | AC-3 fixture: 25-line index + 2 harvested. AC-4 fixture: exactly 30 lines + 0 harvested. | AC-3: no rotation, no history file, result = old bytes + 2 appended lines. AC-4: sha256 of both files unchanged. **HEAD passes both — controls.** | AC-3, AC-4, FR-3 |
| V-5 | AC-5's **two** fixtures: (i) header alone ≥30 lines with 2 entries and ≥1 harvested; (ii) **header-only** over the cap with ≥1 harvested, where the clamp reduces the rotation to zero. Read stdout and each resulting file; compute `wc -l` − 30. | Each run exits 0; at most the entries present rotated; **no header line and no harvested entry deleted**; the report's residual number equals `wc -l` of that resulting index minus 30, digit for digit, in **both** runs — including (ii), where nothing is rotated (PQ-2). Also proves the empty-`remaining` expansion is safe under `set -u`. **HEAD prints no residual line at all and rotates nothing — HEAD fails both.** | AC-5, BC-5 |
| V-6 | AC-6 fixture: a `## Insight` bullet wrapped across three lines with `· evidence: <slug>` on the last. `grep` the resulting index line. | One index line carrying the tag; nothing truncated or split. **HEAD passes — this is the FR-4 regression pin.** | AC-6, FR-4 |
| V-7 | BC-4 fixture: index already at 35 lines, 0 harvested and, in a second run, 2 harvested. | Both runs bring the index to 30. | BC-4 |
| V-8 | `--dry-run` over the AC-1 fixture: full-tree snapshot (existence, size, mtime, sha256) before/after, plus a positive control that writes one byte and proves the snapshot detects it; the dry-run report line quoted on **HEAD** and on the candidate. | Zero bytes written; the candidate reports the absolute number **`Rotated 3`**, equal to V-1's measured wet-run rotation. **HEAD reports `Rotated 0`.** If the two strings match, AC-7 is recorded NOT-DISCRIMINATING, never passed. | AC-7, BC-7, FR-3 |
| V-9 | **(a)** Route every unit of `docs/features/_archived/doctor-rows-establish-their-fact/01_REQUIREMENT_ANALYSIS.md` + `01_RATIONALE.md` and `docs/features/_archived/ruleset-staleness-visibility/02_SOLUTION_DESIGN.md` + `02_RATIONALE.md` by hand against B-1; count units with **zero** destinations and with **two**. **(b)** Tabulate each FR-6(c) kind → its archived witness (path:line, from `01_RATIONALE.md:200-218`) → the portion that witness occupied → the portion B-1 routes it to. | (a) Both counts are 0. (b) Every kind's B-1 routing equals its witness's portion, with the two known divergences recorded (`## Smaller alternative rejected` and the per-edit size table each sat in the rationale in an older task and in the contract in the most recent one — most recent decides). A contradiction corrects B-1 in place before E-2 lands (BC-12, RS-2). **HEAD has no such section — every unit has zero destinations and no kind has a routing.** | AC-9, FR-6, FR-7, BC-12 |
| V-10 | `git log --name-only -3` over the three most recent **delivery** commits; partition every path into that task's product files or B-2. | No path in neither. **HEAD's only instance of the list is T-19's prose, under which `docs/batches/BATCH_PLAN.md` / `BATCH_LOG.md` fall in neither.** Any leftover path is added to B-2 before E-3 lands. | AC-11, FR-9 |
| V-11 | Read rule 80's `## When to read` trigger line and `AI-GUIDE.md:30` side by side; read B-2 for `docs/batches/**`. | Both state the same trigger, including the committed-diff-criterion clause; `docs/batches/**` present. | AC-12, FR-8, FR-10 |
| V-12 | AC-13 drill. Copy `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.47.0/skills/harness-init/templates/common/.harness/scripts/archive-task.sh` (resolved through `upgrade-project.sh:56`, `:189`, `:222`; **read-only**, never into `.harness/`) to `test/t27/refresh/.harness/scripts/archive-task.sh`. Using **B-3's bytes only** — no in-file note, no re-diagnosis, no `git checkout` — run each row's check against that text, record the verdict and perform the stated action. Then run the AC-1 and AC-6 fixtures against the resulting script. | Version and path reported (BC-13). Two verdicts quoted with the command and number that produced each. The resulting script leaves the AC-1 fixture's index at **≤30 lines** by `wc -l` and puts the AC-6 fixture's wrapped bullet into the index with its continuation text and its trailing `· evidence:` tag. No step discarded the arriving text. **HEAD's only record is the in-file comment the replacement deletes — the drill has nothing to start from.** | AC-13, FR-5, BC-11, BC-13 |
| V-13 | `git diff -- .harness/scripts/verify_all.sh` ; `grep -n 'wc -l' .harness/scripts/verify_all.sh` ; `bash .harness/scripts/verify_all.sh` from the repository root. | Empty diff; F.4 still tests `> 30` lines; **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**. | AC-8, FR-11, BC-10 |
| V-14 | Read the `archive-task.sh` diff: count added lines, count `^[a-z_]*()` function definitions before and after, count subprocess invocations inside the entry loops; `wc -l` on all `.harness/rules/*.md`; `git status --porcelain` for `test/`; confirm no digest, pin, hook or `verify_all` step was added. | ≤8 added lines including E-1b, identical function count, no new per-entry invocation, rule 70 ≤130, every fragment ≤200, no new fragment, no fixture path tracked, no new executable artifact. | AC-16, AC-10, BC-9, BC-11, NFR-1, NFR-2, NFR-3 |
| V-15 | At delivery: `git status` + `git diff --name-only` partitioned against AC-14's two lists; then **one** run of the repository's own `archive-task.sh --task harness-self-maintenance`; sha256 of `.harness/insight-index.md` and `insight-history.md` immediately after it exits and again at `git add`. | Only E-1…E-4's paths in the product diff; only AC-14's second list among the delivery-time writes; index ≤30 lines; ≥1 insight harvested; both digest pairs equal — **no hand-rotation**. AC-15 is **not dischargeable before delivery**: the design only makes it reachable (E-1), and stage 7 must produce a non-empty `## Insight` section for its first clause. | AC-14, AC-15, BC-8, FR-10, FR-11 |
| V-16 | C-3's two fixtures, both over the cap, run with the candidate and `wc -l` quoted before and after: (i) an index whose final line carries **no trailing newline**; (ii) an index with **zero** non-bullet lines. | Each is reported with its measured result. Under I-1's stated condition they are the two shapes where the rewrite emits one line more than the decision counted, so **31 lines and F.4 WARN is the expected residual, reported against FR-1** — never repaired by a hand edit and never by touching `:105-132` (RS-9). | AC-1 (boundary), FR-1 |

## Smaller alternative rejected

*(Section placed here by `.harness/rules/85-design-discipline.md:41`, which names it in
`02_SOLUTION_DESIGN.md` by name — B-1's precedence clause, not an invented section.)*

Rule 85 puts the burden of proof on the larger design. Per defect, the smaller design and what the
extra lines buy — stated so stage 3 can **test** the answer.

**R-18 (the metric).** Smaller by 2 lines: keep the bullet count and add the header's size as a
constant — `total_after=$(( ${#current[@]} + ${#harvested[@]} + 8 ))` — a one-line edit, zero added
lines, and AC-1 through AC-4 all pass today. **Rejected**, and this is the abstraction the symptom is
hiding: 8 is not a fact about the cap, and it is not even a fact about the header block. The script's
"header" is `grep -vE '^\s*-\s'` over the **whole file** (`archive-task.sh:114`), so a blank line left
between two entries, or a stray `## Rotated` heading pasted in by a hand rotation of the kind this
project has performed sixteen times, raises that count without anyone touching the header — the
constant is stale before the next delivery, not merely after the next header edit. Upstream reached
the same conclusion independently and says so in its own comment (harness-kit 0.47.0 template,
`:382-385`). What the extra lines buy is that the script and F.4 call **the same tool on the same
file**. Also rejected as **larger**: any awk/sed rewrite of the rotation body, any helper function,
any second pass over the entries (AC-16, NFR-3).

**BC-5 (the clamp).** Smaller by 1 line: no clamp, and let the existing branch run. **Rejected by
measurement, not by taste** — with `set -u` and `rotate_count > ${#current[@]}`, `${current[$i]}`
expands an unset element and the run dies mid-archive after the harvest report has already printed.
The one line buys AC-5's whole statement clause and the file's survival; upstream ships the same
clamp (0.47.0 template `:340`), which is independent confirmation.

**R-37 (the boundary rule).** Round 1 shipped a 30-line section carrying a 10-row per-kind unit table
and defended it with "rejected by AC-9". The gate tested that answer and it failed (F-5): a degenerate
rule reading "everything goes to the contract portion" scores 0/0 on AC-9's collision counts too.
AC-9(b) now prices the table against practice, and **the table loses**: with each FR-6(c) kind checked
against the archived instance this project actually wrote (`02_RATIONALE.md`
`## AC-9(b) — every FR-6(c) kind against its witness`), the test plus the precedence clause route
**all seven** kinds to the portion their witness occupied, and the table's own
`measurement obligation → contract` row contradicts its witness. **So the ten lines are deleted**: B-1
ships FR-6(a)'s test, (b)'s precedence clause, the two-destinations sentence and (d)'s schema-gap
answer, at 18 lines instead of 30, and AC-9(b)'s final clause is the criterion that authorised it.
Also rejected as **larger**: a routing checklist per stage, a per-stage section registry, a
`verify_all` check that a stage doc's sections are declared.

**R-36 (the path list).** Smaller: no rule text at all — fix T-19's prose in place. **Rejected by
FR-8**: an archived stage document is not a fragment any stage reads, so the next criterion inherits
nothing. Smaller within the section: F-7's redundant bullet is deleted (the insight history is already
inside `docs/features/_archived/**`), taking B-2 from 14 lines to 13. Also rejected as **larger**: a
template file, a snippet library or a generator (OQ-10 rules this out by name), and a new rule
fragment (OQ-3, E.5's index duty).

**FR-5 (durability).** Smaller: keep the in-file comment (0 lines). **Rejected by evidence** —
`upgrade-project.sh:186-227` copies the template over the file unconditionally, so the comment is
deleted by the very event it warns about. Next smaller: one line in `.harness/insight-index.md`.
**Rejected for two reasons**: an insight line rotates out (into `insight-history.md`, which nothing
reads at task start) — a record this task's own fix eventually deletes — and one line cannot carry two
checks, two verdict actions and two loss consequences. Smaller within the record: round 1's version of
B-3 was 12 lines and **wrong** (F-1) — it instructed `git checkout -- <path>`, which discards a
425-line replacement, and obliged a re-application the arriving text already provides. The 14 lines
are what a check-plus-action-per-verdict record costs, and they land in a file already in the diff,
adding **zero** files. Rejected as **larger**: a digest gate, a pinned copy, a `verify_all` step, a CI
job (BC-11, K-13) — each would have to prove the check route fails first, and it does not.

**This document.** Round 1 carried three H2 sections the architect contract does not declare
(`## Durability ruling`, `## Requirement coverage`, `## Projected size`). All three are **deleted**:
the durability ruling's binding half is now I-5, K-13, K-14 and B-3 with its pricing in
`02_RATIONALE.md`; the coverage mapping is the ledger's `what changes` cells plus the verification
plan's fourth column; the size table is the `Est.` figure already on every ledger row. That is ~40
doc lines removed and it is what makes B-1's clause (d) true of this document (F-6, C-6).

**The task as a whole.** Rejected as larger, without argument beyond BC-11 and NFR-2: a harness
linter, a script-integrity checker, a vendored-file digest gate, a `verify_all` F.7 step, a CI job, a
scheduled self-check. Each would have had to prove the cheaper route fails first; it does not.

## Partition assignment

`.harness/agents/` holds no `dev-*.md` files (the directory does not exist), so this project runs in
**single Developer** mode: every edit above is marked `single-dev` and there is no dispatch order or
parallelism to state. E-1/E-1b, E-2 and E-3/E-4 are independent of each other; the sequence in
`## Migration & edit sequence` is a verification order, not a dependency order.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RS-1 | **Ruled INCLUDE, unconditionally** (C-1). E-1b lands in this task whatever V-2b observes; V-2b is a reported measurement, not a gate, and both exit statuses (HEAD and candidate) are quoted. | `04_DEVELOPMENT.md`, `06_TEST_REPORT.md` |
| RS-2 | V-9 may find a unit of T-26/T-19 with two destinations or none, or an FR-6(c) kind whose witness contradicts B-1. B-1 is then corrected **in place** before E-2 lands (BC-12); it is never shipped with a known unroutable unit and no section is invented for one. | `04_DEVELOPMENT.md`, `06_TEST_REPORT.md` |
| RS-3 | V-10 may find a delivery-commit path outside B-2 ∪ product files. That path is added to B-2 before E-3 lands — that is FR-9's derivation, not a criterion failure. | `04_DEVELOPMENT.md`, `06_TEST_REPORT.md` |
| RS-4 | AC-15 is observable only at delivery, and only once: the repository's own index and `docs/features/harness-self-maintenance/` are touched by exactly one archive run (BC-8, C-7). If it leaves the index over 30, report the failure — **do not hand-rotate**, which would destroy the observation. | `07_DELIVERY.md` |
| RS-5 | `07_DELIVERY.md` must carry a non-empty `## Insight` section or AC-15's first clause fails by construction. Candidates: `/harness-upgrade` **replaces** a vendored script with the plugin's current template rather than reverting local hunks, so a durability record must state checks against the arriving text rather than a restore command; and `set -e` + `[[ … ]] && cmd` aborting `archive-task.sh:82` on a dry run with no index. | `07_DELIVERY.md` `## Insight` |
| RS-6 | Upstream report (zero local cost): harness-kit's `archive-task.sh` decides rotation on an **entry** count (0.47.0 template `:333`, `:337-338`) while its own `verify_all` F.4 caps the index in **lines**. There the branch does fire and one entry may occupy several index lines, so the divergence is **wider** than in the vendored 151-line script, not dead — a run can satisfy the entry test and still leave the file over the line cap. Report the metric mismatch, not a dead branch (F-9). Owner/PM action, not a task. | `07_DELIVERY.md`, PM report |
| RS-7 | Two declines belong in `.harness/rejected-decisions.md`: `insight-index-header-count-as-a-constant` and `vendored-fix-durability-by-a-project-side-check`. That file is outside AC-14's **product** list, so the PM files them at delivery (the T-26 RS-7 precedent). | `07_DELIVERY.md` (PM files) |
| RS-8 | `.harness/rules/70-doc-size.md` lands at ~111 lines against AC-10's ≤130 — ~19 lines of headroom, gained by deleting B-1's unit table. Any later addition is weighed against it; the next process rule probably belongs in a `70b-` sibling (rule 70's own caps table prescribes the split at `:24`). | `07_DELIVERY.md` (pool) |
| RS-9 | Two index shapes leave the run at 31 lines and F.4 WARN despite a correct decision, because the frozen rewrite (`:113-119`) emits one line the decision did not count: an index with no trailing final newline, and an index with zero non-bullet lines. V-16 measures both and reports them; the repair is inside `:105-132` and therefore belongs to whichever task next opens that range (or to the OQ-11 adoption row, since the 0.47.0 template already fixes both with `printf '%s\n'` and a scanned header range). | `06_TEST_REPORT.md`, `07_DELIVERY.md` (pool) |
| RS-10 | FR-6(c)'s per-kind list is **not shipped**: AC-9(b)'s final clause fires because the test plus the precedence clause route all seven witnessed kinds correctly. Stage 3 should confirm that reading; if it rules the list must ship, the seven rows return with `measurement obligation → rationale` (its witness, `doctor-rows-establish-their-fact/01_REQUIREMENT_ANALYSIS.md:215`), not `→ contract`. | `03_GATE_REVIEW.md`, `06_TEST_REPORT.md` |
| RS-11 | This task declines the 0.47.0 refresh (out-of-scope 10, OQ-11). The pool row *adopt harness-kit's `archive-task.sh` rewrite* carries RS-6, RS-9, the `.ps1` mirror question (OQ-4) and a re-derivation of AC-1…AC-7 against a different program. | `07_DELIVERY.md` (pool) |

## Verdict

READY
