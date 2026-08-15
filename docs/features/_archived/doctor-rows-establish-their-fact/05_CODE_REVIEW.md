> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `/home/alan/Programs/singbox-cli/bin/sc`
- `/home/alan/Programs/singbox-cli/README.md`
- `/home/alan/Programs/singbox-cli/README.zh-CN.md`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/CONTEXT.md`
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`
- `/home/alan/Programs/singbox-cli/docs/features/doctor-rows-establish-their-fact/01_REQUIREMENT_ANALYSIS.md` (contract read, not judged)
- `/home/alan/Programs/singbox-cli/docs/features/doctor-rows-establish-their-fact/02_SOLUTION_DESIGN.md` (contract read, not judged)
- `/home/alan/Programs/singbox-cli/docs/features/doctor-rows-establish-their-fact/03_GATE_REVIEW.md` (contract read, not judged)
- `/home/alan/Programs/singbox-cli/docs/features/doctor-rows-establish-their-fact/04_DEVELOPMENT.md` (contract read, judged for disclosure adequacy)
- `/home/alan/Programs/singbox-cli/docs/features/doctor-rows-establish-their-fact/04_RATIONALE.md` (opened under T5.2 — adjudicating declared drift D-1)
- `/home/alan/Programs/singbox-cli/.harness/rules/70-doc-size.md` (schema check)

**Tool limit, stated before any verdict rests on it.** Stage 5 holds `Read` / `Grep` / `Glob` only on this run — no execution tool. Every finding below is established by reading the working tree first-hand. Two obligations are therefore discharged by surrogate rather than by re-execution and are labelled as such: the `git diff --numstat` half of BC-G, and AC-17's `git status`. Neither is passed on the developer's word alone — each carries a first-hand surrogate and a residual routing the machine measurement to the next stage that holds the tool.

## Findings

| id | severity | axis | file:line | finding |
|---|---|---|---|---|
| CR-1 | MINOR | Standards-conformance | `bin/sc:2222-2223` | `stored_delays()`'s first guard paragraph still reads "The is_running() guard is INSIDE the function **so every future caller inherits it**: on a stopped host there is no request at all and therefore no 3 s wait." After E2 that is over-broad — a caller naming a port does **not** inherit it, and `sc doctor` is exactly such a caller. The narrowing lives only in the next paragraph (`:2225-2227`), and `docs/dev-map.md:65` states the same contract correctly ("every caller **that does not name a port** inherits"). This is the task's own BC-D principle — a sentence must not outlive the check it describes — left unapplied at the one site E2 falsified. Two words fix it; no behaviour is involved. |
| CR-2 | MINOR | Standards-conformance | `docs/features/doctor-rows-establish-their-fact/04_DEVELOPMENT.md:85-92` | The fixture near-miss remediation is stated as "The case was rebuilt to call `cmd_ls()` **directly**, and the final fixture drives `main()` only for `doctor` and `ipv6`." That does not remove the reach it was written to remove: `main()`'s read-only arm is `if args.cmd in ("doctor", "config")` (`bin/sc:3755-3760`), so **`ipv6` takes the initialising arm exactly as `ls` did** and the final fixture still drives `_init_files()` — including its hard-coded `Path("/var/lib/sing-box").mkdir(...)` (`bin/sc:543`, un-repointable by any harness, per the comment at `:35`). The host effect is nil for precisely the reasons the developer documented (`exist_ok=True`, mtime unchanged, all eight constants redirected), and the disclosure itself is otherwise exemplary — but the remediation sentence as written would let a later reader believe the initialising arm is no longer driven. Correct the sentence, not the fixture. |
| CR-3 | NIT | Standards-conformance | `docs/dev-map.md:39` | The `# Clash API` file-map row still reads "`port=None` means 'the port `main()` resolved'; only `sc doctor` passes one explicitly" — true, but carrying none of the second clause that the "Reusable utilities" row (`:65`) now carries. Two rows describe the same argument and only one states its two-clause contract. Not declared in E9's four rows, so this is flagged, not required; the RS-6 residual is the natural home for it. |

## Requirement coverage check

| criterion | implementation | status |
|---|---|---|
| FR-1 / FR-2 (each row states only what its probe established; narrow-vs-establish per row) | AAAA → establish (`bin/sc:2719-2726`); node delays → establish (`:2234`, `:2852-2864`); DNS → narrow (`:2871-2884`) | ✅ |
| FR-3 / AC-16 (three fixes share no new construct) | Top-level `def`/`class` count over `bin/sc` measured first-hand by me: **113** — identical to the reported before/after. The three fixes are one expression, one condition and five sentences; no module, class, decorator, registry, helper or shared validator appears | ✅ |
| FR-4 / AC-1 (position, not membership) | `bin/sc:2720` `rules[:len(prepend)] == prepend` | ✅ |
| FR-5 / AC-3 (one definition, two readers) | `_dns_overlay(suppress)` (`:1753-1773`) is the sole home; `generate_config()` (`:2092`) and `_doctor_ipv6()` (`:2719`) are its only readers — grep over `bin/sc` returns exactly those two call sites | ✅ |
| FR-6 / AC-5 (count read, never a count no request produced) | Guard `:2234` narrowed; `_doctor_clash()` gained no call, no check, no second liveness judgement; PROBLEM sentence (`:2861-2864`) states the read | ✅ — see ruling R-a below |
| FR-7 / BC-7 / AC-7 (`sc ls` unchanged, guard kept in the function) | `cmd_ls()` calls `stored_delays()` with no port (`:2311`); the guard is still inside the function, only its condition narrowed (K-4) | ✅ |
| FR-8 / AC-9 / AC-10 / BC-12 (all three DNS branches) | `:2871-2884`; OK asserts no upstream resolution, both PROBLEM branches carry the shared clause | ✅ |
| FR-9 / K-5 (probe unchanged) | `:2869` — one `GET /dns/query?name=` + `EGRESS_HOST` + `&type=A`, one name, one type, one constant, no retry, no second endpoint | ✅ |
| FR-10 / FR-11 / AC-12 / AC-13 (R-24 at one line) | `:3219-3220` prints `cmd_telemetry`'s existing key; both comparison sides still come from `ipv6_decision()` (`:3209`, `:3213`), neither from disk; no branch added | ✅ |
| FR-12(a) no second opinion | E2 **removes** one (a liveness judgement overriding the caller's); E1 **adds** none (no second `ipv6_decision()` call — `_doctor_ipv6()` calls it once at `:2701` and hands `suppress` to the overlay) | ✅ |
| FR-12(b) process-wide read-only | `main()`'s read-only arm is unchanged (`bin/sc:3755-3760`): `doctor` still reaches neither `_init_files()` nor `_resolve_clash_port()`. `_dns_overlay()` after E1 is pure — no I/O, no print, no `ipv6_decision()` call (`:1753-1773`), and `_aaaa_rule()` likewise (`:1742-1750`) | ✅ |
| FR-12(c) ordering table / causal order | `DOCTOR_SECTIONS` (`:2985-2995`) byte-consistent with the published order; its sole reader is `cmd_doctor` (`:3014`) | ✅ |
| FR-12(d) row grammar, classes, markers, exit mapping, isolation, flush | `_doctor_print` / per-section envelope / `worst = max(...)` at `:2998-3028` untouched | ✅ |
| FR-13 / AC-15 (published sentences true of the build) | `README.md:263,266,272,279` and `README.zh-CN.md:263,266,272,279`, each read against the shipped strings; `README*.md:280` (exit `2`) **unchanged**, correctly — no row becomes UNKNOWN where it was PROBLEM, so BC-9 does not fire. `docs/dev-map.md:58,61,62,65`. `CHANGELOG.md:26`, one `### 修复` entry in Chinese naming the three rows, the `sc ipv6` line, both exit-status directions and the byte-identical `config.json` | ✅ |
| AC-2 (both BC-3 causes on one line) | `:2723-2726` names regeneration **and** `{override}`; `TRANSLATIONS` zh half `:310` carries both | ✅ |
| AC-4 (generated document reads `[OK]` with the existing sentence) | The `[OK]` key `:308` and its site `:2721-2722` are unchanged | ✅ |
| AC-6 (init system + no history stays PROBLEM `0/2` naming `sc ls`) | `:2861-2864` keeps class, numerals and `sc ls` | ✅ (behavioural confirmation is stage 6's) |
| AC-8 (no second liveness judgement, no new liveness source) | Ruling R-b below | ✅ |
| AC-11 (one `GET /dns/query`, no write) | One call site (`:2869`); no new write path anywhere in the changed regions; `_write_private()` unreached from any doctor probe | ✅ (snapshot evidence is stage 6's) |
| AC-14 (same rows, labels, order, exit status) | No row added or removed: `_doctor_clash()` returns the same four rows on every branch (`:2819-2885`); `DOCTOR_SECTIONS` unchanged | ✅ |
| AC-17 (only the declared files) | The six declared files carry the changes described by E1…E10 and I found no change outside them by reading; `git status` / `git diff --numstat` could not be re-executed at this stage → RES-1 | ✅ (surrogate; machine confirmation routed) |
| NFR-1 (report shape on a healthy host) | No row added; no row's enumeration grows with the host's contents | ✅ |
| NFR-2 (added cost is zero requests) | Ruling R-c below | ✅ with recorded tension |
| NFR-3 (size bar) | BC-G ruling below | ✅ at the ceiling |
| NFR-4 (every changed string keeps its `zh` entry in its existing thematic group; no `en` half) | Five keys re-worded in place at `:308-310`, `:334-335`, `:336-337`, `:338-339`, `:340-341`, each in its existing group; the key **is** the English rendering at every site (`:2722`, `:2724-2726`, `:2862-2864`, `:2878-2879`, `:2882-2884`, `:2873-2875`) | ✅ |

**Ruling R-a (FR-6's letter vs the shipped row).** FR-6 admits "a count read from the `/proxies` answer, **or** UNKNOWN naming that the count could not be read". The shipped zero case is PROBLEM naming "the list could not be read" as one of three causes rather than UNKNOWN. This is not developer drift: it is I-6's stated invariant ("states the **read**, not the world"), it is out-of-scope 3 of the design, and gate condition **BC-A** ratifies exactly this shape in advance ("must state what was read and name 'the list could not be read' among its causes"). The row is honest in every reachable state — a `GET /proxies` is always issued on this branch, so no count is stated that no request produced. In-bounds; the discrimination is stage 6's under BC-A.

**Ruling R-b (AC-8 / K-3 and the one legitimate `is_running` in the diff).** AC-8's grep is a proxy; its intent, stated in FR-6, is "no **second** liveness judgement is introduced anywhere". I read every call site rather than the grep. `is_running()` is called from exactly one place inside `stored_delays()` — the guard at `:2234`, which is I-4 verbatim — and `_doctor_clash()` gained no liveness call, no `SYSTEMD`/`OPENRC` read and no `subprocess` call. The token appears in the diff only as the two halves of that one changed guard line; the new docstring paragraph deliberately says "the guard above" (`:2226`) rather than naming the function again, so the grep stays readable. Intent held, letter satisfied on the only reading that means anything. Elsewhere in `bin/sc` the token appears only at pre-existing sites (`:2201-2207`, `:2357`, `:2436`, `:2444`, `:2745`, `:3178`, `:3401`), none of them new.

**Ruling R-c (NFR-2 vs FR-6, named rather than passed silently).** On an init-less host with an answering API the candidate issues a `GET /proxies` that HEAD short-circuited away. Read literally ("no probe issues a request this build does not already issue") that is a new request on that host class; read as the constraint the design and K-5 spell out (no new endpoint, no new constant, ≤ 1 `GET` per `stored_delays()` call, only on the branch where `/configs` already answered) it is not. FR-6 is the specific, later-ruled provision (OQ-3: "R-49 → establish; narrowing is inadmissible") and it cannot be satisfied without that request; NFR-2's own purpose — no probe invented for this task — is intact. I rule the request in-bounds, and route the per-host-class request count to stage 6 (RES-4) so the reading is measured rather than argued.

## Design fidelity check

| design item | implementation | status |
|---|---|---|
| E1 — AAAA row: `_dns_overlay(suppress)`, compose list passes `ipv6_decision()[1]`, probe tests the head, PROBLEM names both causes, three docstrings corrected | `bin/sc:1753`, `:2092`, `:2719-2726`, docstrings at `:1743-1747`, `:1754-1771`, `:2684-2699` | ✅ |
| E2 — **one changed line** `if port is None and not is_running():`; docstring states the interface; `_doctor_clash()` gains no call; PROBLEM states the read | `:2234`, `:2225-2227`, `:2852`, `:2861-2864` | ✅ (docstring caveat = CR-1) |
| E3 — DNS sentences only; probe, endpoint, name, type, timing, classes byte-for-byte unchanged | `:2868-2884`; `started`/`ms` timing, the `is None` / `Answer` / else branch structure and all three classes unchanged; `_doctor_clash()`'s docstring gained the cache sentence at `:2816-2817` | ✅ |
| E4 — R-24 key swap; orphaned key deleted | `:3219-3220` prints the `cmd_telemetry` key (`:208-211`); grep confirms **exactly one** "Nothing changed" key survives and both call sites (`:3219`, `:3282`) resolve to it — the short sibling formerly at `:192` is gone | ✅ |
| E5 — five `zh` entries re-worded in place, one deleted, none added | `:308-310`, `:334-335`, `:336-337`, `:338-339`, `:340-341` re-worded in their existing groups; one deletion; no new key found anywhere in the table | ✅ |
| E6 / E7 — four README lines per file, mirrors aligned | `README.md:263,266,272,279` ≡ `README.zh-CN.md:263,266,272,279`; both files' `:280` unchanged; the mirror still aligns line-for-line at every one of the five numbers | ✅ |
| E8 — one Chinese `### 修复` entry under `[Unreleased]` | `CHANGELOG.md:26` | ✅ |
| E9 — four "Reusable utilities" rows | `docs/dev-map.md:58` (`ipv6_decision()` caller list), `:61` (`_aaaa_rule()` — position, not membership), `:62` (`_dns_overlay(suppress)`), `:65` (`stored_delays()` two-clause guard); the mandated recipe at `:136` is untouched, per BC-J | ✅ (see CR-3) |
| E10 — one `CONTEXT.md` glossary term | `CONTEXT.md:106-113`, placed with the composition terms, `_Avoid_` line present | ✅ |
| I-1 `_dns_overlay(suppress)` — one home of content **and** emitted position, pure, never calls `ipv6_decision()` | `:1753-1773`; returns `{"dns": {"rules": {"$prepend": [_aaaa_rule(suppress)]}}}` | ✅ |
| I-2 compose list; `ipv6_decision()` still called once per generate | `:2091-2092`; overlay order unchanged | ✅ |
| I-3 probe shape `rules[:len(prepend)] == prepend`, guarded by `isinstance`, KeyError → the section's own UNKNOWN | `:2718-2720`; the overlay call is **outside** the `try` at `:2705-2709`, so a renamed directive raises into `cmd_doctor`'s per-section envelope (`:3015-3022`) — never a silent PROBLEM | ✅ |
| I-4 `stored_delays(port=None)` guard, return shape, ≤1 GET, method set, `isinstance` house style | `:2234-2258` — body below the guard byte-consistent with its frozen description | ✅ |
| I-5 AAAA PROBLEM sentence, two placeholders on both halves, `override=str(OVERRIDE_PATH)` | key `:309` / zh `:310` / site `:2723-2726` | ✅ |
| I-6 node-delay PROBLEM sentence | key `:334` / zh `:335` / site `:2861-2864`; the `{n}/{total}` OK key `:332-333` unchanged | ✅ |
| I-7 DNS OK sentence | key `:336` / zh `:337` / site `:2877-2879` | ✅ |
| I-8 DNS PROBLEM sentences, one clause spelled identically four times | keys `:338`, `:340` / zh `:339`, `:341` / sites `:2872-2875`, `:2881-2884` — **BC-H confirmed byte-identical**, see below | ✅ |
| I-9 published sentences, exit-`2` row needs no change | as E6/E7 above | ✅ |
| I-10 glossary term | `CONTEXT.md:106-113` | ✅ |
| K-1 no new top-level `def`/`class`, no shared construct | 113 measured first-hand; three fixes share nothing new | ✅ |
| K-2 zero keys added, exactly one deleted, placeholder sets and thematic groups kept | verified per key, both halves | ✅ |
| K-3 no new liveness source | ruling R-b | ✅ |
| K-4 guard neither deleted nor moved out of the function | `:2234`, still the first statement of `stored_delays()` | ✅ |
| K-5 nothing about what `/dns/query` is asked changed | `:2869` | ✅ |
| K-6 `sc doctor` read-only; arm reaches neither writer | `:3755-3760` | ✅ |
| K-7 emitted `config.json` byte-identical | E1 changes only how the overlay **receives** the decision; `_aaaa_rule()`'s returned dict and `$prepend` are unchanged, so the emitted bytes cannot move. Byte-identity was measured by the developer across four compositions (`04_RATIONALE.md` §V-1); I confirm the code path admits no other outcome | ✅ |
| K-8 no new `try`/`except` around `clash_api()`, `_dns_overlay()` or `stored_delays()` | `_doctor_clash()` wraps only `load_nodes()` (pre-existing, `:2839-2847`); `_doctor_ipv6()` wraps only the file read (pre-existing, `:2705-2709`); `stored_delays()` has none | ✅ |
| K-9 no `失败：` in any changed or added `zh` string | grep over `bin/sc`: the literal occurs only at `:136`, `:145`, `:213`, all pre-existing keys untouched by this task | ✅ |
| K-10 fixture discipline (no live re-exec, no live-service action) | disclosed and judged; see CR-2 | ✅ with CR-2 |
| Frozen set, read with BC-D's narrowing | `_aaaa_rule()` returned dict and signature unchanged (`:1742`, `:1749-1750`); `ipv6_decision()` body/signature/return unchanged (`:1722-1739`); `is_running()` unchanged (`:2201-2207`); `clash_api()` unchanged; `CONFIG_BASE`/`_compose`/`_merge`/`_apply_directive`/`DIRECTIVES` untouched; `DOCTOR_*` + `_doctor_print()` + `cmd_doctor()` untouched; `cmd_ls()`/`cmd_status()` untouched; `stored_delays()` return shape and body below the guard untouched; `install.sh`/`uninstall.sh`/`systemd/**` and `.harness/**`/`docs/tasks.md`/`docs/batches/**` untouched | ✅ |
| D-1 declared drift — `ipv6_decision()`'s docstring caller list corrected | `:1708-1710` now reads "cmd_ipv6(), `sc doctor`'s AAAA row and generate_config() (which hands it to _dns_overlay())" | ✅ **in-bounds, not a scope escape** — ruling below |

**D-1 ruling.** In-bounds. The frozen row's own stated reason is behavioural ("T-16's AC-6 and FR-11 depend on both sides of `cmd_ipv6`'s comparison coming from it"), and the body, signature and return value are byte-unchanged — I read them. BC-D established for this very task that a frozen row freezes the returned value and the signature, **not** a sentence the edit falsifies; E1 falsifies this sentence in exactly the way it falsified `_aaaa_rule()`'s, and E9 corrects the identical caller list in `docs/dev-map.md:58` by design, so leaving the code sentence would ship the map and the code in disagreement — the defect this whole task exists to remove. Four docstring lines, no behaviour, inside the size bar. Approved as declared.

## The three binding conditions owned by stage 5

**BC-G — the size gate.** Quoted as delivered, from `04_DEVELOPMENT.md` §Condition disposition: `git diff --numstat bin/sc` → **`55  44`**, i.e. `+55/−44`. That is **inside** BC-G's `+55/−45` bar and is therefore **not** reported as a scope escape against NFR-3 / F-9 — but it is **at the ceiling on the added half, with zero margin**, and the recorded discharge covers `≈ +50/−40`, so the delivery sits above its own projection and below its gate. AC-16's before/after count I ran **as written and first-hand**, by the read-only means available: `^(def |class )` over `/home/alan/Programs/singbox-cli/bin/sc` → **113**, matching both the reported "before" and the reported "after"; no new top-level `def` or `class` exists, and no construct is shared across the three rows. The numstat itself I could not re-execute (no execution tool at this stage) — it is quoted, not re-measured, and RES-1 routes the machine measurement to stage 6.

**BC-H — the shared clause.** **Confirmed, no divergence.** English: both `:338` and `:340` (and their sites `:2882-2884`, `:2873-2875`) carry, byte-identically, `try another node with `sc use <n>`; an answer already cached by the running sing-box survives a node change`. Chinese: both `:339` and `:341` carry, byte-identically, `可用 `sc use <编号>` 换一个节点试试；正在运行的 sing-box 已缓存的应答不会因为换节点而失效`. The multi-line source concatenations at the two call sites resolve to the same bytes as their table keys. Placeholder sets, all five re-worded keys, both halves: `{decision, override}` / `{decision, override}`; `{total}` / `{total}`; `{name, ms}` / `{ms, name}`; `{name, ms}` / `{name, ms}`; `{name, ms}` / `{ms, name}` — set-equal on every one (order differs on two `zh` halves, which is rendering order, not a set difference).

**BC-D (stage 5's half).** **Confirmed.** `grep` for `membership` over `bin/sc` returns nothing — no docstring anywhere in the file still describes the probe as a membership test; the only `成员` occurrence (`:359`) is an unrelated pre-existing key about JSON array members. `_aaaa_rule()`'s body and returned dict are untouched (`:1749-1750`: `{"action": "predefined", "rcode": "NOERROR", "query_type": ([28, 64, 65] if suppress else [64, 65])}`), its signature unchanged, and only the docstring clause at `:1745-1747` corrected — it now reads "a POSITION test against `_dns_overlay()`'s own payload". `_doctor_ipv6()`'s prohibition sentence is **gone**: the docstring at `:2684-2699` carries no "deliberately NOT called" clause, and PQ-1's reason for it is genuinely removed — `_dns_overlay(suppress)` is now pure and calls `ipv6_decision()` nowhere.

## The honesty test — the point of the task

| row | does the shipped sentence claim only what the probe established? |
|---|---|
| DNS `[OK]` (`:2877-2879`) | **Yes.** "the running sing-box answered for {name} in {ms} ms, possibly from its own DNS cache" asserts an **answer**, not a resolution; no upstream claim survives anywhere in the file — the old "resolved in … through the running sing-box" string is absent from `bin/sc`. The `{ms}` is attached to "answered", not to a resolution. |
| DNS PROBLEM ×2 | **Yes.** Both withdraw the assertion that a node change is effective against a cached answer, and the clause is a standing property of the install ("an answer **already cached** … survives a node change"), so it is true on the branch where nothing answered — it claims nothing about this answer's provenance. |
| node delays PROBLEM (`:2861-2864`) | **Yes.** "a stored delay was **read** for 0/{total} nodes — either no probe has completed yet, every node is failing, **or the list could not be read**". A `GET /proxies` is now issued on every branch this row is reached from, so no count is stated that no request produced; and the third cause keeps the sentence true in the state where the request produced no usable body. |
| node delays `[OK]` (`:2855-2859`) | **Yes.** `n` is `len(tags & set(delays))` over the `/proxies` answer just read. |
| AAAA PROBLEM (`:2723-2726`) | **Yes**, and BC-F holds: both BC-3 causes are named on the one line — regeneration **and** `{override}` — and I-5's `OVERRIDE_PATH` clause is present in **both** language halves (`:309` en, `:310` zh), neither shortened nor merged. |
| AAAA `[OK]` (`:2721-2722`, key `:308`) | **Yes**, and deliberately narrower than what was established: the probe established the rule is **first**; the sentence claims only that the document carries the decision. Narrower than the fact is admissible under FR-1; wider is not. |

## Fixture near-miss — adequacy of disclosure and remediation

**Disclosure: adequate, and better than the norm.** It is in the **contract** portion, names the mechanism (`main()`'s initialising arm), the exact function, the exact lines (`bin/sc:541-543`), the evidence that nothing was written (`exist_ok=True`, `/var/lib/sing-box` mtime unchanged, no new entry), what was redirected, and that no live-service action, no `/etc/sing-box` write, no install over `/usr/local/bin/sc` and no live Clash API request occurred at any point. I re-read `_init_files()` and confirm the mechanism as described: only `Path("/var/lib/sing-box")` is un-repointable (the comment at `:35` already records why), and both `mkdir` calls pass `exist_ok=True`. I re-ran nothing, per my constraints.

**Remediation: effective in substance, inaccurately stated.** See CR-2 — `ipv6` takes the same initialising arm as `ls`, so the final fixture still drives `_init_files()`. The residual host exposure is the same nil quantity, but the sentence claims a boundary the code does not draw. MINOR, routed to stage 6 as RES-3 so the QA fixtures state the true reach and re-assert the snapshot rather than inherit the claim.

## Credential contracts

No credential bytes appear in the diff or in this document. T-13's credential handling and T-06's always-redacted `sc config` are untouched: `cmd_config`'s single `sys.stdout.write` through `_redact()` and its "no switch" contract are intact (`bin/sc:3113-3120`), `_write_private()` is unreached from any changed path, and the AAAA row prints no document content — only the two constants `str(CFG_PATH)` and `str(OVERRIDE_PATH)`. `verify_all` A.1 "No hardcoded secrets" is unaffected by every line I read.

## Axis status
- **Standards-conformance: 3 findings, worst = MINOR** (CR-1 docstring over-broad after E2; CR-2 inaccurate remediation sentence in a stage doc; CR-3 dev-map row not carrying the second clause). No blocking defect on this axis. Repo conventions otherwise held: contract docstrings beside every changed construct, `isinstance` house style with no new `try`/`except`, translation keys as their own English rendering, cross-language mirror alignment, no invented rule applied anywhere in this review.
- **Spec/design-fidelity: no findings.** E1…E10 shipped as declared; I-1…I-10 match the shipped strings and shapes, including I-8's four-times-identical clause; K-1…K-10 all held; the frozen set moved nowhere under BC-D's narrowing; D-1 is ruled in-bounds; the exit-`2` published row is correctly unchanged because BC-9 does not fire. Three requirement readings were adjudicated rather than passed silently (R-a FR-6's letter, R-b AC-8's grep, R-c NFR-2 vs FR-6) and all three resolve in-bounds.
- Aggregate: the more severe of the two axes = **MINOR**.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | BC-G's `git diff --numstat bin/sc` was quoted (`55  44`), not re-executed — stage 5 held no execution tool. AC-16's count was re-run first-hand (113). The delivery is at the ceiling on the added half with zero margin; the machine measurement of the numstat and of `git status` (AC-17) must be re-run and quoted by the first stage that holds Bash. | `06_TEST_REPORT.md` |
| RES-2 | BC-A and BC-B remain wholly unobserved at stage 5 — both are behavioural cells (`/configs` answers while `/proxies` does not; init system reporting stopped while the API answers). Code review establishes that the shipped sentences are true in those states; it cannot establish that they render. | `06_TEST_REPORT.md` |
| RES-3 | `sc ipv6` takes `main()`'s initialising arm (`bin/sc:3755-3760`), so any fixture driving `main()` for it reaches `_init_files()` and its hard-coded `/var/lib/sing-box`. Stage 6's fixtures must state that reach and re-assert the fixture-root snapshot rather than inherit stage 4's remediation sentence. | `06_TEST_REPORT.md` |
| RES-4 | NFR-2 is ruled satisfied on the reading "no new endpoint, no new constant, ≤ 1 `GET` per `stored_delays()` call". On an init-less host the candidate nonetheless issues a `/proxies` request HEAD did not. Count requests per host class, candidate vs HEAD, so the reading is measured. | `06_TEST_REPORT.md` |
| RES-5 | RS-3 stands: `stored_delays()` still cannot distinguish "no `/proxies` answer" from "an answer with no history". I-6's sentence is true across both; the distinction stays unavailable while the return shape is frozen. | `07_DELIVERY.md` (pool) |
| RES-6 | RS-6 discharged into this review and extended: the two-clause `port` contract now lives correctly in `docs/dev-map.md:65`, over-broadly in `bin/sc:2222-2223` (CR-1) and not at all in `docs/dev-map.md:39` (CR-3). Any future caller that names a port inherits "you have already judged liveness" — the three statements of that contract should agree. | `07_DELIVERY.md` (pool) |
| RES-7 | R-37, **eighteenth** confirmation: `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` (read this run — the file carries `## Caps` and `## Process discipline` only), so this review's transcripts and per-key evidence go to `05_RATIONALE.md` by the reviewer contract's own default. T-27 owns the one-section fix. | `07_DELIVERY.md`, T-27 |
| RES-8 | RS-2 upheld unchanged: BC-10 was discharged at stage 2 and is not reopened here. Stage 5 issued **no** request to the live Clash API, ran the installed `sc` never, imported `bin/sc` never, and wrote nothing anywhere. | `06_TEST_REPORT.md` |

## Verdict
APPROVED WITH COMMENTS
