# 02 — Rationale · T-19 `ruleset-staleness-visibility`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| "Is this rule-set usable?" | `srs_reject_reason(head, size)` | `/home/alan/Programs/singbox-cli/bin/sc:746` | Reuse as-is. Not touched, not re-derived, not consulted a second way. |
| One rule-set file's on-disk facts, from one read | `ruleset_state(path)` | `bin/sc:761` | **Extend** — one element (`mtime`) from one `os.fstat()` on the file object the read already holds. This is the only new fact in the subsystem. |
| The whole-disk snapshot | `ruleset_states()` | `bin/sc:826` | Reuse; widens with its element type. Already the sole snapshot for `cmd_update_rules` and `_doctor_rulesets`. |
| Stopping the widening before config generation | `_status_view()` | `bin/sc:843` | Reuse as-is — its docstring already declares itself "where a widening of the snapshot tuple stops". This design is the case it was written for, so FR-5 costs zero lines. |
| Content-change pairing | `changed_usable_tags(before, after)` | `bin/sc:861` | Reuse; destructuring widens, semantics untouched. `.harness/rejected-decisions.md § mtime-or-size-as-a-ruleset-change-signal` stays in force: mtime is displayed, never compared. |
| A bilingual phrase for a rule-set fact, resolved at print time | `_status_text(status)` | `bin/sc:897` | **Pattern reused, not extended.** `_age_text(mtime)` is its sibling: same section, same "must stay a function because `LANG` is assigned after import" reason, same one-argument shape. Merging age into `_status_text()` would make one renderer answer two questions. |
| Rendering a rule-set fact that may be absent | `t("{reason}, size unavailable")` | `bin/sc:2373` | Reuse of the *idea* (a word, never a number, when the read produced nothing). `sc doctor`'s own key is untouched; T-19 adds the age counterpart. |
| Bilingual output | `t()` + `TRANSLATIONS["zh"]` | `bin/sc:123`, `:403` | Reuse as-is. No `en` table, so every new key is its own English sentence. |
| Restart the service | `restart_service()` | `bin/sc:1962` | **Extend** with a return value. Its two direct callers are `reload_or_restart()` (`:1972`) and `cmd_update_rules()` (`:2809`); the six commands in out-of-scope item 5 all go through `reload_or_restart()`, which ignores the new return. |
| Apply-decision-per-run | the `if changed and CFG_PATH.exists():` block | `bin/sc:2796-2810` | Reuse as-is; only the claims *about* it change. T-10's comment block stays. |
| A duration formatter anywhere in the tree | (none found — `time` is not even imported; `sc update-interval` delegates every schedule to `systemctl list-timers`) | — | New function justified; one stdlib import (`time`). |
| A generic "run outcome" recorder / envelope | (none found, and Q-2 forbids adding one) | — | Not built. Three variables that already exist are combined in one expression. |

**Dependencies:** one new *stdlib* import, `time`, for `time.time()`. No third-party package, no service,
no file format, no constant, no module-level name.

## Risk analysis

| # | risk | mitigation |
|---|---|---|
| R-A | **A fixture restarts the developer's live sing-box.** `is_running()` runs `systemctl is-active sing-box` against the real host whenever `SYSTEMD` is true; if the host's service is up it returns `True` and `restart_service()` then runs `systemctl restart sing-box`. AC-B6 requires `SYSTEMD = True`, so this is not hypothetical. | K-19 makes replacing the module's `subprocess.run` binding a precondition of setting `SYSTEMD = True`, and forbids the replacement from execing `systemctl`. K-18 restates the safety floor. V-8/V-9 assert against the stub's call log, which is also the evidence that no real command ran. |
| R-B | **The widening leaks into `config.json`.** A destructuring edit made in the wrong place (e.g. widening `_status_view()`'s *return* instead of its *input*) would put a timestamp on the config path and break T-15's differential. | K-5 pins the return shape; the frozen set names `generate_config()`, `usable_tags()`, `_warn_degraded()` and `ruleset_report()`; V-6 is a byte comparison at the **same** fixture path (a second `mkdtemp()` root yields a 100 % mismatch that reads exactly like a refactor bug — insight-index 2026-08-01). |
| R-C | **The DIGEST CONTRACT acquires a second, differently-shaped invariant.** If the `fstat` sat outside the `try`, or if `mtime` were defaulted to `0.0`, the file would have three equivalences instead of one and BC-3/BC-1 would disagree. | K-3 and K-4: one `try`, one equivalence chain, docstring updated in the same hunk. V-7 exercises the empty-file corner the chain is written for; V-2/V-4 exercise the `None` corner. |
| R-D | **A new zh string collides with a load-bearing grep token.** `失败：` in `bin/sc` output means "this file was not updated"; T-19 writes squarely in that output region, and the natural Chinese for a failed restart is `重启失败`. | I-13 is `重启未成功`, and the note under the interface table states the reason. V-16 greps every added zh string for `失败` in any form. |
| R-E | **`sc status` becomes measurably slower or noisier under redirection.** The section adds four full file reads to a command that previously did none, and `cmd_status`'s prints are block-buffered while its `ip` subprocess writes fd 1 immediately (R-33). | The reads are local, chunked at 64 KiB, and are the only honest source of the status printed beside the age; RS-4 asks the gate to confirm the NFR reading. K-7 forbids a selective `flush=`, so the section joins the existing buffered block and adds no new class of reordering (Q-12). V-3/V-4 capture through a pipe. |
| R-F | **A future edit re-introduces an unconditional restart or an unconditional success claim.** `verify_all` B.1 is a syntax gate and would not notice; this is T-10's R6 restated. | K-10 keeps T-10's load-bearing comment in place; I-5 concentrates the run's truth in one expression, so a future edit that wants to lie has to edit the line that names `ok`; V-12 cross-checks every claim against the stub call log in four fixture states and both languages. |
| R-G | **A refuted premise.** P-3/P-4 are the whole justification for half 2; if HEAD already exited non-zero on a failed regeneration, half 2 would shrink to the outcome wording. | The design is already the minimum for each defect separately (see the smaller-alternative table): if P-3 is refuted, E-10's `regen_ok` term is the only casualty; if P-4 is refuted, E-9 and I-13 are. Neither refutation touches half 1 (Q-1). Stage 4/6 measure both before writing the code, per `01`'s `## Premises to be measured`. |
| R-H | **`install.sh` step 6 mislabels a new failure class** (Q-9). | Accepted upstream, not fixed here (out-of-scope 4). RS-3 restates it so stages 5/6 do not raise it as a T-19 defect. |

## Why the timestamp does not re-open "no second opinion"

T-05 made rule-set health flow through one function and deliberately kept `st_size` off the graph: the
byte counter inside the one reader already answers "how many bytes", so a `stat` would be a *second
answer to a question already answered*, and the two could disagree (`sc doctor` would print a size that
did not decide the status it sits beside).

A timestamp is a different kind of thing. The read cannot produce it at all, so obtaining it is not a
second answer — it is a first answer to a new question. What the design still owes is that the answer
is about the **same bytes**. `os.fstat(fh.fileno())` inside the existing `with` block pays that: the
descriptor is the one the digest was computed from, so no rename, replace or deletion between the read
and the query can make the timestamp describe a different file. A `path.stat()` at a display site
would not pay it, which is why K-1 forbids it and RS-6 asks for the decision to be recorded durably.

The DIGEST CONTRACT then extends rather than forks: the `fstat` lives inside the same `try`, so the
same single condition — "a complete read happened" — governs all three of digest, size and mtime.
BC-3's readable empty file gets a real age for exactly the reason it already gets a real `0`.

`_status_view()` needs no argument about any of this: it was written as the shield, and
`changed_usable_tags()`'s pairing is by tag over digests, so a fourth element it never reads cannot
change what it decides. The rejected decision
`.harness/rejected-decisions.md § mtime-or-size-as-a-ruleset-change-signal` is untouched in substance:
it declines mtime as the *content-change* signal, and Q-5 already recorded why the property that record
objects to (renewal on every successful fetch) is precisely the property a "how long since the last
successful update" display needs.

## How T-20 consumes this (FR-2)

`_doctor_rulesets()` (`bin/sc:2354`) already loops over `ruleset_states()` and already destructures
`size` to build `t("{reason}, {size} bytes")`. After T-19 that same loop holds `mtime`, and
`_age_text(mtime)` is in scope. T-20's rule-set-age row is therefore an edit to one existing format
string (or one extra row built from values already in hand) — no new query, no new renderer, no second
vocabulary, and no change to `sc doctor`'s class constants, since Q-4 forbids deriving a
PROBLEM/UNKNOWN verdict from an age. That is the whole of the coupling: T-19 must not add the row
(out-of-scope 10), and T-20 must not add a second age derivation (K-17).

## Options considered and dropped

- **A `ruleset_age()` returning seconds plus a separate `_age_text()` renderer.** Two functions where
  the display is the only consumer; the seconds value has no second caller, and Q-4 forbids the
  threshold that would give it one. Dropped as speculative generality.
- **`_age_text(mtime, now=None)` for testability.** Rejected: a fixture sets the mtime relative to
  `time.time()` just as easily (`os.utime`), and the parameter would be the first crack in FR-2's "no
  command-specific argument" property. V-1/V-5 need nothing beyond `os.utime`.
- **A module-level `AGE_UNITS` tuple** (the `RULESET_FILES` / `TELEMETRY_NAMES` precedent). It has one
  consumer and no cross-file meaning, so the tuple lives inside `_age_text()`; the precedent applies to
  data other code must agree about, and nothing else needs to agree about this ladder.
- **Printing the age in `sc ls` or in the degradation warning.** No requirement asks for it, and
  `_warn_degraded()` is a config-generation-time warning on stderr — adding a disk-age fact to it would
  put an age on the config path's output for no stated need.
- **Making `reload_or_restart()` propagate the restart's status.** It would change `sc reload`,
  `sc use`, `sc add`, `sc rm`, `sc ipv6` and `sc telemetry` — exactly the six commands out-of-scope
  item 5 protects — and no requirement in T-19 asks about them. Deliberately left as a residual of
  T-10's R5, not claimed here.
- **A `SuccessExitStatus=` or `Restart=` edit to the unit.** Q-7 measured that the shipped unit is
  `Type=oneshot` with one un-prefixed `ExecStart` and neither directive, so a non-zero exit is already
  recorded as a failed unit. Nothing to change (out-of-scope 2).

## Evidence relied on

| claim | source |
|---|---|
| `_status_view()` is the declared stop-point of a snapshot widening | `bin/sc:843-849` docstring; `docs/dev-map.md` "Per-file rule-set state" |
| `size` is the read's own counter and `st_size` is deliberately absent | `bin/sc:761-786` DIGEST CONTRACT; `docs/dev-map.md` "One file's on-disk facts" |
| `restart_service()`'s only direct callers are `reload_or_restart()` and `cmd_update_rules()`; the six protected commands reach it only through the former | grep of `bin/sc` for `restart_service|reload_or_restart` → `:1962, :1969, :1972, :2158, :2180, :2196, :2627, :2690, :2809, :2927` |
| Widening `restart_service()` was already identified and filed as a pool-row candidate rather than a T-10 defect | `docs/features/_archived/ruleset-update-no-needless-restart/02_SOLUTION_DESIGN.md` R5 |
| The outcome line is a closed set printed exactly once, immediately before the exit | same document, §6.2/§6.3; `bin/sc:2811-2823` |
| HEAD prints "config regenerated" on a `gained` run regardless of `generate_config()`'s return | `bin/sc:2798-2803` |
| HEAD ignores the restart command's status | `bin/sc:1962-1966` (`check=False`, no return), `bin/sc:2809-2810` |
| `is_running()` shells out to the live `systemctl is-active` | `bin/sc:2001-2007` |
| `TRANSLATIONS` has no `en` table, so a key prints verbatim in English | `bin/sc:123`, `:403-405`; `docs/dev-map.md` "Bilingual output" |
| `check-i18n-parity.sh` covers `install.sh` only | `docs/dev-map.md` "Bilingual parity proof"; insight-index 2026-08-01 |
| `main()` reassigns `LANG` and `CLASH_PORT` after import (the two vacuity traps) | `bin/sc:3094`, `:3126-3131`; insight-index 2026-08-01 / 2026-08-14 |
| `_init_files()` hard-codes `/var/lib/sing-box` | insight-index 2026-08-01; `docs/dev-map.md` "Patterns to avoid" |
| A `generate_config()` differential must use one fixture path | insight-index 2026-08-01 |
| `失败：` is a load-bearing diagnostic grep in `bin/sc` output | `.harness/insight-index.md` (T-02 lineage) restated in the PM dispatch |
| `git diff --stat`'s bar counts insertions **plus** deletions | insight-index 2026-08-14 |
| `sc status`'s buffered/unbuffered reordering is pre-existing | insight-index 2026-08-14; `01` Q-12 |
| `time` is not imported by `bin/sc` today | `bin/sc:3-18` |
| The four rule-set filenames and their order | `bin/sc:98-103` |

## Size accounting

Expected diff, honestly counted (added lines only, as `git diff --numstat`'s first field, never the
`--stat` bar):

| file | added | removed | note |
|---|---|---|---|
| `bin/sc` half 1 | ≈ 45 | ≈ 12 | of which ≈ 18 are docstring/comment; the executable core is `import time`, one `fstat` line, 7 data rows, `_age_text()`'s 9 lines, `cmd_status()`'s 3, and 8 single-token destructuring changes |
| `bin/sc` half 2 | ≈ 22 | ≈ 12 | of which ≈ 9 are docstring/comment; the executable core is 4 lines in `restart_service()`, one `ok = …` line, one new `elif` branch, one `sys.stderr.write` for one `sys.exit`, and one `sys.exit(1)` |
| `README.md` / `README.zh-CN.md` | 1 each | 1 each | one line each |
| `CHANGELOG.md` | 1 | 0 | one entry |

The second half is T-18-sized. The first half is larger than T-17/T-18 and the reason is stated rather
than hidden: about a third of it is the DIGEST CONTRACT docstring, which is the artifact that keeps the
subsystem's single-reader property true, and eight of its lines are one-token destructuring edits that
FR-1 makes unavoidable the moment the snapshot carries a fourth fact. The alternative that removes them
is priced in `02_SOLUTION_DESIGN.md`'s `## Smaller alternative rejected`, half 1, row 1.
