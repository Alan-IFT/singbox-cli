# 06 — Test Report · T-23 `state-file-io-contract`

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

## Test plan

Fixtures are stage artifacts under the session scratchpad, never the worktree (RT-7; T-28 owns the
committed suite). Every run loads `bin/sc` through the `docs/dev-map.md` recipe (K-13): re-exec
neutralised via an `os.geteuid` shim, source opened with `encoding="utf-8"`, all **eight** path
constants repointed into a `mkdtemp()` root **with one assertion per constant**,
`SYSTEMD = OPENRC = False`, `SB_BIN` stubbed, `_init_files` replaced by a no-op. `HEAD control`
means the same step against a `git clone` of HEAD `cf164f9` — a clone, never a `git worktree`;
`sha256(headclone/bin/sc)` = `sha256(git show HEAD:bin/sc)` = `2584722…`, candidate `012df62…`.

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 non-UTF-8 `settings.json`, `sc ipv6 show` | V-1 candidate + HEAD control | `run.sh` → `log_ac2h.txt`, `fix/ac1` |
| AC-2 same fixture, `sc telemetry show` / `sc status` / saved port | V-2 candidate + HEAD control; `--call _saved_clash_port` | `run.sh`, `fix/ac2`, `fix/ac2b` |
| AC-3 `null` / `42` / `"telemetry"` / `[]` × four accessors | V-3 through `main()` (8 runs) **and** per-accessor direct calls (32 runs) | `log_ac3.txt`, `log_ac3call.txt` |
| AC-4 `settings.json` absent | V-4 `sc ipv6 show`, `sc ls`; plus the zero-byte case (BC-2) | `log_ac45.txt` |
| AC-5 usable `lang:zh, ipv6:off, telemetry:allow, clash_api_port` | V-5 `sc ipv6 show` / `sc telemetry show` / `sc ls`; `--call _saved_clash_port` | `log_ac45.txt`, `fix/ac5*` |
| AC-6 `sc lang zh` on an unusable document, digests | V-6 × 3 causes × 2 builds | `log_ac6.txt` |
| AC-7 R-27 clobber, digest before/after | V-7 `sc ls` on the **valid-UTF-8-but-not-JSON** fixture (C-7), + HEAD control | `fix/ac7` |
| AC-8 4 node fixtures × `sc ls` / `sc now` / **`sc use 1`** (C-1) | V-8, 12 candidate + 12 HEAD runs; `sc status` run alongside, not counted | `log_ac8.txt` |
| AC-9 `sc doctor` on those four fixtures | V-9 with `sc.clash_api` stubbed + `clash_api_port` recorded (C-6), 8 runs; plus an E-16-reverted control | `log_ac9.txt`, `noE16/sc` |
| AC-10 usable two-node store | V-10 `sc ls`, `sc now` | `fix/ac10`, `fix/smoke` |
| AC-11 `sc add 'trojan://p%C3%A9q@…'` under proved non-UTF-8 | V-11 candidate + HEAD, env proof first | `locale_run.sh`, `fix/ac11_*` |
| AC-12 CJK-tagged store + ASCII add under proved non-UTF-8 | V-12 candidate + HEAD, byte comparison | `locale_run.sh`, `check_ac12.py` |
| AC-13 differential byte-identity | V-13 both checkouts, C-5 fixture, each build's own `_init_files()` seed (RES-1) | `ac13.sh` |
| AC-14 modes after each write | V-14 `stat` after V-11, V-12, V-13 and a UTF-8 run | `ac13.sh`, `fix/ac1*` |
| AC-15 `_write_private()` | V-15 read the shipped function | `bin/sc:501-524` |
| AC-16 drift digest over bytes | V-16 read the shipped function | `bin/sc:1943-1953` |
| AC-17 translation table | V-17 machine-count added table-shaped diff lines; `verify_all` A.1 | `git diff bin/sc` |
| AC-18 decide-site count | V-18 enumerate every `except OverrideError` / `isinstance` in the shipped file | `grep` over `bin/sc` |
| AC-19 diff budget | V-19 `git diff --numstat bin/sc`, `git status` | worktree |
| AC-20 `verify_all` | V-20 from the repository root | `.harness/scripts/verify_all.sh` |
| AC-21 live host, root | V-21 — **BLOCKED for every agent**; filed as operator obligation **id 4** | `.harness/operator-obligations.md` |
| FR-5 / BC-12 once-ness | V-23 `_read_state` wrapped, warning lines counted | `count_reads.py` |
| FR-12 one writer | V-22 enumerate writers of `SETTINGS_PATH` | `grep` over `bin/sc` |

### Per-criterion result

| id | verdict | evidence |
|---|---|---|
| AC-1 | **PASS** | cand exit 0, `IPv6 name resolution → auto`, exactly one `⚠️ … not valid UTF-8 text`, no `Traceback`, file IDENTICAL. HEAD: exit 1, `UnicodeDecodeError` at `headclone/bin/sc:390`. |
| AC-2 | **PASS** | `sc telemetry show` → `block` + name list, same single line; `--call _saved_clash_port -> None` (the port is unrecorded). HEAD tracebacks on both commands. Observed through the accessor, not `sc status` (F-16). |
| AC-3 | **PASS** | All four fixtures: cand exit 0, one warning `the top level must be a JSON object`, all four accessors at `en` / `None` / `auto` / `block`, no traceback. Through-`main()` HEAD control = one `AttributeError` from `_load_lang()` on all four (C-2). Per-accessor controls reported by direct call only. |
| AC-4 | **PASS** | `settings.json` absent → **zero** stderr lines naming it, accessors at defaults, exit 0. BC-2's zero-byte file gives `not valid JSON (Expecting value: …)` and still degrades. |
| AC-5 | **PASS** | Chinese output (`IPv6 域名解析 → off`, `遥测域名拦截 → allow`, Chinese `sc ls` header), `--call _saved_clash_port -> 29099`, `settings.json` IDENTICAL (so the recorded port was used, not re-probed), **no** warning line. |
| AC-6 | **PASS** | 3 causes × cand: exit 1, digest IDENTICAL, and the **last** stderr line is the abort sentence without the `⚠️` prefix (C-13). HEAD on the non-JSON fixture exits **0** and destroys the file. |
| AC-7 | **PASS** | C-7 fixture (`this is not json but it is utf-8`): cand `9e795e15… -> 9e795e15… IDENTICAL`; HEAD `-> 1c559f7c… CHANGED`, replaced by `{ "clash_api_port": 29091 }`. |
| AC-8 | **PASS** | 12/12 cand: exit 1, one sentence naming `nodes.json` with the matching cause, **0 tracebacks**, file byte-identical. HEAD: **11 tracebacks + 1 silently wrong answer** (`sc now` on `{}` → exit 0, `(none)`). `sc status` exits 0 on both builds and is not counted (C-1). |
| AC-9 | **NOT DISCRIMINATING** (C-6) | With the stub and a recorded port, all 8 runs (4 fixtures × 2 builds) print **20 rows**, last row present, exit 1, no `Traceback`; the node-delay row names the file on both builds. Reported as not discriminating, never as a pass. E-16 verified instead by a within-candidate control (below). |
| AC-10 | **PASS** | `sc ls` prints both node rows, exit 0; `sc now` prints `alpha`, exit 0. |
| AC-11 | **PASS (disk clause)** · exit clause **BLOCKED-BY-T-25** | Environment proved non-UTF-8 in-process first. Password on disk decodes as UTF-8 to exactly `péq`, no `\uXXXX`, 3 nodes (none lost), mode `0600`, no "could not write" line, no encode/decode error in the state path. HEAD: `UnicodeEncodeError` in `_write_private`, node unwritten. Exit clause blocked on `bin/sc:2345` (RES-5). |
| AC-12 | **PASS (disk clause)** · exit clause **BLOCKED-BY-T-25** | Pre-existing `香港节点` bytes identical before/after (2 occurrences each), both nodes present, no `\uXXXX`. HEAD: `UnicodeDecodeError` on the read, file unchanged. Exit clause blocked on the same ground — V-12's URL is **all-ASCII** and still exits 1 at `:2345`. |
| AC-13 | **PASS** (RES-1 discharged) | `settings.json`, `nodes.json`, `config.json` **and** the drift record byte-identical between a real HEAD checkout and the candidate on the C-5 fixture, with each build running its **own** `_init_files()` seed. Repeated 3×. |
| AC-14 | **PASS** | After V-11/V-12/V-13 runs: `config.json` `600`, `nodes.json` `600`, `.config.sha256` `600`, `settings.json` `664` — and HEAD gives `settings.json` the same `664` under the same `umask 0002`. |
| AC-15 | **PASS** [S] | `bin/sc:501-524`: `mkstemp(dir=…)` → `os.fchmod(fd, CRED_MODE)` on the still-empty descriptor → `fdopen(fd, "w", encoding="utf-8")`, `fd = -1` → write/flush/`fsync` → `close` → `os.replace`, `finally` closing a live fd and unlinking a surviving temp. Only the `encoding=` keyword and one comment differ. |
| AC-16 | **PASS** [S] | `_config_digest()` still feeds `hashlib.sha256()` from `CFG_PATH.open("rb")` in 64 KiB chunks; no decode anywhere in the drift quartet. |
| AC-17 | **PASS** [S] | Machine count over `git diff bin/sc`: **1** added translation-table line, **0** removed. `"the \"{member}\" member must be a JSON array": "\"{member}\" 成员必须是 JSON 数组"` — same single `{member}` placeholder in both, no `失败`. `verify_all` A.1 PASS. |
| AC-18 | **PASS** [S] | Independent enumeration: `except OverrideError` at `:436` (write-refusal, permitted), `:595` (degrade), `:2038` / `:2072` (pre-existing override-provenance wrappers, not state reads), `:3700` (abort); `except (OverrideError, TypeError, KeyError)` at `:2791` (doctor's row). **Three decide-sites plus one permitted arm.** The only `isinstance` calls near a state read are `:558`, `:565`, `:567`, all inside `_read_state` itself. |
| AC-19 | **PASS** [S] | `git diff --numstat bin/sc` = `76 51`; against C-8's amended cap (≤76 added, ≤48 code) added is exactly at it. `git status` shows only `bin/sc`, `CHANGELOG.md`, `CONTEXT.md`, `docs/dev-map.md`, this task's untracked document directory, and the PM-owned `docs/batches/**`. No new module, no new package. |
| AC-20 | **PASS** | `bash .harness/scripts/verify_all.sh` from the repository root: `PASS: 17  WARN: 0  FAIL: 0  SKIP: 1`. |
| AC-21 | **BLOCKED** (C-15) | Needs root and the installed `/usr/local/bin/sc` against the live service. Filed verbatim with V-21's recipe as **operator obligation id 4**. **Nothing was substituted** — the seventh consecutive un-substituted obligation (R-31 / R-41 / R-47 / R-52 / R-60, and obligation 3). |

**Tally — PASS 18 · NOT DISCRIMINATING 1 (AC-9) · BLOCKED 1 (AC-21) · FAIL 0**, plus AC-11's and
AC-12's process-exit clauses recorded **BLOCKED-BY-T-25**, neither passed nor failed nor dropped.

### Gate conditions addressed to stage 6

| id | how discharged |
|---|---|
| C-1 | Twelve runs are `sc ls` / `sc now` / **`sc use 1`** × the four `nodes.json` fixtures. `sc status` was run alongside on the `{}` fixture and exits 0 on **both** builds — it reads no node store under `SYSTEMD = OPENRC = False`. Not counted. |
| C-2 | The discriminator reported is FR-5's single warning line plus the absence of a traceback, never the value `auto`. Through-`main()` HEAD control reported as one `AttributeError` from `_load_lang()` for all four. Per-accessor controls reported **as direct calls on the imported module**, and reported as measured rather than as predicted (see the `[]` refinement in `## Defects found` DEF-4). |
| C-5 | Differential fixture files listed and asserted below. |
| C-6 | `sc.clash_api` stubbed to return a `dict`, `clash_api_port: 29099` recorded, so `_doctor_clash()` reaches E-16's guard. It does **not** discriminate against HEAD → reported as **not discriminating**, never a pass. Stage 4's within-candidate control reproduced. |
| C-7 | The R-27 clobber control ran on the **valid-UTF-8-but-not-JSON** `settings.json` fixture, whose exact content is `this is not json but it is utf-8`. The non-UTF-8 and non-object fixtures were not used as R-27 controls. |
| C-13 | AC-6 is reported as the **abort sentence on the exit path** (exit 1 + the last stderr line, without the `⚠️` prefix), never as an occurrence count. The string does appear twice, as C-13 states. |
| C-15 | AC-21 BLOCKED, operator obligation id 4, nothing substituted. |

**C-5 differential fixture, file by file** — `fix/ac13_head/etc/sing-box/` and
`fix/ac13_cand/etc/sing-box/`, both grown from an empty directory by each build's own code:

| file | content | every key is enum / boolean / ASCII? |
|---|---|---|
| `settings.json` | `{"default_tun": true, "mode": "rule", "lang": "en", "clash_api_port": 29091}` | `default_tun` boolean · `mode` validated enum · `lang` validated enum · `clash_api_port` int. **Yes.** No `update_interval`, no hand-edited value, no non-ASCII byte. |
| `nodes.json` | one node from `trojan://asciipw@ascii.example:8443` → `tag ascii.example:8443`, `type trojan`, `server ascii.example`, `server_port 8443`, `password asciipw` (invented) | every value pure ASCII, all sc-authored by the share-URL parser. **Yes.** |
| `config.json` | generated from the two above | derived only from the above plus `CONFIG_BASE`. **Yes.** |
| `.config.sha256` | sha256 hex of `config.json`'s bytes | ASCII hex. **Yes.** |

## Adversarial tests

One row per acceptance criterion, each with a hypothesis written before the run and an independent
reproducer built from the criterion text — not from `04_DEVELOPMENT.md`'s test code. Full runs in
`06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | the run writes *more* than one settings warning, because three accessors read the file | `run.sh cand ac1 badutf8 ok -- ipv6 show` (NEW) | Survived — `EXIT=0` / `IPv6 name resolution → auto` / one line: `⚠️  Cannot use …/settings.json: not valid UTF-8 text`. Wrapping `_read_state` shows **4 reads, 1 line**. |
| AC-2 | `sc status` prints a *fabricated* saved port instead of treating it as unrecorded | `run.sh cand ac2 badutf8 ok -- status`; `--call _saved_clash_port` (NEW) | Survived — `CALL _saved_clash_port -> None`; `sc status` prints no port row at all under the fixture (F-16), so nothing is fabricated. |
| AC-3 | the `"telemetry"` fixture yields `auto` by substring accident on the **candidate** too | `--call _ipv6_setting` on both builds (NEW) | Survived — HEAD `CALL _ipv6_setting -> 'auto'` (accident); candidate reaches `auto` only after `_read_state` rejects the string: `Cannot use …: the top level must be a JSON object`. |
| AC-4 | a run with no `settings.json` still emits the warning line via some second reader | `run.sh cand ac4 absent ok -- ipv6 show` (NEW) | Survived — `--- STDERR` block is empty; `settings.json ABSENT -> …` created only by `_resolve_clash_port`'s legitimate persist on an *absent* document. |
| AC-5 | the build always answers *unusable*, so AC-1..AC-3 pass while nothing works | `wrongbuild/sc` = candidate + one `raise _unusable(...)` at the top of `_read_state`; AC-5 fixture (NEW) | **Killed the wrong build** — `sc ipv6 show` gives `IPv6 name resolution → auto` + a ⚠️ line where AC-5 demands `off` and silence. AC-1/AC-2's observables pass on it. Control is real. |
| AC-6 | the abort still rewrites the file, or exits 0 | `run.sh cand ac6_notjson notjson ok -- lang zh` (NEW) | Survived — `EXIT=1`, `settings.json … IDENTICAL`. HEAD: `EXIT=0`, `语言 → zh`, file replaced by `{ "clash_api_port": 29091, "lang": "zh" }` — **HEAD loses the user's file silently**. |
| AC-7 | the clobber control does not reproduce, making AC-7 vacuous | `run.sh head ac7 notjson ok -- ls` (NEW, C-7 fixture) | Survived — HEAD `settings.json 9e795e15… -> 1c559f7c… CHANGED`, candidate `IDENTICAL`. Control reproduces on exactly the fixture C-7 names. |
| AC-8 | HEAD tracebacks all twelve, so the report's control claim is false | machine count over `log_ac8.txt` (NEW) | Survived, claim corrected — `candidate blocks with Traceback: 0   HEAD blocks with Traceback: 11   total blocks: 24`; the twelfth is `sc now` on `{}` at HEAD: `EXIT=0` / `(none)`. |
| AC-9 | doctor's "complete table, no traceback" is true on **any** build, so AC-9 proves nothing | `noE16/sc` = candidate with E-16 alone reverted (NEW) | **AC-9 does not discriminate vs HEAD** (both 20 rows). E-16's own control does: `EXIT=1`, rows `20 → 17`, `[UNKNOWN] Clash API: this check could not run: not valid UTF-8 text`. |
| AC-10 | an always-unusable build still passes AC-10 | `wrongbuild/sc` + `sc ls` / `sc now` (NEW) | **Killed it** — `[wrong build] sc ls -> exit=1`, `sc now -> exit=1`, no rows, no tag. Candidate: both rows + `alpha`, exit 0. |
| AC-11 | the harness is secretly UTF-8, so the assertion is vacuous (the round-1 defect) | `locale_run.sh` with `--require-non-utf8` (NEW) | Survived — proof written in-process first: `{"stdout_encoding": "ascii", "preferred": "ANSI_X3.4-1968", "utf8_mode": 0, "is_non_utf8": true}`. Dropping `PYTHONUTF8=0` gives `stdout=utf-8 … utf8_mode=1`, which the runner refuses. |
| AC-12 | the rewrite re-escapes the CJK tag as `\uXXXX`, or drops the node | `check_ac12.py` byte comparison (NEW) | Survived — `post contains backslash-u: False`, `node count: 2 tags: ['香港节点', 'ascii.example:8443']`, `first tag field bytes` identical to `pre`. |
| AC-13 | correct code *fails* this on a legitimate input, so the restriction hides a real divergence | `adv2.sh` A-15: `update_interval: "每天"` then `sc lang zh` on both builds (NEW) | **Divergence confirmed and deliberate** — HEAD writes `"update_interval": "\u6bcf\u5929"`, candidate writes `"update_interval": "每天"`. C-5's exclusion is load-bearing, not cosmetic; AC-13 passes on the permitted set. |
| AC-14 | the new codec argument widens a mode at some instant | `stat` after every write in V-11..V-13, both builds (NEW) | Survived — `600 config.json`, `600 nodes.json`, `600 .config.sha256`, `664 settings.json` on **both** builds under `umask 0002`. |
| AC-15 | the `encoding=` argument moved `fchmod` after the first write | read `bin/sc:501-524` | Survived — order is `mkstemp(dir=…)` → `os.fchmod(fd, CRED_MODE)` → `os.fdopen(fd, "w", encoding="utf-8")` → write/flush/fsync → `os.replace`, `finally` intact. |
| AC-16 | some decode crept into the drift path, making the verdict locale-dependent | `grep -n "read_text()\|read_bytes()" bin/sc` | Survived — the only `read_text()` calls are `:1646` (if_inet6), `:1994` (ASCII digest record), `:2659` / `:3065` (the frozen `config.json` readers, K-10). `_config_digest` uses `CFG_PATH.open("rb")`. |
| AC-17 | a second key slipped in, or the zh entry is missing | machine count of table-shaped `+`/`-` diff lines (NEW) | Survived — `added translation-table-shaped lines: 1`, `removed: 0`, and the one line carries both halves. |
| AC-18 | a per-call-site guard was added somewhere among the 16 | `grep -n "except OverrideError" bin/sc`, `grep -n "isinstance(" bin/sc` | Survived — 5 `except OverrideError` + 1 tuple form, all accounted for; no `isinstance` around any state read outside `_read_state`. |
| AC-19 | the diff grew past C-8's cap or added a file | `git diff --numstat bin/sc`; `git status --porcelain` | Survived — `76	51	bin/sc`; tracked changes are exactly `bin/sc`, `CHANGELOG.md`, `CONTEXT.md`, `docs/dev-map.md` (+ PM-owned `docs/batches/**`). |
| AC-20 | a task document trips F.6's 500-line cap or E.6's heading grep | `bash .harness/scripts/verify_all.sh` from the root | Survived — `PASS: 17  WARN: 0  FAIL: 0  SKIP: 1`; `[E.6] Adversarial tests section … PASS`, `[F.6] Active task docs <=500 lines each ... PASS`. |
| AC-21 | some fixture could stand in for the live host | none attempted | **BLOCKED** — needs root and the installed binary. Filed as operator obligation id 4 with V-21's recipe. Nothing substituted. |

### Attacks on the build itself, beyond the criteria

| attack | reproducer | outcome |
|---|---|---|
| **Make it swallow a file silently.** `settings.json` as a directory, and at mode `000`. | `adv.sh` A-1 / A-2 (NEW) | Named and loud both times: `cannot be read (Is a directory)`, `cannot be read (Permission denied)`, then the documented default. All four `_read_state` causes are reachable. |
| **Mislabel a document.** Break `override.json` and `nodes.json` in the same run, through `generate_config()`, both orders. | `adv2.sh` A-11 / A-12 (NEW) | No mislabelling: broken override → `Cannot use …/override.json: not valid JSON`; broken node store → `Cannot use …/nodes.json: not valid JSON`. `e.path` holds (RT-1). |
| **Clobber a file it should not.** Every FR-6 command on an unusable `settings.json`. | `sc mode` / `ipv6` / `telemetry` / `default-tun` / `lang` / `on` / `off` (NEW) | 7/7 `exit=1`, 0 tracebacks, `settings=SAME` on all seven. (`sc update-interval` is unreachable under K-13 — DEF-1.) |
| **Lose a node.** `sc add` with a read-only `/etc/sing-box`; and with a raw non-ASCII byte in `argv` under the proved non-UTF-8 locale (BC-10 / Q-9). | `adv2.sh` A-8b, `adv.sh` A-9 (NEW) | Both give one sentence and exit 1 with the store byte-identical and **no temporary left**: `Could not write …/nodes.json: Permission denied` and `Could not write …/nodes.json: 'utf-8' codec can't encode characters in position 491-492: surrogates not allowed`. K-5's `getattr` is what keeps the second one from failing inside its own handler; HEAD gives a raw `UnicodeEncodeError` traceback there. |
| **Read a torn document.** 10 reader threads × 200 reads through `_read_state` while `save_nodes()` rewrites the file continuously. | `conc.py` (NEW) | `reads ok: 2000 unusable: 0 torn (partial JSON): 0 other exceptions: 0`; `distinct node counts observed: … min 0 max 40` proves the writer really raced. BC-8 holds. |
| **Smuggle a non-UTF-8 document past the reader.** A UTF-16 `nodes.json` — `json.loads` accepts `bytes` and would auto-detect it. | `adv5.sh` B-2 (NEW) | Rejected by name: `Cannot use …/nodes.json: not valid UTF-8 text`, exit 1. The explicit `.decode("utf-8")` is what closes it (RT-8b). |

## Boundary tests added

- `settings.json` absent, zero bytes, a directory, mode `000`, `null`, `42`, `"telemetry"`, `[]`,
  a UTF-8 BOM, truncated JSON, and a valid document with an unrecognised value (BC-4).
- `nodes.json` absent, invalid UTF-8, UTF-16, non-JSON, a JSON array, `{}` with no `nodes`, `nodes`
  as an object, `nodes` as an empty array (BC-7), and an element that is not an object (BC-9).
- Unicode: a `香港节点` tag surviving read → modify → write, and a `péq` password surviving a write,
  both under a **proved** non-UTF-8 process; plus `sc rm` leaving the CJK tag intact and active.
- Concurrency: 2000 reads against a continuously rewriting writer (BC-8).
- Size: a 3.2 MB `nodes.json` holding 20 000 nodes — no cap (Q-11), `sc now` answers in `0.06 s`.
- Write failure: read-only target directory, and an argument carrying lone surrogates (BC-10/BC-11).
- Locale: the three-variable matrix, including the negative control that the round-1 recipe
  (`LC_ALL=C PYTHONCOERCECLOCALE=0`) yields a fully **UTF-8** process and therefore verifies nothing.

## verify_all result

```
invocation: bash .harness/scripts/verify_all.sh   (from the repository root)
PASS: 17   WARN: 0   FAIL: 0   SKIP: 1
```

- Total tests: `baseline.json` `test_count: 0` → `0` (no committed test added; T-28 owns the suite)
- Pass: 17
- Fail: 0
- Warn: 0
- Skip: 1 (`[B.3] Lint`)
- New tests added: 0 committed; **≈150 stage-artifact runs** under the session scratchpad (RT-7)
- Baseline updated: **no** — `test_count` stays 0 by T-28's ownership; nothing was lowered and no
  test was deleted. A.1 (no hardcoded secrets) stays PASS with this task's documents in place.

## Defects found

- **[MINOR] DEF-1 — FR-6 names `sc update-interval`, but that command is unreachable under K-13's
  mandated fixture.** `cmd_update_interval` is `if SYSTEMD: … elif OPENRC: …`; with
  `SYSTEMD = OPENRC = False` it takes neither arm, reaches no `load_settings()`, and exits **0** on an
  unusable `settings.json`. Same shape as C-1's `sc status`, which the gate caught and this one it did
  not. Reproducer: `run.sh cand fr6 notjson ok -- update-interval 12h` → `exit=0`, `settings=SAME`.
  Not substituted: reaching the systemd arm needs `SYSTEMD = True` and its first act is
  `Path("/etc/systemd/system/sing-box-rules-update.timer.d").mkdir(...)` + `systemctl daemon-reload` +
  `systemctl restart` on the live host, which NFR-7 forbids. **Not a product defect**: the two
  `load_settings()` calls at `bin/sc:3402` / `:3441` are unguarded and inside `main()`'s try, the same
  mechanism verified by run for the other seven FR-6 commands. This is a criteria gap; route to PM.
  `bin/sc:3402`.
- **[MINOR] DEF-2 — RES-4 / CR-5 confirmed by measurement, not just by reading.** With
  `settings.json` unusable, `sc reload` exits 0 and regenerates `config.json` from the degraded
  defaults: it **adds** an NXDOMAIN block for 17 telemetry domains that the user's stored
  `telemetry: allow` had turned off, flips `external_controller` from the user's recorded
  `127.0.0.1:29099` to a freshly probed `127.0.0.1:29091` (BC-15), and records that digest as the new
  drift baseline. The only output is the one `⚠️ Cannot use …settings.json` line, which names neither
  consequence. Authorised by FR-4 / Q-2 / BC-15 and already travelling as RES-4; this run is the
  evidence the pool row should carry. Reproducer: `adv4.sh` A-17b. `bin/sc:1615`, `bin/sc:1818`.
- **[MINOR] DEF-3 — RT-4 confirmed reachable, and unchanged from HEAD.** `save_settings()` is
  unguarded, so seeding `settings.json` on a read-only `/etc/sing-box` is a raw
  `PermissionError: [Errno 13] … settings.json` traceback. Reproducer: `adv3.sh` A-18. **HEAD does the
  same** (`adv4.sh` A-18b, identical traceback), so C-11's "unchanged from HEAD" holds and this is
  pool material, not a regression. `bin/sc:604`.
- **[MINOR] DEF-4 — C-2's per-accessor control is stated more narrowly than it measures.** C-2
  predicts a fixed `TypeError ×2 / AttributeError ×2 / silent auto`. Measured, the shape varies by
  fixture: for `[]`, HEAD's `_ipv6_setting()` **and** `_telemetry_setting()` both return the correct
  default *silently* (`"ipv6" not in []` is `True`), so that fixture has **two** silent accidents, not
  one, and none of the four values discriminates there. The reported discriminator is unaffected —
  FR-5's line plus the absence of a traceback — but a report reciting C-2's fixed shape would be
  wrong. Reproducer: `log_ac3call.txt`. `bin/sc:1615`, `bin/sc:1818` (HEAD `:1571`, `:1790`).
- **[BLOCKED] AC-21 / C-15** — needs root and the installed binary. Operator obligation **id 4**,
  V-21's recipe verbatim. Nothing substituted.
- **[BLOCKED-BY-T-25] AC-11 / AC-12 process-exit clause (RES-5)** — `bin/sc:2345` prints an
  sc-authored `U+2192` to a strict stdout, so `sc add` exits non-zero **after** writing correct bytes,
  and does so for an all-ASCII share URL too. Never a pass, never a fail, never dropped.

No BLOCKER and no CRITICAL. No product change is requested by this stage.

## Stability

- The four discriminating steps were repeated: V-1 ×10, V-8's `{}` × `sc use 1` ×10, V-11 ×10 under
  the proved non-UTF-8 environment, and V-13's differential ×3 — **33 runs, zero disagreement**.
  Every V-11 run reported `proof=True`, `password == 'péq'`, 3 nodes, no `\uXXXX`; every V-13 round
  reported all four documents `BYTE-IDENTICAL`.
- No flakes observed; no test is quarantined; no test was deleted or skipped.
- Service witness, `systemctl show -p MainPID -p ActiveEnterTimestamp` (never `is-active`):
  before `MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`; after, identical.
  `/etc/sing-box` mtime `2026-08-11 12:13:57`, `/var/lib/sing-box` mtime `2026-07-30 12:59:24` —
  both predate this session. `/usr/local/bin/sc` was never invoked and `bin/sc` was never modified.

## Verdict

APPROVED FOR DELIVERY
