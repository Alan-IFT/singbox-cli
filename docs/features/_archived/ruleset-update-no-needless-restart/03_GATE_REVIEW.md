# 03 — Gate Review — ruleset-update-no-needless-restart (T-10)

- **Task**: T-10 · **Mode**: full · **Date**: 2026-07-31 · **Deferred-human**: `defer, do not ask`
- **Upstream**: `01_REQUIREMENT_ANALYSIS.md` = `READY` · `02_SOLUTION_DESIGN.md` = `READY`
- **Verdict**: **`APPROVED FOR DEVELOPMENT`** (framework equivalent: `APPROVED WITH CONDITIONS`) — conditions **C-1 … C-11** in §6 are binding, not advice.
- Repo root for every path below: `/home/alan/Programs/singbox-cli`.

> Transcription note (PM): the gate-reviewer agent runs with Read/Glob/Grep only and could not
> write this file. The content below is its deliverable verbatim; the PM transcribed it without
> editing findings, rulings, conditions or the verdict.

## 1. What was independently verified (not taken on trust)

Every path:line claim either stage made about existing code was opened and read. Result: **no citation in either document is wrong.**

| Claim (source) | Verified | Result |
|---|---|---|
| Unconditional restart tail | `bin/sc:1141-1143` | ✔ exact — see F-11 for an ordering detail neither document names |
| `restart_service()` = full restart, both inits | `bin/sc:834-838` | ✔ |
| `is_running()`, `clash_api()`, `generate_config()` | `bin/sc:864-870`, `:850-861`, `:721-831` | ✔ ranges exact |
| `srs_reject_reason` / `ruleset_status` / `ruleset_report` / `usable_tags` | `bin/sc:497-509`, `:512-528`, `:531-541`, `:544-546` | ✔ exact; `generate_config` destructures 3-tuples at `:804`, which is what makes `_status_view` load-bearing |
| 64 KiB chunk idiom + `head` accumulation to reuse | `bin/sc:688`, `:693-695` | ✔ `r.read(65536)`; the proposed `ruleset_state` body mirrors an idiom that already exists |
| Auto-elevate re-execs the installed binary | `bin/sc:77-78` | ✔ `os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] …)` |
| `LANG` is module state assigned in `main()` | `bin/sc:164`, `:1387-1389`, `t()` at `:211` | ✔ G-7's technique is sound |
| OpenRC periodic script runs the same command | `bin/sc:1217` | ✔ |
| `install.sh` step 6 consumes the exit status; step 7 runs `sc reload` | `install.sh:456`, `:479-492` | ✔ D-6 is correctly load-bearing |
| OpenRC service defines no `reload()` | `install.sh:412-431` | ✔ F-3 stands |
| `ExecReload=/bin/kill -HUP $MAINPID` | `systemd/sing-box.service:10` | ✔ |
| `CHANGELOG.md:15` asserts the restart | `CHANGELOG.md:15` | ✔ clause present verbatim; §6.5's replacement reads correctly **in context** (inside the `systemctl start …update.service` sentence) |
| `CHANGELOG.md:11` (T-02 entry) stays true | `CHANGELOG.md:11` | ✔ "补齐规则集后会自动重新生成配置并（在服务正在运行时）重启" remains true under B-6 — no edit owed |
| READMEs claim no unconditional restart | `README.md:12,84,114,118,150` + zh twin | ✔ §13's re-check correct; no README edit owed |
| Five pre-existing 3.7+ violations | `bin/sc:827`, `:869`, `:1176` | ✔ exactly five (`capture_output=` ×3, `text=True` ×2) |
| `dev-map.md` names `ruleset_status(path)` as the per-file adapter | `docs/dev-map.md:46-47` | ✔ — see F-9 |
| Decline records read and honoured | `.harness/rejected-decisions.md` (5 records) | ✔ `ruleset-unit-tests-in-t02` already carries T-10's re-occurrence (`:65-68`); `trust-singbox-fswatch-ruleset-reload` exists (`:81-102`) |

**Static probes of `/usr/local/bin/sing-box` re-run independently** (same tooling limits as stage 2 — `rg` over the binary, no shell):

| Probe | Stage 2 said | This review measured |
|---|---|---|
| `vehicleType` | absent | **0 matches** ✔ |
| `ruleCount` | absent | **0 matches** ✔ |
| `/providers/rules` | present | **1 match** ✔ |
| `route/rule/rule_set_local.go` | present | **1 match** ✔ |
| `watch rule-set file`, `reload rule-set ` | present | **1 match each** ✔ |
| `fswatch` / `fsnotify` linked | present | **39 matching lines** ✔ |
| `reloaded rule-set` | absent ("the success path is silent") | **0 matches** ✔ — *but* `updated rule-set ` and `rule-set updated` each match **1 line**, and `route/rule/rule_set_remote.go` is linked in. See §3 item 2 / F-3 of the ruling. |

## 2. Eight-dimension audit

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **WARN** | All 16 behaviours are decidable and every AC names a verification method, but two ACs specify a method that cannot establish what they assert: AC-24's `is-active` witness (F-2) and AC-21's `py_compile` (F-6). |
| 2 | Design completeness | **PASS** | Every in-scope behaviour B-1…B-16 has a named home, and all 20 boundary conditions are answered — BC-1…BC-19 in §4.4's trace and §7's case table, BC-12 in §10.2, BC-14 in R4, BC-20 in §6.4 + G-7. |
| 3 | Reuse correctness | **PASS** | Every reused symbol exists at the cited line with the cited shape; the one genuinely new capability (a content fingerprint) is correctly identified as having no existing implementation, and the "evaluated and not used" rows (Clash API, `ExecReload`) are backed by probes I reproduced. |
| 4 | Risk coverage | **WARN** | R1…R10 name the real risks including the one that already bit this project, but R9 claims more than the design delivers (F-4) and no row covers the doc-size gate the design itself trips (F-1). |
| 5 | Migration safety | **PASS** | Nothing is persisted, migrated or flagged: rollback is restoring one file, and the first post-upgrade run is provably a no-op when rule-sets are current. |
| 6 | Boundary handling | **WARN** | Null/empty/max/concurrency/error paths are all traced, but the digest's `None` contract is under-specified for the partial-read and zero-byte cases (F-5) — the one place the central invariant could be implemented wrongly. |
| 7 | Test feasibility | **WARN** | 24 of 25 ACs are mechanically testable with the T-02 recipe and AC-19 is correctly retired with a written reason, but G-2 as written cannot coexist with AC-7/AC-8 (F-3b) and G-4's witness is blind to the event it guards (F-2). |
| 8 | Out-of-scope clarity | **PASS** | §5/§13 enumerate the boundary file by file and the design declines three tempting adjacencies (loss-regeneration, `restart_service` exit status, watcher trust) with written records. |

No dimension is FAIL. All four WARNs are closed by conditions in §6.

## 3. Rulings on the four challenge items

### Item 1 — D-8: no committed test tree. **RULING: UPHELD (`bin/sc` + `CHANGELOG.md`).**

I am the actor entitled to widen AC-22, and I decline to widen it for tests.

1. **Committing a test is not one file, it is a project decision.** For a committed test to mean anything, `verify_all` B.2 must stop being SKIP (`.harness/rules/50-singbox-cli.md:34-38`), which requires a runner command, a `Test:` line in rule 50, a `tests/` layout and `baseline.json`'s `test_count`. That is T-07's scope. A test tree committed *without* wiring B.2 is strictly worse than none: a suite nobody runs, which lets the next task believe it is covered.
2. **Rule 85 argues against, not for.** The counter-rule forbids widening a task beyond the user's requirement; consolidation "re-homes scope between tasks, it never invents new scope". The harness is re-homed to T-07 by record, not discarded.
3. **Project history is consistent and honest about it.** T-02 changed config generation, added 346 lines and ran 846 QA assertions — none committed, deferred by a written record, which already carries T-10's re-occurrence (`.harness/rejected-decisions.md:65-68`). Overturning here would leave the *larger* change untested and the smaller one tested.
4. **R6's residual risk is bounded in-boundary.** The in-diff mitigation (a comment at the apply site naming the defect) is checkable at stage 5.

Conditions attached: **C-9, C-11**. If PM disagrees, the correct route is a T-07 priority bump, not a widened AC-22 here.

### Item 2 — F-4: "silent success ⇒ no evidence channel". **RULING: CONCLUSION SAFE; ONE EVIDENCE CLAIM OVERSTATED.**

The **decision** (restart, only on a real content change) is right. The **stated reason** is partly wrong, and that matters because it is now also in a `rejected-decisions.md` record a future task will read as fact.

- **F-2 is sound.** `/providers/rules` present with **neither** `ruleCount` **nor** `vehicleType` anywhere in the binary is good evidence that the route is a compatibility stub, not a rule-provider implementation — a Clash-Meta provider response cannot be serialised without those field names. With `sc`'s client only ever issuing `PUT /proxies/proxy`, "the Clash API cannot apply a local `.srs`" is a sound conclusion, not an inherited assumption.
- **F-4(c) is overstated.** "No `reloaded rule-set` literal; only failures log ⇒ **no channel at all**" does not survive its own method: `updated rule-set ` **and** `rule-set updated` are both present in the same binary, alongside `route/rule/rule_set_remote.go`. The honest statement is *"a success literal exists but cannot be attributed to the local-file path from strings alone."*
- **The conclusion survives anyway, for three reasons stage 2 did not use:**
  1. **Our own config closes the channel.** `generate_config()` emits `"log": {"level": "warn"}` (`bin/sc:746`), so any Info-level success line is never written on this project's hosts — independent of what the binary can print.
  2. **B-12 forbids a systemd-only oracle.** Reading a journal has no OpenRC counterpart, and `sc` contains no log-reading code at all.
  3. **F-4(a) is still open and fatal on its own.** Whether `fswatch` survives `tmp.replace(target)` (inode vs. dirent) is undetermined, so even a perfect oracle would not tell us the right thing happened for *our* write pattern.
- **F-1's fleet argument is the weakest link and should not be reused.** "A capability of one version is unsound for the fleet" holds only for capabilities that cannot be probed at run time — `sing-box version` and Clash `/version` are both probeable per host. The load-bearing constraints are (1), (2) and F-4(a).
- **No cheap evidence channel was missed.** I looked for four: the log path (closed by (1)+(2)), a provider-status read (F-2), a route-match probe (no such endpoint), and "restart-free by construction" (unfalsifiable — exactly D-1 candidate (c)).
- **Must a shell re-verify this? No** — nothing in the design depends on it, which is its main virtue. Optionally at stage 6, one context extraction (`grep -a -o '.\{0,60\}rule-set.\{0,60\}'`) can attribute the `updated rule-set ` literal; that is documentation accuracy, **not** a gate, and must not block. What must **not** happen is the tempting "just try it and see" experiment on this host — NFR-1 forbids it and the decline record's unblock path correctly requires a disposable host.
- **Cost of over-conservatism, honestly stated:** one restart per genuinely changed rule-set — the same restart today's code performs, so never worse than status quo (and see F-8: changes may be more frequent than E-13 implies, which raises the value of the deferred watcher work rather than of a different decision now).

### Item 3 — G-1…G-7. **RULING: G-1, G-5, G-6, G-7 CHECKABLE; G-2, G-3, G-4 NOT, AS WRITTEN.**

| Gate | Checkable? | Ruling |
|---|---|---|
| G-1 module load | Yes | Make it self-asserting: assert `mod.SYSTEMD is False`, `mod.OPENRC is False`, `str(mod.CFG_DIR).startswith(tmproot)` before the first call. |
| G-2 subprocess tripwire | **No** | Two defects — F-3(a), F-3(b). |
| G-3 scratch scripts | **No, as written** | "06 lists every script and shows the lines" is honour-system: a forgotten script is the T-02 failure mode, and a forgotten script is also the one that will not be listed. |
| G-4 live-service witness | **No** | `systemctl is-active` prints `active` before **and after** a restart — blind to the event it exists to detect. |
| G-5 nothing under `/etc/sing-box/**` | Partly | Unenforceable from inside the harness for paths that bypass it; make it observational — quote `ls -la --time-style=full-iso /etc/sing-box /etc/sing-box/rules` before and after, plus `find /etc/sing-box -newermt <stage-start>` empty at the end. |
| G-6 no network | Yes | Loopback stubs / stubbed `_fetch_to_temp`; assert the stub's request log accounts for every fetch. |
| G-7 both languages | Yes | `mod.LANG = "en"/"zh"` is valid (`bin/sc:164`); every outcome-line assertion runs twice. |

**(a) The scratch-script clause targets the right thing with the wrong mechanism.** The T-02 incident worked because a *non-root* agent can still restart the live service through exactly one door: `/usr/local/bin/sc` auto-elevates via the NOPASSWD sudoers entry scoped to that path (`bin/sc:77-78` + `/etc/sudoers.d/sc`). The mechanical form is therefore: (i) every verification command runs at a **non-root euid**, `id -u` quoted in `06`; (ii) nothing ever executes `/usr/local/bin/sc`, enforced by the PATH-shim layer rather than by promising; (iii) all module loading goes through **one** shared loader (T-02's `qalib.load_sc`), so "did this script neutralise the auto-elevate?" collapses to "does it import the loader?" — a grep over the whole scratch directory.

**(b) The deny-by-default `subprocess.run` tripwire is necessary but not sufficient, and as written it contradicts AC-7/AC-8.** It patches one module attribute, so `subprocess.Popen`, `check_call`, `os.system`, `os.execvp` and any re-import walk past it. T-02 used **two** layers (`06_TEST_REPORT.md` §1 F-3: module globals **plus** PATH-shim `systemctl`/`rc-service` binaries writing a marker file, asserted absent in every test file); the design cites that report as its recipe but reproduces only the weaker half. The second layer is also the only thing that covers G-3's unlisted script.

**(c) "Quote `systemctl is-active` before and after" is not a safety gate.** It is a *liveness* check, not a *non-interference* check; both readings say `active` even if the harness restarted sing-box twenty times — it would have passed *during* the T-02 incident. The check that detects the actual damage is process identity/start time: `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` before and after, asserted identical (OpenRC: pidfile contents). Keep `is-active` (AC-24 names it), but it cannot be the only witness.

### Item 4 — Concept economy and the `gained ⊆ changed` proof. **RULING: CONCEPT COUNT RIGHT; INVARIANT HOLDS, WITH ONE CONDITION.**

**Concept economy: correct.** Two facts from one query is the right number. Rule 85 test 2 is the binding test: a separate `ruleset_digest(path)` would re-implement the symlink / non-regular-file / EPERM branch a second time — the same failure mode as T-02's "`path.exists()` vs. a real usability judgment". The counter-rule also holds: two functions, one helper, one tuple field; no module, no class, no config key, one stdlib import. `_status_view` earns its existence at three call sites and keeps `usable_tags` / `generate_config` (which destructures 3-tuples at `bin/sc:804`) untouched — I verified that constraint is real, not a rationalisation.

**The invariant is TRUE.** Attacked with the boundary cases named in the challenge:

| Attempted counter-example | Before | After | In `changed`? |
|---|---|---|---|
| absent → downloaded | `absent`, `None` | `usable`, X | ✔ |
| **permissions fixed externally, bytes never changed** | `unreadable`, `None` | `usable`, X | ✔ `None ≠ X` — the digest is `None` because *we could not read*, not because the file was empty |
| directory / fifo / dangling symlink replaced | `unreadable`, `None` | `usable`, X | ✔ |
| **partially-written file completed** | `too-small`, D(300 B) | `usable`, D(700 B) | ✔ |
| bad-magic body replaced | `bad-magic`, D1 | `usable`, D2 | ✔ status is a pure function of the bytes (`srs_reject_reason(head, size)`), so equal digests would force equal status; contrapositive gives D1 ≠ D2 |
| 0-byte file → real file | `too-small`, sha256(b"") | `usable`, X | ✔ **provided the empty file gets a real digest, not `None`** |
| magic/floor reinterpreted mid-run | impossible (module constants) | — | — |

The proof rests on a property the design states only in prose: **`digest is None` ⟺ no complete read happened ⟺ status ∈ {`absent`, `unreadable`}**. If an implementation returns `None` for "zero bytes read" (a readable empty file) or a *partial* digest after a mid-stream `OSError`, the mapping breaks and with it the "exactly one apply per run" structural claim. That is F-5 / **C-5**. With C-5 satisfied, AC-4 really is structural.

One check the design does not make but which strengthens it: an invalid body is rejected *before* installation (`_fetch_to_temp` → `srs_reject_reason(head, got)` at `bin/sc:707`; `tmp.replace(target)` only on success at `:1107`), so a run can never itself create a bad-magic-but-changed file.

## 4. Findings (by severity)

**No BLOCKER findings.** Nothing requires redesign.

### MAJOR

**F-1 — `02_SOLUTION_DESIGN.md` is 559 lines; the project's own gate caps active task docs at 500, and AC-20 forbids new WARNs.** `verify_all.sh:223-231` (F.6) counts `0[1-7]_*.md` and `PM_LOG.md` under `docs/features` excluding `_archived/`, and **any WARN makes `verify_all` exit 1** (`:242-244`), which also fails the declare-done gate (`AI-GUIDE.md:87`). T-02's design landed at exactly 500 for this reason. **Owner: solution-architect** (`.harness/rules/70-doc-size.md`). The developer must **not** edit `02`. → C-1.

**F-2 — the NFR-1 live-service witness cannot detect a restart (AC-24 + G-4).** `systemctl is-active sing-box` returns `active` on both sides of a restart, so the criterion that exists because T-02 bounced the owner's live service would have passed during that incident. **Owner: `01` §7 AC-24 / §8 NFR-1.4 and `02` §11 G-4.** Not a rollback: AC-24 stays satisfiable and is strengthened, not contradicted. → C-2.

**F-3 — G-2/G-3 are weaker than the T-02 practice they cite, and G-2 conflicts with AC-7/AC-8.** (a) single-layer patching misses `Popen`/`check_call`/`os.system`/`os.execvp`/re-imports; (b) `generate_config()` shells out to `sing-box check` (`bin/sc:826`) and `is_running()` to `systemctl is-active` (`:866`), so a tripwire that raises on **any** call and forbids whitelisting `sing-box` makes AC-7/AC-8 unrunnable as specified; (c) G-3 relies on remembering to list every scratch script. **Owner: `02` §11.** → C-3, C-4.

### MEDIUM

**F-4 — R9 and §4.4 overclaim what the `usable in after` filter buys.** "Whatever we restart for, we restart only for a file sing-box will actually load" is false as a property of the *run*: if rule-set A is lost externally while B changes, the run restarts for B into a `config.json` that still defines A's missing path — T-02's `parse rule-set[0]: open …: no such file` FATAL, with `Restart=on-failure` looping. The filter prevents a restart *caused by* the loss, not a restart *during* a loss. Today's code restarts unconditionally in the same situation, so this is not a regression in a successful run — but see F-11. **Owner: `02` §9 R9 / §4.4.** → C-7.

**F-5 — the digest contract is under-specified exactly where the invariant depends on it.** "`None` when no bytes could be read" is ambiguous for (i) a readable empty file and (ii) an `OSError` after N bytes (a partial digest would be a content claim about bytes never fully read). **Owner: `02` §4.1.** → C-5.

**F-6 — AC-21's method cannot detect what AC-21 asserts.** `python3 -m py_compile bin/sc` on this host (Python 3.12 per T-02's report) accepts every 3.7/3.8 construct. The concrete hazard this change introduces is the walrus operator in a chunk loop (`while chunk := fh.read(65536)`) — the idiomatic way to write the very loop `ruleset_state` needs. T-02 solved this with banned-construct regexes over the added lines (its AC-26). **Owner: `01` §7 AC-21 (method), `02` §10.5.** → C-6.

**F-7 — extending `ruleset_status`'s body widens the failure surface of every existing caller, including `generate_config()`, which §3 lists as "not touched".** A file readable at byte 0 but faulting at byte 500 000 is `usable` today and `unreadable` after this change, so `generate_config()` would drop it and its routing rules. Arguably more truthful, and the accepted cost of R2 — but it is a behaviour change to a T-02-owned path that neither document states. **Owner: `02` §3 / §9 R2.** → C-7.

**F-8 — E-13's inference is a non-sequitur and has propagated into four documents.** `.harness/insight-index.md:15` states that the four **mirrors** serve byte-identical content — cross-mirror agreement at one instant. `01` E-13 converts it into "a successful re-download of unchanged bytes is the common case", and that reading is now in `02` §2.3, `.harness/rejected-decisions.md:73-76` and `PM_LOG.md:21-22`. Week-over-week stability of MetaCubeX rule-sets is **not** established by it. Consequences: (i) the mtime/size decline still stands on its real argument (a write-based signal is true on every successful run *regardless of frequency*), so no decision changes; (ii) no user-facing text may claim restarts are now rare — the `CHANGELOG.md` bullet in §6.5 was checked and correctly claims no such thing; (iii) if changes are frequent, the value of the deferred watcher work goes **up**. **Owner: `01` §2 E-13.** → C-9.

### LOW / NIT

**F-9 — `ruleset_status()` is retained because a document the task may not edit mentions it.** R10/A-2 keep a caller-less function to avoid drifting `docs/dev-map.md:46`. Keeping it may well be right (T-05 will plausibly call it), but *"AC-22 forbids editing the doc"* is an inverted dependency. This project has a real dev-map obligation — T-02's code reviewer audited it; T-09 recorded "no dev-map update was owed" as an explicit finding. → C-8 widens AC-22 by exactly one file so the call is made on merit.

**F-10 — comparison must be by tag, not by list index.** Both snapshots iterate `RULESET_FILES`, so positional pairing works today and would become a latent bug the moment that tuple changes.

**F-11 — a behaviour delta neither document names in its diff reading.** Today `sys.exit` at `bin/sc:1140` runs **before** the unconditional restart at `:1141`, so a run with any failed rule-set never reaches the restart. Under the new flow the apply block runs before the exit (correct per B-14/BC-9/T-02 ordering), so *"two changed, two failed"* now restarts where today it does not. Requirement-sanctioned and strictly narrower than today's behaviour on successful runs — but it is the one case where F-4's hazard is genuinely **new**. → C-7.

**F-12 — stale path in the PM dispatch prompt.** T-02's documents live at `docs/features/_archived/config-degrade-missing-rulesets/`. Both stage documents cite the archived path correctly; `.harness/rejected-decisions.md:26,53` still carries the old path (pre-existing, outside this boundary — do not fix here).

**F-13 — zh collision audit re-run independently: CLEAN.** All three new zh strings checked against `失败：`, `失败`, `成功`, `错误：`, `⚠️`, `已跳过`, and against every existing zh value in `TRANSLATIONS` — no collision; `规则集已更新：` / `规则集已恢复：` / `规则集更新失败` remain mutually distinguishable under any plausible grep. Bilingual parity holds: no `en` table exists (`bin/sc:84`), the English key *is* the output, all three keys are full sentences with identical placeholder sets. The 64 KiB insight applies to *download progress* fixtures only; the new sha256 loop reads a regular file, terminates on `b""`, and reusing the existing `65536` literal (`bin/sc:688`) adds no constant.

**F-14 — T-02 recovery preservation: CONFIRMED.** Re-homing the recovery block under `if changed and CFG_PATH.exists()` preserves unusable → usable ⇒ regenerate + apply, because `gained ⊆ changed` makes the outer guard strictly weaker than the old `if gained and CFG_PATH.exists()`. Inner order is preserved verbatim: `generate_config()` → restored line → `if regen_ok and is_running()` → restart, so a failed `sing-box check` still blocks the restart, the restored message still prints when the service is stopped, and the apply still precedes the non-zero exit. `README.md:118`'s promise survives.

## 5. Questions the developer will ask — pre-answered

**Q1. What exactly is `digest` when the file is unreadable half-way through?** `None`, always. Rule: `digest is not None` ⟺ the file was read to EOF without error. Any `OSError` at any point ⇒ `("unreadable", None)`; never a partial digest. A readable **empty** file is `("too-small", sha256(b"").hexdigest())` — a real digest, because zero bytes *were* read successfully. The whole invariant rests on this. (C-5.)

**Q2. Two `None` digests — same content or not?** Not the same; `changed_usable_tags` must treat `None != None`. It is safe because of the second half of the predicate: a tag not `usable` in `after` is excluded regardless, which is what makes BC-7 and BC-13 come out right. Do not "fix" it into equality — it would look tidier and break BC-6.

**Q3. Can I pair `before`/`after` positionally?** No — build `{tag: …}` dicts and compare by tag. (F-10.)

**Q4. The tripwire raises on every `subprocess.run`, but AC-7 needs `generate_config()` to succeed — do I whitelist `sing-box check`?** No. Stub module attributes: `mod.generate_config = lambda: True` (and `False` for the regen-failure outcome), `mod.is_running = lambda: True/False`, keeping the tripwire deny-by-default so any *unstubbed* shell-out is a hard failure. Config generation is T-02 territory, covered by re-running its fixtures. (C-4.)

**Q5. May I drop `ruleset_status()` now that nothing calls it?** Your call on merit, not on the doc boundary — C-8 widens AC-22 to allow `docs/dev-map.md`. If kept, the docstring must say why it has no in-tree caller; if deleted, update `dev-map.md:46` in the same commit. Record the choice in `04`.

**Q6. Should I skip the restart when a rule-set was lost mid-run, since I already have both snapshots?** **No — not in this task.** No AC asks for it, D-4/§5.6 put loss-driven behaviour out of scope, and today's code restarts in that situation anyway. Record it as an observed residual (C-7) and let PM decide whether it becomes a pool row.

**Q7. Can I use `while chunk := fh.read(65536)`?** No — walrus is 3.8; the floor is 3.6 (`.harness/rules/50-singbox-cli.md:103`). Use the `while True: … if not chunk: break` shape `_fetch_to_temp` already uses at `bin/sc:687-695`, including its `head = (head + chunk)[:len(SRS_MAGIC)]` accumulation. Do not add a sixth `capture_output=` / `text=` site.

**Q8. `verify_all` shows a WARN — did I break something?** Check F.6 first: it WARNs on `02_SOLUTION_DESIGN.md` (559 lines) until C-1 is done, and that WARN is not yours. Take the AC-20 baseline from a pristine `HEAD` (`git stash`) and compare deltas; say in `04` which WARNs pre-existed.

## 6. Conditions (binding — what stage 4 must satisfy and stage 5/6 can check)

| # | Condition | Owner | Checkable by |
|---|---|---|---|
| C-1 | Compact `02_SOLUTION_DESIGN.md` to ≤500 lines (content unchanged; reference rather than paste). The developer must not edit it. | architect / PM, **before stage 6** | `wc -l` ≤ 500; F.6 PASS |
| C-2 | The live-service witness records `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` (OpenRC: pidfile contents) before and after the whole verification run, both quoted and **identical**; `is-active` kept for AC-24 but not the sole witness. | dev + QA | quoted pairs in `04`/`06` |
| C-3 | Keep T-02's **two-layer** guard: module-level deny-by-default `subprocess.run` fake **and** PATH-prepended `systemctl`/`rc-service` shims writing a marker file, asserted absent at the end of every script. Every command runs at non-root euid with `id -u` quoted; nothing executes `/usr/local/bin/sc`; all module loading goes through one shared loader so G-3 becomes a grep, not a promise. | dev + QA | shim source + marker assertion pasted in `04`/`06`; grep over scratch scripts |
| C-4 | Resolve the G-2 ↔ AC-7/AC-8 conflict by stubbing `mod.generate_config` / `mod.is_running`, never by whitelisting `sing-box` in the tripwire. | dev | test source in `04` |
| C-5 | `ruleset_state`'s docstring **and** implementation state: `digest is None` ⟺ status ∈ {`absent`, `unreadable`} ⟺ no complete read; any mid-read `OSError` ⇒ `("unreadable", None)`; an empty readable file gets a real digest. Cover chmod-000, directory, dangling symlink, 0-byte and short-file fixtures. | dev | docstring + AC-13 fixtures |
| C-6 | No `:=`, no f-string `=`, no new `capture_output=` / `text=`; AC-21 verified by banned-construct regexes over the added lines (T-02's AC-26 technique), not `py_compile` alone. | dev + QA | regex list + output in `04`/`06` |
| C-7 | `04` records three residuals in its own words: (i) F-11's BC-9 delta, (ii) F-4's lost-rule-set restart hazard, correcting R9's absolute wording, (iii) F-7's widened failure surface for `generate_config()`. | dev | presence in `04` |
| C-8 | AC-22's product diff is widened by **exactly one** file: `docs/dev-map.md`, and only for accuracy of its rule-set rows (`:46-47`) — either update them to name `ruleset_state(path) -> (status, digest)` as the single reader, or state in `04` why no update is owed (T-09's form). No other file joins the diff. | dev | `git diff --name-only` ⊆ {`bin/sc`, `CHANGELOG.md`, `docs/dev-map.md`} |
| C-9 | No downstream document, code comment or user-facing string repeats (i) "sing-box logs nothing on a successful rule-set reload" as fact, or (ii) "re-downloading identical bytes is the common case" as a conclusion from the mirror insight. | dev + QA | grep of `04`/`05`/`06` + the diff |
| C-10 | The run-level outcome line is asserted **exactly once** on both exit paths (exit 0 via `Done`, and the `sys.exit` non-zero path) and in **both** languages. | QA | AC-3/AC-18 assertions |
| C-11 | D-8 stands: no committed test tree, B.2 stays SKIP with the recorded reason. In exchange the harness pasted into `06_TEST_REPORT.md` must be **complete and runnable verbatim** (whole files, no elisions, loader included), and R6's in-code comment naming the T-10 defect must be present at the apply site. | dev + QA | `05` greps the comment; `06` contains whole files |

## Verdict

**`APPROVED FOR DEVELOPMENT`** — framework equivalent `APPROVED WITH CONDITIONS`, conditions C-1 … C-11 binding. Neither `ROLLBACK TO REQUIREMENT-ANALYST` nor `ROLLBACK TO SOLUTION-ARCHITECT` is warranted: no finding requires re-deciding a behaviour or a structure. The two findings touching `01` (AC-24's witness, AC-21's method) strengthen those criteria rather than contradict them; the one structural finding against `02` (F-1, doc length) is a mechanical compaction that does not block coding and must complete before stage 6.

`BLOCKED: NEEDS-HUMAN` is **not** raised — no safety red line was reached. NFR-1 remains the most dangerous part of this task and must be restated verbatim in the developer and QA dispatch prompts, with C-2 and C-3 attached.

**Next:** Developer — implement `02` §10.5 in order, under C-1 … C-11.
