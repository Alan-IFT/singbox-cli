# Delivery Summary

## Summary

- Task: `doctor-extended-checks` (T-20) — extend `sc doctor` with the checks that need features
  landing after it, each reported as a conclusion with a next step.
- Mode: full
- Stages traversed: 1 requirement-analyst (2026-08-14, READY) → 2 solution-architect (READY) →
  3 gate-reviewer (APPROVED WITH CONDITIONS, GC-1…GC-10) → 4 developer round 1 (READY FOR REVIEW) →
  5 code-reviewer round 1 (**ROLLBACK TO DEVELOPER**) → 4 developer round 2 (READY FOR REVIEW) →
  5 code-reviewer round 2 (APPROVED WITH MINOR) → 6 qa-tester (APPROVED FOR DELIVERY) → 7 delivery.
- Rollbacks: **1** — stage 5 → stage 4, on CR-1 (MAJOR): the clean-host permission row asserted the
  universal "no file grants access to group or other" while `settings.json` is excluded **by name,
  whatever its mode**, and `save_settings()` writes it with `write_text()`, so it is **0644 on every
  default install**. The row therefore printed a false statement on the most common host state
  there is, and both READMEs described it the same way. Fixed by narrowing the **sentence**, never
  the check — the reviewer verified at round 2 that both predicates are byte-unchanged.
- Final verify_all result: **PASS** — PASS 17 / WARN 0 / FAIL 0 / SKIP 1, measured at four PM
  checkpoints (after stage 4 round 1, after stage 4 round 2, after stage 6, and at delivery).
  Identical to the batch baseline measured after T-06. E.6 passes with QA's unnumbered
  `## Adversarial tests` heading.
- Baseline changes: **none**. `.harness/scripts/baseline.json` deliberately not raised — it is in
  the design's frozen set, `verify_all` defines no test count on this project, and raising it would
  record a number no shipped check produces. QA's 317 assertions live in gitignored `test/t20/`,
  the same home as the existing `test/step7/`.
- Outstanding risks: five MINOR defects, none blocking, all filed as pool rows (R-48 … R-52 in
  `docs/tasks.md`). The two that matter: **DEF-2** — `GET /dns/query` populates the install's own
  DNS cache, so every run warms the entry the next run reads, and inside the TTL the DNS row
  reports a cache read rather than resolution through the tunnel; **DEF-1** — a live Clash API on a
  host with no init system makes the node-delay row state `0/{total}`, a count it never read.
  **AC-B14 is BLOCKED, not discharged** (below).
- Files changed: 5 tracked files, **+366 / −66** —
  `bin/sc 331/37` · `README.zh-CN.md 14/12` · `README.md 13/11` · `docs/dev-map.md 7/6` ·
  `CHANGELOG.md 1/0`. Untracked additions: this task's stage docs and
  `.harness/operator-obligations.md` (created by QA; it did not exist).
  `docs/batches/**` left **unstaged**, per the batch loop's ownership and R-36's carve-out.
- Next steps for user: install the new `bin/sc` and run `sc doctor` as root on the live host —
  that single run is the one promise this task did not close (**AC-B14**, filed as operator
  obligation id 1). It also carries the standing **R-30** obligation: the change reaches the live
  host only when a human installs it.

### What shipped, and why it is this small

Six facts, all of which already existed somewhere in the tree. The design question was "which
existing call does each row stand on", and the answer held for all six: rule-set age on T-19's
single reader `mtime` + `_age_text()`; drift on T-06's extracted `_drift_state()`; AAAA state on
T-16's `ipv6_decision()`; node delays on T-15's `stored_delays()`; permissions on T-13's `CRED_MODE`
and its own `mode & 0o077` predicate; DNS through the existing, already-total `clash_api()`.
Shape: **two new `DOCTOR_SECTIONS` entries, five new rows, three small seams** — and **+5 rows
exactly** on a healthy host (16 → 21, measured against a HEAD clone on the same fixture root),
every one `[OK]`, none naming a path or a next step, exit 0.

`_age_seconds()` was deliberately **not** added; the staleness verdict compares inline against the
same `mtime` the row renders. The three seams that were added were each proved load-bearing rather
than accepted — `_aaaa_rule()` removes a double `ipv6_decision()` call (which would print BC-9's
stderr line twice) and a positional `[0]` that would silently check the wrong rule; `EGRESS_HOST`
gives the DNS row and the egress row one literal with a byte-identical request URL.

### The goal sentence, re-derived first-hand

Five of six clauses survived; **"DNS timing" was refuted** — the fifth consecutive pool task where
stage 1 found its own goal sentence partly wrong, and again the largest saving. `CONFIG_BASE`'s
entire `dns` block carries no timeout key of any kind, consistent with T-16's bogus-key-controlled
probe showing sing-box 1.13.15 accepts no DNS timeout at any level. A row reporting a configured
DNS timeout would have reported a value that does not exist. It was re-scoped to one **measured**
fact, gated by BC-16: ship nothing unless a first-hand probe found a boundable mechanism reaching
the running install's resolver. The probe found one and FR-6 shipped — see the Insight section for
what the probe method does and does not establish.

### Decisions taken under the owner's standing grant

- **R-10 closed** — the permission row's full sweep of the configuration directory catches a
  hand-made `config.json.bak-<date>` at 0644 with no filename pattern anywhere, which is exactly
  the instance R-10 filed. The asymmetry that makes it safe: NG-11 forbids the *installer* sweep
  from roaming because it `chmod`s; a reporter only reports.
- **R-11 half-closed** — the directory row is PROBLEM only on `mode & 0o022`, the
  rename-between-`fchmod`-and-replace window R-11 actually names, and never on the world-readable
  mode every host has (a row that fires on 100 % of installs teaches people to ignore it).
  R-11's other half — setting the directory's mode deliberately in `install.sh` — stays open.
- **R-32 closed** — the Clash row's PROBLEM message stops asserting the `3s timeout` cause it did
  not observe.
- **R-43 closed by ruling** — BC-13's third clause gives way, T-06's K-14 stands: a present,
  non-empty, non-digest drift record reads as *drifted*, matching the existing judgement rather
  than giving two commands two opinions about drift.
- **CHANGELOG.md amended one clause beyond the reviewer's named scope** at round 2, because it
  carried the identical false promise about the identical row. Judged the same finding, not a
  widened diff: its numstat is `+1/−0` either way.

## Insight

- 2026-08-14 · `settings.json` is **0644 on every default install** — `save_settings()` writes it with `write_text()` rather than `_write_private()`, and T-13's installer sweep excludes it by name — so any sentence a tool prints about "files in the configuration directory" is false on 100 % of hosts unless it says *credential* file; the instance was found only because a reviewer read the clean-host row's wording against the check's exclusion list · evidence: doctor-extended-checks
- 2026-08-14 · The Clash API's `GET /dns/query` is answered from, **and populates**, the running install's own DNS cache (`experimental.cache_file`), so each probe warms the entry the next probe reads — measured live: a fresh name costs 175 ms, the same name 3 s later 4 ms with the authority TTL decremented 195 → 190 → 186, and a negative answer is held 1800 s — which means a "DNS timing" reading inside that window reports a cache hit rather than resolution through the tunnel · evidence: doctor-extended-checks
- 2026-08-14 · A `clashapi.*Router` symbol present in the `sing-box` binary proves only that a route is **mounted**, never that its body is supported: `clashapi.scriptRouter` is present while `/script` answers "not supported", so symbol-table grep is a sound existence probe (the Go linker drops unreferenced functions, and a fabricated symbol name matches 0) but must be paired with one live read-only request before any response shape is designed against · evidence: doctor-extended-checks
- 2026-08-14 · `is_running()` returns `False` from its **final line** without ever reaching `subprocess.run` when `SYSTEMD` and `OPENRC` are both false, so `stored_delays()` returns `({}, None)` and a live Clash API on a host with no init system yields `0/{total} nodes carry a stored delay` — a count never read from an API that answered — and in a fixture the same line makes the whole node-delay matrix agree on candidate and control unless `sc.SYSTEMD = True` is set alongside the `subprocess.run` stub · evidence: doctor-extended-checks

## Verdict

DELIVERED
