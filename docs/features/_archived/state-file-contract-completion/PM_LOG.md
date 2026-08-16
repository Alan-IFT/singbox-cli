# PM Log — T-29 / state-file-contract-completion

- Task: T-29, pool `closeout` (`docs/batches/closeout/BATCH_PLAN.md`)
- Mode: full (7 stages). Dispatched by `/harness-batch`; standing decision authority granted
  («你来决策就行»), so `BLOCKED: NEEDS-HUMAN` is reserved for a genuine safety red line.
- Started / delivered: 2026-08-16

## Pre-dispatch checks

`node .harness/scripts/task-state.js show` — **the script does not exist in this project**
(MODULE_NOT_FOUND, exit 1); the rounds ledger below is the durable state, as in every prior task
here. `.harness/intervention.md` absent at every one of the eight boundary checks (before stage 1 and
after each stage completion) — no intervention was ever pending. Working tree clean at start.
`docs/tasks.md` at its 300-line F.5 cap, so the T-29 row and every new row are added at delivery
together with rotation into `docs/tasks-archive.md`, rather than pushing the file over the cap
mid-task. Insight index 30 lines / 22 entries; **8 surfaced whole** to downstream dispatches (the
`PYTHONUTF8=0` locale-vacuity entry, the stderr-`backslashreplace`-vs-strict-stdout entry, the
`json.loads`-over-`bytes` entry, the `PYTHONIOENCODING`-before-locale entry, the loader-recipe R-77
entry, the `main()`-once-per-process entry, the codec-deletion-false-kill entry, and the
`verify_all`-must-run-from-the-repository-root entry).

## Rounds ledger

| Stage | Round | Verdict | Route |
|---|---|---|---|
| 1 requirement-analyst | 1 | READY | advance → stage 2 |
| 2 solution-architect | 1 | READY (+1 upstream defect) | rollback → stage 1 (AC-1 uncountable) |
| 1 requirement-analyst | 2 | READY | advance → stage 3 |
| 3 gate-reviewer | 1 | BLOCKED ON DESIGN | rollback → stage 2 (C-1) + stage 1 (C-2) |
| 1 requirement-analyst | 3 | READY | advance |
| 2 solution-architect | 2 | READY | advance → stage 3 re-review |
| 3 gate-reviewer | 2 | APPROVED WITH CONDITIONS | advance → stage 4 |
| 4 developer | 1 | READY FOR REVIEW | advance → stage 5 |
| 5 code-reviewer | 1 | APPROVED WITH MINOR FINDINGS | rollback → stage 4 (CR-1 clause only) |
| 4 developer | 2 | READY FOR REVIEW | advance → stage 6 |
| 6 qa-tester | 1 | CHANGES REQUIRED (D-1 MAJOR) | rollback → stage 1 (AC-11 unsatisfiable) |
| 1 requirement-analyst | 4 | READY | advance → stage 2 |
| 2 solution-architect | 3 | READY | advance → stage 4 |
| 4 developer | 3 | READY FOR REVIEW | advance → stages 5 + 6, concurrently |
| 5 code-reviewer | 2 | APPROVED (0 CRITICAL, 0 MAJOR) | advance |
| 6 qa-tester | 2 | CHANGES REQUIRED (D-2 CRITICAL) | **rollback → PM** (rule 70 Rule 2) |
| — PM compaction | — | done | → stage 6 re-verify |
| 6 qa-tester | 3 | (AC-14 re-verify) | → stage 7 |

## Compacted stages 1..4 (2026-08-16)

Compacted under rule 70 Rule 2 at a stage boundary — stages 1–4 are stably past; stages 5 and 6 below
are kept full and chronological. Nothing here was decided by me: every ruling is the owning stage's.

- **Stage 1 r1 — the three rulings the pool asked for.** **R-65 → REFUSE**: an unusable settings
  document blocks every run that **writes**, blocks no run that only **reports** (Q-2 answers T-16's
  AC-6 — it is the existing reader's existing outcome through the existing envelope, so no second
  opinion; Q-3 **bounds** R-27's "what is discarded was not in effect" rather than overturning it,
  because a regeneration *acts* on the discarded choices). **R-76 → blanket sweep, six sites** (the
  four named plus two locale-encoded *writes* the row never counted, `bin/sc:3451`/`:3499`), on the
  ground that a rule with zero exceptions is pinnable by a source scan and one with an exception is
  not. **R-66 → render it, keep the swallow** (FR-5 makes T-23's declining ground a binding
  requirement). Two first-hand corrections to my brief: `bin/sc:567`'s docstring does **not**
  contradict the code (it is scoped to state documents, and none of the four sites reads one) — the
  sentences actually false are both READMEs' `:297`; and R-66's "only" is imprecise. R-77 reported
  **discharged in fact** by T-28.
- **Stage 2 r1 — the design, and it found an upstream defect.** FR-6's single insertion point is
  `generate_config()` (two callers; no reporting command reaches it, so **FR-8 needs zero code**).
  Framing that keeps it small: the eight read-modify-write commands already refuse via
  `load_settings()`; FR-6 is that rule applied to the one RMW nobody had spelled. It **took the
  smaller** FR-7 shape (catch-and-flag over catch-store-re-raise) because the larger buys sentence
  *position* only, and rejected two others as **wrong, not larger**. It then reported that **AC-1 was
  uncountable** — "exactly one sentence" counted total stderr lines, which contradicted FR-8 inside
  the same document and would have produced a false FAIL at stage 6.
- **Stage 1 r2 — AC-1 corrected** to "one refusal sentence **in addition to** the run's existing
  announcement", keeping the non-zero exit, the three byte-identical files and the R-22 defence
  clause verbatim. AC-4 and AC-5 checked first-hand for the same defect and **deliberately left
  unchanged** with reasons (`warn=True` is passed at exactly one site in the file).
- **Stage 3 r1 — BLOCKED ON DESIGN, and it caught the defect before any code existed.** **G-1
  (MAJOR)**: `generate_config()` raises `OverrideError` from **four** places, so the design's bare
  `except OverrideError:` was a four-document catch — `sc update-rules` would have exited 1 with the
  cause named nowhere, i.e. **this task's own defect re-installed one document over**. **G-2
  (MAJOR)**: AC-5 could not detect it, so it would have **shipped green** — the R-22 shape. It ruled
  the FR-7 smaller shape correct (escalation stays unspent) and the NFR-1 overage justified. Ten
  binding conditions C-1…C-10.
- **Stage 1 r3 + stage 2 r2 — run concurrently, and they agreed.** Analyst added **AC-19** (C-2) as
  **one row, two runs**, naming the composition-fault path excluded-and-unrunnable rather than
  silently satisfied (R-67), with a **mutation as its discriminating control** since HEAD passes it —
  a regression guard, labelled as such. It **declined my stricter gloss** (I had asked it to demand
  the outcome line; at HEAD this path prints none, so my version would have failed the smallest
  correct fix). Architect re-derived the arm to a `.path` guard + bare re-raise, forming **no second
  opinion about usability** (`.path` is set by `_unusable()`, class default `None` sorts to the
  re-raise), and rejected four alternatives including a `SettingsError` **subclass** — this project
  answers "whose document" with an **attribute, not a taxonomy**.
- **Stage 3 r2 — APPROVED WITH CONDITIONS.** G-1 verified closed at all four raise sites plus two
  structural checks. **On the budget it named the budget as the defect**, which is more useful than a
  grudging pass: NFR-1's provenance priced a modified line as an added line, priced a *five-line*
  renderer at four, and **omitted FR-5 entirely** — *19 was always the right number; 14 is a defect in
  the budget.* It confirmed my gloss was wrong and AC-19's "at most one" correct. New **G-9**: K-4
  claimed `_load_lang()` skips `doctor`/`config`, but `main()` calls it on **both** arms — bound as
  C-11 rather than a third stage-2 rollback, and without it a stage-6 reader would have reported AC-4
  failed **against correct code**.
- **Stage 4 r1 — `bin/sc` +24 / −9** (19 code, 5 comment), the design's number to the line, confirmed
  by `git diff --numstat`. Frozen surfaces carry no hunk. Suite 14 → **17 defined / 17 run / 17
  passed**, floor raised in the same change, none removed or weakened. Three mutations killed as
  stated (including `AttributeError` **inside the handler** for a bare `e.strerror`, reproducing
  T-23's finding first-hand). **One mutation failed to kill and it said so**: collapsing E-10's arm
  leaves the suite green — routed to stage 5 as an explicit ruling rather than decided by me.
- **Stage 4 r2 — CR-1 discharged as a written boundary** (one coverage clause at `docs/dev-map.md:76`,
  inside E-13's existing scope): no new row, no new file, no assertion, floor unmoved, **no product
  line added**, `verify_all` and the suite unmoved.

## Stage 5 — code review

**Round 1 — `APPROVED WITH MINOR FINDINGS` (0 CRITICAL, 0 MAJOR, 2 MINOR, 4 NIT).**
Spec/design-fidelity axis: **no findings at all**. It verified the C-1 guard independently and
tabulated **eight** raise paths where the gate found four, including `_compose()`'s own overlays.
FR-5's pairing shipped intact — renderer, `except SystemExit:`, and that `try` holding **exactly one
statement**, with all ten other `save_settings()` callers read in their blocks. It ruled the unpinned
guard a **written boundary, not a fourth assertion**: the property is a regression guard for a HEAD
behaviour, the honest pin needs the suite's first **command-level** fixture (a pool row), and an `ast`
shape assertion would pin a **spelling, not a behaviour** — reddening B.4 for the `if/else` form
stage 2 had priced as correct. Routed back one clause; CR-2 and four NITs carried, not fixed.

**Round 2 — `APPROVED` (0 CRITICAL, 0 MAJOR; 2 MINOR, 5 NIT, none blocking).** Both corrected README
paragraphs carry AC-11's four assertions and both negatives **in both languages** — the Chinese read
clause by clause as a document in its own right, not skimmed as a translation. Blast radius held:
`:124`/`:152` still carry HEAD's wording (CR-2 untouched, RES-3 intact) and every line number cited in
round 1 is unmoved. New **CR-7**: `cmd_config()`'s docstring makes the same two-spelling enumeration —
**ruled shippable**, because it states nothing false, draws **no** conclusion about the saved file (so
neither AC-11 negative is engaged), and correcting it would cost a `bin/sc` line no ledger row
authorises and move the `+24/−9` that four documents cite; it travels to T-32 as RES-5. **RES-4
restated rather than retired** — its byte-identity form is obsolete, but a real unverified half (the
blast radius) remained, and leaving it as written would have sent delivery hunting an identity that
must *not* hold.

## Stage 6 — QA

**Round 1 — 18 PASS / 1 FAIL / 0 BLOCKED / 0 NOT-DISCRIMINATING.** Every discriminating row
discriminated: HEAD killed eight, five purpose-built mutants killed the rest. **RES-1 discharged** —
the `m_arm_collapsed` mutant **FAILs AC-19** (`sentences naming the document = 0`) while leaving the
suite at 17/17/17, so CR-1's boundary is exact. **RES-4 discharged**: both READMEs machine-checked
byte-identical to HEAD.

**D-1 (MAJOR)** — AC-9's own mandated CJK fixture falsified the third clause of both READMEs' `:297`
paragraph. `backslashreplace` has **three** forms and the paragraph named two; `\uNNNN` **is** a legal
JSON escape, so for a CJK document the saved file *is* valid JSON. Pre-existing text, **vacuous at
HEAD** (the run ended at the read) and **live after this change** — exactly the "repairing it
falsifies a shipped sentence" shape R-76 predicted, in a clause nobody had enumerated.

**My routing decision on D-1, and why it is stage 1.** AC-11 had become **unsatisfiable**: it demanded
the paragraph be *byte-identical to HEAD* **and** true. Only the analyst may resolve a tension inside
its own document (hard rule 2). **Not deferred to T-32** despite the pool's ordering note making
deferral defensible, because the dispatch says in terms: *"this task carries its own prose correction
— do not defer that to T-32."*

**Hard rule 3, recorded at the boundary case.** Stage 1 round 4 was its **third** rollback. Rule 3
exists to stop *thrash*; this was not thrash — the pipeline advanced through stages 2–6 between each,
each rollback came from a **different** stage finding a **different** narrow defect, and no ruling was
ever re-opened. I proceeded, and bound myself to escalate if round 4 did not settle AC-11. **It did**,
so the bind never fired.

**The D-1 chain — three narrow rounds, no re-gate.** *Stage 1 r4*: AC-11 restated to "corrected and
true, one hunk per file, four behavioural assertions in each language", with out-of-scope 10 and 8,
NFR-3's permitted paths and Q-5 adjusted and Q-14 added; the discriminating control preserved (HEAD's
own text fails clause (c) on the CJK row; a build correcting only the English file FAILs). *Stage 2
r3*: one ledger row and one unfreeze — K-12 rewritten to "correct exactly that paragraph, freeze
everything else", V-11 amended in place. The architect **declined my suggested row id**: `E-15` was
already taken and using it would have renumbered three rows, so the row is **E-18** — correct call, I
had not checked the ledger. E-1…E-17 byte-identical. *Stage 4 r3*: two prose hunks, **no product code
line**. It **re-measured rather than transcribed**, and **discarded its own first probe** on finding
that a tag passed through `argv` under `LC_ALL=C` decodes with `surrogateescape` and kills the run
inside the fixture's *own* writer before `sc` is reached. It also corrected my brief: this project's
`verify_all` defines **no A.3 row**, and it said so rather than claiming an A.3 PASS.

**No re-gate for that delta, deliberately** — the design change was one ledger row transcribing a
requirement stage 1 had already fixed, touching none of the gate's live conditions C-8…C-12, and both
stage 5 and stage 6 re-verified the result independently. My routing decision, recorded as such.

**Round 2 — AC-11 PASS with both controls behaving**, boundary swept over 8 835 code points
(`x`: U+0080…U+00FF, `u`: U+0100…U+FFFF, `U`: ≥U+10000), independently reproducing stage 4's
measurement. HEAD control FAILs; the english-only control FAILs with every clause marked `[zh]`.
AC-19 **re-run** (2 cases × 3 builds) rather than carried. Eleven rows carried forward on a **measured
build identity** — `diff <(sed '3408,3410d' bin/sc) qa/mutants/m_arm_collapsed` is empty — not on
assertion. RES-4 retired at this stage, its git-level half discharged.

**D-2 (CRITICAL) — routed to me, and it is mine to fix.** `verify_all` had moved to
`PASS 18 / WARN 1 / FAIL 0 / SKIP 1`, **exit 1**, against AC-14's required 19/0/0/1. The single WARN
is `[F.6] Active task docs <=500 lines each`; the check prints no file name, so QA re-ran the
predicate by hand and found **exactly one** file over the cap: **this `PM_LOG.md`, at 550 lines**. No
product code implicated. QA correctly **did not fix it** — rule 70 Rule 2 makes PM_LOG compaction
PM-owned and forbids delegating it to an agent that is reading the file.

**PM compaction (this document, at a stage boundary).** Compacted stages 1..4 to one-line summaries
per rule 70 Rule 2, keeping stages 5 and 6 full and chronological. No decision, ruling, round record
or residual was dropped — only verbatim restatement of evidence the archived stage docs already carry.
Then re-verified the gate myself and re-dispatched stage 6 for AC-14 only.

## Residuals to file at delivery

RES-2 (buy the committed pin for E-10's guard: a command-level fixture, floor 17 → 18 — plus SG-1(a),
`m_persist_oserror` and `m_refusal_global` ride the same row), RES-3 (both READMEs' `:124`/`:152`
"every command except `sc doctor`"), RES-5 / CR-7 (`cmd_config()`'s docstring, → T-32), the
architect's two stage-2 residuals (`subprocess.run(text=True)` at `bin/sc:2157`/`:3473`;
`install.sh:492-506`'s locale-dependent reader whose `except json.JSONDecodeError` misses
`UnicodeDecodeError`), C-12 / G-10 (an aborting `sc update-rules` prints no run-level outcome line, at
HEAD and after), and SG-1(b) — `docs/tasks.md:228`'s R-76 text now asserts something false of the
shipped code, mine to close.
