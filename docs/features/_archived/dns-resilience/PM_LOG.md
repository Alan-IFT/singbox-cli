# PM Log — T-16 / dns-resilience

> Mode: full (7 stages). Invoked by `/harness-batch` on pool `default`.
> Decision mode: owner granted standing authority (「你来决策就行」). `BLOCKED: NEEDS-HUMAN`
> reserved for a genuine safety red line only.

## Compacted stages 1..5 (2026-08-14, rule 70)

Compacted at the stage-6→7 boundary because F.6 fired on this file at 517 lines. Stages 1-5 are
stably past; their verbose entries are replaced by the one-line summaries below. **The measurement
probe block is kept verbatim** — `01`, `02`, `03`, `05` and `06` all cite `PM_LOG.md` as its home,
so deleting it would break five cross-references. Stage 6 and the round-3 closures are kept full.

### Task-start record

- Task folder created; **`.harness/scripts/task-state.js` does not exist on this host**
  (`MODULE_NOT_FOUND`), so durable counters were unavailable and rollback streaks were tracked by hand
  in the transition table below. Recorded fail-open.
- **Single-developer mode**: no `.harness/agents/dev-*.md` exists, so stage 4 dispatched the plugin
  agent `harness-kit:developer`. Not partitioned.
- Prior art read: `BATCH_PLAN.md` (T-16 row + the T-12 absorption, the live hand-patch, the rule-order
  constraint, the two through-lines), `docs/tasks.md` (T-14/T-15 rows; open rows R-15…R-22),
  `.harness/insight-index.md` (21 entries; **11 surfaced whole** into dispatch prompts — the
  auto-elevate trap, the `失败：` grep, the `MainPID`/`ActiveEnterTimestamp` witness, the clone-not-
  worktree rule, E.6's heading regex, `_init_files()`'s hard-coded path, the same-fixture-path rule,
  the `LANG` vacuity trap, and T-15's three urltest/Clash-API facts), and `bin/sc:1081-1143`.
- Baseline to preserve: `verify_all` **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**.

### Stage summaries

1. **Stage 1 r1 → READY.** 34 ACs (10 behavioural), R-22's lesson discharged at requirement level:
   behavioural class defined as "observes a real resolver in a real sing-box", `AC-B10` + `NFR-7`
   require a reproducing HEAD control or the run is inconclusive. **R-16 ruled NOT claimed** (Q-1) on
   T-16's own reasons, not inherited from T-14 or T-15 — no README obligation incurred.
2. **Stage 2 r1 → BLOCKED ON UPSTREAM (FR-9, FR-10).** Design complete except the budget; the architect
   could not establish that sing-box accepts a DNS-query-level wait, and proved `connect_timeout`
   cannot serve (BC-2's hang is *after* the dial). **FR-13's required report came back "the composition
   layer expressed everything" — no new directive, no literal in `generate_config()`.**
3. **PM-commissioned measurement probe** (instrument, not a stage — wrote no stage doc). Neither stage 1
   nor 2 holds `Bash`; rolling back before measuring would have made the analyst restate FR-9 on a
   guess. Results kept verbatim below.
4. **Stage 1 r2 → READY.** FR-9 restated (no new stall + a 100 ms bound on the node-independent class),
   FR-10 inverted keeping its number, **FR-8 ↔ FR-11 resolved in FR-11's favour** (Q-17: the
   no-rule-matched class *is* the foreign internet, so re-pointing `final` would change answers and
   disclose every foreign name to the domestic resolver **on every healthy host**), BC-22 corrected.
   AC counts unchanged at 34/10/24, every id preserved; behavioural ACs shrank to a *smaller observed
   behaviour*, never to an artifact check.
5. **Stage 2 r2 → READY.** Deleted I-8/I-9/`DNS_BUDGET`/L-6/K-2/K-4/V-1/V-2/RS-2/RS-4/RS-5; froze
   `dns.final` (I-16/K-13); added I-17 mapping the node-independent class per mode and per rule-set
   state. **It verified the analyst's re-examine list rather than executing it** — declining to delete
   V-11 (that would have left AC-7's second half unverified) and adding three things the AC texts imply
   but do not state, incl. V-36's non-vacuity run.
6. **Stage 3 → APPROVED WITH CONDITIONS (C-1…C-11), 10 findings.** Corrected my dispatch's verdict
   vocabulary (I had named the *plan-mode* string), refused to soften dimension 7's FAIL while still
   approving, and **caught a second instance of RS-10's defect class (F-1)**: four behavioural HEAD
   controls classified as *agreement* controls would have stalled ≈10 s and returned inconclusive.
   Ruled RS-10 amendable in place by C-2 rather than by a third requirement round.
7. **Stage 4 r1 → READY FOR REVIEW.** All V-steps run, none inconclusive; four upstream drift rows
   found and recorded rather than worked around (notably **DR-5**: the design's "usable node" staging
   passes `sing-box check` and dies at run).
8. **Stage 5 r1 → CHANGES REQUIRED (2 MAJOR), stage 6 held.** Both MAJORs were shipped *text*:
   **CR-1** violated binding condition C-4 outright; **CR-2** shipped "every AAAA lookup still travels
   to the proxied resolver" **as a measured claim** when it is false for four of six probe classes, and
   the section contradicted its own table three paragraphs later. This is T-15's R-22 class, caught a
   stage earlier this time.
9. **Stage 4 r2 → READY FOR REVIEW.** CR-1/CR-2/CR-3 text, CR-5 code (a `UnicodeDecodeError` traceback
   in this task's own new function), CR-7 reconciled. **CR-7 resolved against me**: my "+275" was
   `--stat`'s changed-line column (263+12), so no added line was ever outside V-24's scan — the charge
   was mine, not stage 4's.
10. **Stage 5 r2 → APPROVED** (0 CRITICAL, 0 MAJOR; 3 MINOR, 2 NIT). The reviewer **withdrew its own
    CR-7** rather than leave a false charge standing, and verified CR-5's invariant is now *total* by
    walking every other escaping class on the path.

### Infrastructure faults (neither caused by the task)

- Stage 5 r2 dispatch #1 failed with `claude-sonnet-5[1m] is temporarily unavailable, so auto mode
  cannot determine the safety of Agent` — the same classifier outage that stranded T-01's stage 5 in
  this batch. Cleared on retry.
- Stage 6 dispatch #1 was killed mid-run by `API Error: Unable to connect to API (ENOTIMP)`. Verified
  clean afterwards before re-dispatch: **no `06_TEST_REPORT.md` written**, `git status` unchanged, HEAD
  still `9f85f9e`, live service untouched, and `pgrep -x sing-box` showing only the live process — no
  fixture instance survived.
- `guard-rm.sh` blocked a `cat >> … <<'EOF'` append to this log ("could not parse nested pwsh command
  safely") on a command containing **no `rm`** — the same misparse T-15 hit on `git commit`. The bypass
  was **not** set; the `Edit` tool was used instead.

## Measurement probe results (kept verbatim — cited by `01`, `02`, `03`, `05`, `06`)

Read-only against the real `sing-box 1.13.15` (`Revision 3708fa18766c`). **Live service provably
untouched**: `MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` identical before,
mid-probe and after; live Clash API on `127.0.0.1:29090` never contacted; every fixture process
confirmed dead; no repository file modified.

**M-1 — V-2 REJECT, decisively.** `"timeout": "4s"` is rejected in all three placements:

| variant | exit | stderr |
|---|---|---|
| base fixture (control) | 0 | *(empty)* |
| `timeout` on `remote_dns` | 1 | `dns.servers[1].timeout: json: unknown field "timeout"` |
| `timeout` on `direct_dns` | 1 | `dns.servers[2].timeout: json: unknown field "timeout"` |
| `timeout` at `dns` block level | 1 | `dns.timeout: json: unknown field "timeout"` |
| `timeout` on `dns.rules[1]` | 1 | `dns.rules[1].timeout: json: unknown field "timeout"` |
| **bogus-key control** on the same objects | 1 | `… json: unknown field "nonsense_key_zz"` |

The bogus-key control is what makes the rejection informative: **the decoder rejects unknown fields**,
so `timeout` being rejected proves it is not a field of a DNS server, the `dns` block or a DNS rule in
this build — not merely that it was ignored. String probe: `query_timeout` 0, `dns_timeout` 0,
`exchange_timeout` 0, `connect_timeout` 2 (dial-fields struct), `json:"timeout` 5 (four are
`timeout_ms`; the one `json:"timeout,omitempty"` sits among inbound/sniffer strings, not DNS).

**M-2 — the DNS rule chain never falls through on failure.** Fixture in exactly the I-8 shape, two
local stub resolvers, non-vacuity proved by sing-box's own trace:

| state | remote stub | direct stub | wall clock | client result |
|---|---|---|---|---|
| remote answers | received, replied | **never consulted** | 0.018 s | `NOERROR A 10.77.0.1` |
| remote NXDOMAIN | received, replied | **never consulted** | 0.017 s | `NXDOMAIN` |
| remote SERVFAIL | received, replied | **never consulted** | 0.007 s | `SERVFAIL` |
| **remote black-holes** | one packet, no reply | **never consulted** | **30.046 s** (client's own limit) | `no servers could be reached` — sing-box sent nothing |

**M-3 — the 10 s is sing-box's own per-query DNS deadline, and it is not configurable.** Logged
`dns: exchange failed …: context deadline exceeded` stamped `[10.0s]`, reproducibly across three runs
at two client timeouts. **At expiry sing-box drops the query silently** — no answer, no retry, no
second server.

**M-4 — `dns.final` is the no-rule-matched routing default, never a failure fallback.** Control: with
the rule changed so nothing matches, the direct stub was consulted in 0.006 s.

**M-5 — explicitly NOT established** (respected as such by every downstream stage): that no
query-level bound exists under some *other* key name (only `timeout` was probed, in three positions);
where the 10.0 s constant lives in the binary; whether a detoured DoH server behaves like the measured
plain-UDP path.

**Two fixture facts the probe paid for**, promoted to binding constraints: `CONFIG_BASE`'s
`{"action": "sniff"}` is a **prerequisite** for the `hijack-dns` rule (without it a `direct` inbound
forwards the packet to itself in a silent loop); and a fixture omitting `route.default_domain_resolver`
**fails `check` outright** in 1.13.15.

## Stage transitions

| # | Stage | Agent | Round | Verdict | Route decision |
|---|---|---|---|---|---|
| 1 | 1 — requirement | requirement-analyst | 1 | READY | ADVANCE to stage 2 |
| 2 | 2 — design | solution-architect | 1 | BLOCKED ON UPSTREAM (FR-9, FR-10) | HOLD — commission probe |
| 3 | probe | (PM instrument, general-purpose) | — | V-2 REJECT; no fall-through; 10.0 s is sing-box's | ROLLBACK to stage 1 |
| 4 | 1 — requirement | requirement-analyst | 2 | READY | ADVANCE to stage 2 (round 2) |
| 5 | 2 — design | solution-architect | 2 | READY | ADVANCE to stage 3 |
| 6 | 3 — gate | gate-reviewer | 1 | APPROVED WITH CONDITIONS (C-1…C-11) | ADVANCE to stage 4 |
| 7 | 4 — development | harness-kit:developer | 1 | READY FOR REVIEW | ADVANCE to stage 5 |
| 8 | 5 — code review | code-reviewer | 1 | CHANGES REQUIRED (2 MAJOR) | ROLLBACK to stage 4 |
| 9 | 4 — development | harness-kit:developer | 2 | READY FOR REVIEW | ADVANCE to stage 5 (round 2) |
| 10 | 5 — code review | code-reviewer | 2 | APPROVED (0 CRITICAL, 0 MAJOR) | ADVANCE to stage 6 |
| 11 | 6 — QA | harness-kit:qa-tester | 1 | APPROVED FOR DELIVERY | close 2 MINORs, then stage 7 |
| 12 | 4 — development | harness-kit:developer | 3 | closed | QA-1 text fix landed |
| 13 | 1 — requirement | requirement-analyst | 3 | filed | C-2, C-4, QA-2 closed in `01` |
| 14 | 7 — delivery | (PM) | 1 | — | in progress |

**Rollback totals: 2** (stage 2→1 on measurement; stage 5→4 on two MAJOR text defects). Peak streak at
any one stage: **1** — the 3-consecutive-rollback stop rule never came close to firing.

**Transcriptions performed** (stages 3 and 5 hold no write capability): `03_GATE_REVIEW.md` +
`03_RATIONALE.md`, and `05_CODE_REVIEW.md` + `05_RATIONALE.md` twice (round 2 **replaced** the content,
never appended). Each time I checked the body opened with its declared line, ended with its `## Verdict`
line, that every header-named path carried a portion, and that no partial return was reported — then
wrote verbatim, repairing nothing.

**Intervention checks: 13, all absent.** `.harness/intervention.md` was checked after `PM_LOG.md`
creation, after every stage completion, and before every re-dispatch. Never present; nothing consumed.

## 2026-08-14 — stage 6 complete

- `06_TEST_REPORT.md` (165) + `06_RATIONALE.md` (423). Verdict **APPROVED FOR DELIVERY**; `verify_all`
  **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**. E.6 PASS (heading unnumbered). The V-25-predicted F.6 WARN
  did not fire on QA's own documents.
- **Stage-7 gate satisfied: stages 5 and 6 both PASS.**
- **QA rebuilt rather than inherited.** It took the C-7 recipe, DR-4/DR-5, the `.test` trap and the two
  `sniff`/`default_domain_resolver` facts **as instructions only**, and rebuilt the import shim, the
  eight-constant repoint with assertion, both UDP stubs, the hang listener, the `dig` driver, **every
  probe classification (re-derived by measurement before any assertion was written)** and every number.
  Baseline is a `git clone` at `9f85f9e`, verified pre-T-16 by reading `1101: … "query_type": [64, 65]`
  — the **repo**, not the hand-patched installed binary.
- **R-22 discharged by observation.** AAAA answered empty in **19.7 ms** where the HEAD control produced
  *no answer at all* and logged `[10.0s] dns: exchange failed … context deadline exceeded`. 3
  defect-reproducing controls exhibited their defect, 8 agreement controls matched, **no run
  inconclusive**. AC-B1's fixture was rebuilt and re-measured **10 times** from scratch, 10/10 identical,
  worst 23.9 ms against a 100 ms bound.
- **QA invented the test the plan lacked, and it is load-bearing — ADV-1.** Same candidate build, same
  fixture, `sc ipv6 on` + a hung node → **stalls at 15030.8 ms**. That proves the rig *can* observe a
  stall, so every candidate green is non-vacuous **on the candidate side too**, not merely that HEAD
  differs. ADV-2 proved types 64/65 were measurably *not* suppressed at HEAD in `direct` mode, which is
  what earns the changelog's rule-order claim.
- **C-2's corrected `direct` clause verified exactly as the gate wrote it**: `global` stalls 15031 ms;
  `direct` does not stall — HEAD answers from the non-proxied resolver (`ans=1`), the defect being the
  *absence* of suppression. The gate's ruling to amend in place is vindicated by measurement.
- **RES-1 discharged with a shell** (AC-8/AC-9 byte-identity by `ast`, never `grep`); **RES-3
  discharged**. Neither travels further.
- Two harness defects were found and fixed **in the harness**, neither in `bin/sc`, and recorded so the
  fix is not mistaken for a product change.
- **Baseline deliberately not updated** — this task commits no test (out-of-scope item 8; R-9 owns a
  committed harness), `verify_all`'s step count is unchanged, `.harness/**` is outside NFR-3. No
  operator obligation created.

## 2026-08-14 — two MINOR closures before delivery

I closed both rather than shipping them, because each was cheap and each was the over-claim class this
task had already caught twice.

### Stage 4 round 3 — QA-1 (developer)

> `round 3 · scoped the start-up write in README.md:124, README.zh-CN.md:124 and CHANGELOG.md:7 from
> "on a fresh host" / "全新机器上" to the set _saved_clash_port() actually decides (any host with no
> valid recorded clash_api_port, including one upgraded from a version predating the port auto-probe);
> 04_DEVELOPMENT.md corrected in place · why: QA measured that the start-up path writes settings.json
> on established hosts too, so "fresh host" misleads an upgraded user · finding id: QA-1 (MINOR,
> stage 5's CR-10 residue)`

- **It split the sentence into two write-sets rather than widening one clause** — directory creation
  and file seeding really are fresh-host-only, while the port write is not; one flat clause would have
  traded one imprecision for a bigger one. It wrote "valid" because `_saved_clash_port()` also returns
  `None` for an out-of-range port or an unparseable file.
- **The malformed-file consequence was deliberately left out of user text** and recorded unfixed and
  unclaimed in `04`'s open issues: it is reachable only on a file already unparseable, where every
  reader in `sc` already treats those keys as absent, so the rewrite discards a value that was not in
  effect. Putting a corrupted-file edge case into a sentence about "does `sc ipv6 show` change
  anything" would push aside the fact users need.
- Both READMEs still **332 lines** with identical structural line-number lists (102 marks each);
  `bin/sc` untouched at 272/12; C-4's unqualified disclosure clause preserved; K-16/C-10 re-checked.

### Stage 1 round 3 — C-2, C-4, QA-2 (requirement-analyst)

> `round 3 · C-2 folded into AC-B10, C-4 scoped AC-12/BC-11/NFR-5 (+FR-4) to cmd_ipv6(), BC-13 given
> the repair path · gate condition C-2 and C-4 named RA as the one who files them at delivery, and
> QA-2/CR-6 routed the BC-13 gap to RA · findings F-2 (C-2), F-4 (C-4), QA-2 = CR-6/RES-2`

- **I did not edit `01` myself** — downstream may not edit upstream, and I am a router; the gate's two
  filings went to the document's author.
- **The analyst found a fourth site I had not named**: `FR-4` also read "`sc ipv6 show` … writes
  nothing" — the same over-claim at *requirement* level. It scoped that too and grep-checked the rest.
  BC-11 now uses **QA's** wider measurement, not the narrower "fresh host".
- **QA-2 closed as a boundary correction only, no new FR**, with reasoning I accept: the escape already
  exists and works, so what is missing is a *prompt*, not a capability; a new FR would need a code
  change and a criterion, neither authorised, and a contract line with no implementation behind it is
  the very over-claim NFR-7 exists to prevent.
- **The analyst corrected my dispatch text on the merits.** I had repeated stage 5's and stage 6's line
  that "`sc ipv6 off` repairs it". That is true only in the direction QA measured (host *gained* an
  address). In the **harmful** direction — host *lost* its global address under `auto` — `off` decides
  "suppress" exactly as `auto` already does, so it prints "nothing changed" and repairs nothing; the
  working escapes are `sc reload`, or `sc ipv6 on` then `sc ipv6 auto`. BC-13 now states the general
  rule, true in both directions. **Three stages carried the narrower claim; the fourth caught it.**

- **Intervention check #14 (before stage 7): `.harness/intervention.md` absent.**

## 2026-08-14 — stage 7 delivery close-out

- `07_DELIVERY.md` written; verdict **DELIVERED**. Product diff **5 files, +342 / −21**.
- **Entropy watch: not run, fail-open.** `.harness/scripts/entropy-cadence` **does not exist on this
  host** (neither the `.sh` nor any extensionless form), so the cadence check resolves to NOT-DUE per
  the documented fail-open rule: no supervisor scan, no `## Entropy watch` section, no digest. The
  delivery verdict is unaffected — the cadence is non-blocking by design.
- **Doc-size obligations discharged by hand, all three:**
  - `PM_LOG.md` compacted under rule 70 (517 → 251 lines) at the stage-6→7 boundary, keeping stages 6-7
    full and the measurement block verbatim because five stage docs cite it.
  - `docs/tasks.md` kept under its 300-line F.5 cap (**298**): T-15's and T-14's Completed rows and the
    "T-02 consolidation" note (pure historical rationale, already recorded in that task's archived
    `02_SOLUTION_DESIGN.md` §12) rotated into `docs/tasks-archive.md`, and the template-boilerplate
    `Conventions` / `How tasks relate` sections compressed — **deliberately in preference to displacing
    older *open* rows off the board**, which is where open work belongs.
  - `.harness/insight-index.md`: `archive-task.sh` harvested 7 insights and, exactly as **R-18**
    predicts, did **not** rotate — the index stood at **37 lines** against its 30-line cap. Hand-rotated
    the 7 oldest entries into `docs/features/_archived/insight-history.md`; index back to **30**. That
    is R-18's **fourth** confirmation and it is now filed on the board.
- Open rows filed: **R-23 … R-27** (the measured capability gap, the unprompted stale-document repair
  path, `_load_lang()`'s non-UTF-8 traceback family, the `OverrideError` third-site provenance, and the
  malformed-`settings.json` key loss). T-16's row updated in `docs/tasks.md`; `docs/dev-map.md` was
  updated by stage 4 in the same diff.
- Final gate re-run after archiving and after every rotation: `verify_all` **PASS 17 / WARN 0 / FAIL 0
  / SKIP 1** — the batch baseline, preserved.
- `docs/batches/**` left unstaged: those artifacts belong to the batch loop, not to this task.
