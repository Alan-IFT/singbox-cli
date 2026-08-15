# 04 — Development · T-24 `override-error-envelope`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

## Summary

One `try` region inside `generate_config()` now spans `if override is not None:` through a hoisted `text = json.dumps(config, indent=2, ensure_ascii=False)`, with an explicit `except OverrideError: raise` pass-through and an `except Exception as e:` arm that raises `_unusable(<path gated on override presence>, t("no configuration could be produced from it ({fault})", fault=type(e).__name__)) from None`; the load wrapper carries the same second arm with an unconditional `OVERRIDE_PATH`.

`_merge()`'s per-key loop is re-derived around the **target's** current type: a key whose current value is a `list` is assigned from exactly one expression, `_apply_directive(...)`, and every other overlay shape there — object, scalar, JSON `null`, bare array — reaches the one sentence that already existed; one branch was deleted and none added.

The composed-document array assertion constructs through `_unusable()` and gates its **path label** on `override is not None`, closing R-26; both READMEs and `CHANGELOG.md` state the rule. E1…E9 all landed in the design's `## Migration & edit sequence` order.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `bin/sc` | `_unusable()` docstring generalised from "a state document's failure" to "an unusable document's failure" — body unchanged, it is now THE single construction site of a path-carrying `OverrideError`. `+1/−1` | E1 |
| `bin/sc` | `TRANSLATIONS["zh"]`, immediately after `"at {at}: this must stay an array"`: the one new key/value pair `"no configuration could be produced from it ({fault})"` → `"无法据此生成配置（{fault}）"`. `+2/−0` | E2 |
| `bin/sc` | `_merge()` — the per-key loop re-derived around the target's current type; `_directive_of(value, where)` hoisted into a ternary guarded by `isinstance(value, dict)` at the top of the loop body; the two separate copy branches collapsed into one `elif isinstance(value, (dict, list)): target[key] = copy.deepcopy(value)`; docstring paragraph restated. `+28/−21` | E3 |
| `bin/sc` | `generate_config()`'s load wrapper gains a second arm for non-`OverrideError` exceptions with an **unconditional** `OVERRIDE_PATH`. `+3/−0` | E4 |
| `bin/sc` | `generate_config()` — the envelope: one `try`, two arms, the `json.dumps` hoist, the write line rewritten to `_write_private(CFG_PATH, text)`, and the enclosed region re-indented. `+43/−32` combined with E6 (they overlap in one hunk; see `## verify_all result` for the split) | E5 |
| `bin/sc` | The composed-document array assertion constructs through `_unusable()` and gates its path label on `override is not None`; the three inline construction lines become two. `+2/−3` | E6 |
| `README.md` | One new paragraph at `:400`, inside `## 🛠 Custom configuration (override.json)`, after the `$before`/`$after` paragraph and before the `Example —` block. `+2/−0` | E7 |
| `README.zh-CN.md` | The same paragraph in Chinese at the identical line number `:400`. `+2/−0` | E8 |
| `CHANGELOG.md` | One bullet as the first entry under `### 修复`, carrying every item K-12 lists. Two of its claims are stated **as this stage measured them, not as the requirement framed them**: (a) the pre-change silent replacement that reached disk is scoped to the array keys the composed-document assertion does **not** guard (`dns.servers`, `inbounds`, `outbounds` — HEAD: bytes changed and `_record_generated()` baselines the drift record onto the broken document **before** `sing-box check` runs). **The exit code in that clause was stub-scoped and is now corrected**: this stage measured `exit 0` only because C-1's harness stubs `subprocess.run` to `returncode 0`, so the checker never ran; with the real `sing-box` un-stubbed, stage 6 measured `lines=6 exit=1` on all three named keys (`06_TEST_REPORT.md` §RES-7, defect QA-1), and could construct no shape where the silent replacement and exit 0 co-occur. The bullet no longer claims an exit code for the pre-change build — it now states the overwrite and the baselined drift record, then the checker's non-zero exit. The bullet also says plainly that at `dns.rules` / `route.rules` / `route.rule_set` the pre-change build already ended as one line and a non-zero exit with the file untouched; (b) the class-name fault clause is attributed to the envelope's arms only — the array-vocabulary sentence names a position instead — and the no-echo property is attached to **that class-name arm alone**, where it holds by construction (`bin/sc:2122-2124` renders `type(e).__name__` and never `str(e)`; `:2084-2085` states why). It is **not** claimed for every failure in the region: `_anchor_index`'s pre-existing `—— match：{anchor}` (`bin/sc:1400-1404`, zh key `:370-371`) prints the user's anchor object verbatim, which BC-4 permits because this task neither introduces that sentence nor newly reaches it (`03_RATIONALE.md:198`) and which `02_SOLUTION_DESIGN.md:294` declines to fix. `+2/−0` | E9 |
| `CONTEXT.md` | **Not touched by stage 4.** Written by the architect at stage 2 (`:172-178`, actual `+8/−0`); excluded from K-16's budget by C-7, still in stage 5's review scope. | E10 |
| `docs/dev-map.md` | **Not edited** — outside C-7's permitted set. One row is now false; the exact current and replacement text is handed to the PM under `## Open issues for review`. | — |

## verify_all result

```
command: bash .harness/scripts/verify_all.sh, run from /home/alan/Programs/singbox-cli
baseline (working tree at HEAD, before any edit): PASS 17 / WARN 0 / FAIL 0 / SKIP 1
after (candidate, re-measured at this document's last edit): PASS 17 / WARN 0 / FAIL 0 / SKIP 1 (exit 0)
delta: 0 new FAIL, 0 new WARN, 0 new SKIP - baseline preserved, no check regressed
A.1 (No hardcoded secrets): PASS on every run
verify_all: PASSES from the repository root; no product file produced a WARN at any round
```

```
diff budget (K-16 as amended by C-8) — git diff --numstat
bin/sc          +79 / -55     budget +80 / -65  (added tolerance +6 unused)
README.md        +2 /  -0
README.zh-CN.md  +2 /  -0
CHANGELOG.md     +2 /  -0
product total   +85 / -55     budget +86 / -65  (added tolerance +6 unused)
CONTEXT.md       +8 /  -0     stage 2's edit, excluded by C-7 (design predicted +7)
```

```
E5 line split, published as C-8 amendment (a) requires
scaffolding                  +7   try: / except OverrideError: / raise / except Exception as e: / the raise's 3 wrapped lines
hoist                        +1   text = json.dumps(config, indent=2, ensure_ascii=False)
write-line rewrite       +1 / -1  _write_private(CFG_PATH, text)
explanatory comment          +5   the 5-line region comment above the try (cap: <= +5)
------------------------------------------------------------------------------
added beyond the split:       0   nothing to report under C-8
mechanical re-indent     +29 /-29 the enclosed region minus E6's 3 replaced lines
E6 inside the same hunk   +2 / -3 the assertion's construction through _unusable()
region size measured:        32   lines :2069-2100, exactly C-8's endorsed figure
```

```
per-hunk numstat (git diff -U0), mapped to ledger ids
-373,0  +374,2    E2   +2 / -0
-542    +544      E1   +1 / -1
-1441,6 +1443,9   E3   +9 / -6   (docstring)
-1455,2 +1460,10  E3  +10 / -2   (loop)
-1458,13 +1470,0  E3   +0 / -13  (loop)
-1473,0 +1474,9   E3   +9 / -0   (loop)
-2040,0 +2050,3   E4   +3 / -0
-2069,32 +2081,44 E5+E6 +44 / -32
-2104   +2128     E5   +1 / -1
```

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| D-1 | K-11 — `git diff -w` over `generate_config()` "must show only the envelope's own added lines, the assertion's two-line replacement and the `json.dumps` hoist" | The `-w` diff additionally shows **two comment blocks re-flowed** (the "NOT schema validation" block above the assertion, and the "Degrade per file" block), and the last sentence of the first block **rewritten**. Line counts are unchanged in both blocks; no statement, no expression and no identifier moved. | Two causes, both forced. (a) Width: the enclosing indent grows by 4 and those comment lines were already 89–91 columns, which would have put them at 93–95 against a house maximum of 92 in this region. (b) Truth: the old sentence read *"It cannot fire when there is no override … which is why this raise, too, names the user's document"* — that is precisely the reasoning E6 exists to retire (R-26). Leaving it in place next to a gated label would have shipped a comment asserting the refuted premise. The replacement keeps the true half ("every overlay sc composes leaves all three arrays, so today it cannot fire without an override") and states the new rule. |
| D-2 | E3 per-edit size row `+26/−28` | Measured `+28/−21` | `+2` added: a 3-line comment above the hoisted `directive = …` recording PQ-3/C-13's precedence rule (the whole point of the ternary is invisible without it), offset by tighter wrapping elsewhere. `−7` fewer removed: git matched more context inside the loop than the design's line-by-line count assumed (`for`, `where =`, the trailing `else:` / `target[key] = value`, and the two `raise` sentence bodies are byte-identical and were re-used, not deleted). Both totals stay inside K-16, whose cap is on the product diff and not on the per-edit row. |
| D-3 | E4 per-edit size row `+3/−0` and the key's shape | Measured `+3/−0`, but the translation key is written as **two adjacent string literals** (`"no configuration could be produced from it " "({fault})"`) at this site so the raise fits on 2 lines. | Writing the key whole here needs a 95-column line or a 4th line. Python folds adjacent literals at parse time, so the runtime key, the `zh` lookup and AC-10's AST extraction all see one string; E5's site and the `zh` table both carry it whole. Measured: `ast` extraction reports exactly one new `t()` key, `'no configuration could be produced from it ({fault})'`. |
| D-4 | K-12 — the `CHANGELOG.md` bullet must state "the seven malformed shapes" | The bullet states **eight** (`八种`) | BC-1 enumerates M0…M7, which is eight members. K-12's "seven" is an off-by-one against its own upstream; the bullet follows BC-1. Nothing else in K-12's required content list was dropped. |

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| C-1 (AC-2 amended: `main()` entry, `argv=["sc","reload"]`, `_init_files()` neutralised, all path constants repointed, `restart_service` + `subprocess.run` stubbed, `settings.json` carrying `clash_api_port` **and** `lang`) | **Built and run.** Harness = `scratchpad/runner.py` (loads `bin/sc` source, textually removes the auto-elevate block, execs it as a module, repoints `CFG_DIR`/`CFG_PATH`/`NODES_PATH`/`SETTINGS_PATH`/`RULES_DIR`/`OVERRIDE_PATH`/`STATE_PATH`/`LIB_DIR`, replaces `_init_files` with a no-op, `restart_service` with `lambda: True`, `subprocess` with a silent shim, sets `SYSTEMD=OPENRC=False`, then calls `main()`), one child process per fixture with `stderr=STDOUT` so the "one line" clause is measured on the real combined stream and the exit status is the real one. | M0…M8 all four clauses PASS; observed exit status `1` for every member. Full transcript in `04_RATIONALE.md`. |
| C-2 (clause (v): one member run at `lang=en` and `lang=zh`; the `zh` line positively contains `无法据此生成配置`; never by assigning `sc.LANG`) | **Done for two members.** Language set only in the fixture's own `settings.json`, so `main()`'s post-import `LANG = _load_lang()` is what selects it (BC-13, insight index 2026-08-01). | M1 `zh`: `无法使用 …/override.json：无法据此生成配置（RecursionError）` — one line, exit 1, contains `无法据此生成配置`, contains no `失败`. M4 `zh`: `无法使用 …/override.json：在 dns.rules：修改已有数组必须使用 $prepend, $append, $replace, $before, $after 之一`. Both `en` runs render the English keys. |
| C-3 (AC-2 (iv) is the survival of a **pre-existing** `config.json` with sentinel content and a pre-existing `.config.sha256`) | **Done.** Every fixture is built with `config.json` = `{"SENTINEL": "config.json must survive byte-identical"}\n` and `.config.sha256` = 64 zeros + `\n` **before** the run; (iv) is `sha256(before) == sha256(after)` for both files, never an existence test. | Both digests unchanged for M0…M8. Non-vacuity proved by the adversarial build (AC-3) and by the HEAD control at `dns.servers`, which both flip (iv) to false on the same fixture. |
| C-4 (AC-7 pinned to a scalar at an object-valued key; second clause: the line must be the **assertion's own** sentence) | **Done.** `_dns_overlay()` patched to `return {"dns": 5}`; run with no override present, candidate and HEAD clone. | candidate: `Cannot use …/config.json: at dns.rules: this must stay an array` — names `config.json`, does **not** name `override.json`, and is the assertion's own sentence, not the envelope's. HEAD control: same sentence but `Cannot use …/override.json:` — the R-26 defect, so the control discriminates. |
| C-6 (`_filter_rules`'s body, signature and call-site **argument lists** byte-identical; enclosing indentation may change) | **Held.** | AST comparison against the HEAD clone: function source segment identical `True`; `ast.unparse` of both call sites identical `True` → `["_filter_rules(config['dns']['rules'], defined)", "_filter_rules(config['route']['rules'], defined)"]`. `git diff -w` shows both call lines as **context**, i.e. unchanged. |
| C-7 (permitted file set; no new file) | **Held.** `git status --porcelain` shows exactly `bin/sc`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, `CONTEXT.md` (stage 2's), this task's own `docs/features/override-error-envelope/`, and the PM-owned `docs/batches/followups/*` which stage 4 did not touch. No file created outside the scratchpad. `docs/dev-map.md` deliberately **not** edited. | See `## Open issues for review` for the dev-map hand-off. |
| C-8 (E5 split published; added tolerance `+6` on added lines only; removals hard-capped at `−65`) | **Held, with the split published above and 0 lines beyond it.** `bin/sc −55`, product `−55` — well inside the hard `−65`. Added lines used none of the `+6` tolerance. | `## verify_all result`, the E5 split block. |
| C-12 (stage 4's record must state that the region encloses `_warn_degraded(report)` and `_warn_drift()`) | **Stated.** The contiguous region K-1 defines runs from `if override is not None:` to the `json.dumps` hoist, so it necessarily encloses `_warn_degraded(report)` (was `:2099`, now `:2116`) and `_warn_drift()` (was `:2100`, now `:2117`), **whose inputs are not override-supplied content** by FR-2's own test: `_warn_degraded` consumes `report` from `ruleset_report()` and `_warn_drift()` reads `CFG_PATH` and `STATE_PATH`. An exception from either is therefore rendered as "no configuration could be produced from `override.json` (`<class>`)" even though the override caused none of it. This is accepted, not overlooked: BC-11 grants exactly that licence and the fault clause is what keeps such a defect reportable. Stage 6 owns the forced-raise fixture. | This row. |
| C-15 (safety: no write to `/etc/sing-box` or `/var/lib/sing-box`; live service untouched; `_init_files()` neutralised; `systemctl show -p MainPID -p ActiveEnterTimestamp` at start and end; `is-active` never invoked) | **Held.** Every fixture lives under the session scratchpad. `_init_files` replaced by a no-op on every `main()`-driven run. `SYSTEMD`/`OPENRC` forced `False` and `restart_service` stubbed, so no init-system command is ever formed; the `subprocess` shim would have logged any child that was attempted and logged none. `is-active` was never invoked. | `MainPID=2566751 / ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` at the start of this stage and **identical** at the end. |
| C-16 (every gate finding is read-derived; stage 4 must measure, never cite) | **Held.** Nothing in this document cites a gate claim as measured. The gate's M0/M1 depth claims, the `_merge` case table, the AC-7 trace and the K-16 arithmetic were each re-measured here: depth fixtures by bisection in child interpreters (never against the number 500), the case table by running all nine fixtures plus the three C-13 precedence fixtures, AC-7 by the pinned perturbation on both builds, and the K-16 arithmetic by `git diff --numstat` / `-U0` per hunk. One gate figure is **confirmed exactly**: the region `:2069-2100` is 32 lines. | Per-row evidence above. |
| C-5, C-9, C-10, C-11, C-13, C-14 | **Not stage 4's** (owners: 6, PM, 6, 6, 6, 6/PM). Three of them were nonetheless exercised here so stage 6 starts from working fixtures: C-10's M8 fixture passes AC-2 (i)–(iv); C-11's bisection method is implemented and its two thresholds measured (`copy.deepcopy` overflows at depth **498**, `json.loads` at **9997**, on CPython 3.12.3 at `sys.getrecursionlimit() == 1000`); C-13's three precedence fixtures render sentences byte-identical to HEAD. | `04_RATIONALE.md`. |

## Open issues for review

**`docs/dev-map.md:38` is now false and I may not edit it (C-7).** The row enumerates the sites that set `OverrideError.path`, and E6 makes one of them conditional; it also has no statement about the region at all, which is stale-by-omission of the single largest structural fact this task adds. Exact current text (one sentence inside the `# Config generation` cell):

> The split buys provenance, not bytes: each of the two failure sources has its own code site, and the sites that handle the USER's document (the load, that merge, and the three-key array guard) set `OverrideError.path = OVERRIDE_PATH` — the class default `None` renders against `CFG_PATH`, so a fault in an overlay `sc` wrote is never reported as a fault in the user's file.

Exact replacement text:

> The split buys provenance, not bytes: each of the two failure sources has its own code site, and the sites that handle the USER's document (the load and that merge) set `OverrideError.path = OVERRIDE_PATH`, while the three-key array guard sets it **only when an override is present** (`OVERRIDE_PATH if override is not None else None`, T-24 / R-26) — the class default `None` renders against `CFG_PATH`, so a fault in an overlay `sc` wrote is never reported as a fault in the user's file. Since T-24 the span from `if override is not None:` to a hoisted `text = json.dumps(config, indent=2, ensure_ascii=False)` is **one `try` region**: `OverrideError` passes through untouched and every other exception becomes `_unusable(<the same gated path>, t("no configuration could be produced from it ({fault})", fault=type(e).__name__))`, so nothing between the override's bytes and the emitted document's bytes can be a traceback or reach `_write_private()`; the load wrapper carries the same second arm with an unconditional `OVERRIDE_PATH`. Two statements the region encloses, `_warn_degraded()` and `_warn_drift()`, take no override-supplied input — a fault there is named against `override.json` too, which is the price of a contiguous region and the reason the fault clause exists.

**`docs/dev-map.md:55` is not false but is now incomplete** (recommended, PM's call). Current: `THE merge: objects by depth, arrays only under a directive from DIRECTIVES.` Suggested: `THE merge: objects by depth; a key whose current value is an array accepts a directive object and **nothing else** — object, scalar, JSON null and bare array all earn the one sentence naming the vocabulary (T-24 FR-3), and the branch is taken on the TARGET's current type, never on the overlay value's.`

**A boundary FR-2 does not reach, found while measuring.** `subprocess.run([SB_BIN, "check", …])` at `bin/sc:2135` still has no `shutil.which` guard, so `sc reload` tracebacks on a host with no `sing-box` — the gate filed this as F-14/info and it is confirmed by construction (the harness had to stub `subprocess.run` for every success-path fixture). It sits outside FR-2's region by Q-8 and outside this task; it is a PM-owned re-homed row.

**`docs/dev-map.md:63`'s R-16 parenthetical** is the PM-owned re-homed row from `01_RATIONALE.md` §"Re-homed findings" item 2. Untouched, as the design ledger directs.

**One `[needs a run]` in `02_RATIONALE.md` is now closed.** §"Why the envelope's boundary is where it is" asked for a run confirming that the `json.dumps` hoist does not move the existing `"Could not write {path}: {err}"` rendering for a lone surrogate. Measured on both builds with `{"zzz": "\ud800"}`: identical 3-line output, identical exit `1`, `config.json` and the drift record byte-identical, on candidate and on the HEAD clone. The `UnicodeEncodeError` is indeed raised at the encode inside `_write_private()`, outside the region.

**AC-15 remains BLOCKED by construction** (C-14, stage 6/PM). Nothing in this stage substituted a weaker observable for it.

## Dev-map updates

None written. `docs/dev-map.md` is outside C-7's permitted file set; the two corrections above are handed to the PM as exact old/new text rather than applied here. No module, folder or file was added, moved or removed by this task — `NFR-2`/`K-8` hold: no new function, class, module or file exists, and `git status` shows no untracked product path.

## Insight to surface

- 2026-08-15 · On the shipped build M4–M7 written at `dns.rules`/`route.rules`/`route.rule_set` never reach disk — the composed-document assertion already stops them with one line and exit 1 — so an R-22 control placed at those keys shows candidate and HEAD **identical on all four AC-2 clauses**; the silent-replacement-reaches-disk class is only reachable at an array key the assertion does not guard (`dns.servers`, `inbounds`, `outbounds`), where HEAD writes a `config.json` whose `dns.servers` is a dict/int/None and baselines its digest before the checker ever sees it — the run exits **0** only while `subprocess.run` is stubbed, because with the real `sing-box` present `sing-box check` rejects the just-written document and the run exits **1** (QA-1), so the harm that survives un-stubbing is the overwrite plus the baselined drift record, never the exit code · evidence: bin/sc:2093-2097 (assertion) vs HEAD runs at `{"dns": {"servers": 5}}` — stubbed (this stage) and un-stubbed (`06_TEST_REPORT.md` §RES-7)
- 2026-08-15 · `copy.deepcopy` overflows a nested-object document at depth **498** while `json.loads` survives to **9996** on CPython 3.12.3 at `sys.getrecursionlimit() == 1000` — a factor of ~20, not the "roughly half" the requirement's rationale assumes — so a single depth fixture cannot exercise both recursion positions and the two must be bisected independently · evidence: bisection in child interpreters, `scratchpad/measure.py::_probe`

## Verdict

READY FOR REVIEW
