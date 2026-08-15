# PM Log — T-22 / share-url-userinfo-contract

> Mode: **full** (7 stages). Pool: `followups` (`docs/batches/followups/BATCH_PLAN.md`).
> Invoked by `/harness-batch`. Deferred-human mode: standing decision authority granted by the
> owner (「你来决策就行」); `BLOCKED: NEEDS-HUMAN` reserved for a genuine safety red line.

## Task start — 2026-08-15

- Task folder created: `docs/features/share-url-userinfo-contract/`.
- **Intervention check #0** (before stage 1 dispatch): `.harness/intervention.md` **absent** — no pending message.
- **Durable state**: `.harness/scripts/task-state.js` **does not exist on this host** — fail-open,
  stage/round counters tracked in this log instead. Same for `.harness/scripts/entropy-cadence`
  (absent ⇒ cadence resolves to NOT-DUE, fail-open, no entropy sweep at delivery).
- **Task board read** (`docs/tasks.md`, 278 lines, at its 300-line F.5 cap). Related historical rows:
  - **R-42** (filed by T-06, `sc-config-show`) — `parse_tuic()` has never stored a tuic password;
    owner field reads "next task touching the share-URL parsers" ⇒ **this task**. To be closed here.
  - **R-46** (`SECRET_KEYS` omits inbound TLS key material) — per BATCH_PLAN, carried only if the fix
    touches the credential vocabulary; otherwise left filed.
  - **R-56** (T-07's `uncoverable()` accepts a userinfo authority) — a *different* file
    (`restricted-network-regression.sh`), owned by T-28. Adjacent, not in scope.
  - T-06 (`sc-config-show`) is the archived task that discovered R-42; its stage docs are in
    `docs/features/_archived/sc-config-show/`.
- `docs/dev-map.md` read at 159 lines (dev/test stages touch `bin/sc`).
- **Insight-index query** (terms: userinfo, urlparse, share URL, parser, password, credential,
  fixture, LANG, encoding): 5 entries apply, carried verbatim into dispatch prompts.

## Stage 1 — requirement-analyst — dispatched 2026-08-15

**Verdict: READY.** Contract `01_REQUIREMENT_ANALYSIS.md` (160 lines) + `01_RATIONALE.md` (134 lines).
9 FRs, 12 BCs, 15 ACs, 11 resolved questions, 0 open. No `BLOCKED: NEEDS-HUMAN`.

Routing-relevant outcomes (reasons live in the stage docs, not here):

- **Three goal-sentence clauses refuted at stage 1** — the seventh consecutive pool row where that held.
  (a) "`parse_ss` already does it correctly" is **half false**: it splits raw correctly but
  `bin/sc:732` decodes for **all three arms**, so an ss password recovered from base64 containing a
  literal `%XX` is silently altered — the dispatch's own reference implementation is a member of the
  defect family. (b) "four call sites, three wrong" **undercounts**: five userinfo readers, four wrong
  in some reachable input class once the decode half is counted. (c) `"password": ""` sharpened to
  tuic specifically.
- **Q-1, the storage question — answered: re-add, not regenerate.** Nodes are stored as already-parsed
  dicts (`bin/sc:2295`, `:2301`, `:2308`); the share URL is **never persisted**, so no migration is
  expressible and a broken node is repaired only by `sc rm` + `sc add`. Binds FR-9/AC-12's changelog.
- **Q-2 decode order — split raw, then decode once per field** (in-repo precedent `parse_ss` `:717`/`:732`).
- **Q-3 `parse_vless`** — in the family for decoding, out for splitting; AC-4 pins byte-identity.
- **Q-5 R-46 stays filed** (no credential-vocabulary change; AC-9 pins both frozensets).
- **AC-13 is the only BLOCKED criterion** (real authentication on the live host), with a named
  operator-obligations recipe and no artifact substitution — R-31/R-41/R-47/R-52/R-60 precedent, sixth hold.
- **R-22 answered structurally**: AC-1 is a byte-compare of the emitted document's credential against
  the constant the URL was built from, and **AC-2 is its negative control** (the same procedure must
  *fail* against HEAD, else both are void). AC-14 is explicitly labelled non-regression-only because a
  well-formed document with a wrong credential passes `sing-box check`.
- **R-37 confirmed an eighth time** (Q-9) — recorded, not worked around; owned by T-27.

- **Intervention check #1** (after stage 1, before routing): `.harness/intervention.md` **absent**.
- **Developer mode**: `.harness/agents/` does not exist ⇒ **single-Developer mode**; stage 4 will
  dispatch the plugin agent `harness-kit:developer`.
- **Decision: ADVANCE to stage 2** (solution-architect). No rollback. Consecutive rollbacks at stage 1: 0.

## Stage 2 — solution-architect — dispatched 2026-08-15

**Verdict: READY.** Contract `02_SOLUTION_DESIGN.md` (253 lines) + `02_RATIONALE.md` (169 lines).
No stage-1 conflict; no rollback requested.

- **The one construct**: `_userinfo(authority) -> (whole, first, rest)`, pure, no `urlparse` of its
  own, decoding each returned field exactly once. Five call sites take one line each as a *choice of
  projection* (trojan/hy2 take `whole`, tuic takes `first`/`rest`, vless takes `first`, ss's plaintext
  arm takes `first`/`rest`). Three values rather than two because BC-4 needs `pw:` and `pw`
  distinguishable. **Six readings disappear** (`:637`, `:696`, `:717`, `:732`, `:744`, `:763-768`),
  leaving zero `.username`/`.password` readers — which is the AC-10 static sweep made satisfiable.
- **Rule 85 burden of proof discharged explicitly.** Smaller alternative named and rejected: five local
  fixes, ~6 changed lines, zero new functions — it satisfies FR-2…FR-8 and wins on line count but
  **fails FR-1/AC-10**, so the tie-break does not apply (it settles ties between designs meeting the
  same requirement). Extra ~13 lines buy the removal of the *premise* that caused the bug. Also
  rejected as larger: a per-scheme grammar table, a `mode=`/`whole=True` parameter, a new module.
  **Stage 3 must test this answer, not accept it.**
- **Size budget derived from its own element list** (NFR-2/R-61), not a round number: ≤22 added /
  ≤11 removed across 6 hunks, net ≈ +11.
- **A.1 handled by construction**: every fixture credential ≤7 chars, because `verify_all` A.1's
  `git grep` fires at 8 and `100%2525` is exactly 8.
- **Harness safety bound into the contract** (K-15…K-20): T-13 neutralisation, never `main()` /
  `_init_files()`, all eight path constants repointed **and asserted**, `git clone` baseline (never a
  worktree), **same fixture root for both runs**, stub `SB_BIN`, `SYSTEMD=OPENRC=False`, post-run
  assertions on `sc.LANG` and `sc.CLASH_PORT`.
- Two pre-declared behaviour deltas 01 does not list (**K-8** colonless plaintext `ss://`,
  **K-9** `vless://` with no userinfo) — declared so a reviewer cannot silently "fix" them into guards;
  RT-6 asks stages 5/6 to confirm they are the only two.
- Six residuals travel to delivery (RT-1…RT-6) because `.harness/**` and `CONTEXT.md` sit outside
  NFR-3's permitted diff (T-18/T-19 precedent).

- **Intervention check #2** (after stage 2): `.harness/intervention.md` **absent**.
- **Decision: ADVANCE to stage 3** (gate-reviewer). Consecutive rollbacks at stage 2: 0.

## Stage 3 — gate-reviewer — round 1 — dispatched 2026-08-15

**Verdict: CHANGES REQUESTED.** Transcribed verbatim (I hold the write capability; the reviewer does
not): `03_GATE_REVIEW.md` + `03_RATIONALE.md`. Transcription pre-check passed — body opened with the
declared line `> Contract portion. Rationale: 03_RATIONALE.md (absent = none written).`, ended with
its `## Verdict` line, both header-named paths present, no partial return reported.

**Transcription deviation recorded:** the returned `03_RATIONALE.md` body carries a `## Round record`
section, which a stage document must not hold (round records belong here, in `PM_LOG.md`). No
`SendMessage` capability is available to this PM to correct the same agent's return in place, and the
gate's own verdict already makes round 2 mandatory — at which the document at that path is
**replaced**, not appended to. Removal is bound into the round-2 gate dispatch. Its content, for this
log: *round 1, nothing reworked; GF-1/GF-2 route to requirement-analyst, the `02` mirrors and four
MINOR to solution-architect; no design rework requested.*

**Rule-85 adjudication — the gate tested the architect's answer rather than accepting it, and
approved the larger design first-hand.** It reconstructed the rejected five-site fix line by line,
confirmed it is *correct* on FR-2…FR-9 and every BC (so the rejection could not rest on correctness),
and found it fails **only** FR-1/AC-10 while leaving three idioms, two still resting on `p.username`'s
hidden first-field semantics — the documented cause of this very bug. It then proved the three-value
return minimal in both directions (`whole` unrecoverable from `(first, rest)` for `pw:` vs `pw`;
`(first, rest)` unrecoverable from `whole` after decoding). **No line of the architecture is in
question** — every finding is criterion text or fixture pinning.

**Findings: 2 MAJOR, 7 MINOR, 9 binding conditions (BND-1…BND-9), 7 pre-answered developer questions.**
Both MAJORs are the R-22 trap caught at stage 3 in its sharper form — a criterion that cannot
discriminate, and a promise wider than the behaviour:

- **GF-1 (MAJOR → requirement-analyst, `01` AC-2; mirror in `02` V-2).** AC-2, the pipeline's only
  negative control, demands a HEAD mismatch for the trojan/hy2 `F-b` fixtures — but HEAD emits those
  **correctly** (`a%3Ab` carries no *raw* colon, so `p.username` is the whole userinfo and `unquote`
  gives `a:b`). Unsatisfiable on correct code, and `02`'s edit sequence says a red AC-2 voids the
  harness — so it would send stage 4 hunting a fault that does not exist, whose cheapest exit is to
  weaken the control.
- **GF-2 (MAJOR → requirement-analyst, `01` AC-12; mirror in `02` K-14a).** The changelog damage
  clause is false in three of its four readings: at HEAD an ss password containing a colon, and a
  trojan/hy2/ss-plaintext password containing `%25`, are **correct**. Only tuic (always), trojan/hy2
  with a **raw** colon, and ss whose **base64-recovered** password contains `%XX` are damaged. This
  would tell users in a Chinese user-facing CHANGELOG to re-add nodes that were never broken.
- **GF-3 (MINOR → architect).** A **third** behaviour delta exists (ss plaintext `method` is now
  decoded), acknowledged only in the non-binding rationale; RT-6 itself said a third would mean the
  design is wrong, not the finding. Also tightens AC-3's `%`-free clause to the whole userinfo.
- **GF-4 / GF-8 (MINOR → architect).** Two unlisted routes to a vacuous green: V-6's sweep has no
  colon-splitting pattern (a call site re-splitting a projection passes AC-10), and building fixture
  URLs with a blanket `quote()` (`safe='/'`) silently converts every `F-a` into an `F-b`, greening
  AC-1 against a truncating parser **and** erasing AC-2's red — the two criteria agreeing while
  observing nothing, exactly T-06's stage-3 form.
- **GF-5 (MINOR).** No fixture carries BC-4's `pw:` shape — the one case the three-value return exists
  for — so a two-value implementation passes everything stated. BND-5 pins all three shapes.
- **GF-6, GF-7, GF-9 (MINOR).** Adjudications, not defects: AC-7's bracketed-`server` wording resolved
  in K-4's favour (BND-8, so stage 6 cannot file a false red), K-13's docstring needs one scoping word
  so the shipped file does not contradict its own `:724`, and FR-7's decode half is recorded as
  carried by AC-10 alone rather than believed measured.

**Independently re-verified by the gate against the code (not against the documents):** Q-1's storage
answer (share URL reaches no writer ⇒ re-add, not regenerate); the import-time re-exec at
`bin/sc:124-125` and the sufficiency of the neutralisation; `_init_files()`'s `/var/lib/sing-box`
literal at `:532`; that eight constants is the right number and `restart_service()` is **not** on
`generate_config()`'s path; and A.1's threshold read first-hand from `verify_all.sh:33-34` — 8
characters, tracked files only, `*.md` excluded, so AC-6's `100%2525` and K-15's ≤7 cap reconcile.

- **Intervention check #3** (after stage 3 round 1): `.harness/intervention.md` **absent**.
- **Decision: ROLLBACK 3 → 1** (requirement-analyst owns `01`'s two MAJORs), then 1 → 2 (architect
  owns the `02` mirrors and four MINORs), then re-gate. Per hard rule 2, no downstream agent edits
  `01`. Consecutive rollbacks at stage 3: **1** (limit 3).

## Stage 1′ — requirement-analyst rework — dispatched 2026-08-15

**Verdict: READY.** `01_REQUIREMENT_ANALYSIS.md` corrected **in place** to current state (no round
section inside the document, per the round-record rule). **No gate finding refuted** — every claim was
reproduced first-hand against `bin/sc` and `/usr/lib/python3.12/urllib/parse.py` before being acted on.

Round record (round 2 · what changed · why · finding id):

> corrected AC-2's expected-mismatch set to five tuic + the six trojan/hysteria2 `F-a` fixtures
> (GF-1/BND-1); replaced AC-12's damage clause with four exact predicates plus two explicit non-claims
> and a both-README language clause (GF-2/BND-2); `F-a` now carries all three BC-4 shapes for
> trojan/hysteria2 (GF-5/BND-5); added the explicit fixture-construction rule banning a blanket
> `quote()` (BND-6); AC-3/AC-4 byte-identity corpora widened to "no `%` anywhere in the userinfo" and
> FR-6 now states the ss plaintext `method` decode (BND-3); AC-7 re-worded to unbracketed `server` per
> K-4 (GF-6/BND-8); added **AC-16** + **Q-12** so FR-7's decode half is positively observed (GF-9) ·
> **why:** two MAJOR findings made the pipeline's only negative control unsatisfiable on correct code
> and put a factually false damage claim into a user-facing Chinese CHANGELOG · findings GF-1, GF-2,
> GF-5, GF-6, GF-9, BND-3, BND-6 · no gate finding refuted.

Independently reproduced by the analyst while correcting: all three BC-4 shapes are red at HEAD
(`::`→`""`, `:pw`→`""`, `pw:`→`pw`), `trojan://::@host:443` is parseable (`_check_bracketed_netloc`
runs only when a bracket is present), and all five tuic fixtures are red. Document ~172 lines.

## Stage 2′ — solution-architect rework — dispatched 2026-08-15

**Verdict: READY.** `02_SOLUTION_DESIGN.md` corrected in place (291 lines). **The architecture is
byte-identical to the approved version** — `_userinfo`, the five call sites, CL-1…CL-11, the frozen
set and K-12's ≤22/≤11 budget all unchanged; every edit was verification-plan text, a mirror of a
corrected requirement, or a constraint's wording. NFR-3's product diff still `bin/sc` + `CHANGELOG.md`.

Round record (round 2, condensed — full per-unit list in the architect's return):

> V-2 rewritten to AC-2's enumerated eleven-fixture mismatch set with trojan/hy2 `F-b`…`F-e` stated as
> matching at HEAD **by construction**, and the void condition re-expressed as "a match inside the set,
> or a mismatch outside it" (GF-1/BND-1); edit-sequence step 6's rollback re-scoped so neither symptom
> is ever grounds to change `bin/sc` (GF-1); K-14a restated as the four exact damage predicates plus
> the two non-claims, English gloss rewritten, V-7 now reads it clause by clause (GF-2/BND-2); K-8 now
> carries both ss-plaintext deltas, K-9 relabelled the third, RT-6 says **three**, V-3/V-4 corpora
> tightened, I-6 states the `method` decode (GF-3/BND-3); V-6 split into two pattern groups, group (ii)
> sweeping `partition(':')`/`split(":"`/`rsplit(":"` with five pre-enumerated permitted hits, the range
> anchored on the two banner **comments** rather than line numbers so it survives the diff
> (GF-4/BND-4); new **K-21** per-class explicit fixture text with a blanket `quote()` banned
> (GF-8/BND-6); K-13's no-second-opinion sentence scoped to material taken from **URI text**, K-7
> extended to pin `:715` and `:724` as non-violations (GF-7/BND-7/PQ-3); K-15 rewritten so the ≤7-char
> cap binds only text that could become tracked, K-19 gained a per-run reset rule, K-4 aligned with the
> corrected AC-7, V-5 gained the `vless://a%2Db` fixture (BND-9, PQ-4, PQ-6, BND-8, AC-16/Q-12);
> rationale gained a per-parser delta enumeration, RS-11/RS-12 discharging the gate's dimension-4 WARN,
> and the stale `_runtime_overlay` cite `:1815` → `:1831`.

- **No fourth behaviour delta**, confirmed first-hand per parser against `bin/sc:629-788` — the gate's
  enumeration of three is correct. Two near-misses closed in writing so no later stage files them as a
  fourth: trojan/hy2 have no null-delta (HEAD's `or ""` already absorbs it), and `ss://@h:443` raises
  the same `ValueError` at HEAD, making it an instance of K-8's first delta.
- **The architect corrected one gate finding rather than refuting it** — a downstream stage improving a
  reviewer's fix, the T-07/CR-5 pattern, and the right direction: **BND-4's permitted-hit enumeration
  was short by one.** `bin/sc:715` (`method, password = decoded.split(":", 1)`, the SIP002
  base64-userinfo arm) also survives the change, since CL-6 replaces only the `except` arm. GF-4's
  substance stands entirely; only the count was wrong, so V-6 now enumerates **five** permitted hits —
  otherwise a reviewer applying the sweep would file `:715` as an FR-1 violation. Nothing else in
  `03_GATE_REVIEW.md` refuted; GF-1, GF-2, GF-3, GF-7, GF-8 and PQ-1…PQ-7 all reproduce.

- **Intervention check #4** (after stages 1′/2′): `.harness/intervention.md` **absent**.
- **Decision: ADVANCE to stage 3 round 2** (re-gate). Consecutive rollbacks at stage 3: 1 (limit 3).

## Stage 3 — gate-reviewer — round 2 — dispatched 2026-08-15

**Verdict: APPROVED FOR DEVELOPMENT.** Transcribed verbatim; both portions replaced (not appended),
transcription pre-check passed, and this round's bodies carry **no** round-record section — the round-2
dispatch's binding correction of round 1's deviation took effect.

Round record (round 2):

> gate re-review of the corrected `01` + `02` · all nine round-1 findings verified **discharged against
> the code**, not against the authors' claims (GF-1, GF-2 MAJOR; GF-3…GF-9 MINOR), two with bound
> residuals (GF-7 → BND-7 rescoped, GF-9 → BND-10 added) · **BND-4 corrected in place** from four
> permitted colon-split hits to five · three new MINOR findings raised and **bound rather than
> returned** (GF-10 → BND-12, GF-11 → BND-11, GF-12 → BND-13) · CHANGES REQUESTED → APPROVED FOR
> DEVELOPMENT, **13 binding conditions** carried forward onto stages 4/5/6.

- **The gate re-derived rather than accepted.** It computed HEAD's output for **all nineteen** V-1
  fixtures by hand and confirmed exactly the eleven AC-2 now names are red and the eight are green *by
  construction* — so the pipeline's negative control is now an instrument that correct code passes and
  broken code fails. It likewise re-walked AC-12's damage set class by class (four damaged, three
  correct-at-HEAD) and re-derived the behaviour deltas per parser: **three, no fourth**, with the three
  likeliest hiding places probed and null (`@` in an `ss://` `?plugin=` tail, unencoded `@` in a netloc
  userinfo, an invalid `%zz` escape).
- **The gate sustained the architect's refutation of its own finding, in writing** — the second time
  this project has had a downstream stage correct a reviewer on the merits (T-07/CR-5 precedent).
  BND-4 now enumerates **five** permitted colon-split hits: `bin/sc:715` survives because CL-6 replaces
  only the `except` arm. Had it stood at four, stage 5 would have filed a spurious FR-1 violation
  against correct code.
- **Three new MINORs, each an instrument defect rather than a design defect**, and each bound so a
  third rollback was not spent on wording: **GF-10** (`01` FR-6's "first colon of the *decoded*
  userinfo" contradicts FR-2 for the ss plaintext arm — adjudicated in FR-2's favour, BND-12),
  **GF-11** (V-6's sweep is literal to a spelling: group (i) demands one `netloc` read inside
  `_userinfo` while K-5 *requires* four `p.netloc` reads at the call sites, so run literally it reds a
  compliant implementation, and the tempting fix is exactly what K-5 forbids; group (ii) misses a
  single-quoted `split(':', 1)` — BND-11), **GF-12** (K-12's "exactly six hunks" cannot be a `git diff`
  count for seven change sites, and its element maxima sum to 23 against a ≤22 cap — BND-13 keeps the
  cap and trims the docstring instead).
- **Nothing was smuggled in under a correction**: the rework added exactly one criterion (AC-16) and
  one question (Q-12) and **no code element**; `_userinfo`'s shape, the five call sites, K-12's cap and
  NFR-3's two-file diff are unchanged, so rule 85 was explicitly **not** re-litigated.

- **Intervention check #5** (after stage 3 round 2): `.harness/intervention.md` **absent**.
- **Stage gate satisfied**: stage 3 carries an explicit approval verdict, so stage 4 may start.
- **Decision: ADVANCE to stage 4** (`harness-kit:developer`, single-Developer mode). Consecutive
  rollbacks at stage 3: reset to 0 on approval; 1 spent in total.

## Stage 4 — developer — dispatched 2026-08-15

**Verdict: READY FOR REVIEW.** `04_DEVELOPMENT.md` (196 lines) + `04_RATIONALE.md` (129 lines).
Nothing committed, nothing pushed (delivery-time commit is mine under rule 80).

- **Diffstat** — `bin/sc` **+21 / −11** (inside K-12's ≤22/≤11 per BND-13, docstring at 5 physical
  lines), `CHANGELOG.md` +2, `docs/dev-map.md` +3/−1 (RT-3's `## Reusable utilities` row — a stage-4
  duty outside NFR-3's *product* diff). PM-verified independently: `git diff --stat` = 3 files,
  +25/−12; working tree carries no other modification.
- **The seven change sites render as five `git diff` hunks**, not GF-12's predicted seven: CL-1+CL-2
  and CL-4+CL-7 are ≤6 lines apart and git merges them at default context. BND-13 is satisfied because
  the **cap**, not the hunk count, is the binding number — which is exactly why the gate bound it that
  way rather than pinning a count.
- **AC-1/AC-2 — the negative control landed exactly on its predicted set.** 19 fixtures built,
  **19/19 green on the candidate**, and **exactly 11 red at HEAD** (`t_a t_b t_c t_d t_e j_a1 j_a2 j_a3
  y_a1 y_a2 y_a3`) — BND-1's set fixture-for-fixture, with **no match inside it and no mismatch outside
  it**, so neither void condition fired. 50 fixtures in total across AC-3/AC-4/AC-5…AC-8/AC-16, 0
  failing rows; every `%`-free ss/vless/vmess node byte-identical to HEAD; exactly the three declared
  deltas and no fourth.
- **AC-10 sweep (BND-4 + BND-11) discharged with its command and output quoted in the document.**
  Group (ii) run **quote-agnostically**: exactly **five** hits, exactly the pre-enumerated ones
  (`:636` inside `_userinfo`, `:729` SIP002 arm, `:738` legacy arm, `:734`/`:739` host/port). Group (i):
  four `p.netloc` argument passes plus one application of the last-`@` rule inside `_userinfo(authority)`
  — and **zero `.username` / `.password` readings remain in the entire file**, which is FR-1 made
  observable rather than asserted.
- **Harness safety honoured in full**: built outside the worktree (scratchpad), baseline by **`git
  clone` at `51c0f47`** (never a worktree), same fixture root for both runs, `main()` and
  `_init_files()` never called, `/etc/sing-box` and `/var/lib/sing-box` mtimes unchanged, live service
  untouched.
- **`verify_all`: PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — identical to the developer's own pre-edit
  capture and to the batch baseline measured at the close of the previous pool. **A.1 stayed PASS.**
  Stage-5 gate satisfied.
- **Binding conditions**: BND-2, 4, 6, 7, 9, 10, 11, 12, 13 discharged with evidence (BND-12's order
  named explicitly — the ss plaintext arm splits at the first colon of the **raw** userinfo and decodes
  afterwards, once per field). BND-1, 3, 5, 8 observed by the harness, formal rows left to QA. **None
  left undischarged.**
- **AC-13 remains BLOCKED by construction** with its operator recipe (RT-1); no artifact check
  substituted — the sixth consecutive hold of that discipline. AC-14 not run (stubbed `SB_BIN`,
  non-regression only, as `01` labels it).
- **Insight surfaced for delivery**: `parse_ss`'s SIP002 arm is selected by a `ValueError` from the
  colon split **inside** its `try`, not by base64 validity — `_b64dec` succeeds on ordinary plaintext
  method names, which is why a colonless plaintext userinfo reached HEAD's `except` arm and raised a
  second, uncaught `ValueError` there. Carried to `07_DELIVERY.md` for the insight index.

- **Intervention check #6** (after stage 4): `.harness/intervention.md` **absent**.
- **Decision: ADVANCE to stage 5** (code-reviewer). Consecutive rollbacks at stage 4: 0.

## Stage 5 — code-reviewer — round 1 — dispatched 2026-08-15

**Verdict: APPROVED.** Transcribed verbatim (`05_CODE_REVIEW.md` + `05_RATIONALE.md`); pre-check
passed — declared opening line present, ends with `## Verdict` / `APPROVED`, both header-named paths
returned, no round-record section inside either body.

Round record: *round 1 · first review of T-22 stage 5 · independent re-run of the AC-10 sweep
(ripgrep; this stage holds no shell), independent +21/−11 measurement against the baseline clone at
`51c0f47`, independent per-parser delta re-derivation, independent audit of the uncommitted harness ·
no finding id reopened.*

**0 CRITICAL, 0 MAJOR, 3 MINOR, 3 NIT.** The reviewer re-established everything first-hand rather
than reading stage 4's transcript as evidence:

- **Sweep re-run over the whole file, not just the parser section**: **zero** `.username`/`.password`
  anywhere in `bin/sc`; group (ii) run quote-agnostically gives **exactly five** hits, exactly the
  five BND-4 pre-enumerated, **no sixth**; group (i) four `p.netloc` argument passes plus one
  last-`@` application inside `_userinfo(authority)`. It also added a pattern of its own initiative
  (`@`-boundary readings spelled some other way) — none found. BND-4 + BND-11 discharged.
- **The 5-vs-7 hunk question ruled and explained** rather than waved: git merges sites separated by
  ≤6 unchanged lines at default context, and CL-1↔CL-2 are 3 apart while CL-7↔CL-4 are exactly 6, so
  seven sites render as five **deterministically**. All seven sites present; +21/−11 re-measured
  line-for-line. BND-13 discharged — the cap, not the count, was always the binding number.
- **The negative control was re-derived, not trusted**: the reviewer recomputed all nineteen
  HEAD outcomes by hand and reproduced the same 11, and confirmed the harness implements V-2's void
  condition **in code** (`HARNESS INDICTED (never bin/sc)`), builds expected values from constants,
  contains **zero** `quote(` calls, and asserts ss arm-selection rather than assuming it.
- **No fourth behaviour delta** — now derived independently three times (architect, gate, reviewer).
- **CR-4 records a site neither the gate nor the developer enumerated**: `bin/sc:726`'s
  `body.rsplit("@", 1)` *does* apply the last-`@` rule to URI text, and the shipped docstring survives
  only because CL-6 left its product feeding `_b64dec` alone. True today, and fragile if a future
  change gives that variable a second consumer — captured for the insight index.

**Routing of the three MINORs:**

- **CR-1, CR-2 → QA (stage 6)**, carried as RES-1/RES-2. Both are gaps in what the *harness observes*,
  not in what the code does: no ss fixture puts a `%` in a **plaintext** userinfo (so BC-10's `%3A`
  half, BND-12's own named divergence case for `parse_ss`, and K-8 delta 2 are all taken on trust),
  and AC-3/AC-4 assert on the parsed node rather than the **emitted document** FR-8 speaks about.
- **CR-3 → developer (stage 4′).** The CHANGELOG's tuic clause appends «服务端因此一直认证不过» — a
  claim about live-server authentication that **AC-13, BLOCKED by construction, is precisely the row
  that would establish**. **PM decision under standing authority: route it back rather than accept
  it.** This is the same defect class the pipeline already spent a MAJOR finding on (GF-2): a
  user-facing Chinese sentence, in the one document its audience cannot check, claiming more than was
  measured. The reviewer called it non-blocking and offered a decline-with-a-line option; I am not
  taking that option, because "the inference is very likely true" is exactly the reasoning R-22 exists
  to refuse, and the fix costs one clause. Hard rule 2 makes this the developer's edit, not QA's.

- **Intervention check #7** (after stage 5): `.harness/intervention.md` **absent**.
- **Decision: ROLLBACK 5 → 4 for CR-3 only** (targeted, no re-implementation), then stage 6.
  Consecutive rollbacks at stage 5: **1** (limit 3).

## Stage 4′ — developer — CR-3 targeted round — dispatched 2026-08-15

**Verdict: READY FOR REVIEW.** `CHANGELOG.md` only; `04_DEVELOPMENT.md` corrected in place (199 lines).

Round record:

> round 2 · softened `CHANGELOG.md:26`'s tuic damage clause from 「服务端因此一直认证不过」 to
> 「因此存下来的这个节点手里已经没有它的分享链接带来的那份凭据」, and re-stated BND-2 / AC-12 / CL-8 /
> Design-drift in `04_DEVELOPMENT.md` to match · **why:** the old clause claimed live-server
> authentication behaviour that only AC-13 (BLOCKED by construction) could establish, in the one
> document its audience cannot check — the same defect class as GF-2; the new clause states the
> **measured stored artifact** instead · CR-3 (MINOR).

- **`bin/sc` byte-identical to what the reviewer approved** — `sha256 258472289b264a8588…`, hashed
  before and after the round; `docs/dev-map.md` likewise unchanged (`sha256 3dfcc38a…`).
  `git diff --numstat` still `bin/sc 21/11`, `docs/dev-map.md 2/1`, `CHANGELOG.md 2/0`. NFR-3's
  permitted product diff did not widen.
- **BND-2 re-read clause by clause after the edit**: four damage predicates present, both named
  non-claims still stated *positively as correct-today*, remove-and-re-add repair with its
  `sc reload` **修不好**它 negative and reason intact, Chinese only (no gloss ⇒ no divergence),
  `失败：` still exactly once in the file (the pre-existing `:39` 0.1.0-era entry) and zero times in
  the bullet.
- **`verify_all`: PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, run twice (after the CHANGELOG edit and after
  the doc edits) — matches the batch baseline. F.6 PASS.
- The fixture harness was **not** re-run — nothing it observes changed — and CR-1/CR-2 were correctly
  **not** pre-empted; they are QA's.

**PM routing decision (standing authority): no second code-review round.** CR-3's fix is a single
user-facing CHANGELOG clause, made to the shape the reviewer itself proposed, with `bin/sc` proved
byte-identical by hash — there is no code for a reviewer to re-read. **AC-12 is a QA criterion**, so
the corrected clause gets an independent clause-by-clause read at stage 6 by an agent that has not
seen it before. That is a stronger check than a re-review by its own author's reviewer, and it costs
no extra round.

- **Intervention check #8** (after stage 4′): `.harness/intervention.md` **absent**.
- **Stage-6 gate satisfied**: stage 4 shows `verify_all` PASSED; stage 5 verdict is APPROVED.
- **Decision: ADVANCE to stage 6** (qa-tester). Consecutive rollbacks: 0 at stage 4; the stage-5
  rollback is discharged.

## Stage 6 — qa-tester — dispatched 2026-08-15

**Verdict: APPROVED FOR DELIVERY.** `06_TEST_REPORT.md` (121 lines, `## Adversarial tests` unnumbered
at line 35 — E.6 re-run PASS with the report in place) + `06_RATIONALE.md` (500 lines, carrying RT-5's
full harness listing including the per-class fixture-construction block, for T-28).

**16 criteria PASS / 0 FAIL / 1 BLOCKED** (AC-13, by construction; no artifact check substituted).

- **QA rebuilt rather than inherited.** Fixtures written from `01`'s AC table with credential
  constants **different from stage 4's**, and the negative control still landed on exactly the
  predicted set: 19 built, **11 red at HEAD**, matching BND-1 fixture-for-fixture with no match inside
  the set and no mismatch outside it.
- **The harness was attacked before being trusted (R-22).** Four forbidden implementations were
  driven through the same comparator and **each died on exactly the fixture its condition predicts**:
  `first+":"+rest` rebuild → `pw:`; decode-then-split → `qs_b`/`qx5`; FR-5-applied-to-vless →
  `qv_bnd10`; `p.username` → the three BC-4 shapes. That is the strongest anti-vacuity evidence this
  project has produced.
- **RES-1 and RES-2 closed real gaps and changed no outcome.** The new `ss://a%3Ab:pw@…` fixture is
  now the observed instrument for BC-10's `%3A` half, BND-12 *for `parse_ss`*, and K-8 delta 2 — three
  things previously taken on trust — and it is one of the two fixtures that kills the decode-then-split
  mutant. Every AC-3/AC-4 assertion moved onto the outbound read back from `CFG_PATH` plus
  `generated is True`, so FR-8 is now observed **through the emitted document** for all six schemes.
- **AC-14 answered Q-10 with a measurement, and the answer is the important one**: a real
  `sing-box check` **accepts** `{"password":""}` on a tuic outbound. The row is non-regression only,
  exactly as `01` labelled it — and it is why AC-13 cannot be substituted by anything.
- **No fourth behaviour delta** — a 566-URL sweep with 258 divergences, judged by an **independent
  model oracle** re-implementing FR-2/3/4/5/7 from `01`'s text: `violations: 0` over 528 urlparse-scheme
  URLs, with all 10 `ss://` divergences classifying into the three declared deltas. Fourth
  independent derivation, fourth agreement.
- **`_userinfo`'s totality claim was observed rather than asserted**: 29,726 inputs (NUL, emoji,
  `%zz`, bare `%`, 100k-char strings) → `raised=0`, `invariant violations=0`.
- **Stability**: 10 consecutive full runs, byte-identical result files; `verify_all` ×3 identical.
  Live-host isolation held across ~930 fixture runs — `MainPID=2566751` and `ActiveEnterTimestamp`
  identical before and after, `is-active` never called, `main()`/`_init_files()` never called,
  `sc.LANG`/`sc.CLASH_PORT` asserted after **every** run.
- **`verify_all` PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — second and third independent executions
  (RES-4), matching the batch baseline. `baseline.json` deliberately **not** raised: no committed test
  was added (K-15 keeps the harness out of the worktree; **T-28** owns the suite), and a number no
  committed suite backs would be a false one.
- **New rows**: QA-1 (non-UTF-8 writers raise on a non-ASCII credential — pre-existing, but this
  change makes it *reachable* for shapes that used to be emptied; owner **T-23**) → filed as **R-62**;
  QA-2 (R-37, eleventh confirmation; owner **T-27**) → recorded in the T-22 notes rather than
  duplicated as a row; QA-3 (AC-13's operator recipe) → filed as **operator obligation id 3**.

- **Intervention check #9** (after stage 6): `.harness/intervention.md` **absent**.
- **Stage-7 gate satisfied**: stages 5 and 6 both PASS.
- **Decision: ADVANCE to stage 7** (delivery). Consecutive rollbacks at stage 6: 0.

## Stage 7 — delivery — 2026-08-15

- `07_DELIVERY.md` composed (verdict **DELIVERED**), with three harvested insight lines.
- **Entropy watch: not run, and no `## Entropy watch` section written.**
  `.harness/scripts/entropy-cadence` **does not exist on this host**, so the cadence check resolves to
  **NOT-DUE** under its documented fail-open rule. No scan dispatched, no digest, delivery unchanged.
  Same fail-open applies to `.harness/scripts/task-state.js` (absent all task; stage/round counters
  were tracked in this log instead).
- **Residuals discharged at delivery**: RT-1/RES-5/QA-3 → `.harness/operator-obligations.md` **id 3**
  (with the recipe, and the note that `sing-box check` cannot stand in for it); RT-2 →
  `.harness/rejected-decisions.md` record `share-url-userinfo-five-local-fixes`; RT-3 → `CONTEXT.md`
  glossary term **userinfo reading**; RT-5 → QA's `06_RATIONALE.md` listing, for T-28; RT-4/RES-7 →
  T-27 (R-37). CL-9's dev-map row shipped at stage 4.
- **Board maintenance**: **R-42 marked CLOSED** against the task that discharged it, with the note
  that it *understated* its own class. T-07's Completed row rotated into `docs/tasks-archive.md`
  (genuinely closed by shipped work at commit `99745ac`; its `[VM]` criteria live on as operator
  obligation id 2) to make room within F.5's 300-line cap — `docs/tasks.md` at **296**. New rows
  **R-62** (→ T-23) and **R-63** (→ next task touching `parse_ss`) filed.
- **Insight index hand-rotated before the harvest (R-18, tenth confirmation)** — `archive-task.sh`
  counts *bullets* where F.4 counts *lines*, so its branch cannot fire. Three lines moved to
  `docs/features/_archived/insight-history.md`, each with a stated reason; notably the 2026-08-14
  `urlparse().username` line, **superseded by this task's fix** and false in the present tense if
  kept. Index at **29** lines after the 3-line harvest, F.4 PASS.
- **`guard-rm.sh` spuriously blocked a heredoc a ninth time** ("could not parse nested pwsh command
  safely" on a command containing no `rm`). Worked around by writing content to files and invoking by
  path; `HARNESS_ALLOW_OUTSIDE_RM` was **never** set. Owner remains T-27's caveat about
  plugin-vendored files.
- `archive-task.sh --task share-url-userinfo-contract` run: 3 insights harvested, stage docs moved to
  `docs/features/_archived/share-url-userinfo-contract/`.
- **`verify_all` re-run at the final PM checkpoint: PASS 17 / WARN 0 / FAIL 0 / SKIP 1.**
- Commit + push to `main` on `origin` per `.harness/rules/80-delivery-policy.md` (durably authorized;
  never force-pushed, no history rewrite, no tag). `docs/batches/**` deliberately left untouched and
  unstaged — it belongs to the batch loop.
