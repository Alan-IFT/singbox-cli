# PM Log — T-21 ruleset-source-strategy-from-v2rayn

- Mode: **explore** (per the `BATCH_PLAN.md` T-21 row). Stages: light stage 1 + `findings.md`.
  No `02`-`07`, no gate, no developer, no QA, no code. Dispatched by `/harness-batch` on pool
  `default` under deferred-human mode.
- 2026-08-14 · task folder created; `.harness/intervention.md` **absent** at all three checkpoints
  (before stage 1, after stage 1, before delivery) — no pending intervention, nothing consumed.
- 2026-08-14 · `.harness/scripts/task-state.js` and `.harness/scripts/entropy-cadence` **do not
  exist on this host**. Handled fail-open per the brief: no durable-state init/verdict was written
  and no entropy cadence was incremented, checked or swept. Recorded here instead. The entropy
  watch is in any case `full`-mode-only.
- 2026-08-14 · Insight index queried before dispatch. Two entries applied and were carried into the
  stage-1 dispatch prompt as evidence-validity constraints: `_init_files()`'s hard-coded
  `/var/lib/sing-box` literal (2026-08-01) and `urlopen(timeout=N)` bounding a socket operation
  rather than wall clock (2026-08-14). Both bound the exploration's method — `bin/sc` was never
  imported or executed, and every timing is an observed `curl -w %{time_total}`.

## Stage 1 — requirement-analyst (light), round 1, ACCEPTED

- Output: `01_REQUIREMENT_ANALYSIS.md`, 95 lines. Explore-shaped: question, SC-1…SC-7 success
  criteria, candidates C-1…C-5 (including the **null candidate**, carried explicitly), out-of-scope.
  Verdict `READY`. No `01_RATIONALE.md` returned ⇒ none written.
- The analyst reported one thing the pool's own notes did not say, and it turned out to be the
  hinge of the whole task: this project's `RULESET_BASES` points at **MetaCubeX/meta-rules-dat**,
  not at any repo v2rayN uses, so Q1's premise is a claim about MetaCubeX's releases and is not
  inherited from v2rayN's evidence. It was correctly filed as a verification obligation under SC-4
  rather than asserted. First-hand checking then **refuted** it.
- Its unresolved ambiguity (whether "direct" is a reachable state at all on a pure-TUN host) was
  left open rather than assumed, per the pool's explicit instruction. Settled by measurement in
  `findings.md` §Q4: it is not reachable here without mutating the live tunnel, and that is
  recorded as a named, un-taken measurement rather than substituted with weaker evidence.
- 0 rollbacks. No round-2 record exists for any stage.

## Exploration — conducted by the PM directly (per the `/harness-explore` contract)

- Output: `findings.md`, 311 lines (F.6's 500-line cap is not exceeded; F.6 in any case globs only
  `PM_LOG.md` and `0[1-7]_*.md`).
- Safety: read-only throughout. No write to `/etc/sing-box/` or `/var/lib/sing-box`; no service
  action; `bin/sc` never imported; `/usr/local/bin/sc` never invoked; the installer never run. Rule
  fetches went to session-scratchpad paths only, never over a live `.srs`. Service witnessed with
  `systemctl show -p MainPID -p ActiveEnterTimestamp` (never `is-active`): `MainPID=2566751`,
  `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`, identical before and after. No credential
  byte was read or printed — `/etc/sing-box/config.json` is 0600 and unreadable to this agent, so
  config facts came from `bin/sc`'s `CONFIG_BASE` plus the read-only Clash API.
- Verdicts: Q1 **DECLINE** (premise refuted twice), Q2 **DEFER** with a content-complaint trigger,
  Q3 **DECLINE** as a `sc` feature, Q4 **DECLINE** any switch. Net code change: **none**.
- Three of the seven premises audited were false and one half-false; the corrections are in
  `findings.md` §Premise audit. This is the sixth consecutive pool task to find its own goal
  sentence partly false against reality.

## Delivery

- Rows filed (as rows, never as code): **R-53** (bases 1 and 2 share a failure domain), **R-54**
  (R-16 re-homed — an explore task ships no code and cannot claim it), **R-55** (two README
  sentences the findings established). No `BATCH_PLAN.md` task row filed: the findings recommend
  no code, and manufacturing one would be the failure mode the brief named.
- `docs/dev-map.md` untouched — no structure changed, as predicted.
- Insight index: 2 entries appended by hand (explore mode produces no `07_DELIVERY.md`, so
  `archive-task.sh` has nothing to harvest). 2 entries hand-rotated to
  `docs/features/_archived/insight-history.md` to hold the file at 30 lines. **R-18 confirmed a
  tenth time**: the script counts *bullets* (22) while `verify_all` F.4 counts *lines* (30), so its
  rotation cannot fire at the cap.
- `docs/batches/**` deliberately left unstaged — it belongs to the batch loop.
