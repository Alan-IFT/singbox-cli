# 06 — Test Report · T-20 `doctor-extended-checks`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

## Test plan

Suite rebuilt at this stage from `01`'s criteria and from `bin/sc` itself; no assertion and no
line number inherited from `04_DEVELOPMENT.md` (RES-10). Files are under `test/t20/`
(gitignored, like the existing `test/step7/`); run with `bash test/t20/run.sh`.

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-B1 stale rule-set → PROBLEM naming age + refresh command | `90 days` [D]; current-mtime control [A]; 59/60/61-day boundary; summary lifts to PROBLEM | `test/t20/t_rulesets.py` |
| AC-B2 drift record ≠ document → PROBLEM naming the override | differing digest [D]; matching [A]; absent [A]; empty [A]; non-digest ⇒ PROBLEM (Q-9) | `test/t20/t_drift_ipv6.py` |
| AC-B3 AAAA decision vs document, both directions | doc suppresses + host has global v6 [D]; mirror [D]; 4 agreeing controls (`auto`×2, `on`, `off`) [A] | `test/t20/t_drift_ipv6.py` |
| AC-B4 stored delays | `/proxies` without history [D]; with delays [A]; the GC-4 vacuity twin | `test/t20/t_clash.py` |
| AC-B5 DNS lookup | `Answer` [A]; P-3's NXDOMAIN body [D]; stub sleeping past the socket timeout [D] | `test/t20/t_clash.py` |
| AC-B6 `config.json.bak-<date>` at 0644 (R-10's instance) | [D] named with `644` + `chmod 600`; same file at 0600 [A]; file-mode boundary 600/640/604/601/700 | `test/t20/t_perm.py` |
| AC-B7 configuration directory at 0777 (R-11's instance) | [D] named with `777` + `chmod go-w`; dir-mode boundary 755/775/757/705/777 [A]+[D] | `test/t20/t_perm.py` |
| AC-B8 wholly healthy fixture | GC-1(a)(b)(c)(d) asserted separately; +5 vs a HEAD **clone** run on the same root | `test/t20/t_healthy.py` |
| AC-B9 `sc lang zh` | stale row, five PROBLEM rows, two detail lines, the healthy five, two UNKNOWN rows | `test/t20/t_zh.py` |
| AC-B10 creates/modifies/removes nothing | full snapshot (existence, size, mtime, sha256, mode) before/after; no config dir created; 9 writer raisers silent + 2 positive controls | `test/t20/t_readonly.py` |
| AC-B11 each new probe failed independently | 5 sub-runs; all nine `DOCTOR_SECTIONS` labels printed, normal exit, no traceback | `test/t20/t_readonly.py` |
| AC-B12 API unreachable while the service runs | both rows UNKNOWN; a witness stub on another port proves no request was issued | `test/t20/t_clash.py` |
| AC-B13 symlink to a 0777 file outside the root | reported as a link; the string `777` absent from stdout; PQ-2 mixed case | `test/t20/t_perm.py` |
| **AC-B14 shipped invocation as root on the live host** | **not obtainable — BLOCKED and filed**, see `## Defects found` | — |
| AC-S1 each fact stands on its owner's call | GC-5's four deletion runs + an AST call-graph read (one call site per owner) | `t_readonly.py`, `t_static.py` |
| AC-S2 no second opinion | AST sweep: no `st_size`/`getmtime` node, 2 mode reads only, 1 `ipv6_decision()`, 0 `_dns_overlay()`, 2 `clash_api()` both GET, no `try` around either | `test/t20/t_static.py` |
| AC-S3 one ordering table + FR-12 | all five precedence pairs + "permissions last" on one healthy capture | `test/t20/t_healthy.py` |
| AC-S4 no writer reachable | transitive call graph from the 9 probes (33 functions) ∩ writers = ∅; no mutating attribute call | `test/t20/t_static.py` |
| AC-S5 strings | +28/−3 zh delta, placeholder parity per key, no `失败`, no `ls.`-style key, no CJK in a key | `test/t20/t_static.py` |
| AC-S6 nothing else moved | AST equality vs HEAD for `DOCTOR_EXIT`/`MARK`/`MSG_LINES`/`CRED_MODE`/`_doctor_print` + 11 frozen functions; timeouts 8/30/3 unchanged | `test/t20/t_static.py` |
| AC-S7 diff touches only declared files | `git status` + `git diff --numstat` + `--cached` read, below | `test/t20/t_static.py` |
| AC-S8 no credential byte in any row | three planted literals (nodes/config/override) absent from stdout | `test/t20/t_healthy.py` |
| AC-S9 one threshold constant | defined at `:102`, exactly one reader at `:2511` inside `_doctor_rulesets`, value 60 | `test/t20/t_static.py` |
| K-5 / V-11 emitted bytes unchanged | `generate_config()` HEAD vs candidate, 4 decision states, one root + one pinned port | `test/t20/t_v11.py` |

Result: **317/317 assertions pass**, in 3 consecutive full runs.

## Adversarial tests

One predicted failure per criterion, written before the run. Reproducers are mine; ≤5 lines cited
per row, full runs in `06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (tool output) |
|---|---|---|---|
| AC-B1 | the verdict and the phrase come from different reads, so at 60 days exactly they disagree | `t_rulesets.py` boundary 59/60/61 d (NEW) | Survived — `[OK] … 59 days ago` / `[PROBLEM] geoip-cn.srs: usable, 203 bytes, 60 days ago — run \`sc update-rules\` to refresh` |
| AC-B1 control | the age is rendered only on stale rows, which AC-B1 + its control + AC-B8 all tolerate (F-10) | GC-9 capture on a healthy fixture (NEW) | Survived — `[OK] geosite-google.srs: usable, 203 bytes, 0 seconds ago` |
| AC-B2 | a non-digest record reads "unknown" rather than "drifted", contradicting Q-9 | `.config.sha256` = `not-a-digest` (NEW) | Survived — `[PROBLEM] config drift: changed since sc generated it — keep the change in …/override.json, then run \`sc reload\`` |
| AC-B3 | the membership test is position-blind, so a document carrying the rule at index 3 reads OK while suppression is not in force in `global`/`direct` (RES-1) | 3 decoy rules prepended (NEW) | **Reproduced** — `[OK] IPv6 (AAAA): … config.json carries this decision`. Pre-recorded as CR-2/RES-1; filed MINOR below |
| AC-B4 | `is_running()` returns False from its final line, so candidate and control agree and no `/proxies` is issued (F-3) | same fixture with / without `sc.SYSTEMD = True` (NEW) | Survived with the flag — stub log `['/configs', '/proxies', '/dns/query?name=api.ipify.org&type=A']`. Without it: `[PROBLEM] node delays: 0/2 …` and log `['/configs', '/dns/query?…']` — the vacuous twin |
| AC-B4 | a live API + no init system makes the row assert a count it never read (BC-11) | `SYSTEMD=OPENRC=False`, stub answering with delays (NEW) | **FAILED the criterion's spirit** — row says `0/2 nodes carry a stored delay` though `/proxies` holds two. Filed MINOR (DEF-1) |
| AC-B5 | "no answer" and "no records" are the same body, so one branch is unreachable | P-3's real NXDOMAIN body vs a 4.5 s stub (NEW) | Survived — `[PROBLEM] … returned no records after 0 ms` vs `[PROBLEM] … no answer for api.ipify.org after 3003 ms`; no row contains `3s`, `timeout` or a bound |
| AC-B5 | the row can read `[OK]` from the install's own DNS cache, which the run itself warms (RES-2) | 4 read-only `GET`s on the live `127.0.0.1:29090` (NEW) | **Reproduced and sharpened** — `query 1: 175 ms authority-TTL=[1800]` / `query 2: 4 ms authority-TTL=[1796]`; `api.ipify.org` TTL `195 → 190 → 186`. Filed MINOR (DEF-2) |
| AC-B6 | an enumerated sweep misses a hand-made backup name | `config.json.bak-2026-08-01` at 0644 (NEW) | Survived — `…/config.json.bak-2026-08-01 is mode 644 — run: chmod 600 …`; `settings.json` (also 0644) never named |
| AC-B7 | the row fires on the world-readable mode every host has, or misses group-write | dir modes 755/775/757/705/777 (NEW) | Survived — 755 and 705 `[OK]`; 775, 757, 777 `[PROBLEM] … is mode 777 — run: chmod go-w …` |
| AC-B8 | the fixture cannot make the five unowned sections green, so the exit clause forces a weakened row-level clause (F-4) | healthy fixture + HEAD-clone diff (NEW) | Survived — 16 → **21 rows (+5)**, every new row `[OK]`, none names a path or a next step, **exit 0**, no partial to report |
| AC-B9 | zh renders vacuously because only `sc.LANG` is set and English satisfies "no 失败" | `sc.LANG="zh"` **and** `lang: zh` in the fixture's own `settings.json`, asserting CJK per row (NEW) | Survived — `[异常] 节点延迟: 0/2 个节点有已记录的延迟 —— …请查看 \`sc ls\``; markers `[正常]/[异常]/[未知]`; 0 `失败` |
| AC-B10 | the fixture's own loader creates the directory, so "created nothing" is unmeasurable | 9 writer raisers + 2 positive controls (NEW) | Survived — snapshot of 12 entries identical; no raiser fired; controls **did** fire (`_init_files`, `save_settings` via `sc mode global`) |
| AC-B11 | one failing probe costs another section its label | 5 independent failures (NEW) | Survived — all nine section labels printed in every run, exit ∈ {1,2}, no traceback |
| AC-B12 | a "closed port" fixture is answered by the live instance (29090) | witness stub on a *different* proved-free port (NEW) | Survived — both rows `[UNKNOWN] … not probed — the Clash API did not answer`; witness log `[]` |
| AC-B13 | `stat` follows the link and prints the target's mode | symlink → 0777 file outside the root (NEW) | Survived — `… is a symbolic link; sc never creates one here — check it with: ls -l …`; `777` absent from stdout |
| AC-B14 | — | — | **BLOCKED**, not obtainable (K-18); filed, never substituted |
| AC-S1 | a deleted owner still yields a working row through an independent path; or the test passes on any build because `except Exception` catches it | four deletions, asserting the *named* section and the symbol (NEW) | Survived — `[UNKNOWN] rule-sets: this check could not run: name '_age_text' is not defined` (and 3 more); every other section still prints |
| AC-S2 | a substring sweep passes/fails for the wrong reason because docstrings name the banned calls (D-4) | AST sweep + a substring cross-check (NEW) | Survived — 0 `st_size`/`getmtime` nodes; 4 substring hits, all prose (3 at HEAD) |
| AC-S8 | a credential leaks through the drift or permission rows | literals planted in `nodes.json`, `config.json`, `override.json` (NEW) | Survived — all three absent from stdout, including on the PROBLEM paths |
| K-5 | `_aaaa_rule()`'s extraction changed the emitted document | `generate_config()` HEAD vs candidate ×4 states (NEW) | Survived — `d7347308…` = `d7347308…` (off/auto-no-v6), `fe45a288…` = `fe45a288…` (on/auto-v6); control: the two decisions do differ |
| BC-26 | a concurrent run or a mid-generation rewrite crashes or blocks | 5 concurrent child processes; 5 runs against a churning `config.json` (NEW) | Survived — `[(0,21)]×5`; exit codes {0,1}, row count {21}, no traceback |

## Boundary tests added

- Rule-set age: 59 d, 60 d, 61 d (the `>=` threshold), mtime in the future (+1 h), absent file, a
  directory in the file's place, and `size is None` — the phrase and the verdict agree at every point.
- File modes: 600, 601, 604, 640, 700; directory modes 705, 755, 757, 775, 777.
- Permission section: 12 offending files (cap = 5 detail lines + `... 7 more line(s) not shown`),
  a symlink alone (UNKNOWN), a symlink plus a wide file (PROBLEM, `{n}` counts wide modes only),
  a world-writable `rules/` sub-directory (never descended), an entry that vanishes between the
  listing and the `lstat()`, an absent directory, and a directory at mode 0000.
- `config.json`: absent, truncated JSON, valid JSON that is not an object, `dns` as a string.
- `nodes.json`: absent, malformed, wrong shape (`{"nodes": 3}`), empty node list, a node tag
  carrying an emoji and CJK.
- Clash: no port recorded, a port nothing listens on, `/configs` answering `{}`, `/proxies` without
  history, `/dns/query` answering / answering without `Answer` / sleeping past the socket timeout.
- Concurrency: 5 simultaneous `sc doctor` processes on one root; 5 runs against a `config.json`
  rewritten every millisecond.
- Output contract: byte scan of a redirected capture for `\r` and ESC; an auto-select tag carrying
  `\r\x1b[31mRED\x1b[0m`; per-row flush observed on a real pipe (15 rows arrived before the 3 s
  DNS wait ended).
- Languages: every case above repeated in Chinese for the five new rows and the detail lines.

## verify_all result

- command: `bash /home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh`
- Total steps: 18 → 18 (unchanged; this task adds no `verify_all` step)
- Pass: 17
- Fail: 0
- Warn: 0
- Skip: 1 (B.3 lint — no linter on this project)
- Batch baseline (PASS 17 / WARN 0 / FAIL 0 / SKIP 1): matched exactly
- E.6 (`^##\s+Adversarial\s+tests`): PASS with this report present
- New tests added: 317 assertions across 14 files in `test/t20/` (0 before; this project ships no
  in-repo test suite — `test/` is gitignored, per the existing `test/step7/`)
- Baseline updated: **no** — `.harness/scripts/baseline.json` is in `02_SOLUTION_DESIGN.md`'s frozen
  set ("the count deltas stay at zero"), `verify_all` defines no test count on this project, and the
  file has read `test_count: 0` since 2026-07-31. Raising it would record a number no shipped check
  produces.
- AC-S7 tracked diff: `bin/sc 331/37` · `README.md 13/11` · `README.zh-CN.md 14/12` ·
  `CHANGELOG.md 1/0` · `docs/dev-map.md 7/6` — declared files only; `bin/sc` matches the declared
  +331/−37 exactly
- AC-S7 carve-out: `docs/batches/default/BATCH_PLAN.md 7/7` modified and **unstaged**;
  `git diff --cached` is empty, so nothing under `docs/batches/**` is staged (R-36)
- AC-S7 untracked: this task's stage docs, `docs/batches/default/BATCH_LOG.md`,
  `.harness/operator-obligations.md` (new, see DEF-4), and `test/` (gitignored) — none enters the diff
- Regression check: HEAD (`5bd0eaa`, a **clone**) run on the same fixture root produces 16 rows, all
  present verbatim in the candidate's 21 except the four `.srs` rows, which gained exactly
  `, 0 seconds ago`; `sing-box check`'s absence under an unreadable configuration directory is
  HEAD's behaviour too, not a regression

## Defects found

| id | severity | statement | reproducer | file:line |
|---|---|---|---|---|
| DEF-1 | MINOR | BC-11's "the service is not running ⇒ the node-delay row is UNKNOWN and issues no request" is not honoured when the Clash API answers while `is_running()` is False (no init system detected — a container, or a manually started sing-box). The row then states `0/{total} nodes carry a stored delay`, a count it never read, on a host whose `/proxies` holds delays. No false `[OK]`, the next step (`sc ls`) is harmless and shows the same emptiness, and the cause is `stored_delays()`' internal guard, which the frozen set forbids this task from touching. This is RES-4/RS-2 **plus** the BC-11 clause the residual does not name. | `bash test/t20/run.sh t_clash` → the "GC-4 vacuity demonstration" block: stub answers `/proxies` with two delays, `SYSTEMD=OPENRC=False` | `bin/sc:2765` (`stored_delays(port=port)`), guard at `bin/sc:2159` |
| DEF-2 | MINOR | The DNS row can be answered from the install's own cache, and `GET /dns/query` **populates that cache itself** — so every run warms the entry the next run reads, independently of the egress probe CR-3 names. Measured on the live host: a fresh name costs 175 ms, the same name 3 s later costs 4 ms with the TTL decremented; `api.ipify.org` TTL runs 195 → 190 → 186 across three runs; a negative answer is held 1800 s. Inside that window the row reports a cache read, not resolution through the tunnel. Row wording stays literally true; the fact it exists to establish is not established. | four read-only `GET`s on `127.0.0.1:29090`, `06_RATIONALE.md` `## The live-host probes` | `bin/sc:2781-2795` |
| DEF-3 | MINOR | The AAAA membership test is position-blind: a document carrying the rule at index 3 reads `[OK] … config.json carries this decision` while index 0 is what makes the suppression mode-independent. Reproduced independently; identical to CR-2/RES-1, which FR-4 and I-6 both specify and which needs a design decision. | `bash test/t20/run.sh t_drift_ipv6` → "RES-1 / CR-2 residual" | `bin/sc:2637` |
| DEF-4 | MINOR | **AC-B14 is BLOCKED, not discharged.** The shipped invocation is `sc doctor` as root on the live host; installing the candidate over `/usr/local/bin/sc` is forbidden by K-18 and no agent here holds an interactive root credential. No weaker artifact check was substituted (R-31 / R-41 / R-47). Filed as operator obligation **id 1** in `.harness/operator-obligations.md`, a file this stage created because it did not exist. | — | `01_REQUIREMENT_ANALYSIS.md` AC-B14 |
| DEF-5 | MINOR | Schema gap, **R-37 seventh confirmation**: `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule`, so the units this stage's dispatch requires in the contract (the GC discharges with captures, the stub request log, the AC-S7 read) fit no declared shape. They were fitted into the declared sections rather than given invented ones, and the gap is recorded here as the schema requires. | `grep -n "Stage-doc boundary rule" .harness/rules/70-doc-size.md` → no match | `.harness/rules/70-doc-size.md` |

No BLOCKER, no CRITICAL, no MAJOR. DEF-1…DEF-3 are row-level residuals already travelling as
RES-4 / RES-2 / RES-1; DEF-1's BC-11 clause and DEF-2's self-warming half are new at this stage and
should be carried into `07_DELIVERY.md`'s pool rows with those words. RES-6 was also reproduced (a
0777 `rules/` sub-directory still reads `[OK] file permissions`) and CR-11 confirmed in the safe
direction (a non-credential file at 0644 is reported, so the sentence under-promises and can produce
no false `[OK]`).

## Stability

- The healthy fixture and a broken fixture were each driven **10 times**: after normalising the temp
  root, the port and the measured milliseconds, all 10 reports hash identically per fixture, with one
  exit code (0 / 1) and one row count (21 / 21).
- The full suite ran **3 consecutive times**: 317/317 assertions each round. No file flaked.
- No timing-sensitive assertion depends on a sleep other than the deliberate 4.5 s stub stall, whose
  observed elapsed value (3003 ms) is reported, never asserted as a bound.
- Five concurrent `sc doctor` processes on one root and five runs against a `config.json` rewritten
  every millisecond all completed with 21 rows and no traceback.

## Verdict

APPROVED FOR DELIVERY  (5 MINOR defects, 0 BLOCKER / 0 CRITICAL / 0 MAJOR; AC-B14 BLOCKED and filed)
