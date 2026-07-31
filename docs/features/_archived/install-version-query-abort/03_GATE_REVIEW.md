# 03 — Gate Review · T-11 `install-version-query-abort`

- Mode: **full** · Decision mode: **deferred-human** (`defer, do not ask`) · Stage 3, 2026-08-01
- Read: `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`, `PM_LOG.md`, `install.sh` @ `22502f9`, `AI-GUIDE.md`, rules `85-design-discipline` / `50-singbox-cli` / `25-decision-policy` (red lines), `.harness/insight-index.md`, `.harness/rejected-decisions.md`, `.harness/scripts/verify_all.sh`, `.harness/scripts/archive-task.sh`, `CONTEXT.md`, `docs/dev-map.md`, `docs/tasks.md`.
- This stage has **no shell tool**. Every check below is a read of the actual source; nothing upstream is taken on trust. Shell facts I could not obtain are named as stage-4 obligations with a prediction and a stop rule (C-8).
- **Persistence note (PM):** the gate-reviewer agent has no write-capable tool. This document is the gate's output saved verbatim by the PM; no word was altered.

## 1. Source verification log — upstream claims checked against `install.sh`

**V** = verified true at HEAD; **V±** = true with a correction.

| Claim (source) | Result |
|---|---|
| `install.sh:9` is `set -euo pipefail` | **V** |
| `:373-375` is the bare `SB_VER=$(curl … \| grep … \| head -1 \| sed …)`; handler at `:376-381` | **V** |
| `CURL_OPTS_QUIET=(-f -s -S -L)` at `:128`, `-S` kept | **V** |
| Phase defaults `:27-29`; `install_report()` `:243-288`; `install_report \|\| exit 1` at `:518` | **V** |
| `install_report` prints `fail_config` at `:263-267` when `PHASE_CONFIG != ok` | **V** — false at step 2 |
| … `fail_rulesets` `:268-270` when `PHASE_RULESETS=failed` | **V** — false at step 2 |
| … `fail_rules`/`fail_reload` `:273-274` naming `sc update-rules` / `sc reload` | **V** — `sc` installed at `:398`, later |
| … `fail_status "systemctl status sing-box"` `:276` | **V** — unit installed at `:428`, later |
| … `fail_nolog "$INSTALL_LOG"` `:285` (`LOG_SINK` is `/dev/null` until the probe at `:472`) | **V** — misleading at step 2; `/var/log/sing-box` is created at `:397` |
| `t()` at `:139-238`; zh `:145-185`, en `:189-229`; **41 keys each**; `local fmt` has no default | **V** |
| `t() {` and its closing `}` are the only column-0 lines of the function; `esac` is indented | **V** — §5.2's extraction anchors are exact |
| No line in the `t()` body contains `fmt=` other than the 82 case lines (`:142` is `local fmt`, `:234` is `printf "$fmt\n"`) | **V** — §5.2 step 2's assertion is sound |
| `download_failed` `:150`/`:194`, `check_network` `:151`/`:195` | **V** |
| `CLEANUP_DIRS` + `trap cleanup EXIT` `:320-325`; `ARTIFACT_DIR` pushed `:333`, `SB_TMPDIR` `:372` | **V** — B-10 holds on `exit 1` |
| First `mkdir -p /etc/sing-box…` is `:397` | **V** — B-9 holds structurally |
| Pre-step-7 early exits at `:35 :47 :57 :66 :313 :348`, two using these two keys (`:346-348`, `:385-387`) | **V±** — `:313` exits **without printing** (user answered "not y"); the established-shape argument still holds on `:346-348` / `:385-387` |
| `verify_all.sh:70` is `step "B.2" "Tests pass" "SKIP"`, inside `HARNESS:B-CUSTOM` markers | **V** |
| F.6 excludes `*/_archived/*` (`verify_all.sh:223-231`) | **V** — PM-1's "self-clears at archive" is true by construction |
| `rejected-decisions.md:57-73` = `ruleset-unit-tests-in-t02`; `:110-138` = this row's own deferral | **V** |
| `docs/dev-map.md:52` — `bin/sc` has no `en` table; `:17` — CHANGELOG is written in Chinese | **V** |
| `.harness/insight-index.md` lines 10 / 13 / 19 / 22 / 26 / 28 cited by both docs | **V** — all six land on the cited fact |
| Sweep: `install.sh` contains **11** command substitutions in code | **V±** — 11 **sites**, but **12** substitutions: `:318` nests `$(dirname …)` inside `$(cd … && pwd \|\| echo "")`. A mechanical `$(` count of code yields 12. See F-1 / C-9. |

Two upstream text claims I could **not** confirm as written:

- Design §3.3 says curl's raw English line is "genuine diagnostic detail *below* the localized statement". In execution order it is printed **first** (curl runs before `t`). Cosmetic wording; it must not drive a reordering attempt (F-5).
- BC-4 (requirement) says a tag without a leading `v` may still be "semver-like [so] the run proceeds (unchanged from HEAD)". At HEAD that branch is unreachable: the non-matching passthrough emits the whole JSON line (`  "tag_name": "1.10.0",`), which can never match `^[0-9]+\.[0-9]+` because of the leading whitespace. Both HEAD and the proposed shape land on the handler. This makes B-5 **easier** to satisfy, not harder (F-4).

## 2. The eight-dimension audit

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | B-1…B-12 are mechanism-free and each names an observable; B-2's five modes are exhaustive over the pipeline's status space (curl fails / curl succeeds × extraction yields nothing / empty / non-semver), which I re-derived independently from `:373-381`. D-1…D-7 leave no fork unresolved. |
| 2 | Design completeness | **PASS** | §3.3 traces all five B-2 modes to the single judge at `:377`; §3.1 gives verbatim post-change text; every out-of-scope sibling site carries a re-homed row. Nothing in B-1…B-12 is unaddressed. |
| 3 | Reuse correctness | **PASS** | Every symbol the design says it reuses exists at the cited lines (§1): `t()`, both keys, `CURL_OPTS_QUIET`, `CLEANUP_DIRS`/`trap`, the `verify_all` B.2 slot, both sibling early-exit blocks. The one "new module" claim (`check-i18n-parity.sh`) is genuinely absent from `.harness/scripts/`. |
| 4 | Risk coverage | **WARN** | R-a…R-h are the right risks and R-f is unusually good. Four real risks are missing: the harness end-anchor collision (F-2), a `curl` stub that never gets invoked (F-3), two governing documents whose "B.2 is SKIP" sentence goes stale (F-7), and the nested-substitution miscount (F-1). All four convert into stage-4 conditions. |
| 5 | Migration safety | **PASS** | No schema, no data migration, no installed-footprint change, no feature flag needed: `install.sh` is fetched fresh per run, rollback is `git revert`. The failure path is print-and-exit and creates nothing under `/etc` (first `mkdir` is `:397`), so B-9/NFR-3 hold structurally rather than by assertion. |
| 6 | Boundary handling | **PASS** | `set -u` handled by the pre-assignment `SB_VER=""` (BC-6); empty body, non-2xx, interstitial, empty version and non-semver each have a stub mode; bash 4.2 / curl 7.29 floors untouched (no array expansion, no curl option); concurrency explicitly declared not-a-scenario with a reason. `exit 1` runs the EXIT trap, so temp dirs go. |
| 7 | Test feasibility | **WARN** | Every AC is dischargeable without running `install.sh`, and §6's fragment harness is the right instrument. But AC-6, AC-5, AC-7 and AC-8 can each go green while proving nothing as specified (F-8…F-10), and AC-13's counting rule contradicts a mechanical count (F-1). C-2…C-6 and C-9 close all of it. |
| 8 | Out-of-scope clarity | **PASS** | O-1…O-10 plus §11's restatement are explicit, and every declined item has a named row (R-1…R-6). The over-build pressure points (a `fetch_sb_version()` helper, a `fail_download()` helper, GitHub auth, retries) are each declined **with the future edit named** — rule 85's counter-rule applied in the right direction. |

No dimension is FAIL.

## 3. Adjudications — the nine points the PM referred

### A-1 · The core fork: explicit early exit, not `install_report()`. **UPHELD.**

I checked the six claimed-false statements against `install_report()` myself (§1). All six are real: with `PHASE_CONFIG=failed` and `PHASE_RULESETS=failed` at step 2 the function prints `fail_config` (config generation never ran), `fail_rulesets` (step 6 never ran), instructs `sc update-rules` and `sc reload` (installed at `:398`, after this point), names `systemctl status sing-box` (unit installed at `:428`), and prints `fail_nolog` claiming `/var/log/sing-box/install.log` "is not writable" when in truth the directory does not exist yet and the probe at `:472` has not run. That is six statements B-4 forbids either explicitly (config generation, config check, rule-sets, uninstalled commands) or by its "true of what happened" clause.

This is not rationalizing the easier change, for four independent reasons:

1. **The requirement pre-authorized the fork.** §2.4 states the same finding and ends "The architect owns the mechanism"; D-6 deliberately holds the exit status at 1 so B-1 is judged *route-neutrally*; O-10 pins `install_report()`'s behaviour for a step-7 run.
2. **The originating record delegated it explicitly.** `rejected-decisions.md:129-134`: "That row decides whether the fix keeps the direct `exit 1` or routes through `install_report()`" — and it names the expected shape, "an explicit `if ! SB_VER=$(…)`". The design lands exactly there.
3. **The early exit satisfies the project's own definition.** `CONTEXT.md`'s `stated outcome` is "a sentence the installer itself prints, in the user's chosen language, saying what happened and what to do next, paired with an exit status derived from the same facts." `t download_failed "GitHub API (sing-box version)"` + `t check_network` + `exit 1` is exactly that. T-01's guarantee is that the installer *states its outcome*, not that it does so through one particular function — and §2.3/D-7 already establish that the guarantee is not global today.
4. **The seam tests really do come back negative.** Step 2 computes nothing `install_report()` consumes (test 1); no judgment is duplicated — "is this version usable?" vs "did config+service succeed?" are different questions with different remediation (test 2); the deletion test on a hypothetical era-discriminator branch reveals a pass-through wrapper around two `t` calls.

Residual, recorded not blocked: for mode 5 (`vnightly`) the rendered "Download failed" is imprecise — a version *was* downloaded, it is merely unusable. That imprecision exists at HEAD (the handler at `:377` already catches modes 4 and 5 and prints this), D-1 deliberately merged all five modes onto one handler, and B-4's enumerated prohibitions do not cover it. Not a defect introduced here.

### A-2 · `head -1` → `sed -n '1s…p'`. **UPHELD, with C-1 and C-2 binding.**

I worked the equivalence out rather than accepting §3.2:

- `grep '"tag_name"'` emits only matching lines. `sed -n '1s/.*"v\([^"]*\)".*/\1/p'` applies `s` to **line 1 of sed's input** — i.e. grep's first output line, exactly what `head -1` selected — and `p` prints only on a successful substitution. For every well-formed body the output is byte-identical to `head -1 | sed 's/…/\1/'`. **B-5 holds.**
- Multiple `tag_name` lines: HEAD takes line 1 and substitutes; the new form addresses line 1 and substitutes. Same line, same result; a later matching line is ignored by both.
- The only divergence is a first line that does *not* match: HEAD echoes it whole, the new form emits nothing. Both flow to the same handler and the same `exit 1` (F-4: HEAD's passthrough can never satisfy `^[0-9]+\.[0-9]+`). Observationally identical.
- No command is added to the invoked set (`sed`, `grep` already there; `head` survives at `:368`/`:392`). GNU/BSD/busybox `sed` all support a numeric address with `s///p` under `-n`, so the Alpine floor is safe.

Is the SIGPIPE concern real or speculative? **Real in mechanism, near-unreachable in practice, and that is precisely why the change is right.** With `head -1` retained under the new `if` guard, a `grep` killed by SIGPIPE (141) is, under `pipefail`, the rightmost non-zero status, so the guard's failure leg would wipe a correctly extracted `SB_VER` and report a **successful** fetch as failed — a new, non-deterministic wrong answer HEAD does not produce in that form. BC-5/B-6 forbid depending on the race falling the friendly way. For the real endpoint the body is ~1.6 KB and grep emits one short line, so the race is essentially unreachable; the removal is belt-and-braces for the success path and load-bearing only for large/hostile bodies. That argues for keeping it: the diff is two lines inside a block being restructured anyway, and B-5 is preserved.

**But the change must be defended.** The `1` address is what makes the shape equivalent; drop it and `sed` prints *every* matching line, giving a multi-line `SB_VER`. Nothing in AC-6 as written detects that, because the design's success fixture has one `tag_name` line. C-1 and C-2 are binding.

### A-3 · B-8 in T-11 after D-4 weakened reason 1. **SHIPS. No fifth deferral.**

The PM is right that reason 1 is weakened: with no new key, the check is no longer *this task's own* verification instrument for a string the task introduces. Both answers were defensible; I land on shipping.

- **Reason 1 is weakened, not void.** B-7 binds *reused* strings too ("whether reused or newly introduced"), and AC-8 states parity as a product property. The check is the only committed, mechanical witness for AC-8, and it is what makes AC-5's zh assertions reproducible after the throwaway harness is deleted.
- **An independent standing justification exists that does not depend on reason 1.** `rejected-decisions.md:75-86` (`t-fmt-default-fallback`) declines the cheap mitigation and records that "**the structural fix is a committed key-parity gate**". That is the project's own position on a hazard recorded at `.harness/insight-index.md:10`. Shipping the gate discharges a decline the project already made — re-homing filed scope, not inventing scope, so red line 3 of rule 25 is not engaged, and rule 85's "name the future edit it prevents" is answered concretely: a future task adding a `t()` key to one table only, which aborts the whole installer the first time anyone answers `2`.
- **The overturn condition demonstrably did not fire.** I checked §5.2's parser assumptions against `install.sh:139-238`: the column-0 anchors are exact, every `fmt=` line yields a key, attribution is never used. The judgment is behavioural — sourcing the fragment and rendering under `set -u` reproduces L10's *actual* failure mode. That is not a fragile parser.
- **Cost is bounded and reversible**: one ~60-line script reading one file, no new dependency, one replaced line inside a preserved custom-marker block.

Counterweights accepted: D-2's **reason 3 is misapplied** (F-6), and the diff now touches `.harness/scripts/`, which T-07 nominally owns. Neither is decisive against three surviving reasons.

**Guard:** the check must never become the thing that fails delivery. C-13 is the escape hatch — if it cannot be made green against the unmodified `install.sh` inside the developer's budget, defer a **fifth, reasoned** time with a record appended to `ruleset-unit-tests-in-t02` (that file's contract is one record per concept, so append — do not open a new handle). Weakening the check to make it pass is forbidden.

### A-4 · R-g — AC-12's permitted-diff list. **WIDENED (gate ruling).**

AC-12 is hereby widened. The complete permitted shipping diff for T-11 is exactly:

1. `install.sh`
2. `CHANGELOG.md`
3. `.harness/scripts/check-i18n-parity.sh` (new)
4. `.harness/scripts/verify_all.sh` (B.2 line only, inside the `HARNESS:B-CUSTOM` markers)
5. `docs/tasks.md`
6. `docs/dev-map.md`
7. `CONTEXT.md` (the two stage-1 glossary terms already in the working tree)
8. `docs/features/install-version-query-abort/`
9. **`.harness/rejected-decisions.md`** — D-5 (GitHub API authentication, declined) and §3.5's `installer-early-exit-download-helper` (declined), plus a closing note on the existing `installer-version-query-silent-abort` record stating T-11 resolved it
10. **`.harness/rules/50-singbox-cli.md`** — the single stale sentence at `:36-38` (C-11)
11. **`.harness/insight-index.md`** and `docs/features/_archived/` — **delivery tooling only** (`archive-task.sh` appends harvested insights and moves the folder). No stage may hand-edit `insight-index.md`.

Anything outside this list is a review failure. `verify_all.ps1`, `baseline.json`, `bin/sc`, `systemd/`, `uninstall.sh`, `README*.md` stay untouched.

### A-5 · PM-2 — stage 1's `CONTEXT.md` edit. **UPHELD.**

I read the file. Both terms follow the existing three-part shape, the diff is additive, and `stated outcome` is load-bearing: I used its definition — not my own reading — to adjudicate A-1. A glossary whose central term is undefined while two documents build obligations on it is the drift `CONTEXT.md` exists to prevent. `assignment abort` likewise names the mechanism R-1/R-3 will reuse. Declared in AC-12, so not slipped in. No revert. One note: the entry's "a run that ends without one is a defect regardless of why it ended" is consistent with D-7 only because R-3 is an *open defect row*; it must not later be quoted as evidence that the guarantee already holds.

### A-6 · PM-1 — the F.6 WARN (549-line requirement doc). **UPHELD. No compaction.**

Verified mechanically: `verify_all.sh:223-231` skips any path containing `/_archived/`, and `archive-task.sh` moves the folder there, so the WARN clears by construction at delivery. F.6 is WARN-only by design (rule 70), AC-3's gate is "0 FAIL", and the alternative — a fresh agent rewriting a 549-line document that is now the binding contract for 15 acceptance criteria — risks silently dropping binding content for cosmetic gain. That trade is not close. Stages 3-7 keep their own docs ≤500 lines (this one does). Operational note for delivery: `verify_all.sh` **exits 1 when `warns > 0`**, so a non-zero exit must not be read as failure while F.6 stands.

### A-7 · Verifiability under the safety rule. **SUFFICIENT, after C-3, C-6, C-7.**

§6 is the strongest part of the design: fragment extraction, a stubbed `curl` first on `PATH`, `LANG_CHOICE` assigned directly (the only honest way to reach the zh table without an interactive prompt), `$TMP`-only writes, and a refuse-to-run denylist. I checked the denylist against the post-change block `:373-383`: it contains none of the denied tokens and exactly two `fi`, so the harness runs on the intended fragment and refuses on an over-run that reaches `tar` / `install -m`.

Three gaps, all closable:

- The **end anchor collides**: the first `t fetching_item` *in the file* is `install.sh:344`, above the block. A `sed` range from `/SB_VER=/` is safe; a `grep -n | head -1` implementation is not (C-6).
- The denylist omits **`sing-box`** — exactly L13's incident class (a test executing the installed binary); `:392` runs `sing-box version` nine lines below the block's end. It also omits the six package-manager binaries, `/var/`, `rm -rf`, `cat >` and `python3` (C-7).
- Nothing asserts the **stub was actually invoked**. If `$TMP/bin` fails to lead `PATH`, `transport` mode reaches the real GitHub API and the assertions may still pass for the wrong reason (C-3).

With those three, five failure modes × two languages is genuinely sufficient: the driver reproduces the exact statuses (`6`, `22`, `0`) and bodies that distinguish the modes, and the zh table is reached through the same variable the installer sets.

### A-8 · Vacuous-green risk. **Five criteria (plus E-10) can pass without proving anything.**

| Criterion | How it goes vacuously green | Non-vacuity guard |
|---|---|---|
| **AC-6** | The success fixture has one `tag_name` line, so `sed -n '1s…p'` and an unaddressed `sed -n 's…p'` produce identical output. AC-6 cannot detect a dropped `1` address — the single highest-risk regression in the diff. | **C-2**: fixture with ≥2 `tag_name` lines; assert the captured `SB_VER` is exactly one line and byte-equal to the HEAD-fragment run. |
| **AC-5** | "Every asserted line non-empty and contains no `unbound variable`" is **also true of an English run**. A driver that silently ignored `LANG_CHOICE` would pass. | **C-4**: assert the zh literals `下载失败` / `请检查网络后重试`, and that zh stdout ≠ en stdout for the same `STUB_MODE`. |
| **AC-7** | The mutant legs assert "expect 1". `exit 2` ("cannot decide") is also non-zero — a checker that chokes on the mutated file would read as detection. | **C-5**: assert status **== 1** exactly, and that the mutated key's name appears in stdout. Add an en-side mutant: the two tables are different `t()` branches. |
| **AC-8** | It is AC-7's PASS leg restated. A checker that always exits 0 satisfies AC-8. | **C-5**: AC-8 is discharged **only** if all three AC-7 mutants returned 1; state the dependency in the test report. |
| **AC-3** | A delta read against a non-pristine baseline (L26's worktree trap) proves nothing about which steps moved. | **C-12**: baseline is a **clone**; assert `git -C <clone> status --porcelain` empty, B.2 `SKIP` there and `PASS` in the changed tree, F.6 the only other delta. |
| **E-10** | If E10a and E10b both succeed, "the removal was precautionary" is a valid reading only if the input really overflowed the pipe buffer. | **C-8**: assert grep's output exceeds 64 KiB before concluding anything; otherwise record *inconclusive*. |

AC-4 is not on this list: it asserts a specific rendering plus the absence of the `SB_VER=[…]` echo, which is a real discriminator — provided C-3's stub witness holds.

### A-9 · E-10 deferred to stage 4. **ACCEPTABLE.**

The design's shape does not depend on E-10's outcome in either direction, and BC-5 forbids letting it. The only part with teeth is E10b's stop rule (does `sed -n '1s…p'` still yield `1.10.0` on a large input), and that is a *pre-edit* check — cheap, no root, no network — and stage 4 is the first stage able to run it. Forcing it earlier only re-homes it to a second PM pre-flight for no information gain. Binding: it runs **before** `install.sh` is edited (C-8), and its conclusion is governed by the non-vacuity guard above. AC-6 with C-2's multi-line fixture independently covers the same functional ground, so E-10 is evidence, not a single point of failure.

## 4. Findings

| # | Finding | Owner | Severity |
|---|---|---|---|
| F-1 | The sweep says "11 command substitutions"; `install.sh` has 11 **sites** but **12** substitutions — `:318` nests `$(dirname …)` inside `$(cd … \|\| echo "")`. AC-13 ("row count equals the number of such substitutions in the changed file") fails against a mechanical `$(` count. Requirement §2.3 and design §4 share the miscount. | requirement-analyst / solution-architect | WARN — resolved by ruling C-9, no rollback |
| F-2 | §6.2's end anchor "the first line matching `t fetching_item`" matches `install.sh:344` first, above the block. | solution-architect | WARN — C-6 |
| F-3 | §6.3's stub has no invocation witness; a `PATH` mistake silently reaches the real network and can still pass the assertions. | solution-architect | WARN — C-3 |
| F-4 | BC-4 describes a HEAD branch ("still semver-like → the run proceeds") that is unreachable: the non-matching passthrough carries leading whitespace, so `^[0-9]+\.[0-9]+` can never match. | requirement-analyst | INFO — makes B-5 easier; no action |
| F-5 | Design §3.3 says curl's raw stderr line sits "below" the localized statement; it is emitted **first**. | solution-architect | INFO — wording; do not reorder anything |
| F-6 | D-2 reason 3 cites rule 50's bilingual-parity ask, but rule 50 `:131-132` asks for it in **`bin/sc`**, which O-9 excludes. Reason 3 does not support B-8 as scoped. (B-8 survives on `t-fmt-default-fallback` + rule 50 `:36-38`.) | requirement-analyst | WARN — recorded, non-blocking |
| F-7 | Shipping B-8 makes two governing documents false: `docs/dev-map.md:22-23` and `.harness/rules/50-singbox-cli.md:36-38` both state B.2/B.3 are still SKIP. Rule 50 `:40-41` records that this exact stale claim has already propagated once. Neither is in the design's edit plan; rule 50 is not in AC-12 at all. | solution-architect (plan) / gate (AC-12) | WARN — C-10, C-11 |
| F-8 | AC-6 as specified cannot distinguish `1s…p` from an unaddressed `s…p` (single-line fixture). | requirement-analyst / solution-architect | WARN — C-2 |
| F-9 | AC-7 accepts any non-zero status as detection, conflating `exit 1` with `exit 2`. | requirement-analyst | WARN — C-5 |
| F-10 | AC-5's zh assertions are satisfied by an English run. | requirement-analyst | WARN — C-4 |
| F-11 | §6.2's "exactly two `fi`" is unqualified; a substring match would miscount. | solution-architect | INFO — C-7 |

No FAIL. Every WARN is discharged by a numbered condition below; none requires reopening an upstream document, and no condition changes the design's shape.

## 5. Questions the developer will ask — pre-answered

1. **"Can I keep `head -1` and just add the `if`?"** No — C-1. It reintroduces the SIGPIPE → `pipefail` → wiped-`SB_VER` path that would report a *successful* fetch as failed (BC-5/B-6). The `1` address in `sed -n '1s…p'` is what preserves `head -1`'s "first line only" semantics; dropping it yields a multi-line `SB_VER`.
2. **"Should I call `install_report()` so the run ends with the standard banner?"** No — A-1. It would print six statements that are false or useless at step 2 and would break AC-11. The two `t` calls plus `exit 1` *are* the stated outcome under `CONTEXT.md`'s definition, and D-6 keeps the status at 1.
3. **"May I add a `fail_download()` helper — three call sites is a real seam?"** No. §3.5 declined it; re-homed as R-5. It would pull `:346-348` and `:385-387` into the diff and weaken the line-by-line audits AC-9 and B-5 rest on. Record the decline in `rejected-decisions.md`.
4. **"May I add a `version_query_failed` key so the message is precise for the interstitial case?"** Not needed, and not free. D-4 resolved to reuse; §3.4's judgement against B-4 holds. If you nonetheless find a rendering you believe is false, stop and say so rather than adding a key quietly — a new key changes B-7/AC-8's surface and must be added to **both** tables at the same relative position.
5. **"Can the parity check just diff the two `case` blocks?"** No — that is the fragile parser PM-3's overturn condition names. Keep §5.2's behavioural render: source the extracted `t()` under `set -u` and call every key in each language. A missing key must fail because `printf` dereferences an unset `fmt` — the production failure mode itself, not a proxy.
6. **"`verify_all` still exits 1 after my change — did I break it?"** No: it exits 1 whenever `warns > 0`, and F.6 (stage 1's 549-line doc) is a known, attributable, self-clearing WARN (A-6). The gate is 0 FAIL. Expected summary after the change: **PASS 16 / WARN 1 / FAIL 0 / SKIP 1**.
7. **"May I run `install.sh` once in a container to be sure?"** No. §6's rule is absolute: `install.sh` is never executed, in whole or in part, by any stage of this task. The fragment harness plus the refuse-to-run denylist is the only sanctioned route (L13).

## 6. Binding conditions on stage 4 (checkable by stages 5-6)

- **C-1** The extraction pipeline contains no early-exiting reader: no `head`, no `grep -m1`, no `sed …q` in the changed block, and the `sed` expression is exactly `sed -n '1s/.*"v\([^"]*\)".*/\1/p'` — the `1` address and the `p` flag both present.
- **C-2** AC-6's success fixture contains **≥2** lines matching `"tag_name"`. Assertions: the captured `SB_VER` is a single line, equals `1.10.0`, and is byte-equal between the HEAD fragment and the changed fragment; the `t fetching_item` line is byte-identical between the two runs in both languages.
- **C-3** The `curl` stub appends one line to `$TMP/stub.log` per invocation. Every AC-4/AC-5 result asserts the log grew by exactly 1 and that `command -v curl` resolves inside `$TMP/bin`. A run where it does not is void, not a pass.
- **C-4** AC-5 asserts the zh literals `下载失败` and `请检查网络后重试`, and that zh stdout differs from en stdout for the same `STUB_MODE`.
- **C-5** AC-7 asserts exit status **exactly 1** on each mutant (never merely non-zero — `exit 2` is "cannot decide") and that the offending key name appears in stdout. **Three** mutants: key deleted from zh only, key deleted from **en** only, one `%s` removed from one language's `fail_status`. AC-8 is recorded as discharged only if all three returned 1.
- **C-6** The harness extracts the block as a `sed` range starting at `/SB_VER=/`, so the end anchor cannot bind to `install.sh:344`. It then asserts the fragment is non-empty, **≤20 lines**, and contains `download_failed`; otherwise it refuses to run.
- **C-7** The §6.2 denylist additionally rejects: `sing-box`, `apt-get`, `dnf`, `yum`, `pacman`, `zypper`, `apk`, `/var/`, `rm -rf`, `cat >`, `python3`. The "exactly two `fi`" test matches whole lines (`^[[:space:]]*fi$`).
- **C-8** E-10 runs **before** `install.sh` is edited. Its stop rule stands: if E10b does not print `V=[1.10.0]` with exit 0, stop and report without editing. The probe first asserts grep's output exceeds 64 KiB; if it does not, both legs are recorded **inconclusive**, not "precautionary".
- **C-9** AC-13 is discharged against substitution **sites**: 11 rows = 11 sites. The §4 row for `install.sh:318` gains an explicit mention of the nested `$(dirname …)` so no substitution is silently dropped (B-12's actual purpose). A raw `$(` count is **12** in code and must not be used as the criterion. `04_DEVELOPMENT.md` records this ruling.
- **C-10** The shipping diff matches A-4's eleven-item list exactly. `git status --porcelain` and `git diff --stat` are pasted. `verify_all.ps1`, `baseline.json`, `bin/sc`, `systemd/`, `uninstall.sh`, `README*.md` unchanged.
- **C-11** The two stale sentences are corrected in the same commit: `docs/dev-map.md:22-23` and `.harness/rules/50-singbox-cli.md:36-38` ("B.2 (tests) and B.3 (lint) are still SKIP"). B.3 remains SKIP; only the B.2 claim changes. Minimal edit — no other line of rule 50 is touched.
- **C-12** AC-3's baseline is a **clone**, with `git -C <clone> status --porcelain` empty. The delta is asserted step-by-step: B.2 `SKIP`→`PASS`, F.6 `PASS`→`WARN`, every other step identical. Expected summary: PASS 16 / WARN 1 / FAIL 0 / SKIP 1. `verify_all`'s exit 1 (warns>0) is not a failure.
- **C-13** If `check-i18n-parity.sh` cannot be made green against the **unmodified** `install.sh` within the developer's budget, defer a fifth, *reasoned* time: append the reason to the existing `ruleset-unit-tests-in-t02` record (do not open a second handle), revert the `verify_all` B.2 edit, and record B-8/AC-7/AC-8/BC-16 as not discharged. Weakening the check to make it pass — narrowing the key list, tolerating exit 2, skipping a language — is forbidden.
- **C-14** AC-11 holds with no exception: `install.sh:24-29`, `:243-288` and `:518` are byte-identical to HEAD. The reviewer diffs those three ranges explicitly.
- **C-15** AC-14's witness is captured at **three** checkpoints (development start, development end, QA end) and each reading is pasted: baseline `MainPID=2500438`, `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST`. `systemctl is-active` is not a valid witness.
- **C-16** The three `rejected-decisions.md` records are written at delivery: D-5 (GitHub API authentication — declined, with the "an authenticated call still fails on DNS, 5xx and behind a captive portal" reasoning), `installer-early-exit-download-helper` (declined, re-homed as R-5), and a closing line on `installer-version-query-silent-abort` naming T-11 as its resolution.
- **C-17** `CHANGELOG.md` does not claim the installer now always states its outcome (D-7). R-1…R-6 are filed in `docs/tasks.md`; R-6 records the `verify_all.ps1` mirror divergence explicitly.

## 7. Verdict

The premise is empirically established (E-0 7/7, E8, E9), the fork is decided correctly and for reasons that survive independent checking against the source, the fix has an exact written shape whose success path I re-derived as byte-equivalent, all five failure modes converge on one handler, the safety posture is the strongest this project has produced, and the scope boundaries are explicit with every declined item re-homed rather than dropped. The defects I found are verification defects — five criteria that could have gone vacuously green, one harness anchor collision, one miscount and two stale sentences — not design defects, and each is closed by a numbered condition without reopening an upstream document.

**APPROVED FOR DEVELOPMENT** — subject to binding conditions C-1 … C-17.
