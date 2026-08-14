# PM_LOG — T-17 `telemetry-reject-list`

Mode: **full** (7 stages). Dispatched by `/harness-batch` on pool `default`.
Goal: ship the common-telemetry DNS reject list as an **opt-out overlay on T-14's layer** — after
T-14 and T-16 this should be close to **data plus a toggle, not new machinery**.

## Task start — 2026-08-14

**Durable state.** `.harness/scripts/task-state.js` does **not exist on this host** (`.harness/scripts/`
holds no `task-state.js`; T-16 recorded the same). Treated **fail-open** per the batch dispatch: no
`init`, no `verdict` calls; the stage/round/streak counters this log keeps by hand are the record of
record for the 3-consecutive-rollback rule.

**Intervention check #1** (before stage 1 dispatch): `.harness/intervention.md` **absent** — no pending
intervention.

**Decision authority.** `.harness/rules/25-decision-policy.md` reads **Active mode: 1 (human decides)**.
The batch dispatch carries an explicit standing grant from the owner (「你来决策就行」/「你来逐个把任务
做完」) with `BLOCKED: NEEDS-HUMAN` reserved for a genuine safety red line. I record the tension rather
than resolve it silently: for this run I operate as **Mode-1-with-standing-grant** — judgment calls are
resolved downstream and recorded (rule 25's audit trail), and the rule-25 **red lines** still escalate,
with the single documented exception that red line 2 (outward-facing / push to `main`) is durably
pre-authorized by `.harness/rules/80-delivery-policy.md`.

**Insight index queried** (`.harness/insight-index.md`, 30 lines, all read). Entries surfaced whole into
dispatch prompts, by consumer:
- Safety (dev + QA): `bin/sc` import-time auto-elevate re-execs the **installed** `/usr/local/bin/sc`;
  `_init_files()` hard-codes `/var/lib/sing-box` (index line 12).
- Harness correctness (dev + QA): differential `generate_config()` needs the **same** fixture path
  (`RULES_DIR` is emitted verbatim into `route.rule_set[].path`, line 16); `main()` reassigns `LANG`, so
  setting only `sc.LANG` renders English and Chinese assertions pass vacuously (line 17); use a **clone**,
  never a `git worktree`, for a pristine baseline.
- New strings (dev): `失败：` is a load-bearing diagnostic grep; `TRANSLATIONS` has no `en` table so
  `t()` returns the key verbatim (R-19) — every new key needs readable text in **both** languages.
- DNS mechanism (analyst + architect): lines 24, 25, 26, 27, 30 — no DNS-query-level timeout at any
  level; the rule chain **never falls through on failure** and `dns.final` is the no-rule-matched
  default; `geosite-private` matches the reserved TLD `test`; a `detour` to a bare `direct` outbound is
  fatal at run though it passes `check`; `dig … ANY` uses TCP.
- Verification: `systemctl is-active` cannot detect a restart — use
  `systemctl show -p MainPID -p ActiveEnterTimestamp`.

**Related historical tasks** (read before planning; contracts only, per my T7 trigger list):
- **T-14** `config-composition-layer` — `CONFIG_BASE` + `_runtime_overlay()` + user `override.json`
  through one `_merge()` with five directives (`$replace`/`$prepend`/`$append`/`$before`/`$after`).
  `$before`/`$after` take an **anchor object**, never a numeric index (`bin/sc:1085-1089`) —
  deliberately, "precisely the case two future overlays into `dns.rules` would hit".
- **T-15** `proxy-urltest-group` — first consumer; established the overlay idiom; **declined R-16**.
- **T-16** `dns-resilience` — second consumer, and the second edit to this same array. Its `02` §I-17
  fixes the post-T-16 emitted order: `[0]` suppression · `[1]` `hosts_dns` · `[2]` `clash_mode: Global`
  · `[3]` `clash_mode: Direct` · `[4]` `geosite-google` · `[5]` `geosite-private` · `[6]` domestic
  `domain_suffix` · `[7]` `geosite-cn`. T-16's V-5 deliberately preserved T-17's slot: "the anchor
  `{"clash_mode": "Direct"}` still matches exactly one element, so T-17's slot stays expressible", and
  its out-of-scope disclaims "any opinion about where T-17's rule sits beyond leaving both positions
  expressible (Q-13)". The original field report's constraint — **after `clash_mode`, before the
  routing rules** — therefore lands at index 4.
- **R-23** (T-16's unshipped goal clause) is a *measured capability gap*, not a defect. T-17 must not
  design against a DNS capability T-16 disproved.

**Open row R-16** (merge has no type-mismatch vocabulary; a bare object silently replaces an array)
is unclaimed, owner "whichever of T-15/T-16/T-17/T-21 first needs the vocabulary". T-15 declined it
(D-13 class); T-16 ruled it not-ours on its own reasons (Q-1). **Stage 1 is instructed to rule
explicitly, with reasons, rather than inherit either ruling.**

**Baseline** measured independently after T-16: `verify_all PASS 17 / WARN 0 / FAIL 0 / SKIP 1`.
A FAIL after this task stops the whole batch.

---

## Stage transitions

| # | stage | agent | dispatched | verdict | route |
|---|---|---|---|---|---|
| 1 | 1 · requirement analysis | `harness-kit:requirement-analyst` | 2026-08-14 | **READY** | → probe, then stage 2 |

### Stage 1 — READY (round 1, no rework)

Produced `01_REQUIREMENT_ANALYSIS.md` (286 lines) + `01_RATIONALE.md` (235). FR-1…FR-14, 14 out-of-scope
items, BC-1…BC-18, AC-B1…AC-B7 behavioural + AC-1…AC-21 structural, NFR-1…NFR-10, Q-1…Q-15.
**Intervention check #2**: `.harness/intervention.md` absent.

**Autonomous decisions recorded under the standing grant** (rule 25 audit trail):

**D-1 · Q-6 overrules the field report's stated rule slot — ADVANCED, not escalated, and handed to the
gate.** The field report (carried verbatim in my dispatch) requires the reject rule "after `clash_mode`
and before the routing rules". Stage 1 instead requires it **before both `clash_mode` rules** and after
the predefined-hosts rule. Its reason: `dns.rules` carries two layers — rules that *answer here* and
rules that *choose a resolver* — and `clash_mode` is the second kind, so the report's slot means
`{"server":"remote_dns","clash_mode":"Global"}` (which matches **every** query in `global` mode) is
reached first and the reject rule never runs. That reproduces T-16's defect **shape** one task later:
a privacy setting the user never touched is silently revoked in the mode people switch to when
something is already broken.

*Why I did not escalate.* Rule 25's red line 4 covers a CLAUDE.md red line, a stated "don't", or a
governance rule; a rule-placement suggestion inside a requirement is none of those. The batch dispatch
narrows escalation to "a genuine safety red line", and this is neither safety-critical nor irreversible
— the artifact is regenerated, and `sc telemetry allow` reverses it. My own stage-1 dispatch explicitly
opened the position as "yours to require and to justify", and T-16's Q-13 took no position while its
V-5 kept **both** slots expressible, so no upstream contract is contradicted. The analyst flagged it
as the one candidate point for user confirmation, which is why it is recorded here at length rather
than resolved quietly. **Routing consequence: stage 3 must rule on Q-6 as an explicit, named gate
condition, and it is a delivery-time review-after item.** The cost stage 1 states rather than hides:
mode-switching is *not* an escape hatch for a mis-blocked application — BC-14's two recourses are.

**D-2 · BC-15's measurement obligation is discharged by a PM-commissioned probe, before stage 2, not by
a rollback after it.** BC-15 makes "does real 1.13.15 accept `{"action":"predefined","rcode":"NXDOMAIN"}`
and truly issue no upstream query" a precondition of the design, but the architect holds no shell
(`Read`/`Glob`/`Grep`). T-16 hit this identically: stage 2 returned `BLOCKED ON UPSTREAM` and the PM
commissioned a read-only probe **before** routing the rollback. Doing it up front here saves a round
that is otherwise guaranteed. Probe commissioned read-only under an explicit safety envelope (no
`/etc/sing-box` write, no live-service touch, no `/usr/local/bin/sc` invocation, unprivileged second
sing-box only, `MainPID`+`ActiveEnterTimestamp` witness both sides). It measures: Q-A the `NXDOMAIN`
mechanism incl. a bogus-key control; Q-B the alternatives and which ones *drop* rather than answer;
**Q-C `domain_suffix` label-boundary semantics**, which decide the shipped list's shape and BC-9;
Q-D the `clash_mode` mechanism underlying D-1; Q-E the BC-10 interaction with T-16's rule; Q-F caching.

**Noted for stage 2 as bound obligations** (not re-decided by me): R-16 **declined** with a third
reason neither T-15 nor T-16 gave — R-16's vocabulary would not serve T-17's own user-extension case,
which needs *element addressing* that the documented `"0"`-key boundary denies; so R-16 stays open and
unclaimed with its README obligation intact. No `geosite`/rule-set (Q-3): a DNS rule carrying
`rule_set` is deleted by `_filter_rules` on precisely the degraded host that needs it. Toggle is
`sc telemetry block|allow|show`, default `block`, key never seeded, `on`/`off` deliberately **invalid**
and loud. `show` prints the whole list, so the "opaque blocklist in a generated artifact" anti-pattern
cannot hold.

**Residuals travelling to me for delivery** (outside NFR-3's permitted diff): `CONTEXT.md` wants two
glossary terms (*telemetry reject list*, *reject rule*); `.harness/rejected-decisions.md` wants three
records (`telemetry-list-as-geosite-ruleset`, `telemetry-toggle-as-on-off`,
`telemetry-reject-by-dropping-the-query`).

### Interlude — PM-commissioned read-only measurement probe (between stages 1 and 2)

Not a pipeline stage; commissioned under D-2 to discharge BC-15 before stage 2 rather than after a
rollback. Read-only, scratchpad-only, wrote nothing in the repo. **Live service provably untouched:**
`MainPID=2566751` and `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` identical before and after;
`/etc/sing-box` and `/var/lib/sing-box` mtimes unchanged and both predating the session; every started
process confirmed dead. The probe did **not** import `bin/sc` at all, removing the auto-elevate hazard
rather than neutralising it. Binary: `sing-box 1.13.15`, rev `3708fa18766c`.

**Outcome — BC-15 discharged affirmatively; no rollback to stage 1 needed.**

- **Q-A** `{"action":"predefined","rcode":"NXDOMAIN"}` passes `check` and, at run, returns `NXDOMAIN`
  with `ANSWER: 0`, flags `qr aa rd ra` (**authoritative** denial), in ~4 ms by sing-box's own clock.
  **Neither stub recorded the query** across ~40 rejected probes while controls in the same runs *were*
  recorded — "no upstream query" is **observed**, not inferred. A bogus-key control (`json: unknown
  field`) proves acceptance means the key is real. FR-3 is satisfiable exactly as written.
- **Q-B** Four traps now bound as design constraints: `predefined` + `NXDOMAIN` + a non-empty `answer`
  emits a **self-contradictory** `NXDOMAIN`-with-`ANSWER:1` reply that still passes `check`; `rcode`
  omitted silently defaults to `NOERROR`; `rcode` is **case-sensitive uppercase**; and **the `reject`
  decoder accepts unknown fields** (even a meaningless `rcode`) while `predefined` rejects them — so a
  bogus-key control is valid only on `predefined`. `reject method:"drop"` is the silent-drop shape Q-4
  forbids; bare `reject`/`method:"default"` is REFUSED, not a drop.
- **Q-C** **`domain_suffix` is label-boundary aware in 1.13.15, not a raw character suffix.** A single
  key `domain_suffix:["<name>"]` (no leading dot) satisfies FR-3 **and** BC-9 by itself — matches apex
  and every subdomain, does not match `notexample.com`. The leading-dot form is the *narrower* one and
  would silently leave the apex resolvable. This kills a two-key list as defending against a false
  positive **that does not exist in this binary**.
- **Q-D — D-1 is confirmed by measurement, and the defect is worse than Q-6 argued.** With the rule at
  the field report's slot (after `clash_mode`), a listed name in mode `Global` returned `NOERROR`/1
  record **and the remote stub recorded it**; in mode `Direct`, `NOERROR`/1 and **the direct stub
  recorded it**. Placed before them: `NXDOMAIN`/0/no stub in all three modes. So the report's slot does
  not merely fail to reject — **it leaks the telemetry name to an upstream resolver, in both non-`rule`
  modes**, which is precisely the outcome the feature exists to prevent. D-1 stands on measurement now,
  not on reasoning; the gate still rules on it, but the evidence is no longer contestable.
- **Q-E** BC-10's ordering is a real, observable AAAA behaviour change (T-16-first ⇒ empty `NOERROR`
  for a listed name; reject-first ⇒ uniform `NXDOMAIN`). **Neither ordering leaks.** Handed to stage 2
  as a deliberate semantic call, with FR-11 (T-16 keeps index 0) selecting ordering A by default.
- **Q-F** Partly measured: the denial carries **no SOA** (`AUTHORITY: 0`), so a downstream resolver has
  no MINIMUM from which to derive a negative-cache TTL. **Client-side negative caching was NOT
  measured** — stage 1's Q-5 rationale leans on it. Stage 2 is instructed not to restate it as fact;
  Q-5's *decision* is independently sound on its semantic ground (the rule denies the **name**, not a
  **type**). Possible `01` wording correction flagged **to the gate**, not performed as a rollback.

**New insight candidates from the probe** (carried to delivery): `dig`'s default EDNS COOKIE defeats
sing-box's upstream cache entirely (5 queries → 5 upstream; `+nocookie` → 1); `domain_suffix` is
label-boundary aware; the `reject` decoder accepts unknown fields while `predefined` does not;
`predefined`+`NXDOMAIN`+`answer` is self-contradictory yet valid; `rcode` is case-sensitive uppercase;
a `dig` subprocess costs ~17.5 ms of pure startup, so a 100 ms assertion driven by `dig` really asserts
~82 ms of headroom. T-16's three fixture facts all reproduced cleanly — the fixture is reusable.

| # | stage | agent | dispatched | verdict | route |
|---|---|---|---|---|---|
| 2 | 2 · solution design | `harness-kit:solution-architect` | 2026-08-14 | **READY** | → stage 3 |

## Intervention consumed at 2026-08-14T11:15+08:00

Found at the stage-2 → stage-3 boundary (read point 2). Full content, verbatim:

```markdown
# Intervention

NOTE — Owner restated the design directive on 2026-08-14, with an added clause, and it now governs
every remaining task in this batch:

> 「以少就是多（更少的代码或实现能达到同样的目的），优先用好的设计避免不断的修修补补为原则进行决策」

**Less is more.** Between two designs that satisfy the same stated requirement, take the smaller
one — fewer lines, fewer files, fewer new concepts, fewer moving parts to keep correct later. The
burden of proof is on the larger design: stage 2 must name the smaller alternative it rejected and
say what the extra code buys, and stage 3 must test that answer rather than accept it.

Because the owner has now stated this three times, it has been promoted from a per-task
intervention into the permanent rule: see the new **"Less is more"** section in
`.harness/rules/85-design-discipline.md`. Read the rule, not just this note — it carries the
concrete tests (data over machinery; reuse an existing seam over a parallel one; prefer deleting to
adding; two symptoms with one cause get one fix; a design's true size is its diff plus what every
future reader must hold in their head).

This is a NOTE, not a REDIRECT: nothing already decided in this task is overturned by fiat.
Re-examine the current design against the rule at the next stage boundary and either confirm it
with reasons or shrink it. T-17's goal sentence already says it should "collapse to data plus a
toggle, not new machinery" — that expectation is now backed by a rule.
```

**Keyword: `NOTE`.** Per `.harness/rules/65-intervention.md`'s table (re-read at consumption time,
not from memory): *acknowledge in PM_LOG, attach to next dispatch prompt, continue.* No stage is
overturned, nothing is rolled back, and the note says so itself.

**I read the rule, not just the note.** `.harness/rules/85-design-discipline.md` now carries a
permanent `## Less is more — the tie-break, and the burden of proof` section: prefer data over
machinery, reuse an existing seam over a parallel one, prefer deleting to adding, two symptoms with
one cause get one fix, and count a design's size as its diff **plus** what every future reader must
hold in their head. It explicitly composes with the older clause rather than conflicting: 「避免修修
补补」 forbids band-aids, 「少就是多」 forbids paying for coherence with bulk.

**Action taken:** attached to the stage-3 dispatch, where the rule itself places the duty — "stage 3
must test that answer rather than accept it". The timing is fortunate rather than disruptive: the
next boundary *is* the gate, which already owed a ruling on the "data plus a toggle, not new
machinery" constraint, so the note sharpens an existing gate condition instead of adding a new
process step. `.harness/intervention.md` **deleted** after consumption (staleness would re-apply it).

**One caution I am passing to the gate rather than resolving myself:** stage 2 reports declining two
*larger* alternatives (a `_setting_reader()` factoring and a generalised list-of-names overlay).
That discharges the counter-rule, but the new clause runs the *other* direction — it asks whether a
**smaller** design than the chosen one exists. The gate is asked to test that specific direction,
and I name one candidate for it to rule on rather than deciding it myself (see stage-3 dispatch).

| # | stage | agent | dispatched | verdict | route |
|---|---|---|---|---|---|
| 3 | 3 · gate review | `harness-kit:gate-reviewer` | 2026-08-14 | **APPROVED WITH CONDITIONS** | → stage 4 |
| 4 | 4 · development | `harness-kit:developer` | 2026-08-14 | **READY FOR REVIEW** | → stage 5 |
| 5 | 5 · code review | `harness-kit:code-reviewer` | 2026-08-14 | **APPROVED WITH FINDINGS** | → stage 4 round 2 (CR-1, CR-3) |
| 6 | 4 · development (round 2) | `harness-kit:developer` | 2026-08-14 | **READY FOR REVIEW** | → stage 6 |
| 7 | 6 · QA test | `harness-kit:qa-tester` | 2026-08-14 | _running_ | — |

### Stage 3 — APPROVED WITH CONDITIONS (round 1, no rework)

Round record, verbatim from the reviewer: `round 1 · initial gate review of T-17 · 13 findings, 11
binding conditions, verdict APPROVED WITH CONDITIONS · new: F-2 (published exception anchor vanishes
under allow and breaks sc telemetry allow), F-1/F-4 (V-28 control classifications), F-5 (RS-8 names
vs Q-2's own rule), F-3 (BC-5's no-traceback clause) · GC-2 ruled correct on the evidence but referred
to the owner under Mode 1 red line 4 (C-11).`

**Transcription.** The reviewer holds no write capability. Both returned portions were checked before
anything was written — each begins at its declared opening line, the contract ends at its `## Verdict`
line, both header-named paths carried a portion, and no partial return was reported — then written
**verbatim** to `03_GATE_REVIEW.md` and `03_RATIONALE.md`. Nothing added, nothing repaired; the round
record above stays in this log and out of the stage docs.

**Dimension 6 (boundary handling) came back FAIL** and dimensions 1/4/7 WARN, yet the verdict is an
approval — correctly, because every one is discharged by a text-, document- or fixture-level condition
that changes no interface and no line of `bin/sc`. **No rollback to stage 1 or 2.** I did not soften
this: the FAIL is recorded as the reviewer wrote it.

**The finding that earned the stage — F-2.** The design published `{"rcode": "NXDOMAIN"}` as the
per-name exception anchor, but that element **exists only under `block`**. So a user who follows the
documented recipe and later runs `sc telemetry allow` — BC-14's *first* recourse — hits
`generate_config()` raising `OverrideError`, which `reload_or_restart()` (`sc:1822-1826`) does not
catch. The escape hatch breaks on precisely the host that used the other escape hatch. That is a real
user-facing defect found before a line was written.

**Autonomous decisions recorded (rule 25 audit trail):**

**D-3 · C-4's anchor choice routed to stage 4, not back to stage 2.** The gate explicitly left the
choice open ("Stage 4 (or a stage-2 round, if the PM prefers) picks the anchor") and asserts at least
one qualifying element exists. A stage-2 round would cost a full rework cycle to choose one anchor
inside an already-approved design; the gate approved stage 4 to begin and stage 5 will check the
choice. Routed to stage 4 with the property stated (present in **both** settings states and **every**
rule-set state, ahead of the reject rule's slot) and the choice left to the implementer.

**D-4 · C-3 is a genuine drop authority, and I did not pre-empt it.** Three names ship only on
first-hand corroboration that the host string exists; a *corrected spelling is barred* at stage 4 and
returns to the gate. The gate records its own doubt is strongest on N-7 and expects that check to
fail. I passed that expectation through verbatim rather than softening it — a dropped name is the
designed outcome here, not a failure.

**C-7 and C-11 are mine.** C-7: file the Q-5 negative-caching amendment into **both**
`01_REQUIREMENT_ANALYSIS.md` (Q-5) and `01_RATIONALE.md` (§ Q-4/Q-5) at delivery — the gate caught
that RS-2 named only the contract copy, so amending Q-5 alone would archive the rationale's copy
intact (F-11). C-11: surface the rule-position override to the owner **before delivery**, carrying the
measurement and the gate's recommendation to keep it. **Status: surfaced to the owner in my visible
response at this boundary; not blocking stage 4, per the gate's own scoping.** If no answer arrives by
delivery I ship the override — the owner's *intent* (block telemetry) is served by it, the owner's
stated *mechanism* was measured to leak, the batch dispatch carries a standing decision grant, and the
change is reversible. That disposition is recorded here rather than left implicit.

**The "less is more" test was actually run**, in the direction the new rule specifies. The gate tested
four *smaller* shapes against the file rather than accepting stage 2's account of two *larger* ones:
(0) rule in `CONFIG_BASE` with no overlay — **not expressible**, `DIRECTIVES` has no removal member;
(a) fusing the two DNS overlays — **not expressible**, `_directive_of` raises at `sc:1209` on two `$`
keys in one merge value; (b) inlining `_telemetry_setting()` — **loses**, two consumers and a
before/after comparison would create three derivations of "absent means block"; (c) a shorter list —
the right shrink is "no name the project cannot evidence", which is C-3. Verdict: no smaller design
exists in code, but the design **was** larger than necessary in *published surface* — two anchors, one
of which vanishes — which is F-2. The rule found a real defect on its first application.

### Stage 4 — READY FOR REVIEW (round 1, no rework)

Round record, verbatim: `round 1 · initial implementation of T-17 across bin/sc, both READMEs,
CHANGELOG.md, docs/dev-map.md · conditions C-1…C-6, C-8, C-9, C-10 all discharged at stage 4, with C-4
forcing a documented anchor change (DD-1/DD-2) and C-3 forcing one name dropped (DD-3) · no finding id
(first pass).`

**Intervention check** at this boundary: `.harness/intervention.md` absent.

**Stage gate satisfied and independently re-verified by me, not taken on report.** I re-ran
`bash .harness/scripts/verify_all.sh` myself after the developer finished: **PASS 17 / WARN 0 / FAIL 0
/ SKIP 1** — the batch baseline exactly, no new FAIL and no new WARN. The F.6 doc-size WARN that `02`
V-21 predicted did **not** occur, because the developer put transcripts in `04_RATIONALE.md` and kept
every file under the 500-line cap. Live service witness re-read by me: `MainPID=2566751`,
`ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` — identical to the reading the probe took before
stage 2, so the service has been untouched across the whole pipeline.

**Diff confined to NFR-3's permitted set** (verified by `git diff --numstat`, whose first field is the
added count — not the `--stat` bar, which counts insertions **plus** deletions and would inflate it):
`bin/sc` +219/−2, `README.md` +100, `README.zh-CN.md` +100, `CHANGELOG.md` +2, `docs/dev-map.md` +6/−4.
`docs/tasks.md` carries only my own active-task row; `docs/batches/**` carries only the batch loop's
own edits (T-15/T-16 → done, T-17 → in-progress) and **stays unstaged at delivery** per the dispatch.
`CONTEXT.md`, `.harness/**`, `install.sh`, `uninstall.sh`, `systemd/` all unmodified.

**Two conditions did real work, exactly as the gate predicted:**

- **C-4 changed shipped documentation (DD-1/DD-2).** The developer *measured* F-2 rather than
  reasoning about it: with the old recipe in `override.json`, `sc telemetry allow` exits **1**, and
  the transcript shows the setting line printing *before* the failure — so the host ends up recorded
  `allow` with a `config.json` that was never regenerated. Worse than the gate's static reading. Both
  READMEs now publish `$after {"server": "hosts_dns"}`, verified across 18 combinations including
  HEAD. Because one array takes exactly one directive, the **addition** recipe had to move to the same
  anchor — the only way C-4's required combined single-directive form can exist.
- **C-3 dropped a name (DD-3).** N-7 `telemetry-coverage.mozilla.org` returns `NXDOMAIN` from four
  independent resolvers against a control that resolves. **Precisely where the gate said its doubt was
  strongest.** The spelling was *not* corrected — C-3 bars that at stage 4. **17 names ship**, all four
  FR-2 classes intact. A curated list shipped one name that did not exist, and the pipeline caught it
  by measurement rather than by review.

**C-2 caught a case it did not itself enumerate (DD-5).** Run as AC-B6b writes it, the observation is
**INCONCLUSIVE** — the control agrees instead of reproducing, because at HEAD the name resolves for
the opposite reason. Split into `[A]` and `[D]` halves, both pass. The developer **reported the
bundled inconclusive result** rather than quietly substituting the split — the honest move, and the
same defect class the gate caught as F-4. Final: **30 observations, 30 pass, 0 fail, 0 inconclusive**
(`[D]` 17, `[A]` 13).

**New finding travelling to review and delivery.** C-5's mandated run surfaced a *second* hole nobody
asked about: **`sc telemetry show` also raises** on a non-UTF-8 `settings.json`, because I-3 mandates
`_ipv6_setting()`'s guard tuple verbatim and `UnicodeDecodeError` is a `ValueError`, **not** an
`OSError`. Pre-existing — `sc ipv6 show` fails identically on the same fixture, which is the control
proving it is not a regression — and D-10/C-5 forbid widening the tuple here. Documented in the
function's docstring and filed. This is R-25's family; one `except (OSError, ValueError)` at
`load_settings()` closes it for every reader at once. **Pool row candidate at delivery.**

**DD-4 is the one I am not ruling on myself** and have routed to stage 5: a fifth definition,
`_telemetry_meaning(setting)`, appeared that the design did not name. The developer's argument is that
both `cmd_telemetry()` forms print the meaning sentence, so spelling the conditional twice would be
two definitions of one judgment (rule 85's own test 2). Under the *new* less-is-more clause that
deserves scrutiny rather than acceptance, so stage 5 rules on it explicitly.

### Stage 5 — APPROVED WITH FINDINGS (round 1)

**0 CRITICAL, 0 MAJOR, 5 MINOR, 2 NIT. No rollback.** All five design drifts **upheld**.
**Intervention check** at this boundary: `.harness/intervention.md` absent.

**Transcription.** The reviewer holds no write capability. Both returned portions were checked before
writing — each begins at its declared opening line, the contract ends at its `## Verdict` line, both
header-named paths carried a portion, no partial return — then written **verbatim** to
`05_CODE_REVIEW.md` and `05_RATIONALE.md`. The reviewer wrapped each body in a ```` ```markdown ````
transport fence and declared the fenced content to be the file; the fence is the wrapper, not the
body, so it was not written. Nothing else added, nothing repaired.

**The review did the job stage 5 exists for: it re-derived rather than accepted.** It did not take
DD-1/DD-2 on the developer's measurement — it decomposed the anchor claim into four checkable
propositions and worked the index arithmetic itself, concluding that `$after {"server":"hosts_dns"}`
is not merely adequate but **the unique solution to C-4**: `{"rcode":"NXDOMAIN"}` exists only under
`block`; `{"clash_mode":"Global"}` resolves *after* the shipped rule and so excepts nothing;
`{"action":"predefined"}` matches two elements under `block` and, were it unique, would land ahead of
the hosts rule and break BC-11. That exhausts the candidates. A different reviewer reaching the same
answer by a different route is worth more than the original measurement.

**DD-4 ruled on properly, against the new rule rather than against the developer's argument.** The
reviewer wrote out the one genuinely smaller shape (restructure `cmd_telemetry()` to print once,
~6 fewer lines, zero new definitions) and rejected it on rule 85's own accounting — a design's size
is its diff **plus** what every future reader must hold, and a two-phase branch inside a command that
also persists state and restarts a service is more to hold than a named five-line mapping. Its
sharpest line is that the developer's own defence was *correct but incomplete*: it established the
helper is harmless, not that it is smaller. **`_telemetry_meaning()` stands.**

**Routing decisions (rule 25 audit trail):**

**D-5 · CR-1 + CR-3 routed back to the developer as a tight round 2, not deferred to delivery.** The
reviewer left this to my discretion ("in this round or at delivery"). Both are developer-owned:
CR-1 is `docs/dev-map.md`, a **product** file I have no business editing as PM, and its row is a
guard that currently points at an element no user writes (`{"clash_mode":"Global"}`) while leaving
the one they do write (`{"clash_mode":"Direct"}`, `README*.md:384`, shipped since T-14) unguarded —
the inverse of its purpose. CR-3 is a Summary that reports "0 inconclusive" while AC-B6b *as written*
came back inconclusive; AC-B7/NFR-8 require that fact where the **result** is stated. Deferring CR-3
risks it propagating into `06_TEST_REPORT.md`, which is exactly what the reviewer warned against, so
it is cheaper to fix before QA reads `04` than after. **Rollback count at stage 4: 1** — well clear
of the three-consecutive limit, and this is a reporting/doc round, not a code defect.

**D-6 · sequential, not parallel, with QA.** Round 2 touches `04_DEVELOPMENT.md`, which QA reads.
Running them concurrently risks QA restating the very Summary being corrected.

**Findings that are mine at delivery** (added to C-7's amendment pass): **RES-5/CR-5** — `02`'s I-9
"Published anchors" row and **RS-3's `CONTEXT.md` glossary term** both still name
`{"rcode":"NXDOMAIN"}`; RS-3 is the one residual on this task whose text **escapes the feature folder
into a document every future task reads**, so filing it unamended would write a project-wide glossary
entry that both shipped READMEs contradict. **RES-6/CR-2** — the K-12-forbidden negative-caching
claim also lives in *shipped source* at `bin/sc:1595-1596`, which is T-16's and frozen by K-6/AC-7,
so it is correctly untouched here; C-7's amendment scope covers only `01` and `01_RATIONALE.md` and
must be widened to note it. **RES-9** — AC-B4's count overstates fourfold. **RES-8** — two pool rows.

**Carried to stage 6:** RES-1 (AC-7's freeze must be re-run as an `ast`+byte comparison — stage 5 held
no shell and says so rather than claiming it), RES-2 (every behavioural observation is accepted from
`04_RATIONALE.md`, re-measured by nobody at stage 5), RES-3/CR-4 (AC-B6b's `[D]` half was evidenced
on **5 of 16** names while the criterion says *every* — observe all 16 or state the sample as a
limit, as C-10 required for BC-1), RES-4 (state the inconclusive where the count is stated).

### Stage 4 round 2 — READY FOR REVIEW (rollback 1 at stage 4; streak 1, limit 3)

Round record, verbatim: `round 2 · corrected dev-map's published-anchor guard to
{"server":"hosts_dns"} (three recipes) + {"clash_mode":"Direct"} (README*.md:384), marking
{"clash_mode":"Global"} explicitly not published, and mirrored it into 04's Dev-map updates;
qualified 04's Summary so the AC-B6b-as-written INCONCLUSIVE result is visible where the 30/0/0 count
is stated · the guard named an element no user writes while the one they do write went unguarded, and
the Summary alone told a reader the opposite of what happened · CR-1, CR-3`

**Intervention check** at this boundary: `.harness/intervention.md` absent.

**CR-1 was worse than the review reported, and the developer verified rather than accepted.** Told
that the row named the wrong anchor, it checked first-hand: `grep -n 'clash_mode' README*.md` returns
**four hits, all `Direct`** — `{"clash_mode":"Global"}` appears in **neither README**, existing only
inside `bin/sc` as the shipped overlay's *internal* anchor. And `{"server":"hosts_dns"}` is published
**three** times per README, not the two the row claimed. So the guard was wrong in both directions.
The corrected row now also states explicitly that `{"clash_mode":"Global"}` is *not* published —
changing it breaks only this repo — which is the kind of distinction that stops a future task
guessing. I spot-checked the greps myself: 4 `hosts_dns` hits per README, `clash_mode` only at
`:377`/`:384`, both `Direct`. Confirmed.

**No re-review of round 2.** Both edits are documentation (`docs/dev-map.md`, `04_DEVELOPMENT.md`);
`bin/sc` is byte-untouched this round (`git diff --numstat` still +219/−2). Re-running stage 5 over
two prose corrections would be disproportionate, and stage 6's own documentation checks plus my
delivery verification cover them. Recorded as a decision rather than an omission.

`verify_all` re-run by the developer **and independently by me** after the edits:
**PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — baseline preserved.

**Stage-6 dispatch carries the four residuals as its primary work**, not as footnotes: run AC-7's
freeze as a real `ast`+byte comparison (K-15 forbids `grep` — `timeout=3` is a textual prefix of
`timeout=30`); **rebuild the rig from scratch** rather than trusting stage 4's, which is what caught
defects on T-16; resolve the 5-of-16 sample; and state the inconclusive in the headline. Plus E.6's
**unnumbered** `## Adversarial tests` heading, the full safety envelope, and an instruction to invent
the tests the plan lacks — including a non-vacuity proof that the rig can observe both a *resolved*
and a *rejected* answer, so no green is an artifact of a broken rig.

### Stage 6 — APPROVED FOR DELIVERY (round 1)

**Intervention check** at this boundary: `.harness/intervention.md` absent.

**95 behavioural observations — 93 pass, 0 fail, 2 INCONCLUSIVE** (`[D]` 52 / `[A]` 43). Structural
AC-1…AC-21: 0 failures. **0 BLOCKER / 0 CRITICAL / 0 MAJOR, 5 MINOR.** `verify_all` PASS 17/0/0/1,
E.6 PASS (unnumbered `## Adversarial tests`), F.6 PASS — the predicted WARN never occurred because
QA, like stage 4, put transcripts in the rationale portion.

**All four handed-down residuals discharged, and the stage justified itself on each.** RES-1: the
freeze check had never actually been executed — `ast` slice + sha256 against a pristine clone gives
**25/25 byte-identical**, and QA proved its own comparator non-blind on a 1-space mutant of `_merge`
while demonstrating the K-15 trap (`'timeout=3' in 'timeout=30'` → `True`). RES-2: rig rebuilt from
scratch, stage 4's never imported — and it caught **two defects in QA's own checkers** plus a
classifier mis-encoding, all recorded rather than silently fixed. RES-3: **all 16** other listed
names observed, not the 5-name sample, so no limit needs stating. RES-4: the inconclusive appears in
the headline paragraph, beside the count, and in the AC-B6b row.

**The most creditable thing in the report is the second inconclusive**: an adversarial observation QA
itself **mis-declared** as `[D]` when it is an agreement observation by construction. QA reported it
**as declared** rather than quietly re-classing it to make the sheet green. That is the discipline
NFR-8 exists to produce, applied against its own author.

**QA also invented eight tests the plan lacked** — non-vacuity (the rig sees a resolved *and* a
rejected answer in the same second), BC-9 near-miss, over-match (parent domain, sibling TLD
`hm.baidu.com.cn`, a punycode look-alike), case + 20-label depth, **DNS over TCP**, non-A query types,
BC-11 bootstrap, and a **re-measurement of C-4's own justification** (old anchor `exit=1`, shipped
anchor `exit=0`). Stability: the full matrix run **5×**, 575 probes, **0 keys varied**.

**Five MINOR defects, none blocking.** D-2/D-3/D-4 each carry a **HEAD-side control proving them
pre-existing** — non-atomic `save_settings()` under 10 parallel writers (5/10 vs HEAD's 1/10), a
setting persisted before a failed regeneration, and a non-object `settings.json` raising `TypeError`
out of the settings reader. D-4 **widens R-25 into R-29**: the fix is one guard at `load_settings()`
covering `ValueError` *and* `TypeError` plus an is-a-dict check, closing it for three readers at once
rather than three separate tuples. D-1 and D-5 were mine at delivery.

### Stage 7 — DELIVERED

**Intervention check** before delivery: `.harness/intervention.md` absent.

**Amendments filed by me, per C-7 / RES-5 / RES-9 / D-1 / D-5** — downstream may not edit upstream, so
these were the PM's to apply:
- `01_REQUIREMENT_ANALYSIS.md` **Q-5** and `01_RATIONALE.md` **§Q-4/Q-5** — the unmeasured
  client-side negative-caching claim, amended in **both** copies. F-11's whole point was that RS-2
  named only the contract copy, so amending Q-5 alone would have archived the rationale's copy intact.
- `01` **AC-B4** — "24 combinations per name" corrected to 6 per probe name / 24 in total (RES-9).
- `02_SOLUTION_DESIGN.md` **I-9** and **RS-3** — both still named `{"rcode":"NXDOMAIN"}` as a
  published anchor. RS-3 mattered most: it is the one residual whose text **escapes the feature
  folder into `CONTEXT.md`**, so filing it unamended would have written a project-wide glossary entry
  that both shipped READMEs contradict.
- `04:40` / `05` AC-17 — READMEs are **432** lines, not 433 (D-1); the mirror property itself holds.

**Residuals applied outside the task's permitted diff** (the PM's, by design): `CONTEXT.md` gains the
two glossary terms **with the corrected anchor**; `.harness/rejected-decisions.md` gains four records
(`telemetry-list-as-geosite-ruleset`, `telemetry-toggle-as-on-off`,
`telemetry-reject-by-dropping-the-query`, `telemetry-list-with-a-second-domain-key`).

**R-18 confirmed a FIFTH time.** `archive-task.sh` harvested 8 insights and left the index at **38**
against its 30-line cap — it counts *bullets* while F.4 counts *lines*, so its rotation never fires.
Hand-rotated 8 entries into `docs/features/_archived/insight-history.md`, chosen because a shipped
fix or committed gate now carries them, **not** because they are old.

**`docs/tasks.md` held under its 300-line cap without displacing a single open row**, keeping the
T-15/T-16 preference. Rotated T-16's *completed* row to `docs/tasks-archive.md`, then found two of
T-08's rows **genuinely resolved** and rotated those as closed — verified before rotating, not
assumed: item 1 is the whole subject of delivered T-11, and item 2's "committed parity gate" is now
`verify_all` B.2, which PASSes. 298 lines.

**`.harness/scripts/task-state.js` and `.harness/scripts/entropy-cadence` do not exist on this host.**
Both treated **fail-open** as the dispatch directs and as T-16 did: no counter calls, and the entropy
cadence resolves to **NOT-DUE**, so no scan ran and **no `## Entropy watch` section** was written.
Recorded rather than silently skipped.

**Final:** `verify_all` **PASS 17 / WARN 0 / FAIL 0 / SKIP 1` — baseline preserved, never lowered,
re-run independently by me at three checkpoints. Live service untouched end to end: `MainPID=2566751`
and `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` identical from the pre-stage-2 probe through
delivery. Product diff **5 files, +427/−6**. **1 rollback**, documentation only. `docs/batches/**`
left unstaged for the batch loop.
