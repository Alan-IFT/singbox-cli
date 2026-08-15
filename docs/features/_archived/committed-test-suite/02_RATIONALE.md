# T-28 · committed-test-suite — Rationale

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Load `bin/sc` without the sudo re-exec | the `sys.modules["os"]` shim recipe | `/home/alan/Programs/singbox-cli/docs/dev-map.md:121-158` | **Reuse verbatim** — mandated, and the design adds only `encoding="utf-8"` (R-77, already filed against the recipe). No new neutralisation idea. |
| A working instance of that recipe | `load_sc()` / `repoint()` | `docs/features/_archived/config-write-permission-hardening/06_TEST_REPORT.md:456-476`; `docs/features/_archived/share-url-userinfo-contract/06_RATIONALE.md:218-249` | **Reuse the shape** — T-13's loader and T-22's eight-constant repoint are the two preserved listings; the design keeps their structure and drops what this task does not need (T-13's `PublishSpy`, its `SC_HEAD_SRC` differential, T-22's fixture/compare split into three files). |
| A committed check with a runner, exit codes and a `verify_all` wiring | `check-i18n-parity.sh` | `/home/alan/Programs/singbox-cli/.harness/scripts/check-i18n-parity.sh` | **Reuse the conventions** — 0755, no `.ps1`, self-locating (`SELF_DIR`, `:31`), `mktemp -d` + `trap` cleanup, hard-fail on "cannot decide". B.4 copies B.2's step shape (`.harness/scripts/verify_all.sh:70-76`) almost line for line. |
| A committed scenario harness already wired to nothing | `restricted-network-regression.sh` | `/home/alan/Programs/singbox-cli/.harness/scripts/restricted-network-regression.sh` | **Reuse as-is and wire `--self-check`** — the `--self-check` arm already needs no root, no network and writes nothing (`:140-146`), and it returns before every gate. No new self-check is written. |
| An assertion floor a program reads | `baseline.json` | `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json` | **Reuse the file** — it exists with `test_count: 0` and no reader (R-4/R-9). This task gives it its first reader instead of inventing a counts file. |
| E3/E4's "falsified observation" verdict shape | E5's verdict expression | `restricted-network-regression.sh:273` | **Reuse the shape** — R-59's fix is to mirror `[ "$st" = PASS ] && [ "$agree" -eq 0 ]`, not to invent a third verdict rule. |
| Placeholder extraction for FR-13 | (none in-tree; `check-i18n-parity.sh` counts `printf` specifiers for **Bash**) | — | **New, but stdlib**: `string.Formatter().parse` is the exact reader `str.format` uses, so the assertion reproduces the production failure rather than approximating it. No regex, no parser. |
| A `sing-box` stub for `generate_config()` | `stub_sing_box()` | `06_TEST_REPORT.md:479-487` (T-13) | **Not reused — dropped.** See "The smaller design" below. |

Nothing else in `docs/dev-map.md`'s reusable-utilities table does any part of this: there is no
committed test artifact for `bin/sc` at all, which is the whole of R-9.

## The smaller design, and what the extra code buys

Rule 85 puts the burden on the larger design. Four places where a smaller one existed:

1. **No `sing-box` stub, and no child process at all.** BC-16 licenses one child (a stub written
   into the run root); T-13 shipped a six-line `stub_sing_box()`. The design instead repoints
   `sc.SB_BIN` at a path inside the root that **does not exist**. This is one line instead of six,
   spawns nothing, and *fails closed*: a future `bin/sc` path that reaches `subprocess.run` gets
   `FileNotFoundError` inside the assertion instead of silently executing something. It is
   affordable because the only assertion that drives `generate_config()` (I-26) raises inside the
   document envelope, well before the write and the checker. **The larger design buys nothing
   here, so it was dropped.**
2. **No name-by-name repoint assertion.** The obvious BC-2 implementation is eight `assert`
   lines. The design instead asserts over **every `pathlib.Path`-valued attribute of the loaded
   module** — two lines, and total: it covers the eight, it covers `LIB_DIR` (repointed for the
   same money, which also makes a stray `cmd_uninstall` find nothing instead of the real
   uninstaller), and it covers the ninth constant nobody has added yet, which is BC-2's stated
   purpose. Smaller **and** stronger.
3. **No baseline reader inside the suite.** Passing `--min N` to the suite would shave ~6 lines
   off B.4. Rejected: it moves the gate's judgment into the artifact being gated, so a suite that
   miscounts also decides whether the miscount matters. The floor comparison stays in B.4, where
   Q-3 put it.
4. **14 assertions rather than 7.** This is the one place the design takes the larger option, and
   it costs ~20 lines of boilerplate. What it buys is AC-10: with seven fat assertions, a single
   mutation that kills one clause makes the whole assertion fail, so every other clause in it
   *looks* discriminating and R-22's failure mode goes undetected — exactly the trap AC-10 exists
   to close. The stopping rule is "one assertion per independently mutatable clause", which is
   why the number is 14 and not 30.

The whole-design comparison is against **T-07's standard** (one file, no framework, no fixture
library, no runner, no second file, no directory): this design matches it — one file, no
directory, no dependency, stdlib only, no discovery mechanism (`TESTS` is a tuple), no assertion
base class, no fixture library (one function returning a directory), no mock server, no mutation
machinery. What it adds over T-07's artifact is a `--source` parameter and per-assertion names,
both pinned by FR-4/FR-5/FR-6 and both load-bearing for stage 6.

## Line budget derivation (R-61)

The requirement's floor list totals 300 with a 330 cap. Re-derived against **this** design's
element list rather than carried over:

| element | lines | note |
|---|---|---|
| header: purpose, usage, safety contract, what it never does | 24 | the durable artifact — a future editor reads it before the code |
| imports (incl. K-5's pre-import line) + `PATHS` + witness roots + default source | 20 | the path table is 10 lines of data |
| `load()` | 16 | incl. both post-restore asserts |
| `fixture()` + the inside-root predicate | 22 | repoint + BC-2's assertion, one table driving both |
| `witness()` + its comparison | 16 | |
| shared helpers (`raised()`, the placeholder reader) | 10 | used by six assertions |
| 14 assertions | 155 | ~11 each incl. one docstring line and one blank |
| `TESTS` tuple | 6 | |
| `main()` + entry point | 34 | root refusal, load, witness, run loop, summary, cleanup |
| **total** | **303** | cap **330**, ~8 % headroom |

Conclusion: the cap is **credible and confirmed, not amended**. The allocation differs from the
requirement's (a bigger constants block, a smaller loader and fixture, bigger assertion groups)
but the total lands within 1 %. The 60-line external budget is planned at 59, which is the
tighter of the two numbers and the one most likely to need a report (RS-6).

## Risk analysis

| # | risk | mitigation |
|---|---|---|
| R1 | **A future refactor of `bin/sc`'s elevate block defeats the neutralisation and `verify_all` re-execs the installed `sc` under sudo on the owner's machine.** This is the task's red line and R-78's live near-miss. | The shim neutralises `os.geteuid` rather than the `execvp` line, so it holds for any spelling of the elevate condition; it **fails closed** if `geteuid` moves (the branch is then taken with the real euid and `execvp("sudo", …)` raises or re-execs — either way `load()` never returns and the run FAILs). Two independent refusals at euid 0 (K-3). `SB_BIN` points at nothing (K-1). The host witness (I-7) is the third, evidence-independent line. |
| R2 | **A path constant is added to `bin/sc` later and writes under `/etc` from inside `verify_all`.** | The `Path`-attribute scan (I-5) fails the run for *any* unrepointed `Path`, not just the eight named ones. AC-8 tests it by deleting a repoint line. |
| R3 | **The suite passes vacuously** — an assertion that no mutation kills, reported as a pass. | One assertion per independently mutatable clause (K-17); AC-10's sweep at stage 6; three clauses already flagged as expected NOT-DISCRIMINATING or codec-specific (RS-3, RS-4, and assertion 14, which finds zero offenders today). `_aaaa_rule(True) != _aaaa_rule(False)` is asserted so I-29's two-decision loop cannot agree with itself. |
| R4 | **B.4 becomes a permanently green decoration** if the suite silently stops running assertions. | Three independent failure routes: the suite's own exit code, the `passed < test_count` floor, and "no summary line found" (I-11). BC-10 is enforced by the floor, not by the suite's self-report. |
| R5 | **The 60-line external cap is exceeded by the doc hunks.** | Per-file allocation in K-13 with a one-line margin; RS-6 tells stage 4 to report rather than silently overrun. The `.ps1` hunks are net-negative in three places (TODO comments replaced by one reason line each). |
| R6 | **The `os` shim leaks into a stdlib module** first imported during `exec`, leaving a `geteuid`-lying `os` in the process forever. | K-5's single pre-import line covers `bin/sc`'s whole import list; the `finally` covers `sys.modules`; AC-9 asserts the restoration on both paths. RS-7 hands the sync obligation to code review. |
| R7 | **FR-13 finds >3 offenders and BC-11 forces a re-homed row mid-task.** | A static read of `bin/sc:132-392` found **zero** offenders (every `zh` field name appears in its key), so the expected count is 0. RS-5 records the prediction so a disagreement at stage 4 is visible immediately rather than absorbed. |
| R8 | **`verify_all`'s cwd trap** (insight index line 13) makes B.4/B.5 report a false red from a subdirectory. | Not fixable here (out-of-scope 10 freezes the surrounding steps, and a `cd` inside the markers would change every later step). The suite itself is cwd-proof (BC-7, I-1), so the trap stays a property of the caller and cannot reproduce *inside* the artifact this task adds. |
| R9 | **The `generate_config()`-driving assertion (I-26) drifts** — a future edit makes the AttributeError unreachable and the assertion passes for the wrong reason. | It asserts the fault clause is **exactly** `AttributeError`, not merely "some class name", so a different exception class fails the assertion loudly rather than passing. |

## Evidence and citations

- Auto-elevate at import: `bin/sc:124-126` (`os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] …)`).
- The eight path constants: `bin/sc:23-38, 64`; `LIB_DIR` at `:43`; `PERIODIC_DIRS` holds `Path`s
  inside a **dict** (`:79-83`), so it is invisible to the attribute scan and is only ever written
  by `cmd_update_interval`, which no assertion calls.
- `_write_private`'s three elements (mkstemp / fchmod-while-empty / replace): `bin/sc:487-537`.
- `_read_state`'s explicit decode: `bin/sc:569`; `json.loads` auto-detecting UTF-16 from bytes is
  insight index line 16, which is why I-23's fixture must be *valid JSON* in UTF-16.
- The fault clause: `bin/sc:2133-2136` (`fault=type(e).__name__`), reachable through
  `_filter_rules`'s `rule.get("rule_set")` on a non-dict element (`bin/sc:1079`).
- `_dns_overlay` / `_aaaa_rule`: `bin/sc:1742-1773`; the second `dns.rules` writer is
  `_telemetry_overlay()` (`bin/sc:1850`), whose `$before {"clash_mode": "Global"}` anchor lands at
  index 2 on an ordinary host — insight index line 26, which is why I-29 composes against it.
- `_redact` / `MASK` / `SECRET_KEYS` / `VISIBLE_IN_OUTBOUND`: `bin/sc:3042-3102`.
- `t()`'s `msg.format(**kwargs)`: `bin/sc:480-482` — the raise FR-13 guards against.
- `main()` reassigns `LANG` after `parse_args` (`docs/dev-map.md:42`), and a fixture cannot call
  `main()` twice in one process (insight index line 25) — together the reason K-2 forbids it and
  the reason `sc.LANG` is set directly instead.
- `verify_all.sh`'s summary counts `id|name|status` records matching `PASS` (`:242`) — the source
  of BC-14. Step shapes copied: `:67-76`.
- `check-i18n-parity.sh`'s conventions: `:29-52` (self-location, `mktemp -d`, `trap`, hard exit 2).
- R-56/R-58/R-59/R-77/R-78/R-84 statements: `docs/tasks.md:161,163,164,240,241,264`.

## Decisions recorded

- **No entry added to `.harness/rejected-decisions.md`.** The one standing record this task
  touches, `§ ruleset-unit-tests-in-t02`, is *discharged* rather than re-confirmed: it names B.4
  as the unblock path and B.4 is what ships. Nothing was declined here that a future task would
  otherwise re-propose — the stub-`sing-box` and the `--min` flag were sized out, not ruled out,
  and both are recorded above where a future reader will actually look.
- **`CONTEXT.md` gains one term, `contract suite`.** The glossary already carries this task's
  `assertion floor`, and the agent contract requires a new domain term to be recorded inline. It
  is a seventh file relative to the requirement's named six, so it is declared as C-8 rather than
  slipped into the 60-line budget.
- **File name `check-sc-contracts.py`.** Parallel to `check-i18n-parity.sh`; "contract" is this
  project's own word for what the suite asserts (T-13's credential contract, T-22's userinfo
  contract, T-25's output-layer contract), and `sc` names the subject. `.py` because `py_compile`
  and `--source` both read it as Python (AC-20).
