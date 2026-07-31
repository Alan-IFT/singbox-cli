# 04 — Development Record · T-11 `install-version-query-abort`

- Mode: **full** · Decision mode: **deferred-human** (`defer, do not ask`) · Stage 4, 2026-08-01
- Binding inputs, read in order: `03_GATE_REVIEW.md` (C-1 … C-17), `02_SOLUTION_DESIGN.md`,
  `01_REQUIREMENT_ANALYSIS.md`, `PM_LOG.md`, `.harness/rules/50-singbox-cli.md`,
  `.harness/rules/85-design-discipline.md`, `.harness/insight-index.md`, `AI-GUIDE.md`,
  `docs/dev-map.md`.
- **`install.sh` was never executed, in whole or in part.** No `sudo`, no package manager, no
  `systemctl` verb other than the read-only `show`, no write under `/etc`, `/usr/local`, `/var`.

## Summary

`install.sh` step 2's version query now *judges* the version it extracted instead of terminating the
script at the assignment: the pipeline moved into an `if` condition (`set -e`'s exempt context) and
`head -1` was replaced by `sed -n '1s/.*"v\([^"]*\)".*/\1/p'`, so no element of the pipeline can be
killed by a downstream reader closing the pipe. All five B-2 failure modes now converge on the
already-written handler at what is now `install.sh:391-395` and print a localized statement plus
`exit 1`. Outside the product file, a new `.harness/scripts/check-i18n-parity.sh` renders all 41
`t()` keys in both languages under `set -u` and is wired as `verify_all` **B.2**, which stops being a
permanent `SKIP`.

## Order of work (C-8) and the two live-service witnesses (C-15)

| # | Step | Result |
|---|---|---|
| 1 | Live-service witness, development **start** | `MainPID=2500438` / `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST` |
| 2 | **E-10 run before any edit to `install.sh`** | see below — stop rule satisfied in substance, fixture defect reported |
| 3 | `install.sh` edit (design §3.1 + C-1) | done |
| 4 | `check-i18n-parity.sh` + `verify_all` B.2 wiring | done, `OK: 41 keys, both languages` |
| 5 | Safety harness, AC-4/5/6/7 with C-2…C-7 guards | 126 assertions, 0 failures |
| 6 | C-11 stale sentences | corrected, B.3 still SKIP |
| 7 | `CHANGELOG.md` (C-17) | added, does **not** claim a global guarantee |
| 8 | `verify_all` + C-12 clone delta | PASS 16 / WARN 1 / FAIL 0 / SKIP 1; exactly 2 deltas |
| 9 | Live-service witness, development **end** | `MainPID=2500438` / `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST` |

Both readings are **byte-identical to the PM's task-start baseline**. `systemctl show -p MainPID -p
ActiveEnterTimestamp` was the only `systemctl` invocation of this stage; `is-active` was never used
(insight L22). The service was neither restarted nor touched.

## E-10 — transcript and conclusion

### Leg 1: the design's §10 script, run verbatim, with C-8's non-vacuity guard first

```
== C-8 non-vacuity guard: size of grep's output ==
grep output bytes = 5000000
GUARD: PASS (> 64 KiB = 65536) -> an early-exiting reader really can SIGPIPE upstream

E10a big input, pipeline ENDING IN head -1, pipefail
  -> exit 141

E10b same input, sed -n 1s..p instead of head -1
  -> exit 141
```

The guard passed (5 MB ≫ 64 KiB), so neither leg is "inconclusive" for want of data. But **E10b did
not print `V=[1.10.0]` with exit 0** — the literal trigger of the stop rule. I did not edit
`install.sh` at that point. I diagnosed it first.

### Leg 2: diagnosis — the defect is in the probe's fixture, not in the design's shape

```
E10c  is the GENERATOR the SIGPIPE source? (no extraction at all)
  -> exit 141                                  # `yes … | head -200000 > /dev/null` alone

generating big.txt out of band (generator status deliberately ignored)
big.txt bytes = 5000000, lines = 200000

E10d  big input from a FILE, pipeline ENDING IN head -1, pipefail  (corrected E10a)
  -> exit 141                                  # no V= line: the assignment ABORTED

E10e  same input, sed -n 1s..p instead of head -1  (corrected E10b)
V=[1.10.0]
  -> exit 0

E10f  the exact production shape: grep reads a FILE (no cat), sed -n 1s..p
V=[1.10.0]
  -> exit 0

E10g  line count of what sed emits (guards against a DROPPED 1 address)
lines=0
chars=6
  -> exit 0

E10h  CONTROL: the same expression WITHOUT the 1 address (what C-1 forbids)
chars=1399999
  -> exit 0
```

**E10c is decisive**: `yes … | head -200000` is *itself* an early-exiting reader **inside the
measured pipeline**. It SIGPIPEs `yes`, `pipefail` takes 141 as the pipeline's status, and the
assignment aborts *regardless of what the tail of the pipeline does*. The design's fixture therefore
returns 141 for both legs and can never distinguish them. Production has no such element: `curl`
reads its socket to EOF and exits 0.

### Conclusion

- The stop rule's **substance** is satisfied: with the generator moved out of band, the design's
  exact expression yields `V=[1.10.0]` with exit 0 on a 5 MB / 200 000-line input (E10e, E10f).
  §3.1's shape is right. I proceeded to edit, and I am reporting the fixture defect rather than
  silently working around it (see "Upstream defects", D-A).
- **The `head -1` removal is load-bearing, not precautionary.** The design offered "precautionary" as
  the reading if E10a matched E10b. On a fair fixture they do *not* match: E10d (with `head -1`)
  aborts with 141 and no value, E10e (with `sed -n '1s…p'`) returns `1.10.0` and exit 0, on
  byte-identical input. That is exactly the BC-5/B-6 misclassification — a *successful* fetch
  reported as a failed one — reproduced on demand.
- **The `1` address is load-bearing and now has empirical proof** (E10h): dropping it yields
  1 399 999 characters instead of 6. This is the C-1/C-2 regression the gate called the highest-risk
  line in the diff, and it is independently caught by the harness fixture (see AC-6 below).

## The change to `install.sh`

`git diff install.sh` (the whole product diff, +22/−4):

```diff
-    SB_VER=$(curl "${CURL_OPTS_QUIET[@]}" "https://api.github.com/repos/${SB_REPO}/releases/latest" \
-        | grep '"tag_name"' | head -1 \
-        | sed 's/.*"v\([^"]*\)".*/\1/')
-    # Validate that we got a semver-like string (e.g. "1.10.0")
+    # Under `set -euo pipefail` a bare VAR=$(pipeline) carries the pipeline's own
+    # status, so a failed fetch terminated the installer HERE — before the
+    # validation below, which is the only code that can say what went wrong (T-11).
+    # `if` is one of set -e's exempt contexts, so the status is caught, not fatal.
+    #
+    # NO ELEMENT OF THIS PIPELINE MAY EXIT BEFORE EOF. `head -1` was removed for
+    # exactly that reason: a reader that closes the pipe early (head, grep -m1,
+    # sed q) can kill an upstream element with SIGPIPE, and `pipefail` would then
+    # report a SUCCESSFUL fetch as a failed one. `sed -n '1s…p'` reads to EOF and
+    # still yields only the first matching line, as `head -1` did.
+    SB_VER=""
+    if ! SB_VER=$(curl "${CURL_OPTS_QUIET[@]}" "https://api.github.com/repos/${SB_REPO}/releases/latest" \
+        | grep '"tag_name"' \
+        | sed -n '1s/.*"v\([^"]*\)".*/\1/p'); then
+        SB_VER=""
+    fi
+    # Validate that we got a semver-like string (e.g. "1.10.0"). This is the ONLY
+    # judge of whether the version is usable; the pipeline's status never decides.
     if [ -z "$SB_VER" ] || ! echo "$SB_VER" | grep -qE '^[0-9]+\.[0-9]+'; then
```

Typed verbatim from design §3.1. The handler (`t download_failed` / `t check_network` / `exit 1`),
`SB_URL=`, and everything below are byte-identical to HEAD. `bash -n install.sh` exits 0 (AC-2).

**C-1 audit of the changed block.** The `sed` expression is exactly
`sed -n '1s/.*"v\([^"]*\)".*/\1/p'` — the `1` address and the `p` flag are both present. Grepping the
changed block for `head`, `grep -m1` and `sed …q` returns **only the four comment lines that name
them as forbidden**; no executable early-exiting reader remains.

## Files changed

| Path | Change | A-4 item |
|---|---|---|
| `install.sh` | step 2 version query only (`:373-395`); +22/−4 | 1 |
| `CHANGELOG.md` | one zh `修复` bullet under `[Unreleased]` | 2 |
| `.harness/scripts/check-i18n-parity.sh` | **new**, 123 lines, executable | 3 |
| `.harness/scripts/verify_all.sh` | B.2 line only, inside the `HARNESS:B-CUSTOM` markers | 4 |
| `docs/tasks.md` | new section, R-1 … R-6 | 5 |
| `docs/dev-map.md` | B.2 sentence + 1 utility row + 1 pattern bullet | 6 |
| `CONTEXT.md` | *stage 1's* two glossary terms, untouched by me | 7 |
| `docs/features/install-version-query-abort/04_DEVELOPMENT.md` | this file | 8 |
| `.harness/rules/50-singbox-cli.md` | the single stale sentence at `:36-38` (C-11) | 10 |

A-4 items **9** (`.harness/rejected-decisions.md`: D-5, `installer-early-exit-download-helper`, and
the closing note on `installer-version-query-silent-abort`) and **11** (`insight-index.md` /
`_archived/`, delivery tooling only) are **not** in my diff: C-16 assigns them to delivery, and A-4
item 11 forbids any stage hand-editing `insight-index.md`. The reviewer should expect exactly nine of
the eleven items now, and the remaining two at stage 7.

## verify_all result

### Baseline (working tree, before any change)

```
[B.2] Tests pass ... SKIP
[F.6] Active task docs <=500 lines each ... WARN
=== Summary ===   PASS: 15   WARN: 1   FAIL: 0   SKIP: 2      (exit 1)
```

### After changes

```
A.1 A.2 B.1 PASS · [B.2] install.sh bilingual key parity ... PASS · [B.3] Lint ... SKIP
E.1 E.2 E.3 E.4 E.4b E.5 E.6 PASS · F.1 F.2 F.3 F.4 F.5 PASS · [F.6] Active task docs ... WARN
=== Summary ===   PASS: 16   WARN: 1   FAIL: 0   SKIP: 1      (exit 1)
```

**0 FAIL — the stated gate.** Exit 1 is `warns > 0` (`verify_all.sh:243`), not failure, while F.6
stands (gate §5 answer 6, A-6). The summary matches the gate's prediction exactly.

### C-12 — delta against a pristine **clone** (never a worktree, insight L26)

```
clone:  git clone <repo> baseline-clone            HEAD 9184171 == worktree HEAD
        git -C baseline-clone status --porcelain   -> EMPTY (pristine)
        [ -d baseline-clone/.git ]                 -> YES (a real dir, so A.1/A.2 do not SKIP)
clone summary: PASS 16 / WARN 0 / FAIL 0 / SKIP 2   (exit 0)
```

Step-by-step, all 18 steps compared:

```
  A.1    clone=PASS  changed=PASS  same        E.4    clone=PASS  changed=PASS  same
  A.2    clone=PASS  changed=PASS  same        E.5    clone=PASS  changed=PASS  same
  B.1    clone=PASS  changed=PASS  same        E.6    clone=PASS  changed=PASS  same
  B.2    clone=SKIP  changed=PASS  *** CHANGED ***    F.1-F.5  all same (PASS)
  B.3    clone=SKIP  changed=SKIP  same        F.6    clone=PASS  changed=WARN  *** CHANGED ***
  E.1-E.3, E.4b  all same (PASS)
```

**Exactly the two expected deltas** — BC-16's B-8 flip and PM-1's F.6. F.6's sole offender is
mechanically attributed:

```
OVER: docs/features/install-version-query-abort/01_REQUIREMENT_ANALYSIS.md = 549L
  205L 03_GATE_REVIEW.md · 500L 02_SOLUTION_DESIGN.md · 235L PM_LOG.md · (this file <500L)
```

No second F.6 offender exists; this document is under the cap.

## Acceptance criteria discharged at this stage

| AC | Result |
|---|---|
| AC-1 | Discharged upstream by the PM pre-flight (7/7) and cited in `02_SOLUTION_DESIGN.md` §0. |
| AC-2 | `bash -n install.sh` → exit 0 (also B.1 PASS). |
| AC-3 | 0 FAIL; clone delta = exactly the two expected steps (above). |
| AC-4 | 6 stub modes covering all five B-2 modes, en, each observed independently. **36 assertions, 0 failures.** |
| AC-5 | The same six modes in zh, with C-4's literals and the en≠zh check. **54 assertions, 0 failures.** |
| AC-6 | Success fixture against the HEAD fragment and the changed fragment, both languages: `SB_VER=[1.10.0]`, stdout byte-identical. |
| AC-7 | 3 mutants, each **exactly** status 1 and naming the offending key; plus an exit-2 control. |
| AC-8 | Discharged **only because all three AC-7 mutants returned 1** (C-5's dependency stated). `OK: 41 keys, both languages`. |
| AC-9 | `install.sh:116-132` byte-identical to HEAD; no curl option added, removed or altered. |
| AC-10 | Invoked-command sets HEAD vs changed: **identical**. No new file in the installed footprint. |
| AC-11 / C-14 | `:24-29` and `:243-288` byte-identical to HEAD; `install_report \|\| exit 1` byte-identical (HEAD `:518` → now `:532`). **No exception at all.** |
| AC-12 / C-10 | See "Files changed"; nine of A-4's eleven items, two delivery-owned. |
| AC-13 / C-9 | 11 sites in the changed file (ruling below). |
| AC-14 / C-15 | Both witnesses identical (above). |
| AC-15 | Wrote only the nine repo paths listed by `git status --porcelain` plus a `mktemp -d` under the session scratchpad. Nothing under `/etc`, `/usr/local`, `/etc/sudoers.d`. No package manager ran. |

### C-9's ruling, recorded explicitly

**AC-13 is discharged against substitution *sites*: 11 rows = 11 sites.** Measured on the changed
file:

```
command-substitution SITES (code lines containing "$(") : 11
raw "$(" OCCURRENCES in code                            : 12   <-- must NOT be used as the criterion
```

The 12th occurrence is the **nested** `$(dirname …)` inside `SCRIPT_DIR="$(cd "$(dirname …)" … )"` at
`install.sh:318` (design §4 row 6). The change adds and removes no substitution; the eleven sites in
the changed file are `:39 :51 :61 :62 :307 :318 :332 :368 :371 :384 :406`, i.e. design §4's eleven
HEAD anchors with the defect site at `373→384` and the two sites below the block shifted by +14.

## Safety harness (design §6) — what was built and what it proved

Everything ran inside a `mktemp -d`. `install.sh` was **never executed**; only the extracted
version-query block ran, and only after the refuse-to-run guard passed.

- **Fragment extraction (C-6)** is a `sed` **range** anchored on `/SB_VER=/`, so the end anchor cannot
  bind to `install.sh:344` (finding F-2). Measured: changed fragment **15 lines**, first line
  `SB_VER=""`, last line `t fetching_item "sing-box v$SB_VER ($ARCH)"`; HEAD fragment 11 lines.
- **Refuse-to-run guard (C-6/C-7)**: non-empty, ≤20 lines, contains `curl` `grep` `download_failed`
  `check_network` `exit 1` `fetching_item`, whole-line `^[[:space:]]*fi$` count equal to the expected
  value (F-11), and none of the denied tokens. Four **isolating negative controls** prove the guard
  bites rather than decorating: an over-run to `step2_done` (refused), and the changed fragment plus
  one added line invoking `sing-box` / `tar ` / `install -m` / `mkdir` (each refused, naming the
  rule).
- **`curl` stub + C-3 witness**: `$TMP/bin` is prepended to `PATH`; the stub appends one line per
  invocation to `$TMP/stub.log` and ignores every option, so the untouched `-f -s -S -L` array is
  genuinely exercised. **Every** AC-4/AC-5/AC-6 result asserts the log grew by exactly 1 *and* that
  the driver's `command -v curl` resolved inside `$TMP/bin`. 21 stub invocations, 21 witnesses.
- **Poison pills (extra interlock, mine)**: refusing stubs named `sing-box`, `sudo`, `systemctl`,
  `rc-service`, `rc-update`, `apt-get`, `dnf`, `yum`, `pacman`, `zypper`, `apk`, `visudo`, `install`,
  `tar`, `chmod` also sit first on `PATH`, log, and exit 99. **`POISON` lines in `stub.log`: 0.**
- **`driver.sh` carries `set -euo pipefail`** (without it the harness proves nothing — E3) and assigns
  `LANG_CHOICE` directly, which is how BC-11's zh table is reached with no interactive prompt.

Results, `HARNESS SUMMARY: PASS=126 FAIL=0`:

```
AC-4 (en)   transport / http403 / interstitial / empty200 / emptyver / nonsemver
            exit 1 · "Download failed: GitHub API (sing-box version)" · "Please check your
            network and retry" · NO "SB_VER=[" echo · stub delta 1 · curl from $TMP/bin
AC-5 (zh)   same six · "下载失败：GitHub API (sing-box version)" · "请检查网络后重试"
            · no "unbound variable" anywhere · zh stdout ≠ en stdout for every mode (C-4)
```

**Non-vacuity, run as an explicit negative control**: the *same* harness on the **HEAD** fragment,
modes transport / http403 / interstitial / empty200 → `exit=1 stdout=[]`, i.e. the installer dies
producing nothing. That is the defect this task removes, reproduced, and it proves the AC-4
assertions are discriminating rather than trivially true.

### AC-6 / C-2 — the fixture that can see a dropped `1` address

The success fixture is a hand-written ~1.6 KB latest-release body (design §6.3 permits this; **no
network was used at any point**) with **two** `"tag_name"` lines: the real `v1.10.0` first and a
decoy `v9.9.9-decoy` later.

```
--- en ---                                   --- zh ---
changed: exit=0                              changed: exit=0
  |   ↓ Fetching sing-box v1.10.0 (amd64) ...  |   ↓ 获取 sing-box v1.10.0 (amd64) ...
  | SB_VER=[1.10.0]                            | SB_VER=[1.10.0]
HEAD   : exit=0   (identical)                HEAD   : exit=0   (identical)
```

Asserted and passing in both languages: stdout **byte-identical** HEAD vs changed (so the
`t fetching_item` line is byte-identical, B-5), `SB_VER` is exactly one line, equals `1.10.0`, and
the decoy tag is absent. And the fixture is proven **capable of failing**: a mutant fragment with the
`1` address stripped produces

```
  ↓ Fetching sing-box v1.10.0|9.9.9-decoy (amd64) ...   SB_VER=[1.10.0|9.9.9-decoy]
```

so the single highest-risk regression in this diff is detectable, which the design's single-line
fixture could not have done (finding F-8).

### AC-7 / AC-8 / C-5 — the parity checker's mutants

```
PASS  HEAD install.sh (unmodified)       status=0 (expected exactly 0), stdout 'OK: 41 keys'
PASS  working-tree install.sh            status=0 (expected exactly 0), stdout 'OK: 41 keys'
PASS  mutant A: key gone from zh only    status=1 (expected exactly 1), names 'check_network'
      -> check_network: missing in zh (renders in en only)
PASS  mutant B: key gone from en only    status=1 (expected exactly 1), names 'check_network'
      -> check_network: missing in en (renders in zh only)
PASS  mutant C: %s dropped from zh       status=1 (expected exactly 1), names 'fail_status'
      -> fail_status: specifier count differs (en=1 zh=0)
PASS  control: t() unfindable -> exit 2  status=2 (expected exactly 2), 'CANNOT DECIDE'
AC-7 summary: PASS=6 FAIL=0
AC-8 DISCHARGED (all three mutants returned exactly 1, and both real files return 0)
```

Every status is asserted **exactly**, never "non-zero" (F-9), and the exit-2 control proves 1 and 2
are distinguishable. Mutations lived only in `$TMP`; the working tree was never mutated. **C-13 did
not fire**: the check is green against the unmodified `install.sh` at HEAD, so no fifth deferral is
owed and the `verify_all` B.2 edit stands.

**The B.2 *wiring* is separately proven non-vacuous** (a checker that always passed, or a `step` call
that ignored `$?`, would satisfy AC-8 as written). Running the exact block now in `verify_all.sh`
against a mutated copy in `$TMP`, then against the real file:

```
[B.2] install.sh bilingual key parity ... FAIL
      check_network: missing in zh (renders in en only)
[B.2] install.sh bilingual key parity ... PASS      (same snippet, unmutated file)
```

The checker follows design §5.2 exactly: extract `t()` between the column-0 anchors, enumerate
*candidate* keys as a union (never attributed to a block), assert **every** `fmt=` line produced a key
(82/82 — else exit 2), then render behaviourally in a `bash -u` child so a missing key dies on
`printf`'s unset `fmt` — the production failure mode itself, not a proxy. It never sources or
executes `install.sh`, writes only in its own `mktemp -d`, and needs no root and no network.

## Deviations from the design / gate — `DESIGN DRIFT`, all harness-side

**None of these touch product code.** `install.sh` is design §3.1 verbatim.

1. **`DESIGN DRIFT` · C-7's `sing-box` denylist entry is applied in *command position*, not as a raw
   substring.** Implemented literally first; the harness's first run **refused both fragments**:

   ```
   REFUSE[changed]: denied token [sing-box version]
   REFUSE[changed]: sing-box in command position
   ```

   Cause: the block's own handler argument is `t download_failed "GitHub API (sing-box version)"`, and
   the block also contains `sing-box` in the tarball URL and in the `fetching_item` argument. A
   substring rule banning `sing-box` therefore refuses the exact fragment it exists to let run, and
   AC-4/5/6 become undischargeable. The gate's stated intent (A-7) is L13's incident class — *a test
   executing the installed binary*, i.e. `install.sh:392`'s `$(sing-box version | head -1)`. The rule
   is now `(^|[;&|]|\$\()[[:space:]]*sing-box([[:space:]]|$)`, which matches an invocation and not
   inert text, and the absolute `sing-box version` substring was dropped for the same collision.
   **Compensating controls, both verified**: (a) an isolating negative control — the changed fragment
   plus `t step2_done "$(sing-box version | head -1)"` is refused, naming the rule; (b) a poison-pill
   `sing-box` executable first on `PATH` that refuses and exits 99, never reached (0 `POISON` lines).
   Reviewer: this is the one judgement call in the safety layer; it is recorded here so it is audited
   rather than assumed.
2. **`DESIGN DRIFT` (minor) · the "exactly two `fi`" assertion is parameterised.** §6.2 wrote it for
   the post-change block, but AC-6 also requires running the **HEAD** fragment, which has exactly
   **one** `fi`. The guard now takes the expected count (2 changed / 1 HEAD) and still matches whole
   lines only (F-11). Measured and printed in the transcript.
3. **CHANGELOG placement.** Design §11 says "one entry under a new version heading". I appended under
   the existing `## [Unreleased]` → `### 修复`, where T-01, T-02, T-09 and T-10 all put theirs.
   Creating a new version heading is a release decision that is the owner's, not mine.
4. **AC-4 ran six stub modes, not five.** B-2 mode 3 (2xx with no tag) is exercised twice —
   `interstitial` (BC-3) and `empty200` (BC-1) — as design §6.3's own table lists. Five modes, six
   independent results. More coverage, not less.
5. **Fixture provenance.** `latest.json` is hand-written (design §6.3's stated fallback) rather than
   captured from GitHub, because C-2 requires ≥2 `tag_name` lines, which a real body does not have.
   Consequence worth stating: **this stage made no network request at all.**

## Upstream defects found (reported, not worked around, not edited)

- **D-A · `02_SOLUTION_DESIGN.md` §10 — the E-10 fixture cannot measure what E-10 asks.** Its input
  generator `yes … | head -200000` is itself an early-exiting reader inside the measured pipeline, so
  under `pipefail` it SIGPIPEs `yes` and both legs return 141 no matter what the extraction tail does
  (proved by E10c in isolation). As written, the stop rule fires on every run for a reason unrelated
  to the shape under test. Fix: materialise the input out of band, then measure. Owner:
  solution-architect. **Impact on this task: none** — the corrected legs E10e/E10f satisfy the stop
  rule's substance and strengthen its conclusion (the `head -1` removal is load-bearing, not
  precautionary).
- **D-B · every stage document cites "HEAD `22502f9`", but HEAD is `9184171`.** `22502f9` is an
  ancestor from 2026-06-04; `install.sh` differs between them by 159 insertions / 26 deletions, and
  `CURL_OPTS_QUIET` at `:128` — which the gate verified as `V` — does not exist at `22502f9` at all.
  Every cited line anchor is correct **for `9184171`**; only the sha label is wrong. Owner:
  requirement-analyst (propagated to design and gate). Impact: none on the code, but a reviewer
  re-checking anchors against `22502f9` would find nothing where the docs say it is.
- **D-C · `02_SOLUTION_DESIGN.md` §4 says sites below the edit shift by "+11 lines".** The block grows
  by **+14** (9 lines → 23). `+11` happens to be the shift of the `SB_VER=$(` line itself
  (`373 → 384`); the sites strictly below shift by 14 (`392 → 406`). Cosmetic; recorded so the sweep's
  anchors can be re-derived. Owner: solution-architect.

Two gate findings I re-confirmed rather than acted on, as instructed: **F-4** (BC-4's "still
semver-like → the run proceeds" branch is unreachable at HEAD) and **F-5** (curl's raw line is printed
*before*, not below, the localized statement — wording only; nothing was reordered).

## Binding-conditions checklist (C-1 … C-17)

| # | Status | Evidence |
|---|---|---|
| C-1 | **discharged** | `sed -n '1s/.*"v\([^"]*\)".*/\1/p'` verbatim, `1` + `p` present; no executable `head` / `grep -m1` / `sed …q` in the block (only the comment naming them). |
| C-2 | **discharged** | Fixture has 2 `"tag_name"` lines; `SB_VER` single line, `= 1.10.0`, byte-equal HEAD vs changed; `t fetching_item` byte-identical in both languages; dropped-`1` mutant demonstrably detected. |
| C-3 | **discharged** | `stub.log` +1 asserted on all 21 runs; `command -v curl` asserted inside `$TMP/bin` on every AC-4/5/6 result. |
| C-4 | **discharged** | `下载失败` and `请检查网络后重试` asserted; zh stdout ≠ en stdout for all six modes. |
| C-5 | **discharged** | 3 mutants (zh key, **en** key, `%s` in `fail_status`), each **exactly** 1 and naming the key; AC-8 recorded as dependent on all three. |
| C-6 | **discharged** | `sed` range from `/SB_VER=/`; fragment non-empty, 15 lines (≤20), contains `download_failed`. |
| C-7 | **discharged with a recorded deviation** | All 22 substring tokens enforced incl. C-7's additions; `sing-box` enforced in command position — see Deviation 1, with two compensating controls. Whole-line `^[[:space:]]*fi$`. |
| C-8 | **discharged** | E-10 ran **before** the edit; 64 KiB guard asserted first (5 000 000 B); literal stop-rule trigger diagnosed to a fixture defect and reported as D-A, not worked around silently. |
| C-9 | **discharged** | Ruling recorded above: 11 sites, raw `$(` count 12 not used; `:318`'s nested `$(dirname …)` named. |
| C-10 | **discharged** | `git status --porcelain` + `git diff --stat` pasted; `verify_all.ps1`, `baseline.json`, `bin/sc`, `systemd/`, `uninstall.sh`, `README*.md` verified clean. |
| C-11 | **discharged** | `docs/dev-map.md:22-24` and `.harness/rules/50-singbox-cli.md:36-38` corrected; B.3 stays SKIP; no other line of rule 50 touched. |
| C-12 | **discharged** | **Clone**, not worktree; `status --porcelain` empty; `.git` a directory; 18/18 steps compared; exactly 2 deltas. |
| C-13 | **not applicable** | The check is green against the unmodified `install.sh`; no fifth deferral owed, nothing appended to `ruleset-unit-tests-in-t02`, the B.2 wiring stands. |
| C-14 | **discharged** | `:24-29`, `:243-288` byte-identical; `install_report \|\| exit 1` unchanged (`:518 → :532`). |
| C-15 | **discharged** | Both readings pasted and identical to the baseline; `is-active` never used. QA owns the third checkpoint. |
| C-16 | **deferred to delivery, by C-16's own wording** | The three `rejected-decisions.md` records are written "at delivery"; A-4 item 9. Not in my diff. |
| C-17 | **discharged** | CHANGELOG explicitly ends "「安装器在任何情况下都会说明结果」目前还不成立" (D-7); R-1…R-6 filed in `docs/tasks.md`, R-6 naming `verify_all.ps1:79`'s divergence. |

## Shipping diff (C-10)

```
$ git status --porcelain
 M .harness/rules/50-singbox-cli.md      M docs/dev-map.md
 M .harness/scripts/verify_all.sh        M docs/tasks.md
 M CHANGELOG.md                          M install.sh
 M CONTEXT.md                           ?? .harness/scripts/check-i18n-parity.sh
                                        ?? docs/features/install-version-query-abort/

$ git diff --stat
 .harness/rules/50-singbox-cli.md |  6 ++++--
 .harness/scripts/verify_all.sh   |  8 +++++++-
 CHANGELOG.md                     |  2 ++
 CONTEXT.md                       | 14 ++++++++++++++     (stage 1's, PM-2 / A-5)
 docs/dev-map.md                  |  9 ++++++++-
 docs/tasks.md                    | 33 ++++++++++++++++++++++++++++++++-
 install.sh                       | 22 ++++++++++++++++++----
 7 files changed, 85 insertions(+), 9 deletions(-)

clean: verify_all.ps1 · baseline.json · bin/sc · uninstall.sh · README.md · README.zh-CN.md · systemd/
```

**Not committed, not pushed.** The owner owns delivery.

## Dev-map updates

- `docs/dev-map.md:22-24` — B.2 is no longer described as `SKIP` (C-11).
- Reusable utilities, new row: `Bilingual parity proof for install.sh | check-i18n-parity.sh [FILE] |
  .harness/scripts/ | …extracts the function and renders every key under set -u; wired as verify_all
  B.2. Exit 0/1/2 — 2 is a failure for the caller, never a pass. Does not cover bin/sc.`
- Patterns to follow, new bullet: never write a bare `VAR=$(pipeline)` under `set -euo pipefail` when
  a handler below is supposed to see the failure — put it in an `if` condition and keep every element
  of the pipeline reading to EOF.

## Open issues for review

1. `.harness/rules/50-singbox-cli.md:43` still opens "Minimum manual verification … **until B.2/B.3
   are real**". B.3 is still SKIP so the sentence is not false, and C-11 forbids touching any other
   line of rule 50, so I left it. Flagging it so the next rule-50 edit tightens it.
2. `docs/tasks.md:11` still shows T-11 at stage `req`. The board is PM-maintained; I did not move it.
3. `.harness/scripts/verify_all.ps1` now genuinely diverges from the Bash mirror (R-6, filed).
4. `.harness/scripts/baseline.json` still reads `test_count: 0` although B.2 is now a real check
   (R-4, filed) — outside A-4's permitted diff, so not touched.
5. Residual imprecision the gate already accepted (A-1): for B-2 mode 5 (`vnightly`) the rendered
   "Download failed" is imprecise — a version *was* transferred, it is merely unusable. Pre-existing
   at HEAD, deliberately merged onto one handler by D-1, and not among B-4's prohibitions.

## Insight to surface

- A `yes … | head -N` input generator is itself an early-exiting reader, so under `pipefail` it SIGPIPEs its own producer and the whole pipeline returns 141 no matter what the tail does — a SIGPIPE probe must materialise its large input out of band or it measures only its own generator · evidence: install-version-query-abort E10a/E10b vs E10c/E10e

## Verdict

**READY FOR REVIEW**
