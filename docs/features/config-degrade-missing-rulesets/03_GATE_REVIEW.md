# 03 — Gate Review — config-degrade-missing-rulesets (T-02)

- **Task**: T-02 · **Mode**: full · **Date**: 2026-07-31 · deferred-human (no questions asked)
- **Upstream**: `01_REQUIREMENT_ANALYSIS.md` = `READY`, `02_SOLUTION_DESIGN.md` = `READY`
- **Verdict**: **`APPROVED FOR DEVELOPMENT`** — with 9 conditions (all WARN, none blocking)

> Persistence note (PM): the gate-reviewer agent ran without write tools in this session; this
> document is its returned output persisted verbatim by the PM Orchestrator. No PM edits.

---

## 0. What was actually verified in code

Every path:line claim in both upstream docs was checked against the working tree, not trusted.

| Claim | Verified |
|---|---|
| `RULESET_URLS` filename→absolute URL, 4 entries | ✅ `bin/sc:45-50`; only **two** consumers exist (`:45` def, `:807` loop) — the rename to `RULESET_FILES` cannot break a third site |
| `route.rule_set` = 4 unconditional entries | ✅ `bin/sc:530-539` |
| `route.rules` rule-set refs | ✅ `bin/sc:522,524,527,528` (each rule is exactly `{outbound, rule_set}`) |
| `dns.rules` **also** refs rule-set tags (E-4) | ✅ `bin/sc:497,498,501` (each is exactly `{server, rule_set}`) — E-4 is real and is the single most important finding in 01 |
| `tmp.write_bytes(r.read())` + `tmp.replace()` | ✅ `bin/sc:813-814` |
| Shared fixed temp name | ✅ `bin/sc:809` |
| Cause on **stdout**, count on **stderr** | ✅ `bin/sc:817` (`print`) vs `:821` (`sys.exit`) |
| `install.sh` redirect + exit-status branch | ✅ `install.sh:456-463`, `:479` |
| `t()` falls back to the English key, never aborts (E-10) | ✅ `bin/sc:172-174` — `TRANSLATIONS.get(LANG,{}).get(s,s)`, `.format` only when kwargs |
| `ls.idx` prints literally in English today | ✅ `bin/sc:642` — design's "no namespaced keys" rule is grounded |
| Auto-elevate at import, 2 lines (E-13) | ✅ `bin/sc:52-54`; sudoers `NOPASSWD:` with no `env_keep` ✅ `install.sh:437-441` |
| `main()` is `__main__`-guarded; import runs definitions only | ✅ `bin/sc:1089-1090`; `_init_files()` is called from `main()` only (`:1056`) — **importing does not touch `/etc`** |
| `RULES_DIR`/`CFG_PATH` referenced only inside function bodies | ✅ — post-exec global repointing (design §13) genuinely works |
| Timeout constants | ✅ `:583`=3, `:742`=8, `:812`=30 |
| Reuse targets exist | ✅ `t()` `:172`, ⚠️-to-stderr `:555`, `generate_config` `:455`, `reload_or_restart` `:567`, `restart_service` `:560`, `is_running` `:590`, `clash_api` `:576`, `cmd_reload` `:928`, argparse `:1069`, `HELP_EN:980` / `HELP_ZH:1025` |
| README anchor blocks | ✅ `README.md:103-111` / `README.zh-CN.md:103-111` are the matching "Ruleset update" / "规则集更新" blocks |
| verify_all F.6 = **WARN** (not FAIL) at >500 lines | ✅ `verify_all.sh:223-231` |
| `.harness/rejected-decisions.md` already carries the 3 declines | ✅ lines 17-45 |

**Design claim with no existing symbol:** `srs_reject_reason`, `ruleset_status`, `ruleset_report`, `usable_tags`, `_status_text`, `_filter_rules`, `_warn_degraded`, `_ruleset_bases`, `_clear_stale_temps`, `_fetch_to_temp` are all new — correctly declared new in §8's reuse audit ("none — `path.exists()` was the only notion"). Confirmed: no ruleset-usability predicate exists anywhere in `bin/sc` today. (§3 calls these "nine functions"; there are ten. Cosmetic.)

**Insight-index cross-check:** no entry contradicts the design. Line 11 (`sc update-rules` cause on **stdout**) is honoured by §5.2 and Q4. Line 10 (`install.sh`'s crash-prone `t()`) correctly does *not* transfer — E-10 proves `bin/sc`'s `t()` has different semantics, and this was verified in code. Line 12 (`systemd/sing-box-rules-update.service` → `/usr/local/bin/proxy`) is confirmed still broken (`systemd/sing-box-rules-update.service:7`) and correctly left to T-09.

---

## 1. The 8-dimension audit

| # | Dimension | Result | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | Every one of B-1…B-26 is a stated observable with a matching AC; the 32 boundary conditions cover the reported failure and its inverse (BC-17, "all bases fail but the file is already good"), and the 9 deferred decisions each carry a proceeding assumption, so nothing is unspecifiable. |
| 2 | Design completeness | **PASS** | Every in-scope behavior maps to a named function with a signature: B-1/B-2→`srs_reject_reason`+`ruleset_status`, B-4/B-5→`usable` set + `_filter_rules`, B-8→`_warn_degraded`, B-10…B-16→`_ruleset_bases`+`_fetch_to_temp`+§6.2, B-17→the `gained`/`CFG_PATH.exists()` block, B-18…B-20→§5.3, B-21/B-22→pid-suffixed temp + `_clear_stale_temps`, B-23…B-26→§5.4/§5.5/§2. No numbered behavior is left without a design. |
| 3 | Reuse correctness | **PASS** | Every reused symbol was opened and confirmed callable as described; the audit's *negative* claim (no prior usability notion) was independently verified by grepping the whole tree; and the "`sc reload` needs no change" claim was traced through `cmd_reload:928 → reload_or_restart:567 → generate_config:455` and is correct. |
| 4 | Risk coverage | **WARN** | R1-R9 are the real risks and R4/R5 show genuine care (CJK double-width erase, pid liveness). Three plausible risks are absent: transparent content-encoding, bases 2-4 never being validated against reality, and chunked-read timeout semantics. See F-6, F-7, F-8. |
| 5 | Migration safety | **PASS** | No persisted state, no schema, no flag needed — and §10.3's argument for *not* adding a flag ("the degradation path is the failure path; gating it would keep the bug reachable") is correct. Rollback is a file swap; a config generated while degraded is a strict subset that the old code re-expands. Legacy fixed-name `*.srs.tmp` debris is explicitly handled (§10.1). |
| 6 | Boundary handling | **WARN** | BC-1…BC-32 each have a designed answer, and the two hardest pairs are reconciled rather than hand-waved (BC-19 vs BC-20 via pid liveness; BC-17 vs BC-16 via disk-based re-judgement). Three edges need an implementation note the design does not give: multi-chunk magic accumulation, a malformed `Content-Length`, and PID reuse. See F-1, F-4, F-5. |
| 7 | Test feasibility | **WARN** | Every AC except AC-7 and AC-27 is executable with local stubs, and §13 gives a concrete, *verified-correct* module-loading recipe. Two seams are missing from the recipe (`systemctl` stubbing) and one AC is literally unpassable as written (AC-25 vs `.harness/rejected-decisions.md`). See F-3, F-9. |
| 8 | Out-of-scope clarity | **PASS** | 12 requirement exclusions + §11's design exclusions name the adjacent rows by ID (T-05, T-06, T-07, T-08, T-09, Q9's new row), so the developer has an explicit "not yours" list for every temptation adjacent to this diff. `install.sh`, `uninstall.sh`, `systemd/` are named untouched in three places. |

---

## 2. Rule-85 double check (both directions)

**(a) Is usability defined once?** Yes, structurally — not merely by assertion.
- One pure predicate `srs_reject_reason(head, size)` with three adapters: a path adapter (`ruleset_status`), a socket adapter (`_fetch_to_temp`), a screen adapter (`_status_text`).
- `generate_config()` calls `ruleset_report()` **once** and derives `usable` **once**; that single set feeds the definition list *and* both reference arrays. This is what makes finding #1 structural rather than diligent.
- The deletion test in §12 is real: remove `srs_reject_reason` and the magic/floor logic reappears in config generation, download validation and `sc doctor`.

**(b) Does the counter-rule hold?** Yes.
- No new file, module, package, config key, settings key, persisted state, dependency, or command. Two module constants, one predicate, one section header.
- The only surface additions are `--mirror` and `SB_RULES_BASE`, both required by B-14; the only new data shape is a tuple of pairs replacing a dict.
- Two spots to watch, both judged acceptable: `RULE_ANSWER_KEYS` and the "rule kept because it has another matcher" branch in `_filter_rules` are **dead code against today's config** (every rule-set rule at `:497,498,501,522,524,527,528` is exactly `{answer-key, rule_set}`). The design says so explicitly and justifies it by B-5's literal text. That is requirement-driven, not speculative — accepted. It stays acceptable only because it is ~4 lines; if it grows into a matcher taxonomy during development, that is scope creep.
- `_status_text` as a *function* rather than a dict (§3.2's "trap") is not generality — it is forced by `LANG` being assigned in `main()` after import (`bin/sc:1057`). Verified.

---

## 3. The nine specific verifications requested

### V-1 — No dangling tag references, in **both** arrays ✅ PASS
`_filter_rules(rules, usable)` keys off the presence of a `rule_set` key, not off which array the rule came from, and is called twice with the same `usable` object (§6.1). I enumerated every referencing site in the real code: `dns.rules` at `:497` (`geosite-google`), `:498` (`geosite-private`), `:501` (`geosite-cn`); `route.rules` at `:522` (`geosite-google`), `:524` (`geosite-private`), `:527` (`geoip-cn`), `:528` (`geosite-cn`). All seven are inside the two arrays the filter is applied to. **There is no third site in `bin/sc` that names a rule-set tag** (grep-confirmed: the only other occurrences of the tag strings are the `route.rule_set` definitions at `:531-538`, which are themselves built from the same `usable` set). AC-6's 16-subset property test is the right closure check.

### V-2 — Python 3.6 floor ✅ PASS
Every construct the design prescribes is 3.6-legal: f-strings (3.6), `frozenset(...)`, `os.getpid()`, `os.kill(pid, 0)` + `ProcessLookupError` (3.3), `Path.replace()` (3.4), `Path.is_symlink()`/`is_file()`/`stat()`, `open(Path, "wb")` (3.6), `print(..., end="", flush=True)` (3.3), `argparse action="append"`, `str.rstrip`, `sys.stdout.isatty()`. No walrus, no `dict |`, no positional-only params, no f-string `=`, no `capture_output=`, no `missing_ok=`. Standard library only. The one 3.8-ism inside the rewritten region (`unlink(missing_ok=True)`, `bin/sc:819`) is explicitly removed (Q9). Design also correctly refuses to depend on dict ordering by using a tuple of pairs.
**Correction to upstream fact (non-blocking):** E-12 says `capture_output=` appears at **two** sites; there are **three** — `bin/sc:553`, **`:595`** (`is_running()`, OpenRC branch), `:857`. Neither doc is wrong about *this task's* obligation (none of the three is rewritten; `is_running()` is called, not modified, so B-25 holds), but **Q9's pool row must be filed with three sites, not two**, or `:595` will be missed.

### V-3 — Timeout constants and the aggregate budget ✅ PASS (claim verified, and it is stronger than stated)
`:583`, `:742`, `:812` keep their values; `30` moves into `_fetch_to_temp` unchanged.
The design's worst case ("file 1 pays 4×30 s, files 2-4 pay 0") understates the general bound. The correct invariant is: **a failed attempt always adds its base to `dead`, and a base can be added to `dead` at most once per run, so the number of timeout-paying attempts in a whole run is ≤ `len(bases)`, independent of file count.** The adversarial case named in the review brief — base succeeds for file 1, fails for file 2 — is covered: base1 ok(f1) → base1 timeout(f2)=30 s, dead → base2 ok(f2) → base2 timeout(f3)=30 s, dead → base3 ok(f3) → base3 timeout(f4)=30 s, dead → base4 ok(f4). Total penalty 3×30 = 90 s ≤ 4×30 = 120 s. **The bound holds.** No ~8-minute (16×30 s) hang is reachable with the default list.
Two qualifications, both acceptable: (i) a user-supplied `--mirror` list of N bases raises the bound to N×30 s — user-chosen, and Q3's "replace, don't prepend" keeps N small; (ii) `timeout=30` is a socket timeout, not a transfer deadline, so a slow-trickling server can still exceed the bound — but that is **identical to `main`'s behavior** (`r.read()` uses the same per-recv timeout), so it is not a regression introduced here.

### V-4 — The stdout/stderr split ✅ PASS
§5.2 tabulates it and the composed multi-base cause is substituted into `{e}` of the **existing** `t("failed: {e}")` `print()` — same stream, same line shape, so T-01's `install.log` reader and the insight-index invariant both survive. Aggregate stays on stderr via `sys.exit` (`bin/sc:821` reused verbatim). Q4 routes the *new* degradation warning to stderr and correctly scopes the insight-index rule to `update-rules` per-file causes. `install.sh:456` merges `2>&1` so nothing is lost at install time either way.

### V-5 — Non-TTY degradation ✅ PASS
`tty = sys.stdout.isatty()` computed once and threaded into `_fetch_to_temp`; §5.3 fixes the non-TTY shape as byte-identical to today (one `  ↓ f ... ` prefix + one completion, no `\r` anywhere), and the multi-base cause is deliberately kept on **one line** so AC-15's "exactly one completion line per rule-set" stays literally true. Both non-TTY consumers are real and confirmed: `install.sh:456` (redirect to `install.log`) and the OpenRC periodic script written by `bin/sc:898`. (The systemd timer is currently a no-op because of the `/usr/local/bin/proxy` defect — T-09 — so B-19's systemd rationale is forward-looking; the OpenRC and installer paths make it binding today regardless.)

### V-6 — Atomicity ✅ PASS
`_fetch_to_temp` validates *before* returning and "never touches the rule-set's real path"; the caller does `tmp.replace(target)` only on a clean return, and unlinks `tmp` on any exception. Same-directory temp ⇒ `replace()` is a true atomic rename. BC-17/BC-18/BC-29 all follow. Collision safety comes from the pid suffix (E-6's real defect at `bin/sc:809`).

### V-7 — The size-floor decision ✅ PASS, reasoning holds
The asymmetry argument is correct and decisive: a floor that is too **low** is caught downstream (magic rejects HTML, Content-Length equality rejects truncation, `sing-box check` is the final gate, and the next base is tried), whereas a floor that is too **high** silently and *permanently* rejects a correctly downloaded file — reproducing the exact bug T-02 exists to remove, with no recovery path. `geosite-private` compiles from a handful of suffixes and plausibly lands in the low hundreds of bytes, so 512 is a real hazard, not a hypothetical one. The binding constraint — *the floor must stay strictly below the smallest real rule-set* — is stated in three places (Q1, the constant's code comment §3.1, `rejected-decisions.md:23-24`) and is testable by AC-27, with the escalation rule ("never raise without the measurement") written down. This is the right shape for a decision that cannot be closed offline.

### V-8 — Testability without network ✅ PASS (with one gap, F-3)
The §13 recipe was validated against the real file: replacing the single line `bin/sc:54` with `pass` leaves `if os.geteuid() != 0:` syntactically valid; module-level execution is definitions plus `shutil.which` probes only; `_init_files()` is reachable **only** from `main()`, which is `__main__`-guarded — so `exec()`-loading the source touches nothing under `/etc`. `CFG_DIR`/`CFG_PATH`/`NODES_PATH`/`SETTINGS_PATH`/`RULES_DIR` are referenced exclusively inside function bodies, so post-exec repointing works. sudo `env_reset` (BC-25) is a *runtime* constraint only — an in-process harness sets `os.environ` directly, so AC-21 is executable. Bonus determinism the design did not claim but that holds: because `main()` never runs, `CLASH_PORT` stays at `CLASH_PORT_BASE` (29090), so AC-3's JSON baseline comparison is stable.

### V-9 — Scope boundary ✅ PASS
§2 confines production changes to `bin/sc` + `CHANGELOG.md` + both READMEs; `install.sh`, `uninstall.sh`, `systemd/*`, `verify_all.sh`, `CONTEXT.md` are named untouched. No `sc doctor`, no `sc config --show`, no new command. The only judgment call — declining to wire `verify_all` B.2 despite rule 50's "first real task must replace the SKIP" — is explicitly reasoned, routed to T-07, and recorded as a *deferral* (not a rejection) in `rejected-decisions.md:37-45`, with the harness handed forward rather than discarded. Accepted.

---

## 4. Findings (conditions on the approval)

All findings are **WARN**. None blocks. F-1 through F-5 are implementation conditions the developer must satisfy; F-6 through F-9 are for QA/PM.

**F-1 · WARN · Design §3.4 (`_fetch_to_temp`) — the SRS magic must be accumulated across chunks.**
`read(65536)` may legally return fewer than 3 bytes on the first call (short read, slow trickle, `file://`). An implementation that snapshots `chunk[:3]` from the first chunk will report `bad-magic` for a perfectly good file. The predicate signature already anticipates this (`head -- may be shorter than SRS_MAGIC or empty`), but the design never states the accumulation rule, and this is the one bug in this task that would look exactly like the bug being fixed.
**Condition:** accumulate `head = (head + chunk)[:len(SRS_MAGIC)]` while `len(head) < len(SRS_MAGIC)`, and add a stub-server case that delivers a 1-byte first chunk to AC-16/AC-17's fixtures.

**F-2 · WARN · Design §5.4 vs Requirement B-8 — the composition of `{names}` is unspecified.**
B-8 requires the warning to name "which ones they are"; §5.4 gives only `{names}` and never says whether it is `geoip-cn, geosite-cn` or `geoip-cn (missing), geosite-cn (not a rule-set file)`. `_status_text` exists and its four phrases are translated, but on the config side it would then have no consumer.
**Pre-answer (developer may proceed on this):** render `{names}` as `tag (t(status-phrase))`, comma-joined. It is the only reading under which `_status_text` earns its place on the config side, and it is the only way BC-5's "an HTML error page is sitting on disk" is distinguishable from BC-1's "the file is missing" in the warning — which is exactly the actionability B-8 is asking for.

**F-3 · WARN · Design §13 — the test recipe stubs `sing-box` but not `systemctl`/`rc-service`.**
`is_running()` (`bin/sc:590-596`) and `restart_service()` (`:560-564`) shell out unconditionally when `SYSTEMD`/`OPENRC` are true, and both are evaluated at import from the *real* PATH (`bin/sc:34-35`). AC-22's recovery path calls both. On a developer box that has systemd and a real `sing-box` unit, running the harness can restart the developer's actual service.
**Condition:** the harness must either set `mod.SYSTEMD = mod.OPENRC = False` after exec, or put `systemctl`/`rc-service` stubs on PATH (T-01's technique). Record whichever was used in `06_TEST_REPORT.md`.

**F-4 · WARN · Design §3.4 / B-12 — a malformed `Content-Length` must not crash the run.**
"when the response declares a content length" implies `int(r.headers.get("Content-Length"))`, which raises `TypeError`/`ValueError` on `None` or garbage. Inside `_fetch_to_temp` this becomes an ordinary base failure (caught by the caller's `except Exception`) — tolerable — but it would be reported with a Python type-error string rather than a cause, and it would mark a base dead on a header quirk.
**Condition:** parse defensively; treat an unparseable header as "no declared length" (BC-14 path), not as a failure.

**F-5 · WARN · Design §9 R5 vs Requirement BC-20 — PID reuse defeats stale-temp cleanup, and the legacy temp name has no PID.**
R5 skips any temp whose PID suffix is a live process. On a busy host a recycled PID makes a genuinely stale temp permanently un-cleanable, which contradicts BC-20's absolute "is removed when that rule-set is next fetched". Separately, §10.1 requires removing the legacy fixed-name `geoip-cn.srs.tmp` (`bin/sc:809`) — which has **no** parseable suffix at all.
**Condition:** (a) treat an absent or non-integer suffix as stale and remove it; (b) accept PID-reuse as a residual (the only cost is debris — `ruleset_report()` iterates `RULESET_FILES`, so a `.tmp.N` file can never be *mistaken* for a rule-set, which is BC-20's load-bearing half and is structural); (c) **QA must generate AC-20's stale-temp fixture with a PID known to be dead**, or the test is flaky by construction.

**F-6 · WARN · Design §9 — missing risk: transparent content-encoding on a proxying mirror.**
If any base (realistically `ghfast.top`, a third-party GitHub proxy) returns `Content-Encoding: gzip`, `urllib` does not decode it, so the body fails the magic check for *all four files* and that base is marked dead run-wide. The design's own machinery handles it gracefully (reject → next base → cause names the base and says "not a rule-set file"), so this is a gap in the risk table, not in the code.
**Condition:** do **not** add an `Accept-Encoding` header (urllib sends none by default — keep it that way); note the failure signature in `06_TEST_REPORT.md` so a future report of "not a rule-set file from every mirror" is diagnosable.

**F-7 · WARN · Requirement AC-27 + Design §7 Q1 — bases 2, 3 and 4 are never validated against reality by any criterion.**
AC-27 exercises "the default **first** base" only; AC-11's fallback ordering uses stub servers. The four base URLs have different structural forms — jsDelivr's `/gh/OWNER/REPO@BRANCH/PATH` (bases 1-2) vs the `ghfast.top/<full raw URL>` prefix (base 3) vs plain raw (base 4). Static inspection says all four are well-formed and base 4 reconstructs today's effective URL exactly (`raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo` + `/geoip/cn.srs` ≡ the current `github.com/.../raw/sing/geo/geoip/cn.srs` after its 302), but a path-layout typo in base 1, 2 or 3 would ship undetected and only surface as a silent extra 30 s on a user's machine.
**Condition:** where any network exists, fetch one file from **each** of the four bases by hand and record the result; otherwise report all four as **unverified** and carry it as a residual risk alongside the AC-27 floor measurement.

**F-8 · WARN · Design §6.2 — recovery can restart the service during an `install.sh` re-run (the documented upgrade path).**
BC-27 covers only the *fresh* install (no config ⇒ guard holds). On a re-run, `CFG_PATH` exists and the service is typically running, so step 6's `sc update-rules` will regenerate the config and `restart_service()` before step 7's `sc reload` regenerates and restarts again. Harmless (both restarts land in `LOG_SINK`, `install.sh` is untouched, idempotency is preserved), but it is a behavior change no boundary condition enumerates and it will surprise whoever reads the install log.
**Condition:** none — proceed as designed; record the double restart in `06_TEST_REPORT.md` so it is not later reported as a defect.

**F-9 · WARN · Requirement AC-25 is literally unpassable as written.**
AC-25 asserts the diff touches only four files, but `.harness/rejected-decisions.md` has *already* been modified by stage 2 (lines 17-45) and `docs/features/**` will grow. Design §2 pre-empts this ("harness bookkeeping is outside AC-25's product diff") and cannot amend the requirement.
**Condition:** QA evaluates AC-25 against the **product** diff (`bin/sc`, `CHANGELOG.md`, `README.md`, `README.zh-CN.md`), excluding `.harness/` and `docs/`, and says so in the test report. The load-bearing half — `install.sh`, `uninstall.sh`, `systemd/*` byte-identical to `main`, and no timeout constant changed — is unaffected and must be asserted strictly.

**Trivia (no action):** §3 says "nine functions", lists ten. `02_SOLUTION_DESIGN.md` is 501 lines ⇒ `verify_all` F.6 emits a WARN; F.6 is a WARN-level check so AC-1's `FAIL: 0` is unaffected, but the run will exit 1.

---

## 5. High-probability developer questions — pre-answered

**Q. "`route.rule_set` empty — delete the key or emit `[]`?"**
Delete it (§4). `rule_set` is optional in sing-box, and an absent optional field is the safest form. B-4 permits either, so if a `sing-box check` on some build ever rejects the omission (R2), switching to `[]` is a one-line change requiring no doc update. Exercise this under AC-7 before assuming.

**Q. "Do I filter `dns.rules` and `route.rules` with one function or two?"**
One — `_filter_rules(rules, usable)` called twice with the *same* `usable` object. This is the whole point of finding #1: if the two arrays are filtered by two code paths, a future added rule in one array can drift. Do not add an `array_name` parameter.

**Q. "A rule ends up with an empty `rule_set` — drop the rule or drop the key?"**
Drop the whole rule, **unless** it carries a matcher outside `RULE_ANSWER_KEYS ∪ {rule_set}`, in which case delete only `rule_set`. For today's config the second branch never fires — all seven rule-set rules (`:497,498,501,522,524,527,528`) are exactly `{answer-key, rule_set}` — but B-5 mandates the branch. Keep it to ~4 lines; do not grow a matcher taxonomy.

**Q. "Should the degradation warning print on `sc ls` / `sc status` too?"**
No. It fires inside `generate_config()`, so only commands that regenerate emit it: `add`, `rm`, `use` (when it regenerates), `mode`, `default-tun`, `reload`, and the `update-rules` recovery path. B-8 says "every time a degraded config is generated" — that is the boundary. Adding a warning to read-only commands is scope creep.

**Q. "`update-rules` partially succeeded — do I regenerate before or after `sys.exit`?"**
Before (§6.2). A 3-of-4 recovery must still repair the config; exiting first would strand it. Note the resulting composite output — "Rule-sets restored: …" on stdout, the degradation warning for the remaining one on stderr, then the aggregate count on stderr — is intended, not a conflict.

**Q. "Recovery ran but `sing-box check` failed — still print 'Rule-sets restored'?"**
Yes; `generate_config()` writes the file before checking, so "config regenerated" is literally true and the check failure surfaces on stderr as `⚠️ Config check failed` (`bin/sc:555`). Only the restart is gated on `ok`. Do not invent a third message.

**Q. "Can I use `contextlib.suppress` / `dataclasses` / an `Enum` for the status token?"**
`contextlib.suppress` is fine (3.4) but adds nothing; `dataclasses` is 3.7 — **banned** by B-25; an `Enum` is 3.4-legal but is exactly the over-build rule 85's counter-rule forbids. The status is a `str`. Four call sites compare it to `"usable"`; one formats it.

**Q. "Should `--mirror` fall back to the defaults if the named mirror fails?"**
No — Q3/BC-24. `--mirror` replaces the list. Silent fallback would make it useless as a diagnostic and make AC-21 untestable.

**Q. "Add a progress-redraw throttle so fast downloads don't flicker?"**
No — §5.3 forbids it explicitly. A throttle lets a fast local stub produce zero intermediate states and makes AC-16 unpassable. One redraw per 64 KiB chunk.

**Q. "Namespaced translation keys like `ruleset.absent`?"**
No — §5.4. `TRANSLATIONS` has no `en` table, so `t()` returns the key verbatim in English; `bin/sc:642` already prints the literal `ls.idx` today because of this. Every new key must be readable English prose.

**Q. "May I fix `capture_output=` at `:553`/`:595`/`:857` while I'm in there?"**
No — Q9, a separate pool row. Note for PM: that row must list **three** sites, not the two E-12 claims.

---

## 6. Residual risks carried into development

| Risk | Owner | Closure |
|---|---|---|
| `SRS_MIN_BYTES = 16` never measured against a real `geosite-private.srs` | QA (AC-27) | Requires network; report **unverified** if unavailable. Raising the floor without the measurement is forbidden. |
| Bases 2-4 never fetched from for real (F-7) | QA | Manual per-base fetch where network permits; otherwise unverified. |
| `sing-box check` acceptance of an absent `rule_set` key across all 16 subsets (R2/AC-7) | QA | Requires a `sing-box` binary; otherwise unverified. |
| PID reuse leaving temp debris (F-5) | Accepted | Cost is debris only; the "never mistaken for a rule-set" half is structural. |
| systemd weekly timer still points at `/usr/local/bin/proxy` | T-09 | Out of scope; B-19 remains justified by OpenRC + `install.sh`. |

---

## Verdict

**`APPROVED FOR DEVELOPMENT`**

The requirement is complete and testable; the design covers every numbered behavior with a named function and a contract; the reuse audit is accurate in both its positive and its negative claims; the dangling-reference problem is solved *structurally* in both arrays rather than by discipline; the time-budget claim survives the adversarial case and is in fact bounded more tightly than the design states; the stdout/stderr split, the Python 3.6 floor, the three fixed timeouts, atomicity, non-TTY degradation and the scope boundary all hold under code inspection; and the size-floor reasoning is sound with its binding constraint stated in three places and an explicit rule against raising it unmeasured.

Nine WARN-level conditions apply. F-1 (accumulate the magic across chunks), F-3 (stub `systemctl` in the harness), F-4 (defensive `Content-Length` parse) and F-5 (unparseable temp suffix = stale) are implementation conditions the developer must satisfy. F-2 is pre-answered and the developer may proceed on it. F-6…F-9 are QA/PM record-keeping. None warrants a rollback.

**PM follow-up:** Q9's new pool row must name **three** `capture_output=` sites — `bin/sc:553`, `:595`, `:857` — not the two recorded in E-12.
