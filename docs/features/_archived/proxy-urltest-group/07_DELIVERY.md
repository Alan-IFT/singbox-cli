# Delivery Summary

## Summary

- Task: `proxy-urltest-group` (T-15) — make the `proxy` tag able to resolve to a probing `urltest` group rather than only a concrete node, so a single flaky node has a failover path, and surface per-node latency from the Clash API in `sc ls`.
- Mode: full (7 stages)
- Stages traversed: 1 requirement (2026-08-02, pre-existing, READY) → 2 design (2026-08-13, re-dispatched after round 1 produced no artifact, READY) → 3 gate (APPROVED WITH CONDITIONS, C-1…C-9) → 4 development round 1 (READY FOR REVIEW) → 5 code review (APPROVED, CR-1…CR-5) → 6 QA round 1 (**CHANGES REQUIRED**, DEF-1…DEF-5) → 4 development round 2 (READY FOR REVIEW) → 6 QA round 2 (APPROVED FOR DELIVERY) → 7 delivery (2026-08-13)
- Rollbacks: **1** — stage 6 → stage 4 on **DEF-2**, a MAJOR documentation defect: both READMEs and the CHANGELOG promised unattended failover without qualification, and QA's measurements against the real binary showed the promise was wider than the behaviour. Fixed as a prose qualification; no code changed. Stage 2 was additionally **re-dispatched** (not a rollback — round 1 left no artifact and no findings). Consecutive-rollback streak never exceeded 1 at any stage.
- Final verify_all result: **PASS** — `bash .harness/scripts/verify_all.sh` → **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, measured after archive. Better than the batch baseline (PASS 16 / WARN 1): F.6 cleared exactly as predicted when the stage docs left `docs/features/`, and F.5 — which fired at 308 lines once this task's board row and four open rows landed — was cleared by rotating the eight oldest Completed rows into `docs/tasks-archive.md` per rule 70 rule 3. The remaining SKIP is B.3 lint (no lint config, pre-existing). Every stage of this task also measured PASS 16 / WARN 1 / FAIL 0 / SKIP 1 against the in-flight tree, i.e. **no FAIL at any point**.
- Baseline changes: none — `.harness/scripts/baseline.json` still reads `test_count: 0`. This project has no committed test suite (NG-9 / R-9); QA's 13 suites and 230+ assertions were scratchpad throwaways by design.
- Outstanding risks:
  - **A `urltest` group does not demote a member that accepts a connection and then never answers** — QA measured 440 s (2.4 probe intervals) with 100 % of traffic failing, across three independent runs, against a positive control that moved in 183 s. This is the failure mode `01 §1.2` leads with. It is now stated in both READMEs and the CHANGELOG rather than papered over; sing-box exposes no per-probe timeout, so closing it needs a health signal `sc` does not have today.
  - Unattended demotion of a *slow* or *refusing* member lands one probe round later (measured 183 s / 190 s against the emitted `interval: 3m`), with requests failing throughout. Documented.
  - **DEF-1** (filed as an open row): four uncaught exception classes escape the frozen `clash_api()` into `sc ls` on a broken host. Pre-existing — HEAD's `sc status` raises the same — and unfixable inside this task's frozen set.
  - **DEF-3** (filed): `RESERVED_TAGS` omits `GLOBAL`, so a node named exactly `GLOBAL` inherits sing-box's implicit selector's stored delay.
  - **DEF-4 / DEF-5** (filed): upstream requirement gaps — no AC observed the behavioural goal, which is why DEF-2 survived five stages with every AC green; and `BC-9`'s stated exception mechanism is factually wrong.
- Files changed: 5 product files, **+250 / −25** — `bin/sc` (+200/−17), `README.md` (+21/−2), `README.zh-CN.md` (+21/−2), `docs/dev-map.md` (+6/−4), `CHANGELOG.md` (+2/−0). Plus this task's stage docs, `docs/tasks.md` (board + 4 open rows), `.harness/insight-index.md` and `docs/features/_archived/insight-history.md` (hand-rotation, see below).
- Next steps for user: nothing required. `sc reload` on an existing host picks up the new shape with no hand-editing and no drift warning; hosts already pinned to a node keep that pin (only `sc`'s own arbitrary auto-picks become the group). New installs get failover by default. Four follow-up rows are on the board for whichever task next touches these surfaces.

### What shipped

`proxy` remains a **selector** — the field report's premise that it binds a single node was false and was verified false at the source (`bin/sc:1356-1363`) before any design was written. What it gains is a probing member: a `urltest` outbound tagged `auto`, emitted whenever at least one node exists, composed through the T-14 layer's existing `$replace` with no new merge directive and no outbound literal inside `generate_config()`. `sc use auto` selects it through the same Clash API path `sc use <node>` uses, with the same restart fallback; `sc use <node>` is byte-identical to HEAD for all 30 spec × language combinations QA compared against a pristine clone. `sc ls` gains a last-position delay column and, when the group is emitted, an index-less group row naming the node the group is on right now — so `sc use <n>` numbering is untouched.

Three new functions carry every new judgment and each has exactly one definition: `_auto_group_emitted()` (is the group in the document), `_valid_selection()` (the single selection-validity judge, consumed by all three of `sc`'s former auto-picks), and `stored_delays()` (the single reader of "what delay does the running sing-box report", written so `sc doctor` can call it later unchanged).

### Delivery-time obligations discharged

- **Insight index hand-rotated.** `archive-task.sh`'s rotation is dead (R-18: it counts bullets, `verify_all` F.4 counts lines), so the four harvested entries were balanced by hand-rotating four entries into `docs/features/_archived/insight-history.md`, chosen by rule 70's "what no longer earns its line" rather than oldest-first.
- **Open rows filed** into `docs/tasks.md`: **R-19** (the five `ls.*` keys print literally in English), **R-20** (DEF-1), **R-21** (DEF-3), **R-22** (DEF-4/DEF-5, the upstream requirement gaps).
- `docs/dev-map.md` updated by stage 4 (two new reusable-utility rows, three section rows, and the `$replace`-versus-`$append` note that T-16/T-17 will need).

## Insight

- 2026-08-13 · A sing-box `urltest` group demotes a member that is slow or refuses within about one `interval`, but **never** demotes a member that accepts the connection and then never answers — a probe that hangs never completes, so the cached selection is never revisited even after the stale history is dropped, and there is no per-probe timeout option to change it · evidence: proxy-urltest-group
- 2026-08-13 · sing-box's `interrupt_exist_connections` governs **external (inbound-originated)** connections only — the binary carries `interrupt.ContextWithIsExternalConnection`/`IsExternalConnectionFromContext` beside `(*Group).Interrupt`, so setting it false *spares* external connections while sing-box's own internal ones (the DoH transport carrying `remote_dns`) are torn down on every re-selection regardless · evidence: proxy-urltest-group
- 2026-08-13 · `clash_api()`'s `except (URLError, HTTPError)` does not cover what its own body raises: a port that accepts and never answers yields `TimeoutError`, a non-JSON 2xx `JSONDecodeError`, invalid UTF-8 `UnicodeDecodeError`, a short body `IncompleteRead` — so every caller, not just the new one, can take a traceback on a host where something other than sing-box holds the Clash port · evidence: proxy-urltest-group
- 2026-08-13 · sing-box's `GET /proxies` returns entries that are not `sc` outbounds at all — its implicit `GLOBAL` selector among them — so a delay map keyed by the API's own tags is not node-keyed, and a node named after one of them silently inherits that entry's history · evidence: proxy-urltest-group

## Verdict

DELIVERED
