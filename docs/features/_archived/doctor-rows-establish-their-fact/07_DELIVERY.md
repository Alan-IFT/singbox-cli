# Delivery Summary

## Summary

- Task: `doctor-rows-establish-their-fact` (T-26, pool `followups`) — close the three `sc doctor`
  rows that reported a conclusion they did not establish, the shared cause being a verdict derived
  from a **proxy for the fact rather than from the fact**.
- Mode: full (7 stages)
- Stages traversed: 1 requirement analysis (READY) → 2 solution design (READY) → 3 gate review
  (APPROVED WITH CONDITIONS, BC-A…BC-J) → 4 development (READY FOR REVIEW) → 5 code review
  (APPROVED WITH COMMENTS) → 4 round 2 (CR-1/CR-2) → 6 QA (CHANGES REQUIRED, DEF-1) → 4 round 3 +
  2 round 2 (DEF-1, in parallel) → 6 round 2 (APPROVED FOR DELIVERY) → 7 delivery. All 2026-08-15.
- Rollbacks: 4. **CR-1** — a `stored_delays()` docstring sentence that E2 falsified, routed to the
  developer; **CR-2** — an inaccurate boundary claim in the developer's own safety disclosure;
  **DEF-1** — a published `CHANGELOG.md` sentence claiming an exit transition the build cannot
  produce, routed to **two** owners because QA identified the origin as well as the symptom (the
  developer for the shipped prose, the architect for `02_SOLUTION_DESIGN.md`'s clause (c), which
  said the same thing and is where the developer got it). No stage reached three consecutive
  rollbacks; no escalation trigger fired.
- Final verify_all result: **PASS** — `bash .harness/scripts/verify_all.sh` from the repository
  root, **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, identical to the pre-task baseline. Re-run
  independently by the PM after the last edit.
- Baseline changes: none. `baseline.json` untouched, `test_count` stays `0` (T-28 owns the committed
  suite). No check lowered, modified or deleted. No operator obligation opened — ids 1-5 stand.
- Outstanding risks: none blocking. Three residuals filed as rows (below). The one worth naming:
  the AAAA probe's emitter/probe coupling has a **silent** failure mode — an emptied `$prepend`
  payload would read `[OK]` — against the loud `[UNKNOWN]` it gives on a renamed directive.
- Files changed: 6 (excluding `docs/batches/**`, which is the batch runner's own) —
  `bin/sc` `+55/−45`, `README.md` `+4/−4`, `README.zh-CN.md` `+4/−4`, `docs/dev-map.md` `+4/−4`,
  `CONTEXT.md` `+9/−0`, `CHANGELOG.md` `+2/−0`. Top-level `def`/`class` count **113 → 113**;
  `TRANSLATIONS["zh"]` **183 → 182** (zero added, exactly one deleted).
- Next steps for user: none required. `config.json` regenerates byte-identically, so no host needs
  `sc reload` to keep working. Two behaviour changes are published in both READMEs: a host whose
  AAAA rule is not the first `dns.rules` entry now reads `[PROBLEM]` and exits `1` instead of `0`
  (the correction this task exists for), and an init-less host with a responding Clash API now reads
  a real delay count and exits `2` instead of `1`.

### What closed, and how — the part a future reader must not misread

**R-48, R-49, R-50 and R-24 are all CLOSED.** They did not close the same way, and the difference is
the interesting part:

- **R-48 closed by NARROWING THE CLAIM, not by strengthening the check.** The DNS probe is
  byte-for-byte unchanged — same endpoint, same name, same type, same timing, same three outcome
  classes. Only what the sentences claim changed: the row now says the running install *answered*,
  and names the install's own DNS cache as an admissible source, instead of asserting a resolution
  through the tunnel. **This is a weaker guarantee than the old sentence implied, and that is the
  point** — the old sentence was literally true and still not established. Nobody should read this
  as `sc doctor` having gained the ability to prove a fresh upstream resolution. It has not, and
  stage 2 established by first-hand probe that it cannot: see the insight line below.
- **R-49 closed by ESTABLISHING the fact** — narrowing was inadmissible, because a count is not a
  narrowable claim; it was either read or it was not. The fix **removes a second opinion** rather
  than adding a check: `_doctor_clash()` already knew the process was alive from the `/configs`
  answer it held, and `stored_delays()` was re-deciding it through `is_running()`, whose weaker
  answer won. One changed line, `if port is None and not is_running():`. `sc ls` names no port, so
  the guarantee BC-11 was written for survives untouched.
- **R-50 closed by a REQUIREMENT RULING, then a code change.** Stage 1 ruled the requirement is
  **position, not membership**, amending T-20's FR-4 and I-6 — on three first-hand grounds, the
  strongest being that `README.md:126` already published the *position* as the product's promise.
  The probe now tests that the authored rule is the **first** `dns.rules` entry.
- **R-24 closed at one changed line**, reusing the translated sentence `cmd_telemetry` already
  ships for the identical state, which let a now-orphaned key be deleted — net negative lines.

## Insight

- 2026-08-15 · sing-box's Clash API exposes DNS-cache control only as a **mutating** fake-IP flush (`clashapi.cacheRouter` → `flushFakeip`) and as **configuration** options (`disable_cache`, `independent_cache`, `cache_capacity`), never as a read-only request parameter — and the `/dns/query` JSON body carries no cache-hit indicator either, so no `sc` probe can ever ask this install for an uncached resolution *or* detect that it got one; a row wanting that fact must narrow its claim rather than chase a measurement · evidence: doctor-rows-establish-their-fact
- 2026-08-15 · Removing a `[PROBLEM]` row from `sc doctor` can **raise** the exit code: `DOCTOR_EXIT` maps UNKNOWN→2 while the severity ordering feeding `worst = max(...)` is OK<UNKNOWN<PROBLEM, so a PROBLEM row **masks** any UNKNOWN row in the exit status — measured as HEAD `EXIT=1` → candidate `EXIT=2` on a wholly healthy init-less host, where `_doctor_service()` returns two unconditional UNKNOWN rows (`bin/sc:2741-2742`); the exit code is a class label, not a severity scale, and "this fix can only improve the exit code" is false · evidence: doctor-rows-establish-their-fact
- 2026-08-15 · A `bin/sc` fixture **cannot call `main()` twice in one process**: `main()`'s `io.TextIOWrapper` re-wrap leaves the previous run's wrapper over the same `BufferedWriter`, and replacing it closes that buffer, so every later `print()` raises `ValueError: I/O operation on closed file` — with stderr discarded the fixture then prints *nothing* and reads as a probe that produced no rows rather than a harness that broke; one case per process is the only reliable shape · evidence: doctor-rows-establish-their-fact
- 2026-08-15 · `telemetry: block` is the **absent-key default**, so `_telemetry_overlay()` is a second `sc`-authored writer of `dns.rules` on an *ordinary* host, not a hypothetical future one — its `$before {"clash_mode":"Global"}` anchor resolves by search and lands its rule at index **2** (behind the `hosts_dns` rule), which is what leaves the AAAA rule's index 0 intact; any future check of a rule's emitted position must be composed against this second writer, not against a bare base template · evidence: doctor-rows-establish-their-fact

## Verdict

DELIVERED
