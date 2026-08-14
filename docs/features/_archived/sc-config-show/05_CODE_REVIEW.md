> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

# T-06 — sc-config-show · Code Review

## Files reviewed

- `/home/alan/Programs/singbox-cli/bin/sc` (`:280-338` i18n, `:345-349` `_load_lang`, `:419-421` `t()`, `:504-509` `load_settings`, `:517-737` share-URL parsers, `:1780-1828` `_runtime_overlay`, `:1834-1927` drift quartet, `:2338-2360` `_plain`, `:2649-2779` the `# config` block, `:2943-2954` pre-existing `isatty` site, `:3188-3196` `HELP_EN`, `:3258-3266` `HELP_ZH`, `:3315-3386` `main()`)
- `/home/alan/Programs/singbox-cli/README.md` (`:280-299`, `:453` EOF)
- `/home/alan/Programs/singbox-cli/README.zh-CN.md` (`:280-299`, `:453` EOF)
- `/home/alan/Programs/singbox-cli/CHANGELOG.md` (`:1-8`)
- `/home/alan/Programs/singbox-cli/CONTEXT.md` (`:142-154`)
- `/home/alan/Programs/singbox-cli/docs/dev-map.md` (`:38`, `:40`, `:42`, `:65`, `:66`, `:154-156`)
- Upstream contracts read in full: `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`, `03_GATE_REVIEW.md`, `04_DEVELOPMENT.md`; `02_RATIONALE.md` consulted under trigger T5.3 (reuse correctness of `_config_digest()` / `_warn_drift()`).
- Rules read: `AI-GUIDE.md`, `.harness/rules/85-design-discipline.md`, `.harness/rules/70-doc-size.md` (confirmed: **no `## Stage-doc boundary rule` section** on this project — R-37 / Q-12 stands, the contract schema is applied as written and the task proceeds).
- Not reviewed, per instruction: `docs/batches/**`. `docs/tasks.md`'s working-tree change is PM ledger, outside the developer's declared file list.

There are **no test files in this repo** (`docs/dev-map.md:22` — "no build step, no dependency manifest and no test directory"). The verification artifacts are the V-1…V-14 harness runs recorded in `04_DEVELOPMENT.md`; those are transient fixtures, not committed code, so "read the tests" resolves to auditing the code each V-step claims to observe. That audit is what this document reports.

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | MINOR | Spec/design-fidelity | `docs/features/sc-config-show/04_DEVELOPMENT.md:58-60` | V-1's evidence for GC-1 states "10 masked positions == the 10 credential positions" but its own enumeration sums to **nine** — "uuid x3, password x4 incl. obfs.password, public_key, short_id". The correct enumeration for six schemes is uuid x3 (vless, vmess, tuic) + password x5 (trojan, ss, hy2, `hy2.obfs.password`, tuic) + public_key + short_id = 10, which V-2's independent "9 distinct synthesized credential values" corroborates (10 positions minus the tuic password, which never reaches disk — see CR-5). So the count 10 is right and "x4" is a transcription slip, but GC-1's discharge at stage 6 rests on exactly this identity. **Owner: developer** (document correction only; no code defect). QA must re-derive both counts from its own fixture rather than copy this line. |
| CR-2 | MINOR | Spec/design-fidelity | `bin/sc:2755-2768` | The `BrokenPipeError` guard (K-6, `:2769-2779`) wraps the stdout write and its flush only. The three-or-two stderr writes and `sys.stderr.flush()` at `:2755-2768` sit outside it, so `sc config 2>&1 \| head -1` — both streams into a short-reading pipe — can still raise `BrokenPipeError` out of `cmd_config()` and out of `main()`. BC-14 is worded for stdout alone (`sc config \| head -5`, which is fully handled), and K-6 places the guard exactly where the design put it, so **the code is faithful and the gap is upstream**. **Owner: architect** (design gap over BC-14's wording). Deliberately **not** a change to make inside T-06: widening the guard is machinery the design did not buy and `.harness/rules/85-design-discipline.md` § "Less is more" puts the burden of proof on it. Travels as RES-6. |
| CR-3 | NIT | Standards-conformance | `bin/sc:3195`, `bin/sc:3265` | The mask literal is spelled verbatim as `******` in five prose surfaces — both help rows, `README.md:293`, `README.zh-CN.md:293`, `CHANGELOG.md:7` — while every functional site interpolates `MASK` (`:2715`, `:2717`, `:2758`). This is **not** a K-2 / GC-8 violation: the spelling is identical everywhere, so there is one mask and one definition. But `MASK`'s comment (`:2661-2665`) carries no K-10-style "change this and you change those five" obligation the way `VISIBLE_IN_OUTBOUND`'s does (`:2671-2673`). **Owner: developer**, non-blocking; changing `MASK` is close to forbidden anyway (FR-5 fixed literal, A.1's 8-character threshold), which is why this is a NIT and not a MINOR. |
| CR-4 | NIT | Spec/design-fidelity | `bin/sc:2689-2691` | `SECRET_KEYS`'s six names do not include inbound TLS private-key material (`key`, `certificate`, `key_path`), which is the most likely *real* instance of the FR-9 limit both READMEs state — the same class as the READMEs' own `auth_token` example (`README.md:299`). `sc` never emits an inbound TLS key, so nothing shipped leaks; this is exactly the documented, gate-approved boundary of Q-5's "floor, not the guarantee". Recorded so the limit is a reviewed decision rather than an unexamined one. **Owner: requirement-analyst**, at pool intake if ever revisited; **no change requested in T-06**. |
| CR-5 | MINOR | Spec/design-fidelity | `bin/sc:712-717` | **Confirmed, not refuted.** `urllib.parse.urlparse().username` returns the userinfo up to the first `:`, so `":" in userinfo` at `:713` is unreachable-true for `tuic://uuid:password@host`, and every tuic outbound `sc` emits carries `"password": ""`. Pre-existing, unrelated to T-06, and the developer **correctly did not fix it** (out of scope 3 is silent on parsers, but the change is outside every C-row and would touch `# Share-URL parsers`, which C-1…C-11 do not name). Its effect on this task's verification is narrow but real: the tuic password is one of AC-B1/GC-1's ten masked positions yet cannot appear in AC-B2's leak search, because the value never reaches disk — that one position's masking is proved **structurally** (it is `password`, in `SECRET_KEYS`, `:2714-2715`) and not observationally. **Owner: pool intake (requirement-analyst)**; the defect is rated on its own row, not here. Travels as RES-4. |

No CRITICAL and no MAJOR finding. The four load-bearing guarantees were re-verified first-hand rather than accepted: the redactor was hand-traced against the four shapes that actually occur, `VISIBLE_IN_OUTBOUND` was re-derived from the emitting code rather than compared to a table, the one-stdout-write invariant was read as an invariant of the whole function body, and the frozen set was checked by line-offset arithmetic across the whole file (see `05_RATIONALE.md`).

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| FR-1 `sc config` bare subcommand, no flag, no positional | `bin/sc:3325` `sub.add_parser("config")`; `:3361` handler; `sc config <anything>` is argparse's own exit-2 usage error, no code | ✅ |
| FR-2 every invocation redacted, no opt-out | `:2770` is the **only** `sys.stdout.write` in `cmd_config()`; its argument is `json.dumps(_redact(doc, False), …)` with no branch, setting, env var or argument reaching it. Grepped: `_redact` has exactly one call site outside itself (`:2770`); `MASK` is referenced only at `:2715`, `:2717`, `:2758` | ✅ |
| FR-3 inside `outbounds`, at every depth, a key outside the visible key set has its whole value masked | `:2716-2717` (region rule) + `:2719` (`strict or k == "outbounds"`, never reset). Hand-traced against a T-15 `urltest` group whose `outbounds` is a list of tag strings, `transport.headers` with arbitrary keys plus `Host`, and `obfs.password` inside a visible `obfs` — all four render as FR-3 requires | ✅ |
| FR-4 six names masked document-wide, `outbounds` included | `:2689-2691` + `:2714-2715`, tested **before** the region rule. `experimental.clash_api.secret` at the root (where `strict` is `False`) is masked by this rule alone — traced | ✅ |
| FR-5 value replaced never the key; one fixed literal; any JSON type; structure preserved | `out[k] = MASK` at `:2715`/`:2717` keeps `k`; `MASK = "******"` (`:2660`) is the single literal, carrying nothing derived from the value; `json.dumps(..., indent=2, ensure_ascii=False)` re-emits a parseable document with the file's key order | ✅ |
| FR-6 document on stdout, commentary on stderr, path + masked-credentials + provenance | `:2755-2763`, then the single stdout write at `:2770`. Nothing else writes stdout in `cmd_config()`; no `print()` anywhere in the block | ✅ |
| FR-7 writes nothing, no socket, no subprocess, no Clash API, no validity verdict | `cmd_config()` / `_redact()` call none of `_init_files`, `_resolve_clash_port`, `generate_config`, `clash_api`, `is_running`, `subprocess.*`, `socket.*`, `urllib.*` — verified by reading both bodies end to end. `main():3352` keeps `config` off the initialising arm; `_load_lang()` (`:345-349`) reads and returns `"en"` on absence, writing nothing | ✅ |
| FR-8 exit 0 on a full print, non-zero otherwise; drift/absent record/unknown shape are not failures | `cmd_config()` returns `None` on success ⇒ `main()` returns ⇒ 0; every failure path is a `sys.exit(<sentence>)` (`:2738`, `:2743`, `:2750`, `:2753`) ⇒ 1; `:2769-2779` exits 1 on a broken pipe; the drift branches (`:2760-2763`) change no status | ✅ |
| FR-9 documented in `HELP_EN`/`HELP_ZH` + both READMEs, limit stated | `bin/sc:3193-3196`, `:3263-3266`; `README.md:280-299`, `README.zh-CN.md:280-299`; the limit is in the READMEs only, per GC-6 | ✅ |
| BC-1 file absent | `:2737-2738` `FileNotFoundError` → `no file at {path}`, stdout untouched | ✅ |
| BC-2 unreadable (EACCES, EIO) | `:2739-2744` `OSError` → `cannot read {path}: {e}` — a different sentence from BC-1's | ✅ |
| BC-3 not valid UTF-8 | same catch, via `ValueError` in the tuple; the comment at `:2740-2742` names why `except OSError` alone would let `UnicodeDecodeError` through | ✅ |
| BC-4 empty / valid UTF-8 that is not JSON; raw text not printed | `:2745-2751`; the `sys.exit` precedes every stdout write, and `:2748-2749` states why the raw text is withheld | ✅ |
| BC-5 parses but is not an object | `:2752-2754`, same frame with `the top level must be a JSON object` | ✅ |
| BC-6 `outbounds` absent or not an array | falls out of `_redact`'s totality: `:2708-2711`; a string at that key is returned unchanged, the rest of the document runs under FR-4 alone | ✅ |
| BC-7 a non-object element of `outbounds` | `:2710-2711` returns it unchanged inside the `:2709` list map | ✅ |
| BC-8 an outbound key `sc` never emits | `:2716-2717` — the fail-closed direction; verified against `override.json`-supplied names (`private_key`, `pre_shared_key`, an invented name), the first two also hit `SECRET_KEYS` | ✅ |
| BC-9 `transport.headers` with arbitrary keys | `Host` is in the set (`:2681`), every sibling key is masked at `:2717` — `strict` is already true two levels up | ✅ |
| BC-10 large document, no cap, no truncation | no size cap, no depth cap, no `sys.setrecursionlimit`, no `try` around `_redact` — verified by grep across `bin/sc` | ✅ |
| BC-11 `config.json` replaced mid-read | one `CFG_PATH.read_text()` at `:2736`; the atomic replace is `_write_private()`'s `os.replace` (`bin/sc:426-458`, frozen and untouched) | ✅ |
| BC-12 / BC-13 record absent, empty, unreadable, not a digest | `_drift_state()` `:1896-1905` returns `None` for `OSError`/`ValueError`, for empty-after-`.strip()`, and for an unavailable `_config_digest()`; `:2760-2763` writes no third line on `None` and leaves the status 0 | ✅ |
| BC-14 stdout closed early | `:2769-2779`, `os._exit(1)` — **not** `sys.exit(1)` — with the flush inside the `try` immediately after the write, exactly as D-3 directs | ✅ |
| BC-15 stdout not a TTY | no `isatty()` in the feature; the only `isatty()` in `bin/sc` is the pre-existing `:2946` in `cmd_update_rules` | ✅ |
| BC-16 a masked key holding a non-string value | `:2715`/`:2717` assign `MASK` before any type inspection, so `"password": 12345678` becomes the mask rather than being preserved or dropped | ✅ |
| AC-B1 real configuration rendered readably | carrier present (FR-1…FR-5 rows above); V-1 run by the developer. **GC-1's stronger form is QA's to discharge at stage 6** — see CR-1 | ✅ carrier |
| AC-B2 no fixture credential in either stream | carrier present; note CR-5 narrows the observation for one of the ten positions | ✅ carrier |
| AC-B3 override-added outbound, three unknown keys | `:2714-2717` covers all three (two by name, one by region) | ✅ |
| AC-B4 no config directory ⇒ non-zero, filesystem unchanged | `main():3352` + `:2737-2738`; GC-2's raiser-based proof is QA's record | ✅ carrier |
| AC-B5 / AC-B6 stream split and ordering | `:2755-2768` then `:2770`; `sys.stderr.flush()` is the last statement before the first stdout byte | ✅ |
| AC-B7 three provenance states | `:2759-2763` over `_drift_state()`'s three values | ✅ |
| AC-B8 `\| head -5` | `:2769-2779` | ✅ |
| AC-S1 four keys render in both languages, no new `失败：`, help + READMEs | `bin/sc:332-337` — all four keys present in `TRANSLATIONS["zh"]` with the placeholder sets their call sites pass (`{path}`, `{mask}`, none, none); `t()` is `msg.format(**kwargs) if kwargs else msg` (`:419-421`), so no call site can raise `KeyError`; the five **reused** keys are present at `:280`, `:281`, `:304`, `:307`, `:308` and D-1's mandatory `path=` is passed at every site (`:2738`, `:2743-2744`, `:2750`, `:2753`). No new zh string contains `失败` | ✅ |
| AC-S2 `verify_all` PASS, A.1 included | **Not re-run — this reviewer holds no shell.** A.1 was re-verified by inspection: `verify_all.sh:33`'s exact regex `(api[_-]?key\|secret\|password\|token)[[:space:]]*[:=][[:space:]]*["'][^"']{8,}["']` matches **nothing** in any non-`.md` file in the repo, comments and help text included. `MASK` is six characters, below the eight-character threshold | ✅ inspected |
| AC-B9 live host as root | expected BLOCKED; owner-run, QA files the row (R-31/R-41) | ⏸ QA |
| NFR-1 zero network I/O, zero subprocesses | no `socket`/`urllib`/`subprocess` reference on the `cmd_config` path; GC-5's V-10 report is QA's | ✅ carrier |
| NFR-2 no new file, one self-contained `bin/sc`, no new import | no file added; no import added — the block uses only `json`, `sys`, `os`, already imported | ✅ |
| NFR-3 no committed non-`.md` literal matching A.1 | see AC-S2 row | ✅ |
| NFR-4 synthesized credentials only in fixtures and documents | no credential-shaped literal in any stage document or in `bin/sc` | ✅ |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| C-1 block placed after `cmd_doctor`, before `cmd_mode` | `bin/sc:2649-2779`, `cmd_mode` at `:2782` | ✅ |
| C-2 `_drift_state()` extracted, `_warn_drift()` reduced to its renderer | `:1879-1905` / `:1908-1927`; `_warn_drift()` no longer reads `STATE_PATH` | ✅ |
| C-3 three wiring lines in `main()` + comment restated for two commands | `:3325`, `:3340-3352`, `:3361` | ✅ |
| C-4 four `TRANSLATIONS["zh"]` entries under one `# sc config` comment | `:330-337` | ✅ |
| C-5 `HELP_EN` / `HELP_ZH` rows immediately after `doctor` | `:3193-3196`, `:3263-3266`, column 30 / column 32, matching the neighbouring `doctor` row exactly | ✅ |
| C-6 / C-7 README sections, line-for-line mirrors at mirrored positions | both at `:280-299`, both files 453 lines, both followed by the ruleset-update section at `:301`; paragraph-for-paragraph correspondence verified | ✅ |
| C-8 one `### 新增` bullet at the head of `## [Unreleased]` | `CHANGELOG.md:7` | ✅ |
| C-9 four dev-map rows changed, one added | `:38`, `:40`, `:42`, `:65`, `:66`, plus the `:154` pattern bullet | ✅ |
| C-10 / GC-4 `CONTEXT.md` glossary | `:142-154`; see GC-4 row below | ✅ |
| I-1 `MASK = "******"`, six U+002A | `:2660` | ✅ |
| I-2 `VISIBLE_IN_OUTBOUND` — exactly the 34 names | `:2674-2683`. Compared **name by name** against I-2: 34 names, same 34, no typo, no omission, no extra. Independently re-derived from the emitting code (`:517-737` parsers, `:1796-1819` `_runtime_overlay`): every non-credential key name those sites emit is present, and `detour` is the single member no emitter produces | ✅ |
| I-3 `SECRET_KEYS` — six names, tested at every depth and **before** the region rule | `:2689-2691`, `:2714-2715`. The two sets are disjoint, so today the order changes no output; the order is nevertheless the one I-4 mandates, which is what keeps a future addition to `VISIBLE_IN_OUTBOUND` from exposing a credential | ✅ |
| I-4 `_redact(value, strict)` — pure, total, rules in the stated order, `strict` monotone | `:2694-2720`, four rules in I-4's order; builds new containers, mutates nothing; `strict or k == "outbounds"` at `:2719` is the only place `strict` changes and it can only rise | ✅ |
| I-5 `_drift_state()` → `True`/`False`/`None` | `:1879-1905`; digest from `_config_digest()` and nowhere else | ✅ |
| I-6 `cmd_config(args)` — one `read_text`, exactly one stdout write, non-zero on every failure | `:2723-2779` | ✅ |
| I-7 CLI surface bare, no flag, no positional | `:3325` | ✅ |
| I-8…I-11 four keys, exact strings, exact placeholders | `:332-337` against the design's strings — identical, both languages | ✅ |
| I-12 help rows: command, redaction guarantee, read-only guarantee, stream split | `:3193-3196` / `:3263-3266` | ✅ |
| I-13 `json.dumps(<redacted>, indent=2, ensure_ascii=False)` + one `"\n"`, written once | `:2770-2771` | ✅ |
| I-14 stderr order I-8, I-9, I-10/I-11, flushed before the first stdout byte | `:2755-2768` | ✅ |
| K-1 `if args.cmd in ("doctor", "config")`, no `READ_ONLY_COMMANDS`, default arm still initialising | `:3352`; the `else` arm at `:3354-3357` is unchanged and every other command — present and future — takes it. No new constant, no per-subcommand flag; `docs/dev-map.md:154-156` still reads as a prohibition and now says "its two read-only commands" | ✅ |
| K-2 one mask spelling | one definition, one spelling; see CR-3 for the prose duplication, which is the *same* spelling | ✅ |
| K-3 no `isatty()` in this feature | grep: the only occurrence in `bin/sc` is the pre-existing `:2946` | ✅ |
| K-4 `sys.stderr.flush()` before the first stdout byte | `:2768`, immediately before the `try` | ✅ |
| K-5 ordered catches onto the reused keys, with the stated placeholders | `:2735-2754`; `path=` passed at every site per D-1 | ✅ |
| K-6 single write + flush inside `except BrokenPipeError: os._exit(1)`, with the comment | `:2769-2779`; the flush is inside the `try`, immediately after the write (D-3); `os._exit(1)`, not `sys.exit(1)` | ✅ |
| K-7 exactly one `sys.stdout.write`, unconditionally through `_redact` | `:2770` — the only one in the function and the only `_redact` call site | ✅ |
| K-8 none of the forbidden calls, no validity verdict | verified by reading `cmd_config()` and `_redact()` in full | ✅ |
| K-9 no new file, no new import | ✅ |
| K-10 the obligation recorded in the constant's own comment | `:2671-2673` | ✅ |
| K-11 no A.1-matching literal in a non-`.md` file | see AC-S2 | ✅ |
| K-12 the limit in both READMEs, the two subsections line-for-line mirrors | `README.md:299` / `README.zh-CN.md:299`, inside mirrored `:280-299` sections | ✅ |
| K-13 no new zh string contains `失败：` | `:332-337` and the zh help rows `:3263-3266` — no `失败` at all | ✅ |
| K-14 `_warn_drift()`'s observable behaviour unchanged | `:1922-1927`: `if not _drift_state(): return` is false for both `False` and `None`, so the single `⚠️` line is written in exactly "record exists, non-empty, digest available, and the two differ" and nothing is written in every other case. The pre-edit body's catch tuple already included `ValueError` (`_archived/config-composition-layer/04_DEVELOPMENT.md:279`), so the non-UTF-8 record state is silent before **and** after — the one state where an extraction like this usually changes behaviour | ✅ |
| K-15 canonical vocabulary, no `_Avoid_` synonym | "visible key set" and "mask" used in the code comment (`:2667`), the help rows, both READMEs and `CONTEXT.md`; grep for `whitelist` / `censor` / `redaction placeholder` / `白名单` across the changed files: no hit | ✅ |
| GC-3 the drift **quartet** in **both** dev-map homes | `docs/dev-map.md:38` (`# Config generation` section row) **and** `:65` (`## Reusable utilities`, "Was config.json changed behind our back?"). Both name all four functions, both name `_drift_state()` as **the** judgement and `_warn_drift()` as its renderer. **Checked separately, not as one** | ✅ discharged |
| GC-4 `CONTEXT.md` states the `detour` exception in the same sentence that claims derivation | `CONTEXT.md:144-147`: "It is derived, not curated — every key name `sc` emits inside an outbound, minus the credential-bearing ones, **plus `detour`, sing-box's outbound-chaining key, which `sc` itself never emits** — so a key nobody enumerated is masked rather than printed." One sentence, exception included. Independently corroborated: `detour` is emitted by `sc` only at `bin/sc:1170`, inside a DNS server, never inside an outbound. No other glossary wording differs from the stage-2 C-10 block (see `05_RATIONALE.md` for the limits of this check) | ✅ discharged |
| GC-6 the FR-9 limit in the two READMEs **only**; help rows carry no override caveat; READMEs mirrored | Both help rows (`:3193-3196`, `:3263-3266`) state the command, the mask literal, the read-only guarantee and the stream split, and contain **no** occurrence of "override" / `override.json` in any form. The limit appears at `README.md:299` and `README.zh-CN.md:299` and nowhere else in the shipped surface. Both sections occupy `:280-299` in both files, both files end at line 453, and the following section (`### Ruleset update` / `### 规则集更新`) starts at `:301` in both | ✅ discharged |
| GC-8 (a) no second mask spelling | one `MASK` definition; every functional site interpolates it; the prose occurrences are the identical six characters (CR-3) | ✅ discharged |
| GC-8 (b) no second drift judgement | `_drift_state()` is the only one; `_warn_drift()` delegates (`:1922`); `cmd_config()` delegates (`:2759`); no digest comparison anywhere else | ✅ discharged |
| GC-8 (c) no second document reader | `CFG_PATH.read_text()` appears once in `cmd_config()` (`:2736`); the only other read of `CFG_PATH` on this path is the pre-existing `_config_digest()` (`:1846-1856`), which I-6 explicitly sanctions and which is frozen and unmodified | ✅ discharged |
| GC-8 (d) no `isatty()` call | see K-3 | ✅ discharged |
| GC-8 (e) no depth or size cap | no cap constant, no `sys.setrecursionlimit`, no `try` around `_redact`, no truncation of the dumped string — grep-verified | ✅ discharged |
| GC-8 (f) no change to `_load_lang()` / `load_settings()` | `:345-349` still catches `(FileNotFoundError, json.JSONDecodeError, OSError)` and **not** `ValueError`; `:504-505` is a bare `json.loads(SETTINGS_PATH.read_text())`. R-25/R-29 remain open exactly as out-of-scope 6 requires — the tempting one-word fix was **not** taken | ✅ discharged |
| GC-7 F-8 recorded as a residual, no code bought | `04_DEVELOPMENT.md:126-132` (RS-6); `CFG_PATH.read_text()` carries no `encoding=` and the dump carries none either, per D-6 | ✅ discharged (owner: stage 4/6) |
| Frozen set — `install.sh`, `uninstall.sh`, `systemd/**` | not in the developer's declared file list and not in the reported diff | ✅ untouched |
| Frozen set — `generate_config()`, `_compose()`, `_merge()`, `CONFIG_BASE`, the three overlays | unchanged; `generate_config()` at `:1930` is exactly its pre-edit self shifted by the additions above it, and `_warn_drift()`'s call at `:2003` is unchanged | ✅ untouched |
| Frozen set — `_write_private()`, `_record_generated()`, `_config_digest()`, `STATE_PATH` semantics | `:426`, `:1859-1876`, `:1834-1856` read unchanged; `_config_digest()` is **called** by `_drift_state()`, never edited | ✅ untouched |
| Frozen set — `cmd_doctor()` and the whole doctor block except `_plain()`'s call sites | the block occupies `:2321-2646`; its internal offsets are consistent with pure displacement by the +8 i18n and +22 drift additions above it, and `_plain()` is reused unchanged at four new call sites | ✅ untouched |
| Frozen set — `_load_lang()`, `load_settings()`, the five `ls.*` keys | see GC-8 (f); the `ls.*` keys are untouched | ✅ untouched |
| `.harness/rules/85-design-discipline.md` § "Less is more" — the code did not grow past the design | What shipped is exactly the design's inventory: two frozensets, one constant, one pure function, one command function, one extracted judgement, three wiring lines, four keys, two help rows. **No** added helper, **no** extra option, **no** defensive cap, **no** second spelling, **no** speculative seam. The one refactor (`_drift_state()`) names the future edit it prevents (T-20's doctor drift row) and removes a duplicated judgement rather than adding a parallel one | ✅ |

## Axis status

- **Standards-conformance: 1 finding, worst = NIT** (CR-3). Checked and clean: `.harness/rules/85-design-discipline.md` § "Less is more" (nothing grew past the design); `docs/dev-map.md`'s "Patterns to follow" (English sentence as translation key with a matching zh placeholder set; stdout results / stderr aggregates; no raw `\r` in non-TTY output — `json.dumps` escapes any CR inside a string value, so a hand-edited document cannot inject one; Python 3.6 syntax floor, stdlib only, no walrus, no new import); "Patterns to avoid" (no `READ_ONLY_COMMANDS`, no second opinion, `bin/sc` not split); `CLAUDE.md`'s output-language split (code, comments and stage docs English; README-zh and CHANGELOG Chinese); `.harness/rules/70-doc-size.md` caps (`04_DEVELOPMENT.md` 170 lines, well under 500 — and confirmed that this project's fragment defines **no** `## Stage-doc boundary rule`, so the contract schema applies as written per R-37/Q-12); naming and comment discipline consistent with the surrounding file (WHY-comments, no dead code, no premature abstraction); `CONTEXT.md`'s `_Avoid_` synonym lists respected. No invented rule was applied — every citation above is to AI-GUIDE, a `.harness/rules/*` fragment, `docs/dev-map.md`, or a numbered upstream item.
- **Spec/design-fidelity: 4 findings, worst = MINOR** (CR-1, CR-2, CR-4, CR-5). Every FR, every BC, every I-, K- and C-item has a named carrier that I read; GC-3, GC-4, GC-6 and GC-8 are each explicitly discharged above; GC-7 is confirmed recorded upstream. **GC-1 and GC-5 are QA's at stage 6 and are deliberately not discharged here** — nothing in the shipped code makes either unobservable: V-1's position-by-position comparison runs against a fixture the harness controls, and V-10's raiser sweep is unobstructed because `cmd_config()` reaches no network, subprocess or service symbol at all. The one caveat QA must carry into GC-1 is CR-1's arithmetic and CR-5's structurally-but-not-observationally-proved position.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-1 | RS-3 — `_drift_state()` runs after the document is read, so if `sc reload` completes in between, the provenance line may describe a newer inode than the document printed. The document is still whole (BC-11, `rename(2)`); both outcomes are non-alarming and no code was bought for it. | `06_TEST_REPORT.md` (stated, not tested) |
| RES-2 | RS-4 — `json.loads` keeps the last of duplicate keys, so a hand-edited `config.json` with a repeated key is shown without the earlier one. Accepted for the same reason BC-4 refuses to print unparseable text. | `06_TEST_REPORT.md` (disclosure) |
| RES-3 | RS-6 / GC-7 — neither the read nor the write names an encoding, so a `C`/`POSIX`-locale host at the 3.6 floor can report a valid non-ASCII-tagged document as unreadable, or die on the write. Repo-wide pre-existing class; no code bought here per D-6. | `06_TEST_REPORT.md` (restated per GC-7) |
| RES-4 | CR-5 — `parse_tuic()` never stores a tuic link's password (`urlparse().username` stops at the `:`, so `bin/sc:713`'s `if ":" in userinfo:` is unreachable-true and every tuic outbound carries `"password": ""`). Confirmed at code level, out of T-06's scope, correctly not fixed here. Its T-06 side effect: one of AC-B1/GC-1's ten masked positions cannot be leak-tested by AC-B2 because the value never reaches disk. | `07_DELIVERY.md` → a `docs/tasks.md` pool row; the AC-B2 caveat also to `06_TEST_REPORT.md` |
| RES-5 | A credential key whose value is the empty string still renders `******`, so an *unset* credential is indistinguishable from a set one. This is FR-5 as written and was a decision, not an accident. | `06_TEST_REPORT.md` (disclosure) |
| RES-6 | CR-2 — the `BrokenPipeError` guard covers the stdout write only; `sc config 2>&1 \| head -1` can still surface a Python-level error. BC-14 covers stdout alone and K-6 scopes the guard accordingly, so this is a design gap, not a code defect, and deliberately not fixed inside T-06. | `07_DELIVERY.md` → a `docs/tasks.md` pool row |
| RES-7 | CR-1 — GC-1's discharge rests on a masked-position count whose enumeration in `04_DEVELOPMENT.md` sums to 9 while stating 10. QA must re-derive both counts from its own fixture. | `06_TEST_REPORT.md` (GC-1 record) |
| RES-8 | RS-1 (four declined approaches → `.harness/rejected-decisions.md`), RS-2 (R-25/R-29 pool row), RS-5 (the stderr-line-buffering insight) are unchanged by the implementation and still travel as the design routed them. | PM at delivery (`07_DELIVERY.md`) |

## Verdict
APPROVED
