# T-28 · committed-test-suite — Requirement Analysis

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

`bin/sc` has no committed test: every contract it ships is held by construction and by a
throwaway harness that is deleted at delivery, so `verify_all` can prove the file parses and
nothing about what it does — and discharging that requires importing `bin/sc` on the owner's
live machine on every future `verify_all` run, which is itself the hazard R-9 was deferred five
times over.

## In-scope behaviors

**FR-1** — Exactly one new committed file carries the suite, placed in `.harness/scripts/`
beside `check-i18n-parity.sh` and `restricted-network-regression.sh`. It adds no directory, no
framework, no fixture library, no mock server, no separate runner and no second file.

**FR-2** — The suite loads `bin/sc` as a module through the neutralisation recipe in
`docs/dev-map.md` (`## Patterns to avoid`): an `os` shim in `sys.modules` whose `geteuid` reads
`0`, the source compiled and executed unmodified, the real `os` restored in a `finally`. It
never executes `bin/sc` as a child process, never invokes `/usr/local/bin/sc`, and loads at most
once per process.

**FR-3** — Every assertion is made by calling a named function of the loaded module. The suite
calls neither `main()` nor `_init_files()`.

**FR-4** — The `bin/sc` under test is a parameter of the run, defaulting to the repository's own
copy, so a deliberately mutated copy is driven without editing the suite.

**FR-5** — The suite runs every assertion, one named assertion, or lists the names, selected on
the command line.

**FR-6** — Each assertion carries a stable name; the run prints one result line per assertion
and a final summary carrying the number defined and the number passed, and exits `0` if and only
if every assertion defined was executed and passed.

**FR-7** — The suite asserts `_userinfo(authority)`'s three projections: the userinfo ends at the
authority's **last** `@`, the field boundary is the **first raw** colon, each projection is
percent-decoded exactly once, and `whole` is not derivable from `(first, rest)`.

**FR-8** — The suite asserts `_write_private(path, text)` leaves the target at mode exactly
`0600` under a hostile process umask, over a pre-existing wider target, and over a symlinked
target, and that the written bytes decode as UTF-8 independently of the process locale.

**FR-9** — The suite asserts `_read_state()`'s contract: an explicit UTF-8 decode (a UTF-16
document is refused by name), one top-level shape check per document, the `default` split between
absent-is-empty and absent-is-failure, and one `OverrideError` family carrying `.path`.

**FR-10** — The suite asserts the override envelope: each merge-directive violation at an array
key raises `OverrideError` with the vocabulary sentence, and the unusable-document sentence's
fault clause is a bare exception **class name** — no whitespace, no quote, and no substring of
the offending override document.

**FR-11** — The suite asserts `_redact(value, strict)`: every `SECRET_KEYS` name is masked at
every depth of a whole document; inside `outbounds` a key outside `VISIBLE_IN_OUTBOUND` is masked
at every depth; the mask replaces the value and never the key; and the mask carries nothing
derived from what it replaced.

**FR-12** — The suite asserts `_dns_overlay(suppress)`'s `$prepend` payload is **non-empty** and
that its emitted position is the head of `dns.rules` in the composed document, for both values of
the decision.

**FR-13** — The suite asserts that every `zh` entry in `TRANSLATIONS` names a placeholder set that
is a subset of its own key's placeholder set, so no `t()` call passing keyword arguments can raise
under `LANG = "zh"`.

**FR-14** — `verify_all.sh` gains two new steps inside the `HARNESS:B-CUSTOM` markers: **B.4**
runs the suite, **B.5** runs `restricted-network-regression.sh --self-check`. Neither replaces,
renames or widens B.1, B.2 or B.3.

**FR-15** — B.4 reads the assertion floor from `.harness/scripts/baseline.json` and FAILs when the
number of assertions passed is below it, when the suite exits non-zero, or when `baseline.json`
is absent or unreadable.

**FR-16** — `baseline.json`'s `test_count` and `passing_count` are set to the count the delivered
suite reports, and its `notes` field states which program reads the file and what the number
means.

**FR-17** — In `verify_all.ps1`, every `B.*` id names the identical check its `verify_all.sh`
counterpart names; a check the mirror cannot run returns SKIP and states the reason on the run's
output.

**FR-18** — `restricted-network-regression.sh` is corrected on the three defects this task's
wiring makes load-bearing or reaches for free: `uncoverable()` rejects a userinfo-bearing
authority (**R-56**), E3 and E4 report their own falsified observation as FAIL rather than
`BLOCKED` (**R-59**), and the comment at `:31` no longer asserts of itself something false
(**R-58**).

**FR-19** — `docs/dev-map.md`'s loader recipe gains the three clauses filed against it —
`encoding="utf-8"` on the source read (**R-77**), the argparse-usage-error-at-exit-2 failure
signature of a skipped recipe (**R-78**), and the fact that every command except `doctor` and
`config` drives `_init_files()` (**R-84**) — plus one clause naming the committed suite as the
recipe's working reference. `.harness/rules/50-singbox-cli.md`'s `<your test command>` placeholder
and its "no test directory" sentence are replaced by the real command; `docs/dev-map.md`'s
"Deliberately not wired into `verify_all`" row for `restricted-network-regression.sh` is corrected
to what ships.

## Out of scope

1. Any coverage requiring a second process or a controlled process environment — the stdout
   wrapper, every encoding/locale criterion, and T-25's output-layer contract as a whole. Re-homed
   as a row.
2. Wiring the token form of `restricted-network-regression.sh`; only `--self-check` is wired.
3. Closing R-7's second B.2 blind spot (`install.sh` `t <key>` call sites) and any other change to
   `check-i18n-parity.sh` or to B.2's scope.
4. Replacing, repurposing or removing B.3's `SKIP`.
5. R-57 (the two `--source`-only derivation defects), unreachable through the default source.
6. Any change to `bin/sc` behaviour, except `zh` translation-string repairs required by FR-13 and
   bounded by BC-11.
7. Coverage of `clash_api()`, `stored_delays()`, `_egress_ip()` or any function whose subject is a
   socket, a service or the network.
8. Coverage of `install.sh`, `uninstall.sh` and `systemd/` beyond what B.1, B.2 and B.5 already do.
9. A test directory, a test framework, a dependency manifest, a lint config, a `.gitignore` change.
10. `.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md`, and every A.*, E.* and F.* step of
    both `verify_all` mirrors.
11. Making `_init_files()`'s `/var/lib/sing-box` literal repointable.
12. Any operator obligation, VM run, or criterion needing root.

## Boundary conditions

**BC-1** — Effective uid is 0 → the suite refuses before loading anything, prints one line naming
the refusal, and exits non-zero.

**BC-2** — Before any assertion runs, every one of the eight path constants (`CFG_DIR`, `CFG_PATH`,
`NODES_PATH`, `SETTINGS_PATH`, `RULES_DIR`, `OVERRIDE_PATH`, `STATE_PATH`, `IF_INET6_PATH`) is
asserted to resolve inside the run's own temporary root → a constant added to `bin/sc` later and
not repointed makes the suite fail loudly, never write outside that root.

**BC-3** — `bin/sc` raises during load → the real `os` module is restored anyway, the restoration
is asserted, and the suite exits non-zero naming the load failure.

**BC-4** — The run's temporary root is created with `mkdtemp` and removed at exit; a removal
failure is reported by path and never silent. No fixed path is used, so two concurrent
`verify_all` runs cannot collide.

**BC-5** — `/etc/sing-box`, `/etc/sing-box/*` and `/var/lib/sing-box` are witnessed read-only
before and after the run; any difference in existence, inode, mode, size or mtime → the run FAILs
naming the path, whatever the assertions said.

**BC-6** — `python3` is absent → B.4 FAILs, matching B.1's treatment of the same absence; it never
SKIPs.

**BC-7** — The suite resolves the repository root from its own file location, never from the
current working directory, so `verify_all`'s cwd trap does not reproduce inside it.

**BC-8** — No line of the suite matches `verify_all` A.1's secret pattern: a literal following a
`password` / `secret` / `token` / `api_key` key carries at most 7 characters between its quotes.
Fixture hosts are `.invalid` names or `203.0.113.0/24` literals.

**BC-9** — No real credential byte, from any host or any node, appears in the suite, in its output,
or in any stage document of this task.

**BC-10** — The suite crashes, is skipped, or executes zero assertions → B.4 FAILs. A run that
reports fewer assertions than it defines is a failure, not a partial pass.

**BC-11** — FR-13's assertion finds offending `zh` entries → up to three are repaired in place as
translation-string edits and named in the delivery; a fourth makes the repair a re-homed row, and
the assertion is neither weakened nor removed in either case.

**BC-12** — `restricted-network-regression.sh --self-check` exits non-zero → B.5 FAILs and prints
the script's output. B.5 never passes the destructive token and never runs the script as root.

**BC-13** — Both mirrors' new steps live inside the `>>> HARNESS:B-CUSTOM:BEGIN/END <<<` markers,
which `/harness-upgrade` preserves; nothing is added outside them.

**BC-14** — No new step's id or name contains the substring `PASS`, which `verify_all.sh`'s summary
counts by matching against the whole `id|name|status` record.

**BC-15** — A step that PASSes prints no output beyond its own status line; output is emitted only
on FAIL, matching B.1 and B.2.

**BC-16** — The only child process the suite spawns is the stub `sing-box` script it wrote into its
own temporary root. It opens no socket, resolves no name and reads no file outside that root except
`bin/sc` itself.

## Acceptance criteria

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | `bash .harness/scripts/verify_all.sh` from the repository root reports **PASS 19 / WARN 0 / FAIL 0 / SKIP 1** and exits 0. | [B] | Run it. Falsified by any other four-number summary; the task-start baseline is 17/0/0/1 and the two new steps are both real. |
| AC-2 | The suite exits 0 on the delivered tree, and its summary line's "passed" count equals its "defined" count. | [B] | Run the suite directly. Falsified by a non-zero exit or unequal counts. |
| AC-3 | Every assertion is individually runnable by name, and `--list` names them all. | [B] | Run one by name and compare `--list`'s output against the summary's defined count. Falsified by a name that cannot be selected. |
| AC-4 | Running the suite as root refuses before `bin/sc` is loaded. | [B] | Invoke the refusal branch by stubbing the euid read in a copy, or observe the branch is taken before the load statement. Falsified by any load occurring under euid 0. |
| AC-5 | After a full run, `/etc/sing-box`, every entry directly inside it, and `/var/lib/sing-box` are unchanged in existence, inode, mode, size and mtime. | [B] | The witness is taken by the suite and re-taken independently outside it. Falsified by any differing field. |
| AC-6 | After a full run, `systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts sing-box` is identical to the pre-run reading. | [B] | Taken outside the suite, before and after. Never `is-active`. Falsified by any changed field. |
| AC-7 | No process spawned by the run has `/usr/local/bin/sc` or `sudo` as its executable. | [B] | Assert the suite's own spawn sites, and confirm `bin/sc` is loaded only through the neutralised loader. Falsified by a single such spawn. |
| AC-8 | Every one of the eight path constants resolves inside the run's temporary root, asserted by the suite before any assertion executes. | [B] | Delete one repointing line in a scratch copy: the suite must fail, not write outside. Falsified if it proceeds. |
| AC-9 | After the load, `sys.modules["os"]` is the real `os` module, including on a load that raises. | [B] | Assert both paths, the second with a deliberately broken source copy. Falsified by a leaked shim. |
| AC-10 | Every assertion the suite defines is shown to fail against at least one deliberately mutated copy of `bin/sc`, and the mutation and the resulting failure are recorded per assertion in `06_TEST_REPORT.md`. | [B] | FR-4's subject parameter drives a mutated clone. Falsified by any assertion that passes against every mutation reachable for its subject — which must then be reported NOT-DISCRIMINATING, never as passed. |
| AC-11 | The FR-10 fault-clause assertion fails against a build using `str(e)` in place of `type(e).__name__`. | [B] | Named instance of AC-10, discharging R-71. Falsified if that build passes. |
| AC-12 | The FR-12 assertion fails against a build whose `_dns_overlay` `$prepend` payload is emptied. | [B] | Named instance of AC-10, discharging R-80's silent `[] == []` mode. Falsified if that build passes. |
| AC-13 | B.4 FAILs when the suite reports fewer passed assertions than `baseline.json`'s `test_count`, and when `baseline.json` is absent. | [B] | Run the step against a lowered suite and against a moved `baseline.json`. Falsified by a PASS in either case. |
| AC-14 | `baseline.json`'s `test_count` equals the number of assertions the delivered suite defines, and `passing_count` equals it. | [S] | Compare the file against the suite's own summary. Falsified by any inequality. |
| AC-15 | `verify_all.sh`'s B.1, B.2 and B.3 are byte-identical to the task-start versions, and the added lines lie entirely inside the `HARNESS:B-CUSTOM` markers. | [S] | `git diff` against the task-start commit. Falsified by one changed byte outside the markers or inside B.1–B.3. |
| AC-16 | For each of B.1, B.2, B.3, B.4, B.5, the id and the check name in `verify_all.ps1` name the same check as in `verify_all.sh`, and every `.ps1` step that cannot run states its reason. | [S] | Read both files side by side. Falsified by an id whose two names describe different checks, or a bare SKIP with no stated reason. |
| AC-17 | `bash .harness/scripts/restricted-network-regression.sh --self-check` exits 0, writes no file, and reports all four shipped bases covered. | [B] | Run it; witness the filesystem around it. Falsified by a non-zero exit or any write. |
| AC-18 | `uncoverable()` returns "cannot cover" for the authority `u@cdn.example`, and the four shipped bases stay covered. | [B] | Drive `--self-check --source` over a copy carrying that base. Falsified by `SELF-CHECK OK` on it. |
| AC-19 | On an observation that is already falsified on its own terms, E3 and E4 report `FAIL`, not `BLOCKED`; `BLOCKED` remains for an observation that could not be taken or could not be falsified. | [B] | Drive the two verdict expressions directly over the recorded no-egress state. Falsified by a `BLOCKED` on a falsified observation. |
| AC-20 | The suite is `python3 -m py_compile`-clean and uses no syntax newer than Python 3.6 and no import outside the standard library. | [S] | Compile it; enumerate its imports. Falsified by a single non-stdlib import or a 3.7+ construct. |
| AC-21 | Two consecutive runs of the suite produce identical output apart from the temporary root's path. | [B] | Run twice, diff. Falsified by any other difference — a clock, a network or a random dependence. |
| AC-22 | No line of the committed diff matches `verify_all` A.1's secret pattern, evaluated without the `.harness/` exclusion. | [S] | Run A.1's own regex over the diff with the exclusions removed. Falsified by one hit. |
| AC-23 | `docs/dev-map.md` and `.harness/rules/50-singbox-cli.md` describe what ships: the real test command, the wired `--self-check`, and the three loader-recipe clauses of R-77 / R-78 / R-84. | [S] | Read both against the delivered tree. Falsified by any surviving `<your test command>`, "no test directory", or "not wired into `verify_all`" claim. |
| AC-24 | The whole of B.4 completes in under 5 seconds of wall clock on the pool host. | [B] | Time the step. Falsified by a longer run; a suite that needs longer has grown machinery this requirement forbids. |

## Non-functional requirements

- **Size, derived from the element list, not from a round number (R-61).** Floor by element:
  header + safety block 28, imports 10, loader 22, fixture root 34, host witness 14, assertion
  runner 30, and the seven assertion groups 22 / 24 / 26 / 30 / 20 / 12 / 18, entry point 10 —
  **300 lines**. The cap is **330** (a 10 % margin over that floor). A gate that finds this cap not
  credible **amends** it against a re-derived element list and records the derivation; approving a
  cap it disbelieves is the defect R-61 filed.
- Everything outside the suite file is capped at **60 added or changed lines** in total across
  `verify_all.sh`, `verify_all.ps1`, `baseline.json`, `restricted-network-regression.sh`,
  `docs/dev-map.md` and `.harness/rules/50-singbox-cli.md`.
- The suite depends on the standard library only, holds `bin/sc`'s Python 3.6 syntax floor, and
  requires no dependency manifest.
- The suite performs no network access; its only child process is the stub written into its own
  temporary root (BC-16).
- Every committed credential contract stays as delivered: `_write_private()` remains the only
  writer of `config.json`, credential bytes are never wider than `0600` at any instant, and
  `sc config` remains always-redacted. The suite asserts these; it never relaxes them.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Which `verify_all` step id carries the suite? | **B.4**, with **B.5** for the self-check. B.3 stays a `SKIP` named `Lint`, untouched and unrepurposed; B.2 stays `check-i18n-parity.sh install.sh` at exactly today's scope. `.harness/rejected-decisions.md § ruleset-unit-tests-in-t02` already names B.4 as the unblock path. |
| Q-2 | What summary does `verify_all` produce after this task? | **PASS 19 / WARN 0 / FAIL 0 / SKIP 1**, exit 0. Two real steps are added to today's 17/0/0/1; B.3 remains the single SKIP. |
| Q-3 | What makes `baseline.json` honest rather than merely non-zero? | A program reads it. T-07 declined to populate it because nothing in the repository read it and no assertion could run; after this task B.4 reads `test_count` as a floor and FAILs below it, so a number that stops corresponding to what runs turns the gate red instead of decorating a file. |
| Q-4 | Do realistic fixture credentials threaten A.1? | Not as filed, and the constraint binds anyway. A.1's own pathspec excludes `.harness/*` in both mirrors, so a suite placed per FR-1 is never scanned by it — which makes placement the load-bearing fact and therefore a bad thing to rely on. BC-8 and AC-22 bind the suite's content as if it were scanned. |
| Q-5 | Is a `bin/sc` suite the natural place to close B.2's blind spot? | **No.** R-7's second blind spot is `install.sh`'s Bash `t()` aborting under `set -u`; `bin/sc`'s `t()` returns the key itself in English for a missing entry, by design, so the two have opposite failure directions and no shared artifact. The `bin/sc`-side hazard that *is* real and covered by nothing — a `zh` entry whose placeholder set exceeds its key's, which raises at `msg.format(**kwargs)` — is covered here as FR-13. R-7 stays open and unnarrowed. |
| Q-6 | R-59's requested requirement ruling: `BLOCKED` or the condition's own verdict? | **The condition's own falsified observation outranks a harness-level prerequisite doubt.** Where a condition's observation is already FAIL on its own terms, the verdict is `FAIL`; `BLOCKED` is reserved for an observation that could not be taken or could not be falsified. This resolves the K-11 / BC-10 collision in BC-10's favour and is implemented at E3 and E4 by mirroring E5's existing shape. |
| Q-7 | Which row carries the AAAA position test's silent failure mode? | **R-80**, not R-85. R-85 is a `CHANGELOG.md` wording row owned by the next task editing that entry and is out of this task's scope; the emptied-`$prepend` mode is R-80, and FR-12 / AC-12 discharge it. |
| Q-8 | Why is T-25's output-layer contract left untested? | Because no honest same-process assertion of it exists, and the process-multiplying alternative is forbidden. An `io.StringIO` capture presents no `.buffer`, so it exercises the unwrapped stream and certifies nothing; `main()` cannot be called twice in one process; and every locale criterion needs `PYTHONUTF8=0` in a child, which would mean executing `bin/sc` as a program and re-opening the auto-elevate hazard this task exists to close. Re-homed as a row, with the constraint stated. |
| Q-9 | How is the suite's own non-vacuity proven, given R-22? | Per assertion, at stage 6, by driving FR-4's subject parameter against deliberately mutated copies of `bin/sc` in a scratch clone, with the mutation and the observed failure recorded per assertion in `06_TEST_REPORT.md` (AC-10). The committed artifact carries no mutation machinery. An assertion no reachable mutation kills is reported **NOT-DISCRIMINATING**, never as passed. |
| Q-10 | Which of T-07's four defects are fixed here? | R-56 and R-59 (FR-18) because B.5 makes the first load-bearing and R-59 is addressed to this stage by name; R-58 because it is one comment line in a file this task already opens. **R-57 stays open** — both halves are `--source`-only and unreachable through the default source, and repairing the `sed` range and the `grep` pattern carries its own failure modes for no reachable defect. |
| Q-11 | Is the restricted-network scenario itself wired in? | Only `--self-check`, which needs no root, no network, writes nothing, and returns before every refusal gate. The token form stays operator-only under `.harness/operator-obligations.md` row 2; wiring it would put a root-requiring, `/etc/hosts`-writing installer run inside `verify_all`, which is this task's stated red line. |
| Q-12 | Must the suite run on Windows? | No. It asserts POSIX file modes and reads `os.geteuid`, so it is Linux-only by subject. `verify_all.ps1` names B.4 and B.5 identically to the `.sh` and returns SKIP with the reason stated — the same honesty discipline as a BLOCKED criterion, and the discharge R-6 actually asks for. |
| Q-13 | Where does the suite live? | `.harness/scripts/`. `.gitignore:19` ignores `test/` wholesale, so a test directory would need a `.gitignore` change and would put the suite outside the directory both existing committed test artifacts already occupy. |
| Q-14 | Should `_init_files()`'s hard-coded `/var/lib/sing-box` be made repointable so a fixture can drive it? | **Declined.** FR-3 forbids driving `_init_files()`, whose two branches are now nothing but `save_nodes()` / `save_settings()` calls the suite covers directly, so the constant buys this task nothing and would be a product edit made for a test's convenience. Re-homed as a row against R-84's family. |
| Q-15 | Does the committed suite replace `docs/dev-map.md`'s prose recipe? | No. The prose stays and gains one clause naming the suite as its working reference, so a future author can read the rule before reading the code. |
| Q-16 | May any `verify_all` step be weakened, renamed or widened to make a new step pass? | No. AC-15 pins B.1–B.3 byte-identical and confines every added line to the `HARNESS:B-CUSTOM` markers; a new step that cannot pass is a FAIL to be fixed or a BLOCKED to be filed, never a loosened neighbour. |

## Verdict

READY
