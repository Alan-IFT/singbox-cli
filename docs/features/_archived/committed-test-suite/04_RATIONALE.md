# T-28 · committed-test-suite — Development rationale

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

## Rationale triggers reached

- **T4.1** (about to record `DESIGN DRIFT`) → read `02_RATIONALE.md` "Line budget derivation
  (R-61)" and "Risk analysis". Present; the element table in `04_DEVELOPMENT.md` is measured
  against it element for element rather than against the requirement's NFR list.
- **T4.4** (reworking after code-review defects) → read `05_RATIONALE.md`: Ruling 1's
  region-by-region floor (429) and trim arithmetic, and Ruling 2's enumeration of the uncovered
  `os` names. Present, and both are load-bearing here — the enumeration is what CR-1's fix is
  checked against, and Ruling 1 is why no line was removed to chase 350.
- **T4.2** fired once, on `02_SOLUTION_DESIGN.md` C-8 / `03_GATE_REVIEW.md` PQ-2: both cite
  `CONTEXT.md:198-203` as already defining **assertion floor**, and that range defines *state
  document* instead. `02_RATIONALE.md` was read (present) and repeats the claim without evidence,
  so the tree was believed over the citation — see drift D-6. No T4.3 (nothing blocked).

## BC-A — the recorded process-start runs, in full

Three scratch copies of `bin/sc`, each with the uid source moved off `geteuid` (so the shim's
predicate defeat does **not** apply) and the elevate body starting a process by a different name.
`bin/sc` itself untouched; `posix_spawn`'s target does not exist, so even an *undenied* call
spawns nothing:

```
$ sed -e 's/os\.geteuid()/os.getuid()/' bin/sc > $S/sc-getuid
$ sed -e 's/os\.geteuid()/os.getuid()/' \
      -e 's|^    os\.execvp("sudo".*|    os.popen("echo THIS-SHELL-MUST-NOT-RUN")|' bin/sc > $S/sc-popen
$ sed -e 's/os\.geteuid()/os.getuid()/' \
      -e 's|^    os\.execvp("sudo".*|    os.posix_spawn("/nonexistent-sc", ["x"], {})|' bin/sc > $S/sc-posixspawn

$ python3 .harness/scripts/check-sc-contracts.py --source $S/sc-getuid
load failed  LoadRefused: bin/sc tried to start or replace a process during load (first argument: ('sudo',)) -- its elevate guard is reading a uid source the geteuid shim does not cover
os restored  True
summary: 14 defined, 0 run, 0 passed
exit=2
$ python3 .harness/scripts/check-sc-contracts.py --source $S/sc-popen
load failed  LoadRefused: bin/sc tried to start or replace a process during load (first argument: ('echo THIS-SHELL-MUST-NOT-RUN',)) -- …
os restored  True
summary: 14 defined, 0 run, 0 passed
exit=2                       # and "THIS-SHELL-MUST-NOT-RUN" never appears: no shell ran
$ python3 .harness/scripts/check-sc-contracts.py --source $S/sc-posixspawn
load failed  LoadRefused: bin/sc tried to start or replace a process during load (first argument: ('/nonexistent-sc',)) -- …
os restored  True
summary: 14 defined, 0 run, 0 passed
exit=2

# CONTROL: the same copy under the ROUND-1 filter, restored byte for byte in a scratch
# copy of the suite (`if name.startswith(("exec", "spawn", "fork")) or name == "system":`)
$ python3 $S/suite-round1.py --source $S/sc-posixspawn
load failed  FileNotFoundError: [Errno 2] No such file or directory: '/nonexistent-sc'
os restored  True
summary: 14 defined, 0 run, 0 passed

$ python3 -c '…'
round-1  : ['execvp']
delivered: ['popen', 'posix_spawn', 'posix_spawnp', 'execvp']
```

The control is the point: under the round-1 filter the guard reached the **real**
`os.posix_spawn`, and only the missing target path stopped it. Had `bin/sc` been refactored to
`os.posix_spawn("/usr/bin/sudo", …)`, `verify_all` would have started a real process on the
owner's live machine. Service witness taken immediately before and after these commands, and
around the full `verify_all` run, unchanged: `MainPID=2566751 / NRestarts=0 /
ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`.

Why the denial is still data and not a wrapper: the shim already copies `os.__dict__`, so the
only missing step is to rebind the names that *start or replace a process*. What round 1 got
wrong was the belief — written into the header — that the prefixes `exec` / `spawn` / `fork` plus
`system` "cover every such name that exists on the platform, present and future". They do not:
`popen` and `posix_spawn*` are outside all three, and CPython added `posix_spawn` in 3.8, which is
itself the demonstration that this list decays. The delivered filter enumerates the set against
`dir(os)` and the header now says the list *is* the guarantee rather than claiming closure it
cannot have. `bin/sc`'s own legitimate `os.execvp("bash", …)` in `cmd_uninstall` is never reached,
because no assertion calls that command and the denial only binds inside the loaded module's `os`.

The asymmetry worth naming: `sys.modules["os"]` is restored in the `finally`, but the loaded
module keeps the shim in its globals **forever** — which is why the denial covers the whole run and
not just the import, and why `mod.os is shim` is asserted after the restore rather than before.

## Why the file is 449 lines, and what was actually tried

First working draft: **478** lines (14/14 passing on the first run); 446 after the trims below;
**449** after the review round, whose three code fixes cost +2 (`_execute`'s after-witness on the
failure path), +2 (the strict inside-root predicate), +2 net (the header's corrected coverage
claim) and −1 (`redact_masks_unlisted_keys_inside_outbounds`'s docstring re-flowed to one line so
`--list` stops truncating it). Two lines were reclaimed without losing a clause — the `TESTS`
comment and the K-5 comment each lost a wrapped line, and the BC-F paragraph one — because the
amended cap is 450 and a file that sits *on* its cap has no room for the next honest sentence.
Trims applied, in K-14's order:

1. Header prose compressed and de-duplicated against `load()`'s own comments — 38 → 36.
2. `_refused()` introduced and used at six raise-sites (assertions 7, 8, 9 ×4, 10): each site
   lost 4-5 lines of `try/except/else` boilerplate — assertions 225 → 191, helpers +12.
3. `_mode()` introduced; five `os.lstat(str(p)).st_mode & 0o777` expressions collapsed to fit on
   one line each.
4. `TESTS` packed two names per line; the runner's witness-diff print folded to one line;
   `main()`'s argv loop rewritten as a `pop(0)` loop.

Refused, deliberately:

- **Merging assertions of a group** (K-14's trim step 2). It saves ~4 lines per merge — I would
  have to merge nine of the fourteen to reach 350 — and it contradicts K-17/BC-I, moves
  `baseline.json`'s floor, and removes the per-name selection AC-3 and AC-10 both need.
- **One blank line between top-level definitions** instead of two. It would save 19 lines by
  making the file the only one in the repository that does not follow `bin/sc`'s own spacing.
- **`argparse` for the CLI.** It would save ~8 lines, but a bad flag would then print an
  *argparse usage error at exit 2* — the exact signature R-78 filed as "reads like a harness bug"
  and that this task's dev-map clause teaches readers to recognise as a skipped recipe.
- Dropping any clause of any assertion, or the witness, the `PATHS` scan or the `finally`
  (forbidden by K-14 and BC-D in so many words).

The honest conclusion is R-61's own: the cap was a pre-implementation estimate of a file nobody
had written, and the requirement's own instruction — derive from an element list, not a round
number — was followed by two documents and still landed 32 % low. The delivered file is the
smallest one that carries every clause the requirement lists. Stage 5 re-derived the floor region
by region at **429** and amended the cap to **450**, upholding the refusal of trim step 2 on
arithmetic (the maximal permitted merge, 14→7, lands at ≈390 — still over 350).

## Why `104` external `+` lines, or `50` net, rather than `80`

Per-file, what the added lines actually are:

- `verify_all.sh` **21**: 3 comment, 12 B.4 logic, 5 B.5 logic, 1 blank. The floor extraction, the
  summary extraction and the three FAIL branches are FR-15's three clauses.
- `verify_all.ps1` **18** replacing 10: five `Step` blocks at 4 lines each (FR-17 requires one
  printed reason per SKIP) + a 3-line comment stating F-9's ordering caveat.
- `restricted-network-regression.sh` **20** added / **20** deleted, **net 0** — this file is
  strictly smaller in content and identical in size; the metric charges every rewritten line.
- `docs/dev-map.md` **34** added / **15** deleted, **net +19**: 9 for BC-B's narrowing (the
  enumerated denial list, CR-1), 9 for K-15's four clauses, 5 for the test-directory paragraph, 1
  for the wiring correction, 1 for the utilities row, 1 token inside the copy-pasteable block for
  `encoding="utf-8"` (CR-4), and the repointing clause rewritten from eight constants to nine
  (CR-9).
- `.harness/rules/50-singbox-cli.md` **8**: K-16's three edits, exactly as planned.

Stage 5 falsified the `+`-only metric (it charges an in-place rewrite twice) and restated the cap
as **60 net**; the delivered figure is **50 net** (104 `+`, 54 `−`). I did not re-flow prose to
game either metric; the numbers are reported as `git diff --numstat` gives them.

## The three smaller review fixes, and why each is two lines rather than a mechanism

- **CR-2 (BC-5's after-witness on the failure path).** The obvious shape — a `_witnessed(before)`
  helper both paths call — costs 7 lines of helper plus 2 blanks to save 3, i.e. +7 against a cap
  with 4 lines of room. The delivered shape is +2: the load/fixture failure no longer returns
  early, it sets `selected, loaded = (), False` and falls into the one witness comparison that
  already existed. The summary line still renders `14 defined, 0 run, 0 passed` (BC-10, and B.4's
  `sed` still finds `0 passed` under the floor), and `if not loaded: return 2` keeps the exit
  status the failure path had. Proved by calling `_execute` with a deliberately falsified
  `before`: `WITNESS  /etc/sing-box  before=('FALSIFIED-BEFORE',) after=(…)` then `returned 2`.
- **CR-3 (the inside-root predicate).** `startswith((root, root + os.sep))` is a bare prefix test
  wearing a strictness costume. `(str(p) + os.sep).startswith(root + os.sep)` would have been one
  line and exactly right, but it is a trick a reader has to verify; the delivered form is the
  reviewer's own two clauses, +2 lines, and reads as what it claims. Checked directly: for
  `root=/tmp/sc-contract-ab` and `/tmp/sc-contract-abc/etc/config.json`, round 1 answers "inside",
  the delivered predicate answers "outside".
- **CR-7 (`--list` truncation).** One docstring, re-flowed to a single 88-column line; all 14
  `--list` lines now end in a full stop.
- **CR-1's mechanism was left name-based deliberately.** The alternatives are all bigger: an
  allow-list of `os` (a second maintenance surface), a `subprocess` shim (ruled out by stage 5 and
  by rule 85), or an audit hook (`sys.addaudithook`, 3.8+, below the project's 3.6 floor and a
  process-wide global the suite would have to remove again). The name list is the smallest thing
  that closes the hole, and its weakness — it decays as `os` grows — is now written where the
  next reader meets it, in the header and in the dev-map recipe, instead of being denied.

## The `CONTEXT.md` citation that does not hold (D-6)

`02_SOLUTION_DESIGN.md` C-8 and `03_GATE_REVIEW.md` PQ-2 both state that `CONTEXT.md:198-203`
already defines **assertion floor** — PQ-2 even quotes it as "already defines assertion floor in
terms of 'the committed test step'". `git show HEAD:CONTEXT.md` has no such term anywhere, and
`:190-200` is the **state document** entry. The likeliest reading is that the term was drafted in
a stage document and never landed in the tree. Shipping a `baseline.json` floor whose vocabulary
is undefined would have made FR-16's `notes` field the only place the concept exists, so the entry
was written (7 lines) alongside the one C-8 asked for (7 lines + a separator). Both are declared
outside the C-2 … C-7 budget, on the same ground C-8 gave for the first.

## Measurements taken that the contract portion only cites

| what | result |
|---|---|
| `python3 -m py_compile` on the suite | clean |
| import audit (AST) | 19 top-level modules, **all** stdlib; 0 f-strings, 0 walrus, no `capture_output=` / `missing_ok=` / `dataclasses` |
| two consecutive full runs, diffed | byte-identical (the run root's path never reaches stdout) |
| suite wall clock | 0.068 s |
| `--list` | 14 lines, one per assertion, no load |
| single-name run | `PASS  write_private_writes_utf8_bytes …` + `summary: 14 defined, 1 run, 1 passed`, exit 0 |
| unknown name | `unknown assertion(s): nope`, exit 2, nothing loaded |
| A.1's regex over the whole diff **with the `.harness/` exclusion removed** | 0 hits |
| host witness independent of the suite (`ls -lai` + `stat`, `/etc/sing-box` + entries + `/var/lib/sing-box`) around a full run | identical |
| self-check before C-5 / after C-5 | `SELF-CHECK OK: 4 shipped base(s), all covered`, exit 0, both times |
| self-check over a copy carrying `https://u@cdn.example/geo` | `SELF-CHECK FAIL: uncoverable base(s): https://u@cdn.example/geo`, exit 1 (AC-18 smoke) |

## Smoke-level non-vacuity (NOT the AC-10 sweep — stage 6 owns that)

| mutation | assertion | observed |
|---|---|---|
| `fault=type(e).__name__` → `fault=str(e)` | `unusable_fault_clause_is_a_class_name` | FAIL: `got "…({'str' object has no attribute 'get'})", want "…(AttributeError)"` |
| `$prepend: [_aaaa_rule(suppress)]` → `$prepend: []` | `dns_overlay_prepend_is_head_of_dns_rules` | FAIL: `the $prepend payload is empty for suppress=True` |
| `("IF_INET6_PATH", "if_inet6")` row deleted from a scratch copy of the **suite** | (the fixture gate) | `fixture failed  AssertionError: Path constant(s) outside the run root: IF_INET6_PATH`, 0 assertions run, nothing written outside the root |
| source raising at import / source with a syntax error | (the load gate) | `load failed  RuntimeError: boom at import` / `load failed  SyntaxError: invalid syntax`, both with `os restored  True` |
| `("IF_INET6_PATH", "if_inet6")` row deleted, re-run **after** CR-3's strict predicate | (the fixture gate) | unchanged: `fixture failed  AssertionError: Path constant(s) outside the run root: IF_INET6_PATH`, exit 2 |
| falsified `before` handed to `_execute` on the load-failure path (CR-2) | (the witness gate) | `WITNESS  /etc/sing-box  before=('FALSIFIED-BEFORE',) after=(…)`, `returned 2` |

Every one of these ran against a **copy** under the scratch directory; `bin/sc` was never edited,
and the four mutated copies are outside the repository.

## Assertion 14's subject, in case a later round disagrees

`182` entries in `1` table (`zh`), `0` offenders. The check is `string.Formatter().parse` on both
the key and the translation: a field name the translation uses that the key does not name, an
auto-numbered `{}`, a positional `{0}`, or an unmatched brace are each an offender, reported one
per line with its key. Since `t()` renders `msg.format(**kwargs)` with keywords only, `""` and a
digit-only field name are unusable by construction, which is why they are offenders rather than
merely unmatched. C-9 stayed empty; BC-11 was never engaged; `bin/sc` has no diff.
