# 05 — Code Review — config-degrade-missing-rulesets (T-02)

> Persistence note (PM): the code-reviewer agent ran without Write/Bash tools in this session;
> this document is its returned output persisted verbatim by the PM Orchestrator. No PM edits.

**Verification limitation (stated, not hidden):** no shell in this session. `git diff`, `git show main:bin/sc`, `python3 -m py_compile`, and `verify_all` were **not** re-executed. The "before" state was reconstructed from the path:line evidence in `01`/`03` (independently corroborated: every anchor those docs cite still resolves to the code they describe). Scope (AC-25) was verified by **content inspection** of `install.sh`, `uninstall.sh`, `systemd/*` — not by byte comparison. Where a criterion needed execution I say so rather than assume.

## Files reviewed
- `/home/alan/Programs/singbox-cli/bin/sc` (whole file; rule-set section `:45-74`, `:127-140`, `:491-711`, `:716-826`, `:1073-1127`, `:1282-1289`, `:1334-1340`, `:1384-1385`)
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`
- `/home/alan/Programs/singbox-cli/README.md` `:104-118`
- `/home/alan/Programs/singbox-cli/README.zh-CN.md` `:104-118`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/install.sh` `:448-487`, `/home/alan/Programs/singbox-cli/uninstall.sh` `:110-125`, `/home/alan/Programs/singbox-cli/systemd/sing-box-rules-update.service` (scope check)
- No test files exist (`B.2`/`B.3` still `SKIP`, per Q8/T-07).

## Findings

### CRITICAL
None.

### MAJOR
None.

### MINOR

- **[MAINT] `bin/sc:617-620` vs `:630` — the declared `_temp_path()` drift is justified by a claim that is factually false.** `04_DEVELOPMENT.md:148-151` says the helper exists because "`_clear_stale_temps` needs to construct the same prefix … rather than write the expression twice". It doesn't use it: `_clear_stale_temps` builds `prefix = fname + ".tmp"` independently at `:630`, and `_temp_path` has exactly **one** caller (`:1082`). So the `".tmp"` literal is still written twice, and the two are coupled only by convention — change the suffix in `_temp_path` and stale-temp cleanup silently stops matching, including the legacy-name path F-5 exists to cover. The drift is still *accepted* (3 lines, no behavioural difference, name is well chosen), but the reason recorded for it does not hold. Suggested: `_temp_prefix(fname)` used by both, or have `_clear_stale_temps` derive its prefix from `_temp_path(fname).name.rsplit(".", 1)[0]`.

- **[LOGIC] `bin/sc:578-581` — dropping `rule_set` from a rule that has another matcher *broadens* that rule.** sing-box rule fields are ANDed, so `{"action":"reject","network":["udp"],"rule_set":["x"]}` with `x` unusable becomes `{"action":"reject","network":["udp"]}` — a strictly wider reject. `02_SOLUTION_DESIGN.md:157-158` claims the filter "degrades toward `final` rather than toward a broadened match"; that is true only of the *drop* branch, not this one. The branch is **dead against today's config** (all seven rule-set rules at `:763,764,767,788,790,793,794` are exactly `{answer-key, rule_set}`) and is mandated verbatim by B-5, so this is not a defect today. But the comment at `:579` ("Still matches on something else: drop only the reference, keep the rule.") should say that the surviving rule matches **more** than it did, so a future author adding a mixed-matcher rule-set rule is warned.

- **[MAINT] `bin/sc:796-800` vs `:543-545` — the definition list re-tests `status == "usable"` instead of consulting `usable`.** `usable` is computed at `:724` and drives both `_filter_rules` calls, but the `route.rule_set` comprehension filters by `status == "usable"` again. Both read the same immutable `report`, so they cannot disagree *today* — but this is one more place the "is it usable?" test is spelled out, which is the exact smell rule 85 targets and which the design's own §12 deletion-test argument leans on. `for tag, fname, status in report if tag in usable` would leave literally one expression of the fact. (This is the second declared drift — "comprehension over `report` rather than `RULESET_FILES`" — and that part is fine: same source tuple, same order, tag already computed. Accepted; only the predicate duplication is worth changing.)

- **[SEC] `bin/sc:1075` + `:77-78` — `--mirror` crosses the sudo boundary; the requirement's security NFR says it doesn't.** `01_REQUIREMENT_ANALYSIS.md:228` states "The mirror override is only effective for a caller who is already root (E-13, BC-25)". That is true for `SB_RULES_BASE` (env is stripped by `env_reset`) but **false for `--mirror`**: `os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])` preserves argv verbatim, which is exactly why `README.md:116` says "Prefer `--mirror`". Consequence: any user covered by `NOPASSWD: /usr/local/bin/sc` can direct root's fetch at an arbitrary URL, and `urllib.request.urlopen` accepts `file://` — so `--mirror file:///some/dir` makes root copy `<dir>/geoip/cn.srs` into the world-readable `/etc/sing-box/rules/`, gated only by the `SRS` magic and the 16-byte floor. **Practical impact is negligible** (the same caller can already run `sc uninstall`, `sc add <attacker node>`, `sc off` as root, so no privilege is gained) and no numbered behavior is violated — BC-24 is satisfied because a genuinely unsupported scheme raises `URLError` and is reported per-base. Recorded as a stale security statement plus an undocumented `file://` surface; a scheme allow-list (`http`/`https`) would be a one-line hardening, but adding it here would exceed B-14 and BC-24 as written. Recommend a pool row, not a change in this task.

- **[LOGIC] `bin/sc:559-583` — `_filter_rules` does not recurse into `type: "logical"` sub-rules.** The "dangling reference is structurally impossible" property holds for flat rules only; a nested `{"type":"logical","mode":"and","rules":[{"rule_set":[...]}]}` would bypass the filter entirely. No such rule exists in the config literal and §4 item 11 forbids adding one in this task, and `docs/dev-map.md:73-74` already carries the guard rail. Note only.

- **[MAINT] `docs/dev-map.md:34,37` — two inaccuracies in the file the developer agent reads before writing code.** `:34` names the share-link dispatcher `parse_link`; the actual symbol is `parse_share_url` (`bin/sc:474`). `:37` places `restart_service()` / `reload_or_restart()` under `# Clash API`; they live in the `# Config generation` section (`bin/sc:829,836`), before the `# Clash API` header at `:843`.

### NIT

- `bin/sc:1128` — one blank line between `cmd_update_rules` and `cmd_update_interval`; every other top-level function in the file is separated by two.
- `bin/sc:127` — the new `# rule-sets: …` comment now visually captures three pre-existing keys that follow it (`"→ Restarting sing-box ..."`, `"Done"`, `"Reloaded"`, `:141-143`). Moving the new block after them, or adding a closing `# status / output` marker, restores the grouping.
- `bin/sc:591` — `"%s (%s)" % (...)` in a file that otherwise uses f-strings / `.format`.
- `bin/sc:1117-1119` — `print(t("Rule-sets restored…"))` immediately followed by `print("\n" + t("→ Restarting sing-box ..."))` emits a stray blank line. The `"\n"` was carried over from `main`, where it separated the restart notice from the last file's completion line.
- `bin/sc:1075` — `getattr(args, "mirror", None)`; the attribute always exists (`:1385` sets `default=None`), and design §6.2 writes `args.mirror`. Harmless defensiveness.
- `bin/sc:522-524` — `stat()` then `open()` is a two-step read of one file. BC-29's "complete old or complete new, never a blend" is guaranteed for the *bytes* by `replace()`, but `(size, head)` can straddle the swap. Cannot yield a wrong verdict in practice (only validated files are ever installed, so both versions pass). `os.fstat(fh.fileno())` inside the same `open` would make it exact.
- `bin/sc:1098-1100` — a purely local failure (disk full, `replace()` EPERM) marks the *base* dead, so files 2-4 then fail fast with "skipped" causes rather than each attempting. BC-18's "the run continues with the remaining files" is still literally true, and this is Q6's sanctioned semantics; noting it because the emitted cause will name mirrors for what is a local-disk fault.
- **B-16 wording vs. built behaviour** — `:1122` exits non-zero when a *download* failed, even if the on-disk rule-set is still usable (BC-17). B-16's literal text says "non-zero when at least one rule-set is unusable"; **AC-13 explicitly requires the built behaviour** and it preserves `main`'s contract that `install.sh:456` branches on. Correct as built; flagged so it is not re-litigated later.
- Not this task's, but for PM's Q9 pool row: `subprocess.run(..., text=True)` is also **3.7+** and sits at `bin/sc:822` and `:1159`. The row currently tracks only `capture_output=` at `:822`, `:864`, `:1159`.

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| B-1 one usability definition | `srs_reject_reason` `bin/sc:496-508` (only definition of magic+floor) | ✅ |
| B-2 per-file status, one shape | `ruleset_status:511-527` flat token; consumed by `:723`, `:702`, `:548` | ✅ |
| B-3 invocable in isolation | `ruleset_report:530-540` — stat + 3-byte read, no net/service/config, no writes | ✅ |
| B-4 only usable rule-sets defined | `:796-800`; empty ⇒ key deleted `:812-813` | ✅ |
| B-5 every dangling ref dropped, both lists | `_filter_rules:559-583` called at `:814` **and** `:815` with the same `usable` | ✅ |
| B-6 per-file degradation | per-tag set membership, no all-or-nothing branch | ✅ |
| B-7 core config untouched | `:740-808` literal unchanged; only `rule_set` + the two `rules` arrays are rewritten | ✅ |
| B-8 bilingual warning, real counts, both commands, two wordings | `_warn_degraded:586-602`; `n=len(bad), total=len(report)`; `:592` selects the wording | ✅ |
| B-9 degradation is not an error | `generate_config` returns `True` unless `sing-box check` fails (`:823-826`) | ✅ |
| B-10 relpath + ordered bases, slash tolerance | `:59-71`; `base.rstrip("/") + "/" + relpath` `:1092` | ✅ |
| B-11 bases tried in order until one validates | `:1087-1104` with `break` on success | ✅ |
| B-12 validate before install | `:699-705` (length equality + magic + floor) precedes `tmp.replace` `:1095` | ✅ |
| B-13 dead base not retried in-run | `dead.add(base)` `:1099`, `if base in dead` `:1088` | ✅ |
| B-14 `--mirror` > `SB_RULES_BASE`, replace, whitespace-only = absent | `_ruleset_bases:605-614` | ✅ |
| B-15 cause names every base, stdout | `causes` incl. `skipped` entries `:1089-1090`; `print(t("failed: {e}", …))` `:1108` | ✅ |
| B-16 exit-status contract | `:1122-1123` `sys.exit` (stderr, non-zero) | ✅ (see NIT) |
| B-17 automatic recovery | `:1110-1121`, `CFG_PATH.exists()` guard, `generate_config()` not a patch, restart only if running | ✅ |
| B-18 TTY progress | `:691-698`, per-chunk redraw, `%` only when `declared` | ✅ |
| B-19 non-TTY: no `\r`, one line/file | both writers guarded by `if tty` (`:691`, `:707`); cause is one joined line | ✅ |
| B-20 chunked read | `r.read(65536)` loop `:682-690`; whole-body `read()` gone | ✅ |
| B-21 temp-then-replace, unique | `_temp_path:617-620` pid suffix; `tmp.replace` `:1095` same dir | ✅ |
| B-22 no damage, no debris | `except` ⇒ `tmp.unlink()` `:1101-1104`; stale sweep `:623-658` | ✅ (killed-run debris cleaned at next fetch, exactly as B-22 sentence 2 provides) |
| B-23 bilingual parity, matching placeholders | 11 new keys `:128-140`; concatenated call-site literals at `:593-601` match the table keys character-for-character; placeholder sets identical | ✅ |
| B-24 help + both READMEs | `:1282-1289` / `:1334-1340`; `README.md:106-118` / `README.zh-CN.md:106-118` matching positions | ✅ |
| B-25 Python 3.6 floor | new code uses only 3.6-legal constructs; `unlink(missing_ok=)` gone; no walrus / f-string `=` / `dict \|` / `dataclasses` / `capture_output=` / `text=` added | ✅ |
| B-26 diff boundary | `install.sh:448-487`, `uninstall.sh:110-125`, `systemd/sing-box-rules-update.service` carry no rule-set-related edit and still show their pre-existing state (incl. the T-09 `/usr/local/bin/proxy` defect) | ✅ by inspection (no byte-diff available) |
| AC-1 / AC-2…AC-27 | executed by the developer's throwaway harness (225 assertions) per `04_DEVELOPMENT.md:98-141`; not re-executable here | ⚠️ dev-reported, QA to re-run independently |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| §3.1 constants block verbatim | `bin/sc:49-74` | ✅ |
| §3.2 `srs_reject_reason` order: too-small then bad-magic | `:504-507` | ✅ |
| §3.2 `ruleset_status` symlink/dir/OSError ladder | `:516-527` | ✅ |
| §3.2 `_status_text` a **function**, not a module-level dict | `:548-556` | ✅ (the `LANG`-freeze trap avoided) |
| §3.3 one `_filter_rules`, no array-name param | `:559`, called `:814,815` | ✅ |
| §3.3 `_warn_degraded` → stderr (Q4) | `:602` | ✅ |
| §3.4 `_fetch_to_temp(url, tmp, prefix, tty)` signature + TTY cursor contract | `:661-711` incl. the `finally` redraw | ✅ |
| §4 empty `rule_set` ⇒ key deleted, not `[]` | `:812-813` | ✅ |
| §4 temp name = `fname + ".tmp." + pid` | `:620` | ✅ |
| §4 comprehension over `RULESET_FILES` | over `report` instead | ⚠️ declared drift — **accepted** (same tuple, same order, tag pre-computed; see MINOR #3 for the one predicate nit) |
| §4/§6.2 temp name inline | extracted to `_temp_path` | ⚠️ declared drift — **accepted** (3 lines, no behaviour change; stated justification is wrong, see MINOR #1) |
| §5.2 stream split | causes/`OK`/`Restored`/`Restarting`/`Done` on stdout; aggregate + `⚠️` on stderr | ✅ |
| §5.3 single-line multi-base cause, `\033[K` erase, no throttle | `:1108`, `:697,710`, one redraw per chunk | ✅ |
| §5.4 11 keys, no namespaced keys, `⚠️` outside `t()` | `:128-140`, `:602` | ✅ |
| §6.2 recovery **before** `sys.exit`; `CFG_PATH.exists()` guard; restart only if `ok and is_running()` | `:1110-1123` | ✅ |
| §6.2 order preserved: exit → then the ordinary restart → `Done` | `:1122-1127`, identical to `main`'s `:821-825` shape | ✅ |
| §12 counter-rule (no new file/module/config key/command) | one section header, two constants, one predicate, `--mirror` only | ✅ |
| Timeouts unchanged (=3, =8, =30) | `bin/sc:852`, `:1011`, `:674` | ✅ |
| **Undeclared drift** | none behavioural found (only `getattr` vs `args.mirror`, a NIT) | ✅ |

## The five binding gate conditions

| # | Condition | Evidence | Status |
|---|---|---|---|
| F-1 | magic accumulated across chunks | `:688-690` — `if len(head) < len(SRS_MAGIC): head = (head + chunk)[:len(SRS_MAGIC)]`, inside the read loop. A 1-byte first `read()` cannot produce a false `bad-magic`; `srs_reject_reason` also short-circuits on `too-small` first, so a genuinely tiny body is never mislabelled. | ✅ |
| F-2 | `{names}` as `tag (status phrase)` | `:591` — `", ".join("%s (%s)" % (tag, _status_text(status)) …)`; `_status_text` therefore has a config-side consumer. | ✅ |
| F-4 | defensive `Content-Length` | `:676-680` — `except (TypeError, ValueError) → declared = None`, plus `declared < 0 → None`. Absent/garbage takes the BC-14 path and does **not** mark the base dead. `if declared:` at `:692` also makes a declared `0` non-fatal (no `ZeroDivisionError`). | ✅ |
| F-5 | absent/non-integer suffix = stale | `:640-652` — exact `<name>.tmp` (legacy fixed name) skips the pid block entirely ⇒ removed; `int()` failure ⇒ `pid = -1` ⇒ removed; `pid <= 0` ⇒ removed; only a live foreign pid is spared (`ProcessLookupError` ⇒ dead, other `OSError`/EPERM ⇒ live). A real `.srs` can never match the prefix. | ✅ |
| F-6 | no `Accept-Encoding` added | `:674` — `urllib.request.urlopen(url, timeout=30)` with a bare URL string; no `Request`, no headers anywhere in the new code. | ✅ |

## Single-judgment property (rule 85)

**Deletion test — passes.** Remove `srs_reject_reason` (`:496-508`) and the magic/floor logic must reappear in **two** live places immediately (`ruleset_status:527`, `_fetch_to_temp:702`) plus wherever `sc doctor`/T-05 lands. That is >1, so the abstraction earns its place.

**One judgment, not three — confirmed structurally, not by assertion.** `generate_config` calls `ruleset_report()` exactly once (`:723`) and derives `usable` once (`:724`); that one set drives the definition list and *both* reference arrays through *one* `_filter_rules`. `cmd_update_rules` consults the same `ruleset_report()` for `before`/`after` (`:1077`, `:1110`) rather than tracking its own success flags — so "did this run help?" is answered by the same predicate that answers "should this be in the config?". Progress display is not a fourth notion: it is inside the same fetch that validates.

**Counter-rule — holds.** No new file, module, package, config key, settings key, persisted state, dependency, or command. The additions are two constants, one predicate, three adapters, four thin helpers, one section header, and one CLI flag mandated by B-14. `RULE_ANSWER_KEYS` + the other-matcher branch remain ~4 lines and did not grow into a matcher taxonomy, exactly as the gate conditioned.

**Sole residue:** the "is it usable?" test is spelled twice (`usable_tags:545` and the comprehension at `:799`) — MINOR #3, harmless because both read the same `report`.

## No dangling rule-set references

Exhaustive grep of `bin/sc` for the four tag strings returns exactly ten sites: the four `RULESET_FILES` filenames (`:60-63`), the three `dns.rules` references (`:763, 764, 767`), the four `route.rules` references (`:788, 790, 793, 794`), and the definition comprehension (`:796-800`). **There is no third referencing site.** Both reference arrays are reassigned from `_filter_rules(..., usable)` at `:814-815`, and the definitions come from the same `report` — so `referenced ⊆ defined` is a structural consequence, not a discipline. The only way to escape it is a nested `type: logical` rule (MINOR #5), which does not exist and which `docs/dev-map.md:73-74` already warns against.

## Python 3.6 floor across the diff

Every construct in the new/rewritten region is ≤3.6: f-string `:1083`, `frozenset` `:74`, generator into `set()` `:545`, `%`-format `:591`, `os.getpid` `:620`, `Path.iterdir/open/unlink/replace/is_symlink/is_file/stat`, `os.kill` + `ProcessLookupError` `:647-651`, `str.split/rstrip`, `print(..., end="", flush=True)`, `argparse action="append"`, `sys.stdout.isatty()`, `getattr`, `sorted(set - set)`. **No** walrus, f-string `=`, `dict |`, `dataclasses`, `capture_output=`, `text=`, or `unlink(missing_ok=)` is added. The three pre-existing `capture_output=` sites survive untouched at `:822`, `:864`, `:1159` — confirmed as the separate filed row, not this task's defect (with the `text=` addendum noted above).

## Other dimension notes

- **Performance.** One `stat` + one 3-byte read per rule-set per report (12 syscalls per `update-rules` run, 3 per config generation) on a path already dominated by a `sing-box check` subprocess. Download memory is bounded at 64 KiB. `_clear_stale_temps` does one `iterdir()` per file — four listings of a ≤8-entry directory. Time budget: `dead` is populated on *any* failure and a base can be marked at most once, so timeout-paying attempts per run ≤ `len(bases)` — the gate's tightened bound is what the code implements. No N+1, no unbounded loop, no new sync I/O on a hot path.
- **Atomicity.** Validation (`:699-705`) strictly precedes `tmp.replace(target)` (`:1095`); every exception path unlinks the temp (`:1101-1104`) and never touches the real path. Same-directory rename ⇒ true atomic swap. BC-17/BC-18/BC-29 hold.
- **stdout/stderr split.** Per-file cause via `print` (`:1108`), aggregate via `sys.exit` (`:1123`), degradation warning via `sys.stderr.write` (`:602`). T-01's install-log reader and `install.sh:456`'s exit-status branch are both intact; `install.sh` itself is untouched.
- **Tests.** None committed — deliberate, adjudicated at Q8/GR V-9 and recorded in `.harness/rejected-decisions.md`; T-07 owns the harness. Rule 50's "first task that *adds* a build/test/lint command must replace the SKIP" is not triggered (no command was added). The developer's 225-assertion harness is scratchpad-only and must be handed to QA/T-07 rather than discarded — flagging for PM, not as a defect.
- **Bilingual parity.** All 11 new keys present with identical placeholder sets; both multi-line call-site literals concatenate to exactly their table keys (checked character-by-character, including the trailing spaces at `:593`/`:594` and `:598`/`:599`); zh strings use full-width parentheses so no stray `{}` can raise `KeyError`; every new English key is readable prose, no `ls.idx`-style namespacing. Help and both READMEs carry `--mirror` + `SB_RULES_BASE` in matching positions.

## Axis status
- **Standards-conformance:** 2 findings, worst = **MINOR** (`_temp_path` coupling `bin/sc:617/630`; `docs/dev-map.md:34,37` inaccuracies), plus 8 NITs. Bilingual parity, Python 3.6 floor, the three owner-fixed timeouts, the stdout/stderr split, the non-TTY no-`\r` rule, doc-size caps, and the dev-map obligation all conform. No invented rules applied.
- **Spec/design-fidelity:** 4 findings, worst = **MINOR** (AND-rule broadening `:578-581`; duplicated `status == "usable"` predicate `:799`; `--mirror`-vs-sudo security-NFR staleness `:1075`; non-recursive `_filter_rules` `:559`). All 26 numbered behaviors implemented; both declared drifts accepted with reasons; no undeclared behavioural drift found; all five binding gate conditions verified in code.

## Verdict

**APPROVED** (0 CRITICAL, 0 MAJOR, 6 MINOR, 8 NIT)

---

## Delta review — D-1 / Amendment A-1

> Appended 2026-07-31 after the developer's fix pass (`04_DEVELOPMENT.md` § `Fix pass — D-1 /
> Amendment A-1`). This is a **delta re-review**, scoped to the A-1 change plus the two in-scope
> corrections; everything above this line stands as written and is not re-litigated.
>
> Persistence note (PM): this session also had no Write tool; section persisted verbatim by the PM.
>
> **Verification limitation (same as the first pass, stated not hidden):** no shell in this session.
> `git diff`, `python3 -m py_compile bin/sc` and `verify_all.sh` were **not** re-executed. The claim
> "nothing else in `bin/sc` moved" is evidenced below by line-offset arithmetic against the anchors
> this document already recorded, which detects insertions/deletions but not a same-size in-place
> edit. The developer's `verify_all` table (16/0/0/2, delta 0) and his AC re-runs are dev-reported;
> QA re-runs them at stage 7.

### Files reviewed (delta)
- `/home/alan/Programs/singbox-cli/bin/sc` — `:140`, `:560-588`, `:1078-1144` (whole `cmd_update_rules`), plus `:610-639`, `:666-716` re-read as unchanged context
- `/home/alan/Programs/singbox-cli/CHANGELOG.md` `:7`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md` `:34,36,37`
- `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` `:37-47` (the A-1 record)

### 1. Does the fix close D-1?

**Yes, structurally — not by enumeration of cases.** There is exactly **one** rejection path out of
the inner loop: `_fetch_to_temp()` raises on transport failure, on `HTTPError` (non-2xx), on
`got != declared` (truncation) and on any `srs_reject_reason()` rejection — all of them, plus a
failing `tmp.replace(target)`, land in the single `except Exception as e:` at `bin/sc:1113`, which
builds `entry` **once** and appends it to **both** lists (`:1115-1117`). There is no second `except`,
no `continue` that skips the append, and no early `break` inside the `try`. So "contacted and
rejected" ⇒ "in `tried`" holds for every path, including the paths QA counted among D-1's nine
swallowed causes (truncated / zero-length bodies). `tried` is then rendered on the surviving
completion line at `:1108-1111`.

Information-conservation argument (the property D-1 actually asked for): a base's *real* cause is
emitted exactly once per run, on the first file where it failed — either on that file's
`OK (...); fell back after: ...` line (a later base worked) or inside that file's `failed: ...` line
(all bases exhausted). On every subsequent file the base is `dead` and contributes only the
`skipped (...)` text to `causes`. There is no run in which a base is contacted, rejected, and never
named. **D-1 closed.**

### 2. A-1 fidelity — two lists, dead-skips excluded

| A-1 clause | Implementation | Status |
|---|---|---|
| `causes` unchanged — every base in list order, dead-skips included, feeds the total-failure line | `:1097`, `:1101-1103`, `:1116`; printed unchanged at `:1125` via the same `t("failed: {e}")` | ✅ |
| `tried` — only bases contacted and rejected **for this file** | `:1098`, appended only at `:1117` inside `except` | ✅ |
| Dead-skips contribute **nothing** to `tried` | `:1100-1103` appends to `causes` then `continue` — the `tried.append` is unreachable from that branch | ✅ real, not nominal |
| Rendered by the **same `print`** onto the **same** completion line | `:1108-1111` — `print(t("OK ({size} bytes)", size=got) + note)`, one call, one `\n` | ✅ |
| `tried` empty ⇒ no note | `note = (... if tried else "")` `:1108-1109`; `"" ` concatenated, no separator, no format artifact | ✅ |
| Both lists reset per file | `:1097-1098` inside the `for fname, relpath` body, above the base loop | ✅ |
| `dead` still populated on any failure (B-13/Q6, timeout budget) | `:1114` before the appends | ✅ unchanged |

The dead-skip exclusion is what stops a single broken mirror from repeating its cause on all four
files; verified at the branch level above, and it is the reason files 2-4 of a base-1-dead run stay
byte-identical to `main`'s shape.

### 3. AC-3 / happy-path invariance

`note` is the empty string when `tried` is falsy, and it is **concatenated**, not joined or
`format`-substituted — so with base 1 answering the emitted bytes are exactly
`t("OK ({size} bytes)", size=got) + "" + "\n"`, i.e. character-for-character `main`'s line. No stray
`; `, no space, no `[]`/`()` artifact, and the leading `; ` lives *inside* the key so it cannot leak
when the note is absent. `_fetch_to_temp` is untouched, so the non-TTY path still writes nothing
before the completion line. **AC-3's config-side comparison is unaffected by construction** — the fix
is confined to `cmd_update_rules`' stdout; `generate_config()` was not edited (`# Config generation`
starts at `:719` and no anchor inside it moved relative to the +5 offset).

### 4. AC-15 — one completion line, no `\r` on a pipe

- One `print` per success (`:1111`), one per total failure (`:1125`), mutually exclusive via
  `break`/`for…else`. The note cannot add a line.
- Every `\r` and `\033[K` in the module is still inside `if tty:` guards (`:696-703`, `:711-716`);
  the delta added no writer.
- **A newline cannot enter the note**: base URLs come from `_ruleset_bases` (`:616,618`), which uses
  `str.split()` — whitespace-splitting, so a `\n` inside `--mirror`/`SB_RULES_BASE` becomes a base
  separator and can never survive into a base string. `str(e)` for `URLError`/`HTTPError`/our own
  `ValueError(t(...))` carries no newline (the HTTP reason phrase is line-delimited by
  `http.client`). So AC-15 holds structurally, not just for the tested fixtures.

### 5. AC-13 — the total-failure shape did not move

`causes` construction, the `skipped (this source already failed in this run)` text (`:1102`), the
`print(t("failed: {e}", e="; ".join(causes)))` line (`:1125`) and the stderr aggregate
`sys.exit("\n" + t("{n} ruleset(s) failed to update", ...))` (`:1140`) are all byte-unchanged from
the approved pass. Nothing in the delta touches the `for…else` branch.

### 6. stdout/stderr split

Preserved. The note travels on stdout inside the existing per-file `print`; stderr still carries only
the aggregate (`:1140`) and `_warn_degraded`'s warning (`:591-607`). T-01's install-log reader and
`install.sh:456`'s exit-status branch see the same streams and the same exit contract — the note is
emitted on a **success**, so it changes no exit status.

### 7. The new translation key

- `bin/sc:140` — `"; fell back after: {causes}": "；已回退，前序镜像失败：{causes}"`. Placeholder set
  `{causes}` in both languages; call site `:1108` passes exactly `causes=` and nothing else ⇒ no
  `KeyError`, no unused kwarg (`t()` at `:211-213` does `msg.format(**kwargs)`, so a mismatch either
  way would raise).
- Cause text is passed as a **value**, never as a format template, so a `{` in a URL or an exception
  message cannot raise (R7's failure mode is not reachable here).
- English key is readable prose and un-namespaced (no `ls.idx` style) — when `LANG == "en"` the key
  itself is printed, which reads correctly appended to `OK (n bytes)`. Text matches §5.4 verbatim,
  including the intentional leading `; `.
- Key is placed inside the `# rule-sets:` comment block (`:127-141`), consistent with the other ten.

**MINOR finding, see below:** the zh rendering contains the substring `失败：`.

### 8. Python 3.6 floor / timeouts

Delta constructs: string `+`, `list.append`, `"; ".join`, a conditional expression, `t()` kwargs.
All ≤3.6. No walrus, no f-string `=`, no `capture_output=`/`text=`/`missing_ok=`, no dict-merge added.
Timeout constants re-grepped in the current file: `bin/sc:679` `timeout=30` (ruleset download),
`:857` `timeout=3` (Clash API), `:1016` `timeout=8` (egress IP) — **three constants, three values,
unchanged**, and no fourth `timeout=` exists.

### 9. Developer-declared items — adjudication

**(a) `DESIGN DRIFT (documentation only)` — the CHANGELOG clause. Accepted, no finding.**
A-1 does not mention `CHANGELOG.md`, but `02` §2's file list and AC-25's diff scope both include it,
and A-1 changes user-visible output — leaving the existing bullet describing an output shape that no
longer exists would be the worse outcome. I read the clause (`CHANGELOG.md:7`) against the code and
both of its claims are accurate: the cause is appended after that rule-set's result line in the
`；已回退，前序镜像失败：<镜像> -> <原因>` form, and it is absent when the first mirror works. It
also correctly does *not* promise per-file repetition (which the dead-skip exclusion prevents).
Declaring it was the right call; it is documentation tracking behaviour, not drift.

**(b) D-4 now also reachable on a success line. Agreed — note only, belongs to the existing D-4 row.**
`tmp.open()`/`tmp.replace()` `OSError`s are caught by the same `except` (`:1113`), so a local-disk
fault still produces a mirror-flavoured cause *including the internal temp path* — and via `tried`
that text can now appear on an `OK (...)` line, i.e. in `install.log` on a run that otherwise
succeeded. This is a widening of D-4's surface, not a new defect, and A-1's shape makes it
unavoidable without changing D-4's root cause (a local fault classified as a base failure). The D-4
pool row should record this second surface so whoever fixes it tests both lines.

### 10. The two in-scope corrections

| Item | Verified against code | Status |
|---|---|---|
| `docs/dev-map.md:34` — dispatcher named `parse_share_url` | `bin/sc:475 def parse_share_url(url)` ✔; the row's section title `# Share-URL parsers` now also matches the real header at `bin/sc:247` | ✅ (fixes prior MINOR #6, and a second inaccuracy that MINOR #6 did not name) |
| `docs/dev-map.md:36-37` — `restart_service()`/`reload_or_restart()` under `# Config generation`; `# Clash API` keeps `clash_api()`/`is_running()` | `bin/sc:834`, `:841` sit inside `# Config generation` (`:719`) and before `# Clash API` (`:848`); `clash_api()` `:850`, `is_running()` `:864` | ✅ |
| `bin/sc:580-584` — AND-semantics warning comment at the other-matcher branch | Comment now states the survivor matches **MORE**, gives the `{network: udp, rule_set: X}` → "all udp" example, notes the branch is dead for today's config and that a mixed-matcher rule would be silently broadened. Code lines `:579`, `:585-586` are unchanged ⇒ **behaviour untouched**, B-5 still mandated verbatim | ✅ (fixes prior MINOR #2 / QA D-3, comment-only as asked) |

### 11. Regression check — nothing else moved, nothing got worse

Line-offset arithmetic against this document's own anchors gives a fully consistent picture of
**exactly three** edit sites in `bin/sc` and no others:

| Anchor (first pass) | Now | Offset |
|---|---|---|
| `_filter_rules` def `:559` | `:560` | +1 (the one new translation key at `:140`) |
| `_fetch_to_temp` def `:661`; `timeout=30` `:674` | `:666`; `:679` | +5 (+4 from the 4 added comment lines in `_filter_rules`) |
| `timeout=3` `:852`; `timeout=8` `:1011`; `cmd_update_rules` def `:1073` | `:857`; `:1016`; `:1078` | +5 |
| `def cmd_update_interval` `:1129`; `HELP_ZH` `:1334`; `--mirror` argparse `:1385` | `:1146`; `:1351`; `:1402` | +17 (+12 inside `cmd_update_rules`: 6 comment, `tried = []`, 2 note lines + 1 comment, `entry` + `tried.append`) |

Uniform offsets on both sides of each edit ⇒ no insertion or deletion anywhere else in the file
(a same-size in-place edit would be invisible to this method — flagged as the residual).

Prior findings re-checked, none worsened:

| Prior finding | State |
|---|---|
| MINOR #1 `_temp_path` prefix coupling (`:622` vs `:635`) | unchanged, still open (PM-deferred row) |
| MINOR #2 AND-broadening comment | **fixed** this pass |
| MINOR #3 duplicated `status == "usable"` predicate | unchanged |
| MINOR #4 `--mirror` vs sudo (D-2) | unchanged, out of scope by instruction |
| MINOR #5 non-recursive `_filter_rules` | unchanged |
| MINOR #6 dev-map inaccuracies | **fixed** this pass |
| NIT one blank line before `cmd_update_interval` (`:1145`) | unchanged |
| NIT `# rule-sets:` comment grouping (`:127`) | unchanged in kind (one more key under it) |
| NIT `%`-format `:596`, `getattr` `:1080`, `stat`+`open` `:527`, stray blank line `:1136`, B-16 wording | all unchanged |
| NIT local fault reported as a mirror failure | **one more surface** — see §9(b) |

### Findings (delta)

#### CRITICAL
None.

#### MAJOR
None. D-1 is closed (§1).

#### MINOR
- **[I18N/MAINT] `bin/sc:140` — the zh note contains `失败：`, which is exactly the grep that A-1's own
  rejected-decisions record says a *successful* line must not match.**
  `.harness/rejected-decisions.md:44-45` declines reusing the `failed: {e}` key on the ground that
  "it would make a *successful* line match the `failed:` / `失败：` grep that today means 'this file
  was not updated'." The chosen zh string `"；已回退，前序镜像失败：{causes}"` contains `失败：`
  verbatim — the same substring produced by `"failed: {e}" → "失败：{e}"` (`bin/sc:126`). So the
  stated protection holds in English (`fell back after:` shares nothing with `failed:`) and is
  defeated in Chinese: `grep '失败：' install.log` now matches lines where the rule-set **was**
  updated. **The developer is not at fault** — `02` §5.4 specifies this string character-for-character
  and it was implemented exactly; this is a defect in the design text, caught only by reading the two
  governance documents against each other. No automated consumer greps it today (`install.sh:456`
  branches on exit status), so impact is a human reading a zh `install.log` — MINOR, not blocking.
  Cheapest fix, if the architect concurs: drop the collision from the zh string, e.g.
  `"；已回退，前序镜像未成功：{causes}"` or `"；已回退，前序镜像报错：{causes}"` (one-token change in
  `bin/sc:140` and `02` §5.4; placeholder set unchanged, AC-14 unaffected).

#### NIT
- `bin/sc:1091-1096` — a 6-line comment guarding two 1-line declarations. Earns its place (the
  `causes`/`tried` split is exactly the invariant a future editor would collapse), but it now
  restates A-1 nearly in full; two lines plus the design pointer would carry the same warning.
- `bin/sc:1108` — attacker-influenced text (`--mirror` values, remote error strings) now reaches a
  **success** line as well as the failure line. Bounded (`len(bases) - 1` entries, one real cause per
  base per run, no newline possible per §4) and identical in kind to the pre-existing failure-line
  exposure, so no action here; noted because A-1 widened where it lands.

### Requirement coverage check (delta only — the ACs A-1's own re-run list names)

| Criterion | Implementation | Status |
|---|---|---|
| AC-10 "assert the failure of base 1 appears in the output" | `:1117` (append) → `:1108-1111` (render) | ✅ static; dev-reproduced |
| AC-11 "the output names bases 1 and 2 with distinct causes" | same; one `entry` per contacted base, joined with `"; "` | ✅ static; dev-reproduced |
| AC-3 output/JSON unchanged when nothing is wrong | `note == ""` concatenated (§3); `generate_config()` untouched | ✅ |
| AC-12 dead-base hit counts | `dead.add(base)` `:1114`, `if base in dead` `:1100` — unchanged | ✅ |
| AC-13 total-failure line + stderr aggregate unmoved | `:1125`, `:1140` byte-unchanged (§5) | ✅ |
| AC-14 bilingual parity, no `KeyError` | `:140` vs call site `:1108` (§7) | ✅ static |
| AC-15 one completion line, no `\r` on a pipe | one `print`; all `\r` writers still `if tty` (§4) | ✅ |
| AC-16 / AC-17 TTY redraw, no `%` without a declared length | `_fetch_to_temp` untouched; the `finally` redraw still precedes the completion line | ✅ |
| AC-18 truncation cause now visible | `ValueError` from `:705-706` → `except` → `tried` | ✅ |
| AC-21 / AC-23 override precedence, exit status | `_ruleset_bases` and the `failed`/`sys.exit` path untouched | ✅ |
| AC-25 / AC-26 diff scope, 3.6 floor, timeouts | product diff unchanged in shape; constants 30/3/8 re-grepped; delta constructs all ≤3.6 (§8) | ✅ static (no byte diff available) |

### Design fidelity check (Amendment A-1)

| A-1 item | Implementation | Status |
|---|---|---|
| `tried` list, populated only in the `except` | `bin/sc:1098`, `:1117` | ✅ |
| `causes` semantics unchanged | `:1097`, `:1101-1103`, `:1116`, `:1125` | ✅ |
| Dead-skip excluded from `tried` | `:1100-1103` `continue` before the `try` | ✅ |
| One `print`, one line | `:1111` | ✅ |
| Key text + both translations exactly as §5.4 | `:140`, call site `:1108` | ✅ (see MINOR — the design's zh text itself collides with `失败：`) |
| Rejected shapes not implemented (second line / stderr / reusing `failed: {e}`) | no second `print`, no `sys.stderr` in the delta, distinct key | ✅ |
| No timeout, stream, exit-status or config-side movement | §5, §6, §8 | ✅ |
| §9 R4 TTY-wrap note (line terminated before the next prefix) | `print` ends the line; next iteration writes `prefix` fresh at `:1089` | ✅ |
| CHANGELOG clause (declared, not in A-1) | `CHANGELOG.md:7` — accepted, §9(a) | ✅ |

### Axis status (delta)
- **Standards-conformance:** 1 finding, worst = **MINOR** (`bin/sc:140` zh `失败：` collision vs
  `.harness/rejected-decisions.md:44-45`), plus 2 NITs. Bilingual parity, the 3.6 floor, the three
  owner-fixed timeouts, the stdout/stderr split, the non-TTY no-`\r` rule and the dev-map obligation
  all conform; the dev-map row is now *more* accurate than before this pass. No invented rules
  applied.
- **Spec/design-fidelity:** **no findings.** Amendment A-1 is implemented exactly as revised — two
  lists, dead-skips excluded, one `print`, one new key; both developer-declared items adjudicated as
  acceptable (§9); no undeclared drift found, and no prior-pass design item regressed.

### Verdict (delta)

**APPROVED** — 0 CRITICAL, 0 MAJOR, 1 MINOR, 2 NIT.
D-1 is closed structurally (single rejection path ⇒ single append site ⇒ every contacted-and-rejected
base is named), the dead-skip exclusion is real, and the happy path is byte-identical by
construction. Aggregate for the task remains **APPROVED**; the running MINOR count is 5 open
(2 of the original 6 fixed this pass) + 1 new, all non-blocking. The one new MINOR is a design-text
defect, not a developer defect — route it to the architect as a one-token zh amendment or accept it
as documented residue, but do not roll back the code for it.
