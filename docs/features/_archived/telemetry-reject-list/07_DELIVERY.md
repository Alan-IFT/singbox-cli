# Delivery Summary

## Summary

- Task: **T-17 `telemetry-reject-list`** — ship the common-telemetry DNS reject list as an opt-out
  overlay on T-14's composition layer: data plus a toggle, not new machinery.
- Mode: **full** (7 stages), dispatched by `/harness-batch` on pool `default`.
- Stages traversed (all 2026-08-14):
  1. requirement analysis → **READY**
  · *PM-commissioned read-only measurement probe* (interlude, between stages 1 and 2)
  2. solution design → **READY**
  · *`NOTE` intervention consumed at the 2→3 boundary* (「以少就是多」, promoted into rule 85)
  3. gate review → **APPROVED WITH CONDITIONS** (13 findings, 11 conditions)
  4. development → **READY FOR REVIEW**
  5. code review → **APPROVED WITH FINDINGS** (0 CRITICAL, 0 MAJOR, 5 MINOR, 2 NIT)
  4′. development round 2 (CR-1, CR-3) → **READY FOR REVIEW**
  6. QA test → **APPROVED FOR DELIVERY**
  7. delivery (this document)
- Rollbacks: **1** — stage 5 → stage 4, documentation only. A `docs/dev-map.md` guard row named an
  anchor no README publishes while the one users do write went unguarded (CR-1), and `04`'s Summary
  reported "0 inconclusive" while a criterion *as written* was inconclusive (CR-3). No code defect
  caused a rollback at any point.
- Final `verify_all` result: **PASS** — `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, the batch baseline,
  preserved and never lowered. Re-run independently by the PM at three checkpoints (after stage 4,
  after round 2, at delivery), not accepted on report.
- Baseline changes: **none.** `.harness/scripts/baseline.json` still records `test_count: 0` — this
  project ships no committed suite (out-of-scope item 10 / R-9 owns one). Every fixture on this task
  was throwaway; sources are pasted into `04_RATIONALE.md` and `06_RATIONALE.md`.
- Outstanding risks: **R-28** the name list has no freshness owner — proven necessary, since one of
  the eighteen proposed names did not exist; **R-29** `load_settings()` lets `UnicodeDecodeError` and
  a non-object document reach the user as a traceback, for every reader (pre-existing, HEAD-controlled,
  supersedes R-25); **R-30** the behaviour reaches the owner's live host only when a human installs
  the new `bin/sc` and runs `sc reload`. Two further pre-existing families (non-atomic
  `save_settings()` under concurrency; a setting persisted before a failed regeneration) each ship
  with a HEAD-side control proving they are not T-17 regressions.
- Files changed: **5 product files, +427/−6** — `bin/sc` +219/−2, `README.md` +100,
  `README.zh-CN.md` +100, `CHANGELOG.md` +2, `docs/dev-map.md` +6/−4. Counted with
  `git diff --numstat` (first field = added), never `--stat`'s bar, which sums insertions **and**
  deletions. Plus delivery-time edits outside the task's permitted diff, applied by the PM:
  `CONTEXT.md` (2 glossary terms), `.harness/rejected-decisions.md` (4 records), `docs/tasks.md`,
  `docs/tasks-archive.md`, `.harness/insight-index.md`, `docs/features/_archived/insight-history.md`.
- Next steps for user: install the new `bin/sc` and run `sc reload` to apply it on the live host
  (R-30). One decision remains genuinely yours — see **Owner decision outstanding** below.

## Owner decision outstanding (gate condition C-11)

The reject rule's position **overrides the field report's stated slot**, and the gate declined to
close that itself: rule 25 red line 4 (conflict with an explicit user constraint) escalates in all
three modes, and the gate could not read the field report to judge how considered the sentence was.

The field report specified the rule sit **after** `clash_mode` and before the routing rules. It ships
**before** both `clash_mode` rules. The reason is measured, not argued — a PM-commissioned read-only
probe against real `sing-box 1.13.15`:

| rule at the field report's slot | `rule` mode | `global` mode | `direct` mode |
|---|---|---|---|
| listed name | `NXDOMAIN`, 0 records | **`NOERROR`, 1 record, recorded by the upstream stub** | **`NOERROR`, 1 record, recorded by the other stub** |

| rule before both `clash_mode` rules | `rule` | `global` | `direct` |
|---|---|---|---|
| listed name | `NXDOMAIN`, 0, no receipt | `NXDOMAIN`, 0, no receipt | `NXDOMAIN`, 0, no receipt |

Each `clash_mode` rule is a catch-all *within its mode*, so at the report's slot the rule is never
reached in either non-`rule` mode — and for a **name** rule that is not merely "not blocked", it is
the telemetry name **measurably leaked to an upstream resolver**, which is the outcome the feature
exists to prevent. It is also the defect shape T-16 had just fixed, one task later.

**Shipped on the owner's standing batch grant, with the measurement recorded and the gate's
recommendation to keep it.** The cost is stated rather than hidden: switching routing mode is *not*
an escape hatch for a mis-blocked application — `sc telemetry allow` and the per-name override recipe
are, and both READMEs carry them plus a sentence saying so explicitly. Reverting is cheap in code
(one anchor string, one README paragraph per language, one dev-map row) but touches `02` I-9, AC-2,
V-3, V-23 and both READMEs — so it is far cheaper now than after the next task builds on it.

## What shipped

`sc telemetry block|allow|show`, defaulting to **`block`**, switching one `predefined` DNS rule
carrying **17** curated telemetry names as a single dotless `domain_suffix` list, emitted at
`dns.rules[2]` — after the predefined-hosts rule (so `sc`'s own DoH bootstrap keeps answering) and
before both `clash_mode` rules (so rejection is mode-independent). A listed name and every subdomain
of it are answered `NXDOMAIN`, authoritatively, in 2–7 ms, with **no upstream query** — observed at
instrumented stub resolvers, not inferred.

The goal sentence predicted the shape and the shape held: one tuple, one settings reader, one overlay,
one command, six strings, and **one changed line** in `generate_config()`. No new file, directive,
import, module-level path, wait constant, rule-set, download, or persisted state beyond one settings
key. The FR-10 report (RS-1) is that T-14's composition layer could express **everything**; the one
thing it cannot express — element addressing into a nested array, to extend the shipped rule in place
— was re-homed to a documented second-rule recipe that costs the user four lines of JSON.

## Insight

- 2026-08-14 · `domain_suffix` in sing-box 1.13.15 is **label-boundary aware**, not the raw character suffix the v2ray era assumed — one dotless entry matches the apex and every subdomain at any depth, case-insensitively, and does **not** match `notexample.com` or `example.com.evil.net`, so the habitual `domain` + `.suffix` pairing is dead weight defending against a false positive this binary cannot produce, while a bare leading-dot `.example.com` is the genuinely wrong form because it silently leaves the apex resolvable · evidence: telemetry-reject-list
- 2026-08-14 · A sing-box DNS rule placed **after** the two `clash_mode` rules is unreachable in both non-`rule` modes, because each `clash_mode` rule is a catch-all within its own mode — and for a name-scoped rule that is not "merely unblocked" but the name **measurably leaked to an upstream resolver** (`NOERROR`, 1 record, recorded at the stub, in `global` and `direct` alike), which is why a privacy or suppression rule must precede them · evidence: telemetry-reject-list
- 2026-08-14 · sing-box 1.13.15's `predefined` DNS-rule decoder **rejects** unknown fields while its `reject` decoder **accepts** them — `{"action":"reject","zzz_nope":1}` and even a meaningless `rcode` on a `reject` rule pass `check` and do nothing — so the bogus-key acceptance control that proves a key is real is sound **only** against `predefined`, and `reject` + `rcode` is a validating no-op trap · evidence: telemetry-reject-list
- 2026-08-14 · A `predefined` rule with `rcode:"NXDOMAIN"` **and** a non-empty `answer` emits a self-contradictory reply — `status: NXDOMAIN` carrying `ANSWER: 1` — and still passes `sing-box check`; an omitted `rcode` silently means `NOERROR`, and a lowercase `"nxdomain"` is a hard `check` failure, so all three of key-absence, explicitness and case are load-bearing · evidence: telemetry-reject-list
- 2026-08-14 · `dig`'s default EDNS COOKIE defeats sing-box 1.13.15's upstream DNS cache entirely — 5 client queries produce 5 upstream queries with it and 1 with `+nocookie` — so any harness measuring caching or "was upstream contacted twice" is measuring the cookie; separately a `dig` subprocess costs ≈17.5 ms of pure startup here, so a `dig`-driven 100 ms assertion really asserts ≈82 ms of headroom · evidence: telemetry-reject-list
- 2026-08-14 · An `override.json` anchor that a README publishes must match exactly one element in **every** state the document can reach, not just the state it was written for: `{"rcode":"NXDOMAIN"}` existed only while the reject list was on, so the shipped recipe made `sc telemetry allow` exit 1 with `$before matched 0 elements` — and because the setting is persisted *before* regeneration, the host was left recorded `allow` with a `config.json` never regenerated · evidence: telemetry-reject-list
- 2026-08-14 · `sing-box check` fully parses every `.srs` the document references, so a fixture with synthetic rule-set bytes that satisfy this project's own `srs_reject_reason()` still dies at `initialize router: parse rule-set[0]: zlib: invalid header` — a `check`-based fixture must copy the host's real `.srs` bytes, or only the all-rule-sets-unusable state is actually testable · evidence: telemetry-reject-list
- 2026-08-14 · A `[D]`/`[A]` control class is a property of an **observation**, never of a criterion: an acceptance criterion that bundles "the excepted name resolves" (which HEAD also does) with "every other name stays rejected" (which HEAD does not) can only ever produce an *agreeing* control, making it inconclusive by construction no matter how good the rig — split per observation, both halves pass · evidence: telemetry-reject-list

## Verdict

DELIVERED
