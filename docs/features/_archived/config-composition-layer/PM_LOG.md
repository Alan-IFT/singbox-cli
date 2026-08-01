# PM Log — config-composition-layer (T-14)

Mode: **full** (7 stages). Dispatched by the owner with standing decision authority
(「你来决策就行」), deferred-human mode: defer, do not ask. `BLOCKED: NEEDS-HUMAN` is reserved
for a genuine safety red line only.

## Pre-flight

- `.harness/intervention.md`: **absent** (checked before stage 1 dispatch) — no pending intervention.
- `.harness/insight-index.md`: read (30 entries). Applicable lines surfaced to downstream stages:
  - L11 auto-elevate re-execs the **installed** `/usr/local/bin/sc` under sudo → every harness must
    neutralise it (safety-critical for this task; the whole task is about `generate_config()`).
  - L12 `失败：` is a load-bearing diagnostic grep in `bin/sc` output → any new zh string must avoid it.
  - L18 `systemctl is-active` cannot detect a restart → witness is `show -p MainPID -p ActiveEnterTimestamp`.
  - L22 a `git worktree` is not a valid pristine baseline for `verify_all.sh` → use a clone.
  - L26 `verify_all` E.6 matches `^##\s+Adversarial\s+tests` → a numbered heading FAILs the step.
  - L27 `_init_files()` hard-codes `/var/lib/sing-box` → never drive it from a redirected harness.
  - L28/L29 `_write_private()` mechanics (fchmod-before-first-byte, O_EXCL+replace) → config writing
    must keep going through it; do not reintroduce a second write path.
- `docs/tasks.md`: read. Related historical tasks that touch this code path, all DELIVERED:
  - **T-02** `config-degrade-missing-rulesets` — `_filter_rules`, per-file degradation, empty
    `route.rule_set` deleted. Runs *after* the dict is built.
  - **T-05** `sc-doctor` — `ruleset_report()` = `_status_view(ruleset_states())`; `_init_files()`
    deliberately below `parse_args()`; `doctor` strictly read-only.
  - **T-10** `ruleset-update-no-needless-restart` — `ruleset_state()` digest-based change detection.
  - **T-13** `config-write-permission-hardening` — `_write_private()` is the single credential write.
  - Open row **R-9** (committed `bin/sc` harness) is adjacent but out of scope here.
- `docs/dev-map.md`: read. `# Config generation` section, `_filter_rules`, `_write_private`,
  the harness neutralisation recipe, and the "Config is regenerated, never patched" pattern all bear
  directly on this task.

## Task board

Added as **T-14 / config-composition-layer / mode: full**.

## Stage transitions

| # | Stage | Agent | Verdict | Decision |
|---|---|---|---|---|
| 1 | Requirement analysis | requirement-analyst | **READY** — 17 in-scope behaviours, 26 boundary conditions, 30 ACs, 7 NFRs, 16 decisions taken under standing authority, 0 open questions | **ADVANCE to stage 2** |

### Stage 1 → 2 (2026-08-01)

`01_REQUIREMENT_ANALYSIS.md` written (540 lines — over the 500-line soft cap; see PM ruling P-2).
No `BLOCKED:` marker, no rollback request, no safety red line. Intervention file re-checked:
**absent**.

Three things the analyst established by reading the source rather than assuming, which change what
stage 2 must design against:

- **Route mode is NOT an axis of the differential closure.** `generate_config()` never calls
  `load_settings()`; `cmd_mode` persists the mode and pushes it through the Clash API only. The
  dispatch brief said "every route mode"; the analyst verified it is not an input at all. Closure is
  16 rule-set subsets × 4 node/active states = **64 runs** plus targeted extras. This *narrows* the
  gate on evidence rather than by convenience — accepted.
- **Two byte-identity traps**: the emitted document has no trailing newline and uses
  `ensure_ascii=False` (BC-4/BC-22); and `_filter_rules` **mutates surviving rules in place**, which
  is harmless today only because the literal is rebuilt on every call. A module-level base template
  turns that into cross-invocation corruption (BC-20/AC-11). This is the single sharpest constraint
  on the architect's representation choice.
- **D-11 is scope-derived, not preference**: `install.sh` fetches an enumerated artifact list and is
  out of scope, so a separately-shipped template file would simply be absent on every `curl | bash`
  install. The template must live inside `bin/sc`; representation remains the architect's call.

**PM ruling P-1 — CONTEXT.md edit permitted.** The analyst added five glossary terms (`base
template`, `overlay`, `directive`, `user override`, `drift`) to `CONTEXT.md`, which the dispatch's
scope boundary did not name. Ruled **in scope**: that boundary governs the *product* diff (`bin/sc`
+ the two READMEs), and `CONTEXT.md`'s stated purpose is to stop two tasks meaning two things by one
word — precisely the T-15/T-16/T-17 hand-off this task exists to enable. Flagged to the gate
reviewer to confirm the new terms describe *behaviour* and do not presuppose a mechanism the
architect is still free to choose (D-16 in particular).

**PM ruling P-2 — doc-size overrun noted, not bounced.** 540 lines against rule 70's 500-line cap.
Not routed back: a re-dispatch to shorten prose spends a stage transition on formatting while the
content is load-bearing (64-run closure enumeration + 26 boundary conditions). Carried to the gate
as an item to assess, and to delivery as a known WARN candidate (F.6 fired on both T-05 and T-13 and
cleared on archive).

| 2 | Solution design | solution-architect | **READY** — D-16 decided (single `override.json`), 7 mechanisms settled, 3 tensions + 1 discretionary element flagged for the gate | **ADVANCE to stage 3** |

### Stage 2 → 3 (2026-08-01)

`02_SOLUTION_DESIGN.md` written (638 lines). No `BLOCKED:` marker, no rollback request against
stage 1, no safety red line. Intervention file re-checked: **absent**.

The architect decided **D-16 = a single `/etc/sing-box/override.json`**, rejecting the `conf.d/`
fragment directory on rule-85 grounds (it serves none of the five nameable consumers: T-15/T-16/T-17
ship overlays as code inside `bin/sc`; T-21 could not install a fragment because `install.sh` is out
of scope and `sc` never writes the override, so the directory ships empty on every host; and the one
real consumer is served *worse* because `sc` may not `mkdir` it). Recorded in
`.harness/rejected-decisions.md`. That is the decision stage 1 handed forward — it is now closed.

The design's load-bearing claim, which the gate must test hardest: **AC-1 holds by construction**
because every run-time value is written to a key that *already exists* in `CONFIG_BASE` (placeholders
`[]`, `[]`, `""`), and assigning to an existing dict key preserves its position. If that claim is
false anywhere, the gate is the last stage that can catch it cheaply.

| 3 | Gate review | gate-reviewer | **APPROVED FOR DEVELOPMENT** with 8 binding conditions | **ADVANCE to stage 4** |

### Stage 3 → 4 (2026-08-01)

`03_GATE_REVIEW.md` written. **No rollback** — the gate ruled on all four flagged items rather than
returning them, which is the outcome a well-formed design earns. Intervention file re-checked:
**absent**.

| 4 | Development | developer (single-dev mode) | **READY FOR REVIEW** — AC-1 148/148 PASS, 91 semantic checks 0 failed, all 8 gate conditions discharged, `verify_all` 0 new FAIL / 0 new WARN | **ADVANCE to stage 5** |

### Stage 4 → 5 (2026-08-01)

`04_DEVELOPMENT.md` written (670 lines). No `BLOCKED` marker, **no design drift reported**, no
rollback request. Intervention file re-checked: **absent**.

**Stage gate checked before advancing:** `verify_all` PASS 16 / WARN 1 / FAIL 0 / SKIP 1 —
identical to the pre-edit working-tree baseline, and the single WARN is F.6 doc-size which already
fired from `01`/`02` before any code was written. **0 new FAIL, 0 new WARN.** The pristine clone at
`f642ca7` reads 17/0/0/1, confirming the clone (not a worktree) was a valid oracle.

**Build order was followed in the order the gate made non-negotiable**, and it paid: the harness was
proven to FAIL on three mutants *before* `bin/sc` was touched — including **M2, a pure key reorder
that changes no value**, which is exactly the failure R-1 named as hardest to spot by eye. A green
148-run differential now means something. The literal move was then done **by script**, never
re-typed, and `diff` shows exactly four hunks (the name + the three position-holding placeholders).

**Correction to my own dispatch, recorded:** I passed the gate's Condition 2 premise that
`git status` showed `M bin/sc`. The developer checked and found `bin/sc` **clean** at pin time
(`git diff --stat -- bin/sc` empty, working tree = `HEAD` = `f642ca7`); the dirty files were
`CONTEXT.md`, `.harness/rejected-decisions.md` and `docs/tasks.md` — stage-2's own artifacts. My
session-start snapshot was stale. The condition was still discharged the safe way (pinned from the
working tree, not `git show`), so the stale premise cost nothing — but the error was mine, not the
gate's, and it is recorded rather than quietly dropped.

**Two findings I am carrying to stage 6 as QA obligations**, both discovered by the developer
against its *own* work rather than reported clean:

- **The `zh` fixture must pin `settings.json["lang"]`, not just `sc.LANG`** — `main()` reassigns
  `LANG` via `_load_lang()` after import, so a harness setting only `sc.LANG` renders **English** on
  every path driven through `main()`. The developer's first 25 `zh` assertions were **vacuous** and
  passed anyway, because "no newline, no `失败：`" is also true of English. This is a vacuity trap
  that will silently swallow QA's bilingual coverage too.
- **Baseline and candidate must run at the *same* fixture path** — the fixture root is emitted
  verbatim inside `route.rule_set[].path`, so two `mkdtemp()` roots produce a 100% config mismatch
  that reads like a refactor bug. This *contradicts* the gate's Condition 3 wording ("fresh fixture
  root per point"); the developer resolved it as wipe-and-re-seed at a stable path and recorded the
  measurement rather than silently deviating. **PM ruling P-7: the deviation is correct and is
  accepted.** Condition 3's intent was "no stale `STATE_PATH`", which wipe-and-re-seed satisfies
  exactly; its literal wording was written without knowing the root is an emitted value.

| 5 | Code review | code-reviewer | **APPROVED** — 0 CRITICAL, 0 MAJOR, 2 MINOR, 3 NIT; **no design drift** | **In-stage return to 4′ for MINOR-2, then ADVANCE to stage 6** |
| 4′ | In-stage return | developer | README factual error corrected in both languages; `verify_all` unchanged | **ADVANCE to stage 6** |

### Stage 5 → 4′ → 6 (2026-08-01)

`05_CODE_REVIEW.md` transcribed verbatim (same read-only tool-set situation as stage 3 — PM ruling
P-5 applies unchanged). Intervention file re-checked: **absent**.

**The review did the job it exists for: it re-derived the central claim instead of accepting it.**
The reviewer walked `CONFIG_BASE` against the pinned baseline **line by line, not by diff summary**,
and confirmed all 12 emitted positions — down to an incidental double-space inside
`{"outbound": "proxy",  "clash_mode": "Global"}` surviving, and the `domain_suffix` lists keeping
their wrap point. It also independently confirmed the three properties that would have been most
expensive to discover later:

- **Deep-copy discipline is complete** — all eight entry points where an overlay value reaches the
  document are deep-copied, and the `$before`/`$after` splice takes its surviving elements from the
  already-copied document, so no alias exists. This was the task's most dangerous defect class
  (R-5): one shallow path and `_filter_rules`' in-place mutation corrupts `CONFIG_BASE` for the
  *second* call in the same process.
- **B-7 is structural, not remembered** — there is genuinely no edge in the call graph from
  `_apply_directive` back to `_merge` or `_directive_of`, so an inserted value is *unreachable* from
  the directive classifier.
- **`defined` is computed two lines before the `del`**, as A-7 requires.

**In-stage return at 4′ (not a rollback).** MINOR-2 was a factual error in the task's own new
user-facing documentation: both READMEs claimed `sc mode` regenerates `config.json`. It does not —
and `01` §5 names precisely that fact as the reason route mode is not an axis of AC-1's closure, so
the shipped README contradicted the task's own requirement document. I routed it to the developer
(the owner the reviewer named) as a documentation-only fix. The developer verified the three
functions itself rather than trusting my summary and **found a third mis-statement the review had
missed**: `cmd_update_rules` regenerates only when a rule-set was *gained*, not on every content
change. Three of six were wrong, not two. Fixed as an always/maybe split rather than a per-command
truth table — the matrix would have been rule 85's counter-rule violated in prose. `bin/sc`
untouched, so the 148-run differential still stands; `verify_all` unchanged at 16/1/0/1.

| 6 | QA test | qa-tester | **CHANGES REQUIRED** — AC-1 independently reproduced (164 runs, 860 comparisons, byte-identical); all 30 ACs pass; **1 MAJOR + 2 MINOR found** | **ROLLBACK to stage 1 (scoped addendum), MAJOR only** |

### Stage 6 → 1′ (2026-08-01) — ROLLBACK #1

`06_TEST_REPORT.md` written (2264 lines). Intervention file re-checked: **absent**.

**The gate held under an independent rebuild.** QA derived its oracle from `01`'s ACs, not from the
developer's code, and reproduced AC-1 at **164 runs / 860 comparisons** against a pristine **clone**
at `f642ca7` — and independently confirmed AC-2 by matching the clone's `bin/sc` sha256 to the hash
`04` §2 recorded. Non-vacuity was proved with **six** mutants (value, pure key reorder, array
reorder, stderr-only, `nodes.json`-only, return-value-only), each failing with the correct blast
radius. 10/10 stable, no flakes. Service identical at **10** checkpoints.

**The MAJOR — routed to stage 1, and here is why that is the right desk.**

A **dangling symlink** at `override.json` is silently treated as *absent*: `os.stat` follows
symlinks (which is exactly what makes D-14's accepted case work), so a broken link lands in the
`FileNotFoundError → return None` arm. Measured: `rv=True`, empty stderr, `config.json` replaced,
`exit=0`, and **no drift warning either**, because `sc` generated the file so the record matches.
**The user's entire override is discarded without a word — the precise failure `01` §2 says this
task exists to remove, reproduced inside the fix for it.**

I am routing this to the **requirement-analyst**, not the developer, because it is a genuine
upstream ambiguity rather than a coding slip:

- **BC-7** says empty ≡ absent. **BC-9** says "any non-regular file **after symlink resolution** →
  malformed". A dangling symlink resolves to *nothing*, so it falls in the seam between the two and
  **no AC is literally violated**. Only the author of the requirement can say which governs.
- The behaviour was **specified by the design** (`02` §5.4's step list writes
  `FileNotFoundError -> None (absent)` explicitly), so the developer implemented what it was given.
  Bouncing it to the developer would ask them to overrule a design, which they may not do.
- The workflow that produces it is the one D-14 **deliberately blessed** ("users legitimately
  symlink configuration into a version-controlled directory"), so this is not an exotic path.
- The sharpest evidence is internal: `bin/sc:723` already decides this identical question the *other*
  way for the project's other user-facing file — *"A dangling symlink does not exist, but it is
  broken rather than absent"* → `unreadable`. **Two functions in one file now hold opposite opinions
  about the same shape**, which is the duplicated-judgment seam rule 85 exists to prevent.

**Scope of the rollback is deliberately narrow**: a numbered addendum closing the BC-7/BC-9 seam,
**not** a re-analysis. AC-1 cannot be affected — with no override present there is no symlink — so
the 164-run gate does not need re-deriving, only re-running. I have asked the analyst to state
explicitly whether closing the gap needs the architect (a design change) or falls inside D-14's
existing intent (straight to the developer), so the return path is chosen on the merits rather than
by my guess.

**The two MINOR are also handed to the analyst to rule on scope** (it owns scope, I do not):
a 500-level-deep override yields a 2999-line `RecursionError` traceback against NFR-7's one-line
contract, and a bare *object* silently replacing an existing array is the unguarded mirror of D-5.
Both are contained (no write, no service action; the second is caught by the real `sing-box check`).

### Stage 1′ → 4″ (2026-08-01)

The analyst appended **§12 Addendum A** to `01_REQUIREMENT_ANALYSIS.md` — new **BC-27 / AC-31 /
D-17** — without rewriting or renumbering anything above it, and filed **R-15 / R-16** in
`docs/tasks.md` for the two MINOR. Intervention file re-checked: **absent**.

**The ruling: a dangling symlink is `malformed`, not `absent`.** The reasoning is better than the
precedent I handed it. I expected consistency with `ruleset_state` to carry the ruling; the analyst
**declined to lean on it**, calling it corroborating rather than decisive (that function classifies a
downloaded artifact under a digest contract, which is a different question), and instead applied
**BC-7's own discriminator — can this shape encode a typo?** Empty/whitespace cannot; a symlink is an
affirmative act naming a target, and a moved or mistyped target *is* a typo. Combined with B-9
(`sc` never creates or writes this file), a link at that path can only be the user's act, so calling
it "the user expressed no override" contradicts an observable fact. It also corrected my citation:
the precedent is at `bin/sc:732-734`, not `:723` — `:723` is inside the docstring.

**The routing answer I actually needed: developer, not architect.** `02` §5.4's *step order* does not
change (the stat-before-open FIFO guard is untouched; the discrimination lives inside the existing
first step's failure arm), and **D-14's rationale does not change** — a link resolving to *nothing*
was never inside D-14's grant, it was unenumerated. No new component, call site, interface or
ordering. That saved a stage-2 transition without cutting a corner.

**The sharp edge the analyst flagged, and why it was the whole risk:** the arm being amended is
entered on **every single AC-1 run** (no override file ⇒ not-found path). A careless fix would have
broken byte-identity for the entire task. Hence AC-31's second clause: not-a-symlink must remain a
**silent `None`**. I passed this to the developer as the one thing that could go wrong.

| # | Stage | Agent | Verdict | Decision |
|---|---|---|---|---|
| 1′ | Requirement addendum | requirement-analyst | **BC-27 / AC-31 / D-17 ruled**; MINOR-A → R-15, MINOR-B → R-16; routing: developer | **ADVANCE to stage 4″** |
| 4″ | Development (scoped fix) | developer | **DONE** — 5-line `islink` block + 1 `t()` key pair; AC-1 green on both harnesses; non-vacuity mutant 12/26 red | **ADVANCE to 5′ + 6′** |

### Stage 4″ → 5′ + 6′ (2026-08-01)

The fix is `os.path.islink` in the not-found arm, raising the existing `OverrideError`. Two
implementation judgments the developer made and justified rather than defaulted:

- **`os.path.islink` makes BC-27's final-component-only boundary a property of the primitive**, not a
  second invariant someone must keep true — it is `lstat`-based, so it is `False` both for a
  genuinely absent entry and for a broken *parent* component, which is exactly where the analyst drew
  the line.
- **`os.path.realpath`, not `os.readlink`** — `readlink` names only an intermediate link in a chain
  and **can raise `OSError` inside a `FileNotFoundError` handler**, which would surface to the user as
  a traceback. `realpath` resolves to the component actually missing and swallows its own errors, and
  is non-strict on the 3.6 floor (`strict=` is 3.10+).

**Non-vacuity was proved on the fix itself**, which is the part I would otherwise have had to take on
trust: reverting *only* the five-line block turns 12 of 26 new assertions red, reproducing the MAJOR
verbatim (`exit was 0`, `config.json was modified`, `restart_service called 1 times`, `drift record
changed`) — while everything else stays green, which is what shows the fix is confined to the arm it
claims. The 164-run differential was re-run **as QA published it**, against QA's own oracle, neither
relaxed nor re-baselined.

**Design drift declared, not silently absorbed.** `02` §5.4's step list still reads
`FileNotFoundError -> None (absent)`. The developer left `02` unedited (downstream cannot edit
upstream) and recorded the supersession in `04` §17 citing BC-27/D-17/AC-31. That is the correct
handling of the rule, and 5′ is checking it.

**Dispatched 5′ and 6′ in parallel** — both examine the same frozen 5-line delta from independent
perspectives, and neither's conclusion is an input to the other's.

| 5′ | Delta review | code-reviewer | **APPROVED** (delta) — 0 CRITICAL, 0 MAJOR, 0 MINOR, 2 NIT (both `04` §17.1 prose) | **Record correction dispatched at 4‴** |
| 6′ | QA re-verification | qa-tester | **PASS** — MAJOR closed; earlier CHANGES REQUIRED explicitly superseded | **ADVANCE to stage 7** |

### Stage 5′ + 6′ → 7 (2026-08-01)

Both parallel verifications returned. Intervention file re-checked: **absent**. **Delivery gate met**
— stages 5 and 6 both PASS.

**5′ refused to take the scope claim on trust, and that is why it was worth running.** Rather than
reading the diff, it proved the delta by **line arithmetic**: every anchor from its original review
moved by exactly one of two constants (+2 or +19), which is only possible if `bin/sc` gained lines at
exactly two points and lost none anywhere. A diff can be mis-read; that argument cannot. It confirmed
AC-31 clause 2 structurally (the amended arm's only added statement is an `if` guarding a `raise`, so
the not-a-symlink path still reaches `return None` unchanged), confirmed `os.path.islink` is
`lstat`-based and swallows its own errors — making BC-27's final-component-only boundary **a property
of the primitive rather than an invariant someone must maintain** — and confirmed the declared design
drift was handled correctly.

**6′ rebuilt rather than inherited, again.** It wrote its **own** `qa_bc27.py` (50 assertions) from
`01` §12 rather than reusing the developer's `bc27_test.py`, then proved non-vacuity against a mutant
that removes only the five `islink` lines: **30 ok / 20 FAILED**, the 20 being exactly the BC-27
clause-1 assertions, reproducing the MAJOR verbatim (`exit code 0`, `config.json NOT byte-identical`,
`restart_service called 1x`, and the run even printing `Reloaded` / `已重新加载`). The other 30 stayed
green, which is what shows the fix is confined to its arm. AC-1 re-ran at **164 runs, unrelaxed and
un-rebaselined**, against the same pristine `f642ca7` clone.

It went beyond the developer's tests in ways that mattered: symlink targets containing `\n`/`\r`/
ESC-CSI and `{format}` braces (a double-`str.format` risk), a symlink **loop** (`ELOOP` is `OSError`,
not `FileNotFoundError`, so it takes a different arm), a link pointing *through* a broken parent, and
whole-tree equality instead of per-file. All survived.

**Two initial reds that QA correctly diagnosed as its own harness rather than the code** — and
probed rather than assumed: `sc use` + a dangling link changed `nodes.json`, which the **unfixed**
build also does for an invalid-JSON override (`cmd_use` writes `active` before composition —
pre-existing, outside AC-20/AC-31); and a whole-tree comparison against `f642ca7` differed at
`.config.sha256`, a file T-14 *adds by design* (BC-16). Both were re-pointed at the correct oracle
instead of being filed as defects.

**PM ruling P-10 — the two 5′ NITs are worth a stage transition, and here is why.** They are prose
errors in `04` §17.1, not code defects, and the reviewer routed no owner. I dispatched a
documentation-only correction anyway (4‴) because one of them is a **false technical fact that would
be archived and inherited**: "`realpath` cannot raise" is true from Python 3.10 but not on this
project's documented **3.6 floor**, where `posixpath._joinrealpath` calls `os.readlink` unguarded.
Leaving it would teach the next task something untrue about the interpreter this project actually
targets. The choice of `realpath` still stands on its other leg (chain resolution), so no code moves.
I asked the developer to verify the claim against real `posixpath` source rather than accept my
assertion of it.

| 4‴ | Record correction | developer | `04` §17.1 false claim retracted; count corrected 4 → 19 | **ADVANCE** |
| 4⁗ | Source comment correction | developer | comment-only +3/−2; token stream proven identical (11 778 both sides) | **ADVANCE to stage 7** |
| 7 | Delivery | PM Orchestrator | `07_DELIVERY.md` written; board updated; archived | **DELIVERED** |

### Stage 4‴ / 4⁗ → 7 (2026-08-01)

**PM ruling P-11 — I overruled the developer on the source comment, and it flagged rather than
decided, which is the behaviour I want.** After correcting `04` §17.1, the developer reported that
the *same* retracted claim ("`realpath` … unlike readlink it cannot raise") still lived in the code
comment at `bin/sc:1297-1298`, judged it not worth reopening two green gates, filed it for T-20 —
**and told me, so I could decide otherwise.** I did. A false claim in a comment is worse than one in
a stage document, because the comment is what gets read at the point of the next change; and writing
a paragraph elsewhere explaining that the claim is false while leaving the claim in the source is
exactly the residue rule 85 forbids. The deciding factor was one the developer could not weigh —
this task is being delivered now, not continuing into T-20. Gates were **re-run, not reopened**, and
I required the full 164-run differential anyway, precisely because "it's only a comment" is how
byte-identity gates get skipped.

The developer went further than asked and **verified my premise against real stdlib source on two
interpreters**, which improved the fact: the TOCTOU window is not a ≤3.9 artifact at all — on 3.12.3
the 3.10 rewrite guarded the `lstat` and left `os.readlink` **still unguarded** at `posixpath:499`.
It also proved the comment edit inert by **token stream** (11 778 tokens identical with comments
dropped) rather than by reading the diff, which is the only method that would catch a re-indent.

**This was declared the final change.** Anything surfacing after it goes to an open row.

### Stage 7 — delivery (2026-08-01)

`07_DELIVERY.md` written; `docs/tasks.md` updated (T-14 moved to Completed; **R-17** filed for R-4's
encoding defect, **R-18** filed for the archive-script defect below); `archive-task.sh` run.

**Post-archive `verify_all`: PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — the pristine-clone profile
exactly. The F.6 doc-size WARN cleared on archive as the gate predicted at stage 3, before a line of
code was written.

**The archive step earned its own finding.** All four insights harvested intact (single-physical-line
discipline held, and the script turns out to carry a *local* fix for the older truncation bug at
`:51-71` that a `/harness-upgrade` may silently revert). More usefully, the **root cause of the
long-known broken rotation was diagnosed**: the script's threshold counts **bullets** while
`verify_all` F.4 counts **lines**, and the two differ by the file's header — so the branch can never
fire on any index with a header. That is not a tuning problem, and it has cost every task since T-05
a manual step. Filed as **R-18**.

**Index rotation: 3 of my 4 proposed entries, one substitution, and one reasoned refusal.** I asked
for four entries out under rule 70's "what no longer earns its line". The agent **kept** the
progress-redraw throttle entry I had proposed removing, on evidence I did not have: `docs/tasks.md`
files it as an open row against a harness **T-07 inherits**, and T-13's rotation had already deleted
its predecessor *because this entry supersedes it* — so dropping it would leave the corrected reading
nowhere while the uncorrected one is already gone. It substituted a generic writing caution instead.
That is the right call and I accepted it; my selection was made from the index alone, its from the
index plus the open rows.

**PM ruling P-8 — MINOR-1 is NOT fixed in T-14, and that is the reviewer's own instruction.**
An override appending a **non-object** element to `dns.rules`/`route.rules` passes the shape
assertion and then reaches `AttributeError` in `_filter_rules` — a traceback where every other
malformed-override case produces a sentence. It is real, but every fix touches `_filter_rules`
(pinned by AC-8) or widens `02` §6 past its stated three paths, either of which is an unreviewable
change inside a byte-identity gate. Filed as a new open row at delivery. Owner: requirement-analyst,
next task at this seam.

**PM ruling P-9 — the `CHANGELOG.md` / `docs/features/sc-doctor/` snapshot discrepancy is stale
context, not a scope breach.** The reviewer checked `CHANGELOG.md`'s contents and found **no** T-14
material; `docs/features/sc-doctor/` resolves to nothing on disk. Both come from my session-start
git snapshot, the same stale snapshot that produced the phantom `M bin/sc`. Recorded for the owner
to reconcile before committing; nothing for the pipeline to do.

**PM ruling P-5 — I transcribed the gate's document.** The stage-3 agent's tool set is read-only
(Read/Glob/Grep), so it returned the finished document in its reply and could not write it. I wrote
`03_GATE_REVIEW.md` **verbatim**, adding only a provenance note at the top. This is transcription,
not authorship: no finding, condition or verdict was added, removed or reworded. Recording it
because a PM writing into a stage document is otherwise a pipeline violation.

**The central claim survived.** The gate did what it was asked and walked today's literal key by key
against the composed path — all 9 top-level positions plus the selector's 5 keys, the node
outbounds and the `route.rule_set` entries. Two results worth carrying forward:

- `(node_tags or []) + ["direct"]` and `node_tags + ["direct"]` are equal **for every input**,
  because `node_tags` is a list comprehension and is falsy exactly when the `or []` arm fires. That
  is the one place a "harmless simplification" could have silently broken AC-1.
- `CLASH_PORT` in `CONFIG_BASE` would have **frozen the emitted port at 29090** on every host that
  ever probed a different one. The architect's call to read it at call time was load-bearing, not
  stylistic.

**Rulings recorded (all four flagged items closed at the gate, none returned):** T-1 ACCEPTED
(whitespace-only ≡ absent, branch narrowly bounded); T-2 ACCEPTED (the `nodes.json` rewrite is none
of the three things AC-20 pins, and BC-3's explicit preservation outranks D-2's looser phrasing);
T-3 ACCEPTED without the 6-line stash (`save_nodes()` already unwinds past the same block, so the
stash would advertise an invariant as enforced while one of two doors stays open — worse than the
honest state R-12 records); **A-7 RULED IN** (equal by construction *and* detected by the 64-run
closure, since all four tags are referenced in `route.rules`).

Eight conditions now bind the developer. Three are safety or evidence conditions I consider
non-negotiable and will check at stage 5/6: **C-1** (no live-host action — the gate caught that
`02` §7's "or with the service stopped" is the one sentence in 1178 lines a stage-6 agent could act
on literally, and reinterpreted it), **C-2** (pin the baseline from the **working tree**, not
`git show HEAD:bin/sc` — `git status` shows `M bin/sc`, so the two differ and the wrong oracle fails
in the false-green direction), and **C-3** (fresh fixture root per point, or the candidate's own
`STATE_PATH` makes it emit a drift line the baseline cannot).

**PM ruling P-6 — single-developer mode.** No `.harness/agents/dev-*.md` files exist, so stage 4
dispatches the plugin `harness-kit:developer` and the design carries no partition split, as
instructed.

**PM ruling P-4 — `docs/dev-map.md` added to the diff boundary; permitted.** The architect flagged
that it exceeds the dispatch's stated boundary (`bin/sc` + the two READMEs). Ruled **in scope**:
dev-map's own header mandates an update when modules or reusable utilities change, and the developer
agent's contract requires it. This task adds a `# Config composition` section, several reusable
utilities, and — the load-bearing one — **two new paths (`OVERRIDE_PATH`, `STATE_PATH`) that every
future harness must repoint or it writes under `/etc`**. Omitting that from dev-map would leave the
next task's harness unsafe. The boundary's purpose is to bound the *product* diff; this is
documentation.

**PM ruling P-3 — D-16 forwarded, not decided by me.** The analyst deliberately left the override's
location/shape (single `override.json` vs `conf.d/` fragment directory) to stage 2 with the
trade-off and four binding constraints written out. That is a design decision, not a routing
decision; forwarding it unchanged is the correct call for a router. It is explicitly NOT a
needs-human item — the owner's standing grant covers it.
