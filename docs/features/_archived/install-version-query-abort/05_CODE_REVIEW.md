# Code Review — T-11 `install-version-query-abort`

- Stage 5, 2026-08-01 · Mode **full** · Decision mode **deferred-human** (`defer, do not ask`)
- Read: `01_REQUIREMENT_ANALYSIS.md` (§3 behaviors, §5 BCs, §6 ACs), `02_SOLUTION_DESIGN.md`,
  `03_GATE_REVIEW.md` (C-1…C-17), `04_DEVELOPMENT.md`, `PM_LOG.md`, `AI-GUIDE`-adjacent rules
  `85-design-discipline` / `50-singbox-cli` / `00-core`, `.harness/insight-index.md`, `docs/dev-map.md`.
- **Read-only stage.** No tool was run; every product claim below is a read of the working tree as it
  now stands. Where a claim can only be established by running something (git diff, `bash -n`, the
  throwaway harness), I say so explicitly rather than inheriting the developer's word for it.
- **Anchors are working-tree line numbers.** The `22502f9` vs `9184171` sha-label dispute is
  PM-owned; I spent no effort on it.
- **Persistence note (PM):** the code-reviewer agent has no write-capable tool. This document is the
  reviewer's output saved verbatim by the PM; no word was altered.

## Files reviewed

- `/home/alan/Programs/singbox-cli/install.sh` (`:1-140`, `:139-238`, `:240-298`, `:300-420`, `:520-534`)
- `/home/alan/Programs/singbox-cli/.harness/scripts/check-i18n-parity.sh` (all 123 lines)
- `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` (`:1-40`, `:48-78`, `:210-249`)
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`, `/home/alan/Programs/singbox-cli/docs/tasks.md`
- `/home/alan/Programs/singbox-cli/.harness/rules/50-singbox-cli.md` (`:25-54`)
- `/home/alan/Programs/singbox-cli/CHANGELOG.md` (`:1-24`), `/home/alan/Programs/singbox-cli/CONTEXT.md` (glossary)
- `/home/alan/Programs/singbox-cli/.harness/insight-index.md`, `.harness/scripts/archive-task.sh` (harvest path)

**Not reviewable at this stage:** the AC-4/5/6/7 fragment harness is deliberately not committed
(design §6 — it is pasted into `06_TEST_REPORT.md`). See MINOR [VERIF-1].

---

## 1. The single highest-risk line — C-1, verified character by character

`install.sh:386` reads, in full:

```
        | sed -n '1s/.*"v\([^"]*\)".*/\1/p'); then
```

Token by token against C-1's required literal `sed -n '1s/.*"v\([^"]*\)".*/\1/p'`:
`sed` · `-n` · `'` · **`1`** · `s` · `/.*"v/` · `\(` · `[^"]*` · `\)` · `"` · `.*` · `/` · `\1` · `/` ·
**`p`** · `'`. **Both the `1` address and the `p` flag are present and the expression is
byte-identical to the required literal.** No `\1` mangling, no stray whitespace inside the quotes.

Early-exiting readers in the changed block (`:383-395`): line 385 is `| grep '"tag_name"' \` — plain
`grep`, no `-m1`. There is **no executable `head`, `grep -m1` or `sed …q`** anywhere in `:383-395`.
The tokens `head`, `grep -m1`, `sed q` appear only in the four comment lines `:378`, `:380`, `:381`,
`:382`, which name them as forbidden. The two surviving `head -1` uses in the file are `:368` and
`:406` (the R-2 sibling display sites), correctly untouched.

**C-1 discharged.**

## 2. B-5 — the success path is byte-equivalent, re-derived independently

I did not accept §3.2's prose. Working it out on grep's output:

- **Single `tag_name` line.** HEAD: `head -1` selects it; `sed 's/.*"v\([^"]*\)".*/\1/'` substitutes.
  New: `1s` addresses sed's input line 1 — which *is* grep's first output line — and `p` under `-n`
  prints only on a successful substitution. Same line, same regex, same output.
- **Multiple `tag_name` lines** (the case the PM asked about): HEAD's `head -1` discards lines 2..n
  before sed sees them; the new form lets sed read lines 2..n but neither addresses nor prints them
  (`-n` + `1` address). Output identical. The developer's decoy fixture (`v1.10.0` first,
  `v9.9.9-decoy` later) exercises exactly this and reports `SB_VER=[1.10.0]`, matching my derivation.
- **The one divergence** — a first line that does not match `"v…"`: HEAD echoes the line whole
  (leading whitespace intact, so `^[0-9]+\.[0-9]+` can never match — gate F-4); the new form emits
  nothing. Both land on the same judge at `:391` and the same `exit 1`. Observationally identical.
  I also checked the no-leading-whitespace variant (`"tag_name":"1.10.0"`): HEAD's passthrough starts
  with `"`, still fails the semver test. No behavioural divergence exists.

**B-5 / AC-6 hold on the code as written.**

## 3. All five B-2 modes reach the handler — traced in the code, not the prose

```
:383  SB_VER=""                          unconditional; BC-6 satisfied before any read
:384  if ! SB_VER=$(curl … | grep … | sed …); then      set -e exempt context (E4/E9)
:387      SB_VER=""
:388  fi
:391  if [ -z "$SB_VER" ] || ! echo "$SB_VER" | grep -qE '^[0-9]+\.[0-9]+'; then
:392      t download_failed "GitHub API (sing-box version)"
:393      t check_network
:394      exit 1
```

| B-2 mode | Pipeline status | Value at `:391` | Reaches handler |
|---|---|---|---|
| 1 transport (6/7/35) | non-zero (curl) | `""` via `:387` | yes |
| 2 non-2xx (22, via `-f`) | non-zero (curl) | `""` via `:387` | yes |
| 3 2xx, no tag | non-zero (grep 1) | `""` via `:387` | yes |
| 4 `"tag_name": "v"` | **zero** | `""` (sed prints an empty line; `$()` strips it) | yes via `-z` |
| 5 `"tag_name": "vnightly"` | zero | `nightly` | yes via the `grep -qE` leg |

The only assignments to `SB_VER` are `:383`, the `if`-guarded one at `:384`, and `:387`. **No path can
abort at the assignment**, and `SB_VER` is defined on every path before `:391` reads it, so `set -u`
(BC-6) is satisfied on both legs. `!` correctly suppresses the `then` branch when the pipeline
succeeds, so a good fetch is not wiped.

B-9: `exit 1` at `:394` precedes the first `mkdir -p /etc/sing-box …`, now at `:411`. B-10:
`CLEANUP_DIRS`/`trap cleanup EXIT` at `:320-325` with `SB_TMPDIR` pushed at `:372`, i.e. *before* the
block — the trap fires on `exit 1`. Both hold structurally.

## 4. AC-11 / C-14 and AC-9 — the untouched machinery

The edit is entirely at `:373+`, so `:1-372` cannot have shifted; I verified the *content* at each
pinned range against what the gate verified at HEAD (§1 of `03_GATE_REVIEW.md`):

- `:24-29` — the comment plus `PHASE_RULESETS="failed"` / `PHASE_CONFIG="failed"` /
  `PHASE_SERVICE="not-started"`. Matches the gate's `V` exactly.
- `:243-288` — `install_report()`; `fail_config` at `:263-267`, `fail_rulesets` `:268-270`,
  `fail_rules`/`fail_reload` `:273-274`, `fail_status` `:276`, `fail_log`/`fail_nolog` `:282-286`,
  `return 1` `:287`. Every line the gate verified is present at the same offset.
- `install_report || exit 1` at `:532`, followed by `exit 0` at `:533`. HEAD `:518` + the block's
  growth of 14 = 532. Arithmetic self-consistent, **no exception taken**.
- **AC-9** — `:116-132` is the T-08 flag-policy block verbatim, `CURL_OPTS_QUIET=(-f -s -S -L)` at
  `:128`, `CURL_OPTS_PROGRESS` at `:129-132`. All three curl call sites (`:345`, `:384`, `:398`)
  expand an array and add **no literal option**. No `--max-time`, `--retry`, `--connect-timeout`
  anywhere in the file.

Caveat of method: I cannot run `git diff`, so "byte-identical to HEAD" is established here as
"content matches what stage 3 independently verified at HEAD, at unchanged line numbers". That is the
strongest read-only form of the check; QA should still run the three explicit range diffs C-14 asks
for.

## 5. Adjudication — the `sing-box` denylist drift (the PM's question 5)

**Ruling: the deviation was the right call. C-7 as literally written is unsatisfiable, and the
developer's substitute preserves the gate's stated intent.**

The evidence is in the file, not just in the developer's report. The block the harness must run
contains the literal `sing-box` three times: `:392` `t download_failed "GitHub API (sing-box
version)"`, `:396`'s `SB_URL=…/sing-box-${SB_VER}-linux-…`, and `:397` `t fetching_item "sing-box
v$SB_VER ($ARCH)"`. A substring denylist on `sing-box` therefore refuses the exact fragment it exists
to protect, and AC-4/AC-5/AC-6 become undischargeable. That is a genuine self-contradiction in C-7,
not a developer convenience.

Does the replacement `(^|[;&|]|\$\()[[:space:]]*sing-box([[:space:]]|$)` preserve L13's intent — *a
test executing the installed binary*? Against the actual over-run risk, yes:

- The nearest executions of the binary are `:368` and `:406`, both `"$(sing-box version | head -1)"`.
  The `\$\(` alternative matches both. I checked this against the literal text.
- Every plausible over-run past the end anchor first hits a **substring**-denied token anyway: `:398`
  `curl … -o`, `:403` `mkdir -p`, `:404` `tar -xz`, `:405` `install -m 755`. The command-position rule
  is not the only thing standing between the harness and the system.
- The poison-pill layer (refusing `sing-box`, `sudo`, `systemctl`, `tar`, `install`, `chmod`, `mkdir`
  and the six package managers first on `PATH`, exit 99, `POISON` lines in `stub.log` = 0) is a
  second interlock that **does not depend on the regex at all**. That is the control that makes this
  deviation safe rather than merely argued.

Residual holes I found in the regex, recorded so they are not assumed away: it does not match a
backticked invocation, nor `if sing-box …` / `then sing-box …` / `exec sing-box …` (a keyword before
the command breaks the `^[[:space:]]*` anchor). Neither is reachable given the `sed`-range extraction
and the ≤20-line cap, and both are caught by the poison pill. **No hole is opened.** Recorded as
NIT [SAFE-1] rather than a finding.

Ownership note for the PM: C-7's `sing-box` clause was **not satisfiable as written**. That is a gate
defect, discharged by the developer correctly and transparently; it should be recorded against
stage 3 so the same literal is not reissued on a future task.

## 6. The parity checker (the PM's question 6)

I read all 123 lines. It implements design §5.2 as specified and has **not** degenerated into the
`case`-block diff PM-3's overturn condition forbids:

- `:48` extraction is a `sed` range `'/^t() {/,/^}/p'` — first column-0 `}` after the anchor, so it
  cannot over-run the function. `:51-52` assert both anchors independently.
- `:57-59` refuses to source a fragment containing `$(` or a backtick. This is a **strengthening
  beyond the design** and it is the right one: it makes "sourcing defines a function and executes
  nothing" a checked property rather than an assumed one.
- `:62-68` is the union/no-attribution step plus the anti-drift assertion (`n_fmt` must equal
  `n_case`, else exit 2). `:70` enumerates as a **union** (`sort -u`), never attributed to a block.
  Verified against `install.sh:139-238`: `:142` is `local fmt` (no `=`) and `:234` is
  `printf "$fmt\n"`, so the 82 case lines are the only `fmt=` lines — the assertion is sound.
- `:75-96` is the **behavioural** judgment: one `bash -u` child per language sources the fragment,
  sets `LANG_CHOICE`, and renders every key inside `out=$( t "$k" 2>&1 )`. A key absent from that
  table leaves `local fmt` unset, `printf` dereferences it under `set -u`, and the *subshell* dies —
  the production failure mode itself, with the outer loop surviving because neither script uses
  `set -e`. `:92-95` then asserts the record count, so a language that silently produced fewer
  records is exit 2, not a pass.
- Exit 1 vs exit 2 are strictly distinguished: `die2()` at `:34` is the only exit-2 route and prints
  `CANNOT DECIDE:`; exit 1 at `:119` is only reachable with `bad > 0`. `verify_all.sh:72-73` treats
  **any** non-zero rc as FAIL, so exit 2 can never read green.
- No weakening under C-13: the key list is not narrowed, neither language is skipped, exit 2 is not
  tolerated, and the check is reported green against the *unmodified* `install.sh`.

Specifier counting (`:84-85`) is correct and subtler than it looks: the render calls `t "$k"` with no
arguments, so `install.sh:232`'s `[ "$#" -gt 0 ]` test takes the `printf "%s\n" "$fmt"` branch and the
raw `%s` survives into `out`. `${out//%%/}` then `${spec//[!%]/}` counts real conversions only.

I independently confirmed the product property AC-8 asserts, by reading the tables rather than
trusting the checker: zh `:145-185` and en `:189-229` are **41 keys each, identical names in
identical order**, and the specifier counts agree on every key carrying one (`download_failed` 1/1,
`check_network` 0/0, `step2_already` 1/1, `step6_warn` 1/1, `step6_nolog` 1/1, `fail_status` 1/1,
`fail_nolog` 1/1, `fail_log` 1/1, `target_user`/`install_source`/`language_chosen` 1/1).

The wiring at `verify_all.sh:70-76` is design §5.3 verbatim, inside the `HARNESS:B-CUSTOM` markers
(`:48`/`:78`), and `verify_all.sh:6` is `set -uo pipefail` — **no `-e`** — so the bare
`b2_out=$(…); b2_rc=$?` at `:71` cannot abort the harness by this task's own mechanism. Worth stating
explicitly, since that is exactly the trap under review.

## 7. Vacuous greens (the PM's question 7)

The gate's five (C-2/C-3/C-4/C-5/C-12) are addressed as reported, subject to [VERIF-1] below. Two the
gate did **not** anticipate, found by reading the committed checker:

1. **The checker cannot detect a broken language dispatch.** If `install.sh:143`'s
   `if [ "$LANG_CHOICE" = "zh" ]` were ever changed (say to `= "cn"`), both render children would
   fall to the `else` branch, produce the **en** table twice, agree on every status, length and
   specifier count, and the check would print `OK: 41 keys, both languages` — a literally false
   statement — and exit 0. B.2 would be green while the zh path was entirely unreachable. A one-line
   guard closes it: assert that at least one key's en and zh renderings differ. See MINOR [VAC-1].
2. **The specifier check is coupled to `install.sh:232`.** If that `[ "$#" -gt 0 ]` branch were
   removed so `t` always ran `printf "$fmt\n" "$@"`, a zero-arg render would consume `%s` into the
   empty string and *both* languages would count 0 specifiers — mismatches would become
   undetectable, silently. Same finding, second leg.

One near-miss worth crediting rather than flagging: the third obvious degradation — someone adding
the declined `t-fmt-default-fallback` (`local fmt=""`) — **is** caught, because that line contains
the substring `fmt=` but does not match the key regex, so `n_fmt != n_case` fires exit 2 at `:66-68`.
That is a real, if incidental, robustness property. The exotic `${fmt:=…}` form would evade it; NIT
only.

## 8. Scope, conditions and documents

**C-10 / AC-12 — the nine expected A-4 items.** Each named file carries exactly the described change,
and nothing outside the list shows a T-11 edit:

| A-4 item | State in the tree |
|---|---|
| 1 `install.sh` | step-2 block `:373-395` only |
| 2 `CHANGELOG.md` | one zh `修复` bullet at `:20`, under the existing `[Unreleased]` |
| 3 `check-i18n-parity.sh` | new, 123 lines |
| 4 `verify_all.sh` | `:70-76` only, inside the markers; `:77` B.3 still `SKIP` |
| 5 `docs/tasks.md` | R-1…R-6 at `:53-82` |
| 6 `docs/dev-map.md` | `:22-24` B.2 sentence, `:56` utility row, `:73-77` pattern bullet |
| 7 `CONTEXT.md` | stage 1's `stated outcome` / `assignment abort`, unaltered shape |
| 8 task docs | `04_DEVELOPMENT.md` = 497 lines, under the 500 cap |
| 10 `.harness/rules/50-singbox-cli.md` | `:34-40` rewritten minimally |

Items 9 (`rejected-decisions.md`) and 11 (`insight-index.md` / `_archived/`) are correctly **absent**
— C-16 assigns them to delivery and A-4 item 11 forbids hand-editing the index. `verify_all.ps1`,
`baseline.json`, `bin/sc`, `systemd/`, `uninstall.sh`, `README*.md` show no T-11 content.

**C-11.** `docs/dev-map.md:22-24` now reads "B.2 runs the `install.sh` bilingual key-parity check
(T-11); B.3 (lint) is still `SKIP`". Rule 50 `:36-40` now says B.2 is a real gate since T-11 and
B.3 is still SKIP, with `:42-43`'s "do not repeat the all-SKIP claim" warning intact. **B.3 remains
SKIP in the script itself** (`verify_all.sh:77`).

**C-17.** The CHANGELOG bullet at `:20` ends: 「…`install.sh` 里 `tar` / `install` / `python3` 等命令失败
时仍会中止而不作说明，「安装器在任何情况下都会说明结果」目前还不成立。」 — an explicit denial of the global
guarantee, exactly D-7. Its factual claims check out against the code: temp-dir cleanup (trap at
`:325`), nothing under `/etc/sing-box/` (first `mkdir` at `:411`), exit status 1 (`:394`), curl
parameters unchanged. R-1…R-6 are filed, R-6 naming `verify_all.ps1:79`.

**C-9 / AC-13.** I counted the command substitutions myself: code sites are `:39 :51 :61 :62 :307
:318 :332 :368 :371 :384 :406` = **11 sites**, with `:318` nesting `$(dirname …)` for **12 raw
occurrences**. That is exactly the developer's ruling and exactly design §4's eleven rows, with the
defect site at `373→384` and the two sites below shifted by +14.

**D-C confirmed independently.** The shift below the block is **+14**, not design §4's "+11":
`:392→:406`, `:397→:411`, `:518→:532` all move by 14. Owner solution-architect; already reported;
cosmetic.

**E-10 / D-A.** The developer's diagnosis is right on mechanism: `yes … | head -200000` is itself an
early-exiting reader inside the measured pipeline, so under `pipefail` it returns 141 whatever the
tail does, and the design's probe could never distinguish its two legs. The corrected legs (input
materialised out of band) do support "the removal is load-bearing" — **for a 5 MB body**. See MINOR
[EVID-1] on how far that conclusion generalises.

**Safety.** I found **no evidence that any stage executed `install.sh`**. The one committed
executable never sources or executes it (`check-i18n-parity.sh:48` extracts by `sed` to a temp file;
only `$FRAG` is sourced, and only after the `$(`/backtick refusal at `:57-59` and the two anchor
assertions). `verify_all.sh` touches `install.sh` only via `bash -n` (`:65`) and the parity check.
The installed footprint is unchanged: the new script lives under `.harness/`, which is not shipped
(`docs/dev-map.md:19`).

---

## Findings

### CRITICAL
None.

### MAJOR
None.

### MINOR

- **[VAC-1] `check-i18n-parity.sh:100-115` — the checker cannot detect a broken language dispatch,
  and would print `OK: 41 keys, both languages` while zh is unreachable.** Two legs, detailed in §7:
  (a) if `install.sh:143`'s `LANG_CHOICE` test stops selecting the zh table, both renders return the
  en table and every comparison agrees; (b) if `install.sh:232`'s zero-arg `printf "%s\n"` branch is
  removed, specifier mismatches become invisible. Both are silent degradations of a *permanent* gate,
  which is the worst kind. The implementation is faithful to design §5.2 step 4, so this is a design
  blind spot, not an implementation defect. Cheapest fix: assert at least one key renders differently
  between the two languages. **Owner: solution-architect** — non-blocking; suitable as an R-row for
  the next task touching `.harness/scripts/`.
- **[VERIF-1] The C-2/C-3/C-4/C-6/C-7 guards are not independently auditable at this stage.** The
  harness is deliberately uncommitted (design §6), and `04_DEVELOPMENT.md` pastes transcripts and
  assertion counts but not the harness source. Everything I could verify from the tree checks out and
  the reported guards are the right shape, but "the guard is real as implemented" is, for those five
  conditions, a claim I can corroborate only through excerpts. This is a consequence of the design's
  own choice, not a developer defect. **Recommendation:** QA (stage 6) should **rebuild** the harness
  from the ACs rather than inherit the developer's, as T-10's QA did — that turns [VERIF-1] into an
  independent second witness instead of a re-run. **Owner: PM routing** (no code change).
- **[EVID-1] `04_DEVELOPMENT.md` — "the `head -1` removal is load-bearing, not precautionary"
  overstates what E10d/E10e establish, and contradicts the gate's own A-2 finding without saying so.**
  The corrected legs used a 5 MB / 200 000-line fixture; the production endpoint is ~1.6 KB and grep
  emits one short line, where the race is unreachable. The gate ruled precisely this: "load-bearing
  only for large/hostile bodies… belt-and-braces for the success path". The accurate statement is
  *load-bearing for large or hostile bodies, precautionary for the real endpoint* — which is still a
  complete justification for the change, because BC-5 forbids depending on the race falling the
  friendly way either way. Worth correcting before it is quoted into `06`/`07`.
  **Owner: developer** (documentation only; no code change).
- **[DOC-1] `.harness/rules/50-singbox-cli.md:45` still opens "Minimum manual verification for any
  change, until B.2/B.3 are real"**, which now reads as false for B.2. The developer surfaced this and
  correctly left it alone: C-11 says "no other line of rule 50 is touched". Flagged so the PM routes
  it to the next rule-50 edit rather than losing it. **Owner: follow-up row** — no action this task.
- **[DOC-2] The insight bullet at `04_DEVELOPMENT.md:492` lacks the `- YYYY-MM-DD · ` prefix** that
  `.harness/insight-index.md:7-9` defines as the record format. It is correctly **one physical line**
  with a trailing `· evidence:` tag (insight L21 respected), and `archive-task.sh` harvests from
  `07_DELIVERY.md`, not from this file — so this is a handoff note: stage 7 must restate it with the
  date prefix. Also note the index is at **29/30 lines**; this insight takes it to exactly the cap,
  so the next task will need a rotation. **Owner: delivery (stage 7).**

### NIT

- **[SAFE-1]** The command-position rule does not match a backticked invocation, nor `if sing-box …`
  / `then sing-box …` / `exec sing-box …`. Unreachable given the `sed`-range extraction and the
  ≤20-line cap, and covered by the poison-pill layer regardless. Recorded, not actionable.
- **[LOGIC-1] `install.sh:391` — `echo "$SB_VER" | grep -qE …` is itself an early-exiting reader
  under `pipefail`, two lines below a comment forbidding exactly that.** It is safe and must **not**
  be changed: the payload is a single short line well under `PIPE_BUF`, `echo` is a builtin, the line
  sits in an `if` condition (so `set -e` cannot fire), and even in the pathological case the failure
  direction is *fail-closed* (a hostile megabyte-long value would be rejected, not accepted). It is
  byte-identical to HEAD, and touching it would breach B-5's line-by-line audit for zero gain. Noted
  only so a future reader does not mistake it for an oversight.
- **[LOGIC-2]** The greedy `.*"v` picks the **last** `"v` on its input line, so a minified
  single-line JSON body could extract the wrong field. Identical at HEAD (same regex), so B-5 holds
  and nothing is introduced here; GitHub returns pretty-printed JSON. Belongs with R-3 if ever.
- **[MAINT-1]** The new comment at `:373` contains the literal `VAR=$(pipeline)`, so a naive
  file-wide `$(` count now returns one more *line* than at HEAD. C-9's "code lines only" ruling
  already covers it, but a future AC-13-style sweep should restate the ruling rather than re-derive
  a raw count.

---

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| B-1 stated outcome + exit 1 | `install.sh:392-394` | PASS |
| B-2 five modes | traced §3 above | PASS |
| B-3 no abort at the assignment | `:383-388` (`if` guard + pre-assignment) | PASS |
| B-4 statement true of what happened | reuses `download_failed`/`check_network`, arg names the GitHub API version query; asserts nothing about config/service/rulesets; names no uninstalled command | PASS |
| B-5 success path unchanged | re-derived §2; AC-6 decoy fixture | PASS |
| B-6 no SIGPIPE dependence | `sed -n '1s…p'` reads to EOF | PASS |
| B-7 both tables, same specifiers | `:150/:194`, `:151/:195`; no new key | PASS |
| B-8 committed, non-SKIP check | `check-i18n-parity.sh` + `verify_all.sh:70-76` | PASS |
| B-9 nothing under `/etc/sing-box/` | `exit 1` `:394` precedes `mkdir` `:411` | PASS |
| B-10 temp dirs removed, exit 1 | trap `:325`, `SB_TMPDIR` pushed `:372` | PASS |
| B-11 no new external command | curl/grep/sed only; `head` still at `:368`/`:406` | PASS |
| B-12 sweep carried forward | design §4, 11 rows; R-1…R-6 in `docs/tasks.md:53-82` | PASS |
| AC-1 E-0 7/7 | PM pre-flight, design §0 | PASS (documented; outside my reach) |
| AC-2 `bash -n` | reported 0; also `verify_all` B.1 PASS | PASS (not runnable here) |
| AC-3 0 FAIL + clone delta | PASS 16/WARN 1/FAIL 0/SKIP 1 vs clone 16/0/0/2 — arithmetic internally consistent (18 steps, F.6 PASS in a clone lacking the untracked docs folder) | PASS |
| AC-4 five modes, en | 36 assertions reported | PASS (see [VERIF-1]) |
| AC-5 both languages | 54 assertions, C-4 literals + en≠zh | PASS (see [VERIF-1]) |
| AC-6 success byte-identical | decoy fixture, dropped-`1` mutant detected | PASS (see [VERIF-1]) |
| AC-7 mutants, exit exactly 1 | 3 mutants + exit-2 control | PASS (see [VERIF-1]) |
| AC-8 parity holds | **independently confirmed by reading `:145-185` vs `:189-229`** | PASS |
| AC-9 no curl option changed | `:116-132` + all three call sites verified | PASS |
| AC-10 no new command / footprint | verified; `.harness/` is not shipped | PASS |
| AC-11 T-01 machinery intact | `:24-29`, `:243-288`, `:532` verified | PASS |
| AC-12 shipping diff | nine of eleven A-4 items, two delivery-owned | PASS |
| AC-13 sweep row count | 11 sites, counted independently | PASS |
| AC-14 live service untouched | two identical witnesses; QA owns the third | PASS (stage-6 obligation) |
| AC-15 no writes to `/etc` etc. | attested; no contrary evidence in the tree | PASS |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| §3.1 verbatim post-change block | `install.sh:373-395` matches character for character, comments included | PASS |
| §3.5 explicit early exit, not `install_report()` | `:392-394`; report machinery untouched | PASS |
| §3.4 no new `t()` key | 41 keys unchanged in both tables | PASS |
| §5.1 interface + exit 0/1/2 | `check-i18n-parity.sh:15-21`, `:34`, `:119`, `:123` | PASS |
| §5.2 union enumeration, behavioural render | `:62-96`; attribution never used | PASS |
| §5.3 `verify_all` B.2 wiring | `verify_all.sh:70-76`, verbatim, inside the markers | PASS |
| §6.2 refuse-to-run denylist | `sing-box` enforced in **command position**, not as a substring | **drift — adjudicated ACCEPTED** (§5) |
| §6.2 "exactly two `fi`" | parameterised (2 changed / 1 HEAD) so the HEAD fragment is runnable | drift — necessary and correct |
| §6.3 five stub modes | six modes run (mode 3 twice, per §6.3's own table) | PASS — more coverage |
| §10 E-10 probe | fixture defective as designed; corrected out of band, reported as D-A | **design defect, owner solution-architect** |
| §4 "+11 line shift" | actual shift is **+14** | **design defect (D-C), cosmetic** |
| §11 CHANGELOG under a new version heading | appended under existing `[Unreleased] → 修复` | drift — matches house style (T-01/02/09/10); a version heading is an owner/release call. Accepted |

No drift changes the shape of the fix, and every drift is declared in `04_DEVELOPMENT.md` rather than
discovered here — which is the behaviour the process is trying to produce.

## Axis status

- **Standards-conformance: 2 findings, worst = MINOR** ([DOC-1], [DOC-2]; plus NITs [MAINT-1],
  [SAFE-1]). Rule 85's counter-rule holds — no helper, no new product file, no speculative
  generality; the one new file is B-8, re-homed filed scope adjudicated by gate A-3. Doc caps
  respected (`04` = 497L; the single F.6 WARN is stage 1's 549-line requirement doc, known and
  self-clearing). Cross-shell parity: `verify_all.ps1` genuinely diverges, but the gate placed it
  outside the permitted diff and required it filed — it is, as R-6. No invented rules were applied in
  this review.
- **Spec/design-fidelity: 3 findings, worst = MINOR** ([VAC-1], [VERIF-1], [EVID-1]; plus NITs
  [LOGIC-1], [LOGIC-2]). All 12 behaviors and all 15 acceptance criteria are covered; the three
  design-side defects ([EVID-1]'s §10 fixture, D-C's +14, and [VAC-1]'s comparison blind spot) are
  documentation- or robustness-level and none reaches the product code.
- Aggregate = the more severe of the two = **MINOR**. Neither axis carries an unaddressed CRITICAL or
  MAJOR.

## Verdict

The highest-risk line is exactly right, character for character. The success path is byte-equivalent
and I re-derived it rather than accepting it. All five failure modes provably reach one handler, with
`set -u` closed by the pre-assignment. T-01's machinery and the curl flag policy are untouched. The
one safety-layer deviation was forced by a gate condition that was unsatisfiable as written, and the
developer replaced it with a narrower rule plus a regex-independent second interlock instead of
quietly dropping it. The parity checker is the behavioural instrument the design specified, not the
fragile parser PM-3 forbade, and it distinguishes "broken" from "cannot decide". Every deviation is
declared. The two vacuous greens I found that the gate did not are limitations of the *design's*
comparison step, not false discharges of any criterion.

**APPROVED** — with five non-blocking observations. For PM routing:
[EVID-1] → **developer** (one sentence in `04_DEVELOPMENT.md`, before it propagates to `06`/`07`);
[VAC-1] and the confirmed D-C/D-A → **solution-architect**, as follow-up rows rather than a rollback;
[VERIF-1] → stage 6 should **rebuild** the harness, not inherit it;
[DOC-1] → next rule-50 edit; [DOC-2] → stage 7 restates the insight with its date prefix.
