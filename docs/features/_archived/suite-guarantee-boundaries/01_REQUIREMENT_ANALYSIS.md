# 01 — Requirement Analysis · T-31 `suite-guarantee-boundaries`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

The contract suite's guarantees and its written claims have drifted apart: its process-start denial
is a name list over one module's namespace, its assertion floor has no control against being
lowered, two of its claimed invariants are held by memory rather than by the artifact, and three
whole classes it is blind to are not stated where a reader meets them — this task makes every
guarantee-shaped sentence either enforced or marked as a boundary, and closes only the boundaries
whose closure is strictly narrowing.

## In-scope behaviors

**FR-1** — Every guarantee-shaped sentence in the contract suite's **claim surface** — the module
header of `.harness/scripts/check-sc-contracts.py`, the fixture-loader recipe block and its
"what it guarantees / what it does not" text in `docs/dev-map.md`, and the `notes` value of
`.harness/scripts/baseline.json` — is, after this task, either enforced by the delivered artifact
or marked in the same place as a boundary the artifact does not enforce. This is the task's one
rule; FR-2 … FR-7 are its instances.

**FR-2** — A subject source whose import starts a process through a route that does not pass
through the loaded module's own `os` binding either (a) starts no process, with the run ending
non-zero and naming the refusal, or (b) has that route named as not covered per FR-1. Which of the
two holds is decided by AC-1's measurement, not assumed.

**FR-3** — No name is added to the denial's `os` enumeration in order to make an unscoped
completeness claim true; a claim of completeness over `dir(os)` is scoped to the platform on which
it holds. A denial that gains names without gaining capability coverage does not satisfy FR-2.

**FR-4** — `verify_all` FAILs when the assertion floor in `.harness/scripts/baseline.json` is lower
than the floor recorded in the last commit, and PASSes when it is equal or higher. The comparison
is owned by `verify_all`, never by the suite whose count it judges.

**FR-5** — The claim surface states that the suite's sentence assertions pin the English key
spelling of each sentence they name, that a translation-only wording regression is outside their
reach, and that re-running the same assertions under another language does not change this. No
second-language pass is added to stand in for that boundary.

**FR-6** — The claim surface states that T-25's output-layer contract is outside any same-process
assertion's reach, and names what does verify it. No committed artifact executes `bin/sc` as a
program, and no committed artifact starts a child process.

**FR-7** — The invariant "the one writer installs `config.json`" (T-13; `_write_private()` is the
sole writer, and `generate_config()` installs through it) is either enforced by a clause of the
contract suite over the subject's own source, driven by the suite's existing subject parameter, or
recorded in the claim surface as held by a decision record alone. The delivered document names
which, and why, as a ruling of this task rather than an inheritance of T-30's `K-11`.

**FR-8** — No committed assertion is removed, and the assertion floor is never lowered. If the
delivered suite defines more assertions than it defines today, the floor is raised to the new
count in the same commit.

**FR-9** — `bin/sc` is not modified by this task: this task changes what is claimed and what is
checked, never the product behaviour being checked.

## Out of scope

1. R-97, R-101 and R-103 — the recovery-arm guard, the rendered-outcome half of BC-11, and the
   `out.replace` / composed-bytes controls: they add coverage, this task bounds guarantees.
2. End-to-end `sc config` redaction (`cmd_config` is never driven) — same family as 1; it stays
   filed and is named as uncovered, not closed.
3. R-102(b) — whether the rejection arm sits inside or outside the inner `try` — stays filed.
4. Any test framework, test runner, child-process harness, coverage tracker, mutation machinery,
   new file, new directory, or new dependency.
5. The eleven prose sentences owned by T-32 (R-63, R-74, R-77 … R-85, R-91, R-94), including any
   that sit inside a block this task edits.
6. R-89 / R-90 / R-92 (`archive-task.sh`, blocked on the owner's R-87 decision) and R-86
   (`guard-rm.sh`, T-27's ruling stands).
7. `verify_all` B.3 (the standing SKIP) and B.5 (T-07's restricted-network self-check): neither is
   repurposed, widened, nor read as covering anything new.
8. `.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md`.
9. `sys.addaudithook` as a denial mechanism — below the project's Python 3.6 floor and priced and
   rejected by T-28.
10. The `.ps1` mirror's B.4, which stays SKIP; no new step is added there.

## Boundary conditions

**BC-1** — euid 0 → the suite refuses at both entry points before reading any source, unchanged by
this task; no check added here runs before that refusal.

**BC-2** — the last-committed floor is unreadable (no `.git`, no `git`, the file absent at the last
commit, or its `test_count` non-numeric there) → the monotonicity comparison is not performed,
`verify_all` does not FAIL for that reason, and the step's output states that it was not performed.

**BC-3** — current floor greater than the last-committed floor → PASS; equal → PASS; lower → FAIL,
naming both numbers and the file.

**BC-4** — the floor was already lowered in the last commit → the comparison cannot see it. This is
declared here as a non-discriminating case, not left for stage 6 to discover: the control binds at
the instant before a commit, which is the instant the delivery policy requires a passing run.

**BC-5** — the load-time denial is widened → whatever it displaces is restored in the same `finally`
that restores the `os` shim, the restoration is asserted, and a failed restoration ends the run
non-zero.

**BC-6** — an assertion legitimately supplies a process-API-shaped stub (the checker stub) → the
widened denial is scoped to the load and does not reach the assertion phase.

**BC-7** — a probe measures whether a route escapes the denial → its target is harmless (a marker
file under the run's scratch directory, or a `/bin/true`-class program), its subject is a scratch
source file and never `bin/sc`, never the installed `sc`, and it names nothing under
`/etc/sing-box`, `/var/lib/sing-box`, or the running service.

**BC-8** — a source-level clause is adopted for FR-7 → it reads the loaded module's own source so
the subject parameter drives it, it bounds the named function, and it pins neither statement order
nor spelling: a reshaped `generate_config()` that still installs through `_write_private()` passes
it.

**BC-9** — a criterion requires root → it is reported BLOCKED and filed as a row, never substituted
with a weaker run.

**BC-10** — the delivered suite defines N assertions → the assertion floor equals N in the same
commit, and no assertion is removed to reach that number.

**BC-11** — a proposed closure trades any part of the safety spine (a `verify_all` run can never
elevate privileges and never starts a process) for coverage → the closure is refused and the row's
disposition becomes the written boundary; if even the boundary cannot be stated truthfully, the
verdict is `BLOCKED: NEEDS-HUMAN`.

**BC-12** — an edit lands in a block that also holds a T-32-owned sentence → that sentence is left
byte-identical.

## Acceptance criteria

| id | criterion | class ([S] read the artifact / [B] run and observe) | verification, and the wrong build it fails on |
|---|---|---|---|
| AC-1 | The escape measurement is reported — probe source, exact command, observed marker state, suite exit code — **before** the design fixes FR-2's disposition. | [B] | `02_SOLUTION_DESIGN.md` cites the run and `06_TEST_REPORT.md` re-takes it; a design that asserts the outcome without a run fails this. |
| AC-2 | A scratch subject whose import starts a process outside the shimmed `os` binding, under a uid predicate the shim does not neutralise, either leaves no marker and ends the run non-zero, or has that route named as not covered in both claim-surface documents. | [B] | Run the suite against the BC-7 probe, then read both documents; **today's tree fails it** — the route is neither refused nor named in the recipe block. |
| AC-3 | No claim-surface sentence asserts coverage the delivered artifact lacks; the `dir(os)` completeness claim is scoped to the platform where it holds. | [S] | Read both documents against the delivered denial; **today's header fails it** (`os.startfile` matches no prefix while the sentence says every name). |
| AC-4 | Lowering the assertion floor below its last-committed value makes `verify_all` FAIL, naming both numbers. | [B] | Set the floor to 17 with 18 committed, run; **today's `verify_all` fails this** — measured PASS at 17. Restore and re-run. |
| AC-5 | Raising the floor to the delivered assertion count leaves `verify_all` PASS. | [B] | The delivery run; a control written as equality rather than monotonicity fails this. |
| AC-6 | With the last-committed floor unreadable, `verify_all` does not FAIL for that reason and states that the comparison was not performed. | [B] | Run in a scratch copy with no `.git`; a control that FAILs on absent history fails this. |
| AC-7 | A subject whose only defect is a translated wording survives every re-run of the committed assertions in any language, and the FR-5 boundary states exactly that. | [B] | Mutate one translated value in a scratch copy, run under both language settings; if the mutant dies, the boundary sentence is false and this criterion fails. |
| AC-8 | No committed artifact runs `bin/sc` as a program or starts a child process, and the FR-6 boundary names what does verify T-25's output-layer contract. | [S] | Read the committed diff and the claim surface; any committed runner or spawn fails it. |
| AC-9 | FR-7 is discharged: either a clause FAILs on a subject that installs the document by `os.replace` and PASSes on the task-start `bin/sc`, or the claim surface records the invariant as unenforced. | [B] | Drive the suite's subject parameter at the `os.replace` shape and at the task-start source; that mutant is green today and is the discriminator. |
| AC-10 | `bin/sc` is byte-identical to its task-start `sha256`. | [S] | Record the digest at stage 2 and at delivery; any `bin/sc` edit fails it. |
| AC-11 | `bash .harness/scripts/verify_all.sh` ends PASS with FAIL 0 and WARN 0, B.3 the only SKIP, and the delivery states the step tally against the task-start `PASS 19 / WARN 0 / FAIL 0 / SKIP 1`. | [B] | The delivery run; any new FAIL, any new WARN, or a second SKIP fails it. |
| AC-12 | Every criterion that cannot discriminate is reported NOT-DISCRIMINATING rather than passed, BC-4's declared case included. | [S] | `06_TEST_REPORT.md`; a report that rounds one up fails it. |
| AC-13 | The delivered change adds no new file, directory, dependency or framework, and its net executable addition is within NFR-2 or the gate has re-derived that cap over its own element list. | [S] | `git diff --stat` plus the element list; a new file or an unamended overrun fails it. |
| AC-14 | A criterion that needs root is reported BLOCKED and filed as a row, never substituted. | [S] | `06_TEST_REPORT.md` plus the filed row; a substituted weaker run fails it. |

## Non-functional requirements

- **NFR-1 (safety spine)** — a full `verify_all` run starts no child process and never elevates:
  `execve` count 1 (the interpreter itself) and `clone` count 0 over a B.4 run, re-taken as T-28
  measured it; if the tracing tool is unavailable, the reading is BLOCKED and filed, never
  substituted.
- **NFR-2 (size)** — net executable addition ≤ **40** lines across `.harness/scripts/verify_all.sh`
  and `.harness/scripts/check-sc-contracts.py`, derived from the element list: floor monotonicity
  control 8–12, load-time route denial 3–6, source-level clause plus its registry row 10–18,
  floor edit 2. Per R-61 the gate re-derives this number and amends it rather than approving one it
  finds incredible.
- **NFR-3 (stack)** — Python 3.6 syntax floor, standard library only, `0755` on the suite,
  no new file, directory or dependency.
- **NFR-4 (docs)** — each stage document ≤ 500 lines (`verify_all` F.6); claim-surface additions
  stay inside the project's document-size rule.
- **NFR-5 (live host)** — `/etc/sing-box` with its entries, `/var/lib/sing-box`, and the running
  service are unchanged at every stage boundary; witnessed with `systemctl show` (`MainPID`,
  `NRestarts`, `ActiveEnterTimestamp`), never `is-active`.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Does R-93 close with code or with prose? | Both, split by half. The capability half is decided by AC-1's measurement: if a non-`os` route starts a process during load, it is denied at the level where the whole route is refused rather than by naming more `os` attributes; the residual routes it still cannot cover are written per FR-1. The enumeration half closes as prose only — the completeness claim is scoped to POSIX. |
| Q-2 | Is `os.startfile` added to the denial tuple? | No. Adding a name that no supported platform reaches makes an unscoped sentence true without adding capability, which is the defect T-28's CR-1 already caught one level up. The sentence is scoped instead — T-26's precedent, closing a row by narrowing the claim with the checked artifact unchanged. |
| Q-3 | Is a 15th-style assertion added that checks no `dir(os)` name outside the tuple is a known process-starter? | No. Such a check requires a hard-coded list of known process-starters, i.e. the same enumeration one level up, and it would report green on the day a future name arrives — exactly the guarantee it claims to give. The future-name risk stays a written boundary. |
| Q-4 | Does a second language pass over the same assertions close R-95? | No, and this is binding on stage 2: the expected value in each sentence assertion is produced by the same lookup as the observed value, so a wording change moves both sides and no re-run discriminates it. R-95 closes as a written boundary (FR-5), at zero executable lines. |
| Q-5 | Is a check added that every asserted sentence has a translation entry? | No. A key with no translation renders its English text **by design** per the project's own stated i18n rule, so such a check would assert a property the design explicitly disclaims. |
| Q-6 | Is R-96 closed with a mechanism? | No. It closes as a written boundary naming what does verify T-25's contract: review at change time, plus out-of-process measurement taken when the output layer itself changes. A child-process runner is refused under BC-11 — the trade it asks for is the suite's whole safety property. |
| Q-7 | R-102's fresh ruling — does a source-level clause get adopted for the one-writer invariant? | Adopt it, unless the gate refutes the ground: the property has **zero** behavioural reach (0 observable differences over 13 cases), the suite **already** contains a source-parsing assertion driven by the same subject parameter, so this reuses an existing seam rather than adding machinery, and T-30's `K-11` does not transfer because its subject was statement order while this one is which callee owns the write. If the gate refutes it, FR-7's second branch applies and the claim surface says the invariant is unenforced. |
| Q-8 | Is R-102(b) (the rejection arm's position) taken here? | No — it stays filed, and its filed characterisation is corrected at delivery: the mutant diverges from HEAD only when the rejection's own message write raises, which is a **behavioural** condition an arm could reach, so "needs a structural control" is not inherited as fact. |
| Q-9 | Where does the floor's monotonicity control live? | In `verify_all`, never inside the suite: a miscounting suite must not be the judge of whether its own miscount matters (T-28's ruling, upheld). Whether it extends the existing step or becomes a new one is stage 2's call; on failure it names both numbers. |
| Q-10 | Is R-67 an item of work here? | No — it is a practice, discharged by this document declaring BC-4's non-discriminating case up front and by AC-12 requiring stage 6 to report rather than round up. |
| Q-11 | Which document does a boundary sentence go in? | Both claim-surface documents for every boundary this task states — the suite's header is where a maintainer meets it, the fixture-loader recipe is where every future test task meets it, and today the recipe names none of the uncovered routes. The floor's `notes` value changes only if the floor's control changes what that value means. |
| Q-12 | What if the measurement shows no route escapes the denial? | FR-2's branch (b) applies unchanged: the boundary is written and no code is added. The measurement decides the disposition; it does not decide whether the claim surface is corrected. |

## Verdict

READY
