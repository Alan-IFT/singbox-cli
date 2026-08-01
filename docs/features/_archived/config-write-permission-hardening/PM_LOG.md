# PM Log — config-write-permission-hardening (T-13)

Mode: **full** (7 stages). Deferred-human mode: defer, do not ask; standing decision
authority granted by the owner. Return `BLOCKED: NEEDS-HUMAN` only for a genuine safety
red line.

## Task framing (from the dispatch)

Close the credential-exposure window when writing `config.json`:

1. Create `config.json` restricted from the outset (no write-then-chmod window).
2. Same treatment for any backup copy of a credential-bearing file the tool writes — or
   state plainly that no such path exists.
3. `install.sh` gains a closing permission sweep over `/etc/sing-box/`; the report-vs-repair
   choice must be made deliberately and justified.

The reporter's stated root cause ("never sets permissions when regenerating") is asserted
by the owner to be **wrong** for current code, and every stage must re-verify rather than
take either the reporter's or the owner's word for it.

## Pre-flight

- `.harness/intervention.md`: **absent** at task start (checked before stage 1 dispatch).
- `.harness/insight-index.md`: read; at its 30-line cap (30 content lines). Harvest sparingly;
  hand-rotate overflow at delivery because `archive-task.sh` rotation is known broken.
- `docs/tasks.md`: read. Related history:
  - **T-05 `sc-doctor`** — most related. Shipped `sc doctor` (commit `1b1b0e0`); scope boundary
    says reuse its permission reporting if it exists, otherwise leave it to T-20.
  - **T-02 `config-degrade-missing-rulesets`** — owns `generate_config()` and the atomic
    temp-then-replace pattern in `_fetch_to_temp()`; atomicity must not regress.
  - **T-11 `install-version-query-abort`** — owns `install.sh` failure reporting and made
    `check-i18n-parity.sh` the `verify_all` B.2 gate that now gates this task's new strings.
  - **T-08 `install-binary-download-progress`** — `install.sh` diff discipline precedent.
- `docs/dev-map.md`: read. Relevant seams: `# Paths`, `# State files` (`save_nodes`,
  `save_settings`), `# Config generation` (`generate_config()` "writes 0600").
- Task board updated with the new active row (mode: full).

## Insights surfaced into dispatch prompts

| Insight (index line) | Carried to |
|---|---|
| `bin/sc` auto-elevate re-execs the **installed** `/usr/local/bin/sc`; sudo `env_reset` drops env | developer, qa-tester |
| `_init_files()` hard-codes `/var/lib/sing-box` while every other path is repointable | architect, developer, qa-tester |
| `systemctl is-active` cannot detect a restart; use `MainPID` + `ActiveEnterTimestamp` | developer, qa-tester |
| B.2 parity gate renders the **en** table twice if `LANG_CHOICE` dispatch breaks | developer, qa-tester |
| A `git worktree` is not a valid pristine baseline for `verify_all.sh`; use a clone | qa-tester |
| `verify_all` E.6 matches `^##\s+Adversarial\s+tests` — do not number that heading | qa-tester |
| `archive-task.sh` harvests only the FIRST physical line of an `## Insight` bullet | PM (delivery) |

## Stage transitions

| # | Time | Stage | Decision |
|---|---|---|---|
| 1 | 2026-08-01 | — | Task folder created, board updated, no intervention. Dispatching stage 1. |
| 2 | 2026-08-01 | 1 → 2 | Stage 1 verdict **READY**, 0 blocking questions, 8 recorded decisions. Advancing to solution-architect. No intervention file at this boundary. |

### Stage 1 → 2 routing notes

Stage 1 adjudicated the disputed root cause independently (E-14): the reporter's cause is **false**
for current source (one write path, chmod on the next line), the owner is right about the code and
this host, but both framings are imprecise — the window is at **first creation** only, and a legacy
0644 file self-heals on the first regeneration by any current build. That narrows the reporter's
observation to version skew and makes the installer sweep the surface that actually reaches such a
host. Accepted as the task's premise.

Two items the PM is **not** ruling on, carried forward for the architect to address and the gate to
adjudicate (a PM ruling here would be a professional judgment, which is not the PM's to make):

- **S-1 — AC-25 vs the scope boundary.** The dispatch says "`bin/sc` and `install.sh` only", but
  AC-25 requires `README.md` / `README.zh-CN.md` / `CHANGELOG.md` edits. Project convention (T-09,
  T-02) does ship a `CHANGELOG.md` entry per task. The architect must state whether documentation
  is inside or outside the permitted diff; the gate rules.
- **S-2 — DECISION-8 (no committed test harness, 4th deferral).** Stage 1 flags this as its own
  weakest decision and explicitly refers the call to stage 2/3, "not smuggled in at stage 4".

One scope change was made on evidence and is accepted: **`nodes.json` is in scope** (DECISION-2) —
it carries the byte-identical write-then-chmod defect at two sites and is the primary credential
store. This is inside the `bin/sc` boundary and is what the dispatch's DESIGN NOTES anticipated.

### Stage 2 → 3 routing notes

Stage 2 verdict **READY**. It settled the central mechanism by reading CPython source rather than
citing docs, and its sharpest finding overturns a premise the dispatch itself floated: **"mkstemp is
0600" is false as an equality** — `_mkstemp_inner` passes `0o600` as `open(2)`'s mode argument and
never chmods, so umask still masks it (umask `0o277` yields `0400`). The chosen construction defeats
each of NFR-1's three facts with a *different* element: `os.fchmod` on the descriptor before any byte
is written (defeats umask masking), `O_CREAT|O_EXCL` on a fresh name plus `os.replace` (defeats
mode-ignored-for-existing-file), and the ordering itself (defeats the write-then-chmod window).

Items the architect ruled on, now referred to the gate:

- **S-1 → ruled inside the permitted diff**, with an explicit 10-file list. Reasoning: the dispatch's
  scope boundary constrains the *behaviour-change surface*; AC-25 comes from an APPROVED binding
  document. Gate must uphold or overturn.
- **S-2 → ruled defer again**, but on a structural ground rather than a fourth repetition: AC-23
  demands zero delta in `verify_all` PASS/WARN/FAIL/SKIP counts against a HEAD clone, and B.3 is a
  hard-coded `SKIP`, so wiring a real test step necessarily moves the counts. Partial repayment: the
  auto-elevate **neutralisation recipe** is productised in the design (§14 V-1, a `sys.modules` `os`
  shim, fail-closed, no edit to `bin/sc`). Overturn condition stated: the gate reading AC-23 as "no
  regression" rather than "zero delta". **The gate must rule explicitly.**
- **Three AC scope readings** the architect referred rather than resolved unilaterally (AC-4/AC-6
  measurement scope; AC-8's "exactly one line" vs `cmd_reload`'s pre-existing `Reload failed`).

Stage 2 also reports that **`docs/tasks.md` R-7 is stale** — the B.2 false-green blind spot was
closed by commit `49506f8` (`check-i18n-parity.sh` self-check). PM will correct the board at
delivery; the architect correctly did not edit it.

Stage 2 wrote to `.harness/rejected-decisions.md` (2 new records + 1 re-occurrence) and added the
term *credential document* to `CONTEXT.md`, both per standing project contract. Noted, not a
scope breach; the gate should confirm.

| 3 | 2026-08-01 | 2 → 3 | Stage 2 verdict **READY**. Advancing to gate-reviewer with the three referrals. No intervention. |
| 4 | 2026-08-01 | 3 → 4 | Gate verdict **APPROVED FOR DEVELOPMENT**, conditions C-1…C-14 binding. Stage gate satisfied (explicit PASS). No partition `dev-*` agents present → **single-developer mode**, dispatching `harness-kit:developer`. No intervention. |

### Stage 3 → 4 routing notes

The gate has no write tool (read-only by design), so it returned `03_GATE_REVIEW.md` in full and the
PM persisted it **verbatim**, altering neither content nor verdict.

Referrals ruled: **S-1 upheld and widened by one file** (`docs/architecture.md`'s 安全考量 table —
the gate overturned the architect's exclusion, since after this task `config.json` is as
credential-bearing as `nodes.json` and the table would read the opposite way). **S-2: AC-23's
literal "zero delta" reading overturned** — it would forbid what rule 50 mandates, so AC-23 means
"no step regresses, and no count moves for a reason the task cannot name". The harness deferral is
nonetheless **upheld on a new ground** (a committed step means importing `bin/sc` on the owner's
live machine forever, defusing the very re-exec that once restarted the owner's VPN — safety
criteria no APPROVED requirement states). The three AC scope readings upheld with non-vacuity
conditions.

Five gate WARNs, zero FAIL, no design change required. The gate's own new finding **F-3** corrects
the dispatch's premise: the stated baseline `PASS 17 / WARN 0 / FAIL 0 / SKIP 1` is T-05's
*post-archive* measurement, and F.6 (doc size) is **already WARN in the working tree** because
`02_SOLUTION_DESIGN.md` is 789 lines. Two PM notes on that:

- The architect self-reported "约 470 行" for a 789-line document. A document-accuracy defect, not a
  design defect; not worth a rollback, recorded here.
- Rule 70's cap is exceeded by an active stage doc. Precedent T-05: F.6 WARNed and **cleared on
  archive**. PM accepts the traversal and will confirm it clears at delivery rather than compacting
  a gate-approved design mid-flight.

| 5 | 2026-08-01 | 4 → 5 | Stage 4 reports **no design drift**, `verify_all` **PASS 16 / WARN 1 / FAIL 0 / SKIP 1 — zero delta** against its own pre-edit measurement. Stage-5 entry gate satisfied (no FAIL). Advancing to code-reviewer. No intervention. |

### Stage 4 → 5 routing notes

The gate's F-3 was **half confirmed, half refuted by measurement**: F.6 is indeed already WARN
(789-line design doc, pre-existing before the first edit), but **F.4 reads PASS**, so the insight
index is not over its cap in the working tree. The dispatch's `17/0/0/1` is confirmed to be T-05's
post-archive figure, not a run-today prediction.

Live service witnessed with `systemctl show -p MainPID -p ActiveEnterTimestamp` (never `is-active`):
`MainPID=2887037` / `Sat 2026-08-01 10:06:40 CST`, **identical before and after**. `/etc/sing-box`
and `/var/lib/sing-box` stat-witnessed unchanged. `install.sh` never executed, installed
`/usr/local/bin/sc` never touched, nothing committed or pushed.

The gate's predicted P-1 regression is guarded by **measurement rather than argument**: bare
`mkstemp` at umask `0o277` yields `0400`, `_write_private` yields exactly `0600` at all four umasks.
Non-vacuity shown against a pristine `HEAD` copy — HEAD exposes `config.json` at `0o666` holding
5148 bytes at the publish instant.

Five items stage 4 honestly could **not** verify, all carried to stage 6 as obligations: AC-23's
post-archive clone comparison, Python 3.6 (no 3.6 interpreter on this host), C-6's `os.replace`
falsifier + fixture filesystem type, AC-24's `sc doctor` byte-identical render, AC-27's second
installer run.

| 6 | 2026-08-01 | 5 → 4' | Stage 5 verdict **PASS**, no BLOCKER, no MAJOR, **no design drift**, C-12 discharged. One MINOR (`docs/dev-map.md` stale `bin/sc:309` citation) routed **back to the developer** — the reviewer is read-only and only the implementer fixes code. Not counted as a pipeline rollback: no upstream document was wrong and no stage was re-run. |
| 7 | 2026-08-01 | 4' → 6 | Developer verified the line independently (`bin/sc:367`), replaced the citation with a **drift-proof semantic anchor** rather than a new number, swept for siblings (one found, `check-i18n-parity.sh:48`, verified sound and left), `verify_all` unchanged at 16/1/0/1. Advancing to qa-tester. No intervention. |

### Stage 5 → 6 routing notes

Stage 5 also had no write tool; `05_CODE_REVIEW.md` was persisted verbatim by the PM.

The reviewer substituted **line arithmetic** for a `git diff` it could not run: every HEAD anchor the
upstream documents recorded is displaced by *exactly* the size of the intended insertions and by
nothing else — positive evidence that `install_report()`'s body, the auto-elevate block and the
doctor block are untouched. `bin/sc:88-89`'s auto-elevate is confirmed **unmodified in product
code**; neutralisation lives only in the harness recipe. Reflog confirms nothing was committed.

The MINOR fix produced a small piece of process evidence worth keeping: the developer's own first
draft of the fix entry asserted a stale line count *inside the entry about stale line counts*, caught
it against `wc -l`, and removed the number. That is the same failure the MINOR was about, one level
up — and the reason the drift-proof form is the right choice.

**Open obligations carried into stage 6**: C-3 (harness pasted verbatim, not narrated — stage 5's
NOTE-8 flags it at risk because stage 4 discarded its harnesses), C-5, C-6, C-7, C-8, C-9, C-13, and
the AC-21 / AC-23 / AC-24 / AC-27 verification owed by §6 of the review.

**New PM-routed item from stage 4:** `/etc/sing-box/config.json.bak-2026-08-01-1001` exists on this
host — a **hand-made** backup at `0600`. It is correctly outside `CRED_FILES` (NG-11), but a
hand-made credential backup at a *wide* mode would be invisible to the sweep. Board row owed;
natural owner is T-20's permission audit. Added to the delivery-time board work.

| 8 | 2026-08-01 | 6 → 7 | Stage 6 verdict **PASS** — 106 assertions, 0 failures, 0 flakes, non-vacuity proven against a pristine HEAD **clone**. Stage-7 entry gate satisfied (stages 5 and 6 both PASS). No intervention. |
| 9 | 2026-08-01 | 7 | Delivery composed. Entropy-watch cadence: `.harness/scripts/entropy-cadence` **does not exist** in this project → fail-open → **NOT-DUE**, so no scan was run and no `## Entropy watch` section was written. Board updated, insight index hand-rotated, `archive-task.sh` run. **DELIVERED.** |

### Stage 6 → 7 routing notes

QA discharged every named condition and said which measurement discharged each. The three
falsification controls against a pristine HEAD clone are what make the greens earned rather than
asserted; the sharpest is the symlink control, which showed HEAD writing **12214 credential bytes
through a planted link** with its trailing chmod then narrowing the *destination* — a redirection
bug, not merely a timing window, and one no upstream document had predicted in that form.

QA's one MINOR is **documentation-only and owned by the requirement-analyst**: AC-4's literal text
says "*every* regular file in the fixture configuration directory", which contradicts NG-4, since
`settings.json` is deliberately left at the ambient umask. No correct implementation can satisfy it
literally. QA applied the behaviour-3 reading the gate had already ruled and supplied a reproducer.
**PM ruling: no rollback.** The requirement document is APPROVED and archived; the defect is in the
wording of a criterion whose *intent* was ruled at stage 3 and measured correctly at stage 6, and
re-opening stage 1 to reword a criterion that changed no outcome would cost a full re-gate for zero
behavioural difference. Recorded here and in `07_DELIVERY.md` instead.

### Delivery actions taken by the PM

1. `07_DELIVERY.md` written, with an `## Insight` section of **three** bullets, each a single
   physical line (`archive-task.sh` harvests only the first physical line of a bullet).
2. **Insight index hand-rotated before harvesting**, because `archive-task.sh`'s rotation is known
   broken and the index was already at its 30-line cap. Three entries were moved to
   `docs/features/_archived/insight-history.md` with a written rationale each, chosen by rule 70's
   "what no longer earns its line" rather than oldest-first: the B.2 `LANG_CHOICE` false-green
   (**superseded by a fix**, commit `49506f8`), the `http.client` chunk-size reading (**superseded by
   its own later refinement**, already in the index), and the 696-byte `geosite-private.srs` figure
   (**a fixture measurement with no live consumer**). Net effect: 30 → 27 → 30 lines, F.4 never WARNs.
3. `docs/tasks.md`: T-13 moved to completed; **C-1** discharged by filing R-9 with full scope; **C-11**
   discharged by filing R-11, R-12 and R-13; R-10 and R-14 filed from stage 4's and stage 6's
   findings; and **R-7 narrowed rather than struck** — its first blind spot is genuinely fixed, its
   second is live and nothing committed catches it.
4. `archive-task.sh --task config-write-permission-hardening` run; stage docs moved under
   `docs/features/_archived/`.

**PM-owned conditions, discharged at delivery** (`docs/tasks.md` is PM-only per §8 item 10):
**C-1** — file the committed `bin/sc` test harness as its own numbered row, and **narrow** R-7
rather than striking it (its second blind spot is live). **C-11** — re-home three open rows: the
world-writable-`/etc/sing-box` residual, F-4's invariant statement, F-5's English-only start-up
render.
