# 04 — Development · T-19 `ruleset-staleness-visibility`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).
>
> Mode: **full** · Single-developer (no `.harness/agents/dev-*.md` partitions). Implemented in
> `02`'s `## Migration & edit sequence` order, 1 → 6. Three units the PM's dispatch requires in this
> contract fit no declared section shape on this project (`.harness/rules/70-doc-size.md` defines no
> `## Stage-doc boundary rule` — the E-20 gap stages 2 and 3 recorded); they are carried below as
> named sections and the gap is restated in `## Open issues for review`.

## Summary

1. `ruleset_state()` now returns `(status, digest, size, mtime)` from one read — `os.fstat()` on the
   same open handle — `ruleset_states()` carries it as a 6-tuple, `_age_text(mtime)` renders it, and
   `sc status` prints one `=== Rule-sets ===` row per rule-set unconditionally.
2. `restart_service()` returns a bool, and `cmd_update_rules()`'s tail derives one `ok` expression
   that feeds both the four-branch outcome line and the single `sys.exit(1)`.
3. `bin/sc` +80 / −29 against C-6's +80 / −30 ceiling; `verify_all` at the batch baseline; one
   DESIGN DRIFT (an added `sys.stdout.flush()`), measured, not assumed.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | `import time`; 7 `TRANSLATIONS["zh"]` entries; `ruleset_state()` 4-tuple + widened DIGEST CONTRACT; `ruleset_states()` 6-tuple; three destructuring sites starred; new `_age_text()`; `sc status` rule-set section; `restart_service()` → bool; `cmd_update_rules()` tail (one determination, four-branch outcome, one exit site); `HELP_EN` / `HELP_ZH` `status` line | E-1 … E-10, C-1 |
| `/home/alan/Programs/singbox-cli/README.md` | line 245 — `sc status`'s one-line description gains `rule-set status + age` | E-11 |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` | line 245 — its line-for-line mirror (`规则集状态与更新时间`) | E-12 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | one entry at the top of `### 新增` under `## [Unreleased]`, Chinese, covering both halves | E-13 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | `## Reusable utilities` only: the on-disk-reader row and the per-file-snapshot row corrected, one row added for `_age_text()` | E-14 |

Nothing else was touched. `docs/tasks.md`, `docs/batches/**`, `.harness/**`, `install.sh`,
`uninstall.sh` and every `systemd/*` file are unmodified by this stage. (`git status` shows
`docs/batches/default/BATCH_PLAN.md` modified and `docs/batches/default/BATCH_LOG.md` untracked —
both were already in the working tree when this stage started; they are the PM's, not mine.)

## Per-edit-id size accounting (C-6)

`git diff --numstat` per hunk, attributed to the ledger id whose old-file range it falls in.

| edit id | surface | `02` estimate | actual (+/−) | note |
|---|---|---|---|---|
| E-1 | `import time` | ≈ +1 | +1 / −0 | as estimated |
| E-2 | `TRANSLATIONS["zh"]`, 7 keys | ≈ +7 | +7 / −0 | as estimated |
| E-3 | `ruleset_state()` | ≈ +14 / −6 | +15 / −12 | 8 of the adds and 7 of the deletes are the docstring; the estimate under-counted the deletes, because widening the DIGEST CONTRACT edits existing lines rather than adding new ones. Reflow was minimised deliberately (only the lines the widening falsifies were touched) to stay under the ceiling |
| E-4 | `ruleset_states()` | ≈ +2 / −2 | +3 / −3 | +1/−1 over estimate: the docstring's first line states the tuple shape and would otherwise be false |
| E-5 | `_status_view()`, `changed_usable_tags()` ×2 | ≈ +3 / −3 | +3 / −3 | as estimated (A-6 form, below) |
| E-6 | `_age_text()` | ≈ +18 | +18 / −0 | as estimated |
| E-7 | `_doctor_rulesets()` | ≈ +1 / −1 | +1 / −1 | as estimated |
| E-8 | `cmd_status()` section | ≈ +4 | +4 / −0 | 3 code lines + 1 comment recording K-6's placement |
| E-9 | `restart_service()` | ≈ +8 / −4 | +10 / −2 | the `else: return True` arm and `return r.returncode == 0` are additions, not replacements, so adds are higher and deletes lower than the estimate's shape |
| E-10 | `cmd_update_rules()` tail | ≈ +14 / −8 | +15 / −6 | includes the one DESIGN DRIFT line (`sys.stdout.flush()`) |
| C-1 | `HELP_EN` + `HELP_ZH` | not in `02`'s ledger (gate finding F-1) | +3 / −2 | EN wraps onto a continuation line at column 30 (the `add` / `doctor` precedent); ZH fits on one line |
| **`bin/sc` total** | | | **+80 / −29** | ceiling **+80 / −30** — not exceeded, no overrun to answer against rule 85 |
| E-11 | `README.md` | 1 line | +1 / −1 | |
| E-12 | `README.zh-CN.md` | 1 line | +1 / −1 | |
| E-13 | `CHANGELOG.md` | one entry | +2 / −0 | entry + blank line |
| E-14 | `docs/dev-map.md` | ≈ +1 / −2 (F-11: really +3/−2) | +3 / −2 | two rows corrected, one row added, same table, nothing else — matches F-11's corrected arithmetic |

**A-6 — the smaller form was taken.** All three destructuring edits use starred unpacking
(`for tag, fname, status, *_rest in states`, `... digest, *_rest in before/after`,
`... _digest, size, *_rest in states`), not a named placeholder per element. Reason: identical line
count today, valid at the 3.6 floor (PEP 3132, Python 3.0), and it removes these same three edits
from T-20 and from every later widening of the snapshot tuple — the future edit rule 85 asks a
refactor to name. `_status_view()` remains the shield: its **return** is still 3 elements, so
`_runtime_overlay():1815`, `usable_tags():905` and `_warn_degraded():976` (A-1's real destructuring sites)
were not touched.

**C-1 — the help-line edit.** `HELP_EN`'s `status` line now reads
`Show service status, TUN interface, rule-set status + age,` with `active node, egress IP` on a
continuation line; `HELP_ZH`'s reads `查看服务状态、TUN 接口、规则集状态与更新时间、当前节点、出口 IP`.
Descriptions still start at column 30 in both blocks (the continuation line starts at column 30
too, matching `add`'s and `doctor`'s existing sub-lines). No translation key was added — the two
help blocks are printed literals, not `t()` call sites. Both enumerations use the same words as
`README.md:245` / `README.zh-CN.md:245`, edited in the same commit as E-8.

## verify_all result

```
baseline (before any edit): PASS 17 / WARN 0 / FAIL 0 / SKIP 1
after (final):              PASS 17 / WARN 0 / FAIL 0 / SKIP 1
delta:                      0 new FAIL, 0 new WARN, baseline preserved
command:                    bash .harness/scripts/verify_all.sh
```

Final run, verbatim:

```
=== Summary ===
  PASS: 17
  WARN: 0
  FAIL: 0
  SKIP: 1
```

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| D-1 | K-13 — "replace `sys.exit("\n" + t(...))` with `sys.stderr.write("\n" + t(...) + "\n")` **in the same position**, so the aggregate's stream, wording, leading newline and single-line shape stay byte-identical (BC-8 freeze)" | The replacement is exactly as specified, **plus one added line immediately before it**: `sys.stdout.flush()` (`bin/sc:2869`). One line beyond the ledger, inside E-10 | K-13 as written is byte-identical on each stream *separately* but **not** on the merged stream `install.sh:567` actually captures (`>>file 2>&1`), and A-3 asserted the interleaving was unchanged. Measured: at HEAD `sys.exit(<str>)` is handled by the interpreter, which flushes stdout **before** writing the string, so the aggregate lands after all stdout; a mid-run `sys.stderr.write` lands **before** the still-buffered stdout, splitting a per-file line in two. With the flush, the candidate's merged capture is byte-identical to HEAD's (transcript in `04_RATIONALE.md`). Answered against rule 85: it is one line that removes a regression rather than adding a mechanism, and it is the cheapest form — no envelope, no wrapper (K-15 intact) |

No other deviation. Everything else follows `02` as written, including I-3's `"%-20s %s, %s"` format
(see the first `## Open issues for review` row for the consequence I noticed but did not change).

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| C-1 | **discharged** | `bin/sc` `HELP_EN` `status` line + continuation, `HELP_ZH` `status` line; both name the rule-set section, descriptions still at column 30, no `t()` key added, same commit as E-8/E-11/E-12. Per-edit-id row above |
| C-2 | **owned by stage 6** — nothing done here that presumes it | RS-4's cost is real and unchanged by implementation: `cmd_status()` now performs four full `.srs` reads (`ruleset_states()`), plus exactly one `fstat` per file on an already-open handle. No network, no service, no subprocess added |
| C-3 | **owned by stage 6** | Every observation below is reported with its own control class; the two freezes (AC-B4, AC-B7) are labelled as freezes and are never quoted as evidence of a change |
| C-4 | **owned by stage 6; the pair was already observed here** | The section printed in **both** `is_running()` states: `False` arm (`SYSTEMD = OPENRC = False`, `is_running():2038` returns `False` without consulting any port — port silence is not the lever) and `True` arm (`SYSTEMD = True`, stubbed `systemctl is-active` → 0). Captures in `## Self-verification` |
| C-5 | **discharged for every fixture this stage built** | Every step that set `SYSTEMD = True` ran in a child process and assigned `sc.subprocess = <stub module>`; the real module's `run` was never mutated. The stub is total and closed — canned result per enumerated argv, `raise AssertionError` on anything else. Full call log quoted per run below. Live-service witness: `systemctl show -p MainPID -p ActiveEnterTimestamp sing-box` → `MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`, i.e. unchanged across this stage (dated three days before it) |
| C-6 | **discharged; stage 5 re-runs it** | `bin/sc` +80 / −29 against +80 / −30. Per-edit-id table above. `git diff docs/dev-map.md` is +3 / −2: two rows corrected, one row added, same table, no section added or removed, no other row altered, no row deleted |
| C-7 | **owned by stage 7** | AC-B9 / P-6 was not observed here and was not substituted: no agent in this pipeline touched the live unit |
| C-8 | **owned by stage 6; the risk it guards was found and removed here** | The merged `2>&1` capture of the all-mirrors-fail run is byte-identical between HEAD and candidate **because of** D-1; without D-1 it was not. Transcript in `04_RATIONALE.md` |

## Self-verification

Fixture form (scratchpad only — never committed, out-of-scope item 8): `docs/dev-map.md`'s
module-load recipe with the `os.geteuid` shim; all **eight** path constants repointed into a
`mkdtemp()` root **with an assertion that each resolves inside it**; `sc.SB_BIN` a repointed stub;
`sc.LANG` set explicitly; the fixture's own `settings.json` carrying `clash_api_port`;
`_init_files()` never driven; `/usr/local/bin/sc` never invoked; no step drives `main()` — each
calls `sc.cmd_status(...)` / `sc.cmd_update_rules(...)` / `sc.generate_config()` directly.

The C-5 stub, quoted in full:

```python
def stub_subprocess(table, log):
    """A TOTAL and CLOSED subprocess stub (C-5).

    `table` maps an explicitly enumerated argv tuple to (returncode, stdout, stderr).
    Any other argv raises, so nothing can reach a real systemctl / rc-service / sing-box.
    """
    mod = types.ModuleType("subprocess")

    def run(argv, *args, **kwargs):
        argv = list(argv)
        log.append(argv)
        key = tuple(argv)
        if key not in table:
            raise AssertionError("STUB REFUSED un-enumerated argv: %r" % (argv,))
        rc, out, err = table[key]
        return _Result(argv, rc, out, err)

    mod.run = run
    ...
    return mod
```

installed as `sc.subprocess = fixture.stub_subprocess(table, log)` — the loaded module's own
namespace. The real `subprocess` module object is never mutated.

| step | run | result | control at HEAD (pristine `git clone`, `84c8d8b`) |
|---|---|---|---|
| S-1 (AC-B1) | `cmd_status()`, stdout to a file, 4 fixture `.srs`: fresh / `os.utime` −30 d / absent / a directory | `=== Rule-sets ===` then 4 rows in `RULESET_FILES` order: `geoip-cn.srs usable, 0 seconds ago` · `geosite-cn.srs usable, 30 days ago` · `geosite-google.srs missing, last update unknown` · `geosite-private.srs unreadable, last update unknown` | **disagrees** — HEAD prints no rule-set section at all (`ValueError: '=== Rule-sets ===' is not in list`) |
| S-2 (AC-B2, BC-1, BC-2) | same capture, per-line | both unavailable rows read `last update unknown` (zh `更新时间未知`); no digit anywhere in the suffix after the filename | disagrees (no section) |
| S-3 (BC-5) | same fixture with `RULES_DIR` deleted | 4 rows, each `missing, last update unknown`; `RULES_DIR` still does not exist after the run | disagrees |
| S-4 (BC-4) | one `.srs` `os.utime`'d to now + 1 h | `0 seconds ago` (zh `0 秒前`); no `-`, no warning | disagrees |
| S-5 (BC-3) | readable 0-byte `.srs`, direct `ruleset_state()` | `("too-small", "e3b0c442…b855", 0, 1786696011.699…)` — a real digest, a real `0` **and** a real mtime | disagrees (3-tuple at HEAD) |
| S-6 (BC-6 / C-4) | `cmd_status()` with `SYSTEMD = True`, stubbed `systemctl is-active` → 0, `_egress_ip` stubbed to raise | section printed in the `True` arm too; stub log `[['systemctl','status','--no-pager','-n','5','sing-box'], ['ip','-br','addr','show','sb-tun'], ['systemctl','is-active','--quiet','sing-box']]` — no argv escaped the stub, no `restart` | disagrees |
| S-7 (AC-B4, **freeze**) | two `generate_config()` runs at the **same** fixture path, timestamps current then −30 d | identical bytes (5650), `route.rule_set` identical, 4 entries | **agrees by construction** — never quoted as evidence of a change |
| S-8 (FR-5 differential, **freeze**) | HEAD and candidate `generate_config()` at the **same** fixture root | both `sha256 8a58bd64dc4f…8746`, 5666 bytes | agrees by construction |
| S-9 (AC-B5, BC-9) | child process, `file://` mirror, existing `config.json`, `SYSTEMD = True`, stubbed `check` → 1 | **exit 1**; no `config regenerated` line; outcome `… — the sing-box service was not touched`; stub log `[[SB_BIN,'check','-c',CFG]]` — **no** `systemctl` at all | **disagrees** — HEAD exits **0**, prints `Rule-sets restored: … — config regenerated` **and** `Done` (P-3 confirmed) |
| S-10 (AC-B6, BC-10) | as S-9 but `check` → 0, `systemctl restart` → 1 | **exit 1**; outcome `… — the sing-box service could not be restarted` (zh `…—— sing-box 服务重启未成功`); stub log has exactly one `['systemctl','restart','sing-box']` | **disagrees** — HEAD exits **0** and prints `… — sing-box restarted to load them` + `Done` (P-4 confirmed) |
| S-11 (restart succeeds) | as S-10 but `restart` → 0 | exit 0, `… — sing-box restarted to load them`, `Done` | agrees — byte-identical to HEAD |
| S-12 (AC-B7 / BC-11, **freeze**) | child run, `file://` mirror serving byte-identical content | exit **0**, `No rule-set changed — the sing-box service was not touched`, `Done`, stub log **empty** | agrees at HEAD by design |
| S-13 (AC-B7 / BC-8, **freeze**) | child run, mirror base pointed at a non-existent local path (no network) | exit **1**; per-file `failed: …` causes on stdout; one `4 ruleset(s) failed to update` on stderr preceded by a blank line; one outcome line | agrees on exit and on each stream; **merged `2>&1` capture byte-identical only after D-1** |
| S-14 (BC-12) | fresh install: no `config.json`, rule-sets gained | exit 0, no `generate_config()` call (`SB_BIN` absent from the stub log), no service action | agrees |
| S-15 (AC-B8) | outcome-line count across S-9 … S-14 | exactly **1** line from I-6's closed set per run in every state; `Done` present only on the three zero-exit runs; the one `config regenerated` claim appears only on runs where `generate_config()` returned `True` | per-observation classes as columned |
| S-16 (AC-S2, BC-7) | table read of the 7 new keys + `\r` byte scan of **33** captured streams | all 7 present in `zh` with equal placeholder sets, none containing `失败`; `TRANSLATIONS` still has no `en` table; **0** streams contain `\r` | — |

Every `[B]` step was additionally run with `sc.LANG = "zh"` for the rendering assertions
(S-1 … S-5, S-10, S-12): `可用, 30 天前` · `缺失, 更新时间未知` · `0 秒前` ·
`规则集已更新：… —— sing-box 服务重启未成功` · `规则集内容无变化 —— 未改动 sing-box 服务` + `完成`.

**AC-B9 is BLOCKED and was not substituted** — it needs root and the live unit, which K-18 forbids
every agent in this pipeline. The only service observation made here is the read-only
`systemctl show -p MainPID -p ActiveEnterTimestamp` witness quoted under C-5. **BC-13 (V-14)** was
not exercised at this stage; it is stage 6's, and K-15 is satisfied structurally (no envelope, no
`try/finally`, no `atexit`, no wrapper was added).

## AC-S1 static sweep

`grep -n "st_mtime\|getmtime\|os\.stat\|\.stat()\|st_ctime\|st_atime\|fstat" bin/sc`:

| line | hit | verdict |
|---|---|---|
| 816 | `mtime = os.fstat(fh.fileno()).st_mtime` inside `ruleset_state()`'s existing `with` / `try` | **the one timestamp query** (K-1, K-3) |
| 776, 785 | `ruleset_state()` docstring prose | not a query |
| 1388 | `st = os.stat(str(OVERRIDE_PATH))` in `_load_override()`, read through `S_ISREG` (`st_mode`) | **the known non-timestamp hit A-2 predicted** — `:1359` at `03`'s line numbering, `:1388` after this stage's +29 lines above it. It reads no timestamp. The assertion is "exactly one site reads `st_mtime`", not "exactly one `os.stat` in the file"; it is reported, not papered over, and the assertion is not widened |

`grep -n "_age_text" bin/sc` → `925: def _age_text(mtime)` and `2272:` the single call site in
`cmd_status()`. **One renderer, one call site, signature `(mtime)`** — no `sc status`-specific
argument, so T-20's `sc doctor` row consumes it unchanged. `st_size` still appears nowhere (K-2).

## Open issues for review

- **Schema gap (restated).** `.harness/rules/70-doc-size.md` on this project defines no
  `## Stage-doc boundary rule`, so `## Per-edit-id size accounting (C-6)`, `## Self-verification`
  and `## AC-S1 static sweep` — all three required by the PM's dispatch in this contract — fit no
  declared section shape. Written as named sections rather than forced into an existing one, per
  the E-20 precedent set at stages 2 and 3.
- **The zh rule-set row uses an ASCII `, ` separator.** I-3 fixes the format as
  `"%-20s %s, %s"` in code, so under `LANG=zh` the row reads `可用, 30 天前` while `sc doctor`'s
  equivalent row reads `可用，5572 字节` — doctor localises the separator because it lives inside
  the key `"{reason}, {size} bytes"` (`bin/sc:278`). Implemented as designed; flagged as a
  follow-up row below rather than drifted.
- **RS-5 confirmed in the shipped output.** `_age_text()` pluralises like the existing
  `{n} ruleset(s)` keys, so `1 days ago` is reachable (a 36-hour-old file). Deliberate per Q-11;
  it is now observable rather than hypothetical.
- **Fixture hazard for stage 6.** A redirected `cmd_status()` fixture whose `settings.json` says
  `clash_api_port: 29090` reaches the **live** sing-box on this host: S-6's capture printed
  `=== Route mode === / Rule`, i.e. `clash_api("GET", "/configs")` was answered by the real
  instance. Read-only here (`sc status` only ever GETs), but a fixture that issued a `PUT`/`PATCH`
  would mutate the running service. Stage 6 should pick a port it has proved free, or state that
  the only Clash call in the step is a GET.

## Dev-map updates

- `## Reusable utilities` — "One file's on-disk facts" row: return shape corrected to
  `(status, digest, size, mtime)`, the equivalence chain extended with `mtime is None`, and the
  `os.fstat()`-on-the-same-handle rule (never a second `stat()` of the path) stated.
- `## Reusable utilities` — "Per-file rule-set state" row: `ruleset_states()` corrected from
  "digest **and size** appended (5-tuples)" to "digest, size **and mtime** appended (6-tuples)", and
  the shielded-sites attribution corrected in the same line to the three that really destructure the
  3-tuple — `_runtime_overlay():1815`, `usable_tags():905`, `_warn_degraded():976` — with
  `generate_config()` named as passing `report` through and destructuring nothing (F-14 / A-1).
- `## Reusable utilities` — one row added: "How old is this rule-set file?" → `_age_text(mtime)`,
  naming the vocabulary, the word form, the no-threshold rule and the must-stay-a-function reason.
- No section added or removed, no other row's text altered, no row deleted (`+3 / −2`).

## Insight to surface

- `sys.exit(<str>)` is handled by the interpreter, which flushes stdout **before** writing the string to stderr, so replacing it with an in-run `sys.stderr.write` reorders the merged `2>&1` capture `install.sh` records — the aggregate lands ahead of the still-buffered stdout and splits a per-file line in two — unless an explicit `sys.stdout.flush()` is added first · evidence: bin/sc:2869
- A redirected `bin/sc` fixture that repoints the eight path constants is still not isolated from the live sing-box: `CLASH_PORT` 29090 is the port the real instance listens on here, so `cmd_status()`'s `clash_api("GET","/configs")` was answered by the running service (`Route mode: Rule`) from inside a fully redirected temp root · evidence: bin/sc:2277

## Verdict

**READY FOR REVIEW**
