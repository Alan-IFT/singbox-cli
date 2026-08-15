# 06 — Test Report · T-24 `override-error-envelope`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

## Test plan

**Provenance legend, binding on every figure below.** `[R2]` = measured by this stage's second
attempt (2026-08-15 16:28–16:45), artifact `re/…`. `[R1]` = recorded transcript of the **first**
attempt (killed by an API transport error at 16:20, before it wrote anything); four results remain
`[R1]`-only and are labelled as such. `[R3]` = **re-measured in the verification round**
(2026-08-15 17:00–17:25), artifact `r2-*.txt`. The verification round re-ran exactly what the two
repairs could have moved — `verify_all` on both trees, the `git` figures, the service witness, and
every clause of the repaired `CHANGELOG.md:26` sentence — and nothing else: `bin/sc` is unchanged
since `[R2]` (mtime `2026-08-15 15:01:00`, i.e. before the `[R2]` run; `git diff --numstat` still
`79/55`; `git diff -w` still `60/36`), so M0…M8, the M9 band, the six wrong builds, C-12, C-13,
AC-1, AC-4 and T-13 were deliberately **not** re-run and keep their `[R2]`/`[R1]` markers. Stage
artifacts live in the session scratchpad and are committed nowhere; the `[R1]`/`[R2]` artifact names
are provenance labels, not paths that still exist (their session's scratchpad is gone). Nothing here
is reported as measured that no attempt ran.

**Harness** (`scratchpad/qa/qarun.py` + `qalib.py`, written at stage 6 from the criterion text, not
from `04_DEVELOPMENT.md`'s harness). Child process per fixture: the `sc` source is read, the
auto-elevate block is removed by **text** substitution before `exec` (an assert refuses to run if the
anchor is missing — C-15), the module is exec'd, all eight path constants are repointed into
`scratchpad/qa/fx/`, `_init_files` → no-op, `restart_service` → `lambda: True`,
`SYSTEMD = OPENRC = False`, `subprocess` → a logging shim, then `main()` is called with
`sys.argv = ["sc", "reload"]` and `SystemExit` propagates. `stderr` is merged into `stdout`, which is
the exact shape `install.sh` redirects into `/var/log/sing-box/install.log` (BC-3). Every fixture
carries `settings.json` with **both** `clash_api_port` and `lang`, a **pre-existing** `config.json`
= `{"SENTINEL": "config.json must survive byte-identical"}\n` and a **pre-existing** `.config.sha256`
= 64 zeros (C-1 / C-3); clause (iv) is `sha256(before) == sha256(after)` on both files, never an
existence test. `HEAD control` = a `git clone` at `2de1339`;
`sha256(head-clone/bin/sc)` = `sha256(git show HEAD:bin/sc)` = `012df625…`, verified `[R2]` and
re-verified `[R3]` on a freshly made clone. The verification round's harness (`r2_order.py`,
`r2_order_control.py`, `r2_working_overwritten.py`, `r2_no_singbox.py`) was written from the
repaired CHANGELOG sentence, not from any earlier harness, and repeats the same discipline: the
auto-elevate block removed by text substitution behind an `assert`, the same eight path constants
repointed, `_init_files` a no-op, `restart_service` stubbed, `SYSTEMD = OPENRC = False`.

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 override-less byte identity, 24 states | `ac1.py` candidate vs HEAD clone + perturbed-build control | `re/ac1.txt` |
| AC-2 (i)–(v) as amended by C-1/C-2/C-3, M0…M7 + **M8** (C-10) | `ac2.py cand` / `ac2.py head`, 13 members each | `re/ac2-cand.txt`, `re/ac2-head.txt` |
| AC-2 (v) language clause (C-2) | `qa2-lang.py` — M0/M2/M4/M8 at `lang=en` **and** `lang=zh` (NEW, mine) | `re/qa2-lang.txt` |
| AC-3 R-22 gate | `wrongbuilds.py` W-A/W-B/W-C + `wrongbuilds2.py` W-D/W-E/W-F (NEW, mine) | `re/wrongbuilds.txt`, `re/wrongbuilds2.txt` |
| AC-4 / BC-9 published recipes byte-identical | `ac4.py`, 11 valid overrides + non-vacuity control | `re/ac4.txt` |
| AC-5 one sentence for M4…M7, names the vocabulary | `c13.py` §AC-5 | `re/c13.txt` |
| AC-6 pre-existing bare-array error unchanged | `c13.py` — 11 precedence/AC-6 fixtures vs HEAD | `re/c13.txt` |
| AC-7 as amended by C-4 (`{"dns": 5}`, no override) | `ac7.py` cand / HEAD / E6-reverted build | `re/ac7.txt` |
| AC-8 `_filter_rules` frozen | `structural.py` + `qa2-extractors.py` control (NEW, mine) | `re/structural.txt`, `re/qa2-extractors.txt` |
| AC-9 / BC-7 no directive→merge edge | `structural.py` + injected-edge control | same |
| AC-10 as amended by C-5 | `structural.py` AST key extraction + bare-literal controls | same |
| AC-11 README parity | `structural.py` §AC-11 | `re/structural.txt` |
| AC-12 the published promise, per member | conjunction of AC-2 (i)–(iv) over 13 members | `re/ac2-cand.txt` |
| AC-13 `verify_all` from the repository root | two runs: working tree and pristine HEAD clone, re-run `[R3]` | this document |
| AC-14 service witness | `systemctl show -p MainPID -p ActiveEnterTimestamp` at start and end | this document |
| AC-15 shipped invocation | **BLOCKED by construction**; operator obligation **id 5** | `.harness/operator-obligations.md` |
| BC-2 no write, no child process, `nodes.json` intact | `qa2-bc2-res9.py` — 13 members, child log per run (NEW, mine) | `re/qa2-bc2-res9.txt` |
| BC-3 exactly one line | measured on the combined stream in every run above | all |
| BC-5 / T-13 / T-14 | `t13.py` syscall timeline + `qa2-conc.py` sampler (NEW, mine) | `re/t13.txt`, `re/qa2-conc.txt` |
| C-11 M9 band | `bisect_band.py` + `probe.py` in child interpreters | `re/band.txt` |
| C-12 / RES-2 forced raise on a drifted+degraded fixture | `c12.py` | `re/c12.txt` |
| C-13 precedence, every target type | `c13.py` — 8 precedence + 2 C-13 + 1 AC-6 fixture | `re/c13.txt` |
| RES-1 dual position | `ac2.py` `M4b…M7b` at `dns.servers`, both builds | `re/ac2-*.txt` |
| RES-5 diff budget | `git diff --numstat`, `git diff -w --numstat`, `git status --porcelain` | this document |
| RES-7 stub lifted | `qa2-res7.py` / `qa2-res7b.py` with the **real** `sing-box check` (NEW, mine) | `re/qa2-res7*.txt` |
| RES-7′ the repaired `CHANGELOG.md:26` tail, clause by clause | `r2_order.py` (spawn-time snapshot) + `r2_working_overwritten.py` + `r2_order_control.py` + `r2_no_singbox.py` (NEW, mine, `[R3]`) | `r2-order.txt`, `r2-order-control.txt` |
| RES-9 three load-time faults | `qa2-bc2-res9.py` §RES-9 vs HEAD | `re/qa2-bc2-res9.txt` |

### Per-criterion result

| id | verdict | evidence |
|---|---|---|
| AC-1 | **PASS** `[R2]` | `24/24 states byte-identical (emitted document AND combined stream AND exit status)`; control (`CONFIG_BASE log.level warn→info`) reports `DIFFERENT: True`. |
| AC-2 | **PASS** `[R2]` | Candidate `13 PASS / 0 FAIL` on M0…M8 + M4b…M7b: every member one line, exit `1`, both digests unchanged, no traceback. HEAD control `4 PASS / 9 FAIL`. |
| AC-2 (v) | **PASS** `[R2]` | Same member, two languages, set only through the fixture's `settings.json`: `zh` contains `无法据此生成配置`, no `失败`. |
| AC-3 | **PASS** `[R2]` | W-A (catch-all that generates a config anyway) fails `['ii','iii','iv']` on **every** member; W-C (writes then raises correctly) fails `['iv']`. |
| AC-4 | **PASS** `[R2]` | `11/11 valid overrides byte-identical to the pre-change build`; control `DIFFERENT: True`; recipe effect present; emitted mode `0o600`. |
| AC-5 | **PASS** `[R2]` | `distinct sentences over M4..M7: 1`; the sentence names all five directives (`$prepend/$append/$replace/$before/$after`). |
| AC-6 | **PASS** `[R2]` | `candidate == HEAD on 11/11 precedence/AC-6 fixtures`; `AC-6 sentence == the M4..M7 sentence: True`. |
| AC-7 | **PASS** `[R2]` | Candidate names `config.json`, not `override.json`, and renders the **assertion's own** sentence; HEAD control names `override.json` (R-26); the E6-reverted build reproduces HEAD. |
| AC-8 | **PASS** `[R2]` | Source segment identical to HEAD; call-site argument lists identical; the same extractor flags a one-line body mutation (`frozen==HEAD -> False`). |
| AC-9 | **PASS** `[R2]` | `_apply_directive` callees `['OverrideError','_anchor_index','deepcopy','isinstance','set','t']`; injected-edge control flips to `True`. |
| AC-10 | **PASS** `[R2]`, with a criteria-gap note (QA-4) | Exactly **1** new `t()` key (NFR-1 cap 2), placeholders `['fault']` on both sides, `失败` absent, unnamespaced; C-5 satisfied. |
| AC-11 | **PASS** `[R2]` | `README.md=457 README.zh-CN.md=457`, `heading/fence/table/blank-line shape divergences: 0`, FR-6's paragraph at `:400` in both. |
| AC-12 | **PASS** `[R2]` | The conjunction holds on all 13 members; BC-2 additionally shows `children=NONE` and `nodes.json identical=True` for each. |
| AC-13 | **PASS** `[R3]` (was FAIL `[R2]` → defect **QA-2**, now CLOSED) | Working tree and pristine HEAD clone both `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, both `exit 0` — **identical**, so no new FAIL and no new WARN. The `[R2]` WARN (`PM_LOG.md:505L` under F.6) is gone: the PM compacted the file to **482** lines. `verify_all.sh` itself is byte-unmodified (`git status --porcelain .harness/scripts/` empty) and `baseline.json` untouched. |
| AC-14 | **PASS** `[R2]`, re-verified `[R3]` | `MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` at start **and** end of both rounds; `NRestarts=0`; `is-active` never invoked. |
| AC-15 | **BLOCKED** `[R2]` | Operator obligation **id 5** verified present, complete and carrying V-12 verbatim plus the bisection warning. Nothing substituted. **Eighth** consecutive such obligation. |

### Gate condition disposition (03_GATE_REVIEW.md)

| id | disposition |
|---|---|
| C-1 | **Discharged** `[R2]`. Entry point `main()`, `argv=["sc","reload"]`, `_init_files()` neutralised, all eight path constants repointed, `restart_service` + `subprocess` stubbed, `settings.json` carrying `clash_api_port` **and** `lang`. Captured `SystemExit` code = **1** for every one of the 13 members. |
| C-2 | **Discharged** `[R2]`. Four members at both languages; `zh` positively contains `无法据此生成配置`; language never set by assigning the module global. |
| C-3 | **Discharged** `[R2]`. Sentinel `config.json` = `{"SENTINEL": "config.json must survive byte-identical"}\n`, `sha256 = bb2499315a356468…`; sentinel `.config.sha256` = 64 zeros + newline, `sha256 = 827d096d92f3deea…`. Before == after on all 13 members, both files. Non-vacuous: W-C and the HEAD `dns.servers` control both flip (iv) to `False` on the same fixture. |
| C-4 | **Discharged** `[R2]`. Perturbation is the pinned scalar at an object-valued key (`_dns_overlay() → {"dns": 5}`), no override present; the rendered line is the assertion's own sentence. |
| C-5 | **Discharged** `[R2]`, with QA-4. The sentence is found as a `t()` **key** at `bin/sc:2051` and `:2123`; the only bare occurrence is `:374`, the `zh` **table** key, which is required. A build with **both** emission sites bare fails the check. |
| C-6 | **Discharged** `[R2]`. Argument lists byte-identical, indentation only. |
| C-8 / K-16 | **Discharged** `[R2]` — see `## verify_all result`. |
| C-10 | **Discharged** `[R2]`. M8 `{"route":{"rule_set":{"$append":[{"tag":["a"]}]}}}` passes AC-2 (i)–(iv): 1 line, exit 1, both digests unchanged, fault clause `TypeError`. HEAD on the same fixture: **17-line traceback**. M8 is also the **only** member that kills the leaf-enumeration wrong build W-F. |
| C-11 | **Discharged** `[R2]`, band **EMPTY** — see `## Adversarial tests`. |
| C-12 / RES-2 | **Discharged** `[R2]`. On a fixture that is **both** drifted (sentinel `config.json` vs all-zero `.config.sha256`) **and** degraded (2 of 4 rule-sets missing): `_warn_degraded` forced to raise → **1 line**, exit 1, digests unchanged, fault clause `ValueError`; `_warn_drift` forced to raise → **2 lines**, the `⚠️` degraded line first, then the fault line naming `KeyError`. Both name the class of a fault that is **not** the user's (BC-11 exercised, not asserted). |
| C-13 | **Discharged** `[R2]`. `unknown directive` and `cannot be combined with other keys` fire ahead of every target test at **all four** target types (list / dict / scalar / absent), byte-identical to HEAD in text and trigger; `{"dns":{"rules":{"$nope":[]}}}` and `{"log":{"$append":[]}}` both render today's sentences unchanged. |
| C-14 | **Discharged**. AC-15 BLOCKED, obligation id 5, nothing substituted, no second row added. |
| C-15 | **Held** `[R2]`. No fixture outside the session scratchpad; `/etc/sing-box` mtime `2026-08-11 12:13:57` and `/var/lib/sing-box` mtime `2026-07-30 12:59:24` both predate this session; `/usr/local/bin/sc` untouched (113 841 bytes, the HEAD build); `is-active` never invoked. |
| C-16 | **Honoured.** No gate claim is cited here as measured; each was re-run. The gate's own M8 construction and `_merge` case table are confirmed by run. |
| C-7, C-9 | Not stage 6's to discharge (PM). C-7's permitted set is confirmed by `git status` below, with `.harness/operator-obligations.md` added under C-14's own instruction. C-9's record must carry the M9 result below. |

### Residuals disposition (05_CODE_REVIEW.md)

| id | disposition |
|---|---|
| RES-1 | **Discharged in writing** `[R2]`. At the **guarded** keys (`dns.rules` / `route.rules` / `route.rule_set`) the control does **not** discriminate: HEAD already renders one line, exits 1 and leaves both files byte-identical for M4–M7, exactly as the candidate does — only the sentence's vocabulary changed (`this must stay an array` → `an existing array must be changed with one of …`). At `{"dns":{"servers":…}}` it **does**: HEAD gives **2 lines, exit 0, bytes CHANGED**; the candidate gives 1 line, exit 1, bytes identical. No AC-2 clause and no BC-1 member changes meaning; the falsified item is the annotation, not the criterion. |
| RES-2 | **Discharged** — see C-12 above. The exactly-one-line property is structural for BC-1 only; a `⚠️` line legitimately precedes at a later abort point, and that is measured, not assumed. |
| RES-5 | **Discharged** `[R2]`, re-run `[R3]` — `git` figures below, unchanged to the digit. Stage 5's read-derived budget figures are **confirmed exactly**, and the QA-1 repair consumed **zero** budget (`CHANGELOG.md` is still `+2/−0`; the rewrite sits inside an already-added line). |
| RES-7 | **Discharged** `[R2]`; the note was **not** adequate → defect **QA-1**, now **CLOSED** by the developer's replacement tail at `CHANGELOG.md:26`, re-verified clause by clause `[R3]`. I lifted the stub (safe: the only child ever formed is `sing-box check -c <fixture>/config.json`, read-only). `inbounds` / `outbounds` are no longer named-but-unmeasured: both measured, both behave exactly as `dns.servers`. See `### RES-7` below for the clause-by-clause verification of the replacement text. |
| RES-9 | **Closed, nothing published is false** `[R2]`. The three pre-existing load-time faults (`bin/sc:1536`, `:1540`, `:1548`) each render **one** line, exit 1, leave both files byte-identical, echo no document value, and are **byte-identical to HEAD**. The CHANGELOG's leading claim (one `无法使用 …` line + non-zero exit) is true of all three; only its two-way split does not classify them. Optional one-word repair; no correctness consequence. |
| RES-3, RES-4, RES-6, RES-8 | Not stage 6's (PM). RES-4's `docs/dev-map.md:38` false clause is confirmed still present at this tree. |

## Adversarial tests

One row per acceptance criterion. The hypothesis was written **before** the run; the reproducer was
built from the criterion text, not from `04_DEVELOPMENT.md`'s harness. Cited output is ≤5 lines of
real captured output; full runs in `06_RATIONALE.md`. `<fx>` is the fixture root.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | the byte-identity harness is vacuous — it would report identical for a build that changed the override-less path too | `ac1.py` with `srcpatch-ac1-control.json` (`CONFIG_BASE log.level warn→info`) | Survived — `AC-1: 24/24 states byte-identical`, `non-vacuity control … reports DIFFERENT: True` |
| AC-2 | some member escapes as more than one line, or the sentinel `config.json` moves | `ac2.py cand`, 13 members through `main()` | Survived — `verdicts: 13 PASS / 0 FAIL`; e.g. `M8 en lines=1 exit=1 (i)=True (ii)path=True fault=True (iii)=True (iv)bytes_identical=True tb=False -> PASS` |
| AC-2 (v) | the `zh` run renders English because `main()` reassigns the language after import (BC-13) | `qa2-lang.py` (NEW) — language only in the fixture's `settings.json` | Survived — `无法使用 <fx>/override.json：无法据此生成配置（TypeError）`, `has_zh_fault=True has_shibai=False` |
| AC-3 | a build that swallows everything and writes anyway still passes AC-2, because "no traceback + one line" is all it takes (R-22) | `wrongbuilds.py` W-A (NEW) | **Killed it** — `M4: lines=1 exit=0 bytes_identical=False -> clauses failing: ['ii','iii','iv']`, output `Reloaded`. Clause (iv) is the one that bites; (ii)/(iii) also bite |
| AC-4 | the envelope changed an emitted byte on some valid recipe — an off-by-one indent, a re-ordered key | `ac4.py`, 9 recipes + `{}` + whitespace-only | Survived — `AC-4: 11/11 valid overrides byte-identical to the pre-change build`; control `DIFFERENT: True` |
| AC-5 | four shapes give four sentences, i.e. a patch list wearing a vocabulary's clothes | `c13.py` §AC-5 over M4–M7 | Survived — `distinct sentences over M4..M7: 1`; `vocabulary names $prepend/$append/$replace/$before/$after: True` ×5 |
| AC-6 | the re-derived loop moved the pre-existing bare-array error's text or its trigger | `c13.py`, 11 fixtures, string equality vs HEAD | Survived — `candidate == HEAD on 11/11 precedence/AC-6 fixtures`; `AC-6 sentence == the M4..M7 sentence: True` |
| AC-7 | the perturbation raises inside `_compose` first, so a build with E3 and **no E6** passes (F-5) | `ac7.py` with `srcpatch-E6-reverted.json` (NEW build) | **Killed the E6-less build** — cand `Cannot use <fx>/config.json: at dns.rules: this must stay an array`; E6-reverted `Cannot use <fx>/override.json: …` — the wrong document named |
| AC-8 | the criterion is decorative: it would report "frozen" for a mutated body too | `qa2-extractors.py` (NEW) one-line body injection | Survived — `shipped: frozen==HEAD -> True | mutated: frozen==HEAD -> False` |
| AC-9 | the call-graph extractor cannot see an edge it is supposed to forbid | `qa2-extractors.py` injects `_merge({}, {})` into `_apply_directive` | Survived — `shipped: edge -> False | mutated: edge -> True` |
| AC-10 | a build emitting the sentence as a bare literal passes vacuously (F-8 / C-5) | `qa2-extractors.py`, one site bare then both sites bare | **Partly survived** — both bare: `t() sites NONE … C-5 as worded -> FAIL` (killed). One site bare: `t() sites [2051] … -> PASS` — **NOT-DISCRIMINATING**, filed QA-4 |
| AC-11 | the two READMEs drifted by a line, so "same relative position" is false | `structural.py` line-shape comparison | Survived — `457 == 457`, `shape divergences: 0 []`, both `:400` |
| AC-12 | the published promise fails on the member nobody ran (M8, C-10) | `ac2.py` M8 + `qa2-bc2-res9.py` | Survived — M8 `lines=1 exit=1 (iv)=True`; HEAD on M8: `lines=17 … tb=True` |
| AC-13 | a task document trips F.6's 500-line cap, or E.6's heading grep — and, after the repair, that the WARN was made to go away by editing the check rather than the document | `bash .harness/scripts/verify_all.sh` from the root, on the working tree and on a fresh `git clone` at `2de1339`; plus `git status --porcelain .harness/scripts/` | `[R2]` **FAILED** — `PASS: 16  WARN: 1` vs clone `PASS: 17  WARN: 0`, `[F.6] … PM_LOG.md:505L`; filed QA-2. `[R3]` Survived — both trees `PASS: 17  WARN: 0  FAIL: 0  SKIP: 1`, `EXIT=0`; `.harness/scripts/` shows **no** modification, so the WARN went away because `PM_LOG.md` is 482 lines |
| AC-14 | some fixture reached the live service through a path the harness did not repoint | `systemctl show -p MainPID -p ActiveEnterTimestamp` at start and end of both rounds | Survived — `MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` identical `[R2]` and `[R3]`; `NRestarts=0`; no child process ever formed except `sing-box check` where deliberately un-stubbed |
| AC-15 | some fixture could stand in for the shipped invocation | none attempted | **BLOCKED** — needs root, the installed binary and the live service. Operator obligation id 5, V-12 verbatim. Nothing substituted |

### The wrong builds (R-22): what kills each

Six wrong builds, all constructed here, all run through AC-2's clauses on the BC-1 members. A
criterion that only checks "no traceback" is satisfied by a build that swallows the error and ships
a configuration ignoring the user's override — so each build is reported with **the clause that
kills it**, and a build that no clause kills is reported as such.

| build | what it does | killed by | evidence |
|---|---|---|---|
| **W-A** | `except Exception:` then generates and writes `config.json` anyway (Q-10's build) | AC-2 **(ii), (iii), (iv)** on every member | `M2: lines=1 exit=0 bytes_identical=False -> ['ii','iii','iv']`, line = `Reloaded` |
| **W-B** | `except Exception: return False` — the invoking command's generic line, one line, exit 1, no write | AC-2 **(ii)** alone, on every member | `M4: lines=1 exit=1 bytes_identical=True -> ['ii']`, line = `Reload failed` |
| **W-C** | renders the correct sentence and exits 1 — but writes the broken document first | AC-2 **(iv)** alone, on every member | `M8: lines=1 exit=1 bytes_identical=False -> ['iv']` |
| **W-D** | `fault=str(e)` instead of `type(e).__name__` — leaks the exception's own message | **nothing** — survives all nine members | `M2 … -> failing: NONE (SURVIVED)`, line carries `('int' object has no attribute 'get')`. **NOT-DISCRIMINATING**, filed QA-3 |
| **W-E** | label never gated: `_unusable(None, …)`, so the line always names `config.json` (K-3/E4/E6 reverted) | AC-2 **(ii)** on M1/M2/M3/M8 — but **not** on M0 or M4–M7 | `M2 … names_cfg_only=True -> ['ii_path']`; `M0 … SURVIVED` (M0 aborts at the **load** arm, `bin/sc:2051`, which is unconditional) |
| **W-F** | envelope enumerates **leaves** (`except (RecursionError, AttributeError)`) instead of being a region — the design's rejected alternative | AC-2 **(i), (ii)** on **M8 only** | `M8 lines=17 … tb=True -> ['i','ii_path','ii_fault']`; M0–M7 all `SURVIVED`. This is the measured justification for C-10 promoting M8 to a required fixture |

**No wrong build survives the whole criteria set except W-D**, and W-D's survival is a gap in the
criteria, not in the code: the shipped build renders `type(e).__name__` at both sites and never
`str(e)` (`bin/sc:2051-2052`, `:2122-2124`), so BC-4 holds **by construction** — but no criterion
would notice its removal. I tried to realise the harm and could not: across the 9 BC-1/M8 members
plus 6 purpose-built echo carriers, **no document value ever reached the line** even under W-D; the
messages carry types and interpreter text only. Reported as an uncontrolled property, not a defect.

### C-11 — the M9 band, by bisection against the interpreter's own limits

Never against the number 500: each threshold is the smallest failing depth found by bisection in a
child interpreter, confirmed at `d-1` and `d`. `[R2]`, byte-identical to the first attempt's
`band.txt`.

```
interpreter: 3.12.3        recursionlimit: 1000
deepcopy   smallest failing depth = 498    (confirm d=497: OK | d=498: RecursionError)
dumps      smallest failing depth = 996    (confirm d=995: OK | d=996: RecursionError)
loads      smallest failing depth = 9997   (confirm d=9996: OK | d=9997: RecursionError)
band = [996, 498) -> EMPTY (width 0)
```

**The M9 band is EMPTY, and I state that in writing**: `copy.deepcopy` overflows at **498**, the
hoisted `json.dumps(indent=2)` at **996**, so every document the deep copy survives, the dump also
survives — width **0**. M9 is not constructible on this interpreter; `02_SOLUTION_DESIGN.md`'s
"two holes constructible today" is confirmed to be **one** hole (M8) plus a conjecture, exactly as
gate finding F-2 suspected. C-9's rejected-decisions record must say so. End-to-end confirmation
across the whole range (`band-e2e.txt`, `[R1]`, method re-run `[R2]`): depths 497, 498, 700, 995,
996, 1200, 9996, 9997, 10047 all give `lines=1 exit=1 bytes_identical=True tb=False` — the region
covers the entire band including the two thresholds; only depth 400 (a *valid* document) reloads.
Separately, `01_REQUIREMENT_ANALYSIS.md` BC-8's "roughly half" is refuted: the ratio is ~**20×**.

### RES-7 — the pre-change harm at an unguarded array key, with the stub lifted

The one claim neither stage 4 nor stage 5 could test. I ran it with the **real** `sing-box`
(v1.13.15) un-stubbed; the only child process ever formed is `['sing-box','check','-c','<fx>/config.json']`,
read-only, against a fixture path.

```
HEAD  {"dns":{"servers":5}}  lines=6 exit=1  cfg+drift unchanged=False   RAN sing-box check -> returncode=1
   | ⚠️  Config check failed:
   | FATAL[0000] decode config at <fx>/config.json: dns.servers: json: cannot unmarshal number …
cand  {"dns":{"servers":5}}  lines=1 exit=1  cfg+drift unchanged=True    children: NONE
   | Cannot use <fx>/override.json: at dns.servers: an existing array must be changed with one of …
```

Measured on `dns.servers` (scalar, object, `null`), `inbounds` and `outbounds` — **five shapes, all
identical in kind**: HEAD silently replaces, writes the broken document, baselines its digest, and
then exits **1** with the checker's message. I could construct **no** shape in which the pre-change
build silently replaces *and* exits 0 with `sing-box` present (a bare array at an unguarded key does
not silently replace — the pre-existing sentence already rejects it on HEAD, `AC-6`). So the note's
scoping was **not** adequate: the published clause was stub-scoped **and false on any host that has
`sing-box`**, which is every host `install.sh` produces. Filed **QA-1**.

**The replacement tail, verified clause by clause `[R3]`.** The developer's new text makes five
claims. Each was re-measured on HEAD with a reproducer written from the *new sentence* (not from the
old harness, which no longer exists): `r2_order.py` snapshots `config.json` and `.config.sha256`
**at the instant the child is spawned** and then delegates to the real `sing-box`;
`r2_working_overwritten.py` first produces a configuration the real checker **accepts**, then
re-runs with the override; `r2_order_control.py` repeats everything with the checker stubbed to
`returncode 0`, which is the non-vacuity control.

| clause of the new tail | outcome `[R3]`, with output |
|---|---|
| 把你那份数组**静默替换**成你写的那个值 | **True** — with the checker stubbed, i.e. the only condition under which nothing at all objects: `CONTROL inbounds exit=0 cfg_changed=True drift_changed=True spawns=1 emitted[inbounds]=5`, and the run's whole output is `Reloaded` |
| 再把这份已经坏掉的文档正常写进 `config.json` | **True** — `config.json  sha before=bb2499315a356468 after=03b0b2e4b75e1de9 changed=True` (the sentinel is gone; `dns.servers` is the scalar `5`) |
| **在校验之前**就把漂移记录也更新成它 | **True, and established here for the first time** — `[R2]` only showed both files changed by the *end* of the run. `AT SPAWN ['sing-box', 'check', '-c', …]` / `O1 drift record already baselined onto the just-written document: True` / `O1b it is NOT still the pre-existing record: True`, on all three keys |
| 原来那份能用的配置就此被覆盖 | **True, literally** — `PHASE 1 (no override)  exit=0  sing-box check on the result -> returncode=0  => this config.json IS a working one` then `PHASE 2 … the working document survived: False   (emitted dns.servers = 5)`; the drift record at spawn is no longer the working one (`still == the working one: False`) |
| 随后 `sing-box check` 才会拦下它、让这次运行以非 0 退出（三个键上实测） | **True, and causally attributed** — `exit=1` with `FATAL[0000] … cannot unmarshal number` on `dns.servers`, `inbounds`, `outbounds`; the same fixtures with the checker stubbed give `CONTROL dns.servers exit=0` / `inbounds exit=0` / `outbounds exit=0`, so the non-zero exit is the checker's and nothing else's |

**No sixth over-claim.** I read the tail for a clause claiming more than the code delivers — the
failure mode of CR-1, CR-3, CR-8 and CR-11, all of which were clauses of this one sentence — and
found none. One clause is host-scoped rather than wrong: on a host with **no** `sing-box`, the
checker cannot be what stops the run. Measured (`r2_no_singbox.py`, `SB_BIN` pointed at a name not
on `PATH`): `HEAD, no sing-box on PATH: exit=1 traceback=True … emitted dns.servers=5`, an uncaught
`FileNotFoundError` from `bin/sc:2135`. The load-bearing half (「非 0 退出」, the overwrite, the
baselined drift record) survives even there; only the attribution to the checker does not, and
`install.sh` installs `sing-box` on every host it produces. Not filed.

### Attacks beyond the criteria

| attack | reproducer | outcome |
|---|---|---|
| **Format-string injection through a document key** — `{at}`, `{}`, `{0}`, `{fault}`, `%s` inside a key that reaches `t()`'s template | `qa2-probe.py` P1 (NEW) | Survived — rendered literally every time: `at a{at}b: unknown directive $nope — …`, 1 line, exit 1, bytes identical, no traceback |
| **Make it echo a credential-shaped value** — 6 carriers designed to put a sentinel into an exception message | `qa2-probe.py` P2 (NEW), on the W-D build | No echo on any of them (`echoes_sentinel=False` ×6). The only value-echoing sentence in the file remains `_anchor_index`'s pre-existing `—— match：{anchor}` (BC-4-permitted, Q-12 re-homed) |
| **Race the writer** — 10 concurrent `sc reload` with a sampler on `config.json` | `qa2-conc.py` (NEW) | Survived — `6276` samples, `partial/invalid documents seen: 0`, `mode wider than 0600 seen: 0`, `modes observed: ['0o600']`, `leftover .tmp files: none` |
| **Widen credential bytes for an instant** (T-13) | `t13.py` syscall timeline, both builds | Survived — `mkstemp … 0o600 size=0` → `fchmod 0o600 size=0` → `fsync 0o600 size=6373` → `replace 0o600`. Content never exists at a wider mode; identical on HEAD |
| **Turn the drift record into a copy** (T-14) | `t13.py` tail | Survived — `drift record is 64 hex: True | equals sha256(config.json bytes): True | contains any config byte-run: False` |
| **Reach the write path from a different command** | `othercmds.txt` `[R1]` — `sc use / mode / ipv6 / telemetry / add / rm / default-tun` with a broken override | Every config-emitting command aborts one-line with both files intact; the non-emitting ones (`mode`, `default-tun`) are unaffected. Candidate and HEAD differ only in the sentence's wording |
| **Kill it at the encode** — a lone surrogate in a value | `surrogate.txt` `[R1]` (also stage 4, `04_DEVELOPMENT.md:117`) | Fails **outside** the region at `_write_private`, identically on both builds: 3 lines, exit 1, `Could not write <fx>/config.json: 'utf-8' codec can't encode character '\ud800'`, files intact |

## Boundary tests added

- Override document: absent, empty file, whitespace-only, `{}`, invalid JSON, top level array /
  scalar / `null`, larger than `OVERRIDE_MAX_BYTES` (1 048 576), invalid UTF-8, a directory, a
  dangling symlink — 25 shapes in `boundary.py`, each compared against HEAD.
- Keys: containing a newline, a CR, a CSI escape, a NUL, a lone surrogate, 4 000 characters, CJK,
  and format-string metacharacters (`{at}`, `{}`, `{0}`, `{fault}`, `%s`).
- Depth: bisected thresholds 497/498 (deep copy), 995/996 (`json.dumps`), 9996/9997 (`json.loads`),
  plus 400, 700, 1200 and 10 047 — both recursion positions and the whole band between them.
- Directive edge cases: `$before`/`$after` matching 0 elements and matching 9, `$replace` with a
  non-array payload, two directives in one object, a directive at a non-list target, a directive at
  an absent key, an unknown directive at all four target types.
- Provenance: every fault run once with an override present and once without (C-12's four cases),
  so both sides of the `override is not None` gate are exercised at the same abort point.
- Concurrency: 10 parallel `sc reload` with 6 276 mode/parse samples of `config.json`.
- Rule-set state: 0, 2 and 4 of 4 rule-sets present, so the degraded warning is both absent and
  present at the measured abort points.
- Languages: every fault class rendered at `lang=en` and `lang=zh`.

## verify_all result

```
invocation: bash .harness/scripts/verify_all.sh   (from the repository root, /home/alan/Programs/singbox-cli)
working tree (candidate):  PASS: 17   WARN: 0   FAIL: 0   SKIP: 1     (exit 0)     [R3]
pristine HEAD clone 2de1339: PASS: 17  WARN: 0   FAIL: 0   SKIP: 1     (exit 0)     [R3]
[F.6] Active task docs <=500 lines each ... PASS   (PM_LOG.md is 482 lines; it was 505 at [R2])
superseded [R2] reading, kept for provenance: working tree PASS: 16 WARN: 1 (the F.6 WARN, QA-2)
```

- Total tests: `baseline.json` `test_count: 0` → `0`
- Pass: 17 on both runs — **identical to the pristine HEAD clone**, which is what AC-13 asks
- Fail: **0** on both runs
- Warn: **0** on both runs — the `[R2]` WARN is closed (QA-2); no new WARN of any kind
- Skip: 1 (`[B.3] Lint`, SKIP on both)
- `verify_all.sh` and its checks are byte-unmodified: `git status --porcelain .harness/scripts/` is
  empty, and `baseline.json` still carries `test_count: 0` with an mtime of `2026-07-31`. The WARN
  went away because the document shrank, not because the check did
- New tests added: 0 committed — **T-28 owns the committed suite**; several hundred stage-artifact
  runs under the session scratchpad (the 10-round sweep alone is 130), none committed
- Baseline updated: **no** — `test_count` stays 0; nothing lowered, no test deleted or skipped
- A.1 (no hardcoded secrets): PASS on both runs, with this task's documents in place; no credential
  byte appears in any stage document (BC-4 / verify_all A.1)
- E.6 (`## Adversarial tests` heading): PASS — this document carries it unnumbered and unsuffixed
- RES-5, `git diff --numstat` re-run `[R3]` after both repairs: `bin/sc 79/55`, `CHANGELOG.md 2/0`,
  `README.md 2/0`, `README.zh-CN.md 2/0` → **product +85 / −55** against C-8's `≤ +86 / −65`
  (added tolerance `+6` unused; removals `−55`, inside the hard `−65` with no tolerance used).
  `bin/sc +79/−55` against `≤ +80/−65`. Stage 5's read-derived figures are **confirmed exactly**,
  and the QA-1 repair consumed **zero** budget: `git diff CHANGELOG.md` is still `2 insertions(+)`,
  `0 deletions`, so the replacement tail was reworded inside an already-added line.
- RES-5, `git diff -w --numstat` `[R3]`: `bin/sc 60/36` — the 19/19 difference is the mechanical
  re-indent (D-1), consistent with the published E5 split.
- RES-5, `git status --porcelain` `[R3]`: ` M` on `bin/sc`, `README.md`, `README.zh-CN.md`,
  `CHANGELOG.md`, `CONTEXT.md` (stage 2's, excluded by C-7), `.harness/operator-obligations.md`
  (**this stage**, required by C-14), the PM-owned `docs/batches/followups/*`, plus `??` on this
  task's own document directory. **Unchanged from `[R2]`: the repairs added no file and touched
  nothing outside the permitted set.** `docs/dev-map.md` correctly untouched (RES-4 is the PM's);
  `bin/sc`'s mtime (`15:01:00`) predates both the `[R2]` measurements and the repair round.

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| **QA-1** | **MAJOR** — **CLOSED** `[R3]` | Was: the published clause `而且退出码仍然是 0，这次运行会被当成成功` is false on any host that has `sing-box` (HEAD at `{"dns":{"servers":5}}` / `{"inbounds":5}` / `{"outbounds":5}` with the real checker: `lines=6 exit=1`, `FATAL … cannot unmarshal number`), because stage 4 measured it with `subprocess.run` stubbed to `returncode 0`. **Closed by**: the developer replaced the tail (C-7 routes `CHANGELOG.md` to the developer, so the PM rolled its own edit back — correct). **Verified by**: `r2_order.py` / `r2_working_overwritten.py` / `r2_order_control.py` / `r2_no_singbox.py`, written fresh from the *new* sentence; all five clauses hold, including the ordering claim 「在校验之前」 that `[R2]` had **not** established. See `### RES-7`. No sixth over-claim; budget unchanged (`+2/−0`). | `CHANGELOG.md:26` |
| **QA-2** | **MINOR** — **CLOSED** `[R3]` | Was: one new WARN against a pristine HEAD clone, `[F.6] … PM_LOG.md:505L`, so AC-13 ("no new FAIL and no new WARN") failed. **Closed by**: the PM compacted `PM_LOG.md` to **482** lines (it passed through 531 mid-round; the developer reported that re-inflation rather than assuming it away). **Verified by**: re-running `bash .harness/scripts/verify_all.sh` from the repository root — `PASS: 17 WARN: 0 FAIL: 0 SKIP: 1`, `EXIT=0` — and on a **freshly made** clone at `2de1339`, byte-identical counts; plus `git status --porcelain .harness/scripts/` empty, so no check was weakened to get there. | `docs/features/override-error-envelope/PM_LOG.md` (482L) |
| **QA-3** | **MINOR** (criteria gap, no product change requested) | `python3 scratchpad/qa/wrongbuilds2.py` — build W-D (`fault=str(e)`) survives **all nine** BC-1/M8 members and every AC-2 clause: `M2 … -> failing: NONE (SURVIVED)` with the line carrying `('int' object has no attribute 'get')`. No criterion in the set controls BC-4's no-echo property at runtime; it holds by construction only. 6 purpose-built carriers produced **no** actual echo, so the hazard is real but unrealised. Suggested owner: T-28's committed suite. | `bin/sc:2122-2124` |
| **QA-4** | **MINOR** (criteria gap, no product change requested) | `python3 scratchpad/qa/qa2-extractors.py` — with the region's emission site rewritten as a bare literal, C-5's check still reports `t() sites [2051] … PASS`; only when **both** sites go bare does it report `FAIL`. C-5 as worded ("found as a `t()` key") is satisfied by a partial bare-literal build. Strengthened form ("no emission site is a bare literal") passes on the shipped file: bare occurrences are `[374]`, the `zh` table key alone. | `bin/sc:2051`, `:2123` |
| **QA-5** | **NIT** (feeds C-9, PM) | `python3 scratchpad/qa/bisect_band.py` → `band = [996, 498) -> EMPTY (width 0)`. `02_SOLUTION_DESIGN.md`'s M9 is **not constructible** on CPython 3.12.3; gate finding F-2 is confirmed by measurement. The rejected-decisions record C-9 mandates must not cite M9 as a constructed hole. Also refutes `01_REQUIREMENT_ANALYSIS.md` BC-8's "roughly half" (measured ~20×). | `02_SOLUTION_DESIGN.md` §"Smaller alternative rejected"; `01_REQUIREMENT_ANALYSIS.md:96-98` |
| **QA-6** | **NIT** (upstream stage doc, now stale; no re-test, no product change) | New at `[R3]`. `04_DEVELOPMENT.md:120` still asserts in the present tense **"QA-2 is still open at this tree and `verify_all` still reports it … `PM_LOG.md` is 531 lines … `PASS 16 / WARN 1`"**, and adds "`04_DEVELOPMENT.md` is 132 lines". Measured now: `PM_LOG.md` **482**, `verify_all` `PASS 17 / WARN 0`, `04_DEVELOPMENT.md` **135**. True when written, false at the delivered tree. Not mine to edit (rule 2); flagged so the record is not left claiming a defect that is closed. Does **not** block delivery. | `docs/features/override-error-envelope/04_DEVELOPMENT.md:120` |
| **BLOCKED** | — | AC-15 needs root, the installed binary and the live service. Operator obligation **id 5**, V-12's recipe verbatim, with the bisection warning attached. Nothing substituted; no second row added. | `.harness/operator-obligations.md:5` |

No BLOCKER, no CRITICAL, and **nothing open that blocks delivery**. `bin/sc` passed every criterion
it was measured against, including six adversarial builds, and is byte-unchanged since `[R2]` — no
developer code change was ever requested by this stage. **QA-1 and QA-2 are CLOSED and re-verified
`[R3]`.** What stays open is deliberately not a repair request: QA-3 and QA-4 are **criteria gaps**
(the criteria set would not notice a regression; the shipped code is correct today), QA-3 re-homed
to T-28's committed suite; QA-5 is a NIT feeding C-9's record; QA-6 is a stale figure in an upstream
stage document; AC-15 stays **BLOCKED** by construction under operator obligation **id 5**, nothing
substituted. The PM-owned RES-4 (`docs/dev-map.md:38`) is unrelated to this stage's two defects and
still open.

## Stability

- The 13-member AC-2 sweep was repeated **10 times** (130 runs): `members with more than one
  distinct observation (flaky): NONE`; every member stable at `lines=1 exit=1 bytes_identical=True`,
  with the rendered line identical across all rounds.
- Cross-attempt stability: `ac2.py`, `ac1.py`, `ac4.py`, `ac7.py`, `c12.py`, `c13.py`,
  `structural.py`, `boundary.py`, `wrongbuilds.py`, `bisect_band.py` and `t13.py` were each re-run
  today and produced output **byte-identical** to the first attempt's transcripts (`t13.py` modulo
  its temp-file names). Two independent runs, hours apart, same machine, same answers.
- Verification round `[R3]`: `r2_order.py` at `dns.servers` was run **3** further times; the
  observation block (`exit`, both digests, `O1`, `O1b`, `O2`) hashes to the same `md5` on all three
  (`7510a649d19fd788d86cd79caa557dec`). `verify_all` was run twice (working tree, fresh clone) with
  identical counts. No flake.
- No flake observed, no test quarantined, no test deleted or skipped, no `verify_all` check modified.
- Service witness, `systemctl show -p MainPID -p ActiveEnterTimestamp` (never `is-active`): before
  `MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`; after, **identical**, with
  `NRestarts=0` — and identical again at both ends of the verification round, which ran the real
  `sing-box check` against scratchpad fixtures. Identical to stage 4's readings. `/etc/sing-box`
  (`2026-08-11 12:13:57`) and `/var/lib/sing-box` (`2026-07-30 12:59:24`) mtimes both still predate
  this work; `/etc/sing-box/config.json` mtime unchanged; `/usr/local/bin/sc` is still the HEAD build
  (113 841 bytes) and was never invoked. The four `.srs` rule-sets were **read** out of
  `/etc/sing-box/rules/` to build a checker-valid fixture; nothing was written there.
- Four results are `[R1]`-only (the first attempt's transcripts, not re-run today):
  `othercmds.txt`, `surrogate.txt`, `res7.txt`/`res7b.txt` (superseded by my own `qa2-res7*.py`) and
  `extractor-controls.txt` (superseded by `qa2-extractors.py`). None carries a criterion verdict on
  its own.

## Verdict

APPROVED FOR DELIVERY — QA-1 and QA-2 CLOSED and re-verified; AC-15 stays BLOCKED under operator obligation id 5.
