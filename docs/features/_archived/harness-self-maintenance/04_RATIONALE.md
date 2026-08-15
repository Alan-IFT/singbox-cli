# 04 — Rationale · T-27 `harness-self-maintenance`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

## 1. Fixture inventory and the runs taken on it (measurement narrative)

Every fixture is a tree under `test/t27/<case>/` holding `.harness/scripts/archive-task.sh` (a
**copy** of the text under test), `.harness/insight-index.md` and
`docs/features/fixture-task/07_DELIVERY.md`. Builder: `test/t27/mkfix.sh`. Nothing under `test/`
is tracked (`.gitignore:19`), `HARNESS_ALLOW_OUTSIDE_RM` was never set, and the repository's own
`archive-task.sh` was never executed.

| case | index before (`wc -l`) | harvested | exit | report line(s) | index after | history |
|---|---|---|---|---|---|---|
| `head-ac1` (HEAD control) | 30 | 3 | 0 | — | **33** | absent |
| `ac1` (candidate) | 30 | 3 | 0 | `Rotating 3 old insight(s) to insight-history.md` | **30** | 3 entries |
| `head-ac1-dry` (HEAD, `--dry-run`, same index bytes) | 30 | 3 | 0 | `  - Rotated 0 old insight(s) to insight-history.md` | 30 | absent |
| `ac1-dry` (candidate, `--dry-run`) | 30 | 3 | 0 | `  - Rotated 3 old insight(s) to insight-history.md` | 30 | absent |
| `head-ac3` | 25 | 2 | 0 | — | 27 | absent |
| `ac3` | 25 | 2 | 0 | — | 27 | absent |
| `head-ac4` | 30 | 0 | 0 | — | 30 | absent |
| `ac4` | 30 | 0 | 0 | — | 30 (sha256 unchanged) | absent |
| `head-ac5i` | 32 | 1 | 0 | — | 33 | absent |
| `ac5i` | 32 | 1 | 0 | `Over cap: 1 line(s) …` + `Rotating 2 old insight(s) …` | 31 | 2 entries |
| `head-ac5ii` | 32 | 1 | 0 | — | 33 | absent |
| `ac5ii` | 32 | 1 | 0 | `Over cap: 3 line(s) …` (no `Rotating` line) | 33 | absent |
| `head-ac6` | 13 | 3 (one wrapped) | 0 | — | 16, tag present | absent |
| `ac6` | 13 | 3 (one wrapped) | 0 | — | 16, tag present | absent |
| `bc2` (header only, 0 entries) | 8 | 2 | 0 | — | 10 | absent |
| `bc3a/b/c` (no `07`, no `## Insight`, empty `## Insight`) | 25 | 0 | 0 | — | 25, sha256 unchanged | absent |
| `bc4a` | 35 | 0 | 0 | `Rotating 5 old insight(s) …` | 30 | 5 entries |
| `bc4b` | 35 | 2 | 0 | `Rotating 7 old insight(s) …` | 30 | 7 entries |
| `head-v2b` / `v2b` (no index at all, `--dry-run`) | absent | 1 | 0 / 0 | full dry-run report on both | still absent | absent |
| `c3i` / `c3ii` / `c3iii` | 31 / 32 / 33 | 1 each | 0 | see `04_DEVELOPMENT.md` C-3 row | 31 / 31 / 29 | 2 / 3 / 4 entries |
| `refresh-ac1` / `refresh-ac6` (0.47.0 as it arrives) | 30 / 13 | 3 / 3 | 0 / 0 | see the drill | 33 / 16 | absent |
| `rfix-ac1` / `rfix-ac6` (0.47.0 + the *lost* action) | 30 / 13 | 3 / 3 | 0 / 0 | `Rotating 3 old insight entry(ies) …` | 30 / 16 | 3 entries |

AC-2's byte comparison ran on the `ac1` wet run through `test/t27/ac2_check.py` (exit 0):
22 pre-existing + 3 harvested = 3 rotated + 22 remaining, `(rotated ‖ remaining)` equal to
`(pre-existing ‖ harvested)` as byte lists and in order, rotated == the oldest three, the 8 header
lines byte-identical (sha256 `1c09421c4ea7…` on both sides), the three hostile entries
(`- -n foo …`, `- $x \`date\` and a\backslash\t …`, a 386-byte longest line) each byte-equal to
their source, and the longest line unsplit. This is PQ-6/PQ-8's claim reproduced: bash's builtin
`echo` interprets nothing without `-e`, and the hazard is the header, not the entry.

## 2. V-2b — why HEAD does not abort, and what that costs the design's stated basis

The design's E-1b row and RS-5 both assert that under `set -euo pipefail` the AND-list at
`archive-task.sh:82` "returns 1 when the test fails, aborting a `--dry-run` run whose index is
absent". **Measured, it does not.** HEAD on the `head-v2b` fixture printed the missing-index
warning, printed the whole dry-run report, wrote zero bytes and exited **0**.

The reason is bash's own errexit exemption: the shell does not exit when the failing command is
part of an `&&` list and is not the command following the final `&&`. Here the failing command is
the `[[ … ]]` itself. Minimal reproduction, run first-hand:

```
$ bash -c 'set -euo pipefail; if [[ ! -f /nonexistent-xyz ]]; then echo "warn"; [[ "true" == false ]] && touch /dev/null; fi; echo "reached line after the if"'
warn
reached line after the if
  exit=0
```

So E-1b is a **hardening** edit, not a bug fix: the form is one `return`-position change away from
being fatal (it is fatal as the last command of a function or of the script), and K-4 bans it for
that reason. C-1 ruled it unconditional and V-2b "a measurement that is reported, not a gate", so
it landed and the measurement is reported. Two consequences travel: RS-5's second candidate insight
is **false as stated** and must not be written into `07_DELIVERY.md` `## Insight`; and the E-1b
ledger cell's justification is wrong while its instruction is right.

## 3. V-9(a) — the hand-routing worksheet

Routed against the text landed in `.harness/rules/70-doc-size.md:80-97`. Destination counts:
**zero units with none, zero units with two** (n = 30 units).

`doctor-rows-establish-their-fact/01_REQUIREMENT_ANALYSIS.md` — `## Goal`, `## In-scope behaviors`,
`## Out of scope`, `## Boundary conditions`, `## Acceptance criteria`,
`## Non-functional requirements`, `## Resolved questions`, `## Verdict`: all eight are shapes the
requirement-analyst contract declares by name (0.47.0 `agents/requirement-analyst.md:20-27`), so
**precedence** decides → contract, which is where they sit. The bare test agrees on all eight.

`…/01_RATIONALE.md` — `## 1. Per-row re-verification` (+4 H3 children), `## 2. Candidate answers,
and the argument that selected among them` (+4 H3 children), `## 3. Related tasks`,
`## 4. Traps the fixtures must avoid`, `## 5. Glossary terms proposed for CONTEXT.md`: the
requirement-analyst contract's rationale paragraph names "the evidence narrative and measurements,
the related-tasks survey, each question's candidate answers and the argument that selected among
them" (`requirement-analyst.md:33-38`) → precedence → rationale, which is where they sit.
`## 4. Traps the fixtures must avoid (for stage 2's V-table and stage 6)` is the one unit where the
bare test alone is arguable — its title addresses two later stages — and it is exactly the case the
precedence clause exists for: it is a measurement narrative of what prior tasks paid, named by the
contract, so it routes to rationale and its binding half became stage 2's V-table rows. Recorded as
the single unit that needed precedence rather than the test.

`ruleset-staleness-visibility/02_SOLUTION_DESIGN.md` — `## Architecture summary`, `## Change
ledger`, `## Interfaces`, `## Constraints`, `## Frozen set`, `## Migration & edit sequence`,
`## Out of scope`, `## Verification plan`, `## Residuals travelling`, `## Partition assignment`,
`## Verdict` are declared shapes (`agents/solution-architect.md:19-31`) → precedence → contract.
`## Requirement coverage` and `## Smaller alternative rejected` are **not** declared; the bare test
sends both to the contract (stage 3 audits coverage; `.harness/rules/85-design-discipline.md:41-42`
obliges stage 3 to *test* the rejected alternative) and both sit in the contract. One destination
each.

`…/02_RATIONALE.md` — `## Reuse audit`, `## Risk analysis`, `## Options considered and dropped`,
`## Evidence relied on` are named by the architect contract's rationale paragraph
(`solution-architect.md:44-49`: "the reuse audit …, the risk analysis, option comparisons,
measurement narratives, evidence citations") → precedence → rationale, where they sit.
`## Why the timestamp does not re-open "no second opinion"` and `## How T-20 consumes this (FR-2)`
are arguments, not obligations — the obligation they explain is FR-2 in the contract → rationale.
`## Size accounting` is the per-edit size table; see V-9(b) row 3 for its divergence.

The count cannot come out other than 0/0, and this is worth stating plainly: the test is total and
binary, and the precedence clause resolves rather than adds, so no unit can score two and none can
score zero. That is F-5's observation, and it is why AC-9(b) — not (a) — is the clause that carries
the weight.

## 4. AC-13 drill — full transcript

Version measured: harness-kit **0.47.0**,
`skills/harness-init/templates/common/.harness/scripts/archive-task.sh`, 425 lines,
sha256 `4c8db8c81ee8b74f903585d00d94224f20fd46a9210ea451ab08d07ac4e82d9e`, resolved through
`upgrade-project.sh:56` (`$TEMPLATE_ROOT/skills/harness-init/templates/common/.harness/scripts`)
and refreshed by name at `:186-194`. Copied to `test/t27/refresh/.harness/scripts/archive-task.sh`
and `chmod a-w`; the digest of the copy equals the digest of the template. No byte of it entered
`.harness/`. The drill used the landed rule-80 record only — no in-file note was opened, no
`git checkout` was run, neither defect was re-diagnosed.

**Check 1 (metric row).** Record's check: *"archive a fixture whose index is at the cap with ≥1
harvested insight, then `wc -l` the resulting index"*. Fixture: the AC-1 fixture (30-line index,
3 harvested), per PQ-6 read "at the cap" in lines.

```
$ bash test/t27/refresh-ac1/.harness/scripts/archive-task.sh --task fixture-task   # EXIT 0
Index tally: entries 22, unaccounted lines 0, entries after run 25
$ wc -l < test/t27/refresh-ac1/.harness/insight-index.md
33
```

Exit status 0 → the check completed (C-12). 33 > 30 → verdict ***lost***.

**Check 2 (join row).** Record's check: *"archive a fixture whose `## Insight` bullet wraps over
three lines with the tag on the last, then read what it wrote"*.

```
$ bash test/t27/refresh-ac6/.harness/scripts/archive-task.sh --task fixture-task   # EXIT 0
Insight tally: entries 3, continuation lines 2, ignorable lines 2 (terminal footer 0), unaccounted lines 0
$ grep -c 'fixture-wrapped' test/t27/refresh-ac6/.harness/insight-index.md   # exit 0
1
```

Exit status 0 → the check completed. Continuation text and the trailing `· evidence:` tag both
present (as a three-physical-line entry, which is how that program stores entries) → verdict
***already provided*** → the record's action is **change nothing**, and nothing was changed.

**Action for *lost*.** The record states it as a metric, not a patch: *"make the rotation decision
read `wc -l` of the index — F.4's own measurement, `verify_all.sh:213-219` — instead of whatever it
counts, and rotate until the file it writes is ≤30 lines."* On a program whose entries span several
lines (PQ-7) that reads as: rotate entries until the **emitted** line count falls to the cap. Two
bounded hunks onto the arriving text (`test/t27/apply_lost_action.py`, result in
`test/t27/refresh-fixed/`, `+13 / −5`, `bash -n` clean), nothing discarded:

1. the entry-count decision at the arriving text's `:337-341` becomes a loop that sums
   `IDX_HDR` + every stored entry's line span + `HARVEST`, then rotates while that sum > 30 and
   `rotate_count < idx_entries` (the clamp becomes the loop bound);
2. the write-branch head `if (( total_after > 30 ))` at `:368` becomes `if (( rotate_count > 0 ))`,
   because the entry total no longer decides whether the rewrite runs.

Neither hunk transcribes this repository's own edit — the two programs are structurally different
— and neither re-diagnoses a defect.

**Both AC-13 observables on the resulting script.** AC-1 fixture: 30 lines before → `Rotating 3 old
insight entry(ies) to insight-history.md`, exit 0, **30 lines** after by `wc -l`, 3 entries in
`insight-history.md`. AC-6 fixture: exit 0, the wrapped bullet reaches the index with its
continuation text (`over three physical lines`, 1 match) and its trailing tag
(`· evidence: fixture-wrapped`, at index line 16).

**F-15's hazard is real and untouched by this drill.** 0.47.0 exits **3** on any unclassifiable
line, writing nothing (`:353-357`); such a run leaves the index ≤30 and would read as *already
provided* to a reader who did not look at the exit status. Both checks here exited 0, so no verdict
rests on a refusing run. Stage 5 ruled on it (**CR-1**, MAJOR, `05_RATIONALE.md` §5): the clause is
required in rule 80's own bytes because C-12's procedural cover expires with T-27 while the fragment
is permanent. It is now landed at `.harness/rules/80-delivery-policy.md:75-78`, transcribed from the
byte-form the reviewer supplied rather than drafted here (K-12), so the hazard is closed at the
record and no longer an open issue. The drill above is unaffected — both its checks exited 0.

## 5. The measurement tool itself — a trap this task walked into

`grep` in the interactive shell these measurements were taken from is a **shell function** wrapping
**ugrep 7.5.0**, while a child `bash` running a script gets **GNU grep 3.11** (`/usr/bin/grep`;
`type grep` in a script prints `grep is /usr/bin/grep`). The two disagree: on a file whose last
line carries no trailing newline, `grep -cv PATTERN` under ugrep returns one **less** than
`grep -v PATTERN | wc -l`, measured on `test/t27/c3i`'s index (`-cv` = 7, piped count = 8, file
holds 8 non-bullet lines) and reproduced on a 5-line synthetic file. Every count in
`04_DEVELOPMENT.md` was therefore re-taken with `/usr/bin/grep` explicitly. The scripts under test
are unaffected — they never see the function — but a *measurement* of them taken at the tool layer
is not the measurement the script takes, which is precisely the class of error this whole task is
about.

## 6. Size accounting

| edit | added | removed | of which executable | design estimate |
|---|---|---|---|---|
| E-1 + E-1b (`archive-task.sh`) | 8 | 4 | 8 | +7/−3 and +1/−1 = +8/−4 |
| E-2 (`70-doc-size.md`) | 20 | 1 | 0 | +20/−1 |
| E-3 (`80-delivery-policy.md`) | 36 | 0 | 0 | +30/−0 |
| E-4 (`AI-GUIDE.md`) | 1 | 1 | 0 | +1/−1 |
| total | **65** | **6** | **8** | ≈ +59/−6, 8 executable |

E-3 is 6 lines over its estimate: **3 lines** from C-10's authorised re-wording of B-3's opening
sentence, which took that paragraph from 7 lines to 10; **2 lines** from the trigger line landing
as a two-line paragraph plus its blank separator rather than the one line estimated; and **1 line**
from CR-1's completion clause, inserted at `80-delivery-policy.md:75-78` after round 1. `.harness/rules/70-doc-size.md`
= 110 lines (AC-10 bar ≤130, F.2 bar ≤200); `.harness/rules/80-delivery-policy.md` = 89 (F.2 bar
≤200, `git diff --numstat` = 36/0); `AI-GUIDE.md` = 97 (F.1 bar ≤200). No fragment added, so E.5's
index duty is discharged by the single rewritten line.
