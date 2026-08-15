# T-28 · committed-test-suite — Solution Design

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

One new file, `.harness/scripts/check-sc-contracts.py`, loads `bin/sc` through the
`docs/dev-map.md` shim recipe and asserts 14 named clauses by calling named functions of the
loaded module; nothing in `bin/sc` changes and no directory, framework, fixture library, mock
server, runner or second file is added.

The seam is **the loaded module object**: the suite's only coupling to `bin/sc` is the source
path (a `--source` parameter) plus the module attributes it repoints and calls, so a mutated
copy is driven with no machinery in the committed file.

`verify_all` gains two steps inside the `HARNESS:B-CUSTOM` markers — B.4 runs the suite against
`baseline.json`'s floor, B.5 runs the existing `restricted-network-regression.sh --self-check`;
B.1/B.2/B.3 and every A.*/E.*/F.* step are untouched.

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| C-1 | `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` | new | The whole suite: header, loader, fixture root, host witness, 14 assertions, runner, CLI. Mode 0755, shebang `#!/usr/bin/env python3`, English throughout. | single |
| C-2 | `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` | edit | B.4 and B.5 appended **after** the `step "B.3" …` line and **before** `# >>> HARNESS:B-CUSTOM:END <<<`. No other byte changes. | single |
| C-3 | `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.ps1` | edit | Inside the same markers: B.1/B.2 renamed to their `.sh` check names, the three `# TODO:` comment blocks replaced by one printed SKIP reason each (B.1/B.2/B.3), and two new SKIP steps B.4/B.5 with reasons. | single |
| C-4 | `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json` | edit | `test_count` and `passing_count` set to the delivered assertion count (14 as designed); `notes` rewritten to name B.4 as the reader and state what the number means. `version`, `created`, `warnings_baseline` unchanged. | single |
| C-5 | `/home/alan/Programs/singbox-cli/.harness/scripts/restricted-network-regression.sh` | edit | R-56 (`uncoverable()` rejects a userinfo authority), R-59 (E3/E4 verdict shape), R-58 (the `:31` comment). Three hunks, net-negative in lines. | single |
| C-6 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | Four hunks: the `:22` "no test directory" paragraph, the loader recipe (R-77 / R-78 / R-84 + the working-reference clause), the `restricted-network-regression.sh` row's wiring claim, and one new `## Reusable utilities` row for the suite. | single |
| C-7 | `/home/alan/Programs/singbox-cli/.harness/rules/50-singbox-cli.md` | edit | `<your test command>` → the real command; the "no test directory" sentence; the B.* status paragraph gains B.4/B.5. | single |
| C-8 | `/home/alan/Programs/singbox-cli/CONTEXT.md` | edit | One glossary entry, **contract suite**, beside the existing **assertion floor**. Outside the requirement's named six-file set; declared here rather than done silently. | single |
| C-9 | `/home/alan/Programs/singbox-cli/bin/sc` | edit (conditional) | `zh` translation-string repairs **only if** assertion 14 finds an offending entry (BC-11, ≤3 in place). A static read of `bin/sc:132-392` found **zero** offenders, so this row is expected to stay empty; it exists so a finding has a declared home. | single |

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | suite CLI | `python3 .harness/scripts/check-sc-contracts.py [--source PATH] [--list] [NAME …]` | `--source` defaults to `<this file>/../../bin/sc`, resolved from `__file__`, never from the cwd (BC-7, FR-4). `--list` prints one `NAME — first docstring line` per assertion and exits 0 without loading `bin/sc`. Bare `NAME`s select; no name selects all. |
| I-2 | assertion | `def <stable_name>(sc): """<FR-n> <one-line claim>""" … return "<evidence>"` | Module-level function; the function name **is** the stable id (FR-6) and the selectable name (FR-5); passes ⇒ returns a short evidence string, fails ⇒ raises. Takes exactly one argument, the loaded module, so FR-4's subject reaches every assertion unchanged. |
| I-3 | registry | `TESTS = (…)` — a tuple of the 14 functions in fixed order | Data, not discovery: the run order and `--list` order are the tuple's order, which is what makes two runs byte-identical (AC-21). `len(TESTS)` is the "defined" count and must equal `baseline.json`'s `test_count`. |
| I-4 | loader | `load(src) -> module` | Refuses at euid 0 **before** any read of `src`; installs a `types.ModuleType("os")` whose `__dict__` copies the real `os` and whose `geteuid` returns `0`; reads `src` with `open(src, encoding="utf-8")` (R-77); `compile`+`exec` into a fresh module; restores `sys.modules["os"]` in a `finally` and then asserts `sys.modules["os"] is os` and `mod.os is shim`. Never mutates `bin/sc`. Called **once** per process (FR-2). |
| I-5 | fixture root | `fixture(sc, name) -> Path` | The **run root** is created once by `main()` with `tempfile.mkdtemp(prefix="sc-contract-")` and removed in a `finally` (K-7); `fixture()` creates the fresh subdirectory `<run root>/<name>`, sets each name in `PATHS` to its leaf under it, then asserts **every** `pathlib.Path`-valued attribute of the module resolves inside the run root — the eight of BC-2 plus `LIB_DIR`, and any future constant, by construction. Also sets `sc.SYSTEMD = sc.OPENRC = False`, `sc.CLASH_PORT = 29090`, `sc.LANG = "en"`, `sc.SB_BIN = <root>/no-sing-box` (a path that does not exist), creates `rules/`, writes an empty `if_inet6` (so the IPv6 decision is host-independent). `main()` calls it once before the first assertion, so BC-2's check runs even when every selected assertion is a pure one; each assertion that needs a directory calls it again, so no assertion depends on another's state. |
| I-6 | path table | `PATHS = (("CFG_DIR", ""), ("CFG_PATH", "config.json"), ("NODES_PATH", "nodes.json"), ("SETTINGS_PATH", "settings.json"), ("RULES_DIR", "rules"), ("OVERRIDE_PATH", "override.json"), ("STATE_PATH", ".config.sha256"), ("IF_INET6_PATH", "if_inet6"), ("LIB_DIR", "lib"))` | One table drives both the repoint and BC-2's assertion; deleting a row leaves that constant under `/etc` and the assertion fails (AC-8). |
| I-7 | host witness | `witness() -> dict` | `os.lstat` (never `stat`) over `/etc/sing-box`, every entry `os.listdir` reports directly inside it, and `/var/lib/sing-box`; each value is `(st_ino, st_mode, st_size, st_mtime)` or `("ERR", errno)`. Read-only, total (an unreadable or absent path is a stable value, not a failure). Taken before the first assertion and after the last; any difference FAILs the run naming each differing path, whatever the assertions said (BC-5). |
| I-8 | summary line | last stdout line, exactly `summary: {d} defined, {r} run, {p} passed` | The three counts are `len(TESTS)`, the number selected and executed, and the number that passed. B.4 reads `{p}` from this line; no other line may match the pattern. |
| I-9 | result line | `PASS  {name}  {evidence}` / `FAIL  {name}  {ExcType}: {message}` | One line per assertion, in `TESTS` order, no timing and no clock-derived text anywhere in the output (AC-21). |
| I-10 | exit status | `0` iff at least one assertion ran, every assertion that ran passed, the witness agreed, and the load and root-refusal gates passed | For the default (unselected) run `run == defined`, which is FR-6's clause exactly. For a name-selected run the code reports **that assertion's** verdict — required by AC-3 and by AC-10's per-assertion sweep — and the `defined`/`run` split in I-8 is what lets B.4 tell a partial run from a full one. |
| I-11 | `verify_all.sh` B.4 | `step "B.4" "bin/sc contract assertions" …` | FAILs when `python3` is absent, when `.harness/scripts/baseline.json` is absent or its `test_count` unreadable, when the suite exits non-zero, when no summary line is found, or when `{p}` < `test_count`. Extraction: `sed -n 's/^summary: [0-9]* defined, [0-9]* run, \([0-9]*\) passed$/\1/p'`. Prints the suite's captured output only in the FAIL detail. |
| I-12 | `verify_all.sh` B.5 | `step "B.5" "restricted-network self-check" …` | Runs `bash .harness/scripts/restricted-network-regression.sh --self-check` with no other argument, ever; exit 0 ⇒ PASS printing nothing, any other exit ⇒ FAIL printing the captured output. No existence guard: a missing script must FAIL, never SKIP. |
| I-13 | `verify_all.ps1` B.1…B.5 | five `Step "<id>" "<the .sh name>" { … return "SKIP" }` | Each id carries the identical check name to its `.sh` counterpart, and each prints its own reason before returning SKIP (B.1/B.2: the checks are `python3`/`bash`-shaped and the mirror does not run them; B.3: no lint config is committed; B.4: Linux-only by subject — POSIX modes and `os.geteuid`; B.5: a Bash scenario script). |
| I-14 | `baseline.json` | `{"version": 1, "created": "2026-07-31", "test_count": <N>, "passing_count": <N>, "warnings_baseline": 0, "notes": "<who reads it, and what the number means>"}` | `test_count == passing_count == len(TESTS)`; `notes` names `.harness/scripts/verify_all.sh` B.4 as the program that reads `test_count` as the assertion floor and states that B.4 FAILs below it. |
| I-15 | `uncoverable()` | `case "$1" in ""\|localhost\|*@*\|*:*\|[0-9]*.[0-9]*.[0-9]*.[0-9]*) return 0 ;; esac` | The `*@*` alternative is added; the preceding comment gains "a userinfo-bearing authority" to its list. Returns "cannot cover" for `u@cdn.example` while the four shipped bases stay covered (AC-18). |
| I-16 | E3 / E4 verdict | `st` computed first; then `if [ "$st" = PASS ] && [ -n "$rblock" ]` ⇒ `BLOCKED`, `else` ⇒ `set_c N "$st" …` | Mirrors E5's shipped shape (`:273`). E3's conjunction absorbs the old `nolog` arm as `[ "$nolog" -eq 0 ]`, so a "log not writable" observation stays FAIL. E6 keeps its `BLOCKED` arms unchanged. |
| I-17 | `userinfo_ends_at_last_at` | `sc._userinfo("a@b@h")`, `sc._userinfo("h")` | FR-7. The userinfo is everything before the **last** `@` (`"a@b"`), and `""` on an authority with none — all three projections empty. |
| I-18 | `userinfo_splits_at_first_raw_colon` | `sc._userinfo("u:p:q@h")`, `sc._userinfo("pw:@h")`, `sc._userinfo("pw@h")` | FR-7. `first`/`rest` split at the **first** colon (`"u"`, `"p:q"`); `pw:` and `pw` give the same `(first, rest)` and different `whole`, so `whole` is not derivable from the pair. |
| I-19 | `userinfo_decodes_exactly_once` | `sc._userinfo("a%3Ab@h")`, `sc._userinfo("a%2540b@h")` | FR-7. `%3A` is not a delimiter (it survives into `first`), and each projection is unquoted exactly once (`%2540` → `%40`, never `@`). |
| I-20 | `write_private_exact_0600_under_hostile_umask` | `sc._write_private(<dir>/c.json, …)` at `os.umask(0o277)`, restored in a `finally`; a bare `tempfile.mkstemp` in the same directory as the control | FR-8. Mode is **exactly** `0600` while the control reads `0400`, which is what makes `os.fchmod` demonstrably load-bearing rather than redundant. |
| I-21 | `write_private_replaces_wider_and_symlinked_target` | pre-existing regular target at `0666`; then a target that is a symlink to another file **inside the run root** | FR-8. Both end as regular files at `0600` carrying the new bytes; the symlink's former destination is unchanged in mode and content — the write went through `replace`, never through the link. |
| I-22 | `write_private_writes_utf8_bytes` | `sc._write_private(p, <text with a non-ASCII character>)`, then `p.read_bytes()` | FR-8. The bytes on disk equal `text.encode("utf-8")` exactly, independently of the process locale, because the codec is named at the writer, not inherited. |
| I-23 | `read_state_refuses_utf16_by_name` | `sc._read_state(p)` over a **valid JSON object encoded UTF-16** | FR-9. Raises `sc.OverrideError` whose sentence is the `not valid UTF-8 text` rendering and whose `.path` is `p`. `json.loads` auto-detects UTF-16 from bytes, so only the explicit `.decode("utf-8")` can produce this refusal (insight index line 16). |
| I-24 | `read_state_shape_and_default_split` | `sc._read_state` over a top-level array; over `{"nodes": {}}` with `member="nodes"`; over an absent path with and without `default={}` | FR-9. One shape sentence per document; absent-with-default returns the default, absent-without-default raises; every failure is one `OverrideError` family carrying `.path`. |
| I-25 | `merge_array_key_demands_a_directive` | `sc._merge(sc._compose([]), {"dns": {"rules": v}})` for `v` in an object, a scalar, `None`, a bare array | FR-10. Each raises `OverrideError` whose sentence names every member of `sc.DIRECTIVES` (compared against `sc._directive_list()`, never a literal), and the branch is taken on the target's array-ness, not on `v`'s type. |
| I-26 | `unusable_fault_clause_is_a_class_name` | `sc.generate_config()` with a nodes fixture and an `override.json` of `{"route": {"rules": {"$append": ["<sentinel>"]}}}` | FR-10, AC-11. `_filter_rules` raises `AttributeError` inside the document envelope; the raised `OverrideError` carries `.path == sc.OVERRIDE_PATH` and a fault clause that is exactly `AttributeError` — one token, no whitespace, no quote — and the sentinel appears nowhere in the sentence. `generate_config()` raises before `_write_private()` and before any `subprocess.run`. |
| I-27 | `redact_masks_secret_keys_at_every_depth` | `sc._redact(doc, False)` over a document placing every name in `sc.SECRET_KEYS` at depths 1, 2 and 3, inside and outside `outbounds` | FR-11. Every such value is `sc.MASK`; every **key** survives; the set is read from `sc.SECRET_KEYS`, never re-spelled. |
| I-28 | `redact_masks_unlisted_keys_inside_outbounds` | `sc._redact(doc, False)` over an `outbounds` array carrying a visible key, an unlisted key, and an unlisted key nested two levels under a visible container; plus two documents differing only in a secret's value and length | FR-11. `strict` turns true on descent into `outbounds` and never back; a visible key renders verbatim; the two redacted documents are byte-identical, so the mask carries nothing derived from what it replaced. |
| I-29 | `dns_overlay_prepend_is_head_of_dns_rules` | for `suppress` in `(True, False)`: `sc._dns_overlay(suppress)`, then `sc._compose([sc._dns_overlay(suppress), sc._telemetry_overlay()])` | FR-12, AC-12. The `$prepend` payload is **non-empty**, its first element equals `sc._aaaa_rule(suppress)`, and it is the head of the composed `dns.rules` — composed against the second `dns.rules` writer, never a bare base (insight index line 26). `_aaaa_rule(True) != _aaaa_rule(False)`, so the pair cannot agree vacuously. |
| I-30 | `zh_placeholders_are_a_subset_of_their_key` | for every table in `sc.TRANSLATIONS` and every `(key, value)`: `string.Formatter().parse` on both | FR-13. Every field name the translation names is a field name its key names; an auto-numbered (`{}`), positional (`{0}`) or unmatched-brace field is itself a violation, reported by key. Offenders are listed one per line so BC-11's count is readable. |

## Constraints

**K-1** — The suite must never execute `bin/sc` or `/usr/local/bin/sc` as a program, never call
`sudo`, and never spawn any child process; `sc.SB_BIN` is repointed to a **non-existent** path
inside the run root so that any future `bin/sc` path reaching `subprocess.run` raises
`FileNotFoundError` inside the run rather than executing anything (BC-16, AC-7).

**K-2** — The suite must call neither `main()` nor `_init_files()`, and no assertion may call
`is_running()`, `clash_api()`, `stored_delays()`, `_egress_ip()`, `_resolve_clash_port()` or
`_free_port()` (FR-3, out-of-scope 7, BC-16).

**K-3** — `main()` must refuse at euid 0 and return non-zero **before** the `load()` call, and
`load()` must refuse again at its own first statement, before it opens the source (BC-1, AC-4).

**K-4** — `load()` must restore `sys.modules["os"]` in a `finally`; the caller must print whether
`sys.modules["os"] is os` on the load-failure path and assert it on the success path (BC-3, AC-9).

**K-5** — One statement must import every stdlib module `bin/sc` imports that the suite does not
itself need (`base64`, `copy`, `hashlib`, `http.client`, `socket`, `subprocess`, `time`,
`urllib.parse`, `urllib.request`), before the shim is installed, so no stdlib module first
imported during `exec` binds the shim as its `os`. Its effect is not observable in this run; it is
one line of data and it closes the one leak the `finally` cannot.

**K-6** — Every assertion that writes must write only under the directory `fixture()` returned;
no assertion may create a symlink whose target lies outside the run root.

**K-7** — The run root is created with `tempfile.mkdtemp` and removed with `shutil.rmtree` in a
`finally`; a removal failure prints the root path and makes the run exit non-zero (BC-4).

**K-8** — No fixture literal following a `password` / `secret` / `token` / `api_key` key may exceed
7 characters between its quotes; every fixture host is a `.invalid` name or a `203.0.113.0/24`
literal; no real credential byte appears anywhere (BC-8, BC-9, AC-22).

**K-9** — The suite must hold Python 3.6 syntax (no f-string `=`, no walrus, no `dataclasses`,
no `unlink(missing_ok=)`, no `capture_output=`) and import nothing outside the standard library
(AC-20).

**K-10** — The suite's output must contain no clock, no random value and no host-derived text
other than the run root's path (AC-21).

**K-11** — Every added line in both `verify_all` mirrors lies inside the
`>>> HARNESS:B-CUSTOM:BEGIN/END <<<` markers; `verify_all.sh`'s B.1, B.2 and B.3 stay
byte-identical; no new step id or name contains the substring `PASS`; a PASSing step prints
nothing (BC-13, BC-14, BC-15, AC-15, Q-16).

**K-12** — A `zh` repair under BC-11 changes the translated string only — never the English key,
never a call site — and must not introduce the `失败：` literal that
`.harness/rejected-decisions.md § ruleset-degradation-note-key` forbids in a non-failure string.

**K-13** — Total added-or-changed lines across C-2 … C-7 must not exceed **60**; the planned
allocation is C-2 18, C-3 12, C-4 3, C-5 6, C-6 12, C-7 8 = 59. C-8 is one glossary entry of 6
lines, declared outside that budget.

**K-14** — The suite file must not exceed **330** lines — the requirement's cap, re-derived
against this design's own element list (303 planned, ~8 % headroom; derivation in
`02_RATIONALE.md`) and therefore confirmed rather than amended. If the implementation exceeds it,
the developer reports the overrun with its own element table; the trim order is header prose
first, then merging two assertions **of the same group**, and never the witness, the `PATHS`
assertion, the `finally` or an assertion's clause.

**K-17** — Assertion granularity is **one assertion per independently mutatable clause**; that
rule, not a target count, is what fixes the number at 14. Adding a fifteenth means a fifteenth
clause with its own mutation, and it moves `baseline.json` in the same commit.

**K-15** — C-6's loader-recipe hunk must add exactly four clauses, each one line: (a) the source
is read with `encoding="utf-8"`, because CPython reads a script as UTF-8 (PEP 263) while a bare
`open()` decodes with the locale codec and dies at `bin/sc`'s first non-ASCII byte under
`LC_ALL=C PYTHONUTF8=0` (**R-77**); (b) a context that skips the recipe does not get a loud
"you imported the installed build" — it gets an **argparse usage error about its own argv at
exit 2**, from the `sudo`-re-exec'd `/usr/local/bin/sc`, which reads like a harness bug
(**R-78**); (c) `main()`'s read-only arm is only `("doctor", "config")`, so **every** other
command drives `_init_files()` and its un-repointable `/var/lib/sing-box` literal (**R-84**);
(d) `.harness/scripts/check-sc-contracts.py` is the recipe's working reference. The prose recipe
stays (Q-15).

**K-16** — C-7 must state the real test command
(`python3 .harness/scripts/check-sc-contracts.py`, wired as B.4) and the wired B.5, must remove
the "no test directory" sentence rather than re-word it around, and must leave B.3's SKIP
sentence intact (out-of-scope 4).

## Frozen set

| path | why frozen |
|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` (everything except a `zh` translation string under BC-11) | Out-of-scope 6. No behaviour change; `_init_files()`'s `/var/lib/sing-box` literal stays as-is (Q-14). |
| `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` B.1/B.2/B.3 and every A.*/E.*/F.* step | AC-15, out-of-scope 10. |
| `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.ps1` A.*/E.*/F.* steps | Out-of-scope 10. |
| `/home/alan/Programs/singbox-cli/.harness/scripts/check-i18n-parity.sh` | Out-of-scope 3; B.2's scope is unchanged. |
| `restricted-network-regression.sh`'s token arm, gates, E1/E2/E5/E6 and the `sed`/`grep` derivation | Only R-56/R-58/R-59 are in scope; R-57 stays open (Q-10). |
| `/home/alan/Programs/singbox-cli/.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md` | Project red lines, out-of-scope 10. |
| `/home/alan/Programs/singbox-cli/.gitignore`, and the absence of any test directory | Out-of-scope 9, Q-13. |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | C-1 | None. The file is inert until something invokes it. | `git rm` the file; nothing else references it yet. |
| 2 | C-9 (conditional) | C-1 exists and assertion 14 reports ≥1 offending `zh` entry, ≤3 of them. | Revert the string; the assertion goes red again and the finding is re-homed as a row (BC-11). |
| 3 | C-4 | `python3 .harness/scripts/check-sc-contracts.py` exits 0 and its summary reports `d == r == p`; `test_count` is set to that number, never guessed. | Restore `test_count: 0` / the old `notes`; B.4 then passes vacuously — which is why C-4 precedes C-2. |
| 4 | C-2 | C-1 and C-4 in place. | Delete the two step blocks; the summary returns to `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`. |
| 5 | C-5 | `bash .harness/scripts/restricted-network-regression.sh --self-check` exits 0 **before** the edit, so the edit's effect is attributable. | Revert the three hunks; B.5 keeps passing either way (the self-check's four bases are covered before and after). |
| 6 | C-3 | C-2 in place, so the two mirrors can be read side by side. | Revert; the `.ps1` returns to three SKIPs and its summary loses two SKIPs. |
| 7 | C-6, C-7, C-8 | Everything above is green; the docs describe what shipped, not what was planned. | Revert the hunks. |

No data migration, no flag, no compatibility window: nothing in this task is read by an installed
`sc`, by a user's host, or by any file the installer copies.

## Out of scope

- No change to `CHANGELOG.md`: nothing user-visible ships unless C-9 fires, and a translation-string
  repair is recorded in the delivery, not in the user-facing changelog.
- No `.ps1` mirror of the suite, and no `.ps1` implementation of B.1/B.2 — both stay honest SKIPs.
- No coverage of the stdout wrapper, of any encoding/locale criterion, or of T-25's output-layer
  contract (out-of-scope 1, Q-8).
- No second process, no mutation machinery, no fixture library, no `conftest`, no CI job.
- No change to `docs/tasks.md`, `.harness/insight-index.md` or `.harness/operator-obligations.md`
  — the PM and stage 7 own those.

## Verification plan

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | `bash .harness/scripts/verify_all.sh` from the repository root | `PASS 19 / WARN 0 / FAIL 0 / SKIP 1`, exit 0 | AC-1 |
| V-2 | `python3 .harness/scripts/check-sc-contracts.py` | exit 0; last line `summary: 14 defined, 14 run, 14 passed` | AC-2 |
| V-3 | `--list`, then one name selected | 14 names listed; the selected run prints one result line and `summary: 14 defined, 1 run, 1 passed` | AC-3 |
| V-4 | Read `main()` and `load()`; drive the refusal by stubbing the euid read in a scratch copy | the refusal branch precedes the `load()` call and precedes `open(src)` | AC-4 |
| V-5 | `witness()`'s five fields re-taken independently outside the suite around a full run | every field identical for `/etc/sing-box`, each entry inside it, `/var/lib/sing-box` | AC-5 |
| V-6 | `systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts sing-box` before/after, outside the suite | identical; `is-active` never invoked | AC-6 |
| V-7 | Enumerate the suite's spawn sites; observe the process tree during a run | zero child processes; no `sudo`, no `/usr/local/bin/sc` | AC-7 |
| V-8 | Delete one `PATHS` row in a scratch copy of the suite and run it | the fixture assertion fails naming the constant; no write outside the run root | AC-8 |
| V-9 | A deliberately broken `--source` copy (syntax error, and a raise at import) | `sys.modules["os"] is os` reported true on both the raising and the clean path | AC-9 |
| V-10 | Per assertion: one mutated `bin/sc` clone driven through `--source` | every one of the 14 fails against at least one mutation; each mutation + failure recorded in `06_TEST_REPORT.md` | AC-10 |
| V-11 | A clone whose `generate_config()` fault clause uses `str(e)` | assertion `unusable_fault_clause_is_a_class_name` FAILs | AC-11 |
| V-12 | A clone whose `_dns_overlay` `$prepend` payload is `[]` | assertion `dns_overlay_prepend_is_head_of_dns_rules` FAILs | AC-12 |
| V-13 | B.4 against a lowered suite (one assertion removed) and against a moved `baseline.json` | FAIL in both cases, with the reason in the detail | AC-13 |
| V-14 | `baseline.json` against the suite's own summary | `test_count == passing_count == 14` | AC-14 |
| V-15 | `git diff` of `verify_all.sh` against the task-start commit | changes confined to the `HARNESS:B-CUSTOM` markers; B.1–B.3 byte-identical | AC-15 |
| V-16 | Read both mirrors side by side | B.1…B.5 name the same check under the same id; every `.ps1` SKIP prints a reason | AC-16 |
| V-17 | `bash .harness/scripts/restricted-network-regression.sh --self-check`, filesystem witnessed around it | exit 0, no write, four bases reported covered | AC-17 |
| V-18 | `--self-check --source <copy carrying `https://u@cdn.example/geo`>` | `SELF-CHECK FAIL: uncoverable base(s): …`, exit 1 | AC-18 |
| V-19 | Drive E3's and E4's verdict expressions over the recorded no-egress state | `FAIL`, not `BLOCKED`; `BLOCKED` survives where the observation is PASS and the pair unproven | AC-19 |
| V-20 | `python3 -m py_compile` the suite; enumerate its imports | clean; every import stdlib; no 3.7+ construct | AC-20 |
| V-21 | Two consecutive full runs, diffed | identical apart from the run root's path | AC-21 |
| V-22 | A.1's regex, exclusions removed, over the committed diff | zero hits | AC-22 |
| V-23 | Read `docs/dev-map.md` and `.harness/rules/50-singbox-cli.md` against the tree | no surviving `<your test command>`, "no test directory" or "not wired into `verify_all`" claim; R-77/R-78/R-84 clauses present | AC-23 |
| V-24 | Time B.4 | under 5 s wall clock | AC-24 |

## Residuals travelling

| id | statement | must reach <stage/doc> |
|---|---|---|
| RS-1 | The 14 assertion names and their mutation candidates (V-10) — one mutation per independently mutatable clause; an assertion no reachable mutation kills is reported **NOT-DISCRIMINATING**, never as passed. | stage 6 / `06_TEST_REPORT.md` |
| RS-2 | I-10's reading of FR-6 (a name-selected run reports its own verdict; `defined` vs `run` carries the partial-run fact) is a design reading of a contract clause that AC-3 and AC-10 pull the other way. Rule it. | stage 3 / `03_GATE_REVIEW.md` |
| RS-3 | Assertion 10's third clause ("no substring of the offending document") is implied by its second on the chosen fixture — no reachable mutation kills it alone. Expected NOT-DISCRIMINATING at clause level, discriminating at assertion level. | stage 6 |
| RS-4 | Assertion 6 (`_write_private` writes UTF-8 bytes) is killed by an `encoding="latin-1"` mutation but **not** by deleting `encoding=` on a UTF-8 host (insight index lines 14/22). Sweep it with the codec-substitution mutation. | stage 6 |
| RS-5 | A static read of `bin/sc:132-392` found **zero** `zh` entries whose placeholder set exceeds their key's, so C-9 is expected to stay empty and assertion 14 is a forward guard. If the delivered run disagrees, BC-11 governs. | stage 4 / `04_DEVELOPMENT.md` |
| RS-6 | K-13's 60-line budget is planned at 59 with a one-line margin. If the doc hunks need more, trim prose in C-6/C-7 — never drop a required clause — and report the final count. | stage 4 |
| RS-7 | The shim becomes the `os` of any stdlib module first imported during `exec` (K-5 closes it for `bin/sc`'s own import list). If `bin/sc` gains an import later, K-5's line must gain it too. | stage 5 / `05_CODE_REVIEW.md` |
| RS-8 | R-57 stays open and unnarrowed; R-7's `install.sh` blind spot stays open (Q-5); R-85 is not this task's. | stage 7 / `docs/tasks.md` |

## Partition assignment

Not applicable — `.harness/agents/` does not exist, so this project runs **single Developer**
mode. Every change-ledger row is partition `single`, in the C-1 → C-9 order given by the
`## Migration & edit sequence` table.

## Verdict

READY
