# 01 — Rationale · T-19 `ruleset-staleness-visibility`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## EVIDENCE — what HEAD does today

Backward-looking citations, read this task. Path-and-line is deliberate here: this section proves what
was found, it is not the brief the pipeline builds from.

| # | Fact | Source |
|---|---|---|
| E-1 | `cmd_update_rules()`'s tail is: one run-level outcome line, then `if failed: sys.exit("\n" + t("{n} ruleset(s) failed to update", …))`, then `print(t("Done"))`. `failed` collects only rule-sets for which **every** base was exhausted. | `bin/sc:2811-2823` |
| E-2 | `sys.exit(<str>)` is the project's established non-zero exit idiom (`bin/sc:484`, `:2168`, `:2581`, `:2628`, …): the interpreter prints the string to stderr and exits 1. So **a failed download already fails the unit** — the goal's second clause is false for the case it names. Independently corroborated by `.harness/rejected-decisions.md § doctor-exit-status-always-zero` ("`sc update-rules` exits non-zero when rule-sets failed"). | `bin/sc` passim |
| E-3 | The gained-rule-set branch calls `generate_config()` into `regen_ok` and then prints `Rule-sets restored: {names} — config regenerated` **unconditionally**, so the line is printed even when generation returned False. | `bin/sc:2798-2803` |
| E-4 | `regen_ok == False` suppresses the restart and nothing else: the run falls through to the outcome line, `failed` is empty, `Done` prints, and the process exits **0**. `generate_config()` returns False on a write `OSError` and on a non-zero `sing-box check`, each with one stderr line. | `bin/sc:2796-2823`, `:1947-1960` |
| E-5 | `restart_service()` runs `systemctl restart` / `rc-service restart` with `check=False` and returns nothing, so a failed restart is invisible; the run then prints `Rule-sets updated: {names} — sing-box restarted to load them`. | `bin/sc:1962-1966`, `:2815-2817` |
| E-6 | The single reader returns `(status, digest, size)` from one chunked read and holds a binding contract `size is None ⟺ digest is None ⟺ no complete read`. `size` is the read's real byte count, never `st_size`. | `bin/sc:761-809` |
| E-7 | `ruleset_states()` is the 5-tuple snapshot; `_status_view()` projects it to the 3-tuples `generate_config()` / `usable_tags()` / `_warn_degraded()` destructure, and is documented as "where a widening of the snapshot tuple stops". `ruleset_report()` **is** `_status_view(ruleset_states())`. | `bin/sc:826-858` |
| E-8 | `sc doctor`'s rule-set probe already consumes `ruleset_states()` and prints the size that decided the status — the precedent for a second fact travelling with the status through the same reader. | `bin/sc:2354-2379` |
| E-9 | `cmd_status()` prints six sections and **no rule-set information at all**; four of the six are inside `if is_running():`. | `bin/sc:2224-2245` |
| E-10 | `install.sh` step 6 sets `PHASE_RULESETS="ok"` only when `/usr/local/bin/sc update-rules` exits 0, and otherwise prints its "ruleset download failed" warning. | `install.sh:567-570` |
| E-11 | The shipped unit is `Type=oneshot` with `ExecStart=/usr/local/bin/sc update-rules` — no `-` prefix, no `SuccessExitStatus=`, no `Restart=`. The timer is `OnCalendar=weekly`, `RandomizedDelaySec=1h`, `Persistent=true`. | `systemd/sing-box-rules-update.service:1-7`, `.timer:1-10` |
| E-12 | The OpenRC periodic script written by `sc update-interval` is `#!/bin/sh\n/usr/local/bin/sc update-rules\n` — the same command, so an exit-status change reaches it for free. | `bin/sc:2894-2897` |
| E-13 | Both READMEs describe `sc status` as "service status, TUN interface, current node, egress IP" on one line each — the only user-facing text a new section falsifies. | `README.md:245`, `README.zh-CN.md:245` |
| E-14 | `失败：` is the zh rendering of `"failed: {e}"`, the per-file "this file was not updated" line, and two comment blocks in `bin/sc` already forbid new zh strings from containing it. | `bin/sc:204`, `:246-247`, `:294-295` |
| E-15 | `main()` sends every command except `doctor` through `_init_files()` and `_resolve_clash_port()`, both of which write; `_init_files()` hard-codes `/var/lib/sing-box`. `sc status` therefore cannot be run as shipped from a redirected fixture. | `bin/sc:3116-3131`, insight-index 2026-08-01 |

**Consequence chain.** The goal's second clause is one-third refuted (E-1, E-2) and two-thirds
under-stated: the two states that actually exit 0 after a failure (E-3/E-4 and E-5) were named by
nobody, and one of them prints a sentence that is false (E-3). Re-deriving the clause is what turns a
"make it exit non-zero" patch into the one coherent statement FR-6 makes — the run's outcome sentence
and its exit status come from one determination.

## Related historical work

Linked, not re-described. Contract portions were read for each.

- `docs/features/_archived/config-degrade-missing-rulesets/` (T-02, `ab4e4a4`) — the one usability
  judgment and the one reader (E-6). FR-1 lands the timestamp there rather than beside it.
- `docs/features/_archived/sc-doctor/` (T-05, `1b1b0e0`) — "no second opinion" made concrete (E-7, E-8);
  the model FR-1/FR-2 and AC-S1 copy.
- `docs/features/_archived/fix-rules-update-execstart/` (T-09) — §4 item 1 rejected unifying the
  systemd and OpenRC invocation paths; Q-3 keeps that ruling. Its §2 is also the project's standing
  reminder that a premise about timer history needs a measurement (P-7).
- `docs/features/_archived/ruleset-update-no-needless-restart/` (T-10, `90ad762`) — B-10's closed set of
  run-level outcomes, B-11's `失败：` ban, B-13's stream split, D-6's "a no-op run exits 0 because
  `install.sh` branches on it" (BC-11).
- `docs/tasks.md` R-12 (Q-2), R-19 (out-of-scope 9), R-22 (the AC-B set exists because of it),
  R-31 (AC-B9's blocked-not-substituted discipline), R-33 (Q-12).
- `.harness/rejected-decisions.md § mtime-or-size-as-a-ruleset-change-signal` (Q-5),
  `§ doctor-exit-status-always-zero` (E-2, Q-10), `§ ruleset-unit-tests-in-t02` (out-of-scope 8).
- `docs/batches/default/BATCH_PLAN.md` row T-20 — its `sc doctor` rule-set-age row is the consumer
  FR-2 is shaped for.

## Candidates considered, and what selected among them

**Q-1 (one task or two).** Candidates: (a) one task, two halves; (b) split, T-19 = age only; (c) split,
T-19 = run-outcome only and the age half absorbed into T-20, which already wants an age row. (c) is the
strongest rival — it would put the age datum and its first verdict in one task and remove the
"A computes what B consumes" shape entirely. It loses because `sc status` consumes the age in T-19
itself (so nothing is computed *only* for a later task), and because it would enlarge T-20, already the
largest remaining row, to buy nothing T-19 does not already own. (b) loses to the pipeline cost of a
second row for a few lines. The pool's original "they belong together" ruling was not inherited: it was
re-derived above and it survives, but for a different reason than the pool gave — not one judgment
shared, but two small independent changes cheaper to ship in one pass than in two.

**Q-2 (R-12).** Candidates: (a) claim it with a `try/finally` or an exception envelope around
`cmd_update_rules()`; (b) claim it by making the two helpers return instead of exiting; (c) narrow it.
(a) prints an outcome line on paths that have no outcome (including `KeyboardInterrupt`) and would
print it *after* the exit message the user actually needs; (b) reopens two designs that stages 3 and 5
already ruled ship-as-designed at T-13 and T-14, for a trigger that needs two simultaneous faults.
(c) wins under 「少就是多」 and is honest about what is left open.

**Q-4 (staleness threshold).** Candidates: (a) a constant threshold plus a stale verdict; (b) a
threshold derived from the configured update cadence; (c) age as a number only, verdict deferred to the
surface that needs one. (a) is wrong on any host that ran `sc update-interval`; (b) is real machinery
(a second reader of the cadence setting, plus a story for an arbitrary `OnCalendar` expression) bought
for a requirement nobody stated; (c) leaves T-20 free to define the verdict once, over a datum that
already has exactly one producer. The counter-argument — that the goal says "make stale rule-sets
**loud**" and a bare number is quiet — is answered by the second half: the loud channel for "updates
stopped working" is the failed unit, and the age is the durable record a user can read afterwards.

**Q-6 (failed restart).** Candidates: (a) in scope; (b) out of scope as "not an update failure". (b)
reads the goal literally and leaves the run's only outright false sentence in place; rule 85's own T-01
precedent (a banner printing ✅ unconditionally while the installer knew better) is this exact shape.
The scope cost is bounded by out-of-scope item 5: no other caller of the restart helper changes
behavior.

**Q-11 (age rendering).** Candidates: (a) an absolute timestamp; (b) a duration; (c) both. A timestamp
makes the reader do the arithmetic and drags in timezone and locale questions; both is two facts per
line against a one-line-per-item contract. A duration it is, with the format left to stage 2 because no
acceptance criterion depends on the exact wording.

**AC-S3's file list.** The property AC-S3 exists for is "the product diff stays small and enumerated",
and two classes of file were missing from the list without weakening that property. Candidates for the
first: (a) leave `docs/dev-map.md` out and let the map ship stale as a pool row; (b) admit it unbounded;
(c) admit it with the edit bounded to the rows the widening falsifies. (a) is the T-08 shape exactly —
its stage 6 could not add a dev-map seam row because the file sat outside that task's carve-out, so a
known-false row shipped and became an open pool row; here the two rows state tuple shapes (`(status,
digest, size)`, "5-tuples") that the widening makes false, and T-20 reads precisely those rows to find
where rule-set age lives. (b) turns the carve-out into a licence to restructure a navigation document
inside a behaviour task. (c) keeps both halves: the map stays true and stage 5 can test the bound by
reading the diff of one file. Candidates for the second: (a) leave the criterion as written and accept
that it is false at the moment of delivery no matter what the developer does; (b) drop the file
constraint entirely; (c) enumerate the PM's delivery-time writes as a separate, closed list. (a) makes
an acceptance criterion unsatisfiable, (b) discards the property, (c) keeps the product diff enumerated
while stating who writes what — which is also why the criterion now fails on a path in *neither* list
rather than merely on a path outside the first.

## Notes for downstream stages

- **The fixture cannot use `main()`.** `sc status` is not on `main()`'s read-only arm (E-15), so a
  behavioral run drives `cmd_status(args)` directly on a loaded module with the eight constants
  repointed. The as-shipped root run is AC-B9 and is expected to be reported BLOCKED.
- **Control classes.** AC-B5 and AC-B6 are the only observations where HEAD and the candidate disagree;
  AC-B7's control agrees **by design** and must be labelled a freeze. Bundling an already-true clause
  with a changed one produces an inconclusive control no rig can rescue
  (insight-index, `telemetry-reject-list`).
- **The `CLASH_PORT` and `LANG` vacuity traps** both apply to any `sc status` fixture: `main()`
  reassigns both after import, so a fixture that sets neither renders English and probes a port free by
  construction (insight-index, `config-composition-layer` and `status-egress-via-clash-api`).
- **Glossary.** Two terms are worth adding to `CONTEXT.md` by whoever next edits it (this task was
  scoped to write only its two stage documents): **rule-set age** — the elapsed time since a rule-set
  file's bytes were last written, which for every file this project installs is the time of its last
  successful fetch; _Avoid_: freshness, last-checked, staleness (a verdict, which this project does not
  define). And **run outcome** — the single determination from which a command's outcome sentence and
  its process exit status are both derived, so the two cannot disagree; _Avoid_: exit code, result,
  status.
