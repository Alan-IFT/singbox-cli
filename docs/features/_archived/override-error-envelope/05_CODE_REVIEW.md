> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed

- `/home/alan/Programs/singbox-cli/CHANGELOG.md` (`:24-26`) — the corrected bullet, read as delivered
- `/home/alan/Programs/singbox-cli/bin/sc` (`:356-383`, `:525-570`, `:1058-1105`, `:1340-1562`, `:1990-2140`, `:3725-3744`) — re-read; identical to rounds 1 and 2 at every line cited then
- `/home/alan/Programs/singbox-cli/README.md` (`:394-411`) · `/home/alan/Programs/singbox-cli/README.zh-CN.md` (`:394-411`) — re-read; unchanged
- `/home/alan/Programs/singbox-cli/CONTEXT.md` (`:166-183`) — re-read; unchanged, C-7's sign-off stands
- `/home/alan/Programs/singbox-cli/docs/dev-map.md` (`:34-59`) — re-read; still not edited, `:38`'s false clause and `:57`'s stale citation both still present
- `/home/alan/Programs/singbox-cli/.harness/rules/70-doc-size.md` (`:18-33`) — confirmed: no `## Stage-doc boundary rule` section on this project
- `/home/alan/Programs/singbox-cli/AI-GUIDE.md` (`:88-98`)
- Upstream contract: `01_REQUIREMENT_ANALYSIS.md` (`:70-87`, BC-2…BC-6), `02_SOLUTION_DESIGN.md` (`:32`, `:258`, `:294`, `:322`), `03_GATE_REVIEW.md`, `04_DEVELOPMENT.md` (`:14-27`, the corrected E9 row as delivered)
- Rationale, on trigger: `04_RATIONALE.md` (T5.2 — D-1…D-4 and the M0…M8 / dual-position transcripts), `02_RATIONALE.md` (T5.1 — why K-11 has its shape), `01_RATIONALE.md` §"Re-homed findings" `:149-166` (T5.3 — CR-8's risk is owned there), `03_RATIONALE.md` `:198` (BC-4 confirmation, by search)

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | MAJOR | Spec/design-fidelity | `CHANGELOG.md:26` | **CLOSED at round 2.** The bullet no longer publishes the silent-write claim unconditionally. As shipped it splits the four array-position shapes by key: at `dns.rules` / `route.rules` / `route.rule_set` "过去也已经是一行说明加非 0 退出、`config.json` 一个字节都不变（本项没有改变这三个键上的结果，只是把说法收敛成了下面那一句）" — which is `04_RATIONALE.md:157-170` (HEAD at `dns.rules`: 1 line, exit 1, `bytes_identical=True`) plus `:114-119` (candidate: same outcome, vocabulary sentence) exactly; and the silent replacement, the written broken document and `退出码仍然是 0` are confined to the unguarded keys, where `:172-188` measured HEAD at `dns.servers` as 2 lines, **exit 0**, bytes CHANGED. The refuted premise no longer ships. Re-read at round 3: unchanged. |
| CR-2 | MAJOR | Standards-conformance | `docs/dev-map.md:38` | **OPEN, PM-owned.** Re-read at round 3: the clause "the sites that handle the USER's document (the load, that merge, **and the three-key array guard**) set `OverrideError.path = OVERRIDE_PATH`" is still present verbatim and still false against `bin/sc:2101` (`OVERRIDE_PATH if override is not None else None`). C-7 excludes this file from the developer's set, so the developer correctly did not touch it in any of the three rounds; the replacement text handed over at `04_DEVELOPMENT.md:107-109` remains confirmed true clause by clause, subject to CR-6's amendment. A false published row must not ship — this gates the commit (RES-4), not the code, and it is not a developer action. |
| CR-3 | MINOR | Spec/design-fidelity | `CHANGELOG.md:26` | **CLOSED at round 2.** The class-name clause is attributed to the "说不清的（栈溢出、`AttributeError` 这类）" arm — true of M0–M3 and M8 (`04_RATIONALE.md:106-113`, `:120-121`) — and the dotted position to the array-vocabulary sentence, true of M4–M7 (`:114-119`). No universal over the region survives on the fault clause. |
| CR-4 | MINOR | Standards-conformance | `CONTEXT.md:174-175` | **OPEN** (accepted as a note at round 1; unchanged at rounds 2 and 3). Glossary overreach: "inside which *any* exception becomes one unusable-document sentence naming a path **and a fault class**". An `OverrideError` raised inside the region passes through `except OverrideError: raise` (`bin/sc:2119-2120`) with its own sentence, which names a dotted position, a directive or an anchor — never a fault class. CR-8 showed the same overreach doing real damage once restated as a user-facing promise; the glossary entry is internal and non-blocking, but it is the sentence that seeded the defect and is worth one clause's repair in the PM's pass. |
| CR-5 | MINOR | Spec/design-fidelity | `bin/sc:2116-2118` | **OPEN → RES-2.** The "exactly one line" property is structural for BC-1 only: every BC-1 abort point precedes `_warn_degraded(report)` (`:2116`) and `_warn_drift()` (`:2117`). A failure at the hoisted `json.dumps` (`:2118`, RS-3's M9 band) or inside `_warn_drift` on a **drifted or degraded** host emits the `⚠️` line first. Not a BC-3 breach (BC-3 is BC-1-scoped); C-12's forced-raise fixture must be built on a drifted/degraded fixture so the count is measured. |
| CR-6 | MINOR | Standards-conformance | `docs/dev-map.md` replacement text (proposed) | **OPEN, PM-owned → RES-4.** The proposed `:38` replacement's final clause — "a fault there is named against `override.json` too" — holds only when an override is present; the same gate at `bin/sc:2122` renders `config.json` otherwise. Recommend "…whenever an override is present". Also recommend adopting the `:55` amendment in shortened form: "the branch is taken on the TARGET's current type, never on the overlay value's". |
| CR-7 | NIT | Standards-conformance | `bin/sc:2051-2052` | **OPEN, no change requested.** The translation key is two adjacent string literals; folded at parse time, and AC-10's AST extraction sees one key (`04_RATIONALE.md:286`). A `grep`-based key audit would miss it. Recorded for the next key auditor. |
| CR-8 | MAJOR | Spec/design-fidelity | `CHANGELOG.md:26` (also `04_DEVELOPMENT.md:25`) | **CLOSED at round 3.** The round-2 universal ("这一行**绝不回显你文档里的任何一个值**", asserted over "其中任何一步出错") is gone. The delivered tail attaches the property to the class-name arm alone: "说不清的（栈溢出、`AttributeError` 这类），带上一句指明故障类别的说明 —— **只写异常的类名**，异常自己那句可能抄着你文档内容的消息不会被打印出来". That is true **by construction** at both sites the arm has: `bin/sc:2051-2052` and `:2122-2124` render `t("no configuration could be produced from it ({fault})", fault=type(e).__name__)` and reference `e` nowhere else — no `str(e)`, no `e.args`, `from None` on both — and `main()`'s sole rendering site (`:3737-3739`) prints `str(e)` of the composed `OverrideError` message, never a `__cause__`. The class name is derived from the exception type, which no document content can influence. Independently re-enumerated (not accepted from the report): the only sentence reachable inside `:2086-2118` that echoes a document value is `_anchor_index:1400-1404`'s `—— match：{anchor}`, and it belongs to the pass-through arm, about which the new text claims nothing; the remaining echoes are dotted positions, key names and directive names, which BC-4 (`01:78-80`) explicitly permits and which the surviving clause "写错在哪儿说得清的…这一行点的就是那个位置" describes without over-reaching. `04_DEVELOPMENT.md:25`'s E9 row carries the same scoped claim, cites `bin/sc:2122-2124` and `:2084-2085` for the construction, names `_anchor_index` (`bin/sc:1400-1404`, zh key `:370-371`) as the excluded sentence, and attributes the exclusion to BC-4's scoping, `03_RATIONALE.md:198` and `02_SOLUTION_DESIGN.md:294` — every citation verified. See CR-11 for the one residual imprecision, a NIT. |
| CR-9 | NIT | Spec/design-fidelity | `CHANGELOG.md:26` | **OPEN → RES-7**, two precision notes on clauses round 1 endorsed, neither blocking; deliberately not a rollback item and correctly left untouched at round 3. (a) `退出码仍然是 0` was measured with `subprocess.run` stubbed to `returncode 0` (`04_RATIONALE.md:9-11`, C-1/PQ-8), so on a host with a real `sing-box` the broken document written at an unguarded key would in most shapes be caught by `sing-box check` **after** the write and after `_record_generated()` — exit 1 with the checker's own message, the written file and the baselined digest unchanged. The bullet's substantive claims (silent replacement, broken document on disk, run reported as success under the measured conditions) stand; the exit code is stub-scoped. (b) `inbounds` / `outbounds` are named but only `dns.servers` was measured; they are structurally identical (no guard at `bin/sc:2099`), so this is unmeasured-but-sound, not wrong. |
| CR-10 | NIT | Standards-conformance | `docs/dev-map.md:57` | **OPEN, PM-owned → RES-8. Pre-existing and not caused by T-24.** The "base of the emitted config" row cites the published anchor `{"clash_mode": "Direct"}` as "the Custom-configuration example, `README*.md:384`". `README.md:384` is a table row about `$append`; the anchor now sits at `:402` (prose) and `:409` (JSON) in both READMEs. T-24 moved that block by exactly one line, so the citation was already stale. Worth repairing in the same PM pass as CR-2/CR-6. |
| CR-11 | NIT | Spec/design-fidelity | `CHANGELOG.md:26` | **NEW at round 3, non-blocking, nothing falsified.** The bullet opens its dichotomy over "其中任何一步出错" and then splits it two ways — "写错在哪儿说得清的…这一行点的就是那个位置；说不清的…带上一句指明故障类别的说明". The split is exhaustive over the **eight shapes the bullet itself enumerates** (M0–M3 → class name at `bin/sc:2122-2124`; M4–M7 → the position sentence at `:1471-1473` or the assertion at `:2101-2102`), but the span it opens over also contains three pre-existing load-time content faults that fall in neither branch as worded: `not valid UTF-8 text` (`:1540`), `larger than {n} bytes` (`:1536`) and `the top level must be a JSON object` (`:1548`) name a **cause**, not a position and not a class. The bullet's leading claim — one line `无法使用 …：…` plus a non-zero exit — is true of all of them, and none echoes a document value, so nothing published is false. This is a wording NIT of the same family as CR-3 and CR-8, recorded so the pattern is visible rather than silently third-time-lucky; one word ("其中任何一步" → naming the eight shapes) would close it if the PM wants it closed at all. |

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| FR-1 | `bin/sc:2119-2124` + `:2045-2052` → `main()`'s arm `:3737-3739`; fault clause `type(e).__name__` | ✅ read-confirmed, re-verified at round 3 |
| FR-2 | region `:2086-2118` (load `:2045-2052` separately); `_write_private` and `sing-box check` outside | ✅ read-confirmed |
| FR-3 | `_merge` `:1464-1475` — one admissible expression at a list target, one sentence otherwise | ✅ read-confirmed |
| FR-4 | `:2101` and `:2122` gate the path label on `override is not None` | ✅ read-confirmed |
| FR-5 | E3/E6 are the only edits on the override-less emission path | ✅ stage-4 measured, 24/24 states |
| FR-6 | `README.md:400` / `README.zh-CN.md:400`; standing promise at `:398` in both | ✅ read-confirmed, unchanged at rounds 2 and 3 |
| AC-1 | 24-state byte-identity + non-vacuity control | ✅ stage-4 measured; re-run at stage 6 |
| AC-2 (i)–(v) as amended by C-1/C-2/C-3 | M0…M8 via `main()`, `argv=["sc","reload"]` | ✅ stage-4 measured (1 line, exit 1, sentinel bytes survive, `zh` line contains `无法据此生成配置`) |
| AC-2 **control** | HEAD at `dns.rules` does **not** discriminate for M4–M7; the `dns.servers` position does (HEAD exits 0 and writes) | ⚠️ annotation falsified, criterion satisfied — see RES-1; **not** a rollback to stage 1 |
| AC-3 | region ends at `:2118`, `_write_private` at `:2128`; no `except` returns | ✅ read-confirmed + stage-4 adversarial build |
| AC-4 | 9 recipes byte-identical, with control | ✅ stage-4 measured |
| AC-5 | one `raise` at `:1471-1473` for all four shapes; `_directive_list()` names five | ✅ read-confirmed; 1 distinct sentence measured |
| AC-6 | the pre-existing sentence and trigger are a subset of the new rule | ✅ stage-4 measured, string equality vs HEAD |
| AC-7 as amended by C-4 | `:2099-2102` loop unconditional, label gated; `_dig` returns `None` on a non-dict step (`:1353`) | ✅ read-confirmed + stage-4 measured, control discriminates |
| AC-8 / C-6 | `_filter_rules` call sites `:2114-2115` — argument lists unchanged, indentation only | ✅ read-confirmed + AST comparison |
| AC-9 | `_apply_directive` `:1408-1433` calls `_anchor_index`, `copy.deepcopy`, `t`, `OverrideError` — no `_merge` | ✅ read-confirmed |
| AC-10 as amended by C-5 | key at `:2051-2052` and `:2123`; `zh` at `:374-375`; placeholder `{fault}` both sides; unnamespaced | ✅ read-confirmed; `失败` re-grepped at round 3 — absent from `CHANGELOG.md:26`, present only on lines `10,14,18,20,22,28,32,34,36,39,40,43`, all pre-existing entries |
| AC-11 | both READMEs `:400`, identical relative position, section parallel line for line | ✅ read-confirmed, re-read unchanged at round 3 |
| AC-12 | conjunction of AC-2 (i)–(iv) | ✅ stage-4 measured |
| AC-13 | `verify_all` PASS 17 / WARN 0 / FAIL 0 / SKIP 1, baseline preserved; re-run at rounds 2 and 3 | ✅ stage-4 measured; **not** re-runnable here |
| AC-14 | `MainPID` / `ActiveEnterTimestamp` identical across stage 4 | ✅ stage-4 measured; nothing executed at stage 5, 5′ or 5″ |
| AC-15 | BLOCKED by construction, nothing substituted | ✅ correctly BLOCKED |
| NFR-1 | exactly one new key (cap two) | ✅ read-confirmed |
| NFR-2 as amended by C-7 | five product files + `CONTEXT.md`; round 3 touched `CHANGELOG.md` and this task's stage documents only, both corrections in-line on already-added lines, product diff unmoved at +85/−55 | ✅ read-confirmed at the cited spans; `git status` / `--numstat` re-check routed to stage 6 (RES-5) |
| NFR-3 / K-16 | see Design fidelity check | ✅ arithmetic reconstructed from the shipped file; `bin/sc` unchanged at rounds 2 and 3 |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| E1 `_unusable()` docstring generalised, body frozen | `:543-547` | ✅ |
| E2 one `zh` entry after `:373` | `:374-375` | ✅ |
| E3 loop re-derived on the target's type | `:1458-1485`; `_directive_of` hoisted to a ternary at `:1463` ahead of every target test | ✅ |
| E4 load's second arm, unconditional `OVERRIDE_PATH` | `:2050-2052` | ✅ |
| E5 envelope, `try` at `if override is not None:` through the hoist | `try` `:2086`, `if` `:2087`, hoist `:2118`, arms `:2119-2124` | ✅ |
| E6 assertion through `_unusable()`, label gated | `:2101-2102`, loop at `:2099` unconditional | ✅ |
| E7 / E8 | `README.md:400`, `README.zh-CN.md:400` | ✅ |
| E9 one bullet under `### 修复` carrying every K-12 item | `CHANGELOG.md:26` | ✅ CR-1, CR-3 and CR-8 all closed; CR-9 and CR-11 remain as NITs |
| E10 `CONTEXT.md` glossary | `:172-178` | ✅ signed off (CR-4 open as a note) |
| BC-4 (ban scoped to sentences this task introduces or newly reaches) | code: no new sentence echoes a document value; `_anchor_index`'s pre-existing echo (`:1400-1404`) is correctly re-homed, not newly reached. Note: the published claim is now scoped to the class-name arm and no longer reaches that sentence | ✅ in `bin/sc` **and** in the published note |
| K-1 boundary | `_compose` `:2079-2080` above; `_write_private` `:2128`, `_record_generated` `:2133`, check `:2135` below | ✅ |
| K-2 arm order, `from None` | `except OverrideError: raise` first (`:2119-2120`), `except Exception` second (`:2121-2124`), `from None` on both `:2052` / `:2124` | ✅ PQ-2 satisfied |
| K-3 / K-4 / K-5 | unconditional `OVERRIDE_PATH` at the load; `type(e).__name__` only; the outer arm assigns `e.path` for nothing | ✅ |
| K-6 / K-7 | `_directive_of` once per dict-valued key before any target test; exactly one un-copied assignment `:1485`, guarded by `:1482` | ✅ |
| K-8 | no `setrecursionlimit`; no depth/node/size cap; `OVERRIDE_MAX_BYTES` untouched | ✅ grep-confirmed |
| K-11 | `-w` diff additionally shows two re-flowed comment blocks — D-1 | ✅ accepted |
| K-12 "seven malformed shapes" | bullet says 八种 — D-4, untouched at round 3 | ✅ accepted; K-12 is the erratum (BC-1 enumerates M0…M7) → RES-3 |
| K-13 / K-14 / K-15 | loop unconditional; `_filter_rules` argument lists byte-identical; `main()`'s arm renders `e.path or CFG_PATH` at `:3737-3739`, unnarrowed | ✅ |
| K-16 / C-8 | `bin/sc` +79/−55 vs ≤ +80/−65; product +85/−55 vs ≤ +86/−65; tolerance unused, unmoved by the in-line rewrites at rounds 2 and 3 | ✅ split verified against the shipped file; `git` re-run routed to stage 6 |
| D-1 re-flowed comments + one rewritten sentence | `:2094-2098`, `:2104-2109` | **accepted** — RK-2 intact; the retired clause asserted the premise E6 refutes |
| D-2 E3 measured +28/−21 vs designed +26/−28 | 3-line precedence comment at `:1460-1462` | **accepted** — K-16 caps the product diff, not per-edit rows |
| D-3 key as two adjacent literals | `:2051-2052` folds to the exact `zh` key at `:374` | **accepted** (CR-7 is a NIT) |
| D-4 eight vs seven | `CHANGELOG.md:26` | **accepted** on the count |
| T-13 / BC-5 | `_write_private` `:476-527` untouched; the only `CFG_PATH` writer (`:2128`) | ✅ read-confirmed |
| T-14 / BC-5 | `_config_digest()` `:1952-1962` hashes bytes; `_record_generated()` `:1976-1982` writes a 64-hex digest | ✅ |
| BC-7 / AC-9 | no `_apply_directive → _merge` edge | ✅ |
| R-22 gate | no path reaches `_write_private()` with a failed override: both arms `raise`, neither returns; no caller of `generate_config()` swallows `OverrideError` (`:2158`, `:3359`) | ✅ read-confirmed |

## Axis status

- **Standards-conformance**: 1 MAJOR (CR-2) + 2 MINOR (CR-4, CR-6) + 2 NITs (CR-7, CR-10) open, worst = **MAJOR**. Every one of them is **PM-owned or advisory**: CR-2, CR-6 and CR-10 are `docs/dev-map.md` actions that C-7's own file-set restriction forbids the developer from taking, and they gate the commit under RES-4/RES-8, not the code. No AI-GUIDE, `.harness/rules/*` or dev-map pattern violation in the code; the round-3 prose is 中文 as this project's split requires, carries no `失败`, no credential bytes, and matches its siblings' shape (bold emphasis, `——` clause dashes, one bullet, no new line). `70-doc-size.md` confirmed to declare no `## Stage-doc boundary rule`, so this document applies the schema as written.
- **Spec/design-fidelity**: 3 findings closed (CR-1 and CR-3 at round 2, CR-8 at round 3), 1 MINOR open (CR-5) + 2 NITs (CR-9, CR-11), worst = **MINOR**. No developer-owned MAJOR or CRITICAL remains. Every FR, BC and AC is implemented at a named line; `bin/sc` is unchanged since round 1 and the published note now says exactly what the code does, with the one property the requirement declined to require (BC-4's out-of-scope anchor echo) correctly left unclaimed.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-1 | AC-2's control annotation is falsified at the three guarded keys and is discharged by the dual-position measurement, not by a contract correction. Stage 6 must run the AC-2 control at **both** positions and state in writing that the guarded-key control does not discriminate while `{"dns": {"servers": …}}` does (HEAD: exit 0, bytes changed). No AC-2 clause and no BC-1 member changes meaning. | `06_TEST_REPORT.md` |
| RES-2 | CR-5: the one-line property is structural for BC-1 only. C-12's forced-raise fixture must run on a fixture whose `config.json` has drifted from `.config.sha256` and whose rule-sets are degraded, and report the measured line count at that abort point. | `06_TEST_REPORT.md` |
| RES-3 | K-12's "seven malformed shapes" is an off-by-one against BC-1's M0…M7. Design-document erratum; no code or CHANGELOG consequence beyond D-4's acceptance. | PM, `PM_LOG.md` |
| RES-4 | `docs/dev-map.md:38` must be replaced before delivery with the developer's text (`04_DEVELOPMENT.md:107-109`) as amended by CR-6, and `:55` adopted in shortened form. PM-owned under C-7; this is the one MAJOR still open and it blocks the commit, not the code. | PM, before commit |
| RES-5 | Every finding in this document is **read-derived**. Stage 5 held no execution tool at any of its three rounds: `git diff --numstat`, `git diff -w`, `git status --porcelain`, `verify_all` and every [B] criterion were reconstructed from the shipped files and from stage 4's transcripts, never re-measured; the round-2 and round-3 scope claims were verified by re-reading every line the previous round cited, not by `git`. V-7 and V-13 must be re-run at stage 6 against the tree as delivered. | `06_TEST_REPORT.md` |
| RES-6 | C-9 (rejected-decisions record), C-10 (M8 as a required fixture), C-11 (M9 band by bisection), C-14 (AC-15 as an operator obligation) remain undischarged and are not stage 5's. | PM / `06_TEST_REPORT.md` |
| RES-7 | CR-9: the `退出码仍然是 0` clause rests on stage 4's stubbed `subprocess.run`. Stage 6 cannot lift the stub either (AC-15 is BLOCKED), so the claim stays stub-scoped: either the note carries that scoping or the residual is recorded as an accepted imprecision about the pre-change build. `inbounds` / `outbounds` remain named-but-unmeasured. | `06_TEST_REPORT.md` / PM |
| RES-8 | CR-10: `docs/dev-map.md:57` cites `README*.md:384` for the `{"clash_mode": "Direct"}` published anchor, which sits at `:402`/`:409`. Pre-existing; repair in the same PM pass as CR-2/CR-6. | PM, before commit |
| RES-9 | CR-11: `CHANGELOG.md:26`'s two-way split is exhaustive over the eight enumerated shapes but is opened over the whole span, in which three pre-existing load-time faults (`bin/sc:1536`, `:1540`, `:1548`) are named by cause rather than by position or class. Nothing published is false and no echo is involved. Optional single-word repair in the PM's delivery pass; otherwise accept and close. | PM, delivery pass |

## Verdict
APPROVED — 0 CRITICAL, 0 MAJOR developer-owned (CR-8 closed by construction at `bin/sc:2051-2052` / `:2122-2124`); 1 MAJOR PM-owned (CR-2, `docs/dev-map.md:38`) blocks the commit under RES-4, plus MINOR/NIT notes CR-4, CR-5, CR-6, CR-7, CR-9, CR-10, CR-11.
