# 06 — Test Report · T-30 `validate-before-baseline`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

## Test plan

Every row was run by a QA-authored fixture written from `01_REQUIREMENT_ANALYSIS.md`'s criterion,
never from `04_DEVELOPMENT.md`'s test code. `Q:` names a QA fixture (session-local, under the
scratchpad root `t30qa/`; its construction is in `06_RATIONALE.md` §1 so it is rebuildable).
`S:` names the committed suite. Differential rows ran both builds at **one** fixture path from a
`git clone --no-hardlinks` of `fc634e3`, never a `git worktree`; `generate_config()` /
`reload_or_restart()` were called directly, never through `main()`, so `sc.LANG` survived.

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 accepted verdict replaces `config.json` byte-identically, `0600`, record = sha256, one restart | `matrix.py accepted` (CAND vs HEAD at one root), `spans.py`, plus mutants W1/W2 | `Q:matrix.py`, `Q:qalib.py`, `S:check-sc-contracts.py` arm 2 |
| AC-2 rejected verdict, existing configuration | `matrix.py rejected`, `matrix.py quote-candidate`, `conc.py reject` (10-way) | `Q:matrix.py`, `Q:conc.py`, `S:` arm 1 |
| AC-3 rejected verdict, fresh host | `matrix.py rejected-fresh` | `Q:matrix.py`, `S:` arm 1 |
| AC-4 `SB_BIN` absent | `matrix.py absent-bin` (en + zh) | `Q:matrix.py`, `S:` arm 3 |
| AC-5 `SB_BIN` present but not an executable | `matrix.py unexec-bin` | `Q:matrix.py` |
| AC-6 checker exits non-zero with undecodable bytes | `matrix.py undecodable` (`\xff\xfe` on stderr) | `Q:matrix.py` |
| AC-7 candidate `0600` at the instant it holds the document; no survivor | `qalib.py witness-accept` / `witness-reject` (a **real child** stats what it was handed), listings before/after on all 22 runs | `Q:qalib.py`, `S:` arms 1-3 |
| AC-8 rejection message clauses, both languages | `run.py quote-candidate en\|zh`, `empty-reject en\|zh`, `absent-bin en\|zh` | `Q:run.py` |
| AC-9 `sc doctor` freeze over three on-disk states | `freeze.py doctor` CAND vs HEAD | `Q:freeze.py` |
| AC-10 `update-rules` / `reload` / `add` freeze | `freeze.py commands`, `freeze.py update-rules` (stubbed `_fetch_to_temp`, rejecting checker) | `Q:freeze.py` |
| AC-11 real `sing-box` 1.13.15 | `run.py real-reject` / `real-accept`; raw-pipe CSI check | `Q:qalib.py` |
| AC-12 installed host, live unit, reboot | **BLOCKED** — operator obligation 6 | `.harness/operator-obligations.md:13` |
| AC-13 committed assertions pass, floor does not fall | `verify_all` B.4 ×3, suite ×10, ratchet probe at floors 17/18/19 in the clone | `.harness/scripts/verify_all.sh`, `baseline.json` |
| FR-1 / NFR-1 exactly one checker process, on the candidate | real-child argv tally, accepted + rejected | `Q:` §1.6 |
| NFR-3 ≤ 25 net executable lines | independent `ast` classifier over both whole files | `Q:spans.py` |
| NFR-4 emitted bytes unchanged | sha256 `c976467141f3f0e1…` identical CAND/HEAD on 6 accepted-class cases | `Q:matrix.py`, `Q:sweep.py` |
| BC-1 / BC-4 / BC-6 / BC-7 | `probes.py` ×4, `conc.py` ×3, `spans.py` body-AST equality | `Q:probes.py`, `Q:conc.py`, `Q:spans.py` |

## Adversarial tests

One predicted failure per criterion, written before the run. Reproducers are QA's own.
Full runs in `06_RATIONALE.md`; ≤5 cited lines per row.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | the re-order changes the installed bytes, the mode, or the restart count — or AC-1 is satisfied by a build that rejects everything | `matrix.py accepted` at one root on both builds; then `mut-W1-rejects-everything`, `mut-W2-never-installs` through B.4 | **Survived, and it discriminates.** `CAND='c976467141f3f0e12378d10e57fbcb564efd570d7d1ae0da78fc300dd4c9fdc2' HEAD='c976467141f3f0e1…'` · `cfg_mode CAND='0o600' HEAD='0o600'` · `restarts CAND=1 HEAD=1` · W1 → `AssertionError: accepted: generate_config()'s return: got False, want True` · W2 → `AssertionError: accepted: config.json still holds the pre-run bytes` |
| AC-2 | the "left unchanged" claim is true of the file but not of the drift record, or holds only single-threaded | `matrix.py rejected`; `conc.py reject` — 10 concurrent `generate_config()` processes on one `CFG_DIR` | **Survived.** `** cfg_after_is_sentinel CAND=True HEAD=False` · `** state_after CAND='SENTINEL-QA-DIGEST\n' HEAD='c976467141f3f0e1…'` · 10-way: `config.json is the sentinel: True` · `listing before == after: True` · every child `{"ok": false, "raised": null}` |
| AC-3 | a fresh host still gets a `.config.sha256` written by the drift quartet's own path | `matrix.py rejected-fresh` (neither file pre-created) | **Survived.** `** cfg_after_exists CAND=False HEAD=True` · `** state_exists CAND=False HEAD=True` · HEAD listing `before={…'nodes.json'} after={…'.config.sha256','config.json',…}`, CAND listing unchanged |
| AC-4 | `subprocess` raises something the arm does not catch, or the fall-through skips the record | `matrix.py absent-bin`, en and zh | **Survived.** `** returned CAND=True HEAD=None` · `HEAD raised "FileNotFoundError: [Errno 2] …/no-such-binary"` · `state_is_sha_of_cfg CAND=True` · `⚠️ …/config.json was installed without being checked — \`sing-box check\` could not be run: [Errno 2]…` |
| AC-5 | AC-4's guard is a presence test, so an unexecutable file takes a different path | `matrix.py unexec-bin` (`0755`, non-executable content) | **Survived, and the pair discriminates.** CAND `returned=True`, one line `… could not be run: [Errno 8] Exec format error: '$R/not-an-executable'` — a **different errno** from AC-4's `[Errno 2]`, both reaching one arm; `HEAD raised "OSError: [Errno 8] Exec format error"` |
| AC-6 | `errors="replace"` is claimed, not present, so `\xff\xfe` still raises | `matrix.py undecodable` | **Survived.** `** returned CAND=False HEAD=None` · `HEAD raised "UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 6"` · CAND rendered `FATAL �� bad` and left both files at the sentinel |
| AC-7 | the mode is asserted from source rather than observed, and a candidate survives some path | `witness-accept` / `witness-reject`: a **real child** `stat`s argv[3] from inside the check; `mut-W3-candidate-wide`, `mut-W4-leak-on-reject` through B.4 | **Survived, and it discriminates.** witness: `cand_mode '0o600'` · `cand_dir '$R'` · `cand_sha 'c976467141f3f0e1…'` (= the bytes later installed) · `cfg_sha_at_verdict '5738058a…'` (still the sentinel) · W3 → `got 420, want 384`; W4 → `got [… 'config.json.check.ib6hr7vy' …]` |
| AC-8 | a stub never quotes a path, so the substitution is untested; or `zh` renders English | `run.py quote-candidate en\|zh` — a **real child** that echoes `argv[3]`; then `mut-res2-no-substitution` | **Survived.** en/zh both: `⚠️ $R/config.json 未被改动 —— \`sing-box check\` 拒绝了新的配置：` · `FATAL decode config at $R/config.json: bad` · `has ESC: False | has CR: False | has .check.: False | has 失败：: False` · mutant leaks `…/config.json.check.7ce3w3wi` (DEF-4) |
| AC-9 | the moved `_record_generated()` call changes a doctor row | `freeze.py doctor` over three on-disk states, CAND vs HEAD | **Survived (freeze, control agrees with HEAD by design).** `=== doctor: CAND vs HEAD` → `IDENTICAL` (byte-identical JSON, 3 states × stdout/stderr/exit) |
| AC-10 | the new `return False` grows the population of runs with no run-level outcome line | `freeze.py commands`, `freeze.py update-rules` with a rejecting checker | **Survived.** `reload how SAME 'SystemExit' value SAME 'Reload failed'` · `add stdout SAME 'Added: n2 (⚠️ config check failed — see \`sc log\`)\n'` · update-rules `value SAME 1`, `stdout SAME: True`, exactly one outcome line `Rule-sets updated: … the sing-box service was not touched` |
| AC-11 | `_plain()` strips only the SGR intro, so a real checker's `\x1b[0m` survives (T-05 DEF-1) | `run.py real-reject` with `/usr/local/bin/sing-box` 1.13.15; raw pipe control | **Survived — NOT BLOCKED.** raw pipe: `^[[31mFATAL^[[0m[0000] decode config at csi/bad.json: …` · CAND: `FATAL[0000] decode config at $R/config.json: dns.servers[4]: …` `ESC: False CR: False .check.: False`, `cfg_after_is_sentinel True` · HEAD: `'\x1b[31mFATAL\x1b[0m[0000] …'` and it **installed and baselined** the rejected document |
| AC-12 | — | — | **BLOCKED** — needs root, the installed `/usr/local/bin/sc`, the live unit and a reboot. Filed with its full recipe as operator obligation **6**. Nothing substituted. |
| AC-13 | the floor is a ratchet only by convention, so a lowered `test_count` still passes B.4 | `verify_all` in the HEAD clone with `test_count` set to 17 / 18 / 19 | **FAILED the second clause.** `floor=17 -> [B.4] … PASS` · `floor=18 -> … PASS` · `floor=19 -> … FAIL`. The suite-regression clause discriminates; **"the floor does not fall" does not** — see DEF-7 |
| BC-1 | the `finally` only covers the two `return`s, not an exception it cannot name | `probes.py install-raises-memoryerror` / `install-raises-keyboardinterrupt` | **Survived.** `"how": "raised", "value": "MemoryError: …"` · `"leaked_candidates": []` · `"listing_unchanged": true` · `"cfg_is_sentinel": true` (same for `KeyboardInterrupt`) |
| BC-4 | an unwritable drift record turns a successful run into a failure | `probes.py drift-record-unwritable` (`STATE_PATH` replaced by a directory) | **Survived.** `"how": "returned", "value": true` · `"cfg_len": 4625` · `"leaked_candidates": []` — `_record_generated()`'s own guard swallows it, silently, as designed |
| BC-6 | two runs collide on the candidate's name or on `config.json` | `conc.py accept` and `conc.py reject`, 10 processes each | **Survived.** accept: all 10 `{"ok": true, "raised": null}`, `drift record == sha256(config.json): True`; reject: all 10 `false`, `listing before == after: True` |
| BC-7 / K-2 | `_write_private` was "left byte-identical" by inspection only | `spans.py` — spans located by `ast`, not by the cited line numbers | **Survived.** `_write_private 51 488:538 433f00cacff4e18b | 51 491:541 433f00cacff4e18b IDENTICAL`; body-AST equality `True`; the developer's convention reproduced exactly as `c394797931d99deb` |
| CR-6 fence | the inner `else` is load-bearing and nothing watches it | `mut-CR6-arm-inside-try` (rejection arm absorbed into the inner `try`) + `fence.py` (a stderr that refuses only the rejection sentence) | **FAILED — uncontrolled.** B.4 `18 defined, 18 run, 18 passed` on the mutant, and: `"value": true` · `"config.json UNCHANGED (AC-2)": false` · `"config.json len": 4625` · `"drift record UNCHANGED": false` · user told `…was installed without being checked…`. See DEF-5 |

## Boundary tests added

- Empty rejecting output (BC-10): the reused key states the exit status in both languages — `the checker reported an error, no message (exit 1)` / `检查器报告了错误，未输出信息（退出码 1）`.
- Undecodable checker output: `\xff\xfe` on stderr → rejection carrying U+FFFD, no exception.
- Candidate creation refused by **EACCES** (`CFG_DIR` mode `0500`), not only by the suite's ENOENT: one `Could not write $R/config.json: Permission denied`, `False`, nothing created.
- `config.json` pre-existing at mode `0666`: installed result is `0600`.
- `config.json` pre-existing as a **symlink** pointing outside the root: replaced by a regular `0600` file; the symlink's destination is byte-unchanged (`'DO-NOT-TOUCH\n'`).
- Hostile umask `0o000` and `0o077`: installed mode `0600` under both.
- Non-ASCII / emoji node tag (`东京-🚀`): document composed and installed, 4661 bytes, record = its sha256.
- Ten concurrent `generate_config()` processes on one `CFG_DIR`, accepted and rejected verdicts.
- An exception outside `(OSError, ValueError)` raised at the install (`MemoryError`, `KeyboardInterrupt`): candidate still removed.
- A `ValueError` raised by the checker invocation itself (see DEF-6).
- Drift record unwritable (`STATE_PATH` is a directory): run still succeeds.
- Both languages on all three verdict arms, driven without `main()` so `sc.LANG` is the one that renders.

## verify_all result

- Command: `bash /home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh`
- Total tests: 18 → 18 (committed assertion count; no assertion added — see `## Defects found` and `02` `## Out of scope` 9)
- Pass: 19 steps (`PASS: 19`)
- Fail: 0
- Warn: 0
- Skip: 1 (B.3 Lint)
- Exit code: 0
- B.4: `18 defined, 18 run, 18 passed`; `baseline.json` `test_count` 18 / `passing_count` 18
- New tests added: 0 committed; 22 QA fixture cases + 16 mutants, run at stage 6
- Baseline updated: no — already at 18/18, floor neither raised nor lowered
- PM-owned `F.*` WARNs: none (F.5 and F.6 both PASS; nothing owed to the PM here)
- A.1: PASS; the QA fixtures live outside the repo, and A.1's pathspec excludes `.harness/*` wholesale in any case

## Defects found

All seven are **coverage** findings against the committed suite or against prose; none is a defect
in the shipped behaviour, and none blocks delivery. Reproducers run from the scratchpad root
`t30qa/` (`06_RATIONALE.md` §1).

| id | severity | reproducer | file:line |
|---|---|---|---|
| DEF-1 (= RES-8 / CR-12, **confirmed by measurement**) | MINOR | `mutate.py` builds `mut-res8-silent` (the outer handler's `sys.stderr.write` deleted); `check-sc-contracts.py --source mut-res8-silent` → `18 defined, 18 run, 18 passed`; `res8_cmd.py … readonly` → `"outcome_lines": []`, `"n_stderr_lines": 1`, still `SystemExit "Reload failed"`. Arm 4 in isolation (arms 1-3 emptied on a copy) also **PASSES** on it. | `.harness/scripts/check-sc-contracts.py:670-683`; claimed in full at `:618-620` and `docs/dev-map.md:87` |
| DEF-2 (= RES-9 first half) | MINOR | `mut-res9-other-doc` installs `{"log": {"level": "info"}}` instead of the composed document → B.4 `18/18 passed`. My AC-1 differential kills it: `cfg_after_len shipped 4625 / mutant 39` on 3 cases. | `.harness/scripts/check-sc-contracts.py:663-668` |
| DEF-3 (= RES-9 second half, **and its remedy is not the one proposed**) | MINOR | `mut-res9-os-replace` (`os.replace(name, str(CFG_PATH))`, the declined `candidate-installed-by-os-replace-instead-of-the-one-writer`) → B.4 `18/18 passed` **and** `sweep.py` reports `0 observable difference(s) across 9 cases`, extended to symlinked target, `0666` target, `umask 000` and the real binary: 13 cases, zero differences. A byte-comparison arm would **not** kill it — only a structural control can. | `.harness/scripts/check-sc-contracts.py:663-668`; K-2 at `02_SOLUTION_DESIGN.md:77-80` |
| DEF-4 (= RES-2 / CR-5, **confirmed and user-visible**) | MINOR | `mut-res2-no-substitution` → B.4 `18/18 passed`; `run.py quote-candidate` (a real child that echoes `argv[3]`) renders `FATAL decode config at $R/config.json.check.7ce3w3wi: bad` to the user, violating FR-5. | `bin/sc:2193`; no control anywhere |
| DEF-5 (**new** — the fence CR-6 states and CR-17 files) | MINOR | `mut-CR6-arm-inside-try` (rejection arm moved inside the inner `try`) → B.4 `18/18 passed`; `fence.py` with a stderr that refuses only the rejection sentence → the mutant returns `True`, installs 4625 bytes over the sentinel, re-baselines the record, and tells the user the document `was installed without being checked`. The shipped build returns `False` and installs nothing. | `bin/sc:2183` (the `else:`); reasoning lives only in `04_RATIONALE.md:186-194`, which is archived at delivery |
| DEF-6 (**new**) | NIT | `probes.py checker-raises-valueerror` → the shipped build renders `⚠️ Could not write $R/config.json: synthetic: a decode-shaped failure` for a write that never happened; `config.json` is intact and `False` is returned. HEAD tracebacks there **after** installing, so this is strictly better, and the path is unreachable with `bin/sc`'s fixed argv. | `bin/sc:2198-2206` (I-9 excludes only a checker `OSError`) |
| DEF-7 (**new**) | MINOR | In the HEAD clone with the delivered suite: `test_count` 19 → `[B.4] … FAIL`; 18 → `PASS`; **17 → `PASS`**. B.4 compares passing count against the floor and never against the floor's own history, so AC-13's second clause has no control. | `.harness/scripts/verify_all.sh` B.4 vs `.harness/scripts/baseline.json:4-5` |

**Recommended committed clauses (a future task, not this one — `02` `## Out of scope` 9 declines a
fifth arm and I-14 fixes arm 4 as written).** DEF-1: assert arm 4's captured stderr holds exactly
one `Could not write` line containing `str(CFG_PATH)` and no `.check.` — cost ≈ 6 lines, needs a
`sys.stderr` capture in the arm. DEF-2: `_eq(after, composed_bytes, …)` in arms 2-3 where
`composed_bytes` is read from the candidate by the stub at verdict time — cost ≈ 3 lines, and it
also closes DEF-4's sibling. DEF-3 and DEF-5: **structural**, not behavioural — an `ast` clause
(`generate_config()` contains exactly one `os.replace`-free install through `_write_private`, and
the rejection `Raise`/`Return` is a child of an `orelse`, not of the inner `Try.body`) or a grep in
`verify_all`; note K-11 declined `ast` shape checks for statement order, so this needs a ruling
rather than an edit. DEF-7: a monotonicity check on `baseline.json` against `git show HEAD:` —
`verify_all`-owned, so PM/architect territory.

## Stability

- `.harness/scripts/check-sc-contracts.py` run **10** times: `18 defined, 18 run, 18 passed` every time. No flake.
- `verify_all.sh` run **3** times: `PASS: 19 WARN: 0 FAIL: 0 SKIP: 1`, exit 0 every time. No flake.
- The QA differential matrix (9 cases × build) run **3** times against the shipped build: `0 observable difference(s) across 9 cases` each time — byte-stable including the composed document's sha256, the drift record and every stderr line.
- The 10-way concurrency fixture was run 3 times per verdict: no collision, no leaked `config.json.check*`, no exception, in 60 child processes.
- No test was deleted, skipped or weakened. The B.4 floor was never lowered; the 17/18/19 ratchet probe ran in the HEAD clone and was reverted (`git checkout --`).
- Live service witness, `systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts sing-box` (never `is-active`): **before** `MainPID=2566751 NRestarts=0 ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`; **after** identical. `/etc/sing-box` and `/var/lib/sing-box` entry sets unchanged; no fixture ever wrote either, none drove `sc reload` against the host, none restarted the service.

## Verdict

APPROVED FOR DELIVERY
