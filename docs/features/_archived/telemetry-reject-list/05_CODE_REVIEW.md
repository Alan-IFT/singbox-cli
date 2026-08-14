> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `/home/alan/Programs/singbox-cli/bin/sc`
- `/home/alan/Programs/singbox-cli/README.md`
- `/home/alan/Programs/singbox-cli/README.zh-CN.md`
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/docs/features/telemetry-reject-list/01_REQUIREMENT_ANALYSIS.md`
- `/home/alan/Programs/singbox-cli/docs/features/telemetry-reject-list/02_SOLUTION_DESIGN.md`
- `/home/alan/Programs/singbox-cli/docs/features/telemetry-reject-list/03_GATE_REVIEW.md`
- `/home/alan/Programs/singbox-cli/docs/features/telemetry-reject-list/04_DEVELOPMENT.md`
- `/home/alan/Programs/singbox-cli/docs/features/telemetry-reject-list/04_RATIONALE.md`
- `/home/alan/Programs/singbox-cli/.harness/rules/85-design-discipline.md`

This stage held **no shell**: every check below is by reading the working tree. AC-7's `ast`+byte
freeze comparison (K-15) and the 30 behavioural observations could not be re-executed here; they are
carried as RES-1 and RES-2 rather than claimed.

## Findings

| id | severity | axis | file:line | finding |
|---|---|---|---|---|
| CR-1 | MINOR | Standards-conformance | `docs/dev-map.md:55` | The published-anchor warning names the wrong second anchor. It reads "`{"server": "hosts_dns"}` (T-17's two recipes) and `{"clash_mode": "Global"}`", but after DD-2 **neither README publishes `{"clash_mode": "Global"}` anywhere** — the second anchor users are actually told to type is `{"clash_mode": "Direct"}` (`README.md:384`, `README.zh-CN.md:384`, the Custom-configuration example, shipped since T-14). The row exists precisely to stop a future task breaking a user-visible anchor, and as written it guards an element no user writes while leaving the one they do write unguarded. Also "T-17's two recipes" is now three (add / except / combined). Developer-owned, one line. |
| CR-2 | MINOR | Standards-conformance | `bin/sc:1595-1596` | Shipped source states the client-side negative-caching claim K-12 forbids: *"NXDOMAIN would poison the negative cache for the whole name, its A record included."* It is **pre-existing** (T-16's `_dns_overlay()` docstring) and **frozen** by K-6/AC-7, so it is correctly not the developer's to touch — but C-7 scopes its amendment to `01`'s Q-5 and `01_RATIONALE.md` only, so the claim survives in a file that ships. Not a T-17 regression; routes to the PM's C-7 amendment scope (and to whoever owns R-25's neighbourhood). |
| CR-3 | MINOR | Spec/design-fidelity | `04_DEVELOPMENT.md:23-24` | The Summary reports "**30 pass, 0 fail, 0 inconclusive**" with no mention that AC-B6b *as the criterion is written* came back **inconclusive**. That fact appears only at DD-5 (`:75`), in the C-2 disposition (`:82`) and in `04_RATIONALE.md:193-206`. AC-B7 and NFR-8 make "reported as inconclusive" an outcome that must be visible where the result is stated, not only where the drift is explained; a reader of the Summary alone learns the opposite. The count itself is defensible (the 30 are the post-split observations) — the omission is the defect. Must not be carried into `06_TEST_REPORT.md` in this shape. |
| CR-4 | MINOR | Spec/design-fidelity | `04_RATIONALE.md:213-219` | V-27b-ii evidences "every OTHER listed name stays rejected" against **5 of the 16** other names. AC-B6b says *every* other listed name; design V-27 said "the other 17 stay `NXDOMAIN`". A five-name sample is sound engineering but is not the criterion, and `04` presents it as discharging it. Stage 6 must either observe all 16 or state the sample as a stated limit, as C-10 required for BC-1. |
| CR-5 | MINOR | Spec/design-fidelity | `02_SOLUTION_DESIGN.md:283` (and `:67`) | DD-1/DD-2 leave two stage-2 units stale in a way that **escapes the working tree**: RS-3's glossary term, which travels to `07_DELIVERY.md` and thence into `CONTEXT.md`, defines *reject rule* as "anchored by `{"rcode": "NXDOMAIN"}`", and I-9's "Published anchors" row still names both replaced anchors. Filed unamended, delivery writes a project-wide glossary entry that contradicts both shipped READMEs. Needs the same treatment C-7 gives Q-5: a PM amendment at stage 7, not a stage-4 edit. |
| CR-6 | NIT | Standards-conformance | `docs/dev-map.md:41` | "descriptions start at column 30, sub-options at column 32" now describes only the rows that fit — there are two overflowing rows (`update-interval`, `telemetry`). D-7 pre-answered this ("describes the rows that fit"), so it is noted, not charged. |
| CR-7 | NIT | Spec/design-fidelity | `README.md:202-217` | The published exception rule lands at index 2, ahead of **both** `clash_mode` rules, so the excepted name is pinned to the chosen resolver in `global` and `direct` too, in both settings states. Correct, identical under the design's original anchor, and consistent with the sentence at `:154` — but no shipped line says it outright. A future sentence, not a change. |

**No CRITICAL and no MAJOR finding exists on either axis.** The five decisions the PM asked me to
scrutinise are each ruled on in `## Design fidelity check` and reasoned in `05_RATIONALE.md`; DD-1,
DD-2, DD-3, DD-4 and DD-5 are all **upheld**.

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| AC-B1 | `04_RATIONALE.md:245-255` non-vacuity + V-22; `aa` set, `ANSWER:0`, no stub receipt | ✅ per transcript — not re-run here (RES-2) |
| AC-B2 | V-23, fixture's own Clash API, `global` + `direct` | ✅ per transcript |
| AC-B3 | V-24, resolved-answer non-vacuity proof | ✅ per transcript |
| AC-B4 | V-25, 6 per probe name / 24 total, near-miss `notcrashlytics.com` (`04_RATIONALE.md:270-273`) | ✅ per transcript; count reported as run per C-10 |
| AC-B5 | V-26 + the zero-node state added under C-10 | ✅ per transcript |
| AC-B6a | V-27a, add recipe under both settings | ✅ per transcript |
| AC-B6b | V-27b bundled = INCONCLUSIVE, reported; split V-27b-i `[A]` + V-27b-ii `[D]` both pass | ✅ substance — split upheld; see CR-3 (reporting) and CR-4 (5 of 16 names) |
| AC-B7 | C-2 disposition: 30 observations, `[D]` 17 / `[A]` 13, classified before the run | ✅ per transcript; CR-3 qualifies the headline |
| AC-1 | `bin/sc:1725-1729` — one rule, `action`/`rcode`/`domain_suffix`, no `rule_set` | ✅ |
| AC-2 | `$prepend` (`:1599`) → index 0; base hosts rule index 1 (`:1154`); `$before {"clash_mode":"Global"}` → index 2; `Global` (`server: remote_dns`) index 3 | ✅ by construction in all four states |
| AC-3 | `{"clash_mode":"Global"}` and `{"clash_mode":"Direct"}` each match one element (`:1155-1156`); the README's documented anchor `{"server":"hosts_dns"}` matches exactly one (`:1154`) and is undeletable by `_filter_rules` | ✅ — all three anchors satisfy AC-3 as written; see 05_RATIONALE §1 |
| AC-4 | `_telemetry_overlay()` returns `{}` under `allow`; `_directive_of({})` → `None`, `_merge` iterates nothing (`:1225-1227`, `:1311`) | ✅ by construction + reported differential |
| AC-5 | Six `sing-box check` states, real `.srs` bytes after the `zlib: invalid header` correction (`04_RATIONALE.md:176-191`) | ✅ per transcript |
| AC-6 | `TELEMETRY_NAMES` read only at `:1728` and `:2670`; `_telemetry_setting()` called only at `:1723`, `:2667`, `:2673`, `:2677`; no second spelling anywhere in the tree | ✅ |
| AC-7 | `DIRECTIVES` `:1108`, `_directive_of` `:1215`, `_anchor_index` `:1241`, `_apply_directive` `:1264`, `_merge` `:1292`, `_load_override` `:1337`, `_filter_rules` `:914` — all read, all consistent with their T-14/T-16 shape, none referenced by new code except as callers | ✅ by reading; byte comparison not re-run (RES-1) |
| AC-8 | `generate_config()` `:1911-1912` — one statement, no literal, guard still three keys `:1925`; no new module-level constant but `TELEMETRY_NAMES`; imports `:3-18` unchanged, all stdlib; no new `timeout=`/`capture_output=` | ✅ |
| AC-9 | 17 names `:1624-1646`, one source line each, four classes (5/1/5/6), K-10 exclusions named in the block comment `:1610-1618` | ✅ 17 ≤ 24 |
| AC-10 | `cmd_telemetry()` `:2663-2686`, exit 0 on all three forms, `print()` per fact | ✅ per transcript |
| AC-11 | `show` arm `:2666-2672` calls `_telemetry_setting()` (read-only) + `print` only | ✅ by reading |
| AC-12 | `before`/`setting` both from `_telemetry_setting()` `:2673`/`:2677`; no-op line `:2681-2682` names `sc reload` | ✅; C-8's third case recorded |
| AC-13 | `:1681-1692` — absent/JSON-error/OSError → `block`; key absent → `block`; bad value → `block` + exactly one stderr line naming file, key, both values | ✅ |
| AC-14 | `:2663-2665` — `.lower()` then membership, `sys.exit(t(...))`, nothing written by the handler | ✅ (`on`/`off` rejected) |
| AC-15 | `generate_config()`'s drift trio untouched `:1944`, `:1953` | ✅ per transcript |
| AC-16 | Six keys `:191-202`; placeholder sets `{val}` / ∅ / ∅ / ∅ / `{path}` / ∅ identical on both sides; no `失败：`; no `ls.*` | ✅ — and every new `t()` call site resolves to a key present in `zh` (incl. the two reused: `:183`, `:138`) |
| AC-17 | Both READMEs **432** lines *(PM amendment at delivery per stage-6 D-1: this row read 433, inherited from `04`; `wc -l` gives 432/432 — the mirror property itself holds and the ✅ is unaffected)*, every heading on the same line number, the three JSON blocks byte-identical across languages; changelog `CHANGELOG.md:7` Chinese, under `### 新增`, states the `block` default and both escapes | ✅ |
| AC-18 | Recipes at `README*.md:186-236`, all anchored on an element present in every state | ✅ per transcript |
| AC-19 | `HELP_EN:2981-2983`, `HELP_ZH:3047-3049` — two spaces after an overflowing 28-char left column, sub-options at column 32, per D-7 | ✅ |
| AC-20 | No walrus, no `dataclasses`, no new `capture_output=`, no non-stdlib import in the new code | ✅ |
| AC-21 | `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, re-run independently by the PM | ✅ |

FR coverage follows the ACs above with three additions verified directly: **FR-4/BC-11** — the reject
rule is emitted *after* `{"server":"hosts_dns","ip_accept_any":true}` and *before* both `clash_mode`
rules, and no member of the predefined hosts table (`bin/sc:1144-1151`) is matched by any listed
suffix; **FR-5** — the rule carries no `rule_set`, so `_filter_rules` (`:921-926`) keeps it
unconditionally; **FR-11** — `_dns_overlay()`'s `$prepend` is untouched, so T-16's rule holds index 0
in all four states and BC-10's overlap is exactly as designed.

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| I-2 `TELEMETRY_NAMES`, 18 names | tuple of **17**, N-7 dropped under C-3 | ✅ **DD-3 upheld** — drop recorded per K-10, four resolvers + a `NOERROR` control, no spelling substituted, four FR-2 classes intact, 17 ≤ 24, and the count is consistent in both READMEs, the tables (17 rows), the changelog and the "other 16" recipe line. A one-member class 2 is FR-2's second clause applied honestly, not a gap: FR-2 requires the class be *covered*, not sized |
| I-3 `_telemetry_setting()` | `:1649-1692`, `_ipv6_setting()`'s guard tuple verbatim | ✅ |
| I-4 the emitted rule | `:1727-1728` — three keys in order, `answer` **absent**, `rcode` uppercase `"NXDOMAIN"`, one dotless `domain_suffix`, no second matcher, no `reject` action anywhere in DNS (the only `"reject"` in the file is `route.rules`' pre-existing QUIC rule, `:1185`) | ✅ Q-B traps all cleared |
| I-5 `_telemetry_overlay()` | `:1695-1729`, `$before {"clash_mode":"Global"}`, `{}` under `allow`, emits `list(TELEMETRY_NAMES)` | ✅ shipped anchor unchanged — DD-1/DD-2 moved only the *published* anchors |
| I-6 `generate_config()` | `:1911-1912`, one list element; `OverrideError` provenance wrappers `:1880-1884`, `:1913-1918`, `:1925-1929` untouched | ✅ |
| I-7 `cmd_telemetry()` | `:2638-2686` | ✅ |
| I-8 six strings | `:191-202` | ✅ |
| I-9 index order | `[0]` suppression · `[1]` hosts · `[2]` reject · `[3]` Global · `[4]` Direct | ✅ |
| I-9 **published anchors** | both replaced by `$after {"server":"hosts_dns"}` | ✅ **DD-1 + DD-2 upheld, and independently derived as the *only* admissible choice** — `{"server":"hosts_dns"}` matches exactly one `dns.rules` element in all four states and at HEAD (no other element carries that key/value; `_filter_rules` cannot delete it; the shipped overlay resolves its own anchor before the user's document is merged, so a user cannot break it); `$after` on it lands at index 2, after the hosts rule (BC-11 holds) and ahead of the shipped rule, which shifts to 3. The shared-anchor claim is sound: `_directive_of` (`:1228`) admits one directive per object and one `override.json` exists, so C-4's combined form forces one anchor — and `{"clash_mode":"Global"}` cannot be that anchor, because `$before` it lands *after* the shipped rule and excepts nothing. Reasoning in `05_RATIONALE.md §1` |
| FR-9 clause 2 / AC-3 | `{"clash_mode":"Global"}` still matches exactly one element in both settings states | ✅ developer's reading confirmed — the clause is about the emitted document, not about what the README advertises; its *purpose* ("a user rule can be inserted before them in both settings states") is now served by the `hosts_dns` anchor, which is strictly stronger since it also precedes the shipped rule |
| L-2/L-4: four new definitions | a fifth, `_telemetry_meaning(setting)`, `:2626-2635` | ✅ **DD-4 upheld** — ruled under rule 85 in full. It is the *smaller* design: rule 85's test 2 (duplicated judgment) is triggered by the alternative, since the `block`/`allow` → sentence conditional is printed from two arms; it is pure, private, argument-taking, reads nothing, adds no second reader of the setting and no third consumer of the list (AC-6's two-consumer property verified unchanged), and matches the project's own precedent that the judgment→sentence mapping has one home (`ipv6_decision()` returns its sentence). The only genuinely smaller shape — restructuring `cmd_telemetry()` to print once — buys ~6 lines by interleaving the `show` and `set` flows behind two `if val == "show"` tests, which costs more in what a reader must hold than the name saves. K-1 constrains the two *singleton* definitions and is untouched; FR-10's envelope forbids files, downloads, rule-sets, command surfaces and persisted state, none of which this is |
| V-28 / AC-B6b as one `[D]` observation | split into `[A]` + `[D]`, bundled result reported | ✅ **DD-5 upheld** — this is the honest reading and it does not weaken the criterion. AC-B6b's two halves have opposite control classes (HEAD resolves the excepted name for the *opposite* reason, and HEAD rejects none of the others), so as one observation the control can only agree, which NFR-8 makes inconclusive by construction; splitting applies C-2's "classify per observation" rather than relaxing it, and the `[D]` half now carries a real defect control it did not have before. Reporting the bundled inconclusive rather than quietly replacing it is exactly what AC-B7 asks for — CR-3 is about where it is stated, not whether |
| Frozen set | `DIRECTIVES` `:1108`, `_directive_of` `:1215`, `_anchor_index` `:1241`, `_apply_directive` `:1264`, `_merge` `:1292`, `_load_override` `:1337`, `_filter_rules` `:914`, `_dns_overlay` `:1581`, `ipv6_decision` `:1543`, `_ipv6_setting` `:1458`, `_runtime_overlay` `:1732`, `CONFIG_BASE["dns"]` `:1137-1169`, `CONFIG_BASE["route"]` `:1176-1196`, `_init_files` `:462`, `load/save_settings` `:488-493`, `_write_private` `:410`, `main()`'s read-only arm `:3120-3125` | ✅ by reading — all present, unreferenced by new logic except as callers, `doctor` still the one positively named read-only command; byte comparison itself is RES-1 |
| C-5 / D-10 non-UTF-8 hole | `:1681-1683` guard tuple is `_ipv6_setting()`'s (`:1475`) **character for character** | ✅ **genuinely pre-existing and genuinely not widened.** `UnicodeDecodeError` is a `ValueError`, and the identical tuple sits in `_ipv6_setting()`, which this task does not touch and which T-16 shipped — `sc ipv6 show` is a valid control, not a co-defendant. The docstring `:1659-1669` names both holes; no README, help row, changelog line or runtime string claims `sc telemetry` is traceback-free. The neighbouring `_ipv6_setting()` docstring still says "silently", but it is frozen here and correctly untouched |
| K-11 / K-12 / NFR-10 | `README.md:238`, `README.zh-CN.md:238`, `CHANGELOG.md:7` | ✅ in every user-facing surface; the one residual instance is CR-2, in frozen source |
| C-6 / C-9 | `README*.md:154`; four-column table `:158-176` for all 17; N-14 and N-11 comments `:1641`, `:1637` | ✅ |
| K-13 permitted diff | `bin/sc`, both READMEs, `CHANGELOG.md`, `docs/dev-map.md`, stage docs | ✅ nothing else in the tree carries a T-17 edit |

## Axis status
- **Standards-conformance: 3 findings, worst = MINOR** (CR-1, CR-2, CR-6). The repo's conventions
  hold: no invented rule, no widened vocabulary, no new file or constant beyond the one tuple, the
  `t()`-key discipline is exact, both READMEs are true line-for-line mirrors at 433 lines, the help
  alignment follows the overflow convention D-7 authorised, and the two rule-85 tests the task
  invites (`_telemetry_meaning`, the list's size) both come out in the implementation's favour.
- **Spec/design-fidelity: 4 findings, worst = MINOR** (CR-3, CR-4, CR-5, CR-7). Every acceptance
  criterion has an implementation; all five recorded drifts are upheld on their substance, three of
  them (DD-1, DD-2, DD-3) as the correct discharge of a binding gate condition; the residue is
  reporting precision in `04` and two stage-2 units that will mislead at delivery if nobody amends
  them.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-1 | AC-7's freeze is asserted from reading, not from an `ast` extraction + byte comparison against HEAD — stage 5 held no shell. K-15 makes the mechanical check binding; stage 6 must run it and record it. | `06_TEST_REPORT.md` |
| RES-2 | Every behavioural observation (V-22…V-30, the controls, the latency distribution, the C-3 resolution checks) is accepted here from `04_RATIONALE.md` and re-measured by nobody at this stage. | `06_TEST_REPORT.md` |
| RES-3 | CR-4: AC-B6b's `[D]` half was evidenced on 5 of 16 names. Observe all 16 or state the sample as a limit, as C-10 did for BC-1. | `06_TEST_REPORT.md` |
| RES-4 | CR-3: `06` must state the AC-B6b-as-written inconclusive result where it states the count, not only where it explains the split. | `06_TEST_REPORT.md` |
| RES-5 | CR-5: I-9's "Published anchors" row and RS-3's `CONTEXT.md` glossary term both still name `{"rcode": "NXDOMAIN"}`. Amend at delivery, in the same pass as C-7's Q-5 amendment, or `CONTEXT.md` receives a definition both shipped READMEs contradict. | `07_DELIVERY.md`, `02_SOLUTION_DESIGN.md` |
| RES-6 | CR-2: the K-12-forbidden negative-caching claim also lives in shipped source at `bin/sc:1595-1596` (frozen, T-16's). C-7's amendment list covers `01` and `01_RATIONALE.md` only. | `07_DELIVERY.md` |
| RES-7 | CR-1: `docs/dev-map.md:55` names `{"clash_mode":"Global"}` as a published anchor; the actual second published anchor is `{"clash_mode":"Direct"}` (`README*.md:384`). One-line correction, developer-owned. | `07_DELIVERY.md` |
| RES-8 | A pool row that re-runs a resolution check over `TELEMETRY_NAMES` (RS-7 + the N-7 drop proves the need), and a second that closes the `UnicodeDecodeError` hole once at `load_settings()` for every reader — both named by the developer, neither owned by anyone yet. | `docs/tasks.md` (via PM) |
| RES-9 | AC-B4's verification column overstates its own count fourfold ("24 combinations per name"); it is 6 per probe name, 24 in total. Correct at delivery. | `01_REQUIREMENT_ANALYSIS.md` (via PM) |

## Verdict
APPROVED WITH FINDINGS (0 CRITICAL, 0 MAJOR, 5 MINOR, 2 NIT) — CR-1 and CR-3 are the developer's, in
this round or at delivery; CR-2, CR-5 and CR-4/RES-3 route to the PM and stage 6; no rollback.
