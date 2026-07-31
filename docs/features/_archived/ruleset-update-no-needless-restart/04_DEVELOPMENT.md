# 04 — Development Record · T-10 `ruleset-update-no-needless-restart`

- **Task**: T-10 · **Mode**: full · **Date**: 2026-07-31 · **Deferred-human**: `defer, do not ask`
- **Upstream**: `01` = READY · `02` = READY (rev. 2, 495 lines) · `03` = `APPROVED FOR DEVELOPMENT`, C-1…C-11 binding
- **Implemented**: `02` §10.5 in order, under C-1…C-11. `01`/`02`/`03` were read-only.
- Repo root for every relative path below: `/home/alan/Programs/singbox-cli`.

## Summary

`sc update-rules` no longer treats "the run finished" as "something changed". The existing single
on-disk rule-set query gained one field — `ruleset_state(path)` returns `(status, digest)` from one
chunked read — so the run's before/after snapshots answer both "which rule-sets became usable"
(`gained`, drives config regeneration) and "whose installed bytes really changed"
(`changed_usable_tags`, drives the apply) from the same bytes. The unconditional tail
`if not applied and is_running(): restart_service()` is gone; there is now exactly one apply
decision per run, guarded by the change set, plus one truthful run-level outcome line in both
languages. No new file, no new dependency beyond stdlib `hashlib`, no exit-status change, no
change to the download loop or to the generated config.

## Files changed

Product diff is exactly `bin/sc` + `CHANGELOG.md` + `docs/dev-map.md` (C-8). `+141/−28`, `+2/−1`,
`+4/−2` respectively.

### `bin/sc` (`+141/−28`, file now 1536 lines)

**Every line number in this table is POST-change** (working tree, `bin/sc` = 1536 lines). The only
pre-change citations in this document are labelled `pre-change` inline, in C-4 and C-6 below.

| Line(s), post-change | Change |
|---|---|
| `:5` | `import hashlib` — the only import added; stdlib, 3.6-safe, no wheel/network/privilege. |
| `:143-145` | Three new `TRANSLATIONS["zh"]` keys, placed beside the existing `Rule-sets restored:` key. |
| `:516-558` | **`ruleset_state(path) -> (status, digest)`** — new; takes over the old `ruleset_status` body. Same `path.exists()` / symlink / `is_file()` / `except OSError` branches; the `open()` is extended from "read the magic" to "stream the whole file", accumulating `head`, the **real** byte count (replacing `st_size`) and a `hashlib.sha256()`. Chunked at 65536 via the `while True: … if not chunk: break` shape (`:527-536`). The binding digest contract is in the docstring (`:517-534`) and honoured by the body. |
| `:561-573` | **`ruleset_status(path)`** — now a 2-line status-only view, `ruleset_state(path)[0]`. Retained; the docstring states it has no in-tree caller and why (see *Decisions* below). |
| `:575-588` | **`ruleset_states()`** — new. `[(tag, filename, status, digest), …]` in `RULESET_FILES` order. THE snapshot. |
| `:591-596` | **`_status_view(states)`** — new. 4-tuples → 3-tuples. Three call sites: `ruleset_report()` and the two snapshots in `cmd_update_rules`. |
| `:599-605` | `ruleset_report()` — **contract unchanged**, reimplemented as `_status_view(ruleset_states())`. |
| `:608-636` | **`changed_usable_tags(before, after)`** — new, pure. Sorted tags usable in `after` whose digest differs from `before`, paired **by tag through dicts** (`:623`), never by index (F-10). |
| `:639-641`, `:655-683`, `:686-702`, `:816-926` (incl. `:899`), `:929-933`, `:945-956`, `:959-965` | **Not touched.** Per function, post-change: `usable_tags()` `:639-641` · `_filter_rules()` `:655-683` · `_warn_degraded()` `:686-702` · `generate_config()` `:816-926`, whose 3-tuple destructuring `for tag, fname, status in report if status == "usable"` is `:899` · `restart_service()` `:929-933` · `clash_api()` `:945-956` · `is_running()` `:959-965`. |
| `:1177` | `before = usable_tags(ruleset_report())` → `before = ruleset_states()`. |
| `:1180-1216` | The download loop — **byte-identical**, single hunk boundary only. |
| `:1222-1256` | The apply tail, rewritten. `after`/`gained`/`changed` (`:1222-1224`); the single apply block `if changed and CFG_PATH.exists():` (`:1231`) with the recovery block re-homed inside it, inner order preserved (`generate_config()` → restored line → `if regen_ok and is_running()` → restart); **R6's comment at the apply site** (`:1240-1242`, immediately above `restart_service()` at `:1243`); the three-way outcome line (`:1247-1254`), always, exactly once, immediately before `if failed: sys.exit(…)` (`:1255`); `print(t("Done"))` (`:1257`). The old `if not applied and is_running(): …` lines are deleted. |

### `CHANGELOG.md` (`+2/−1`)

1. `:15` — the clause `注意这条命令在 sing-box 正在运行时会重启 sing-box（连接会中断几秒）` replaced by
   `注意这条命令只有在规则集内容确实发生变化时才会重启 sing-box（那几秒连接会中断）；内容没变时不会碰服务`,
   verbatim per `02` §6.5. Nothing else on that line changed; `:11` (T-02's entry) stays true, no edit owed.
2. `:16` — the new `### 修复` bullet, verbatim per `02` §6.5, one physical line like its neighbours.

### `docs/dev-map.md` (`+4/−2`)

Rows 46-47 of the "Reusable utilities" table only (the scope C-8 allows). See *Dev-map updates*.

## verify_all result

Command: `bash .harness/scripts/verify_all.sh`.

| Run | PASS | WARN | FAIL | SKIP | exit |
|---|---|---|---|---|---|
| **Baseline — pristine `HEAD`** (`git clone --no-hardlinks` of the repo into the scratchpad, HEAD `10fa8e8`) | 16 | 0 | 0 | 2 | 0 |
| **Baseline — working tree before any code change** (stage docs present) | 16 | 0 | 0 | 2 | 0 |
| **After this change** | 16 | 0 | 0 | 2 | 0 |

**Delta: zero.** No new FAIL, no new WARN, no check regressed from PASS.

**Which WARNs pre-existed: none.** The gate's Q8 anticipated an F.6 WARN on
`02_SOLUTION_DESIGN.md`; C-1 was already done before I started (the file is 495 lines), so F.6 is
PASS on both sides. The two SKIPs (B.2 tests, B.3 lint) are the project's standing state and are
unchanged by design — D-8/C-11 keep B.2 SKIP with its recorded reason.

I took the baseline from a pristine clone rather than `git stash -u` so that the untracked stage
documents were never moved; the clone gives a real `.git` directory, so A.1/A.2 run rather than
SKIP and the two baselines are directly comparable (they are identical).

## C-2 — live-service witness (before / after the whole verification run)

`systemctl is-active` alone is **not** the witness (it prints `active` on both sides of a restart
and would have passed during the T-02 incident). Process identity and activation time are:

```
--- BEFORE (2026-07-31T23:32:18+08:00, before any code was written) ---
$ systemctl is-active sing-box
active
$ systemctl show sing-box -p MainPID -p ActiveEnterTimestamp
MainPID=2500438
ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST

--- AFTER (2026-07-31T23:47:25+08:00, after every script and the final verify_all) ---
$ systemctl is-active sing-box
active
$ systemctl show sing-box -p MainPID -p ActiveEnterTimestamp
MainPID=2500438
ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
```

**Identical `MainPID` (2500438) and identical `ActiveEnterTimestamp`** — the live sing-box was
never restarted, never reloaded, never stopped. `is-active` is kept because AC-24 names it, and
both readings are `active`. The owner's connections (and this session's own SSH-equivalent) were
never dropped.

`/etc/sing-box/**` witness (G-5): `ls -la --time-style=full-iso /etc/sing-box /etc/sing-box/rules`
was quoted before and after every runner invocation and is byte-for-byte the same listing
(`config.json` 5572 B @ 2026-07-30 13:00:14, the four `.srs` files unchanged at their 17:04
timestamps), and `find /etc/sing-box -newermt '<stage-start>'` printed `(empty)` at the end of
every run. Nothing under `/etc/sing-box/**` was written.

## C-3 — how the two layers were built

All scripts live in `<scratchpad>/t10/` (not in the repo) and run through `t10/run.sh`.

**Layer 1 — module-level deny-by-default `subprocess` fake** (`t10/qalib.py`, `Tripwire` +
`load_sc`). After `exec`ing the neutralised source, the loaded module's `subprocess` attribute is
replaced with a stub module whose `run`, `Popen`, `call`, `check_call` and `check_output` all point
at one `Tripwire` instance that **records argv and raises on every call**. Nothing is whitelisted —
in particular `sing-box` is not (C-4). Every script asserts `mod.tripwire.calls == []` at the end,
except `t6`, which asserts the tripwire is what *stopped* the real `generate_config()` at its
`sing-box check`.

**Layer 2 — PATH-prepended shims writing a marker file.** `t10/run.sh` writes executables named
`systemctl`, `rc-service`, `sing-box`, `sc`, `sudo`, `service`, `openrc` into `t10/shims/`, prepends
that directory to `PATH` before `python3` starts, and `qalib.install_shims()` re-installs them
in-process so children inherit them. Shim source, verbatim:

```sh
#!/bin/sh
printf "%s %s\n" "$(basename "$0")" "$*" >> "$SC_T10_MARKER"
echo "BLOCKED by T-10 shim: $(basename "$0") $*" >&2
exit 91
```

Marker assertion, at the end of every script (`qalib.assert_no_service_calls`) **and** again in the
runner after all scripts:

```
### PATH-shim marker (must be absent)
(absent — no systemctl / rc-service / sing-box / sc / sudo invocation)
```

This is the layer that covers `Popen` / `check_call` / `os.system` / `os.execvp` / a re-import, and
the one that covers an unlisted script. Including a `sudo` shim means the auto-elevate itself could
not reach `/usr/local/bin/sc` even if the source substitution had failed.

**Auto-elevate neutralisation, in one shared loader.** `qalib.load_sc()` reads `bin/sc` as text,
requires the exact `bin/sc:78-79` block to be present (and **hard-fails** if `bin/sc` ever changes
shape rather than silently loading it un-neutralised), replaces it with `if False: pass`, also
neutralises `cmd_uninstall`'s `os.execvp("bash", …)`, then refuses to `exec` the source if any of
`os.execvp` / `os.execv(` / `os.execl` / `os.system` / `["sudo", "/usr/local/bin/sc"]` survives.
It then sets `SYSTEMD = OPENRC = False`, repoints `CFG_DIR / CFG_PATH / NODES_PATH / SETTINGS_PATH
/ RULES_DIR / LIB_DIR` into a `tempfile.mkdtemp()` root, and **self-asserts all of it before the
caller can call anything**. `mod.__name__` is never `"__main__"`, so `main()` cannot run.

**G-3 is a grep, not a promise.** Every script imports `qalib`; `run.sh` greps the whole directory
before running anything and aborts on a violation:

```
### G-3: every .py in this directory routes module loading through the ONE loader
    t1_state.py  OK (import qalib)      t4_static.py  OK (import qalib)
    t2_update_rules.py  OK (import qalib)   t5_tty.py  OK (import qalib)
    t3_negative_control.py  OK (import qalib)  t6_generate_config.py  OK (import qalib)
```

**Non-root euid, quoted** (`id -u`): `### euid: 1000  (alan)` — printed by `run.sh` at the top of
every run, which refuses to proceed at euid 0. No script executes `/usr/local/bin/sc`; the only
occurrences of that string in `t10/` are inside `qalib.py`'s substitution constants and its own
comment. `sc_HEAD.py` is a data copy of `git show HEAD:bin/sc` used by the negative control; it is
loaded through the same loader and never executed.

**Note for QA (real hazard observed).** The session scratchpad root (one level above `t10/`)
contains un-neutralised leftovers from earlier tasks, including `main_sc.py:54`, which is a live
copy of `bin/sc` carrying `os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])`.
Running it would be the T-02 incident again. That is exactly why the T-10 scripts were moved into
their own directory: it makes the G-3 grep total over a directory whose contents I control.

## C-4 — the G-2 ↔ AC-7/AC-8 conflict

Resolved by stubbing **module attributes**, never by whitelisting `sing-box`
(`qalib.stub_service`): `mod.generate_config`, `mod.is_running`, `mod.restart_service`,
`mod.reload_or_restart` are replaced with functions that append their name to an **ordered** log
(which is what AC-12/AC-4 assert on) and return the configured value. The tripwire stays armed
throughout, so any *unstubbed* shell-out is a hard failure. Test source:

```python
def stub_service(mod, running=True, regen=True):
    log = []
    def _generate_config():  log.append("generate_config");  return regen
    def _is_running():       log.append("is_running");       return running
    def _restart_service():  log.append("restart_service")
    def _reload_or_restart():log.append("reload_or_restart");return True
    mod.generate_config = _generate_config;  mod.is_running = _is_running
    mod.restart_service = _restart_service;  mod.reload_or_restart = _reload_or_restart
    return log
```

`t6_generate_config.py` then covers the **real** `generate_config()` separately, running it up to —
and not past — its `sing-box check`, which the tripwire blocks; the assertion is that the tripwire's
first recorded argv is `sing-box`, and that the config written before that point still defines the
right rule-sets. That is what proves the 3-tuple destructuring
(`for tag, fname, status in report if status == "usable"`) survived: **pre-change `bin/sc:804`,
post-change `bin/sc:899`**, inside `generate_config()`'s `route.rule_set` comprehension.

## C-5 — the digest contract

Stated in `ruleset_state`'s docstring (`bin/sc:517-534`) as an equivalence —
`digest is None ⟺ no complete read happened ⟺ status ∈ {absent, unreadable}` — and honoured by the
body: the sole `except OSError` returns `("unreadable", None)` **after** possibly hashing N bytes,
so a partial digest is never returned; a readable empty file falls through the loop with `size == 0`
and returns `("too-small", sha256(b"").hexdigest())`. Verified as an equivalence over every required
fixture (`t1_state.py`, C-5 block — chmod-000, directory, dangling symlink, 0-byte, short file, plus
bad-magic, usable, multi-chunk, and a simulated mid-read `OSError`):

```
  PASS  readable empty -> ('too-small', sha256(b''))
  PASS  OSError after N bytes -> ('unreadable', None), no partial digest
  PASS  C-5 nope.srs       status=absent     digest=None
  PASS  C-5 dir.srs        status=unreadable digest=None
  PASS  C-5 dangling.srs   status=unreadable digest=None
  PASS  C-5 noperm.srs     status=unreadable digest=None
  PASS  C-5 empty.srs      status=too-small  digest=real
  PASS  C-5 short.srs      status=too-small  digest=real
  PASS  C-5 html.srs       status=bad-magic  digest=real
  PASS  C-5 good.srs       status=usable     digest=real
  PASS  C-5 big_a.srs      status=usable     digest=real
  PASS  ruleset_state creates nothing
```

## C-6 — Python 3.6 floor, by regex over the added lines

`py_compile` on this host (3.12) cannot see a 3.7/3.8 construct, so AC-21 was verified with
banned-construct regexes over the **added** lines of `git diff --unified=0 -- bin/sc`
(`t4_static.py`), the T-02 AC-26 technique. 141 added lines, 28 removed. Regex list and result:

| Construct | Regex | Result |
|---|---|---|
| walrus `:=` (3.8) | `(?<![:=!<>+\-*/%&\|^])(:=)` | 0 hits |
| f-string `=` specifier (3.8) | `f["'][^"']*\{[^{}]*=\s*[}:]` | 0 hits |
| `capture_output=` (3.7) | `\bcapture_output\s*=` | 0 hits in added lines |
| `text=` (3.7) | `\btext\s*=` | 0 hits in added lines |
| `unlink(missing_ok=)` (3.8) | `missing_ok\s*=` | 0 hits |
| dataclasses (3.7) | `\bdataclass` | 0 hits |
| `from __future__` (3.7) | `__future__` | 0 hits |
| positional-only `/` (3.8) | `def\s+\w+\([^)]*,\s*/\s*[,)]` | 0 hits |
| dict `\|=` (3.9) | `^\s*\w+\s*\|=` | 0 hits |
| `match` statement (3.10) | `^\s*match\s+.*:\s*$` | 0 hits |
| `asyncio.run` (3.7) | `asyncio\.run` | 0 hits |

Whole-file counters, so no sixth 3.7+ site was added: `capture_output=` still **3**, `text=True`
still **2**. Those five sites sit on three physical lines, all pre-existing and untouched:
**pre-change `bin/sc:827`, `:869`, `:1176` → post-change `bin/sc:922`, `:964`, `:1289`**
(`generate_config()`'s `sing-box check` at `:921-922`, `is_running()`'s OpenRC branch at
`:963-964`, and `cmd_update_interval`'s `systemctl restart …rules-update.timer` at `:1287-1289` —
none of the three is on `cmd_update_rules`' path). Re-grep to confirm:
`grep -n 'capture_output=\|text=True\|:=\|missing_ok=' bin/sc` → exactly those three lines.
Exactly **one** import added and it is `hashlib`. The chunk loop uses the
`while True: … if not chunk: break` shape (`bin/sc:527-536`), the same idiom as `_fetch_to_temp`.
`python3 -m py_compile bin/sc` was additionally run after every step of `02` §10.5 and passes
(verify_all B.1 PASS).

## C-7 — three residuals, in my own words (the third has two halves)

**(i) F-11 — a run with failures can now restart, where today it never did.** Today `sys.exit`
(`bin/sc:1140`) sits *above* the unconditional restart, so any failed rule-set short-circuits the
whole apply. The design's required ordering (B-14/BC-9: apply before the non-zero exit, T-02's
ordering) puts the apply block first, so the case "2 rule-sets changed, 2 failed on every mirror"
now restarts where the old code exited without restarting. This is requirement-sanctioned and it is
the honest behaviour — the two rule-sets that *did* change are on disk and stale in the running
process — and on successful runs the new behaviour is strictly narrower than today's. I verified the
ordering both ways in `t2` ("BC-9 | AC-12 restart precedes the outcome line, which precedes the
exit", both languages). What I want the reviewer to notice: this is the **one** case where the
hazard in (ii) is genuinely new rather than inherited.

**(ii) F-4 — the `usable in after` filter is narrower than R9's wording claims.** R9 says "whatever
we restart for, we restart only for a file sing-box will actually load". That is true of the
*trigger* and false of the *run*: if an external actor destroys rule-set A while rule-set B legitimately
changes, `changed = {B}` and we restart into a `config.json` that still names A's path — sing-box
then FATALs on `parse rule-set[…]: open …: no such file`, which is precisely T-02's failure, with
`Restart=on-failure` looping. The filter prevents a restart **caused by** a loss, not a restart
**during** a loss. Today's code restarts unconditionally in that same situation, so this is not a
regression on a successful run — except in case (i), where it is new. I did **not** widen the fix
(gate Q6 answers this explicitly: no AC asks for it, D-4/§5.6 put loss-driven behaviour out of
scope). Recorded for PM to decide whether it becomes a pool row. The cheap future shape would be
"skip the restart when the usable set *shrank* during the run", which both snapshots already
contain.

**(iii) F-7 — `generate_config()`'s failure surface is wider now, on a path `02` §3 lists as "not
touched".** Because the digest lives inside the one existing query, `ruleset_report()` now reads
each file to EOF rather than reading 12 bytes. A file that opens and reads fine at byte 0 but faults
at byte 500 000 (bad sector, a flaky network filesystem, a truncating writer) was `usable` before
this change and is `unreadable` after it — so `generate_config()`, and therefore `sc use / add / rm
/ reload` (see (iii-b) for why that list excludes `mode` and `default-tun`), will now drop that
rule-set and its routing rules where they previously kept them
and let sing-box fail later. I consider the new behaviour more truthful (a rule-set sing-box cannot
read is not usable) and it is the accepted cost of R2, but it is a behaviour change on a T-02-owned
path that neither `01` nor `02` states in its diff reading. Cost side of R2 measured in passing: the
four real rule-sets total ~480 KB, hashed in 64 KiB chunks — microseconds against the `sing-box
check` subprocess `generate_config()` already spawns. `t6_generate_config.py` re-runs T-02's
degradation matrix through the new reader and it is unchanged.

**(iii-b) F-7's other half — unbounded read *size*, not just a wider fault surface** (added on
review; M-3). The paragraph above records what happens when a read *faults*; it does not record what
happens when a read simply does not end. `ruleset_state()` streams to EOF with no size ceiling and
runs inside `generate_config()`, so a pathologically large **regular** file at
`/etc/sing-box/rules/*.srs` — disk corruption, a botched `cp`, a log written to that name — now
costs a full sha256 over its entire length on **every** `sc use / add / rm / reload` (and on
`sc update-rules` itself), where before it cost 12 bytes plus one `stat`. That command list is
verified, not assumed: `generate_config()` has exactly two call sites, `reload_or_restart()`
(`bin/sc:937`) and `cmd_update_rules` (`:1236`), and `reload_or_restart()` is reached only from
`cmd_use` `:1032`, `cmd_add` `:1050`, `cmd_rm` `:1064`, `cmd_reload` `:1361`. Scope: real rule-sets
total ~480 KB, so this is a robustness edge, **not** a happy-path regression (the measured cost
above stands), and `if not path.is_file()` (`bin/sc:544`) already rejects a fifo, a device node or a
`/dev/zero` symlink — the bad case needs a genuinely large file on disk, not an infinite stream.
**Deliberately not fixed.** A cap would change what `srs_reject_reason()` *means*, introducing a
"too big to judge" verdict that no AC, no `01` requirement and no `02` section defines — a design
decision, not something to smuggle in under a review fix. Recorded as a residual and a **follow-up
pool-row candidate**; the shape a future task would weigh is "cap the hashed length and define the
verdict for a file that exceeds it", decided in `02`, not in `bin/sc`.

## C-9 — corrected overclaims are absent

Neither corrected overclaim appears anywhere in the shipped diff, in a code comment, or in a user
string, and neither appears in this document as a fact. Asserted mechanically over the added lines
of `bin/sc` + `CHANGELOG.md` + `docs/dev-map.md` (`t4_static.py`, 11 phrases including
"logs nothing", "silent on success", "the common case", "rarely", "常见情况", "很少") — 0 hits.
Positively: the `CHANGELOG` bullet claims only that a run restarts *when content changed* and does
not restart when it did not; it says nothing about how often that is. The design's frequency-free
argument is the one I implemented — a write-based signal ("200 OK", mtime, "a file was replaced") is
wrong on every successful run regardless of frequency; a content-based signal is right on every run
regardless of frequency.

## C-11 — R6's in-code comment at the apply site

Present at `bin/sc:1240-1242`, immediately above `restart_service()` at `:1243`:

```python
        if regen_ok and is_running():
            print("\n" + t("→ Restarting sing-box ..."))
            # The restart is conditional on changed_usable_tags(); an unconditional restart
            # here is the T-10 defect — it dropped every live connection (a remote admin's
            # own SSH included) on every weekly timer run, for four unchanged files.
            restart_service()
            restarted = True
```

`t4_static.py` asserts mechanically that a comment naming both `changed_usable_tags()` and
"T-10 defect" sits within six lines above the `restart_service()` call, so a future edit that keeps
the call and drops the comment is caught. B.2 stays SKIP with its recorded reason; no test tree was
committed (D-8 upheld). The complete harness is in `<scratchpad>/t10/` — `qalib.py`, `run.sh`,
`t1`…`t6` — for QA to paste verbatim into `06_TEST_REPORT.md` per C-11.

## Verification performed (fixtures and stubs only)

`bash run.sh t1_state.py t2_update_rules.py t3_negative_control.py t4_static.py t5_tty.py
t6_generate_config.py` → **350 assertions, 0 failures**, runner exit 0.

| Script | Assertions | Covers |
|---|---|---|
| `t1_state.py` | 50 | C-5 contract + AC-13 fixtures, the `ruleset_status`/`_status_view`/`ruleset_report` rewiring, the `changed_usable_tags` table (BC-1/2/4/5/6/7/13/16, AC-5, AC-6, F-10 pairing-by-tag with a control), AC-25 deletion test |
| `t2_update_rules.py` | 201 | Whole-command runs, **both languages**: BC-1 (AC-1/2/3), BC-2 (AC-4), BC-4 (AC-7), BC-5 (AC-8), failed regeneration, BC-10 (AC-9), BC-11 (AC-10, exit 0), BC-8 (AC-11), BC-9 (AC-12, F-11), BC-13, BC-19; AC-16 stream shape; AC-18 restart-wording absence; C-10 exactly one outcome line on both exit paths |
| `t3_negative_control.py` | 8 | The same BC-1 fixture against `git show HEAD:bin/sc` — proves the fixture detects the defect |
| `t4_static.py` | 67 | C-6 regexes, AC-14/AC-15 + zh collision audit vs. HEAD, C-8 diff boundary, C-9 phrases, C-11 comment |
| `t5_tty.py` | 16 | D-5: the outcome line on a **real pty** and on a redirected stream, both languages; AC-16/AC-17-adjacent stream shape |
| `t6_generate_config.py` | 8 | The **real** `generate_config()` through the new reader (T-02 degradation matrix), stopped by the tripwire at `sing-box check` |

The negative control is the load-bearing one — a test that cannot fail proves nothing:

```
== the PRE-CHANGE bin/sc (HEAD) on the identical no-op fixture
     service-layer call log: ['is_running', 'restart_service']
== the CHANGED bin/sc on the identical fixture
     service-layer call log: []
== delta on one identical fixture: ['is_running', 'restart_service']  ->  []
```

T-02 recovery preserved exactly (F-14): `unusable → usable ⇒ regenerate + apply`. The outer guard
`if changed and CFG_PATH.exists()` is strictly weaker than the old `if gained and
CFG_PATH.exists()` because `gained ⊆ changed`, and the inner order is verbatim, so a failed
`sing-box check` still blocks the restart (asserted: log `['generate_config']` only), the
`Rule-sets restored: … — config regenerated` / `规则集已恢复：…` line still prints when the service
is stopped, and the apply still precedes the non-zero exit.

## Design drift

**None.** `02` §10.5 was implemented in order; every signature, string, guard and ordering matches
§4/§6/§7. Two implementation choices worth naming, both *inside* the design rather than deviations:

1. **The `None` arm in `changed_usable_tags` is spelled out rather than left to `!=`.** `02` §4.1/§4.4
   and gate Q2 require that two `None` digests are **not** "the same content". Plain `old != new`
   would make `None != None` false, i.e. equal. I wrote
   `if old_digest is None or digest is None or old_digest != digest:` with a comment saying the
   None-vs-None arm is unreachable for a tag usable in `after` (its digest is real, by C-5) and
   exists so a later edit cannot quietly make two never-read files compare equal. Same results,
   the design's stated semantics, no hidden dependence on Python's `None` comparison.
2. **`docs/dev-map.md` gained two rows rather than only editing two.** C-8 permits that file "only
   for accuracy of its rule-set rows (`:46-47`)". I edited exactly that region, but describing the
   new shape accurately needed a row for `ruleset_state` and one for `changed_usable_tags` — the
   whole point of the row being that the next task must not write a second reader. Flagged so the
   reviewer can confirm the boundary call.

## Decisions recorded (standing authority, `defer, do not ask`)

**Gate Q5 — keep or delete `ruleset_status()`? → KEEP**, decided on merit, not on the doc boundary
(C-8 removed that boundary). Rubric: *sound software engineering* and *long-term maintainability*.
`srs_reject_reason` has three adapters — per file, per socket-bytes, per screen. Deleting the
per-file one leaves a caller who wants one file's status with either `ruleset_state(p)[0]` (a tuple
index at the call site, which is exactly the shape that tempts someone into `path.exists()` instead)
or `ruleset_states()`, which reads all four files to answer a question about one. The cost is one
line delegating to a function that *is* exercised, so it cannot drift semantically, and the docstring
states plainly that it has no in-tree caller today and why it exists. T-05 (`sc doctor`) is a filed
pool row that asks precisely this question. If T-05 lands and does not use it, deleting it then is a
two-line change.

**Correction (N-1) — what actually protects `ruleset_status()`.** An earlier draft said it "is
covered by `t1_state.py` assertions, so it is not untested dead code". That overreaches: under D-8
no test tree is committed and those assertions live only in the scratchpad harness, so **from the
repository's point of view it is an uncovered, caller-less function**. What protects it is its
shape, not a test that does not ship — `bin/sc:572` is the one-line delegation
`return ruleset_state(path)[0]` to a function every in-tree caller exercises, so it cannot drift
semantically without the reader itself breaking first. The keep decision rests on that and on the
rubric above (gate Q5 delegated it on merit), not on coverage.

**PM ruling on review M-5 — `CONTEXT.md:26-31` stays, not reverted.** The reviewer flagged it as
dirty against HEAD while C-8 names the product diff as exactly `bin/sc` + `CHANGELOG.md` +
`docs/dev-map.md`. PM ruling: that glossary entry was written at **stage 1**, is mandated by `01`
§3, and I never touched it at stage 4. C-8 constrains the *product* diff, and `CONTEXT.md` is a
project-context artifact in the class of `docs/features/**`, `docs/tasks.md` and
`.harness/rejected-decisions.md` — all exempted by `02` §3 on T-02 precedent. C-8's check is
therefore an **attributed** list (file → stage that wrote it), not set-inclusion over `git status`.

**Baseline method.** Pristine `HEAD` baseline taken from a `git clone --no-hardlinks` into the
scratchpad rather than `git stash -u`, so the untracked stage documents were never moved. Both
baselines were measured and are identical, so nothing turns on the choice.

**No `BLOCKED: NEEDS-HUMAN` was raised.** No safety red line was reached. In particular I did not
run the "just try a real restart and see whether the fswatch watcher picks it up" experiment: on
this host that is the red line, not a shortcut, and the decline record's unblock path correctly
requires a disposable host.

## Open issues for review

1. **R9's residual (C-7 ii)** — restart-during-a-loss. Not fixed, by gate ruling; PM's call whether
   it becomes a pool row. Both snapshots already carry what a fix would need.
2. **R5** — `restart_service()` runs `check=False` and never learns whether the daemon came back, so
   `— sing-box restarted to load them` claims a restart was *issued*, which is what actually
   happened. Unchanged from today; `02` §9 R5 flags it as a pool-row candidate.
3. **D-7's inherited stray blank line** — `"\n" + t("→ Restarting sing-box ...")` keeps its leading
   newline. Neither fixed nor worsened; it is now printed from **one** site instead of two.
4. **`ruleset_status()` has no in-tree caller** — deliberate, see the decision above. A reviewer who
   disagrees should say so now rather than after T-05.
5. **Scratchpad hygiene** — the shared session scratchpad root holds un-neutralised copies of
   `bin/sc` from earlier tasks (`main_sc.py:54` carries a live auto-elevate). Out of this task's
   diff, but QA should not run anything from that directory.
6. **Unbounded hashed length (C-7 iii-b, review M-3)** — **follow-up pool-row candidate.**
   `ruleset_state()` has no size ceiling, so a pathologically large regular `.srs` is hashed in
   full on every `sc use / add / rm / reload`. Not fixed here on purpose: a cap redefines
   `srs_reject_reason()`'s verdict set and is a design decision. Robustness edge only — real
   rule-sets are ~480 KB and `is_file()` already excludes fifos/devices.
7. **NFR-3 says "at most twice per run"; a `gained` run reads three times (review M-4)** — noted,
   not fixed: the third pass is `generate_config()`'s own `ruleset_report()`, inherited from T-02
   and on the "not touched" row. `cmd_update_rules` itself still takes exactly two snapshots. QA
   records the third pass against NFR-3 rather than as a T-10 regression.
8. **PEP 8 E302 at `bin/sc:1258` (review M-2)** — one blank line before `def cmd_update_interval`
   where the file's convention is two. Verified pre-existing: at HEAD the same single blank line
   sits at `HEAD:bin/sc:1145` before the `:1146` def, and my hunk (ending `print(t("Done"))`)
   preserved it verbatim. Follow-up, not fixed here by review instruction; B.3 lint is SKIP.

## Dev-map updates

`docs/dev-map.md`, "Reusable utilities" table, rows 46-47 (the only region C-8 permits). Row 46's
adapter list now names `ruleset_state(path)` instead of `ruleset_status(path)` as the per-file
adapter, and two rows were added:

```
| One file's on-disk facts | `ruleset_state(path)` → `(status, digest)` | same | The ONE reader of a `.srs` on disk, from one chunked read. `digest` is sha256 of the full content, or `None` — and `digest is None` ⟺ status ∈ `absent / unreadable` ⟺ no complete read (a readable *empty* file gets a real digest). `ruleset_status(path)` is its status-only view; it has no in-tree caller today and is kept as the named per-file adapter. |
| "Did any rule-set's content change?" | `changed_usable_tags(before, after)` | same | Both args are `ruleset_states()` snapshots; returns the sorted tags that are usable *after* and whose bytes really differ. Paired by tag, never by list index. This — not "the download succeeded" — is what `sc update-rules` restarts on. |
```

Row 47 additionally notes that `ruleset_report()` is now `_status_view(ruleset_states())` and that
`ruleset_states()` is the same list with the digest appended. No new folder, module or section was
created, so the "Folder layout" and "`bin/sc` internal sections" tables need no edit — everything
lives in the existing `# ============ Rule-sets ============` section.

## Insight to surface

- `sudo`'s `env_reset` is not the only way a harness leaks: a *shared* scratch directory does it too — this session's scratchpad root still held `main_sc.py`, a full un-neutralised copy of `bin/sc` whose import-time `os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] …)` would re-run the T-02 incident, so a per-task scratch subdirectory is what makes "every script neutralises the auto-elevate" a total grep · evidence: `<scratchpad>/main_sc.py:54` vs `<scratchpad>/t10/run.sh` G-3 block

## Verdict

**READY FOR REVIEW.**

`verify_all` PASS with zero delta against a pristine `HEAD` baseline (16 PASS / 0 WARN / 0 FAIL / 2
SKIP, exit 0); no WARN pre-existed. 350 fixture-and-stub assertions pass, including a negative
control proving the defect is reproduced on `HEAD` and gone here. The live sing-box was never
touched: `MainPID=2500438` and `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST` are identical
before and after the whole run, `/etc/sing-box` is unmodified, and no PATH shim was ever invoked.
Product diff is exactly `bin/sc` + `CHANGELOG.md` + `docs/dev-map.md`. **Not committed, not pushed**
— the owner handles delivery.
