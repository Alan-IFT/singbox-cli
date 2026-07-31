# 05 — Code Review — install-enable-start-split (T-01)

- **Task ID**: T-01 · **Mode**: full · **Date**: 2026-07-31 — **rev. 3 (rewritten in place; the rev-1
  review is deleted, not appended to — it reviewed code that no longer exists)**
- **Upstream**: `01` rev. 2 (`READY`) · `02` rev. 3 (`READY`) · `03` rev. 3 (`APPROVED WITH CONDITIONS`;
  C-1, C-5, C-6, C-7, C-8, C-9 in force; **C-2/C-3/C-4 retired**) · `04` rev. 3 (`READY FOR REVIEW`)
- **Reviewed tree**: working tree over `HEAD` = `6282cea` (pre-rev-1, 386-line `install.sh`). The diff is
  therefore rev-1 **and** rev-3 together; per gate §7 that sum **is** the net delivery and is not scope creep.
- **Verdict**: `APPROVED` — 0 CRITICAL, 0 MAJOR, 1 MINOR, 5 NIT.

> Read-only review. No code was edited, no upstream doc was edited, nothing was committed.
> **Tool limitation, stated up front**: this reviewer can read and grep but cannot execute. `bash -n`,
> `verify_all`, `git diff` and the 334-assertion harness are **developer-reported**, not re-executed here.
> Every ✅ below is earned by static reading of the shipped file unless the row says otherwise.

---

## 0. Independence

The coordinator's spot-check (pessimistic defaults at `:21-29`; one derivation in `install_report()`) was
treated as **input, not evidence**. Every claim below was re-derived from the file. The rev-1 review's
STD-1…STD-3 came from exactly this posture; the same posture is applied here, and it produced one MINOR
that no upstream doc states in these terms (M-1) plus an independent confirmation of the stream-capture
decision from `bin/sc` rather than from `01` §2.2.

## 1. Files reviewed

- `/home/alan/Programs/singbox-cli/install.sh` (497 lines, read in full)
- `/home/alan/Programs/singbox-cli/CHANGELOG.md:8` (the amended bullet)
- Read as evidence, confirmed unmodified by this task: `/home/alan/Programs/singbox-cli/bin/sc`
  (`:545-564`, `:804-825`), `.harness/rules/85-design-discipline.md`, `.harness/rules/50-singbox-cli.md`
- Tests: `test/step7/run.sh` is **uncommitted and gitignored by construction** (`02` §10.1, `04` §QA), so it
  is outside the delivery diff and outside this review's read set. Its 334 green assertions are the
  developer's self-verification; stage 6 owns QA. This review does not credit them as independent evidence.

---

## 2. Findings

### CRITICAL
**None.**

### MAJOR
**None.**

### MINOR

- **M-1 [SPEC/TEST-SCOPE]** `install.sh:471-472` (and `:482`, `:486`) — **AC-5's "byte-identical success
  output" is proven for stdout under a stub that is silent on success; it is not true of a real systemd
  host, and the gap is not stated anywhere upstream in these terms.** `HEAD:install.sh` ran
  `systemctl enable --now sing-box` **unredirected** (rev-1 review §3 records the surviving
  `systemctl start sing-box || true` at `:380-381` as "UNREDIRECTED, asymmetry preserved"). On a real host
  `systemctl enable` writes `Created symlink /etc/systemd/system/… → …` to **stderr**. Rev. 3 sends all
  eight step-6/7 streams to `$LOG_SINK`, so those lines now go to the log instead of the terminal.
  This is **deliberate and correct** — `02` §4.G explicitly retires the D-5 asymmetry and gate rev. 2
  approved it, and B-13's parenthetical ("no new lines, no leaked subprocess chatter") reads as forbidding
  *additions*, which this is not. It is also strictly an improvement. **But** `02` §10.2.1 S1 asserts
  byte-identity with a stub that emits nothing on success, so the harness structurally cannot observe the
  removed chatter, and `04:128` states AC-5 unqualified ("the banner move changed nothing a user sees").
  **Requested action — reporting only, no code change**: `06_TEST_REPORT.md` should scope the AC-5 claim to
  *stdout, stub-driven*, and cite `02` §10.3 limit 3 (real `systemctl` semantics unverified) as the reason
  the stderr delta is untested. Owner: QA/PM, not the developer. Not a defect in `install.sh`.

### NIT

- **N-1 [DOC]** `CHANGELOG.md:8` names only `systemctl status sing-box` in the remediation triple; on
  OpenRC the installer prints `rc-service sing-box status` (`install.sh:258`). Factually narrow, not wrong.
  **Do not fix in T-01** — §4.I is mandated verbatim by gate C-1, so editing it would itself be a drift.
- **N-2 [MAINT]** `install.sh:18-19`, `:26`, `:444-449`, `:261` — the "why" comments cite stage-doc
  identifiers (`B-14`, `B-15`). They are resolvable (`docs/features/` is committed) but those IDs renumber
  across revisions (B-10/B-11 were superseded once already). Self-contained wording would age better.
  **Do not fix in T-01** — C-1 mandates the design's comment text verbatim; worth a convention note for
  future tasks instead.
- **N-3 [MAINT, pre-existing]** `install.sh:127` / `:170` — `run_as_root` is a **dead `t()` key**: the only
  root check (`:32-36`) precedes `t()`'s definition and uses raw bilingual `echo`. Present on `main`, not
  introduced here, and correctly counted in the 40/40 parity. No action.
- **N-4 [DOC]** Self-reported doc sizes in the gate are stale: `03` §0.1/§5 report itself as 392 lines and
  `04` as 274; measured, `03` is 430 and `04` is 208 (`01` 404 and `02` 481 match). **C-9's 500-line cap is
  met by every document**, so this is informational only.
- **N-5 [LOGIC, informational]** The B-17 guarantee is **stronger on the degraded path than on the promoted
  one**: with `LOG_SINK=/dev/null` a write can never fail, whereas with the sink promoted a disk that fills
  after the probe makes `sc reload`'s own writes fail inside Python and can flip a healthy phase to
  `failed`. That is exactly `02` §9 R5, accepted as Low. Recorded because the *inversion* is not stated
  upstream and is mildly counter-intuitive. No action.

---

## 3. Design fidelity — region by region against `02` rev. 3 §4.A-§4.I

Each region was compared statement by statement against the design's fenced block.

| Region | Design | Landed | Status |
|---|---|---|---|
| §4.A constants | `INSTALL_LOG`, `LOG_SINK="/dev/null"`, 3 `PHASE_*` + comments | `install.sh:18-29` | ✅ identical, incl. comment text and inline `# ok \| failed` annotations; placed after `SB_REPO=` |
| §4.B `cleanup()` | `${CLEANUP_DIRS[@]+"${CLEANUP_DIRS[@]}"}` + `rm -rf "$d" \|\| true` | `:300-305`, trap at `:305` | ✅ identical; `trap cleanup EXIT` untouched |
| §4.C `t()` keys | 11 new keys per branch, `step6_warn` rewritten | zh `:156-166`, en `:199-209`; `step6_warn` `:146`/`:189` | ✅ identical text, identical order, alignment preserved |
| §4.D `install_report()` | 49-line function after `t()`'s `}` | `:220-268` | ✅ identical, statement for statement |
| §4.E log probe | `if ( umask 027; printf … >>"$INSTALL_LOG" ) 2>/dev/null; then LOG_SINK=…; fi` | `:443-452` | ✅ identical, incl. no `!`, `2>/dev/null` on the **subshell**, no `else`; G-5 layout exact (`:441` visudo / `:442` blank / block / `:453` blank / `:454` marker) |
| §4.F step 6 | `if … >>"$LOG_SINK" 2>&1` / `elif [ "$LOG_SINK" = "$INSTALL_LOG" ]` / `else` | `:454-463` | ✅ identical; flat `elif`, both arms pass `"$INSTALL_LOG"` |
| §4.G step 7 | register×2 `\|\| true`, `sc reload` condition, launch in `if`, timer `\|\| true` | `:465-492` | ✅ identical; `PHASE_CONFIG="ok"` leads the `then` list; `t step7` unmoved and unreworded |
| §4.H tail | `install_report \|\| exit 1` / `exit 0` | `:494-497` | ✅ identical; the 13 banner lines are **gone from the tail** and present in §4.D |
| §4.I CHANGELOG | one bullet amended in place | `CHANGELOG.md:8` | ✅ verbatim; one bullet, no second bullet, no heading, no version bump |

**Design drift: none.** No route to the solution-architect.

Banner-move check (AC-5, static half): the success arm at `:224-237` emits 13 output statements in the
design's order — `echo ""`, `═`×55, `done_banner`, `═`×55, `echo ""`, `next_steps/add/status/help/lang/
uninstall`, `echo ""`, `note_initial`. All three separators are the same 55-character literal used at
`:332`/`:334`. Consistent with "moved, not retyped".

---

## 4. The variable split — full audit (the load-bearing check)

Grep of every `INSTALL_LOG` / `LOG_SINK` occurrence in the shipped file:

| Requirement | Result |
|---|---|
| `^INSTALL_LOG=` appears exactly once | ✅ `:21` only — **never reassigned** |
| `$INSTALL_LOG` as a redirection target | ✅ **only** `:450`, inside the probe, where it must be |
| `LOG_SINK` pessimistic default | ✅ `:22` `/dev/null`, promoted only at `:451` inside the probe's `then` |
| All eight step-6/7 redirections use `$LOG_SINK` | ✅ `:456`, `:471`, `:472`, `:474`, `:479`, `:482`, `:486`, `:488` — **eight, no half-rename** |
| `LOG_SINK` never an argument to `t` | ✅ its only non-redirection uses are `:262` and `:459`, both the left side of `[ "$LOG_SINK" = "$INSTALL_LOG" ]` |
| Every user-facing log mention passes `"$INSTALL_LOG"` | ✅ `:263`, `:265`, `:460`, `:462` — all four |
| No `/dev/null` literal in any user-facing string | ✅ the token appears at `:20`/`:22` (comment + sink default), `:450` (`2>/dev/null`), and 10 pre-existing suppressions (`:88-111`, `:287`, `:298`, `:346`, `:441`). **Zero occurrences inside any of the 40 `t()` strings.** |

The equality test is **exact, not heuristic**: `LOG_SINK` has two literal values and one writer, and
`INSTALL_LOG` is a compile-time constant that cannot alias `/dev/null`. I re-derived all eight
{probe} × {phase} combinations against the code (not against `03` §1.2) and reached the same result: no
path states anything untrue about the log, and `/dev/null` never reaches stdout.

---

## 5. i18n parity — release blocker class, verified statically

`t()` still declares `local fmt` with **no default** (`:124`, per Q4(a)), so a one-language key is an
installer abort under `set -u`, not a blank line. Therefore this was checked by enumeration, not by trust.

- **Key count**: 80 `<key>) fmt=` lines total; zh `:127-166` = **40**, en `:170-209` = **40**. ✅
- **Key names**: the two lists are identical, name for name, **in the same order**; no duplicates, no
  collisions with the 29 pre-existing keys. The 11 new names in both: `fail_banner`, `fail_config`,
  `fail_service`, `fail_rulesets`, `fail_next`, `fail_rules`, `fail_reload`, `fail_status`, `fail_log`,
  `fail_nolog`, `step6_nolog`. ✅
- **`%s` arity**: exactly one `%s` and exactly one argument for `fail_status` (`:163`/`:206`, called at
  `:256`/`:258`), `fail_log` (`:164`/`:207`, `:263`), `fail_nolog` (`:165`/`:208`, `:265`),
  `step6_warn` (`:146`/`:189`, `:460`), `step6_nolog` (`:166`/`:209`, `:462`). The other six new keys carry
  **zero** `%` and are called with zero arguments, so they take `t()`'s `printf "%s\n"` arm. ✅
- **No orphan call sites**: all 42 `t <key>` invocations in the file name a key present in **both**
  branches. ✅ (One key, `run_as_root`, is defined and never called — N-3, pre-existing.)
- **B-14**: `step6_warn` no longer asserts a speculative cause; zh `详细原因见 %s`, en `see %s for the
  cause`. Neither contains `网络问题` / `network issue`. ✅

---

## 6. Requirement coverage — B-1 … B-19

| # | Behavior | Implementation | Status |
|---|---|---|---|
| B-1 | systemd autostart registered unconditionally, before config gen | `:470-471` (before `:479`) | ✅ |
| B-2 | timer registered unconditionally | `:472` | ✅ |
| B-3 | registration failure non-fatal | `\|\| true` at `:471`, `:472`, `:474` | ✅ |
| B-4 | one phase-status model, 3 phases, 2 values each | `:27-29` defaults; writers `:457`, `:480`, `:483`, `:489`; **read only** at `:226`, `:243`, `:248` | ✅ |
| B-5 | config gen cannot abort the installer | `:479` condition position | ✅ |
| B-6 | launch conditional, guarded, recorded | `:482-490`; skipped ⇒ default `not-started` | ✅ |
| B-7 | OpenRC parity | `:474` unconditional add; `:488-489` conditional start; `:258` `rc-service sing-box status`; no rules-update token on the OpenRC path | ✅ |
| B-8 | idempotency | steps 6-7 touch neither `nodes.json` nor `settings.json`; log is `>>` | ✅ |
| B-9 | ordering observable | register (`:471-474`) < reload (`:479`) < start (`:482`/`:488`) | ✅ |
| B-10 | bilingual parity mandatory | §5 above, 40/40 | ✅ |
| B-11 | exit status derived, non-zero on failure | `install_report` returns 0/1 (`:238`, `:267`); `:496-497` | ✅ exit 1 (confirmed adjudicated, B-11/Q6a) |
| B-12 | real cause preserved in the log | `:456` both streams (stdout carries the per-file cause, `bin/sc:817`); `:479` both streams (stderr carries it, `bin/sc:555`,`:932`) | ✅ |
| B-13 | nothing discarded in 6-7; terminal quiet | all 8 commands → `$LOG_SINK`; no new stdout line on success | ✅ (see M-1 for the stderr-chatter nuance) |
| B-14 | step-6 warning names the log path, no speculation | `:146`/`:189` + `:460` | ✅ |
| B-15 | honest closing output | `:226-238` success arm unchanged; `:240-267` failure arm; log path named, contents never dumped; rulesets-only failure ⇒ success (`PHASE_RULESETS` absent from `:226`) | ✅ |
| B-16 | remediation list + no self-heal promise | `:252-259`; `fail_next` says 「系统不会自动恢复」/"nothing repairs it automatically"; `fail_status` switches on `INIT_SYS` | ✅ |
| B-17 | logging never breaks the install | sink is `/dev/null` or a proven-openable path, so `>>` cannot fail at open; neither log variable is read by the success test | ✅ (R5 residual, N-5) |
| B-18 | derived status is the process status | `:304` guards both the empty-array expansion and the `rm`; trap returns 0 and never calls `exit` | ✅ |
| B-19 | log not world-readable | `umask 027` inside the probe subshell ⇒ 0640 root-owned at creation | ✅ (creation-time only — gate G-6, unchanged) |

**Honest banner on every path**: yes. Every reachable end state routes through `install_report()`, whose
two arms are mutually exclusive and jointly exhaustive on `PHASE_CONFIG`/`PHASE_SERVICE`.
**Failure exits non-zero**: yes, `1`. **Success output unchanged**: yes on stdout; see M-1.

---

## 7. Acceptance criteria — AC-1 … AC-20

| # | Evidence | Status |
|---|---|---|
| AC-1 | `bash -n` — **developer-reported PASS**; not executable by this reviewer. Static read found no syntax hazard. | ✅ (reported) |
| AC-2 | `verify_all` `FAIL: 0` — **developer-reported** (16/0/0/2, exit 0). | ✅ (reported) |
| AC-3 | `:471-472` unconditional; `:482`/`:486`/`:488` all inside the `PHASE_CONFIG=ok` branch ⇒ no `start` on a reload failure | ✅ static |
| AC-4 | no unguarded failure-prone command after `:456`; script reaches `:496` on every path | ✅ static |
| AC-5 | stdout ordering/text preserved; harness-reported byte-identity vs `HEAD` | ✅ with **M-1** scope caveat |
| AC-6 | `:27-29` unconditional defaults ⇒ readable under `set -u` at `:226` on every path | ✅ static |
| AC-7 | `:474`, `:488`; no `sing-box-rules-update` token in the OpenRC branch | ✅ static |
| AC-8 | `>>` append + per-run marker `:450`; no user-data write | ✅ static |
| AC-9 | **Not executed, not executable here** — deferred to T-07 (C-7). Claiming otherwise is a defect. | ⏸ deferred |
| AC-10 | Cannot run `git diff`. Spot-checked `bin/sc:812` (`timeout=30`) and `:552-557` intact; developer reports empty diffs for `bin/sc`, `uninstall.sh`, `systemd/`, `.harness/`, `README*`. | ✅ (reported + spot-check) |
| AC-11/12 | superseded | — |
| AC-13 | `:240` fail banner, `:252-259` three commands, `:263`/`:265` literal `$INSTALL_LOG`; `done_banner` unreachable when the success test is false | ✅ static |
| AC-14 | `:238` return 0 → `:497` exit 0; `:267` return 1 → `:496` exit 1 | ✅ static |
| AC-15 | `:456` captures **stdout** too (`bin/sc:817` is a `print`), and nothing reaches the terminal | ✅ static |
| AC-16 | both branches complete; no key reachable in one language only | ✅ static |
| AC-17 | 40/40, identical names (§5) | ✅ static |
| AC-18 | `:146`/`:189` name `%s`, no speculative cause | ✅ static |
| AC-19 | probe failure ⇒ sink `/dev/null`, phases and exit status unaffected | ✅ static |
| AC-20 | `umask 027` in the probe subshell | ✅ static |

No criterion is unimplemented. **No CRITICAL from coverage.**

---

## 8. `set -euo pipefail` — re-derived independently (`install.sh:9`)

- **`install_report || exit 1`** (`:496`): the function is the left operand of `||`, so errexit is
  suspended for its whole body (bash propagates the AND-OR suspension into the callee). Its body is only
  `echo`/`t`/`[`, and the two `return`s are explicit — the status cannot be lost. `:497 exit 0` is reached
  only when the function returned 0. ✅
- **The probe** (`:450`): a `( … )` subshell in `if` condition position. It contains **no assignment**
  (`umask` + `printf` only), so BC-12 holds and the promotion at `:451` runs in the parent. The
  `2>/dev/null` is on the **subshell**, so the shell's own `…: Permission denied` (emitted when the `>>`
  redirection fails, before `printf` runs) is discarded. No `else` ⇒ the compound returns 0 ⇒ `$?` entering
  step 6 is 0. Caught traps are reset to default inside a subshell, so a failing probe cannot fire
  `cleanup` and `rm -rf` the artifact directory mid-install. ✅
- **errexit suspension in conditions**: `:456`, `:459`, `:479`, `:482`, `:488` are all condition position;
  `:471`, `:472`, `:474`, `:486` are left operands of `|| true`. Nothing new can abort the script; exit 127
  is just another non-zero (BC-3). ✅
- **`|| true` operands**: all four are complete simple commands with their redirections attached before the
  `||`, so the redirection failure mode is also absorbed. ✅
- **`${CLEANUP_DIRS[@]+"${CLEANUP_DIRS[@]}"}`** (`:304`): the `+` alternate form suppresses the bash-4.2
  empty-array `unbound variable` fault, and the inner quoting is preserved so paths with spaces survive.
  A zero-iteration `for` returns 0; `rm -rf "$d" || true` returns 0. ✅
- **EXIT trap vs. the derived status**: the trap never calls `exit`, and no command in it can fail under
  errexit, so bash preserves the status that triggered the exit. `install_report`'s value survives to the
  process. ✅
- **`pipefail`**: no pipeline, no `$( )`, no `&` is introduced in any changed region — it never applies. ✅
- **`set -u`**: all six globals `install_report()` reads (`PHASE_*`×3, `INIT_SYS`, `INSTALL_LOG`,
  `LOG_SINK`) are unconditionally assigned at `:21-29` / `:68-69`, before any read. ✅
- **Assignments** are all literals (`:457`, `:480`, `:483`, `:489`, `:451`) — status 0, no `((…))`, no
  `let` (BC-9). ✅

## 9. Single derivation (design's central invariant)

`PHASE_*` are read at **exactly three sites, all inside `install_report()`** (`:226`, `:243`, `:248`).
The success test exists **once**, at `:226`. There is no second `if` anywhere in the file re-asking "did it
work" — the defect the design exists to prevent is absent. ✅

## 10. Gate C-5 prohibitions — each verified

| Prohibition | Result |
|---|---|
| No `INSTALL_LOG` reassignment | ✅ one assignment, `:21` |
| No `LOG_SAVED`-style flag | ✅ zero occurrences |
| No predicate function | ✅ functions in the file: `pkg_install`, `t`, `install_report`, `cleanup` — no wrapper around the `[` test |
| No re-probe | ✅ one probe, `:450` |
| No `/dev/null` in user text | ✅ §4 above |
| No `local fmt=""` | ✅ `:124` is bare `local fmt` |
| No liveness probe | ✅ no `is-active`, no `sleep` |
| No `tee` | ✅ zero |
| No `date` / new external command | ✅ `umask`, `printf`, `$$` are builtins |
| `t step7` unmoved / unreworded | ✅ `:466`, first statement of step 7; strings `:147`/`:190` unchanged |
| No timeout changed | ✅ `bin/sc:812` still `timeout=30` (spot-read); `bin/sc` reported byte-identical |
| `bin/sc` / `uninstall.sh` / `systemd/*` / `.harness/` untouched | ✅ developer-reported empty diffs; nothing in `install.sh` references them beyond the pre-existing install steps |
| Exactly one CHANGELOG bullet | ✅ `CHANGELOG.md:8`, amended in place; `:7` is the pre-existing Clash-API bullet from `22502f9` |
| No success test outside `install_report()` | ✅ §9 |
| **`INSTALL_OK` fully retired** | ✅ **zero occurrences** in `install.sh` |

## 11. Design discipline — the 386 → 497 growth (required finding)

**Verdict: the +111 lines are carried by the requirement. No speculative generality.** Accounting:

| Lines | What | Carried by |
|---|---|---|
| ~22 | 11 new `t()` keys × 2 branches | B-10 (bilingual parity is a hard rule, `50-singbox-cli.md`) — the single largest block, and unavoidable |
| ~36 net | `install_report()` minus the 13 banner lines it absorbed | B-4/B-11/B-15 — one function, no parameters, no state |
| ~13 | five constants + their comment | B-4 + G-1's split |
| ~11 | the log block + probe | B-12/B-17/B-19 |
| ~14 | rev-1's step-7 expansion (10 → 24 lines) | B-1/B-2/B-3/B-5/B-6 |
| ~7 | step 6's `elif`/`else`, `cleanup`'s guard comment, the tail | B-14/B-18 |

Counter-rule applied to the fix itself: **no new file, no module, no config format, no persisted state, no
flag, no predicate, no framework.** The delivered shape is literally the rule's own sanctioned example —
"a well-named function and two variables". The one abstraction added (`install_report()`) passes the
"name the future edit it prevents" test: without it the success test reappears at two call sites, which is
precisely how the tree came to print `✅ 安装完成` while step 7 already knew better. About 25 of the 111
lines are comments, all "why" (the `>>`-on-unwritable-path rationale, the bash-4.2 array fault, the
pessimistic-default discipline) — none restating what the code says. **PASS.**

The one thing I'd watch, stated so a future task doesn't over-read it: `PHASE_RULESETS` has exactly **one**
consumer (`:248`, a hint line) and never influences the exit status. It survives the deletion test only
because B-4 mandates three phases and B-15 mandates the `fail_rulesets` hint. It is **not** health state
and must not be treated as such by T-05.

## 12. The three PM judgment calls — my own view

1. **Retiring `INSTALL_OK` in favour of `PHASE_RULESETS`/`PHASE_CONFIG`/`PHASE_SERVICE` — I agree**, and I
   would have reached the same conclusion independently. `INSTALL_OK` asserted a whole-install verdict while
   only ever encoding config generation (a failed `systemctl start` left it `1`); once the banner reads the
   state, that name puts a lie one dereference from the output. The three names map 1:1 onto B-4's table,
   which is the actual domain. Overriding the owner's literal suggested shape is justified here because the
   owner's *stated goal* (「优先用好的设计」) is better served by the renaming than by the identifier —
   `01` B-4 itself says "the requirement is the single source of truth, not the identifier". Cost: two extra
   variables, both in the constant block, both with pessimistic defaults. Correct trade.
2. **The `INSTALL_LOG` / `LOG_SINK` split — I agree, strongly.** This is the finding my rev-1 review would
   have raised had the code existed. One variable doing both jobs is not a naming problem, it is a
   correctness problem: demoting the sink rewrote what the user was *told*, producing 「详细原因见
   /dev/null」 — a false statement inside the fix for false statements. Two literal-valued variables with one
   writer each make the equality test exact rather than heuristic, which is what lets the two message
   variants be provably true. I verified all eight probe × phase combinations from the code itself and found
   no untrue path. The declines that came with it (no third flag, no predicate) are also right.
3. **Capturing stdout as well as stderr — I agree, and I confirmed the premise at source rather than
   accepting `01` §2.2.** `bin/sc:817` is `print(t("failed: {e}", e=e))` → **stdout**; `bin/sc:821` is
   `sys.exit("\n" + t("{n} ruleset(s) failed to update", …))` → **stderr, count only**. A literal
   stderr-only reading of the owner's instruction would have logged "4 ruleset(s) failed to update" and
   discarded every `urlopen error timed out` — reproducing the reported defect one layer down. Two points
   nobody upstream states: (a) stdout capture also preserves `bin/sc:811`/`:815`'s per-file
   `↓ <file> … OK (n bytes)` trace, so the log shows *which* files succeeded before the failure — more
   diagnostic value than the design claimed; (b) the cost is that every run, including clean ones, appends
   that chatter, and there is no rotation (out of scope by `01` §4.8, removed wholesale by
   `uninstall.sh:137`). Bounded and acceptable. The deviation from the instruction's literal wording is the
   correct call and is properly recorded as D-2.

## 13. Performance and security

- **Performance**: not material, as specified. No new loop, no new network call, no new process. The probe
  is one `printf` to an already-existing directory. Eight redirections open a file per command, all
  builtin-cheap. ✅
- **Security**: `install.log` is created `0640` root-owned via `umask 027` in the probe subshell (the umask
  cannot leak to the parent). It can quote config fragments (`bin/sc:555` echoes `sing-box check` stderr,
  and `config.json` holds node credentials at mode 600), so the restrictive mode is load-bearing, not
  cosmetic — correctly identified by B-19. Considered and **not** findings: the containing directory
  `/var/log/sing-box` is created root-owned by the installer itself (`:375`) before any write, so a symlink
  plant into it is not reachable by an unprivileged user; no new privilege, no sudoers change, no new
  network endpoint; `t()`'s `printf "$fmt\n"` is format-string-injectable only from the key table, never
  from user input, and every new format carries at most one `%s`. ✅

## 14. Confirmed, not re-litigated

Exit `1` on failure (B-11/Q6a); no `tee` (pipefail would let a logging fault fail the install);
`PHASE_SERVICE=started` is a launch-command result, not a liveness fact (R1 → T-05). All three are visible
in the code exactly as adjudicated.

**T-09 note (do not fix here).** `systemd/sing-box-rules-update.service:7`'s stale
`ExecStart=/usr/local/bin/proxy` is owner-confirmed and owned by T-09; `systemd/` is untouched by this
change, correctly. One consequence worth recording for T-09's priority: `install.sh:472` now registers the
timer **unconditionally**, including on runs that fail at `sc reload` — where `HEAD` aborted before ever
reaching the timer. T-01 therefore does not create T-09's bug but **widens its blast radius to failed
installs**, adding a weekly `203/EXEC` to hosts that previously had no timer at all. The OpenRC path is
unaffected (`bin/sc:898` writes the correct `/usr/local/bin/sc update-rules`, and this task adds no OpenRC
schedule). Raises T-09's user-visible impact until it lands.

---

## Axis status

- **Standards-conformance**: **3 findings, worst = NIT** (N-2 comment-ID convention, N-3 pre-existing dead
  key, N-4 stale doc line counts). `50-singbox-cli.md`'s bilingual hard requirement, both-init-system rule,
  single-self-contained-file rule, idempotency rule, and `85-design-discipline.md`'s counter-rule all PASS;
  `70-doc-size.md` / C-9 met by every document. No invented rules were applied.
- **Spec/design-fidelity**: **2 findings, worst = MINOR** (M-1 AC-5 claim scope — a reporting action for
  stage 6, not a code change; N-1 CHANGELOG OpenRC variant, which C-1 forbids changing). All nine design
  regions §4.A-§4.I landed verbatim; all nineteen behaviors B-1…B-19 implemented; nineteen of twenty
  acceptance criteria satisfiable, AC-9 honestly deferred to T-07.

Aggregate = the more severe of the two axes = **MINOR**. Neither axis carries an unaddressed CRITICAL or
MAJOR, so the verdict may read `APPROVED`.

## Routing

- **Code defect → developer**: **none.** Nothing in `install.sh` or `CHANGELOG.md` requires a change.
- **Design drift → solution-architect**: **none.** Zero drift across all nine regions.
- **M-1** is a stage-6 reporting action for PM/QA: scope AC-5's byte-identity claim to *stdout under a
  silent stub* in `06_TEST_REPORT.md` and cite `02` §10.3 limit 3. It does not block merge.

## Verdict

APPROVED (0 CRITICAL, 0 MAJOR, 1 MINOR, 5 NIT)
