# 02 — Solution Design · T-24 `override-error-envelope`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

One `try` region inside `generate_config()` spans the override's bytes to the emitted
document's bytes, and every exception leaving it becomes one already-rendered
`OverrideError` through the existing single arm — the load keeps its own second arm because
its provenance is unconditional.

`_merge()`'s per-key loop is re-derived so that a key whose current value is a list has
exactly **one** admissible overlay value, a directive object, and every other shape reaches
the sentence that already exists — a branch is deleted, none is added.

Nothing else moves: `_filter_rules()`, `_apply_directive()`, `_directive_of()`,
`_load_override()`'s body, `CONFIG_BASE`, `_write_private()`, the `sing-box check` block and
`main()`'s rendering arm are all untouched, and no new function, class, file or module exists.

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| E1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_unusable()` docstring (`:541-545`) generalised from "a state document's failure" to "an unusable document's failure" — the function body is unchanged and it becomes the single construction site for every path-carrying `OverrideError` (BC-6). +1/−1 | single dev |
| E2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `TRANSLATIONS["zh"]`, inside the config-composition block guarded by the `失败` comment at `:345-346`, immediately after `"at {at}: this must stay an array"` (`:373`): one new key/value pair. +2/−0 | single dev |
| E3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_merge()` (`:1434-1476`) — the per-key loop `:1453-1476` re-derived around the target's current type instead of the overlay value's type, plus the docstring paragraph `:1441-1446` restated. Serves FR-3, AC-5, AC-6. +26/−28 | single dev |
| E4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `generate_config()`'s load wrapper (`:2036-2040`) gains a second arm for non-`OverrideError` exceptions, with unconditional `OVERRIDE_PATH`. Serves FR-2 (M0), Q-8. +3/−0 | single dev |
| E5 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `generate_config()` — the envelope: one `try` from `:2069` through a hoisted `text = json.dumps(config, indent=2, ensure_ascii=False)`, two arms, and `_write_private(CFG_PATH, text)` at `:2104`. Serves FR-1, FR-2, BC-11. +46/−33, of which +32/−32 is re-indentation of unchanged statements | single dev |
| E6 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | The composed-document array assertion (`:2081-2085`) constructs through `_unusable()` and gates its **path label** on `override is not None`. Serves FR-4, AC-7, R-26. +2/−3 | single dev |
| E7 | `/home/alan/Programs/singbox-cli/README.md` | edit | One new paragraph after `:398`, inside `## 🛠 Custom configuration (override.json)`, stating FR-3's rule. +2/−0 | single dev |
| E8 | `/home/alan/Programs/singbox-cli/README.zh-CN.md` | edit | The same paragraph in Chinese, after `:398`, at the identical line number. +2/−0 | single dev |
| E9 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | One bullet as the first entry under `### 修复` (`:24-26`). +2/−0 | single dev |
| E10 | `/home/alan/Programs/singbox-cli/CONTEXT.md` | edit | Glossary term **document envelope** added to `## Language`. **Written at stage 2 by the architect** — not part of stage 4's diff. +7/−0 | stage 2 (done) |
| E11 | `/home/alan/Programs/singbox-cli/docs/features/override-error-envelope/02_RATIONALE.md` | new | Reuse audit, risk table, the measurement claims and the option narratives. Written at stage 2. | stage 2 (done) |
| — | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | **not edited** | `:38` publishes the claim that all three user-document sites set `OVERRIDE_PATH` by call structure; E6 makes that claim true, so no text changes. `:63`'s R-16 parenthetical is a PM-owned re-homed row (`01_RATIONALE.md` §"Re-homed findings" item 2), not this task's. | — |

**Per-edit size table** (the derivation for `## Constraints` K-16):

| edit | added | removed | of which mechanical re-indent |
|---|---|---|---|
| E1 | 1 | 1 | 0 |
| E2 | 2 | 0 | 0 |
| E3 | 26 | 28 | 0 |
| E4 | 3 | 0 | 0 |
| E5 | 46 | 33 | 32 / 32 |
| E6 | 2 | 3 | 0 |
| `bin/sc` subtotal | **80** | **65** | 32 / 32 |
| E7 + E8 + E9 | 6 | 0 | 0 |
| product total | **86** | **65** | 32 / 32 |

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `bin/sc` `_unusable` | `_unusable(path, problem) -> OverrideError` — signature, body and return-not-raise contract all unchanged | THE single construction site of a path-carrying `OverrideError`, for every unusable document: the two state documents, the composed-document assertion and the envelope. If `OverrideError` is ever renamed or re-parented, this is the one line that moves (BC-6). |
| I-2 | `bin/sc` `_merge` | `_merge(target, overlay, at="") -> None` — signature unchanged, in-place semantics unchanged | A key whose current value in `target` is a `list` is assigned from exactly one expression, `_apply_directive(...)`; every other overlay shape at that key raises `"at {at}: an existing array must be changed with one of {directives}"`. A key whose current value is not a list keeps today's behaviour statement for statement. |
| I-3 | `bin/sc` `_merge`, deep-copy site | `elif isinstance(value, (dict, list)): target[key] = copy.deepcopy(value)` replaces the two separate copy branches at `:1461` and `:1474` | After E3, `_merge` holds exactly **one** un-copied assignment (`target[key] = value`) and it is reachable only when `value` is neither `dict` nor `list`; every overlay-contributed container still reaches the document through `copy.deepcopy` (`:1423`, `:1428`, `:1430`, `:1431`, the merged branch, `_compose`'s `:1550`). |
| I-4 | `bin/sc` `generate_config` | `generate_config() -> bool` — signature and both `False` returns unchanged | Out of the enveloped region only `OverrideError` (and `BaseException`, e.g. `KeyboardInterrupt`) can propagate. A write failure and a `sing-box check` failure keep their existing stderr line + `return False`, because both sit **outside** the region. |
| I-5 | `bin/sc` translation key | `"no configuration could be produced from it ({fault})"` → `"无法据此生成配置（{fault}）"` (one entry, in the block at `:345-373`) | The only new key in this task. One placeholder, `{fault}`, present in both languages; no `失败：`; unnamespaced prose; the English key renders verbatim in English (BC-10). |
| I-6 | rendered line, override present | `Cannot use /etc/sing-box/override.json: no configuration could be produced from it (RecursionError)` — one line, via `main()`'s existing arm at `:3713-3715`, exit status 1 | Names the override path (FR-1), carries a fault clause that identifies the fault class (BC-11), is not the invoking command's generic outcome line, and contains no value taken from the override document (BC-4). |
| I-7 | rendered line, no override present | `Cannot use /etc/sing-box/config.json: at dns.rules: this must stay an array` | Provenance is decided by `override is not None`, never by the exception's class (FR-4, AC-7). The assertion still executes on the override-less path, so this stays the assertion's own sentence rather than the envelope's. |
| I-8 | `README.md` / `README.zh-CN.md` heading | `## 🛠 Custom configuration (override.json)` / `## 🛠 自定义配置（override.json）`, new paragraph after the `$before`/`$after` paragraph at `:398` and before the `Example —` / `示例 ——` block at `:400` | Both files gain the same number of lines at the same line numbers, so their heading / fence / table / blank-line structure still matches line for line (AC-11). |
| I-9 | `README.md` new sentence | `A key whose current value is an array therefore accepts **only** a directive object: an object, a scalar, `null` or a bare array written there is an error naming the five directives, never a silent replacement. To empty an array, use `$replace` with `[]`.` | States FR-3's rule in the section that already documents the directives. |
| I-10 | `README.zh-CN.md` new sentence | `因此，当前值是数组的那个键**只接受指令对象**：在那里写对象、标量、`null` 或裸数组都会报错并列出这五个指令，绝不会静默替换。要清空一个数组，请用 `$replace` 配 `[]`。` | The same statement, same relative position, one line. |

## Constraints

**K-1** — The developer opens the envelope's `try` at `generate_config()`'s `if override is not None:` (`bin/sc:2069`) and closes it immediately after a hoisted `text = json.dumps(config, indent=2, ensure_ascii=False)`; `config = _compose([...])` (`:2067-2068`) stays **above** it and `_write_private` / `_record_generated()` / the `sing-box check` block stay **below** it.

**K-2** — The developer writes the envelope's two arms in this order: `except OverrideError:` + a bare `raise` (an explicit pass-through, required because `OverrideError` is a direct `Exception` subclass), then `except Exception as e:` raising `_unusable(OVERRIDE_PATH if override is not None else None, t("no configuration could be produced from it ({fault})", fault=type(e).__name__))` with `from None`.

**K-3** — The developer adds the same second arm to the load wrapper at `:2036-2040` with an **unconditional** `OVERRIDE_PATH`, because every exception escaping `_load_override()` arises after the file was confirmed to exist, be regular and be non-empty.

**K-4** — The developer names the fault with `type(e).__name__` and nothing else: never `str(e)`, never `repr(e)`, never `e.args`, never `traceback` output (BC-4 — an exception's own message can embed a value the document supplied).

**K-5** — The developer leaves the inner `try/except OverrideError: e.path = OVERRIDE_PATH; raise` around `_merge(config, override)` (`:2070-2074`) exactly as it is, and the outer `except OverrideError:` arm assigns `e.path` for no exception and under no condition.

**K-6** — The developer makes `_apply_directive(...)` the only expression `_merge` assigns to a key whose current value is a `list`, and evaluates `_directive_of(value, where)` at exactly the positions and the count it is evaluated at today (once per `dict`-valued overlay key, before any test on `target`).

**K-7** — The developer leaves `_merge` with exactly one assignment that is not deep-copied, guarded so it is unreachable when `value` is a `dict` or a `list`.

**K-8** — The developer adds no function, no class, no module, no file, no `sys.setrecursionlimit` call, and no depth, node or size cap anywhere (NFR-2, BC-8, out-of-scope 2).

**K-9** — The developer adds exactly one translation key, I-5, and no other user-facing string (NFR-1 permits two; this design spends one).

**K-10** — The developer inserts I-9 and I-10 at the identical line number in both READMEs and changes no other line of either file (AC-11).

**K-11** — The developer keeps the envelope's re-indentation behaviour-free: `git diff -w` restricted to `generate_config()` must show only the envelope's own added lines, the assertion's two-line replacement and the `json.dumps` hoist.

**K-12** — The developer writes the `CHANGELOG.md` bullet in Chinese under `### 修复`, and it must state: the seven malformed shapes; that each now ends as one line naming `override.json` and a non-zero exit; that `config.json` and the drift record are left byte-identical; that an array-valued key accepts only a directive object; and that a valid override's emitted document is unchanged.

**K-13** — The developer gates the **path label** of the composed-document assertion on `override is not None` and leaves the `for at in (...)` loop itself running unconditionally, so the no-override case keeps the assertion's own sentence instead of degrading to the envelope's (out-of-scope 4: the assertion is not widened, and it is not narrowed out of the no-override path either).

**K-14** — The developer leaves `_filter_rules()` (`:1056-…`) and both call sites' argument lists (`:2097-2098`) byte-identical (AC-8).

**K-15** — The developer never narrows `main()`'s `except OverrideError` arm (`:3700-3715`) back to the user's override: it renders `e.path or CFG_PATH` and serves 16 unguarded state-document call sites through `_read_state`.

**K-16** — The developer keeps the product diff at or under **+86 / −65 across `bin/sc`, `README.md`, `README.zh-CN.md` and `CHANGELOG.md`**, with a tolerance of +6 / −6 for wrapping; the number is the sum of the per-edit size table above, and 32 added / 32 removed of it is mechanical re-indentation. A larger diff is a design defect to be reported, not absorbed.

## Smaller alternative rejected

### The smaller design, in full

**S — three point fixes plus E3 and E6, no envelope.** Written against the shipped file:

- **S1** (`bin/sc:1536`) — `except ValueError as e:` becomes `except (ValueError, RecursionError) as e:`. M0 then renders through the existing `"not valid JSON ({err})"`. **1 word changed, 0 lines added.**
- **S2** (`bin/sc:2070-2074`) — after the existing `except OverrideError` arm add
  `except RecursionError:` → `raise _unusable(OVERRIDE_PATH, t(<a fault sentence>)) from None`. Covers M1. **+3.**
- **S3** — E3 unchanged: the `_merge` loop re-derivation. Covers M4, M5, M6, M7 and keeps M-none of the rest. **+26/−28.**
- **S4** (`bin/sc:2097-2098`) — wrap the two `_filter_rules` calls in
  `try: … except (AttributeError, TypeError):` → the same `_unusable` raise. Covers M2, M3. **+4, with a 2-line re-indent.**
- **S5** — E6 unchanged: the provenance label gate. **+2/−3.**
- Both READMEs and `CHANGELOG.md` identical to this design.

**Size: `bin/sc` ≈ +36 / −31 against this design's +80 / −65.** It adds no `except Exception`
anywhere, needs no 32-line re-indent, and adds one translation key or zero (S1 reuses the
existing JSON sentence; S2 and S4 can share one new key).

### What S does satisfy — stated without shading

S satisfies **FR-1** for every member of BC-1, **FR-3** in full (same edit), **FR-4** in full
(same edit), **FR-5** (it does not touch the override-less path except through E6, which is
label-only), **FR-6**, and **every one of BC-1 … BC-14**: one line, non-zero exit, no write, no
service action, no cap, no new class, no `_apply_directive → _merge` edge, key parity, and the
`_filter_rules` freeze.

It also satisfies, by construction, **every acceptance criterion this task carries** — AC-1
through AC-15, including AC-2's four clauses for each of M0…M7, AC-3's adversarial build, AC-5's
same-sentence clause, AC-7's provenance, and AC-12's README promise. **19 of the 21 binding
units (6 FR + 15 AC) are satisfied by S.** It is not a strawman: it is the shape the task's
symptom list literally asks for, and it would pass the whole criteria set as written.

### What the extra code buys

**FR-2, and only FR-2 — but FR-2 is a totality claim that no enumeration can discharge.**
FR-2 does not say "M0…M7 are handled"; it says *"A failure **anywhere in that region** satisfies
FR-1"*, over a region that runs arbitrary user JSON through `_merge`, `_dig`, a `set()`
comprehension, `_filter_rules` and `json.dumps`. S covers five points in that region and names
four exception classes. Two holes are constructible **today**, on the shipped file, with no
future change:

- **M8** — `{"route": {"rule_set": {"$append": [{"tag": ["a"]}]}}}`. A legal directive, at a
  legal array position, whose inserted element is copied verbatim (BC-7 forbids interpreting
  it). At `:2093` `set(d.get("tag") …)` raises `TypeError: unhashable type: 'list'`, outside
  S4's two wrapped lines. **Traceback, and a broken `config.json` is not written only because
  the traceback aborts first.**
- **M9** — `json.dumps(config, indent=2, …)` at `:2104` uses CPython's **pure-Python** encoder
  (`c_make_encoder` is bypassed whenever `indent` is not `None`), whose `yield from` chain costs
  frames per level much as `copy.deepcopy` does. A document in the band where the merge's copy
  survives and the encoder does not is a `RecursionError` outside every arm S adds.

Neither is in BC-1, so neither is measured by AC-2 — which is exactly why S passes every AC and
still fails the requirement. That gap is the 修修补补 shape rule 85 forbids: BC-1 is a symptom
list, FR-2 is the abstraction behind it, and a design shaped like BC-1 is code shaped like the
bug report.

Second purchase, smaller but real: **BC-11's reportability.** S's `except RecursionError` and
`except (AttributeError, TypeError)` are a leaf enumeration, and this repository has already
paid for that shape twice with evidence — `.harness/rejected-decisions.md`
§`clash-api-bare-except-and-leaf-enumeration` records R-20 filing four leaves, stage 4 measuring
a fifth and stage 6 a sixth. That record also declined `except Exception` for `clash_api()`, and
its own stated distinction is the one that applies here: *"`cmd_doctor` itself does use
`except Exception` and is right to: a **driver** isolating unknown probe code can enumerate
nothing, while a four-statement body can."* The enveloped region is a driver over unknown
**data**, not a four-statement body; and the reason `except Exception` was wrong in
`clash_api()` — that sc would assert the host is broken when sc is broken — is answered here by
Q-9/BC-11, which require the fault clause precisely so an internal defect stays reportable.

Rule 85's tie-break settles ties **between designs that satisfy the same requirement**. S and
this design do not satisfy the same requirement, so the tie-break does not reach them — the same
adjudication the gate made at T-22 (`.harness/rejected-decisions.md`
§`share-url-userinfo-five-local-fixes`).

### The nearer alternative — this design minus its least-justified part

The least-justified part is **E4, the load's second arm (+3 lines)**. Removing it and taking S1
instead — widening `_load_override`'s existing `except ValueError` at `:1536` to
`except (ValueError, RecursionError)` — is genuinely 3 lines smaller, deletes nothing else
(so the count does not move back), and arguably renders *better prose*, because M0 would then
read `not valid JSON (maximum recursion depth exceeded …)` rather than a bare class name.

**It is refuted by its own provenance.** M0 exists *because* `:1536`'s enumeration was written as
`ValueError` and CPython's scanner signals depth exhaustion with `RecursionError`, which is not
one. Repairing that site by appending the class that escaped is the identical act that produced
the defect, one class later; and the enumeration would still be open in both directions
(`MemoryError` on a 1 MiB pathological document, and whatever a future decode or parse path
raises). E4's `except Exception` closes the site as a *region*, which is what FR-2 asks for at
the load exactly as it asks at the merge — and Q-8 is explicit that an envelope scoped to the
merge alone leaves M0 a traceback.

Two further "nearer" candidates, both checked and both **larger**:

- Keeping the assertion's three inline construction lines instead of routing E6 through
  `_unusable()`: that is +1 line, not −1, and it leaves three construction sites for a
  path-carrying `OverrideError` where BC-6 wants one.
- Dropping the `json.dumps` hoist (−2 lines): it re-opens M9 and puts a step whose input is
  override-supplied content outside the region FR-2 defines, for two lines.

Also declined **as larger**: extracting the enveloped region into a new
`_emitted_json(override, nodes, active, report)` helper to avoid the 32-line re-indent. It moves
the same lines rather than deleting them, adds a four-argument interface and a name, and forces
`_warn_degraded()` / `_warn_drift()` to move relative to the document they describe. Rule 85's
counter-rule asks which future edit it prevents; none is nameable.

## Requirement coverage

| unit | satisfied by | note |
|---|---|---|
| FR-1 | E4, E5 (+ existing `main()` arm) | rendering is reused, not rebuilt |
| FR-2 | E4 (load) + E5 (merge → serialisation) | the region, not a point list |
| FR-3 | E3 | one sentence for object / scalar / `null` / bare array |
| FR-4 | E6 | label gated on `override is not None` |
| FR-5 | E3 + E6 only touch paths an override reaches; verification only | AC-1 |
| FR-6 | E7, E8 | the standing promise at `:378` needs no edit — E3/E5 make it true |
| BC-1 M0 | E4 | `RecursionError` inside `json.loads` |
| BC-1 M1 | E5 | `RecursionError` inside `_merge`'s `copy.deepcopy` |
| BC-1 M2, M3 | E5 | `AttributeError` inside `_filter_rules`, caught at the region |
| BC-1 M4, M7 | E3 | object / index-like object at an array key |
| BC-1 M5, M6 | E3 | scalar / `null` at an array key |
| BC-2 | structural: every BC-1 abort point precedes `_write_private` (`:2103`); verification only | AC-2 (iv) |
| BC-3 | structural: every BC-1 abort point also precedes `_warn_degraded` (`:2099`) and `_warn_drift` (`:2100`), so no second line can be emitted; `main()`'s arm collapses `\n` | AC-2 (i) |
| BC-4 | K-4 | `type(e).__name__` only |
| BC-5 | no edit — `_write_private` and `_record_generated` are frozen | AC-2 (iv) |
| BC-6 | E1, K-15 | `_unusable()` becomes the one construction site; the arm is never narrowed |
| BC-7 | E3 under K-6; `_apply_directive` byte-identical | AC-9 |
| BC-8 | K-8 | no limit change, no cap |
| BC-9 | E3 admits every published recipe (all use directives at array positions) | AC-4 |
| BC-10 | E2 under K-9 | AC-10 |
| BC-11 | E4, E5 under K-4 | the fault clause is the reportability |
| BC-12 | binds the harness, not the product; verification only | AC-14 |
| BC-13 | binds the harness; verification only | AC-2 (ii) in zh |
| BC-14 | verification only | AC-15 |
| AC-1 | verification only — E3 is the only edit on the override-less emission path, and no sc overlay puts a non-directive value at an array key (`_runtime_overlay` `$replace`s `outbounds` and `route.rule_set`, `_dns_overlay` `$prepend`s `dns.rules`, `_telemetry_overlay` `$before`s or returns `{}`) | V-1 |
| AC-2 | E3, E4, E5, E6 | V-2 |
| AC-3 | E5's region ends before `_write_private`; verification only | V-3 |
| AC-4 | E3; verification only | V-4 |
| AC-5 | E3 — all four shapes reach one `raise` | V-5 |
| AC-6 | E3 — the existing sentence and its trigger are a subset of the new rule | V-5 |
| AC-7 | E6 (assertion arm), **not** E5 — see RS-1 | V-6 |
| AC-8 | K-14 | V-7 |
| AC-9 | K-6 | V-7 |
| AC-10 | E2, K-9 | V-8 |
| AC-11 | E7, E8, K-10 | V-9 |
| AC-12 | E3 + E4 + E5 | V-2 |
| AC-13 | verification only | V-10 |
| AC-14 | verification only | V-11 |
| AC-15 | BLOCKED by construction — filed as an operator obligation | V-12 |
| NFR-1 | K-9 (one key, cap is two) | V-8 |
| NFR-2 | K-8, change ledger | V-7 |
| NFR-3 | K-16 + the per-edit size table | V-13 |

## Frozen set

| path | why frozen |
|---|---|
| `bin/sc` `_filter_rules()` and both call-site argument lists (`:1056-…`, `:2097-2098`) | T-14 AC-8 / out-of-scope 3 — body, signature and arguments byte-identical |
| `bin/sc` `_apply_directive()` (`:1406-1431`) | BC-7 / AC-9 — it must gain no callee, and its four `copy.deepcopy` sites are T-14's verified discipline |
| `bin/sc` `_directive_of()` (`:1357-1380`) and `_anchor_index()` (`:1383-1403`) | The one directive recognition site; `_anchor_index`'s anchor echo is a PM-owned re-homed row, not this task's |
| `bin/sc` `_load_override()` body (`:1479-1540`) | R-69's five policies survive only because the reader is untouched; E4 wraps the **call**, not the body |
| `bin/sc` `OverrideError` class and its `path` attribute (`:1223-1242`) | BC-6 — not renamed, not re-parented, no subclass, no taxonomy |
| `bin/sc` `main()`'s `except OverrideError` arm (`:3698-3715`) | BC-6 / K-15 — 16 unguarded state-document call sites depend on `e.path or CFG_PATH` |
| `bin/sc` `_write_private()` (`:474-…`), `_record_generated()`, the `sing-box check` block (`:2103-2116`) | BC-5, and Q-8's rejection of candidate (c): their failures have correct, tested renderings |
| `bin/sc` `CONFIG_BASE` (`:1277-1344`) | Key order is emission order; AC-1 byte-identity rests on it |
| `bin/sc` `OVERRIDE_MAX_BYTES`, `DIRECTIVES` (`:1250-1254`) | Out-of-scope 2 and Q-3 — no new cap, no fourth rule, no sixth directive |
| `bin/sc` `_redact()` and the `# config` block | Out-of-scope 6 — the masking walk gains no envelope and no cap (R-44 stays open) |
| `install.sh`, `uninstall.sh`, `systemd/*`, `.harness/**`, `.claude/**` | NFR-2 — outside the product diff |
| `docs/features/override-error-envelope/01_REQUIREMENT_ANALYSIS.md` | Upstream contract; a defect there is reported, never patched here |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | E1, E2 | none — E1 is a docstring, E2 an unreferenced table entry; both are inert until E4/E5 land | revert the two hunks; no behaviour to restore |
| 2 | E3 | none | revert the loop hunk; the pre-change loop is recoverable verbatim from `bin/sc:1453-1476` at `HEAD` |
| 3 | E4 | E2 present, or the `t()` call renders the key verbatim in both languages | revert the arm; M0 returns to a traceback |
| 4 | E5 | E2 and E4 present; E1's generalised docstring present so `_unusable` reads honestly at its new caller | revert the whole `try` block **and** the `json.dumps` hoist together; a half-reverted hoist leaves `text` undefined |
| 5 | E6 | **E5 must already be in the same working tree** — Q-4: the label gate alone is safe under this design, but shipping it without the envelope leaves M0…M3 as tracebacks and AC-7's control comparison meaningless | revert to `failure.path = OVERRIDE_PATH`; the pre-change three-line form is at `:2083-2085` |
| 6 | E7, E8 | E3 in the tree — the READMEs must not state a rule the code does not yet enforce | revert both files in one hunk pair, or AC-11 parity breaks |
| 7 | E9 | E1…E8 all in the tree | revert the bullet |

No data migration: no file format changes, no on-disk shape changes, no setting is added or read, and `config.json` / `nodes.json` / `settings.json` / `.config.sha256` keep their current contents and encodings. No feature flag: the change is a failure-path contract, and a flag would be a second opinion about whether a document is usable. Backwards compatibility is the whole of AC-4 and AC-1 — every override that produces a `sing-box check`-accepted document today produces the identical bytes after.

**One deliberate behaviour change beyond the malformed set**, recorded here because it is not in BC-1: a `ValueError` raised by `json.dumps` itself (circular reference; unreachable, since every value in the document came from `json.loads` or a literal) would previously have rendered as `"Could not write {path}: {err}"` + `return False` and will now render as an unusable-document sentence + non-zero exit. `_write_private`'s own `OSError`/`ValueError` — including the `UnicodeEncodeError` from a lone surrogate, which is raised at the encode inside `_write_private` and not by `json.dumps` — is unaffected.

## Out of scope

This design does not cover the object position: an overlay scalar or array replacing an object stays today's silent replacement (out-of-scope 5, Q-3).
This design does not envelope `cmd_config`'s masking walk, and adds no cap there or anywhere (out-of-scope 6, R-44 stays open).
This design does not collapse `_load_override()` and `_read_state()` into one reader (out-of-scope 7, R-69's five policies).
This design does not add the missing run-level outcome line to `sc update-rules`, and it widens that line's absent population (out-of-scope 8, Q-6, R-12).
This design does not reorder any side effect relative to an abort: `nodes.json`'s stale-selection repair still precedes a merge-time failure, and `sc add` still persists before generating (out-of-scope 9).
This design does not add a command, a setting, a file under `/etc/sing-box`, a schema, a validator, an exception hierarchy or an error taxonomy (out-of-scope 1 and 10, NFR-2).
This design does not change the drift record's ordering relative to `sing-box check`; a document that reaches disk and then fails the check is still baselined (a PM-owned re-homed row).
This design does not fix `_anchor_index`'s echo of user JSON into the captured stream (a PM-owned re-homed row; BC-4 binds only sentences this task introduces or newly reaches).
This design does not repair `t()`'s missing `en` table; the new key renders verbatim in English by design, and T-25 owns the fix (BC-10).

## Verification plan

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | T-14's byte-identity harness over the settings × rule-set state matrix, pre-change source vs candidate, whole emitted tree, plus its non-vacuity control (a deliberately perturbed build must report *different*) | every emitted file byte-identical; every stream empty where it was empty; the control run reports a difference | AC-1, FR-5 |
| V-2 | Per-member fixtures M0…M7 through `generate_config()` with `CFG_PATH` / `OVERRIDE_PATH` / `NODES_PATH` / `SETTINGS_PATH` / `RULES_DIR` repointed and `_init_files()` neutralised; combined stdout+stderr captured; `config.json` and `.config.sha256` digested before and after | exactly one line; the line contains the override path and a fault clause; non-zero exit; both files byte-identical; control on the pre-change source shows a traceback (M0–M3) or a written document (M4–M7) | AC-2, AC-12 |
| V-3 | The adversarial build of AC-3 (catch everything, emit anyway) run against V-2 | it fails V-2 clause (iv) | AC-3 |
| V-4 | Each override recipe published in both READMEs, plus one directive of each of the five names, emitted and compared byte-for-byte against the pre-change source; control: a recipe whose effect is removed must show as different | identical bytes per recipe; control differs | AC-4, BC-9 |
| V-5 | M4, M5, M6, M7 rendered lines compared for string equality modulo the dotted position; each of `$prepend`, `$append`, `$replace`, `$before`, `$after` tested for membership in the sentence; T-14's bare-array-over-array fixture re-run against the pre-change string | one sentence for all four; five names present; the T-14 fixture's line unchanged in text and trigger | AC-5, AC-6 |
| V-6 | No override present; one sc overlay perturbed to leave a non-array at `dns.rules`; rendered line inspected. Control: the same perturbation on the pre-change source | candidate names `config.json`; pre-change source names `override.json`. **Note RS-1:** under this design the line is the assertion's own sentence, not the envelope's | AC-7 |
| V-7 | Source diff of `_filter_rules` and its call sites; call-graph extraction over the module as T-14 verified B-7; `git diff -w` over `generate_config()`; `git diff --stat` over the four product files | `_filter_rules` and its argument lists byte-identical; no `_apply_directive → _merge` edge; `-w` diff shows only the envelope's own lines; no new file, function or class | AC-8, AC-9, NFR-2 |
| V-8 | AST extraction of `t()` keys from `bin/sc` (from the code, never from this document), diffed against `HEAD` | exactly one new key; present in `zh` with the identical `{fault}` placeholder; no `失败：`; unnamespaced | AC-10, NFR-1 |
| V-9 | Structural line-number equality of `README.md` and `README.zh-CN.md` (headings, fences, tables, blank lines), as T-14's README-parity criterion does | still matching line for line; the new paragraph at the same line number in both | AC-11 |
| V-10 | `.harness/scripts/verify_all` run **from the repository root** on the candidate and on a pristine `HEAD` clone | no new FAIL, no new WARN; A.1 (no hardcoded secrets) still PASS | AC-13, BC-4 |
| V-11 | `systemctl show -p MainPID -p ActiveEnterTimestamp` at the start and end of every stage that runs anything; `is-active` never invoked | both values identical throughout | AC-14, BC-12 |
| V-12 | The shipped invocation: install the new `bin/sc`, place each BC-1 member at the override path, run `sc reload`, read `/var/log/sing-box/install.log` | **BLOCKED by construction** — needs root and the live service; filed as an operator obligation with this recipe, nothing substituted | AC-15, BC-14 |
| V-13 | `git diff --numstat` over the four product files, compared against K-16's budget and the per-edit size table | at or under +86 / −65 ± 6; any overrun reported as a design defect, not absorbed | NFR-3 |

## Residuals travelling

| id | statement | must reach <stage/doc> |
|---|---|---|
| RS-1 | AC-7's "smallest wrong build that passes" note — *"one that gates the assertion on override-presence but has no envelope — killed because that build produces a traceback here"* — is falsified by K-13, which gates the **label** rather than the loop, so the assertion still fires and no traceback occurs on the override-less path. AC-7's criterion text is satisfied; the build it names is killed by AC-2 (M0–M3) instead. | stage 3 `03_GATE_REVIEW.md`, stage 6 `06_TEST_REPORT.md` |
| RS-2 | **M8** — `{"route": {"rule_set": {"$append": [{"tag": ["a"]}]}}}` reaches `TypeError: unhashable type: 'list'` at `bin/sc:2093`, inside the envelope but outside BC-1. It is the cheapest evidence that FR-2 is a region and not a point list. Add it as a ninth fixture; it is not a binding criterion. | stage 6 `06_TEST_REPORT.md` |
| RS-3 | **M9** — the `json.dumps(config, indent=2, …)` band (pure-Python encoder, `c_make_encoder` bypassed by `indent`) may or may not be non-empty on the interpreter under test. Build the depth fixtures relative to the interpreter's own limits by bisection, never against the number 500. | stage 6 `06_TEST_REPORT.md` |
| RS-4 | The four re-homed findings in `01_RATIONALE.md` §"Re-homed findings" (the `_anchor_index` anchor echo; `docs/dev-map.md:63`'s R-16 parenthetical; the drift record baselining a checker-rejected document; R-12's widened population) stay PM-owned rows and are absorbed by no edit here. | PM, `docs/tasks.md` |
| RS-5 | `.harness/rejected-decisions.md` gains one record — `override-error-envelope-point-fixes-without-a-region` — carrying the S design, the 19-of-21 concession and the FR-2 totality argument. `.harness/**` is outside this task's product diff, so the PM files it at delivery, as it did for T-18 R2 and T-19 RS-6. | PM, at delivery |
| RS-6 | This contract carries two sections the generic stage-2 schema does not declare — `## Smaller alternative rejected` (mandated by name in the PM dispatch and by `.harness/rules/85-design-discipline.md` §"Recording the call") and `## Requirement coverage` (mandated by the PM dispatch). `.harness/rules/70-doc-size.md` declares no `## Stage-doc boundary rule` on this project, so Q-11's ruling applies and the deviation is recorded rather than resolved by invention. | stage 3 `03_GATE_REVIEW.md` |

## Partition assignment

**None.** `.harness/agents/` contains no `dev-*.md` file — this project runs single-Developer
mode, so stage 4 dispatches `harness-kit:developer` once for all of E1…E9 in one working tree,
in the `## Migration & edit sequence` order. There is no parallelism to describe and no
cross-partition dependency to order.

## Verdict

READY.
