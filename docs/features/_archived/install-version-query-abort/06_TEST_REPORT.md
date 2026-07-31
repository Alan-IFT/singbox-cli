# 06 — Test Report · T-11 `install-version-query-abort`

- Mode: **full** · Decision mode: **deferred-human** · Stage 6 (QA), 2026-08-01
- Read: `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`, `03_GATE_REVIEW.md` (C-1…C-17),
  `04_DEVELOPMENT.md`, `05_CODE_REVIEW.md`, `PM_LOG.md`, plus the working tree.
- **The harness below was rebuilt from the acceptance criteria.** Per stage 5 [VERIF-1] I did not
  inherit, copy or re-run the developer's harness (it is uncommitted; I never saw its source).
  Fixtures, stub, guard, driver and every assertion are mine, written from B-2/AC-4…AC-7. Where my
  numbers match `04_DEVELOPMENT.md`, that is an **independent second witness**.
- **`install.sh` was never executed, in whole or in part.** No `sudo`, no package manager, no
  `systemctl` verb other than read-only `show`, no write under `/etc`, `/usr/local`, `/var`, no git
  write. Everything ran inside one `mktemp -d` (`$QA`).
- HEAD is **`9184171`** (`git rev-parse HEAD` → `91841719bbdc…`); the `22502f9` in stages 1-3 is a
  mislabel (developer D-B) and all anchors resolve at `9184171`.

## 1. The harness I built

```
$QA/bin/curl              stub: ignores every option, body from $STUB_MODE/$STUB_FILE,
                          appends one CURL line per call to $QA/stub.log
$QA/bin/{sudo,systemctl,sing-box,apt-get,dnf,yum,pacman,zypper,apk,visudo,install,
         tar,chmod,mkdir,rm,rc-service,rc-update,python3}   poison pills: log POISON, exit 99
$QA/fixtures/             hand-written bodies — NO network request was made at any point
$QA/frag/block.{changed,head}   sed range  /SB_VER=/,/t fetching_item/     (C-6)
$QA/frag/t.{changed,head}       sed range  /^t() {/,/^}/
$QA/guard.sh              refuse-to-run interlock (C-6 + C-7 as amended by stage 5)
$QA/driver.sh             set -euo pipefail; . t.frag; LANG_CHOICE=$LANG_IN; ARCH=amd64;
                          SB_REPO=…; CURL_OPTS_QUIET=(-f -s -S -L); . block.frag;
                          echo "SB_VER=[$SB_VER]"
```

Every run is `env -i PATH="$QA/bin:/usr/bin:/bin" …`, so the stub and poison pills lead `PATH` and no
ambient environment leaks in. The driver prints `WHICH_CURL=$(command -v curl)` to stderr — my C-3
witness, taken from *inside* the driver process. `driver.sh`'s `CURL_OPTS_QUIET` was diffed against
`install.sh:128` and is byte-equal, so the untouched `-f -s -S -L` array is genuinely exercised.

**C-6 — the end-anchor collision (gate F-2), measured:** `grep -n 't fetching_item' install.sh` →
`344:` (above the block) and `397:`. A `grep | head -1` anchor binds to `:344`; a `sed` **range** from
`/SB_VER=/` cannot, since sed searches the end address only from the line after the start. Result:
`block.changed` = **15 lines**, `block.head` = **11 lines** — independently equal to stage 4.

**C-7 — the guard, and proof it bites.** Substring denylist: `install -m`, `tar `, `systemctl`,
`rc-service`, `rc-update`, `pkg_install`, `visudo`, `chmod`, `mkdir`, `sudo`, `/etc/`, `/usr/local/`,
`apt-get`, `dnf`, `yum`, `pacman`, `zypper`, `apk`, `/var/`, `rm -rf`, `cat >`, `python3`. Plus
`sing-box` in **command position** only, per the stage-5 amendment — I confirmed a raw substring ban
is unsatisfiable, since the legitimate fragment contains the literal three times (`:392` handler
argument, `:396` URL, `:397` notice). Whole-line `^[[:space:]]*fi$` count, parameterised (2/1).

```
GUARD OK: block.changed (15 lines, fi=2)      GUARD OK: block.head (11 lines, fi=1)

NEGATIVE CONTROLS — guard must refuse each:
over_singbox -> REFUSE: sing-box in command position
over_tar     -> REFUSE: denied token [tar ]          over_install -> REFUSE: [install -m]
over_mkdir   -> REFUSE: [mkdir] ; [/etc/]            over_sysctl  -> REFUSE: [systemctl]
empty        -> REFUSE: fragment is empty
overrun_full -> REFUSE: 24 lines (>20); fi 3!=2; [install -m]; [tar ]; [mkdir];
                sing-box in command position
```

`overrun_full` is the real over-run — the same range extended to `/t step2_done/`, i.e. what would run
if the block's boundaries moved. It is refused six ways.

---

## 2. Test plan

| AC | Test case(s) | Where |
|---|---|---|
| AC-1 | E-0 legs E1/E2/E3/E4/E9 re-run verbatim | `bash -c` in `$QA` |
| AC-2 | `bash -n` on `install.sh`, `check-i18n-parity.sh`, `verify_all.sh` | working tree |
| AC-3 / C-12 | `verify_all` changed tree vs pristine **clone** of `9184171`, 18 steps compared | `$QA/baseline-clone` |
| AC-4 | 6 stub modes covering B-2.1…B-2.5, en, each observed independently | `$QA/driver.sh` |
| AC-5 / C-4 | same 6 modes in zh + zh literals + zh≠en stdout | `$QA/driver.sh` |
| AC-6 / C-2 | success fixture with **2** `"tag_name"` lines, changed vs HEAD, both langs; dropped-`1` mutant | `$QA/driver.sh` |
| AC-7 / C-5 | 3 mutants (zh key, en key, `%s`) + exit-2 control, temp copies only | `$QA/i18n/` |
| AC-8 | committed checker on the real file (dependent on all 3 mutants) + wiring mutation | working tree |
| AC-9 / AC-11 / C-14 | range diffs `:116-132`, `:24-29`, `:243-288`, `install_report \|\| exit 1` | `git show HEAD:` |
| AC-10 | invoked-command sets HEAD vs changed, compared with `comm` | `git show HEAD:` |
| AC-12 / C-10 | `git status --porcelain` + `git diff --stat` | working tree |
| AC-13 / C-9 | substitution **sites** vs raw `$(` occurrences, HEAD and changed | comment-stripped scan |
| AC-14 / C-15 · AC-15 | `systemctl show -p MainPID -p ActiveEnterTimestamp`; write ledger + poison log | §7 |

## 3. Boundary tests added

Ten hostile/edge response bodies, each run through the shipped fragment **and** the HEAD fragment and
compared by exit status + stdout checksum. **Every pair matched — B-5 holds on all ten.**

| body | changed | HEAD same? |
|---|---|---|
| well-formed `v1.10.0` | 0 / `Fetching sing-box v1.10.0` | yes |
| tag without leading `v` (BC-4) | 1 / stated failure | yes |
| minified single-line JSON, two quoted `v` values | 0 / `v1.10.0` | yes |
| unicode `v1.10.0-中文🎉` | 0 / renders intact | yes |
| 100 000-char version · embedded NUL byte · `v../../etc/passwd` | 1 / stated failure (each) | yes |
| `v1.10.0; rm -rf /` | 0 / passes semver test | yes |
| CRLF line endings | 0 / `v1.10.0` | yes |
| tag containing `%s%n%d` | 0 / printed literally, both langs | yes |

Also covered: empty 200 body (BC-1), 403 (BC-2), HTML interstitial (BC-3), 5 MB body (BC-15), `set -u`
on both legs (BC-6 — no `unbound variable` in any of 132 stderr captures), zh reached with no
interactive prompt (BC-11), concurrency explicitly not a scenario (BC-14 — no shared state added).

## Adversarial tests

One independent reproducer per criterion, hypothesis written **before** the run.

| AC | Hypothesis ("I expect failure when…") | Reproducer (NEW — mine) | Outcome |
|---|---|---|---|
| AC-1 | `set -e` does not really abort on `V=$(pipeline)` in bash 5.2 — the premise is false | E1/E2 re-run | Survived — §4.1 |
| AC-2 | the new `if !` block has an unbalanced `fi` | `bash -n install.sh` | Survived — exit 0 |
| AC-3 | the baseline is contaminated, or `.git` is a worktree file (L26) so A.1/A.2 silently SKIP | `git clone` + `[ -d .git ]` + 18-step compare | Survived — §5 |
| AC-4 | one of the five modes still dies at the assignment; or the stub is never invoked and I am hitting the real GitHub API | 12 driver runs + `stub.log` delta + `WHICH_CURL` | Survived — §4.2 |
| AC-5 | the zh literals never appear because the driver ignores `LANG_CHOICE` (an en-only run passes the criterion as written) | assert `下载失败`/`请检查网络后重试` **and** zh≠en stdout | Survived — §4.2 |
| AC-6 | the `1` sed address can be dropped with no assertion noticing | 2-`tag_name` fixture + mutant with `1` removed | Survived, **and the test provably fails on the mutant** — §4.3 |
| AC-7 | a mutant returns `exit 2` ("cannot decide") and is scored as detection | assert status **==1** exactly + exit-2 control | Survived — §4.4 |
| AC-8 | the checker always exits 0 | AC-7 dependency + full-`verify_all` wiring mutation | Survived — §4.4 |
| AC-9 | a curl option was altered inside the restructured block | range diff `:116-132` + option-literal scan | Survived — §6 |
| AC-10 | `head` was dropped from the invoked-command set | `comm` on command inventories | Survived — §6 |
| AC-11 | `install_report \|\| exit 1` moved or changed | three range diffs vs `9184171` | Survived — §6 |
| AC-12 | something outside A-4's list is dirty | `git status --porcelain` | Survived — §6 |
| AC-13 | the raw `$(` count of 12 was used as the criterion | site vs raw count, HEAD and changed | Survived — §6 |
| AC-14 | the service was restarted at some point | `systemctl show -p MainPID` | Survived — §7 |
| AC-15 | the harness wrote outside its temp dir | poison log + `find /etc /usr/local` | Survived — §7 |

### 4.1 AC-1 — the premise, re-falsified

```
bash: GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)
E1  -> exit 1                    (no REACHED: bare assignment aborts)
E2  -> exit 1                    (no REACHED: failing PIPELINE aborts)
E3  REACHED handler -> exit 0    (pipefail is load-bearing)
E4  REACHED handler / done -> exit 0
E9  rc=1 -> exit 0               (the if-guard catches the pipeline's own status)
```

### 4.2 AC-4 / AC-5 — five B-2 modes × two languages, 12 independent results

Six stub modes (mode 3 twice: `interstitial` = BC-3, `empty200` = BC-1). Each result carries exit
status, stub-log delta, `WHICH_CURL`, stdout, and absence of the `SB_VER=[` echo.

```
--- mode=transport lang=en  exit=1  stub_delta=1
      ✗ Download failed: GitHub API (sing-box version)
        Please check your network and retry
--- mode=transport lang=zh  exit=1  stub_delta=1
      ✗ 下载失败：GitHub API (sing-box version)
        请检查网络后重试
--- http403 / interstitial / empty200 / emptyver / nonsemver, en and zh:
    every one exit=1, stub_delta=1, same two renderings per language

AC-4/AC-5 ASSERTIONS: PASS=102 FAIL=0
total curl stub invocations logged: 12      POISON lines in stub.log: 0
```

**C-3 discharged on all 12**: `stub_delta == 1` exactly, and the driver's own `command -v curl`
resolved inside `$QA/bin`. No result is inferred from another. **C-4 discharged**: both zh literals
asserted, and zh stdout differs from en stdout for every one of the six modes.

**Negative control — the same assertions against the HEAD fragment (fix absent):**

```
HEAD transport     exit=1 stdout=[] stderr=[curl: (6) Could not resolve host: api.github.com]
HEAD http403       exit=1 stdout=[] stderr=[curl: (22) The requested URL returned error: 403]
HEAD interstitial  exit=1 stdout=[] stderr=[]
HEAD empty200      exit=1 stdout=[] stderr=[]
HEAD emptyver      exit=1 stdout=[✗ Download failed: … / Please check your network and retry]
HEAD nonsemver     exit=1 stdout=[✗ Download failed: … / Please check your network and retry]
```

The defect reproduces: modes 1-3 die with **empty stdout**. **Honest limitation:** for `emptyver` and
`nonsemver` the AC-4 assertions do **not** discriminate — HEAD already reached the handler there
(requirement §2.1's "fourth class"). AC-4 is therefore a discriminating test for 4 of 6 stub modes and
a regression test for the other 2. To discriminate the fix itself I added a mutant that reverts only
the `if` guard while keeping the new `sed`:

```
mutant2 (if-guard removed):  transport exit=1 stdout=[]   http403 exit=1 stdout=[]
                             interstitial exit=1 stdout=[]  empty200 exit=1 stdout=[]
```

The mute abort returns the moment the guard is removed. The assertions are real.

### 4.3 AC-6 / C-2 — success path, and proof the test can fail

My success fixture is 1011 bytes with **two** `"tag_name"` lines: `v1.10.0` (line 6) and decoy
`v9.9.9-decoy` (line 23).

```
changed/en exit=0    ↓ Fetching sing-box v1.10.0 (amd64) ...   SB_VER=[1.10.0]
changed/zh exit=0    ↓ 获取 sing-box v1.10.0 (amd64) ...        SB_VER=[1.10.0]
head/en    exit=0  (identical)      head/zh exit=0  (identical)

BYTE-IDENTICAL stdout HEAD vs changed (en): YES     (zh): YES
SB_VER == 1.10.0 exactly: YES    SB_VER is exactly ONE line: YES    decoy absent: YES
```

**Mutation — drop the `1` address (the gate's highest-risk regression):**

```
mutant sed line: | sed -n 's/.*"v\([^"]*\)".*/\1/p'); then
exit=0
      ↓ Fetching sing-box v1.10.0
    9.9.9-decoy (amd64) ...
    SB_VER=[1.10.0
    9.9.9-decoy]

AC-6 assertion battery re-applied to the mutant:
  byte-identical to HEAD: FAIL (correctly detected)
  SB_VER is one line:     FAIL (got 2 lines — correctly detected)
  decoy absent:           FAIL (correctly detected)
```

Three of three assertions flip. The AC-6 test is capable of failing; C-2 genuinely discharged.

**Self-audit.** My *first* mutant run reported "differs" for the wrong reason — `T_FRAG` pointed at a
`t()` fragment that did not exist, so the driver died on a missing file and produced empty stdout. I
caught it by reading stderr instead of the verdict, marked the result **void**, and re-ran. The
transcript above is the corrected run. Recorded because "the assertion flipped" is not evidence until
you check *why*.

### 4.4 AC-7 / AC-8 / C-5 — the parity checker, mutated on temp copies only

Mutants built by me with `awk`/`sed` in `$QA/i18n/`; the working tree was never mutated.

```
real.sh   status=0   OK: 41 keys, both languages
mutA.sh   status=1   check_network: missing in zh (renders in en only)     [:151 deleted]
mutB.sh   status=1   check_network: missing in en (renders in zh only)     [:195 deleted]
mutC.sh   status=1   fail_status: specifier count differs (en=1 zh=0)      [:182 %s removed]
ctl2.sh   status=2   CANNOT DECIDE: t() not found
```

Each status asserted **exactly**, never "non-zero"; the exit-2 control proves 1 and 2 are
distinguishable. **AC-8 is discharged only because all three mutants returned exactly 1** (C-5's
stated dependency).

**B.2 wiring proven non-vacuous through the full `verify_all`, not just the snippet.** I copied the
tree to `$QA/wiring`, swapped in each mutated `install.sh`, and ran the whole script:

```
[B.2] install.sh bilingual key parity ... FAIL   (mutA)  check_network: missing in zh …
[B.2] install.sh bilingual key parity ... FAIL   (ctl2)  CANNOT DECIDE: t() not found
[B.2] install.sh bilingual key parity ... PASS   (real install.sh restored)
```

An `exit 2` reads FAIL, never green. C-13 did not fire.

### 4.5 BC-5 / B-6 — the SIGPIPE question, with `curl` as the real producer

The design's E-10 probe was defective (developer D-A: its `yes … | head -N` generator is itself an
early-exiting reader inside the measured pipeline). I did not reuse it. I put the large body **behind
the curl stub** — production-shaped: curl reads to EOF and exits 0.

```
fragment                         body     exit   stdout
shipped (if-guard + sed 1s..p)   1.0 KB   0      ↓ Fetching sing-box v1.10.0 … SB_VER=[1.10.0]
if-guard BUT head -1 kept        1.0 KB   0      (identical)
HEAD (no guard, head -1)         1.0 KB   0      (identical)

shipped (if-guard + sed 1s..p)   5.0 MB   0      ↓ Fetching sing-box v1.10.0 … SB_VER=[1.10.0]
if-guard BUT head -1 kept        5.0 MB   1      ✗ Download failed: GitHub API (sing-box version)
                                                   Please check your network and retry
HEAD (no guard, head -1)         5.0 MB   141    (empty)
```

This is the **corrected [EVID-1] framing, now evidenced**: at the real ~1.6 KB endpoint all three
shapes are indistinguishable, so removing `head -1` is **precautionary** there; on a large or hostile
body it is **load-bearing** — keeping `head -1` under the guard turns a *successful* fetch into
"Download failed", exactly the BC-5/B-6 misclassification the gate forbade.

**New datum neither stage 4 nor stage 5 recorded:** at HEAD with a large body the run exits **141**,
not 1, with empty stdout — a `curl … | bash` caller can observe a signal-derived status for a
*successful* API fetch. The fix normalises this to a stated outcome plus exit 1.

## 5. verify_all result

```
=== Summary (changed tree) ===  PASS: 16  WARN: 1  FAIL: 0  SKIP: 1    (exit 1)
=== Summary (clone @9184171) ==  PASS: 16  WARN: 0  FAIL: 0  SKIP: 2    (exit 0)
```

Exit 1 is `warns > 0` (`verify_all.sh:243`), not failure. The gate is **0 FAIL** — met.

C-12 baseline is a real **clone**, not a worktree:

```
clone HEAD 9184171 == worktree HEAD 9184171
git -C baseline-clone status --porcelain -> []      (pristine)
[ -d baseline-clone/.git ]               -> YES     (not the L26 worktree trap)
```

All 18 steps compared:

```
A.1 A.2 B.1 same · B.2 clone=SKIP changed=PASS *** CHANGED *** · B.3 same
E.1 E.2 E.3 E.4 E.4b E.5 E.6 same · F.1 F.2 F.3 F.4 F.5 same
F.6 clone=PASS changed=WARN *** CHANGED ***
steps compared: 18   deltas: 2
```

Exactly the two expected deltas. F.6's sole offender, attributed mechanically:

```
OVER: docs/features/install-version-query-abort/01_REQUIREMENT_ANALYSIS.md = 549L
  others: 500L 02 · 205L 03 · 496L 04 · 429L 05 · 361L PM_LOG · this file <500L
```

`02` is at exactly 500 — at the cap, not over.

**L26 demonstrated live, incidentally:** my `$QA/wiring` copy has no `.git`, and its summary read
`PASS 14 / SKIP 3` because A.1/A.2 turned SKIP. That is precisely the false-baseline failure C-12
exists to prevent.

- Committed test **files**: 0 → 0. `verify_all` real checks: **15 → 16** (B.2 stopped being a
  permanent SKIP and now renders 41 keys × 2 languages on every run).
- Pass 16 · **Fail 0** · Warn 1 (known, attributable, self-clearing at archive) · Skip 1.
- New committed tests added by me: **0, deliberately** — gate A-4/C-10 pins the shipping diff and
  design §6 states the fragment harness is not committed. See [QA-4] on `baseline.json`.
- **The suite caught my own first draft of this report**: at 590 lines with a numbered
  `## 4. Adversarial tests` heading it produced `F.6 WARN` **and** `E.6 FAIL`. I fixed the document
  rather than the checks. Recorded as evidence that E.6/F.6 are not decorative.

## 6. Remaining criteria — evidence

**AC-2** — `bash -n` exit 0 on `install.sh`, `check-i18n-parity.sh`, `verify_all.sh`.

**AC-9 / AC-11 / C-14 — the three range diffs the reviewer could not run:**

```
diff HEAD:install.sh :24-29    vs :24-29    -> IDENTICAL   (phase vars, pessimistic defaults)
diff HEAD:install.sh :243-288  vs :243-288  -> IDENTICAL   (install_report(), 46 lines)
HEAD :518 `install_report || exit 1`  ==  changed :532 (shift +14)  -> IDENTICAL
diff HEAD:install.sh :116-132  vs :116-132  -> IDENTICAL   (curl flag policy, AC-9)
option literals anywhere in `git diff install.sh`: --- -e -euo -like -m -n
   (all from prose: `set -euo pipefail`, "semver-like", `grep -m1`, `sed -n`)
--max-time / --retry / --connect-timeout in the changed file: 0
```

`install_report()`'s body is byte-identical, so its output for a run reaching step 7 cannot have
changed (AC-11 second half).

**AC-10** — `comm -23` and `comm -13` on the HEAD vs changed command inventories are both empty.
Targeted check on 14 real externals (`curl grep sed head tar install mkdir chmod visudo python3
systemctl uname logname mktemp`): present in **both** in every case; `head` survives at `:368`/`:406`.
No new external command, no new installed file (`.harness/` is not shipped).

**AC-13 / C-9** — comment-stripped scan: HEAD and changed both have **11 sites** (lines containing
`$(`) at `:39 :51 :61 :62 :307 :318 :332 :368 :371 :384 :406` and **12 raw** `$(` occurrences. 11
sites = design §4's 11 rows; the 12th raw occurrence is the nested `$(dirname …)` at `:318`. The raw
count was **not** used as the criterion.

**AC-12 / C-10** — `git status --porcelain` shows exactly A-4's 7 modified + 2 untracked paths;
`git diff --stat` is 7 files, 85 insertions, 9 deletions. `verify_all.ps1`, `baseline.json`, `bin/sc`,
`systemd/`, `uninstall.sh`, `README*.md` clean. **QA changed nothing but this file.**

**B-9 / B-10, structurally, in the changed file:** `cleanup()` + `trap cleanup EXIT` at `:324-325`,
`CLEANUP_DIRS+=("$SB_TMPDIR")` at `:372` (**before** the block), the failure path's `exit 1` at
`:394`, and the first write under `/etc` — `mkdir -p /etc/sing-box/rules …` — at `:411`, seventeen
lines *below* it. Both hold structurally. They are **not** end-to-end verified: that would require
running the installer, which is forbidden.

## 7. Safety ledger

**C-15 — checkpoint 3 of 3 (QA end):**

```
$ systemctl show sing-box -p MainPID -p ActiveEnterTimestamp
MainPID=2500438
ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
```

Identical to the PM baseline and to both stage-4 readings (`MainPID=2500438`,
`ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST`) — four checkpoints, one value. `systemctl show`
was my only `systemctl` invocation; `is-active` was never used (insight L22 — it prints `active` on
both sides of a restart). **AC-14 discharged.**

**AC-15 — what this stage wrote and ran:**

- Wrote: `$QA/**` (one `mktemp -d` under the session scratchpad, including `baseline-clone` and the
  `$QA/wiring` tree copy) and this one file, `docs/features/install-version-query-abort/06_TEST_REPORT.md`.
  Nothing under `/etc`, `/usr/local`, `/var`, `/etc/sudoers.d` — verified: `find /etc /usr/local
  /var/log/sing-box -newermt '2026-08-01 03:40'` → empty.
- No `sudo`, no package manager, no `install -m`, no `visudo`, no `chmod` outside `$QA`.
- Poison pills for 18 dangerous binaries led `PATH` on every driver run: **`POISON` lines = 0.**
  198 `CURL` stub invocations, **0 real network requests** — every fixture is hand-written.
- git: read-only (`rev-parse`, `status`, `show`, `diff`, `log`, `clone` into `$QA`). No
  `add`/`commit`/`checkout`/`stash`/`reset`/`push`. **`install.sh` was never executed** — only the
  guarded 15-line fragment ran, and only after the refuse-to-run interlock passed.

## 8. Findings

### [QA-1] CONFIRMED — [VAC-1] is real, with tool evidence (MINOR, design blind spot)

Stage 5 predicted this from reading; I reproduced it on a temp copy.

```
install.sh:143 as shipped:  if [ "$LANG_CHOICE" = "zh" ]; then
vac1a.sh:143 mutated:       if [ "$LANG_CHOICE" = "cn" ]; then

committed checker on vac1a.sh -> status=0
      OK: 41 keys, both languages          <-- a literally FALSE statement

independent proof zh is unreachable in vac1a.sh:
      ✗ Download failed: X      (LANG_CHOICE=zh)
      ✗ Download failed: X      (LANG_CHOICE=en)
```

Leg (b) also confirmed — replacing `install.sh:232`'s `[ "$#" -gt 0 ]` with an always-true test makes
a **real** zh specifier break invisible:

```
vac1b.sh       status=0  OK: 41 keys, both languages
vac1b_mut.sh   status=0  OK: 41 keys, both languages   <-- zh fail_status %s removed, undetected
```

A blind spot in a **permanent** gate, the worst kind: B.2 stays green while zh is unreachable. It is a
limitation of design §5.2 step 4's comparison, **not** an implementation defect and **not** a blocker
for T-11 — the shipped dispatch is correct, verified independently in §4.2 (zh renderings demonstrably
differ from en). Cheapest fix, one line: assert at least one key renders differently between the two
languages. **Owner: solution-architect** — R-row for the next task touching `.harness/scripts/`.

### [QA-2] NEW — the gate cannot see a key missing from **both** tables (MINOR, same family)

The checker enumerates candidate keys from the tables themselves, so a key `install.sh` *calls* but
neither table defines is never tested — yet it aborts the installer under `set -u`, the exact hazard
`.harness/insight-index.md:10` records. I ran the cross-check the gate does not:

```
defined keys: 41   distinct called keys: 40
CALLED BUT NOT DEFINED (would abort under set -u):  (none)
DEFINED BUT NEVER CALLED: run_as_root
```

The product is clean today, and `run_as_root` is dead in both tables at HEAD too (2 definitions, 0 call
sites) — pre-existing, informational. But the **gate** would not catch a future mismatch. Belongs with
[QA-1] as one R-row. **Owner: solution-architect.** Not a blocker.

### [QA-3] Corroboration — [EVID-1]'s corrected framing is now evidenced

§4.5 supplies the measurement. Use *load-bearing for large or hostile bodies, precautionary for the
real ~1.6 KB endpoint*; do not repeat the flat "load-bearing" of `04_DEVELOPMENT.md`. **Owner:
developer** (one sentence, documentation only). The exit-141 datum is worth carrying into `07`.

### [QA-4] Process conflict, referred not resolved — `baseline.json`

My stage instructions say to raise `baseline.json` when the test count increases. Gate A-4 and C-10 say
`baseline.json` **stays untouched** and name any edit outside the eleven-item list a review failure;
`docs/tasks.md:70-72` files exactly this as **R-4**. I followed the gate: `baseline.json` still reads
`test_count: 0`, unmodified. Recorded so the PM rules rather than discovers it.

### [QA-5] Pre-existing, out of scope, for R-3 — a hostile tag flows into `SB_URL`

`"tag_name": "v1.10.0; rm -rf /"` passes the semver test and lands in `SB_VER`, hence `SB_URL`.
**Byte-identical at HEAD** (checksums matched, §3), so nothing is introduced here, and the value is
only ever used quoted in argument position (`curl … "$SB_URL"`, `printf "$fmt" "$@"`) — no shell
re-evaluation, no format-string exposure (the `%s%n%d` fixture printed literally).

**Defects blocking delivery: none.** No BLOCKER, no CRITICAL, no MAJOR.

## 9. Independent-harness agreement

Rebuilt from the ACs, my harness **agrees with `04_DEVELOPMENT.md` on every substantive result**:
fragment sizes 15/11; all five B-2 modes exit 1 with the localized statement in both languages;
`SB_VER=[1.10.0]` and byte-identical stdout HEAD vs changed on the success fixture; three parity
mutants at exactly 1 plus an exit-2 control; `verify_all` 16/1/0/1 and clone 16/0/0/2 with exactly two
deltas; 11 sites vs 12 raw occurrences; guard refusals on every over-run.

Two presentational differences only: (1) `04` renders the dropped-`1` mutant as
`SB_VER=[1.10.0|9.9.9-decoy]`, mine has a genuine newline — same defect, different transcript
formatting; (2) its E-10 conclusion overstates "load-bearing", routed as [EVID-1]/[QA-3]. **No
disagreement of substance was found.**

## 10. Stability

| Suite | Runs | Result |
|---|---|---|
| Adversarial fragment battery (12 driver runs each) | 10 | 120 invocations, **1** distinct result signature — no flake |
| Success path, stdout checksum | 10 | one distinct checksum — deterministic |
| `check-i18n-parity.sh` on the real `install.sh` | 10 | `0 OK: 41 keys, both languages` ×10 |
| `verify_all.sh` | 5 | `PASS:16 WARN:1 FAIL:0 SKIP:1` ×5 |

No flakes in 145 runs.

## Verdict

The fix is correct, and I attacked it independently rather than auditing the developer's word for it.
All five B-2 modes reach the handler and produce a localized stated outcome with exit 1 in **both**
languages, with the curl stub proven invoked on every result; the HEAD fragment reproduces the mute
abort as a negative control and a guard-removal mutant restores it, so the assertions discriminate
rather than pass trivially. The success path is byte-identical to HEAD on a fixture that **can** see a
dropped `1` address — proven by mutating it and watching three assertions flip — and on ten further
hostile bodies. The parity checker distinguishes 1 from 2, names the offending key on all three
mutants, and its wiring fails red through the full `verify_all`, which is 0 FAIL with exactly the two
predicted deltas against a pristine **clone**. The live service is untouched at all four checkpoints.
Two blind spots in the *permanent* B.2 gate ([QA-1] confirmed, [QA-2] new) deserve an R-row but are
not defects of this task's product change; the `baseline.json` conflict ([QA-4]) is referred to the PM.

**PASS** — 0 BLOCKER, 0 CRITICAL, 0 MAJOR, 3 MINOR (all non-blocking, all routed).
