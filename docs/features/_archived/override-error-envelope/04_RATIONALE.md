# 04 — Rationale · T-24 `override-error-envelope`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

## Method, and its honest limit

Every number in `04_DEVELOPMENT.md` was produced by running something on this host. Nothing was
read off `03_GATE_REVIEW.md` and re-published (C-16). Three things were **not** measured and are
named as such: AC-15 (BLOCKED by construction — root and the live service), the M9 band C-11
assigns to stage 6, and any behaviour of a real `sing-box` binary (`subprocess.run` is stubbed on
every fixture, per C-1 and PQ-8).

The whole measurement runs on **CPython 3.12.3** at `sys.getrecursionlimit() == 1000`. The two
depth fixtures are therefore host-specific by construction and are rebuilt by bisection on every
run rather than pinned to a constant.

## The harness, and why it is shaped this way

`scratchpad/runner.py` — one child process per fixture.

1. It reads `bin/sc` as **text** and asserts the exact auto-elevate block is present:
   `if os.geteuid() != 0:\n    os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])`.
   It replaces that block with `if False:\n    pass`, then asserts `os.execvp("sudo"` no longer
   occurs, and **refuses to run** if the anchor was not found. Without this an import of `bin/sc`
   re-execs the *installed* binary against the live service (BC-12/C-15). A text substitution was
   chosen over `os.geteuid` monkey-patching because the guard runs at module-exec time, before any
   patch could be installed.
2. It `exec`s the patched source into a fresh `types.ModuleType`, then repoints every path
   constant — `CFG_DIR`, `CFG_PATH`, `NODES_PATH`, `SETTINGS_PATH`, `RULES_DIR`, `OVERRIDE_PATH`,
   `STATE_PATH`, `LIB_DIR` — at the fixture root.
3. It replaces `_init_files` with `lambda: None`. This is not optional: `_init_files()` hard-codes
   `Path("/var/lib/sing-box")` as a literal that **no** repointing reaches (insight index
   2026-08-01), and `sc reload` takes the `else` arm of `main()`'s opt-out, so it would run.
4. It stubs `restart_service` to `lambda: True`, sets `SYSTEMD = OPENRC = False`, and replaces the
   module's `subprocess` binding with a shim whose `run()` returns `returncode 0` and appends its
   argv to `$HARNESS_SUBPROC_LOG` when that variable is set. Belt and braces: with both init flags
   false, `restart_service` and `is_running` return without forming a command at all, so even an
   unstubbed `subprocess` could not have reached `systemctl`.
5. It sets `sys.argv = ["sc", "reload"]` and calls `main()`, letting `SystemExit` propagate so the
   process exit status and the rendered line are the **real** ones (F-4/C-1: `generate_config()`
   renders nothing and returns nothing observable — only `main()`'s arm at `:3713-3715` produces
   a line and a status).

The parent captures the child with `stdout=PIPE, stderr=STDOUT` into **one** pipe. That is the
only way "combined stdout+stderr is exactly one line" (BC-3) is a measurement rather than an
assumption, and it is the same shape `install.sh` uses when it redirects into
`/var/log/sing-box/install.log`.

**Fixture (C-1, C-3).** Each fixture root is rebuilt from scratch and holds:

| file | content | why |
|---|---|---|
| `config.json` | `{"SENTINEL": "config.json must survive byte-identical"}\n` | C-3 — (iv) is the survival of *these bytes*, never the absence of a file (F-6) |
| `.config.sha256` | 64 `0` characters + `\n` | C-3 — same, for the drift record |
| `nodes.json` | one `trojan` node, `active` naming it, password `PLACEHOLDER` | needed for `_runtime_overlay`; deliberately not a real credential (BC-4) |
| `settings.json` | `{"lang": …, "clash_api_port": 39999, "default_tun": true, "mode": "rule"}` | C-1 — `clash_api_port` present so `_resolve_clash_port()` honours it and never probes-then-persists (the `CLASH_PORT` twin of the `LANG` trap, insight index 2026-08-14); `lang` present because `main()` **reassigns** `LANG` from `_load_lang()` after import, so setting `sc.LANG` would render English and every Chinese assertion would pass vacuously (BC-13, insight index 2026-08-01) |
| `rules/*.srs` | four files, `b"SRS" + 61 zero bytes` | pass `ruleset_state()`'s magic + `SRS_MIN_BYTES` test so `route.rule_set` is non-empty and no degradation noise enters the stream |

**Controls run against a clone, never a worktree.** `git clone --no-hardlinks` of the repository
into `scratchpad/head-clone`, checked out at `2de1339`. Confirmed by `git log --oneline -1` inside
the clone before any run.

**One fixture path for differential runs.** The first round used one directory per member, which
made AC-5's string-equality clause report **4 distinct sentences** — the sentences differed only
in the fixture path embedded by `main()`'s `Cannot use {path}: {problem}`. Re-run at a single
shared path, the same four fixtures give **1** distinct sentence. This is the same failure mode
R-22's dispatch warns about for `RULES_DIR` in a `generate_config()` differential, arriving
through `OVERRIDE_PATH` instead: two roots yield a difference that reads like a defect and is
purely the harness's.

## Depth fixtures, by bisection (C-11's method, applied at stage 4)

Both thresholds are measured in a **child interpreter** per probe, so the harness's own stack
depth never contaminates the result. The document under test is
`{"zzz": ` + `{"a": ` × d + `1` + `}` × d + `}` — nested under a key `CONFIG_BASE` does not
have, so `_merge` reaches `target[key] = copy.deepcopy(value)` without recursing itself.

```
interpreter: 3.12.3   sys.getrecursionlimit(): 1000
smallest depth at which json.loads raises RecursionError  : 9997
smallest depth at which the parse survives and copy.deepcopy raises RecursionError : 498
direct confirmation:
  497  loads OK | deepcopy OK
  498  loads OK | deepcopy RecursionError
  9996 loads OK | deepcopy RecursionError
  9997 loads RecursionError
```

M0 is built at `9997 + 50`, M1 at `498 + 50`; both are asserted under `OVERRIDE_MAX_BYTES`
(1 MiB) before use. That the two fixtures really hit **different** positions is not asserted, it
is shown by the HEAD control's tracebacks: M0 ends
`RecursionError: maximum recursion depth exceeded while decoding a JSON object from a unicode string`
(27 lines) and M1 ends `RecursionError: maximum recursion depth exceeded` (**2 999** lines — the
`copy.deepcopy` chain, and the literal number BC-3 names).

The gap is a factor of ~20, not the "roughly half" `01`'s reasoning assumes. Nothing in the
delivered code depends on that ratio; it matters only to whoever builds the fixtures, which is why
it is surfaced as an insight.

## AC-2 transcript — M0…M8 on the candidate (C-1, C-3 amendments applied)

Every row: `main()`, `argv=["sc","reload"]`, combined stream, sentinel `config.json` and
`.config.sha256` in place before the run. `exit` is the real process status.

```
M0  lines=1 exit=1 bytes_identical=True
    Cannot use <fixture>/override.json: no configuration could be produced from it (RecursionError)
M1  lines=1 exit=1 bytes_identical=True
    Cannot use <fixture>/override.json: no configuration could be produced from it (RecursionError)
M2  lines=1 exit=1 bytes_identical=True
    Cannot use <fixture>/override.json: no configuration could be produced from it (AttributeError)
M3  lines=1 exit=1 bytes_identical=True
    Cannot use <fixture>/override.json: no configuration could be produced from it (AttributeError)
M4  lines=1 exit=1 bytes_identical=True
    Cannot use <fixture>/override.json: at dns.rules: an existing array must be changed with one of
    $prepend, $append, $replace, $before, $after
M5  lines=1 exit=1 bytes_identical=True     (same sentence)
M6  lines=1 exit=1 bytes_identical=True     (same sentence)
M7  lines=1 exit=1 bytes_identical=True     (same sentence)
M8  lines=1 exit=1 bytes_identical=True
    Cannot use <fixture>/override.json: no configuration could be produced from it (TypeError)
```

Fixture documents, verbatim:

```
M0  {"zzz": {"a": {"a": … 10047 deep … 1 … }}}
M1  {"zzz": {"a": {"a": …   548 deep … 1 … }}}
M2  {"dns": {"rules": {"$append": [5]}}}
M3  {"route": {"rules": {"$append": [5]}}}
M4  {"dns": {"rules": {"foo": 1}}}
M5  {"dns": {"rules": 5}}
M6  {"dns": {"rules": null}}
M7  {"dns": {"rules": {"0": {"outbound": "direct"}}}}
M8  {"route": {"rule_set": {"$append": [{"tag": ["a"]}]}}}
```

M2/M3 use a **directive** rather than a bare array on purpose: under E3 a bare array at an
array-valued key is stopped by the vocabulary sentence before `_filter_rules` is ever reached, so
`{"$append": [5]}` is the only shape that actually inserts a non-object element and exercises the
`AttributeError` FR-2 has to catch. The candidate's fault clause names `AttributeError` — the same
class the HEAD traceback ends on (`'int' object has no attribute 'get'`), which is the evidence
that the envelope is catching that fault and not a different one.

Clause (ii) was checked as: the line contains the override path **and** a fault clause **and** is
not the invoking command's generic outcome line (`"Reload failed"`, which `cmd_reload` emits and
which contains neither a path nor a fault).

## The control, and the one place it did not discriminate

```
same nine fixtures, HEAD clone
M0  lines=27    exit=1  bytes_identical=True   traceback  -> discriminates
M1  lines=2999  exit=1  bytes_identical=True   traceback  -> discriminates
M2  lines=18    exit=1  bytes_identical=True   traceback  -> discriminates
M3  lines=18    exit=1  bytes_identical=True   traceback  -> discriminates
M4  lines=1     exit=1  bytes_identical=True   no traceback -> DOES NOT DISCRIMINATE
M5  lines=1     exit=1  bytes_identical=True   no traceback -> DOES NOT DISCRIMINATE
M6  lines=1     exit=1  bytes_identical=True   no traceback -> DOES NOT DISCRIMINATE
M7  lines=1     exit=1  bytes_identical=True   no traceback -> DOES NOT DISCRIMINATE
M8  lines=15    exit=1  bytes_identical=True   traceback  -> discriminates
```

This is the single most important thing measured at this stage, and it corrects the requirement's
framing. On HEAD, M4–M7 at `dns.rules` do **not** produce a written broken document: the
composed-document assertion at the old `:2081-2085` catches them, because replacing `dns.rules`
with an object, a scalar or `null` makes `_dig(config, "dns.rules")` a non-list. HEAD renders
`Cannot use …/override.json: at dns.rules: this must stay an array`, one line, exit 1, files
untouched — all four AC-2 clauses hold on the **pre-change** build. AC-2's stated control ("a
written broken document (M4–M7)") is therefore wrong at those three keys.

The class is real; it just lives elsewhere. The assertion guards exactly `dns.rules`,
`route.rules` and `route.rule_set`. At any other array-valued key of the composed document there
is no guard, and HEAD writes:

```
M4b {"dns": {"servers": {"foo": 1}}}      cand: 1 line, exit 1, bytes identical
                                          HEAD: 2 lines, exit 0, bytes CHANGED — dns.servers is now dict
M5b {"dns": {"servers": 5}}               HEAD: 2 lines, exit 0, bytes CHANGED — dns.servers is now int
M6b {"dns": {"servers": null}}            HEAD: 2 lines, exit 0, bytes CHANGED — dns.servers is now NoneType
M7b {"dns": {"servers": {"0": {…}}}}      HEAD: 2 lines, exit 0, bytes CHANGED — dns.servers is now dict
```

The four HEAD rows above are the R-22 shape: the pre-change build silently ignores the user's
override, writes a broken `config.json` and baselines its digest as "what sc last wrote". **The
`exit 0` in those rows is an artefact of this harness and must not be read as HEAD's exit code**:
C-1 stubs `subprocess.run` to `returncode 0`, so `sing-box check` never ran here. Stage 6 lifted the
stub and measured HEAD with the real `sing-box` at all three unguarded keys — `lines=6 exit=1`, the
checker's `cannot unmarshal number` FATAL (`06_TEST_REPORT.md` §RES-7, defect QA-1). What survives
un-stubbing is the overwrite of a working `config.json` and the drift record baselined onto the
broken one *before* the check; "reports success" does not, and the CHANGELOG clause that said so was
repaired at round 4. The candidate answers all four with one line, a non-zero exit and untouched
bytes. BC-1 does not pin which array key M4–M7 sit at; both positions were therefore run, and the
`dns.servers` position is the one that carries the discriminating control.

## AC-3 — the adversarial build

Constructed by replacing the envelope's two arms with

```python
    except Exception:
        text = json.dumps(config, indent=2, ensure_ascii=False)
```

i.e. exactly Q-10's "catches everything and generates a `config.json` anyway".

```
M2 adversarial: lines=1 exit=0 bytes_identical=False  -> clause (iv) FAILS, as AC-3 requires
M8 adversarial: lines=1 exit=0 bytes_identical=False  -> clause (iv) FAILS, as AC-3 requires
```

Note what this build *does* satisfy: no traceback, exactly one line. A criteria set stopping at
"no traceback" would have passed it. (iv) is the whole of the gate.

## AC-1 — 24 states, byte-identical, with a non-vacuous control

Matrix: 3 rule-set states (4 of 4 present / 2 of 4 / none) × 8 settings states (`mode` rule /
global / direct, `default_tun` off, `ipv6` on / off, `telemetry` allow, `lang` zh), no override
present, candidate vs HEAD clone at the **same** fixture path.

```
24/24 states byte-identical in the emitted document AND in every stream AND in the exit status
non-vacuity control: log.level "warn" -> "info" in CONFIG_BASE reports DIFFERENT = True
```

The control matters: `RULES_DIR` is emitted verbatim into `route.rule_set[].path`, so a harness
using two `mkdtemp()` roots would report 100 % mismatch and read like a refactor bug. One root,
rebuilt between runs, is what makes "byte-identical" mean anything.

## AC-4 — nine valid overrides, byte-identical

Both README recipes (`$after` anchored on `{"clash_mode": "Direct"}`, and the telemetry
allow-one recipe anchored on `{"server": "hosts_dns"}`), the object-merge example
(`{"log": {"level": "debug"}}`), one directive of each of the five names, and `$replace` with `[]`
(the README's new sentence tells users to empty an array that way, so it had to be run):

```
9/9 recipes emit a byte-identical config.json on candidate and HEAD
non-vacuity control ($append vs no override at all): different = True
```

## AC-5 / AC-6 / C-13 — the vocabulary, at one fixture path

```
distinct sentences over M4/M5/M6/M7: 1
  Cannot use <fixture>/override.json: at dns.rules: an existing array must be changed with
  one of $prepend, $append, $replace, $before, $after
all five directive names present: $prepend True  $append True  $replace True  $before True  $after True

AC-6 bare array over an existing array — string equality candidate == HEAD: True
AC-6 sentence == the M4..M7 sentence: True     (FR-3 subsumes the old rule rather than adding a fourth)

C-13 precedence, candidate vs HEAD, same path:
  {"dns": {"rules": {"$nope": []}}}            equal=True   at dns.rules: unknown directive $nope — use one of …
  {"log": {"$append": []}}                     equal=True   at log: $append can only be applied to an array that already exists
  {"dns": {"rules": {"$append": [], "x": 1}}}  equal=True   at dns.rules: $append cannot be combined with other keys in the same object
```

The third fixture is not in C-13's list and was added: `_directive_of`'s *other* error is the
mixed-keys one, and the ternary hoist is exactly the edit that could have reordered it. Both fire
ahead of the array-position error, at both target types.

## AC-7 — the pinned perturbation (C-4)

`_dns_overlay()` patched to `return {"dns": 5}`, no override present:

```
candidate    1 line, exit 1
  Cannot use <fixture>/config.json: at dns.rules: this must stay an array
  names config.json: True | names override.json: False
HEAD control 1 line, exit 1
  Cannot use <fixture>/override.json: at dns.rules: this must stay an array
  names config.json: False | names override.json: True
```

Both clauses of the amended criterion hold: the path is `config.json`, and the sentence is the
**assertion's own**, not the envelope's — which is RS-1's ruling confirmed by measurement rather
than by reading. K-13's label-gate leaves the `for at in (…)` loop running unconditionally, so no
traceback occurs on the override-less path and the build the original annotation named is killed
by AC-2 on M0–M3 instead.

## Structural criteria

```
AC-8  _filter_rules source segment identical to HEAD: True
      call-site argument lists (ast.unparse) identical: True
        ["_filter_rules(config['dns']['rules'], defined)",
         "_filter_rules(config['route']['rules'], defined)"]
      git diff -w shows both call lines as CONTEXT (unchanged)
AC-9  _apply_directive callees: ['OverrideError', '_anchor_index', 'deepcopy', 'isinstance', 'set', 't']
      _merge edge present: False
AC-10 new t() keys (AST, from the code): {'no configuration could be produced from it ({fault})'}
      zh: '无法据此生成配置（{fault}）'
      placeholders en=['fault'] zh=['fault'] equal=True
      '失败：' in zh: False | unnamespaced: True | emitted through t(), not a bare literal: True  (C-5)
AC-11 README.md 457 lines, README.zh-CN.md 457 lines
      heading / fence / table / blank-line shape identical line for line: True, 0 divergences
```

Frozen-set check — every one of these is byte-identical to the HEAD clone: `_write_private`,
`_record_generated`, `_config_digest`, `_apply_directive`, `_directive_of`, `_anchor_index`,
`_load_override`, `_compose`, `_filter_rules`, `OverrideError`, `_directive_list`, `main`, `_dig`,
`_warn_drift`, `_warn_degraded`, `restart_service`, `reload_or_restart`, `cmd_reload`.

## The hard constraints, each measured rather than assumed

**T-13 / BC-5.** `_write_private` is byte-identical to HEAD and its three call sites are
`NODES_PATH`, `STATE_PATH`, `CFG_PATH` — the only write of `CFG_PATH` in the file is
`_write_private(CFG_PATH, text)`. An emitted fixture `config.json` is mode `0o600`. PQ-5's claim
was verified, not assumed: the hoist binds a string that **already existed in this frame** as the
call's argument expression; no new file, no new buffer, no new path. (`nodes.json` is `0o664` in
the fixture because the harness's own `build_fixture` wrote the seed file and `save_nodes` was
never reached — not a product fact.)

**T-14.** The drift record after a successful run is 64 hex characters and equals
`sha256(config.json bytes)` computed independently by the harness. `_config_digest` and
`_record_generated` are byte-identical to HEAD; the record is a digest, never a copy.

**BC-3.** Exactly one line for all nine members, measured on the *combined* stream of a real child
process. The HEAD control's M1 is the 2 999-line case the requirement names by number.

**BC-4.** The only new sentence carries `type(e).__name__` and nothing else — never `str(e)`,
`repr(e)`, `e.args` or traceback text (K-4). `verify_all` A.1 (No hardcoded secrets) PASS before
and after. No override fixture in this document contains a value that could be a credential; the
node fixture's password is the literal `PLACEHOLDER`.

**BC-6 / K-15.** `main()`'s `except OverrideError` arm and the `OverrideError` class are
byte-identical to HEAD; the arm still renders `e.path or CFG_PATH` and still serves the state
documents. `_unusable()` is now the single construction site: the two state-document paths, the
composed-document assertion, the load's second arm and the region's second arm all go through it.
Its body did not change — only its docstring, which previously said "state document".

**BC-7.** No `_apply_directive → _merge` edge (AST, above). E3 adds no call: it hoists the
existing `_directive_of` call into a ternary and re-orders tests.

**BC-8 / R-44.** `grep -c setrecursionlimit bin/sc` = **0**. No depth, node or size cap was added
anywhere; `OVERRIDE_MAX_BYTES` is untouched. The `dns.servers` measurement above shows why this
matters: the merge's deep copy overflowing far *earlier* than the parse is what keeps R-44's
masking-walk failure unreachable through `override.json`.

**K-7.** `_merge` now holds exactly one un-copied assignment, `target[key] = value`, reachable
only when `value` is neither `dict` nor `list` (the preceding `elif isinstance(value, (dict, list))`
guards it). Full assignment list from the AST: `root = …`, `where = …`, `directive = …`,
`target[key] = _apply_directive(…)`, `target[key] = copy.deepcopy(value)`, `target[key] = value`.

## The drift argument, in full (D-1)

K-11 asks that `git diff -w` over `generate_config()` show only the envelope's own added lines,
the assertion's two-line replacement and the hoist. It shows two more things, and both were
deliberate.

*Width.* The comment lines inside the enclosed region were already 89–91 columns. The house
maximum in this file's code region is 92 (measured: `awk` over `bin/sc` lines 1400–2120 at HEAD,
excluding the data literals at 1776–1795). Adding 4 columns of indent puts them at 93–95. The
choice was: re-flow the comments, or ship five lines wider than anything else in the function.
Re-flowing changes no statement and no line count, so it costs nothing under K-16.

*Truth.* The pre-change comment above the assertion ended: *"It cannot fire when there is no
override — every overlay sc composes leaves all three arrays — which is why this raise, too, names
the user's document."* That final clause is the R-26 reasoning E6 exists to retire. AC-7's
perturbation is a live demonstration that the assertion **can** fire without an override, and the
whole point of the gate is that provenance no longer rests on that argument holding. Shipping a
gated label under a comment justifying an ungated one would be a reviewer's finding at stage 5 and
a reader's trap forever. The replacement keeps the true half and states the new rule, in the same
three lines.

Reported rather than absorbed, as C-8's discipline requires for lines and as rule 7 of the
developer contract requires for behaviour-free deviations.

## What a rework round would need

- If stage 5 rejects D-1, the two comment blocks revert to a pure indent shift and the region's
  five comment lines run to 93–95 columns; the stale final clause then needs a separate, PM-routed
  edit, because leaving it is worse than either alternative.
- If stage 6's C-11 measurement finds the M9 band **empty** on its interpreter, nothing in the
  delivered code changes — the region covers `json.dumps` whether or not a document exists that
  overflows only there. The band's width is a fact about CPython, not about this build.
- If stage 6 wants the C-12 forced-raise fixture, the cheapest shape is to patch `_warn_degraded`
  to `raise ValueError()` through `runner.py`'s existing `sc_src_patch` hook (used here for AC-3
  and AC-7) and assert the line reads `… (ValueError)` while `config.json` stays at the sentinel.
