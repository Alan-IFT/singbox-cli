> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `/home/alan/Programs/singbox-cli/.harness/scripts/restricted-network-regression.sh` (330 lines, re-read whole)
- `/home/alan/Programs/singbox-cli/docs/features/restricted-network-regression-test/04_DEVELOPMENT.md`
- `/home/alan/Programs/singbox-cli/docs/features/restricted-network-regression-test/04_RATIONALE.md` (§8, §9, §10 — T5.2, adjudicating D-6)
- `/home/alan/Programs/singbox-cli/docs/features/restricted-network-regression-test/01_REQUIREMENT_ANALYSIS.md` (FR-9…FR-14, BC-9…BC-13)
- `/home/alan/Programs/singbox-cli/docs/features/restricted-network-regression-test/02_SOLUTION_DESIGN.md` (K-9…K-13, V-16, V-17)
- `/home/alan/Programs/singbox-cli/bin/sc` (read-only: `:105-125`, `:3237-3331`)
- `/home/alan/Programs/singbox-cli/install.sh` (read-only: `:575-616`)
- `/home/alan/Programs/singbox-cli/.harness/rules/70-doc-size.md` (section list only)
- Round 1 also reviewed and unchanged since: `docs/dev-map.md:79-80`, `.harness/rejected-decisions.md:483-495`, `CONTEXT.md:156-161`, `.gitignore`, `.harness/scripts/verify_all.sh`

## Findings

| id | severity | axis | file:line | finding |
|---|---|---|---|---|
| CR-2 | MINOR | Standards | `.harness/scripts/restricted-network-regression.sh:1-330` vs `02_SOLUTION_DESIGN.md` K-10 | Rule-85 judgment **re-stated against 330 lines**: still earned, still no refactor demanded. The round-2 additions are +13 lines (4 for BC-9's E3/E4 guard, 9 for E5's agreement arm) and both earn their lines — one closed a MAJOR vacuous green, the other closed the last condition that agreed rather than constrained, and 4 of its 9 lines are the comment (`:269-272`) recording why the obvious one-line test is a no-op, which is the single most re-derivation-prone fact in the file. The binding floor is now 267 (28 mandated I-15 guide + 239 code at zero comments and zero blanks) against a 250 cap, so the cap remains unreachable without dropping a contract element. Defect is the cap's provenance, not the artifact. Owner: stage 7 (RES-5); no code change. |
| CR-7 | MINOR | Spec/design | `.harness/scripts/restricted-network-regression.sh:311-312` | Unchanged from round 1. E4's five clauses are four absence assertions plus `sing-box check` exit 0, and `sing-box` accepts a near-empty document — E4 cannot distinguish a correctly degraded config from one that defines nothing. FR-7/V-15 as written ask for exactly this, so the artifact is contract-faithful and the gap is upstream. E1, E5 and E4's now-non-vacuous `pair=` constrain it in practice. Recorded, not to be fixed here. |
| CR-9 | NIT | Standards | `.harness/scripts/restricted-network-regression.sh:57` | Unchanged from round 1, re-verified at current line numbers. GC-6 holds by reading: no `mktemp -d`, no `cp`, no `>`/`>>` on the argv, `--self-check` or either refusal path; the first is `mktemp -d` at `:187`. Strictly, `usage()`'s here-document makes bash create and immediately unlink a temp file under `$TMPDIR`; immaterial, and inside AC-3's "its own temporary area". |
| CR-10 | NIT | Standards | `.harness/scripts/restricted-network-regression.sh:101`, `:105`, `:195`, `:248` | Unchanged from round 1. `for b in $BASES` / `for h in $HOSTS` / `printf '%s\n' $list` are unquoted word-splits that also glob. Correct for the four shipped bases, but `--self-check --source FILE` accepts an arbitrary list, so a base carrying `[`, `*` or `?` would be silently transformed. `set -f` at the top closes it. |
| CR-12 | NIT | Standards | `.harness/scripts/restricted-network-regression.sh:323-324`, `:247-251` | Unchanged from round 1, re-verified at current lines. `[ "$rr" != 0 ]` / `[ "$rdn" != 0 ]` are string tests that would accept `?`, but the sibling `[ "$rd" = 4 ]` rejects the `?` triple `cfg_facts` emits as a unit; and with a missing log `nfail=0` makes the `nbase` loop report `bases_named=4` in `obs=`, which the mandatory `[ "$nfail" -eq 4 ]` clause then rejects. Misleading-in-`obs=`, never verdict-bearing. |
| CR-13 | MINOR | Spec/design | `.harness/scripts/restricted-network-regression.sh:299-300`, `:308-309` | **New, and the inverse hazard of CR-1.** `rblock` is tested *before* each condition's own verdict, so when the recovery arm reached no source, E3 and E4 report `BLOCKED` even in states where their own blackout-arm observation is already falsified: `nolog≥1` (which `BC-10` names as `E3 FAIL` in so many words) becomes BLOCKED at `:299`, and a genuine E4 failure (`mode=644`, an unparsable document, `sing-box check` non-zero) becomes BLOCKED at `:308`. On a no-egress VM — the configuration that produced CR-1 — every E3/E4 product failure would read as a harness excuse. Never a false green (`finish` exits 1 on any non-PASS), so MINOR. E5 carries the correct shape at `:273` (`[ "$st" = PASS ] && [ "$agree" -eq 0 ]`) and E3/E4 do not; mirroring it is one line each. Contract collision, honestly resolved toward K-11's letter ("a condition whose `pair=` value could not be taken is BLOCKED") against BC-10's `FAIL`; K-11 is the more recent and more specific statement, so this is not a violation, and BC-10's arm is unreachable in this artifact by design. |
| CR-14 | NIT | Spec/design | `.harness/scripts/restricted-network-regression.sh:293-294` | The `nok=0, nrf=0` sub-case — `sc update-rules` died before its first fetch, i.e. a **product** crash — is labelled `unproven;no_reachable_source`, attributing a product failure to the network. Both discriminators are in hand at `:293` (`urc` non-zero with `nrf=0` cannot be a reachability outcome). E6's `obs=` does carry `urc=` and `ok_lines=` one line down, so the information is on screen; the reason token merely points the wrong way. A third token would cost one line. |
| CR-15 | NIT | Standards | `.harness/scripts/restricted-network-regression.sh:68`, `:278` | The CR-3 fix introduced one side effect: `die` calls `unmet_all`, which overwrites **all six** entries, so a `die` on the `/etc/hosts` restore at `:278` discards E1, E2 and E5's already-composed real verdicts and reprints them as `UNMET obs=fatal:cannot_restore_/etc/hosts`. Exit is 1 either way and the three earlier `die` sites (`:187`, `:190`, `:193`) run before any entry is set, so only this one path loses evidence. `unmet_all` filling only unset entries would keep it. |

## Requirement coverage check

| criterion | implementation | status |
|---|---|---|
| AC-1 tracked, not ignored | `.gitignore` matches no path under `.harness/scripts/`; mode `0755` per `04_DEVELOPMENT.md` C-1 | ✅ ignore half verified here; `git ls-files`/`100755` half is V-1, stage 6 |
| AC-2 parses, counts unchanged | no F.* cap covers `.harness/scripts/`; A.1 excludes `.harness/*`; `verify_all` re-measured `PASS 17 / WARN 0 / FAIL 0 / SKIP 1` after the round-2 edits | ✅ |
| AC-3 no token ⇒ exit 2, no write | `:138` `*) usage`, `:66` `exit 2`; no filesystem write before `:187`, and no round-2 edit sits before it | ✅ |
| AC-4 token + configured install ⇒ refuse | `:151-156`, gate 2 before gate 3, `finish 3` | ✅ |
| AC-5 self-check covered / uncovered arms | `:110-121`, `:144`, `:92` `uncoverable` | ✅ |
| AC-6 E1 | `:206-225` | ✅ implemented; unrun `[VM]` |
| AC-7 E2 | `:226-235`; `install.sh:582-583`, `:597` confirm both units reach the asserted state | ✅ implemented; unrun `[VM]` |
| AC-8 E3 | `:236-251`, `:297-306` | ✅ implemented; unrun `[VM]` — see CR-13 |
| AC-9 E4 | `:252-255`, `:307-314` | ✅ implemented; unrun `[VM]` — see CR-7, CR-13 |
| AC-10 E5 | `:258-275` | ✅ **was ⚠️ in round 1**; `active` now requires two agreeing non-zero `MainPID` reads, else BLOCKED (D-6) |
| AC-11 E6 | `:279-289`, `:315-326` | ✅ implemented; unrun `[VM]` |
| AC-12 every condition has a same-run counter-observation | twelve `obs=`/`pair=` fields; **five** BLOCKED arms (`:220`, `:274`, `:299`, `:308`, `:318`); BC-9 reason computed once at `:293-294` and gating E3, E4 and E6 | ✅ **was ❌ MAJOR in round 1 (CR-1)**; the vacuous `pair=` is unreachable and a correct run — including a partial recovery — still reaches PASS |
| AC-13 populated rule-set dir ⇒ UNMET | `:171` | ✅ |
| AC-14 two dev-map rows | `docs/dev-map.md:79`, `:80` | ✅ (E5's clause updated for D-6) |
| AC-15 operator guide, Chinese | `:2-28`: preconditions 1-7, VM prep, invocation with verbatim token, single-use sentence | ✅ |
| AC-16 frozen product files | no ledger row touches them; nothing in the artifact writes them; PM re-measured the diff as ledger-confined | ✅ per reading; byte-identity is V-8, stage 6 |
| AC-17 `baseline.json` unchanged | not referenced by the artifact or any C-row | ✅ per reading; V-9 is stage 6 |
| AC-18 live instance untouched | live-service witness (`MainPID`, `ActiveEnterTimestamp`) and `/etc/hosts` sha256 identical across task start, round-1 end and round-2 end | ✅ this stage executed nothing |
| AC-19 `[VM]` criteria BLOCKED in the report | — | stage 6 |
| AC-20 six lines, exit derived | `:73-80` `finish`, verified for exit 0/1/2/3; **all four `die` paths now emit them** (`:68` `unmet_all` + `finish 1`), verified at `:187`, `:190`, `:193`, `:278` | ✅ **was ⚠️ in round 1 (CR-3)** — see CR-15 for the one side effect |

## Design fidelity check

| design item | implementation | status |
|---|---|---|
| C-1 new artifact, `0755` | `.harness/scripts/restricted-network-regression.sh`, 330 lines | ✅ (line cap: CR-2) |
| C-2 two dev-map rows, nothing else changed | `docs/dev-map.md:79-80` | ✅ |
| C-3 rejected-decisions record | `:483-495`, decision + why + origin | ✅ |
| C-4 `CONTEXT.md` `**blackout**` entry | `:156-161`, 2 sentences + `_Avoid_` | ✅ |
| C-5 stage-4 document | present with rationale sibling | ✅ |
| no file edited without a ledger row | only the four above carry the artifact's name | ✅ |
| I-1…I-4 invocations, exits | `:42`, `:56-67`, `:136-148` | ✅ (I-1 wording now declared: D-7) |
| I-5 six-line report | `:69-80` + `:68` | ✅ **round-1 ⚠️ cleared** |
| I-6 textual derivation, never imports `bin/sc` | `:88`; re-verified against `bin/sc:113-118` — the `sed` range plus `grep -oE 'https?://[^"]+'` yields exactly the four bases, base 3 whole (its embedded second URL is not split off) | ✅ |
| I-7 blackout set + uncoverable predicate | `:92`, `:96-107`; 6 hosts from 4 bases + 3 names | ✅ |
| I-8 hosts block, byte restore | `:190-193`, `:278` | ✅ |
| I-9 resolver proof | `:194-202` | ✅ |
| I-10 `cfg_facts` counts only | `:123-134` | ✅ (separator now declared: D-8) |
| I-11 / I-12 / I-13 / I-14 records | `docs/dev-map.md:79-80`, `rejected-decisions.md`, `CONTEXT.md` | ✅ |
| I-15 guide, only Chinese in the file | `:2-28`; everything below `:30` English | ✅ |
| K-1 `set -uo pipefail`, no `set -e`, four `\|\| die` | `:40`; `die` at `:187`, `:190`, `:193`, `:278` — still exactly four, none moved before a gate | ✅ |
| K-2 no status-consulted `$(cmd\|grep)`; captures under `$WORK` | `:98-100` takes emptiness as the datum; the pipelines at `:117`, `:119`, `:249-250` feed string comparisons only; `irc` `:206`, `ccheck` `:255`, `urc` `:283` explicitly captured; every redirect targets `$WORK`, `/etc/hosts` or `/dev/null` | ✅ |
| K-3 gate order token → node store → root → preconditions | `:138-148` → `:151` → `:157` → `:163-175`; every round-2 edit is at `:68` (a function whose four call sites are all past gate 4) or past `:255` | ✅ |
| K-4 writes only `$WORK` + `/etc/hosts` | no other write target; no `uninstall.sh`, no unit removal, no `resolv.conf`/firewall | ✅ |
| K-5 presence-only matching | every assertion is `grep -q`/`grep -c`; no `head`, `tail`, line number or adjacency test | ✅ |
| K-6 `printf '1\ny\n'` | `:206` | ✅ |
| K-7 ≤30 s of own waiting | 10 × 1 s (`:259`) + 5 × 1 s (`:285`) = 15 s; the round-2 edits added no `sleep` | ✅ |
| K-8 no document byte printed | counts, modes, statuses, matched markers only; `sing-box check` output to `$WORK/check.out`, never read back | ✅ |
| K-9 `SB_RULES_BASE` unset | `:168` | ✅ |
| K-10 ≤250 lines | 330 | ⚠️ recorded under GC-9 / D-2 — CR-2, judged earned |
| K-11 `pair=` discipline, BLOCKED never PASS | `:69`, five BLOCKED arms, BC-9 at `:293-294` | ✅ **round-1 ❌ MAJOR cleared** — see CR-13 for the BLOCKED-over-FAIL precedence |
| K-12 `[6/7]` fixed-string step-6 guard | `:209` `grep -qF` | ✅ |
| K-13 nothing wired into `verify_all`, no `.ps1` | neither file names the artifact; no `.ps1` sibling | ✅ |
| GC-1 E1's `pair=` separates degraded from healthy | `:215`, `:219-225`; `s6w=0` ⇒ BLOCKED | ✅ discharged, no regression at new lines |
| GC-2 every marker match fixed-string | `:209`, `:214`, `:215`, `:238-242`, `:249-250`, `:284` all `-qF`/`-cF`; the only two regexes are the `:88` extractor and the `:197` resolver anchor | ✅ discharged |
| GC-3 E6 requires non-zero `dns_refs` | `:324` `[ "$rdn" != 0 ]` (moved from `:311`) | ✅ discharged |
| GC-4 E5 read at the end of the window | `:258-266`, `:268`; `prev5=""` still makes the first positive read unbreakable, and `agree` is set only at the break (`:263`) | ✅ discharged, strengthened |
| GC-5 self-check prints list **and** count | `:117-120` | ✅ discharged; the printed-vs-source comparison is RES-3 |
| GC-6 nothing created before the four gates | first `mktemp -d` still `:187`; `die` writes nothing and no `die` site precedes it; no `cp`/`>`/`>>` earlier on any path | ✅ discharged, re-verified after the `die` change |
| GC-7 repo root from own path | `:50-51`; `git` occurs only at `:17`, `:19` (guide) and `:48` (the comment saying why not) | ✅ discharged |
| GC-9 overrun recorded, nothing dropped | D-2 updated to 330 with the 267 floor; round 2 added elements and dropped none | ✅ discharged |
| GC-10 code side: nothing can touch this host | gate 2 at `:151`; the artifact never imports, sources, executes or `python3`-loads `bin/sc`; the only `/usr/local/bin/sc` invocation is `:283`, 132 lines past gate 2 | ✅ discharged |
| D-1 ledger interface-id off-by-two | documentation-only | accepted as shipped |
| D-2 330 lines vs 250 | recorded under GC-9 | accepted as shipped — CR-2 |
| D-3 entry-boundary base matcher | `:248-250`, verified against `bin/sc:3258-3284` | accepted as shipped — the fix is correct |
| D-4 `EXIT` trap restoring `/etc/hosts` | `:188`, after `mktemp -d`, guarded on `$WORK` non-empty **and** `hosts.orig` existing | accepted as shipped — net safety gain |
| D-5 extra gate-4 refusals | `:165-166`, `:170` | accepted as shipped — fail-closed |
| D-6 E5 requires two agreeing `MainPID` reads, else BLOCKED | `:258-275` | **accepted as shipped, and the round-1 named fix is withdrawn.** Verified on the code: the loop's tail `prev5="$p5"` (`:265`) makes `[ "$p5" = "$prev5" ]` true at *both* exits, so CR-5's named clause was a no-op and the developer's refutation is correct. The shipped `agree` flag is the well-formed test. Audited both failure directions: a correct quiet install PASSes on the second read (`install.sh:593` starts the service several observations earlier), and a dead service still reports FAIL, not BLOCKED |
| D-7 token spelled twice (`:42` constant, `:22` guide) | I-1 vs I-15 collision, resolved toward I-15 | accepted as shipped — CR-8 closed by the declaration |
| D-8 `cfg_facts` `;`-separated | `:123-134`; `obs=`'s field grammar requires it | accepted as shipped — CR-11 closed by the declaration |

## Axis status
- Standards-conformance: 5 findings (CR-2, CR-9, CR-10, CR-12, CR-15), worst = MINOR. Shell correctness re-verified after the edits and clean: `set -e` still absent, all three consulted statuses (`irc`, `ccheck`, `urc`) explicitly captured, no status-consulted pipeline assignment, no redirect into an unproven directory, `local` declarations all assigned before use under `set -u`, `i` correctly reused after the settle loop consumed it. Documented-convention conformance (AI-GUIDE, `.harness/rules/*`, cross-shell parity, dev-map) is clean; the one cap breach is K-10, adjudicated as earned.
- Spec/design-fidelity: 3 findings (CR-7, CR-13, CR-14), worst = MINOR. Round 1's only MAJOR (CR-1 / AC-12 / K-11) is closed and verified in both directions; CR-3 and CR-6 are closed; CR-5 is withdrawn as refuted; CR-4's ruling is accepted; CR-8 and CR-11 are closed by D-7/D-8.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | **CLOSED.** CR-1's fix re-reviewed on the code before any `[VM]` run: `nok` is `-1` on every path where the recovery arm did not run and `0` only when it ran and matched no `OK (` line, so the `-lt 0` / `-eq 0` ordering at `:293-294` is exhaustive and non-overlapping; the vacuous `E3/E4 PASS` is unreachable, and `nok≥1` — including partial recovery — still reaches PASS with a genuinely differing `pair=`, because `bin/sc:3295-3303` regenerates the config whenever any rule-set is gained. | closed here; no downstream owner |
| RES-2 | AC-1's `git ls-files` + `100755` half, AC-16's clone-based byte comparison and AC-17 were verified by reading only; V-1, V-8 (a `git clone`, never a worktree — GC-11) and V-9 remain owed. Owner: stage 6. | `06_TEST_REPORT.md` |
| RES-3 | GC-5's second half, narrowed: the derivation expression at `:88` is now verified by reading against `bin/sc:113-118` in both rounds, so what stage 6 still owes is the character-for-character comparison of the four **printed** URLs in the actual `--self-check` transcript. Exit 0 alone cannot detect an under-matching derivation (F-6, unrepaired by design). Owner: stage 6. | `06_TEST_REPORT.md` |
| RES-4 | Three E5/E3/E4 behaviours are untestable `[HOST]` and must be read against the first real `[VM]` transcript: (a) the crash-loop residual the 1 s sampler leaves open — a restart cycle longer than ~2 s can still show two agreeing reads and PASS (D-6, acknowledged by the developer); (b) CR-13's BLOCKED-over-FAIL precedence at E3/E4 on a no-egress VM; (c) CR-4's BLOCKED-vs-FAIL vocabulary for `unknown`/`absent`/`?`. Owner: stage 6. | `06_TEST_REPORT.md` |
| RES-5 | The 250-line cap is unreachable by 17 lines at zero comments and zero blanks (measured floor 267 at 330 total); K-10's "target ≤235" was never achievable and the gate said so in F-11 before approving K-10 unchanged. Any future artifact of this class should be capped from the element list, not from a round number. Owner: stage 7. | `07_DELIVERY.md` |
| RES-6 | `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` (R-37; its sections remain What this is / When to read this / Caps / Process discipline / Adversarial check). Both rounds of this document applied the reviewer schema as written and routed the rule-85 argument to `05_RATIONALE.md`. Owner: stage 7. | `07_DELIVERY.md` |

## Verdict
APPROVED WITH RESIDUALS (0 CRITICAL, 0 MAJOR; 3 MINOR, 5 NIT open, none blocking; RES-2 … RES-6 travelling)
