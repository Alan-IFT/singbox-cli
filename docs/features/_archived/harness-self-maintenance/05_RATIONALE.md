> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## 1. CR-1 — the landed bytes, compared character by character

The clause I specified (round-1 rationale §5) and the clause on disk are the same text. Landed,
`.harness/rules/80-delivery-policy.md:75-78`, quoted in full because a condition turns on it:

> For each fix below, run its check against the arriving text and take the action for the verdict it
> gives, naming the version measured: a verdict is a property of that text, not a standing fact. A check
> whose command exits non-zero **did not complete** and yields no verdict — a run that wrote nothing is
> never *already provided*. `git log -p -- <path>` holds the pre-replacement text when an action needs it.

Sentence 1 is B-3's pre-existing sentence, unaltered. Sentences 2 and 3 are the byte-form, with the
only difference being where the physical line breaks fall — the paragraph was reflowed to four
lines instead of three. Emphasis markers survive in both places (`**did not complete**`,
`*already provided*`), the em-dash is the same character, and the backtick spans are intact. The
developer's normalised compare reporting `MATCH: True` agrees with what I read.

Placement checks that mattered as much as the wording: the clause is **inside the paragraph**
(`:68-78`), not appended as a table row or a new bullet, so a reader reaches it before the table it
governs. `## Local fixes to plugin-vendored scripts` is `:66-83` — heading `:66`, paragraph
`:68-78`, table header `:80-81`, rows `:82-83`. The rows are byte-identical to
`02_SOLUTION_DESIGN.md:180-181`, checked cell by cell including the `≤30 → change nothing` and
`>30 → …` verdict cells and the embedded `verify_all.sh:213-219` citation. Nothing else in B-3
moved.

## 2. Does the clause deliver the property, or only mention exit status?

The distinction I asked myself to re-check. Merely mentioning exit status would be a sentence like
"note the exit status of each check" — a reader could note it and still conclude *already provided*.
The landed sentence does three separable things: it **classifies** a non-zero exit ("did not
complete"), it **withholds the output** ("yields no verdict"), and it **forecloses the one wrong
answer by name** ("a run that wrote nothing is never *already provided*"). The third is what closes
the actual hazard, because the hazard is not that the reader ignores the exit code — it is that the
observable the table asks for (`wc -l` of the resulting index) is **≤30 on a refusing run for the
wrong reason**, the index being untouched rather than correctly rotated.

Against the arrival in the cache: `0.47.0:336` sets `refusing=true` when `h_unacc > 0 || idx_unacc > 0`;
`:343` freezes `index_after`; `:353-357` prints the refusal and `exit 3` **above** the line at `:363`
that opens the write phase. So the refusing path writes nothing at all, and its resulting index is
the pre-run index — ≤30 whenever the fixture started at the cap. Before the clause, that reads as
*already provided*; after it, the run yields no verdict.

FR-5's binding property is "from the record and its checks alone … the reader reaches one verdict
per fix plus the action the record states for that verdict, and applying those actions leaves the
resulting script deciding rotation on the cap's own measurement". Two arrivals exist. A completing
arrival: verdict, stated action, and the action makes the script read `wc -l` — the property holds,
and stage 4's C-12 drill demonstrated exactly that on 0.47.0 with an accepting fixture. A refusing
arrival: no verdict, therefore no action, therefore no *wrong* action; the reader is left holding an
unfinished check, which is a state that demands work rather than one that silently certifies. That
is the strongest form the property can take on an arrival whose check cannot run, and it is what I-5
("resolvable from its own bytes") requires — the bytes now resolve the case instead of falling
through it.

The one thing the clause does not do is spell the recovery step ("make the check complete — e.g.
against a fixture with no unclassifiable lines — then re-read the verdict"). I considered raising
that and did not: a sentence stating that a check yielded no verdict, sitting immediately above a
table whose every row maps verdicts to actions, leaves only one thing to do. Spelling it costs
another line on a fragment that has just been charged one, and rule 85's burden of proof sits on the
larger text. Recorded in CR-1 as a residual reading rather than as work.

## 3. Rule 85 on the round-2 delta

One sentence, +1 line, `88 → 89`, on a fragment under none of NFR-1's three budgets (the
`archive-task.sh` diff, B-1 ≤35, FR-8's list ≤15) and at 89 against F.2's 200.
`.harness/rules/85-design-discipline.md:46-51` prices **machinery** and **bulk**: prefer data over
machinery, reuse an existing seam, prefer deleting, count what every future reader must hold in
their head. The clause adds no file, no concept, no mechanism and no second home for a judgment —
it extends a paragraph that already tells the reader how to treat a verdict, and what a future
reader must now hold is one more true fact about a check they were already being told to run. The
ledger is unmoved. It earns its line.

## 4. Carried forward unchanged from round 1

**AC-5's identity.** With `H` non-bullet lines, `C` bullets, `h` harvested: on the rewrite path the
file becomes `total_after − r` lines, so `wc -l − 30 = total_after − 30 − r`, digit for digit the
expression at `archive-task.sh:98`; on the clamp-to-zero path the `elif` appends, the file becomes
`total_after` lines, and the same expression yields `total_after − 30 − 0`. Both of AC-5's fixtures
close.

**C-3's three residuals.** (i) `wc -l` 31 with an unterminated final line, `h = 1` → rotate 2 → 31
lines, all terminated, F.4 WARN — count divergence. (ii) `wc -l` 32 with `H = 0`, `h = 1` → rotate 3
→ `echo "$header"` on an empty `header` writes one empty line → 31, WARN — a line added, none lost.
(iii) verified first-hand: `test/t27/c3iii/.harness/insight-index.md` holds **29** lines, the
mid-file marker sits at line **9** (was 19), the trailing blank is gone; 33 → 29 with F.4 PASSing
over a file that lost a line and reordered another. Stage 4's "content loss, not count divergence"
is the right wording, and the repair is `:118`, inside the frozen range.

**E-1b's basis.** Bash exempts a failing command inside an `&&` list from errexit unless it follows
the final `&&`. At `test/t27/head-v2b/.harness/scripts/archive-task.sh:82` the failing command is
the `[[ … ]]`, so HEAD completes a `--dry-run` with no index at exit 0. The edit still stands on
C-1 and K-4; the sentence justifying it does not. RES-4 is the part that is not optional: an insight
line outlives the task in a file every task reads at start, and writing that false claim into
`.harness/insight-index.md` would be this task committing its own defect class on the way out.

## 5. CR-10 — the arithmetic, and why it is worth a line

`04_RATIONALE.md:198-212` is stage 4's size ledger. Its E-3 row still reads `35 / 0`, its total row
`64 / 6`, and its closing paragraph "`.harness/rules/80-delivery-policy.md` = 88". The round-2 delta
adds exactly one line to that file and nothing else, so the true figures are `36 / 0`, `65 / 6` and
**89** — which is what `04_DEVELOPMENT.md:24` and `:28` now say, and what I counted on disk (the
file's last line is `:89`). The decomposition against E-3's `+30` estimate is now: 3 lines of C-10's
re-scoping, 2 lines of wrap, 1 line of CR-1's clause.

It is a non-binding portion and the contract beside it is right, so nothing downstream is forced
into error. I raise it because the rationale is where stage 6 will look for the per-edit breakdown
when it re-measures under RES-1, because a reader comparing §6's "= 88" against the 89-line file
learns to distrust the ledger, and because this task's entire subject is a harness artifact whose
stated number no longer matches the file it describes. Three characters.

CR-11 is the same shape one document over: `04_DEVELOPMENT.md:23` says the `## When to read this`
bullet landed at `:15`, but `70-doc-size.md:14` is "Before pasting evidence into a stage doc…" and
the boundary-rule bullet is `:16`. My round-1 E-2 row cited `:16` and I did not notice the row said
`:15` — CR-3 named only the two section addresses, so the developer's re-measurement pass, which was
faithful to CR-3's scope, had no reason to touch it. Recording it now rather than leaving a fourth
round to find it.

## 6. C-10's two imprecisions, still not acted on

Both inside `80-delivery-policy.md:68-74`, both re-checked this round, neither false enough to spend
a re-wording on.

(a) `:195-227` is cited for "no marker preservation and no backup". That loop also holds a
template-missing branch (`upgrade-project.sh:198-208`) that **retains** the project's copy and emits
`NOOP`/`GAP`. The landed sentence is scoped by "with the plugin's current template when the two
differ", which presupposes a template exists, so the clause is vacuous there rather than false.

(b) "it is spliced, HALTs on unmarked custom `B.*` checks, and gets a timestamped `.bak`
(`:548-556`)". The splice is `:535-542` and the `.bak` write is `:571-573`; `:548-556` is the HALT
branch, whose own message names the `.bak`. All three statements are true of the file; only the
address is loose, and CR-4 already puts every address in this paragraph on the pool row.

What C-10 exists for is correct: `refresh_set` (`:186-194`) names exactly the seven pairs the
sentence lists, and `verify_all.{sh,ps1}` appears only in `known` (`:141`), with `:136-138` stating
the invariant. The fragment asserts nothing false of `verify_all`.

## 7. What I still could not execute

No Bash tool in either round. `git diff`, `git status`, `wc`, `sha256sum` and every re-run of
`verify_all` were unavailable, so stage 4's numeric claims were audited by reading the artifacts they
describe and re-deriving the arithmetic. This round I read `80-delivery-policy.md`,
`70-doc-size.md`, `archive-task.sh`, `AI-GUIDE.md` and `.harness/insight-index.md` end to end and
counted their lines from the numbered output; every count agreed with stage 4 except the three in
`04_RATIONALE.md` §6 (CR-10). The `.ps1` line at `:74` and `verify_all.sh:213-219` are unchanged in
form. RES-1 remains a measurement obligation on stage 6, not a finding against the developer:
nothing I read suggests a discrepancy in the diff itself.
