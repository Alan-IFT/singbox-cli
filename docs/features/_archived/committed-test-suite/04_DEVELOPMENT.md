# T-28 · committed-test-suite — Development

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

## Summary

`.harness/scripts/check-sc-contracts.py` ships as the project's one committed test artifact: it
loads `bin/sc` in-process through the `docs/dev-map.md` recipe **plus a shim that denies every
process-start name in `dir(os)`** — `exec*` / `spawn*` / `fork*` / `system` **and** `popen` /
`posix_spawn*` — and asserts 14 named clauses by calling named functions of the loaded module.

`verify_all` gained B.4 (the suite, floored by `baseline.json`'s `test_count`) and B.5
(`restricted-network-regression.sh --self-check`) inside the `HARNESS:B-CUSTOM` markers; B.1/B.2/B.3
are byte-identical, and the scenario script's R-56 / R-58 / R-59 defects are fixed.

`bin/sc` is unchanged — C-9 did not fire (assertion 14 reports **zero** offenders over 182 entries).

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `.harness/scripts/check-sc-contracts.py` | **New**, 449 lines, mode 0755. Header (safety + BC-A mechanism and its stated limit + BC-F invariant), `load()` (euid gate, shim, denial of every process-start name in `dir(os)`, `finally`, post-restore asserts), `fixture()` (repoint + the strict inside-root predicate), `witness()`, 5 shared helpers, 14 assertions, `TESTS`, runner (the after-witness on **both** exit paths), CLI. | C-1 |
| `.harness/scripts/baseline.json` | `test_count` / `passing_count` `0` → **14**; `notes` names `verify_all.sh` B.4 as the reader and states the ratchet. `version` / `created` / `warnings_baseline` untouched. | C-4 |
| `.harness/scripts/verify_all.sh` | B.4 + B.5 appended after `step "B.3"` and before `HARNESS:B-CUSTOM:END`. One hunk, `@@ -77,0 +78,21 @@`. No other byte. | C-2 |
| `.harness/scripts/verify_all.ps1` | B.1/B.2 renamed to their `.sh` check names; the three `# TODO:` blocks replaced by one printed SKIP reason each; B.4 and B.5 added as reasoned SKIPs. Inside the markers. | C-3 |
| `.harness/scripts/restricted-network-regression.sh` | `uncoverable()` gains `*@*` (**R-56**); E3/E4 compute their own verdict first and let `rblock` block only a PASS, absorbing the `nolog` arm as a conjunct (**R-59**); the `:30-31` comment no longer carries the file's only CJK nor claims more than it can (**R-58**). | C-5 |
| `docs/dev-map.md` | Four hunks: the "no test directory" paragraph; the recipe's guarantee narrowed to predicate-not-capability (**BC-B**) — the denial list reads `dir(os)`'s **whole** process-start set and says a name prefix is not a capability either — + the four R-77 / R-78 / R-84 / working-reference clauses, with `encoding="utf-8"` **inside the copy-pasteable block**; the `--self-check` wiring claim; one new `## Reusable utilities` row for the suite. The repointing clause names **nine** constants (`LIB_DIR` included), matching the working reference it cites. | C-6 |
| `.harness/rules/50-singbox-cli.md` | `<your test command>` → `python3 .harness/scripts/check-sc-contracts.py`; "no test directory" removed; the B.* paragraph gains B.4/B.5. B.3's SKIP sentence intact. | C-7 |
| `CONTEXT.md` | **Two** glossary entries, 15 lines, declared outside the external budget: **contract suite**, and **assertion floor** — which C-8 and PQ-2 both record as already existing at `CONTEXT.md:198-203` but which is **not** in `HEAD` (`git show HEAD:CONTEXT.md` has no such term), so `baseline.json`'s floor had no definition to sit beside. Drift **D-6**. | C-8 |
| `bin/sc` | **Unchanged.** Conditional row did not fire. | C-9 |

**External budget, `git diff --numstat` against `HEAD` (`55f39f0`).** BC-D's `+`-only metric was
falsified at stage 5 (it charges an in-place rewrite twice) and restated as **60 net** lines across
C-2 … C-7; delivered **50 net** (104 `+`, 54 `−`). No required clause was dropped to fit; see
drift **D-2**.

| id | file | planned `+` | actual `+` | actual `−` | net |
|---|---|---|---|---|---|
| C-2 | `verify_all.sh` | 20 | 21 | 0 | **+21** |
| C-3 | `verify_all.ps1` | 15 | 18 | 10 | **+8** |
| C-4 | `baseline.json` | 3 | 3 | 3 | **0** |
| C-5 | `restricted-network-regression.sh` | 15 | 20 | 20 | **0** |
| C-6 | `docs/dev-map.md` | 12 | 34 | 15 | **+19** |
| C-7 | `.harness/rules/50-singbox-cli.md` | 8 | 8 | 6 | **+2** |
| | **total C-2 … C-7** | 73 | 104 | 54 | **+50** (cap 60) |
| C-8 | `CONTEXT.md` (declared separately) | 6 | 15 | 0 | **+15** |

## verify_all result

```
baseline (pre-edit, HEAD 55f39f0, repo root): PASS 17 / WARN 0 / FAIL 0 / SKIP 1, exit 0
after    (delivered tree,        repo root): PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0
delta: +2 PASS (B.4 "bin/sc contract assertions", B.5 "restricted-network self-check")
delta: 0 new WARN, 0 new FAIL; SKIP unchanged at 1 (B.3 Lint, untouched)
AC-1: discharged in full — no residual WARN, nothing attributed away
suite direct run: exit 0, "summary: 14 defined, 14 run, 14 passed"
AC-14: len(TESTS) 14 == baseline.json test_count 14 == passing_count 14
suite size: 449 lines (BC-E as amended at stage 5: cap 450 over a re-derived floor of 429)
B.4 wall clock: 0.068 s (AC-24 budget 5 s)
BC-A proof, scratch bin/sc copies, delivered suite (bin/sc itself untouched):
  guard reads os.getuid() + os.execvp  -> LoadRefused ('sudo',),          exit 2
  guard reads os.getuid() + os.popen   -> LoadRefused ('echo …',),        exit 2, no shell ran
  guard reads os.getuid() + os.posix_spawn -> LoadRefused ('/nonexistent-sc',), exit 2
  same posix_spawn copy under the ROUND-1 filter (control) -> NOT denied: the real
  os.posix_spawn ran and failed only on the missing path (FileNotFoundError), exit 2
BC-5 proof (CR-2): _execute called with a falsified `before` on the load-failure path
  prints "WITNESS /etc/sing-box before=… after=…" and returns 2 — the after-witness is
  now taken on both exit paths
BC-2 proof (CR-3): a scratch suite copy with the IF_INET6_PATH row deleted still stops at
  "fixture failed  AssertionError: Path constant(s) outside the run root: IF_INET6_PATH",
  0 assertions run; the predicate is now `== root or startswith(root + os.sep)`, and on a
  sibling root sharing a prefix the round-1 form answered "inside" where this one answers
  "outside"
service witness before and after every run, this round included: MainPID=2566751 ·
  NRestarts=0 · ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST — identical, `systemctl
  show` only, `is-active` never invoked
host witness (independent of the suite, `ls -lai` + `stat` over /etc/sing-box, its entries
  and /var/lib/sing-box) around a full run: byte-identical
```

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| D-1 | K-14 / **BC-E**: suite file ≤ **350** lines (floor 325) | delivered **449** | Every clause of FR-7 … FR-13, BC-2 … BC-9, K-1 … K-12 is present; the trim order was applied as far as it goes (header prose 478 → 446, and re-trimmed where CR-1/CR-2/CR-3 needed room), and step 2 — merging two assertions of the same group — was **refused**: its maximal permitted extent (14→7) lands at ≈390, so the cap was unattainable by every permitted lever combined, and it contradicts K-17/BC-I and moves `baseline.json`. Element table below. **Stage 5 ruled the drift EARNED and amended BC-E to 450 over a re-derived binding floor of 429**; 449 is inside the amended cap and nothing was dropped to reach it. |
| D-2 | **BC-D**: ≤ **80** added lines across C-2 … C-7 | delivered **104 `+` / 50 net** | No clause dropped: BC-B's narrowing (9), K-15's four clauses (9), FR-19's two rows (2), K-16's three edits (8), FR-14/FR-15's two steps (21), FR-18's three hunks (20) are each required by a requirement row. The `+` metric charges rewritten lines as additions — C-5 is +20/−20, net 0. **Stage 5 ruled the drift EARNED and restated the cap as 60 net**; delivered 50 net. |
| D-3 | I-1: `--list` prints `NAME — first docstring line` | prints `NAME<2 spaces><first docstring line>` | Keeps every printed byte ASCII, so the run cannot raise `UnicodeEncodeError` on a non-UTF-8 stdout (insight index 14/20/21) — and it matches I-9's two-space result-line shape. |
| D-4 | I-4: the loader as designed defeats the `geteuid` predicate | **plus** every process-start name in `dir(os)` — `exec*` / `spawn*` / `fork*` / `system` **and** `popen` / `posix_spawn*` — raises `LoadRefused` on the shim | **BC-A.** One line of data (a name filter over `dir(os)`), no wrapper; see the disposition row for the recorded runs. |
| D-5 | I-11: separate FAIL details for "exited non-zero" and "no summary line" | one branch reporting `exit $rc, passed='$b4_passed'` plus the captured output | Both facts are in the one detail line, and B.4's added-line count stays inside a budget already over (D-2). Both cases still FAIL. |
| D-6 | C-8 / PQ-2: one glossary entry, beside the **assertion floor** entry "already at `CONTEXT.md:198-203`" | **two** entries, 15 lines — **assertion floor** was written as well | The term does not exist at `HEAD` (`git show HEAD:CONTEXT.md` finds it nowhere): design and gate both cite a line range that carries the *state document* entry. Shipping `baseline.json`'s floor while the glossary defines neither the floor nor the program that reads it would leave AC-16/FR-16's vocabulary undefined, so the missing entry was written rather than the citation trusted. Declared outside the C-2 … C-7 budget, like the entry it accompanies. |

**BC-E element table**, element for element against `02_RATIONALE.md`'s own 303-line derivation
(the one BC-E amended to a 325 floor / 350 cap). Every element ran over except `fixture()`; the
list named the right elements, it under-priced them.

| element | design (`02_RATIONALE.md`) | delivered | miss |
|---|---|---|---|
| header: purpose, usage, safety contract | 24 | 38 | +14 — BC-A's mechanism, its enumerated name set and its stated limit, plus BC-F's invariant, were all added after that table |
| imports (incl. K-5) + `PATHS` + witness roots + default source | 20 | 29 | +9 — K-5 is 2 statements + its justification; `PATHS` is 6 lines wrapped at 92 cols |
| `load()` | 16 | 26 | +10 — the process-start denial (D-4), R-77's comment, both post-restore asserts |
| `fixture()` + the inside-root predicate | 22 | **21** | −1 — the one element under budget, even after CR-3's strict predicate |
| `witness()` (+ `_facts`; the comparison lives in the runner) | 16 | 31 | +15 — BC-H's asymmetry statement is 7 of them |
| shared helpers (`_eq`, `_mode`, `_refused`, `_no_new_process`, `LoadRefused`) | 10 | 31 | +21 — 5 helpers, not 2; they *remove* ~25 lines from the assertions |
| 14 assertions | 155 (~11 each) | 190 (~13.6 each) | +35 — an assertion is `def` + docstring + fixture + 3-5 clause checks + evidence + 2 separators |
| `TESTS` tuple | 6 | 10 | +4 — 14 names + I-3's rationale |
| runner + `main()` + entry point | 34 | 73 | +39 — I-1's three CLI surfaces (`--source`, `--list`, name selection + unknown-name refusal) were folded into this line, and BC-5's after-witness runs on both exit paths |
| **total** | **303** | **449** | +146; 58 of the 449 are blank separators (30 top-level blocks). Stage 5's independent region-by-region floor: **429**, recoverable surplus ≈17 (3.8 %) |

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| BC-A | **Discharged** | Mechanism: `load()` copies `os.__dict__` into the shim, then rebinds to a raiser **every** name in `dir(os)` that starts a process — `exec*`, `spawn*`, `fork*`, `system`, **`popen`** (it runs `/bin/sh -c`) and **`posix_spawn*`** (3.8+; neither begins with `exec`/`spawn`/`fork`, which is the hole CR-1 named: a name prefix is not a capability either). The set was enumerated against `dir(os)`, not guessed; the header says so, and says that the list therefore *is* the guarantee, so a name a future CPython adds belongs in it. Because `bin/sc` binds that shim as its own `os` at import, the denial covers the whole run, not just the load. Recorded runs, each against a scratch copy of `bin/sc` (never `bin/sc` itself) whose guard reads `os.getuid()` — the uid source the shim does not cover — and starts a process by a different name: `os.execvp` → `LoadRefused … (first argument: ('sudo',))`; `os.popen("echo THIS-SHELL-MUST-NOT-RUN")` → `LoadRefused … ('echo THIS-SHELL-MUST-NOT-RUN',)` with that text never printed, i.e. no shell ran; `os.posix_spawn("/nonexistent-sc", …)` → `LoadRefused … ('/nonexistent-sc',)`. All three print `os restored  True` / `summary: 14 defined, 0 run, 0 passed`, **exit 2**; service `MainPID` identical before and after. **Control**: the same `posix_spawn` copy under the round-1 filter reaches the real `os.posix_spawn` and stops only because the target path does not exist (`FileNotFoundError`) — the hole was real, not theoretical. Stated limit (in the file header): an import-time re-exec that avoids `os` — `subprocess`, `ctypes` — is not covered; nothing here shims `subprocess`, and stage 5 ruled that limit acceptable given `SB_BIN` points at a non-existent path and K-2 forbids the spawning functions. |
| BC-B | **Discharged** | `docs/dev-map.md` "Patterns to avoid": the "fails closed if `geteuid` moves" clause is **gone**; the recipe now reads "**What it guarantees and what it does not**: it defeats the *predicate* … never the *capability* … a guard refactored to `os.getuid()` / `os.getresuid()` / `os.geteuid() > 0` re-execs the INSTALLED `sc` under `sudo` … Deny the capability too: on the shim, **every process-start name in `dir(os)`** must raise — `exec*` / `spawn*` / `fork*` / `system`, **and** `popen` … and `posix_spawn*` … A name prefix is not a capability either". |
| BC-C | **Discharged** | Pre-edit summary measured **before the first edit**, from the repository root, at HEAD `55f39f0`: **PASS 17 / WARN 0 / FAIL 0 / SKIP 1, exit 0** — the PM's measurement is **confirmed**. Post-edit: **PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0**; no WARN to attribute away. F.4 (30/30) and F.5 (300/300) still PASS; nothing in this task touched `.harness/insight-index.md` or `docs/tasks.md`, so the zero headroom is stage 7's to clear by rotation. |
| BC-D | **Reported; inside the amended metric** | Table above: **104** `+` / **50 net** vs BC-D-as-written's 80 `+`, and vs stage 5's restated **60 net**. Drift **D-2**, ruled earned. |
| BC-E | **Reported; inside the amended cap** | **449** lines vs BC-E-as-written's 350, and vs stage 5's amended **450** over a floor of 429. Element table above. Drift **D-1**, ruled earned — no clause dropped, and no line removed to chase a number. |
| BC-F | **Discharged** | Stated in the suite header, in the terms required: "every module attribute that **IS** a `pathlib.Path` … a Path inside a container escapes the scan, so `PERIODIC_DIRS` (`bin/sc:79-83`, a dict of Paths) and `SB_BIN` (a `str`) are handled by hand". Restated in `docs/dev-map.md`'s fourth recipe clause. Behaviour re-checked after CR-3's strict predicate: deleting the `IF_INET6_PATH` row from a scratch copy of the suite gives `fixture failed  AssertionError: Path constant(s) outside the run root: IF_INET6_PATH`, exit 2, zero assertions run. The predicate is `resolved == root or resolved.startswith(root + os.sep)` — the round-1 tuple's first alternative subsumed the second, so it accepted a sibling root that merely shares the prefix; it no longer does. |
| BC-G | **Honoured** | NFR 5's "The suite asserts these" is **not** repeated anywhere in this document. Named as uncovered by the 14: (a) `_write_private()`'s **exclusivity** as the writer of `config.json` — no assertion reaches a successful `generate_config()` write; (b) `sc config` **end-to-end** redaction — `cmd_config` is never driven, only `_redact` is. Carried to stage 6 in `## Open issues for review`. |
| BC-H | **Discharged** | The asymmetry is stated in `witness()`'s own docstring, with the cause (`bin/sc:1354` emits `experimental.cache_file.path = /var/lib/sing-box/cache.db`, so a running sing-box owns a file inside a witnessed directory). AC-5 was observed with the service **live** (`MainPID=2566751`, `NRestarts=0`, unchanged across the run); stage 6 re-takes it. |
| BC-I | **Discharged — restatement below** | K-17's rule as **actually applied**: *one assertion per fixture-and-subject group; a clause gets its own assertion when it needs its own fixture or its own subject, and clauses that share both ride in one assertion.* That is why FR-7's three clauses are three assertions (three subjects of `_userinfo`) while FR-9's three ride in two (one document fixture each), and why FR-10's two split by fixture rather than by clause. **14 is the outcome of that rule, not a target.** The binding non-vacuity mechanism is **RS-1's per-clause mutation list at stage 6** — not the assertion count and not the assertion total: an assertion is honest only when every clause it carries has a mutation that kills it, and a clause no reachable mutation kills is reported NOT-DISCRIMINATING. |
| BC-J | **Discharged** | B.4 invokes `python3 .harness/scripts/check-sc-contracts.py` with **no** `NAME` argument; it extracts `\([0-9]*\) passed` from the `summary:` line and compares it against `baseline.json`'s `test_count` (`(( b4_passed < b4_floor ))`). `{r}` ("run") is never read by the step. `--list` and name selection stay developer/stage-6 surfaces. |
| BC-K | **Discharged — offender list EMPTY** | Assertion 14 over the delivered tree: `182 entries in 1 table(s), 0 offenders`. The gate's independent read is confirmed; **C-9 did not fire, `bin/sc` is untouched, BC-11 never engaged.** |

## Open issues for review

- **Both caps were falsified rather than met**: the suite is 449 lines (BC-E as written: 350;
  amended by stage 5 to 450 over a measured floor of 429) and the external budget is 50 net
  (BC-D as written: 80 `+`; restated as 60 net). Nothing was trimmed to chase either number, and
  the amended figures are what stage 6 and the pool row should carry.
- **BC-A's stated gap stands, by ruling**: an import-time re-exec that does not go through the
  module's `os` (`subprocess`, `ctypes`) is not denied. Closing it means a second `sys.modules`
  shim bought against a hypothesis; `SB_BIN` points at a non-existent path and K-2 forbids the
  spawning functions. The limit is stated in the file header beside a now-true statement of what
  *is* covered — which is the condition stage 5 attached to accepting it.
- **The denial list is a name list.** It is complete against `dir(os)` on CPython 3.6-3.13 today,
  and the header says so, but nothing re-checks it: a process-start name added to `os` by a future
  CPython reopens the hole silently. The only standing guard is the sentence in the header and in
  `docs/dev-map.md`'s recipe.
- **`CONTEXT.md`'s glossary lacked the term the design said it had** (D-6). Worth a look at the
  next document-citing gate: C-8 and PQ-2 both cite `CONTEXT.md:198-203` for **assertion floor**,
  and that range holds the *state document* entry instead.
- **RS-7 stands**: K-5's pre-import line must gain any module `bin/sc` starts importing. Today it
  covers `argparse, base64, copy, hashlib, http.client, io, socket, stat, subprocess, time,
  urllib.parse, urllib.request` — `bin/sc`'s full import list minus what the suite itself imports.
- **BC-G's uncovered pair** (for `06_TEST_REPORT.md`'s coverage statement): `_write_private()`
  exclusivity and end-to-end `sc config` redaction are **not** asserted by the 14.
- **RS-4 stands**: `write_private_writes_utf8_bytes` is killed by an `encoding="latin-1"`
  substitution, **not** by deleting `encoding=` on this UTF-8 host. Sweep it with the codec
  substitution, or it reports a false kill.
- **AC-13 was not taken here** (PQ-7: a scratch clone or a move-and-restore, never during an AC-1
  measurement). Only the extraction was checked in isolation: a missing `baseline.json` yields an
  empty floor, which is B.4's FAIL branch. Stage 6 owns both wet cases.
- **AC-10's sweep is stage 6's.** My smoke checks (reported as smoke, not as the sweep): AC-11's
  `str(e)` build FAILs `unusable_fault_clause_is_a_class_name`; AC-12's emptied `$prepend` FAILs
  `dns_overlay_prepend_is_head_of_dns_rules`; a raising source and a syntax-error source both print
  `os restored  True` and exit 2 (AC-9).
- **AC-22's exclusion-free regex run hits a pre-existing line**, `restricted-network-regression.sh:43`
  (`TOKEN='--i-will-destroy-this-vm'`), which no hunk of this task touched; zero hits inside the
  diff. Recorded so stage 6 does not read it as this task's failure.
- **Untouched pool rows**: R-57 (both halves `--source`-only), R-7 (`install.sh` `t <key>` sites),
  R-75 (this task pins no `失败：` grep — it only *removes* that literal from a comment) and R-85
  remain open and unnarrowed.
- `.harness/insight-index.md` is at 30/30 and `docs/tasks.md` at 300/300. Neither was touched here;
  a stage-7 harvest tips F.4 and must be cleared by `archive-task` rotation (BC-C), never by editing
  a cap — and note insight index line 29: the rotation itself can silently lose lines.

## Dev-map updates

- The "no test directory" paragraph now states that the committed tests live in
  `.harness/scripts/` (`.gitignore:19` ignores `test/`) and names B.4 and B.5.
- The loader recipe's guarantee is narrowed (BC-B): it defeats the predicate, not the capability,
  so the recipe now demands that **every process-start name in `dir(os)`** raise on the shim —
  `exec*` / `spawn*` / `fork*` / `system` **and** `popen` / `posix_spawn*` — with the note that a
  name prefix is not a capability either.
- The recipe gains the four required clauses: `encoding="utf-8"` (R-77) — written **inside the
  copy-pasteable block**, which is what a reader copies, as well as in the prose; the
  argparse-usage-error-at-exit-2 signature (R-78); the `("doctor", "config")` read-only arm
  (R-84); and `check-sc-contracts.py` as the working reference — the last one carrying the
  Path-invariant limit (BC-F).
- The repointing clause names **nine** path constants, `LIB_DIR` included, and says which two are
  not under `/etc/sing-box` — matching the working reference the same paragraph cites.
- `restricted-network-regression.sh`'s row: "Deliberately **not** wired into `verify_all`" is
  replaced by "since T-28 it is wired as `verify_all` B.5 — the token form stays operator-only".
- New `## Reusable utilities` row: `check-sc-contracts.py`, what it asserts, how it loads, what it
  never calls.

## Insight to surface

- An element-list-derived line cap under-prices a test artifact by ~45 % even when the list names every element correctly: T-28's suite was floored at 303 (re-derived 325, capped 350) and delivered **449** with no clause dropped, and **every** element ran over but one — assertions 155 → 190 (an assertion is a docstring + a fixture + 3-5 clause checks + an evidence line + 2 separators, ~13.6 lines, not the ~11 charged), runner + CLI 34 → 73, shared helpers 10 → 31, header 24 → 38 — so a cap on a file nobody has written yet is a guess whose error bar is the artifact's own size, and the fix is to amend it against a re-derivation (stage 5 measured a 429 floor and amended to 450), never to trim to the number · evidence: `.harness/scripts/check-sc-contracts.py` (449 lines, 14 assertions) vs `02_RATIONALE.md` "Line budget derivation"
- `docs/dev-map.md`'s loader shim becomes `bin/sc`'s `os` **permanently** — `sys.modules["os"]` is restored in the `finally` but the loaded module keeps the shim in its globals, so a capability *deleted* from the shim stays denied for the whole run: rebinding every process-start name to a raiser turns "fails closed against process replacement" into one line of data instead of a wrapper, and a `bin/sc` copy whose guard reads `os.getuid()` then aborts the run at exit 2 instead of `sudo`-re-execing the installed build · evidence: `.harness/scripts/check-sc-contracts.py` `load()`
- A name prefix is not a capability either — the substitution repeats one level up: `dir(os)`'s process-start set is **not** covered by `("exec", "spawn", "fork")` + `system`, because `popen` (which runs `/bin/sh -c`) and `posix_spawn`/`posix_spawnp` (3.8+) begin with none of them, so a denial filter written from the obvious prefixes lets a re-exec through and the "what this covers" sentence beside it is false as written · evidence: `.harness/scripts/check-sc-contracts.py` `load()` — control run: a scratch guard calling `os.posix_spawn` reaches the real call under the prefix-only filter and is refused under the enumerated one

## Verdict

READY FOR REVIEW
