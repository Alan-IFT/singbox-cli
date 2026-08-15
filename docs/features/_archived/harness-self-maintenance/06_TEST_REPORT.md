# 06 — Test Report · T-27 `harness-self-maintenance`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

## Test plan

Every run in this document was executed from `/home/alan/Programs/singbox-cli` (K-10, BC-10, C-8).
Every fixture lives under `test/t27/qa/` — a path `.gitignore:19` (`test/`) ignores — and every run
executed **that fixture's own copy** of the script (K-9, C-9), never `.harness/scripts/archive-task.sh`
itself. `HARNESS_ALLOW_OUTSIDE_RM` was never set; no service action, no write under `/etc/sing-box`
or `/var/lib/sing-box`, no `bin/sc` import (K-11). The fixtures are **mine**: built by
`test/t27/qa/build.py`, written from the acceptance criteria, not from stage 4's `mkfix.sh` — none of
stage 4's 25 fixture trees was reused or read for its expected values. `cand` = the working-tree
script (sha256 `558eaf1c07b0…`), `head` = `git show HEAD:.harness/scripts/archive-task.sh`
(sha256 `794279cc95f6…`), both copied into each tree.

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 30-line index + 3 harvested → ≤30 lines, 3 to history | `build.py ac1 {cand,head}` + wet run, `wc -l` before/after, history diff | `test/t27/qa/build.py` (`ac1`), `test/t27/qa/ac1-{cand,head}/` |
| AC-2 byte conservation, oldest rotated, header intact | `build.py ac2 cand` + `check_ac2.py` (independent re-implementation of the awk join) | `test/t27/qa/check_ac2.py`, `test/t27/qa/ac2-cand/` |
| AC-3 25 lines + 2 harvested → no rotation | `build.py ac3 cand` + wet run, `diff` of the first 25 lines | `test/t27/qa/ac3-cand/` |
| AC-4 exactly 30 + 0 harvested → byte-identical | `build.py ac4 cand` + wet run, sha256 before/after | `test/t27/qa/ac4-cand/` |
| AC-5 residual == `wc -l` − 30 on both clamp fixtures | `build.py ac5i {cand,head}`, `build.py ac5ii {cand,head}` + wet runs | `test/t27/qa/ac5i-*/`, `test/t27/qa/ac5ii-*/` |
| AC-6 wrapped bullet keeps continuation + `· evidence:` tag | `build.py ac6 {cand,head}` + wet run, `grep` the index line | `test/t27/qa/ac6-{cand,head}/` |
| AC-7 `--dry-run` writes nothing, states absolute `Rotated 3` | `build.py ac1 {cand,head}` + `--dry-run`, `snap.py` full-tree snapshot + one-byte positive control | `test/t27/qa/snap.py`, `test/t27/qa/ac1-{cand,head}/` |
| AC-8 `verify_all` untouched, F.4 unchanged, PASS 17 | `git diff -- .harness/scripts/verify_all.sh`; `sed -n '213,219p'`; `bash .harness/scripts/verify_all.sh` ×3 | repo root |
| AC-9 (a) unit routing 0/0, (b) 7 kinds vs witnesses | hand-routing spot-check of 8 units of the two archived pairs against the landed `70-doc-size.md:80-96`; C-11 witness re-read | `docs/features/_archived/{doctor-rows-establish-their-fact,ruleset-staleness-visibility}/` |
| AC-10 rule 70 ≤130, fragments ≤200, E.5 PASS | `wc -l .harness/rules/*.md`; verify_all F.2 + E.5 | repo root |
| AC-11 three delivery commits partitioned | `git show --name-only --pretty=format: {d849234,6d16caf,6c034d6}` partitioned against B-2 + product files | repo root |
| AC-12 trigger word-for-word in both homes | `sed -n '6,14p' .harness/rules/80-delivery-policy.md`; `sed -n '30p' AI-GUIDE.md`; HEAD control via `git show` | repo root |
| AC-13 drill from B-3's bytes alone | template copied read-only to `test/t27/qa/refresh/`; both checks run; *lost* action applied by `apply_lost_action.py`; AC-1 + AC-6 re-run | `test/t27/qa/apply_lost_action.py`, `test/t27/qa/{refresh-ac1,refresh-ac6,drill-ac1,drill-ac6}/` |
| AC-14 product diff / delivery writes | `git diff --numstat`, `git status --porcelain`, `git status --porcelain -- test/`, `git check-ignore -v` | repo root |
| AC-15 delivery run needs no hand-rotation | **not dischargeable at stage 6** (C-7/RS-4); pre-flight = RES-2 measurement + a simulation over a byte-identical **copy** of the real index | `test/t27/qa/ac15-sim/` |
| AC-16 metric not algorithm | `git diff -- .harness/scripts/archive-task.sh`; function count HEAD vs candidate; `echo`-line diff; per-entry invocation census | repo root |
| C-3 (i)(ii)(iii) divergence residuals | `build.py {c3i,c3ii,c3iii} cand` + wet runs, `wc -l` before/after, marker position, bullet conservation | `test/t27/qa/c3{i,ii,iii}-cand/` |

## Adversarial tests

One predicted failure per criterion, each with a reproducer I wrote from the criterion. Cited output
is ≤5 lines; full runs are in `06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | the rewrite emits one line more than the decision counted, so the "≤30" run actually lands at 31 | `bash test/t27/qa/ac1-cand/.harness/scripts/archive-task.sh --task fixture-task` (NEW) | **Survived** — `before: 30 lines` / `Rotating 3 old insight(s) to insight-history.md` / `after : 30 lines` / history holds 3 entries. HEAD control on a byte-identical index: `after : 33 lines`, `history exists: no` |
| AC-2 | a `- -n …` entry, a backslash entry or a `$VAR` entry is mangled by builtin `echo`, or the 402-byte line is reflowed | `python3 test/t27/qa/check_ac2.py test/t27/qa/ac2-cand …` (NEW, my own awk-join re-implementation) | **Survived** — `header sha256[16]: fa03a015032a5477 (pre) / fa03a015032a5477 (post)`, `longest pre line : 402 bytes; present after: True`, all three hostile entries `round-trip byte-identical: True`, `AC-2 OK` (exit 0) |
| AC-3 | the new unconditional `rotate_count=0` path still rewrites the file, changing bytes below the cap | `bash test/t27/qa/ac3-cand/.harness/scripts/archive-task.sh --task fixture-task` (NEW) | **Survived** — `after: 27; history exists: no`, `first 25 lines identical: yes`, last two lines are exactly the two harvested bullets |
| AC-4 | `index_lines == 30` is read as `> 30` (an off-by-one at the cap) and the file is rewritten | `bash test/t27/qa/ac4-cand/.harness/scripts/archive-task.sh --task fixture-task` (NEW) | **Survived** — `before: 30 sha=59fe2f678bb06c11` / `after : 30 sha=59fe2f678bb06c11`, no history file |
| AC-5 | the residual number is computed before the clamp, so it disagrees with `wc -l` − 30 on the clamp-to-zero fixture | two wet runs (NEW) | **Survived, digit for digit** — (i) `Over cap: 1 …` with `after : 31 lines; wc-l MINUS 30 = 1`; (ii) `Over cap: 3 …` with `after : 33 lines; wc-l MINUS 30 = 3`, printed although **nothing** was rotated. HEAD prints no such line on either fixture |
| AC-6 | the metric edit sits close enough to the harvest to disturb the `awk` join and drop the tag | `bash test/t27/qa/ac6-cand/.harness/scripts/archive-task.sh --task fixture-task` (NEW) | **Survived** — one index line: `26:- 2026-08-16 · a wrapped insight … and whose third line carries the tag · evidence: fixture-wrapped`; identical on HEAD (control) |
| AC-7 | `--dry-run` touches the index (the `touch`), or reports a *relative* count that matches HEAD's string | dry runs on both scripts over byte-identical trees + `snap.py` + a one-byte positive control (NEW) | **Survived and DISCRIMINATING** — candidate `  - Rotated 3 old insight(s) to insight-history.md`; HEAD `  - Rotated 0 old insight(s) to insight-history.md`; snapshot diff empty on both; control detected `size=1561` → `size=1562`, sha256 changed |
| AC-8 | the four edits perturb F.2 (rule 80 grew) or E.5, dropping the count below 17 | `bash .harness/scripts/verify_all.sh` ×3 from the repo root | **Survived** — `PASS: 17  WARN: 0  FAIL: 0  SKIP: 1`, exit 0, three times; `git diff -- .harness/scripts/verify_all.sh` empty; `verify_all.sh:215` still `n=$(wc -l < .harness/insight-index.md)` |
| AC-9 | some unit of the two archived pairs gets **two** destinations because the precedence clause and the bare test disagree | hand-routing 8 units of the T-26 `01_*` pair and the T-19 `02_*` pair against `70-doc-size.md:80-96` | **Survived** — 0 units with none, 0 with two; one unit (`01_RATIONALE.md:154` "Traps the fixtures must avoid") needed the precedence clause, not the bare test. C-11's routing re-verified first-hand: `01_RATIONALE.md:5-10` says *"routed to a later stage (contract OQ-8, BC-10, AC-1/AC-5/AC-9/AC-10)"* → **contract** |
| AC-10 | rule 80's +36 lines pushes some fragment past 200, or the new section past rule 70's 130 | `wc -l .harness/rules/*.md` + F.2/E.5 | **Survived** — `110 .harness/rules/70-doc-size.md`, `89 .harness/rules/80-delivery-policy.md`, 11 fragments, largest `178 .harness/rules/_ai-native-prompt.md`; F.2 and E.5 PASS |
| AC-11 | a path in one of the three delivery commits falls in neither list — the exact defect the task is fixing | `git show --name-only --pretty=format: d849234 6d16caf 6c034d6` | **Survived** — 75 paths, all in B-2 or in that task's product set (`bin/sc`, `CHANGELOG.md`, both READMEs, `docs/dev-map.md`). HEAD control: T-19's prose at `ruleset-staleness-visibility/01_REQUIREMENT_ANALYSIS.md:149` omits `CONTEXT.md` and `.harness/operator-obligations.md`, both of which appear → **HEAD fails** |
| AC-12 | the two trigger texts differ by a word, so a stage reading only `AI-GUIDE.md` gets a different trigger | `sed -n '11,12p' .harness/rules/80-delivery-policy.md` vs `sed -n '30p' AI-GUIDE.md` | **Survived** — both carry `when writing an acceptance criterion over the committed diff (stages 1-2)` and `after \`/harness-upgrade\`` byte-identically; `docs/batches/**` present at `80-delivery-policy.md:36`. HEAD: both homes are delivery-time only |
| AC-13 | B-3's record cannot be resolved from its own bytes — the *lost* action needs the deleted in-file note, or the resulting script still fails AC-1 | template copied read-only; both checks run; `apply_lost_action.py` (NEW) applied the metric row's action; AC-1 + AC-6 re-run | **Survived** — see `### AC-13 drill` below. Resulting script: AC-1 fixture `after wc -l = 30`, `history entries: 3`, exit 0; AC-6 fixture keeps continuation + `· evidence: fixture-wrapped`, exit 0 |
| AC-14 | a fixture path, or `docs/batches/**`, leaks into the product diff | `git status --porcelain`, `git diff --numstat`, `git check-ignore -v` | **Survived** — product diff is exactly the four E-1…E-4 paths; `git status --porcelain -- test/` empty; `git check-ignore -v test/t27/qa/build.py` → `.gitignore:19:test/` |
| AC-15 | the index does not end with a newline, so the delivery run lands at 31 and F.4 WARNs through no fault of E-1 (RES-2) | `wc -l` + `tail -c 1 … \| xxd`, then a wet run over a byte-identical **copy** | **Survived (pre-flight only)** — `tail -c 1` = `0a`, `wc -l` = **30**; simulation over the copy: `Rotating 3` → `after wc -l = 30 -> F.4 PASS`; repository index provably untouched (`git diff --numstat -- .harness/insight-index.md` empty, sha256 `e148278e434dfff7` unchanged) |
| AC-16 | the clamp line, being new, changed or reordered a report string, or added a per-entry subprocess | `echo`-line diff HEAD vs candidate; function count; invocation census | **Survived** — exactly one `echo` line added (the `Over cap:` residual, mandated by I-2); every pre-existing report line byte-identical; functions `0` → `0`; `wc -l` occurrences `0` → `1`, outside every loop |
| ADV-1 (RES-9) | an index entry occupying more than one physical line is hoisted into the header, producing a WARN shape C-3's three do not cover | `build.py adv-multiline cand` + wet run (NEW) | **Reproduced, no new WARN shape** — `before wc -l = 33` → `after wc -l = 30 -> F.4 PASS`, but the hand-edited continuation line moved from physical line **15** to line **9**. Same mechanism as C-3(iii); filed QA-2 |
| ADV-2 | a blank line left **between two entries** (the residue of a hand rotation) is silently deleted even though the file's final line is a bullet — outside C-3(iii)'s stated shape | `build.py adv-blankmid cand` + wet run (NEW) | **BROKE IT** — `before wc -l = 32` (`non-bullet=9`) → `after wc -l = 29` (`non-bullet after = 8`), F.4 **PASS** over a file that lost a line, final line still a bullet. A **fourth** shape in RS-9's class; filed QA-1 |
| ADV-3 | an index whose final line is unterminated takes the append path and the harvested entry is concatenated onto the previous line | `build.py`-derived `advx1`/`advx2` (NEW), candidate **and** HEAD | **BROKE IT, HEAD-identical** — `> filler header line 24- 2026-08-16 · harvested insight 1 · evidence: fixture-new`; `cmp` of the candidate and HEAD outputs: byte-identical. Pre-existing, not a regression; filed QA-3 |
| ADV-4 (C-12/F-15) | the metric check reads a **refusing** arrival (0.47.0 exits 3, writes nothing) as *already provided* | `refuse3` fixture: a `## Rotated 2026-01-01` line in an at-cap index, run against the 0.47.0 template (NEW) | **Survived — the landed clause is load-bearing** — `cmd exit status = 3`, `refusing to harvest — 1 unclassifiable line(s); nothing written.`, `wc -l of resulting index = 30`. `80-delivery-policy.md:76-78` forbids reading that ≤30 as a verdict |
| ADV-5 | a residual number disagrees with `wc -l` − 30 when the clamp meets an unterminated final line | `advx1` (header-only over cap, unterminated) (NEW) | **Survived** — `Over cap: 2 …` with `after wc -l = 32 ; wc-l MINUS 30 = 2` |
| ADV-6 | there is a path where F.4 WARNs and **no** residual line prints (`rotate_count == ${#current[@]}` with an over-cap header) | `advx3` (header 30 + 3 entries) and `advx4` (header 31 + 3 entries) (NEW) | **Survived** — `advx3`: no residual line, `after wc -l = 30 ; F.4 PASS`; `advx4`: `Over cap: 1 …`, `after wc -l = 31 ; F.4 WARN`. Algebraically `rotate_count == ${#current[@]}` requires `header + harvested == 30`, so an over-cap header always clamps |
| ADV-7 (RES-5) | `07_DELIVERY.md`'s harvest heading may be suffixed and harvest **zero** — the shape stage 4's own `## Insight to surface` heading has | `build.py adv-heading cand` with heading `## Insight to surface` (NEW) | **Confirmed hazard** — `(no harvest/rotation line)`, index unchanged at 30 lines, exit 0. Not a defect of this change; a standing delivery precondition, filed QA-4 |
| ADV-8 | the candidate rotates the **newest** entries, or drops the header, on some path | AC-2 conservation check + header comparison on both AC-5 fixtures | **Survived** — `check_ac2.py` asserts `rotated == pre_entries[:len(rotated)]` and `rotated ∥ remaining == pre ∥ harvested` (exit 0); on both AC-5 fixtures `header lines byte-identical to the pre-run index: yes` (30 and 32 lines) |

### AC-13 drill — from B-3's bytes alone (C-12: command, exit status, number)

Arriving text: harness-kit **0.47.0**,
`skills/harness-init/templates/common/.harness/scripts/archive-task.sh`, **425** lines, sha256
`4c8db8c81ee8b74f903585d00d94224f20fd46a9210ea451ab08d07ac4e82d9e`, resolved through
`upgrade-project.sh:56`. Copied **read-only** (`-r--r--r--`) to `test/t27/qa/refresh/template-0.47.0.sh`;
no byte of it entered `.harness/` (K-14). I read only `80-delivery-policy.md:66-83` and the arriving
text; the vendored file's in-file note at `archive-task.sh:51-56` was not opened for the drill and
neither defect was re-diagnosed.

| step | command | exit status | number produced | verdict / action |
|---|---|---|---|---|
| check 1 (metric row) | `bash test/t27/qa/refresh-ac1/.harness/scripts/archive-task.sh --task fixture-task` over an index at the cap (30 lines) with 3 harvested | **0** — completed | `wc -l` of the resulting index = **33** | 33 > 30 → ***lost*** → action: make the decision read `wc -l` and rotate until the emitted file is ≤30 |
| check 2 (join row) | `bash test/t27/qa/refresh-ac6/.harness/scripts/archive-task.sh --task fixture-task` | **0** — completed | `grep -c 'evidence: fixture-wrapped'` = **1** (exit 0); `grep -c 'continues the sentence'` = **1** (exit 0) | continuation + tag present → ***already provided*** → action: change nothing (nothing was changed) |
| *lost* action applied | `python3 test/t27/qa/apply_lost_action.py refresh/template-0.47.0.sh refresh-fixed.sh` — two bounded hunks onto the arriving text, `+17 / −5`, 425 → 437 lines, nothing discarded | 0 | — | stated as a metric, not a patch (PQ-7): the entries there span several lines, so the loop rotates entries until the **emitted line count** reaches 30 |
| observable 1 | `bash test/t27/qa/drill-ac1/.harness/scripts/archive-task.sh --task fixture-task` | **0** | `after wc -l = 30`, `history entries: 3` | AC-13 clause 1 holds |
| observable 2 | `bash test/t27/qa/drill-ac6/.harness/scripts/archive-task.sh --task fixture-task` | **0** | tail of index = the wrapped bullet's 3 lines ending `· evidence: fixture-wrapped` | AC-13 clause 2 holds |
| ADV-4 (refusing arrival) | `bash test/t27/qa/refuse3/.harness/scripts/archive-task.sh --task fixture-task` | **3** | `wc -l` = 30 | exit ≠ 0 → **the check did not complete**; no verdict (`80-delivery-policy.md:76-78`). Never read as *already provided* |

## Boundary tests added

- **BC-1 × BC-7** — `.harness/insight-index.md` absent, `--dry-run`: HEAD **exit 0**, candidate **exit 0**; both print the full dry-run report, both leave the tree byte-identical, neither creates the index. RES-3 confirmed: the design's stated basis at `02_SOLUTION_DESIGN.md:31` ("aborts … under `set -e`") is **contradicted by measurement** — bash exempts a failing command inside an `&&` list from `errexit` unless it follows the final `&&`.
- **BC-2** — header-only index over the cap (AC-5 (ii)): clamp reduces the rotation to zero, the `elif` appends, no `insight-history.md` is created, exit 0.
- **BC-3** — three shapes (no `07_DELIVERY.md`; a `07_DELIVERY.md` with no `## Insight`; an empty `## Insight`): index sha256 `971898a03c623753` unchanged in all three, no history file, and the task folder still moved. Exit 0 each.
- **BC-4** — index already at 35 lines: with 0 harvested `Rotating 5` → 30 lines; with 2 harvested `Rotating 7` → 30 lines.
- **BC-5** — the cap unreachable by rotating entries, both variants: at most the entries present rotated, no header line and no harvested entry deleted, residual printed, exit 0 (the empty `remaining` array expands safely under `set -u`).
- **BC-6** — hostile entry bytes: `- -n …`, `- back\slash \t \n and \\ literal …`, `- $VAR ${HOME} \`id\` $(id) …` and a 402-byte longest line all round-trip byte-identically through rotation.
- **BC-7** — `--dry-run` over the AC-1 fixture: full-tree snapshot (existence, size, mtime_ns, sha256) identical before and after on **both** scripts, with a positive control proving the snapshot detects a one-byte append.
- **Unicode / wide characters** — every fixture entry carries `·` (U+00B7) and the index header carries an em dash; all round-trip unchanged.
- **Divergence shapes (C-3)** — three built and measured; a **fourth** found adversarially (ADV-2). See `### C-3 residuals` under `## Defects found`.

## verify_all result

```
command:  bash .harness/scripts/verify_all.sh      (cwd /home/alan/Programs/singbox-cli, K-10/C-8)
result:   PASS: 17   WARN: 0   FAIL: 0   SKIP: 1     (exit 0; three consecutive runs, identical)
```

- Total tests: `baseline.json` `test_count: 0` → `0` (this project has committed no test suite; `test/` is ignored)
- Pass: 17
- Fail: 0
- Warn: 0
- Skip: 1 — `[B.3] Lint (no linter on this project)`, the same SKIP as baseline
- New tests added: 0 committed; **37 fixture trees** and **49 script executions** in this stage — 35 candidate (10 of them the AC-1 stability repeats), 7 HEAD control, 5 against the 0.47.0 template, 2 against its patched form — plus 4 new stage-artifact tools (`build.py`, `check_ac2.py`, `snap.py`, `apply_lost_action.py`), all under `test/t27/qa/`
- Baseline updated: **no** — `test_count` has stood at 0 since 2026-07-31 across sixteen deliveries; raising it here would both invent a convention (out-of-scope 5, NFR-2) and put a fifth path in the product diff, failing AC-14. Nothing was lowered, no test deleted, no check modified. `[E.6]` and `[F.6]` both PASS with this document in place.
- New operator obligation: **none** — no check in this task needs a host these agents cannot reach.
- frozen: `git diff -- .harness/scripts/verify_all.sh` → empty (AC-8)
- F.4 metric: `verify_all.sh:215` `n=$(wc -l < .harness/insight-index.md)`; `:216` `(( n > 30 ))` — unchanged

### RES-1 — the measurements review could not take (CR-8)

```
git diff --numstat        70-doc-size.md 20/1 · 80-delivery-policy.md 36/0 · archive-task.sh 8/4 · AI-GUIDE.md 1/1
                          (plus docs/batches/followups/BATCH_LOG.md 15/0, BATCH_PLAN.md 6/6 — B-2 process paths)
product total             +65 / −6      (20+36+8+1 = 65 added; 1+0+4+1 = 6 removed)
git status --porcelain    4 product paths ' M' + 2 docs/batches ' M' + '?? docs/features/harness-self-maintenance/'
shell functions           HEAD 0  →  candidate 0        file 150 → 154 lines (150 + 8 − 4)
```

- `git diff --numstat` for the whole frozen set — `verify_all.{sh,ps1}`, `guard-rm.{sh,ps1}`,
  `archive-task.ps1`, `check-i18n-parity.sh`, `bin/sc`, `install.sh`, `uninstall.sh`, `README.md`,
  `README.zh-CN.md`, `CHANGELOG.md`, `CLAUDE.md`, `.github/copilot-instructions.md`,
  `docs/dev-map.md`, `.harness/rules/05-insight-index.md`, `.harness/insight-index.md`, `.claude` —
  returns **no row**. `git status --porcelain -- .claude` returns **nothing**.
- Landed sizes re-measured: `70-doc-size.md` **110**, `80-delivery-policy.md` **89**,
  `AI-GUIDE.md` **97**, `archive-task.sh` **154**. 11 rule fragments, largest 178.
- The RES-10 corrections are confirmed against the files: rule 80 = **89**, its numstat **36 / 0**,
  product total **+65 / −6**, and the new rule-70 trigger bullet is at **`70-doc-size.md:16`**
  (`:15` is the pre-existing "Before pasting evidence into a stage doc" bullet). The stale `35 / 0`
  / `64` / `88` figures were **not** inherited; every number above is mine.
- `git status --porcelain -- test/` → **empty**; `git check-ignore -v test/t27/qa/build.py` →
  `.gitignore:19:test/`. No fixture artifact is tracked (AC-14, C-9).

### RES-2 — the input AC-15 rides on

```
wc -l .harness/insight-index.md        →  30
tail -c 1 .harness/insight-index.md | xxd  →  00000000: 0a    .
non-bullet lines                        →  8   (lines 1-8, all leading; final line is a bullet)
```

**Implication for AC-15: the good case holds.** The file **does** end with a newline, so `wc -l` = 30
is the true physical line count, and the delivery run rotates exactly `h` for any `1 ≤ h ≤ 22`,
landing at exactly 30 with F.4 PASS. The RES-2 failure mode (`wc -l` = 29 → rotate `h−1` → 31 →
F.4 WARN) is **not** present. Simulated over a byte-identical copy with 3 insights:
`Rotating 3` → `after wc -l = 30 -> F.4 PASS`. The repository's own index was **not** run against
(`git diff --numstat -- .harness/insight-index.md` empty; sha256 `e148278e434dfff7` before and after
the simulation) — C-7's single observation is intact.

Two further properties of the real index that make the delivery run the *ideal* case: all 8
non-bullet lines are **leading** (so C-3(iii)'s hoist cannot reorder anything) and there is **no
blank line between entries** (so ADV-2's silent deletion cannot fire).

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| QA-1 | MINOR — residual against FR-2, **not repairable inside this task's frozen range** | `python3 test/t27/qa/build.py adv-blankmid cand && bash test/t27/qa/adv-blankmid-cand/.harness/scripts/archive-task.sh --task fixture-task` → `before wc -l = 32` (9 non-bullet) → `after wc -l = 29` (8 non-bullet), F.4 **PASS** | `.harness/scripts/archive-task.sh:118` — a **blank line between two entries** is the file's last non-bullet line; command substitution strips it from `header=$(grep -vE …)`, so it is silently deleted **even though the file's final line is a bullet**. C-3(iii) is stated as "final line a non-bullet line" and does **not** cover this. RS-9's statement should read *"the file's last non-bullet line is blank"*, not *"the final line is a non-bullet line"*. Repair lives in the frozen `:109-136` (AC-16) → pool row with RS-9/RES-6 |
| QA-2 | MINOR — residual, RES-9 reproduced first-hand | `python3 test/t27/qa/build.py adv-multiline cand && bash …/archive-task.sh --task fixture-task` → the hand-edited continuation line moves from physical line **15** to line **9**; 33 → 30, F.4 PASS | `.harness/scripts/archive-task.sh:118` — an index entry occupying more than one physical line (reachable only by hand edit) is counted by `index_lines`, classified non-bullet and hoisted into the header. Same mechanism and same frozen range as QA-1 → pool row with RS-9 |
| QA-3 | MINOR — residual, **HEAD-identical, not a regression** | `advx1` / `advx2` fixtures → `> filler header line 24- 2026-08-16 · harvested insight 1 · evidence: fixture-new`; `cmp` of candidate and HEAD outputs byte-identical | `.harness/scripts/archive-task.sh:128` — the append path writes `echo "$h" >> "$insight_index"` onto an index whose final line carries no trailing newline, concatenating the harvested entry onto that line and destroying its bullet marker. Pre-existing at HEAD; cannot bite at delivery (RES-2 measured `0a`) → pool row with RS-9 |
| QA-4 | MINOR — standing delivery precondition, not a code defect | `python3 test/t27/qa/build.py adv-heading cand && bash …/archive-task.sh --task fixture-task` with `## Insight to surface` → `(no harvest/rotation line)`, index unchanged, exit 0 | `.harness/scripts/archive-task.sh:58` (`/^##[[:space:]]+Insights?[[:space:]]*$/`). RES-5 confirmed by execution: a suffixed heading harvests **zero** and AC-15's first clause fails by construction. Stage 4's own section is titled `## Insight to surface` — `07_DELIVERY.md` must use exactly `## Insight` or `## Insights` |
| QA-5 | NIT — observation, no action | `/usr/bin/grep -n '^## '` over the four archived documents AC-9(a) routes → **33** H2 units, not the **30** `04_DEVELOPMENT.md` C-11 row reports | `04_DEVELOPMENT.md:70`. The criterion's own clauses (**zero** units with none, **zero** with two) hold on my spot-check of 8 units, so AC-9(a) passes either way; the difference is a counting convention, recorded rather than raised |
| QA-6 | **schema-gap row (B-1 clause d, `70-doc-size.md:94-96`)** | — | This document. Four units fit no declared shape of `06_TEST_REPORT.md` (`agents/qa-tester.md:16-24` declares seven sections and no criterion-outcome table, no drill transcript and no measurement set): the **per-criterion V-1…V-16 outcomes**, the **AC-13 drill transcript**, the **C-3 residual table** and the **RES-1/RES-2 measurement sets**. B-1's precedence clause applies — the PM dispatch and gate conditions C-3/C-8/C-9/C-11/C-12 name these outputs by name → **contract**. Destinations given instead of new H2 sections, following T-26's archived precedent (`doctor-rows-establish-their-fact/06_TEST_REPORT.md:144-262`, `###` sub-blocks inside a declared H2): outcomes → `## Adversarial tests` rows + `## Test plan`; drill → `### AC-13 drill` inside `## Adversarial tests`; C-3 residuals → `### C-3 residuals` below; measurement sets → `### RES-1` / `### RES-2` inside `## verify_all result`. No section was invented, no file opened, no changelog added |

**Zero BLOCKER, zero CRITICAL, zero MAJOR.** No defect of the four landed edits was found: every
criterion that separates HEAD from the candidate separates it in the direction the design predicted,
and QA-1…QA-3 are properties of the **frozen** rewrite at `:109-136` that this task is forbidden to
touch (AC-16, NFR-1, `02_SOLUTION_DESIGN.md` out-of-scope 8).

### C-3 residuals — three fixtures, all over the cap, never repaired

Measured with the candidate script; `archive-task.sh:109-136` untouched, no hand edit to any index.
Stage 4's numbers are **confirmed**, independently, on my own fixtures.

| shape | `wc -l` before | run said | `wc -l` after | F.4 | what actually happened |
|---|---|---|---|---|---|
| (i) final line with **no trailing newline** | **31** (32 physical lines; `tail -c 1` = `34`) | `Rotating 2 old insight(s)` | **31** | **WARN** | count divergence only: `wc -l` undercounts the unterminated line by one, so the decision aimed at 30; content conserved, the final line is now terminated (`0a`), non-bullet 8 → 8 |
| (ii) **zero non-bullet lines** | **32** | `Rotating 3 old insight(s)` | **31** | **WARN** | count divergence only: `header=$(grep -vE …)` is empty and `echo "$header"` writes an empty line where none existed, non-bullet **0 → 1**; no content lost |
| (iii) **final line a non-bullet line** | **33** (8 header + 10 entries + 1 mid-file marker + 13 entries + 1 trailing blank) | `Rotating 4 old insight(s)` | **29** | **PASS** | **content loss + reorder**, the dangerous one: the trailing blank line is gone (non-bullet 10 → 9) and the mid-file marker moved from line **19** to line **9**. Bullet conservation still holds (`rotated ∥ remaining == pre ∥ harvested` = True, 4 + 20 == 23 + 1), so what is lost is a *non-bullet* line — and F.4 PASSes over the loss |

Stage 4 reported 31→31, 32→31 and 33→**29** with the marker moving 19 → 9. **All three reproduce
exactly.** ADV-2 (QA-1) adds a fourth shape in the same class that C-3's three statements do not
cover; ADV-1 (QA-2) is RES-9's multi-line entry, reproduced.

## Stability

- The AC-1 fixture was rebuilt and run **10** times: `lines=30`, `idx_sha=bd0b7ae23302`,
  `hist_sha=3` on every run — 10/10 identical, no flakes.
- `bash .harness/scripts/verify_all.sh` was run **3** times from the repository root:
  `PASS: 17  WARN: 0  FAIL: 0  SKIP: 1`, exit 0, three times — no flakes.
- The AC-7 dry-run snapshot comparison was taken on two independent trees (candidate and HEAD) and
  was empty both times, with the positive control firing on a one-byte write — the snapshot is not
  vacuous.
- No test in this stage depends on wall-clock time except the `## Rotated <date>` history header,
  which is compared by entry content rather than by date.
- Measurement hygiene: every count that decides a criterion was taken with `/usr/bin/grep`
  explicitly, because this project's interactive `grep` is a ugrep wrapper whose `-cv` disagrees with
  the GNU `grep` a script gets (stage 4's insight, re-honoured here).

## Verdict

PASS WITH RESIDUALS — APPROVED FOR DELIVERY (0 blocking defects; QA-1…QA-4 are residuals for the pool, QA-5 an observation, QA-6 a schema-gap row; AC-15 deferred to C-7's single delivery run).
