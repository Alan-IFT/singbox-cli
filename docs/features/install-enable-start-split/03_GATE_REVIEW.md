# 03 — Gate Review — install-enable-start-split (T-01)

- **Task ID**: T-01
- **Mode**: full (stages 1 → 7) — full-mode verdict vocabulary applies
- **Date**: 2026-07-31 (**rev. 3** — narrow re-gate of the G-1 amendment)
- **Upstream**: `01_REQUIREMENT_ANALYSIS.md` **rev. 2** (`READY`), `02_SOLUTION_DESIGN.md` **rev. 3** (`READY`, 481 lines)
- **Dispatch context**: deferred-human mode (defer, do not ask); read-only, no code edits, no commits
- **Verdict**: `APPROVED WITH CONDITIONS` — **this is a PASS; stage 4 may start.** Conditions in force: **C-1, C-5, C-6, C-7, C-8, C-9** (§9). **C-2, C-3, C-4 are retired.** No FAIL and **no WARN** in any dimension.

> Authored by the gate-reviewer agent (read-only tool set: Read/Glob/Grep); persisted to this path by
> the PM orchestrator verbatim, with no edits to content.

---

## 0. Scope of this revision, and the disposition of every rev-2 condition

| Rev | What changed | Why |
|---|---|---|
| 1 | Reviewed the step-7-only design. `APPROVED WITH CONDITIONS` C-1…C-7. | Original T-01/T-04 split. |
| 2 | Re-review after T-04 was absorbed. Confirmed the five load-bearing decisions; reversed two of its own rev-1 conditions; findings G-1…G-6. `APPROVED WITH CONDITIONS` C-1…C-9. | Owner directive 「优先用好的设计，避免不断的修修补补」. |
| **3 (this document)** | **Narrow re-gate of the G-1 amendment only** (`02` rev. 3: the `INSTALL_LOG`/`LOG_SINK` split, the probe polarity flip, +2 `t()` keys, §4.E layout, §10.2.3). Rewritten in place; rev-2 §1-§8 are superseded, not appended to. **G-1 is closed.** Four new nits G-7…G-10, none routed. | PM routed G-1 to the architect rather than accepting C-2/C-3. |

**Nothing here binds by inertia.** Settled in rev. 2 and *not* reopened: the phase-status model, `INSTALL_OK`'s
retirement, Q2's both-streams capture, the no-`tee` mechanism, Q5, and my own C-5/D-5 reversals.

### 0.1 The one unambiguous condition list for stages 4 and 6

| Rev-2 condition | Disposition in rev. 3 |
|---|---|
| **C-1** (implement §4.A-§4.I verbatim over the working tree; both `t()` branches identical) | **SURVIVES, amended**: the key total is now **40/40**, not 38/38 (§1.4). |
| **C-2** (record the exact text produced when the probe degraded `INSTALL_LOG` to `/dev/null`) | **RETIRED — its subject no longer exists.** No path prints `/dev/null` to a user (§1.2). Nothing left to record; the residual duty ("do not invent behavior") is already C-1 + `02` §12(4b). |
| **C-3** (normalize or restate S11) | **RETIRED.** S11 is satisfiable verbatim as written in `02` rev. 3 §10.2.1; I constructed its expected stdout for all three sub-cases (§2.2). No token normalization is needed, and the row now asserts the *absence* of a `/dev/null` token — a stronger check than the one C-3 would have bought. |
| **C-4** (record how the S1 baseline was built) | **RETIRED.** `02` §10.2.3 supplies the recipe, it is constructible against either HEAD shape, and its pre-assertions fail loudly on mis-extraction (§2.3). The residual duty — record the resolved `HEAD` sha in `06` — is now *design text* (`02` §10.2.3, last sentence) and binds QA there; it needs no separate gate condition. |
| **C-5** (the do-not-build list) | **SURVIVES, extended** by `02` §12(4b): no `INSTALL_LOG` reassignment, no third `LOG_SAVED`-style flag, no predicate function wrapping `[ "$LOG_SINK" = "$INSTALL_LOG" ]`, no re-probe, no `/dev/null` literal in user-facing text. I agree with all five (§4). |
| **C-6** (keep the rev-1 harness fixes F-1/F-2/F-7) | **SURVIVES** — `02` §10.2 still does not restate them. |
| **C-7** (`06` restates §10.3's four coverage limits verbatim; AC-9 unverified/deferred) | **SURVIVES.** All four limits are intact in rev. 3 (§5). |
| **C-8** (`04_DEVELOPMENT.md` rewritten, not appended) | **SURVIVES**, now against **rev. 3** — `04`'s rev-1 claims (`INSTALL_OK`, "no user-facing string added", "exit 0 on both paths") remain false. |
| **C-9** (every stage doc under 500 lines) | **SURVIVES**, and is met today: `01` 404, `02` 481, `04` 274, `05` 364, `PM_LOG` 418, this doc 392. |

---

## 1. What I verified for the amendment

Re-read against the real files this pass, not trusted from `02`: `install.sh:1-20`, `:100-190`, `:210-221`,
`:340-400`; `.harness/rules/85-design-discipline.md` and `70-doc-size.md` in full; `50-singbox-cli.md`
(bilingual / both-init-systems / idempotency clauses); `.harness/insight-index.md`; `01` rev. 2 and `PM_LOG.md`
in full. **`.harness/insight-index.md` is still header-only — no recorded insight contradicts the amendment.**
Rev-2's §1.1 anchor table stands unchanged; only the anchors the amendment touches are re-measured below.

### 1.1 Line anchors and file facts the amendment depends on

| Claim (`02` rev. 3) | Verified? | Evidence |
|---|---|---|
| §4.A appends after `install.sh:16` | **Correct** | `:16` `SB_REPO="SagerNet/sing-box"` is the last constant; `:17` blank. |
| §4.B replaces `:215-216`, trap at `:217` untouched | **Correct** | `:215` `CLEANUP_DIRS=()`, `:216` `cleanup() {…}`, `:217` `trap cleanup EXIT`. |
| §4.C zh insert after `:142`, en after `:174`; `step6_warn` at `:133`/`:165` | **All four correct** | `:142`/`:174` are the last `note_initial)` lines; `:133`/`:165` are the `step6_warn)` lines. |
| §4.E inserts after the blank line `:354`, before `:355` | **Correct, and G-5 is fixed** | `:353` `visudo -c -f …`, `:354` blank, `:355` `# ---------- step 6: rulesets ----------`. The specified layout (blank / block / blank / marker) reproduces the file's rhythm exactly. |
| §4.F replaces `:355-361`; §4.G `:363-386`; §4.H `:388-400` | **All correct** | `:361` `fi`, `:386` `fi`, `:400` `t note_initial` is the file's last line; `:387` blank and untouched. |
| Both `t()` branches hold **29** keys today | **Correct** | zh `:114-142` = 29, en `:146-174` = 29. 29 + 11 = **40**. |
| No new key name collides with an existing one | **Correct** | Existing `step6*` keys are `step6`, `step6_ok`, `step6_warn`; there is no `fail_*` key and no `step6_nolog`. |
| `t()` extraction still terminates correctly | **Correct** | With 11 keys added, `t()` still contains no bare `^}$` before `:183`; `install_report()`'s body contains none at all. |
| §4.D's three `═` separators are byte-identical to the file's | **Correct — re-measured after the rev-3 reflow** | `install.sh` has exactly 4 lines of `^echo "═{55}"$`; `02` has exactly 3 occurrences of `═{55}"` and **zero** of `═{56}`. Copying §4.D verbatim remains safe. |
| No `/dev/null` literal survives in any `t()` string | **Correct** | Grep of `02` for `/dev/null`: it appears only in the §4.A default + comment, the §4.E probe (`2>/dev/null`), prose, the §7 diagram, S9/S11's *absence* assertions, and the §4.I CHANGELOG bullet describing the **old** behavior. None of the 40 keys contains it. |

### 1.2 Does the G-1 fix actually work? — exhaustive path table

`LOG_SINK` has exactly two possible values and exactly one writer (the §4.E probe's `then` list);
`INSTALL_LOG` has one assignment and is never reassigned. I enumerated every reachable combination of
{probe outcome} × {phase outcomes} and derived what the user sees:

| # | Probe | rulesets / config / service | What is said about the log | True? |
|---|---|---|---|---|
| 1 | ok | ok / ok / started | nothing — the success arm never mentions the log | **vacuously true** |
| 2 | failed | ok / ok / started | nothing; stdout byte-identical to #1 | **true** |
| 3 | ok | failed / ok / started | `step6_warn "$INSTALL_LOG"` — "see \<path\> for the cause" | **true** — `update-rules`' stdout+stderr were appended |
| 4 | failed | failed / ok / started | `step6_nolog "$INSTALL_LOG"` — "\<path\> is not writable, the cause was not saved" | **true** — nothing was written anywhere |
| 5 | ok | */ failed / not-started | `fail_config` (+`fail_rulesets`) + `fail_log "$INSTALL_LOG"` | **true** — `sc reload`'s stderr (`bin/sc:555,932`) is in the file |
| 6 | failed | */ failed / not-started | `fail_nolog "$INSTALL_LOG"` — names the real path, denies the save | **true** |
| 7 | ok | */ ok / not-started | `fail_service` + `fail_log "$INSTALL_LOG"` | **true** — the failed launch's stderr is in the file |
| 8 | failed | */ ok / not-started | `fail_service` + `fail_nolog "$INSTALL_LOG"` | **true** |

**No path tells the user anything untrue**, and `/dev/null` never reaches stdout on any path.
`[ "$LOG_SINK" = "$INSTALL_LOG" ]` is an **exact** test of "were this run's diagnostics saved", not a
heuristic, because (i) `LOG_SINK` has two literal values and one writer, (ii) `INSTALL_LOG` is a constant
that is provably not `/dev/null` (statically asserted by `02` §10.2.2's AC-13 grep), so the two values can
never alias. Two residuals, both already named by the design and neither new:

- **R5 (TOCTOU)**: the probe succeeds, then the file stops accepting writes mid-run → #5/#7 overclaim.
  `02` §9 R5 states this explicitly and rejects re-probing (`§12(4b)`). Correctly bounded.
- A failing command that emits nothing would leave only the run marker while #5/#7 say "written to
  \<path\>". Not reachable in practice: `bin/sc:932` always writes a message, and a failed
  `systemctl start` always emits a `Job for …` line. Not a finding.

**The strongest evidence that G-1 is genuinely closed, not merely reworded**: rev. 2's degraded path
printed `/dev/null` and therefore **failed AC-13 literally** (the output would not have contained the
string `/var/log/sing-box/install.log`). Rev. 3 satisfies AC-13, AC-18 and AC-19 on *every* path.

### 1.3 The probe polarity flip, `set -e`/`set -u`/subshell/trap — my own derivation

`if ( umask 027; printf … >>"$INSTALL_LOG" ) 2>/dev/null; then LOG_SINK="$INSTALL_LOG"; fi`

- **Polarity is correct.** The `then` list runs only after the append actually opened, so the sink is
  *promoted on proof* and defaults pessimistic — consistent with `PHASE_*`. Dropping the rev-2 `!` also
  removes the one construct (`! cmd` under errexit) that has surprising interactions outside condition
  position; here it was safe either way, but the simpler form is strictly easier to audit.
- **Failure is silent and non-fatal.** The redirection is evaluated in the forked subshell before
  `printf` runs; the shell's `…: Permission denied` goes to the subshell's stderr, which the `2>/dev/null`
  on the subshell discards. The subshell exits non-zero, the condition is false, there is no `else`, so
  the compound returns **0** and `$?` entering step 6 is 0. ✔
- **No assignment is lost.** The subshell contains a `umask` builtin call and a `printf` — **no
  assignment**. `LOG_SINK="$INSTALL_LOG"` is executed in the parent's `then` list. BC-12 holds. ✔
- **`set -u`.** `install_report()` now reads **six** globals (`PHASE_*`×3, `INIT_SYS`, `INSTALL_LOG`,
  `LOG_SINK`); all six are assigned unconditionally before any read (`§4.A`; `INIT_SYS` at `:55-56`).
  `LOG_SINK` is read at `§4.F`'s `elif` and `§4.D`'s `if`, both after `§4.A`. ✔
- **`pipefail`** still never applies: the amendment introduces no pipeline, no `$( )`, no `&`. ✔
- **The EXIT trap cannot fire inside the probe.** Bash resets caught traps to default in a `( … )`
  subshell, so a failing probe cannot invoke `cleanup` and `rm -rf` the artifact directory mid-install.
  I checked this because `CLEANUP_DIRS` is non-empty on the remote-download path by the time step 5 ends.
  Safe. ✔ (Rev-2's §4.B empty-array guard is unchanged and still correct.)

### 1.4 Key parity — 40/40, verified name-by-name and format-by-format

Both §4.C blocks add the **same 11 names in the same order**: `fail_banner`, `fail_config`,
`fail_service`, `fail_rulesets`, `fail_next`, `fail_rules`, `fail_reload`, `fail_status`, `fail_log`,
**`fail_nolog`**, **`step6_nolog`**. 29 existing + 11 = **40 per branch**, matching `02` §4.C, S14 and
the §Verdict. The two new keys are present in **both** branches — this is the check that matters, since a
one-language key is a hard installer abort under `set -u` (`install.sh:111,181`), not a cosmetic miss.

**Format-specifier safety** (the second abort class — a `%s` with no argument prints garbage, an
argument with no `%s` is silently dropped):

| Key | `%` count | Call site | Args |
|---|---|---|---|
| `fail_status` | one `%s` (both) | §4.D, both `INIT_SYS` arms | 1 |
| `fail_log` | one `%s` (both) | §4.D | 1 |
| `fail_nolog` | one `%s` (both) | §4.D | 1 |
| `step6_warn` (rewritten) | one `%s` (both) | §4.F | 1 |
| `step6_nolog` | one `%s` (both) | §4.F | 1 |
| the other 6 new keys | **zero** `%`, zero backslashes | §4.D | 0 → emitted via the `printf "%s\n"` arm |

Every one of the 11 new keys has exactly one call site, and every key called by `install_report()` exists
in both branches. No dead key, no missing key, no arity mismatch. ✔

### 1.5 B-17 — a logging fault still cannot flip a healthy phase

Confirmed, and it is now structurally easier to see than in rev. 2. `PHASE_*` are written only by
`§4.F`/`§4.G` from the *guarded command's* exit status; `LOG_SINK` and `INSTALL_LOG` are literal
assignments read by nobody in the success test (`§4.D`'s `[ "$PHASE_CONFIG" = "ok" ] && [ "$PHASE_SERVICE"
= "started" ]`). The redirection target is always either `/dev/null` or a path the probe just proved
openable, so `>>"$LOG_SINK"` cannot fail the command it decorates. I also checked the classic half-rename
bug: **all eight redirections in §4.F/§4.G use `$LOG_SINK`**, none was left pointing at `$INSTALL_LOG`;
`$INSTALL_LOG` appears as a redirection target only inside the probe, where it must.

---

## 2. The three conditions the architect asked to retire — adjudicated individually

### 2.1 C-2 — **retired.** Its subject is gone

C-2 existed to force the developer to write down a dishonest string so the owner could see it. §1.2 shows
no such string is produced on any path. Retiring it removes a duty that would otherwise be discharged with
"n/a", which is worse than no duty. The behavior it guarded against ("do not silently invent a different
message") is fully covered by C-1 (verbatim §4) plus `02` §12(4b).

### 2.2 C-3 — **retired.** S11 is satisfiable verbatim; I built its expected output

The row's three sub-cases, derived from §4.D/§4.F rather than from the row's prose:

- **S1 degraded** — the success arm names no log at all → stdout **byte-identical** to the writable twin.
  Satisfiable as written.
- **S2 degraded** — one line differs: `fail_log "<LOG_PATH>"` → `fail_nolog "<LOG_PATH>"`. Both contain
  `$LOG_PATH`; the row says exactly this.
- **S10 degraded** — **two** lines differ (`step6_warn`→`step6_nolog` and `fail_log`→`fail_nolog`); the
  row's "likewise, **and** its step-6 line is …" covers both. No third line moves.

The `PHASES …`/exit-status equality across twins follows from §1.5, and `stderr free of Permission denied`
follows from the probe's `2>/dev/null` (§1.3). The added assertion "**stdout contains no `/dev/null`
token**" is exactly the right verbatim expression of C-3's intent and is stronger than the normalization
C-3 would have bought. **C-3 is discharged, not merely satisfied.**

### 2.3 C-4 — **retired.** §10.2.3's recipe is constructible and fails loudly

I traced it against the real repo:

- `grep -qE '^# -+ step 6: rulesets -+$'` **matches** `install.sh:355` (`# ` + 17 dashes + ` step 6:
  rulesets ` + 17 dashes). The two negative pre-assertions can only match once rev. 2/3 is committed,
  which this dispatch forbids — so they are a genuine tripwire against building a baseline from the *new*
  file, which is the one mis-extraction that could produce a false green.
- **HEAD-shape-agnostic: confirmed.** The working tree is clean at HEAD, so HEAD already carries the rev-1
  step-7 block; the recipe also works against a pre-rev-1 HEAD. In both shapes the success-path **stdout**
  is the same (`t step7` + the 13-line banner), because the stub is silent on success — the design states
  that precondition explicitly, and it is the load-bearing one. `INSTALL_OK` is assigned inside the
  baseline's own tail, so no `status.sh` is needed; the baseline tail ends at `t note_initial` with no
  `exit`, so the driver exits 0. Both true of the file on disk.
- **`set -e` interaction**: `grep -q … && exit 1` / `grep -q … || exit 1` are AND/OR lists in which the
  `grep` is not the final command, so a "good" (non-matching) grep cannot trip errexit. ✔
- **Failure mode is loud**: any mis-extraction yields a non-empty `diff`, i.e. a red S1 — it cannot
  silently pass. Nit G-9 below.

---

## 3. D-9 — the requirement reading. **Sound, and correctly placed in `02` rather than `01`**

D-9's proceeding assumption is: having named the real path, **deny** (truthfully) that this run's
diagnostics were saved there. I checked it against `01` rev. 2 clause by clause:

- **B-15(iii)** requires the failure output to print the literal path. `fail_nolog` prints it. ✔
- **B-14** requires the step-6 warning to name the path and drop the speculative cause. `step6_nolog`
  names it and asserts nothing speculative. ✔
- **B-17** requires the installer to "still print the correct banner per B-15". The architect reads
  "correct" as *keeps B-15's structure and stays true*. This is the only reading available: the
  alternative ("repeat a sentence that has become false") makes B-17 self-contradictory with §1's goal.
- **AC-13 / AC-18 / AC-19** are all satisfiable on the degraded path under this reading, and AC-13 was
  **not** satisfiable under rev. 2's. That settles it: the assumption is not merely defensible, it is the
  only one consistent with the acceptance criteria as written.

**No requirement change is needed, so no route to the requirement-analyst.** The reversal cost is real and
small, and the owner can still object — see H-1. One inaccuracy in how the cost is stated is recorded as
G-7.

---

## 4. Over-build check — **I agree with both declines**

- **No third `LOG_SAVED` flag.** It would be a second encoding of a fact `LOG_SINK` already carries, i.e.
  the precise defect shape of `INSTALL_OK` (a name asserting one thing while the value encodes another),
  reintroduced in the fix for a dishonesty bug. `85-design-discipline.md`'s counter-rule literally
  sanctions "a well-named function and two variables"; the design lands exactly there.
- **No predicate function.** Applying the rule's own test — "if you cannot name the future edit it
  prevents, it is not justified" — I tried and failed to name one: there are two call sites, both in
  regions this task freezes, and no downstream consumer (`sc doctor` is T-05 and reads no installer state).
  A function wrapping a single `[` is a pass-through.
- **The split itself passes the same test**, so this is not a double standard: the future edit it prevents
  is nameable and already happened once — any later change to the redirection target silently rewrites
  what the user is told, which is how rev. 2 acquired G-1 in the first place.

---

## 5. Line budget and content integrity of `02` rev. 3

- **481 lines** (measured, not trusted) — under the 500-line cap; F.6 stays clear and `verify_all` should
  still report `WARN: 0`, exit 0. This document is **392**. `01` 404, `04` 274, `05` 364, `PM_LOG` 418.
- **§4's code blocks are intact**: A, B, C (zh / en / the two `step6_warn` replacements), D, E, F, G, H, I
  — nine fenced blocks, all present, with §4.D's separators re-measured (§1.1).
- **§10.3's four coverage limits are intact** and unchanged in substance, with limit 2 correctly amended to
  say `LOG_SINK` is still derived by the real probe, and limit 4 retaining "**AC-9 is not executed. Full
  stop.**"
- The reflow dropped **no** content I can find: §8's seven reuse rows, §9's R1-R7, §12's eight
  out-of-scope items and §14's deferred items are all still present. §14 now numbers D-1…D-4, D-6, D-8,
  D-9 — D-5 and D-7 were *merged* into D-4 and D-3, and their content is verifiably inside those rows
  (nit G-10 concerns only where that is explained).

---

## 6. Rules compliance (delta only; rev-2's rulings stand for everything unchanged)

| Rule | Status |
|---|---|
| `85-design-discipline.md` | **PASS.** The amendment fixes the mechanism instead of documenting the defect — the counter-rule is honored in the same breath (two declines, both recorded in §3.1.1 and §12(4b)). Test 1 (patch-then-patch seam): the fix removes a seam rather than adding one. |
| `50-singbox-cli.md` — bilingual output | **PASS, re-verified key-by-key at 40/40** (§1.4), including format-specifier arity, which the rule's "adding a message in one language only is a defect" makes a release blocker here. |
| `50-singbox-cli.md` — both init systems | **PASS.** The amendment is init-agnostic: the two new keys are printed on both branches, and `fail_status` still switches on `INIT_SYS`. |
| `50-singbox-cli.md` — single self-contained `install.sh`, idempotency, Python floor | **PASS** — unchanged; no new file, command, or dependency; `bin/sc` byte-identical. |
| `70-doc-size.md` | **PASS** — §5. |
| `80-delivery-policy.md` | **N/A at this stage** — no commit, no push. |

---

## 7. Eight-dimension audit (rev. 3)

| # | Dimension | Result | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** (was WARN) | The rev-2 gap — `01` never said what to print when logging degraded — is now answered by a design-level reading that satisfies B-14, B-15(iii), B-17, AC-13, AC-18 and AC-19 simultaneously (§3), and is recorded as a reversible D-9 rather than assumed. B-1…B-19 remain individually testable. Residual: G-2's stale sentence in `01` §8 Q5, inert and already resolved in AC-10's favor. |
| 2 | Design completeness | **PASS** | Every in-scope behavior still has exact final text; the amendment adds the two message variants that were the only unrealized part of B-15/B-17, and §4.E now fixes the blank-line layout (G-5 closed). The developer makes no design decision. |
| 3 | Reuse correctness | **PASS** | Every anchor the amendment moves was re-measured against the working tree (§1.1); the new §8 row ("a 'did this side-effect happen' flag — none exists") is accurate: `INSTALL_OK` is retired and nothing else carries that fact. The `t()`+`printf` idiom and the `if`-guard precedent are reused, not reinvented. |
| 4 | Risk coverage | **PASS** | R1-R7 survive intact, and R5 now carries the *correct* residual for the new mechanism — the TOCTOU overclaim — stated in one honest sentence rather than hidden. No new risk class is introduced: the fix adds one variable and two message variants, all on paths that cannot alter control flow (§1.5). |
| 5 | Migration safety | **PASS** | Unchanged: no schema, no on-disk format, no migration, no flag; rollback is `git revert` + the next `curl \| bash`. The amendment adds no new file and no new mode. |
| 6 | Boundary handling | **PASS** (was WARN) | BC-17 now has a designed answer for both halves — what the installer *does* (unchanged) and what it *says* (`fail_nolog`/`step6_nolog`). All eight probe × phase combinations were enumerated and every one is truthful (§1.2). Null/unset, 127, masked unit, OpenRC-only, empty array at exit and unwritable log all remain covered. |
| 7 | Test feasibility | **PASS** (was WARN) | Both rev-2 spec defects are gone: S11 is satisfiable verbatim with a constructible expected output for each of its three sub-cases (§2.2), and S1's baseline has an audited, HEAD-shape-agnostic recipe whose failure mode is a red diff, never a false green (§2.3). S14 asserts the 40/40 parity that R3 makes load-bearing. AC-9 remains honestly excepted. |
| 8 | Out-of-scope clarity | **PASS** | `02` §12 gains item (4b), which forbids the five most likely over-builds *of this very fix* — including the two the architect itself declined. That is the right place for them: a developer who "improves" the fix with a `LOG_SAVED` flag now contradicts an explicit prohibition rather than an unstated preference. |

**No FAIL and no WARN in any dimension — the cleanest state this task has reached.**

---

## 8. Findings

### Blocking defects

**None. G-1 is closed at the mechanism level and no new defect was introduced.** Nothing requires a change
to `01` or `02` before coding starts — so this re-gate does **not** produce a third consecutive return to
stage 2, and PM rule 3's hard stop is not triggered.

### G-1 — **CLOSED**

The overloaded variable is split; every message names `$INSTALL_LOG` and states truthfully whether this
run's diagnostics reached it; the equality test is exact, not heuristic; `/dev/null` never reaches stdout;
and the degraded path now *satisfies* AC-13 where rev. 2 violated it (§1.2). The owner of the finding —
`02` §4.D/§4.E/§4.F — has discharged it. `01` needed no change (§3).

### New findings, all minor, none routed

**G-7 — `02` §14 D-9 slightly understates its own reversal cost.** It says reverting to "print 'written to
%s' unconditionally" is "a two-key deletion … nothing outside §4.C/D/F depends on it". In fact §4.D's
`if`/`else` and §4.F's `elif` would collapse, and **§10.2.1 S11 and §10.2.2's G-1 row** also depend on the
decision. Still a small, bounded reversal; the substantive claim (cheap, local, no ripple into the status
model) is correct. Recorded so a future reader does not under-scope it. Owner: `02` §14 D-9.

**G-8 — the exactness of `[ "$LOG_SINK" = "$INSTALL_LOG" ]` has one harness-only precondition.** It is
exact because `INSTALL_LOG` can never equal the literal `/dev/null` — true of the shipped constant, and
statically asserted by §10.2.2's AC-13 grep. But `02` §10.2's driver *overrides* `INSTALL_LOG` with
`$LOG_PATH`; a QA author who pointed `LOG_PATH` at `/dev/null` would make the two alias and the test
degenerate. No scenario does this (all use paths under `$T_DIR`). Recorded as a QA caution, not a
condition. Owner: none.

**G-9 — §10.2.3's two baseline fragments are not covered by §10.2's pre-assertions** (non-empty,
`bash -n`-clean). A mis-extraction there surfaces as a non-empty `diff`, i.e. a **loud red S1**, so it
cannot manufacture a false PASS — which is why this is a nit and not a condition. Owner: `02` §10.2.3.

**G-10 — §14's deferred-item numbering now skips D-5 and D-7**, and the explanation ("merged into
D-4/D-3") lives in a parenthetical inside §10.2.1 rather than in §14 itself. I confirmed both merged items'
content is genuinely present in the surviving rows, so nothing was dropped. Cosmetic. Owner: `02` §14.

**G-2, G-4, G-6 (from rev. 2) remain as recorded**: `01` §8 Q5's stale proceeding assumption (inert;
AC-10 governs), `umask 027` being a creation-time guarantee only, and `verify_all` now exiting 0.
**G-3 and G-5 are closed** by §10.2.3 and §4.E respectively.

### Positive confirmations worth recording

- **The fix is smaller than the finding.** One extra variable, two extra keys, one `elif`, one `if/else` —
  and it converts a documented dishonesty into a proven-true statement on all eight paths. PM's decision
  to route rather than accept C-2/C-3 bought a real mechanism for roughly the cost of the paperwork it
  replaced.
- **The pessimistic-default discipline is now uniform.** `LOG_SINK` starts at `/dev/null` and is *promoted*
  on proof, exactly as `PHASE_*` start at `failed`/`not-started` and are promoted by their owning step.
  One idea, applied consistently, is why the amendment reads as design rather than as a patch.
- **The half-rename bug did not happen.** All eight redirections were switched to `$LOG_SINK`; none was
  left pointing at `$INSTALL_LOG` (§1.5). This is the single most likely mechanical slip in a
  variable-split edit, and the design text is already clean of it — so the developer copying §4 verbatim
  inherits a correct rename.
- **`02` §10.2.2's G-1 static row is a genuine regression guard**, not decoration: it pins `LOG_SINK` to
  four legal syntactic positions and asserts `^INSTALL_LOG=` appears exactly once. A future edit that
  re-merges the two jobs fails a grep, not a reviewer's memory.

---

## 9. Conditions in force for stages 4-6

**C-1, C-5, C-6, C-7, C-8, C-9 — as dispositioned in §0.1. C-2, C-3 and C-4 are retired and must not be
carried forward.** Restated in full so no downstream agent has to reconstruct them:

- **C-1.** Implement `02` rev. 3 §4.A-§4.I verbatim over the **current working tree** (do not revert
  `install.sh` first). Both `t()` branches must end at **40** keys with identical names. No file other
  than `install.sh` and the one amended `CHANGELOG.md` bullet may change (AC-10).
- **C-5.** Do **not**: reassign `INSTALL_LOG`; add a `LOG_SAVED`-style flag, a predicate function, or a
  re-probe; put a `/dev/null` literal in any user-facing string; add `local fmt=""` to `t()`; add a
  liveness probe or persisted health state; add a `tee` pipeline, a `date` timestamp or any external
  command; reword or move `t step7`; change any timeout; touch `bin/sc`, `uninstall.sh`, `systemd/*` or
  `.harness/scripts/verify_all.sh`; add a second CHANGELOG bullet; or add any success test outside
  `install_report()`.
- **C-6.** Keep the rev-1 harness fixes (F-1 `T_DIR`, F-2 pure-builtin `${0##*/}` stub, F-7 `[+]`,
  whole-line `grep -nxF`) when extending `test/step7/run.sh`; `02` §10.2 still does not restate them.
- **C-7.** `06_TEST_REPORT.md` must restate `02` §10.3's four coverage limits verbatim and report **AC-9
  as unverified / deferred to T-07**. Claiming AC-9 as executed is a defect.
- **C-8.** `04_DEVELOPMENT.md` must be **rewritten** for rev. 3, not appended to.
- **C-9.** Keep every stage document under 500 lines; the gate remains `FAIL: 0`, and a new WARN is now
  attributable to whoever introduces it.

---

## 10. Developer / QA questions — pre-answered (delta over rev. 2)

Rev-2's Q-A … Q-G still apply unchanged, **except Q-E's key total, which is now 40**. Q-H is superseded.

**Q-H (replaces rev-2's). "What does the installer print if the log turned out to be unwritable?"**
**Answered, in §4 itself.** Step 6 prints `step6_nolog`, the failure banner prints `fail_nolog`; both name
the real path `/var/log/sing-box/install.log` and state that this run's diagnostics were **not** saved.
Nothing prints `/dev/null` — that string is an implementation detail of `LOG_SINK` only. Implement §4
verbatim; there is nothing left to record or invent (C-2 is retired).

**Q-J. "Two variables for one path looks redundant — can I collapse them?"** No, and this is the whole
point of rev. 3: `INSTALL_LOG` is what the user is *told*, `LOG_SINK` is where bytes *go*. Merging them
reintroduces G-1. `02` §10.2.2's grep row will catch it, and §12(4b) forbids it explicitly.

**Q-K. "Should the probe use `if !` like the old design?"** No. Rev. 3 flips it deliberately so the sink is
promoted on proof, matching the pessimistic-default discipline of `PHASE_*`. Copy §4.E as printed,
including the `2>/dev/null` on the **subshell** (not on the `printf`) — that is what keeps a failed probe
silent on the terminal.

**Q-L (QA). "Where do I point `LOG_PATH`?"** At a path under `$T_DIR`. Never at `/dev/null`: that would
make the harness's `INSTALL_LOG` alias `LOG_SINK`'s pessimistic default and quietly invalidate S11 (G-8).

**Q-M (QA). "S11 says the degraded run's stdout equals the twin's — is that literally achievable?"** Yes,
verbatim, and the row already names the exact difference per case: none for S1, one line for S2, two lines
for S10 (§2.2). Do not normalize any token; do assert the absence of a `/dev/null` token.

---

## 11. Deferred human-decision items (deferred-human mode — recorded, not asked)

| # | Item | Assumption this review proceeds under |
|---|---|---|
| **H-1** (revised) | **D-9**: on the degraded-log path the installer names the real path and **denies** that this run's diagnostics were saved there (`fail_nolog`, `step6_nolog`). The alternative the owner may prefer — say "written to \<path\>" unconditionally — is *less* true but shorter. | Assumed: **deny, truthfully**. Verified consistent with B-14, B-15(iii), B-17, AC-13, AC-18, AC-19 (§3); reversal cost is `02` §4.C/D/F plus S11 and §10.2.2's G-1 row (G-7). Surfaced so the owner can object; no requirement change is needed either way. |
| H-2 | Exit status becomes `1` on the failure path — a deliberate contract change for `curl \| bash` wrappers. | Assumed **accepted** (B-11; restores `main`'s pre-rev-1 behavior). |
| H-3 | `PHASE_SERVICE=started` is a launch-command result, not a liveness fact (R1). | Assumed **accepted** as B-4's definition; liveness probe is T-05's. |
| H-4 | R2 — `systemd/sing-box-rules-update.service:7`'s stale `/usr/local/bin/proxy` ExecStart. | Assumed **backlog**; recommended row `T-08 rules-update-unit-execstart`. |
| H-5 | Key-parity check + scenario harness promotion into `verify_all` B.2/B.3. | Assumed **T-07**, one row covering both. |

---

## Verdict

**APPROVED WITH CONDITIONS — this is an explicit PASS; stage 4 may start.** Conditions in force:
**C-1, C-5, C-6, C-7, C-8, C-9**. **C-2, C-3 and C-4 are retired** and must not bind by inertia.

**G-1 is closed.** The `INSTALL_LOG` / `LOG_SINK` split is a genuine fix, not a rewording: I enumerated all
eight probe × phase combinations and the installer tells the truth on every one; `[ "$LOG_SINK" =
"$INSTALL_LOG" ]` is exact rather than heuristic because the two values provably cannot alias; the probe's
polarity flip is correct under `set -euo pipefail` and loses no assignment; B-17 still holds because
neither variable is read by the success test; and key parity is **40/40** with correct `%s` arity in both
branches — the one failure mode that would abort the installer for Chinese users only.

**The amendment introduces no new defect**, so there is **no third return to stage 2** and PM rule 3's hard
stop is not reached. The four new findings (G-7 … G-10) are recorded nits — an understated reversal cost,
a harness caution, a missing pre-assertion whose failure mode is loud, and a numbering gap — none of which
blocks development or needs a condition.

One item remains for the owner rather than for any agent: **H-1 / D-9** — whether "the log could not be
written, so this run's error was not saved" is the message they want, versus the shorter but less true
"written to \<path\>". The design proceeds on the truthful reading, which is the only one consistent with
`01`'s own acceptance criteria, and the reversal is cheap and local if the owner disagrees.
