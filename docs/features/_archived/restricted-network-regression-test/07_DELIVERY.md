# Delivery Summary

## Summary

- Task: `restricted-network-regression-test` (T-07) — give the project a repeatable, committed way to observe what a restricted-network install actually ends up as, and assert it.
- Mode: full (7 stages), single-Developer (no `.harness/agents/dev-*.md` on this project)
- Stages traversed: 1 req (r1) → 2 design (r1) → 3 gate (r1, `APPROVED WITH CONDITIONS`, GC-1…GC-11) → 4 dev (r1) → 5 review (r1, **ROLLBACK**) → 4 dev (r2) → 5 review (r2, `APPROVED WITH RESIDUALS`) → 6 QA (r1, `APPROVED FOR DELIVERY`) → 7 delivery. 2026-08-14 → 2026-08-15.
- Rollbacks: **1** (stage 5 → 4, CR-1 MAJOR: BC-9's second clause unimplemented for E3/E4, so on a no-egress VM both printed `PASS` with a `pair=` byte-identical to their own `obs=` — gate finding F-1's defect relocated). Fixed and re-verified in both directions.
- Final verify_all result: **PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — batch baseline preserved, never lowered. PM-measured at five checkpoints (pre-stage-1, post-stage-4 r1, post-stage-4 r2, post-QA, post-archive).
- Baseline changes: **none**. `.harness/scripts/baseline.json` stays byte-unchanged at `test_count: 0` (AC-17 binds it; Q-9 rules that a count would claim tests that never ran). 0 committed tests added; 63 host observations were taken across 6 reproducers and 17 scratch fixtures, none committable — the ledger admits no new file, `.gitignore:19` ignores `test/`, and K-13 leaves `verify_all` wiring to R-9. Their source is transcribed into `06_RATIONALE.md` §13 so the T-02/T-08 loss of scratchpad-only harnesses is not repeated.
- Outstanding risks: the artifact **has never been run end to end** — that is the designed-for outcome (Q-15/RS-5), not a failure, and all eight `[VM]` criteria are reported `BLOCKED` with a named recipe rather than substituted. `.harness/operator-obligations.md` **row 2** carries the recipe (R-1…R-6) plus the three RES-4 readings the operator must take against the first real transcript. Four MINOR/NIT defects (D6-1…D6-4), none reachable with the four bases `bin/sc` ships at HEAD.
- Files changed: 5 files, **+355/−0** (`.harness/scripts/restricted-network-regression.sh` +330 new/0755, `.harness/rejected-decisions.md` +15, `CONTEXT.md` +7, `docs/dev-map.md` +2, `.harness/operator-obligations.md` +1), plus this task's 13 stage documents. **Zero product diff**: `install.sh`, `bin/sc`, `uninstall.sh` and `systemd/*` verified byte-identical to HEAD, 6/6, against a `git clone` (never a worktree — GC-11) with a one-byte negative control.
- Next steps for user: boot one throwaway systemd VM and run operator-obligation row 2. Until then T-01's AC-9 and T-02's `install.log` capture remain unverified by a run — but they are now verifiable by one command instead of by a research project.

### What the goal sentence got wrong — all four clauses, the sixth consecutive row

Stage 1 refuted the goal first-hand and the gate re-derived the headline independently through all five code links, without reference to stage 1's chain:

1. **The five end-state conditions are superseded, and one is inverted.** T-01's AC-9 — "prints the failure banner, and exits non-zero" — is **false against current code**. `install.sh:567` leaves `PHASE_RULESETS=failed`, but `:590`'s `sc reload` reaches `generate_config()`, which deletes the empty `route.rule_set` (`bin/sc:2060-2061`) and filters **both** rule arrays (`:2062-2063`); `sing-box check` then passes, `PHASE_CONFIG=ok`, the service is already up, and `install_report()` takes its **success** arm — `✅ Install complete`, exit **0**. A regression test written to AC-9 would have **failed on correct code**. Re-derived as six conditions E1…E6, each attributed to the task that set it.
2. **Blocking `github.com` / `raw.githubusercontent.com` cannot reproduce the scenario** — four shipped sources across three failure domains; two jsDelivr edges and `ghfast.top` keep answering. The blackout is *derived* from `RULESET_BASES` at run time (FR-3), never hardcoded.
3. **"the full one-liner install" is impossible under its own premise** — the one-liner fetches `install.sh` from the blocked host, and the remote-artifact branch exits at its first fetch; `RAW_BASE` has no override. The artifact drives the local-checkout branch and the coverage limit is stated.
4. **Container is out; VM only** — E1/E5 need systemd as PID 1 plus `/dev/net/tun`.

### The vacuous-green hunt, which is what this task was actually about

Nine were already on this project's record (T-08's six, one of which had produced a false PASS). This pipeline found four more, each at a different stage, and **none of them was found by reading the stage that introduced it**:

- **Gate, F-1** — E1's `pair=` was a restatement, and E1's assertion is satisfied *identically by a completely unrestricted healthy install*. → GC-1 replaced it with the step-6 warning, which separates a **degraded** success from a healthy one.
- **Developer, D-3** — `RULESET_BASES`' base 4 is a byte-**suffix** of base 3, so the obvious substring test reports 4-of-4 on a log naming 3. Measured 4 vs 3; fixed with a per-entry boundary match, and reproduced independently at QA.
- **Code review, CR-1** (the rollback) — BC-9's second clause was implemented for E6 and forgotten for E3/E4.
- **QA, D6-1** — `uncoverable()` rejects an empty host, `localhost`, an IP literal and a port-bearing authority but **accepts a userinfo authority**, so it reports "covered" for a base whose sunk name (`u@cdn.example`) is not the name any fetcher resolves (`cdn.example`).

QA also **reproduced F-6 before trusting anything**: `--self-check` prints `SELF-CHECK OK: 3 shipped base(s), all covered` and exits 0 on a three-base source, so exit 0 is not a guard — the printed list is. It then compared the four printed URLs to `bin/sc:113-118` with an **independent** parser (`ast.literal_eval`, sharing no code with the artifact's `sed`+`grep`): byte-identical, with a one-byte-edit and a dropped-line negative control.

### A downstream stage refuted a reviewer's named fix, and the reviewer withdrew it

Stage 5 asked for `[ "$p5" = "$prev5" ]` in E5's PASS conjunction. Stage 4 measured it to be a **tautology at both loop exits** — the loop body's tail is `prev5="$p5"`, so the exhausted exit has just created the identity and the break exit required it (`p5=111 prev5=111 equal=yes` on the crash-loop state the fix was meant to catch). It shipped the working equivalent (an `agree` flag set at the break) and **kept a dead service reporting FAIL rather than BLOCKED** — a product failure must not be laundered into a harness excuse. Stage 5 verified the replacement in both failure directions and withdrew CR-5 in writing.

### Rule 85 「以少就是多」 — tested twice, and the cap was the thing that failed

The requirement capped the artifact at 250 lines; the gate independently estimated 240-265 and wrote F-11 saying the cap had no margin and K-10's "target ≤235" was not credible — **then approved K-10 unchanged**. It shipped at 330. Stage 5 spent the burden of proof region by region and judged the overrun **earned**: recoverable surplus is ~15-20 lines, and the binding floor (239 code at zero comments and zero blanks + the 28-line operator guide GC-9 forbids trimming) is **267**, so the cap was unreachable by construction. No refactor was demanded, the counter-rule was honoured (no future edit could be named that a smaller shape would prevent), and nothing was dropped to make a number. What the design *did* avoid is the thing rule 85 was aimed at here: no framework, no fixture library, no mock server, no fault-injection matrix, no runner, **no second file and no new directory** — this project has thrown away five harnesses, and the sixth is one script beside `check-i18n-parity.sh`.

### The BLOCKED discipline, held a fifth time

R-31, R-41, R-47 and R-52 were each a criterion needing root or a live run, reported BLOCKED rather than substituted. T-07 makes five, and it is the largest instance: **eight criteria, not one**. No artifact reading is offered as evidence for any of them; the three unit-level rows (AC-8/9/11) are explicitly labelled *partly discharged at unit level, condition still BLOCKED*. Nothing on this host was mutated — `install.sh` never ran, `/usr/local/bin/sc` was never invoked, `bin/sc` was never imported, `/etc/hosts` / `nsswitch.conf` / `resolv.conf` are unchanged, and the live-service witness (`MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`) was identical at all 12 sample points, `is-active` never invoked.

## Insight

- 2026-08-15 · A total rule-set blackout no longer produces a failed install: `generate_config()` deletes the empty `route.rule_set` and filters both rule arrays, so `sing-box check` passes, the service starts, and `install.sh` takes `install_report()`'s **success** arm — `✅ Install complete`, exit **0** — which inverts T-01's AC-9 ("prints the failure banner, exits non-zero") and would make any regression test written to that criterion fail on correct code · evidence: restricted-network-regression-test
- 2026-08-15 · `RULESET_BASES`' base 4 is a byte-**suffix** of base 3 (base 3 is `https://ghfast.top/` followed by base 4 verbatim), so any substring test for "the log names all four bases" counts **4 on a log naming only 3** — measured 4 vs 3 against a synthetic 3-of-4 `install.log` — and a per-entry boundary match (`failed: <base> -> ` / `; <base> -> `) is the only form that counts honestly · evidence: restricted-network-regression-test

## Verdict

DELIVERED
