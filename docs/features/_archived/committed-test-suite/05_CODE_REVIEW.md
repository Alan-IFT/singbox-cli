> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

# T-28 · committed-test-suite — Code Review

## Files reviewed
- `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` (new, **449** lines — re-read in full this round)
- `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` (re-read in full: markers `:48`/`:99`, B.1-B.3 `:52-77`, B.4/B.5 `:79-98`)
- `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.ps1` (`:70-99`)
- `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json`
- `/home/alan/Programs/singbox-cli/.harness/scripts/restricted-network-regression.sh` (`:25-109`)
- `/home/alan/Programs/singbox-cli/docs/dev-map.md` (re-read in full — the only doc file whose diff changed this round, +34/−15)
- `/home/alan/Programs/singbox-cli/.harness/rules/50-singbox-cli.md` (`:20-58`)
- `/home/alan/Programs/singbox-cli/CONTEXT.md` (`:1-60`, `:180-221` — both new glossary entries)
- `/home/alan/Programs/singbox-cli/bin/sc` (unchanged; read as the subject — `:1-140`, `:3549` for `LIB_DIR`)
- `/home/alan/Programs/singbox-cli/.harness/rules/70-doc-size.md` (caps table + `## Stage-doc boundary rule`)
- Upstream: `01_REQUIREMENT_ANALYSIS.md` (`:181-204`, the full AC list), `02_SOLUTION_DESIGN.md`, `03_GATE_REVIEW.md` + `03_RATIONALE.md`, `04_DEVELOPMENT.md` (round-2 text). `02_RATIONALE.md` reached under T5.1 for the line budget; `04_RATIONALE.md` under T5.2 for D-1/D-2/D-4/D-6; both present. D-6's provenance was supplied by the PM from `PM_LOG.md` decision #2 and was **also verified by reading** (`CONTEXT.md:198-204`).

## Findings

| id | severity | axis | file:line | finding |
|---|---|---|---|---|
| CR-1 | **RESOLVED** (was MAJOR) | Spec/design-fidelity | `check-sc-contracts.py:106-108`, `:18-25`, `docs/dev-map.md:130-137` | **Closed, verified independently.** The tuple is now `("exec", "spawn", "fork", "popen", "posix_spawn", "system")`. Checked name by name against CPython's `os` on POSIX: `exec{l,le,lp,lpe,v,ve,vp,vpe}`, `spawn{l,le,lp,lpe,v,ve,vp,vpe}`, `fork`, `forkpty`, `system`, `popen`, `posix_spawn`, `posix_spawnp` — **every** POSIX process-start name is now matched, and `"system"` as a *prefix* over-denies nothing (`system` is the only such name). The header sentence at `:24-25` is true as written on this platform, and `:18-23` now enumerates the list and states that the enumeration *is* the guarantee. `dev-map.md:130-137` carries the same list plus "A name prefix is not a capability either". Stage 4's control run is valid and discriminating — see `05_RATIONALE.md` ruling 1. Residual limit on Windows only: **CR-10**. |
| CR-2 | **RESOLVED** (was MINOR) | Spec/design-fidelity | `check-sc-contracts.py:386-388`, `:397-405` | **Closed.** `_execute` sets `selected, loaded = (), False` and falls through; `sc` is never dereferenced on that path (the `for` body over `()` does not run), the after-witness and the `changed` loop execute, the summary still renders `14 defined, 0 run, 0 passed` — byte-compatible with B.4's `sed` at `verify_all.sh:88` — and `if not loaded: return 2` preserves exit 2. BC-5 now holds on both exit paths, which is BC-5 as written. |
| CR-3 | **RESOLVED** (was MINOR) | Standards-conformance | `check-sc-contracts.py:137-142` | **Closed.** The predicate is `str(v.resolve()) != root and not str(v.resolve()).startswith(root + os.sep)`, i.e. inside ⟺ equal-or-under. No dead alternative, and a sibling root sharing the prefix now answers "outside". |
| CR-4 | **RESOLVED** (was MINOR) | Standards-conformance | `docs/dev-map.md:146` | **Closed.** The copy-pasteable block reads `exec(compile(open("bin/sc", encoding="utf-8").read(), "bin/sc", "exec"), sc.__dict__)`; the prose clause at `:169-171` still states R-77's reason. Block and paragraph now agree. |
| CR-7 | **RESOLVED** (was NIT) | Standards-conformance | `check-sc-contracts.py:312` | **Closed.** The docstring is one line; all 14 `TESTS` docstrings are single-line and end in a full stop, so `--list` truncates none. At 94 columns it is within the file's own observed range (`:227`, `:304`, `:314`, `:316` are 93-95) and no column cap is documented in this repo. |
| CR-9 | **RESOLVED** (was NIT) | Standards-conformance | `docs/dev-map.md:151-161` | **Closed.** The recipe names **nine** constants including `LIB_DIR` and names the two outside `/etc/sing-box` (`IF_INET6_PATH` = `/proc/net/if_inet6`, `LIB_DIR` = `/usr/local/lib/singbox-cli`) — both verified at `bin/sc:64` and `:43`. See **CR-11** for the same document's other count. |
| CR-5 | MINOR (ruling; no action demanded) | Spec/design-fidelity | `check-sc-contracts.py` (whole file), `04_DEVELOPMENT.md` D-1 | **D-1 stays EARNED; the amended cap is re-derived once more.** Delivered **449** is inside the 450 I set at round 1, so there is no drift to report — but the three lines the file gained are all lines *this review demanded* (CR-1's enumeration, CR-2's fall-through), so the binding floor rises with it: re-derived floor **432**, recoverable surplus ≈**17** (3.8 %, unchanged in proportion — derivation in `05_RATIONALE.md`). **One line of headroom is not a cap**, it is a restatement of the file's current size, and the next required clause would trip BC-E a third time for a reason that is not a defect. BC-E's standing number is therefore amended to **465** = floor 432 + one assertion at the measured mean (13.6 lines) + its separators. I demand no trim and disbelieve no number (R-61). |
| CR-6 | MINOR (ruling; no action demanded) | Spec/design-fidelity | `04_DEVELOPMENT.md` D-2, C-2 … C-7 | **D-2 stays EARNED under the restated metric.** Re-measured against the PM's `--numstat`: 21 + 8 + 0 + 0 + 19 + 2 = **50 net** against the restated **60 net** (the `+`-only figure is 104 and still charges the `+20/−20` in-place rewrite of C-5 twice). C-6's growth from +15 net to +19 net is entirely CR-1/CR-4/CR-9 work — every added line traced, see the design-fidelity table. Inside the cap; nothing to fix. |
| CR-8 | NIT | Standards-conformance | `.harness/scripts/restricted-network-regression.sh:43` | Unchanged from round 1. AC-22's exclusion-free regex run hits `TOKEN='--i-will-destroy-this-vm'`, a **pre-existing** line no hunk of this task touched. Nothing in the committed diff matches. Recorded so stage 6 does not read it as this task's failure. |
| CR-10 | NIT | Spec/design-fidelity (x-ref Standards) | `check-sc-contracts.py:18-19`, `:24-25` | `os.startfile` exists in `dir(os)` **on Windows only** and begins with none of the six prefixes, so the header's "EVERY process-start name in `dir(os)`" and "Covered: any process the loaded module starts … through its own `os`" are true on POSIX and false on Windows. No live exposure: `bin/sc` is a Linux CLI, `verify_all.ps1:90-93` SKIPs B.4 with the reason "Linux-only by subject", and on Linux the name is not in `dir(os)` at all. Cheapest honest fixes, in order: add `"startfile"` to the tuple (one token, costs nothing on POSIX), or scope the header sentence to POSIX. Not a blocker. |
| CR-11 | NIT | Standards-conformance | `docs/dev-map.md:33` vs `:151` | One document now gives two counts for the same repointable set: the `# Paths` row still says "The **eight** path constants are only ever referenced *inside* function bodies" while the recipe says **nine**. `LIB_DIR` qualifies on that row's own test — it is a `Path` in `# Paths` (`bin/sc:43`) referenced only inside a function body (`bin/sc:3549`). Note the fix is to `dev-map.md:33` alone: `bin/sc:59-63` carries the same "eighth" wording and `bin/sc` **must stay untouched** (out-of-scope 5), and AC-8/FR-19 do not require this line, so no clause is at risk either way. |
| CR-12 | MINOR | Spec/design-fidelity | `04_DEVELOPMENT.md` D-6 row + `## Open issues for review` bullet 4 | **D-6's delivered content is ACCEPTED; its stated cause is false and must not travel.** The content is right: `CONTEXT.md` carries two well-formed glossary entries — **assertion floor** (`:198-204`, accurate against `verify_all.sh:83-92`) and **contract suite** (`:206-211`) — 15 added lines, declared outside the C-2 … C-7 budget, in the file's established `term / definition / _Avoid_` shape, and no cap governs `CONTEXT.md` (rule 70's table lists none). But "design and gate both cite a line range that carries the *state document* entry" is falsifiable by reading: `:198-204` **is** the assertion-floor entry and the state-document entry is at `:189-196`. Per `PM_LOG.md` decision #2, **stage 1 wrote that entry during this same task**, so PQ-2 read the uncommitted working tree correctly and neither the design nor the gate cited a phantom range. Nothing in `CONTEXT.md` changes; the drift declaration's *why* cell does, or `07_DELIVERY.md` carries the correction (RES-10). |

## Requirement coverage check

| criterion | implementation | status |
|---|---|---|
| FR-1 one committed file, no directory/framework/second file | `check-sc-contracts.py` only | ✅ |
| FR-2 loads via the shim recipe, never as a program, once per process | `:99-122`; called once at `:380` | ✅ |
| FR-3 asserts by calling named functions; never `main()`/`_init_files()` | `TESTS` `:366-374`; `bin/sc:3791` guard false under `ModuleType("sc")` | ✅ |
| FR-4 subject is a run parameter | `--source` `:417-418`, default `:57` | ✅ |
| FR-5 all / one by name / `--list` | `:414-433` | ✅ |
| FR-6 stable names, one line per assertion, summary, exit 0 iff | `:393-405` | ✅ |
| FR-7 `_userinfo` three projections | `:177-198` — verified against `bin/sc:686-695` | ✅ |
| FR-8 `_write_private` 0600 / wider / symlink / UTF-8 bytes | `:201-241` | ✅ |
| FR-9 `_read_state` UTF-16 / shape / default split / `.path` | `:244-268` | ✅ |
| FR-10 directive vocabulary + fault clause is a class name | `:271-296` | ✅ |
| FR-11 `_redact` depth, region, key survival, mask carries nothing | `:299-322` | ✅ |
| FR-12 `$prepend` non-empty and head of composed `dns.rules` | `:325-338` | ✅ |
| FR-13 `zh` placeholders ⊆ key | `:341-361`; 182 entries, 0 offenders | ✅ |
| FR-14 B.4 + B.5 inside the markers, B.1-B.3 untouched | `verify_all.sh:79-98`, markers `:48`/`:99` | ✅ |
| FR-15 B.4 reads the floor; FAILs below it / non-zero / absent file | `verify_all.sh:83-92` | ✅ |
| FR-16 `baseline.json` counts + `notes` name the reader | `baseline.json:4-7` | ✅ |
| FR-17 `.ps1` ids name the same checks; every SKIP states a reason | `verify_all.ps1:75-98` — five ids, five reasons | ✅ |
| FR-18 R-56 / R-59 / R-58 | `restricted-network-regression.sh:94`, `:30-32`, E3/E4 verdict shape | ✅ |
| FR-19 recipe clauses + `50-singbox-cli.md` + wiring row | `dev-map.md:22-27,86,87,151-177`; `50-singbox-cli.md:22-42` | ✅ (CR-4, CR-9 closed) |
| BC-1 refuse at euid 0, one line, non-zero | `:410-413` (first statement of `main`), `:101` (first statement of `load`, before `open` at `:115`) | ✅ |
| BC-2 path constants inside the root before any assertion | `PATHS` `:61-64` (nine), scan `:137-142`, preflight `:382` | ✅ (CR-3 closed) |
| BC-3 `os` restored on the raising path, asserted, non-zero | `finally :118-119`, check `:120-121`, report `:385` | ✅ |
| BC-4 `mkdtemp` + `rmtree` in `finally`, failure named by path | `:435`, `:439-444` | ✅ |
| BC-5 host witnessed before and after | `:434`, `:397-400` — **now on both exit paths** | ✅ (CR-2 closed) |
| BC-6 `python3` absent ⇒ B.4 FAILs | `verify_all.sh:84` | ✅ |
| BC-7 repo root from `__file__` | `:56` | ✅ |
| BC-8 / BC-9 no ≥8-char credential literal, `.invalid` hosts | `"pw"`, `"a"`, `"bbbbbb"`, `a.invalid` | ✅ (CR-8) |
| BC-10 crash / skip / zero assertions ⇒ B.4 FAILs | `:405` (`selected and passed == len(selected)`), `:401-404` 0-run summary + exit 2 | ✅ |
| BC-11 / BC-K `zh` repairs | offender list empty; `bin/sc` untouched | ✅ |
| BC-12 B.5 FAILs and prints; never the token, never root | `verify_all.sh:96-98` | ✅ |
| BC-13 both mirrors' additions inside the markers | `.sh:79-98`, `.ps1:75-98` | ✅ |
| BC-14 no new id/name contains `PASS` | `"bin/sc contract assertions"`, `"restricted-network self-check"` | ✅ |
| BC-15 a PASSing step prints nothing | `verify_all.sh:92,97` — detail only on FAIL | ✅ |
| BC-16 no socket, no name resolution, no child process | zero spawn sites; `SB_BIN` → non-existent path `:136` | ✅ (CR-1 closed) |
| AC-1 `PASS 19 / WARN 0 / FAIL 0 / SKIP 1` | PM re-measured after the rework: 19/0/0/1, EXIT=0 | ✅ re-run at stage 6 |
| AC-2 exit 0, passed == defined | `14 defined, 14 run, 14 passed` | ✅ stage 6 |
| AC-3 每 name selectable, `--list` names all | `:419-433`; unknown name ⇒ exit 2 `:429-432`, before any witness or `mkdtemp` | ✅ |
| AC-4 root refusal precedes the load | `:410-413` is `main()`'s first statement; `:101` is `load()`'s first and precedes `open(src)` `:115` | ✅ (**added this round — the round-1 table omitted AC-4**) |
| AC-5 `/etc/sing-box` + entries + `/var/lib/sing-box` unchanged | `witness()` `:154-174` (`lstat`, total) | ✅ stage 6 (service live) |
| AC-6 `systemctl show` identical | suite never invokes `systemctl`; PM re-measured `MainPID=2566751`, `NRestarts=0`, unchanged | ✅ stage 6 |
| AC-7 no `sudo` / `/usr/local/bin/sc` process | zero spawn sites; forward guarantee now enumerated | ✅ (CR-1 closed; CR-10 is Windows-only) |
| AC-8 delete a `PATHS` row ⇒ fail, no outside write | `:137-142`; scratch run re-taken after CR-3 and recorded in `04` | ✅ |
| AC-9 `sys.modules["os"] is os` on both paths | `:120`, `:385` | ✅ |
| AC-10 every assertion killed by ≥1 mutation | all 14 private mutations re-checked against the **reworked** file — see `05_RATIONALE.md` | ✅ code permits — sweep is stage 6 |
| AC-11 `str(e)` build FAILs the fault-clause assertion | `:290-292` compares the exact `t(...)` rendering | ✅ stage 6 |
| AC-12 emptied `$prepend` FAILs the DNS assertion | `:330-331` explicit non-empty check | ✅ stage 6 |
| AC-13 B.4 FAILs on a lowered suite and an absent `baseline.json` | `verify_all.sh:85`, `:89-90` | ✅ code permits — wet cases stage 6 |
| AC-14 `test_count == passing_count == len(TESTS)` | 14 / 14 / 14 | ✅ |
| AC-15 B.1-B.3 byte-identical, additions inside the markers | `--numstat` **21/0** for `verify_all.sh` — a pure insertion, so every other byte is unchanged by arithmetic; the 21 lines are `:78-98`, inside markers `:48`/`:99`; B.1-B.3 read at `:52-77` | ✅ structure — `git diff` is V-15 at stage 6 |
| AC-16 five ids name the same checks; every `.ps1` SKIP states a reason | `verify_all.ps1:75-98` — names byte-equal to the `.sh` | ✅ |
| AC-17 / AC-18 self-check exit 0, writes nothing, four bases covered; `u@cdn.example` rejected | `restricted-network-regression.sh:89-108` | ✅ stage 6 |
| AC-19 E3/E4 report FAIL, not BLOCKED, on a falsified observation | unchanged from round 1 | ✅ |
| AC-20 3.6 syntax floor, stdlib only | `%`-formatting throughout, no walrus/f-string/`dataclasses`; imports `:39-52` all stdlib | ✅ |
| AC-21 deterministic output | no clock, no random, no host text; `TESTS` is data, `sorted()` everywhere | ✅ stage 6 |
| AC-22 A.1's regex over the diff, exclusions removed | zero hits in the diff | ✅ (CR-8) |
| AC-23 docs describe what ships | `dev-map.md:22-27,86,87`; `50-singbox-cli.md:22-42`; no `<your test command>`, no "no test directory", no "not wired" | ✅ (CR-4, CR-9 closed) |
| AC-24 B.4 under 5 s | 0.068 s | ✅ stage 6 |
| Out-of-scope 1-12 | no test dir, no framework, no dependency, no `.gitignore` change, **`bin/sc` untouched**, B.2 unwidened (`verify_all.sh:70-76`), B.3 SKIP intact, R-57 untouched (`:89`) | ✅ |

## Design fidelity check

| design item | implementation | status |
|---|---|---|
| C-1 the suite, 0755, English, one file | delivered, 449 lines | ✅ |
| C-2 B.4/B.5 appended after `step "B.3"`, no other byte | one hunk `:78-98`, 21/0 | ✅ |
| C-3 `.ps1` renames + printed reasons + B.4/B.5 | `+18/−10`, all inside the markers | ✅ |
| C-4 `test_count`/`passing_count`/`notes`; `version`/`created`/`warnings_baseline` untouched | `baseline.json` | ✅ |
| C-5 three hunks, R-56/R-58/R-59 only | `:94`, `:30-32`, E3/E4 — unchanged this round, re-read | ✅ |
| C-6 four hunks incl. BC-B narrowing | `dev-map.md:22-27,86,87,130-177` — every added line this round traced to CR-1 (`:130-137`), CR-4 (`:146`) or CR-9 (`:151-161`); no unrelated content entered | ✅ (CR-11 is a pre-existing count in the same file) |
| C-7 real command, "no test directory" removed, B.3 sentence intact | `50-singbox-cli.md:22-42` | ✅ |
| C-8 glossary entry beside **assertion floor** | `CONTEXT.md:198-204` + `:206-211`, 15 lines | ✅ content — **CR-12** on the declaration's cause |
| C-9 `bin/sc` `zh` repairs | did not fire — 0 offenders | ✅ |
| I-4 loader: euid gate before `open`, shim, `encoding="utf-8"`, `finally`, post-restore assert | `:99-122` | ✅ |
| I-5 / I-6 `fixture()` + `PATHS` one table | `:125-143`, `:61-64` | ✅ |
| I-7 `witness()` `lstat`, total, `("ERR", errno)` | `:146-174` | ✅ |
| I-8 summary line shape | `:401-402` — matches `verify_all.sh:88`'s anchored `sed` exactly, on both exit paths | ✅ |
| I-9 / I-10 result line, exit status | `:393-405` | ✅ |
| I-11 B.4 detail, extraction, floor comparison | `verify_all.sh:83-92` | ✅ (D-5 accepted) |
| I-12 B.5, no existence guard, no second argument | `verify_all.sh:96-98` | ✅ |
| I-13 five `.ps1` steps with reasons | `verify_all.ps1:75-98` | ✅ |
| I-14 `baseline.json` shape | delivered | ✅ |
| I-15 / I-16 `uncoverable()` `*@*`; E3/E4 verdict shape | unchanged | ✅ |
| I-17 … I-30 the 14 assertions | `:177-361`, in `TESTS` order — bodies byte-unchanged from round 1 | ✅ |
| K-1 never a program, `SB_BIN` non-existent | `:136` | ✅ |
| K-2 forbidden calls | none reached | ✅ |
| K-3 / K-4 double euid gate; `finally` + assert | `:101`, `:410`; `:118-121` | ✅ |
| K-5 pre-import of `bin/sc`'s stdlib set | `:48-52` — re-checked name-by-name against `bin/sc:3-20`: complete | ✅ (RES-5) |
| K-6 / K-7 writes under the fixture; symlink target inside the root; `rmtree` in `finally` | `:224`, `:439-444` | ✅ |
| K-8 / K-9 / K-10 literals, 3.6 floor, determinism | verified | ✅ |
| K-11 markers, byte-identity, no `PASS`, silent on PASS | verified | ✅ |
| K-13 / **BC-D** ≤80 added | 104 `+` / **50 net** | ❌ **drift D-2 — EARNED, cap restated 60 net (CR-6)** |
| K-14 / **BC-E** ≤350 lines | **449** | ❌ **drift D-1 — EARNED; cap amended 450 → re-derived 465 over floor 432 (CR-5)** |
| K-15 four recipe clauses, one line each | `dev-map.md:169-177`, with R-77 also inside the block | ✅ (CR-4 closed) |
| K-16 real command, sentence removed, B.3 intact | `50-singbox-cli.md` | ✅ |
| K-17 / **BC-I** granularity restated as applied | `04_DEVELOPMENT.md` disposition + `check-sc-contracts.py:364-365` | ✅ |
| **BC-A** capability denial, not predicate | `:106-108` — mechanism correct, outlives the load (`mod.os is shim`, `:120`), and the name set is **now complete on POSIX** | ✅ **CR-1 closed** (CR-10: Windows `startfile`) |
| BC-A's declared limit (`subprocess` / `ctypes`) | stated at `:26-28` | ✅ **ACCEPTABLE** — the round-1 condition ("a statement of what is not covered is only trustworthy beside a true statement of what is") is now met |
| BC-B recipe guarantee narrowed | `dev-map.md:130-137` — "fails closed if `geteuid` moves" is **still gone**; the paragraph now reads "What it guarantees and what it does not" and demands the whole `dir(os)` set | ✅ narrowing survives the rewrite |
| BC-C pre-edit baseline before the first edit | 17/0/0/1 at `55f39f0` | ✅ |
| BC-F real invariant + `PERIODIC_DIRS` / `SB_BIN` escapes | header `:30-33` + `dev-map.md:175-177`; re-verified against `bin/sc:23-83` | ✅ |
| BC-G NFR 5's overclaim not repeated; uncovered pair named | `04_DEVELOPMENT.md` | ✅ (RES-2) |
| BC-H witness asymmetry stated where the witness is defined | `:157-162`, with the `bin/sc:1354` cause | ✅ |
| BC-J B.4 with no `NAME`, compares `passed` never `run` | `verify_all.sh:87-90` | ✅ |
| D-3 `--list` separator two ASCII spaces | `:421` | ✅ accepted |
| D-4 exec denial added to I-4 | `:106-108` | ✅ accepted — enumerated, not guessed |
| D-5 one B.4 FAIL branch instead of two | `verify_all.sh:89` | ✅ accepted |
| D-6 two `CONTEXT.md` entries, +15, declared | `CONTEXT.md:198-211` | ✅ **content accepted** — **CR-12** on the stated cause |

## Axis status
- **Standards-conformance: 5 findings, worst OPEN = NIT** (CR-3, CR-4, CR-7, CR-9 all closed this round; CR-11 open at NIT). The delivered artifact holds this repo's conventions: stdlib only, 3.6 floor, `%`-formatting, data-over-machinery (`TESTS`, `PATHS`), comments carrying the WHY, no dead branch, cross-shell parity honest in both mirrors (`.ps1` states a reason per SKIP), every `F.*` cap green in the PM's re-measured run (19/0/0/1), and rule 85's 「以少就是多」 held — the three fixes cost 3 lines and bought no machinery.
- **Spec/design-fidelity: 7 findings, worst OPEN = MINOR** (CR-1 and CR-2 closed; CR-5, CR-6, CR-12 are MINOR rulings with no code action; CR-8, CR-10 are NIT). Every FR, BC and AC — including **AC-4**, which round 1 omitted — maps to code; the three declared drifts are ruled earned or accepted; no CRITICAL or MAJOR remains on either axis.

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RES-1 | The two caps as amended: suite **465** over a re-derived binding floor of **432** (delivered 449; the round-1 cap of 450 left one line of headroom and measured only the file itself); external budget **60 net** lines (delivered 50), the `+`-only metric withdrawn. This is the **third** re-derivation of the same number (303 → 325/350 → 450 → 465): R-61's lesson is that a cap on an unwritten artifact is a guess whose error bar is the artifact's size, and the correct move is always to amend against a re-derivation, never to approve a number you disbelieve and never to trim a required clause to fit. | `07_DELIVERY.md` + the `docs/tasks.md` pool row / insight harvest |
| RES-2 | BC-G's uncovered pair: `_write_private()`'s **exclusivity** as the writer of `config.json`, and **end-to-end** `sc config` redaction (`cmd_config` is never driven). Neither is asserted by the 14; NFR 5's "The suite asserts these" must not be repeated. | `06_TEST_REPORT.md` coverage statement |
| RES-3 | RS-4 confirmed by reading: assertion 6's fixture text `"节点 ✓"` is not latin-1-encodable, so the **codec substitution** kills it loudly while deleting `encoding=` on this UTF-8 host does not. Sweep it with the substitution or it reports a false kill. | `06_TEST_REPORT.md` (AC-10) |
| RES-4 | RS-3 stands: assertion 10's "no substring of the offending document" clause is implied by its sentence-equality clause on this fixture — NOT-DISCRIMINATING at clause level, discriminating at assertion level. Report it that way, never as passed. | `06_TEST_REPORT.md` |
| RES-5 | RS-7 discharged **today** — `:48-52` re-checked name-by-name against `bin/sc:3-20`. It has no standing guard: a future `bin/sc` import silently re-opens the leak. | `07_DELIVERY.md` / `docs/dev-map.md` recipe |
| RES-6 | Stage 6 owns the wet cases stage 4 did not take: AC-13's two FAILs, AC-15's `git diff` against `55f39f0`, AC-5 with the service live, AC-22's regex run (which hits the pre-existing `restricted-network-regression.sh:43`, CR-8) — **and** the three BC-A denial proofs plus the round-1-filter control, which are stage 4's recorded scratch runs and have not been re-taken independently. | `06_TEST_REPORT.md` |
| RES-7 | **Superseded by CR-2's fix, and re-pointed:** the after-witness now runs on the load/fixture-failure path, so BC-5 holds unconditionally. One consequence to state beside the AC-5 result: on that path `if not loaded: return 2` precedes the `changed` comparison, so a witness change there is **printed** (`WITNESS …`) but the exit code is 2 rather than 1 — non-zero either way, and B.4 FAILs. | `06_TEST_REPORT.md` |
| RES-8 | R-57, R-7, R-75 and R-85 stay open and unnarrowed; `.harness/insight-index.md` (30/30) and `docs/tasks.md` (300/300) carry zero headroom, and insight index line 29 says the rotation itself can lose lines — re-measure after `archive-task`, never edit a cap. | `07_DELIVERY.md` |
| RES-9 | The process-start denial is a **name list with no standing guard**: it is complete against CPython's POSIX `os` today (verified this round), incomplete for Windows `os.startfile` (CR-10), and a name a future CPython adds re-opens it silently. The only guards are the header sentence `:18-23` and `docs/dev-map.md:130-137`. A cheap standing check for a later task: assert in the suite that no `dir(os)` name outside the tuple is a known process-starter. | `07_DELIVERY.md` + `docs/tasks.md` pool row |
| RES-10 | `CONTEXT.md` gained **two** glossary terms, **+15** lines, both authored by this task — stage 1 wrote **assertion floor** (`:198-204`), stage 4 wrote **contract suite** (`:206-211`) — declared outside the C-2 … C-7 budget, and no cap governs `CONTEXT.md`. Deliver it with that sentence, **not** with D-6's stated cause: PQ-2's `CONTEXT.md:198-203` citation was correct against the working tree it read, and no upstream document cited a phantom range (CR-12). | `07_DELIVERY.md` (and the D-6 row if stage 4 touches `04` again) |

## Verdict
APPROVED
