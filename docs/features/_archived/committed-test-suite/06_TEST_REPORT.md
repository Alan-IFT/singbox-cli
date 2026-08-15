> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

# T-28 · committed-test-suite — Test Report

## Test plan

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 `verify_all` 19/0/0/1 exit 0 from the repo root | `bash .harness/scripts/verify_all.sh` ×4 (1 measurement + 3 stability) | `.harness/scripts/verify_all.sh` |
| AC-2 suite exits 0, passed == defined | direct run ×12 | `.harness/scripts/check-sc-contracts.py` |
| AC-3 every assertion selectable, `--list` names all | `--list` (14 lines) + a per-name loop over all 14 + one unknown name | same |
| AC-4 root refusal precedes the load | euid read stubbed in a scratch **suite** copy: (a) `main()` gate, (b) `main()` gate deleted + `--source /nonexistent/bin/sc`, (c) non-root control | scratch `ac4/*/check-sc-contracts.py` |
| AC-5 `/etc/sing-box` + entries + `/var/lib/sing-box` unchanged | independent `stat` witness before/after the whole stage, service **live** | scratch `hostwitness.sh` |
| AC-6 `systemctl show` identical | same witness script (`show` only, never `is-active`) | same |
| AC-7 no `sudo` / `/usr/local/bin/sc` process | `strace -f -e trace=execve,clone,fork,vfork,socket,connect` over a full run | scratch `strace.txt` |
| AC-8 eight (nine) path constants inside the run root | `PATHS` row `IF_INET6_PATH` deleted in a scratch suite copy, driven `--source bin/sc` | scratch `ac4/no-if-inet6/` |
| AC-9 `sys.modules["os"]` restored on both paths | `--source` at a raising source and at an uncompilable source | scratch `ac4/sources/` |
| AC-10 every assertion killed by ≥1 mutation, **per clause** | 32-clause mutation sweep, 31 mutants + 1 codec control | scratch `sweep.py` (see `## Adversarial tests`) |
| AC-11 `str(e)` build fails the fault clause | sweep M19 | same |
| AC-12 emptied `$prepend` fails the DNS assertion | sweep M26 | same |
| AC-13 B.4 FAILs below the floor and on an absent `baseline.json` | 3 wet cases in a scratch **clone** (PQ-7) + 1 control | scratch `clone/` |
| AC-14 `test_count == passing_count == len(TESTS)` | AST count of `TESTS` vs the JSON | `.harness/scripts/baseline.json` |
| AC-15 B.1-B.3 byte-identical, additions inside the markers | `git diff 55f39f0`, sha256 of lines 52-77, per-line marker check | scratch `bc13.py` |
| AC-16 five ids name the same check in both mirrors | extracted `(id,name)` pairs from both files, diffed | scratch `ac16.sh` |
| AC-17 `--self-check` exit 0, writes nothing, four bases covered | run under `strace` over every write syscall | `.harness/scripts/restricted-network-regression.sh` |
| AC-18 `u@cdn.example` rejected, four bases still covered | `--self-check --source <copy carrying that base>` + a pre-R-56 control | scratch `rn/` |
| AC-19 E3/E4 FAIL, not BLOCKED, on a falsified observation | the two verdict expressions **extracted by line number** and driven over 8 states | scratch `ac19.sh` |
| AC-20 3.6 floor, stdlib only | `py_compile` + an AST import/construct audit | scratch `ac20.py` |
| AC-21 two runs identical | 10 sequential runs diffed + 10 parallel | scratch `stab-*.txt` |
| AC-22 A.1's regex over the diff, exclusions removed | regex over every added line incl. the new file; plus A.1's own `git grep` without `:!.harness/*` | scratch `task-diff-added.txt` |
| AC-23 docs describe what ships | grep for each named falsifier and each required clause | scratch `ac23.sh` |
| AC-24 B.4 under 5 s | the B.4 block replayed under `/usr/bin/time`, 3 takes | `.harness/scripts/verify_all.sh:82-92` |

No test was deleted, weakened or renamed; `verify_all` and its checks were not modified.
The 14 committed assertions were not edited — FR-1 caps the task at one committed file, so
every reproducer above lives in scratch and none of it is proposed for commit.

## Adversarial tests

Each row states the failure I predicted **before** running it. Full runs: `06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (cited output) |
|---|---|---|---|
| AC-1 | a doc-size cap with zero headroom (F.4 30/30, F.5 300/300) has already tipped, so the run is 18/1/0/1 | `bash .harness/scripts/verify_all.sh` from `/home/alan/Programs/singbox-cli` | Survived — `PASS: 19` `WARN: 0` `FAIL: 0` `SKIP: 1`, `EXIT=0`. F.4/F.5 re-measured at 30 and 300, both PASS (strict `>`), nothing attributed away (BC-C) |
| AC-2 | some assertion is order-dependent and only passes as part of the whole | 12 full runs + all 14 single-name runs | Survived — `summary: 14 defined, 14 run, 14 passed`, exit 0; every single-name run `1 run, 1 passed` |
| AC-3 | a name in `--list` is not selectable, or `--list` misses one | loop over `--list`'s 14 names; then `no_such_assertion` | Survived — `list lines: 14`, `unselectable: 0`; unknown name ⇒ `unknown assertion(s): no_such_assertion`, `EXIT=2` before any witness |
| AC-4 | the euid gate is decorative and `bin/sc` is opened anyway | scratch suite copy, `main()` gate deleted, euid read stubbed 0, `--source /nonexistent/bin/sc` | Survived — `load failed  LoadRefused: refusing to load bin/sc as root`; the non-root control on the same absent path gives `FileNotFoundError`, so the gate provably precedes `open()` |
| AC-5 | the live sing-box rewrites `/var/lib/sing-box/cache.db` mid-run and reddens the witness (F-7) | independent `stat` of `/etc/sing-box`, its 6 entries and `/var/lib/sing-box`, before and after the entire stage | Survived — `IDENTICAL`. Service **live** throughout: `MainPID=2566751`, `NRestarts=0`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`. The asymmetry held: the `cache.db` entry is deliberately not witnessed |
| AC-6 | some probe restarts or reloads the unit | `systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts` at start, mid, end; `is-active` never invoked | Survived — three readings identical; no `systemctl` call in any traced run |
| AC-7 | something in the run reaches `sudo` or the installed `sc` | `strace -f -e trace=execve,clone,fork,vfork,socket,connect` over a full run | Survived — `count execve: 1` (the interpreter itself), `count clone: 0`, `count socket: 0` |
| AC-8 | with a `PATHS` row gone the run proceeds and writes under `/etc` | delete the `IF_INET6_PATH` row in a scratch suite copy | Survived — `fixture failed  AssertionError: Path constant(s) outside the run root: IF_INET6_PATH`, `0 run`, exit 2, host witness unchanged |
| AC-9 | a load that raises leaks the shim | `--source` at a raising source, then at an uncompilable one | Survived — `RuntimeError: deliberate import-time failure` / `SyntaxError: invalid syntax`, each with `os restored  True`, exit 2 |
| AC-11 | `str(e)` still renders a class-name-shaped sentence and slips through | sweep **M19** | **Killed the assertion** — `the sentence: got "no configuration could be produced from it ('str' object has no attribute 'get')"`. R-71 discharged |
| AC-12 | an emptied `$prepend` degenerates to `[] == []` and passes silently (R-80) | sweep **M26** | **Killed the assertion** — `AssertionError: the $prepend payload is empty for suppress=True`. R-80's silent mode is closed |
| AC-13 | the floor is decorative: a suite that is green on its own passes B.4 | scratch clone, one name removed from `TESTS` | **B.4 FAILed** — suite alone `13 defined, 13 run, 13 passed` **exit 0**, yet `[B.4] … FAIL  13 assertion(s) passed, floor is 14`, `verify_all EXIT=2` |
| AC-13 | an absent `baseline.json` makes the floor empty and B.4 passes vacuously | same clone, `baseline.json` moved aside and restored | **B.4 FAILed** — `.harness/scripts/baseline.json is absent or its test_count unreadable`, `PASS: 18 / FAIL: 1`, exit 2 |
| AC-13 | a non-zero suite exit is not noticed (BC-10) | same clone, `bin/sc` replaced by mutant M19 | **B.4 FAILed** — `exit 1, passed='13'`, exit 2. Clone restored and re-verified `[B.4] … PASS` |
| AC-14 | `test_count` was hand-set and no longer matches the code | AST count vs the JSON | Survived — `len(TESTS) = 14`, `test_count = 14 | passing_count = 14` |
| AC-15 | the insertion disturbed a byte of B.1-B.3 or escaped the markers | `git diff 55f39f0`, sha256 of lines 52-77, per-line marker arithmetic | Survived — one hunk `@@ -75,6 +75,27 @@`, `21 0`; both sha256 `6ad1a373…`; `EVERY changed line is inside the markers` for **both** mirrors |
| AC-16 | the `.ps1` reuses an id for a different check, or SKIPs bare | `(id,name)` pairs extracted from both files and diffed | Survived — `IDENTICAL id+name pairs in both mirrors`; 5 reason strings for 5 steps |
| AC-17 | `--self-check` writes something (a temp dir, a log) despite the claim | run under `strace` over `openat/creat/mkdir/unlink/rename/chmod/truncate` | Survived — `SELF-CHECK OK: 4 shipped base(s), all covered`, exit 0, **zero** write-mode opens, `0` sockets |
| AC-18 | `*@*` also rejects the two shipped bases whose URL contains `@` (PQ-4) | `--self-check --source <bin/sc + a u@cdn.example base>`, then a pre-R-56 control | Survived — `SELF-CHECK FAIL: uncoverable base(s): https://u@cdn.example/…`, exit 1, four shipped bases still derived. Control (no `*@*`): `SELF-CHECK OK: 5 shipped base(s), all covered` listing `u@cdn.example` as a blackout host — R-56's fix is load-bearing |
| AC-19 | the reordering left a path where a falsified observation still reports BLOCKED | E3/E4 expressions **extracted from lines 304-314** and driven over 8 states | Survived — falsified ⇒ `E3 VERDICT=FAIL` / `E4 VERDICT=FAIL` even with `rblock` set; unfalsified + `rblock` ⇒ `BLOCKED`; unfalsified + no `rblock` ⇒ `PASS` |
| AC-20 | a 3.7+ construct or a non-stdlib import slipped in | `py_compile` + AST audit | Survived — `non-stdlib: NONE`, `post-3.6 constructs: NONE`, `f-string literal count: 0`, 449 lines, mode 755 |
| AC-21 | a clock, a PID or a dict order leaks into the output | 10 sequential runs, pairwise diff; then 10 parallel | Survived — all 10 byte-identical (`sha256 c43d0ae5…`); the temp root never reaches the output at all, so not even that differs |
| AC-22 | CR-8's predicted hit is real and lands in this task's diff | A.1's own regex over every added line, then A.1's `git grep` with `:!.harness/*` removed | Survived — `ZERO HITS in this task's added lines` (568 lines scanned). **CR-8's premise refuted**: A.1 is case-**sensitive**, `TOKEN='--i-will-destroy-this-vm'` matches only with `-i` (`case-sensitive: 0`, `case-insensitive: 1`), so the exclusion-free run has zero hits anywhere outside `*.md` |
| AC-23 | one of the three retired claims survives somewhere in the two docs | grep each falsifier | Survived — `<your test command>` 0, `no test directory` 0, `not wired into` 0, **`fails closed if` 0** (BC-B's narrowing intact) |
| AC-24 | loading a 3800-line module 8× (one fixture per assertion) blows the 5 s budget | the B.4 block replayed under `/usr/bin/time`, 3 takes | Survived — `0.07 s`, `0.08 s`, `0.07 s` against a 5 s budget |

**AC-10 — the R-22 sweep, one row per CLAUSE (BC-I).** Every mutation is applied to a **copy**
of `bin/sc` in scratch and driven through the suite's own `--source`; `bin/sc` is byte-identical
to `55f39f0` (`sha256 b2b79856…`). Outcome cites the assertion that caught it.

| AC | Clause (hypothesis: "this clause is vacuous") | Reproducer (mutation) | Outcome |
|---|---|---|---|
| AC-10 | userinfo ends at the **last** `@` | M1 `rpartition("@")`→`partition` | KILLED `userinfo_ends_at_last_at` — `got ('a','a',''), want ('a@b','a@b','')` |
| AC-10 | an authority with no `@` has an empty userinfo | M2 `… or authority` | KILLED same — `got ('h','h',''), want ('','','')` |
| AC-10 | the boundary is the **first raw** colon | M3 `partition(":")`→`rpartition` | KILLED `userinfo_splits_at_first_raw_colon` — `got ('u:p:q','u:p','q')` |
| AC-10 | `whole` is not derivable from `(first, rest)` | M4 rebuild `whole` from the pair | KILLED same — `whole is derivable from (first, rest): both 'pw'` |
| AC-10 | the decode happens **after** the split | M5 decode `raw` before splitting | KILLED `userinfo_decodes_exactly_once` — `got ('a:b','a','b')` |
| AC-10 | decoded exactly **once** | M6 `unquote(unquote(s))` | KILLED same — `got ('a@b','a@b',''), want ('a%40b',…)` |
| AC-10 | mode is exactly 0600 whatever the umask cleared | M7 delete `os.fchmod` | KILLED `write_private_exact_0600_under_hostile_umask` — `got 256, want 384` |
| AC-10 | *(control clause)* the bare `mkstemp` beside it reads 0400 | no `bin/sc` mutation can reach it — it asserts the **fixture's** umask | **NOT-DISCRIMINATING against `bin/sc`** — by design a control on the environment; it is what makes M7's kill meaningful |
| AC-10 | a wider pre-existing target ends 0600 with the new content | M8 write in place instead of `mkstemp`+`replace` | KILLED `write_private_replaces_wider_and_symlinked_target` — `got (438,'new'), want (384,'new')` |
| AC-10 | a symlinked target is **replaced**, not written through | M9 `os.replace(tmp, realpath(path))` | KILLED same — `got (True, 511, 'through'), want (False, 384, 'through')` |
| AC-10 | the link's former destination is left intact | M10 pre-truncate the target "for writability" | KILLED same — `the link's former destination: got (420,''), want (420,'victim')` |
| AC-10 | the bytes on disk are the text's UTF-8 | M11 **codec substitution** `utf-8`→`latin-1` (RES-3) | KILLED `write_private_writes_utf8_bytes` — `UnicodeEncodeError: 'latin-1' codec can't encode characters in position 0-1` |
| AC-10 | *(RES-3 control)* would deleting `encoding=` kill it too? | M11b `encoding=` deleted | **SURVIVED, as predicted** — `PASS … 5 text characters -> 11 UTF-8 bytes`. RS-4 confirmed: sweeping it that way reports a **false kill** |
| AC-10 | the UTF-8 decode is **explicit** | M12 hand `read_bytes()` to `json.loads` | KILLED `read_state_refuses_utf16_by_name` — `a UTF-16 document: no OverrideError was raised` |
| AC-10 | *(control clause)* `json.loads` accepts the same bytes | asserted in the suite over the fixture, not over `bin/sc` | **NOT-DISCRIMINATING against `bin/sc`** — the pre-assertion that proves the fixture discriminates (insight 16) |
| AC-10 | one top-level shape check per document | M13 delete the `isinstance(doc, dict)` test | KILLED `read_state_shape_and_default_split` — `a top-level array: no OverrideError was raised` |
| AC-10 | one member-array shape check per document | M14 delete the member test | KILLED same — `a member that is not an array: no OverrideError was raised` |
| AC-10 | absent-**is-empty** half of the `default` split | M15 disable the `default` arm | KILLED same — `OverrideError: cannot be read (No such file or directory)` |
| AC-10 | absent-**is-failure** half of the `default` split | M16 return the default regardless | KILLED same — `an absent document: no OverrideError was raised` |
| AC-10 | the `OverrideError` family carries `.path` | M17 `failure.path = None` | KILLED same — `OverrideError.path: got None, want PosixPath('…/top.json')` |
| AC-10 | the array position is decided on the **target's** type | M18 branch on the overlay value | KILLED `merge_array_key_demands_a_directive` — `{'server': 'x'} over dns.rules: no OverrideError was raised` |
| AC-10 | the fault clause is a bare exception **class name** | M19 `type(e).__name__`→`str(e)` (**AC-11**) | KILLED `unusable_fault_clause_is_a_class_name` — see the AC-11 row |
| AC-10 | no configuration reaches disk on the fault path | M20 write a partial config in the fault arm | KILLED same — `whether a configuration reached disk: got True, want False` |
| AC-10 | the sentence carries **no substring** of the offending document | M21 embed `json.dumps(override)` in the fault | **NOT-DISCRIMINATING at clause level (RES-4/RS-3 confirmed)** — the sentence-equality clause fires first: `the sentence: got 'no configuration could be produced from it (AttributeError {"route"…'`. Any sentence that fails the substring clause has already failed equality, so no mutation can reach it. The assertion as a whole discriminates (M19, M20) |
| AC-10 | `SECRET_KEYS` is masked **everywhere**, not only in `outbounds` | M22 `strict and k in SECRET_KEYS` | KILLED `redact_masks_secret_keys_at_every_depth` — `got {'password': 's', … 'log': {'password': 's'…` |
| AC-10 | `strict` is **sticky** on descent | M23 `_redact(v, k == "outbounds")` | KILLED `redact_masks_unlisted_keys_inside_outbounds` — `'nested': {'a': 1}` left unmasked |
| AC-10 | the region rule applies **only** inside `outbounds` | M24 drop `strict` from the `elif` | KILLED same — top-level `'unlisted': '******'` where `'abc'` was wanted |
| AC-10 | the mask carries nothing derived from what it replaced | M25 `MASK + "(%d)" % len(v)` | KILLED same — `'password': "******(1)"` vs the 6-char document |
| AC-10 | the `$prepend` payload is **non-empty** | M26 empty the payload (**AC-12**) | KILLED `dns_overlay_prepend_is_head_of_dns_rules` — see the AC-12 row |
| AC-10 | the payload's first element **is** that decision's AAAA rule | M27 `_aaaa_rule(not suppress)` | KILLED same — `got {…'query_type': [64, 65]}, want {…[28, 64, 65]}` |
| AC-10 | the emitted position is the **head** of composed `dns.rules` | M28b the second `dns.rules` writer prepends too | KILLED same — `the head of composed dns.rules: got {… 'rcode': 'NXDOMAIN', 'domain_suffix': ['telemetry.microsoft.com'…` |
| AC-10 | *(same clause, coarser mutation)* `$prepend`→`$append` | M28 | KILLED same, but at the payload extraction — `KeyError: '$prepend'`. Recorded because it does **not** exercise the position clause; M28b is the position-only kill |
| AC-10 | the two decisions differ (no vacuous agreement) | M29 `_aaaa_rule` ignores `suppress` | KILLED same — `both decisions give the same rule, so neither is tested` |
| AC-10 | an offending `zh` placeholder is found | M30 add `{bogus}` to one `zh` value | KILLED `zh_placeholders_are_a_subset_of_their_key` — `1 offending entry(ies):` |
| AC-10 | assertion 14 discriminates a broken from a fixed `bin/sc` **today** | delivered tree: `182 entries in 1 table(s), 0 offenders` | **Forward guard, no current subject** — confirmed, as pre-declared. It is mutation-reachable (M30), so it is not vacuous, but on today's `bin/sc` it separates nothing |
| AC-10 | *(beyond the 14)* the host-witness **comparison** is itself never exercised | falsify the `before` reading in a scratch suite copy | KILLED — `WITNESS /etc/sing-box/PHANTOM before=('ERR',2) after=None` with `14 defined, 14 run, 14 passed` yet **exit 1**. A green suite still reddens B.4 when the host moved |

**BC-A, re-taken independently (RES-6).** Stage 4's runs were re-taken from scratch, not inherited.

| AC | Hypothesis | Reproducer | Outcome |
|---|---|---|---|
| AC-7 | a guard reading `os.getuid()` + `os.execvp` re-execs the installed `sc` under sudo (R-78) | scratch `bin/sc` copy, delivered suite | Refused — `LoadRefused: bin/sc tried to start or replace a process during load (first argument: ('sudo',))`, `os restored  True`, `0 run`, exit 2 |
| AC-7 | `popen` is not a prefix of `exec`/`spawn`/`fork`, so a shell starts | same, guard = `os.popen("touch <probe>")` | Refused — exit 2, and the decisive check: `PROBE ARTIFACT … EXISTS: False` — no shell ran |
| AC-7 | `posix_spawn` likewise | same, guard = `os.posix_spawn("/nonexistent-sc", …)` | Refused — `LoadRefused … ('/nonexistent-sc',)`, exit 2 |
| AC-7 | **CONTROL** — under the round-1 prefix filter the same copies are *not* denied | round-1 filter spliced into a scratch **suite** copy | Demonstrated: `posix_spawn` copy ⇒ `FileNotFoundError` (the real call ran, stopped only by the missing path); `popen` copy ⇒ **`PROBE ARTIFACT … EXISTS: True`** and `summary: 14 defined, 14 run, 14 passed`, **exit 0** — a fully green run with a shell started from `bin/sc`'s import |

## Boundary tests added

- **Root:** never taken as root. The euid **read** is stubbed in a scratch suite copy, exercising both gates (`main()`, then `load()`); `AC-4b` proves ordering by making the source absent — the gate answers before `open()` can.
- **Concurrency:** 10 simultaneous suite processes all report `14 defined, 14 run, 14 passed`; `mkdtemp` gives each its own root (BC-4), and no run root survives any run.
- **Hostile ambient umask `0777`:** the run FAILs loudly and correctly — `fixture failed  PermissionError … /preflight/rules`, `0 run`, exit 2 — and BC-4's non-silent removal failure fires: `run root NOT removed: /tmp/sc-contract-auisq03v`. The named directory is left at mode 0000 and needs a `chmod` before it can be removed. Spec-conformant, recorded so it is recognised rather than re-diagnosed. **Permissive umask `0000`:** all 14 pass.
- **Locale:** `env -i LC_ALL=C PYTHONUTF8=0` — 14/14, exit 0. R-77's `encoding="utf-8"` on the source read is what makes this hold; every printed byte is ASCII (D-3).
- **cwd:** run from `/` — 14/14. BC-7 also fell out of a mistake: a scratch copy of the suite resolved its default source from **its own** location (`…/scratchpad/bin/sc`), never from the cwd.
- **`TMPDIR` unwritable (mode 0500):** CPython's `tempfile` falls back to `/tmp`; the run completes 14/14. No fixed path is used anywhere.
- **Empty / absent / malformed subject:** absent source ⇒ `FileNotFoundError`; raising source ⇒ `RuntimeError`; uncompilable source ⇒ `SyntaxError` — each with `os restored  True` and exit 2.
- **Unicode:** the UTF-8 clause is asserted with `"节点 ✓"` (non-latin-1-encodable), which is exactly what makes the codec-substitution mutation kill it; a UTF-16 state document is refused by name.
- **Filesystem, witnessed by syscall:** over a full run, every write-mode open, `mkdir`, `unlink`, `rename`, `chmod` and `symlink` lands inside the `mkdtemp` root. The one exception is CPython's own `tempfile` bootstrap probe — one `O_CREAT|O_EXCL|O_NOFOLLOW` file at mode 0600 created directly in `$TMPDIR` and `unlink`ed on the next syscall, before the run root exists. `/etc/sing-box` is opened `O_RDONLY|O_DIRECTORY` only.

## verify_all result

```
command: bash .harness/scripts/verify_all.sh   (cwd = /home/alan/Programs/singbox-cli)
total steps: 20   (18 at task-start HEAD 55f39f0, + B.4 + B.5)
PASS: 19
WARN: 0
FAIL: 0
SKIP: 1        (B.3 Lint — untouched, unrepurposed)
exit code: 0
AC-1: discharged in full, all four numbers plus the exit code; no residual WARN, nothing attributed away (BC-C)
task-start baseline: PASS 17 / WARN 0 / FAIL 0 / SKIP 1, exit 0 at 55f39f0 — confirmed independently by re-reading the diff and the step count, not accepted from 04
suite direct: exit 0, "summary: 14 defined, 14 run, 14 passed"
B.4 wall clock: 0.07 s / 0.08 s / 0.07 s   (AC-24 budget 5 s)
new tests added: 0 committed (FR-1 permits exactly one committed file, already delivered); 32 clause mutants + 6 capability/gate probes written and run in scratch, none proposed for commit
test count: 0 (baseline.json at 55f39f0) -> 14 (delivered)
baseline updated: no — test_count 14 already equals len(TESTS) 14 and passing_count 14; verified equal, not raised, and never lowered
F.4 .harness/insight-index.md: 30 / 30 lines, PASS (strict >), zero headroom
F.5 docs/tasks.md: 300 / 300 lines, PASS (strict >), zero headroom
F.6 longest doc in this feature: PM_LOG.md 292 lines
operator obligations: none added; nothing in this task required root or a host these agents cannot reach
```

**Coverage statement (BC-G / RES-2), stated plainly.** NFR 5's sentence "The suite asserts these"
is **not** repeated here, and two of the three clauses it claims are **uncovered by the 14**:

- `_write_private()`'s **exclusivity** as the writer of `config.json` is not asserted. No
  assertion reaches a successful `generate_config()` write — the one assertion that enters it
  asserts the opposite (`whether a configuration reached disk: … want False`).
- **End-to-end** `sc config` redaction is not asserted. `cmd_config` is never called; redaction
  is asserted only at `_redact`'s own level.

Measured surface: the 14 assertions call **13 of `bin/sc`'s 113 named functions** directly
(`_aaaa_rule, _compose, _directive_list, _dns_overlay, _merge, _read_state, _redact,
_telemetry_overlay, _userinfo, _write_private, generate_config, save_nodes, t`). The third NFR-5
clause — credential bytes never wider than 0600 at any instant — **is** asserted, and its
mutation kills (M7, M8, M9).

**Coverage limit, confirmed not a defect.** `fixture()` sets `sc.LANG = "en"` and `TRANSLATIONS`
has no `en` table, so every sentence assertion compares against `t()`'s **key**. I destroyed two
`zh` renderings in a scratch copy (`"顶层必须是一个 JSON 对象"` → `"WRONG-ZH-RENDERING"`,
`"不是有效的 UTF-8 文本"` → `"ALSO-WRONG"`) and the suite still reported
`14 defined, 14 run, 14 passed`, exit 0. A mutation that breaks only the `zh` rendering is
invisible to the 14; assertion 14 guards `zh` **placeholders**, never wording.

**RES-7, stated beside AC-5.** The after-witness now runs on the load/fixture-failure path, so
BC-5 holds unconditionally — but `if not loaded: return 2` precedes the `changed` comparison, so
a witness change there is **printed** and the exit is **2**, not 1. Both observed in one probe:
loaded path ⇒ `WITNESS …` + exit 1; failed-load path ⇒ `WITNESS …` + exit 2. Non-zero either
way, and B.4 FAILs on both.

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| — | — | No defect was found. 24 of 24 acceptance criteria PASS, 0 FAIL, 0 BLOCKED. | — |

Three findings that are **not** defects, recorded so they are not re-discovered:
`CR-8`'s predicted AC-22 hit does not exist under A.1's own case-sensitive regex (premise
refuted, not inherited); the `zh`-rendering blind spot above is a coverage limit; the
mode-0000 leftover run root under a hostile ambient umask is BC-4 behaving as specified.

## Stability

- Suite run 10× sequentially: 10 × exit 0, all outputs **byte-identical** (`sha256 c43d0ae5…`). No flake.
- Suite run 10× in parallel: 10 × `summary: 14 defined, 14 run, 14 passed`. No collision, no leftover run root — `mkdtemp` per run (BC-4).
- `verify_all.sh` run 3× after the measurement run: `19/0/0/1 exit 0` each time.
- Determinism is structural, not lucky: no clock, no randomness, no host text and no temp-root path reaches the output, so two runs differ in nothing at all — a stronger result than AC-21 asks for.
- No test flaked in any of the 60+ suite invocations taken this stage, including the 38 scratch-mutant runs.

## Verdict

APPROVED FOR DELIVERY
