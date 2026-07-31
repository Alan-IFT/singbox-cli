# 02 — Solution Design — install-enable-start-split (T-01)

- **Task ID**: T-01 · **Mode**: full · **Date**: 2026-07-31 (**rev. 3** — narrow amendment for gate finding G-1)
- **Upstream**: `01_REQUIREMENT_ANALYSIS.md` **rev. 2**, verdict `READY`; `03_GATE_REVIEW.md` **rev. 2**, `APPROVED WITH CONDITIONS`
- **Dispatch context**: deferred-human mode (defer, do not ask) · **Verdict**: `READY`

## 0. Revision history

| Rev | What changed | Why |
|---|---|---|
| 1 | Step 7 only: unconditional registration + `INSTALL_OK`; banner, exit status, logging and messaging deferred to T-04. | Mirrored the rev.-1 requirement's T-01/T-04 split. |
| 2 | T-04 absorbed. One behavior: **install.sh reports its true outcome**. Adds the three-variable phase-status model in the constant block, `install_report()` deriving banner **and** exit code, `/var/log/sing-box/install.log` capture for steps 6-7, 9 bilingual `t()` keys, a rewritten `step6_warn`, the `CLEANUP_DIRS` EXIT-trap fix; `INSTALL_OK` **retired** (§3.1); rev.-1 §5.2/§6/§7 and D-2/D-4/D-5 **cut**, not appended to. Rev. 1's shipped control-flow shape — register unconditionally, `sc reload` in condition position, launch only on success (code-review `APPROVED`) — is **kept**; only the status carrier, the redirection targets and the closing block change. | Owner directive 「优先用好的设计，避免不断的修修补补」. |
| **3 (this document)** | **Gate finding G-1 only.** The displayed log path and the redirection target become **two variables** (`INSTALL_LOG` / `LOG_SINK`, §3.1.1), so a failed writability probe can no longer make the installer say 「详细原因见 /dev/null」; +2 bilingual keys (**40/40**, §4.C); §4.E blank-line layout specified (G-5); §10.2.3 adds the S1 baseline recipe (G-3); S11 restated and now satisfiable. | Gate rev. 2 §5 G-1/G-3/G-5 + §9 H-1; same owner directive — fix the mechanism rather than ship a documented dishonesty. |

Rev. 3 touches §1, §3.1.1 (new), §3.2, §3.3, §4.A/C/D/E/F/G, §5-§7, §9 R3/R4, §10.2-§10.2.3 (10.2.3 new),
§12 and §14 D-9 (new). **Every other decision is unchanged and not reopened**: the phase-status model,
`INSTALL_OK`'s retirement, Q2's both-streams capture, the no-`tee` mechanism, Q5's "do not edit
`verify_all`", and the D-4/D-5 reversals — all confirmed by gate rev. 2 §2.1-§2.5.

## 1. Architecture summary

`install.sh` gains a small explicit **phase-status model**: three top-level variables with pessimistic defaults beside the other constants, written by the step that owns each phase (step 6 → rulesets; step 7 → config, service), read by one new function `install_report()` that prints the closing block **and** returns the process exit status. The success banner is unchanged; the failure banner names the failed phase, lists three remediation commands and names the log. Every diagnostic steps 6-7 send to `/dev/null` today is appended to `/var/log/sing-box/install.log` (0640) instead, behind a one-time writability probe. The path the user is **shown** (`INSTALL_LOG`) and the path commands are **redirected to** (`LOG_SINK`) are separate variables, so degrading the sink can never make a message lie (§3.1.1), and logging can never change what the installer does. The `cleanup` EXIT trap becomes empty-array-safe so it cannot override the derived status on bash 4.2. No new file, external command, dependency or network call.

## 2. Affected modules

| File | Change |
|---|---|
| `/home/alan/Programs/singbox-cli/install.sh` | Eight regions, §4 A-H. Everything else byte-identical. |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | **Amend the existing bullet at line 8 in place** (§4.I). No second bullet, no heading, no version bump. |

Not modified: `bin/sc` (byte-identical; timeouts at `:583`/`:742`/`:812` untouched), `uninstall.sh` (already `rm -rf /var/log/sing-box/` at `:137`, disclosed at `:49`/`:68`, so `install.log` leaves no residue), `systemd/*`, `README*.md`, `.harness/scripts/verify_all.sh` (§14 D-6), `docs/dev-map.md`, `CONTEXT.md` (no domain term coined; `PHASE_*`/`INSTALL_LOG`/`LOG_SINK`/`install_report` are implementation identifiers).

## 3. Status model and module decomposition

### 3.1 The phase status

| Variable | Legal values | Only writer | Meaning |
|---|---|---|---|
| `PHASE_RULESETS` | `ok` \| `failed` | step 6 | `/usr/local/bin/sc update-rules` exited 0. |
| `PHASE_CONFIG` | `ok` \| `failed` | step 7 | `/usr/local/bin/sc reload` exited 0 — config regenerated **and** passed `sing-box check` (`bin/sc:552-557`, `:928-932`). |
| `PHASE_SERVICE` | `started` \| `not-started` | step 7 | The **`sing-box`** launch command exited 0; `not-started` whenever launch is skipped. |

Declared once with pessimistic defaults (§4.A), so nothing claims success until a step records it; one consumer, `install_report()`, so no second condition re-derives "did it work". **`INSTALL_OK` is retired, not kept** (gate rev. 2 §2.1 confirms): the name asserts "the install is OK" while the value only ever encoded *config generation* (a failed `systemctl start` still left it `1`), so once the banner reads the state that name puts a lie one dereference from the banner. **The rules-update timer is deliberately not a phase**: `systemctl start …timer` stays `|| true` and unrecorded — an auxiliary weekly schedule failing does not make a running proxy a failed install, and its unit is separately broken (§12.8). B-4 names one service-launch command; this is it.

### 3.1.1 The log path is two variables, not one (fixes gate G-1)

| Variable | Legal values | Only writer | Job |
|---|---|---|---|
| `INSTALL_LOG` | `/var/log/sing-box/install.log` | §4.A, constant | The path the user is **told about**. Never reassigned. |
| `LOG_SINK` | `"$INSTALL_LOG"` \| `/dev/null` | the §4.E probe | The path commands are **redirected to**. |

Rev. 2 gave one variable both jobs, so a failed probe reassigned it and every message then named `/dev/null` — untrue twice over: nothing was written there, and the path the user must be told about is the real one (B-15 iii, B-14). Splitting them makes every message true on **every** path by construction, and the sink's pessimistic `/dev/null` default matches §3.1's discipline — the probe *promotes* the sink after proving the file openable, instead of a constant being demoted. **Invariant**: `LOG_SINK` holds exactly one of its two values and nothing else assigns it, so `[ "$LOG_SINK" = "$INSTALL_LOG" ]` is an exact test of "were this run's diagnostics saved", not a heuristic; it selects between two message variants at the only two sites that mention the log (§4.F step 6, §4.D failure banner). **No third `LOG_SAVED` flag**: it would be redundant state co-varying with `LOG_SINK`, and by the deletion test a predicate function wrapping a single `[` at two call sites is a pass-through. **B-17 still holds**: both variables are literal assignments and neither is read by the success test, so no logging outcome can move a phase or the exit status. The requirement reading this rests on is recorded as **D-9** (§14).

### 3.2 `install_report()` — the one new module

Defined immediately after `t()` (current `install.sh:183`), called from the file's last lines. No parameters; reads globals `PHASE_RULESETS`, `PHASE_CONFIG`, `PHASE_SERVICE`, `INIT_SYS`, `INSTALL_LOG`, `LOG_SINK`; writes to **stdout**; **returns 0** iff `PHASE_CONFIG=ok` **and** `PHASE_SERVICE=started`, else `1`. A function rather than an inline `if`, so "what counted as success" is one named place where the exit status, the banner and the harness all cross — delete it and the derivation reappears at two call sites, which is how the tree came to print `✅ 安装完成` while step 7 already knew better. Not built: no persisted health state, no state file, no `sc doctor` contract (requirement §4.7).

### 3.3 `set -e` / `set -u` / `pipefail` / subshells (`install.sh:9` = `set -euo pipefail`)

- **Assignments** are literals with no command substitution → status 0; no `((…))`, no `let` (BC-9).
- **Guards**: `sc update-rules`, `sc reload`, `systemctl start sing-box`, `rc-service … start` and the log probe sit in **`if` condition position** (errexit suspended); registrations and the timer start are left operands of `|| true`. Nothing new can abort the script (BC-10; BC-3: 127 is just non-zero). An `if` with a false condition and no `else` returns 0, and every new arm ends in an assignment or `|| true`, so `$?` entering the closing block is 0 on every path. At the call site `install_report || exit 1` errexit is suspended for the whole function body; its commands are all `echo`/`t`/`[`, and "the report always finishes printing" is what we want.
- **`set -u`**: all six globals `install_report()` reads are assigned before any read on every path — `INIT_SYS` at `:55-56`, the rest in §4.A. Hence the hoist (rev.-1 D-4 reversed, §14 D-4).
- **Subshells**: the only new one is the log probe, which contains **no** assignment; `LOG_SINK="$INSTALL_LOG"` is assigned in the parent's `then` list. No `$( )`, no `&` (BC-12). No pipeline is introduced anywhere, so **`pipefail`** never applies — deliberate, see §6.

## 4. Exact final text of every changed region

Indentation 4 spaces (8 when nested). **Move the `echo "═══…"` separators rather than retyping them** — the
success output must stay byte-identical (AC-5); the ones printed below are verified 55-char identical to
the file's (gate rev. 2 §1.2), so copying §4.D verbatim is also safe.

### A. Constant block — append after `install.sh:16` (`SB_REPO=…`)

```bash
# The log path the user is TOLD about — never reassigned, so every message names
# the real path (B-14, B-15). LOG_SINK is where output is actually redirected;
# it stays /dev/null until the probe below step 5 proves the log file openable.
INSTALL_LOG="/var/log/sing-box/install.log"
LOG_SINK="/dev/null"         # "$INSTALL_LOG" | /dev/null — written only by the probe

# Phase status — the single source of truth for the closing report
# (install_report) and for the process exit status. Pessimistic defaults: a
# phase counts as failed until the step that owns it records otherwise.
PHASE_RULESETS="failed"      # ok | failed           — step 6
PHASE_CONFIG="failed"        # ok | failed           — step 7, sc reload
PHASE_SERVICE="not-started"  # started | not-started — step 7, service launch
```

### B. `cleanup()` — replace `install.sh:215-216` (`trap cleanup EXIT` at `:217` unchanged)

```bash
CLEANUP_DIRS=()
# "${arr[@]}" over an EMPTY array is an unbound-variable error under `set -u` on
# bash < 4.4 (CentOS/RHEL 7 ships 4.2). Inside the EXIT trap that would override
# the installer's derived exit status, so guard both the expansion and the rm.
cleanup() { for d in ${CLEANUP_DIRS[@]+"${CLEANUP_DIRS[@]}"}; do rm -rf "$d" || true; done; }
```

### C. `t()` keys — insert 11 lines after `note_initial)` in **both** branches

zh (after `install.sh:142`):

```bash
            fail_banner)         fmt="  ❌ 安装未完成" ;;
            fail_config)         fmt="配置生成失败：sing-box 没有通过配置校验，服务未启动。" ;;
            fail_service)        fmt="配置已生成，但服务启动失败，当前没有运行。" ;;
            fail_rulesets)       fmt="规则集缺失（第 6 步下载失败），这通常就是配置校验失败的原因。" ;;
            fail_next)           fmt="请手动执行以下命令修复（系统不会自动恢复）：" ;;
            fail_rules)          fmt="  1. 重新下载规则集：sc update-rules" ;;
            fail_reload)         fmt="  2. 重新生成配置：  sc reload" ;;
            fail_status)         fmt="  3. 查看服务状态：  %s" ;;
            fail_log)            fmt="详细错误已记录在 %s" ;;
            fail_nolog)          fmt="%s 不可写，本次的详细错误没有保存；请直接运行上面的命令查看错误输出。" ;;
            step6_nolog)         fmt="  ⚠️ 规则集下载失败，%s 不可写，详细原因未能保存，稍后用 'sc update-rules' 重试" ;;
```

en (after `install.sh:174`):

```bash
            fail_banner)         fmt="  ❌ Install incomplete" ;;
            fail_config)         fmt="Config generation failed: sing-box did not pass the config check, so the service was not started." ;;
            fail_service)        fmt="The config was generated, but the service failed to start and is not running." ;;
            fail_rulesets)       fmt="The rulesets are missing (the step 6 download failed) — that is usually why the config check fails." ;;
            fail_next)           fmt="Run these commands yourself to fix it (nothing repairs it automatically):" ;;
            fail_rules)          fmt="  1. Re-download rulesets: sc update-rules" ;;
            fail_reload)         fmt="  2. Regenerate config:    sc reload" ;;
            fail_status)         fmt="  3. Check service state:  %s" ;;
            fail_log)            fmt="The detailed error was written to %s" ;;
            fail_nolog)          fmt="%s is not writable, so the detailed error was not saved — run the commands above to see it." ;;
            step6_nolog)         fmt="  ⚠️ Ruleset download failed — %s is not writable, so the cause was not saved; retry later with 'sc update-rules'" ;;
```

Replace the two existing `step6_warn` lines (`:133` zh, `:165` en) with, respectively:

```bash
            step6_warn)          fmt="  ⚠️ 规则集下载失败，详细原因见 %s，稍后用 'sc update-rules' 重试" ;;
            step6_warn)          fmt="  ⚠️ Ruleset download failed — see %s for the cause; retry later with 'sc update-rules'" ;;
```

Both branches must end with **40 keys** (29 + 11 = rev. 2's 9 plus `fail_nolog` and `step6_nolog`) and with
**identical key names**. A key in only one branch aborts the installer for that language under `set -u`
(`install.sh:109-111,177-182`, STD-3), and the zh branch is only reachable via the prompt at `:195-199`, so
an English-only run cannot detect it — hence both blocks verbatim: copy, never re-derive. Alignment: key +
`)` padded to width 21, then `fmt=`; `%` only as `%s`, exactly one per new string, one argument per call.

### D. `install_report()` — insert after `t()`'s closing `}` (`install.sh:183`)

```bash
# Closing report. Reads the recorded phase status and nothing else, so the
# banner and the exit status can never disagree. Returns 0 for a successful
# install (config generated AND service running), 1 otherwise.
install_report() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    if [ "$PHASE_CONFIG" = "ok" ] && [ "$PHASE_SERVICE" = "started" ]; then
        t done_banner
        echo "═══════════════════════════════════════════════════════"
        echo ""
        t next_steps
        t next_add
        t next_status
        t next_help
        t next_lang
        t next_uninstall
        echo ""
        t note_initial
        return 0
    fi
    t fail_banner
    echo "═══════════════════════════════════════════════════════"
    echo ""
    if [ "$PHASE_CONFIG" = "ok" ]; then
        t fail_service
    else
        t fail_config
    fi
    if [ "$PHASE_RULESETS" = "failed" ]; then
        t fail_rulesets
    fi
    echo ""
    t fail_next
    t fail_rules
    t fail_reload
    if [ "$INIT_SYS" = "systemd" ]; then
        t fail_status "systemctl status sing-box"
    else
        t fail_status "rc-service sing-box status"
    fi
    echo ""
    # Always name the real log path; say which of the two things is true of it.
    if [ "$LOG_SINK" = "$INSTALL_LOG" ]; then
        t fail_log "$INSTALL_LOG"
    else
        t fail_nolog "$INSTALL_LOG"
    fi
    return 1
}
```

The success arm emits exactly today's 13-line closing block in today's order (B-15, AC-5) and never mentions
the log, so a degraded log leaves the success path byte-identical.

### E. Install-log block — insert **after the existing blank line `install.sh:354`**, ending with one new blank line (G-5)

Exact layout, so the file's `\n# ----------------- step N …` rhythm is preserved: `visudo -c -f …` (`:353`)
/ the existing blank line (`:354`) / the block below / **one new blank line** / `# ---------- step 6 …`.

```bash
# ----------------- install log -----------------
# Steps 6-7 append their diagnostics here, so a failed run keeps the real cause
# instead of sending it to /dev/null. Mode 0640: captured `sing-box check`
# output can quote fragments of the generated config. Only on success is the
# sink promoted to the real file — logging must never change what the installer
# does (a plain >> on an unwritable path makes the command itself fail), and
# INSTALL_LOG is never touched, so every message still names the real path.
if ( umask 027; printf '\n===== singbox-cli install (pid %s) =====\n' "$$" >>"$INSTALL_LOG" ) 2>/dev/null; then
    LOG_SINK="$INSTALL_LOG"
fi
```

`/var/log/sing-box` already exists (`install.sh:287`, step 3, ordered before this block — BC-16); the marker
makes each run distinguishable inside the appended file (BC-18). The `if` has no `else` and its condition is
a subshell with stderr discarded, so a failed probe is silent (no `Permission denied` on the terminal),
non-fatal, and leaves the statement's status 0.

### F. Step 6 — replace `install.sh:355-361`

```bash
# ----------------- step 6: rulesets -----------------
t step6
if /usr/local/bin/sc update-rules >>"$LOG_SINK" 2>&1; then
    PHASE_RULESETS="ok"
    t step6_ok
elif [ "$LOG_SINK" = "$INSTALL_LOG" ]; then
    t step6_warn "$INSTALL_LOG"
else
    t step6_nolog "$INSTALL_LOG"
fi
```

**Both** streams are captured, not stderr only: `sc update-rules` prints the per-file cause on **stdout**
(`bin/sc:817`, the `urlopen error timed out` text) and only the aggregate on stderr (`bin/sc:821`), so a
literal stderr-only capture would log the count and lose the cause (Q2, gate F-4). The `elif` (rather than a
nested `if`) keeps the block flat and the two warning variants side by side; both name `$INSTALL_LOG`, never
`$LOG_SINK` (B-14).

### G. Step 7 — replace `install.sh:363-386`

```bash
# ----------------- step 7: enable + start -----------------
t step7

# Register for boot autostart first: registration must not depend on config
# generation, and a failure here must never abort the install.
if [ "$INIT_SYS" = "systemd" ]; then
    systemctl enable sing-box >>"$LOG_SINK" 2>&1 || true
    systemctl enable sing-box-rules-update.timer >>"$LOG_SINK" 2>&1 || true
else
    rc-update add sing-box default >>"$LOG_SINK" 2>&1 || true
fi

# Generate the initial config; start the service only if that succeeded.
# Each phase records its own outcome; nothing else decides what the run was.
if /usr/local/bin/sc reload >>"$LOG_SINK" 2>&1; then
    PHASE_CONFIG="ok"
    if [ "$INIT_SYS" = "systemd" ]; then
        if systemctl start sing-box >>"$LOG_SINK" 2>&1; then
            PHASE_SERVICE="started"
        fi
        # The rules-update timer is auxiliary: its start does not decide the run.
        systemctl start sing-box-rules-update.timer >>"$LOG_SINK" 2>&1 || true
    else
        if rc-service sing-box start >>"$LOG_SINK" 2>&1; then
            PHASE_SERVICE="started"
        fi
    fi
fi
```

Rev.-1's redirection asymmetry (D-5) is **retired**: uniform logging gives both init systems the same
silent-on-success behavior *and* keeps a failed `systemctl start`'s diagnostics in the file the failure
banner points at. `PHASE_CONFIG="ok"` leads the `then` list; position is immaterial, every launch is guarded.

### H. Closing lines — replace the banner block `install.sh:388-400` (its 13 lines move into §4.D)

```bash
# The closing report and the exit status come from the same derivation, so the
# installer cannot print success for a run that did not install a working service.
install_report || exit 1
exit 0
```

`install_report` is the left operand of `||`, so errexit cannot pre-empt the explicit `exit`; one failure
value, `1` (Q6(a)).

### I. CHANGELOG — replace the bullet at `CHANGELOG.md:8` in place

```markdown
- **安装器如实报告安装结果**：以前 `install.sh` 第 7 步先执行 `sc reload` 再 `systemctl enable --now`，一旦规则集下载失败导致配置校验不通过，脚本会在 `set -e` 下直接中断，开机自启和自动更新定时器都没来得及注册；第 6、7 步的错误又全部丢进 `/dev/null`，结尾还无条件打印「✅ 安装完成」。现在：先无条件注册开机自启（`systemctl enable` / `rc-update add`，失败也不中断），再按配置生成是否成功决定要不要 `start` 服务；第 6、7 步的输出统一追加到 `/var/log/sing-box/install.log`（权限 0640，写不进去时如实说明而不是假装已记录）；结尾横幅与退出码都由记录的阶段状态推导——成功照旧，失败则打印失败原因、修复命令（`sc update-rules` / `sc reload` / `systemctl status sing-box`）和日志路径，并以非 0 退出。
```

## 5. API contracts

**Process exit status**: `0` iff `PHASE_CONFIG=ok` **and** `PHASE_SERVICE=started`, else `1`; nothing between `install_report` and termination alters it (§4.B closes the one known override path, B-18). This restores a machine-detectable failure signal: `main` exits 1 on the reported failure via errexit, the rev.-1 tree exits 0 (gate F-3), rev. 3 exits 1 **by derivation**. **`install.log`**: root-owned, `0640` (B-19), append-only, one `===== singbox-cli install (pid N) =====` marker per run, verbatim untranslated diagnostics (BC-19), read by no program. **User-facing log references**: every message that mentions the log names the literal `$INSTALL_LOG` path (B-14, B-15 iii) and states truthfully whether *this run's* diagnostics reached it; `/dev/null` is an implementation detail that never appears in output (§3.1.1). **`sc` (unchanged)**: `update-rules` / `reload` take no arguments; exit status selects a branch, output is captured; 127 is an ordinary non-zero.

## 6. Log-capture mechanism

`>>"$LOG_SINK" 2>&1` on each command — append, both streams, opened by the shell in the forked child. **No `tee`, no pipeline**: under `set -o pipefail`, `cmd | tee -a "$LOG"` reports the pipeline's worst status, so an unwritable log would flip a healthy phase to `failed` (the B-17/BC-13 hazard), and it would echo diagnostics to the terminal (breaking B-13); with no pipeline, `pipefail` never applies. **The probe is required** because a bare `>>` at an unwritable path fails *before* the command runs, so `if sc reload >>"$LOG" 2>&1` would record `PHASE_CONFIG=failed` on a healthy host and print `Permission denied` to the terminal; it resolves writability once into `LOG_SINK`, and call sites then redirect either to a known-openable path or to `/dev/null`, reproducing today's behavior exactly (B-17, AC-19) while the *displayed* path stays constant (§3.1.1). It cannot itself become fatal — a subshell in `if` condition position, stderr discarded, no `else` — and its `umask 027` creates the file `0640` without leaking to the parent (AC-20). **No new external command**: `umask`, `printf`, `$$` are builtins; a `date` timestamp was **declined** because requirement §7 forbids a new external command and bash 4.2's `printf '%(…)T'` argument handling is not safe to assume on the oldest supported distro.

## 7. Sequence / flow

```
step 5 → log block: probe once → LOG_SINK = "$INSTALL_LOG" | /dev/null  (dir made at :287)
                                 INSTALL_LOG unchanged — it is what the user is shown
step 6 if sc update-rules >>SINK ─ok─► PHASE_RULESETS=ok, t step6_ok
                    └─≠0─► SINK==log ? t step6_warn "$INSTALL_LOG" : t step6_nolog "$INSTALL_LOG"
step 7 7a REGISTER (unconditional, guarded, logged: `enable` ×2 | `rc-update add`)
       7b if sc reload >>SINK ─0─► PHASE_CONFIG=ok; if <launch sing-box> → PHASE_SERVICE=started
                                   (systemd also starts …timer || true — auxiliary, unrecorded)
                          └─≠0─► no launch runs; both phases keep pessimistic defaults
install_report()  ok & started ─► today's banner + next steps + note → return 0 → exit 0
                  otherwise    ─► ❌ banner + failed phase (+ rulesets hint) + the 3 remediation
                     commands + fail_log|fail_nolog "$INSTALL_LOG" → 1 → exit 1 (trap preserves it)
```

## 8. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Guard a failure-prone command so it selects a branch; make one non-fatal | `if /usr/local/bin/sc update-rules …; then … else … fi`; `… \|\| true` | `install.sh:357-361`; `:369-372`, `:26,48,49` | **Reuse both idioms** for all new guards. |
| Init-system dispatch / detection | `[ "$INIT_SYS" = "systemd" ]`, `IS_SYSTEMD`/`IS_OPENRC` | `install.sh:47-56`, `:317-345`, `:368` | Reuse unchanged; also makes BC-7 unreachable. |
| Unconditional registration + conditional launch | phases 7a/7b as shipped | `install.sh:363-386` | **Keep the shape**; only redirection and the status carrier change. |
| Bilingual message emission with `%s` | `t()` + `printf "$fmt\n" "$@"` | `install.sh:108-183`; callers `:227`, `:247-249` | Reuse; the 11 new keys follow the two-branch, aligned-`fmt=` style. |
| Closing banner / next-steps text | `done_banner`, `next_*`, `note_initial` | `install.sh:388-400` → §4.D | **Move, do not retype.** |
| Log dir creation; removal + disclosure at uninstall; EXIT cleanup | `mkdir -p … /var/log/sing-box …`; `rm -rf /var/log/sing-box/`, `list_log`; `cleanup()` + `trap` | `install.sh:287`, `:215-217`; `uninstall.sh:137`, `:49`, `:68` | Reuse as precondition (no new `mkdir`, BC-16); uninstall already covers `install.log`; `cleanup()` **extended in place** (§4.B), no new trap. |
| A "did this side-effect actually happen" flag reusable for the log | none — `INSTALL_OK` was the only outcome carrier and is retired (§3.1) | `install.sh:376-385` | **Two plain variables justified** (§3.1.1); no helper, no new state. |
| Deriving a run outcome; a committed test runner | none (the banner is unconditional; B.2/B.3 are `SKIP`) | `install.sh:388-400`; `.harness/scripts/verify_all.sh:70-71` | **New function justified**; harness stays uncommitted (§10), B.2 promotion with T-07 (§14 D-6). |

Checked and non-constraining: `.harness/insight-index.md` (header only), `.harness/rejected-decisions.md`
(template only; the `date`/`tee`/`LOG_SAVED` declines are task-scoped, recorded inline in §6 and §3.1.1),
`CONTEXT.md` and `docs/dev-map.md` (templates). **New dependencies: none.**

## 9. Risk analysis

| # | Risk | Sev | Mitigation / assessment |
|---|---|---|---|
| R1 | **`PHASE_SERVICE=started` can be optimistic**: `systemd/sing-box.service:8` is `Type=simple`, so `systemctl start` returns 0 once the process is forked; a binary dying 200 ms later still yields a success banner. | Med | **Accepted as B-4's definition** (phase = launch command's exit status). A liveness probe (`is-active` after a sleep) is a timing heuristic and belongs to `sc doctor` (T-05). Narrowed in practice: `sc reload` already passed `sing-box check` on the same config, excluding the common crash cause. Untested here (§10.3 item 3). |
| R2 | **Units enabled but not startable → 5 s restart loop** (`Restart=on-failure`, `RestartSec=5`, never trips the 5-starts/10 s limiter). | Med | Accepted — it is B-1/B-2/BC-14. Root cause removed by T-02; this design at least *tells* the user (banner + log) instead of failing silently. Recovery unchanged: `sc update-rules && sc reload`. |
| R3 | **A one-language `t()` key aborts the installer** under `set -u` (STD-3); 11 keys × 2 branches is where this bites, and rev. 3 adds the two most easily forgotten ones. | High if hit | §4.C gives both branches verbatim; S14 compares key sets statically and asserts **40/40**; AC-16 runs every scenario in both languages. Q4(a) keeps `t()` unmodified so the failure stays loud instead of printing an empty banner line. |
| R4 | **Success-path output drift**: the banner moves into a function; a retyped separator or reordered `t` call silently breaks "success output unchanged". | Med | §4 mandates *moving* the lines; S1 diffs a stubbed success run against a baseline built by the audited recipe in **§10.2.3**; the reviewer diffs `install.sh:388-400` against the function body. |
| R5 | **Log write fails mid-run** (disk fills after the probe) → a healthy command exits non-zero → wrong phase; separately the log **can quote config fragments** (`bin/sc:555`). | Low | Not closable without a pipeline, which §6 rejects for worse reasons; on a full disk the install fails for real anyway (`sc reload` writes `config.json`), and the realistic unwritable cases (missing dir, read-only mount, wrong owner) are caught by the probe. Disclosure is bounded by `0640` root-owned (B-19, AC-20) and `uninstall.sh:137`. Residual: the run then says "written to <path>" for a file that stopped accepting writes — one order of magnitude rarer than the probe case and not detectable without re-probing. |
| R6 | **EXIT trap overrides the exit status** on bash 4.2 (gate F-5). | Med | §4.B guards both the array expansion and `rm -rf`. Residual: bash 3.x, never supported. |
| R7 | **Harness false confidence** — it runs an *extracted* copy; drift would make a green run meaningless. | Med | It asserts every fragment is non-empty and `bash -n`-clean, and that the shipped file still contains the literals `INSTALL_LOG="/var/log/sing-box/install.log"` and `/usr/local/bin/sc` before any rewrite. Limits in §10.3. |

## 10. Verification design

### 10.1 Constraint, location, commit status

No systemd-capable, network-restricted host exists here, and an end-to-end run needs root, distro packages and GitHub. **AC-9 is NOT executable in this environment and will not be executed** — stages 6/7 report it as *deferred manual verification* (T-07); claiming it as executed is a defect. The harness exercises the **install-log block through EOF** plus the extracted `t()` and `install_report()`, i.e. exactly the regions this task changes. It lives at `/home/alan/Programs/singbox-cli/test/step7/run.sh` (extended from the rev.-1 harness, already green — `04_DEVELOPMENT.md:148-190`) and is **uncommitted by construction** (`.gitignore:19`), so AC-10 holds. This section is its spec of record.

### 10.2 Mechanics

Extract four fragments from the real file (no copy-paste), then rewrite only the absolute `sc` path
(`sed -i "s#/usr/local/bin/sc#$STUB/sc#g" "$T/tail.sh"` — PATH cannot intercept an absolute path):

```bash
SRC=/home/alan/Programs/singbox-cli/install.sh
sed -n '/^INSTALL_LOG=/,/^PHASE_SERVICE=/p'   "$SRC" > "$T/status.sh"
sed -n '/^t() {$/,/^}$/p'                     "$SRC" > "$T/t.sh"
sed -n '/^install_report() {$/,/^}$/p'        "$SRC" > "$T/report.sh"
awk '/^# -+ install log -+$/{f=1} f'          "$SRC" > "$T/tail.sh"
```

Pre-assertions (fail loudly): every fragment non-empty and `bash -n`-clean; `tail.sh`'s last line is `exit 0`; `status.sh` contains both `INSTALL_LOG=` and `LOG_SINK=`; `$SRC` still contains both literals named in R7. **Stub** (as built): one pure-builtin script (`#!/bin/bash`, `self="${0##*/}"`, no external command, so the strict-PATH scenario stays valid), symlinked as `systemctl`, `sc`, `rc-update`, `rc-service`, appending `"$self $*"` to `$CALL_LOG` and dispatching on `$self`/`$1`; **silent on stdout and stderr for every command that succeeds** (§10.2.3 depends on this). Knobs: `sc update-rules` prints a distinctive cause on **stdout** and an aggregate on **stderr** then exits `$STUB_SC_RULES_RC`; `sc reload` prints on stderr and exits `$STUB_SC_RELOAD_RC`.

**Driver** (`/bin/bash "$T/driver.sh"` — the scenario PATH may lack a shell): `set -euo pipefail` as in `install.sh:9`; `LANG_CHOICE="${LANG_CHOICE:-en}"`; source `status.sh`, override `INSTALL_LOG="$LOG_PATH"` (AC-15/19/20) and **nothing else — `LOG_SINK` must be left at its `/dev/null` default**, because the probe inside `tail.sh` is what derives it and that derivation is exactly what S11 exercises. Then source `t.sh` and `report.sh`, install the AC-6 probe — `eval "real_install_report() $(declare -f install_report | tail -n +2)"` plus a wrapper printing `PHASES $PHASE_RULESETS $PHASE_CONFIG $PHASE_SERVICE` **to stderr** with no `:-` defaults (a genuine `set -u` probe) before calling `real_install_report` — then source `tail.sh`, which ends in `exit`, so the driver's status **is** the installer's derived status (AC-14). Per-scenario env: `PATH="$STUB:/usr/bin:/bin"`, `T_DIR`, `INIT_SYS`, `LOG_PATH`, `CALL_LOG`, `STUB_*_RC`; stdout, stderr and `$?` captured separately.

### 10.2.1 Scenarios — each runs twice, `LANG_CHOICE=en` and `zh` (AC-16)

| ID | Setup | Assertions | Criteria |
|---|---|---|---|
| S1 | systemd; rules 0, reload 0, start 0 | ordered log: both `enable` < `sc reload` < `start sing-box`; `PHASES ok ok started`; exit **0**; no failure text; stdout **byte-identical** to the §10.2.3 baseline; `stat -c %a "$LOG_PATH"` = `640` | AC-5, AC-6, AC-14, AC-20, B-9, BC-1 |
| S2 | systemd; reload ≠0 — repeated with the `sc` symlink deleted (127) | both `enable` present; **zero** `^systemctl start `; output has `fail_banner`, `fail_config`, `sc update-rules`, `sc reload`, `systemctl status sing-box`, `$LOG_PATH`; **no** `done_banner` text; `PHASES … failed not-started`; exit **1** | AC-3, AC-4, AC-13, AC-14, BC-2, BC-3 |
| S4 | systemd; `enable` ≠0, reload 0 | **both** `enable` lines present; reload and starts still run; exit 0 | BC-4, B-3 |
| S5 | systemd; reload 0, `start sing-box` ≠0 | `PHASES … ok not-started`; `fail_service` text (not `fail_config`); exit **1** | BC-5, B-15 |
| S6 | openrc; all 0 — repeated with `PATH="$STUB"` only and the `systemctl` stub deleted | `rc-update add sing-box default` + `rc-service sing-box start`; **zero** `systemctl` lines (stub tripwire); **zero** `sing-box-rules-update` tokens; exit 0; stderr free of `command not found` | AC-7, B-7, BC-6 |
| S7 | openrc; reload ≠0 | `rc-update add` present; **zero** `rc-service … start`; banner names **`rc-service sing-box status`**, never `systemctl` | AC-7, B-7, B-16 |
| S9 | rules ≠0, reload 0, start 0 | `step6_warn` printed, contains `$LOG_PATH`, no "网络问题"/"network issue", no `/dev/null`; the stdout cause is **in the log** and **not** on the terminal; **success** banner; exit **0** | AC-15, AC-18, BC-15, Q3(a) |
| S10 | rules ≠0, reload ≠0 (the reported real case) | failure banner **plus** the `fail_rulesets` line; log holds both causes; both `enable` present; exit 1 | BC-14, B-4 |
| S11 | **S1, S2 and S10 re-run with `LOG_PATH` inside a `chmod 500` dir** (the probe fails, `LOG_SINK` stays `/dev/null`) | All three: same `PHASES` and same exit status as the writable twin; stderr free of `Permission denied` / `cannot create`; **stdout contains no `/dev/null` token**; `$LOG_PATH` still absent from disk. Per case — **S1**: stdout **byte-identical** to its writable twin (the success path names no log at all). **S2**: stdout equals the twin's with the one `fail_log` line replaced by `fail_nolog`, which contains `$LOG_PATH`. **S10**: likewise, and its step-6 line is `step6_nolog` containing `$LOG_PATH` where the twin printed `step6_warn` | AC-19, B-17, B-15(iii), G-1 |
| S13 | every scenario run twice into the same log | identical exit status and normalized call log; run 1's lines still present; **two** run markers | AC-8, BC-18 |
| S14 | static, no driver | the sorted zh and en key lists are identical, each has **40** entries, and both contain the 11 new keys (including `fail_nolog`, `step6_nolog`) | AC-17, B-10 |

Every run also asserts that stderr contains no `unbound variable` and that each new message renders
non-empty in the active language. (ID gaps are deliberate: the merged cases S3/S8/S12 are the "repeated
with …" clauses of S2/S6/S1; likewise D-5/D-7 are merged into D-4/D-3 in §14.) **S11 is now satisfiable as
literally written** — the degraded run no longer prints a different *path* from its twin, only a different
*sentence about that path*, and the row names the one line that differs; gate condition **C-3 can be
retired**, and no log-path token normalization is needed.

### 10.2.2 Static-only criteria

| Criterion | Method |
|---|---|
| AC-1, AC-2 | `bash -n install.sh`; `bash .harness/scripts/verify_all.sh` → **`FAIL: 0`** (it exits 1 whenever `warns > 0`; this rev. 3 document is still under the F.6 500-line cap, gate C-9) |
| AC-10 | `git diff` review: only `install.sh` + the one amended `CHANGELOG.md` bullet; `git diff -- bin/sc uninstall.sh systemd/ .harness/` empty; timeouts unmoved |
| AC-13 (literal path) | `grep -qF 'INSTALL_LOG="/var/log/sing-box/install.log"' install.sh` — the harness overrides the path, so the shipped literal is asserted statically |
| G-1 (the two jobs stay separate) | `grep -n 't step6_warn\|t step6_nolog\|t fail_log\|t fail_nolog' install.sh` — every call passes `"$INSTALL_LOG"`; `grep -n 'LOG_SINK' install.sh` shows it **only** as the §4.A declaration/comment, the §4.E probe assignment, a redirection target, or the left side of `[ "$LOG_SINK" = "$INSTALL_LOG" ]` — **never as an argument to `t`**; `grep -c '^INSTALL_LOG=' install.sh` = **1** (it is never reassigned) |
| AC-9 | **Not executable here.** Report as unverified / deferred to T-07. |

### 10.2.3 How QA builds the S1 byte-identity baseline (fixes gate G-3, retires C-4)

The banner moves into a function, so file-level `cmp` can no longer prove "success output unchanged"; S1's
stdout diff is the load-bearing check and its baseline must be built, not assumed. The §10.2 recipes do
**not** apply to `HEAD:install.sh` (it has no `install log` marker and no `install_report`), so:

```bash
B="$T/base"; mkdir -p "$B"
git -C /home/alan/Programs/singbox-cli show HEAD:install.sh > "$B/install.sh"
grep -qF 'install_report'             "$B/install.sh" && exit 1   # rev. 2/3 must NOT be committed yet
grep -qE '^# -+ install log -+$'      "$B/install.sh" && exit 1   # ditto
grep -qE '^# -+ step 6: rulesets -+$' "$B/install.sh" || exit 1   # the baseline really is the installer
sed -n '/^t() {$/,/^}$/p'                 "$B/install.sh" > "$B/t.sh"
awk '/^# -+ step 6: rulesets -+$/{f=1} f' "$B/install.sh" > "$B/tail.sh"
sed -i "s#/usr/local/bin/sc#$STUB/sc#g" "$B/tail.sh"
```

Baseline driver: `set -euo pipefail`; the same `LANG_CHOICE`, `INIT_SYS=systemd`, `PATH` and `STUB_*_RC=0` as S1; source `t.sh`, then `tail.sh`. It needs no `status.sh` (the baseline's only status variable, `INSTALL_OK`, is assigned inside its own tail) and no `LOG_PATH` (it redirects to a literal `/dev/null`); its tail ends at `t note_initial` with no `exit`, so it exits 0. **Precondition**: the stub is silent for every command that succeeds (§10.2), otherwise the baseline would capture the unredirected `systemctl start` chatter that this design sends to the sink. AC-5 passes iff `diff` of the two captured stdouts is empty in **both** languages. The recipe is HEAD-shape-agnostic — it works whether or not rev. 1 is committed — and `06_TEST_REPORT.md` records the resolved `HEAD` sha it ran against.

### 10.3 Coverage limits — restate verbatim in `06_TEST_REPORT.md`

1. Only the install-log block → EOF, plus `t()` and `install_report()`, are executed; pre-flight and steps 1-5 are not exercised.
2. `/usr/local/bin/sc` and `INSTALL_LOG` are rewritten/overridden (shipped literals covered statically only; `LOG_SINK` is still derived by the real probe), and the `sc` stub does not emulate `sc`'s internal `systemctl restart` (`bin/sc:560-571`).
3. No real init system runs: `systemctl enable`/`start` semantics (symlinks, masked units, `Type=simple` start-vs-alive, container buses) are **not** verified — only that the calls are issued, in order, tolerated and recorded. R1 is therefore untested.
4. B-8 is proxied at region granularity (S13); whole-installer idempotency is not run. AC-19/S11 rely on `chmod 500` denying the *non-root* harness user, so they do not model a root install on a read-only mount, and **AC-9 is not executed. Full stop.**

## 11. Migration / rollout plan

- **Backwards compatibility**: no on-disk format, config schema or CLI change; on a healthy host the only differences are the two `enable` calls moving before `sc reload` and a new append-only log. **The exit-status change is intentional and is the contract** (§5): wrappers that today treat any completion as success will see `1` on genuinely failed installs — the point of the task, and a restoration of `main`'s pre-rev.-1 behavior.
- **Existing installations**: re-running the one-liner is the documented upgrade path (`.harness/rules/50-singbox-cli.md`) and repairs a host left un-enabled by the reported failure; no migration script, no data migration. `install.log` sits inside the directory `uninstall.sh:137` removes.
- **No feature flag, deliberately** — `install.sh` is served over `curl | bash` from raw `main`, so the rollout unit is the git commit. **Rollback**: `git revert`; the next `curl | bash` serves the old file, and there is no state to unwind (enabled units are the desired end state, removed by `uninstall.sh:114-115,122-123`). With T-04 absorbed the rev.-1 two-push "silent-failure window" no longer exists. This dispatch instructs *not* to commit or push.

## 12. Out-of-scope clarifications

The developer must **not** implement: (1) any change to `bin/sc` — config degradation and ruleset mirrors/validation/retry are **T-02**, and `bin/sc` must stay byte-identical to `main`; (2) any timeout constant (`bin/sc:583`=3, `:742`=8, `:812`=30); (3) step 4 units, step 5 sudoers, the binary install/version logic, the pre-flight blocks, or the `t step7` progress text (rewording it breaks AC-5); (4) a `t()` safety net (`local fmt=""`) — Q4(a) keeps the loud failure; (4b) any reassignment of `INSTALL_LOG`, any third `LOG_SAVED`-style flag, any predicate function wrapping the `[ "$LOG_SINK" = "$INSTALL_LOG" ]` test, any re-probe of writability, or a `/dev/null` literal anywhere in user-facing text (§3.1.1); (5) an OpenRC rules-update schedule, a liveness probe (R1 → **T-05**), any persisted health state for `sc doctor` (**T-05**), or log rotation/retention (§4.8); (6) any `uninstall.sh` change; (7) anything wired into `verify_all.sh`, including the key-parity check, or committing the harness (**T-07**, §14 D-6); (8) fixing `systemd/sing-box-rules-update.service:7`'s stale `/usr/local/bin/proxy` `ExecStart` — pre-existing (203/EXEC), not made worse here, and the reason B-16 may not promise self-repair; recommend a separate `T-08 rules-update-unit-execstart` row.

## 13. Partition assignment

**Not applicable** — `.harness/agents/` does not exist and `.harness/rules/50-singbox-cli.md` §Partitioning
states this project runs **single developer**: everything below goes to `harness-kit:developer`, one pass,
no parallelism and no inter-partition ordering.

| File | Partition | New / Edit | Dependency |
|---|---|---|---|
| `/home/alan/Programs/singbox-cli/install.sh` | `harness-kit:developer` | edit (regions §4.A-H) | — |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | `harness-kit:developer` | edit (amend bullet 8) | — |
| `/home/alan/Programs/singbox-cli/test/step7/run.sh` | same agent, QA-scoped, uncommitted | edit (extend the rev.-1 harness) | after `install.sh` |

## 14. Deferred items (deferred-human mode — recorded, not asked)

| # | Item | Proceeding assumption |
|---|---|---|
| D-1 | Q1 — CHANGELOG shape | (a) one combined bullet; the rev.-1 bullet at `CHANGELOG.md:8` is **amended in place** (§4.I), not duplicated. |
| D-2 | Q2 — which streams are captured | (a), architect-confirmed: **stdout+stderr** everywhere, because for step 6 the cause is on stdout (`bin/sc:817`). The literal "stderr only" instruction would have logged the count and lost the cause. |
| D-3 | Q3 / Q6 | Q3 (a): a ruleset failure alone is **not** an install failure — `PHASE_RULESETS` never enters the success test, it only adds the `fail_rulesets` hint to a run that failed anyway (S9 asserts success + exit 0). Q6 (a): one failure value, `1`. |
| D-4 | Rev.-1 D-4 / gate C-5 — "do not hoist the status variable"; rev.-1 D-5 — redirection asymmetry | **Both reversed in rev. 2 and confirmed retired by gate rev. 2 §2.2.** All three `PHASE_*` plus `INSTALL_LOG`/`LOG_SINK` live in the constant block, so every read — including from a trap or a future early-exit path — is `set -u`-safe with a pessimistic default. Not reopened here. |
| D-6 | Q5 — wire the `t()` key-parity check into `verify_all` B.2 | **(b): not in T-01.** (i) AC-10 confines the diff to `install.sh` + `CHANGELOG.md`, and the architect cannot amend an acceptance criterion; (ii) B.2 is labelled "Tests pass" — filling it with a single parity assertion makes the gate claim more than it verifies, the same overclaim this task removes (parity is a lint, i.e. B.3); (iii) the rev.-1 gate already routed promotion to T-07, which inherits a proven path (`04_DEVELOPMENT.md:262-268`). **PM recommendation**: one T-07 row covering *both* the parity check and the scenario harness. Meanwhile AC-17 is covered by S14 plus diff review. |
| D-8 | Exact wording of the 11 new strings and the CHANGELOG bullet; whether the failure block should also say autostart *is* registered, or print to stderr | §4.C / §4.I are authoritative — the developer may fix a typo, not change scope, key names, or the three remediation commands. Neither addition is made: B-16 forbids text implying self-healing and the short form is least likely to read as "it fixes itself at boot", and stdout matches every other `t()` call. Both reversible. |
| **D-9** | **Gate H-1 / G-1**: what the installer says when the log could not be written — which path to name, and whether to claim the error was recorded there | **Resolved at the design level; no requirement change needed, and stated plainly rather than assumed silently.** Always name `$INSTALL_LOG` (that is what B-14 and B-15(iii) literally require) and say truthfully whether *this run's* diagnostics reached it (`fail_log`/`fail_nolog`, `step6_warn`/`step6_nolog`). B-17's "still prints the correct banner per B-15" is read as *the banner keeps B-15's structure and stays true*, not *it repeats a sentence that has become false* — a false sentence is precisely the defect class this task exists to remove. The alternative the owner may still prefer — print "written to %s" unconditionally — is a **requirement** decision (`01` B-15) and would be a two-key deletion here. Reversible; nothing outside §4.C/D/F depends on it. |

## Verdict

**READY.** §4 gives the exact final text of all eight `install.sh` regions plus the CHANGELOG line; §3 fixes
the phase-status model and the log-path split with explicit `set -e`/`set -u`/subshell/`pipefail` reasoning;
§6 fixes the log-capture mechanism and proves it cannot become fatal; §10 covers AC-3…AC-8 and AC-13…AC-20
in both languages, AC-9 honestly excepted. No requirement is contradicted.

**Rev. 3 disposition of the gate's conditions**: **G-1 fixed at the mechanism level** (§3.1.1) — no path
prints `/dev/null` to the user, so **C-2 has nothing left to record**; **C-3 retired** — S11 is now
satisfiable verbatim and asserts the honest behavior; **C-4 retired** — §10.2.3 gives the baseline recipe;
**G-5 fixed** (§4.E layout); **C-9 held** (this document is under 500 lines). C-1, C-5, C-6, C-7 and C-8 are
unaffected and still bind, with C-1's key total now **40/40** and C-5 extended by §12(4b).
