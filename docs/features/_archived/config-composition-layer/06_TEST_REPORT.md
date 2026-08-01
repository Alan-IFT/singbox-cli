# 06 — Test Report · T-14 `config-composition-layer`

Mode: **full** · Stage 6 · Decision authority: **deferred-human, defer-do-not-ask**. Upstream:
`01` READY (30 AC / 26 BC / 7 NFR), `02` READY, `03` APPROVED with 8 conditions, `04` delivered,
`05` APPROVED (0 CRITICAL, 0 MAJOR, 2 MINOR, 3 NIT).

Per project precedent (T-05, T-10, T-11, T-13) this stage **rebuilt** the harness rather than
re-running the developer's. Every oracle below is derived from `01`'s acceptance criteria and from
the pre-change source; **no assertion is inherited from `04`**. `04` §14 was read only to reproduce
the *fixture setup*, and the `docs/dev-map.md` neutralisation recipe was copied verbatim because
the rules forbid inventing another.

---

## 1. Verdict

**CHANGES REQUIRED — 1 MAJOR, 2 MINOR.**

The hard gate holds. AC-1 was reproduced independently and non-vacuously: **164 differential runs
(82 points × 2 languages, 860 individual comparisons) are byte-identical** to a pristine clone at
`f642ca7`, and the harness was first **proven to fail on six mutants**, including a pure key reorder
that changes no value. `verify_all` ends with **0 FAIL**. All 30 acceptance criteria pass.

The MAJOR is not an AC violation — it is a boundary no upstream stage enumerated, in code this task
introduced, whose failure mode is *exactly the one the task exists to remove*: a **dangling symlink**
at `override.json` is silently treated as **absent**, so the user's entire override is discarded
without a word and `sc reload` reports success. `02` §5.4 / D-14 explicitly endorse the symlink
workflow that produces it, and the project's own `ruleset_state()` (`bin/sc:723`) already decides the
identical question the other way for the other user-facing file — *"A dangling symlink does not
exist, but it is broken rather than absent."* Two functions in one file now hold opposite opinions
about the same shape.

Nothing about the fix can disturb the byte-identity gate (with no override there is no symlink), so
this is a small, contained change, not a rework.

---

## 2. Safety — what was done and what was never done

| Rail | Evidence |
|---|---|
| `assert os.geteuid() != 0` kept, never weakened | `qa_common.py:21`; uid 1000 throughout. It is what makes the mode-`000` `unreadable` fixture really produce `unreadable` — verified: `x-all-unreadable` / `x-one-unreadable` points exist and degrade. |
| All **seven** repointed constants asserted inside the temp root | `qa_common.repoint()` asserts containment in the harness `mkdtemp()` root **and** `not startswith("/etc")` for each of `CFG_DIR CFG_PATH NODES_PATH SETTINGS_PATH RULES_DIR OVERRIDE_PATH STATE_PATH`, on **every** repoint (≈1 400 times this session). |
| Neutralisation recipe copied verbatim | `qa_common.load_module()` — the `os` shim whose `geteuid` returns 0, restored in a `finally`. Plus a post-load assertion that `CFG_DIR` is still `/etc/sing-box`, i.e. the module really did not re-exec. |
| `/usr/local/bin/sc` never invoked | Not referenced by any harness file. The oracle is a **pristine clone**, not a worktree: `ls -ld .git` → `drwxrwxr-x … .git` (a directory), so `verify_all` A.1/A.2 are real PASSes. |
| `_init_files()` never driven | Stubbed to a no-op for every `main()`-driven test (`qa_semantics.drive_main`). Its hard-coded `/var/lib/sing-box` `Path` literal was never reached. |
| Nothing written under `/etc` | `/etc/sing-box/` before and after: `config.json` mtime `Aug 1 10:06` (unchanged, predates this task), **no `override.json`, no `.config.sha256`**, no new file of any kind. Verified again after the last run. |
| `sing-box` never stopped/started/reloaded/restarted | `SYSTEMD = OPENRC = False` on every module; `restart_service` additionally replaced by a counting spy in every `main()` drive and asserted `== 0`. `install.sh` never executed. |
| The real binary was used **read-only** | `sing-box check -c <temp file>` only — the same call `generate_config()` itself makes. `cache_file.path` was rewritten into the temp root first, so no `/var/lib` write could even be attempted. |

### Service witness — `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`

Never `is-active`. Baseline to match: `MainPID=2887037`, `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST`.

| # | Checkpoint | Reading |
|---|---|---|
| 1 | before any harness was written | `MainPID=2887037` / `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST` |
| 2 | before the AC-4 mutant sweep | identical |
| 3 | after the 164-run differential | identical |
| 4 | `qa_semantics.py` start / end | identical (both) |
| 5 | `qa_errors.py` start / end (incl. 86 `main()`-driven aborts) | identical (both) |
| 6 | `qa_commands.py` start / end (incl. stubbed `update-rules`) | identical (both) |
| 7 | `qa_realbox.py` start / end (11 real `sing-box check` runs) | identical (both) |
| 8 | after 200 concurrent generations | identical |
| 9 | after `verify_all` | identical |
| 10 | final | `MainPID=2887037` / `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST` |

---

## 3. AC-4 — the non-vacuity proof (built and run **before** any green run was believed)

Six mutants of the **candidate**, each breaking exactly one of the six facts the differential claims
to compare. `qa_mutants.py` asserts each anchor matches exactly once, so a silent no-op mutation is
impossible.

```
### mutants (AC-4) ###
m1_value                 RESULT: FAIL — 172 mismatch(es)
m2_key_reorder           RESULT: FAIL — 172 mismatch(es)
m3_array_reorder         RESULT: FAIL — 52 mismatch(es)
m4_stderr_only           RESULT: FAIL — 152 mismatch(es)
m5_nodes_only            RESULT: FAIL — 72 mismatch(es)
m6_return_only           RESULT: FAIL — 8 mismatch(es)
```

| Mutant | What it breaks | First reported mismatch |
|---|---|---|
| **m1** `"level": "warn"` → `"warns"` | an emitted **value** | `subset00/a-no-nodes [en] config call1  line 3  baseline: "level": "warn"  candidate: "level": "warns"` |
| **m2** `dns."final"` ⇄ `dns."independent_cache"` | a **pure key reorder, no value changes** — R-1's exact case | `line 90  baseline: "final": "remote_dns"  candidate: "independent_cache": true` |
| **m3** `route.rules` geoip-cn ⇄ geosite-cn | an **array element reorder** | `subset03/… line 183  baseline: "geoip-cn"  candidate: "geosite-cn"` |
| **m4** `"⚠️  "` → `"⚠️ "` in `_warn_degraded` | **stderr only**, document untouched | `stderr call1  baseline: '⚠️  4/4 rule-sets unusable …'  candidate: '⚠️ 4/4 …'` |
| **m5** `nodes_data["qa_marker"] = 1` in the BC-3 rewrite | **nodes.json only** | `nodes call1  line 3  baseline: "nodes": []  candidate: "nodes": [],` |
| **m6** `if False and r.returncode != 0` | the **boolean return** only | `x-check-fails [en] return call1  base=False cand=True` (and the missing stderr line) |

m3 fails on 52/164 and m6 on 8/164 because only some points reach those facts (m3 needs
`geoip-cn` **and** `geosite-cn` usable; m6 needs the `/bin/false` check-failure points). m5 fires on
the `a-no-nodes` and `d-three-stale-active` states — exactly the states that take the `save_nodes()`
branch. Each mutant's blast radius is the shape it should be, which is a second, independent check
that the harness is measuring what it claims.

**A green run from a harness never shown to fail is worth nothing. This one was shown to fail six
different ways first.**

---

## 4. AC-1 / AC-2 / AC-3 / AC-11 / AC-12 — the gate, reproduced independently

```
$ python3 qa_diff.py --baseline pristine/bin/sc \
                     --candidate /home/alan/Programs/singbox-cli/bin/sc
compared 164 differential runs (82 points x 2 languages)
RESULT: PASS — byte-identical config, stderr (all calls), return value and nodes.json
```

**82 points = 64 + 18.** The 64 are the mandated closure: 16 rule-set usability subsets × 4
node/active states (`a` no nodes / `active` null; `b` one node; `c` three nodes, `active` = the
second; `d` three nodes, `active` naming a tag not in the list — the BC-3 rewrite path). The 18
extras, all layered on state (c):

`x-all-bad-magic`, `x-one-bad-magic`, `x-all-too-small`, `x-one-too-small`, `x-all-unreadable`,
`x-one-unreadable`, `x-mixed-status` (one file per non-usable status simultaneously),
`x-nonascii-tags`, `x-nonascii-stale-active`, `x-nonascii-degraded`, `x-clash-port-29137`,
`x-clash-port-1`, `x-alt-rules-dir`, `x-alt-rules-dir-degraded`, `x-three-calls`,
`x-three-calls-stale-active`, `x-check-fails`, `x-check-fails-degraded`.

**Compared per run, on EVERY call** (not just call 1 — `05` §9 **O-1** addressed):

1. `config.json` bytes 2. `nodes.json` bytes 3. captured stderr 4. the boolean return
5. the fixture file list (the candidate may add **exactly** `.config.sha256` and nothing else)
6. plus, on the candidate alone, that calls 2 and 3 produced the same bytes as call 1 (AC-11).

**860 individual comparisons**, in both `en` and `zh`.

**AC-2 — the oracle.** A pristine `git clone` at `f642ca7` (never a worktree). Its `bin/sc` is
`sha256 674be9f1e8256c6e75b8aa8cd5eed84167b15f4bb4b43bf787c1266c63e9d1e9`, which **equals the hash
`04` §2 recorded for the developer's pinned baseline** — an independent confirmation that the
developer's oracle really was the repository's pre-change source and not something else.

**Trap 1 inherited and honoured.** Baseline and candidate run at the *same* fixture path
(`<mkdtemp>/fixture`), wiped and re-seeded from scratch for each side of each point, because the
root is emitted verbatim inside `route.rule_set[].path`. `wipe()` removes dotfiles, so no candidate
run ever sees a stale `.config.sha256`.

---

## 5. Per-criterion results

### The hard gate

| AC | Result | Evidence |
|---|---|---|
| **AC-1** byte-identical over the closure | ✅ | 164 runs / 860 comparisons, above |
| **AC-2** oracle = pre-change source | ✅ | pristine clone at `f642ca7`, `.git` is a directory; hash matches `04` §2 |
| **AC-3** streams + return value too | ✅ | stderr and `rv` compared on **all** calls, both languages |
| **AC-4** non-vacuity | ✅ | 6 mutants, all FAIL — §3 |

### Structure

| AC | Result | Evidence |
|---|---|---|
| **AC-5** no literal in the function | ✅ | AST: `CONFIG_BASE` is a module-level `ast.Dict`; `generate_config`'s body contains **no** `Dict` node with ≥3 keys; top-level keys are `log dns inbounds outbounds route experimental` |
| **AC-6** exactly one merge, override goes through it | ✅ | AST: one `def _merge`. **Deletion test run**: `_compose([{"log": {"level": "debug"}}])` with the run-time overlay's call site removed yields `{"level": "debug", "timestamp": True}` and `outbounds == []` — the override composed through the same `_merge` |
| **AC-7** single self-contained file | ✅ | `git diff --stat -- install.sh` empty; AST import set ⊆ stdlib (`copy` and `stat` are the two additions) |
| **AC-8** `_filter_rules` unchanged | ✅ | `ast.dump` of the function is **identical** to the baseline's; parameters still `(rules, usable)`; exactly **2** call sites |
| **AC-9** observable ordering | ✅ | Live instrumentation of `_warn_degraded` / `_warn_drift` / `_write_private` / `_record_generated` / `subprocess.run`: `['warn_degraded', 'warn_drift', 'write:config.json', 'record', 'write:.config.sha256', 'check']` |
| **AC-10** sole writer | ✅ | grep of every `CFG_PATH` line for `write_text` / `open(...,"w")` / `.write(` → empty; exactly one `_write_private(CFG_PATH` |
| **AC-11** repeated calls | ✅ | 3-call points in the differential (self-compared **and** baseline-compared per call) + 3 calls with an override present + 200 concurrent generations |
| **AC-12** `nodes.json` unchanged | ✅ | compared per call in all 164 runs; separately with an override present over 3 calls |

### Override semantics

| AC | Result | Evidence |
|---|---|---|
| **AC-13** object deep-merge | ✅ | `{"log": {"level": "debug"}}` → `log` is `{"level": "debug", "timestamp": true}` **in that key order**; top-level key order unchanged; a *new* key appends without moving the existing ones |
| **AC-14** `$replace` | ✅ | `dns.rules` becomes exactly the override's array; `dns`'s own key order unchanged |
| **AC-15** `$prepend` / `$append` | ✅ | element first / last, the 12 base elements in their original order |
| **AC-16** anchored insertion | ✅ | `$after` on `{"clash_mode": "Direct"}` (the T-16/T-17 shape) lands at `anchor+1`; `$before` at `anchor-1`; every other element's relative order preserved (list equality against the base) |
| **AC-17** two overlays compose | ✅ | A after `Direct`, B after `Global`, both present at their own anchors; **and** the composed result is byte-equal when the two overlays are applied in the opposite order — no index arithmetic against the base |
| **AC-18** inserted value verbatim | ✅ | An inserted rule carrying `rule_set`, `domain_suffix`, a literal `"$append"` key, a literal `"$before"` key *and* a nested `{"$replace": …}` / `{"$patch": …}` is emitted **identical** — through `_compose` alone and end-to-end |
| **AC-19** bare arrays | ✅ | bare array at an absent key accepted (`{"newthing": [1,2,3]}` emitted); bare array over `dns.rules` rejected with a message naming `$prepend, $append, $replace` as a **readable joined string**, not a tuple repr (gate condition 6) |
| **AC-20** every error case | ✅ | **86 malformed cases** (43 shapes × 2 languages) driven through `main()`'s `reload` handler. Each asserts: config.json byte-identical to a hand-written sentinel, `SystemExit` carrying a **string** (⇒ status 1), the message names `OVERRIDE_PATH` **and** the specific problem, **one physical line** with no `\n` / `\r` / ESC, no `失败：`, and the drift record neither created nor changed. Plus the same for `sc add`, `sc rm`, `sc use`, `sc update-rules` |
| **AC-21** no service-affecting action | ✅ | `restart_service` replaced by a counting spy in **every** `main()` drive; `== 0` in all of them |

### Drift

| AC | Result | Evidence |
|---|---|---|
| **AC-22** drift stated before replacement | ✅ | `_write_private` hooked: at the instant `config.json` was opened for replacement, stderr already contained the drift line **and** the hand-edited bytes were still on disk. Exactly one line; names both `config.json` and `override.json`; one physical line; generation proceeded; the line clears on the next run. Rendered in Chinese through `main()` with `settings.json`'s `lang` pinned |
| **AC-23** silent when unchanged | ✅ | second consecutive generation emits nothing |
| **AC-24** absent record | ✅ | silent, and the run creates the record |
| **AC-25** no second credential copy | ✅ | record is `^[0-9a-f]{64}\n$`, 65 bytes, mode `0600`, equals `sha256(config.json on disk)`, contains no fragment of the node UUID |
| **AC-26** `sc doctor` writes nothing | ✅ | one `cmd_doctor` run against a fixture carrying a hand-modified `config.json`, a **malformed** `override.json` and no drift record → `{path: (bytes, mode)}` snapshot **identical** before and after; no drift record created; a report was produced; the override was never read (no `Cannot use` anywhere in the output) |

### Bilingual & documentation

| AC | Result | Evidence |
|---|---|---|
| **AC-27** `zh` parity, no `失败：` | ✅ | Keys extracted from the **code by AST** (not from `02` §8's table): exactly **17** new keys, all present in `TRANSLATIONS["zh"]`, placeholder sets equal, none containing `失败：`; **no pre-existing `zh` entry lost**; no new dynamic `t()` call site (the 2 at `bin/sc:1996` are pre-existing) |
| **AC-28** prose keys, no namespacing | ✅ | every new key is a space-separated English sentence with no CJK; none matches `^[a-z0-9_]+(\.[a-z0-9_]+)+$` |
| **AC-29** both READMEs | ✅ | 286 lines each; headings (22), code fences (30), table rows (39) and blank lines (78) at **identical line numbers**; both file-locations rows present |
| **AC-30** `verify_all` no new FAIL | ✅ | §9 |

### Boundary conditions

BC-1 – BC-6 are covered by the 82-point closure. Explicitly re-derived here:

| BC | Result | Evidence |
|---|---|---|
| BC-4 non-ASCII | ✅ | `'东京·节点①'.encode()` appears **raw** in the emitted bytes; no `\u` escape anywhere |
| BC-7 / T-1 both edges | ✅ | `{}`, whitespace-only and zero-byte all produce bytes identical to *absent*; `[]`, `null`, `0`, `"{"`, `true`, `"hi"` all stay **malformed** and write no `config.json` |
| BC-9 | ✅ | directory, FIFO, symlink→FIFO, symlink→`/dev/null` all rejected as `not a regular file`; **the FIFO cases were run under a 10 s `SIGALRM` and did not hang** |
| BC-10 | ✅ | mode-`000` file and a symlink loop (ELOOP) both rejected with the OS cause |
| BC-15 | ✅ | an override that nulls `external_controller` and replaces the `proxy` outbound is **accepted** (not prevented) and **passes the real `sing-box check`** — exactly the honest hazard the READMEs document |
| BC-16 / BC-17 | ✅ | no record ⇒ silent + record created; `config.json` absent ⇒ silent |
| BC-20 | ✅ | after ~1 400 compositions in single processes, `CONFIG_BASE`'s three placeholders are still `[]`, `[]`, `""` and its two rule arrays still hold 8 and 12 elements |
| BC-21 | ✅ | node objects reach the document unmutated (no marker key leaks back into `nodes.json`) |
| BC-22 | ✅ | emitted document ends `}\n}` — **no** trailing newline |
| BC-23 | ✅ | `['log','dns','inbounds','outbounds','route','experimental']`; `route` = `['default_domain_resolver','auto_detect_interface','rules','rule_set','final']` |
| BC-24 | ✅ | `/bin/false` points: one translated stderr warning + `return False`, identical to baseline, in both languages |
| BC-26 | ✅ | importing `bin/sc` (neutralised) created **nothing** under `/etc/sing-box` — directory listing byte-identical; the two new constants still point at `/etc` at import time and are only repointed afterwards |
| D-14 | ✅ | a symlink resolving to a **regular** file is accepted and its content applied (`log.level == "debug"`, exit 0) |

### Non-functional

| NFR | Result | Evidence |
|---|---|---|
| NFR-1 harness safety | ✅ | §2 |
| NFR-2 no new dependency | ✅ | AST import set ⊆ stdlib; `copy` + `stat` are the only additions |
| NFR-3 Python 3.6 floor | ⚠️ partial | AST: no walrus, no `dataclasses`, no `unlink(missing_ok=)`, and **no new `capture_output=`** (count identical to the baseline's 3). **Not executed under a 3.6 interpreter — none is installed on this host.** See §11 |
| NFR-4 credential confidentiality | ✅ | `config.json` mode `600` after 200 concurrent generations; drift record mode `600` and digest-only |
| NFR-5 cost | ✅ (measured) | `generate_config()`: baseline **1.554 ms**, candidate **2.340 ms** → **+0.785 ms** per call (+50 % in isolation, unchanged whether an override is present: 2.345 ms). Context: the `sing-box check` subprocess in the same function costs **7.2 ms** on this host, before any service restart. No network call, no extra subprocess. NFR-5's literal wording ("no *measurable* latency") is not true in a microbenchmark; it is immaterial in the command |
| NFR-6 compatibility | ✅ for the code path | BC-16 makes the upgrade silent and self-healing. `install.sh` itself was **not executed** — see §11 |
| NFR-7 non-TTY output | ✅ except D-2 | every error line and the drift line carry no `\n` / `\r` / ESC, including for a key containing a literal newline, a key containing CR + a CSI sequence, and an anchor value containing a newline. **Defect D-2 is the one exception** |

---

## Adversarial tests

One stated hypothesis per acceptance criterion, written **before** the run. Every reproducer is
mine; none is `04`'s. "Survived" means the implementation held under a test built to break it.

| AC | Hypothesis — "I expect failure when…" | Reproducer (all NEW, written here) | Outcome |
|---|---|---|---|
| AC-1 | the fixture root differs between sides, or a subset boundary shifts key order | `qa_diff.py` — 82 points × 2 langs, same fixture path, wipe-and-re-seed | **Survived** — `RESULT: PASS` (164 runs) |
| AC-2 | the developer's baseline was not really the repo's pre-change source | `sha256sum pristine/bin/sc` vs `04` §2 | **Survived** — `674be9f1…d1e9`, identical |
| AC-3 | stderr differs on a repeat call (O-1's gap) | per-call stderr comparison for all 3 calls at the AC-11 points | **Survived** — calls 2 and 3 emit `''` on both sides |
| AC-4 | a reorder that changes no value slips through | `qa_mutants.py` m2 | **Survived (as a failure)** — 172 mismatches; harness proven live |
| AC-5 | a dict literal survives inside `generate_config` under another name | AST walk for any `Dict` with ≥3 keys in the function | **Survived** — none |
| AC-6 | a second merge path exists for the override | AST count of `def _merge` + the deletion test | **Survived** — 1 definition; override composes with the run-time overlay removed |
| AC-7 | a non-stdlib import or an `install.sh` edit crept in | AST import set; `git diff --stat -- install.sh` | **Survived** — stdlib only; empty diff |
| AC-8 | `_filter_rules` was silently reshaped | `ast.dump` equality against the pristine clone | **Survived** — byte-for-byte the same function |
| AC-9 | the write moved relative to the warnings | runtime instrumentation of 5 functions | **Survived** — exact expected order |
| AC-10 | a second write path to `config.json` exists | grep every `CFG_PATH` line for a write verb | **Survived** — none |
| AC-11 | `_filter_rules`' in-place mutation corrupts the template for call 2 | 3 calls × 4 points, self-compared; then 200 concurrent | **Survived** — identical bytes, `CONFIG_BASE` intact |
| AC-12 | composition aliases the node objects into the document | marker-key check + per-call `nodes.json` comparison | **Survived** |
| AC-13 | the merged key moves position | key-order equality on `log` and on the top level | **Survived** |
| AC-14 | `$replace` re-appends the key at the end | `list(d["dns"])` vs base | **Survived** |
| AC-15 | base order is disturbed | list equality on the 12 untouched elements | **Survived** |
| AC-16 | the anchor matches the wrong `clash_mode` rule | index arithmetic against the located anchor | **Survived** |
| AC-17 | the second insertion uses an index computed against the base | compose A→B **and** B→A, compare results | **Survived** — identical |
| AC-18 | a `$` key inside an inserted element is interpreted | insert an element carrying `$append`, `$before` and a nested `$patch` | **Survived** — verbatim |
| AC-19 | the directive list renders as a tuple repr (gate C-6) | assert the joined string is in the message | **Survived** |
| AC-20 | one of 43 malformed shapes writes, exits 0, or emits >1 line | `qa_errors.py`, 86 `main()` drives | **Survived** for all 43 in both languages |
| AC-21 | some command reaches `restart_service` before the abort | counting spy on `restart_service` in every drive, incl. `add`/`rm`/`use`/`update-rules` | **Survived** — 0 calls everywhere |
| AC-22 | the drift line is emitted *after* the replacement | hook `_write_private` and read stderr **and** the on-disk bytes at that instant | **Survived** — line present, old bytes still on disk |
| AC-23 | a no-op regeneration warns | second consecutive run | **Survived** — silent |
| AC-24 | an absent record warns on every upgrading host | fresh fixture with `config.json` but no record | **Survived** — silent, record created |
| AC-25 | the record leaks credential bytes or a wrong mode | regex + mode + UUID-substring check | **Survived** — 65 B, `0600`, digest only |
| AC-26 | `doctor` reads the override or creates the record | byte-**and-mode** tree snapshot around one `cmd_doctor` | **Survived** — identical tree |
| AC-27 | a key exists in the code but in neither table (insight-index's invisible class) | AST extraction from **code**, not from `02` §8 | **Survived** — 17/17 present, placeholders equal, no `失败：`, no pre-existing entry lost |
| AC-28 | a namespaced key like `ls.idx` was added | regex over the 17 extracted keys | **Survived** |
| AC-29 | the two READMEs drifted apart | heading/fence/table/blank line-number equality | **Survived** — 286 = 286, all identical |
| AC-30 | a new FAIL appears vs a pristine clone | `verify_all` on both trees | **Survived** — 0 FAIL both sides |

### Adversarial probes beyond the criteria (where the three defects came from)

| Probe | Hypothesis | Outcome |
|---|---|---|
| **Dangling symlink** at `override.json` | D-14 endorses symlinking into a VCS dir; what happens when the target moves? | **FAILED → D-1 (MAJOR)** — silently absent, `rv=True`, empty stderr, config replaced. The same fixture through the project's own `ruleset_state()` returns `('unreadable', None, None)` |
| **Deeply nested override** | `json.loads` / `deepcopy` recursion is not a `ValueError` | **FAILED → D-2 (MINOR)** — a **3 001-byte** override (500 levels) yields a **2 999-line, 135 KB** `RecursionError` traceback, exit 1 |
| **Object over an existing array** | D-5 forbids the mirror case; is the symmetric one guarded? | **FAILED → D-3 (MINOR)** — `{"inbounds": {"mtu": 1500}}` silently replaces the array; exit 0 with the stub; caught only by the real `sing-box check` |
| **Corrupt** (not absent) drift record | `read_text()` on invalid UTF-8 raises `UnicodeDecodeError`, a `ValueError` | **Survived** — 6 corruption shapes (invalid UTF-8, empty, whitespace, short hex, 200 KB, NUL bytes) all degrade correctly and are repaired by the run |
| Drift record path is a **directory** | `_write_private` would raise `IsADirectoryError` | **Survived** — best-effort swallow, `rv=True`, no crash |
| **generate → edit → generate → edit → generate** | the record could go stale and warn forever, or never | **Survived** — `[False, True, True]`, exactly right |
| **200 concurrent generations** (8 threads × 25) | the record could describe another process's document ⇒ false drift | **Survived** — 0 spurious warnings, `record == sha256(disk)`, no `.tmp` residue, mode `600`. Structural: `_config_digest()` hashes the **file**, so the record can never disagree with the disk |
| **The real `sing-box` 1.13.15**, not a stub | the composed document might be structurally different in a way `/bin/true` hides | **Survived** — baseline and candidate both `rc=0`; 7 override shapes all `rc=0` |
| `sc use` **hot-apply arm** with a malformed override | `cmd_use` might read the override anyway | **Survived** — `generate_config` called 0 times, exit 0 |
| `sc mode` with a malformed override | the README says it never regenerates | **Survived** — exit 0, config untouched, mode persisted |
| `sc update-rules` with **nothing changed** / with a **gain** | the README's "may do so as well" must be exact | **Survived** — 0 regenerations vs 1 |
| **`LC_ALL=C`** (what `sudo`'s `env_reset` leaves) | R-4's `_write_private` exposure | **Confirmed, pre-existing** — see §7 |
| **UTF-8 BOM** override | `str.strip()` does not strip `U+FEFF` | Malformed, with an actionable message — see §7 |

---

## 6. Defects

### [MAJOR] D-1 — a dangling symlink at `override.json` is silently treated as *absent*

**The user's entire override is discarded, `config.json` is overwritten, and `sc` reports success.**

Reproducer (fixture only — nothing under `/etc` is touched):

```
wipe(); seed(N3, "osaka-02", ALL_USABLE, config_bytes=SENTINEL); repoint(sc)
(ROOT/"override.json").symlink_to(ROOT/"my-overrides"/"sing-box.json")   # target absent
sc.generate_config()
```

Measured:

```
DANGLING SYMLINK: rv=True stderr='' config replaced=True
  the same fixture, via ruleset_state (project precedent): ('unreadable', None, None)
```

Through `main()`: `exit=0`, `stderr=''`, `config.json` replaced. No drift warning either — `sc`
generated the file, so the record matches.

**File:line.** `bin/sc:1279-1282`:

```python
    try:
        st = os.stat(str(OVERRIDE_PATH))
    except FileNotFoundError:
        return None
```

`os.stat` follows symlinks (which is what makes D-14 work), so a **broken** link raises
`FileNotFoundError` and lands in the "absent" arm.

**Why this is MAJOR and not a nit.**

1. It is the failure mode `01` §2 names as the reason the task exists: *"a hand-edit to `config.json`
   is discarded with no message."* Here the *override* is discarded with no message.
2. The workflow that produces it is the one `02` §5.4 / D-14 explicitly blesses: *"users legitimately
   symlink their configuration into a version-controlled directory."* A branch checkout, a `git
   clean`, or a moved dotfiles repo breaks the link. The next `sc reload` — or `install.sh` step 7 —
   silently drops every customisation.
3. `bin/sc` already decides this exact question, the other way, for the other user-facing file:
   `ruleset_state()` (`bin/sc:723`) — *"A dangling symlink does not exist, but it is broken rather
   than absent."* Two functions in one file now hold **opposite opinions about the same shape**,
   which is precisely what `docs/dev-map.md`'s "never a second opinion" pattern forbids.
4. BC-9's enumeration ("directory, FIFO, device, or any non-regular file **after symlink
   resolution**") does not literally cover "resolves to nothing", so no AC is violated — which is
   why this is a boundary the requirement missed, not an implementation slip.

**Fix shape (for the developer — not applied here).** In the `FileNotFoundError` arm, distinguish a
broken link from a genuinely absent file, e.g. `if os.path.islink(str(OVERRIDE_PATH)): raise
OverrideError(...)`. `os.path` is already reachable through the imported `os`; the existing key 6
(`cannot be read ({err})`) could carry it, or one new key + `zh` entry. **It cannot affect AC-1**:
with no override there is no symlink, so the 164-run gate is untouched by any fix here. Re-running
`qa_diff.py` after the fix is nevertheless the right gate.

**Owner: developer** (via PM). **Also for the requirement-analyst:** BC-9 should gain the case.

---

### [MINOR] D-2 — a deeply nested override produces a 2 999-line Python traceback, not a sentence

Reproducer:

```
override.json = '{"a":' * 500 + '1' + '}' * 500        # 3 001 bytes, well under the 1 MiB cap
sc reload
```

Measured:

```
EXIT=1
stderr: 2999 lines (135 KB), ending in
  RecursionError: maximum recursion depth exceeded
config.json untouched: True
.config.sha256 created: False
```

The deepest frames are `bin/sc:1245 target[key] = copy.deepcopy(value)` → `copy.py:_deepcopy_dict`.
The threshold on this host is between 490 (fine) and 500 (raises).

**Assessment.** No write, no service action, non-zero exit — so `config.json` and the service are
safe. What fails is the *contract*: `01` B-11 wants a message naming the file and the fault, and
NFR-7 wants one complete line per fact because `sc reload`'s streams are redirected into
`/var/log/sing-box/install.log` (BC-18). 135 KB of traceback into the install log is the opposite.
The trigger requires a deliberately or accidentally pathological document, which is why this is
MINOR rather than MAJOR.

**Same family as `05`'s MINOR-1.** Both are "an override shape outside BC-8…BC-14's enumeration
reaches a Python traceback instead of a sentence". I reproduced MINOR-1 unchanged and in three
variants:

```
MINOR-1 non-object element appended to dns.rules    exc="AttributeError: 'str' object has no attribute 'get'"   config.json untouched=True  restarts=0
MINOR-1 non-object element appended to route.rules  exc="AttributeError: 'int' object has no attribute 'get'"   config.json untouched=True  restarts=0
MINOR-1 null element appended to dns.rules          exc="AttributeError: 'NoneType' object has no attribute 'get'" config.json untouched=True  restarts=0
```

**Recommendation:** one open row in `docs/tasks.md` covering the family, listing both instances.
**Owner: requirement-analyst**, per `05`'s routing for MINOR-1. Do **not** widen `02` §6's shape
assertion or touch `_filter_rules` inside T-14.

---

### [MINOR] D-3 — a bare **object** silently replaces an existing array (the mirror of D-5, unguarded)

```
override.json = {"inbounds": {"mtu": 1500}}
→ exit 0, emitted document has  "inbounds": {"mtu": 1500}   (the whole TUN inbound gone)
```

`02` §5.3's table specifies this (`plain object | absent, or not an object | target[key] =
deepcopy(value)`), so it is **as designed** — but D-5's own rationale argues against it: a bare
*array* over an existing array is an error precisely because *"a user writing one `dns.rules` entry
to add it and silently getting a one-rule DNS section"* is intolerable. Writing
`{"inbounds": {"mtu": 1500}}` to tweak the MTU is the same mistake in the other direction, and it is
accepted in silence.

**Contained, not dangerous.** Verified against the real binary:

```
ASYMMETRY: object silently replacing the inbounds array   rc=1
  FATAL decode config: inbounds: json: cannot unmarshal object into Go struct field _Options
```

so `sing-box check` rejects it, `generate_config()` returns `False`, `sc reload` exits
`Reload failed`, and the service is never restarted. For `dns.rules` / `route.rules` /
`route.rule_set` the §6 shape assertion catches it with a sentence first; the gap is the arrays
*outside* those three (`inbounds`, `outbounds`, `dns.servers`).

**Owner: requirement-analyst** — a vocabulary note for T-15/T-16, or one open row. Not a T-14
blocker.

---

## 7. Confirmed, not defects

| Item | Finding |
|---|---|
| **R-4** (`_write_private` has no `encoding=`) | **Confirmed, pre-existing, identical on both sides.** Under `LC_ALL=C` (`preferred encoding: ANSI_X3.4-1968`) both baseline and candidate raise on a non-ASCII node tag. **Refinement for the pool row:** the raise is *not* in `_write_private` — it is a `UnicodeDecodeError` in `load_nodes()` (`bin/sc:418`, `NODES_PATH.read_text()`), which fires first. `02` §13's statement names only the write side; the read side is the earlier and equally real exposure. ASCII-only nodes are unaffected. Deliberately **not fixed**, per the gate |
| **UTF-8 BOM** override | Treated as **malformed**, with an actionable message: `not valid JSON (Unexpected UTF-8 BOM (decode using utf-8-sig): line 1 column 1 (char 0))`. `str.strip()` does not strip `U+FEFF`, so T-1's "whitespace ≡ absent" branch does not swallow it. Correct behaviour; noted because a Windows editor produces it |
| `sc add` + malformed override | The node **is** persisted before the abort (`tags=['tokyo-01','osaka-02','sg-03','qa-new']`), then exit 1. This is A-5 as specified and `04` §11.3 as recorded. Confirmed, not re-litigated |
| T-3 (`sc update-rules` skips its run-level outcome line) | Reproduced with a stubbed `_fetch_to_temp` (no network): with a rule-set **gained** and a malformed override, the outcome line is **not** printed and the command exits 1 with the override sentence. Exactly the gate's ship-as-designed ruling; `docs/tasks.md` R-12 records it (gate condition 8 discharged) |
| `route.rule_set` with a non-object element | Accepted (the `isinstance(d, dict)` guard at `:1475` is doing its job); the real `sing-box check` would reject the document. No traceback |
| NaN / Infinity smuggled through `json.loads` | Emitted verbatim, so `config.json` becomes non-JSON; the real binary rejects it (`rc=1 … invalid character 'N'`), `return False`, no restart. Inside D-2's pre-existing envelope ("a schema-invalid document reaches disk before `check` rejects it") |

---

## 8. `05` §9 — the six observations, dispositions

| # | Disposition |
|---|---|
| **O-1** | **Addressed.** My differential compares stderr, the return value, `config.json` **and** `nodes.json` on **every** call of the 3-call points, and additionally self-compares calls 2/3 against call 1. Calls 2 and 3 emit `''` on both sides; the gap the developer left is real but empty |
| **O-2** | **Addressed.** AC-22/AC-23/AC-24 were re-derived from scratch (`qa_semantics.drift`), not re-run: the drift line's presence, its position *relative to the replacement* (hooked `_write_private`), its content in both languages, its one-line shape, its clearing, six corrupt-record shapes, a directory at `STATE_PATH`, and the edit→generate→edit→generate sequence |
| **O-3** | **Confirmed stale, moved on.** `git diff --stat -- CHANGELOG.md` is **empty** (the file is not modified in the current tree); `docs/features/` contains only `_archived/` and `config-composition-layer/` — no `sc-doctor/`. Both were snapshot artifacts |
| **O-4** | **Inherited.** Every `main()`-driven test seeds `settings.json` with `lang`, and the Chinese assertions test **actual Chinese content** (`startswith("无法使用 ")`, `"曾被 sc 以外的方式修改" in stderr`), not properties both languages share |
| **O-5** | **Confirmed as a real boundary.** `{"dns": {"rules": {"0": {...}}}}` does not address element 0 — the object is not a directive, so it **replaces the whole array**, and the §6 shape assertion then rejects it. There is no vocabulary for reaching inside an array element; the only route is `$replace` of the whole array, or `$before`/`$after` with an anchor. T-15/T-16 inherit this accurately. (The same mechanism is D-3 above when the array is *not* one of the three shape-asserted paths) |
| **O-6** | Not a finding. F.6 is WARN-only and clears on archive |

---

## 9. `verify_all`

```
$ bash .harness/scripts/verify_all.sh          # working tree
[A.1] No hardcoded secrets ... PASS          [E.4b] Hook commands resolve ... PASS
[A.2] No .env files committed ... PASS       [E.5] AI-GUIDE indexes rules ... PASS
[B.1] Syntax (bin/sc, install.sh, ...) PASS  [E.6] Adversarial tests section ... PASS
[B.2] install.sh bilingual key parity . PASS [F.1] AI-GUIDE.md <=200 lines ... PASS
[B.3] Lint ... SKIP                          [F.2] Rule fragments <=200 lines ... PASS
[E.1] Bootstrap files present ... PASS       [F.3] Agent definitions <=300 lines PASS
[E.2] workflow.md present ... PASS           [F.4] insight-index.md <=30 lines .. PASS
[E.3] Agents layout v0.30+ ... PASS          [F.5] docs/tasks.md <=300 lines .... PASS
[E.4] Binding in sync ... PASS               [F.6] Active task docs <=500 lines . WARN

=== Summary ===  PASS: 16   WARN: 1   FAIL: 0   SKIP: 1
```

| Tree | PASS | WARN | FAIL | SKIP |
|---|---|---|---|---|
| Pristine **clone** at `f642ca7` (the AC-30 oracle) | 17 | 0 | 0 | 1 |
| Working tree (T-14 applied) | 16 | 1 | 0 | 1 |

**Delta: 0 new FAIL.** The single WARN is F.6, caused by `01` (539 L), `02` (637 L), `04` (721 L)
and this report — all four clear on `archive-task`. `.git` is a directory in the clone, so A.1/A.2
are genuine PASSes and the 17/1 split is real, not the 14/4 a worktree would have produced.

**`baseline.json` not updated — judgment call recorded.** `.harness/scripts/baseline.json` holds
`test_count: 0`. `01` O-8 / open row R-9 state that no `bin/sc` harness is committed or wired into
`verify_all`; this stage's harness is a throwaway like the developer's. The committed test count
therefore did **not** increase, and raising it would record tests that do not exist. `warnings_baseline`
is likewise left at 0 rather than ratcheted to 1 for a WARN that clears on archive. Closing R-9 is
the task that should move this file.

---

## 10. Stability

The complete suite was run **10 consecutive times**:

```
run 1 | diff: RESULT: PASS … | sem: 180 ok, 0 FAILED, 3 notes | err: 95 ok, 1 FAILED | cmd: 22 ok, 0 FAILED
run 2 | …identical…
…
run 10| diff: RESULT: PASS … | sem: 180 ok, 0 FAILED, 3 notes | err: 95 ok, 1 FAILED | cmd: 22 ok, 0 FAILED
```

**No flakes: 10/10 identical.** The single `FAILED` in `qa_errors.py` is defect **D-2**, reproducible
10/10. The six mutants also fail identically on every repetition.

Totals: **1 158 individual assertions** — 860 differential comparisons + 180 semantic + 96 error-path
+ 22 per-command — plus 11 real `sing-box check` invocations, 200 concurrent generations and the
6-mutant non-vacuity sweep.

---

## 11. What I could NOT verify (stated, not implied)

1. **Python 3.6 execution (NFR-3).** No 3.6 interpreter is installed. I checked the *syntax* floor
   by AST (no walrus, no `dataclasses`, no `missing_ok=`, no **new** `capture_output=`) and confirmed
   the emitted key order relies on CPython dict insertion order as BC-23 documents — but nothing was
   actually run under 3.6.
2. **`install.sh` end-to-end (BC-18 / BC-19 / NFR-6 / AC-7's `curl | bash` claim).** `install.sh` is
   out of scope and must not be executed. I verified `install.sh` is byte-unchanged and that
   `cmd_reload` exits non-zero on `OverrideError` (which is what step 7 would observe), but the
   installer's own `PHASE_CONFIG=failed` derivation and banner were **not** exercised.
3. **A real service restart / a real drifted host.** Never attempted, by rule. `restart_service` was
   always a spy and `SYSTEMD`/`OPENRC` always `False`.
4. **OpenRC / Alpine, and any host that is not this one.** Only the Linux + systemd + Python 3.12
   configuration on this machine was exercised. `_load_override`'s behaviour on a filesystem without
   symlinks, or with a case-insensitive path, is untested.
5. **`sing-box` actually *loading* a composed document.** I ran `sing-box check` (schema validation)
   11 times against the real 1.13.15 binary; I did not start a sing-box instance with any of them.
6. **Overrides at the 1 MiB boundary in anger.** The size cap is exercised at cap+64 bytes; I did not
   test a legitimate 1 MiB-minus-one-byte override for performance.
7. **The `route.rule_set` / `dns.servers` / `outbounds` D-3 variants against a real host.** They were
   validated by `sing-box check` only.
8. **`_egress_ip()` in `sc doctor`** was stubbed to stay offline; the AC-26 no-write property was
   verified with that one probe disabled.

---

## 12. Routing

| Defect | Severity | Owner | Blocks delivery? |
|---|---|---|---|
| **D-1** dangling symlink ⇒ silently absent | MAJOR | **developer** (fix `_load_override`'s `FileNotFoundError` arm); requirement-analyst to widen BC-9 | **Yes** — this is the CHANGES REQUIRED |
| **D-2** deep nesting ⇒ 2 999-line traceback (with `05` MINOR-1, one family) | MINOR | requirement-analyst — one open row in `docs/tasks.md` | No |
| **D-3** object silently replaces an existing array | MINOR | requirement-analyst — vocabulary note for T-15/T-16 | No |
| R-4 refinement (`load_nodes()` fails before `_write_private`) | — | requirement-analyst — fold into R-4's pool row | No |

After D-1 is fixed, the only re-test required is: `qa_diff.py` (the byte-identity gate must still be
green — it cannot be affected, but prove it), plus the BC-9 rows of `qa_errors.py`.

---

## 13. The harness, verbatim and runnable

Seven files. To reproduce from scratch:

```bash
mkdir -p qa && cd qa
git clone /home/alan/Programs/singbox-cli pristine && (cd pristine && git checkout f642ca7)
# ... save the seven files below ...
python3 qa_mutants.py                                   # AC-4 mutants
for m in mutants/*.py; do python3 qa_diff.py --baseline pristine/bin/sc --candidate $m; done
python3 qa_diff.py --baseline pristine/bin/sc --candidate /path/to/repo/bin/sc
python3 qa_semantics.py && python3 qa_errors.py && python3 qa_commands.py && python3 qa_realbox.py
```

Every file refuses to run as root and asserts all seven path constants resolve inside its own
`mkdtemp()` root before any command is driven.

### `qa_common.py`

```python
#!/usr/bin/env python3
"""T-14 QA — shared, INDEPENDENTLY WRITTEN fixture/loader layer.

Derived from `01`'s ACs and from the pre-change source, not from `04`'s harness. The
only thing knowingly copied is the neutralisation recipe in docs/dev-map.md "Patterns
to avoid", which is copied VERBATIM because the rules forbid inventing another.
"""
import io
import json
import os
import shutil
import stat as _stat
import sys
import tempfile
import types
from pathlib import Path

# ------------------------------------------------------------------ safety rails
# Not ceremony: the mode-000 `unreadable` rule-set fixture only produces "unreadable"
# for a non-root reader. As root four of the sixteen subsets silently collapse.
assert os.geteuid() != 0, "QA harness must not run as root"

REPO = Path("/home/alan/Programs/singbox-cli")
SEVEN = ("CFG_DIR", "CFG_PATH", "NODES_PATH", "SETTINGS_PATH", "RULES_DIR",
         "OVERRIDE_PATH", "STATE_PATH")


def load_module(src_path, name):
    """docs/dev-map.md "Patterns to avoid" recipe, verbatim."""
    src_path = str(src_path)
    sc = types.ModuleType(name)
    shim = types.ModuleType("os")
    shim.__dict__.update(os.__dict__)
    shim.geteuid = lambda: 0                   # the elevate branch is simply not taken
    sys.modules["os"] = shim
    try:
        # encoding= is the harness's own affair: the interpreter reads a *script* as
        # UTF-8 per PEP 3120 regardless of locale, so this keeps the loader faithful
        # to how bin/sc is really executed even under LC_ALL=C.
        exec(compile(open(src_path, encoding="utf-8").read(), src_path, "exec"),
             sc.__dict__)
    finally:
        sys.modules["os"] = os                 # restore IMMEDIATELY, in a finally
    # The module must not have re-exec'd, and must not have written anything.
    assert sc.__dict__.get("CFG_DIR") == Path("/etc/sing-box")
    return sc


PARENT = Path(tempfile.mkdtemp(prefix="t14qa-"))
assert str(PARENT).startswith(tempfile.gettempdir() + os.sep)
assert not str(PARENT).startswith("/etc")
ROOT = PARENT / "fixture"           # STABLE path: it is emitted inside route.rule_set[].path
ALT_RULES = PARENT / "altrules"     # for the non-default RULES_DIR extra


def _inside(child, parent):
    try:
        Path(child).resolve().relative_to(Path(parent).resolve())
        return True
    except ValueError:
        return False


def repoint(sc, root=ROOT, rules_dir=None, lang="en", clash_port=29090,
            sb_bin="/bin/true"):
    """Repoint every path constant into the harness-owned temp tree and PROVE it."""
    sc.CFG_DIR = Path(root)
    sc.CFG_PATH = sc.CFG_DIR / "config.json"
    sc.NODES_PATH = sc.CFG_DIR / "nodes.json"
    sc.SETTINGS_PATH = sc.CFG_DIR / "settings.json"
    sc.RULES_DIR = Path(rules_dir) if rules_dir else sc.CFG_DIR / "rules"
    # The candidate has these two; the baseline does not — setting them is a no-op there.
    sc.OVERRIDE_PATH = sc.CFG_DIR / "override.json"
    sc.STATE_PATH = sc.CFG_DIR / ".config.sha256"
    sc.SYSTEMD = False
    sc.OPENRC = False
    sc.CLASH_PORT = clash_port
    sc.LANG = lang
    sc.SB_BIN = sb_bin
    # THE structural guard. Not vigilance: an assertion.
    for const in SEVEN:
        val = sc.__dict__.get(const)
        assert val is not None, "missing path constant %s" % const
        assert _inside(val, PARENT), "%s escaped the temp root: %s" % (const, val)
        assert not str(val).startswith("/etc"), "%s is under /etc: %s" % (const, val)
    assert sc.SYSTEMD is False and sc.OPENRC is False
    return sc


# ------------------------------------------------------------------ fixtures
USABLE = b"SRS" + b"\x01" * 64
BAD_MAGIC = b"XRS" + b"\x01" * 64
TOO_SMALL = b"SRS"
RULESET_FILENAMES = ("geoip-cn.srs", "geosite-cn.srs",
                     "geosite-google.srs", "geosite-private.srs")


def node(tag, host="203.0.113.7", port=443):
    return {
        "type": "vless", "tag": tag, "server": host, "server_port": port,
        "uuid": "11111111-2222-3333-4444-555555555555",
        "flow": "xtls-rprx-vision",
        "tls": {"enabled": True, "server_name": "example.com",
                "utls": {"enabled": True, "fingerprint": "chrome"}},
    }


def _chmod_tree(path):
    for dirpath, dirnames, filenames in os.walk(str(path)):
        for n in dirnames + filenames:
            try:
                os.chmod(os.path.join(dirpath, n), 0o700)
            except OSError:
                pass


def wipe(root=ROOT):
    """Remove EVERYTHING, dotfiles included — a stale .config.sha256 would make the
    candidate emit a drift line the baseline cannot."""
    root = Path(root)
    if root.exists():
        _chmod_tree(root)
        shutil.rmtree(str(root))
    assert not root.exists()


def seed(nodes, active, statuses, root=ROOT, rules_dir=None, lang="en",
         override=None, config_bytes=None, state_bytes=None):
    """statuses: 4-tuple, one of usable/absent/bad-magic/too-small/unreadable per file
    in RULESET_FILES order."""
    root = Path(root)
    root.mkdir(parents=True)
    rd = Path(rules_dir) if rules_dir else root / "rules"
    if rd.exists():
        _chmod_tree(rd)
        shutil.rmtree(str(rd))
    rd.mkdir(parents=True)
    for fname, status in zip(RULESET_FILENAMES, statuses):
        p = rd / fname
        if status == "absent":
            continue
        if status == "usable":
            p.write_bytes(USABLE)
        elif status == "bad-magic":
            p.write_bytes(BAD_MAGIC)
        elif status == "too-small":
            p.write_bytes(TOO_SMALL)
        elif status == "unreadable":
            p.write_bytes(USABLE)
            os.chmod(str(p), 0o000)
        else:
            raise AssertionError("unknown status " + status)
    (root / "nodes.json").write_bytes(
        json.dumps({"active": active, "nodes": nodes}, indent=2,
                   ensure_ascii=False).encode("utf-8"))
    # main() reassigns LANG from settings.json via _load_lang(); a test that drives
    # main() and sets only sc.LANG renders English and makes every zh assertion vacuous.
    (root / "settings.json").write_bytes(
        json.dumps({"default_tun": True, "mode": "rule", "lang": lang},
                   indent=2).encode("utf-8"))
    if override is not None:
        if isinstance(override, bytes):
            (root / "override.json").write_bytes(override)
        else:
            (root / "override.json").write_bytes(override.encode("utf-8"))
    if config_bytes is not None:
        (root / "config.json").write_bytes(config_bytes)
    if state_bytes is not None:
        (root / ".config.sha256").write_bytes(state_bytes)
    return root


def tree_snapshot(root=ROOT):
    """{relative path: (bytes, mode)} for every regular file under root."""
    out = {}
    root = Path(root)
    for dirpath, dirnames, filenames in os.walk(str(root)):
        for n in filenames:
            p = Path(dirpath) / n
            rel = str(p.relative_to(root))
            st = os.lstat(str(p))
            if _stat.S_ISLNK(st.st_mode):
                data = b"<symlink->" + os.readlink(str(p)).encode()
            elif not _stat.S_ISREG(st.st_mode):
                data = b"<non-regular:%o>" % _stat.S_IFMT(st.st_mode)
            else:
                try:
                    data = p.read_bytes()
                except OSError:
                    data = b"<unreadable>"
            out[rel] = (data, _stat.S_IMODE(st.st_mode))
    return out


def file_list(root=ROOT):
    return sorted(tree_snapshot(root).keys())


class Captured(object):
    def __init__(self, rv, err, exc, config, nodes):
        self.rv = rv
        self.err = err
        self.exc = exc
        self.config = config
        self.nodes = nodes


def run_generate(sc, calls=1):
    """generate_config() with stderr, return value, config bytes and nodes.json bytes
    captured after EVERY call — not just the first (05 §9 O-1)."""
    results = []
    for _ in range(calls):
        buf = io.StringIO()
        old = sys.stderr
        sys.stderr = buf
        try:
            rv, exc = None, None
            try:
                rv = sc.generate_config()
            except BaseException as e:              # noqa: BLE001 - harness
                exc = "%s: %s" % (type(e).__name__, e)
        finally:
            sys.stderr = old
        cfg = sc.CFG_PATH.read_bytes() if sc.CFG_PATH.exists() else None
        nodes = sc.NODES_PATH.read_bytes() if sc.NODES_PATH.exists() else None
        results.append(Captured(rv, buf.getvalue(), exc, cfg, nodes))
    return results


def witness(label):
    import subprocess
    out = subprocess.run(["systemctl", "show", "sing-box", "-p", "MainPID",
                          "-p", "ActiveEnterTimestamp"],
                         stdout=subprocess.PIPE, text=True).stdout.strip()
    print("[witness %s] %s" % (label, out.replace("\n", " | ")))
    return out
```

### `qa_diff.py`

```python
#!/usr/bin/env python3
"""T-14 AC-1/AC-2/AC-3/AC-11/AC-12 — QA's OWN differential.

Oracle = the pre-change `bin/sc` obtained from a pristine CLONE at f642ca7.
Candidate = the working tree's `bin/sc`.
Compared per point: config.json bytes, stderr of EVERY call, the boolean return of
EVERY call, nodes.json bytes, and the fixture file list.
"""
import argparse
import itertools
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qa_common import (ALT_RULES, PARENT, ROOT, RULESET_FILENAMES, file_list,
                       load_module, node, repoint, run_generate, seed, wipe,
                       witness)

NODE_STATES = {
    "a-no-nodes": ([], None),
    "b-one-node": ([node("tokyo-01")], "tokyo-01"),
    "c-three-active-2nd": ([node("tokyo-01"), node("osaka-02"), node("sg-03")],
                           "osaka-02"),
    "d-three-stale-active": ([node("tokyo-01"), node("osaka-02"), node("sg-03")],
                             "ghost-99"),
}
NONASCII = [node("东京·节点①"), node("大阪-ノード②"), node("Zürich-③")]


def points():
    pts = []
    # --- the 64: 16 rule-set subsets x 4 node/active states -------------------
    for mask in range(16):
        statuses = tuple("usable" if (mask >> i) & 1 else "absent" for i in range(4))
        for sname, (nodes, active) in NODE_STATES.items():
            pts.append(dict(name="subset%02d/%s" % (mask, sname), nodes=nodes,
                            active=active, statuses=statuses))
    # --- extras, layered on state (c) ----------------------------------------
    c_nodes, c_active = NODE_STATES["c-three-active-2nd"]
    for st in ("bad-magic", "too-small", "unreadable"):
        pts.append(dict(name="x-all-%s" % st, nodes=c_nodes, active=c_active,
                        statuses=(st,) * 4))
        pts.append(dict(name="x-one-%s" % st, nodes=c_nodes, active=c_active,
                        statuses=(st, "usable", "usable", "usable")))
    pts.append(dict(name="x-mixed-status", nodes=c_nodes, active=c_active,
                    statuses=("absent", "bad-magic", "too-small", "unreadable")))
    pts.append(dict(name="x-nonascii-tags", nodes=NONASCII, active="大阪-ノード②",
                    statuses=("usable",) * 4))
    pts.append(dict(name="x-nonascii-stale-active", nodes=NONASCII, active="不存在",
                    statuses=("usable", "absent", "usable", "absent")))
    pts.append(dict(name="x-nonascii-degraded", nodes=NONASCII, active="东京·节点①",
                    statuses=("absent",) * 4))
    pts.append(dict(name="x-clash-port-29137", nodes=c_nodes, active=c_active,
                    statuses=("usable",) * 4, clash_port=29137))
    pts.append(dict(name="x-clash-port-1", nodes=c_nodes, active=c_active,
                    statuses=("usable", "absent", "usable", "absent"), clash_port=1))
    pts.append(dict(name="x-alt-rules-dir", nodes=c_nodes, active=c_active,
                    statuses=("usable", "usable", "absent", "usable"),
                    rules_dir=str(ALT_RULES)))
    pts.append(dict(name="x-alt-rules-dir-degraded", nodes=c_nodes, active=c_active,
                    statuses=("absent",) * 4, rules_dir=str(ALT_RULES)))
    # AC-11 — three consecutive calls in ONE process, stderr compared on ALL THREE
    pts.append(dict(name="x-three-calls", nodes=c_nodes, active=c_active,
                    statuses=("usable", "usable", "absent", "absent"), calls=3))
    pts.append(dict(name="x-three-calls-stale-active", nodes=c_nodes, active="ghost-99",
                    statuses=("usable",) * 4, calls=3))
    # BC-24 — `sing-box check` failure path
    pts.append(dict(name="x-check-fails", nodes=c_nodes, active=c_active,
                    statuses=("usable",) * 4, sb_bin="/bin/false"))
    pts.append(dict(name="x-check-fails-degraded", nodes=c_nodes, active=c_active,
                    statuses=("absent", "usable", "absent", "usable"),
                    sb_bin="/bin/false"))
    return pts


def observe(sc, pt, lang):
    """Wipe, re-seed at the SAME path, run, and collect everything observable."""
    wipe()
    if pt.get("rules_dir"):
        seed(pt["nodes"], pt["active"], pt["statuses"], lang=lang,
             rules_dir=pt["rules_dir"])
    else:
        seed(pt["nodes"], pt["active"], pt["statuses"], lang=lang)
    repoint(sc, rules_dir=pt.get("rules_dir"), lang=lang,
            clash_port=pt.get("clash_port", 29090),
            sb_bin=pt.get("sb_bin", "/bin/true"))
    res = run_generate(sc, calls=pt.get("calls", 1))
    return {
        "config": [r.config for r in res],
        "nodes": [r.nodes for r in res],
        "rv": [r.rv for r in res],
        "err": [r.err for r in res],
        "exc": [r.exc for r in res],
        "files": file_list(),
    }


def firstdiff(a, b):
    if a is None or b is None:
        return "one side is None (%r / %r)" % (a is None, b is None)
    la = a.decode("utf-8", "replace").splitlines()
    lb = b.decode("utf-8", "replace").splitlines()
    for i in range(max(len(la), len(lb))):
        x = la[i] if i < len(la) else "<eof>"
        y = lb[i] if i < len(lb) else "<eof>"
        if x != y:
            return "line %d\n      baseline : %s\n      candidate: %s" % (i + 1, x, y)
    return "identical text, different bytes (len %d vs %d)" % (len(a), len(b))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--baseline", required=True)
    ap.add_argument("--candidate", required=True)
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    base = load_module(args.baseline, "sc_base")
    cand = load_module(args.candidate, "sc_cand")

    pts = points()
    mismatches = []
    n = 0
    for pt in pts:
        for lang in ("en", "zh"):
            n += 1
            b = observe(base, pt, lang)
            c = observe(cand, pt, lang)
            tag = "%-32s [%s]" % (pt["name"], lang)
            if b["exc"] != [None] * len(b["exc"]) or c["exc"] != [None] * len(c["exc"]):
                mismatches.append((tag, "exception", "base=%r cand=%r"
                                   % (b["exc"], c["exc"])))
                continue
            # Per CALL: config bytes, nodes.json bytes, stderr, return value.
            for i in range(len(b["config"])):
                if b["config"][i] != c["config"][i]:
                    mismatches.append((tag, "config call%d" % (i + 1),
                                       firstdiff(b["config"][i], c["config"][i])))
                if b["nodes"][i] != c["nodes"][i]:
                    mismatches.append((tag, "nodes call%d" % (i + 1),
                                       firstdiff(b["nodes"][i], c["nodes"][i])))
                if b["err"][i] != c["err"][i]:
                    mismatches.append((tag, "stderr call%d" % (i + 1),
                                       "baseline : %r\n      candidate: %r"
                                       % (b["err"][i], c["err"][i])))
                if b["rv"][i] != c["rv"][i]:
                    mismatches.append((tag, "return call%d" % (i + 1),
                                       "base=%r cand=%r" % (b["rv"][i], c["rv"][i])))
            # AC-11 on the candidate itself: every call in the run produced the same
            # bytes as the first (BC-20 — the base template must not be mutated).
            for i in range(1, len(c["config"])):
                if c["config"][i] != c["config"][0]:
                    mismatches.append((tag, "AC-11 self call%d" % (i + 1),
                                       firstdiff(c["config"][0], c["config"][i])))
            extra = set(c["files"]) - set(b["files"])
            missing = set(b["files"]) - set(c["files"])
            if extra != {".config.sha256"} or missing:
                mismatches.append((tag, "fixture tree",
                                   "extra=%r missing=%r" % (sorted(extra),
                                                            sorted(missing))))
    print("compared %d differential runs (%d points x 2 languages)" % (n, len(pts)))
    if mismatches:
        print("RESULT: FAIL — %d mismatch(es)" % len(mismatches))
        for tag, what, detail in mismatches[:12]:
            print("  %s %-14s\n      %s" % (tag, what, detail))
        if len(mismatches) > 12:
            print("  ... %d more" % (len(mismatches) - 12))
        return 1
    print("RESULT: PASS — byte-identical config, stderr (all calls), return value "
          "and nodes.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

### `qa_mutants.py`

```python
#!/usr/bin/env python3
"""AC-4 non-vacuity: build mutants of the CANDIDATE, one broken fact each.

A green differential from a harness never shown to fail proves nothing. Six mutants,
covering every fact the differential claims to compare:
  M1 an emitted VALUE          M2 a pure KEY REORDER (no value changes)  -- R-1's case
  M3 an ARRAY ELEMENT REORDER  M4 stderr only (document untouched)
  M5 nodes.json only           M6 the boolean RETURN value only
"""
import os
import sys
from pathlib import Path

SRC = Path("/home/alan/Programs/singbox-cli/bin/sc")
OUT = Path(__file__).resolve().parent / "mutants"

MUTATIONS = {
    "m1_value": [
        ('"log": {"level": "warn", "timestamp": True},',
         '"log": {"level": "warns", "timestamp": True},'),
    ],
    "m2_key_reorder": [
        ('        "final": "remote_dns",\n        "independent_cache": True,\n',
         '        "independent_cache": True,\n        "final": "remote_dns",\n'),
    ],
    "m3_array_reorder": [
        ('            {"outbound": "direct", "rule_set": ["geoip-cn"]},\n'
         '            {"outbound": "direct", "rule_set": ["geosite-cn"]},\n',
         '            {"outbound": "direct", "rule_set": ["geosite-cn"]},\n'
         '            {"outbound": "direct", "rule_set": ["geoip-cn"]},\n'),
    ],
    "m4_stderr_only": [
        ('sys.stderr.write("⚠️  " + msg + "\\n")',
         'sys.stderr.write("⚠️ " + msg + "\\n")'),
    ],
    "m5_nodes_only": [
        ('        nodes_data["active"] = active\n        save_nodes(nodes_data)',
         '        nodes_data["active"] = active\n'
         '        nodes_data["qa_marker"] = 1\n        save_nodes(nodes_data)'),
    ],
    "m6_return_only": [
        ('    r = subprocess.run([SB_BIN, "check", "-c", str(CFG_PATH)],\n'
         '                       capture_output=True, text=True)\n'
         '    if r.returncode != 0:',
         '    r = subprocess.run([SB_BIN, "check", "-c", str(CFG_PATH)],\n'
         '                       capture_output=True, text=True)\n'
         '    if False and r.returncode != 0:'),
    ],
}


def main():
    OUT.mkdir(exist_ok=True)
    text = SRC.read_text()
    for name, subs in MUTATIONS.items():
        out = text
        for old, new in subs:
            count = out.count(old)
            assert count == 1, "%s: anchor matched %d times" % (name, count)
            out = out.replace(old, new)
        assert out != text
        p = OUT / (name + ".py")
        p.write_text(out)
        print("wrote %s" % p)


if __name__ == "__main__":
    main()
```

### `qa_semantics.py`

```python
#!/usr/bin/env python3
"""T-14 QA — everything the differential cannot see (AC-5 … AC-30, BC-7 … BC-26).

Independently derived from 01's acceptance criteria. Drives the CANDIDATE only.
"""
import ast
import io
import json
import os
import re
import signal
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qa_common import (ALT_RULES, PARENT, ROOT, RULESET_FILENAMES, file_list,
                       load_module, node, repoint, run_generate, seed,
                       tree_snapshot, wipe, witness)

CAND_SRC = Path("/home/alan/Programs/singbox-cli/bin/sc")
BASE_SRC = Path(__file__).resolve().parent / "pristine" / "bin" / "sc"

RESULTS = []
FAILED = []


def ok(cond, label, detail=""):
    RESULTS.append((bool(cond), label, detail))
    if not cond:
        FAILED.append((label, detail))
    return bool(cond)


def note(label, detail):
    RESULTS.append((None, label, detail))


N3 = [node("tokyo-01"), node("osaka-02"), node("sg-03")]
ALL_USABLE = ("usable",) * 4


# ================================================================= plumbing
def gen(sc, override=None, nodes=N3, active="osaka-02", statuses=ALL_USABLE,
        lang="en", calls=1, config_bytes=None, state_bytes=None, sb_bin="/bin/true",
        seed_override=True):
    wipe()
    seed(nodes, active, statuses, lang=lang,
         override=override if seed_override else None,
         config_bytes=config_bytes, state_bytes=state_bytes)
    repoint(sc, lang=lang, sb_bin=sb_bin)
    return run_generate(sc, calls=calls)


def doc_of(sc):
    return json.loads(sc.CFG_PATH.read_text())


class Spy(object):
    def __init__(self):
        self.calls = []

    def __call__(self, *a, **k):
        self.calls.append((a, k))


def drive_main(sc, argv, lang="en", running=False):
    """Run main() with argv. _init_files() is NEVER driven (it hard-codes /var/lib)."""
    real_init, real_port = sc._init_files, sc._resolve_clash_port
    real_restart, real_running = sc.restart_service, sc.is_running
    restart_spy = Spy()
    sc._init_files = lambda: None
    sc._resolve_clash_port = lambda: 29090
    sc.restart_service = restart_spy
    sc.is_running = (lambda: True) if running else (lambda: False)
    out, err = io.StringIO(), io.StringIO()
    o_out, o_err, o_argv = sys.stdout, sys.stderr, sys.argv
    sys.stdout, sys.stderr, sys.argv = out, err, ["sc"] + argv
    code, exc = None, None
    try:
        try:
            sc.main()
            code = 0
        except SystemExit as e:
            code = e.code
        except BaseException as e:                  # noqa: BLE001
            exc = "%s: %s" % (type(e).__name__, e)
    finally:
        sys.stdout, sys.stderr, sys.argv = o_out, o_err, o_argv
        sc._init_files, sc._resolve_clash_port = real_init, real_port
        sc.restart_service, sc.is_running = real_restart, real_running
    return dict(code=code, out=out.getvalue(), err=err.getvalue(), exc=exc,
                restarts=len(restart_spy.calls))


SENTINEL = b'{\n  "qa": "hand written config, must survive"\n}'


def malformed_case(sc, name, override, lang="en", pre_state=None, setup=None):
    """One malformed-override case, driven through main()'s `reload` handler."""
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, lang=lang, config_bytes=SENTINEL,
         state_bytes=pre_state)
    repoint(sc, lang=lang)
    if setup:
        setup(sc)
    else:
        p = ROOT / "override.json"
        if isinstance(override, bytes):
            p.write_bytes(override)
        else:
            p.write_text(override)
    before = tree_snapshot()
    r = drive_main(sc, ["reload"], lang=lang)
    after = tree_snapshot()
    line = r["code"] if isinstance(r["code"], str) else ""
    prefix = "无法使用 " if lang == "zh" else "Cannot use "
    problems = []
    if r["exc"]:
        problems.append("raised %s" % r["exc"])
    if not isinstance(r["code"], str):
        problems.append("exit code was %r, not a message string" % (r["code"],))
    if after.get("config.json", (None,))[0] != SENTINEL:
        problems.append("config.json was modified")
    if r["restarts"]:
        problems.append("restart_service called %d times" % r["restarts"])
    if not line.startswith(prefix):
        problems.append("message does not start with %r: %r" % (prefix, line[:80]))
    if str(sc.OVERRIDE_PATH) not in line:
        problems.append("message does not name the override path")
    for bad, tag in (("\n", "LF"), ("\r", "CR"), ("\x1b", "ESC")):
        if bad in line:
            problems.append("message contains %s" % tag)
    if "失败：" in line:
        problems.append("message contains the 失败： grep marker")
    # the drift record must not have been created or altered
    if after.get(".config.sha256") != before.get(".config.sha256"):
        problems.append("drift record changed")
    ok(not problems, "AC-20/21 [%s] %s" % (lang, name),
       "; ".join(problems) + " | line=%r" % line[:160])
    return line


# ================================================================= AC-5 … AC-12
def structure(cand, base):
    src = CAND_SRC.read_text()
    tree = ast.parse(src)
    top = {n.targets[0].id: n for n in tree.body
           if isinstance(n, ast.Assign) and len(n.targets) == 1
           and isinstance(n.targets[0], ast.Name)}
    # AC-5
    ok("CONFIG_BASE" in top and isinstance(top["CONFIG_BASE"].value, ast.Dict),
       "AC-5 CONFIG_BASE is a module-level dict literal")
    fn = [n for n in tree.body if isinstance(n, ast.FunctionDef)
          and n.name == "generate_config"][0]
    lits = set()
    for n in ast.walk(fn):
        if isinstance(n, ast.Dict) and len(n.keys) >= 3:
            lits.add(ast.dump(n)[:60])
    ok(not lits, "AC-5 no configuration literal remains inside generate_config()",
       repr(sorted(lits)))
    ok(isinstance(cand.CONFIG_BASE, dict) and set(cand.CONFIG_BASE) ==
       {"log", "dns", "inbounds", "outbounds", "route", "experimental"},
       "AC-5 CONFIG_BASE top-level keys", repr(list(cand.CONFIG_BASE)))
    # AC-6 — exactly one merge implementation
    merges = [n.name for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)
              and n.name in ("_merge",)]
    ok(merges == ["_merge"], "AC-6 exactly one _merge definition", repr(merges))
    # AC-6 deletion test: with the run-time overlay's call site removed, the user
    # override still composes through the very same _merge.
    doc = cand._compose([{"log": {"level": "debug"}}])
    ok(doc["log"] == {"level": "debug", "timestamp": True} and doc["outbounds"] == [],
       "AC-6 deletion test: override composes with no run-time overlay", repr(doc["log"]))
    # AC-7 — single file, stdlib only
    imports = set()
    for n in ast.walk(tree):
        if isinstance(n, ast.Import):
            imports |= {a.name.split(".")[0] for a in n.names}
        elif isinstance(n, ast.ImportFrom) and n.level == 0 and n.module:
            imports.add(n.module.split(".")[0])
    stdlib = {"argparse", "base64", "hashlib", "json", "os", "shutil", "socket",
              "subprocess", "sys", "tempfile", "time", "urllib", "pathlib", "copy",
              "stat", "types", "datetime", "re", "textwrap", "errno", "signal"}
    ok(imports <= stdlib, "AC-7 stdlib-only imports", repr(sorted(imports - stdlib)))
    inst_now = subprocess.run(["git", "-C", "/home/alan/Programs/singbox-cli", "diff",
                               "--stat", "--", "install.sh"], stdout=subprocess.PIPE,
                              text=True).stdout
    ok(inst_now.strip() == "", "AC-7 install.sh untouched", inst_now)
    # AC-8 — _filter_rules identical to the baseline, two call sites, no new parameter
    def extract(text, name):
        t = ast.parse(text)
        for n in ast.walk(t):
            if isinstance(n, ast.FunctionDef) and n.name == name:
                return ast.dump(n)
        return None
    ok(extract(src, "_filter_rules") == extract(BASE_SRC.read_text(), "_filter_rules"),
       "AC-8 _filter_rules is byte-for-byte the same function as the baseline")
    ok([a.arg for a in [n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)
                        and n.name == "_filter_rules"][0].args.args] ==
       ["rules", "usable"], "AC-8 _filter_rules gained no array-name parameter")
    sites = [n for n in ast.walk(tree) if isinstance(n, ast.Call)
             and isinstance(n.func, ast.Name) and n.func.id == "_filter_rules"]
    ok(len(sites) == 2, "AC-8 exactly two _filter_rules call sites", str(len(sites)))
    # AC-10 — sole writer of config.json
    grep = subprocess.run(["grep", "-rn", "CFG_PATH", "/home/alan/Programs/singbox-cli/bin/sc"],
                          stdout=subprocess.PIPE, text=True).stdout
    writers = [ln for ln in grep.splitlines()
               if re.search(r"(write_text|open\([^)]*[\"']w|\.write\()", ln)]
    ok(not writers, "AC-10 no write path to CFG_PATH other than _write_private",
       repr(writers))
    ok(src.count("_write_private(CFG_PATH") == 1,
       "AC-10 exactly one _write_private(CFG_PATH, …) call site")
    # NFR-3 — 3.6 floor: no walrus, no new capture_output=
    ok(not any(isinstance(n, getattr(ast, "NamedExpr", ())) for n in ast.walk(tree)),
       "NFR-3 no walrus operator")
    ok(src.count("capture_output=") == BASE_SRC.read_text().count("capture_output="),
       "NFR-3 no new capture_output= site (3 pre-existing, separate pool row)")
    ok("dataclass" not in src and "missing_ok=" not in src,
       "NFR-3 no dataclasses / unlink(missing_ok=)")


# ================================================================= AC-9 ordering
def ordering(cand):
    trace = []
    real = dict(wd=cand._warn_degraded, wdr=cand._warn_drift,
                wp=cand._write_private, rec=cand._record_generated,
                run=cand.subprocess.run)
    cand._warn_degraded = lambda r: (trace.append("warn_degraded"), real["wd"](r))[1]
    cand._warn_drift = lambda: (trace.append("warn_drift"), real["wdr"]())[1]
    cand._write_private = lambda p, t: (trace.append("write:" + p.name),
                                        real["wp"](p, t))[1]
    cand._record_generated = lambda: (trace.append("record"), real["rec"]())[1]
    cand.subprocess.run = lambda *a, **k: (trace.append("check"), real["run"](*a, **k))[1]
    try:
        gen(cand, statuses=("usable", "absent", "usable", "absent"))
        ok(trace == ["warn_degraded", "warn_drift", "write:config.json", "record",
                     "write:.config.sha256", "check"],
           "AC-9 observable ordering: degrade → drift → write config → record "
           "→ check", repr(trace))
    finally:
        cand._warn_degraded, cand._warn_drift = real["wd"], real["wdr"]
        cand._write_private, cand._record_generated = real["wp"], real["rec"]
        cand.subprocess.run = real["run"]


# ================================================================= AC-13 … AC-19
def override_semantics(cand):
    base = json.loads(json.dumps(cand.CONFIG_BASE))

    # AC-13 deep merge: siblings AND positions survive
    gen(cand, override='{"log": {"level": "debug"}}')
    d = doc_of(cand)
    ok(d["log"] == {"level": "debug", "timestamp": True}
       and list(d["log"]) == ["level", "timestamp"],
       "AC-13 deep merge keeps sibling and position", repr(d["log"]))
    ok(list(d) == ["log", "dns", "inbounds", "outbounds", "route", "experimental"],
       "AC-13 top-level key order unchanged by an override", repr(list(d)))

    # a key the base does not have is added, at the end of its object
    gen(cand, override='{"log": {"output": "/tmp/x.log"}}')
    d = doc_of(cand)
    ok(list(d["log"]) == ["level", "timestamp", "output"],
       "AC-13 a new key is appended, existing ones do not move", repr(list(d["log"])))

    # AC-14 $replace
    gen(cand, override='{"dns": {"rules": {"$replace": [{"server": "only"}]}}}')
    d = doc_of(cand)
    ok(d["dns"]["rules"] == [{"server": "only"}], "AC-14 $replace yields exactly the "
       "override's array", repr(d["dns"]["rules"]))
    ok(list(d["dns"]) == list(base["dns"]),
       "AC-14 $replace does not move the key", repr(list(d["dns"])))

    # AC-15 $prepend / $append on route.rules
    gen(cand, override=json.dumps({"route": {"rules": {"$prepend": [{"action": "P"}]}}}))
    d = doc_of(cand)
    ok(d["route"]["rules"][0] == {"action": "P"}
       and d["route"]["rules"][1:] == base["route"]["rules"],
       "AC-15 $prepend puts the element first, base order intact")
    gen(cand, override=json.dumps({"route": {"rules": {"$append": [{"action": "A"}]}}}))
    d = doc_of(cand)
    ok(d["route"]["rules"][-1] == {"action": "A"}
       and d["route"]["rules"][:-1] == base["route"]["rules"],
       "AC-15 $append puts the element last, base order intact")

    # AC-16 anchored insertion — the T-16/T-17 shape
    ov = {"dns": {"rules": {"$after": {"match": {"clash_mode": "Direct"},
                                       "values": [{"action": "reject", "qa": 1}]}}}}
    gen(cand, override=json.dumps(ov))
    d = doc_of(cand)
    rules = d["dns"]["rules"]
    anchor_i = [i for i, r in enumerate(rules) if r.get("clash_mode") == "Direct"][0]
    ok(rules[anchor_i + 1] == {"action": "reject", "qa": 1},
       "AC-16 $after inserts immediately after the anchor", repr(rules[anchor_i:anchor_i + 2]))
    ok([r for r in rules if r != {"action": "reject", "qa": 1}] == base["dns"]["rules"],
       "AC-16 every other element keeps its relative order")
    ov["dns"]["rules"] = {"$before": ov["dns"]["rules"]["$after"]}
    gen(cand, override=json.dumps(ov))
    rules = doc_of(cand)["dns"]["rules"]
    anchor_i = [i for i, r in enumerate(rules) if r.get("clash_mode") == "Direct"][0]
    ok(rules[anchor_i - 1] == {"action": "reject", "qa": 1},
       "AC-16 $before inserts immediately before the anchor")

    # AC-17 two overlays compose, each at its own anchor, no index arithmetic
    a = {"dns": {"rules": {"$after": {"match": {"clash_mode": "Direct"},
                                      "values": [{"tag": "A"}]}}}}
    b = {"dns": {"rules": {"$after": {"match": {"clash_mode": "Global"},
                                      "values": [{"tag": "B"}]}}}}
    doc = cand._compose([cand._runtime_overlay([], None, []), a, b])
    tags = [r.get("tag") or r.get("clash_mode") or "-" for r in doc["dns"]["rules"]]
    ok("A" in tags and "B" in tags
       and tags.index("B") == tags.index("Global") + 1
       and tags.index("A") == tags.index("Direct") + 1,
       "AC-17 two overlays each land at their own anchor", repr(tags))
    doc2 = cand._compose([cand._runtime_overlay([], None, []), b, a])
    tags2 = [r.get("tag") or r.get("clash_mode") or "-" for r in doc2["dns"]["rules"]]
    ok(tags2 == tags, "AC-17 the RESULT is independent of the order the two overlays "
       "are applied in (no index arithmetic against the base)",
       "%r vs %r" % (tags2, tags))

    # AC-18 an inserted value is copied verbatim, nested keys never interpreted
    hostile = {"outbound": "direct", "rule_set": ["geosite-cn"],
               "domain_suffix": ["a.com", "b.com"],
               "$append": ["this is DATA, not a directive"],
               "$before": {"match": {"outbound": "direct"}, "values": []},
               "nested": {"$replace": [1, 2, 3], "deep": [{"$patch": 1}]}}
    ov = {"route": {"rules": {"$append": [hostile]}}}
    # through _compose alone (no _filter_rules): must be verbatim
    got = cand._compose([cand._runtime_overlay([], None, []),
                         json.loads(json.dumps(ov))])["route"]["rules"][-1]
    ok(got == hostile, "AC-18 inserted value copied verbatim by _compose, incl. two "
       "literal $ keys and a nested $ key", repr(got))
    # and end-to-end, with the referenced rule-set defined so _filter_rules keeps it
    gen(cand, override=json.dumps(ov), statuses=ALL_USABLE)
    got = doc_of(cand)["route"]["rules"][-1]
    ok(got == hostile, "AC-18 inserted value emitted verbatim end-to-end", repr(got))
    # boundary (05 §9 O-5): the vocabulary cannot reach INSIDE an array element
    try:
        cand._compose([{"route": {"rules": {"$after": {
            "match": {"clash_mode": "Direct"},
            "values": [{"x": 1}]}}}, "dns": {"rules": {"0": {"server": "z"}}}}])
        note("O-5 vocabulary boundary", "no error for an index-like key")
    except cand.OverrideError as e:
        note("O-5 vocabulary boundary CONFIRMED: no way to modify a value nested "
             "inside an array element", str(e))

    # AC-19 bare array rules
    gen(cand, override=json.dumps({"newthing": [1, 2, 3]}))
    ok(doc_of(cand).get("newthing") == [1, 2, 3],
       "AC-19 bare array at a key absent from the base is accepted (D-6)")
    try:
        cand._compose([{"dns": {"rules": [{"server": "x"}]}}])
        ok(False, "AC-19 bare array over an existing array is rejected")
    except cand.OverrideError as e:
        msg = str(e)
        ok(all(d in msg for d in ("$prepend", "$append", "$replace")),
           "AC-19 the rejection names $prepend / $append / $replace", msg)
        ok("(" not in msg.split("one of")[-1][:4],
           "C-6 {directives} renders as a readable list, not a tuple repr", msg)

    # A-7 — a user-defined rule-set is NOT silently stripped from the rule arrays
    ov = {"route": {"rule_set": {"$append": [{"tag": "qa-set", "type": "local",
                                             "format": "binary", "path": "/x.srs"}]},
                    "rules": {"$append": [{"outbound": "direct",
                                           "rule_set": ["qa-set"]}]}}}
    gen(cand, override=json.dumps(ov), statuses=("absent",) * 4)
    d = doc_of(cand)
    ok(any(r.get("rule_set") == ["qa-set"] for r in d["route"]["rules"]),
       "A-7 a rule referencing a USER-defined rule-set survives _filter_rules")
    ok([s["tag"] for s in d["route"]["rule_set"]] == ["qa-set"],
       "A-7 the user's rule_set definition survives with all four files unusable")


# ================================================================= BC-7 / T-1
def empty_and_absent(cand):
    gen(cand, override=None)
    absent_bytes = cand.CFG_PATH.read_bytes()
    for label, content in (("{}", "{}"), ("whitespace-only", "   \n\t \n"),
                           ("zero-byte", ""), ("BOM+ws", "﻿  ")):
        res = gen(cand, override=content)[0]
        same = (cand.CFG_PATH.exists()
                and cand.CFG_PATH.read_bytes() == absent_bytes)
        if label == "BOM+ws":
            note("BC-7 U+FEFF BOM + whitespace override",
                 "identical to absent" if same else
                 "treated as MALFORMED (%s) — str.strip() does not strip U+FEFF"
                 % res.exc)
            continue
        ok(same, "BC-7/T-1 %s override is identical to absent" % label,
           str(res.exc))
    for label, content in (("[]", "[]"), ("null", "null"), ("0", "0"),
                           ('"{"', "{"), ('"true"', "true"), ('string', '"hi"')):
        res = gen(cand, override=content)[0]
        ok(res.exc is not None and res.exc.startswith("OverrideError"),
           "BC-7/T-1 %s override stays MALFORMED" % label, str(res.exc))
        ok(not cand.CFG_PATH.exists(),
           "BC-7/T-1 %s override wrote no config.json" % label)


# ================================================================= AC-22 … AC-25
def drift(cand):
    # AC-24 — no record at all (every host upgrading from a pre-T-14 build)
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, config_bytes=SENTINEL)
    repoint(cand)
    ok(not cand.STATE_PATH.exists(), "AC-24 fixture starts with no drift record")
    r = run_generate(cand)[0]
    ok("modified outside" not in r.err and "曾被" not in r.err,
       "AC-24 absent record ⇒ silent (BC-16, D-4)", repr(r.err))
    ok(cand.STATE_PATH.exists(), "AC-24 the run creates the record")
    rec = cand.STATE_PATH.read_bytes()
    ok(re.match(rb"^[0-9a-f]{64}\n$", rec) is not None,
       "AC-25 record is exactly a 64-hex digest + newline", repr(rec))
    ok(oct(cand.STATE_PATH.stat().st_mode)[-3:] == "600",
       "AC-25 record is mode 0600", oct(cand.STATE_PATH.stat().st_mode))
    cfg = cand.CFG_PATH.read_bytes()
    ok(b"11111111-2222" not in rec and rec.strip().decode() ==
       __import__("hashlib").sha256(cfg).hexdigest(),
       "AC-25 record holds no credential bytes and is sha256(config.json on disk)")

    # AC-23 — unchanged ⇒ silent
    r = run_generate(cand)[0]
    ok("modified outside" not in r.err, "AC-23 byte-identical config ⇒ no drift line",
       repr(r.err))

    # AC-22 — hand-edit, then regenerate
    cand.CFG_PATH.write_bytes(cand.CFG_PATH.read_bytes() + b"\n// hand edit\n")
    edited = cand.CFG_PATH.read_bytes()
    seen = {}
    real_wp = cand._write_private

    def spy(p, t):
        if p.name == "config.json":
            seen["stderr_at_write"] = sys.stderr.getvalue()
            seen["on_disk_at_write"] = p.read_bytes()
        return real_wp(p, t)
    cand._write_private = spy
    try:
        r = run_generate(cand)[0]
    finally:
        cand._write_private = real_wp
    ok(r.err.count("modified outside") == 1,
       "AC-22 exactly one drift line", repr(r.err))
    ok("modified outside" in seen.get("stderr_at_write", ""),
       "AC-22 the drift line is emitted BEFORE the file is replaced")
    ok(seen.get("on_disk_at_write") == edited,
       "AC-22 the hand-edited file was still on disk when the line was written")
    ok(str(cand.OVERRIDE_PATH) in r.err and str(cand.CFG_PATH) in r.err,
       "AC-22 the drift line names both config.json and override.json", repr(r.err))
    ok(r.err.count("\n") == 1 and "\r" not in r.err and "\x1b" not in r.err,
       "NFR-7 the drift line is ONE physical line", repr(r.err))
    ok(cand.CFG_PATH.read_bytes() != edited, "AC-22 generation proceeded (not blocked)")
    r = run_generate(cand)[0]
    ok("modified outside" not in r.err, "AC-22 the drift line clears on the next run")

    # zh rendering, driven through main() with settings.json pinned (O-4's trap)
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, lang="zh", config_bytes=SENTINEL,
         state_bytes=b"0" * 64 + b"\n")
    repoint(cand, lang="zh")
    r = drive_main(cand, ["reload"], lang="zh")
    ok("曾被 sc 以外的方式修改" in r["err"],
       "AC-22 zh drift line renders Chinese through main()", repr(r["err"][:200]))
    ok("失败：" not in r["err"], "AC-27 zh drift line has no 失败： marker")

    # corrupt records — must degrade to "unknown", never traceback
    for label, blob in (("invalid UTF-8", b"\xff\xfe\x00garbage"),
                        ("empty", b""), ("whitespace", b"   \n"),
                        ("wrong length hex", b"deadbeef\n"),
                        ("huge", b"a" * 200000),
                        ("binary NULs", b"\x00" * 65)):
        wipe()
        seed(N3, "osaka-02", ALL_USABLE, config_bytes=SENTINEL, state_bytes=blob)
        repoint(cand)
        res = run_generate(cand)[0]
        ok(res.exc is None, "corrupt drift record (%s) does not raise" % label,
           str(res.exc))
        if label in ("empty", "whitespace", "invalid UTF-8"):
            ok("modified outside" not in res.err,
               "corrupt drift record (%s) ⇒ silent (unknown)" % label, repr(res.err))
        else:
            ok("modified outside" in res.err,
               "non-matching drift record (%s) ⇒ warns" % label, repr(res.err))
        ok(re.match(rb"^[0-9a-f]{64}\n$", cand.STATE_PATH.read_bytes()) is not None,
           "corrupt drift record (%s) is repaired by the run" % label)

    # STATE_PATH is a directory — _write_private must not explode
    wipe()
    seed(N3, "osaka-02", ALL_USABLE)
    repoint(cand)
    (ROOT / ".config.sha256").mkdir()
    res = run_generate(cand)[0]
    ok(res.exc is None and res.rv is True,
       "drift record path is a DIRECTORY ⇒ best-effort, no crash", str(res.exc))

    # BC-17 — config.json absent
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, state_bytes=b"a" * 64 + b"\n")
    repoint(cand)
    res = run_generate(cand)[0]
    ok("modified outside" not in res.err,
       "BC-17 config.json absent ⇒ no drift line", repr(res.err))

    # generate → hand-edit → generate → hand-edit → generate
    wipe()
    seed(N3, "osaka-02", ALL_USABLE)
    repoint(cand)
    warns = []
    for i in range(3):
        res = run_generate(cand)[0]
        warns.append("modified outside" in res.err)
        cand.CFG_PATH.write_bytes(cand.CFG_PATH.read_bytes() + b"x")
    ok(warns == [False, True, True],
       "sequence generate→edit→generate→edit→generate warns on 2nd and 3rd", repr(warns))


# ================================================================= AC-26
def doctor(cand):
    wipe()
    seed(N3, "osaka-02", ("usable", "absent", "bad-magic", "too-small"), lang="en",
         override='{"dns": {"rules": [ this is not json ]}}',
         config_bytes=SENTINEL)
    repoint(cand)
    real_egress = cand._egress_ip
    cand._egress_ip = lambda: None          # stay offline
    before = tree_snapshot()
    try:
        r = drive_main(cand, ["doctor"])
    finally:
        cand._egress_ip = real_egress
    after = tree_snapshot()
    ok(before == after, "AC-26 sc doctor leaves the fixture byte-AND-mode identical",
       repr(sorted(set(after) ^ set(before))) + " changed=" +
       repr([k for k in before if k in after and before[k] != after[k]]))
    ok(not (ROOT / ".config.sha256").exists(),
       "AC-26 sc doctor creates no drift record")
    ok(r["exc"] is None, "AC-26 sc doctor with a malformed override does not raise",
       str(r["exc"]))
    ok(len(r["out"]) > 200, "AC-26 sc doctor still produced a report",
       str(len(r["out"])))
    ok("Cannot use" not in r["out"] and "Cannot use" not in r["err"],
       "BC-26 sc doctor never reads the override")


# ================================================================= AC-27 / AC-28
def i18n(cand):
    src = CAND_SRC.read_text()
    tree = ast.parse(src)
    keys = set()
    DYNAMIC = []
    for n in ast.walk(tree):
        if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id == "t":
            if n.args and isinstance(n.args[0], ast.Str):
                keys.add(n.args[0].s)
            elif n.args and isinstance(n.args[0], ast.Constant) \
                    and isinstance(n.args[0].value, str):
                keys.add(n.args[0].value)
            else:
                DYNAMIC.append(ast.dump(n.args[0])[:60] if n.args else "no args")
    base_keys = set()
    btree = ast.parse(BASE_SRC.read_text())
    for n in ast.walk(btree):
        if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id == "t":
            if n.args and isinstance(n.args[0], ast.Constant) \
                    and isinstance(n.args[0].value, str):
                base_keys.add(n.args[0].value)
    new = sorted(keys - base_keys)
    zh = cand.TRANSLATIONS["zh"]
    ok(len(new) == 17, "AC-27 exactly 17 new t() keys (as designed)",
       "%d: %r" % (len(new), new))
    for k in new:
        ok(k in zh, "AC-27 new key present in zh table: %r" % k[:50])
        if k in zh:
            ph_en = set(re.findall(r"\{(\w+)\}", k))
            ph_zh = set(re.findall(r"\{(\w+)\}", zh[k]))
            ok(ph_en == ph_zh, "AC-27 placeholder set matches for %r" % k[:40],
               "%r vs %r" % (sorted(ph_en), sorted(ph_zh)))
            ok("失败：" not in zh[k], "AC-27 no 失败： in zh for %r" % k[:40])
        cjk = [c for c in k if "一" <= c <= "鿿"
               or "　" <= c <= "〿" or "＀" <= c <= "￯"]
        ok(not cjk and " " in k,
           "AC-28 key is readable English prose: %r" % k[:50], repr(cjk))
        ok(not re.match(r"^[a-z0-9_]+(\.[a-z0-9_]+)+$", k),
           "AC-28 no namespaced key: %r" % k[:40])
    # no PRE-EXISTING zh entry regressed out of the table
    bmod = load_module(str(BASE_SRC), "sc_base_i18n")
    bzh = bmod.TRANSLATIONS["zh"]
    lost = sorted(k for k in bzh if k not in zh)
    ok(not lost, "AC-27 no pre-existing zh entry was lost", repr(lost[:3]))
    note("AC-27 dynamic t() call sites (pre-existing, doctor's row renderer)",
         repr(DYNAMIC))
    ok(len(DYNAMIC) == 2, "AC-27 no NEW dynamic t() call site was added "
       "(2 pre-existing at bin/sc:1996)", repr(DYNAMIC))
    return new


# ================================================================= main
def main():
    witness("start")
    cand = load_module(str(CAND_SRC), "sc_cand")
    base = load_module(str(BASE_SRC), "sc_base")
    structure(cand, base)
    ordering(cand)
    override_semantics(cand)
    empty_and_absent(cand)
    drift(cand)
    doctor(cand)
    i18n(cand)
    witness("end")

    npass = sum(1 for r, _, _ in RESULTS if r is True)
    nfail = sum(1 for r, _, _ in RESULTS if r is False)
    nnote = sum(1 for r, _, _ in RESULTS if r is None)
    for r, label, detail in RESULTS:
        mark = {True: "ok  ", False: "FAIL", None: "note"}[r]
        print("%s %s%s" % (mark, label, ("   -- " + detail) if r is not True and detail
                                        else ""))
    print("\n%d ok, %d FAILED, %d notes" % (npass, nfail, nnote))
    return 1 if nfail else 0


if __name__ == "__main__":
    sys.exit(main())
```

### `qa_errors.py`

```python
#!/usr/bin/env python3
"""T-14 QA — AC-20 / AC-21 / BC-8 … BC-14 / NFR-7, driven through main()'s `reload`.

Every case asserts, independently of the developer's harness:
  * config.json is BYTE-IDENTICAL afterwards (a sentinel hand-written document)
  * the command exits non-zero, with a message (SystemExit carrying a str => status 1)
  * the message names the override path AND the specific problem
  * the message is ONE physical line: no \\n, no \\r, no ESC
  * restart_service() was never called (no service-affecting action)
  * the drift record was neither created nor changed
and runs the whole set in BOTH languages, with settings.json's `lang` pinned
(main() reassigns LANG from _load_lang(), so setting sc.LANG alone renders English).
"""
import json
import os
import signal
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qa_common import ROOT, load_module, node, repoint, seed, tree_snapshot, wipe, witness
import qa_semantics as S
from qa_semantics import (ALL_USABLE, FAILED, N3, RESULTS, SENTINEL, drive_main,
                          malformed_case, note, ok)

CAND = Path("/home/alan/Programs/singbox-cli/bin/sc")

BIG = json.dumps({"x": "y" * (1024 * 1024 + 64)})
DEEP = '{"a":' * 40000 + "1" + "}" * 40000


def _mk(kind):
    """setup callables for the non-regular-file / permission cases."""
    def inner(sc):
        p = ROOT / "override.json"
        if kind == "dir":
            p.mkdir()
        elif kind == "fifo":
            os.mkfifo(str(p))
        elif kind == "unreadable":
            p.write_text('{"log": {"level": "debug"}}')
            os.chmod(str(p), 0o000)
        elif kind == "symlink-to-fifo":
            fifo = ROOT / "target.fifo"
            os.mkfifo(str(fifo))
            p.symlink_to(fifo)
        elif kind == "dangling-symlink":
            p.symlink_to(ROOT / "nowhere.json")
        elif kind == "symlink-loop":
            os.symlink(str(ROOT / "b.json"), str(p))
            os.symlink(str(p), str(ROOT / "b.json"))
        elif kind == "symlink-to-regular-bad":
            real = ROOT / "real.json"
            real.write_text("[]")
            p.symlink_to(real)
        elif kind == "symlink-to-regular-good":
            real = ROOT / "real.json"
            real.write_text('{"log": {"level": "debug"}}')
            p.symlink_to(real)
        elif kind == "devnull":
            p.symlink_to("/dev/null")
        else:
            raise AssertionError(kind)
    return inner


CASES = [
    # (label, override-content, setup)
    ("BC-8 not valid JSON",            '{"log": ',                      None),
    ("BC-8 trailing comma",            '{"log": {"level": "x"},}',      None),
    ("BC-8 top level array",           '[]',                            None),
    ("BC-8 top level null",            'null',                          None),
    ("BC-8 top level number",          '0',                             None),
    ("BC-8 top level string",          '"hi"',                          None),
    ("BC-8 top level true",            'true',                          None),
    ("BC-8 not valid UTF-8",           b'{"log": "\xff\xfe"}',          None),
    ("BC-8 larger than 1 MiB",         BIG,                             None),
    ("BC-9 path is a directory",       None,             _mk("dir")),
    ("BC-9 path is a FIFO",            None,             _mk("fifo")),
    ("BC-9 symlink to a FIFO",         None,             _mk("symlink-to-fifo")),
    ("BC-9 symlink to /dev/null",      None,             _mk("devnull")),
    ("BC-10 unreadable (mode 000)",    None,             _mk("unreadable")),
    ("BC-10 symlink loop (ELOOP)",     None,             _mk("symlink-loop")),
    ("D-14 symlink to a regular file with a bad document",
     None,                                               _mk("symlink-to-regular-bad")),
    ("BC-11 bare array over dns.rules",
     '{"dns": {"rules": [{"server": "x"}]}}',                           None),
    ("BC-11 bare array over route.rule_set",
     '{"route": {"rule_set": []}}',                                     None),
    ("BC-14 unknown directive",
     '{"dns": {"rules": {"$patch": []}}}',                              None),
    ("BC-14 lone $ key",
     '{"dns": {"rules": {"$": []}}}',                                   None),
    ("B-5 directive mixed with an ordinary key",
     '{"dns": {"rules": {"$append": [], "x": 1}}}',                     None),
    ("B-5 two directives in one object",
     '{"dns": {"rules": {"$append": [], "$prepend": []}}}',             None),
    ("BC-13 directive on an object",
     '{"log": {"$append": []}}',                                        None),
    ("BC-13 directive on a scalar",
     '{"route": {"final": {"$append": []}}}',                           None),
    ("A-4 directive at a key that does not exist",
     '{"nope": {"$append": []}}',                                       None),
    ("A-4 directive at the top level",
     '{"$append": []}',                                                 None),
    ("$append payload is not an array",
     '{"dns": {"rules": {"$append": {"a": 1}}}}',                       None),
    ("$replace payload is a scalar",
     '{"dns": {"rules": {"$replace": 5}}}',                             None),
    ("$before payload is an array",
     '{"dns": {"rules": {"$before": []}}}',                             None),
    ("$before payload missing values",
     '{"dns": {"rules": {"$before": {"match": {}}}}}',                  None),
    ("$before payload with an extra key",
     '{"dns": {"rules": {"$before": {"match": {}, "values": [], "z": 1}}}}', None),
    ("$after values is not an array",
     '{"dns": {"rules": {"$after": {"match": {"clash_mode": "Direct"},'
     ' "values": {}}}}}',                                               None),
    ("$after match is not an object",
     '{"dns": {"rules": {"$after": {"match": 1, "values": []}}}}',      None),
    ("BC-12 anchor matches zero elements",
     '{"dns": {"rules": {"$after": {"match": {"clash_mode": "Nope"},'
     ' "values": [{"a": 1}]}}}}',                                       None),
    ("BC-12 anchor matches several elements",
     '{"route": {"rules": {"$after": {"match": {"outbound": "direct"},'
     ' "values": [{"a": 1}]}}}}',                                       None),
    ("shape assertion: dns.rules turned into a scalar",
     '{"dns": {"rules": "nope"}}',                                      None),
    ("shape assertion: route.rule_set turned into a number",
     '{"route": {"rule_set": 5}}',                                      None),
    ("shape assertion: route turned into a scalar",
     '{"route": 1}',                                                    None),
    ("hostile: key containing a literal newline",
     json.dumps({"dns": {"ru\nles": {"$append": []}}}),                 None),
    ("hostile: key containing CR and a CSI sequence",
     json.dumps({"dns": {"ru\r[31mles": {"$append": []}}}),       None),
    ("hostile: anchor value containing a newline",
     json.dumps({"dns": {"rules": {"$after": {"match": {"clash_mode": "Di\nrect"},
                                              "values": []}}}}),       None),
    ("hostile: key containing a lone ESC",
     json.dumps({"dns": {"rules": {"$append": []}}}),             None),
    ("hostile: directive name containing a newline",
     json.dumps({"dns": {"rules": {"$ap\npend": []}}}),                 None),
]


def main():
    witness("errors:start")
    sc = load_module(str(CAND), "sc_err")
    for lang in ("en", "zh"):
        for label, content, setup in CASES:
            if setup is not None and "FIFO" in label:
                signal.signal(signal.SIGALRM,
                              lambda *a: (_ for _ in ()).throw(
                                  AssertionError("HUNG on a FIFO")))
                signal.alarm(10)
            try:
                malformed_case(sc, label, content, lang=lang, setup=setup)
            finally:
                signal.alarm(0)

    # ---- the DANGLING SYMLINK: absent, or broken? -----------------------
    # ruleset_state() (bin/sc:723) already decides this question for the other
    # user-facing file in this project: "A dangling symlink does not exist, but it is
    # broken rather than absent" -> "unreadable". _load_override() forms the opposite
    # opinion. Characterise it rather than assume.
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, config_bytes=SENTINEL)
    repoint(sc)
    _mk("dangling-symlink")(sc)
    r = drive_main(sc, ["reload"])
    cfg = sc.CFG_PATH.read_bytes()
    note("DANGLING SYMLINK at override.json",
         "exit=%r  config.json replaced=%s  stderr=%r"
         % (r["code"], cfg != SENTINEL, r["err"][:120]))
    ok(sc.RULES_DIR.exists(), "fixture intact")
    # the project's own precedent, measured on the same fixture
    dang = ROOT / "rules" / "geoip-cn.srs"
    dang.unlink()
    dang.symlink_to(ROOT / "rules" / "gone.srs")
    note("PRECEDENT ruleset_state() on a dangling symlink",
         repr(sc.ruleset_state(dang)))

    # ---- the cases that must be ACCEPTED --------------------------------
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, config_bytes=SENTINEL)
    repoint(sc)
    _mk("symlink-to-regular-good")(sc)
    r = drive_main(sc, ["reload"])
    doc = json.loads(sc.CFG_PATH.read_text())
    ok(r["code"] == 0 and doc["log"]["level"] == "debug",
       "D-14 a symlink resolving to a REGULAR file is accepted",
       "%r %r" % (r["code"], r["err"][:120]))

    # ---- deep nesting: does a hand-written override earn a sentence? -----
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, config_bytes=SENTINEL, override=DEEP)
    repoint(sc)
    before = tree_snapshot()
    r = drive_main(sc, ["reload"])
    after = tree_snapshot()
    ok(after.get("config.json", (None,))[0] == SENTINEL,
       "deeply nested override does not touch config.json")
    ok(isinstance(r["code"], str) and r["code"].startswith("Cannot use "),
       "deeply nested override earns an OverrideError sentence, not a traceback",
       "code=%r exc=%r" % (str(r["code"])[:100], r["exc"]))

    # ---- valid JSON, semantically hostile (BC-15) -----------------------
    wipe()
    seed(N3, "osaka-02", ALL_USABLE)
    repoint(sc)
    (ROOT / "override.json").write_text(json.dumps({
        "experimental": {"clash_api": {"$append": []}}}))
    r = drive_main(sc, ["reload"])
    note("BC-15 $append on experimental.clash_api (an object)", repr(r["code"])[:120])
    wipe()
    seed(N3, "osaka-02", ALL_USABLE)
    repoint(sc)
    (ROOT / "override.json").write_text(json.dumps({
        "experimental": {"clash_api": {"external_controller": None}},
        "outbounds": {"$replace": [{"type": "direct", "tag": "not-proxy"}]}}))
    r = drive_main(sc, ["reload"])
    doc = json.loads(sc.CFG_PATH.read_text())
    ok(r["code"] == 0
       and doc["experimental"]["clash_api"]["external_controller"] is None
       and not any(o.get("tag") == "proxy" for o in doc["outbounds"]),
       "BC-15 an override that removes what sc depends on is NOT prevented "
       "(documented, not blocked)", repr(r["code"])[:120])

    # ---- an object silently REPLACING an existing array ------------------
    wipe()
    seed(N3, "osaka-02", ALL_USABLE)
    repoint(sc)
    (ROOT / "override.json").write_text(json.dumps({"inbounds": {"mtu": 1500}}))
    r = drive_main(sc, ["reload"])
    doc = json.loads(sc.CFG_PATH.read_text()) if sc.CFG_PATH.exists() else None
    note("ASYMMETRY: a bare OBJECT over an existing array",
         "exit=%r  inbounds=%r" % (r["code"], doc and doc.get("inbounds")))

    # ---- NaN / Infinity ---------------------------------------------------
    wipe()
    seed(N3, "osaka-02", ALL_USABLE)
    repoint(sc)
    (ROOT / "override.json").write_text('{"log": {"level": NaN}}')
    r = drive_main(sc, ["reload"])
    raw = sc.CFG_PATH.read_text() if sc.CFG_PATH.exists() else ""
    note("NaN in an override", "exit=%r  emitted contains NaN: %s"
         % (r["code"], "NaN" in raw))

    # ---- AC-12 with an override present ----------------------------------
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, override='{"log": {"level": "debug"}}')
    repoint(sc)
    before_nodes = sc.NODES_PATH.read_bytes()
    S.run_generate(sc, calls=3)
    ok(sc.NODES_PATH.read_bytes() == before_nodes,
       "AC-12 nodes.json byte-unchanged across 3 generations WITH an override")
    doc = json.loads(sc.CFG_PATH.read_text())
    ok(doc["outbounds"][1]["tag"] == "tokyo-01" and "qa" not in doc["outbounds"][1],
       "BC-21 the node objects reached the document unmutated")

    # ---- AC-11 with an override present ----------------------------------
    res = S.run_generate(sc, calls=3)
    ok(res[0].config == res[1].config == res[2].config,
       "AC-11 three consecutive calls WITH an override yield identical bytes")

    # ---- a second module-level mutation check ----------------------------
    ok(sc.CONFIG_BASE["outbounds"] == [] and sc.CONFIG_BASE["route"]["rule_set"] == []
       and sc.CONFIG_BASE["experimental"]["clash_api"]["external_controller"] == ""
       and len(sc.CONFIG_BASE["dns"]["rules"]) == 8
       and len(sc.CONFIG_BASE["route"]["rules"]) == 12,
       "BC-20 CONFIG_BASE is unmutated after ~100 compositions in this process",
       repr(sc.CONFIG_BASE["outbounds"])[:80])

    # ---- exit status is really 1 -----------------------------------------
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, override="[]")
    repoint(sc)
    r = drive_main(sc, ["reload"])
    ok(isinstance(r["code"], str),
       "AC-20 SystemExit carries a message string ⇒ process status 1")

    witness("errors:end")
    npass = sum(1 for x, _, _ in RESULTS if x is True)
    nfail = sum(1 for x, _, _ in RESULTS if x is False)
    for x, label, detail in RESULTS:
        if x is not True:
            print("%s %s   -- %s" % ({False: "FAIL", None: "note"}[x], label, detail))
    print("\n%d ok, %d FAILED" % (npass, nfail))
    return 1 if nfail else 0


if __name__ == "__main__":
    sys.exit(main())
```

### `qa_commands.py`

```python
#!/usr/bin/env python3
"""T-14 QA — AC-21 across every command, plus the README's regeneration claim and the
two MINOR findings stage 5 left open. No network: _fetch_to_temp is stubbed.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qa_common import (ROOT, USABLE, load_module, node, repoint, seed,
                       tree_snapshot, wipe, witness)
from qa_semantics import ALL_USABLE, N3, RESULTS, SENTINEL, drive_main, note, ok

CAND = "/home/alan/Programs/singbox-cli/bin/sc"
BAD = '{"dns": {"rules": {"$patch": []}}}'
VLESS = ("vless://11111111-2222-3333-4444-555555555555@203.0.113.9:443"
         "?encryption=none&security=tls&sni=e.com&type=tcp#qa-new")


def fixture(sc, lang="en", override=None, statuses=ALL_USABLE, config=SENTINEL):
    wipe()
    seed(N3, "osaka-02", statuses, lang=lang, override=override, config_bytes=config)
    repoint(sc, lang=lang)


def gen_spy(sc):
    calls = []
    real = sc.generate_config
    sc.generate_config = lambda: (calls.append(1), real())[1]
    return calls, real


def main():
    witness("commands:start")
    sc = load_module(CAND, "sc_cmd")

    # ---- AC-21: every command that regenerates aborts with the service untouched ---
    for cmd, argv in (("reload", ["reload"]), ("add", ["add", VLESS]),
                      ("rm", ["rm", "sg-03"]), ("use", ["use", "tokyo-01"]),
                      ("mode", ["mode", "global"])):
        fixture(sc, override=BAD)
        before = tree_snapshot()
        r = drive_main(sc, argv)
        after = tree_snapshot()
        cfg_same = after.get("config.json", (None,))[0] == SENTINEL
        if cmd == "mode":
            ok(r["code"] is 0 or r["code"] is None or r["code"] == 0,
               "README claim: `sc mode` NEVER regenerates — a malformed override "
               "cannot block it", repr(r["code"]))
            ok(cfg_same and r["restarts"] == 0,
               "`sc mode` writes no config.json and touches no service")
            ok(json.loads((ROOT / "settings.json").read_text())["mode"] == "global",
               "`sc mode` still persisted the mode")
            continue
        ok(isinstance(r["code"], str) and r["code"].startswith("Cannot use "),
           "AC-20 `sc %s` exits 1 with the override sentence" % cmd,
           repr(r["code"])[:110])
        ok(cfg_same, "AC-20 `sc %s` leaves config.json byte-identical" % cmd)
        ok(r["restarts"] == 0,
           "AC-21 `sc %s` performs no service-affecting action" % cmd)

    # `sc add` persists the node before it aborts (04 §11.3) — confirm, do not assume
    fixture(sc, override=BAD)
    drive_main(sc, ["add", VLESS])
    tags = [n["tag"] for n in json.loads((ROOT / "nodes.json").read_text())["nodes"]]
    note("`sc add` + malformed override", "node persisted before the abort: tags=%r"
         % tags)

    # ---- cmd_use hot-apply arm never reads the override --------------------
    fixture(sc, override=BAD)
    real_api = sc.clash_api
    sc.clash_api = lambda *a, **k: {"ok": True}
    calls, real_gen = gen_spy(sc)
    try:
        r = drive_main(sc, ["use", "tokyo-01"], running=True)
    finally:
        sc.clash_api = real_api
        sc.generate_config = real_gen
    ok(r["code"] == 0 and calls == [],
       "README claim: `sc use` regenerates ONLY on the hot-apply fallback arm "
       "(a malformed override does not block a live node switch)",
       "code=%r generate_config calls=%d" % (r["code"], len(calls)))

    # ---- cmd_update_rules: regenerates only when a rule-set is GAINED -------
    def stub_fetch(body):
        def inner(url, tmp, prefix, tty):
            tmp.write_bytes(body)
            return len(body)
        return inner

    # (a) nothing changed -> no regeneration at all
    fixture(sc, statuses=ALL_USABLE, config=SENTINEL)
    real_fetch = sc._fetch_to_temp
    sc._fetch_to_temp = stub_fetch(USABLE)          # identical bytes to the fixture
    calls, real_gen = gen_spy(sc)
    try:
        r = drive_main(sc, ["update-rules"])
    finally:
        sc._fetch_to_temp, sc.generate_config = real_fetch, real_gen
    ok(calls == [] and "not touched" in r["out"],
       "README claim: `sc update-rules` does NOT regenerate when nothing changed",
       "calls=%d out=%r" % (len(calls), r["out"][-90:]))

    # (b) a rule-set is gained -> regenerates
    fixture(sc, statuses=("absent",) * 4, config=SENTINEL)
    sc._fetch_to_temp = stub_fetch(USABLE)
    calls, real_gen = gen_spy(sc)
    try:
        r = drive_main(sc, ["update-rules"])
    finally:
        sc._fetch_to_temp, sc.generate_config = real_fetch, real_gen
    ok(len(calls) == 1 and "regenerated" in r["out"],
       "README claim: `sc update-rules` regenerates when a rule-set is GAINED",
       "calls=%d" % len(calls))

    # (c) gained + malformed override -> T-3's documented consequence
    fixture(sc, statuses=("absent",) * 4, config=SENTINEL, override=BAD)
    sc._fetch_to_temp = stub_fetch(USABLE)
    try:
        r = drive_main(sc, ["update-rules"])
    finally:
        sc._fetch_to_temp = real_fetch
    outcome = any(s in r["out"] for s in ("was not touched", "restarted to load them"))
    ok(isinstance(r["code"], str) and r["code"].startswith("Cannot use "),
       "AC-20 `sc update-rules` exits 1 with the override sentence")
    ok(tree_snapshot().get("config.json", (None,))[0] == SENTINEL,
       "AC-20 `sc update-rules` leaves config.json byte-identical")
    ok(r["restarts"] == 0, "AC-21 `sc update-rules` performs no service action")
    note("T-3 (ruled ship-as-designed at the gate)",
         "run-level outcome line printed = %s  [expected False]" % outcome)

    # ---- stage-5 MINOR-1: the residual traceback path ----------------------
    for label, ov in (("non-object element appended to dns.rules",
                       '{"dns": {"rules": {"$append": ["oops"]}}}'),
                      ("non-object element appended to route.rules",
                       '{"route": {"rules": {"$append": [42]}}}'),
                      ("null element appended to dns.rules",
                       '{"dns": {"rules": {"$append": [null]}}}')):
        fixture(sc, override=ov)
        r = drive_main(sc, ["reload"])
        same = tree_snapshot().get("config.json", (None,))[0] == SENTINEL
        note("MINOR-1 %s" % label,
             "exc=%r  config.json untouched=%s  restarts=%d"
             % (r["exc"], same, r["restarts"]))

    # ---- non-object element in route.rule_set (the guarded array) ----------
    fixture(sc, override='{"route": {"rule_set": {"$append": ["oops"]}}}')
    r = drive_main(sc, ["reload"])
    note("route.rule_set with a non-object element (guarded at :1475)",
         "exit=%r exc=%r" % (str(r["code"])[:60], r["exc"]))

    # ---- BC-18/BC-19: streams redirected (install.sh step 7 shape) ---------
    fixture(sc, config=SENTINEL)
    drive_main(sc, ["reload"])                       # creates the record
    (ROOT / "config.json").write_bytes(
        (ROOT / "config.json").read_bytes() + b"\n")
    r = drive_main(sc, ["reload"])
    ok(r["err"].count("\n") == 1 and "\r" not in r["err"],
       "BC-18/NFR-7 the drift warning survives redirection as ONE line",
       repr(r["err"])[:140])

    witness("commands:end")
    nfail = sum(1 for x, _, _ in RESULTS if x is False)
    for x, label, detail in RESULTS:
        if x is not True:
            print("%s %s   -- %s" % ({False: "FAIL", None: "note"}[x], label, detail))
    print("\n%d ok, %d FAILED"
          % (sum(1 for x, _, _ in RESULTS if x is True), nfail))
    return 1 if nfail else 0


if __name__ == "__main__":
    sys.exit(main())
```

### `qa_realbox.py`

```python
#!/usr/bin/env python3
"""T-14 QA — validate the COMPOSED document against the REAL sing-box binary.

`sing-box check -c <file>` is read-only: it is the very call generate_config() makes
on every run. Nothing is started, stopped or reloaded; the cache_file path is rewritten
into the temp root so no /var/lib write can be attempted.
"""
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qa_common import ROOT, load_module, node, repoint, run_generate, seed, wipe, witness
from qa_semantics import ALL_USABLE, N3

SB = "/usr/local/bin/sing-box"
CAND = "/home/alan/Programs/singbox-cli/bin/sc"
BASE = str(Path(__file__).resolve().parent / "pristine" / "bin" / "sc")


def check(doc, label):
    doc = json.loads(json.dumps(doc)) if isinstance(doc, dict) else json.loads(doc)
    doc.setdefault("experimental", {}).setdefault("cache_file", {})["path"] = \
        str(ROOT / "cache.db")
    p = ROOT / "qa-check.json"
    p.write_text(json.dumps(doc, indent=2, ensure_ascii=False))
    r = subprocess.run([SB, "check", "-c", str(p)], stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, text=True, timeout=60)
    print("%-58s rc=%d %s" % (label, r.returncode,
                              r.stdout.strip().replace("\n", " | ")[:150]))
    p.unlink()
    return r.returncode


def emit(sc, override=None, statuses=("absent",) * 4):
    wipe()
    seed(N3, "osaka-02", statuses, override=override)
    repoint(sc)
    res = run_generate(sc)[0]
    return sc.CFG_PATH.read_text() if sc.CFG_PATH.exists() else None, res


def main():
    witness("realbox:start")
    print("sing-box:", subprocess.run([SB, "version"], stdout=subprocess.PIPE,
                                      text=True).stdout.splitlines()[0])
    cand = load_module(CAND, "sc_rb")
    base = load_module(BASE, "sc_rb_base")

    b, _ = emit(base)
    c, _ = emit(cand)
    assert b == c, "baseline and candidate diverged"
    check(b, "baseline, no override, all rule-sets absent")
    check(c, "CANDIDATE, no override, all rule-sets absent")

    for label, ov in [
        ("override {} (empty)", "{}"),
        ("deep-merge log.level=debug", '{"log": {"level": "debug"}}'),
        ("$after anchored on clash_mode Direct (the T-16 shape)",
         json.dumps({"dns": {"rules": {"$after": {
             "match": {"clash_mode": "Direct"},
             "values": [{"server": "direct_dns", "domain_suffix": ["qa.test"]}]}}}})),
        ("$append a route rule", json.dumps({"route": {"rules": {"$append": [
            {"outbound": "direct", "domain_suffix": ["qa.test"]}]}}})),
        ("$prepend an outbound-ish new key", json.dumps({"endpoints": []})),
        ("BC-15: external_controller removed (set to null)",
         json.dumps({"experimental": {"clash_api": {"external_controller": None}}})),
        ("BC-15: proxy outbound tag replaced",
         json.dumps({"outbounds": {"$replace": [
             {"type": "direct", "tag": "not-proxy"}]}})),
        ("ASYMMETRY: object silently replacing the inbounds array",
         json.dumps({"inbounds": {"mtu": 1500}})),
        ("NaN smuggled through json.loads", '{"log": {"level": NaN}}'),
    ]:
        doc, res = emit(cand, override=ov)
        if doc is None:
            print("%-58s (aborted: %s)" % (label, res.exc))
            continue
        try:
            check(doc, label)
        except Exception as e:
            print("%-58s harness could not check: %s" % (label, e))
    witness("realbox:end")


if __name__ == "__main__":
    main()
```

---

## Stage 6′ — re-verification (BC-27 / AC-31)

Scope: the one fix routed from `06` MAJOR **D-1** — `01` §12 (Addendum A) **BC-27 / AC-31 / D-17**,
implemented as `04` §17. Nothing else was re-tested. The 164-run differential, the six mutants and
the 30 AC results in §1 – §11 stand as written; §12's routing line is what this section closes.

**The oracle for this behaviour is `01` §12, read directly.** Where §12 and `04` §17 might have
disagreed I would have followed §12; they did not disagree.

### 6′.1 Verdict of the re-verification

| | |
|---|---|
| MAJOR **D-1** | **CLOSED** — reproduced red on the unfixed build, green on the fixed one, 20 assertions |
| AC-1 (the one that matters) | **still green** — 164/164, unrelaxed, same `f642ca7` oracle |
| AC-31 clause 2 | **green** — silent `None`, and the override-less build is byte-identical to T-14 *without* the fix, whole tree |
| BC-27, both languages | **green** — 20 assertions over 10 link shapes × 2 languages |
| The narrowed parent boundary | **green** — a broken *parent* still behaves as absent, 8 assertions |
| D-14, BC-9 | **green** — unmoved, 12 + 10 assertions |
| AC-27 / AC-28 for the new key | **green** — one key pair, `{target}` on both sides, no `失败：` |
| `verify_all` | **PASS 16 / WARN 1 / FAIL 0 / SKIP 1** |
| New defects found in this stage | **none** |

### 6′.2 What I ran, and against what

Everything below is my own harness (§13), not `04`'s. The one file written new for this stage is
`qa_bc27.py`, pasted verbatim in §6′.11. I read `04` §17 only to learn *which five lines changed*;
the assertions come from §12's text.

| Harness | Candidate | Oracle | Result |
|---|---|---|---|
| `qa_bc27.py` (**new**, 50 assertions) | working tree `bin/sc` | `01` §12 | **50 ok, 0 FAILED** |
| `qa_bc27.py` | `mutant_nofix.py` (fix reverted) | — | **30 ok, 20 FAILED** — the non-vacuity proof |
| `qa_diff.py` + `qa_common.py` (§13, **unmodified**) | working tree `bin/sc` | pristine clone at `f642ca7` | **PASS — 164 runs** (82 points × 2 languages) |
| `qa_semantics.py` (§13, **one assertion changed**, §6′.6) | working tree `bin/sc` | `f642ca7` | **186 ok, 0 FAILED, 3 notes** |
| `qa_errors.py` (§13, **unmodified**) | working tree `bin/sc` | — | **95 ok, 1 FAILED** — the 1 is R-15, expected |
| `bc27_test.py` (`04` §17's own, unmodified, run as a **cross-check only**) | working tree `bin/sc` | — | 26 ok, 0 FAILED |
| `bash .harness/scripts/verify_all.sh` | working tree | — | **PASS 16 / WARN 1 / FAIL 0 / SKIP 1** |

The differential's oracle is the same one §4 used, re-established and re-proved identical:

```
$ git clone -q /home/alan/Programs/singbox-cli pristine && git -C pristine checkout -q f642ca7
$ git -C pristine log --oneline -1
f642ca7 docs(pool): restructure remaining rows around one config-composition layer
$ diff -q pristine/bin/sc sc_baseline.py
pristine/bin/sc == sc_baseline.py == f642ca7:bin/sc

$ python3 qa_diff.py --baseline sc_baseline.py --candidate bin/sc --quiet
compared 164 differential runs (82 points x 2 languages)
RESULT: PASS — byte-identical config, stderr (all calls), return value and nodes.json
```

**It was not relaxed, re-scoped or re-baselined.** `qa_diff.py` and `qa_common.py` are byte-identical
to the copies published in §13; the only tolerance in the file is the pre-existing
`extra != {".config.sha256"}` line, which was already there at stage 6 because T-14 adds that file by
design (BC-16).

### 6′.3 Probes, one hypothesis per clause of §12

Each row states the failure predicted **before** the run. Where the implementation held, what was
tried against it is recorded.

| §12 clause | Hypothesis — "I expect failure when…" | Reproducer (all NEW, mine) | Outcome |
|---|---|---|---|
| BC-27, sentence | the target is interpolated into a translated template *and then* into `main()`'s outer template, so a target containing `\n` / `\r` / an ESC-CSI sequence yields a multi-line or escape-bearing message | `qa_bc27.py` → `p_control_chars` | **Survived.** The rendering site collapses `\n` *before* `_plain()` strips CR and CSI, so `…/a b c d.json` arrives as one physical line, no ESC |
| BC-27, sentence | `t()` runs `str.format` on the template and `main()` runs it again on the assembled sentence — a target containing `{path}` should raise `KeyError` or leak | `qa_bc27.py` → `p_braces` | **Survived.** `format` is applied to templates only, never to a substituted value; `{path}-{target}.json` appears literally |
| BC-27, "through a chain of links" | `realpath` on a 3-link chain names the *first* link, not the missing end | `qa_bc27.py` → `p_chain3` | **Survived.** The message names `…/the-end-is-missing.json` |
| BC-27, relative targets | a relative target resolves against the *process* cwd, not the link's directory, so the named target is a lie | `qa_bc27.py` → `p_relative`, `p_dotdot` | **Survived.** Both resolve against the link's own directory; `../fixture/nope/sb.json` normalises to `…/fixture/nope/sb.json` |
| BC-27, final-component-only | a link whose *target* has a missing parent directory is a different code path and falls through to "absent" | `qa_bc27.py` → `p_through_broken_parent` | **Survived.** `islink` is about the *path*, not the resolution, so it is malformed — correct under §12.1 |
| AC-31 / AC-21 | with the service believed **running**, or on a **different command** (`sc use`), some service-affecting or file-writing action slips in ahead of the abort | `qa_bc27.py` → `running=True`, `argv=("use","tokyo-01")` | **Survived for `config.json`, the drift record and `restart_service`.** One measured exception, pre-existing and out of scope — see §6′.5 |
| AC-31 clause 2 | the extra `lstat` on the arm every AC-1 run takes changes *something* — a stray write, a stream byte, a return value | `qa_bc27.py` Group B, two oracles | **Survived.** Identical to `f642ca7` on `config.json` + `nodes.json` + both streams + return value, and identical to T-14-**without**-the-fix on the *whole tree*, drift record included |
| §12.1 narrowed boundary | `linkdir/override.json` where `linkdir` is a dangling **directory** link raises — an implementation testing `islink(dirname)`, or `lstat`-ing a resolved path, would draw the line one component too early | `qa_bc27.py` → `absent(...)` × 4 shapes × 2 langs | **Survived.** Silent `None`, and `sc reload` still exits 0 and restarts once. The line is drawn exactly where §12.1 drew it |
| BC-9 (must be untouched) | the new arm swallows the FIFO/device case, or the `stat`-before-`open` ordering moved and a FIFO hangs the CLI | `qa_bc27.py` Group D under a 20 s `SIGALRM`; `qa_errors.py` BC-9 rows | **Survived.** FIFO and directory targets still say *not a regular file* / *不是普通文件*, never the symlink sentence; no run approached the alarm |
| BC-9, unenumerated shape | a symlink **loop** raises `ELOOP`, an `OSError` but *not* `FileNotFoundError` — reached via a bare `except OSError` it would misreport, unhandled it would traceback | `qa_bc27.py` → `p_to_self_loop` | **Survived.** Lands in the pre-existing `OSError` arm: one line, names the path, no traceback, no hang |
| D-14 | the new `islink` test fires before `os.stat` follows the link, breaking the accepted case | `qa_bc27.py` Group D | **Survived.** `log.level == "debug"` applied, `log.timestamp` preserved, exit 0, one restart |
| AC-27 / AC-28 | the new key is namespaced, or its `zh` value drops `{target}` or carries `失败：` | AST extraction over `bin/sc`, `qa_semantics.py::i18n` | **Survived.** See §6′.6 |

### 6′.4 The 20 BC-27 assertions, and the messages they check

`qa_bc27.py::malformed()` (§6′.11, lines 67–128) is one assertion per row; every clause below must
hold or the row is red:

```
    r["exc"]                            -> red: raised out of main()
    not isinstance(r["code"], str)      -> red: exit code is not a message string (=> not status 1)
    after["config.json"] != SENTINEL    -> red: config.json NOT byte-identical
    after[".config.sha256"] != STATE    -> red: drift record changed
    r["restarts"]                       -> red: restart_service called Nx (AC-21)
    r["err"] or r["out"]                -> red: wrote to a stream as well
    physical_lines(msg) != 1            -> red: NOT one physical line
    "\x1b" in msg                       -> red: message contains ESC
    str(sc.OVERRIDE_PATH) not in msg    -> red: does not name the override path
    "失败：" in msg                      -> red: carries the 失败： grep marker
    zh: "符号链接" and "不存在" present, "symbolic link" absent
    en: "symbolic link" and "does not exist" present
    expect_target / expect_marker present in msg
    whole-tree equality before/after (minus an explicitly named, measured exception)
```

Rendered, measured (not quoted from `04`) — the `zh` run has `lang` pinned in the fixture's
`settings.json`, which `main()` re-reads, so the Chinese assertion is on real Chinese content:

```
en  Cannot use /tmp/t14qa-v2ivxgk5/fixture/override.json: a symbolic link whose target /tmp/t14qa-v2ivxgk5/fixture/dotfiles/sing-box.json does not exist
zh  无法使用 /tmp/t14qa-v2ivxgk5/fixture/override.json：是一个符号链接，但其目标 /tmp/t14qa-v2ivxgk5/fixture/dotfiles/sing-box.json 不存在
```

"Non-zero exit" is a property of `sys.exit(<str>)`, proved rather than assumed, and it is where the
one-physical-line contract is finally cashed:

```
$ python3 -c "import sys; sys.exit('Cannot use /etc/sing-box/override.json: a symbolic link whose target /home/u/dotfiles/sb.json does not exist')" >o 2>e
exit=1   stdout bytes=0   stderr lines=1
$ od -c e | tail -1
0000120   f i l e s / s b . j s o n   d o e s   n o t   e x i s t  \n
```

Full run:

```
[witness qa_bc27:start] MainPID=2887037 | ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST
ok   BC-27/AC-31 [en] direct dangling link (absolute target)
ok   BC-27/AC-31 [en] 3-link chain, broken at the end
ok   BC-27/AC-31 [en] relative target
ok   BC-27/AC-31 [en] relative target with ..
ok   BC-27/AC-31 [en] target containing \n, \r and an ESC/CSI sequence
ok   BC-27/AC-31 [en] target containing {format} braces
ok   BC-27/AC-31 [en] non-ASCII target
ok   BC-27/AC-31 [en] link pointing THROUGH a directory that does not exist
ok   BC-27/AC-31 [en] dangling link, service believed running
ok   BC-27/AC-31 [en] dangling link, `sc use tokyo-01` (a second command)
ok   BC-27/AC-31 [zh] ... the same ten, zh
ok   AC-31.2 [en] no entry at the override path => silent None
ok   AC-1 [en] override-less build still matches the f642ca7 PRE-CHANGE build (config.json + nodes.json bytes, both streams, return value)
ok   AC-31.2 [en] override-less build identical to T-14 WITHOUT the islink block — whole tree, drift record included
ok   AC-31.2 [zh] ... the same three, zh
ok   AC-31.2 [en] no entry at all => silent None
ok   AC-31.2 [en] no entry at all => `sc reload` still succeeds normally
ok   AC-31.2 [en] broken PARENT: dangling directory link => silent None
ok   AC-31.2 [en] broken PARENT: dangling directory link => `sc reload` still succeeds normally
ok   AC-31.2 [en] broken PARENT: no directory at all => silent None
ok   AC-31.2 [en] broken PARENT: no directory at all => `sc reload` still succeeds normally
ok   AC-31.2 [en] PARENT is a link that RESOLVES, final component missing => silent None
ok   AC-31.2 [en] PARENT is a link that RESOLVES, final component missing => `sc reload` still succeeds normally
ok   AC-31.2 [zh] ... the same eight, zh
ok   D-14 [en] symlink -> REGULAR file with a valid override is still applied
ok   BC-9 [en] symlink -> FIFO still reports 'not a regular file', no hang
ok   BC-9 [en] symlink -> directory still reports 'not a regular file', no hang
ok   BC-9 [en] a symlink LOOP aborts in one line, no traceback, no hang
ok   D-14 [zh] ... the same four, zh
[witness qa_bc27:end] MainPID=2887037 | ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST

50 ok, 0 FAILED
```

### 6′.5 Non-vacuity — these assertions reproduced the MAJOR before they were believed

`mutant_nofix.py` is the **working tree's** `bin/sc` with only the five-line `islink` block deleted;
nothing else, the `zh` table entry included, was touched:

```
$ diff bin/sc mutant_nofix.py
1296,1300d1295
<         if os.path.islink(str(OVERRIDE_PATH)):
<             # realpath, not readlink: it resolves a CHAIN of links down to the component
<             # that is actually missing, and unlike readlink it cannot raise.
<             raise OverrideError(t("a symbolic link whose target {target} does not exist",
<                                   target=os.path.realpath(str(OVERRIDE_PATH))))

$ python3 qa_bc27.py mutant_nofix.py
30 ok, 20 FAILED
FAILED labels:
  - BC-27/AC-31 [en] direct dangling link (absolute target)
  - BC-27/AC-31 [en] 3-link chain, broken at the end
  - BC-27/AC-31 [en] relative target
  - BC-27/AC-31 [en] relative target with ..
  - BC-27/AC-31 [en] target containing \n, \r and an ESC/CSI sequence
  - BC-27/AC-31 [en] target containing {format} braces
  - BC-27/AC-31 [en] non-ASCII target
  - BC-27/AC-31 [en] link pointing THROUGH a directory that does not exist
  - BC-27/AC-31 [en] dangling link, service believed running
  - BC-27/AC-31 [en] dangling link, `sc use tokyo-01` (a second command)
  ... and the same ten in [zh]
```

**Exactly the 20 BC-27 clause-1 assertions go red; the other 30 stay green** — which is the evidence
that the fix is confined to the arm it claims. And they go red by *reproducing D-1 verbatim*:

```
FAIL BC-27/AC-31 [en] direct dangling link (absolute target)
  -- exit code 0 is not a message string (=> not status 1); config.json NOT byte-identical;
     drift record changed: (b'2281d53e0c1491b654fac4dfa3e43ce54de35d67926ca2c8926d407025f458e0\n', 384);
     restart_service called 1x (AC-21); stderr also written: '⚠️  …/config.json was modified outside
     sc — those changes are about to be replaced; put them i'; stdout written: 'Reloaded\n';
     NOT one physical line (0): ''; message does not name the override path; …

FAIL BC-27/AC-31 [zh] direct dangling link (absolute target)
  -- … stdout written: '已重新加载\n'; zh message is not really Chinese: ''; …
```

**The one measured exception, and why it is not a defect.** The whole-tree assertion initially went
red for `sc use tokyo-01` (`nodes.json` changed) and for the AC-1 comparison against `f642ca7`
(`.config.sha256` present on one side only). Neither assertion was weakened until it was measured
which side was wrong:

```
$ python3 _probe1.py
[use + invalid-JSON override, T-14 unfixed] exit='Cannot use …/override.json…' changed=['nodes.json']
[use + invalid-JSON override, T-14 fixed  ] exit='Cannot use …/override.json…' changed=['nodes.json']
[override-less generate_config, f642ca7 baseline] files=[... no .config.sha256 ...]
[override-less generate_config, T-14 unfixed   ] files=['.config.sha256', ...]
[override-less generate_config, T-14 fixed     ] files=['.config.sha256', ...]
```

- `cmd_use` writes `nodes.json["active"]` **before** composition runs, so *every* malformed override —
  invalid JSON included, on the **unfixed** build — leaves it changed. Pre-existing T-14 behaviour,
  identical on both builds, and outside AC-20/AC-31, which guarantee `config.json`. Recorded as an
  observation (§6′.7), not a defect, and not re-opened here.
- `.config.sha256` is a file T-14 **adds** by design (BC-16), so a whole-tree comparison against
  pre-T-14 code is the harness being wrong, not the code. Replaced with the two correct oracles —
  `f642ca7` for the shared files/streams/return value, and the unfixed T-14 build for the whole tree.

### 6′.6 AC-27 / AC-28 for the new key, extracted from the code

`qa_semantics.py::i18n` walks the AST of `bin/sc` for `t()` call sites with a literal first argument
and subtracts the same set taken from `f642ca7`. It is the only file of mine that changed this stage,
by one assertion, because §12 approves exactly one more key pair:

```python
    # 17 at stage 6; 18 from stage 6' — `01` §12 (Addendum A) approves EXACTLY one more
    # key pair for BC-27. Still an equality, and the key itself is pinned on the next
    # line, so an eighteenth-and-a-half key is still a failure.
    ok(len(new) == 18, "AC-27 exactly 18 new t() keys (17 + BC-27's one, as designed)",
       "%d: %r" % (len(new), new))
    ok("a symbolic link whose target {target} does not exist" in new,
       "AC-27 the 18th key is BC-27's, and no other", repr(new))
```

This is a **ratchet up, not a relaxation**: it is still an equality, and the identity of the extra key
is now pinned too, which the old assertion did not do. Non-vacuity had to be measured separately,
because the AST checks read the working tree by design and so ignore the `argv` candidate:

```
working tree bin/sc  new t() keys = 18   assertion(==18) PASS   BC-27 key present: True
mutant_nofix.py      new t() keys = 17   assertion(==18) FAIL   BC-27 key present: False
```

Result on the fixed tree:

```
ok   AC-27 exactly 18 new t() keys (17 + BC-27's one, as designed)
ok   AC-27 the 18th key is BC-27's, and no other
ok   AC-27 new key present in zh table: 'a symbolic link whose target {target} does not exi'
ok   AC-27 placeholder set matches for 'a symbolic link whose target {target} do'
ok   AC-27 no 失败： in zh for 'a symbolic link whose target {target} do'
ok   AC-28 key is readable English prose: 'a symbolic link whose target {target} does not exi'
ok   AC-28 no namespaced key: 'a symbolic link whose target {target} do'
ok   AC-27 no pre-existing zh entry was lost
ok   AC-27 no NEW dynamic t() call site was added (2 pre-existing at bin/sc:1996)

186 ok, 0 FAILED, 3 notes
```

One key pair, identical placeholder set `{target}`, no `失败：`, readable English prose as the key, not
namespaced. AC-27 and AC-28 hold.

### 6′.7 BC-9 re-run, and the out-of-scope rows

`qa_errors.py`, **unmodified**, against the fixed tree. Its `ok()` prints only failures, so the BC-9
rows were surfaced with a wrapper that monkey-patches `ok` to print every row — the harness file
itself was not edited:

```
ok   AC-20/21 [en] BC-9 path is a directory          ok   AC-20/21 [zh] BC-9 path is a directory
ok   AC-20/21 [en] BC-9 path is a FIFO               ok   AC-20/21 [zh] BC-9 path is a FIFO
ok   AC-20/21 [en] BC-9 symlink to a FIFO            ok   AC-20/21 [zh] BC-9 symlink to a FIFO
ok   AC-20/21 [en] BC-9 symlink to /dev/null         ok   AC-20/21 [zh] BC-9 symlink to /dev/null
ok   AC-20/21 [en] D-14 symlink to a regular file with a bad document   (and [zh])
ok   D-14 a symlink resolving to a REGULAR file is accepted

95 ok, 1 FAILED
```

The FIFO rows run under a 10 s `SIGALRM` inside `qa_errors.py` and a 20 s one inside `qa_bc27.py`;
neither fired. The `stat`-before-`open` ordering is intact and the guard still works.

The single FAIL is `deeply nested override earns an OverrideError sentence, not a traceback` →
`RecursionError` — **R-15**, ruled out of T-14 by `01` §12.4 (O-11). Expected, identical to the
stage-6 run, **not** a regression. `qa_errors.py`'s two characterisation notes now read:

```
note DANGLING SYMLINK at override.json   -- exit='Cannot use …/override.json: a symbolic link whose
     target …/nowhere.json does not exist'  config.json replaced=False  stderr=''
note ASYMMETRY: a bare OBJECT over an existing array   -- exit=0  inbounds={'mtu': 1500}
```

The first is the MAJOR, now closed. The second is **R-16** (`01` §12.4, O-12), still out of scope;
stage 5's MINOR-1 sits inside **R-15**. All three are filed in `docs/tasks.md:162-177`; none was
retested as a defect here, and none was touched.

**Out-of-scope observation, needing no new row:** `sc use <tag>` writes `nodes.json["active"]` before
composition, so an aborted `use` leaves the active node changed while `config.json` still names the
old one — a subsequent successful `sc reload` would then switch nodes. This is pre-existing for
*every* malformed-override shape (measured on the unfixed build, §6′.5), is outside
AC-20/AC-21/AC-31, and is not caused by BC-27. Raising it belongs to whoever next opens `cmd_use`,
not to this fix.

### 6′.8 `verify_all`, stability and safety

```
$ bash .harness/scripts/verify_all.sh
[A.1] No hardcoded secrets ... PASS          [E.4b] Hook commands resolve ... PASS
[A.2] No .env files committed ... PASS       [E.5] AI-GUIDE indexes rules ... PASS
[B.1] Syntax (bin/sc, install.sh, ...) PASS  [E.6] Adversarial tests section ... PASS
[B.2] install.sh bilingual key parity . PASS [F.1] AI-GUIDE.md <=200 lines ... PASS
[B.3] Lint ... SKIP                          [F.2] Rule fragments <=200 lines ... PASS
[E.1] Bootstrap files present ... PASS       [F.3] Agent definitions <=300 lines PASS
[E.2] workflow.md present ... PASS           [F.4] insight-index.md <=30 lines .. PASS
[E.3] Agents layout v0.30+ ... PASS          [F.5] docs/tasks.md <=300 lines .... PASS
[E.4] Binding in sync ... PASS               [F.6] Active task docs <=500 lines . WARN

=== Summary ===  PASS: 16   WARN: 1   FAIL: 0   SKIP: 1
```

Identical to §9's working-tree run. **Delta: 0 new FAIL.** The WARN is still F.6 (`01`, `02`, `04` and
this report over 500 lines), which clears on `archive-task`. `verify_all.sh` and its checks were not
edited. `baseline.json` is **still not updated**, for the reason recorded in §9 — no `bin/sc` harness
is committed or wired into `verify_all` (R-9), so the committed test count did not change and raising
it would record tests that do not exist.

Stability — `qa_bc27.py` **10 consecutive runs**, the two long harnesses 3× each:

```
run  1..10: 50 ok, 0 FAILED      (identical every run)
errors run 1..3: 95 ok, 1 FAILED (the R-15 row, every run)
diff   run 1..3: RESULT: PASS — byte-identical config, stderr (all calls), return value and nodes.json
```

No flakes. The FIFO and loop cases are the only timing-sensitive ones and both are alarm-guarded.

Safety, unchanged from §2 and re-asserted at runtime: `assert os.geteuid() != 0` in `qa_common.py`;
all seven path constants asserted inside the temp root and asserted not under `/etc` on every
`repoint()`, plus an explicit re-assertion in `qa_bc27.py::absent()` where `OVERRIDE_PATH` is moved
into a sub-directory; `SB_BIN=/bin/true`; `SYSTEMD = OPENRC = False`; `_init_files()` never driven;
`/usr/local/bin/sc` never invoked; nothing written under `/etc` or `/dev`; `sing-box` never stopped,
started, reloaded or restarted. Every symlink *target* planted in this stage is inside the temp tree —
none points at a real system path.

Service witness at every checkpoint of this stage — start, `qa_bc27` start/end (× 13 runs),
`qa_errors` start/end (× 4), and after `verify_all`:

```
MainPID=2887037
ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST
```

Unchanged at every reading, identical to the T-14 baseline. `/etc/sing-box/config.json` mtime is
still `2026-08-01 10:06:40`, `nodes.json` still `2026-07-30 13:00:32`, and
`/etc/sing-box/override.json` still does not exist.

### 6′.9 What I could NOT verify in this stage (stated, not implied)

1. **BC-19 / `install.sh` step 7.** §12.2 predicts that a host whose link target is unavailable at
   install time now gets `PHASE_CONFIG=failed` instead of a silent discard. O-2 forbids executing
   `install.sh`, and it was not executed. The claim follows from the abort's exit status, which was
   measured; the installer's banner on that path is unverified by execution, exactly as at stage 6.
2. **Real `sing-box` on the new path.** The abort happens before any config is written, so
   `sing-box check` never runs on this input — there is nothing for the real binary to validate. Not
   a gap, but stated so it is not mistaken for one.
3. **A dangling link owned by another user, or on a read-only mount.** `islink` is an `lstat` and
   cannot fail in a way `os.stat` did not already fail differently; not constructible without root,
   which the harness forbids. The neighbouring `EACCES` case is already covered by the pre-existing
   `OSError` arm and its `qa_errors.py` rows.
4. **Concurrency.** A link replaced between `os.stat` and `os.path.islink` would take the "absent"
   branch. `realpath` was chosen precisely because it cannot raise in that window (`04` §17.1), and
   the outcome is at worst the pre-fix behaviour for one run — but no race harness was built for a
   window this narrow on a single-user CLI.

### 6′.10 Verdict

**PASS — APPROVED FOR DELIVERY.**

This **supersedes the `CHANGES REQUIRED (3 defects)` verdict in §1.** MAJOR **D-1** is **closed**:
reproduced red on the unfixed build across 20 independent assertions, green on the fixed one, in both
languages, over ten link shapes and two commands. AC-1 is intact and re-proved on the same unrelaxed
164-run differential against the same `f642ca7` oracle. AC-31 clause 2 holds — the override-less arm
is byte-identical to T-14 *without* the fix, whole tree. The boundary §12.1 drew at the final path
component is the boundary the code draws. D-14, BC-9, AC-27 and AC-28 are unmoved. `verify_all`:
PASS 16 / WARN 1 / FAIL 0 / SKIP 1.

`06` MINOR-A and MINOR-B remain open as **R-15** and **R-16** in `docs/tasks.md`, by the analyst's
ruling in `01` §12.4; they are not defects of T-14 and are not counted against this verdict.

**No new defects were found in this stage.**

### 6′.11 `qa_bc27.py`, verbatim and runnable

Drop next to `qa_common.py` / `qa_semantics.py` from §13, with `sc_baseline.py` (= `f642ca7:bin/sc`)
and `mutant_nofix.py` (= the working tree's `bin/sc` minus the five `islink` lines) in the same
directory. Run `python3 qa_bc27.py [path-to-candidate-sc]`.

```python
#!/usr/bin/env python3
"""T-14 stage 6' — QA's OWN reproducer for BC-27 / AC-31 / D-17.

Written from `01` §12 (Addendum A) and from the pre-change source, NOT from `04` §17's
bc27_test.py. Where it overlaps the developer's test that is convergent evidence; where
it does not (targets containing \\n / \\r / ESC / format braces, a symlink LOOP, a link
pointing THROUGH a broken parent, a parent link that resolves, a second command, the
running-service variant, whole-tree equality rather than per-file equality) it is the
adversarial part.

Every group states a failure hypothesis in its docstring before it runs.

Safety: fixture/loader layer is qa_common.py (docs/dev-map.md recipe verbatim, the
geteuid assertion and the all-seven-paths-inside-temp-root assertion). SB_BIN=/bin/true,
SYSTEMD=OPENRC=False, _init_files() never driven, nothing under /etc, nothing under
/dev, /usr/local/bin/sc never invoked, the real service never touched.
"""
import io
import json
import os
import signal
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qa_common import (PARENT, ROOT, load_module, repoint, seed, tree_snapshot, wipe,
                       witness)
from qa_semantics import ALL_USABLE, N3, SENTINEL, drive_main

CAND = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/home/alan/Programs/singbox-cli/bin/sc")
BASE = Path(__file__).resolve().parent / "sc_baseline.py"
STATE = b"deadbeef" * 8            # a pre-existing drift record: must survive untouched

R = []


def ok(cond, label, detail=""):
    R.append((bool(cond), label, detail))
    print("%s %s%s" % ("ok  " if cond else "FAIL", label,
                       "" if cond else "\n         -- " + detail))


def physical_lines(s):
    return 1 + sum(s.count(c) for c in ("\n", "\r")) if s else 0


class Timeout(object):
    """A hang is a defect, not a hung test run."""

    def __init__(self, secs):
        self.secs = secs

    def __enter__(self):
        signal.signal(signal.SIGALRM, self._boom)
        signal.alarm(self.secs)

    def __exit__(self, *a):
        signal.alarm(0)
        return False

    @staticmethod
    def _boom(*a):
        raise AssertionError("HUNG: exceeded the timeout")


# ------------------------------------------------------------------------------
def malformed(sc, label, plant, lang, argv=("reload",), running=False,
              expect_target=None, expect_marker=None, tree_ignore=()):
    """AC-31 clause 1 + AC-20's three guarantees + AC-21, measured on one fixture.

    Hypothesis: I expect the whole-tree equality check to fail — the developer's own
    test only compares config.json and .config.sha256, so anything else the run touches
    (nodes.json rewritten by `use`, a temp file left behind, a mode change) would slip
    past it and past AC-20's wording as the developer read it.
    """
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, lang=lang, config_bytes=SENTINEL, state_bytes=STATE)
    repoint(sc, lang=lang)
    plant(ROOT / "override.json")
    before = tree_snapshot()
    with Timeout(20):
        r = drive_main(sc, list(argv), lang=lang, running=running)
    after = tree_snapshot()
    msg = r["code"] if isinstance(r["code"], str) else ""
    bad = []
    if r["exc"]:
        bad.append("raised out of main(): %s" % r["exc"])
    if not isinstance(r["code"], str):
        bad.append("exit code %r is not a message string (=> not status 1)" % (r["code"],))
    if after.get("config.json", (None, None))[0] != SENTINEL:
        bad.append("config.json NOT byte-identical")
    if after.get(".config.sha256", (None, None))[0] != STATE:
        bad.append("drift record changed: %r" % (after.get(".config.sha256"),))
    if r["restarts"]:
        bad.append("restart_service called %dx (AC-21)" % r["restarts"])
    if r["err"]:
        bad.append("stderr also written: %r" % r["err"][:120])
    if r["out"]:
        bad.append("stdout written: %r" % r["out"][:120])
    if physical_lines(msg) != 1:
        bad.append("NOT one physical line (%d): %r" % (physical_lines(msg), msg))
    if "\x1b" in msg:
        bad.append("message contains ESC")
    if str(sc.OVERRIDE_PATH) not in msg:
        bad.append("message does not name the override path")
    if "失败：" in msg:
        bad.append("message carries the 失败： grep marker")
    if lang == "zh":
        if "符号链接" not in msg or "不存在" not in msg:
            bad.append("zh message is not really Chinese: %r" % msg)
        if "symbolic link" in msg:
            bad.append("zh message leaked the English key")
    else:
        if "symbolic link" not in msg or "does not exist" not in msg:
            bad.append("en message does not say what is wrong: %r" % msg)
    if expect_target is not None and expect_target not in msg:
        bad.append("message does not name the missing target %r" % expect_target)
    if expect_marker is not None and expect_marker not in msg:
        bad.append("message lost the marker %r" % expect_marker)
    # the strongest form of "nothing was written": the WHOLE tree is unchanged.
    # tree_ignore names files a command legitimately writes BEFORE composition runs
    # (measured, not assumed: see the `use` note in the report).
    delta = sorted(k for k in set(after) | set(before)
                   if after.get(k) != before.get(k) and k not in tree_ignore)
    if delta:
        bad.append("tree changed at %r" % (delta[:5],))
    ok(not bad, "BC-27/AC-31 [%s] %s" % (lang, label), "; ".join(bad) + "\n         msg=%r" % msg)
    return msg


def absent(sc, label, setup, lang, path_attr=None):
    """The narrowed boundary + AC-31 clause 2.

    Hypothesis: I expect the `linkdir` case to RAISE — islink() is true for the parent
    link, and if the implementation had tested `os.path.islink(dirname)` or used
    `lstat` on a resolved path the broken-parent case would fall on the malformed side,
    which is precisely the line §12.1 says must NOT move.
    """
    wipe()
    seed(N3, "osaka-02", ALL_USABLE, lang=lang, config_bytes=SENTINEL, state_bytes=STATE)
    repoint(sc, lang=lang)
    setup(sc)
    if path_attr is not None:
        sc.OVERRIDE_PATH = path_attr(sc)
        p = Path(str(sc.OVERRIDE_PATH))
        assert str(p).startswith(str(PARENT) + os.sep), "escaped the temp root: %s" % p
        assert not str(p).startswith("/etc")
    out, err = io.StringIO(), io.StringIO()
    oo, oe = sys.stdout, sys.stderr
    sys.stdout, sys.stderr = out, err
    got, exc = None, None
    try:
        with Timeout(20):
            got = sc._load_override()
    except BaseException as e:                       # noqa: BLE001 - harness
        got, exc = "<raised>", "%s: %s" % (type(e).__name__, e)
    finally:
        sys.stdout, sys.stderr = oo, oe
    ok(got is None and exc is None and out.getvalue() == "" and err.getvalue() == "",
       "AC-31.2 [%s] %s => silent None" % (lang, label),
       "got=%r exc=%r out=%r err=%r" % (got, exc, out.getvalue(), err.getvalue()))
    with Timeout(20):
        r = drive_main(sc, ["reload"], lang=lang)
    ok(r["code"] == 0 and not r["exc"] and r["restarts"] == 1,
       "AC-31.2 [%s] %s => `sc reload` still succeeds normally" % (lang, label),
       "code=%r exc=%r restarts=%r err=%r" % (r["code"], r["exc"], r["restarts"],
                                              r["err"][:160]))


# ------------------------------------------------------------------ planters
def p_direct(p):
    p.symlink_to(ROOT / "dotfiles" / "sing-box.json")


def p_chain3(p):
    a, b = ROOT / "link-a", ROOT / "link-b"
    b.symlink_to(ROOT / "the-end-is-missing.json")
    a.symlink_to(b)
    p.symlink_to(a)


def p_relative(p):
    os.symlink("dotfiles/sing-box.json", str(p))


def p_dotdot(p):
    os.symlink("../fixture/nope/sb.json", str(p))


def p_control_chars(p):
    os.symlink(str(ROOT / "a\nb\rc\x1b[31md.json"), str(p))


def p_braces(p):
    os.symlink(str(ROOT / "{path}-{target}.json"), str(p))


def p_unicode(p):
    os.symlink(str(ROOT / "配置/覆盖 override.json"), str(p))


def p_through_broken_parent(p):
    # final component IS a link; it points through a directory that does not exist.
    os.symlink(str(ROOT / "no-such-dir" / "sb.json"), str(p))


def p_to_self_loop(p):
    other = ROOT / "loop-b.json"
    os.symlink(str(other), str(p))
    os.symlink(str(p), str(other))


def p_to_fifo(p):
    f = ROOT / "a-fifo"
    os.mkfifo(str(f))
    p.symlink_to(f)


def p_to_dir(p):
    d = ROOT / "a-directory"
    d.mkdir()
    p.symlink_to(d)


# ------------------------------------------------------------------ main
def main():
    witness("qa_bc27:start")
    sc = load_module(str(CAND), "sc_qa_bc27")
    base = load_module(str(BASE), "sc_qa_bc27_base")

    # ---- Group A: BC-27, both languages, six shapes -------------------------
    for lang in ("en", "zh"):
        malformed(sc, "direct dangling link (absolute target)", p_direct, lang,
                  expect_target=str(ROOT / "dotfiles" / "sing-box.json"))
        malformed(sc, "3-link chain, broken at the end", p_chain3, lang,
                  expect_target=str(ROOT / "the-end-is-missing.json"))
        malformed(sc, "relative target", p_relative, lang,
                  expect_target=str(ROOT / "dotfiles" / "sing-box.json"))
        malformed(sc, "relative target with ..", p_dotdot, lang,
                  expect_target=str(ROOT / "nope" / "sb.json"))
        # adversarial: the target is interpolated into a translated template and then
        # into main()'s outer template. A target may legally contain \n, \r and ESC.
        malformed(sc, "target containing \\n, \\r and an ESC/CSI sequence",
                  p_control_chars, lang, expect_marker="a b")
        # adversarial: str.format() applied twice would blow up or leak on braces.
        malformed(sc, "target containing {format} braces", p_braces, lang,
                  expect_target=str(ROOT / "{path}-{target}.json"))
        malformed(sc, "non-ASCII target", p_unicode, lang,
                  expect_target=str(ROOT / "配置" / "覆盖 override.json"))
        # §12.1's boundary, from the MALFORMED side: the final component is itself a
        # link, so it is malformed even though what is missing is a parent of its TARGET.
        malformed(sc, "link pointing THROUGH a directory that does not exist",
                  p_through_broken_parent, lang,
                  expect_target=str(ROOT / "no-such-dir" / "sb.json"))
        # AC-21 with the service believed to be RUNNING, and on a second command.
        malformed(sc, "dangling link, service believed running", p_direct, lang,
                  running=True)
        # `sc use` writes nodes.json["active"] BEFORE composition — measured identical
        # on the UNFIXED T-14 build for an invalid-JSON override, so it is pre-existing
        # T-14 behaviour and outside AC-20/AC-31, which guarantee config.json only.
        malformed(sc, "dangling link, `sc use tokyo-01` (a second command)", p_direct,
                  lang, argv=("use", "tokyo-01"), tree_ignore=("nodes.json",))

    # ---- Group B: AC-31 clause 2, the AC-1-protecting arm --------------------
    # Hypothesis: I expect the extra lstat to change SOMETHING observable — a stray
    # print, a different return value, or a config byte — on the arm every AC-1 point
    # takes. If nothing moves, AC-1 cannot have moved either.
    #
    # TWO oracles, because they answer two different questions:
    #   * vs f642ca7 (pre-T-14): config.json / nodes.json bytes, streams, return value.
    #     NOT the whole tree — T-14 legitimately ADDS .config.sha256 (BC-16), so a
    #     whole-tree comparison here would fail for the unfixed build too (measured).
    #   * vs mutant_nofix (T-14 minus the five-line islink block): the WHOLE tree,
    #     including the drift record. This is the exact "the fix changed nothing on
    #     this arm" question, and nothing legitimately differs.
    nofix = load_module(str(Path(__file__).resolve().parent / "mutant_nofix.py"),
                        "sc_qa_bc27_nofix")

    def build(mod, lang):
        wipe()
        seed(N3, "osaka-02", ALL_USABLE, lang=lang, state_bytes=STATE)
        repoint(mod, lang=lang)
        out, err = io.StringIO(), io.StringIO()
        oo, oe = sys.stdout, sys.stderr
        sys.stdout, sys.stderr = out, err
        try:
            rv = mod.generate_config()
        finally:
            sys.stdout, sys.stderr = oo, oe
        return rv, out.getvalue(), err.getvalue(), tree_snapshot()

    for lang in ("en", "zh"):
        b_rv, b_out, b_err, b_tree = build(base, lang)
        n_rv, n_out, n_err, n_tree = build(nofix, lang)

        wipe()
        seed(N3, "osaka-02", ALL_USABLE, lang=lang, state_bytes=STATE)
        repoint(sc, lang=lang)
        out, err = io.StringIO(), io.StringIO()
        oo, oe = sys.stdout, sys.stderr
        sys.stdout, sys.stderr = out, err
        try:
            got = sc._load_override()
        finally:
            sys.stdout, sys.stderr = oo, oe
        ok(got is None and out.getvalue() == "" and err.getvalue() == "",
           "AC-31.2 [%s] no entry at the override path => silent None" % lang,
           "got=%r out=%r err=%r" % (got, out.getvalue(), err.getvalue()))

        c_rv, c_out, c_err, c_tree = build(sc, lang)
        shared = ("config.json", "nodes.json")
        ok(c_rv == b_rv and c_out == b_out and c_err == b_err
           and all(c_tree.get(k) == b_tree.get(k) for k in shared),
           "AC-1 [%s] override-less build still matches the f642ca7 PRE-CHANGE build "
           "(config.json + nodes.json bytes, both streams, return value)" % lang,
           "rv=%r/%r out=%r/%r err=%r/%r diff=%r"
           % (c_rv, b_rv, c_out[:80], b_out[:80], c_err[:80], b_err[:80],
              [k for k in shared if c_tree.get(k) != b_tree.get(k)]))
        ok(c_rv == n_rv and c_out == n_out and c_err == n_err and c_tree == n_tree,
           "AC-31.2 [%s] override-less build identical to T-14 WITHOUT the islink block "
           "— whole tree, drift record included" % lang,
           "rv=%r/%r treediff=%r" % (c_rv, n_rv,
                                     sorted(k for k in set(c_tree) | set(n_tree)
                                            if c_tree.get(k) != n_tree.get(k))[:5]))

    # ---- Group C: the narrowed boundary, ABSENT side -------------------------
    for lang in ("en", "zh"):
        absent(sc, "no entry at all", lambda s: None, lang)
        absent(sc, "broken PARENT: dangling directory link",
               lambda s: os.symlink(str(ROOT / "no-such-dir"), str(ROOT / "linkdir")),
               lang, path_attr=lambda s: ROOT / "linkdir" / "override.json")
        absent(sc, "broken PARENT: no directory at all", lambda s: None, lang,
               path_attr=lambda s: ROOT / "missing-dir" / "override.json")
        absent(sc, "PARENT is a link that RESOLVES, final component missing",
               lambda s: (os.mkdir(str(ROOT / "realdir")),
                          os.symlink(str(ROOT / "realdir"), str(ROOT / "okdir"))),
               lang, path_attr=lambda s: ROOT / "okdir" / "override.json")

    # ---- Group D: D-14 and BC-9 must be exactly where they were --------------
    for lang in ("en", "zh"):
        wipe()
        seed(N3, "osaka-02", ALL_USABLE, lang=lang, config_bytes=SENTINEL)
        repoint(sc, lang=lang)
        real = ROOT / "dotfiles" / "sing-box.json"
        real.parent.mkdir()
        real.write_text('{"log": {"level": "debug"}}')
        (ROOT / "override.json").symlink_to(real)
        with Timeout(20):
            r = drive_main(sc, ["reload"], lang=lang)
        doc = json.loads(sc.CFG_PATH.read_text()) if sc.CFG_PATH.exists() else {}
        ok(r["code"] == 0 and not r["exc"] and doc.get("log", {}).get("level") == "debug"
           and doc.get("log", {}).get("timestamp") is True and r["restarts"] == 1,
           "D-14 [%s] symlink -> REGULAR file with a valid override is still applied"
           % lang, "code=%r exc=%r log=%r" % (r["code"], r["exc"], doc.get("log")))

        # BC-9's guard: stat-before-open, and a NON-regular target is still 'not a
        # regular file' — not the new symlink message, and never a hang.
        for label, plant, want_en in (
                ("symlink -> FIFO", p_to_fifo, "not a regular file"),
                ("symlink -> directory", p_to_dir, "not a regular file")):
            wipe()
            seed(N3, "osaka-02", ALL_USABLE, lang=lang, config_bytes=SENTINEL)
            repoint(sc, lang=lang)
            plant(ROOT / "override.json")
            with Timeout(20):
                r = drive_main(sc, ["reload"], lang=lang)
            msg = r["code"] if isinstance(r["code"], str) else ""
            want = want_en if lang == "en" else "不是普通文件"
            ok(want in msg and "symbolic link" not in msg and "符号链接" not in msg
               and sc.CFG_PATH.read_bytes() == SENTINEL and r["restarts"] == 0,
               "BC-9 [%s] %s still reports 'not a regular file', no hang" % (lang, label),
               "msg=%r restarts=%r" % (msg, r["restarts"]))

        # A symlink LOOP: os.stat raises ELOOP, not FileNotFoundError, so it must land
        # in the pre-existing OSError arm, not in the new one, and must not traceback.
        wipe()
        seed(N3, "osaka-02", ALL_USABLE, lang=lang, config_bytes=SENTINEL)
        repoint(sc, lang=lang)
        p_to_self_loop(ROOT / "override.json")
        with Timeout(20):
            r = drive_main(sc, ["reload"], lang=lang)
        msg = r["code"] if isinstance(r["code"], str) else ""
        ok(isinstance(r["code"], str) and not r["exc"] and physical_lines(msg) == 1
           and str(sc.OVERRIDE_PATH) in msg and sc.CFG_PATH.read_bytes() == SENTINEL
           and r["restarts"] == 0,
           "BC-9 [%s] a symlink LOOP aborts in one line, no traceback, no hang" % lang,
           "code=%r exc=%r msg=%r" % (r["code"], r["exc"], msg))

    wipe()
    witness("qa_bc27:end")
    nfail = sum(1 for x, _, _ in R if not x)
    print("\n%d ok, %d FAILED" % (len(R) - nfail, nfail))
    if nfail:
        print("FAILED labels:")
        for good, label, _ in R:
            if not good:
                print("  - " + label)
    return 1 if nfail else 0


if __name__ == "__main__":
    sys.exit(main())
```
