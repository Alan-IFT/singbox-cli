> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## Round 2 — F-2 re-measured, and mostly withdrawn

The PM refuted F-2's first premise with a measurement. I re-took it against the files rather than accepting the numbers, and the refutation holds. Under this project's T-07/CR-5 and T-22/BND-4 precedent, the finding is amended in place: the falsified clause is withdrawn, the surviving clause is re-worded and re-graded.

**What I measured.** ripgrep numbers `docs/tasks.md`'s last content line — `  same feature → build on the prior design rather than redesigning; conflicting decisions → flag.` — **300**. The anchors agree with the file viewer at 285 (`| R-90 |`), 289 (`Unnumbered:`), 294 (`## Conventions`), 296 (`- **ID**`) and 299 (`- Starting a task`), so no offset accumulates through the body; the two counters diverge **only at EOF**.

**Where my 301 came from.** The file viewer numbers the empty position *after* the file's final newline. It printed a bare `301` for `docs/tasks.md` — and, decisively, a bare `31` for `.harness/insight-index.md`, a file that is unambiguously 30 lines (28 non-empty by `grep -c '.'`, plus the two blank lines at 2 and 6, and the PM's `grep -c ''` = 30). One phantom on each file, at the same place, on a file whose true length is independently known: the artifact is the viewer's, not the repository's. `wc -l`, `grep -c ''` and F.4/F.5 never see that position. My round-1 count read the viewer's EOF marker as content.

**The operators and the exit code, read directly.** `verify_all.sh:216` is `if (( n > 30 ))` and `:224` is `if (( n > 300 ))` — both strict, so 30 and 300 land on the `else` arm and step PASS. `:248-250` is `(( errors > 0 )) && exit 2`, `(( warns > 0 )) && exit 1`, `exit 0`; with `warns == 0` the script exits **0**. `:242`'s `pass_count` greps the `report` array, whose records are `id|name|status` and whose names contain no "PASS". So today's `PASS 17 / WARN 0 / FAIL 0 / SKIP 1` is 18 steps, C-2 adds B.4 and B.5, and AC-1's `PASS 19 / WARN 0 / FAIL 0 / SKIP 1` with exit 0 is arithmetic on a measured baseline — derivable, and now discharged as all four numbers plus the exit code (BC-C).

**What survives.** Both cap files are at exactly their cap: 30/30 and 300/300, zero headroom. Stage 7 has two growth events. The `## Insight` harvest appends a line per insight to the index, so a clean F.4 depends on `archive-task`'s rotation firing — and insight-index line 29 is this project's own measured reason not to assume it does (`archive-task.sh:109-136` hoists non-bullet lines and can come back *shorter* with a marker moved, a loss that lands under the cap and passes F.4 silently). T-28's board rows already exist (285-292 and 133/173/193/209/238/240), so the row itself costs nothing; a **new ledger row** does. That is a real, presently-unowned hazard — but it is a housekeeping-ordering hazard whose remedy is rule 70's rotation, not a defect in AC-1 or in the design, which is why F-2 drops from MAJOR to MINOR and BC-C now demands the full four numbers instead of licensing an attributed-away WARN. The one addition BC-C makes is to record `archive-task`'s printed rotation count when it fires: T-27 closed R-18 on that rotation with a single run of its own, and this delivery is where the second independent confirmation is cheapest — it is a line of output already being produced, not new work.

Nothing else in this review is affected: F-2 was never load-bearing for any other finding or condition, and the verdict was never resting on it.

## Where rule 85's required test lives

`.harness/rules/85-design-discipline.md` makes stage 3's test of stage 2's smaller-design answer a required part of the review. Its **outcomes** are contract rows (F-8, BC-I); its **narrative** is below, per the `## Stage-doc boundary rule` in `.harness/rules/70-doc-size.md` and that rule's precedence clause. This is not a schema gap.

## The less-is-more test — "14 assertions instead of 7"

The design's claim is that seven fat assertions would let one clause's mutation mask its siblings. Tested directly: **does any of the 14 share a mutation with a sibling such that the pair should merge?**

I built the mutation table by reading each subject and asking, for each assertion, whether a mutation exists that kills **it alone**.

| assertion | private mutation | sibling that survives it |
|---|---|---|
| I-17 last-`@` | `rpartition("@")` → `partition("@")` | I-18/I-19 fixtures carry one `@` |
| I-18 first raw colon | `partition(":")` → `rpartition(":")` | I-17/I-19 fixtures carry no raw colon |
| I-19 decode-once | drop `unquote`, or apply it twice | I-17/I-18 fixtures carry no escapes |
| I-20 exact 0600 | delete `os.fchmod` | I-21 runs at the ordinary umask, where `mkstemp` already yields 0600 |
| I-21 replace, not write-through | resolve the target through `realpath` before `replace` | I-20's target is fresh, so `realpath` is itself |
| I-22 UTF-8 bytes | `encoding="utf-8"` → `"latin-1"` | I-20/I-21 write ASCII |
| I-23 UTF-16 refused by name | feed `read_bytes()` to `json.loads` (insight 16) | I-24's documents are UTF-8 |
| I-24 shape / default / `.path` | drop the `isinstance(doc, dict)` test; flip the `default is not None` arm; drop `.path` | I-23 raises at the decode |
| I-25 array key demands a directive | branch on the overlay value's type instead of the target's | I-26's override is a valid `$append` |
| I-26 fault clause is a class name | `type(e).__name__` → `str(e)` (AC-11) | I-25 never enters `generate_config` |
| I-27 secrets at every depth | mask by name only inside `outbounds` | I-28's pair sits inside `outbounds` |
| I-28 strict region + mask carries nothing | `strict or k == "outbounds"` → `k == "outbounds"` | I-27's secrets are masked by name regardless |
| I-29 `$prepend` non-empty and at the head | empty the payload (AC-12/R-80); `$prepend` → `$append` | nothing else composes a document |
| I-30 `zh` ⊆ key | introduce one offending `zh` string | nothing else reads `TRANSLATIONS` |

**Result: every one of the 14 has a private mutation; no pair should merge.** Two mutations *are* shared — "write in place instead of `mkstemp`+`replace`" kills I-20 and I-21, and "delete the `SECRET_KEYS` branch" kills I-27 and I-28 — but sharing is not the merge test; each of the four keeps a mutation that kills it alone. The 14 stands.

What the test *did* refute is the design's stated ground for it. The rationale argues that a fat assertion makes its other clauses look discriminating — but I-24 is itself a three-clause assertion, and it is non-vacuous precisely because RS-1 sweeps **one mutation per clause**, not one per assertion. So per-clause mutation, not assertion count, is what closes R-22; K-17's wording claims a stopping rule the design did not apply uniformly (F-8, BC-I). The granularity error, where there is one, is in the *smaller* direction, so rule 85 asks for no change to it.

**The three calls that went the smaller way**, tested for what they gave up:

1. **No `sing-box` stub; `SB_BIN` → a non-existent path.** Nothing lost. The only assertion that enters `generate_config()` raises at `bin/sc:1079` before the write and before the checker (PQ-6), and I-29 reaches the emitted position through `_compose([_dns_overlay, _telemetry_overlay])` rather than through a full generation. One line beats six *and* fails closed. Correct call.
2. **Path-attribute scan instead of eight named asserts.** Smaller and stronger for the case BC-2 names, but the "any future constant, by construction" claim is false for a `Path` held in a container — `PERIODIC_DIRS` is the standing counter-example, and `SB_BIN` is a `str` (F-5, BC-F). Narrow the claim, keep the scan.
3. **No `--min` in the suite; the floor stays in B.4.** Correct, and load-bearing: FR-15 puts the floor read in the step, and moving it into the artifact would let a miscounting suite decide whether its own miscount matters.

Whole-design comparison against T-07's standard holds on inspection: one file, no directory, no framework, no fixture library, no mock server, no runner, no second file, stdlib only, `TESTS` as data rather than discovery.

## Re-derivation of the two caps (R-61)

R-61 is addressed to this stage by name: T-07's gate declared a cap not credible and approved it anyway. Both of this task's caps were re-derived rather than accepted.

**Suite file (K-14).** The design's element table totals 303 and charges a blank line only inside the assertion budget ("~11 each incl. one docstring line and one blank"). Counting the top-level blocks the same table implies — header, the constants block, `load()`, `fixture()` + its predicate, `witness()` + its comparison, two shared helpers, `TESTS`, `main()`, the entry point — gives ~12 non-assertion blocks and therefore ~22 separator lines that no element carries. Honest floor **325**; at PEP 8's two blanks between top-level defs it is ~339. A 330 cap is 2 % over the first figure and *under* the second, which is T-07's failure shape (a cap unreachable by construction) in miniature. Amended to **350** — floor 325 plus ~7 %, and still above the two-blank case's own margin. The trim order in K-14 is untouched, and the burden of proof stays on the larger file.

**External budget (K-13).** "Added or changed lines" was never defined; under the only reading that binds (`+` lines in the diff) the allocation is wrong where it matters most. C-5's R-59 hunk replaces E3's seven-line arm with a six-line one and E4's seven with six — 12 added lines before R-56's two and R-58's one — against an allocation of 6. C-2's B.4 needs a `python3` guard, a `test_count` read, a captured run, a summary extraction and four distinct FAIL arms (~16), plus B.5 (~4), against an allocation of 18. Re-derived plan: C-2 20 / C-3 15 / C-4 3 / C-5 15 / C-6 12 / C-7 8 = **73**. Every line of it is mandated by FR-14 … FR-19 and RS-6 forbids dropping a clause to fit, so the cap moves: **80**, metric stated (BC-D).

## The safety spine — what I verified and what I did not accept

Verified structural, on the code:

- `bin/sc:125-126` is `if os.geteuid() != 0: os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])` — the shim's `geteuid → 0` does neutralise it without touching the source, exactly as `docs/dev-map.md:129-139` says.
- `bin/sc:3791` is `if __name__ == "__main__": main()`; `types.ModuleType("sc")` sets `__name__ = "sc"`, so the guard is False and `main()` is structurally unreachable. `_init_files()` is called only from `main()` (`:3757`), and its `/var/lib/sing-box` literal at `:543` is confirmed un-repointable.
- Module-level execution is inert apart from `shutil.which` at `:75-76`, which spawns nothing and is overwritten by `fixture()`.
- The `finally` restoration plus the two post-restore asserts (I-4, AC-9) cover BC-3's raising path; K-5's pre-import line closes the one leak the `finally` cannot.
- BC-2's assertion runs before the first assertion because `main()` calls `fixture()` once itself (I-5).

**Not accepted:** the recipe's inherited claim that it "fails closed if `geteuid` moves". It does not. The shim is a copy of the real `os.__dict__`, so the capability that did the damage in R-78 — `os.execvp` — is present and live throughout the load, and only the *predicate* guarding it is falsified. A refactor to `os.getuid()`, `os.getresuid()` or `os.geteuid() > 0` — none exotic — puts a password-less `sudo /usr/local/bin/sc` on the owner's live machine inside `verify_all`, forever. What happens then is R-78's signature: the process is replaced, the `finally` never runs, the `mkdtemp` root is never removed, and the run surfaces as an argparse usage error at exit 2 that reads like a harness bug. It fails red rather than green, which is why F-1 is MAJOR-with-condition rather than a rollback — but "this step imports `bin/sc` on the live host on every future run, forever" is this task's own red line, and a capability defence costs less code than the predicate defence it strengthens.

## Non-vacuity, read recursively (R-22)

I looked for vacuity beyond the three declared points. The three declarations are honest, not excuses: RS-3 (I-26's third clause implied by its second on the chosen fixture) is a clause-level statement inside a discriminating assertion; RS-4 is measured against insight-index lines 14/22 — a missing `encoding=` is invisible on a UTF-8 host, which is why the sweep must use codec substitution; assertion 14 has no current subject, which I confirmed rather than accepted (PQ-3), and remains mutation-reachable.

No **undeclared** vacuity was found. The two candidates I probed both discriminate: I-23 is killed by the `json.loads(bytes)` mutation (insight 16 is the evidence that only the explicit `.decode("utf-8")` produces the refusal), and I-29's `_aaaa_rule(True) != _aaaa_rule(False)` assertion is what stops its two-decision loop agreeing with itself. I-20's control — a bare `mkstemp` in the same directory reading 0400 at umask `0o277` — is the strongest single piece of design here: it makes `os.fchmod`'s load-bearingness observable rather than argued.

## Verified good, worth carrying

- The whole of `_userinfo`'s three-projection contract checks out against `bin/sc:692-695`, including the non-derivability of `whole` from `(first, rest)` (`pw:` and `pw` both give `("pw", "")`).
- `_merge`'s array branch is taken on the **target's** type at `bin/sc:1476`, so I-25's four values all raise the one vocabulary sentence — as designed.
- `_redact`'s `strict or k == "outbounds"` at `:3101` is the exact line I-28's private mutation targets.
- The `$prepend`/`$before` interaction I-29 relies on matches insight-index line 26 measurement for measurement: telemetry's rule lands at index 2 and leaves the AAAA rule at index 0.
- E5's verdict expression at `restricted-network-regression.sh:273` is the shape I-16 mirrors, and absorbing the old `nolog` arm into the conjunction as `[ "$nolog" -eq 0 ]` preserves BC-10's mandated `E3 FAIL` — Q-6's ruling is implemented correctly.
- The migration order is genuinely load-bearing, not decorative: C-4 before C-2 is what stops B.4 passing against a `0` floor, and step 5's "run the self-check **before** the edit" is the attributable-baseline discipline BC-C now asks for on `verify_all` as a whole.
- `verify_all.sh` is green at HEAD and its two doc-size caps are met exactly — measured twice, once by the PM and once here against the files (see the round-2 section). The pre-edit baseline AC-1 names is real, which is what lets BC-C demand all four numbers rather than an attribution.

## Two things stage 6 should expect to be annoying

`AC-13`'s "`baseline.json` absent" case and `AC-8`'s "delete one `PATHS` row" case both mutate the working tree; taken in the wrong order they contaminate AC-15's `git diff` and AC-22's regex sweep. And AC-5 is the one criterion whose green depends on a process this task does not control — see F-7/BC-H; observe it once with the service live, so that a later flake is recognised as the service writing its cache rather than as a regression in the suite.
