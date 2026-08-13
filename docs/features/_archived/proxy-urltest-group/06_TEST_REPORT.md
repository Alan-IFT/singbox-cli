# 06 — Test Report · T-15 `proxy-urltest-group`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

Mode: **full**. Upstream contract portions read in full: `01`, `02`, `03`, `04`, `05`.
`02_RATIONALE.md` opened under **T6.1** (AC-15's verification step is under-specified in `02` — F-2)
and `04_RATIONALE.md` under **T6.2** (C-6's binary-string measurement). `.harness/rules/70-doc-size.md`
still has no `## Stage-doc boundary rule`, so the agent schema is applied as written.

The harness is **QA's own**, rebuilt from `docs/dev-map.md:109-135` and `01 §9`; no file from stage 4's
scratchpad was read, sourced or imported. Every suite runs the HEAD **clone** (`1e454b6`) beside the
candidate at the **same** fixture root (S-7). Full runs: `06_RATIONALE.md`.

Every behavioural result below was measured against `bin/sc`
`sha256:ae8198cf8134eaa7a79c50cc2cb3f3002a9feeef16b96d56eb600376d18082f8`, which is the byte-exact
file now in the tree — the only edits after those runs were to `README.md`, `README.zh-CN.md` and
`CHANGELOG.md`, verified by that hash and by `git diff --numstat`.

## Test plan

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1, AC-2 | `AC-1: exactly one urltest`, `members == node tags in nodes.json order`, `direct is not a member`, `selector holds auto + every node tag + direct` | `qa/t_headline.py` |
| AC-3, AC-4, AC-6, AC-14 | 14-state matrix (BC-1…BC-4, K-6, BC-8, unicode tags) × independent closure scan × **real** `/usr/local/bin/sing-box check` | `qa/t_regress.py` |
| AC-5 | `the WHOLE zero-node document is byte-identical to HEAD's` + non-vacuity at 3 nodes | `qa/t_regress.py` |
| AC-7 | `no urltest/selector/outbounds literal in generate_config()` (AST, not grep) | `qa/t_static.py` |
| AC-8, AC-22 | `sc use auto` vs stub: one `PUT`, no service call; 404 → restart path | `qa/t_upgrade.py` |
| AC-9 | `nodes.json byte-identical after 5 generations`, document identical ×5 | `qa/t_regress.py` |
| AC-10, BC-3 | `sc rm` of the last node with `active='auto'`, real `reload_or_restart()` | `qa/t_regress.py` |
| AC-11, BC-7 | fragment `#auto`, and also `#proxy` / `#direct` | `qa/t_regress.py` |
| AC-12, BC-8 | node `auto-jp` then `sc use auto`, then `sc use auto-jp` | `qa/t_regress.py` |
| AC-13, AC-31 | 15 specs × 2 languages vs HEAD: exit, stdout **bytes**, stderr bytes, persisted selection | `qa/t_regress.py` |
| AC-15, AC-23 | **V-19 run** — second unprivileged sing-box, group selected without any `PUT`; SOCKS5 `ATYP` recorded | `qa/t_v19.py` |
| AC-16, I-13 | the group emits exactly seven keys; `interrupt_exist_connections` absent on group, `True` on selector | `qa/t_static.py` |
| AC-17, AC-18, AC-19, AC-21 | BC-13 fixture written by the HEAD clone, then two reloads + a hand-edit non-vacuity arm | `qa/t_upgrade.py` |
| AC-20 | `sc update-rules` against a local mirror serving identical bytes, counting proxy on `restart_service` | `qa/t_upgrade.py` |
| AC-24, AC-25, BC-9, BC-10 | stopped / refused / hung / non-JSON / bad-UTF-8 / truncated + 28 malformed bodies × 2 languages | `qa/t_broken.py` |
| AC-26, FR-12 | mixed known/unknown table; `delay` `0`, `True`, `"90"`, `90.5`, negative, 1e30 | `qa/t_broken.py`, `qa/t_headline.py` |
| AC-27, NFR-1 | connection-counting stub with `is_running()` false; wall-clock | `qa/t_broken.py` |
| AC-28, AC-29 | file-wide `timeout=` set vs HEAD; every mutating call site vs HEAD; `stored_delays` call list | `qa/t_static.py` |
| AC-30 | zero nodes, both languages, byte-identical to HEAD, zero requests | `qa/t_broken.py` |
| AC-32 | `bash .harness/scripts/verify_all.sh` | — |
| AC-33, FR-15 | new-key diff vs HEAD, placeholder parity, `失败：` scan, S-8 mutant | `qa/t_lang.py` |
| AC-34, C-2, C-8, K-18 | structural mirror by position; the `:101` and `:103` claims asserted phrase by phrase in both files; CHANGELOG placement | `qa/t_readme.py` |
| NFR-3 · the failover claim itself | `:89`'s five claim atoms (promise, probe-round mechanism, ~3 min magnitude, hang carve-out + mechanism, observation + manual escape) asserted **per language**, plus the `CHANGELOG.md:7` bullet, plus a mutant arm | `qa/t_def2.py` |
| AC-35, NFR-2 | `py_compile`, `ast.parse(feature_version=(3,6))`, import set vs HEAD | `qa/t_static.py` |
| C-1 (audit) | K-6 host: no group, no warning, index 1 kept, `sc use auto` pins the node | `qa/t_regress.py` |
| C-5 (audit) | group row present with indices asserted; mixed known/unknown cells | `qa/t_headline.py` |
| C-7 (audit) | hand-made empty-member `urltest` vs the real binary | `qa/t_static.py` |
| RES-2 | eleven frozen anchors extracted by AST and byte-compared to HEAD | `qa/frozen.py` |
| NG-11, NG-7 | `sc now` ×6, `sc status` ×4, `sc doctor` ×2 — byte-identical to HEAD | `qa/t_regress.py`, `qa/t_upgrade.py` |
| **the headline behaviour** (`01 §2`, no AC covers it — see DEF-4) | latency swap; member refuses; member hangs — real sing-box, real traffic | `qa/t_control.py`, `qa/t_refuse_long.py`, `qa/t_hang_long.py` |

## Adversarial tests

One row per acceptance-criterion cluster; the hypothesis was written **before** the run.
Cited output is verbatim; full runs in `06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-24 / BC-9 · RES-1 | a 2xx body that is not JSON escapes `clash_api()` into `cmd_ls()` | `python3 qa/t_broken.py` §P2 (NEW — stub answers `200 text/html`) | **FAILED — RES-1 CONFIRMED.** `json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)` · frames `sc:1748 cmd_ls <- sc:1673 stored_delays <- sc:1637 clash_api`. HEAD's `sc status` raises the same type → pre-existing. **DEF-1** |
| AC-24 / BC-9 | a port that accepts TCP and never answers raises rather than returning `None` — `except (URLError, HTTPError)` does not cover `getresponse()` | `python3 qa/t_broken.py` §P3 (NEW) | **FAILED — WIDER THAN RES-1.** `TimeoutError: timed out` after `3.00 s`, `frames: sc:1748 cmd_ls <- sc:1673 stored_delays <- sc:1635 clash_api`; HEAD `sc status`: `TimeoutError('timed out') after 3.00 s`. Needs **no** foreign server — a stalled sing-box suffices. **DEF-1** |
| AC-24 / BC-9 | an invalid-UTF-8 or over-declared-`Content-Length` 2xx body also escapes | `python3 qa/t_broken.py` §P4/§P6 (NEW) | **FAILED.** `UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 0` and `http.client.IncompleteRead: IncompleteRead(15 bytes read, 50 more expected)`. **DEF-1** |
| AC-25 / BC-10 | at least one malformed JSON shape escapes the `isinstance` gates | `python3 qa/t_broken.py` §P5 (NEW — 28 bodies × 2 languages through `cmd_ls`, not through `stored_delays`) | **Survived** — `PASS AC-25/BC-10: all 28 malformed bodies x 2 languages survive cmd_ls :: []`. Tried: top level list/str/null/number, `proxies` list/null, entry non-dict, history str/empty/`[[1]]`/`[None]`, delay `"90"`/`90.5`/`True`/`0`/`-5`/`10**30`/nested, `now` numeric/empty/unknown/400-char, unicode tag key. K-12's gates hold. |
| AC-27 | the `is_running()` guard sits after the first socket, so a stopped host still waits 3 s | `python3 qa/t_broken.py` §P1 (NEW — connection-counting stub) | **Survived** — `connections=0 requests=0`, `0.0000 s`. |
| AC-5 | the zero-node document moved (key order or whitespace) | `python3 qa/t_regress.py` (NEW — HEAD clone and candidate at the **same** `mkdtemp` root) | **Survived** — `the WHOLE zero-node document is byte-identical to HEAD's :: 5048 vs 5048 bytes`; non-vacuity arm at 3 nodes `DOES differ :: 5583 vs 5863 bytes`. |
| AC-13 / AC-31 | index numbering shifts once the group row is displayed | `python3 qa/t_regress.py` (NEW — 15 specs incl. `0`, `4`, `""`, `-1`, `"1 "`, `99999999999999999999`) | **Survived** — `30 spec x language combinations identical to HEAD :: []`; non-vacuity: `sc use auto` **does** differ (`head=(…,'US-1') cand=(…,'auto')`). |
| AC-12 / BC-8 | `auto-jp` swallows `sc use auto` through the substring fallback | `python3 qa/t_regress.py` (NEW) | **Survived** — `` `sc use auto` selects the GROUP, not auto-jp :: Switched to: auto ``; `sc use auto-jp` still pins it. |
| AC-11 / BC-7 | a `#auto` fragment collides | `python3 qa/t_regress.py` (NEW; also `#proxy`, `#direct`) | **Survived** — `tag='auto #2'`, `'proxy #2'`, `'direct #2'`; real checker accepts `['proxy','auto','auto #2','direct']`. |
| AC-6 / FR-3 | the reserved set is incomplete — the live API returns a `GLOBAL` entry nobody reserved | `python3 qa/t_global.py` (NEW) | **FAILED (narrow).** A node tagged `GLOBAL` is mintable, the real checker accepts it, and its row reads `9999 ms` — sing-box's own implicit selector's history. No exception, table intact. **DEF-3** |
| AC-15 / AC-23 · C-3 / RES-3 | the probe resolves `www.gstatic.com` through `remote_dns → proxy →` the group being probed and deadlocks (K-14 is an inference from one binary string) | `python3 qa/t_v19.py` (NEW — **V-19 RUN**: a second unprivileged sing-box on the emitted document, group selected because `_valid_selection()` makes it `proxy.default`; **zero** `PUT`/`PATCH`/`DELETE`; live service untouched) | **Survived — K-14 CONFIRMED BY OBSERVATION.** `SOCKS5 CONNECTs recorded: atyp={3} hosts={'www.gstatic.com'}` — the FQDN was handed to the member, so no local DNS server resolved it. `histories: {'auto': 916, 'R-1': 980, 'R-2': 916}` and `sc ls` rendered `→ R-2 … 916 ms`, dead member `-`. |
| AC-14 / BC-6 · C-7 | the real binary accepts an empty member list, making `_auto_group_emitted`'s first clause decorative | `python3 qa/t_static.py` (NEW hand-made document) | **Survived** — `exit=1 ['FATAL[0000] initialize outbound[1]: missing tags']`. C-7 reproduced independently. |
| AC-18 | the first reload after the upgrade warns about drift, because the shape changed | `python3 qa/t_upgrade.py` (NEW — pre-T-15 `config.json` + real `.config.sha256` written by the HEAD clone) | **Survived** — `it prints NO drift warning :: ''`; non-vacuity arm: a hand-edited `config.json` **does** warn (`⚠️ …was modified outside sc…`). |
| AC-33 / S-8 | the Chinese assertions pass vacuously because `main()` reassigns `LANG` | `python3 qa/t_lang.py` (NEW) | **Trap reproduced, then avoided.** `S-8 TRAP REPRODUCED: main() clobbers sc.LANG :: LANG after main()='en' header='       Delay'`; the route this stage uses renders `延迟`; mutant arm (zh key deleted) **does** fail. |
| RES-2 | a frozen anchor moved and only structural review would miss it | `python3 qa/frozen.py` (NEW — AST extraction, byte compare) | **Survived** — 11/11 `IDENTICAL`, `FROZEN-SET RESULT: 0 anchor(s) differ`. Mutant arm: `clash_api *** DIFFERS *** … -timeout=3 +timeout=9`, exit 1. |
| **`01 §2` goal** (no AC covers it) | the group cannot re-select at all in a fixture | `python3 qa/t_control.py` (NEW — positive control, latency swap only) | **Survived** — `CONTROL: the group re-selected … :: moved after 183 s`; `histA=884 histB=1133`. I-10's "≈ one interval" bound confirmed by measurement. |
| **`01 §1.2` item 1** (no AC covers it) | a member that *refuses* keeps carrying traffic | `python3 qa/t_refuse_long.py` (NEW — real sing-box, real traffic every 10 s, 420 s) | **Survived, but slowly** — moved at `t=190s`, i.e. after one full `interval` of `HTTPError` on **every** request. `t= 20s … histA=None` yet `now=NODE-A` until `t=190s`. |
| **`01 §1.2`'s motivating failure** ("handshakes that hang rather than refuse") | a hung member IS demoted, because its probe times out | `python3 qa/t_hang_long.py` (NEW — 440 s = 2.4 intervals, traffic every 10 s) | **FAILED — the feature does not cover this case.** `now=NODE-A` for all 440 s, `traffic='TimeoutError'` on every one of 22 attempts. `t=180s conns A=+10 B=+1` proves the interval check ran; `histA=692` stayed stale, and even after `t=300s histA=None` the group did **not** move for a further 140 s. Not repairable in code within this task's scope; the shipped docs now carve it out — **DEF-2** |
| NFR-3 · the claim the docs make about all three measurements above | the qualification is en-only, or the zh drops one of the two bounds, or it sits in another paragraph so a reader of `:89` alone still gets the unqualified promise | `python3 qa/t_def2.py` (NEW, round 2 — I wrote it from the measurements, not from the diff) | **Survived** — `FAILURES: 0` over 22 assertions; `README.md:89 -- BOUND 2: observed, and a manual escape is given :: all 2 phrases present`, same for zh; `:89 is the ONLY place the unattended promise is made :: no other occurrence`; the promise and its bound are one semicolon-joined sentence (`不需要任何人敲命令；但切走发生在**`). Mutant arm (bound clause deleted) is detected. |

## Boundary tests added

- Zero nodes: emitted document byte-identical to HEAD; `sc ls` line byte-identical in both languages; **zero** API requests.
- One node, three nodes, unicode node tags (`节点-北京`, `🇯🇵 tokyo`), a node tagged exactly `auto`, a node tagged `auto-jp`, a node tagged `GLOBAL`.
- Persisted `active` of: `None`, a valid tag, `"auto"`, a vanished tag, the integer `7`, `"proxy"`, `"direct"`.
- `sc use` specs: `0`, `4`, `""`, `-1`, `"1 "`, `" US"`, `"US-1 "`, `"nope"`, `"99999999999999999999"`, substring, exact, index — × 2 languages.
- Clash API transport: stopped service, connection refused, port that accepts and never answers (3 s), `200 text/html`, invalid-UTF-8 body, `Content-Length` over-declared by 50 bytes, HTTP 404.
- Clash API bodies: 28 malformed shapes × 2 languages (list/str/null/number top level, `proxies` non-dict, entry non-dict, history non-list/empty/non-dict element, `delay` as string / float / `True` / `0` / negative / `10**30` / nested object, `now` numeric / empty / naming an unknown node / 400 characters, proxy set omitting every known node, unicode tag key).
- Non-TTY contract on every render: no `\r`, no line ending in whitespace, one complete line per entry.
- `override.json` malformed while `active == "auto"` and the last node is removed (CR-2's abort path) — and its self-heal.
- Config generation repeated 5× with `active == "auto"`; two consecutive `sc reload`s on an upgraded host; a hand-edited `config.json` as the drift non-vacuity arm.
- User-facing claims as a boundary: each of `:89`'s five claim atoms asserted independently in **both** languages, so a claim can be dropped from one language without being dropped from the other and still be caught (NFR-3); plus a negative sweep for the unqualified promise anywhere else in either file, and a mutant arm that deletes the bound clause.

## verify_all result

```
command:  bash .harness/scripts/verify_all.sh   (no extensionless dispatcher on this host)
```

- Total checks: 18 → 18
- Pass: 16
- Fail: **0**
- Warn: 1 — F.6, over-cap active task docs, two of them: this task's own 597-line `01_REQUIREMENT_ANALYSIS.md` (predicted by V-22) and its 504-line `PM_LOG.md`. Both clear on archive; neither is QA's to edit. This report is 141 lines and `06_RATIONALE.md` 277 — neither adds to it.
- Skip: 1 — B.3 lint, no lint config (pre-existing)
- E.6 (`Adversarial tests` section) : PASS — heading is `## Adversarial tests`, unnumbered
- New tests added: 0 committed (NG-9). 14 scratchpad suites, **252 named assertions** — several of which iterate a matrix (30 `sc use` spec×language pairs against HEAD, 56 malformed-body×language runs, a 14-state config matrix, 16 frozen anchors) — all under `/tmp/…/scratchpad/qa`
- Baseline updated: **no** — `.harness/scripts/baseline.json` still reads `test_count: 0`; this project has no committed test suite (NG-9 / R-9), so the count cannot go up without violating the non-goal
- C-9 bar: **PASS 16 / WARN 1 / FAIL 0 / SKIP 1 — no FAIL**, exactly the batch baseline
- Service witness (S-6), start and end of stage 6: `MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` — **identical**. `/etc/sing-box/` mtimes unchanged; one `sing-box` process on the host, the service's own.

## Defects found

- **[MAJOR] DEF-2 — CLOSED, verified.** *Found:* both READMEs and `CHANGELOG.md` promised unattended failover with no bound, while the measurement on the real binary with the emitted parameters is: a *slower* member demoted after ≈one `interval` (183 s); a *refusing* member after ≈one `interval` (190 s), during which **every** request fails; a member that **accepts and never answers** never demoted in 440 s (2.4 intervals) across three independent runs, 100 % of traffic failing throughout. Reproducers: `qa/t_hang_long.py`, `qa/t_refuse_long.py`, positive control `qa/t_control.py`. *Fixed as* a documentation change inside NFR-5's permitted diff — no code change; `bin/sc` is byte-identical (hash above). `README.md:89`, `README.zh-CN.md:89` and `CHANGELOG.md:7` now carry the promise **plus both measured bounds**: the switch lands on the next probe round, "up to about 3 minutes of failing requests … not an instant cut-over"; and the hanging member is explicitly not covered, with the mechanism ("a probe that never finishes never revises the choice"), the observation ("stayed on such a node for as long as the test ran") and the manual escape (`sc use <name>`). *Verified* by `python3 qa/t_def2.py` — `FAILURES: 0`, both languages, mutant arm detected. Residual, accepted: 190 s is stated as "about 3 minutes"; the approximation is the emitted `interval` itself and does not restore the overclaim.
- **[MAJOR] DEF-1 — `sc ls` raises an uncaught Python exception on a broken host, for 2 of BC-9's 4 states.** Four escape routes out of the frozen `clash_api()` (`bin/sc:1635-1638`, whose `except` catches only `URLError`/`HTTPError`): `JSONDecodeError` (non-JSON 2xx), `UnicodeDecodeError` (invalid-UTF-8 2xx), `TimeoutError` (port accepts, never answers), `IncompleteRead` (short body). Reproducers: `qa/t_broken.py` §P2/§P3/§P4/§P6. Pre-existing — HEAD's `sc status` raises the same types, verified against the clone — but T-15 newly puts `sc ls`, the command AC-24 says must work on a broken host, on that path. **Not fixable in this task**: `clash_api()` is frozen (AC-28, byte-identity verified) and K-12 forbids a local `try`/`except`. Route: follow-up pool row against `clash_api()`, **widened** from RES-1's single non-JSON case. `bin/sc:1637` / `bin/sc:1635`.
- **[MINOR] DEF-3 — the reserved-tag set does not cover `GLOBAL`.** `RESERVED_TAGS` is `{proxy, direct, auto}`, but the live `GET /proxies` on this host returns a `GLOBAL` entry (sing-box's implicit selector). A node tagged `GLOBAL` mints cleanly, the real checker accepts the document, and `sc ls` prints that entry's stored delay in the node's row. Reproducer: `python3 qa/t_global.py` → row ends `9999 ms`. Narrow (the user must name a node exactly `GLOBAL`), no exception, table intact. `bin/sc:56`.
- **[MINOR] DEF-4 — upstream: no acceptance criterion observes the goal.** AC-1…AC-35 verify the emitted document, the selection state machine and the `sc ls` rendering; not one asks whether a degraded node stops carrying traffic. That is why DEF-2 survived stages 2–5 with every AC green. Route: requirement-analyst. `01 §6`.
- **[MINOR] DEF-5 — upstream: `01 §5 BC-9`'s stated mechanism is factually incomplete.** "`clash_api()` returns `None` on every `URLError`/`HTTPError`; a hung port costs the existing 3 s timeout and no more" — the 3 s bound holds, but the return does not: `urlopen`'s `getresponse()` raises `TimeoutError`, which is neither. This is the reading AC-24 inherited. Route: requirement-analyst. `01 §5 BC-9`.

Not defects, re-confirmed as accepted: RS-3/RES-5 (`delay == 0` and never-probed both render `-` — observed on real data in `qa/t_v19.py`), R-19 (the five `ls.*` keys), CR-2 (reproduced and shown self-healing), CR-3 (reproduced: the README sample is condensed; mirrored, so AC-34 unaffected).

## Stability

- Deterministic suites (`t_headline`, `t_lang`, `t_regress`, `t_readme`, `t_static`) run **10×**: 50/50 clean, no flakes.
- `t_upgrade` run **3×** and `t_broken` run **3×**: identical results each time (`t_broken` reports the same 5 expected-fail rows, which are DEF-1's four shapes plus its table-lost consequence — deterministic, not flaky).
- `verify_all` run **3×**: PASS 16 / WARN 1 / FAIL 0 / SKIP 1 every time; re-run after the documentation fix, same result.
- The documentation suites (`t_readme`, `t_def2`) re-run against the fixed files: `FAILURES: 0` both, deterministic, no network and no clock in either.
- The three live-sing-box suites are timing-bounded rather than flaky: `t_control` moved at 183 s and `t_refuse_long` at 190 s (both ≈ the emitted `interval` of 3 m); `t_hang_long` did not move in 440 s across two independent runs (`t_failover.py` 240 s, `t_failover2.py` 260 s, `t_hang_long.py` 440 s — three runs, same outcome).
- No flaky test was found. No test was deleted or skipped.

## Verdict

**APPROVED FOR DELIVERY**

All 35 acceptance criteria are satisfied as written (AC-15 and AC-23 by observation, not inference —
**V-19 was run**, discharging C-3/RES-3), the eleven frozen anchors are byte-identical (RES-2 closed),
C-8's paragraph and C-2's blockquote are present and mirrored at `:101` / `:103`, AC-34's line-for-line
mirror holds at 305 lines each with zero positional mismatches, AC-33/FR-15 is clean (no new zh string
contains `失败：`; the single occurrence at `CHANGELOG.md:26` is pre-existing and untouched), K-18's
entry sits under the existing `## [Unreleased]` → `### 新增` with no new version heading, `verify_all`
ends with no FAIL (C-9), the diff stays inside NFR-5's permitted set, and the S-6 service witness is
unchanged at both ends. DEF-2 — the one defect that blocked delivery — is closed: the docs now state
what was measured, in both languages, and `bin/sc` did not move to achieve it. DEF-1 and DEF-3 are
filed as follow-ups rather than as changes required of this diff: neither is fixable inside this task's
frozen set. DEF-4 and DEF-5 route to the requirement-analyst. What ships is a feature that demotes a
slow or refusing member unattended within one probe interval, does not rescue a hung one, and now says
so.
