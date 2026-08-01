# Delivery Summary — T-14 `config-composition-layer`

- **Task**: `config-composition-layer` — turn `config.json` generation from one hardcoded ~70-line
  dict into a composition (base template as data → ordered overlays → user override), with explicit
  array directives and drift detection, under a byte-identity gate.
- **Mode**: full (7 stages)
- **Decision authority**: deferred-human, defer-do-not-ask. Standing grant from the owner
  (「你来决策就行」). **No `BLOCKED: NEEDS-HUMAN` was raised** — no safety red line was reached.

## Stages traversed (all 2026-08-01)

| # | Stage | Agent | Verdict |
|---|---|---|---|
| 1 | Requirement analysis | requirement-analyst | READY — 30 ACs, 26 BCs, 7 NFRs, 16 decisions, 0 open questions |
| 2 | Solution design | solution-architect | READY — D-16 decided (single `override.json`) |
| 3 | Gate review | gate-reviewer | **APPROVED FOR DEVELOPMENT** + 8 conditions |
| 4 | Development | developer | AC-1 148/148; 91 semantic checks; 8/8 conditions discharged |
| 5 | Code review | code-reviewer | **APPROVED** — 0 CRITICAL, 0 MAJOR, 2 MINOR, no design drift |
| 4′ | In-stage return | developer | README factual error corrected (both languages) |
| 6 | QA test | qa-tester | **CHANGES REQUIRED** — 1 MAJOR, 2 MINOR |
| **1′** | **Requirement addendum** | **requirement-analyst** | **ROLLBACK** — BC-27 / AC-31 / D-17 ruled; MINOR→R-15/R-16 |
| 4″ | Development (scoped fix) | developer | `islink` discrimination; non-vacuity mutant 12/26 red |
| 5′ | Delta review | code-reviewer | **APPROVED** (delta) — 0 CRITICAL/MAJOR/MINOR, 2 NIT |
| 6′ | QA re-verification | qa-tester | **PASS** — MAJOR closed, earlier verdict superseded |
| 4‴ | Record correction | developer | `04` §17.1 false claim retracted, count corrected |
| 4⁗ | Source comment correction | developer | comment-only, +3/−2, token stream proven identical |
| 7 | Delivery | PM | this document |

## Rollbacks: 1

**Stage 6 → stage 1′.** QA found a **MAJOR**: a **dangling symlink** at
`/etc/sing-box/override.json` was silently treated as *absent* — `rv=True`, empty stderr,
`config.json` regenerated and replaced, `exit=0`, and no drift warning either (because `sc` wrote
the file, so the record matched). **The user's entire override was discarded without a word — the
exact failure this task exists to remove, reproduced inside the fix for it**, on the
version-controlled-symlink workflow D-14 had deliberately blessed.

Routed to the **requirement-analyst**, not the developer, because **no AC forbade it**: it sat in
the seam between BC-7 ("empty ≡ absent") and BC-9 ("non-regular **after symlink resolution**"), and
`02` §5.4 had *specified* the behaviour (`FileNotFoundError -> None (absent)`), which a developer may
not overrule. The analyst ruled it **malformed** — declining to lean on the internal precedent at
`bin/sc:732-734` (calling it corroborating, not decisive) and reasoning instead from BC-7's own
discriminator: *can this shape encode a typo?* Empty cannot; a symlink naming a moved target can.
It then ruled the fix needed **no design change**, saving a stage-2 transition on the merits.

Three further in-stage returns to the developer, none of them defects in the sense of failed work:
4′ (a README factual error found at review), 4‴ and 4⁗ (record and source-comment corrections
following stage 5′'s NITs). No stage was rolled back twice; the 3-consecutive-rollback stop was
never approached.

## Final `verify_all` result: **PASS**

```
PASS: 16   WARN: 1   FAIL: 0   SKIP: 1
```

- **0 FAIL** — the gate the task was held to.
- The single **WARN is `[F.6] Active task docs <=500 lines each`**, caused by this task's own stage
  documents. It was predicted by the gate before any code was written, is WARN-only, and **clears on
  archive** (F.6 skips `/_archived/`), exactly as it did for T-05 and T-13.
- `SKIP` is `[B.3] Lint`, unchanged and pre-existing.
- A pristine **clone** at `f642ca7` reads **17 / 0 / 0 / 1**. The delta is therefore exactly the one
  predicted doc-size WARN and nothing else. A clone was used, never a `git worktree` — in a worktree
  `.git` is a *file*, which turns A.1/A.2 to SKIP and falsely reports 14/4.

## Baseline changes

`.harness/scripts/baseline.json` still reads `test_count: 0`, **deliberately**. This task's
harnesses are throwaways (O-8); a committed `bin/sc` suite is open row **R-9**, which carries its own
fail-closed safety criteria and is explicitly not opened here. Stated rather than quietly left.

## Evidence the gate actually held

- **AC-1 (byte-identity) reproduced twice, independently.** The developer measured 148 runs; QA
  **rebuilt its own harness from the ACs** rather than inheriting, and measured **164 runs**
  (82 points × 2 languages, 860 comparisons) against a pristine `f642ca7` clone — byte-identical
  `config.json`, stderr, boolean return and `nodes.json`. Re-run green after every subsequent change,
  including the final comment-only edit, **unrelaxed and never re-baselined**.
- **Non-vacuity proven before the refactor, not after.** The developer proved its harness FAILS on
  three mutants *before touching the literal* — including **M2, a pure key reorder that changes no
  value**, the failure mode R-1 named as hardest to spot by eye. QA independently used **six**.
- **The fix itself was proven non-vacuous.** Reverting only the five `islink` lines turns 20 of QA's
  50 BC-27 assertions red, reproducing the MAJOR verbatim (`exit code 0`, `config.json NOT
  byte-identical`, `restart_service called 1x`, the run even printing `Reloaded` / `已重新加载`),
  while the other 30 stay green — which is what shows the fix is confined to its own arm.
- **The literal move was a pure text move**, done by script and never re-typed: `diff` shows exactly
  four hunks (the name + three position-holding placeholders). Stage 5 re-verified it position by
  position, down to an incidental double-space and a list's wrap point surviving.
- **The final comment edit was proven inert by token stream**, not by reading the diff: 11 778 tokens
  identical on both sides with `COMMENT`/`NL`/`INDENT`/`DEDENT` dropped.

## Safety record

- Live service **provably untouched at every checkpoint** across all stages —
  `MainPID=2887037`, `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST`, identical at the final
  reading. Measured with `systemctl show -p MainPID -p ActiveEnterTimestamp`, **never `is-active`**,
  which prints `active` on both sides of a restart and cannot detect a bounce at all.
- `/etc/sing-box/` **never written**: `override.json` and `.config.sha256` do not exist on this host,
  and `config.json`'s mtime is unchanged from before the task.
- `/usr/local/bin/sc` **never invoked**; `install.sh` never executed; `_init_files()` never driven
  (it hard-codes `/var/lib/sing-box`).
- Every harness used the `docs/dev-map.md` neutralisation recipe verbatim and kept both load-bearing
  assertions — `assert os.geteuid() != 0` (what makes the mode-`000` `unreadable` fixture real rather
  than silently degrading to `usable`) and the all-seven-paths-inside-temp-root assertion.

## Files changed

```
 .harness/rejected-decisions.md |  21 ++
 CONTEXT.md                     |  37 +++
 README.md                      |  51 ++++
 README.zh-CN.md                |  51 ++++
 bin/sc                         | 613 +++++++++++++++++++++++++++++++++++------
 docs/dev-map.md                |  28 +-
 docs/tasks.md                  |  34 ++-
 7 files changed, 740 insertions(+), 95 deletions(-)
```

`install.sh`, `uninstall.sh`, `systemd/` and every timeout are **untouched**, as scoped.
`CHANGELOG.md` is **not** modified — the earlier report of it was a stale git snapshot, confirmed at
delivery. `docs/features/config-composition-layer/` is untracked (stage documents).

**Zero config content change**: no urltest group (T-15), no DNS change (T-16), no telemetry list
(T-17), no source profiles (T-21). T-14 ships **zero** content overlays by design (D-12) — the point
was to make those four edits small, not to make them.

## What T-15 / T-16 / T-17 / T-21 inherit

- `CONFIG_BASE` is module-level data; a change to the emitted config goes there or into an overlay,
  **never back into `generate_config()` as a literal**.
- Five directives — `$replace`, `$prepend`, `$append`, `$before`, `$after` — through **one**
  `_merge()`. Anchored insertion matches exactly one element and errors on 0 or >1, so T-16's and
  T-17's insertions into `dns.rules` compose at their own anchors with **no index arithmetic**
  (a numeric index written by T-16 would be wrong the moment T-17 inserts earlier).
- **A known boundary, recorded so it is not discovered as a surprise**: the vocabulary cannot modify
  a value *nested inside* an array element (e.g. adding to a rule's `query_type` list). Such a need
  decomposes into an insertion, or into editing `_runtime_overlay`'s own dict — both still
  composition. Stage 5 and the gate independently confirmed every named consumer's need is
  expressible.

## Outstanding risks

| # | Risk | Status |
|---|---|---|
| R-4 | `_write_private()` / `save_nodes()` use `os.fdopen(fd, "w")` with **no `encoding=`**, so a non-ASCII node tag under a non-UTF-8 locale raises. QA refined it: the raise actually lands first in `load_nodes()`, not the write side. | Pre-existing; ruled out of scope by the gate. **Needs a pool row.** |
| R-15 | A non-object element in `dns.rules`/`route.rules`, and a 500-level-deep override, both reach a Python traceback rather than the `OverrideError` sentence. | Filed in `docs/tasks.md`. Analyst ruled the coherent fix is one exception envelope (an error-model change needing the architect), not a depth counter. |
| R-16 | A bare **object** silently replaces an existing array — the unguarded mirror of D-5. | Filed. Contained: the real `sing-box` 1.13.15 rejects the result, so `sc reload` fails loudly and the service is untouched. |
| BC-15 | A *valid* override that removes `experimental.clash_api.external_controller` or the `proxy` tag breaks `sc use`/`sc status` while still passing `sing-box check`. | Not prevented by design (a "what `sc` depends on" schema serves none of the five consumers); **documented in both READMEs**. |
| — | A parent component that is a *regular file* raises `NotADirectoryError` → reported malformed rather than absent. | Pre-existing, unchanged, fail-safe in direction (loud, no write). Recorded so it is not later misread as a BC-27 regression. |
| — | Python **3.6 is statically audited, not executed** — no 3.6 interpreter on this host. The `posixpath` claim was verified on 3.8.2 (the nearest interpreter on the same side of the 3.10 rewrite) and 3.12.3. | Owed and labelled as such, as in T-13. |

## Next steps for the owner

1. **Review and commit.** Nothing is committed or pushed, per your instruction.
2. `CHANGELOG.md` has no T-14 entry yet — it was deliberately left to delivery by project convention
   and no AC depends on it.
3. **R-4 needs a pool row**; R-15 / R-16 are already filed in `docs/tasks.md`.
4. On upgrade, existing hosts are silent by design (BC-16: an absent drift record means *unknown*,
   not drift — otherwise the warning would fire on 100% of installs at first upgrade and train users
   to ignore the one warning that must stay loud).

## Insight

- 2026-08-01 · A differential harness for `generate_config()` must run baseline and candidate at the **same** fixture path, because `RULES_DIR` is emitted verbatim inside `route.rule_set[].path` — two `mkdtemp()` roots yield a 100% config mismatch that reads exactly like a refactor bug · evidence: config-composition-layer
- 2026-08-01 · `main()` reassigns `LANG` from `_load_lang()` after import, so a `bin/sc` harness that sets only `sc.LANG` renders **English** on every `main()`-driven path — Chinese assertions then pass vacuously, because "no newline, no 失败" is also true of English · evidence: config-composition-layer
- 2026-08-01 · `os.stat` follows symlinks, so a **dangling** symlink raises `FileNotFoundError` and is indistinguishable from an absent file — any "absent" arm written with `os.stat` silently swallows a user-owned file that is present; `os.path.islink` is the discriminator and, being `lstat`-based, also returns False for a broken *parent* component · evidence: config-composition-layer
- 2026-08-01 · `os.path.realpath` is not raise-free on any Python this project targets: `posixpath._joinrealpath` calls `os.readlink` **unguarded** at 3.8.2 and **still** at 3.12.3 — the 3.10 rewrite guarded the `lstat`, not the `readlink` · evidence: config-composition-layer
