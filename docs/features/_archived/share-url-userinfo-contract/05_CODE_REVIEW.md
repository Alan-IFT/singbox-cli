> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

# 05 — Code Review · T-22 `share-url-userinfo-contract`

## Files reviewed
- `/home/alan/Programs/singbox-cli/bin/sc`
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/README.md` (NFR-3 falsification check only; unmodified)
- `/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/t22/fixtures.py`
- `/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/t22/runner.py`
- `/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/t22/compare.py`
- `/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/t22/run.sh`
- `/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/t22/baseline-clone/bin/sc` (HEAD, for the independent diff and delta derivation)

## Findings

| id | severity | axis | file:line | finding |
|---|---|---|---|---|
| CR-1 | MINOR | Spec/design-fidelity | `scratchpad/t22/fixtures.py:66-80` | No `ss://` fixture carries a `%` anywhere in a **plaintext (URI-text)** userinfo. Three declared things therefore rest on nothing observed: BC-10's `%3A` half, BND-12's own named divergence case (`ss://a%3Ab:pw@h:8388` → `method` `a:b` / `password` `pw` under split-then-decode, `a` / `b:pw` under the forbidden order), and K-8 **delta 2** (the plaintext `method` is now decoded), which the developer's BND-3 row concedes no fixture diverges on. `s_h`'s `%41` is base64-recovered material, and `x5` observes the ordering for **tuic**, not for `parse_ss`. The shipped code is correct — both arms consume the one construct — so this is a coverage gap, not a defect. One fixture closes all three. Owner: QA (`06_TEST_REPORT.md`), carried as RES-1. |
| CR-2 | MINOR | Spec/design-fidelity | `scratchpad/t22/compare.py:70-71` | AC-3 and AC-4 assert on `row["node"]` — the parser's return value — while AC-1 and AC-5…AC-8 assert on `row["outbound"]`, read back from the document written to `CFG_PATH` in that run. FR-8 says the credential reaches the **emitted document** unmodified for **every** supported scheme; as run, shadowsocks, vless and vmess credentials never cross `generate_config()` under assertion, and AC-16's `v16` uuid is asserted on the parsed object rather than the document V-5 names. Neither group asserts `generated is True` (only AC-5…AC-8 does). `row["outbound"]` is already captured by `runner.py:86-89`, so the cost is one word. Owner: QA, carried as RES-2. |
| CR-3 | MINOR | Standards-conformance | `CHANGELOG.md:26` | The tuic damage clause appends «服务端因此一直认证不过» — a claim about live-server authentication behaviour. K-14 (a)'s four predicates are each present and each correct against HEAD; this is an unverified **consequence** attached to one of them, and AC-13 (BLOCKED by construction: root + real credential) is precisely the row that would establish it. K-14's own reasoning is that a sentence its audience cannot check must not outrun what is known. The predicate («存下来的 `password` 都是空字符串») is verified and sufficient; the consequence is not. Owner: developer. |
| CR-4 | NIT | Standards-conformance | `bin/sc:726` | `parse_ss` still binds `userinfo` from `body.rsplit("@", 1)` — frozen by K-6, correctly untouched. Worth recording *why* it is harmless: after CL-6 that value feeds **only** `_b64dec` at `:729`, so it never becomes a userinfo field taken from URI text, which is exactly what keeps `_userinfo`'s no-second-opinion sentence true (see BND-7 row below). The name still invites a fresh reader to take it for THE userinfo. No action available under K-6. |
| CR-5 | NIT | Standards-conformance | `bin/sc:638` | `dec(raw)` is evaluated at all five call sites including the three that discard it via `_`. Free in practice — `urllib.parse.unquote` returns its argument unchanged when no `%` is present — and I-1's three-value shape is what makes `pw:` recoverable at all. Recorded so a later reader does not mistake the `_` discards for dead computation and "optimise" the contract into two values. |
| CR-6 | NIT | Standards-conformance | this document, schema | BND-11 binds the sweep command and its output to `05_CODE_REVIEW.md`. The reviewer schema declares no section that can hold a command transcript, and `.harness/rules/70-doc-size.md` still has no `## Stage-doc boundary rule` (**R-37**, confirmed here for the tenth time) to classify one. Rather than invent a section, the transcript is in `05_RATIONALE.md` §"AC-10 static sweep" and its **result** is carried by the AC-10 and V-6 rows below. Recorded as a Findings row against the schema, per the reviewer contract. Owner: T-27. |

## Requirement coverage check

| criterion | implementation | status |
|---|---|---|
| AC-1 | `bin/sc:629-638` + `:644`, `:704`, `:731`, `:753`, `:778`; observed 19/19 on the candidate through the document at `CFG_PATH` (`compare.py:41-46` asserting `fixtures.py` constants) | ✅ |
| AC-2 | `compare.py:48-67`; 11 red at HEAD = `t_a t_b t_c t_d t_e j_a1 j_a2 j_a3 y_a1 y_a2 y_a3`. I re-derived all nineteen by hand against `baseline-clone/bin/sc:637,696,744,763-768` — the set matches BND-1 fixture-for-fixture, no match inside it, no mismatch outside it | ✅ |
| AC-3 | `fixtures.py:66-80`; `s_j`/`s_a`/`s_e`/`s_i` byte-identical, `s_h` = BC-9, `s_k` = K-8 delta 1. Enumerated set satisfied exactly; see CR-1 for the `%`-in-plaintext-userinfo gap and CR-2 for the assertion source | ✅ (CR-1, CR-2 noted) |
| AC-4 | `fixtures.py:85-123`; 12 vless (6 transports × `none`, `tls` ×2, `reality` ×2, `v11`, `v16`) + 4 vmess, every vless fixture carrying a uuid (K-9), no `%` outside `v16` | ✅ |
| AC-5 | `x5` = `tuic://a%3Ab:pw@h.example:443` → `uuid` `a:b`, `password` `pw`; guaranteed by `bin/sc:635-636` splitting before `:638` decodes | ✅ |
| AC-6 | `t_c`/`j_c`/`y_c` `100%2525`→`100%25`; `x6j`/`x6t` `100%25`→`100%`. Exactly one `unquote` per projection (`bin/sc:638`) | ✅ |
| AC-7 | `x7j`/`x7y`/`x7t` → `server` `2001:db8::1` **unbracketed**, `server_port` 443, credential correct. `p.hostname`/`p.port` untouched at `:648-649`, `:708-709`, `:757-758`, `:782-783`; brackets sit right of the last `@`, so `whole` never contains them (K-4, BND-8) | ✅ |
| AC-8 | `x8j`/`x8y`/`x8t` → `password` `""`, tuic also `uuid` `""`, document written. `rpartition` yields `""` with no `@`; `_userinfo` raises for no `str` | ✅ |
| AC-9 | `SECRET_KEYS` / `VISIBLE_IN_OUTBOUND` / `MASK` outside every hunk; the only key-shaped change is vless `"uuid": null` → `""` — same key, declared by K-9. Emitted key set identical to HEAD over all 50 fixtures | ✅ |
| AC-10 | My own sweep, re-run over the **whole** file (not only the section): zero `.username`/`.password`; group (ii) **exactly five** hits at `:636`, `:729`, `:734`, `:738`, `:739` — the five pre-enumerated by BND-4, no sixth; group (i) one last-`@` application inside `_userinfo` + four `p.netloc` argument passes + `unquote` only inside `_userinfo` and at the two tag decodes (`:575`, `:724`) + `body.rsplit("@", 1)` present and unchanged. Transcript in `05_RATIONALE.md` (CR-6) | ✅ |
| AC-11 | No `t()` call, no user-facing string and no `TRANSLATIONS` key added anywhere in the hunks; `失败：` occurs once in `CHANGELOG.md` (line 39, a pre-existing 0.1.0-era entry) and zero times in the new bullet | ✅ |
| AC-12 | `CHANGELOG.md:26`, read clause by clause: (a) 每一个 tuic 节点 → empty password; (b) trojan / hysteria2 with a **未经转义的冒号**; (c) shadowsocks **从 base64 还原出来的** password containing `%XX`; (d) vless / tuic ids percent-escaped in the link. Both non-claims are made **positively** as correct-today («shadowsocks 密码里的冒号» and «trojan / hysteria2 / shadowsocks 明文形式密码里的百分号»), which I verified against HEAD's `:717`, `:724`, `:696`, `:744`. Repair = `sc rm` → `sc add`, with `sc reload` **修不好**它 and Q-1's reason. Chinese only, no English gloss, so no cross-language divergence is possible. No README sentence is falsified (grep of `README.md` for tuic / password / credential claims found none about fidelity), so the parity clause does not fire | ✅ (CR-3 noted) |
| AC-13 | **BLOCKED by construction** — root + installed `/usr/local/bin/sc` + a real credential. Not attempted, not treated as a defect, no artifact check substituted (K-20). Operator recipe travels as RES-5 | ⛔ BLOCKED (expected) |
| AC-14 | Not run at this stage — needs a real `sing-box` with `SB_BIN` un-stubbed. **Non-regression only** wherever reported: HEAD's defective document also passes | ⏳ QA (V-9) |
| AC-15 | Developer records PASS 17 · WARN 0 · FAIL 0 · SKIP 1, matching the batch baseline, A.1 PASS. **I could not re-run it**: this stage holds no shell capability. Not a defect; the reviewer-side V-8 run is carried as RES-4 | ⏳ (RES-4) |
| AC-16 | `v16` = `vless://a%2Db@h.example:443` → `uuid` `a-b`; `bin/sc:644` takes the **first** projection and `:638` decodes it once. HEAD emits `a%2Db` (`baseline-clone/bin/sc:637`) | ✅ (CR-2 noted) |

## Design fidelity check

| design item | implementation | status |
|---|---|---|
| I-1 `_userinfo(authority) -> (whole, first, rest)`, pure, total, decoded exactly once | `bin/sc:629-638`; signature exactly as specified — no added parameter, no default, no module, no `urlparse` of its own | ✅ |
| I-1 three values rather than two (`pw:` vs `pw`) | `:638` returns `dec(raw)` independently of `first`/`rest`; `j_a3`/`y_a3` (`pw:`) green on the candidate, which a `first + ":" + rest` rebuild cannot achieve | ✅ |
| I-2 vless takes the **first** projection | `:644` `_, uuid, _ = _userinfo(p.netloc)` | ✅ |
| I-3 / I-4 trojan and hysteria2 take the **whole** projection, identically | `:704` and `:753`, byte-identical statements — they cannot diverge | ✅ |
| I-5 tuic takes (**first**, **rest**) | `:778` `_, uuid, password = _userinfo(p.netloc)`; HEAD's structurally dead `":" in userinfo` branch (`baseline-clone/bin/sc:763-768`) deleted | ✅ |
| I-6 ss plaintext arm takes (**first**, **rest**) over the `ss://` body, `except` arm only | `:731` `_, method, password = _userinfo(body)`; `body.rpartition("@")[0]` reproduces `body.rsplit("@", 1)[0]` value-for-value | ✅ |
| I-7 zero edits between parser and document | `# Config composition`, `generate_config()`, `_runtime_overlay()` outside every hunk | ✅ |
| K-1 last `@` via `rpartition` | `:635` `raw = authority.rpartition("@")[0]` — not `partition`, not `split('@', 1)`, not `index` | ✅ |
| K-2 / BND-12 split on **raw** text, decode after, once per field | `:635` → `:636` `raw.partition(":")` → `:638` three single `dec()` calls. The plaintext ss arm inherits this order through `:731`; the opposite order would make `ss://a%3Ab:pw@h` emit `method` `a`, `password` `b:pw` | ✅ discharged |
| K-3 no `.username` / `.password` | zero occurrences in the whole file (my sweep) | ✅ |
| K-4 host/port unchanged | `p.hostname` / `p.port` at `:648-649`, `:708-709`, `:757-758`, `:782-783` byte-identical to HEAD | ✅ |
| K-5 four `p.netloc` argument passes | `:644`, `:704`, `:753`, `:778` | ✅ |
| K-6 ss arm selection / `rsplit("@")` / `hostpart` / `int(port)` frozen | `:725-726`, `:732-734`, `:744` identical to `baseline-clone/bin/sc:711-712`, `:718-720`, `:730` | ✅ |
| K-7 neither base64 arm routed through `_userinfo` or `unquote` | `:729` and `:738` keep their own split; `:746` is now bare `password` | ✅ |
| K-13 / BND-7 docstring is the contract, no-second-opinion sentence scoped to userinfo **fields taken from URI text** | `:630-634`. Not falsified by `:729`/`:738` (base64-recovered material, never URI text), not by `:575`/`:724` (URI text, but a tag), and not by `:726` — whose product, after CL-6, feeds only `_b64dec` and never becomes a field (CR-4). Return order, last-`@`, first-raw-colon, decode-once and purity all stated in 5 physical lines | ✅ discharged |
| K-10 / K-11 no new string, key, error path or import | none added; `urllib.parse` already imported, `str.partition`/`rpartition` 3.6-legal | ✅ |
| K-12 / BND-13 ≤22 added / ≤11 removed across the six named edit locations | **+21 / −11**, measured by me line-for-line against the baseline clone (12 for CL-1, 2/1 each for CL-2/CL-3/CL-4, 2/2 for CL-6+CL-7, 1/6 for CL-5). All seven change sites present. The 5-hunk rendering is git's default 3-line context merging two adjacent pairs (CL-1↔CL-2 three lines apart, CL-7↔CL-4 six lines apart); BND-13 and PQ-10 both make the **cap** the binding number, not the hunk count | ✅ discharged — 5 hunks satisfies it |
| K-14 / BND-2 CHANGELOG bullet, Chinese, four predicates, two non-claims, repair with its `sc reload` negative | `CHANGELOG.md:26` — all four present, both non-claims stated positively as correct-today, repair and negative both present, clauses (c) and (d) present | ✅ discharged (CR-3 noted) |
| K-15…K-19 harness outside the worktree, os-shim neutralisation, no `main()`/`_init_files()`, eight paths repointed **and asserted**, `git clone` at the same fixture root | `run.sh:1-24` (`git clone`, never `git worktree`; refuses root), `runner.py:26-38` (shim restored in `finally`), `:41-62` (all eight asserted inside root), `:79-83` (state rewritten, `STATE_PATH` unlinked, root never moved), `:93-94` (`LANG`/`CLASH_PORT` asserted after **every** run). Baseline clone's `origin/main` = `51c0f476…` = the worktree's `refs/heads/main`, so the baseline is genuinely HEAD | ✅ |
| K-21 / BND-6 per-class explicit fixture text, never a blanket `quote()` | `fixtures.py` carries zero `quote(` calls; every raw `:` is raw (`t_a` `p:q`, `j_a1..3`, `y_a1..3`, `s_a`, `s_j`, `v11`), every `%3A`/`%2525`/`%XX` is a literal, and every expected value is a constant, never a re-derivation | ✅ |
| BND-10 vless `%`-free raw-colon fixture | `v11` = `vless://a:b@h.example:443` → `uuid` `a`, byte-identical to HEAD — the only instrument separating FR-7's first-field reading from FR-5's whole-userinfo one | ✅ |
| RT-6 / BND-3 exactly three behaviour deltas, no fourth | Re-derived per parser, HEAD vs shipped, from `baseline-clone/bin/sc:629-784`: vless (`None`→`""` + decode, both stated), trojan/hy2 (whole vs first, FR-5), tuic (rest vs `""` + uuid decode, FR-4), ss (base64 no longer decoded = FR-6/BC-9, plus delta 1 and delta 2). **No fourth.** The no-userinfo path agrees with HEAD for trojan/hy2/tuic (`""` either way); the empty-userinfo-with-`@` path likewise | ✅ no fourth found |
| Frozen set (`parse_vmess`, `_q`/`_b64dec`/`_name`/`_attach_*`, ss `:711-716`/`:718-725`/`:730`, host/port, `MASK`/`SECRET_KEYS`/`VISIBLE_IN_OUTBOUND`, `TRANSLATIONS`, composition layer, `cmd_add`/`load_nodes`/`save_nodes`, `install.sh`, READMEs, `.harness/**`) | Every one outside the hunks | ✅ |
| CL-8 placement, CL-9 dev-map row | `CHANGELOG.md:26` first under `### 修复` (newest-first at HEAD — inside CL-8's latitude, which fixes the section not the position); `docs/dev-map.md:35` names `_userinfo` ahead of the six parsers, `:48` carries the reusable-utility row with the last-`@` rule, the first-raw-colon rule, decode-once, the three-vs-two justification, the `p.username` prohibition **with its cause**, and the base64 arms / tag decodes that are deliberately not it | ✅ |
| NFR-3 permitted product diff = `bin/sc` + `CHANGELOG.md`; `docs/dev-map.md` a stage-4 duty outside it | This stage holds no shell, so `git status` was not run; mtime ordering is the substitute and is decisive: the only files in the repo modified after `03_RATIONALE.md` are `bin/sc`, `CHANGELOG.md`, `docs/dev-map.md`, then the stage-4 documents. `docs/batches/**`, `README.md`, `README.zh-CN.md`, `install.sh`, `uninstall.sh`, `systemd/**`, `.harness/**` and `docs/tasks.md` all predate stage 1. The `test/` tree in the worktree is `.gitignore`d and predates this task | ✅ |

## Axis status
- **Standards-conformance**: 3 findings (CR-3 MINOR, CR-4 NIT, CR-5 NIT, plus the schema record CR-6 NIT), worst = **MINOR**. No AI-GUIDE, `.harness/rules/*`, dev-map, naming, doc-size or cross-shell parity rule is violated; no rule was invented against the change.
- **Spec/design-fidelity**: 2 findings (CR-1 MINOR, CR-2 MINOR), worst = **MINOR**. Both are gaps in what the uncommitted harness *observes*, not in what the shipped code *does*: every FR, BC, I-n and K-n resolves in the shipped file, the design was implemented as approved with no added parameter, no new module and no re-opened shape, and no fourth behaviour delta exists.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | One `ss://` fixture with a `%` in its **plaintext** userinfo — `ss://a%3Ab:pw@h.example:8388` expecting `method` `a:b`, `password` `pw` — is the single instrument that observes BC-10's `%3A` half, BND-12's named divergence case for `parse_ss`, and K-8 delta 2. None exists today (CR-1). | `06_TEST_REPORT.md` |
| RES-2 | AC-3 / AC-4 must assert on `row["outbound"]` (the document written to `CFG_PATH` in that run) rather than `row["node"]`, and must assert `generated is True`, so FR-8 is observed through the document for shadowsocks, vless and vmess as it already is for tuic / trojan / hysteria2 (CR-2). | `06_TEST_REPORT.md` |
| RES-3 | BC-8 (`%FF` → U+FFFD, lossy, no exception) and BC-11 (no length cap) are unobserved by any fixture; the developer surfaced both. Neither is expressible as a credential-fidelity assertion, so QA should record them as reasoned non-assertions rather than silently drop them. | `06_TEST_REPORT.md` |
| RES-4 | V-8 / AC-15 was **not re-run at this stage** — the code-review stage holds no shell capability. The developer's PASS 17 · WARN 0 · FAIL 0 · SKIP 1 stands unaudited by a second party until QA's run, which is therefore the second independent execution, not the third. | `06_TEST_REPORT.md` |
| RES-5 | AC-13 is BLOCKED by construction and was not attempted; no artifact check was substituted. RT-1's operator row must be appended to `.harness/operator-obligations.md` at delivery. | PM → `07_DELIVERY.md` |
| RES-6 | AC-14 (`sing-box check`) is unrun and must be labelled **non-regression only** wherever it is reported — HEAD's defective document passes it too. | `06_TEST_REPORT.md` |
| RES-7 | **R-37**, tenth confirmation: `.harness/rules/70-doc-size.md` declares no `## Stage-doc boundary rule`, so this document's sweep transcript is placed by the reviewer schema's fallback rather than by the rule (CR-6). | T-27 |
| RES-8 | RT-2 (`rejected-decisions.md` record `share-url-userinfo-five-local-fixes`), RT-3 (`CONTEXT.md` glossary term **userinfo reading**) and RT-5 (the full harness listing **including its per-class fixture-construction block**, for T-28) are all still open and unaffected by this review. | RT-2/RT-3 → PM at delivery; RT-5 → QA → T-28 |

## Verdict
APPROVED
