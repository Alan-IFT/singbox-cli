> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

# 06 — Test Report · T-22 `share-url-userinfo-contract`

## Test plan

Every fixture below is **mine**, written from `01`'s AC table with credential constants that differ
from stage 4's, and every userinfo is explicit per-class text (K-21 / BND-6): a raw `:` for `F-a`, a
literal `%3A` for `F-b`, a literal `%2525` for `F-c`, explicit `%XX` for `F-d`, a raw `@` for `F-e`.
No credential is passed through `quote()` — `grep -n 'quote(' qa_fixtures.py qa_runner.py` returns a
single hit, `qa_fixtures.py:3`, the docstring sentence saying so; zero call sites — and every
expected value is the constant the URL text was written to carry. Files are outside the worktree and
uncommitted (K-15 / BND-9); the full listing, including the per-class construction block RT-5 names,
is in `06_RATIONALE.md`.

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 credential in the emitted document == the constant the URL carries | 19 fixtures: tuic `qt_a` `tuic://U9:a:b:c@h.example:443` → `uuid U9` / `password a:b:c`, `qt_b` `…:x%3Ay@` → `x:y`, `qt_c` `…:100%2525@` → `100%25`, `qt_d` `…:p%C3%A9q@` → `péq`, `qt_e` `…:a@b@` → `a@b`; trojan `qj_a1` `trojan://::@` → `::`, `qj_a2` `:q7` → `:q7`, `qj_a3` `q7:` → `q7:`, `qj_b/c/d/e` as tuic's `F-b…F-e`; hysteria2 `qy_*` the same seven. Asserted on the outbound read back from `CFG_PATH` **in that run**, on `generated is True`, on equal length, and on the raw document bytes | `qa_fixtures.py:AC1`, `qa_compare.py:check` |
| AC-2 same procedure at HEAD reports exactly 11 red | the same 19 fixtures against a `git clone` of HEAD `51c0f47` at the same fixture root; `head_red` hand-authored per fixture, compared as a set | `qa_compare.py` AC-2 block |
| AC-3 shadowsocks fields + byte-identity | `qs_j` (`F-j`), `qs_a` (`F-a`, `a:b`), `qs_e` (`F-e`, `pw@x`), `qs_i` (`F-i` whole-body base64), `qs_h` (`F-h`, base64 `p%41q`), **`qs_b` `ss://a%3Ab:pw@h.example:8388` → `method a:b` / `password pw` (RES-1)**, `qs_k` colonless (K-8 delta 1). Asserted on the **document** (RES-2) | `qa_fixtures.py:AC3` |
| AC-4 vless + vmess byte-identity | `qv01…qv12` (tcp/ws/grpc/h2/http/httpupgrade × none, + `tls` ×3, `reality` ×2), every vless carrying a uuid (K-9); `qv_bnd10` `vless://a:b@h.example:443` (BND-10); `qv16`; `qm01…qm05` vmess with `uuid` asserted `== U9` (FR-8's vmess half, RES-2) | `qa_fixtures.py:AC4` |
| AC-5 `%3A` in the first field | `qx5` `tuic://a%3Ab:pw@h.example:443` → `uuid a:b`, `password pw` | `qa_fixtures.py:AC5_8` |
| AC-6 one decode pass | `qt_c`/`qj_c`/`qy_c` `100%2525`→`100%25`; `qx6j`/`qx6t` `100%25`→`100%` | `qa_fixtures.py` |
| AC-7 bracketed IPv6 | `qx7j`/`qx7y`/`qx7t` from `[2001:db8::1]:443` → `server 2001:db8::1` **unbracketed** (BND-8), `server_port 443`, credential correct (`qx7t` carries `p:q`) | `qa_fixtures.py` |
| AC-8 no userinfo | `qx8j`/`qx8y`/`qx8t` → `password ""` (tuic also `uuid ""`), no exception, `generated is True` | `qa_fixtures.py` |
| AC-9 no new emitted key | frozensets absent from the diff; emitted outbound key set over all 57 fixtures, candidate vs HEAD | `qa_static.sh`, key-set diff |
| AC-10 exactly one userinfo reading | section sweep, two pattern groups, group (ii) quote-agnostic; plus `.username`/`.password` over the whole file | `qa_static.sh` |
| AC-11 no new user-facing string | `git diff` grep for `t(` / `失败：` | `qa_static.sh` |
| AC-12 CHANGELOG damage set | `CHANGELOG.md:26` read clause by clause against the four predicates, the two non-claims and the repair, each checked against **HEAD's measured behaviour** | `CHANGELOG.md:26` + `qa_delta.py` |
| AC-13 live tuic authentication | **BLOCKED by construction** — needs root, the installed `/usr/local/bin/sc` and a real credential. No artifact check substituted | operator obligation, id **3** (next unused) |
| AC-14 `sing-box check` | real `/usr/local/bin/sing-box` over the emitted documents; **non-regression only** | `qa_ac14.py` |
| AC-15 `verify_all` | `bash .harness/scripts/verify_all.sh` ×3, from the repo root | `.harness/scripts/verify_all.sh` |
| AC-16 vless id decoded | `qv16` `vless://a%2Db@h.example:443` → `uuid a-b` (HEAD `a%2Db`) | `qa_fixtures.py:AC4` |

## Adversarial tests

One row per acceptance criterion: a hypothesis written **before** the run, an independent reproducer,
and the outcome with cited output. Full runs are in `06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | the password is read back from the parser rather than from the file, so a document-level truncation would hide; I assert the file's **bytes** instead | `bash qa_run.sh` (NEW, mine) — 19 fixtures, byte check `'"password": ' + json.dumps(want)` in `CFG_PATH`'s text | Survived — `qt_a PASS … qy_e PASS`, and `RESULT: ALL GREEN (0 failing fixtures of 57)` |
| AC-2 | the mismatch set is 11 only because stage 4's constants were chosen to make it 11; with different constants HEAD should break the pattern | same run, HEAD = `git clone` at `51c0f47`, `head_red` hand-derived by me against `parse.py:198` | Survived — `red at HEAD : 11 ['qj_a1','qj_a2','qj_a3','qt_a','qt_b','qt_c','qt_d','qt_e','qy_a1','qy_a2','qy_a3']` / `predicted red (BND-1): 11 [same]` / `PASS -- control agrees fixture-for-fixture` |
| AC-3 | `parse_ss`'s plaintext arm still decides its own boundary: `ss://a%3Ab:pw@…` should split at the `%3A` (CR-1's untested case) | `qs_b` (NEW — RES-1's fixture, no ss fixture had a `%` in a plaintext userinfo before) | Survived — `qs_b PASS (declared delta; head={… "method": "a%3Ab", "password": "pw"})`; candidate emits `method a:b` / `password pw`. Closes BC-10's `%3A` half, BND-12 for `parse_ss`, and K-8 delta 2 |
| AC-4 | vless takes FR-5's whole-userinfo reading, so `vless://a:b@…` emits `a:b` and drifts from HEAD | `qv_bnd10` (BND-10's instrument) + mutant **m3** which really does apply FR-5 to vless | Survived — `qv_bnd10 PASS`, byte-identical to HEAD; the mutant dies exactly there: `m3_vless_whole: qv_bnd10 FAIL uuid='a:b' want 'a'` |
| AC-5 | `%3A` forges a delimiter because decoding happens first | `qx5` + mutant **m2** (`unquote` before `partition`) | Survived — `qx5 PASS`; mutant dies: `qx5 FAIL uuid='a' want 'a:b'; password='b:pw' want 'pw'` |
| AC-6 | `%2525` is decoded twice (`100%`) or not at all (`100%2525`) | `qt_c`/`qj_c`/`qy_c` and `qx6j`/`qx6t` | Survived — all five PASS; `100%2525`→`100%25`, `100%25`→`100%` |
| AC-7 | the IPv6 brackets' colons leak into the userinfo, or the credential is lost beside them | `qx7t` `tuic://U9:p:q@[2001:db8::1]:443` | Survived — `qx7t PASS` (`server 2001:db8::1` unbracketed, `server_port 443`, `password p:q`). Per BND-8 the missing brackets are **not** filed |
| AC-8 | a userinfo-less authority raises, or writes no document | `qx8j`/`qx8y`/`qx8t`, `generated is True` asserted | Survived — all three PASS with `password ""` (tuic `uuid ""`), document written |
| AC-9 | some emitted outbound key set moved for at least one fixture | key-set diff over all 57 fixtures, candidate vs HEAD | Survived — `candidate-only keys: []` / `head-only keys: []` / `14 keys`; the only per-fixture difference is `qs_k`, where HEAD emits **no** node at all (delta 1) |
| AC-10 | a call site re-splits a projection, giving a sixth colon-split hit that stage 4's quoted pattern missed | my own quote-agnostic sweep, plus `.username`/`.password` over the **whole** file | Survived — `group (ii) hit count: 5` at `:636 :729 :734 :738 :739`, exactly BND-4's enumeration; `p.username/p.password` count over the whole file: `0` |
| AC-11 | the diff smuggles a user-facing string | `git diff -- bin/sc \| grep -E '^\+.*(t\(\|失败：)'` | Survived — `(none)`; `失败：` in `CHANGELOG.md` still `1` (the 0.1.0-era entry) |
| AC-12 | the corrected bullet still claims something HEAD does not do, or drops a predicate | each clause re-measured against HEAD, not against the design | Survived — (a) `qt_*` HEAD `password ""` ×5; (b) `qj_a1/2/3` red, `qj_b` (`%3A`) green; (c) `qs_h` HEAD `pAq` vs `p%41q`; (d) HEAD `{'uuid': 'a%2Db'}` for **both** vless and tuic. Both non-claims verified true: ss colon (`qs_a`) and `%` in trojan/hy2/ss-plaintext passwords are byte-identical at HEAD. `sc reload` negative confirmed in code — `args.url` appears only at `bin/sc:2302,2305`, never persisted. CR-3's live-server clause is **gone** |
| AC-13 | — (cannot be obtained: root + installed binary + real credential) | none attempted | **BLOCKED by construction.** No artifact check substituted (R-31/R-41/R-47/R-52/R-60, sixth time). Operator recipe filed below |
| AC-14 | the checker accepts a defective document, so the row proves nothing — I expect HEAD to pass too | `sing-box check -c` over both checkouts' documents, legal UUID corpus | **Confirmed non-regression, as predicted**: `c_t_a cand accepted {"password":"a:b:c"}` / `head accepted {"password":""}`. A real `sing-box` accepts an empty tuic password — the measured answer to Q-10, and why this row is never evidence for FR-1…FR-8 |
| AC-15 | the report or the harness trips A.1 or a size cap | `bash .harness/scripts/verify_all.sh` from the repo root, ×3 | Survived — `PASS: 17 WARN: 0 FAIL: 0 SKIP: 1` three times; A.1 PASS, E.6 PASS, F.6 PASS with both stage-6 documents in place |
| AC-16 | the id is decoded twice, or the first-field reading discards the decode | `qv16` | Survived — `qv16 PASS (declared delta; head={… "uuid": "a%2Db"})`; candidate `a-b` |
| FR-1 / BND-3 (whole-file) | a **fourth** behaviour delta exists that three stages missed | `qa_delta.py` (566 URLs) + `qa_model.py`: an independent re-implementation of FR-2/3/4/5/7 judges every non-`ss` divergence, and every non-credential key must match HEAD | Survived — `urlparse-scheme URLs checked against the model: 528 ; violations: 0` / `ss divergences: 10`, all ten classified as delta 1 (×3), delta 2 (×3) or FR-6/BC-9 (×4). **No fourth delta** |
| I-1 (totality) | `_userinfo` raises on some pathological string — the "total over every `str`" claim nobody observed | `qa_total.py`: 29,726 inputs incl. NUL, surrogate-free emoji, `%zz`, bare `%`, 100k-char strings | Survived — `inputs=29726 raised=0 invariant violations=0` |
| harness (R-22) | my own harness is vacuously green | `mutate.py`: four forbidden implementations driven through the same comparator | Survived — every mutant dies on the predicted fixture: `m1 qj_a3/qy_a3 FAIL password='q7' want 'q7:'`; `m2 qs_b/qx5 FAIL`; `m3 qv_bnd10 FAIL`; `m4 qj_a1/a2/a3 + qbc11j FAIL` |

## Boundary tests added

- BC-1 / AC-8: authority with no `@`, for trojan, hysteria2 and tuic — `password ""`, tuic `uuid ""`, no exception, document written.
- BC-2 / `F-e`: unencoded `@` inside the userinfo (`a@b`) for all three schemes and for `ss://` (`pw@x`) — split at the **last** `@`.
- BC-3 / AC-7: bracketed IPv6 host with a colon-bearing tuic password (`U9:p:q@[2001:db8::1]:443`).
- BC-4 / BND-5: all three shapes — `::`, `:q7`, `q7:` — for **both** trojan and hysteria2; `q7:` is the shape a first+rest rebuild cannot emit, and it is the fixture that kills mutant m1.
- BC-5 / AC-5: `%3A` in the first field, for tuic (`qx5`) **and** for the ss plaintext arm (`qs_b`, new).
- BC-6 / AC-6: `%2525` → `100%25` and `%25` → `100%`, on trojan, hysteria2 and tuic.
- BC-7: percent-encoded non-ASCII (`p%C3%A9q` → `péq`) on all three schemes, asserted in the document's bytes with `ensure_ascii=False`.
- BC-8: `%FF` → U+FFFD, lossy, **no exception**, document written (`qbc8`), plus the ss half from the sweep (`ss://p%FFq:pw@…` → `method p�q`). The credential-fidelity half is not assertable and is a reasoned non-assertion (`06_RATIONALE.md`).
- BC-9: base64-recovered `%41` and `%2525` emitted verbatim (`qs_h`, plus four sweep cases across both base64 arms).
- BC-10: colon **and** `%3A` after the ss method boundary (`qs_a`, `qs_b`).
- BC-11: 2001-character userinfo carrying 1000 raw colons, trojan and tuic (`qbc11j`, `qbc11t`) — transcribed whole into the document; HEAD emits `a` and `""` respectively.
- BC-12: unsupported scheme and `urlparse`-hostile inputs left unchanged — covered by the 566-URL sweep, where every non-divergent case is byte-identical to HEAD.
- Empty-string, NUL, malformed `%zz`, bare `%`, raw `?`/`#`//`/`, emoji and 100k-character inputs against `_userinfo` directly (totality fuzz). Concurrency is not asserted: `_userinfo` is pure and does no I/O, and `generate_config()`'s atomicity is untouched by this change.

## verify_all result

```
command: bash /home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh   (run from the repo root)
```

- Total checks: 18 → 18 (17 PASS + 1 SKIP)
- Pass: 17
- Fail: 0
- Warn: 0
- Skip: 1 (B.3 lint, unchanged from the batch baseline)
- Batch baseline (PASS 17 / WARN 0 / FAIL 0 / SKIP 1): matched
- A.1 (no hardcoded secrets): PASS — the harness is untracked and outside the worktree (BND-9)
- E.6 (Adversarial tests section) and F.6 (≤500 lines) re-run **after** both stage-6 documents landed: PASS, PASS
- New tests added: 57 differential fixtures + 4 mutants + 566-URL sweep + 29,726-input fuzz — **none committed** (K-15 forbids the harness inside the worktree; T-28 owns the committed suite)
- Baseline updated: **no**. `.harness/scripts/baseline.json` still reads `test_count: 0`; no committed test was added by this task, so the baseline is preserved rather than raised, and a number that no committed suite backs would be a false one. T-28 is the task that raises it.
- Diffstat re-measured independently: `bin/sc` **+21 / −11** in 5 hunks; `CHANGELOG.md` +2; `docs/dev-map.md` +2/−1; no other tracked file modified.

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| QA-1 | MINOR — **pre-existing, not a regression**; owner: developer via **T-23** | `env LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0 python3 qa_locale.py <bin/sc> <root> <stub>` on `trojan://p%C3%A9q@h.example:443`: `RAISED out of sc's own writers: UnicodeEncodeError: 'ascii' codec can't encode character '\xe9'`. **Identical at HEAD**, so BC-7 is not regressed — but this change makes non-ASCII credentials reachable for tuic/trojan/hysteria2 shapes that used to be emptied or truncated, so more inputs can now reach the failing writer. T-23 owns the `encoding=` defect; this run shows it is not only the state file | `bin/sc:477` `_write_private`, `bin/sc:549` `save_nodes`, `bin/sc:2079` `generate_config` |
| QA-2 | MINOR — schema gap, owner **T-27** (R-37, **eleventh** confirmation) | RT-5 binds the harness listing to this document, and `.harness/rules/70-doc-size.md` still declares no `## Stage-doc boundary rule` to classify a code listing; no section of the QA schema can hold one. Rather than invent a section, the listing (including the per-class fixture-construction block) is in `06_RATIONALE.md` and this row records the gap, as `05_CODE_REVIEW.md` CR-6 did | `.harness/rules/70-doc-size.md` |
| QA-3 | **BLOCKED by construction — not a defect** | AC-13. Recipe for `.harness/operator-obligations.md`, **next unused id = 3**: install the new `bin/sc`; `sc rm` the tuic node; `sc add '<its share link>'`; `sc use` it; confirm egress through it; confirm `sc config` shows a **masked, non-absent** password for that outbound. Needs root, the installed `/usr/local/bin/sc` and a real credential — forbidden to every agent here. No artifact check was substituted anywhere in this report | `01_REQUIREMENT_ANALYSIS.md` AC-13 / RT-1 / RES-5 |

No BLOCKER, CRITICAL or MAJOR defect was found. Two observations that are **not** defects, recorded
so a later reader does not re-derive them: (1) K-8 delta 1 now stores a node where HEAD raised, and
its document is rejected by a real `sing-box check` (`missing password`) — but the failure class
pre-exists at HEAD via `ss://aes-128-gcm:@h:8388`, which behaves identically on both sides, so the
delta moves one input into an existing class rather than creating one; (2) a tuic outbound whose
`uuid` is not a legal UUID is rejected by `sing-box check` at HEAD and on the candidate alike, which
is why AC-14 was re-run with a legal UUID.

## Stability

- The full 57-fixture differential ran 10 consecutive times: `ALL GREEN (0 failing fixtures of 57)` every time, and each run's result file is byte-identical to the first (`node-json identical to run 0: yes` ×10). No flake.
- `verify_all` ran 3 times: `PASS 17 · WARN 0 · FAIL 0 · SKIP 1` every time. No flake.
- Determinism note: `RULES_DIR` is emitted verbatim into `route.rule_set[].path`, so both checkouts were driven at the **same** fixture root (K-19); `nodes.json` / `settings.json` are rewritten and `.config.sha256` **and** `config.json` unlinked between runs, so no comparison can read a stale document.
- Live-host isolation held across every run: `MainPID=2566751` and `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` before and after; `/etc/sing-box` and `/var/lib/sing-box` mtimes unchanged; `is-active` never called; `main()` and `_init_files()` never called; `sc.LANG` / `sc.CLASH_PORT` asserted after every one of the ~930 fixture runs.

## Verdict

APPROVED FOR DELIVERY
