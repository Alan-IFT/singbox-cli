# Delivery Summary — T-13 `config-write-permission-hardening`

- **Task:** `config-write-permission-hardening` — close the credential-exposure window when writing
  `config.json`, extend the same guarantee to every credential document the tool writes, and give
  `install.sh` a closing permission sweep over `/etc/sing-box/`.
- **Mode:** full (7 stages).
- **Decision mode:** deferred-human (`defer, do not ask`) under the owner's standing authority. No
  `BLOCKED: NEEDS-HUMAN` was raised; no safety red line was reached.

## Stages traversed

| Stage | Agent | Verdict | Date |
|---|---|---|---|
| 1 | requirement-analyst | READY — 27 ACs, 8 recorded decisions, 0 blocking questions | 2026-08-01 |
| 2 | solution-architect | READY — mechanism proven from CPython source, 13-item risk register | 2026-08-01 |
| 3 | gate-reviewer | **APPROVED FOR DEVELOPMENT** — 5 WARN, 0 FAIL, conditions C-1…C-14 | 2026-08-01 |
| 4 | developer | Implemented; `verify_all` no FAIL, zero delta vs its own pre-edit measurement | 2026-08-01 |
| 5 | code-reviewer | **PASS** — 0 BLOCKER, 0 MAJOR, 1 MINOR, no design drift; C-12 discharged | 2026-08-01 |
| 4' | developer | MINOR fixed (stale citation → drift-proof anchor); counts unchanged | 2026-08-01 |
| 6 | qa-tester | **PASS** — 106 assertions, 0 failures, 0 flakes, non-vacuity proven | 2026-08-01 |
| 7 | pm-orchestrator | this document | 2026-08-01 |

## Rollbacks

**0 pipeline rollbacks.** No stage document was ever sent back to its author for a defect, and no
stage was re-run.

One **in-stage return** at 4′: stage 5's single MINOR (a stale `bin/sc:309` citation in
`docs/dev-map.md`, displaced to `:367` by this task's own +58 lines) was routed back to the
developer, because the reviewer is read-only and only the implementer edits code. That is a defect
routed to its owner, not a rollback of an upstream document.

Two potential rollbacks were **ruled rather than bounced**, which is why the count is zero:

- The gate could have sent S-2 (the fourth deferral of a committed test harness) back to the
  architect. It instead **overturned AC-23's literal reading** — "zero delta" would forbid what rule
  50 mandates, namely turning a permanently-`SKIP` check into a real one — while upholding the
  deferral on a *new* ground: a committed step means importing `bin/sc` on the owner's live machine
  forever, which requires defusing the auto-elevate re-exec permanently, and no APPROVED requirement
  states the safety criteria that would need.
- Stage 5 could have sent the D-2 control-flow change (`save_nodes()` now `sys.exit`s inside
  `generate_config()`'s call graph) to the architect as drift. It ruled it **ship-as-designed**: on
  that path HEAD already exited via an uncaught traceback skipping the same lines, so the change is
  traceback → one translated line naming path and cause.

## Final `verify_all` result

**PASS 16 / WARN 1 / FAIL 0 / SKIP 1** in the working tree — **FAIL: 0**, the binding gate.

The delta is fully attributed, as C-4 required:

| Measurement | Result | Attribution |
|---|---|---|
| Pristine `HEAD` **clone** (`11e545b`; a clone, never a worktree) | 17 / 0 / 0 / 1 | the clone carries none of this task's stage docs |
| Working tree, before the first edit | 16 / 1 / 0 / 1 | F.6 already WARN — `02_SOLUTION_DESIGN.md` at 788 lines |
| Working tree, after delivery | 16 / 1 / 0 / 1 | F.6, now `02_SOLUTION_DESIGN.md` 788L + `06_TEST_REPORT.md` 1679L |
| QA's post-archive simulation | 17 / 0 / 0 / 1 | F.6 clears when stage docs move under `_archived/` |

The dispatch's stated baseline `PASS 17 / WARN 0 / FAIL 0 / SKIP 1` was T-05's **post-archive**
figure, not a prediction of a run today — the gate caught this as F-3 before any code was written,
and stage 4 confirmed it by measuring first. F.4 (insight-index ≤30 lines) **PASSes** throughout,
refuting the gate's "may also WARN" half. The one SKIP is B.3 (lint), unchanged.

## Baseline changes

- `.harness/scripts/baseline.json` still reads `test_count: 0` — no committed suite, by the gate's
  explicit ruling (open row R-4, and now R-9 below).
- QA built **two** harnesses from the acceptance criteria rather than inheriting stage 4's (which
  were discarded): **27 Python assertions + 79 shell assertions = 106**, 0 failures, 0 flakes across
  10× repetitions of each, plus a full pass on CPython 3.8.2. Both are pasted **verbatim and
  runnable** into `06_TEST_REPORT.md` §12, discharging C-3 — the price the gate charged for
  deferring a committed suite a fourth time. The umask guard is a separately runnable assertion:
  `python3 t13_qa.py ac2_umask_0277`.

## What actually shipped

The reporter's stated root cause did **not** survive scrutiny, and neither did the owner's framing
in full. Three stages verified independently and converged:

- There is **exactly one** write path to `config.json` and it *is* followed by `os.chmod(…, 0o600)`.
  The reporter's "never sets permissions when regenerating" is **false** for current code.
- But `Path.write_text`'s mode applies **only at creation**, so the window was at *first creation*,
  not at every regeneration; and the trailing chmod *narrows* an already-0644 file, so a legacy host
  self-heals on its first regeneration by any current build. That leaves **version skew** as the one
  surviving explanation of the reporter's `-rw-r--r--` — and is exactly why the installer sweep is
  the surface that reaches such a host.
- The dispatch's own suggested mechanism was also wrong in a way that mattered: **"`mkstemp` is
  0600" is false as an equality.** It passes `0o600` as `open(2)`'s mode argument and never chmods,
  so umask still masks it — at umask `0o277` it yields `0400`, and BC-2 demands *exactly* `0600`.

The shipped construction defeats each of the three facts with a **different** element:
`os.fchmod(fd, CRED_MODE)` on the descriptor **before the first byte** (defeats umask masking),
`O_CREAT|O_EXCL` on a fresh name plus `os.replace` (defeats mode-being-ignored-for-an-existing-file,
and yields atomicity as a by-product rather than as extra scope), and the ordering itself (defeats
the write-then-chmod window). One helper, `_write_private()`, serves all three credential-document
call sites; `settings.json` deliberately does not route through it (it carries no credential, and
any fixed mode would change observable behaviour NG-4 forbids). No `os.chmod` remains on any
credential path.

`nodes.json` was pulled into scope on evidence at stage 1 — it carried the byte-identical defect at
two sites and is the *primary* credential store, so fixing `config.json` alone would have shipped
the same hole in the more sensitive file.

**Backups: none exist.** Searched and stated plainly rather than invented. The requirement was
restated as a standing invariant covering any future temporary or backup copy, and no backup
feature was built.

The installer sweep **repairs by narrowing, loudly** — one line per file naming old and new mode,
never widening, never aborting the run, never touching `install_report()`'s banner or exit
derivation. Report-only was rejected because it would leave a named exposure in place under an
"install complete" banner; silent repair was rejected outright because changing permissions on a
user's system is itself a decision.

## The greens are earned, not asserted

Every major assertion was falsified on demand against a pristine `HEAD` **clone**:

| Assertion | New build | Pristine HEAD |
|---|---|---|
| never wider than 0600 at the publish instant | PASS | **FAIL — `config.json` at `0o666` holding 12206 bytes** |
| pre-existing target byte-identical at that instant | PASS | **FAIL — target already holds new bytes at `0o644`** |
| symlink destination untouched | PASS | **FAIL — 12214 credential bytes written *through* the link, and HEAD's trailing chmod narrowed the destination** |

C-5 (all seven `perm_*` keys reached in **both** languages under `bash -u`, run continuing every
time, with a control proving the abort path is live), C-6 (`os.replace` mode preservation **with**
its falsifier, on a named **ext4** fixture, not tmpfs), C-7 (AC-21's second half discharged by the
two-transcript diff, explicitly *not* by `check-i18n-parity.sh` §3b), C-8, C-9 and C-13 are all
discharged and each says which measurement discharged it.

## Files changed

`git diff --stat`: **10 files, +256 / −13**.

Product code is **2 files, +156 / −6** — `bin/sc` `+74/−6`, `install.sh` `+82/−0`. The remaining
eight are documentation and harness memory, every one inside the gate's pinned eleven-entry diff:
`README.md`, `README.zh-CN.md`, `CHANGELOG.md`, `docs/dev-map.md`, `docs/architecture.md` (exactly
one row), `CONTEXT.md`, `.harness/rejected-decisions.md`, `docs/tasks.md` (PM only — the developer
never touched it).

## Safety

The live service is provably untouched. `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`
(never `is-active`, which prints `active` on both sides of a restart) read **identically at six
independent checkpoints** across stages 4, 6 and 7: `MainPID=2887037`,
`ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST`.

`/etc/sing-box/*` and `/var/lib/sing-box` were stat-witnessed byte-for-byte unchanged across all 21
QA harness runs. `install.sh` was never executed; `/usr/local/bin/sc` was never invoked;
`_init_files()` was never driven; the auto-elevate re-exec was neutralised only via the `sys.modules`
shim, never by editing `bin/sc` — and stage 5 confirmed `bin/sc:88-89` is unmodified in product code.

**Nothing was committed and nothing was pushed.** The owner owns delivery.

## Outstanding risks

1. **F.6 WARN is live until archive.** Two stage docs exceed rule 70's 500-line cap
   (`02_SOLUTION_DESIGN.md` 788L, `06_TEST_REPORT.md` 1679L). QA's post-archive simulation returns
   17/0/0/1, and T-05 traversed and cleared exactly this. The design doc's over-length is a real
   process defect: the architect self-reported "约 470 行" for a 788-line document.
2. **Python 3.6 is statically audited, not executed.** No 3.6 interpreter exists on this host. Every
   API used is ≤3.3 (`os.replace` is the newest) and QA ran a full pass on 3.8.2 — but the floor is
   asserted by audit, and it is labelled as such rather than claimed as measured.
3. **A hand-made credential backup at a wide mode would be invisible to the sweep.**
   `/etc/sing-box/config.json.bak-2026-08-01-1001` exists on this host at 0600, correctly outside
   `CRED_FILES` per NG-11. Filed as R-10.
4. **The new path needs write permission on the *directory* where HEAD needed it only on the file.**
   Found by QA, unpredicted by any upstream document. Unreachable in production (root bypasses
   directory DAC; EROFS fails both paths), but it is a real behaviour change.
5. **`sc doctor` still has no permission row** — deliberately left to T-20, which will then hold the
   same "which files are credential-bearing, at what mode" judgment that `install.sh` now states.
   The convergence point is marked in the design and not built.
6. **The committed-harness debt is now five tasks old.** Filed with scope as R-9.

## Next steps for the owner

- Review and commit. Suggested product-scope message: `fix(sc): create credential files 0600 from
  the outset, sweep modes on install`.
- The `## Insight` section below is harvested into `.harness/insight-index.md` by
  `archive-task.sh`; three entries that no longer earn their line were hand-rotated into
  `docs/features/_archived/insight-history.md` first, because the script's rotation is broken.
- R-9 (committed `bin/sc` test harness) is the row the gate charged as the price of this task's
  deferral. It now has a runnable harness in `06_TEST_REPORT.md` §12 to build from.

## Insight

- 2026-08-01 · `tempfile.mkstemp`'s `0o600` is `open(2)`'s **mode argument**, not a chmod, so umask still masks it — at umask `0o277` it yields `0400`, and only an `os.fchmod` on the descriptor **before the first byte** makes the mode exactly 0600 regardless of umask · evidence: config-write-permission-hardening
- 2026-08-01 · At HEAD a planted symlink at `config.json` made `Path.write_text` write 12214 credential bytes **through** the link and the trailing `os.chmod` then narrowed the *destination*, so write-then-chmod was a redirection bug as well as a window — measured, not reasoned · evidence: config-write-permission-hardening
- 2026-08-01 · `check-i18n-parity.sh` enumerates keys **from the two tables**, so a `t <key>` *call site* naming a key absent from **both** is invisible to B.2 while killing the installer outright under `set -u` (`local fmt` has no default, and `|| true` cannot catch an expansion error) · evidence: config-write-permission-hardening
