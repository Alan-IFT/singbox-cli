# 01 — Rationale · T-24 `override-error-envelope`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## Method, and its one honest limit

**This stage holds no `Bash` tool.** Every claim below was verified by reading the shipped source and
the archived stage documents, not by running anything. Where a clause can only be settled by a run it
is marked **[needs a run]** and routed to stage 4 or 6 — it is never dressed up as measured. Nothing
was inherited: each clause of the brief was re-derived from `bin/sc` at the current working tree.

Backward-looking evidence keeps `path:line` citations, per `.harness/rules/05-insight-index.md`.
Forward-looking requirement prose in the contract carries none, per the analyst contract.

## Clause-by-clause disposition of the brief

| brief clause | disposition |
|---|---|
| R-15(a): a 500-level override makes `copy.deepcopy` raise `RecursionError` | **Survived, structurally.** `_merge` reaches `target[key] = copy.deepcopy(value)` (`bin/sc:1461`) on the first key of `{"a":{"a":…}}`, since `a` is absent from the base; `copy.deepcopy` recurses ~2 Python frames per level. The 2 999-line / 135 KB figure is T-14's measurement (`06_TEST_REPORT.md:362-378`), not re-measured here. **[needs a run]** for the numbers. |
| R-15(b): a non-object element in `dns.rules`/`route.rules` reaches `AttributeError` | **Survived.** `_filter_rules` calls `rule.get("rule_set")` with no shape test (`bin/sc:1065`), reached for both arrays (`:2097-2098`). Insertion is verbatim by design (`_apply_directive` has no edge back to `_directive_of`), so `{"dns":{"rules":{"$append":["oops"]}}}` puts a string there. `route.rule_set` is **not** exposed — its comprehension is guarded by `isinstance(d, dict)` (`:2093`). |
| R-15: both instances contained — no write, no service action, non-zero exit | **Survived.** Both raise before `_write_private` (`:2104`); `restart_service()` is reachable only from `reload_or_restart()` after `generate_config()` returns. |
| R-15's two forbidden fixes | **Consistent and non-empty.** With the assertion not widened, `_filter_rules` untouched, and R-44 forbidding a cap, the only admissible shape left is the envelope — which is why R-15 named it. No constraint is crossed; none needed to be. |
| R-16: `{"inbounds":{"mtu":1500}}` silently replaces the TUN inbound array | **Survived.** `_merge`: the value is a dict, `_directive_of` returns `None`, `isinstance(target.get("inbounds"), dict)` is false because it is a list, so `target[key] = copy.deepcopy(value)` (`bin/sc:1458-1461`). |
| R-16's counter-weight: "the binary already catches it, so how much vocabulary is owed?" | **REFUTED — this is the load-bearing refutation of the brief.** See "The counter-weight is false" below. |
| R-16: an object keyed `"0"` does not address array element 0 | **Survived**, and it is *already named today* — replacing `dns.rules` with `{"0":{…}}` trips the composed-document assertion (`:2081-2085`), so M7's value is that FR-3 catches it *earlier* and with a message naming the directives. |
| R-26: provenance structural at two of three sites | **Survived.** The load (`:2036-2040`) and the user's merge (`:2069-2074`) are structurally the user's document. The assertion (`:2081-2085`) runs unconditionally and sets the override path from a comment's argument. `docs/dev-map.md:38` publishes the stronger claim for all three; it is false for the third. |
| R-26: "zero behavioural cost" | **Survived on reachable inputs, refined.** All three `sc` overlays leave the three arrays as lists (`_runtime_overlay` `$replace`s two, `_dns_overlay` `$prepend`s, `_telemetry_overlay` `$before`s or returns `{}`), so the assertion cannot fire without an override. **But** gating it *alone* turns the unreachable case from a mislabelled sentence into a traceback (a dict at `dns.rules` iterates to strings → `AttributeError`; a scalar → `TypeError`). Gate and envelope must land together. |
| R-44: D-2's premise false on CPython; C scanner budget ≠ Python recursion limit | **Survived as stated**, and it matters more than R-44 thought — see Q-8 and "A third instance of R-15" below. |
| R-44: "reachable only by a hand-edited **or `override.json`-supplied** document" | **REFUTED in its `override.json` half.** Every container an override contributes reaches the document through `copy.deepcopy` (`:1423`, `:1428`, `:1430`, `:1431`, `:1461`, `:1474`); the only unguarded assignment is `target[key] = value` (`:1476`), reachable for non-container values only. `copy.deepcopy` costs ~2 frames per level, the masking walk ~1 — and the two existing independent measurements match that ratio (T-14: overflow between 490 and 500; R-44: depth 990 renders fine). So a document deep enough to overflow the masking walk cannot survive the merge. **[needs a run]** to confirm the ratio. This is why BC-8 forbids raising the recursion limit: that bound is currently doing R-44's work for free. |
| R-44: no cap should be added | **Adopted as a bound**, out-of-scope 2 and 6. |
| R-69: `_unusable()` is the single construction site; `main()`'s arm must keep honouring `e.path` | **Survived.** `_unusable` (`:541-545`) is the only place a state document's failure is constructed; the arm renders `e.path or CFG_PATH` (`:3713-3715`). Four other `except OverrideError` sites exist (`:436`, `:595`, `:2038`/`:2072`, `:2791`) and none is affected by this task. |
| R-69: the two readers differ in **three** policies | **REFUTED — there are five.** `_load_override` (`:1500-1540`) carries: `os.stat` before any `open()`; `stat.S_ISREG`; dangling-symlink-as-malformed (BC-27); the cap enforced on the read rather than on `st_size`; and whitespace-or-zero-byte as absent. `_read_state` (`:548-569`) carries none of them. Moot in practice — out-of-scope 7 declines the collapse — but the count should not be carried forward wrong. |
| R-12 as narrowed by T-19's Q-2 | **Survived, and not closed here.** The envelope adds no run-level outcome line; it moves shapes *into* the population that lacks one. |
| T-14: deep-copy discipline at all eight overlay entry points; B-7 structural | **Survived**, re-read at `_apply_directive` and `_directive_of` (`:1357-1431`). BC-7 forbids the new envelope creating the edge. |

## The counter-weight is false — why R-16 is owed after four declines

T-14's `06` measured the mirror to be loud (`sing-box` 1.13.15 returns `rc=1`, `sc reload` fails in
the same invocation, the service is never restarted) and `01` §12.4 O-12 declined the fix on that
ground. Re-reading `generate_config()` shows what that assessment did not state:

```
bin/sc:2104   _write_private(CFG_PATH, json.dumps(config, ...))    # the broken document lands
bin/sc:2109   _record_generated()                                  # its digest becomes the baseline
bin/sc:2111   subprocess.run([SB_BIN, "check", ...])               # only now is it rejected
```

So for the whole R-16 population the binary's rejection arrives **seven lines after the previous
working `config.json` has been replaced** and **two lines after its digest was recorded as "what `sc`
last wrote"**. Three consequences, none of them stated in T-14's assessment:

1. The user's previously valid configuration is gone. The running service survives only because it
   holds its configuration in memory; the next boot or restart starts `sing-box` against the broken
   file.
2. The drift machinery reports the broken document as pristine, because the baseline is its own
   digest — so `sc config`'s provenance line will not flag it either.
3. The message the user gets is the checker's schema complaint, which names a sing-box field, not the
   user's mistake.

And the promise is already published, in both languages at the same line:

- `README.md:378` — "One that cannot be applied stops the command **before anything is written**:
  `config.json` is left exactly as it was, the running service is not touched, and the message names
  the file and the problem."
- `README.zh-CN.md:378` — the same sentence.

That sentence is **false today** for M4–M7 (the command writes) and false for M0–M3 (there is no
message, only a traceback). So this task does not add a promise; it makes a shipped one true. That,
rather than "silent versus loud", is why the vocabulary is owed after four declines. It also settles
Q-2 without re-litigating D-5: D-5's rationale rested on the wrong result being *valid and silent*,
and the mirror's wrong result is indeed neither — but "invalid and loud" was never the same thing as
"harmless", and the write ordering is what makes the difference.

Rule 85 check: the fix is one clause, not four. `_merge` already refuses a bare array over an
existing array with a sentence naming the directives; FR-3 makes that the rule for *every* non-directive
value at an array key. The array-position arm and the object-position arm then mirror each other
exactly, and the vocabulary costs **zero new translation keys** (NFR-1). A per-shape guard set would
be the 修修补补 shape the rule forbids, and AC-5's same-sentence clause is what makes the difference
observable rather than asserted.

Why the object position stays out (out-of-scope 5): there is no measured symptom, no README promise
about it, and the meaning of `{"experimental":{"cache_file":null}}` is unresolved — `null` is the only
way an override can clear a key today, and the merge's own comment records that deliberately
("scalars, JSON null included", `bin/sc:1476`). Extending the rule there would risk a legitimate
idiom for a case nobody has hit. At the array position `null` is safe to refuse, because clearing an
array wholesale already has a spelling: `$replace` with `[]`.

## A third instance of R-15 that no row records

`_load_override()` catches `ValueError` around `json.loads` (`bin/sc:1534-1537`). CPython's JSON
scanner signals depth exhaustion with `RecursionError`, which is **not** a `ValueError`, so an
override deep enough to exhaust the scanner's budget escapes the load's own enumeration as a
traceback — before `_merge` is ever reached. T-14's 500-level fixture sat below that budget and hit
`copy.deepcopy` instead, which is why the family was filed with two members. With
`OVERRIDE_MAX_BYTES` at 1 MiB a document of ~175 000 levels fits comfortably inside the cap, so the
case is constructible. This is M0, and it is the whole reason FR-2 puts the load inside the envelope
rather than only the merge. **[needs a run]** to confirm the exception class and the threshold, which
is interpreter-version dependent — which is also why no acceptance criterion pins a depth *number*:
a fixture must be built relative to the interpreter's own limits, not to 500.

## Candidates weighed, and what beat them

**Q-3, the width of the vocabulary.** Candidates: (a) array position only, one sentence; (b) array
*and* object positions — "a container is never replaced by a value of a different kind"; (c) a full
type-compatibility table between overlay and target. (b) is the more honest abstraction and only a
little larger, but it makes `null`-over-object an error and that is the one clearing idiom the merge
deliberately supports; (c) is a taxonomy the goal statement forbids by name. (a) wins on rule 85's
tie-break *and* on the counter-rule: it is the smallest statement that covers every measured symptom
and it deletes a special case rather than adding one.

**Q-8, the envelope's extent.** Candidates: (a) the merge call only; (b) load + merge + the
override-dependent steps up to the write; (c) the whole of `generate_config()`; (d) `main()`'s arm
widened to catch `Exception`. (a) leaves M0 a traceback. (c) and (d) would blame the user's document
for a write failure and for the checker's own faults, both of which already have correct, tested
renderings that must not be disturbed — and (d) additionally makes every command's every defect read
as an unusable-document sentence, which is the exact failure the class's own docstring was written to
prevent (`bin/sc:1227-1229`). (b) is what FR-2 states.

**Q-9, provenance under an envelope.** Candidates: (a) decide by exception class (a taxonomy — out of
scope); (b) decide by whether an override was supplied; (c) always name `config.json`. (c) is a
regression against T-14's whole provenance design. (b) makes the property structural in the same way
R-26 wants for the assertion — which is why R-26 and R-15 are one design and not two, and why AC-7
can kill a build that has the gate without the envelope.

**Rejected as scope-widening:** enveloping `cmd_config`'s masking walk (R-44 says no machinery);
adding a depth or node cap (R-44, BC-10 and T-06 D-2 all against); collapsing the two JSON readers
(R-69's five policies); repairing the run-level outcome line (R-12's owner is elsewhere).

## Related historical work

- **T-14 `config-composition-layer`** — `docs/features/_archived/config-composition-layer/`. The
  layer this task puts an error model over. `01_REQUIREMENT_ANALYSIS.md` §12.4 (O-11/O-12, where
  R-15 and R-16 were filed), AC-8, `02_SOLUTION_DESIGN.md` §5.3/§6 and D-5, `05_CODE_REVIEW.md`
  MINOR-1, `06_TEST_REPORT.md` D-2 and §8 O-5. Its byte-identity harness is the precedent AC-1 and
  AC-4 reuse.
- **T-23 `state-file-io-contract`** — `docs/features/_archived/state-file-io-contract/`. Source of
  R-69; `02_RATIONALE.md` §1 states the three obligations RT-1/RT-2 carry.
- **T-06 `sc-config-show`** — source of R-44 and of gate answer D-2, and of the standing decision that
  `sc config` is always redacted.
- **T-21 `proxy-urltest-group`** — R-54, the fourth decline of R-16.
- `docs/tasks.md` rows R-12, R-15, R-16, R-26, R-44, R-54, R-69; `.harness/rejected-decisions.md`
  holds no record touching this scope, so nothing is being re-litigated.
- `.harness/insight-index.md`: all six surfaced entries were applied — `_init_files()`'s hard-coded
  `/var/lib/sing-box` and the `main()` language reassignment shape BC-12 and BC-13; the `verify_all`
  cwd trap shapes AC-13; the two locale entries and the `json.loads`-accepts-bytes entry are recorded
  as **not applicable** here, because this task adds no locale dimension and no new decode site — and
  the recursion fixtures are deliberately built on interpreter limits, never on `LC_ALL`.

## Re-homed findings — rows for the PM, not absorbed here

1. **An existing error message echoes user-supplied object content into a captured stream.**
   `_anchor_index` interpolates `json.dumps(match, …)` into its sentence (`bin/sc:1398-1402`), and
   `main()`'s arm writes that to stderr, which `install.sh` redirects into
   `/var/log/sing-box/install.log`. No credential `sc` itself writes can appear in an anchor, but an
   anchor is arbitrary user JSON. Fixing it edits a T-14 message this task does not otherwise touch;
   BC-4 confines the ban to sentences this task introduces or newly reaches.
2. **`docs/dev-map.md:63` cites R-16 for a different gap.** Its parenthetical attaches "R-16 is open
   and unclaimed" to the absence of an *additive* directive that composes with `$replace`d
   `outbounds` — a capability gap R-16 does not state. When R-16 closes, that parenthetical must not
   be read as closed with it.
3. **The drift record baselines a document the checker then rejects.** `_record_generated()` runs
   before `sing-box check` (`bin/sc:2109` vs `:2111`), so any document that reaches disk and fails the
   check is recorded as "what `sc` last wrote". This task removes only the `sc`-detectable slice
   (FR-3); the NaN/schema slice T-14's `06` accepted under its D-2 envelope remains.
4. **R-12's population widens under this task** (Q-6). Worth noting on R-12's row so the next owner
   sees that the sentence-and-exit path now serves more shapes.

## What a rework round would need

None so far. If a later stage refutes Q-2's write-ordering argument by measurement — for instance if
a run shows `sing-box check` failing before `_write_private` on some path — the contract's Q-2 and
BC-1's M4–M7 members are the units that change, and the change is made in place with the round
record returned to the PM.
