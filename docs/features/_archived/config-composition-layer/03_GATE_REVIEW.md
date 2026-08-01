# 03 — Gate Review · T-14 `config-composition-layer`

> Authored by the stage-3 gate-reviewer agent. Transcribed verbatim by the PM Orchestrator because
> that agent's tool set is read-only (Read/Glob/Grep); no content was added, removed or altered.

Mode: **full** · Stage 3 · Decision authority: **deferred-human, defer-do-not-ask**. Every ambiguity
found is ruled here as a numbered condition binding on the developer. No item reached a safety red
line. Upstream verdicts confirmed: `01` **READY**, `02` **READY**.

I verified against the source, not against the documents. Citations are by semantic anchor where a
line number will drift under this refactor.

---

## 1. The central claim, walked key by key

**Claim under test (`02` §5.1/§5.2/§16):** AC-1 holds by construction because every run-time value is
written to a key that already exists in `CONFIG_BASE`, and assigning to an existing dict key
preserves its position.

I read today's literal (`generate_config()`, `bin/sc:1001-1069`) and walked the composition against
it. **The claim holds.** Every position, in emission order:

| # | Today's literal | Composed path | Position preserved? |
|---|---|---|---|
| 1 | `log` | base only | yes — untouched |
| 2 | `dns` (`servers`, `rules`, `final`, `independent_cache`) | base only; `dns.rules` mutated in place by `_filter_rules` after composition, exactly as today | yes |
| 3 | `inbounds[0].interface_name = TUN_IFACE` | base, constant captured at import | yes — see F-1 |
| 4 | `outbounds = [selector] + nodes + [direct]` | base `[]` ← `$replace` | yes — existing key |
| 5 | `route.default_domain_resolver` / `auto_detect_interface` / `rules` | base only | yes |
| 6 | `route.rule_set` (comprehension over `report`) | base `[]` ← `$replace` | yes — existing key, 4th in `route` |
| 7 | `route.final` | base only | yes |
| 8 | `experimental.cache_file` | base only | yes |
| 9 | `experimental.clash_api.external_controller` | base `""` ← scalar depth-merge | yes — existing key, sole key of `clash_api` |

Array-element level:

- **Selector object.** Today `type, tag, outbounds, default, interrupt_exist_connections`
  (`bin/sc:993-999`). `02` §5.2 emits the same five keys in the same order. Today's
  `(node_tags or []) + ["direct"]` and §5.2's `node_tags + ["direct"]` are equal for every input:
  `node_tags` is a list comprehension, so it is `[]` (falsy) exactly when the `or []` arm fires.
- **Node outbounds.** Reach the array through `copy.deepcopy` inside `_apply_directive`. `deepcopy`
  of a dict rebuilds it by iteration, so key insertion order survives, and `json.dumps` output is
  byte-identical. This is also what makes BC-21 structural.
- **`route.rule_set` entries.** `tag, type, format, path` in both; `RULES_DIR` read at call time.
- **`del config["route"]["rule_set"]`** on the empty case removes a key without reordering the rest.

**The three suspects the PM named, resolved against the source:**

- `TUN_IFACE` (`bin/sc:34`) — never reassigned anywhere in the file (grep: 6 read sites, 0 writes).
  A genuine compile-time constant. Import-time capture in `CONFIG_BASE` is correct **for emission**
  but breaks a documented harness contract — F-1 below.
- `RULES_DIR` (`bin/sc:23`) — repointed by every harness; §5.2 reads it at call time. Correct.
- `CLASH_PORT` (`bin/sc:228`, reassigned at `bin/sc:2043` inside `main()`) — a module-level default
  that `main()` overwrites *after* import. §5.2 reads it at call time. Correct; had it been placed
  in `CONFIG_BASE` the emitted port would have frozen at 29090 on every host that ever probed a
  different one. The architect's stated reason is the real one.

**`defined` vs `usable_tags(report)` (A-7) — equal by construction, verified not assumed.**
`_runtime_overlay` builds `route.rule_set` from `[... for tag, fname, status in report if status ==
"usable"]`; `usable_tags(report)` (`bin/sc:794-796`) is `set(tag for tag, _f, status in report if
status == "usable")`. Same source, same predicate, same tags. Furthermore, all four tags are
referenced in `route.rules` (`geosite-google`, `geosite-private`, `geoip-cn`, `geosite-cn`), so
**any** divergence between the two sets would alter the filtered arrays and be caught by the 64-run
byte comparison. AC-1 is not weakened; the differential is a proof, not a hope.

**Conclusion: no key and no array element is emitted at a different position, and no value the base
cannot express was found. The approach is sound and does not need to change.**

## 2. Audit — 8 dimensions

| # | Dimension | Result | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | All 30 ACs are mechanically checkable. The closure is finite because the analyst *verified* `generate_config()` never calls `load_settings()` — I confirmed it: the function's only inputs are `load_nodes()`, `ruleset_report()`, `CLASH_PORT`, `TUN_IFACE`, `RULES_DIR`. |
| 2 | Design completeness | **PASS** | Every AC has a named mechanism except AC-26, which has no driver in §11 (F-3). Every AC-1 position is discharged by §1 above. |
| 3 | Reuse correctness | **PASS** | Every cited symbol exists and behaves as claimed: `_write_private` `bin/sc:312`, `_filter_rules` `:816`, `_warn_degraded` `:847`, `ruleset_report` `:754`, `usable_tags` `:794`, `_plain` `:1304`, `t`/`TRANSLATIONS` `:305`/`:95`, `save_nodes`'s `sys.exit` `:386`, `_resolve_clash_port`'s `except OSError: pass` `:288-289`, `hashlib.sha256` streaming in `ruleset_state` `:695-711`. "No merge of any kind exists" is accurate — the only `.update(` in the file is a hashlib digest (`:703`). `copy` and `stat` are genuinely absent from the import block (`:3-16`). |
| 4 | Risk coverage | **PASS** | R-1 (key reorder) is correctly named as the top risk. Two risks the design did not name are added as F-2 and F-4. |
| 5 | Migration safety | **PASS** | No data migration. BC-16 (absent record ⇒ unknown) is what makes the upgrade path silent on 100% of existing hosts; `uninstall.sh:135` removes `/etc/sing-box/` wholesale so the new artifacts leave no residue; `install.sh:412-417` is untouched so AC-7 holds. |
| 6 | Boundary handling | **PASS** | Null (BC-1, `active or "direct"`), empty (BC-7 + T-1), max (`OVERRIDE_MAX_BYTES`, read-capped so the grow-after-stat race is closed), non-regular file (`stat.S_ISREG` before `open`, which is the correct order — `os.stat` does not block on a FIFO, `open` would), error paths (BC-8…BC-14 each with a distinct message). Concurrency is out of the model and correctly so: `_write_private` is atomic and there is no lock today. |
| 7 | Test feasibility | **WARN** | §11 is drivable as written and the two safety properties are load-bearing and real (F-5), but three gaps: fixture freshness (F-2), AC-26 has no driver (F-3), and the baseline oracle is ambiguous while the working tree is dirty (F-4). All are conditions, not defects. |
| 8 | Out-of-scope clarity | **PASS** | O-1…O-10 are restated in `02` §15 and each is re-homed to a named owner (T-20, R-9, R-10/R-11, a new pool row for R-4). D-12's "zero content overlays" is the line that stops over-building, and it is enforced by AC-1 itself. |

## 3. Findings

**F-1 · WARN · `02` §4 / P-4 · `docs/dev-map.md` line 30 becomes false for `TUN_IFACE`.**
That row states the `# Paths` contract verbatim: constants there are *"only ever referenced inside
function bodies, so a test harness can repoint them after import."* Once `CONFIG_BASE` is a
module-level literal containing `interface_name: TUN_IFACE`, that is no longer true of `TUN_IFACE` —
a harness that repoints it after import gets the old device name in the emitted config, silently.
The design's dev-map update (§2) lists the two new paths but not this exception. Owner: developer,
at the dev-map edit P-4 already permits. → **Condition 5.**

**F-2 · WARN · `02` §11 · fixture freshness is not pinned, and the drift line is stderr.**
The candidate writes `STATE_PATH` and `_warn_drift()` writes to stderr, which AC-3 byte-compares.
§11 item 7 anticipates the extra artifact but never says each of the 64 points runs in a *fresh*
`mkdtemp()` root. A stale `STATE_PATH` from a previous point makes the candidate emit a drift line
the baseline cannot emit — a spurious AC-3 failure at best, and at worst a masked one if the
developer then relaxes the stderr comparison to make it green. → **Condition 3.**

**F-3 · WARN · `02` §11 · AC-26 has no driver.**
AC-26 (doctor writes nothing, over a fixture carrying a hand-modified `config.json`, a malformed
override and no drift record) is listed in `01` §6 but appears in none of §11's twelve items. It is
cheap: `_doctor_config()` (`bin/sc:1419-1446`) opens `CFG_PATH` read-only and doctor takes `main()`'s
read-only arm (`bin/sc:2038-2039`), so the property holds by inspection — but AC-26 asks for a run,
not an inspection, and T-05's read-only property is exactly the kind that decays silently.
→ **Condition 4.**

**F-4 · WARN · `01` AC-2 vs. the repository state · the baseline oracle is ambiguous today.**
`git status` at gate time shows `M bin/sc` — the working tree differs from `HEAD`. AC-2 says the
baseline is "`bin/sc` at the task's starting commit … e.g. a pristine clone or `git show`". With a
dirty tree, `git show <commit>:bin/sc` is **not** the starting state, and if the uncommitted delta
touches `generate_config()` the 64-run differential silently measures the wrong thing — in the
direction that produces a false green. → **Condition 2.**

**F-5 · PASS (positive) · `02` §11/§12 · both safety properties are real and load-bearing.**
Verified against `docs/dev-map.md` "Patterns to avoid": the recipe's `assert os.geteuid() != 0` is
what makes the `unreadable` rule-set fixture (mode `000`) producible at all — root would read it and
the fixture would silently degrade to `usable`, quietly deleting four of the sixteen subsets from the
closure. And `_init_files()`'s `/var/lib/sing-box` hard-coding is confirmed at `bin/sc:367`
(insight-index L27), which is both why §11 item 4 forbids driving it and why the architect's
rejection of `/var/lib/sing-box` for the drift record is correct on testability grounds. §11 item 2's
"assert every repointed path is inside the temp root" is the only mechanism in either document that
structurally prevents a forgotten constant writing under `/etc`. It must not be softened.

**F-6 · WARN · `02` §7 · one sentence can be read as licensing a live-host action.**
§7 says *"QA must exercise AC-20/AC-21 through `sc reload`, or with the service stopped."* On this
machine `sc reload` is `/usr/local/bin/sc`, which regenerates the owner's live `/etc/sing-box/
config.json` and restarts the running service; "with the service stopped" would mean stopping it.
Both are forbidden by NFR-1. The intent is clearly the in-fixture module call, but the wording is the
one place in 1178 lines that a stage-6 agent could act on literally. → **Condition 1** (this is the
only finding I would call safety-adjacent; it is a wording fix, not a design defect).

**F-7 · WARN · `02` §8 key 9/10 · `{directives}` renders a Python tuple.**
`DIRECTIVES` is `("$prepend", "$append", "$replace", "$before", "$after")`; `t("… one of
{directives}", directives=DIRECTIVES)` emits `('$prepend', '$append', …)` on the user's screen.
AC-19 requires the message to *name* the three directives; a repr is not naming. → **Condition 6.**

**F-8 · WARN · `bin/sc:1304-1325` · `_plain()` does not remove `\n`.**
Confirmed by reading it: it strips `\r`, removes complete CSI sequences, and `rstrip()`s. JSON
permits a literal newline inside a key (escaped `\n`), and `where` is built from user-supplied key
names, so a crafted override can emit a multi-line error against NFR-7's "one complete line per
fact". One-token fix at the single render site. → **Condition 7** (low severity; recorded so it is a
decision rather than an oversight).

**F-9 · WARN · `02` §16 · the consumer table overstates T-21.**
Row 1 claims T-15/T-16/T-17/**T-21** "all four edit" `CONFIG_BASE`. T-21 (`BATCH_PLAN.md:30`) is a
rule-set *source* problem — mirrors, releases, selectable source sets — which touches
`RULESET_BASES` / `RULESET_FILES`, not the emitted document, and the design's own §3 and the
`override-as-confd-fragment-directory` record both characterise it as a `settings.json` selection
problem. Rule 85 is still satisfied (four real consumers for `CONFIG_BASE`: T-15, T-16, T-17, user
customization), so this is a documentation inaccuracy, not a structural one. No condition; do not
re-litigate at stage 5.

**F-10 · INFO · `02` §5.7 · `_dig` has exactly one caller.**
The weakest member of the decomposition, same class as T-05's `_doctor_print` which that gate
permitted. It earns its place by keeping the §6 shape assertion a one-liner. Permitted; it must not
grow a second parameter or a mode.

**F-11 · INFO · `cmd_add` and a malformed override.** `sc add` persists the node at `bin/sc:1218`
(`save_nodes`) *before* `reload_or_restart()`, so under A-5 the node is added and the only message is
"Cannot use /etc/sing-box/override.json: …". This is precedented — today a `sing-box check` failure
leaves the node persisted too (`bin/sc:1219-1224`) — so it is not a new shape. No action.

## 4. Rulings on the eight items the PM routed here

**T-1 (whitespace-only / zero-byte override ≡ absent) — ACCEPTED.**
BC-7 and D-16's binding constraint 2 both say "empty is identical to absent"; BC-8's list is about
malformed *content*, and whitespace cannot encode a typo. The alternative's failure is concrete:
`touch /etc/sing-box/override.json` would break `sc reload` and fail an install via BC-19. Binding:
the branch is `if not text.strip(): return None` and nothing wider. `"{"`, `"[]"`, `"null"`, `"0"`
and any other non-whitespace non-object content stay malformed, and both edges must be tested.

**T-2 (merge-time error aborts after the `nodes.json` active-rewrite) — ACCEPTED; it satisfies
AC-20.** AC-20's text pins three things: no write to `config.json`, a non-zero exit, and a message
naming the override path and the problem. The BC-3 rewrite is none of those. AC-21 also holds — I
confirmed `restart_service()` is reachable only from `reload_or_restart()` (`bin/sc:1102-1106`)
*after* `generate_config()` returns, and it never returns. D-2's own rationale scopes itself to "let
a typo install a broken document", which the parse-first ordering fully prevents. BC-3 is an explicit
preservation requirement and outranks D-2's looser phrasing. Keeping BC-3 literal was the right call.

**T-3 (`sc update-rules` skips T-10's run-level outcome line) — ACCEPTED; the 6-line stash is NOT
required.** Reasons, in order of weight: (a) the invariant's *substance* is preserved — I confirmed
the abort lands at `bin/sc:1734`, strictly before `restart_service()` at `:1741`, so nothing happened
to the service and the run states exactly which file to fix; (b) `save_nodes()` already unwinds past
that same summary block from inside the same call, so the stash would close one of two doors while
advertising the invariant as enforced — a worse state than the honest one R-12 records; (c) six lines
of exception-stashing inside the one command T-10 has just stabilised, on the least reachable path in
the task, is precisely the speculative complexity rule 85 forbids. **Binding:** R-12's row in
`docs/tasks.md` is updated at delivery to name the second raise site, so the open-row ledger stays
truthful. → **Condition 8.**

**A-7 (`_filter_rules` receives `defined`, not `usable_tags(report)`) — RULED IN.**
Three reasons. (i) AC-1 is provably unaffected — verified in §1 above, and the 64-run closure
*detects* any divergence rather than assuming none, since all four tags are referenced in
`route.rules`. (ii) It is not a behaviour change: the override path has no prior behaviour, so this
is a new-path design choice of the same kind as A-5, and calling it "behaviour change in a zero-
behaviour-change task" misapplies the gate. (iii) Without it, the single most natural user
customization — define a rule-set, then reference it — silently deletes every referencing rule, which
is verbatim the "overlay that silently does nothing" failure BC-12 declares intolerable. AC-8's
"with the same usable set" is satisfied on its operative reading (both call sites get the same set,
`_filter_rules` gains no array-name parameter, one definition). Note for stage 5: `defined` must be
computed **before** `del config["route"]["rule_set"]`, as `02` §6 has it.

**A-5 (`OverrideError` → `sys.exit`, exit 1 from `sc add` / `sc rm`) — CONFIRMED, not a regression.**
`OverrideError` is raisable only from `_load_override()`, `_merge`/`_apply_directive`, and the §6
shape assertion. The first requires `/etc/sing-box/override.json` to exist — a file that does not
exist on any host today and that `sc` never creates (B-9). The latter two require an override to be
present, because with none the run-time overlay's three directives are all `$replace` against arrays
`CONFIG_BASE` guarantees (this is R-3's premise and it is sound today). Today's behaviour is
confirmed unchanged: `cmd_add` prints the check-failed line and exits 0 (`bin/sc:1219-1224`),
`cmd_rm` discards the return entirely (`bin/sc:1233`). Both keep exiting 0 on every path that exists
today. `cmd_use`'s hot-apply arm (`bin/sc:1196-1200`) never reaches `generate_config()`, as §7 states.

**P-4 (`docs/dev-map.md` in the diff boundary) — CONFIRMED.**
The load-bearing reason is real and I verified it: `docs/dev-map.md:30` enumerates the five
repointable path constants and `:111-119` is the repoint instruction every future harness copies.
Two new constants under `/etc/sing-box` that are not on that list means the next task's harness
writes under `/etc`. This is documentation with a safety function. Approved — with F-1's addition:
the same edit must record that `TUN_IFACE` is now captured at import and can no longer be repointed.

**P-1 (six glossary terms in `CONTEXT.md`) — CONFIRMED.**
Read all six (`CONTEXT.md:87-122`). `base template`, `overlay`, `user override` and `drift` describe
behaviour and state, and their `_Avoid_` lists do the disambiguating work the file exists for.
`directive` names the five sigils, but `01` B-5 mandates that vocabulary at requirement level, so it
records a settled requirement rather than pre-deciding a design. `drift record` names a path and an
algorithm, but both are stage 2's own closed decisions and T-20 is the named consumer that needs
them. **Nothing pre-decides anything for T-15/T-16/T-17**: no term says where a shipped overlay
lives, in what order overlays apply beyond "user override last", or what any of the three will
contain. One observation, no action: `user override` says "document" (singular), written while D-16
was still open; it now matches D-16's outcome, so it needs no edit.

**Doc size — assessed, no bounce.**
`verify_all.sh:229-237` (F.6) is **WARN-only**, and its loop `continue`s on any path containing
`/_archived/`. So: `01` (540L) and `02` (638L) will fire F.6 WARN from now until archive, and
archiving clears it exactly as it did for T-05 and T-13. **AC-30 is unaffected** — it requires no new
*FAIL*, and a WARN is not a FAIL. The content is load-bearing (a 64-run closure enumeration and a
17-key translation table); trimming prose would cost a stage transition and buy a cosmetic. PM ruling
P-2 upheld. Reviewer's own note: this document is deliberately kept under the cap.

## 5. Predicted `verify_all` outcome

Same PASS/FAIL profile as a pristine clone, **plus F.6 WARN**. Specifically:

- **B.1** (`python3 -m py_compile bin/sc`, `bash -n`) — the real gate. Two new imports and a large
  literal move; a stray comma in `CONFIG_BASE` fails here first. Run it after every edit, not once.
- **B.2** — `install.sh` untouched, so unchanged PASS. The 17 new `bin/sc` keys are **not** covered by
  B.2 (it is install.sh-only, `dev-map.md` and insight-index L30 both say so); §11 item 11's scripted
  parity assertion is the only coverage they get. I checked the table by hand: all 17 placeholder
  sets match, no `zh` value contains `失败：`, and no key contains a stray literal brace.
- **E.6** — matches `^##\s+Adversarial\s+tests` and does **not** skip `_archived/`. The stage-6 report
  must use that heading unnumbered (insight-index L26; it cost T-05 a debug cycle).
- **F.4** — `.harness/insight-index.md` is at exactly the 30-line cap. A delivery insight appended
  without running `archive-task` will flip F.4 to WARN.
- **F.6** — WARN naming `01`, `02`, and every later stage doc over 500 lines. Expected; clears on
  archive.
- **A.1** — the new README sections contain example override JSON, but A.1 excludes `*.md`. No risk.

## 6. High-probability developer questions, pre-answered

1. *"Can I write `CONFIG_BASE` by reformatting the literal in place?"* — **No.** Move it as a pure
   text move with no re-typing and no re-indent-driven reflow (R-1). Build the differential first and
   prove it FAILS on a one-character change (AC-4) **before** you touch the literal, otherwise a
   green run proves only that your harness is inert.
2. *"`assigning to an existing key preserves position` — is that safe on the 3.6 floor?"* — Yes, and
   it is CPython implementation detail there, language guarantee from 3.7 (BC-23). No `OrderedDict`.
   `copy.deepcopy` preserves insertion order on both. Nothing in either document's sketches is
   3.7-only: `f`-strings are 3.6, `os.stat`/`Path` interop is 3.6, `stat.S_ISREG` and `copy.deepcopy`
   are ancient, `contextlib.redirect_stderr` is 3.5. No walrus, no `dataclasses`, no
   `capture_output=` beyond the three pre-existing sites you are not touching.
3. *"T-16 needs to change `query_type: [64, 65]` to include AAAA — there is no `$modify` and D-8
   forbids `$delete`. Is the vocabulary under-built?"* — **No.** That need decomposes into an
   *insertion*: a separate `{"action": "predefined", "rcode": "NOERROR", "query_type": [28]}` placed
   with `$after` the existing predefined rule, since sing-box evaluates `dns.rules` in order. Every
   named consumer's need is expressible as an insertion, an append/prepend, or a whole-array
   `$replace`. Do not add a mutation or deletion directive on T-16's behalf; that is T-16's decision
   with T-16's evidence.
4. *"Is `$before`/`$after` + anchor matching speculative?"* — No. `01` §2 and the current array
   (`bin/sc:1019-1029`) show the constraint is semantic — the reject rule must sit after the
   `clash_mode` rules and before the rule-set-driven rules — and T-16 and T-17 both insert into
   `dns.rules` (`BATCH_PLAN.md:25-26`). A numeric index written by T-16 is wrong the moment T-17
   inserts earlier, which is D-7's exact case. It is the largest new machinery and it is the one
   piece with two independent named consumers.
5. *"Where does the drift record collide?"* — Nowhere, verified: `uninstall.sh:135` removes
   `/etc/sing-box/` wholesale; `install.sh:315` sweeps a fixed `CRED_FILES=(config.json nodes.json)`
   list, so `.config.sha256` is neither swept nor expected (correct — a hex digest is not a
   credential document); the only directory `bin/sc` enumerates is `RULES_DIR` (`bin/sc:893`), not
   `CFG_DIR`, so `_write_private`'s `.config.sha256.tmp.<pid>.*` temp cannot be caught by a stale
   sweeper.
6. *"Should I fix R-4 while I am in `_write_private()`?"* — **No**, and the architect's call is
   right. `os.fdopen(fd, "w")` at `bin/sc:344` has no `encoding=`, but the identical exposure already
   exists in `save_nodes()` (`bin/sc:384`, also `ensure_ascii=False`), so it is a pre-existing defect
   of `_write_private`'s contract, not of this task's. Fixing it changes `_write_private`'s behaviour
   inside a task whose gate is byte-identity. Report it as a new pool row at delivery; note that the
   drift record is immune because `_config_digest()` hashes the file's bytes.

## 7. Verdict

**APPROVED FOR DEVELOPMENT** — with eight conditions. No `BLOCKED`, no rollback: the central claim
survived a key-by-key walk against the source, every referenced symbol exists and behaves as claimed,
and each of the four flagged items (T-1, T-2, T-3, A-7) is ruled here rather than returned.

### Conditions binding on the developer

1. **No live-host action, ever.** `02` §7's "QA must exercise AC-20/AC-21 through `sc reload`, or
   with the service stopped" is to be read as: through the *neutralised module* in a `mkdtemp()`
   fixture. Never invoke `/usr/local/bin/sc`, never stop or restart the owner's `sing-box`, never
   write under `/etc`. Report `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` identical
   to `MainPID=2887037` / `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST` at every checkpoint.
   `02` §12 and §11 items 1/2/4 are binding verbatim; the `assert os.geteuid() != 0` and the "every
   repointed path is inside the temp root" assertion may not be weakened for any reason (F-5, F-6).
2. **Pin the baseline before the first edit.** Copy the current working-tree `bin/sc` to the baseline
   temp file *before* touching it, and record `git diff --stat -- bin/sc` in `04_DEVELOPMENT.md`. If
   it is non-empty, say so and say what the delta is — do not substitute `git show HEAD:bin/sc`. For
   AC-30's pristine comparison use a **clone**, never a `git worktree` (insight-index L22: a worktree
   turns A.1/A.2 SKIP and falsely reports 14/4). (F-4)
3. **Fresh fixture root per differential point**, or unlink `STATE_PATH` before each candidate run,
   and state which you chose. `02` §11 item 7's "only extra artifact" assertion stays. (F-2)
4. **Drive AC-26.** One `cmd_doctor` run against a fixture carrying a hand-modified `config.json`, a
   malformed `override.json` and no drift record; assert the fixture tree is byte-identical
   afterwards. (F-3)
5. **The `docs/dev-map.md` edit must record the `TUN_IFACE` exception** alongside `OVERRIDE_PATH` and
   `STATE_PATH`: the `# Paths` "repointable after import" contract no longer holds for `TUN_IFACE`,
   because `CONFIG_BASE` captures it at import. (F-1)
6. **Render `{directives}` as a readable joined string**, not a tuple repr, in keys 9 and 10. (F-7)
7. **Collapse newlines at the single render site** in `main()`'s handler, so NFR-7's one-line
   contract survives an override key containing a literal newline — `_plain()` removes `\r` and CSI
   sequences only (`bin/sc:1323-1325`). (F-8)
8. **Update open row R-12 in `docs/tasks.md` at delivery** to name `generate_config()`'s new
   `OverrideError` as a second unwind past `cmd_update_rules`' run-level outcome block. This is the
   price of the T-3 ruling. (F-9's §16 T-21 inaccuracy needs no fix and must not be re-litigated at
   stage 5.)

**Build order is not negotiable:** the differential harness and AC-4's non-vacuity proof first, the
literal move second. A green 64-run differential from a harness that was never shown to fail is worth
nothing.
