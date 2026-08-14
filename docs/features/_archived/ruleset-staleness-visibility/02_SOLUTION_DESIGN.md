# 02 — Solution Design · T-19 `ruleset-staleness-visibility`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).
>
> Mode: **full** · Single-developer project (no `.harness/agents/dev-*.md`). Risk analysis, the
> reuse audit and every option comparison live in `02_RATIONALE.md` per the stage-doc schema;
> the freeze/control observations stage 6 needs are binding and are carried here, in
> `## Verification plan`.

## Architecture summary

1. **Half 1** adds one datum to the one rule-set reader — `os.fstat()` on the *same open file object*
   whose bytes already produced the digest and the byte count — and one renderer beside `_status_text()`;
   `sc status` gains one section that prints them. Nothing on the config path changes: `_status_view()`
   absorbs the widening exactly as its docstring promises.
2. **Half 2** gives `restart_service()` a return value and replaces `cmd_update_rules()`'s three
   independent endings (an aggregate `sys.exit`, an unconditional "config regenerated" claim, an
   unobserved restart) with one boolean determination that feeds both the outcome sentence and the
   single exit site. T-10's "exactly one apply per run" and its conditional restart are untouched.
3. The two halves share no code, no variable and no output line (Q-1); every other command, the
   generated `config.json`, `install.sh`, and every systemd/OpenRC file are unchanged.

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| E-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `import time` (line 15 block, stdlib, alphabetical): the only new import; nothing else in the file needs a wall clock. ≈ +1 | single-dev |
| E-2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `TRANSLATIONS["zh"]`: 7 new entries (I-7…I-13), placed in the existing thematic groups (`# status / output` for the six display keys, next to the other `Rule-sets updated: …` keys for the outcome key). ≈ +7 | single-dev |
| E-3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `ruleset_state()` (`:761-809`): 4-tuple, `mtime` from `os.fstat(fh.fileno()).st_mtime` inside the same `with`; all five return sites widened; DIGEST CONTRACT docstring extended to name `mtime` (I-1, K-1…K-4). ≈ +14 / −6, of which ~8 are docstring | single-dev |
| E-4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `ruleset_states()` (`:826-840`): 6-tuple; two lines. `ruleset_status()` (`:812-823`) unchanged — `[0]` still indexes the status. ≈ +2 / −2 | single-dev |
| E-5 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_status_view()` (`:843-849`) and `changed_usable_tags()` (`:876`, `:878`): destructuring widened by one ignored name each. Return shapes unchanged. ≈ +3 / −3 | single-dev |
| E-6 | `/home/alan/Programs/singbox-cli/bin/sc` | new (function) | `_age_text(mtime)` immediately after `_status_text()` (`:911`) — the one age renderer (I-2). ≈ +18, of which ~8 are docstring | single-dev |
| E-7 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_doctor_rulesets()` (`:2363`): destructuring widened by one ignored name. No new doctor row (out-of-scope 10 — T-20 owns it). ≈ +1 / −1 | single-dev |
| E-8 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `cmd_status()` (`:2230-2232`): the rule-set section, after the TUN block and **before** `if is_running():` (I-3, K-6, K-7). ≈ +4 | single-dev |
| E-9 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `restart_service()` (`:1962-1966`): returns a bool (I-4, K-8, K-9). `reload_or_restart()` (`:1969-1973`) is **not** edited. ≈ +8 / −4, of which ~5 are docstring | single-dev |
| E-10 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `cmd_update_rules()` tail (`:2791-2823`): one determination, four-branch outcome, one exit site (I-5, I-6, K-10…K-15). ≈ +14 / −8, of which ~5 are comment | single-dev |
| E-11 | `/home/alan/Programs/singbox-cli/README.md` | edit | line 245 one-line description of `sc status` gains the rule-set section. Exactly one line. | single-dev |
| E-12 | `/home/alan/Programs/singbox-cli/README.zh-CN.md` | edit | line 245, its line-for-line mirror. Exactly one line. | single-dev |
| E-13 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | one entry at the top of `### 新增` under `## [Unreleased]`, in Chinese (the file's single language), covering both halves (FR-10). | single-dev |
| E-14 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit — **pending PM ruling** | the "One file's on-disk facts" row states a 3-tuple and the "Per-file rule-set state" row states 5-tuples; both become false at E-3/E-4, and a new "Rule-set age" row is where T-20 will look for `_age_text()`. **AC-S3's file list does not admit this file** — see RS-1; the developer edits it only if the PM widens AC-S3, otherwise the residual travels. ≈ +1 / −2 | single-dev |
| E-15 | `/home/alan/Programs/singbox-cli/docs/features/ruleset-staleness-visibility/03_GATE_REVIEW.md` | new | stage 3 output. | single-dev |
| E-16 | `/home/alan/Programs/singbox-cli/docs/features/ruleset-staleness-visibility/04_DEVELOPMENT.md` | new | stage 4 output. | single-dev |
| E-17 | `/home/alan/Programs/singbox-cli/docs/features/ruleset-staleness-visibility/05_CODE_REVIEW.md` | new | stage 5 output. | single-dev |
| E-18 | `/home/alan/Programs/singbox-cli/docs/features/ruleset-staleness-visibility/06_TEST_REPORT.md` | new | stage 6 output; carries the fixture sources (never committed to the tree — out-of-scope 8). | single-dev |
| E-19 | `/home/alan/Programs/singbox-cli/docs/features/ruleset-staleness-visibility/07_DELIVERY.md` | new | stage 7 output. | single-dev |
| E-20 | *(schema gap, no file)* | — | This project's `.harness/rules/70-doc-size.md` defines no `## Stage-doc boundary rule`, so two units the PM's dispatch requires in the contract — `## Smaller alternative rejected` (rule 85) and `## Requirement coverage` (FR/BC/AC mapping) — fit no declared section shape. Recorded as a gap per the stage-2 contract; both are written below rather than invented into an existing shape. | single-dev |

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `bin/sc` `# Rule-sets` | `ruleset_state(path) -> (status, digest, size, mtime)` | `mtime` is `st_mtime` (float seconds) read by `os.fstat(fh.fileno())` on the **same open file object** the digest and the byte count came from, or `None`. The DIGEST CONTRACT extends verbatim: `mtime is None <=> size is None <=> digest is None <=> status in {"absent","unreadable"}`. `st_size` still appears nowhere. Never raises, never writes. |
| I-2 | `bin/sc` `# Rule-sets`, after `_status_text()` | `_age_text(mtime) -> str` | THE one age renderer. Takes one argument and no command-specific argument, so `sc status` today and `sc doctor` in T-20 call it unchanged. `None` ⇒ the word form (I-12), never a number. Otherwise `delta = max(0, int(time.time() - mtime))` rendered in exactly one coarse unit chosen by magnitude — `>= 86400` days, `>= 3600` hours, `>= 60` minutes, else seconds — with integer floor division. Must stay a function (LANG is assigned in `main()` after import; a module-level dict of rendered values would freeze English — `_status_text()`'s reason). Pure apart from the clock; never raises. |
| I-3 | `sc status` stdout | `=== Rule-sets ===` heading, then one line per entry of `ruleset_states()` in `RULESET_FILES` order: `"%-20s %s, %s" % (fname, _status_text(status), _age_text(mtime))` | Exactly one complete line per rule-set, printed unconditionally, outside `if is_running():`. No `\r`, no `flush=`, no intermediate state, no numeric duration when `mtime is None`. |
| I-4 | `bin/sc` `# Config generation` | `restart_service() -> bool` | `True` when the init system's restart command returned 0, `False` when it returned non-zero, `True` when neither `SYSTEMD` nor `OPENRC` is set (nothing was asked, so nothing reported failure — HEAD's behaviour on such a host is preserved; see RS-2). Still `check=False`; still the only place `sc` restarts the service. |
| I-5 | `cmd_update_rules()` run determination | `ok = not failed and regen_ok and restarted is not False` | The single truth about the run. `restarted` is tri-state: `None` = no restart was needed or attempted, `True` = the command returned 0, `False` = it returned non-zero. `regen_ok` is hoisted to function scope, initialised `True`, and is only ever assigned from `generate_config()`. Both the outcome sentence (I-6) and the process status read this one expression; there is no second failure record. |
| I-6 | `sc update-rules` run-level outcome line | closed set of **four**, exactly one printed per run, before the exit: (a) `not changed` ⇒ `"No rule-set changed — the sing-box service was not touched"`; (b) `restarted` ⇒ `"Rule-sets updated: {names} — sing-box restarted to load them"`; (c) `restarted is False` ⇒ I-13; (d) else ⇒ `"Rule-sets updated: {names} — the sing-box service was not touched"` | Branch order is (a),(b),(c),(d). Three of the four are byte-identical to T-10's set; (c) is the only extension, and it is the truthful variant FR-8 requires. `Done` is a trailer, not an outcome line, and is printed only when `ok`. |
| I-7 | `TRANSLATIONS["zh"]` | `"=== Rule-sets ==="` → `"=== 规则集 ==="` | |
| I-8 | `TRANSLATIONS["zh"]` | `"{n} seconds ago"` → `"{n} 秒前"` | |
| I-9 | `TRANSLATIONS["zh"]` | `"{n} minutes ago"` → `"{n} 分钟前"` | |
| I-10 | `TRANSLATIONS["zh"]` | `"{n} hours ago"` → `"{n} 小时前"` | |
| I-11 | `TRANSLATIONS["zh"]` | `"{n} days ago"` → `"{n} 天前"` | |
| I-12 | `TRANSLATIONS["zh"]` | `"last update unknown"` → `"更新时间未知"` | |
| I-13 | `TRANSLATIONS["zh"]` | `"Rule-sets updated: {names} — the sing-box service could not be restarted"` → `"规则集已更新：{names} —— sing-box 服务重启未成功"` | |

For I-7…I-13: the English sentence **is** the key (there is no `en` table), the zh value carries the same
placeholder set, the em dash matches the neighbouring keys (` — ` in English, ` —— ` in Chinese), and no
zh string contains `失败` in any form — `重启未成功` is deliberate, because `失败：` in `bin/sc` output is a
load-bearing diagnostic grep meaning "this file was not updated".

## Constraints

**K-1** — The implementer obtains the timestamp with `os.fstat(fh.fileno())` inside `ruleset_state()`'s
existing `with path.open("rb")` block, after the read loop; never with `path.stat()`, `os.stat()`,
`st_mtime` on a path, or any second `open()`.

**K-2** — The implementer reads only `st_mtime` from that result. `st_size` must not be introduced: the
read's own byte counter already answers "how many bytes", and a second answer is the defect T-05 removed.

**K-3** — The implementer keeps the `fstat` call inside the existing `try:` so that an `OSError` from it
yields `("unreadable", None, None, None)` — the DIGEST CONTRACT must never admit a state where `size` is
real and `mtime` is `None`, or the reverse.

**K-4** — The implementer extends `ruleset_state()`'s DIGEST CONTRACT docstring to name `mtime` in the
same equivalence chain, and states there that a readable empty file therefore carries a real `mtime`
(BC-3).

**K-5** — The implementer leaves `_status_view()`'s **return** shape at 3 elements, so
`generate_config()`, `usable_tags()`, `_warn_degraded()` and `ruleset_report()` need no edit and no
rule-set timestamp can reach the composed document.

**K-6** — The implementer places the `sc status` rule-set section after the `=== TUN interface ===`
block and before `if is_running():`, so it prints on a host whose service is stopped or unreachable.

**K-7** — The implementer adds no `flush=` to the new `print()` calls: every other `cmd_status()`
heading is block-buffered, and a selectively flushed section would change R-33's shape rather than
leave it alone (Q-12, out-of-scope 7).

**K-8** — The implementer does not change `reload_or_restart()`: it keeps ignoring
`restart_service()`'s return and keeps returning `True` iff `generate_config()` succeeded, which is what
leaves `sc reload` (`bin/sc:2927`), `sc use` (`:2158`), `sc add` (`:2180`), `sc rm` (`:2196`),
`sc ipv6` (`:2627`) and `sc telemetry` (`:2690`) — the complete set of callers, none of which calls
`restart_service()` directly — unaffected (out-of-scope 5).

**K-9** — The implementer keeps `subprocess.run(..., check=False)` in `restart_service()` and reads
`.returncode`; raising `CalledProcessError` into six existing callers is forbidden by K-8.

**K-10** — The implementer keeps the apply block's structure intact: one `generate_config()` call
guarded by `gained`, one `restart_service()` call guarded by `regen_ok and is_running()`, both inside the
single `if changed and CFG_PATH.exists():` — T-10's "exactly one apply per run" and its load-bearing
comment survive byte-for-byte, and T-02's recovery regeneration stays ahead of the exit.

**K-11** — The implementer prints `"Rule-sets restored: {names} — config regenerated"` only when
`generate_config()` returned `True` (FR-8, BC-9).

**K-12** — The implementer derives the process status from `ok` at exactly one `sys.exit(1)` site placed
after the outcome line and after the aggregate stderr line; no other `sys.exit` is added to
`cmd_update_rules()`.

**K-13** — The implementer replaces `sys.exit("\n" + t("{n} ruleset(s) failed to update", …))` with
`sys.stderr.write("\n" + t("{n} ruleset(s) failed to update", …) + "\n")` in the same position, so the
aggregate's stream, wording, leading newline and single-line shape stay byte-identical (BC-8 freeze).

**K-14** — The implementer prints `t("Done")` only when `ok`, and adds no other stdout line to the tail;
`Done` remains a trailer and is never counted as a run-level outcome line.

**K-15** — The implementer adds no envelope, `try/finally`, `atexit` hook or wrapper around
`cmd_update_rules()`, and prints no outcome line on a path that unwinds past its tail (Q-2, R-12
narrowed, BC-13).

**K-16** — The implementer adds no staleness threshold, no fresh/stale verdict, no age-derived warning,
no age-derived exit status and no age-derived class constant anywhere (Q-4, out-of-scope 1).

**K-17** — The implementer adds no `sc doctor` row and no second age derivation; T-20 consumes
`ruleset_states()`'s `mtime` and `_age_text()` exactly as `_doctor_rulesets()` already consumes `size`
and `_status_text()` (FR-2, out-of-scope 10).

**K-18** — Every stage after this one honours the safety floor: never write `/etc/sing-box/` or
`/var/lib/sing-box`, never drive `_init_files()` (it hard-codes `/var/lib/sing-box`), never invoke
`/usr/local/bin/sc` (`bin/sc`'s import-time auto-elevate re-execs the **installed** binary), never
start/stop/restart/reload the live service, never write a systemd unit or drop-in. `systemd-analyze
verify` is the only admissible static check of a unit and `systemctl show -p MainPID -p
ActiveEnterTimestamp` (never `is-active`) the only admissible restart witness.

**K-19** — Any fixture that sets `SYSTEMD = True` replaces the loaded module's `subprocess.run` binding
**before** calling any command, and that replacement never execs `systemctl`: `is_running()` shells out
to `systemctl is-active sing-box` against the **live** host, and a `True` from it would drive
`restart_service()` into `systemctl restart sing-box` on the developer's machine.

## Smaller alternative rejected

*(Rule 85 · `.harness/rules/85-design-discipline.md`. Named as E-20: no declared section shape holds it
on this project.)*

| half | the smaller design | what the extra code buys |
|---|---|---|
| 1 | **Do not widen the tuple.** `cmd_status()` calls `os.stat(RULES_DIR / fname).st_mtime` itself in the new loop, next to `ruleset_report()`. Saves E-3's return-site edits and all of E-4/E-5/E-7 — about 7 edited lines and one widened contract. | Six edited lines and one extended docstring buy the property this project spends its rule-set design on: the timestamp comes from the same open file object whose bytes decided the status, so `sc status` cannot report `absent` beside a real age, cannot report an age belonging to a file replaced between the read and the stat, and cannot hold a second opinion about `.srs` metadata. It also buys T-20 for free — the row lands as one `_age_text(mtime)` call inside `_doctor_rulesets()`'s existing loop instead of a second stat site. FR-1 and AC-S1 make it binding besides. |
| 1 | **Reuse `sc doctor`'s S2 rows** — call `_doctor_rulesets()` from `cmd_status()` and print its rows. Zero new renderer, zero new heading key. | Rejected as *larger*, not smaller: it drags `DOCTOR_OK`/`DOCTOR_PROBLEM` and `_doctor_print()`'s column contract into `sc status` and gives a facts screen a verdict vocabulary that Q-4 forbids. `_age_text()` beside `_status_text()` is the seam that already exists. |
| 1 | **A four-key unit ladder is data, not machinery** — the alternative (one `"{n} {unit} ago"` key plus four unit words) needs the same five entries, adds a composition step, and renders a stray space in Chinese. The ladder lives as a 3-row local tuple inside `_age_text()`; no module-level name is added. | — |
| 2 | **Fix only the regeneration claim**: move the "config regenerated" print inside `if regen_ok:` and add `regen_ok` to the exit condition. About 4 lines, no `restart_service()` change, no new key. | E-9's 4 code lines plus one translation key buy BC-10 / AC-B6 — the failed restart, which Q-6 calls the loudest lie the run can tell, and which T-10's own R5 filed as a pool-row candidate ("widening `restart_service()`'s contract … flagged to PM"). FR-7 names the service-affecting action explicitly, so the smaller design does not satisfy the requirement. |
| 2 | **One boolean expression, not a failure record.** The larger design considered was a `failures = []` list (or an exception envelope) accumulating causes and deciding the status from its length. | Rejected: `failed`, `regen_ok` and `restarted` already exist in that scope, so `ok = not failed and regen_ok and restarted is not False` is one line over data the run already holds — a list would be a second place the run's success is recorded, i.e. exactly the disagreement FR-6 exists to prevent. The envelope form is additionally forbidden by Q-2. |
| 2 | **Tri-state `restarted` instead of a second `restart_failed` flag.** | It costs one comment line and saves one variable and one branch; `elif restarted:` in the outcome chain keeps working unchanged because both `None` and `False` are falsy. |

## Frozen set

| path | why frozen |
|---|---|
| `bin/sc` `generate_config()` (`:1871-1960`) | FR-5: the config path must not see a timestamp. It consumes `ruleset_report()` (3-tuples) and is unchanged; T-15's differential pins its emitted bytes. |
| `bin/sc` `_status_view()`'s return shape, `usable_tags()`, `_warn_degraded()`, `_filter_rules()`, `ruleset_report()`, `srs_reject_reason()` | The shield the widening stops at (dev-map). Editing any of them means the widening leaked. |
| `bin/sc` `reload_or_restart()` (`:1969-1973`) | Out-of-scope 5: the six other restart callers reach the service only through it. |
| `bin/sc` `CONFIG_BASE`, `_runtime_overlay()`, `_dns_overlay()`, `_telemetry_overlay()`, `_compose()`, `_merge()` | Not on this task's path; T-15/T-17 differentials pin them. |
| `bin/sc` `_fetch_to_temp()`, `_temp_path()`, `_clear_stale_temps()`, `_ruleset_bases()`, and the per-file `↓ … OK ({size} bytes)` / `failed: {e}` lines | FR-9 / BC-8 / BC-14 freezes: the per-file output contract and the concurrency story are unchanged. |
| `bin/sc` the five `ls.*` keys | Out-of-scope 9 (R-19). |
| `bin/sc` `cmd_status()`'s existing sections and their order | Out-of-scope 7 (R-33, R-34). Only an insertion is permitted. |
| `install.sh` (step 6 included), `uninstall.sh` | Out-of-scope 4 / Q-9. |
| `systemd/sing-box-rules-update.service`, `systemd/sing-box-rules-update.timer`, `systemd/sing-box.service`, the OpenRC periodic script and the code that writes it | Out-of-scope 2 / Q-3 / Q-7: a non-zero exit is already recorded as a failed unit. |
| `.harness/scripts/*`, `.harness/scripts/baseline.json` | Out-of-scope 8 (R-9): no new `verify_all` step. |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | E-1, E-3, E-4, E-5, E-7 | none — this is the widening, and it is behaviour-neutral on its own: no caller reads the new element yet. `verify_all` B.1 must pass after it. | revert the five hunks; nothing else depends on them. |
| 2 | E-2 (I-7…I-12), E-6 | order 1 landed (`_age_text()` has nothing to render before it). | revert; `_status_text()` is untouched. |
| 3 | E-8 | order 2 landed. First user-visible change (AC-B1…AC-B3 become observable here). | revert the 4-line insertion; half 1 disappears with no residue, and half 2 is unaffected (Q-1). |
| 4 | E-9 | none — independent of orders 1-3. `reload_or_restart()` ignores the new return, so no caller's behaviour changes at this point. | revert; the six other callers were never touched. |
| 5 | E-2 (I-13), E-10 | order 4 landed. Second user-visible change (AC-B5, AC-B6, AC-B8 become observable here). | revert orders 4+5 together; half 1 is unaffected (Q-1). |
| 6 | E-11, E-12, E-13, (E-14 if admitted) | orders 3 and 5 landed — the docs describe shipped behaviour, in the same commit (FR-10). | revert with the code. |

No data migration, no on-disk format change, no new file, no setting, no flag: `settings.json`,
`nodes.json`, `config.json` and `rules/*.srs` are untouched by both halves, so an upgrade needs no
`sc reload` and a downgrade needs no repair. Backwards compatibility for consumers of
`sc update-rules`' exit status is stated in Q-9/Q-10: status `1` for every failure class, `install.sh`
step 6 re-labels a non-download cause as its ruleset warning (accepted, filed as RS-3), and BC-11's
zero-status path is unchanged.

## Out of scope

- Everything in `01_REQUIREMENT_ANALYSIS.md` `## Out of scope` items 1-11, unchanged and restated by
  K-15, K-16, K-17, K-8, K-7 and the frozen set.
- Whether the timer has ever fired on this host, and how often (P-7: no requirement rests on it).
- The `capture_output=` Python-3.6 floor violations at three existing sites (its own pool row).
- `sc status`'s buffering (R-33) and its "one value line per heading" promise (R-34).
- Any change to what a rule-set *is*, to `SRS_MIN_BYTES`, to the mirror list, or to the download path.

## Verification plan

Every `[B]` step runs in a redirected fixture built with `docs/dev-map.md`'s module-load recipe: the
`os.geteuid` shim, all **eight** path constants repointed into a `mkdtemp()` root **with an assertion
that each resolves inside it**, `sc.SB_BIN` a stub script, `sc.LANG` set explicitly, and the fixture's
own `settings.json` carrying `clash_api_port` (the `LANG` / `CLASH_PORT` vacuity traps — `main()`
assigns both after import, so **no step drives `main()`**; each calls `sc.cmd_status(...)` /
`sc.cmd_update_rules(...)` directly). `_init_files()` is never driven. `/usr/local/bin/sc` is never
invoked. K-18 and K-19 bind every step.

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | `cmd_status()` with `SYSTEMD = OPENRC = False`, stdout to a pipe, four fixture `.srs`: two usable (one written now, one `os.utime`'d to now − 30 d), one absent, one a directory. | `=== Rule-sets ===` then 4 lines in `RULESET_FILES` order; the aged file reads `≥ 29 days ago`, the fresh one a seconds-or-minutes duration under 60 s. | AC-B1 |
| V-2 | Same capture, per-line assertions on the absent and the directory entries. | Both read `last update unknown` (zh: `更新时间未知`); neither line contains a digit outside the filename. | AC-B2 |
| V-3 | Same capture with nothing listening on the fixture's `clash_api_port`. | All four rule-set lines present and complete; the `=== Current node ===` … `=== Egress IP ===` block absent. | AC-B3, BC-6 |
| V-4 | Same fixture with `RULES_DIR` deleted; assert the directory does not exist after the run. | Four lines, each `missing, last update unknown`; nothing created. **Observed at `cmd_status()`, not `main()`** — `_init_files()` creates `RULES_DIR` on the shipped path and is HEAD behaviour this task does not change. | BC-5 |
| V-5 | One `.srs` `os.utime`'d to now + 1 h (clock skew). | `0 seconds ago` (zh `0 秒前`); no `-`, no warning, exit unchanged. | BC-4 |
| V-6 | Two `generate_config()` runs at the **same** fixture path (`RULES_DIR` is emitted verbatim into `route.rule_set[].path`), identical rule-set bytes, timestamps current then 30 d old; byte-compare `config.json`. | Identical bytes; `route.rule_set` identical; no rule-set dropped between the two. | AC-B4, FR-5 |
| V-7 | A readable 0-byte `.srs`: direct `ruleset_state()` call. | `("too-small", <sha256 of b"">, 0, <real float>)`; `sc status` shows a real duration on that line. | BC-3 |
| V-8 | Child process: existing `config.json`, `file://` mirror serving a valid `.srs` that makes one tag *gained*, `SYSTEMD = True`, `subprocess.run` replaced with a logging stub returning 0 for `["systemctl","is-active",…]` and non-zero for `[SB_BIN,"check",…]`. Read the child's exit status. | Exit **1**; stub log contains **no** `systemctl restart`; stdout carries no `config regenerated` claim; the outcome line is `… the sing-box service was not touched`. **HEAD control at the same fixture exits 0** (P-3). | AC-B5, BC-9 |
| V-9 | Child process as V-8 but `check` returns 0 and `["systemctl","restart",…]` returns non-zero. | Exit **1**; outcome line is I-13's; stub log shows exactly one `systemctl restart`. **HEAD control exits 0 and prints `… sing-box restarted to load them`** (P-4). | AC-B6, BC-10 |
| V-10 | Freeze A: child run with `--mirror` at an unreachable base. | Exit non-zero; per-file `failed: …` causes on stdout; exactly one `{n} ruleset(s) failed to update` on stderr, preceded by a blank line; one outcome line. **Control agrees at HEAD by design — a freeze, never quoted as evidence of a change** (P-2). | AC-B7, BC-8 |
| V-11 | Freeze B: child run with a `file://` mirror serving byte-identical content. | Exit **0**; outcome line `No rule-set changed — the sing-box service was not touched`; `Done` printed; stub log empty of `systemctl`. **Control agrees at HEAD.** | AC-B7, BC-11 |
| V-12 | Across V-8…V-11, count outcome lines and cross-check each claim against the stub call log; repeat every run with `sc.LANG = "en"` and `"zh"`. | Exactly one line from I-6's closed set per run in every state; every claim true of that run; `Done` never counted as one. | AC-B8 |
| V-13 | Fresh install: no `config.json`, one rule-set gains. | No `generate_config()` call, no service action, exit governed only by download outcomes. | BC-12 |
| V-14 | R-12's two unwind paths (a helper `sys.exit`, an `OverrideError` from `generate_config()`). | Process exits non-zero, cause on stderr, no service-affecting action, **no** outcome line — recorded as R-12's open row, never as a T-19 defect. | BC-13 |
| V-15 | Static sweep of `bin/sc` for `st_mtime` / `os.stat` / `path.stat` / `getmtime`, and for `_age_text` call sites; read `_age_text`'s signature. | Exactly one timestamp query, inside `ruleset_state()`; exactly one age renderer; its signature is `(mtime)`. | AC-S1 |
| V-16 | Table read of the 7 new keys; byte scan of every captured stream from V-1…V-14 for `\r`; grep every added zh string for `失败`. | Both languages present, placeholder sets equal, no `\r`, no `失败`. Note: `check-i18n-parity.sh` (B.2) covers `install.sh` only and cannot see these keys — the table read is the proof. | AC-S2, BC-7 |
| V-17 | `git diff --name-only`; `.harness/scripts/verify_all.sh` before and after; review of every command run in stages 4-6. | Diff limited to AC-S3's list (plus `docs/dev-map.md` only if the PM admits E-14); **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**; no write under `/etc/sing-box` or `/var/lib/sing-box`, no `/usr/local/bin/sc`, no live-service or unit touch. Added-line counts quoted from `--numstat`'s first field, never from `--stat`'s bar. | AC-S3 |
| V-18 | AC-B9: the shipped invocation on a systemd host, as root, observed read-only. | Not obtainable inside this pipeline (P-6, K-18). **Report BLOCKED with the reason; never substitute a unit-file read.** | AC-B9 |

## Requirement coverage

*(Second unit of the E-20 schema gap.)*

| id | where it is satisfied |
|---|---|
| FR-1 | I-1, K-1…K-3, E-3. |
| FR-2 | I-2, K-17, E-6. |
| FR-3 | I-3, K-6, E-8. |
| FR-4 | I-2 (`None` ⇒ I-12), I-12. |
| FR-5 | K-5 + frozen set (`generate_config()` consumes `ruleset_report()`, still 3-tuples); V-6. |
| FR-6 | I-5 — one expression, one exit site (K-12). |
| FR-7 | I-5's three terms: `failed` (download), `regen_ok` (regeneration + `sing-box check`, which `generate_config()` folds into its one bool), `restarted is not False` (service-affecting action). |
| FR-8 | K-11 (no false regeneration claim) + I-6 branch (c) (no false restart claim). |
| FR-9 | Frozen set (per-file lines, TTY gating, stderr aggregate) + K-13 + I-6 (four-member closed set, one per run) + K-14. |
| FR-10 | I-7…I-13 and the note under them; E-11, E-12, E-13. |
| BC-1, BC-2 | I-1 (`absent` / `unreadable` ⇒ `mtime is None`) + I-2's word form; V-2. |
| BC-3 | K-4; V-7. |
| BC-4 | I-2's `max(0, …)`; V-5. |
| BC-5 | I-1 + purity of `ruleset_states()`; V-4 and its `main()` caveat. |
| BC-6 | K-6; V-3. |
| BC-7 | I-3 (no `\r`, one complete line); V-16. |
| BC-8 | K-13 + frozen set; V-10. |
| BC-9 | K-11 + K-10 (restart gated on `regen_ok`) + I-5; V-8. |
| BC-10 | I-4 + I-6 branch (c) + I-5; V-9. |
| BC-11 | I-6 branch (a) + `ok` true in that state; V-11. |
| BC-12 | K-10 (the `CFG_PATH.exists()` guard is untouched); V-13. |
| BC-13 | K-15; V-14. |
| BC-14 | Frozen set (`_temp_path()` unchanged); the reported age is whichever run last replaced the file — a property of I-1, not of new code. |
| AC-B1…AC-B9, AC-S1…AC-S3 | V-1…V-18 as columned above. |

**Unverifiable as written:** **AC-B9** only — it needs root and the live unit, which K-18 forbids
every agent in this pipeline. It is reported BLOCKED with the reason (P-6), never substituted. No
other criterion is unverifiable, but two carry caveats stage 6 must state rather than paper over:
**AC-B7** is a freeze whose control agrees at HEAD by construction, so it can never be discriminating;
and **AC-B2**'s "no numeric duration" is asserted against the rendered line, whose filename contains no
digit today (`geoip-cn.srs` etc.) — if a future rule-set filename carries one, the assertion needs the
suffix after the status, not the whole line.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RS-1 | AC-S3's permitted-file list omits `docs/dev-map.md`, but E-3/E-4/E-6 falsify two of its "Reusable utilities" rows (`(status, digest, size)`, "5-tuples") and T-20 is the next task to read them. Recommended resolution: the PM widens AC-S3 by one filename. If it is not widened, the map ships stale and the correction must be filed as a pool row. | PM (before `03_GATE_REVIEW.md`); if declined, `07_DELIVERY.md` as a follow-up row |
| RS-2 | `restart_service()` returns `True` when neither `SYSTEMD` nor `OPENRC` is set, so on a host running sing-box under some other supervisor `sc update-rules` still says "restarted" without having restarted anything. HEAD behaviour, no requirement covers it, and making it `False` would introduce a non-zero exit in a state nobody asked about. | `07_DELIVERY.md` as a follow-up pool row |
| RS-3 | Q-9's accepted imprecision: `install.sh` step 6 will now report its ruleset-**download** warning for a regeneration or restart cause. | PM (already filed per Q-9); restated here so stage 5/6 do not re-raise it as a defect |
| RS-4 | `sc status` now performs four full `.srs` reads it did not perform before (they are the only honest source of the status the section prints). Bounded by `SRS_MIN_BYTES`-to-a-few-hundred-KB local reads, no network, no subprocess — but it is a real cost increase on the command, not a metadata-only one, and the NFR's "on local files already being read" is read as "the timestamp adds no read of its own". | `03_GATE_REVIEW.md` — the gate should confirm this reading of the NFR |
| RS-5 | `_age_text()` renders the largest unit only (`36 hours ago` ⇒ `1 days ago`) and pluralises like the existing `{n} ruleset(s)` keys, i.e. `1 days ago` is possible. Deliberate (one deterministic vocabulary, Q-11); a future task may add plural handling for every key at once. | `07_DELIVERY.md` as a follow-up pool row |
| RS-6 | One durable declined approach earns a `.harness/rejected-decisions.md` record that this stage may not write (its dispatch admits two files): **`ruleset-timestamp-outside-the-single-reader`** — declined; a rule-set's timestamp is read only by `ruleset_state()`, from the same open file object as its digest and byte count, never by a `path.stat()` at a display site. Why: a second query can describe a different file (replace-between-read-and-stat) and can pair a real age with an `absent` status, which is the "second opinion" defect T-02/T-05 spent this subsystem's design removing. Origin: T-19 `02_SOLUTION_DESIGN.md` I-1 / K-1 / `## Smaller alternative rejected` half 1. | PM, at task close (per `.harness/rules/25-decision-policy.md`) |

## Partition assignment

**Single-developer mode.** This project has no `.harness/agents/dev-*.md` partitions, so there is no
partition split and no dispatch order: one Developer implements E-1…E-14 in the `## Migration & edit
sequence` order. Every ledger row carries `single-dev` for that reason.

## Verdict

**READY.**
