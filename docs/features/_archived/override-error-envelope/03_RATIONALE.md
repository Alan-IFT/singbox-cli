> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## Method, and its one honest limit

This stage holds no execution tool. Every claim below was derived by reading `bin/sc` at the current working tree, both READMEs, `CHANGELOG.md`, `CONTEXT.md`, `.harness/rules/85-design-discipline.md`, `.harness/rules/70-doc-size.md`, `.harness/rejected-decisions.md`, `.harness/insight-index.md` and the archived T-14 and T-23 documents. Nothing was run, nothing was written, and no upstream document was edited. C-16 makes that limit binding downstream: every finding here is routed to stage 4 or 6 by name for measurement, and none may be cited as measured.

Every symbol the design claims to reuse was opened and read: `_unusable` (`bin/sc:541-545`), `_read_state` (`:548-569`), `OverrideError` (`:1223-1242`), `DIRECTIVES` / `_directive_list` (`:1250-1259`), `_dig` (`:1347-1354`), `_directive_of` (`:1357-1380`), `_anchor_index` (`:1383-1403`), `_apply_directive` (`:1406-1431`), `_merge` (`:1434-1476`), `_load_override` (`:1479-1540`), `_compose` (`:1543-1553`), `_filter_rules` (`:1056-1084`), `_warn_drift` (`:2005-2024`), `generate_config` (`:2027-2116`), the three overlays (`:1752`, `:1857-1863`, `:1910-1925`), `main()` (`:3644-3715`), and the `zh` composition block (`:345-373`). All exist, all at the cited lines, all able to carry the load the design puts on them.

## Duty 1 — rebuilding design S line by line

### The two holes, rebuilt against the shipped file

**M8 is real, and it is reachable through `override.json`.** Traced statement by statement for `{"route": {"rule_set": {"$append": [{"tag": ["a"]}]}}}`:

1. `_merge(config, override)` — key `route`, value a `dict`, `_directive_of` returns `None` (no `$` key), `target["route"]` is a `dict`, so it recurses (`:1455-1459`).
2. Key `rule_set`, value `{"$append": […]}` — `_directive_of` returns `("$append", [{"tag": ["a"]}])` (`:1367-1380`). `target["rule_set"]` is a `list`, because `_runtime_overlay` `$replace`s it at `:1917`. So `_apply_directive` runs (`:1462-1464`).
3. `_apply_directive` — payload is a `list`, so the `$append` tail returns `current + copy.deepcopy(payload)` (`:1424`, `:1431`). The inserted element is **never re-classified**: `_apply_directive` has no edge back to `_directive_of`, which is precisely T-14's B-7 and precisely why the element arrives verbatim.
4. `bin/sc:2093` — `set(d.get("tag") for d in config["route"]["rule_set"] if isinstance(d, dict))`. The element is a `dict`, so the `isinstance` guard admits it; `d.get("tag")` is `["a"]`; `set()` raises `TypeError: unhashable type: 'list'`.

So the architect's M8 is not a strawman and not a hand-edited-`config.json` case, which out-of-scope 6 would have excluded. It is a legal directive at a legal array position with an illegal payload element, and it produces a traceback on the shipped build.

**But M8 does not buy the envelope.** S4 as the architect wrote it wraps `:2097-2098`. Opening the same `try` at `:2093` instead covers `:2093-2098` — the `set()` comprehension, the empty-case `del`, and both `_filter_rules` calls — at **zero additional added lines**: the same `try:`, the same `except (AttributeError, TypeError):`, the same raise, with six lines re-indented instead of two. `TypeError` is already in S4's tuple. That is a correction of the architect **in the smaller design's favour**, and it is the T-23-precedent kind of work: rebuild the alternative and correct its author in either direction. (S4 would additionally need the same `OVERRIDE_PATH if override is not None else None` label gate E6 uses, since `:2093-2098` runs on the override-less path too; still free.)

**M9 is not established.** The contract portion of `02` says two holes are "constructible **today**, on the shipped file, with no future change". Its own RS-3 says the band "may or may not be non-empty on the interpreter under test". Both cannot be true. Reading is enough to see why the band's sign is genuinely uncertain: `copy.deepcopy` costs roughly two Python frames per dict level, and `json`'s pure-Python encoder — reached whenever `indent` is not `None`, because `c_make_encoder` is bypassed — costs roughly two generator frames per level through its `yield from` chain. Two costs of the same order, on documents of nearly the same depth (the composed document is the override's depth plus a constant). The band may be a few levels wide in either direction, or empty. I cannot measure it, so C-11 routes it to stage 6 with an explicit instruction to report emptiness as emptiness rather than omitting the row.

Net: of the design's two concrete purchases, one is free to S and the other is unproven. **The chosen design's justification, as written, does not survive.**

### The nearer alternative, and whether its refutation is sound

The architect refutes "drop E4, widen `:1536` to `except (ValueError, RecursionError)`" with: *"M0 exists because `:1536`'s enumeration was written as `ValueError` … repairing that site by appending the class that escaped is the identical act that produced the defect, one class later."*

As an argument form that is rhetoric. Appending a class to an enumeration is not per se the act that produced the defect; every enumeration that is in fact complete was written by exactly that act. The sentence proves nothing on its own.

The **conclusion** nevertheless survives, on three things the section does not cite:

- `bin/sc:1534-1537` wraps exactly one statement. That statement can raise `RecursionError` (CPython's `_json` C scanner signals depth exhaustion through `Py_EnterRecursiveCall`, and `RecursionError` subclasses `RuntimeError`, not `ValueError`) and `MemoryError` (a pathological document well inside `OVERRIDE_MAX_BYTES`' 1 MiB). Widening to two classes leaves the site open in at least one more direction that exists today, not merely in some future.
- `.harness/insight-index.md`, 2026-08-14: `UnicodeDecodeError` is a `ValueError` and **not** an `OSError`, so this repository's habitual `except OSError` let it through as a traceback — the same failure, already indexed, in the same file.
- `.harness/rejected-decisions.md` §`clash-api-bare-except-and-leaf-enumeration`: R-20 filed **four** leaves, stage 4 measured a fifth, stage 6 a sixth. Two of six were unknown to the pipeline until its last stage ran. This is measured project evidence that leaf enumerations at data boundaries in this codebase ship incomplete.

So F-3 records the rhetoric and the ruling keeps the conclusion. E4 stands.

### The adjudication, with the honest arithmetic

Raw sizes flatter the smaller design. Stripping mechanical re-indentation from both:

| | added (logical) | removed (logical) |
|---|---|---|
| chosen — E1 1, E2 2, E3 26, E4 3, E5 14, E6 2 | **+48** | **−33** |
| S+ (S with S4 opened at `:2093`) — S1 1, S2 3, S3 26, S4 4, S5 2, one key 2 | **≈ +38** | **≈ −32** |

They share E3/S3 (+26/−28) and E6/S5 (+2/−3) exactly. The contested delta is roughly **ten to twelve added lines** and one concept: a region rather than four catch sites. That is a much smaller purchase than `+80/−65` against `+36/−31` suggests, and it is the number rule 85's burden of proof actually has to be discharged against.

What the twelve lines buy, once M8 and M9 are removed from the ledger:

1. **FR-2's totality.** I checked whether FR-2 is a framing that manufactures the need for the larger design. It is not. `01`'s Goal — written above and before FR-2 — already says *"Every way the user's `override.json` can fail to produce an emitted configuration document must end as one complete named line"*. FR-2 restates that goal at the level of the region; it does not introduce a new claim to justify a new shape. And the analyst's own audit shows R-15 named the envelope because both other repairs are forbidden (the assertion may not be widened, `_filter_rules` may not be touched, no cap may be added). So the totality reading is inherited, not invented. The analyst was entitled to write it.
2. **BC-11's reportability under an exception nobody enumerated.** Under S+, a `NameError` introduced by a future refactor anywhere in `:2069-2104` is a traceback. Under the envelope it is `Cannot use /etc/sing-box/override.json: no configuration could be produced from it (NameError)` — attributable and greppable. No criterion in either design measures this, because it is the same property FR-2 states; C-12 makes stage 6 exercise it once with a forced raise.
3. **The project's own prior adjudication of this exact question.** The `clash-api` record declined `except Exception` for `clash_api()` on the ground that a defect *inside* sc would be reported as the host being broken — and drew, itself, the distinction that decides this case: *"`cmd_doctor` itself does use `except Exception` and is right to: a **driver** isolating unknown probe code can enumerate nothing, while a four-statement body can."* `generate_config()`'s enveloped region is thirty-odd lines driving arbitrary user JSON through `_merge`, `_dig`, a `set()` comprehension, `_filter_rules` and `json.dumps`. It is a driver over unknown data, not a four-statement body. And the reason `except Exception` was wrong in `clash_api()` is answered here structurally: `_unusable` keeps provenance a property of the call structure, and the fault clause keeps an sc defect reportable.

Could I instead have ordered S+? Only by ruling FR-2 either unwarranted or discharged by an enumeration. The first is untenable — FR-2 is the Goal restated. The second is a rewrite of the contract, which belongs to the analyst; the architect's own rework note says exactly that (*"the correct outcome is an amendment to FR-2 by the analyst, not a silent shrink of the envelope"*), and it is the right process. And I would not have made that amendment even if it were mine: rule 85 forbids code shaped like the bug report, and S+ is literally BC-1 ∪ {M8} rendered as four catch sites naming four classes. Twelve lines is a cheap price to stop shaping the code like the symptom list.

**So the architect's rule-85 call is upheld — and two of its three supports are struck.** C-9 binds the correction into `.harness/rejected-decisions.md` so the permanent record is not false, because a rejected-decisions entry claiming two constructible holes when one is free to the alternative and the other was never measured would mislead the next task that reads it.

### Policing the vocabulary

The dispatch asks whether a type-mismatch "vocabulary" has grown into a schema language. It has not, and I looked hard for the machinery to strike:

- FR-3 costs **zero** new translation keys — it widens the trigger of a sentence that already exists at `bin/sc:1471-1473` / `:359-360`.
- E3 **deletes** a branch: the two `copy.deepcopy` sites at `:1461` and `:1474` merge into one, leaving `_merge` with exactly one un-copied assignment, guarded so it is unreachable for containers.
- The whole task adds one dict entry, one changed loop, two exception arms, one conditional expression and one docstring word. No function, no class, no module, no file, no exception hierarchy, no taxonomy, no cap.
- NFR-1 permits two new keys; the design spends one.

I re-derived E3's loop against every case the file handles today and confirmed the behaviour table it must preserve: target `dict` + plain object → recurse; target absent + bare array → accept and `deepcopy`; target not a list + directive → today's "can only be applied to an array that already exists"; target anything but a list + scalar or `null` → assign (out-of-scope 5's clearing idiom intact); target `list` + object / scalar / `null` / bare array → the one existing sentence; target `list` + directive → `_apply_directive`. The only thing this re-derivation can silently lose is the **precedence** of `_directive_of`'s own two errors, which is why C-13 makes it a measured property rather than a comment.

There is nothing here to strike.

## Duty 2 — attacking the criteria

### What was already right

The R-22 trap the dispatch names is already built, and built well. AC-3 *constructs* the swallow-and-emit build and requires it to fail; AC-2 (iv) is the clause that kills it; AC-4 requires a **valid** override's effect to be present byte-for-byte against the pre-change source, killing the opposite failure; Q-10 states the pair explicitly. No criterion in this set is "no traceback" alone. That is a materially better criteria set than T-22's or T-23's arrived with, and it should be said as a positive statement rather than as an absence of findings.

### AC-2 cannot be run where it says (F-4, C-1)

`generate_config()` does not render anything. It raises `OverrideError`, and the sentence and the exit status are produced by `main()`'s arm at `bin/sc:3713-3715` (`sys.exit(_plain(t("Cannot use {path}: {problem}", …).replace("\n", " ")))`). A harness that calls `generate_config()` directly, as V-2 specifies, observes **zero** lines on the combined stream and an uncaught exception — so AC-2 (i) and (iii) certify nothing at the stated entry point. This is the same class of defect T-23's gate found in its AC-8: a criterion demanding an observable the code cannot produce there.

BC-12 already anticipated the fix without the criterion adopting it: *"Any run driving a non-`doctor`/`config` command through `main()` must neutralise `_init_files()`."* Confirmed against `bin/sc:3681-3686` — the `else` arm calls `_init_files()` (whose `/var/lib/sing-box` is a hard-coded literal), `_load_lang()` and `_resolve_clash_port()`. So the fixture drives `main()` with `argv = ["sc", "reload"]`, neutralises `_init_files`, repoints the path constants, pins `clash_api_port` and `lang` in the fixture's `settings.json` (insight index 2026-08-14, the `CLASH_PORT` twin of the `LANG` trap), and stubs `restart_service` / `subprocess.run`. Checked: nothing else on that route prints before the abort — `cmd_reload` prints only after `reload_or_restart()` returns, `_warn_degraded` (`:2099`) and `_warn_drift` (`:2100`) sit after every BC-1 abort point, and `_settings_or_empty(warn=True)`'s warning needs a broken `settings.json` the fixture must not have. So "exactly one line" is achievable and observable — at `main()`.

### AC-7 stops testing E6 (F-5, C-4) — and RS-1's ruling

RS-1 asks me to rule whether AC-7's stale annotation is an annotation defect or a contract defect. I checked the architect's claim that AC-2 kills the gate-without-envelope build: on such a build M0 raises `RecursionError` out of `json.loads` inside `_load_override` (past `except ValueError` at `:1536`), and M1–M3 raise out of `copy.deepcopy` and `_filter_rules`; all four reach the interpreter as tracebacks. AC-2 (i) fails (many lines) and (ii) fails (no path, no fault clause). **AC-2 does kill that build**, so RS-1's ruling stands: annotation defect, no analyst round-trip.

But rebuilding AC-7's own fixture found something worse, which RS-1 does not report. The obvious perturbation — an overlay function returning `{"dns": {"rules": {}}}` or a scalar there — no longer reaches the composed-document assertion at all under E3, because a non-directive value at an array-valued key now raises **inside `_compose`**, before `:2081`. That `OverrideError` carries `path = None`, so `main()` renders `Cannot use /etc/sing-box/config.json: …` and the criterion's stated clause passes. Meanwhile the pre-change control still names `override.json`, because on the old build the same perturbation silently replaced `dns.rules` and tripped the assertion at `:2083-2085` with its hard-coded `failure.path = OVERRIDE_PATH`. So candidate and control differ, AC-7 reports PASS — **and E6 was never executed.** A build carrying E3 and no E6 whatsoever passes AC-7.

The amendment pins a perturbation that survives E3 and still reaches `:2081`: a scalar at an **object**-valued key on the path, e.g. an overlay returning `{"dns": 5}`. Traced: `target["dns"]` is a `dict`, the value is neither `dict` nor `list`, so E3 keeps today's scalar branch and assigns `config["dns"] = 5`; then `_dig(config, "dns.rules")` walks to `5`, fails `isinstance(cur, dict)` and returns `None` (`:1347-1354`); the assertion fires at `at dns.rules`. On the pre-change build, identically, with `path = OVERRIDE_PATH`. Candidate names `config.json`, control names `override.json`, and the second amended clause — the line must be the **assertion's own** sentence, `at dns.rules: this must stay an array` — is what forces E6 to have been executed. This is also consistent with out-of-scope 5, which deliberately leaves the object position a silent replacement.

### The remaining criterion attacks

- **AC-2 (iv)** (F-6): "byte-identical to before the run" over a file that does not exist is satisfied by the absence of a write *and* by every build that never gets far enough to write. Pinning a sentinel `config.json` and a sentinel `.config.sha256` turns it from an absence into a positive survival. This is the clause the whole R-22 gate rests on, so it is worth the two lines of fixture.
- **BC-13** (F-7): the coverage table discharges it through "AC-2 (ii) in zh", which AC-2 does not say. Rather than leave a boundary condition riding on a clause that does not exist, C-2 adds one: a second run of one member with `lang: "zh"` in the fixture's `settings.json`, asserting positively-present `无法据此生成配置`. Because that fixture drives `main()` (C-1), the language reassignment at `:3685` is exercised rather than bypassed — which is the whole point of the 2026-08-01 insight-index entry, and the reason `sc.LANG` alone must never be the mechanism.
- **AC-10** (F-8): a build that writes the fault sentence as a bare literal adds no `t()` key and passes AC-10 by adding nothing. C-5 requires the AST extraction to find the sentence *as a key*; C-2's `zh` run kills the same build independently.
- **AC-1, AC-4, AC-5, AC-6, AC-9, AC-11, AC-12, AC-13, AC-14** were attacked the same way and hold. AC-4's control (a recipe whose effect is removed must show as different) and AC-1's control (a deliberately perturbed build must report different) are both genuine non-vacuity controls. AC-5's string-equality clause is exactly what stops four per-shape guards passing. AC-1's structural premise was independently confirmed: `_dns_overlay` `$prepend`s (`:1752`), `_telemetry_overlay` `$before`s or returns `{}` (`:1857-1863`), `_runtime_overlay` `$replace`s `outbounds` and `route.rule_set` (`:1914`, `:1917`), and `experimental.clash_api.external_controller` is a string over a string (`:1342`, `:1923`) — so E3's new array arm is genuinely unreachable without an override.

## Duty 3 — the two open items and feasibility

### `CONTEXT.md`

The edit exists: `CONTEXT.md:172-178`, the term **document envelope**, inside `## Language`, before `## Project intent`. It carries no product bytes. NFR-2 as written admits four product files and would exclude it.

T-23 is directly on point and I follow it. Its gate wrote, at `03_GATE_REVIEW.md:34` (F-13) and `:55` (C-12), that NFR-3's file list was *under-inclusive rather than the design out of bounds*, and amended the list to include `docs/dev-map.md` and `CONTEXT.md`; the task shipped `CONTEXT.md +9` and `05_CODE_REVIEW.md:92` reviewed the term. So: **the edit is permitted and NFR-2 is amended in writing.** It is not reverted.

One thing T-23 did that this task cannot do by default: there, `CONTEXT.md` was E-20 in the *developer's* diff, so stage 5 read it as a matter of course. Here it was written at stage 2 and the ledger says "not part of stage 4's diff" — which also puts it outside V-7's `git diff --stat` and V-13's numstat. Left alone, a product-tree file would ship unreviewed. C-7 therefore does three things at once: amends NFR-2, excludes `CONTEXT.md` from K-16's budget (it is not stage 4's work and must not consume stage 4's allowance), and requires `05_CODE_REVIEW.md` to read and sign it off explicitly.

### The size cap K-16

R-61's defect is a cap that is a round number and gets approved after being called incredible. K-16 is not that, and the check is arithmetic rather than opinion:

- Removals sum exactly: E1 1 + E3 28 + E5 33 + E6 3 = **65**. Every one is enumerated against a line range in the shipped file.
- The "32 added / 32 removed mechanical" figure is not decorative: `bin/sc:2069` through `:2100` inclusive is **32 lines**, which is precisely the block E5's `try` re-indents. The number is read off the file, not chosen.
- E3's `−28` matches the loop `:1453-1476` (24 lines) plus four docstring lines from `:1441-1446`; `+26` matches a re-derived loop of about nineteen lines plus a restated paragraph. Credible.
- E6's `+2/−3` matches: the three-line construction at `:2083-2085` becomes a two-line `raise _unusable(...)`. A net deletion.
- E7+E8+E9 at `+6` matches three files gaining one paragraph plus a blank line each — and I confirmed both READMEs are line-parallel through `:374-400`, so K-10's identical-line-number insertion is possible by construction.

The one soft spot is E5 (F-12). Its logical `+14/−1` is about five lines more than its named elements account for: `try:` 1, `except OverrideError:` 1, `raise` 1, `except Exception as e:` 1, the wrapped `raise _unusable(...) from None` 3, the hoisted `text = …` 1, and the write-line rewrite +1/−1 — nine added, one removed. Five unexplained added lines under a further `±6` tolerance is eleven lines of slack on a 48-line logical change, and that is where R-61 bites even though the cap itself is derived. The likely honest explanation is `bin/sc`'s house style, in which every block of this kind carries a rationale comment — `generate_config()`'s existing comments at `:2028-2035`, `:2063-2066`, `:2076-2080` and `:2087-2092` are exactly that. So C-8 does not cut the number; it makes the split explicit (`+7` scaffolding, `+1` hoist, `+1/−1` rewrite, `≤ +5` comment) so an overrun is visible against a named element rather than absorbed into slack. And it removes the tolerance from the removal side entirely: wrapping adds lines, it never removes them, so a removal count above 65 would mean deleting something the design did not enumerate.

**Endorsed with its arithmetic, amended in two places.** That is R-61 honoured: the cap is neither approved as-is nor waved away.

### Feasibility

Twelve of fifteen criteria run at stage 4/6 with no root and no live service, under C-15's constraints: AC-1, AC-2 (as amended), AC-3, AC-4 (with `subprocess.run` stubbed — see F-14), AC-5, AC-6, AC-7 (as amended), AC-8, AC-9, AC-10, AC-11, AC-12, AC-13. AC-14 is runnable unprivileged — `systemctl show -p MainPID -p ActiveEnterTimestamp` is a read-only property query and needs no root, which is exactly why the project standardised on it over `is-active`.

**AC-15 is correctly BLOCKED by construction.** It needs root, the installed binary at `/usr/local/bin/sc`, the live service and the installer's own capture of `/var/log/sing-box/install.log`. No weaker observable exists that would mean the same thing: driving `main()` in a fixture proves the sentence and the status, but not that the installed binary and the log capture behave that way, which is the whole content of the criterion. BC-14's precedent (seven times) is the right disposition, and C-14 forbids substitution and forbids any other criterion being reported as covering it. No *other* criterion needs root or the live service.

## Duty 4 — the hard constraints, checked against the file

**BC-7 / T-14 B-7 — no `_apply_directive → _merge` edge.** E3 edits `_merge`, not `_apply_directive`; `_apply_directive` (`:1406-1431`) calls only `_anchor_index`, `copy.deepcopy`, `OverrideError` and `t`, and K-6 plus the frozen set keep it byte-identical. The call graph gains exactly one edge in the whole task, `generate_config → _unusable`. The property survives for its original reason, which the docstring at `:1361-1365` states: an element inserted into an array is never passed back through the classifier. Verified; AC-9's extraction will measure it.

**T-14's deep-copy discipline.** The file holds seven `copy.deepcopy` sites: `:1423`, `:1428`, `:1430`, `:1431` (all in `_apply_directive`), `:1461` and `:1474` (in `_merge`), and `:1550` (`_compose`'s template copy). Not eight, as the dispatch says, and not the six I-3 implies — hence F-13, which asks stage 6 to enumerate from the code rather than from any document. E3 merges the two `_merge` sites into one guarded branch, leaving exactly one un-copied assignment unreachable for containers; E5's hoist copies nothing at all, since `json.dumps` returns a new `str`. The discipline is preserved by a deletion, which is the strongest form.

**BC-8 / R-44.** `bin/sc` contains no `setrecursionlimit` call anywhere, and no cap of any kind is added. Confirmed by search, not by reading the design. The bound the analyst identified — the merge's copy overflowing at roughly half the depth the masking walk does — is arithmetic that E3 preserves, since the copy site remains on every container path.

**Out-of-scope 3 / T-14 AC-8.** T-14's original AC-8 (`01_REQUIREMENT_ANALYSIS.md:283-285`) reads: `_filter_rules` remains the single definition, is still called for both arrays with the same usable set, and *"gains no array-name parameter"*. It constrains the interface, not the enclosing whitespace. This task's AC-8 restates that as "byte-identical … and so are its call sites' argument lists", while out-of-scope 3 says "not its call sites" full stop. The two cannot both stand, because **both** designs change those lines' indentation — the chosen design's E5 re-indents `:2097-2098` as part of its 32 lines, and S4 would re-indent them as part of its two. So the broad reading forbids the chosen design as well as the rejected one, which is a sure sign it is the wrong reading. C-6 fixes the reading at AC-8's, symmetrically. To answer the dispatch's question directly: **S4's `try` around the call sites would not have violated AC-8.**

**BC-5 / T-13 + T-14.** `_write_private()` stays the only writer of `config.json` (frozen set), and the `json.dumps` hoist moves no byte anywhere new — the complete serialised string already existed in `generate_config()`'s frame as `_write_private`'s argument at `:2104`; binding it to `text` three lines earlier changes only a name's lifetime. No new file, no new mode, no new instant at which credential bytes exist above `0600`. `_record_generated()` is untouched and still digests the file on disk through `_config_digest()` (`:1931-…`, *"sha256 hex of config.json AS IT IS ON DISK"*), never `text`.

**BC-6 / R-69.** `main()`'s arm at `:3700-3715` renders `e.path or CFG_PATH`, and K-15 plus the frozen set forbid narrowing it; it serves sixteen unguarded state-document call sites through `_read_state`. After E6, the path-carrying **construction** sites collapse to one, `_unusable` — the two remaining `e.path = OVERRIDE_PATH` statements at `:2039` and `:2073` are relabels of an already-constructed exception, deliberately kept because the call structure is what states whose document it is (K-5, and the class docstring at `:1231-1235` makes that the design). I-1's invariant is accurate as written. The four other `except OverrideError` sites (`:436`, `:595`, `:2038`/`:2072`, `:2791`) are unaffected.

**BC-3 — exactly one line, traced for M0.** `_load_override()` raises `RecursionError` inside `json.loads` at `:1535`; `except ValueError` at `:1536` does not catch it (`RecursionError` subclasses `RuntimeError`); E4's new arm at `:2036-2040` catches it and raises `_unusable(OVERRIDE_PATH, …) from None`; the stack has fully unwound to `generate_config()`'s frame by then, so building the sentence has room (RK-4 is right about this); nothing between the raise and `main()` prints, because `cmd_reload` prints only on return and `_warn_degraded` / `_warn_drift` are far below; `main()`'s arm collapses `\n` and `sys.exit` emits one line and status 1. One line, for M0, structurally. The same trace holds for M1–M8, all of which abort above `:2099`.

**BC-4 — every new and newly-reachable sentence.** The new key carries only `{fault}` = `type(e).__name__`, a code identifier, with `str(e)` / `repr(e)` / `e.args` banned by K-4. The newly-reachable existing sentence is `"at {at}: an existing array must be changed with one of {directives}"`, whose placeholders are a dotted key path and the fixed vocabulary — both expressly permitted by BC-4. E6's sentence takes `at` from the literal tuple `("dns.rules", "route.rules", "route.rule_set")`. And the analyst's re-homed anchor-echo finding checks out as correctly re-homed rather than absorbed: `_anchor_index`'s `anchor=json.dumps(match, …)` at `:1398-1402` is reached from `_apply_directive` from `_merge`, which was **already** inside the pre-existing inner `try` at `:2070-2074` and already rendered through `main()`'s arm — so the envelope does not newly reach it, and BC-4's scope excludes it correctly.

**BC-10.** One new key (K-9, against NFR-1's ceiling of two), inserted at `:373` inside the block whose comment at `:345-346` already carries the `失败` ban. The `zh` value `无法据此生成配置（{fault}）` carries the identical single placeholder, contains no `失败`, and the key is unnamespaced English prose that renders verbatim in English. Verified against the table's shape at `:345-382`.

## The one boundary the design does not argue (F-10)

`02`'s boundary section reasons carefully about the two ends — `_compose` outside because its input carries no override content, `_write_private` outside because an `OSError` is a fact about the filesystem — and then says nothing about the middle. But a contiguous region from `:2069` through the hoisted `json.dumps` necessarily encloses `_warn_degraded(report)` (`:2099`) and `_warn_drift()` (`:2100`), and neither takes override-supplied content as input: `report` comes from `ruleset_report()` and `_warn_drift` reads `config.json` and the drift record off disk. By FR-2's own test they do not belong in the region.

They cannot be moved: T-14's AC-9 pins the observable ordering (degradation warning, then write, then check), so both must stay above the write, and the serialisation must be inside. Splitting the region into two would cost more lines than it saves. So enclosing them is right — but it should have been *said*, in the section that exists to say exactly this. The practical exposure is small: `_warn_drift` is already defensive (`_drift_state()` swallows `OSError`/`ValueError` and returns `None`), so the realistic residue is a write failure on a closed stderr, which would render as an unusable-document sentence naming `override.json` with the fault clause attached. That is BC-11's stated contract rather than a violation of it — with an override present, sc cannot distinguish the two cases, so it names the override and names the fault. C-12 makes stage 4 record the boundary and stage 6 exercise it once, which also gives BC-11's reportability its only direct measurement anywhere in the plan.

## Verified good — positive statements, not absences

- The provenance design is genuinely structural after E6: `docs/dev-map.md:38` publishes the claim that all three user-document sites set `OVERRIDE_PATH` by call structure, and E6 is what makes that claim true for the third. Leaving `dev-map.md` unedited is correct, not an omission.
- The load's second arm is genuinely a *second* arm rather than duplicated judgment: `load_nodes()` (`:2042`), `ruleset_report()` (`:2049`) and the stale-selection repair (`:2056-2061`) sit between load and merge, out-of-scope 9 pins their ordering, and enveloping them would blame the user's override for a `KeyError` on a hand-edited `nodes.json` at `:2056`. Two arms encode two different provenance rules; they share one rendering.
- The edit sequence's step-5 precondition (E6 only in a tree that already has E5) is not bookkeeping: without it, AC-7's control comparison is meaningless and M0–M3 remain tracebacks, which is Q-4's stated hazard. It is correctly pinned.
- `README.md:378` / `README.zh-CN.md:378` do publish the promise FR-6's second clause needs, at the identical line in both files, so that clause really does require no README edit — the code change makes a shipped sentence true. Confirmed by reading both.
- No entry in `.harness/insight-index.md` contradicts any load-bearing assumption of this design. Three entries *support* it (the `UnicodeDecodeError`-is-not-an-`OSError` entry, the `LANG` reassignment vacuity trap, the `verify_all` cwd trap), and the two locale entries and the `json.loads`-accepts-bytes entry are correctly recorded as not applicable — this task adds no decode site and no locale dimension.

## What a rework round would need

None is required; the verdict is approval with amendments. If stage 6's C-11 measurement finds the M9 band empty, nothing in the design changes — C-9 already requires the rejected-decisions record to rest on FR-2 and the leaf-enumeration evidence rather than on M9. If stage 4 finds the E5 split of C-8 cannot be met without exceeding `+80` on `bin/sc`, that is reported as a design defect against K-16 and returns here, not absorbed. If C-4's amended AC-7 perturbation turns out not to reach `:2081` on the candidate — the one place my read-derived trace could be wrong — the criterion returns here for a second amendment rather than being weakened at stage 6.

---

## Summary for the PM

**Verdict: `APPROVED FOR DEVELOPMENT`**, with sixteen binding conditions.

**Rule-85 call: upheld — but two of its three supports struck.** I rebuilt design S against `bin/sc` line by line and corrected the architect **in the smaller design's favour** on both concrete claims:

- **M8 is real and reachable** through `override.json` (verified statement by statement: `_apply_directive` at `:1431` inserts the element verbatim, `set(d.get("tag") …)` at `:2093` raises `TypeError: unhashable type: 'list'`) — **but it costs S zero added lines to cover**, by opening S4's `try` at `:2093` instead of `:2097`. M8 does not buy the envelope.
- **M9 is unproven.** The design's contract calls it constructible today; its own RS-3 concedes the band may be empty. I could not measure it.
- The "same act one class later" refutation of the nearer alternative is **rhetoric as written**; its conclusion survives on evidence the design does not cite (`:1534-1537` wraps one statement that raises `RecursionError` and `MemoryError`, neither a `ValueError`; the insight-index `UnicodeDecodeError` entry; the R-20 four→five→six leaf record).

The envelope is upheld on what remains: FR-2's totality is the Goal restated rather than a framing invented to justify size (so the analyst was entitled to write it); the honest delta is ~12 logical added lines, not the raw +44; and the project's own `clash-api` adjudication supplies the deciding distinction — a driver over unknown data may enumerate nothing, a four-statement body may not. **C-9 binds the PM to correct RS-5's rejected-decisions text before filing it**, so the permanent record does not carry the two struck claims.

**Criteria amended in writing (no analyst round-trip):**

| criterion | amendment |
|---|---|
| **AC-2** | Entry point corrected to `main()` — `generate_config()` raises and renders nothing, so (i) "one line" and (iii) "non-zero exit" were unobservable where specified (C-1). Gains clause (v), a `zh` run, which discharges the otherwise-vacuous BC-13 (C-2). Clause (iv) now requires a pre-existing sentinel `config.json` + `.config.sha256`, so the R-22 gate cannot pass on absence (C-3). |
| **AC-7** | Perturbation pinned and a sentence-identity clause added (C-4). **I found worse than RS-1 reported:** under E3 the natural perturbation raises inside `_compose` before the assertion, so AC-7 as written was passed by a build carrying **no E6 at all**. RS-1's own ruling is nonetheless **upheld** — I confirmed first-hand that AC-2 kills the gate-without-envelope build via M0–M3. |
| **AC-10** | Must find the fault sentence as a `t()` key, killing a bare-literal build (C-5). |
| **out-of-scope 3** | Read as AC-8 states it — argument lists, not enclosing indentation. Both designs re-indent `:2097-2098`, so the broad reading forbade the chosen design too (C-6). |
| **NFR-2** | Amended to include `CONTEXT.md`, following T-23's gate C-12. The edit is **permitted, not reverted** — but because it was written at stage 2 it falls outside stage 5's default scope, so C-7 requires `05_CODE_REVIEW.md` to sign it off and excludes it from K-16's budget. |
| **K-16** | **Endorsed with its arithmetic** (removals sum exactly to −65; the "32" is the literal line count of `:2069-2100`, so it is derived, not round) — **amended twice**: E5's `+14` is republished as a named split (`+7`/`+1`/`+1−1`/`≤+5` comment), since ~5 lines were unaccounted for, and the `±6` tolerance now applies to **added** lines only. |

**Feasibility:** AC-15's `BLOCKED by construction` is correct and nothing weaker is substituted (C-14). No other criterion needs root or the live service; AC-14's `systemctl show` runs unprivileged. AC-4 additionally needs `subprocess.run` stubbed — `bin/sc:2111` has no `shutil.which` guard (F-14, a new PM-owned re-homed row).

**Hard constraints:** all survive — no `_apply_directive → _merge` edge, deep-copy discipline preserved by deletion, no cap and no `setrecursionlimit` anywhere in the file, `_write_private` still the sole writer with no credential byte moved by the hoist, `main()`'s arm untouched, one line traced structurally for M0, and no BC-4 echo (the `_anchor_index` anchor echo is correctly re-homed — it was already reachable, so the envelope does not newly reach it).

**No machinery to strike.** FR-3 costs zero new keys, E3 deletes a branch, and the task adds no function, class, file or taxonomy.

**All findings are read-derived, not measured** — this stage holds no execution tool. C-16 routes every one to stage 4 or 6 by name and forbids citing any of them downstream as measured.
