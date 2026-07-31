# PM Log — ruleset-update-no-needless-restart (T-10)

Mode: **full** (stages 1→7). Deferred-human mode: defer, do not ask (standing decision
authority granted by owner; judgment calls resolved against `.harness/decision-rubric.md`
and recorded here; only a genuine safety red line returns `BLOCKED: NEEDS-HUMAN`).

Goal: stop `sc update-rules` restarting sing-box when no rule-set actually changed on disk,
now that T-09 (commit 0bb2373) made the weekly timer able to fire for the first time.

## Task start — 2026-07-31

- Task folder created: `docs/features/ruleset-update-no-needless-restart/`.
- `.harness/intervention.md`: **absent** (checked before stage-1 dispatch) → no pending
  intervention.
- `.harness/insight-index.md`: read, 12 entries. Four bear on this task and are carried into
  dispatch prompts:
  - auto-elevate re-execs the **installed** `/usr/local/bin/sc` (T-02 incident) — mandatory
    safety constraint for every harness AND scratch script.
  - `失败：` is a load-bearing diagnostic grep string.
  - 64 KiB chunk-read: progress fixtures under 64 KiB assert nothing.
  - `geosite-private.srs` is 696 bytes; all four mirrors serve byte-identical content.
    **Corrected at stage 3 (gate F-8 / C-9):** this is cross-mirror agreement at one instant.
    It does NOT establish week-over-week upstream stability, so it may not be used to claim
    "re-downloading identical bytes is the common case" — an inference this log originally
    carried and which had propagated into three other documents. No decision depends on
    frequency: a write-based change signal is wrong on *every* successful run regardless.
  - (also carried) archive-task harvests only the first physical line of an insight bullet.
- `docs/tasks.md`: read. Related history — **T-02** (`config-degrade-missing-rulesets`,
  ab4e4a4) owns the ruleset-status machinery (`ruleset_report`/`usable_tags`/
  `srs_reject_reason`) and the `gained`/`applied` notion this task must reuse rather than
  duplicate; **T-09** (`fix-rules-update-execstart`, 0bb2373) activated the timer. Board row
  added with `mode: full`.
- Partition detection: no `.harness/agents/dev-*.md` → **single Developer mode**
  (`harness-kit:developer`) at stage 4.

## Stage transitions

| # | Stage | Agent | Result | Notes |
|---|---|---|---|---|
| 1 | requirement | requirement-analyst | **READY** | 16 behaviours / 20 BCs / 25 ACs / 5 NFRs / 9 recorded decisions. No BLOCKED. |
| 2 | design | solution-architect | **READY** | D-1 closed on evidence → restart-only, on real content change. |
| 3 | gate | gate-reviewer | **APPROVED FOR DEVELOPMENT** | 0 BLOCKER / 3 MAJOR / 5 MEDIUM / 6 LOW; conditions C-1…C-11 binding. |
| 3b | design fix | solution-architect | **DONE** | C-1 doc compaction 559 → **495** lines + 2 accuracy corrections. Not a rollback. |
| 4 | development | harness-kit:developer | **READY FOR REVIEW** | `bin/sc` +141/−28; verify_all 16/0/0/2, **delta 0**; service witness identical. |
| 5 | code review | harness-kit:code-reviewer | **APPROVED** | 0 CRITICAL / 0 MAJOR / 5 MINOR / 2 NIT. No code change requested. |
| 5b | doc fix | harness-kit:developer | **DONE** | M-1 citations + N-1 wording + M-3 residual. `04` 437 → 497 lines. Not a rollback. |
| 6 | QA | harness-kit:qa-tester | **PASS WITH NOTES** | 522 assertions / 0 failures / **0 product defects**. |
| 7 | delivery | (PM) | **DELIVERED** | `07_DELIVERY.md` written; `verify_all` re-run 16/0/0/2. |

### Stage 6 → 7 decision (deliver) — 2026-08-01

QA verdict **`PASS WITH NOTES` — 0 product defects**. No `BLOCKED:`. Intervention check after
stage 6: `.harness/intervention.md` absent.

**Stage-7 gate satisfied**: stages 5 (`APPROVED`) and 6 (`PASS`) both passed.

QA did what the brief asked and rebuilt its own pristine `HEAD` (`10fa8e8`) baseline rather than
trusting the developer's numbers — per-check diff **IDENTICAL, delta 0**. 522 assertions across 8
scripts QA wrote itself from `01` §6/§7. The four red assertions during the stage were all in
QA's own test code, documented as such, and none was a product defect.

**The fix is demonstrated, not asserted.** Negative control on the identical no-op fixture: HEAD
yields `['is_running', 'restart_service']`, the working tree yields `[]`. Four injected mutants
all killed — notably the size-instead-of-content mutant, which **only** AC-5's
equal-size-different-content case catches, i.e. the requirement's insistence on content over size
was load-bearing rather than pedantic. In a 10-way concurrent race HEAD applies 10 times and the
change applies once.

**Safety constraint verified end to end.** C-2's witness identical (`MainPID=2500438`,
`ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST` on both sides), `/etc/sing-box` listings
identical, `find -newermt` empty, PATH-shim marker absent across all 10 runs, euid 1000
throughout, `/usr/local/bin/sc` never executed. QA confirmed it neither ran nor imitated the
un-neutralised `main_sc.py` in the shared scratchpad root.

**C-8 executed as the PM ruled** — an attributed list, not a set-inclusion test. Product diff is
exactly `bin/sc` + `CHANGELOG.md` + `docs/dev-map.md`; every other dirty file is a pipeline-written
harness/context artifact.

**One upstream prediction corrected by measurement:** stage 5 reasoned that a mode-000 *parent
directory* would yield `absent`; QA measured `unreadable` on Python 3.12.3 (`Path.exists()`
propagates EACCES). Both are inside the `None` set, so the `gained ⊆ changed` invariant is
unaffected. Recorded for accuracy — reasoning corrected by execution is exactly what stage 6 is
for.

**C-11 satisfied without tripping F.6.** The complete verbatim harness (2257 lines) went to
`QA_HARNESS_T10.md`; F.6 matches only `0[1-7]_*.md` and `PM_LOG.md`, so nothing is elided and no
gate is bypassed. `06_TEST_REPORT.md` is 357 lines.

### Entropy watch — NOT DUE (fail-open)

Mode is `full`, so the cadenced entropy watch applies. `.harness/scripts/entropy-cadence` does
**not exist** in this project. Per the cadence's fail-open rule, any missing/erroring cadence I/O
resolves to **NOT-DUE**: no scan was dispatched, no `## Entropy watch` section was added to
`07_DELIVERY.md`, and the delivery verdict is unaffected. Recorded rather than silently skipped.

### Delivery

`07_DELIVERY.md` written. `verify_all` re-run independently at delivery: **PASS 16 / WARN 0 /
FAIL 0 / SKIP 2**, F.6 PASS with every active task doc under the cap. `docs/tasks.md` updated —
T-10 moved to Completed. **Nothing committed or pushed**; `HEAD` remains `10fa8e8` and the owner
owns delivery, as instructed.

Three `## Insight` bullets written, each as **one physical line** per
`.harness/insight-index.md:21`. Insight-index is 21 lines against the F.4 cap of 30, so the three
additions land at 24 — within cap. Final step: `.harness/scripts/archive-task.sh`.

**Rollback count: 0.** Stages 3b and 5b were document-only corrections routed to their owning
agents; neither changed a decision, a behaviour, or a line of shipped code, so neither
incremented the counter.

### Stage 4 → 5 decision (advance) — 2026-07-31

Developer verdict **READY FOR REVIEW**, no `BLOCKED:` marker. Intervention check after stage 4:
`.harness/intervention.md` absent.

**Stage-5 gate satisfied.** `verify_all` must show `verify_all` PASSED before code review:
pristine-`HEAD` baseline (fresh clone at `10fa8e8`) and post-change run are both
**16 PASS / 0 WARN / 0 FAIL / 2 SKIP, exit 0** — **delta zero**. No WARN pre-existed, because
C-1 had already closed the F.6 doc-size finding before stage 4 started. The two SKIPs (B.2/B.3)
are the project's standing state, not something this task introduced.

**The mandatory safety constraint held — verified, not asserted.** This is the check that
mattered most, since T-02's incident is why it exists:

```
BEFORE 23:32:18   active   MainPID=2500438   ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
AFTER  23:50:23   active   MainPID=2500438   ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
```

Identical `MainPID` **and** identical `ActiveEnterTimestamp` across the whole verification run —
i.e. the live sing-box was never restarted, established by the C-2 witness rather than by
`is-active` alone (which the gate proved blind to exactly this event). `/etc/sing-box` listings
identical; `find -newermt` empty on every run; euid 1000 throughout.

C-3's two layers were built as required: layer 1 replaces the loaded module's whole `subprocess`
surface (`run`/`Popen`/`call`/`check_call`/`check_output`) with one deny-by-default tripwire that
records argv and raises, never whitelisting `sing-box`; layer 2 PATH-prepends
`systemctl`/`rc-service`/`sing-box`/`sc`/`sudo`/`service`/`openrc` shims that append to a marker
file and exit 91, asserted absent at the end of every script. The scratch-script clause became
mechanical as the gate demanded: one shared `qalib.load_sc()` that hard-fails if `bin/sc`'s
auto-elevate block stops matching, plus a `run.sh` that greps the directory for `import qalib`
before running anything and refuses at euid 0. 350 assertions, 0 failures, including a **negative
control** — the identical no-op fixture yields `['is_running','restart_service']` on `HEAD` and
`[]` after the change, which is the defect being fixed, demonstrated rather than claimed.

**Carried into the QA dispatch as a live hazard:** the developer found that the shared session
scratchpad root still contains `main_sc.py:54` — an un-neutralised copy of `bin/sc`'s
auto-elevate block left by an earlier task. Anything run from that directory could re-execute
the installed `/usr/local/bin/sc` under sudo against the live service. QA must not run anything
from there. This is the T-02 failure mode still physically present on disk.

**PM note for the reviewer (not a judgment, a boundary question):** the developer flagged that
`docs/dev-map.md` *gained* two rows rather than only having its existing `:46-47` rows edited.
C-8 admits that file "only for accuracy of its rule-set rows". Whether the addition stays within
that grant is the reviewer's call, not the PM's.

### Stage 5 → 6 decision (advance) — 2026-08-01

Code review verdict **`APPROVED`** — 0 CRITICAL, 0 MAJOR, 5 MINOR, 2 NIT, **no code change
requested**. No `BLOCKED:`. Intervention check after stage 5: `.harness/intervention.md` absent.
Transcribed verbatim by the PM (the reviewer is Read/Glob/Grep-only), findings and verdict
unedited.

The review confirmed in the **body of the code**, not merely in the docstring, the one place this
implementation could have silently failed: `digest.hexdigest()` is reachable only after the loop
completes, `except OSError` returns `("unreadable", None)` before any digest value can exist, and
a readable empty file falls through to a real `sha256(b"")`. So C-5 holds, `gained ⊆ changed`
stands, and AC-4's "exactly one apply per run" is structural — `restart_service()` has exactly
one call site outside `reload_or_restart()`, under `if changed and CFG_PATH.exists()`. T-02's
recovery order was re-verified verbatim and still precedes the non-zero exit.

**PM ruling on M-5 (the reviewer routed this to me explicitly).** `CONTEXT.md:26-31` is dirty
relative to HEAD and would make C-8's literal `git diff --name-only ⊆ {bin/sc, CHANGELOG.md,
docs/dev-map.md}` check fail. Ruling: **the entry stays, and C-8 is satisfied.** Reasons:
(1) it was written at **stage 1** and is *mandated* by `01` §3 — the developer never touched it;
(2) C-8 constrains the **product** diff, and `CONTEXT.md` is a project-context artifact in the
same class as `docs/features/**`, `docs/tasks.md` and `.harness/rejected-decisions.md`, all of
which `02` §3 already exempts by T-02 precedent; (3) reverting it would delete a definition the
requirement requires to exist. C-8 is therefore executed as an **attributed** list (file → stage
that wrote it) rather than a set-inclusion test, and QA was instructed accordingly. This is a
scope-boundary call inside the owner's standing grant — the task's stated boundary named
`install.sh`, `systemd/` and T-02's mirror logic as off-limits, none of which is implicated.

**Rolled the two "must fix before QA" items back to the developer as a document-only fix** (M-1
line citations, N-1 wording, plus the M-3 residual half the reviewer found missing). **This is
not a rollback for defect** — no code change was requested and stage 5's APPROVED verdict stands;
the rollback counter stays at **0**. The developer verified each corrected number against `bin/sc`
rather than trusting the correction letter, and **found two errors in the letter itself**:
`_filter_rules()` is `:655-683`, not `:665-683`; and the pre-existing C-7(iii) residual claimed
the widened read surface affects `sc add / rm / use / mode / default-tun / reload`, when
`generate_config()` has exactly two call sites and `cmd_mode` / `cmd_default_tun` never
regenerate config — corrected to `sc use / add / rm / reload` with call-site evidence. It also
established that M-2's blank line is **pre-existing** (`HEAD:bin/sc:1145` has the same single
blank line), not introduced by this hunk. `verify_all` re-run: **16 / 0 / 0 / 2, exit 0**, delta
still zero.

**Doc-size watch:** `04` is now **497** lines against the 500 cap (it crossed to 505 mid-edit and
was compressed back). `01` 372 · `02` 495 · `03` 208 · `05` ≈470. Three docs are within 5 lines
of the cap, so QA was told explicitly to keep `06` under 500 — a WARN there fails `verify_all`
outright and would block delivery for a formatting reason.

### Stage 1 → 2 decision (advance) — 2026-07-31

`01_REQUIREMENT_ANALYSIS.md` written, verdict READY, no `BLOCKED:` marker. Intervention check
after stage 1: `.harness/intervention.md` absent. Routing forward to stage 2.

PM notes on stage-1 output (recorded, not judged professionally):

- The analyst found `bin/sc:1217` — OpenRC hosts run the same command from
  `/etc/periodic/<period>/singbox-update-rules`, so the defect is **not systemd-only**. This
  widens the *impact* statement, not the diff: still `bin/sc` only.
- **Scope adjustment accepted (D-9):** `CHANGELOG.md:15` currently tells users the command
  "在 sing-box 正在运行时会重启 sing-box（连接会中断几秒）". Shipping the fix while leaving
  that in place publishes a false statement. `CHANGELOG.md` is therefore in the diff boundary,
  giving the same two-file shape T-09 shipped. This does not breach the task's scope boundary
  (which named `install.sh`, `systemd/` and T-02's mirror logic as off-limits — not the
  changelog). Recorded under standing decision authority.
- D-1 (apply mechanism) is deliberately left **conditional on stage-2 evidence**: hot-apply if
  demonstrable, honest restart otherwise; asserting without demonstrating is forbidden. This
  is exactly the question stage 2 must close.
- D-8 (no committed test tree) was flagged by the analyst as its own weakest decision. Carried
  to the gate reviewer as an explicit challenge item rather than silently accepted.
- Side artifacts written by stage 1: `CONTEXT.md` (stub filled, 7 terms) and one new
  `.harness/rejected-decisions.md` record (`mtime-or-size-as-a-ruleset-change-signal`). Both
  are harness/context artifacts, not production code — no gate issue.

### Stage 2 → 3 decision (advance) — 2026-07-31

`02_SOLUTION_DESIGN.md` written (~460 lines, under the rule-70 cap), verdict READY, no
`BLOCKED:` marker. Intervention check after stage 2: `.harness/intervention.md` absent.

The central open question of this task (D-1, hot-apply vs restart) is **closed with stated
evidence rather than assumption**, which is what the brief required:

- F-2 — the Clash API cannot apply a local `.srs`: `/providers/rules` is present in the
  installed binary but the Clash rule-provider payload fields (`ruleCount`, `vehicleType`) are
  absent. T-02's E-7 is now **confirmed by evidence**, not inherited.
- F-3 — SIGHUP reload exists but recreates the whole instance, and the OpenRC service defines
  no `reload()` → fails B-12. Rejected.
- F-4 — sing-box **does** watch local rule-sets (`sagernet/fswatch`), but its success path is
  **silent**, so `sc` has no channel to obtain evidence a reload happened; B-4/B-5 forbid an
  unevidenced "applied" claim. Deferred decline recorded in `.harness/rejected-decisions.md`
  (`trust-singbox-fswatch-ruleset-reload`) with an unblock path.
- Method limit stated honestly in the doc: the architect has no shell (Read/Glob/Grep only), so
  no `sing-box version` and no live Clash API query; conclusions rest on static probes of the
  installed binary plus repo files, and F-3's "recreates the instance" is explicitly labelled
  as reasoned rather than executed. **PM accepts this** — the design is constructed to depend
  on no unverified fact (if the watcher works the restart is redundant-but-correct; if not, the
  restart is the only thing that applies the data). The gate reviewer is asked to test exactly
  that claim.
- F-1 — `install.sh:352-357` installs the *latest* release, so the sing-box version is **not
  pinned** and hosts differ. This is the strongest single argument against a
  version-conditional reload path, and it is a genuinely new project fact.

Design shape accepted for gating: `ruleset_state()` returns `(status, digest)` from **one**
read (D-2 — two facts, one on-disk query), `ruleset_report()` keeps its exact T-02 contract as
a status-only view so `generate_config`/`usable_tags`/`_warn_degraded` are untouched, and
`changed_usable_tags()` counts a tag only if usable in `after` AND digest-differing — which
also prevents restarting into an externally-corrupted `.srs`. `gained ⊆ changed` is proven, so
"exactly one apply per run" is structural rather than asserted.

Carried to the gate as explicit challenge items (not silently accepted):
1. **D-8** — no committed test tree, for a change that is *about* restart behaviour. Both stage
   1 and stage 2 flagged this as their weakest decision; the architect states the gate reviewer
   is the only actor who can widen AC-22. PM concurs that this is the gate's call, not the
   PM's, and asks for an explicit ruling.
2. **F-4** — whether "silent success path ⇒ no evidence channel" is sound, or whether a
   cheap evidence channel was missed.
3. **G-1…G-7** — whether the NFR-1 safety gates are actually pass/fail-testable as written,
   with specific attention to the scratch-script clause (the real T-02 gap) and the new
   deny-by-default `subprocess.run` tripwire.

### Stage 3 → 4 decision (advance under conditions) — 2026-07-31

Gate verdict **`APPROVED FOR DEVELOPMENT`** (framework equivalent: approved *with conditions*),
0 BLOCKER, 3 MAJOR, 5 MEDIUM, 6 LOW/NIT, conditions **C-1 … C-11 binding**. No `BLOCKED:
NEEDS-HUMAN`. Intervention check after stage 3: `.harness/intervention.md` absent.

**Transcription note.** The gate-reviewer agent runs Read/Glob/Grep-only and could not write its
own file. The PM transcribed its deliverable verbatim into `03_GATE_REVIEW.md` — findings,
rulings, conditions and verdict unedited. The PM authored no review content. (Same limitation
applies to the architect at stage 2 for shell access; both are recorded rather than papered
over.)

**Rulings the gate returned on the three challenge items the PM raised:**

1. **D-8 — UPHELD.** No committed test tree; diff stays at `bin/sc` + `CHANGELOG.md`
   (+ `docs/dev-map.md` by C-8). Reasoning the PM accepts: wiring a committed suite requires
   `verify_all` B.2 to stop being SKIP, which needs a runner, a rule-50 `Test:` line, a `tests/`
   layout and `baseline.json` `test_count` — that is T-07's scope, and a suite nobody runs is
   worse than none because the next task believes it is covered. Compensated by C-11 (the QA
   harness must be pasted complete and runnable verbatim) and C-9.
2. **F-4 — conclusion SAFE, one evidence claim OVERSTATED.** The gate re-ran every stage-2
   binary probe and confirmed all of them, but found `updated rule-set ` and `rule-set updated`
   *do* exist in the binary, so "no evidence channel at all" was wrong; the true statement is
   that the literal cannot be attributed to the local-file path from strings alone. Restart-only
   survives on three stronger grounds (our own `log.level=warn`, B-12's no-systemd-only-oracle
   rule, and the undetermined fswatch-vs-`replace()` question). Routed to the architect as a
   correction, not a rollback — the decision did not change, only its stated basis.
3. **G-1…G-7 — G-1/G-5/G-6/G-7 checkable; G-2, G-3, G-4 NOT pass/fail as written.** The most
   consequential finding in the whole review: **`systemctl is-active` cannot detect a restart**
   (it prints `active` on both sides), so the criterion that exists *because* T-02 bounced the
   owner's live service would have passed *during* that incident. C-2 replaces it with
   `MainPID` + `ActiveEnterTimestamp` identity. C-3 restores T-02's **two-layer** guard (the
   design had reproduced only the weaker half) and converts the scratch-script clause from an
   honour-system list into a grep over a single shared loader.
4. **Concept economy — right count; `gained ⊆ changed` PROVEN**, conditional on C-5's digest
   contract. The gate attacked the invariant with six boundary cases (including
   externally-fixed permissions and a completed partial write) and it held.

**PM decision on the two findings that touch `01` (F-2 AC-24 witness, F-6 AC-21 method):**
**no rollback to the analyst.** Both findings *strengthen* their ACs rather than contradict them
(AC-24 keeps `is-active` and gains a real witness; AC-21 keeps `py_compile` and gains
banned-construct regexes), and the gate — the actor entitled to rule — explicitly declined to
roll back. Rolling back would cost a full cycle and change no behaviour. The strengthened forms
are binding on stages 4-6 as C-2 and C-6, which is where they are actually checked. Recorded
under standing decision authority.

**C-1 handled before stage 4, not before stage 6.** The gate allowed the compaction any time
before stage 6, but the developer implements *from* `02`, so letting it be edited underneath a
running developer would be an avoidable read inconsistency. Routed to the architect immediately:
`02_SOLUTION_DESIGN.md` **559 → 495 lines** (F.6 cap 500, 5 lines of margin), no decision lost
(D-1…D-9, A-1/A-2, R1…R10, G-1…G-7 and §10.5's order all verified present after compaction), and
the two accuracy corrections applied to both the design and the two affected
`.harness/rejected-decisions.md` records. Also folded C-5 and F-10 into §4 as binding contract
text so the implementation cannot get the invariant wrong by prose ambiguity. **This is a
document fix, not a rollback** — no rollback counter incremented; stage 3's verdict stands
unchanged and was not re-run.

