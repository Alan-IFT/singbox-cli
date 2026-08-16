# 01 — Requirement Analysis · T-32 `record-accuracy-sweep`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

Eleven filed rows (R-63, R-74, R-77, R-78, R-79, R-82, R-83, R-84, R-85, R-91, R-94) each name a
shipped sentence that claims something this repository's code does not do; every one of them is
re-verified against the current tree, the ones still false are corrected so the corrected sentence
is true of the code it describes, the ones already discharged are reported rather than edited, and
nothing else is added.

## In-scope behaviors

**FR-1** — Each of the eleven rows is classified against the current tree as **ALREADY CLOSED**,
**LIVE**, **LIVE BUT DIFFERENT FROM FILED**, or **NOT A PROSE DEFECT**, and the classification is
established by reading the artifact and the code the sentence describes, never by inheriting the
row's own description. A row classified ALREADY CLOSED is edited nowhere.

**FR-2** — R-77, R-78 and R-84 are reported as **ALREADY CLOSED**: the mandated fixture-loader
recipe already reads its source with an explicit UTF-8 encoding, already names the failure signature
a context that skips the recipe meets, and already names which commands reach `_init_files()`. The
delivery names, for each, the discharging task and the current text that discharges it, and shows
that this task changed no byte of the recipe block or of those clauses.

**FR-3** — R-63: `bin/sc` states, where an editor of the share-URL parsers meets it, that the
`_userinfo` docstring's uniqueness claim holds only while the last-`@` split inside the
shadowsocks parser keeps exactly one consumer, and that this consumer treats the split's product as
a base64 candidate rather than as a userinfo field. The statement changes no executable line.

**FR-4** — R-79: the dev-map's `backslashreplace` cost clause states that the displaced
`surrogateescape` round-trip has never been observable at either site the clause names, because on
the build that carried `surrogateescape` the run ended earlier at an `sc`-authored non-ASCII
character under the same locale — i.e. the clause states the price as **prospective**, binding a
future site rather than recording a loss any shipped build took.

**FR-5** — R-82: the dev-map file-map row for the Clash API states **both** clauses of
`stored_delays()`'s `port` contract — that `port=None` means the port `main()` resolved **and**
"judge liveness yourself", and that a caller naming a port asserts it has already established the
API answers — so the three places that state the contract agree.

**FR-6** — R-83: the AAAA PROBLEM sentence names the condition that produces it (the first
`dns.rules` element on disk is not the one this build emits for this decision) and distinguishes the
causes `sc reload` repairs from the causes regeneration reproduces. Any directive enumeration it
carries is exactly the set of directives that can change that first element, established from the
directive applier's own behaviour. The English key and its `zh` entry change together and carry the
same placeholder set.

**FR-7** — R-85: the changelog lead for T-26 states the exit-code effect as the transitions the
build can produce rather than as a direction, and every transition it states is derivable from
`sc doctor`'s class-to-exit mapping together with the row-class changes T-26 made. The replacement
wording filed with the row is adopted only if it survives that derivation.

**FR-8** — R-91: in rule 80's durability section, each clause about `upgrade-project.sh` — the
refresh set, the replacement loop, the exclusion of `verify_all.{sh,ps1}` from that set, the splice,
the HALT on unmarked custom checks, and the timestamped backup — resolves to the code that
implements that clause, or names the mechanism in words with no range at all. No clause shares a
citation with a clause it does not cover.

**FR-9** — R-94, whose population is **five** clauses rather than the three filed: every document
that states a count of `bin/sc`'s repointable path constants states the count that constant set
actually has; every document that states the committed assertion count states the count the suite
actually defines and the floor actually carries; and rule 50's manual-verification preamble names
only a check that is still a SKIP. `bin/sc`'s own "eighth" wording is not edited.

**FR-10** — R-74 receives a **ruling**, recorded on the task board as the row's disposition: R-74
**does not close here**. It stays open as a standing practice with no code owner, in the shape R-22
is already carried; its row text is amended in place to record that its eleven filed instances were
swept by T-32 and that instance discharge is not row closure. The amended row states no verified
guarantee about future sentences.

**FR-11** — The sweep adds no mechanism: no script, no template, no linter, no doc-lint, no
`verify_all` step, no new file whose purpose is to prevent prose drift. The decline is recorded once
in `.harness/rejected-decisions.md` with the two precedents it rests on and the R-74 ruling that
follows from it.

**FR-12** — The task board records the disposition of each of the eleven rows, and `docs/tasks.md`
is brought under its size cap by rotating **completed** rows into `docs/tasks-archive.md` before
anything is added; no open row is displaced to make room.

## Out of scope

1. R-89, R-90 and R-92 — the index-rewrite defects in `archive-task.sh`, blocked on the owner's R-87
   decision about the 425-line upstream rewrite.
2. R-86 — `guard-rm.sh` refusing `rm`-free commands; T-27's scope ruling stands, the bypass is never
   set, and this task does not re-litigate it.
3. R-109 — the fenced loader block carrying neither half of the capability denial. It is not on the
   list, and because FR-2 edits nothing in that block the sweep neither collides with it nor
   duplicates it; the delivery states that explicitly.
4. R-98 and R-106(a)-(b) — same class as the eleven, assigned to T-32 by the board, excluded from
   this contract by the PM's ruling on Q-8: the scope is not widened.
5. R-106(c) — `_warn_drift()`'s wording on a rejected run; upstream-ruled by T-30's BC-5 and
   recorded so a sweep does not re-discover it as a defect.
6. R-110(a)-(b) — amending T-31's own requirement text and `CONTEXT.md`'s **claim surface** entry.
7. Any behavioural change: no statement added, removed or reordered in `bin/sc`, `install.sh`,
   `uninstall.sh` or `.harness/scripts/*`; the emitted `config.json` is byte-identical.
8. `bin/sc`'s "seven repointable path constants … as the eighth" comment, by the row's own
   instruction.
9. `.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md`.
10. `verify_all.ps1` and the Windows mirror (R-107).
11. `/etc/sing-box`, `/var/lib/sing-box`, the installed `/usr/local/bin/sc` and the live service.

## Boundary conditions

**BC-1** — A row whose sentence is already true of the code → no edit anywhere; the row is reported
as attrition with the text and the code that discharge it.

**BC-2** — A row that turns out to be a **code** defect wearing a prose disguise → the sweep stops
at that row, files it, and does not weaken the sentence to match the defect. The standard is T-26's
closure of R-48: a claim is narrowed only after the stronger claim is proved never to have been
available.

**BC-3** — A row whose filed repair is itself false of the code → the filed repair is refuted in
writing and the correction is derived from the code instead. This condition is **live for R-83 and
R-85**, and a delivery that adopts either row's filed wording without testing it fails AC-8 and
AC-11.

**BC-4** — A corrected sentence that is user-facing → the English key and the `zh` entry change in
the same commit, the placeholder set is unchanged, and every README carrying the same sentence is
corrected with it; where no README carries it, the delivery records the search that establishes so.

**BC-5** — A line carrying `失败：` or `failed: ` → not changed by this sweep. If a repair would
touch one, the change to the diagnostic grep is stated rather than made silently (R-75).

**BC-6** — `docs/tasks.md` at its 300-line cap → rotate completed rows into the archive first; a
rotation never closes a row, and each rotated block keeps a one-line pointer at its old site.

**BC-7** — An edited rule fragment → each `.harness/rules/*.md` file stays at or below 200 lines
(F.2), and `AI-GUIDE.md` keeps indexing every fragment (E.5); no fragment is added or renamed.

**BC-8** — A criterion that needs root, the installed `sc`, or the live service → QA reports
**BLOCKED and files a row**; nothing is substituted for it.

**BC-9** — A criterion that would need `bin/sc` imported → it is re-stated so reading settles it. If
one genuinely cannot be, it runs only through `verify_all` B.4 (the mandated recipe plus T-31's
two-half denial), and the delivery states why reading could not settle it.

**BC-10** — A row citing a line number that has drifted → the repair re-anchors the claim to the
artifact by name; line numbers appear only in backward-looking evidence, never in a corrected
sentence whose subject can move.

**BC-11** — `verify_all` reports a FAIL → the task stops and reports; a FAIL is never carried into
delivery, and the batch stops on this, its last row.

**BC-12** — No stage document, commit message or corrected sentence contains a real credential,
share link or key (`verify_all` A.1).

## Acceptance criteria

Class **[S]** = established by reading a named artifact; **[B]** = established by running something
and reporting its output. Every row is checked against the code the sentence describes, never
against the row's description of it.

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | The clause FR-3 adds is true of the delivered `bin/sc`: inside the shadowsocks parser the value bound by the last-`@` split has exactly one consumer, and that consumer is the base64 decode helper. | [S] | Enumerate every use of that binding in the delivered `parse_ss`; count is 1 and the use is the decode. A criterion satisfied by the clause merely existing FAILs. |
| AC-2 | FR-3's clause costs zero executable lines: `bin/sc`'s statement list is unchanged. | [B] | `python3 -m py_compile bin/sc` exits 0; `git diff -- bin/sc` reviewed hunk by hunk shows only comment, docstring and user-facing-sentence text; B.4 reports `19 defined, 19 run, 19 passed`. |
| AC-3 | FR-4's rewritten cost clause is true of the build it describes: at each site the clause names, the pre-`backslashreplace` build ended the run at an earlier `sc`-authored non-ASCII write under `LC_ALL=C PYTHONUTF8=0`, so no shipped build rendered undecodable-byte data there. | [B] | `git show <pre-T-25 commit>:bin/sc` and trace, **in the retrieved text**, the earlier non-ASCII write reached on the same run at each named site. No stage of this task executes an `sc` — historical, current or installed — as a program: `sc` elevates at import by re-execing a hard-coded absolute installed path with the caller's argv, so neither a historical copy nor a scratch tree contains what would run, and the act is refused under NFR-4. Where source order cannot settle a site, that site's outcome is **BLOCKED and a row is filed** per BC-8; nothing is substituted for it. Never cite T-25's report as the check. |
| AC-4 | FR-5's rewritten row is true of `stored_delays()` as delivered: the liveness guard fires only when no port is named, so a named port is not overridden by it. | [S] | Read the guard and the docstring in the delivered `bin/sc`; confirm the file-map row, the utilities row and the docstring now state the same two clauses. |
| AC-5 | FR-6's rewritten sentence is true of the directive applier as delivered: the set of directives it names is exactly the set that can change `dns.rules`' first element. | [S] | Enumerate the five directives against the applier's own insert positions; a directive that cannot reach index 0 is not named as one that can. |
| AC-6 | FR-6's rewritten sentence offers `sc reload` only for causes regeneration repairs, and says so for the causes regeneration reproduces. | [S] | Read the composition order in the delivered `bin/sc` (the user override is merged last, on every run) and confirm the sentence does not promise repair for an override-caused displacement. |
| AC-7 | FR-6's `zh` entry renders the same facts with the same placeholder set as its English key. | [B] | B.4's placeholder-subset assertion PASSes over the delivered `TRANSLATIONS`; the pair is read side by side. The doctor probe is **not driven** from a test — the loader recipe forbids it — and the delivery states that. |
| AC-8 | R-83's filed characterisation is tested rather than inherited: the delivery states, with the applier's behaviour as evidence, how many directives reach the row and whether the filed "four" holds. | [S] | The stated count is re-derived independently at review; a delivery that reproduces "four" without that derivation FAILs. |
| AC-9 | FR-7's rewritten lead states **exactly** the exit-code transitions derivable from `sc doctor`'s class-to-exit mapping together with the row-class changes T-26 made: no transition it states is underivable, **and no derivable transition is absent from it**. | [S] | For each doctor row constructor in the delivered `bin/sc`, enumerate the classes it can return; derive worst-class → exit before and after T-26's change over **every** doctor row the T-26 changelog entry names as changed, not a subset of them; compare the derived set against the lead's set **in both directions**. A lead stating a strict subset of the derived set FAILs, exactly as one stating an underivable transition does. |
| AC-10 | The derivation in AC-9 explicitly decides the case of a host that carries at least one UNKNOWN row, no PROBLEM row, and a `dns.rules` head this build would not emit. | [S] | Name that host's before/after exit pair and whether it is reachable; the answer appears in the delivery, not only in the reasoning. |
| AC-11 | R-85's filed replacement wording is adopted only after AC-9's derivation; if the derivation refutes it, the delivered lead says something the derivation supports instead. | [S] | Compare the delivered lead against AC-9's transition table; a lead adopting the filed wording while the table contradicts it FAILs. |
| AC-12 | Each clause of FR-8's rewritten durability section resolves to the code implementing that clause in the delivered `upgrade-project.sh`. | [S] | Read every cited range in the delivered tree and name what is there; the splice, the HALT branch and the backup write are each covered by a citation that contains them, or by no citation at all. |
| AC-13 | Every delivered document stating a count of repointable path constants states the number of `Path`-valued constants in `bin/sc`'s paths section that are referenced only inside function bodies. | [S] | Enumerate those constants in the delivered `bin/sc` and compare with each document's number; the enumeration is listed, not asserted. |
| AC-14 | Every delivered document stating the committed assertion count states the number the suite defines and the floor carries. | [B] | Count the suite's test tuple in the delivered tree, read `baseline.json`'s `test_count`, and read B.4's own `N defined` line from a `verify_all` run; all three agree with every document. |
| AC-15 | Rule 50's manual-verification preamble names only a check that is still a SKIP in the delivered `verify_all.sh`. | [B] | Read the step list from a full `verify_all` run and compare with the preamble's wording. |
| AC-16 | R-77, R-78 and R-84 are discharged in the tree and untouched by this task: the recipe reads its source with an explicit encoding, names the exit-2 argparse signature, and names the read-only command pair — and each is true of `bin/sc` as delivered. | [S] | `git diff -- docs/dev-map.md` shows no hunk inside the recipe block or its clauses; the auto-elevate line re-execs the installed path with the caller's argv; the read-only arm names exactly the two commands the clause names. |
| AC-17 | The R-74 ruling is recorded with its reasoning, and the amended row is true of the tree: no code owner exists for it and each of its eleven instances carries the disposition FR-1 gave it. | [S] | Read the amended row against the FR-1 classification table; a ruling stated as an aside rather than as a disposition FAILs. |
| AC-18 | The delivered diff adds no check, script, template or `verify_all` step. | [B] | `git diff --stat` over the delivery commit against rule 80's process-path list plus this task's product files; a full `verify_all` run reports the same step set as the task-start baseline, with no step added. |
| AC-19 | `bash .harness/scripts/verify_all.sh` returns **no FAIL** over the delivered tree, with F.2, F.5 and E.5 all PASS. | [B] | One full run, output recorded; the task-start baseline is **measured, not inherited** (see Q-7). |
| AC-20 | Every user-facing correction lands in both languages, and no line carrying `失败：` or `failed: ` is changed. | [B] | Search the delivered tree for both literals and diff the result against the change set; where a README carries no counterpart of a corrected sentence, record the search that shows it. |
| AC-21 | The live host is untouched. | [B] | `systemctl show -p MainPID -p NRestarts -p ActiveEnterTimestamp sing-box` before and after, values identical (`is-active` never invoked); `/etc/sing-box` and `/var/lib/sing-box` unmodified. |

## Non-functional requirements

**NFR-1** — The change is prose only: outside process-path files, no statement in any executable
artifact is added, removed or reordered. The only `bin/sc` changes permitted are comment/docstring
text and the text of one existing user-facing sentence with its `zh` entry.

**NFR-2** — Changed lines outside rule 80's process-path list stay at or below **30**, enumerated
per row at stage 2 (R-63 ≈2 · R-79 ≈3 · R-82 ≈1 · R-83 ≈5 · R-85 ≈1 · R-91 ≈3 · R-94 ≈5). A larger
number is argued against rule 85's burden of proof, never taken silently.

**NFR-3** — `bin/sc`'s sha256 changes with this task (FR-3 and FR-6 both touch it). No delivered
document claims `bin/sc` is byte-identical at HEAD after this task; every existing citation of
T-31's digest stays a past-tense statement about T-31 and is left alone.

**NFR-4** — No stage of this task imports `bin/sc` outside `verify_all` B.4, and no stage runs the
installed `sc`.

**NFR-5** — Every claim in the stage documents that needed a run and did not get one is marked as
owed rather than presented as measurement (the T-30 stage-5 standard).

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Does R-63's repair edit `bin/sc`, given the prose-only boundary? | Yes. The clause lands in `bin/sc` beside the parser it protects, as comment or docstring text, changing zero executable lines. A dev-map clause is not a substitute: the trap is sprung by an editor reading the parser, not the map. |
| Q-2 | Is R-83's repair — rewriting a shipped user-facing string and its translation — inside the prose-only boundary? | Yes. It replaces the text of one sentence a user reads and its `zh` entry, adds and removes no statement, and leaves the emitted document byte-identical. It is not a behaviour change and not a mechanism. |
| Q-3 | Is R-83's filed characterisation ("four directives reach it, and the advice is ineffective for `$replace`") adopted? | No. The correction is derived from the directive applier: only directives that can change `dns.rules`' first element reach the row, and `sc reload` is reproduced-not-repaired for **every** override-caused displacement, not only one. The filed count and the filed exception are tested at AC-5/AC-6/AC-8, not inherited. |
| Q-4 | Is R-85's filed replacement wording (「没有哪台机器的退出码会变小」) adopted? | No, not as filed. It is admitted only if AC-9's derivation supports it; the analyst's reading of the exit mapping finds a host class whose exit moves from 2 to 1, which refutes it as written. The delivered lead states the transitions the derivation supports. |
| Q-5 | Does R-74 close here? | **No.** R-74 stays open as a standing practice with no code owner, in the shape R-22 is carried, and its row is amended in place to record the T-32 sweep as instance discharge. Reasoning: the row has no closure predicate, the only mechanism that would give it one is declined (Q-6), and closing it would replace eleven corrected instances with a claim about future sentences — the exact over-claim R-74 names. |
| Q-6 | Does this task add a mechanism that prevents prose drift? | No. A check, a linter, a template or a `verify_all` step is declined on the merits and the decline is recorded once in `.harness/rejected-decisions.md`, citing T-27 (which designed a routing table and then **deleted** it once it proved unnecessary) and T-31 (which closed R-95 and R-96 with a written boundary at zero executable lines). |
| Q-7 | Which `verify_all` baseline do downstream stages compare against? | The one measured at task start over this tree, not the figure carried in the dispatch: `baseline.json` reads `test_count` **19** (raised by T-31 in the same commit as its 19th assertion), and the suite defines 19. A criterion written against 18 would pass a lowered floor and is refused. |
| Q-8 | R-98 and R-106(a)-(b) are assigned to T-32 by the board but are not on the operator's list, and T-32 is the programme's final task — are they in scope? | **Not in this contract.** T-32's scope is the eleven; these rows carry no FR and no AC here. This is the PM's ruling to widen or to re-home, and a widening arrives as an amendment naming which FR and which AC each row adds — this document does not carry them silently either way. Evidence for the ruling, including the fact that R-98(a)'s population is **six** sites rather than the two filed, is in `01_RATIONALE.md`. |
| Q-9 | A schema gap: the operator directed one item to be raised "as an open question, not decided", while this contract may carry no unanswered question. | Recorded as a schema-gap row here rather than by inventing a section: Q-8 answers the **scope** question (which is this stage's to answer) and leaves the **disposition** question to the PM, which is the only shape in which both instructions hold. |

## Verdict

READY
