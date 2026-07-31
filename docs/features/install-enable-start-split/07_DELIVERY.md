# Delivery Summary — install-enable-start-split (T-01)

- **Task**: `install-enable-start-split` — make `install.sh` report its true outcome: register autostart
  unconditionally, preserve the real error cause, print an honest closing banner, and exit non-zero on
  failure.
- **Mode**: full (stages 1 → 7)
- **Delivered**: 2026-07-31 · **Status**: DELIVERED (uncommitted — the stream owns commit and push)

## Stages traversed

| # | Stage | Verdict |
|---|---|---|
| 1 | requirement-analyst | `READY` |
| 2 | solution-architect | `READY` |
| 3 | gate-reviewer | `APPROVED WITH CONDITIONS` |
| 4 | developer | implemented, `verify_all FAIL: 0` |
| 5 | code-reviewer | `APPROVED` |
| — | **coordinator intervention** | scope expanded — former T-04 absorbed |
| 1b | requirement-analyst (rev. 2) | `READY` |
| 2b | solution-architect (rev. 2) | `READY` |
| 3b | gate-reviewer (rev. 2) | **rollback → stage 2** (finding G-1) |
| 2c | solution-architect (rev. 3) | `READY` |
| 3c | gate-reviewer (rev. 3) | **PASS** — no FAIL, no WARN in any dimension |
| 4b | developer (rev. 3) | implemented, no drift |
| 5b | code-reviewer (rev. 3) | `APPROVED` — 0 critical, 0 major, 1 minor, 5 nit |
| 6 | qa-tester | `APPROVED FOR DELIVERY` — 0 defects in `install.sh` |
| 7 | delivery (PM) | this document |

## Rollbacks: 3

1. **Stage 5 → stage 1** — coordinator intervention. The owner's standing directive
   (优先用好的设计，避免不断的修修补补) invalidated the T-01/T-04 split: the tree was incoherent on its own,
   computing `INSTALL_OK` in step 7 while the banner still printed `✅ 安装完成` unconditionally, so the
   installer still lied on the failure path. PM routed to stage **1** rather than the instructed stage 2,
   because `01` actively *forbade* the new scope (§4.1 put the banner out of scope; B-11/AC-12 made
   "exit 0 on both paths" normative) and designing against it would have drawn a correct requirement-gap
   bounce from the gate.
2. **Stage 3b → stage 2c** — gate finding **G-1**: `INSTALL_LOG` served as both the redirection target and
   the string shown to the user, so on an unwritable-log path the installer printed 「详细原因见 /dev/null」.
   The gate offered a cheaper "document it" path; PM declined it and routed the fix, because shipping a
   documented dishonesty is a smaller instance of the defect the task exists to remove.
3. *(not a stage rollback)* **Stage 5b halted once** on a platform classifier outage — four consecutive
   `Agent` dispatch failures. PM declared a hard stop rather than reviewing the code itself, skipping to
   stage 7, or writing a premature delivery doc; the stage ran to completion on retry.

## Final verify_all result: PASS

```
PASS: 16   WARN: 0   FAIL: 0   SKIP: 2      (exit 0)
```

The two SKIPs (`[B.2] Tests pass`, `[B.3] Lint`) are pre-existing and unchanged — no committed runner is
configured. `[F.6]` (doc size) went from WARN to PASS after PM compacted `PM_LOG.md` (554 → 204 lines), the
one defect QA found outside the code.

## Baseline changes

- **Test count**: no committed baseline change. `.harness/baseline.json` deliberately left untouched — it
  is a tracked file and editing it would breach AC-10 while asserting a count for gitignored suites. The
  QA suites are uncommitted under `test/` (gitignored via `.gitignore:19`).
- **Assertions executed this task** (all in gitignored harnesses): 334 (developer suite, re-run and
  hardened by QA) + 341 (QA-authored adversarial suite) = **675**, plus a mutation run of **17 mutants,
  17 killed, 0 survived**, which is what demonstrates neither suite is vacuous.
- `install.sh`: 386 → 497 lines. The code reviewer's required design-discipline finding is that the +111
  lines are **requirement-carried with no speculative generality** — roughly 22 lines are the mandatory
  bilingual string table alone.

## Files changed

```
 CHANGELOG.md  |   1 +
 install.sh    | 157 +++++++++++++++++++++++++++++++++++++++++++++++++---------
 3 files changed, 136 insertions(+), 24 deletions(-)
```

(`docs/tasks.md` and `docs/features/` are pipeline artifacts. `git diff -- bin/sc uninstall.sh systemd/
.harness/` is **empty**; `test/` does not appear at all.)

**What landed in `install.sh`**: a three-variable phase-status model (`PHASE_RULESETS`, `PHASE_CONFIG`,
`PHASE_SERVICE`) with pessimistic defaults; one `install_report()` function that derives *both* the closing
banner and the exit status from that single source; `INSTALL_LOG` (the path the user is told about) split
from `LOG_SINK` (the redirection target, promoted only on proof by a writability probe); unconditional
autostart registration before config generation; both streams of `sc update-rules` and `sc reload` captured
to `/var/log/sing-box/install.log`; and 11 new `t()` keys in **both** language branches (40/40).

## Outstanding risks

1. **AC-9 is UNVERIFIED.** The owner-stated criterion — on a machine that cannot reach GitHub, both units
   report `enabled` — was **not executed**. No network-restricted systemd VM exists in this environment.
   Deferred to T-07. Everything else was verified by a stubbed-PATH harness plus static reasoning; QA's
   report is explicit about executed-vs-reasoned throughout.
2. **AC-5 is scoped, not absolute.** "Success output byte-identical" is proven for **stdout under a stub
   that is silent on success**. On a real systemd host `HEAD` ran `systemctl enable --now` unredirected, so
   its `Created symlink …` stderr reached the terminal and now goes to the log instead. Deliberate and
   approved, but structurally unobservable by any stub (see `02` §10.3 limit 3).
3. **T-09 impact is widened by this task.** `systemd/sing-box-rules-update.service:7` has
   `ExecStart=/usr/local/bin/proxy update-rules`, a binary that has never existed (the CLI installs as
   `/usr/local/bin/sc`), so the weekly auto-update has never run on any install. T-01 does not create that
   bug and does not touch `systemd/`, but it now enables the timer **unconditionally — including on failed
   installs**, where the old code aborted before reaching it. Hosts that previously had no timer will now
   get a weekly `203/EXEC`. This raises T-09's user-visible impact until T-09 lands. systemd-only; the
   OpenRC path is correct (`bin/sc:898`).
4. **`PHASE_SERVICE=started` is optimistic.** `Type=simple` means `systemctl start` returns 0 on fork, so
   the value is a launch-command result, not a liveness fact. Accepted as B-4's definition; a liveness
   probe belongs to T-05 and must not be inferred from this variable.
5. **Log growth is unbounded.** Every run appends, including clean ones; there is no rotation (out of
   scope). `uninstall.sh:137` removes the directory wholesale.
6. **One open owner decision** (gate H-1 / design D-9): on the degraded-log path the installer names the
   real path and *denies* that this run's diagnostics were saved (truthful) rather than claiming they were
   (shorter). Reversal is cheap and local — two keys plus one `if/else`.

## Next steps for user

- Commit and push (the stream owns this; nothing was committed here).
- `.harness/scripts/archive-task --task install-enable-start-split` has **not** been run — PM has no shell
  in this session. Run it after the commit to harvest the insights below and archive the stage docs.
- Prioritize **T-09** — its blast radius is now wider (risk 3).
- **T-07** should promote the QA suites into `verify_all` `[B.2]` with the assertion floor set to **675**,
  and add the `t()` key-parity check.

## Insight

- 2026-07-31 · `install.sh`'s `t()` declares `local fmt` with no default, so a key present in only one
  language branch aborts the whole installer under `set -u` rather than printing a blank line — and the zh
  branch is only reachable by answering `2` at the language prompt, so an English-only test run cannot
  detect it · evidence: install-enable-start-split
- 2026-07-31 · `sc update-rules` prints the actual failure cause (`urlopen error timed out`) on **stdout**
  (`bin/sc:817`) while stderr carries only the aggregate count (`bin/sc:821`), so capturing stderr alone
  logs "N ruleset(s) failed to update" and loses the diagnosis entirely · evidence: install-enable-start-split
- 2026-07-31 · `systemd/sing-box-rules-update.service` has always pointed at `/usr/local/bin/proxy`, a
  binary this project never installs, so the weekly ruleset auto-update has never run on any systemd
  install; the OpenRC path (`bin/sc:898`) is correct · evidence: install-enable-start-split (filed as T-09)
- 2026-07-31 · Under `set -euo pipefail`, redirecting a command to an unwritable path fails *before* the
  command runs, so a bare `>>"$LOG"` guard would record a healthy step as failed; and a `tee` pipeline
  would let a logging fault flip a healthy phase under `pipefail` · evidence: install-enable-start-split
