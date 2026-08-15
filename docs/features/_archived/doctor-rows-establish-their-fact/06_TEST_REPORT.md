# 06 — Test Report · T-26 `doctor-rows-establish-their-fact`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

Mode: **full**. Upstream contract portions `01`, `02`, `03`, `04`, `05` all present and read in
full. `04_RATIONALE.md` opened under **T6.2** (I re-take stage 4's BC-C and V-1 measurements rather
than inherit them); `05_RATIONALE.md` opened under **T6.3** (RES-1…RES-8 are not self-contained in
`05`'s contract portion, and the reviewer's rejected readings bear on BC-A and NFR-2). `01`/`02`
rationales not reached — no criterion's verification step was under-specified (T6.1 did not fire).
`.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` (**R-37, nineteenth
confirmation**), so the agent schema is applied as written: every transcript, the fixture source and
the rejected readings live in `06_RATIONALE.md`.

**The standard applied (R-22, diagnostic form).** A criterion that merely re-asserts a row's current
behaviour would certify the defect, so every criterion labelled **discriminating** was run on the
candidate **and** on a pristine HEAD clone, and both halves are reported. **All 7 discriminating
criteria discriminated**; none is reported `NOT-DISCRIMINATING`. Nothing was BLOCKED — no criterion
in this task needs root or the installed binary — so **no operator obligation is opened**; ids 1-5
stand unchanged.

**Headline.** 122 fixture runs (61 candidate/HEAD pairs) + 50 stability repeats + 6 static censuses.
**All 17 acceptance criteria pass.** AC-15 failed on the first pass — `CHANGELOG.md:26` published an
exit-status transition the shipped build never produces (`DEF-1`) — and is **re-verified against my
own re-measurement** after the repair: the published transitions now match the measured ones on both
host classes, and the added mechanism aside is measured true on both builds. The three row fixes, the
`sc ipv6` line, all six binding conditions I own and all five routed residuals are discharged,
`bin/sc` is byte-identical to the build all 114 first-pass runs were taken on
(`md5 10536f7ff491…`, `55 45`), and `verify_all` is green at baseline.

## Test plan

Fixtures are stage artifacts under the session scratchpad, never the worktree (T-28 owns the
committed suite). Every run loads `bin/sc` through the `docs/dev-map.md` recipe (K-10): re-exec
neutralised by an `os.geteuid` shim restored in a `finally`, `assert os.geteuid() != 0` first,
source opened with `encoding="utf-8"` (R-77), all **eight** path constants repointed into a
`mkdtemp()` root **with one assertion per constant**, `SB_BIN` a stub script, **one case per
process** (`main()`'s `TextIOWrapper` re-wrap trap). `HEAD` means a `git clone` (never a worktree)
at `6d16caf`; `md5(headclone/bin/sc)` = `md5(git show HEAD:bin/sc)` = `6631231690cf…`, candidate
`10536f7ff491…`. Trap compliance, each one measured on this project: the Clash port is recorded in
**the fixture's own `settings.json`** and every HEAD half of every Clash case shows `GET /configs` in
the stub log (fixture not void); `lang` is set in that same `settings.json` so `main()`'s reassignment
cannot render English (the zh rows below carry `[异常]`/`[正常]`, not `[PROBLEM]`); `sc.SYSTEMD = True`
is **always** paired with a stubbed `subprocess.run`; `TUN_IFACE` is not repointable, so the TUN row
is a real read-only `ip` query, identical on both sides. `_egress_ip()` is stubbed to a fixed address
on both sides (determinism only; the egress row is not under test). No live Clash API call, no live
service action, no write under `/etc/sing-box` or `/var/lib/sing-box`, no install over
`/usr/local/bin/sc`, at any point.

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 rule at index 3 behind three decoys ⇒ PROBLEM | `aaaa-index3` **[D]** candidate + HEAD; plus `aaaa-index1` (rule behind one `clash_mode` rule) | `drive.py`, `runs/aaaa-index3.en.*` |
| AC-2 PROBLEM next step valid for both BC-3 causes; also on a document lacking the rule | `aaaa-index3`, `aaaa-missing` **[D]**, both languages | `runs/aaaa-{index3,missing}.{en,zh}.*` |
| AC-3 one definition of the position, two readers; divergence not silently possible | `aaaa-emit-append` **[D]** (directive renamed in the emitter only) + `_aaaa_rule`/`_dns_overlay` call-site census (AST) | `runs/aaaa-emit-append.en.*`, `06_RATIONALE.md` §census |
| AC-4 generated document reads `[OK]` for both decisions | `aaaa-generated` (`ipv6:off`), `aaaa-generated-on` (`ipv6:on`) — control | `runs/aaaa-generated*.en.*` |
| AC-5 init-less + API answering + delays for 2 tags ⇒ `2/2`, not `0/2` | `nd-initless-delays` **[D]** candidate + HEAD, with stub request log | `runs/nd-initless-delays.{en,zh}.*` |
| AC-6 init system running + entries with no history ⇒ PROBLEM `0/2` naming `sc ls` | `nd-running-nohistory` (`SYSTEMD=True` **and** `subprocess.run` stubbed) — control | `runs/nd-running-nohistory.en.*` |
| AC-7 init system stopped ⇒ no `/proxies` from `sc doctor` or `sc ls` | `nd-stopped-noapi` (V-7's coherent fixture) **and** `ls-stopped-api` (stub answering, guard must hold) — control | `runs/nd-stopped-noapi.en.*`, `runs/ls-*.en.*` |
| AC-8 no second liveness judgement, no new liveness source | `is_running()` **call-site** census by AST on both builds (RES-8/R-b), plus the diff grep for the record | `06_RATIONALE.md` §census |
| AC-9 warm-cache answer ⇒ OK names the install's own cache, claims no upstream resolution | `dns-answer` **[D]** candidate + HEAD, en + zh | `runs/dns-answer.{en,zh}.*` |
| AC-10 empty `Answer` and no answer ⇒ PROBLEM ×2, both carrying the clause | `dns-empty`, `dns-noanswer` **[D]**, en + zh; plus `dns-nonobject` | `runs/dns-{empty,noanswer,nonobject}.*` |
| AC-11 exactly one `GET /dns/query`, no other DNS request, no mutating request, root snapshot identical | request log + before/after snapshot (size, mtime_ns, mode, sha256) on **all 24 doctor runs**, plus a one-byte positive control | `runs/*.json` `request_log` / `snapshot_*` |
| AC-12 `sc ipv6 <value>` no-op names `sc reload`, both languages, zero keys added, zero branches | `ipv6-noop` **[D]** en + zh, candidate + HEAD; TRANSLATIONS delta by AST | `runs/ipv6-noop.{en,zh}.*` |
| AC-13 a flip still regenerates and prints the existing sentence; neither comparison side from disk | `ipv6-flip` en + zh — control; `cmd_ipv6` source read | `runs/ipv6-flip.{en,zh}.*` |
| AC-14 same rows, labels, order, exit status as HEAD on a healthy fixture | `healthy-clean` (21 rows, all `[OK]`, exit 0) + `healthy` — control | `runs/healthy-clean.en.*` |
| AC-15 every published sentence true of the shipped build | `README*.md:263,266,272,279,280`, `docs/dev-map.md:58,61,62,65`, `CONTEXT.md`, `CHANGELOG.md:26`, each read against a captured candidate run; the exit-direction clause re-measured on **both** host classes it names, on both builds | passes — `DEF-1` closed by re-measurement |
| AC-16 no shared construct; top-level `def`/`class` count | AST count both builds | 113 → 113 |
| AC-17 only the declared files | `git status --porcelain`, `git diff --numstat` (RES-1) | worktree |
| BC-A `/configs` answers, `/proxies` refused | `bca-configs-only` **[D]** candidate + HEAD, both renderings quoted below | `runs/bca-configs-only.{en,zh}.*` |
| BC-B init reports **stopped**, API **answering** both routes | `bcb-stopped-api-answering` **[D]** candidate + HEAD, with the request log | `runs/bcb-stopped-api-answering.en.*` |
| BC-C `telemetry: block` in the fixture's own `settings.json`; `dns.rules[0]` asserted; V-1 byte-identity | `aaaa-generated-block`, `aaaa-generated` (absent key), `aaaa-generated-allow`, `aaaa-generated-on` | `runs/aaaa-generated*.en.*.config.json` |
| BC-E the gate, from the repository root | `bash .harness/scripts/verify_all.sh` | `## verify_all result` |
| BC-F I-5's `OVERRIDE_PATH` clause in the **rendered** row, `en` and `zh` | `aaaa-index3.en`, `aaaa-index3.zh` | quoted below |
| BC-I RS-2 upheld; BC-10 not reopened | no probe of the live Clash API was made, and none of the stub work touched cache control | statement below |
| RES-1 numstat + `git status` re-measured | `git diff --numstat`, `git status --porcelain` | quoted below |
| RES-2 BC-A / BC-B rendered | as BC-A / BC-B above | rendered, not argued |
| RES-3 `sc ipv6` reaches `_init_files()`; snapshot re-asserted | `ipv6-noop`, `ipv6-flip`, `telemetry-noop`, `ipv6-show` (8 runs), `/var/lib/sing-box` witnessed before/after | `runs/ipv6-*.json` `var_lib_*` |
| RES-4 requests per host class, candidate vs HEAD | request-count table over all 24 doctor runs + 2 `sc ls` runs | table below |
| RES-8 AC-8 by call site, not by grep | AST census | 6 → 6 sites, same 6 functions |

## Adversarial tests

One row per acceptance criterion. Each hypothesis was written **before** the run, from the criterion
text — not from `04_DEVELOPMENT.md`'s fixture code. `[D]` = discriminating: the pair is reported, and
HEAD must fail. Full transcripts in `06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | the position test is really still a membership test, so a decoy-led document reads `[OK]` | `drive.py … aaaa-index3` (NEW, mine) candidate **and** HEAD | **[D] Survived; HEAD fails.** CAND `[PROBLEM] IPv6 (AAAA): …; config.json does not carry this decision as the first dns.rules entry — …`; HEAD `[OK] IPv6 (AAAA): …; config.json carries this decision`. Also at index **1** (behind `{"clash_mode":"Global"}` — the position that kills it in `global`/`direct`): CAND PROBLEM, HEAD `[OK]`. |
| AC-2 | the second cause is in the table but drops out of the rendered row (a `{override}` that renders empty) | `aaaa-index3` + `aaaa-missing`, `en` and `zh` (NEW) | **[D] Survived.** Both causes render on one line: `… run \`sc reload\` to regenerate it, and check <ROOT>/etc/sing-box/override.json if it prepends a rule of its own`. The rule-absent fixture renders the same sentence. HEAD renders `… does not carry this decision — run \`sc reload\` to regenerate it` only. |
| AC-3 | the coupling is decorative: move the emitted position and the probe follows nothing | patch `_dns_overlay`'s directive `$prepend`→`$append` **in the emitter only**, regenerate, then run doctor (NEW) | **[D] Survived; HEAD fails loudly.** Emitted doc: AAAA rule now at index **8 of 9** on both builds. CAND: `[UNKNOWN] IPv6 (AAAA): this check could not run: '$prepend'`. HEAD: `[OK] IPv6 (AAAA): … config.json carries this decision` — the emitter moved, the probe did not notice. |
| AC-4 | the new expression makes a freshly generated document read PROBLEM on some composition | `aaaa-generated` / `-block` / `-allow` / `-on` (4 compositions) | Survived (control). `[OK] … config.json carries this decision` on all four, candidate and HEAD; `dns.rules[0] == _aaaa_rule(suppress)` asserted True in each. |
| AC-5 | the guard change is inert because `stored_delays()` re-judges liveness anyway | `nd-initless-delays` (`SYSTEMD=OPENRC=False`, stub delays 111/222 ms) (NEW) | **[D] Survived; HEAD fails.** CAND `[OK] node delays: 2/2 nodes carry a stored delay …; auto-select is on n1`, log `['GET /configs','GET /proxies','GET /dns/query…']`. HEAD `[PROBLEM] node delays: 0/2 …`, log `['GET /configs','GET /dns/query…']` — **the count HEAD printed had no request behind it.** |
| AC-6 | the fix over-reaches and turns a genuine `0/2` into `[OK]` | `nd-running-nohistory` (`SYSTEMD=True` **and** `subprocess.run` stubbed, entries with `history: []`) | Survived (control). Both builds `[PROBLEM] node delays: … 0/2 … see \`sc ls\``; class, numerals and `sc ls` unchanged; both request `/proxies`. |
| AC-7 | the narrowed guard leaks into `sc ls`, so a stopped host pays a request and a wait | `ls-stopped-api` (NEW): init reports **stopped**, stub **answering**, `sc.CLASH_PORT` = the stub port, `cmd_ls()` called directly | Survived (control). Stub log `[]` on **both** builds; delay column all `-`; the two tables are **byte-identical**. With the service running: log `['GET /proxies']`, `111 ms`/`222 ms`, tables again byte-identical. A deleted guard would have shown the request. |
| AC-8 | the diff's four `is_running` tokens hide a real second judgement | AST call-site census on both builds (NEW; grep is the proxy, not the test) | Survived. `is_running()` call sites **6 → 6**, in the identical six functions (`_doctor_service`, `cmd_mode`, `cmd_status`, `cmd_update_rules`, `cmd_use`, `stored_delays`); `subprocess.run` sites **28 → 28**. The four diff tokens are one guard line's two halves and one docstring line's two halves. |
| AC-9 | the OK row still asserts a resolution somewhere in its rendering | `dns-answer` (stub answers `/dns/query` immediately with a non-empty `Answer`) (NEW) | **[D] Survived; HEAD fails.** CAND `[OK] DNS lookup: the running sing-box answered for api.ipify.org in 0 ms, possibly from its own DNS cache`. HEAD `[OK] DNS lookup: api.ipify.org resolved in 0 ms, through the running sing-box`. |
| AC-10 | the clause is on the OK branch only, or worded differently on the two PROBLEM branches | `dns-empty`, `dns-noanswer` (NEW) | **[D] Survived; HEAD fails.** CAND: `… returned no records after 0 ms — try another node with \`sc use <n>\`; an answer already cached by the running sing-box survives a node change` and `no answer for … — ` + the **same** trailing clause. HEAD carries neither. Classes unchanged on both. |
| AC-11 | some probe writes the root, or a second DNS request slips in on one branch | request log + full snapshot on 24 doctor runs, plus a one-byte canary control (NEW) | Survived. Every doctor run: `GET /dns/query…` exactly **1**; methods observed across every run: `['GET']`, non-GET: `[]`. `snapshot_identical: true` on 24/24. Positive control `control_snapshot_detects_write: true`. Fresh-host case: `cfg_dir before False → after False`. |
| AC-12 | `main()` reassigns `LANG` and the zh half renders in English (the vacuity trap) | `ipv6-noop` en **and** zh, `lang` set in the fixture's own `settings.json` (NEW) | **[D] Survived; HEAD fails.** CAND en `Nothing changed — the sing-box service was not touched; run \`sc reload\` to apply this setting to a configuration generated before it`; CAND zh `设置无变化 —— 未改动 sing-box 服务；若当前配置生成于该设置之前，请运行 \`sc reload\` 使其生效`. HEAD both: no escape named. TRANSLATIONS: **0 added**, 1 deleted (183 → 182 zh entries), 0 branches. |
| AC-13 | the key swap broke the flip path, or a comparison side now comes from disk | `ipv6-flip` en + zh; `cmd_ipv6` source read | Survived (control). Both builds print `Configuration regenerated; sing-box restarted` / `配置已重新生成，sing-box 已重启`; both comparison sides are `ipv6_decision()` (`:3203`, `:3208`), neither reads `config.json`. Regression: `sc telemetry block` no-op and `sc ipv6 show` are byte-identical to HEAD in both languages. |
| AC-14 | a row was added, lost, or reordered on a healthy host | `healthy-clean` row-by-row diff, candidate vs HEAD (NEW) | Survived (control). 21 rows, same labels, same order, **all `[OK]`**, `exit 0` on both. Only two cells differ: the fixture's own random port, and the DNS sentence (the intended change). |
| AC-15 | some published sentence outlives the check it describes | each published line read against a captured candidate run; the exit-direction claim re-measured on **both** host classes it names, candidate and HEAD (NEW, mine) | **Failed first, survives now.** First pass: `CHANGELOG.md:26` published `退出码从 \`1\` 变成 \`0\`` where the same fixture measures HEAD `EXIT = 1`, candidate `EXIT = 2` (`DEF-1`). After the repair, re-measured from my own fixtures, not from the repair's text: `healthy-clean-initless` HEAD `exit = 1` / cand `exit = 2`; `healthy-clean-override` HEAD `exit = 0` / cand `exit = 1` — both now exactly what the entry publishes. |
| AC-15b | the repair's new mechanism aside is itself a false statement — the 「服务」/「开机自启」 rows are *not* already `[未知]` on both builds, or some other `[异常]` row survives on that host class | `healthy-clean-initless` re-run both sides, full row census (NEW, mine) | Survived. Both builds print `[UNKNOWN] service: no init system detected (neither systemd nor OpenRC)` and `[UNKNOWN] boot autostart: <same cause>`; candidate `[PROBLEM]` row count on that fixture is **0**, so `worst` lands on `UNKNOWN` and `DOCTOR_EXIT` reports `2`. Guard `bin/sc:2739`, cause `:2740`, the two rows `:2741-2742`. |
| AC-16 | a helper was introduced to serve two rows | AST top-level `def`/`class` count, both builds | Survived. **113 → 113**; `_aaaa_rule()` now has exactly **one** caller (`_dns_overlay`), where HEAD had two — the shared construct count went *down*, not up. |
| AC-17 | the delivered diff exceeds BC-G's bar, or touches a file it should not | `git diff --numstat`, `git status --porcelain` (RES-1) | Survived. `bin/sc  55  45` — at the ceiling on **both** halves, inside `+55/−45`. Tracked changes: `bin/sc`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, `CONTEXT.md`, `docs/dev-map.md` + PM-owned `docs/batches/**` (mtime 20:33, pre-stage-4). Note: stage 5 quoted `55 44`; the measured removed half is **45**. Still inside the bar; the reviewer's conclusion is unaffected. |

### Attacks beyond the criteria

| attack | reproducer | outcome |
|---|---|---|
| **Make the node-delay row fabricate a count.** `/proxies` answers with delays for tags the host does not have. | `nd-foreign-tags` (NEW) | No fabrication: `[PROBLEM] node delays: a stored delay was read for 0/2 nodes …`. The count is `len(tags & delays)`, not `len(delays)`. |
| **Make it traceback on a malformed list.** `/proxies` → `{"proxies": "not-a-dict"}`, and `[1,2,3]`. | `nd-malformed-proxies`, `nd-proxies-nonobject` (NEW) | No traceback, no fabricated number; the row states the read and names **"or the list could not be read"** — the one cause that is literally true here. This is the state I-6 was written for. |
| **Make the AAAA probe raise on a hostile document.** `dns` a string, `rules` absent, top level a list, `config.json` mode `000`, `dns.rules = [1,"x",null]`, `dns.rules = []`, the rule for the *other* decision, `query_type` reordered to `[64,65,28]`, keys reordered inside the rule. | 9 fixtures (NEW) | Nothing raised on any. Classes match HEAD exactly on all of them; key-order-permuted rule ⇒ `[OK]` (dict equality), `query_type` list reordered ⇒ `PROBLEM` (list order is part of the rule) — both correct, both identical to HEAD's judgement. |
| **Prove the read-only claim on a fresh host.** Delete the whole config directory, then run doctor. | `aaaa-freshhost` (NEW) | `cfg_dir_existed_before_run: false` → `cfg_dir_exists_after_run: false`, snapshot identical, no `clash_api_port` persisted. `_init_files()` / `_resolve_clash_port()` unreached, both builds. |
| **Force a second `ipv6_decision()`** — E1 makes the probe call `_dns_overlay()`, which at HEAD called `ipv6_decision()` itself. | `nd-ipv6-call-count`: `ipv6_decision` wrapped and counted through a whole `sc doctor` run (NEW) | **1 call** on the candidate, 1 on HEAD. PQ-1 holds: the overlay is pure and the address source is read once. |
| **Empty the emitter's payload** instead of renaming its directive. | `aaaa-emit-empty` (NEW) | Recorded, not filed: with `$prepend: []` the candidate reads `[OK]` on a document carrying no AAAA rule (`rules[:0] == []`), where HEAD reads PROBLEM. Reachable only by an emitter edit that stops emitting the rule — in which world the sentence is vacuously true — but it is the coupling's one **silent** failure mode against the rename's loud one. Pool candidate. |
| **`sc ls` on a stopped host with a live API.** The state RS-1 calls incoherent for AC-7, built anyway for `sc ls`. | `ls-stopped-api` | Guard held (above). This is the observation that would fail a build satisfying AC-5 by deleting the guard. |

## Boundary tests added

- BC-1: `config.json` unreadable (mode `000`), not JSON-object (a list), `dns` a string, `dns.rules`
  absent, `dns.rules` holding scalars — five fixtures, no exception, classes identical to HEAD.
- BC-2: `dns.rules` empty, and carrying the rule for the *other* decision — PROBLEM on both builds.
- BC-3: the authored rule at index 1 and at index 3 — PROBLEM, both repair routes on one line.
- BC-4: a user `override.json` that `$prepend`s to `dns.rules`, on a **generated** document — the
  emitted rule lands at index 1 and the row is PROBLEM naming `override.json`; HEAD reads `[OK]`.
- BC-5 (rehearsed): the emitter's directive renamed → probe raises → `[UNKNOWN]`, never a silent
  PROBLEM on a healthy host; the whole rest of the report still prints (single-row section, PQ-3).
- BC-6/BC-7/BC-8: init-less + API answering; init reporting stopped with the API silent; and no port
  recorded — the last leaves all four Clash rows UNKNOWN with **zero** requests.
- BC-12: cached-negative branches — empty `Answer`, no answer, and a non-object body.
- BC-13: every changed sentence rendered under `sc lang zh` (AAAA PROBLEM, node-delay PROBLEM,
  all three DNS branches, the `sc ipv6` no-op line); `grep 失败：` over every zh output: **0**.
- BC-14: a raising probe (the rename fixture) costs one row and one section, nothing else.
- Concurrency/ordering: 50 repeat runs, per-row flush observed on a pipe (all output captured
  through a redirected stdout, order stable).
- Unicode/shape: rule-dict key permutation, `query_type` element reordering, CJK output under `zh`.
- i18n closure (AST, both builds): every `t()` literal call site resolves to a table key
  (**0 missing**), every key's `zh` half carries the same placeholder set (**0 divergences**), every
  call site's kwargs equal its key's placeholders (**0 divergences**), **0 new orphan keys**.
- BC-H re-verified independently: the shared cache clause appears byte-identically in exactly **2**
  English keys and **2** `zh` values.

## verify_all result

```
invocation: bash .harness/scripts/verify_all.sh   (from /home/alan/Programs/singbox-cli)
PASS: 17   WARN: 0   FAIL: 0   SKIP: 1
```

- Total tests: `baseline.json` `test_count: 0` → `0` (no committed test added; T-28 owns the suite)
- Pass: 17
- Fail: 0
- Warn: 0
- Skip: 1 (`[B.3] Lint`, SKIP at baseline too)
- New tests added: 0 committed; **172 stage-artifact runs** (122 fixture runs = 61 candidate/HEAD
  pairs, + 50 stability repeats) and 6 static censuses
- Baseline updated: **no** — `test_count` stays 0 by T-28's ownership; nothing was lowered, no test
  was deleted, no check was modified. `[E.6] Adversarial tests section` and `[F.6] Active task docs
  <=500 lines` both PASS with this document in place.
- **BC-E discharged**: the command line above is the only one used; no extensionless path, no other
  working directory. Expected baseline `PASS 17 / WARN 0 / FAIL 0 / SKIP 1` met exactly — and met
  again, unchanged, on the re-run taken after the `CHANGELOG.md` repair, with `[E.6] Adversarial
  tests section` and `[F.6] Active task docs <=500 lines` both still PASS with this document in
  place.

### RES-4 — requests per host class, candidate vs HEAD (measured)

| host class | candidate `/configs` `/proxies` `/dns/query` | HEAD |
|---|---|---|
| no port recorded (`aaaa-*`, fresh host) | 0 / 0 / 0 | 0 / 0 / 0 |
| port recorded, API silent (`nd-stopped-noapi`) | 0 logged / 0 / 0 | same |
| init system running, API answering | 1 / 1 / 1 | 1 / 1 / 1 |
| **init-less**, API answering | 1 / **1** / 1 | 1 / **0** / 1 |
| init reports **stopped**, API answering (BC-B) | 1 / **1** / 1 | 1 / **0** / 1 |
| `/configs` answers, `/proxies` refuses (BC-A) | 1 / **1** / 1 | 1 / **0** / 1 |
| `sc ls`, service stopped | 0 | 0 |
| `sc ls`, service running | 1 `/proxies` | 1 `/proxies` |

Methods observed across every run: `['GET']`; non-GET requests: none. NFR-2 on the reviewer's
reading (R-c) is **measured, not argued**: no new endpoint, no new constant, ≤1 `GET` per
`stored_delays()` call, `/dns/query` exactly once per doctor run, and the one added request appears
only on host classes where HEAD short-circuited it and only after `/configs` answered.

### Binding conditions I own

**BC-A — `/configs` answers, `/proxies` refused (503).** Discharged, **discriminating**.
Candidate: `[PROBLEM] node delays: a stored delay was read for 0/2 nodes — either no probe has
completed yet, every node is failing, or the list could not be read; see \`sc ls\`` — request log
`['GET /configs', 'GET /proxies', 'GET /dns/query?name=api.ipify.org&type=A']`.
HEAD: `[PROBLEM] node delays: 0/2 nodes carry a stored delay — either no probe has completed yet or
every node is failing; see \`sc ls\`` — request log `['GET /configs', 'GET /dns/query?…']`, i.e.
**HEAD states a count no request produced**. The candidate names "the list could not be read" among
its causes, which is the literally true cause in this state. Rendered in `zh` as well:
`只读到 0/2 个节点的已记录延迟 —— … 也可能这份列表没读出来；请查看 \`sc ls\``.

**BC-B — init reports stopped, API answering both routes.** Discharged, **discriminating**.
Candidate: `/proxies` **is** requested (log `['GET /configs','GET /proxies','GET /dns/query…']`) and
the row reads `[OK] node delays: 2/2 nodes carry a stored delay (history, not a fresh measurement);
auto-select is on n1`. HEAD: no `/proxies` in the log, `[PROBLEM] … 0/2 …`. That is the fix, not a
regression (RS-1 governs AC-7's fixture only). Fixture cell: `sc.SYSTEMD = True`,
`subprocess.run` stubbed to return `3` for `systemctl is-active`, stub answering both routes.

**BC-C — the second `sc`-authored `dns.rules` writer.** Discharged, and the developer's two
measurements are **independently reproduced**: `telemetry: block` is the absent-key default (the
composition with no `telemetry` key and the composition with an explicit `telemetry: block` have the
identical normalised digest `e6638e550a235afd…`), and the `$before {"clash_mode":"Global"}` anchor
puts the telemetry rule at index **2**, not 1. Composed `dns.rules[0..2]` with `telemetry: block` in
the fixture's own `settings.json`:

```
[0] {"action": "predefined", "rcode": "NOERROR", "query_type": [28, 64, 65]}   ← asserted == _aaaa_rule(True)
[1] {"server": "hosts_dns", "ip_accept_any": true}
[2] {"action": "predefined", "rcode": "NXDOMAIN", "domain_suffix": ["telemetry.microsoft.com", … 17 names]}
```

V-1 byte-identity run for that composition **and** three others (`telemetry` absent, `telemetry:
allow`, `ipv6: on`): candidate and HEAD digests identical in all four
(`e6638e55…` / `ecad7f04…` / `e6638e55…` / `9d1929ea…`; digests taken over the emitted text with the
fixture root normalised, since the two clones write to different `mkdtemp()` roots).

**BC-E — the gate.** Discharged; command line and result quoted above.

**BC-F — I-5's `OVERRIDE_PATH` clause in the rendered row.** Discharged, both languages:

```
en: [PROBLEM] IPv6 (AAAA): AAAA queries are answered empty (setting: off); config.json does not
    carry this decision as the first dns.rules entry — run `sc reload` to regenerate it, and check
    <ROOT>/etc/sing-box/override.json if it prepends a rule of its own
zh: [异常] IPv6（AAAA）: AAAA 查询直接返回空结果（设置：off）；config.json 的 dns.rules 第一条不是该决策
    对应的规则 —— 运行 `sc reload` 重新生成；若 <ROOT>/etc/sing-box/override.json 自己往前插了规则，请检查它
```

The clause is neither dropped, shortened nor merged into the regeneration clause in either half.

**BC-I — RS-2 upheld.** BC-10 is **not** reopened. No request of any kind was issued to the live
Clash API at any point in this stage; the only `/dns/query` traffic anywhere was against my own
stub, on a loopback port of my own choosing. **No cache-control parameter was observed**, because no
observation of the real endpoint was made — so there is nothing to record as a pool candidate under
this condition, and nothing was exercised against the live install.

### Residual dispositions

- **RES-1** — discharged by measurement: `git diff --numstat` → `55  45  bin/sc`; `git status
  --porcelain` shows exactly the six declared files, the two PM-owned `docs/batches/**` files and
  this task's untracked stage-doc directory. Stage 5's quoted `55 44` was one line off on the removed
  half; the delivered figure is at BC-G's ceiling on **both** halves and inside it. Re-measured after
  the `CHANGELOG.md` repair: `bin/sc  55  45` unchanged and `md5` unchanged, the file set unchanged
  (`CHANGELOG.md 2 0`, `CONTEXT.md 9 0`, `README.md 4 4`, `README.zh-CN.md 4 4`, `docs/dev-map.md
  4 4`), no new tracked file.
- **RES-2** — discharged: BC-A and BC-B are now **rendered**, not argued (above).
- **RES-3** — re-asserted first-hand, not inherited. `sc ipv6` (and `sc telemetry`, and every other
  non-`doctor` command) takes `main()`'s initialising arm, so my four `main()`-driven non-doctor
  fixtures **do** reach `_init_files()` and its hard-coded `Path("/var/lib/sing-box")`. Positive
  proof of the reach: those runs' `settings.json` gains `clash_api_port: 29091`, which only
  `_resolve_clash_port()` writes. Host effect measured before and after **each of the 8 runs**:
  `/var/lib/sing-box` mtime `1785387564302353878` unchanged, entry list `['cache.db']` unchanged,
  `var_lib_unchanged: true` 8/8. Every `doctor` fixture, by contrast, reaches neither writer
  (`aaaa-freshhost` above).
- **RES-4** — discharged by the table above.
- **RES-8** — discharged by call site, not by grep: 6 → 6 sites in the identical six functions.

## Defects found

**DEF-1 — [MAJOR] `CHANGELOG.md:26` published an exit-status transition the shipped build never
produces. AC-15 failed on it. — FIXED, re-verified, CLOSED.**

What was wrong: the entry read `没有 init 系统、Clash API 正常应答的机器 … 退出码从 \`1\` 变成 \`0\``.
On any host with neither systemd nor OpenRC, `_doctor_service()` returns **two `[UNKNOWN]` rows**
unconditionally — guard `bin/sc:2739`, cause `:2740`, the two rows `:2741-2742` — and `worst =
max(worst, cls)` (`:3027`) over `OK < UNKNOWN < PROBLEM` (`:2476`) maps through `DOCTOR_EXIT = {OK:
0, UNKNOWN: 2, PROBLEM: 1}` (`:2480`). Such a host cannot exit `0`, before this task or after.

*(Span correction, mine: my first-pass citation `bin/sc:2741-2744` was two lines long at the tail —
`:2743-2744` are `init = …` / `running = is_running()`, the **has-init** branch. Established by
reading the file this round: the two `[UNKNOWN]` row tuples are `:2741-2742`. `04_DEVELOPMENT.md`'s
`:2740-2742` (cause + rows) and `02_SOLUTION_DESIGN.md`'s `:2739-2742` (guard + cause + rows) are
both true of what each claims to span; mine was the one that was wrong.)*

The repair is text-only, in `CHANGELOG.md` alone. `bin/sc` is **byte-identical** to the build every
first-pass run was taken on (`md5 10536f7ff4912c6dd7de97930dad582b`, `git diff --numstat` `55 45`),
so no measurement is invalidated and none was inherited: I re-ran my own fixtures.

Re-verification (mine, one process per side, same driver as the first pass):

```
healthy-clean-initless   HEAD exit = 1   CAND exit = 2    published: 1 → 2   ✅
healthy-clean-override   HEAD exit = 0   CAND exit = 1    published: 0 → 1   ✅
cand initless rows:      [UNKNOWN] service / [UNKNOWN] boot autostart, [PROBLEM] count = 0
HEAD initless rows:      [UNKNOWN] service / [UNKNOWN] boot autostart  ← "新旧版本都一样" holds
```

Every clause of the repaired sentence is now measured true: the row transition (`[异常]` → `[正常]`),
the exit transition (`1` → `2`), the aside that those two rows are already `[未知]` on **both**
builds, the masking mechanism (`worst = max(...)`, so the `[异常]` was hiding them in the exit status
only), and the other host class (`0` → `1`). `README*.md:278-280`'s exit table needs nothing and got
nothing — it already lists "no init system detected" as an exit-`2` cause, and no row became
`[UNKNOWN]` where it was `[PROBLEM]`. The rest of the entry is unchanged in substance and re-checked
against captured runs: HEAD `[OK]` on a rule at index 3 **and** at index 1 vs candidate `[PROBLEM]`
naming both repair routes; HEAD's init-less request log `['GET /configs','GET /dns/query…']` behind a
printed `0/2` vs the candidate's `['GET /configs','GET /proxies','GET /dns/query…']` behind `2/2`;
the two DNS sentences. No new false statement was introduced.

**Ruling on the untouched lead 「退出码的影响只有一个方向」 — accepted, not raised.** The developer left
it and recorded it as pre-existing looseness. I agree, and for a stronger reason than "pre-existing":
the repair made it *more* defensible, not less. Before, the published pair was `1` → `0` and `0` →
`1` — opposite directions under **both** available readings of 方向 (numeric and severity). After, the
pair is `1` → `2` and `0` → `1`: under the numeric reading the sentence is now literally true (no
host's exit code goes down; both affected classes go up), and under the severity reading 方向 is a
summary qualifier, not a behaviour claim — every concrete, checkable transition beneath it is
measured true. It is ambiguous, not false, so it fails no criterion. **Pool candidate** for a future
documentation pass: replace 方向 with the fact it summarises ("没有哪台机器的退出码会变小").

No other defect found, first pass or this one. No BLOCKED criterion, so no operator obligation is
opened; ids 1-5 stand unchanged.

## Stability

- 50 repeat runs (5 representative cases × 10, all candidate): `aaaa-index3`, `bca-configs-only`,
  `dns-answer`, `healthy-clean`, `nd-initless-delays`. **1 distinct normalised output per case**,
  one distinct exit status per case (`1,1,1,0,1`), **0 bytes on stderr across all 50 runs**.
  Normalisation covers only the fixture root path, the fixture's random port, the measured
  milliseconds and the rule-set age — nothing else varied.
- No flake observed anywhere in the 122 pair runs either; every candidate/HEAD pair reproduced on
  re-run while the fixtures were being extended.
- Reproduction across sessions, on the same `bin/sc` bytes: 8 further runs taken after the
  `CHANGELOG.md` repair — `healthy-clean-initless`, `healthy-clean-override`, `healthy-clean` (en +
  zh), `aaaa-index3`, `nd-initless-delays`, `dns-answer` — reproduced their first-pass exit status,
  request log and row text **exactly**, on both sides. 0 flakes, 0 bytes on stderr.
- `verify_all` run three times (before and after this document was first written, and again after
  the repair): `PASS 17 / WARN 0 / FAIL 0 / SKIP 1` every time.

## Verdict

APPROVED FOR DELIVERY
