# 03 — Gate Review — `sc doctor` (T-05)

> **Transcription note (PM).** The `gate-reviewer` agent is provisioned read-only
> (Read / Glob / Grep) by design, so it returned this document as text and the PM wrote it to
> disk **verbatim**. Content is the reviewer's; the PM authored none of it. The PM's routing
> decision on F-5/C-8 is recorded in `PM_LOG.md`, not here.

Mode: **full** · Stage 3 · Decision mode: **deferred-human (defer, do not ask)**.
Verified against `bin/sc` at HEAD `22502f9` (1537 lines), `01_` (READY), `02_` (READY FOR GATE REVIEW), `.harness/rules/85-design-discipline.md`, `.harness/rules/50-singbox-cli.md`, `.harness/rules/70-doc-size.md`, `docs/dev-map.md`, `.harness/insight-index.md`, `.harness/rejected-decisions.md`, `.harness/scripts/verify_all.sh`. Every anchor below was opened and read; none is taken from upstream on trust. I verify, I do not author; `01_` and `02_` are unedited.

## 1. Verdict

**APPROVED FOR DEVELOPMENT WITH CONDITIONS** (§6). No safety red line: the read-only guarantee is sound as designed, with one measured residual (RISK-1) whose contingency I rule acceptable.

## 2. Audit — the eight dimensions

| # | Dimension | Result | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **WARN** | All 26 ACs are inspectable or executable except AC-16, whose "byte-identical `sc status`" cannot hold between any two captures on the same host (F-3). |
| 2 | Design completeness | **WARN** | Every FR and BC maps to a named mechanism, but two edits (E-17; D-4's `_resolve_clash_port()` sketch) are not executable as literally written (F-1, F-2). |
| 3 | Reuse correctness | **PASS** | Every §11 reuse claim checked at source and holds: `ruleset_states()` `bin/sc:575-588`, `_status_view()` `:591-596`, `ruleset_report()` `:599-605`, `changed_usable_tags()` `:608-636`, `_status_text()` `:644-652`, `is_running()` `:959-965`, `clash_api()` `:945-956`, `SYSTEMD`/`OPENRC` `:35-36`, `SB_BIN`/`CFG_PATH`/`RULES_DIR` `:32`/`:19`/`:22`. |
| 4 | Risk coverage | **WARN** | R-1..R-10 are the real risks (R-3/R-8/R-9 unusually well aimed); three lower-order ones are missing — F-11, F-12, F-13. |
| 5 | Migration safety | **PASS** | No data migration; the one persistence path keeps its semantics under C-2; D-2's tuple widening is internal and provably non-regressing (Q2). |
| 6 | Boundary handling | **PASS** | BC-1..BC-18 each land on a named row and class, including the two easy to get backwards: BC-8's init-first short-circuit ahead of `is_running()`'s hard `False` (`bin/sc:965`), and BC-12's down-service-is-PROBLEM. |
| 7 | Test feasibility | **WARN** | AC-16/T-7 not executable as written (F-3); T-1 genuinely needs stage 6; AC-14's behavioural half needs a constructed fixture (it is constructible). |
| 8 | Out-of-scope clarity | **PASS** | §2 + §16 close scope at the permitted five files; nothing reaches `install.sh`, `uninstall.sh`, `systemd/` (Q12). |

## 3. Rulings on the twelve questions

### Q1 — AC-13's deletion test. **Satisfied in the stronger form; AC-13's illustrative clause is imprecise and is read as stage 2 reads it.**

Verified at source: `ruleset_report()` is literally `return _status_view(ruleset_states())` (`bin/sc:599-605`, return at `:605`). The design's claim is exact.

- AC-13's *criterion* says "through the existing per-rule-set **report/state** functions" — plural; `ruleset_states()` is one of them, so consuming it satisfies that sentence directly.
- AC-13's *deletion test* names "the rule-set report function". Read literally it fails: deleting only `ruleset_report()` breaks `generate_config()` (`bin/sc:823`) while S2 keeps working.
- Literal satisfaction is **impossible without violating FR-12**: `ruleset_report()` returns `(tag, filename, status)` and can carry no size; taking status from it and size from `ruleset_states()` is two reads per file (FR-12: "the same single read") and admits a self-contradicting report under BC-15. A functional requirement outranks an illustration inside an acceptance criterion.
- The property AC-13 protects is *stronger* under the design: deleting `ruleset_state()` or `ruleset_states()` breaks S2, `ruleset_report()`, `generate_config()` and both `cmd_update_rules` snapshots at once. No independent path survives.

Binding (C-6): QA executes the deletion test against `ruleset_states()`/`ruleset_state()` and records the reading plus the FR-12 conflict. A reading, not an amendment.

### Q2 — D-2 vs T-10. **No regression; the widening is provably contained.**

- **Pairing is by tag, never index.** `old = dict((tag, digest) for tag, _fname, _status, digest in before)` (`:623`), lookup `old.get(tag)` (`:628`). Widening `:623`/`:625` by one `_size` name touches neither the dict, the lookup, nor the `None` reasoning at `:634`.
- **"Exactly one apply per run" is structural and unedited:** `if changed and CFG_PATH.exists():` (`:1230`), single `restart_service()` (`:1243`), single run-level statement (`:1247-1254`). `cmd_update_rules` (`:1173-1257`) needs no edit — `before`/`after` (`:1177`, `:1222`) flow only into `changed_usable_tags()` (`:1224`) and `_status_view()` (`:1223`).
- **The five "no edit at all" claims are true.** `usable_tags()` (`:639-641`) is called at `:824` with `ruleset_report()`'s 3-tuples and at `:1223` with `_status_view()`'s 3-tuples — both unchanged because `_status_view()`'s *output* shape is unchanged. `_warn_degraded()` (`:686-702`, unpack `:688`) is called only at `:916` with the same `report`. `generate_config()` destructures 3-tuples at `:899`. `ruleset_status()` (`:572`) projects `[0]` and stays correct.
- **The extended contract is exact.** Early returns are `:543` (both ternary arms), `:545`, `:557` — all `(status, None)` → `(status, None, None)`; the only other return, `:558`, carries a real digest and a real size. So `size is None ⇔ digest is None ⇔ no complete read ⇔ status ∈ {absent, unreadable}` with no gap, and the partial `size` accumulated at `:552` before an `OSError` is correctly discarded (a partial size is a content claim about bytes never fully read — the defect the contract at `:523-533` exists to prevent). A readable empty file yields `("too-small", <digest>, 0)` because `0 < SRS_MIN_BYTES` (`:509`, `:56`).

T-9 is the right executed guard and is retained.

### Q3 — D-3. **Substance correct, failure direction safe; the edit instruction is wrong as written (F-1).**

- **The four protections hold.** (1) `if args.cmd == "doctor": … else: <today's three statements>` — every existing and future subcommand lands in the `else` arm with no action by anyone; forgetting the mechanism yields "a new read-only command wrote files", never "an existing command lost initialisation". Correct direction. (2) The `else` arm is `:1501-1503` re-indented. (3) `_init_files` defined `:222`, called once; `_resolve_clash_port` defined `:191`, called once (F-6 corrects only the grep count). (4) T-6 is executed, not inspected.
- **The instruction is not executable.** E-17 says move `args = parser.parse_args()` (`:1522`) above `:1501`. It cannot go there — `parser`/`sub` are built at `:1504-1520`. The equivalent correct edit moves the three init statements **down**. Verified behaviour-preserving: `:1504-1520` contains no `t()` call and no `LANG`/`CLASH_PORT` read (parser built with `add_help=False`, no `help=`/`description=` strings). → C-1.
- **Observable behaviour of parsing earlier.** Argparse messages are English and `LANG`-independent, so no output changes. Usage errors (`sc badcmd`, `sc use` with no argument, `sc --help` — unrecognised under `add_help=False`) print the same text and still exit 2; the only difference is they no longer create `/etc/sing-box`, which is strictly more conservative and is stated. `sc` bare and `sc help` take the `else` arm (`args.cmd is None`). Sub-parser `--help` (auto-added by `add_parser`) still prints and exits 0.
- **Auto-elevate — checked, no interaction.** `os.execvp("sudo", …)` is at `bin/sc:78-79`, at **import** time, before `main()` is entered — before *both* the old and new parse position. The standing BC-17 consequence is unchanged: as non-root, `./bin/sc doctor` re-execs the **installed** `/usr/local/bin/sc`, which on a not-yet-upgraded host answers `invalid choice: 'doctor'`, exit 2. Not a design defect; pre-answered as Q-2 below.
- **`CLASH_PORT` in the doctor arm** stays at the module default `29090` (`:169`). Grep confirms its only readers are `generate_config()` (`:906`, unreachable) and `clash_api()` (`:946`, reached only with explicit `port=`). `global LANG, CLASH_PORT` (`:1500`) does not require assignment in both arms. Safe under C-3.

### Q4 — D-1's exit map. **Consistent, complete, predictable; the argparse collision does not matter.**

`worst = max(worst, cls)` over `OK=0 < UNKNOWN=1 < PROBLEM=2`, then `DOCTOR_EXIT = {0:0, 1:2, 2:1}`. Pure function of the multiset of printed row classes: 1 iff any `[PROBLEM]`, else 2 iff any `[UNKNOWN]`, else 0; `cls is None` continuation lines contribute nothing. FR-25 holds (language/TTY/order independent — different init systems produce *different findings*, which FR-25 permits); FR-26 holds (`sys.exit` after the loop); FR-28 holds (three values, documented in §8, both help blocks, both READMEs). The two-value folding argument in §3.1 is sound. The `2` collision is real and correctly judged harmless: `sc doctor extra-arg` exits 2 from argparse with a usage message and **no report**, whereas every doctor-produced status follows seven section labels; swapping would move the overlap onto the commoner value. Already recorded as `doctor-exit-status-always-zero` (`.harness/rejected-decisions.md:186-201`).

### Q5 — D-4. **`_free_port()` is structurally unreachable; `_saved_clash_port()` does become the single reader — but the sketch drops a binding (F-2).**

Grep confirms `_free_port` occurs exactly twice: definition `:179`, single call inside `_resolve_clash_port()` `:206`. `_resolve_clash_port()` is called exactly once, from `main()` `:1503`, which after D-3 lives only in the non-`doctor` arm. So `doctor → _resolve_clash_port → _free_port` has no edge, and stage 1 R-2's tautology cannot occur. `settings["clash_api_port"]` is read at exactly one place (`:203`) and written at exactly one (`:207`); after the split the read is `_saved_clash_port()`'s — AC-15 holds.

**But** `bin/sc:207-211` uses the local `settings` dict the sketch has just moved out. Repairing it carelessly (`save_settings({"clash_api_port": port})`) would erase `lang`, `mode`, `default_tun`, `update_interval` on the first run of any command on a host with a settings file but no persisted port — exactly the pre-auto-probe installs `CHANGELOG.md:15` describes. → C-2.

### Q6 — D-5. **The extraction preserves `sc status` byte-for-byte in both languages; the AC that proves it does not (F-3).**

`cmd_status` is `:1092-1114`. The TUN literal is `:1099` (`subprocess.run(["ip","-br","addr","show","sb-tun"])`), inside no conditional, printing straight to stdout — substituting a constant of identical value cannot change a byte. The egress block is `:1109-1114`, **inside** the `if is_running():` gate opened at `:1100`; `_egress_ip()`'s body is `:1111-1112` lifted verbatim, and `print(_egress_ip())` inside the existing `try` raises the same exception types from the same two calls, so `t("(error: {e})", e=e)` (`:1114`) renders identically — in zh too, since `（错误：{e}）` (`:105`) is untouched. Moving the `print` outside the `with` changes nothing observable. `generate_config()`'s `"interface_name"` (`:873`) emits the same JSON string. AC-15 verified by grep: `sb-tun` at `:873` and `:1099` only; `api.ipify.org` at `:1111` only.

The *proof* is the problem: `cmd_status` also runs `systemctl status --no-pager -n 5` (`:1095`) — elapsed-time field, PID, five journal lines — and prints a live egress address (`:1112`). Two captures differ with or without this change. → F-3 / C-4.

### Q7 — D-6/D-7. **Isolation, label coverage and non-TTY purity are correct and explicitly specified; the scrubber's coverage is under-specified (F-4).**

- `except Exception` is named explicitly with `BaseException`/bare `except:` explicitly rejected (§3.7), so `KeyboardInterrupt`/`SystemExit` pass through and Ctrl-C during the 8 s egress wait behaves as in every other subcommand.
- All seven labels print under every failure: the fallback row's `label_key = None` resolves to the section label (§5.2). Because a probe returns its whole row list before anything is printed, a probe that raises mid-way loses its computed rows and prints one UNKNOWN row under the section label — AC-8 still passes, and FR-10's unit is the section, so streaming is unaffected.
- FR-21: the guarantee is unconditional (no TTY gate), which is the right shape. `_doctor_run` merges stderr into stdout (`stderr=subprocess.STDOUT`), so no tool's bytes reach the terminal outside the report; `is_running()`'s systemd branch is `--quiet` (`:961`) and its OpenRC branch captures (`:964`) — neither leaks. Residual: §6's row specs interpolate `{e}` and the egress value without naming `_plain()` → F-4/C-5.
- Flush ordering is *specified*, not implied: `print(..., flush=True)` per row, with the 8 KiB pipe-buffer failure mode named; only the integer `worst` is accumulated.
- AC-3's greppability is real and rests on a detail worth pinning: the separator `": "` is literal ASCII outside `t()`, so `Clash API` (a proper prefix of `Clash API responding` in **both** languages) is disambiguated by `grep '\] Clash API: '`. QA must use the anchored form.

### Q8 — D-8/RISK-1. **The contingency is acceptable as written and does not pre-emptively weaken FR-4; I could not settle the question by inspection.**

Established read-only: the generated config declares `experimental.cache_file.path = /var/lib/sing-box/cache.db` (`:903-905`); `sing-box check -c` already runs on every `sc add`/`rm`/`reload` (`:921-926`); `/var/lib/sing-box/cache.db` exists on this host and all four `.srs` plus the three JSON files exist. None of that discriminates between "check builds and closes the instance" and "check starts the cache service" — that is external-binary control flow, not a string or path in this repository. I have read-only tools and will not execute the binary or touch the live service. The architect's abstention is correct, not lazy.

The contingency is acceptable because it *narrows* rather than pre-empts: it forbids dropping the check (which would gut the diagnostic the owner's failure chain ends in) and forbids substituting a JSON parse (a second opinion about config validity `bin/sc` does not hold), and routes any measured write into a documented path-scoped exception re-reviewed at this gate. "No third option" is defensible: checking a rewritten copy would both write a file (FR-4's absolute clause) and check an artefact that is not the installed one. I confirm the structural limit: on a host with no `/etc/sing-box`, S3 short-circuits at "no file" and never invokes the checker, so AC-5's fresh-host half is immune either way. Gap: the contingency covers "write measured" and "no write measured" but not "cannot measure" → C-7.

### Q9 — Rule 85, both directions. **No second opinion; the decomposition is the right granularity, with one borderline member.**

*No duplicated judgment*, each checked: usability → `srs_reject_reason()`/`ruleset_state()` (doctor contains no magic or size test); status wording → `_status_text()`; running → `is_running()`; init → `SYSTEMD`/`OPENRC`; port → `_saved_clash_port()`; egress → `_egress_ip()`; TUN name → `TUN_IFACE`; config validity → the same external checker `generate_config()` calls. The declined consolidations each name the future edit they do *not* prevent — the right test. One omission (F-7): `sc` already keeps a second record of "starts at boot" in `settings["default_tun"]` (`:1088`, `:1143-1144`), and the design never says why `doctor` asks the init system instead. Asking the authority is correct — a disagreement is itself a defect worth seeing — but it must be stated so nobody "fixes" it toward the settings key.

*Not over-built.* One constant plus two extractions that FR-18 **requires** (not design inventions); `_plain()` with a stated five-call-site deletion test; `_doctor_run()` used by four probes, carrying the 3.6 constraint in one place; seven probes, which are the domain's shape (FR-6), not the bug report's; `DOCTOR_SECTIONS`, the artefact AC-3 checks; three small class constants carrying FR-8 and D-1. No new file, module, flag, `--json` or config format. Borderline: `_doctor_print()` has a single caller and inlines in ~4 lines, so its rule-85 justification is weak. Permitted — it is where FR-20/FR-21's row shape is pinned — but it must not grow parameters or modes (F-14).

### Q10 — Completeness against every AC. **No AC is silently unaddressed; one (AC-16) is unverifiable by its own method, one (AC-13) needs Q1's reading.**

AC-1 ✓ E-16/E-18 · AC-2 ✓ §13, both READMEs' insertion point verified (`README.md:94-101`/`:103`, `README.zh-CN.md:94-101`/`:103` are true mirrors) · AC-3 ✓ D-9 + anchored grep · AC-4 ✓ §6.2 · AC-5 ✓ D-3 + T-2, RISK-1 the only residual · AC-6 ✓ everything doctor runs is a query · AC-7 ✓ §9, independently re-audited below · AC-8/9/10 ✓ D-7 · AC-11 ✓ D-6 · AC-12 ✓ per-row flush · AC-13 → Q1 · AC-14 ✓ D-2; the behavioural half is constructible (a `.srs` whose `st_size` and read length differ is obtainable, e.g. a symlink into a pseudo-filesystem) and the inspection half is decisive alone · AC-15 ✓ grep · AC-16 → F-3 · AC-17 ✓ under C-5 · AC-18 ✓ I checked every §10 row: each zh value's placeholder set equals its key's exactly (`{code}`, `{n}/{total}`, `{reason}`/`{size}`, `{path}`, `{e}`, `{init}`, `{state}`, `{iface}`), so R-5's `KeyError` cannot fire · AC-19 ✓ all keys prose, no `ls.idx`-style token · AC-20 ✓ no §10 zh value contains `失败` in any form, nor do the four reused keys (`(none)` `:103`, `(error: {e})` `:105`, `_status_text()`'s four at `:133-136`) · AC-21 ✓ D-1 · AC-22 ✓ modulo F-13 · AC-23 ✓ Q11 · AC-24 ✓ the 16/22-line count recomputes correctly · AC-25 → F-5 · AC-26 ✓ Q12.

### Q11 — Python 3.6 floor. **Every implied construct is 3.6-legal; no new `capture_output=` site.**

`subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)` + `.stdout.decode("utf-8","replace")` (3.5+); `CompletedProcess.returncode`; f-strings (already at `:906`, `:946`, `:1108`); default kwargs; `max()`; dict/tuple literals; `with urllib.request.urlopen(...) as resp` (already `:1111`); `str.rstrip()`/`replace()`; `sys.exit(int)`. No walrus, `text=`, `capture_output=`, f-string `=`, `unlink(missing_ok=)`, `dataclasses`. The three pre-existing 3.7+ sites are `bin/sc:922`, `:964`, `:1289` (grep-confirmed), none in this diff — and the refusal to wrap `generate_config()`'s checker call is what keeps it that way. See F-11 for the one pre-existing site newly *reached*.

### Q12 — Scope. **The design cannot drift outside the permitted diff.**

§2 names exactly `bin/sc`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, `docs/dev-map.md`; §16 restates it. Nothing in E-1..E-18, §13 or §14 reads or writes `install.sh`, `uninstall.sh` or `systemd/`; the only system-level behaviour changed is inside `main()`. `CONTEXT.md` is deliberately untouched with a stated reason. Two pipeline artefacts fall outside the product list and are **already written**: this document's siblings, and two records in `.harness/rejected-decisions.md` (`doctor-exit-status-always-zero`:186-201, `shared-singbox-check-wrapper`:203-218). Harness memory, not product; every prior task did the same — but they must be declared in `07_DELIVERY.md` so the commit diff holds no surprise (C-8).

## 4. Independent verifications (not taken from upstream)

**`t()` / `TRANSLATIONS`.** `bin/sc:215-217` is `TRANSLATIONS.get(LANG, {}).get(s, s)` then `.format(**kwargs)` only when kwargs are present; `TRANSLATIONS` (`:85-166`) has exactly one top-level key, `"zh"`. Stage 1 R-4 and §5.2's "unknown keys pass through verbatim" are both correct. One consequence the design uses without stating: because `t()` formats *only* when kwargs are passed, `t(label)` and `t(DOCTOR_MARK[cls])` cannot raise on a stray brace in a filename.

**The `失败：` literal.** `"failed: {e}"` → `失败：{e}` at `bin/sc:127` (the `mirror-fallback-cause…` record cites `:126` — one-line drift, not this task's file to fix). No new or reused zh string contains the substring; the only route into doctor's zh output would be foreign text, which is English on every supported path. AC-20's run-time rendering check (T-10) is the right instrument and deliberately not a repository grep (`insight-index.md:19`).

**Timeouts unchanged.** `clash_api()`'s `timeout=3` is at `:952` and E-11 touches only `:945-946`; `_egress_ip()` carries the existing `timeout=8` from `:1111`; the 30 s download timeout is not on any reachable path. `_doctor_run` adds no `timeout=` at all (F-10).

**Read-only enumeration (AC-7/FR-3/FR-4) — the most important check.** Independently audited:

| Operation | Where | Read-only? |
|---|---|---|
| `os.execvp("sudo", …)` at import | `:78-79` | no project file written; sudo's own bookkeeping is outside the guarantee — F-9 |
| `shutil.which("systemctl"/"rc-service")` | `:35-36` | PATH lookup |
| `_load_lang()` → `read_text()` | `:172-176` | read; tolerates absence; never creates |
| `shutil.which(SB_BIN)` (S1/S3) | new | PATH lookup |
| `sing-box version` (S1) | new | prints a version |
| `ruleset_states()`→`ruleset_state()` (S2) | `:575-588`, `:516-558` | `exists()`/`is_file()`/`open("rb")`; **no `mkdir`** — verified at `:541`, so BC-3's absent rules dir is not created |
| `open(CFG_PATH, "rb")` (S3) | new | read mode |
| `sing-box check -c` (S3) | new | the sole residual — RISK-1 |
| `systemctl is-active --quiet` / `rc-service status` (S4) | `:959-965` | queries; `is-active` cannot even witness a restart (`insight-index.md:22`) |
| `systemctl is-enabled` / `rc-update show default` (S4) | new | queries; `rc-update show` takes no runlevel-modifying argument |
| `ip -br addr show` (S5) | new | `show` |
| `load_settings()` via `_saved_clash_port()` (S6) | `:243-244` | `read_text()` |
| `clash_api("GET","/configs", port=…)` (S6) | `:945-956` | loopback GET; does not mutate the running instance |
| `_egress_ip()` (S7) | new | HTTPS GET to the one existing endpoint |

Not on the graph, confirmed by call-site inspection: `_init_files()`, `_resolve_clash_port()`, `_free_port()`, `save_settings()`, `save_nodes()`, `generate_config()`, `restart_service()`, `reload_or_restart()`, `_fetch_to_temp()`, `_temp_path()`, `_clear_stale_temps()`, `RULES_DIR.mkdir()`. **I found no hole in the file-writing guarantee** other than RISK-1 and F-9's ruling.

**`.harness/insight-index.md`.** No entry contradicts the design; five support it — `:13` (auto-elevate re-execs the installed `sc`), `:16` (`失败：`), `:19` (self-violating repository-grep criteria), `:22` (`is-active` cannot witness a restart), `:26` (clone, not worktree). The index stands at 29 lines against the 30 cap, so R-10's one-physical-line harvest budget is real.

## 5. Pre-answered developer questions

**Q-1. "E-17 says move `parse_args()` above line 1501 — but `parser` doesn't exist yet."** Move the three init statements **down**, to immediately after `args = parser.parse_args()`, and branch there. Verified safe: nothing in `:1504-1520` reads `LANG`/`CLASH_PORT` or calls `t()`. Keep `global LANG, CLASH_PORT` at `:1500`.

**Q-2. "`./bin/sc doctor` says `invalid choice: 'doctor'`."** Expected, not your bug: as non-root the import-time auto-elevate (`:78-79`) re-execs the **installed** `/usr/local/bin/sc`, which predates your change. Test as root against the edited file, or install first (`insight-index.md:13`).

**Q-3. "`_resolve_clash_port()`'s `settings` is now undefined — can I `save_settings({"clash_api_port": port})`?"** **No** — that erases `lang`, `mode`, `default_tun`, `update_interval`. Re-load the dict in the fallback arm inside the same `(FileNotFoundError, json.JSONDecodeError, OSError)` guard as `:199-202`, assign into it, keep `except OSError: pass` around `save_settings` (`:208-211`).

**Q-4. "Service is down — shouldn't S5's missing TUN and S6's unanswered port be UNKNOWN per FR-8?"** No. FR-8's general sentence is overridden by BC-10 ("PROBLEM, distinct from BC-9's UNKNOWN") and BC-12 ("PROBLEM 'no answer' after the existing 3 s timeout, not UNKNOWN"). The only mandated prerequisite→UNKNOWN mapping is S3's missing checker. Do not "fix" this.

**Q-5. "S2 needs sizes but AC-13 names `ruleset_report()` — call both?"** No: two reads per file violates FR-12 and admits a self-contradicting report under BC-15. Call `ruleset_states()` once; see Q1.

**Q-6. "Where exactly does `_plain()` go?"** At doctor's own call sites: `_plain(str(e))` in every `{e}` interpolation (S1, S3, S5, driver backstop), `_plain()` on `_egress_ip()`'s return inside S7, and inside `_doctor_run`. **Not** inside `_egress_ip()` — it `rstrip()`s, and `sc status` prints that value directly (FR-19/AC-16).

**Q-7. "`clash_api()` returned `{}` — is that 'no answer'?"** No; `:954` returns `{}` for an empty body, which is falsy. Test `is not None`. Also (F-12) a read-phase `socket.timeout` or non-JSON body escapes `clash_api()`'s `except` at `:955` and surfaces as S6's driver-backstop UNKNOWN rather than the designed PROBLEM row — acceptable, not a bug to chase.

**Q-8. "Add `timeout=` to `_doctor_run` so a hung `ip` can't wedge the report?"** No — NFR-2 and stage 1 §3.5 forbid introducing a timeout constant, and `cmd_status` already runs `systemctl status` (`:1095`) and `ip` (`:1099`) unbounded. Disclosed in §14 T-4.

## 6. Findings and conditions

| # | Sev | Finding | Anchor | Owner |
|---|---|---|---|---|
| F-1 | MAJOR | E-17 not executable: `parse_args()` (`bin/sc:1522`) cannot move above `:1501` because `parser`/`sub` are built at `:1504-1520`. D-3's substance is correct; only the instruction is wrong. | `02_` §4 E-17 / §3.3 | solution-architect (instruction) / developer (execution) |
| F-2 | MAJOR | D-4's sketch removes the `settings` binding `bin/sc:207-211` needs; the obvious repair destroys unrelated settings keys on pre-auto-probe installs. | `02_` §3.4 | solution-architect |
| F-3 | MAJOR | AC-16/T-7's method is not executable: `cmd_status` prints `systemctl status --no-pager -n 5` (`:1095`) and a live egress address (`:1112`), so two captures never `cmp` equal, change or no change. | `01_` AC-16 · `02_` §14 T-7 | solution-architect (test method) |
| F-4 | MINOR | `_plain()`'s coverage is in §3.6 but §6's rows interpolate `{e}`/version/egress without naming it; the correct placement (call site, not inside `_egress_ip()`) is unstated and load-bearing for FR-19. | `02_` §3.6 vs §6 | solution-architect |
| F-5 | MINOR | `02_SOLUTION_DESIGN.md` is 858 lines against rule 70's 500-line per-task cap; `verify_all` F.6 (`.harness/scripts/verify_all.sh:229-237`) will WARN — an unpredicted AC-25 delta. (`01_` is 496, inside the cap.) | `.harness/rules/70-doc-size.md:29` | solution-architect / PM |
| F-6 | MINOR | §3.3 mechanism 3's grep claim is inexact: `_resolve_clash_port()` yields three hits, not two (`:169`'s comment names it). The single-call-site property still holds. | `02_` §3.3 | solution-architect |
| F-7 | MINOR | §11's "only judgments doctor forms" omits (a) "is the binary present" and (b) that `settings["default_tun"]` (`:1088`, `:1143-1144`) is a pre-existing second record of "starts at boot"; consulting the init system is correct but undeclared. | `02_` §11 | solution-architect |
| F-8 | INFO | FR-8's general prerequisite rule conflicts with BC-10/BC-12; the specific boundary conditions win and the design follows them. Pre-answered (Q-4). | `01_` FR-8 vs BC-10/BC-12 | ruled here |
| F-9 | INFO | FR-4's absolute clause vs reality: auto-elevate `sudo` (`:78-79`) and `systemctl` queries cause bookkeeping writes outside the project's trees. AC-5's snapshot of `/etc/sing-box` + `/var/lib/sing-box` is the binding operational definition; FR-4 is satisfiable as measured. | `01_` FR-4/AC-5 | ruled here |
| F-10 | INFO | NFR-2 only partly satisfiable: `_doctor_run` has no `timeout=`, so a hung local binary is unbounded. Precedent at `:1095`/`:1099`. Disclosed in §14 T-4. Accepted. | `01_` NFR-2 · `02_` §14 T-4 | ruled here |
| F-11 | INFO | S4 calls `is_running()`, whose OpenRC branch uses `capture_output=` (`:964`) — pre-existing 3.7+. On a 3.6 OpenRC host S4 raises `TypeError`, rendered by the driver as one UNKNOWN row; all seven labels still print. No new occurrence; out of scope. | `bin/sc:964` | noted |
| F-12 | INFO | `clash_api()` (`:955`) catches only `URLError`/`HTTPError`; read-phase `socket.timeout` or a non-JSON body propagates to the driver backstop instead of S6's designed PROBLEM row. §6's S6 classification is not exhaustive; FR-9 still holds. | `:945-956` · `02_` §6 S6 | noted |
| F-13 | INFO | FR-27/AC-22 residual: `_doctor_print` runs outside the per-probe `try`, so a `UnicodeEncodeError` under an ASCII stdout encoding with `lang zh` escapes as a traceback. Pre-existing project-wide (`cmd_status` same exposure); not introduced here. | `02_` §3.7 | noted |
| F-14 | INFO | `_doctor_print()` has one caller — the only decomposition member with a weak rule-85 justification. Permitted (it pins FR-20/FR-21's row shape) but must not grow parameters or modes. | `02_` §5.1 | ruled here |

### Conditions

1. **C-1 (F-1)** — Implement D-3 by moving `bin/sc:1501-1503` **down** to immediately after `args = parser.parse_args()` and branching there; do not move `parse_args()` up. Keep the `else` arm's three statements textually identical and in order.
2. **C-2 (F-2)** — In `_resolve_clash_port()`'s first-run branch, re-load the settings dict inside the same `(FileNotFoundError, json.JSONDecodeError, OSError)` guard as `:199-202`, assign `settings["clash_api_port"] = port` into it, keep `except OSError: pass`. Never call `save_settings()` with a fresh single-key dict. Add an executed check that `lang`/`mode`/`default_tun` survive a first-run port resolution.
3. **C-3** — S6 calls `clash_api(..., port=port)` only when `_saved_clash_port()` returned non-`None`; `doctor` never reads module-level `CLASH_PORT`.
4. **C-4 (F-3)** — Restate AC-16's comparison so it is falsifiable: exclude the volatile `systemctl status` block and the live egress line, or capture with the service stopped and compare only the regions this diff can reach. Record the comparison in `06_TEST_REPORT.md`. An unqualified `cmp` of two `sc status` captures is not evidence.
5. **C-5 (F-4)** — Route every foreign string through `_plain()` at doctor's call sites (all `{e}`, the egress value, `_doctor_run`'s output). `_egress_ip()` itself stays byte-faithful (FR-19/AC-16).
6. **C-6 (Q1)** — Execute AC-13's deletion test against `ruleset_states()`/`ruleset_state()` and record in `04_`/`06_` that AC-13's "report function" wording was read as the state/report machinery, with the FR-12 two-reads conflict as the reason.
7. **C-7 (Q8)** — If T-1 cannot be measured (no `sing-box` binary, or no valid `config.json` on the QA host), that is **inconclusive**, not a pass: return to this gate rather than adopting §3.8's prediction as fact.
8. **C-8 (F-5/F-6/F-7/scope)** — PM/architect: compact `02_` below rule 70's 500-line cap or declare F.6's WARN as a predicted AC-25 delta. Developer: declare the two `.harness/rejected-decisions.md` records in `07_DELIVERY.md` as pipeline artefacts outside AC-26's product list, and state in `04_` why `doctor` reads the init system rather than `settings["default_tun"]`.

None of these requires a design change of substance; all eight are executable inside development and QA, and neither `01_` nor `02_` must be reopened for the pipeline to proceed — F-5's compaction is a documentation-hygiene routing decision for the PM, not a design defect.

---

**APPROVED FOR DEVELOPMENT WITH CONDITIONS:** C-1 (restate D-3's edit as moving the init block down below `parse_args()`), C-2 (preserve `_resolve_clash_port()`'s settings-merge semantics), C-3 (S6 never reads the global `CLASH_PORT`), C-4 (make AC-16's comparison falsifiable), C-5 (`_plain()` at the call sites, never inside `_egress_ip()`), C-6 (execute AC-13's deletion test against `ruleset_states()`/`ruleset_state()` and record the reading), C-7 (an unmeasurable T-1 returns to this gate), C-8 (compact `02_` or declare the F.6 delta; declare the rejected-decisions records; state the `default_tun` ruling).
