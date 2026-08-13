# PM_LOG — proxy-urltest-group (T-15)

Mode: **full** (7 stages). Decision mode: deferred-human — standing authority granted by the
owner (「你来决策就行」); resolve judgment calls downstream and record them. `BLOCKED: NEEDS-HUMAN`
only for a genuine safety red line.

## Pre-flight (PM)

- `.harness/intervention.md`: **absent** at task start — nothing to consume.
- `docs/tasks.md` read. Related history: **T-14** (`config-composition-layer`, `1e454b6`) is the
  layer this task must build on; **T-05** (`sc-doctor`, `1b1b0e0`) already reports node state and
  owns the rule-85 "no second opinion" constraint for any latency notion; **T-10** (`90ad762`)
  made restart conditional; **T-13** owns `_write_private()`. Open rows R-16 (merge has no
  type-mismatch vocabulary — **owner is explicitly "whichever of T-15/T-16/T-17/T-21 first needs
  the vocabulary"**, i.e. possibly this task) and R-18 (`archive-task.sh` rotation dead) are live.
- `docs/dev-map.md` read; `# Config composition`, `# Clash API`, `# Commands` and the reusable-
  utilities table are the relevant sections.

### PM premise check (the brief asked for independent re-verification)

The field report claims `proxy` 出站直接绑定单节点. **False.** `bin/sc:1357-1363` reads:

```python
selector = {
    "type": "selector", "tag": "proxy",
    "outbounds": node_tags + ["direct"],
    "default": active or "direct",
    "interrupt_exist_connections": True,
}
```

`proxy` is already a selector over every node plus `direct`. The dispatch brief's correction is
confirmed at the source. The *substance* (a selector never probes, so it never leaves a bad node)
is untouched by this correction and is what stage 1 must specify against. Stage 1 is told to
re-verify rather than inherit this reading.

### Insight-index entries surfaced to downstream stages

Read at task start (30 lines, at the F.4 cap — see the delivery note below). Carried into
dispatch prompts:

- **Safety (dev + QA):** line 11 — `bin/sc`'s import-time auto-elevate re-execs the *installed*
  `/usr/local/bin/sc`; an un-neutralised import runs the installed tool against the live service.
  Line 23 — `_init_files()` hard-codes `/var/lib/sing-box`, so never drive it even in a fully
  redirected fixture.
- **Harness correctness (dev + QA):** line 27 — a differential `generate_config()` harness must
  run baseline and candidate at the **same** fixture path (`RULES_DIR` is emitted verbatim).
  Line 28 — `main()` reassigns `LANG`, so setting only `sc.LANG` renders English on `main()`-driven
  paths and Chinese assertions pass vacuously. Line 18 — use a **clone**, never a `git worktree`,
  for a pristine baseline.
- **New strings (dev):** line 12 — `失败：` in `bin/sc` output is a load-bearing diagnostic grep;
  any new zh string must avoid it.
- **Verification (dev + QA):** line 15 — `systemctl is-active` cannot detect a restart; use
  `systemctl show -p MainPID -p ActiveEnterTimestamp`.
- **QA doc shape:** line 22 — `verify_all` E.6 matches `^##\s+Adversarial\s+tests`; a numbered
  heading makes it FAIL.

### Delivery-time note to self (PM)

`.harness/insight-index.md` is at **30 lines = the F.4 cap**. Any harvest overflows it, and
`archive-task.sh`'s rotation is dead (R-18: it counts bullets, F.4 counts lines). **Hand-rotate**
into `docs/features/_archived/insight-history.md` at delivery.

## Stage transitions

| # | Stage | Agent | Decision | Timestamp |
|---|---|---|---|---|
| 1 | Requirement analysis | harness-kit:requirement-analyst | **ADVANCE** → stage 2 | 2026-08-02 |
| 2 | Solution design | harness-kit:solution-architect | dispatched, **no artifact** | 2026-08-02 |
| 2 | Solution design (re-dispatch) | harness-kit:solution-architect | **ADVANCE** → stage 3 | 2026-08-13 |
| 3 | Gate review | harness-kit:gate-reviewer | **ADVANCE** → stage 4 | 2026-08-13 |
| 4 | Development | harness-kit:developer | **ADVANCE** → stage 5 | 2026-08-13 |
| 5 | Code review | harness-kit:code-reviewer | **ADVANCE** → stage 6 | 2026-08-13 |
| 6 | QA test | harness-kit:qa-tester | **ROLLBACK** → stage 4 (DEF-2) | 2026-08-13 |
| 4 | Development (round 2) | harness-kit:developer | **ADVANCE** → stage 6 (stage 5 stands) | 2026-08-13 |
| 6 | QA test (round 2) | harness-kit:qa-tester | **ADVANCE** → stage 7 | 2026-08-13 |
| 7 | Delivery | (PM) | **DELIVERED** | 2026-08-13 |

### Stage 1 → 2 (ADVANCE)

`01_REQUIREMENT_ANALYSIS.md` verdict **READY**. 35 ACs, 16 BCs, 13 NGs, 14 decisions taken under
the standing authority, nothing escalated. Read in full by the PM. Basis for advancing:

- **The premise correction was re-verified independently** at `bin/sc:1356-1363` (E-1), not
  inherited from my dispatch — which is what I asked for.
- **It corrected my dispatch twice, with evidence, rather than accepting it.** (a) E-3: `sc doctor`
  has **no** node or latency notion at all — `DOCTOR_SECTIONS` (`bin/sc:1995-2003`) covers binary /
  rule-sets / config / service / TUN / Clash API / egress. My brief said "if it already has a latency
  notion, reuse it"; the answer is that there is nothing to reuse, so D-8 creates the *first* one and
  places it for `sc doctor` to call later. (b) E-4: `GET /proxies` serves a **stored** url-test
  history (`LoadURLTestHistory`×2, `json:"delay"`×1, `meanDelay`×**0**), so no AC may assume a fresh
  measurement or the Clash.Meta aggregate field.
- **It found the sharpest correctness surface before stage 4 could discover it** (D-6): if `active`
  may hold the group's tag, config generation's stale-active repair at `bin/sc:1472-1475` **clobbers
  it back to `node_tags[0]` on every regeneration** unless its predicate widens (AC-9); `cmd_rm`
  (`:1655-1656`) leaves `active` naming a vanished outbound when the last node goes (AC-10); and
  `_resolve_node()`'s substring fallback (`:1578-1583`) lets a node named `auto-jp` swallow
  `sc use auto` (AC-12). None of these were in my brief.
- **Rule-85 ruling is argued, not asserted**: both halves are one task — test 1 fires because half B
  alone ships a delay column that is empty on every host nobody has probed (dishonest on its own,
  the T-01 `INSTALL_OK` precedent), test 2 fires because both halves need "which node is traffic on
  right now".
- **R-16 ruled NOT claimed by T-15** (D-12), with the reason: this task's overlay is code-authored
  and uses the existing `$replace` on an array `CONFIG_BASE` already defines, while R-16 is about a
  *user* override replacing an array with a bare object. R-16 stays open for T-16/T-17/T-21. NG-13
  makes the ruling binding, so stage 3 need not re-open it.
- **NG-6 pre-empts a re-litigation**: the urltest `interval`/`idle_timeout` are probe cadence emitted
  into sing-box's config, not `sc`'s own waits, so they are governed by AC-16 rather than by the
  no-new-timeout-constant boundary. Stated inside the non-goal itself.

Three items deliberately handed to stage 2 as design calls with their governing ACs already fixed:
the reserved tag literal (D-2, recommends `auto`), the one-node arm (D-4, recommends always emitting
the group at ≥1 node), and the group parameters (D-11 → AC-15/AC-16).

New open row surfaced: **R-19** (the five `ls.*` keys print literally in English at `bin/sc:174-178`;
the new column header must not copy that defect — D-13/NG-10). PM will file at delivery.

## Resume 2026-08-13 (batch `default`, pool run)

Task adopted mid-flight by a new PM instance dispatched from `/harness-batch`. State on entry:

- `01_REQUIREMENT_ANALYSIS.md` present, verdict **READY** — read in full, **not** re-dispatched.
- `02_SOLUTION_DESIGN.md` **absent** — the previous stage-2 dispatch produced no artifact. A missing
  *contract* portion routes back to the stage that owes it, so stage 2 is re-dispatched. Not a
  rollback: stage 1 is untouched and no round-1 stage-2 findings exist to carry forward, so the
  rollback streak at stage 2 stays at 0.
- `.harness/intervention.md`: **absent** — nothing to consume.
- No `.harness/agents/dev-*.md` on this project ⇒ **single-Developer mode** at stage 4
  (`harness-kit:developer`).

Host facts recorded once, so no downstream stage rediscovers them:

- `.harness/scripts/task-state.js` **does not exist** on this host (only `.sh`/`.ps1` scripts are
  present). Durable counters are unavailable; this `PM_LOG.md` is the sole rollback ledger, and the
  three-consecutive-rollbacks stop is tracked here by hand.
- There is no extensionless `verify_all` dispatcher either — the declare-done gate is
  `bash .harness/scripts/verify_all.sh`. Batch baseline measured at batch start:
  **PASS 16 / WARN 1 / FAIL 0 / SKIP 1**, the WARN being F.6 on this task's own 597-line
  `01_REQUIREMENT_ANALYSIS.md`, which clears on archive. Note this differs from AC-32's stated
  baseline (PASS 17 / WARN 0); the delta is that same F.6 WARN, so AC-32's "no FAIL" bar is the
  operative one and the WARN is **predicted, not discovered**.
- `archive-task` likewise exists only as `.sh`/`.ps1`; R-18 (rotation counts bullets, F.4 counts
  lines) means the insight index at the 30-line cap must be **hand-rotated** at delivery.

### Stage 2 re-dispatch (round 2)

Dispatched `harness-kit:solution-architect` with: the three design calls stage 1 handed forward
(D-2 tag literal, D-4 one-node arm, D-11 → AC-15/AC-16 group parameters), the binding NG-13/D-12
R-16 ruling (stage 3 must not re-open it), and the Clash-API insight line (`GET /proxies` serves a
stored `LoadURLTestHistory`, `json:"delay"`, no `meanDelay`). Told to name the partition section as
not-applicable, and to keep `02_SOLUTION_DESIGN.md` under the 500-line cap by citation rather than
paste (rule 70) since F.6 already fired once on this task.

**Round record (stage 2, round 2)** — returned by the architect, written here because no stage doc
carries a changelog: *round 2 · produced `02_SOLUTION_DESIGN.md` (215 lines) + `02_RATIONALE.md`
(145 lines) where round 1 produced nothing · D-2/D-4/D-11 resolved, AC-15 answered with
binary-string evidence, one upstream gap (a node already tagged `auto` on an upgrading host) closed
in-design as K-6, BC-6 re-homed to V-4 because the session had no shell tool · no finding id, round
1 left none.*

### Stage 2 → 3 (ADVANCE)

`02_SOLUTION_DESIGN.md` verdict **READY**; both portions present, 215 + 145 lines, both under the
500-line cap. Read in full by the PM. Basis for advancing:

- **All three handed-forward design calls are resolved, not deferred again.** D-2 → `AUTO_TAG =
  "auto"` with `RESERVED_TAGS` built *from* it (I-1/I-2), so FR-2's single-definition property is
  structural. D-4 → always emit at ≥1 node, with the cost stated rather than hidden. D-11/AC-16 →
  five parameter rows individually justified (I-9…I-13), including one **changed** from the report's
  starting point (`interrupt_exist_connections` omitted, because an automatic 51 ms-triggered switch
  must not kill live connections) — which is what AC-16 asked for and what a wholesale adoption
  would not have produced.
- **AC-15 is answered with a mechanism, not an assurance** (K-14/K-15): with no `domain_strategy`
  on the emitted outbound the probe FQDN goes to the member's remote server rather than a local
  resolver, so `remote_dns` → `proxy` → the group is unreachable; the fallback branch is pinned to
  `direct_dns` by `route.default_domain_resolver`. It is also made *falsifiable* by V-19 (a delay
  exists ⟺ the probe resolved and completed), which is the part that keeps it honest.
- **NG-13/D-12 held.** The change reaches the document through the existing `$replace` on a key
  `CONFIG_BASE` already defines; `_merge()`'s vocabulary is in the frozen set. R-16 stays open.
- **FR-9 is discharged explicitly** (RS-1): nothing was inexpressible in the T-14 layer, stated as a
  finding rather than left silent, plus a forward observation for T-16/T-17 (a second shipped
  overlay must `$append`, not re-state the array).
- **It found and closed an upstream gap rather than silently widening FR-1** (K-6): BC-7 covers a
  colliding share-link *fragment* but not a node **already** tagged `auto` on an upgrading host,
  which would have emitted a duplicate tag and failed AC-17's quiet-upgrade promise. Handled by
  I-3's second clause. Not routed back to stage 1: the fix lives entirely in the design's emit
  condition, requirements need no new AC to express it, and a rollback would cost a full stage-1
  round to add a boundary condition the design already satisfies. **Stage 3 is told to test this
  judgment specifically** — it is the one place a downstream stage absorbed an upstream defect.

**Filename correction (PM, per the stage-doc filename authority).** RS-4's "must reach" column names
`06_QA_REPORT.md`. The pipeline's stage-6 contract filename is **`06_TEST_REPORT.md`**. Corrected in
the stage-3 and stage-6 dispatch prompts; the design doc itself is left as written (downstream
cannot edit upstream, and this is a routing correction, not a design defect).

### Carried-forward verification debt (PM)

**RS-4 / BC-6 is not settled and is not a blocker.** The architect had no shell tool, so no real
`sing-box check` ran. Routing judgment: not a stage-2 rollback, because (a) the design makes an
empty member list *unreachable by construction* (I-3 requires a non-empty `node_tags`), so BC-6 is
defensive rather than load-bearing, and (b) AC-14 already puts the real binary in front of six
generated documents at stage 4/6, where the tooling exists. V-4 carries the empty-member probe as a
record-keeping item. Stage 3 (`Read`/`Glob`/`Grep` only) cannot settle it either; **stage 4 owes the
answer**, and stage 6 confirms it.

### Stage 3 → 4 (ADVANCE)

`.harness/intervention.md` re-checked before this routing decision: **absent**.

Both stage-3 portions were returned in the reviewer's final message and **transcribed verbatim** by
the PM (the reviewer holds no write capability). Pre-write check passed on both: each body begins
with its declared opening line — verified against the reviewer's own schema at
`~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.47.0/agents/gate-reviewer.md:18-19,38-39`
rather than assumed — the contract ends at its `## Verdict` line, both header-named paths carried a
portion, and neither was reported partial. Nothing was added, completed or repaired.

**Round record (stage 3, round 1)** — *round 1 · first gate review of T-15, no prior round ·
full-mode audit against `bin/sc`, both READMEs, `CHANGELOG.md`, `docs/dev-map.md`,
`.harness/insight-index.md` and `verify_all.sh` · verdict APPROVED WITH CONDITIONS, 5 PASS / 3 WARN /
0 FAIL, findings F-1…F-7, conditions C-1…C-9 binding on stages 4 and 6 · no route-back to stage 1 or
stage 2 · finding ids opened: F-1 (K-6 silent carve-out, indistinguishable `Switched to: auto`), F-2
(V-19 unrunnable under S-5), F-3 (I-13 vs the DoH transport), F-4 (AC-21 unobserved), F-5
(AC-31/AC-26 unobserved), F-6 (delivered delay column on pinned hosts), F-7 (RS-1 received and
answered as Q-5).*

Verdict **APPROVED WITH CONDITIONS**, which per the reviewer's vocabulary (`:52-55`) means
development may proceed with C-1…C-9 met *during* development. The stage-4 gate is therefore
satisfied. Basis for advancing rather than rolling back:

- **Zero FAIL dimensions and no `BLOCKED ON …` verdict.** The three WARNs are all *verification*
  gaps or a stated tension, not a defect in the requirement or the design — and each one is
  converted into a numbered binding condition with a named owner stage, which is the mechanism that
  makes advancing safe.
- **It re-derived rather than trusted.** Every cited anchor in `02` was checked at the source
  (`_unique_tag`'s single call site at `bin/sc:1639`, `clash_api`'s `timeout=3` at `:1546`, the
  `_warn_drift` ordering `:1502` before `:1506`, `HELP_ZH:2379`, `CHANGELOG.md:3/:5`), and it walked
  AC-9's clobber path through the real repair predicate to confirm the design's central claim.
- **It tested the K-6 judgment I flagged and reached a sharper answer than either side.** It agrees
  the *mechanism* was right to close in-design, and isolates what stage 2 could not legislate: on a
  host with a node already tagged `auto`, `sc use auto` prints a `Switched to: auto` that is
  **byte-identical** to the real-group case (`bin/sc:1576`, `:1624`), so the surface a user would
  consult to check actively confirms the wrong belief. That is F-1 (major) → C-1 + C-2, discharged
  inside stage 4's existing L-13/L-14 scope. This is the finding that most justified running the
  gate at all.
- **It caught two ACs whose V-rows do not observe them** (F-4: V-12's observables discharge AC-20,
  not AC-21, and V-11 runs with `SYSTEMD = OPENRC = False` so `restart_service()` is inert; F-5:
  no step renders the table with the group row, nor one mixing known and unknown delays) — exactly
  the "has a V-row but nothing actually discharges it" class I asked it to hunt.
- **F-2 is correctly sized.** V-19's precondition (the group *selected* on the live host) is
  reachable only via the `PUT /proxies/proxy` that S-5 forbids, so AC-15's falsifier as written is
  unrunnable. It did **not** inflate this into a block, because K-14/K-15 already discharge AC-15's
  literal demand and the rationale names three independent paths that all terminate away from the
  group. C-3 lets QA record V-19 as not-run *stated as such*, which is the honest resolution.
- **The bindings I told it not to re-open stayed closed** (NG-13/D-12/R-16, NG-6, the rule-85
  ruling), and it spent no finding on the `06_QA_REPORT.md` naming slip I had already corrected.
- **F-3 is a live tension handed to stage 4, not a dodge.** It declines to pick a value for
  `interrupt_exist_connections` on the group because the deciding fact — how long a DoH transport
  through a half-dead member takes to error out — is unmeasured by anyone in this pipeline. C-6 asks
  stage 4 to weigh the case and record the answer.

No route-back. Rollback streak at stage 3: **0**.

### Stage 4 dispatch (round 1)

Dispatched `harness-kit:developer` (single-Developer mode; no `.harness/agents/dev-*.md` exists).
Carried: the C-1…C-9 conditions as non-negotiable acceptance items, the six pre-answered questions
Q-1…Q-6 so they are not re-asked, the S-1…S-9 safety constraints with the live-service and
`_init_files()` hazards restated, the `verify_all.sh` invocation form and the no-FAIL bar, and the
stage-4-owed evidence: V-4's real `sing-box check` battery (which also settles RS-4/BC-6 per C-7)
and C-4's own observable for AC-21.

**Round record (stage 4, round 1)** — *round 1 · initial implementation of L-1…L-17 per the migration
sequence, C-1/C-2/C-4/C-5/C-6/C-7 discharged · why: first pass · findings: none (no rework).*

### Stage 4 → 5 (ADVANCE)

`.harness/intervention.md` re-checked: **absent**.

**Stage-5 gate satisfied.** `04_DEVELOPMENT.md` §`verify_all result` records
`bash .harness/scripts/verify_all.sh` → **PASS 16 / WARN 1 / FAIL 0 / SKIP 1**, identical to the
batch baseline: **no FAIL**, no new WARN. The single WARN is F.6 on this task's own stage-1 doc and
clears on archive, exactly as V-22 predicted. PM confirmed the diff independently — `git diff --stat`
shows `bin/sc` +217/−19, `README.md` and `README.zh-CN.md` +23/−2 each, `CHANGELOG.md` +2,
`docs/dev-map.md` +10/−4, and **nothing outside NFR-5's permitted diff** (`docs/tasks.md` and
`docs/batches/**` carry the batch orchestrator's own pre-existing edits, not the developer's).

Basis for advancing:

- **All six developer-owned gate conditions are discharged with evidence, not asserted.** 179 fixture
  assertions, 0 failures, across four scratchpad harnesses; nothing added to the repo (NG-9 held).
- **C-7 settled the question stage 2 could not.** The real `/usr/local/bin/sing-box check` on a
  `urltest` with `outbounds: []` → **exit 1, `FATAL[0000] initialize outbound[1]: missing tags`**.
  E-4's hypothesis is now confirmed fact, and `_auto_group_emitted()`'s first clause is load-bearing
  rather than tidy. RS-4/BC-6 is closed.
- **C-6 was resolved by finding a better fact, not by picking a side.** The gate framed the call as
  turning on an unmeasured quantity (how long a DoH transport through a half-dead member takes to
  error out). The developer instead read the installed binary and found
  `interrupt.ContextWithIsExternalConnection` / `IsExternalConnectionFromContext` beside
  `(*Group).Interrupt`: `interrupt_exist_connections` governs **external, inbound-originated**
  connections only, so sing-box's own internally dialled DoH transport is torn down on re-selection
  regardless. F-3's inversion does not occur; the omission stands, the emitted document is unchanged,
  so no V-4 re-run was owed. This is the strongest single result of the stage.
- **C-1/C-2 close gate finding F-1.** The `auto`-named-node fixture reproduced the hazard exactly —
  `sc use auto` there prints a `Switched to: auto` byte-identical to the failover case — and the fix
  is the mirrored blockquote at `README.md:103` / `README.zh-CN.md:103` stating that no group exists
  on such a host and that the line does not mean failover.
- **C-5 exceeded its bar**: AC-31 is verified in its strongest available form — every HEAD row is a
  **byte-prefix** of the candidate row, header included — rather than by index comparison alone.
- **C-4 gave AC-21 a real observable**: `restart_service()` wrapped by a counting proxy, entered 2/2
  on `sc reload` and 0 on a no-change `sc update-rules`, with `SYSTEMD = OPENRC = False` so it is a
  call-site observable and never a live bounce. V-12 is now cited for AC-20 only.
- **Design drift: none**, and the frozen set is grepped byte-identical in the diff (`_resolve_node`,
  `clash_api`, `_merge`/`DIRECTIVES`, `_write_private`, `cmd_now`, `cmd_status`, `_warn_drift`, the
  five `ls.*` keys, `CONFIG_BASE.dns`, `route.default_domain_resolver`). Two elaborations inside a
  ledger row's own intent are self-reported rather than left for the reviewer to find.
- **Safety held.** The S-6 witness (`MainPID=2566751`, `Tue 2026-08-11 12:13:57 CST`) is identical
  before and after stage 4; every mutation went to a stub server, never the live Clash API.

**Correction to a stale figure carried in my own dispatch (PM).** Stage 1's S-6 baseline
(`MainPID=2887037`, `Sat 2026-08-01 10:06:40 CST`) was already stale when stage 4 began; the live
witness has read `MainPID=2566751 / Tue 2026-08-11 12:13:57 CST` since a service start on 2026-08-11,
i.e. **before** this batch. Not a bounce and not caused by any stage of this task. The **new figures
are carried into the stage-6 dispatch** so QA does not misread the drift as a restart.

Four insight candidates surfaced in `04_DEVELOPMENT.md` `## Insight to surface`; PM will weigh them
for `07_DELIVERY.md`'s harvest at delivery (the index is at the F.4 cap, so they compete for space
against a hand-rotation).

### Stage 5 dispatch (round 1)

Dispatched `harness-kit:code-reviewer` (no write capability — returns both portions in its final
message; PM transcribes verbatim to `05_CODE_REVIEW.md` / `05_RATIONALE.md`). Carried: the three
upstream contracts by name, the C-1…C-7 dispositions to audit rather than re-derive, the frozen set
and NFR-5 as the drift surface, and the read-only constraint (S-1's auto-elevate hazard means the
reviewer must not execute `bin/sc` in any form).

**Round record (stage 5, round 1)** — *round 1 · first review of the T-15 working tree; no prior
round, nothing corrected · read-only audit of `bin/sc` + 4 docs against 01/02/03 · findings
CR-1…CR-5, verdict APPROVED.*

### Stage 5 → 6 (ADVANCE)

`.harness/intervention.md` re-checked: **absent**.

Both stage-5 portions transcribed verbatim by the PM. Pre-write check passed: each body begins with
its declared opening line (verified against `…/harness-kit/0.47.0/agents/code-reviewer.md:19,43`),
the contract ends at its `## Verdict` line, both header-named paths carried a portion, neither was
reported partial. The reviewer wrapped each body in a presentation fence in its message; the fences
are message delimiters, not document content, so the content between them was written unchanged —
nothing added, completed or repaired.

Verdict **APPROVED**. Basis for advancing:

- **No MAJOR or CRITICAL finding, and no design drift** — silent or declared. Every I-1…I-19 shape
  and K-1…K-18 constraint was checked at source and holds; 33 of 35 ACs are satisfied in code, and
  the two that are not (AC-15/AC-23) are carried to QA by C-3, which is where the design itself
  directs them.
- **The two MINOR findings are both correctly *not* routed back.** CR-1 is the sharper one: a 2xx
  body that is not JSON raises `ValueError`/`UnicodeDecodeError` out of `clash_api()`
  (`bin/sc:1637`) — one frame *above* `stored_delays()`, which the reviewer confirmed is itself
  total. It cannot be fixed here without violating a constraint: `clash_api()` is frozen (AC-28) and
  K-12 forbids a local `try`/`except`. It is also **pre-existing** — `cmd_status:1877` carries the
  same exposure at HEAD — and reachability is compound (sing-box up *and* a foreign HTTP server
  holding the persisted Clash port). Routing it to the developer would be asking for a constraint
  violation, so it travels as RES-1 to QA's adversarial section and then to delivery as a candidate
  follow-up row against `clash_api()`.
- **CR-2 corrects a pre-answered question rather than accepting it.** Q-2 licensed `cmd_rm`'s kept
  guard on the premise that the repair "persists before anything downstream can fail"; the reviewer
  traced the real ordering and found `_load_override()` at `bin/sc:1543` runs *before* the repair at
  `:1560-1564`, so a malformed `override.json` leaves `active: "auto"` with zero nodes. It then
  established the consequence is nil — no document is emitted in that run, so no emitted-document AC
  is violated, and the next successful generation repairs it. Precisely the "the contract modelled
  this more favourably than the code delivers" class a gate cannot catch from documents alone.
- **It independently adjudicated C-6**, the one call stage 4 resolved by inference. It re-read the
  binary rather than accepting the transcript, and found the semantics run *stronger* than the
  developer claimed: `Interrupt(interruptExternalConnections bool)` **spares** external connections
  when false and never enables interruption of internal ones — the opposite direction from F-3's
  fear. Gate finding F-3 is closed on substance.
- **It re-derived the two by-construction claims** (AC-5's zero-node collapse and AC-9's
  idempotence) as arguments rather than trusting the fixtures, and stated plainly what it could
  *not* do: with no shell it could verify frozen-set byte-identity only structurally (RES-2, one
  `git diff` over eleven anchors closes it — routed to QA).
- **Three NITs** (CR-3/CR-4/CR-5) are cosmetic, mirrored in both READMEs, and none touches AC-34.

No route-back. Rollback streak at stage 5: **0**.

### Stage 6 dispatch (round 1)

Dispatched `harness-kit:qa-tester`. Carried: the six residuals QA owes (RES-1…RES-3 are actionable
this stage), the three QA-owned gate conditions **C-3** (V-19 run by a non-mutating route or recorded
as not-run-and-why), **C-8** (both READMEs state the delay is a stored value and `-` on a pinned host
is by design) and **C-9** (the `^##\s+Adversarial\s+tests` heading shape and the no-FAIL bar), the
S-1…S-9 safety constraints, and the **corrected** S-6 witness figures (`MainPID=2566751`,
`Tue 2026-08-11 12:13:57 CST`) so pre-existing drift is not misread as a bounce. The dispatch also
required QA to **rebuild its own harness** rather than inherit stage 4's, and to **prove non-vacuity**
(a test that cannot fail is not evidence) — the S-8 `LANG` trap being the named example.

**Round record (stage 6, round 1)** — *round 1 · QA rebuilt the fixture harness from
`docs/dev-map.md:109-135` (no stage-4 scratchpad reuse), ran V-19 by an isolated route, and filed 5
defects · why: C-3/C-8/C-9 plus RES-1/RES-2/RES-3 needed independent evidence, and the headline
behaviour had no AC covering it · findings: DEF-1…DEF-5.*

### Stage 6 → 4 (ROLLBACK — DEF-2)

`.harness/intervention.md` re-checked: **absent**.

Verdict **CHANGES REQUIRED (1 defect)**. Routed per the rollback table (*QA finds bug → developer*):
**DEF-2 to `harness-kit:developer`**, round 2. This is the pipeline working as designed — five stages
of document review passed this diff, and only running the real binary against real traffic found it.

**DEF-2 (MAJOR).** Both READMEs (`:89`) and `CHANGELOG.md:7` promise a degrading node "stops carrying
traffic … without anyone having to type a command". Measured on the real binary with the emitted
parameters:

| fault injected | measured outcome |
|---|---|
| member gets slower (positive control) | demoted at **183 s** — I-10's "≈ one interval" bound confirmed |
| member refuses connections | demoted at **190 s**, every request failing throughout |
| member accepts and never answers | **never demoted in 440 s** (2.4 intervals), 100 % of traffic failing |

The third is the failure `01 §1.2` **leads with** ("TLS handshakes that hang rather than refuse").
Three independent runs, same outcome, against a positive control that does move — so the harness can
see a re-selection. `conns A=+10 B=+1` at t=180 proves the interval check ran; the stale history
survived, and even after it was cleared the group did not move for a further 140 s. No emitted
parameter fixes this (sing-box exposes no per-probe timeout), so **the fix is a qualification of the
promise, not a code change** — inside NFR-5's permitted diff, which is why it routes to the developer
rather than back to the architect.

**Rollback streak at stage 4: 1** (of 3 before a mandatory stop). Stage 4 round 1's code is not in
question; every AC-1…AC-35 remains satisfied as written.

**Filed as follow-ups, deliberately NOT routed back (PM decision under standing authority):**

- **DEF-1 (MAJOR, pre-existing)** — RES-1 confirmed **and wider than the reviewer's analysis**: four
  uncaught exceptions escape the frozen `clash_api()` into `cmd_ls` (`JSONDecodeError`,
  `UnicodeDecodeError`, `TimeoutError`, `IncompleteRead`), so 2 of BC-9's 4 states fail AC-24. The
  reviewer's "needs a *foreign* HTTP server" reachability **understates it**: a stalled sing-box
  listener alone produces the `TimeoutError`. Not routed back because it is **not fixable inside this
  task's frozen set** — `clash_api()` is frozen by AC-28 (byte-identity now independently verified)
  and K-12 forbids a local `try`/`except`; asking the developer to fix it is asking for a constraint
  violation. HEAD's `sc status` raises the same types, so the diff creates no new exposure class —
  it puts one more command on an existing path. **PM files a pool row** naming the *class*, not the
  one body shape.
- **DEF-3 (MINOR)** — `RESERVED_TAGS` omits `GLOBAL`; a node so named inherits sing-box's implicit
  selector's stored delay (`9999 ms` in the reproducer). Narrow, no exception, table intact. **PM
  files a pool row.**
- **DEF-4 / DEF-5 (both MINOR, upstream, owned by `01`)** — DEF-4: not one of the 35 ACs observes the
  goal in `01 §2`; all verify the artifact. That is precisely why DEF-2 passed stages 2–5 with every
  AC green. DEF-5: `BC-9`'s stated mechanism is factually wrong (`except (URLError, HTTPError)` does
  not catch what `getresponse()` raises), and AC-24 inherited that reading.
  **Not routed to the requirement-analyst**, though the rollback table would allow it, because: (a)
  QA's own verdict names DEF-2 as the sole blocker and classes both of these MINOR; (b) the gap
  DEF-4 describes has already been **closed empirically** — QA measured the behaviour the missing AC
  would have demanded, and the discrepancy it exposed is being fixed this round; (c) DEF-5's
  consequence is DEF-1, already filed and unfixable here; and (d) reopening stage 1 would re-run six
  stages to add an AC whose evidence now exists in `06_TEST_REPORT.md`. Both become **open rows in
  `docs/tasks.md`**, carrying QA's evidence, so the next task touching this surface inherits the
  correction rather than rediscovering it. Recorded here as a PM routing decision, not a silent drop.

### Stage 4 dispatch (round 2 — DEF-2 only)

Scope deliberately narrow: qualify the promise at `README.md:89` / `README.zh-CN.md:89` /
`CHANGELOG.md:7` against QA's measurements. No code change, no re-opened design. AC-34's
line-for-line mirror and the `失败：` prohibition still bind; `verify_all` must stay at no FAIL.

**Round record (stage 4, round 2)** — *round 2 · qualified the failover promise in `README.md:89`,
`README.zh-CN.md:89` and `CHANGELOG.md:7` — the switch lands one probe round (~3 min of failing
traffic) after a slow/refusing member, and a member that accepts-and-never-answers is not covered at
all; `04_DEVELOPMENT.md` corrected in place (summary, L-13/14/15 rows, numstat diff totals, drift
elaboration, two new open issues, one new insight) · why: QA measured the shipped claim wider than
the behaviour and no emitted parameter can close the hang case (`urltest` has no per-probe timeout) ·
finding: DEF-2 (MAJOR).*

### Stage 4 (round 2) → 6 (ADVANCE — stage 5's APPROVED stands, not re-run)

`.harness/intervention.md` re-checked: **absent**.

The fix is what DEF-2 asked for: the promise now carries its two measured bounds — it still fires
unattended for a node that slows or starts refusing, but on the *next probe round* rather than
instantly, and it explicitly does **not** cover the hanging member, with `sc use <name>` named as the
manual escape. It corrects an overclaim without retreating into a hedge that promises nothing, which
was the failure mode I flagged in the dispatch.

**Stage 5 is deliberately not re-run, and the code review's APPROVED verdict stands.** PM verified
independently rather than accepting the developer's word: `git diff --numstat` shows `bin/sc` at
`200/17` and `docs/dev-map.md` at `6/4` — **byte-identical to the tree stage 5 reviewed** (both files
were untouched this round; the round-1 figures of +217/−19 in `04` were `--stat` changed-line counts,
now restated correctly). The entire round-2 diff is prose inside three files, and the three
constraints that prose can violate — AC-34's mirror, AC-33's `失败：` prohibition, K-18's CHANGELOG
placement — are all checked by **stage 6**, which is also the only stage holding the measurements the
new wording must match. Re-running a source-reading stage over a paragraph it cannot evaluate would
add a round and no information. Both READMEs remain **305 lines** (PM-verified).

Note for the record: stage 5 *did* review README prose in round 1 (CR-3/CR-4 are README findings), so
this is a scope judgment about *this* change, not a claim that prose is outside a code reviewer's
remit.

### Stage 6 dispatch (round 2 — focused re-verification)

Dispatched `harness-kit:qa-tester` for a **focused** round: re-verify DEF-2's fix against its own
measurements, re-assert AC-34's structural mirror, AC-33's parity and `失败：` scan, K-18's CHANGELOG
placement, and `verify_all` at no FAIL — plus confirm nothing else in the tree moved. Explicitly told
**not** to re-run the full 13-suite battery: round 1's results stand for everything the code still
does, and the S-6 witness must again be unchanged. Told to correct `06_TEST_REPORT.md` **in place**
(no `## Round N` section) and to keep the `## Adversarial tests` heading unnumbered.

**Round record (stage 6, round 2)** — *round 2 · corrected `06_TEST_REPORT.md` and `06_RATIONALE.md`
in place: DEF-2 re-verified against the new wording and marked CLOSED, verdict flipped CHANGES
REQUIRED (1 defect) → APPROVED FOR DELIVERY; added the NFR-3 claims-parity row to the test plan and
adversarial table, corrected the F.6 WARN detail (two over-cap files, not one) and the
suite/assertion counts · why: the developer's documentation-only fix was the only outstanding
blocker, and the contract portion must describe current state, not round history · finding id:
DEF-2.*

### Stage 6 (round 2) → 7 (ADVANCE)

`.harness/intervention.md` re-checked: **absent**.

Verdict **APPROVED FOR DELIVERY**. **Stage-7 gate satisfied**: stage 5 PASSED (APPROVED, and its
subject `bin/sc` is byte-identical to the delivered tree — QA re-confirmed by hash against the copy
its battery ran) and stage 6 now PASSES.

QA did not merely accept the fix. It wrote an independent reproducer from **its own measurements
rather than from the diff**, with three failure hypotheses stated in advance (en-only fix; zh keeps
the promise but drops a bound; the qualification buried in a later paragraph a reader skips) — all
three refuted, 22 assertions, 0 failures, plus a mutant arm proving the check detects a deleted
bound. It then made two judgment calls in the open rather than silently: "up to about 3 minutes"
rounds down across the 190 s it measured (accepted — the operative claim is the *mechanism*, "next
probe round", and the actionable figure is the emitted `interval`; it states it would have filed
"at most 3 minutes"), and the zh hang clause generalises slightly wider than the en (accepted — both
carry the unbounded mechanistic claim it follows from, and it errs toward warning). Claim sets match
atom for atom, so NFR-3 parity holds.

**QA's correction to its own round-1 report, worth carrying:** F.6's WARN now covers **two** files,
not one — `01_REQUIREMENT_ANALYSIS.md` (597 lines) and this `PM_LOG.md` (504 lines). Both leave the
`docs/features/` glob on archive, and F.4/F.6 count one WARN either way, so the no-FAIL bar is
unaffected. I am not compacting `PM_LOG.md` under rule 70 rule 2: compaction exists to keep an
**active** log cheap for the stages still to come, and there are none — the file is archived in this
same step, where the cap stops applying to it.

## Stage 7 — Delivery

`07_DELIVERY.md` composed. Verdict **DELIVERED**.

**Entropy watch: skipped, not-due.** `.harness/scripts/entropy-cadence` does not exist on this host
(the `.harness/scripts/` directory carries only `.sh`/`.ps1` units and no cadence pair). Per the
cadence's fail-open rule, any cadence I/O problem resolves to **NOT-DUE**: no scan was dispatched, no
`## Entropy watch` section was appended, and the delivery verdict is unchanged. Recorded rather than
silently omitted.

**Obligations discharged, in order:**

1. `07_DELIVERY.md` composed (Summary / Insight / Verdict; no entropy section, per above).
2. `docs/tasks.md` — T-15 moved from Active to Completed with a delivery summary; the Active table is
   now empty. Open rows **R-19** (the five `ls.*` keys, surfaced at stage 1 and made NG-10), **R-20**
   (DEF-1, the `clash_api()` exception class), **R-21** (DEF-3, `GLOBAL` unreserved) and **R-22**
   (DEF-4/DEF-5, the upstream requirement gaps) filed under a new T-15 section, each carrying why it
   was re-homed rather than fixed.
3. `docs/dev-map.md` — already updated by stage 4 (two reusable-utility rows, three section rows, and
   the `$replace`-versus-`$append` note T-16/T-17 will need). No further PM edit required.
4. Insight harvest + **hand-rotation** (R-18: `archive-task.sh` counts bullets, F.4 counts lines, so
   its rotation branch cannot fire on an index with a header — 21 + 4 = 25 bullets is under its 30
   while the file would sit at 34 lines against F.4's 30).
5. `archive-task.sh --task proxy-urltest-group`.
6. `verify_all.sh` re-run on the archived tree, then commit + push per rule 80.

### Delivery close-out (executed)

- **`archive-task.sh` run**: harvested 4 insights, moved all 9 stage docs + this log to
  `docs/features/_archived/proxy-urltest-group/`, exit 0. **Its rotation branch did not fire**, third
  confirmation of R-18: 21 + 4 = 25 bullets against its own 30, while the file stood at 34 lines
  against F.4's 30.
- **Hand-rotation done.** Four entries moved to `docs/features/_archived/insight-history.md` with the
  reason each stopped earning its line, chosen by rule 70's criterion rather than oldest-first: the
  `>>"$LOG"`/`tee` entry (blunt form of a family whose sharp form is still indexed, wider class filed
  as R-3); the systemd `PATH` entry (`systemctl show-environment` answers it in a minute — below
  rule 05's derivability bar); the `archive-task.sh` first-physical-line entry (**stale in its literal
  claim** — the script now carries a local awk fix that joins continuation lines, and R-18 is the
  better home for the residual `/harness-upgrade`-reverts-it risk); and the fswatch/`log.level=warn`
  entry (its decision is a delivered decline recorded in T-10's board row). **One kept deliberately**:
  the progress-throttle entry, because the 2026-08-01 rotation note had already declined to drop it
  on grounds that still hold, and re-dropping it would delete the corrected reading while its
  uncorrected predecessor is already gone. Index back to **30 lines, F.4 PASS**.
- **`docs/tasks.md` rotation — an unplanned obligation this delivery created.** With T-15's row and
  R-19…R-22 filed, the board hit **308 lines** and **F.5 turned WARN** just as F.6 cleared. Rule 70
  rule 3 assigns this to the PM, so the eight oldest Completed rows moved to a new
  `docs/tasks-archive.md`, keeping **T-15** and **T-14** — T-14 being the composition layer the
  remaining batch tasks (T-16 / T-17 / T-21) build on, so it is the one historical row they must
  read. The archive header records the real cause for whoever hits it next: the cap was reached by
  **row length**, not row count (ten rows against rule 70's ~30 trigger), so the durable fix is
  shorter outcome paragraphs, not more rotation. The board pointer was added *inside* the existing
  header blockquote line so the fix did not spend a line on itself.
- **Final gate: `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`** — better than the batch baseline (16/1), both
  doc-size WARNs cleared. Only SKIP is B.3 lint, pre-existing. `07_DELIVERY.md` and the board row
  were both corrected to this measured figure rather than left at the composition-time estimate.
- **Committed and pushed** per rule 80's standing authorization: `6778711`, 22 files,
  **+3119/−38**, pushed `1e454b6..6778711` to `origin/main` (fetched first; `origin` had not moved).
  Preconditions checked before staging: no FAIL, diff confined to what `07_DELIVERY.md` claims, no
  credential or real share-link in the diff (the two `vless://` grep hits are pre-existing README
  placeholder text in hunk context), nothing under `/etc/sing-box/` captured. **`docs/batches/**` was
  deliberately left unstaged** — those are the batch coordinator's files, not this task's, and rule 80
  forbids a blind `git add -A`.
- **One hard-safety event, handled without override.** `guard-rm.sh` blocked the first commit attempt
  — *"could not parse nested pwsh command safely"*, triggered by the heredoc form of the message, not
  by anything destructive (the command contained no `rm`). I did **not** set
  `HARNESS_ALLOW_OUTSIDE_RM=1`; overriding a guard because it inconvenienced me is the failure mode
  the guard exists to prevent. Re-issued as `git commit -F <scratchpad file>`, which the guard parses
  cleanly. Worth a row if it recurs: the guard's parser treats a heredoc body as a nested command.
