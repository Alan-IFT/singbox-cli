# PM Log — T-23 `state-file-io-contract`

Mode: **full** (7 stages). Pool: `followups` (dispatched by `/harness-batch`).
Started: 2026-08-15.

## Task-start checks

| check | result |
|---|---|
| `.harness/intervention.md` | absent at task start — no pending intervention |
| `.harness/agents/dev-*.md` | directory `.harness/agents/` does not exist ⇒ **single-Developer mode** (`harness-kit:developer`) |
| `.harness/scripts/task-state.js` | **does not exist on this host** — fail-open, no durable counters; streaks tracked in this log by hand |
| `.harness/scripts/entropy-cadence` | **does not exist on this host** — fail-open, cadence resolves to NOT-DUE, no entropy sweep, no `## Entropy watch` section |
| `docs/tasks.md` | read; 296 lines, at its 300-line F.5 cap — rotation owed at delivery |
| `.harness/insight-index.md` | read; 30 lines, at its F.4 cap — hand-rotation owed at delivery (R-18, eleventh time) |
| related historical tasks | T-13 `config-write-permission-hardening`, T-14 `config-composition-layer`, T-16 `dns-resilience`, T-17 `telemetry-reject-list`, T-18 `status-egress-via-clash-api`, T-06 `sc-config-show`, T-22 `share-url-userinfo-contract` — all archived under `docs/features/_archived/` |

## Insight-index entries surfaced to downstream stages

Carried whole into the stage-1 and stage-2 dispatch prompts:

- 2026-08-14 · `Path.read_text()` behind any of `bin/sc`'s eight repointable path constants can raise `UnicodeDecodeError`, which is a `ValueError` and **not** an `OSError`, so the repo's habitual `except OSError` lets it through as a traceback — `bin/sc:1712` already guards with `(OSError, ValueError)` while `_load_lang()` at `:312` does not · evidence: dns-resilience
- 2026-08-01 · `main()` reassigns `LANG` from `_load_lang()` after import, so a `bin/sc` harness that sets only `sc.LANG` renders **English** on every `main()`-driven path — Chinese assertions then pass vacuously, because "no newline, no 失败" is also true of English · evidence: config-composition-layer
- 2026-08-01 · `_init_files()` hard-codes `/var/lib/sing-box` as a `Path` literal — the one directory in it not built from a repointable module-level constant — so a redirected-paths harness driving any non-doctor command still writes to the real `/var/lib` · evidence: sc-doctor
- 2026-08-14 · `settings.json` is **0644 on every default install** — `save_settings()` writes it with `write_text()` rather than `_write_private()`, and T-13's installer sweep excludes it by name — so any sentence a tool prints about "files in the configuration directory" is false on 100 % of hosts unless it says *credential* file · evidence: doctor-extended-checks
- 2026-08-15 · `.harness/scripts/verify_all.sh` resolves its checks through **relative** paths, so run from any subdirectory it self-reports `PASS 4 / FAIL 4 / SKIP 10` — a false red that looks like a product regression and is purely the caller's cwd; it must be invoked from the repository root · evidence: share-url-userinfo-contract
- 2026-08-01 · `verify_all` E.6 matches the heading regex `^##\s+Adversarial\s+tests`, so a *numbered* heading such as `## 3. Adversarial tests` makes E.6 FAIL rather than SKIP · evidence: sc-doctor

## Stage transitions

### Stage 1 — requirement-analyst → **READY** (round 1, no rollback)

Wrote `01_REQUIREMENT_ANALYSIS.md` (12 FR / 10 non-goals / 16 BC / 21 AC / 9 NFR / 13 resolved
questions) + `01_RATIONALE.md`. Intervention check before dispatch: **absent**.

**Nine clauses of the handed brief refuted first-hand** — the eighth consecutive pool row where
stage 1 corrected its own dispatch. The load-bearing ones for downstream routing:

1. **R-29's prescribed catch tuple is insufficient.** `_load_lang()` and `_saved_clash_port()` reach
   `.get()` on a non-dict → **`AttributeError`**, which `(OSError, ValueError, TypeError)` does not
   catch. Applied literally, R-29's own fix leaves two of the four readers it names tracebacking.
   The **is-a-dict check**, not the tuple, is what closes the class (Q-1).
2. **R-29's `"telemetry"` example does not raise in one reader — it answers wrongly and silently.**
   `"ipv6" not in "telemetry"` is a legal substring test, so `_ipv6_setting()` returns `auto`
   (BC-3/AC-3). Worse than a traceback and unmentioned upstream.
3. **"Four readers" undercounts by an order of magnitude**: two helper readers + one inline read
   across **22 call sites**, 17 unguarded (Q-12).
4. **"Make T-06's oracle the contract everywhere" is unsafe as written.** `cmd_config`'s good
   sentence exists *because* it does not decode UTF-8; giving it `encoding=` turns a one-sentence
   failure into a `UnicodeEncodeError` on strictly-encoded stdout. `config.json` readers excluded
   (Q-6); new sentences confined to stderr (`backslashreplace`).
5. **R-17's QA refinement and R-62 are both true but in mutually exclusive states** — read-fires-first
   only once a non-ASCII tag is already stored; the fresh-install path lands in the writer.
6. **The fix closes the non-ASCII *credential* population, not the *tag* population** — `#香港节点`
   moves from a decode traceback to an encode traceback on stdout (BC-14, re-homed to T-25, with an
   explicit ban on over-claiming in any changelog).
7. **Two stale anchors**: `_load_lang()` is `:388-392`, not `:312-314`; the insight-index's `:1712`
   model guard now points into a DNS overlay (living instances `:1970`, `:2635`, `:3043`).
8. **Unclaimed extra defect**: `_init_files()` is a **second writer of `settings.json`** (→ FR-12),
   and a `nodes.json` of `{}` gives `KeyError` that an is-a-dict check alone misses (→ FR-3's
   "object with an array `nodes`").

**PM routing decision: ADVANCE to stage 2.** No rollback. The refutations change the design input
rather than invalidating it, and every one is recorded as a binding FR/BC/Q rather than left loose.
Stage-1 streak at this stage: 0 consecutive rollbacks.

### Stage 2 — solution-architect → **READY** (round 1, no rollback)

Wrote `02_SOLUTION_DESIGN.md` (22-row change ledger E-1…E-22, 11 interfaces, 16 constraints K-1…K-16,
23-step verification plan, 8 travelling residuals) + `02_RATIONALE.md`. Intervention check before
dispatch: **absent**.

**The design in one line.** One reader `_read_state(path, default=None, member=None)` whose *unusable*
answer is the file's **existing** `OverrideError` envelope with `.path` set — so `main()`'s **untouched**
`Cannot use {path}: {problem}` arm gives **17 unguarded call sites** FR-6/FR-8 for **zero edits to them**
— plus one `_settings_or_empty(warn=False)` making an unusable `settings.json` mean an *empty settings
document*, from which all four documented defaults fall out. FR-5's once-ness is supplied by `main()`'s
single pre-`LANG` call to `_load_lang()` rather than by a module-level flag.

**Budget: +70 / −43 in `bin/sc`, 46 added code lines** — against NFR-1's `≤ +70 / −30, ≤ 40 code`. Excess
is +6 code and −13 deletion, itemised per edit id and justified in `02_RATIONALE.md` §"Budget excess":
NFR-1's own itemisation models the degrade as "four guard tuples narrowed" and models neither a
warn-once home nor a path-carrying raise, while this design **deletes 12 lines that model keeps** (11 of
them `_telemetry_setting()`'s "THE SILENCE HAS TWO HOLES" docstring, which the change makes false), so
net file growth is 16 lines against the budget's own 19.

**Rule 85 discharged in the required form.** `## Smaller alternative rejected` writes out *three local
hardenings, no new function* (≈+13/−9) in full and **admits it is genuinely correct** for FR-2, FR-4,
FR-10, FR-11, BC-3 (including the `"telemetry"` substring accident) and 12 of the 21 ACs — "not a
strawman: it is what the brief asked for, and half of this design's own diff is literally its item 3."
It is rejected only because it leaves **16 of the 17 unguarded call sites tracebacking** (FR-6, FR-8,
AC-6, AC-8, AC-9) and cannot satisfy AC-18. A **second, nearer** alternative (this design minus the two
helper functions) is also written out and rejected on three counted grounds.

**PM routing decision: ADVANCE to stage 3.** No rollback. The architect raised three upstream notes and
requested no rollback on any; all three are routed to the gate as explicit rulings to make:

| note | what the gate must rule |
|---|---|
| GA-1 | **FR-11 vs out-of-scope item 7 / Q-10.** FR-11's first clause reads onto `save_settings()`, but item 7 excludes `settings.json`'s atomicity. The architect scoped FR-11 to the two sites that already render the sentence and left `save_settings()` unguarded (matching HEAD), filing residual RT-4. If the gate reads FR-11 the other way it is +6 lines and needs budget relief. |
| GA-2 | **AC-13 vs FR-10 for `settings.json`.** HEAD's `save_settings()` escapes to `\uXXXX`; FR-10 requires literal non-ASCII. Byte-identity with HEAD therefore holds only for inputs `sc` itself can author (it can author no non-ASCII settings value). AC-13's fixture set must be built from sc-authored documents (risk R3). |
| GA-3 | **AC-18's count.** The architect counts three decide-sites and states V-18 explicitly so the gate can rule rather than discover: `_resolve_clash_port()`'s FR-7 clause is a fourth `except OverrideError` but decides *not to overwrite*, not what the document means. |

Additionally routed to the gate as the load-bearing design judgment: **reusing `OverrideError` unchanged**
(no rename, no sibling, no `__init__` change) for a document the class is not named for, with the cost to
T-24 stated as RT-1/RT-2 and `_unusable()` existing as a named factory precisely so it is the **single
line** T-24 must move if it re-parents the class.

### Stage 3 — gate-reviewer → **APPROVED WITH CONDITIONS** (round 1, no rollback)

The reviewer holds no write capability. It returned both portions in its final message under headers
naming their target paths. **PM transcription check before writing:** `03_GATE_REVIEW.md`'s body begins
with its declared opening line (`# 03 — Gate Review · T-23 …`), ends with its `## Verdict` line, both
header-named paths carry a portion, and no partial return was reported. Both written **verbatim** —
`03_GATE_REVIEW.md` and `03_RATIONALE.md`. Nothing added, nothing repaired, no round record in either.

**17 findings (3 FAIL / 11 WARN / 3 INFO), 15 binding conditions C-1…C-15, 12 pre-answered developer
questions.** Intervention check before dispatch: **absent**.

**Rule 85 discharged the way T-22's gate discharged it — by reconstruction, not by reading the
architect's account.** The gate rebuilt both rejected designs against `bin/sc` at HEAD and **corrected
the architect in the smaller design's disfavour**: Design A (*three local hardenings*) does **not** in
fact satisfy FR-4/AC-1/AC-2/AC-3 as the architect conceded it did, because `_resolve_clash_port()` is a
**fifth** reader of `settings.json` (`:439`) that Design A never touches and that runs at `:3661` —
**outside `main()`'s try** — so it tracebacks on every one of those fixtures. Design C (the nearer
alternative) was shown to be **~4 lines larger**, because `_settings_or_empty()` pays for its own 8 code
lines by letting four `try/except` blocks be deleted. **Ruling: the chosen design ships, minimal in both
directions.** The architect's headline is off by one — **16** unguarded zero-edit call sites, not 17.

**The load-bearing assumption was verified call site by call site**: all 22 `load_settings()` /
`load_nodes()` sites located, 6 guarded / 16 unguarded, every unguarded one confirmed under `main()`'s
try at `:3673-3674` with no intervening `except` that swallows an `OverrideError`, and the two sites
that run *outside* that try identified as exactly the two E-7/E-8 edit.

**Three FAIL-grade findings, all verification defects — and one is precisely the R-22 trap the dispatch
predicted:**

| id | the defect |
|---|---|
| F-1 | **AC-8 demands of `sc status` an observable correct code cannot produce.** `cmd_status`'s only `load_nodes()` (`:2376`) is behind `if is_running():`, which returns `False` from `:2146` under K-13's own mandated `SYSTEMD = OPENRC = False`. Four of AC-8's twelve runs read no node store on **either** build, so the stated control is false. → C-1 substitutes `sc use 1`. This is the **third** appearance of the `is_running()`-under-a-fixture trap in this project (already in the insight index from `doctor-extended-checks`). |
| F-2 | **AC-3's stated control is unreachable through `main()`** — HEAD's `_load_lang()` raises `AttributeError` first, and the candidate's `auto` is textually identical to HEAD's wrong `auto`. → C-2 names FR-5's warning line as the discriminator. |
| F-3 | **The migration sequence is not shippable as written** — between steps 3 and 4 `_resolve_clash_port()`'s untouched tuple lets the new `OverrideError` escape at `:3661`, outside `main()`'s try, so every non-doctor command tracebacks. → C-3: eight edit ids in one commit. |

**Rulings the PM asked for:** GA-1 upheld (FR-11 does **not** reach `save_settings()`; no budget relief
needed — the ground is verified, not deferred, → C-11). GA-2 legitimate in substance but **wrong in its
stated ground** — `sc` *can* author one non-ASCII settings value (`update_interval`, `:3377`, the only
settings key copied verbatim from `argv`), so AC-13 is narrowed in writing (→ C-5). GA-3 the architect's
reading holds, but is checkable only by enumeration (→ C-10). `OverrideError` reuse **legitimate**, with
the mandatory correction that the class docstring and `main()`'s comment — which K-9 froze and this
change makes false — must be fixed now (→ C-4). I-9's new key **necessary**; NFR-2 amended (→ C-9).

**R-61 honoured rather than repeated**: the gate found NFR-1's `−30` a prediction masquerading as a cap
and **amended it in writing** (C-8: `≤ +76 added, ≤ 48 code`) instead of approving a cap it did not
believe. NFR-2 and NFR-3 amended likewise.

**PM routing decision: ADVANCE to stage 4.** Stage gate satisfied — stage 3 produced an explicit
approval verdict. No rollback; stage-3 streak 0. Single-Developer mode; all 15 conditions carried into
the stage-4 dispatch.

### Stage 4 — developer (single-Developer) → **READY FOR REVIEW** (round 1)

Wrote `04_DEVELOPMENT.md` + `04_RATIONALE.md`. Intervention check before dispatch: **absent**.

**Stage gate before stage 5 checked and satisfied:** `04` reports `verify_all` **PASS 17 / WARN 0 /
FAIL 0 / SKIP 1**, invoked as `bash .harness/scripts/verify_all.sh` **from the repository root**,
before and after — baseline preserved, 0 new failures.

Measured product diff: **`bin/sc` +76 / −51**, of which **46 added lines are code**, 24 comment or
docstring, 6 blank separators — inside C-8's amended cap (`≤ +76 added, ≤ 48 code`), the added figure
exactly at it. Whole worktree: `bin/sc`, `CHANGELOG.md +2`, `CONTEXT.md +9`, `docs/dev-map.md +3/−1`.
**No new file created anywhere** (C-12). `docs/batches/**` was already dirty at stage start and carries
none of the developer's edits — it stays unstaged per the delivery policy.

All **15 gate conditions dispositioned** in `04`'s condition table with evidence. Three design drifts
declared (D-1/D-2/D-3), each pre-authorised: D-1 and D-2 take Q-D's explicitly permitted single-`try`
shape and save 4 lines the C-8 cap needed; D-3 spends terse docstrings because the gate's own C-4 added
3 prose lines *after* the budget was set.

**PM routing decision: ROLLBACK to stages 1 and 2 for a narrow criterion-correction round, in
parallel.** The developer found **three defects in upstream acceptance criteria** and correctly reported
rather than edited them (hard rule 2). Two are the R-22 class this project has now paid for repeatedly,
and one voids a negative control outright:

| # | defect | owning doc |
|---|---|---|
| 1 | **AC-11/AC-12/V-11/V-12 name an environment that is not a non-UTF-8 environment.** Under `LC_ALL=C PYTHONCOERCECLOCALE=0` on Python 3.7+ (this host: 3.12.3), **PEP 540 auto-enables UTF-8 Mode** because `LC_CTYPE` is `C`, so stdout, `getpreferredencoding()` and the filesystem encoding are all UTF-8 — **HEAD passes both criteria unchanged**. The negative control is void and both criteria pass vacuously on broken and fixed code alike. `PYTHONUTF8=0` is required, and `01_RATIONALE.md` already records R-62's own measurement *with* that flag; only the criteria dropped it. | `01` (AC-11, AC-12), `02` (V-11, V-12) |
| 2 | **AC-11's and AC-12's "exits 0" clause is unsatisfiable inside this row's scope.** Under the corrected environment the candidate writes the correct bytes and *then* dies in `cmd_add`'s **own success line** (`bin/sc:2345`, `U+2192` — an sc-authored character, not a node tag) on strictly-encoded stdout. That is BC-14 / RT-3 / T-25. As written the criterion would report FAIL against correct code. | `01` |
| 3 | **AC-8's control is eleven tracebacks and one silently wrong answer, not twelve tracebacks.** `sc now` on a `{}` `nodes.json` exits **0** at HEAD and prints `(none)` (`cmd_now` only does `.get("active")`). The cell still discriminates, but a `06` row asserting "HEAD tracebacks all twelve" would be false. | `01` |

This is exactly the failure mode the dispatch named and that rolled T-22 back twice — a criterion that
cannot detect what it claims. It is caught **before** QA rather than by it, which is the intended
placement. The corrections **narrow criteria to what correct code can produce**; they change no FR, no
design decision and no shipped line, so stage 4's output stands and no re-gate is run — the gate had
already exercised the same amending power in C-1/C-2/C-5/C-6/C-7 under the standing grant, and a
stage-3 re-run would re-adjudicate an approval nothing has disturbed. Recorded here as the PM's call.

**Streaks after this rollback: stage 1 = 1 consecutive, stage 2 = 1 consecutive.** Limit is 3.

### Stage 1 — requirement-analyst, **round 2** → **READY** (criterion correction)

Round record as returned by the analyst: **round 2 · corrected AC-8, AC-11, AC-12 in place · because
stage 4 defects D-1/D-2/D-3 showed three criteria could not detect what they claimed · finding ids
`04_DEVELOPMENT.md` §"Open issues for review" 1-3.**

- **AC-8** — third command is now **`sc use 1`** with its one-line ground (carrying gate C-1's
  phrasing rather than re-inventing it), and the stated HEAD control is now **eleven tracebacks and
  one silently wrong answer**. The `{}` × `sc now` cell was **kept**, not dropped — it is the only
  cell that catches a build reading `active` without checking `nodes`. A report asserting "twelve
  tracebacks" now explicitly fails the row.
- **AC-11 / AC-12** — (a) the environment pins **all three** variables and is a **proved
  precondition**: `sys.stdout.encoding` and `locale.getpreferredencoding(False)` must be asserted to
  be no UTF-8 alias *in the same process* before any other assertion in the row is credited. (b) The
  clauses are **split**: the disk state is owed and verified by this row; the **process exit status**
  is marked **BLOCKED-BY-T-25** — never a pass, never a fail, never dropped.
- `01_RATIONALE.md` — the PEP 538-only ground replaced by stage 4's measurement, plus two
  "candidates considered" bullets recording that *split* beat *drop the exit clause* and that
  *restate the control* beat *narrow the criterion*.

**Confirmed unaltered:** every FR, BC, NFR, Q and the Goal; AC-1…AC-7, AC-9, AC-10, AC-13…AC-21 and
the criteria preamble byte-identical to round 1; no id added, removed or renumbered; gate conditions
C-1/C-2/C-5/C-6/C-7 not contradicted. No file outside `01_*` touched.

### Stage 2 — solution-architect, **round 2** → **READY** (verification-plan correction)

Round record as returned by the architect: **round 2 · corrected V-11, V-12 and RT-3's statement
text · because `PYTHONCOERCECLOCALE=0` disables PEP 538 coercion only while PEP 540 auto-enables
UTF-8 Mode for a `C` `LC_CTYPE`, so the two-variable recipe selected a fully UTF-8 process and both
stated controls were void — both steps would have certified the unfixed build · finding id
`04_DEVELOPMENT.md` §"Open issues for review" 1-2.**

- V-11/V-12 pin all three variables and require the environment assertion as the step's **first
  act**, invoking the plan preamble's existing "inconclusive, never a pass" rule explicitly.
- Each row's observable is split into a **disk clause owed by this row** (with its now-real HEAD
  control — `UnicodeEncodeError` on write, `UnicodeDecodeError` on read) and a **process-exit clause
  marked BLOCKED-BY-T-25** with the `bin/sc:2345` ground.
- **RT-3's statement text amended only** (the row and its `→ T-25` target already existed), carrying
  the two facts T-25 must inherit: the stdout failure is **not confined to user data** (an all-ASCII
  `sc add` still exits non-zero because of the sc-authored arrow), and T-25's own criteria must pin
  all three variables or they verify nothing.

**Confirmed unaltered:** architecture summary, change ledger E-1…E-22, interfaces I-1…I-11,
constraints K-1…K-16, smaller-alternative section, frozen set, migration sequence, out-of-scope,
partition assignment, and V-1…V-10 / V-13…V-23 — all byte-unchanged. The gate's separate
"V-11/V-12 safe as written" finding (the `SB_BIN` stub axis) is untouched and still stands.

### Stage 5 — code-reviewer → **CHANGES REQUESTED (0 CRITICAL, 2 MAJOR)** (round 1)

The reviewer holds no write capability. **PM transcription check before writing:** `05_CODE_REVIEW.md`'s
body begins with its declared opening line, ends with its `## Verdict` line, both header-named paths
carry a portion, no partial return reported. Both written **verbatim** — `05_CODE_REVIEW.md` and
`05_RATIONALE.md`. (Two literal `\uXXXX` escape sequences in the rationale were normalised to rendered
glyphs by the editor on first write and were **restored to the author's literal text**; nothing else
was altered, added or repaired.)

**`bin/sc` is correct as shipped — the reviewer would approve the code as-is. Both MAJORs are in
prose files:**

| id | sev | defect |
|---|---|---|
| CR-1 | MAJOR | `CHANGELOG.md:26` claims `sc add` 「不再报错」 under a non-UTF-8 locale. **False, and BC-14 forbids exactly this claim** — `cmd_add`'s success line (`bin/sc:2345`) prints an sc-authored `U+2192` to a strict stdout and dies there **even for an all-ASCII URL**. The developer's own open issue 2 says so. A user reading it would conclude the fix did not ship, while the node is safely on disk. |
| CR-2 | MAJOR | `docs/dev-map.md:59` still says `_telemetry_setting()`'s guard tuple "inherits the same hole: a non-UTF-8 `settings.json` raises `UnicodeDecodeError`…". E-9/E-10 deleted that tuple and this task closed that hole — **the same diff edited two other rows of this same file**, so it is the diff's own internal inconsistency, in the ledger the next agent reads first. |
| CR-3 | MINOR | `CHANGELOG.md:26` says 「全文只有两处」 read the state files; it is **three** (`_load_lang()`'s inline read, which E-6 deletes). |

**Independent verifications the PM asked for, all confirmed:**

- **C-10 enumerated from the shipped file, not from the developer's list**: exactly three decide-sites
  (`_settings_or_empty():595`, `main():3700`, `_doctor_clash():2791`) plus the permitted write-refusal
  arm (`_resolve_clash_port():436`). `generate_config()`'s two `except OverrideError` are pre-existing
  user-override wrappers enclosing **no** state read — `load_nodes()` sits at `:2042`, *between* them,
  which is what stops a broken node store being mislabelled as the override file. **No fifth guard.**
  D-2's three `isinstance` calls ruled *inside* the reader.
- **C-8 independently reconstructed** edit-id by edit-id (the reviewer has no shell): **+76 / −51, 46
  code** — reproducing the developer's figures on two independent totals. Added is **exactly at** the
  amended cap, code **2 under**. The reconstruction also proves `ensure_ascii=False` at `:578`/`:2104`
  was already at HEAD, i.e. **no unledgered edit**.
- **T-13 survives verbatim** — `mkstemp(dir=…)` → `fchmod` on the still-empty descriptor → write /
  flush / fsync → `os.replace`, `finally` intact; only the `encoding=` keyword and one comment changed
  in the region; credential bytes never exist at a mode wider than `0600` at any instant.
- **T-14 survives verbatim** — `_config_digest()` still hashes `CFG_PATH.open("rb")`, no decode
  anywhere in the drift quartet.
- **K-12's central claim re-verified**: all 16 unguarded call sites listed in the shipped file, none
  acquired a guard.

**A drafted MAJOR was withdrawn on evidence and re-filed as RES-6** — the new `⚠️` stderr line does
*not* traceback under a proved non-UTF-8 locale, because `sys.stderr` carries
`errors="backslashreplace"` while `sys.stdout` is strict. That asymmetry is exactly what T-25 must
inherit or its criteria will verify nothing.

**PM routing decision: ROLLBACK to stage 4 (developer) for CR-1, CR-2, CR-3.** Reviewer-found defects
in files the developer owns → developer fixes them (never the reviewer). All three are one-sentence
prose edits; **no `bin/sc` line changes**, so the C-8 budget and every K-constraint are untouched.
CR-6 needs no action. CR-7 is optional. **CR-4 and CR-5 are deliberately NOT routed to stage 4** —
both are statement-widening, not code, and the reviewer filed them as RES-3/RES-4 travelling to the
`followups` pool; the PM files them as new rows at delivery.

**Streaks: stage 4 = 1 consecutive rollback, stage 5 = 0.** Limit is 3.

### Stage 4 — developer, **round 2** → **READY FOR REVIEW** (three prose edits, no code)

Round record as returned: **round 2 · three prose corrections in `CHANGELOG.md` and `docs/dev-map.md`,
no code · CR-1, CR-2, CR-3 (+ CR-7 taken free).** `verify_all` re-run **twice** from the repository
root: `PASS 17 / WARN 0 / FAIL 0 / SKIP 1` both times. **`git diff --numstat -- bin/sc` still reads
`76 51`** — byte-unchanged, so C-8's measurement and the whole of stage 5's constraint verification
stand without re-opening. `04_DEVELOPMENT.md` corrected **in place**, no round section added; the
`docs/dev-map.md` figure moved `+3/−1` → the **measured** `+5/−4`. CR-4/CR-5 correctly left alone as
RES-3/RES-4, and `02_SOLUTION_DESIGN.md` was not opened.

### Stage 5 — code-reviewer, **round 2** → **APPROVED WITH RESIDUALS**

Round record as returned: **round 2 · verified CR-1, CR-2, CR-3 and CR-7 closed by reading the shipped
files; re-verified `bin/sc` byte-unchanged by re-reading every round-1 anchor at its recorded line
number; carried the round-1 clean list forward; filed one new NIT (CR-8) that does not block.**

**PM transcription check before writing:** body begins with its declared opening line, ends with its
`## Verdict` line, both header-named paths carry a portion, no partial return. Both **replaced**
verbatim — never appended. (Two literal `\uXXXX` escape sequences in the rationale were normalised to
glyphs by the editor and **restored to the author's literal text**; nothing else altered.)

- **CR-1 closed on substance, not by rewording.** The reviewer re-applied its own round-1 test and
  checked the new claim against control flow: `save_nodes()` is at `bin/sc:2343`, **two lines before**
  the failing `U+2192` print at `:2345`, with only `reload_or_restart()` between them — whose
  diagnostics go to stderr and so cannot raise first. The data really is durable when the process
  dies, so the bullet's "already on disk, do not re-add" is true. It also caught that the parenthetical
  attaches 「不再」 to the `UnicodeEncodeError` alone — a looser draft saying 「不再是 `\uXXXX`」 would
  have been **false for `nodes.json`**, where `ensure_ascii=False` was already at HEAD.
- **`bin/sc` byte-unchanged, verified independently** rather than on the developer's word: every
  round-1 anchor re-read at its recorded number, spanning line 352 to the last line of a 3720-line
  file. Any insertion or deletion would have shifted every anchor below it. The one residue — an
  equal-length in-place substitution between anchors — is honestly named and is confined to code the
  diff never touched, since every touched region was re-read in full.
- **CR-8 filed as a new NIT against prose unchanged since round 1**, explicitly labelled *"a correction
  of my own coverage, not a regression by the developer"*, and deliberately given a severity that
  cannot move the verdict. Travels as RES-8, optional.
- **RES-2 sharpened**: the reviewer found the environment-supplied `git status` snapshot in its own
  context **demonstrably stale** (it named `docs/features/proxy-urltest-group/` as untracked, a
  directory since archived) and refused to discharge C-12 with it — insisting the PM run a real one.

### Stage 6 — qa-tester → **APPROVED FOR DELIVERY**

Wrote `06_TEST_REPORT.md` (with the **unnumbered** `## Adversarial tests` heading E.6 requires) and
`06_RATIONALE.md`; appended **operator obligation id 4** to `.harness/operator-obligations.md`.
Intervention check before dispatch: **absent**.

**Tally: PASS 18 / FAIL 0 / BLOCKED 1 / NOT-DISCRIMINATING 1**, plus two clauses BLOCKED-BY-T-25.
≈150 fixture runs; HEAD baseline from a **clone** of `cf164f9` (never a worktree), digest-matched to
`git show HEAD:bin/sc`. `verify_all` `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`.

**QA killed the wrong build, which is the point of the whole R-22 discipline.** `wrongbuild/sc` — the
candidate plus an unconditional `raise _unusable(...)` at the top of the reader — **passes AC-1, AC-2
and AC-3's observables** and is killed by AC-5 and AC-10. The controls are real, not decorative.

It also **refused to inflate a green**: AC-9 is reported **NOT DISCRIMINATING** rather than PASS,
exactly as the gate's C-6 instructed, because HEAD's wider tuple catches the same four causes; E-16
was instead verified by a within-candidate control that collapses doctor's Clash section from four
rows to one. And it **proved C-5's fixture restriction load-bearing** rather than cosmetic.

**Four defects, none requiring a product change**, all routed to the pool: DEF-1 (a criteria gap of
exactly C-1's shape that the gate caught once and missed once — `sc update-interval` is unreachable
under the mandated fixture, and QA substituted nothing rather than driving a live `daemon-reload`),
DEF-2 (RES-4 quantified by measurement), DEF-3 (RT-4 reachable and identical at HEAD, so C-11's ground
holds), DEF-4 (C-2's per-accessor control narrower than it measures).

**Service witness** (`systemctl show -p MainPID -p ActiveEnterTimestamp`, never `is-active`):
`MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` before and after — identical.

**PM routing decision: ADVANCE to stage 7.** Delivery gate satisfied — stage 5 `APPROVED WITH
RESIDUALS` and stage 6 `APPROVED FOR DELIVERY`, both approvals.

### Stage 7 — delivery (PM)

- **PM checkpoint `verify_all`** (fourth independent run): `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`.
- **RES-2 discharged with a real `git status`**: tracked changes are exactly `bin/sc`, `CHANGELOG.md`,
  `CONTEXT.md`, `docs/dev-map.md`, plus `.harness/operator-obligations.md` (QA's obligation id 4) and
  the delivery bookkeeping; `docs/batches/**` was already dirty at task start, carries no stage edit,
  and stays **unstaged** per the batch policy. **No new file outside this task's own documents.**
- **Service witness at delivery**: identical to QA's readings — third concordant measurement.
- **Entropy cadence: fail-open, NOT-DUE.** `.harness/scripts/entropy-cadence` does not exist on this
  host, so per the non-blocking rule the cadence resolves to not-due: **no scan, no `## Entropy watch`
  section, no change to the delivery verdict**. Recorded rather than silently skipped.
- **`task-state.js` absent** — the whole run's counters were tracked by hand in this log.
- **`.harness/insight-index.md` hand-rotated (R-18, twelfth confirmation)**: four entries moved to
  `docs/features/_archived/insight-history.md` with a stated reason each, taking the index 29 → 25 so
  the harvest of four lands at 29 under F.4's 30-line cap. **Selection was by value, not by age** —
  rule 70 says cuts remove what no longer earns its line — so the `LANG` reassignment trap,
  `_init_files()`'s hard-coded `/var/lib/sing-box` and `settings.json`-is-0644 were **kept** despite
  being older than two of the four rotated.
- **`docs/tasks.md` rotated under F.5**: T-22's outcome row moved to `docs/tasks-archive.md` and
  replaced by a one-line summary — **completed rows rotated in preference to displacing open rows**,
  per rule 70's ordering. Two entries fully owned elsewhere (R-15 → T-24, R-18 → T-27) and one now
  closed (R-17) were compressed. Final: **299 lines**, F.5 PASS.
- **Five rows closed explicitly** — R-17, R-25, R-27, R-29, R-62 — each with what the pipeline learned
  that its own row got wrong. **Six new rows filed**, R-64 … R-69; R-69 is addressed to **T-24**, the
  next row in this pool, because T-23 leaves it a second consumer of `OverrideError` and one line to
  move rather than rewrite.

**Verdict: DELIVERED.**
