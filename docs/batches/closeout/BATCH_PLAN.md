# Batch Plan — closeout

> Created: 2026-08-16
> Default mode: full
> Stop policy: strong-signal-only

**Provenance and the decision to keep this pool small.** The `followups` pool closed ~28 rows and
filed R-62 … R-96. Reflexively opening a third pool of the same size would be the treadmill the
owner's standing directive exists to stop, so the new rows were triaged against
`.harness/rules/85-design-discipline.md` — including its **"Less is more"** section — **before** any
row was written. The result is **four** tasks, and two whole categories are deliberately **not
built** (see below). "Do nothing here" is a conclusion this project has reached before on the
merits: T-21 recommended no code at all.

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|
| T-29 | state-file-contract-completion | Finish the contract T-23 started: four bare `read_text()` calls remain in `bin/sc`, `save_settings()` is the only authored document whose write failure is never rendered, and an unusable `settings.json` still lets a regenerating run silently discard the user's stored choices. | full | — | done (all three closed; R-76's sweep was six sites, wider than the row named) |
| T-30 | validate-before-baseline | Stop a configuration from being written and its drift digest baselined onto a document the checker then rejects, and stop `sc reload` tracebacking on a host with no `sing-box` binary — one ordering, two symptoms. | full | — | done (R-70 + R-73 both closed as **one** design; R-81 ruled out as not one-line and left filed) |
| T-31 | suite-guarantee-boundaries | Make the committed suite's guarantees match its claims: the privilege denial that keeps `verify_all` from ever elevating is a **name list** covering only `os.*`, and the suite is structurally blind to zh-only regressions and to T-25's output-layer contract. | full | — | done (R-93 capability half by a check, enumeration half **by narrowing the claim**; **R-95 + R-96 closed by a written boundary at zero code**; R-104 by new `verify_all` B.6) |
| T-32 | record-accuracy-sweep | Correct the eleven filed sentences — in shipped prose, dev-map rows, rule fragments and a changelog lead — that claim something the code does not do, and add nothing else. | full | — | done (7 closed, **3 already discharged by T-28**, R-74 ruled open with reasons; no mechanism added) |

## Notes

### How these four were derived

- **T-29 — T-23's family was bigger than T-23 named, and the remainder is measurable.** Verified
  2026-08-16: **four** bare `read_text()` calls survive at `bin/sc:1667`, `:2015`, `:2705`, `:3121`,
  while `:567`'s docstring already claims 'explicit `"utf-8"`, never `read_text()`'. **R-76** names
  the `cmd_config` instance and observes that repairing it falsifies a shipped sentence — so this
  task carries a prose correction with its code, which is why it is not left to T-32. **R-66**:
  `save_settings()` is now the **only** authored document whose write failure is not rendered — a gap
  created by the very contract that closed the others, i.e. exactly the "half a family" shape rule 85
  names. **R-65** is the user-visible one: on an unusable `settings.json` a regenerating run
  **silently discards the user's stored choices and re-baselines**, which is data loss with no
  sentence. Three rows, one incomplete contract.
- **T-30 — one ordering, two symptoms, and T-24 established the mechanism.** **R-73**: `sing-box
  check` runs *after* `_write_private()` **and after the drift record is baselined**, so the loudness
  everyone has been relying on protects the *running service*, not the *stored configuration* — a
  document the checker rejects can sit on disk with a digest recorded as good. T-24 found this while
  refuting its own brief's counter-weight. **R-70**: `sc reload` tracebacks on a host with no
  `sing-box` binary — the same call path, missing the same guard. **R-81** (`stored_delays()` cannot
  distinguish "no `/proxies` answer" from "an answer carrying no history") rides along **only if it
  is one line**; it is a different seam and must not widen this task.
- **T-31 — this is a safety row and it continues T-28's own hardest finding.** T-28's reviewer caught
  that its first fix was **a name prefix standing in for a capability**; **R-93** says the delivered
  version is still a name list, and `check-sc-contracts.py:107` confirms it:
  `name.startswith(("exec","spawn","fork","popen","posix_spawn","system"))`. The file's line 22 states
  the limitation honestly — *"the denial is by NAME, so this enumeration IS the guarantee"* — which
  makes this a **known boundary to close or to accept in writing**, not a hidden defect. **The
  specific gap to establish first: the shim covers `os.*` only, and `subprocess` reaches
  `_posixsubprocess` (a C extension) without passing through the shimmed `os` attribute lookup.**
  Measure it before designing; if `subprocess.Popen` escapes the denial, that is the row. **R-95**
  (blind to zh-only regressions) and **R-96** (T-25's output-layer contract is structurally
  untestable by any same-process assertion) belong here because they are the same question — what the
  suite actually guarantees versus what a reader assumes — and **R-96 may be unfixable, in which case
  the correct output is a written boundary, not code.** **R-67** is the criteria-gap statement of the
  same family.
- **T-32 — eleven sentences, one cause, and no code.** R-63, R-74, R-77, R-78, R-79, R-82, R-83,
  R-84, R-85, R-91, R-94. Each is a claim in shipped prose, a `docs/dev-map.md` row, a rule fragment
  or a changelog lead that says more or other than the code does. **R-74 states the general form**
  and its owner field reads "every stage that writes a user-facing or record sentence" — this is the
  project's most-repeated defect: T-24's **three** rollbacks were all prose with `bin/sc`
  byte-identical from round 1, T-25's rollback was a record defect, and T-26's MAJOR was a published
  exit transition the build cannot produce. **Hard scope limit: correct the sentences and add
  nothing.** No linter, no doc-lint step, no `verify_all` check, no template. A mechanism to prevent
  prose drift is exactly the meta-tooling rule 85's counter-rule declines, and T-27 already declined
  its cousin by deleting a table it had designed. Two of the eleven (R-77, R-84) concern the
  **mandated fixture-loader recipe**, which every future test task depends on, so they are the ones
  to get right rather than merely edit.

### Rows deliberately not made into tasks

- **`archive-task.sh`'s internals — R-89, R-90, R-92 — are blocked on a decision only the owner can
  make, and doing them first risks wasted work.** All three live in `archive-task.sh:109-136`, and
  **R-87** asks whether to adopt harness-kit 0.47.0's upstream refresh, which is a **425-line
  rewrite** of that file. It fixes four things this copy still gets wrong, **does not fix R-18** (just
  closed by T-27 locally), and **cannot be taken selectively** — `refresh_set` also re-lands the
  frozen `archive-task.ps1` and `guard-rm.*`. Repairing three defects inside a file that may be
  wholesale replaced is the clearest possible case for waiting. **Owner decision required.**
- **R-86 — `guard-rm.sh` blocking commands containing no `rm`** (twelve instances, the bypass never
  set). T-27 filed it with a scope ruling that deliberately keeps it out: it is documented behaviour,
  a fix to a *refusal* artifact can only make it permit **more**, and the workaround costs one flag.
  That ruling stands.
- **Operator obligations — R-68, R-87, R-88, and `.harness/operator-obligations.md` id 1–5.**
  Human-only by construction. No agent in this project can discharge them.
- **R-46, R-51, R-53, R-57, R-61, R-72** and the other accepted boundaries. Each was ruled on by a
  gate or reviewer with reasons. R-57's two `--source` derivation defects are unreachable through the
  default source; R-72 (an error message echoing user-supplied JSON into the captured log) is real but
  bounded and belongs to whoever next opens those strings.

### Ordering

T-29 and T-30 first — both are live user-visible defects, and T-30's is silent data corruption of a
kind the project has been assuming the binary catches. T-31 next: it is safety, but it is a
*boundary* question rather than a live exploit, and it should be answered after the code it guards has
stopped moving. T-32 last, deliberately — a prose sweep run before the other three would have to be
redone for the sentences they change.

## Column reference

- **ID** — pool-local identifier (`T-NN`), continuing the previous pools' numbering.
- **Slug** — kebab-case; becomes `docs/features/<slug>/`.
- **Goal** — one sentence; becomes pm-orchestrator's task-description input.
- **Mode** — `full` (default 7-stage) | `plan` (stages 1-3 only) | `goal` (Dev + QA loop).
- **Depends on** — comma-separated `T-NN` IDs in the same pool, or `—` for none.
- **Status** — `pending` | `in-progress` | `done` | `failed` | `blocked` | `needs-human` | `skipped`.
