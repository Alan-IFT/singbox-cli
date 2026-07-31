# 02 — Solution Design · T-11 `install-version-query-abort`

- Mode: **full** · Decision mode: **deferred-human** · Partition: **single-developer** · Stage 2, 2026-08-01
- Binding input: `01_REQUIREMENT_ANALYSIS.md` (`READY FOR DESIGN`). Read: `AI-GUIDE.md`, rules
  `85-design-discipline` / `50-singbox-cli`, `.harness/insight-index.md` (28/30),
  `.harness/rejected-decisions.md`, `docs/dev-map.md`, `CONTEXT.md`, `PM_LOG.md` (PM-1/2/3),
  `install.sh` at HEAD `22502f9`.

---

## 0. AC-1 — the shell-semantics experiment, discharged by the PM pre-flight

AC-1 assigned experiment E-0 to this stage. This stage has **no shell tool** (Read/Glob/Grep only);
the PM detected the capability gap and ran E-0 as a pre-flight, re-homing AC-1 there
(`PM_LOG.md` § "PM pre-flight"). Transcript, on `GNU bash 5.2.21(1)-release`, **7/7 MATCH**:

```
E1 bare assignment, failing command
  -> exit 1
E2 bare assignment, failing PIPELINE (grep finds nothing)
  -> exit 1
E3 same, WITHOUT pipefail
REACHED handler
  -> exit 0
E4 assignment inside an if condition
REACHED handler
done
  -> exit 0
E5 local masks the status - the real exemption
REACHED after local
  -> exit 0
E6 substitution as an ARGUMENT to a command
[]
REACHED
  -> exit 0
E7 assignment whose list ends in || true
REACHED, V=[]
  -> exit 0
```

**The stop rule was not triggered** — E1 and E2 printed no `REACHED`, so the defect is real and the
premise stands; E5/E6/E7 matched, so §2.3's sweep verdicts are cleared. Two further PM-commissioned
probes, carrying no design preference:

- **E8** — `f() { V=$(false); …}; f` at top level: neither line printed, exit 1. The abort fires
  inside a function body exactly as at top level → relocating the assignment into a helper does not
  avoid it, so no `fetch_sb_version()` helper is proposed.
- **E9** — `if V=$(printf "x\n" | grep zzz | head -1); then … else echo "rc=$?"; fi`: else-branch
  ran, `$?` was the pipeline's `1`, overall exit 0, `V` captured on the success leg without a second
  evaluation → the `if`-guard is the mechanism.

**Every shell fact this design relies on is covered by E1-E9.** The design deliberately depends on
*no* unverified semantics (in particular it does not depend on whether an assignment survives a
failing substitution, nor on `VAR=$(…) || true`'s exemption — see §3.2). One optional-but-cheap
probe is commissioned for stage 4 as **E-10** (§10).

---

## 1. Architecture summary

`install.sh` step 2 stops terminating at the version-query assignment and starts *judging* the
version it extracted. The pipeline is placed in an `if` condition — one of `set -e`'s exempt
contexts (E4/E9) — so its status is caught rather than fatal, and `head -1` is replaced by
`sed -n '1s…p'` so that no element of the pipeline can be killed by a downstream reader closing the
pipe (BC-5/B-6). The already-written validation at `install.sh:377` becomes the **single judge** of
whether the version is usable, and therefore the single place all five failure modes of B-2 converge
on; the handler it guards (`t download_failed` / `t check_network` / `exit 1`) is unchanged. No new
message key, no new variable beyond `SB_VER` itself, no change to `install_report()` or to the phase
machinery (AC-11 holds with **no** exception), no curl option touched (AC-9). Outside the product
file, one new harness script asserts bilingual key parity of `t()` and replaces `verify_all.sh`'s
permanently-`SKIP` B.2.

## 2. Affected modules

| Path | Change | Why |
|---|---|---|
| `/home/alan/Programs/singbox-cli/install.sh` | edit, step 2 only (`:373-381`) | the defect |
| `/home/alan/Programs/singbox-cli/.harness/scripts/check-i18n-parity.sh` | **new** | B-8 |
| `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` | edit, B.2 only | B-8 wiring |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | append | user-visible fix |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | append 2 rows | new script + new pattern |
| `/home/alan/Programs/singbox-cli/docs/tasks.md` | append R-1…R-6 | B-12 / re-homed rows (PM numbers) |
| `/home/alan/Programs/singbox-cli/docs/features/install-version-query-abort/` | task docs | pipeline |

Not touched, by O-1/O-2/AC-12: `bin/sc`, `systemd/`, `uninstall.sh`, `README*.md`,
`baseline.json`, `verify_all.ps1` (R-6), every `CURL_OPTS_*` line (`install.sh:116-132`).

## 3. The fix at `install.sh:373-381`

### 3.1 Intended post-change code (verbatim; the developer types this)

```bash
    # Under `set -euo pipefail` a bare VAR=$(pipeline) carries the pipeline's own
    # status, so a failed fetch terminated the installer HERE — before the
    # validation below, which is the only code that can say what went wrong (T-11).
    # `if` is one of set -e's exempt contexts, so the status is caught, not fatal.
    #
    # NO ELEMENT OF THIS PIPELINE MAY EXIT BEFORE EOF. `head -1` was removed for
    # exactly that reason: a reader that closes the pipe early (head, grep -m1,
    # sed q) can kill an upstream element with SIGPIPE, and `pipefail` would then
    # report a SUCCESSFUL fetch as a failed one. `sed -n '1s…p'` reads to EOF and
    # still yields only the first matching line, as `head -1` did.
    SB_VER=""
    if ! SB_VER=$(curl "${CURL_OPTS_QUIET[@]}" "https://api.github.com/repos/${SB_REPO}/releases/latest" \
        | grep '"tag_name"' \
        | sed -n '1s/.*"v\([^"]*\)".*/\1/p'); then
        SB_VER=""
    fi
    # Validate that we got a semver-like string (e.g. "1.10.0"). This is the ONLY
    # judge of whether the version is usable; the pipeline's status never decides.
    if [ -z "$SB_VER" ] || ! echo "$SB_VER" | grep -qE '^[0-9]+\.[0-9]+'; then
        t download_failed "GitHub API (sing-box version)"
        t check_network
        exit 1
    fi
```

Everything from `SB_URL=` (`:382`) onward is byte-identical to HEAD.

### 3.2 Why this shape and not the alternatives

| Alternative | Rejected because |
|---|---|
| `SB_VER=$(…) \|\| true` | Textbook-exempt (non-last element of an `\|\|` list) but **not covered by E1-E9** — E7 only proved the *inner* `$(false \|\| true)` form. Adopting it would make the design rest on an unverified fact, which §0 forbids. Also keeps the value only by relying on assignment-survives-failure semantics. |
| `if ! SB_VER=$(…); then :; fi` (keep whatever was captured) | Immune to SIGPIPE even with `head -1`, but depends on the same unverified "the assignment happens although the substitution failed" fact, and reads as a no-op to the next maintainer. |
| Move the query into `fetch_sb_version()` and call it | **E8 proves this does not work**: the abort fires inside a function body identically. It would only work if the *call* sat in an exempt context — i.e. the same `if` guard, plus a function. Rule 85's counter-rule: a function that buys nothing. |
| `set +e` / `set +o pipefail` around the query | Turns a global invariant off and on for three lines; any later `return`/`exit` path between them leaks the relaxed state. |
| Keep `head -1` and guard with `if` | **Violates B-6/BC-5.** A 1.6 KB body will usually fit the pipe buffer, but "usually" is exactly what BC-5 forbids: if `head -1` exits first, `curl`/`grep` can die of SIGPIPE, `pipefail` propagates it, the guard's failure leg wipes `SB_VER`, and a *successful* fetch is reported as a failed one. Structural immunity beats a race that reproduces once a year. |
| Two-stage (capture body to `SB_API`, then extract) | Also immune, but adds a variable, a second `if`, and a second failure classification for no behavioural gain once `head` is gone. |

`sed -n '1s/…/\1/p'` is equivalent to `head -1 | sed 's/…/\1/'` on the success path: `grep` emits only
`"tag_name"` lines, `1s` applies to the first of them, and `p` under `-n` prints it. It differs only
where HEAD would have echoed a *non-matching* first line unchanged (a tag with no leading `v`,
BC-4): HEAD emits the whole JSON line, this shape emits nothing. Both land on the same handler
(B-2.4 vs B-2.5 — indistinguishable to the user by D-1), so the observable outcome is identical and
the success path is byte-identical (B-5, AC-6). No command is added: `grep` and `sed` are already
invoked here; `head` is only removed (AC-10 compares invoked-command *sets*, and `head` still occurs
at `:368`/`:392`, so the set is unchanged).

### 3.3 Control flow, all five B-2 modes

```
                curl -f -s -S -L  https://api.github.com/…/releases/latest
                        |                 (CURL_OPTS_QUIET, install.sh:128 — untouched)
   mode 1 transport ────┤ exit 6/7/35, stderr: raw curl line, stdout empty
   mode 2 non-2xx   ────┤ exit 22 (-f), stdout empty
   mode 3 interstitial ─┤ exit 0, stdout HTML / empty body
   mode 4/5 odd tag ────┤ exit 0, stdout real JSON
                        v
                grep '"tag_name"'      -> reads to EOF; exit 1 (modes 1,2,3) / 0 (4,5)
                        v
                sed -n '1s…p'          -> reads to EOF; never exits early
                        v
        pipefail status: non-zero (1,2,3)          zero (4,5)
                        v                            v
        `if !` failure leg: SB_VER=""        SB_VER = "" | "nightly" | "1.10.0"
                        \                            /
                         v                          v
        if [ -z "$SB_VER" ] || ! grep -qE '^[0-9]+\.[0-9]+'   <-- the single judge
                  true (1,2,3,4,5)          |        false (well-formed)
                        v                   |             v
        t download_failed "GitHub API …"    |     SB_URL=… ; t fetching_item … (unchanged)
        t check_network                     |
        exit 1  -> trap cleanup EXIT (:325) removes SB_TMPDIR + ARTIFACT_DIR (B-10)
                -> nothing under /etc exists yet: mkdir is :397, step 3 (B-9)
```

Modes 1 and 2 additionally leave curl's raw English line on stderr (kept by `-S`, `:126`); that line
is not the stated outcome and is not suppressed — suppressing it would need a curl option change
(AC-9 forbids) and it is genuine diagnostic detail *below* the localized statement.

### 3.4 D-4 — reuse `download_failed` / `check_network`. **No new key.**

Rendered (en): `✗ Download failed: GitHub API (sing-box version)` + `  Please check your network and
retry`; (zh): `✗ 下载失败：GitHub API (sing-box version)` + `  请检查网络后重试`. Judged against B-4:
it names the sing-box version query against the GitHub API as the thing that failed (the argument
says so literally); it states a next action; it asserts nothing about config generation, the config
check, the service or rule-sets; it names no command this run has not installed. True of all five
modes — in every one of them, *obtaining the version* is what failed, which is what the argument
names. The residual imprecision (mode 3 is a successful HTTP transfer) does not reach a false
statement, and "check your network" is in fact the right next action for a captive portal.

Consequences accepted, stated because they matter downstream: (a) the parity surface stays at zero,
which is what `t-fmt-default-fallback` in `.harness/rejected-decisions.md` prescribes as the
per-task mitigation ("fewer keys"); (b) **D-2's reason 1 weakens** — the parity check no longer
guards a *new* string. B-8 is nevertheless a binding behavior, not a conditional one, and PM-3's
only overturn condition is parser fragility, which §5 shows does not apply.

### 3.5 The reporting route — explicit early exit, **not** `install_report()`

**Decision: keep the early exit.** AC-11 therefore holds with **no exception at all**: the three
phase variables, their pessimistic defaults, `install_report()`'s success condition and body, and the
closing `install_report || exit 1` (`:518`) are byte-identical to HEAD.

Why, judged against B-1/B-4:

1. **As it stands, `install_report()` cannot tell the truth here.** At step 2, `PHASE_CONFIG` is
   still `failed`, so `:263-267` prints `fail_config` ("sing-box did not pass the config check") —
   false, config generation never ran; `PHASE_RULESETS` is `failed`, so `:268-270` prints
   `fail_rulesets` — false; `:273-274` instruct `sc update-rules` / `sc reload`, installed at `:398`,
   i.e. *after* this point; `:276` names `systemctl status sing-box`, a unit written at `:428`; and
   `:285` names `/var/log/sing-box/install.log`, whose directory is created at `:397` (BC-13). Six
   false or useless statements, against a requirement whose whole point is B-4.
2. **Making it tell the truth means giving it two eras.** It would need an era discriminator (a
   `PHASE_PREREQ`, or a `FAIL_REASON`) plus an early-return branch. The two branches would share
   three `echo` lines of banner and nothing else: different judgment ("did config+service succeed?"
   vs "is this version usable?"), different remediation, different vocabulary. Rule 85 test 1 — step
   2 computes nothing `install_report()` consumes; test 2 — no duplicated judgment. **The deletion
   test**: delete that branch and no complexity reappears anywhere; it is a pass-through wrapper
   around two `t` calls.
3. **It contradicts the requirement's own scoping.** O-10 pins `install_report()`'s behavior for a
   run that reaches step 7; an era discriminator is precisely the kind of edit every later
   phase-adding task would then also have to make. **The future edit this choice prevents:**
   "every task that adds a pre-step-7 failure path must extend `install_report()`'s discriminator."
4. **It is the file's established shape for this era.** Six early exits already print and exit
   before step 7 (`:35`, `:47`, `:57`, `:66`, `:313`, `:348`), two of them (`:346-348`, `:385-387`)
   with exactly the two keys this path uses. Reusing that shape is a reuse decision, not a bolted-on
   parallel notion: no new reporting mechanism is introduced, and D-6 keeps the status at 1, so the
   observable contract is identical to the `install_report || exit 1` route.

**Explicitly declined** (rule 85, record in `.harness/rejected-decisions.md` at delivery, handle
`installer-early-exit-download-helper`): folding the three-line
`t download_failed … ; t check_network ; exit 1` idiom into a `fail_download()` helper. Three call
sites make the seam real, but the requirement asks for none of it, and it would put `:346-348` and
`:385-387` — code this task otherwise does not touch — into the diff, weakening AC-9's and B-5's
line-by-line audit for a purely cosmetic gain. Re-homed as **R-5**, together with the wider R-3 class
that would be its natural owner.

## 4. Sibling sweep carried forward (B-12 / AC-13)

One row per command substitution in `install.sh`. HEAD `22502f9` has **11**; the change adds and
removes none, so the changed file also has **11** — the developer must not add or remove one.
Anchors are HEAD line numbers; sites below the edit shift by the block's growth (+11 lines).

| # | HEAD line | Site | Verdict for the changed file |
|---|---|---|---|
| 1 | 39 | `PKG_MGR=$(type -P apt-get \|\| … \|\| true)` | Not the defect — list ends in `true`, status forced 0 (E7). Handler `:40-48` reachable. Untouched. |
| 2 | 51 | `case "$(uname -m)" in` | Not the defect — the substitution's status is not the `case`'s (E6). Empty word falls to `*)` `:54-57`. Untouched. |
| 3 | 61 | `IS_SYSTEMD=$(type -P systemctl \|\| true)` | Not the defect — status forced 0. Handler `:63-67`. Untouched. |
| 4 | 62 | `IS_OPENRC=$(type -P rc-service \|\| true)` | Not the defect — same handler. Untouched. |
| 5 | 307 | `INSTALL_USER="${SUDO_USER:-$(logname … \|\| echo "")}"` | Not the defect — inner list ends in `echo`. Handler `:308-315`. Untouched. |
| 6 | 318 | `SCRIPT_DIR="$(cd … && pwd \|\| echo "")"` | Not the defect — status forced 0; handler is the `-n` test at `:327`. Untouched. |
| 7 | 332 | `ARTIFACT_DIR="$(mktemp -d -t …)"` | Same mechanism, **out of scope by D-3/O-8** — no handler below is made unreachable and `mktemp` prints its own diagnosis. **R-1**. Untouched. |
| 8 | 368 | `t step2_already "$(sing-box version \| head -1)"` | Not an abort (argument position, E6); latent *display* defect. **R-2**. Untouched. |
| 9 | 371 | `SB_TMPDIR="$(mktemp -d)"` | As #7. **R-1**. Untouched. |
| 10 | **373** | **`SB_VER=$(curl … \| grep … \| sed …)`** | **THE DEFECT — fixed here** (§3.1): moved into an `if` condition, `head -1` removed. |
| 11 | 392 | `t step2_done "$(sing-box version \| head -1)"` | As #8. **R-2**. Untouched. |

Not command substitutions and deliberately not claimed fixed (O-7, **R-3**): bare `python3` heredoc
`:403-417`, `tar -xz` `:390`, `install -m` `:391`/`:398`/`:399`/`:428-430`, `chmod` `:454`/`:462`,
`visudo -c` `:463`. T-01's guarantee is still not global after this task (D-7).

## 5. B-8 — the bilingual key-parity check. **It ships; no fifth deferral.**

PM-3's overturn condition is "cannot be written without a fragile parser of the two `case` blocks".
It can: **the parser's only job is to enumerate candidate key names; the judgment is behavioural.**

### 5.1 Module: `.harness/scripts/check-i18n-parity.sh`

Responsibility: assert that `install.sh`'s `t()` renders every key in **both** languages and with the
same number of `printf` conversion specifiers. Public interface:

```
check-i18n-parity.sh [FILE]      FILE defaults to <script dir>/../../install.sh
exit 0  parity holds            (prints "OK: N keys, both languages")
exit 1  parity broken           (one line per offending key on stdout: key, what differs)
exit 2  cannot decide           (t() not found / no keys parsed / a fmt= line not parsed)
```

`exit 2` is a hard failure for the caller, not a pass: a file the check cannot read must never be
reported green.

### 5.2 Algorithm

1. **Extract** `t()` by function-boundary anchors — from the line `^t() {` to the **first** following
   line `^}` — into a `mktemp` file. Both anchors sit at column 0 and nothing inside the body starts
   at column 0 (`install.sh:139-238` verified: `case` closes with `esac`), so the range is exact.
   Empty extraction → exit 2.
2. **Enumerate candidate keys** from the extracted text: every line matching
   `^[[:space:]]*([A-Za-z0-9_]+)\)[[:space:]]*fmt=`, take the **union** across both `case` blocks —
   never attributing a key to a block. Assertion: **every line in the fragment containing `fmt=`
   must have produced a key**, else exit 2. This closes the only false-PASS hole (a reformat the
   parser silently skips in *both* blocks).
3. **Render behaviourally.** For each language `L ∈ {en, zh}`, run one `bash` child: `set -u`, source
   the fragment, `LANG_CHOICE=L`, then for each key `k` capture `out=$( t "$k" 2>&1 )` inside a
   subshell and record `k`, the subshell's status and `out`. A key missing from that table leaves
   `fmt` unset and `printf "%s\n" "$fmt"` aborts the subshell under `set -u` — **the production
   failure mode itself** (`.harness/insight-index.md:10`), not a proxy for it. The outer loop
   survives because the check script does not use `set -e`.
4. **Compare.** Per key: both statuses 0 and both outputs non-empty (else "missing in <lang>"), then
   equal specifier counts — count `%` after deleting every `%%`, since `t()` calls `printf "$fmt"`
   with the key's arguments (`:232-234`). Print a one-line summary; exit 0/1/2.

Why this is not fragile: over-inclusion (a stray token read as a key) fails *both* renders → loud
FAIL, never a silent PASS; under-inclusion is caught by step 2's assertion; misattribution is
impossible because attribution is never used; and the `case`-block boundary (`else` at `:187`) is
never parsed at all. The fragment is self-contained — `t()` reads only `LANG_CHOICE`, `$1…$@` and
`printf` (verified `:139-238`) — so sourcing it defines a function and executes nothing.

**Safety:** it never sources or executes `install.sh`, writes only inside `mktemp`, runs no installer
command, and needs no root and no network.

### 5.3 Wiring into `verify_all.sh` (B-8, BC-16)

Replace the `step "B.2" "Tests pass" "SKIP"` line (`.harness/scripts/verify_all.sh:70`), inside the
preserved `HARNESS:B-CUSTOM` markers, with:

```bash
if [[ -x .harness/scripts/check-i18n-parity.sh || -f .harness/scripts/check-i18n-parity.sh ]]; then
    b2_out=$(bash .harness/scripts/check-i18n-parity.sh install.sh 2>&1); b2_rc=$?
    if [[ $b2_rc -eq 0 ]]; then step "B.2" "install.sh bilingual key parity" "PASS"
    else step "B.2" "install.sh bilingual key parity" "FAIL" "$b2_out"; fi
else
    step "B.2" "install.sh bilingual key parity" "SKIP"
fi
```

The step is **renamed** rather than left as "Tests pass": one parity check is not a test suite, and
rule 50's demand is that a permanently-`SKIP`ping check stop proving nothing. B.3 (lint) stays SKIP.
Expected summary flip: `PASS 15 → 16`, `SKIP 2 → 1` (plus PM-1's known F.6 WARN, which self-clears at
archive). `.harness/scripts/verify_all.ps1` is **not** updated — it is outside AC-12's diff surface;
recorded as **R-6** so the mirror's divergence is not silent.

## 6. Verification harness (AC-4/AC-5/AC-6) — safety-critical, do not improvise

`.harness/insight-index.md:13` records why this section is prescriptive: a test once re-execed the
*installed* tool under sudo and restarted the owner's live sing-box. **`install.sh` is never run, in
whole or in part, by any stage of this task.** The harness lives in a `mktemp -d` and is pasted into
`06_TEST_REPORT.md`; it is not committed (AC-12 does not permit a new file outside the listed set).

### 6.1 Shape

```
$TMP/
  install.src        cp of the working-tree install.sh   (or `git show HEAD:install.sh` for AC-6)
  t.frag             t() extracted exactly as in §5.2 step 1
  block.frag         the step-2 version-query block, extracted per §6.2
  bin/curl           the stub; $TMP/bin is PREPENDED to PATH
  fixtures/*.json    response bodies
  driver.sh          set -euo pipefail; . t.frag; LANG_CHOICE=$1; ARCH=amd64
                     SB_REPO="SagerNet/sing-box"
                     <the CURL_OPTS_QUIET= line grepped verbatim from install.src>
                     . block.frag ; echo "SB_VER=[$SB_VER]"
```

`driver.sh` **must** carry `set -euo pipefail` — without it the harness proves nothing (E3).
`LANG_CHOICE` is assigned directly, which is how BC-11's "zh is only reachable by answering `2`" is
satisfied with no interactive prompt.

### 6.2 Block extraction + the refuse-to-run guard

Extract from the first line matching `SB_VER=` through the first line matching `t fetching_item`
(i.e. `install.sh:373-383` post-change, the pre-download notice included so AC-6 has a real line to
compare). Then **assert the fragment's shape before running it**, and abort the harness otherwise:

- must contain: `curl`, `grep`, `download_failed`, `check_network`, `exit 1`, `fetching_item`;
- must contain exactly two `fi`;
- **must NOT contain any of**: `install -m`, `tar `, `systemctl`, `rc-service`, `rc-update`,
  `pkg_install`, `visudo`, `chmod`, `mkdir`, `sudo`, `/etc/`, `/usr/local/`.

The denylist is the safety interlock: if a future edit moves the block's boundaries, the harness
refuses to run instead of executing installer lines that write to the system.

### 6.3 The `curl` stub

A ~15-line `bash` script on `$TMP/bin`, selecting behaviour from `$STUB_MODE`, ignoring every option
(it must accept and ignore `-f -s -S -L` so AC-9's untouched flag array is genuinely exercised):

| `STUB_MODE` | stdout | stderr | exit | Covers |
|---|---|---|---|---|
| `transport` | — | `curl: (6) Could not resolve host: api.github.com` | 6 | B-2.1 / BC-2-adjacent |
| `http403` | — | `curl: (22) The requested URL returned error: 403` | 22 | B-2.2 / BC-2 |
| `interstitial` | `<html>…captive portal…</html>` | — | 0 | B-2.3 / BC-3 |
| `empty200` | (zero bytes) | — | 0 | B-2.3 / BC-1 |
| `emptyver` | JSON with `"tag_name": "v"` | — | 0 | B-2.4 |
| `nonsemver` | JSON with `"tag_name": "vnightly"` | — | 0 | B-2.5 / BC-4 |
| `success` | `fixtures/latest.json` (a real ~1.6 KB latest-release body, `"tag_name": "v1.10.0"`) | — | 0 | B-5 / AC-6 |

### 6.4 Assertions

- **AC-4** (5 modes × 1 language, each result observed independently, none inferred): driver exit
  status `1`; stdout contains the `download_failed` rendering with `GitHub API (sing-box version)`
  and the `check_network` line; stdout contains **no** `SB_VER=[…]` echo (the block exited first).
- **AC-5**: repeat all of AC-4 with `LANG_CHOICE=zh`; each asserted line non-empty and containing no
  `unbound variable` — 10 results total.
- **AC-6**: `STUB_MODE=success` against both `install.src` = working tree and `= git show HEAD:` —
  `SB_VER=[1.10.0]` in both, and the `t fetching_item` line byte-identical between the two runs
  (`diff` of captured stdout, both languages).
- **AC-7**: run `check-i18n-parity.sh` against the real file (expect 0) and against two `$TMP` copies
  — one with a key deleted from the zh block only (expect 1, naming that key), one with a `%s`
  removed from one language's `fail_status` (expect 1, naming a specifier-count mismatch). Mutations
  live only in `$TMP`; the working tree is never mutated.

Nothing in §6 reaches `pkg_install`, `systemctl`, `install -m`, `visudo`, or any path under `/etc`,
`/usr/local` or `/etc/sudoers.d`; nothing runs under `sudo`; the only network access permitted is an
optional one-time read of the GitHub API to capture `fixtures/latest.json` (a hand-written body of
the same shape is equally acceptable, and is the fallback when the rate limit bites).

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Localized failure statement | `t()` + `download_failed`, `check_network` | `install.sh:139-238`, `:150-151`, `:194-195` | **Reuse as-is, no new key** (§3.4) |
| curl option policy | `CURL_OPTS_QUIET` | `install.sh:116-132` (T-08, `9184171`) | Consume unchanged (O-2/AC-9) |
| "print, then exit 1" failure idiom for a pre-step-7 transfer | `:345-349`, `:384-388` | `install.sh` | Mirror the shape; **not** factored into a helper (R-5) |
| Closing report + derived exit status | `install_report()`, `PHASE_*`, `install_report \|\| exit 1` | `install.sh:24-29`, `:243-288`, `:518` | **Deliberately not extended** (§3.5); untouched (AC-11) |
| Temp-dir cleanup on any exit | `CLEANUP_DIRS` + `trap cleanup EXIT` | `install.sh:320-325` | Reuse as-is — satisfies B-10 with no new code |
| Extract `t()` for out-of-process use | (none found) | — | New, in `check-i18n-parity.sh`; **the same extraction serves the §6 harness**, so the idea has two consumers, not one |
| Committed parity gate | (none — deferred 4× as `ruleset-unit-tests-in-t02`) | `.harness/rejected-decisions.md:57-73` | New module justified: B-8, PM-3, rule 50 |
| Bilingual parity for `bin/sc` | `TRANSLATIONS` (no `en` table) | `bin/sc`, `docs/dev-map.md:52` | Out of scope (O-9) — different shape, would need a different checker |
| verify_all step slot | `step "B.2" … SKIP` | `.harness/scripts/verify_all.sh:70` | Replace in place, inside the preserved custom markers |

## 8. Data model / API contracts

No schema, no migration, no table, no HTTP surface of our own. The only external contract consumed
is `GET https://api.github.com/repos/SagerNet/sing-box/releases/latest`, whose only field this code
reads is `tag_name` — unchanged from HEAD, unauthenticated (O-4 / D-5 declined). The internal
"contract" that changes is the exit status of one shell statement, which is now caught rather than
fatal; the process exit status on this path stays **1** (D-6), identical to both HEAD's diagnosed
path and `install_report`'s failure status, so B-1 is judged route-neutrally.

## 9. Risks

| # | Risk | Mitigation |
|---|---|---|
| R-a | A later edit re-adds `head -1` / `grep -m1` / `sed q` to the pipeline, restoring the BC-5 misclassification the guard now converts into a wiped `SB_VER`. | The load-bearing comment in §3.1 says so in capitals at the site; `.harness/insight-index.md:28` already records the mechanism; CHANGELOG names it. A mechanical check for this is **not** proposed (would need to parse pipelines) — accepted residual. |
| R-b | The `if` guard is removed by someone "simplifying" the assignment back. | Same comment; AC-4's five results are pasted in `06_TEST_REPORT.md` as the regression witness; the shape is one `if`, not a helper, so it is hard to remove accidentally. |
| R-c | `sed -n '1s…p'` behaves differently from `head -1 \| sed` on some tag shape. | AC-6 byte-compares against the HEAD fragment on a real fixture; §3.2 enumerates the one divergence (non-`v` tag) and shows both land on the same handler. |
| R-d | The parity checker's parser drifts and silently stops testing keys. | §5.2 step 2: every `fmt=` line must yield a key, else exit 2 = FAIL. AC-7's two mutants prove both failure legs fire. |
| R-e | Wiring B.2 changes the `verify_all` summary and is read as a regression. | BC-16 + PM-1: exactly two expected deltas (B.2 SKIP→PASS, F.6 WARN from stage 1's 549-line doc). AC-3 pastes both summaries against a **clone**, never a worktree (`.harness/insight-index.md:26`). |
| R-f | The harness reaches a real system path or the live service. | §6.2's refuse-to-run denylist, `$TMP`-only writes, stubbed `curl` first on PATH, no `sudo` anywhere, AC-14's `systemctl show -p MainPID -p ActiveEnterTimestamp` witness before/after each stage (`is-active` is **not** valid). |
| R-g | `AC-12`'s permitted-diff list omits `.harness/rejected-decisions.md`, yet D-5 and PM-3 both require appending to it (and §3.5 adds a third record). | **Flagged for stage 3, not resolved here** — this stage cannot edit the requirement. Read AC-12 as widened by the same mechanism PM-1 used to widen AC-3, or have the gate rule. Not a blocker: the appends are required by binding decisions of the same document. |
| R-h | zh rendering of the reused keys is never exercised because CI is English-only. | AC-5 forces `LANG_CHOICE=zh` in the driver; B.2 now renders **all 41 keys** in both languages on every `verify_all` run. |

## 10. Open experiment for stage 4 (E-10) — required, non-blocking

The design is immune to BC-5 by construction, so nothing here can change the shape; the probe records
whether the removal of `head -1` was load-bearing or belt-and-braces. Run in `$TMP`, no root, no
network:

```bash
b() { bash -c "$1"; echo "  -> exit $?"; }
# input is ~5 MB, far over any pipe buffer, so an early-exiting reader really can SIGPIPE upstream
echo "E10a big input, pipeline ENDING IN head -1, pipefail"
b 'set -euo pipefail; V=$(yes "  \"tag_name\": \"v1.10.0\"," | head -200000 | grep tag_name | head -1 | sed -n "1s/.*\"v\([^\"]*\)\".*/\1/p"); echo "V=[$V]"'
#  predict: SIGPIPE upstream -> pipefail -> non-zero -> assignment ABORTS, no V= line, exit non-zero
echo "E10b same input, sed -n 1s..p instead of head -1"
b 'set -euo pipefail; V=$(yes "  \"tag_name\": \"v1.10.0\"," | head -200000 | grep tag_name | sed -n "1s/.*\"v\([^\"]*\)\".*/\1/p"); echo "V=[$V]"'
#  predict: V=[1.10.0], exit 0 — no element exits before EOF
```

**Stop rule:** if **E10b** does not print `V=[1.10.0]` with exit 0, §3.1's shape is wrong — stage 4
stops and reports before editing `install.sh`. If **E10a** matches E10b (both succeed), the `head -1`
removal was precautionary, not load-bearing: record that in `06_TEST_REPORT.md`; the shape still does
not change, because BC-5 forbids depending on the race falling the friendly way.

## 11. Rollout, compatibility, out-of-scope boundaries

- **Rollout**: one commit; `install.sh` is fetched fresh on every `curl | bash` run, so there is no
  version skew and no feature flag. **Rollback** = revert the commit; no state, no migration, no
  installed artifact changes (AC-10: the installed footprint gains no file).
- **Compatibility**: `if !`, `sed -n`, `printf`, `grep -qE` are all bash-3-era constructs — the
  bash 4.2 floor (BC-7) is untouched and no `${arr[@]}` expansion is added. No curl option is added,
  removed or altered, so the curl 7.29 floor (BC-8) is untouched. Init-system-agnostic (NFR-1):
  step 2 runs before any service work. Single self-contained file preserved (NFR-2).
- **Idempotency / data safety**: the failure path is print-and-exit; it creates nothing under
  `/etc/sing-box/` (first `mkdir` is `:397`) and re-running the installer stays the upgrade path
  (B-9, NFR-3). No credential, no sudoers change, no mode change (NFR-4, O-4).
- **CHANGELOG.md** (zh, per `docs/dev-map.md:17`) — one entry under a new version heading:
  `修复：install.sh 获取 sing-box 版本失败时（网络故障、GitHub API 403/404、返回内容中没有版本号）会在赋值处静默中止，不再提示任何信息；现在会用所选语言说明失败原因并以状态码 1 退出。`
  It must **not** claim the installer now always states its outcome (D-7).
- **`docs/dev-map.md`** — add exactly two things: a "Reusable utilities" row for
  `.harness/scripts/check-i18n-parity.sh` ("`t()` key + specifier parity for `install.sh`; extracts
  the function and renders every key under `set -u`; wired as `verify_all` B.2"), and a
  "Patterns to follow" bullet: "In `install.sh`, never write a bare `VAR=$(pipeline)` under
  `set -euo pipefail` when a handler below is supposed to see the failure — put it in an `if`
  condition, and keep every element of the pipeline reading to EOF."
- **`CONTEXT.md`**: **no edit** — `stated outcome` and `assignment abort` (stage 1, accepted as PM-2)
  already carry this design's vocabulary.
- **Out of scope, restated as design boundaries**: R-1 (`mktemp -d`), R-2 (empty `sing-box version`
  display), R-3 (bare `python3`/`tar`/`install`/`visudo`/`chmod`), R-5 (the `fail_download` helper),
  R-6 (`verify_all.ps1` mirror), `bin/sc` parity (O-9), retries/timeouts (O-3), GitHub auth (O-4).
  None is silently dropped: each is a row for `docs/tasks.md`.

## 12. Partition assignment

`partition: single-developer` — no `.harness/agents/dev-*.md` exists
(`.harness/rules/50-singbox-cli.md` § Partitioning; `PM_LOG.md`). All §2 files go to the one
Developer, in order: `install.sh` → `check-i18n-parity.sh` → `verify_all.sh` → docs. No parallelism.

## Verdict

The open fork is decided (explicit early exit, §3.5); the fix has an exact written shape justified
against five rejected alternatives (§3); all five B-2 modes are traced to one handler (§3.3); D-4 is
resolved as reuse (§3.4); B-8 ships non-fragile and wired (§5); the B-12 sweep is carried forward at
11 rows (§4); the AC-4/5/6/7 harness is specified down to its refuse-to-run interlock (§6). One
requirement-level inconsistency is flagged for the gate rather than resolved here (R-g), and one
experiment is commissioned for stage 4 with a stop rule (§10).

**READY FOR GATE REVIEW**
