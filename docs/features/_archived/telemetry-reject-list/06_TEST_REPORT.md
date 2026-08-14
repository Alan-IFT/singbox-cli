# 06 — Test Report · T-17 `telemetry-reject-list`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

Mode: **full**. Upstream contract portions `01`, `02`, `03`, `04`, `05` all present and read
in full. `04_RATIONALE.md` opened under **T6.2** (re-measuring stage 4's behavioural claims)
and `05_RATIONALE.md` under **T6.3** (RES-1…RES-4 are not self-contained in `05`'s contract).
`.harness/rules/70-doc-size.md` carries no `## Stage-doc boundary rule` section, so the agent
schema is applied as written: every transcript, the rig sources and the measurement narrative
live in `06_RATIONALE.md`.

**Headline, stated where the count is stated (RES-4).** 95 behavioural observations, each
with a pristine-HEAD-clone control classified before the run: **93 pass, 0 fail, 2
INCONCLUSIVE**. One of the two is **AC-B6b *as the criterion is written***, which comes back
inconclusive by construction — its bundled control can only agree — exactly as stage 4
reported (DD-5). Its two split halves, `[A]` and `[D]`, both pass, and the `[D]` half was
observed on **all 16** other listed names, not a sample (RES-3). The other inconclusive is an
adversarial observation **I mis-declared** as `[D]`; it is reported rather than re-classed.
A reader who stops here has not learned the opposite of what happened.

## Test plan

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-B1 listed name + subdomains rejected `NXDOMAIN`, no stub receipt, <100 ms | `S1\|rule\|{hm.baidu.com, x.hm.baidu.com, a.b.c.hm.baidu.com}` × HEAD control; `O-B1-*` | `qa6/run_behav.py`, `qa6/compare.py` |
| AC-B2 same in clash mode `global` and `direct` | `S1\|global\|*`, `S1\|direct\|*`, mode set through the **fixture's own** controller; `O-B2-*` | `qa6/run_behav.py` |
| AC-B3 after `telemetry allow` the name resolves to the same stub as HEAD | `S3` × 3 modes × 2 names; `O-B3-*`; also the resolved-answer non-vacuity proof | `qa6/run_behav.py`, `qa6/smoke6.py` |
| AC-B4 near-miss / domestic / geosite-google / no-rule names unchanged | `S1` + `S2`, 4 names × 3 modes × 2 rule-set states = 24; `O-B4-*` | `qa6/run_behav.py` |
| AC-B5 rule-sets unusable, node accepts-never-answers, zero nodes | `S2`, `S5`, `S4` × 3 modes; `O-B5-*` | `qa6/run_behav.py` |
| AC-B6a README add recipe under **both** settings | `S6a`, `S6b`; `O-B6a-*` | `qa6/run_behav.py` |
| AC-B6b README exception recipe: one name restored, every other rejected | `S7` — the excepted name **plus all 16 others**; `O-B6b-asWritten`, `O-B6b-i`, `O-B6b-ii-*` | `qa6/run_behav.py` |
| AC-B7 every behavioural observation has a classified control | `qa6/compare.py`, one `[D]`/`[A]` per **observation**; 95 observations, `[D]` 52 / `[A]` 43 | `qa6/compare.py` |
| AC-1 one reject rule, three keys, no `rule_set` | `check("AC-1", …)` × 6 | `qa6/struct6.py` |
| AC-2 index relation in all four states | `check("AC-2", …)` × 6 | `qa6/struct6.py` |
| AC-3 anchor match counts in all four states | `check("AC-3", …)` × 8 | `qa6/struct6.py` |
| AC-4 `allow` byte-identical to pre-T-17, same fixture path | differential × 6 states | `qa6/struct6.py` |
| AC-5 real `sing-box check` in six states | `sing-box check -c` × 6 | `qa6/struct6.py` |
| AC-6 one definition of list and setting; deletion test | `ast` load-node census + two deletion mutants | `qa6/struct6.py`, `qa6/deletion6.py` |
| AC-7 eleven frozen symbols byte-identical to HEAD | `ast` extraction + sha256, 25 symbols; **no `grep`** (K-15) | `qa6/freeze.py`, `qa6/freeze_nonvacuity.py` |
| AC-8 no literal, no fourth guard key, no new path/wait/import | `ast` diff of top-level assigns, imports, `timeout=` kwargs | `qa6/struct6.py` |
| AC-9 ≤24 names, one source line each, four classes | list audit against N-1…N-18 + first-hand resolution check | `qa6/struct6.py`, `qa6/names6.py` |
| AC-10 six `main()`-driven runs, both languages | `run_main(["telemetry", v])` × 6, `lang` seeded in fixture `settings.json` | `qa6/cmd6.py` |
| AC-11 `show` writes nothing, does nothing service-affecting | mtime+size snapshot of the whole fixture root, `restart_service` recorder | `qa6/cmd6.py` |
| AC-12 no-op vs changing set, both directions + C-8's third case | mtime witness + recorder, with the changing run as non-vacuity control | `qa6/cmd6.py` |
| AC-13 absent file / absent key / bad value, both languages | 6 fixtures, stderr line-counted | `qa6/cmd6.py` |
| AC-14 bad argument in mixed case, incl. `on`/`off` | 7 arguments × fixture snapshot | `qa6/cmd6.py` |
| AC-15 BC-13 upgrade, two consecutive `sc reload` | pre-T-17 `config.json` + digest written by the HEAD clone | `qa6/cmd6.py` |
| AC-16 six new keys, placeholder parity, no `失败：`, no `ls.*` | `ast`-extracted `TRANSLATIONS`, candidate vs HEAD | `qa6/struct6.py` |
| AC-17 READMEs mirrored, FR-12's six items, changelog | line/heading/fence/table skeleton comparison + K-11/K-12 scan | `qa6/docs6.py` |
| AC-18 both READMEs' recipes copy-pasteable and correct | 3 fenced blocks × 2 revisions × 2 settings × 2 rule-set states = 24 | `qa6/docs6.py` |
| AC-19 `telemetry` help row at the existing alignment | display-column comparison against `ipv6` and `update-interval` | `qa6/docs6.py` |
| AC-20 `py_compile`, 3.6 syntax floor | compile + `ast` scan | `qa6/struct6.py` |
| AC-21 `verify_all` with no FAIL against 17/0/0/1 | `bash .harness/scripts/verify_all.sh` | — |

## Adversarial tests

One row per acceptance criterion, each with a hypothesis written **before** the run and an
independent reproducer built at this stage from the criterion — not from `04`'s test code.
Cited output is real; full runs are in `06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-B1 | the rule is emitted but the running binary still queries upstream, or answers slowly | `qa6/run_behav.py` S1 + `compare.py` (NEW) | Survived — `hm.baidu.com A NXDOMAIN ANS=0 [qr aa rd ra] stub=None qtime=1ms`; HEAD `NOERROR ANS=1 stub=direct` |
| AC-B2 | `global`/`direct` bypass the rule, as the field-report slot would have | same, mode via the **fixture's** Clash API (NEW) | Survived — `global`/`direct` both `NXDOMAIN ANS=0 stub=None`; HEAD `global` `NOERROR/1/stub=remote` |
| AC-B3 | `allow` still leaves a rejection, or moves which resolver answers | S3 × 3 modes (NEW) | Survived — `S3\|rule\|hm.baidu.com NOERROR ANS=1 stub=direct`, identical to HEAD in all 6 pairs |
| AC-B4 | the new rule steals a name it must not, in some mode/rule-set corner | S1+S2, 24 combinations (NEW) | Survived — 24/24 same stub as HEAD, e.g. `nothm.baidu.com … stub=direct` both sides |
| AC-B5 | rejection depends on a usable rule-set or a reachable node | S2 / S5 / S4 × 3 modes (NEW) | Survived — all 9 `NXDOMAIN ANS=0 stub=None`; HEAD `S5\|global` `NO-ANSWER after 6020.7 ms` |
| AC-B6a | the add recipe works under `block` only | S6a + S6b (NEW) | Survived — `tracker.example.com NXDOMAIN` under **both** settings |
| AC-B6b | "every other listed name stays rejected" holds for the 5 stage 4 sampled but not all 16 | S7, all 17 names probed (NEW) | Survived — 16/16 `NXDOMAIN ANS=0 aa stub=None`; excepted name `NOERROR/1/stub=direct`. **Bundled `[D]` = INCONCLUSIVE** (control can only agree) |
| AC-B7 | some observation has no control, or a control that neither reproduces nor agrees | `compare.py`, per-observation classes (NEW) | **95 obs, 93 pass / 0 fail / 2 INCONCLUSIVE**, `[D]` 52 / `[A]` 43 — both inconclusives named above |
| AC-1 | `answer` or `rule_set` sneaks in, or `rcode` is lower-cased | `struct6.py` key-order read | Survived — `['action', 'rcode', 'domain_suffix']`, `NXDOMAIN`, no `answer`/`rule_set`/`server`, no leading dot |
| AC-2 | the rule lands after a `clash_mode` rule in the degraded state | index relation × 4 states | Survived — `hosts=1 < reject=2 < Global=3, Direct=4, remote_dns=[3, 5]` (and `[3]` degraded) |
| AC-3 | an anchor matches 0 or 2 elements in some state | subset-equality count × 4 states | Survived — `G=1 D=1 hosts=1` in all four; `{rcode:NXDOMAIN}` 1 under `block`, 0 under `allow` |
| AC-4 | `allow` is not really byte-identical — a key order or whitespace drift | differential at the **same** fixture path × 6 | Survived — 6/6 identical (`5334/3573/5712/3951/6006/4245` bytes) |
| AC-5 | the real binary rejects the document in some state | `sing-box check` × 6, real `.srs` bytes | Survived — 6/6 `rc=0` |
| AC-6 | a second spelling of the list or the setting exists somewhere | `ast` load census + deletion mutants | Survived — 2 code consumers each; after deleting the second, `overlay still emits 17 names, identical=True` |
| AC-7 | a frozen symbol drifted by a byte and reading missed it (RES-1) | `ast` slice + sha256 vs a pristine clone | Survived — `25/25 symbols byte-identical (RES-1 set: 11)`; comparator proven non-blind on a 1-space mutant |
| AC-8 | a new constant, wait or import slipped in | `ast` diff candidate vs HEAD | Survived — `new module-level constants = ['TELEMETRY_NAMES']`, imports unchanged, `timeout=` 3 before / 3 after |
| AC-9 | a listed name does not exist, or lacks its justification | list audit + 3-resolver check | Survived — 17 ≤ 24, 4 classes, comment on every line; all 17 `NOERROR`, dropped N-7 `NXDOMAIN` on all 3 |
| AC-10 | `main()` reassigns `LANG`, so the Chinese path renders English | 6 `main()` runs, `lang` seeded in `settings.json` | Survived — zh first line `遥测域名拦截 → block`; `show` = 19 lines; `lines[2:] == list(TELEMETRY_NAMES)` |
| AC-11 | `show` touches a file or the service | full-tree mtime+size snapshot + recorder | Survived — `7 files, not one mtime or size changed`, `restart recorder: 0 calls` |
| AC-12 | the no-op run still regenerates, or the witness cannot fire at all | both directions + non-vacuity control | Survived — no-op `restarts=0`, `config.json` never generated; changing run `restarts=1`, mtime changed |
| AC-13 | a hand-edited value prints two lines, or none | 6 fixtures, stderr line-counted | Survived — absent/absent-key → `'block'`, 0 stderr lines; bad value → `'block'` + exactly 1 line naming file, key, both values |
| AC-14 | `on`/`off` are silently accepted, or something is written first | 7 arguments + fixture snapshot | Survived — `on`/`off`/`xyz` exit 1, name the three values, snapshot unchanged; `BLOCK`/`Allow`/`SHOW` accepted |
| AC-15 | the upgrade prints a drift warning on the first reload | HEAD clone writes the pre-T-17 pair, then two reloads | Survived — first `exit=0, drift warnings=0`; second `exit=0, stderr=''` |
| AC-16 | a `zh` value lost a placeholder or a key was renamed | `ast` `TRANSLATIONS` diff | Survived — 6 new keys, placeholder sets equal, no `失败：`, no `ls.*`, no pre-existing key touched |
| AC-17 | the two READMEs drifted by a line, or a sentence over-claims | skeleton comparison + K-11/K-12 scan | Survived — `432 / 432` lines, 25 headings / 42 fences / 63 rows on identical lines; the one IP-layer mention is the required negation |
| AC-18 | a published recipe fails in a state its author did not try | 3 blocks × 2 revisions × 2 settings × 2 rule-set states | Survived — 24/24 applied; `recipe 3 / candidate / block: user=[2, 3] shipped=[4]` |
| AC-19 | the overflowing row breaks the column convention | display-width comparison, D-7's convention | Survived — `telemetry` (28 ch) → col 32, `update-interval` (27) → col 31, both exactly 2 spaces; `ipv6` pads to 30 |
| AC-20 | 3.7+ syntax crept in | `py_compile` + `ast` scan | Survived — compiles; no walrus, no `dataclasses`, no new `capture_output=` |
| AC-21 | the new documents trip a `verify_all` check | `bash .harness/scripts/verify_all.sh` | Survived — `PASS: 17 / WARN: 0 / FAIL: 0 / SKIP: 1` |
| *(invented)* non-vacuity | the rig cannot see a *resolved* answer, so every green is an artifact | `qa6/smoke6.py`, one instance, four names (NEW) | Survived — `example.org NOERROR/1/stub=remote` **and** `hm.baidu.com NXDOMAIN/0/stub=None` in the same second |
| *(invented)* BC-9 near miss | `notX` or `X.evil.net` is swallowed by the suffix match | S1, 2 names × 3 modes (NEW) | Survived — `nothm.baidu.com NOERROR/1/stub=direct`, `hm.baidu.com.evil.net NOERROR/1/stub=remote`, both identical to HEAD |
| *(invented)* over-match | the parent, a sibling TLD, or an IDN look-alike is rejected too | `qa6/adv6.py` (NEW) | Survived — `baidu.com NOERROR/1`, `hm.baidu.com.cn NOERROR/1`, `xn--hm-baidu-0m3f.com NOERROR/1` |
| *(invented)* case + depth | matching is case-sensitive, or breaks at a long label / deep name | `qa6/adv6.py`, `qa6/run_behav.py` (NEW) | Survived — `X.Hm.BaiDu.CoM`, `a×63.hm.baidu.com`, 20-label name: all `NXDOMAIN ANS=0 aa` |
| *(invented)* transport | rejection is UDP-only and a TCP client escapes it | `S1tcp` with `dig +tcp` (NEW) | Survived — `NXDOMAIN ANS=0 aa stub=None` over TCP; control `example.org NOERROR/1/stub=remote` |
| *(invented)* query type | only A/AAAA are rejected | `S1\|*\|hm.baidu.com\|MX` (NEW) | Survived — `MX NXDOMAIN ANS=0 aa stub=None`; HEAD `NOERROR ANS=0 stub=direct` (leak) |
| *(invented)* BC-11 bootstrap | the list breaks `sc`'s own DoH bootstrap | `cloudflare-dns.com` probe + hosts-table membership (NEW) | Survived — `NOERROR ANS=2 [qr aa rd ra] stub=None`; no hosts entry is matched by any listed suffix |
| *(invented)* C-4 re-measure | the anchor swap was justified on a defect that does not reproduce | `qa6/adv6.py` `sc telemetry allow` under each anchor (NEW) | Survived — old anchor `exit=1 … $before matched 0 elements, but exactly one is required`; shipped anchor `exit=0` |
| *(invented)* BC-6 | `$replace` on `dns.rules` does *not* remove the rule, contradicting the doc | `qa6/adv6.py` (NEW) | Survived — `dns.rules=[{"server": "direct_dns"}]`, reject rule gone, `generate_config()=True` — the documented contract |
| *(invented)* BC-8 under `allow` | the user's own rule dies with the shipped one | `S6b` (NEW) | Survived — `tracker.example.com NXDOMAIN` while `hm.baidu.com` resolves. **Declared `[D]`, control can only agree → INCONCLUSIVE as declared**; the informative half is `O-B6a-allow` `[A]`, pass |
| *(invented)* malformed settings | a non-object `settings.json` crashes only the new reader | `qa6/boundary6.py` with HEAD's `_ipv6_setting()` as control (NEW) | **Defect, pre-existing** — `null` → `TypeError: argument of type 'NoneType' is not iterable`, identical on HEAD's reader. D-4 |
| *(invented)* concurrency | 10 parallel sets corrupt `settings.json` | `qa6/boundary6b.py`, HEAD's `sc ipv6` as control (NEW) | **Defect, pre-existing** — `candidate 5/10 raised JSONDecodeError`, `HEAD 1/10`; final file still parses. D-2 |
| *(invented)* persist-then-fail | a failed regeneration leaves the setting recorded anyway | `qa6/boundary6b.py`, HEAD's `sc ipv6 on` as control (NEW) | **Defect, pre-existing** — `exit=1, settings['telemetry']='allow' persisted, config.json written=False`; HEAD identical. D-3 |

## Boundary tests added

- Empty / absent / key-absent `settings.json`, and a value present but unrecognised, in both languages.
- `settings.json` that is valid JSON but not an object: `null`, `[]`, `42`, `"telemetry"`, `["telemetry"]`, and `{"telemetry": 5 / null / ["block"]}`.
- Non-JSON and non-UTF-8 `settings.json`, against both the `show` and the `set` form, each with a HEAD-side control.
- Zero nodes, one node and three nodes; all four rule-sets usable and all four unusable.
- Every node outbound accepting the connection and never answering (a real TCP listener that accepts into a held list).
- All three clash modes, switched through the fixture's own controller, for every behavioural scenario.
- Label-boundary cases: apex, one-label, three-label and 20-label subdomains; a 63-character label; the parent domain; a sibling TLD (`hm.baidu.com.cn`); a character-suffix near miss (`nothm.baidu.com`); a listed name used as a *prefix* (`hm.baidu.com.evil.net`); mixed and upper case; a punycode look-alike.
- Query types beyond A: `AAAA` and `TYPE65` with AAAA suppression in effect and without, and `MX`.
- DNS over TCP as well as UDP, each with its own non-vacuity control.
- Ten parallel `cmd_telemetry()` set-form invocations, with HEAD's `cmd_ipv6()` as the pre-existence control.
- Argument case and near-values: `BLOCK`, `Allow`, `Show`, `SHOW`, `on`, `off`, `xyz`.
- Override documents: the three published recipes, the never-shipped stage-2 anchor, an unrelated broken anchor, and a `$replace` of the whole `dns.rules` array.
- Non-TTY output: every command run captured through a pipe; no `\r` in any new output.

## verify_all result

```
command:                 bash .harness/scripts/verify_all.sh
total checks:            18
pass:                    17
fail:                    0
warn:                    0
skip:                    1  (B.3 lint — no linter in this project, unchanged)
baseline:                PASS 17 / WARN 0 / FAIL 0 / SKIP 1 — preserved, not lowered
E.6 Adversarial tests:   PASS
F.6 doc-size:            PASS with 06_TEST_REPORT.md and 06_RATIONALE.md counted;
                         V-21's predicted WARN did not occur, because the transcripts
                         went to the rationale portion. If it ever WARNs it clears on
                         archive-task and must not be fixed by deleting content
behavioural observations: 95 — 93 pass / 0 fail / 2 INCONCLUSIVE
inconclusive #1:         AC-B6b AS THE CRITERION IS WRITTEN (bundled control can only
                         agree — NFR-8 makes that inconclusive by construction). Its
                         split halves V-27b-i [A] and V-27b-ii [D] both pass, and the
                         [D] half was observed on ALL 16 other listed names
inconclusive #2:         one adversarial observation I declared [D] that is an agreement
                         observation by construction; reported, not re-classed
control classes:         [D] 52 / [A] 43, declared per OBSERVATION before the run (C-2)
structural checks:       AC-1…AC-21 — 0 failures across struct6/deletion6/cmd6/docs6
AC-7 freeze (RES-1):     25/25 symbols byte-identical by ast+sha256; RES-1's 11 included
new tests added:         0 committed (out-of-scope item 10 / R-9 owns a committed harness)
                         14 throwaway harness scripts, sources named in 06_RATIONALE.md
baseline updated:        no — .harness/scripts/baseline.json records test_count 0 and this
                         project has no committed suite; .harness/** is also outside
                         NFR-3's permitted diff, so this stage may not write it
service witness (start): MainPID=2566751  ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
service witness (end):   MainPID=2566751  ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
                         identical — the live sing-box was never restarted, reloaded or
                         stopped; no PUT/PATCH/DELETE reached 127.0.0.1:29090
```

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| D-1 | MINOR | `wc -l README.md README.zh-CN.md` → `432 / 432`; two stage documents state 433. The mirror property itself holds (25 headings, 42 fences, 63 table rows on identical line numbers). Stage-4/5 reporting accuracy; PM at delivery | `docs/features/telemetry-reject-list/04_DEVELOPMENT.md:40`, `05_CODE_REVIEW.md:64` |
| D-2 | MINOR | `python3 qa6/boundary6b.py` — 10 parallel set-form invocations: `candidate 5/10 raised JSONDecodeError`, `HEAD (sc ipv6) 1/10`. `save_settings()` is a non-atomic `write_text()` and is byte-identical to HEAD. **Pre-existing, and BC-17 declares this shape unchanged and out of scope**; belongs to RES-8's pool row | `bin/sc:492` |
| D-3 | MINOR | `python3 qa6/boundary6b.py` § C — `sc telemetry allow` with an unrelated broken `override.json`: `exit=1, settings['telemetry']='allow' persisted, config.json written=False`. HEAD's `sc ipv6 on` is identical on the same fixture. **Pre-existing shape, not a T-17 regression**; DD-1 removed the shipped recipe that made it reachable | `bin/sc:2673-2686` |
| D-4 | MINOR | `python3 qa6/boundary6.py` § A — a `settings.json` that is valid JSON but not an object (`null`, `42`, `"telemetry"`) raises `TypeError: argument of type 'NoneType' is not iterable` out of `_telemetry_setting()`. HEAD's `_ipv6_setting()` raises the identical error on the identical input. **Pre-existing family (R-25); C-5 and D-10 forbid widening the guard here.** It widens RES-8's proposed `except (OSError, ValueError)` at `load_settings()` to "and a non-object document" | `bin/sc:1681-1686` |
| D-5 | MINOR | Still open from stage 5, confirmed present at this stage: `02_SOLUTION_DESIGN.md` RS-3's glossary term and I-9's "Published anchors" row still define the reject rule by `{"rcode": "NXDOMAIN"}`, which no README publishes (RES-5); and `bin/sc:1595-1596` still carries the K-12-forbidden negative-caching sentence in frozen T-16 source (RES-6). PM-owned at delivery, in C-7's amendment pass | `02_SOLUTION_DESIGN.md:283`, `bin/sc:1595` |

No BLOCKER, CRITICAL or MAJOR defect exists. D-2, D-3 and D-4 each have a HEAD-side control
proving they are pre-existing and none is introduced or widened by this task; D-1 and D-5 are
document accuracy, owned by the PM at delivery. **CR-1 / RES-7 is closed** — `docs/dev-map.md`
now names `{"clash_mode": "Direct"}` as the second published anchor and "T-17's three
recipes", which is what stage 5 asked for.

**Two obligations this stage cannot discharge, routed rather than performed.** (a) The
behaviour change reaches the owner's live host only when a human installs the new `bin/sc`
and runs `sc reload` there — no agent on this project may touch `/usr/local/bin/` or the
live service, so that is a standing operator step. It is **not** written to
`.harness/operator-obligations.md`, because `.harness/**` is outside NFR-3's permitted diff
for this task; it travels to the PM. (b) `.harness/scripts/baseline.json` is untouched for
the same reason, and has nothing to raise: it records `test_count: 0` and this project ships
no committed suite.

## Stability

- The full behavioural matrix was run **5 complete times** on the candidate: 115 observation keys × 5 = **575 probes, 0 keys whose `(status, answers, stub)` varied**. No flake was observed and none is named.
- Run durations 12.7 / 11.8 / 12.4 / 12.4 / 12.0 s — no drift, no warm-up effect.
- `dig`-reported query time across all 575 probes: `min=2 p50=3 p95=4 max=7 ms`; end-to-end wall time for the 290 rejection probes `p50=18.3 max=25.8 ms`.
- FR-3's 100 ms budget is stated honestly rather than claimed: `wall − dig's own query time` is `p50 = 15.5 ms`, so **a `dig`-driven assertion is asserting ≈84 ms of headroom, not 100 ms**; sing-box's own answer is 2–7 ms with no warm-up curve.
- No claim is made or tested about client-side negative caching (K-12).
- The deterministic checkers (`freeze.py`, `struct6.py`, `cmd6.py`, `docs6.py`) are pure functions of the working tree and were each re-run after every edit; `verify_all` was run twice at this stage with identical results.

## Verdict

APPROVED FOR DELIVERY
