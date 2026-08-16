# 02 — Rationale · T-32 `record-accuracy-sweep`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

Routing follows `.harness/rules/70-doc-size.md`'s `## Stage-doc boundary rule`; nothing here is
restated from it. **This stage held no shell** (`Read`/`Grep`/`Glob` only), so every claim below is
a reading of the tree at design time; anything needing a run is a criterion in the contract, marked
as owed rather than presented as measurement (NFR-5). Two things follow: the `## Byte-form specification` section is **absent**
from the contract because this project's boundary rule carries no numbered rows for it to be gated
by, so the corrected sentences are specified as clause sets and
invariants (I-1 … I-9) rather than as finished bytes; and where I quote existing text it is
backward-looking evidence, never a replacement string.

## 1. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| "Which directives can change `dns.rules`' head?" | `_apply_directive()` + `_anchor_index()` | `/home/alan/Programs/singbox-cli/bin/sc` | Reuse as the **only** source; the shipped sentence is derived from it and names no directive at all (I-2) |
| "What does `sc doctor` exit?" | `DOCTOR_EXIT` + `cmd_doctor()`'s `worst = max(...)` | same | Reuse as-is; the changelog lead is derived from this mapping, nothing is re-derived |
| "Does the document carry this decision at the head?" | `_doctor_ipv6()` reading `_dns_overlay(suppress)`'s own `$prepend` payload | same | Reuse; the corrected sentence describes exactly this test and adds no second opinion |
| A place to state the two-clause `port` contract | already stated twice — the `stored_delays()` utilities row and the docstring | `/home/alan/Programs/singbox-cli/docs/dev-map.md`, `bin/sc` | Reuse the existing wording; the file-map row is aligned to it rather than given a third phrasing |
| A home for the committed assertion count | `baseline.json`'s `test_count`, read by B.4 and ratcheted by B.6 | `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json` | Reuse as the **single** home; the two prose copies are deleted rather than corrected (§3) |
| A mechanism that prevents prose drift | (none found, and none built) | — | Declined on the merits (§4); recorded once in `.harness/rejected-decisions.md` |
| A record for a declined approach | `.harness/rejected-decisions.md`'s existing `## slug` + Decision/Why/Origin shape | same | Reuse the shape; no new file, no new section kind |
| A place for the derivations the ACs demand | `04_DEVELOPMENT.md`, an existing canonical stage doc | `docs/features/record-accuracy-sweep/` | Reuse; no new document kind is coined |

Nothing in `docs/dev-map.md`'s "Reusable utilities" table needed extending: this task adds no
behaviour, so it introduces no need that a utility could serve.

## 2. The seam — and why consolidation is declined, per row

The dispatch asks whether the seven live rows have a common shape. They have two, at different
levels, and only one of them is buildable.

**The general shape is R-74 itself** — a sentence claiming slightly more than the code delivers.
All eleven rows are instances of it, which is why R-74 is the row that must not close (Q-5) and why
the sweep's durable artifact is the practice, not the eleven edits. The only way to *build* that
shape is a mechanism, which is declined in §4. So at the general level: seam identified, already
named on the board, correctly carried as a practice row. Building it is the failure mode, not the
omission.

**The specific shape is buildable and is built.** Four of the seven rows are the same defect one
level down: **a sentence anchored to an enumeration or a coordinate that its own subject can move.**

| row | the anchor that moves | the property it stood for |
|---|---|---|
| R-83 | "if it **prepends** a rule of its own" — one directive out of five | *a rule of the user's is at the head* — true whatever directive put it there |
| R-91 | four line ranges into a file the described event re-lands | the named mechanisms (`refresh_set`, `VERIFY-SPLICE`, `VERIFY-HALT`, `.bak-<stamp>`) |
| R-94(b)(d) | a count copied into two documents | `baseline.json`'s `test_count`, the one copy a gate reads |
| R-94(a) | a count and an enumeration that omitted a constant | the nine constants, enumerated, with the one exception named |

The repair is the same move each time — **state the property, delete the anchor** — and it is the
move that stops the row recurring. R-83's sentence gets no directive list at all; R-91's paragraph
gets no line range at all; two documents get no count at all. That is consolidation of *shape*, at
a diff strictly smaller than the alternatives, and it needs no new code, file or concept.

The remaining three rows are genuinely singular — R-63 records a dependence that exists nowhere
else, R-79 corrects a modal claim (a loss that was never available), R-82 aligns one of three
statements of an existing contract — and folding them into anything would be shape-matching the
report rather than the domain. Per rule 85's closing paragraph: **the owner's granularity is right
here and is kept.**

## 3. Less is more — the alternatives rejected, per decision

Rule 85 puts the burden of proof on the larger design. Each decision below names the smaller
alternative and what the extra text buys; where the *smaller* option won, the larger is named too.

- **R-83, name three directives vs name none.** Larger: enumerate `$prepend`, `$replace` and
  `$before`-anchored-on-the-first-element. Smaller (taken): name the effect. The enumeration buys a
  user nothing they cannot see by looking at their own file, costs a longer shipped line in two
  languages, and re-arms the exact trap R-83 filed — a sixth directive, or a change to
  `_apply_directive`'s insert positions, falsifies it again. The derivation still has to exist
  (AC-8), so it goes where derivations belong: `04_DEVELOPMENT.md`.
- **R-91, re-cite three ranges vs remove all four.** Smaller diff: fix only the shared citation
  (`:548-556`), leaving three correct ranges. Rejected: the three survivors drift at the same
  refresh, and a paragraph where some anchors are trustworthy and some are not is worse than one
  where none is claimed — that is R-91's successor being filed on delivery day. Removing all four
  costs one more edited line now and buys a paragraph that cannot go stale. FR-8 permits it by name.
- **R-94(b)(d), write 19 vs write no number.** Smaller (taken): delete. The number has now been
  wrong twice (14 → 19 across two tasks) in documents where it decides nothing, and `CONTEXT.md`'s
  **assertion floor** entry already states the principle — the number is honest *because a gate
  reads it*, and a copy no gate reads is decorative. Both sentences already point at
  `baseline.json`, so deletion loses no navigation. Named risk: a gate reviewer may read AC-14 as
  requiring the documents to state the count; AC-14's own wording is conditional ("Every delivered
  document **stating** the committed assertion count …"), so zero statements satisfies it, and the
  fallback if the gate rules otherwise is the literal `19` at both sites — a one-word change, not a
  redesign.
- **R-94(a), fix the count only vs fix the count and the clause.** Smaller: `eight` → `nine`, add
  `LIB_DIR`. Rejected: the row's sentence also asserts the nine are "only ever referenced *inside*
  function bodies", and that is **false of `CFG_DIR`**, which is read six times at module level
  (`bin/sc:24-27`, `:32`, `:38`) to derive its siblings. A pure count fix ships a corrected sentence
  that is still false — R-74's defect, committed while repairing R-74's instances. The extra clause
  costs no extra line (the row is one physical line) and buys a sentence true of every constant it
  covers, plus the reason the eight/nine split existed at all.
- **R-63, a dev-map clause vs a `bin/sc` comment.** Q-1 already ruled: the trap is sprung by an
  editor reading `parse_ss`, so the clause has to be where that editor is. Two lines, zero
  executable statements.
- **R-79, rewrite the cost clause vs delete it.** Deleting would be smaller and is wrong: the cost
  is real *prospectively*, and T-25's argument that "an argument that only buys is a half-recorded
  one" is the reason the clause exists. One added clause turns a false present-tense loss into a
  true prospective price.
- **`docs/tasks.md` rotation, move the T-31 completed row vs leave it.** Rule 70 Rule 3's trigger is
  a Completed table over ~30 rows; it has one, and moving one very long single line frees exactly
  one line of the 300 F.5 counts. Declined for buying nothing; the space comes from rotating the row
  texts this task closes (M-1), which is the same discipline aimed where it pays.

## 4. Q-6 — no mechanism, argued against T-27 and T-31

The operator's expectation was offered to be overturned with evidence. I looked for evidence that a
check would earn its place and did not find it. In my own words, against the two named precedents:

**Against T-27.** T-27 designed a per-kind routing table for stage-doc units, priced it, and then
**deleted it** when every recurring kind routed correctly under the bare test plus precedence — ten
lines that decided nothing a reader could not decide already. A prose-drift check is that table's
twin. Ask what it could decide here: of the eleven rows, nine are semantic claims — *which
directives can reach index 0*, *which exit transitions a build can produce*, *whether a docstring's
uniqueness claim rests on a coincidence*, *whether a displaced round-trip was ever observable*,
*whether a line range covers the clause attached to it*. No committed program can evaluate any of
them without being a second implementation of the thing it checks, which is the "second opinion"
this codebase refuses everywhere else (`docs/dev-map.md`'s doctor rule, `_drift_state()`,
`srs_reject_reason()`). A check that can decide only the two counts is T-27's table again: ten lines
that fire on a spelling.

**Against T-31.** T-31 closed R-95 and R-96 at **zero executable lines** after measuring that the
alternatives were vacuous or destructive — a second-language pass cannot discriminate because
expectation and observation share the `t()` lookup, and a child-process runner would have traded the
suite's whole safety property for coverage. The same measurement applies here and it is already
taken: for the two mechanically-checkable clauses (assertion counts) the mechanism **already
exists** — B.4 prints `N defined` on every `verify_all` run and B.6 ratchets the floor — so a new
check would be a third opinion about a number two steps already read. And this design goes one
better than adding a check: it **removes the copies** (I-6), so the class the check would guard is
empty afterwards. A guard over an empty class is the clearest possible case of machinery whose
future edit cannot be named, which `.harness/rules/85-design-discipline.md:70-71` declines.

**What follows for R-74.** With no mechanism, R-74 has no closure predicate; closing it would
replace eleven corrected instances with a claim about future sentences — the exact over-claim R-74
names. So Q-5's ruling (amend, do not close) is not a preference, it is what Q-6's decline entails,
and the rejected-decisions entry records the two as one decision (I-10).

I therefore agree with the operator's expectation, on the merits and not by deference. **Zero
executable lines is this design's whole answer to a symptom list of eleven.**

## 5. Derivations behind the contract

### 5.1 R-83 — the filed "four" is three, and the exception is universal

From `_apply_directive` and `_anchor_index` in the delivered `bin/sc`: `$prepend` returns
`payload + current`; `$replace` returns the payload; `$before` inserts at the anchor's own index, so
it reaches 0 only when the anchor resolves to the first element; `$after` inserts at `i + 1` with
`i ≥ 0` and therefore **cannot** reach 0; `$append` returns `current + payload`, and `dns.rules` is
non-empty at merge time (the base defines it and `sc`'s own `$prepend` runs first, and one key takes
exactly one directive), so it cannot reach 0 either. Three, one of them conditional. The second
half — "ineffective only for `$replace`" — is refuted by composition order: the user's document is
merged last on **every** regeneration, so `sc reload` reproduces *any* override-caused displacement.
What it does repair is a stale or hand-edited document. Both halves of the filed repair are false,
which is why I-2 forbids the sentence to name a directive at all and pushes the derivation into
`04_DEVELOPMENT.md`.

BC-2 was tested and does not fire: the applier's refusal to insert ahead of the anchor and the
last-merge position of the override are both deliberate design (`docs/dev-map.md`'s config-composition
row), so the code is right and the sentence is wrong — T-26's R-48 standard, inverted correctly.

### 5.2 R-85 — the mapping is a label set, so "direction" is not a property it has

`DOCTOR_OK/UNKNOWN/PROBLEM = 0/1/2` orders severity; `DOCTOR_EXIT = {0:0, 1:2, 2:1}` maps it to
exit values, and `cmd_doctor` takes the worst class. The mapping is **not monotone**, so the
severity order and the numeric order disagree — which is why both the shipped lead ("only one
direction") and the filed replacement ("no host's exit code gets smaller") are false, each under the
reading the other is true of. T-26 changed two row classes (AAAA: membership → position, so
OK → PROBLEM on a displaced head; node delays: PROBLEM → OK on a no-init-system host whose API
answers). Composing them with the mapping gives exactly three transitions and no others:

| host class | worst class before → after | exit |
|---|---|---|
| displaced head, every other row OK | OK → PROBLEM | 0 → 1 |
| **displaced head, ≥1 UNKNOWN row, no PROBLEM row** | **UNKNOWN → PROBLEM** | **2 → 1** |
| no init system, API answers, node delays was the only PROBLEM | PROBLEM → UNKNOWN | 1 → 2 |
| any host already carrying another PROBLEM row | PROBLEM → PROBLEM | 1 → 1 |

**AC-10's host class, decided:** its pair is **2 → 1**, and it is **reachable** — the UNKNOWN can
come from a config-drift row with no record, an unparseable `sing-box version` line, or a
`settings.json` with no recorded Clash API port (four UNKNOWN rows at once, and `sc doctor` never
resolves a port because `main()` keeps it off `_resolve_clash_port()`), each co-occurring with an
override that both READMEs publish a recipe for. So the exit code moves **down** on that host, which
is the refutation the delivered lead must carry.

The transition table is a *source* derivation, not a run: driving a doctor probe from a fixture is
forbidden by the loader recipe, and this stage held no shell. The historical half needs
`git show <T-26 commit>{,^}:bin/sc`, which is a stage-4 run the contract owes (M-4).

### 5.3 R-79 — the price was never paid, and the proof is source order

Under `LC_ALL=C` CPython gives stdout the `surrogateescape` handler, so a `\udcXX` from an
undecodable filesystem byte **is** encodable there — but an `sc`-authored non-ASCII character is
not, and it raises before the line is written. At both sites the clause names, an `sc`-authored
character is encoded first, so the pre-`backslashreplace` build never rendered the data the clause
mourns:

- `cmd_update_rules` prints its `  ↓ <file> ... ` prefix **before** any mirror base can reach
  stdout, on the same run and for the same file; the `--mirror` / `SB_RULES_BASE` cause list is
  printed only after that prefix.
- `_doctor_permissions()`'s `{path}` lines all sit *inside* strings that carry an em dash, and the
  section's summary row — which also carries one — is printed ahead of them.

Both are settled by reading, which matters beyond tidiness: AC-3's fallback of running the
historical copy would take the import-time `os.execvp("sudo", …)` into the **installed** `sc`
against the live service. RS-3 records that, and V-3 forbids the run.

### 5.4 R-94 — the `# Paths` row is wrong twice, not once

`bin/sc`'s `# Paths` section defines nine `Path` constants: `CFG_DIR`, `CFG_PATH`, `NODES_PATH`,
`SETTINGS_PATH`, `RULES_DIR`, `OVERRIDE_PATH`, `STATE_PATH`, `LIB_DIR`, `IF_INET6_PATH`. The row
enumerates eight of them (it omits `LIB_DIR`, added by T-28) — the filed defect — **and** asserts of
all of them a property `CFG_DIR` does not have, since `CFG_DIR` is read at module level six times to
derive its siblings. That second defect is why the two live numbers can both be defended: the
recipe's **nine** is the set a harness must repoint, while AC-13's literal predicate ("referenced
only inside function bodies") selects **eight** — a different eight from the row's. I-5 states the
nine, the enumeration and the one exception in a single sentence, which is true under both readings
and explains rather than replaces `bin/sc`'s frozen "as the eighth" comment (RS-4).

## 6. Risk analysis

| # | risk | mitigation |
|---|---|---|
| 1 | **Translation-key drift.** The English sentence is both a `TRANSLATIONS` key and a call-site literal. Change one and every `zh` user silently reads English; B.4 checks placeholders, not key/call-site identity, and review reads the two lines 2 500 apart | K-3 makes the developer grep the new string and require exactly two occurrences; V-7 records the count |
| 2 | **A corrected sentence that is still false** — the R-74 defect committed while repairing R-74 (live at R-94(a), where a count-only fix leaves `CFG_DIR` misdescribed, and at R-83, where the filed repair names a fourth directive) | every I-row carries a truth condition checkable against named code, and V-1/V-5/V-6/V-11 check the *sentence against the code*, never the sentence against the row |
| 3 | **An AC satisfied by a mere edit** (the inverted R-22 trap: the artifact is the deliverable) | every verification step names its evidence — an enumeration, a `git show`, a grep count, a run's own output — and three steps (V-5, V-9, V-12) fail on a delivery that reproduces a filed number without deriving it |
| 4 | **`docs/tasks.md` breaching F.5 while adding dispositions** for eleven rows to a file at its cap | M-1 rotates first and V-20 measures after; the rotation targets only row texts this task closes, so no open row moves |
| 5 | **Scope drift into R-98 / R-106**, both of which name T-32 as owner and sit one grep away from rows being edited | they carry no ledger row, no I-row and no AC; out-of-scope item 1 states the PM's ruling, and V-16's `git diff --stat` fails on any path outside the ledger |
| 6 | **An unsafe verification** — running a historical `bin/sc`, importing it, or reaching the live host | K-12 forbids all three; RS-3 names the specific trap in AC-3's own wording; V-19 witnesses the service with `systemctl show` only |
| 7 | **Deleting the assertion counts reads as under-delivery** at the gate | §3 prices it, AC-14's conditional wording admits it, `CONTEXT.md`'s **assertion floor** entry supports it, and the fallback (`19` at both sites) is a one-word change if the gate rules otherwise |

## 7. Dependencies

None added. No library, no service, no script, no file whose purpose is machinery — which is the
point of FR-11 and of §4.
