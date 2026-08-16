# 02 — Solution Design · T-32 `record-accuracy-sweep`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

1. Seven shipped sentences in five files are rewritten so each states the property its subject
   cannot move away from; **no executable statement is added, removed or reordered anywhere**, and
   `bin/sc`'s only changes are comment text plus the text of one user-facing key and its `zh` twin.
2. Unchanged: the `docs/dev-map.md` loader recipe block and its four clauses (R-77/R-78/R-84),
   `bin/sc`'s own "as the eighth" comment, every line carrying `失败：` or `failed: `, the emitted
   `config.json`, and `docs/dev-map.md:76`'s past-tense `18 defined … T-30` measurement.
3. The seam is the **repair shape**, not a module: four of the seven rows are a sentence anchored to
   an enumeration or a coordinate its subject can move (R-83's directive, R-91's four ranges,
   R-94's two copied counts), and each is repaired by naming the property the anchor stood for. The
   one abstraction behind all eleven is R-74's practice, which stays a board row — building it as a
   mechanism is declined (FR-11) and argued in `02_RATIONALE.md` §4.

## Change ledger

Budget column = ceiling on physical lines whose content differs, per K-1. Files marked *process
path* are rule 80 process paths and do not count against NFR-2's 30.

| id | absolute path | new/edit | what changes | budget | partition |
|---|---|---|---|---|---|
| E-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | R-63: comment clause immediately above `parse_ss`'s last-`@` split, recording that the split's product has exactly one consumer and is a base64 candidate, not a userinfo field (I-1) | ≤3 | dev |
| E-2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | R-83: the AAAA PROBLEM sentence — `TRANSLATIONS` key + its `zh` value, and the identical key at the `_doctor_ipv6()` call site (I-2) | ≤6 | dev |
| E-3 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | R-79: the `backslashreplace` cost clause states the price as prospective (I-3) | ≤1 | dev |
| E-4 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | R-82: the `# Clash API` file-map row states both clauses of `stored_delays()`'s `port` contract (I-4) | ≤1 | dev |
| E-5 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | R-94(a): the `# Paths` row states **nine**, enumerates them including `LIB_DIR`, and qualifies the "referenced only inside function bodies" clause for `CFG_DIR` (I-5) | ≤1 | dev |
| E-6 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | R-94(d): the `check-sc-contracts.py` utilities row states **no** assertion count; it keeps its existing pointer to `baseline.json`'s floor (I-6) | ≤1 | dev |
| E-7 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | R-85: the T-26 entry's exit-code lead states the derived transition set instead of a direction (I-7) | ≤1 | dev |
| E-8 | `/home/alan/Programs/singbox-cli/.harness/rules/80-delivery-policy.md` | edit | R-91: the durability paragraph names each mechanism in words and carries **zero** line ranges into `upgrade-project.sh` (I-8) | ≤4 | dev |
| E-9 | `/home/alan/Programs/singbox-cli/.harness/rules/50-singbox-cli.md` | edit | R-94(b): the Test bullet states no assertion count (I-6); R-94(c): the manual-verification preamble names only B.3 (I-9) | ≤2 | dev |
| E-10 | `/home/alan/Programs/singbox-cli/docs/tasks.md` | edit | *process path*: R-94(e) count clause; R-74 row amended in place (FR-10); FR-1 disposition of all eleven rows; rotation per M-1; T-32's completed row | — | dev |
| E-11 | `/home/alan/Programs/singbox-cli/docs/tasks-archive.md` | edit | *process path*: receives every block/row rotated by M-1, verbatim, none closed by moving | — | dev |
| E-12 | `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` | edit | *process path*: one appended entry recording FR-11's decline, its two precedents and the R-74 ruling that follows from it (I-10) | — | dev |
| E-13 | `/home/alan/Programs/singbox-cli/docs/features/record-accuracy-sweep/04_DEVELOPMENT.md` | new | *process path*: the developer's stage doc; carries the AC-8 directive derivation and the AC-9/AC-10 transition table (I-11) | — | dev |
| E-14 | `/home/alan/Programs/singbox-cli/docs/features/record-accuracy-sweep/04_RATIONALE.md` | new | *process path*: written **only if** the developer has non-empty rationale; measurement narratives and refutations land here | — | dev |

No other file is touched. A file the developer must touch that has no row here is a design defect —
report it rather than editing silently.

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | comment lines above `parse_ss`'s `body.rsplit("@", 1)` in `bin/sc` | two clauses: (a) this second last-`@` split is not a second userinfo reading — its product is a **base64 candidate** whose sole consumer is the decode helper on the next line; (b) giving that binding a second consumer that treats it as a userinfo field falsifies `_userinfo`'s "no other site" claim | true of the delivered `parse_ss`: the binding has exactly **one** use and that use is the base64 decode. Costs zero executable lines |
| I-2 | the AAAA PROBLEM translation key (`TRANSLATIONS` entry + the `_doctor_ipv6()` call site) and its `zh` value | four clauses in order: `{decision}`; the condition (the first `dns.rules` entry on disk is not the rule this build emits for that decision); `sc reload` offered **only** for a stale or hand-edited document; and, for a `{override}` that puts a rule of its own at the head, that regeneration reproduces it so the override is what to change. Placeholder set exactly `{decision}`, `{override}`. **Names no directive** | every clause is true of the delivered `_apply_directive` / `generate_config` composition order; the English key appears exactly twice in `bin/sc`; the `zh` entry carries the same placeholder set; neither string carries `失败：` or `failed: ` |
| I-3 | `docs/dev-map.md`'s `backslashreplace` cost clause | the existing cost statement plus one clause: the price is **prospective** — at both sites the clause names, the pre-`backslashreplace` build ended the run earlier under the same locale at an `sc`-authored non-ASCII write, so no shipped build rendered undecodable-byte data there; what is displaced binds the next site to reach a printed line | derivable by reading the pre-`backslashreplace` `bin/sc` in source order at both named sites — no run, no citation of T-25's report |
| I-4 | `docs/dev-map.md`'s `# Clash API` file-map row, its `port=` tail | both clauses: `port=None` means the port `main()` resolved **and** "judge liveness yourself"; a caller that names a port asserts it has already established the API answers, and only `sc doctor` names one | the three statements of the contract (this row, the `stored_delays()` utilities row, the docstring) say the same two things; the liveness guard in the delivered `bin/sc` fires only when no port is named |
| I-5 | `docs/dev-map.md`'s `# Paths` section row, its repointable-constants clause | **nine** `Path` constants, enumerated by name including `LIB_DIR` (added by T-28, hence `bin/sc`'s own "eighth" wording is the historical statement it is); the "referenced only inside function bodies" property is asserted of the eight that have it, with `CFG_DIR` named as also read at module level to derive six siblings — which is why repointing it alone moves nothing and the recipe repoints all nine | every clause checkable by enumerating the `# Paths` section of the delivered `bin/sc`; both readings of AC-13 (eight under its literal predicate, nine as the repointable set) are satisfied by the same sentence |
| I-6 | `docs/dev-map.md`'s `check-sc-contracts.py` utilities row and `.harness/rules/50-singbox-cli.md`'s Test bullet | neither states a number of assertions; both keep their existing pointer to `baseline.json`'s `test_count` floor | no delivered document outside `baseline.json` states the committed assertion count, so no document can state it wrongly at the next assertion added |
| I-7 | `CHANGELOG.md`'s T-26 entry, its exit-code lead | the mapping is a label set, not a magnitude, so no direction claim is available; then the derived transition set — `0 → 1`, `2 → 1`, `1 → 2` — and that a host already carrying a PROBLEM row is unchanged | every transition stated is derivable from `sc doctor`'s class→exit mapping and the row classes T-26 changed; the filed replacement 「没有哪台机器的退出码会变小」 is refuted in writing, not adopted |
| I-8 | `.harness/rules/80-delivery-policy.md`'s durability paragraph | six clauses, each naming a mechanism as a token greppable in the arriving text — the `refresh_set` array, the loop that follows it, the `known` array's hand-maintained invariant comment, the `VERIFY-SPLICE` branch, the `VERIFY-HALT` branch, the `.bak-<stamp>` copy — and **no line range into `upgrade-project.sh`** | every named token resolves in the delivered `upgrade-project.sh` by grep; no clause shares an anchor with a clause it does not cover; a refresh that keeps a mechanism keeps its anchor, and one that removes it makes the grep fail loudly instead of pointing at the wrong lines |
| I-9 | `.harness/rules/50-singbox-cli.md`'s manual-verification preamble | names only B.3 | B.3 is the only step reported SKIP by a full `verify_all.sh` run over the delivered tree |
| I-10 | `.harness/rejected-decisions.md`, one appended `## <slug>` entry in the file's existing three-bullet shape | Decision (no check, linter, template, doc-lint or `verify_all` step for prose drift) · Why (nine of eleven are semantic claims no committed check can decide; the two that are counts already have a mechanism in B.4's own `N defined` line, and I-6 removes their copies; T-27 and T-31 as precedents) · Origin (T-32, this document) | one entry, not one per row; states no guarantee about future sentences |
| I-11 | `04_DEVELOPMENT.md`, two required tables | (a) the five directives against `_apply_directive`'s own insert positions, with the count that reaches `dns.rules`' first element and an explicit verdict on the filed "four"; (b) the exit-code transition table: per changed doctor probe, the classes it can return before and after T-26, worst-class → `DOCTOR_EXIT`, with the UNKNOWN-no-PROBLEM host's pair named and its reachability decided | both derived from the delivered `bin/sc` plus `git show` of T-26's commit and its parent; neither adopts a filed characterisation |

## Constraints

**K-1** — The developer counts NFR-2's budget as physical lines whose content differs (a rewritten
line counts once, its deletion is not counted again), summed over `bin/sc`, `docs/dev-map.md`,
`CHANGELOG.md` and the two rule fragments only; the total stays ≤ **30** and each file stays within
its ledger ceiling.

**K-2** — The developer adds, removes and reorders **no** executable statement in `bin/sc`:
`python3 -m py_compile bin/sc` exits 0 and B.4 reports `19 defined, 19 run, 19 passed`.

**K-3** — The developer changes the English key and its `zh` entry in the same commit, keeps the
placeholder set exactly `{decision}` and `{override}`, and verifies by grep that the new English
string occurs **exactly twice** in `bin/sc` — once as the `TRANSLATIONS` key and once at the call
site — because a key that drifts from its call site renders English to every `zh` user and no
committed assertion catches it.

**K-4** — The developer changes no line carrying `失败：` or `failed: `; if a repair would touch
one, the developer states the change to R-75's diagnostic grep in `04_DEVELOPMENT.md` and does not
make it.

**K-5** — The developer puts no line number, line range or file coordinate inside any corrected
sentence whose subject can move; coordinates appear only as backward-looking evidence inside stage
documents.

**K-6** — The developer names no override directive in the shipped AAAA sentence and states the
directive derivation in `04_DEVELOPMENT.md` instead, so the sentence names the effect (a rule of the
user's at the head) rather than a mechanism a future directive would falsify.

**K-7** — The developer leaves zero line ranges into `upgrade-project.sh` in rule 80's durability
paragraph and confirms each named token by grep against the delivered script.

**K-8** — The developer leaves no committed-assertion count in `docs/dev-map.md` or
`.harness/rules/50-singbox-cli.md`; `baseline.json`'s `test_count` (19) stays the one home of that
number, as `CONTEXT.md`'s **assertion floor** entry already requires.

**K-9** — The developer states the R-85 lead's transitions only after deriving them from the
delivered class→exit mapping and T-26's own diff, and records the refutation of the filed
replacement wording rather than silently dropping it.

**K-10** — The developer rotates only rows already closed (including those this task closes) plus
completed-task rows, leaves exactly one pointer line at each rotated block's old site, displaces no
open row, and measures `wc -l docs/tasks.md` ≤ **300** after the additions.

**K-11** — The developer adds no file, script, template, linter, `verify_all` step or check of any
kind, and records the decline once, in `.harness/rejected-decisions.md` only.

**K-12** — The developer never runs a historical or installed `sc`, never imports `bin/sc` outside
`verify_all` B.4, never writes under `/etc/sing-box` or `/var/lib/sing-box`, and witnesses the live
service with `systemctl show -p MainPID -p NRestarts -p ActiveEnterTimestamp sing-box` — never
`is-active`.

**K-13** — The developer treats every quotation of a corrected sentence in
`docs/features/_archived/**` as a historical record and edits none of them.

**K-14** — QA reports **BLOCKED and files a row** for any criterion needing root, the installed
`sc` or the live service, and substitutes nothing for it.

**K-15** — The delivery states, for R-77, R-78 and R-84, the discharging task (established by
`git log -S` over the clause text, not inferred) and the current text that discharges it, and shows
`git diff -- docs/dev-map.md` has no hunk inside the recipe block or those clauses.

## Frozen set

| path | why frozen |
|---|---|
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` — the fenced loader recipe block and its four trailing clauses | FR-2: R-77/R-78/R-84 are ALREADY CLOSED and edited nowhere; R-109 lives in that block and is out of scope |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md:76` — `18 defined / 18 run / 18 passed when last measured, T-30` | a backward-looking measurement, attributed to the task that took it, in a sentence that already says the count is whatever `baseline.json` currently carries; correcting it would falsify a true past-tense statement |
| `/home/alan/Programs/singbox-cli/bin/sc` — the `# Paths` comment ending "as the eighth" | out of scope 8, by R-94's own instruction; I-5 makes the dev-map sentence account for it |
| `/home/alan/Programs/singbox-cli/bin/sc` — every executable statement, and every line carrying `失败：` or `failed: ` | NFR-1, BC-5 |
| `/home/alan/Programs/singbox-cli/README.md`, `README.zh-CN.md` | no README carries the corrected AAAA sentence; both describe *what row 4 checks*, which this task does not change (BC-4's search is recorded, not acted on) |
| `/home/alan/Programs/singbox-cli/.harness/scripts/**`, `verify_all.{sh,ps1}`, `baseline.json` | FR-11 / AC-18: no check is added, changed or removed |
| `/home/alan/Programs/singbox-cli/CONTEXT.md` | out of scope 6 (R-110(b)); this design introduces no new domain term |
| `/home/alan/Programs/singbox-cli/docs/features/_archived/**` | historical records; they quote the pre-repair sentences by design |
| `/home/alan/Programs/singbox-cli/.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md` | red line |
| `/etc/sing-box`, `/var/lib/sing-box`, `/usr/local/bin/sc`, the live service | safety |

## Migration & edit sequence

No data or API shape changes; the ordering below exists because two steps have preconditions and one
frees space.

| order | edit ids | precondition | rollback |
|---|---|---|---|
| M-1 | E-10, E-11 | `wc -l docs/tasks.md` measured first; rotate to the archive, in this order, the **T-22 block** (its only row, R-63, closes here), the R-78/R-79 rows, the R-82/R-83/R-84/R-85 rows, the R-91 row and the R-94 row — each block leaving one pointer line. The T-31 completed-task row is **not** rotated (rule 70 Rule 3's threshold is ~30 rows; the table has one, and moving it frees no line) | `git checkout -- docs/tasks.md docs/tasks-archive.md`; nothing was closed by moving |
| M-2 | E-1, E-3, E-4, E-5, E-6, E-9 | none — six independent single-site prose edits | per-file `git checkout --` |
| M-3 | E-2 | I-11(a) derivation written first: the shipped sentence's advice split is a *product* of the derivation, not an input to it | `git checkout -- bin/sc`; `bin/sc`'s sha256 returns to its task-start value |
| M-4 | E-7 | I-11(b) transition table written first, from `git show <T-26 commit>{,^}:bin/sc`; the filed wording is refuted before any lead is written | `git checkout -- CHANGELOG.md` |
| M-5 | E-8 | each token grepped in the delivered `upgrade-project.sh` before the ranges are removed | `git checkout -- .harness/rules/80-delivery-policy.md` |
| M-6 | E-12, E-10 | M-2…M-5 complete, so the decline record and the board dispositions describe what shipped | process-path files only; `git checkout --` |
| M-7 | E-13, E-14 | all of the above | — |
| M-8 | — | `bash .harness/scripts/verify_all.sh` PASS (no FAIL) is the gate; a FAIL stops the batch on its last row and is never carried into delivery (BC-11) | the task stops and reports; no commit |

Backwards compatibility: `bin/sc`'s sha256 changes (NFR-3) and every existing citation of T-31's
digest stays a past-tense statement about T-31. No flag, no migration, no data change; the emitted
`config.json` is byte-identical because no composition input changes.

## Out of scope

1. R-98 and R-106(a)-(b) — PM-ruled out (Q-8); re-homed by the PM at delivery with a live owner.
   No FR, no AC and no ledger row here.
2. R-106(c) — upstream-ruled by T-30's BC-5.
3. R-89, R-90, R-92 — blocked on the owner's R-87 decision.
4. R-86 — T-27's ruling stands; the bypass is never set.
5. R-109 — the fenced loader block; FR-2 edits nothing inside it, so this sweep neither collides
   with it nor duplicates it.
6. R-110(a)-(b), R-107, R-105, R-108, R-111 — not on the list.
7. Any behavioural change, any new mechanism, and any second opinion about a fact the code already
   owns.
8. Rule 80's vendored-fixes table citation into `verify_all.sh` — same hazard class as R-91 but not
   a clause about `upgrade-project.sh`; recorded as RS-2, not repaired.

## Verification plan

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | enumerate every use of the binding `parse_ss`'s last-`@` split produces, in the delivered `bin/sc` | count is 1 and the use is the base64 decode; the added clause says so | AC-1 |
| V-2 | `python3 -m py_compile bin/sc`; `git diff -- bin/sc` reviewed hunk by hunk | exit 0; only comment, docstring and one user-facing sentence in the hunks | AC-2 |
| V-3 | `git log -S 'backslashreplace' -- bin/sc` → the introducing commit's parent; `git show <parent>:bin/sc`; read source order at both sites the clause names | at each site an `sc`-authored non-ASCII write is encoded before any undecodable-byte datum reaches a printed line — settled by reading; the historical copy is **never executed** (K-12) | AC-3 |
| V-4 | read `stored_delays()`'s guard and docstring, the utilities row and the file-map row | the guard fires only when no port is named; all three now state the same two clauses | AC-4 |
| V-5 | enumerate the five directives against `_apply_directive`'s insert positions | three can change element 0 (`$prepend`, `$replace`, `$before` when its anchor resolves to the first element); `$after` (`i+1`, `i ≥ 0`) and `$append` cannot; the filed "four" is refuted in writing | AC-5, AC-8 |
| V-6 | read the composition order in the delivered `bin/sc` against the shipped sentence | the override is merged last on every run; the sentence promises `sc reload` for no override-caused displacement | AC-6 |
| V-7 | a full `verify_all` run; read the en/`zh` pair side by side; grep the new English string in `bin/sc` | B.4's placeholder-subset assertion PASSes; the pair renders the same facts; the string occurs exactly twice; no doctor probe is driven from a test | AC-7 |
| V-8 | `git show <T-26 commit>^:bin/sc` and `git show <T-26 commit>:bin/sc` for the two changed probes; the delivered `DOCTOR_EXIT` mapping and `cmd_doctor`'s `max` | transition table `0 → 1`, `2 → 1`, `1 → 2`, nothing else; every transition in the delivered lead appears in it | AC-9, AC-11 |
| V-9 | the same table, read for the UNKNOWN-no-PROBLEM host with a non-emitted `dns.rules` head | its pair is named as **2 → 1** and its reachability decided in the delivery, not only in the reasoning | AC-10 |
| V-10 | grep each token rule 80's durability paragraph names in the delivered `upgrade-project.sh`; count line ranges in that paragraph | every token resolves; the range count is 0; the splice, the HALT branch and the backup write are each covered by a token that names them | AC-12 |
| V-11 | enumerate `Path`-valued constants in the delivered `bin/sc`'s `# Paths` section and classify each reference as module-level or function-body | nine constants; eight referenced only inside function bodies; `CFG_DIR` also read at module level to derive six — and the delivered sentence states exactly that | AC-13 |
| V-12 | count the suite's `TESTS` tuple; read `baseline.json`'s `test_count`; read B.4's `N defined` line from a full run; grep the delivered tree for a stated assertion count | 19 / 19 / 19; **no** delivered document outside `baseline.json` states a count, so none can disagree | AC-14 |
| V-13 | read the step list from a full `verify_all.sh` run | B.3 is the only SKIP, and rule 50's preamble names only it | AC-15 |
| V-14 | `git diff -- docs/dev-map.md`; read the three clauses against `bin/sc`; `git log -S` for each clause's discharging task | no hunk inside the recipe block or its clauses; each clause true of the delivered `bin/sc`; the discharging task named, not inferred | AC-16 |
| V-15 | read the amended R-74 row against the FR-1 classification table | the ruling is the row's disposition; each of the eleven instances carries its classification; no guarantee about future sentences is stated | AC-17 |
| V-16 | `git diff --stat` over the delivery against this ledger plus rule 80's process-path list; compare the run's step set with the task-start baseline | no path outside both lists; no step added, removed or renamed | AC-18 |
| V-17 | `bash .harness/scripts/verify_all.sh`, one full run, output recorded | PASS 20 / WARN 0 / FAIL 0 / SKIP 1, exit 0, with B.4/B.5/B.6, F.2, F.5 and E.5 all PASS; baseline measured at task start, not inherited | AC-19 |
| V-18 | search the delivered tree for `失败：` and `failed: ` and diff against the change set; record the README search for the corrected sentence | zero intersection; the README search is recorded with its terms and its empty result | AC-20 |
| V-19 | `systemctl show -p MainPID -p NRestarts -p ActiveEnterTimestamp sing-box` before and after | all three values identical; `is-active` never invoked; `/etc/sing-box` and `/var/lib/sing-box` unmodified | AC-21 |
| V-20 | `wc -l docs/tasks.md`; read each rotated block's old site | ≤ 300 and F.5 PASS; every rotated block has exactly one pointer line; no open row moved | FR-12, BC-6 |
| V-21 | sum the changed lines outside the process-path list, per file | ≤ 30 total and within every ledger ceiling | NFR-2 |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RS-1 | AC-13's literal predicate ("`Path`-valued constants … referenced **only** inside function bodies") yields **eight**, because `CFG_DIR` is also read at module level to derive six siblings — while the set every document is about, and that the loader recipe repoints, is **nine**. I-5 satisfies both readings in one sentence rather than blocking; the criterion's wording is still an upstream imprecision worth an amendment if the gate re-uses it | stage 3 gate review; PM if it routes back to stage 1 |
| RS-2 | Rule 80's vendored-fixes table cites `verify_all.sh:213-219` — a coordinate into a file the same refresh event re-lands (spliced). Identical hazard class to R-91, outside FR-8's clause set (it is not a clause about `upgrade-project.sh`), deliberately not repaired here | PM at delivery, as a filed-row candidate |
| RS-3 | AC-3's fallback ("run that historical copy on a scratch tree") is **unsafe as written**: a pre-T-25 `bin/sc` run as a program takes the import-time `os.execvp("sudo", …)` into the installed `/usr/local/bin/sc` against the live service. V-3 settles both sites by source order instead; if a future site cannot be settled by reading, the answer is **BLOCKED and a filed row**, never a run | stage 4 developer; stage 6 QA |
| RS-4 | `bin/sc:59-63`'s "as the eighth" and the corrected dev-map row will still state different numbers. I-5 makes the dev-map sentence carry the reason (`LIB_DIR` was added later, by T-28), so a reader meets one explanation instead of two counts; `bin/sc` is not edited | stage 5 code review |
| RS-5 | The insight-index entry citing `bin/sc:3769` is correct in substance with a drifted coordinate (`:3837` today). Not this task's row and not edited; recorded because it is the same defect class the sweep exists to name | PM at delivery |

## Partition assignment

This project has **no** `.harness/agents/dev-*.md`, so stage 4 is single-Developer
(`harness-kit:developer`). The table is kept for clarity, with one partition.

| File | Partition | New / Edit | Dependency |
|---|---|---|---|
| `docs/tasks.md`, `docs/tasks-archive.md` | dev | edit | — (M-1 runs first) |
| `bin/sc` | dev | edit (comment + one user-facing key pair) | M-3 depends on the I-11(a) derivation |
| `docs/dev-map.md` | dev | edit (4 rows) | — |
| `CHANGELOG.md` | dev | edit (1 entry) | M-4 depends on the I-11(b) table |
| `.harness/rules/80-delivery-policy.md` | dev | edit | M-5 depends on the grep of `upgrade-project.sh` |
| `.harness/rules/50-singbox-cli.md` | dev | edit | — |
| `.harness/rejected-decisions.md` | dev | edit (append one entry) | after M-2…M-5 |
| `docs/features/record-accuracy-sweep/04_DEVELOPMENT.md` (+ `04_RATIONALE.md` if non-empty) | dev | new | last |

### Dispatch order

1. dev (single partition, steps M-1 → M-8 in order)

### Parallelism

None — one partition, and M-3/M-4/M-5 each have a derivation or a grep as their precondition.

## Verdict

READY
