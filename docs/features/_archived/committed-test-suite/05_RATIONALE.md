> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Ruling 1 — CR-1 closed: the enumeration checked, and what the control proves

**The tuple, checked against `dir(os)` rather than against stage 4's word.** Delivered: `name.startswith(("exec", "spawn", "fork", "popen", "posix_spawn", "system"))` at `check-sc-contracts.py:107`. CPython's `os` on POSIX exposes exactly these process-start names:

| family | names | matched by |
|---|---|---|
| replace this process | `execl execle execlp execlpe execv execve execvp execvpe` | `"exec"` |
| start a child | `spawnl spawnle spawnlp spawnlpe spawnv spawnve spawnvp spawnvpe` | `"spawn"` |
| clone this process | `fork forkpty` | `"fork"` |
| shell | `system` (the only `system*` name — the prefix over-denies nothing), `popen` (runs `/bin/sh -c`) | `"system"`, `"popen"` |
| modern spawn (3.8+) | `posix_spawn posix_spawnp` | `"posix_spawn"` |
| Windows only | `startfile` | **nothing** → CR-10 |

Nothing else in `os` starts a process: `kill`/`abort` end one, `pipe`/`openpty`/`register_at_fork` start none. So the header's `Covered:` sentence at `:24-25` is **true as written on this platform**, which is the condition round 1 attached to accepting BC-A's declared `subprocess`/`ctypes` limit — that acceptance therefore now stands unconditionally. One second-order benefit I checked rather than assumed: denying `popen` cannot break the load, because `bin/sc`'s module body reaches only `shutil.which` (`bin/sc:75-76`) and `shutil` was imported at `:41`, before the shim existed, so it holds the real `os`.

**Does the control mean what it claims?** Yes, and it is the right shape. Stage 4 re-ran the *same* `posix_spawn` scratch copy under the *round-1* filter and got `FileNotFoundError`. That exception can only come from the real `os.posix_spawn` executing and failing at the kernel's path lookup — i.e. the denial did not fire and the only thing that stopped a process being started was that the target path did not exist. Under the delivered filter the same copy raises `LoadRefused`, a **different class from a different raiser**. Two runs, two distinguishable outcomes, one variable changed: that is a control, not a re-assertion. It also retires the "CR-1 was theoretical" reading — the hole was reachable by a one-line refactor of `bin/sc`'s elevate guard, which is exactly BC-A's forward guarantee and exactly what R-78 already did once on this machine.

**On CR-10's severity.** I am not raising the Windows gap above NIT, and the reason is not indulgence: `bin/sc` is a Linux CLI (systemd/OpenRC, POSIX modes, `os.geteuid`), `verify_all.ps1:90-93` SKIPs B.4 with "Linux-only by subject", and on Linux `startfile` is not in `dir(os)` at all, so the loop cannot shim it and no run is affected. What is affected is a *sentence* — "EVERY process-start name in `dir(os)`" — and the whole point of CR-1 was that a false sentence beside a true mechanism is what a future author trusts. One token in the tuple costs nothing on POSIX and makes the sentence unconditional; scoping the sentence to POSIX is equally honest. Either is fine; neither blocks.

## Ruling 2 — CR-2, CR-3, CR-7, CR-9 closed, and what the rework could have broken

**CR-2.** `_execute` `:377-405`. On the load/fixture-failure path it prints the two report lines, sets `selected, loaded = (), False`, and falls through. Three things I checked rather than accepted:
- `sc` is unbound on that path, and the `for fn in selected:` body over `()` never evaluates `fn(sc)`. No `NameError`.
- the summary still renders `14 defined, 0 run, 0 passed`, which `verify_all.sh:88`'s **anchored** `sed` (`^summary: … $`) matches, so B.4 extracts `0`, and both `b4_rc -ne 0` and `0 < 14` FAIL the step. B.4's floor comparison and BC-10 are unchanged.
- exit 2 survives on every failure path: `if not loaded: return 2` (`:403-404`), root refusal `:413`, unknown name `:432`, `rmtree` failure `:444`, and `main()`'s `rc = 2` initialiser (`:436`) covers a raise out of `_execute` before the assignment. The only ordering consequence is the one recorded as RES-7.

**CR-3.** `:137-142` reads `!= root and not startswith(root + os.sep)` — inside ⟺ equal-or-under, no subsuming alternative, and stage 4's re-taken scratch run (delete the `IF_INET6_PATH` row → `fixture failed  AssertionError: Path constant(s) outside the run root: IF_INET6_PATH`, 0 run, exit 2) exercises the reworked predicate, not the old one.

**CR-7 / CR-9 / CR-4.** All 14 `TESTS` docstrings are single-line and end in a full stop, so `fn.__doc__.splitlines()[0]` (`:421`) truncates none; `dev-map.md:146` carries `encoding="utf-8"` inside the copy-pasteable block; `dev-map.md:151-161` names nine constants and identifies `IF_INET6_PATH` and `LIB_DIR` as the two outside `/etc/sing-box` — both verified at `bin/sc:64` and `bin/sc:43`, and `LIB_DIR`'s single reference at `bin/sc:3549` is inside a function body, which is what makes it repointable and what makes `dev-map.md:33`'s "eight" the stale number (CR-11), not the recipe's "nine".

**What the rework could have broken, checked.** `load()` `:99-122`: euid gate still first and still ahead of `open` — the denial loop was moved, not the gate. `fixture()` `:125-143`: the repoint still precedes the scan and the preflight call at `:382` still runs before any assertion. `witness()` `:146-174`: untouched, asymmetry docstring intact. `verify_all.sh`: the PM's `--numstat` of **21/0** is itself the byte-identity proof for AC-15 — a pure insertion cannot have altered B.1/B.2/B.3, and the 21 lines sit at `:78-98` between the markers at `:48` and `:99`. `dev-map.md` at +34/−15: every added line traces to CR-1 (`:130-137`), CR-4 (`:146`), CR-9 (`:151-161`) or previously-approved C-6 content (`:22-27`, `:86`, `:87`), and BC-B's narrowing survived the rewrite — "fails closed if `geteuid` moves" is still absent, replaced by "What it guarantees and what it does not".

## Ruling 3 — the cap, re-derived once more (CR-5)

Round 1 measured a 429-line binding floor under a 446-line file and amended BC-E to 450. The rework added 3 lines, and all three are lines **this review demanded**:

| region | round 1 | round 2 | why the floor moves with it |
|---|---|---|---|
| header docstring | 36 (floor 30) | 38 (floor **34**) | the enumeration of the denial set and "the denial is by NAME, so this enumeration IS the guarantee" are CR-1's fix; they cannot be recovered without re-falsifying the sentence |
| `load()` | 26 (floor 24) | 24 (floor 24) | the denial collapsed from three lines to two; nothing recoverable left |
| `fixture()` | 19 (floor 19) | 19 (floor 19) | CR-3's predicate cost 0 net |
| `_execute` | 29 (floor 29) | 29 (floor **29**) | same line count, strictly more required content (CR-2's fall-through + its two-line WHY comment replaced the early return) |
| all other regions | 336 (floor 327) | 339 (floor **326**) | unchanged text, re-tallied at the new offsets |
| **total** | **446 / 429** | **449 / 432** | recoverable ≈**17**, i.e. **3.8 %** — identical in proportion to round 1 and to T-07's precedent |

So the delivery is inside the cap I set and there is no drift to report. The problem is what a 450 cap over a 449-line file now *means*: it constrains nothing except the next required clause, and it would fire on a change that is not a defect — the same provenance failure R-61 names, one turn further on. A cap's job changes once the artifact exists: before delivery it is an estimate of an unwritten file (falsified at 303, at 325/350, and re-derived at 450); after delivery it is a maintenance ratchet and its natural derivation is measured, not guessed. **465** = floor 432 + one assertion at the file's own measured mean (13.6 lines, from 190 lines over 14 assertions) + its two separators. I believe that number, I demand no trim to reach it, and RES-1 carries it so the next task inherits a measurement rather than a third guess.

CR-6's arithmetic, re-taken off the PM's `--numstat`: 21 (`.sh`) + 8 (`.ps1`) + 0 (`baseline.json`) + 0 (`restricted-network-regression.sh`, `+20/−20`) + 19 (`dev-map.md`) + 2 (`50-singbox-cli.md`) = **50 net** against the restated 60. C-6's growth from +15 to +19 net is CR-1/CR-4/CR-9 work, traced line by line. Nothing to fix.

## Ruling 4 — D-6: two entries, and the one sentence that must not travel (CR-12)

**Read, not inferred.** `CONTEXT.md:189-196` is the **state document** entry; `:198-204` is **assertion floor**; `:206-211` is **contract suite**. Both new entries follow the file's established shape (bold term, definition, `_Avoid_:` line), both are project-specific as the file's own preamble (`:6`) requires, both are accurate — the assertion-floor definition matches `verify_all.sh:83-92`'s actual behaviour (a floor, a ratchet, read by a gate) and the contract-suite definition matches the delivered CLI including the `--source` parameter. Rule 70's caps table names no cap for `CONTEXT.md`, and `verify_all`'s `F.*` group does not measure it, so **+15 lines breaks nothing**; it is correctly declared outside the C-2 … C-7 budget, exactly as C-8's own row was.

**The verdict on the declaration.** Two entries at +15 is acceptable and now honestly declared. What is not acceptable is the *cause* D-6 gives: "design and gate both cite a line range that carries the *state document* entry" is false against the file as it stands (`:198-204` **is** the assertion-floor entry) and false against history — per `PM_LOG.md` decision #2, stage 1 of this task wrote that entry (+8 lines), so PQ-2 read the working tree correctly and stage 4's `git show HEAD:CONTEXT.md` was simply looking at a commit that predates its own task's stage 1. Both entries are this task's own work; no upstream document erred; nothing was written twice (there is exactly one entry per term). Left as written, D-6 would tell a future document-citing gate that a stage-3 citation was fabricated, which is a worse defect than the one it is trying to declare — hence CR-12 at MINOR and RES-10 as the delivery sentence.

Nothing in `CONTEXT.md` needs to change.

## Ruling 5 — the R-22 non-vacuity table re-checked against the reworked file

The 14 assertion bodies (`:177-361`) are **byte-unchanged** from round 1 — I re-read each and matched it against the private-mutation table in `03_RATIONALE.md`. All 14 mutations still kill: `rpartition`→`partition` on `"a@b@h"`; `partition`→`rpartition` on `"u:p:q@h"`; dropping/doubling `unquote` on `%3A`/`%2540`; deleting `fchmod` under `umask 0277` against the `mkstemp` control; resolving through `realpath` before `replace` (link gone, victim still `0644`); `encoding="utf-8"`→`"latin-1"` on `"节点 ✓"` (RS-4: **not** killed by deleting `encoding=`); feeding `read_bytes()` to `json.loads` (with the in-line `json.loads(raw) == {"nodes": []}` pre-assertion proving the fixture discriminates); the three `_read_state` shape/default mutations; type-branching on the overlay value instead of the target (killed by the **bare array** fixture); `type(e).__name__`→`str(e)` against the exact `t(...)` rendering; masking by name only inside `outbounds` (secrets at depths 1-3 under `log`); a non-sticky `strict` (`tls.nested` two levels down) plus the inverse killed by the top-level `"unlisted"` staying verbatim, and the length-pair clause killing a mask that carries a digest; emptying `$prepend` / `$prepend`→`$append`, composed against `_telemetry_overlay()` with `_aaaa_rule(True) != _aaaa_rule(False)` closing the vacuous agreement; and one offending `zh` entry.

The `_execute` change cannot have damaged this: a failing assertion still prints `FAIL` and still does not increment `passed` (`:392-396`), and the loaded path's exit expression `0 if selected and passed == len(selected) and not changed else 1` (`:405`) is untouched — so a mutation-killed assertion still lands as exit 1 and a B.4 FAIL. A mutation that makes the clone unloadable now lands as exit 2 with `0 run` and the after-witness taken, which is a **more** informative kill than round 1's early return.

The systemic caveat from round 1 stands unchanged: `fixture()` sets `sc.LANG = "en"` and `TRANSLATIONS` has no `en` table, so the sentence assertions compare against `t()`'s key — which kills a changed message but is blind to a mutation that breaks only the `zh` rendering. Assertion 14 is the only `zh`-facing guard and it guards placeholders, not wording.

## Notes carried forward, unfiled

- Round 1's requirement-coverage table **omitted AC-4** (root refusal precedes the load). Corrected this round: `:410-413` is `main()`'s first statement and `:101` is `load()`'s first, ahead of `open(src)` at `:115`. The criterion was met all along; the omission was mine, and it is recorded here rather than silently repaired so the coverage table's exhaustiveness claim stays auditable.
- `verify_all.sh:96-97` still relies on `$?` after a command-substitution assignment on the previous line. Correct in Bash; B.4's same-line `; b4_rc=$?` is the sturdier form. Unchanged this round, still not filed — it is the shape of the surrounding file.
- `.harness/rules/50-singbox-cli.md:47` reads "Minimum manual verification for any change, **until B.2/B.3 are real**", which is stale since T-11 (B.2 is real, and `:36-40` in the same file says so) and now doubly so with B.4/B.5 wired. Pre-existing, outside this task's hunks, not required by AC-23 — recorded here so a later task can retire the clause rather than re-discover it.
