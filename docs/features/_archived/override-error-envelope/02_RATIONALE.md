# 02 — Rationale · T-24 `override-error-envelope`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Method, and its honest limit

This stage holds no `Bash` tool and ran nothing. Every claim below was derived by reading the
shipped `bin/sc` at the current working tree, both READMEs, `CHANGELOG.md`, `docs/dev-map.md`,
`.harness/rejected-decisions.md` and the archived stage documents. Claims that can only be
settled by a run are marked **[needs a run]** and travel as RS-2 / RS-3 to stage 6. Nothing was
inherited from `01_RATIONALE.md` without re-deriving it against line numbers.

No trigger of T2.1–T2.4 fired for a *contradiction*; `01_RATIONALE.md` was read in full because
the PM dispatch named it as required reading, and its measurement detail (the deepcopy frame
ratio, the `json.loads` `RecursionError` finding, the write-ordering refutation) is load-bearing
for Q-8 and therefore for E4.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Render an unusable document as one line and exit non-zero | `main()`'s `except OverrideError` arm — `sys.exit(_plain(t("Cannot use {path}: {problem}", …).replace("\n", " ")))` | `/home/alan/Programs/singbox-cli/bin/sc:3700-3715` | **Reuse as-is.** It already collapses newlines, `_plain()`s foreign fragments once, and renders `e.path or CFG_PATH`. No edit, no widening. This is why the envelope raises `OverrideError` instead of printing. |
| Construct an `OverrideError` that names whose document failed | `_unusable(path, problem)` | `bin/sc:541-545` | **Reuse, docstring generalised (E1).** Its body is already exactly "build the exception, attach the path, return it". Routing the envelope and the composed-document assertion through it takes the count of path-carrying construction sites from three to one, which is what BC-6 asks for and what makes a future re-parent a one-line move. |
| Decide provenance without an exception taxonomy | `OverrideError.path` + the class default `None` → `CFG_PATH` | `bin/sc:1223-1242` | **Reuse as-is.** FR-4 is a one-expression change (`OVERRIDE_PATH if override is not None else None`), not a mechanism. |
| The sentence for "an array must be changed with a directive" | `t("at {at}: an existing array must be changed with one of {directives}", …)` | `bin/sc:1471-1473`, table entry `:359-360` | **Reuse, widened trigger (E3).** FR-3 costs **zero** new translation keys because the sentence FR-3 needs already exists — it is the same rule stated over a larger set of overlay shapes. NFR-1 is satisfied with room to spare. |
| Name the directive vocabulary inside a sentence | `_directive_list()` | `bin/sc:1257-1259` | **Reuse as-is** — AC-5's membership test passes through it. |
| Apply a directive to an array, deep-copying every inserted value | `_apply_directive(current, name, payload, where)` | `bin/sc:1406-1431` | **Reuse untouched.** It is byte-identical in this design; E3 changes only *which* values reach it, never what it does. |
| Freeze the exception class hierarchy | `OverrideError(Exception)` with its docstring's own argument for not subclassing `ValueError` | `bin/sc:1223-1240` | **Reuse as-is.** The docstring already argues the case the goal statement forbids re-opening. |
| Read the user's override with five distinct filesystem policies | `_load_override()` | `bin/sc:1479-1540` | **Reuse untouched.** E4 wraps the *call site*, so all five policies (stat-before-open, `S_ISREG`, dangling-symlink-as-malformed, cap-on-read, whitespace-as-absent) survive trivially. |
| One merge implementation for every overlay | `_merge()` + `_compose()` | `bin/sc:1434-1476`, `:1543-1553` | **Extend in place (E3).** A second merge, a validator or a pre-pass would be a second opinion about what "apply a fragment" means — `docs/dev-map.md:55` states that prohibition. |
| A place to state the array rule for users | `## 🛠 Custom configuration (override.json)` and its directive table | `README.md:374-398`, `README.zh-CN.md:374-398` | **Extend with one paragraph each (E7, E8).** The promise FR-6 needs — "stops the command before anything is written … names the file and the problem" — is **already published** at `:378` in both files, so FR-6's second clause needs no README edit at all: the code change makes a shipped sentence true. |
| Byte-identity harness across the settings × rule-set matrix | T-14's harness | `docs/features/_archived/config-composition-layer/06_TEST_REPORT.md` | **Reuse for V-1 and V-4**, as AC-1 and AC-4 both direct. |
| A neutralisation recipe for importing `bin/sc` safely | T-13's `os` shim in `sys.modules` so `geteuid()` returns 0, with no mutation of `bin/sc` | `docs/features/_archived/config-write-permission-hardening/02_SOLUTION_DESIGN.md` §14 V-1, summarised in `docs/dev-map.md` | **Reuse for every fixture run.** Combined with `_init_files()` neutralisation (BC-12) and post-`main()` `LANG` handling (BC-13). |
| PDF-style "new module" need | (none found) | — | **No new module, function, class or file is justified here.** Every need above landed on an existing seam; the only genuinely new artifact is one dict entry (E2). |

**Verdict of the audit:** this task adds *one table row, one changed loop shape, two exception
arms and one conditional expression*. Everything else is existing code being called from one
more place. That is the shape rule 85 asks for — data over machinery, an existing seam over a
parallel one.

## Risk analysis

| id | risk | mitigation | AC / step that catches it |
|---|---|---|---|
| RK-1 | E3's loop re-derivation changes behaviour on the **override-less** path, breaking byte-identity for every host. | Verified by enumeration before design: the three sc overlays only ever put a directive object at an array position — `_runtime_overlay` `$replace`s `outbounds` (`:1914`) and `route.rule_set` (`:1917`), `_dns_overlay` `$prepend`s `dns.rules` (`:1752`), `_telemetry_overlay` `$before`s `dns.rules` or returns `{}` (`:1857-1863`). `experimental.clash_api.external_controller` is a **string over a string** (`:1342`, `:1923`), so it takes the unchanged scalar branch. The new array arm is therefore unreachable without an override. | AC-1 / V-1, with V-1's non-vacuity control |
| RK-2 | The 32-line re-indent silently drops, duplicates or reorders a statement — the classic cost of wrapping a block in `try`. | K-11 makes `git diff -w` over `generate_config()` a binding check: it must show only the envelope's own added lines, the assertion's replacement and the `json.dumps` hoist. Anything else is a defect visible in seconds. | AC-1 / V-1, V-7 |
| RK-3 | `except Exception` swallows something it should not — a `SystemExit` from a nested `sys.exit`, or a `KeyboardInterrupt`. | Neither is an `Exception` subclass in Python 3, so both propagate untouched. The only `sys.exit` inside `generate_config` is in `save_nodes()` (`:581`), which is called at `:2061`, **above** the region. | V-2 (exit status), V-7 (code read) |
| RK-4 | `RecursionError` is caught so close to the stack limit that building the sentence itself overflows. | The handler runs after the stack has unwound back to `generate_config()`'s own frame; `t()` + `_unusable()` + `sys.exit` are three shallow calls. The same construction is already exercised at that depth by the existing arms. | AC-2 for M0 and M1 / V-2 |
| RK-5 | The fault clause leaks a value from the override document into `/var/log/sing-box/install.log`. | K-4 bans `str(e)`, `repr(e)` and `e.args`. `type(e).__name__` is a code identifier: `RecursionError`, `AttributeError`, `TypeError`. No document byte can reach it. | BC-4 / V-10 (`verify_all` A.1), V-2 (ii) |
| RK-6 | A second output line accompanies the abort, breaking BC-3's "exactly one line". | Structural, not hoped for: every BC-1 abort point (`:2037` load, `:2071` merge, `:2083` assertion, `:2093`/`:2097` filter) precedes both `_warn_degraded(report)` (`:2099`) and `_warn_drift()` (`:2100`). The only other line reachable in a run is `_settings_or_empty(warn=True)`'s settings warning, which requires a broken `settings.json` the fixtures must not have. | AC-2 (i) / V-2 |
| RK-7 | The new key is added to the code but not to the `zh` table, or with a different placeholder — the failure `.harness/rejected-decisions.md` §`t-fmt-default-fallback` says cannot be structurally prevented on this project yet. | One key only (K-9), inserted as a single `key: value` line in a dict where key and translation are physically adjacent, inside the block whose comment at `:345-346` already carries the `失败` ban. AST extraction at V-8 reads the code, not this document. | AC-10 / V-8 |
| RK-8 | The README insertion breaks line-for-line parity between the two files. | K-10: identical line count at an identical line number, inserted between `:398` and the `Example` block at `:400` in both. Both files are currently parallel at every line in that section. | AC-11 / V-9 |
| RK-9 | FR-3 rejects a shape some real user's working override relies on. | The rejected shapes are exactly those that today produce a document `sing-box check` rejects (an object or scalar where sing-box requires an array), so BC-9's population — overrides that today yield an accepted `config.json` — is untouched. The one clearing idiom that matters, `null` over an **object**, is deliberately left alone (out-of-scope 5); clearing an array already has a spelling, `$replace` with `[]`, and the new README sentence says so. | AC-4, BC-9 / V-4 |
| RK-10 | The envelope hides a genuine `sc` defect behind "your override is wrong". | Q-9/BC-11's answer, implemented: the fault clause (`type(e).__name__`) is always present, so a `NameError` after a future refactor reads as `no configuration could be produced from it (NameError)` — attributable, greppable, and reportable. The alternative (blaming the exception class) is the taxonomy the goal forbids. | AC-2 (ii) / V-2 |
| RK-11 | `override` is unbound when the envelope's arm evaluates `override is not None`. | The envelope opens **after** `override = _load_override()` completes; the load's own failures are handled by E4's separate arm, which needs no `override` binding because its provenance is unconditional. This is a second, independent reason the two arms are not one. | V-7 (code read), V-2 (M0) |
| RK-12 | The size budget K-16 turns out not to be credible, and the gate approves an overrun rather than amending it (R-61). | The budget is a sum of a per-edit table, not a round number, and it separates 32 mechanical re-indent lines from 48 logical ones. A gate that disbelieves it can recompute it from the same table. | NFR-3 / V-13 |

## Why the envelope's boundary is where it is

FR-2's region is "the override document's bytes → the emitted document", and every boundary
choice below was made against that sentence rather than against convenience.

**Upper boundary: `config = _compose([...])` (`:2067-2068`) is OUTSIDE.** `_compose` merges only
overlays `sc` itself authored; its input contains no override-supplied content, so FR-2's region
does not include it, and an `sc`-internal defect there keeps today's behaviour. Including it
would have cost zero lines, which is exactly why it needed a reason not to: the honest reading of
FR-2 excludes it, and BC-11's licence to name the user's document is granted only for the region
where the user's content is actually flowing.

**Lower boundary: the serialisation is INSIDE, the write is OUTSIDE.** `json.dumps(config,
indent=2, ensure_ascii=False)` is a step between the merge and the write whose input includes
override-supplied content — FR-2's own words — so it is hoisted into the region as `text`.
`_write_private()` is not: an `OSError` there is a fact about the filesystem, and Q-8 rejected
candidate (c) precisely because a write failure and a checker failure already have correct,
tested renderings (`"Could not write {path}: {err}"` + `return False`) that must not be
disturbed. The hoist costs +2/−1 and is behaviour-neutral for the existing
`except (OSError, ValueError)` arm, because the `UnicodeEncodeError` a lone surrogate produces is
raised at the *encode* inside `_write_private`, not by `json.dumps` (which happily emits a `str`
containing the surrogate). **[needs a run]** to confirm that last clause on the interpreter under
test; it is the only place the hoist could move an existing rendering, and V-2's control runs
would show it.

**The load is a separate arm, not part of one big region.** Between the load (`:2036-2040`) and
the merge sit `load_nodes()` (`:2042`), `ruleset_report()` (`:2049`) and the stale-selection
repair (`:2056-2061`). Out-of-scope 9 pins their ordering relative to an abort, so they cannot
move; and enveloping them would blame the user's override for a `KeyError` on a hand-edited
`nodes.json` (`n["tag"]` at `:2056`). Two arms of three lines each is the price of not lying
about provenance. They are not duplicated judgment in rule 85's sense: they encode two different
provenance rules (unconditional vs. gated) that happen to share one rendering.

**Inside the region, `except OverrideError: raise` must be written explicitly**, because
`OverrideError` is a direct `Exception` subclass (`:1223`, and its docstring explains why it is
not a `ValueError`) and would otherwise be swallowed by the second arm and re-wrapped, losing
`e.path` and the specific sentence. The inner `try` around `_merge(config, override)` stays for
the same reason it was written at T-14: it is the **call structure** that says "this is the
user's document", and folding it into a conditional relabel (`if e.path is None and override is
not None`) would replace a structural property with a flag someone has to remember — the exact
defect R-26 filed against the assertion.

## Why the provenance gate is on the label, not on the loop

R-26's wording is "gating the guard on `override is not None`", which reads as gating the loop's
*execution*. FR-4's wording is stronger and different: *"when none is present, **the same
failure** names `config.json`"* — i.e. the failure still occurs and still carries its own
sentence. The contract wins over the row's phrasing, and the contract's reading is also:

- **smaller** — one expression changed, versus an `if` plus a two-line indent;
- **safer** — Q-4's stated hazard (a suppressed guard turns an unreachable mislabelled sentence
  into an `AttributeError` inside `_filter_rules`) simply never arises, because the guard is
  never suppressed;
- **better output** — AC-7's scenario renders `Cannot use /etc/sing-box/config.json: at
  dns.rules: this must stay an array` instead of `… no configuration could be produced from it
  (AttributeError)`. The first names the position; the second names only the class.

The cost is recorded honestly as RS-1: AC-7's "smallest wrong build" annotation assumed the
execution-gate reading, and under this design AC-7 no longer kills a gate-without-envelope build.
AC-2 does — M0…M3 are tracebacks on such a build. The criteria set as a whole is unweakened; one
criterion's annotation is stale.

## BC-7 and the deep-copy discipline, discharged concretely

**No `_apply_directive → _merge` edge is created.** E3 does not add a call anywhere: it hoists
the existing `_directive_of(value, where)` call to the top of the loop body, guarded by
`isinstance(value, dict)` so it is evaluated at exactly the same positions and the same count as
today, and it leaves `_apply_directive` byte-identical (K-6, frozen set). The call graph gains
exactly one edge in the whole task — `generate_config → _unusable`, a function `generate_config`
is already a sibling of — and `_apply_directive`'s callee set is unchanged. AC-9's extraction
sees the same absence T-14 verified as B-7. The property survives for its original reason: an
element inserted into an array is never passed back through the classifier, so an inserted rule
may legally contain a `$`-prefixed key and is emitted verbatim.

**The deep-copy discipline is preserved by a deletion, not a guard.** Today `_merge` copies at
two sites (`:1461` for a dict value, `:1474` for a list value) and assigns without copying at one
(`:1476`, scalars and `null`). E3 merges the two copy sites into one branch,
`elif isinstance(value, (dict, list)): target[key] = copy.deepcopy(value)`, leaving `_merge` with
**exactly one** un-copied assignment whose guard makes it unreachable for containers. Every other
overlay-container path is unchanged: `_apply_directive`'s four sites (`:1423`, `:1428`, `:1430`,
`:1431`) and `_compose`'s template copy (`:1550`). So the count of places a reader must check
falls from six to five, and the invariant "no overlay object is ever aliased into the emitted
document" becomes checkable by reading one `isinstance` test. This also keeps BC-8 intact by
accident of arithmetic: the merge's copy still overflows at roughly half the depth the masking
walk does, which is the bound currently keeping R-44 unreachable through `override.json`.

## Candidates weighed at this stage

**The envelope's implementation shape.** (a) One contiguous `try` inside `generate_config()` —
zero new concepts, one 32-line re-indent. (b) Extract the region into
`_emitted_json(override, nodes, active, report)` and envelope the call — same moved lines, plus a
four-argument interface, a new name, and a forced reordering of `_warn_degraded()` /
`_warn_drift()` relative to the document they describe. (c) Rename `generate_config` to an inner
and add a thin wrapper — rejected outright: it would envelope `_write_private`,
`_record_generated` and `subprocess.run([SB_BIN, "check", …])`, so a missing `sing-box` binary
would render as "your override.json could not be applied", which is Q-8's candidate (c) and a
lie. (d) A context manager — needs a class, which NFR-2 forbids. **(a) wins**; the re-indent is
noise a `-w` diff removes, and rule 85 counts concepts a future reader must hold, not whitespace.

**How the fault is named.** (a) `type(e).__name__` — a code identifier, no document content,
one placeholder. (b) `str(e)` — richer, and unsafe: `ValueError: invalid literal for int() with
base 10: '<value>'` is the class of message that carries user bytes into the install log
(BC-4). (c) Nothing at all — refused by FR-1 and BC-11: "your override is wrong" with no fault
clause makes an internal defect unreportable. **(a) wins**, and it is also why NFR-1's second key
went unspent.

**The sentence.** `"could not be applied ({fault})"` reads well after `Cannot use
…/override.json:` and badly after `Cannot use …/config.json:` (config.json is not "applied").
`"no configuration could be produced from it ({fault})"` is truthful after both paths, names the
thing that failed to happen rather than the mechanism, and its `zh` rendering
`"无法据此生成配置（{fault}）"` contains no `失败`, so it cannot collide with the load-bearing
`失败：` grep that `.harness/rejected-decisions.md`
§`mirror-fallback-cause-on-its-own-line-or-on-stderr` records as having been re-created once
already in a `zh` value after the English one was cleared.

**The README insertion point.** After the `$before`/`$after` paragraph (`:398`) and before the
worked example (`:400`), rather than appended to the bolded lead-in at `:388` (which would put a
long clause between a colon and its table) or between the table and its own explanatory
paragraph. Both files are line-parallel there, so parity is preserved by construction.

## Related historical work

- **T-14 `config-composition-layer`** — `docs/features/_archived/config-composition-layer/`. The
  layer this task puts an error model over; source of B-7, AC-8, the byte-identity harness and
  the provenance design E6 completes.
- **T-23 `state-file-io-contract`** — `docs/features/_archived/state-file-io-contract/`. Source
  of R-69 and of `_unusable()`'s second consumer; RT-1/RT-2 are the reason K-15 exists.
- **T-18 `status-egress-via-clash-api`** — `.harness/rejected-decisions.md`
  §`clash-api-bare-except-and-leaf-enumeration`. The project's prior adjudication of exactly the
  `except Exception` vs. leaf-enumeration question, including the driver-versus-body distinction
  this design leans on.
- **T-22 `share-url-userinfo-contract`** — `.harness/rejected-decisions.md`
  §`share-url-userinfo-five-local-fixes`. The precedent for how rule 85's tie-break is
  adjudicated when the smaller design is correct but does not satisfy the same requirement.
- **T-19 `ruleset-staleness-visibility`** — the precedent for "name the future edit it prevents,
  or it is not justified", applied here to reject the `_emitted_json` extraction.
- **T-06 `sc-config-show`** — source of R-44, honoured as a bound: no cap, anywhere, on anyone's
  say-so.
- `.harness/insight-index.md`: `_init_files()`'s hard-coded `/var/lib/sing-box` and the `main()`
  `LANG` reassignment bind every fixture (BC-12, BC-13, V-2); the `verify_all` cwd trap binds
  V-10. The two locale entries and the `json.loads`-accepts-bytes entry are recorded as **not
  applicable**: this task adds no decode site and no locale dimension, and its depth fixtures are
  built against interpreter limits, never against `LC_ALL`.
- `CONTEXT.md` gained one term at this stage, **document envelope**, because the design sharpens
  a word the requirement already uses.

## What a rework round would need

If stage 3 rebuilds design **S** and finds M8 or M9 unconstructible on the interpreter under
test, the FR-2 argument loses its two concrete holes and rests on the totality reading alone —
which is still binding contract text, but the `## Smaller alternative rejected` section would
need its "constructible today" claims corrected in place, and RS-2/RS-3 amended. If stage 3
instead rules that FR-2 is discharged by covering BC-1, the correct outcome is an amendment to
FR-2 by the analyst, not a silent shrink of the envelope — this design would then become S plus
E4, and K-1, K-2, K-16 and the size table would be the units that change.
