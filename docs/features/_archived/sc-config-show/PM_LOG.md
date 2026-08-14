# PM Log — T-06 / sc-config-show

> Mode: full (1→7). Dispatched by `/harness-batch` on pool `default`.
> Deferred-human mode: standing owner authority granted (「你来决策就行」). `BLOCKED: NEEDS-HUMAN`
> reserved for a genuine safety red line only.

## Task start — 2026-08-14

- Task folder created: `docs/features/sc-config-show/`.
- `.harness/intervention.md`: **absent** (no pending intervention) at task start.
- `.harness/scripts/task-state.js`: **does not exist on this host** → durable-state read/write
  fails open. Stage/round counters tracked in this log instead.
- `.harness/scripts/entropy-cadence`: **does not exist on this host** → delivery-time entropy
  cadence resolves to NOT-DUE (fail-open, non-blocking). No entropy scan, no `## Entropy watch`.
- Partition agents `.harness/agents/dev-*.md`: **none** → single-Developer mode
  (`harness-kit:developer`) at stage 4.
- Board read: `docs/tasks.md` (299 lines, at the 300-line F.5 cap — rotation owed at delivery),
  `docs/batches/default/BATCH_PLAN.md`. T-06 row status `in-progress`.
- Related historical tasks (from board + batch plan): **T-05** `sc-doctor` (config location +
  validation seam, rule-85 "no second opinion"), **T-13** `config-write-permission-hardening`
  (credential bytes, `_write_private()`, 0600-from-creation), **T-14** `config-composition-layer`
  (`CONFIG_BASE` + `_runtime_overlay()` + `override.json`, sha256 drift record at
  `/etc/sing-box/.config.sha256`), **T-15**/**T-16**/**T-17** (overlay consumers), **T-18**
  (R-31: no interactive sudo credential available to any agent here), **T-19** (R-36…R-41).
- `.harness/insight-index.md`: 30 lines, already **at** the F.4 cap → hand-rotation owed at
  delivery (R-18, dead `archive-task.sh` rotation).

## Insights surfaced into dispatch prompts

Carried whole into stage-1/2/4/6 prompts as applicable:

- L10 `_init_files()` hard-codes `/var/lib/sing-box` (dev + QA safety).
- L11 `check-i18n-parity.sh` enumerates keys from the two tables, not call sites (dev).
- L13 `main()` reassigns `LANG` — English renders, zh assertions pass vacuously (dev + QA).
- L18 `Path.read_text()` can raise `UnicodeDecodeError`, a `ValueError` not an `OSError` —
  directly on point for a command whose whole job is reading `config.json` (dev).
- L28 `cmd_status`'s `print()` is block-buffered when stdout is a pipe (dev).
- L30 a fully-repointed fixture is still not isolated from the live service (QA).
- L9 E.6 matches `^##\s+Adversarial\s+tests` — a numbered heading FAILs (QA).
- L19 `git diff --stat`'s bar counts insertions **plus** deletions (PM, delivery).

## Stage 1 — requirement-analyst — dispatched 2026-08-14

Dispatched with the goal sentence marked **suspect** (oldest row in the pool, written 2026-07-31
before T-13…T-19 shipped) and the explicit instruction to re-derive first-hand from current
`bin/sc` and state which clauses survive. R-22 (T-15's lesson) carried: at least one AC must
observe the user-visible outcome.

**Returned round 1, verdict READY.** `01_REQUIREMENT_ANALYSIS.md` + `01_RATIONALE.md` written by
the analyst. No round record owed (round 1).

**All three clauses of the goal sentence were refuted or amended** — the suspicion was warranted,
and this is the fourth consecutive pool task whose goal sentence did not survive contact with the
code:

1. **`sc config --show` — phantom shape.** No `config` subcommand exists; the handlers dict at
   `bin/sc:3183-3192` has 20 entries and none is `config`. There is also **no `parse_args()`
   function at all** — arg parsing is inlined in `main()` at `:3146-3167`, so T-05's constraint is
   real but its anchor is the init block at `:3168-3182`. And `--show` contradicts the project's
   own vocabulary: of 20 commands only two carry a flag, while `show` is a **positional** with
   three precedents (`sc ipv6 show`, `sc telemetry show`, `sc update-interval show`). Ruled
   (Q-1): the command is **`sc config`**, bare — no flag, no positional.
2. **optional `--redact` — default and optionality both overturned (Q-2).** The decisive
   evidence is not in `bin/sc` but in the installer: `install.sh:546-552` writes
   `/etc/sudoers.d/sc` granting the install user `NOPASSWD: /usr/local/bin/sc`, and `bin/sc:117-118`
   re-execs through `sudo` at import. So unredacted output — or any opt-out flag, which carries the
   identical property — would convert a **password-gated** read of a 0600 credential document into
   a **password-free** one for any process running as that user. That is a privilege-boundary
   change caused by the project's own sudoers rule, not merely a scrollback risk, and it reverses
   both T-13's hardening and T-14's digest-never-a-copy precedent. Ruled: **always redacted, no
   opt-out.** Decided under the owner's standing grant; to be surfaced at delivery per policy.
3. **"without root grep" — premise incoherent.** The file is 0600; reading it always
   needs root. `sc` does not bypass root, it *satisfies* it. What the user actually gains: no need
   to know the path, no `sudo cat`, output safe to paste into a bug report, plus one provenance line.

Two further notes worth carrying: the dispatch asked the analyst to enumerate `private_key` /
`pre_shared_key`, and it reported that **neither exists anywhere in `bin/sc`** (only
`tls.reality.public_key:563`, `short_id:566`, `obfs.password:697`) — they can enter the document
only via a user `override.json`, which is precisely why FR-3 is a **fail-closed allow-list** inside
`outbounds` rather than a five-name deny-list. And Q-3 ruled the shown artifact is the **file on
disk** (path self-reported), reusing the existing `_config_digest()` + `.config.sha256` for a
one-line drift state — no diff feature invented.

R-22 satisfied: AC-B1/AC-B2 observe the user-visible outcome directly. AC-B9 is pre-marked
**requires root, expected BLOCKED** (R-31/R-41), so QA files a row rather than substituting an
artifact check.

- `.harness/intervention.md` re-checked after stage 1: **absent**.
- Route: **advance to stage 2**.

## Stage 2 — solution-architect — dispatched 2026-08-14

Dispatched with `01_REQUIREMENT_ANALYSIS.md` as the contract input and rule 85's **"Less is more"**
section (commit `69341b5`) as a binding constraint: the design must name the smaller alternative it
rejected and say what the extra code buys. Single-Developer mode, so no partition-assignment
section is required.

**Returned round 1, verdict READY.** `02_SOLUTION_DESIGN.md` + `02_RATIONALE.md` written. No round
record owed (round 1).

Shape: one command block after `cmd_doctor` (`bin/sc:2616`) — `MASK`, `VISIBLE_IN_OUTBOUND`,
`SECRET_KEYS`, a ~9-line pure `_redact(value, strict)`, a ~20-line `cmd_config()` — plus three
wiring lines in `main()` and four translation keys. No new file, no new import. `MASK = "******"`
(six chars, deliberately under `verify_all` A.1's 8-char threshold). Dispatch is one changed line:
`bin/sc:3177` → `if args.cmd in ("doctor", "config"):`.

**Architect applied ledger row C-10 itself** — two glossary entries in `CONTEXT.md`, a project file
outside the task folder, written at stage 2. Flagged to the gate as an explicit boundary question
to rule on rather than judged here (PM is a router, not an expert).

Residuals travelling: RS-1 (four declined approaches → `.harness/rejected-decisions.md` at
delivery, the T-18/T-19 route), RS-2 (R-25/R-29 inherited, out of scope), RS-5 (insight candidate:
`sys.stderr` became unconditionally line-buffered only in Python 3.9).

- `.harness/intervention.md` re-checked after stage 2: **absent**.
- Route: **advance to stage 3**.

## Stage 3 — gate-reviewer — dispatched and transcribed 2026-08-14

Dispatched with rule 85 in full and the explicit instruction to **test** the architect's
rejected-smaller-alternative answer rather than accept it — specifically the 34-name
`VISIBLE_IN_OUTBOUND`, the `_drift_state()` split, the dispatch change and the user-facing surface —
plus first-hand verification of Q-2's sudoers evidence, an R-22 audit of the AC table, and a ruling
on the C-10 boundary question.

**Returned round 1, verdict `APPROVED FOR DEVELOPMENT`.** Both portions were returned in the final
message under a header naming each path; the body opened with its declared line, ended with its
`## Verdict` line, and neither portion was reported partial — so both were transcribed **verbatim**
to `03_GATE_REVIEW.md` and `03_RATIONALE.md`. Nothing was added, completed or repaired. No round
record owed (round 1).

The gate did the work it was asked to do rather than rubber-stamping:

- **Security ruling upheld on first-hand evidence.** It re-read `install.sh:546-552`,
  `bin/sc:117-118` and `_write_private()` (`:418-458`, `CRED_MODE = 0o600` at `:41`) and confirmed
  the composition Q-2 rests on. It also closed the reverse-risk question: the unredacted document
  stays reachable by `sudo cat`, the password-gated route the sudoers rule does not cover, so no
  legitimate need is left unmet and **no escape hatch is warranted**.
- **The 34 names were re-derived independently** from `bin/sc:519-543`, `:546-567`, `:570-729`,
  `:1788-1811` — 37 distinct emitted names, minus the four credential names, plus `detour` = 34,
  name-for-name identical to I-2. Set is complete and minimal but for that one deliberate addition.
  It then confirmed the 5-name alternative really does cost debuggability (a reality node would
  mask `tls`/`transport`/`flow` wholesale — SNI, ALPN, uTLS fingerprint, ws path, `Host`, gRPC
  service name).
- **The `_drift_state()` split was verified load-bearing**, not a refactor riding along:
  `_warn_drift()` discards the *matches* state at `bin/sc:1892` and no caller can observe it.
- **C-10 ruled within remit (F-5)** on project precedent, *not* an upstream-boundary violation —
  but the audit found a real defect in the wording (**F-4**): the glossary claims pure derivation
  while `detour` is emitted only at `bin/sc:1170`, inside a DNS server, never inside an outbound.

Two MAJOR findings, both discharged by binding conditions rather than rollback:

- **F-1 (R-22 shape, the exact T-15 failure).** AC-B1 and AC-B2 as worded are **both satisfied by an
  all-masked document** — AC-B2 satisfies *better* the more is masked, so the two agree with each
  other on a useless build. **GC-1** binds AC-B1 to V-1's stronger form: the mask appears at exactly
  the fixture's credential positions and nowhere else, counts equal, and an all-masked run is a FAIL.
- **F-2.** V-4's `/var/lib` half is vacuous where that directory already exists (`_init_files()`
  uses `exist_ok=True` on the hard-coded literal at `bin/sc:473`), and the step drives `main()` in
  the one configuration `docs/dev-map.md:141-145` forbids. **GC-2** replaces the primary evidence
  with raisers over `_init_files` / `_resolve_clash_port`.

GC-1…GC-8 bind stages 4/5/6 and are carried into the stage-4 dispatch. No rollback: no finding
changes an interface or a line of `bin/sc`, and F-1/F-6 were resolved under the owner's standing
authority.

- `.harness/intervention.md` re-checked after stage 3: **absent**.
- Stage gate satisfied: explicit PASS verdict present → **advance to stage 4**.

## Stage 4 — developer — dispatched 2026-08-14

Single-Developer mode (`harness-kit:developer`; no `.harness/agents/dev-*.md` on this project).
Dispatched with `01`/`02`/`03` contracts, GC-1…GC-8 and D-1…D-8 carried explicitly, the safety
insights, and the `verify_all.sh` invocation form (no extensionless dispatcher on this host).

**Returned round 1, verdict `READY FOR REVIEW`.** `04_DEVELOPMENT.md` written; no `04_RATIONALE.md`
(no trigger fired). No round record owed (round 1).

- **`verify_all` gate: baseline PASS 17 / WARN 0 / FAIL 0 / SKIP 1 → after PASS 17 / WARN 0 / FAIL 0
  / SKIP 1.** Zero new FAIL, zero new WARN. Stage-5 precondition satisfied.
- Diff (`--numstat`, added lines only): `bin/sc` **+196/−20**, `README.md` +21, `README.zh-CN.md`
  +21, `CONTEXT.md` +14, `docs/dev-map.md` +7/−6, `CHANGELOG.md` +2. `docs/batches/**` untouched by
  the developer (its pre-existing modification belongs to the batch loop and stays unstaged).
- V-1…V-14 all run by the developer; V-15 is the root-on-live-host step and was not run. Reported
  highlights: V-1 masked **exactly 10 positions against 10 fixture credential fields** (GC-1's
  stronger form), V-4 used raisers over `_init_files` / `_resolve_clash_port` as **primary**
  evidence with listings secondary (GC-2), V-11's two independent sweeps confirmed the 34 names are
  derived with `detour` the single added name, V-12 showed `_warn_drift()` byte-identical across
  6 record states × 2 languages (K-14).
- GC-3, GC-4, GC-6, GC-7 (RS-6 recorded, no code bought), GC-8 all reported discharged. GC-1 and
  GC-5 remain QA's to discharge at stage 6.

**New finding worth a pool row — a genuine pre-existing bug, out of this task's scope.** The
developer found while building the fixture that **`parse_tuic()` never stores the password**:
`urlparse().username` stops at the `:`, so `bin/sc:713`'s `if ":" in userinfo:` is always false for
`tuic://uuid:password@host` and every tuic outbound `sc` emits carries `"password": ""`. Not
absorbed (correctly — it is not this task's scope); to be filed as a new open row at delivery.

- `.harness/intervention.md` re-checked after stage 4: **absent**.
- Route: **advance to stage 5**.

## Stage 5 — code-reviewer — dispatched and transcribed 2026-08-14

Dispatched with the 01/02/03/04 contracts, GC-1…GC-8 (GC-3/GC-4/GC-6/GC-8 are stage-5-discharged
per the gate's own table), and the instruction to verify the developer's V-step claims rather than
accept them. Reviewer holds no write capability — it returns the body and the PM transcribes.

**Returned round 1, verdict `APPROVED`.** Both portions returned under a header naming each path;
body opened with its declared line, ended with `## Verdict`, neither reported partial — transcribed
**verbatim** to `05_CODE_REVIEW.md` and `05_RATIONALE.md`. Nothing added or repaired. Round record
(round 1 · first review of stage 4 · no re-review requested · verdict APPROVED) belongs here, not in
the stage doc.

**No CRITICAL, no MAJOR.** Five findings: CR-1 MINOR (a transcription slip in `04_DEVELOPMENT.md`'s
GC-1 evidence — "password x4" where the correct enumeration gives x5; the count 10 is right),
CR-2 MINOR (design gap, owner architect), CR-3 NIT, CR-4 NIT, CR-5 MINOR (the tuic bug, confirmed).

The reviewer was dispatched **without a shell**, and said so rather than papering over it: AC-S2 is
marked "inspected", not "run", and GC-4's "no other glossary wording changed" is explicitly
qualified. In place of `git diff` it used **line-offset arithmetic** — every design-cited pre-edit
line number must differ from the shipped one by exactly the sum of additions above it — and the
chain reconciles to `+196` with no slack, which is the frozen-set negative and the "Less is more"
check made quantitative. GC-3, GC-4, GC-6 and GC-8 (all six sub-items) explicitly discharged.

Notable: it did **not** merely compare `VISIBLE_IN_OUTBOUND` to I-2, it **re-derived** it from the
emitting code, on the grounds that matching the table proves transcription, not correctness — and a
missing name is invisible to every leak test. It also hand-traced `_redact` against the four shapes
that actually occur, including the T-15 `urltest` group: had `outbounds` been omitted from the
visible set the whole auto-select group would have rendered as one `******`.

**CR-5 / RES-4 has a real consequence for stage 6** and is carried into the QA dispatch: because
`parse_tuic()` never stores the password, the tuic credential never reaches disk, so one of GC-1's
ten masked positions can be proved masked **structurally** but not **observationally**. QA must not
report AC-B2 as covering all ten.

- CR-2 (RES-6) is routed to the **architect** by the reviewer, but as a *disposition* rather than a
  change order: BC-14 was worded for stdout alone, K-6 scoped the guard accordingly, so the code is
  faithful and widening the guard is machinery rule 85 does not fund. Filed as a pool row at
  delivery, not a stage-2 rollback. PM concurs with the routing as recorded; no rollback.
- `.harness/intervention.md` re-checked after stage 5: **absent**.
- Route: **advance to stage 6**.

## Stage 6 — qa-tester — dispatched 2026-08-14

Dispatched with the 01/02/03/04/05 contracts; GC-1 (re-derive both counts independently, an
all-masked run is a FAIL), GC-2 (raisers as primary evidence), GC-5 (V-10 under its own id);
RES-1…RES-7 disclosures; AC-B9 pre-marked expected-BLOCKED with a row to file (R-31/R-41); and the
E.6 heading rule (`^##\s+Adversarial\s+tests` — unnumbered).

**Returned round 1, verdict `APPROVED FOR DELIVERY`.** `06_TEST_REPORT.md` (127 lines) +
`06_RATIONALE.md` (500 lines). No round record owed (round 1). `bin/sc` untouched by QA; nothing
committed.

- **GC-1 discharged in the stronger form.** QA built an **independent** reproducer that flattens
  both documents to leaf positions and derives the credential set **structurally from disk**
  (`SECRET_KEYS` anywhere, or `uuid`/`password`/`public_key`/`short_id` under an `outbounds`
  ancestor) rather than from the fixture's own recipe: masked positions in stdout **10**,
  credential positions on disk **10**, equal, unmasked positions differing from disk **0**,
  positions rendered verbatim **187**. **RES-7/CR-1 closed** — the count 10 was right, "password x4"
  was a slip (x5: trojan, ss, hy2, `hy2.obfs.password`, tuic).
- **GC-2 discharged** with raisers over `_init_files`/`_resolve_clash_port` (+19 more) installed
  before `main()`: `PRIMARY raisers fired: 0`, and — the part that makes the negative mean
  something — a **positive control** showing the same sweep on `sc status` gives
  `h.Fired: _init_files`. `/var/lib` reported as secondary and explicitly vacuous. QA then added a
  stronger independent form: CPython **audit hooks**, `total watched events: 0`.
- **GC-5 discharged** (V-10 under its own id, both raiser and audit-hook forms). **GC-7 restated
  and *measured***: under `LC_ALL=C`, a valid document tagged `香港节点` gives `'ascii' codec can't
  decode byte 0xe9`, exit 1, one sentence, no traceback. No code bought.
- **AC-B9 / V-15: BLOCKED, not substituted** — the R-31/R-41 discipline honoured a third time.
- **AC-B2 reported honestly as covering 9 of 10 positions**, exactly as the dispatch required: the
  tuic password is `""` on disk (CR-5), so that position is proved masked structurally, not
  observationally.
- `verify_all`: `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, matching baseline, with A.1, E.6 and F.6 all
  PASS and both new documents in the tree.

**Two new MINOR defects, neither blocking, both routed rather than fixed** (PM decision under the
standing grant — routing back for either would burn a full cycle for zero behaviour change):

- **QA-1 → R-43.** A drift record that exists but is **not a digest** prints "drifted", while BC-13
  says treat it as BC-12. Not fixable inside T-06: V-12 shows `_warn_drift()` at **HEAD** warns
  identically, so changing `_drift_state()` would break K-14, which the gate made binding. The
  *contract* needs correcting, not the code.
- **QA-2 → R-44.** Gate answer **D-2's premise is false on CPython**: `json.loads` uses the C
  scanner, whose depth budget is not the Python recursion limit, so a ~1000-deep document parses
  fine and the pure-Python `_redact` walk overflows. Traceback, exit 1, stdout empty, **no
  credential byte in the traceback**. Unreachable by anything `sc` composes. No cap added — BC-10
  and D-2 both argue against one, and it must not be bought on QA's say-so.

- `.harness/intervention.md` re-checked after stage 6: **absent**.
- Stage gate satisfied: stages 5 and 6 both PASS → **advance to stage 7**.

## Stage 7 — delivery — 2026-08-14

- `07_DELIVERY.md` composed. Verdict **DELIVERED**.
- **Entropy cadence: `.harness/scripts/entropy-cadence` does not exist on this host** → fail-open,
  resolves to **NOT-DUE**. No supervisor scan dispatched, no `## Entropy watch` section, no digest.
  Non-blocking by design; recorded here as the cadence rule requires.
- `.harness/scripts/task-state.js` absent throughout → no durable-state writes; this log is the
  record. Final counters: 7 stages, **0 rollbacks**, 1 round at every stage, longest consecutive
  streak 1.
- `docs/tasks.md`: T-06 row added; **T-19's completed row rotated** to `docs/tasks-archive.md`
  (genuinely closed by shipped work, `71b6d45`). Completed rows were rotated **first**, per policy;
  that alone did not free the space T-06's six new rows needed, so two **still-open** blocks were
  moved after it — T-08's remainder and T-11's R-1…R-8 — each under the archive's existing
  "Still-open rows rotated for space (NOT closed)" convention, with a pointer block left on the
  board naming T-07 as the task that must read them. Board: 299 → **276** lines (F.5 cap 300).
- New rows filed **R-42 … R-47**; R-42 (`parse_tuic()` never stores the password) is the
  highest-impact row this task produced. R-18 confirmed an **eighth** time, R-37 a second time.
- RS-1 discharged: five declined approaches appended to `.harness/rejected-decisions.md` — the
  unredacted/opt-out ruling, the credential deny-list, the 5-name visible key set, textual masking,
  and rendering the would-be composition or a diff.
- `docs/dev-map.md` already updated by the developer at stage 4 (GC-3 verified at stage 5).
