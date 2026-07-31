# 06 — Test Report — install-enable-start-split (T-01)

- **Task ID**: T-01 · **Mode**: full · **Date**: 2026-07-31 — **rev. 3 (written for `02` rev. 3 / `03` rev. 3; no rev-1 content carried forward)**
- **Upstream**: `01` rev. 2 (`READY`), `02` rev. 3 (`READY`), `03` rev. 3 (`APPROVED WITH CONDITIONS`; **C-1, C-5, C-6, C-7, C-8, C-9** in force, **C-2/C-3/C-4 retired**), `04` rev. 3, `05` rev. 3 (`APPROVED`)
- **Code under test**: `/home/alan/Programs/singbox-cli/install.sh` (497 lines, uncommitted working tree) + `CHANGELOG.md:8`
- **Dispatch context**: deferred-human mode (defer, do not ask); no commits, no pushes, no production-code edits
- **Verdict**: **APPROVED FOR DELIVERY** — 0 defects in `install.sh`; 1 MAJOR process defect outside the code (§8 D-1)

---

## 0. What actually ran, and what was only reasoned about

Everything in §1–§6 was **executed** in this session and its output is pasted or counted below.
The following are **reasoned statically only** and are stated as such, never as executed:

| Claim | Why it was not executed |
|---|---|
| **AC-9** (restricted-network systemd host: units `enabled`, failure banner, non-zero exit) | **UNVERIFIED / deferred to T-07.** No systemd-capable, network-restricted VM and no root in this environment (`02` §10.1, gate **C-7**). Claiming it as executed would be a defect. |
| **BC-21** — the bash-4.2 `"${empty[@]}"` unbound-variable fault | Only bash 5.2.21 is installed (`bash --version`); bash ≥ 4.4 stopped treating `"${empty[@]}"`/`"${unset[@]}"` as an error, so the *fault itself* is not reproducible here. What **was** executed: the shipped guarded `cleanup()` preserves exit 0, 1 and 3 through the EXIT trap with empty and unset `CLEANUP_DIRS`, and behaves identically to the pre-fix form on this bash (`qa_adversarial.sh` Q19). The 4.2-specific benefit is reasoned from the guard's form. |
| **R1** — `PHASE_SERVICE=started` vs. process liveness (`Type=simple`) | No real init system (coverage limit 3). Accepted design position (gate H-3), not a QA finding. |
| **M-1's real-host stderr delta** (`Created symlink …` no longer reaching the terminal) | The stub is silent on success, so the harness *structurally cannot* observe it. See §7. |
| Real `systemctl`/`rc-service` semantics (symlinks, masked units, container buses) | Coverage limit 3. |

---

## 1. Test plan — every acceptance criterion to a test

Two suites, both uncommitted (`test/` is gitignored via `.gitignore:19`, and it stays that way — AC-10):

- **`test/step7/run.sh`** — the developer-built harness. QA re-ran it, **read it, and hardened it** (§5.1). 334 assertions.
- **`test/step7/qa_adversarial.sh`** — **QA-owned, written independently from `01` §5/§6**, not from `04`'s test code. Rewritten in place for rev. 3 (its rev-1 self probed `INSTALL_OK`, which no longer exists). 341 assertions.
- **`test/step7/qa_mutate.sh`** — QA-owned mutation harness, rewritten for rev. 3. 17 mutants, both suites run against each.

| # | Criterion | Test case(s) | File |
|---|---|---|---|
| AC-1 | `bash -n install.sh` | direct command → clean; also verify_all `[B.1] PASS` | §4 |
| AC-2 | verify_all ends `FAIL: 0` | direct command | §4 |
| AC-3 | failing `sc reload` → both `enable`, no `start` | `Q2` (exact call-log equality), `S2` | both |
| AC-4 | the script still reaches its final line | `Q2` (last stdout line **is** the log pointer), `S2` | both |
| AC-5 | success call order + stdout unchanged vs `HEAD` | `Q1` order, `Q21` byte-identity vs `HEAD:install.sh`; `S1`+`BASE` | both — **scoped, §7** |
| AC-6 | phase state readable under `set -u`, expected values | `PHASES` probe with **no `:-` defaults**, asserted in Q1–Q13 (16 scenarios) | both |
| AC-7 | OpenRC: `rc-update` both paths, `rc-service start` only on ok, no rules-update token | `Q8` (strict `PATH=$STUB`, `systemctl` deleted), `Q9`; `S6/S6b/S7` | both |
| AC-8 | re-run → same end state, log keeps run 1 | `Q15` (sentinel line + 2 markers + identical stdout/rc/calls), `S13` | both |
| **AC-9** | **restricted-network host** | **NOT EXECUTED — deferred to T-07** (§0, §6) | — |
| AC-10 | diff confined to `install.sh` + one CHANGELOG bullet | `git diff --stat`, per-path `git diff --quiet` (§4.3) | direct |
| AC-11/12 | superseded | — | — |
| AC-13 | failure text: explanation + 3 remediation commands + literal log path; **no** success banner | `Q2`, `Q11` + explicit substring audit of `安装完成` / `Install complete` / `/dev/null` (§4.4) | both |
| AC-14 | failure exits non-zero, success exits 0 | `Q1/Q6/Q7/Q8/Q10/Q13` → 0; `Q2/Q3/Q4/Q5/Q9/Q11/Q14` → 1 | both |
| AC-15 | `update-rules` **stdout** cause in the log, not on the terminal | `Q10` (`QACAUSE` in log, absent from stdout; `QAAGG` too), `S9` | both |
| AC-16 | every scenario in **both** languages, no `unbound variable`, non-empty rendering | every scenario runs `en`+`zh`; `Q17`; **`Q18` executes the real prompt** | both |
| AC-17 | zh/en key sets identical | `Q17` (independent Python extractor) + `S14` (awk extractor) — two different parsers agree: **40/40** | both |
| AC-18 | step-6 warning names the log, no speculative cause | `Q10` (`step6_warn` rendered through the real `t()`; `network issue`/`网络问题` absent) | both |
| AC-19 | unwritable log → same banner, same status | `Q12`: 4 phase outcomes × 2 languages, each diffed against its writable twin | both |
| AC-20 | log mode excludes `other` | `Q1`: `stat -c %a` = **640**, owner = creating user | both |

**Six provable items from the dispatch** — (a) registration happens although `sc reload` fails: `Q2`/`Q11`;
(b) a failing `sc reload` does not abort: `Q2` (final line reached); (c) failure banner **and not** the
success banner: `Q2`/`Q5`/`Q11` (+ §4.4 substring audit); (d) failure path exits non-zero: `Q2`…`Q14`;
(e) the success path is unchanged: `Q1` + `Q21`; (f) both languages render for every new string: every
scenario ×2 languages, `Q17` (40 keys × 2 rendered non-empty; the 12 new/changed keys asserted to *differ*
between zh and en, so a copy-paste of English into the zh branch fails), `Q18` (the real prompt).

---

## 2. Boundary tests added (new in this stage, absent from `run.sh`)

- **Log path is an existing directory** (`Q13`) — probe refuses it, phases and exit status unchanged.
- **Log path containing spaces + unicode** (`Q14`, `…/wei rd 目录/install log.log`) — no word-splitting; the cause still reaches the file; the odd path is printed verbatim.
- **Pre-existing log content** (`Q15`) — a sentinel line written before the run survives two further runs; `QARELOAD` appears exactly twice; markers = 2.
- **10 concurrent installers appending to one log** (`Q16`) — 10 intact run markers, 10 intact (non-interleaved) cause lines, all 10 runs exit 0.
- **`systemctl` absent while `INIT_SYS=systemd`** (`Q4`) — honest `fail_service`, exit 1, nothing leaks to the terminal.
- **Auxiliary-vs-decisive separation** (`Q6`, `Q7`, `Q7b`) — per-unit stub exit codes: only the **timer** start fails → still success; only the timer **enable** fails, then both enables fail → still success and the second `enable` is still attempted.
- **EXIT-trap status contract** (`Q19`) — exit 0/1/3 preserved with empty and unset `CLEANUP_DIRS`.
- **The real language prompt** (`Q18`) — inputs `1`, `2`, `zh`, empty (`LANG=C` and `LANG=zh_CN.UTF-8`), garbage, EOF, and **closed stdin**: `LANG_CHOICE` correct in all 8, and the new keys render in the resulting language.
- **t() call-site audit** (`Q17`) — every `t <key>` call site in the *whole* file exists in the table, and passes exactly as many arguments as its format has `%s` (`BAD none`). A typo in an unexercised call site would abort the installer under `set -u`; nothing in `run.sh` covered this.

---

## Adversarial tests — §3, REQUIRED, one stated hypothesis per criterion

Every reproducer below is **mine**, in `test/step7/qa_adversarial.sh`, written from `01` rather than from
`04`'s test code. Each scenario prints its hypothesis before running.

| AC / item | Hypothesis: "I expect failure when…" | Reproducer (NEW) | Outcome |
|---|---|---|---|
| AC-3, AC-5, B-9 | an extra or reordered invocation slips in — the timer start landing before `sc reload` | `Q1` asserts **exact call-log equality**, not just presence | **Survived.** Log is exactly `sc update-rules / enable sing-box / enable …timer / sc reload / start sing-box / start …timer` in both languages |
| AC-4, BC-2 | `set -e` still kills the run at the failing `sc reload`, or a `start` leaks onto the failure path | `Q2` | **Survived.** Last stdout line is the `fail_log` pointer; zero `^systemctl start ` |
| AC-14 | the failure path exits 0 (the rev-1 regression, gate F-3) | `Q2`, `Q5`, `Q9`, `Q11` | **Survived.** rc=1 on every failure scenario, rc=0 on every success scenario |
| BC-3 | 127 behaves differently from 1 — bash prints `No such file` to the user's terminal | `Q3` (`sc` symlink deleted) | **Survived.** rc=1, `PHASES failed\|failed\|not-started`, diagnostic only in the log |
| — | a missing `systemctl` on a systemd host aborts under `set -e` | `Q4` (`systemctl` deleted, `INIT_SYS=systemd`) | **Survived.** rc=1, `ok\|ok\|not-started`, `fail_service`, stderr clean |
| BC-5 | a failed `systemctl start` still prints the success banner (the original defect class) | `Q5` | **Survived.** `fail_service`, no `done_banner`, rc=1 |
| §3.1 | the auxiliary timer's failure is folded into `PHASE_SERVICE` and flips a good run to failed | `Q6` (`RC_START_TIMER=1` only) | **Survived.** rc=0, `ok\|ok\|started` |
| BC-4 | a failing `enable` short-circuits the second one, or aborts | `Q7`, `Q7b` | **Survived.** Both enables attempted, both starts still ran, rc=0 |
| AC-7, BC-6 | a `systemctl` token leaks onto the OpenRC path, or the stub needs an external command under a strict PATH | `Q8` (`PATH=$STUB` only, `systemctl` deleted) | **Survived.** Exact log = `sc update-rules / rc-update add / sc reload / rc-service start`; zero `systemctl`; zero `sing-box-rules-update` |
| B-16 | the banner hardcodes `systemctl` regardless of init system | `Q9` | **Survived.** `rc-service sing-box status`; the string `systemctl` never appears |
| AC-15, BC-15 | a ruleset failure alone flips the run to failed, or the cause leaks to the terminal | `Q10` | **Survived.** rc=0, success banner, `QACAUSE`+`QAAGG` in the log and **absent** from stdout |
| BC-14 | the ruleset hint is missing, or one of the two causes is lost | `Q11` (the reported real case) | **Survived.** `fail_rulesets` printed, both causes in the log, both units enabled, rc=1 |
| AC-19, B-17, G-1 | the degraded-log path prints `/dev/null`, changes a phase, or changes the exit status | `Q12` — **4 phase outcomes × 2 languages**, each diffed against its writable twin, plus a `SINKEQ` probe proving the probe really failed | **Survived.** Identical rc + identical `PHASES`; success stdout **byte-identical**; failure stdout differs by exactly the one (`fail_nolog`) or two (`+step6_nolog`) lines, each naming the **real** path; no `/dev/null` token anywhere; no log file created |
| BC-17 | `>>` against a directory escapes the probe and kills the run | `Q13` | **Survived.** rc=0, `SINKEQ no`, phases unchanged |
| — | an unquoted redirection target word-splits on a space | `Q14` | **Survived.** |
| BC-18, AC-8 | the second run truncates the log or diverges | `Q15` | **Survived.** |
| — | concurrent appenders corrupt each other's lines | `Q16` (10 parallel) | **Survived.** 10/10 markers and cause lines intact |
| AC-16, AC-17, STD-3 | a key exists in one branch only, or a call site has the wrong arity | `Q17` (independent Python parser; call-site audit) | **Survived.** 40/40, identical names, no arity mismatch, no non-`%s` conversion, `missing:none`, `BAD none` |
| AC-16, BC-22 | zh is only reachable via the prompt, and some input path leaves `LANG_CHOICE` wrong | `Q18` — executes `install.sh:116-285` for real with 8 stdin cases | **Survived** (one pre-existing, non-blocking observation — §8 D-3) |
| B-18, BC-21 | the EXIT trap overrides the derived status | `Q19` | **Survived** on bash 5.2; the 4.2-specific fault is not reproducible here (§0) |
| **meta** | **the suites are vacuous — they would stay green on broken code** | `qa_mutate.sh`: **17 mutants**, both suites run against each | **17/17 KILLED, 0 SURVIVED, 0 BROKEN** (§5.2) |

**Two mutation reproducers inside `qa_adversarial.sh` itself** (`Q20`), so the two highest-severity claims
are proven falsifiable in-suite:

```
PASS  Q20/M-A a one-language key DOES abort the zh run (STD-3 is real)
PASS  Q20/M-A the en run is unaffected — an English-only test CANNOT detect it
PASS  Q20/M-B the G-1 defect DOES print /dev/null when re-introduced
```

---

## 4. Executed evidence

### 4.1 Direct commands

```
$ bash -n install.sh
BASH_N_OK
exit=0
```

```
$ bash .harness/scripts/verify_all.sh
[A.1] No hardcoded secrets ... PASS
[A.2] No .env files committed ... PASS
[B.1] Syntax (bin/sc, install.sh, uninstall.sh) ... PASS
[B.2] Tests pass ... SKIP
[B.3] Lint ... SKIP
[E.1] Bootstrap files present ... PASS
[E.2] workflow.md present ... PASS
[E.3] Agents layout v0.30+ (.harness/agents/ = partition dev-* only) ... PASS
[E.4] Binding in sync (.harness/ -> .claude/) ... PASS
[E.4b] Hook commands resolve to existing scripts ... PASS
[E.5] AI-GUIDE.md indexes every .harness/rules/*.md ... PASS
[E.6] Adversarial tests section in completed task reports ... PASS
[F.1] AI-GUIDE.md <=200 lines ... PASS
[F.2] Rule fragments <=200 lines each ... PASS
[F.3] Agent definitions <=300 lines each ... PASS
[F.4] insight-index.md <=30 lines ... PASS
[F.5] docs/tasks.md <=300 lines ... PASS
[F.6] Active task docs <=500 lines each ... WARN

=== Summary ===
  PASS: 15
  WARN: 1
  FAIL: 0
  SKIP: 2
VERIFY_EXIT=1
```

Re-run **after** this report existed on disk (so `[E.6]` had a file to inspect): identical summary —
`PASS: 15 / WARN: 1 / FAIL: 0 / SKIP: 2`, with `[E.6] Adversarial tests section in completed task reports
... PASS`. Recorded for honesty: my first draft numbered that heading (`## 3. Adversarial tests`), which
`verify_all.sh:168`'s `^##\s+Adversarial\s+tests` rejected — a real `FAIL: 1` that I fixed by renaming
**my own heading**, never the check (that would be circumventing the safety net).

**`FAIL: 0` — the AC-2 requirement as written is met.** The single `WARN` is **not** in the code: F.6's
only offender is `docs/features/install-enable-start-split/PM_LOG.md` at **554 lines** (cap 500), which
grew after the gate measured it at 418. `verify_all.sh` exits 1 whenever `warns > 0` (`:243`). Filed as
**D-1** (§8) and routed to the PM; the developer's stage-4 run recorded `PASS: 16 / WARN: 0`, so this is
the one measurable delta since stage 4 and it is attributable to a stage document, exactly as C-9 foresaw.
Line counts today: `01` 404, `02` 481, `03` 430, `04` 207, `05` 377, **`PM_LOG` 554**, this report < 500.

### 4.2 Suites

```
$ bash test/step7/run.sh            → PASS: 334   FAIL: 0   (exit 0)
$ bash test/step7/qa_adversarial.sh → PASS: 341   FAIL: 0   (exit 0)
$ bash test/step7/qa_mutate.sh      → KILLED: 17  SURVIVED: 0  BROKEN: 0
```

`qa_adversarial.sh` also prints one non-counted line:
`NOTE  Q19 BC-21 bash-4.2 fault NOT reproducible on bash 5.2.21(1)-release — reasoned statically only`.

### 4.3 AC-10 — diff confinement

```
$ git diff --stat
 CHANGELOG.md  |   1 +
 docs/tasks.md |   2 +-
 install.sh    | 157 +++++++++++++++++++++++++++++++++++++++++++++++++---------

bin/sc IDENTICAL · uninstall.sh IDENTICAL · systemd IDENTICAL · .harness IDENTICAL
README.md IDENTICAL · docs/dev-map.md IDENTICAL
bin/sc timeouts :583=3 :742=8 :812=30 — unmoved
CHANGELOG.md: exactly one added bullet under [Unreleased] → 修复 (2 bullets total)
git status --short lists no test/ entry (gitignored)
```

`docs/tasks.md` is the PM's stage-0 board row, present before stage 4 (`04` §Files changed).

### 4.4 G-1 / `LOG_SINK` static audit (executed greps)

```
$ grep -n 't step6_warn\|t step6_nolog\|t fail_log\|t fail_nolog' install.sh
263:        t fail_log "$INSTALL_LOG"      265:        t fail_nolog "$INSTALL_LOG"
460:    t step6_warn "$INSTALL_LOG"        462:    t step6_nolog "$INSTALL_LOG"
$ grep -c '^INSTALL_LOG=' install.sh → 1        $ grep -c 'INSTALL_OK' install.sh → 0
```

`LOG_SINK` occurs only at `:19` (comment), `:22` (declaration), `:451` (the probe's promotion), `:262`/`:459`
(the equality test) and as a redirection target at `:456,471,472,474,479,482,486,488` — **never** an
argument to `t`. No `/dev/null` literal appears in any `t()` string (only comments, the `LOG_SINK` default
and pre-existing step-1…5 redirections).

Rendered failure output, both languages, exit status appended (the reported real case: rulesets **and**
reload fail), captured verbatim from a stub-driven run:

```
▶ [6/7] 下载规则集 (.srs) ...
  ⚠️ 规则集下载失败，详细原因见 <LOG>，稍后用 'sc update-rules' 重试
▶ [7/7] 生成初始配置并启动服务 ...

═══════════════════════════════════════════════════════
  ❌ 安装未完成
═══════════════════════════════════════════════════════

配置生成失败：sing-box 没有通过配置校验，服务未启动。
规则集缺失（第 6 步下载失败），这通常就是配置校验失败的原因。

请手动执行以下命令修复（系统不会自动恢复）：
  1. 重新下载规则集：sc update-rules
  2. 重新生成配置：  sc reload
  3. 查看服务状态：  systemctl status sing-box

详细错误已记录在 <LOG>
[exit status: 1]
```

```
  ❌ Install incomplete … Config generation failed: … The rulesets are missing …
  1. Re-download rulesets: sc update-rules / 2. Regenerate config:    sc reload
  3. Check service state:  systemctl status sing-box
The detailed error was written to <LOG>            [exit status: 1]

$ ls -l <LOG>  → -rw-r----- (0640)
$ cat <LOG>    → ===== singbox-cli install (pid 559021) =====
                 urlopen error timed out
                 FATAL parse rule-set[0]
```

Substring audit on that output (both languages): `安装完成` **absent**, `Install complete` **absent**,
`/dev/null` **absent**. (`安装未完成` does not contain `安装完成`; `Install incomplete` does not contain
`Install complete`.)

### 4.5 AC-5 baseline (`02` §10.2.3)

Baseline built from **`HEAD` = `74f65edc23d03fb2cb03505ff14ba193f7dfecfe`**. Both §10.2.3 tripwires fired
correctly (`install_report` absent from HEAD; no install-log block; step-6 marker present). `HEAD:install.sh`
is **byte-identical** to `6282cea`, the sha `04:129` recorded — verified with
`git diff --quiet 6282cea 74f65ed -- install.sh` → no difference, so the stage-4 AC-5 result and this one
were computed against the same baseline bytes. Result: `diff` of the two captured stdouts is **empty in
both languages**, in both suites.

---

## 5. Audit of the developer's harness (I did not trust it blindly)

### 5.1 Read, re-derived, and one correction applied

I read all 471 lines of `test/step7/run.sh` and re-derived every claim it makes with my own suite. **No
assertion in it was found to be false, and none of its 334 passes was vacuous on the current code.** Its
C-6 fixes are intact and were preserved: `T_DIR` in the scenario env (`:149`), pure-builtin `${0##*/}` stub
(`:86`, plus the driver's builtin `${_body#*$'\n'}` in place of `declare -f | tail`), `[+]`-free awk
extraction, whole-line `grep -nxF`/`-qxF` (`:169-171`).

**Correction made (QA-owned file, no production change):** `outhas`/`outhasnt` passed their needle straight
to `grep -qF`, and `grep -qF ""` matches every line — so if `msg` ever rendered empty (the STD-3 failure
mode) `outhas` would have passed *vacuously* and `outhasnt` would have failed for the wrong reason. Both
now reject an empty needle explicitly. Re-run after the change: **PASS: 334 / FAIL: 0**, unchanged, and all
17 mutants still killed — the hardening is a genuine tightening, not a rewrite.

**Gaps in `run.sh` — closed by `qa_adversarial.sh`, not by deleting anything**: (i) presence/absence call-log
assertions only, so an *extra* invocation could pass unnoticed → `Q1/Q2/Q8` assert exact log equality;
(ii) one `STUB_SYSTEMCTL_START_RC` for both units, so "the timer is auxiliary" was untested → `Q6/Q7`;
(iii) stderr checked against a blacklist → `err_pure` asserts stderr is *exactly* the probe's own lines;
(iv) no call-site key/arity audit, no directory-as-log, no odd path, no concurrency, no EXIT-trap test, and
zh reached only by presetting `LANG_CHOICE` → `Q13`–`Q19`. **No test was deleted**; both rev-1 QA files
were *rewritten in place* because their subject (`INSTALL_OK`, `>/dev/null` redirection) no longer exists in
rev. 3 — every assertion they made is re-made in its rev-3 form plus ~90 new ones.

### 5.2 Mutation results — proof the green is meaningful

`bash test/step7/qa_mutate.sh`, 17 mutants, both suites per mutant, every mutant verified to actually
differ from the shipped file:

| Mutant | Injected defect | Result |
|---|---|---|
| M1 | revert to `HEAD` (reload first, `enable --now`, unguarded, no log) | KILLED (207 / 173 failures) |
| M2 / M17 | `PHASE_CONFIG` / `PHASE_SERVICE` given an optimistic default | KILLED (9 / 8, 20 / 14) |
| M3 | `PHASE_SERVICE="started"` inside a subshell (BC-12) | KILLED (33 / 30) |
| M4 | second `systemctl enable` loses `\|\| true` (B-3) | KILLED (7 / 8) |
| M5 | `systemctl start` hoisted out of the guard (B-6) | KILLED (22 / 20) |
| M6 | registration moved after `sc reload` (B-9) | KILLED (8 / 4) |
| M7 | invented rules-update registration on OpenRC (AC-7) | KILLED (4 / 3) |
| M8 | `sc reload` redirected back to `/dev/null` (B-12) | KILLED (6 / 3) |
| M9 | success test drops the `PHASE_SERVICE` clause (B-11/B-15) | KILLED (10 / 6) |
| M10 | `install_report \|\| true` — exit status discarded (B-11) | KILLED (14 / 10) |
| M11 | `sc reload` out of `if`-condition position (B-5, errexit) | KILLED (43 / 44) |
| M12 | `fail_log`/`fail_nolog` name `$LOG_SINK` — the G-1 defect | KILLED (11 / 11) |
| M13 | zh-only key deletion (`fail_config`) — STD-3 | KILLED (27 / 31) |
| M14 | probe polarity inverted | KILLED (60 / 40) |
| M15 | `umask 027` dropped from the probe (B-19/AC-20) | KILLED (1 / 1) |
| M16 | `t step6_warn` called with no argument (literal `%s`) | KILLED (3 / 5) |

**KILLED 17 · SURVIVED 0 · BROKEN 0.** Both suites independently caught all 17.

---

## 6. Coverage limits — `02` §10.3 restated **verbatim** (gate C-7)

> 1. Only the install-log block → EOF, plus `t()` and `install_report()`, are executed; pre-flight and steps 1-5 are not exercised.
> 2. `/usr/local/bin/sc` and `INSTALL_LOG` are rewritten/overridden (shipped literals covered statically only; `LOG_SINK` is still derived by the real probe), and the `sc` stub does not emulate `sc`'s internal `systemctl restart` (`bin/sc:560-571`).
> 3. No real init system runs: `systemctl enable`/`start` semantics (symlinks, masked units, `Type=simple` start-vs-alive, container buses) are **not** verified — only that the calls are issued, in order, tolerated and recorded. R1 is therefore untested.
> 4. B-8 is proxied at region granularity (S13); whole-installer idempotency is not run. AC-19/S11 rely on `chmod 500` denying the *non-root* harness user, so they do not model a root install on a read-only mount, and **AC-9 is not executed. Full stop.**

**AC-9 is UNVERIFIED and deferred to T-07.** No network-restricted systemd VM exists in this environment
and this stage did not run one. QA's partial extension of limit 1: `Q18` additionally executes
`install.sh:116-285` (the i18n table and the real language prompt) and `Q19` executes `:300-305` (the
cleanup trap), so the un-exercised region is now pre-flight + steps 1-5 minus those two blocks.

---

## 7. AC-5 — scope of the byte-identity claim (code review **M-1**, acted on)

**AC-5's "success output byte-identical" is claimed here only for _stdout, under a stub that is silent on
success_. It is NOT claimed for a real systemd host.** `HEAD:install.sh` ran `systemctl enable --now
sing-box` **unredirected** — executed evidence: `Q21` asserts the literal is present in `HEAD:install.sh`
and that HEAD's call log contains exactly `systemctl enable --now sing-box`, while rev. 3 issues `enable`
and `start` separately with both streams going to `$LOG_SINK`. On a real host `systemctl enable` writes
`Created symlink /etc/systemd/system/… → …` to **stderr**, which used to reach the user's terminal and now
reaches the log instead. That change is deliberate and approved (`02` §4.G retires the D-5 asymmetry; gate
rev. 2 approved it; `05` M-1 classes it "not a defect in `install.sh`" and "strictly an improvement").
**The harness structurally cannot observe it**, because the stub emits nothing on success — the reason is
`02` §10.3 **limit 3** (real `systemctl` semantics are not verified). So: AC-5 **PASSES as scoped**;
the real-host stderr delta is **unverified** and belongs with AC-9 to T-07. `04:128`'s unqualified
phrasing ("the banner move changed nothing a user sees") is corrected by this section.

---

## 8. Defects found

**In `install.sh`: none.** 0 BLOCKER, 0 CRITICAL, 0 MAJOR, 0 MINOR against the code under test.

- **[MAJOR — process, not code] D-1: `verify_all` exits 1 with `WARN: 1` because `PM_LOG.md` is 554 lines
  (cap 500), violating gate condition C-9.**
  Reproducer: `bash .harness/scripts/verify_all.sh` → `[F.6] Active task docs <=500 lines each ... WARN`,
  exit 1; `wc -l docs/features/install-enable-start-split/PM_LOG.md` → 554. File: `PM_LOG.md` (all stage
  docs are within cap: 404 / 481 / 430 / 207 / 377). Owner: **PM** (a QA edit of the PM's log would be an
  upstream-document edit and is out of my mandate). Fix: compact `PM_LOG.md` below 500 lines
  (`70-doc-size.md`: "reference, don't paste"). Not attributable to stage 4 — the developer's run recorded
  `PASS: 16 / WARN: 0 / FAIL: 0`. **`FAIL` is still 0, so the AC-2 criterion as literally written is met;
  the delivery gate for "clean exit 0" is not.**
- **[MINOR — doc accuracy] D-2: `04:129` records the AC-5 baseline as `HEAD = 6282cea`; `HEAD` is now
  `74f65ed`.** Harmless and verified so: `git diff --quiet 6282cea 74f65ed -- install.sh` reports no
  difference (the intervening commit is docs-only), so both runs compared the same bytes. Reproducer:
  `git rev-parse HEAD`. No action needed beyond this note; recorded because §10.2.3 requires the resolved
  sha to be recorded in `06`.
- **[MINOR — pre-existing, out of scope] D-3: with stdin *closed*, the language prompt emits
  `install.sh: line 279: read: read error: 0: Bad file descriptor` before defaulting correctly.**
  Reproducer: extract `:116-285` and source it with `0<&-`. **Proven pre-existing**: the identical
  diagnostic appears from `HEAD:install.sh` (`Q18` asserts the two messages are identical after stripping
  the `file: line N:` prefix), the region is untouched by T-01, `LANG_CHOICE` still defaults correctly and
  the exit status is unaffected. Not a regression; candidate backlog row, not a T-01 change.
- **[INFO] D-4: `install.log` mode is set by the probe's `umask 027`, which applies at *creation* only.**
  A pre-existing file with a looser mode would not be tightened. Not exploitable in production: the parent
  `/var/log/sing-box` is created root-owned `0755` at `install.sh:375`, so only root can pre-create the
  file. Recorded, not filed; no upstream requirement covers re-chmod and B-19 says "created … with a mode".

**Routing**: D-1 → PM (doc compaction). D-2/D-3/D-4 → informational; no developer or analyst action is
required for T-01, and no defect routes back to the developer.

---

## 9. Stability

- `test/step7/qa_adversarial.sh` — **10 consecutive runs, all green** (341/341 each). No flakes.
- `test/step7/run.sh` — **10 consecutive runs, all green** (334/334 each), including after the §5.1
  hardening. No flakes.
- `qa_mutate.sh` — run twice (before and after the §5.1 change): 17/17 killed both times.
- `verify_all` — run 3 times, identical output each time (`PASS 15 / WARN 1 / FAIL 0 / SKIP 2`).
- Timing: each suite ≈ 1.9 s wall, so the whole set is cheap enough for T-07 to promote into `verify_all` B.2.

---

## 10. Test-count baseline (`.harness/scripts/baseline.json`)

**Left unchanged at `test_count: 0 / passing_count: 0 / warnings_baseline: 0`, deliberately.**

`baseline.json` is a **tracked** file (`git ls-files` confirms). Writing 675 into it would (i) break
**AC-10 / gate C-1** ("no file other than `install.sh` and the one amended `CHANGELOG.md` bullet may
change"), and (ii) assert a committed test count for suites that live in a **gitignored** directory and are
not runnable from a fresh clone — the same overclaim class this task exists to remove. `[B.2] Tests pass`
therefore stays `SKIP` (design D-6, gate C-5: `verify_all.sh` must not be touched here).

**Recommended for T-07** (which owns promotion of both the harness and the key-parity check): commit
`test/step7/`, wire `[B.2]` to run both suites, and set `test_count`/`passing_count` to **675**
(334 + 341) as the floor, with `warnings_baseline` staying **0**. Baseline only goes up.

---

## Verdict

**APPROVED FOR DELIVERY.**

`install.sh` has **zero defects** against AC-1…AC-8 and AC-10…AC-20: 675 executed assertions across two
independent suites (334 developer + 341 QA-authored), every scenario in **both** languages, 17/17 mutants
killed, 10/10 stable repeat runs, `bash -n` clean, and `verify_all` at **`FAIL: 0`**. The six items the
coordinator asked to be proven — (a) registration despite a failing `sc reload`, (b) no abort, (c) failure
banner and never the success banner, (d) non-zero exit, (e) an unchanged success path, (f) both languages
for every new string — are each backed by an independent reproducer and pasted output.

Two things are **explicitly not claimed**: **AC-9 is UNVERIFIED and deferred to T-07** (no
network-restricted systemd host here), and **AC-5's byte-identity is scoped to stdout under a
silent-on-success stub** (`02` §10.3 limit 3; the real-host `Created symlink` stderr delta is a deliberate,
approved, unobservable-here improvement — code review M-1).

One **MAJOR process defect outside the code** stands open for the PM: `PM_LOG.md` at 554 lines keeps
`verify_all` at `WARN: 1` / exit 1 (gate C-9). It blocks a clean `exit 0`, not the code — **stage 7 may
proceed on the code; the doc must be compacted before the gate reads clean.**
