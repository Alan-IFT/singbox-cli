> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## 1 — How CR-1's replacement was tested, and what it had to survive

The round-1 finding was not "the number is wrong"; it was "the sentence counts two populations in one
breath". So the test applied to the replacement was the same one, run twice: does it name its
population, and is it exhaustive and disjoint over that population?

**Partition A, declared in the `Why` bullet — rows.** Eleven = nine semantic claims + R-94 + R-74.
Instantiating it against the sweep's own eleven rows: R-63, R-79, R-82, R-83, R-85, R-91 (six rows
whose sentence was corrected and which are not about a count) + R-77, R-78, R-84 (the three found
already discharged, each a semantic claim about what code does — an explicit codec, an exit-2 argparse
signature, a read-only command pair) = **nine**. Plus R-94, plus R-74 = **eleven**. Exhaustive, and no
row appears twice.

**Partition B, declared in the `Decision` bullet — also rows.** Eleven = seven corrected + three
already discharged and edited nowhere + R-74 amended in place. Instantiating: the six above plus R-94
= seven; R-77/R-78/R-84 = three; R-74 = one. **Eleven.**

**The two refine to the same eleven**, which is the property a reader will actually rely on: A's nine
semantic rows are exactly B's six non-R-94 corrected rows plus B's three discharged rows. That
cross-check is why I closed CR-1 rather than merely accepting the new arithmetic — a replacement
enumeration in a record about false enumerations should be verified against a second enumeration in
the same record, and here there is one.

**The population switch inside R-94.** The old sentence slid from rows to clauses without saying so;
the new one says "counting **its clauses**" and then counts documents-with-a-count-clause: three, of
which two deleted and one corrected. I checked each leg against the tree rather than against `04`:

- `.harness/rules/50-singbox-cli.md:29-30` — Test bullet reads "the committed contract assertions over
  `bin/sc`, wired as `verify_all` B.4 against `.harness/scripts/baseline.json`'s floor". No count.
  The floor pointer below it is intact.
- `docs/dev-map.md:87` — "named assertions … **how many there are is not stated here**; `baseline.json`'s
  `test_count` floor is that number's one home and B.4's own `N defined` line is where a run reports it."
  No count.
- `docs/tasks.md:230-231` — "`baseline.json`'s `test_count` is **19** since T-31 (raised in the same
  commit as the suite's nineteenth assertion; corrected here by T-32, R-94)." Correct, and it is
  precisely "docs/tasks.md's record of what T-31 raised", as the sentence describes it.
- `.harness/scripts/baseline.json:4` — `"test_count": 19`.

**The one genuinely new claim in the replacement was B.6, and it needed checking rather than
inheriting.** `verify_all.sh:116-134`: `b6_now` from the working tree's `baseline.json`, `b6_was` from
`git show HEAD:` of the same file, both through the single `floor_of()` reader (`:90-93`), FAIL when
`b6_now < b6_was` naming both numbers, SKIP with a printed line on any unreadable value, and it never
runs the suite. That is a committed-floor ratchet, so "still stands over `baseline.json`'s `test_count`
floor, B.4's own `N defined` line and B.6's committed-floor ratchet" is true of three real mechanisms,
not two real ones and a flourish. `baseline.json`'s own notes describe B.6 identically, including its
one declared blind spot (a lowering already in HEAD).

## 2 — Two readings I considered against the new sentence and cleared

**"…and one line of `docs/tasks.md`".** Taken as a statement about the file, this would be false of the
tree: `docs/tasks.md` carries the number 19 on three lines today (`:16`, `:230-231`, `:277`). Taken
under the population the sentence itself declares one clause earlier — R-94's *clauses* — it is exact:
R-94's count clauses are (b) rule 50, (d) dev-map, (e) `docs/tasks.md:230-231`, one line each. `:277`
is T-31's own block, which round 1 established sits **outside** R-94's declared five-clause population
(that is what CR-4 is), and `:16` is T-32's own row, created by this task. So the sentence is correct
under its declared reading and I did not raise it. It is worth knowing that the tree fact is already
travelling twice — RES-4 for `:230-231` and `:16`, RES-7 for `:277` — so nothing about it is silent.

**"…no committed check can decide any of them", applied to R-91.** R-91's delivered repair is five
greppable tokens, and the developer verified them with `grep -cF` — so at first read a committed check
*could* decide something here. It cannot decide the claim, though: a grep for `refresh_set` establishes
that a name is present, not that `/harness-upgrade` replaces what the paragraph says it replaces. The
tokens are the evidence style the row adopted precisely so a drifted coordinate fails loudly; the
sentence's claim remains a semantic one about what `upgrade-project.sh` does. Cleared, not raised.

**"seven sentences corrected" inside a row population.** Read strictly as sentences, seven is
understated — R-94 alone corrected clauses in three documents. Read as the programme's settled
vocabulary ("the seven corrected sentences" = the seven rows whose sentence was corrected), which is
how `04`'s Summary uses it and how round 1 certified it, the arithmetic 7 + 3 + 1 = 11 holds over rows
uniformly. I did not reopen it in the record. I did raise the same noun **in the board row** as CR-6,
because there the surrounding text says R-94's population is "five clauses not the three filed", which
makes the sentence reading locally self-defeating in a way it is not in the record — and because the
PM is editing that row anyway, so the correction is free.

## 3 — Why CR-5 is raised on a file nobody edited this round

`docs/tasks.md` did not change; `04_DEVELOPMENT.md` did, and the change is what created the
contradiction. `04:61-63` now records the delivered run's witness as `MainPID` 1776263 /
`ActiveEnterTimestamp` Mon 2026-08-17 00:44:47 and states outright that this is **not** the instance
the task's earlier runs recorded. `docs/tasks.md:16` still carries the earlier instance. Two delivered
documents now disagree about which instance the delivery witnessed, and the one a future reader will
reach for is the board row.

The load-bearing claim survives intact and I want that on the record so nobody over-corrects: AC-21
asserts that *this task* disturbed nothing, and that is still supported — every run's before/after pair
is identical, `is-active` was never invoked, `/etc/sing-box`'s mtime has not moved since 2026-08-11
(and `sc reload` / `sc on` / `sc update-rules` all regenerate `config.json`, so it would have), and
`NRestarts=0` with a fresh `ExecMainStartTimestamp` and no reboot is an external stop/start. What is
false is narrower: the parenthetical's identification of the witnessed instance. MINOR, PM-owned,
one edit.

I also checked my own round-1 document against the PM's instruction to correct any figure I had
asserted as current. I had asserted none — round 1's AC-21 row read "OWED at stage 5", with no
`MainPID` and no timestamp anywhere in the document. Nothing to retract; the replacement document
states the fact and routes it forward as RES-8 instead.

One artefact to hand stage 6 before it re-measures: `04:63` says `ps` reports the process starting at
00:44:46 while `ActiveEnterTimestamp` is 00:44:47. That is `ps` deriving a start time from a
boot-relative clock and rounding down — an ordinary one-second disagreement between two clocks, not
evidence of a second instance. Reading it as one would manufacture exactly the kind of false record
this task exists to remove.

## 4 — What I could and could not verify about "only two files changed"

Stage 5 holds `Read` / `Glob` / `Grep` and no `Bash`, so `git diff --stat`, `sha256sum` and `wc -l`
were unavailable. I did not dress reasoning as measurement (the T-30 stage-5 standard). What I did
instead was re-open every round-1 coordinate that a change would most likely have shifted, and check
that the certified text still sits at the same line number:

| coordinate | state at round 2 |
|---|---|
| `dev-map.md:76` (frozen past-tense `18 defined … T-30`) | present, unchanged |
| `dev-map.md:81` (R-79 prospective-price clause, both sites) | present, unchanged |
| `dev-map.md:87` (utilities row, no count) | present, unchanged |
| `50-singbox-cli.md:29-30` (Test bullet) / `:47` (preamble names only B.3) | present, unchanged |
| `80-delivery-policy.md:68-78` (8 lines, zero ranges, five tokens) | present, unchanged |
| `CHANGELOG.md:29` (equality lead, 「恰好是下面三种，没有第四种」, the 2 → 1 downward witness) | present, unchanged |
| `tasks.md:16` / `:230-231` / `:277` | present, unchanged (`:277` is CR-4's subject and was to be left exactly as is) |

Line-number stability across seven coordinates in five files is strong evidence of no edit, and it is
not proof. `bin/sc`'s reported `sha256 0afdc3b6…f669` and `docs/tasks-archive.md`'s byte-identity are
the two claims I could not reach at all; both are stated as **owed** in RES-9 rather than certified.
`docs/tasks.md`'s 293/300 and the delivered `verify_all` counts are likewise PM measurements that this
stage inherited and did not re-take — recorded, not laundered.

`04_DEVELOPMENT.md` reads to 323 numbered lines against F.6's 500, comfortably inside the cap under
either the `Read` or the `wc -l` convention, so the round-1 off-by-one artefact does not bind here.

## 5 — NFR-2, checked rather than accepted

The developer reports 26 / 30 unchanged because both files touched this round are process paths. The
premise is in `02_SOLUTION_DESIGN.md:22` — "*path* are rule 80 process paths and do not count against
NFR-2's 30" — and the two files are ledgered as exactly that: E-12 `.harness/rejected-decisions.md`
(*process path*: one appended entry recording FR-11's decline) and E-13 `04_DEVELOPMENT.md` (*process
path*: the developer's stage doc). NFR-2's population is the five product/rule files in the per-file
table (`bin/sc`, `dev-map.md`, `CHANGELOG.md`, rule 80, rule 50), none of which moved. The reasoning
holds; 26 / 30 stands with four lines of headroom, and V-21's measurement is unaffected.

## 6 — Scope discipline, stated so the next round can hold me to it

I re-derived none of the seven corrected sentences, the R-85 transition set, the R-94 `Path`
enumeration, the R-91 tokens or the R-63 consumer count. Those were established first-hand at round 1
and nothing in this round's two files disturbs them. What I re-opened, I re-opened for one of exactly
three reasons: it is a file that changed (`.harness/rejected-decisions.md`, `04_DEVELOPMENT.md`); it is
a fact one of those files newly asserts and no prior stage verified (B.6's ratchet); or it is a
coordinate whose stability is the evidence for the unchanged-tree claim I was asked to test. Two new
findings came out of it, both MINOR-or-below and both discharged by a PM edit to a row the PM already
owns — neither is worth a third developer round, and I say so in the findings themselves so the
routing question does not have to be re-litigated.
