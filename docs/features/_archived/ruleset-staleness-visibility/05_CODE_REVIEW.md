> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed

- `/home/alan/Programs/singbox-cli/bin/sc`
- `/home/alan/Programs/singbox-cli/README.md`
- `/home/alan/Programs/singbox-cli/README.zh-CN.md`
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/docs/features/ruleset-staleness-visibility/01_REQUIREMENT_ANALYSIS.md`
- `/home/alan/Programs/singbox-cli/docs/features/ruleset-staleness-visibility/02_SOLUTION_DESIGN.md`
- `/home/alan/Programs/singbox-cli/docs/features/ruleset-staleness-visibility/03_GATE_REVIEW.md`
- `/home/alan/Programs/singbox-cli/docs/features/ruleset-staleness-visibility/04_DEVELOPMENT.md`
- `/home/alan/Programs/singbox-cli/docs/features/ruleset-staleness-visibility/04_RATIONALE.md` (T5.2 — adjudicating DESIGN DRIFT D-1)
- `/home/alan/Programs/singbox-cli/.harness/rules/85-design-discipline.md`
- `/home/alan/Programs/singbox-cli/.harness/rules/70-doc-size.md` (no `## Stage-doc boundary rule` — schema applied as written, E-20 gap persists)
- `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` (B.3 Lint = SKIP — no linter enforces blank-line style on `bin/sc`)
- fixture sources, uncommitted (C-5, out-of-scope 8): `fixture.py`, `v_update.py`, `v_status_running.py`, `v_config_diff.py`, `v_config.py` under the stage-4 scratchpad

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | MINOR | Standards-conformance | `04_DEVELOPMENT.md:99`, `:232`, `:233` | Three stale `bin/sc` citations. D-1's flush line is cited `:2871`; it is at `:2869` (`:2871` is `if not ok:`). The second `## Insight to surface` row cites `:2276`; the `clash_api("GET","/configs")` it names is at `:2277`. `04_RATIONALE.md:57` cites `:2750` for `print(prefix, end="", flush=True)`; it is at `:2791`. The two `04` citations travel verbatim into `.harness/insight-index.md`, so the ledger would carry a line number that points at the wrong statement. Owed to the **developer** (or corrected by the PM at ledger-write time). |
| CR-2 | MINOR | Standards-conformance | `docs/dev-map.md:51` | The "Per-file rule-set state" row — one of the two rows this task corrects — still reads "which is why `generate_config()` / `usable_tags()` / `_warn_degraded()` destructure 3-tuples". A-1 and F-14 established `generate_config()` does not destructure the projection at all; `_runtime_overlay()` (`bin/sc:1815`) does. The line was already being edited (already `+1/−1` in the diff), so the correction was free, and this is the row T-20 reads first. Owed to the **developer**. |
| CR-3 | MINOR | Standards-conformance | fixture `fixture.py:51`, `fixture.py:106`, `v_status_running.py:33` | The fixture's `CLASH_PORT` and its own `settings.json` both carry `29090`, which is the port the **live** sing-box listens on here, so a `cmd_status()` step inside a fully redirected temp root had `clash_api("GET","/configs")` answered by the running service (stage 4's capture printed `Route mode: Rule`). Read-only on `sc status`' code path and therefore not a K-18 breach — but it falsifies the "isolated fixture" claim, and a step that ever issued a PUT/PATCH would mutate the live service. Disclosed by the developer; owed to **stage 6** (choose a port proved free, or state in C-4's evidence that the only Clash call in the step is a GET). |
| CR-4 | NIT | Standards-conformance | `bin/sc:2832`, `bin/sc:2853` | `# hoisted: 'ok' below is the run's ONE success record` and `# THE determination: one expression, read by both the outcome sentence and the exit` state the same invariant twice, four lines apart. One line of the +80 budget is recoverable. Not worth a round. |
| CR-5 | MINOR | Spec/design-fidelity | `bin/sc:2272` | Under `LANG=zh` the rule-set row reads `可用, 30 天前` with an ASCII `, `, because I-3 fixes the separator in the format string `"%-20s %s, %s"`; `sc doctor`'s equivalent row reads `可用，5572 字节` because its separator lives inside the key `"{reason}, {size} bytes"` (`bin/sc:278`). Implemented **exactly** as I-3 specifies, so this is design fidelity rather than drift: the design item carries the inconsistency. Fixing it needs one new key plus one zh entry against a budget already at the ceiling — re-homed as a PM follow-up row, not a stage-2 rollback (MINOR does not block). |

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| FR-1 | `ruleset_state()` `bin/sc:816` — `os.fstat(fh.fileno()).st_mtime` on the same open handle; only two callers (`:834`, `:849`), both widened; no other rule-set timestamp query in the file | ✅ |
| FR-2 | `_age_text(mtime)` `bin/sc:925`, one call site `:2272`, signature takes no command-specific argument | ✅ |
| FR-3 | `cmd_status()` `bin/sc:2270-2272` — heading + one line per `ruleset_states()` entry, outside `if is_running():` | ✅ |
| FR-4 | `bin/sc:934-935` — `mtime is None` ⇒ `t("last update unknown")`, never a number | ✅ |
| FR-5 | `_status_view()` `bin/sc:860` still returns 3-tuples; `_runtime_overlay():1815`, `usable_tags():905`, `_warn_degraded():976` untouched; `generate_config()` unchanged | ✅ |
| FR-6 | one determination `bin/sc:2854`, read by the outcome chain `:2857-2867` and by the one exit `:2872` | ✅ |
| FR-7 | `ok = not failed and regen_ok and restarted is not False` — the three terms are download, regeneration+check, service action | ✅ |
| FR-8 | `bin/sc:2844` gates the "config regenerated" claim on `regen_ok`; `:2862-2864` is the truthful failed-restart variant | ✅ |
| FR-9 | per-file lines `:2791-2827` untouched; aggregate still one stderr line with its leading `\n` `:2870`; `Done` only when `ok` `:2873`; four-member closed set `:2857-2867` | ✅ |
| FR-10 | 7 zh keys (`:156`, `:216-220`, `:230`) with matching placeholder sets, none containing `失败`; `README.md:245`; `README.zh-CN.md:245`; `CHANGELOG.md:7` | ✅ |
| BC-1 | `bin/sc:800-803` ⇒ `("absent", None, None, None)` ⇒ word form | ✅ |
| BC-2 | `bin/sc:802`, `:805`, `:819` ⇒ `("unreadable", None, None, None)` ⇒ word form | ✅ |
| BC-3 | empty file: loop breaks, `fstat` still runs `:816`, returns `("too-small", sha256(b""), 0, <real>)`; stated in the DIGEST CONTRACT `:783-785` | ✅ |
| BC-4 | `max(0, int(time.time() - mtime))` `bin/sc:936` | ✅ |
| BC-5 | `ruleset_states()` is a pure query; `cmd_status()` creates nothing | ✅ |
| BC-6 | section placed above `if is_running():` `bin/sc:2269-2273` | ✅ |
| BC-7 | one `print()` per rule-set, no `\r`, no `flush=` (K-7) | ✅ |
| BC-8 | `sys.stderr.write("\n" + … + "\n")` `:2870` in K-13's position; merged-capture order preserved by D-1's `:2869` | ✅ (C-8 re-measured at stage 6) |
| BC-9 | `regen_ok = generate_config()` `:2843`; restart gated on `regen_ok and is_running()` `:2847`; outcome falls to branch (d); `ok` false ⇒ exit 1 | ✅ |
| BC-10 | `restarted = restart_service()` `:2852` ⇒ `False` ⇒ branch (c) `:2862`; `ok` false ⇒ exit 1 | ✅ |
| BC-11 | `not changed` ⇒ branch (a) `:2857`; `ok` true ⇒ `Done`, exit 0 | ✅ |
| BC-12 | `if changed and CFG_PATH.exists():` `:2838` untouched | ✅ |
| BC-13 | no envelope, no `try/finally`, no `atexit`, no wrapper added; the tail is flat | ✅ (V-14 owed to stage 6) |
| BC-14 | `_temp_path()` / `tmp.replace(target)` untouched; the reported age is whichever run last replaced the file | ✅ |
| AC-B1 | `bin/sc:2270-2272` + `_age_text()`; stage-4 S-1 reports `30 days ago` / `0 seconds ago`, HEAD control disagrees | ✅ (re-measured at stage 6) |
| AC-B2 | same section; stage-4 S-2, both unavailable rows word-form, no digit in the suffix | ✅ |
| AC-B3 | placement above `is_running()`; stage-4 S-6 observes both arms (C-4 pair) | ✅ |
| AC-B4 | K-5 shield verified in code; stage-4 S-7 byte-identical (**freeze** — never evidence of a change) | ✅ |
| AC-B5 | `:2843-2847`; stage-4 S-9 exit 1, no `config regenerated`, stub log holds no `systemctl` | ✅ |
| AC-B6 | `:2852`, `:2862`; stage-4 S-10 exit 1, I-13's line, exactly one `systemctl restart` | ✅ |
| AC-B7 | freeze; stage-4 S-12 / S-13 agree at HEAD by design | ✅ (freeze) |
| AC-B8 | outcome chain is a single if/elif over a tri-state; all six reachable states enumerated in `05_RATIONALE.md` and each claim is true of its run | ✅ |
| AC-B9 | not observable by any agent in this pipeline (P-6, K-18) | ⚠️ BLOCKED — carried by C-7 to `07_DELIVERY.md`, never substituted |
| AC-S1 | one `st_mtime` site (`:816`); the known non-timestamp `os.stat` at `:1388` (`_load_override()`, `S_ISREG`) reported, assertion not widened; one renderer, one call site, signature `(mtime)`; `st_size` appears in no code | ✅ |
| AC-S2 | 7 zh keys with equal placeholder sets; no added zh string contains `失败`; `TRANSLATIONS` has no `en` table (`bin/sc:124-125`), so `t()` returns the English key verbatim | ✅ |
| AC-S3 | product diff = `bin/sc`, both READMEs, `CHANGELOG.md`, `docs/dev-map.md` only; `docs/tasks.md` is the PM's carve-out; `docs/batches/**` is the batch loop's, not this task's; verify_all at PASS 17 / WARN 0 / FAIL 0 / SKIP 1, re-measured by the PM after stage 4 | ✅ |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| E-1 `import time` ≈ +1 | `bin/sc:16`; +1 / −0 | ✅ |
| E-2 7 zh keys ≈ +7 | `:156`, `:216-220`, `:230`; +7 / −0 | ✅ |
| E-3 `ruleset_state()` ≈ +14 / −6 | `:769-820`; +15 / −12 (docstring edits, answered in `04`) | ✅ |
| E-4 `ruleset_states()` ≈ +2 / −2 | `:838`, `:849-850`; +3 / −3 | ✅ |
| E-5 three destructuring sites ≈ +3 / −3 | `:860`, `:887`, `:889`, starred (A-6 smaller form); +3 / −3 | ✅ |
| E-6 `_age_text()` ≈ +18 | `:925-940`; +18 / −0 | ✅ |
| E-7 `_doctor_rulesets()` ≈ +1 / −1 | `:2404`; +1 / −1 | ✅ |
| E-8 `cmd_status()` section ≈ +4 | `:2269-2272`; +4 / −0 | ✅ |
| E-9 `restart_service()` ≈ +8 / −4 | `:1991-2003`; +10 / −2 | ✅ |
| E-10 tail ≈ +14 / −8 | `:2829-2873`; +15 / −6, D-1's line included | ✅ |
| C-1 `HELP_EN` / `HELP_ZH` (not in `02`'s ledger, F-1) | `:3023-3024`, `:3090`; +3 / −2 | ✅ |
| **`bin/sc` total, ceiling +80 / −30 (C-6)** | rows above sum to **+80 / −29**, reconciling exactly with the PM's independent `git diff --numstat` | ✅ not exceeded |
| E-11 `README.md` 1 line | `:245` `rule-set status + age`; +1 / −1 | ✅ |
| E-12 `README.zh-CN.md` 1 line | `:245` `规则集状态与更新时间`; +1 / −1 | ✅ |
| E-13 `CHANGELOG.md` one entry | `:7` under `### 新增`, Chinese, both halves, house-style single paragraph; +2 / −0 | ✅ |
| E-14 `docs/dev-map.md`, bounded by out-of-scope 11 | `:49` and `:51` corrected, `:50` added, all inside `## Reusable utilities`; +3 / −2 — the count is exactly 2 modified lines + 1 added line, which the three rows demand, so no other line changed, no section added or removed, no row deleted | ✅ (see CR-2) |
| K-1 `os.fstat(fh.fileno())` inside the existing `with`, never `path.stat()` | `:816`, inside `with path.open("rb") as fh:` `:806` | ✅ |
| K-2 `st_size` introduced nowhere | appears only in pre-existing prose (`:792`, `:1139`, `:1410`); in no code | ✅ |
| K-3 the `fstat` inside the existing `try` | `try:` `:799` … `except OSError:` `:817` encloses `:816` | ✅ |
| K-4 DIGEST CONTRACT names `mtime` in the same equivalence chain | `:776`, `:780-789` — chain and the readable-empty-file sentence both extended | ✅ |
| K-5 `_status_view()`'s **return** stays 3 elements | `:860`; the three real destructuring sites (A-1) `_runtime_overlay():1815`, `usable_tags():905`, `_warn_degraded():976` are untouched | ✅ |
| K-6 section after TUN, before `if is_running():` | `:2267-2273` | ✅ |
| K-7 no `flush=` in the new prints | `:2270`, `:2272` | ✅ |
| K-8 `reload_or_restart()` not edited; six other callers unaffected | `:2006-2010` unchanged; `reload_or_restart()` callers at `:2195`, `:2217`, `:2233`, `:2668`, `:2731`, `:2977`; `restart_service()` has exactly two callers, `:2009` and `:2852` | ✅ |
| K-9 `check=False` kept, `.returncode` read | `:1998`, `:2000`, `:2003` | ✅ |
| K-10 one apply per run; T-10's comment byte-for-byte; T-02's regeneration ahead of the exit | `:2838-2852`; comment `:2849-2851`; `generate_config()` at `:2843` precedes `sys.exit(1)` at `:2872` | ✅ |
| K-11 no false regeneration claim | `:2844` `if regen_ok:` | ✅ |
| K-12 exactly one `sys.exit` in `cmd_update_rules()` | `:2872`, the only one in `:2780-2873` | ✅ |
| K-13 `sys.stderr.write` in the same position | `:2870`; stream, wording, leading `\n` and single-line shape identical — plus D-1's `:2869`, adjudicated below | ✅ with accepted drift |
| K-14 `Done` only when `ok`, no other stdout line added | `:2873`, after the exit site | ✅ |
| K-15 no envelope, `try/finally`, `atexit` or wrapper; no outcome line on an unwind | none added; the tail is flat | ✅ |
| K-16 no threshold, no verdict, no age-derived warning / exit / class constant | `_age_text()` classifies nothing; `dev-map.md:50` states the prohibition | ✅ |
| K-17 no `sc doctor` row, no second age derivation | `_doctor_rulesets():2404` widened by a starred tail only; `_age_text` has one call site | ✅ |
| K-18 safety floor | this stage executed nothing; read-only tools only | ✅ |
| K-19 fixture replaces the loaded module's `subprocess` before any command | `v_update.py:59` then `:60`; `v_status_running.py:19-24` | ✅ |
| I-1 `(status, digest, size, mtime)`, never raises, never writes | `:769-820`, all five return sites widened | ✅ |
| I-2 `_age_text(mtime)`, coarse-unit ladder as a local tuple, must stay a function | `:925-940` — 3-row local tuple, no module-level name added | ✅ |
| I-3 `"%-20s %s, %s"`, one complete line, `RULESET_FILES` order | `:2271-2272` | ✅ (see CR-5) |
| I-4 `restart_service() -> bool`, `True` on no init system | `:1991-2003`; that arm is unreachable from `cmd_update_rules()` (F-13 / A-7) | ✅ |
| I-5 `ok = not failed and regen_ok and restarted is not False`; `restarted` tri-state | `:2832-2833`, `:2854` | ✅ |
| I-6 four-member closed set, branch order (a)(b)(c)(d), `Done` a trailer | `:2857-2867` then `:2871-2873`; all six reachable states enumerated and each claim true (rationale) | ✅ |
| C-1 both help blocks name the rule-set section, column 30 preserved, no key added | `HELP_EN:3023-3024` (continuation at column 30, the `add` / `doctor` precedent), `HELP_ZH:3090`; both blocks are printed literals (`:3141`), not `t()` call sites | ✅ discharged |
| C-5 shadowing form and a total, closed stub | `sc.subprocess = fixture.stub_subprocess(...)` at `v_update.py:59` and `v_status_running.py:19`, both **before** `SYSTEMD = True`; `fixture.py:77-78` raises `AssertionError` on any un-enumerated argv — not a delegating stub; `subprocess.run = …` appears nowhere in the T-19 fixture set | ✅ discharged |
| D-1 (drift) one `sys.stdout.flush()` beyond the ledger | `:2869`, inside `if failed:`, inside E-10's hunk and inside the +80 budget | ✅ **accepted** — reasoning in `05_RATIONALE.md` |
| Frozen set | `generate_config()`, `_runtime_overlay()`, `usable_tags()`, `_warn_degraded()`, `_filter_rules()`, `ruleset_report()`, `srs_reject_reason()`, `reload_or_restart()`, `_fetch_to_temp()`, `_temp_path()`, `_clear_stale_temps()`, `_ruleset_bases()`, the per-file lines, the five `ls.*` keys, `install.sh`, every `systemd/*`, `.harness/scripts/*` — none edited | ✅ |
| Rule 85 on the shipped diff | no new module-level name but `_age_text`; the unit ladder is data (a local tuple), not machinery; added prose sits at the file's existing density and each sentence carries a constraint the design attaches to that symbol (K-1…K-4, I-2's "must stay a function", I-4's unread arm). One duplicated comment found (CR-4); nothing else is unearned | ✅ |

## Axis status

- **Standards-conformance**: 4 findings (CR-1, CR-2, CR-3 MINOR; CR-4 NIT), worst = MINOR. None blocks. The repo's own conventions hold: no invented rule, no hand-edit under `.claude/`, English stage doc, doc-size caps respected, `verify_all` at the batch baseline, and the file's single-blank-line-before-`def` quirk at `:1991` / `:2875` is pre-existing (9 such sites across `bin/sc`, and B.3 Lint is SKIP) rather than introduced here.
- **Spec/design-fidelity**: 1 finding (CR-5 MINOR — a design item faithfully implemented, not drift), worst = MINOR. Every FR, every BC, K-1…K-19, I-1…I-6 and the frozen set verified against the code rather than against the developer's summary; the one recorded `DESIGN DRIFT` (D-1) is adjudicated and accepted; AC-B9 is BLOCKED by K-18 as declared upstream, not missing.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-1 | C-8's merged-`2>&1` byte-identity is established only by stage 4's own measurement; stage 5 corroborated the transcript against the code but executed nothing. If stage 6's HEAD-vs-candidate merged captures are not byte-identical, D-1's `bin/sc:2869` is the first line to re-examine. | `06_TEST_REPORT.md` |
| RES-2 | A-3's "the interleaving is unchanged" and K-13's byte-identity claim are false as written; the true statement is D-1's. The wording belongs to the solution-architect, and the mechanism belongs in the insight ledger with the corrected line number (CR-1). | `07_DELIVERY.md` |
| RES-3 | The fixture's `clash_api_port: 29090` is the live sing-box's port here, so a "fully redirected" `cmd_status()` step was answered by the running service (read-only). Stage 6 must pick a port it has proved free, or state that the only Clash call in the step is a GET (CR-3). | `06_TEST_REPORT.md` |
| RES-4 | The zh rule-set row's ASCII `, ` separator diverges from `sc doctor`'s localised `，` (CR-5). Fixing it costs one key plus one zh entry against a budget already at the ceiling. | `07_DELIVERY.md` as a follow-up pool row |
| RES-5 | `_status_view()`'s docstring (`bin/sc:856-857`) repeats F-14's false attribution (`generate_config()` destructures 3-tuples). Not corrected here — the line was not otherwise edited and the +80 ceiling was reached. | `07_DELIVERY.md` as a follow-up pool row |
| RES-6 | RS-5 is now observable in shipped output rather than hypothetical: a 36-hour-old file renders `1 days ago`. Deliberate per Q-11; a future task may add plural handling for every key at once. | `07_DELIVERY.md` as a follow-up pool row |
| RES-7 | RS-2 does not travel as written (F-13): `restart_service()`'s no-init-system arm is unreachable from `cmd_update_rules()`, confirmed against `is_running():2044` and the `regen_ok and is_running()` guard at `:2847`. Only the narrower true statement travels. | `07_DELIVERY.md` per C-7 |
| RES-8 | AC-B9 / P-6 was never observed and was not substituted; the whole of the evidence for "a non-zero exit makes the unit fail" is the unit-file read behind Q-7. | `07_DELIVERY.md` per C-7 |
| RES-9 | C-2 (the NFR cost reading, measured not asserted) and V-14 / BC-13 were both left to stage 6 by stage 4 and remain undischarged. | `06_TEST_REPORT.md` |
| RES-10 | The E-20 schema gap persists: `.harness/rules/70-doc-size.md` on this project defines no `## Stage-doc boundary rule`, so C-6's per-edit-id table has no declared section of its own. Stage 5 applied the stage-5 schema as written and carried C-6 as `## Design fidelity check` rows rather than inventing a section. Fourth stage to record it. | `07_DELIVERY.md` |
| RES-11 | RS-3 / Q-9 (`install.sh` step 6 re-labelling a non-download cause) is already filed and is restated here so no later stage re-raises it as a T-19 defect. | PM (already filed) |
| RES-12 | RS-6's durable declined approach — `ruleset-timestamp-outside-the-single-reader` — still owes a `.harness/rejected-decisions.md` record that no stage document may write. | PM, at task close |

## Verdict

APPROVED
