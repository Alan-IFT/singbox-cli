# 05 — Code Review · T-14 `config-composition-layer`

> Authored by the stage-5 code-reviewer agent. Transcribed verbatim by the PM Orchestrator because
> that agent's tool set is read-only (Read/Glob/Grep); no content was added, removed or altered.

Mode: **full** · Stage 5 · Decision authority: **deferred-human, defer-do-not-ask**. Upstream
verdicts confirmed: `01` READY, `02` READY, `03` APPROVED-with-8-conditions, `04` READY FOR REVIEW.
I audited the **working tree** against the pinned baseline
(`<scratch>/t14/sc_baseline.py`, the developer's own pre-edit copy — read directly, not trusted from
`04`). Nothing was executed; every claim below is from reading code.

---

## 1. Files reviewed

- `bin/sc` — imports (`:3-18`), `# Paths` (`:20-55`), `zh` table additions (`:237-262`),
  `_write_private` (`:351-400`), `_filter_rules` (`:855-883`), the whole `# Config composition`
  section (`:1014-1355`), the drift trio (`:1361-1432`), `generate_config()` (`:1435-1498`),
  `cmd_use`/`cmd_add`/`cmd_rm` (`:1597-1639`), `cmd_update_rules`' apply block (`:2125-2160`),
  `main()` (`:2412-2473`)
- `README.md` (`:184-252`) and `README.zh-CN.md` (`:184-252`)
- `docs/dev-map.md` (`:30`, `:37-38`, `:52-57`, `:74-76`, `:121-128`)
- `docs/tasks.md` (`:137-149`)
- Baseline oracle: `<scratch>/t14/sc_baseline.py:977-1092` (pre-change `generate_config()`)
- Test code: `<scratch>/t14/t14_diff.py`, `make_mutants.py` (the semantics harness was read only
  for its coverage claims; it is a throwaway per O-8/R-9 and is not part of the diff)

---

## 2. The claim that matters most — audited independently

### 2.1 The literal move is a pure text move. **CONFIRMED at code level.**

I walked `sc_baseline.py:1002-1069` against `bin/sc:1065-1128` line by line, not by diff summary.

| Emitted position | Baseline | `CONFIG_BASE` | Identical? |
|---|---|---|---|
| 1 `log` | `:1002` | `:1065` | yes |
| 2 `dns.servers` (4 entries, incl. the 6-key `predefined` map) | `:1004-1018` | `:1067-1081` | yes, incl. line-break placement |
| 3 `dns.rules` (8 entries) | `:1019-1029` | `:1082-1092` | yes |
| 4 `dns.final` / `dns.independent_cache` | `:1030-1031` | `:1093-1094` | yes, in that order |
| 5 `inbounds[0]` (7 keys, `interface_name: TUN_IFACE`) | `:1033-1037` | `:1096-1100` | yes |
| 6 `outbounds` | `:1038` expression | `:1101` `[]` | **hunk 2** |
| 7 `route.default_domain_resolver` / `auto_detect_interface` | `:1040-1041` | `:1103-1104` | yes |
| 8 `route.rules` (12 entries) | `:1042-1056` | `:1105-1119` | yes |
| 9 `route.rule_set` | `:1057-1061` comprehension | `:1120` `[]` | **hunk 3** |
| 10 `route.final` | `:1062` | `:1121` | yes |
| 11 `experimental.cache_file` | `:1065-1066` | `:1124-1125` | yes |
| 12 `experimental.clash_api.external_controller` | `:1067` f-string | `:1126` `""` | **hunk 4** |

No key, no nested key and no array element sits at a different index. Even the incidental
double-space in `{"outbound": "proxy",  "clash_mode": "Global"}` survives at `bin/sc:1110` and
`:1112`, and the `domain_suffix` five-element lists keep their wrap point. The name change
(`config = {` → `CONFIG_BASE = {`) is hunk 1. **Exactly four hunks; `04` §5's claim is accurate.**

### 2.2 The three placeholders can never be emitted. **CONFIRMED.**

`generate_config()` builds `overlays = [_runtime_overlay(nodes, active, report)]` unconditionally
(`bin/sc:1457`) — there is no branch, no early return and no exception path between that line and
`_compose` (`:1460`) on which the overlay is skipped. `_runtime_overlay` (`:1344-1355`) returns all
three keys unconditionally on every input: `outbounds` `$replace`, `route.rule_set` `$replace`,
`experimental.clash_api.external_controller` scalar. `_merge` reaches each of them because
`CONFIG_BASE` guarantees `outbounds` is a list (`:1101`), `route.rule_set` is a list (`:1120`) and
`clash_api` is a dict holding that key (`:1126`) — so the `$replace` arms take
`isinstance(target.get(key), list)` (`:1246`) and the scalar takes `:1260`. The empty
`route.rule_set` case is handled *after* composition by the pre-existing `del` (`:1477`), not by
leaving the placeholder. **No path emits a placeholder.**

### 2.3 `(node_tags or []) + ["direct"]` → `node_tags + ["direct"]`. **CONFIRMED equal; default not lost.**

`bin/sc:1336` `node_tags = [n["tag"] for n in nodes]` is always a list, so `or []` could only fire on
`[]`, and `[] + ["direct"] == ["direct"]`. `bin/sc:1340` is `"outbounds": node_tags + ["direct"]`.
The default is intact at `bin/sc:1341`: `"default": active or "direct"` — byte-for-byte the
baseline's `:997`. Selector key order (`type, tag, outbounds, default, interrupt_exist_connections`,
`:1337-1343`) matches baseline `:993-999`, and the array expression
`[selector] + nodes + [{"type": "direct", "tag": "direct"}]` (`:1346`) matches baseline `:1038`.

---

## 3. Design fidelity — the nine checks

**1 · Exactly one merge implementation (AC-6).** `_merge` is defined once (`bin/sc:1218`) and is the
only merger in the file; the repo has no other. `_compose` (`:1309-1319`) is
`deepcopy(CONFIG_BASE)` + a loop over `overlays`, so deleting the `_runtime_overlay(...)` element at
`:1457` leaves `_compose([override])` merging the user's document through the identical function.
The deletion test holds **structurally**, not just as a harness assertion. ✅

**2 · B-7/D-9 — no edge from `_apply_directive` back to `_merge`.** Verified by reading
`bin/sc:1190-1215` in full. `_apply_directive`'s only outbound call is `_anchor_index` (`:1204`);
it never calls `_merge` and never calls `_directive_of`. `_anchor_index` (`:1167-1187`) calls
nothing but `json.dumps` and `t`. Directive classification therefore happens in exactly one place
(`_directive_of`, called only from `_merge` at `:1232` and `:1240`, both on a value being merged
*into* the document). An inserted element is unreachable from the classifier. **§5.3's argument is
a real property of the call graph, not a documented intention.** ✅

**3 · Deep-copy discipline — hunted specifically. No hole found.** Every point at which an overlay
value enters the document:

| Site | Line | Copy |
|---|---|---|
| base → document | `:1316` | `copy.deepcopy(CONFIG_BASE)` |
| plain object at an absent/non-object key | `:1245` | `copy.deepcopy(value)` |
| bare array at an absent/non-list key | `:1258` | `copy.deepcopy(value)` |
| `$before`/`$after` payload | `:1207` | `copy.deepcopy(payload["values"])` |
| `$replace` | `:1212` | `copy.deepcopy(payload)` |
| `$prepend` | `:1214` | `copy.deepcopy(payload)` |
| `$append` | `:1215` | `copy.deepcopy(payload)` |
| scalar | `:1260` | immutable by construction (JSON scalars only) |

The `$before`/`$after` arm splices `current[:i]` and `current[i:]` — those elements come from the
already-deep-copied document, not from an overlay, so no alias is created there either. Consequences
verified: `CONFIG_BASE` is unreachable from anything `_filter_rules` (`:872`, `:880`) or the `del`
(`:1477`) mutates, and `nodes` reach `outbounds` only through the `$replace` deepcopy at `:1212`, so
BC-20/BC-21/AC-11 are structural. **R-5, the most dangerous class in this task, is closed.** ✅

**4 · `_write_private()` is the only writer of `config.json` (AC-10).** Repo-wide: the only
`CFG_PATH` write is `bin/sc:1486`; the other `CFG_PATH` uses are `open("rb")` (`:1375`, `:1831`),
`str()` into a subprocess argv (`:1493`, `:1844`), `.exists()` (`:2133`) and message interpolation.
`install.sh` never writes it (`install.sh:315` lists it for a mode sweep, `:530` for an argv). The
drift record goes through the same writer (`bin/sc:1401`), at `CRED_MODE` 0600, and holds 65 bytes
of hex — AC-25 by construction. ✅

**5 · `_filter_rules` (AC-8).** One definition (`bin/sc:855`), unchanged from the baseline, two call
sites (`:1479`, `:1480`), signature still `(rules, usable)` with no array-name parameter. `defined`
is computed at `:1475`, **two lines before** `del config["route"]["rule_set"]` at `:1477` — the
gate's explicit stage-5 item. ✅

**6 · Nothing written at import time or during `sc doctor` (BC-26/AC-26).** Module level in the new
section is a class, three constants, one dict literal and function definitions — no I/O.
`_init_files()` is still below `parse_args()` (`bin/sc:2433` → `:2443-2448`) and `doctor` still
takes the read-only arm. `cmd_doctor` (`:1999-2017`) calls none of `_load_override`, `_warn_drift`,
`_record_generated` or `generate_config`. ✅

**7 · Python 3.6 floor, stdlib only.** New imports are exactly `copy` (`:5`) and `stat` (`:11`); no
third-party import anywhere. No walrus, no `dataclasses`, no `unlink(missing_ok=)`, no f-string `=`
specifier. `capture_output=` appears at exactly three sites (`:1494`, `:1538`, `:2192`) — all
pre-existing, none added. f-strings, `stat.S_ISREG`, `copy.deepcopy` and `os.stat` are all 3.6. ✅

**8 · The 17 `t()` keys.** Counted in the `zh` table at `bin/sc:239-262`: 17 entries, matching `02`
§8 one for one. Placeholder sets are identical in every pair (`{path}{problem}`, `{path}{override}`,
`{err}`, ∅, ∅, `{err}`, ∅, `{n}`, `{at}{directives}`, `{at}{name}{directives}`, `{at}{name}` ×4,
`{at}{name}{count}{anchor}`, ∅, `{at}`). No `zh` value contains `失败：`. Every key is readable
English prose; no namespaced key. I folded each implicit string concatenation at the raise sites and
matched it against the table: `:1158-1159`→`:252`, `:1161-1162`→`:250`, `:1176-1177`→`:257`,
`:1182-1184`→`:259`, `:1199-1200`→`:257`, `:1202`/`:1209`→`:256`, `:1234-1235`→`:254`,
`:1250-1251`→`:254` (a *different* split of the same key — both fold identically), `:1255-1256`→
`:248`, `:1430-1431`→`:240`. **All 17 resolve; none is a call site naming an absent key.** Also
checked for format-injection: every user-derived fragment (`where`, `anchor`, OS `strerror`) is
passed as a `.format` **value**, never spliced into the format string, so a key containing `{` or
`}` cannot raise inside `t()` (`:344-346`). ✅

**9 · README parity.** Headings and code fences are at identical line numbers in both files
(`## 📂 File locations` / `## 📂 文件位置` at 184; the new `## 🛠 Custom configuration` /
`## 🛠 自定义配置` at 205; fences at 213/215, 233/246; `## 🗑 Uninstall` / `## 🗑 卸载` at 254;
`## 📄 License` / `## 📄 许可证` at 284). The two new file-locations rows are at `:193-194` in both.
Paragraph-for-paragraph the sections are the same content in the same order. ✅

---

## 4. The 8 gate conditions — discharge audited

| # | Condition | Audit |
|---|---|---|
| C-1 | No live-host action | `t14_diff.load_module` carries `assert os.geteuid() != 0` unweakened, restores `sys.modules["os"]` in a `finally`, and `repoint()` asserts all **seven** constants resolve inside a harness-owned root plus a second assert that no root is under `/etc`. `_init_files()` is never driven. `SB_BIN=/bin/true`. Nothing in the diff writes under `/etc`. ✅ |
| C-2 | Baseline from the working tree; clone not worktree | The baseline file exists and I read it; it is a pre-change `bin/sc` (its `generate_config` still holds the literal, `usable_tags(report)` and no `copy`/`stat` import), so it is the right oracle and not `/usr/local/bin/sc`. Clone-not-worktree is asserted in `04` §7 and is not verifiable from the tree — accepted on the record. ✅ |
| C-3 | Fixture freshness | **Deviation audited and sound.** `_runtime_overlay` emits `str(RULES_DIR / fname)` (`bin/sc:1349`) into `route.rule_set[].path`, and `RULES_DIR = root/"rules"`, so the fixture root name is *inside the compared bytes*; two `mkdtemp()` names would mismatch 100 % of runs. Reuse of the path string is therefore forced. The stale-state hole is closed: `wipe()` walks `Path.rglob("*")`, which on pathlib **does** return dotfiles, so `.config.sha256` is removed before both the baseline and the candidate run (`t14_diff.py` calls `wipe(); seed()` twice per point), and `02` §11 item 7's "only extra artifact" assertion is retained in `compare()`. No residue path found. ✅ |
| C-4 | AC-26 driven | Claimed in `04` §6/§7 with a byte-**and-mode** snapshot. Consistent with what I verified by inspection (§3.6). ✅ |
| C-5 | dev-map records the `TUN_IFACE` exception | `docs/dev-map.md:30` names all seven constants and states the exception explicitly, with the "repoint before loading, or not at all" instruction; `:128` repeats it inside the recipe. ✅ |
| C-6 | `{directives}` joined | `_directive_list()` (`bin/sc:1044-1046`) returns `", ".join(DIRECTIVES)` and is passed at `:1163` and `:1257` — the only two sites taking `directives=`. No tuple repr can reach a user. ✅ |
| C-7 | Newlines collapsed at the single render site | `bin/sc:2472-2473`: `sys.exit(_plain(t(...).replace("\n", " ")))`. Collapse first, one `_plain()` over the assembled sentence. `_plain` (`:1728`) strips `\r` and complete CSI sequences and `rstrip()`s but does not touch `\n` — which is exactly why the `.replace` is there and why it must stay. ✅ |
| C-8 | R-12 updated | `docs/tasks.md:143-149` names `generate_config()`'s `OverrideError` as the second unwind past `cmd_update_rules`' outcome block, records the ship-as-designed ruling and that the six-line stash was not required. Matches the real code: the raise at `:2139` lands before `restart_service()` at `:2146` and before the outcome block at `:2150-2157`. ✅ |

---

## 5. Scope discipline (rule 85, both edges)

**Zero content change — confirmed.** §2.1 establishes that the emitted document's content is
untouched. No urltest group, no DNS change, no telemetry list, no source profile, no timeout: the
only new emitted-value expressions in the file are the three that already existed
(`node_tags + ["direct"]`, the `rule_set` comprehension, `f"127.0.0.1:{CLASH_PORT}"`), relocated.
`RULESET_BASES` / `RULESET_FILES` / every timeout are byte-identical to the baseline.

**Permitted diff — one item to reconcile.** `bin/sc`, `README.md`, `README.zh-CN.md`,
`docs/dev-map.md`, `docs/tasks.md` are all in scope and all changed as described. `install.sh`,
`uninstall.sh` and `systemd/` are untouched. **However**, the git snapshot handed to this stage also
shows `M CHANGELOG.md`, which `04` §3 explicitly lists as *not touched* and which `04` §9's
`git diff --stat` omits. I read `CHANGELOG.md`: it contains **no** T-14 content (no `override`, no
`composition`, no `drift`, no `覆盖文件`), so it is not a scope breach by this task — but the
discrepancy should be reconciled before commit rather than carried into it. See observation O-3.

**Over-building — none found.** Every symbol in `# Config composition` has a named consumer:
`_merge`/`_directive_of`/`_apply_directive`/`_anchor_index` (all five directives are in `02` §16's
consumer table), `_compose`/`CONFIG_BASE` (T-15/T-16/T-17 + user), `_load_override`/`OVERRIDE_PATH`
(user), `_directive_list` (condition C-6), the drift trio (user + T-20), `_dig` (one caller —
gate F-10, permitted, and it has not grown a parameter or a mode). `usable_tags()` did not become
dead: it is still used at `bin/sc:2126`. No speculative directive, no multi-directive object, no
anchor list, no deletion directive, no `conf.d` machinery.

**Under-building — the vocabulary carries the named consumers.** T-16/T-17 both insert into
`dns.rules`; `{"dns": {"rules": {"$after": {"match": {"clash_mode": "Direct"}, "values": [...]}}}}`
does it, composes with a second such overlay at its own anchor, and needs no index arithmetic —
exactly D-7's case. T-15's urltest group reaches `outbounds` via `$before`/`$after` anchored on
`{"tag": "proxy"}`, applied after the run-time overlay. One boundary worth recording (not a defect,
and the gate pre-answered the analogous T-16 case in `03` §6 Q3): the vocabulary cannot **modify a
value nested inside an array element** — e.g. adding `28` to the selector's own `outbounds` list, or
to `query_type: [64, 65]`. T-15 would express its selector change by editing `_runtime_overlay`'s
`selector` dict (`bin/sc:1337-1343`), which is still composition and still not a literal inside
`generate_config()`, so the refactor's justification stands. Recorded so T-15 does not discover it
as a surprise.

---

## 6. Findings

Severity-rated. Nothing here is CRITICAL and nothing is MAJOR.

### CRITICAL
None.

### MAJOR
None.

### MINOR

- **[LOGIC] `bin/sc:864` (via `:1479-1480`) — one residual traceback path an override can reach.**
  `_filter_rules` calls `rule.get("rule_set")` on every element of `dns.rules` / `route.rules`. An
  override that inserts a **non-object** element — e.g.
  `{"dns": {"rules": {"$append": ["oops"]}}}` — passes the §6 shape assertion (`:1465-1467`; the
  array is still a list) and then raises `AttributeError` at `:864`, i.e. a Python traceback instead
  of the `OverrideError` sentence every other malformed-override case produces. The inconsistency is
  visible one line earlier: `:1475` *does* guard `route.rule_set`'s elements with
  `isinstance(d, dict)`, while the two rule arrays get no equivalent guard — which reads as an
  oversight rather than a decision. **Not an AC violation**: the shape is outside BC-8…BC-14's
  enumeration, O-9 excludes schema validation, and the crash still occurs before `_write_private`,
  so `config.json` is untouched, the service is untouched and the exit is non-zero. But it is
  precisely the class `02` §6's shape assertion exists to close ("a sentence rather than a Python
  traceback"). **Recommendation: do not fix inside T-14** — the natural fixes touch `_filter_rules`,
  which AC-8 pins, or widen §6 past its stated three paths. **Owner: requirement-analyst** — record
  it as a new open row in `docs/tasks.md` alongside R-4, naming the two arrays and the guard
  asymmetry, so the next task that touches this seam owns it.

- **[DOC] `README.md:207` and `README.zh-CN.md:207` — the list of regenerating commands is wrong for
  two of six.** Both files state that `sc reload`, `sc use`, `sc add`, `sc rm`, `sc mode` and
  `sc update-rules` "all rewrite it from scratch". `cmd_mode` (`bin/sc:2020-2029`) **never**
  regenerates — it persists the mode and PATCHes the Clash API, which `01` §5 states explicitly as
  the fact that makes AC-1's closure finite. `cmd_use` (`bin/sc:1597-1607`) regenerates **only** when
  the hot-apply arm fails (service down, or the Clash API PUT returns `None`). The paragraph's
  practical point (a hand-edit to `config.json` will be discarded) survives, and the two files remain
  a line-for-line mirror of each other, so AC-29/B-17 are unaffected. **Owner: developer** — one
  clause in each file, at the same line number, keeping the mirror intact.

### NIT

- **[MSG] `bin/sc:1232-1236`** — a directive at the override's **root** is reported with key 12
  ("`{name}` can only be applied to an array that already exists") rather than a message saying a
  directive is not allowed at the top level. Truthful (the top level is not an array) but indirect.
- **[MSG] `bin/sc:1154-1159`** — two directives in one object are reported with key 11 ("cannot be
  combined with **other keys** in the same object"). The developer recorded this as judgment call 2
  in `04` §8 and it avoids an 18th key; the wording is a shade off for that shape. Noted only.
- **[SEC] `bin/sc:1280` → `:1288`** — `os.stat` by path, then `open` by path: a TOCTOU window in
  which the target could become a FIFO between the two, in which case `open` would block. Not
  reachable by an unprivileged user (`/etc/sing-box` is root-owned and not world-writable; R-11
  already owns the directory-mode question and O-5 re-homes override permissions to T-20), so there
  is no real hole. The docstring's claim that the ordering "stops a device or fifo at that path
  hanging the CLI **forever**" is very slightly stronger than what the code guarantees.

---

## 7. Requirement coverage check

Structure, override semantics, drift and bilingual criteria. AC-1…AC-4, AC-11, AC-12 and the
override/drift *runtime* criteria are execution evidence recorded in `04` §4–§6; what I verify here
is that the code can satisfy them and that the mechanism named exists.

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 byte-identical output | `CONFIG_BASE` `bin/sc:1064-1128` verified position-by-position vs baseline `:1002-1069`; `_runtime_overlay:1344-1355` writes only pre-existing keys | ✅ (mechanism verified at code level; 148 runs recorded in `04` §5) |
| AC-2 oracle = pre-change source | baseline file read directly; it is a pre-change `bin/sc`, not `/usr/local/bin/sc` | ✅ |
| AC-3 streams + return value | `t14_diff.run()` captures stderr via `redirect_stderr`, compares `rv`, `stderr`, `config`, `nodes` in `en` and `zh` | ✅ (see O-1) |
| AC-4 non-vacuity | three mutants incl. a pure key **reorder** (M2), all FAIL; `make_mutants.py` read | ✅ |
| AC-5 no literal in the function | `generate_config` `:1435-1498` contains no configuration literal | ✅ |
| AC-6 one merge, deletion test | `_merge:1218` sole definition; `_compose:1309` loop | ✅ |
| AC-7 single self-contained file | no new file; `install.sh` untouched | ✅ |
| AC-8 `_filter_rules` unchanged | `:855-883`, call sites `:1479-1480`, no new parameter | ✅ |
| AC-9 observable ordering | compose → filter → `_warn_degraded:1481` → write `:1486` → `check :1493`; `_warn_drift:1482` is an addition, not a reordering | ✅ |
| AC-10 sole writer | `:1486`; repo-wide search clean | ✅ |
| AC-11 repeated calls | `deepcopy` at `:1316` + full copy-in discipline | ✅ |
| AC-12 `nodes.json` unchanged | nodes enter only via `$replace` deepcopy `:1212` | ✅ |
| AC-13 object deep-merge | `_merge:1239-1245` | ✅ |
| AC-14 `$replace` | `:1211-1212` | ✅ |
| AC-15 `$prepend`/`$append` | `:1213-1215` | ✅ |
| AC-16 anchored insertion | `_anchor_index:1167-1187`, `:1204-1207` | ✅ |
| AC-17 two overlays compose | `_compose` loops; each `_apply_directive` re-matches against the current array | ✅ |
| AC-18 inserted value verbatim | no edge `_apply_directive` → `_directive_of` (§3.2) | ✅ |
| AC-19 bare array rules | `:1253-1258` (error naming directives / accept at absent key) | ✅ |
| AC-20 error cases | all raises precede `:1486`; `main:2461-2473` exits 1 naming path + problem | ✅ (see MINOR-1 for the one non-enumerated shape) |
| AC-21 no service action | `restart_service` reachable only from `reload_or_restart:1507-1511` after `generate_config` returns | ✅ |
| AC-22 drift before replace | `_warn_drift:1482` precedes `:1486`; message names both paths (`:1429-1432`) | ✅ |
| AC-23 silent when unchanged | `:1427` | ✅ |
| AC-24 absent record silent + created | `:1420-1425` returns silently; `_record_generated:1491` | ✅ |
| AC-25 no second credential copy | digest only, via `_write_private` at `CRED_MODE` (`:1401`) | ✅ |
| AC-26 doctor writes nothing | `cmd_doctor:1999-2017` touches no new artifact; `_init_files` still below `parse_args` | ✅ |
| AC-27 `zh` parity, no `失败：` | `:237-262`, 17/17 | ✅ |
| AC-28 prose keys, no namespacing | `:239-262` | ✅ |
| AC-29 both READMEs | mirrored at identical line numbers | ✅ (content nit: MINOR-2) |
| AC-30 `verify_all` no new FAIL | `04` §9: 16/1/0/1 before and after; the WARN is F.6, pre-existing | ✅ |

Boundary conditions spot-checked and satisfied: BC-1 (`active or "direct"` `:1341`), BC-3 (rewrite
still before the document, `:1452-1455`), BC-4 (`ensure_ascii=False` `:1486`), BC-7/T-1
(`if not text.strip(): return None` `:1298`, and nothing wider — `"[]"`, `"null"`, `"0"`, `"{"` all
fall through to `:1301-1305`), BC-9 (`stat.S_ISREG` before any `open`, `:1285`), BC-16/BC-17
(`:1420-1427`), BC-22 (no trailing newline), BC-23 (insertion order preserved; no `OrderedDict`).

---

## 8. Design fidelity check

| Design item (`02`) | Implementation | Status |
|---|---|---|
| §4 `OVERRIDE_PATH` / `STATE_PATH` in `# Paths` | `bin/sc:30`, `:36` | ✅ |
| §4 new section between `# Rule-sets` and `# Config generation` | `:1014` | ✅ |
| §4 two new stdlib imports, `copy` + `stat` | `:5`, `:11` | ✅ |
| §5.1 `CONFIG_BASE` as a module-level dict literal, deep-copied per call | `:1064`, `:1316` | ✅ |
| §5.2 `_runtime_overlay` as designed | `:1322-1355` | ✅ |
| §5.3 `_merge` classification table | `:1237-1260` — all seven rows implemented as tabulated | ✅ |
| §5.3 directive table incl. `{match, values}` | `:1190-1215` | ✅ |
| §5.4 `_load_override` step order | `:1279-1306` — stat, S_ISREG, capped read, decode, strip, parse, isinstance | ✅ |
| §5.5 `_compose` | `:1309-1319` | ✅ |
| §5.6 drift trio, digest of the file on disk | `:1361-1432` | ✅ |
| §5.7 `_dig` | `:1131-1138`, one caller | ✅ (F-10 permitted) |
| §6 `generate_config` body and ordering | `:1435-1498`, step for step | ✅ |
| §6 A-7 `defined` before the `del` | `:1475` then `:1477` | ✅ (gate RULED IN) |
| §7 single render site, `sys.exit`, `_plain` once | `:2459-2473` | ✅ |
| §8 the 17 keys | `:237-262` | ✅ |
| §9 README section + 2 table rows | `:193-194`, `:205-252` both files | ✅ |
| §14 T-1 / T-2 / T-3 as ruled | `:1298`; parse at `:1440` before `:1452-1455`; unwind past `:2150` documented in `docs/tasks.md:143-149` | ✅ |
| §10 R-4 **not** fixed | `bin/sc:383` `os.fdopen(fd, "w")`, still no `encoding=` | ✅ correctly unfixed and re-homed (`04` §11.1) |
| Elaborations beyond `02` | `_directive_list()` (C-6) and `(OSError, ValueError)` in `_warn_drift:1422` | ✅ both justified in `04` §8; neither changes an interface or an emitted byte |

**Design drift: none.** `04` §10's claim holds against the code.

---

## 9. Non-blocking observations for QA

- **O-1 · `t14_diff.compare()` only inspects `res[0]`.** On the `calls=3` point, calls 2 and 3 are
  compared for `config` bytes only (`t14_diff.py`, the AC-11 block); their captured **stderr** is
  never compared against anything. A spurious drift line on a repeat call would be invisible to the
  differential. Not a defect today — after call 1 the record matches the file on disk, so
  `_warn_drift` provably returns at `bin/sc:1427` — but QA should compare stderr across all three
  calls rather than inherit the gap.
- **O-2 · The 148 AC-1 runs never exercise a non-silent `_warn_drift`.** Correctly so (the baseline
  cannot emit it, and `wipe()` clears `.config.sha256` before every candidate run), but it means the
  drift statement's *content* rests entirely on the semantics harness. QA should re-derive AC-22/
  AC-23/AC-24 independently rather than re-run `t14_semantics.py`.
- **O-3 · `CHANGELOG.md` shows as modified** in this stage's git snapshot while `04` §3 lists it as
  not touched and `04` §9's `--stat` omits it. It contains no T-14 content, so it is not a T-14
  scope breach — reconcile (stash, commit separately, or confirm the snapshot is stale) before the
  delivery commit. Also `?? docs/features/sc-doctor/` appears in the snapshot but resolves to
  nothing on disk; likewise stale.
- **O-4 · The `bin/sc` language trap `04` §8.6 found is worth inheriting.** Any test driving
  `main()` must set `lang` in the fixture's `settings.json`, not just `sc.LANG`, because `main()`
  reassigns `LANG` from `_load_lang()` (`bin/sc:2444`/`:2447`). A harness that sets only `sc.LANG`
  renders English on every `main()`-driven path and makes Chinese assertions vacuous.
- **O-5 · The vocabulary boundary in §5** (no way to modify a value nested inside an array element)
  is a fact T-15 and T-16 should carry into their own design stages.
- **O-6 · Doc size.** `04_DEVELOPMENT.md` is over rule 70's 500-line cap, as `01` and `02` already
  are. Flagged by the developer, predicted by the gate, F.6 is WARN-only and clears on
  `archive-task`. No new FAIL. Not a finding.

---

## 10. Axis status

- **Standards-conformance:** 1 finding, worst = **MINOR** (README command list, `README.md:207` /
  `README.zh-CN.md:207`), plus 2 NIT message-wording items. Repo conventions are otherwise met:
  the `# Paths` contract is re-documented rather than silently broken (`docs/dev-map.md:30`), the
  `⚠️  ` + `t()` + `\n` warning shape is reused verbatim, `_plain()` is applied once at one site,
  no `en` table was invented, no namespaced key was added, both READMEs stay a line-for-line mirror,
  and no rule not present in `AI-GUIDE.md` / `.harness/rules/*` / `docs/dev-map.md` was applied here.
- **Spec/design-fidelity:** 1 finding, worst = **MINOR** (the `_filter_rules` traceback path,
  `bin/sc:864`), plus 1 NIT. All 30 acceptance criteria are covered, `02` §§4–9 are implemented
  element for element, and I found **no** design drift — including on the three items the PM singled
  out (deep-copy discipline, the absent `_apply_directive` → `_merge` edge, and `defined` computed
  before the `del`).

Neither axis carries an unaddressed CRITICAL or MAJOR. Aggregate = **MINOR**.

---

## 11. Verdict

**APPROVED** — 0 CRITICAL, 0 MAJOR, 2 MINOR, 3 NIT.

The central claim survives an independent code-level walk: the literal move is genuinely pure, no
placeholder is reachable, the `node_tags` simplification is equal for every input and the `active or
"direct"` default is intact. The three properties that would have been expensive to discover later —
deep-copy discipline, the missing call-graph edge that makes B-7 structural, and `defined` computed
before the deletion — are all real in the code, not just in the prose.

Routing for the two MINOR findings (both are follow-ups, neither blocks the merge):

1. **[LOGIC] `bin/sc:864`** — a new open row in `docs/tasks.md` naming the two rule arrays and the
   `isinstance` guard asymmetry with `:1475`. **Owner: requirement-analyst.** Do **not** fix inside
   T-14: every fix touches `_filter_rules` (pinned by AC-8) or widens `02` §6 past its stated three
   paths, and either would be an unreviewable change inside a byte-identity gate.
2. **[DOC] `README.md:207` / `README.zh-CN.md:207`** — correct the regenerating-command list
   (`sc mode` never regenerates; `sc use` only on the fallback arm), one clause per file, at the same
   line number so the mirror is preserved. **Owner: developer.** May be folded into the delivery
   commit or deferred to the CHANGELOG pass at the PM's discretion.

---

## 12. Stage 5′ — delta review (BC-27 / AC-31)

> Also authored by the stage-5 code-reviewer agent and transcribed verbatim by the PM Orchestrator,
> for the same read-only tool-set reason.

Scope: the stage-4″ fix only (`04` §17). My stage-5 findings and the **APPROVED** verdict in §11
stand unchanged. Nothing was executed; every claim is from reading `bin/sc` at the current working
tree.

### 12.1 The delta is exactly what was declared — proven by line arithmetic, not by trust

Every anchor I cited in §1–§8 has moved by exactly one of two constants, which is only possible if
`bin/sc` gained lines at exactly two points and lost none anywhere:

| Anchor | §5 line | now | Δ |
|---|---|---|---|
| `_filter_rules` / `CONFIG_BASE` / `_dig` / `_merge` | 855 / 1064 / 1131 / 1218 | 857 / 1066 / 1133 / 1220 | **+2** (the `zh` pair) |
| `_compose` / `_runtime_overlay` / drift trio / `generate_config` / `main` | 1309 / 1322 / 1361 / 1435 / 2412 | 1328 / 1341 / 1380 / 1454 / 2431 | **+19** |

+2 = the `zh` entry (`:245-246`). +19 = that pair plus **17** lines inside `_load_override`
(`:1280-1284` a docstring paragraph, `:1289-1300` the arm: 9 comment lines, `if`, `raise` over two
lines). Uniform shifts on both sides of the insertion points ⇒ no other line in the file was added
or removed. `_filter_rules` (`:857-885`), `_merge`'s classification table, `CONFIG_BASE`,
`generate_config()` (`:1454-1517`) and the drift trio read identically to what §2–§3 recorded.
`README.md` / `README.zh-CN.md` / `docs/dev-map.md` carry no delta content (the `docs/tasks.md`
change is the analyst's R-15/R-16 rows, `:162-184`, not the developer's). **Scope: clean.**

### 12.2 The seven mandate checks

**1 · AC-31 clause 2 — the AC-1 regression risk. VERIFIED SAFE.** `bin/sc:1288-1301`: the
`except FileNotFoundError:` arm's only added statement is `if os.path.islink(...)` guarding a
`raise`; `return None` (`:1301`) is otherwise reached unchanged. No `sys.stderr` write, no return
value change, no state touched. On a path with no entry the cost is one extra `lstat` (NFR-5
immaterial). Byte-identity for the whole task is intact.

**2 · `os.path.islink` cannot raise and cannot mis-classify. CONFIRMED, and the developer's
"property of the primitive" claim is accurate.** `posixpath.islink` is `os.lstat` wrapped in
`except (OSError, ValueError, AttributeError): return False` on the 3.6 floor: it never propagates,
never follows, and is `False` both for a genuinely absent entry and for a missing/dangling **parent**
component (the parent's `lstat` raises `ENOENT` → swallowed). BC-27's final-component-only boundary
therefore needs no second test.

**3 · `realpath` vs `readlink`. Choice CORRECT; one clause of the rationale is overstated (NIT-A).**
`readlink` does return only the immediate target — for a chain it would name a link, not the missing
file — so `realpath` is the right call, and it is correctly used **without** `strict=` (3.10+, would
be a `TypeError` on the floor); non-strict is the default and it returns the unresolvable prefix
rather than raising. See NIT-A for the "cannot raise" half.

**4 · A raise inside an `except` block. No chaining artifact reaches the user.** The new
`OverrideError` propagates out of `_load_override` → `generate_config` (`:1459`), and every
`generate_config()` call site is inside `main()`'s dispatch (`:1527` via `reload_or_restart`, `:2158`
in `cmd_update_rules`; both handlers are called at `:2479` inside the `try`). The single handler
(`:2480-2492`) renders `sys.exit(_plain(t("Cannot use {path}: {problem}", …).replace("\n", " ")))`,
so `__context__` is never formatted — a `SystemExit` carrying a string prints that string and exits
1. **The new raise reaches the one render site and only it.**

**5 · D-14 intact.** `os.stat` (`:1287`) still follows the link, so a symlink to a regular file
never enters the amended arm at all; `S_ISREG` (`:1304`) still judges the target and the document is
read and applied. Not narrowed by one byte.

**6 · BC-9's FIFO guard untouched.** `os.stat` `:1287` → `S_ISREG` `:1304` → first `open` `:1307`.
Same statements, same order, shifted only. The discrimination happens entirely inside the stat's
failure arm, before any `open()`, exactly as `01` §12.3 item 1 requires.

**7 · The new `t()` key. CONFORMS.** Key `"a symbolic link whose target {target} does not exist"`
(`:1299`) ↔ `zh` `"是一个符号链接，但其目标 {target} 不存在"` (`:245-246`). Identical placeholder set
`{target}`; readable English prose; not namespaced; **no `失败`** in the `zh` value; it reads
correctly after both `Cannot use {path}: ` and `无法使用 {path}：`, matching its siblings
(`not a regular file`, `cannot be read ({err})`). The embedded path is passed as a `.format`
**value**, never spliced into the format string, so `{`/`}` in a filename cannot raise inside `t()`;
and a filename containing `\n` — legal on Linux — is collapsed by the `.replace("\n", " ")` at the
single render site *before* `_plain()`, so the one-physical-line contract (NFR-7) holds. The `zh`
table now holds **18** T-14 keys, all still parity-checked.

### 12.3 Design fidelity — the declared drift

**Correctly handled, citation accurate.** `02_SOLUTION_DESIGN.md:246` still reads
`os.stat(OVERRIDE_PATH) FileNotFoundError -> None (absent)`, and `:261`'s D-14 sentence still
stands (and is still true of the code). `04` §17.2 declares this as requirement-driven drift and
leaves `02` unedited, citing `.harness/rules/00-core.md:44` ("Downstream cannot edit upstream
documents") — the rule exists and says that; `01` §12.3 items 1–4 are the analyst's own ruling that
no design change is required. Recording the deviation in `04` is the standing mechanism, and this
review is the site that checks it. The error channel `02` §5.4 designs gains a ninth member and no
step order, interface or data structure moves. **No undeclared drift.**

### 12.4 Findings (delta only)

#### CRITICAL — none. MAJOR — none. MINOR — none.

#### NIT

- **[DOC] `04` §17.1 — "`realpath` … cannot raise" is true from 3.10, not on the documented 3.6
  floor.** In CPython ≤ 3.9 `posixpath._joinrealpath` calls `os.readlink(newpath)` **unguarded**
  after `islink(newpath)` returned `True`; the try/except rewrite landed in 3.10. So `realpath`
  carries the same nanosecond TOCTOU window the developer used to reject `readlink`, and an `OSError`
  there would escape `main()`'s `OverrideError`-only handler as a traceback. This is the *identical*
  class as §6's accepted `[SEC]` NIT (`os.stat` then `open` by path) and needs the same premise to
  fire — a concurrent mutation of a root-owned, non-world-writable directory — so it is not a defect
  in the code, and `realpath` remains the right choice on the surviving half of the argument (chain
  resolution, which `readlink` genuinely cannot do). Only the record's absolute wording is wrong.
- **[DOC] `04` §17.1 — the added-line count understates the delta.** "one `zh` entry … and four
  comment lines" vs the measured **17** added lines: a 4-line docstring paragraph plus a blank
  (`:1280-1284`), 9 comment lines and 3 code lines in the arm (`:1289-1300`). Every added line is a
  comment, a docstring or the declared `if`/`raise`, and the cited range `:1281-1301` does contain
  them all, so nothing is hidden — the count is simply off, and a delta review that trusted the
  number instead of the file would have mis-scoped its read.

#### Observation (no severity)

- **`ENOTDIR` parent flavour.** BC-27 says "a missing or broken parent directory component remains
  absent". The code delivers that for the two shapes the developer tested (no parent, dangling parent
  link — `os.stat` raises `FileNotFoundError`, `islink` is `False`, silent `None`). A parent that is
  a *regular file* raises `NotADirectoryError` instead, lands in the untouched `except OSError` arm
  (`:1302`) and becomes malformed — `Cannot use …: cannot be read (Not a directory)`. Pre-existing,
  unchanged by this delta, fail-safe in direction (loud + no write, never a silent discard), and it
  still satisfies AC-31's operative clause (path + specific problem, exit 1). Recorded so no one
  later reads it as a BC-27 regression.

### 12.5 Not re-litigated — confirmed still open and correctly filed

- **R-15** — `_filter_rules` still does `rule.get("rule_set")` with no `isinstance` guard
  (`bin/sc:866`), so my §6 MINOR-1 (`AttributeError`) is unfixed; `06` MINOR-A (`RecursionError`) is
  likewise unfixed. Both are carried as one row at `docs/tasks.md:167-176`, with the explicit
  instruction not to fix by touching `_filter_rules` (AC-8) or widening `02` §6.
- **R-16** — the bare-object-replaces-array mirror is unfixed and filed at `docs/tasks.md:177-184`.

Both rows name their owner and their reason. No reopening.

### 12.6 Axis status (delta)

- **Standards-conformance:** 2 NIT, both `[DOC]` against `04` §17.1's own prose; worst = **NIT**.
  Code-side conventions are met — one `t()` key pair with matching placeholders and no `失败`, prose
  key, no namespacing, the single render site and single `_plain()` preserved, the `os.stat`-before-
  `open` contract and the `docs/dev-map.md` path list untouched, no rule invented that is not in
  `AI-GUIDE.md` / `.harness/rules/*`.
- **Spec/design-fidelity:** **no findings.** BC-27 is implemented at the one arm it governs, AC-31
  clause 1 (malformed → abort before any write, exit 1, message naming path *and* target) and clause
  2 (no entry → silent `None`, AC-1 unharmed) both hold structurally, D-14 and BC-9 are intact, and
  the single `02` §5.4 divergence is declared, correctly reasoned and correctly cited.

Neither axis carries a CRITICAL or a MAJOR. Aggregate = **NIT**.

### 12.7 Delta verdict

**APPROVED** — 0 CRITICAL, 0 MAJOR, 0 MINOR, 2 NIT (both documentation wording in `04` §17.1;
neither blocks, neither needs a re-run of any gate). No owner is routed.
